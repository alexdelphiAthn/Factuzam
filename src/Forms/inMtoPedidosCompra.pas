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
  Forms, Dialogs, Uni, System.Generics.Collections,
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
  UniDataPedidosCompra, cxBlobEdit, System.Actions, Vcl.ActnList, dxShellDialogs;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;

type
  TfrmMtoPedidosCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcPedido:            TcxPageControl;
    tsLineasPedido:      TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    pnlBottomTotales:    TPanel;
    cxgrdLineasPedido:   TcxGrid;
    tvLineasPedido:      TcxGridDBTableView;
    cxgrdlvlLineasPedido: TcxGridLevel;

    // Cabecera
    lblNroPedido:    TcxLabel;
    txtNUMERO_PEDC:  TcxDBTextEdit;
    lblSeriePedido:  TcxLabel;
    txtSERIE_PEDC:   TcxDBTextEdit;
    lblFechaPedido:  TcxLabel;
    dteFECHA_PEDC:   TcxDBDateEdit;
    lblFechaPrevista:TcxLabel;
    dteFECHA_PREVISTA_PEDC: TcxDBDateEdit;
    lblEstadoPedido: TcxLabel;
    txtESTADO_PEDC:  TcxDBTextEdit;
    lblCodigoEmpresa:   TcxLabel;
    btnCODIGO_EMP_PEDC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    btnCODIGO_PRV_PEDC: TcxDBButtonEdit;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_PEDC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_PEDC: TcxDBTextEdit;
    lblTemporada:       TcxLabel;
    cbbTemporadaPedc:   TcxDBLookupComboBox;

    // Totales
    lblTotalBases:           TcxLabel;
    curTOTAL_BASES_PEDC:     TcxDBCurrencyEdit;
    lblTotalImpuestos:       TcxLabel;
    curTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit;
    lblTotalLiquido:         TcxLabel;
    curTOTAL_LIQUIDO_PEDC:   TcxDBCurrencyEdit;

    // Observaciones
    memObservaciones: TcxDBMemo;
    btnTallasHorizontal:  TcxButton;
    btnAtributosColumna:  TcxButton;
    btnExpandirRecibidos: TcxButton;
    // Atajo: rellena 'A recibir' con el pendiente de TODAS las
    // tallas de la fila focused. Activo solo en pivote expandido.
    btnRecibirFilaEntera: TcxButton;
    // Columna no-bound editable solo en modo vertical (pivote OFF).
    // El usuario teclea aqui "A recibir" por linea SKU. Se oculta
    // cuando entra en modo pivote.
    colLineaPedcARecibir: TcxGridDBColumn;
    btnCrearAlbaran: TcxButton;
    lblContextoTalla: TcxLabel;
    ActionList1: TActionList;
    actArticulos: TAction;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
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
    // Guarda contra la reentrancia que provoca PersistirPreferenciaPivote:
    // su Edit + set field + Post dispara OnDataChange tres veces, y entre
    // el Edit y el set la cabecera todavia tiene el ESPIVOTE viejo. Sin
    // este guardia el hook auto-toggle veria "field='N' y Activo=True"
    // y desactivaria justo despues de activar.
    FInToggleClick   : Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterOpenHook(DataSet: TDataSet);
    procedure PersistirPreferenciaPivote;
    function  RecogerCeldasARecibirVertical(
                                const ACodigoAlm: string): TArray<TCeldaARecibir>;
    // Hook unificado para OnEditValueChanged de columnas talla: en
    // pivote expandido captura el valor en el dict de la libreria
    // (persistencia frente a Post de cxGrid); en el resto de modos
    // delega en el gestor de tallas como antes.
    procedure TallaEditValueChangedHook(Sender: TObject);
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
    // ApplyBestFit + ensanche para la columna Color (el cuadradito de
    // color que pinta FColColorPivot ocupa ~20 px que BestFit no mide).
    procedure BestFitConSwatch;
  public
    dmmPedidosCompra: TdmPedidosCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoPedidosCompra: TfrmMtoPedidosCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFotos,
  inLibAtributosPaleta,
  inLibPedidosCompra,
  inMtoModalSelAlmacenPedido, inLibShowMto;

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

procedure TfrmMtoPedidosCompra.FormCreate(Sender: TObject);
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
  FColColorPivot.Options.Editing := False;
  FColColorProveedorPivot := nil;
  inherited;
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
  // Hook OnDataChange del master: al cambiar de pedido activo, el
  // controlador recarga su cache y republica.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Hook AfterPost del detail: cxGrid borra los Values[] no-bound al
  // repintar tras Post; encadenamos totales del DM + recarga del
  // controlador.
  dmmPedidosCompra.unqryPedidosCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  // Hook AfterOpen del detail: al abrir el cursor (al entrar al form y
  // cada vez que cambia el pedido master) hacemos ApplyBestFit para que
  // las columnas se ajusten al contenido y no salgan truncadas como
  // "Verde botel..." o "MARRO chocolat...".
  dmmPedidosCompra.unqryPedidosCompraLineas.AfterOpen :=
                                             unqryLineasAfterOpenHook;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoPedidosCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  inherited;
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
  cfgT.Conexion           := inLibGlobalVar.oConn;
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
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnEditValueChanged := TallaEditValueChangedHook;
  // 2. Orquestador de pivote (libreria nueva compartida con albaranes).
  cfgP := Default(TGridPivoteCompraConfig);
  cfgP.Conexion             := inLibGlobalVar.oConn;
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
      if not FPivote.ValidarPivotePosible(sMensaje) then
      begin
        // Sender=nil => apertura automatica con la preferencia por
        // defecto (horizontal). Si el documento no es pivotable dejamos
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
      if not FPivote.ValidarPivotePosible(sMensaje) then
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
  if iCeldas = 0 then
    MessageDlg('No hay tallas pendientes de recibir en la fila activa.',
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
  if Field <> nil then Exit;
  if FPivote = nil then Exit;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) and
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil) then
  begin
    // Por defecto la vista es horizontal: solo un 'N' explicito
    // (excepcion que el usuario guardo a mano) la mantiene vertical.
    // NULL / vacio / 'S' abren en horizontal.
    bDeberiaEstarActivo :=
      dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString <> 'N';
    if bDeberiaEstarActivo and (not FPivote.Activo) then
      btnTallasHorizontalClick(nil)
    else if (not bDeberiaEstarActivo) and FPivote.Activo then
      btnTallasHorizontalClick(nil);
  end;
  if not FPivote.Activo then Exit;
  // RecargarYRepublicar ya hace RecalcularMaxColumnas + Captions
  // ANTES de publicar. Llamar a RefrescarVisibilidadTallas aqui haria
  // un segundo RecalcularMax tras publicar y limpiaria los Values[]
  // recien puestos.
  FPivote.RecargarYRepublicar;
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (totales) con la republicacion de Values[] no-bound del controlador.
procedure TfrmMtoPedidosCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmPedidosCompra) then
    dmmPedidosCompra.CalcularTotalesPedidoCompra;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Hook AfterOpen del detail: cada vez que se abre el cursor (entrar al
// form o navegar a otro pedido) ajustamos el ancho de columnas al
// contenido. Asi no salen textos truncados como "Verde botel" o
// "rón choc" en la columna Color.
procedure TfrmMtoPedidosCompra.unqryLineasAfterOpenHook(DataSet: TDataSet);
begin
  if tvLineasPedido <> nil then
    BestFitConSwatch;
end;

// ApplyBestFit estandar + ensanche manual de la columna Color: el
// custom-draw de FColColorPivot pinta un cuadradito de color de
// ANCHO_SWATCH_PX (~20 px) ANTES del texto, y ApplyBestFit solo mide
// el ancho del texto. Sin este ajuste la columna Color queda recortada
// (se ve "ERD" en vez de "VERDE", etc) cuando hay swatch.
procedure TfrmMtoPedidosCompra.BestFitConSwatch;
begin
  if tvLineasPedido = nil then Exit;
  tvLineasPedido.ApplyBestFit;
  if Assigned(FColColorPivot) and FColColorPivot.Visible then
    FColColorPivot.Width := FColColorPivot.Width + ANCHO_SWATCH_PX;
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
  if Assigned(FPivote) and FPivote.Activo and FPivote.Expandido then
    FPivote.CapturarARecibirEditValueChanged(Sender)
  else if Assigned(FGestorTallas) then
    FGestorTallas.PersistirCeldaActiva(Sender);
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

procedure TfrmMtoPedidosCompra.btnCrearAlbaranClick(Sender: TObject);
var
  form: TfrmModalSelAlmacenPedido;
  sSerie, sNumero, sNumAlb, sMsg: string;
  bOk: Boolean;
  bTxOwned: Boolean;
  arrCeldas: TArray<TCeldaARecibir>;
  bUsarCeldas: Boolean;
  recIdx: Integer;
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
    form.SerieAlbDefecto      := sSerie;  // default = misma serie
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
      if bOk then
      begin
        if bTxOwned then inLibGlobalVar.oConn.Commit;
        ShowMessage(sMsg);
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
        dmmPedidosCompra.unqryTablaG.Refresh;
        dmmPedidosCompra.unqryPedidosCompraLineas.Refresh;
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
