{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLogon                                                    }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Esta unidad tiene la primera pantalla donde se autentifica el usuario.    }
{    Presenta la primera pantalla de autenficación de usuario. También permite }
{    Configurar un perfil de conexión de BBDD sin conocer su provider.         }
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
  inLibConexionPerfilIntf,
  inLibConexionesIntf,
  inLibLogonAplicacionIntf,
  inLibArranqueAplicacion;

type
  TfrmLogon = class(TfrmBase, IPasosPreparacionLogon)
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
    procedure GetIniValues;
  private
    FProgressPanel: TPanel;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    FWorkerOperacion: TThread;
    FCerrarAplicacion: Boolean;
    FEnOperacionLarga: Boolean;
    FCancelaOperacionSolicitada: Boolean;
    FFabricaConexiones: IFabricaConexionesUniDAC;
    FPerfilConexionPendiente: TPerfilConexion;
    FCredencialConexionPendiente: string;
    FConfiguracionConexionPendiente: Boolean;
    FResultadoInicioSesion: TResultadoInicioSesion;
    FResultadoLicencia: TResultadoLicenciaAplicacion;
    FCasoUsoRestauracion: ICasoUsoRestauracionConexion;
    FConexionLogon: TUniConnection;
    FRepositorioLogon: IRepositorioLogon;
    FAplicacionLogon: IAplicacionLogon;
    procedure PrepararLogon;
    function ConectarServidorLogon: Boolean;
    function ValidarEstructuraLogon: Boolean;
    function ConectarAplicacionLogon: Boolean;
    function PrepararLicenciaLogon: Boolean;
    procedure PrepararNuevoEquipo;
    procedure AplicarTraduccionesPantalla;
    function ResolverErrorScriptLogon(
      const ASentencia, AError: string): TDecisionErrorScriptLogon;
    procedure CargarPerfilConexion;
    function CrearPerfilConexionFormulario(
      const ABaseDatos: string): TPerfilConexion;
    function ConexionCoincideConPerfil(
      const APerfil: TPerfilConexion): Boolean;
    function PerfilFormularioCoincideConConfigurado: Boolean;
    procedure ConectarPerfilTemporal(
      const APerfil: TPerfilConexion;
      const ACredencial: string;
      APrepararGuardado: Boolean);
    procedure ConectarPerfilFormulario(
      const ABaseDatos: string;
      APrepararGuardado: Boolean);
    procedure ConfirmarConfiguracionConexionVerificada;
    procedure DescartarConfiguracionConexionPendiente;
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
    procedure ConfigurarDialogoCopiaProtegida;
    procedure RestoreFinalizar(AResultado: TResultadoCopiaSeguridad;
                               const AError: string;
                               ALogBuffer: TStringList);
    procedure PrepararWorkerRestauracion(AWorker: TThread);
    function ConexionAplicacionPreparada: Boolean;
    function LicenciaAplicacionPreparada: Boolean;
    function ProcesarLicenciaAplicacion: Boolean;
    procedure InvalidarResultadoInicioSesion;
  public
    constructor Create(
      AOwner: TComponent;
      const AFabricaConexiones: IFabricaConexionesUniDAC); reintroduce;
    destructor Destroy; override;
    function EjecutarAutenticacionAutomatica: Boolean;
    function IsInitializeAuto:Boolean;
    function DebeCerrarAplicacion:Boolean;
    property ResultadoInicioSesion: TResultadoInicioSesion
      read FResultadoInicioSesion;
    property ResultadoLicencia: TResultadoLicenciaAplicacion
      read FResultadoLicencia;
  end;

implementation

uses  inLibWin,
      inLibConfiguracionIni,
      inLibCredencialUsuarioIni,
      inLibNuevoEquipo,
      inLibTraducciones,
      inLibTraduccionesFastReport,
      inLibMsgComun,
      inLibMsgConfiguracion,
      inLibMsgConexion,
      inLibDir,

      Backup.Engine,
      Backup.Types,
      ScriptWriters,
      Core_Interfaces,
      Core_Helpers,
      inLibDBStructure,
      inMtoModalScriptLog,
      inMtoModalContrasenaCopia,
      inMtoModalGenPass,
      inLibCopiasSeguridad,
      inLibRestauracionCopiasConexion,
      UniDataRestauracionCopiasConexion,
      inMtoLogonRestauracionVcl,
      inLibLogonAplicacion,
      inLibProteccionDatosFacturacion,
      UniDataLogonRepositorio,
      UniDataTraduccionesRepositorio,
      UniDataDBStructureRepositorio,
      UniDataLicenciaAplicacionRepositorio;

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
      AFormulario.edtPassBD.Text := AContrasena;
    end;
  Result.MostrarPreparacion :=
    procedure
    begin
      AFormulario.MostrarBarraProgreso(
        SCaptionPreparandoRestauracion);
    end;
end;

{$R *.dfm}

constructor TfrmLogon.Create(
  AOwner: TComponent;
  const AFabricaConexiones: IFabricaConexionesUniDAC);
begin
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  FFabricaConexiones := AFabricaConexiones;
  inherited Create(AOwner);
end;

procedure TfrmLogon.AplicarTraduccionesPantalla;
begin
  AsignarTraducciones(
    TServicioTraducciones.Create(
      TLectorCatalogoTraduccionesUniDAC.Create(FConexionLogon),
      RegistroLog,
      ObtenerIdiomaConfigurado(
        TLectorIdiomaConfiguradoUniDAC.Create(FConexionLogon),
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
var
  sCredencial: string;
  oPerfilFormulario: TPerfilConexion;
  oPerfilAdministrativo: TPerfilConexion;
begin
  sCredencial := InputBox(SSolicitudPassBBDD, '', '');
  DescartarConfiguracionConexionPendiente;
  try
    oPerfilFormulario := CrearPerfilConexionFormulario(
      edtNomBD.Text);
    oPerfilAdministrativo :=
      FFabricaConexiones.CrearPerfilAdministrativo(
        oPerfilFormulario);
    ConectarPerfilTemporal(
      oPerfilAdministrativo,
      sCredencial,
      False);
    if ExisteEsquemaLogonUniDAC(
         FConexionLogon,
         edtNomBD.Text) then
    begin
      ConectarPerfilTemporal(
        oPerfilFormulario,
        sCredencial,
        True);
    end;
    opendialog.Title := STituloCargarScript;
    opendialog.DefaultExtension := 'sql';
    openDialog.DefaultFolder := GetUserDeskFolder;

    if openDialog.Execute then
    begin
      try
        EjecutarScriptLogonUniDAC(
          FConexionLogon,
          opendialog.FileName,
          ResolverErrorScriptLogon);
      except
        on E: EModificacionTablaFacturacionProtegida do
        begin
          RegistroLog.RegistrarAviso(E.Message);
          MessageDlg(E.Message, mtWarning, [mbOK], 0);
          Exit;
        end;
      end;
      if FConfiguracionConexionPendiente then
        ConfirmarConfiguracionConexionVerificada;
      RegistroLog.RegistrarInformacion(
        'El script se ejecutó exitosamente');
      ShowMessage(SScriptEjecutado);
    end
    else
    begin
      DescartarConfiguracionConexionPendiente;
      RegistroLog.RegistrarInformacion(
        'El script no fue ejecutado');
      ShowMessage(SScriptNoEjecutado);
    end;
  finally
    DescartarConfiguracionConexionPendiente;
    if FConexionLogon.Connected then
      FConexionLogon.Disconnect;
  end;
end;

procedure TfrmLogon.FormCreate(Sender: TObject);
begin
  inherited;
  if not EsOrdenParametrosNuevoEquipoValido then
  begin
    FCerrarAplicacion := True;
    ShowMessage(SErrorOrdenParametrosNuevoEquipo);
    Exit;
  end;
  CrearCasoUsoPreparacionLogon(
    Self as IPasosPreparacionLogon).Ejecutar;
end;

procedure TfrmLogon.PrepararLogon;
begin
  InvalidarResultadoInicioSesion;
  CrearRepositorioLogonUniDAC(
    FFabricaConexiones,
    FRepositorioLogon,
    FConexionLogon);
  FAplicacionLogon := CrearAplicacionLogon(FRepositorioLogon);
  // Tamano compacto del login (panel BBDD oculto) calculado desde las
  // coordenadas ya escaladas de los controles, para que los botones no se
  // recorten con escalado DPI (el .dfm no trae PixelsPerInch y el tamano
  // fijo anterior no se reescalaba).
  pnlBBDD.Visible := False;
  Self.ClientWidth :=
    pnlButtons.Left + pnlButtons.Width + pnlButtons.Left;
  Self.ClientHeight := pnlButtons.Top + pnlButtons.Height + pnlLogin.Top;
  {$IFDEF DEBUG}
    RegistroLog.RegistrarInformacion('Arrancando en modo Debug');
  {$ENDIF}
  FCerrarAplicacion := False;
  FEnOperacionLarga := False;
  FCancelaOperacionSolicitada := False;
  FConfiguracionConexionPendiente := False;
  FCredencialConexionPendiente := '';
  FWorkerOperacion := nil;
  FResultadoLicencia :=
    TResultadoLicenciaAplicacion.CrearNoComprobada;
  Self.Position := poScreenCenter;
  edtUser.Text := '';

  GetIniValues;
  if FindCmdLineSwitch('relogin', True) then
    edtPass.Text := '';
  CargarPerfilConexion;
end;

procedure TfrmLogon.CargarPerfilConexion;
var
  oPerfil: TPerfilConexion;
begin
  oPerfil := FFabricaConexiones.Perfil;
  edtHostName.Text := oPerfil.Servidor;
  edtPortBD.Text := IntToStr(oPerfil.Puerto);
  edtNomBD.Text := oPerfil.BaseDatos;
  edtUserBD.Text := oPerfil.Usuario;
  edtPassBD.Text := '';
end;

function TfrmLogon.CrearPerfilConexionFormulario(
  const ABaseDatos: string): TPerfilConexion;
begin
  Result := FFabricaConexiones.Perfil;
  Result.Servidor := Trim(edtHostName.Text);
  Result.Puerto := StrToIntDef(Trim(edtPortBD.Text), 0);
  Result.BaseDatos := Trim(ABaseDatos);
  Result.Usuario := Trim(edtUserBD.Text);
end;

function TfrmLogon.ConexionCoincideConPerfil(
  const APerfil: TPerfilConexion): Boolean;
begin
  Result := Assigned(FConexionLogon) and
    FConexionLogon.Connected and
    SameText(FConexionLogon.Server, APerfil.Servidor) and
    (FConexionLogon.Port = APerfil.Puerto) and
    SameText(FConexionLogon.Database, APerfil.BaseDatos) and
    SameText(FConexionLogon.Username, APerfil.Usuario);
end;

function TfrmLogon.PerfilFormularioCoincideConConfigurado: Boolean;
var
  oConfigurado: TPerfilConexion;
  oFormulario: TPerfilConexion;
begin
  oConfigurado := FFabricaConexiones.Perfil;
  oFormulario := CrearPerfilConexionFormulario(
    edtNomBD.Text);
  Result := (oFormulario.Motor = oConfigurado.Motor) and
    SameText(oFormulario.Servidor, oConfigurado.Servidor) and
    (oFormulario.Puerto = oConfigurado.Puerto) and
    SameText(oFormulario.BaseDatos, oConfigurado.BaseDatos) and
    SameText(oFormulario.Usuario, oConfigurado.Usuario);
end;

procedure TfrmLogon.ConectarPerfilTemporal(
  const APerfil: TPerfilConexion;
  const ACredencial: string;
  APrepararGuardado: Boolean);
begin
  DescartarConfiguracionConexionPendiente;
  if FConexionLogon.Connected then
    FConexionLogon.Disconnect;
  FFabricaConexiones.ConectarTemporal(
    FConexionLogon,
    APerfil,
    ACredencial);
  if APrepararGuardado then
  begin
    FPerfilConexionPendiente := APerfil;
    FCredencialConexionPendiente := ACredencial;
    FConfiguracionConexionPendiente := True;
  end;
end;

procedure TfrmLogon.ConectarPerfilFormulario(
  const ABaseDatos: string;
  APrepararGuardado: Boolean);
var
  sCredencial: string;
begin
  sCredencial := edtPassBD.Text;
  if (sCredencial = '') and
     SameText(ABaseDatos, edtNomBD.Text) and
     PerfilFormularioCoincideConConfigurado then
  begin
    DescartarConfiguracionConexionPendiente;
    if FConexionLogon.Connected then
      FConexionLogon.Disconnect;
    FFabricaConexiones.Conectar(FConexionLogon);
  end
  else
  begin
    ConectarPerfilTemporal(
      CrearPerfilConexionFormulario(ABaseDatos),
      sCredencial,
      APrepararGuardado);
  end;
end;

procedure TfrmLogon.ConfirmarConfiguracionConexionVerificada;
begin
  if FConfiguracionConexionPendiente then
  begin
    FFabricaConexiones.ActualizarConfiguracion(
      FPerfilConexionPendiente,
      FCredencialConexionPendiente);
  end;
  FFabricaConexiones.GuardarConfiguracion;
  edtPassBD.Text := '';
  DescartarConfiguracionConexionPendiente;
end;

procedure TfrmLogon.DescartarConfiguracionConexionPendiente;
begin
  FConfiguracionConexionPendiente := False;
  FPerfilConexionPendiente := Default(TPerfilConexion);
  FCredencialConexionPendiente := '';
end;

function TfrmLogon.ConectarServidorLogon: Boolean;
begin
  Result := True;
  try
    ConectarPerfilFormulario(
      edtNomBD.Text,
      True);
  except
    on E: Exception do
    begin
      DescartarConfiguracionConexionPendiente;
      RegistroLog.RegistrarError(
        Format(SErrorConexionServidorBBDD, [E.Message]));
      ShowMessage(Format(SErrorConexionServidorBBDD, [E.Message]));
      chkAuto.Checked := False;
      EscribirCadenaIni(
        'UserInfo', 'AutoLogin', 'No', GetUserFolder);
      if not pnlBBDD.Visible then
        btnConfClick(Self);
      Result := False;
    end;
  end;
end;

function TfrmLogon.ValidarEstructuraLogon: Boolean;
var
  CheckResult: TDBStructureCheckResult;
begin
  Result := True;
  CheckResult := UniDataDBStructureRepositorio.TDBStructureChecker.Check(
    FConexionLogon,
    edtNomBD.Text);
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
    DescartarConfiguracionConexionPendiente;
    Result := False;
  end;
end;

function TfrmLogon.ConectarAplicacionLogon: Boolean;
var
  oPerfil: TPerfilConexion;
begin
  Result := True;
  try
    oPerfil := CrearPerfilConexionFormulario(
      edtNomBD.Text);
    if not ConexionCoincideConPerfil(oPerfil) then
    begin
      ConectarPerfilFormulario(
        edtNomBD.Text,
        True);
    end;
    ConfirmarConfiguracionConexionVerificada;
  except
    on E: Exception do
    begin
      DescartarConfiguracionConexionPendiente;
      RegistroLog.RegistrarError(
        Format(SErrorConexionBBDD,
          [edtNomBD.Text, E.Message]));
      ShowMessage(Format(SErrorConexionBBDD,
                         [edtNomBD.Text, E.Message]));
      chkAuto.Checked := False;
      EscribirCadenaIni(
        'UserInfo', 'AutoLogin', 'No', GetUserFolder);
      if not pnlBBDD.Visible then
        btnConfClick(Self);
      Result := False;
    end;
  end;
end;

function TfrmLogon.PrepararLicenciaLogon: Boolean;
begin
  AplicarTraduccionesPantalla;
  Result := ProcesarLicenciaAplicacion;
end;

procedure TfrmLogon.PrepararNuevoEquipo;
var
  bConmutadorMantenimiento: Boolean;
  bPendienteInstalacion: Boolean;
  oPerfil: TPerfilConexion;
  sContrasenaNueva: string;
  sRutaIni: string;
begin
  sRutaIni := RutaIniAplicacion(GetUserFolder);
  bConmutadorMantenimiento := HayConmutadorNuevoEquipo;
  bPendienteInstalacion :=
    HayNuevoEquipoPendienteEnIni(sRutaIni);
  if bPendienteInstalacion then
  begin
    oPerfil := FFabricaConexiones.Perfil;
    bPendienteInstalacion := EsPerfilInstalacionDemoLocal(
      oPerfil.Servidor,
      oPerfil.BaseDatos,
      oPerfil.Usuario,
      oPerfil.Puerto);
    if not bPendienteInstalacion then
    begin
      RegistroLog.RegistrarAviso(
        'Se ignoró una marca de nuevo equipo fuera del perfil demo local.');
    end;
  end;
  if not bConmutadorMantenimiento and
     not bPendienteInstalacion then
    Exit;
  { El destino no se toma del INI: NomUser es editable y no concede
    autoridad para restablecer una cuenta arbitraria. }
  edtUser.Text := USUARIO_INICIAL_NUEVO_EQUIPO;
  if not TfrmModalGenPass.SolicitarNueva(
           Self,
           edtUser.Text,
           sContrasenaNueva) then
  begin
    RegistroLog.RegistrarInformacion(
      'Configuración de nuevo equipo cancelada.');
    FCerrarAplicacion := True;
    Exit;
  end;
  try
    try
      FAplicacionLogon.EstablecerContrasenaNuevoEquipo(
        edtUser.Text,
        sContrasenaNueva,
        bPendienteInstalacion and
          not bConmutadorMantenimiento);
    except
      on E: ENuevoEquipoDemoYaPreparado do
      begin
        try
          CompletarNuevoEquipoPendienteEnIni(sRutaIni);
        except
          on ECompletar: Exception do
          begin
            RegistroLog.RegistrarAviso(
              'No se pudo retirar la marca ya consumida de primera ' +
              'ejecución: ' + ECompletar.Message);
          end;
        end;
        RegistroLog.RegistrarAviso(E.Message);
        ShowMessage(E.Message);
        Exit;
      end;
      on E: Exception do
      begin
        RegistroLog.RegistrarError(
          'No se pudo completar el arranque de mantenimiento: ' +
          E.ClassName + ': ' + E.Message);
        ShowMessage(Format(SErrorPrepararNuevoEquipo, [E.Message]));
        edtPass.Text := '';
        FCerrarAplicacion := True;
        Exit;
      end;
    end;

    edtPass.Text := sContrasenaNueva;
    { Conserva exactamente las opciones existentes, pero sustituye ahora la
      credencial recordada para no dejar la contraseña anterior si el
      usuario cierra el login manual que pueda mostrarse a continuación. }
    try
      SetIniValues;
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarError(
          'La contraseña se cambió, pero no se pudieron guardar las ' +
          'preferencias de inicio: ' + E.ClassName + ': ' + E.Message);
        ShowMessage(Format(
          SErrorGuardarInicioTrasNuevoEquipo,
          [E.Message]));
      end;
    end;
    if bPendienteInstalacion then
    begin
      try
        CompletarNuevoEquipoPendienteEnIni(sRutaIni);
      except
        on E: Exception do
        begin
          RegistroLog.RegistrarAviso(
            'La contraseña se cambió, pero quedó pendiente retirar la ' +
            'marca de primera ejecución: ' + E.Message);
          ShowMessage(Format(
            SErrorCompletarNuevoEquipoPendiente,
            [E.Message]));
        end;
      end;
    end;
    RegistroLog.RegistrarInformacion(
      'Contraseña de acceso restablecida mediante el arranque de ' +
      'mantenimiento.');
  finally
    { El control conserva la única copia que consumirá el login. }
    sContrasenaNueva := '';
  end;
end;

function TfrmLogon.ConexionAplicacionPreparada: Boolean;
var
  CheckResult: TDBStructureCheckResult;
  oPerfil: TPerfilConexion;
begin
  Result := False;
  oPerfil := CrearPerfilConexionFormulario(
    edtNomBD.Text);
  try
    if ConexionCoincideConPerfil(oPerfil) and
       (edtPassBD.Text = '') then
    begin
      ConfirmarConfiguracionConexionVerificada;
      Exit(True);
    end;
    ConectarPerfilFormulario(
      edtNomBD.Text,
      True);
    CheckResult := UniDataDBStructureRepositorio.TDBStructureChecker.Check(
      FConexionLogon,
      edtNomBD.Text);
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
      DescartarConfiguracionConexionPendiente;
      Exit;
    end;
    ConfirmarConfiguracionConexionVerificada;
    Result := True;
  except
    on E: Exception do
    begin
      DescartarConfiguracionConexionPendiente;
      RegistroLog.RegistrarError(
        Format(SErrorConexionBBDD,
          [edtNomBD.Text, E.Message]));
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
      if UniDataLicenciaAplicacionRepositorio.RegistrarLicenciaAplicacion(
                                     FConexionLogon,
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
      if UniDataLicenciaAplicacionRepositorio.ComprobarLicenciaAplicacion(
                                     FConexionLogon,
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
  if (FProgressBar <> nil) and FProgressBar.Visible then
  begin
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
end;

procedure TfrmLogon.BackupFinalizar(
  AResultado: TResultadoCopiaSeguridad;
  const AError: string; ALogBuffer: TStringList);
begin
  FWorkerOperacion := nil;
  FCasoUsoRestauracion := CrearCasoUsoRestauracionConexion(
    CrearRepositorioRestauracionConexionUniDAC(
      FConexionLogon,
      FFabricaConexiones));
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

procedure TfrmLogon.ConfigurarDialogoCopiaProtegida;
var
  oTipoFichero: TFileTypeItem;
begin
  saveDialog.Title := STituloGuardarCopiaSeguridad;
  saveDialog.DefaultFolder := GetCurrentDir;
  saveDialog.DefaultExtension := 'crypt';
  saveDialog.Options := saveDialog.Options +
    [fdoStrictFileTypes];
  saveDialog.FileTypes.Clear;
  oTipoFichero := saveDialog.FileTypes.Add;
  oTipoFichero.DisplayName := SCaptionFiltroCopiasCifradas;
  oTipoFichero.FileMask := '*.crypt';
  saveDialog.FileTypeIndex := 1;
  saveDialog.FileName := 'copiaseguridad' +
    FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) + '.crypt';
end;

procedure TfrmLogon.btnCopiaSeguridadClick(Sender: TObject);
var
  iButtonSel: Integer;
  oWorker: TThread;
  sContrasenaCopia: string;
begin
  if not TfrmModalContrasenaCopia.SolicitarNueva(
           Self,
           sContrasenaCopia) then
    Exit;
  ConectarPerfilFormulario(
    edtNomBD.Text,
    True);
  iButtonSel := 0;
  ConfigurarDialogoCopiaProtegida;
  if (saveDialog.Execute) then
  begin
    saveDialog.FileName := ChangeFileExt(
      saveDialog.FileName,
      '.crypt');
    if FileExists(savedialog.FileName) then
    begin
      iButtonSel := MessageDlg(SPreguntaReemplazarFichero,
                               mtCustom, [mbYes, mbNo], 0);
    end;
    if ((iButtonSel = mrYes) or (not FileExists(saveDialog.FileName))) then
    begin
      ConfirmarConfiguracionConexionVerificada;
      MostrarBarraProgreso(SCaptionPreparandoCopiaSeguridad);
      oWorker := CrearWorkerCopiaProtegidaConexion(
        FConexionLogon,
        saveDialog.FileName,
        sContrasenaCopia,
        WorkerProgreso,
        BackupFinalizar);
      FCancelaOperacionSolicitada := False;
      FWorkerOperacion := oWorker;
      try
        oWorker.Start;
      except
        FWorkerOperacion := nil;
        FreeAndNil(oWorker);
        DescartarConfiguracionConexionPendiente;
        raise;
      end;
    end;
    if (iButtonSel <> mrYes) and
       FileExists(saveDialog.FileName) then
      DescartarConfiguracionConexionPendiente;
  end
  else
  begin
    DescartarConfiguracionConexionPendiente;
    RegistroLog.RegistrarError('La copia se canceló');
    ShowMessage(SCopiaSeguridadCancelada);
  end;
  sContrasenaCopia := '';
end;

procedure TfrmLogon.btnRecoverClick(Sender: TObject);
begin
  TCoordinadorLogonRestauracionVcl.Ejecutar(
    CrearContextoLogonRestauracionVcl(Self));
end;

procedure TfrmLogon.btnTestClick(Sender: TObject);
begin
  ConectarPerfilFormulario(
    edtNomBD.Text,
    True);
  ConfirmarConfiguracionConexionVerificada;
  RegistroLog.RegistrarInformacion(SconnSuccBBDD);
  ShowMessage(SConnSuccBBDD);
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

function TfrmLogon.EjecutarAutenticacionAutomatica: Boolean;
begin
  Result := False;
  try
    btnAceptarClick(nil);
    Result := FResultadoInicioSesion.Autenticado;
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarError(
        'Fallo en auto-login: ' + E.ClassName + ': ' + E.Message);
      ShowMessage(Format(SErrorInicioAutomatico, [E.Message]));
      InvalidarResultadoInicioSesion;
      ModalResult := mrNone;
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
var
  bCredencialEliminada: Boolean;
  sErrorEliminarCredencial: string;
  sRutaIni: string;
begin
  sRutaIni := RutaIniAplicacion(GetUserFolder);
  if chkRememberUser.Checked then
  begin
    EscribirCadenaIni(
      'UserInfo', 'RememberUser', 'Yes', GetUserFolder);
    EscribirCadenaIni(
      'UserInfo', 'NomUser', edtUser.Text, GetUserFolder);
  end
  else
  begin
    EscribirCadenaIni(
      'UserInfo', 'RememberUser', 'No', GetUserFolder);
  end;

  if chkRememberPassword.Checked then
  begin
    try
      GuardarContrasenaUsuarioRecordada(
        sRutaIni,
        edtPass.Text);
      EscribirCadenaIni(
        'UserInfo', 'RememberPassword', 'Yes', GetUserFolder);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarError(
          'No se pudo proteger la contraseña recordada: ' +
          E.ClassName + ': ' + E.Message);
        bCredencialEliminada := True;
        sErrorEliminarCredencial := '';
        try
          EliminarContrasenaUsuarioRecordada(sRutaIni);
        except
          on EEliminar: Exception do
          begin
            bCredencialEliminada := False;
            sErrorEliminarCredencial := EEliminar.Message;
            RegistroLog.RegistrarError(
              'Tampoco se pudo retirar la contraseña recordada: ' +
              EEliminar.ClassName + ': ' + EEliminar.Message);
          end;
        end;
        chkAuto.Checked := False;
        if bCredencialEliminada then
        begin
          chkRememberPassword.Checked := False;
          EscribirCadenaIni(
            'UserInfo', 'RememberPassword', 'No', GetUserFolder);
          ShowMessage(Format(
            SErrorGuardarContrasenaUsuario,
            [E.Message]));
        end
        else
        begin
          { No se oculta una credencial que quizá siga en el fichero. }
          chkRememberPassword.Checked := True;
          EscribirCadenaIni(
            'UserInfo', 'RememberPassword', 'Yes', GetUserFolder);
          ShowMessage(Format(
            SErrorGuardarContrasenaUsuarioNoRetirada,
            [E.Message, sErrorEliminarCredencial]));
        end;
      end;
    end;
  end
  else
  begin
    bCredencialEliminada := True;
    try
      EliminarContrasenaUsuarioRecordada(sRutaIni);
    except
      on E: Exception do
      begin
        bCredencialEliminada := False;
        RegistroLog.RegistrarError(
          'No se pudo retirar la contraseña recordada: ' +
          E.ClassName + ': ' + E.Message);
        chkRememberPassword.Checked := True;
        chkAuto.Checked := False;
        EscribirCadenaIni(
          'UserInfo', 'RememberPassword', 'Yes', GetUserFolder);
        ShowMessage(Format(
          SErrorEliminarContrasenaUsuario,
          [E.Message]));
      end;
    end;
    if bCredencialEliminada then
    begin
      EscribirCadenaIni(
        'UserInfo', 'RememberPassword', 'No', GetUserFolder);
    end;
  end;

  if chkAuto.Checked then
    EscribirCadenaIni(
      'UserInfo', 'AutoLogin', 'Yes', GetUserFolder)
  else
    EscribirCadenaIni(
      'UserInfo', 'AutoLogin', 'No', GetUserFolder);
end;

procedure TfrmLogon.GetIniValues;
var
  sRememberUser,
  sAutoRun,
  sRememberPassword,
  sRutaIni: string;
begin
  sRutaIni := RutaIniAplicacion(GetUserFolder);
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
    try
      edtPass.Text := CargarContrasenaUsuarioRecordada(sRutaIni);
      if edtPass.Text = '' then
      begin
        RegistroLog.RegistrarAviso(
          'No hay una contraseña de usuario recordada utilizable.');
      end;
    except
      on E: Exception do
      begin
        edtPass.Text := '';
        RegistroLog.RegistrarAviso(
          'No se pudo recuperar la contraseña recordada: ' +
          E.ClassName + ': ' + E.Message);
      end;
    end;
  end;
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
    Result := chkAuto.Checked and
      (Trim(edtUser.Text) <> '') and
      (edtPass.Text <> '');
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
  FFabricaConexiones := nil;
  inherited;
end;

procedure TfrmLogon.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DescartarConfiguracionConexionPendiente;
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

