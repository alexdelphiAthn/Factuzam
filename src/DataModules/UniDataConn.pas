{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
    { Private declarations }
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
     inMtoPrincipal,
     inLibGlobalVar;

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
    // IMPORTANTE: 0 significa que la conexión física vive indefinidamente en el pool.
    //SpecificOptions.Values['ConnectionLifetime'] := '0';
    PoolingOptions.ConnectionLifetime := 0;
    PoolingOptions.Validate := True;
    // Pide al servidor usar 'interactive_timeout' en vez de 'wait_timeout'
    // Esto suele darte 8 horas (28800s) si el servidor lo permite.
    SpecificOptions.Values['MySQL.Interactive'] := 'True';
    // Tiempo máximo para intentar establecer la conexión inicial
    SpecificOptions.Values['ConnectionTimeout'] := '30';
    // 3. LA CLAVE: AUTO-RECONEXIÓN (LocalFailover)
    // Esto hace que si se cae la red o el servidor patea la conexión,
    // UniDAC se reconecta sola y reintenta la consulta sin dar error al usuario.
    Options.LocalFailover := True;
    Options.DisconnectedMode := True;
  end;
  ConstruirConexion(conUni, sUser, sPasswordEn, sHostName, sPort, sDatabase);
end;

procedure TdmConn.conUniAfterConnect(Sender: TObject);
begin
  // Ejecutamos un comando SQL directo al servidor nada más conectar.
  // 28800 segundos = 8 horas.
  try
    conUni.ExecSQL('SET SESSION wait_timeout = 28800, '+
                   'session interactive_timeout = 28800');
  except
    // Si falla (por permisos), no bloqueamos la app, pero queda registrado.
    on E: Exception do
      {$IFDEF DEBUG}
      ShowMessage('No se pudo establecer el timeout del servidor: ' + E.Message);
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
    1062: sMensaje := 'Ya existe un registro con ese valor (entrada duplicada).';
    1048,
    1364: sMensaje := 'Hay campos obligatorios sin rellenar.';
    1054: sMensaje := 'Campo desconocido en la consulta SQL.';
    1146: sMensaje := 'La tabla consultada no existe en la base de datos.';
    1142,
    1143: sMensaje := 'No tiene permisos suficientes para realizar esta acción en la base de datos.';
    1216,
    1452: sMensaje := 'El valor no existe en la tabla relacionada (clave foránea).';
    1217,
    1451: sMensaje := 'No se puede eliminar: existen registros que dependen de este.';
    1406: sMensaje := 'El dato introducido es demasiado largo para el campo.';
    1045: sMensaje := 'Acceso denegado: usuario o contraseña incorrectos.';
    2003: sMensaje := 'No se puede conectar al servidor MySQL. Comprueba la red y el puerto.';
    2006: sMensaje := 'La conexión con el servidor MySQL se ha perdido.';
    2013: sMensaje := 'Se perdió la conexión durante la ejecución de la consulta.';
    1205: sMensaje := 'El servidor está ocupado (Tiempo de espera de bloqueo). Inténtalo de nuevo.';
    1213: sMensaje := 'Se ha producido un bloqueo cruzado (Deadlock). Inténtalo de nuevo.';
  else
    // Errores no catalogados: mostrar mensaje original
    sMensaje := Format('Error en base de datos [%d]:%s%s', [E.ErrorCode, sLineBreak, E.Message]);
    bEsErrorGenerico := True;
  end;

  {$IFDEF DEBUG}
    // En debug mostramos el original SOLO si no lo hemos puesto ya en el 'else'
    if (not bEsErrorGenerico) and (E.ErrorCode <> 0) then
      sMensaje := sMensaje + Format('%s(MySQL %d: %s)', [sLineBreak, E.ErrorCode, E.Message]);
  {$ENDIF}

  // Guardamos en el log siempre el error real
  inLibLog.Log.LogError(Format('MySQL %d: %s', [E.ErrorCode, E.Message]));

  // --- Opciones de visualización ---

  // OPCIÓN A (Como lo tenías, pero cuidado con los mensajes dobles si no capturas la excepción globalmente)
  MessageDlg(sMensaje, mtError, [mbOK], 0);
  Fail := False;

  // OPCIÓN B (Recomendada si no tienes Application.OnException configurado)
  // Anulamos la excepción original y lanzamos una nueva con nuestro texto.
  // Fail := False;
  // raise Exception.Create(sMensaje);
end;

procedure TdmConn.DataModuleCreate(Sender: TObject);
begin
  UniSQLMonitor1.Active := False;
  //oMemoSQL.Visible := False;
  {$IFDEF DEBUG}
    UniSQLMonitor1.Active := True;
   // oMemoSQL.Visible := True;
  {$ENDIF }
  //ofrmMto2.pcPrincipal.Align := alClient;
end;

procedure TdmConn.UniSQLMonitor1SQL(Sender: TObject; Text: string;
  Flag: TDATraceFlag);
begin
  {$IFDEF DEBUG}
    oMemoSQL.Lines.Add(Text);
    inLibLog.Log.LogSQL(Text);
  {$ENDIF }
end;

procedure TdmConn.ActualizarUserTimeModif(DataSet:TDataSet);
begin
  if (DataSet.FindField('USUARIOMODIF') <> nil) then
    DataSet.FieldbyName('USUARIOMODIF').AsString:= oUser;
  if DataSet.State = dsInsert then
  begin
    if (DataSet.FindField('INSTANTEALTA') <> nil) then
      DataSet.FieldbyName('INSTANTEALTA').AsDateTime := Now;
    if (DataSet.FindField('USUARIOALTA') <> nil) then
      DataSet.FieldbyName('USUARIOALTA').AsString := oUser;
    if (DataSet.FindField('INSTANTEMODIF') <> nil) then
      DataSet.FieldbyName('INSTANTEMODIF').AsDateTime := Now;
  end;
end;

end.
