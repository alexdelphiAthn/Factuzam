{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLogon                                                    }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad tiene la primera pantalla donde se autentifica el usuario.    }
{    Presenta la primera pantalla de autenficación de usuario. También permite }
{    Configurar la conexión a MySQL/MariaDB con su contraseña. Hace copias     }
{******************************************************************************}
unit inMtoLogon;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxLookAndFeelPainters, StdCtrls, cxButtons, rtti,
  UniDataConn, inLibUser, ImgList, Buttons, cxControls, cxContainer,
  Vcl.ExtCtrls, Data.DB, DBAccess, Uni, UniProvider, MySQLUniProvider, DADump,
  MemDS, cxGraphics, cxLookAndFeels, Vcl.Menus, cxEdit, cxCheckBox,
  cxTextEdit, dxSkinsCore, inMtoFrmBase, cxClasses, cxLocalization, cxMemo,
  DASQLMonitor, UniSQLMonitor, System.UITypes, dxShellDialogs, dxSkinBlue,
  dxCore, cxStyles, dxSkinsForm, dxSkinOffice2007Blue, cxGeometry,
  cxLabel,  JvComponentBase, JvEnterTab, JvExControls, JvAnimatedImage,
  JvGIFCtrl, dxSkinBasic, dxSkinBlack, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue, dascript,
      UniScript;

type
  EInvalidUser = class(Exception);
  EPassWordCorrupt = class(Exception);
  TfrmLogon = class(TfrmBase)
    lblUsuario: TcxLabel;
    lblContrasena: TcxLabel;
    edtUser: TcxTextEdit;
    edtPass: TcxTextEdit;
    MySQLUniProvider1: TMySQLUniProvider;
    ucConexion: TUniConnection;
    chkRememberPassword: TcxCheckBox;
    chkRememberUser: TcxCheckBox;
    tbUsers: TUniTable;
    chkAuto: TcxCheckBox;
    UniSQLMonitor1: TUniSQLMonitor;
    pnlBBDD: TPanel;
    lblBBDDConfig: TcxLabel;
    lblHostBBDD: TcxLabel;
    lblPortHost: TcxLabel;
    lblNomBBDD: TcxLabel;
    lblUserBBDD: TcxLabel;
    edtHostName: TcxTextEdit;
    edtPortBD: TcxTextEdit;
    edtNomBD: TcxTextEdit;
    edtUserBD: TcxTextEdit;
    edtPassBD: TcxTextEdit;
    btnChangePassRoot: TcxButton;
    btnTest: TcxButton;
    btnSubirScript: TcxButton;
    btnCopiaSeguridad: TcxButton;
    btnRecover: TcxButton;
    JvEnterAsTab1: TJvEnterAsTab;
    btnConf: TcxButton;
    btnAceptar:TButton;
    btnSalir:TButton;
    saveDialog: TFileSaveDialog;
    openDialog: TFileOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnConfClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnSubirScriptClick(Sender: TObject);
    procedure btnCopiaSeguridadClick(Sender: TObject);
    procedure btnRecoverClick(Sender: TObject);
    procedure ucConexionError(Sender: TObject; E: EDAError; var Fail: Boolean);
    procedure edtPassBDExit(Sender: TObject);
    procedure btnChangePassRootClick(Sender: TObject);
    procedure edtPortBDPropertiesChange(Sender: TObject);
    procedure leerini;
    procedure GetIniValues;
  private
    procedure CambiarPass(f:TUniConnection);
    procedure UniScript1Error(Sender: TObject; E: Exception; SQL: string;
                              var Action: TErrorAction);
    procedure escribirini;
    procedure SetIniValues;

    function ExisteUser(sNom: string; f: TUniConnection): Boolean;
    function LoginCorrecto(sNom,
                           sPassLogin: string;
                           f: TUniConnection): Boolean;
    function GetGrupo(sUser: string; conn: TUniConnection;
      var EsGrupoAdmin: string): string;
  public
    sSuccess:String;
    function IsInitializeAuto:Boolean;
  end;
var
  frmLogon          : TfrmLogon;
  sPass, sPassEn, sUserPassOK: string;

implementation

uses  inLibWin,
      inLibGlobalVar,
      inlibtb,
      inLibMsg,
      inLibDir,
      inLibLog,
      Backup.Engine,
      Backup.Types,
      Providers_MySQL,
      Providers_MySQL_Helpers,
      ScriptWriters,
      Core_Interfaces,
      Core_Helpers, inLibDBStructure;

{$R *.dfm}

procedure TfrmLogon.UniScript1Error(Sender: TObject;
                                    E: Exception;
                                    SQL: string;
                                    var Action: TErrorAction);
var
  Respuesta: Integer;
begin
  // Aquí podemos registrar el error en un log o preguntar al usuario
  Respuesta := MessageDlg(
    'Ocurrió un error ejecutando la siguiente sentencia:' + sLineBreak +
    SQL + sLineBreak + sLineBreak +
    'Detalle del error: ' + E.Message + sLineBreak + sLineBreak +
    '¿Deseas ignorar el error y continuar con el script?',
    mtError, [mbYes, mbNo], 0);
  if Respuesta = mrYes then
    // Ignora la sentencia fallida y continúa con la número 3
    Action := eaContinue
  else
    // Detiene el script y pasa al bloque "except" principal
    Action := eaFail;
end;

procedure TfrmLogon.btnSubirScriptClick(Sender: TObject);
var
  unqryTestBD: TUniQuery;
  SqlScript: TUniScript; // <-- Declaramos el nuevo componente
begin
  sPass := InputBox('Introduzca password de la BBDD', '','');
  ConstruirConexionConnect(ucConexion, edtUserBD.Text,
    sPass,
    edtHostName.Text,
    edtPortBD.Text,
    'information_schema');

  unqryTestBD := TUniQuery.Create(nil);
  unqryTestBD.Connection := ucConexion;
  unqryTestBD.SQL.Text := 'SELECT SCHEMA_NAME ' +
                          '  FROM INFORMATION_SCHEMA.SCHEMATA ' +
                          ' WHERE SCHEMA_NAME = :BBDD ' ;
  unqryTestBD.ParamByName('BBDD').AsString := edtNomBD.Text;
  unqryTestBD.Open;

  if (unqryTestBD.RecordCount > 0) then
  begin
     if ucConexion.Connected = true then
     begin
       ucConexion.Disconnect;
       ConstruirConexionConnect(ucConexion,
                             edtUserBD.Text,
                             sPass,
                             edtHostName.Text,
                             edtPortBD.Text,
                             edtNomBD.Text);
     end;
  end;

  opendialog.Title := 'Cargar script';
  opendialog.DefaultExtension := 'sql';
  openDialog.DefaultFolder := GetUserDeskFolder;

  if openDialog.Execute then
  begin
    SqlScript := TUniScript.Create(nil);
    sqlscript.OnError := UniScript1Error;
    try
      SqlScript.Connection := ucConexion;
      SqlScript.NoPreconnect := True; // Crucial para los DELIMITER de MySQL

      // Cargamos el fichero directamente al script
      SqlScript.SQL.LoadFromFile(opendialog.FileName);

      // Ejecutamos
      SqlScript.Execute;

      Log.LogInfo('El script se ejecutó exitosamente');
      ShowMessage('El script se ejecutó exitosamente');
    finally
      FreeAndNil(SqlScript);
    end;
  end
  else
  begin
    Log.LogInfo('El script no fue ejecutado');
    ShowMessage('El script no fue ejecutado');
  end;

  FreeAndNil(unqryTestBD);
  if (ucConexion.Connected = true) then
    ucConexion.Disconnect;
end;

procedure TfrmLogon.FormCreate(Sender: TObject);
var
  CheckResult: TDBStructureCheckResult;
begin
  ucConexion.Pooling := True;
  ucConexion.PoolingOptions.MinPoolSize := 1;
  ucConexion.PoolingOptions.MaxPoolSize := 50;
  ucConexion.PoolingOptions.ConnectionLifeTime := 3 * 60;
  UniSQLMonitor1.Active := False;
  Self.Width := 375;
  Self.ClientHeight := 353;
  {$IFDEF DEBUG}
    inliblog.Log.LogInfo('Arrancando en modo Debug');
  {$ENDIF}
  sUserPassOK := 'false';
  Self.Position := poScreenCenter;
  edtUser.Text := '';

  GetIniValues;

  sPassEn := leCadINIDir('ConnData',
                         'PasswordEn',
                         '2qJFaDfegP/9y6RDno1FRg==',
                         GetUserFolder);
  if (sPassEn.Length > 2) then
  begin
    try
      sPass := DecriptAES(sPassEn);
    except
      on E: Exception do
        raise EPassWordCorrupt.Create(SErrorDecryptPassBBDD);
    end;
  end;

  // --- 1. Conexión a information_schema para validar estructura ---
  try
    ConstruirConexionConnect(ucConexion,
                             edtUserBD.Text,
                             sPass,
                             edtHostName.Text,
                             edtPortBD.Text,
                             'information_schema');
  except
    on E: Exception do
    begin
      inliblog.Log.LogError('Fallo al conectar al servidor MySQL: ' +
                            E.ClassName + ': ' + E.Message);
      ShowMessage('No se pudo conectar al servidor MySQL/MariaDB:' +
                  sLineBreak + E.Message + sLineBreak + sLineBreak +
                  'Revise la configuración pulsando "Configurar BBDD".');
      chkAuto.Checked := False;
      esCadINIDir('UserInfo', 'AutoLogin', 'No', GetUserFolder);
      if not pnlBBDD.Visible then
        btnConfClick(Self);
      Exit;
    end;
  end;

  // --- 2. Verificación de estructura ---
  CheckResult := TDBStructureChecker.Check(ucConexion, edtNomBD.Text);

  if not CheckResult.IsOK then
  begin
    inliblog.Log.LogError('Estructura BBDD no válida: ' +
                          CheckResult.FormattedMessage);
    ShowMessage(CheckResult.FormattedMessage + sLineBreak + sLineBreak +
                'Puede usar "Subir script" para crear/actualizar la ' +
                'base de datos, o "Recuperar copia" para restaurar un backup.');

    // Desactivamos auto-login para no entrar en bucle
    chkAuto.Checked := False;
    esCadINIDir('UserInfo', 'AutoLogin', 'No', GetUserFolder);

    // Abrimos el panel de configuración
    if not pnlBBDD.Visible then
      btnConfClick(Self);

    // Desconectamos de information_schema, ya no la necesitamos
    if ucConexion.Connected then
      ucConexion.Disconnect;
    Exit;
  end;

  // --- 3. Estructura OK: reconectamos al schema real ---
  if ucConexion.Connected then
    ucConexion.Disconnect;

  try
    ConstruirConexionConnect(ucConexion,
                             edtUserBD.Text,
                             sPass,
                             edtHostName.Text,
                             edtPortBD.Text,
                             edtNomBD.Text);
  except
    on E: Exception do
    begin
      inliblog.Log.LogError('Fallo al conectar a ' + edtNomBD.Text + ': ' +
                            E.ClassName + ': ' + E.Message);
      ShowMessage('No se pudo conectar a la base de datos "' +
                  edtNomBD.Text + '":' + sLineBreak + E.Message);
      chkAuto.Checked := False;
      esCadINIDir('UserInfo', 'AutoLogin', 'No', GetUserFolder);
      if not pnlBBDD.Visible then
        btnConfClick(Self);
      Exit;
    end;
  end;

  // --- 4. Auto-login protegido ---
  if IsInitializeAuto then
  begin
    try
      btnAceptarClick(Self);
    except
      on E: Exception do
      begin
        inliblog.Log.LogError('Fallo en auto-login: ' +
                              E.ClassName + ': ' + E.Message);
        ShowMessage('No se pudo completar el inicio automático:' +
                    sLineBreak + E.Message + sLineBreak + sLineBreak +
                    'Introduzca sus credenciales manualmente.');
        chkAuto.Checked := False;
        esCadINIDir('UserInfo', 'AutoLogin', 'No', GetUserFolder);
        if tbUsers.Active then
          tbUsers.Close;
        sUserPassOK := 'false';
        sSuccess := 'N';
        ModalResult := mrNone;
      end;
    end;
  end;
end;

procedure TfrmLogon.btnConfClick(Sender: TObject);
begin
  if (pnlBBDD.Visible = True) then
  begin
    pnlBBDD.Visible := False;
    ClientWidth := 375;
  end
  else
  begin
    pnlBBDD.Visible := True;
    ClientWidth := 800;
  end;
end;

procedure TfrmLogon.btnCopiaSeguridadClick(Sender: TObject);
var
  s         : string;
  MyText    : TStringlist;
  iButtonSel: Integer;

  // Variables para el nuevo motor de backup
  Options: TBackupOptions;
  Provider: IDBMetadataProvider;
  Helpers: IDBHelpers;
  Writer: IScriptWriter;
  Engine: TDBBackupEngine;
  IncludeTables, ExcludeTables: TStringList;
begin
  ConstruirConexionConnect(ucConexion, edtUserBD.Text,
    sPass,
    edtHostName.Text,
    edtPortBD.Text,
    edtNomBD.Text);
  iButtonSel := 0;

  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultFolder := GetCurrentDir;
  saveDialog.DefaultExtension := '.crypt';
  savedialog.FileName := 'copiaseguridad_' + sPassEn +
                                       FormatDateTime('_dd_mm', Now) + '.crypt';

  if (saveDialog.Execute) then
  begin
    if FileExists(savedialog.FileName) then
    begin
      iButtonSel := MessageDlg('¿Desea reemplazar el fichero existente?',
        mtCustom, [mbYes, mbNo], 0);
    end;

    if ((iButtonSel = mrYes) or (not FileExists(saveDialog.FileName))) then
    begin
      // 1. Configurar Opciones del Backup
      Options.WithData := True;
      Options.WithTriggers := True;
      Options.WithProcedures := True;
      Options.WithFunctions := True;
      Options.WithViews := True;
      Options.DropTablesFirst := True;
      Options.UseTransactions := True;
      IncludeTables := TStringList.Create;
      ExcludeTables := TStringList.Create;
      Provider := TMySQLMetadataProvider.Create(ucConexion, edtNomBD.Text);
      Helpers := TMySQLHelpers.Create;
      Writer := TScriptWriter.Create('');
      try
        Engine := TDBBackupEngine.Create(Provider,
                                         Writer,
                                         Helpers,
                                         Options,
                                         IncludeTables,
                                         ExcludeTables);
        try
          // 3. Ejecutar la generación del script
          Engine.GenerateBackup;
          // 4. Obtener el script en formato String
          s := Writer.GetScript;
          s := StringReplace(s, 'DEFINER=`root`@`localhost`', '',
            [rfReplaceAll, rfIgnoreCase]);
          // 6. Encriptar el resultado
          s := EncriptAESPass(s, AnsiString(sPass));
          // 7. Guardar el archivo encriptado
          MyText := TStringlist.Create;
          try
            MyText.Text := s;
            saveDialog.DefaultFolder := GetUserDeskFolder;
            MyText.SaveToFile(saveDialog.FileName);
          finally
            FreeAndNil(MyText);
          end;
          Log.LogInfo(edtUser.Text + ' Guardó copia Encriptada en ' +
            savedialog.FileName);
          ShowMessage('La copia se guardó exitosamente');
        finally
          FreeAndNil(Engine);
        end;
      finally
        FreeAndNil(IncludeTables);
        FreeAndNil(ExcludeTables);
      end;
    end;
  end
  else
  begin
    Log.LogError('La copia se canceló');
    ShowMessage('La copia se canceló');
  end;
end;

procedure TfrmLogon.btnRecoverClick(Sender: TObject);
var
  MyText            : TStringList;
  s                 : string;
  unqryTestBD       : TUniQuery;
  SqlScript         : TUniScript;
begin
  sPass := InputBox(SGetPassBBDD, '', '');
  ConstruirConexionConnect(ucConexion, edtUserBD.Text,
    sPass,
    edtHostName.Text,
    edtPortBD.Text,
    'information_schema');

  unqryTestBD := TUniQuery.Create(nil);
  unqryTestBD.Connection := ucConexion;
  unqryTestBD.SQL.Text := 'SELECT SCHEMA_NAME ' +
                          '  FROM INFORMATION_SCHEMA.SCHEMATA ' +
                          ' WHERE SCHEMA_NAME = :BBDD ' ;
  unqryTestBD.ParamByName('BBDD').AsString := edtNomBD.Text;
  unqryTestBD.Open;

  if (unqryTestBD.RecordCount > 0) then
  begin
     if ucConexion.Connected = true then
     begin
       ucConexion.Disconnect;
       ConstruirConexionConnect( ucConexion,
                                 edtUserBD.Text,
                                 sPass,
                                 edtHostName.Text,
                                 edtPortBD.Text,
                                 edtNomBD.Text);
     end;
  end;

  opendialog.Title := 'Cargar copia encriptada';
  opendialog.DefaultExtension := 'crypt';
  openDialog.DefaultFolder := GetUserDeskFolder;

  if openDialog.Execute then
  begin
    MyText := TStringlist.create;
    try
      MyText.LoadFromFile(opendialog.FileName);
      s := MyText.Text;
    finally
      FreeAndNil(MyText);
    end;
    // Creamos y configuramos TUniScript
    SqlScript := TUniScript.Create(nil);
    try
      SqlScript.Connection := ucConexion;
      SqlScript.NoPreconnect := True; // Crucial para los DELIMITER de MySQL
      try
        // Desencriptamos y lo asignamos a la propiedad SQL del script
        SqlScript.SQL.Text := DecriptAESPass(s, AnsiString(edtPassBD.Text));
      except
        on E: Exception do
        begin
          ShowMessage(SErrorPassMatchBBDD +' '+ E.ClassName +
            ' Mensaje:' + E.Message);
          raise;
        end;
      end;
      // Ejecutamos la restauración
      SqlScript.Execute;
      ShowMessage(SScriptSuccess);
    finally
      FreeAndNil(SqlScript); // Liberamos el componente
    end;
  end
  else
    ShowMessage('Se canceló la carga del script.');
  unqryTestBD.Close;
  FreeAndNil(unqryTestBD);
end;

procedure TfrmLogon.btnTestClick(Sender: TObject);
begin
  escribirini;
  ConstruirConexionConnect( ucConexion,
                            edtUserBD.Text,
                            sPass,
                            edtHostName.Text,
                            edtPortBD.Text,
                            edtNomBD.Text);
  Log.LogInfo(SconnSuccBBDD);
  ShowMessage(SConnSuccBBDD);
  Exit;
end;

procedure TfrmLogon.CambiarPass(f: TUniConnection);
var
  qryCommand:TUniQuery;
  sNewPass:String;
  sPassEnBD:String;
begin
  if not f.Connected then
    ShowMessage(SNoConnBBDD)
  else
  begin
    if (Application.MessageBox(PWideChar(SWantDefChgBBDD),
                               PWideChar(SAdvMsg), MB_YESNO ) = ID_YES ) then
    begin
      sNewPass := InputBox('Introduzca el nuevo password de la BBDD', '','');
      qryCommand := TUniQuery.Create(nil);
      qryCommand.Connection := f;
      qryCommand.SQL.Text := 'FLUSH PRIVILEGES;';
      qryCommand.ExecSQL;
      qryCommand.SQL.Text := 'ALTER USER root@localhost IDENTIFIED BY :PASS;';
      qryCommand.ParamByName('PASS').AsString := sNewPass;
      qryCommand.ExecSQL;
      sPassEnBD := EncriptAES(sNewPass);
      sPass := sNewPass;
      ShowMessageFmt(SPasswordBBDDChanged, [sPass]);
      Log.LogInfo(sPasswordBBDDChanged);
      esCadIniDir('ConnData', 'PasswordEn', sPassEnBD, GetUserFolder);
      FreeAndNil(qryCommand);
    end;
  end;
end;


procedure TfrmLogon.btnSalirClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Close;
end;

function TfrmLogon.GetGrupo(sUser: string; conn: TUniConnection;
  var EsGrupoAdmin: string): string;
var
  qryGrupo          : TUniQuery;
  sResult           : string;
begin
  qryGrupo := TUniQuery.Create(Self);
  qryGrupo.SQL.Text := ' SELECT GRUPO_USU, ESGRUPOADMINISTRADOR_USUGRP ' +
                        '  FROM VI_USUARIOS  ' +
                        ' WHERE USUARIO_USU = ' + QuotedStr(sUser);
  qryGrupo.Connection := conn;
  qryGrupo.Open;
  sResult := qryGrupo.Fields[0].AsString;
  EsGrupoAdmin := qryGrupo.Fields[1].AsString;
  qryGrupo.Close;
  FreeAndNil(qryGrupo);
  Result := sResult;
end;

procedure TfrmLogon.btnChangePassRootClick(Sender: TObject);
var
  bAllowChange:Boolean;
  sOldPass:String;
  //sNewPass:String;
begin
  inherited;
  bAllowChange := False;
  if (sPass = 'Zamora2023') then
    bAllowChange := True
  else
  begin
    sOldPass := InputBox(SEnterPassBBDD, '','');
  end;
  if not bAllowChange then
  begin
    if ucConexion.Connected then
      ucConexion.Disconnect;
    ConstruirConexionConnect( ucConexion,
                              edtUserBD.Text,
                              sPass,
                              edtHostName.Text,
                              edtPortBD.Text,
                              'information_schema');
    if ucConexion.Connected = true then
      bAllowChange := True;
  end;
  if bAllowChange then
  begin
    CambiarPass(ucConexion);
  end
  else
  begin
    ShowMessage(SErrorPassMatch);
  end;
end;

procedure TfrmLogon.btnAceptarClick(Sender: TObject);
var
  sGrupoAdmin: string;
begin
  try
    if not ExisteUser(edtUser.Text, ucConexion) then
    begin
      Log.LogError('El nombre de usuario no existe');
      raise EInvalidUser.Create('El nombre de usuario no existe');
    end
    else if not LoginCorrecto(edtUser.Text, edtPass.Text, ucConexion) then
    begin
      if (Sender <> nil) then
        ShowMessage(SErrorAuthPass);
      sSuccess := 'N';
      Log.LogError(SErrorAuthPass);
    end
    else
    begin
      Log.LogInfo('Login Correcto');
      tbUsers.Edit;
      tbUsers.FieldByName('ULTIMO_LOGIN_USU').AsDateTime := Now;
      tbUsers.Post;
      oUser    := edtUser.Text;
      oGroup   := GetGrupo(edtUser.Text, ucConexion, sGrupoAdmin);
      orootGroup := sGrupoAdmin;
      oEmpresa := tbUsers.FieldByName('EMPRESA_DEFECTO_USU').AsString;
      oAlmacen := tbUsers.FieldByName('ALMACEN_DEFECTO_USU').AsString;
      oCaja    := tbUsers.FieldByName('CAJA_DEFECTO_USU').AsString;
      tbUsers.Close;
      sUserPassOK := 'true';
      SetIniValues;
      sSuccess := 'S';
      PostMessage(Handle, WM_CLOSE, 0, 0);
      ModalResult := mrOK;
    end;
  except
    on E: EInvalidUser do
    begin
      if (Sender <> nil) then
        ShowMessage(E.Message);
      sSuccess := 'N';
      raise; // que la propague el caller (FormCreate) si es auto-login
    end;
    on E: Exception do
    begin
      Log.LogError('Error en login: ' + E.ClassName + ': ' + E.Message);
      sSuccess := 'N';
      if tbUsers.Active then
        tbUsers.Close;
      raise; // para que FormCreate decida qué hacer
    end;
  end;
end;

function TfrmLogon.ExisteUser(sNom: string; f: TUniConnection): Boolean;
begin
  tbUsers.Open;
  tbUsers.First;
  Result := tbUsers.Locate('USUARIO_USU', sNom, []);
end;

function TfrmLogon.LoginCorrecto(sNom, sPassLogin: string;
                                 f: TUniConnection): Boolean;
var
  sPassMd5          : string;
  sPassBD           : string;
begin
  if sPassLogin <> '' then
  begin
    sPassMd5 := sMd5(sPassLogin);
  end;
  tbUsers.Locate('USUARIO_USU', sNom, []);
  sPAssBD := tbUsers.FindField('PASSWORD_USU').AsString;
  if sPassMd5 = sPassBD then
    Result := True
  else
    Result := False;
end;

procedure TfrmLogon.edtPassBDExit(Sender: TObject);
begin
end;

procedure TfrmLogon.edtPortBDPropertiesChange(Sender: TObject);
begin
end;

procedure TfrmLogon.escribirini;
begin
  esCadIniDir('ConnData', 'HostName', edtHostName.Text, GetUserFolder);
  esCadIniDir('ConnData', 'Database', edtNomBD.Text, GetUserFolder);
  esCadIniDir('ConnData', 'User', edtUserBD.Text, GetUserFolder);
  esCadIniDir('ConnData', 'Puerto', edtPortBD.Text, GetUserFolder);
  if (edtPassBD.Text <> '') then
  begin
    sPass := edtPassBD.Text;
    sPassEn := EncriptAES(sPass);
    esCadIniDir('ConnData', 'PasswordEn', sPassEn, GetUserFolder);
  end;
end;

procedure tfrmLogon.leerini;
begin
  edtHostName.Text := leCadIniDir('ConnData', 'HostName', '127.0.0.1',
                                                                 GetUserFolder);
  edtNomBD.Text := leCadIniDir('ConnData', 'Database', 'factuzam',
                                                                 GetUserFolder);
  edtUserBD.Text := leCadIniDir('ConnData', 'User', 'root', GetUserFolder);
  edtPortBD.Text := leCadIniDir('ConnData', 'Puerto', '3306', GetUserFolder);
end;

procedure TfrmLogon.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F12 then
  begin
    btnAceptarClick(nil);
    Key := 0;
  end
  else if Key = VK_ESCAPE then
  begin
    btnSalirClick(nil);
    Key := 0;
  end;
end;

procedure TfrmLogon.SetIniValues;
begin
  if (chkRememberUser.Checked = True) then
  begin
    esCadINIDir('UserInfo', 'RememberUser', 'Yes', GetUserFolder);
    esCadINIDir('UserInfo', 'NomUser', edtUser.Text, GetUserFolder);
  end;
  if (chkRememberPassword.Checked = True) then
  begin
    esCadINIDir('UserInfo', 'RememberPassword', 'Yes', GetUserFolder);
    esCadINIDir('UserInfo', 'PasswordEn',
                                       EncriptAES(edtPass.Text), GetUserFolder);
  end;
  if (chkAuto.Checked = True) then
      esCadINIDir('UserInfo', 'AutoLogin', 'Yes', GetUserFolder);
  escribirini;
end;

procedure TfrmLogon.ucConexionError(Sender: TObject; E: EDAError;
  var Fail: Boolean);
begin
  Fail := False;
end;

procedure TfrmLogon.GetIniValues;
var
  sRememberUser,
  sAutoRun,
  sRememberPassword     : string;
begin
  sRememberUser := leCadINIDir( 'UserInfo',
                                'RememberUser',
                                'No',
                                GetUserFolder);
  sAutoRun := leCadINIDir('UserInfo',
                          'AutoLogin',
                          'No',
                          GetUserFolder);
  sRememberPassword := leCadINIDir('UserInfo',
    'RememberPassword',
    'No',
    GetUserFolder);
  if SameText(sAutoRun,'Yes') then
  begin
    chkAuto.Checked := True;
  end;
  if SameText(sRememberUser, 'Yes') then
  begin
    chkRememberUser.Checked := True;
    edtUser.Text := leCadINIDir('UserInfo',
                                'NomUser',
                                'Administrador',
                                GetUserFolder);
  end;
  if SameText(sRememberPassword, 'Yes') then
  begin
    chkRememberPassword.Checked := True;
    edtPass.Text := DecriptAES(leCadINIDir('UserInfo',
                                           'PasswordEn',
                                           'q7heHfD7ENowuvRQhW56Og==',
                                           GetUserFolder));
  end;
  leerini;
  inliblog.Log.LogInfo('Leyendo archivo ini de usuario');
end;

function TfrmLogon.IsInitializeAuto: Boolean;
begin
  Result := chkAuto.Checked;
  {$IFDEF DEBUG}
    //Result := False;
  {$ENDIF }
end;

procedure TfrmLogon.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SetIniValues;
  if (ucConexion.Connected = true) then
    ucConexion.Disconnect;
  ucConexion.Pooling := false;
end;

end.

