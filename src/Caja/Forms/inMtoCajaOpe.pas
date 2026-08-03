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
  System.Generics.Collections, System.Diagnostics, cxLocalization,
  inLibLectorScanner, inLibCajaTipos, inLibCajaVentanasIntf,
  inLibCajaVentaIntf, inLibCatalogoSqlIntf,
  inLibFacturasLecturasIntf, inLibCajaEntradaIntf,
  inLibCajaOpePresentacionIntf, inMtoCajaOpePresentacionVcl,
  inLibParametrosIntf, inLibRepositoriosPantallaIntf, inLibLogIntf,
  inLibGenBusq;

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
    RepositoriosArticulos: IRepositoriosArticulosPantalla;
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
    FRepositoriosArticulosPantalla: IRepositoriosArticulosPantalla;
    FDependencias: TContextoDependenciasOperacionCaja;
    FRepositorioArticulos: IRepositorioArticulosCaja;
    FRepositorioFacturas: IRepositorioLecturasFactura;
    FBusquedaVisual: IBusquedaVisual;
    FFotosArticulos: TFotosArticulos;
    FRegistroLog: IRegistroLog;
    FActualizarTotal: TActualizarTotalCajaVcl;
    FCerrarFormulario: TAccionCajaVcl;
    FResolviendoPorScanner: TConsultaBooleanaCajaVcl;
    FLectorLeyendoTrama: TConsultaBooleanaCajaVcl;
    FObtenerAlmacen: TConsultaTextoCajaVcl;
    FResultadoBusquedaIncremental: IResultadoConsultaCaja;
    FConsultaStock: IResultadoConsultaCaja;
    FTecladoLinea: TTecladoLineaOperacionCaja;
    FBmpSwatchBoton: TBitmap;
    FswArtAPopup: TStopwatch;
    FNumAtributosActual: Integer;
    FProcesandoAtributo: Boolean;
    FUltimoArticuloPadre: string;
    FActualizandoDepositos: Boolean;
    FMotivoRechazoArticulo: string;
    FArticuloResueltoEdicion: string;
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
    function GetFuenteStock: TDataSource;
    function GetFuenteBusqueda: TDataSource;
    function GetVistaStock: TcxGridDBTableView;
    function GetVistaBusqueda: TcxGridDBTableView;
    function GetRepositorioSoloTexto: TcxEditRepositoryTextItem;
    function GetRepositorioCombo:
      TcxEditRepositoryExtLookupComboBoxItem;
    function GetTemporizadorBusqueda: TTimer;
    function GetNavegacionEnter: TJvEnterAsTab;
    function GetBotonBuscar: TcxButton;
    function GetBotonEliminar: TcxButton;
    function GetImagenStock: TImage;
    function ObtenerResolviendoPorScanner: Boolean;
    procedure ActualizarLabelTotal(Sender: TObject;
      ANuevoTotal: Currency);
    procedure InicializarTecladoLineaCaja;
    procedure SolicitarFocoArticuloLineaNueva;
    procedure RefrescarFotoStock;
    procedure AbrirPopupAvEnEntrada(Sender: TObject);
    procedure RegistrarValorAtributo(AOrden: Integer;
      const AValorNuevo: string);
    procedure FinalizarUltimoAtributo;
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
    property dsStock: TDataSource read GetFuenteStock;
    property dsBusq: TDataSource read GetFuenteBusqueda;
    property dbtvStock: TcxGridDBTableView read GetVistaStock;
    property dbtvBusq: TcxGridDBTableView read GetVistaBusqueda;
    property repSoloTexto: TcxEditRepositoryTextItem
      read GetRepositorioSoloTexto;
    property repComboBox: TcxEditRepositoryExtLookupComboBoxItem
      read GetRepositorioCombo;
    property tmrBusq: TTimer read GetTemporizadorBusqueda;
    property jvEnterTab: TJvEnterAsTab read GetNavegacionEnter;
    property btnF3: TcxButton read GetBotonBuscar;
    property btnF8: TcxButton read GetBotonEliminar;
    property imgFotoStock: TImage read GetImagenStock;
    property DatosCaja: TdmCajaOpe read FDatosCaja;
    property ConexionPrincipal: TUniConnection read FConexionPrincipal;
    property ParametrosCaja: IParametrosCaja read FParametrosCaja;
    property RepositoriosArticulosPantalla: IRepositoriosArticulosPantalla
      read FRepositoriosArticulosPantalla;
    property RegistroLog: IRegistroLog read FRegistroLog;
    property BusquedaVisual: IBusquedaVisual read FBusquedaVisual;
    property FotosArticulos: TFotosArticulos read FFotosArticulos;
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
      const ACodigo: string): Boolean;
    procedure InicializarPopupBusqueda(Sender: TObject);
    procedure RecalcularPrecioDesdeSku(const ASku: string);
    procedure RellenarAtributosDesdeSku(const ASku: string);
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
    FUltimoTickReloj: TDateTime;
    FDependencias: TContextoDependenciasOperacionCaja;
    FLecturas: TServiciosLecturaOperacionCaja;
    FIncidenciasSql: IRegistroIncidenciasSql;
    FRepositoriosArticulosPantalla: IRepositoriosArticulosPantalla;
    FRepositoriosCajaPantalla: IRepositoriosCajaPantalla;
    FRepositoriosTicketsCajaPantalla: IRepositoriosTicketsCajaPantalla;
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
    procedure GuardarLayoutCaja;
    procedure RestaurarLayoutCaja;
    procedure AbrirBuscarModificar;
    procedure CargarDevolucionPorTicket;
    procedure CargarDevolucionOtraEmpresa(
      const ASerie, ANumero, AAlmacen: string);
    procedure WMPreguntarVentaOrigen(var Msg: TMessage);
                                       message WM_PREGUNTAR_VENTA_ORIGEN;
    function PedirMotivoDevolucionSiProcede: Boolean;
    procedure CargarDepositosF2;
    procedure ActualizarRelojCaja;
    procedure lblFechaCajaDblClick(Sender: TObject);
    procedure AsegurarLineaNueva;
    procedure ActualizarFoco;
    function BuscarArticulo:String;
    procedure WMCancelarLinea(var Msg: TMessage); message WM_CANCELAR_LINEA;
    function ConsolidarSiExiste(SkuBuscado: string): Boolean;
    procedure RellenarAtributosDesdeSku(Sku: string);
    procedure ActualizarColumnasDinamicas(ArticuloPadre: string);
    procedure PoblarAtributosLineasDeposito;
    procedure MostrarColumnasCuentaCliente(AActivar: Boolean);
    function ObtenerColumnaPorTag(NumColumn:Integer):TcxGridDBColumn;
    function RellenarDatosArticuloEnDataset(Codigo: string): Boolean;
    procedure ActualizarLabelTotal(Sender: TObject; NuevoTotal: Currency);
    procedure RecalcularLineasDesdeDM;
    function  ValidarSkuParaVenta(const SkuFinal: string): Boolean;
    procedure BuscarEmpleados;
    procedure BuscarClientes;
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
  inLibUser,

  inLibDevExp, inLibValoresAutomaticos, inLibFacturas,
  inMtoModalGenImpSave, inLibLayoutForm,
  inLibArticulosValidadorIntf, inLibArticulosResolverIntf,
  inLibArticulosAtributosIntf,
  inLibAtributosPaleta,
  inLibShowMto,
  inMtoStockConsulta,
  inLibCorreoTickets,
  inLibCajaVentaCliente,
  inLibCajaVentaOperacion,
  inLibCajaOpeComposicion,
  inLibCajaOpePresentacion,
  inLibCajaEntrada,
  inMtoCajaEntradaVcl,
  // Raiz de composicion de la ventana de caja: el adaptador UniData* se
  // construye aqui y se inyecta en la factoria de dominio.
  UniDataCajaConsultasRepositorio,
  inMtoCajaImpresorVenta,
  inMtoCajaCierreVentaVcl,
  UniDataCajaUnidadTrabajo,
  inMtoModalDevolucionTicket,
  inMtoModalSeleccionVentaOrigen,
  inMtoModalMotivoDevolucion,
  inLibPermisosIntf,
  inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf,
  inLibTicketsCajaIntf,
  UniDataCatalogoSqlAplicacion,
  UniDataTicketsCajaRepositorio,
  UniDataFacturasLecturas,
  UniDataFacturasOperaciones,
  UniDataVentasWsCola,
  inLibFacturasPersistenciaIntf,
  inLibUnidadesMedida, inLibPreviewTicket,
  System.StrUtils,
  inLibMsgCaja, inLibMsgVentas;

procedure InicializarEntradaCajaVcl(AFormulario: TfrmMtoOpeCaja);
var
  Operaciones: TOperacionesEntradaCajaVcl;
  PuertoOperaciones: IOperacionesEntradaCaja;
  Vista: IVistaEntradaCaja;
begin
  Operaciones := Default(TOperacionesEntradaCajaVcl);
  Operaciones.Disponible :=
    function: Boolean
    begin
      Result := Assigned(AFormulario.DatosCaja) and
        AFormulario.DatosCaja.cdsLineas.Active;
    end;
  Operaciones.VendedorAsignado :=
    function: Boolean
    begin
      Result := Trim(AFormulario.DatosCaja.cdsCabecera.FieldByName(
        'CODIGO_CAJERO_FAC').AsString) <> '';
    end;
  Operaciones.PermitirSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.ValidarSkuParaVenta(ACodigoSku);
    end;
  Operaciones.PrepararLinea :=
    procedure
    begin
      if AFormulario.DatosCaja.cdsLineas.State = dsInsert then
      begin
        if Trim(AFormulario.DatosCaja.cdsLineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString) <> '' then
        begin
          AFormulario.DatosCaja.cdsLineas.Post;
          AFormulario.DatosCaja.cdsLineas.Append;
        end;
      end
      else
      begin
        if AFormulario.DatosCaja.cdsLineas.State = dsEdit then
          AFormulario.DatosCaja.cdsLineas.Post;
        AFormulario.DatosCaja.cdsLineas.Append;
      end;
    end;
  Operaciones.ConsolidarSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.ConsolidarSiExiste(ACodigoSku);
    end;
  Operaciones.AplicarCodigo :=
    procedure(const ACodigo, ACodigoSku, ACodigoArticulo: string)
    begin
      AFormulario.FEntrada.ResolviendoPorScanner := True;
      try
        AFormulario.RellenarDatosArticuloEnDataset(ACodigo);
      finally
        AFormulario.FEntrada.ResolviendoPorScanner := False;
      end;
      if (Trim(ACodigoSku) <> '') and
         (ACodigoSku <> ACodigoArticulo) then
        AFormulario.RellenarAtributosDesdeSku(ACodigoSku);
      if AFormulario.DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
        AFormulario.DatosCaja.cdsLineas.Post;
      GridRecalc(
        AFormulario.ConexionPrincipal,
        AFormulario.FLecturas.RepositorioFacturas,
        nil,
        AFormulario.tvLineasOpe,
        AFormulario.DatosCaja.cdsLineas,
        AFormulario.DatosCaja.cdsCabecera,
        AFormulario.ActualizarLabelTotal);
    end;
  Operaciones.Iniciar :=
    procedure
    begin
      AFormulario.FEntrada.ProcesandoLectura := True;
    end;
  Operaciones.Finalizar :=
    procedure
    begin
      AFormulario.FEntrada.ProcesandoLectura := False;
    end;
  Operaciones.MostrarError :=
    procedure(const AMensaje: string)
    begin
      ShowMessage(AMensaje);
    end;
  Operaciones.EnfocarVendedor :=
    procedure
    begin
      if AFormulario.btnCodigoEmpleado.CanFocus then
        AFormulario.btnCodigoEmpleado.SetFocus;
    end;
  Operaciones.PrepararLectura :=
    procedure
    begin
      AFormulario.tmrBusq.Enabled := False;
      if AFormulario.tvLineasOpe.Controller.
         EditingController.IsEditing then
        AFormulario.tvLineasOpe.Controller.
          EditingController.HideEdit(False);
    end;
  Operaciones.RefrescarConsolidacion :=
    procedure
    begin
      AFormulario.tvLineasOpe.DataController.UpdateItems(True);
    end;
  Operaciones.PrepararSiguiente :=
    procedure
    begin
      AFormulario.AsegurarLineaNueva;
      AFormulario.tvLineasOpe.Controller.
        EditingController.ShowEdit;
    end;
  CrearPuertosEntradaCajaVcl(
    Operaciones,
    PuertoOperaciones,
    Vista);
  AFormulario.FEntrada.Aplicacion := CrearAplicacionEntradaCaja(
    AFormulario.FRepositoriosArticulosPantalla.CrearValidadorArticulos(
      AFormulario.ConexionPrincipal),
    PuertoOperaciones,
    Vista);
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
  Result.ActualizarReloj := AFormulario.ActualizarRelojCaja;
  Result.LeerFecha :=
    function: TDateTime
    begin
      Result := AFormulario.FFecha;
    end;
  Result.PresentarResultado := AFormulario.ProcesarResultadoCierre;
end;

function CrearServiciosOperacionCajaVcl(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const AContextoSesion: IContextoSesionAplicacion;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const ANombreFormulario: string;
  ADatosCaja: TdmCajaOpe;
  out AIncidenciasSql: IRegistroIncidenciasSql
): TContextoDependenciasOperacionCaja;
var
  bCatalogoSqlActivo: Boolean;
  oCatalogoSql: ICatalogoSql;
  oUnidadTrabajo: IUnidadTrabajoVentaCaja;
  oImpresor: IImpresorVenta;
  oPersistenciaFacturas: TPersistenciaFacturas;
  oRepositorioTicketsCaja: TRepositoriosTicketsCaja;
begin
  bCatalogoSqlActivo := False;
  if Assigned(APerfilesLectura) then
    bCatalogoSqlActivo := SameText(
      APerfilesLectura.ObtenerValorPerfil(
        ANombreFormulario,
        'oGetSQLFromDB',
        'False'),
      'True');
  CrearCatalogoSqlAplicacion(
    APerfilesLectura,
    APerfilesEscritura,
    bCatalogoSqlActivo,
    oCatalogoSql,
    AIncidenciasSql,
    ARegistroLog);
  oRepositorioTicketsCaja := CrearRepositoriosTicketsCaja(
    AConexion, oCatalogoSql, AIncidenciasSql);
  ADatosCaja.AsignarRepositorioTicketsCaja(
    oRepositorioTicketsCaja);
  oImpresor := TImpresorVentaVcl.Create(
    APropietario,
    AParametrosApp,
    AConexion,
    AParametrosCaja,
    APermisos,
    oRepositorioTicketsCaja.Tickets,
    AUnidades,
    APreviewTicket);
  oUnidadTrabajo := TUnidadTrabajoVentaCajaUniDAC.Create(
    ADatosCaja);
  oPersistenciaFacturas := CrearPersistenciaFacturasUniDAC(AConexion);
  Result := CrearServiciosOperacionCaja(
    AConexion,
    AParametrosCaja,
    AContextoSesion,
    oImpresor,
    oUnidadTrabajo,
    TRepositorioConsultasCaja.Create(
      AConexion,
      oCatalogoSql,
      AIncidenciasSql),
    oPersistenciaFacturas.Pdf,
    CrearRepositorioVentasWsColaUniDAC(AConexion),
    ARegistroLog);
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
  AFormulario.FDependencias := CrearServiciosOperacionCajaVcl(
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

function TEditorLineasCajaVcl.GetFuenteStock: TDataSource;
begin
  Result := FControles.FuenteStock;
end;

function TEditorLineasCajaVcl.GetFuenteBusqueda: TDataSource;
begin
  Result := FControles.FuenteBusqueda;
end;

function TEditorLineasCajaVcl.GetVistaStock: TcxGridDBTableView;
begin
  Result := FControles.VistaStock;
end;

function TEditorLineasCajaVcl.GetVistaBusqueda: TcxGridDBTableView;
begin
  Result := FControles.VistaBusqueda;
end;

function TEditorLineasCajaVcl.GetRepositorioSoloTexto:
  TcxEditRepositoryTextItem;
begin
  Result := FControles.RepositorioSoloTexto;
end;

function TEditorLineasCajaVcl.GetRepositorioCombo:
  TcxEditRepositoryExtLookupComboBoxItem;
begin
  Result := FControles.RepositorioCombo;
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

function TEditorLineasCajaVcl.GetImagenStock: TImage;
begin
  Result := FControles.ImagenStock;
end;

constructor TEditorLineasCajaVcl.Create(
  const AControles: TControlesEditorLineasCajaVcl;
  const AServicios: TServiciosEditorLineasCajaVcl);
begin
  inherited Create;
  FControles := AControles;
  FDatosCaja := AServicios.DatosCaja;
  FConexionPrincipal := AServicios.Conexion;
  FParametrosCaja := AServicios.ParametrosCaja;
  FRepositoriosArticulosPantalla := AServicios.RepositoriosArticulos;
  FDependencias := AServicios.Dependencias;
  FRepositorioArticulos := AServicios.RepositorioArticulos;
  FRepositorioFacturas := AServicios.RepositorioFacturas;
  FBusquedaVisual := AServicios.BusquedaVisual;
  FFotosArticulos := AServicios.FotosArticulos;
  FRegistroLog := AServicios.RegistroLog;
  FActualizarTotal := AServicios.ActualizarTotal;
  FCerrarFormulario := AServicios.CerrarFormulario;
  FResolviendoPorScanner := AServicios.ResolviendoPorScanner;
  FLectorLeyendoTrama := AServicios.LectorLeyendoTrama;
  FObtenerAlmacen := AServicios.ObtenerAlmacen;
  FBmpSwatchBoton := TBitmap.Create;
end;

destructor TEditorLineasCajaVcl.Destroy;
begin
  FTecladoLinea.Procesador := nil;
  FTecladoLinea.Rejilla := nil;
  FConsultaStock := nil;
  FResultadoBusquedaIncremental := nil;
  FRepositorioArticulos := nil;
  FRepositorioFacturas := nil;
  FRepositoriosArticulosPantalla := nil;
  FParametrosCaja := nil;
  FBusquedaVisual := nil;
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
  Servicios.RepositoriosArticulos :=
    AFormulario.FRepositoriosArticulosPantalla;
  Servicios.Dependencias := AFormulario.FDependencias;
  Servicios.RepositorioArticulos :=
    AFormulario.FRepositoriosCajaPantalla.
      CrearRepositorioArticulosCaja(AFormulario.ConexionPrincipal);
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

function TfrmMtoOpeCaja.ValidarSkuParaVenta(
  const SkuFinal: string): Boolean;
begin
  Result := FEditorLineas.ValidarSkuParaVenta(SkuFinal);
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

function TfrmMtoOpeCaja.BuscarArticulo: string;
begin
  Result := FEditorLineas.BuscarArticulo;
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

function TfrmMtoOpeCaja.RellenarDatosArticuloEnDataset(
  Codigo: string): Boolean;
begin
  Result := FEditorLineas.RellenarDatosArticuloEnDataset(Codigo);
end;

procedure TfrmMtoOpeCaja.repComboBoxPropertiesInitPopup(
  Sender: TObject);
begin
  FEditorLineas.InicializarPopupBusqueda(Sender);
end;

procedure TfrmMtoOpeCaja.RellenarAtributosDesdeSku(Sku: string);
begin
  FEditorLineas.RellenarAtributosDesdeSku(Sku);
end;

function TfrmMtoOpeCaja.ConsolidarSiExiste(
  SkuBuscado: string): Boolean;
begin
  Result := FEditorLineas.ConsolidarSiExiste(SkuBuscado);
end;

procedure TfrmMtoOpeCaja.PoblarAtributosLineasDeposito;
begin
  FEditorLineas.PoblarAtributosLineasDeposito;
end;

procedure TfrmMtoOpeCaja.MostrarColumnasCuentaCliente(
  AActivar: Boolean);
begin
  FEditorLineas.MostrarColumnasCuentaCliente(AActivar);
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

procedure TfrmMtoOpeCaja.ActualizarColumnasDinamicas(
  ArticuloPadre: string);
begin
  FEditorLineas.ActualizarColumnasDinamicas(ArticuloPadre);
end;

procedure TfrmMtoOpeCaja.RecalcularLineasDesdeDM;
begin
  FEditorLineas.RecalcularLineas;
end;

procedure TfrmMtoOpeCaja.AsegurarLineaNueva;
begin
  FEditorLineas.AsegurarLineaNueva;
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

function TfrmMtoOpeCaja.ObtenerColumnaPorTag(
  NumColumn: Integer): TcxGridDBColumn;
begin
  Result := FEditorLineas.ObtenerColumnaPorTag(NumColumn);
end;

procedure TfrmMtoOpeCaja.ActualizarFoco;
begin
  if btnCodigoEmpleado.Text = '' then
  begin
    if btnCodigoEmpleado.CanFocus then
      btnCodigoEmpleado.SetFocus;
  end
  else if cxgrdLineasOpe.CanFocus then
  begin
    cxgrdLineasOpe.SetFocus;
  end;
end;

procedure TfrmMtoOpeCaja.ActualizarRelojCaja;
var
  dtAhora: TDateTime;
begin
  dtAhora := Now;
  if FUltimoTickReloj = 0 then
    FUltimoTickReloj := dtAhora;
  if FFecha = 0 then
    FFecha := dtAhora;
  FFecha := FFecha + (dtAhora - FUltimoTickReloj);
  FUltimoTickReloj := dtAhora;
  lblFechaCaja.Caption := FormatDateTime('hh:nn:ss dddd d mmmm yyyy', FFecha);
end;

procedure TfrmMtoOpeCaja.lblFechaCajaDblClick(Sender: TObject);
var
  sHora: string;
  dtHora: TDateTime;
  dtFechaBase: TDateTime;
begin
  dtFechaBase := FFecha;
  if dtFechaBase = 0 then
    dtFechaBase := Now;
  sHora := FormatDateTime('hh:nn', dtFechaBase);
  if InputQuery(STituloHoraCaja, SSolicitudHoraCaja, sHora) then
  begin
    if TryStrToTime(sHora, dtHora) then
    begin
      FFecha := Trunc(dtFechaBase) + Frac(dtHora);
      FUltimoTickReloj := Now;
      ActualizarRelojCaja;
      EscribirFechaCabeceraVenta(DatosCaja.cdsCabecera, FFecha);
      NotificarFechaCaja(FFecha);
    end
    else
      ShowMessage(SErrorHoraCajaNoValida);
  end
  else
  begin
    FFecha := Now;
    FUltimoTickReloj := Now;
    ActualizarRelojCaja;
    EscribirFechaCabeceraVenta(DatosCaja.cdsCabecera, FFecha);
    NotificarFechaCaja(FFecha);
  end;
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
  AsegurarLineaNueva;
  if not (DatosCaja.cdsLineas.State in dsEditModes) then
    DatosCaja.cdsLineas.Edit;
  Result := RellenarDatosArticuloEnDataset(ASku);
  if Result then
  begin
    DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := ACant;
    DatosCaja.cdsLineas.Post;
    GridRecalc(ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
               tvLineasOpe, DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera, ActualizarLabelTotal);
    AsegurarLineaNueva;
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
  sCodEmpleadoDefecto: string;
begin
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FCodigoCaja    := ACaja;
  FFecha         := AFecha;
  FUltimoTickReloj := Now;
  lblTipoRectificativa.Caption := '';
  lblTipoRectificativa.Visible := False;

  if Assigned(DatosCaja) then
  begin
    // 1. Guardar el empleado actual antes de vaciar
    EmpleadoAnterior := '';
    NombreEmpleadoAnterior := '';
    if DatosCaja.cdsCabecera.Active and not DatosCaja.cdsCabecera.IsEmpty then
    begin
      EmpleadoAnterior :=
            DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
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
    MostrarColumnasCuentaCliente(False);
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
    // 4. Mantener el empleado o aplicar el configurado por defecto.
    if EmpleadoAnterior <> '' then
    begin
      DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
                                                               EmpleadoAnterior;
      btnCodigoEmpleado.Text := EmpleadoAnterior;
      lblNombreEmpleado.Caption := NombreEmpleadoAnterior;
    end
    else if ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False) then
    begin
      sCodEmpleadoDefecto :=
        ParametrosCaja.GetString('vgerCodEmpleadoDefecto', '');
      if sCodEmpleadoDefecto <> '' then
      begin
        btnCodigoEmpleado.Text := sCodEmpleadoDefecto;
        btnCodigoEmpleado.ValidateEdit(True);
      end;
    end;
  end;
  dbtvStock.ClearItems;
  lblNombreCliente.Caption := SCaptionVentaContado;
  btnCodigoCliente.Text := '';
  lblTotal.Caption := SCaptionTotalCero;
  ActualizarRelojCaja;
  if Self.Visible then
    ActualizarFoco;
end;

procedure TEditorLineasCajaVcl.ConsultarStock(const ACodigo: string);
var
  View: TcxGridDBTableView;
  DataSetStock: TDataSet;
  I: Integer;
  Mapa: TDictionary<string, string>;
  sCodigoArticulo: string;
  sCodigoConsulta: string;
begin
  sCodigoConsulta := Trim(ACodigo);
  if sCodigoConsulta <> '' then
  begin
    if ParametrosCaja.GetBool(
         'vgerStockTodosColores',
         False) and
       (Pos('/', sCodigoConsulta) > 0) and
       Assigned(DatosCaja) and
       DatosCaja.cdsLineas.Active then
    begin
      // El padre devuelve una fila por color y almacén.
      sCodigoArticulo :=
        Trim(
          DatosCaja.cdsLineas.FieldByName(
            'CODIGO_ART_FACLIN').AsString);
      if sCodigoArticulo <> '' then
      begin
        sCodigoConsulta := sCodigoArticulo;
      end;
    end;
    dsStock.DataSet := nil;
    FConsultaStock :=
      FDependencias.RepositorioConsultas.ConsultarStock(
        sCodigoConsulta);
    DataSetStock := FConsultaStock.DataSet;
    dsStock.DataSet := DataSetStock;
    View := dbtvStock;
    View.BeginUpdate;
    try
      View.ClearItems;
      if not DataSetStock.IsEmpty then
      begin
        View.DataController.CreateAllItems;
        for I := 0 to View.ColumnCount - 1 do
        begin
          if (I = 0) or (I = 1) then
          begin
            View.Columns[I].HeaderAlignmentHorz := taLeftJustify
          end
          else
          begin
            View.Columns[I].HeaderAlignmentHorz := taRightJustify;
          end;
        end;
      end;
    finally
      View.EndUpdate;
    end;
    if DataSetStock.Active and
       (not DataSetStock.IsEmpty) then
    begin
      View.BeginUpdate;
      try
        try
          View.ApplyBestFit;
        except
          // BestFit es cosmetico: no bloquea la carga del stock.
          on E: Exception do
            RegistroLog.RegistrarAviso(
              'CajaOpe: ApplyBestFit del stock ignorado: ' +
              E.Message);
        end;
        // ApplyBestFit no reserva el ancho del indicador de color.
        Mapa := ObtenerMapaAtributosGlobal(
          ConexionPrincipal);
        if Assigned(Mapa) and
           (Mapa.Count > 0) and
           (View.ColumnCount > 0) then
        begin
          AjustarAnchoColumnaParaSwatch(
            ConexionPrincipal,
            View.Columns[0],
            Mapa);
        end;
      finally
        View.EndUpdate;
      end;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.DibujarCeldaLinea(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Info: TInfoBasico;
  Mapa: TDictionary<string, string>;
  sArticulo: string;
  sIdVa: string;
  sTexto: string;
begin
  // Pinta el cuadradito de la paleta basica al lado del valor de atributo
  // (Color = MALVA, Talla = 48, ...) en las celdas de las lineas de venta.
  // La asignacion por articulo gana porque los codigos de proveedor pueden
  // representar colores basicos distintos segun el articulo.
  if (AViewInfo <> nil) and (AViewInfo.Item <> nil) and
     (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item.Tag >= 1) and (AViewInfo.Item.Tag <= 5) then
  begin
    sArticulo := VarToStr(
      AViewInfo.GridRecord.Values[tvArticulo.Index]);
    sTexto := AViewInfo.Text;
    Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
    sIdVa := '';
    if (Mapa <> nil) and (AViewInfo.Item is TcxGridColumn) then
      Mapa.TryGetValue(UpperCase(Trim(
        TcxGridColumn(AViewInfo.Item).Caption)), sIdVa);
    if ObtenerInfoBasicoArticulo(
      ConexionPrincipal,
      sArticulo,
      sIdVa,
      sTexto,
      Info) then
      ADone := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info, sTexto);
  end;
  if (not ADone) and
     PintarCeldaSwatchSiAplica(ConexionPrincipal,ACanvas, AViewInfo, nil) then
    ADone := True;
end;

procedure TEditorLineasCajaVcl.DibujarCeldaStock(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // Solo pintamos swatch en la primera columna (Codigo "CODART/COLOR").
  // Las columnas pivotadas de talla traen cantidades y no queremos
  // cuadradito al lado de cada numero — basta con la del codigo.
  if (AViewInfo = nil) or (AViewInfo.Item = nil) then Exit;
  if AViewInfo.Item.VisibleIndex <> 0 then Exit;
  if PintarCeldaSwatchSiAplica(ConexionPrincipal,ACanvas, AViewInfo, nil) then
    ADone := True;
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
begin
  if (DatosCaja.cdsLineas.Active) then
  begin
    // NUEVO: Bloqueo de borrado por atajo
    if not DatosCaja.cdsLineas.IsEmpty then
    begin
      VieneDeDep :=
        DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if EsLineaDeposito(VieneDeDep) then
      begin
        ShowMessage(SErrorLineaDepositoCajaNoCancelable);
        Exit;
      end;
    end;
    if (DatosCaja.cdsLineas.State = dsInsert) then
      DatosCaja.cdsLineas.Cancel
    else if not DatosCaja.cdsLineas.IsEmpty then
      DatosCaja.cdsLineas.Delete;
    GridRecalc(ConexionPrincipal, FRepositorioFacturas, nil,
               tvLineasOpe,
               DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera,
               ActualizarLabelTotal);
    AsegurarLineaNueva;
  end;
end;

procedure TEditorLineasCajaVcl.EjecutarBusquedaIncremental(
  Sender: TObject);
var
  dtFechaTarifa: TDateTime;
  EditActivo: TcxCustomEdit;
  oDatosBusqueda: TDataSet;
  sTarifa: string;
  TextEdit: TcxCustomTextEdit;
  TextoBusqueda: string;
begin
  tmrBusq.Enabled := False;
  EditActivo := nil;
  dbtvBusq.BeginUpdate;
  try
    dbtvBusq.DataController.DataSource := nil;
    dbtvBusq.DataController.Filter.Clear;
    dbtvBusq.DataController.Filter.Active := False;
    dbtvBusq.Controller.IncSearchingText := '';
    if tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      EditActivo := tvLineasOpe.Controller.EditingController.Edit;
      if EditActivo <> nil then
      begin
        // Cuando el timer dispara, el editor activo puede no ser el de
        // tvArticulo (el usuario pudo moverse a otra celda durante los
        // 500ms de debounce). Solo casteamos a TcxCustomTextEdit si el
        // editor realmente lo es; en otro caso usamos EditingValue.
        // Esto evita el EInvalidCast cuando el editor activo no es de
        // tipo texto (p.ej. TcxButtonEdit de columnas de atributo).
        if EditActivo is TcxCustomTextEdit then
        begin
          TextEdit := TcxCustomTextEdit(EditActivo);
          if TextEdit.SelLength > 0 then
            TextoBusqueda := Copy(TextEdit.Text, 1, TextEdit.SelStart)
          else
            TextoBusqueda := TextEdit.Text;
        end
        else
          TextoBusqueda := VarToStr(EditActivo.EditingValue);
        TextoBusqueda := Trim(TextoBusqueda);
        if Length(TextoBusqueda) >= 1 then
        begin
          sTarifa := DatosCaja.cdsCabecera.FieldByName(
            'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
          dtFechaTarifa := DatosCaja.cdsCabecera.FieldByName(
            'FECHA_FAC').AsDateTime;
          dsBusq.DataSet := nil;
          FResultadoBusquedaIncremental :=
            FRepositorioArticulos.ConsultarArticulosIncremental(
              sTarifa,
              TextoBusqueda,
              dtFechaTarifa);
          oDatosBusqueda := FResultadoBusquedaIncremental.DataSet;
          dsBusq.DataSet := oDatosBusqueda;
          // Diagnostico: registramos el resultado de la busqueda incremental
          // para saber si la vista vi_art_busquedas devuelve filas. El log SQL
          // estandar marca filas=- en queries con LIMIT, asi que aqui lo
          // contamos explicitamente. Si filas=0, el problema es de datos (la
          // vista no devuelve nada para esa TARIFA/FECHA) y no del UI.
          try
            RegistroLog.RegistrarInformacion(
              Format('qryBusq.Open: TARIFA="%s" ' +
              'FECHA_TARIFA="%s" TOKEN="%s" IsEmpty=%s RecordCount=%d',
              [sTarifa,
               DateToStr(dtFechaTarifa),
               TextoBusqueda,
               BoolToStr(oDatosBusqueda.IsEmpty, True),
               oDatosBusqueda.RecordCount]));
            // Volcamos los primeros 5 codigos para verificar que la vista
            // realmente devuelve algo aprovechable (no nulls, codigos validos)
            if not oDatosBusqueda.IsEmpty then
            begin
              oDatosBusqueda.First;
              while (not oDatosBusqueda.Eof) and
                    (oDatosBusqueda.RecNo <= 5) do
              begin
                RegistroLog.RegistrarInformacion(
                  Format('qryBusq fila %d: cod="%s" desc="%s"',
                  [oDatosBusqueda.RecNo,
                   oDatosBusqueda.FieldByName('CODIGO_PADRE').AsString,
                   oDatosBusqueda.FieldByName('DESCRIPCION_ART').AsString]));
                oDatosBusqueda.Next;
              end;
              oDatosBusqueda.First;
            end;
          except
            on E: Exception do
              RegistroLog.RegistrarAviso('qryBusq diagnostico: ' +
                                      E.ClassName + ' ' + E.Message);
          end;
          dbtvBusq.DataController.DataSource := dsBusq;
          dbtvBusq.DataController.Refresh;
        end;
      end;
    end;
  finally
    dbtvBusq.EndUpdate;
  end;
  if (EditActivo is TcxExtLookupComboBox) then
    begin
       if not TcxExtLookupComboBox(EditActivo).DroppedDown then
       begin
          if Assigned(dsBusq.DataSet) and
             not dsBusq.DataSet.IsEmpty then
             TcxExtLookupComboBox(EditActivo).DroppedDown := True;
       end
       else
       begin
          TcxExtLookupComboBox(EditActivo).Properties.DropDownRows := 15;
       end;
    end;
end;

procedure TEditorLineasCajaVcl.ObtenerPropiedadesArticulo(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  EsLaCeldaFocale: Boolean;
  ValorActual: Variant;
begin
  if (ARecord = nil) or (tvLineasOpe.Controller = nil) then
    Exit;
  ValorActual := ARecord.Values[Sender.Index];
  if (not VarIsNull(ValorActual)) and (Trim(VarToStr(ValorActual)) <> '') then
  begin
    AProperties := repSoloTexto.Properties;
    Exit;
  end;
  EsLaCeldaFocale := (tvLineasOpe.Controller.FocusedRecord = ARecord)
                     and
                     (tvLineasOpe.Controller.FocusedItem = Sender);
  if EsLaCeldaFocale then
    AProperties := repComboBox.Properties
  else
    AProperties := repSoloTexto.Properties;
end;

procedure TEditorLineasCajaVcl.CambiarArticulo(Sender: TObject);
begin
  if not FLectorLeyendoTrama() then
  begin
    tmrBusq.Enabled := False;
    tmrBusq.Enabled := True;
  end;
end;

procedure TEditorLineasCajaVcl.CerrarBusquedaArticulo(Sender: TObject);
var
  Combo: TcxExtLookupComboBox;
begin
  if Sender is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(Sender);
    if Combo.Properties.View is TcxGridDBTableView then
    begin
      with TcxGridDBTableView(Combo.Properties.View) do
      begin
        BeginUpdate;
        try
          Controller.IncSearchingText := '';
          DataController.Filter.Clear;
          DataController.Filter.Active := False;
        finally
          EndUpdate;
        end;
      end;
    end;
  end;
end;

function TEditorLineasCajaVcl.BuscarArticulo: string;
  // Helper: ajusta DisplayLabel y, si procede, DisplayFormat de un campo.
  // El cast depende del TField concreto (TFloatField / TFMTBCDField /
  // TDateField / TSQLTimeStampField segun como UniDAC mapea la columna).
  procedure ConfigCampo(F: TField; const ALabel, AFormat: string);
  begin
    if F = nil then Exit;
    if ALabel <> '' then
      F.DisplayLabel := ALabel;
    if AFormat = '' then Exit;
    if F is TFloatField then
      TFloatField(F).DisplayFormat := AFormat
    else if F is TBCDField then
      TBCDField(F).DisplayFormat := AFormat
    else if F is TFMTBCDField then
      TFMTBCDField(F).DisplayFormat := AFormat
    else if F is TDateField then
      TDateField(F).DisplayFormat := AFormat
    else if F is TDateTimeField then
      TDateTimeField(F).DisplayFormat := AFormat
    else if F is TSQLTimeStampField then
      TSQLTimeStampField(F).DisplayFormat := AFormat;
  end;
begin
  // El repositorio entrega la consulta ya abierta. Aqui solo se aplican
  // metadatos de presentacion antes de crear las columnas de la busqueda.
  var oResultado := FRepositorioArticulos.ConsultarArticulosBusqueda(
    DatosCaja.cdsCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
    DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime);
  var oDatos := oResultado.DataSet;
    ConfigCampo(oDatos.FindField('CODIGO_ART_ART'),
                'Código',                '');
    ConfigCampo(oDatos.FindField('DESCRIPCION_ART'),
                'Descripción',           '');
    ConfigCampo(oDatos.FindField('DESCRIPCION_FAM'),
                'Familia',               '');
    ConfigCampo(oDatos.FindField('TEMPORADA'),
                'Temporada',             '');
    ConfigCampo(oDatos.FindField('RAZON_SOCIAL_PROVEEDOR'),
                'Proveedor',             '');
    ConfigCampo(oDatos.FindField('REF_PROVEEDOR'),
                'Ref. proveedor',        '');
    ConfigCampo(oDatos.FindField('CODIGO_TAR_ARTTAR'),
                'Tarifa',                '');
    ConfigCampo(oDatos.FindField('NOMBRE_TAR_TAR'),
                'Nombre tarifa',         '');
    ConfigCampo(oDatos.FindField('PRECIO_FINAL_ARTTAR'),
                'Precio',                '#,##0.00 €');
    ConfigCampo(oDatos.FindField('FECHA_DESDE_ARTTAR'),
                'Desde',                 'dd/mm/yyyy');
    ConfigCampo(oDatos.FindField('FECHA_HASTA_ARTTAR'),
                'Hasta',                 'dd/mm/yyyy');
  if BusquedaVisual.EjecutarBusquedaDataSet(
    'Búsqueda de Artículos en Caja',
    oDatos,
    'frmMtoArtFacSearch',
    Formulario) then
  begin
    Result := oDatos.FieldByName('CODIGO_ART_ART').AsString;
  end
  else
  begin
    Result := '';
  end;
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
  FswArtAPopup := TStopwatch.StartNew;
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
    if (NumAtributos > 0) and (SkuDetectado = CodigoPadre) then
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
  if (DatosCaja = nil) or not DatosCaja.cdsLineas.Active then
    Exit;
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

function TEditorLineasCajaVcl.RellenarDatosArticuloEnDataset(
  const ACodigo: string): Boolean;
var
  Resultado: TResultadoPreparacionArticuloVenta;
  Validador: IArticulosValidador;
  Resolver: IArticulosResolver;
begin
  Result := False;
  FMotivoRechazoArticulo := '';
  if Trim(ACodigo) <> '' then
  begin
    Validador := RepositoriosArticulosPantalla.
      CrearValidadorArticulos(ConexionPrincipal);
    Resolver := RepositoriosArticulosPantalla.
      CrearResolverArticulos(ConexionPrincipal);
    try
      Resultado := PrepararArticuloLineaVenta(
        DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera,
        ACodigo,
        ObtenerResolviendoPorScanner,
        FActualizandoDepositos,
        Validador,
        Resolver,
        ConsultarStock,
        RecalcularPrecioDesdeSku);
      Result := Resultado.Preparado;
      FMotivoRechazoArticulo := Resultado.MotivoRechazo;
      if Resultado.Preparado and (not FActualizandoDepositos) then
        GridRecalc(
          ConexionPrincipal, FRepositorioFacturas, nil,
                   tvLineasOpe, DatosCaja.cdsLineas,
                   DatosCaja.cdsCabecera, ActualizarLabelTotal);
    finally
      Validador := nil;
      Resolver := nil;
    end;
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
  Resolver     : IArticulosResolver;
  Precio       : TArticuloPrecio;
  CodTarifa    : string;
  CodArt       : string;
  FechaFactura : TDateTime;
begin
  if Trim(ASku) = '' then Exit;
  CodTarifa    := DatosCaja.cdsCabecera.FieldByName(
                                       'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
  FechaFactura := DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime;
  CodArt       := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;

  Resolver := RepositoriosArticulosPantalla.CrearResolverArticulos(
    ConexionPrincipal);
  try
    Precio := Resolver.ResolverPrecio(CodArt, ASku, CodTarifa, FechaFactura);
    if not Precio.TieneRegistro then Exit;

    DatosCaja.cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
                                                IfThen(Precio.EsImpIncl,
                                                       'S',
                                                       'N');
    DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
                                                Precio.PrecioSalida;
    DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsCurrency := 1;
    DatosCaja.cdsLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
                                                Precio.PorcentajeDto;

    DatosCaja.cdsLineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                          'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
    GridRecalc(ConexionPrincipal, FRepositorioFacturas, nil,
               tvLineasOpe, DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera, ActualizarLabelTotal);
  finally
    Resolver := nil;
  end;
end;

procedure TEditorLineasCajaVcl.RellenarAtributosDesdeSku(
  const ASku: string);
begin
  // Callback de DatosCaja y pegamento del grid: la escritura vive en
  // inLibCajaVentaOperacion y el lookup se inyecta aqui (14.1).
  RellenarAtributosLineaDesdeSku(
    DatosCaja.cdsLineas,
    ASku,
    RepositoriosArticulosPantalla.
      CrearLookupAtributosArticulos(ConexionPrincipal));
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
      with TcxButtonEditProperties(Col.Properties) do
      begin
        ReadOnly := True;
        Buttons.Clear;
        with Buttons.Add do
        begin
          Default := True;
          Kind := bkEllipsis;
        end;
        OnButtonClick := SeleccionarAtributo;
      end;
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
  if not DatosCaja.cdsLineas.Active then Exit;
  if FActualizandoDepositos then Exit;
  if ARegistroActual = nil then Exit;
  if ARegistroActual.IsNewItemRecord then
  begin
    // La línea nueva conserva el último stock mostrado y queda lista para
    // recibir un código de barras.
    btnF3.Enabled := True;
    btnF8.Enabled := True;
    SolicitarFocoArticuloLineaNueva;
  end
  else if not DatosCaja.cdsLineas.IsEmpty then
  begin
    VieneDeDep := DatosCaja.cdsLineas.FieldByName(
      'VIENE_DE_DEPOSITO').AsString;
    // Deshabilitar F3 y F8 (eliminar) visualmente en líneas de depósito
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
          BE.OnEnter := AbrirPopupAvEnEntrada
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
      Exit;
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
      Exit;
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
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.State = dsBrowse then
  begin
    DatosCaja.cdsLineas.Append;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
    tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
  jvEnterTab.EnterAsTab := False;
end;

procedure TEditorLineasCajaVcl.SalirRejilla(Sender: TObject);
begin
  jvEnterTab.EnterAsTab := True;
end;

procedure TfrmMtoOpeCaja.actBuscarEmpleadosExecute(Sender: TObject);
var
  LCtrl: TWinControl;
  CodigoBuscado: string;
  CurrentEdit: TcxCustomEdit;
begin
  if tvLineasOpe.Controller.FocusedItem <> nil then
  if (tvLineasOpe.Controller.FocusedItem.Tag > 0) then
  begin
    if dsLineas.DataSet.State = dsBrowse then
      dsLineas.DataSet.Edit;
    if not tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      tvLineasOpe.Controller.EditingController.ShowEdit;
    end;
    if tvLineasOpe.Controller.EditingController.IsEditing then
     begin
       CurrentEdit := tvLineasOpe.Controller.EditingController.Edit;
       // F3 sobre una columna de atributo (Color, Talla, ...) abre el popup
       // SeleccionarAvConPaleta directamente, equivalente al antiguo
       // Combo.DroppedDown := True.
       if (CurrentEdit is TcxButtonEdit) then
       begin
         tvLineasOpeAvButtonClick(CurrentEdit, 0);
         Exit;
       end;
    end;
  end;
  LCtrl := Screen.ActiveControl;
  if (LCtrl = btnCodigoEmpleado) or (LCtrl.Parent = btnCodigoEmpleado) then
  begin
    BuscarEmpleados;
  end
  else if (LCtrl = btnCodigoCliente) or (LCtrl.Parent = btnCodigoCliente) then
  begin
    BuscarClientes;
  end
  else
  begin
    if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
    begin
      var VieneDeDep :=
                  DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
        Exit;
    end;
    CodigoBuscado := BuscarArticulo;
    if CodigoBuscado <> '' then
    begin
      if DatosCaja.cdsLineas.State = dsBrowse then
      begin
        if DatosCaja.cdsLineas.IsEmpty then
          DatosCaja.cdsLineas.Append
        else
          DatosCaja.cdsLineas.Edit;
      end;
      if RellenarDatosArticuloEnDataset(CodigoBuscado) then
      begin
        var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
        var SkuDetectado := DatosCaja.cdsLineas.FieldByName(
               'CODIGO_UNIDAD_FACLIN').AsString; // <-- Rescatamos el SKU
        // Validación parametrizada del SKU resuelto en la búsqueda. Si el SKU
        // no existe o no tiene stock (según parámetros), descartamos la línea.
        if (Trim(SkuDetectado) <> '') and (SkuDetectado <> CodArticulo) and
           not ValidarSkuParaVenta(SkuDetectado) then
        begin
          EliminarLineaVentaPorValidacion(DatosCaja.cdsLineas);
          Exit;
        end;
        ActualizarColumnasDinamicas(CodArticulo);
        var NumAtributos := FEditorLineas.NumeroAtributosActual;
        if (Trim(SkuDetectado) <> '') and (NumAtributos > 0) then
        begin
           RellenarAtributosDesdeSku(SkuDetectado);
        end;
        cxgrdLineasOpe.SetFocus;
        // Comprobamos si es un SKU completo (el código de unidad es distinto al
        // padre)
        var EsSkuCompleto := (Trim(SkuDetectado) <> '')
           and (SkuDetectado <> CodArticulo);
        // Supongamos que lees tu parámetro global así (ajusta el nombre a tu
        // variable real)
        var AutoPasarLinea :=
          ParametrosCaja.GetBool('vgerMoverLineaIdentif', False);
        // Si necesita atributos Y NO ES un SKU ya cerrado, nos paramos en la
        // columna de atributos
        if (NumAtributos > 0) and not EsSkuCompleto then
        begin
          var PrimeraCol := ObtenerColumnaPorTag(1);
          if PrimeraCol <> nil then
          begin
            PrimeraCol.Visible := True;
            tvLineasOpe.Controller.FocusedColumn := PrimeraCol;
            tvLineasOpe.Controller.EditingController.ShowEdit;
          end;
        end
        else
        begin
          // El artículo ya está completo (sea simple o un SKU cerrado)
          if AutoPasarLinea then
          begin
            // Forzamos el guardado de la línea actual (si está en edición) para
            // evitar que se pierda
            if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
              DatosCaja.cdsLineas.Post;

            // Creamos línea nueva y ponemos el foco en el buscador de artículos
            DatosCaja.cdsLineas.Append;
            tvLineasOpe.Controller.FocusedColumn := tvArticulo;
            tvLineasOpe.Controller.EditingController.ShowEdit;
          end
          else
          begin
            // Si el parámetro está desactivado, el cajero decide. Lo normal es
            // dejarle en Cantidad.
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.actCargarCtaExecute(Sender: TObject);
begin
  btnF2Click(Sender);
end;

procedure TfrmMtoOpeCaja.AbrirBuscarModificar;
var
  oAnfitrion: IAnfitrionCajaVentanas;
  oConsulta: IConsultaOperacionesCaja;
  oFormulario: TCustomForm;
begin
  if (FCodigoEmpresa = '') or
     (FCodigoAlmacen = '') or
     (FCodigoCaja = '') then
    ShowMessage(SErrorUbicacionCajaBuscarOperacionesNoAsignada)
  else
  begin
    oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
    oConsulta :=
      oAnfitrion.CrearConsultaOperacionesCaja(Application, Permisos);
    oFormulario := oConsulta.FormularioConsultaCaja;
    try
      oFormulario.PopupParent := Self;
      oConsulta.PrepararValores(
        FCodigoEmpresa,
        FCodigoAlmacen,
        FCodigoCaja,
        FFecha);
      oFormulario.Show;
    except
      FreeAndNil(oFormulario);
      raise;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.btnF61Click(Sender: TObject);
begin
  CargarDevolucionPorTicket;
end;

procedure TfrmMtoOpeCaja.CargarDevolucionPorTicket;
var
  Seleccion: TTicketDevolucionSeleccionado;
begin
  // F4: localizar el ticket de origen (escaneo del EAN-13, operación o
  // documento) y cargar sus artículos en negativo. El usuario borra las
  // líneas que no se devuelvan.
  if not OperacionVentaVacia(DatosCaja.cdsLineas) then
    ShowMessage(SErrorDevolucionTicketOperacionEnCurso)
  else
  begin
    if TfrmModalDevolucionTicket.Ejecutar(
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
        CargarRectificacion(
          Seleccion.Serie,
          Seleccion.Numero,
          trcDiferencias,
          tmrMantenerOriginales)
      else
      begin
        ShowMessage(SAvisoDevolucionTicketOtraEmpresa);
        CargarDevolucionOtraEmpresa(
          Seleccion.Serie, Seleccion.Numero, Seleccion.Almacen);
      end;
      GridRecalc(
        ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
                 tvLineasOpe,
                 DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera,
                 ActualizarLabelTotal);
      AsegurarLineaNueva;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.CargarDevolucionOtraEmpresa(
  const ASerie, ANumero, AAlmacen: string);
begin
  // Carga las líneas del ticket en negativo SIN marcar rectificativa
  // fiscal (el ticket es de otra empresa): la operación DV queda
  // referenciada al ticket de origen por SERIE/NUMERO_REF_ORIGEN.
  FDependencias.ServicioRectificacion.Cargar(
    ASerie,
    ANumero,
    trcDiferencias,
    tmrMantenerOriginales,
    DatosCaja.cdsCabecera,
    DatosCaja.cdsLineas);
  if FCaptionPrevio = '' then
    FCaptionPrevio := Caption;
  Caption := FCaptionPrevio + Format(
    SCaptionDevolucionTicketDe, [ASerie, ANumero, AAlmacen]);
end;

procedure TfrmMtoOpeCaja.WMPreguntarVentaOrigen(var Msg: TMessage);
var
  Seleccion: TVentaOrigenSeleccionada;
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
      if TfrmModalSeleccionVentaOrigen.Ejecutar(
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
var
  sMotivo: string;
begin
  // Motivo obligatorio (una vez por operación) si hay devolución
  Result := True;
  if HayLineasNegativasVenta(DatosCaja.cdsLineas) and
     (Trim(FMotivoDevolucion) = '') then
  begin
    if TfrmModalMotivoDevolucion.Ejecutar(Self, sMotivo) then
      FMotivoDevolucion := sMotivo
    else
      Result := False;
  end;
end;

procedure TfrmMtoOpeCaja.btnF10Click(Sender: TObject);
begin
  AbrirBuscarModificar;
end;

procedure TfrmMtoOpeCaja.actBuscarModificarExecute(Sender: TObject);
begin
  btnF10Click(Sender);
end;

procedure TfrmMtoOpeCaja.actEliminarLineaExecute(Sender: TObject);
var
  VieneDeDep: string;
begin
  // NUEVO: Bloqueo de borrado
  if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
  begin
    VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
    if (VieneDeDep = 'S') or (VieneDeDep = 'A') then
    begin
      ShowMessage(SErrorLineaDepositoCajaNoEliminable);
      Exit;
    end;
  end;

  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
    DatosCaja.cdsLineas.Cancel
  else
    if DatosCaja.cdsLineas.State in [dsBrowse] then
      DatosCaja.cdsLineas.Delete;
  AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.actGuardarLayoutExecute(Sender: TObject);
begin
  GuardarLayoutCaja;
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

procedure TfrmMtoOpeCaja.RestaurarLayoutCaja;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  try
    if not Layout.Disponible then Exit;
    Layout.RestaurarGeometria(Self);
    Layout.RestaurarAlturaPanel('StockPanelHeight', pnlBusqueda, 30);
    Layout.RestaurarAnchoPanel('FotoStockWidth',   pnlFotoStock, 50);
    Layout.RestaurarGrid('Lineas', tvLineasOpe);
  finally
    FreeAndNil(Layout);
  end;
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
  if Cacheado then
  begin
    Exit;
  end;
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
//  tvLineasOpe.ApplyBestFit(nil, True, False);
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
        AsegurarLineaNueva;
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

procedure TfrmMtoOpeCaja.BuscarClientes;
var
  formulario: TfrmMtoSearch;
  Consulta: IResultadoConsultaCaja;
begin
  Consulta := FDependencias.RepositorioConsultas.ConsultarClientes;
  formulario := TfrmMtoSearch.Create(nil);
  try
    formulario.Name := 'frmMtoCliSearch';
    formulario.Caption := STituloBusquedaClientes;
    formulario.dsTablaG.DataSet := Consulta.DataSet;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
    begin
      btnCodigoCliente.Text :=
        Consulta.DataSet.FieldByName('Código').AsString;
      if btnCodigoCliente.ValidateEdit(True) then
      begin
        cxgrdLineasOpe.SetFocus;
      end;
    end;
  finally
    FreeAndNil(formulario);
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarClientes;
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
    if not Encontrado then
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
        FRepositoriosTicketsCajaPantalla.CrearRepositorioTraspasoTicket,
        FRepositoriosTicketsCajaPantalla.CrearRepositorioTicketsCaja,
        RegistroLog,
        ConexionPrincipal,
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
    Exit;
  end;

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
  PoblarAtributosLineasDeposito;
  tvFechaOperacion.Visible := True;
  MostrarColumnasCuentaCliente(True);
  // 5. Preparamos la línea en blanco para seguir escaneando (ahora ya no rompe
  // la caché)
  AsegurarLineaNueva;
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

procedure TfrmMtoOpeCaja.btnF2Click(Sender: TObject);
begin
  CargarDepositosF2;
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
    TargetForm := TfrmMtoOpeCaja.Create(Application, Permisos);
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

procedure TfrmMtoOpeCaja.BuscarEmpleados;
var
  formulario: TfrmMtoSearch;
  Consulta: IResultadoConsultaCaja;
begin
  Consulta := FDependencias.RepositorioConsultas.ConsultarEmpleados;
  formulario := TfrmMtoSearch.Create(nil);
  try
    formulario.Name := 'frmMtoEmpCajSearch';
    formulario.Caption := STituloBusquedaEmpleadosCaja;
    formulario.dsTablaG.DataSet := Consulta.DataSet;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
    begin
      btnCodigoEmpleado.Text :=
        Consulta.DataSet.Fields[0].AsString;
      if btnCodigoEmpleado.ValidateEdit(True) then
      begin
        btnCodigoCliente.SetFocus;
      end;
    end;
  finally
    FreeAndNil(formulario);
  end;
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
  FreeAndNil(FEditorLineas);
  FLecturas.RepositorioFacturas := nil;
  FLecturas.ConsultaStock := nil;
  FIncidenciasSql := nil;
  FRepositoriosArticulosPantalla := nil;
  FRepositoriosCajaPantalla := nil;
  FRepositoriosTicketsCajaPantalla := nil;
  FDependencias := Default(TContextoDependenciasOperacionCaja);
  FEntrada.Aplicacion := nil;
  FreeAndNil(FEntrada.Lector);
end;

// Carga en imgFotoStock la foto a 300 px del articulo / SKU de la
// linea activa. Lo invoca DsLineasDataChange al cambiar de registro.
procedure TEditorLineasCajaVcl.RefrescarFotoStock;
var
  sArt : string;
  sSku : string;
  info : TFotoInfo;
  sRuta: string;
  png  : TPngImage;
begin
  if Assigned(imgFotoStock) and Assigned(dsLineas) then
  begin
    LeerArtSkuDeDataSet(dsLineas.DataSet, sArt, sSku);
    // La linea nueva conserva la foto del ultimo articulo introducido.
    if sArt <> '' then
    begin
      imgFotoStock.Picture.Assign(nil);
      info  := FotosArticulos.Resolver(sArt, sSku);
      sRuta := FotosArticulos.RutaFoto(info, frPx300);
      if sRuta <> '' then
      begin
        png := TPngImage.Create;
        try
          png.LoadFromFile(sRuta);
          imgFotoStock.Picture.Assign(png);
        finally
          FreeAndNil(png);
        end;
      end;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.NotificarCambioLinea(
  Sender: TObject; AField: TField);
begin
  // Solo refrescamos cuando cambia el registro activo (Field = nil),// no en cada cambio de columna.
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
  FRepositoriosArticulosPantalla :=
    ObtenerCompositorArticulosPantalla(Self).
      CrearRepositoriosArticulosPantalla(Name);
  FRepositoriosCajaPantalla := ObtenerCompositorCajaPantalla(Self).
    CrearRepositoriosCajaPantalla(Name);
  FRepositoriosTicketsCajaPantalla :=
    ObtenerCompositorTicketsCajaPantalla(Self).
      CrearRepositoriosTicketsCajaPantalla(Name);
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
  InicializarEntradaCajaVcl(Self);
  InicializarServiciosOperacionCajaVcl(Self);
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := nil;
  dsLineas.OnDataChange := DsLineasDataChange;
  InicializarEditorLineasCajaVcl(Self);
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(tvUds, tvTipoCantidad, UnidadesMedida);
  DatosCaja.OnUpdateTotal := ActualizarLabelTotal;
  DatosCaja.OnRellenarArticulo  := RellenarDatosArticuloEnDataset;
  DatosCaja.OnRellenarAtributos := RellenarAtributosDesdeSku;
  DatosCaja.OnRecalcularLineas := RecalcularLineasDesdeDM;
  lblFechaCaja.OnDblClick := lblFechaCajaDblClick;
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
  with dbtvBusq.DataController do
  begin
    DataModeController.GridMode := True;
    DataModeController.SyncMode := False;
    Filter.AutoDataSetFilter := False;
    Options := Options - [dcoImmediatePost, dcoGroupsAlwaysExpanded];
  end;
  with dbtvBusq.OptionsBehavior do
  begin
    IncSearch := False;
    IncSearchItem := nil;
  end;
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
  // F4 -> devolución escaneando / localizando el ticket de origen
  if (Key = VK_F4) then
  begin
    btnF61.Click;
    Key := 0;
  end;
  // Ctrl+F12 -> resetear layout
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    ResetearLayout(
      Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
    Key := 0;
  end;
end;

// Ctrl+U: consulta de stock del articulo de la linea que se esta metiendo.
// Lee el (articulo, sku) de la linea enfocada con el mismo helper que usan
// los mantenimientos via TfrmMtoGen.ResolverArtSkuActivo (CODIGO_ART_FACLIN
// y CODIGO_UNIDAD_FACLIN estan entre sus alias). Si la linea aun no tiene
// articulo resuelto, abre la consulta vacia con su buscador.
procedure TfrmMtoOpeCaja.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  // Articulo/sku de la linea de caja en foco (vacio si aun no hay).
  ACodArt := '';
  ACodSku := '';
  if Assigned(DatosCaja) and Assigned(DatosCaja.cdsLineas) then
    inLibFotos.LeerArtSkuDeDataSet(DatosCaja.cdsLineas, ACodArt, ACodSku);
end;

procedure TfrmMtoOpeCaja.actConsultaStockExecute(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  ResolverArtSkuStock(sArt, sSku);
  inMtoStockConsulta.MostrarStockConsulta(sArt,
    sSku);
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
begin
  RestaurarLayoutCaja;
  ActualizarFoco;
end;

procedure TEditorLineasCajaVcl.AbrirPopupAvEnEntrada(Sender: TObject);
var
  BE: TcxCustomEdit;
begin
  // OnEnter single-shot: cuando el usuario entra en una celda Color/Talla
  // vacia, disparamos el popup automaticamente (sustituye a la antigua
  // ForzarDespliegue que desplegaba el TcxComboBox).
  //
  // No abrimos el popup en linea: cuando WMAvanzarAtribCaja salta de Color
  // a Talla, ShowEdit/InitEdit/OnEnter encadenan en el mismo callstack y
  // el TcxButtonEdit recien creado para Talla aun no ha terminado de
  // parentar; ClientToScreen dentro de tvLineasOpeAvButtonClick pediria
  // Handle -> Parent -> EInvalidOperation. PostMessage hace que el handler
  // retorne y cxGrid acabe la colocacion antes de abrir el popup.
  if not (Sender is TcxCustomEdit) then Exit;
  BE := TcxCustomEdit(Sender);
  BE.OnEnter := nil;
  PostMessage(Formulario.Handle, WM_ABRIR_POPUP_AV, 0, 0);
end;

procedure TEditorLineasCajaVcl.AbrirPopupAtributo;
var
  CurrentEdit: TcxCustomEdit;
begin
  // Disparado por AbrirPopupAvEnEntrada via PostMessage. Para entonces
  // cxGrid ya termino de parentar el TcxButtonEdit, asi que podemos
  // llamar al click handler con el editor actual.
  // Si FswArtAPopup esta en marcha, registramos el tiempo total desde
  // tvArticuloPropertiesValidate hasta aqui — es lo que el usuario
  // percibe como "demora entre Enter del codigo y desplegable".
  if FswArtAPopup.IsRunning then
  begin
    FswArtAPopup.Stop;
  end;
  if not tvLineasOpe.Controller.EditingController.IsEditing then Exit;
  CurrentEdit := tvLineasOpe.Controller.EditingController.Edit;
  if (CurrentEdit is TcxButtonEdit)
     and (CurrentEdit.Tag >= 1) and (CurrentEdit.Tag <= 5) then
    SeleccionarAtributo(CurrentEdit, 0);
end;

procedure TEditorLineasCajaVcl.RegistrarValorAtributo(
  AOrden: Integer; const AValorNuevo: string);
var
  SkuNuevo: string;
  NumAtributosRequeridos: Integer;
begin
  // Aplica el AV elegido por el usuario en el popup al campo ATTRn_VALOR
  // y recalcula el SKU final (CODIGO_UNIDAD_FACLIN). Si el SKU queda
  // completo, dispara el recalculo de precio. La finalizacion de la linea
  // (validar SKU, consultar stock, avanzar foco) se hace fuera para no
  // mover el foco con el editor todavia activo: ver tvLineasOpeAvButtonClick.
  // Sustituye al antiguo OnAtributoChanged del TcxComboBox.
  if (AOrden < 1) or (AOrden > 5) then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;
  if DatosCaja.cdsLineas.State = dsBrowse then
    DatosCaja.cdsLineas.Edit;
  if not (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  DatosCaja.cdsLineas.FieldByName(
    'ATTR' + IntToStr(AOrden) + '_VALOR').AsString := AValorNuevo;

  SkuNuevo := DatosCaja.GenerarSkuFinal(
                DatosCaja.cdsLineas.FieldByName(
                  'CODIGO_ART_FACLIN').AsString);
  if Trim(SkuNuevo) = '' then
    SkuNuevo := DatosCaja.cdsLineas.FieldByName(
                  'CODIGO_ART_FACLIN').AsString;
  DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := SkuNuevo;

  NumAtributosRequeridos := DatosCaja.cdsLineas.FieldByName(
                              'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  if SkuLineaCajaAdmitePrecio(SkuNuevo, NumAtributosRequeridos) then
    RecalcularPrecioDesdeSku(SkuNuevo);
end;

procedure TEditorLineasCajaVcl.FinalizarUltimoAtributo;
var
  SkuNuevo : string;
  EstabaInsertando : Boolean;
begin
  // Logica que antes vivia inline en cxGrid1DBTableView1EditKeyDown cuando
  // se confirmaba el ultimo atributo de la linea. Encapsulada para poder
  // invocarla desde tvLineasOpeAvButtonClick (popup) sin duplicar codigo.
  if FProcesandoAtributo then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;

  // Defensivo: aseguramos que no queda un inplace editor activo antes de
  // empezar a hacer Cancel/Append. Los broadcasts del data link (sobre
  // todo tras el ShowMessage de "no hay stock") intentarian refrescar el
  // TcxButtonEdit y, si cxGrid ya lo desparento, salta EInvalidOperation.
  // HideEdit(False): no intentamos PostEditValue, los campos ya estan
  // escritos por RegistrarValorAtributo.
  if tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(False);

  FProcesandoAtributo := True;
  DatosCaja.cdsLineas.DisableControls;
  try
    EstabaInsertando := (DatosCaja.cdsLineas.State = dsInsert);
    SkuNuevo := DatosCaja.cdsLineas.FieldByName(
                                       'CODIGO_UNIDAD_FACLIN').AsString;

    if EstabaInsertando and ConsolidarSiExiste(SkuNuevo) then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      if not DatosCaja.cdsLineas.IsEmpty then
        if DatosCaja.cdsLineas.FieldByName(
                   'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo then
          DatosCaja.cdsLineas.Delete;
      DatosCaja.cdsLineas.EnableControls;
      DatosCaja.cdsLineas.Append;
      tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      tvLineasOpe.Controller.EditingController.ShowEdit;
      Exit;
    end;

    if not ValidarSkuParaVenta(SkuNuevo) then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      if not DatosCaja.cdsLineas.IsEmpty
         and (DatosCaja.cdsLineas.FieldByName(
                      'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
        DatosCaja.cdsLineas.Delete;
      DatosCaja.cdsLineas.EnableControls;
      //dbtvStock.ClearItems;
      DatosCaja.cdsLineas.Append;
      tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      tvLineasOpe.Controller.EditingController.ShowEdit;
      Exit;
    end;

    ConsultarStock(SkuNuevo);
  finally
    FProcesandoAtributo := False;
    DatosCaja.cdsLineas.EnableControls;
  end;

  if ParametrosCaja.GetBool('vgerMoverLineaIdentif', True) then
  begin
    if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
      DatosCaja.cdsLineas.Post;
    DatosCaja.cdsLineas.Append;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
  end
  else
    tvLineasOpe.Controller.FocusedColumn := tvDescripcion;

  tvLineasOpe.Controller.EditingController.ShowEdit;
end;

procedure TEditorLineasCajaVcl.SeleccionarAtributo(
  Sender: TObject; AButtonIndex: Integer);
var
  Col       : TcxGridColumn;
  Orden     : Integer;
  ArtPadre  : string;
  AvActual  : string;
  NombreAtb : string;
  IdVa      : string;
  AvNuevo   : string;
  Avs       : TArray<string>;
  Mapa      : TDictionary<string, string>;
  EditCtrl  : TWinControl;
  ScrPt     : TPoint;
  WidHint   : Integer;
begin
  // Click en el boton de una columna de atributo (Color, Talla, ...): abre
  // el popup SeleccionarAvConPaleta con cuadraditos de paleta. Mismo flujo
  // que inMtoInventarios.tvLineasSkuPropertiesButtonClick.
  Col := tvLineasOpe.Controller.FocusedColumn;
  if Col = nil then Exit;
  Orden := Col.Tag;
  if (Orden < 1) or (Orden > 5) then Exit;
  if not DatosCaja.cdsLineas.Active then Exit;
  if DatosCaja.cdsLineas.IsEmpty then Exit;

  ArtPadre  := DatosCaja.cdsLineas.FieldByName(
                 'CODIGO_ART_FACLIN').AsString;
  AvActual  := DatosCaja.cdsLineas.FieldByName(
                 'ATTR' + IntToStr(Orden) + '_VALOR').AsString;
  NombreAtb := DatosCaja.cdsLineas.FieldByName(
                 'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString;

  CargarAvsValidosArticulo(
    ArtPadre,
    Orden,
    FRepositoriosArticulosPantalla.
      CrearLookupAtributosArticulos(ConexionPrincipal),
    Avs);
  if Length(Avs) = 0 then
  begin
    ShowMessage(SErrorValoresAtributoCajaNoDefinidos);
    Exit;
  end;

  IdVa := '';
  Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
  if Mapa <> nil then
    Mapa.TryGetValue(UpperCase(Trim(NombreAtb)), IdVa);

  // Posicion del popup justo debajo del editor. SeleccionarAvConPaleta
  // acepta (-1, -1) para auto-centrar; lo usamos como fallback. cxGrid
  // mantiene los TcxButtonEdit en un pool y a veces el editor inplace que
  // recibimos en Sender (sea via OnButtonClick, OnEnter via
  // AbrirPopupAvEnEntrada, o F3 via actBuscarEmpleadosExecute) llega sin
  // Parent en la pasada — ClientToScreen pide Handle, Handle pide Parent
  // y salta EInvalidOperation. Comprobamos HasParent y, por si hay carrera
  // entre el check y la llamada, envolvemos en try/except.
  ScrPt.X := -1; ScrPt.Y := -1;
  WidHint := 120;
  if (Sender is TWinControl) and TWinControl(Sender).HasParent then
  begin
    EditCtrl := TWinControl(Sender);
    try
      ScrPt   := EditCtrl.ClientToScreen(Point(0, EditCtrl.Height));
      WidHint := EditCtrl.Width;
    except
      on E: EInvalidOperation do
      begin
        ScrPt.X := -1;
        ScrPt.Y := -1;
        WidHint := 120;
      end;
    end;
  end;

  if not SeleccionarAvConPaleta(ConexionPrincipal,IdVa, Avs, AvActual, AvNuevo,
                                 ScrPt.X, ScrPt.Y, WidHint, ArtPadre) then
    Exit;

  RegistrarValorAtributo(Orden, AvNuevo);

  // Reflejamos el AV nuevo en el editor para que el usuario lo vea sin
  // tener que esperar a que se reabra la celda. Solo si Sender sigue
  // parentado: durante el modal SeleccionarAvConPaleta cxGrid puede
  // haberle quitado el Parent al editor inplace (perdida de foco) y un
  // EditValue := X sobre un control sin parent dispara EInvalidOperation
  // 'no tiene ventana principal'.
  if (Sender is TcxCustomEdit) and TWinControl(Sender).HasParent then
  begin
    try
      TcxCustomEdit(Sender).EditValue := AvNuevo;
    except
      on E: EInvalidOperation do
        // Defensivo: si cxGrid desparenta el editor entre el HasParent
        // de arriba y el set EditValue, seguimos sin pintar — el data
        // link ya tiene el valor via RegistrarValorAtributo.
        RegistroLog.RegistrarAviso(
          'CajaOpe: EditValue del editor inplace ignorado: ' +
          E.Message);
    end;
  end;

  // Cerramos el editor inplace ANTES de tocar cdsLineas / cambiar foco. Usamos
  // HideEdit(False) porque RegistrarValorAtributo ya escribio el campo: pedir
  // PostEditValue (HideEdit(True)) sobre un editor que cxGrid pudo
  // desparentar durante el popup vuelve a disparar EInvalidOperation.
  if tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(False);

  // Diferimos via PostMessage para soltar el callstack del OnButtonClick.
  // Asi cxGrid termina de limpiar el editor inplace (que ya HideEdit'amos)
  // antes de que FinalizarUltimoAtributo abra el ShowMessage de "no hay
  // stock" o haga Cancel/Append. Si lo hacemos en linea, los DataChange
  // del EnableControls/Append intentan refrescar el TcxButtonEdit que
  // cxGrid todavia tiene en su pool con Parent = nil -> EInvalidOperation.
  if PasoTrasAtributoLineaCaja(Orden, FNumAtributosActual) =
     palFinalizar then
    PostMessage(Formulario.Handle, WM_FINALIZAR_ATRIB_CAJA, 0, 0)
  else
    PostMessage(Formulario.Handle, WM_AVANZAR_ATRIB_CAJA, Orden + 1, 0);

end;

procedure TEditorLineasCajaVcl.FinalizarAtributos;
var
  bSkuCompleto: Boolean;
begin
  // Ejecuta FinalizarUltimoAtributo fuera del callstack del OnButtonClick
  // del TcxButtonEdit. Ver tvLineasOpeAvButtonClick para el motivo.
  // El mensaje solo es valido cuando ya se han elegido todos los atributos:
  // asi un mensaje ajeno o atrasado nunca valida el articulo padre como SKU.
  bSkuCompleto := False;
  if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
    bSkuCompleto := SkuLineaCajaCompleto(
      DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString,
      DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString,
      DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger);
  if bSkuCompleto then
    FinalizarUltimoAtributo;
end;

procedure TEditorLineasCajaVcl.AvanzarAtributo(
  ANumeroColumna: Integer);
var
  SigCol : TcxGridDBColumn;
  sw : TStopwatch;
begin
  // Avanza el foco a la siguiente columna de atributo. Diferido por la
  // misma razon que WMFinalizarAtribCaja.
  sw := TStopwatch.StartNew;
  SigCol := ObtenerColumnaPorTag(ANumeroColumna);
  if (SigCol <> nil) and SigCol.Visible then
  begin
    tvLineasOpe.Controller.FocusedColumn := SigCol;
    tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
//  LogPerfCaja('CajaOpe.AvanzarAtrib',//    Format('tag=%d | total=%d ms',//           [Integer(Msg.WParam),sw.ElapsedMilliseconds]));
end;

procedure TfrmMtoOpeCaja.GuardarLayoutCaja;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarAlturaPanel('StockPanelHeight', pnlBusqueda);
    Layout.GuardarAnchoPanel('FotoStockWidth',    pnlFotoStock);
    Layout.GuardarGrid('Lineas', tvLineasOpe);
    if Layout.PreguntarYGrabar('Personalización Caja') then
      ShowMessage(SInfoLayoutCajaGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

function TfrmMtoOpeCaja.IntentarCerrar: Boolean;
begin
  Result := True;
  if (csDestroying in ComponentState) then Exit;
  if (DatosCaja.cdsLineas.Active) and (not DatosCaja.cdsLineas.IsEmpty) then
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
    begin
      Result := False;
    end;
  end
  else
  begin
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
    if (tvLineasOpe.Columns[i].Tag = ANumeroColumna) then
    begin
      Result := (tvLineasOpe.Columns[i] as TcxGridDBColumn);
      Exit;
    end;
end;

procedure TfrmMtoOpeCaja.Timer1Timer(Sender: TObject);
begin
  ActualizarRelojCaja;
end;

end.
