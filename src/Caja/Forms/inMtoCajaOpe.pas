{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOpe                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de caja: introduccion de lineas de venta.                       }
{    Captura articulos, atributos y descuentos del ticket actual.              }
{******************************************************************************}
unit inMtoCajaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inMtoGenSearch, system.Math, inMtoFrmBase,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxCoreGraphics, cxTextEdit,
  cxMaskEdit, cxButtonEdit, Vcl.ExtCtrls, cxLabel, Vcl.Menus, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, Data.FmtBcd, Data.SqlTimSt, cxDBData,
  cxClasses, cxGridCustomTableView, system.types,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, UniDataCaja,
  JvComponentBase, JvEnterTab, cxDropDownEdit, cxFontNameComboBox, Uni,
  cxCurrencyEdit, cxSpinEdit, cxSplitter, cxDBLookupComboBox,
  cxDBExtLookupComboBox, MemDS, DBAccess, cxEditRepositoryItems, system.UITypes,
  System.Actions, Vcl.ActnList, Vcl.Imaging.PngImage, inLibFotos,
  System.Generics.Collections, cxLocalization,
  inLibLectorScanner, inLibCajaTipos, inLibCajaVentanasIntf,
  inLibCajaVentaIntf, inLibCatalogoSqlIntf,
  inLibFacturasLecturasIntf, inLibCajaEntradaIntf,
  inLibCajaOpePresentacionIntf, inMtoCajaOpePresentacionVcl,
  inLibParametrosIntf, inLibLogIntf, inLibGenBusq,
  inLibPermisosIntf, inLibArticulosValidadorIntf,
  inLibArticulosResolverIntf, inLibArticulosAtributosIntf,
  inLibCajaPantallaInyeccion, inMtoCajaEditorLineasBusqueda,
  inMtoCajaEditorLineasInteraccion, inMtoCajaEditorLineasRender,
  inMtoCajaEditorAtributosVcl, inMtoCajaOpeVentanaVcl;

const
  WM_CANCELAR_LINEA = WM_APP + 100;
  WM_SALTAR_ATRIBUTO = WM_APP + 101;
  // Diferimos FinalizarUltimoAtributo / avance de columna fuera del
  // OnButtonClick del TcxButtonEdit. Si los ejecutamos en linea, cxGrid
  // sigue manteniendo referencia al editor inplace que acaba de procesar
  // el popup; cuando FinalizarUltimoAtributo lanza el ShowMessage de
  // "no hay stock" y luego dispara DataChange via EnableControls/Append,
  // el editor inplace se desparenta y salta EInvalidOperation. Con
  // PostMessage el click handler retorna, cxGrid limpia su estado y
  // luego procesamos.
  WM_FINALIZAR_ATRIB_CAJA = WM_APP + 102;
  WM_AVANZAR_ATRIB_CAJA   = WM_APP + 103;
  // Diferimos tambien la apertura del popup desde el OnEnter del
  // TcxButtonEdit. Cuando WMAvanzarAtribCaja salta de Color a Talla,
  // ShowEdit -> InitEdit -> OnEnter ocurren en cadena en el mismo
  // callstack; el editor inplace de la talla aun no esta del todo
  // colocado y ClientToScreen pide Handle -> Parent -> EInvalidOperation.
  // Con PostMessage, OnEnter retorna, cxGrid termina de parentar, y solo
  // entonces abrimos el popup.
  WM_ABRIR_POPUP_AV       = WM_APP + 104;
  // El grid termina de crear la fila después del cambio de dataset. El foco
  // se aplica en un mensaje posterior para que no restaure la columna previa.
  WM_ENFOCAR_ARTICULO_CAJA = WM_APP + 105;
  // Devolución sin código: al validar una cantidad negativa se difiere el
  // selector de venta de origen (modal) fuera del OnValidate del editor,
  // por las mismas razones que los mensajes de atributos de arriba.
  WM_PREGUNTAR_VENTA_ORIGEN = WM_APP + 106;
type
  TServiciosLecturaOperacionCaja = record
    ConsultaStock: IResultadoConsultaCaja;
    RepositorioFacturas: IRepositorioLecturasFactura;
  end;
  TEntradaOperacionCaja = record
    Lector: TLectorScanner;
    Aplicacion: IAplicacionEntradaCaja;
    ResolviendoPorScanner: Boolean;
    ProcesandoLectura: Boolean;
  end;
  // Entrada por teclado de la línea: el adaptador de rejilla vive
  // mientras lo sostenga el procesador, que es quien guarda la
  // referencia de interfaz.
  TTecladoLineaOperacionCaja = record
    Rejilla: TRejillaLineaCajaVcl;
    Procesador: IProcesadorTeclaLineaCaja;
  end;
  TActualizarTotalCajaVcl = reference to procedure(
    Sender: TObject;
    ANuevoTotal: Currency);
  TControlesEditorLineasCajaVcl = record
    Formulario: TCustomForm;
    Rejilla: TcxGrid;
    VistaLineas: TcxGridDBTableView;
    ColumnaArticulo: TcxGridDBColumn;
    ColumnaDescripcion: TcxGridDBColumn;
    ColumnaUnidades: TcxGridDBColumn;
    ColumnaDescuento: TcxGridDBColumn;
    ColumnaDescuentoMenos: TcxGridDBColumn;
    FuenteLineas: TDataSource;
    FuenteStock: TDataSource;
    FuenteBusqueda: TDataSource;
    VistaStock: TcxGridDBTableView;
    VistaBusqueda: TcxGridDBTableView;
    RepositorioSoloTexto: TcxEditRepositoryTextItem;
    RepositorioCombo: TcxEditRepositoryExtLookupComboBoxItem;
    TemporizadorBusqueda: TTimer;
    NavegacionEnter: TJvEnterAsTab;
    BotonBuscar: TcxButton;
    BotonEliminar: TcxButton;
    ImagenStock: TImage;
  end;
  TServiciosEditorLineasCajaVcl = record
    DatosCaja: TdmCajaOpe;
    Conexion: TUniConnection;
    ParametrosCaja: IParametrosCaja;
    ValidadorArticulos: IArticulosValidador;
    ResolverArticulos: IArticulosResolver;
    AtributosArticulos: IArticulosAtributosLookup;
    Dependencias: TContextoDependenciasOperacionCaja;
    RepositorioArticulos: IRepositorioArticulosCaja;
    RepositorioFacturas: IRepositorioLecturasFactura;
    BusquedaVisual: IBusquedaVisual;
    FotosArticulos: TFotosArticulos;
    RegistroLog: IRegistroLog;
    ActualizarTotal: TActualizarTotalCajaVcl;
    CerrarFormulario: TAccionCajaVcl;
    ResolviendoPorScanner: TConsultaBooleanaCajaVcl;
    LectorLeyendoTrama: TConsultaBooleanaCajaVcl;
    ObtenerAlmacen: TConsultaTextoCajaVcl;
  end;
  TEditorLineasCajaVcl = class
  private
    FControles: TControlesEditorLineasCajaVcl;
    FDatosCaja: TdmCajaOpe;
    FConexionPrincipal: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    FValidadorArticulos: IArticulosValidador;
    FResolverArticulos: IArticulosResolver;
    FAtributosArticulos: IArticulosAtributosLookup;
    FDependencias: TContextoDependenciasOperacionCaja;
    FRepositorioArticulos: IRepositorioArticulosCaja;
    FRepositorioFacturas: IRepositorioLecturasFactura;
    FRegistroLog: IRegistroLog;
    FActualizarTotal: TActualizarTotalCajaVcl;
    FCerrarFormulario: TAccionCajaVcl;
    FResolviendoPorScanner: TConsultaBooleanaCajaVcl;
    FLectorLeyendoTrama: TConsultaBooleanaCajaVcl;
    FObtenerAlmacen: TConsultaTextoCajaVcl;
    FResultadoBusquedaIncremental: IResultadoConsultaCaja;
    FBusqueda: TBusquedaEditorLineasCajaVcl;
    FInteraccion: TInteraccionEditorLineasCajaVcl;
    FRender: TRenderEditorLineasCajaVcl;
    FSelectorAtributos: TSelectorAtributosEditorLineasCajaVcl;
    FTecladoLinea: TTecladoLineaOperacionCaja;
    FBmpSwatchBoton: TBitmap;
    FNumAtributosActual: Integer;
    FUltimoArticuloPadre: string;
    FActualizandoDepositos: Boolean;
    FMotivoRechazoArticulo: string;
    FArticuloResueltoEdicion: string;
    FConservoImportesUltimaPreparacion: Boolean;
    FEnfoqueArticuloPendiente: Boolean;
    function GetFormulario: TCustomForm;
    function GetRejilla: TcxGrid;
    function GetVistaLineas: TcxGridDBTableView;
    function GetColumnaArticulo: TcxGridDBColumn;
    function GetColumnaDescripcion: TcxGridDBColumn;
    function GetColumnaUnidades: TcxGridDBColumn;
    function GetColumnaDescuento: TcxGridDBColumn;
    function GetColumnaDescuentoMenos: TcxGridDBColumn;
    function GetFuenteLineas: TDataSource;
    function GetFuenteBusqueda: TDataSource;
    function GetTemporizadorBusqueda: TTimer;
    function GetNavegacionEnter: TJvEnterAsTab;
    function GetBotonBuscar: TcxButton;
    function GetBotonEliminar: TcxButton;
    function ObtenerResolviendoPorScanner: Boolean;
    procedure ActualizarLabelTotal(Sender: TObject;
      ANuevoTotal: Currency);
    procedure InicializarTecladoLineaCaja;
    procedure SolicitarFocoArticuloLineaNueva;
    procedure RefrescarFotoStock;
    function ObtenerColumnaPorTag(
      ANumeroColumna: Integer): TcxGridDBColumn;
    property Formulario: TCustomForm read GetFormulario;
    property tvLineasOpe: TcxGridDBTableView read GetVistaLineas;
    property tvArticulo: TcxGridDBColumn read GetColumnaArticulo;
    property tvDescripcion: TcxGridDBColumn read GetColumnaDescripcion;
    property tvUds: TcxGridDBColumn read GetColumnaUnidades;
    property tvDescuento: TcxGridDBColumn read GetColumnaDescuento;
    property tvDescuentoMenos: TcxGridDBColumn
      read GetColumnaDescuentoMenos;
    property cxgrdLineasOpe: TcxGrid read GetRejilla;
    property dsLineas: TDataSource read GetFuenteLineas;
    property dsBusq: TDataSource read GetFuenteBusqueda;
    property tmrBusq: TTimer read GetTemporizadorBusqueda;
    property jvEnterTab: TJvEnterAsTab read GetNavegacionEnter;
    property btnF3: TcxButton read GetBotonBuscar;
    property btnF8: TcxButton read GetBotonEliminar;
    property DatosCaja: TdmCajaOpe read FDatosCaja;
    property ConexionPrincipal: TUniConnection read FConexionPrincipal;
    property ParametrosCaja: IParametrosCaja read FParametrosCaja;
  public
    constructor Create(
      const AControles: TControlesEditorLineasCajaVcl;
      const AServicios: TServiciosEditorLineasCajaVcl);
    destructor Destroy; override;
    procedure Inicializar;
    procedure ConsultarStock(const ACodigo: string);
    procedure DibujarCeldaLinea(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure DibujarCeldaStock(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    function ValidarSkuParaVenta(const ASku: string): Boolean;
    procedure CancelarLinea;
    procedure EjecutarBusquedaIncremental(Sender: TObject);
    procedure ObtenerPropiedadesArticulo(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure CambiarArticulo(Sender: TObject);
    procedure CerrarBusquedaArticulo(Sender: TObject);
    function BuscarArticulo: string;
    procedure ValidarArticulo(Sender: TObject;
      var DisplayValue: Variant;
      var ErrorText: TCaption;
      var Error: Boolean);
    procedure CambiarDescuentoMenos(Sender: TObject);
    procedure CambiarDescuento(Sender: TObject);
    procedure CambiarPrecioUnitario(Sender: TObject);
    procedure CambiarTotal(Sender: TObject);
    procedure CambiarUnidades(Sender: TObject);
    function RellenarDatosArticuloEnDataset(
      ACodigo: string): Boolean;
    procedure InicializarPopupBusqueda(Sender: TObject);
    procedure RecalcularPrecioDesdeSku(const ASku: string);
    procedure RellenarAtributosDesdeSku(ASku: string);
    function ConsolidarSiExiste(const ASku: string): Boolean;
    procedure ConstruirColumnasDinamicas;
    procedure PoblarAtributosLineasDeposito;
    procedure MostrarColumnasCuentaCliente(AActivar: Boolean);
    procedure ComprobarFocoRegistro(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; var AAllow: Boolean);
    procedure ComprobarEdicion(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure ProcesarTeclaEdicion(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var AKey: Word; AShift: TShiftState);
    procedure CambiarRegistroEnfocado(Sender: TcxCustomGridTableView;
      ARegistroAnterior, ARegistroActual: TcxCustomGridRecord;
      ACambiaRegistroNuevo: Boolean);
    procedure InicializarEdicion(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure ProcesarTeclaRejilla(Sender: TObject;
      var AKey: Word; AShift: TShiftState);
    procedure PulsarRejilla(Sender: TObject; AButton: TMouseButton;
      AShift: TShiftState; AX, AY: Integer);
    procedure EntrarRejilla(Sender: TObject);
    procedure SalirRejilla(Sender: TObject);
    procedure ActualizarColumnasDinamicas(const AArticulo: string);
    procedure RecalcularLineas;
    procedure AsegurarLineaNueva;
    procedure NotificarCambioLinea(Sender: TObject; AField: TField);
    procedure EnfocarArticulo;
    procedure AbrirPopupAtributo;
    procedure SeleccionarAtributo(Sender: TObject;
      AButtonIndex: Integer);
    procedure FinalizarAtributos;
    procedure AvanzarAtributo(ANumeroColumna: Integer);
    property ActualizandoDepositos: Boolean
      read FActualizandoDepositos write FActualizandoDepositos;
    property NumeroAtributosActual: Integer read FNumAtributosActual;
    property MotivoRechazoArticulo: string read FMotivoRechazoArticulo;
    property ArticuloResueltoEdicion: string
      read FArticuloResueltoEdicion;
  end;
  TfrmMtoOpeCaja = class(TfrmBase, IOperacionCaja)
    pnlUp: TPanel;
    pnlCli: TPanel;
    lblFecha: TcxLabel;
    pnlAccionesIzq: TPanel;
    btnF12: TcxButton;
    btnF3: TcxButton;
    btnF6: TcxButton;
    btnF5: TcxButton;
    btnF7: TcxButton;
    lblCobro: TcxLabel;
    lblBuscar: TcxLabel;
    lblTextoTarifa: TcxLabel;
    lblIndIVA: TcxLabel;
    lblOtro: TcxLabel;
    pnlAccionesDer: TPanel;
    cxgrdLineasOpe: TcxGrid;
    tvLineasOpe: TcxGridDBTableView;
    cxgrdlvlLineasOpe: TcxGridLevel;
    tvEmpleado: TcxGridDBColumn;
    tvArticulo: TcxGridDBColumn;
    tvDescripcion: TcxGridDBColumn;
    tvUds: TcxGridDBColumn;
    tvTipoCantidad: TcxGridDBColumn;
    tvPrecioUni: TcxGridDBColumn;
    tvDescuento: TcxGridDBColumn;
    tvDescuentoMenos: TcxGridDBColumn;
    tvTotal: TcxGridDBColumn;
    tvFechaOperacion: TcxGridDBColumn;
    lblTotal: TcxLabel;
    btnF8: TcxButton;
    lblEliminar: TcxLabel;
    lblNombreEmpleado: TcxLabel;
    lblCliente: TcxLabel;
    btnCodigoCliente: TcxButtonEdit;
    lblNombreCliente: TcxLabel;
    tmrReloj: TTimer;
    dsLineas: TDataSource;
    jvEnterTab: TJvEnterAsTab;
    lblFechaCaja: TcxLabel;
    btnCodigoEmpleado: TcxButtonEdit;
    lblTarifa: TcxLabel;
    lblInstrucciones: TcxLabel;
    lblTipoRectificativa: TcxLabel;
    pnlBusqueda: TPanel;
    cxgrdStock: TcxGrid;
    dbtvStock: TcxGridDBTableView;
    cxgrdlvlBusqueda: TcxGridLevel;
    dsStock: TDataSource;
    pnlFotoStock: TPanel;
    imgFotoStock: TImage;
    splFotoStock: TcxSplitter;
    splOpe: TcxSplitter;
    cxstylrpstry: TcxStyleRepository;
    styPrincipal: TcxStyle;
    styImporte: TcxStyle;
    tmrBusq: TTimer;
    dsBusq: TDataSource;
    tvrBusq: TcxGridViewRepository;
    dbtvBusq: TcxGridDBTableView;
    styCabecera: TcxStyle;
    dbtvBusqINPUT_BUSQUEDA: TcxGridDBColumn;
    dbtvBusqCODIGO_ARTICULO: TcxGridDBColumn;
    dbtvBusqDESCRIPCION_ARTICULO: TcxGridDBColumn;
    dbtvBusqTEMPORADA: TcxGridDBColumn;
    dbtvBusqPROVEEDOR: TcxGridDBColumn;
    dbtvBusqREF_PROVEEDOR: TcxGridDBColumn;
    edtrepArticulo: TcxEditRepository;
    repSoloTexto: TcxEditRepositoryTextItem;
    repComboBox: TcxEditRepositoryExtLookupComboBoxItem;
    btnF61: TcxButton;
    lblBusqTick: TcxLabel;
    alCajaOpe: TActionList;
    actBuscarEmpleados: TAction;
    actSalir: TAction;
    actEliminarLinea: TAction;
    actCobro: TAction;
    btnF2: TcxButton;
    lblCargarCta: TcxLabel;
    actCargarCta: TAction;
    btnF10: TcxButton;
    lblBuscarModificar: TcxLabel;
    actBuscarModificar: TAction;
    actGuardarLayout: TAction;
    actAbrirArticulos: TAction;
    actConsultaStock: TAction;
    pnlTotal: TPanel;
    pnlBotones: TPanel;
    procedure actAbrirArticulosExecute(Sender: TObject);
    procedure actConsultaStockExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnF5Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClientePropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure cxGrid1Enter(Sender: TObject);
    procedure tvArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClienteExit(Sender: TObject);
    procedure btnCodigoEmpleadoExit(Sender: TObject);
    procedure cxGrid1DBTableView1InitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure cxGrid1DBTableView1EditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
      Shift: TShiftState);
    procedure cxGrid1Exit(Sender: TObject);
    procedure tvUdsPropertiesEditValueChanged(Sender: TObject);
    procedure tvDescuentoPropertiesEditValueChanged(Sender: TObject);
    procedure tvDescuentoMenosPropertiesEditValueChanged(Sender: TObject);
    procedure tvPrecioUniPropertiesEditValueChanged(Sender: TObject);
    procedure cxGrid1DBTableView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tmrBusqTimer(Sender: TObject);
    procedure tvArticuloGetProperties(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AProperties: TcxCustomEditProperties);
    procedure repComboBoxPropertiesInitPopup(Sender: TObject);
    procedure tvArticuloPropertiesCloseUp(Sender: TObject);
    procedure cxGrid1DBTableView1CanFocusRecord(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; var AAllow: Boolean);
    procedure tvTotalPropertiesEditValueChanged(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnCodigoClientePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure actBuscarEmpleadosExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure actEliminarLineaExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tvArticuloPropertiesChange(Sender: TObject);
    procedure cxGrid1DBTableView1Editing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvUdsPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure cxGrid1DBTableView1MouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnF2Click(Sender: TObject);
    procedure btnF7Click(Sender: TObject);
    procedure actCargarCtaExecute(Sender: TObject);
    procedure btnF10Click(Sender: TObject);
    procedure btnF61Click(Sender: TObject);
    procedure actBuscarModificarExecute(Sender: TObject);
    procedure cxGrid1DBTableView1FocusedRecordChanged(
      Sender: TcxCustomGridTableView; APrevFocusedRecord,
      AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure actGuardarLayoutExecute(Sender: TObject);
    procedure tvLineasOpeCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure dbtvStockCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    // Modo rectificación: ticket original que se rectifica (lo carga
    // CargarRectificacion desde Buscar operaciones)
    FSerieRectifica:  string;
    FNumeroRectifica: string;
    FTipoRectificativa: TTipoRectificativaCaja;
    FTratamientoMovRectificativa:
      TTratamientoMovimientosRectificativa;
    FCaptionPrevio:   string;
    FDependencias: TContextoDependenciasOperacionCaja;
    FLecturas: TServiciosLecturaOperacionCaja;
    FIncidenciasSql: IRegistroIncidenciasSql;
    FDependenciasPantalla: TDependenciasOperacionCaja;
    // Devoluciones: motivo (se pide al cobrar si hay líneas en negativo)
    // y ticket de origen (F4 o selector de venta sin código). Si el
    // origen es de otra tienda, la grabación genera el traspaso
    // automático hacia el almacén actual.
    FMotivoDevolucion: string;
    FSerieOrigenDev: string;
    FNumeroOrigenDev: string;
    FEmpresaOrigenDev: string;
    FAlmacenOrigenDev: string;
    FSkuPendienteVentaOrigen: string;
    FPreguntandoVentaOrigen: Boolean;
    FEditorLineas: TEditorLineasCajaVcl;
    FPresentacion: TVentanaOperacionCajaVcl;
    procedure CargarDevolucionPorTicket;
    procedure WMPreguntarVentaOrigen(var Msg: TMessage);
                                       message WM_PREGUNTAR_VENTA_ORIGEN;
    function PedirMotivoDevolucionSiProcede: Boolean;
    procedure CargarDepositosF2;
    procedure WMCancelarLinea(var Msg: TMessage); message WM_CANCELAR_LINEA;
    procedure ActualizarLabelTotal(Sender: TObject; NuevoTotal: Currency);
    procedure ProcesarResultadoCierre(
      const AResultado: TResultadoCierreVenta;
      AEnviarEmail: Boolean;
      const AEmailEnvio: string);
    procedure WMSaltarAtributo(var Msg: TMessage); message WM_SALTAR_ATRIBUTO;
    procedure DsLineasDataChange(Sender: TObject; Field: TField);
    procedure tvLineasOpeAvButtonClick(Sender: TObject;
                                       AButtonIndex: Integer);
    procedure WMFinalizarAtribCaja(var Msg: TMessage);
                                       message WM_FINALIZAR_ATRIB_CAJA;
    procedure WMAvanzarAtribCaja(var Msg: TMessage);
                                       message WM_AVANZAR_ATRIB_CAJA;
    procedure WMAbrirPopupAv(var Msg: TMessage);
                                       message WM_ABRIR_POPUP_AV;
    procedure WMEnfocarArticuloCaja(var Msg: TMessage);
                                       message WM_ENFOCAR_ARTICULO_CAJA;
    procedure ProcesarLecturaScanner(const ACodigo: string);
    procedure LectorCodigoLeido(Sender: TObject; const ACodigo: string);
    function  LectorRejillaEditando: Boolean;
    function  LectorEsControlRejilla(AControl: TControl): Boolean;
    function CrearOperacionCajaHermana: TfrmMtoOpeCaja;
    procedure LectorLecturaIniciada(Sender: TObject);
//    procedure LogPerfCaja(const AContexto, ADetalles: string);
  public
    DatosCaja: TdmCajaOpe;
  private
    // Detector reutilizable del lector de codigo de barras (trama STX/ETX +
    // rafaga por velocidad). La mecanica vive en TLectorScanner; aqui solo
    // queda el negocio (ProcesarLecturaScanner y los flags de abajo).
    FEntrada: TEntradaOperacionCaja;
    FValidandoCliente: Boolean;
    FCodigoEmpresa:String;
    FCodigoAlmacen, FCodigoCaja:String;
    FFecha:TDateTime;
  private
    FNumeroCajaActual: Integer;
    const MAX_CAJAS = 5;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasOperacionCaja); reintroduce;
      overload;
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
    function FormularioCaja: TCustomForm;
    // Carga EXTERNA ("Enviar a..." de Documentos de Trabajo): anade
    // una linea con el SKU y cantidad indicados usando el mismo flujo
    // que el lector (RellenarDatosArticuloEnDataset). False si el
    // articulo/SKU no existe o esta descatalogado.
    function CargarSkuExterno(const ASku: string;
                              ACant: Double): Boolean;
    procedure PrepararValores(AEmpresa, AAlmacen, ACaja: string;
                              AFecha: TDateTime);
    procedure CargarDevolucion(
      const ASerie, ANumero, AEmpresaOrigen,
      AAlmacenOrigen: string);
    function IntentarCerrar:Boolean;
    // True si no hay venta a medias (sin líneas pendientes)
    function OperacionVacia: Boolean;
    // Carga la operación como rectificación del ticket indicado. El tipo
    // decide el signo de las líneas y la leyenda de la operación de caja.
    procedure CargarRectificacion(
      const ASerie, ANumero: string;
      ATipoRectificativa: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa);
    property NumeroCajaActual: Integer read FNumeroCajaActual
                                       write FNumeroCajaActual;
  end;

implementation

{$R *.dfm}

uses
  inLibGridCantidad,

  inLibDevExp, inLibValoresAutomaticos,
  UniDataValoresAutomaticosRepositorio, inLibFacturas,
  inLibAtributosPaleta,
  inLibShowMto,
  inLibCorreoTickets, UniDataCorreoTicketsRepositorio,
  inLibCajaVentaCliente,
  inLibCajaVentaOperacion,
  inLibCajaOpePresentacion,
  inMtoCajaCierreVentaVcl,
  inMtoCajaOperacionVclInyeccion,
  inMtoCajaOpeEntradaVcl,
  inMtoCajaOpeBusquedaVcl,
  UniDataFacturasLecturas,
  System.StrUtils,
  inLibMsgCaja, inLibTraducciones;

constructor TfrmMtoOpeCaja.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasOperacionCaja);
begin
  ADependencias.Validar;
  FDependenciasPantalla := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure InicializarVentanaOperacionCajaVcl(
  AFormulario: TfrmMtoOpeCaja);
var
  Contexto: TContextoVentanaOperacionCajaVcl;
begin
  Contexto := Default(TContextoVentanaOperacionCajaVcl);
  Contexto.Formulario := AFormulario;
  Contexto.EtiquetasBotonera := TArray<TcxLabel>.Create(
    AFormulario.lblCobro,
    AFormulario.lblBuscar,
    AFormulario.lblEliminar,
    AFormulario.lblTextoTarifa,
    AFormulario.lblBusqTick,
    AFormulario.lblIndIVA,
    AFormulario.lblOtro,
    AFormulario.lblCargarCta,
    AFormulario.lblBuscarModificar);
  Contexto.EtiquetaFecha := AFormulario.lblFechaCaja;
  Contexto.BotonEmpleado := AFormulario.btnCodigoEmpleado;
  Contexto.RejillaLineas := AFormulario.cxgrdLineasOpe;
  Contexto.PanelBusqueda := AFormulario.pnlBusqueda;
  Contexto.PanelFoto := AFormulario.pnlFotoStock;
  Contexto.VistaLineas := AFormulario.tvLineasOpe;
  Contexto.ContextoSesion := AFormulario.ContextoSesion;
  Contexto.PerfilesLectura := AFormulario.PerfilesLectura;
  Contexto.PerfilesEscritura := AFormulario.PerfilesEscritura;
  Contexto.SolicitudPermisoLayout :=
    AFormulario.SolicitudPermisoLayout;
  Contexto.Permisos := AFormulario.Permisos;
  Contexto.ObtenerEmpresa :=
    function: string
    begin
      Result := AFormulario.FCodigoEmpresa;
    end;
  Contexto.ObtenerAlmacen :=
    function: string
    begin
      Result := AFormulario.FCodigoAlmacen;
    end;
  Contexto.ObtenerCaja :=
    function: string
    begin
      Result := AFormulario.FCodigoCaja;
    end;
  Contexto.ObtenerFecha :=
    function: TDateTime
    begin
      Result := AFormulario.FFecha;
    end;
  Contexto.EstablecerFecha :=
    procedure(AFecha: TDateTime)
    begin
      AFormulario.FFecha := AFecha;
    end;
  Contexto.FormatearFecha :=
    function(AFecha: TDateTime): string
    begin
      Result := FormatearFechaHoraIdioma(
        'hh:nn:ss dddd d mmmm yyyy',
        AFecha,
        AFormulario.Traducciones);
    end;
  Contexto.EscribirFechaCabecera :=
    procedure(AFecha: TDateTime)
    begin
      if Assigned(AFormulario.DatosCaja) and
         Assigned(AFormulario.DatosCaja.cdsCabecera) then
        EscribirFechaCabeceraVenta(
          AFormulario.DatosCaja.cdsCabecera,
          AFecha);
    end;
  Contexto.NotificarFecha :=
    procedure(AFecha: TDateTime)
    begin
      inLibCajaVentanasIntf.NotificarFechaCaja(AFecha);
    end;
  AFormulario.FPresentacion := TVentanaOperacionCajaVcl.Create(
    Contexto);
end;

procedure InicializarEntradaCajaVcl(AFormulario: TfrmMtoOpeCaja);
var
  oContexto: TContextoEntradaCajaOpeVcl;
begin
  oContexto := Default(TContextoEntradaCajaOpeVcl);
  oContexto.Cabecera := AFormulario.DatosCaja.cdsCabecera;
  oContexto.Lineas := AFormulario.DatosCaja.cdsLineas;
  oContexto.VistaLineas := AFormulario.tvLineasOpe;
  oContexto.TemporizadorBusqueda := AFormulario.tmrBusq;
  oContexto.BotonVendedor := AFormulario.btnCodigoEmpleado;
  oContexto.Conexion := AFormulario.ConexionPrincipal;
  oContexto.RepositorioFacturas :=
    AFormulario.FLecturas.RepositorioFacturas;
  oContexto.ValidadorArticulos :=
    AFormulario.FDependenciasPantalla.ValidadorArticulos;
  oContexto.PermitirSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.ValidarSkuParaVenta(
        ACodigoSku);
    end;
  oContexto.ConsolidarSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.ConsolidarSiExiste(
        ACodigoSku);
    end;
  oContexto.RellenarArticulo :=
    function(const ACodigo: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.
        RellenarDatosArticuloEnDataset(ACodigo);
    end;
  oContexto.RellenarAtributos :=
    procedure(const ACodigoSku: string)
    begin
      AFormulario.FEditorLineas.RellenarAtributosDesdeSku(
        ACodigoSku);
    end;
  oContexto.CambiarResolviendo :=
    procedure(AEstado: Boolean)
    begin
      AFormulario.FEntrada.ResolviendoPorScanner := AEstado;
    end;
  oContexto.CambiarProcesando :=
    procedure(AEstado: Boolean)
    begin
      AFormulario.FEntrada.ProcesandoLectura := AEstado;
    end;
  oContexto.AsegurarLinea :=
    procedure
    begin
      AFormulario.FEditorLineas.AsegurarLineaNueva;
    end;
  oContexto.ActualizarTotal := AFormulario.ActualizarLabelTotal;
  AFormulario.FEntrada.Aplicacion :=
    CrearAplicacionEntradaCajaOpeVcl(oContexto);
end;

function CrearContextoBusquedaCajaVcl(
  AFormulario: TfrmMtoOpeCaja): TContextoBusquedaCajaVcl;
begin
  Result := Default(TContextoBusquedaCajaVcl);
  Result.Lineas := AFormulario.DatosCaja.cdsLineas;
  Result.Rejilla := AFormulario.cxgrdLineasOpe;
  Result.VistaLineas := AFormulario.tvLineasOpe;
  Result.BotonEmpleado := AFormulario.btnCodigoEmpleado;
  Result.BotonCliente := AFormulario.btnCodigoCliente;
  Result.ParametrosCaja := AFormulario.ParametrosCaja;
  Result.RepositorioConsultas :=
    AFormulario.FDependencias.RepositorioConsultas;
  Result.AbrirAtributo :=
    procedure(Sender: TObject)
    begin
      AFormulario.tvLineasOpeAvButtonClick(Sender, 0);
    end;
  Result.BuscarArticulo :=
    function: string
    begin
      Result := AFormulario.FEditorLineas.BuscarArticulo;
    end;
  Result.RellenarArticulo :=
    function(const ACodigo: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.
        RellenarDatosArticuloEnDataset(ACodigo);
    end;
  Result.ValidarSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.ValidarSkuParaVenta(
        ACodigoSku);
    end;
  Result.ActualizarColumnas :=
    procedure(const ACodigoArticulo: string)
    begin
      AFormulario.FEditorLineas.ActualizarColumnasDinamicas(
        ACodigoArticulo);
    end;
  Result.NumeroAtributos :=
    function: Integer
    begin
      Result := AFormulario.FEditorLineas.NumeroAtributosActual;
    end;
  Result.RellenarAtributos :=
    procedure(const ACodigoSku: string)
    begin
      AFormulario.FEditorLineas.RellenarAtributosDesdeSku(
        ACodigoSku);
    end;
  Result.ObtenerColumna :=
    function(ANumero: Integer): TcxGridDBColumn
    begin
      Result := AFormulario.FEditorLineas.ObtenerColumnaPorTag(
        ANumero);
    end;
end;

function CrearContextoCierreVentaCajaVcl(
  AFormulario: TfrmMtoOpeCaja): TContextoCierreVentaCajaVcl;
begin
  Result := Default(TContextoCierreVentaCajaVcl);
  Result.Propietario := AFormulario;
  Result.Conexion := AFormulario.ConexionPrincipal;
  Result.RepositorioFacturas :=
    AFormulario.FLecturas.RepositorioFacturas;
  Result.Cabecera := AFormulario.DatosCaja.cdsCabecera;
  Result.Lineas := AFormulario.DatosCaja.cdsLineas;
  Result.RepartidorDescuento :=
    AFormulario.FDependencias.RepartidorDescuento;
  Result.CasoUso := AFormulario.FDependencias.CasoUsoCierre;
  Result.RegistroLog := AFormulario.RegistroLog;
  Result.CodigoEmpresa := AFormulario.FCodigoEmpresa;
  Result.CodigoAlmacen := AFormulario.FCodigoAlmacen;
  Result.CodigoCaja := AFormulario.FCodigoCaja;
  Result.TipoRectificativa := AFormulario.FTipoRectificativa;
  Result.TratamientoMovimientos :=
    AFormulario.FTratamientoMovRectificativa;
  Result.SerieRectificada := AFormulario.FSerieRectifica;
  Result.NumeroRectificado := AFormulario.FNumeroRectifica;
  Result.MotivoDevolucion := AFormulario.FMotivoDevolucion;
  Result.SerieOrigenDevolucion := AFormulario.FSerieOrigenDev;
  Result.NumeroOrigenDevolucion := AFormulario.FNumeroOrigenDev;
  Result.EmpresaOrigenDevolucion := AFormulario.FEmpresaOrigenDev;
  Result.AlmacenOrigenDevolucion := AFormulario.FAlmacenOrigenDev;
  Result.ConfirmarMotivoDevolucion :=
    AFormulario.PedirMotivoDevolucionSiProcede;
  Result.ActualizarReloj :=
    AFormulario.FPresentacion.ActualizarReloj;
  Result.LeerFecha :=
    function: TDateTime
    begin
      Result := AFormulario.FFecha;
    end;
  Result.PresentarResultado := AFormulario.ProcesarResultadoCierre;
  Result.DependenciasFaseCobro :=
    AFormulario.FDependenciasPantalla.FaseCobro;
end;

procedure InicializarServiciosOperacionCajaVcl(
  AFormulario: TfrmMtoOpeCaja);
begin
  AFormulario.DatosCaja := TdmCajaOpe.Create(
    AFormulario,
    AFormulario.ConexionPrincipal,
    AFormulario.ParametrosApp,
    AFormulario.ParametrosCaja,
    AFormulario.PreviewTicket);
  AFormulario.FDependencias := CrearDependenciasOperacionCajaVclUniDAC(
    AFormulario,
    AFormulario.ParametrosApp,
    AFormulario.PreviewTicket,
    AFormulario.UnidadesMedida,
    AFormulario.ConexionPrincipal,
    AFormulario.ParametrosCaja,
    AFormulario.Permisos,
    AFormulario.ContextoSesion,
    AFormulario.PerfilesLectura,
    AFormulario.PerfilesEscritura,
    AFormulario.RegistroLog,
    AFormulario.FDependenciasPantalla.Tickets,
    AFormulario.Name,
    AFormulario.DatosCaja,
    AFormulario.FIncidenciasSql);
end;

function TEditorLineasCajaVcl.GetFormulario: TCustomForm;
begin
  Result := FControles.Formulario;
end;

function TEditorLineasCajaVcl.GetRejilla: TcxGrid;
begin
  Result := FControles.Rejilla;
end;

function TEditorLineasCajaVcl.GetVistaLineas: TcxGridDBTableView;
begin
  Result := FControles.VistaLineas;
end;

function TEditorLineasCajaVcl.GetColumnaArticulo: TcxGridDBColumn;
begin
  Result := FControles.ColumnaArticulo;
end;

function TEditorLineasCajaVcl.GetColumnaDescripcion: TcxGridDBColumn;
begin
  Result := FControles.ColumnaDescripcion;
end;

function TEditorLineasCajaVcl.GetColumnaUnidades: TcxGridDBColumn;
begin
  Result := FControles.ColumnaUnidades;
end;

function TEditorLineasCajaVcl.GetColumnaDescuento: TcxGridDBColumn;
begin
  Result := FControles.ColumnaDescuento;
end;

function TEditorLineasCajaVcl.GetColumnaDescuentoMenos:
  TcxGridDBColumn;
begin
  Result := FControles.ColumnaDescuentoMenos;
end;

function TEditorLineasCajaVcl.GetFuenteLineas: TDataSource;
begin
  Result := FControles.FuenteLineas;
end;

function TEditorLineasCajaVcl.GetFuenteBusqueda: TDataSource;
begin
  Result := FControles.FuenteBusqueda;
end;

function TEditorLineasCajaVcl.GetTemporizadorBusqueda: TTimer;
begin
  Result := FControles.TemporizadorBusqueda;
end;

function TEditorLineasCajaVcl.GetNavegacionEnter: TJvEnterAsTab;
begin
  Result := FControles.NavegacionEnter;
end;

function TEditorLineasCajaVcl.GetBotonBuscar: TcxButton;
begin
  Result := FControles.BotonBuscar;
end;

function TEditorLineasCajaVcl.GetBotonEliminar: TcxButton;
begin
  Result := FControles.BotonEliminar;
end;

constructor TEditorLineasCajaVcl.Create(
  const AControles: TControlesEditorLineasCajaVcl;
  const AServicios: TServiciosEditorLineasCajaVcl);
var
  ContextoBusqueda: TContextoBusquedaEditorLineasCajaVcl;
  ContextoInteraccion: TContextoInteraccionEditorLineasCajaVcl;
  ContextoRender: TContextoRenderEditorLineasCajaVcl;
  ContextoAtributos: TContextoAtributosEditorLineasCajaVcl;
begin
  inherited Create;
  FControles := AControles;
  FDatosCaja := AServicios.DatosCaja;
  FConexionPrincipal := AServicios.Conexion;
  FParametrosCaja := AServicios.ParametrosCaja;
  FValidadorArticulos := AServicios.ValidadorArticulos;
  FResolverArticulos := AServicios.ResolverArticulos;
  FAtributosArticulos := AServicios.AtributosArticulos;
  FDependencias := AServicios.Dependencias;
  FRepositorioArticulos := AServicios.RepositorioArticulos;
  FRepositorioFacturas := AServicios.RepositorioFacturas;
  FRegistroLog := AServicios.RegistroLog;
  FActualizarTotal := AServicios.ActualizarTotal;
  FCerrarFormulario := AServicios.CerrarFormulario;
  FResolviendoPorScanner := AServicios.ResolviendoPorScanner;
  FLectorLeyendoTrama := AServicios.LectorLeyendoTrama;
  FObtenerAlmacen := AServicios.ObtenerAlmacen;
  FBmpSwatchBoton := TBitmap.Create;
  ContextoBusqueda := Default(TContextoBusquedaEditorLineasCajaVcl);
  ContextoBusqueda.Formulario := AControles.Formulario;
  ContextoBusqueda.DatosCaja := AServicios.DatosCaja;
  ContextoBusqueda.Conexion := AServicios.Conexion;
  ContextoBusqueda.ParametrosCaja := AServicios.ParametrosCaja;
  ContextoBusqueda.RepositorioConsultas :=
    AServicios.Dependencias.RepositorioConsultas;
  ContextoBusqueda.RepositorioArticulos :=
    AServicios.RepositorioArticulos;
  ContextoBusqueda.BusquedaVisual := AServicios.BusquedaVisual;
  ContextoBusqueda.FotosArticulos := AServicios.FotosArticulos;
  ContextoBusqueda.RegistroLog := AServicios.RegistroLog;
  ContextoBusqueda.VistaLineas := AControles.VistaLineas;
  ContextoBusqueda.FuenteLineas := AControles.FuenteLineas;
  ContextoBusqueda.FuenteStock := AControles.FuenteStock;
  ContextoBusqueda.FuenteBusqueda := AControles.FuenteBusqueda;
  ContextoBusqueda.VistaStock := AControles.VistaStock;
  ContextoBusqueda.VistaBusqueda := AControles.VistaBusqueda;
  ContextoBusqueda.TemporizadorBusqueda :=
    AControles.TemporizadorBusqueda;
  ContextoBusqueda.ImagenStock := AControles.ImagenStock;
  FBusqueda := TBusquedaEditorLineasCajaVcl.Create(
    ContextoBusqueda);
  ContextoInteraccion :=
    Default(TContextoInteraccionEditorLineasCajaVcl);
  ContextoInteraccion.VistaLineas := AControles.VistaLineas;
  ContextoInteraccion.RepositorioSoloTexto :=
    AControles.RepositorioSoloTexto;
  ContextoInteraccion.RepositorioCombo :=
    AControles.RepositorioCombo;
  ContextoInteraccion.TemporizadorBusqueda :=
    AControles.TemporizadorBusqueda;
  ContextoInteraccion.LectorLeyendoTrama :=
    AServicios.LectorLeyendoTrama;
  FInteraccion := TInteraccionEditorLineasCajaVcl.Create(
    ContextoInteraccion);
  ContextoRender := Default(TContextoRenderEditorLineasCajaVcl);
  ContextoRender.Conexion := AServicios.Conexion;
  ContextoRender.ColumnaArticulo := AControles.ColumnaArticulo;
  FRender := TRenderEditorLineasCajaVcl.Create(ContextoRender);
  ContextoAtributos :=
    Default(TContextoAtributosEditorLineasCajaVcl);
  ContextoAtributos.Formulario := AControles.Formulario;
  ContextoAtributos.DatosCaja := AServicios.DatosCaja;
  ContextoAtributos.Conexion := AServicios.Conexion;
  ContextoAtributos.ParametrosCaja := AServicios.ParametrosCaja;
  ContextoAtributos.AtributosArticulos :=
    AServicios.AtributosArticulos;
  ContextoAtributos.RegistroLog := AServicios.RegistroLog;
  ContextoAtributos.VistaLineas := AControles.VistaLineas;
  ContextoAtributos.ColumnaArticulo := AControles.ColumnaArticulo;
  ContextoAtributos.ColumnaDescripcion :=
    AControles.ColumnaDescripcion;
  ContextoAtributos.ObtenerNumeroAtributos :=
    function: Integer
    begin
      Result := FNumAtributosActual;
    end;
  ContextoAtributos.RecalcularPrecio :=
    procedure(const ASku: string)
    begin
      RecalcularPrecioDesdeSku(ASku);
    end;
  ContextoAtributos.Consolidar :=
    function(const ASku: string): Boolean
    begin
      Result := ConsolidarSiExiste(ASku);
    end;
  ContextoAtributos.ValidarSku :=
    function(const ASku: string): Boolean
    begin
      Result := ValidarSkuParaVenta(ASku);
    end;
  ContextoAtributos.ConsultarStock :=
    procedure(const ASku: string)
    begin
      ConsultarStock(ASku);
    end;
  ContextoAtributos.MensajeFinalizar := WM_FINALIZAR_ATRIB_CAJA;
  ContextoAtributos.MensajeAvanzar := WM_AVANZAR_ATRIB_CAJA;
  ContextoAtributos.MensajeAbrirPopup := WM_ABRIR_POPUP_AV;
  FSelectorAtributos :=
    TSelectorAtributosEditorLineasCajaVcl.Create(
      ContextoAtributos);
end;

destructor TEditorLineasCajaVcl.Destroy;
begin
  FTecladoLinea.Procesador := nil;
  FTecladoLinea.Rejilla := nil;
  FreeAndNil(FSelectorAtributos);
  FreeAndNil(FRender);
  FreeAndNil(FInteraccion);
  FreeAndNil(FBusqueda);
  FResultadoBusquedaIncremental := nil;
  FRepositorioArticulos := nil;
  FRepositorioFacturas := nil;
  FValidadorArticulos := nil;
  FResolverArticulos := nil;
  FAtributosArticulos := nil;
  FParametrosCaja := nil;
  FRegistroLog := nil;
  FreeAndNil(FBmpSwatchBoton);
  inherited;
end;

function TEditorLineasCajaVcl.ObtenerResolviendoPorScanner: Boolean;
begin
  Result := Assigned(FResolviendoPorScanner) and
    FResolviendoPorScanner();
end;

procedure TEditorLineasCajaVcl.ActualizarLabelTotal(Sender: TObject;
  ANuevoTotal: Currency);
begin
  if Assigned(FActualizarTotal) then
    FActualizarTotal(Sender, ANuevoTotal);
end;

procedure TEditorLineasCajaVcl.Inicializar;
begin
  ConstruirColumnasDinamicas;
  InicializarTecladoLineaCaja;
end;

procedure InicializarEditorLineasCajaVcl(
  AFormulario: TfrmMtoOpeCaja);
var
  Controles: TControlesEditorLineasCajaVcl;
  Servicios: TServiciosEditorLineasCajaVcl;
begin
  Controles := Default(TControlesEditorLineasCajaVcl);
  Controles.Formulario := AFormulario;
  Controles.Rejilla := AFormulario.cxgrdLineasOpe;
  Controles.VistaLineas := AFormulario.tvLineasOpe;
  Controles.ColumnaArticulo := AFormulario.tvArticulo;
  Controles.ColumnaDescripcion := AFormulario.tvDescripcion;
  Controles.ColumnaUnidades := AFormulario.tvUds;
  Controles.ColumnaDescuento := AFormulario.tvDescuento;
  Controles.ColumnaDescuentoMenos := AFormulario.tvDescuentoMenos;
  Controles.FuenteLineas := AFormulario.dsLineas;
  Controles.FuenteStock := AFormulario.dsStock;
  Controles.FuenteBusqueda := AFormulario.dsBusq;
  Controles.VistaStock := AFormulario.dbtvStock;
  Controles.VistaBusqueda := AFormulario.dbtvBusq;
  Controles.RepositorioSoloTexto := AFormulario.repSoloTexto;
  Controles.RepositorioCombo := AFormulario.repComboBox;
  Controles.TemporizadorBusqueda := AFormulario.tmrBusq;
  Controles.NavegacionEnter := AFormulario.jvEnterTab;
  Controles.BotonBuscar := AFormulario.btnF3;
  Controles.BotonEliminar := AFormulario.btnF8;
  Controles.ImagenStock := AFormulario.imgFotoStock;
  Servicios := Default(TServiciosEditorLineasCajaVcl);
  Servicios.DatosCaja := AFormulario.DatosCaja;
  Servicios.Conexion := AFormulario.ConexionPrincipal;
  Servicios.ParametrosCaja := AFormulario.ParametrosCaja;
  Servicios.ValidadorArticulos :=
    AFormulario.FDependenciasPantalla.ValidadorArticulos;
  Servicios.ResolverArticulos :=
    AFormulario.FDependenciasPantalla.ResolverArticulos;
  Servicios.AtributosArticulos :=
    AFormulario.FDependenciasPantalla.AtributosArticulos;
  Servicios.Dependencias := AFormulario.FDependencias;
  Servicios.RepositorioArticulos :=
    AFormulario.FDependenciasPantalla.Articulos;
  Servicios.RepositorioFacturas :=
    AFormulario.FLecturas.RepositorioFacturas;
  Servicios.BusquedaVisual := AFormulario.BusquedaVisual;
  Servicios.FotosArticulos := AFormulario.FotosArticulos;
  Servicios.RegistroLog := AFormulario.RegistroLog;
  Servicios.ActualizarTotal :=
    procedure(Sender: TObject; ANuevoTotal: Currency)
    begin
      AFormulario.ActualizarLabelTotal(Sender, ANuevoTotal);
    end;
  Servicios.CerrarFormulario :=
    procedure
    begin
      AFormulario.Close;
    end;
  Servicios.ResolviendoPorScanner :=
    function: Boolean
    begin
      Result := AFormulario.FEntrada.ResolviendoPorScanner;
    end;
  Servicios.LectorLeyendoTrama :=
    function: Boolean
    begin
      Result := AFormulario.FEntrada.Lector.LeyendoTrama;
    end;
  Servicios.ObtenerAlmacen :=
    function: string
    begin
      Result := AFormulario.FCodigoAlmacen;
    end;
  AFormulario.FEditorLineas := TEditorLineasCajaVcl.Create(
    Controles, Servicios);
  AFormulario.FEditorLineas.Inicializar;
end;

procedure TfrmMtoOpeCaja.tvLineasOpeCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FEditorLineas.DibujarCeldaLinea(
    Sender, ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoOpeCaja.dbtvStockCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FEditorLineas.DibujarCeldaStock(
    Sender, ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoOpeCaja.WMCancelarLinea(var Msg: TMessage);
begin
  FEditorLineas.CancelarLinea;
end;

procedure TfrmMtoOpeCaja.tmrBusqTimer(Sender: TObject);
begin
  FEditorLineas.EjecutarBusquedaIncremental(Sender);
end;

procedure TfrmMtoOpeCaja.tvArticuloGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
begin
  FEditorLineas.ObtenerPropiedadesArticulo(
    Sender, ARecord, AProperties);
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesChange(Sender: TObject);
begin
  FEditorLineas.CambiarArticulo(Sender);
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesCloseUp(Sender: TObject);
begin
  FEditorLineas.CerrarBusquedaArticulo(Sender);
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
begin
  FEditorLineas.ValidarArticulo(
    Sender, DisplayValue, ErrorText, Error);
end;

procedure TfrmMtoOpeCaja.tvDescuentoMenosPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarDescuentoMenos(Sender);
end;

procedure TfrmMtoOpeCaja.tvDescuentoPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarDescuento(Sender);
end;

procedure TfrmMtoOpeCaja.tvPrecioUniPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarPrecioUnitario(Sender);
end;

procedure TfrmMtoOpeCaja.tvTotalPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarTotal(Sender);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarUnidades(Sender);
end;

procedure TfrmMtoOpeCaja.repComboBoxPropertiesInitPopup(
  Sender: TObject);
begin
  FEditorLineas.InicializarPopupBusqueda(Sender);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1CanFocusRecord(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  var AAllow: Boolean);
begin
  FEditorLineas.ComprobarFocoRegistro(Sender, ARecord, AAllow);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1Editing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  FEditorLineas.ComprobarEdicion(Sender, AItem, AAllow);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1EditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
begin
  FEditorLineas.ProcesarTeclaEdicion(
    Sender, AItem, AEdit, Key, Shift);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1FocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  FEditorLineas.CambiarRegistroEnfocado(
    Sender,
    APrevFocusedRecord,
    AFocusedRecord,
    ANewItemRecordFocusingChanged);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1InitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  FEditorLineas.InicializarEdicion(Sender, AItem, AEdit);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1KeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FEditorLineas.ProcesarTeclaRejilla(Sender, Key, Shift);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1MouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  FEditorLineas.PulsarRejilla(Sender, Button, Shift, X, Y);
end;

procedure TfrmMtoOpeCaja.cxGrid1Enter(Sender: TObject);
begin
  FEditorLineas.EntrarRejilla(Sender);
end;

procedure TfrmMtoOpeCaja.cxGrid1Exit(Sender: TObject);
begin
  FEditorLineas.SalirRejilla(Sender);
end;

procedure TfrmMtoOpeCaja.DsLineasDataChange(
  Sender: TObject; Field: TField);
begin
  FEditorLineas.NotificarCambioLinea(Sender, Field);
end;

procedure TfrmMtoOpeCaja.WMEnfocarArticuloCaja(var Msg: TMessage);
begin
  FEditorLineas.EnfocarArticulo;
end;

procedure TfrmMtoOpeCaja.WMAbrirPopupAv(var Msg: TMessage);
begin
  FEditorLineas.AbrirPopupAtributo;
end;

procedure TfrmMtoOpeCaja.tvLineasOpeAvButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FEditorLineas.SeleccionarAtributo(Sender, AButtonIndex);
end;

procedure TfrmMtoOpeCaja.WMFinalizarAtribCaja(var Msg: TMessage);
begin
  FEditorLineas.FinalizarAtributos;
end;

procedure TfrmMtoOpeCaja.WMAvanzarAtribCaja(var Msg: TMessage);
begin
  FEditorLineas.AvanzarAtributo(Msg.WParam);
end;

procedure TfrmMtoOpeCaja.WMSaltarAtributo(var Msg: TMessage);
begin
  if (tvLineasOpe.Controller.EditingController <> nil) and
     (tvLineasOpe.Controller.EditingController.IsEditing) then
  begin
    PostMessage(tvLineasOpe.Controller.EditingController.Edit.Handle,
                WM_KEYDOWN,
                VK_RETURN, 0);
  end;
end;

function TfrmMtoOpeCaja.CargarSkuExterno(const ASku: string;
  ACant: Double): Boolean;
begin
  // Fila en blanco lista y en edicion, como tras una lectura.
  FEditorLineas.AsegurarLineaNueva;
  if not (DatosCaja.cdsLineas.State in dsEditModes) then
    DatosCaja.cdsLineas.Edit;
  Result := FEditorLineas.RellenarDatosArticuloEnDataset(ASku);
  if Result then
  begin
    DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := ACant;
    DatosCaja.cdsLineas.Post;
    GridRecalc(ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
               tvLineasOpe, DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera, ActualizarLabelTotal);
    FEditorLineas.AsegurarLineaNueva;
  end
  else
  begin
    if DatosCaja.cdsLineas.State in dsEditModes then
      DatosCaja.cdsLineas.Cancel;
  end;
end;

procedure TfrmMtoOpeCaja.PrepararValores(AEmpresa, AAlmacen, ACaja: string;
                                         AFecha: TDateTime);
var
  EmpleadoAnterior, NombreEmpleadoAnterior: string;
  EmpleadoInicial, NombreEmpleadoInicial: string;
begin
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FCodigoCaja    := ACaja;
  FFecha         := AFecha;
  FPresentacion.ReiniciarReloj;
  lblTipoRectificativa.Caption := '';
  lblTipoRectificativa.Visible := False;

  if Assigned(DatosCaja) then
  begin
    // 1. Guardar el ultimo empleado que el usuario valido en esta ventana.
    // No se toma del dataset: al insertar, los valores automaticos de la
    // tabla pueden haber escrito un cajero que nunca se eligio en caja.
    EmpleadoAnterior := '';
    NombreEmpleadoAnterior := '';
    if DatosCaja.cdsCabecera.Active and
       not DatosCaja.cdsCabecera.IsEmpty and
       SameText(
         Trim(btnCodigoEmpleado.Text),
         Trim(DatosCaja.cdsCabecera.FieldByName(
           'CODIGO_CAJERO_FAC').AsString)) then
    begin
      EmpleadoAnterior := Trim(btnCodigoEmpleado.Text);
      NombreEmpleadoAnterior := lblNombreEmpleado.Caption;
    end;
    if (tvLineasOpe.Controller.EditingController <> nil) and
       tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      tvLineasOpe.Controller.EditingController.HideEdit(True);
    end;
    // 2. Vaciar la venta anterior y preparar la nueva cabecera.
    ReiniciarDatosOperacionVenta(
      DatosCaja.cdsLineas, DatosCaja.cdsCabecera);
    tvLineasOpe.DataController.Refresh;
    // Nueva operacion: ocultamos la fecha de deposito y volvemos a la vista
    // normal de columnas (% y Menos visibles, atributos ocultos) hasta que se
    // vuelva a cargar la cuenta del cliente con F2.
    tvFechaOperacion.Visible := False;
    FEditorLineas.MostrarColumnasCuentaCliente(False);
    lblNombreCliente.Caption := '';
    btnCodigoCliente.Text := '';
    // 3. Aplicar valores base.
    DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime := FFecha;
    AplicarValoresPorDefecto(
      ConexionPrincipal,
      DatosCaja.cdsCabecera,
      'fza_facturas');
    EscribirCabeceraBaseOperacionVenta(
      DatosCaja.cdsCabecera,
      FCodigoEmpresa,
      ParametrosCaja.GetString('vgerDefTarifa', 'PVP'),
      FFecha);
    lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    // 4. El valor automatico de fza_facturas no gobierna el empleado de caja.
    // Se conserva el ultimo validado; si no existe, solo se usa el parametro
    // configurado. En ausencia de ambos se deja vacio para mantener el foco.
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').Clear;
    btnCodigoEmpleado.Text := '';
    lblNombreEmpleado.Caption := '';
    EmpleadoInicial := ResolverEmpleadoNuevaOperacionVenta(
      EmpleadoAnterior,
      ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False),
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', ''));
    if EmpleadoInicial <> '' then
    begin
      if EmpleadoAnterior <> '' then
      begin
        DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
          EmpleadoInicial;
        btnCodigoEmpleado.Text := EmpleadoInicial;
        lblNombreEmpleado.Caption := NombreEmpleadoAnterior;
      end
      else if DatosCaja.BuscarYMostrarNombre(
                'EMPLEADOS',
                EmpleadoInicial,
                NombreEmpleadoInicial) then
      begin
        DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
          EmpleadoInicial;
        btnCodigoEmpleado.Text := EmpleadoInicial;
        lblNombreEmpleado.Caption := NombreEmpleadoInicial;
      end;
    end;
  end;
  dbtvStock.ClearItems;
  lblNombreCliente.Caption := SCaptionVentaContado;
  btnCodigoCliente.Text := '';
  lblTotal.Caption := SCaptionTotalCero;
  FPresentacion.ActualizarReloj;
  if Self.Visible then
    FPresentacion.ActualizarFoco;
end;

procedure TEditorLineasCajaVcl.ConsultarStock(const ACodigo: string);
begin
  FBusqueda.ConsultarStock(ACodigo);
end;

procedure TEditorLineasCajaVcl.DibujarCeldaLinea(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FRender.DibujarCeldaLinea(Sender, ACanvas, AViewInfo, ADone);
end;

procedure TEditorLineasCajaVcl.DibujarCeldaStock(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FRender.DibujarCeldaStock(Sender, ACanvas, AViewInfo, ADone);
end;

function TEditorLineasCajaVcl.ValidarSkuParaVenta(
  const ASku: string): Boolean;
var
  Resultado: TResultadoPoliticaStockVenta;
begin
  Resultado := FDependencias.PoliticaStock.Validar(
    ASku,
    FObtenerAlmacen());
  if Resultado.Mensaje <> '' then
    ShowMessage(Resultado.Mensaje);
  Result := Resultado.Permitida;
end;

procedure TfrmMtoOpeCaja.FormKeyPress(Sender: TObject; var Key: Char);
begin
  FEntrada.Lector.KeyPress(Key);
end;

procedure TfrmMtoOpeCaja.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  ProcesarLecturaScanner(ACodigo);
end;

// El lector consulta si la rejilla estaba editando (anti-eco) y si un control
// pertenece a la rejilla (restauracion del campo solo fuera de la rejilla).
function TfrmMtoOpeCaja.LectorRejillaEditando: Boolean;
begin
  Result := (tvLineasOpe.Controller.EditingController <> nil) and
            tvLineasOpe.Controller.EditingController.IsEditing;
end;

function TfrmMtoOpeCaja.LectorEsControlRejilla(AControl: TControl): Boolean;
var
  C: TControl;
begin
  Result := False;
  C := AControl;
  while (C <> nil) and (not Result) do
  begin
    if C = cxgrdLineasOpe then
      Result := True;
    C := C.Parent;
  end;
end;

// Al iniciar una trama del lector paramos el timer de busqueda incremental.
procedure TfrmMtoOpeCaja.LectorLecturaIniciada(Sender: TObject);
begin
  tmrBusq.Enabled := False;
end;

// Procesa un codigo leido con pistola desde cualquier punto del formulario:
// lo resuelve SOLO contra codigos de barras y, si es vendible, da de alta la
// linea de venta automaticamente y deja una nueva linea lista para el
// siguiente escaneo. El alta de linea es SIEMPRE, con independencia del
// parametro vgerMoverLineaIdentif (que solo gobierna la entrada manual).
// Unica precondicion: el vendedor (cajero) debe estar dado de alta.
procedure TfrmMtoOpeCaja.ProcesarLecturaScanner(const ACodigo: string);
begin
  if Assigned(FEntrada.Aplicacion) then
    FEntrada.Aplicacion.Procesar(ACodigo);
end;

procedure TEditorLineasCajaVcl.CancelarLinea;
var
  VieneDeDep: string;
  bCancelar: Boolean;
begin
  if (DatosCaja.cdsLineas.Active) then
  begin
    bCancelar := True;
    // NUEVO: Bloqueo de borrado por atajo
    if not DatosCaja.cdsLineas.IsEmpty then
    begin
      VieneDeDep :=
        DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if EsLineaDeposito(VieneDeDep) then
      begin
        ShowMessage(SErrorLineaDepositoCajaNoCancelable);
        bCancelar := False;
      end;
    end;
    if bCancelar then
    begin
      if DatosCaja.cdsLineas.State = dsInsert then
        DatosCaja.cdsLineas.Cancel
      else if not DatosCaja.cdsLineas.IsEmpty then
        DatosCaja.cdsLineas.Delete;
      GridRecalc(ConexionPrincipal, FRepositorioFacturas, nil,
        tvLineasOpe, DatosCaja.cdsLineas, DatosCaja.cdsCabecera,
        ActualizarLabelTotal);
      AsegurarLineaNueva;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.EjecutarBusquedaIncremental(
  Sender: TObject);
var
  Resultado: IResultadoConsultaCaja;
begin
  Resultado := FBusqueda.EjecutarBusquedaIncremental(Sender);
  if Assigned(Resultado) then
    FResultadoBusquedaIncremental := Resultado;
end;

procedure TEditorLineasCajaVcl.ObtenerPropiedadesArticulo(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
begin
  FInteraccion.ObtenerPropiedadesArticulo(
    Sender,
    ARecord,
    AProperties);
end;

procedure TEditorLineasCajaVcl.CambiarArticulo(Sender: TObject);
begin
  FInteraccion.CambiarArticulo(Sender);
end;

procedure TEditorLineasCajaVcl.CerrarBusquedaArticulo(Sender: TObject);
begin
  FInteraccion.CerrarBusquedaArticulo(Sender);
end;

function TEditorLineasCajaVcl.BuscarArticulo: string;
begin
  Result := FBusqueda.BuscarArticulo;
end;

procedure TEditorLineasCajaVcl.ValidarArticulo(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodigoInput: string;
  CodigoPadre: string;
  SkuDetectado: string;
  NumAtributos: Integer;
begin
  // Arrancamos el cronometro global art -> primer popup para diagnosticar
  // donde se va el tiempo entre Enter en el codigo y la salida del primer
  // desplegable de atributo (lo cierra WMAbrirPopupAv).
  FSelectorAtributos.IniciarMedicionPopup;
  CodigoInput := VarToStr(DisplayValue);
  FArticuloResueltoEdicion := '';
  if RellenarDatosArticuloEnDataset(CodigoInput) then
  begin
    CodigoPadre  := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    FArticuloResueltoEdicion := CodigoPadre;
    SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    // Validación parametrizada: SKU debe existir en fza_articulos_skus y, si
    // procede, tener stock. Se ejecuta sólo cuando el SKU ya está definido
    // (no es el padre a la espera de talla/color).
    if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodigoPadre) and
       not ValidarSkuParaVenta(SkuDetectado) then
    begin
      EliminarLineaVentaPorValidacion(DatosCaja.cdsLineas);
      DisplayValue := null;
      Error := False;
      Abort;
    end;
    if (not FConservoImportesUltimaPreparacion) and
       (NumAtributos > 0) and (SkuDetectado = CodigoPadre) then
    begin
      DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := 0;
      GridRecalc(
        ConexionPrincipal, FRepositorioFacturas, nil,
                 tvLineasOpe,
                 DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera,
                 ActualizarLabelTotal);
    end;
    if ConsolidarSiExiste(SkuDetectado) then
    begin
       // RellenarDatosArticuloEnDataset ya CONFIRMA (Post) la linea de trabajo
       // en su recalculo fiscal interno, asi que un Cancel no la elimina: si
       // tras cancelar sigue ahi y es el mismo SKU recien consolidado, la
       // BORRAMOS para no dejar duplicado (mismo patron que
       // FinalizarUltimoAtributo).
       if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;
       if not DatosCaja.cdsLineas.IsEmpty then
         if DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString
              = SkuDetectado then
           DatosCaja.cdsLineas.Delete;
       DatosCaja.cdsLineas.Append;
       DisplayValue := null;
       Error := False;
       Abort;
    end;
    tmrBusq.Enabled := False;
    if (CodigoPadre <> '') and (CodigoPadre <> CodigoInput) then
    begin
       DisplayValue := CodigoPadre;
       dsBusq.DataSet := nil;
       FResultadoBusquedaIncremental :=
         FRepositorioArticulos.ConsultarArticulosIncremental(
           DatosCaja.cdsCabecera.FieldByName(
             'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
           CodigoPadre,
           DatosCaja.cdsCabecera.FieldByName(
             'FECHA_FAC').AsDateTime);
       dsBusq.DataSet := FResultadoBusquedaIncremental.DataSet;
    end;
    ActualizarColumnasDinamicas(CodigoPadre);
    // Solo desglosamos atributos si SkuDetectado es un SKU real (distinto
    // del padre). Si SkuDetectado == CodigoPadre estamos a la espera de
    // que el usuario elija talla/color: la query no encontraria nada y
    // gastariamos un round-trip a BBDD para nada.
    if (Trim(SkuDetectado) <> '') and (NumAtributos > 0)
       and (SkuDetectado <> CodigoPadre) then
    begin
       RellenarAtributosDesdeSku(SkuDetectado);
    end;
    Error := False;
  end
  else
  begin
    Error := True;
    if FMotivoRechazoArticulo <> '' then
      ErrorText := FMotivoRechazoArticulo
    else
      ErrorText := SErrorArticuloCajaNoEncontradoDescatalogado;
  end;
end;

procedure TEditorLineasCajaVcl.CambiarDescuentoMenos(
  Sender: TObject);
begin
  // Ponemos a 0 los precios finales para que CalcularLinea
  // respete el descuento y calcule el precio en base a él.
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TEditorLineasCajaVcl.CambiarDescuento(Sender: TObject);
begin
  // Ponemos a 0 los precios finales para que CalcularLinea
  // respete el descuento y calcule el precio en base a él.
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TEditorLineasCajaVcl.CambiarPrecioUnitario(Sender: TObject);
begin
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TEditorLineasCajaVcl.CambiarTotal(Sender: TObject);
begin
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TEditorLineasCajaVcl.CambiarUnidades(Sender: TObject);
begin
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  VieneDeDep: string;
  CantOriginal, NuevaCant: Double;
begin
  if (DatosCaja <> nil) and DatosCaja.cdsLineas.Active then
  begin
  VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
  if VieneDeDep = 'S' then
  begin
    // Convertimos de forma segura el valor tecleado a float
    NuevaCant := StrToFloatDef(VarToStrDef(DisplayValue, '0'), 0);
    CantOriginal := DatosCaja.cdsLineas.FieldByName(
                                              'CANTIDAD_FACLIN').AsFloat;
    // Verificamos que la magnitud sea idéntica (solo permite cambiar signo)
    if Abs(NuevaCant) <> Abs(CantOriginal) then
    begin
      Error := True;
      ErrorText := SErrorCantidadArticuloDepositoCajaNoValida;
    end
    else
    begin
      Error := False;

      // NUEVA LÓGICA: Si cambia a negativo, es una CANCELACIÓN
      if NuevaCant < 0 then
      begin
        DatosCaja.cdsLineas.FieldByName('ACCION_DEPOSITO').AsString :=
                                                                     'CANCELAR';
        // Ponemos el precio a 0 para no devolver el dinero de la prenda
        DatosCaja.cdsLineas.FieldByName(
                                  'PRECIO_SALIDA_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                                       'PORCENTAJE_DTO_FACLIN').AsFloat := 0;
        DatosCaja.cdsLineas.FieldByName(
                                    'PRECIO_DTO_FACLIN').AsCurrency := 0;
      end
      else
      begin
        // Si lo vuelve a poner en positivo, restauramos la acción y su precio
        DatosCaja.cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'COBRAR';
        DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
          DatosCaja.cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
      end;
    end;
  end;
  // Devolución sin código de barras: al validar una cantidad negativa
  // en una línea normal se propone (diferido, fuera del OnValidate) el
  // selector de ventas que contienen ese SKU para elegir el origen.
  if (VieneDeDep <> 'S') and (VieneDeDep <> 'A') then
  begin
    NuevaCant := StrToFloatDef(VarToStrDef(DisplayValue, '0'), 0);
    if (NuevaCant < 0) and
       (FNumeroRectifica = '') and
       (Trim(FSerieOrigenDev) = '') and
       (not FPreguntandoVentaOrigen) then
    begin
      FSkuPendienteVentaOrigen := Trim(
        DatosCaja.cdsLineas.FieldByName(
          'CODIGO_UNIDAD_FACLIN').AsString);
      if FSkuPendienteVentaOrigen = '' then
        FSkuPendienteVentaOrigen := Trim(
          DatosCaja.cdsLineas.FieldByName(
            'CODIGO_ART_FACLIN').AsString);
      if FSkuPendienteVentaOrigen <> '' then
        PostMessage(Handle, WM_PREGUNTAR_VENTA_ORIGEN, 0, 0);
    end;
    end;
  end;
end;

function TEditorLineasCajaVcl.RellenarDatosArticuloEnDataset(
  ACodigo: string): Boolean;
var
  Resultado: TResultadoPreparacionArticuloVenta;
begin
  Result := False;
  FMotivoRechazoArticulo := '';
  FConservoImportesUltimaPreparacion := False;
  if Trim(ACodigo) <> '' then
  begin
    Resultado := PrepararArticuloLineaVenta(
      DatosCaja.cdsLineas,
      DatosCaja.cdsCabecera,
      ACodigo,
      ObtenerResolviendoPorScanner,
      FActualizandoDepositos,
      FValidadorArticulos,
      FResolverArticulos,
      ConsultarStock,
      RecalcularPrecioDesdeSku);
    Result := Resultado.Preparado;
    FMotivoRechazoArticulo := Resultado.MotivoRechazo;
    FConservoImportesUltimaPreparacion :=
      Resultado.ConservoImportesExistentes;
    if Resultado.Preparado and (not FActualizandoDepositos) then
      GridRecalc(
        ConexionPrincipal, FRepositorioFacturas, nil,
        tvLineasOpe, DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera, ActualizarLabelTotal);
  end;
end;

procedure TEditorLineasCajaVcl.InicializarPopupBusqueda(Sender: TObject);
var
  View: TcxGridDBTableView;
begin
  if Sender is TcxExtLookupComboBox then
  begin
    if TcxExtLookupComboBox(Sender).Properties.View is TcxGridDBTableView then
    begin
       View := TcxGridDBTableView(TcxExtLookupComboBox(Sender).Properties.View);
       View.BeginUpdate;
       try
         View.Controller.IncSearchingText := '';
         View.DataController.Filter.Clear;
         View.DataController.Filter.Active := False;
         View.DataController.Filter.AutoDataSetFilter := False;
         View.DataController.Refresh;
       finally
         View.EndUpdate;
       end;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.RecalcularPrecioDesdeSku(
  const ASku: string);
var
  Precio       : TArticuloPrecio;
  CodTarifa    : string;
  CodArt       : string;
  FechaFactura : TDateTime;
begin
  if Trim(ASku) <> '' then
  begin
    CodTarifa := DatosCaja.cdsCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    FechaFactura := DatosCaja.cdsCabecera.FieldByName(
      'FECHA_FAC').AsDateTime;
    CodArt := DatosCaja.cdsLineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
    Precio := FResolverArticulos.ResolverPrecio(
      CodArt, ASku, CodTarifa, FechaFactura);
    if Precio.TieneRegistro then
    begin
      DatosCaja.cdsLineas.FieldByName(
        'ESIMP_INCL_TARIFA_FACLIN').AsString :=
          IfThen(Precio.EsImpIncl, 'S', 'N');
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_SALIDA_FACLIN').AsCurrency := Precio.PrecioSalida;
      DatosCaja.cdsLineas.FieldByName(
        'CANTIDAD_FACLIN').AsCurrency := 1;
      DatosCaja.cdsLineas.FieldByName(
        'PORCENTAJE_DTO_FACLIN').AsFloat := Precio.PorcentajeDto;
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_DTO_FACLIN').AsCurrency := 0;
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
      GridRecalc(ConexionPrincipal, FRepositorioFacturas, nil,
        tvLineasOpe, DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera, ActualizarLabelTotal);
    end;
  end;
end;

procedure TEditorLineasCajaVcl.RellenarAtributosDesdeSku(
  ASku: string);
begin
  // Callback de DatosCaja y pegamento del grid: la escritura vive en
  // inLibCajaVentaOperacion y el lookup se inyecta aqui (14.1).
  RellenarAtributosLineaDesdeSku(
    DatosCaja.cdsLineas,
    ASku,
    FAtributosArticulos);
end;

function TEditorLineasCajaVcl.ConsolidarSiExiste(
  const ASku: string): Boolean;
var
  Clon: TClientDataSet;
  OldQty: Double;
  VieneDeDep: string;
begin
  Result := False;
  if ParametrosCaja.GetBool('vgerAgruparUnidadesIguales', False) and
     (Trim(ASku) <> '') then
  begin
    Clon := TClientDataSet.Create(nil);
    try
      Clon.CloneCursor(DatosCaja.cdsLineas, True);
      Clon.First;
      while not Clon.Eof do
      begin
        VieneDeDep := Clon.FieldByName('VIENE_DE_DEPOSITO').AsString;
        // Solo consolidamos líneas de venta normal.
        // Las líneas de depósito ('S' = prenda apartada, 'A' = abono)
        // NO se consolidan: representan operaciones distintas aunque
        // compartan SKU con un artículo que el cliente se lleva ahora.
        if (VieneDeDep <> 'S') and (VieneDeDep <> 'A') and
           (Clon.FieldByName('CODIGO_UNIDAD_FACLIN').AsString = ASku)
           and (Clon.RecNo <> DatosCaja.cdsLineas.RecNo) then
        begin
          OldQty := Clon.FieldByName('CANTIDAD_FACLIN').AsFloat;
          Clon.Edit;
          Clon.FieldByName('CANTIDAD_FACLIN').AsFloat := OldQty + 1;
          dsLineas.DataSet.DisableControls;
          Clon.Post;
          dsLineas.DataSet.EnableControls;
          GridRecalc(
            ConexionPrincipal, FRepositorioFacturas, nil,
                     tvLineasOpe,
                     DatosCaja.cdsLineas,
                     DatosCaja.cdsCabecera,
                     ActualizarLabelTotal);
          Result := True;
          Break;
        end;
        Clon.Next;
      end;
    finally
      FreeAndNil(Clon);
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ConstruirColumnasDinamicas;
var
  i: Integer;
  Col: TcxGridDBColumn;
  MaxAtributos: Integer;
  IndiceBase:Integer;
  Propiedades: TcxButtonEditProperties;
  Boton: TcxEditButton;
begin
  MaxAtributos := 5;
  IndiceBase := tvArticulo.Index;
  tvLineasOpe.BeginUpdate;
  try
    for i := 1 to MaxAtributos do
    begin
      Col := tvLineasOpe.CreateColumn;
      Col.Name := 'tvAtributoDyn' + IntToStr(i);
      Col.Tag := i;
      Col.DataBinding.FieldName := 'ATTR' + IntToStr(i) + '_VALOR';
      Col.Caption := '-';
      Col.Visible := False;
      Col.Width := 80;
      // TcxButtonEdit con un boton bkEllipsis (que cambiamos a bkGlyph en
      // InitEdit cuando el AV actual tiene swatch en la paleta basica). El
      // click abre SeleccionarAvConPaleta — mismo patron que inMtoInventarios.
      Col.PropertiesClass := TcxButtonEditProperties;
      Propiedades := TcxButtonEditProperties(Col.Properties);
      Propiedades.ReadOnly := True;
      Propiedades.Buttons.Clear;
      Boton := Propiedades.Buttons.Add;
      Boton.Default := True;
      Boton.Kind := bkEllipsis;
      Propiedades.OnButtonClick := FSelectorAtributos.SeleccionarAtributo;
      Col.Index := IndiceBase + i;
    end;
  finally
    tvLineasOpe.EndUpdate;
  end;
end;

procedure TEditorLineasCajaVcl.PoblarAtributosLineasDeposito;
var
  aNombres: TNombresAtributosCaja;
  art, sku: string;
  i: Integer;
begin
  // Rellena Color/Talla (ATTR*_NOMBRE/_VALOR) de cada prenda apartada que se
  // ha cargado con F2, igual que haria un escaneo normal, para que se vean
  // sin entrar linea por linea. La carga de depositos no los puebla (esta
  // optimizada para no lanzar queries por fila).
  DatosCaja.cdsLineas.DisableControls;
  FActualizandoDepositos := True;
  try
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      // Solo las prendas ('S'); el abono ('A') no tiene Color/Talla.
      if DatosCaja.cdsLineas.FieldByName(
                                     'VIENE_DE_DEPOSITO').AsString = 'S' then
      begin
        art := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
        sku := DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
        aNombres :=
          FRepositorioArticulos.ListarNombresAtributosArticulo(art);
        DatosCaja.cdsLineas.Edit;
        DatosCaja.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := Length(aNombres);
        for i := 1 to 5 do
        begin
          if i <= Length(aNombres) then
            DatosCaja.cdsLineas.FieldByName(
              'ATTR' + IntToStr(i) + '_NOMBRE').AsString := aNombres[i - 1]
          else
            DatosCaja.cdsLineas.FieldByName(
              'ATTR' + IntToStr(i) + '_NOMBRE').AsString := '';
        end;
        RellenarAtributosDesdeSku(sku);
        DatosCaja.cdsLineas.Post;
      end;
      DatosCaja.cdsLineas.Next;
    end;
  finally
    FActualizandoDepositos := False;
    DatosCaja.cdsLineas.EnableControls;
  end;
end;

procedure TEditorLineasCajaVcl.MostrarColumnasCuentaCliente(
  AActivar: Boolean);
var
  Clon: TClientDataSet;
  Col: TcxGridDBColumn;
  Nombre: string;
  i: Integer;
begin
  // Vista de cuenta de cliente (F2): sobran las columnas % y Menos y faltan
  // Color/Talla. AActivar=True monta esa vista; False vuelve a la normal (el
  // escaneo reactiva los atributos por linea).
  tvLineasOpe.BeginUpdate;
  try
    tvDescuento.Visible := not AActivar;
    tvDescuentoMenos.Visible := not AActivar;
    if AActivar then
    begin
      Clon := TClientDataSet.Create(nil);
      try
        Clon.CloneCursor(DatosCaja.cdsLineas, True);
        for i := 1 to 5 do
        begin
          Col := ObtenerColumnaPorTag(i);
          if Col <> nil then
          begin
            // Caption = nombre del atributo de la primera prenda que lo tenga.
            Nombre := '';
            Clon.First;
            while (Nombre = '') and not Clon.Eof do
            begin
              if Clon.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
                Nombre := Clon.FieldByName(
                  'ATTR' + IntToStr(i) + '_NOMBRE').AsString;
              Clon.Next;
            end;
            Col.Options.Editing := False;
            if Nombre <> '' then
            begin
              Col.Caption := Nombre;
              Col.Visible := True;
            end
            else
            begin
              Col.Caption := '-';
              Col.Visible := False;
            end;
          end;
        end;
      finally
        FreeAndNil(Clon);
      end;
    end
    else
    begin
      // Reseteamos los atributos e invalidamos la cache para que el proximo
      // escaneo los vuelva a pintar segun el articulo.
      for i := 1 to 5 do
      begin
        Col := ObtenerColumnaPorTag(i);
        if Col <> nil then
        begin
          Col.Visible := False;
          Col.Caption := '-';
          Col.Options.Editing := False;
        end;
      end;
      FUltimoArticuloPadre := '';
    end;
  finally
    tvLineasOpe.EndUpdate;
  end;
end;

procedure TEditorLineasCajaVcl.ComprobarFocoRegistro(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  var AAllow: Boolean);
var
  CodArticulo, SkuActual: string;
begin
  if (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
    end
    else
    begin
      SkuActual := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
      if SkuActual = '' then
         SkuActual := CodArticulo;
      if ConsolidarSiExiste(SkuActual) then
      begin
        // La linea de trabajo ya puede estar grabada: Cancel no la quita.
        // Si tras cancelar sigue ahi con el mismo SKU consolidado, la
        // borramos para no duplicar (mismo patron que en Validate).
        if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          DatosCaja.cdsLineas.Cancel;
        if not DatosCaja.cdsLineas.IsEmpty then
          if DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString
               = SkuActual then
            DatosCaja.cdsLineas.Delete;
      end;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ComprobarEdicion(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  if (DatosCaja <> nil) and
     DatosCaja.cdsLineas.Active and
     not DatosCaja.cdsLineas.IsEmpty then
  begin
    // Si la línea es la prenda base del depósito
    if DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
    begin
      // Solo permitimos editar la columna de Cantidad/Unidades
      if AItem <> tvUds then
        AAllow := False;
    end
    // Si la línea es el abono (anticipo de dinero, marcado con 'A' según tu
    //UniDataCaja)
    else if DatosCaja.cdsLineas.FieldByName(
      'VIENE_DE_DEPOSITO').AsString = 'A' then
    begin
      // No permitimos tocar absolutamente nada de la línea del abono
      AAllow := False;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ProcesarTeclaEdicion(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var AKey: Word; AShift: TShiftState);
begin
  // La decision (busqueda incremental, retirada de la linea en blanco,
  // confirmacion del articulo y destino del foco) vive en
  // inLibCajaOpePresentacion; aqui solo se le da el editor en curso.
  FTecladoLinea.Rejilla.FijarEdicion(AItem, AEdit);
  if FTecladoLinea.Procesador.Procesar(
       TraducirTeclaLineaCaja(AKey)) then
    AKey := 0;
end;

procedure TEditorLineasCajaVcl.CambiarRegistroEnfocado(
  Sender: TcxCustomGridTableView; ARegistroAnterior,
  ARegistroActual: TcxCustomGridRecord; ACambiaRegistroNuevo: Boolean);
var
  sCodPadre, sSku, VieneDeDep: string;
  EsDeposito: boolean;
begin
  if DatosCaja.cdsLineas.Active and not FActualizandoDepositos and
     (ARegistroActual <> nil) then
  begin
    if ARegistroActual.IsNewItemRecord then
    begin
      btnF3.Enabled := True;
      btnF8.Enabled := True;
      SolicitarFocoArticuloLineaNueva;
    end
    else if not DatosCaja.cdsLineas.IsEmpty then
    begin
      VieneDeDep := DatosCaja.cdsLineas.FieldByName(
        'VIENE_DE_DEPOSITO').AsString;
      EsDeposito := (VieneDeDep = 'S') or (VieneDeDep = 'A');
      btnF3.Enabled := not EsDeposito;
      btnF8.Enabled := not EsDeposito;
      sCodPadre := DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString;
      sSku := DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString;
      if sCodPadre <> '' then
        ActualizarColumnasDinamicas(sCodPadre);
      if (Pos('/', sSku) > 0) and
         (Trim(DatosCaja.cdsLineas.FieldByName(
           'ATTR1_VALOR').AsString) = '') then
        RellenarAtributosDesdeSku(sSku);
      if Trim(sSku) <> '' then
        ConsultarStock(sSku)
      else if Trim(sCodPadre) <> '' then
        ConsultarStock(sCodPadre);
    end;
  end;
end;


procedure TEditorLineasCajaVcl.InicializarEdicion(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  BE        : TcxButtonEdit;
  AvActual  : string;
  NombreAtb : string;
  IdVa      : string;
  Mapa      : TDictionary<string, string>;
  Info      : TInfoBasico;
  Btn       : TcxEditButton;
begin
  // Estilo Excel: al entrar en una celda, teclear sustituye su contenido.
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
  // Columnas de atributo dinamico (Color, Talla, ...). Mismo patron que
  // inMtoInventarios:
  //   (1) Si el AV actual tiene color en la paleta basica, el boton muestra
  //       un glyph con el cuadradito; si no, vuelve a bkEllipsis.
  //   (2) Si la celda esta vacia, OnEnter dispara el popup automaticamente
  //       (sustituye al antiguo Combo.DroppedDown via ForzarDespliegue).
  if (AItem.Tag >= 1) and (AItem.Tag <= 5) then
  begin
    if AEdit is TcxButtonEdit then
    begin
      BE := TcxButtonEdit(AEdit);
      BE.Tag := AItem.Tag;
      if BE.Properties.Buttons.Count > 0 then
      begin
        Btn := BE.Properties.Buttons[0];

        AvActual  := '';
        NombreAtb := '';
        if DatosCaja.cdsLineas.Active
           and (not DatosCaja.cdsLineas.IsEmpty) then
        begin
          AvActual  := DatosCaja.cdsLineas.FieldByName(
                         'ATTR' + IntToStr(AItem.Tag) + '_VALOR').AsString;
          NombreAtb := DatosCaja.cdsLineas.FieldByName(
                         'ATTR' + IntToStr(AItem.Tag) + '_NOMBRE').AsString;
        end;

        IdVa := '';
        Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
        if Mapa <> nil then
          Mapa.TryGetValue(UpperCase(Trim(NombreAtb)), IdVa);

        Info := Default(TInfoBasico);
        if (IdVa <> '') and (Trim(AvActual) <> '') then
          ObtenerInfoBasico(ConexionPrincipal,IdVa, AvActual, Info);

        if Info.EsValido and
           PintarSwatchEnBitmap(FBmpSwatchBoton, Info, 14) then
        begin
          Btn.Glyph.Assign(FBmpSwatchBoton);
          Btn.Kind := bkGlyph;
        end
        else
          Btn.Kind := bkEllipsis;

        if Trim(AvActual) = '' then
          BE.OnEnter := FSelectorAtributos.AbrirPopupEnEntrada
        else
          BE.OnEnter := nil;
      end;
    end;
  end;
  if AItem = tvArticulo then
  begin
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange := CambiarArticulo;
    var ValorActual :=
                    AItem.GridView.Controller.FocusedRecord.Values[AItem.Index];
    if (not VarIsNull(ValorActual)) and (Trim(VarToStr(ValorActual)) <> '') then
    begin
       if AEdit is TcxCustomTextEdit then
       begin
          TcxCustomTextEdit(AEdit).Text := VarToStr(ValorActual);
          TcxCustomTextEdit(AEdit).SelectAll;
       end;
    end
    else
    begin
       dsBusq.DataSet := nil;
       FResultadoBusquedaIncremental := nil;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ProcesarTeclaRejilla(Sender: TObject;
  var AKey: Word; AShift: TShiftState);
begin
  if (AKey = VK_ESCAPE) then
  begin
    if DatosCaja.cdsLineas.State = dsInsert then
    begin
      DatosCaja.cdsLineas.Cancel;
      AKey := 0;
    end;
    if DatosCaja.cdsLineas.RecordCount > 0 then
    begin
      if MessageDlg(SPreguntaCancelarVentaCaja,
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        FCerrarFormulario();
      end;
    end
    else
    begin
      FCerrarFormulario();
    end;
    AKey := 0;
  end;
  if (AKey = VK_UP) and (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
      AKey := 0;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.PulsarRejilla(Sender: TObject;
  AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  // No cambiar la celda elegida; solo crear una linea si no existe ninguna.
  if (AButton = mbLeft) and DatosCaja.cdsLineas.IsEmpty then
    AsegurarLineaNueva;
end;

procedure TEditorLineasCajaVcl.EntrarRejilla(Sender: TObject);
begin
  if DatosCaja.cdsLineas.Active then
  begin
    if DatosCaja.cdsLineas.State = dsBrowse then
    begin
      DatosCaja.cdsLineas.Append;
      tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      tvLineasOpe.Controller.EditingController.ShowEdit;
    end;
    jvEnterTab.EnterAsTab := False;
  end;
end;

procedure TEditorLineasCajaVcl.SalirRejilla(Sender: TObject);
begin
  jvEnterTab.EnterAsTab := True;
end;

procedure TfrmMtoOpeCaja.actBuscarEmpleadosExecute(Sender: TObject);
begin
  EjecutarBusquedaContextualCajaVcl(
    CrearContextoBusquedaCajaVcl(Self));
end;

procedure TfrmMtoOpeCaja.actCargarCtaExecute(Sender: TObject);
begin
  btnF2Click(Sender);
end;

procedure TfrmMtoOpeCaja.btnF61Click(Sender: TObject);
begin
  CargarDevolucionPorTicket;
end;

procedure TfrmMtoOpeCaja.CargarDevolucionPorTicket;
var
  Seleccion: TOrigenDevolucionCajaVcl;
begin
  // F4: localizar el ticket de origen (escaneo del EAN-13, operación o
  // documento) y cargar sus artículos en negativo. El usuario borra las
  // líneas que no se devuelvan.
  if not OperacionVentaVacia(DatosCaja.cdsLineas) then
    ShowMessage(SErrorDevolucionTicketOperacionEnCurso)
  else
  begin
    if SeleccionarTicketDevolucionCajaVcl(
         Self,
         FDependencias.RepositorioConsultas,
         FCodigoEmpresa,
         FCodigoAlmacen,
         FCodigoCaja,
         Seleccion) then
    begin
      FSerieOrigenDev := Seleccion.Serie;
      FNumeroOrigenDev := Seleccion.Numero;
      FEmpresaOrigenDev := Seleccion.Empresa;
      FAlmacenOrigenDev := Seleccion.Almacen;
      if SameText(Seleccion.Empresa, FCodigoEmpresa) then
      begin
        CargarRectificacion(
          Seleccion.Serie,
          Seleccion.Numero,
          trcDiferencias,
          tmrMantenerOriginales);
        GridRecalc(
          ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
          tvLineasOpe,
          DatosCaja.cdsLineas,
          DatosCaja.cdsCabecera,
          ActualizarLabelTotal);
        FEditorLineas.AsegurarLineaNueva;
      end
      else
      begin
        ShowMessage(SAvisoDevolucionTicketOtraEmpresa);
        CargarDevolucion(
          Seleccion.Serie,
          Seleccion.Numero,
          Seleccion.Empresa,
          Seleccion.Almacen);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.CargarDevolucion(
  const ASerie, ANumero, AEmpresaOrigen,
  AAlmacenOrigen: string);
begin
  // Devolucion comercial: copia la venta en negativo y conserva el ticket
  // de origen para la operacion DV, pero no crea una rectificativa fiscal.
  FSerieOrigenDev := ASerie;
  FNumeroOrigenDev := ANumero;
  FEmpresaOrigenDev := AEmpresaOrigen;
  FAlmacenOrigenDev := AAlmacenOrigen;
  FSerieRectifica := '';
  FNumeroRectifica := '';
  FTipoRectificativa := trcNinguna;
  FTratamientoMovRectificativa := tmrMantenerOriginales;
  FMotivoDevolucion := '';
  FDependencias.ServicioRectificacion.CargarDevolucion(
    ASerie,
    ANumero,
    DatosCaja.cdsCabecera,
    DatosCaja.cdsLineas);
  if FCaptionPrevio = '' then
    FCaptionPrevio := Caption;
  Caption := FCaptionPrevio + Format(
    SCaptionDevolucionTicketDe, [ASerie, ANumero, AAlmacenOrigen]);
  lblTipoRectificativa.Caption := '';
  lblTipoRectificativa.Visible := False;
  GridRecalc(
    ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
    tvLineasOpe,
    DatosCaja.cdsLineas,
    DatosCaja.cdsCabecera,
    ActualizarLabelTotal);
  FEditorLineas.AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.WMPreguntarVentaOrigen(var Msg: TMessage);
var
  Seleccion: TOrigenDevolucionCajaVcl;
  sSku: string;
begin
  // Devolución sin código de barras: al meter una prenda en negativo se
  // proponen las ventas que la contienen para elegir el ticket de
  // origen. Cancelar es válido: la devolución queda sin origen (DV).
  sSku := FSkuPendienteVentaOrigen;
  FSkuPendienteVentaOrigen := '';
  if (sSku <> '') and
     (FNumeroRectifica = '') and
     (Trim(FSerieOrigenDev) = '') and
     (not FPreguntandoVentaOrigen) then
  begin
    FPreguntandoVentaOrigen := True;
    try
      if SeleccionarVentaOrigenCajaVcl(
           Self,
           FDependencias.RepositorioConsultas,
           sSku,
           FCodigoEmpresa,
           Seleccion) then
      begin
        FSerieOrigenDev := Seleccion.Serie;
        FNumeroOrigenDev := Seleccion.Numero;
        FEmpresaOrigenDev := Seleccion.Empresa;
        FAlmacenOrigenDev := Seleccion.Almacen;
        if SameText(Seleccion.Empresa, FCodigoEmpresa) then
        begin
          // Rectificativa por diferencias del ticket elegido: solo se
          // marca la referencia; las líneas las decide el usuario.
          FSerieRectifica := Seleccion.Serie;
          FNumeroRectifica := Seleccion.Numero;
          FTipoRectificativa := trcDiferencias;
          FTratamientoMovRectificativa := tmrMantenerOriginales;
          if FCaptionPrevio = '' then
            FCaptionPrevio := Caption;
          Caption := FCaptionPrevio +
            '  —  RECTIFICATIVA POR DIFERENCIAS de ' +
            Seleccion.Serie + '\' + Seleccion.Numero;
          lblTipoRectificativa.Caption := Format(
            SCaptionRectificativaTipo, ['POR DIFERENCIAS']);
          lblTipoRectificativa.Visible := True;
        end
        else
        begin
          if FCaptionPrevio = '' then
            FCaptionPrevio := Caption;
          Caption := FCaptionPrevio + Format(
            SCaptionDevolucionTicketDe,
            [Seleccion.Serie, Seleccion.Numero, Seleccion.Almacen]);
        end;
      end;
    finally
      FPreguntandoVentaOrigen := False;
    end;
  end;
end;

function TfrmMtoOpeCaja.PedirMotivoDevolucionSiProcede: Boolean;
begin
  Result := PedirMotivoDevolucionCajaVcl(
    Self,
    DatosCaja.cdsLineas,
    FMotivoDevolucion);
end;

procedure TfrmMtoOpeCaja.btnF10Click(Sender: TObject);
begin
  FPresentacion.AbrirBuscarModificar;
end;

procedure TfrmMtoOpeCaja.actBuscarModificarExecute(Sender: TObject);
begin
  btnF10Click(Sender);
end;

procedure TfrmMtoOpeCaja.actEliminarLineaExecute(Sender: TObject);
var
  VieneDeDep: string;
  bEliminar: Boolean;
begin
  bEliminar := True;
  // NUEVO: Bloqueo de borrado
  if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
  begin
    VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
    if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
    begin
      ShowMessage(SErrorLineaDepositoCajaNoEliminable);
      bEliminar := False;
    end;
  end;
  if bEliminar then
  begin
    if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
      DatosCaja.cdsLineas.Cancel
    else if DatosCaja.cdsLineas.State = dsBrowse then
      DatosCaja.cdsLineas.Delete;
    FEditorLineas.AsegurarLineaNueva;
  end;
end;

procedure TfrmMtoOpeCaja.actGuardarLayoutExecute(Sender: TObject);
begin
  FPresentacion.GuardarLayout;
end;

procedure TfrmMtoOpeCaja.actAbrirArticulosExecute(Sender: TObject);
var
  sCodArt: string;
begin
  sCodArt := '';
  if Assigned(DatosCaja) and
     Assigned(DatosCaja.cdsLineas) and
     DatosCaja.cdsLineas.Active then
    sCodArt := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
  ShowMto(Application.MainForm, 'Articulos', sCodArt);
end;

procedure TfrmMtoOpeCaja.actSalirExecute(Sender: TObject);
begin
  if (DatosCaja.cdsLineas.Active) and (not DatosCaja.cdsLineas.IsEmpty) then
  begin
    if MessageDlg(SPreguntaBorrarVentaCaja,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;
      Close;
    end;
  end
  else
  begin
    Close;
  end;
end;

procedure TEditorLineasCajaVcl.ActualizarColumnasDinamicas(
  const AArticulo: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
  aNombresAtributos: TNombresAtributosCaja;
  Cacheado: Boolean;
begin
  // --- OPTIMIZACIÓN: Si es el mismo tipo de artículo, no repintamos ---
  Cacheado := SameText(AArticulo, FUltimoArticuloPadre);
  if not Cacheado then
  begin
    FUltimoArticuloPadre := AArticulo;
  SetLength(aNombresAtributos, 0);
  if (AArticulo <> '') and (AArticulo <> 'ACUENTA') then
  begin
    aNombresAtributos :=
      FRepositorioArticulos.ListarNombresAtributosArticulo(
        AArticulo);
  end;
  FNumAtributosActual := Length(aNombresAtributos);
  // Solo tocamos la memoria del dataset si estamos escaneando algo nuevo
  if DatosCaja.cdsLineas.Active and
     (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger :=
      Length(aNombresAtributos);
  end;
  tvLineasOpe.BeginUpdate;
  try
    for i := 1 to 5 do
    begin
      Col := ObtenerColumnaPorTag(i);
      if Col <> nil then
      begin
        if i <= Length(aNombresAtributos) then
        begin
          Col.Caption := aNombresAtributos[i - 1];
          Col.Visible := True;
          Col.Options.Editing := True;
          if DatosCaja.cdsLineas.Active and
             (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
          begin
            DatosCaja.cdsLineas.FieldByName(
              'ATTR' + IntToStr(i) + '_NOMBRE').AsString :=
              aNombresAtributos[i - 1];
          end;
        end
        else
        begin
          Col.Visible := False;
          Col.Options.Editing := False;
          Col.Caption := '-';
        end;
      end;
    end;
  finally
    tvLineasOpe.EndUpdate;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.ActualizarLabelTotal(Sender: TObject;
  NuevoTotal: Currency);
begin
  lblTotal.Caption := Format(SCaptionTotalImporte, [NuevoTotal]);
end;

procedure TEditorLineasCajaVcl.RecalcularLineas;
begin
  GridRecalc(
    ConexionPrincipal,
    FRepositorioFacturas,
    nil,
    tvLineasOpe,
    DatosCaja.cdsLineas,
    DatosCaja.cdsCabecera,
    ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.btnCodigoClienteExit(Sender: TObject);
var
  Edit: TcxCustomEdit;
begin
  if Sender is TcxCustomEdit then
  begin
    Edit := TcxCustomEdit(Sender);
    if Edit.EditModified then
    begin
      Edit.ValidateEdit(True);
      Edit.EditModified := False;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomCliente: string;
  sCodigo: string;
  Totales: TFacturaTotales;
  Cliente: TClienteCaja;
begin
  // Durante un escaneo no validamos el cliente: el foco se mueve a la rejilla
  // y el campo pudo quedar con la rafaga; lo da por bueno y no molesta.
  if FEntrada.ProcesandoLectura then
    Error := False
  else if not FValidandoCliente then
  begin
    FValidandoCliente := True;
    try
      // 1. Limpieza de los depositos del cliente anterior. La regla y
      //    las escrituras de cabecera viven en inLibCajaVentaCliente;
      //    aqui quedan el grid, las etiquetas y el recalculo.
      LimpiarLineasDeposito(DatosCaja.cdsLineas);
      // 2. Busqueda y asignacion del nuevo cliente.
      sCodigo := VarToStr(DisplayValue);
      if Trim(sCodigo) = '' then
      begin
        lblNombreCliente.Caption := SCaptionVentaContado;
        EscribirCabeceraVentaContado(DatosCaja.cdsCabecera,
                                     DatosCaja.GetTarifaDefault);
        lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
        Error := False;
      end
      else
      begin
        sNomCliente := '';
        if FDependencias.RepositorioConsultas.ObtenerCliente(
             sCodigo,
             Cliente) then
        begin
          sNomCliente := Cliente.RazonSocial;
          EscribirCabeceraClienteVenta(DatosCaja.cdsCabecera, Cliente);
          lblTarifa.Caption :=
            Cliente.TarifaArticulo;
          // Cliente con depositos: solo se cargan solos con el
          // parametro de autocarga activo.
          if DebeCargarDepositosCliente(
               Cliente.EsPermiteDeuda,
               ParametrosCaja.GetBool(
                 'vgerAutoLoadDepositos',
                 False)) then
          begin
            tvLineasOpe.BeginUpdate;
            FEditorLineas.ActualizandoDepositos := True;
            try
              DatosCaja.CargarDepositosCliente(
                sCodigo);
            finally
              tvLineasOpe.EndUpdate;
              FEditorLineas.ActualizandoDepositos := False;
            end;
          end;
        end;
        if sNomCliente = '' then
        begin
          Error := True;
          ErrorText := SErrorCodigoClienteCajaNoExiste;
        end
        else
        begin
          Error := False;
          lblNombreCliente.Caption := sNomCliente;
          ErrorText := '';
        end;
      end;
      // 3. Proteccion contra dataset vacio y recalculo final.
      if DatosCaja.cdsLineas.Active then
      begin
        tvLineasOpe.DataController.UpdateItems(False);
        // 2º Ponemos el foco en la línea nueva
        FEditorLineas.AsegurarLineaNueva;
        // 3º Como paso final absoluto, pisamos la etiqueta leyendo la
        // memoria contable
        Totales := TFacturaTotales.Create(
          ConexionPrincipal,
          FLecturas.RepositorioFacturas,
          DatosCaja.cdsCabecera,
          DatosCaja.cdsLineas,
          nil,
          RegistroLog);
        try
          Totales.ProcesarFacturaCompleta;
          ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
        finally
          FreeAndNil(Totales);
        end;
      end;
    finally
      FValidandoCliente := False;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.AsegurarLineaNueva;
begin
  if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active then
  begin
    // 1. Si no hay líneas en absoluto, insertamos una.
    if DatosCaja.cdsLineas.IsEmpty then
    begin
      DatosCaja.cdsLineas.Append;
    end
    // 2. Si ya hay líneas, verificamos que no estemos YA insertando una nueva
    else if not (DatosCaja.cdsLineas.State = dsInsert) then
    begin
      // Solo añadimos si la línea actual tiene un código de artículo.
      // Así evitamos crear líneas en blanco repetidas si hacen varios clics.
      if Trim(DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString) <> '' then
      begin
        DatosCaja.cdsLineas.Append;
      end;
    end;
    // 3. Forzamos el foco visual a la celda del Artículo, lista para escanear
    if cxgrdLineasOpe.CanFocus then
      cxgrdLineasOpe.SetFocus;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
    SolicitarFocoArticuloLineaNueva;
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoExit(Sender: TObject);
begin
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).ValidateEdit(True);
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarEmpleadoCajaVcl(CrearContextoBusquedaCajaVcl(Self));
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarClienteCajaVcl(CrearContextoBusquedaCajaVcl(Self));
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomEmpleado: string;
  sCodigo: string;
  Empleado: TEmpleadoCaja;
  Encontrado: Boolean;
begin
  // Durante un escaneo no validamos el empleado (mismo motivo que en cliente).
  if FEntrada.ProcesandoLectura then
  begin
    Error := False;
  end;
  if not FEntrada.ProcesandoLectura then
  begin
    sCodigo := VarToStr(DisplayValue);
    Encontrado :=
      (Trim(sCodigo) <> '') and
      DatosCaja.BuscarYMostrarNombre(
        'EMPLEADOS',
        sCodigo,
        sNomEmpleado);
    if Encontrado then
    begin
      Empleado.Codigo := sCodigo;
      Empleado.Nombre := sNomEmpleado;
    end;
    if (not Encontrado) and (Trim(sCodigo) <> '') then
    begin
      Encontrado :=
        FDependencias.RepositorioConsultas.BuscarEmpleado(
          sCodigo,
          Empleado);
    end;
    if Encontrado then
    begin
      DisplayValue := Empleado.Codigo;
      lblNombreEmpleado.Caption := Empleado.Nombre;
      DatosCaja.cdsCabecera.Edit;
      DatosCaja.cdsCabecera.FieldByName(
        'CODIGO_CAJERO_FAC').AsString :=
        Empleado.Codigo;
      Error := False;
      ErrorText := '';
    end
    else
    begin
      Error := True;
      ErrorText := SErrorEmpleadoCajaNoEncontrado;
      lblNombreEmpleado.Caption := '';
      if DatosCaja.cdsCabecera.Active and
         not DatosCaja.cdsCabecera.IsEmpty then
      begin
        DatosCaja.cdsCabecera.Edit;
        DatosCaja.cdsCabecera.FieldByName(
          'CODIGO_CAJERO_FAC').Clear;
      end;
    end;
  end;
//  tvLineasOpe.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.ProcesarResultadoCierre(
  const AResultado: TResultadoCierreVenta;
  AEnviarEmail: Boolean;
  const AEmailEnvio: string);
var
  sMensajeCorreo: string;
begin
  if FNumeroRectifica <> '' then
  begin
    if FTipoRectificativa = trcSustitutiva then
      RefrescarConsultasOperacionesCaja;
    FSerieRectifica := '';
    FNumeroRectifica := '';
    FTipoRectificativa := trcNinguna;
    FTratamientoMovRectificativa := tmrMantenerOriginales;
    if FCaptionPrevio <> '' then
      Caption := FCaptionPrevio;
  end;
  // Devolución con origen sin rectificativa (otra empresa): restaurar
  // el título y limpiar SIEMPRE el estado de devolución (motivo y
  // ticket de origen) tras grabar.
  if (FNumeroRectifica = '') and
     (Trim(FSerieOrigenDev) <> '') and
     (FCaptionPrevio <> '') then
    Caption := FCaptionPrevio;
  // Limpiar el estado de devolucion (motivo y ticket de origen).
  FMotivoDevolucion := '';
  FSerieOrigenDev := '';
  FNumeroOrigenDev := '';
  FEmpresaOrigenDev := '';
  FAlmacenOrigenDev := '';
  FSkuPendienteVentaOrigen := '';
  if AResultado.CodigoValeGenerado <> '' then
  begin
    ShowMessage(Format(
      SInfoValeCajaEntregar,
      [AResultado.CodigoValeGenerado]));
  end;
  if AEnviarEmail then
  begin
    Screen.Cursor := crHourGlass;
    try
      if EnviarDocumentacionOperacion(
        ParametrosApp,
        PreviewTicket,
        UnidadesMedida,
        FDependenciasPantalla.TraspasoTicket,
        FDependenciasPantalla.Tickets,
        RegistroLog,
        ConexionPrincipal,
        CrearCorreoTicketsLecturas(ConexionPrincipal).
          CargarDatosOperacion(
            FCodigoEmpresa,
            FCodigoAlmacen,
            FCodigoCaja,
            AResultado.NumeroGenerado),
        FCodigoEmpresa,
        FCodigoAlmacen,
        FCodigoCaja,
        AResultado.NumeroGenerado,
        AEmailEnvio,
        sMensajeCorreo) then
      begin
        ShowMessage(sMensajeCorreo);
      end
      else
      begin
        ShowMessage(Format(
          SErrorCorreoOperacionCajaNoEnviado,
          [sMensajeCorreo]));
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
  PrepararValores(
    FCodigoEmpresa,
    FCodigoAlmacen,
    FCodigoCaja,
    FFecha);
end;

procedure TfrmMtoOpeCaja.btnF12Click(Sender: TObject);
begin
  TCoordinadorCierreVentaCajaVcl.Ejecutar(
    CrearContextoCierreVentaCajaVcl(Self));
end;

function TfrmMtoOpeCaja.OperacionVacia: Boolean;
begin
  Result := OperacionVentaVacia(DatosCaja.cdsLineas);
end;

function TfrmMtoOpeCaja.FormularioCaja: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmMtoOpeCaja.CargarRectificacion(
  const ASerie, ANumero: string;
  ATipoRectificativa: TTipoRectificativaCaja;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa);
var
  Resultado: TResultadoRectificacionCaja;
begin
  Resultado := FDependencias.ServicioRectificacion.Cargar(
    ASerie,
    ANumero,
    ATipoRectificativa,
    ATratamientoMovimientos,
    DatosCaja.cdsCabecera,
    DatosCaja.cdsLineas);
  FSerieRectifica := Resultado.Serie;
  FNumeroRectifica := Resultado.Numero;
  FTipoRectificativa := Resultado.Tipo;
  FTratamientoMovRectificativa :=
    Resultado.TratamientoMovimientos;
  if FCaptionPrevio = '' then
  begin
    FCaptionPrevio := Caption;
  end;
  Caption :=
    FCaptionPrevio +
    '  —  RECTIFICATIVA ' +
    Resultado.DescripcionTipo +
    ' de ' +
    Resultado.Serie +
    '\' +
    Resultado.Numero;
  lblTipoRectificativa.Caption := Format(SCaptionRectificativaTipo,
    [Resultado.DescripcionTipo]);
  lblTipoRectificativa.Visible := True;
end;

procedure TfrmMtoOpeCaja.CargarDepositosF2;
var
  sCodigoCliente: string;
  Totales: TFacturaTotales;
begin
  sCodigoCliente :=
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString;
  if (Trim(sCodigoCliente) = '') or (Trim(sCodigoCliente) = '0') then
  begin
    ShowMessage(SErrorClienteDepositosCajaNoSeleccionado);
  end
  else
  begin
  // 1. Matar la edición activa limpiamente (Evita el error de
  // Artículo no encontrado en la línea en blanco)
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
  begin
    tvLineasOpe.Controller.EditingController.HideEdit(False);
  end;
  // 2. Cancelar línea a medias si la hubiera
  if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
    DatosCaja.cdsLineas.Cancel;
  // 3. Limpieza y carga de depósitos de forma silenciosa
  DatosCaja.cdsLineas.DisableControls;
  tvLineasOpe.BeginUpdate;
  FEditorLineas.ActualizandoDepositos := True;
  try
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      if (DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S')
                                                                              or
         (DatosCaja.cdsLineas.FieldByName(
                                       'VIENE_DE_DEPOSITO').AsString = 'A') then
        DatosCaja.cdsLineas.Delete
      else
        DatosCaja.cdsLineas.Next;
    end;
    DatosCaja.CargarDepositosCliente(sCodigoCliente);
  finally
    DatosCaja.cdsLineas.EnableControls;
    tvLineasOpe.EndUpdate;
    FEditorLineas.ActualizandoDepositos := False;
  end;
  tvLineasOpe.DataController.UpdateItems(False);
  // Modo cuenta de cliente (F2): rellenamos Color/Talla de cada prenda y
  // ajustamos las columnas (fecha de la operacion visible; % y Menos ocultas)
  // antes de añadir la linea en blanco de escaneo.
  FEditorLineas.PoblarAtributosLineasDeposito;
  tvFechaOperacion.Visible := True;
  FEditorLineas.MostrarColumnasCuentaCliente(True);
  // 5. Preparamos la línea en blanco para seguir escaneando (ahora ya no rompe
  // la caché)
  FEditorLineas.AsegurarLineaNueva;
  // 6. Calculamos el total SIEMPRE AL FINAL, forzando la lectura de memoria
  // interna
  Totales := TFacturaTotales.Create(
    ConexionPrincipal,
    FLecturas.RepositorioFacturas,
    DatosCaja.cdsCabecera,
    DatosCaja.cdsLineas,
    nil,
    RegistroLog);
  try
    Totales.ProcesarFacturaCompleta;
    ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
  finally
    FreeAndNil(Totales);
    end;
  end;
end;

procedure TfrmMtoOpeCaja.btnF2Click(Sender: TObject);
begin
  CargarDepositosF2;
end;

function TfrmMtoOpeCaja.CrearOperacionCajaHermana: TfrmMtoOpeCaja;
begin
  Result := TfrmMtoOpeCaja.Create(
    Application,
    TContextoAutorizacionPantalla.Crear(Permisos),
    FDependenciasPantalla);
end;

procedure TfrmMtoOpeCaja.btnF5Click(Sender: TObject);
var
  i: Integer;
  NextIndex: Integer;
  TargetForm: TfrmMtoOpeCaja;
  Found: Boolean;
  const MAX_OPERACIONES = 5;
begin
  NextIndex := Self.Tag + 1;
  if NextIndex > MAX_OPERACIONES then
    NextIndex := 1;
  Found := False;
  TargetForm := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Screen.Forms[i] is TfrmMtoOpeCaja then
    begin
      if Screen.Forms[i].Tag = NextIndex then
      begin
        TargetForm := TfrmMtoOpeCaja(Screen.Forms[i]);
        Found := True;
        Break;
      end;
    end;
  end;
  if Found then
  begin
    TargetForm.Show;
    TargetForm.BringToFront;
    if TargetForm.WindowState = wsMinimized then
      TargetForm.WindowState := wsNormal;
  end
  else
  begin
    TargetForm := CrearOperacionCajaHermana;
    TargetForm.PopupParent := Self.PopupParent;
    TargetForm.Tag := NextIndex;
    TargetForm.Caption := Format(STituloOperacionNCajaReal,
                                 [NextIndex, Self.FCodigoCaja]);
    TargetForm.PrepararValores(Self.FCodigoEmpresa,
                               Self.FCodigoAlmacen,
                               Self.FCodigoCaja,
                               Self.FFecha);
    TargetForm.Show;
  end;
  Self.Hide;
end;

procedure TfrmMtoOpeCaja.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMtoOpeCaja.FormDestroy(Sender: TObject);
begin
  if Assigned(DatosCaja) then
  begin
    DatosCaja.OnUpdateTotal := nil;
    DatosCaja.OnRellenarArticulo := nil;
    DatosCaja.OnRellenarAtributos := nil;
    DatosCaja.OnRecalcularLineas := nil;
  end;
  dsBusq.DataSet := nil;
  dsStock.DataSet := nil;
  FreeAndNil(FPresentacion);
  FreeAndNil(FEditorLineas);
  FLecturas.RepositorioFacturas := nil;
  FLecturas.ConsultaStock := nil;
  FIncidenciasSql := nil;
  FDependenciasPantalla := Default(TDependenciasOperacionCaja);
  FDependencias := Default(TContextoDependenciasOperacionCaja);
  FEntrada.Aplicacion := nil;
  FreeAndNil(FEntrada.Lector);
end;

// Carga en imgFotoStock la foto a 300 px del articulo / SKU de la
// linea activa. Lo invoca DsLineasDataChange al cambiar de registro.
procedure TEditorLineasCajaVcl.RefrescarFotoStock;
begin
  FBusqueda.RefrescarFotoStock;
end;

procedure TEditorLineasCajaVcl.NotificarCambioLinea(
  Sender: TObject; AField: TField);
begin
  // Solo refrescamos cuando cambia el registro activo (Field = nil),// no en
  // cada cambio de columna.
  if AField = nil then
  begin
    RefrescarFotoStock;
    if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active and
       (DatosCaja.cdsLineas.State = dsInsert) and
       (Trim(DatosCaja.cdsLineas.FieldByName(
         'CODIGO_ART_FACLIN').AsString) = '') then
      SolicitarFocoArticuloLineaNueva;
  end;
end;

procedure TEditorLineasCajaVcl.SolicitarFocoArticuloLineaNueva;
begin
  if (not FEnfoqueArticuloPendiente) and
     (not (csDestroying in Formulario.ComponentState)) then
  begin
    FEnfoqueArticuloPendiente := True;
    PostMessage(Formulario.Handle, WM_ENFOCAR_ARTICULO_CAJA, 0, 0);
  end;
end;

procedure TEditorLineasCajaVcl.EnfocarArticulo;
begin
  FEnfoqueArticuloPendiente := False;
  if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active and
     (DatosCaja.cdsLineas.State = dsInsert) and
     (Trim(DatosCaja.cdsLineas.FieldByName(
       'CODIGO_ART_FACLIN').AsString) = '') then
  begin
    if cxgrdLineasOpe.CanFocus then
      cxgrdLineasOpe.SetFocus;
    if tvLineasOpe.Controller.EditingController.IsEditing and
       (tvLineasOpe.Controller.EditingItem <> tvArticulo) then
      tvLineasOpe.Controller.EditingController.HideEdit(False);
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
    if not tvLineasOpe.Controller.EditingController.IsEditing then
      tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
end;

// Raiz de composicion del teclado de linea: la rejilla y las operaciones
// de articulo se envuelven en puertos estrechos y el nucleo sin VCL solo
// conoce esos puertos (PLAN_SOLID.md P1).
procedure TEditorLineasCajaVcl.InicializarTecladoLineaCaja;
var
  Operaciones: TOperacionesArticuloLineaCajaVcl;
  PuertoArticulo: IArticuloLineaCaja;
  Avisos: IAvisosOperacionCaja;
begin
  Operaciones := Default(TOperacionesArticuloLineaCajaVcl);
  Operaciones.BuscarArticulo :=
    function: string
    begin
      Result := BuscarArticulo;
    end;
  Operaciones.CargarArticulo :=
    function(const ACodigo: string): Boolean
    begin
      Result := RellenarDatosArticuloEnDataset(ACodigo);
    end;
  Operaciones.MotivoRechazo :=
    function: string
    begin
      Result := FMotivoRechazoArticulo;
    end;
  Operaciones.ArticuloResuelto :=
    function: string
    begin
      Result := FArticuloResueltoEdicion;
    end;
  Operaciones.OlvidarArticuloResuelto :=
    procedure
    begin
      FArticuloResueltoEdicion := '';
    end;
  Operaciones.PrepararColumnasAtributos :=
    function(const AArticulo: string): Integer
    begin
      ActualizarColumnasDinamicas(AArticulo);
      Result := FNumAtributosActual;
    end;
  Operaciones.SkuVendible :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := ValidarSkuParaVenta(ACodigoSku);
    end;
  Operaciones.VolcarAtributosDeSku :=
    procedure(const ACodigoSku: string)
    begin
      RellenarAtributosDesdeSku(ACodigoSku);
    end;
  Operaciones.AvanzarDeLinea :=
    function: Boolean
    begin
      Result := ParametrosCaja.GetBool(
        'vgerMoverLineaIdentif', True);
    end;
  Operaciones.Avisar :=
    procedure(const AMensaje: string)
    begin
      ShowMessage(AMensaje);
    end;
  CrearPuertosArticuloLineaCajaVcl(
    Operaciones, PuertoArticulo, Avisos);
  FTecladoLinea.Rejilla := TRejillaLineaCajaVcl.Create(
    tvLineasOpe,
    tvArticulo,
    tvDescripcion,
    tmrBusq,
    function(AOrden: Integer): TcxGridColumn
    begin
      Result := ObtenerColumnaPorTag(AOrden);
    end);
  FTecladoLinea.Procesador := CrearProcesadorTeclaLineaCaja(
    FTecladoLinea.Rejilla,
    CrearLineaVentaCajaDataSet(DatosCaja.cdsLineas),
    PuertoArticulo,
    Avisos);
end;

procedure TfrmMtoOpeCaja.FormCreate(Sender: TObject);
begin
  inherited;
  InicializarVentanaOperacionCajaVcl(Self);
  // Conserva el texto nuevo aunque la instalacion tenga el catalogo anterior.
  if SameText(lblCargarCta.Caption, 'Cargar cta.') then
    lblCargarCta.Caption := 'Cta. Cliente';
  if SameText(lblBuscarModificar.Caption, 'Buscar/Mod.') then
    lblBuscarModificar.Caption := 'Buscar/Modif.';
  if SameText(lblBusqTick.Caption, 'Búsq Tick') or
     SameText(lblBusqTick.Caption, 'Busq Tick') then
    lblBusqTick.Caption := 'Buscar ticket';
  FPresentacion.AjustarFuentesBotonera;
  FDependenciasPantalla.Validar;
  FLecturas.RepositorioFacturas :=
    CrearRepositorioLecturasFacturaUniDAC(ConexionPrincipal);
  // Detector del lector de codigo de barras (modo restaurar, con anti-eco para
  // la rejilla editable). Los parametros salen de la configuracion de caja.
  FEntrada.Lector := TLectorScanner.Create;
  FEntrada.Lector.Activo := ParametrosCaja.GetBool(
    'vgerScanVelActivo',
    True);
  FEntrada.Lector.UmbralMs := ParametrosCaja.GetInt(
    'vgerScanVelMs',
    40);
  FEntrada.Lector.LongitudMinima := ParametrosCaja.GetInt(
    'vgerScanMinLong',
    4);
  // En caja, la lectura se procesa como artículo desde cualquier columna.
  FEntrada.Lector.OmitirEnRejilla := False;
  FEntrada.Lector.OnCodigoLeido := LectorCodigoLeido;
  FEntrada.Lector.OnLecturaIniciada := LectorLecturaIniciada;
  FEntrada.Lector.OnRejillaEditando := LectorRejillaEditando;
  FEntrada.Lector.OnEsControlRejilla := LectorEsControlRejilla;
  InicializarServiciosOperacionCajaVcl(Self);
  InicializarEntradaCajaVcl(Self);
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := nil;
  dsLineas.OnDataChange := DsLineasDataChange;
  InicializarEditorLineasCajaVcl(Self);
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(tvUds, tvTipoCantidad, UnidadesMedida);
  DatosCaja.OnUpdateTotal := ActualizarLabelTotal;
  DatosCaja.OnRellenarArticulo :=
    FEditorLineas.RellenarDatosArticuloEnDataset;
  DatosCaja.OnRellenarAtributos :=
    FEditorLineas.RellenarAtributosDesdeSku;
  DatosCaja.OnRecalcularLineas := FEditorLineas.RecalcularLineas;
  lblFechaCaja.OnDblClick := FPresentacion.CambiarHora;
  tvEmpleado.Visible :=
    ParametrosCaja.GetBool('vgerShowEmpleadoLinea', True);
  var PermiteDescuentos :=
    ParametrosCaja.GetBool('vgerDescuentos', True);
  tvDescuento.Options.Editing := PermiteDescuentos;
  tvDescuentoMenos.Options.Editing := PermiteDescuentos;
  // El Total tambien es editable y, al bajarlo, aplica un descuento
  // implicito (GridRecalc recalcula % y Menos a partir del total). Si no
  // se permiten descuentos hay que bloquearlo igual que % y Menos; de lo
  // contrario seria una via para saltarse el control editando el total.
  tvTotal.Options.Editing := PermiteDescuentos;
  // El Precio unitario es la otra via: bajarlo reduce el importe (un
  // descuento de facto). Con descuentos denegados, el precio de tarifa
  // queda intocable.
  tvPrecioUni.Options.Editing := PermiteDescuentos;
  dbtvBusq.DataController.DataModeController.GridMode := True;
  dbtvBusq.DataController.DataModeController.SyncMode := False;
  dbtvBusq.DataController.Filter.AutoDataSetFilter := False;
  dbtvBusq.DataController.Options := dbtvBusq.DataController.Options -
    [dcoImmediatePost, dcoGroupsAlwaysExpanded];
  dbtvBusq.OptionsBehavior.IncSearch := False;
  dbtvBusq.OptionsBehavior.IncSearchItem := nil;
  repSoloTexto.Properties.OnValidate := tvArticuloPropertiesValidate;
  repComboBox.Properties.OnCloseUp   := tvArticuloPropertiesCloseUp;
end;

procedure TfrmMtoOpeCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // El lector resetea su estado, captura si la rejilla editaba y cierra la
  // lectura por velocidad (consume el VK_RETURN si era una rafaga del lector).
  FEntrada.Lector.KeyDown(Key, Shift);
  if (Key = VK_F5) then
    btnF5.Click;
  if (Key = VK_F7) then
  begin
    btnF7.Click;
    Key := 0;
  end;
  // F4 -> devolución escaneando / localizando el ticket de origen
  if (Key = VK_F4) then
  begin
    btnF61.Click;
    Key := 0;
  end;
  // Ctrl+F12 -> resetear layout
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    FPresentacion.ResetearLayout;
    Key := 0;
  end;
end;

procedure TfrmMtoOpeCaja.btnF7Click(Sender: TObject);
var
  bLineaInmaterial: Boolean;
  sTipoIvaActual: string;
  sTipoIvaNuevo: string;
begin
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(True);
  bLineaInmaterial := Assigned(DatosCaja);
  if bLineaInmaterial then
    bLineaInmaterial := DatosCaja.cdsLineas.Active;
  if bLineaInmaterial then
    bLineaInmaterial := not DatosCaja.cdsLineas.IsEmpty;
  if bLineaInmaterial then
    bLineaInmaterial := SameText(
      Trim(DatosCaja.cdsLineas.FieldByName(
        'TIPO_ARTICULO_FACLIN').AsString),
      'SERVICIO');
  if not bLineaInmaterial then
    ShowMessage(SErrorCambioIvaSoloArticuloInmaterial)
  else
  begin
    sTipoIvaActual := DatosCaja.cdsLineas.FieldByName(
      'TIPO_IVA_ARTICULO_FACLIN').AsString;
    if SolicitarCambioIvaCaja(
         Self, sTipoIvaActual, sTipoIvaNuevo) and
       not SameText(sTipoIvaActual, sTipoIvaNuevo) then
    begin
      ActualizarLineaFactura(
        ConexionPrincipal,
        FLecturas.RepositorioFacturas,
        DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera,
        ftipiva,
        sTipoIvaNuevo,
        ActualizarLabelTotal);
      tvLineasOpe.DataController.Refresh;
    end;
  end;
end;

// Ctrl+U: consulta de stock del articulo de la linea que se esta metiendo.
// Lee el (articulo, sku) de la linea enfocada con el mismo helper que usan
// los mantenimientos via TfrmMtoGen.ResolverArtSkuActivo (CODIGO_ART_FACLIN
// y CODIGO_UNIDAD_FACLIN estan entre sus alias). Si la linea aun no tiene
// articulo resuelto, abre la consulta vacia con su buscador.
procedure TfrmMtoOpeCaja.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  if Assigned(DatosCaja) then
    ResolverArtSkuStockCaja(DatosCaja.cdsLineas, ACodArt, ACodSku)
  else
  begin
    ACodArt := '';
    ACodSku := '';
  end;
end;

procedure TfrmMtoOpeCaja.actConsultaStockExecute(Sender: TObject);
begin
  if Assigned(DatosCaja) then
    MostrarConsultaStockCaja(DatosCaja.cdsLineas)
  else
    MostrarConsultaStockCaja(nil);
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
begin
  FPresentacion.RestaurarLayout;
  FPresentacion.ActualizarFoco;
end;

procedure TEditorLineasCajaVcl.AbrirPopupAtributo;
begin
  FSelectorAtributos.AbrirPopupAtributo;
end;

procedure TEditorLineasCajaVcl.SeleccionarAtributo(
  Sender: TObject; AButtonIndex: Integer);
begin
  FSelectorAtributos.SeleccionarAtributo(Sender, AButtonIndex);
end;

procedure TEditorLineasCajaVcl.FinalizarAtributos;
begin
  FSelectorAtributos.FinalizarAtributos;
end;

procedure TEditorLineasCajaVcl.AvanzarAtributo(
  ANumeroColumna: Integer);
begin
  FSelectorAtributos.AvanzarAtributo(ANumeroColumna);
end;

function TfrmMtoOpeCaja.IntentarCerrar: Boolean;
begin
  Result := True;
  if not (csDestroying in ComponentState) then
  begin
    if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
    begin
      if not Visible then
      begin
        Show;
        BringToFront;
      end;
      if MessageDlg(
        Format(SPreguntaEliminarOperacionCajaPendiente, [Self.Tag]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          DatosCaja.cdsLineas.Cancel;
        Close;
      end
      else
        Result := False;
    end
    else
      Close;
  end;
end;

function TEditorLineasCajaVcl.ObtenerColumnaPorTag(
  ANumeroColumna: Integer): TcxGridDBColumn;
var
  i:Integer;
begin
  Result := nil;
  for i:= 0 to tvLineasOpe.ColumnCount - 1 do
    if (Result = nil) and
       (tvLineasOpe.Columns[i].Tag = ANumeroColumna) then
      Result := (tvLineasOpe.Columns[i] as TcxGridDBColumn);
end;

procedure TfrmMtoOpeCaja.Timer1Timer(Sender: TObject);
begin
  FPresentacion.ActualizarReloj;
end;

end.
