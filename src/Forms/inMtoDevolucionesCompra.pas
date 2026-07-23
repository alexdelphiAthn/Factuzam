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
  inMtoGen, dxSkinsCore, dxSkinBlue, dxSkinsForm,
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
  Vcl.ActnList, cxSplitter;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;

type
  TfrmMtoDevolucionesCompra = class(TfrmMtoGen)
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
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoDevolucionesCompra: TfrmMtoDevolucionesCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFiltroUsuario,
  inLibFotos,
  inLibLog,
  inLibArticulosResolver,
  inLibArticulosValidador,
  inLibGridCantidad,
  inLibAtributosPaleta,
  UniDataArticulos,
  inLibComprasImpuestos,
  inMtoModalImpDevCompra,
  inMtoModalImpDevCompraV,
  inMtoModalEtiqDev, inLibShowMto, inLibGenBusq, inLibtb,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku;

{$R *.dfm}

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
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
  end;
  CargarSeriesEmpresa(sEmpresa, 'DC', cbbSERIE_DEVC.Properties.Items);
  if cbbSERIE_DEVC.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de devoluciones a proveedor (tipo DC) ' +
                  'para la empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
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
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasDevolucion.DataController.DataSource) then
  begin
    ds := tvLineasDevolucion.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
  if ACodArt = '' then
  begin
    ACodArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
    ACodSku := ValorLineaActiva('CODIGO_UNIDAD_DEVCLIN');
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// devolucion, ademas de dsTablaG (cabecera) enganchamos
// dsDevolucionesCompraLineas.
function TfrmMtoDevolucionesCompra.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmDevolucionesCompra) then
    Result := [dsTablaG, dmmDevolucionesCompra.dsDevolucionesCompraLineas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoDevolucionesCompra.FormCreate(Sender: TObject);
var
  colSku: TcxGridDBColumn;
begin
  FColorPivotCodigos := TDictionary<string, string>.Create;
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := tvLineasDevolucion.CreateColumn;
  FColColorPivot.Name    := 'colLinDevcColorPivot';
  FColColorPivot.Caption := 'Color';
  FColColorPivot.Width   := 110;
  FColColorPivot.Visible := False;
  FColColorPivot.Options.Editing := True;
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
  colSku := tvLineasDevolucion.GetColumnByFieldName('CODIGO_UNIDAD_DEVCLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := colLineaDevcCODIGO_UNIDADPropertiesButtonClick;
      OnValidate := colLineaDevcCODIGO_UNIDADPropertiesValidate;
    end;
  end;
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
    Result := Trim(oEmpresa);
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
      qry.Connection := inLibGlobalVar.oConn;
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
              qry.Connection := inLibGlobalVar.oConn;
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
      bHayColor := ObtenerInfoBasico('CO', sCodigo, Info);
    if not bHayColor then
      bHayColor := ObtenerInfoBasico('CO', sTexto, Info);
    if not bHayColor then
      bHayColor := BuscarInfoBasicoEnArticulo(sTexto,
                                              ObtenerMapaAtributosGlobal,
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
      qry.Connection := inLibGlobalVar.oConn;
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
            qry.Connection := inLibGlobalVar.oConn;
            Screen.Cursor := crHourGlass;
            try
              if bPivotActivo then
                FPivote.Desactivar;
              if dsLin.Active then
                dsLin.Close;
              bTxOwned := not inLibGlobalVar.oConn.InTransaction;
              try
                if bTxOwned then
                  inLibGlobalVar.oConn.StartTransaction;
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
                if bTxOwned and inLibGlobalVar.oConn.InTransaction then
                  inLibGlobalVar.oConn.Commit;
              except
                if bTxOwned and inLibGlobalVar.oConn.InTransaction then
                  inLibGlobalVar.oConn.Rollback;
                raise;
              end;
              if not dsLin.Active then
                dsLin.Open;
              RefrescarTrasBorrado;
              if iFilas = 0 then
                MessageDlg('No se ha encontrado ninguna linea de ese color.',
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

procedure TfrmMtoDevolucionesCompra.AsegurarCabeceraPersistidaParaLineas;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;

  function ValorLinea(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := dsLin.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function LineaActualVacia: Boolean;
  begin
    Result := (ValorLinea('CODIGO_ART_DEVCLIN') = '') and
              (ValorLinea('CODIGO_UNIDAD_DEVCLIN') = '');
  end;

  procedure SincronizarCabeceraEnLinea;
  begin
    if Assigned(dsLin) and dsLin.Active and
       (dsLin.State in dsEditModes) then
    begin
      if dsLin.FindField('NUMERO_DEVC_DEVCLIN') <> nil then
        dsLin.FieldByName('NUMERO_DEVC_DEVCLIN').AsString :=
          dsCab.FieldByName('NUMERO_DEVC').AsString;
      if dsLin.FindField('SERIE_DEVC_DEVCLIN') <> nil then
        dsLin.FieldByName('SERIE_DEVC_DEVCLIN').AsString :=
          dsCab.FieldByName('SERIE_DEVC').AsString;
    end;
  end;

begin
  if not Assigned(dmmDevolucionesCompra) then
    Exit;
  dsCab := dmmDevolucionesCompra.unqryTablaG;
  dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
  if (dsCab = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    raise Exception.Create(
      'Crea o selecciona una devolucion antes de añadir lineas.');
  if (dsCab.FindField('CODIGO_ALM_DEVC') <> nil) and
     (Trim(dsCab.FieldByName('CODIGO_ALM_DEVC').AsString) = '') then
  begin
    pcCab.ActivePage := tsCabecera;
    if cbbCODIGO_ALM_DEVC.CanFocus then
      cbbCODIGO_ALM_DEVC.SetFocus;
    raise Exception.Create(
      'Debe seleccionar el almacen de salida de la devolucion.');
  end;
  sNumero := Trim(dsCab.FieldByName('NUMERO_DEVC').AsString);
  if Assigned(dsLin) and dsLin.Active and (dsLin.State = dsInsert) and
     ((sNumero = '') or (sNumero = '0')) and LineaActualVacia then
    dsLin.Cancel;
  if (dsCab.State in dsEditModes) or (sNumero = '') or (sNumero = '0') then
  begin
    if not (dsCab.State in dsEditModes) then
      dsCab.Edit;
    if (dsCab.FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil) and
       (Trim(dsCab.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString) = '') then
      dsCab.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString := 'N';
    dsCab.Post;
  end;
  SincronizarCabeceraEnLinea;
  if Assigned(dsLin) and dsLin.Active and (not (dsLin.State in dsEditModes)) then
  begin
    dsLin.Close;
    dsLin.Open;
  end;
end;

function TfrmMtoDevolucionesCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
var
  dsCab      : TDataSet;
  dsLin      : TDataSet;
  q          : TUniQuery;
  incidencias: TStringList;
  sSerie     : string;
  sNumero    : string;

  function ValorLinea(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := dsLin.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function LineaActualTieneArticulo: Boolean;
  begin
    Result := (ValorLinea('CODIGO_ART_DEVCLIN') <> '') or
              (ValorLinea('CODIGO_UNIDAD_DEVCLIN') <> '');
  end;

  function LineaActualTieneSistemaTallas: Boolean;
  var
    Campo: TField;
  begin
    Result := False;
    Campo := dsLin.FindField('ID_AC_PIVOT_DEVCLIN');
    if Campo <> nil then
      Result := (not Campo.IsNull) and (Campo.AsInteger > 0);
  end;

begin
  Result := False;
  AMensaje := '';
  if (dmmDevolucionesCompra = nil) or (FPivote = nil) then
    Result := True
  else
  begin
    dsCab := dmmDevolucionesCompra.unqryTablaG;
    dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (dsCab = nil) or (not dsCab.Active) or dsCab.IsEmpty then
      AMensaje := 'Crea o selecciona una devolucion antes de activar tallas.'
    else if Assigned(dsLin) and dsLin.Active and
            (dsLin.State in dsEditModes) then
    begin
      if LineaActualTieneArticulo and
         (not LineaActualTieneSistemaTallas) then
        AMensaje :=
          'El articulo en curso no tiene sistema de tallas asignado.'
      else if LineaActualTieneArticulo then
      begin
        AsegurarCabeceraPersistidaParaLineas;
        if dsLin.State in dsEditModes then
          dsLin.Post;
      end
      else if dsCab.State = dsInsert then
        AMensaje :=
          'En alta, selecciona primero un articulo con sistema de tallas.';
    end
    else if dsCab.State = dsInsert then
      AMensaje :=
        'En alta, selecciona primero un articulo con sistema de tallas.';
    if AMensaje = '' then
    begin
      sNumero := Trim(dsCab.FieldByName('NUMERO_DEVC').AsString);
      if (sNumero = '') or (sNumero = '0') then
        AsegurarCabeceraPersistidaParaLineas;
      sSerie := Trim(dsCab.FieldByName('SERIE_DEVC').AsString);
      sNumero := Trim(dsCab.FieldByName('NUMERO_DEVC').AsString);
      incidencias := TStringList.Create;
      q := TUniQuery.Create(nil);
      try
        q.Connection := dmmDevolucionesCompra.unqryTablaG.Connection;
        q.SQL.Text :=
          'SELECT DISTINCT L.CODIGO_ART_DEVCLIN AS ART ' +
          '  FROM fza_devoluciones_compra_lineas L ' +
          ' WHERE L.SERIE_DEVC_DEVCLIN = :serie ' +
          '   AND L.NUMERO_DEVC_DEVCLIN = :numero ' +
          '   AND COALESCE(TRIM(L.CODIGO_ART_DEVCLIN), '''') <> '''' ' +
          '   AND (L.ID_AC_PIVOT_DEVCLIN IS NULL ' +
          '        OR L.ID_AC_PIVOT_DEVCLIN = 0) ' +
          ' ORDER BY ART';
        q.ParamByName('serie').AsString := sSerie;
        q.ParamByName('numero').AsString := sNumero;
        q.Open;
        while not q.Eof do
        begin
          incidencias.Add('- Articulo sin sistema de tallas: ' +
                          q.FieldByName('ART').AsString);
          q.Next;
        end;
        if incidencias.Count > 0 then
          AMensaje := 'No se puede activar tallas en horizontal:' +
                      sLineBreak + sLineBreak +
                      incidencias.Text + sLineBreak +
                      'Asigna un sistema de tallas o elimina la linea.'
        else
          Result := FPivote.ValidarPivotePosible(AMensaje);
      finally
        FreeAndNil(q);
        FreeAndNil(incidencias);
      end;
    end;
  end;
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

function TfrmMtoDevolucionesCompra.SqlRestriccionUsuario: string;
begin
  // Documentos de compra: empresa y almacén (no llevan caja)
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_DEVC', 'CODIGO_ALM_DEVC', '');
end;

procedure TfrmMtoDevolucionesCompra.CrearTablaPrincipal;
begin
  inherited;
  // El padre (TfrmMtoGen.CrearTablaPrincipal -> CrearDataModule) ya creo
  // la instancia del DM via RTTI desde fza_winforms y la dejo en
  // tdmDataModule, ademas de enganchar dsTablaG.DataSet a su unqryTablaG.
  // Tomamos esa misma instancia; antes haciamos TdmDevolucionesCompra.Create
  // en FormCreate y enlazabamos el grid de lineas a un segundo DM cuyo
  // unqryDevolucionesCompraLineas nunca recibia el .Open de
  // AbrirTablaPrincipalAsync. Fallback Create(Self) por si la BBDD no
  // tiene la entrada en fza_winforms (migracion no aplicada).
  dmmDevolucionesCompra := (tdmDataModule as TdmDevolucionesCompra);
  if not Assigned(dmmDevolucionesCompra) then
  begin
    dmmDevolucionesCompra := TdmDevolucionesCompra.Create(Self);
    dsTablaG.DataSet := dmmDevolucionesCompra.unqryTablaG;
    // Sin esta linea, TfrmMtoGen.AbrirTablaPrincipalAsync ve
    // tdmDataModule=nil y aborta -> la query principal nunca se abre y
    // el form se queda vacio. Solo pasa cuando fza_winforms NO tiene la
    // entrada de DevolucionesCompra (BBDD sin la migracion aplicada); con
    // la entrada presente, el padre rellena tdmDataModule antes de
    // entrar a CrearTablaPrincipal y este bloque no se ejecuta.
    tdmDataModule := dmmDevolucionesCompra;
  end;
  tvLineasDevolucion.DataController.DataSource :=
    dmmDevolucionesCompra.dsDevolucionesCompraLineas;
  tvMovimientosProveedor.DataController.DataSource :=
    dmmDevolucionesCompra.dsMovimientosProveedor;
  // MasterSource se enlaza en DataModuleCreate del DM, pero lo
  // re-aseguramos por idempotencia.
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.MasterSource := dsTablaG;
  dmmDevolucionesCompra.unqryMovimientosProveedor.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_DEVC;NUMERO_DEVC';
end;

procedure TfrmMtoDevolucionesCompra.FormDestroy(Sender: TObject);
begin
  // El modo del contrato se libera ANTES del inherited: su teardown
  // toca el view y el dataset de lineas, que deben seguir vivos (misma
  // leccion que pedidos/facturas de venta, AV al cerrar 08/07/26).
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      // Teardown defensivo en cierre.
    end;
    FModoEntrada := nil;
  end;
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  FreeAndNil(FColorPivotCodigos);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoDevolucionesCompra.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineasDevolucion.CreateColumn;
    col.Name    := 'dbcLinDevcTalla' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 50;
    col.Tag     := i + 1;
    col.Visible := False;
    col.DataBinding.ValueTypeClass := TcxFloatValueType;
    col.PropertiesClass := TcxCurrencyEditProperties;
    curProps := TcxCurrencyEditProperties(col.Properties);
    curProps.DisplayFormat := '#,##0';
    FTallaColumns[i] := col;
  end;
end;

// Crea CANT_ATRIB_MAX columnas no-bound para mostrar los valores de
// los atributos del SKU de cada linea (modo "atributo por columna",
// estilo inventarios). Read-only y no persistentes: solo
// visualizacion. La carga real de valores por SKU queda como TODO.
procedure TfrmMtoDevolucionesCompra.CrearColumnasAtributos;
var
  i: Integer;
  col: TcxGridDBColumn;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
  begin
    col := tvLineasDevolucion.CreateColumn;
    col.Name    := 'dbcLinDevcAtrib' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 90;
    col.Tag     := -(i + 1);  // tag negativo para no chocar con tallas
    col.Visible := False;
    col.Options.Editing := False;
    FAtribColumns[i] := col;
  end;
end;

procedure TfrmMtoDevolucionesCompra.InicializarGestorYPivote;
var
  cfgT : TGridTallasConfig;
  cfgP : TGridPivoteCompraConfig;
  i    : Integer;
  arr  : TArray<TcxGridDBColumn>;
begin
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if FPivote       <> nil then FreeAndNil(FPivote);
  if dmmDevolucionesCompra = nil then Exit;
  SetLength(arr, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arr[i] := FTallaColumns[i];
  // 1. Gestor inline de tallas (libreria existente). Mismo patron que
  //    Sesiones, con los nombres DEVC/DEVCLIN/DEVCCEL.
  cfgT := Default(TGridTallasConfig);
  cfgT.Conexion           := dmmDevolucionesCompra.unqryTablaG.Connection;
  cfgT.Usuario            := oUser;
  cfgT.Grid               := tvLineasDevolucion;
  cfgT.SourceMaster       := dsTablaG;
  cfgT.SourceLineas       := dmmDevolucionesCompra.dsDevolucionesCompraLineas;
  cfgT.ColumnasTallas     := arr;
  cfgT.FieldSerieMaster   := 'SERIE_DEVC';
  cfgT.FieldNumeroMaster  := 'NUMERO_DEVC';
  cfgT.FieldLinea         := 'LINEA_DEVCLIN';
  cfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_DEVCLIN';
  cfgT.FieldPrecioBase    := 'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN';
  cfgT.FieldTotalUds      := 'TOTAL_UNIDADES_DEVCLIN';
  cfgT.FieldTotalLinea    := 'TOTAL_DEVCLIN';
  cfgT.TablaCeldas        := 'fza_devoluciones_compra_celdas';
  cfgT.FieldSerieCel      := 'SERIE_DEVC_DEVCCEL';
  cfgT.FieldNumeroCel     := 'NUMERO_DEVC_DEVCCEL';
  cfgT.FieldLineaCel      := 'LINEA_DEVC_DEVCCEL';
  cfgT.FieldFilaCel       := 'ID_FILA_DEVC_DEVCCEL';
  cfgT.FieldAvPivotCel    := 'ID_AV_PIVOT_DEVCCEL';
  cfgT.FieldCantidadCel   := 'CANTIDAD_DEVCCEL';
  cfgT.FieldAlmacenCel    := 'CODIGO_ALM_DEVCCEL';
  cfgT.IdFilaFijo         := 1;
  cfgT.MaxColumnas        := CANT_TALLAS_MAX;
  FGestorTallas := TGestorGridTallas.Create(cfgT);
  // Hookea cada columna talla: en pivote actualiza la linea SKU real;
  // fuera de pivote persiste la celda inline.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
    begin
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnEditValueChanged := TallaEditValueChangedHook;
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnValidate := TallaValidateHook;
    end;
  // 2. Orquestador de pivote (libreria nueva, compartida con pedidos).
  cfgP := Default(TGridPivoteCompraConfig);
  cfgP.Conexion             := dmmDevolucionesCompra.unqryTablaG.Connection;
  cfgP.Grid                 := tvLineasDevolucion;
  cfgP.SourceMaster         := dsTablaG;
  cfgP.SourceLineas         := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
  cfgP.Gestor               := FGestorTallas;
  cfgP.ColColorPivot        := FColColorPivot;
  cfgP.ColumnasTallas       := arr;
  cfgP.MaxColumnasTallas    := CANT_TALLAS_MAX;
  cfgP.TablaLineas          := 'fza_devoluciones_compra_lineas';
  cfgP.FieldSerieMaster     := 'SERIE_DEVC';
  cfgP.FieldNumeroMaster    := 'NUMERO_DEVC';
  cfgP.FieldSerieLin        := 'SERIE_DEVC_DEVCLIN';
  cfgP.FieldNumeroLin       := 'NUMERO_DEVC_DEVCLIN';
  cfgP.FieldLinea           := 'LINEA_DEVCLIN';
  cfgP.FieldArt             := 'CODIGO_ART_DEVCLIN';
  cfgP.FieldSku             := 'CODIGO_UNIDAD_DEVCLIN';
  cfgP.FieldCantidad        := 'CANTIDAD_DEVCLIN';
  cfgP.FieldPrecioBase      := 'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN';
  cfgP.FieldTotalUds        := 'TOTAL_UNIDADES_DEVCLIN';
  cfgP.FieldTotalLinea      := 'TOTAL_DEVCLIN';
  cfgP.FieldIdAcPivot       := 'ID_AC_PIVOT_DEVCLIN';
  cfgP.FieldAlmacen         := 'CODIGO_ALMACEN_DEVCLIN';
  cfgP.FieldAlmacenMaster   := 'CODIGO_ALM_DEVC';
  cfgP.CamposOcultosEnPivote := TArray<string>.Create(
    'CODIGO_UNIDAD_DEVCLIN',
    'CANTIDAD_DEVCLIN',
    'TOTAL_DEVCLIN');
  FPivote := TGridPivoteCompra.Create(cfgP);
end;

procedure TfrmMtoDevolucionesCompra.RefrescarVisibilidadTallas;
var
  i: Integer;
begin
  // Sin pivote activo: ocultar todas las columnas talla. Con pivote
  // activo: delega en el gestor para mostrar solo las que aplican y
  // pintar captions. La carga de cantidades del pivote la hace el
  // controlador (no usamos FGestorTallas.CargarCantidadesTodasLineas
  // porque en compras la cantidad por SKU vive en la linea, no en
  // una tabla de celdas como en sesiones).
  if (FPivote = nil) or (not FPivote.Activo) or (FGestorTallas = nil) then
  begin
    for i := 0 to CANT_TALLAS_MAX - 1 do
      if FTallaColumns[i] <> nil then
        FTallaColumns[i].Visible := False;
    Exit;
  end;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.ActualizarCaptionsLineaActiva;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarVisibilidadAtributos;
var
  i: Integer;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Visible := FMostrarAtributos;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributos del articulo de la linea con foco y
// los aplica como captions de las columnas ATTRn. La carga de los
// VALORES por SKU se hara en un hito posterior (cuando este el flujo
// completo de edicion de SKU por talla / color).
procedure TfrmMtoDevolucionesCompra.CargarCaptionsAtributosLineaActiva;
var
  i: Integer;
  sArt: string;
  qry: TUniQuery;
  iCol: Integer;
begin
  if dmmDevolucionesCompra = nil then Exit;
  qry := dmmDevolucionesCompra.unqryDefArticuloDevc;
  if qry = nil then Exit;

  // Reset de captions a placeholder.
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Caption := 'Atributo ' + IntToStr(i + 1);

  if (dmmDevolucionesCompra.unqryDevolucionesCompraLineas = nil) or
     (not dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Active) or
     (dmmDevolucionesCompra.unqryDevolucionesCompraLineas.IsEmpty) then Exit;
  sArt := dmmDevolucionesCompra.unqryDevolucionesCompraLineas.
            FieldByName('CODIGO_ART_DEVCLIN').AsString;
  if sArt = '' then Exit;

  qry.Close;
  qry.ParamByName('ARTICULO').AsString := sArt;
  qry.Open;
  iCol := 0;
  while (not qry.Eof) and (iCol < CANT_ATRIB_MAX) do
  begin
    if FAtribColumns[iCol] <> nil then
      FAtribColumns[iCol].Caption :=
        qry.FieldByName('NOMBRE_ATRIBUTO').AsString;
    Inc(iCol);
    qry.Next;
  end;
  qry.Close;
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
  // Persiste el modo en la cabecera para que la proxima apertura del
  // devolucion arranque ya en el modo elegido.
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty or
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_DEVC') = nil) then
    Exit;
  if not (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
    dsTablaG.DataSet.Edit;
  dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString :=
    IfThen(FPivote.Activo, 'S', 'N');
  dsTablaG.DataSet.Post;
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
    ShowMessage('No hay devolucion de compra activo que imprimir.');
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
    ShowMessage('No hay devolucion de compra activo que imprimir.');
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
    ShowMessage('No hay devolucion de compra activo.');
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

procedure TfrmMtoDevolucionesCompra.DevolverTodoStock;
var
  dsCab       : TDataSet;
  dsLin       : TDataSet;
  qAux        : TUniQuery;
  sSerie      : string;
  sNumero     : string;
  sLinea      : string;
  sArt        : string;
  sPrv        : string;
  sAlm        : string;
  rIvaN       : Double;
  rIvaR       : Double;
  rIvaS       : Double;
  rIvaE       : Double;
  iLineas     : Integer;
  iLineaBase  : Integer;
  iColorAv    : Integer;
  iStock       : Integer;
  bTxOwned    : Boolean;
  bPivotActivo: Boolean;

  function CampoCabeceraString(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := dsCab.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function CampoCabeceraFloat(const ACampo: string): Double;
  var
    Campo: TField;
  begin
    Result := 0;
    Campo := dsCab.FindField(ACampo);
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsFloat;
  end;

  function LineaBaseDocumento: Integer;
  begin
    Result := 0;
    qAux.Close;
    qAux.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(NULLIF(LINEA_DEVCLIN, '''') ' +
      '       AS UNSIGNED)), 0) AS LINEA_BASE ' +
      '  FROM fza_devoluciones_compra_lineas ' +
      ' WHERE SERIE_DEVC_DEVCLIN = :serie ' +
      '   AND NUMERO_DEVC_DEVCLIN = :numero';
    qAux.ParamByName('serie').AsString := sSerie;
    qAux.ParamByName('numero').AsString := sNumero;
    qAux.Open;
    if not qAux.IsEmpty then
      Result := qAux.FieldByName('LINEA_BASE').AsInteger;
    qAux.Close;
  end;

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

  procedure ParametrosGrupo;
  begin
    qAux.ParamByName('serie').AsString := sSerie;
    qAux.ParamByName('numero').AsString := sNumero;
    qAux.ParamByName('art').AsString := sArt;
    if iColorAv > 0 then
      qAux.ParamByName('color_av').AsInteger := iColorAv;
  end;

  procedure BorrarGrupoFilaActual;
  begin
    qAux.Close;
    qAux.SQL.Text :=
      'DELETE C ' +
      '  FROM fza_devoluciones_compra_celdas C ' +
      '  JOIN fza_devoluciones_compra_lineas L ' +
      '    ON C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
      '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
      '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
      '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
      SQLJoinColorLinea +
      SQLCondicionGrupo;
    ParametrosGrupo;
    qAux.ExecSQL;
    qAux.Close;
    qAux.SQL.Text :=
      'DELETE L ' +
      '  FROM fza_devoluciones_compra_lineas L ' +
      SQLJoinColorLinea +
      SQLCondicionGrupo;
    ParametrosGrupo;
    qAux.ExecSQL;
  end;

  function SQLStockDisponibleFila: string;
  begin
    Result :=
      'SELECT COALESCE(SK.CODIGO_ART_SKU, ' +
      '                STK.CODIGO_UNIDAD_STK) AS ART, ' +
      '       STK.CODIGO_UNIDAD_STK AS SKU_STOCK, ' +
      '       SUM(COALESCE(STK.CANTIDAD_STK, 0)) AS CANTIDAD, ' +
      '       LEFT(MAX(COALESCE(AP.REF_PROVEEDOR_AP, '''')), 100) AS REF_PRV, ' +
      '       MAX(COALESCE(ACA.ID_AC, 0)) AS ID_AC, ' +
      '       LEFT(MAX(COALESCE(ART.CODIGO_FAM_ART, '''')), 20) AS CODIGO_FAM, ' +
      '       LEFT(MAX(COALESCE(NULLIF(FAM.DESCRIPCION_FAM, ''''), ' +
      '                         FAM.NOMBRE_FAM_FAM, ' +
      '                         ART.CODIGO_FAM_ART, '''')), 200) AS NOMBRE_FAM, ' +
      '       LEFT(MAX(COALESCE(ART.DESCRIPCION_ART, '''')), 100) AS DESCRIPCION_ART, ' +
      '       LEFT(MAX(COALESCE(ART.TIPO_CANTIDAD_ART, ''Uds'')), 20) AS TIPO_CANTIDAD_ART, ' +
      '       MAX(CASE WHEN UPPER(COALESCE(ART.TIPO_IVA_ART, ''N'')) ' +
      '                    IN (''N'', ''R'', ''S'', ''E'') ' +
      '                THEN UPPER(ART.TIPO_IVA_ART) ' +
      '                ELSE ''N'' END) AS TIPO_IVA_ART, ' +
      '       MAX(COALESCE(SKUC.PRECIO_ULT_COMPRA_SKUC, ' +
      '                    AP.PRECIO_ULT_COMPRA_AP, 0)) AS PRECIO_COMPRA, ' +
      '       MIN(COALESCE(ART.ORDEN_ART, 999999)) AS ORDEN_ART ' +
      '  FROM fza_articulos_stockactual STK ' +
      '  LEFT JOIN fza_articulos_skus SK ' +
      '    ON SK.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK ' +
      '  JOIN fza_articulos ART ' +
      '    ON ART.CODIGO_ART_ART = COALESCE(SK.CODIGO_ART_SKU, ' +
      '                                     STK.CODIGO_UNIDAD_STK) ' +
      '  JOIN fza_articulos_proveedores AP ' +
      '    ON AP.CODIGO_ART_AP = ART.CODIGO_ART_ART ' +
      '   AND AP.CODIGO_PRV_AP = :prv ' +
      '  LEFT JOIN fza_articulos_skus_costes SKUC ' +
      '    ON SKUC.CODIGO_UNIDAD_SKU_SKUC = STK.CODIGO_UNIDAD_STK ' +
      '  LEFT JOIN fza_atributos_sku CO ' +
      '    ON CO.CODIGO_UNIDAD_SKU_SA = STK.CODIGO_UNIDAD_STK ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVC0 ' +
      '                WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
      '                  AND AVC0.ID_VA_AV = ''CO'') ' +
      '  LEFT JOIN fza_atributos_valores AVC ' +
      '    ON AVC.ID_AV = CO.ID_AV_SA ' +
      '   AND AVC.ID_VA_AV = ''CO'' ' +
      '  LEFT JOIN fza_articulos_familias FAM ' +
      '    ON FAM.CODIGO_FAM_FAM = ART.CODIGO_FAM_ART ' +
      '  LEFT JOIN ( ' +
      '        SELECT CODIGO_ART_ACA, MIN(ID_AC_ACA) AS ID_AC ' +
      '          FROM fza_articulos_conjuntos_asign ' +
      '         WHERE ID_VA_ACA <> ''CO'' ' +
      '         GROUP BY CODIGO_ART_ACA ' +
      '       ) ACA ' +
      '    ON ACA.CODIGO_ART_ACA = ART.CODIGO_ART_ART ' +
      ' WHERE STK.CODIGO_ALM_STK = :alm ' +
      '   AND COALESCE(SK.CODIGO_ART_SKU, ' +
      '                STK.CODIGO_UNIDAD_STK) = :art ' +
      '   AND COALESCE(ART.ESACTIVO_ART, ''S'') = ''S'' ' +
      '   AND (SK.CODIGO_UNIDAD_SKU IS NULL ' +
      '        OR COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'') ' +
      '   AND ((:color_av > 0 AND COALESCE(AVC.ID_AV, 0) = :color_av) ' +
      '        OR (:color_av = 0 AND COALESCE(AVC.ID_AV, 0) = 0)) ' +
      ' GROUP BY COALESCE(SK.CODIGO_ART_SKU, STK.CODIGO_UNIDAD_STK), ' +
      '          STK.CODIGO_UNIDAD_STK ' +
      'HAVING SUM(COALESCE(STK.CANTIDAD_STK, 0)) > 0';
  end;

  procedure ParametrosStock;
  begin
    qAux.ParamByName('prv').AsString := sPrv;
    qAux.ParamByName('alm').AsString := sAlm;
    qAux.ParamByName('art').AsString := sArt;
    qAux.ParamByName('color_av').AsInteger := iColorAv;
  end;

  function ArticuloTieneColores: Boolean;
  begin
    Result := False;
    qAux.Close;
    qAux.SQL.Text :=
      'SELECT 1 ' +
      '  FROM fza_articulos_skus SK ' +
      '  JOIN fza_atributos_sku SA ' +
      '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
      '  JOIN fza_atributos_valores AV ' +
      '    ON AV.ID_AV = SA.ID_AV_SA ' +
      '   AND AV.ID_VA_AV = ''CO'' ' +
      ' WHERE SK.CODIGO_ART_SKU = :art ' +
      ' LIMIT 1';
    qAux.ParamByName('art').AsString := sArt;
    qAux.Open;
    Result := not qAux.IsEmpty;
    qAux.Close;
  end;

  function ContarStockDisponible: Integer;
  begin
    Result := 0;
    qAux.Close;
    qAux.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM (' + SQLStockDisponibleFila + ') X';
    ParametrosStock;
    qAux.Open;
    if not qAux.IsEmpty then
      Result := qAux.FieldByName('N').AsInteger;
    qAux.Close;
  end;

  procedure InsertarLineasStockFila;
  begin
    qAux.Close;
    qAux.SQL.Text :=
      'INSERT INTO fza_devoluciones_compra_lineas ( ' +
      '  NUMERO_DEVC_DEVCLIN, SERIE_DEVC_DEVCLIN, LINEA_DEVCLIN, ' +
      '  CODIGO_ART_DEVCLIN, CODIGO_UNIDAD_DEVCLIN, REF_PRV_DEVCLIN, ' +
      '  ID_AC_PIVOT_DEVCLIN, CODIGO_FAM_DEVCLIN, NOMBRE_FAM_DEVCLIN, ' +
      '  DESCRIPCION_ARTICULO_DEVCLIN, TIPO_CANTIDAD_ARTICULO_DEVCLIN, ' +
      '  CANTIDAD_DEVCLIN, TOTAL_UNIDADES_DEVCLIN, ' +
      '  TIPO_IVA_ARTICULO_DEVCLIN, PORCENTAJE_IVA_DEVCLIN, ' +
      '  PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN, ' +
      '  PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN, TOTAL_DEVCLIN, ' +
      '  CODIGO_ALMACEN_DEVCLIN, ESFACTURADA_DEVCLIN, ' +
      '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :numero, :serie, ' +
      '       LPAD(:linea_base + (ROW_NUMBER() OVER (ORDER BY ' +
      '                                Y.ORDEN_ART, Y.ART, Y.SKU_STOCK) ' +
      '                                * 10), 4, ''0''), ' +
      '       Y.ART, Y.SKU_STOCK, Y.REF_PRV, NULLIF(Y.ID_AC, 0), ' +
      '       Y.CODIGO_FAM, Y.NOMBRE_FAM, Y.DESCRIPCION_ART, ' +
      '       Y.TIPO_CANTIDAD_ART, Y.CANTIDAD, Y.CANTIDAD, ' +
      '       Y.TIPO_IVA_ART, Y.PORCENTAJE_IVA, Y.PRECIO_COMPRA, ' +
      '       Y.PRECIO_COMPRA * (1 + Y.PORCENTAJE_IVA / 100), ' +
      '       Y.CANTIDAD * Y.PRECIO_COMPRA, :almacen_linea, ''N'', ' +
      '       NOW(), NOW(), :usuario_alta, :usuario_modif ' +
      '  FROM ( ' +
      '        SELECT X.*, ' +
      '               CASE X.TIPO_IVA_ART ' +
      '                 WHEN ''R'' THEN :iva_r ' +
      '                 WHEN ''S'' THEN :iva_s ' +
      '                 WHEN ''E'' THEN :iva_e ' +
      '                 ELSE :iva_n END AS PORCENTAJE_IVA ' +
      '          FROM (' + SQLStockDisponibleFila + ') X ' +
      '       ) Y ' +
      ' ORDER BY Y.ORDEN_ART, Y.ART, Y.SKU_STOCK';
    qAux.ParamByName('serie').AsString := sSerie;
    qAux.ParamByName('numero').AsString := sNumero;
    qAux.ParamByName('linea_base').AsInteger := iLineaBase;
    qAux.ParamByName('almacen_linea').AsString := sAlm;
    qAux.ParamByName('usuario_alta').AsString := inLibGlobalVar.oUser;
    qAux.ParamByName('usuario_modif').AsString := inLibGlobalVar.oUser;
    qAux.ParamByName('iva_n').AsFloat := rIvaN;
    qAux.ParamByName('iva_r').AsFloat := rIvaR;
    qAux.ParamByName('iva_s').AsFloat := rIvaS;
    qAux.ParamByName('iva_e').AsFloat := rIvaE;
    ParametrosStock;
    qAux.ExecSQL;
    iLineas := qAux.RowsAffected;
  end;

begin
  if dmmDevolucionesCompra <> nil then
  begin
    dsCab := dmmDevolucionesCompra.unqryTablaG;
    dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (dsCab <> nil) and dsCab.Active and (not dsCab.IsEmpty) and
       (dsLin <> nil) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sSerie := CampoCabeceraString('SERIE_DEVC');
      sNumero := CampoCabeceraString('NUMERO_DEVC');
      sPrv := CampoCabeceraString('CODIGO_PRV_DEVC');
      sAlm := CampoCabeceraString('CODIGO_ALM_DEVC');
      bPivotActivo := Assigned(FPivote) and FPivote.Activo;
      if dsLin.Active and (dsLin.State in dsEditModes) then
        dsLin.Post;
      sLinea := ValorLineaActiva('LINEA_DEVCLIN');
      sArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
      ObtenerColorPivotLineaActual(sSerie, sNumero, sLinea, iColorAv);
      rIvaN := CampoCabeceraFloat('PORCENTAJE_IVAN_DEVC');
      rIvaR := CampoCabeceraFloat('PORCENTAJE_IVAR_DEVC');
      rIvaS := CampoCabeceraFloat('PORCENTAJE_IVAS_DEVC');
      rIvaE := CampoCabeceraFloat('PORCENTAJE_IVAE_DEVC');
      if (sPrv = '') or (sPrv = '0') then
        MessageDlg('Selecciona un proveedor antes de devolver la fila.',
                   mtWarning, [mbOk], 0)
      else if sAlm = '' then
        MessageDlg('Selecciona el almacen de salida antes de devolver el ' +
                   'stock.', mtWarning, [mbOk], 0)
      else if sLinea = '' then
        MessageDlg('Selecciona una fila antes de devolver su stock.',
                   mtInformation, [mbOk], 0)
      else if sArt = '' then
        MessageDlg('Selecciona un articulo en la fila antes de devolver ' +
                   'su stock.', mtInformation, [mbOk], 0)
      else
      begin
        qAux := TUniQuery.Create(nil);
        try
          qAux.Connection := inLibGlobalVar.oConn;
          if (iColorAv = 0) and ArticuloTieneColores then
            MessageDlg('Selecciona el color de la fila antes de devolver ' +
                       'su stock.', mtInformation, [mbOk], 0)
          else
          begin
            iStock := ContarStockDisponible;
            if iStock = 0 then
              MessageDlg('No hay stock positivo para el articulo/color de ' +
                         'la fila en el almacen de salida.',
                         mtInformation, [mbOk], 0)
            else if MessageDlg('Esto sustituira las cantidades de la fila ' +
                      'actual por el stock positivo de ese articulo/color ' +
                      'en el almacen de salida. Continuar?',
                      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
            begin
              Screen.Cursor := crHourGlass;
              try
                if bPivotActivo then
                  FPivote.Desactivar;
                if dsLin.Active then
                  dsLin.Close;
                bTxOwned := not inLibGlobalVar.oConn.InTransaction;
                try
                  if bTxOwned then
                    inLibGlobalVar.oConn.StartTransaction;
                  BorrarGrupoFilaActual;
                  iLineaBase := LineaBaseDocumento;
                  InsertarLineasStockFila;
                  if bTxOwned and inLibGlobalVar.oConn.InTransaction then
                    inLibGlobalVar.oConn.Commit;
                except
                  if bTxOwned and inLibGlobalVar.oConn.InTransaction then
                    inLibGlobalVar.oConn.Rollback;
                  raise;
                end;
                if not dsLin.Active then
                  dsLin.Open;
                dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
                if dsCab.State in dsEditModes then
                  dsCab.Post;
                RestaurarPivoteHorizontalTrasOperacion(bPivotActivo);
                MessageDlg(Format('Se han preparado %d lineas de la fila ' +
                                  'con el stock actual.', [iLineas]),
                           mtInformation, [mbOk], 0);
                finally
                  Screen.Cursor := crDefault;
                  if (dsLin <> nil) and (not dsLin.Active) then
                    dsLin.Open;
                end;
            end;
          end;
        finally
          Screen.Cursor := crDefault;
          if Assigned(qAux) then
            FreeAndNil(qAux);
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
    raise Exception.Create(
      'Debe seleccionar el almacen de salida de la devolucion.');
  end;
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    dmmDevolucionesCompra.unqryTablaG.Connection,
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas, 'DEVCLIN');
  if (sLineasSinSku <> '') and
     (MessageDlg('Las líneas ' + sLineasSinSku + ' tienen artículos ' +
                 'con variaciones sin SKU asignado. ' +
                 '¿Grabar de todas formas?',
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

// Hook del OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field=nil) que dispara cxGrid al cambiar de record activo. Sincroniza
// el toggle con la preferencia guardada en la cabecera y dispara la
// recarga del controlador de pivote.
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
  if Field <> nil then
    Exit;
  // Contrato de entrada: al navegar de devolucion, las lineas llegan
  // recargadas por el master-detail. En desglose basta desempaquetar
  // SKU->ATTR; el modo tallas re-pivota su cache reconstruyendo. La
  // preferencia ESPIVOTE del pivote de compras antiguo se IGNORA
  // (pivote retirado de esta pantalla).
  if Assigned(dmmDevolucionesCompra) and
     dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Active and
     (not (dsTablaG.State in dsEditModes)) then
  begin
    // Sin modo construido (llegar navegando sin pisar el grid) se
    // veian las columnas del dfm: construir tambien en ese caso.
    if (not FColsModoConstruido) or
       (FModoEntradaSel = mcsTallasHorPed) then
      ConstruirModoEntrada
    else if FModoEntradaSel = mcsAuto then
      dmmDevolucionesCompra.DesempaquetarAtributosLineas;
  end;
end;

procedure TfrmMtoDevolucionesCompra.ActualizarLabelProveedor;
var
  sCodigo : string;
  sNombre : string;
  sRazon  : string;
begin
  // Resuelve NOMBRE_PRV + RAZON_SOCIAL_PRV (via el lookup unqryPrvDataDevc)
  // y los pinta en el rotulo. Se antepone el nombre comercial: es el que
  // el usuario reconoce a simple vista; la razon social solo se anade
  // entre parentesis como referencia si difiere.
  sCodigo := '';
  if (dmmDevolucionesCompra <> nil) and
     Assigned(dmmDevolucionesCompra.unqryTablaG) and
     dmmDevolucionesCompra.unqryTablaG.Active and
     (not dmmDevolucionesCompra.unqryTablaG.IsEmpty) then
    sCodigo :=
      Trim(dmmDevolucionesCompra.unqryTablaG.FieldByName('CODIGO_PRV_DEVC').AsString);
  if sCodigo = '' then
    lblProveedorNombreDevc.Caption := ''
  else if (dmmDevolucionesCompra.unqryPrvDataDevc <> nil) and
          dmmDevolucionesCompra.unqryPrvDataDevc.Active and
          dmmDevolucionesCompra.unqryPrvDataDevc.Locate('CODIGO_PRV_PRV', sCodigo, []) then
  begin
    sRazon  := dmmDevolucionesCompra.unqryPrvDataDevc.FieldByName('RAZON_SOCIAL_PRV').AsString;
    sNombre := dmmDevolucionesCompra.unqryPrvDataDevc.FieldByName('NOMBRE_PRV').AsString;
    // Si no hay nombre comercial cargado, caemos a la razon social como
    // rotulo principal. Si hay nombre y difiere de la razon social, la
    // razon social se anade entre parentesis como referencia.
    if Trim(sNombre) = '' then
      lblProveedorNombreDevc.Caption := sCodigo + ' - ' + sRazon
    else if not SameText(Trim(sNombre), Trim(sRazon)) then
      lblProveedorNombreDevc.Caption :=
        sCodigo + ' - ' + sNombre + '  (' + sRazon + ')'
    else
      lblProveedorNombreDevc.Caption := sCodigo + ' - ' + sNombre;
  end
  else
    lblProveedorNombreDevc.Caption := sCodigo + ' - (proveedor no encontrado)';
end;

procedure TfrmMtoDevolucionesCompra.ActualizarLabelPrendas;
begin
  if (dmmDevolucionesCompra <> nil) and
     Assigned(dmmDevolucionesCompra.unqryTablaG) and
     dmmDevolucionesCompra.unqryTablaG.Active and
     (not dmmDevolucionesCompra.unqryTablaG.IsEmpty) then
    lblCabTotalPrendasValor.Caption :=
      FormatFloat('#,##0', dmmDevolucionesCompra.TotalPrendasDevolucion)
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
  if Assigned(FGestorTallas) and Assigned(FPivote) and FPivote.Activo then
    FGestorTallas.ActualizarCaptionsLineaActiva;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
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
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
  AsegurarPrimeraLineaDevolucionCompra;
  // Contrato de entrada: primera construccion al entrar en el grid.
  // El teardown cancela la linea vacia auto-anadida: se recrea.
  if not FColsModoConstruido then
  begin
    ConstruirModoEntrada;
    AsegurarPrimeraLineaDevolucionCompra;
  end;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoDevolucionesCompra.cxgrdLineasDevolucionExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoDevolucionesCompra.ActualizarCaptionModoLineas;
begin
  if not FColsModoConstruido then
    tsLineasDevolucion.Caption := '&1_Líneas '
  else
    case FModoEntradaSel of
      mcsSku:
        tsLineasDevolucion.Caption := '&1_Líneas [SKU]';
      mcsTallasHorPed:
        tsLineasDevolucion.Caption := '&1_Líneas [Tallas horiz.]';
    else
      tsLineasDevolucion.Caption := '&1_Líneas [Desglose]';
    end;
end;

procedure TfrmMtoDevolucionesCompra.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  // F1: alterna Auto (desglose) -> SKU -> Tallas horizontal con las
  // lineas de la devolucion a la vista, igual que albaranes de compra.
  if (Key = VK_F1) and (Shift = []) and
     (pcDevolucion.ActivePage = tsLineasDevolucion) and
     (dmmDevolucionesCompra <> nil) then
  begin
    Key := 0;
    case FModoEntradaSel of
      mcsAuto: FModoEntradaSel := mcsSku;
      mcsSku: FModoEntradaSel := mcsTallasHorPed;
    else
      FModoEntradaSel := mcsAuto;
    end;
    ConstruirModoEntrada;
  end;
  inherited;
end;

procedure TfrmMtoDevolucionesCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  i: Integer;
  ds: TDataSet;
  bDegradarASku: Boolean;
begin
  if (dmmDevolucionesCompra = nil) or (csDestroying in ComponentState) then
    Exit;
  ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
  if not ds.Active then
    Exit;
  // Teardown del modo anterior (patron albaranes de compra).
  if tvLineasDevolucion.Controller.EditingController.IsEditing then
    try
      tvLineasDevolucion.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        ;
    end;
  if ds.State in dsEditModes then
    ds.Cancel;
  if FModoEntrada <> nil then
    FModoEntrada.Desmontar;
  tvLineasDevolucion.OnInitEdit := nil;
  tvLineasDevolucion.OnEditKeyDown := nil;
  tvLineasDevolucion.OnEditing := nil;
  tvLineasDevolucion.OnFocusedRecordChanged := nil;
  tvLineasDevolucion.OnFocusedItemChanged := nil;
  tvLineasDevolucion.OnCustomDrawCell := nil;
  // El ClearItems mata TODAS las columnas: las del dfm y las del
  // pivote de compras retirado. Fuera las referencias ANTES de que
  // ningun repintado o refresco las toque.
  tvLineasDevolucion.ClearItems;
  FModoEntrada := nil;
  for i := 0 to CANT_TALLAS_MAX - 1 do
    FTallaColumns[i] := nil;
  for i := 0 to CANT_ATRIB_MAX - 1 do
    FAtribColumns[i] := nil;
  FColColorPivot := nil;
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _DEVCLIN; idempotente por linea). SKU y tallas
  // horizontal derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmDevolucionesCompra.DesempaquetarAtributosLineas;
  Cfg := Default(TConfigColumnasSku);
  Cfg.Conexion := dmmDevolucionesCompra.unqryTablaG.Connection;
  Cfg.View := tvLineasDevolucion;
  Cfg.Cds := ds;
  Cfg.Modo := FModoEntradaSel;
  Cfg.AlmacenStock := Trim(dmmDevolucionesCompra.unqryTablaG.
    FieldByName('CODIGO_ALM_DEVC').AsString);
  Cfg.Distribuido := False;
  Cfg.Campos.CodigoArt := 'CODIGO_ART_DEVCLIN';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD_DEVCLIN';
  Cfg.Campos.Descripcion := 'DESCRIPCION_ARTICULO_DEVCLIN';
  Cfg.Campos.Cantidad := 'CANTIDAD_DEVCLIN';
  Cfg.Campos.Almacen := 'CODIGO_ALMACEN_DEVCLIN';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_DEVCLIN';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] :=
      'ATTR' + IntToStr(i) + '_VALOR_DEVCLIN';
    Cfg.Campos.AttrNombre[i] :=
      'ATTR' + IntToStr(i) + '_NOMBRE_DEVCLIN';
  end;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := Default(TGridPivoteVentaConfig);
    CfgPV.Conexion := dmmDevolucionesCompra.unqryTablaG.Connection;
    CfgPV.Usuario := oUser;
    CfgPV.SourceMaster := dsTablaG;
    CfgPV.SourceLineas := dmmDevolucionesCompra.dsDevolucionesCompraLineas;
    CfgPV.FieldSerieMaster := 'SERIE_DEVC';
    CfgPV.FieldNumeroMaster := 'NUMERO_DEVC';
    CfgPV.FieldLinea := 'LINEA_DEVCLIN';
    CfgPV.FieldArt := 'CODIGO_ART_DEVCLIN';
    CfgPV.FieldSku := 'CODIGO_UNIDAD_DEVCLIN';
    CfgPV.FieldDescripcion := 'DESCRIPCION_ARTICULO_DEVCLIN';
    CfgPV.FieldTipoCantidad := 'TIPO_CANTIDAD_ARTICULO_DEVCLIN';
    // Devolucion de compra: UNA sola cantidad por linea -> banda unica.
    CfgPV.FieldCantidadPedida := 'CANTIDAD_DEVCLIN';
    CfgPV.FieldCantidadEntregada := '';
    CfgPV.FieldCantidadAAlbaranar := '';
    CfgPV.FieldPrecioBase := 'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN';
    CfgPV.FieldAlmacen := 'CODIGO_ALMACEN_DEVCLIN';
    CfgPV.FieldAlmacenMaster := 'CODIGO_ALM_DEVC';
    CfgPV.MaxColumnas := CANT_TALLAS_MAX;
    CfgPV.BandaUnica := True;
    // La columna Total del host pasa a UNIDADES del grupo en pivote.
    CfgPV.FieldTotalUdsGrupo := 'TOTAL_DEVCLIN';
    CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
    CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  FModoEntrada.OnResuelto := ModoEntradaResuelto;
  FModoEntrada.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FModoEntrada.OnSalirEdicion := RestaurarEnterAsTabTemporal;
  // El flag ANTES del Construir: si algo aborta a medias, nadie debe
  // tocar las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  bDegradarASku := False;
  try
    FModoEntrada.Construir;
  except
    // Fallo montando tallas horizontal (modo por defecto): degradar a
    // SKU. En cualquier otro modo la excepcion sigue su curso.
    on E: Exception do
      if FModoEntradaSel = mcsTallasHorPed then
      begin
        if inLibLog.Log <> nil then
          inLibLog.Log.LogError(
            'DevolucionesCompra: fallo construyendo tallas horizontal, ' +
            'se degrada a SKU: ' + E.Message);
        bDegradarASku := True;
      end
      else
        raise;
  end;
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
    case DetectarModoColumnasSku(Cfg) of
      mcsSku:
        tsLineasDevolucion.Caption := '&1_Líneas [SKU]';
      mcsTallasHorPed:
        tsLineasDevolucion.Caption := '&1_Líneas [Tallas horiz.]';
    else
      begin
        tsLineasDevolucion.Caption := '&1_Líneas [Desglose]';
        MostrarColumnasAtributoGlobalesDevc;
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.MostrarColumnasAtributoGlobalesDevc;
var
  Qry: TUniQuery;
  i, iOrden: Integer;
  Col: TcxGridColumn;
begin
  // Nombres globales de atributos para ver Color/Talla desde el
  // principio (mismo helper que pedidos/facturas de venta).
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := dmmDevolucionesCompra.unqryTablaG.Connection;
    Qry.SQL.Text :=
      'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE,' +
      '       MIN(ORDEN_VA) AS ORDEN' +
      '  FROM fza_variaciones_atributos' +
      ' GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA)' +
      ' ORDER BY ORDEN, NOMBRE LIMIT 5';
    Qry.Open;
    iOrden := 1;
    while (not Qry.Eof) and (iOrden <= 5) do
    begin
      // Solo las columnas del contrato (Tag positivo 1..5); las
      // FAtribColumns propias llevan Tag negativo y no chocan.
      for i := 0 to tvLineasDevolucion.ColumnCount - 1 do
      begin
        Col := tvLineasDevolucion.Columns[i];
        if Col.Tag = iOrden then
        begin
          Col.Caption := Qry.FieldByName('NOMBRE').AsString;
          Col.Visible := True;
        end;
      end;
      Inc(iOrden);
      Qry.Next;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TfrmMtoDevolucionesCompra.CrearColumnasHostDevolucionCompra;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineasDevolucion.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
var
  ColLinea, ColCantidad, ColTipoCantidad: TcxGridDBColumn;
begin
  // Columnas propias de la devolucion de compra tras el ClearItems del
  // contrato (las del modo — articulo/SKU/color/tallas — ya existen).
  ColLinea := Col('Línea', 'LINEA_DEVCLIN', 60, False);
  Col('Modelo prov.', 'REF_PRV_DEVCLIN', 130, True);
  Col('Descripción', 'DESCRIPCION_ARTICULO_DEVCLIN', 260, False);
  if FModoEntradaSel <> mcsTallasHorPed then
  begin
    ColCantidad := Col('Cantidad', 'CANTIDAD_DEVCLIN', 80, True);
    ColTipoCantidad := Col('', 'TIPO_CANTIDAD_ARTICULO_DEVCLIN',
                           90, False);
    VincularCantidadGrid(ColCantidad, ColTipoCantidad);
  end;
  Col('Precio compra', 'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN', 130, True);
  Col('% IVA', 'PORCENTAJE_IVA_DEVCLIN', 70, True);
  // En pivote la vista vuelca aqui las UNIDADES del grupo (la libreria
  // machaca TOTAL en la copia visual); en el resto de modos, importe.
  if FModoEntradaSel = mcsTallasHorPed then
    Col('Total uds.', 'TOTAL_DEVCLIN', 100, False)
  else
    Col('Total', 'TOTAL_DEVCLIN', 100, False);
  Col('Almacén', 'CODIGO_ALMACEN_DEVCLIN', 90, True);
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
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
  qry: TUniQuery;
  sPrv: string;

  function ProveedorCabecera: string;
  var
    ds   : TDataSet;
    Campo: TField;
  begin
    Result := '';
    ds := dsTablaG.DataSet;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) then
    begin
      Campo := ds.FindField('CODIGO_PRV_DEVC');
      if Campo <> nil then
        Result := Trim(Campo.AsString);
    end;
  end;

begin
  Result := '';
  sPrv := ProveedorCabecera;
  if (sPrv = '') or (sPrv = '0') then
  begin
    MessageDlg('Selecciona un proveedor antes de buscar articulos.',
               mtInformation, [mbOk], 0);
  end
  else
  begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := inLibGlobalVar.oConn;
    qry.SQL.Text :=
      'SELECT art.CODIGO_ART_ART, art.ESACTIVO_ART, art.ORDEN_ART, ' +
      '       art.DESCRIPCION_ART, art.CODIGO_FAM_ART, ' +
      '       fam.DESCRIPCION_FAM, art.TIPO_IVA_ART, ' +
      '       iva.NOMBRE_TIPO_IVA_IVATIP, art.TIPO_CANTIDAD_ART, ' +
      '       ap.CODIGO_PRV_AP, prv.RAZON_SOCIAL_PRV, prv.NOMBRE_PRV, ' +
      '       ap.REF_PROVEEDOR_AP AS REF_PROVEEDOR, ' +
      '       ap.PRECIO_ULT_COMPRA_AP, ap.FECHA_VALIDEZ_AP ' +
      '  FROM fza_articulos_proveedores ap ' +
      '  JOIN fza_articulos art ' +
      '    ON art.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
      '  LEFT JOIN fza_articulos_familias fam ' +
      '    ON fam.CODIGO_FAM_FAM = art.CODIGO_FAM_ART ' +
      '  LEFT JOIN fza_ivas_tipos iva ' +
      '    ON iva.CODIGO_ABREVIATURA_IVA_IVATIP = art.TIPO_IVA_ART ' +
      '  LEFT JOIN fza_proveedores prv ' +
      '    ON prv.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
      ' WHERE ap.CODIGO_PRV_AP = :prv ' +
      '   AND COALESCE(art.ESACTIVO_ART, ''S'') = ''S'' ' +
      ' ORDER BY art.ORDEN_ART, art.CODIGO_ART_ART';
    qry.ParamByName('prv').AsString := sPrv;
    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de artículos', qry,
         'frmMtoDevcArtSearch', Self) and
       (qry.FindField('CODIGO_ART_ART') <> nil) then
      Result := qry.FieldByName('CODIGO_ART_ART').AsString;
  finally
    FreeAndNil(qry);
  end;
  end;
end;

function TfrmMtoDevolucionesCompra.ArticuloLineaActivaDevolucion: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmDevolucionesCompra) then
  begin
    ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_DEVCLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_DEVCLIN').AsString);
  end;
end;

function TfrmMtoDevolucionesCompra.BuscarSkuDevolucion(
  const ACodigoArt: string): string;
var
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmDevolucionesCompra) then
    MessageDlg('No está abierta la devolución de compra.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := inLibGlobalVar.oConn;
      qry.SQL.Text :=
        'SELECT SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU, ' +
        '       GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
        '                    AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS ' +
        '  FROM fza_articulos_skus SK ' +
        '  LEFT JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  LEFT JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = SA.ID_AV_SA ' +
        '  LEFT JOIN fza_variaciones_atributos VA ' +
        '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
        '   AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
        ' WHERE SK.CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU ' +
        ' ORDER BY SK.CODIGO_UNIDAD_SKU';
      qry.ParamByName('art').AsString := sArt;
      if TBusquedaUtils.EjecutarBusqueda(
           'SKUs del artículo ' + sArt,
           qry,
           'frmMtoDevcSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
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

procedure TfrmMtoDevolucionesCompra.AplicarArticuloDevolucion(
  const ACodigoArt: string);
var
  ds       : TDataSet;
  Validador: TArticulosValidador;
  Resolucion: TArtResolucionEntrada;
  Resolver : TArticulosResolver;
  Datos    : TArticuloDatos;
  qry      : TUniQuery;
  sArt     : string;
  sSku      : string;
  sPrv     : string;
  sAlm     : string;
  sModeloPrv: string;
  dFecha   : TDateTime;
  iAcPivot : Integer;
  rCantidad: Double;

  function CampoCabeceraString(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    if Assigned(dsTablaG) and Assigned(dsTablaG.DataSet) then
    begin
      Campo := dsTablaG.DataSet.FindField(ACampo);
      if Campo <> nil then
        Result := Trim(Campo.AsString);
    end;
  end;

  function FechaCabecera: TDateTime;
  var
    Campo: TField;
  begin
    Result := Date;
    if Assigned(dsTablaG) and Assigned(dsTablaG.DataSet) then
    begin
      Campo := dsTablaG.DataSet.FindField('FECHA_DEVC');
      if (Campo <> nil) and (not Campo.IsNull) then
        Result := Campo.AsDateTime;
    end;
  end;

  function ResolverConjuntoPivotArticulo(const ACodigoArticulo: string): Integer;
  begin
    Result := 0;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := inLibGlobalVar.oConn;
      qry.SQL.Text :=
        'SELECT aca.ID_AC_ACA ' +
        '  FROM fza_articulos_conjuntos_asign aca ' +
        ' WHERE aca.CODIGO_ART_ACA = :art ' +
        '   AND aca.ID_VA_ACA <> ''CO'' ' +
        ' ORDER BY aca.ID_VA_ACA ' +
        ' LIMIT 1';
      qry.ParamByName('art').AsString := ACodigoArticulo;
      qry.Open;
      if not qry.IsEmpty then
        Result := qry.FieldByName('ID_AC_ACA').AsInteger;
    finally
      FreeAndNil(qry);
    end;
  end;

  function ModeloProveedorArticulo(const ACodigoArticulo,
                                        ACodigoProveedor: string): string;
  begin
    Result := '';
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := inLibGlobalVar.oConn;
      qry.SQL.Text :=
        'SELECT ap.REF_PROVEEDOR_AP ' +
        '  FROM fza_articulos_proveedores ap ' +
        ' WHERE ap.CODIGO_ART_AP = :art ' +
        '   AND COALESCE(TRIM(ap.REF_PROVEEDOR_AP), '''') <> '''' ' +
        ' ORDER BY CASE WHEN ap.CODIGO_PRV_AP = :prv THEN 0 ELSE 1 END, ' +
        '          CASE ap.ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ' +
        '               ELSE 1 END, ' +
        '          ap.FECHA_VALIDEZ_AP DESC, ap.CODIGO_PRV_AP ' +
        ' LIMIT 1';
      qry.ParamByName('art').AsString := ACodigoArticulo;
      qry.ParamByName('prv').AsString := ACodigoProveedor;
      qry.Open;
      if not qry.IsEmpty then
        Result := qry.FieldByName('REF_PROVEEDOR_AP').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;

  function EsCodigoArticuloExacto(const ACodigo: string): Boolean;
  var
    qArt: TUniQuery;
  begin
    Result := False;
    if Trim(ACodigo) <> '' then
    begin
      qArt := TUniQuery.Create(nil);
      try
        qArt.Connection := inLibGlobalVar.oConn;
        qArt.SQL.Text :=
          'SELECT 1 ' +
          '  FROM fza_articulos ' +
          ' WHERE CODIGO_ART_ART = :art ' +
          ' LIMIT 1';
        qArt.ParamByName('art').AsString := Trim(ACodigo);
        qArt.Open;
        Result := not qArt.IsEmpty;
      finally
        FreeAndNil(qArt);
      end;
    end;
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

  procedure LimpiarCampo(const ACampo: string);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.Clear;
  end;

  procedure EnfocarSku(AAbrirBusqueda: Boolean);
  var
    colSku: TcxGridDBColumn;
  begin
    colSku := tvLineasDevolucion.GetColumnByFieldName('CODIGO_UNIDAD_DEVCLIN');
    if colSku <> nil then
    begin
      colSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasDevolucion.Controller.FocusedColumn := colSku;
          tvLineasDevolucion.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            colLineaDevcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sArt := Trim(ACodigoArt);
  if (sArt <> '') and Assigned(dmmDevolucionesCompra) and
     (not FAplicandoArticulo) then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if Assigned(ds) and ds.Active then
    begin
      FAplicandoArticulo := True;
      try
        if ds.IsEmpty then
          ds.Append;
        if not (ds.State in dsEditModes) then
          ds.Edit;
        sPrv := CampoCabeceraString('CODIGO_PRV_DEVC');
        sAlm := CampoCabeceraString('CODIGO_ALM_DEVC');
        dFecha := FechaCabecera;
        sSku := '';
        Datos.Clear;
        if EsCodigoArticuloExacto(sArt) then
        begin
          Resolver := TArticulosResolver.Create(inLibGlobalVar.oConn);
          try
            Datos := Resolver.ResolverDatos(sArt, '', '', dFecha, sAlm,
                                            sPrv);
            if Datos.Encontrado and Datos.RequiereSku then
              Datos.UltimoCoste := Resolver.ResolverUltimoCoste(
                Datos.CodigoArticulo, sPrv, '');
          finally
            FreeAndNil(Resolver);
          end;
        end
        else
        begin
          Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
          try
            Resolucion := Validador.Resolver(sArt);
          finally
            FreeAndNil(Validador);
          end;
          if Resolucion.Encontrado then
          begin
            sArt := Resolucion.CodigoArticulo;
            sSku := Resolucion.CodigoSku;
            Resolver := TArticulosResolver.Create(inLibGlobalVar.oConn);
            try
              Datos := Resolver.ResolverDatos(sArt, sSku, '', dFecha, sAlm,
                                              sPrv);
              if Datos.Encontrado and Datos.RequiereSku then
                Datos.UltimoCoste := Resolver.ResolverUltimoCoste(
                  Datos.CodigoArticulo, sPrv, '');
            finally
              FreeAndNil(Resolver);
            end;
          end
          else
          begin
            if Resolucion.Mensaje <> '' then
              Datos.Mensaje := Resolucion.Mensaje
            else
              Datos.Mensaje := 'No se encontró el artículo "' + sArt + '".';
          end;
        end;
        if Datos.Encontrado then
        begin
          iAcPivot := ResolverConjuntoPivotArticulo(Datos.CodigoArticulo);
          sModeloPrv := ModeloProveedorArticulo(Datos.CodigoArticulo, sPrv);
          if sModeloPrv = '' then
            sModeloPrv := Datos.UltimoCoste.RefProveedor;
          PonerString('CODIGO_ART_DEVCLIN', Datos.CodigoArticulo);
          PonerString('CODIGO_UNIDAD_DEVCLIN', Datos.CodigoSku);
          PonerString('REF_PRV_DEVCLIN', sModeloPrv);
          PonerString('CODIGO_FAM_DEVCLIN', Datos.CodigoFamilia);
          PonerString('DESCRIPCION_ARTICULO_DEVCLIN',
                      Datos.DescripcionArticulo);
          PonerString('TIPO_CANTIDAD_ARTICULO_DEVCLIN',
                      Datos.TipoCantidad);
          PonerString('TIPO_IVA_ARTICULO_DEVCLIN', Datos.TipoIVA);
          PonerFloat('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
                     Datos.UltimoCoste.PrecioUltCompra);
          if sAlm <> '' then
            PonerString('CODIGO_ALMACEN_DEVCLIN', sAlm);
          if iAcPivot > 0 then
            PonerInteger('ID_AC_PIVOT_DEVCLIN', iAcPivot)
          else
            LimpiarCampo('ID_AC_PIVOT_DEVCLIN');
          rCantidad := 0;
          if Datos.RequiereSku and (iAcPivot > 0) then
          begin
            PonerFloat('CANTIDAD_DEVCLIN', 0);
            PonerFloat('TOTAL_UNIDADES_DEVCLIN', 0);
          end
          else
          begin
            if ds.FindField('CANTIDAD_DEVCLIN') <> nil then
              rCantidad := ds.FieldByName('CANTIDAD_DEVCLIN').AsFloat;
            if rCantidad = 0 then
            begin
              rCantidad := 1;
              PonerFloat('CANTIDAD_DEVCLIN', rCantidad);
            end;
            if Datos.CodigoSku <> '' then
              PonerFloat('TOTAL_UNIDADES_DEVCLIN', rCantidad);
          end;
          PonerFloat('TOTAL_DEVCLIN',
                     rCantidad * Datos.UltimoCoste.PrecioUltCompra);
          if Datos.RequiereSku and (iAcPivot > 0) then
            PrepararColorPendienteArticuloDevolucion(Datos.CodigoArticulo,
                                                     iAcPivot);
          // Pivote de compras antiguo RETIRADO: sin auto-activacion
          // por preferencia ESPIVOTE. El modo de entrada (tallas
          // horizontal / SKU / desglose) lo gobierna el contrato
          // ColumnSKUcxGrid via F1.
          if Datos.RequiereSku and (Datos.CodigoSku = '') and
             ((FPivote = nil) or (not FPivote.Activo)) then
            EnfocarSku(True);
          RefrescarVisibilidadTallas;
          if FMostrarAtributos then
            CargarCaptionsAtributosLineaActiva;
          // En horizontal el pivote necesita la linea ya materializada para
          // crear/actualizar el SKU al teclear en la talla siguiente.
          if Assigned(FPivote) and FPivote.Activo and
             (ds.State in dsEditModes) then
            ds.Post;
        end
        else if Datos.Mensaje <> '' then
          MessageDlg(Datos.Mensaje, mtWarning, [mbOk], 0);
      finally
        FAplicandoArticulo := False;
      end;
    end;
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
  with tvLineasDevolucion.DataController.DataSet do
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ART_DEVCLIN').AsString);
end;

procedure TfrmMtoDevolucionesCompra.actIrProveedorExecute(Sender: TObject);
var
  sPrv: string;
begin
  sPrv := '';
  if Assigned(dmmDevolucionesCompra) and
     (not dmmDevolucionesCompra.unqryTablaG.IsEmpty) then
    sPrv := Trim(dmmDevolucionesCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_DEVC').AsString);
  if sPrv = '' then
    ShowMto(Self.Owner, 'Proveedores')
  else
    ShowMto(Self.Owner, 'Proveedores', sPrv);
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
      MessageDlg('Crea o selecciona una devolución de compra antes de ' +
                 'elegir la empresa.', mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
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
      MessageDlg('Crea o selecciona una devolución de compra antes de ' +
                 'elegir el proveedor.', mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
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
      AplicarIvaExentoIntracomunitarioProveedor(inLibGlobalVar.oConn, ds,
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
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
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
