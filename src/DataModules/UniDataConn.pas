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
  SysUtils, Classes, DB, ADODB, DBAccess, Uni, inLibUser, vcl.Controls,
  UniProvider, MySQLUniProvider, DASQLMonitor, UniSQLMonitor, vcl.Dialogs;

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
    // Estado para cronometrar entre tfQExecute y el siguiente flag que
    // indique fin (tfQOpen para SELECT, tfQClose para DML, tfQError...).
    // Si llega un nuevo tfQExecute antes de cerrar, se loguea el pendiente.
    FSQLStartMs   : Int64;
    FSQLActual    : string;
    FSQLPendiente : Boolean;
    procedure VolcarSQLPendiente(AOk: Boolean; const AError: string);
  public
    procedure ActualizarUserTimeModif(DataSet:TDataSet);
  end;

var
  dmConn: TdmConn;

implementation

uses inLibDir,
     inLibtb,
     inLibWin,
     inLibLog,
     inLibAppParam,
     inMtoPrincipal,
     inLibGlobalVar,
     Winapi.Windows;

{$R *.dfm}

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
  ConstruirConexion(conUni, sUser, sPasswordEn, sHostName, sPort, sDatabase);
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
      ShowMessage(
        'No se pudo fijar la colación de la sesión: ' + E.Message);
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
      ShowMessage(
        'No se pudo establecer el timeout del servidor: ' + E.Message);
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
    1062: sMensaje :=
      'Ya existe un registro con ese valor (entrada duplicada).';
    1048,
    1364: sMensaje := 'Hay campos obligatorios sin rellenar.';
    1054: sMensaje := 'Campo desconocido en la consulta SQL: ' + E.Message;
    1146: sMensaje :=
      'La tabla consultada no existe en la base de datos: ' + E.Message;
    1142,
    1143: sMensaje := 'No tiene permisos suficientes para realizar esta ' +
                      'acción en la base de datos.';
    1216,
    1452: sMensaje :=
      'El valor no existe en la tabla relacionada (clave foránea).';
    1217,
    1451: sMensaje :=
      'No se puede eliminar: existen registros que dependen de este.';
    1406: sMensaje := 'El dato introducido es demasiado largo para el campo.';
    1045: sMensaje := 'Acceso denegado: usuario o contraseña incorrectos.';
    2003: sMensaje :=
      'No se puede conectar al servidor MySQL. Comprueba la red y el puerto.';
    2006: sMensaje := 'La conexión con el servidor MySQL se ha perdido.';
    2013: sMensaje :=
      'Se perdió la conexión durante la ejecución de la consulta.';
    1205: sMensaje := 'El servidor está ocupado (Tiempo de espera de ' +
                      'bloqueo). Inténtalo de nuevo.';
    1213: sMensaje :=
      'Se ha producido un bloqueo cruzado (Deadlock). Inténtalo de nuevo.';
    1050: sMensaje :=
      'La tabla o vista ya existe en la base de datos ' + E.Message;
    1304:
      begin
        // Opción rápida y sencilla: Adjuntamos el mensaje original de MySQL
        // que contiene el nombre del procedimiento.
        sMensaje := 'El procedimiento o función ya existe en la base de datos.'
          + sLineBreak +
                    'Detalle del servidor: ' + E.Message;
      end;
  else
    // Errores no catalogados: mostrar mensaje original
    sMensaje := Format('Error en base de datos [%d]:%s%s',
                       [E.ErrorCode, sLineBreak, E.Message]);
    bEsErrorGenerico := True;
  end;
  // En DEBUG o si el usuario activó appModoDebug, anexamos el error MySQL
  // original al mensaje mostrado para facilitar el diagnóstico.
  if {$IFDEF DEBUG}True{$ELSE}
      (Assigned(inLibAppParam.oAppParams) and
       inLibAppParam.oAppParams.GetBool('appModoDebug', False)){$ENDIF} then
  begin
    if (not bEsErrorGenerico) and (E.ErrorCode <> 0) then
      sMensaje := sMensaje + Format('%s(MySQL %d: %s)',
                                     [sLineBreak, E.ErrorCode, E.Message]);
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
  FSQLPendiente := False;
end;

procedure TdmConn.VolcarSQLPendiente(AOk: Boolean; const AError: string);
var
  ElapsedMs: Int64;
begin
  if not FSQLPendiente then
    Exit;
  ElapsedMs     := GetTickCount64 - FSQLStartMs;
  // -1 en filas: el UniSQLMonitor no expone RowsAffected en su evento.
  // Si un caller necesita la cifra exacta, debe llamar directamente a
  // Log.LogSQLExt desde el AfterExecute/AfterOpen de su query concreta.
  inLibLog.Log.LogSQLExt(FSQLActual, ElapsedMs, -1, AOk, AError);
  FSQLPendiente := False;
end;

procedure TdmConn.UniSQLMonitor1SQL(Sender: TObject; Text: string;
  Flag: TDATraceFlag);
begin
  if not inLibLog.Log.IsLogTypeEnabled(ltSQL) then
  begin
    // Tambien limpiamos el pendiente si lo hay para no arrastrar timing
    // entre sesiones de log activado/desactivado.
    FSQLPendiente := False;
    Exit;
  end;

  case Flag of
    tfQExecute:
      begin
        // Si quedaba uno sin cerrar (operacion sin tfQOpen/tfQClose),
        // lo volcamos antes de arrancar el nuevo cronometro.
        if FSQLPendiente then
          VolcarSQLPendiente(True, '');
        FSQLActual    := Text;
        FSQLStartMs   := GetTickCount64;
        FSQLPendiente := True;
      end;
    tfConnect, tfQFetch, tfObjDestroy:
      VolcarSQLPendiente(True, '');
    tfError:
      VolcarSQLPendiente(False, Text);
  end;

  // Dump al memo SQL en pantalla si esta visible (lo controla
  // AplicarModosDepuracion en funcion de los flags). No restringido a
  // DEBUG: si el usuario activo el modo SQL, ya esta autorizado.
  if Assigned(oMemoSQL) and oMemoSQL.Visible and (Flag = tfQExecute) then
    oMemoSQL.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + Text);
end;

procedure TdmConn.ActualizarUserTimeModif(DataSet:TDataSet);
begin
  if (DataSet.FindField('USUARIO_MODIF') <> nil) then
    DataSet.FieldbyName('USUARIO_MODIF').AsString:= oUser;
  if DataSet.State = dsInsert then
  begin
    if (DataSet.FindField('INSTANTE_ALTA') <> nil) then
      DataSet.FieldbyName('INSTANTE_ALTA').AsDateTime := Now;
    if (DataSet.FindField('USUARIO_ALTA') <> nil) then
      DataSet.FieldbyName('USUARIO_ALTA').AsString := oUser;
    if (DataSet.FindField('INSTANTE_MODIF') <> nil) then
      DataSet.FieldbyName('INSTANTE_MODIF').AsDateTime := Now;
  end;
end;

end.
