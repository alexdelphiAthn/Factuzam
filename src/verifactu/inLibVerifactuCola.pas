{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuCola                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de envío Verifactu (fza_verifactu_cola): encolado de la factura      }
{    al grabar la venta e hilo en segundo plano que procesa la cola, envía     }
{    los registros a la AEAT y persiste la consolidación.                      }
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
    procedure ProcesarFila(AIdCola: Int64;
                           const ASerie, ANumero, ATipoOperacion: string;
                           AIntentos: Integer);
    procedure GuardarEnvioOk(AIdCola: Int64;
                             const ASerie, ANumero, ATipoOperacion: string;
                             const AResultado: TResultadoEnvioVerifactu);
    procedure GuardarEnvioError(AIdCola: Int64;
                                const ASerie, ANumero, AMensaje: string;
                                AIntentos: Integer);
    procedure EsperarCiclo;
  protected
    procedure Execute; override;
  public
    destructor Destroy; override;
  end;

var
  oHiloCola: THiloVerifactuCola = nil;

// ===========================================================================
//   TVerifactuCola — API pública
// ===========================================================================

class procedure TVerifactuCola.EncolarFactura(AQryTrx: TUniQuery;
                                              const ASerie, ANumero: string;
                                              const ATipoOperacion: string);
begin
  // ON DUPLICATE: si la factura ya estaba encolada no se duplica la
  // fila; solo se refresca la auditoría
  AQryTrx.SQL.Text :=
    ' INSERT INTO fza_verifactu_cola ' +
    ' (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, TIPO_OPERACION_VFCOLA, ' +
    '  ESTADO_VFCOLA, CONTADOR_INTENTOS_VFCOLA, INSTANTE_ALTA, ' +
    '  USUARIO_ALTA) ' +
    ' VALUES ' +
    ' (:SERIE, :NUMERO, :TIPOOP, ''PENDIENTE'', 0, NOW(), :USUARIO) ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF  = :USUARIO';
  AQryTrx.ParamByName('SERIE').AsString   := ASerie;
  AQryTrx.ParamByName('NUMERO').AsString  := ANumero;
  AQryTrx.ParamByName('TIPOOP').AsString  := ATipoOperacion;
  AQryTrx.ParamByName('USUARIO').AsString := oUser;
  AQryTrx.Execute;
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
  iPasos: Integer;
  iPaso:  Integer;
begin
  iPasos := oAppParams.GetInt('appVerifactuSegundosCiclo', 60);
  if iPasos < 5 then
    iPasos := 5;
  // Espera troceada en pasos de 100 ms para reaccionar rápido a la parada
  iPasos := iPasos * 10;
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
  Qry: TUniQuery;
begin
  if FConn = nil then
    FConn := CrearConexionPropia;
  if not EnvioVerifactuDisponible then
  begin
    // Sin cliente de envío integrado la cola se acumula en PENDIENTE.
    // Se deja constancia una sola vez por sesión.
    if not FAvisoNoDisponible then
    begin
      RegistrarEventoVerifactu(FConn, cEventoVerifactuInfo,
        'Cola Verifactu activa sin cliente de envío AEAT integrado: ' +
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
        ProcesarFila(Qry.FieldByName(fidvfcola).AsLargeInt,
                     Qry.FieldByName(fserievfcola).AsString,
                     Qry.FieldByName(fnumerovfcola).AsString,
                     Qry.FieldByName(ftipoopvfcola).AsString,
                     Qry.FieldByName(fintentosvfcola).AsInteger);
        Qry.Next;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure THiloVerifactuCola.ProcesarFila(AIdCola: Int64;
                                          const ASerie, ANumero,
                                          ATipoOperacion: string;
                                          AIntentos: Integer);
var
  Qry:        TUniQuery;
  bReclamada: Boolean;
  oResultado: TResultadoEnvioVerifactu;
begin
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
    oResultado := EnviarRegistroFactura(FConn, ASerie, ANumero,
                                        ATipoOperacion);
    if oResultado.Ok then
      GuardarEnvioOk(AIdCola, ASerie, ANumero, ATipoOperacion, oResultado)
    else
      GuardarEnvioError(AIdCola, ASerie, ANumero,
                        oResultado.MensajeError, AIntentos);
  end;
end;

procedure THiloVerifactuCola.GuardarEnvioOk(AIdCola: Int64;
                                            const ASerie, ANumero,
                                            ATipoOperacion: string;
                                            const AResultado:
                                                  TResultadoEnvioVerifactu);
var
  Qry:   TUniQuery;
  sFase: string;
begin
  if ATipoOperacion = 'ANULACION' then
    sFase := 'CANCELADA'
  else
    sFase := 'ONLINE';
  FConn.StartTransaction;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := FConn;
      // Consolidación: misma estructura que rellena OdaVeriFactu
      Qry.SQL.Text :=
        ' INSERT INTO fza_facturas_consolidaciones ' +
        ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
        '  REQUEST_ID_CONSOLIDACION_FACCON, ' +
        '  QUEUE_ID_CONSOLIDACION_FACCON, ' +
        '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
        '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
        '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
        '  FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
        '  RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON) ' +
        ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
        '        NULLIF(:REQUESTID, ''''), NULLIF(:QUEUEID, 0), ' +
        '        NULLIF(:ISSUERID, ''''), :ISSUEDTIME, ' +
        '        NULLIF(:CHAINNUM, ''''), NULLIF(:CHAINHASH, ''''), ' +
        '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), NOW(), ' +
        '        ''PROCESADO'', NULLIF(:RESPUESTA, ''''), ' +
        '        NULLIF(:PETICION, '''') ' +
        ' FROM fza_facturas_consolidaciones';
      Qry.ParamByName('SERIE').AsString     := ASerie;
      Qry.ParamByName('NUMERO').AsString    := ANumero;
      Qry.ParamByName('REQUESTID').AsString := AResultado.RequestId;
      Qry.ParamByName('QUEUEID').AsInteger  := AResultado.QueueId;
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
      Qry.ParamByName('RESPUESTA').AsString := AResultado.RespuestaCompleta;
      Qry.ParamByName('PETICION').AsString  := AResultado.PeticionCompleta;
      Qry.Execute;
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
      // Cola: fila enviada
      Qry.SQL.Text :=
        ' UPDATE fza_verifactu_cola ' +
        ' SET ESTADO_VFCOLA = ''ENVIADA'', ' +
        '     INSTANTE_ENVIO_VFCOLA = NOW(), ' +
        '     MENSAJE_ERROR_VFCOLA = NULL, ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE ID_VFCOLA = :ID';
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('ID').AsLargeInt    := AIdCola;
      Qry.Execute;
      FConn.Commit;
    except
      on E: Exception do
      begin
        FConn.Rollback;
        raise;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
  RegistrarEventoVerifactu(FConn, cEventoVerifactuEnvioOk,
    'Registro de facturación (' + ATipoOperacion + ') enviado a la AEAT',
    '', ASerie, ANumero);
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
