{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipal                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para presentar la pantalla    }
{    Principal de entrada al programa donde está el menú con todas las opcio-  }
{    nes disponibles. Guarda estructuras como Conexión a BBDD.                 }
{******************************************************************************}
unit inMtoPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils,
  System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, SynEditHighlighter,
  SynHighlighterSQL,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxCore, cxContainer,
  cxEdit, dxSkinsForm, cxStyles, cxClasses, Vcl.ExtCtrls, cxLabel,
  Vcl.Menus, cxPC, cxTextEdit, cxMemo, inMtoFrmBase, UniDataConn,
  UniDataPerfiles, cxLocalization, Vcl.Buttons, inLibUnitForm, JvMenus,
  System.UITypes, DAScript, Uni, dxShellDialogs, dxSkinsCore, dxSkinBlue,
  JvComponentBase, JvEnterTab, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue,
  inLibFormManager, System.Actions,
  Vcl.ComCtrls, JvExComCtrls, JvStatusBar, SynEdit,
  Backup.Engine, Backup.Types, Providers_MySQL, Providers_MySQL_Helpers,
  ScriptWriters, Core_Interfaces, Core_Helpers, UniScript, System.Diagnostics,
  System.Threading,
  dxGDIPlusClasses, cxImage, Vcl.Imaging.pngimage;

const
  WM_FREECONTROL = WM_USER;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(TfrmBase)
    mnuCaja: TMenuItem;
    mnuMenuCaja: TMenuItem;
    mnuAlmacenes: TMenuItem;
    mnuInvocarLogin: TMenuItem;
    mnuCajaParam: TMenuItem;
    JvStatusBar1: TJvStatusBar;
    saveDialog: TFileSaveDialog;
    openDialog: TFileOpenDialog;
    mnuParmetrosdeEntorno: TMenuItem;
    N2: TMenuItem;
    Compras1: TMenuItem;
    FormasdePagoCaja1: TMenuItem;
    mnuFormaPagoVenta: TMenuItem;
    Pedidos1: TMenuItem;
    Albaranes1: TMenuItem;
    Facturas1: TMenuItem;
    Sesiones1: TMenuItem;
    mnuCrearArtculosyunpedidoounalbarn: TMenuItem;
    Formasdepago2: TMenuItem;
    dxSkinController1: TdxSkinController;
    mnuAlmacen: TMenuItem;
    Movimientosdealmacn1: TMenuItem;
    mnuInventarios: TMenuItem;
    mnuPropiedades: TMenuItem;
    mnuVariaciones: TMenuItem;
    mnuAtributosConjuntos: TMenuItem;
    mnuAtributosBasicos: TMenuItem;
    mnuCajaPagosHist: TMenuItem;
    mnuCajaValesHist: TMenuItem;
    mnuCajaOperacionesHist: TMenuItem;
    mnuDepositosCliente: TMenuItem;
    mnuFacturasSimplif: TMenuItem;
    mnuCajaArqueosHist: TMenuItem;
    mnuAlmacenInformes: TMenuItem;
    mnuBalanceAlmacenHorizontal: TMenuItem;
    mnuBalanceAlmacenSinTallas: TMenuItem;
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuAlmacenesClick(Sender: TObject);
    procedure mnuInvocarLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure mnuFormaPagoVentaClick(Sender: TObject);
    procedure mnuParmetrosdeEntornoClick(Sender: TObject);
    procedure mnuInventariosClick(Sender: TObject);
    procedure mnuPropiedadesClick(Sender: TObject);
//    procedure mnuPropiedadesValoresClick(Sender: TObject);
    procedure mnuVariacionesClick(Sender: TObject);
    procedure mnuAtributosConjuntosClick(Sender: TObject);
    procedure mnuAtributosBasicosClick(Sender: TObject);
    procedure mnuCajaPagosHistClick(Sender: TObject);
    procedure mnuCajaValesHistClick(Sender: TObject);
    procedure mnuCajaOperacionesHistClick(Sender: TObject);
    procedure mnuCajaArqueosHistClick(Sender: TObject);
    procedure FormasdePagoCaja1Click(Sender: TObject);
    procedure mnuFacturasSimplifClick(Sender: TObject);
    procedure Movimientosdealmacn1Click(Sender: TObject);
    procedure mnuBalanceAlmacenHorizontalClick(Sender: TObject);
    procedure mnuBalanceAlmacenSinTallasClick(Sender: TObject);
    procedure mnuDepositosClienteClick(Sender: TObject);
    procedure pcPrincipalChange(Sender: TObject);
  public
    // Re-vincula la pantalla flotante de fotos (si esta abierta) al
    // Mto recibido y refresca el articulo / SKU activo. NO la abre
    // automaticamente: para abrirla el usuario debe pulsar Ctrl+F
    // en el Mto activo. Llamado desde pcPrincipalChange (cambio de
    // pestana) y desde TfrmMtoGen.FormShow para mantener el contexto.
    procedure EngancharFotoAlMto(AMto: TObject);
  published
    tmr1: TTimer;
    StyleRepository1: TcxStyleRepository;
    StylCab: TcxStyle;
    EditStyleController: TcxEditStyleController;
    LookAndFeelController1: TcxLookAndFeelController;
    Panel1: TPanel;
    pcPrincipal: TcxPageControl;
    imgFondoLogo: TImage;
    pnlPPBottom: TPanel;
    cxMemo1: TcxMemo;
    jvMnMenuPrin: TJvMainMenu;
    Archivo1: TMenuItem;
    Ventas1: TMenuItem;
    Utilidades1: TMenuItem;
    Ayuda1: TMenuItem;
    mnuEmpresas: TMenuItem;
    mnuClientes: TMenuItem;
    mnuProveedores: TMenuItem;
    mnuArticulos: TMenuItem;
    mnuFacturas: TMenuItem;
    ablasAuxiliares1: TMenuItem;
    mnuTarifas: TMenuItem;
    mnuFamilias: TMenuItem;
    Salir1: TMenuItem;
    mnuGruposdeIVA: TMenuItem;
    mnuIvas: TMenuItem;
    mnuContadores: TMenuItem;
    mnuPaises: TMenuItem;
    mnuUnidadesMedida: TMenuItem;
    N1: TMenuItem;
    UsuariosGruposyPerfiles1: TMenuItem;
    HacerCopiadeSeguridad1: TMenuItem;
    mnuEjecutarScript: TMenuItem;
    mnuGeneradorProcesos: TMenuItem;
    mnuUsuarios: TMenuItem;
    mnuEmpleados: TMenuItem;
    mnuGrupos: TMenuItem;
    mnuPerfiles: TMenuItem;
    mnuPermisos: TMenuItem;
    mnuPermisosTabla: TMenuItem;
    Acercade1: TMenuItem;
    Listados1: TMenuItem;
    mnuLisVentas: TMenuItem;
    mnuPedidosVenta: TMenuItem;
    mnuAlbaranesVenta: TMenuItem;
    procedure mnuPedidosVentaClick(Sender: TObject);
    procedure mnuAlbaranesVentaClick(Sender: TObject);
    procedure Sesiones1Click(Sender: TObject);
    procedure Albaranes1Click(Sender: TObject);
    procedure Pedidos1Click(Sender: TObject);
    procedure mnuEmpresasClick(Sender: TObject);
    procedure mnuClientesClick(Sender: TObject);
    procedure mnuProveedoresClick(Sender: TObject);
    procedure mnuArticulosClick(Sender: TObject);
    procedure mnuTarifasClick(Sender: TObject);
    procedure mnuFamiliasClick(Sender: TObject);
    procedure mnArchivoSalirClick(Sender: TObject);
    procedure mnuFacturasClick(Sender: TObject);
    procedure mnuGruposdeIVAClick(Sender: TObject);
    procedure mnuIvasClick(Sender: TObject);
    procedure mnuContadoresClick(Sender: TObject);
    procedure mnuUsuariosClick(Sender: TObject);
    procedure mnuEmpleadosClick(Sender: TObject);
    procedure mnuGruposClick(Sender: TObject);
    procedure mnuPerfilesClick(Sender: TObject);
    procedure mnuPermisosClick(Sender: TObject);
    procedure mnuPermisosTablaClick(Sender: TObject);
    procedure CopiasdeSeguridad1Click(Sender: TObject);
    procedure mnuEjecutarScriptClick(Sender: TObject);
    procedure mnuGeneradorProcesosClick(Sender: TObject);
    procedure mnuPaisesClick(Sender: TObject);
    procedure mnuUnidadesMedidaClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure mnuAcercadeClick(Sender: TObject);
    function IsShortCut(var Message: TWMKey): Boolean; override;
//    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
//      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure WMFreeControl(var Msg: TMessage); message WM_USER + 1;
    procedure LogFormClose(Sender: TObject; var Action: TCloseAction);
  private
    FException: Boolean;
    FStopwatch: TStopwatch;
    FLogForm: TForm;
    FLogMemo: TSynEdit;
    FLogBuffer: TStringList;
    FSavedNCMValid: Boolean;
    FExceptionDialogMemo: TcxMemo;
    FEnOperacionLarga: Boolean;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    FReiniciando: Boolean;
    procedure AppException(Sender: TObject; E: Exception);
    function ConstruirDetalleException(Sender: TObject; E: Exception): string;
    procedure MostrarDetalleExcepcion(const ATexto: string);
    procedure CopiarExceptionDialogClick(Sender: TObject);
    procedure AplicarPermisosMenu;
    // Precarga de caches de arranque. El modo (serie / paralelo) lo decide
    // el parametro appArranqueEnParalelo.
    procedure PrecargarCachesSerie;
    procedure PrecargarCachesParalelo;
    function CrearConexionPrecarga: TUniConnection;
    function EjecutarCargaWorker(ACarga: TProc<TUniConnection>;
                                 out AError: string): Int64;
    function CopiaSeguridad: Boolean;
    procedure WorkerProgreso(const AEtapa: string;
                              APaso, ATotal: Integer;
                              AFilaGlobal,
                              AFilasGlobalTotal: Integer);
    procedure BackupFinalizar(AExito: Boolean; const AError: string;
                               ALogBuffer: TStringList);
    procedure RestoreFinalizar(AExito: Boolean; const AError: string;
                                ALogBuffer: TStringList);
    procedure MostrarBarraProgreso;
    procedure OcultarBarraProgreso;
    function ContieneDDL(const ASQL: string): Boolean;
    procedure ActualizarFondoLogo;
    procedure CargarFondoLogo;
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    // Atajos globales capturados a nivel de aplicacion (las ventanas de caja
    // son top-level y no pasan por IsShortCut): F9 abre cajon en caja y
    // Ctrl+U abre la consulta de stock en cualquier pantalla.
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure UniScript1Error(Sender: TObject; E: Exception; SQL: string;
                              var Action: TErrorAction);
    procedure ScriptAfterExecute(Sender: TObject;
                                 SQL: string);
    procedure ScriptBeforeExecute(Sender: TObject;
                                  var SQL: string;
                                  var Omit: Boolean);
  public
    { Public declarations }
    FormManager : TEmbeddedFormManager;
    FDmConn: TdmConn;
    FdmDataPerfiles: TdmPerfiles;
    oFzaWinf: TfzaWinF;
    // Splash mostrado al arrancar; lo libera CerrarSplashInicio al final
    // del FormCreate, respetando un suelo minimo de visibilidad.
    FSplashInicio:    TObject;
    FSplashTimestamp: TDateTime;
    // Logo de fondo + nombre + version creados dinamicamente sobre Panel1.
    // Replica visual del splash; visibles cuando no hay pestañas abiertas
    // y ocultos en cuanto se abre cualquier mantenimiento.
    FLogoBgPanel:   TObject;
    FLogoBgImage:   TObject;
    FLogoBgNombre:  TObject;
    FLogoBgVersion: TObject;
    procedure CerrarSplashInicio(aMinimoMs: Integer);
    procedure CrearLogoFondoBg;
    procedure CentrarLogoFondoBg;
    procedure FormResize(Sender: TObject);
  end;

var
  frmMtoPrincipal: TfrmMtoPrincipal;
  bIsConnected: Boolean;

implementation

uses inLibUser,
  inLibWin,
  inLibShowMto,
  inLibtb,
  inLibGlobalVar,
  inLibInformesGuiasCache,
  inLibConfigCampos,
  inLibPermisos,
  inLibLog,
  inLibDir,
  inMtoSplash,
  inMtoAppParam,
  inMtoCajaMenu,
  inMtoCajaParam,
  inLibGenerarTicketCaja,
  inMtoStockConsulta,
  inMtoModalGenFilter,
  inMtoModalScriptLog,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inLibCajaParam,
  inLibAppParam,
  inLibUnidadesMedida,
  inLibBuscarImpresora,
  inMtoGen,
  inMtoFotoArticulo,
  System.RegularExpressions,
  Vcl.StdCtrls,
  inLibBackupWorker,
  Vcl.Clipbrd;

{$R *.dfm}

procedure TfrmMtoPrincipal.LogFormClose(Sender: TObject;
                                        var Action: TCloseAction);
begin
  Action := caFree;
  FLogForm := nil;
  FLogMemo := nil;
end;

procedure TfrmMtoPrincipal.ScriptBeforeExecute(Sender: TObject;
                                               var SQL: string;
                                               var Omit: Boolean);
begin
  if FLogBuffer = nil then
    FLogBuffer := TStringList.Create;
  FLogBuffer.Add(' -- Ejecutando (' +
                  FormatDateTime('hh:nn:ss.zzz', Now) + '): ');
  FLogBuffer.Add(SQL);
  FStopwatch := TStopwatch.StartNew;
end;

procedure TfrmMtoPrincipal.ScriptAfterExecute(Sender: TObject; SQL: string);
begin
  FStopwatch.Stop;
  if FLogBuffer <> nil then
  begin
    FLogBuffer.Add(Format(' -- [OK] Filas afectadas: %d | Tiempo: %d ms',
                           [(Sender as TUniScript).RowsAffected,
                           FStopwatch.ElapsedMilliseconds]));
    FLogBuffer.Add('--------------------------------------------------');
  end;
  // Actualizar barra de progreso (cada 20 sentencias)
  if (FProgressBar <> nil) and FProgressBar.Visible then
  begin
    FProgressBar.Position := FProgressBar.Position + 1;
    if (FProgressBar.Position mod 20) = 0 then
    begin
      FProgressLabel.Caption :=
        Format('Sentencia %d / %d...',
               [FProgressBar.Position, FProgressBar.Max]);
      FProgressBar.Update;
      FProgressLabel.Update;
    end;
  end;
end;

function TfrmMtoPrincipal.ContieneDDL(const ASQL: string): Boolean;
var
  Patron: string;
begin
  Patron := '\b(CREATE|ALTER|DROP|TRUNCATE|RENAME)\b';
  Result := TRegEx.IsMatch(ASQL, Patron, [roIgnoreCase]);
end;

procedure TfrmMtoPrincipal.UniScript1Error(Sender: TObject;
                                           E: Exception;
                                           SQL: string;
                                           var Action: TErrorAction);
var
  Respuesta: Integer;
begin
  if Assigned(FLogMemo) then
  begin
    FStopwatch.Stop;
    FLogMemo.Lines.Add('  [ERROR] ' + E.Message + Format(' Tiempo: %d ms',
                                   [FStopwatch.ElapsedMilliseconds]));
    FLogMemo.Lines.Add('--------------------------------------------------');
    FLogMemo.SelStart := Length(FLogMemo.Text);
    SendMessage(FLogMemo.Handle, EM_SCROLLCARET, 0, 0);
    Application.ProcessMessages;
  end;
  var MsgCorta := E.Message;
  if Length(MsgCorta) > 200 then
    MsgCorta := Copy(MsgCorta, 1, 200) + '...';
  Respuesta := MessageDlg(
    'Ocurrió un error ejecutando el script.' +  sLineBreak +
    'Detalle del error: ' + MsgCorta + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?',
    mtError, [mbYes, mbNo], 0);
  if Respuesta = mrYes then
    Action := eaContinue
  else
    Action := eaFail;
end;

procedure TfrmMtoPrincipal.ApplicationEvents1Idle(Sender: TObject;
                                                  var Done: Boolean);
var
  EstadoTeclas: string;
begin
  if FEnOperacionLarga then
  begin
    Done := True;
    Exit;
  end;
  EstadoTeclas := '';
  if (GetKeyState(VK_CAPITAL) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'CAPS  ';
  if (GetKeyState(VK_NUMLOCK) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'NUM  ';
  if (GetKeyState(VK_SCROLL) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'SCRL  ';
  if (GetKeyState(VK_INSERT) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'OVR'
  else
    EstadoTeclas := EstadoTeclas + 'INS';
  EstadoTeclas := Trim(EstadoTeclas);
  if jvStatusBar1.Panels[0].Text <> EstadoTeclas then
    jvStatusBar1.Panels[0].Text := EstadoTeclas;
  ActualizarFondoLogo;
end;


procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
var
  sDis: string;

  procedure AplicarTema;
  var
    sTema, sPaleta: string;
  begin
    if not (Assigned(LookAndFeelController1) and
            Assigned(dxSkinController1)) then
      Exit;
    try
      sTema := oAppParams.GetString('appTema');
      if sTema = '' then
      begin
        if DarkModeIsEnabled then
          sTema := 'MetropolisDark'
        else
          sTema := 'Office2007Pink';
      end;
      LookAndFeelController1.SkinName := sTema;
      dxSkinController1.SkinName      := sTema;
      // Paleta de color (solo skins modernos la soportan)
      sPaleta := oAppParams.GetString('appPaleta');
      if sPaleta <> '' then
        TcxRootLookAndFeel.Instance.SkinPaletteName := sPaleta;
    except
      on E: Exception do
        inLibLog.Log.LogWarning('Error al establecer skin: ' + E.Message);
    end;
  end;

begin
  Application.OnException := AppException;
  FSavedNCMValid := False;
  Application.OnIdle := ApplicationEvents1Idle;
  Application.OnMessage := AppMessage;
  sDis := '';
  oMemoSQL := cxMemo1;
  // Splash no-modal al arrancar. Lo mantenemos visible mientras corre el
  // resto de la inicializacion y garantizamos un suelo de 1000 ms para
  // que la marca se lea aunque todo termine en 250 ms.
  FSplashInicio := nil;
  FSplashTimestamp := Now;
  try
    FSplashInicio := TfrmSplash.Create(nil);
    TfrmSplash(FSplashInicio).FormStyle := fsStayOnTop;
    TfrmSplash(FSplashInicio).btnAceptar.Visible := False;
    TfrmSplash(FSplashInicio).Show;
    Application.ProcessMessages;
  except
    // Si el splash falla por lo que sea, no rompemos el arranque.
    FreeAndNil(FSplashInicio);
  end;
  FormManager := TEmbeddedFormManager.Create(Self.pcPrincipal);
  FDmConn     := TdmConn.Create(Self);
  FDmConn.conUni.Connect;
  tmr1Timer(Sender);
  FdmDataPerfiles := TdmPerfiles.Create(Self);
  odmPerfiles     := FdmDataPerfiles;
  oConn           := FDmConn.conUni;
  odmConn         := FDmConn;
  ofrmMto2        := Self;
  oFzaWinf := TfzaWinF.Create(Self);
  oFzaWinf.Charge(oConn);
  // AppParams primero: define y lee appArranqueEnParalelo, que decide como
  // se precargan las caches pesadas (perfiles, informes-guias, config-campos
  // y permisos). Charge se queda siempre en el hilo principal (toca VCL).
  inLibLog.Log.LogInfo('Arranque: pre-InicializarParametrosApp');
  oAppParams.InicializarParametrosApp(oUser, oGroup);
  if oAppParams.GetBool('appArranqueEnParalelo', False) then
    PrecargarCachesParalelo
  else
    PrecargarCachesSerie;
  inLibLog.Log.LogInfo('Arranque: pre-InicializarParametrosCaja');
  oCajaParams.InicializarParametrosCaja(oUser, oGroup);
  // Cache de unidades de medida: decimales por unidad y factores de
  // conversion. La usan ficha de articulo, lineas de documento e informes.
  oUnidades.Cargar;
  oNomImpresoraCaja := GetImpresoraCaja;
  jvStatusBar1.Panels[1].Text := FDmConn.conUni.Server + ':' +
    IntToStr(FDmConn.conUni.Port) + ' (' + FDmConn.conUni.Database + ')';
  if oRootGroup = 'S' then
    sDis := ' ✪';
  jvStatusBar1.Panels[2].Text := oUser + ' (' + oGroup + ') ' + sDis;
  jvStatusBar1.Panels[3].Text := oEmpresa + '\' + oAlmacen + '\' + oCaja;
  Self.Caption := oAppName + ' ' + oVersion;
  // Aplicar permisos de menú: ocultar items sin acceso
  AplicarPermisosMenu;
  // Visibilidad inicial del panel de monitor SQL: ya no la decide solo el
  // {$IFDEF DEBUG}. AplicarModosDepuracion la sincronizará con los flags
  // appModoDebug / appModoDebugSQL que acaba de cargar InicializarParametrosApp.
  pnlPPBottom.Visible := False;
  cxMemo1.Visible     := False;
  inLibLog.AplicarModosDepuracion;
  AplicarTema;
  CargarFondoLogo;
  imgFondoLogo.BringToFront;
  // Logo de fondo via TImage + labels dinamicos (replica del splash).
  // El imgFondoLogo del .dfm no termina de pintar por culpa del wrapper
  // TdxSmartImage que VCL no deserializa, asi que servimos la imagen
  // desde controles creados aqui.
  CrearLogoFondoBg;
  // OnResize lo bindeamos en codigo porque FormResize esta en public y
  // .dfm streaming solo encuentra event handlers en published; asi
  // evitamos un EReadError 'Invalid property value' al cargar el form.
  Self.OnResize := FormResize;
  ActualizarFondoLogo;
  inLibLog.Log.LogInfo('Arranque del sistema');
  // Suelo de visibilidad del splash: si la inicializacion fue mas rapida
  // de 1000 ms, esperamos a llegar a ese minimo para que el usuario
  // pueda leer la marca; si tardo mas, lo cerramos sin demora.
  CerrarSplashInicio(1000);
end;

procedure TfrmMtoPrincipal.CrearLogoFondoBg;
var
  oNombre:  TcxLabel;
  oVer:     TcxLabel;
begin
  FLogoBgPanel   := nil;
  FLogoBgImage   := nil;
  FLogoBgNombre  := nil;
  FLogoBgVersion := nil;
  // Truco del commit 2b39e93: TImage es TGraphicControl y NUNCA puede
  // pintarse encima de un TWinControl hermano (pcPrincipal alClient en
  // Panel1). La solucion es REPARENTAR imgFondoLogo al propio
  // pcPrincipal — queda como hijo directo del PageControl (no en una
  // TabSheet), se pinta sobre su area cliente vacia cuando no hay
  // pestanas, y la TcxTabSheet activa lo tapa automaticamente cuando
  // si las hay (z-order natural, sin tener que togglear Visible).
  imgFondoLogo.Parent  := pcPrincipal;
  imgFondoLogo.Anchors := [akTop, akRight];
  imgFondoLogo.Proportional := True;
  imgFondoLogo.Stretch      := True;
  imgFondoLogo.Center       := True;
  FLogoBgImage := imgFondoLogo;
  // Labels nombre+version tambien dentro de pcPrincipal para que
  // sigan el mismo destino: visibles sin pestanas, tapados por la
  // TabSheet activa cuando hay alguna abierta.
  oNombre := TcxLabel.Create(Self);
  oNombre.Parent  := pcPrincipal;
  oNombre.Caption := 'Alejandro Laorden Hidalgo';
  oNombre.AutoSize := False;
  oNombre.Style.Font.Name   := 'Lucida Sans';
  oNombre.Style.Font.Height := -17;
  oNombre.Style.Font.Style  := [fsBold];
  oNombre.Properties.Alignment.Horz := taCenter;
  oNombre.Transparent := True;
  FLogoBgNombre := oNombre;
  oVer := TcxLabel.Create(Self);
  oVer.Parent  := pcPrincipal;
  oVer.Caption := 'Versión ' + oVersion;
  oVer.AutoSize := False;
  oVer.Style.Font.Name   := 'Lucida Sans';
  oVer.Style.Font.Height := -14;
  oVer.Properties.Alignment.Horz := taCenter;
  oVer.Transparent := True;
  FLogoBgVersion := oVer;
  CentrarLogoFondoBg;
end;

procedure TfrmMtoPrincipal.CentrarLogoFondoBg;
var
  cw, ch, w, h, cx, cy: Integer;
begin
  if imgFondoLogo = nil then
    Exit;
  // Trabajamos sobre el cliente de pcPrincipal (donde reparentamos los
  // controles), no sobre Panel1. Asi al cambiar el tamano de la ventana
  // FormResize recoloca todo respecto al area cliente real.
  cw := pcPrincipal.ClientWidth;
  ch := pcPrincipal.ClientHeight;
  // Logo: 50% del ancho, max 600, min 240, manteniendo aspect 520x130.
  w := cw div 2;
  if w > 600 then w := 600;
  if w < 240 then w := 240;
  h := Round(w * 130 / 520);
  cx := (cw - w) div 2;
  cy := (ch - h - 80) div 2;
  if cy < 20 then cy := 20;
  imgFondoLogo.Anchors := [];
  imgFondoLogo.SetBounds(cx, cy, w, h);
  if FLogoBgNombre <> nil then
    TcxLabel(FLogoBgNombre).SetBounds(0, cy + h + 8, cw, 26);
  if FLogoBgVersion <> nil then
    TcxLabel(FLogoBgVersion).SetBounds(0, cy + h + 38, cw, 20);
end;

procedure TfrmMtoPrincipal.FormResize(Sender: TObject);
begin
  CentrarLogoFondoBg;
end;

procedure TfrmMtoPrincipal.CerrarSplashInicio(aMinimoMs: Integer);
var
  iElapsedMs, iEsperaMs: Integer;
begin
  if FSplashInicio = nil then
    Exit;
  // Si ya ha pasado el suelo minimo, cierre inmediato. Si no, dormimos
  // lo que falte. Sleep simple: el splash no se anima durante la espera
  // pero la VCL no se cuelga porque estamos en el ultimo paso de
  // FormCreate; Application.Run procesara mensajes despues.
  iElapsedMs := Round((Now - FSplashTimestamp) * 86400000);
  if iElapsedMs < aMinimoMs then
  begin
    iEsperaMs := aMinimoMs - iElapsedMs;
    Application.ProcessMessages;
    Sleep(iEsperaMs);
  end;
  try
    TfrmSplash(FSplashInicio).Close;
  except
    // Si el form ya estaba liberado por algun motivo, lo ignoramos.
  end;
  FreeAndNil(FSplashInicio);
end;

// El Picture.Data del .dfm trae un envoltorio TdxSmartImage que el TImage
// de VCL no sabe deserializar (queda vacio al cargar el form). Cargamos
// 'fondo.png' desde disco en runtime probando rutas candidatas relativas
// al .exe (Debug queda en Win32\Debug, Release al lado de los assets).
procedure TfrmMtoPrincipal.CargarFondoLogo;
const
  CRutas: array[0..3] of string = (
    'fondo.png',
    '..\..\fondo.png',
    'logo_art\icon-256.png',
    '..\..\logo_art\icon-256.png'
  );
var
  sBase, sRuta: string;
  i: Integer;
  oRes: TResourceStream;
  oPng: TPngImage;
begin
  // 1) Recurso RCDATA 'FONDO' embebido en el .exe via {$R fondo.res} en
  //    fzam.dpr. Es el camino preferente porque no depende de tener el
  //    fichero al lado del .exe. Si el recurso no esta presente (porque
  //    se compilo sin fondo.res) caemos a las rutas relativas de disco.
  try
    oRes := TResourceStream.Create(HInstance, 'FONDO', RT_RCDATA);
    try
      oPng := TPngImage.Create;
      try
        oPng.LoadFromStream(oRes);
        imgFondoLogo.Picture.Assign(oPng);
        inLibLog.Log.LogInfo('CargarFondoLogo: OK desde recurso FONDO ' +
                             '(' + IntToStr(oRes.Size) + ' bytes)');
        Exit;
      finally
        oPng.Free;
      end;
    finally
      oRes.Free;
    end;
  except
    on E: Exception do
      inLibLog.Log.LogInfo('CargarFondoLogo: recurso FONDO no disponible ' +
                           '(' + E.Message + '); pruebo disco');
  end;
  // 2) Fallback a fichero suelto: para builds Debug donde fondo.png
  //    vive en la raiz del repo (..\..\fondo.png desde Win32/Debug).
  sBase := inLibDir.DirApp;
  inLibLog.Log.LogInfo('CargarFondoLogo: base="' + sBase + '"');
  for i := 0 to High(CRutas) do
  begin
    sRuta := sBase + CRutas[i];
    if FileExists(sRuta) then
    begin
      try
        imgFondoLogo.Picture.LoadFromFile(sRuta);
        inLibLog.Log.LogInfo('CargarFondoLogo: OK desde "' + sRuta + '"');
        Exit;
      except
        on E: Exception do
          inLibLog.Log.LogWarning('No se pudo cargar fondo ' + sRuta +
                                  ': ' + E.Message);
      end;
    end
    else
      inLibLog.Log.LogInfo('CargarFondoLogo: no existe "' + sRuta + '"');
  end;
  inLibLog.Log.LogWarning('No se encontro imagen de fondo (fondo.png).');
end;

procedure TfrmMtoPrincipal.ActualizarFondoLogo;
var
  bDebeVerse, bTieneImg: Boolean;
begin
  // Con imgFondoLogo y labels reparentados a pcPrincipal, la TcxTabSheet
  // activa los tapa por z-order automaticamente cuando hay pestanas
  // abiertas — pero togglear Visible es mas barato que dejarlos pintando
  // detras, asi que mantenemos la condicion PageCount=0 explicita.
  bTieneImg  := imgFondoLogo.Picture.Graphic <> nil;
  bDebeVerse := (pcPrincipal.PageCount = 0) and bTieneImg;
  if imgFondoLogo.Visible <> bDebeVerse then
    imgFondoLogo.Visible := bDebeVerse;
  if FLogoBgNombre <> nil then
    if TcxLabel(FLogoBgNombre).Visible <> bDebeVerse then
      TcxLabel(FLogoBgNombre).Visible := bDebeVerse;
  if FLogoBgVersion <> nil then
    if TcxLabel(FLogoBgVersion).Visible <> bDebeVerse then
      TcxLabel(FLogoBgVersion).Visible := bDebeVerse;
end;

procedure TfrmMtoPrincipal.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self, 'Tarifas');
end;

procedure TfrmMtoPrincipal.CopiasdeSeguridad1Click(Sender: TObject);
var
  Worker: TBackupWorker;
begin
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultExtension := 'sql';
  saveDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  saveDialog.FileTypes.Clear;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  saveDialog.FileName := 'copiaseguridad' +
    FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) + '.sql';
  if saveDialog.Execute then
  begin
    MostrarBarraProgreso;
    Worker := TBackupWorker.Create(
      FDmConn.conUni.Server,
      FDmConn.conUni.Port,
      FDmConn.conUni.Database,
      FDmConn.conUni.Username,
      FDmConn.conUni.Password,
      saveDialog.FileName,
      False, '');
    Worker.OnProgreso := WorkerProgreso;
    Worker.OnFinalizar := BackupFinalizar;
    Worker.Start;
  end;
end;

// validar iban online https://www.iban.com
// validar nif europeo https://ec.europa.eu/taxation_customs/tin/#/check-tin

procedure TfrmMtoPrincipal.PrecargarCachesSerie;
var
  swTotal: TStopwatch;
begin
  swTotal := TStopwatch.StartNew;
  Log.LogInfo('Arranque: PrecargarCachesSerie INICIO');
  odmPerfiles.PrecargarPerfilesUsuario;
  oInfGuiasCache := TInformesGuiasCache.Create;
  oInfGuiasCache.Precargar;
  oConfigCampos := TConfigCamposCache.Create;
  oConfigCampos.Precargar;
  oPermisos := TPermisosCache.Create;
  oPermisos.Precargar(oConn, oUser, oGroup, oRootGroup = 'S');
  Log.LogInfo(Format('PrecargaSerie: total=%d ms', [swTotal.ElapsedMilliseconds]));
end;

function TfrmMtoPrincipal.CrearConexionPrecarga: TUniConnection;
begin
  // Conexion efimera para una tarea de precarga, creada y usada en SU hilo.
  // Mismos parametros que oConn (salen del mismo pool) pero SIN cablear
  // OnError/AfterConnect: el AfterConnect global ejecuta SQL sobre el conUni
  // global por nombre, y llamarlo desde un worker seria una carrera; el SET
  // wait_timeout no aporta a una conexion de un solo uso. Leer aqui las
  // propiedades de oConn es seguro: en la fase paralela el hilo principal
  // esta en WaitForAll y nadie las modifica.
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
    Result.Connect;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TfrmMtoPrincipal.EjecutarCargaWorker(ACarga: TProc<TUniConnection>;
                                              out AError: string): Int64;
var
  sw: TStopwatch;
  c: TUniConnection;
begin
  AError := '';
  sw := TStopwatch.StartNew;
  c := nil;
  try
    try
      c := CrearConexionPrecarga;
      ACarga(c);
    except
      // Capturamos la excepcion en la tarea para que NO aborte el WaitForAll.
      // La cache afectada queda sin cargar y degrada sola (FCargada=False).
      on E: Exception do
        AError := E.ClassName + ': ' + E.Message;
    end;
  finally
    if c <> nil then
      FreeAndNil(c);
  end;
  Result := sw.ElapsedMilliseconds;
end;

procedure TfrmMtoPrincipal.PrecargarCachesParalelo;
var
  swTotal: TStopwatch;
  bEsAdmin: Boolean;
  msPerfiles, msInfGuias, msConfig, msPermisos: Int64;
  errPerfiles, errInfGuias, errConfig, errPermisos: string;
  t1, t2, t3, t4: ITask;
begin
  swTotal := TStopwatch.StartNew;
  Log.LogInfo('Arranque: PrecargarCachesParalelo INICIO');
  bEsAdmin := (oRootGroup = 'S');
  msPerfiles := 0;
  msInfGuias := 0;
  msConfig := 0;
  msPermisos := 0;
  errPerfiles := '';
  errInfGuias := '';
  errConfig := '';
  errPermisos := '';
  oInfGuiasCache := TInformesGuiasCache.Create;
  oConfigCampos  := TConfigCamposCache.Create;
  oPermisos      := TPermisosCache.Create;
  // Cada tarea escribe solo en SUS variables (sin estado compartido) y captura
  // su excepcion (no se propaga al WaitForAll). El log es thread-safe (mutex).
  t1 := TTask.Run(
    procedure
    begin
      msPerfiles := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          odmPerfiles.PrecargarPerfilesUsuario(c);
        end, errPerfiles);
    end);
  t2 := TTask.Run(
    procedure
    begin
      msInfGuias := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          oInfGuiasCache.Precargar(c);
        end, errInfGuias);
    end);
  t3 := TTask.Run(
    procedure
    begin
      msConfig := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          oConfigCampos.Precargar(c);
        end, errConfig);
    end);
  t4 := TTask.Run(
    procedure
    begin
      msPermisos := EjecutarCargaWorker(
        procedure(c: TUniConnection)
        begin
          oPermisos.Precargar(c, oUser, oGroup, bEsAdmin);
        end, errPermisos);
    end);
  TTask.WaitForAll([t1, t2, t3, t4]);
  Log.LogInfo(Format('PrecargaParalela: total=%d ms || ' +
    'perfiles=%d infguias=%d config=%d permisos=%d',
    [swTotal.ElapsedMilliseconds,
     msPerfiles, msInfGuias, msConfig, msPermisos]));
  if (errPerfiles <> '') or (errInfGuias <> '') or
     (errConfig <> '') or (errPermisos <> '') then
    Log.LogError(Format('PrecargaParalela errores -> perfiles=[%s] ' +
      'infguias=[%s] config=[%s] permisos=[%s]',
      [errPerfiles, errInfGuias, errConfig, errPermisos]));
end;

procedure TfrmMtoPrincipal.AplicarPermisosMenu;
var
  i: Integer;
  // Procesa un item y sus hijos. Devuelve True si queda visible. Una hoja
  // se oculta y deshabilita cuando su permiso (oFzaWinf.CodigoMenu, que
  // resuelve 'menu.<CALL>' si esta registrado o 'menu.<Name>' si no) esta
  // denegado. Enabled:=False ademas neutraliza el atajo de teclado del
  // item (un menu solo invisible seguiria disparando su ShortCut). Un
  // contenedor se oculta si ninguno de sus hijos queda visible.
  function ProcesarItem(AItem: TMenuItem): Boolean;
  var
    j: Integer;
    sCodigo: string;
    bHayHijoVisible: Boolean;
  begin
    if AItem.Caption = '-' then
      Result := AItem.Visible
    else if AItem.Count > 0 then
    begin
      bHayHijoVisible := False;
      for j := 0 to AItem.Count - 1 do
        if ProcesarItem(AItem.Items[j]) then
          bHayHijoVisible := True;
      if not bHayHijoVisible then
      begin
        AItem.Visible := False;
        AItem.Enabled := False;
      end;
      Result := AItem.Visible;
    end
    else
    begin
      sCodigo := oFzaWinf.CodigoMenu(AItem);
      if (sCodigo <> '') and (not oPermisos.TienePermiso(sCodigo)) then
      begin
        AItem.Visible := False;
        AItem.Enabled := False;
        Log.LogInfo(Format('Permiso %s denegado: menu oculto', [sCodigo]));
      end;
      Result := AItem.Visible;
    end;
  end;
begin
  if (oPermisos <> nil) and (oPermisos.Cargada) and (Menu <> nil) then
    for i := 0 to Menu.Items.Count - 1 do
      ProcesarItem(Menu.Items[i]);
end;

procedure TfrmMtoPrincipal.WorkerProgreso(const AEtapa: string;
                                          APaso, ATotal: Integer;
                                          AFilaGlobal,
                                          AFilasGlobalTotal: Integer);
begin
  if (FProgressBar = nil) or (not FProgressBar.Visible) then
    Exit;
  if AFilasGlobalTotal > 0 then
  begin
    FProgressBar.Max := AFilasGlobalTotal;
    FProgressBar.Position := AFilaGlobal;
  end;
  if ATotal > 0 then
    FProgressLabel.Caption :=
      Format('%s  %d / %d', [AEtapa, APaso, ATotal])
  else
    FProgressLabel.Caption := AEtapa;
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmMtoPrincipal.BackupFinalizar(AExito: Boolean;
  const AError: string; ALogBuffer: TStringList);
begin
  OcultarBarraProgreso;
  if AExito then
  begin
    inLibLog.Log.LogInfo('Copia de seguridad creada exitosamente');
    ShowMessage('La copia se guardó exitosamente.');
  end
  else
  begin
    inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' + AError);
    ShowMessage('No se pudo crear la copia de seguridad.' +
                sLineBreak + AError);
  end;
end;

procedure TfrmMtoPrincipal.RestoreFinalizar(AExito: Boolean;
  const AError: string; ALogBuffer: TStringList);
var
  LogForm: TfrmMtoModalScriptLog;
begin
  OcultarBarraProgreso;
  // Mostrar log de ejecución
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
  if AExito then
    ShowMessage('El script se ejecutó exitosamente')
  else
  begin
    inLibLog.Log.LogError('Error en restauración: ' + AError);
    ShowMessage('Hubo problemas al ejecutar el script.' +
                sLineBreak + AError);
  end;
end;

procedure TfrmMtoPrincipal.MostrarBarraProgreso;
begin
  FEnOperacionLarga := True;
  if FProgressLabel = nil then
  begin
    FProgressLabel := TcxLabel.Create(Self);
    FProgressLabel.Parent := pnlPPBottom;
    FProgressLabel.Align := alTop;
    FProgressLabel.AutoSize := False;
    FProgressLabel.Height := 26;
    FProgressLabel.Caption := '';
    FProgressLabel.Transparent := True;
  end;
  if FProgressBar = nil then
  begin
    FProgressBar := TProgressBar.Create(Self);
    FProgressBar.Parent := pnlPPBottom;
    FProgressBar.Align := alTop;
    FProgressBar.Height := 18;
    FProgressBar.Min := 0;
    FProgressBar.Max := 100;
    FProgressBar.Position := 0;
    FProgressBar.Smooth := True;
  end;
  FProgressLabel.Visible := True;
  FProgressBar.Visible := True;
  pnlPPBottom.Visible := True;
  FProgressBar.Position := 0;
  FProgressLabel.Caption := 'Preparando...';
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmMtoPrincipal.OcultarBarraProgreso;
begin
  FEnOperacionLarga := False;
  if FProgressBar <> nil then
    FProgressBar.Visible := False;
  if FProgressLabel <> nil then
    FProgressLabel.Visible := False;
  pnlPPBottom.Visible := False;
end;

function TfrmMtoPrincipal.CopiaSeguridad: Boolean;
var
  Options: TBackupOptions;
  Provider: IDBMetadataProvider;
  Helpers: IDBHelpers;
  Writer: IScriptWriter;
  Engine: TDBBackupEngine;
  IncludeTables, ExcludeTables: TStringList;
begin
  Result := False;
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultExtension := 'sql';
  saveDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  saveDialog.FileTypes.Clear;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  saveDialog.FileName := 'copiaseguridad' +
                           FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) + '.sql';
  if saveDialog.Execute then
  begin
    Options.WithData := True;
    Options.WithTriggers := True;
    Options.WithProcedures := True;
    Options.WithFunctions := True;
    Options.WithViews := True;
    Options.DropTablesFirst := True;
    Options.UseTransactions := True;
    Options.ExtendedInsert := True;
    Options.ExtendedInsertRows := 500;
    IncludeTables := TStringList.Create;
    ExcludeTables := TStringList.Create;
    Provider := TMySQLMetadataProvider.Create(FDmConn.conUni,
                                              FDmConn.conUni.Database);
    Helpers := TMySQLHelpers.Create;
    Writer := TScriptWriter.Create(saveDialog.FileName);
    MostrarBarraProgreso;
    try
      try
        Engine := TDBBackupEngine.Create(Provider, Writer, Helpers,
                                         Options,
                                         IncludeTables, ExcludeTables);
        try
          Engine.OnProgress := WorkerProgreso;
          Engine.GenerateBackup;
          inLibLog.Log.LogInfo('Copia de seguridad creada en ' +
                                                           saveDialog.FileName);
          ShowMessage('La copia se guardó exitosamente.');
          Result := True;
        finally
          FreeAndNil(Engine);
        end;
      except
        on E: Exception do
        begin
          inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' +
                                                                     E.Message);
          ShowMessage('No se pudo crear la copia de seguridad.' + sLineBreak +
                                                                     E.Message);
          Result := False;
        end;
      end;
    finally
      OcultarBarraProgreso;
      FreeAndNil(IncludeTables);
      FreeAndNil(ExcludeTables);
    end;
  end;
end;

procedure TfrmMtoPrincipal.FormActivate(Sender: TObject);
begin
  inherited;
  // FormPaint(Sender);
end;

procedure TfrmMtoPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
//var
//  I: Integer;
begin
  Application.OnException := nil;
  Application.OnMessage := nil;
  inherited;
  try
    inLibLog.Log.LogInfo('Cerrando ventana principal');
    tmr1.Enabled := False;
    if Assigned(FormManager) then
    try
      FormManager.CloseAll;
    except
      on E: Exception do inLibLog.Log.LogError('Error en CloseAll: ' +
                                                                     E.Message);
    end;
    FreeAndNil(oFzaWinf);
    if (FdmDataPerfiles <> nil) then
      FreeAndNil(FdmDataPerfiles);
    FreeAndNil(FDmConn);
  finally
    inLibLog.Log.LogInfo('Ventana principal Cerrada');
    Action := caFree;
  end;
end;

procedure TfrmMtoPrincipal.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  inherited;
  // Cierre por reinicio de sesion ('Invocar login'): no preguntar.
  if (FReiniciando) then
    CanClose := True
  else if (pcPrincipal.PageCount = 0) then
  begin
    if MessageDlg('¿Quiere salir de la aplicación Fzam?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      CanClose := False; // Cancela el cierre
    end
    else
    begin
      CanClose := True;  // Permite el cierre
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmMtoPrincipal.FormShow(Sender: TObject);
begin
  if FException then
  begin
    PostMessage(Handle, wm_Close, 0, 0);
    Exit;
  end;
  // Defensivo: tras todo el init de FormCreate, garantizamos que el logo
  // este encima de pcPrincipal (z-order) y que ActualizarFondoLogo haya
  // decidido visibilidad ya con el form fisicamente visible en pantalla.
  // Si CargarFondoLogo no encontro el png, esto es no-op (Picture.Graphic
  // sigue nil y ActualizarFondoLogo deja Visible=False).
  imgFondoLogo.BringToFront;
  ActualizarFondoLogo;
end;

procedure TfrmMtoPrincipal.AppMessage(var Msg: TMsg; var Handled: Boolean);
var
  LForm: TForm;
  ts: TcxTabSheet;
  sArt, sSku: string;
begin
  // Solo pulsaciones de tecla y descartando la autorrepeticion (bit 30).
  if (Msg.message = WM_KEYDOWN) and ((Msg.lParam and $40000000) = 0) then
  begin
    // F9: abrir el cajon en caja. Solo con sesion de caja abierta
    // (frmMtoMenuCaja vivo) y F9 sola, sin Ctrl/Alt/Mayus.
    if (Msg.wParam = WPARAM(VK_F9)) and Assigned(frmMtoMenuCaja) and
       (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
       (GetKeyState(VK_SHIFT) >= 0) then
    begin
      AbrirCajonSinVenta;
      Handled := True;
    end
    // Ctrl+U: consulta de stock global, precargando el articulo en foco.
    else if (Msg.wParam = WPARAM(Ord('U'))) and (GetKeyState(VK_CONTROL) < 0) and
            (GetKeyState(VK_MENU) >= 0) and (GetKeyState(VK_SHIFT) >= 0) then
    begin
      // Si el principal esta activo, el form logico es el de la pestaña activa.
      LForm := Screen.ActiveForm;
      if (LForm = Self) and (pcPrincipal.PageCount > 0) and
         (pcPrincipal.ActivePageIndex >= 0) then
      begin
        ts := pcPrincipal.Pages[pcPrincipal.ActivePageIndex] as TcxTabSheet;
        if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
          LForm := TForm(ts.Controls[0]);
      end;
      sArt := '';
      sSku := '';
      if LForm is TfrmBase then
        TfrmBase(LForm).ResolverArtSkuStock(sArt, sSku);
      MostrarStockConsulta(LForm, sArt, sSku);
      Handled := True;
    end;
  end;
end;

function TfrmMtoPrincipal.IsShortCut(var Message: TWMKey): Boolean;
var
  Component: TComponent;
  ActiveForm: TCustomForm;
  ts: TcxTabSheet;
  I: Integer;
  iPageActive: Integer;
  bFound: Boolean;
begin
  // Alt+F4 -> cerrar aplicacion
  if (Message.CharCode = VK_F4)
     and (HiWord(Message.KeyData) and KF_ALTDOWN <> 0) then
  begin
    Self.Close;
    Result := True;
    Exit;
  end;
  // Ctrl+F4 -> cerrar pestaña activa o ventana flotante
  if (Message.CharCode = VK_F4)
     and (GetKeyState(VK_CONTROL) < 0)
     and (HiWord(Message.KeyData) and KF_ALTDOWN = 0) then
  begin
    // Ventana flotante (no modal): cerrarla
    if Assigned(Screen.ActiveForm) and
       (Screen.ActiveForm <> Self) and
       (Screen.ActiveForm.Parent = nil) then
    begin
      Screen.ActiveForm.Close;
      Result := True;
      Exit;
    end;
    // Pestaña embebida
    if (pcPrincipal.PageCount > 0) then
      FormManager.CloseActiveForm;
    Result := True;
    Exit;
  end;
  // ESC -> cerrar pestaña activa o salir
  if (Message.CharCode = VK_ESCAPE) then
  begin
    if Application.ModalLevel > 0 then
    begin
      Result := inherited IsShortCut(Message);
      Exit;
    end;
    if Assigned(Screen.ActiveForm) and
       (Screen.ActiveForm <> Self) and
       (Screen.ActiveForm.Parent = nil) then
    begin
      Result := inherited IsShortCut(Message);
      Exit;
    end;
    if (pcPrincipal.PageCount = 0) then
    begin
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
      Result := True;
      Exit;
    end
    else
    begin
      FormManager.CloseActiveForm;
      Result := True;
      Exit;
    end;
  end;
  // Ventana no embebida (modal top-level) -> delegar a sus ActionLists
  ActiveForm := Screen.ActiveForm;
  if Assigned(ActiveForm) and
     (ActiveForm <> Self) and
     (ActiveForm.Parent = nil) then
  begin
    Result := False;
    for I := 0 to ActiveForm.ComponentCount - 1 do
    begin
      Component := ActiveForm.Components[I];
      if Component is TActionList then
      begin
        if TActionList(Component).IsShortCut(Message) then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
    Exit;
  end;
  // Enrutar a los TActionList del formulario hijo en la pestaña activa.
  // Recorre TODOS los ActionList del hijo (base + propios del Mto).
  bFound := False;
  if (Self.pcPrincipal.PageCount > 0) then
  begin
    iPageActive := pcPrincipal.ActivePageIndex;
    if (iPageActive >= 0) then
    begin
      ts := (Self.pcPrincipal.Pages[iPageActive] as TcxTabSheet);
      if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
      begin
        for I := 0 to (ts.Controls[0] as TForm).ComponentCount - 1 do
        begin
          Component := (ts.Controls[0] as TForm).Components[I];
          if (Component is TActionList) then
          begin
            if TActionList(Component).IsShortCut(Message) then
            begin
              bFound := True;
              Break;
            end;
          end;
        end;
      end;
    end;
  end;
  if bFound then
    Result := True
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
var
  SqlTexto: string;
  FS: TFileStream;
  Bytes: TBytes;
  BytesToRead: Int64;
  Worker: TRestoreWorker;
begin
  if not mnuEjecutarScript.Visible then
    Exit;
  openDialog.Title := 'Cargar script';
  openDialog.FileTypes.Clear;
  with openDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with openDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  openDialog.DefaultExtension := 'sql';
  openDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  if openDialog.Execute then
  begin
    // Leer solo los primeros 64 KB para comprobar DDL sin cargar
    // todo el fichero en memoria (los backups pueden ser muy grandes).
    FS := TFileStream.Create(openDialog.FileName,
                             fmOpenRead or fmShareDenyNone);
    try
      BytesToRead := FS.Size;
      if BytesToRead > 65536 then
        BytesToRead := 65536;
      SetLength(Bytes, BytesToRead);
      FS.ReadBuffer(Bytes, BytesToRead);
      SqlTexto := TEncoding.UTF8.GetString(Bytes);
    finally
      FreeAndNil(FS);
    end;
    if ContieneDDL(SqlTexto) then
    begin
      var Respuesta := MessageDlg(
        'ATENCIÓN: El script contiene sentencias DDL (modifican la ' +
        'estructura de la base de datos).' + sLineBreak +
        'En MySQL/MariaDB, estos cambios provocan un guardado automático y ' +
        'NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
        '¿Deseas realizar una copia de seguridad antes de continuar?',
          mtWarning, [mbYes, mbNo, mbCancel], 0);
      case Respuesta of
        mrYes:
          begin
            if not CopiaSeguridad then
            begin
              ShowMessage('Operación cancelada. El script no se ejecutará.');
              Exit;
            end;
          end;
        mrCancel:
          Exit;
      end;
    end;
    // Lanzar ejecución en segundo plano
    MostrarBarraProgreso;
    Worker := TRestoreWorker.Create(
      FDmConn.conUni.Server,
      FDmConn.conUni.Port,
      FDmConn.conUni.Database,
      FDmConn.conUni.Username,
      FDmConn.conUni.Password,
      openDialog.FileName,
      '');
    Worker.OnProgreso := WorkerProgreso;
    Worker.OnFinalizar := RestoreFinalizar;
    Worker.Start;
  end;
end;

procedure TfrmMtoPrincipal.tmr1Timer(Sender: TObject);
var
  ADateStr          : string;
  ATimeStr          : string;
begin
  bIsConnected := False;
  ADateStr := DateToStr(Now);
  ATimeStr := FormatDateTime('hh:mm', Now);
  if FDmConn <> nil then
    if FDmConn.conUni.Connected then
    begin
      bIsConnected := True;
      jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + ' Conn';
    end
    else
      bIsConnected := False;
  if (FDmConn = nil) or (not bIsConnected) then
  begin
    jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + 'NO Conn';
    inLibLog.Log.LogError('Se ha perdido la conexión con la BBDD');
  end;

end;


procedure TfrmMtoPrincipal.WMFreeControl(var Msg: TMessage);
var
  TabACerrar: TcxTabSheet;
begin
  TabACerrar := TcxTabSheet(Msg.LParam);
  if FormManager <> nil then
  begin
    FormManager.CloseFormByCaption(TabACerrar.Caption);
  end
  else
  begin
    FreeAndNil(TabACerrar);
  end;
end;

procedure TfrmMtoPrincipal.mnuLisVentasClick(Sender: TObject);
var
  frmModalGenFilter: TfrmModalGenFilter;
begin
  inherited;
  try
    frmModalGenFilter := TfrmModalGenFilter.Create(Self);
    frmModalGenFilter.ShowModal;
  finally
    FreeAndNil(frmModalGenFilter);
  end;
end;

procedure TfrmMtoPrincipal.mnuMenuCajaClick(Sender: TObject);
begin
  inherited;
  if not mnuMenuCaja.Visible then Exit;
  if Assigned(frmMtoMenuCaja) then
  begin
    if frmMtoMenuCaja.WindowState = wsMinimized then
      frmMtoMenuCaja.WindowState := wsNormal;
    frmMtoMenuCaja.BringToFront;
  end
  else
  begin
    frmMtoMenuCaja := TfrmMtoMenuCaja.Create(Application);
    frmMtoMenuCaja.Show;
  end;
  Self.WindowState := wsMinimized;
end;

procedure TfrmMtoPrincipal.mnuAcercadeClick(Sender: TObject);
var
  frmSplash: TfrmSplash;
begin
  inherited;
  try
    frmSplash := TfrmSplash.Create(Self);
    frmSplash.ShowModal;
  finally
    FreeAndNil(frmSplash);
  end;
end;

procedure TfrmMtoPrincipal.mnuAlmacenesClick(Sender: TObject);
begin
  inherited;
  if mnuAlmacenes.Visible then
    ShowMto(Self, 'Almacenes');
end;

procedure TfrmMtoPrincipal.mnuArticulosClick(Sender: TObject);
begin
  if (mnuArticulos.Visible) then
    ShowMto(Self, 'Articulos');
end;

procedure TfrmMtoPrincipal.mnuCajaParamClick(Sender: TObject);
var
  frmMtoCajaParam: TfrmMtoCajaParam;
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    try
      frmMtoCajaParam := TfrmMtoCajaParam.Create(Self);
      frmMtoCajaParam.ShowModal;
    finally
      FreeAndNil(frmMtoCajaParam);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuClientesClick(Sender: TObject);
begin
  if (mnuClientes.Visible) then
    ShowMto(Self, 'Clientes');
end;

procedure TfrmMtoPrincipal.mnuContadoresClick(Sender: TObject);
begin
  if (mnuContadores.Visible) then
    ShowMto(Self, 'Contadores');
end;

procedure TfrmMtoPrincipal.mnuFacturasClick(Sender: TObject);
begin
  if (mnuFacturas.Visible) then
    ShowMto(Self, 'Facturas');
end;

procedure TfrmMtoPrincipal.mnuFacturasSimplifClick(Sender: TObject);
begin
  if (mnuFacturasSimplif.Visible) then
    ShowMto(Self, 'FacturasSimplif');
end;

procedure TfrmMtoPrincipal.mnuFamiliasClick(Sender: TObject);
begin
  if (mnuFamilias.Visible) then
    ShowMto(Self, 'Familias');
end;

procedure TfrmMtoPrincipal.mnuFormaPagoVentaClick(Sender: TObject);
begin
  inherited;
  if mnuFormaPagoVenta.Visible then
    ShowMto(Self, 'FormasdePago');
end;

procedure TfrmMtoPrincipal.mnuPedidosVentaClick(Sender: TObject);
begin
  inherited;
  if mnuPedidosVenta.Visible then
    ShowMto(Self, 'Pedidos');
end;

procedure TfrmMtoPrincipal.mnuAlbaranesVentaClick(Sender: TObject);
begin
  inherited;
  if mnuAlbaranesVenta.Visible then
    ShowMto(Self, 'Albaranes');
end;

procedure TfrmMtoPrincipal.Sesiones1Click(Sender: TObject);
begin
  inherited;
  if mnuCrearArtculosyunpedidoounalbarn.Visible then
    ShowMto(Self, 'ComprasSesiones');
end;

procedure TfrmMtoPrincipal.Albaranes1Click(Sender: TObject);
begin
  inherited;
  if Albaranes1.Visible then
    ShowMto(Self, 'AlbaranesCompra');
end;

procedure TfrmMtoPrincipal.Pedidos1Click(Sender: TObject);
begin
  inherited;
  if Pedidos1.Visible then
    ShowMto(Self, 'PedidosCompra');
end;

procedure TfrmMtoPrincipal.mnuGeneradorProcesosClick(Sender: TObject);
begin
  if (mnuGeneradorProcesos.Visible) then
    ShowMto(Self, 'GeneradorProcesos');
end;

procedure TfrmMtoPrincipal.mnuGruposClick(Sender: TObject);
begin
  if (mnuGrupos.Visible) then
    ShowMto(Self, 'Grupos');
end;

procedure TfrmMtoPrincipal.mnuGruposdeIVAClick(Sender: TObject);
begin
  if (mnuGruposdeIVA.Visible) then
    ShowMto(Self, 'IvasGrupos');
end;

procedure TfrmMtoPrincipal.mnuInventariosClick(Sender: TObject);
begin
  inherited;
  if mnuInventarios.Visible then
    ShowMto(Self, 'Inventarios');
end;

procedure TfrmMtoPrincipal.mnuIvasClick(Sender: TObject);
begin
  if (mnuIvas.Visible) then
    ShowMto(Self, 'Ivas');
end;

procedure TfrmMtoPrincipal.mnuEmpresasClick(Sender: TObject);
begin
  if (mnuEmpresas.Visible) then
    ShowMto(Self,
            'Empresas');
end;

procedure TfrmMtoPrincipal.mnuInvocarLoginClick(Sender: TObject);
begin
  // Cerrar sesion: relanza Fzam con el conmutador /relogin (que ignora el
  // auto-login y la contrasena recordada para forzar la reidentificacion)
  // y cierra esta instancia.
  FReiniciando := True;
  ShellExecute(0,
               'open',
               PChar(Application.ExeName),
               PChar('/relogin'),
               nil,
               SW_SHOWNORMAL);
  Close;
end;

procedure TfrmMtoPrincipal.mnuPaisesClick(Sender: TObject);
begin
  inherited;
  if (mnuPaises.Visible) then
    ShowMto(Self, 'Paises');
end;

procedure TfrmMtoPrincipal.mnuUnidadesMedidaClick(Sender: TObject);
begin
  inherited;
  if (mnuUnidadesMedida.Visible) then
    ShowMto(Self, 'UnidadesMedida');
end;

procedure TfrmMtoPrincipal.mnuPerfilesClick(Sender: TObject);
begin
  if (mnuPerfiles.Visible) then
    ShowMto(Self,
            'UsuariosPerfiles');
end;

procedure TfrmMtoPrincipal.mnuPermisosClick(Sender: TObject);
begin
  if (mnuPermisos.Visible) then
    ShowMto(Self, 'Permisos');
end;

procedure TfrmMtoPrincipal.mnuPermisosTablaClick(Sender: TObject);
begin
  if (mnuPermisosTabla.Visible) then
    ShowMto(Self, 'PermisosTabla');
end;

procedure TfrmMtoPrincipal.mnuProveedoresClick(Sender: TObject);
begin
  if (mnuProveedores.Visible) then
    ShowMto(Self, 'Proveedores');
end;

procedure TfrmMtoPrincipal.mnuUsuariosClick(Sender: TObject);
begin
  if (mnuUsuarios.Visible) then
    ShowMto(Self, 'Usuarios');
end;

procedure TfrmMtoPrincipal.mnuEmpleadosClick(Sender: TObject);
begin
  if (mnuEmpleados.Visible) then
    ShowMto(Self, 'Empleados');
end;

procedure TfrmMtoPrincipal.mnuParmetrosdeEntornoClick(Sender: TObject);
var
    frmMtoAppParam: TfrmMtoAppParam;
begin
  inherited;
  try
    frmMtoAppParam := TfrmMtoAppParam.Create(Self);
    frmMtoAppParam.ShowModal;
  finally
    FreeAndNil(frmMtoAppParam);
  end;
end;

procedure TfrmMtoPrincipal.mnuPropiedadesClick(Sender: TObject);
begin
  if (mnuPropiedades.Visible) then
    ShowMto(Self, 'Propiedades');
end;

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVariacionesClick(Sender: TObject);
begin
  if (mnuVariaciones.Visible) then
    ShowMto(Self, 'Variaciones');
end;

procedure TfrmMtoPrincipal.mnuAtributosConjuntosClick(Sender: TObject);
begin
  if (mnuAtributosConjuntos.Visible) then
    ShowMto(Self, 'AtributosConjuntos');
end;

procedure TfrmMtoPrincipal.mnuAtributosBasicosClick(Sender: TObject);
begin
  if (mnuAtributosBasicos.Visible) then
    ShowMto(Self, 'AtributosBasicos');
end;

procedure TfrmMtoPrincipal.mnuCajaPagosHistClick(Sender: TObject);
begin
  if (mnuCajaPagosHist.Visible) then
    ShowMto(Self, 'CajaPagosHist');
end;

procedure TfrmMtoPrincipal.FormasdePagoCaja1Click(Sender: TObject);
begin
  if (FormasdePagoCaja1.Visible) then
    ShowMto(Self, 'CajaFormasPago');
end;

procedure TfrmMtoPrincipal.mnuCajaValesHistClick(Sender: TObject);
begin
  if (mnuCajaValesHist.Visible) then
    ShowMto(Self, 'CajaValesHist');
end;

procedure TfrmMtoPrincipal.mnuCajaOperacionesHistClick(Sender: TObject);
begin
  if (mnuCajaOperacionesHist.Visible) then
    ShowMto(Self, 'CajaOperacionesHist');
end;

procedure TfrmMtoPrincipal.mnuCajaArqueosHistClick(Sender: TObject);
begin
  if (mnuCajaArqueosHist.Visible) then
    ShowMto(Self, 'CajaArqueosHist');
end;

procedure TfrmMtoPrincipal.Movimientosdealmacn1Click(Sender: TObject);
begin
  if (Movimientosdealmacn1.Visible) then
    ShowMto(Self, 'MovimientosAlmacen');
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenHorizontalClick(Sender: TObject);
var
  frm: TfrmPrintBalanceTallas;
begin
  // Informe A4 horizontal (FastReport) del balance de almacén por tallas
  // con foto. El usuario filtra modo (entre fechas / acumulados), nivel de
  // detalle, fechas, almacén y familia en el propio modal.
  if mnuBalanceAlmacenHorizontal.Visible then
  begin
    frm := TfrmPrintBalanceTallas.Create(Application);
    try
      frm.ShowModal;
    finally
      FreeAndNil(frm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenSinTallasClick(Sender: TObject);
var
  frm: TfrmPrintBalanceSinTallas;
begin
  // Informe vertical (FastReport) del balance de almacén SIN tallas: una fila
  // por (artículo, color, banda). Incluye todos los artículos, también los no
  // tallables que el informe horizontal deja fuera. Mismos filtros, modos,
  // bandas y agrupaciones.
  if mnuBalanceAlmacenSinTallas.Visible then
  begin
    frm := TfrmPrintBalanceSinTallas.Create(Application);
    try
      frm.ShowModal;
    finally
      FreeAndNil(frm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuDepositosClienteClick(Sender: TObject);
begin
  if (mnuDepositosCliente.Visible) then
    ShowMto(Self, 'DepositosCliente');
end;

// Foto flotante transversal: cuando el usuario cambia de pestana
// (=Mto activo), si la pantalla flotante ya esta abierta la
// re-vincula al nuevo Mto. Si no esta abierta no hacemos nada: el
// usuario la abre manualmente con Ctrl+F cuando quiera.
procedure TfrmMtoPrincipal.pcPrincipalChange(Sender: TObject);
var
  ts: TcxTabSheet;
begin
  ActualizarFondoLogo;
  if pcPrincipal.ActivePageIndex < 0 then
  begin
    if Assigned(frmFotoArticulo) and frmFotoArticulo.Visible then
    begin
      frmFotoArticulo.VincularDataSources([], nil);
      frmFotoArticulo.SetArticuloSku('', '');
    end;
    Exit;
  end;
  ts := pcPrincipal.Pages[pcPrincipal.ActivePageIndex] as TcxTabSheet;
  if (ts.ControlCount = 0) or not (ts.Controls[0] is TfrmMtoGen) then
  begin
    if Assigned(frmFotoArticulo) and frmFotoArticulo.Visible then
      frmFotoArticulo.VincularDataSources([], nil);
    Exit;
  end;
  EngancharFotoAlMto(ts.Controls[0]);
end;

procedure TfrmMtoPrincipal.EngancharFotoAlMto(AMto: TObject);
var
  frmActivo : TfrmMtoGen;
  sArt, sSku: string;
begin
  // Solo re-vincula si la flotante YA esta abierta (el usuario la
  // abrio con Ctrl+F en algun Mto y al cambiar a otro queremos
  // que siga el contexto). NO la abrimos automaticamente: el usuario
  // decide cuando aparece.
  if not Assigned(frmFotoArticulo) then Exit;
  if not frmFotoArticulo.Visible then Exit;
  if not (AMto is TfrmMtoGen) then Exit;
  frmActivo := TfrmMtoGen(AMto);
  frmActivo.ResolverArtSkuActivo(sArt, sSku);
  frmFotoArticulo.VincularDataSources(frmActivo.DataSourcesParaFoto,
                                      frmActivo.ResolverArtSkuActivo);
  frmFotoArticulo.SetArticuloSku(sArt, sSku);
end;

// Captura cualquier excepción no atrapada por bloques try/except en la
// aplicación. Asignado a Application.OnException desde FormCreate. El
// objetivo es no perder NINGÚN detalle del fallo: registra todo al log
// y muestra al usuario un diálogo con la traza completa y un botón
// para copiarla al portapapeles (para que pueda pegarla en un reporte).
procedure TfrmMtoPrincipal.AppException(Sender: TObject; E: Exception);
var
  sDetalle: string;
  bRuidoEditorInplace: Boolean;
begin
  // Filtro: EInvalidOperation "no tiene ventana principal" disparado por
  // el editor inplace del cxGrid sin Parent durante transiciones de celda.
  // Es ruido benigno: el handle se acaba creando en la siguiente pasada,
  // el usuario no pierde datos. Solo lo registramos como warning, sin
  // diálogo modal. Patron mitigado tambien en inMtoCajaOpe e inLibDevExp.
  bRuidoEditorInplace := (E is EInvalidOperation) and
                         (Pos('no tiene ventana principal',
                              E.Message) > 0);
  if bRuidoEditorInplace then
  begin
    try
      inLibLog.Log.LogWarning('AppException ignorado (editor inplace sin ' +
                              'Parent): ' + E.Message);
    except
    end;
  end
  else
  begin
    try
      sDetalle := ConstruirDetalleException(Sender, E);
      try
        inLibLog.Log.LogError('AppException ' + E.ClassName + ': ' +
                              E.Message);
        inLibLog.Log.LogError('AppException detalle:' + sLineBreak + sDetalle);
      except
        // Si el log falla no podemos hacer mucho; seguimos para mostrarlo.
      end;
      MostrarDetalleExcepcion(sDetalle);
    except
      // Última red de seguridad: si la construcción del detalle o el
      // diálogo fallan, al menos mostramos lo básico para que el usuario
      // sepa que algo ha pasado.
      try
        Application.ShowException(E);
      except
      end;
    end;
  end;
end;

function TfrmMtoPrincipal.ConstruirDetalleException(Sender: TObject;
                                                   E: Exception): string;
var
  sSenderClass, sSenderName: string;
  pAddr: Pointer;
  Inner: Exception;
  iNivel: Integer;
begin
  if Assigned(Sender) then
  begin
    sSenderClass := Sender.ClassName;
    if (Sender is TComponent) and (TComponent(Sender).Name <> '') then
      sSenderName := TComponent(Sender).Name
    else
      sSenderName := '(sin nombre)';
  end
  else
  begin
    sSenderClass := '(nil)';
    sSenderName  := '(nil)';
  end;
  pAddr := ExceptAddr;
  Result :=
    '=== Detalle del error ===' + sLineBreak +
    'Aplicación   : ' + oAppName + ' ' + oVersion + sLineBreak +
    'Fecha / hora : ' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
                                                                  sLineBreak +
    'Usuario      : ' + oUser + ' (' + oGroup + ')' + sLineBreak +
    'Empresa      : ' + oEmpresa + sLineBreak +
    'Almacén/Caja : ' + oAlmacen + ' / ' + oCaja + sLineBreak +
    'Equipo       : ' + GetComputerName + sLineBreak +
    sLineBreak +
    '--- Excepción ---' + sLineBreak +
    'Clase        : ' + E.ClassName + sLineBreak +
    'Mensaje      : ' + E.Message + sLineBreak +
    'Dirección    : $' + IntToHex(NativeUInt(pAddr),
                                  SizeOf(Pointer) * 2) + sLineBreak +
    sLineBreak +
    '--- Sender ---' + sLineBreak +
    'Clase        : ' + sSenderClass + sLineBreak +
    'Nombre       : ' + sSenderName + sLineBreak;
  // Stack trace: solo aparece si hay un proveedor registrado (madExcept,
  // JCL, EurekaLog…). Si no, será cadena vacía: no es un fallo.
  if E.StackTrace <> '' then
    Result := Result + sLineBreak +
      '--- Stack ---' + sLineBreak + E.StackTrace + sLineBreak;
  // Excepciones encadenadas (raise … from). Limitamos profundidad
  // para evitar bucles infinitos por ciclos accidentales.
  Inner := E.InnerException;
  iNivel := 1;
  while Assigned(Inner) and (iNivel <= 5) do
  begin
    Result := Result + sLineBreak +
      Format('--- Inner exception #%d ---', [iNivel]) + sLineBreak +
      'Clase   : ' + Inner.ClassName + sLineBreak +
      'Mensaje : ' + Inner.Message + sLineBreak;
    if Inner.StackTrace <> '' then
      Result := Result + 'Stack   :' + sLineBreak + Inner.StackTrace +
                                                                  sLineBreak;
    Inner := Inner.InnerException;
    Inc(iNivel);
  end;
end;

procedure TfrmMtoPrincipal.MostrarDetalleExcepcion(const ATexto: string);
var
  Dialog    : TForm;
  pnlBotones: TPanel;
  btnCopiar : TButton;
  btnCerrar : TButton;
  lblCabec  : TLabel;
begin
  Dialog := TForm.Create(nil);
  try
    Dialog.Caption     := 'Se ha producido un error';
    Dialog.Position    := poScreenCenter;
    Dialog.Width       := 760;
    Dialog.Height      := 520;
    Dialog.BorderStyle := bsSizeable;
    Dialog.BorderIcons := [biSystemMenu];
    Dialog.KeyPreview  := True;

    lblCabec := TLabel.Create(Dialog);
    lblCabec.Parent    := Dialog;
    lblCabec.Align     := alTop;
    lblCabec.AutoSize  := False;
    lblCabec.Height    := 28;
    lblCabec.Layout    := tlCenter;
    lblCabec.Caption   := '  Detalle completo del error. Usa "Copiar al ' +
                          'portapapeles" para pegarlo en un reporte.';

    pnlBotones := TPanel.Create(Dialog);
    pnlBotones.Parent      := Dialog;
    pnlBotones.Align       := alBottom;
    pnlBotones.Height      := 48;
    pnlBotones.BevelOuter  := bvNone;

    btnCerrar := TButton.Create(Dialog);
    btnCerrar.Parent       := pnlBotones;
    btnCerrar.Caption      := 'Cerrar';
    btnCerrar.Width        := 100;
    btnCerrar.Height       := 32;
    btnCerrar.Top          := 8;
    btnCerrar.Anchors      := [akRight, akTop];
    btnCerrar.Left         := pnlBotones.ClientWidth - btnCerrar.Width - 12;
    btnCerrar.ModalResult  := mrOk;
    btnCerrar.Default      := True;
    btnCerrar.Cancel       := True;

    btnCopiar := TButton.Create(Dialog);
    btnCopiar.Parent       := pnlBotones;
    btnCopiar.Caption      := 'Copiar al portapapeles';
    btnCopiar.Width        := 190;
    btnCopiar.Height       := 32;
    btnCopiar.Top          := 8;
    btnCopiar.Anchors      := [akRight, akTop];
    btnCopiar.Left         := btnCerrar.Left - btnCopiar.Width - 8;
    btnCopiar.OnClick      := CopiarExceptionDialogClick;

    FExceptionDialogMemo := TcxMemo.Create(Dialog);
    FExceptionDialogMemo.Parent     := Dialog;
    FExceptionDialogMemo.Align      := alClient;
    FExceptionDialogMemo.Properties.ReadOnly   := True;
    FExceptionDialogMemo.Properties.ScrollBars := ssBoth;
    FExceptionDialogMemo.Properties.WordWrap   := False;
    FExceptionDialogMemo.Style.Font.Name  := 'Consolas';
    FExceptionDialogMemo.Style.Font.Size  := 9;
    FExceptionDialogMemo.Text       := ATexto;

    Dialog.ActiveControl := btnCerrar;
    Dialog.ShowModal;
  finally
    FExceptionDialogMemo := nil;
    FreeAndNil(Dialog);
  end;
end;

procedure TfrmMtoPrincipal.CopiarExceptionDialogClick(Sender: TObject);
begin
  if Assigned(FExceptionDialogMemo) then
  try
    Clipboard.AsText := FExceptionDialogMemo.Text;
  except
    on E: Exception do
      inLibLog.Log.LogWarning('No se pudo copiar al portapapeles: ' +
                                                                   E.Message);
  end;
end;

end.
