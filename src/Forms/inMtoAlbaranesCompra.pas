{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlbaranesCompra                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de albaranes de COMPRA.                                     }
{    Cabecera + lineas sobre fza_albaranes_compra. Espejo simplificado         }
{    de inMtoAlbaranes adaptado a documento de compra (proveedor en            }
{    lugar de cliente, precio de compra en lugar de venta).                    }
{                                                                              }
{    Movimientos de stock: el data module (UniDataAlbaranesCompra)             }
{    reconstruye los movimientos AC desde las lineas actuales del              }
{    documento para mantener el kardex sincronizado tras correcciones.         }
{    La generacion de factura sigue pendiente para un hito posterior.          }
{******************************************************************************}
unit inMtoAlbaranesCompra;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni, System.Types,
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
  inLibColumnasSkuIntf,
  inLibGridPivoteVenta,
  inLibAplicacionArticuloCompraIntf,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibComprasPantallaIntf,
  UniDataAlbaranesCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList, cxSplitter, inLibDocumento, inLibDocumentoIntf;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;
  ID_VA_COLOR     = 'CO';

type
  TfrmMtoAlbaranesCompra = class(TfrmMtoDocumento)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcAlbaran:           TcxPageControl;
    tsLineasAlbaran:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasAlbaran:  TcxGrid;
    tvLineasAlbaran:     TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    tsProveedor:         TcxTabSheet;
    cxgrdMovimientosProveedor: TcxGrid;
    tvMovimientosProveedor: TcxGridDBTableView;
    cxgrdlvlMovimientosProveedor: TcxGridLevel;

    // Cabecera
    lblNroAlbaran:    TcxLabel;
    txtNUMERO_ALBC:   TcxDBTextEdit;
    lblSerieAlbaran:  TcxLabel;
    // Serie en combo editable: lista las series 'AB' de la empresa
    // (fza_empresas_series) y permite teclear una nueva.
    cbbSERIE_ALBC:    TcxDBComboBox;
    lblFechaAlbaran:  TcxLabel;
    dteINSTANTEMOVIMIENTO_ALBC: TcxDBDateEdit;
    lblTemporadaAlbaran: TcxLabel;
    cbbTemporadaAlbc: TcxDBLookupComboBox;
    lblPedidoOrigen:  TcxLabel;
    txtNUMERO_PED_ALBC: TcxDBTextEdit;
    txtSERIE_PED_ALBC:  TcxDBTextEdit;
    lblFacturaDestino: TcxLabel;
    txtNUMERO_FAC_ALBC: TcxDBTextEdit;
    txtSERIE_FAC_ALBC:  TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALBC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_ALBC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombreAlbc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_ALBC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    cbbCODIGO_ALM_ALBC: TcxDBLookupComboBox;
    // Check informativo: el albaran es mercancia en deposito.
    chkESDEPOSITO_ALBC: TcxDBCheckBox;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_ALBC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_ALBC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_ALBC: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_ALBC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_ALBC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_ALBC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_ALBC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_ALBC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_ALBC: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_ALBC: TcxDBLookupComboBox;
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
    btnImprimirH: TcxButton;
    btnImprimirV: TcxButton;
    btnPegatinas: TcxButton;
    // Boton para saltar al pedido de compra de origen del albaran
    // (atajo Ctrl+May+A via actIrDocumento).
    btnIrDocumento: TcxButton;
    ActionList1: TActionList;
    actArticulos: TAction;
    actIrDocumento: TAction;
    actIrFacturaCreada: TAction;
    actIrProveedor: TAction;
    btnIrFacturaCreada: TcxButton;
    lblTotalesTotalPrendas: TcxLabel;
    curTotalesTOTAL_PRENDAS_ALBC: TcxDBCurrencyEdit;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnImprimirHClick(Sender: TObject);
    procedure btnImprimirVClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    // Eventos del grid de lineas — mismos handlers que en Sesiones de compra:
    // sin esto, las celdas talla quedan vacias al navegar, no se sombrean
    // las celdas fuera del conjunto pivot y Enter no salta de celda.
    procedure tvLineasAlbaranFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasAlbaranCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasAlbaranEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cxgrdLineasAlbaranEnter(Sender: TObject);
    procedure cxgrdLineasAlbaranExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrFacturaCreadaExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_ALBCPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_ALBCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnCODIGO_EMP_ALBCPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_PRV_ALBCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_ALM_ALBCPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_ALBCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure cbbCODIGO_PRV_ALBCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure colLineaAlbcCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaAlbcCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaAlbcCODIGO_UNIDADPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    FColColorPivot   : TcxGridDBColumn;
    FBasicosColor    : TArray<string>;
    FAplicacionArticuloCompra: IAplicacionArticuloCompra;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributos: IArticulosAtributosLookup;
    FBusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    FBusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    FBusquedasArticulos: IBusquedasCompraPersistencia;
    // Guarda contra reentrada del toggle desde dsTablaGDataChangeHook
    // disparado por el Edit/Post de PersistirPreferenciaPivote (entre
    // el Edit y el set, la cabecera tiene el ESPIVOTE viejo y el hook
    // veria discrepancia con Activo).
    FInToggleClick   : Boolean;
    FAfterOpenLineasOriginal: TDataSetNotifyEvent;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal, con el
    // MISMO pivote tallashorped de venta (BANDA UNICA: Cantidad) sobre
    // lineas SKU reales, sin tabla de celdas. El Construir hace
    // ClearItems: las columnas del dfm y las del pivote de compras
    // antiguo mueren y las del documento se recrean en runtime. El
    // pivote de compras (FPivote/ESPIVOTE) queda RETIRADO de esta
    // pantalla (decision 09/07/26, mismo criterio que pedidos compra).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure CargarBasicosColorArticulo(const ACodigoArt: string);
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombreAlbc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataAlbaranesCompra
    // .unqryPrvDataAlbc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterOpenHook(DataSet: TDataSet);
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject; var DisplayValue: Variant;
                                var ErrorText: TCaption;
                                var Error: Boolean);
    function BuscarArticuloAlbaranCompra: string;
    function BuscarSkuAlbaranCompra(const ACodigoArt: string): string;
    function BuscarEmpresaAlbaranCompra(out ACodigo: string): Boolean;
    function BuscarProveedorAlbaranCompra(out ACodigo: string): Boolean;
    function ArticuloLineaActivaAlbaranCompra: string;
    procedure AplicarArticuloAlbaranCompra(const ACodigoArt: string);
    procedure EnfocarSkuAlbaranCompra(AAbrirBusqueda: Boolean);
    procedure PresentarArticuloAlbaranCompra(
      const AResultado: TResultadoAplicacionArticuloCompra);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaAlbaranCompra;
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
    function PuedeActivarTallasHorizontal(var AMensaje: string): Boolean;
    procedure colLineaAlbcCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLinAlbcColorPivotButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure PersistirPreferenciaPivote;
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostAlbaranCompra;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    // Rotulo de modo en la pestania de lineas, como en ventas.
    procedure ActualizarCaptionModoLineas;
    // Color/Talla visibles con nombres globales en desglose,
    // mismo paso que pedidos de compra.
    procedure MostrarColumnasAtributoGlobalesAlbc;
  protected
    // F1 = ciclar el modo de entrada (KeyPreview de TfrmBase),
    // mismo atajo que pedidos/facturas de venta y pedidos de compra.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmAlbaranesCompra: TdmAlbaranesCompra;
    procedure CrearTablaPrincipal; override;
  end;

implementation

uses
  System.StrUtils,
  inLibFiltroUsuario,

  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataAplicacionArticuloCompra,
  inLibGridCantidad,
  inLibColumnasDocumento, UniDataColumnasDocumentoRepositorio,
  UniDataGen,
  inLibBusquedasCompra,
  inLibValidacionDocumento, UniDataValidacionDocumentoRepositorio,
  inLibPresentacionDocumento,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inLibAtributosPaleta,
  inLibMsgArticulos, inLibMsgCompras,
  UniDataArticulos,
  inMtoModalImpAlbCompra,
  inMtoModalImpAlbCompraV,
  inMtoModalEtiqAlb, inLibShowMto, inLibGenBusq,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta, UniDataGridPivoteCompraRepositorio,
  UniDataColumnasSkuServicios, UniDataModoTallas,
  UniDataComprasPantallaComposicion;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// dsTablaG apunta a la cabecera del albaran de compra. El articulo
// activo vive en la fila del sub-grid tvLineasAlbaran
// (CODIGO_ART_ALBCLIN / CODIGO_UNIDAD_ALBCLIN).
function TfrmMtoAlbaranesCompra.BuscarArticuloAlbaranCompra: string;
var
  sPrv: string;
begin
  Result := '';
  if Assigned(dmmAlbaranesCompra) then
  begin
    sPrv := Trim(dmmAlbaranesCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_ALBC').AsString);
    if (sPrv = '') or (sPrv = '0') then
      MessageDlg(SErrorProveedorNoSeleccionadoBuscarArticulos,
                 mtInformation, [mbOk], 0)
    else
      Result := BuscarArticuloProveedorCompra(
        FBusquedasArticulos, BusquedaVisual, sPrv,
        'Búsqueda de artículos', 'frmMtoDevcArtSearch', Self);
  end;
end;

function TfrmMtoAlbaranesCompra.ArticuloLineaActivaAlbaranCompra: string;
begin
  Result := '';
  if Assigned(dmmAlbaranesCompra) then
    Result := ValorTextoDataSetCompra(
      dmmAlbaranesCompra.unqryAlbaranesCompraLineas,
      'CODIGO_ART_ALBCLIN');
end;

function TfrmMtoAlbaranesCompra.BuscarSkuAlbaranCompra(
  const ACodigoArt: string): string;
var
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmAlbaranesCompra) then
    MessageDlg(SErrorAlbaranCompraNoAbierto,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg(SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarSkuArticuloCompra(
      FBusquedasArticulos, BusquedaVisual, sArt,
      'SKUs del artículo ' + sArt,
      'frmMtoAlbcSkuSearch', Self);
end;

procedure TfrmMtoAlbaranesCompra.CargarBasicosColorArticulo(
  const ACodigoArt: string);
begin
  FBasicosColor := ObtenerBasicosArticulo(
    ConexionPrincipal, ACodigoArt, ID_VA_COLOR);
end;

procedure TfrmMtoAlbaranesCompra.AsegurarCabeceraPersistidaParaLineas;
begin
  if not Assigned(dmmAlbaranesCompra) then
    raise Exception.Create(SErrorAlbaranCompraNoInicializado)
  else
    AsegurarCabeceraPersistidaCompra(
      dmmAlbaranesCompra.unqryTablaG,
      dmmAlbaranesCompra.unqryAlbaranesCompraLineas,
      ConfiguracionTallasDocumento,
      nil);
end;

function TfrmMtoAlbaranesCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
  if Assigned(dmmAlbaranesCompra) and Assigned(FPivote) then
    Result := PuedeActivarTallasHorizontalCompra(
      dmmAlbaranesCompra.unqryTablaG,
      dmmAlbaranesCompra.unqryAlbaranesCompraLineas,
      CrearValidacionDocumentoLecturas(
        dmmAlbaranesCompra.unqryTablaG.Connection),
      ConfiguracionTallasDocumento,
      AsegurarCabeceraPersistidaParaLineas,
      FPivote.ValidarPivotePosible, AMensaje);
end;

procedure TfrmMtoAlbaranesCompra.AplicarArticuloAlbaranCompra(
  const ACodigoArt: string);
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
  bPivoteActivo: Boolean;
begin
  if (Trim(ACodigoArt) <> '') and Assigned(dmmAlbaranesCompra) and
     (FAplicacionArticuloCompra <> nil) then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    bPivoteActivo := Assigned(FPivote) and FPivote.Activo;
    oEntrada := RecogerEntradaArticuloCompra(
      ACodigoArt,
      dmmAlbaranesCompra.unqryTablaG,
      tdacAlbaran,
      bPivoteActivo);
    oResultado := FAplicacionArticuloCompra.Ejecutar(
      oEntrada,
      tdacAlbaran);
    PresentarArticuloAlbaranCompra(oResultado);
  end;
end;

procedure TfrmMtoAlbaranesCompra.EnfocarSkuAlbaranCompra(
  AAbrirBusqueda: Boolean);
var
  oColumnaSku: TcxGridDBColumn;
begin
  oColumnaSku := tvLineasAlbaran.GetColumnByFieldName(
    'CODIGO_UNIDAD_ALBCLIN');
  if oColumnaSku <> nil then
  begin
    oColumnaSku.Visible := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        tvLineasAlbaran.Controller.FocusedColumn := oColumnaSku;
        tvLineasAlbaran.Controller.EditingController.ShowEdit;
        if AAbrirBusqueda then
          colLineaAlbcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
      end);
  end;
end;

procedure TfrmMtoAlbaranesCompra.PresentarArticuloAlbaranCompra(
  const AResultado: TResultadoAplicacionArticuloCompra);
begin
  if AResultado.Mensaje <> '' then
    MessageDlg(AResultado.Mensaje, mtWarning, [mbOk], 0);
  if AResultado.Aplicado and AResultado.RequiereSku and
     ((FPivote = nil) or (not FPivote.Activo)) then
    EnfocarSkuAlbaranCompra(True);
end;

// Combo de serie de la cabecera: al desplegar se recargan las series
// 'AB' vigentes de la empresa del albaran. Si la empresa no tiene
// ninguna, se avisa y se ofrece ir a Empresas -> Series a crearlas.
procedure TfrmMtoAlbaranesCompra.cbbSERIE_ALBCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmAlbaranesCompra <> nil) and dmmAlbaranesCompra.unqryTablaG.Active then
    sEmpresa := Trim(dmmAlbaranesCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_ALBC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_ALBC.Properties.Items);
  if cbbSERIE_ALBC.Properties.Items.Count = 0 then
  begin
    if MessageDlg(Format(SPreguntaAbrirSeriesAlbaranCompra, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ShowMto(Self.Owner, 'Empresas');
  end;
end;

procedure TfrmMtoAlbaranesCompra.FormCreate(Sender: TObject);
var
  oEntrada: TEntradaComposicionComprasPantalla;
  oServicios: TServiciosComprasPantalla;
begin
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := CrearColumnaColorPivoteDocumento(
    tvLineasAlbaran, 'colLinAlbcColorPivot', 110);
  ConfigurarColumnaBotonDocumento(
    FColColorPivot, colLinAlbcColorPivotButtonClick);
  inherited;
  oEntrada := Default(TEntradaComposicionComprasPantalla);
  oEntrada.Tipo := tccAlbaran;
  oEntrada.Conexion := ConexionPrincipal;
  oEntrada.Cabecera := dmmAlbaranesCompra.unqryTablaG;
  oEntrada.Lineas := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
  oServicios := ComponerComprasPantalla(
    Self,
    oEntrada);
  FAplicacionArticuloCompra := oServicios.Documento.AplicacionArticulo;
  FValidadorArticulos := oServicios.Documento.ValidadorArticulos;
  FLookupAtributos := oServicios.Documento.LookupAtributos;
  FBusquedaEmpresas := oServicios.Documento.BusquedaEmpresas;
  FBusquedaProveedores := oServicios.Documento.BusquedaProveedores;
  FBusquedasArticulos := oServicios.Documento.BusquedasArticulos;
  ConfigurarColumnaBusquedaDocumento(
    tvLineasAlbaran, 'CODIGO_UNIDAD_ALBCLIN',
    colLineaAlbcCODIGO_UNIDADPropertiesButtonClick,
    colLineaAlbcCODIGO_UNIDADPropertiesValidate);
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre albaranes, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor del albaran enfocado al abrir el form.
  ActualizarLabelProveedor;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesAlbaranCompra).
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FAfterOpenLineasOriginal :=
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterOpen;
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterOpen :=
                                             unqryLineasAfterOpenHook;
  FMostrarAtributos := False;
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
  if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Active then
    ConstruirModoEntrada;
  // El dfm guarda Totales como pagina activa: al abrir, la primera.
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoAlbaranesCompra.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdAlbaran, sdCompra));
  AsignarVistaLineasDocumento(tvLineasAlbaran);
  inherited;
  dmmAlbaranesCompra := TdmAlbaranesCompra(
    AsegurarDataModuleDocumento(
      Self, tdmDataModule, TdmAlbaranesCompra));
  ConfigurarTablaPrincipalDocumento(
    dmmAlbaranesCompra, dsTablaG, tvLineasAlbaran,
    dmmAlbaranesCompra.dsAlbaranesCompraLineas,
    [dmmAlbaranesCompra.unqryAlbaranesCompraLineas,
     dmmAlbaranesCompra.unqryMovimientosProveedor],
    pkFieldName, 'SERIE_ALBC;NUMERO_ALBC');
  tvMovimientosProveedor.DataController.DataSource :=
    dmmAlbaranesCompra.dsMovimientosProveedor;
  cbbTotalesFORMA_PAGO_ALBC.Properties.ListSource :=
    dmmAlbaranesCompra.dsFormasPago;
  cbbCODIGO_ALM_ALBC.Properties.ListSource :=
    dmmAlbaranesCompra.dsAlmacenesAlbc;
  cbbTemporadaAlbc.Properties.ListSource :=
    dmmAlbaranesCompra.dsTemporadasAlbc;
  cbbTemporadaAlbc.Properties.ListFieldNames := 'PV';
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup unqryPrvDataAlbc, ya cargado para el rotulo.
  cbbCODIGO_PRV_ALBC.Properties.ListSource := dmmAlbaranesCompra.dsPrvDataAlbc;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_ALBC);
end;

procedure TfrmMtoAlbaranesCompra.FormDestroy(Sender: TObject);
begin
  FAplicacionArticuloCompra := nil;
  FValidadorArticulos := nil;
  FLookupAtributos := nil;
  FBusquedaEmpresas := nil;
  FBusquedaProveedores := nil;
  FBusquedasArticulos := nil;
  LiberarModoYGestoresDocumento(
    FModoEntrada, FPivote, FGestorTallas);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoAlbaranesCompra.CrearColumnasTallas;
begin
  CrearColumnasTallasDocumento(tvLineasAlbaran, 'dbcLinAlbcTalla',
    50, FTallaColumns);
end;

// Columnas no-bound y de solo lectura para el desglose visual del SKU.
procedure TfrmMtoAlbaranesCompra.CrearColumnasAtributos;
begin
  CrearColumnasAtributosDocumento(tvLineasAlbaran,
    'dbcLinAlbcAtrib', FAtribColumns);
end;

procedure TfrmMtoAlbaranesCompra.InicializarGestorYPivote;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfigTallas: TGridTallasConfig;
  oConfigPivote: TGridPivoteCompraConfig;
begin
  if Assigned(FGestorTallas) then
    FreeAndNil(FGestorTallas);
  if Assigned(FPivote) then
    FreeAndNil(FPivote);
  if Assigned(dmmAlbaranesCompra) then
  begin
    oBase := Default(TConfigPivoteDocumentoCompra);
    oBase.Conexion := dmmAlbaranesCompra.unqryTablaG.Connection;
    oBase.ContextoSesion := ContextoSesion;
    oBase.Usuario := IdentidadSesion.Usuario;
    oBase.Vista := tvLineasAlbaran;
    oBase.SourceMaster := dsTablaG;
    oBase.SourceLineas :=
      dmmAlbaranesCompra.dsAlbaranesCompraLineas;
    oBase.ConsultaLineas :=
      dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
    oBase.ColumnasTallas := CopiarColumnasDocumento(FTallaColumns);
    oBase.ColColorPivot := FColColorPivot;
    oBase.PrefijoCabecera := 'ALBC';
    oBase.PrefijoLinea := 'ALBCLIN';
    oBase.PrefijoCelda := 'ALBCCEL';
    oBase.NombreTablaDocumento := 'albaranes';
    oBase.AplicarContextoPivote := True;
    oBase.RegistroLog := RegistroLog;
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

procedure TfrmMtoAlbaranesCompra.RefrescarVisibilidadTallas;
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

procedure TfrmMtoAlbaranesCompra.RefrescarVisibilidadAtributos;
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
procedure TfrmMtoAlbaranesCompra.CargarCaptionsAtributosLineaActiva;
begin
  if Assigned(dmmAlbaranesCompra) then
    CargarCaptionsAtributosDocumento(
      dmmAlbaranesCompra.unqryDefArticuloAlbc,
      dmmAlbaranesCompra.unqryAlbaranesCompraLineas,
      'CODIGO_ART_ALBCLIN', FAtribColumns);
end;

procedure TfrmMtoAlbaranesCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmAlbaranesCompra <> nil) and (FPivote <> nil) and
     not FInToggleClick then
  begin
    FInToggleClick := True;
    try
      if not FPivote.Activo then
      begin
        if PuedeActivarTallasHorizontal(sMensaje) then
        begin
          FPivote.Activar;
          if Sender <> nil then
            PersistirPreferenciaPivote;
        end
        else if Sender <> nil then
          MessageDlg(sMensaje, mtWarning, [mbOk], 0);
      end
      else
      begin
        FPivote.Desactivar;
        if Sender <> nil then
          PersistirPreferenciaPivote;
      end;
    finally
      FInToggleClick := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.PersistirPreferenciaPivote;
begin
  PersistirPreferenciaPivoteDocumento(
    dsTablaG.DataSet, 'ESPIVOTE_HORIZONTAL_ALBC', FPivote.Activo);
end;

procedure TfrmMtoAlbaranesCompra.btnImprimirHClick(Sender: TObject);
var
  form    : TfrmPrintAlbCompra;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmAlbaranesCompra <> nil then
  begin
    if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
      ShowMessage(SErrorAlbaranCompraSinImpresionActivo)
    else
    begin
      if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmAlbaranesCompra.unqryTablaG.Post;
      if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.State in
         [dsEdit, dsInsert] then
        dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Post;
      sSerie := dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'SERIE_ALBC').AsString;
      sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'NUMERO_ALBC').AsString;
      form := TfrmPrintAlbCompra.Create(Application);
      try
        form.dmAlbc := dmmAlbaranesCompra;
        form.edtSerie.Text := sSerie;
        form.edtNumero.Text := sNumero;
        form.ShowModal;
      finally
        FreeAndNil(form);
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnImprimirVClick(Sender: TObject);
var
  form    : TfrmPrintAlbCompraV;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmAlbaranesCompra <> nil then
  begin
    if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
      ShowMessage(SErrorAlbaranCompraSinImpresionActivo)
    else
    begin
      if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmAlbaranesCompra.unqryTablaG.Post;
      if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.State in
         [dsEdit, dsInsert] then
        dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Post;
      sSerie := dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'SERIE_ALBC').AsString;
      sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'NUMERO_ALBC').AsString;
      form := TfrmPrintAlbCompraV.Create(Application);
      try
        form.dmAlbc := dmmAlbaranesCompra;
        form.edtSerie.Text := sSerie;
        form.edtNumero.Text := sNumero;
        form.ShowModal;
      finally
        FreeAndNil(form);
      end;
    end;
  end;
end;


procedure TfrmMtoAlbaranesCompra.btnPegatinasClick(Sender: TObject);
var
  form    : TfrmPrintEtiqAlb;
  dmArt   : TdmArticulos;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmAlbaranesCompra <> nil then
  begin
    if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
      ShowMessage(SErrorAlbaranCompraNoActivo)
    else
    begin
      if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmAlbaranesCompra.unqryTablaG.Post;
      sSerie := dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'SERIE_ALBC').AsString;
      sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'NUMERO_ALBC').AsString;
  // El modal reutiliza el dataset de etiquetas del DM de articulos
  // (cdsEtiquetasArt, fxdsEtiquetasArt) para que el mismo .fr3 sirva
  // en ambos sitios. Creamos un DM temporal porque el form de
  // albaranes no necesita uno permanente.
  // TdmArticulos.Create dispara DataModuleCreate que ya asigna la
  // conexion. No necesitamos AbrirDetalles ni OpenTables — las queries
  // de print (unqryTarifasPrint, unqryArtPrint) se abren bajo demanda
  // desde el modal / CrearDataSetEtiquetasArt.
      dmArt := TdmArticulos.Create(nil);
    try
      form := TfrmPrintEtiqAlb.Create(Application);
      try
        form.DMArt := dmArt;
        form.DMAlbc := dmmAlbaranesCompra;
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

procedure TfrmMtoAlbaranesCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoAlbaranesCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoAlbaranesCompra.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  if RegistroLog <> nil then
    RegistroLog.RegistrarInformacion('AlbaranesCompra.btnGrabarClick: INICIO');
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    FValidadorArticulos,
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas, 'ALBCLIN');
  if (sLineasSinSku = '') or
     (MessageDlg(Format(SPreguntaGrabarAlbaranCompraSinSku,
                  [sLineasSinSku]),
                  mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    if Assigned(FPivote) and FPivote.Activo and
       not FPivote.Expandido then
      FPivote.PersistirCantidadesPendientes;
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
      dsTablaG.DataSet.Post;
    end;
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
  end;
end;

// Actualiza la cabecera y delega el modo al navegar entre albaranes.
procedure TfrmMtoAlbaranesCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
begin
  // Refrescar el rotulo del proveedor al navegar entre albaranes (Field=nil)
  // o al cambiar CODIGO_PRV_ALBC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_ALBC') then
    ActualizarLabelProveedor;
  if (Field = nil) and Assigned(dmmAlbaranesCompra) and
     dmmAlbaranesCompra.unqryTablaG.Active and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
    dmmAlbaranesCompra.RefrescarAlmacenes(
      dmmAlbaranesCompra.unqryTablaG.FieldByName(
        'CODIGO_EMP_ALBC').AsString);
  if Assigned(dmmAlbaranesCompra) then
    ActualizarModoEntradaAlNavegarDocumento(
      Field, dmmAlbaranesCompra.unqryAlbaranesCompraLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel, True,
      ConstruirModoEntrada,
      dmmAlbaranesCompra.DesempaquetarAtributosLineas);
end;

procedure TfrmMtoAlbaranesCompra.ActualizarLabelProveedor;
begin
  if Assigned(dmmAlbaranesCompra) then
    lblProveedorNombreAlbc.Caption := TextoProveedorDocumento(
      dmmAlbaranesCompra.unqryTablaG,
      dmmAlbaranesCompra.unqryPrvDataAlbc,
      'CODIGO_PRV_ALBC')
  else
    lblProveedorNombreAlbc.Caption := '';
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesAlbaranCompra) con la republicacion del controlador.
procedure TfrmMtoAlbaranesCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmAlbaranesCompra) then
  begin
    dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
    dmmAlbaranesCompra.SincronizarMovimientos;
  end;
  // En reorganizacion del modo de entrada la lib republica al final:
  // republicar por cada linea repite trabajo sin efecto visual.
  if ((dmmAlbaranesCompra = nil) or
      (not dmmAlbaranesCompra.EnReorganizacionLineas)) and
     Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

procedure TfrmMtoAlbaranesCompra.unqryLineasAfterOpenHook(DataSet: TDataSet);
begin
  if Assigned(FAfterOpenLineasOriginal) then
    FAfterOpenLineasOriginal(DataSet);
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla y, si "atributo por columna" esta activo, recargamos los nombres
// de atributo del articulo activo.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarFocoLineaDocumento(
    FGestorTallas, FPivote, FMostrarAtributos,
    CargarCaptionsAtributosLineaActiva);
end;

// Sombreado de celdas talla fuera del conjunto pivot — delegamos en lib.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

// Bloqueo de edicion en celdas talla fuera del conjunto — delegamos en lib.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranEditing(
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
procedure TfrmMtoAlbaranesCompra.cxgrdLineasAlbaranEnter(Sender: TObject);
begin
  inherited;
  EntrarGridLineasDocumento(
    Self, FColsModoConstruido, False, FModoEntrada,
    AsegurarPrimeraLineaAlbaranCompra, ConstruirModoEntrada);
end;

procedure TfrmMtoAlbaranesCompra.cxgrdLineasAlbaranExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoAlbaranesCompra.ActualizarCaptionModoLineas;
begin
  tsLineasAlbaran.Caption := CaptionModoLineasDocumento(
    '&1_Líneas', '&1_Líneas ', FColsModoConstruido,
    FModoEntradaSel, False);
end;

procedure TfrmMtoAlbaranesCompra.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcAlbaran.ActivePage = tsLineasAlbaran) and
    (dmmAlbaranesCompra <> nil), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasHorPed], ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoAlbaranesCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  ds: TDataSet;
  bDegradarASku: Boolean;
  ModoEfectivo: TModoColumnasSku;
begin
  if (dmmAlbaranesCompra <> nil) and
     not (csDestroying in ComponentState) then
  begin
    ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
    if ds.Active then
    begin
  // Expansion/consolidacion en bloque (una linea por SKU): totales y
  // movimientos se recalculan UNA vez al finalizar en vez de por cada
  // post de linea (cascada de segundos al entrar al modo).
  dmmAlbaranesCompra.IniciarReorganizacionLineas;
  try
  PrepararReconstruccionModoDocumento(tvLineasAlbaran, ds,
    FModoEntrada, FTallaColumns, FAtribColumns, FColColorPivot);
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _ALBCLIN; idempotente por linea). SKU y tallas
  // horizontal derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmAlbaranesCompra.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    CrearServiciosColumnasSkuUniDAC(
      dmmAlbaranesCompra.unqryTablaG.Connection),
    ContextoSesion, tvLineasAlbaran, ds, FModoEntradaSel,
    Trim(dmmAlbaranesCompra.unqryTablaG.
      FieldByName('CODIGO_ALM_ALBC').AsString), 'ALBCLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FValidadorArticulos;
  Cfg.LookupAtributos := FLookupAtributos;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := CrearConfigPivoteBandasDocumentoCompra(
      dmmAlbaranesCompra.unqryTablaG.Connection,
      IdentidadSesion.Usuario, dsTablaG,
      dmmAlbaranesCompra.dsAlbaranesCompraLineas,
      'ALBC', 'ALBCLIN',
      'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN',
      CANT_TALLAS_MAX);
    // Albaran de compra: UNA sola cantidad por linea -> banda unica.
    CfgPV.BandaUnica := True;
    // La columna Total del host pasa a UNIDADES del grupo en pivote.
    CfgPV.FieldTotalUdsGrupo := 'TOTAL_ALBCLIN';
    CfgPV.Repositorios :=
      CrearRepositorioPivoteVenta(
        CfgPV.Conexion, CfgPV.Usuario, BusquedaVisual);
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
    [mcsTallasHorPed], 'AlbaranesCompra');
  if bDegradarASku then
  begin
    // Reconstruccion completa en SKU: el teardown de la reentrada
    // limpia lo que el pivote dejara a medias. Maximo una reentrada.
    FModoEntradaSel := mcsSku;
    ConstruirModoEntrada;
  end
  else
  begin
    CrearColumnasHostAlbaranCompra;
    // Rotulo por modo EFECTIVO (Auto puede degradar a SKU si faltan
    // las columnas ATTR en la BBDD) y, en desglose, mostrar Color y
    // Talla con nombres globales desde el principio (patron pedidos
    // de compra).
    ModoEfectivo := DetectarModoColumnasSku(Cfg);
    tsLineasAlbaran.Caption := CaptionModoLineasDocumento(
      '&1_Líneas', '&1_Líneas ', True, ModoEfectivo, False);
    if not (ModoEfectivo in [mcsSku, mcsTallasHorPed]) then
      MostrarColumnasAtributoGlobalesAlbc;
  end;
  finally
    dmmAlbaranesCompra.FinalizarReorganizacionLineas;
  end;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.MostrarColumnasAtributoGlobalesAlbc;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineasAlbaran,
    CrearColumnasDocumentoLecturas(
      dmmAlbaranesCompra.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoAlbaranesCompra.CrearColumnasHostAlbaranCompra;
var
  Columnas: TColumnasHostDocumentoCompra;
begin
  Columnas := CrearColumnasHostDocumentoCompra(
    tvLineasAlbaran, FModoEntradaSel, 'ALBCLIN');
  if Assigned(Columnas.ColCantidad) then
    VincularCantidadGrid(Columnas.ColCantidad,
      Columnas.ColTipoCantidad, UnidadesMedida);
end;

procedure TfrmMtoAlbaranesCompra.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo clasico del albaran de compra (precio de compra del
  // proveedor, IVA, modelo proveedor...) se reaprovecha tal cual:
  // AplicarArticuloAlbaranCompra acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloAlbaranCompra(ASku);
end;

procedure TfrmMtoAlbaranesCompra.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloAlbaranCompra(ACodigoSku);
end;

procedure TfrmMtoAlbaranesCompra.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoAlbaranesCompra.TallaEditValueChangedHook(Sender: TObject);
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

procedure TfrmMtoAlbaranesCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

procedure TfrmMtoAlbaranesCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasAlbaran.DataController.DataSet,
    'CODIGO_ART_ALBCLIN');
end;

procedure TfrmMtoAlbaranesCompra.actIrProveedorExecute(Sender: TObject);
begin
  if Assigned(dmmAlbaranesCompra) then
    ShowMtoCodigoDataSet(Self.Owner, 'Proveedores',
      dmmAlbaranesCompra.unqryTablaG, 'CODIGO_PRV_ALBC')
  else
    ShowMto(Self.Owner, 'Proveedores');
end;

function TfrmMtoAlbaranesCompra.BuscarEmpresaAlbaranCompra(
  out ACodigo: string): Boolean;
var
  oConsulta: IConsultaComprasPantalla;
  oDatos: TDataSet;
begin
  ACodigo := '';
  oConsulta := FBusquedaEmpresas.ConsultarEmpresas;
  oDatos := oConsulta.DataSet;
  Result := BusquedaVisual.EjecutarBusquedaDataSet(
    'Búsqueda de empresas', oDatos, 'frmMtoEmpFacSearch', Self);
  if Result then
    ACodigo := oDatos.FieldByName('CODIGO_EMP_EMP').AsString;
end;

function TfrmMtoAlbaranesCompra.BuscarProveedorAlbaranCompra(
  out ACodigo: string): Boolean;
var
  oConsulta: IConsultaComprasPantalla;
  oDatos: TDataSet;
begin
  ACodigo := '';
  oConsulta := FBusquedaProveedores.ConsultarProveedores;
  oDatos := oConsulta.DataSet;
  Result := BusquedaVisual.EjecutarBusquedaDataSet(
    'Búsqueda de proveedores', oDatos, 'frmMtoAlbcProvSearch', Self);
  if Result then
    ACodigo := oDatos.FieldByName('CODIGO_PRV_PRV').AsString;
end;

procedure TfrmMtoAlbaranesCompra.btnCODIGO_EMP_ALBCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmAlbaranesCompra) then
  begin
    ds := dmmAlbaranesCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorAlbaranCompraNecesarioElegirEmpresa,
                 mtInformation, [mbOk], 0)
    else if BuscarEmpresaAlbaranCompra(sCodigo) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_EMP_ALBC').AsString := sCodigo;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoAlbaranesCompra.cbbCODIGO_PRV_ALBCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmAlbaranesCompra) then
  begin
    ds := dmmAlbaranesCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorAlbaranCompraNecesarioElegirProveedor,
                 mtInformation, [mbOk], 0)
    else if BuscarProveedorAlbaranCompra(sCodigo) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_PRV_ALBC').AsString := sCodigo;
      AplicarIvaExentoIntracomunitarioProveedor(
        CrearLecturasImpuestos(ConexionPrincipal), ds,
        'CODIGO_PRV_ALBC', 'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC');
      dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
      ActualizarLabelProveedor;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnCODIGO_EMP_ALBCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sEmpresa: string;
begin
  inherited;
  if Assigned(dmmAlbaranesCompra) then
  begin
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
       (dsTablaG.DataSet.State in dsEditModes) and
       (Sender is TcxCustomEdit) then
    begin
      e := Sender as TcxCustomEdit;
      sEmpresa := Trim(VarToStr(e.EditingValue));
      if sEmpresa <> '' then
        dmmAlbaranesCompra.BuscarEmpresa(sEmpresa);
    end;
    dmmAlbaranesCompra.RefrescarAlmacenes('');
  end;
end;

procedure TfrmMtoAlbaranesCompra.cbbCODIGO_ALM_ALBCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sAlmacen: string;
  sEmpresa: string;
  ds: TDataSet;
begin
  inherited;
  if Assigned(dmmAlbaranesCompra) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sAlmacen := Trim(VarToStr(e.EditingValue));
    if (sAlmacen <> '') and
       dmmAlbaranesCompra.unqryAlmacenesAlbc.Active and
       dmmAlbaranesCompra.unqryAlmacenesAlbc.Locate(
         'CODIGO_ALM_ALM', sAlmacen, []) then
    begin
      sEmpresa := Trim(dmmAlbaranesCompra.unqryAlmacenesAlbc.
                         FieldByName('CODIGO_EMP_ALM').AsString);
      ds := dsTablaG.DataSet;
      if (sEmpresa <> '') and
         (Trim(ds.FieldByName('CODIGO_EMP_ALBC').AsString) <> sEmpresa) then
        dmmAlbaranesCompra.BuscarEmpresa(sEmpresa);
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnCODIGO_EMP_ALBCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_ALBCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranesCompra.cbbCODIGO_PRV_ALBCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_ALBCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloAlbaranCompra;
  if sCodigo <> '' then
    AplicarArticuloAlbaranCompra(sCodigo);
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_ARTPropertiesValidate(
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
      AplicarArticuloAlbaranCompra(sCodigo);
      if Assigned(dmmAlbaranesCompra) and
         dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Active and
         (dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
            FindField('CODIGO_ART_ALBCLIN') <> nil) then
        DisplayValue := dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
                          FieldByName('CODIGO_ART_ALBCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaAlbaranCompra;
  sSku := BuscarSkuAlbaranCompra(sArt);
  if sSku <> '' then
    AplicarArticuloAlbaranCompra(sSku);
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_UNIDADPropertiesValidate(
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
      AplicarArticuloAlbaranCompra(sCodigo);
      if Assigned(dmmAlbaranesCompra) and
         dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Active and
         (dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
            FindField('CODIGO_UNIDAD_ALBCLIN') <> nil) then
        DisplayValue := dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
                          FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.AsegurarPrimeraLineaAlbaranCompra;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmAlbaranesCompra) then
  begin
    dsCab := dmmAlbaranesCompra.unqryTablaG;
    dsLin := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_ALBC').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_ALBC').AsString);
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

procedure TfrmMtoAlbaranesCompra.colLinAlbcColorPivotButtonClick(
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
    MessageDlg(SErrorActivarTallasHorizontalesParaColor,
               mtInformation, [mbOk], 0);
  end
  else
  begin
    sArt := ArticuloLineaActivaAlbaranCompra;
    if sArt = '' then
      MessageDlg(SErrorArticuloNoSeleccionadoElegirColor,
                 mtInformation, [mbOk], 0)
    else
    begin
      CargarBasicosColorArticulo(sArt);
      if Length(FBasicosColor) = 0 then
        MessageDlg(Format(SErrorArticuloSinColoresBasicosActivos, [sArt]),
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
            FPivote.RecargarYRepublicar
          else if sMensaje <> '' then
            MessageDlg(sMensaje, mtWarning, [mbOk], 0);
        end
      end;
    end;
  end;
end;

// "Ir a documento" (Ctrl+May+A): salta al pedido de compra del que nace
// el albaran (SERIE_PED_ALBC / NUMERO_PED_ALBC). Si el albaran se creo a
// mano y no procede de ningun pedido, avisamos en lugar de abrir un Mto
// vacio.
procedure TfrmMtoAlbaranesCompra.actIrDocumentoExecute(Sender: TObject);
begin
  inherited;
  if (dmmAlbaranesCompra <> nil) and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
    ShowMtoDocumentoDataSet(Self.Owner, 'PedidosCompra',
      dmmAlbaranesCompra.unqryTablaG,
      'SERIE_PED_ALBC', 'NUMERO_PED_ALBC',
      SAvisoAlbaranCompraSinPedido);
end;

procedure TfrmMtoAlbaranesCompra.actIrFacturaCreadaExecute(Sender: TObject);
begin
  inherited;
  if (dmmAlbaranesCompra <> nil) and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
    ShowMtoDocumentoDataSet(Self.Owner, 'FacturasCompra',
      dmmAlbaranesCompra.unqryTablaG,
      'SERIE_FAC_ALBC', 'NUMERO_FAC_ALBC',
      SAvisoAlbaranCompraSinFactura);
end;

procedure TfrmMtoAlbaranesCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Append;
end;

procedure TfrmMtoAlbaranesCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg(SPreguntaEliminarLineaAlbaranCompra,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Delete;
end;

initialization
  RegistrarPantalla(TfrmMtoAlbaranesCompra);
  ForceReferenceToClass(TfrmMtoAlbaranesCompra);
end.
