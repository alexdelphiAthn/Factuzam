{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPedidosCompra                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       1.1.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Mantenimiento de pedidos de COMPRA.                                       }
{    Cabecera + lineas sobre fza_pedidos_compra. La logica de movimientos     }
{    de stock NO existe en pedidos (es compromiso, no entrada): el AfterPost  }
{    de la cabecera sincroniza fza_articulos_pdte_recibir y el boton          }
{    "Crear albaran" genera un albaran de compra para el almacen elegido,    }
{    que es quien dispara los movimientos via                                  }
{    inLibAlbaranesCompraMovimientos.                                          }
{                                                                              }
{    Modo "Tallas en horizontal": delegado en TGridPivoteCompra              }
{    (inLibGridPivoteCompra). Esta libreria orquesta el filtrado, cache,      }
{    publicacion de cantidades y pintado de celdas, y se comparte con el     }
{    Mto de albaranes de compra.                                              }
{******************************************************************************}
unit inMtoPedidosCompra;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni, System.Generics.Collections, System.Types,
  inMtoDocumento, dxSkinsCore, dxSkinBlue, dxSkinsForm,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  Vcl.Menus, JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls,
  cxRadioGroup, cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo,
  cxCheckBox, cxGroupBox, cxDBLabel, cxButtonEdit, cxGridBandedTableView,
  cxGridDBBandedTableView,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridPivoteVenta,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibAplicacionArticuloCompraIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibComprasPantallaIntf,
  inLibPermisosIntf,
  inLibRepositoriosPantallaIntf,
  inLibPedidosCompraIntf,
  UniDataPedidosCompra, cxBlobEdit, System.Actions, Vcl.ActnList,
  dxShellDialogs, cxSplitter, inLibDocumento, inLibDocumentoIntf;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;
  ID_VA_COLOR     = 'CO';
  NOMBRE_PANTALLA_PEDIDOS_COMPRA = 'frmMtoPedidosCompra';
  // Ancho (px) de cada columna talla en modo pivote. Tambien actua de
  // suelo tras ApplyBestFit: el BestFit mide solo el Value numerico corto
  // de la celda y, al ignorar el custom-draw (rotulo de talla + sub-cifras
  // Pedido/Recibido/A recibir), dejaria las columnas tan estrechas que el
  // rotulo de 2 digitos (p.ej. "36") se corta a "3".
  ANCHO_TALLA_PX  = 50;

type
  TfrmMtoPedidosCompra = class(TfrmMtoDocumento)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcPedido:            TcxPageControl;
    tsLineasPedido:      TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasPedido:   TcxGrid;
    tvLineasPedido:      TcxGridDBTableView;
    cxgrdlvlLineasPedido: TcxGridLevel;
    // Pestania "Albaranes": lista (solo lectura) de los albaranes de
    // compra ya creados desde este pedido.
    tsAlbaranesPedc:       TcxTabSheet;
    cxgrdAlbaranesPedc:    TcxGrid;
    tvAlbaranesPedc:       TcxGridDBTableView;
    cxgrdlvlAlbaranesPedc: TcxGridLevel;

    // Cabecera
    lblNroPedido:    TcxLabel;
    txtNUMERO_PEDC:  TcxDBTextEdit;
    lblSeriePedido:  TcxLabel;
    // Serie en combo editable: lista las series 'PC' de la empresa
    // (fza_empresas_series) y permite teclear una nueva.
    cbbSERIE_PEDC:   TcxDBComboBox;
    lblFechaPedido:  TcxLabel;
    dteFECHA_PEDC:   TcxDBDateEdit;
    lblFechaPrevista:TcxLabel;
    dteFECHA_PREVISTA_PEDC: TcxDBDateEdit;
    lblFechaTopeRecepcionPedc: TcxLabel;
    dteFECHA_TOPE_RECEPCION_PEDC: TcxDBDateEdit;
    lblEstadoPedido: TcxLabel;
    txtESTADO_PEDC:  TcxDBTextEdit;
    lblCodigoEmpresa:   TcxLabel;
    btnCODIGO_EMP_PEDC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_PEDC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombrePedc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_PEDC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    cbbCODIGO_ALM_PEDC: TcxDBLookupComboBox;
    lblTemporada:       TcxLabel;
    cbbTemporadaPedc:   TcxDBLookupComboBox;
    lblCabCantidadPedidaPedc: TcxLabel;
    curCabCANTIDAD_PEDIDA_PEDC: TcxDBCurrencyEdit;
    lblCabCantidadRecibidaPedc: TcxLabel;
    curCabCANTIDAD_RECIBIDA_PEDC: TcxDBCurrencyEdit;
    lblCabCantidadPendientePedc: TcxLabel;
    curCabCANTIDAD_PENDIENTE_RECEPCION_PEDC: TcxDBCurrencyEdit;
    lblCabCantidadAAlbaranarPedc: TcxLabel;
    curCabCANTIDAD_A_ALBARANAR_PEDC: TcxCurrencyEdit;

    // Totales
    lblTotalBases:           TcxLabel;
    curTOTAL_BASES_PEDC:     TcxDBCurrencyEdit;
    lblTotalImpuestos:       TcxLabel;
    curTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit;
    lblTotalLiquido:         TcxLabel;
    curTOTAL_LIQUIDO_PEDC:   TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_PEDC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_PEDC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_PEDC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_PEDC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_PEDC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_PEDC: TcxDBCurrencyEdit;
    lblTotalesTotalPrendas: TcxLabel;
    curTotalesTOTAL_PRENDAS_PEDC: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_PEDC: TcxDBLookupComboBox;
    grpDesgloseImpuestos: TGroupBox;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;

    // Observaciones
    memObservaciones: TcxDBMemo;
    btnTallasHorizontal:  TcxButton;
    btnExpandirRecibidos: TcxButton;
    // Atajo: rellena 'A recibir' con el pendiente de TODAS las
    // tallas de la fila focused. Activo solo en pivote expandido.
    btnRecibirFilaEntera: TcxButton;
    // Columna no-bound editable solo en modo vertical (pivote OFF).
    // El usuario teclea aqui "A recibir" por linea SKU. Se oculta
    // cuando entra en modo pivote.
    colLineaPedcARecibir: TcxGridDBColumn;
    colLineaPedcCODIGO_UNIDAD: TcxGridDBColumn;
    btnCrearAlbaran: TcxButton;
    btnPegatinas: TcxButton;
    lblContextoTalla: TcxLabel;
    ActionList1: TActionList;
    actArticulos: TAction;
    btnRecibirTodo: TcxButton;
    // Atajo Ctrl+May+A en la pestania Albaranes: abre el albaran de
    // compra seleccionado en la rejilla.
    actIrDocumento: TAction;
    actIrProveedor: TAction;
    Panel1: TPanel;
    btnIraalbaran: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    procedure btnExpandirRecibidosClick(Sender: TObject);
    procedure btnRecibirFilaEnteraClick(Sender: TObject);
    procedure tvLineasPedidoFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasPedidoCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasPedidoEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure tvLineasPedidoInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
    procedure tvLineasPedidoFocusedItemChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedItem, AFocusedItem: TcxCustomGridTableItem);
    procedure cxgrdLineasPedidoEnter(Sender: TObject);
    procedure cxgrdLineasPedidoExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_PEDCPropertiesInitPopup(Sender: TObject);
    procedure btnRecibirTodoClick(Sender: TObject);
    procedure btnCODIGO_EMP_PEDCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnCODIGO_EMP_PEDCPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_PRV_PEDCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_ALM_PEDCPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_PEDCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure cbbCODIGO_PRV_PEDCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure colLineaPedcCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaPedcCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaPedcCODIGO_UNIDADPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure btnIraalbaranClick(Sender: TObject);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    // "Color": cuadradito del color basico + texto del color del SKU
    // (AV.AV, p.ej. "VERDE"). Columna unica - antes habia 2 (Color
    // proveedor + C. Basico) pero el usuario decidio unificarlas.
    FColColorPivot          : TcxGridDBColumn;
    // Reservado por compatibilidad con la libreria. Siempre nil ahora
    // que la columna Color es unica.
    FColColorProveedorPivot : TcxGridDBColumn;
    FBasicosColor           : TArray<string>;
  protected
    FAplicacionArticuloCompra: IAplicacionArticuloCompra;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributos: IArticulosAtributosLookup;
    FRecepcionPedido: IRecepcionPedidoCompra;
    FConsultasPedido: IConsultasPedidoCompraPantalla;
    FBusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    FBusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    FBusquedasArticulos: IBusquedasCompraPersistencia;
  private
    FAfterPostLineasOriginal: TDataSetNotifyEvent;
    FEstiloRecepcionVencida : TcxStyle;
    // Guarda contra la reentrancia que provoca PersistirPreferenciaPivote:
    // su Edit + set field + Post dispara OnDataChange tres veces, y entre
    // el Edit y el set la cabecera todavia tiene el ESPIVOTE viejo. Sin
    // este guardia el hook auto-toggle veria "field='N' y Activo=True"
    // y desactivaria justo despues de activar.
    FInToggleClick   : Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    // Valores de las columnas de atributo del modo Desglose, derivados
    // AL VUELO del SKU de la fila (segmentos tras el articulo). Sin
    // estado: no hay Values[] no-bound que se reseteen con el grid.
    procedure AtribGetDataText(Sender: TcxCustomGridTableItem;
                               ARecordIndex: Integer; var AText: string);
    procedure CargarBasicosColorArticulo(const ACodigoArt: string);
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombrePedc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataPedidosCompra
    // .unqryPrvDataPedc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterOpenHook(DataSet: TDataSet);
    procedure PersistirPreferenciaPivote;
    function  RecogerCeldasARecibirVertical(
                                const ACodigoAlm: string):
                                TArray<TCeldaARecibir>;
    // Hook unificado para OnEditValueChanged de columnas talla: en
    // pivote lo resuelve la libreria de compras; fuera de pivote
    // delega en el gestor de tallas como antes.
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject; var DisplayValue: Variant;
                                var ErrorText: TCaption;
                                var Error: Boolean);
    function BuscarArticuloPedidoCompra: string;
    function BuscarSkuPedidoCompra(const ACodigoArt: string): string;
    function ArticuloLineaActivaPedidoCompra: string;
    procedure AplicarArticuloPedidoCompra(const ACodigoArt: string);
    procedure EnfocarSkuPedidoCompra(AAbrirBusqueda: Boolean);
    procedure PresentarArticuloPedidoCompra(
      const AResultado: TResultadoAplicacionArticuloCompra);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaPedidoCompra;
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
    function PuedeActivarTallasHorizontal(var AMensaje: string): Boolean;
    procedure colLineaPedcCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLinPedcColorPivotButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    function  ColumnaPedidosCompraExiste(const ANombreColumna: string): Boolean;
    // Devuelve el almacen efectivo de la primera linea del pedido
    // (CODIGO_ALMACEN_PEDCLIN, con fallback al CODIGO_ALM_PEDC de
    // cabecera). Usado como default del combo en el modal Crear
    // albaran. Vacio si el pedido no tiene lineas.
    function  AlmacenEfectivoPrimeraLinea(const ASerie,
                                          ANumero: string): string;
    // Devuelve el almacen efectivo de la primera linea en modo vertical
    // cuyo "A recibir" sea > 0. Sin tecleos devuelve ''.
    function  PrimerAlmacenARecibirVertical: string;
    // Rellena la columna no-bound "A recibir" (modo vertical) de TODAS
    // las lineas del pedido con su pendiente (Pedida - Recibida). Las
    // lineas sin pendiente quedan a Null. Devuelve cuantas se rellenaron.
    function  RellenarARecibirVerticalTodo: Integer;
    function  TotalAAlbaranarVertical: Double;
    function  TotalAAlbaranar: Double;
    procedure RefrescarCantidadAAlbaranar;
    // Clamp de la columna "A recibir" en modo vertical: el maximo es el
    // pendiente de la linea (CANTIDAD - CANTIDAD_RECIBIDA).
    procedure ARecibirVerticalEditValueChanged(Sender: TObject);
    procedure GridListaGetContentStyle(Sender: TcxCustomGridTableView;
                ARecord: TcxCustomGridRecord;
                AItem: TcxCustomGridTableItem;
                var AStyle: TcxStyle);
    // ApplyBestFit + ensanche para la columna Color (el cuadradito de
    // color que pinta FColColorPivot ocupa ~20 px que BestFit no mide).
    procedure BestFitConSwatch;
    // Rotulo de modo en la pestania de lineas, como en ventas.
    procedure ActualizarCaptionModoLineas;
  private
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal, con el
    // MISMO pivote tallashorped de pedidos de venta (bandas Pedido /
    // A recibir / Pendiente sobre lineas SKU reales, sin tabla de
    // celdas). El Construir hace ClearItems: las columnas del dfm y
    // las del pivote de compras antiguo mueren y las del documento se
    // recrean en runtime. El pivote de compras (FPivote/ESPIVOTE)
    // queda RETIRADO de esta pantalla (decision 09/07/26).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    // Guarda de reentrada del rebuild: el Desempaquetar/Post de la
    // construccion recalcula totales de cabecera y dispara
    // dsTablaGDataChangeHook, que sin esta guarda relanzaba
    // ConstruirModoEntrada en mitad de la construccion.
    FConstruyendoModo: Boolean;
    // Pedido (serie|numero) para el que se construyo el modo: el hook
    // de DataChange solo reconstruye el modo bandas si esta clave
    // cambia. Un Post de la MISMA cabecera (totales, INSTANTE_MODIF)
    // tambien dispara DataChange y reconstruir ahi encadenaba una
    // tormenta de SQL por cada click (10/07/26).
    FPedidoModoActual: string;
    procedure ConstruirModoEntrada;
    function  PedidoClaveActual: string;
    procedure CrearColumnasHostPedidoCompra;
    procedure MostrarColumnasAtributoGlobalesPedc;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    // "A recibir" como CAMPO (CANTIDAD_A_RECIBIR_PEDCLIN): clamp al
    // pendiente y recogida/limpieza por almacen para Crear albaran.
    procedure ARecibirCampoEditValueChanged(Sender: TObject);
    function  RecogerCeldasARecibirCampo(
                const ACodigoAlm: string): TArray<TCeldaARecibir>;
    procedure LimpiarARecibirCampoAlmacen(const ACodigoAlm: string);
    function  TotalARecibirCampo: Double;
    function  PrimerAlmacenARecibirCampo: string;
    function  RellenarARecibirCampoTodo: Integer;
  protected
    // F1 = ciclar el modo de entrada (KeyPreview de TfrmBase),
    // mismo atajo que pedidos/facturas de venta.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmPedidosCompra: TdmPedidosCompra;
    procedure CrearTablaPrincipal; override;
  end;

function CrearPedidosCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AArticulos: IRepositoriosArticulosPantalla): TForm;

implementation

uses
  System.StrUtils,
  inLibFiltroUsuario,
  inLibAtributosPaleta,
  inLibPedidosCompra,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataAplicacionArticuloCompra,
  UniDataComprasPantallaComposicion,
  inLibGridCantidad,
  inLibColumnasDocumento, UniDataColumnasDocumentoRepositorio,
  UniDataGen,
  inLibBusquedasCompra,
  inLibValidacionDocumento, UniDataValidacionDocumentoRepositorio,
  inLibPresentacionDocumento,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inMtoModalSelAlmacenPedido, inMtoModalDocsCreados, inMtoModalEtiqPed,
  inLibShowMto, inLibGenBusq, UniDataArticulos,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku, inLibMsgCompras,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta, UniDataGridPivoteCompraRepositorio,
  UniDataModoTallas, UniDataColumnasSkuServicios;

{$R *.dfm}

type
  TfrmMtoPedidosCompraInyectada = class(TfrmMtoPedidosCompra)
  private
    FArticulos: IRepositoriosArticulosPantalla;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const AArticulos: IRepositoriosArticulosPantalla); reintroduce;
    procedure CrearTablaPrincipal; override;
  end;

procedure ForceReferenceToClass(C: TClass); begin end;

function CrearPedidosCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AArticulos: IRepositoriosArticulosPantalla): TForm;
begin
  Result := TfrmMtoPedidosCompraInyectada.Create(
    AOwner,
    AContexto,
    AArticulos);
end;

constructor TfrmMtoPedidosCompraInyectada.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AArticulos: IRepositoriosArticulosPantalla);
begin
  FArticulos := AArticulos;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoPedidosCompraInyectada.CrearTablaPrincipal;
var
  oContexto: TContextoPedidoCompraPantalla;
  oEntrada: TEntradaDocumentoCompraPantalla;
begin
  inherited;
  oEntrada := Default(TEntradaDocumentoCompraPantalla);
  oEntrada.Conexion := dmmPedidosCompra.unqryTablaG.Connection;
  oEntrada.Cabecera := dmmPedidosCompra.unqryTablaG;
  oEntrada.Lineas := dmmPedidosCompra.unqryPedidosCompraLineas;
  ComponerComprasPantalla(FArticulos, oEntrada, oContexto);
  FAplicacionArticuloCompra := oContexto.AplicacionArticulo;
  FValidadorArticulos := oContexto.ValidadorArticulos;
  FLookupAtributos := oContexto.LookupAtributos;
  FRecepcionPedido := oContexto.Recepcion;
  FConsultasPedido := oContexto.Consultas;
  FBusquedaEmpresas := oContexto.BusquedaEmpresas;
  FBusquedaProveedores := oContexto.BusquedaProveedores;
  FBusquedasArticulos := oContexto.BusquedasArticulos;
  FArticulos := nil;
end;

// dsTablaG apunta a la cabecera del pedido de compra. El articulo
// activo vive en la fila del sub-grid tvLineasPedido
// (CODIGO_ART_PEDCLIN / CODIGO_UNIDAD_PEDCLIN).
function TfrmMtoPedidosCompra.BuscarArticuloPedidoCompra: string;
var
  sPrv: string;
begin
  Result := '';
  if Assigned(dmmPedidosCompra) then
  begin
    sPrv := Trim(dmmPedidosCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_PEDC').AsString);
    if (sPrv = '') or (sPrv = '0') then
      MessageDlg(SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra,
                 mtInformation, [mbOk], 0)
    else
      Result := BuscarArticuloProveedorCompra(
        FBusquedasArticulos, BusquedaVisual, sPrv,
        'Búsqueda de artículos', 'frmMtoDevcArtSearch', Self);
  end;
end;

function TfrmMtoPedidosCompra.ArticuloLineaActivaPedidoCompra: string;
begin
  Result := '';
  if Assigned(dmmPedidosCompra) then
    Result := ValorTextoDataSetCompra(
      dmmPedidosCompra.unqryPedidosCompraLineas,
      'CODIGO_ART_PEDCLIN');
end;

function TfrmMtoPedidosCompra.BuscarSkuPedidoCompra(
  const ACodigoArt: string): string;
var
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmPedidosCompra) then
    MessageDlg(SErrorPedidoCompraNoAbierto,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg(SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarSkuArticuloCompra(
      FBusquedasArticulos, BusquedaVisual, sArt,
      'SKUs del artículo ' + sArt,
      'frmMtoPedcSkuSearch', Self);
end;

procedure TfrmMtoPedidosCompra.AsegurarCabeceraPersistidaParaLineas;
begin
  if not Assigned(dmmPedidosCompra) then
    raise Exception.Create(SErrorPedidoCompraNoInicializado)
  else
    AsegurarCabeceraPersistidaCompra(
      dmmPedidosCompra.unqryTablaG,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      ConfiguracionTallasDocumento,
      nil);
end;

function TfrmMtoPedidosCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
  if Assigned(dmmPedidosCompra) and Assigned(FPivote) then
    Result := PuedeActivarTallasHorizontalCompra(
      dmmPedidosCompra.unqryTablaG,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      CrearValidacionDocumentoLecturas(
        dmmPedidosCompra.unqryTablaG.Connection),
      ConfiguracionTallasDocumento,
      AsegurarCabeceraPersistidaParaLineas,
      FPivote.ValidarPivotePosible, AMensaje);
end;

procedure TfrmMtoPedidosCompra.AplicarArticuloPedidoCompra(
  const ACodigoArt: string);
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
  bPivoteActivo: Boolean;
begin
  if (Trim(ACodigoArt) <> '') and Assigned(dmmPedidosCompra) and
     (FAplicacionArticuloCompra <> nil) then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    bPivoteActivo := Assigned(FPivote) and FPivote.Activo;
    oEntrada := RecogerEntradaArticuloCompra(
      ACodigoArt,
      dmmPedidosCompra.unqryTablaG,
      tdacPedido,
      bPivoteActivo);
    oResultado := FAplicacionArticuloCompra.Ejecutar(
      oEntrada,
      tdacPedido);
    PresentarArticuloPedidoCompra(oResultado);
  end;
end;

procedure TfrmMtoPedidosCompra.EnfocarSkuPedidoCompra(
  AAbrirBusqueda: Boolean);
var
  oColumnaSku: TcxGridDBColumn;
begin
  oColumnaSku := tvLineasPedido.GetColumnByFieldName(
    'CODIGO_UNIDAD_PEDCLIN');
  if oColumnaSku <> nil then
  begin
    oColumnaSku.Visible := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        tvLineasPedido.Controller.FocusedColumn := oColumnaSku;
        tvLineasPedido.Controller.EditingController.ShowEdit;
        if AAbrirBusqueda then
          colLineaPedcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
      end);
  end;
end;

procedure TfrmMtoPedidosCompra.PresentarArticuloPedidoCompra(
  const AResultado: TResultadoAplicacionArticuloCompra);
var
  oLineas: TDataSet;
begin
  if AResultado.Mensaje <> '' then
    MessageDlg(AResultado.Mensaje, mtWarning, [mbOk], 0);
  if AResultado.Aplicado then
  begin
    if Assigned(FPivote) then
    begin
      if (AResultado.AccionPivote = apacDesactivar) and FPivote.Activo then
        btnTallasHorizontalClick(nil)
      else if AResultado.AccionPivote = apacActivarYRecargar then
      begin
        if not FPivote.Activo then
          btnTallasHorizontalClick(nil);
        if FPivote.Activo then
        begin
          oLineas := dmmPedidosCompra.unqryPedidosCompraLineas;
          if oLineas.State in dsEditModes then
            oLineas.Post;
          FPivote.RecargarYRepublicar;
        end;
      end
      else if AResultado.AccionPivote = apacRecargar then
      begin
        oLineas := dmmPedidosCompra.unqryPedidosCompraLineas;
        if oLineas.State in dsEditModes then
          oLineas.Post;
        FPivote.RecargarYRepublicar;
      end;
    end;
    if AResultado.RequiereSku and
       ((FPivote = nil) or (not FPivote.Activo)) then
      EnfocarSkuPedidoCompra(True);
  end;
end;

procedure TfrmMtoPedidosCompra.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  // Mismo orden que albaranes / sesiones: columnas no-bound de tallas
  // y atributos se crean ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna unica 'Color': cuadradito del color basico + texto del
  // color del SKU (AV.AV, p.ej. "VERDE"). El cuadradito sale del HEX
  // del basico, el texto del nombre del atributo en la jerarquia del
  // SKU. Asi el usuario ve a la vez la etiqueta que el sistema usa
  // ("VERDE") y el color real que la representa.
  FColColorPivot := CrearColumnaColorPivoteDocumento(
    tvLineasPedido, 'colLinPedcColorPivot', 130);
  ConfigurarColumnaBotonDocumento(
    FColColorPivot, colLinPedcColorPivotButtonClick);
  FColColorProveedorPivot := nil;
  inherited;
  FEstiloRecepcionVencida := TcxStyle.Create(Self);
  FEstiloRecepcionVencida.AssignedValues := [svTextColor];
  FEstiloRecepcionVencida.TextColor := clRed;
  for i := 0 to cxGrdDBTabPrin.ItemCount - 1 do
    cxGrdDBTabPrin.Items[i].Styles.OnGetContentStyle :=
      GridListaGetContentStyle;
  ConfigurarColumnaBusquedaDocumento(
    tvLineasPedido, 'CODIGO_UNIDAD_PEDCLIN',
    colLineaPedcCODIGO_UNIDADPropertiesButtonClick,
    colLineaPedcCODIGO_UNIDADPropertiesValidate);
  InicializarGestorYPivote;
  // Pintado del swatch de color en la columna no-bound: delegamos en el
  // controlador de pivote.
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // Hook OnFocusedItemChanged: al moverse a una celda talla en
  // pivote expandido alimentamos el label de contexto con Pedido /
  // Recibida (que el editor inplace nativo tapa durante la edicion).
  tvLineasPedido.OnFocusedItemChanged := tvLineasPedidoFocusedItemChanged;
  // ListSource del combo Temporada (no se puede asignar en DFM porque
  // el dataset esta en el DM hijo y se instancia despues del form).
  cbbTemporadaPedc.Properties.ListSource := dmmPedidosCompra.dsTemporadasPedc;
  cbbTemporadaPedc.Properties.ListFieldNames := 'PV';
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup unqryPrvDataPedc, ya cargado para el rotulo.
  cbbCODIGO_PRV_PEDC.Properties.ListSource := dmmPedidosCompra.dsPrvDataPedc;
  // Hook OnDataChange del master: al cambiar de pedido activo, el
  // controlador recarga su cache y republica.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor del pedido enfocado al abrir el form.
  ActualizarLabelProveedor;
  // Hook AfterPost del detail: cxGrid borra los Values[] no-bound al
  // repintar tras Post; conservamos la logica del DM y recargamos el
  // controlador.
  FAfterPostLineasOriginal :=
    dmmPedidosCompra.unqryPedidosCompraLineas.AfterPost;
  dmmPedidosCompra.unqryPedidosCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  // Hook AfterOpen del detail: al abrir el cursor (al entrar al form y
  // cada vez que cambia el pedido master) hacemos ApplyBestFit para que
  // las columnas se ajusten al contenido y no salgan truncadas como
  // "Verde botel..." o "MARRO chocolat...".
  dmmPedidosCompra.unqryPedidosCompraLineas.AfterOpen :=
                                             unqryLineasAfterOpenHook;
  // Clamp de "A recibir" en modo vertical: la columna no-bound se crea
  // en el dfm sin handler; lo enganchamos aqui para ajustar al maximo
  // pendiente lo que teclee el usuario.
  if Assigned(colLineaPedcARecibir) and
     (colLineaPedcARecibir.Properties is TcxCurrencyEditProperties) then
    TcxCurrencyEditProperties(colLineaPedcARecibir.Properties).
      OnEditValueChanged := ARecibirVerticalEditValueChanged;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
  RefrescarCantidadAAlbaranar;
  // Contrato de entrada ColumnSKUcxGrid: Tallas horizontal inline
  // (celdas) por defecto; si su construccion falla, ConstruirModoEntrada
  // degrada a SKU. F1 cicla los modos. El pivote de compras antiguo
  // queda RETIRADO de esta pantalla: se ocultan sus botones y nunca se
  // activa (la preferencia ESPIVOTE de la cabecera se ignora).
  FModoEntradaSel := mcsTallasInline;
  FColsModoConstruido := False;
  btnTallasHorizontal.Visible := False;
  // "Expandir recibidos" se conserva: ahora salta directamente al
  // modo Tallas horizontal (tallashorped), cuyas bandas Pedido /
  // A recibir / Pendiente son el "expandido" del pivote antiguo.
  btnExpandirRecibidos.Visible := True;
  btnRecibirFilaEntera.Visible := False;
  lblContextoTalla.Visible := False;
  ActualizarCaptionModoLineas;
  // Primera construccion al abrir la pantalla: sin ella, hasta entrar
  // en el grid se veian las columnas del dfm (ningun modo).
  if Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryPedidosCompraLineas.Active then
    ConstruirModoEntrada;
end;

procedure TfrmMtoPedidosCompra.FormDestroy(Sender: TObject);
var
  bHuboCambios: Boolean;
begin
  FAplicacionArticuloCompra := nil;
  FValidadorArticulos := nil;
  FLookupAtributos := nil;
  FRecepcionPedido := nil;
  FConsultasPedido := nil;
  FBusquedaEmpresas := nil;
  FBusquedaProveedores := nil;
  FBusquedasArticulos := nil;
  // El modo del contrato se libera ANTES del inherited: su teardown
  // toca el view y el dataset de lineas, que deben seguir vivos (misma
  // leccion que pedidos/facturas de venta, AV al cerrar 08/07/26).
  if FModoEntrada <> nil then
  begin
    // Teardown SILENCIOSO: la expansion del modo tallas postea lineas
    // y sin bracket cada post recalculaba totales (IVA linea a linea)
    // y regeneraba pendientes; con el form muriendo solo importa dejar
    // los datos consistentes y sincronizar pendientes UNA vez.
    bHuboCambios := False;
    if Assigned(dmmPedidosCompra) then
      dmmPedidosCompra.IniciarReorganizacionLineas;
    try
      try
        FModoEntrada.Desmontar;
      except
        // Teardown defensivo en cierre.
        on E: Exception do
          if RegistroLog <> nil then
            RegistroLog.RegistrarAviso(
              'PedidosCompra.FormDestroy: Desmontar fallo: ' +
              E.Message);
      end;
    finally
      if Assigned(dmmPedidosCompra) then
        bHuboCambios := dmmPedidosCompra.AbortarReorganizacionLineas;
    end;
    if bHuboCambios then
      dmmPedidosCompra.SincronizarPdteRecibir;
    FModoEntrada := nil;
  end;
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  inherited;
end;

procedure TfrmMtoPedidosCompra.GridListaGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  colFecha: TcxGridDBColumn;
  colPdte : TcxGridDBColumn;
  vFecha  : Variant;
  vPdte   : Variant;
  dFecha  : TDateTime;
  rPdte   : Double;
begin
  if (ARecord <> nil) and (Sender is TcxGridDBTableView) then
  begin
    colFecha :=
      TcxGridDBTableView(Sender).GetColumnByFieldName(
        'FECHA_TOPE_RECEPCION_PEDC');
    colPdte :=
      TcxGridDBTableView(Sender).GetColumnByFieldName(
        'CANTIDAD_PENDIENTE_RECEPCION_PEDC');
    if (colFecha <> nil) and (colPdte <> nil) then
    begin
      vFecha := ARecord.Values[colFecha.Index];
      vPdte := ARecord.Values[colPdte.Index];
      if not (VarIsNull(vFecha) or VarIsEmpty(vFecha) or
              VarIsNull(vPdte) or VarIsEmpty(vPdte)) then
      begin
        dFecha := VarToDateTime(vFecha);
        if VarIsNumeric(vPdte) then
          rPdte := vPdte
        else
          rPdte := StrToFloatDef(VarToStr(vPdte), 0);
        if (rPdte > 0) and (Trunc(dFecha) < Date) then
          AStyle := FEstiloRecepcionVencida;
      end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.TotalAAlbaranarVertical: Double;
var
  ds     : TUniQuery;
  bk     : TBookmark;
  recIdx : Integer;
  idxCol : Integer;
  vARec  : Variant;
  rARec  : Double;
begin
  Result := 0;
  if (dmmPedidosCompra <> nil) and (colLineaPedcARecibir <> nil) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
  idxCol := colLineaPedcARecibir.Index;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    recIdx := 0;
    ds.First;
    while not ds.Eof do
    begin
      vARec := tvLineasPedido.DataController.Values[recIdx, idxCol];
      if not (VarIsNull(vARec) or VarIsEmpty(vARec)) then
      begin
        if VarIsNumeric(vARec) then
          rARec := vARec
        else
          rARec := StrToFloatDef(VarToStr(vARec), 0);
        if rARec > 0 then
          Result := Result + rARec;
      end;
      Inc(recIdx);
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.TotalAAlbaranar: Double;
begin
  Result := 0;
  if FColsModoConstruido then
    // Contrato construido: "A recibir" vive en el campo
    // CANTIDAD_A_RECIBIR_PEDCLIN (columna en SKU/Desglose, banda en
    // tallas horizontal).
    Result := TotalARecibirCampo
  else if Assigned(FPivote) and FPivote.Activo then
  begin
    if FPivote.Expandido then
      Result := FPivote.TotalARecibir;
  end
  else
    Result := TotalAAlbaranarVertical;
end;

procedure TfrmMtoPedidosCompra.RefrescarCantidadAAlbaranar;
begin
  if curCabCANTIDAD_A_ALBARANAR_PEDC <> nil then
    curCabCANTIDAD_A_ALBARANAR_PEDC.EditValue := TotalAAlbaranar;
end;

procedure TfrmMtoPedidosCompra.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdPedido, sdCompra));
  AsignarVistaLineasDocumento(tvLineasPedido);
  inherited;
  dmmPedidosCompra := TdmPedidosCompra(
    AsegurarDataModuleDocumento(
      Self, tdmDataModule, TdmPedidosCompra));
  ConfigurarTablaPrincipalDocumento(
    dmmPedidosCompra, dsTablaG, tvLineasPedido,
    dmmPedidosCompra.dsPedidosCompraLineas,
    [dmmPedidosCompra.unqryPedidosCompraLineas,
     dmmPedidosCompra.unqryAlbaranesPedc],
    pkFieldName, 'SERIE_PEDC;NUMERO_PEDC');
  tvAlbaranesPedc.DataController.DataSource :=
    dmmPedidosCompra.dsAlbaranesPedc;
  cbbTotalesFORMA_PAGO_PEDC.Properties.ListSource :=
    dmmPedidosCompra.dsFormasPago;
  cbbCODIGO_ALM_PEDC.Properties.ListSource :=
    dmmPedidosCompra.dsAlmacenesPedc;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PEDC);
end;

procedure TfrmMtoPedidosCompra.CrearColumnasTallas;
begin
  CrearColumnasTallasDocumento(tvLineasPedido, 'dbcLinPedcTalla',
    ANCHO_TALLA_PX, FTallaColumns);
end;

procedure TfrmMtoPedidosCompra.CrearColumnasAtributos;
begin
  CrearColumnasAtributosDocumento(tvLineasPedido,
    'dbcLinPedcAtrib', FAtribColumns, AtribGetDataText);
end;

procedure TfrmMtoPedidosCompra.AtribGetDataText(
  Sender: TcxCustomGridTableItem; ARecordIndex: Integer;
  var AText: string);
var
  colSku: TcxGridDBColumn;
  Partes: TArray<string>;
  iOrden: Integer;
begin
  AText := '';
  // Tag negativo -(1..5): posicion del atributo en el SKU
  // ART/VAL1/VAL2... (Partes[0] es el articulo).
  iOrden := -Sender.Tag;
  colSku := tvLineasPedido.GetColumnByFieldName('CODIGO_UNIDAD_PEDCLIN');
  if (colSku <> nil) and (iOrden >= 1) and (ARecordIndex >= 0) then
  begin
    Partes := VarToStr(tvLineasPedido.DataController.GetValue(
                ARecordIndex, colSku.Index)).Split(['/']);
    if iOrden <= High(Partes) then
      AText := Partes[iOrden];
  end;
end;

procedure TfrmMtoPedidosCompra.CargarBasicosColorArticulo(
  const ACodigoArt: string);
begin
  FBasicosColor := ObtenerBasicosArticulo(
    ConexionPrincipal, ACodigoArt, ID_VA_COLOR);
end;

procedure TfrmMtoPedidosCompra.InicializarGestorYPivote;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfigTallas: TGridTallasConfig;
  oConfigPivote: TGridPivoteCompraConfig;
begin
  if Assigned(FGestorTallas) then
    FreeAndNil(FGestorTallas);
  if Assigned(FPivote) then
    FreeAndNil(FPivote);
  if Assigned(dmmPedidosCompra) then
  begin
    oBase := Default(TConfigPivoteDocumentoCompra);
    oBase.Conexion := dmmPedidosCompra.unqryTablaG.Connection;
    oBase.ContextoSesion := ContextoSesion;
    oBase.Usuario := IdentidadSesion.Usuario;
    oBase.Vista := tvLineasPedido;
    oBase.SourceMaster := dsTablaG;
    oBase.SourceLineas := dmmPedidosCompra.dsPedidosCompraLineas;
    oBase.ConsultaLineas :=
      dmmPedidosCompra.unqryPedidosCompraLineas;
    oBase.ColumnasTallas := CopiarColumnasDocumento(FTallaColumns);
    oBase.ColColorPivot := FColColorPivot;
    oBase.ColColorProveedorPivot := FColColorProveedorPivot;
    oBase.PrefijoCabecera := 'PEDC';
    oBase.PrefijoLinea := 'PEDCLIN';
    oBase.PrefijoCelda := 'PEDCCEL';
    oBase.NombreTablaDocumento := 'pedidos';
    oBase.AplicarContextoPivote := True;
    oBase.RegistroLog := RegistroLog;
    oBase.TieneCantidadRecibida := True;
    if ColumnaPedidosCompraExiste('COLOR_TEXTO_PEDCLIN') then
      oBase.CampoColorTexto := 'COLOR_TEXTO_PEDCLIN';
    oConfigTallas := CrearConfigTallasDocumentoCompra(oBase);
    oConfigTallas.Persistencia := CrearPersistenciaGridTallasInline(
      oBase.Conexion,
      CrearConfigPersistenciaTallasInline(oConfigTallas));
    FGestorTallas := TGestorGridTallas.Create(oConfigTallas);
    ConfigurarEventosTallasDocumento(FTallaColumns,
      TallaEditValueChangedHook, TallaValidateHook);
    oConfigPivote := CrearConfigPivoteDocumentoCompra(oBase,
      FGestorTallas);
    FPivote := TGridPivoteCompra.Create(
      oConfigPivote,
      CrearRepositorioGridPivoteCompraUniDAC(ConexionPrincipal));
  end;
end;

procedure TfrmMtoPedidosCompra.RefrescarVisibilidadTallas;
begin
  if (FPivote = nil) or (not FPivote.Activo) or (FGestorTallas = nil) then
    EstablecerVisibilidadColumnasDocumento(FTallaColumns, False)
  else
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoPedidosCompra.RefrescarVisibilidadAtributos;
var
  i, iIdx: Integer;
begin
  // Desglose vs SKU, como en ventas: en Desglose los atributos van
  // PEGADOS al articulo y la columna SKU se oculta (color/talla ya se
  // ven desglosados); en SKU, al reves. En pivote no se toca nada.
  if (FPivote = nil) or (not FPivote.Activo) then
  begin
    if Assigned(colLineaPedcCODIGO_UNIDAD) then
      colLineaPedcCODIGO_UNIDAD.Visible := not FMostrarAtributos;
    if FMostrarAtributos and Assigned(colLineaPedcCODIGO_UNIDAD) then
    begin
      // Recolocar los atributos justo detras del hueco del SKU (las
      // columnas nacieron al final del view en CrearColumnasAtributos).
      iIdx := colLineaPedcCODIGO_UNIDAD.Index + 1;
      for i := 0 to CANT_ATRIB_MAX - 1 do
        if FAtribColumns[i] <> nil then
        begin
          FAtribColumns[i].Index := iIdx;
          Inc(iIdx);
        end;
    end;
  end;
  EstablecerVisibilidadColumnasDocumento(FAtribColumns,
    FMostrarAtributos);
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributo del articulo de la linea con foco y los
// aplica como captions de las columnas ATTRn. La carga de VALORES por
// SKU queda como TODO (hito posterior).
procedure TfrmMtoPedidosCompra.CargarCaptionsAtributosLineaActiva;
begin
  if Assigned(dmmPedidosCompra) then
    CargarCaptionsAtributosDocumento(
      dmmPedidosCompra.unqryDefArticuloPedc,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      'CODIGO_ART_PEDCLIN', FAtribColumns);
end;

procedure TfrmMtoPedidosCompra.PersistirPreferenciaPivote;
begin
  PersistirPreferenciaPivoteDocumento(
    dsTablaG.DataSet, 'ESPIVOTE_HORIZONTAL_PEDC', FPivote.Activo);
end;

procedure TfrmMtoPedidosCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmPedidosCompra <> nil) and (FPivote <> nil) and
     not FInToggleClick then
  begin
  // Guardia de reentrada: bloquea el auto-toggle del data-change hook
  // mientras PersistirPreferenciaPivote esta editando+posting la cabecera.
  // Sin esto, el Edit dispara OnDataChange con la cabecera todavia con
  // el valor viejo, el hook ve discrepancia con Activo y vuelve a llamar
  // a este handler.
  FInToggleClick := True;
  try
    if not FPivote.Activo then
    begin
      if PuedeActivarTallasHorizontal(sMensaje) then
      begin
        FPivote.Activar;
        if Assigned(colLineaPedcARecibir) then
          colLineaPedcARecibir.Visible := False;
        ActualizarCaptionModoLineas;
        BestFitConSwatch;
        if Sender <> nil then
          PersistirPreferenciaPivote;
      end
      else if Sender <> nil then
        MessageDlg(sMensaje, mtWarning, [mbOk], 0);
    end
    else
    begin
      FPivote.Desactivar;
      if Assigned(colLineaPedcARecibir) then
        colLineaPedcARecibir.Visible := True;
      ActualizarCaptionModoLineas;
      BestFitConSwatch;
      if Sender <> nil then
        PersistirPreferenciaPivote;
    end;
  finally
    FInToggleClick := False;
  end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoPedidosCompra.ActualizarCaptionModoLineas;
begin
  tsLineasPedido.Caption := CaptionModoLineasDocumento(
    'Líneas', 'Líneas', FColsModoConstruido,
    FModoEntradaSel, True);
end;

procedure TfrmMtoPedidosCompra.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcPedido.ActivePage = tsLineasPedido) and
    (dmmPedidosCompra <> nil), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasInline, mcsTallasHorPed],
    ConstruirModoEntrada);
  inherited;
end;

// "Expandir recibidos": salta directamente al modo Tallas horizontal
// del contrato (tallashorped). Sus bandas Pedido / A recibir /
// Pendiente equivalen al pivote expandido antiguo.
procedure TfrmMtoPedidosCompra.btnExpandirRecibidosClick(Sender: TObject);
begin
  inherited;
  if dmmPedidosCompra <> nil then
    CambiarModoEntradaDocumento(
      FModoEntradaSel, mcsTallasHorPed, ConstruirModoEntrada);
end;

// Rellena el sub-segmento 'A recibir' con el pendiente (Pedido -
// Recibida) de TODAS las tallas de la fila focused. Solo aplica en
// pivote expandido — si no, avisa al usuario.
procedure TfrmMtoPedidosCompra.btnRecibirFilaEnteraClick(Sender: TObject);
var
  iCeldas: Integer;
begin
  inherited;
  if (FPivote = nil) or (not FPivote.Activo) or (not FPivote.Expandido) then
    MessageDlg(SErrorExpandirRecibidosNoActivo,
               mtInformation, [mbOk], 0)
  else
  begin
    iCeldas := FPivote.RecibirFilaEntera;
    RefrescarCantidadAAlbaranar;
    if iCeldas = 0 then
      MessageDlg(SInfoTallasPendientesRecibirNoDisponibles,
                 mtInformation, [mbOk], 0);
  end;
end;

// Rellena de una sola pasada TODO el pedido con las cantidades
// pendientes de recibir (Pedida - Recibida). En modo vertical vuelca la
// columna "A recibir" de cada linea; en pivote rellena las celdas talla
// (si el pivote esta plano lo expandimos antes para que el usuario vea
// el resultado). Tras esto basta con pulsar "Crear albaran".
procedure TfrmMtoPedidosCompra.btnRecibirTodoClick(Sender: TObject);
var
  iRellenadas: Integer;
begin
  inherited;
  if dmmPedidosCompra <> nil then
  begin
  if FColsModoConstruido then
    // Contrato construido: volcar el pendiente de cada linea al campo
    // "A recibir" (los Post rearman la recarga del pivote de tallas).
    iRellenadas := RellenarARecibirCampoTodo
  else if Assigned(FPivote) and FPivote.Activo then
  begin
    // En pivote la entrada de "A recibir" vive en las celdas talla, que
    // solo se pintan y editan en modo expandido. Si esta plano, expandimos.
    if not FPivote.Expandido then
      FPivote.Expandir;
    iRellenadas := FPivote.RecibirTodo;
    BestFitConSwatch;
  end
  else
    // Modo vertical: una fila por SKU, columna "A recibir" editable.
    iRellenadas := RellenarARecibirVerticalTodo;
  RefrescarCantidadAAlbaranar;
  if iRellenadas = 0 then
    MessageDlg(SInfoPedidoCompraSinPendientesRecibir,
               mtInformation, [mbOk], 0);
  end;
end;

procedure TfrmMtoPedidosCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidosCompra.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  if RegistroLog <> nil then
    RegistroLog.RegistrarInformacion('PedidosCompra.btnGrabarClick: INICIO');
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    FValidadorArticulos,
    dmmPedidosCompra.unqryPedidosCompraLineas, 'PEDCLIN');
  if (sLineasSinSku = '') or
     (MessageDlg(Format(SPreguntaGrabarPedidoCompraSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    if Assigned(FPivote) and FPivote.Activo and
       not FPivote.Expandido then
      FPivote.PersistirCantidadesPendientes;
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmPedidosCompra.CalcularTotalesPedidoCompra;
      dsTablaG.DataSet.Post;
    end;
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
    RefrescarCantidadAAlbaranar;
  end;
end;

procedure TfrmMtoPedidosCompra.btnIraalbaranClick(Sender: TObject);
begin
  inherited;
  actIrDocumentoExecute(Sender);
end;

// Hook del OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field=nil). Reaplica el modo pivote si la cabecera lo trae como
// preferencia y republica cantidades. Toda la fontaneria vive en la
// libreria; aqui solo orquestamos el toggle desde la cabecera.
procedure TfrmMtoPedidosCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                     Field: TField);
begin
  // Refrescar el rotulo del proveedor al navegar entre pedidos (Field=nil)
  // o al cambiar CODIGO_PRV_PEDC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_PEDC') then
    ActualizarLabelProveedor;
  if (Field = nil) and Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryTablaG.Active and
     (not dmmPedidosCompra.unqryTablaG.IsEmpty) then
    dmmPedidosCompra.RefrescarAlmacenes(
      dmmPedidosCompra.unqryTablaG.FieldByName(
        'CODIGO_EMP_PEDC').AsString);
  if Field = nil then
  begin
  // Contrato de entrada: al navegar de pedido, las lineas llegan
  // recargadas por el master-detail. En desglose basta desempaquetar
  // SKU->ATTR; el modo tallas re-pivota su cache reconstruyendo
  // (mismo criterio que facturas). La preferencia ESPIVOTE del pivote
  // de compras antiguo se IGNORA (pivote retirado de esta pantalla).
  if (not FConstruyendoModo) and
     Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryPedidosCompraLineas.Active and
     (not (dsTablaG.State in dsEditModes)) then
  begin
    // Sin modo construido (llegar navegando sin pisar el grid) se
    // veian las columnas del dfm: construir tambien en ese caso.
    // Tallas INLINE no convierte al navegar: mirar un pedido no debe
    // escribirlo (con cientos de pedidos seria una tormenta). La
    // fusion se hace al ENTRAR AL GRID de lineas (cxgrdLineasPedido
    // Enter) o con F1; hasta entonces el pedido sin fusionar se ve
    // linea a linea por SKU.
    // Tallas HORIZONTAL bandas: SOLO si el pedido cambio de verdad.
    // El Post de la misma cabecera tambien pasa por aqui con Field=nil
    // y reconstruir en ese caso encadenaba rebuild -> recalculo ->
    // Post -> rebuild (tormenta de SQL por cada click).
    if (not FColsModoConstruido) or
       ((FModoEntradaSel = mcsTallasHorPed) and
        (PedidoClaveActual <> FPedidoModoActual)) then
      ConstruirModoEntrada
    else if FModoEntradaSel = mcsAuto then
      dmmPedidosCompra.DesempaquetarAtributosLineas;
  end;
  RefrescarCantidadAAlbaranar;
  end;
end;

// Clave serie|numero de la cabecera activa: identifica el pedido para
// el que esta construido el modo de entrada.
function TfrmMtoPedidosCompra.PedidoClaveActual: string;
begin
  Result := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active then
    Result :=
      Trim(dsTablaG.DataSet.FieldByName('SERIE_PEDC').AsString) + '|' +
      Trim(dsTablaG.DataSet.FieldByName('NUMERO_PEDC').AsString);
end;

procedure TfrmMtoPedidosCompra.ActualizarLabelProveedor;
begin
  if Assigned(dmmPedidosCompra) then
    lblProveedorNombrePedc.Caption := TextoProveedorDocumento(
      dmmPedidosCompra.unqryTablaG,
      dmmPedidosCompra.unqryPrvDataPedc,
      'CODIGO_PRV_PEDC')
  else
    lblProveedorNombrePedc.Caption := '';
end;

// Hook AfterPost del detail: encadena la logica original del DM con la
// republicacion de Values[] no-bound del controlador.
procedure TfrmMtoPedidosCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FAfterPostLineasOriginal) then
    FAfterPostLineasOriginal(DataSet)
  else if Assigned(dmmPedidosCompra) then
    dmmPedidosCompra.CalcularTotalesPedidoCompra;
  // En reorganizacion del modo de entrada la lib republica al final:
  // refrescar por cada linea repite consultas sin efecto visual.
  if (dmmPedidosCompra = nil) or
     (not dmmPedidosCompra.EnReorganizacionLineas) then
  begin
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
    RefrescarCantidadAAlbaranar;
  end;
end;

// Hook AfterOpen del detail: cada vez que se abre el cursor (entrar al
// form o navegar a otro pedido) ajustamos el ancho de columnas al
// contenido. Asi no salen textos truncados como "Verde botel" o
// "rón choc" en la columna Color.
procedure TfrmMtoPedidosCompra.unqryLineasAfterOpenHook(DataSet: TDataSet);
begin
  if tvLineasPedido <> nil then
    BestFitConSwatch;
  RefrescarCantidadAAlbaranar;
end;

// ApplyBestFit estandar + ensanche manual de la columna Color: el
// custom-draw de FColColorPivot pinta un cuadradito de color de
// ANCHO_SWATCH_PX (~20 px) ANTES del texto, y ApplyBestFit solo mide
// el ancho del texto. Sin este ajuste la columna Color queda recortada
// (se ve "ERD" en vez de "VERDE", etc) cuando hay swatch.
procedure TfrmMtoPedidosCompra.BestFitConSwatch;
var
  i: Integer;
begin
  if (tvLineasPedido <> nil) and not FColsModoConstruido then
  begin
    tvLineasPedido.ApplyBestFit;
    if Assigned(FColColorPivot) and FColColorPivot.Visible then
      FColColorPivot.Width := FColColorPivot.Width + ANCHO_SWATCH_PX;
    for i := 0 to CANT_TALLAS_MAX - 1 do
      if Assigned(FTallaColumns[i]) and FTallaColumns[i].Visible and
         (FTallaColumns[i].Width < ANCHO_TALLA_PX) then
        FTallaColumns[i].Width := ANCHO_TALLA_PX;
  end;
end;

// Comprueba via INFORMATION_SCHEMA si una columna existe en
// fza_pedidos_compra_lineas. Lo usamos para activar features
// (FieldColorTexto, etc.) solo si el ALTER correspondiente de
// pedidos_compra.sql se ha aplicado.
function TfrmMtoPedidosCompra.ColumnaPedidosCompraExiste(
                                       const ANombreColumna: string): Boolean;
begin
  Result := FConsultasPedido.ColumnaLineasExiste(ANombreColumna);
end;

procedure TfrmMtoPedidosCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasPedido.DataController.DataSet,
    'CODIGO_ART_PEDCLIN');
end;

procedure TfrmMtoPedidosCompra.actIrProveedorExecute(Sender: TObject);
begin
  if Assigned(dmmPedidosCompra) then
    ShowMtoCodigoDataSet(Self.Owner, 'Proveedores',
      dmmPedidosCompra.unqryTablaG, 'CODIGO_PRV_PEDC')
  else
    ShowMto(Self.Owner, 'Proveedores');
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  oConsulta: IConsultaComprasPantalla;
  ds: TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    ds := dmmPedidosCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorPedidoCompraNecesarioElegirEmpresa,
                 mtInformation, [mbOk], 0)
    else
    begin
      oConsulta := FBusquedaEmpresas.ConsultarEmpresas;
      if BusquedaVisual.EjecutarBusquedaDataSet(
        'Búsqueda de empresas',
        oConsulta.DataSet,
        'frmMtoEmpFacSearch',
        Self) then
      begin
        if not (ds.State in [dsInsert, dsEdit]) then
          ds.Edit;
        ds.FieldByName('CODIGO_EMP_PEDC').AsString :=
          oConsulta.DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoPedidosCompra.cbbCODIGO_PRV_PEDCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  oConsulta: IConsultaComprasPantalla;
  ds: TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    ds := dmmPedidosCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorPedidoCompraNecesarioElegirProveedor,
                 mtInformation, [mbOk], 0)
    else
    begin
      oConsulta := FBusquedaProveedores.ConsultarProveedores;
      if BusquedaVisual.EjecutarBusquedaDataSet(
        'Búsqueda de proveedores',
        oConsulta.DataSet,
        'frmMtoPedcProvSearch',
        Self) then
      begin
        if not (ds.State in [dsInsert, dsEdit]) then
          ds.Edit;
        ds.FieldByName('CODIGO_PRV_PEDC').AsString :=
          oConsulta.DataSet.FieldByName('CODIGO_PRV_PRV').AsString;
        AplicarIvaExentoIntracomunitarioProveedor(
          CrearLecturasImpuestos(ConexionPrincipal),
          ds,
          'CODIGO_PRV_PEDC',
          'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC');
        dmmPedidosCompra.CalcularTotalesPedidoCompra;
        ActualizarLabelProveedor;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sEmpresa: string;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
       (dsTablaG.DataSet.State in dsEditModes) and
       (Sender is TcxCustomEdit) then
    begin
      e := Sender as TcxCustomEdit;
      sEmpresa := Trim(VarToStr(e.EditingValue));
      if sEmpresa <> '' then
        dmmPedidosCompra.BuscarEmpresa(sEmpresa);
    end;
    dmmPedidosCompra.RefrescarAlmacenes('');
  end;
end;

procedure TfrmMtoPedidosCompra.cbbCODIGO_ALM_PEDCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sAlmacen: string;
  sEmpresa: string;
  ds: TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sAlmacen := Trim(VarToStr(e.EditingValue));
    if (sAlmacen <> '') and
       dmmPedidosCompra.unqryAlmacenesPedc.Active and
       dmmPedidosCompra.unqryAlmacenesPedc.Locate(
         'CODIGO_ALM_ALM', sAlmacen, []) then
    begin
      sEmpresa := Trim(dmmPedidosCompra.unqryAlmacenesPedc.
                         FieldByName('CODIGO_EMP_ALM').AsString);
      ds := dsTablaG.DataSet;
      if (sEmpresa <> '') and
         (Trim(ds.FieldByName('CODIGO_EMP_PEDC').AsString) <> sEmpresa) then
        dmmPedidosCompra.BuscarEmpresa(sEmpresa);
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_PEDCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPedidosCompra.cbbCODIGO_PRV_PEDCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_PEDCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloPedidoCompra;
  if sCodigo <> '' then
    AplicarArticuloPedidoCompra(sCodigo);
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_ARTPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloPedidoCompra(sCodigo);
      if Assigned(dmmPedidosCompra) and
         dmmPedidosCompra.unqryPedidosCompraLineas.Active and
         (dmmPedidosCompra.unqryPedidosCompraLineas.
            FindField('CODIGO_ART_PEDCLIN') <> nil) then
        DisplayValue := dmmPedidosCompra.unqryPedidosCompraLineas.
                          FieldByName('CODIGO_ART_PEDCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaPedidoCompra;
  sSku := BuscarSkuPedidoCompra(sArt);
  if sSku <> '' then
    AplicarArticuloPedidoCompra(sSku);
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_UNIDADPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloPedidoCompra(sCodigo);
      if Assigned(dmmPedidosCompra) and
         dmmPedidosCompra.unqryPedidosCompraLineas.Active and
         (dmmPedidosCompra.unqryPedidosCompraLineas.
            FindField('CODIGO_UNIDAD_PEDCLIN') <> nil) then
        DisplayValue := dmmPedidosCompra.unqryPedidosCompraLineas.
                          FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.AsegurarPrimeraLineaPedidoCompra;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmPedidosCompra) then
  begin
    dsCab := dmmPedidosCompra.unqryTablaG;
    dsLin := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_PEDC').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_PEDC').AsString);
      if (sNumero <> '') and (sNumero <> '0') and (sSerie <> '') then
      begin
        if not dsLin.Active then
          dsLin.Open;
        if dsLin.IsEmpty and not (dsLin.State in dsEditModes) then
          dsLin.Append;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.colLinPedcColorPivotButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt    : string;
  sActual : string;
  sNuevo  : string;
  sMensaje: string;
  Edit    : TWinControl;
  ScrPt   : TPoint;
  WidHint : Integer;
begin
  if (FPivote = nil) or (not FPivote.Activo) then
  begin
    MessageDlg(SErrorTallasHorizontalesNecesariasElegirColor,
               mtInformation, [mbOk], 0);
  end
  else
  begin
    sArt := ArticuloLineaActivaPedidoCompra;
    if sArt = '' then
      MessageDlg(SErrorArticuloNoSeleccionadoElegirColorPedidoCompra,
                 mtInformation, [mbOk], 0)
    else
    begin
      CargarBasicosColorArticulo(sArt);
      if Length(FBasicosColor) = 0 then
        MessageDlg(Format(SErrorArticuloPedidoCompraSinColoresBasicos,
                          [sArt]),
                   mtInformation, [mbOk], 0)
      else
      begin
        sActual := FPivote.ColorCodigoLineaActiva;
        ScrPt.X := -1;
        ScrPt.Y := -1;
        WidHint := FColColorPivot.Width;
        if Sender is TWinControl then
        begin
          Edit := TWinControl(Sender);
          ScrPt := Edit.ClientToScreen(Point(0, Edit.Height));
          WidHint := Edit.Width;
        end;
        if SeleccionarAvConPaleta(
          ConexionPrincipal,
          ID_VA_COLOR,
          FBasicosColor,
          sActual,
                                  sNuevo, ScrPt.X, ScrPt.Y, WidHint) then
        begin
          if FPivote.CambiarColorLineaActiva(sNuevo, sMensaje) then
          begin
            FPivote.RecargarYRepublicar;
            BestFitConSwatch;
          end
          else if sMensaje <> '' then
            MessageDlg(sMensaje, mtWarning, [mbOk], 0);
        end
      end;
    end;
  end;
end;

// "Ir a documento" (Ctrl+May+A) desde la pestania Albaranes del pedido:
// abre la ficha del albaran de compra seleccionado en la rejilla. Solo
// actua si esa pestania esta activa y hay un albaran en la fila actual.
procedure TfrmMtoPedidosCompra.actIrDocumentoExecute(Sender: TObject);
begin
  inherited;
  if (pcPedido.ActivePage = tsAlbaranesPedc) and
     (dmmPedidosCompra <> nil) and
     dmmPedidosCompra.unqryAlbaranesPedc.Active and
     (not dmmPedidosCompra.unqryAlbaranesPedc.IsEmpty) then
    ShowMtoDocumentoDataSet(Self.Owner, 'AlbaranesCompra',
      dmmPedidosCompra.unqryAlbaranesPedc,
      'SERIE_ALBC', 'NUMERO_ALBC');
end;

function TfrmMtoPedidosCompra.AlmacenEfectivoPrimeraLinea(
                                  const ASerie, ANumero: string): string;
begin
  Result := FConsultasPedido.AlmacenEfectivoPrimeraLinea(
    ASerie,
    ANumero);
end;

procedure TfrmMtoPedidosCompra.tvLineasPedidoFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarFocoLineaDocumento(
    FGestorTallas, FPivote, FMostrarAtributos,
    CargarCaptionsAtributosLineaActiva);
  // Al saltar de fila la celda activa cambia aunque la columna no —
  // refrescamos el label de contexto. Sender.Controller expone
  // FocusedItem (TcxCustomGridTableItem); FocusedColumn solo esta en
  // el controller DB-tipado.
  tvLineasPedidoFocusedItemChanged(Sender, nil,
                                   Sender.Controller.FocusedItem);
end;

// Sombrear celdas talla fuera del conjunto pivot — delegamos en la lib.
procedure TfrmMtoPedidosCompra.tvLineasPedidoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoPedidosCompra.tvLineasPedidoEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.EditingCeldaTalla(Sender, AItem, AAllow);
end;

// SelectAll estilo Excel via libreria. En pivote expandido el editor
// no llega a abrirse (lo bloquea tvLineasPedidoEditing), asi que esto
// solo aplica al modo vertical / celdas no-talla.
procedure TfrmMtoPedidosCompra.tvLineasPedidoInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.InitEditCeldaTalla(Sender, AItem, AEdit);
end;

procedure TfrmMtoPedidosCompra.cxgrdLineasPedidoEnter(Sender: TObject);
begin
  inherited;
  EntrarGridLineasDocumento(
    Self, FColsModoConstruido,
    FColsModoConstruido and
    (FModoEntradaSel = mcsTallasInline) and
    Assigned(dmmPedidosCompra) and
    dmmPedidosCompra.HayLineasSinPivotar,
    FModoEntrada, AsegurarPrimeraLineaPedidoCompra,
    ConstruirModoEntrada);
end;

procedure TfrmMtoPedidosCompra.cxgrdLineasPedidoExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

// Alimenta el label de contexto con Pedido/Recibida de la celda
// talla focused. cxGrid edita la celda con su editor nativo (cursor
// real, navegacion, etc) tapando el pintado durante la edicion; el
// label de arriba muestra la misma informacion fuera de la celda
// para que el usuario no la pierda mientras teclea.
procedure TfrmMtoPedidosCompra.tvLineasPedidoFocusedItemChanged(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
var
  sTalla   : string;
  rPed     : Double;
  rRec     : Double;
begin
  if Assigned(FPivote) and
     FPivote.GetInfoCeldaTallaActiva(sTalla, rPed, rRec) then
  begin
    lblContextoTalla.Caption := Format(
      'Talla %s    Pedido: %.0f    Recibido: %.0f',
      [sTalla, rPed, rRec]);
    lblContextoTalla.Visible := True;
  end
  else
  begin
    lblContextoTalla.Caption := '';
    lblContextoTalla.Visible := False;
  end;
end;

procedure TfrmMtoPedidosCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  dmmPedidosCompra.unqryPedidosCompraLineas.Append;
end;

procedure TfrmMtoPedidosCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg(SPreguntaEliminarLineaPedidoCompra,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmPedidosCompra.unqryPedidosCompraLineas.Delete;
end;

// Recoge las cantidades "A recibir" tecleadas en modo vertical (no
// pivote). Lee la columna no-bound colLineaPedcARecibir para cada
// linea del dataset, y devuelve las que tengan cantidad > 0.
procedure TfrmMtoPedidosCompra.TallaEditValueChangedHook(Sender: TObject);
begin
  if Assigned(FPivote) and FPivote.Activo then
  begin
    if FPivote.Expandido then
      FPivote.CapturarARecibirEditValueChanged(Sender)
    else
      FPivote.CapturarCantidadEditValueChanged(Sender);
  end
  else if Assigned(FGestorTallas) then
    FGestorTallas.PersistirCeldaActiva(Sender);
  RefrescarCantidadAAlbaranar;
end;

procedure TfrmMtoPedidosCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

function TfrmMtoPedidosCompra.PrimerAlmacenARecibirVertical: string;
var
  ds: TUniQuery;
  bk: TBookmark;
  recIdx, idxCol: Integer;
  vARec: Variant;
  rARec: Double;
  sAlmLin, sAlmCab: string;
begin
  Result := '';
  if (dmmPedidosCompra <> nil) and (colLineaPedcARecibir <> nil) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
  sAlmCab :=
    dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
  idxCol := colLineaPedcARecibir.Index;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    recIdx := 0;
    ds.First;
    while (Result = '') and not ds.Eof do
    begin
      vARec := tvLineasPedido.DataController.Values[recIdx, idxCol];
      rARec := 0;
      if not (VarIsNull(vARec) or VarIsEmpty(vARec)) then
      begin
        if VarIsNumeric(vARec) then
          rARec := vARec
        else
          rARec := StrToFloatDef(VarToStr(vARec), 0);
      end;
      if rARec > 0 then
      begin
        sAlmLin := ds.FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString;
        if Trim(sAlmLin) <> '' then
          Result := sAlmLin
        else
          Result := sAlmCab;
      end;
      Inc(recIdx);
      ds.Next;
    end;
  finally
    if Assigned(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.RecogerCeldasARecibirVertical(
                                  const ACodigoAlm: string):
                                  TArray<TCeldaARecibir>;
var
  ds: TUniQuery;
  res: TList<TCeldaARecibir>;
  bk: TBookmark;
  recIdx, idxCol: Integer;
  vARec: Variant;
  rARec: Double;
  c: TCeldaARecibir;
  sAlmLin, sAlmCab, sAlmEfe: string;
begin
  Result := nil;
  if (dmmPedidosCompra <> nil) and (colLineaPedcARecibir <> nil) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
  sAlmCab :=
    dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
  idxCol := colLineaPedcARecibir.Index;
  res := TList<TCeldaARecibir>.Create;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    recIdx := 0;
    ds.First;
    while not ds.Eof do
    begin
      vARec := tvLineasPedido.DataController.Values[recIdx, idxCol];
      rARec := 0;
      if not (VarIsNull(vARec) or VarIsEmpty(vARec)) then
      begin
        if VarIsNumeric(vARec) then
          rARec := vARec
        else
          rARec := StrToFloatDef(VarToStr(vARec), 0);
      end;
      if rARec > 0 then
      begin
        sAlmLin := ds.FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString;
        if Trim(sAlmLin) <> '' then
          sAlmEfe := sAlmLin
        else
          sAlmEfe := sAlmCab;
        if SameText(sAlmEfe, ACodigoAlm) then
        begin
          c.LineaPedido   := ds.FieldByName('LINEA_PEDCLIN').AsString;
          c.CodigoSku     := ds.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
          c.CodigoAlmacen := sAlmEfe;
          c.Cantidad      := rARec;
          res.Add(c);
        end;
      end;
      Inc(recIdx);
      ds.Next;
    end;
    Result := res.ToArray;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
    FreeAndNil(res);
  end;
    end;
  end;
end;

// Recorre todas las lineas del pedido en modo vertical y vuelca en la
// columna no-bound "A recibir" el pendiente de cada una (Pedida -
// Recibida). Las lineas ya recibidas del todo quedan a Null. Devuelve
// el numero de lineas con pendiente. Misma tecnica de iteracion que
// RecogerCeldasARecibirVertical: dataset + recIdx paralelo del grid.
function TfrmMtoPedidosCompra.RellenarARecibirVerticalTodo: Integer;
var
  ds     : TUniQuery;
  bk     : TBookmark;
  recIdx : Integer;
  idxCol : Integer;
  rPdte  : Double;
begin
  Result := 0;
  if (dmmPedidosCompra <> nil) and (colLineaPedcARecibir <> nil) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
    begin
  idxCol := colLineaPedcARecibir.Index;
  bk := ds.GetBookmark;
  ds.DisableControls;
  tvLineasPedido.DataController.BeginUpdate;
  try
    recIdx := 0;
    ds.First;
    while not ds.Eof do
    begin
      rPdte := ds.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
               ds.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
      if rPdte > 0 then
      begin
        tvLineasPedido.DataController.Values[recIdx, idxCol] := rPdte;
        Inc(Result);
      end
      else
        tvLineasPedido.DataController.Values[recIdx, idxCol] := Null;
      Inc(recIdx);
      ds.Next;
    end;
  finally
    tvLineasPedido.DataController.EndUpdate;
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

// Clamp del "A recibir" tecleado en modo vertical: si supera el
// pendiente de la linea (CANTIDAD - CANTIDAD_RECIBIDA) se ajusta
// automaticamente al maximo y se avisa con un beep. La reasignacion
// de EditValue re-dispara el handler una vez, ya con valor valido.
procedure TfrmMtoPedidosCompra.ARecibirVerticalEditValueChanged(
  Sender: TObject);
var
  ed     : TcxCustomEdit;
  ds     : TUniQuery;
  vEdit  : Variant;
  rValor : Double;
  rPdte  : Double;
begin
  // La columna solo se ve en modo vertical; en pivote el clamp lo hace
  // la libreria sobre las celdas talla.
  if (Sender is TcxCustomEdit) and (dmmPedidosCompra <> nil) and
     (not (Assigned(FPivote) and FPivote.Activo)) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    begin
      ed    := TcxCustomEdit(Sender);
      vEdit := ed.EditValue;
      rValor := 0;
      if not (VarIsNull(vEdit) or VarIsEmpty(vEdit)) then
      begin
        if VarIsNumeric(vEdit) then
          rValor := vEdit
        else
          rValor := StrToFloatDef(VarToStr(vEdit), 0);
      end;
      rPdte := ds.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
               ds.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
      if rPdte < 0 then
        rPdte := 0;
      if rValor > rPdte then
      begin
        MessageBeep(MB_ICONWARNING);
        if rPdte > 0 then
          ed.EditValue := rPdte
        else
          ed.EditValue := Null;
      end;
    end;
  end;
  RefrescarCantidadAAlbaranar;
end;

// Combo de serie de la cabecera: al desplegar se recargan las series
// 'PC' vigentes de la empresa del pedido. Si la empresa no tiene
// ninguna, se avisa y se ofrece ir a Empresas -> Series a crearlas.
procedure TfrmMtoPedidosCompra.cbbSERIE_PEDCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmPedidosCompra <> nil) and dmmPedidosCompra.unqryTablaG.Active then
    sEmpresa := Trim(dmmPedidosCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_PEDC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_PEDC.Properties.Items);
  if cbbSERIE_PEDC.Properties.Items.Count = 0 then
  begin
    if MessageDlg(Format(SPreguntaAbrirSeriesPedidoCompra, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ShowMto(Self.Owner, 'Empresas');
  end;
end;

procedure TfrmMtoPedidosCompra.btnPegatinasClick(Sender: TObject);
var
  form: TfrmPrintEtiqPed;
  dmArt: TdmArticulos;
  sSerie: string;
  sNumero: string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmPedidosCompra <> nil then
  begin
    if dmmPedidosCompra.unqryTablaG.IsEmpty then
      ShowMessage(SErrorPedidoCompraNoActivo)
    else
    begin
      if dmmPedidosCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmPedidosCompra.unqryTablaG.Post;
      if dmmPedidosCompra.unqryPedidosCompraLineas.State in
         [dsEdit, dsInsert] then
        dmmPedidosCompra.unqryPedidosCompraLineas.Post;
      sSerie := dmmPedidosCompra.unqryTablaG.FieldByName(
        'SERIE_PEDC').AsString;
      sNumero := dmmPedidosCompra.unqryTablaG.FieldByName(
        'NUMERO_PEDC').AsString;
      dmArt := TdmArticulos.Create(nil);
      try
        form := TfrmPrintEtiqPed.Create(Application);
        try
          form.DMArt := dmArt;
          form.DMPedc := dmmPedidosCompra;
          form.Serie := sSerie;
          form.Numero := sNumero;
          form.ShowModal;
        finally
          FreeAndNil(form);
        end;
      finally
        FreeAndNil(dmArt);
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnCrearAlbaranClick(Sender: TObject);
var
  form: TfrmModalSelAlmacenPedido;
  sSerie, sNumero, sMsg: string;
  bOk: Boolean;
  arrCeldas: TArray<TCeldaARecibir>;
  recIdx: Integer;
  frmDocs: TfrmModalDocsCreados;
  sSerieDoc, sNumeroDoc: string;
  ParametrosRecepcion: TParametrosRecepcionPedidoCompra;
  ResultadoRecepcion: TResultadoRecepcionPedidoCompra;
begin
  inherited;
  if dmmPedidosCompra <> nil then
  begin
  if dmmPedidosCompra.unqryTablaG.IsEmpty then
    ShowMessage(SErrorPedidoCompraNoActivoCrearAlbaran)
  else
  begin
  if dmmPedidosCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmPedidosCompra.unqryTablaG.Post;
  if dmmPedidosCompra.unqryPedidosCompraLineas.State in [dsEdit, dsInsert] then
    dmmPedidosCompra.unqryPedidosCompraLineas.Post;
  sSerie  := dmmPedidosCompra.unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := dmmPedidosCompra.unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  form := TfrmModalSelAlmacenPedido.Create(Application);
  try
    form.SeriePedc            := sSerie;
    form.NumPedc              := sNumero;
    // Empresa del pedido: el modal carga con ella el combo de series
    // 'AB' y propone la serie que lleve el almacen elegido.
    form.CodigoEmpresa        :=
      dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString;
    form.SerieAlbDefecto      := sSerie;  // fallback = misma serie
    form.RefProveedorDefecto  :=
      dmmPedidosCompra.unqryTablaG.FieldByName('REF_PROVEEDOR_PEDC').AsString;
    // La temporada del pedido se hereda en el modal. Si la cabecera no
    // tiene (NULL) cae a 0 y el combo queda en blanco.
    form.IdPvTemporadaDefecto :=
      dmmPedidosCompra.unqryTablaG.FieldByName(
        'ID_PV_TEMPORADA_PEDC').AsInteger;
    // Almacen por defecto del modal: el de la primera celda con
    // cantidad 'A recibir' > 0 (sea en pivote expandido o en modo
    // vertical). Si el usuario no ha tecleado nada todavia, caemos al
    // almacen efectivo de la primera linea del pedido como fallback.
    if FColsModoConstruido then
      form.CodigoAlmacenDefecto := PrimerAlmacenARecibirCampo
    else if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
      form.CodigoAlmacenDefecto := FPivote.PrimerAlmacenARecibir
    else
      form.CodigoAlmacenDefecto := PrimerAlmacenARecibirVertical;
    if Trim(form.CodigoAlmacenDefecto) = '' then
      form.CodigoAlmacenDefecto :=
        AlmacenEfectivoPrimeraLinea(sSerie, sNumero);
    form.ShowModal;
    if form.Aceptado and (Trim(form.CodigoAlmacen) <> '') then
    begin
    // Decidir flujo: si el pivote esta expandido leemos celdas via lib;
    // si no, miramos la columna "A recibir" del modo vertical. Si no
    // hay tecleos en ninguno, caemos al flujo clasico (pendientes
    // totales del almacen).
    if FColsModoConstruido then
      // Contrato construido: "A recibir" vive en el campo
      // CANTIDAD_A_RECIBIR_PEDCLIN, tecleado como columna en
      // SKU/Desglose o como banda en tallas horizontal.
      arrCeldas := RecogerCeldasARecibirCampo(form.CodigoAlmacen)
    else if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
      arrCeldas := FPivote.IterarARecibirPorAlmacen(form.CodigoAlmacen)
    else
      arrCeldas := RecogerCeldasARecibirVertical(form.CodigoAlmacen);
    ParametrosRecepcion.SeriePedido := sSerie;
    ParametrosRecepcion.NumeroPedido := sNumero;
    ParametrosRecepcion.CodigoAlmacen := form.CodigoAlmacen;
    ParametrosRecepcion.SerieAlbaran := form.SerieAlbaran;
    ParametrosRecepcion.SerieAlbaranDestino :=
      form.AlbaranSerieDestino;
    ParametrosRecepcion.NumeroAlbaranDestino :=
      form.AlbaranNumDestino;
    ParametrosRecepcion.Usuario := IdentidadSesion.Usuario;
    ParametrosRecepcion.ReferenciaProveedor := form.RefProveedor;
    ParametrosRecepcion.FechaRecepcion := form.FechaRecepcion;
    ParametrosRecepcion.IdPvTemporada := form.IdPvTemporada;
    ParametrosRecepcion.Incorporar := form.Incorporar;
    ParametrosRecepcion.Celdas := arrCeldas;
    try
      bOk := FRecepcionPedido.EjecutarRecepcionPedidoCompra(
        ParametrosRecepcion,
        ResultadoRecepcion);
      sMsg := ResultadoRecepcion.Mensaje;
      if bOk then
      begin
        // Limpiar las celdas "A recibir" tecleadas para el almacen
        // procesado, para que el usuario pueda seguir con otro almacen
        // sin tener que borrar manualmente.
        if FColsModoConstruido then
          LimpiarARecibirCampoAlmacen(form.CodigoAlmacen)
        else if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
          FPivote.LimpiarARecibirParaAlmacen(form.CodigoAlmacen)
        else if Assigned(colLineaPedcARecibir) then
        begin
          // Modo vertical: poner a Null la columna A recibir de las
          // lineas cuyo almacen efectivo es el procesado.
          tvLineasPedido.DataController.BeginUpdate;
          try
            for recIdx := 0 to tvLineasPedido.DataController.RecordCount - 1 do
              tvLineasPedido.DataController.Values[recIdx,
                                  colLineaPedcARecibir.Index] := Null;
          finally
            tvLineasPedido.DataController.EndUpdate;
          end;
        end;
        RefrescarCantidadAAlbaranar;
        dmmPedidosCompra.unqryTablaG.Refresh;
        dmmPedidosCompra.unqryPedidosCompraLineas.Refresh;
        // Refrescar el grid de la pestania "Albaranes" para que aparezca
        // el albaran recien creado / incorporado (es detail del pedido,// no se
        // refresca solo al hacer Refresh del master).
        if dmmPedidosCompra.unqryAlbaranesPedc.Active then
          dmmPedidosCompra.unqryAlbaranesPedc.Close;
        dmmPedidosCompra.unqryAlbaranesPedc.Open;
        // Mostrar el albaran recien creado / incorporado en un modal
        // estilo Sesiones, con boton "Ir a documento" para abrir su
        // ficha. En modo incorporar el destino es el albaran existente
        // (Albaran...Destino); si no, el nuevo (SerieAlbaran / sNumAlb).
        sSerieDoc := ResultadoRecepcion.SerieAlbaran;
        sNumeroDoc := ResultadoRecepcion.NumeroAlbaran;
        frmDocs := TfrmModalDocsCreados.Create(Self);
        // Bloqueamos el caFree del ancestro (FormClose lo pone) para
        // poder leer Confirmado tras ShowModal y liberarlo nosotros.
        frmDocs.OnClose := nil;
        try
          frmDocs.lblTitulo.Caption :=
            Format('Albaran creado desde el pedido %s/%s', [sSerie, sNumero]);
          frmDocs.Agregar('Albaran', sSerieDoc, sNumeroDoc,
                          form.CodigoAlmacen);
          frmDocs.ShowModal;
          if frmDocs.Confirmado then
            ShowMto(Self.Owner, 'AlbaranesCompra',
                    sSerieDoc + ',' + sNumeroDoc);
        finally
          FreeAndNil(frmDocs);
        end;
      end
      else
        MessageDlg(sMsg, mtWarning, [mbOk], 0);
    except
      on E: Exception do
      begin
        MessageDlg(Format(SErrorCrearAlbaranDesdePedidoCompra,
                          [E.Message]),
                   mtError, [mbOk], 0);
      end;
    end;
    end;
  finally
    FreeAndNil(form);
  end;
  end;
  end;
end;

// ===========================================================================
// CONTRATO DE ENTRADA ColumnSKUcxGrid (Auto / SKU / Tallas horizontal + F1)
// ===========================================================================

procedure TfrmMtoPedidosCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  CfgT: TGridTallasConfig;
  ds: TDataSet;
  bDegradarASku: Boolean;
  ModoEfectivo: TModoColumnasSku;
begin
  if (dmmPedidosCompra <> nil) and
     not (csDestroying in ComponentState) and not FConstruyendoModo then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if ds.Active then
    begin
  FConstruyendoModo := True;
  // Registrar para que pedido se construye: el hook de DataChange solo
  // reconstruye el modo bandas cuando esta clave cambia.
  FPedidoModoActual := PedidoClaveActual;
  // Expansion/consolidacion en bloque (una linea por SKU): totales y
  // pendientes de recibir se recalculan UNA vez al finalizar en vez de
  // por cada post de linea (segundos de cascada al entrar al modo).
  dmmPedidosCompra.IniciarReorganizacionLineas;
  try
  PrepararReconstruccionModoDocumento(tvLineasPedido, ds,
    FModoEntrada, FTallaColumns, FAtribColumns, FColColorPivot);
  FColColorProveedorPivot := nil;
  colLineaPedcARecibir := nil;
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _PEDCLIN; idempotente por linea). SKU y tallas
  // derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmPedidosCompra.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    CrearServiciosColumnasSkuUniDAC(
      dmmPedidosCompra.unqryTablaG.Connection),
    ContextoSesion, tvLineasPedido, ds, FModoEntradaSel,
    Trim(dmmPedidosCompra.unqryTablaG.
      FieldByName('CODIGO_ALM_PEDC').AsString), 'PEDCLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FValidadorArticulos;
  Cfg.LookupAtributos := FLookupAtributos;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := CrearConfigPivoteBandasDocumentoCompra(
      dmmPedidosCompra.unqryTablaG.Connection,
      IdentidadSesion.Usuario, dsTablaG,
      dmmPedidosCompra.dsPedidosCompraLineas,
      'PEDC', 'PEDCLIN',
      'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN',
      CANT_TALLAS_MAX);
    // Compra sobre las bandas del pivote de venta: Pedido /
    // A recibir (banda de servicio) / Pendiente.
    CfgPV.FieldCantidadEntregada := 'CANTIDAD_RECIBIDA_PEDCLIN';
    CfgPV.FieldCantidadAAlbaranar := 'CANTIDAD_A_RECIBIR_PEDCLIN';
    CfgPV.BandaUnica := False;
    CfgPV.TextoBandaAAlbaranar := 'A recibir';
    CfgPV.Repositorios :=
      CrearRepositorioPivoteVenta(
        CfgPV.Conexion, CfgPV.Usuario, BusquedaVisual);
    CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
    CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
  end
  else if FModoEntradaSel = mcsTallasInline then
  begin
    // Tallas horizontal INLINE (estilo albaranes/sesiones): lineas
    // consolidadas por articulo+color y cantidades por celda de talla
    // en fza_pedidos_compra_celdas.
    CfgT := Default(TGridTallasConfig);
    CfgT.Conexion := dmmPedidosCompra.unqryTablaG.Connection;
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasPedido;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmPedidosCompra.dsPedidosCompraLineas;
    CfgT.FieldSerieMaster := 'SERIE_PEDC';
    CfgT.FieldNumeroMaster := 'NUMERO_PEDC';
    CfgT.FieldLinea := 'LINEA_PEDCLIN';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_PEDCLIN';
    CfgT.FieldPrecioBase := 'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN';
    CfgT.FieldTotalUds := 'CANTIDAD_PEDCLIN';
    CfgT.FieldTotalLinea := 'TOTAL_PEDCLIN';
    CfgT.TablaCeldas := 'fza_pedidos_compra_celdas';
    CfgT.FieldSerieCel := 'SERIE_PEDC_PEDCCEL';
    CfgT.FieldNumeroCel := 'NUMERO_PEDC_PEDCCEL';
    // Con infijo PEDC, como en la tabla real (patron ALBC_ALBCCEL).
    CfgT.FieldLineaCel := 'LINEA_PEDC_PEDCCEL';
    CfgT.FieldFilaCel := 'ID_FILA_PEDC_PEDCCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_PEDCCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_PEDCCEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := CANT_TALLAS_MAX;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  // El flag ANTES del Construir: si algo aborta a medias, nadie debe
  // tocar las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  bDegradarASku := not ConstruirModoEntradaDocumento(
    FModoEntrada, ModoEntradaResuelto, DesactivarEnterAsTabTemporal,
    RestaurarEnterAsTabTemporal, FModoEntradaSel,
    [mcsTallasInline, mcsTallasHorPed], 'PedidosCompra');
  if not bDegradarASku then
  begin
    CrearColumnasHostPedidoCompra;
    // Rotulo por modo EFECTIVO (Auto puede degradar a SKU si faltan
    // las columnas ATTR) y, en desglose, mostrar Color/Talla con los
    // nombres globales desde el principio (paso de pedidos de venta).
    ModoEfectivo := DetectarModoColumnasSku(Cfg);
    tsLineasPedido.Caption := CaptionModoLineasDocumento(
      'Líneas', 'Líneas', True, ModoEfectivo, True);
    if not (ModoEfectivo in
      [mcsSku, mcsTallasInline, mcsTallasHorPed]) then
      MostrarColumnasAtributoGlobalesPedc;
  end;
  finally
    dmmPedidosCompra.FinalizarReorganizacionLineas;
    FConstruyendoModo := False;
  end;
  // Reconstruccion completa en SKU FUERA del guard de reentrada
  // (dentro, la llamada recursiva saldria sin hacer nada). Maximo una.
  if bDegradarASku then
  begin
    FModoEntradaSel := mcsSku;
    ConstruirModoEntrada;
  end
  else
    RefrescarCantidadAAlbaranar;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.MostrarColumnasAtributoGlobalesPedc;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineasPedido,
    CrearColumnasDocumentoLecturas(
      dmmPedidosCompra.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoPedidosCompra.CrearColumnasHostPedidoCompra;
var
  ColLinea, ColPedida, ColRecibida, ColARecibir,
  ColTipoCantidad: TcxGridDBColumn;
begin
  // Columnas propias del pedido de compra tras el ClearItems del
  // contrato (las del modo — articulo/SKU/color/tallas — ya existen).
  ColLinea := CrearColumnaHostDocumento(
    tvLineasPedido, 'Línea', 'LINEA_PEDCLIN', 55, False);
  CrearColumnaHostDocumento(tvLineasPedido, 'Modelo prov.',
    'REF_PRV_PEDCLIN', 130, True);
  CrearColumnaHostDocumento(tvLineasPedido, 'Descripción',
    'DESCRIPCION_ARTICULO_PEDCLIN', 240, False);
  if FModoEntradaSel <> mcsTallasHorPed then
  begin
    // En el inline la cantidad PEDIDA se teclea por celda de talla y
    // CANTIDAD_PEDCLIN pasa a ser el TOTAL de la linea consolidada:
    // solo lectura en ese modo.
    ColPedida := CrearColumnaHostDocumento(
      tvLineasPedido, 'Pedida', 'CANTIDAD_PEDCLIN', 70,
      FModoEntradaSel <> mcsTallasInline);
    ColRecibida := CrearColumnaHostDocumento(
      tvLineasPedido, 'Recibida', 'CANTIDAD_RECIBIDA_PEDCLIN',
      75, False);
    ColARecibir := CrearColumnaHostDocumento(
      tvLineasPedido, 'A recibir',
      'CANTIDAD_A_RECIBIR_PEDCLIN', 80, True);
    ColARecibir.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(ColARecibir.Properties).
      OnEditValueChanged := ARecibirCampoEditValueChanged;
    ColTipoCantidad := CrearColumnaHostDocumento(
      tvLineasPedido, '', 'TIPO_CANTIDAD_ARTICULO_PEDCLIN',
      90, False);
    VincularCantidadGrid(ColPedida, ColTipoCantidad, UnidadesMedida);
    VincularCantidadGrid(ColRecibida, ColTipoCantidad, UnidadesMedida);
    VincularCantidadGrid(ColARecibir, ColTipoCantidad, UnidadesMedida);
  end;
  CrearColumnaHostDocumento(tvLineasPedido, 'Precio compra',
    'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN', 130, True);
  CrearColumnaHostDocumento(tvLineasPedido, '% IVA',
    'PORCENTAJE_IVA_PEDCLIN', 70, True);
  CrearColumnaHostDocumento(tvLineasPedido, 'Total',
    'TOTAL_PEDCLIN', 95, False);
  CrearColumnaHostDocumento(tvLineasPedido, 'Almacén',
    'CODIGO_ALMACEN_PEDCLIN', 80, True);
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
end;

procedure TfrmMtoPedidosCompra.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo clasico del pedido de compra (precio de compra del
  // proveedor, IVA, modelo proveedor, pivote del articulo...) se
  // reaprovecha tal cual: AplicarArticuloPedidoCompra acepta articulo
  // o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloPedidoCompra(ASku);
end;

procedure TfrmMtoPedidosCompra.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloPedidoCompra(ACodigoSku);
end;

procedure TfrmMtoPedidosCompra.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  ActualizarCaptionModoLineas;
end;

// Clamp del "A recibir" (campo CANTIDAD_A_RECIBIR_PEDCLIN) en los
// modos SKU/Desglose: el maximo es el pendiente de la linea. En el
// modo tallas el clamp lo hace el propio pivote sobre su banda.
procedure TfrmMtoPedidosCompra.ARecibirCampoEditValueChanged(
  Sender: TObject);
var
  ed     : TcxCustomEdit;
  ds     : TUniQuery;
  vEdit  : Variant;
  rValor : Double;
  rPdte  : Double;
begin
  if (Sender is TcxCustomEdit) and (dmmPedidosCompra <> nil) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    begin
      ed    := TcxCustomEdit(Sender);
      vEdit := ed.EditValue;
      rValor := 0;
      if not (VarIsNull(vEdit) or VarIsEmpty(vEdit)) then
      begin
        if VarIsNumeric(vEdit) then
          rValor := vEdit
        else
          rValor := StrToFloatDef(VarToStr(vEdit), 0);
      end;
      rPdte := ds.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
               ds.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
      if rPdte < 0 then
        rPdte := 0;
      if rValor > rPdte then
      begin
        MessageBeep(MB_ICONWARNING);
        ed.EditValue := rPdte;
      end;
    end;
  end;
  RefrescarCantidadAAlbaranar;
end;

function TfrmMtoPedidosCompra.RecogerCeldasARecibirCampo(
  const ACodigoAlm: string): TArray<TCeldaARecibir>;
var
  ds: TUniQuery;
  res: TList<TCeldaARecibir>;
  bk: TBookmark;
  rARec: Double;
  c: TCeldaARecibir;
  sAlmLin, sAlmCab, sAlmEfe: string;
begin
  Result := nil;
  if dmmPedidosCompra <> nil then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty and
       (ds.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
    begin
  sAlmCab :=
    dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
  res := TList<TCeldaARecibir>.Create;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      rARec := ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat;
      if rARec > 0 then
      begin
        sAlmLin := ds.FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString;
        if Trim(sAlmLin) <> '' then
          sAlmEfe := sAlmLin
        else
          sAlmEfe := sAlmCab;
        if SameText(sAlmEfe, ACodigoAlm) then
        begin
          c.LineaPedido   := ds.FieldByName('LINEA_PEDCLIN').AsString;
          c.CodigoSku     :=
            ds.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
          c.CodigoAlmacen := sAlmEfe;
          c.Cantidad      := rARec;
          res.Add(c);
        end;
      end;
      ds.Next;
    end;
    Result := res.ToArray;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
    FreeAndNil(res);
  end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.LimpiarARecibirCampoAlmacen(
  const ACodigoAlm: string);
var
  ds: TUniQuery;
  bk: TBookmark;
  sAlmLin, sAlmCab, sAlmEfe: string;
begin
  if dmmPedidosCompra <> nil then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty and
       (ds.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
    begin
  sAlmCab :=
    dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      if ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat > 0 then
      begin
        sAlmLin := ds.FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString;
        if Trim(sAlmLin) <> '' then
          sAlmEfe := sAlmLin
        else
          sAlmEfe := sAlmCab;
        if SameText(sAlmEfe, ACodigoAlm) then
        begin
          ds.Edit;
          ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat := 0;
          ds.Post;
        end;
      end;
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.TotalARecibirCampo: Double;
var
  ds: TUniQuery;
  bk: TBookmark;
begin
  Result := 0;
  if dmmPedidosCompra <> nil then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty and
       not (ds.State in dsEditModes) and
       (ds.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
    begin
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      Result := Result +
        ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat;
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.PrimerAlmacenARecibirCampo: string;
var
  ds: TUniQuery;
  bk: TBookmark;
  sAlmCab: string;
begin
  Result := '';
  if dmmPedidosCompra <> nil then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty and
       (ds.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
    begin
  sAlmCab :=
    dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while (Result = '') and (not ds.Eof) do
    begin
      if ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat > 0 then
      begin
        Result :=
          Trim(ds.FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString);
        if Result = '' then
          Result := sAlmCab;
      end;
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.RellenarARecibirCampoTodo: Integer;
var
  ds: TUniQuery;
  bk: TBookmark;
  rPdte: Double;
begin
  Result := 0;
  if dmmPedidosCompra <> nil then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (ds <> nil) and ds.Active and not ds.IsEmpty and
       (ds.FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil) then
    begin
  if ds.State in dsEditModes then
    ds.Post;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      rPdte := ds.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
               ds.FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
      if rPdte < 0 then
        rPdte := 0;
      if ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat <>
         rPdte then
      begin
        ds.Edit;
        ds.FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat := rPdte;
        ds.Post;
      end;
      if rPdte > 0 then
        Inc(Result);
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bk) then
      ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoPedidosCompra);
  ForceReferenceToClass(TfrmMtoPedidosCompra);
end.
