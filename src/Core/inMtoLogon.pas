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
  Dialogs, cxLookAndFeelPainters, StdCtrls, ComCtrls, cxButtons, rtti,
  UniDataConn, ImgList, Buttons, cxControls, cxContainer,
  Vcl.ExtCtrls, Uni, cxGraphics, cxLookAndFeels, Vcl.Menus, cxEdit, cxCheckBox,
  cxTextEdit, dxSkinsCore, inMtoFrmBase, cxClasses, cxLocalization, cxMemo,
  System.UITypes, dxShellDialogs, dxSkinBlue,
  dxCore, cxStyles, dxSkinsForm, dxSkinOffice2007Blue, cxGeometry,
  cxLabel, JvComponentBase, JvEnterTab, JvExControls, JvAnimatedImage,
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
  dxSkinWhiteprint, dxSkinXmas2008Blue,
  inLibContextoSesionIntf, inLibLicenciaAplicacion,
  inLibCopiasSeguridadIntf,
  inLibRestauracionCopiasConexionIntf,
  inLibLogonAplicacionIntf;

type
  EPassWordCorrupt = class(Exception);
  TfrmLogon = class(TfrmBase)
    lblUsuario: TcxLabel;
    lblContrasena: TcxLabel;
    edtUser: TcxTextEdit;
    edtPass: TcxTextEdit;
    chkRememberPassword: TcxCheckBox;
    chkRememberUser: TcxCheckBox;
    chkAuto: TcxCheckBox;
    pnlBBDD: TPanel;
    pnlLogin: TPanel;
    pnlButtons: TPanel;
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
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnConfClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnSubirScriptClick(Sender: TObject);
    procedure btnCopiaSeguridadClick(Sender: TObject);
    procedure btnRecoverClick(Sender: TObject);
    procedure edtPassBDExit(Sender: TObject);
    procedure edtPortBDPropertiesChange(Sender: TObject);
    procedure leerini;
    procedure GetIniValues;
  private
    FProgressPanel: TPanel;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    FWorkerOperacion: TThread;
    FCerrarAplicacion: Boolean;
    FEnOperacionLarga: Boolean;
    FCancelaOperacionSolicitada: Boolean;
    FPasswordConexion: string;
    FPasswordConexionEncriptado: string;
    FResultadoInicioSesion: TResultadoInicioSesion;
    FResultadoLicencia: TResultadoLicenciaAplicacion;
    FCasoUsoRestauracion: ICasoUsoRestauracionConexion;
    FConexionLogon: TUniConnection;
    FRepositorioLogon: IRepositorioLogon;
    FAplicacionLogon: IAplicacionLogon;
    procedure AplicarTraduccionesPantalla;
    function ResolverErrorScriptLogon(
      const ASentencia, AError: string): TDecisionErrorScriptLogon;
    procedure escribirini;
    procedure SetIniValues;
    procedure BloquearPantallaOperacion;
    procedure DesbloquearPantallaOperacion;
    procedure RecolocarBarraProgreso;
    procedure MostrarBarraProgreso(const ATextoInicial: string = '');
    procedure OcultarBarraProgreso;
    function PorcentajeProgreso(AValor, ATotal: Integer): Integer;
    function TextoProgreso(const AEtapa: string;
                           AValor, ATotal: Integer): string;
    procedure SolicitarCancelarOperacionEnCurso;
    procedure WorkerProgreso(const AEtapa: string;
                              APaso, ATotal: Integer;
                              AFilaGlobal,
                              AFilasGlobalTotal: Integer);
    procedure BackupFinalizar(AResultado: TResultadoCopiaSeguridad;
                              const AError: string;
                              ALogBuffer: TStringList);
    procedure RestoreFinalizar(AResultado: TResultadoCopiaSeguridad;
                               const AError: string;
                               ALogBuffer: TStringList);
    procedure PrepararWorkerRestauracion(AWorker: TThread);
    function ConexionAplicacionPreparada: Boolean;
    function LicenciaAplicacionPreparada: Boolean;
    function ProcesarLicenciaAplicacion: Boolean;
    procedure InvalidarResultadoInicioSesion;
  public
    destructor Destroy; override;
    function IsInitializeAuto:Boolean;
    function DebeCerrarAplicacion:Boolean;
    property ResultadoInicioSesion: TResultadoInicioSesion
      read FResultadoInicioSesion;
    property ResultadoLicencia: TResultadoLicenciaAplicacion
      read FResultadoLicencia;
  end;

implementation

uses  inLibWin,
      inLibCifrado,
      inLibConfiguracionIni,
      inLibConexionesUniDAC,
      inLibTraducciones,
      inLibTraduccionesFastReport,
      inLibMsgComun,
      inLibMsgConfiguracion,
      inLibDir,

      Backup.Engine,
      Backup.Types,
      Providers_MySQL,
      Providers_MySQL_Helpers,
      ScriptWriters,
      Core_Interfaces,
      Core_Helpers,
      inLibDBStructure,
      inMtoModalScriptLog,
      inLibBackupWorker,
      inLibRestauracionCopiasConexion,
      UniDataRestauracionCopiasConexion,
      inMtoLogonRestauracionVcl,
      inLibLogonAplicacion,
      UniDataLogonRepositorio;

function CrearContextoLogonRestauracionVcl(
  AFormulario: TfrmLogon): TContextoLogonRestauracionVcl;
begin
  Result := Default(TContextoLogonRestauracionVcl);
  Result.Dialogo := AFormulario.openDialog;
  Result.CasoUso := AFormulario.FCasoUsoRestauracion;
  Result.Host := AFormulario.edtHostName.Text;
  Result.Puerto := AFormulario.edtPortBD.Text;
  Result.BaseDatos := AFormulario.edtNomBD.Text;
  Result.Usuario := AFormulario.edtUserBD.Text;
  Result.OnPrepararWorker :=
    AFormulario.PrepararWorkerRestauracion;
  Result.OnProgreso := AFormulario.WorkerProgreso;
  Result.OnFinalizar := AFormulario.RestoreFinalizar;
  Result.EstablecerContrasena :=
    procedure(const AContrasena: string)
    begin
      AFormulario.FPasswordConexion := AContrasena;
    end;
  Result.MostrarPreparacion :=
    procedure
    begin
      AFormulario.MostrarBarraProgreso(
        SCaptionPreparandoRestauracion);
    end;
end;

{$R *.dfm}

procedure TfrmLogon.AplicarTraduccionesPantalla;
begin
  AsignarTraducciones(
    TServicioTraducciones.Create(
      TServicioConexionesUniDAC.Create(FConexionLogon),
      RegistroLog,
      ObtenerIdiomaConfigurado(
        FConexionLogon,
        edtUser.Text,
        RegistroLog)));
  AplicarIdiomaFastReport(Traducciones.Idioma);
  Traducciones.Aplicar(Self);
end;

function TfrmLogon.ResolverErrorScriptLogon(
  const ASentencia, AError: string): TDecisionErrorScriptLogon;
var
  Respuesta: Integer;
begin
  Respuesta := MessageDlg(
    Format(SErrorSentenciaScript, [ASentencia, AError]),
    mtError,
    [mbYes, mbNo],
    0);
  if Respuesta = mrYes then
    Result := deslContinuar
  else
    Result := deslDetener;
end;

procedure TfrmLogon.btnSubirScriptClick(Sender: TObject);
begin
  FPasswordConexion := InputBox(SSolicitudPassBBDD, '', '');
  ConfigurarYConectarMySQL(FConexionLogon, edtUserBD.Text,
    FPasswordConexion,
    edtHostName.Text,
    edtPortBD.Text,
    'information_schema');

  if ExisteEsquemaLogonUniDAC(FConexionLogon, edtNomBD.Text) then
  begin
    if FConexionLogon.Connected then
      FConexionLogon.Disconnect;
    ConfigurarYConectarMySQL(
      FConexionLogon,
      edtUserBD.Text,
      FPasswordConexion,
      edtHostName.Text,
      edtPortBD.Text,
      edtNomBD.Text);
  end;
  opendialog.Title := STituloCargarScript;
  opendialog.DefaultExtension := 'sql';
  openDialog.DefaultFolder := GetUserDeskFolder;

  if openDialog.Execute then
  begin
    EjecutarScriptLogonUniDAC(
      FConexionLogon,
      opendialog.FileName,
      ResolverErrorScriptLogon);
    RegistroLog.RegistrarInformacion('El script se ejecutó exitosamente');
    ShowMessage(SScriptEjecutado);
  end
  else
  begin
    RegistroLog.RegistrarInformacion('El script no fue ejecutado');
    ShowMessage(SScriptNoEjecutado);
  end;

  if FConexionLogon.Connected then
    FConexionLogon.Disconnect;
end;

procedure TfrmLogon.FormCreate(Sender: TObject);
var
  CheckResult: TDBStructureCheckResult;
begin
  InvalidarResultadoInicioSesion;
  CrearRepositorioLogonUniDAC(
    FRepositorioLogon,
    FConexionLogon);
  FAplicacionLogon := CrearAplicacionLogon(FRepositorioLogon);
  // Tamano compacto del login (panel BBDD oculto) calculado desde las
  // coordenadas ya escaladas de los controles, para que los botones no se
  // recorten con escalado DPI (el .dfm no trae PixelsPerInch y el tamano
  // fijo anterior no se reescalaba).
  pnlBBDD.Visible := False;
  Self.ClientWidth  := pnlButtons.Left + pnlButtons.Width + pnlButtons.Left;
  Self.ClientHeight := pnlButtons.Top + pnlButtons.Height + pnlLogin.Top;
  {$IFDEF DEBUG}
    RegistroLog.RegistrarInformacion('Arrancando en modo Debug');
  {$ENDIF}
  FCerrarAplicacion := False;
  FEnOperacionLarga := False;
  FCancelaOperacionSolicitada := False;
  FWorkerOperacion := nil;
  FResultadoLicencia :=
    TResultadoLicenciaAplicacion.CrearNoComprobada;
  Self.Position := poScreenCenter;
  edtUser.Text := '';

  GetIniValues;

  FPasswordConexionEncriptado := LeerCadenaIni('ConnData',
                         'PasswordEn',
                         '2qJFaDfegP/9y6RDno1FRg==',
                         GetUserFolder);
  if (FPasswordConexionEncriptado.Length > 2) then
  begin
    try
      FPasswordConexion := DescifrarAES(
        FPasswordConexionEncriptado);
    except
      on E: Exception do
        raise EPassWordCorrupt.Create(SErrorDecryptPassBBDD);
    end;
  end;

  // --- 1. Conexión a information_schema para validar estructura ---
  try
    ConfigurarYConectarMySQL(FConexionLogon,
                             edtUserBD.Text,
                             FPasswordConexion,
                             edtHostName.Text,
                             edtPortBD.Text,
                             'information_schema');
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarError('Fallo al conectar al servidor MySQL: ' +
                            E.ClassName + ': ' + E.Message);
      ShowMessage(Format(SErrorConexionServidorBBDD, [E.Message]));
      chkAuto.Checked := False;
      EscribirCadenaIni(
        'UserInfo', 'AutoLogin', 'No', GetUserFolder);
      if not pnlBBDD.Visible then
        btnConfClick(Self);
      Exit;
    end;
  end;

  // --- 2. Verificación de estructura ---
  CheckResult := TDBStructureChecker.Check(FConexionLogon, edtNomBD.Text);

  if not CheckResult.IsOK then
  begin
    RegistroLog.RegistrarError('Estructura BBDD no válida: ' +
                          CheckResult.FormattedMessage);
    ShowMessage(Format(SErrorEstructuraBBDD,
                       [CheckResult.FormattedMessage]));

    // Desactivamos auto-login para no entrar en bucle
    chkAuto.Checked := False;
    EscribirCadenaIni(
      'UserInfo', 'AutoLogin', 'No', GetUserFolder);

    // Abrimos el panel de configuración
    if not pnlBBDD.Visible then
      btnConfClick(Self);

    // Desconectamos de information_schema, ya no la necesitamos
    if FConexionLogon.Connected then
      FConexionLogon.Disconnect;
    Exit;
  end;

  // --- 3. Estructura OK: reconectamos al schema real ---
  if FConexionLogon.Connected then
    FConexionLogon.Disconnect;

  try
    ConfigurarYConectarMySQL(FConexionLogon,
                             edtUserBD.Text,
                             FPasswordConexion,
                             edtHostName.Text,
                             edtPortBD.Text,
                             edtNomBD.Text);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarError('Fallo al conectar a ' + edtNomBD.Text + ': ' +
                            E.ClassName + ': ' + E.Message);
      ShowMessage(Format(SErrorConexionBBDD,
                         [edtNomBD.Text, E.Message]));
      chkAuto.Checked := False;
      EscribirCadenaIni(
        'UserInfo', 'AutoLogin', 'No', GetUserFolder);
      if not pnlBBDD.Visible then
        btnConfClick(Self);
      Exit;
    end;
  end;

  AplicarTraduccionesPantalla;
  if not ProcesarLicenciaAplicacion then
    Exit;

  // --- /relogin: reinicio desde 'Invocar login'. Vacia la contrasena
  // recordada para forzar que se introduzca de nuevo (el auto-login ya
  // queda neutralizado en IsInitializeAuto). ---
  if FindCmdLineSwitch('relogin', True) then
    edtPass.Text := '';
  // --- 4. Auto-login protegido ---
  if IsInitializeAuto then
  begin
    try
      btnAceptarClick(Self);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarError('Fallo en auto-login: ' +
                              E.ClassName + ': ' + E.Message);
        ShowMessage(Format(SErrorInicioAutomatico, [E.Message]));
        chkAuto.Checked := False;
        EscribirCadenaIni(
          'UserInfo', 'AutoLogin', 'No', GetUserFolder);
        InvalidarResultadoInicioSesion;
        ModalResult := mrNone;
      end;
    end;
  end;
end;

function TfrmLogon.ConexionAplicacionPreparada: Boolean;
var
  CheckResult: TDBStructureCheckResult;
  bServidorConectado: Boolean;
  sPasswordConexion: string;
begin
  Result := False;
  sPasswordConexion := FPasswordConexion;
  if edtPassBD.Text <> '' then
    sPasswordConexion := edtPassBD.Text;
  if FConexionLogon.Connected and
     SameText(FConexionLogon.Database, edtNomBD.Text) then
    Result := True
  else
  begin
    if FConexionLogon.Connected then
      FConexionLogon.Disconnect;
    bServidorConectado := False;
    try
      ConfigurarYConectarMySQL(FConexionLogon,
                               edtUserBD.Text,
                               sPasswordConexion,
                               edtHostName.Text,
                               edtPortBD.Text,
                               'information_schema');
      bServidorConectado := True;
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarError('Fallo al conectar al servidor MySQL: ' +
                              E.ClassName + ': ' + E.Message);
        ShowMessage(Format(SErrorConexionServidorBBDD, [E.Message]));
        chkAuto.Checked := False;
        EscribirCadenaIni(
          'UserInfo', 'AutoLogin', 'No', GetUserFolder);
        if not pnlBBDD.Visible then
          btnConfClick(Self);
      end;
    end;
    if bServidorConectado then
    begin
      CheckResult := TDBStructureChecker.Check(FConexionLogon, edtNomBD.Text);
      if not CheckResult.IsOK then
      begin
        RegistroLog.RegistrarError('Estructura BBDD no válida: ' +
                              CheckResult.FormattedMessage);
        ShowMessage(Format(SErrorEstructuraBBDD,
                           [CheckResult.FormattedMessage]));
        chkAuto.Checked := False;
        EscribirCadenaIni(
          'UserInfo', 'AutoLogin', 'No', GetUserFolder);
        if not pnlBBDD.Visible then
          btnConfClick(Self);
        if FConexionLogon.Connected then
          FConexionLogon.Disconnect;
      end
      else
      begin
        if FConexionLogon.Connected then
          FConexionLogon.Disconnect;
        try
          ConfigurarYConectarMySQL(FConexionLogon,
                                   edtUserBD.Text,
                                   sPasswordConexion,
                                   edtHostName.Text,
                                   edtPortBD.Text,
                                   edtNomBD.Text);
          FPasswordConexion := sPasswordConexion;
          Result := True;
        except
          on E: Exception do
          begin
            RegistroLog.RegistrarError('Fallo al conectar a ' + edtNomBD.Text +
                                  ': ' + E.ClassName + ': ' + E.Message);
            ShowMessage(Format(SErrorConexionBBDD,
                               [edtNomBD.Text, E.Message]));
            chkAuto.Checked := False;
            EscribirCadenaIni(
              'UserInfo', 'AutoLogin', 'No', GetUserFolder);
            if not pnlBBDD.Visible then
              btnConfClick(Self);
          end;
        end;
      end;
    end;
  end;
end;

function TfrmLogon.LicenciaAplicacionPreparada: Boolean;
begin
  Result := False;
  if ConexionAplicacionPreparada then
  begin
    if FResultadoLicencia.Comprobada and
       SameText(FResultadoLicencia.BBDD, FConexionLogon.Database) then
      Result := True
    else
      Result := ProcesarLicenciaAplicacion;
  end;
end;

function TfrmLogon.ProcesarLicenciaAplicacion: Boolean;
var
  Estado: TEstadoLicenciaAplicacion;
  sMensaje,
  sCodigoEsperado,
  sCodigoGuardado,
  sCodigo,
  sDetalleNifs,
  sRutaIni: string;
  iNumeroNifs: Integer;
begin
  Result := True;
  FResultadoLicencia.Comprobada := False;
  FResultadoLicencia.BBDD := FConexionLogon.Database;
  FResultadoLicencia.Estado := elaInvalida;
  FResultadoLicencia.Mensaje := '';
  if HayConmutadorRegistroLicencia then
  begin
    Result := False;
    FCerrarAplicacion := True;
    InvalidarResultadoInicioSesion;
    try
      if RegistrarLicenciaAplicacion(FConexionLogon,
                                     sCodigo,
                                     iNumeroNifs,
                                     sDetalleNifs,
                                     sRutaIni) then
      begin
        FResultadoLicencia.Comprobada := True;
        FResultadoLicencia.Estado := elaValida;
        FResultadoLicencia.Mensaje := 'Licencia establecida.';
        RegistroLog.RegistrarInformacion(
          'Licencia establecida. Código: ' + sCodigo);
        ShowMessage(Format(SLicenciaEstablecida,
                           [sCodigo, iNumeroNifs, sRutaIni,
                            Trim(sDetalleNifs)]));
      end
      else
      begin
        FResultadoLicencia.Comprobada := True;
        FResultadoLicencia.Estado := elaSinNifEmpresa;
        FResultadoLicencia.Mensaje := 'No hay NIF de empresa configurado.';
        RegistroLog.RegistrarInformacion(
          'No se establece licencia porque no hay NIF de empresa.');
        ShowMessage(SLicenciaNoEstablecidaSinNif);
      end;
    except
      on E: Exception do
      begin
        FResultadoLicencia.Mensaje := E.Message;
        RegistroLog.RegistrarError(
          'Error estableciendo licencia: ' + E.Message);
        ShowMessage(Format(SErrorEstablecerLicencia, [E.Message]));
      end;
    end;
  end
  else
  begin
    try
      if ComprobarLicenciaAplicacion(FConexionLogon,
                                     Estado,
                                     sMensaje,
                                     sCodigoEsperado,
                                     sCodigoGuardado) then
      begin
        FResultadoLicencia.Comprobada := True;
        FResultadoLicencia.Estado := Estado;
        FResultadoLicencia.Mensaje := sMensaje;
        if Estado = elaSinNifEmpresa then
          RegistroLog.RegistrarInformacion(sMensaje)
        else
          RegistroLog.RegistrarInformacion('Licencia de aplicación válida.');
      end
      else
      begin
        FResultadoLicencia.Comprobada := True;
        FResultadoLicencia.Estado := Estado;
        FResultadoLicencia.Mensaje := 'Copia DEMO. ' + sMensaje;
        RegistroLog.RegistrarAviso('Aplicación en modo DEMO. ' + sMensaje);
        RegistroLog.RegistrarError('Código guardado: ' + sCodigoGuardado +
                              ' Código esperado: ' + sCodigoEsperado);
        ShowMessage(Format(SModoDemo, [LIMITE_FACTURAS_DEMO_DIA]));
      end;
    except
      on E: Exception do
      begin
        FResultadoLicencia.Comprobada := True;
        FResultadoLicencia.Estado := elaInvalida;
        FResultadoLicencia.Mensaje := 'Copia DEMO. ' + E.Message;
        RegistroLog.RegistrarError('Error validando licencia: ' + E.Message);
        RegistroLog.RegistrarAviso('Aplicación en modo DEMO por error ' +
                                'validando licencia.');
        ShowMessage(Format(SModoDemo, [LIMITE_FACTURAS_DEMO_DIA]));
      end;
    end;
  end;
end;

procedure TfrmLogon.btnConfClick(Sender: TObject);
begin
  if (pnlBBDD.Visible = True) then
  begin
    pnlBBDD.Visible := False;
    ClientWidth := pnlButtons.Left + pnlButtons.Width + pnlButtons.Left;
  end
  else
  begin
    pnlBBDD.Visible := True;
    ClientWidth := pnlBBDD.Left + pnlBBDD.Width + pnlButtons.Left;
  end;
end;

procedure TfrmLogon.BloquearPantallaOperacion;
begin
  FEnOperacionLarga := True;
  Screen.Cursor := crHourGlass;
  btnAceptar.Enabled := False;
  btnSalir.Enabled := False;
  btnConf.Enabled := False;
  btnTest.Enabled := False;
  btnSubirScript.Enabled := False;
  btnCopiaSeguridad.Enabled := False;
  btnRecover.Enabled := False;
  edtUser.Enabled := False;
  edtPass.Enabled := False;
  chkRememberUser.Enabled := False;
  chkRememberPassword.Enabled := False;
  chkAuto.Enabled := False;
  edtHostName.Enabled := False;
  edtPortBD.Enabled := False;
  edtNomBD.Enabled := False;
  edtUserBD.Enabled := False;
  edtPassBD.Enabled := False;
end;

procedure TfrmLogon.DesbloquearPantallaOperacion;
begin
  FEnOperacionLarga := False;
  Screen.Cursor := crDefault;
  btnAceptar.Enabled := True;
  btnSalir.Enabled := True;
  btnConf.Enabled := True;
  btnTest.Enabled := True;
  btnSubirScript.Enabled := True;
  btnCopiaSeguridad.Enabled := True;
  btnRecover.Enabled := True;
  edtUser.Enabled := True;
  edtPass.Enabled := True;
  chkRememberUser.Enabled := True;
  chkRememberPassword.Enabled := True;
  chkAuto.Enabled := True;
  edtHostName.Enabled := True;
  edtPortBD.Enabled := True;
  edtNomBD.Enabled := True;
  edtUserBD.Enabled := True;
  edtPassBD.Enabled := True;
end;

procedure TfrmLogon.RecolocarBarraProgreso;
var
  iTopBotones: Integer;
  iAncho: Integer;
begin
  if FProgressPanel <> nil then
  begin
    iTopBotones := btnRecover.Top + btnRecover.Height;
    if btnCopiaSeguridad.Top + btnCopiaSeguridad.Height > iTopBotones then
      iTopBotones := btnCopiaSeguridad.Top + btnCopiaSeguridad.Height;
    iAncho := (btnRecover.Left + btnRecover.Width) - btnCopiaSeguridad.Left;
    FProgressPanel.Left := btnCopiaSeguridad.Left;
    FProgressPanel.Top := iTopBotones + 12;
    FProgressPanel.Width := iAncho;
    FProgressPanel.Height := 48;
    if FProgressPanel.Top + FProgressPanel.Height >
       pnlBBDD.ClientHeight - 8 then
    begin
      FProgressPanel.Top := pnlBBDD.ClientHeight -
                            FProgressPanel.Height - 8;
    end;
    if FProgressLabel <> nil then
    begin
      FProgressLabel.Left := 0;
      FProgressLabel.Top := 0;
      FProgressLabel.Width := FProgressPanel.Width;
      FProgressLabel.Height := 22;
    end;
    if FProgressBar <> nil then
    begin
      FProgressBar.Left := 0;
      FProgressBar.Top := 25;
      FProgressBar.Width := FProgressPanel.Width;
      FProgressBar.Height := 18;
    end;
  end;
end;

procedure TfrmLogon.MostrarBarraProgreso(const ATextoInicial: string);
begin
  BloquearPantallaOperacion;
  if FProgressPanel = nil then
  begin
    FProgressPanel := TPanel.Create(Self);
    FProgressPanel.Parent := pnlBBDD;
    FProgressPanel.BevelOuter := bvNone;
    FProgressPanel.ParentBackground := False;
    FProgressPanel.Color := pnlBBDD.Color;
  end;
  if FProgressBar = nil then
  begin
    FProgressBar := TProgressBar.Create(Self);
    FProgressBar.Parent := FProgressPanel;
    FProgressBar.Min := 0;
    FProgressBar.Max := 100;
    FProgressBar.Position := 0;
    FProgressBar.Smooth := True;
  end;
  if FProgressLabel = nil then
  begin
    FProgressLabel := TcxLabel.Create(Self);
    FProgressLabel.Parent := FProgressPanel;
    FProgressLabel.AutoSize := False;
    FProgressLabel.Caption := '';
    FProgressLabel.Transparent := False;
    FProgressLabel.Style.Color := pnlBBDD.Color;
    FProgressLabel.ShowHint := True;
  end;
  RecolocarBarraProgreso;
  FProgressPanel.Visible := True;
  FProgressLabel.Visible := True;
  FProgressBar.Visible := True;
  FProgressBar.Position := 0;
  if ATextoInicial = '' then
    FProgressLabel.Caption := SCaptionPreparando
  else
    FProgressLabel.Caption := ATextoInicial;
  FProgressLabel.Hint := FProgressLabel.Caption;
  FProgressPanel.BringToFront;
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmLogon.OcultarBarraProgreso;
begin
  if FProgressBar <> nil then
    FProgressBar.Visible := False;
  if FProgressLabel <> nil then
    FProgressLabel.Visible := False;
  if FProgressPanel <> nil then
    FProgressPanel.Visible := False;
  DesbloquearPantallaOperacion;
end;

function TfrmLogon.PorcentajeProgreso(AValor, ATotal: Integer): Integer;
begin
  Result := 0;
  if ATotal > 0 then
  begin
    Result := Trunc((AValor * 100.0) / ATotal);
    if Result < 0 then
      Result := 0;
    if Result > 100 then
      Result := 100;
  end;
end;

function TfrmLogon.TextoProgreso(const AEtapa: string;
                                 AValor, ATotal: Integer): string;
var
  sEtapa: string;
begin
  sEtapa := Trim(AEtapa);
  sEtapa := StringReplace(sEtapa, ' (KB)', '', [rfReplaceAll, rfIgnoreCase]);
  if sEtapa = '' then
    sEtapa := 'Procesando';
  if Length(sEtapa) > 34 then
    sEtapa := Copy(sEtapa, 1, 31) + '...';
  if ATotal > 0 then
    Result := Format('%s: %d%%', [sEtapa,
                                  PorcentajeProgreso(AValor, ATotal)])
  else
    Result := sEtapa;
end;

procedure TfrmLogon.SolicitarCancelarOperacionEnCurso;
begin
  if FEnOperacionLarga then
  begin
    if FCancelaOperacionSolicitada then
      ShowMessage(SCancelacionSolicitada)
    else if MessageDlg(SPreguntaCancelarOperacion,
                       mtWarning, [mbYes, mbNo], 0) = mrYes then
    begin
      FCancelaOperacionSolicitada := True;
      if Assigned(FWorkerOperacion) then
        FWorkerOperacion.Terminate;
      if FProgressLabel <> nil then
      begin
        FProgressLabel.Caption := SCaptionCancelandoOperacion;
        FProgressLabel.Hint := FProgressLabel.Caption;
        FProgressLabel.Update;
      end;
    end;
  end;
end;

procedure TfrmLogon.WorkerProgreso(const AEtapa: string;
                                   APaso, ATotal: Integer;
                                   AFilaGlobal,
                                   AFilasGlobalTotal: Integer);
var
  iValor: Integer;
  iTotal: Integer;
begin
  if (FProgressBar = nil) or (not FProgressBar.Visible) then
    Exit;
  iValor := APaso;
  iTotal := ATotal;
  if AFilasGlobalTotal > 0 then
  begin
    iValor := AFilaGlobal;
    iTotal := AFilasGlobalTotal;
  end;
  FProgressBar.Max := 100;
  FProgressBar.Position := PorcentajeProgreso(iValor, iTotal);
  FProgressLabel.Caption := TextoProgreso(AEtapa, iValor, iTotal);
  FProgressLabel.Hint := FProgressLabel.Caption;
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmLogon.BackupFinalizar(
  AResultado: TResultadoCopiaSeguridad;
  const AError: string; ALogBuffer: TStringList);
begin
  FWorkerOperacion := nil;
  FCasoUsoRestauracion := CrearCasoUsoRestauracionConexion(
    CrearRepositorioRestauracionConexionUniDAC(FConexionLogon));
  FCancelaOperacionSolicitada := False;
  OcultarBarraProgreso;
  if AResultado = rcsCancelada then
    ShowMessage(SOperacionCancelada)
  else if AResultado = rcsCompletada then
  begin
    RegistroLog.RegistrarInformacion(
      edtUser.Text + ' Guardó copia exitosamente');
    ShowMessage(SCopiaSeguridadGuardada);
  end
  else
  begin
    RegistroLog.RegistrarError('La copia falló: ' + AError);
    ShowMessage(Format(SErrorCrearCopiaSeguridad, [AError]));
  end;
end;

procedure TfrmLogon.RestoreFinalizar(
  AResultado: TResultadoCopiaSeguridad;
  const AError: string; ALogBuffer: TStringList);
var
  LogForm: TfrmMtoModalScriptLog;
begin
  FWorkerOperacion := nil;
  FCancelaOperacionSolicitada := False;
  OcultarBarraProgreso;
  if AResultado = rcsCancelada then
  begin
    if ALogBuffer <> nil then
      FreeAndNil(ALogBuffer);
    ShowMessage(SRestauracionCancelada);
  end
  else
  begin
    LogForm := TfrmMtoModalScriptLog.Create(Self);
    LogForm.LogMemo.Lines.Add('-- RESTAURACIÓN DE COPIA DE SEGURIDAD --');
    LogForm.LogMemo.Lines.Add(
      '-------------------------------------------------');
    if ALogBuffer <> nil then
    begin
      LogForm.AppendLines(ALogBuffer);
      FreeAndNil(ALogBuffer);
    end;
    LogForm.Show;
    if AResultado = rcsCompletada then
      ShowMessage(SScriptSuccess)
    else
    begin
      RegistroLog.RegistrarError('Error en restauración: ' + AError);
      ShowMessage(Format(SErrorRestaurarCopiaSeguridad, [AError]));
    end;
  end;
end;

procedure TfrmLogon.PrepararWorkerRestauracion(
  AWorker: TThread);
begin
  FCancelaOperacionSolicitada := False;
  FWorkerOperacion := AWorker;
end;

procedure TfrmLogon.btnCopiaSeguridadClick(Sender: TObject);
var
  iButtonSel: Integer;
  Worker: TBackupWorker;
begin
  ConfigurarYConectarMySQL(FConexionLogon, edtUserBD.Text,
    FPasswordConexion,
    edtHostName.Text,
    edtPortBD.Text,
    edtNomBD.Text);
  iButtonSel := 0;
  saveDialog.Title := STituloGuardarCopiaSeguridad;
  saveDialog.DefaultFolder := GetCurrentDir;
  saveDialog.DefaultExtension := '.crypt';
  savedialog.FileName := 'copiaseguridad_' + FPasswordConexionEncriptado +
                                       FormatDateTime('_dd_mm', Now) + '.crypt';
  if (saveDialog.Execute) then
  begin
    if FileExists(savedialog.FileName) then
    begin
      iButtonSel := MessageDlg(SPreguntaReemplazarFichero,
                               mtCustom, [mbYes, mbNo], 0);
    end;
    if ((iButtonSel = mrYes) or (not FileExists(saveDialog.FileName))) then
    begin
      MostrarBarraProgreso(SCaptionPreparandoCopiaSeguridad);
      Worker := TBackupWorker.Create(
        edtHostName.Text,
        StrToIntDef(edtPortBD.Text, 3306),
        edtNomBD.Text,
        edtUserBD.Text,
        FPasswordConexion,
        saveDialog.FileName,
        True,
        FPasswordConexion);
      Worker.OnProgreso := WorkerProgreso;
      Worker.OnFinalizar := BackupFinalizar;
      FCancelaOperacionSolicitada := False;
      FWorkerOperacion := Worker;
      Worker.Start;
    end;
  end
  else
  begin
    RegistroLog.RegistrarError('La copia se canceló');
    ShowMessage(SCopiaSeguridadCancelada);
  end;
end;

procedure TfrmLogon.btnRecoverClick(Sender: TObject);
begin
  TCoordinadorLogonRestauracionVcl.Ejecutar(
    CrearContextoLogonRestauracionVcl(Self));
end;

procedure TfrmLogon.btnTestClick(Sender: TObject);
begin
  escribirini;
  ConfigurarYConectarMySQL(FConexionLogon,
                            edtUserBD.Text,
                            FPasswordConexion,
                            edtHostName.Text,
                            edtPortBD.Text,
                            edtNomBD.Text);
  RegistroLog.RegistrarInformacion(SconnSuccBBDD);
  ShowMessage(SConnSuccBBDD);
  Exit;
end;

procedure TfrmLogon.btnSalirClick(Sender: TObject);
begin
  if FEnOperacionLarga then
  begin
    SolicitarCancelarOperacionEnCurso;
  end
  else
  begin
    ModalResult := mrCancel;
    Close;
  end;
end;

procedure TfrmLogon.btnAceptarClick(Sender: TObject);
var
  Resultado: TResultadoAutenticacionLogon;
begin
  InvalidarResultadoInicioSesion;
  if not LicenciaAplicacionPreparada then
  begin
    if FCerrarAplicacion then
    begin
      ModalResult := mrCancel;
      Close;
    end
    else
      ModalResult := mrNone;
  end
  else
  begin
    Resultado := FAplicacionLogon.Autenticar(
      edtUser.Text,
      edtPass.Text);
    case Resultado.Estado of
      ealAutenticado:
      begin
        RegistroLog.RegistrarInformacion('Login correcto');
        FResultadoInicioSesion :=
          TResultadoInicioSesion.CrearAutenticado(
            TIdentidadSesion.Crear(
              Resultado.Usuario,
              Resultado.Grupo,
              Resultado.EsGrupoAdministrador),
            TUbicacionSesion.Crear(
              Resultado.Empresa,
              Resultado.Almacen,
              Resultado.Caja));
        SetIniValues;
        PostMessage(Handle, WM_CLOSE, 0, 0);
        ModalResult := mrOK;
      end;
      ealCredencialesInvalidas:
      begin
        RegistroLog.RegistrarAviso(SErrorAuthPass);
        if Sender <> nil then
          ShowMessage(SErrorAuthPass);
        ModalResult := mrNone;
      end;
      ealNoDisponible:
      begin
        RegistroLog.RegistrarError(
          'Autenticación no disponible: ' + Resultado.Mensaje);
        if Sender <> nil then
          ShowMessage(Resultado.Mensaje);
        ModalResult := mrNone;
      end;
      ealError:
      begin
        RegistroLog.RegistrarError(
          'Error de autenticación: ' + Resultado.Mensaje);
        if Sender <> nil then
          ShowMessage(Resultado.Mensaje);
        ModalResult := mrNone;
      end;
    end;
  end;
end;

procedure TfrmLogon.InvalidarResultadoInicioSesion;
begin
  FResultadoInicioSesion :=
    TResultadoInicioSesion.CrearNoAutenticado;
end;

procedure TfrmLogon.edtPassBDExit(Sender: TObject);
begin
end;

procedure TfrmLogon.edtPortBDPropertiesChange(Sender: TObject);
begin
end;

procedure TfrmLogon.escribirini;
begin
  EscribirCadenaIni(
    'ConnData', 'HostName', edtHostName.Text, GetUserFolder);
  EscribirCadenaIni(
    'ConnData', 'Database', edtNomBD.Text, GetUserFolder);
  EscribirCadenaIni(
    'ConnData', 'User', edtUserBD.Text, GetUserFolder);
  EscribirCadenaIni(
    'ConnData', 'Puerto', edtPortBD.Text, GetUserFolder);
  if (edtPassBD.Text <> '') then
  begin
    FPasswordConexion := edtPassBD.Text;
    FPasswordConexionEncriptado := CifrarAES(
      FPasswordConexion);
    EscribirCadenaIni(
      'ConnData',
      'PasswordEn',
      FPasswordConexionEncriptado,
      GetUserFolder);
  end;
end;

procedure tfrmLogon.leerini;
begin
  edtHostName.Text := LeerCadenaIni('ConnData', 'HostName', '127.0.0.1',
                                                                 GetUserFolder);
  edtNomBD.Text := LeerCadenaIni('ConnData', 'Database', 'factuzam',
                                                                 GetUserFolder);
  edtUserBD.Text := LeerCadenaIni(
    'ConnData', 'User', 'root', GetUserFolder);
  edtPortBD.Text := LeerCadenaIni(
    'ConnData', 'Puerto', '3306', GetUserFolder);
end;

procedure TfrmLogon.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if FEnOperacionLarga then
  begin
    if Key = VK_ESCAPE then
      SolicitarCancelarOperacionEnCurso;
    Key := 0;
  end
  else if Key = VK_F12 then
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
    EscribirCadenaIni(
      'UserInfo', 'RememberUser', 'Yes', GetUserFolder);
    EscribirCadenaIni(
      'UserInfo', 'NomUser', edtUser.Text, GetUserFolder);
  end;
  if (chkRememberPassword.Checked = True) then
  begin
    EscribirCadenaIni(
      'UserInfo', 'RememberPassword', 'Yes', GetUserFolder);
    EscribirCadenaIni('UserInfo', 'PasswordEn',
                                       CifrarAES(edtPass.Text),
                                       GetUserFolder);
  end;
  if (chkAuto.Checked = True) then
      EscribirCadenaIni(
        'UserInfo', 'AutoLogin', 'Yes', GetUserFolder);
  escribirini;
end;

procedure TfrmLogon.GetIniValues;
var
  sRememberUser,
  sAutoRun,
  sRememberPassword     : string;
begin
  sRememberUser := LeerCadenaIni('UserInfo',
                                'RememberUser',
                                'No',
                                GetUserFolder);
  sAutoRun := LeerCadenaIni('UserInfo',
                          'AutoLogin',
                          'No',
                          GetUserFolder);
  sRememberPassword := LeerCadenaIni('UserInfo',
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
    edtUser.Text := LeerCadenaIni('UserInfo',
                                'NomUser',
                                'Administrador',
                                GetUserFolder);
  end;
  if SameText(sRememberPassword, 'Yes') then
  begin
    chkRememberPassword.Checked := True;
    edtPass.Text := DescifrarAES(LeerCadenaIni('UserInfo',
                                           'PasswordEn',
                                           'q7heHfD7ENowuvRQhW56Og==',
                                           GetUserFolder));
  end;
  leerini;
  RegistroLog.RegistrarInformacion('Leyendo archivo ini de usuario');
end;

function TfrmLogon.IsInitializeAuto: Boolean;
begin
  // El conmutador /relogin (reinicio desde 'Invocar login' del menu
  // principal) ignora el auto-login para forzar la reidentificacion
  // manual, sin alterar la configuracion guardada del auto-login.
  if FindCmdLineSwitch('relogin', True) then
    Result := False
  else
    Result := chkAuto.Checked;
  {$IFDEF DEBUG}
    //Result := False;
  {$ENDIF }
end;

function TfrmLogon.DebeCerrarAplicacion: Boolean;
begin
  Result := FCerrarAplicacion;
end;

destructor TfrmLogon.Destroy;
begin
  FAplicacionLogon := nil;
  FRepositorioLogon := nil;
  FConexionLogon := nil;
  inherited;
end;

procedure TfrmLogon.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SetIniValues;
  AsignarTraducciones(nil);
  if (FConexionLogon.Connected = true) then
    FConexionLogon.Disconnect;
  FConexionLogon.Pooling := false;
end;

procedure TfrmLogon.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FEnOperacionLarga then
  begin
    CanClose := False;
    SolicitarCancelarOperacionEnCurso;
  end
  else
    CanClose := True;
end;

end.

