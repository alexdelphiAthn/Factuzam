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
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni, System.Generics.Collections, System.Types,
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
  UniDataPedidosCompra, cxBlobEdit, System.Actions, Vcl.ActnList,
  dxShellDialogs, cxSplitter;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;
  ID_VA_COLOR     = 'CO';
  // Ancho (px) de cada columna talla en modo pivote. Tambien actua de
  // suelo tras ApplyBestFit: el BestFit mide solo el Value numerico corto
  // de la celda y, al ignorar el custom-draw (rotulo de talla + sub-cifras
  // Pedido/Recibido/A recibir), dejaria las columnas tan estrechas que el
  // rotulo de 2 digitos (p.ej. "36") se corta a "3".
  ANCHO_TALLA_PX  = 50;

type
  TfrmMtoPedidosCompra = class(TfrmMtoGen)
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
    FAplicandoArticulo      : Boolean;
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
                                const ACodigoAlm: string): TArray<TCeldaARecibir>;
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
  public
    dmmPedidosCompra: TdmPedidosCompra;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoPedidosCompra: TfrmMtoPedidosCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFiltroUsuario,
  inLibFotos,
  inLibAtributosPaleta,
  inLibPedidosCompra,
  inLibLog,
  inLibtb,
  inLibArticulosResolver,
  inLibArticulosValidador,
  inLibComprasImpuestos,
  inMtoModalSelAlmacenPedido, inMtoModalDocsCreados, inMtoModalEtiqPed,
  inLibShowMto, inLibGenBusq, UniDataArticulos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// dsTablaG apunta a la cabecera del pedido de compra. El articulo
// activo vive en la fila del sub-grid tvLineasPedido
// (CODIGO_ART_PEDCLIN / CODIGO_UNIDAD_PEDCLIN).
procedure TfrmMtoPedidosCompra.ResolverArtSkuActivo(out ACodArt,
                                                    ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasPedido.DataController.DataSource) then
  begin
    ds := tvLineasPedido.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// pedido, ademas de dsTablaG (cabecera) enganchamos
// dsPedidosCompraLineas.
function TfrmMtoPedidosCompra.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmPedidosCompra) then
    Result := [dsTablaG, dmmPedidosCompra.dsPedidosCompraLineas]
  else
    Result := [dsTablaG];
end;

function TfrmMtoPedidosCompra.BuscarArticuloPedidoCompra: string;
var
  qry : TUniQuery;
  sPrv: string;
begin
  Result := '';
  if Assigned(dmmPedidosCompra) then
  begin
    sPrv := Trim(dmmPedidosCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_PEDC').AsString);
    if (sPrv = '') or (sPrv = '0') then
      MessageDlg('Selecciona un proveedor antes de buscar artículos.',
                 mtInformation, [mbOk], 0)
    else
    begin
      qry := TUniQuery.Create(nil);
      try
        qry.Connection := dmmPedidosCompra.unqryTablaG.Connection;
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
        if TBusquedaUtils.EjecutarBusqueda(
             'Búsqueda de artículos',
             qry,
             'frmMtoDevcArtSearch',
             Self) and (qry.FindField('CODIGO_ART_ART') <> nil) then
          Result := qry.FieldByName('CODIGO_ART_ART').AsString;
      finally
        FreeAndNil(qry);
      end;
    end;
  end;
end;

function TfrmMtoPedidosCompra.ArticuloLineaActivaPedidoCompra: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmPedidosCompra) then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_PEDCLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_PEDCLIN').AsString);
  end;
end;

function TfrmMtoPedidosCompra.BuscarSkuPedidoCompra(
  const ACodigoArt: string): string;
var
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmPedidosCompra) then
    MessageDlg('No está abierto el pedido de compra.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmPedidosCompra.unqryTablaG.Connection;
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
           'frmMtoPedcSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.AsegurarCabeceraPersistidaParaLineas;
var
  dsCab  : TDataSet;
  dsLin  : TDataSet;
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
    Result := (ValorLinea('CODIGO_ART_PEDCLIN') = '') and
              (ValorLinea('CODIGO_UNIDAD_PEDCLIN') = '');
  end;

  procedure SincronizarCabeceraEnLinea;
  begin
    if Assigned(dsLin) and dsLin.Active and
       (dsLin.State in dsEditModes) then
    begin
      if dsLin.FindField('NUMERO_PEDC_PEDCLIN') <> nil then
        dsLin.FieldByName('NUMERO_PEDC_PEDCLIN').AsString :=
          dsCab.FieldByName('NUMERO_PEDC').AsString;
      if dsLin.FindField('SERIE_PEDC_PEDCLIN') <> nil then
        dsLin.FieldByName('SERIE_PEDC_PEDCLIN').AsString :=
          dsCab.FieldByName('SERIE_PEDC').AsString;
    end;
  end;

begin
  if not Assigned(dmmPedidosCompra) then
    raise Exception.Create('No esta inicializado el pedido de compra.')
  else
  begin
    dsCab := dmmPedidosCompra.unqryTablaG;
    dsLin := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (dsCab = nil) or (not dsCab.Active) or
       (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
      raise Exception.Create(
        'Crea o selecciona un pedido antes de añadir lineas.');
    sNumero := Trim(dsCab.FieldByName('NUMERO_PEDC').AsString);
    if Assigned(dsLin) and dsLin.Active and (dsLin.State = dsInsert) and
       ((sNumero = '') or (sNumero = '0')) and LineaActualVacia then
      dsLin.Cancel;
    if (dsCab.State in dsEditModes) or (sNumero = '') or
       (sNumero = '0') then
    begin
      if not (dsCab.State in dsEditModes) then
        dsCab.Edit;
      if (dsCab.FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil) and
         (Trim(dsCab.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString) = '')
         then
        dsCab.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString := 'N';
      dsCab.Post;
    end;
    SincronizarCabeceraEnLinea;
    if Assigned(dsLin) and dsLin.Active and
       (not (dsLin.State in dsEditModes)) then
    begin
      dsLin.Close;
      dsLin.Open;
    end;
  end;
end;

function TfrmMtoPedidosCompra.PuedeActivarTallasHorizontal(
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
    Result := (ValorLinea('CODIGO_ART_PEDCLIN') <> '') or
              (ValorLinea('CODIGO_UNIDAD_PEDCLIN') <> '');
  end;

  function LineaActualTieneSistemaTallas: Boolean;
  var
    Campo: TField;
  begin
    Result := False;
    Campo := dsLin.FindField('ID_AC_PIVOT_PEDCLIN');
    if Campo <> nil then
      Result := (not Campo.IsNull) and (Campo.AsInteger > 0);
  end;

begin
  Result := False;
  AMensaje := '';
  if (dmmPedidosCompra = nil) or (FPivote = nil) then
    Result := True
  else
  begin
    dsCab := dmmPedidosCompra.unqryTablaG;
    dsLin := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (dsCab = nil) or (not dsCab.Active) or dsCab.IsEmpty then
      AMensaje := 'Crea o selecciona un pedido antes de activar tallas.'
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
      sNumero := Trim(dsCab.FieldByName('NUMERO_PEDC').AsString);
      if (sNumero = '') or (sNumero = '0') then
        AsegurarCabeceraPersistidaParaLineas;
      sSerie := Trim(dsCab.FieldByName('SERIE_PEDC').AsString);
      sNumero := Trim(dsCab.FieldByName('NUMERO_PEDC').AsString);
      incidencias := TStringList.Create;
      q := TUniQuery.Create(nil);
      try
        q.Connection := dmmPedidosCompra.unqryTablaG.Connection;
        q.SQL.Text :=
          'SELECT DISTINCT L.CODIGO_ART_PEDCLIN AS ART ' +
          '  FROM fza_pedidos_compra_lineas L ' +
          ' WHERE L.SERIE_PEDC_PEDCLIN = :serie ' +
          '   AND L.NUMERO_PEDC_PEDCLIN = :numero ' +
          '   AND COALESCE(TRIM(L.CODIGO_ART_PEDCLIN), '''') <> '''' ' +
          '   AND (L.ID_AC_PIVOT_PEDCLIN IS NULL ' +
          '        OR L.ID_AC_PIVOT_PEDCLIN = 0) ' +
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

procedure TfrmMtoPedidosCompra.AplicarArticuloPedidoCompra(
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
    Campo := dmmPedidosCompra.unqryTablaG.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function FechaCabecera: TDateTime;
  var
    Campo: TField;
  begin
    Result := Date;
    Campo := dmmPedidosCompra.unqryTablaG.FindField('FECHA_PEDC');
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsDateTime;
  end;

  function ResolverConjuntoPivotArticulo(
    const ACodigoArticulo: string): Integer;
  begin
    Result := 0;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmPedidosCompra.unqryTablaG.Connection;
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
      qry.Connection := dmmPedidosCompra.unqryTablaG.Connection;
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
    colSku := tvLineasPedido.GetColumnByFieldName('CODIGO_UNIDAD_PEDCLIN');
    if colSku <> nil then
    begin
      colSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasPedido.Controller.FocusedColumn := colSku;
          tvLineasPedido.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            colLineaPedcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmPedidosCompra) and
     (not FAplicandoArticulo) then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
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
        sPrv := CampoCabeceraString('CODIGO_PRV_PEDC');
        sAlm := CampoCabeceraString('CODIGO_ALM_PEDC');
        dFecha := FechaCabecera;
        Validador := TArticulosValidador.Create(
                       dmmPedidosCompra.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmPedidosCompra.unqryTablaG.Connection);
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
            PonerString('CODIGO_ART_PEDCLIN', Datos.CodigoArticulo);
            PonerString('CODIGO_UNIDAD_PEDCLIN', Datos.CodigoSku);
            PonerString('REF_PRV_PEDCLIN', sModeloPrv);
            PonerString('CODIGO_FAM_PEDCLIN', Datos.CodigoFamilia);
            PonerString('DESCRIPCION_ARTICULO_PEDCLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_PEDCLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_PEDCLIN', Datos.TipoIVA);
            if sAlm <> '' then
              PonerString('CODIGO_ALMACEN_PEDCLIN', sAlm);
            if iAcPivot > 0 then
              PonerInteger('ID_AC_PIVOT_PEDCLIN', iAcPivot)
            else
              LimpiarCampo('ID_AC_PIVOT_PEDCLIN');
            rCantidad := 0;
            if ds.FindField('CANTIDAD_PEDCLIN') <> nil then
              rCantidad := ds.FieldByName('CANTIDAD_PEDCLIN').AsFloat;
            if Datos.RequiereSku and (Datos.CodigoSku = '') then
            begin
              PonerFloat('CANTIDAD_PEDCLIN', 0);
              PonerFloat('TOTAL_UNIDADES_PEDCLIN', 0);
              rCantidad := 0;
            end
            else if rCantidad = 0 then
            begin
              rCantidad := 1;
              PonerFloat('CANTIDAD_PEDCLIN', rCantidad);
              PonerFloat('TOTAL_UNIDADES_PEDCLIN', rCantidad);
            end;
            PonerFloat('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN',
                       Datos.UltimoCoste.PrecioUltCompra);
            PonerFloat('TOTAL_PEDCLIN',
                       rCantidad * Datos.UltimoCoste.PrecioUltCompra);
            PrepararLineaFiscalCompra(
              dmmPedidosCompra.unqryTablaG.Connection,
              dmmPedidosCompra.unqryTablaG, ds, 'PEDC', 'PEDCLIN',
              'TOTAL_PEDCLIN');
            if Assigned(FPivote) then
            begin
              if iAcPivot <= 0 then
              begin
                if FPivote.Activo then
                  btnTallasHorizontalClick(nil);
              end
              else if CampoCabeceraString('ESPIVOTE_HORIZONTAL_PEDC') <> 'N'
              then
              begin
                if not FPivote.Activo then
                  btnTallasHorizontalClick(nil);
                if FPivote.Activo then
                begin
                  if ds.State in dsEditModes then
                    ds.Post;
                  FPivote.RecargarYRepublicar;
                end;
              end;
            end;
            if Datos.RequiereSku and (Datos.CodigoSku = '') and
               ((FPivote = nil) or (not FPivote.Activo)) then
              EnfocarSku(True);
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

procedure TfrmMtoPedidosCompra.FormCreate(Sender: TObject);
var
  colSku: TcxGridDBColumn;
  i     : Integer;
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
  FColColorPivot := tvLineasPedido.CreateColumn;
  FColColorPivot.Name    := 'colLinPedcColorPivot';
  FColColorPivot.Caption := 'Color';
  FColColorPivot.Width   := 130;
  FColColorPivot.Visible := False;
  FColColorPivot.Options.Editing := True;
  FColColorPivot.Options.ShowEditButtons := isebAlways;
  FColColorPivot.PropertiesClass := TcxButtonEditProperties;
  with TcxButtonEditProperties(FColColorPivot.Properties) do
  begin
    Buttons.Clear;
    with Buttons.Add do
      Kind := bkEllipsis;
    OnButtonClick := colLinPedcColorPivotButtonClick;
  end;
  FColColorProveedorPivot := nil;
  inherited;
  FEstiloRecepcionVencida := TcxStyle.Create(Self);
  FEstiloRecepcionVencida.AssignedValues := [svTextColor];
  FEstiloRecepcionVencida.TextColor := clRed;
  for i := 0 to cxGrdDBTabPrin.ItemCount - 1 do
    cxGrdDBTabPrin.Items[i].Styles.OnGetContentStyle :=
      GridListaGetContentStyle;
  colSku := tvLineasPedido.GetColumnByFieldName('CODIGO_UNIDAD_PEDCLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := colLineaPedcCODIGO_UNIDADPropertiesButtonClick;
      OnValidate := colLineaPedcCODIGO_UNIDADPropertiesValidate;
    end;
  end;
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
end;

procedure TfrmMtoPedidosCompra.FormDestroy(Sender: TObject);
begin
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
  if (dmmPedidosCompra = nil) or (colLineaPedcARecibir = nil) then
    Exit;
  ds := dmmPedidosCompra.unqryPedidosCompraLineas;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
    Exit;
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

function TfrmMtoPedidosCompra.TotalAAlbaranar: Double;
begin
  Result := 0;
  if Assigned(FPivote) and FPivote.Activo then
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

function TfrmMtoPedidosCompra.SqlRestriccionUsuario: string;
begin
  // Documentos de compra: empresa y almacén (no llevan caja)
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_PEDC', 'CODIGO_ALM_PEDC', '');
end;

procedure TfrmMtoPedidosCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmPedidosCompra := (tdmDataModule as TdmPedidosCompra);
  if not Assigned(dmmPedidosCompra) then
  begin
    dmmPedidosCompra := TdmPedidosCompra.Create(Self);
    dsTablaG.DataSet := dmmPedidosCompra.unqryTablaG;
    tdmDataModule := dmmPedidosCompra;
  end;
  tvLineasPedido.DataController.DataSource :=
    dmmPedidosCompra.dsPedidosCompraLineas;
  dmmPedidosCompra.unqryPedidosCompraLineas.MasterSource := dsTablaG;
  tvAlbaranesPedc.DataController.DataSource :=
    dmmPedidosCompra.dsAlbaranesPedc;
  cbbTotalesFORMA_PAGO_PEDC.Properties.ListSource :=
    dmmPedidosCompra.dsFormasPago;
  cbbCODIGO_ALM_PEDC.Properties.ListSource :=
    dmmPedidosCompra.dsAlmacenesPedc;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PEDC);
  dmmPedidosCompra.unqryAlbaranesPedc.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_PEDC;NUMERO_PEDC';
end;

procedure TfrmMtoPedidosCompra.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineasPedido.CreateColumn;
    col.Name    := 'dbcLinPedcTalla' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := ANCHO_TALLA_PX;
    col.Tag     := i + 1;
    col.Visible := False;
    col.DataBinding.ValueTypeClass := TcxFloatValueType;
    col.PropertiesClass := TcxCurrencyEditProperties;
    curProps := TcxCurrencyEditProperties(col.Properties);
    curProps.DisplayFormat := '#,##0';
    FTallaColumns[i] := col;
  end;
end;

procedure TfrmMtoPedidosCompra.CrearColumnasAtributos;
var
  i: Integer;
  col: TcxGridDBColumn;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
  begin
    col := tvLineasPedido.CreateColumn;
    col.Name    := 'dbcLinPedcAtrib' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 90;
    col.Tag     := -(i + 1);  // tag negativo para no chocar con tallas
    col.Visible := False;
    col.Options.Editing := False;
    FAtribColumns[i] := col;
  end;
end;

procedure TfrmMtoPedidosCompra.CargarBasicosColorArticulo(
  const ACodigoArt: string);
var
  q   : TUniQuery;
  i   : Integer;
  sArt: string;
begin
  SetLength(FBasicosColor, 0);
  sArt := Trim(ACodigoArt);
  if sArt <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := inLibGlobalVar.oConn;
      q.SQL.Text :=
        'SELECT ATB.CODIGO_ATB, MIN(ATB.ORDEN_ATB) AS ORDEN_ATB, ' +
        '       MIN(ATB.NOMBRE_ATB) AS NOMBRE_ATB ' +
        '  FROM fza_articulos_skus SK ' +
        '  JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = SA.ID_AV_SA ' +
        '   AND AV.ID_VA_AV = :va ' +
        '  JOIN fza_atributos_basicos ATB ' +
        '    ON ATB.ID_VA_ATB = :va ' +
        '   AND (ATB.ID_ATB = AV.ID_ATB_AV ' +
        '        OR (AV.ID_ATB_AV IS NULL AND ATB.CODIGO_ATB = AV.AV)) ' +
        ' WHERE SK.CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        '   AND COALESCE(AV.ESACTIVO_AV, ''S'') = ''S'' ' +
        '   AND COALESCE(ATB.ESACTIVO_ATB, ''S'') = ''S'' ' +
        ' GROUP BY ATB.CODIGO_ATB ' +
        ' ORDER BY ORDEN_ATB, NOMBRE_ATB, ATB.CODIGO_ATB';
      q.ParamByName('va').AsString := ID_VA_COLOR;
      q.ParamByName('art').AsString := sArt;
      q.Open;
      SetLength(FBasicosColor, q.RecordCount);
      i := 0;
      while not q.Eof do
      begin
        FBasicosColor[i] := q.FieldByName('CODIGO_ATB').AsString;
        Inc(i);
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.InicializarGestorYPivote;
var
  cfgT : TGridTallasConfig;
  cfgP : TGridPivoteCompraConfig;
  i    : Integer;
  arr  : TArray<TcxGridDBColumn>;
begin
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if FPivote       <> nil then FreeAndNil(FPivote);
  if dmmPedidosCompra = nil then Exit;
  SetLength(arr, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arr[i] := FTallaColumns[i];
  // 1. Gestor inline de tallas (libreria existente).
  cfgT := Default(TGridTallasConfig);
  cfgT.Conexion           := dmmPedidosCompra.unqryTablaG.Connection;
  cfgT.Usuario            := oUser;
  cfgT.Grid               := tvLineasPedido;
  cfgT.SourceMaster       := dsTablaG;
  cfgT.SourceLineas       := dmmPedidosCompra.dsPedidosCompraLineas;
  cfgT.ColumnasTallas     := arr;
  cfgT.FieldSerieMaster   := 'SERIE_PEDC';
  cfgT.FieldNumeroMaster  := 'NUMERO_PEDC';
  cfgT.FieldLinea         := 'LINEA_PEDCLIN';
  cfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_PEDCLIN';
  cfgT.FieldPrecioBase    := 'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN';
  cfgT.FieldTotalUds      := 'TOTAL_UNIDADES_PEDCLIN';
  cfgT.FieldTotalLinea    := 'TOTAL_PEDCLIN';
  cfgT.TablaCeldas        := 'fza_pedidos_compra_celdas';
  cfgT.FieldSerieCel      := 'SERIE_PEDC_PEDCCEL';
  cfgT.FieldNumeroCel     := 'NUMERO_PEDC_PEDCCEL';
  cfgT.FieldLineaCel      := 'LINEA_PEDC_PEDCCEL';
  cfgT.FieldFilaCel       := 'ID_FILA_PEDC_PEDCCEL';
  cfgT.FieldAvPivotCel    := 'ID_AV_PIVOT_PEDCCEL';
  cfgT.FieldCantidadCel   := 'CANTIDAD_PEDCCEL';
  cfgT.FieldAlmacenCel    := 'CODIGO_ALM_PEDCCEL';
  cfgT.IdFilaFijo         := 1;
  cfgT.MaxColumnas        := CANT_TALLAS_MAX;
  FGestorTallas := TGestorGridTallas.Create(cfgT);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
    begin
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnEditValueChanged := TallaEditValueChangedHook;
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnValidate := TallaValidateHook;
    end;
  // 2. Orquestador de pivote (libreria nueva compartida con albaranes).
  cfgP := Default(TGridPivoteCompraConfig);
  cfgP.Conexion             := dmmPedidosCompra.unqryTablaG.Connection;
  cfgP.Grid                 := tvLineasPedido;
  cfgP.SourceMaster         := dsTablaG;
  cfgP.SourceLineas         := dmmPedidosCompra.unqryPedidosCompraLineas;
  cfgP.Gestor               := FGestorTallas;
  cfgP.ColColorPivot          := FColColorPivot;
  cfgP.ColColorProveedorPivot := FColColorProveedorPivot;
  cfgP.ColumnasTallas       := arr;
  cfgP.MaxColumnasTallas    := CANT_TALLAS_MAX;
  cfgP.TablaLineas          := 'fza_pedidos_compra_lineas';
  cfgP.FieldSerieMaster     := 'SERIE_PEDC';
  cfgP.FieldNumeroMaster    := 'NUMERO_PEDC';
  cfgP.FieldSerieLin        := 'SERIE_PEDC_PEDCLIN';
  cfgP.FieldNumeroLin       := 'NUMERO_PEDC_PEDCLIN';
  cfgP.FieldLinea           := 'LINEA_PEDCLIN';
  cfgP.FieldArt             := 'CODIGO_ART_PEDCLIN';
  cfgP.FieldSku             := 'CODIGO_UNIDAD_PEDCLIN';
  cfgP.FieldCantidad        := 'CANTIDAD_PEDCLIN';
  cfgP.FieldPrecioBase      := 'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN';
  cfgP.FieldTotalUds        := 'TOTAL_UNIDADES_PEDCLIN';
  cfgP.FieldTotalLinea      := 'TOTAL_PEDCLIN';
  cfgP.FieldCantidadRecibida:= 'CANTIDAD_RECIBIDA_PEDCLIN';
  cfgP.FieldCantidadRecibida:= 'CANTIDAD_RECIBIDA_PEDCLIN';
  cfgP.FieldIdAcPivot       := 'ID_AC_PIVOT_PEDCLIN';
  cfgP.FieldAlmacen         := 'CODIGO_ALMACEN_PEDCLIN';
  cfgP.FieldAlmacenMaster   := 'CODIGO_ALM_PEDC';
  // FieldColorTexto solo si la columna existe en BBDD. Asi no crasheamos
  // si el usuario aun no ha aplicado el ALTER de pedidos_compra.sql que
  // anyade COLOR_TEXTO_PEDCLIN.
  if ColumnaPedidosCompraExiste('COLOR_TEXTO_PEDCLIN') then
    cfgP.FieldColorTexto    := 'COLOR_TEXTO_PEDCLIN';
  cfgP.CamposOcultosEnPivote := TArray<string>.Create(
    'CODIGO_UNIDAD_PEDCLIN',
    'CANTIDAD_PEDCLIN',
    'CANTIDAD_RECIBIDA_PEDCLIN',
    'TOTAL_PEDCLIN');
  FPivote := TGridPivoteCompra.Create(cfgP);
end;

procedure TfrmMtoPedidosCompra.RefrescarVisibilidadTallas;
var
  i: Integer;
begin
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

procedure TfrmMtoPedidosCompra.RefrescarVisibilidadAtributos;
var
  i: Integer;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Visible := FMostrarAtributos;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributo del articulo de la linea con foco y los
// aplica como captions de las columnas ATTRn. La carga de VALORES por
// SKU queda como TODO (hito posterior).
procedure TfrmMtoPedidosCompra.CargarCaptionsAtributosLineaActiva;
var
  i: Integer;
  sArt: string;
  qry: TUniQuery;
  iCol: Integer;
begin
  if dmmPedidosCompra = nil then Exit;
  qry := dmmPedidosCompra.unqryDefArticuloPedc;
  if qry = nil then Exit;
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Caption := 'Atributo ' + IntToStr(i + 1);
  if (dmmPedidosCompra.unqryPedidosCompraLineas = nil) or
     (not dmmPedidosCompra.unqryPedidosCompraLineas.Active) or
     (dmmPedidosCompra.unqryPedidosCompraLineas.IsEmpty) then Exit;
  sArt := dmmPedidosCompra.unqryPedidosCompraLineas.
            FieldByName('CODIGO_ART_PEDCLIN').AsString;
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

procedure TfrmMtoPedidosCompra.PersistirPreferenciaPivote;
begin
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty or
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_PEDC') = nil) then
    Exit;
  if not (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
    dsTablaG.DataSet.Edit;
  dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString :=
    IfThen(FPivote.Activo, 'S', 'N');
  dsTablaG.DataSet.Post;
end;

procedure TfrmMtoPedidosCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmPedidosCompra = nil) or (FPivote = nil) then Exit;
  // Guardia de reentrada: bloquea el auto-toggle del data-change hook
  // mientras PersistirPreferenciaPivote esta editando+posting la cabecera.
  // Sin esto, el Edit dispara OnDataChange con la cabecera todavia con
  // el valor viejo, el hook ve discrepancia con Activo y vuelve a llamar
  // a este handler.
  if FInToggleClick then Exit;
  FInToggleClick := True;
  try
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
    // La columna no-bound "A recibir" se ve en modo vertical y se
    // oculta en pivote (en horizontal la entrada de cantidades se
    // hace celda a celda en las columnas talla, no en una columna
    // aparte).
    if Assigned(colLineaPedcARecibir) then
      colLineaPedcARecibir.Visible := not FPivote.Activo;
    // BestFit tras togglear: ajustamos automaticamente el ancho de
    // todas las columnas al contenido. Sin esto algunas (Color con
    // textos largos como "Verde botella", articulo, descripcion...)
    // quedan truncadas.
    BestFitConSwatch;
    // Sender=nil: llamada automatica desde el data-change hook, no
    // re-escribir la preferencia en la cabecera.
    if Sender <> nil then
      PersistirPreferenciaPivote;
  finally
    FInToggleClick := False;
  end;
end;

procedure TfrmMtoPedidosCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

// Toggle del modo "Expandir recibidos": solo aplica con el pivote
// activo. Si no esta, lo activamos primero. Pivote inactivo -> activar
// pivote primero y luego expandir.
procedure TfrmMtoPedidosCompra.btnExpandirRecibidosClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmPedidosCompra = nil) or (FPivote = nil) then Exit;
  if not FPivote.PuedeExpandir then
  begin
    ShowMessage('El pedido no soporta expandir recibidos.');
    Exit;
  end;
  if FPivote.Expandido then
    FPivote.Contraer
  else
  begin
    // Si el pivote no esta activo, lo activamos primero.
    if not FPivote.Activo then
    begin
      if not PuedeActivarTallasHorizontal(sMensaje) then
      begin
        MessageDlg(sMensaje, mtWarning, [mbOk], 0);
        Exit;
      end;
      FPivote.Activar;
      PersistirPreferenciaPivote;
      // BestFit tras activar el pivote.
      BestFitConSwatch;
    end;
    FPivote.Expandir;
  end;
  // BestFit tras toggle de Expandir/Contraer: con la altura nueva las
  // columnas a veces se rompen si el grid recalcula widths antes que
  // heights. Forzamos el ajuste final aqui.
  BestFitConSwatch;
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
  begin
    MessageDlg('Activa "Expandir recibidos" antes de usar este atajo.',
               mtInformation, [mbOk], 0);
    Exit;
  end;
  iCeldas := FPivote.RecibirFilaEntera;
  RefrescarCantidadAAlbaranar;
  if iCeldas = 0 then
    MessageDlg('No hay tallas pendientes de recibir en la fila activa.',
               mtInformation, [mbOk], 0);
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
  if (dmmPedidosCompra = nil) or (FPivote = nil) then
    Exit;
  iRellenadas := 0;
  if FPivote.Activo then
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
    MessageDlg('No hay nada pendiente de recibir en el pedido.',
               mtInformation, [mbOk], 0);
end;

procedure TfrmMtoPedidosCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidosCompra.btnGrabarClick(Sender: TObject);
begin
  if inLibLog.Log <> nil then
    inLibLog.Log.LogInfo('PedidosCompra.btnGrabarClick: INICIO');
  if Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadesPendientes;
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmPedidosCompra.CalcularTotalesPedidoCompra;
    dsTablaG.DataSet.Post;
  end;
  // Tras Grabar, cxGrid borra los Values[] no-bound al repintar.
  // RecargarYRepublicar lo solventa.
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
  RefrescarCantidadAAlbaranar;
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
var
  bDeberiaEstarActivo: Boolean;
begin
  // Refrescar el rotulo del proveedor al navegar entre pedidos (Field=nil)
  // o al cambiar CODIGO_PRV_PEDC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_PEDC') then
    ActualizarLabelProveedor;
  if Field <> nil then Exit;
  if FPivote = nil then
  begin
    RefrescarCantidadAAlbaranar;
    Exit;
  end;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) and
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil) then
  begin
    if dsTablaG.DataSet.State = dsInsert then
    begin
      if FPivote.Activo then
        btnTallasHorizontalClick(nil);
      RefrescarCantidadAAlbaranar;
      Exit;
    end;
    bDeberiaEstarActivo :=
      dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString <> 'N';
    if bDeberiaEstarActivo and (not FPivote.Activo) then
      btnTallasHorizontalClick(nil)
    else if (not bDeberiaEstarActivo) and FPivote.Activo then
      btnTallasHorizontalClick(nil);
  end;
  if not FPivote.Activo then
  begin
    RefrescarCantidadAAlbaranar;
    Exit;
  end;
  // RecargarYRepublicar ya hace RecalcularMaxColumnas + Captions
  // ANTES de publicar. Llamar a RefrescarVisibilidadTallas aqui haria
  // un segundo RecalcularMax tras publicar y limpiaria los Values[]
  // recien puestos.
  FPivote.RecargarYRepublicar;
  RefrescarCantidadAAlbaranar;
end;

procedure TfrmMtoPedidosCompra.ActualizarLabelProveedor;
var
  sCodigo : string;
  sNombre : string;
  sRazon  : string;
begin
  // Resuelve NOMBRE_PRV + RAZON_SOCIAL_PRV (via el lookup unqryPrvDataPedc)
  // y los pinta en el rotulo. Se antepone el nombre comercial: es el que
  // el usuario reconoce a simple vista; la razon social solo se anade
  // entre parentesis como referencia si difiere.
  sCodigo := '';
  if (dmmPedidosCompra <> nil) and Assigned(dmmPedidosCompra.unqryTablaG) and
     dmmPedidosCompra.unqryTablaG.Active and
     (not dmmPedidosCompra.unqryTablaG.IsEmpty) then
    sCodigo :=
      Trim(dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_PRV_PEDC').AsString);
  if sCodigo = '' then
    lblProveedorNombrePedc.Caption := ''
  else if (dmmPedidosCompra.unqryPrvDataPedc <> nil) and
          dmmPedidosCompra.unqryPrvDataPedc.Active and
          dmmPedidosCompra.unqryPrvDataPedc.Locate('CODIGO_PRV_PRV', sCodigo, []) then
  begin
    sRazon  := dmmPedidosCompra.unqryPrvDataPedc.FieldByName('RAZON_SOCIAL_PRV').AsString;
    sNombre := dmmPedidosCompra.unqryPrvDataPedc.FieldByName('NOMBRE_PRV').AsString;
    // Si no hay nombre comercial cargado, caemos a la razon social como
    // rotulo principal. Si hay nombre y difiere de la razon social, la
    // razon social se anade entre parentesis como referencia.
    if Trim(sNombre) = '' then
      lblProveedorNombrePedc.Caption := sCodigo + ' - ' + sRazon
    else if not SameText(Trim(sNombre), Trim(sRazon)) then
      lblProveedorNombrePedc.Caption :=
        sCodigo + ' - ' + sNombre + '  (' + sRazon + ')'
    else
      lblProveedorNombrePedc.Caption := sCodigo + ' - ' + sNombre;
  end
  else
    lblProveedorNombrePedc.Caption := sCodigo + ' - (proveedor no encontrado)';
end;

// Hook AfterPost del detail: encadena la logica original del DM con la
// republicacion de Values[] no-bound del controlador.
procedure TfrmMtoPedidosCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FAfterPostLineasOriginal) then
    FAfterPostLineasOriginal(DataSet)
  else if Assigned(dmmPedidosCompra) then
    dmmPedidosCompra.CalcularTotalesPedidoCompra;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
  RefrescarCantidadAAlbaranar;
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
  if tvLineasPedido = nil then Exit;
  tvLineasPedido.ApplyBestFit;
  if Assigned(FColColorPivot) and FColColorPivot.Visible then
    FColColorPivot.Width := FColColorPivot.Width + ANCHO_SWATCH_PX;
  // Suelo de ancho para las columnas talla: ApplyBestFit las mide por el
  // Value numerico corto e ignora el custom-draw (rotulo de talla +
  // sub-cifras), dejandolas tan estrechas que el rotulo "36"/"38" se corta
  // a "3". Restauramos el ancho minimo legible sin impedir que BestFit las
  // ensanche cuando el contenido lo pida.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if Assigned(FTallaColumns[i]) and FTallaColumns[i].Visible and
       (FTallaColumns[i].Width < ANCHO_TALLA_PX) then
      FTallaColumns[i].Width := ANCHO_TALLA_PX;
end;

// Comprueba via INFORMATION_SCHEMA si una columna existe en
// fza_pedidos_compra_lineas. Lo usamos para activar features
// (FieldColorTexto, etc.) solo si el ALTER correspondiente de
// pedidos_compra.sql se ha aplicado.
function TfrmMtoPedidosCompra.ColumnaPedidosCompraExiste(
                                       const ANombreColumna: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME   = ''fza_pedidos_compra_lineas'' ' +
      '   AND COLUMN_NAME  = :c';
    q.ParamByName('c').AsString := ANombreColumna;
    q.Open;
    Result := q.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoPedidosCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
    with tvLineasPedido.DataController.DataSet do
      ShowMto(Self.Owner,
              'Articulos',
              FieldByName('CODIGO_ART_PEDCLIN').AsString);
end;

procedure TfrmMtoPedidosCompra.actIrProveedorExecute(Sender: TObject);
var
  sPrv: string;
begin
  sPrv := '';
  if Assigned(dmmPedidosCompra) and
     (not dmmPedidosCompra.unqryTablaG.IsEmpty) then
    sPrv := Trim(dmmPedidosCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_PEDC').AsString);
  if sPrv = '' then
    ShowMto(Self.Owner, 'Proveedores')
  else
    ShowMto(Self.Owner, 'Proveedores', sPrv);
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    ds := dmmPedidosCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg('Crea o selecciona un pedido de compra antes de ' +
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
      ds.FieldByName('CODIGO_EMP_PEDC').AsString := sCodigo;
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
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    ds := dmmPedidosCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg('Crea o selecciona un pedido de compra antes de ' +
                 'elegir el proveedor.', mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
              'Búsqueda de proveedores',
              'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
              'CODIGO_PRV_PRV',
              sCodigo,
              'frmMtoPedcProvSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_PRV_PEDC').AsString := sCodigo;
      AplicarIvaExentoIntracomunitarioProveedor(inLibGlobalVar.oConn, ds,
        'CODIGO_PRV_PEDC', 'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC');
      dmmPedidosCompra.CalcularTotalesPedidoCompra;
      ActualizarLabelProveedor;
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
  if not Assigned(dmmPedidosCompra) then
    Exit;
  dsCab := dmmPedidosCompra.unqryTablaG;
  dsLin := dmmPedidosCompra.unqryPedidosCompraLineas;
  if (dsCab = nil) or (dsLin = nil) or (not dsCab.Active) or
     (dsCab.IsEmpty and not (dsCab.State in dsEditModes)) then
    Exit;
  AsegurarCabeceraPersistidaParaLineas;
  sNumero := Trim(dsCab.FieldByName('NUMERO_PEDC').AsString);
  sSerie  := Trim(dsCab.FieldByName('SERIE_PEDC').AsString);
  if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
    Exit;
  if not dsLin.Active then
    dsLin.Open;
  if dsLin.IsEmpty and (not (dsLin.State in dsEditModes)) then
    dsLin.Append;
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
    MessageDlg('Activa las tallas en horizontal antes de elegir color.',
               mtInformation, [mbOk], 0);
  end
  else
  begin
    sArt := ArticuloLineaActivaPedidoCompra;
    if sArt = '' then
      MessageDlg('Selecciona un artículo antes de elegir color.',
                 mtInformation, [mbOk], 0)
    else
    begin
      CargarBasicosColorArticulo(sArt);
      if Length(FBasicosColor) = 0 then
        MessageDlg('El artículo "' + sArt + '" no tiene colores básicos ' +
                   'activos en sus SKUs.',
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
        if SeleccionarAvConPaleta(ID_VA_COLOR, FBasicosColor, sActual,
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
var
  sSerie, sNumero: string;
begin
  inherited;
  if (pcPedido.ActivePage = tsAlbaranesPedc) and
     (dmmPedidosCompra <> nil) and
     dmmPedidosCompra.unqryAlbaranesPedc.Active and
     (not dmmPedidosCompra.unqryAlbaranesPedc.IsEmpty) then
  begin
    sSerie  := Trim(dmmPedidosCompra.unqryAlbaranesPedc.
                      FieldByName('SERIE_ALBC').AsString);
    sNumero := Trim(dmmPedidosCompra.unqryAlbaranesPedc.
                      FieldByName('NUMERO_ALBC').AsString);
    if (sSerie <> '') and (sNumero <> '') then
      ShowMto(Self.Owner, 'AlbaranesCompra', sSerie + ',' + sNumero);
  end;
end;

function TfrmMtoPedidosCompra.AlmacenEfectivoPrimeraLinea(
                                  const ASerie, ANumero: string): string;
var
  q: TUniQuery;
begin
  Result := '';
  if (Trim(ASerie) = '') or (Trim(ANumero) = '') then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) AS ALM ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      ' ORDER BY L.LINEA_PEDCLIN ' +
      ' LIMIT 1';
    q.ParamByName('s').AsString := ASerie;
    q.ParamByName('n').AsString := ANumero;
    q.Open;
    if not q.Eof then
      Result := q.FieldByName('ALM').AsString;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoPedidosCompra.tvLineasPedidoFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if Assigned(FGestorTallas) and Assigned(FPivote) and FPivote.Activo then
    FGestorTallas.ActualizarCaptionsLineaActiva;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
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
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
  AsegurarPrimeraLineaPedidoCompra;
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
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
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
  if (dmmPedidosCompra = nil) or (colLineaPedcARecibir = nil) then Exit;
  ds := dmmPedidosCompra.unqryPedidosCompraLineas;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then Exit;
  sAlmCab := dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
  idxCol := colLineaPedcARecibir.Index;
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
          Result := sAlmLin
        else
          Result := sAlmCab;
        Exit;
      end;
      Inc(recIdx);
      ds.Next;
    end;
  finally
    if Assigned(bk) then ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
  end;
end;

function TfrmMtoPedidosCompra.RecogerCeldasARecibirVertical(
                                  const ACodigoAlm: string): TArray<TCeldaARecibir>;
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
  if (dmmPedidosCompra = nil) or (colLineaPedcARecibir = nil) then Exit;
  ds := dmmPedidosCompra.unqryPedidosCompraLineas;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then Exit;
  sAlmCab := dmmPedidosCompra.unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
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
  if (dmmPedidosCompra = nil) or (colLineaPedcARecibir = nil) then
    Exit;
  ds := dmmPedidosCompra.unqryPedidosCompraLineas;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
    Exit;
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
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
  CargarSeriesEmpresa(sEmpresa, 'PC', cbbSERIE_PEDC.Properties.Items);
  if cbbSERIE_PEDC.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de pedidos de compra (tipo PC) para la ' +
                  'empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
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
  if dmmPedidosCompra = nil then
    Exit;
  if dmmPedidosCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay pedido de compra activo.');
    Exit;
  end;
  if dmmPedidosCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmPedidosCompra.unqryTablaG.Post;
  if dmmPedidosCompra.unqryPedidosCompraLineas.State in [dsEdit, dsInsert] then
    dmmPedidosCompra.unqryPedidosCompraLineas.Post;
  sSerie  := dmmPedidosCompra.unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := dmmPedidosCompra.unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  dmArt := TdmArticulos.Create(nil);
  try
    form := TfrmPrintEtiqPed.Create(Application);
    try
      form.DMArt  := dmArt;
      form.DMPedc := dmmPedidosCompra;
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

procedure TfrmMtoPedidosCompra.btnCrearAlbaranClick(Sender: TObject);
var
  form: TfrmModalSelAlmacenPedido;
  sSerie, sNumero, sNumAlb, sMsg: string;
  bOk: Boolean;
  bTxOwned: Boolean;
  arrCeldas: TArray<TCeldaARecibir>;
  bUsarCeldas: Boolean;
  recIdx: Integer;
  frmDocs: TfrmModalDocsCreados;
  sSerieDoc, sNumeroDoc: string;
begin
  inherited;
  if dmmPedidosCompra = nil then Exit;
  if dmmPedidosCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay pedido activo del que crear albaran.');
    Exit;
  end;
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
      dmmPedidosCompra.unqryTablaG.FieldByName('ID_PV_TEMPORADA_PEDC').AsInteger;
    // Almacen por defecto del modal: el de la primera celda con
    // cantidad 'A recibir' > 0 (sea en pivote expandido o en modo
    // vertical). Si el usuario no ha tecleado nada todavia, caemos al
    // almacen efectivo de la primera linea del pedido como fallback.
    if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
      form.CodigoAlmacenDefecto := FPivote.PrimerAlmacenARecibir
    else
      form.CodigoAlmacenDefecto := PrimerAlmacenARecibirVertical;
    if Trim(form.CodigoAlmacenDefecto) = '' then
      form.CodigoAlmacenDefecto :=
        AlmacenEfectivoPrimeraLinea(sSerie, sNumero);
    form.ShowModal;
    if not form.Aceptado then Exit;
    if Trim(form.CodigoAlmacen) = '' then Exit;
    // Decidir flujo: si el pivote esta expandido leemos celdas via lib;
    // si no, miramos la columna "A recibir" del modo vertical. Si no
    // hay tecleos en ninguno, caemos al flujo clasico (pendientes
    // totales del almacen).
    if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
      arrCeldas := FPivote.IterarARecibirPorAlmacen(form.CodigoAlmacen)
    else
      arrCeldas := RecogerCeldasARecibirVertical(form.CodigoAlmacen);
    bUsarCeldas := Length(arrCeldas) > 0;
    bTxOwned := not inLibGlobalVar.oConn.InTransaction;
    if bTxOwned then inLibGlobalVar.oConn.StartTransaction;
    try
      if form.Incorporar then
      begin
        // Incorporar las lineas a un albaran existente del pedido.
        if bUsarCeldas then
          bOk := inLibPedidosCompra.IncorporarAlbaranDesdePedidoConCantidades(
                  inLibGlobalVar.oConn, sSerie, sNumero, form.CodigoAlmacen,
                  form.AlbaranSerieDestino, form.AlbaranNumDestino, oUser,
                  form.IdPvTemporada, arrCeldas, sMsg)
        else
          bOk := inLibPedidosCompra.IncorporarAlbaranDesdePedido(
                  inLibGlobalVar.oConn, sSerie, sNumero, form.CodigoAlmacen,
                  form.AlbaranSerieDestino, form.AlbaranNumDestino, oUser,
                  form.IdPvTemporada, sMsg);
      end
      else
      begin
        // Crear un albaran nuevo (flujo clasico).
        if bUsarCeldas then
          bOk := inLibPedidosCompra.CrearAlbaranDesdePedidoConCantidades(
                  inLibGlobalVar.oConn, sSerie, sNumero, form.CodigoAlmacen,
                  form.SerieAlbaran, oUser,
                  form.RefProveedor, form.FechaRecepcion, form.IdPvTemporada,
                  arrCeldas, sNumAlb, sMsg)
        else
          bOk := inLibPedidosCompra.CrearAlbaranDesdePedido(
                  inLibGlobalVar.oConn, sSerie, sNumero, form.CodigoAlmacen,
                  form.SerieAlbaran, oUser,
                  form.RefProveedor, form.FechaRecepcion, form.IdPvTemporada,
                  sNumAlb, sMsg);
      end;
      if bOk then
      begin
        if bTxOwned then inLibGlobalVar.oConn.Commit;
        // Limpiar las celdas "A recibir" tecleadas para el almacen
        // procesado, para que el usuario pueda seguir con otro almacen
        // sin tener que borrar manualmente.
        if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
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
        // el albaran recien creado / incorporado (es detail del pedido,
        // no se refresca solo al hacer Refresh del master).
        if dmmPedidosCompra.unqryAlbaranesPedc.Active then
          dmmPedidosCompra.unqryAlbaranesPedc.Close;
        dmmPedidosCompra.unqryAlbaranesPedc.Open;
        // Mostrar el albaran recien creado / incorporado en un modal
        // estilo Sesiones, con boton "Ir a documento" para abrir su
        // ficha. En modo incorporar el destino es el albaran existente
        // (Albaran...Destino); si no, el nuevo (SerieAlbaran / sNumAlb).
        if form.Incorporar then
        begin
          sSerieDoc  := form.AlbaranSerieDestino;
          sNumeroDoc := form.AlbaranNumDestino;
        end
        else
        begin
          sSerieDoc  := form.SerieAlbaran;
          sNumeroDoc := sNumAlb;
        end;
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
      begin
        if bTxOwned then inLibGlobalVar.oConn.Rollback;
        MessageDlg(sMsg, mtWarning, [mbOk], 0);
      end;
    except
      on E: Exception do
      begin
        if bTxOwned and inLibGlobalVar.oConn.InTransaction then
          inLibGlobalVar.oConn.Rollback;
        MessageDlg('Error al crear el albaran: ' + E.Message,
                   mtError, [mbOk], 0);
      end;
    end;
  finally
    FreeAndNil(form);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoPedidosCompra);
end.
