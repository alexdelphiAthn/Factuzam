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
  System.SysUtils, System.Classes, Uni, inLibConexionesIntf,
  inLibParametrosIntf, inLibContextoSesionIntf,
  inLibEmisionFiscalIntf;

type
  TVerifactuCola = class
  public
    // Encola el registro de una factura. AQryTrx participa en la
    // transacción de la grabación de la venta: factura y cola se
    // confirman o deshacen juntas.
    class procedure EncolarFactura(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   const AParametrosCaja: IParametrosCaja;
                                   AQryTrx: TUniQuery;
                                   const AUsuario: string;
                                   const ASerie, ANumero: string;
                                   const ATipoOperacion: string = 'ALTA';
                                   ABorrarMovimientos: Boolean = True);
    // Genera y guarda el registro de facturación firmado sin enviarlo a AEAT.
    // Es el camino NO VERI*FACTU y debe ejecutarse al crear la factura.
    class procedure RegistrarFacturaNoVerifactu(
                                               const AParametrosApp:
                                               IParametrosAplicacion;
                                               const AParametrosCaja:
                                               IParametrosCaja;
                                               AQryTrx: TUniQuery;
                                               const AUsuario: string;
                                               const ASerie,
                                               ANumero: string;
                                               const ATipoOperacion: string =
                                               'ALTA';
                                               ABorrarMovimientos: Boolean =
                                               True);
    // Modo transitorio sin Verifactu: emite la factura con fase propia,
    // sin cola AEAT y sin registro NO VERI*FACTU.
    class procedure MarcarFacturaSinVerifactu(
                                             const AParametrosApp:
                                             IParametrosAplicacion;
                                             const AParametrosCaja:
                                             IParametrosCaja;
                                             AQryTrx: TUniQuery;
                                             const AUsuario: string;
                                             const ASerie,
                                             ANumero: string;
                                             const ATipoOperacion: string =
                                             'ALTA';
                                             ABorrarMovimientos: Boolean =
                                             True);
    // Revierte los movimientos vinculados a una factura de caja (VE) o
    // creada desde el mantenimiento (FC). El SP mantiene stock y acumulados.
    class procedure BorrarMovimientosFactura(AQry: TUniQuery;
                                             const ASerie,
                                             ANumero: string);
    // Marca una factura recién abonada como RECTIFICATIVA, la enlaza con
    // la original (columnas ABONO) y la encola en Verifactu si está
    // activo. La llama el modal de Rectificar de Facturas.
    class procedure EncolarRectificativa(
                                         const AParametrosApp:
                                         IParametrosAplicacion;
                                         const AParametrosCaja:
                                         IParametrosCaja;
                                         AConn: TUniConnection;
                                         const AServicioEmision:
                                         IServicioEmisionFiscal;
                                         const AUsuario: string;
                                         const ASerieOriginal,
                                         ANumeroOriginal,
                                         ASerieRect, ANumeroRect: string;
                                         const ATipoRectificativa: string =
                                         'I';
                                         ABorrarMovimientosOriginales:
                                         Boolean = False);
    // Histórico N:1 de rectificaciones/sustituciones
    // (fza_facturas_relaciones): cada hija guarda su factura de origen
    class procedure RegistrarRelacionFactura(AConn: TUniConnection;
                                             const AUsuario: string;
                                             const ASerie, ANumero,
                                             ASerieOrigen, ANumeroOrigen,
                                             ATipoRelacion: string);
    // Arranque tras el logon y parada al cerrar (ver inMtoPrincipal)
    class procedure IniciarHilo(
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario: string);
    class procedure DetenerHilo;
  end;

implementation

uses
  Winapi.Windows, Data.DB,
  inLibLog, inLibMsg,
  inLibVerifactu, inLibVerifactuEnvio, inLibRelojFiscal,
  inLibVentasWsCola;

const
  fidvfcola       = 'ID_VFCOLA';
  fserievfcola    = 'SERIE_FAC_VFCOLA';
  fnumerovfcola   = 'NUMERO_FAC_VFCOLA';
  ftipoopvfcola   = 'TIPO_OPERACION_VFCOLA';
  fintentosvfcola = 'CONTADOR_INTENTOS_VFCOLA';

type
  // Worker: despierta cada appVerifactuSegundosCiclo segundos, reclama
  // filas PENDIENTE y delega el envío en inLibVerifactuEnvio. Solicita
  // una conexión propia al servicio: la principal no se comparte.
  THiloVerifactuCola = class(TThread)
  private
    FConn:              TUniConnection;
    FConexiones:        IServicioConexiones;
    FContextoSesion:    IContextoSesionAplicacion;
    FParametrosApp:     IParametrosAplicacion;
    FParametrosCaja:    IParametrosCaja;
    FUsuario:           string;
    FAvisoNoDisponible: Boolean;
    function PuedeContinuar: Boolean;
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
    constructor Create(
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario: string); reintroduce;
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

class procedure TVerifactuCola.BorrarMovimientosFactura(
  AQry: TUniQuery; const ASerie, ANumero: string);
begin
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    AQry.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    AQry.ParamByName('t').AsString := 'VE';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
    AQry.SQL.Text :=
      'UPDATE fza_facturas_lineas ' +
      '   SET NUMERO_MOV_FACLIN = NULL ' +
      ' WHERE SERIE_FAC_FACLIN = :s ' +
      '   AND NUMERO_FAC_FACLIN = :n';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
    AQry.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    AQry.ParamByName('t').AsString := 'FC';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
  end;
end;

procedure RegistrarIncidenciaNoVerifactuSeguro(
                                               const AParametrosApp:
                                               IParametrosAplicacion;
                                               AConn: TUniConnection;
                                               const AUsuario: string;
                                               ATipoEvento: Integer;
                                               const ADescripcion,
                                               AMensaje, ASerie,
                                               ANumero: string);
begin
  try
    RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
      ATipoEvento, ADescripcion, AMensaje, ASerie, ANumero);
  except
    on E: Exception do
    begin
      Log.LogError('No se pudo registrar la incidencia NO VERI*FACTU: ' +
                   E.Message);
    end;
  end;
end;

procedure ActualizarCadenaNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero: string;
  const AResultado: TResultadoEnvioVerifactu);
begin
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
  AQry.ParamByName('USUARIO').AsString  := AUsuario;
  AQry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
  AQry.Execute;
end;

function ObtenerEstadoRegistroNoVerifactu(
  const ATipoOperacion: string): string;
begin
  if ATipoOperacion = 'ANULACION' then
    Result := 'NOVERIF_ANULADO'
  else if ATipoOperacion = 'SUBSANACION' then
    Result := 'NOVERIF_SUBSANADO'
  else
    Result := 'NOVERIF_REGISTRADO';
end;

procedure PrepararActualizacionAnulacionNoVerifactu(
  AQry: TUniQuery);
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
end;

procedure PrepararAltaConsolidacionNoVerifactu(
  AQry: TUniQuery);
begin
  AQry.SQL.Text :=
    ' INSERT INTO fza_facturas_consolidaciones ' +
    ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
    '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
    '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
    '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
    '  QRCODE_PNG_FACCON, ' +
    '  FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
    '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
    '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
    '  HUELLA_CERTIFICADO_FACCON) ' +
    ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
    '        :ISSUERID, :ISSUEDTIME, :CHAINNUM, :CHAINHASH, ' +
    '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), :QRPNG, ' +
    '        NOW(), :ESTADO, :REGISTROXML, :FIRMA, :SERIECERT, ' +
    '        :TITULARCERT, :HUELLACERT ' +
    ' FROM fza_facturas_consolidaciones ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  ESTADO_FACCON = VALUES(ESTADO_FACCON), ' +
    '  CHAIN_NUMBER_FACCON = VALUES(CHAIN_NUMBER_FACCON), ' +
    '  CHAIN_HASH_FACCON = VALUES(CHAIN_HASH_FACCON), ' +
    '  VERIFACTU_URL_FACCON = VALUES(VERIFACTU_URL_FACCON), ' +
    '  QRCODE_BASE64_FACCON = VALUES(QRCODE_BASE64_FACCON), ' +
    '  QRCODE_PNG_FACCON = VALUES(QRCODE_PNG_FACCON), ' +
    '  REGISTRO_XML_FACCON = VALUES(REGISTRO_XML_FACCON), ' +
    '  FIRMA_DIGITAL_FACCON = VALUES(FIRMA_DIGITAL_FACCON), ' +
    '  SERIE_CERTIFICADO_FACCON = VALUES(SERIE_CERTIFICADO_FACCON), ' +
    '  TITULAR_CERTIFICADO_FACCON = ' +
    '    VALUES(TITULAR_CERTIFICADO_FACCON), ' +
    '  HUELLA_CERTIFICADO_FACCON = ' +
    '    VALUES(HUELLA_CERTIFICADO_FACCON)';
end;

procedure AsignarParametrosConsolidacionNoVerifactu(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
var
  oPngStream: TBytesStream;
begin
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.ParamByName('ISSUERID').AsString := AResultado.IssuerIrsId;
  AQry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
  AQry.ParamByName('ISSUEDTIME').AsDateTime := AResultado.IssuedTime;
  AQry.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
  AQry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
  AQry.ParamByName('ESTADO').AsString :=
    ObtenerEstadoRegistroNoVerifactu(ATipoOperacion);
  if ATipoOperacion <> 'ANULACION' then
  begin
    AQry.ParamByName('URL').AsString      := AResultado.VerifactuUrl;
    AQry.ParamByName('QRBASE64').AsString := AResultado.QRCodeBase64;
    AQry.ParamByName('QRPNG').DataType    := ftBlob;
    if Length(AResultado.QRCodePng) > 0 then
    begin
      oPngStream := TBytesStream.Create(AResultado.QRCodePng);
      try
        AQry.ParamByName('QRPNG').LoadFromStream(oPngStream, ftBlob);
      finally
        FreeAndNil(oPngStream);
      end;
    end
    else
      AQry.ParamByName('QRPNG').Clear;
  end;
  AQry.ParamByName('REGISTROXML').AsString :=
    AResultado.RegistroXmlFirmado;
  AQry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
  AQry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
  AQry.ParamByName('TITULARCERT').AsString :=
    AResultado.TitularCertificado;
  AQry.ParamByName('HUELLACERT').AsString :=
    AResultado.HuellaCertificado;
end;

procedure GuardarConsolidacionNoVerifactu(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
begin
  if ATipoOperacion = 'ANULACION' then
    PrepararActualizacionAnulacionNoVerifactu(AQry)
  else
    PrepararAltaConsolidacionNoVerifactu(AQry);
  AsignarParametrosConsolidacionNoVerifactu(
    AQry, ASerie, ANumero, ATipoOperacion, AResultado);
  AQry.Execute;
end;

procedure MarcarFacturaRegistradaNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string);
begin
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
    AQry.ParamByName('FASE').AsString := cFaseFacturaNoVerifactuAnulada
  else
    AQry.ParamByName('FASE').AsString := cFaseFacturaNoVerifactuOk;
  AQry.ParamByName('USUARIO').AsString := AUsuario;
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.Execute;
end;

procedure GuardarRegistroNoVerifactu(AQry: TUniQuery;
                                     const AUsuario: string;
                                     const ASerie, ANumero,
                                     ATipoOperacion: string;
                                     const AResultado:
                                     TResultadoEnvioVerifactu;
                                     ABorrarMovimientos: Boolean);
begin
  if not ColumnasFirmaFacturacionDisponibles(AQry.Connection) then
    raise Exception.Create(
      SErrorColumnasFirmaFacturacionNoDisponibles);
  ActualizarCadenaNoVerifactu(
    AQry, AUsuario, ASerie, ANumero, AResultado);
  GuardarConsolidacionNoVerifactu(
    AQry, ASerie, ANumero, ATipoOperacion, AResultado);
  MarcarFacturaRegistradaNoVerifactu(
    AQry, AUsuario, ASerie, ANumero, ATipoOperacion);
  if (ATipoOperacion = 'ANULACION') and ABorrarMovimientos then
    TVerifactuCola.BorrarMovimientosFactura(AQry, ASerie, ANumero);
end;

// ===========================================================================
//   TVerifactuCola — API pública
// ===========================================================================

class procedure TVerifactuCola.EncolarFactura(
                                              const AParametrosApp:
                                              IParametrosAplicacion;
                                              const AParametrosCaja:
                                              IParametrosCaja;
                                              AQryTrx: TUniQuery;
                                              const AUsuario: string;
                                              const ASerie, ANumero: string;
                                              const ATipoOperacion: string;
                                              ABorrarMovimientos: Boolean);
begin
  ValidarRequisitosFiscalesEmision(AParametrosApp, AQryTrx.Connection,
    ASerie, ANumero);
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
  AQryTrx.ParamByName('USUARIO').AsString := AUsuario;
  AQryTrx.Execute;
  if (ATipoOperacion = 'ANULACION') and ABorrarMovimientos then
    BorrarMovimientosFactura(AQryTrx, ASerie, ANumero);
  // El lanzamiento saca la factura de BORRADOR en el acto: el QR es
  // calculable en local (ConstruirUrlQR) y la petición al ws viaja
  // asíncrona en el hilo de la cola.
  if SameText(ATipoOperacion, 'ALTA') then
  begin
    AQryTrx.SQL.Text :=
      ' UPDATE fza_facturas ' +
      '    SET FASE_FAC = :FASE, ' +
      '        INSTANTE_MODIF = NOW(), ' +
      '        USUARIO_MODIF  = :USUARIO ' +
      '  WHERE SERIE_FAC  = :SERIE ' +
      '    AND NUMERO_FAC = :NUMERO ' +
      '    AND (FASE_FAC IS NULL OR ' +
      '         FASE_FAC IN ('''', ''BORRADOR'', ''ERROR'', ' +
      '                       ''VERIFACTU_ERROR''))';
    AQryTrx.ParamByName('SERIE').AsString   := ASerie;
    AQryTrx.ParamByName('NUMERO').AsString  := ANumero;
    AQryTrx.ParamByName('FASE').AsString    :=
      cFaseFacturaVerifactuPendiente;
    AQryTrx.ParamByName('USUARIO').AsString := AUsuario;
    AQryTrx.Execute;
  end;
  TVentasWsCola.RegistrarFactura(AParametrosCaja, AQryTrx, AUsuario,
    ASerie, ANumero, ATipoOperacion);
end;

class procedure TVerifactuCola.RegistrarFacturaNoVerifactu(
                                                           const
                                                           AParametrosApp:
                                                           IParametrosAplicacion;
                                                           const
                                                           AParametrosCaja:
                                                           IParametrosCaja;
                                                           AQryTrx: TUniQuery;
                                                           const AUsuario:
                                                           string;
                                                           const ASerie,
                                                           ANumero: string;
                                                           const ATipoOperacion:
                                                           string;
                                                           ABorrarMovimientos:
                                                           Boolean);
var
  oResultado: TResultadoEnvioVerifactu;
begin
  try
    ValidarRequisitosFiscalesEmision(AParametrosApp, AQryTrx.Connection,
      ASerie, ANumero);
    ExigirRelojFiscal(AParametrosApp,
      STextoRegistroFacturacionNoVerifactu);
    if not VerifactuFirmaCertificado(AParametrosApp) then
      raise Exception.Create(SErrorFirmaRegistroNoVerifactuObligatoria);
    oResultado := GenerarRegistroFacturaLocal(AParametrosApp,
      AQryTrx.Connection, AUsuario, ASerie, ANumero, ATipoOperacion);
    if not oResultado.Ok then
      raise Exception.Create(oResultado.MensajeError);
    GuardarRegistroNoVerifactu(AQryTrx, AUsuario, ASerie, ANumero,
      ATipoOperacion, oResultado, ABorrarMovimientos);
    RegistrarEventoVerifactu(AParametrosApp, AQryTrx.Connection, AUsuario,
      cEventoVerifactuInfo,
      'Registro de facturación NO VERI*FACTU registrado', ATipoOperacion,
      ASerie, ANumero);
    TVentasWsCola.RegistrarFactura(AParametrosCaja, AQryTrx, AUsuario,
      ASerie, ANumero, ATipoOperacion);
  except
    on E: Exception do
    begin
      if Pos('reloj', LowerCase(E.Message)) > 0 then
        RegistrarIncidenciaNoVerifactuSeguro(AParametrosApp,
          AQryTrx.Connection, AUsuario,
          cEventoNoVerifactuIncidenciaReloj,
          'Incidencia de reloj NO VERI*FACTU', E.Message, ASerie, ANumero)
      else
        RegistrarIncidenciaNoVerifactuSeguro(AParametrosApp,
          AQryTrx.Connection, AUsuario,
          cEventoNoVerifactuIncidenciaCert,
          'Incidencia de certificado NO VERI*FACTU', E.Message,
          ASerie, ANumero);
      raise;
    end;
  end;
end;

class procedure TVerifactuCola.MarcarFacturaSinVerifactu(
                                                         const
                                                         AParametrosApp:
                                                         IParametrosAplicacion;
                                                         const
                                                         AParametrosCaja:
                                                         IParametrosCaja;
                                                         AQryTrx: TUniQuery;
                                                         const AUsuario:
                                                         string;
                                                         const ASerie,
                                                         ANumero: string;
                                                         const ATipoOperacion:
                                                         string;
                                                         ABorrarMovimientos:
                                                         Boolean);
var
  sFase: string;
begin
  ValidarRequisitosFiscalesEmision(AParametrosApp, AQryTrx.Connection,
    ASerie, ANumero);
  if ATipoOperacion = 'ANULACION' then
    sFase := cFaseFacturaSinVerifactuAnulada
  else
    sFase := cFaseFacturaSinVerifactu;
  AQryTrx.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET ESCONSOLIDADA_FAC = ''S'', ' +
    '     INSTANTECONSO_FAC = NOW(), ' +
    '     FASE_FAC = :FASE, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  AQryTrx.ParamByName('FASE').AsString := sFase;
  AQryTrx.ParamByName('USUARIO').AsString := AUsuario;
  AQryTrx.ParamByName('SERIE').AsString := ASerie;
  AQryTrx.ParamByName('NUMERO').AsString := ANumero;
  AQryTrx.Execute;
  if (ATipoOperacion = 'ANULACION') and ABorrarMovimientos then
    BorrarMovimientosFactura(AQryTrx, ASerie, ANumero);
  Log.LogInfo('Factura ' + ASerie + '\' + ANumero +
    ' emitida en modo SIN VERIFACTU. Operación: ' + ATipoOperacion);
  TVentasWsCola.RegistrarFactura(AParametrosCaja, AQryTrx, AUsuario,
    ASerie, ANumero, ATipoOperacion);
end;

class procedure TVerifactuCola.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario: string;
  const ASerieOriginal, ANumeroOriginal, ASerieRect, ANumeroRect: string;
  const ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
var
  Qry: TUniQuery;
  sComentario: string;
  sTipoRectificativa: string;
  Solicitud: TSolicitudEmisionFiscal;
begin
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  sTipoRectificativa := UpperCase(Trim(ATipoRectificativa));
  if (sTipoRectificativa <> 'I') and
     (sTipoRectificativa <> 'S') then
    raise Exception.Create(
      'El tipo fiscal de rectificativa debe ser I o S.');
  if sTipoRectificativa = 'S' then
    sComentario := ' ESTA FACTURA RECTIFICA POR SUSTITUCIÓN A LA '
  else
    sComentario := ' ESTA FACTURA RECTIFICA POR DIFERENCIAS A LA ';
  // Guarda: una rectificativa sin serie/numero validos (p.ej. '0'/'0' por
  // una cabecera de caja que no se vuelca) encolaria un registro fantasma
  // que la AEAT rechaza y rompe el enlace ABONO de la original. Se deja
  // constancia en el log y no se toca nada mas.
  if (Trim(ASerieRect) = '') or (Trim(ASerieRect) = '0') or
     (Trim(ANumeroRect) = '') or (Trim(ANumeroRect) = '0') then
    RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
      cEventoVerifactuEnvioError,
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
        '     TIPO_RECTIFICATIVA_FAC = :TIPORECT, ' +
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
        sComentario + ASerieOriginal + '\' + ANumeroOriginal;
      Qry.ParamByName('TIPORECT').AsString := sTipoRectificativa;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
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
      Qry.ParamByName('USUARIO').AsString    := AUsuario;
      Qry.ParamByName('SERIE').AsString      := ASerieOriginal;
      Qry.ParamByName('NUMERO').AsString     := ANumeroOriginal;
      Qry.Execute;
      // Histórico N:1: cada rectificativa conserva su propio enlace
      // aunque la original se rectifique varias veces
      RegistrarRelacionFactura(AConn, AUsuario, ASerieRect, ANumeroRect,
        ASerieOriginal, ANumeroOriginal, 'RECTIFICA');
      if (sTipoRectificativa = 'S') and
         ABorrarMovimientosOriginales then
      begin
        BorrarMovimientosFactura(Qry, ASerieOriginal, ANumeroOriginal);
      end;
      Solicitud := TSolicitudEmisionFiscal.ParaAlta(
        ASerieRect,
        ANumeroRect,
        AUsuario,
        'Rectificativa de ' + ASerieOriginal + '\' + ANumeroOriginal +
        ' tipo ' + sTipoRectificativa +
        ' encolada desde Facturas');
      AServicioEmision.Emitir(Solicitud);
      // El webservice conserva el histórico, pero deja la original fuera
      // de las ventas activas cuando la rectificación es sustitutiva.
      if sTipoRectificativa = 'S' then
      begin
        TVentasWsCola.RegistrarFactura(AParametrosCaja, Qry, AUsuario,
          ASerieOriginal, ANumeroOriginal, 'SUSTITUCION');
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

class procedure TVerifactuCola.RegistrarRelacionFactura(
                                  AConn: TUniConnection;
                                  const AUsuario: string;
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
    Qry.ParamByName('USUARIO').AsString    := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

class procedure TVerifactuCola.IniciarHilo(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string);
begin
  if oHiloCola = nil then
  begin
    oHiloCola := THiloVerifactuCola.Create(
      AConexiones,
      AContextoSesion,
      AParametrosApp,
      AParametrosCaja,
      AUsuario);
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

constructor THiloVerifactuCola.Create(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario: string);
begin
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  inherited Create(True);
  FConexiones := AConexiones;
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FUsuario := AUsuario;
end;

destructor THiloVerifactuCola.Destroy;
begin
  FreeAndNil(FConn);
  FParametrosCaja := nil;
  FParametrosApp := nil;
  FContextoSesion := nil;
  FConexiones := nil;
  inherited;
end;

procedure THiloVerifactuCola.Execute;
begin
  NameThreadForDebugging('VerifactuCola');
  FAvisoNoDisponible := False;
  while (not Terminated) and (not FContextoSesion.CerrandoAplicacion) do
  begin
    // La espera va primero: deja respirar el arranque de la app y
    // permite cerrar sin procesar nada a medias
    EsperarCiclo;
    if (not Terminated) and (not FContextoSesion.CerrandoAplicacion) and
       (ModoVerifactu(FParametrosApp) = mvVerifactu) then
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
  iSegundos := FParametrosApp.GetInt('appVerifactuSegundosCiclo', 60);
  if iSegundos < 5 then
    iSegundos := 5;
  EsperarSegundos(iSegundos);
end;

function THiloVerifactuCola.PuedeContinuar: Boolean;
begin
  Result := not Terminated;
  if Result then
    Result := not FContextoSesion.CerrandoAplicacion;
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
  while (iPaso < iPasos) and PuedeContinuar do
  begin
    Sleep(100);
    Inc(iPaso);
  end;
end;

procedure THiloVerifactuCola.ProcesarPendientes;
var
  Qry:     TUniQuery;
  iEspera: Integer;
begin
  if FConn = nil then
    FConn := FConexiones.CrearConexion(
      nil,
      uctSegundoPlano);
  if not EnvioVerifactuDisponible then
  begin
    // Cliente de envío desactivado: la cola se acumula en PENDIENTE.
    // Se deja constancia una sola vez por sesión.
    if not FAvisoNoDisponible then
    begin
      RegistrarEventoVerifactu(FParametrosApp, FConn, FUsuario,
        cEventoVerifactuInfo,
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
        FParametrosApp.GetInt('appVerifactuMaxIntentos', 10);
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
      while (not Qry.Eof) and PuedeContinuar do
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
    Qry.ParamByName('USUARIO').AsString := FUsuario;
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
      oResultado := EnviarRegistroFactura(FParametrosApp, FConn,
        FUsuario, ASerie, ANumero, ATipoOperacion);
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
    sFase := cFaseFacturaVerifactuAnulada
  else
    sFase := cFaseFacturaVerifactuOk;
  if SameText(AResultado.EstadoRegistro, 'AceptadoConErrores') then
    sEstadoFaccon := 'VERIFACTU_ACEPT_ERR'
  else if SameText(AResultado.EstadoRegistro, 'Duplicado') then
    sEstadoFaccon := 'VERIFACTU_DUPLICADO'
  else if ATipoOperacion = 'SUBSANACION' then
    sEstadoFaccon := 'VERIFACTU_SUBSANADO'
  else
    sEstadoFaccon := 'VERIFACTU_PROCESADO';
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
    Qry.ParamByName('USUARIO').AsString  := FUsuario;
    Qry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
    Qry.Execute;
    bInsertarAlta := (ATipoOperacion <> 'ANULACION');
    if ATipoOperacion = 'ANULACION' then
    begin
      // La anulación actualiza la consolidación del alta (UK_FACTURA)
      Qry.SQL.Text :=
        ' UPDATE fza_facturas_consolidaciones ' +
        ' SET QUEUE_ID_CANCEL_FACCON = :IDCOLA, ' +
        '     ESTADO_FACCON = ''VERIFACTU_ANULADO'', ' +
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
    Qry.ParamByName('USUARIO').AsString := FUsuario;
    Qry.ParamByName('SERIE').AsString   := ASerie;
    Qry.ParamByName('NUMERO').AsString  := ANumero;
    Qry.Execute;
    // Los movimientos se resuelven al solicitar la anulación, cuando el
    // usuario decide si desea revertir el stock. No se repite aquí porque
    // el hilo no conserva esa elección.
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
    Qry.ParamByName('USUARIO').AsString := FUsuario;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(FParametrosApp, FConn, FUsuario,
    cEventoVerifactuEnvioOk,
    'Registro de facturación (' + ATipoOperacion + ') aceptado por la ' +
    'AEAT (' + AResultado.EstadoRegistro + ')',
    'CSV: ' + AResultado.RequestId, ASerie, ANumero);
  TVentasWsCola.RegistrarEventoSeguro(FParametrosCaja, FConn, FUsuario,
    'FISCAL_ACTUALIZADO', ASerie, ANumero);
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
  iMaxIntentos := FParametrosApp.GetInt('appVerifactuMaxIntentos', 10);
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
    Qry.ParamByName('USUARIO').AsString := FUsuario;
    Qry.ParamByName('ID').AsLargeInt    := AIdCola;
    Qry.Execute;
    if sEstado = 'ERROR' then
    begin
      // Reintentos agotados: se refleja en la fase fiscal de la factura
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FASE_FAC = :FASE, ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('FASE').AsString := cFaseFacturaVerifactuError;
      Qry.ParamByName('USUARIO').AsString := FUsuario;
      Qry.ParamByName('SERIE').AsString   := ASerie;
      Qry.ParamByName('NUMERO').AsString  := ANumero;
      Qry.Execute;
    end;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(FParametrosApp, FConn, FUsuario,
    cEventoVerifactuEnvioError,
    'Error de envío Verifactu (intento ' + IntToStr(AIntentos + 1) +
    '): ' + AMensaje, '', ASerie, ANumero);
  TVentasWsCola.RegistrarEventoSeguro(FParametrosCaja, FConn, FUsuario,
    'FISCAL_ACTUALIZADO', ASerie, ANumero);
end;

end.
