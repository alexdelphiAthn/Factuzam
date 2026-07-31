{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDevolucionesCompra                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de devoluciones de COMPRA.                                     }
{    Cabecera + lineas sobre fza_devoluciones_compra. Espejo simplificado         }
{    de inMtoDevoluciones adaptado a documento de compra (proveedor en            }
{    lugar de cliente, precio de compra en lugar de venta).                    }
{                                                                              }
{    Movimientos de stock: el data module (UniDataDevolucionesCompra)             }
{    reconstruye los movimientos DC desde las lineas actuales del              }
{    documento para mantener el kardex sincronizado tras correcciones.         }
{    La generacion de factura sigue pendiente para un hito posterior.          }
{******************************************************************************}
unit inMtoDevolucionesCompra;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni,
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
  cxGridDBBandedTableView, System.Generics.Collections,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  inLibColumnasSkuIntf,
  inLibGridPivoteVenta,
  UniDataDevolucionesCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList, cxSplitter, inLibDocumento, inLibDocumentoIntf;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;

type
  TfrmMtoDevolucionesCompra = class(TfrmMtoDocumento)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcDevolucion:           TcxPageControl;
    tsLineasDevolucion:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasDevolucion:  TcxGrid;
    tvLineasDevolucion:     TcxGridDBTableView;
    cxgrdlvlLineasDevolucion: TcxGridLevel;
    tsProveedor:         TcxTabSheet;
    cxgrdMovimientosProveedor: TcxGrid;
    tvMovimientosProveedor: TcxGridDBTableView;
    cxgrdlvlMovimientosProveedor: TcxGridLevel;

    // Cabecera
    lblNroDevolucion:    TcxLabel;
    txtNUMERO_DEVC:   TcxDBTextEdit;
    lblSerieDevolucion:  TcxLabel;
    cbbSERIE_DEVC:    TcxDBComboBox;
    lblFechaDevolucion:  TcxLabel;
    dteFECHA_DEVC:    TcxDBDateEdit;
    lblCabTotalPrendas: TcxLabel;
    lblCabTotalPrendasValor: TcxLabel;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_DEVC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_DEVC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombreDevc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_DEVC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    cbbCODIGO_ALM_DEVC: TcxDBLookupComboBox;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_DEVC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_DEVC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_DEVC: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_DEVC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_DEVC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_DEVC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_DEVC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_DEVC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_DEVC: TcxDBCurrencyEdit;
    grpDesgloseImpuestos: TGroupBox;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de accion
    btnAnadirLinea:       TcxButton;
    btnBorrarLinea:       TcxButton;
    btnTallasHorizontal:  TcxButton;
    btnAtributosColumna:  TcxButton;
    btnDevolverTodoStock: TcxButton;
    btnImprimirH: TcxButton;
    btnImprimirV: TcxButton;
    btnPegatinas: TcxButton;
    ActionList1: TActionList;
    actArticulos: TAction;
    actIrProveedor: TAction;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnDevolverTodoStockClick(Sender: TObject);
    procedure btnImprimirHClick(Sender: TObject);
    procedure btnImprimirVClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    // Eventos del grid de lineas — mismos handlers que en Sesiones de compra:
    // sin esto, las celdas talla quedan vacias al navegar, no se sombrean
    // las celdas fuera del conjunto pivot y Enter no salta de celda.
    procedure tvLineasDevolucionFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasDevolucionFocusedItemChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedItem, AFocusedItem: TcxCustomGridTableItem);
    procedure tvLineasDevolucionInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure tvLineasDevolucionEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);
    procedure tvLineasDevolucionKeyDown(Sender: TObject; var Key: Word;
                Shift: TShiftState);
    procedure tvLineasDevolucionCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasDevolucionEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cxgrdLineasDevolucionEnter(Sender: TObject);
    procedure cxgrdLineasDevolucionExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_DEVCPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_DEVCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnCODIGO_EMP_DEVCKeyUp(Sender: TObject; var Key: Word;
                Shift: TShiftState);
    procedure cbbCODIGO_PRV_DEVCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_PRV_DEVCKeyUp(Sender: TObject; var Key: Word;
                Shift: TShiftState);
    procedure colLineaDevcCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaDevcCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaDevcCODIGO_UNIDADPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    FColColorPivot   : TcxGridDBColumn;
    FAplicandoArticulo: Boolean;
    // Guarda contra reentrada del toggle desde dsTablaGDataChangeHook
    // disparado por el Edit/Post de PersistirPreferenciaPivote (entre
    // el Edit y el set, la cabecera tiene el ESPIVOTE viejo y el hook
    // veria discrepancia con Activo).
    FInToggleClick   : Boolean;
    FActualizandoColorPivot: Boolean;
    FColorPivotCodigos: TDictionary<string, string>;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal, con el
    // MISMO pivote tallashorped de venta (BANDA UNICA: Cantidad) sobre
    // lineas SKU reales, sin tabla de celdas. El Construir hace
    // ClearItems: las columnas del dfm y las del pivote de compras
    // antiguo mueren y las del documento se recrean en runtime. El
    // pivote de compras (FPivote/ESPIVOTE) queda RETIRADO de esta
    // pantalla (mismo criterio que albaranes/pedidos de compra).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombreDevc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataDevolucionesCompra
    // .unqryPrvDataDevc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    // Pinta lblCabTotalPrendasValor con el total de prendas (suma de
    // CANTIDAD_DEVCLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    function BuscarArticuloDevolucion: string;
    function BuscarSkuDevolucion(const ACodigoArt: string): string;
    function ArticuloLineaActivaDevolucion: string;
    function CodigoEmpresaActiva: string;
    function ValorLineaActiva(const ACampo: string): string;
    procedure EditarPrimeraTallaVisible;
    function CodigoSkuRepresentanteColor(const ACodigoArticulo,
                AColor: string; AIdAcPivot: Integer): string;
    procedure CargarOpcionesColorPivot(AProps: TcxComboBoxProperties);
    procedure ConfigurarEditorColorPivot(AEdit: TcxCustomEdit);
    procedure DesplegarEditorColorPivotDiferido;
    procedure ColorPivotInitPopup(Sender: TObject);
    procedure ColorPivotDrawItem(AControl: TcxCustomComboBox;
                ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
                AState: TOwnerDrawState);
    procedure ColorPivotEditValueChanged(Sender: TObject);
    function ObtenerColorPivotLineaActual(const ASerie, ANumero,
                ALinea: string; out AColorAv: Integer): Boolean;
    procedure BorrarGrupoColorPivotActual;
    procedure RestaurarPivoteHorizontalTrasOperacion(
                ADebeEstarActivo: Boolean);
    procedure PrepararColorPendienteArticuloDevolucion(
                const ACodigoArticulo: string; AIdAcPivot: Integer);
    procedure DevolverTodoStock;
    procedure AplicarArticuloDevolucion(const ACodigoArt: string);
    procedure colLineaDevcCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure AsegurarPrimeraLineaDevolucionCompra;
    procedure RefrescarAlmacenesCabecera;
    procedure ValidarAlmacenSalidaParaLineas;
    procedure AsegurarCabeceraPersistidaParaLineas;
    function PuedeActivarTallasHorizontal(var AMensaje: string): Boolean;
    procedure DispararBusquedaArticuloConTecla(var Key: Word;
                Shift: TShiftState);
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure PersistirPreferenciaPivote;
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostDevolucionCompra;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    // Rotulo de modo en la pestania de lineas, como en ventas.
    procedure ActualizarCaptionModoLineas;
    // Color/Talla visibles con nombres globales en desglose,
    // mismo paso que albaranes/pedidos de compra.
    procedure MostrarColumnasAtributoGlobalesDevc;
  protected
    // F1 = ciclar el modo de entrada (KeyPreview de TfrmBase),
    // mismo atajo que albaranes y pedidos de compra.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmDevolucionesCompra: TdmDevolucionesCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
  end;

implementation

uses
  System.StrUtils,
  inLibFiltroUsuario,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibGridCantidad,
  inLibColumnasDocumento, UniDataGen,
  inLibBusquedasCompra,
  inLibValidacionDocumento,
  inLibPresentacionDocumento,
  inLibAtributosPaleta,
  UniDataArticulos,
  inLibComprasImpuestos,
  inLibDevolucionesCompraStock,
  inLibMsgArticulos, inLibMsgCompras,
  inMtoModalImpDevCompra,
  inMtoModalImpDevCompraV,
  inMtoModalEtiqDev, inLibShowMto, inLibGenBusq,
  inLibValoresAutomaticos,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta;

{$R *.dfm}

type
  TAplicacionArticuloDevolucion = class
  private
    FFormulario: TfrmMtoDevolucionesCompra;
    FDataSet: TDataSet;
    FCodigoArticulo: string;
    FCodigoSku: string;
    FCodigoProveedor: string;
    FCodigoAlmacen: string;
    FFecha: TDateTime;
    FDatos: TArticuloDatos;
    FIdConjuntoPivot: Integer;
    FCantidad: Double;
    function CampoCabeceraString(const Campo: string): string;
    function FechaCabecera: TDateTime;
    function ResolverConjuntoPivotArticulo(
      const CodigoArticulo: string): Integer;
    function ModeloProveedorArticulo(const CodigoArticulo,
      CodigoProveedor: string): string;
    function EsCodigoArticuloExacto(const Codigo: string): Boolean;
    procedure PonerString(const Campo, Valor: string);
    procedure PonerFloat(const Campo: string; Valor: Double);
    procedure PonerInteger(const Campo: string; Valor: Integer);
    procedure LimpiarCampo(const Campo: string);
    procedure EnfocarSku(AbrirBusqueda: Boolean);
    procedure PrepararEdicion;
    procedure CargarDatosArticulo;
    procedure ResolverEntradaSku;
    procedure ResolverArticulo;
    procedure AplicarCamposArticulo;
    procedure AplicarCantidades;
    procedure ActualizarInterfaz;
    procedure AplicarDatos;
  public
    constructor Create(Formulario: TfrmMtoDevolucionesCompra;
      const Codigo: string);
    procedure Ejecutar;
  end;

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoDevolucionesCompra.cbbSERIE_DEVCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmDevolucionesCompra <> nil) and
     dmmDevolucionesCompra.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmDevolucionesCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_DEVC').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
  end;
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_DEVC.Properties.Items);
  if cbbSERIE_DEVC.Properties.Items.Count = 0 then
  begin
    if MessageDlg(Format(SPreguntaAbrirSeriesDevolucionCompra, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera del devolucion de compra. El articulo
// activo vive en la fila del sub-grid tvLineasDevolucion
// (CODIGO_ART_DEVCLIN / CODIGO_UNIDAD_DEVCLIN).
procedure TfrmMtoDevolucionesCompra.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
begin
  inherited;
  if ACodArt = '' then
  begin
    ACodArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
    ACodSku := ValorLineaActiva('CODIGO_UNIDAD_DEVCLIN');
  end;
end;

procedure TfrmMtoDevolucionesCompra.FormCreate(Sender: TObject);
begin
  FColorPivotCodigos := TDictionary<string, string>.Create;
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := CrearColumnaColorPivoteDocumento(
    tvLineasDevolucion, 'colLinDevcColorPivot', 110);
  FColColorPivot.DataBinding.ValueTypeClass := TcxStringValueType;
  FColColorPivot.PropertiesClass := TcxComboBoxProperties;
  with TcxComboBoxProperties(FColColorPivot.Properties) do
  begin
    DropDownListStyle := lsEditList;
    ImmediatePost := True;
    ImmediateDropDownWhenActivated := True;
    ImmediateDropDownWhenKeyPressed := True;
    IncrementalFiltering := True;
    PostPopupValueOnTab := True;
    OnInitPopup := ColorPivotInitPopup;
    OnDrawItem := ColorPivotDrawItem;
    OnEditValueChanged := ColorPivotEditValueChanged;
  end;
  inherited;
  ConfigurarColumnaBusquedaDocumento(
    tvLineasDevolucion, 'CODIGO_UNIDAD_DEVCLIN',
    colLineaDevcCODIGO_UNIDADPropertiesButtonClick,
    colLineaDevcCODIGO_UNIDADPropertiesValidate);
  tvLineasDevolucion.OptionsData.Editing := True;
  tvLineasDevolucion.OptionsBehavior.AlwaysShowEditor := True;
  tvLineasDevolucion.OnFocusedItemChanged :=
    tvLineasDevolucionFocusedItemChanged;
  tvLineasDevolucion.OnInitEdit := tvLineasDevolucionInitEdit;
  cbbCODIGO_ALM_DEVC.OnEnter := DesactivarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.OnExit  := RestaurarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.Properties.OnInitPopup :=
    DesactivarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.Properties.OnCloseUp :=
    RestaurarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.Properties.PostPopupValueOnTab := True;
  if Assigned(dmmDevolucionesCompra) then
  begin
    cbbCODIGO_ALM_DEVC.Properties.ListSource :=
      dmmDevolucionesCompra.dsAlmacenesDevc;
    RefrescarAlmacenesCabecera;
    // ListSource del combo de proveedor (busqueda incremental por codigo).
    // Reutiliza el lookup unqryPrvDataDevc, ya cargado para el rotulo.
    cbbCODIGO_PRV_DEVC.Properties.ListSource :=
      dmmDevolucionesCompra.dsPrvDataDevc;
  end;
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre devoluciones, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor de la devolucion enfocada al abrir el form.
  ActualizarLabelProveedor;
  ActualizarLabelPrendas;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesDevolucionCompra).
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FMostrarAtributos := False;
  FActualizandoColorPivot := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
  // Contrato de entrada ColumnSKUcxGrid: Tallas horizontal por defecto;
  // si su construccion falla, ConstruirModoEntrada degrada a SKU. F1
  // cicla los modos. El pivote de compras antiguo queda RETIRADO de
  // esta pantalla: se ocultan sus botones y nunca se activa (la
  // preferencia ESPIVOTE de la cabecera se ignora).
  FModoEntradaSel := mcsTallasHorPed;
  FColsModoConstruido := False;
  btnTallasHorizontal.Visible := False;
  btnAtributosColumna.Visible := False;
  ActualizarCaptionModoLineas;
  // Primera construccion al abrir la pantalla: sin ella, hasta entrar
  // en el grid se veian las columnas del dfm (ningun modo).
  if Assigned(dmmDevolucionesCompra) and
     dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Active then
    ConstruirModoEntrada;
end;

function TfrmMtoDevolucionesCompra.CodigoEmpresaActiva: string;
var
  ds: TDataSet;
  f : TField;
begin
  Result := '';
  ds := dsTablaG.DataSet;
  if Assigned(ds) and ds.Active and (not ds.IsEmpty) then
  begin
    f := ds.FindField('CODIGO_EMP_DEVC');
    if f <> nil then
      Result := Trim(f.AsString);
  end;
  if Result = '' then
    Result := Trim(UbicacionSesion.Empresa);
end;

function TfrmMtoDevolucionesCompra.ValorLineaActiva(
  const ACampo: string): string;
var
  rec  : TcxCustomGridRecord;
  col  : TcxGridDBColumn;
  valor: Variant;
  ds   : TDataSet;
  campo: TField;
begin
  Result := '';
  rec := tvLineasDevolucion.Controller.FocusedRecord;
  col := tvLineasDevolucion.GetColumnByFieldName(ACampo);
  if (rec <> nil) and (col <> nil) then
  begin
    valor := rec.Values[col.Index];
    if not (VarIsNull(valor) or VarIsEmpty(valor)) then
      Result := Trim(VarToStr(valor));
  end;
  if Result = '' then
  begin
    if Assigned(tvLineasDevolucion.DataController.DataSource) then
    begin
      ds := tvLineasDevolucion.DataController.DataSource.DataSet;
      if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
      begin
        campo := ds.FindField(ACampo);
        if (campo <> nil) and (not campo.IsNull) then
          Result := Trim(campo.AsString);
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.EditarPrimeraTallaVisible;
var
  i: Integer;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if (FTallaColumns[i] <> nil) and FTallaColumns[i].Visible and
       FTallaColumns[i].Options.Editing then
    begin
      tvLineasDevolucion.Controller.FocusedItem := FTallaColumns[i];
      if tvLineasDevolucion.Controller.EditingController <> nil then
        tvLineasDevolucion.Controller.EditingController.ShowEdit;
      Break;
    end;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarAlmacenesCabecera;
begin
  if Assigned(dmmDevolucionesCompra) then
    dmmDevolucionesCompra.RefrescarAlmacenes(CodigoEmpresaActiva);
end;

function TfrmMtoDevolucionesCompra.CodigoSkuRepresentanteColor(
  const ACodigoArticulo, AColor: string; AIdAcPivot: Integer): string;
var
  qry: TUniQuery;
begin
  Result := '';
  if (ACodigoArticulo <> '') and (AColor <> '') then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'SELECT X.SKU ' +
        '  FROM ( ' +
        '        SELECT SK.CODIGO_UNIDAD_SKU AS SKU, ' +
        '               COALESCE(NULLIF(AVC.AV, ''''), ' +
        '                 CASE WHEN INSTR(SK.CODIGO_UNIDAD_SKU, ''/'') > 0 ' +
        '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
        '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
        '                      ELSE '''' END, '''') AS COLOR_TXT, ' +
        '               CASE WHEN :idac <= 0 THEN 0 ' +
        '                    WHEN TAL.ID_AV_SA IS NULL THEN 0 ' +
        '                    WHEN ACD.ID_AV_ACD IS NOT NULL THEN 0 ' +
        '                    ELSE 1 END AS PENALIZA, ' +
        '               COALESCE(ACD.ORDEN_ACD, 999999) AS ORDEN_TALLA ' +
        '          FROM fza_articulos_skus SK ' +
        '          LEFT JOIN fza_atributos_sku CO ' +
        '            ON CO.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '           AND EXISTS (SELECT 1 FROM fza_atributos_valores AVC0 ' +
        '                        WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
        '                          AND AVC0.ID_VA_AV = ''CO'') ' +
        '          LEFT JOIN fza_atributos_valores AVC ' +
        '            ON AVC.ID_AV = CO.ID_AV_SA ' +
        '           AND AVC.ID_VA_AV = ''CO'' ' +
        '          LEFT JOIN fza_atributos_sku TAL ' +
        '            ON TAL.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '           AND EXISTS (SELECT 1 FROM fza_atributos_valores AVT ' +
        '                        WHERE AVT.ID_AV = TAL.ID_AV_SA ' +
        '                          AND AVT.ID_VA_AV = ''TAL'') ' +
        '          LEFT JOIN fza_atributos_conjuntos_det ACD ' +
        '            ON ACD.ID_AC_ACD = :idac ' +
        '           AND ACD.ID_AV_ACD = TAL.ID_AV_SA ' +
        '         WHERE SK.CODIGO_ART_SKU = :art ' +
        '           AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        '       ) X ' +
        ' WHERE X.COLOR_TXT = :color ' +
        ' ORDER BY X.PENALIZA, X.ORDEN_TALLA, X.SKU ' +
        ' LIMIT 1';
      qry.ParamByName('art').AsString := ACodigoArticulo;
      qry.ParamByName('color').AsString := AColor;
      qry.ParamByName('idac').AsInteger := AIdAcPivot;
      qry.Open;
      if not qry.Eof then
        Result := Trim(qry.FieldByName('SKU').AsString);
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.CargarOpcionesColorPivot(
  AProps: TcxComboBoxProperties);
var
  ds      : TDataSet;
  qry     : TUniQuery;
  sArt    : string;
  sTexto  : string;
  sCodigo : string;
begin
  if AProps <> nil then
  begin
    AProps.Items.BeginUpdate;
    try
      AProps.Items.Clear;
      if FColorPivotCodigos <> nil then
        FColorPivotCodigos.Clear;
      if Assigned(dmmDevolucionesCompra) then
      begin
        ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
        if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
        begin
          sArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
          if sArt <> '' then
          begin
            qry := TUniQuery.Create(nil);
            try
              qry.Connection := ConexionPrincipal;
              qry.SQL.Text :=
                'SELECT X.COLOR_TXT, MIN(X.COLOR_COD) AS COLOR_COD ' +
                '  FROM ( ' +
                '        SELECT COALESCE(NULLIF(AVC.AV, ''''), ' +
                '                 CASE WHEN INSTR(SK.CODIGO_UNIDAD_SKU, ' +
                '                                 ''/'') > 0 ' +
                '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
                '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ' +
                '                        ''/'', -1) ' +
                '                      ELSE '''' END, '''') AS COLOR_TXT, ' +
                '               COALESCE(ATBC.CODIGO_ATB, ' +
                '                 CASE WHEN INSTR(SK.CODIGO_UNIDAD_SKU, ' +
                '                                 ''/'') > 0 ' +
                '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
                '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ' +
                '                        ''/'', -1) ' +
                '                      ELSE '''' END, '''') AS COLOR_COD ' +
                '          FROM fza_articulos_skus SK ' +
                '          LEFT JOIN fza_atributos_sku CO ' +
                '            ON CO.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
                '           AND EXISTS (SELECT 1 FROM fza_atributos_valores AVC0 ' +
                '                        WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
                '                          AND AVC0.ID_VA_AV = ''CO'') ' +
                '          LEFT JOIN fza_atributos_valores AVC ' +
                '            ON AVC.ID_AV = CO.ID_AV_SA ' +
                '           AND AVC.ID_VA_AV = ''CO'' ' +
                '          LEFT JOIN fza_atributos_basicos ATBC ' +
                '            ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
                '         WHERE SK.CODIGO_ART_SKU = :art ' +
                '           AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
                '       ) X ' +
                ' WHERE X.COLOR_TXT <> '''' ' +
                ' GROUP BY X.COLOR_TXT ' +
                ' ORDER BY X.COLOR_TXT';
              qry.ParamByName('art').AsString := sArt;
              qry.Open;
              while not qry.Eof do
              begin
                sTexto := Trim(qry.FieldByName('COLOR_TXT').AsString);
                sCodigo := Trim(qry.FieldByName('COLOR_COD').AsString);
                AProps.Items.Add(sTexto);
                if (FColorPivotCodigos <> nil) and (sTexto <> '') and
                   (sCodigo <> '') then
                  FColorPivotCodigos.AddOrSetValue(UpperCase(sTexto),
                                                   sCodigo);
                qry.Next;
              end;
            finally
              FreeAndNil(qry);
            end;
          end;
        end;
      end;
    finally
      AProps.Items.EndUpdate;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.ConfigurarEditorColorPivot(
  AEdit: TcxCustomEdit);
begin
  if AEdit <> nil then
  begin
    AEdit.OnEnter := DesactivarEnterAsTabTemporal;
    AEdit.OnExit := RestaurarEnterAsTabTemporal;
    DesactivarEnterAsTabTemporal(AEdit);
    if AEdit is TcxComboBox then
    begin
      CargarOpcionesColorPivot(TcxComboBox(AEdit).Properties);
      TcxComboBox(AEdit).Properties.OnInitPopup :=
        DesactivarEnterAsTabTemporal;
      TcxComboBox(AEdit).Properties.OnCloseUp :=
        RestaurarEnterAsTabTemporal;
      TcxComboBox(AEdit).Properties.OnDrawItem := ColorPivotDrawItem;
      TcxComboBox(AEdit).Properties.PostPopupValueOnTab := True;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.DesplegarEditorColorPivotDiferido;
begin
  TThread.ForceQueue(nil,
    procedure
    var
      Edit : TcxCustomEdit;
      Combo: TcxComboBox;
    begin
      if (tvLineasDevolucion.Controller.FocusedItem = FColColorPivot) and
         Assigned(FPivote) and FPivote.Activo and
         (not FActualizandoColorPivot) and
         (tvLineasDevolucion.Controller.EditingController <> nil) then
      begin
        CargarOpcionesColorPivot(TcxComboBoxProperties(FColColorPivot.Properties));
        tvLineasDevolucion.Controller.EditingController.ShowEdit;
        Edit := tvLineasDevolucion.Controller.EditingController.Edit;
        ConfigurarEditorColorPivot(Edit);
        if Edit is TcxComboBox then
        begin
          Combo := TcxComboBox(Edit);
          CargarOpcionesColorPivot(Combo.Properties);
          Combo.DroppedDown := True;
        end
        else if Edit is TcxCustomDropDownEdit then
          TcxCustomDropDownEdit(Edit).DroppedDown := True;
      end;
    end);
end;

procedure TfrmMtoDevolucionesCompra.ColorPivotInitPopup(Sender: TObject);
var
  Props: TcxComboBoxProperties;
begin
  Props := nil;
  if Sender is TcxComboBox then
    Props := TcxComboBox(Sender).Properties
  else if FColColorPivot <> nil then
    Props := TcxComboBoxProperties(FColColorPivot.Properties);
  CargarOpcionesColorPivot(Props);
end;

procedure TfrmMtoDevolucionesCompra.ColorPivotDrawItem(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas; AIndex: Integer;
  const ARect: TRect; AState: TOwnerDrawState);
const
  LADO        = 12;
  MARGEN_IZQ  = 6;
  HUECO_TEXTO = 8;
var
  sTexto    : string;
  sCodigo   : string;
  Info      : TInfoBasico;
  rCuadrado : TRect;
  rTexto    : TRect;
  iAlto     : Integer;
  iTop      : Integer;
  bHayColor : Boolean;
begin
  if (AControl <> nil) and (ACanvas <> nil) and
     (AIndex >= 0) and (AIndex < AControl.Properties.Items.Count) then
  begin
    sTexto := AControl.Properties.Items[AIndex];
    ACanvas.FillRect(ARect);
    sCodigo := '';
    if FColorPivotCodigos <> nil then
      FColorPivotCodigos.TryGetValue(UpperCase(Trim(sTexto)), sCodigo);
    bHayColor := False;
    if sCodigo <> '' then
      bHayColor := ObtenerInfoBasico(ConexionPrincipal,'CO', sCodigo, Info);
    if not bHayColor then
      bHayColor := ObtenerInfoBasico(ConexionPrincipal,'CO', sTexto, Info);
    if not bHayColor then
      bHayColor := BuscarInfoBasicoEnArticulo(ConexionPrincipal,sTexto,
                                              ObtenerMapaAtributosGlobal(
                                                ConexionPrincipal),
                                              Info);
    if bHayColor then
    begin
      iAlto := ARect.Bottom - ARect.Top;
      if iAlto > LADO then
        iTop := ARect.Top + (iAlto - LADO) div 2
      else
        iTop := ARect.Top;
      rCuadrado := Rect(ARect.Left + MARGEN_IZQ, iTop,
                        ARect.Left + MARGEN_IZQ + LADO, iTop + LADO);
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := Info.Color;
      ACanvas.FillRect(rCuadrado);
      ACanvas.Brush.Style := bsClear;
      ACanvas.Pen.Color := clBlack;
      ACanvas.Pen.Width := 1;
      ACanvas.Rectangle(rCuadrado);
      ACanvas.Brush.Style := bsSolid;
      rTexto := Rect(rCuadrado.Right + HUECO_TEXTO, ARect.Top,
                     ARect.Right, ARect.Bottom);
    end
    else
      rTexto := Rect(ARect.Left + MARGEN_IZQ, ARect.Top,
                     ARect.Right, ARect.Bottom);
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(sTexto, rTexto,
                     DT_SINGLELINE or DT_VCENTER or DT_LEFT or
                     DT_END_ELLIPSIS);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

procedure TfrmMtoDevolucionesCompra.ColorPivotEditValueChanged(
  Sender: TObject);
var
  ds    : TDataSet;
  sColor: string;
  sArt  : string;
  sSku  : string;
  iAc   : Integer;
begin
  if (not FActualizandoColorPivot) and (Sender is TcxCustomEdit) and
     Assigned(dmmDevolucionesCompra) then
  begin
    ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    begin
      sColor := Trim(VarToStr(TcxCustomEdit(Sender).EditValue));
      sArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
      iAc := StrToIntDef(ValorLineaActiva('ID_AC_PIVOT_DEVCLIN'), 0);
      sSku := CodigoSkuRepresentanteColor(sArt, sColor, iAc);
      if (sSku <> '') and
         (not SameText(sSku,
              Trim(ds.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString))) then
      begin
        FActualizandoColorPivot := True;
        try
          if not (ds.State in dsEditModes) then
            ds.Edit;
          ds.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString := sSku;
          if ds.FindField('ID_AC_PIVOT_DEVCLIN') <> nil then
            ds.FieldByName('ID_AC_PIVOT_DEVCLIN').AsInteger := iAc;
          ds.Post;
          if Assigned(FPivote) and FPivote.Activo then
            FPivote.RecargarYRepublicar;
          RefrescarVisibilidadTallas;
          EditarPrimeraTallaVisible;
        finally
          FActualizandoColorPivot := False;
        end;
      end;
    end;
  end;
end;

function TfrmMtoDevolucionesCompra.ObtenerColorPivotLineaActual(
  const ASerie, ANumero, ALinea: string; out AColorAv: Integer): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  AColorAv := 0;
  if (ASerie <> '') and (ANumero <> '') and (ALinea <> '') then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'SELECT COALESCE(AVC.ID_AV, 0) AS COLOR_AV ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        '  LEFT JOIN fza_atributos_sku SAC ' +
        '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_DEVCLIN ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
        '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
        '                  AND AV.ID_VA_AV = ''CO'') ' +
        '  LEFT JOIN fza_atributos_valores AVC ' +
        '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
        '   AND AVC.ID_VA_AV = ''CO'' ' +
        ' WHERE L.SERIE_DEVC_DEVCLIN = :serie ' +
        '   AND L.NUMERO_DEVC_DEVCLIN = :numero ' +
        '   AND L.LINEA_DEVCLIN = :linea';
      qry.ParamByName('serie').AsString := ASerie;
      qry.ParamByName('numero').AsString := ANumero;
      qry.ParamByName('linea').AsString := ALinea;
      qry.Open;
      if not qry.IsEmpty then
      begin
        AColorAv := qry.FieldByName('COLOR_AV').AsInteger;
        Result := True;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.BorrarGrupoColorPivotActual;
var
  dsCab       : TDataSet;
  dsLin       : TDataSet;
  qry         : TUniQuery;
  sSerie      : string;
  sNumero     : string;
  sLinea      : string;
  sArt        : string;
  iColorAv    : Integer;
  iFilas      : Integer;
  bTxOwned    : Boolean;
  bPivotActivo: Boolean;

  function SQLJoinColorLinea: string;
  begin
    Result :=
      '  LEFT JOIN fza_atributos_sku SAC ' +
      '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_DEVCLIN ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
      '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
      '                  AND AV.ID_VA_AV = ''CO'') ' +
      '  LEFT JOIN fza_atributos_valores AVC ' +
      '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
      '   AND AVC.ID_VA_AV = ''CO'' ';
  end;

  function SQLCondicionGrupo: string;
  begin
    Result :=
      ' WHERE L.SERIE_DEVC_DEVCLIN = :serie ' +
      '   AND L.NUMERO_DEVC_DEVCLIN = :numero ' +
      '   AND L.CODIGO_ART_DEVCLIN = :art ';
    if iColorAv > 0 then
      Result := Result +
        '   AND COALESCE(AVC.ID_AV, 0) = :color_av '
    else
      Result := Result +
        '   AND COALESCE(AVC.ID_AV, 0) = 0 ';
  end;

  procedure ParametrosGrupo(AQuery: TUniQuery);
  begin
    AQuery.ParamByName('serie').AsString := sSerie;
    AQuery.ParamByName('numero').AsString := sNumero;
    AQuery.ParamByName('art').AsString := sArt;
    if iColorAv > 0 then
      AQuery.ParamByName('color_av').AsInteger := iColorAv;
  end;

  procedure RefrescarTrasBorrado;
  begin
    if dsLin.Active and (not dsLin.IsEmpty) then
      dsLin.First;
    dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    dmmDevolucionesCompra.SincronizarMovimientos;
    if (dsCab <> nil) and dsCab.Active and (dsCab.State in dsEditModes) then
      dsCab.Post;
    if bPivotActivo and Assigned(FPivote) and (not FPivote.Activo) then
      btnTallasHorizontalClick(nil);
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
  end;

begin
  if Assigned(dmmDevolucionesCompra) then
  begin
    dsCab := dmmDevolucionesCompra.unqryTablaG;
    dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    bPivotActivo := Assigned(FPivote) and FPivote.Activo;
    if (dsLin <> nil) and dsLin.Active and (not dsLin.IsEmpty) then
    begin
      if dsLin.State = dsInsert then
        dsLin.Cancel
      else
      begin
        if dsLin.State in dsEditModes then
          dsLin.Post;
        sSerie := ValorLineaActiva('SERIE_DEVC_DEVCLIN');
        sNumero := ValorLineaActiva('NUMERO_DEVC_DEVCLIN');
        sLinea := ValorLineaActiva('LINEA_DEVCLIN');
        sArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
        if ObtenerColorPivotLineaActual(sSerie, sNumero, sLinea,
             iColorAv) and (sArt <> '') then
        begin
          qry := TUniQuery.Create(nil);
          try
            qry.Connection := ConexionPrincipal;
            Screen.Cursor := crHourGlass;
            try
              if bPivotActivo then
                FPivote.Desactivar;
              if dsLin.Active then
                dsLin.Close;
              bTxOwned := not ConexionPrincipal.InTransaction;
              try
                if bTxOwned then
                  ConexionPrincipal.StartTransaction;
                qry.SQL.Text :=
                  'DELETE C ' +
                  '  FROM fza_devoluciones_compra_celdas C ' +
                  '  JOIN fza_devoluciones_compra_lineas L ' +
                  '    ON C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
                  '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
                  '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
                  '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
                  SQLJoinColorLinea +
                  SQLCondicionGrupo;
                ParametrosGrupo(qry);
                qry.ExecSQL;
                qry.SQL.Text :=
                  'DELETE L ' +
                  '  FROM fza_devoluciones_compra_lineas L ' +
                  SQLJoinColorLinea +
                  SQLCondicionGrupo;
                ParametrosGrupo(qry);
                qry.ExecSQL;
                iFilas := qry.RowsAffected;
                if bTxOwned and ConexionPrincipal.InTransaction then
                  ConexionPrincipal.Commit;
              except
                if bTxOwned and ConexionPrincipal.InTransaction then
                  ConexionPrincipal.Rollback;
                raise;
              end;
              if not dsLin.Active then
                dsLin.Open;
              RefrescarTrasBorrado;
              if iFilas = 0 then
                MessageDlg(SErrorLineaColorDevolucionNoEncontrada,
                           mtInformation, [mbOk], 0);
            finally
              Screen.Cursor := crDefault;
              if (dsLin <> nil) and (not dsLin.Active) then
                dsLin.Open;
              if bPivotActivo and Assigned(FPivote) and
                 (not FPivote.Activo) then
                btnTallasHorizontalClick(nil);
            end;
          finally
            FreeAndNil(qry);
          end;
        end
        else
        begin
          dsLin.Delete;
          RefrescarTrasBorrado;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.ValidarAlmacenSalidaParaLineas;
begin
  if (dmmDevolucionesCompra.unqryTablaG.FindField(
    'CODIGO_ALM_DEVC') <> nil) and
     (Trim(dmmDevolucionesCompra.unqryTablaG.FieldByName(
      'CODIGO_ALM_DEVC').AsString) = '') then
  begin
    pcCab.ActivePage := tsCabecera;
    if cbbCODIGO_ALM_DEVC.CanFocus then
      cbbCODIGO_ALM_DEVC.SetFocus;
    raise Exception.Create(SErrorAlmacenSalidaDevolucionCompra);
  end;
end;

procedure TfrmMtoDevolucionesCompra.AsegurarCabeceraPersistidaParaLineas;
begin
  if Assigned(dmmDevolucionesCompra) then
    AsegurarCabeceraPersistidaCompra(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      ConfiguracionTallasDocumento,
      ValidarAlmacenSalidaParaLineas);
end;

function TfrmMtoDevolucionesCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
  if Assigned(dmmDevolucionesCompra) and Assigned(FPivote) then
    Result := PuedeActivarTallasHorizontalCompra(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      dmmDevolucionesCompra.unqryTablaG.Connection,
      ConfiguracionTallasDocumento,
      AsegurarCabeceraPersistidaParaLineas,
      FPivote.ValidarPivotePosible, AMensaje);
end;

procedure TfrmMtoDevolucionesCompra.DispararBusquedaArticuloConTecla(
  var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    colLineaDevcCODIGO_ARTPropertiesButtonClick(nil, 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdDevolucion, sdCompra));
  AsignarVistaLineasDocumento(tvLineasDevolucion);
  inherited;
  dmmDevolucionesCompra := TdmDevolucionesCompra(
    AsegurarDataModuleDocumento(
      Self, tdmDataModule, TdmDevolucionesCompra));
  ConfigurarTablaPrincipalDocumento(
    dmmDevolucionesCompra, dsTablaG, tvLineasDevolucion,
    dmmDevolucionesCompra.dsDevolucionesCompraLineas,
    [dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
     dmmDevolucionesCompra.unqryMovimientosProveedor],
    pkFieldName, 'SERIE_DEVC;NUMERO_DEVC');
  tvMovimientosProveedor.DataController.DataSource :=
    dmmDevolucionesCompra.dsMovimientosProveedor;
end;

procedure TfrmMtoDevolucionesCompra.FormDestroy(Sender: TObject);
begin
  LiberarModoYGestoresDocumento(
    FModoEntrada, FPivote, FGestorTallas);
  FreeAndNil(FColorPivotCodigos);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoDevolucionesCompra.CrearColumnasTallas;
begin
  CrearColumnasTallasDocumento(tvLineasDevolucion,
    'dbcLinDevcTalla', 50, FTallaColumns);
end;

// Columnas no-bound y de solo lectura para el desglose visual del SKU.
procedure TfrmMtoDevolucionesCompra.CrearColumnasAtributos;
begin
  CrearColumnasAtributosDocumento(tvLineasDevolucion,
    'dbcLinDevcAtrib', FAtribColumns);
end;

procedure TfrmMtoDevolucionesCompra.InicializarGestorYPivote;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfigTallas: TGridTallasConfig;
  oConfigPivote: TGridPivoteCompraConfig;
begin
  if Assigned(FGestorTallas) then
    FreeAndNil(FGestorTallas);
  if Assigned(FPivote) then
    FreeAndNil(FPivote);
  if Assigned(dmmDevolucionesCompra) then
  begin
    oBase := Default(TConfigPivoteDocumentoCompra);
    oBase.Conexion := dmmDevolucionesCompra.unqryTablaG.Connection;
    oBase.ContextoSesion := ContextoSesion;
    oBase.Usuario := IdentidadSesion.Usuario;
    oBase.Vista := tvLineasDevolucion;
    oBase.SourceMaster := dsTablaG;
    oBase.SourceLineas :=
      dmmDevolucionesCompra.dsDevolucionesCompraLineas;
    oBase.ConsultaLineas :=
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    oBase.ColumnasTallas := CopiarColumnasDocumento(FTallaColumns);
    oBase.ColColorPivot := FColColorPivot;
    oBase.PrefijoCabecera := 'DEVC';
    oBase.PrefijoLinea := 'DEVCLIN';
    oBase.PrefijoCelda := 'DEVCCEL';
    oBase.NombreTablaDocumento := 'devoluciones';
    oBase.AplicarContextoPivote := False;
    oConfigTallas := CrearConfigTallasDocumentoCompra(oBase);
    FGestorTallas := TGestorGridTallas.Create(oConfigTallas);
    ConfigurarEventosTallasDocumento(FTallaColumns,
      TallaEditValueChangedHook, TallaValidateHook);
    oConfigPivote := CrearConfigPivoteDocumentoCompra(oBase,
      FGestorTallas);
    FPivote := TGridPivoteCompra.Create(oConfigPivote);
  end;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarVisibilidadTallas;
begin
  // Sin pivote activo: ocultar todas las columnas talla. Con pivote
  // activo: delega en el gestor para mostrar solo las que aplican y
  // pintar captions. La carga de cantidades del pivote la hace el
  // controlador (no usamos FGestorTallas.CargarCantidadesTodasLineas
  // porque en compras la cantidad por SKU vive en la linea, no en
  // una tabla de celdas como en sesiones).
  if (FPivote = nil) or (not FPivote.Activo) or (FGestorTallas = nil) then
    EstablecerVisibilidadColumnasDocumento(FTallaColumns, False)
  else
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarVisibilidadAtributos;
begin
  EstablecerVisibilidadColumnasDocumento(FAtribColumns,
    FMostrarAtributos);
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributos del articulo de la linea con foco y
// los aplica como captions de las columnas ATTRn. La carga de los
// VALORES por SKU se hara en un hito posterior (cuando este el flujo
// completo de edicion de SKU por talla / color).
procedure TfrmMtoDevolucionesCompra.CargarCaptionsAtributosLineaActiva;
begin
  if Assigned(dmmDevolucionesCompra) then
    CargarCaptionsAtributosDocumento(
      dmmDevolucionesCompra.unqryDefArticuloDevc,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      'CODIGO_ART_DEVCLIN', FAtribColumns);
end;

procedure TfrmMtoDevolucionesCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmDevolucionesCompra = nil) or (FPivote = nil) then Exit;
  // Guardia de reentrada: ver comentario en el campo FInToggleClick.
  if FInToggleClick then Exit;
  FInToggleClick := True;
  try
    // Toggle alterna entre vista plana (1 fila por SKU) y vista pivote
    // (1 fila representante por articulo+color, columnas talla con la
    // cantidad de cada SKU). El modelo BBDD no cambia: el filtro vive
    // en cliente y lo gestiona la libreria.
    if not FPivote.Activo then
    begin
      if not PuedeActivarTallasHorizontal(sMensaje) then
      begin
        // Sender=nil => apertura automatica por preferencia guardada.
        // Si el documento no es pivotable dejamos
        // la vista vertical en silencio; solo avisamos cuando el usuario
        // pulsa el boton expresamente (Sender<>nil).
        if Sender <> nil then
          MessageDlg(sMensaje, mtWarning, [mbOk], 0);
        Exit;
      end;
      FPivote.Activar;
    end
    else
      FPivote.Desactivar;
    // Sender=nil: llamada automatica desde el data-change hook; no
    // re-escribir la preferencia.
    if Sender <> nil then
      PersistirPreferenciaPivote;
  finally
    FInToggleClick := False;
  end;
end;

procedure TfrmMtoDevolucionesCompra.PersistirPreferenciaPivote;
begin
  PersistirPreferenciaPivoteDocumento(
    dsTablaG.DataSet, 'ESPIVOTE_HORIZONTAL_DEVC', FPivote.Activo);
end;

procedure TfrmMtoDevolucionesCompra.btnImprimirHClick(Sender: TObject);
var
  form    : TfrmPrintDevCompra;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDevolucionesCompra = nil then Exit;
  if dmmDevolucionesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage(SErrorDevolucionCompraSinImpresionActiva);
    Exit;
  end;
  if dmmDevolucionesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmDevolucionesCompra.unqryTablaG.Post;
  if dmmDevolucionesCompra.unqryDevolucionesCompraLineas.State in [dsEdit, dsInsert] then
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Post;
  sSerie  := dmmDevolucionesCompra.unqryTablaG.FieldByName('SERIE_DEVC').AsString;
  sNumero := dmmDevolucionesCompra.unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
  form := TfrmPrintDevCompra.Create(Application);
  try
    form.dmDevc        := dmmDevolucionesCompra;
    form.edtSerie.Text := sSerie;
    form.edtNumero.Text:= sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnImprimirVClick(Sender: TObject);
var
  form    : TfrmPrintDevCompraV;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDevolucionesCompra = nil then Exit;
  if dmmDevolucionesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage(SErrorDevolucionCompraSinImpresionActiva);
    Exit;
  end;
  if dmmDevolucionesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmDevolucionesCompra.unqryTablaG.Post;
  if dmmDevolucionesCompra.unqryDevolucionesCompraLineas.State in [dsEdit, dsInsert] then
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Post;
  sSerie  := dmmDevolucionesCompra.unqryTablaG.FieldByName('SERIE_DEVC').AsString;
  sNumero := dmmDevolucionesCompra.unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
  form := TfrmPrintDevCompraV.Create(Application);
  try
    form.dmDevc        := dmmDevolucionesCompra;
    form.edtSerie.Text := sSerie;
    form.edtNumero.Text:= sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
  end;
end;


procedure TfrmMtoDevolucionesCompra.btnPegatinasClick(Sender: TObject);
var
  form    : TfrmPrintEtiqDev;
  dmArt   : TdmArticulos;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDevolucionesCompra = nil then Exit;
  if dmmDevolucionesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage(SErrorDevolucionCompraNoActiva);
    Exit;
  end;
  if dmmDevolucionesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmDevolucionesCompra.unqryTablaG.Post;
  sSerie  := dmmDevolucionesCompra.unqryTablaG.FieldByName('SERIE_DEVC').AsString;
  sNumero := dmmDevolucionesCompra.unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
  // El modal reutiliza el dataset de etiquetas del DM de articulos
  // (cdsEtiquetasArt, fxdsEtiquetasArt) para que el mismo .fr3 sirva
  // en ambos sitios. Creamos un DM temporal porque el form de
  // devoluciones no necesita uno permanente.
  // TdmArticulos.Create dispara DataModuleCreate que ya asigna la
  // conexion. No necesitamos AbrirDetalles ni OpenTables — las queries
  // de print (unqryTarifasPrint, unqryArtPrint) se abren bajo demanda
  // desde el modal / CrearDataSetEtiquetasArt.
  dmArt := TdmArticulos.Create(nil);
  try
    form := TfrmPrintEtiqDev.Create(Application);
    try
      form.DMArt  := dmArt;
      form.DMDevc := dmmDevolucionesCompra;
      form.Serie  := sSerie;
      form.Numero := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  finally
    FreeAndNil(dmArt);
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoDevolucionesCompra.RestaurarPivoteHorizontalTrasOperacion(
  ADebeEstarActivo: Boolean);
var
  dsCab   : TDataSet;
  sMensaje: string;
begin
  if ADebeEstarActivo and Assigned(FPivote) then
  begin
    dsCab := dsTablaG.DataSet;
    if not FPivote.Activo then
    begin
      if PuedeActivarTallasHorizontal(sMensaje) then
      begin
        if (dsCab <> nil) and dsCab.Active and (not dsCab.IsEmpty) and
           (dsCab.FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil) then
        begin
          if not (dsCab.State in dsEditModes) then
            dsCab.Edit;
          dsCab.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString := 'S';
          dsCab.Post;
        end;
        FPivote.Activar;
      end
      else
        MessageDlg(sMensaje, mtWarning, [mbOk], 0);
    end;
    if FPivote.Activo then
      FPivote.RecargarYRepublicar;
  end;
end;

function LeerTextoDataset(
  ADataSet: TDataSet;
  const ACampo: string): string;
var
  Campo: TField;
begin
  Result := '';
  Campo := ADataSet.FindField(ACampo);
  if Campo <> nil then
    Result := Trim(Campo.AsString);
end;

function LeerNumeroDataset(
  ADataSet: TDataSet;
  const ACampo: string): Double;
var
  Campo: TField;
begin
  Result := 0;
  Campo := ADataSet.FindField(ACampo);
  if (Campo <> nil) and (not Campo.IsNull) then
    Result := Campo.AsFloat;
end;

procedure MostrarEstadoStockDevolucionCompra(
  AEstado: TEstadoStockDevolucionCompra);
begin
  case AEstado of
    esdcProveedorNoIndicado:
      MessageDlg(
        SErrorProveedorDevolucionFilaNoSeleccionado,
        mtWarning, [mbOk], 0);
    esdcAlmacenNoIndicado:
      MessageDlg(
        SErrorAlmacenDevolucionFilaNoSeleccionado,
        mtWarning, [mbOk], 0);
    esdcArticuloNoIndicado:
      MessageDlg(
        SErrorArticuloDevolucionFilaNoSeleccionado,
        mtInformation, [mbOk], 0);
    esdcRequiereColor:
      MessageDlg(
        SErrorColorDevolucionFilaNoSeleccionado,
        mtInformation, [mbOk], 0);
    esdcSinStock:
      MessageDlg(
        SErrorStockDevolucionFilaNoDisponible,
        mtInformation, [mbOk], 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.DevolverTodoStock;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sLinea: string;
  iLineas: Integer;
  bPivotActivo: Boolean;
  Estado: TEstadoStockDevolucionCompra;
  Parametros: TParametrosStockDevolucionCompra;
begin
  if dmmDevolucionesCompra <> nil then
  begin
    dsCab := dmmDevolucionesCompra.unqryTablaG;
    dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (dsCab <> nil) and dsCab.Active and (not dsCab.IsEmpty) and
       (dsLin <> nil) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      if dsLin.Active and (dsLin.State in dsEditModes) then
        dsLin.Post;
      sLinea := ValorLineaActiva('LINEA_DEVCLIN');
      if sLinea = '' then
        MessageDlg(SErrorFilaDevolucionStockNoSeleccionada,
          mtInformation, [mbOk], 0)
      else
      begin
        Parametros.Serie := LeerTextoDataset(
          dsCab, 'SERIE_DEVC');
        Parametros.Numero := LeerTextoDataset(
          dsCab, 'NUMERO_DEVC');
        Parametros.CodigoProveedor :=
          LeerTextoDataset(dsCab, 'CODIGO_PRV_DEVC');
        Parametros.CodigoAlmacen :=
          LeerTextoDataset(dsCab, 'CODIGO_ALM_DEVC');
        Parametros.CodigoArticulo :=
          ValorLineaActiva('CODIGO_ART_DEVCLIN');
        Parametros.Usuario := IdentidadSesion.Usuario;
        Parametros.IdColor := 0;
        ObtenerColorPivotLineaActual(
          Parametros.Serie, Parametros.Numero, sLinea,
          Parametros.IdColor);
        Parametros.IvaNormal :=
          LeerNumeroDataset(dsCab, 'PORCENTAJE_IVAN_DEVC');
        Parametros.IvaReducido :=
          LeerNumeroDataset(dsCab, 'PORCENTAJE_IVAR_DEVC');
        Parametros.IvaSuperreducido :=
          LeerNumeroDataset(dsCab, 'PORCENTAJE_IVAS_DEVC');
        Parametros.IvaExento :=
          LeerNumeroDataset(dsCab, 'PORCENTAJE_IVAE_DEVC');
        Estado := ConsultarEstadoStockDevolucionCompra(
          ConexionPrincipal, Parametros);
        if Estado <> esdcDisponible then
          MostrarEstadoStockDevolucionCompra(Estado)
        else if MessageDlg(SPreguntaPrepararStockFilaDevolucion,
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          bPivotActivo := Assigned(FPivote) and FPivote.Activo;
          Screen.Cursor := crHourGlass;
          try
            if bPivotActivo then
              FPivote.Desactivar;
            if dsLin.Active then
              dsLin.Close;
            if DevolverTodoStockCompra(
              ConexionPrincipal, Parametros, iLineas, Estado) then
            begin
              if not dsLin.Active then
                dsLin.Open;
              dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
              if dsCab.State in dsEditModes then
                dsCab.Post;
              MessageDlg(
                Format(SInfoStockFilaDevolucionPreparado, [iLineas]),
                mtInformation, [mbOk], 0);
            end
            else
              MostrarEstadoStockDevolucionCompra(Estado);
          finally
            Screen.Cursor := crDefault;
            if not dsLin.Active then
              dsLin.Open;
            RestaurarPivoteHorizontalTrasOperacion(bPivotActivo);
          end;
        end;
      end;
    end;
  end;
end;
procedure TfrmMtoDevolucionesCompra.btnDevolverTodoStockClick(
  Sender: TObject);
begin
  inherited;
  DevolverTodoStock;
end;

procedure TfrmMtoDevolucionesCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcDevolucion.ActivePage := tsLineasDevolucion;
end;

procedure TfrmMtoDevolucionesCompra.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.FindField('CODIGO_ALM_DEVC') <> nil) and
     (Trim(dsTablaG.DataSet.FieldByName('CODIGO_ALM_DEVC').AsString) = '') then
  begin
    pcCab.ActivePage := tsCabecera;
    if cbbCODIGO_ALM_DEVC.CanFocus then
      cbbCODIGO_ALM_DEVC.SetFocus;
    raise Exception.Create(SErrorAlmacenSalidaDevolucionCompra);
  end;
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    CrearValidadorArticulos(
      dmmDevolucionesCompra.unqryTablaG.Connection),
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas, 'DEVCLIN');
  if (sLineasSinSku <> '') and
     (MessageDlg(Format(SPreguntaGrabarDevolucionCompraSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  if Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadesPendientes;
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    dsTablaG.DataSet.Post;
  end;
  // Tras Grabar, cxGrid borra los Values[] no-bound al repintar.
  // RecargarYRepublicar lo solventa.
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Actualiza la cabecera y delega el modo al navegar entre devoluciones.
procedure TfrmMtoDevolucionesCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
begin
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_EMP_DEVC') then
    RefrescarAlmacenesCabecera;
  // Refrescar el rotulo del proveedor al navegar entre devoluciones
  // (Field=nil) o al cambiar CODIGO_PRV_DEVC tecleado directamente.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_DEVC') then
    ActualizarLabelProveedor;
  // Al navegar entre devoluciones hay que recalcular el total de prendas:
  // las lineas cargadas son las de la devolucion recien enfocada.
  if Field = nil then
    ActualizarLabelPrendas;
  if Assigned(dmmDevolucionesCompra) then
    ActualizarModoEntradaAlNavegarDocumento(
      Field, dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel, True,
      ConstruirModoEntrada,
      dmmDevolucionesCompra.DesempaquetarAtributosLineas);
end;

procedure TfrmMtoDevolucionesCompra.ActualizarLabelProveedor;
begin
  if Assigned(dmmDevolucionesCompra) then
    lblProveedorNombreDevc.Caption := TextoProveedorDocumento(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.unqryPrvDataDevc,
      'CODIGO_PRV_DEVC')
  else
    lblProveedorNombreDevc.Caption := '';
end;

procedure TfrmMtoDevolucionesCompra.ActualizarLabelPrendas;
begin
  if Assigned(dmmDevolucionesCompra) then
    lblCabTotalPrendasValor.Caption := TextoTotalPrendasDocumento(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.TotalPrendasDevolucion)
  else
    lblCabTotalPrendasValor.Caption := '0';
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesDevolucionCompra) con la republicacion del controlador.
procedure TfrmMtoDevolucionesCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmDevolucionesCompra) then
  begin
    dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    dmmDevolucionesCompra.SincronizarMovimientos;
  end;
  ActualizarLabelPrendas;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla y, si "atributo por columna" esta activo, recargamos los nombres
// de atributo del articulo activo.
procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarFocoLineaDocumento(
    FGestorTallas, FPivote, FMostrarAtributos,
    CargarCaptionsAtributosLineaActiva);
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionFocusedItemChanged(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  if (AFocusedItem = FColColorPivot) and Assigned(FPivote) and
     FPivote.Activo and FColColorPivot.Options.Editing and
     (not FActualizandoColorPivot) then
    DesplegarEditorColorPivotDiferido;
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  if (AItem = FColColorPivot) and Assigned(FPivote) and FPivote.Activo and
     FColColorPivot.Options.Editing and (not FActualizandoColorPivot) then
  begin
    ConfigurarEditorColorPivot(AEdit);
    DesplegarEditorColorPivotDiferido;
  end;
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  ColArticulo: TcxGridDBColumn;
begin
  ColArticulo :=
    tvLineasDevolucion.GetColumnByFieldName('CODIGO_ART_DEVCLIN');
  if AItem = ColArticulo then
    DispararBusquedaArticuloConTecla(Key, Shift);
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ColArticulo: TcxGridDBColumn;
begin
  ColArticulo :=
    tvLineasDevolucion.GetColumnByFieldName('CODIGO_ART_DEVCLIN');
  if tvLineasDevolucion.Controller.FocusedItem = ColArticulo then
    DispararBusquedaArticuloConTecla(Key, Shift);
end;

// Sombreado de celdas talla fuera del conjunto pivot — delegamos en lib.
procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

// Bloqueo de edicion en celdas talla fuera del conjunto — delegamos en lib.
procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.EditingCeldaTalla(Sender, AItem, AAllow);
end;

// Apaga TJvEnterAsTab al entrar al grid para que Enter navegue de
// celda a celda (combinado con FocusCellOnTab del grid en el DFM) y lo
// reactiva al salir. Misma logica que en Sesiones.
procedure TfrmMtoDevolucionesCompra.cxgrdLineasDevolucionEnter(Sender: TObject);
begin
  inherited;
  EntrarGridLineasDocumento(
    Self, FColsModoConstruido, False, FModoEntrada,
    AsegurarPrimeraLineaDevolucionCompra, ConstruirModoEntrada);
end;

procedure TfrmMtoDevolucionesCompra.cxgrdLineasDevolucionExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoDevolucionesCompra.ActualizarCaptionModoLineas;
begin
  tsLineasDevolucion.Caption := CaptionModoLineasDocumento(
    '&1_Líneas', '&1_Líneas ', FColsModoConstruido,
    FModoEntradaSel, False);
end;

procedure TfrmMtoDevolucionesCompra.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcDevolucion.ActivePage = tsLineasDevolucion) and
    (dmmDevolucionesCompra <> nil), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasHorPed], ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoDevolucionesCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  ds: TDataSet;
  bDegradarASku: Boolean;
  ModoEfectivo: TModoColumnasSku;
begin
  if (dmmDevolucionesCompra = nil) or (csDestroying in ComponentState) then
    Exit;
  ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
  if not ds.Active then
    Exit;
  PrepararReconstruccionModoDocumento(tvLineasDevolucion, ds,
    FModoEntrada, FTallaColumns, FAtribColumns, FColColorPivot);
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _DEVCLIN; idempotente por linea). SKU y tallas
  // horizontal derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmDevolucionesCompra.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    dmmDevolucionesCompra.unqryTablaG.Connection,
    ContextoSesion, tvLineasDevolucion, ds, FModoEntradaSel,
    Trim(dmmDevolucionesCompra.unqryTablaG.
      FieldByName('CODIGO_ALM_DEVC').AsString), 'DEVCLIN');
  Cfg.ValidadorArticulos :=
    CrearValidadorArticulos(Cfg.Conexion);
  Cfg.LookupAtributos :=
    CrearLookupAtributosArticulos(Cfg.Conexion);
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := CrearConfigPivoteBandasDocumentoCompra(
      dmmDevolucionesCompra.unqryTablaG.Connection,
      IdentidadSesion.Usuario, dsTablaG,
      dmmDevolucionesCompra.dsDevolucionesCompraLineas,
      'DEVC', 'DEVCLIN',
      'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
      CANT_TALLAS_MAX);
    // Devolucion de compra: UNA sola cantidad por linea -> banda unica.
    CfgPV.BandaUnica := True;
    // La columna Total del host pasa a UNIDADES del grupo en pivote.
    CfgPV.FieldTotalUdsGrupo := 'TOTAL_DEVCLIN';
    CfgPV.Repositorio :=
      CrearRepositorioPivoteVenta(CfgPV.Conexion, CfgPV.Usuario);
    CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
    CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  // El flag ANTES del Construir: si algo aborta a medias, nadie debe
  // tocar las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  bDegradarASku := not ConstruirModoEntradaDocumento(
    FModoEntrada, ModoEntradaResuelto, DesactivarEnterAsTabTemporal,
    RestaurarEnterAsTabTemporal, FModoEntradaSel,
    [mcsTallasHorPed], 'DevolucionesCompra');
  if bDegradarASku then
  begin
    // Reconstruccion completa en SKU: el teardown de la reentrada
    // limpia lo que el pivote dejara a medias. Maximo una reentrada.
    FModoEntradaSel := mcsSku;
    ConstruirModoEntrada;
  end
  else
  begin
    CrearColumnasHostDevolucionCompra;
    // Rotulo por modo EFECTIVO (Auto puede degradar a SKU si faltan
    // las columnas ATTR en la BBDD) y, en desglose, mostrar Color y
    // Talla con nombres globales desde el principio (patron albaranes
    // de compra).
    ModoEfectivo := DetectarModoColumnasSku(Cfg);
    tsLineasDevolucion.Caption := CaptionModoLineasDocumento(
      '&1_Líneas', '&1_Líneas ', True, ModoEfectivo, False);
    if not (ModoEfectivo in [mcsSku, mcsTallasHorPed]) then
      MostrarColumnasAtributoGlobalesDevc;
  end;
end;

procedure TfrmMtoDevolucionesCompra.MostrarColumnasAtributoGlobalesDevc;
begin
  MostrarColumnasAtributoGlobalesDocumento(
    dmmDevolucionesCompra.unqryTablaG.Connection,
    tvLineasDevolucion);
end;

procedure TfrmMtoDevolucionesCompra.CrearColumnasHostDevolucionCompra;
var
  Columnas: TColumnasHostDocumentoCompra;
begin
  Columnas := CrearColumnasHostDocumentoCompra(
    tvLineasDevolucion, FModoEntradaSel, 'DEVCLIN');
  if Assigned(Columnas.ColCantidad) then
    VincularCantidadGrid(Columnas.ColCantidad,
      Columnas.ColTipoCantidad);
end;

procedure TfrmMtoDevolucionesCompra.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo clasico de la devolucion de compra (precio de compra del
  // proveedor, IVA, modelo proveedor...) se reaprovecha tal cual:
  // AplicarArticuloDevolucion acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloDevolucion(ASku);
end;

procedure TfrmMtoDevolucionesCompra.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloDevolucion(ACodigoSku);
end;

procedure TfrmMtoDevolucionesCompra.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoDevolucionesCompra.TallaEditValueChangedHook(Sender: TObject);
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
end;

procedure TfrmMtoDevolucionesCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

function TfrmMtoDevolucionesCompra.BuscarArticuloDevolucion: string;
var
  sPrv: string;
begin
  Result := '';
  sPrv := ValorTextoDataSetCompra(
    dsTablaG.DataSet, 'CODIGO_PRV_DEVC');
  if (sPrv = '') or (sPrv = '0') then
    MessageDlg(SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarArticuloProveedorCompra(
      ConexionPrincipal, sPrv, 'Búsqueda de artículos',
      'frmMtoDevcArtSearch', Self);
end;

function TfrmMtoDevolucionesCompra.ArticuloLineaActivaDevolucion: string;
begin
  Result := '';
  if Assigned(dmmDevolucionesCompra) then
    Result := ValorTextoDataSetCompra(
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      'CODIGO_ART_DEVCLIN');
end;

function TfrmMtoDevolucionesCompra.BuscarSkuDevolucion(
  const ACodigoArt: string): string;
var
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmDevolucionesCompra) then
    MessageDlg(SErrorDevolucionCompraNoAbierta,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg(SErrorArticuloNoSeleccionadoBuscarSkusDevolucion,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarSkuArticuloCompra(
      ConexionPrincipal, sArt, 'SKUs del artículo ' + sArt,
      'frmMtoDevcSkuSearch', Self);
end;

procedure TfrmMtoDevolucionesCompra.PrepararColorPendienteArticuloDevolucion(
  const ACodigoArticulo: string; AIdAcPivot: Integer);
var
  ds        : TDataSet;
  sRef      : string;
  sFam      : string;
  sDesc     : string;
  sTipoCant : string;
  sTipoIva  : string;
  sAlm      : string;
  rIva      : Double;
  rPrecioS  : Double;
  rPrecioC  : Double;

  function CampoString(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Result := Campo.AsString;
  end;

  function CampoFloat(const ACampo: string): Double;
  var
    Campo: TField;
  begin
    Result := 0;
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Result := Campo.AsFloat;
  end;

  procedure PonerString(const ACampo, AValor: string);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;

  procedure PonerFloat(const ACampo: string; AValor: Double);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsFloat := AValor;
  end;

  procedure PonerInteger(const ACampo: string; AValor: Integer);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsInteger := AValor;
  end;

  procedure PrepararLinea;
  begin
    PonerString('CODIGO_ART_DEVCLIN', ACodigoArticulo);
    PonerString('CODIGO_UNIDAD_DEVCLIN', '');
    PonerString('REF_PRV_DEVCLIN', sRef);
    PonerString('CODIGO_FAM_DEVCLIN', sFam);
    PonerString('DESCRIPCION_ARTICULO_DEVCLIN', sDesc);
    PonerString('TIPO_CANTIDAD_ARTICULO_DEVCLIN', sTipoCant);
    PonerString('TIPO_IVA_ARTICULO_DEVCLIN', sTipoIva);
    PonerString('CODIGO_ALMACEN_DEVCLIN', sAlm);
    PonerInteger('ID_AC_PIVOT_DEVCLIN', AIdAcPivot);
    PonerFloat('PORCENTAJE_IVA_DEVCLIN', rIva);
    PonerFloat('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN', rPrecioS);
    PonerFloat('PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN', rPrecioC);
    PonerFloat('CANTIDAD_DEVCLIN', 0);
    PonerFloat('TOTAL_UNIDADES_DEVCLIN', 0);
    PonerFloat('TOTAL_DEVCLIN', 0);
  end;

begin
  if (ACodigoArticulo <> '') and
     (AIdAcPivot > 0) and
     Assigned(dmmDevolucionesCompra) then
  begin
    ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (ds <> nil) and ds.Active then
    begin
      sRef      := CampoString('REF_PRV_DEVCLIN');
      sFam      := CampoString('CODIGO_FAM_DEVCLIN');
      sDesc     := CampoString('DESCRIPCION_ARTICULO_DEVCLIN');
      sTipoCant := CampoString('TIPO_CANTIDAD_ARTICULO_DEVCLIN');
      sTipoIva  := CampoString('TIPO_IVA_ARTICULO_DEVCLIN');
      sAlm      := CampoString('CODIGO_ALMACEN_DEVCLIN');
      rIva      := CampoFloat('PORCENTAJE_IVA_DEVCLIN');
      rPrecioS  := CampoFloat('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN');
      rPrecioC  := CampoFloat('PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN');
      if not (ds.State in dsEditModes) then
        ds.Edit;
      PrepararLinea;
      ds.Post;
    end;
  end;
end;

{ TAplicacionArticuloDevolucion }

constructor TAplicacionArticuloDevolucion.Create(
  Formulario: TfrmMtoDevolucionesCompra; const Codigo: string);
begin
  inherited Create;
  FFormulario := Formulario;
  FCodigoArticulo := Trim(Codigo);
end;

function TAplicacionArticuloDevolucion.CampoCabeceraString(
  const Campo: string): string;
var
  CampoDataSet: TField;
begin
  Result := '';
  if Assigned(FFormulario.dsTablaG) and
     Assigned(FFormulario.dsTablaG.DataSet) then
  begin
    CampoDataSet := FFormulario.dsTablaG.DataSet.FindField(Campo);
    if CampoDataSet <> nil then
      Result := Trim(CampoDataSet.AsString);
  end;
end;

function TAplicacionArticuloDevolucion.FechaCabecera: TDateTime;
var
  Campo: TField;
begin
  Result := Date;
  if Assigned(FFormulario.dsTablaG) and
     Assigned(FFormulario.dsTablaG.DataSet) then
  begin
    Campo := FFormulario.dsTablaG.DataSet.FindField('FECHA_DEVC');
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsDateTime;
  end;
end;

function TAplicacionArticuloDevolucion.ResolverConjuntoPivotArticulo(
  const CodigoArticulo: string): Integer;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FFormulario.ConexionPrincipal;
    Consulta.SQL.Text :=
      'SELECT aca.ID_AC_ACA ' +
      '  FROM fza_articulos_conjuntos_asign aca ' +
      ' WHERE aca.CODIGO_ART_ACA = :art ' +
      '   AND aca.ID_VA_ACA <> ''CO'' ' +
      ' ORDER BY aca.ID_VA_ACA ' +
      ' LIMIT 1';
    Consulta.ParamByName('art').AsString := CodigoArticulo;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('ID_AC_ACA').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TAplicacionArticuloDevolucion.ModeloProveedorArticulo(
  const CodigoArticulo, CodigoProveedor: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FFormulario.ConexionPrincipal;
    Consulta.SQL.Text :=
      'SELECT ap.REF_PROVEEDOR_AP ' +
      '  FROM fza_articulos_proveedores ap ' +
      ' WHERE ap.CODIGO_ART_AP = :art ' +
      '   AND COALESCE(TRIM(ap.REF_PROVEEDOR_AP), '''') <> '''' ' +
      ' ORDER BY CASE WHEN ap.CODIGO_PRV_AP = :prv THEN 0 ELSE 1 END, ' +
      '          CASE ap.ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ' +
      '               ELSE 1 END, ' +
      '          ap.FECHA_VALIDEZ_AP DESC, ap.CODIGO_PRV_AP ' +
      ' LIMIT 1';
    Consulta.ParamByName('art').AsString := CodigoArticulo;
    Consulta.ParamByName('prv').AsString := CodigoProveedor;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('REF_PROVEEDOR_AP').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TAplicacionArticuloDevolucion.EsCodigoArticuloExacto(
  const Codigo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  if Trim(Codigo) <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FFormulario.ConexionPrincipal;
      Consulta.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :art ' +
        ' LIMIT 1';
      Consulta.ParamByName('art').AsString := Trim(Codigo);
      Consulta.Open;
      Result := not Consulta.IsEmpty;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TAplicacionArticuloDevolucion.PonerString(
  const Campo, Valor: string);
var
  CampoDataSet: TField;
begin
  CampoDataSet := FDataSet.FindField(Campo);
  if CampoDataSet <> nil then
    CampoDataSet.AsString := Valor;
end;

procedure TAplicacionArticuloDevolucion.PonerFloat(
  const Campo: string; Valor: Double);
var
  CampoDataSet: TField;
begin
  CampoDataSet := FDataSet.FindField(Campo);
  if CampoDataSet <> nil then
    CampoDataSet.AsFloat := Valor;
end;

procedure TAplicacionArticuloDevolucion.PonerInteger(
  const Campo: string; Valor: Integer);
var
  CampoDataSet: TField;
begin
  CampoDataSet := FDataSet.FindField(Campo);
  if CampoDataSet <> nil then
    CampoDataSet.AsInteger := Valor;
end;

procedure TAplicacionArticuloDevolucion.LimpiarCampo(
  const Campo: string);
var
  CampoDataSet: TField;
begin
  CampoDataSet := FDataSet.FindField(Campo);
  if CampoDataSet <> nil then
    CampoDataSet.Clear;
end;

procedure TAplicacionArticuloDevolucion.EnfocarSku(
  AbrirBusqueda: Boolean);
var
  ColumnaSku: TcxGridDBColumn;
  Formulario: TfrmMtoDevolucionesCompra;
begin
  Formulario := FFormulario;
  ColumnaSku := Formulario.tvLineasDevolucion.GetColumnByFieldName(
    'CODIGO_UNIDAD_DEVCLIN');
  if ColumnaSku <> nil then
  begin
    ColumnaSku.Visible := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        Formulario.tvLineasDevolucion.Controller.FocusedColumn :=
          ColumnaSku;
        Formulario.tvLineasDevolucion.Controller.EditingController.ShowEdit;
        if AbrirBusqueda then
          Formulario.colLineaDevcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
      end);
  end;
end;

procedure TAplicacionArticuloDevolucion.PrepararEdicion;
begin
  if FDataSet.IsEmpty then
    FDataSet.Append;
  if not (FDataSet.State in dsEditModes) then
    FDataSet.Edit;
  FCodigoProveedor := CampoCabeceraString('CODIGO_PRV_DEVC');
  FCodigoAlmacen := CampoCabeceraString('CODIGO_ALM_DEVC');
  FFecha := FechaCabecera;
end;

procedure TAplicacionArticuloDevolucion.CargarDatosArticulo;
var
  Resolver: IArticulosResolver;
begin
  Resolver := FFormulario.CrearResolverArticulos(
    FFormulario.ConexionPrincipal);
  try
    FDatos := Resolver.ResolverDatos(
      FCodigoArticulo, FCodigoSku, '', FFecha,
      FCodigoAlmacen, FCodigoProveedor);
    if FDatos.Encontrado and FDatos.RequiereSku then
      FDatos.UltimoCoste := Resolver.ResolverUltimoCoste(
        FDatos.CodigoArticulo, FCodigoProveedor, '');
  finally
    Resolver := nil;
  end;
end;

procedure TAplicacionArticuloDevolucion.ResolverEntradaSku;
var
  Validador: IArticulosValidador;
  Resolucion: TArtResolucionEntrada;
begin
  Validador := FFormulario.CrearValidadorArticulos(
    FFormulario.ConexionPrincipal);
  try
    Resolucion := Validador.Resolver(FCodigoArticulo);
  finally
    Validador := nil;
  end;
  if Resolucion.Encontrado then
  begin
    FCodigoArticulo := Resolucion.CodigoArticulo;
    FCodigoSku := Resolucion.CodigoSku;
    CargarDatosArticulo;
  end
  else if Resolucion.Mensaje <> '' then
    FDatos.Mensaje := Resolucion.Mensaje
  else
    FDatos.Mensaje := 'No se encontró el artículo "' +
      FCodigoArticulo + '".';
end;

procedure TAplicacionArticuloDevolucion.ResolverArticulo;
begin
  FCodigoSku := '';
  FDatos.Clear;
  if EsCodigoArticuloExacto(FCodigoArticulo) then
    CargarDatosArticulo
  else
    ResolverEntradaSku;
end;

procedure TAplicacionArticuloDevolucion.AplicarCamposArticulo;
var
  ModeloProveedor: string;
begin
  FIdConjuntoPivot := ResolverConjuntoPivotArticulo(
    FDatos.CodigoArticulo);
  ModeloProveedor := ModeloProveedorArticulo(
    FDatos.CodigoArticulo, FCodigoProveedor);
  if ModeloProveedor = '' then
    ModeloProveedor := FDatos.UltimoCoste.RefProveedor;
  PonerString('CODIGO_ART_DEVCLIN', FDatos.CodigoArticulo);
  PonerString('CODIGO_UNIDAD_DEVCLIN', FDatos.CodigoSku);
  PonerString('REF_PRV_DEVCLIN', ModeloProveedor);
  PonerString('CODIGO_FAM_DEVCLIN', FDatos.CodigoFamilia);
  PonerString(
    'DESCRIPCION_ARTICULO_DEVCLIN', FDatos.DescripcionArticulo);
  PonerString(
    'TIPO_CANTIDAD_ARTICULO_DEVCLIN', FDatos.TipoCantidad);
  PonerString('TIPO_IVA_ARTICULO_DEVCLIN', FDatos.TipoIVA);
  PonerFloat(
    'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
    FDatos.UltimoCoste.PrecioUltCompra);
  if FCodigoAlmacen <> '' then
    PonerString('CODIGO_ALMACEN_DEVCLIN', FCodigoAlmacen);
  if FIdConjuntoPivot > 0 then
    PonerInteger('ID_AC_PIVOT_DEVCLIN', FIdConjuntoPivot)
  else
    LimpiarCampo('ID_AC_PIVOT_DEVCLIN');
end;

procedure TAplicacionArticuloDevolucion.AplicarCantidades;
begin
  FCantidad := 0;
  if FDatos.RequiereSku and (FIdConjuntoPivot > 0) then
  begin
    PonerFloat('CANTIDAD_DEVCLIN', 0);
    PonerFloat('TOTAL_UNIDADES_DEVCLIN', 0);
  end
  else
  begin
    if FDataSet.FindField('CANTIDAD_DEVCLIN') <> nil then
      FCantidad := FDataSet.FieldByName('CANTIDAD_DEVCLIN').AsFloat;
    if FCantidad = 0 then
    begin
      FCantidad := 1;
      PonerFloat('CANTIDAD_DEVCLIN', FCantidad);
    end;
    if FDatos.CodigoSku <> '' then
      PonerFloat('TOTAL_UNIDADES_DEVCLIN', FCantidad);
  end;
  PonerFloat(
    'TOTAL_DEVCLIN',
    FCantidad * FDatos.UltimoCoste.PrecioUltCompra);
end;

procedure TAplicacionArticuloDevolucion.ActualizarInterfaz;
begin
  if FDatos.RequiereSku and (FDatos.CodigoSku = '') and
     ((FFormulario.FPivote = nil) or
      (not FFormulario.FPivote.Activo)) then
    EnfocarSku(True);
  FFormulario.RefrescarVisibilidadTallas;
  if FFormulario.FMostrarAtributos then
    FFormulario.CargarCaptionsAtributosLineaActiva;
  // El pivote horizontal necesita la línea materializada.
  if Assigned(FFormulario.FPivote) and
     FFormulario.FPivote.Activo and
     (FDataSet.State in dsEditModes) then
    FDataSet.Post;
end;

procedure TAplicacionArticuloDevolucion.AplicarDatos;
begin
  AplicarCamposArticulo;
  AplicarCantidades;
  if FDatos.RequiereSku and (FIdConjuntoPivot > 0) then
    FFormulario.PrepararColorPendienteArticuloDevolucion(
      FDatos.CodigoArticulo, FIdConjuntoPivot);
  ActualizarInterfaz;
end;

procedure TAplicacionArticuloDevolucion.Ejecutar;
begin
  if (FCodigoArticulo <> '') and
     Assigned(FFormulario.dmmDevolucionesCompra) and
     (not FFormulario.FAplicandoArticulo) then
  begin
    FFormulario.AsegurarCabeceraPersistidaParaLineas;
    FDataSet := FFormulario.dmmDevolucionesCompra.
      unqryDevolucionesCompraLineas;
    if Assigned(FDataSet) and FDataSet.Active then
    begin
      FFormulario.FAplicandoArticulo := True;
      try
        PrepararEdicion;
        ResolverArticulo;
        if FDatos.Encontrado then
          AplicarDatos
        else if FDatos.Mensaje <> '' then
          MessageDlg(FDatos.Mensaje, mtWarning, [mbOk], 0);
      finally
        FFormulario.FAplicandoArticulo := False;
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.AplicarArticuloDevolucion(
  const ACodigoArt: string);
var
  Aplicacion: TAplicacionArticuloDevolucion;
begin
  Aplicacion := TAplicacionArticuloDevolucion.Create(Self, ACodigoArt);
  try
    Aplicacion.Ejecutar;
  finally
    FreeAndNil(Aplicacion);
  end;
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloDevolucion;
  if sCodigo <> '' then
    AplicarArticuloDevolucion(sCodigo);
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_ARTPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
      AplicarArticuloDevolucion(sCodigo);
  end;
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaDevolucion;
  sSku := BuscarSkuDevolucion(sArt);
  if sSku <> '' then
    AplicarArticuloDevolucion(sSku);
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_UNIDADPropertiesValidate(
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
      AplicarArticuloDevolucion(sCodigo);
      if Assigned(dmmDevolucionesCompra) and
         dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Active and
         (dmmDevolucionesCompra.unqryDevolucionesCompraLineas.
            FindField('CODIGO_UNIDAD_DEVCLIN') <> nil) then
        DisplayValue := dmmDevolucionesCompra.unqryDevolucionesCompraLineas.
                          FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.AsegurarPrimeraLineaDevolucionCompra;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if not Assigned(dmmDevolucionesCompra) then
    Exit;
  dsCab := dmmDevolucionesCompra.unqryTablaG;
  dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
  if (dsCab = nil) or (dsLin = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    Exit;
  AsegurarCabeceraPersistidaParaLineas;
  sNumero := Trim(dsCab.FieldByName('NUMERO_DEVC').AsString);
  sSerie  := Trim(dsCab.FieldByName('SERIE_DEVC').AsString);
  if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
    Exit;
  if not dsLin.Active then
    dsLin.Open;
  if dsLin.IsEmpty and (not (dsLin.State in dsEditModes)) then
    dsLin.Append;
end;

procedure TfrmMtoDevolucionesCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasDevolucion.DataController.DataSet,
    'CODIGO_ART_DEVCLIN');
end;

procedure TfrmMtoDevolucionesCompra.actIrProveedorExecute(Sender: TObject);
begin
  if Assigned(dmmDevolucionesCompra) then
    ShowMtoCodigoDataSet(Self.Owner, 'Proveedores',
      dmmDevolucionesCompra.unqryTablaG, 'CODIGO_PRV_DEVC')
  else
    ShowMto(Self.Owner, 'Proveedores');
end;

procedure TfrmMtoDevolucionesCompra.btnCODIGO_EMP_DEVCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmDevolucionesCompra) then
  begin
    ds := dmmDevolucionesCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorDevolucionCompraElegirEmpresaNoSeleccionada,
                 mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
      ConexionPrincipal,
      'Búsqueda de empresas',
              'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP',
              'CODIGO_EMP_EMP',
              sCodigo,
              'frmMtoEmpFacSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_EMP_DEVC').AsString := sCodigo;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnCODIGO_EMP_DEVCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_DEVCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.cbbCODIGO_PRV_DEVCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmDevolucionesCompra) then
  begin
    ds := dmmDevolucionesCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorDevolucionCompraElegirProveedorNoSeleccionada,
                 mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
      ConexionPrincipal,
      'Búsqueda de proveedores',
              'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
              'CODIGO_PRV_PRV',
              sCodigo,
              'frmMtoDevcProvSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_PRV_DEVC').AsString := sCodigo;
      AplicarIvaExentoIntracomunitarioProveedor(ConexionPrincipal, ds,
        'CODIGO_PRV_DEVC', 'ESIVA_EXENTO_INTRACOMUNITARIO_DEVC');
      dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
      ActualizarLabelProveedor;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.cbbCODIGO_PRV_DEVCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_DEVCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Append;
end;

procedure TfrmMtoDevolucionesCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg(SPreguntaEliminarLineaDevolucionCompra,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if Assigned(FPivote) and FPivote.Activo then
      BorrarGrupoColorPivotActual
    else
    begin
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Delete;
      dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    end;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoDevolucionesCompra);
end.
