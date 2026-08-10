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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxCore, cxContainer,
  cxEdit, dxSkinsForm, cxStyles, cxClasses, Vcl.ExtCtrls, cxLabel,
  Vcl.Menus, cxPC, cxTextEdit, cxMemo, inMtoFrmBase,
  cxLocalization, Vcl.Buttons,
  inLibUnitForm, JvMenus,
  System.UITypes, Uni, dxShellDialogs, dxSkinsCore, dxSkinBlue,
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
  Vcl.ComCtrls, JvExComCtrls, JvStatusBar, Vcl.AppEvnts,
  dxGDIPlusClasses, cxImage, Vcl.Imaging.pngimage,
  inLibContextoSesionIntf, inLibParametrosIntf, inLibShowMto,
  inLibLicenciaAplicacion, inLibAnfitrionMtoIntf,
  inLibCajaVentanasIntf, inLibPermisosIntf,
  inLibCopiasSeguridadIntf,
  inLibArranqueAplicacion,
  inLibExcepcionesAplicacionIntf,
  inLibOperacionesAplicacionIntf,
  inLibDistribuidorPersistenciaIntf,
  UniDataComposicionAplicacion,
  inMtoMantenimientosInyeccionRaiz,
  inMtoCajaInyeccionRaiz,
  inMtoConfiguracionInyeccionRaiz,
  inMtoPrincipalPresentacionInicio;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(
    TfrmBase,
    IProveedorParametrosEdicion,
    IAnfitrionPantallas,
    IAnfitrionMantenimiento,
    IProveedorMenuPantallas,
    IAnfitrionCajaVentanas,
    IPresentacionOperacionesAplicacion,
    IPasosArranqueAplicacion
  )
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
    Pedidos1: TMenuItem;
    Albaranes1: TMenuItem;
    Devoluciones1: TMenuItem;
    FacturarAlbaranes1: TMenuItem;
    Facturas1: TMenuItem;
    EfectosCompra1: TMenuItem;
    RemesasCompra1: TMenuItem;
    CargarEfectos1: TMenuItem;
    Sesiones1: TMenuItem;
    mnuCrearArtculosyunpedidoounalbarn: TMenuItem;
    Formasdepago2: TMenuItem;
    mnuComprasListados: TMenuItem;
    mnuListadoDocsProveedor: TMenuItem;
    mnuListadoEfectosPago: TMenuItem;
    dxSkinController1: TdxSkinController;
    mnuAlmacen: TMenuItem;
    Movimientosdealmacn1: TMenuItem;
    mnuInventarios: TMenuItem;
    mnuDocumentosTrabajo: TMenuItem;
    mnuPropiedades: TMenuItem;
    mnuVariaciones: TMenuItem;
    mnuAtributosConjuntos: TMenuItem;
    mnuAtributosBasicos: TMenuItem;
    mnuCajaPagosHist: TMenuItem;
    mnuCajaValesHist: TMenuItem;
    mnuVerifactu: TMenuItem;
    mnuVerifactuDeclaracion: TMenuItem;
    mnuVerifactuCola: TMenuItem;
    mnuVerifactuLog: TMenuItem;
    mnuCajaOperacionesHist: TMenuItem;
    mnuDepositosCliente: TMenuItem;
    mnuFacturasSimplif: TMenuItem;
    mnuFacturasProforma: TMenuItem;
    mnuCajaArqueosHist: TMenuItem;
    mnuCajaSolicitudesTraspasoHist: TMenuItem;
    mnuAlmacenInformes: TMenuItem;
    mnuBalanceAlmacenHorizontal: TMenuItem;
    mnuBalanceAlmacenSinTallas: TMenuItem;
    mnuMovVentasArt: TMenuItem;
    EfectosVenta1: TMenuItem;
    RemesasVenta1: TMenuItem;
    CargarEfectosVenta1: TMenuItem;
    mnuTPVListados: TMenuItem;
    mnuListadoOperacionesVenta: TMenuItem;
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuInvocarLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure mnuListadoOperacionesVentaClick(Sender: TObject);
    procedure mnuCajaSolicitudesTraspasoHistClick(Sender: TObject);
    procedure mnuParmetrosdeEntornoClick(Sender: TObject);
//    procedure mnuPropiedadesValoresClick(Sender: TObject);
    procedure mnuVerifactuDeclaracionClick(Sender: TObject);
    procedure mnuBalanceAlmacenHorizontalClick(Sender: TObject);
    procedure mnuBalanceAlmacenSinTallasClick(Sender: TObject);
    procedure mnuMovVentasArtClick(Sender: TObject);
    procedure mnuListadoDocsProveedorClick(Sender: TObject);
    procedure mnuListadoEfectosPagoClick(Sender: TObject);
    procedure pcPrincipalChange(Sender: TObject);
  public
    // Re-vincula la pantalla flotante de fotos (si esta abierta) al
    // Mto recibido y refresca el articulo / SKU activo. NO la abre
    // automaticamente: para abrirla el usuario debe pulsar Ctrl+F
    // en el Mto activo. Llamado desde pcPrincipalChange (cambio de
    // pestana) y desde TfrmMtoGen.FormShow para mantener el contexto.
    procedure EngancharFotoAlMto(AMto: TObject);
    // IAnfitrionPantallas: lo que inLibShowMto necesita del principal
    // (asi la libreria ya no conoce TfrmMtoPrincipal).
    function GestorVentanas: TEmbeddedFormManager;
    function RegistroPantallas: TfzaWinF;
    function CrearPantalla(AClase: TFormClass): TForm;
    procedure PrepararAperturaPantalla;
    function ResolverCallPantalla(const AUnidadClase: string): string;
    function ResolverDataModulePantalla(
      const AUnidadClase: string): string;
    procedure CancelarEdicionesPantallas;
    procedure VincularFotoMantenimiento(AMantenimiento: TObject);
    function CrearCopiaPreviaScriptSoporte: Boolean;
    function MenuAplicacion: TMainMenu;
    function CrearOperacionCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IOperacionCaja;
    function CrearConsultaOperacionesCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
    function CrearTraspasoCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): ITraspasoCaja;
    function CrearRepositorioDistribuidorVisual:
      IRepositorioDistribuidor;
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
    mnuProcesosAuxiliaresBBDD: TMenuItem;
    mnuGeneradorProcesos: TMenuItem;
    mnuUsuarios: TMenuItem;
    mnuEmpleados: TMenuItem;
    mnuGrupos: TMenuItem;
    mnuPerfiles: TMenuItem;
    mnuPermisos: TMenuItem;
    mnuPermisosTabla: TMenuItem;
    Acercade1: TMenuItem;
    mnuManualWeb: TMenuItem;
    mnuForoSoporte: TMenuItem;
    mnuErroresEnvios: TMenuItem;
    mnuConsultaStocks: TMenuItem;
    mnuArticulosSimilares: TMenuItem;
    Listados1: TMenuItem;
    mnuLisVentas: TMenuItem;
    mnuPedidosVenta: TMenuItem;
    mnuAlbaranesVenta: TMenuItem;
    procedure CargarEfectosVenta1Click(Sender: TObject);
    procedure Sesiones1Click(Sender: TObject);
    procedure FacturarAlbaranes1Click(Sender: TObject);
    procedure CargarEfectos1Click(Sender: TObject);
    procedure Formasdepago2Click(Sender: TObject);
    procedure mnuTarifasClick(Sender: TObject);
    procedure mnArchivoSalirClick(Sender: TObject);
    procedure CopiasdeSeguridad1Click(Sender: TObject);
    // Handler unico de los menus de apertura de pantalla: resuelve
    // el CALL del item (fza_winforms) y delega en ShowMto. Sustituye a
    // ~45 OnClick identicos. Pantalla nueva = fila en fza_winforms +
    // OnClick del item = MenuGenericoClick (sin handler nuevo).
    procedure MenuGenericoClick(Sender: TObject);
    procedure mnuEjecutarScriptClick(Sender: TObject);
    procedure mnuProcesosAuxiliaresBBDDClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure mnuAcercadeClick(Sender: TObject);
    procedure mnuManualWebClick(Sender: TObject);
    procedure mnuForoSoporteClick(Sender: TObject);
    procedure mnuConsultaStocksClick(Sender: TObject);
    procedure mnuArticulosSimilaresClick(Sender: TObject);
    function IsShortCut(var Message: TWMKey): Boolean; override;
//    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
//      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure WMFreeControl(var Msg: TMessage); message WM_FREECONTROL;
  private
    FException: Boolean;
    FSavedNCMValid: Boolean;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    FReiniciando: Boolean;
    FFalloCargaPermisosAvisado: Boolean;
    FGestorExcepciones: IGestorExcepcionesAplicacion;
    FComposicion: TComposicionAplicacion;
    FInyeccionMantenimientos: TInyeccionMantenimientosRaiz;
    FInyeccionCaja: TInyeccionCajaRaiz;
    FInyeccionConfiguracion: TInyeccionConfiguracionRaiz;
    FCoordinadorOperaciones: ICasoUsoCopiasSeguridad;
    FPresentacionInicio: TPresentacionInicioPrincipal;
    // Handlers de aplicacion (OnException/OnIdle/OnMessage) registrados via
    // TApplicationEvents: una asignacion directa Application.OnX queda
    // anulada en cuanto cualquier form crea su propio TApplicationEvents
    // (multicaster de la VCL), p.ej. el generador de procesos.
    FAppEvents: TApplicationEvents;
    procedure PrepararContextoAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      out AIdentidad: TIdentidadSesion;
      out AUbicacion: TUbicacionSesion);
    procedure MostrarSplashInicio;
    procedure CrearInfraestructuraAplicacion;
    procedure CrearParametrosSesion(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure CrearServiciosSesion;
    procedure ComprobarConfiguracionFiscal;
    procedure CargarDatosArranque;
    procedure RegistrarFabricasPantallas;
    procedure IniciarProcesosSegundoPlano;
    procedure ActualizarEstadoSesion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure ConfigurarPresentacionPrincipal;
    procedure RegistrarInicioAplicacion;
    procedure CargarServiciosAplicacion(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure ActivarAplicacion;
    procedure PresentarAplicacion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure FinalizarArranqueAplicacion;
    procedure AbrirUrlAyuda(const AUrl: string);
    procedure AppException(Sender: TObject; E: Exception);
    procedure AplicarPermisosMenu;
    procedure AvisarFalloCargaPermisos(const ADetalle: string);
    function SolicitarDestinoCopia(
      out ARutaFichero, AContrasena: string
    ): Boolean;
    function CrearCopiaPreviaScript: Boolean;
    procedure SolicitarCancelarOperacionEnCurso;
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    function GetParametrosAppEdicion: IParametrosEdicion;
    function GetParametrosCajaEdicion: IParametrosEdicion;
    // Atajos globales capturados a nivel de aplicacion (las ventanas de caja
    // son top-level y no pasan por IsShortCut): F9 abre el cajon desde
    // cualquier ventana si hay impresora de tickets asignada y Ctrl+U abre
    // la consulta de stock; Ctrl+E abre la consulta de articulos similares.
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure AbrirCajonDesdePresentacion;
  public
    { Public declarations }
    FormManager : TEmbeddedFormManager;
    destructor Destroy; override;
    procedure InicializarAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure FormResize(Sender: TObject);
    procedure MostrarOperacion;
    procedure ActualizarProgreso(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure MostrarCancelando;
    procedure FinalizarOperacion(
      ATipo: TTipoOperacionAplicacion;
      AResultado: TResultadoCopiaSeguridad;
      const AError: string;
      ALogBuffer: TStringList);
  end;

implementation

uses inLibWin,
  inLibDevExp,
  inLibGlobalVar,
  inLibExcepcionesAplicacion,
  inLibTraduccionesFastReport,
  inLibMonitorSQLIntf,
  inLibMonitorSQLLog,

  inLibPerfilesUsuarioIntf,
  inLibFiltrosGuardadosIntf,
  inLibRegistroPantallas,
  inLibMsgCaja,
  inLibMsgComun,
  inLibMsgConfiguracion,
  inLibDir,
  inMtoCajaMenu,
  inMtoBusquedaDatos,
  inLibGenerarTicketCaja,
  inMtoPrincipalAccionesVcl,
  inMtoModalScriptLog,
  inMtoRestauracionCopiasVcl,
  inMtoGen,
  inMtoFotoArticulo,
  System.RegularExpressions,
  inMtoModalContrasenaCopia,
  inMtoModalErrorAplicacion,
  inMtoPrincipalCertificadosVcl;

function CrearContextoRestauracionCopiasVcl(
  AFormulario: TfrmMtoPrincipal): TContextoRestauracionCopiasVcl;
begin
  Result := Default(TContextoRestauracionCopiasVcl);
  Result.Owner := AFormulario;
  Result.Dialogo := AFormulario.openDialog;
  Result.CasoUso := AFormulario.FCoordinadorOperaciones;
  Result.RutaCopias := AFormulario.ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  Result.Visible := AFormulario.mnuEjecutarScript.Visible;
  Result.ComprobarDDL :=
    function(const ASQL: string): Boolean
    begin
      Result := TRegEx.IsMatch(
        ASQL,
        '\b(CREATE|ALTER|DROP|TRUNCATE|RENAME)\b',
        [roIgnoreCase]);
    end;
  Result.CrearCopiaPrevia :=
    function: Boolean
    begin
      Result := AFormulario.CrearCopiaPreviaScript;
    end;
end;

{$R *.dfm}

const
  URL_MANUAL_WEB = 'https://www.veryverifactu.com/manual/index.html';
  URL_FORO_SOPORTE = 'https://foro.veryverifactu.com/';

resourcestring
  SErrorPantallaNoHeredaFrmBase =
    'La pantalla registrada no hereda de TfrmBase.';

type
  TClaseFrmBase = class of TfrmBase;
  TVisorMonitorSQLMemo = class(
    TInterfacedObject,
    IVisorMonitorSQL
  )
  private
    FMemo: TcxMemo;
  public
    constructor Create(AMemo: TcxMemo);
    procedure EstablecerVisible(AVisible: Boolean);
    procedure MostrarSQL(const ASQL: string);
  end;

constructor TVisorMonitorSQLMemo.Create(AMemo: TcxMemo);
begin
  inherited Create;
  FMemo := AMemo;
end;

procedure TVisorMonitorSQLMemo.EstablecerVisible(AVisible: Boolean);
begin
  if Assigned(FMemo) then
  begin
    FMemo.Visible := AVisible;
    if Assigned(FMemo.Parent) then
      FMemo.Parent.Visible := AVisible;
  end;
end;

procedure TVisorMonitorSQLMemo.MostrarSQL(const ASQL: string);
begin
  if Assigned(FMemo) and FMemo.Visible then
    FMemo.Lines.Add(
      FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + ASQL);
end;

procedure TfrmMtoPrincipal.ApplicationEvents1Idle(Sender: TObject;
                                                  var Done: Boolean);
var
  EstadoTeclas: string;
begin
  if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
    Done := True
  else
  begin
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
    if Assigned(FPresentacionInicio) then
      FPresentacionInicio.ActualizarFondo;
  end;
end;

procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
begin
  inherited;
end;

function TfrmMtoPrincipal.GetParametrosAppEdicion: IParametrosEdicion;
begin
  Result := FComposicion.ParametrosAppEdicion;
end;

function TfrmMtoPrincipal.GetParametrosCajaEdicion: IParametrosEdicion;
begin
  Result := FComposicion.ParametrosCajaEdicion;
end;

procedure TfrmMtoPrincipal.PrepararContextoAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  out AIdentidad: TIdentidadSesion;
  out AUbicacion: TUbicacionSesion);
begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create(
      SErrorContextoInicioSesionNoProporcionado);
  AsignarContextoSesion(AContextoSesion);
  AIdentidad := ContextoSesion.Identidad;
  AUbicacion := ContextoSesion.Ubicacion;
  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnException := AppException;
  FSavedNCMValid := False;
  FAppEvents.OnIdle := ApplicationEvents1Idle;
  FAppEvents.OnMessage := AppMessage;
  FreeAndNil(FPresentacionInicio);
  FPresentacionInicio := TPresentacionInicioPrincipal.Create(
    Self,
    pcPrincipal,
    imgFondoLogo,
    LookAndFeelController1,
    dxSkinController1,
    RegistroLog);
end;

procedure TfrmMtoPrincipal.MostrarSplashInicio;
begin
  FPresentacionInicio.MostrarSplash;
end;

procedure TfrmMtoPrincipal.CrearInfraestructuraAplicacion;
begin
  FormManager := TEmbeddedFormManager.Create(Self.pcPrincipal);
  FGestorExcepciones := CrearGestorExcepcionesAplicacion(
    ContextoSesion,
    RegistroLog,
    CrearPresentacionExcepcionesAplicacionVcl);
  FComposicion := TComposicionAplicacion.Create(
    Self,
    ContextoSesion,
    RegistroLog,
    PreviewTicket,
    TRegistroMonitorSQLLog.Create(
      RegistroLog,
      TVisorMonitorSQLMemo.Create(cxMemo1)),
    FGestorExcepciones,
    Self as IPresentacionOperacionesAplicacion);
  AsignarConfiguracionCampos(FComposicion.ConfiguracionCampos);
  FCoordinadorOperaciones := FComposicion.Operaciones;
  AsignarMonitorSQL(FComposicion.MonitorSQL);
  RegistroLog.AsignarMonitorSQL(FComposicion.MonitorSQL);
  AsignarConexiones(FComposicion.Conexiones);
  AsignarUnidadesMedida(FComposicion.Unidades);
  AsignarAuditoriaDatos(FComposicion.AuditoriaDatos);
  tmr1Timer(nil);
  FComposicion.CrearPerfiles;
  AsignarPerfilesUsuario(FComposicion.ServiciosPerfiles);
end;

procedure TfrmMtoPrincipal.CrearParametrosSesion(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  FComposicion.CrearParametros(AResultadoLicencia);
  AsignarParametros(
    FComposicion.ParametrosApp,
    FComposicion.ParametrosCaja);
  AsignarTraducciones(FComposicion.Traducciones);
  AplicarIdiomaFastReport(Traducciones.Idioma);
  Traducciones.Aplicar(Self);
  FPresentacionInicio.AplicarTraduccionesSplash(Traducciones);
end;

procedure TfrmMtoPrincipal.CrearServiciosSesion;
begin
  FComposicion.CrearServiciosSesion;
  AsignarFotosArticulos(FComposicion.Fotos);
  AsignarFiltrosGuardados(FComposicion.ServiciosFiltros);
end;

procedure TfrmMtoPrincipal.ComprobarConfiguracionFiscal;
begin
  FComposicion.ComprobarConfiguracionFiscal(oVersion);
end;

procedure TfrmMtoPrincipal.CargarDatosArranque;
var
  sErrorPermisos: string;
begin
  sErrorPermisos := FComposicion.CargarDatosArranque;
  AsignarInformesGuiasCache(FComposicion.InformesGuias);
  AsignarPermisos(FComposicion.Permisos);
  if sErrorPermisos <> '' then
    AvisarFalloCargaPermisos(sErrorPermisos);
end;

procedure TfrmMtoPrincipal.RegistrarFabricasPantallas;
begin
  FInyeccionMantenimientos := TInyeccionMantenimientosRaiz.Create(
    Self,
    FComposicion);
  FInyeccionMantenimientos.RegistrarFabricas;
  FInyeccionCaja := TInyeccionCajaRaiz.Create(Self, FComposicion);
  FInyeccionCaja.RegistrarFabricas;
  FInyeccionConfiguracion := TInyeccionConfiguracionRaiz.Create(
    Self,
    FComposicion);
  FInyeccionConfiguracion.RegistrarFabricas;
end;

procedure TfrmMtoPrincipal.IniciarProcesosSegundoPlano;
begin
  FComposicion.IniciarProcesosSegundoPlano;
end;

procedure TfrmMtoPrincipal.ActualizarEstadoSesion(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
var
  sDistintivo: string;
begin
  sDistintivo := '';
  jvStatusBar1.Panels[1].Text := FComposicion.DmConn.conUni.Server + ':' +
    IntToStr(FComposicion.DmConn.conUni.Port) + ' (' +
    FComposicion.DmConn.conUni.Database + ')';
  if AIdentidad.EsAdministrador then
    sDistintivo := ' ✪';
  jvStatusBar1.Panels[2].Text := AIdentidad.Usuario + ' (' +
    AIdentidad.Grupo + ') ' + sDistintivo;
  jvStatusBar1.Panels[3].Text := AUbicacion.Empresa + '\' +
    AUbicacion.Almacen + '\' + AUbicacion.Caja;
  FPresentacionInicio.AplicarTitulo(
    Self,
    EstadoLicenciaEsDemo(ParametrosApp.Licencia.Estado),
    oAppName,
    oVersion);
end;

procedure TfrmMtoPrincipal.ConfigurarPresentacionPrincipal;
begin
  AplicarPermisosMenu;
  // Visibilidad inicial del panel de monitor SQL: ya no la decide solo el
  // {$IFDEF DEBUG}. AplicarModosDepuracion la sincronizará con los flags
  // appModoDebug / appModoDebugSQL que acaba de cargar el servicio.
  pnlPPBottom.Visible := False;
  cxMemo1.Visible     := False;
  RegistroLog.AplicarModosDepuracion(ParametrosApp);
  FPresentacionInicio.Configurar(ParametrosApp, oVersion);
  Self.OnResize := FormResize;
end;

procedure TfrmMtoPrincipal.RegistrarInicioAplicacion;
begin
  FComposicion.RegistrarInicioFiscal;
end;

procedure TfrmMtoPrincipal.InicializarAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  CrearCasoUsoArranqueAplicacion(
    Self as IPasosArranqueAplicacion).Ejecutar(
      AContextoSesion,
      AResultadoLicencia);
end;

procedure TfrmMtoPrincipal.CargarServiciosAplicacion(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  CrearParametrosSesion(AResultadoLicencia);
  CrearServiciosSesion;
  ComprobarConfiguracionFiscal;
  CargarDatosArranque;
end;

procedure TfrmMtoPrincipal.ActivarAplicacion;
begin
  RegistrarFabricasPantallas;
  IniciarProcesosSegundoPlano;
end;

procedure TfrmMtoPrincipal.PresentarAplicacion(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
begin
  ActualizarEstadoSesion(AIdentidad, AUbicacion);
  ConfigurarPresentacionPrincipal;
end;

procedure TfrmMtoPrincipal.FinalizarArranqueAplicacion;
begin
  RegistrarInicioAplicacion;
  FPresentacionInicio.CerrarSplash(1000);
  MostrarAvisoCaducidadCertificados(ConexionPrincipal, RegistroLog);
end;

procedure TfrmMtoPrincipal.FormResize(Sender: TObject);
begin
  if Assigned(FPresentacionInicio) then
    FPresentacionInicio.CentrarFondo;
end;

procedure TfrmMtoPrincipal.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self, 'Tarifas');
end;

function TfrmMtoPrincipal.SolicitarDestinoCopia(
  out ARutaFichero, AContrasena: string): Boolean;
var
  bCifrada: Boolean;
  sExtension: string;
  oTipoFichero: TFileTypeItem;
begin
  ARutaFichero := '';
  AContrasena := '';
  sExtension := FCoordinadorOperaciones.ExtensionCreacionCopia;
  bCifrada := FCoordinadorOperaciones.ModoCreacionCopia =
    mpcCifrada;
  saveDialog.Title := STituloGuardarCopiaSeguridad;
  saveDialog.DefaultExtension := Copy(
    sExtension,
    2,
    MaxInt);
  saveDialog.DefaultFolder := ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  saveDialog.Options := saveDialog.Options +
    [fdoStrictFileTypes, fdoOverwritePrompt];
  saveDialog.FileTypes.Clear;
  oTipoFichero := saveDialog.FileTypes.Add;
  if bCifrada then
  begin
    oTipoFichero.DisplayName := SCaptionFiltroCopiasCifradas;
    oTipoFichero.FileMask := '*.crypt';
  end
  else
  begin
    oTipoFichero.DisplayName := SCaptionFiltroArchivosSql;
    oTipoFichero.FileMask := '*.sql';
  end;
  saveDialog.FileName := 'copiaseguridad' +
    FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) +
    sExtension;
  Result := saveDialog.Execute;
  if Result then
  begin
    ARutaFichero := ChangeFileExt(
      saveDialog.FileName,
      sExtension);
    if bCifrada then
    begin
      Result := TfrmModalContrasenaCopia.SolicitarNueva(
        Self,
        AContrasena);
    end;
  end;
end;

procedure TfrmMtoPrincipal.CopiasdeSeguridad1Click(Sender: TObject);
var
  sContrasena: string;
  sRutaFichero: string;
begin
  if SolicitarDestinoCopia(
    sRutaFichero,
    sContrasena) then
  begin
    FCoordinadorOperaciones.IniciarCopia(
      sRutaFichero,
      sContrasena);
  end;
end;

// validar iban online https://www.iban.com
// validar nif europeo https://ec.europa.eu/taxation_customs/tin/#/check-tin

procedure TfrmMtoPrincipal.AvisarFalloCargaPermisos(
  const ADetalle: string);
begin
  if not FFalloCargaPermisosAvisado then
  begin
    FFalloCargaPermisosAvisado := True;
    RegistroLog.RegistrarError(
      'No se pudieron cargar los permisos: ' + ADetalle);
    MessageDlg(Format(SAvisoCargaPermisosRestringidos, [GetLogFolder]),
               mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoPrincipal.AplicarPermisosMenu;
var
  i: Integer;
  // Las pantallas registradas quedan visibles y desactivadas. Los menús
  // directos de la rama "Menús no visibles" se ocultan por completo.
  function ProcesarItem(AItem: TMenuItem): Boolean;
  var
    j: Integer;
    sCall, sCodigo: string;
    bHayHijoVisible: Boolean;
  begin
    if AItem.Caption = '-' then
      Result := False
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
      sCodigo := FComposicion.RegistroPantallas.CodigoMenu(AItem);
      if (sCodigo <> '') and
         (not Permisos.TienePermiso(sCodigo, paPermitir)) then
      begin
        sCall := FComposicion.RegistroPantallas.CallRegistrado(AItem);
        AItem.Enabled := False;
        if sCall <> '' then
        begin
          AItem.Visible := True;
          RegistroLog.RegistrarInformacion(Format(
            'Permiso %s denegado: menú desactivado',
            [sCodigo]));
        end
        else
        begin
          AItem.Visible := False;
          RegistroLog.RegistrarInformacion(Format(
            'Permiso %s denegado: menú oculto',
            [sCodigo]));
        end;
      end;
      Result := AItem.Visible;
    end;
  end;
begin
  if Assigned(Permisos) and (Menu <> nil) then
    for i := 0 to Menu.Items.Count - 1 do
      ProcesarItem(Menu.Items[i]);
end;

procedure TfrmMtoPrincipal.ActualizarProgreso(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if Assigned(FProgressBar) and FProgressBar.Visible then
  begin
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
end;

procedure TfrmMtoPrincipal.FinalizarOperacion(
  ATipo: TTipoOperacionAplicacion;
  AResultado: TResultadoCopiaSeguridad;
  const AError: string;
  ALogBuffer: TStringList);
var
  LogForm: TfrmMtoModalScriptLog;
begin
  if Assigned(FProgressBar) then
    FProgressBar.Visible := False;
  if Assigned(FProgressLabel) then
    FProgressLabel.Visible := False;
  pnlPPBottom.Visible := False;
  if (AResultado = rcsFallida) and (AError = '') then
    FreeAndNil(ALogBuffer)
  else if ATipo = toaCopiaSeguridad then
  begin
    FreeAndNil(ALogBuffer);
    if AResultado = rcsCancelada then
      ShowMessage(SOperacionCancelada)
    else if AResultado = rcsCompletada then
      ShowMessage(SInfoCopiaSeguridadGuardada)
    else
      ShowMessage(Format(SErrorCrearCopiaSeguridad, [AError]));
  end
  else if ATipo = toaRestauracion then
  begin
    if AResultado = rcsCancelada then
    begin
      FreeAndNil(ALogBuffer);
      ShowMessage(SAvisoRestauracionCancelada);
    end
    else
    begin
      LogForm := TfrmMtoModalScriptLog.Create(Self);
      LogForm.LogMemo.Lines.Add(
        '-- RESTAURACIÓN DE COPIA DE SEGURIDAD --');
      LogForm.LogMemo.Lines.Add(
        '-------------------------------------------------');
      if Assigned(ALogBuffer) then
      begin
        LogForm.AppendLines(ALogBuffer);
        FreeAndNil(ALogBuffer);
      end;
      LogForm.Show;
      if AResultado = rcsCompletada then
        ShowMessage(SScriptEjecutado)
      else
        ShowMessage(Format(SErrorEjecutarScript, [AError]));
    end;
  end;
end;

procedure TfrmMtoPrincipal.SolicitarCancelarOperacionEnCurso;
begin
  if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
  begin
    if FCoordinadorOperaciones.CancelacionSolicitada then
      ShowMessage(SCancelacionSolicitada)
    else if MessageDlg(
         SPreguntaCancelarOperacion,
         mtWarning,
         [mbYes, mbNo],
         0) = mrYes then
    begin
      FCoordinadorOperaciones.SolicitarCancelacion;
    end;
  end;
end;

procedure TfrmMtoPrincipal.MostrarOperacion;
begin
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
  FProgressLabel.Caption := SCaptionPreparando;
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmMtoPrincipal.MostrarCancelando;
begin
  if Assigned(FProgressLabel) then
  begin
    FProgressLabel.Caption := SCaptionCancelandoOperacion;
    FProgressLabel.Update;
  end;
end;

function TfrmMtoPrincipal.CrearCopiaPreviaScript: Boolean;
var
  sContrasena: string;
  sRutaFichero: string;
begin
  Result := SolicitarDestinoCopia(
    sRutaFichero,
    sContrasena);
  if Result then
    Result := FCoordinadorOperaciones.CrearCopia(
      sRutaFichero,
      sContrasena);
end;

function TfrmMtoPrincipal.CrearCopiaPreviaScriptSoporte: Boolean;
begin
  Result := CrearCopiaPreviaScript;
end;

procedure TfrmMtoPrincipal.FormActivate(Sender: TObject);
begin
  inherited;
  // FormPaint(Sender);
end;

destructor TfrmMtoPrincipal.Destroy;
begin
  if Assigned(FInyeccionConfiguracion) then
    FInyeccionConfiguracion.RetirarFabricas;
  FreeAndNil(FInyeccionConfiguracion);
  if Assigned(FInyeccionCaja) then
    FInyeccionCaja.RetirarFabricas;
  FreeAndNil(FInyeccionCaja);
  if Assigned(FInyeccionMantenimientos) then
    FInyeccionMantenimientos.RetirarFabricas;
  FreeAndNil(FInyeccionMantenimientos);
  FCoordinadorOperaciones := nil;
  FGestorExcepciones := nil;
  FreeAndNil(FPresentacionInicio);
  FreeAndNil(FComposicion);
  inherited;
end;

procedure TfrmMtoPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
var
  GestorContexto: IGestorContextoSesion;
begin
  // Señalar a las tareas de segundo plano que la app se esta cerrando, ANTES
  // de empezar a liberar formularios y conexiones. Asi no arrancan trabajo
  // nuevo ni tocan formularios en destruccion
  // (ver inMtoGen.EjecutarEnBackground
  // y el destructor de TfrmMtoGen).
  if Supports(
    ContextoSesion,
    IGestorContextoSesion,
    GestorContexto
  ) then
    GestorContexto.MarcarCierreAplicacion;
  if Assigned(FComposicion) then
  begin
    FComposicion.RegistrarCierreFiscal;
    FComposicion.DetenerProcesosSegundoPlano;
  end;
  // Las ventas flotantes conservan referencias a servicios de la sesion.
  // Deben destruirse antes de liberar la composicion que los proporciona.
  LiberarOperacionesCaja;
  inherited;
  try
    RegistroLog.RegistrarInformacion('Cerrando ventana principal');
    tmr1.Enabled := False;
    if Assigned(FormManager) then
    try
      FormManager.CloseAll;
    except
      on E: Exception do
        RegistroLog.RegistrarError('Error en CloseAll: ' + E.Message);
    end;
    AsignarFotosArticulos(nil);
    AsignarUnidadesMedida(nil);
    AsignarTraducciones(nil);
    AsignarParametros(nil, nil);
    DesvincularConsultaStockPrincipal;
    AsignarPerfilesUsuario(
      CrearServiciosPerfilesUsuario(nil, nil, nil));
    AsignarFiltrosGuardados(
      CrearServiciosFiltrosGuardados(nil, nil, nil));
    AsignarAuditoriaDatos(nil);
    RegistroLog.AsignarMonitorSQL(nil);
    AsignarMonitorSQL(nil);
    AsignarConexiones(nil);
    AsignarInformesGuiasCache(nil);
    FCoordinadorOperaciones := nil;
    FreeAndNil(FComposicion);
    if Assigned(FAppEvents) then
    begin
      FAppEvents.OnException := nil;
      FAppEvents.OnMessage := nil;
    end;
    FGestorExcepciones := nil;
  finally
    RegistroLog.RegistrarInformacion('Ventana principal Cerrada');
    Action := caFree;
  end;
end;

procedure TfrmMtoPrincipal.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  inherited;
  if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
  begin
    CanClose := False;
    SolicitarCancelarOperacionEnCurso;
  end
  // Cierre por reinicio de sesion ('Invocar login'): no preguntar.
  else if (FReiniciando) then
    CanClose := True
  else if (pcPrincipal.PageCount = 0) then
  begin
    if MessageDlg(SPreguntaSalirAplicacion,
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      CanClose := False; // Cancela el cierre
    end
    else
    begin
      CanClose := True;  // Permite el cierre
    end;
  end;
  if CanClose and not FReiniciando then
    CanClose := PuedenCerrarOperacionesCaja;
end;

procedure TfrmMtoPrincipal.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmMtoPrincipal.FormShow(Sender: TObject);
begin
  if FException then
    PostMessage(Handle, wm_Close, 0, 0);
  if not FException then
  begin
    // Garantiza el z-order y la visibilidad con el formulario ya visible
    imgFondoLogo.BringToFront;
    if Assigned(FPresentacionInicio) then
      FPresentacionInicio.ActualizarFondo;
  end;
end;

procedure TfrmMtoPrincipal.AbrirCajonDesdePresentacion;
var
  Resultado: TResultadoAperturaCajon;
begin
  Resultado := AbrirCajonSinVenta(Permisos, ParametrosCaja);
  if not Resultado.Correcto then
  begin
    MessageDlg(Resultado.Mensaje, mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoPrincipal.AppMessage(var Msg: TMsg; var Handled: Boolean);
var
  oControlActivo: TWinControl;
begin
  oControlActivo := Screen.ActiveControl;
  // Solo pulsaciones de tecla y descartando la autorrepeticion (bit 30).
  if (Msg.message = WM_KEYDOWN) and ((Msg.lParam and $40000000) = 0) then
  begin
    // F9: abrir el cajon portamonedas desde cualquier ventana del programa
    // (caja, mantenimientos o el propio principal) si hay impresora de
    // tickets asignada. Sin impresora solo responde con la sesion de caja
    // abierta, para avisar de la falta de
    // configuracion. F9 sola, sin Ctrl/Alt/Mayus.
    if (Msg.wParam = WPARAM(VK_ESCAPE)) and
       Assigned(FCoordinadorOperaciones) and
       FCoordinadorOperaciones.EnCurso then
    begin
      SolicitarCancelarOperacionEnCurso;
      Handled := True;
    end
    else if (Msg.wParam = WPARAM(VK_ESCAPE)) and
            (Application.ModalLevel > 0) and
            Assigned(Screen.ActiveForm) and
            (Screen.ActiveForm <> Self) then
    begin
      Screen.ActiveForm.Close;
      Handled := True;
    end
    else if (Msg.wParam = WPARAM(VK_F9)) and
       (ImpresoraCajaAsignada(ParametrosCaja) or
        MenuCajaAbierto) and
       (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
       (GetKeyState(VK_SHIFT) >= 0) then
    begin
      AbrirCajonDesdePresentacion;
      Handled := True;
    end
    // Ctrl+A conserva Seleccionar todo cuando el foco esta en un editor.
    else if (Msg.wParam = WPARAM(Ord('A'))) and
            (GetKeyState(VK_CONTROL) < 0) and
            (GetKeyState(VK_MENU) >= 0) and
            (GetKeyState(VK_SHIFT) >= 0) and
            Assigned(oControlActivo) and
            ((oControlActivo is TcxCustomTextEdit) or
             (oControlActivo is TCustomEdit)) then
    begin
      if oControlActivo is TcxCustomTextEdit then
        TcxCustomTextEdit(oControlActivo).SelectAll
      else
        TCustomEdit(oControlActivo).SelectAll;
      Handled := True;
    end
    // Ctrl+E: consulta de articulos similares desde cualquier ventana.
    else if (Msg.wParam = WPARAM(Ord('E'))) and
             (GetKeyState(VK_CONTROL) < 0) and
             (GetKeyState(VK_MENU) >= 0) and
             (GetKeyState(VK_SHIFT) >= 0) then
    begin
      mnuArticulosSimilaresClick(Self);
      Handled := True;
    end
    // Ctrl+U: consulta de stock global, precargando el articulo en foco.
    else if (Msg.wParam = WPARAM(Ord('U'))) and
             (GetKeyState(VK_CONTROL) < 0) and
             (GetKeyState(VK_MENU) >= 0) and (GetKeyState(VK_SHIFT) >= 0) then
    begin
      mnuConsultaStocksClick(Self);
      Handled := True;
    end;
  end;
end;

function EsFormularioFlotante(
  AFormulario, AFormularioPrincipal: TCustomForm): Boolean;
begin
  Result := Assigned(AFormulario) and
    (AFormulario <> AFormularioPrincipal) and
    (AFormulario.Parent = nil);
end;

function EjecutarAtajoFormulario(
  AFormulario: TCustomForm;
  var AMensaje: TWMKey): Boolean;
var
  Componente: TComponent;
  i: Integer;
begin
  Result := False;
  i := 0;
  while (i < AFormulario.ComponentCount) and (not Result) do
  begin
    Componente := AFormulario.Components[i];
    if Componente is TActionList then
      Result := TActionList(Componente).IsShortCut(AMensaje);
    Inc(i);
  end;
end;

function FormularioPestanaActiva(
  APaginas: TcxPageControl): TCustomForm;
var
  Pestana: TcxTabSheet;
  PaginaActiva: Integer;
begin
  Result := nil;
  if APaginas.PageCount > 0 then
  begin
    PaginaActiva := APaginas.ActivePageIndex;
    if PaginaActiva >= 0 then
    begin
      Pestana := APaginas.Pages[PaginaActiva] as TcxTabSheet;
      if (Pestana.ControlCount > 0) and
         (Pestana.Controls[0] is TCustomForm) then
        Result := Pestana.Controls[0] as TCustomForm;
    end;
  end;
end;

function TfrmMtoPrincipal.IsShortCut(var Message: TWMKey): Boolean;
var
  FormularioActivo: TCustomForm;
  FormularioPestana: TCustomForm;
  bEsFlotante: Boolean;
begin
  Result := False;
  FormularioActivo := Screen.ActiveForm;
  bEsFlotante := EsFormularioFlotante(FormularioActivo, Self);
  // F9 sola (sin Ctrl/Alt/Mayus ni autorrepeticion) -> abrir el cajon
  // portamonedas, mismo criterio que AppMessage. Via redundante: cubre el
  // foco en el principal y sus pestañas embebidas aunque Application.OnMessage
  // quede desenganchado; si AppMessage ya trato la tecla, el mensaje no se
  // despacha y este punto no llega a ejecutarse (no hay doble apertura).
  if (Message.CharCode = VK_F9) and
     (HiWord(Message.KeyData) and KF_REPEAT = 0) and
     (ImpresoraCajaAsignada(ParametrosCaja) or
      MenuCajaAbierto) and
     (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
     (GetKeyState(VK_SHIFT) >= 0) then
  begin
    AbrirCajonDesdePresentacion;
    Result := True;
  end
  // Alt+F4 -> cerrar aplicacion
  else if (Message.CharCode = VK_F4) and
          (HiWord(Message.KeyData) and KF_ALTDOWN <> 0) then
  begin
    Self.Close;
    Result := True;
  end
  // Ctrl+F4 -> cerrar pestaña activa o ventana flotante
  else if (Message.CharCode = VK_F4) and
          (GetKeyState(VK_CONTROL) < 0) and
          (HiWord(Message.KeyData) and KF_ALTDOWN = 0) then
  begin
    if bEsFlotante then
      FormularioActivo.Close
    else if pcPrincipal.PageCount > 0 then
      FormManager.CloseActiveForm;
    Result := True;
  end
  // ESC -> cerrar pestaña activa o salir
  else if Message.CharCode = VK_ESCAPE then
  begin
    if Application.ModalLevel > 0 then
      Result := inherited IsShortCut(Message)
    else if bEsFlotante then
      Result := inherited IsShortCut(Message)
    else if pcPrincipal.PageCount = 0 then
    begin
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
      Result := True;
    end
    else
    begin
      FormManager.CloseActiveForm;
      Result := True;
    end;
  end
  else if bEsFlotante then
    Result := EjecutarAtajoFormulario(FormularioActivo, Message)
  else
  begin
    FormularioPestana := FormularioPestanaActiva(pcPrincipal);
    if Assigned(FormularioPestana) then
      Result := EjecutarAtajoFormulario(FormularioPestana, Message);
    if not Result then
      Result := inherited IsShortCut(Message);
  end;
end;

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
begin
  TCoordinadorRestauracionCopiasVcl.Ejecutar(
    CrearContextoRestauracionCopiasVcl(Self));
end;

procedure TfrmMtoPrincipal.tmr1Timer(Sender: TObject);
var
  ADateStr          : string;
  ATimeStr          : string;
  bConectado        : Boolean;
begin
  bConectado := False;
  ADateStr := DateToStr(Now);
  ATimeStr := FormatDateTime('hh:mm', Now);
  if Assigned(FComposicion) and Assigned(FComposicion.DmConn) then
    if FComposicion.DmConn.conUni.Connected then
    begin
      bConectado := True;
      jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + ' Conn';
    end
    else
      bConectado := False;
  if (not Assigned(FComposicion)) or
     (not Assigned(FComposicion.DmConn)) or
     (not bConectado) then
  begin
    jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + 'NO Conn';
    RegistroLog.RegistrarError('Se ha perdido la conexión con la BBDD');
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
begin
  inherited;
  MostrarListadoVentas(Self);
end;

procedure TfrmMtoPrincipal.mnuListadoDocsProveedorClick(Sender: TObject);
begin
  inherited;
  MostrarListadoDocumentosProveedor(Self);
end;

procedure TfrmMtoPrincipal.mnuListadoEfectosPagoClick(Sender: TObject);
begin
  inherited;
  MostrarListadoEfectosPago(Self);
end;

procedure TfrmMtoPrincipal.mnuMenuCajaClick(Sender: TObject);
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    FInyeccionCaja.MostrarMenu(Permisos);
    Self.WindowState := wsMinimized;
  end;
end;

procedure TfrmMtoPrincipal.AbrirUrlAyuda(const AUrl: string);
var
  Resultado: HINST;
begin
  Resultado := ShellExecute(0,
                            'open',
                            PChar(AUrl),
                            nil,
                            nil,
                            SW_SHOWNORMAL);
  if Resultado <= 32 then
    ShowMessage(Format(SErrorAbrirDireccion, [AUrl]));
end;

procedure TfrmMtoPrincipal.mnuAcercadeClick(Sender: TObject);
begin
  inherited;
  MostrarAcercaDe(Self, RegistroLog);
end;

procedure TfrmMtoPrincipal.mnuForoSoporteClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(URL_FORO_SOPORTE);
end;

procedure TfrmMtoPrincipal.mnuConsultaStocksClick(Sender: TObject);
begin
  if mnuConsultaStocks.Enabled then
    MostrarConsultaStockPrincipal(Self, pcPrincipal);
end;

procedure TfrmMtoPrincipal.mnuArticulosSimilaresClick(Sender: TObject);
var
  LForm: TForm;
begin
  if mnuArticulosSimilares.Enabled then
  begin
    LForm := Screen.ActiveForm;
    if not (LForm is TfrmMtoBusquedaDatos) then
    begin
      FInyeccionConfiguracion.EjecutarBusquedaDatos(Self, LForm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuManualWebClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(URL_MANUAL_WEB);
end;

procedure TfrmMtoPrincipal.mnuProcesosAuxiliaresBBDDClick(
  Sender: TObject);
begin
  inherited;
  if mnuProcesosAuxiliaresBBDD.Visible then
    MostrarProcesosAuxiliares(Self);
end;

procedure TfrmMtoPrincipal.MenuGenericoClick(Sender: TObject);
var
  oItem: TMenuItem;
  sCall: string;
begin
  if (Sender is TMenuItem) then
  begin
    oItem := TMenuItem(Sender);
    // Mismo guardado que los handlers viejos: solo abre si el item
    // esta visible (permisos de menu ya aplicados).
    if oItem.Visible then
    begin
      sCall := FComposicion.RegistroPantallas.CallRegistrado(oItem);
      if sCall <> '' then
        ShowMto(Self, sCall);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuCajaParamClick(Sender: TObject);
begin
  inherited;
  if mnuMenuCaja.Visible then
    FInyeccionCaja.MostrarParametros;
end;

procedure TfrmMtoPrincipal.mnuListadoOperacionesVentaClick(
  Sender: TObject);
begin
  inherited;
  if mnuListadoOperacionesVenta.Visible then
    FInyeccionCaja.MostrarInformeOperacionesVenta;
end;

procedure TfrmMtoPrincipal.mnuCajaSolicitudesTraspasoHistClick(
  Sender: TObject);
begin
  inherited;
  if mnuCajaSolicitudesTraspasoHist.Visible then
    FInyeccionCaja.MostrarHistoricoSolicitudesTraspaso(
      mnuCajaSolicitudesTraspasoHist.Caption);
end;

procedure TfrmMtoPrincipal.CargarEfectosVenta1Click(Sender: TObject);
begin
  inherited;
  if CargarEfectosVenta1.Visible then
    CargarEfectosRemesaPrincipal(
      nil,
      FInyeccionConfiguracion.CrearRepositorioCargaEfectos(
        'frmModalCargarEfectosVenta'),
      True,
      procedure
      begin
        ShowMto(Self, 'RemesasVenta');
      end);
end;

procedure TfrmMtoPrincipal.Sesiones1Click(Sender: TObject);
begin
  inherited;
  if mnuCrearArtculosyunpedidoounalbarn.Visible then
    ShowMto(Self, 'ComprasSesiones');
end;

procedure TfrmMtoPrincipal.FacturarAlbaranes1Click(Sender: TObject);
begin
  inherited;
  if FacturarAlbaranes1.Visible and FacturarAlbaranesCompra then
    ShowMto(Self, 'FacturasCompra');
end;

procedure TfrmMtoPrincipal.CargarEfectos1Click(Sender: TObject);
begin
  inherited;
  if CargarEfectos1.Visible then
    CargarEfectosRemesaPrincipal(
      nil,
      FInyeccionConfiguracion.CrearRepositorioCargaEfectos(
        'frmModalCargarEfectosCompra'),
      False,
      procedure
      begin
        ShowMto(Self, 'RemesasCompra');
      end);
end;

procedure TfrmMtoPrincipal.Formasdepago2Click(Sender: TObject);
begin
  inherited;
  if Formasdepago2.Visible then
    ShowMto(Self, 'FormasdePago');
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

procedure TfrmMtoPrincipal.mnuParmetrosdeEntornoClick(Sender: TObject);
begin
  inherited;
  FInyeccionConfiguracion.MostrarParametrosAplicacion;
end;

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVerifactuDeclaracionClick(Sender: TObject);
begin
  if (mnuVerifactuDeclaracion.Visible) then
    MostrarDeclaracionVerifactu(Self);
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenHorizontalClick(Sender: TObject);
begin
  // Informe A4 horizontal (FastReport) del balance de almacén por tallas
  // con foto. El usuario filtra modo (entre fechas / acumulados), nivel de
  // detalle, fechas, almacén y familia en el propio modal.
  if mnuBalanceAlmacenHorizontal.Visible then
    MostrarBalanceAlmacenHorizontal;
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenSinTallasClick(Sender: TObject);
begin
  // Informe vertical (FastReport) del balance de almacén SIN tallas: una fila
  // por (artículo, color, banda). Incluye todos los artículos, también los no
  // tallables que el informe horizontal deja fuera. Mismos filtros, modos,
  // bandas y agrupaciones.
  if mnuBalanceAlmacenSinTallas.Visible then
    MostrarBalanceAlmacenSinTallas;
end;

procedure TfrmMtoPrincipal.mnuMovVentasArtClick(Sender: TObject);
begin
  // Informe A4 horizontal (FastReport) del ranking de ventas por artículos y
  // fechas: una fila por artículo (o por artículo+almacén si se agrupa por
  // almacén) con las magnitudes de compra/venta del periodo y dos márgenes.
  // Mismos filtros que el balance más la fecha "Inicio compras".
  if mnuMovVentasArt.Visible then
    MostrarMovimientosVentasArticulos;
end;

// Foto flotante transversal: cuando el usuario cambia de pestana
// (=Mto activo), si la pantalla flotante ya esta abierta la
// re-vincula al nuevo Mto. Si no esta abierta no hacemos nada: el
// usuario la abre manualmente con Ctrl+F cuando quiera.
procedure TfrmMtoPrincipal.pcPrincipalChange(Sender: TObject);
var
  FormularioFoto: TfrmFotoArticulo;
  ts: TcxTabSheet;
begin
  if Assigned(FPresentacionInicio) then
    FPresentacionInicio.ActualizarFondo;
  FormularioFoto := FotoFlotanteActual;
  if pcPrincipal.ActivePageIndex < 0 then
  begin
    if (FormularioFoto <> nil) and FormularioFoto.Visible then
    begin
      FormularioFoto.VincularDataSources([], nil);
      FormularioFoto.SetArticuloSku('', '');
    end;
  end;
  if pcPrincipal.ActivePageIndex >= 0 then
  begin
    ts := pcPrincipal.Pages[pcPrincipal.ActivePageIndex] as TcxTabSheet;
    if (ts.ControlCount = 0) or not (ts.Controls[0] is TfrmMtoGen) then
    begin
      if (FormularioFoto <> nil) and FormularioFoto.Visible then
        FormularioFoto.VincularDataSources([], nil);
    end
    else
      EngancharFotoAlMto(ts.Controls[0]);
  end;
end;

// --- IAnfitrionPantallas -------------------------------------------
function TfrmMtoPrincipal.GestorVentanas: TEmbeddedFormManager;
begin
  if FormManager = nil then
    FormManager := TEmbeddedFormManager.Create(pcPrincipal);
  Result := FormManager;
end;

function TfrmMtoPrincipal.RegistroPantallas: TfzaWinF;
begin
  Result := FComposicion.RegistroPantallas;
end;

function TfrmMtoPrincipal.CrearPantalla(AClase: TFormClass): TForm;
var
  Contexto: TContextoAutorizacionPantalla;
begin
  if not AClase.InheritsFrom(TfrmBase) then
  begin
    raise EInvalidCast.Create(
      SErrorPantallaNoHeredaFrmBase);
  end;
  if TieneFabricaPantalla(AClase) then
    Result := CrearPantallaInyectada(AClase, Self)
  else
  begin
    Contexto := TContextoAutorizacionPantalla.Crear(Permisos);
    Result := TClaseFrmBase(AClase).Create(Self, Contexto);
  end;
end;

function TfrmMtoPrincipal.ResolverCallPantalla(
  const AUnidadClase: string): string;
begin
  Result := FComposicion.RegistroPantallas.CallDeUnit(AUnidadClase);
end;

function TfrmMtoPrincipal.ResolverDataModulePantalla(
  const AUnidadClase: string): string;
begin
  Result := FComposicion.RegistroPantallas.GetDataModuleName(
    AUnidadClase);
end;

procedure TfrmMtoPrincipal.CancelarEdicionesPantallas;
begin
  CancelarGrids(pcPrincipal);
end;

procedure TfrmMtoPrincipal.VincularFotoMantenimiento(
  AMantenimiento: TObject);
begin
  EngancharFotoAlMto(AMantenimiento);
end;

function TfrmMtoPrincipal.MenuAplicacion: TMainMenu;
begin
  Result := Menu;
end;

function TfrmMtoPrincipal.CrearOperacionCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IOperacionCaja;
begin
  Result := FInyeccionCaja.CrearOperacion(AOwner, APermisos);
end;

function TfrmMtoPrincipal.CrearConsultaOperacionesCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
begin
  Result := FInyeccionCaja.CrearConsulta(AOwner, APermisos);
end;

function TfrmMtoPrincipal.CrearTraspasoCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): ITraspasoCaja;
begin
  Result := FInyeccionCaja.CrearTraspaso(AOwner, APermisos);
end;

function TfrmMtoPrincipal.CrearRepositorioDistribuidorVisual:
  IRepositorioDistribuidor;
begin
  Result := FInyeccionConfiguracion.CrearRepositorioDistribuidor;
end;

// Restaurar la ventana principal y apartar el menu de caja antes de
// abrir una pantalla de gestion (antes lo hacia inLibShowMto tocando
// este form directamente).
procedure TfrmMtoPrincipal.PrepararAperturaPantalla;
var
  iForm: Integer;
begin
  if WindowState = wsMinimized then
    WindowState := wsMaximized;
  for iForm := 0 to Screen.FormCount - 1 do
  begin
    if (Screen.Forms[iForm].ClassName = 'TfrmMtoMenuCaja') and
       (Screen.Forms[iForm].WindowState <> wsMinimized) then
      Screen.Forms[iForm].WindowState := wsMinimized;
  end;
end;

procedure TfrmMtoPrincipal.EngancharFotoAlMto(AMto: TObject);
var
  FormularioFoto: TfrmFotoArticulo;
  frmActivo     : TfrmMtoGen;
  sArt, sSku    : string;
begin
  // Solo re-vincula si la flotante YA esta abierta (el usuario la
  // abrio con Ctrl+F en algun Mto y al cambiar a otro queremos
  // que siga el contexto). NO la abrimos automaticamente: el usuario
  // decide cuando aparece.
  FormularioFoto := FotoFlotanteActual;
  if (FormularioFoto <> nil) and FormularioFoto.Visible and
     (AMto is TfrmMtoGen) then
  begin
    frmActivo := TfrmMtoGen(AMto);
    frmActivo.ResolverArtSkuActivo(sArt, sSku);
    FormularioFoto.VincularDataSources(frmActivo.DataSourcesParaFoto,
                                       frmActivo.ResolverArtSkuActivo);
    FormularioFoto.SetArticuloSku(sArt, sSku);
  end;
end;

// Reenvío compatible con TApplicationEvents.OnException.
procedure TfrmMtoPrincipal.AppException(Sender: TObject; E: Exception);
begin
  FGestorExcepciones.Gestionar(Sender, E);
end;

end.
