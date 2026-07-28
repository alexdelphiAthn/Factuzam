{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConn                                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/03/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para realizar la conexión     }
{    principal de todos los datos, por aquí pasa todo desde que se hizo login. }
{******************************************************************************}
unit UniDataConn;

interface

uses
  SysUtils, Classes, ADODB, DBAccess, Uni, inLibUser, vcl.Controls,
  UniProvider, MySQLUniProvider, DASQLMonitor, UniSQLMonitor, vcl.Dialogs,
  inLibMonitorSQLIntf, inLibParametrosIntf;

type
  TdmConn = class(TDataModule)
    conUni: TUniConnection;
    mysqlnprvdr1: TMySQLUniProvider;
    UniSQLMonitor1: TUniSQLMonitor;
    procedure connBeforeConnect(Sender: TObject);
    procedure UniSQLMonitor1SQL(Sender: TObject; Text: string;
      Flag: TDATraceFlag);
    procedure DataModuleCreate(Sender: TObject);
    procedure conUniError(Sender: TObject; E: EDAError; var Fail: Boolean);
    procedure conUniAfterConnect(Sender: TObject);
  private
    FParametrosApp: IParametrosAplicacion;
    FReceptorMonitorSQL: IReceptorEventosMonitorSQL;
  public
    destructor Destroy; override;
    procedure AsignarParametrosApp(
      const AParametrosApp: IParametrosAplicacion);
    procedure AsignarReceptorMonitorSQL(
      const AReceptor: IReceptorEventosMonitorSQL);
  end;

var
  dmConn: TdmConn;

implementation

uses inLibDir,
     inLibtb,
     inLibConexionesUniDAC,
     inLibWin,
     inLibLog,
     inLibMsg;

{$R *.dfm}

procedure TdmConn.AsignarParametrosApp(
  const AParametrosApp: IParametrosAplicacion);
begin
  FParametrosApp := AParametrosApp;
end;

procedure TdmConn.AsignarReceptorMonitorSQL(
  const AReceptor: IReceptorEventosMonitorSQL);
begin
  FReceptorMonitorSQL := AReceptor;
end;

destructor TdmConn.Destroy;
var
  ServicioMonitorSQL: IServicioMonitorSQL;
begin
  if Supports(
       FReceptorMonitorSQL,
       IServicioMonitorSQL,
       ServicioMonitorSQL) then
    ServicioMonitorSQL.Invalidar;
  FReceptorMonitorSQL := nil;
  FParametrosApp := nil;
  inherited;
end;

procedure TdmConn.connBeforeConnect(Sender: TObject);
var
  sDatabase,
  sHostName,
  sPasswordEn,
  sPort,
  sUser: string;
begin
  sDatabase := leCadINIDir('ConnData', 'Database','factuzam', GetUserFolder);
  sHostName :=  leCadINIDir('ConnData', 'HostName','127.0.0.1', GetUserFolder);
  sPasswordEn := DecriptAES(leCadINIDir('ConnData',
                            'PasswordEn',
                            '2qJFaDfegP/9y6RDno1FRg==',
                            GetUserFolder));
  sPort :=  leCadINIDir('ConnData', 'Puerto','3310', GetUserFolder);
  sUser :=  leCadINIDir('ConnData', 'User', 'root', GetUserFolder);
  with Conuni do
  begin
    Pooling := True;
    PoolingOptions.Validate := False;
    PoolingOptions.ConnectionLifetime := 0;
    SpecificOptions.Values['MySQL.Interactive'] := 'True';
    SpecificOptions.Values['ConnectionTimeout'] := '30';
    // 3. LA CLAVE: AUTO-RECONEXIÓN (LocalFailover)
    // Esto hace que si se cae la red o el servidor patea la conexión,
    // UniDAC se reconecta sola y reintenta la consulta sin dar error al
    // usuario.
    Options.LocalFailover := True;
    Options.DisconnectedMode := True;
  end;
  ConfigurarConexionMySQL(
    conUni,
    sUser,
    sPasswordEn,
    sHostName,
    sPort,
    sDatabase);
end;

procedure TdmConn.conUniAfterConnect(Sender: TObject);
var
  Con: TUniConnection;
begin
  // Este handler lo reutilizan las conexiones clonadas (inMtoGen), así
  // que los SET de sesión se aplican a la conexión que dispara el
  // evento, no siempre a conUni.
  if Sender is TUniConnection then
    Con := TUniConnection(Sender)
  else
    Con := conUni;
  // Colación de la sesión = la de la BBDD (utf8mb4_spanish_ci). UniDAC
  // negocia SET NAMES utf8mb4 con la colación por defecto del servidor
  // (en MariaDB moderno utf8mb4_uca1400_ai_ci) y cualquier SQL que cree
  // temporales/derivadas (CTEs, CAST, UNION...) hereda esa colación y
  // lanza [1267] Illegal mix of collations al compararla con las
  // columnas spanish_ci de las tablas. Se reaplica en cada reconexión.
  try
    Con.ExecSQL('SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
  except
    on E: Exception do
      {$IFDEF DEBUG}
      ShowMessage(Format(SAvisoColacionSesion, [E.Message]));
      {$ENDIF}
  end;
  // Ejecutamos un comando SQL directo al servidor nada más conectar.
  // 28800 segundos = 8 horas.
  try
    Con.ExecSQL('SET SESSION wait_timeout = 28800, '+
                'session interactive_timeout = 28800');
  except
    // Si falla (por permisos), no bloqueamos la app, pero queda registrado.
    on E: Exception do
      {$IFDEF DEBUG}
      ShowMessage(Format(SAvisoTimeoutServidor, [E.Message]));
      {$ENDIF}
  end;
end;

procedure TdmConn.conUniError(Sender: TObject; E: EDAError; var Fail: Boolean);
var
  sMensaje: string;
  bEsErrorGenerico: Boolean;
begin
  bEsErrorGenerico := False;
  case E.ErrorCode of
    1062: sMensaje := SErrorBBDDDuplicado;
    1048,
    1364: sMensaje := SErrorBBDDCamposObligatorios;
    1054: sMensaje := Format(SErrorBBDDCampoDesconocido, [E.Message]);
    1146: sMensaje := Format(SErrorBBDDTablaNoExiste, [E.Message]);
    1142,
    1143: sMensaje := SErrorBBDDSinPermisos;
    1216,
    1452: sMensaje := SErrorBBDDClaveForaneaNoExiste;
    1217,
    1451: sMensaje := SErrorBBDDRegistroDependiente;
    1406: sMensaje := SErrorBBDDDatoDemasiadoLargo;
    1045: sMensaje := SErrorBBDDCredencialesIncorrectas;
    2003: sMensaje := SErrorBBDDConexionServidor;
    2006: sMensaje := SErrorBBDDConexionPerdida;
    2013: sMensaje := SErrorBBDDConexionPerdidaConsulta;
    1205: sMensaje := SErrorBBDDTimeoutBloqueo;
    1213: sMensaje := SErrorBBDDDeadlock;
    1050: sMensaje := Format(SErrorBBDDTablaYaExiste, [E.Message]);
    1304:
      begin
        // Opción rápida y sencilla: Adjuntamos el mensaje original de MySQL
        // que contiene el nombre del procedimiento.
        sMensaje := Format(SErrorBBDDProcedimientoYaExiste, [E.Message]);
      end;
  else
    // Errores no catalogados: mostrar mensaje original
    sMensaje := Format(SErrorBBDDGenerico, [E.ErrorCode, E.Message]);
    bEsErrorGenerico := True;
  end;
  // En DEBUG o si el usuario activó appModoDebug, anexamos el error MySQL
  // original al mensaje mostrado para facilitar el diagnóstico.
  if {$IFDEF DEBUG}True{$ELSE}
      (Assigned(FParametrosApp) and
       FParametrosApp.GetBool('appModoDebug', False)){$ENDIF} then
  begin
    if (not bEsErrorGenerico) and (E.ErrorCode <> 0) then
      sMensaje := sMensaje + Format(SDetalleErrorMySQL,
                                    [E.ErrorCode, E.Message]);
  end;
  // Guardamos en el log siempre el error real
  inLibLog.Log.LogError(Format('MySQL %d: %s', [E.ErrorCode, E.Message]));
  Fail := False;
  raise Exception.Create(sMensaje);
end;

procedure TdmConn.DataModuleCreate(Sender: TObject);
begin
  // El monitor se queda activo siempre; el filtrado real lo hace TLog
  // segun IsLogTypeEnabled(ltSQL). El estado del monitor lo reajusta
  // inLibLog.AplicarModosDepuracion cuando se cargan/cambian los flags.
  UniSQLMonitor1.Active := True;
end;

procedure TdmConn.UniSQLMonitor1SQL(Sender: TObject; Text: string;
  Flag: TDATraceFlag);
var
  Evento: TEventoMonitorSQL;
begin
  Evento := emsOtro;
  case Flag of
    tfQExecute:
      Evento := emsEjecutar;
    tfConnect, tfQFetch, tfObjDestroy:
      Evento := emsFinalizar;
    tfError:
      Evento := emsError;
  end;
  if Assigned(FReceptorMonitorSQL) then
    FReceptorMonitorSQL.ProcesarEvento(Text, Evento);
end;

end.
