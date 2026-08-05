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
  inLibExcepcionesAplicacionIntf,
  inLibOperacionesAplicacionIntf,
  inLibRepositoriosPantallaIntf,
  UniDataComposicionAplicacion;

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
    ICompositorSqlPantalla,
    ICompositorArticulosPantalla,
    ICompositorConfiguracionPantalla,
    ICompositorDocumentosPantalla,
    ICompositorRemesasPantalla,
    ICompositorOperacionesPantalla,
    ICompositorVentasPantalla,
    ICompositorCajaPantalla,
    ICompositorTicketsCajaPantalla
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
    function CrearServiciosSqlPantalla(
      const ANombrePantalla: string): TServiciosSqlPantalla;
    function CrearRepositoriosArticulosPantalla(
      const ANombrePantalla: string): IRepositoriosArticulosPantalla;
    function CrearRepositoriosConfiguracionPantalla(
      const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
    function CrearRepositoriosDocumentosPantalla(
      const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
    function CrearRepositoriosRemesasPantalla(
      const ANombrePantalla: string): IRepositoriosRemesasPantalla;
    function CrearRepositoriosOperacionesPantalla(
      const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
    function CrearRepositoriosVentasPantalla(
      const ANombrePantalla: string): IRepositoriosVentasPantalla;
    function CrearRepositoriosCajaPantalla(
      const ANombrePantalla: string): IRepositoriosCajaPantalla;
    function CrearRepositoriosTicketsCajaPantalla(
      const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
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
    FCoordinadorOperaciones: ICasoUsoCopiasSeguridad;
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
    function CrearStockConsultaInyectada(
      AOwner: TComponent): TForm;
    procedure IniciarProcesosSegundoPlano;
    procedure ActualizarEstadoSesion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure AplicarTema;
    procedure ConfigurarPresentacionPrincipal;
    procedure RegistrarInicioAplicacion;
    procedure AbrirUrlAyuda(const AUrl: string);
    procedure AplicarTituloVentana;
    procedure AppException(Sender: TObject; E: Exception);
    procedure AplicarPermisosMenu;
    procedure AvisarFalloCargaPermisos(const ADetalle: string);
    function SolicitarDestinoCopia(
      out ARutaFichero, AContrasena: string
    ): Boolean;
    function CrearCopiaPreviaScript: Boolean;
    procedure SolicitarCancelarOperacionEnCurso;
    procedure ActualizarFondoLogo;
    procedure CargarFondoLogo;
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    function GetParametrosAppEdicion: IParametrosEdicion;
    function GetParametrosCajaEdicion: IParametrosEdicion;
    // Atajos globales capturados a nivel de aplicacion (las ventanas de caja
    // son top-level y no pasan por IsShortCut): F9 abre el cajon desde
    // cualquier ventana si hay impresora de tickets asignada y Ctrl+U abre
    // la consulta de stock; Ctrl+E abre la consulta de articulos similares.
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure AbrirCajonDesdePresentacion;
    procedure MostrarAvisoCaducidadCertificado;
  public
    { Public declarations }
    FormManager : TEmbeddedFormManager;
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
    destructor Destroy; override;
    procedure InicializarAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure CerrarSplashInicio(aMinimoMs: Integer);
    procedure CrearLogoFondoBg;
    procedure CentrarLogoFondoBg;
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
  inMtoSplash,
  inMtoAppParam,
  inMtoCajaMenu,
  inMtoCajaOpe,
  inMtoConsultaOpe,
  inMtoTraspasoOpe,
  inMtoCajaParam,
  inMtoBusquedaDatos,
  inMtoModalVerifactuDecl,
  inLibGenerarTicketCaja,
  inMtoStockConsulta,
  inMtoStockConsultaPresentacionComposicion,
  inMtoModalListadoVentas,
  inMtoModalImpOperacionesVenta,
  inMtoModalScriptLog,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inMtoModalImpMovVentasArt,
  inMtoModalImpDocsProveedor,
  inMtoModalImpEfectosPago,
  inMtoModalFacturarAlbaranes,
  inMtoRestauracionCopiasVcl,
  inMtoModalCargarEfectosRemesa,
  inMtoModalProcesosAuxiliaresBBDD,
  inLibCertificates,
  inLibPrincipalCertificadosIntf,
  UniDataPrincipalCertificadosRepositorio,
  inMtoGen,
  inMtoFotoArticulo,
  System.DateUtils,
  System.RegularExpressions,
  inMtoModalContrasenaCopia,
  inMtoModalErrorAplicacion;

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
  TfrmStockConsultaInyectada = class(TfrmStockConsulta)
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasStockConsulta);
  end;
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

constructor TfrmStockConsultaInyectada.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasStockConsulta);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
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

procedure TfrmMtoPrincipal.MostrarAvisoCaducidadCertificado;
const
  DIAS_AVISO_CERTIFICADO = 5;
var
  Avisos: TStringList;
  Certificado: TCertificadoEmpresaActivo;
  Certificados: TCertificadosEmpresasActivos;
  Repositorio: IRepositorioCertificadosEmpresas;
  sEmpresa: string;
  sSerie: string;
  sTitular: string;
  sTitularReal: string;
  sPrefijo: string;
  dCaducidad: TDateTime;
  iDias: Integer;
  bHayCaducidad: Boolean;

  function TextoDias(ADias: Integer): string;
  begin
    if ADias <= 0 then
      Result := SCertificadoQuedaMenosUnDia
    else if ADias = 1 then
      Result := SCertificadoQuedaUnDia
    else
      Result := Format(SCertificadoQuedanDias, [ADias]);
  end;

  procedure AgregarAviso(const ATexto: string);
  begin
    sPrefijo := '- ' + sEmpresa + ': ';
    if Trim(sTitularReal) <> '' then
      sPrefijo := sPrefijo + Trim(sTitularReal) + ', ';
    Avisos.Add(sPrefijo + ATexto);
  end;

begin
  if ConexionPrincipal <> nil then
  begin
    Avisos := TStringList.Create;
    try
      try
        Repositorio := CrearRepositorioCertificadosEmpresasUniDAC(
          ConexionPrincipal);
        Certificados := Repositorio.ListarActivos;
        for Certificado in Certificados do
        begin
          sEmpresa := Trim(Certificado.Empresa);
          if sEmpresa = '' then
            sEmpresa := Trim(Certificado.CodigoEmpresa);
          sSerie := Trim(Certificado.Serie);
          sTitular := Trim(Certificado.Titular);
          sTitularReal := sTitular;
          bHayCaducidad := ObtenerCaducidadCertificado(sSerie, sTitular,
                                                       dCaducidad,
                                                       sTitularReal);
          if (not bHayCaducidad) and Certificado.TieneFechaHasta then
          begin
            dCaducidad := Certificado.FechaHasta;
            bHayCaducidad := dCaducidad > 0;
          end;
          if sTitularReal = '' then
            sTitularReal := sTitular;
          if bHayCaducidad then
          begin
            if dCaducidad < Now then
            begin
              AgregarAviso(
                Format(SAvisoCertificadoCaducado,
                       [FormatDateTime('dd/mm/yyyy hh:nn', dCaducidad)]));
            end
            else if dCaducidad < IncDay(Now, DIAS_AVISO_CERTIFICADO) then
            begin
              iDias := Trunc(dCaducidad - Now);
              AgregarAviso(
                Format(SAvisoCertificadoProximoCaducar,
                       [FormatDateTime('dd/mm/yyyy hh:nn', dCaducidad),
                        TextoDias(iDias)]));
            end;
          end;
        end;
        if Avisos.Count > 0 then
        begin
          MessageDlg(Format(SAvisoCertificadosCaducidad, [Avisos.Text]),
                     mtWarning, [mbOK], 0);
        end;
      except
        on E: Exception do
          RegistroLog.RegistrarAviso('No se pudo comprobar la caducidad de ' +
            'certificados al arrancar: ' + E.Message);
      end;
    finally
      FreeAndNil(Avisos);
    end;
  end;
end;

procedure TfrmMtoPrincipal.AplicarTituloVentana;
var
  sTitulo: string;
begin
  if EstadoLicenciaEsDemo(ParametrosApp.Licencia.Estado) then
    sTitulo := oAppName + ' DEMO ' + oVersion
  else
    sTitulo := oAppName + ' ' + oVersion;
  Self.Caption := sTitulo;
  Application.Title := sTitulo;
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
    ActualizarFondoLogo;
  end;
end;

procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
begin
  // El proyecto inyecta el contexto antes de inicializar los servicios.
end;

function TfrmMtoPrincipal.GetParametrosAppEdicion: IParametrosEdicion;
begin
  Result := FComposicion.ParametrosAppEdicion;
end;

function TfrmMtoPrincipal.GetParametrosCajaEdicion: IParametrosEdicion;
begin
  Result := FComposicion.ParametrosCajaEdicion;
end;

function TfrmMtoPrincipal.CrearServiciosSqlPantalla(
  const ANombrePantalla: string): TServiciosSqlPantalla;
begin
  Result := FComposicion.CrearServiciosSqlPantalla(ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosArticulosPantalla(
  const ANombrePantalla: string): IRepositoriosArticulosPantalla;
begin
  Result := FComposicion.CrearRepositoriosArticulosPantalla(
    ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosConfiguracionPantalla(
  const ANombrePantalla: string): IRepositoriosConfiguracionPantalla;
begin
  Result := FComposicion.CrearRepositoriosConfiguracionPantalla(
    ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosDocumentosPantalla(
  const ANombrePantalla: string): IRepositoriosDocumentosPantalla;
begin
  Result := FComposicion.CrearRepositoriosDocumentosPantalla(
    ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosRemesasPantalla(
  const ANombrePantalla: string): IRepositoriosRemesasPantalla;
begin
  Result := FComposicion.CrearRepositoriosRemesasPantalla(
    ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosOperacionesPantalla(
  const ANombrePantalla: string): IRepositoriosOperacionesPantalla;
begin
  Result := FComposicion.CrearRepositoriosOperacionesPantalla(
    ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosVentasPantalla(
  const ANombrePantalla: string): IRepositoriosVentasPantalla;
begin
  Result := FComposicion.CrearRepositoriosVentasPantalla(
    ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosCajaPantalla(
  const ANombrePantalla: string): IRepositoriosCajaPantalla;
begin
  Result := FComposicion.CrearRepositoriosCajaPantalla(ANombrePantalla);
end;

function TfrmMtoPrincipal.CrearRepositoriosTicketsCajaPantalla(
  const ANombrePantalla: string): IRepositoriosTicketsCajaPantalla;
begin
  Result := FComposicion.CrearRepositoriosTicketsCajaPantalla(
    ANombrePantalla);
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
end;

procedure TfrmMtoPrincipal.MostrarSplashInicio;
begin
  FSplashInicio := nil;
  FSplashTimestamp := Now;
  try
    FSplashInicio := TfrmSplash.Create(nil, RegistroLog);
    TfrmSplash(FSplashInicio).FormStyle := fsStayOnTop;
    TfrmSplash(FSplashInicio).btnAceptar.Visible := False;
    TfrmSplash(FSplashInicio).Show;
    Application.ProcessMessages;
  except
    // Si el splash falla por lo que sea, no rompemos el arranque.
    FreeAndNil(FSplashInicio);
  end;
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
  if FSplashInicio is TfrmSplash then
    Traducciones.Aplicar(TfrmSplash(FSplashInicio));
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

function TfrmMtoPrincipal.CrearStockConsultaInyectada(
  AOwner: TComponent): TForm;
var
  Articulos: IRepositoriosArticulosPantalla;
  Dependencias: TContextoDependenciasStockConsulta;
  Documentos: IRepositoriosDocumentosPantalla;
  EsOwnerAplicacion: Boolean;
  Formulario: TfrmStockConsulta;
  OwnerCreacion: TComponent;
begin
  EsOwnerAplicacion := AOwner = Application;
  OwnerCreacion := AOwner;
  if not Assigned(OwnerCreacion) or EsOwnerAplicacion then
    OwnerCreacion := Self;
  Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
    NOMBRE_PANTALLA_STOCK_CONSULTA);
  Documentos := FComposicion.CrearRepositoriosDocumentosPantalla(
    NOMBRE_PANTALLA_STOCK_CONSULTA);
  Dependencias := CrearContextoStockConsulta(
    Articulos,
    Documentos,
    ConexionPrincipal);
  Formulario := TfrmStockConsultaInyectada.Create(
    OwnerCreacion,
    TContextoAutorizacionPantalla.Crear(Permisos),
    Dependencias);
  if EsOwnerAplicacion then
  begin
    Self.RemoveComponent(Formulario);
    Application.InsertComponent(Formulario);
  end;
  Result := Formulario;
end;

procedure TfrmMtoPrincipal.RegistrarFabricasPantallas;
begin
  RegistrarFabricaPantalla(
    TfrmStockConsulta,
    function(AOwner: TComponent): TForm
    begin
      Result := CrearStockConsultaInyectada(AOwner);
    end);
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
  AplicarTituloVentana;
end;

procedure TfrmMtoPrincipal.AplicarTema;
var
  sPaleta, sTema: string;
begin
  if Assigned(LookAndFeelController1) and
     Assigned(dxSkinController1) then
  begin
    try
      sTema := ParametrosApp.GetString('appTema');
      if sTema = '' then
      begin
        if DarkModeIsEnabled then
          sTema := 'MetropolisDark'
        else
          sTema := 'Office2007Pink';
      end;
      LookAndFeelController1.SkinName := sTema;
      dxSkinController1.SkinName := sTema;
      sPaleta := ParametrosApp.GetString('appPaleta');
      if sPaleta <> '' then
        TcxRootLookAndFeel.Instance.SkinPaletteName := sPaleta;
    except
      on E: Exception do
        RegistroLog.RegistrarAviso(
          'Error al establecer skin: ' + E.Message);
    end;
  end;
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
  AplicarTema;
  CargarFondoLogo;
  // pcPrincipal tiene Align=alClient en Panel1 y repinta su area cliente
  // encima de cualquier hermano. Reparentamos imgFondoLogo al propio
  // pcPrincipal: queda como hijo directo del PageControl (no en una
  // TabSheet), asi se pinta sobre su area cliente cuando no hay pestanas
  // y queda tapado automaticamente por el TcxTabSheet activo cuando si
  // las hay (sin invadir zonas fuera del PageControl).
  imgFondoLogo.Parent := pcPrincipal;
  imgFondoLogo.Anchors := [akTop, akRight];
  imgFondoLogo.Left := pcPrincipal.ClientWidth - imgFondoLogo.Width - 16;
  imgFondoLogo.Top := 16;
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
end;

procedure TfrmMtoPrincipal.RegistrarInicioAplicacion;
begin
  FComposicion.RegistrarInicioFiscal;
end;

procedure TfrmMtoPrincipal.InicializarAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
var
  IdentidadActual: TIdentidadSesion;
  UbicacionActual: TUbicacionSesion;
begin
  PrepararContextoAplicacion(
    AContextoSesion, IdentidadActual, UbicacionActual);
  MostrarSplashInicio;
  CrearInfraestructuraAplicacion;
  CrearParametrosSesion(AResultadoLicencia);
  CrearServiciosSesion;
  ComprobarConfiguracionFiscal;
  CargarDatosArranque;
  RegistrarFabricasPantallas;
  IniciarProcesosSegundoPlano;
  ActualizarEstadoSesion(IdentidadActual, UbicacionActual);
  ConfigurarPresentacionPrincipal;
  RegistrarInicioAplicacion;
  CerrarSplashInicio(1000);
  MostrarAvisoCaducidadCertificado;
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
  oVer.Caption := Format(SCaptionVersion, [oVersion]);
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
  if imgFondoLogo <> nil then
  begin
    // Trabajamos sobre el cliente real de pcPrincipal
    cw := pcPrincipal.ClientWidth;
    ch := pcPrincipal.ClientHeight;
    // Logo: ~33% del ancho, max 380, min 180, manteniendo aspect 520x130.
    w := cw div 3;
    if w > 380 then
      w := 380;
    if w < 180 then
      w := 180;
    h := Round(w * 130 / 520);
    cx := (cw - w) div 2;
    cy := (ch - h - 80) div 2;
    if cy < 20 then
      cy := 20;
    imgFondoLogo.Anchors := [];
    imgFondoLogo.SetBounds(cx, cy, w, h);
    if FLogoBgNombre <> nil then
      TcxLabel(FLogoBgNombre).SetBounds(0, cy + h + 8, cw, 26);
    if FLogoBgVersion <> nil then
      TcxLabel(FLogoBgVersion).SetBounds(0, cy + h + 38, cw, 20);
  end;
end;

procedure TfrmMtoPrincipal.FormResize(Sender: TObject);
begin
  CentrarLogoFondoBg;
end;

procedure TfrmMtoPrincipal.CerrarSplashInicio(aMinimoMs: Integer);
var
  iElapsedMs, iEsperaMs: Integer;
begin
  if FSplashInicio <> nil then
  begin
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
      on E: Exception do
        RegistroLog.RegistrarAviso(
          'Principal: cierre del splash de inicio fallo: ' + E.Message);
    end;
    FreeAndNil(FSplashInicio);
  end;
end;

// El Picture.Data del .dfm trae un envoltorio TdxSmartImage que el TImage
// de VCL no sabe deserializar (queda vacio al cargar el form). Cargamos
// fondo.png desde un recurso RCDATA incrustado en el .exe (ver fondo.rc
// + directiva $R en fzam.dpr) para no depender de archivos en disco.
procedure TfrmMtoPrincipal.CargarFondoLogo;
const
  // Rutas relativas al .exe donde buscar fondo.png si no hay recurso
  CRutas: array[0..1] of string = ('fondo.png', '..\..\fondo.png');
var
  sBase, sRuta: string;
  i: Integer;
  oRes: TResourceStream;
  oPng: TPngImage;
  Cargado: Boolean;
begin
  // 1) Recurso RCDATA 'FONDO' embebido en el .exe via {$R fondo.res} en
  //    fzam.dpr. Es el camino preferente porque no depende de tener el
  //    fichero al lado del .exe. Si el recurso no esta presente (porque
  //    se compilo sin fondo.res) caemos a las rutas relativas de disco.
  Cargado := False;
  try
    oRes := TResourceStream.Create(HInstance, 'FONDO', RT_RCDATA);
    try
      oPng := TPngImage.Create;
      try
        oPng.LoadFromStream(oRes);
        imgFondoLogo.Picture.Assign(oPng);
        RegistroLog.RegistrarInformacion(
          'CargarFondoLogo: OK desde recurso FONDO ' +
                             '(' + IntToStr(oRes.Size) + ' bytes)');
        Cargado := True;
      finally
        oPng.Free;
      end;
    finally
      oRes.Free;
    end;
  except
    on E: Exception do
      RegistroLog.RegistrarInformacion(
        'CargarFondoLogo: recurso FONDO no disponible ' +
                           '(' + E.Message + '); pruebo disco');
  end;
  // 2) Fallback a fichero suelto: para builds Debug donde fondo.png
  //    vive en la raiz del repo (..\..ondo.png desde Win32/Debug).
  if not Cargado then
  begin
    sBase := inLibDir.DirApp;
    RegistroLog.RegistrarInformacion(
      'CargarFondoLogo: base="' + sBase + '"');
    i := 0;
    while (i <= High(CRutas)) and not Cargado do
    begin
      sRuta := sBase + CRutas[i];
      if FileExists(sRuta) then
      begin
        try
          imgFondoLogo.Picture.LoadFromFile(sRuta);
          Cargado := True;
          RegistroLog.RegistrarInformacion(
            'CargarFondoLogo: OK desde "' + sRuta + '"');
        except
          on E: Exception do
            RegistroLog.RegistrarAviso(
              'No se pudo cargar fondo ' + sRuta + ': ' + E.Message);
        end;
      end
      else
        RegistroLog.RegistrarInformacion(
          'CargarFondoLogo: no existe "' + sRuta + '"');
      Inc(i);
    end;
  end;
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
  RetirarFabricaPantalla(TfrmStockConsulta);
  FCoordinadorOperaciones := nil;
  FGestorExcepciones := nil;
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
    DesvincularPerfilesStockConsulta;
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
    ActualizarFondoLogo;
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

function TfrmMtoPrincipal.IsShortCut(var Message: TWMKey): Boolean;
var
  Component: TComponent;
  ActiveForm: TCustomForm;
  ts: TcxTabSheet;
  I: Integer;
  iPageActive: Integer;
  bFound: Boolean;
begin
  Result := False;
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
    // Ventana flotante (no modal): cerrarla
    if Assigned(Screen.ActiveForm) and
       (Screen.ActiveForm <> Self) and
       (Screen.ActiveForm.Parent = nil) then
      Screen.ActiveForm.Close
    else if pcPrincipal.PageCount > 0 then
      FormManager.CloseActiveForm;
    Result := True;
  end
  // ESC -> cerrar pestaña activa o salir
  else if Message.CharCode = VK_ESCAPE then
  begin
    if Application.ModalLevel > 0 then
      Result := inherited IsShortCut(Message)
    else if Assigned(Screen.ActiveForm) and
            (Screen.ActiveForm <> Self) and
            (Screen.ActiveForm.Parent = nil) then
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
  else
  begin
    // Ventana no embebida: delegar a sus ActionLists
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
    end;
    if not (Assigned(ActiveForm) and
            (ActiveForm <> Self) and
            (ActiveForm.Parent = nil)) then
    begin
      // Enrutar a los ActionList del formulario hijo de la pestaña activa
      bFound := False;
      if Self.pcPrincipal.PageCount > 0 then
      begin
        iPageActive := pcPrincipal.ActivePageIndex;
        if iPageActive >= 0 then
        begin
          ts := Self.pcPrincipal.Pages[iPageActive] as TcxTabSheet;
          if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
          begin
            for I := 0 to (ts.Controls[0] as TForm).ComponentCount - 1 do
            begin
              Component := (ts.Controls[0] as TForm).Components[I];
              if Component is TActionList then
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
var
  frmListadoVentas: TfrmModalListadoVentas;
begin
  inherited;
  try
    frmListadoVentas := TfrmModalListadoVentas.Create(Self);
    frmListadoVentas.ShowModal;
  finally
    FreeAndNil(frmListadoVentas);
  end;
end;

procedure TfrmMtoPrincipal.mnuListadoDocsProveedorClick(Sender: TObject);
var
  frmListadoDocsProveedor: TfrmPrintDocsProveedor;
begin
  inherited;
  try
    frmListadoDocsProveedor := TfrmPrintDocsProveedor.Create(Self);
    frmListadoDocsProveedor.ShowModal;
  finally
    FreeAndNil(frmListadoDocsProveedor);
  end;
end;

procedure TfrmMtoPrincipal.mnuListadoEfectosPagoClick(Sender: TObject);
var
  frmListadoEfectosPago: TfrmPrintEfectosPago;
begin
  inherited;
  try
    frmListadoEfectosPago := TfrmPrintEfectosPago.Create(Self);
    frmListadoEfectosPago.ShowModal;
  finally
    FreeAndNil(frmListadoEfectosPago);
  end;
end;

procedure TfrmMtoPrincipal.mnuMenuCajaClick(Sender: TObject);
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    MostrarMenuCaja(Permisos);
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
var
  frmSplash: TfrmSplash;
begin
  inherited;
  try
    frmSplash := TfrmSplash.Create(Self, RegistroLog);
    frmSplash.ShowModal;
  finally
    FreeAndNil(frmSplash);
  end;
end;

procedure TfrmMtoPrincipal.mnuForoSoporteClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(URL_FORO_SOPORTE);
end;

procedure TfrmMtoPrincipal.mnuConsultaStocksClick(Sender: TObject);
var
  LForm: TForm;
  ts: TcxTabSheet;
  sArt, sSku: string;
begin
  if mnuConsultaStocks.Enabled then
  begin
    // Si el principal esta activo, el form logico es el de la pestaña activa.
    LForm := Screen.ActiveForm;
    if (LForm = Self) and (pcPrincipal.PageCount > 0) and
       (pcPrincipal.ActivePageIndex >= 0) then
    begin
      ts := pcPrincipal.Pages[pcPrincipal.ActivePageIndex] as TcxTabSheet;
      if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
      begin
        LForm := TForm(ts.Controls[0]);
      end;
    end;
    sArt := '';
    sSku := '';
    if LForm is TfrmBase then
    begin
      TfrmBase(LForm).ResolverArtSkuStock(sArt, sSku);
    end;
    MostrarStockConsulta(sArt, sSku);
  end;
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
      TfrmMtoBusquedaDatos.Ejecutar(Self, LForm);
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
    TfrmModalProcesosAuxiliaresBBDD.Ejecutar(Self);
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

procedure TfrmMtoPrincipal.mnuListadoOperacionesVentaClick(
  Sender: TObject);
var
  frmListado: TfrmPrintOperacionesVenta;
begin
  inherited;
  if mnuListadoOperacionesVenta.Visible then
  begin
    frmListado := TfrmPrintOperacionesVenta.Create(Self);
    try
      frmListado.ShowModal;
    finally
      FreeAndNil(frmListado);
    end;
  end;
end;

procedure TfrmMtoPrincipal.CargarEfectosVenta1Click(Sender: TObject);
var
  f: TfrmModalCargarEfectosRemesa;
begin
  inherited;
  if CargarEfectosVenta1.Visible then
  begin
    f := TfrmModalCargarEfectosRemesa.CrearParaVenta(nil);
    try
      if f.ShowModal = mrOk then
        ShowMto(Self, 'RemesasVenta');
    finally
      f.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.Sesiones1Click(Sender: TObject);
begin
  inherited;
  if mnuCrearArtculosyunpedidoounalbarn.Visible then
    ShowMto(Self, 'ComprasSesiones');
end;

procedure TfrmMtoPrincipal.FacturarAlbaranes1Click(Sender: TObject);
var
  f: TfrmModalFacturarAlbaranes;
begin
  inherited;
  if FacturarAlbaranes1.Visible then
  begin
    f := TfrmModalFacturarAlbaranes.Create(nil);
    try
      if f.ShowModal = mrOk then
        ShowMto(Self, 'FacturasCompra');
    finally
      f.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.CargarEfectos1Click(Sender: TObject);
var
  f: TfrmModalCargarEfectosRemesa;
begin
  inherited;
  if CargarEfectos1.Visible then
  begin
    f := TfrmModalCargarEfectosRemesa.CrearParaCompra(nil);
    try
      if f.ShowModal = mrOk then
        ShowMto(Self, 'RemesasCompra');
    finally
      f.Free;
    end;
  end;
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

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVerifactuDeclaracionClick(Sender: TObject);
begin
  if (mnuVerifactuDeclaracion.Visible) then
    TfrmModalVerifactuDecl.Ejecutar(Self);
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

procedure TfrmMtoPrincipal.mnuMovVentasArtClick(Sender: TObject);
var
  frm: TfrmPrintMovVentasArt;
begin
  // Informe A4 horizontal (FastReport) del ranking de ventas por artículos y
  // fechas: una fila por artículo (o por artículo+almacén si se agrupa por
  // almacén) con las magnitudes de compra/venta del periodo y dos márgenes.
  // Mismos filtros que el balance más la fecha "Inicio compras".
  if mnuMovVentasArt.Visible then
  begin
    frm := TfrmPrintMovVentasArt.Create(Application);
    try
      frm.ShowModal;
    finally
      FreeAndNil(frm);
    end;
  end;
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
  ActualizarFondoLogo;
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
var
  oFormulario: TfrmMtoOpeCaja;
begin
  oFormulario := TfrmMtoOpeCaja.Create(AOwner, APermisos);
  if not Supports(oFormulario, IOperacionCaja, Result) then
  begin
    FreeAndNil(oFormulario);
    raise EInvalidCast.Create(
      'La ventana de operación no implementa IOperacionCaja.');
  end;
end;

function TfrmMtoPrincipal.CrearConsultaOperacionesCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
var
  oFormulario: TfrmConsultaOpe;
begin
  oFormulario := TfrmConsultaOpe.Create(AOwner, APermisos);
  if not Supports(oFormulario, IConsultaOperacionesCaja, Result) then
  begin
    FreeAndNil(oFormulario);
    raise EInvalidCast.Create(
      'La ventana de consulta no implementa IConsultaOperacionesCaja.');
  end;
end;

function TfrmMtoPrincipal.CrearTraspasoCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): ITraspasoCaja;
begin
  Result := TfrmMtoOpeTraspaso.Create(AOwner, APermisos);
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
