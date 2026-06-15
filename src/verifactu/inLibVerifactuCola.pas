{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuCola                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de envío Verifactu (fza_verifactu_cola): encolado de la factura      }
{    al grabar la venta e hilo en segundo plano que procesa la cola, envía     }
{    los registros a la AEAT y persiste consolidación, cadena y eventos.       }
{******************************************************************************}
unit inLibVerifactuCola;

interface

uses
  System.SysUtils, System.Classes, Uni;

type
  TVerifactuCola = class
  public
    // Encola el registro de una factura. AQryTrx participa en la
    // transacción de la grabación de la venta: factura y cola se
    // confirman o deshacen juntas.
    class procedure EncolarFactura(AQryTrx: TUniQuery;
                                   const ASerie, ANumero: string;
                                   const ATipoOperacion: string = 'ALTA');
    // Genera y guarda el registro de facturación firmado sin enviarlo a AEAT.
    // Es el camino NO VERI*FACTU y debe ejecutarse al crear la factura.
    class procedure RegistrarFacturaNoVerifactu(AQryTrx: TUniQuery;
                                               const ASerie,
                                               ANumero: string;
                                               const ATipoOperacion: string =
                                               'ALTA');
    // Marca una factura recién abonada como RECTIFICATIVA, la enlaza con
    // la original (columnas ABONO) y la encola en Verifactu si está
    // activo. La llama el modal de Rectificar de Facturas.
    class procedure EncolarRectificativa(AConn: TUniConnection;
                                         const ASerieOriginal,
                                         ANumeroOriginal,
                                         ASerieRect, ANumeroRect: string);
    // Histórico N:1 de rectificaciones/sustituciones
    // (fza_facturas_relaciones): cada hija guarda su factura de origen
    class procedure RegistrarRelacionFactura(AConn: TUniConnection;
                                             const ASerie, ANumero,
                                             ASerieOrigen, ANumeroOrigen,
                                             ATipoRelacion: string);
    // Arranque tras el logon y parada al cerrar (ver inMtoPrincipal)
    class procedure IniciarHilo;
    class procedure DetenerHilo;
  end;

implementation

uses
  Winapi.Windows, Data.DB,
  inLibGlobalVar, inLibAppParam, inLibLog,
  inLibVerifactu, inLibVerifactuEnvio;

const
  fidvfcola       = 'ID_VFCOLA';
  fserievfcola    = 'SERIE_FAC_VFCOLA';
  fnumerovfcola   = 'NUMERO_FAC_VFCOLA';
  ftipoopvfcola   = 'TIPO_OPERACION_VFCOLA';
  fintentosvfcola = 'CONTADOR_INTENTOS_VFCOLA';

type
  // Worker: despierta cada appVerifactuSegundosCiclo segundos, reclama
  // filas PENDIENTE y delega el envío en inLibVerifactuEnvio. Usa una
  // conexión propia: oConn no se comparte entre hilos.
  THiloVerifactuCola = class(TThread)
  private
    FConn:              TUniConnection;
    FAvisoNoDisponible: Boolean;
    function CrearConexionPropia: TUniConnection;
    procedure ProcesarPendientes;
    // Devuelve los segundos de espera que pide la AEAT tras el envío
    // (control de flujo TiempoEsperaEnvio); 0 si no procede esperar
    function ProcesarFila(AIdCola: Int64;
                          const ASerie, ANumero, ATipoOperacion: string;
                          AIntentos: Integer): Integer;
    procedure GuardarEnvioOk(AIdCola: Int64;
                             const ASerie, ANumero, ATipoOperacion: string;
                             const AResultado: TResultadoEnvioVerifactu);
    procedure GuardarEnvioError(AIdCola: Int64;
                                const ASerie, ANumero, AMensaje: string;
                                AIntentos: Integer);
    procedure EsperarCiclo;
    procedure EsperarSegundos(ASegundos: Integer);
  protected
    procedure Execute; override;
  public
    destructor Destroy; override;
  end;

var
  oHiloCola: THiloVerifactuCola = nil;

function ColumnasFirmaFacturacionDisponibles(AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_facturas_consolidaciones'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_FACCON'', ' +
      '       ''FIRMA_DIGITAL_FACCON'', ''SERIE_CERTIFICADO_FACCON'', ' +
      '       ''TITULAR_CERTIFICADO_FACCON'', ' +
      '       ''HUELLA_CERTIFICADO_FACCON'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure GuardarRegistroNoVerifactu(AQry: TUniQuery;
                                     const ASerie, ANumero,
                                     ATipoOperacion: string;
                                     const AResultado:
                                     TResultadoEnvioVerifactu);
var
  sEstado: string;
begin
  if not ColumnasFirmaFacturacionDisponibles(AQry.Connection) then
    raise Exception.Create('Faltan columnas de firma en ' +
      'fza_facturas_consolidaciones. Aplique el script ' +
      'DESARROLLOS EN CURSO\verifactu_registros_firmados.sql.');
  AQry.SQL.Text :=
    ' UPDATE fza_verifactu_cadena ' +
    ' SET CONTADOR_VFCAD = :CONTADOR, ' +
    '     SERIE_FAC_VFCAD  = :SERIE, ' +
    '     NUMERO_FAC_VFCAD = :NUMERO, ' +
    '     FECHA_FAC_VFCAD  = STR_TO_DATE(:FECHA, ''%d-%m-%Y''), ' +
    '     HUELLA_VFCAD = :HUELLA, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE NIF_VFCAD = :NIF';
  AQry.ParamByName('CONTADOR').AsString := AResultado.ChainNumber;
  AQry.ParamByName('SERIE').AsString    := ASerie;
  AQry.ParamByName('NUMERO').AsString   := ANumero;
  AQry.ParamByName('FECHA').AsString    := AResultado.FechaExpedicion;
  AQry.ParamByName('HUELLA').AsString   := AResultado.ChainHash;
  AQry.ParamByName('USUARIO').AsString  := oUser;
  AQry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
  AQry.Execute;
  if ATipoOperacion = 'ANULACION' then
    sEstado := 'ANULADO_NO_VERIFACTU'
  else if ATipoOperacion = 'SUBSANACION' then
    sEstado := 'SUBSANADO_NO_VERIFACTU'
  else
    sEstado := 'REGISTRADO_NO_VERIFACTU';
  if ATipoOperacion = 'ANULACION' then
  begin
    AQry.SQL.Text :=
      ' UPDATE fza_facturas_consolidaciones ' +
      ' SET CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
      '     CHAIN_HASH_FACCON = :CHAINHASH, ' +
      '     ISSUER_IRS_ID_CONSOLIDACION_FACCON = :ISSUERID, ' +
      '     ISSUED_TIME_FACCON = :ISSUEDTIME, ' +
      '     FECHA_PROCESAMIENTO_FACCON = NOW(), ' +
      '     ESTADO_FACCON = :ESTADO, ' +
      '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
      '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
      '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
      '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
      '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO';
  end
  else
  begin
    AQry.SQL.Text :=
      ' INSERT INTO fza_facturas_consolidaciones ' +
      ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
      '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
      '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
      '  FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
      '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
      '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
      '  HUELLA_CERTIFICADO_FACCON) ' +
      ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
      '        :ISSUERID, :ISSUEDTIME, :CHAINNUM, :CHAINHASH, ' +
      '        NOW(), :ESTADO, :REGISTROXML, :FIRMA, :SERIECERT, ' +
      '        :TITULARCERT, :HUELLACERT ' +
      ' FROM fza_facturas_consolidaciones ' +
      ' ON DUPLICATE KEY UPDATE ' +
      '  ESTADO_FACCON = VALUES(ESTADO_FACCON), ' +
      '  CHAIN_NUMBER_FACCON = VALUES(CHAIN_NUMBER_FACCON), ' +
      '  CHAIN_HASH_FACCON = VALUES(CHAIN_HASH_FACCON), ' +
      '  REGISTRO_XML_FACCON = VALUES(REGISTRO_XML_FACCON), ' +
      '  FIRMA_DIGITAL_FACCON = VALUES(FIRMA_DIGITAL_FACCON), ' +
      '  SERIE_CERTIFICADO_FACCON = VALUES(SERIE_CERTIFICADO_FACCON), ' +
      '  TITULAR_CERTIFICADO_FACCON = VALUES(TITULAR_CERTIFICADO_FACCON), ' +
      '  HUELLA_CERTIFICADO_FACCON = VALUES(HUELLA_CERTIFICADO_FACCON)';
  end;
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.ParamByName('ISSUERID').AsString := AResultado.IssuerIrsId;
  AQry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
  AQry.ParamByName('ISSUEDTIME').AsDateTime := AResultado.IssuedTime;
  AQry.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
  AQry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
  AQry.ParamByName('ESTADO').AsString := sEstado;
  AQry.ParamByName('REGISTROXML').AsString :=
    AResultado.RegistroXmlFirmado;
  AQry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
  AQry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
  AQry.ParamByName('TITULARCERT').AsString :=
    AResultado.TitularCertificado;
  AQry.ParamByName('HUELLACERT').AsString :=
    AResultado.HuellaCertificado;
  AQry.Execute;
  AQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET ESCONSOLIDADA_FAC = ''S'', ' +
    '     INSTANTECONSO_FAC = NOW(), ' +
    '     FASE_FAC = :FASE, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  if ATipoOperacion = 'ANULACION' then
    AQry.ParamByName('FASE').AsString := 'CANCELADA'
  else
    AQry.ParamByName('FASE').AsString := 'ONLINE';
  AQry.ParamByName('USUARIO').AsString := oUser;
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.Execute;
end;

// ===========================================================================
//   TVerifactuCola — API pública
// ===========================================================================

class procedure TVerifactuCola.EncolarFactura(AQryTrx: TUniQuery;
                                              const ASerie, ANumero: string;
                                              const ATipoOperacion: string);
begin
  // ON DUPLICATE: si la operación ya estaba encolada se relanza
  // (vuelve a PENDIENTE con los intentos a cero)
  AQryTrx.SQL.Text :=
    ' INSERT INTO fza_verifactu_cola ' +
    ' (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, TIPO_OPERACION_VFCOLA, ' +
    '  ESTADO_VFCOLA, CONTADOR_INTENTOS_VFCOLA, INSTANTE_ALTA, ' +
    '  USUARIO_ALTA) ' +
    ' VALUES ' +
    ' (:SERIE, :NUMERO, :TIPOOP, ''PENDIENTE'', 0, NOW(), :USUARIO) ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  ESTADO_VFCOLA = ''PENDIENTE'', ' +
    '  CONTADOR_INTENTOS_VFCOLA = 0, ' +
    '  INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
    '  MENSAJE_ERROR_VFCOLA = NULL, ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF  = :USUARIO';
  AQryTrx.ParamByName('SERIE').AsString   := ASerie;
  AQryTrx.ParamByName('NUMERO').AsString  := ANumero;
  AQryTrx.ParamByName('TIPOOP').AsString  := ATipoOperacion;
  AQryTrx.ParamByName('USUARIO').AsString := oUser;
  AQryTrx.Execute;
  // El lanzamiento saca la factura de BORRADOR en el acto: el QR es
  // calculable en local (ConstruirUrlQR) y la petición al ws viaja
  // asíncrona en el hilo de la cola. Desde ONLINE ya puede imprimirse
  // y deja de ser editable (solo anular o rectificar).
  if SameText(ATipoOperacion, 'ALTA') then
  begin
    AQryTrx.SQL.Text :=
      ' UPDATE fza_facturas ' +
      '    SET FASE_FAC = ''ONLINE'', ' +
      '        INSTANTE_MODIF = NOW(), ' +
      '        USUARIO_MODIF  = :USUARIO ' +
      '  WHERE SERIE_FAC  = :SERIE ' +
      '    AND NUMERO_FAC = :NUMERO ' +
      '    AND (FASE_FAC IS NULL OR ' +
      '         FASE_FAC IN ('''', ''BORRADOR'', ''ERROR''))';
    AQryTrx.ParamByName('SERIE').AsString   := ASerie;
    AQryTrx.ParamByName('NUMERO').AsString  := ANumero;
    AQryTrx.ParamByName('USUARIO').AsString := oUser;
    AQryTrx.Execute;
  end;
end;

class procedure TVerifactuCola.RegistrarFacturaNoVerifactu(AQryTrx: TUniQuery;
                                                           const ASerie,
                                                           ANumero: string;
                                                           const ATipoOperacion:
                                                           string);
var
  oResultado: TResultadoEnvioVerifactu;
begin
  oResultado := GenerarRegistroFacturaLocal(AQryTrx.Connection, ASerie,
                                            ANumero, ATipoOperacion);
  if not oResultado.Ok then
    raise Exception.Create(oResultado.MensajeError);
  GuardarRegistroNoVerifactu(AQryTrx, ASerie, ANumero, ATipoOperacion,
                             oResultado);
  RegistrarEventoVerifactu(AQryTrx.Connection, cEventoVerifactuInfo,
    'Registro de facturación NO VERI*FACTU firmado', ATipoOperacion,
    ASerie, ANumero);
end;

class procedure TVerifactuCola.EncolarRectificativa(AConn: TUniConnection;
                                                    const ASerieOriginal,
                                                    ANumeroOriginal,
                                                    ASerieRect,
                                                    ANumeroRect: string);
var
  Qry: TUniQuery;
begin
  // Guarda: una rectificativa sin serie/numero validos (p.ej. '0'/'0' por
  // una cabecera de caja que no se vuelca) encolaria un registro fantasma
  // que la AEAT rechaza y rompe el enlace ABONO de la original. Se deja
  // constancia en el log y no se toca nada mas.
  if (Trim(ASerieRect) = '') or (Trim(ASerieRect) = '0') or
     (Trim(ANumeroRect) = '') or (Trim(ANumeroRect) = '0') then
    RegistrarEventoVerifactu(AConn, cEventoVerifactuEnvioError,
      'Rectificativa de ' + ASerieOriginal + '\' + ANumeroOriginal +
      ' NO encolada: la factura rectificativa carece de serie/numero ' +
      'validos (recibido ' + ASerieRect + '\' + ANumeroRect + ')', '',
      ASerieOriginal, ANumeroOriginal)
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      // Rectificativa: tipo y fase propios, sin enlace ABONO heredado de
      // la copia del SP, y comentario con la factura que rectifica
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET TIPO_FAC = ''RECTIFICATIVA'', ' +
        '     FASE_FAC = ''BORRADOR'', ' +
        '     SERIE_FAC_ABONO_FAC  = NULL, ' +
        '     NUMERO_FAC_ABONO_FAC = NULL, ' +
        '     COMENTARIOS_FAC = TRIM(CONCAT(IFNULL(COMENTARIOS_FAC, ' +
        '         ''''), :COMENTARIO)), ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('COMENTARIO').AsString :=
        ' ESTA FACTURA ANULA Y RECTIFICA A LA ' + ASerieOriginal + '\' +
        ANumeroOriginal;
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('SERIE').AsString   := ASerieRect;
      Qry.ParamByName('NUMERO').AsString  := ANumeroRect;
      Qry.Execute;
      // La factura ORIGINAL pasa a fase RECTIFICADA y guarda en sus
      // columnas ABONO la rectificativa que la anula
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FASE_FAC = ''RECTIFICADA'', ' +
        '     SERIE_FAC_ABONO_FAC  = :SERIERECT, ' +
        '     NUMERO_FAC_ABONO_FAC = :NUMERORECT, ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIERECT').AsString  := ASerieRect;
      Qry.ParamByName('NUMERORECT').AsString := ANumeroRect;
      Qry.ParamByName('USUARIO').AsString    := oUser;
      Qry.ParamByName('SERIE').AsString      := ASerieOriginal;
      Qry.ParamByName('NUMERO').AsString     := ANumeroOriginal;
      Qry.Execute;
      // Histórico N:1: cada rectificativa conserva su propio enlace
      // aunque la original se rectifique varias veces
      RegistrarRelacionFactura(AConn, ASerieRect, ANumeroRect,
                               ASerieOriginal, ANumeroOriginal,
                               'RECTIFICA');
      if VerifactuActivo then
      begin
        EncolarFactura(Qry, ASerieRect, ANumeroRect);
        RegistrarEventoVerifactu(AConn, cEventoVerifactuEncolado,
          'Rectificativa de ' + ASerieOriginal + '\' + ANumeroOriginal +
          ' encolada desde Facturas', '', ASerieRect, ANumeroRect);
      end;
      if not VerifactuActivo then
        RegistrarFacturaNoVerifactu(Qry, ASerieRect, ANumeroRect);
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

class procedure TVerifactuCola.RegistrarRelacionFactura(
                                  AConn: TUniConnection;
                                  const ASerie, ANumero,
                                  ASerieOrigen, ANumeroOrigen,
                                  ATipoRelacion: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' INSERT INTO fza_facturas_relaciones ' +
      ' (SERIE_FAC_FACREL, NUMERO_FAC_FACREL, ' +
      '  SERIE_FAC_ORIGEN_FACREL, NUMERO_FAC_ORIGEN_FACREL, ' +
      '  TIPO_RELACION_FACREL, INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' VALUES (:SERIE, :NUMERO, :SERIEORIG, :NUMEROORIG, :TIPO, ' +
      '         NOW(), :USUARIO) ' +
      ' ON DUPLICATE KEY UPDATE ' +
      '  SERIE_FAC_ORIGEN_FACREL  = :SERIEORIG, ' +
      '  NUMERO_FAC_ORIGEN_FACREL = :NUMEROORIG, ' +
      '  INSTANTE_MODIF = NOW(), ' +
      '  USUARIO_MODIF  = :USUARIO';
    Qry.ParamByName('SERIE').AsString      := ASerie;
    Qry.ParamByName('NUMERO').AsString     := ANumero;
    Qry.ParamByName('SERIEORIG').AsString  := ASerieOrigen;
    Qry.ParamByName('NUMEROORIG').AsString := ANumeroOrigen;
    Qry.ParamByName('TIPO').AsString       := ATipoRelacion;
    Qry.ParamByName('USUARIO').AsString    := oUser;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

class procedure TVerifactuCola.IniciarHilo;
begin
  if oHiloCola = nil then
  begin
    oHiloCola := THiloVerifactuCola.Create(True);
    oHiloCola.FreeOnTerminate := False;
    oHiloCola.Start;
    inLibLog.Log.LogInfo('Cola Verifactu: hilo iniciado');
  end;
end;

class procedure TVerifactuCola.DetenerHilo;
begin
  if oHiloCola <> nil then
  begin
    oHiloCola.Terminate;
    oHiloCola.WaitFor;
    FreeAndNil(oHiloCola);
    inLibLog.Log.LogInfo('Cola Verifactu: hilo detenido');
  end;
end;

// ===========================================================================
//   THiloVerifactuCola — worker en segundo plano
// ===========================================================================

destructor THiloVerifactuCola.Destroy;
begin
  FreeAndNil(FConn);
  inherited;
end;

procedure THiloVerifactuCola.Execute;
begin
  NameThreadForDebugging('VerifactuCola');
  FAvisoNoDisponible := False;
  while (not Terminated) and (not oCerrandoApp) do
  begin
    // La espera va primero: deja respirar el arranque de la app y
    // permite cerrar sin procesar nada a medias
    EsperarCiclo;
    if (not Terminated) and (not oCerrandoApp) and
       oAppParams.GetBool('appVerifactuActivo', False) then
    begin
      try
        ProcesarPendientes;
      except
        on E: Exception do
        begin
          inLibLog.Log.LogError('Cola Verifactu: ' + E.Message);
          // Si la conexión propia quedó inservible se recrea al
          // siguiente ciclo
          FreeAndNil(FConn);
        end;
      end;
    end;
  end;
end;

procedure THiloVerifactuCola.EsperarCiclo;
var
  iSegundos: Integer;
begin
  iSegundos := oAppParams.GetInt('appVerifactuSegundosCiclo', 60);
  if iSegundos < 5 then
    iSegundos := 5;
  EsperarSegundos(iSegundos);
end;

procedure THiloVerifactuCola.EsperarSegundos(ASegundos: Integer);
var
  iPasos: Integer;
  iPaso:  Integer;
begin
  // Tope de cordura y espera troceada en pasos de 100 ms para
  // reaccionar rápido a la parada del hilo
  if ASegundos > 300 then
    ASegundos := 300;
  iPasos := ASegundos * 10;
  iPaso  := 0;
  while (iPaso < iPasos) and (not Terminated) and (not oCerrandoApp) do
  begin
    Sleep(100);
    Inc(iPaso);
  end;
end;

function THiloVerifactuCola.CrearConexionPropia: TUniConnection;
begin
  // Clon de la conexión global (mismo patrón que
  // TfrmMtoGen.CrearConexionPropia): con los mismos parámetros las
  // conexiones físicas salen del mismo pool de UniDAC
  Result := TUniConnection.Create(nil);
  try
    Result.LoginPrompt  := False;
    Result.ProviderName := oConn.ProviderName;
    Result.Server       := oConn.Server;
    Result.Port         := oConn.Port;
    Result.Database     := oConn.Database;
    Result.Username     := oConn.Username;
    Result.Password     := oConn.Password;
    Result.Pooling      := True;
    Result.PoolingOptions.ConnectionLifetime := 0;
    Result.PoolingOptions.Validate := True;
    Result.SpecificOptions.Values['MySQL.Interactive'] := 'True';
    Result.SpecificOptions.Values['ConnectionTimeout'] := '30';
    Result.Options.LocalFailover    := True;
    Result.Options.DisconnectedMode := True;
    // AfterConnect reaplica colación y timeouts tras cada reconexión.
    // El OnError de UI no se engancha: los errores del hilo se capturan
    // en Execute y van al log.
    Result.AfterConnect := oConn.AfterConnect;
    Result.Connect;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure THiloVerifactuCola.ProcesarPendientes;
var
  Qry:     TUniQuery;
  iEspera: Integer;
begin
  if FConn = nil then
    FConn := CrearConexionPropia;
  if not EnvioVerifactuDisponible then
  begin
    // Cliente de envío desactivado: la cola se acumula en PENDIENTE.
    // Se deja constancia una sola vez por sesión.
    if not FAvisoNoDisponible then
    begin
      RegistrarEventoVerifactu(FConn, cEventoVerifactuInfo,
        'Cola Verifactu activa sin cliente de envío AEAT disponible: ' +
        'las facturas quedan en estado PENDIENTE');
      FAvisoNoDisponible := True;
    end;
  end
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConn;
      // Rescate de filas PROCESANDO huérfanas (cierre brusco de la app)
      Qry.SQL.Text :=
        ' UPDATE fza_verifactu_cola ' +
        ' SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
        '     INSTANTE_MODIF = NOW() ' +
        ' WHERE ESTADO_VFCOLA = ''PROCESANDO'' ' +
        '   AND INSTANTE_MODIF < DATE_SUB(NOW(), INTERVAL 10 MINUTE)';
      Qry.Execute;
      // Reproceso: filas en ERROR con menos intentos que el máximo
      // vigente vuelven a la cola (p.ej. tras corregir configuración,
      // resetear intentos a mano o subir appVerifactuMaxIntentos)
      Qry.SQL.Text :=
        ' UPDATE fza_verifactu_cola ' +
        ' SET ESTADO_VFCOLA = ''PENDIENTE'', ' +
        '     INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
        '     INSTANTE_MODIF = NOW() ' +
        ' WHERE ESTADO_VFCOLA = ''ERROR'' ' +
        '   AND CONTADOR_INTENTOS_VFCOLA < :MAXINTENTOS';
      Qry.ParamByName('MAXINTENTOS').AsInteger :=
        oAppParams.GetInt('appVerifactuMaxIntentos', 10);
      Qry.Execute;
      Qry.SQL.Text :=
        ' SELECT ID_VFCOLA, SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, ' +
        '        TIPO_OPERACION_VFCOLA, CONTADOR_INTENTOS_VFCOLA ' +
        ' FROM fza_verifactu_cola ' +
        ' WHERE ESTADO_VFCOLA = ''PENDIENTE'' ' +
        '   AND (INSTANTE_PROXIMO_INTENTO_VFCOLA IS NULL ' +
        '        OR INSTANTE_PROXIMO_INTENTO_VFCOLA <= NOW()) ' +
        ' ORDER BY ID_VFCOLA ' +
        ' LIMIT 25';
      Qry.Open;
      while (not Qry.Eof) and (not Terminated) and (not oCerrandoApp) do
      begin
        iEspera := ProcesarFila(Qry.FieldByName(fidvfcola).AsLargeInt,
                                Qry.FieldByName(fserievfcola).AsString,
                                Qry.FieldByName(fnumerovfcola).AsString,
                                Qry.FieldByName(ftipoopvfcola).AsString,
                                Qry.FieldByName(fintentosvfcola).AsInteger);
        // Control de flujo de la AEAT entre envíos consecutivos
        if iEspera > 0 then
          EsperarSegundos(iEspera);
        Qry.Next;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function THiloVerifactuCola.ProcesarFila(AIdCola: Int64;
                                         const ASerie, ANumero,
                                         ATipoOperacion: string;
                                         AIntentos: Integer): Integer;
var
  Qry:        TUniQuery;
  bReclamada: Boolean;
  oResultado: TResultadoEnvioVerifactu;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    // Reclamo optimista: si otro puesto se adelantó, aquí no se procesa
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''PROCESANDO'', ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID ' +
      '   AND ESTADO_VFCOLA = ''PENDIENTE''';
    Qry.ParamByName('USUARIO').AsString := oUser;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
    bReclamada := (Qry.RowsAffected = 1);
  finally
    FreeAndNil(Qry);
  end;
  if bReclamada then
  begin
    // Transacción del envío: el FOR UPDATE de fza_verifactu_cadena que
    // toma EnviarRegistroFactura serializa el encadenamiento entre
    // puestos hasta el commit/rollback
    FConn.StartTransaction;
    try
      oResultado := EnviarRegistroFactura(FConn, ASerie, ANumero,
                                          ATipoOperacion);
      if oResultado.Ok then
      begin
        // El registro YA está aceptado por la AEAT: si fallara la
        // persistencia local se anota la verdad y el reintento se
        // resolverá por la vía del registro duplicado
        try
          GuardarEnvioOk(AIdCola, ASerie, ANumero, ATipoOperacion,
                         oResultado);
          FConn.Commit;
          Result := oResultado.EsperaSegundos;
        except
          on E: Exception do
          begin
            if FConn.InTransaction then
              FConn.Rollback;
            GuardarEnvioError(AIdCola, ASerie, ANumero,
              'Aceptado por la AEAT pero falló la persistencia ' +
              'local: ' + E.Message, AIntentos);
          end;
        end;
      end
      else
      begin
        FConn.Rollback;
        GuardarEnvioError(AIdCola, ASerie, ANumero,
                          oResultado.MensajeError, AIntentos);
      end;
    except
      on E: Exception do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        GuardarEnvioError(AIdCola, ASerie, ANumero, E.Message, AIntentos);
      end;
    end;
  end;
end;

procedure THiloVerifactuCola.GuardarEnvioOk(AIdCola: Int64;
                                            const ASerie, ANumero,
                                            ATipoOperacion: string;
                                            const AResultado:
                                                  TResultadoEnvioVerifactu);
var
  Qry:           TUniQuery;
  oPngStream:    TBytesStream;
  sFase:         string;
  sEstadoFaccon: string;
  bInsertarAlta: Boolean;
begin
  // Se ejecuta DENTRO de la transacción abierta por ProcesarFila
  if ATipoOperacion = 'ANULACION' then
    sFase := 'CANCELADA'
  else
    sFase := 'ONLINE';
  if SameText(AResultado.EstadoRegistro, 'AceptadoConErrores') then
    sEstadoFaccon := 'ACEPTADO_ERR'
  else if SameText(AResultado.EstadoRegistro, 'Duplicado') then
    sEstadoFaccon := 'DUPLICADO'
  else if ATipoOperacion = 'SUBSANACION' then
    sEstadoFaccon := 'SUBSANADO'
  else
    sEstadoFaccon := 'PROCESADO';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    // Avanzar la cadena de huellas del emisor (fila bloqueada con
    // FOR UPDATE desde EnviarRegistroFactura)
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cadena ' +
      ' SET CONTADOR_VFCAD = :CONTADOR, ' +
      '     SERIE_FAC_VFCAD  = :SERIE, ' +
      '     NUMERO_FAC_VFCAD = :NUMERO, ' +
      '     FECHA_FAC_VFCAD  = STR_TO_DATE(:FECHA, ''%d-%m-%Y''), ' +
      '     HUELLA_VFCAD = :HUELLA, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE NIF_VFCAD = :NIF';
    Qry.ParamByName('CONTADOR').AsString := AResultado.ChainNumber;
    Qry.ParamByName('SERIE').AsString    := ASerie;
    Qry.ParamByName('NUMERO').AsString   := ANumero;
    Qry.ParamByName('FECHA').AsString    := AResultado.FechaExpedicion;
    Qry.ParamByName('HUELLA').AsString   := AResultado.ChainHash;
    Qry.ParamByName('USUARIO').AsString  := oUser;
    Qry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
    Qry.Execute;
    bInsertarAlta := (ATipoOperacion <> 'ANULACION');
    if ATipoOperacion = 'ANULACION' then
    begin
      // La anulación actualiza la consolidación del alta (UK_FACTURA)
      Qry.SQL.Text :=
        ' UPDATE fza_facturas_consolidaciones ' +
        ' SET QUEUE_ID_CANCEL_FACCON = :IDCOLA, ' +
        '     ESTADO_FACCON = ''ANULADO'', ' +
        '     CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
        '     CHAIN_HASH_FACCON   = :CHAINHASH, ' +
        '     RESPUESTA_COMPLETA_FACCON = :RESPUESTA, ' +
        '     PETICION_COMPLETA_FACCON  = :PETICION, ' +
        '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
        '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
        '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
        '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
        '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT, ' +
        '     FECHA_PROCESAMIENTO_FACCON = NOW() ' +
        ' WHERE SERIE_FAC_FACCON  = :SERIE ' +
        '   AND NUMERO_FAC_FACCON = :NUMERO';
      Qry.ParamByName('IDCOLA').AsLargeInt  := AIdCola;
      Qry.ParamByName('CHAINNUM').AsString  := AResultado.ChainNumber;
      Qry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
      Qry.ParamByName('RESPUESTA').AsString :=
        AResultado.RespuestaCompleta;
      Qry.ParamByName('PETICION').AsString :=
        AResultado.PeticionCompleta;
      Qry.ParamByName('REGISTROXML').AsString :=
        AResultado.RegistroXmlFirmado;
      Qry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
      Qry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
      Qry.ParamByName('TITULARCERT').AsString :=
        AResultado.TitularCertificado;
      Qry.ParamByName('HUELLACERT').AsString :=
        AResultado.HuellaCertificado;
      Qry.ParamByName('SERIE').AsString  := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Execute;
    end;
    if ATipoOperacion = 'SUBSANACION' then
    begin
      // La subsanación reescribe la consolidación del alta; si no
      // existiera (alta nunca consolidada) se inserta entera abajo
      Qry.SQL.Text :=
        ' UPDATE fza_facturas_consolidaciones ' +
        ' SET REQUEST_ID_CONSOLIDACION_FACCON = ' +
        '       IFNULL(NULLIF(:REQUESTID, ''''), ' +
        '              REQUEST_ID_CONSOLIDACION_FACCON), ' +
        '     CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
        '     CHAIN_HASH_FACCON   = :CHAINHASH, ' +
        '     ESTADO_FACCON = :ESTADO, ' +
        '     RESPUESTA_COMPLETA_FACCON = :RESPUESTA, ' +
        '     PETICION_COMPLETA_FACCON  = :PETICION, ' +
        '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
        '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
        '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
        '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
        '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT, ' +
        '     FECHA_PROCESAMIENTO_FACCON = NOW() ' +
        ' WHERE SERIE_FAC_FACCON  = :SERIE ' +
        '   AND NUMERO_FAC_FACCON = :NUMERO';
      Qry.ParamByName('REQUESTID').AsString := AResultado.RequestId;
      Qry.ParamByName('CHAINNUM').AsString  := AResultado.ChainNumber;
      Qry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
      Qry.ParamByName('ESTADO').AsString    := sEstadoFaccon;
      Qry.ParamByName('RESPUESTA').AsString :=
        AResultado.RespuestaCompleta;
      Qry.ParamByName('PETICION').AsString :=
        AResultado.PeticionCompleta;
      Qry.ParamByName('REGISTROXML').AsString :=
        AResultado.RegistroXmlFirmado;
      Qry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
      Qry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
      Qry.ParamByName('TITULARCERT').AsString :=
        AResultado.TitularCertificado;
      Qry.ParamByName('HUELLACERT').AsString :=
        AResultado.HuellaCertificado;
      Qry.ParamByName('SERIE').AsString  := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Execute;
      bInsertarAlta := (Qry.RowsAffected = 0);
    end;
    if bInsertarAlta then
    begin
      // Consolidación del alta: misma estructura que usa OdaVeriFactu
      Qry.SQL.Text :=
        ' INSERT INTO fza_facturas_consolidaciones ' +
        ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
        '  REQUEST_ID_CONSOLIDACION_FACCON, ' +
        '  QUEUE_ID_CONSOLIDACION_FACCON, ' +
        '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
        '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
        '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
        '  QRCODE_PNG_FACCON, ' +
        '  FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
        '  RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON, ' +
        '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
        '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
        '  HUELLA_CERTIFICADO_FACCON) ' +
        ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
        '        NULLIF(:REQUESTID, ''''), :IDCOLA, ' +
        '        NULLIF(:ISSUERID, ''''), :ISSUEDTIME, ' +
        '        NULLIF(:CHAINNUM, ''''), NULLIF(:CHAINHASH, ''''), ' +
        '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), ' +
        '        :QRPNG, NOW(), ' +
        '        :ESTADO, NULLIF(:RESPUESTA, ''''), ' +
        '        NULLIF(:PETICION, ''''), :REGISTROXML, :FIRMA, ' +
        '        :SERIECERT, :TITULARCERT, :HUELLACERT ' +
        ' FROM fza_facturas_consolidaciones';
      Qry.ParamByName('SERIE').AsString     := ASerie;
      Qry.ParamByName('NUMERO').AsString    := ANumero;
      Qry.ParamByName('REQUESTID').AsString := AResultado.RequestId;
      Qry.ParamByName('IDCOLA').AsLargeInt  := AIdCola;
      Qry.ParamByName('ISSUERID').AsString  := AResultado.IssuerIrsId;
      Qry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
      if AResultado.IssuedTime > 0 then
        Qry.ParamByName('ISSUEDTIME').AsDateTime := AResultado.IssuedTime
      else
        Qry.ParamByName('ISSUEDTIME').Clear;
      Qry.ParamByName('CHAINNUM').AsString  := AResultado.ChainNumber;
      Qry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
      Qry.ParamByName('URL').AsString       := AResultado.VerifactuUrl;
      Qry.ParamByName('QRBASE64').AsString  := AResultado.QRCodeBase64;
      Qry.ParamByName('QRPNG').DataType     := ftBlob;
      if Length(AResultado.QRCodePng) > 0 then
      begin
        oPngStream := TBytesStream.Create(AResultado.QRCodePng);
        try
          Qry.ParamByName('QRPNG').LoadFromStream(oPngStream, ftBlob);
        finally
          FreeAndNil(oPngStream);
        end;
      end
      else
        Qry.ParamByName('QRPNG').Clear;
      Qry.ParamByName('ESTADO').AsString    := sEstadoFaccon;
      Qry.ParamByName('RESPUESTA').AsString :=
        AResultado.RespuestaCompleta;
      Qry.ParamByName('PETICION').AsString :=
        AResultado.PeticionCompleta;
      Qry.ParamByName('REGISTROXML').AsString :=
        AResultado.RegistroXmlFirmado;
      Qry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
      Qry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
      Qry.ParamByName('TITULARCERT').AsString :=
        AResultado.TitularCertificado;
      Qry.ParamByName('HUELLACERT').AsString :=
        AResultado.HuellaCertificado;
      Qry.Execute;
    end;
    // Estado fiscal de la factura
    Qry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET ESCONSOLIDADA_FAC = ''S'', ' +
      '     INSTANTECONSO_FAC = NOW(), ' +
      '     FASE_FAC = :FASE, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE SERIE_FAC  = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    Qry.ParamByName('FASE').AsString    := sFase;
    Qry.ParamByName('USUARIO').AsString := oUser;
    Qry.ParamByName('SERIE').AsString   := ASerie;
    Qry.ParamByName('NUMERO').AsString  := ANumero;
    Qry.Execute;
    // Cola: fila enviada. El mensaje informativo se conserva cuando la
    // AEAT acepta con errores.
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''ENVIADA'', ' +
      '     INSTANTE_ENVIO_VFCOLA = NOW(), ' +
      '     MENSAJE_ERROR_VFCOLA = NULLIF(:MENSAJE, ''''), ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID';
    Qry.ParamByName('MENSAJE').AsString := AResultado.MensajeError;
    Qry.ParamByName('USUARIO').AsString := oUser;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(FConn, cEventoVerifactuEnvioOk,
    'Registro de facturación (' + ATipoOperacion + ') aceptado por la ' +
    'AEAT (' + AResultado.EstadoRegistro + ')',
    'CSV: ' + AResultado.RequestId, ASerie, ANumero);
end;

procedure THiloVerifactuCola.GuardarEnvioError(AIdCola: Int64;
                                               const ASerie, ANumero,
                                               AMensaje: string;
                                               AIntentos: Integer);
var
  Qry:          TUniQuery;
  iMaxIntentos: Integer;
  iEspera:      Integer;
  sEstado:      string;
begin
  iMaxIntentos := oAppParams.GetInt('appVerifactuMaxIntentos', 10);
  // Backoff exponencial 60s * 2^intentos con techo en 32 minutos
  if AIntentos > 5 then
    iEspera := 60 * 32
  else
    iEspera := 60 * (1 shl AIntentos);
  if (AIntentos + 1) >= iMaxIntentos then
    sEstado := 'ERROR'
  else
    sEstado := 'PENDIENTE';
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = :ESTADO, ' +
      '     CONTADOR_INTENTOS_VFCOLA = CONTADOR_INTENTOS_VFCOLA + 1, ' +
      '     INSTANTE_PROXIMO_INTENTO_VFCOLA = ' +
      '         DATE_ADD(NOW(), INTERVAL :ESPERA SECOND), ' +
      '     MENSAJE_ERROR_VFCOLA = :MENSAJE, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID';
    Qry.ParamByName('ESTADO').AsString  := sEstado;
    Qry.ParamByName('ESPERA').AsInteger := iEspera;
    Qry.ParamByName('MENSAJE').AsString := AMensaje;
    Qry.ParamByName('USUARIO').AsString := oUser;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
    if sEstado = 'ERROR' then
    begin
      // Reintentos agotados: se refleja en la fase fiscal de la factura
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FASE_FAC = ''ERROR'', ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('SERIE').AsString   := ASerie;
      Qry.ParamByName('NUMERO').AsString  := ANumero;
      Qry.Execute;
    end;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(FConn, cEventoVerifactuEnvioError,
    'Error de envío Verifactu (intento ' + IntToStr(AIntentos + 1) +
    '): ' + AMensaje, '', ASerie, ANumero);
end;

end.
