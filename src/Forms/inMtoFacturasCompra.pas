{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasCompra                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de facturas de COMPRA.                                     }
{    Cabecera + lineas sobre fza_facturas_compra. Espejo simplificado         }
{    de inMtoFacturas adaptado a documento de compra (proveedor en            }
{    lugar de cliente, precio de compra en lugar de venta).                    }
{                                                                              }
{    Movimientos de stock: el data module (UniDataFacturasCompra)             }
{    detecta transiciones de ESTADO_FACC en BeforePost y dispara en            }
{    AfterPost la generacion (ABIERTA -> CERRADA) o reversion                  }
{    (CERRADA -> ABIERTA) via inLibFacturasCompraMovimientos.                 }
{    La generacion de factura sigue pendiente para un hito posterior.          }
{******************************************************************************}
unit inMtoFacturasCompra;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni, System.Types,
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
  cxGridDBBandedTableView,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  inLibColumnasSkuIntf,
  inLibGridPivoteVenta,
  UniDataFacturasCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList, cxSplitter;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;
  ID_VA_COLOR     = 'CO';

type
  TfrmMtoFacturasCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcFactura:           TcxPageControl;
    tsLineasFactura:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasFactura:  TcxGrid;
    tvLineasFactura:     TcxGridDBTableView;
    cxgrdlvlLineasFactura: TcxGridLevel;

    // Cabecera
    lblNroFactura:    TcxLabel;
    txtNUMERO_FACC:   TcxDBTextEdit;
    lblSerieFactura:  TcxLabel;
    cbbSERIE_FACC:    TcxDBComboBox;
    lblFechaFactura:  TcxLabel;
    dteFECHA_FACC:    TcxDBDateEdit;
    lblEstadoFactura: TcxLabel;
    txtESTADO_FACC:   TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_FACC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_FACC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombreFacc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_FACC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    cbbCODIGO_ALM_FACC: TcxDBLookupComboBox;
    lblFormaPago: TcxLabel;
    cbbFORMA_PAGO_FACC: TcxDBLookupComboBox;
    tsEfectos: TcxTabSheet;
    pnlEfectosTop: TPanel;
    btnGenerarEfectos: TcxButton;
    btnRegistrarPago: TcxButton;
    cxgrdEfectos: TcxGrid;
    tvEfectos: TcxGridDBTableView;
    lvlEfectos: TcxGridLevel;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_FACC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_FACC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_FACC: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_FACC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_FACC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_FACC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_FACC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_FACC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_FACC: TcxDBCurrencyEdit;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasFacc: TcxLabel;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_FACC: TcxDBLookupComboBox;
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
    procedure btnImprimirHClick(Sender: TObject);
    procedure btnImprimirVClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    // Eventos del grid de lineas — mismos handlers que en Sesiones de compra:
    // sin esto, las celdas talla quedan vacias al navegar, no se sombrean
    // las celdas fuera del conjunto pivot y Enter no salta de celda.
    procedure tvLineasFacturaFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasFacturaCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasFacturaEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cxgrdLineasFacturaEnter(Sender: TObject);
    procedure cxgrdLineasFacturaExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_FACCPropertiesInitPopup(Sender: TObject);
    procedure cbbCODIGO_PRV_FACCPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_PRV_FACCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_PRV_FACCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure btnGenerarEfectosClick(Sender: TObject);
    procedure btnRegistrarPagoClick(Sender: TObject);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    FColColorPivot   : TcxGridDBColumn;
    FBasicosColor    : TArray<string>;
    FAplicandoArticulo: Boolean;
    // Guarda contra reentrada del toggle desde dsTablaGDataChangeHook
    // disparado por el Edit/Post de PersistirPreferenciaPivote (entre
    // el Edit y el set, la cabecera tiene el ESPIVOTE viejo y el hook
    // veria discrepancia con Activo).
    FInToggleClick   : Boolean;
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
    procedure CargarBasicosColorArticulo(const ACodigoArt: string);
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombreFacc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataFacturasCompra
    // .unqryPrvDataFacc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    // Pinta lblTotalPrendasFacc con el total de prendas (suma de
    // CANTIDAD_FACCLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject; var DisplayValue: Variant;
                                var ErrorText: TCaption;
                                var Error: Boolean);
    function BuscarArticuloFacturaCompra: string;
    function BuscarSkuFacturaCompra(const ACodigoArt: string): string;
    function ArticuloLineaActivaFacturaCompra: string;
    procedure AplicarArticuloFacturaCompra(const ACodigoArt: string);
    procedure colLineaFaccCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaFaccCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaFaccCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLinFaccColorPivotButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaFacturaCompra;
    function PuedeActivarTallasHorizontal(var AMensaje: string): Boolean;
    procedure PersistirPreferenciaPivote;
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostFacturaCompra;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    // Rotulo de modo en la pestania de lineas, como en ventas.
    procedure ActualizarCaptionModoLineas;
    // Color/Talla visibles con nombres globales en desglose,
    // mismo paso que albaranes/pedidos de compra.
    procedure MostrarColumnasAtributoGlobalesFacc;
  protected
    // F1 = ciclar el modo de entrada (KeyPreview de TfrmBase),
    // mismo atajo que albaranes y pedidos de compra.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmFacturasCompra: TdmFacturasCompra;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoFacturasCompra: TfrmMtoFacturasCompra;

implementation

uses
  System.StrUtils,
  inLibFiltroUsuario,
  inLibArticulosResolver,
  inLibArticulosValidador,
  inLibGridCantidad,
  inLibColumnasDocumento,
  inLibBusquedasCompra,
  inLibValidacionDocumento,
  inLibPresentacionDocumento,
  inLibComprasImpuestos,
  inLibAtributosPaleta,
  inLibMsg,
  UniDataArticulos,
  inMtoModalImpFacCompra,
  inMtoModalImpFacCompraV,
  inLibShowMto, inMtoModalRegistrarPago,
  inMtoModalSeleccionarBanco, inLibGenBusq,
  inLibValoresAutomaticos,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoFacturasCompra.cbbSERIE_FACCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmFacturasCompra <> nil) and
     dmmFacturasCompra.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmFacturasCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_FACC').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
  end;
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    'FP',
    cbbSERIE_FACC.Properties.Items);
  if cbbSERIE_FACC.Properties.Items.Count = 0 then
  begin
    if MessageDlg(Format(SPreguntaAbrirSeriesFacturaCompra, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera del factura de compra. El articulo
// activo vive en la fila del sub-grid tvLineasFactura
// (CODIGO_ART_FACCLIN / CODIGO_UNIDAD_FACCLIN).
procedure TfrmMtoFacturasCompra.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
begin
  ResolverArtSkuActivoDocumento(
    tvLineasFactura, ACodArt, ACodSku);
end;

function TfrmMtoFacturasCompra.DataSourcesParaFoto: TArray<TDataSource>;
begin
  Result := DataSourcesParaFotoDocumento(
    dsTablaG, tvLineasFactura);
end;

function TfrmMtoFacturasCompra.BuscarArticuloFacturaCompra: string;
var
  sPrv: string;
begin
  Result := '';
  if Assigned(dmmFacturasCompra) then
  begin
    sPrv := Trim(dmmFacturasCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_FACC').AsString);
    if (sPrv = '') or (sPrv = '0') then
      MessageDlg(SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra,
                 mtInformation, [mbOk], 0)
    else
      Result := BuscarArticuloProveedorCompra(
        dmmFacturasCompra.unqryTablaG.Connection, sPrv,
        'Búsqueda de artículos', 'frmMtoFaccArtSearch', Self);
  end;
end;

function TfrmMtoFacturasCompra.ArticuloLineaActivaFacturaCompra: string;
begin
  Result := '';
  if Assigned(dmmFacturasCompra) then
    Result := ValorTextoDataSetCompra(
      dmmFacturasCompra.unqryFacturasCompraLineas,
      'CODIGO_ART_FACCLIN');
end;

function TfrmMtoFacturasCompra.BuscarSkuFacturaCompra(
  const ACodigoArt: string): string;
var
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmFacturasCompra) then
    MessageDlg(SErrorFacturaCompraNoAbierta,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg(SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarSkuArticuloCompra(
      dmmFacturasCompra.unqryTablaG.Connection, sArt,
      'SKUs del artículo ' + sArt,
      'frmMtoFaccSkuSearch', Self);
end;

procedure TfrmMtoFacturasCompra.CargarBasicosColorArticulo(
  const ACodigoArt: string);
begin
  FBasicosColor := ObtenerBasicosArticulo(
    ConexionPrincipal, ACodigoArt, ID_VA_COLOR);
end;

procedure TfrmMtoFacturasCompra.FormCreate(Sender: TObject);
begin
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := CrearColumnaColorPivoteDocumento(
    tvLineasFactura, 'colLinFaccColorPivot', 110);
  ConfigurarColumnaBotonDocumento(
    FColColorPivot, colLinFaccColorPivotButtonClick);
  inherited;
  ConfigurarColumnaBusquedaDocumento(
    tvLineasFactura, 'CODIGO_ART_FACCLIN',
    colLineaFaccCODIGO_ARTPropertiesButtonClick,
    colLineaFaccCODIGO_ARTPropertiesValidate);
  ConfigurarColumnaBusquedaDocumento(
    tvLineasFactura, 'CODIGO_UNIDAD_FACCLIN',
    colLineaFaccCODIGO_UNIDADPropertiesButtonClick);
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre facturas, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor de la factura enfocada al abrir el form.
  ActualizarLabelProveedor;
  ActualizarLabelPrendas;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesFacturaCompra).
  dmmFacturasCompra.unqryFacturasCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
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
  if Assigned(dmmFacturasCompra) and
     dmmFacturasCompra.unqryFacturasCompraLineas.Active then
    ConstruirModoEntrada;
end;

function TfrmMtoFacturasCompra.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroDocumento(
    ContextoSesion, ParametrosApp, 'FACC');
end;

procedure TfrmMtoFacturasCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmFacturasCompra := TdmFacturasCompra(
    AsegurarDataModuleDocumento(
      Self, tdmDataModule, TdmFacturasCompra));
  ConfigurarTablaPrincipalDocumento(
    dmmFacturasCompra, dsTablaG, tvLineasFactura,
    dmmFacturasCompra.dsFacturasCompraLineas,
    [dmmFacturasCompra.unqryFacturasCompraLineas,
     dmmFacturasCompra.unqryEfectos],
    pkFieldName, 'SERIE_FACC;NUMERO_FACC');
  tvEfectos.DataController.DataSource := dmmFacturasCompra.dsEfectos;
  cbbFORMA_PAGO_FACC.Properties.ListSource :=
    dmmFacturasCompra.dsFormasPago;
  cbbTotalesFORMA_PAGO_FACC.Properties.ListSource :=
    dmmFacturasCompra.dsFormasPago;
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup unqryPrvDataFacc, ya cargado para el rotulo.
  cbbCODIGO_PRV_FACC.Properties.ListSource := dmmFacturasCompra.dsPrvDataFacc;
  cbbCODIGO_ALM_FACC.Properties.ListSource :=
    dmmFacturasCompra.dsAlmacenesFacc;
end;

procedure TfrmMtoFacturasCompra.FormDestroy(Sender: TObject);
begin
  LiberarModoYGestoresDocumento(
    FModoEntrada, FPivote, FGestorTallas);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoFacturasCompra.CrearColumnasTallas;
begin
  CrearColumnasTallasDocumento(tvLineasFactura, 'dbcLinFaccTalla',
    50, FTallaColumns);
end;

// Columnas no-bound y de solo lectura para el desglose visual del SKU.
procedure TfrmMtoFacturasCompra.CrearColumnasAtributos;
begin
  CrearColumnasAtributosDocumento(tvLineasFactura,
    'dbcLinFaccAtrib', FAtribColumns);
end;

procedure TfrmMtoFacturasCompra.InicializarGestorYPivote;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfigTallas: TGridTallasConfig;
  oConfigPivote: TGridPivoteCompraConfig;
begin
  if Assigned(FGestorTallas) then
    FreeAndNil(FGestorTallas);
  if Assigned(FPivote) then
    FreeAndNil(FPivote);
  if Assigned(dmmFacturasCompra) then
  begin
    oBase := Default(TConfigPivoteDocumentoCompra);
    oBase.Conexion := dmmFacturasCompra.unqryTablaG.Connection;
    oBase.ContextoSesion := ContextoSesion;
    oBase.Usuario := IdentidadSesion.Usuario;
    oBase.Vista := tvLineasFactura;
    oBase.SourceMaster := dsTablaG;
    oBase.SourceLineas :=
      dmmFacturasCompra.dsFacturasCompraLineas;
    oBase.ConsultaLineas :=
      dmmFacturasCompra.unqryFacturasCompraLineas;
    oBase.ColumnasTallas := CopiarColumnasDocumento(FTallaColumns);
    oBase.ColColorPivot := FColColorPivot;
    oBase.PrefijoCabecera := 'FACC';
    oBase.PrefijoLinea := 'FACCLIN';
    oBase.PrefijoCelda := 'FACCCEL';
    oBase.NombreTablaDocumento := 'facturas';
    oBase.AplicarContextoPivote := True;
    oConfigTallas := CrearConfigTallasDocumentoCompra(oBase);
    FGestorTallas := TGestorGridTallas.Create(oConfigTallas);
    ConfigurarEventosTallasDocumento(FTallaColumns,
      TallaEditValueChangedHook, TallaValidateHook);
    oConfigPivote := CrearConfigPivoteDocumentoCompra(oBase,
      FGestorTallas);
    FPivote := TGridPivoteCompra.Create(oConfigPivote);
  end;
end;

procedure TfrmMtoFacturasCompra.RefrescarVisibilidadTallas;
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

procedure TfrmMtoFacturasCompra.RefrescarVisibilidadAtributos;
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
procedure TfrmMtoFacturasCompra.CargarCaptionsAtributosLineaActiva;
begin
  if Assigned(dmmFacturasCompra) then
    CargarCaptionsAtributosDocumento(
      dmmFacturasCompra.unqryDefArticuloFacc,
      dmmFacturasCompra.unqryFacturasCompraLineas,
      'CODIGO_ART_FACCLIN', FAtribColumns);
end;

procedure TfrmMtoFacturasCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmFacturasCompra = nil) or (FPivote = nil) then Exit;
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

procedure TfrmMtoFacturasCompra.PersistirPreferenciaPivote;
begin
  PersistirPreferenciaPivoteDocumento(
    dsTablaG.DataSet, 'ESPIVOTE_HORIZONTAL_FACC', FPivote.Activo);
end;

procedure TfrmMtoFacturasCompra.btnImprimirHClick(Sender: TObject);
var
  form    : TfrmPrintFacCompra;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmFacturasCompra = nil then
    ShowMessage(SErrorFacturaCompraSinImpresionActiva)
  else if dmmFacturasCompra.unqryTablaG.IsEmpty then
    ShowMessage(SErrorFacturaCompraSinImpresionActiva)
  else
  begin
    if dmmFacturasCompra.unqryTablaG.State in [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryTablaG.Post;
    if dmmFacturasCompra.unqryFacturasCompraLineas.State in
       [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryFacturasCompraLineas.Post;
    sSerie  := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'SERIE_FACC').AsString;
    sNumero := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'NUMERO_FACC').AsString;
    form := TfrmPrintFacCompra.Create(Application);
    try
      form.dmFacc         := dmmFacturasCompra;
      form.edtSerie.Text  := sSerie;
      form.edtNumero.Text := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.btnImprimirVClick(Sender: TObject);
var
  form    : TfrmPrintFacCompraV;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmFacturasCompra = nil then
    ShowMessage(SErrorFacturaCompraSinImpresionActiva)
  else if dmmFacturasCompra.unqryTablaG.IsEmpty then
    ShowMessage(SErrorFacturaCompraSinImpresionActiva)
  else
  begin
    if dmmFacturasCompra.unqryTablaG.State in [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryTablaG.Post;
    if dmmFacturasCompra.unqryFacturasCompraLineas.State in
       [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryFacturasCompraLineas.Post;
    sSerie  := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'SERIE_FACC').AsString;
    sNumero := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'NUMERO_FACC').AsString;
    form := TfrmPrintFacCompraV.Create(Application);
    try
      form.dmFacc         := dmmFacturasCompra;
      form.edtSerie.Text  := sSerie;
      form.edtNumero.Text := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.btnPegatinasClick(Sender: TObject);
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  ShowMessage(SAvisoEtiquetasBorradorCompraPendientes);
end;

procedure TfrmMtoFacturasCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoFacturasCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcFactura.ActivePage := tsLineasFactura;
end;

procedure TfrmMtoFacturasCompra.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    dmmFacturasCompra.unqryTablaG.Connection,
    dmmFacturasCompra.unqryFacturasCompraLineas, 'FACCLIN');
  if (sLineasSinSku <> '') and
     (MessageDlg(Format(SPreguntaGrabarFacturaCompraSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  if Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadesPendientes;
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmFacturasCompra.CalcularTotalesFacturaCompra;
    dsTablaG.DataSet.Post;
  end;
  // Tras Grabar, cxGrid borra los Values[] no-bound al repintar.
  // RecargarYRepublicar lo solventa.
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Actualiza la cabecera y delega el modo al navegar entre facturas.
procedure TfrmMtoFacturasCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
begin
  if ((Field = nil) or SameText(Field.FieldName, 'CODIGO_EMP_FACC')) and
     Assigned(dmmFacturasCompra) and
     dmmFacturasCompra.unqryTablaG.Active and
     (not dmmFacturasCompra.unqryTablaG.IsEmpty) then
    dmmFacturasCompra.RefrescarAlmacenes(
      dmmFacturasCompra.unqryTablaG.FieldByName(
        'CODIGO_EMP_FACC').AsString);
  // Refrescar el rotulo del proveedor al navegar entre facturas (Field=nil)
  // o al cambiar CODIGO_PRV_FACC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_FACC') then
    ActualizarLabelProveedor;
  // Al navegar entre facturas hay que recalcular el total de prendas: las
  // lineas cargadas son las de la factura recien enfocada.
  if Field = nil then
    ActualizarLabelPrendas;
  if Assigned(dmmFacturasCompra) then
    ActualizarModoEntradaAlNavegarDocumento(
      Field, dmmFacturasCompra.unqryFacturasCompraLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel, True,
      ConstruirModoEntrada,
      dmmFacturasCompra.DesempaquetarAtributosLineas);
end;

procedure TfrmMtoFacturasCompra.ActualizarLabelProveedor;
begin
  if Assigned(dmmFacturasCompra) then
    lblProveedorNombreFacc.Caption := TextoProveedorDocumento(
      dmmFacturasCompra.unqryTablaG,
      dmmFacturasCompra.unqryPrvDataFacc,
      'CODIGO_PRV_FACC')
  else
    lblProveedorNombreFacc.Caption := '';
end;

procedure TfrmMtoFacturasCompra.ActualizarLabelPrendas;
begin
  if Assigned(dmmFacturasCompra) then
    lblTotalPrendasFacc.Caption := TextoTotalPrendasDocumento(
      dmmFacturasCompra.unqryTablaG,
      dmmFacturasCompra.TotalPrendasFactura)
  else
    lblTotalPrendasFacc.Caption := '0';
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesFacturaCompra) con la republicacion del controlador.
procedure TfrmMtoFacturasCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmFacturasCompra) then
    dmmFacturasCompra.CalcularTotalesFacturaCompra;
  ActualizarLabelPrendas;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla y, si "atributo por columna" esta activo, recargamos los nombres
// de atributo del articulo activo.
procedure TfrmMtoFacturasCompra.tvLineasFacturaFocusedRecordChanged(
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
procedure TfrmMtoFacturasCompra.tvLineasFacturaCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

// Bloqueo de edicion en celdas talla fuera del conjunto — delegamos en lib.
procedure TfrmMtoFacturasCompra.tvLineasFacturaEditing(
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
procedure TfrmMtoFacturasCompra.cxgrdLineasFacturaEnter(Sender: TObject);
begin
  inherited;
  EntrarGridLineasDocumento(
    Self, FColsModoConstruido, False, FModoEntrada,
    AsegurarPrimeraLineaFacturaCompra, ConstruirModoEntrada);
end;

procedure TfrmMtoFacturasCompra.cxgrdLineasFacturaExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoFacturasCompra.ActualizarCaptionModoLineas;
begin
  tsLineasFactura.Caption := CaptionModoLineasDocumento(
    'Líneas', 'Líneas ', FColsModoConstruido,
    FModoEntradaSel, False);
end;

procedure TfrmMtoFacturasCompra.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcFactura.ActivePage = tsLineasFactura) and
    (dmmFacturasCompra <> nil), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasHorPed], ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoFacturasCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  ds: TDataSet;
  bDegradarASku: Boolean;
  ModoEfectivo: TModoColumnasSku;
begin
  if (dmmFacturasCompra = nil) or (csDestroying in ComponentState) then
    Exit;
  ds := dmmFacturasCompra.unqryFacturasCompraLineas;
  if not ds.Active then
    Exit;
  PrepararReconstruccionModoDocumento(tvLineasFactura, ds,
    FModoEntrada, FTallaColumns, FAtribColumns, FColColorPivot);
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _FACCLIN; idempotente por linea). SKU y tallas
  // horizontal derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmFacturasCompra.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    dmmFacturasCompra.unqryTablaG.Connection,
    ContextoSesion, tvLineasFactura, ds, FModoEntradaSel,
    Trim(dmmFacturasCompra.unqryTablaG.
      FieldByName('CODIGO_ALM_FACC').AsString), 'FACCLIN');
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := CrearConfigPivoteBandasDocumentoCompra(
      dmmFacturasCompra.unqryTablaG.Connection,
      IdentidadSesion.Usuario, dsTablaG,
      dmmFacturasCompra.dsFacturasCompraLineas,
      'FACC', 'FACCLIN',
      'PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN',
      CANT_TALLAS_MAX);
    // Factura de compra: UNA sola cantidad por linea -> banda unica.
    CfgPV.BandaUnica := True;
    // La columna Total del host pasa a UNIDADES del grupo en pivote.
    CfgPV.FieldTotalUdsGrupo := 'TOTAL_FACCLIN';
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
    [mcsTallasHorPed], 'FacturasCompra');
  if bDegradarASku then
  begin
    // Reconstruccion completa en SKU: el teardown de la reentrada
    // limpia lo que el pivote dejara a medias. Maximo una reentrada.
    FModoEntradaSel := mcsSku;
    ConstruirModoEntrada;
  end
  else
  begin
    CrearColumnasHostFacturaCompra;
    // Rotulo por modo EFECTIVO (Auto puede degradar a SKU si faltan
    // las columnas ATTR en la BBDD) y, en desglose, mostrar Color y
    // Talla con nombres globales desde el principio (patron albaranes
    // de compra).
    ModoEfectivo := DetectarModoColumnasSku(Cfg);
    tsLineasFactura.Caption := CaptionModoLineasDocumento(
      'Líneas', 'Líneas ', True, ModoEfectivo, False);
    if not (ModoEfectivo in [mcsSku, mcsTallasHorPed]) then
      MostrarColumnasAtributoGlobalesFacc;
  end;
end;

procedure TfrmMtoFacturasCompra.MostrarColumnasAtributoGlobalesFacc;
begin
  MostrarColumnasAtributoGlobalesDocumento(
    dmmFacturasCompra.unqryTablaG.Connection,
    tvLineasFactura);
end;

procedure TfrmMtoFacturasCompra.CrearColumnasHostFacturaCompra;
var
  Columnas: TColumnasHostDocumentoCompra;
begin
  Columnas := CrearColumnasHostDocumentoCompra(
    tvLineasFactura, FModoEntradaSel, 'FACCLIN');
  if Assigned(Columnas.ColCantidad) then
    VincularCantidadGrid(Columnas.ColCantidad,
      Columnas.ColTipoCantidad);
  Columnas.ColPrecioCompra.PropertiesClass :=
    TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(
    Columnas.ColPrecioCompra.Properties).DisplayFormat :=
    '#,##0.00 €';
end;

procedure TfrmMtoFacturasCompra.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo clasico de la factura de compra (precio de compra del
  // proveedor, IVA, modelo proveedor...) se reaprovecha tal cual:
  // AplicarArticuloFacturaCompra acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloFacturaCompra(ASku);
end;

procedure TfrmMtoFacturasCompra.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloFacturaCompra(ACodigoSku);
end;

procedure TfrmMtoFacturasCompra.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoFacturasCompra.TallaEditValueChangedHook(Sender: TObject);
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

procedure TfrmMtoFacturasCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

procedure TfrmMtoFacturasCompra.AsegurarCabeceraPersistidaParaLineas;
begin
  if not Assigned(dmmFacturasCompra) then
    raise Exception.Create(SErrorFacturaCompraNoInicializada)
  else
    AsegurarCabeceraPersistidaCompra(
      dmmFacturasCompra.unqryTablaG,
      dmmFacturasCompra.unqryFacturasCompraLineas,
      CrearConfiguracionTallasCompra(
        'una factura', 'FACC', 'FACCLIN',
        'fza_facturas_compra_lineas'),
      nil);
end;

procedure TfrmMtoFacturasCompra.AsegurarPrimeraLineaFacturaCompra;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if not Assigned(dmmFacturasCompra) then
    Exit;
  dsCab := dmmFacturasCompra.unqryTablaG;
  dsLin := dmmFacturasCompra.unqryFacturasCompraLineas;
  if (dsCab = nil) or (dsLin = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    Exit;
  AsegurarCabeceraPersistidaParaLineas;
  sNumero := Trim(dsCab.FieldByName('NUMERO_FACC').AsString);
  sSerie  := Trim(dsCab.FieldByName('SERIE_FACC').AsString);
  if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
    Exit;
  if not dsLin.Active then
    dsLin.Open;
  if dsLin.IsEmpty and (not (dsLin.State in dsEditModes)) then
    dsLin.Append;
end;

function TfrmMtoFacturasCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
  if Assigned(dmmFacturasCompra) and Assigned(FPivote) then
    Result := PuedeActivarTallasHorizontalCompra(
      dmmFacturasCompra.unqryTablaG,
      dmmFacturasCompra.unqryFacturasCompraLineas,
      dmmFacturasCompra.unqryTablaG.Connection,
      CrearConfiguracionTallasCompra(
        'una factura', 'FACC', 'FACCLIN',
        'fza_facturas_compra_lineas'),
      AsegurarCabeceraPersistidaParaLineas,
      FPivote.ValidarPivotePosible, AMensaje);
end;

procedure TfrmMtoFacturasCompra.AplicarArticuloFacturaCompra(
  const ACodigoArt: string);
var
  ds         : TDataSet;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
  Datos      : TArticuloDatos;
  qry        : TUniQuery;
  sInput     : string;
  sPrv       : string;
  sAlm       : string;
  sModeloPrv : string;
  dFecha     : TDateTime;
  iAcPivot   : Integer;
  rCantidad  : Double;

  function CampoCabeceraString(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := dmmFacturasCompra.unqryTablaG.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function FechaCabecera: TDateTime;
  var
    Campo: TField;
  begin
    Result := Date;
    Campo := dmmFacturasCompra.unqryTablaG.FindField('FECHA_FACC');
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsDateTime;
  end;

  function ResolverConjuntoPivotArticulo(
    const ACodigoArticulo: string): Integer;
  begin
    Result := 0;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmFacturasCompra.unqryTablaG.Connection;
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
      qry.Connection := dmmFacturasCompra.unqryTablaG.Connection;
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
    colSku := tvLineasFactura.GetColumnByFieldName('CODIGO_UNIDAD_FACCLIN');
    if colSku <> nil then
    begin
      colSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasFactura.Controller.FocusedColumn := colSku;
          tvLineasFactura.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            colLineaFaccCODIGO_UNIDADPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmFacturasCompra) and
     (not FAplicandoArticulo) then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    ds := dmmFacturasCompra.unqryFacturasCompraLineas;
    if Assigned(ds) and ds.Active then
    begin
      FAplicandoArticulo := True;
      Validador := nil;
      Resolver := nil;
      try
        if ds.IsEmpty then
          ds.Append;
        if not (ds.State in dsEditModes) then
          ds.Edit;
        sPrv := CampoCabeceraString('CODIGO_PRV_FACC');
        sAlm := CampoCabeceraString('CODIGO_ALM_FACC');
        dFecha := FechaCabecera;
        Validador := TArticulosValidador.Create(
                       dmmFacturasCompra.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmFacturasCompra.unqryTablaG.Connection,
                      ParametrosCaja);
        Resolucion := Validador.Resolver(sInput);
        if Resolucion.Encontrado then
        begin
          Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo,
                                          Resolucion.CodigoSku,
                                          '',
                                          dFecha,
                                          sAlm,
                                          sPrv);
          if Datos.Encontrado then
          begin
            if Datos.RequiereSku then
              Datos.UltimoCoste := Resolver.ResolverUltimoCoste(
                Datos.CodigoArticulo, sPrv, '');
            iAcPivot := ResolverConjuntoPivotArticulo(Datos.CodigoArticulo);
            sModeloPrv := ModeloProveedorArticulo(Datos.CodigoArticulo, sPrv);
            if sModeloPrv = '' then
              sModeloPrv := Datos.UltimoCoste.RefProveedor;
            PonerString('CODIGO_ART_FACCLIN', Datos.CodigoArticulo);
            PonerString('CODIGO_UNIDAD_FACCLIN', Datos.CodigoSku);
            PonerString('REF_PRV_FACCLIN', sModeloPrv);
            PonerString('CODIGO_FAM_FACCLIN', Datos.CodigoFamilia);
            PonerString('NOMBRE_FAM_FACCLIN', Datos.DescripcionFamilia);
            PonerString('DESCRIPCION_ARTICULO_FACCLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_FACCLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_FACCLIN', Datos.TipoIVA);
            if sAlm <> '' then
              PonerString('CODIGO_ALMACEN_FACCLIN', sAlm);
            if iAcPivot > 0 then
              PonerInteger('ID_AC_PIVOT_FACCLIN', iAcPivot)
            else
              LimpiarCampo('ID_AC_PIVOT_FACCLIN');
            rCantidad := 0;
            if ds.FindField('CANTIDAD_FACCLIN') <> nil then
              rCantidad := ds.FieldByName('CANTIDAD_FACCLIN').AsFloat;
            if Datos.RequiereSku and (Datos.CodigoSku = '') then
            begin
              PonerFloat('CANTIDAD_FACCLIN', 0);
              PonerFloat('TOTAL_UNIDADES_FACCLIN', 0);
              rCantidad := 0;
            end
            else if rCantidad = 0 then
            begin
              rCantidad := 1;
              PonerFloat('CANTIDAD_FACCLIN', rCantidad);
              PonerFloat('TOTAL_UNIDADES_FACCLIN', rCantidad);
            end
            else
              PonerFloat('TOTAL_UNIDADES_FACCLIN', rCantidad);
            PonerFloat('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN',
                       Datos.UltimoCoste.PrecioUltCompra);
            PonerFloat('TOTAL_FACCLIN',
                       rCantidad * Datos.UltimoCoste.PrecioUltCompra);
            PrepararLineaFiscalCompra(
              dmmFacturasCompra.unqryTablaG.Connection,
              dmmFacturasCompra.unqryTablaG, ds, 'FACC', 'FACCLIN',
              'TOTAL_FACCLIN');
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
            if Assigned(FPivote) and FPivote.Activo and
               (ds.State in dsEditModes) then
              ds.Post;
          end
          else if Datos.Mensaje <> '' then
            MessageDlg(Datos.Mensaje, mtWarning, [mbOk], 0);
        end
        else if Resolucion.Mensaje <> '' then
          MessageDlg(Resolucion.Mensaje, mtWarning, [mbOk], 0);
      finally
        FreeAndNil(Resolver);
        FreeAndNil(Validador);
        FAplicandoArticulo := False;
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.colLineaFaccCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloFacturaCompra;
  if sCodigo <> '' then
    AplicarArticuloFacturaCompra(sCodigo);
end;

procedure TfrmMtoFacturasCompra.colLineaFaccCODIGO_ARTPropertiesValidate(
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
      AplicarArticuloFacturaCompra(sCodigo);
      if Assigned(dmmFacturasCompra) and
         dmmFacturasCompra.unqryFacturasCompraLineas.Active and
         (dmmFacturasCompra.unqryFacturasCompraLineas.
            FindField('CODIGO_ART_FACCLIN') <> nil) then
        DisplayValue := dmmFacturasCompra.unqryFacturasCompraLineas.
                          FieldByName('CODIGO_ART_FACCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.colLineaFaccCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaFacturaCompra;
  sSku := BuscarSkuFacturaCompra(sArt);
  if sSku <> '' then
    AplicarArticuloFacturaCompra(sSku);
end;

procedure TfrmMtoFacturasCompra.colLinFaccColorPivotButtonClick(
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
    sArt := ArticuloLineaActivaFacturaCompra;
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

procedure TfrmMtoFacturasCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasFactura.DataController.DataSet,
    'CODIGO_ART_FACCLIN');
end;

procedure TfrmMtoFacturasCompra.actIrProveedorExecute(Sender: TObject);
begin
  if Assigned(dmmFacturasCompra) then
    ShowMtoCodigoDataSet(Self.Owner, 'Proveedores',
      dmmFacturasCompra.unqryTablaG, 'CODIGO_PRV_FACC')
  else
    ShowMto(Self.Owner, 'Proveedores');
end;

procedure TfrmMtoFacturasCompra.cbbCODIGO_PRV_FACCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  // Al cargar/cambiar el proveedor, precarga su forma de pago en la cabecera.
  if (Assigned(dmmFacturasCompra) and Assigned(dsTablaG.DataSet) and
      ((dsTablaG.DataSet.State = dsInsert) or
       (dsTablaG.DataSet.State = dsEdit))) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := VarToStr(e.EditingValue);
    dmmFacturasCompra.CargarFormaPagoProveedor(sCodigo);
  end;
  ActualizarLabelProveedor;
end;

// Boton "..." del combo de proveedor: busqueda modal por nombre/razon
// social, acceso alternativo a la busqueda incremental por codigo del
// propio combo.
procedure TfrmMtoFacturasCompra.cbbCODIGO_PRV_FACCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmFacturasCompra) then
  begin
    ds := dmmFacturasCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg(SErrorFacturaCompraElegirProveedorNoSeleccionada,
                 mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
      ConexionPrincipal,
      'Búsqueda de proveedores',
              'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
              'CODIGO_PRV_PRV',
              sCodigo,
              'frmMtoFaccProvSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_PRV_FACC').AsString := sCodigo;
      dmmFacturasCompra.CargarFormaPagoProveedor(sCodigo);
      ActualizarLabelProveedor;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.cbbCODIGO_PRV_FACCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_FACCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoFacturasCompra.btnGenerarEfectosClick(Sender: TObject);
var
  iRes: Integer;
  sEmp, sPrv, sPref: string;
  selBanco: TSeleccionBancoResult;
begin
  inherited;
  if Assigned(dmmFacturasCompra) then
  begin
    // Cuenta de la empresa (cargo) para el pago: eleccion manual, con el
    // banco por defecto del proveedor pre-seleccionado si lo tiene.
    sEmp  := dsTablaG.DataSet.FieldByName('CODIGO_EMP_FACC').AsString;
    sPrv  := dsTablaG.DataSet.FieldByName('CODIGO_PRV_FACC').AsString;
    sPref := dmmFacturasCompra.GetBancoDefectoProveedor(sPrv);
    selBanco := TfrmModalSeleccionarBanco.Ejecutar(Self, ConexionPrincipal,
                                                   sEmp, ubePago, sPref);
    if not selBanco.Aceptado then
      ShowMessage(SInfoGeneracionEfectosPagoCancelada)
    else
    begin
      iRes := dmmFacturasCompra.GenerarEfectos(selBanco.CodigoEmpban,
                                               selBanco.Iban);
      if iRes > 0 then
        ShowMessage(Format(SInfoEfectosPagoGenerados, [iRes]))
      else if iRes = 0 then
        ShowMessage(SAvisoEfectosPagoNoGenerados)
      else
        ShowMessage(SErrorGenerarEfectosPagoSinBorrador);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.btnRegistrarPagoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe, iRes: Integer;
  fPend: Double;
begin
  inherited;
  if Assigned(dmmFacturasCompra) and
     (dmmFacturasCompra.unqryEfectos <> nil) and
     dmmFacturasCompra.unqryEfectos.Active and
     (not dmmFacturasCompra.unqryEfectos.IsEmpty) then
  begin
    q     := dmmFacturasCompra.unqryEfectos;
    iEfe  := q.FieldByName('NUMERO_EFEC').AsInteger;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    frm := TfrmModalRegistrarPago.Create(nil);
    try
      frm.SetDatos(
        Format('Efecto %d - vto %s - pendiente %.2f',
          [iEfe,
           FormatDateTime('dd/mm/yyyy',
             q.FieldByName('FECHA_VENCIMIENTO_EFEC').AsDateTime),
           fPend]),
        fPend);
      if frm.ShowModal = mrOk then
      begin
        iRes := dmmFacturasCompra.RegistrarPagoEfecto(iEfe, frm.Fecha,
                  frm.Importe, frm.Tipo, frm.Referencia);
        if iRes > 0 then
          ShowMessage(SInfoEfectoConciliado)
        else
          ShowMessage(SErrorConciliarEfecto);
      end;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage(SErrorEfectoCompraNoSeleccionado);
end;

procedure TfrmMtoFacturasCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  dmmFacturasCompra.unqryFacturasCompraLineas.Append;
end;

procedure TfrmMtoFacturasCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg(SPreguntaEliminarLineaFacturaCompra,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmFacturasCompra.unqryFacturasCompraLineas.Delete;
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasCompra);
end.
