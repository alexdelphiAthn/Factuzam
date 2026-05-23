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
{    lugar de cliente, precio de compra en lugar de venta). No genera          }
{    aun factura ni movimientos de stock; eso vendra en hitos                  }
{    posteriores.                                                              }
{******************************************************************************}
unit inMtoAlbaranesCompra;

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
  UniDataAlbaranesCompra, cxBlobEdit, dxShellDialogs;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;

type
  TfrmMtoAlbaranesCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcAlbaran:           TcxPageControl;
    tsLineasAlbaran:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    pnlBottomTotales:    TPanel;
    cxgrdLineasAlbaran:  TcxGrid;
    tvLineasAlbaran:     TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;

    // Cabecera
    lblNroAlbaran:    TcxLabel;
    txtNUMERO_ALBC:   TcxDBTextEdit;
    lblSerieAlbaran:  TcxLabel;
    txtSERIE_ALBC:    TcxDBTextEdit;
    lblFechaAlbaran:  TcxLabel;
    dteFECHA_ALBC:    TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_ALBC:   TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALBC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    btnCODIGO_PRV_ALBC: TcxDBButtonEdit;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_ALBC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_ALBC: TcxDBTextEdit;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_ALBC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_ALBC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_ALBC: TcxDBCurrencyEdit;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de accion
    btnAnadirLinea:       TcxButton;
    btnBorrarLinea:       TcxButton;
    btnTallasHorizontal:  TcxButton;
    btnAtributosColumna:  TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
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
  private
    FGestorTallas    : TGestorGridTallas;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarTallas    : Boolean;
    FMostrarAtributos : Boolean;
    // ----- Estado del modo pivote -----
    // Cuando FMostrarTallas=True, el detail se filtra para mostrar solo una
    // linea representante por (articulo + color) y las cantidades de cada
    // SKU del grupo se publican en las celdas talla no-bound del grid. La
    // estructura subyacente de fza_albaranes_compra_lineas (1 fila por SKU)
    // no cambia; el agrupado es solo de vista.
    FPivotLineasRepr : TList<Integer>;
    FPivotCantidades : TDictionary<Int64,Double>;
    FPivotMaxAvTalla : Integer;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure InicializarGestorTallas;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    // Hooks que reaccionan a cambios de master / detail para republicar
    // las cantidades de las celdas no-bound (cxGrid las pierde al repintar
    // tras un Post automatico del dataset).
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    // Pivote por SKU -> art+color (vista, no toca BBDD).
    procedure CargarCachePivot;
    procedure unqryLineasFilterRecord(DataSet: TDataSet;
                                      var Accept: Boolean);
    procedure PublicarCantidadesPivot;
    procedure AplicarVisibilidadColumnasPivot(AModoPivot: Boolean);
  public
    dmmAlbaranesCompra: TdmAlbaranesCompra;
  end;

var
  frmMtoAlbaranesCompra: TfrmMtoAlbaranesCompra;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoAlbaranesCompra.FormCreate(Sender: TObject);
begin
  // Igual que en Sesiones: las columnas no-bound de tallas y atributos
  // se crean ANTES del inherited, porque la cadena de inicializacion
  // del Mto base puede tocar el grid (CrearTablaPrincipal, etc.).
  CrearColumnasTallas;
  CrearColumnasAtributos;
  FPivotLineasRepr := TList<Integer>.Create;
  FPivotCantidades := TDictionary<Int64,Double>.Create;

  inherited;

  dmmAlbaranesCompra := TdmAlbaranesCompra.Create(Self);
  dsTablaG.DataSet := dmmAlbaranesCompra.unqryTablaG;
  tvLineasAlbaran.DataController.DataSource :=
    dmmAlbaranesCompra.dsAlbaranesCompraLineas;
  // Enganchar master-detail: el detail tiene MasterFields/DetailFields en
  // el DFM pero MasterSource solo se puede asignar a runtime porque el
  // dsTablaG es del form (no del DM). Sin esto el detail no se filtra
  // por la cabecera activa y o no ve nada o ve todas las lineas de la
  // BBDD (segun como UniDAC lo interprete).
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.MasterSource := dsTablaG;
  // unqryAlbaranesCompraLineas se abre en AbrirDetalles (main thread)
  // tras unqryTablaG, igual que en el Mto de albaranes de venta.

  InicializarGestorTallas;
  // Hook OnDataChange del master: al navegar de un albaran a otro hay
  // que re-cargar las cantidades de tallas porque las columnas no-bound
  // del cxGrid se vacian al cambiar el record activo. Mismo patron que
  // en inMtoComprasSesiones.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Hook AfterPost del detail: cuando el usuario cambia de fila el
  // dataset hace Post automatico y cxGrid repinta la fila desde el
  // dataset, borrando los Values[] no-bound de la fila que abandona.
  // Re-publicamos las cantidades — el SELECT agregado es barato. Hay
  // que conservar la logica original del DM (CalcularTotalesAlbaranCompra),
  // por eso el hook hace las dos cosas.
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FMostrarTallas    := False;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoAlbaranesCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FGestorTallas);
  FreeAndNil(FPivotLineasRepr);
  FreeAndNil(FPivotCantidades);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoAlbaranesCompra.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineasAlbaran.CreateColumn;
    col.Name    := 'dbcLinAlbcTalla' + Format('%.2d', [i + 1]);
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
procedure TfrmMtoAlbaranesCompra.CrearColumnasAtributos;
var
  i: Integer;
  col: TcxGridDBColumn;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
  begin
    col := tvLineasAlbaran.CreateColumn;
    col.Name    := 'dbcLinAlbcAtrib' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 90;
    col.Tag     := -(i + 1);  // tag negativo para no chocar con tallas
    col.Visible := False;
    col.Options.Editing := False;
    FAtribColumns[i] := col;
  end;
end;

procedure TfrmMtoAlbaranesCompra.InicializarGestorTallas;
var
  cfg     : TGridTallasConfig;
  i       : Integer;
  arrCols : TArray<TcxGridDBColumn>;
begin
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if dmmAlbaranesCompra = nil then Exit;

  SetLength(arrCols, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arrCols[i] := FTallaColumns[i];

  // Mismo patron que Sesiones, con los nombres ALBC/ALBCLIN/ALBCCEL.
  cfg := Default(TGridTallasConfig);
  cfg.Conexion           := inLibGlobalVar.oConn;
  cfg.Usuario            := oUser;
  cfg.Grid               := tvLineasAlbaran;
  cfg.SourceMaster       := dsTablaG;
  cfg.SourceLineas       := dmmAlbaranesCompra.dsAlbaranesCompraLineas;
  cfg.ColumnasTallas     := arrCols;
  cfg.FieldSerieMaster   := 'SERIE_ALBC';
  cfg.FieldNumeroMaster  := 'NUMERO_ALBC';
  cfg.FieldLinea         := 'LINEA_ALBCLIN';
  cfg.FieldConjuntoPivot := 'ID_AC_PIVOT_ALBCLIN';
  cfg.FieldPrecioBase    := 'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN';
  cfg.FieldTotalUds      := 'TOTAL_UNIDADES_ALBCLIN';
  cfg.FieldTotalLinea    := 'TOTAL_ALBCLIN';
  cfg.TablaCeldas        := 'fza_albaranes_compra_celdas';
  cfg.FieldSerieCel      := 'SERIE_ALBC_ALBCCEL';
  cfg.FieldNumeroCel     := 'NUMERO_ALBC_ALBCCEL';
  cfg.FieldLineaCel      := 'LINEA_ALBC_ALBCCEL';
  cfg.FieldFilaCel       := 'ID_FILA_ALBC_ALBCCEL';
  cfg.FieldAvPivotCel    := 'ID_AV_PIVOT_ALBCCEL';
  cfg.FieldCantidadCel   := 'CANTIDAD_ALBCCEL';
  cfg.FieldAlmacenCel    := 'CODIGO_ALM_ALBCCEL';
  cfg.IdFilaFijo         := 1;
  cfg.MaxColumnas        := CANT_TALLAS_MAX;

  FGestorTallas := TGestorGridTallas.Create(cfg);

  // Hookea el OnEditValueChanged de cada columna talla al gestor para
  // que persista la celda y refresque totales al teclear.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnEditValueChanged := FGestorTallas.PersistirCeldaActiva;
end;

procedure TfrmMtoAlbaranesCompra.RefrescarVisibilidadTallas;
var
  i: Integer;
begin
  // Sin gestor o sin toggle activo: oculta todas las columnas talla.
  // Con toggle activo y gestor inicializado: delega en el gestor para
  // que muestre solo las que aplican al maximo del documento y pinte
  // los captions de la linea con foco.
  if (not FMostrarTallas) or (FGestorTallas = nil) then
  begin
    for i := 0 to CANT_TALLAS_MAX - 1 do
      if FTallaColumns[i] <> nil then
        FTallaColumns[i].Visible := False;
    Exit;
  end;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.CargarCantidadesTodasLineas;
  FGestorTallas.ActualizarCaptionsLineaActiva;
end;

procedure TfrmMtoAlbaranesCompra.RefrescarVisibilidadAtributos;
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
procedure TfrmMtoAlbaranesCompra.CargarCaptionsAtributosLineaActiva;
var
  i: Integer;
  sArt: string;
  qry: TUniQuery;
  iCol: Integer;
begin
  if dmmAlbaranesCompra = nil then Exit;
  qry := dmmAlbaranesCompra.unqryDefArticuloAlbc;
  if qry = nil then Exit;

  // Reset de captions a placeholder.
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Caption := 'Atributo ' + IntToStr(i + 1);

  if (dmmAlbaranesCompra.unqryAlbaranesCompraLineas = nil) or
     (not dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Active) or
     (dmmAlbaranesCompra.unqryAlbaranesCompraLineas.IsEmpty) then Exit;
  sArt := dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
            FieldByName('CODIGO_ART_ALBCLIN').AsString;
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

procedure TfrmMtoAlbaranesCompra.btnTallasHorizontalClick(Sender: TObject);
var
  ds: TUniQuery;
begin
  inherited;
  FMostrarTallas := not FMostrarTallas;
  if dmmAlbaranesCompra = nil then Exit;
  ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
  // El toggle alterna entre vista plana (1 fila por SKU, columnas SKU /
  // Cantidad / Total visibles) y vista pivote (1 fila representante por
  // articulo+color, columnas talla con la cantidad de cada SKU). El
  // modelo BBDD no cambia: el filtro vive en cliente.
  if FMostrarTallas then
  begin
    CargarCachePivot;
    ds.OnFilterRecord := unqryLineasFilterRecord;
    ds.Filtered       := True;
  end
  else
  begin
    ds.Filtered       := False;
    ds.OnFilterRecord := nil;
    if Assigned(FPivotLineasRepr) then FPivotLineasRepr.Clear;
    if Assigned(FPivotCantidades) then FPivotCantidades.Clear;
  end;
  AplicarVisibilidadColumnasPivot(FMostrarTallas);
  RefrescarVisibilidadTallas;
  if FMostrarTallas then
    PublicarCantidadesPivot;
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
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
    dsTablaG.DataSet.Post;
  end;
  // Tras Grabar, cxGrid limpia los Values[] no-bound al redibujar el
  // row (los Posts del master/detail provocan re-fetch). Recargamos
  // cantidades desde la tabla de celdas para que las celdas talla
  // vuelvan a mostrar lo que el usuario tecleo. Mismo patron que en
  // inMtoComprasSesiones.btnGrabarClick.
  if Assigned(FGestorTallas) then
    FGestorTallas.CargarCantidadesTodasLineas;
end;

// Hook del OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field = nil) que dispara cxGrid al cambiar de record activo en el
// master. Es el momento de invalidar la cache del gestor (los conjuntos
// pivot pueden cambiar entre albaranes), recalcular el numero de
// columnas talla visibles y republicar las cantidades de las lineas
// del albaran que acaba de tomar foco.
procedure TfrmMtoAlbaranesCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
var
  ds: TUniQuery;
begin
  if Field <> nil then Exit;
  if FGestorTallas = nil then Exit;
  if not FMostrarTallas then Exit;
  // Modo pivote activo + cambio de albaran activo: recargar el cache
  // (lineas representantes + cantidades por talla del nuevo albaran) y
  // reaplicar el filtro y la publicacion de cantidades sobre el grid.
  ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
  ds.Filtered := False;
  CargarCachePivot;
  ds.Filtered := True;
  FGestorTallas.InvalidarCache;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.ActualizarCaptionsLineaActiva;
  PublicarCantidadesPivot;
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesAlbaranCompra) con la republicacion de Values[] no-bound
// del gestor. Sustituye al AfterPost original del DM (asignado en
// FormCreate tras crear el DM).
procedure TfrmMtoAlbaranesCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmAlbaranesCompra) then
    dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
  if Assigned(FGestorTallas) and FMostrarTallas then
    FGestorTallas.CargarCantidadesTodasLineas;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla (cada linea puede tener un sistema de tallaje distinto) y, si
// el modo "atributo por columna" esta activo, recargamos los nombres de
// atributo del articulo activo. Mismo patron que en Sesiones.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if Assigned(FGestorTallas) and FMostrarTallas then
    FGestorTallas.ActualizarCaptionsLineaActiva;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Sombrea en gris claro las celdas talla cuya posicion (Tag = 1..N)
// excede el tamanyo del conjunto pivot de la fila para que el usuario
// vea de un vistazo cuales no aplican. El bloqueo real de edicion vive
// en tvLineasAlbaranEditing — este handler solo pinta.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Col   : TcxGridColumn;
  colAc : TcxGridColumn;
  vAc   : Variant;
  iAc   : Integer;
  arr   : TArrPosConjunto;
begin
  inherited;
  if (not FMostrarTallas) or (FGestorTallas = nil) then Exit;
  if AViewInfo.GridRecord = nil then Exit;
  if not (AViewInfo.Item is TcxGridColumn) then Exit;
  Col := TcxGridColumn(AViewInfo.Item);
  if (Col.Tag < 1) or (Col.Tag > CANT_TALLAS_MAX) then Exit;
  if Col <> FTallaColumns[Col.Tag - 1] then Exit;
  colAc := tvLineasAlbaran.GetColumnByFieldName('ID_AC_PIVOT_ALBCLIN');
  if colAc = nil then Exit;
  vAc := AViewInfo.GridRecord.Values[colAc.Index];
  if VarIsNull(vAc) or VarIsEmpty(vAc) or (not VarIsNumeric(vAc)) then Exit;
  iAc := vAc;
  if iAc <= 0 then Exit;
  arr := FGestorTallas.GetPosicionesConjunto(iAc);
  if Col.Tag <= Length(arr) then Exit;
  ACanvas.Brush.Color := $00E8E8E8;
  ACanvas.FillRect(AViewInfo.Bounds);
  ADone := True;
end;

// Bloquea la edicion en celdas talla fuera del conjunto pivot de la
// linea activa. Asi el usuario no puede teclear cantidades en celdas
// que no aplican al sistema de tallaje de esa linea.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  inherited;
  if AItem = nil then Exit;
  if (AItem.Tag < 1) or (AItem.Tag > CANT_TALLAS_MAX) then Exit;
  if FGestorTallas = nil then Exit;
  if dmmAlbaranesCompra = nil then Exit;
  if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.IsEmpty then Exit;
  iAc := dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
                              FieldByName('ID_AC_PIVOT_ALBCLIN').AsInteger;
  if iAc <= 0 then Exit;
  arr := FGestorTallas.GetPosicionesConjunto(iAc);
  if AItem.Tag > Length(arr) then
    AAllow := False;
end;

// Apaga TJvEnterAsTab al entrar al grid para que Enter navegue de
// celda a celda (combinado con FocusCellOnTab del grid en el DFM) y lo
// reactiva al salir. Misma logica que en Sesiones.
procedure TfrmMtoAlbaranesCompra.cxgrdLineasAlbaranEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;

procedure TfrmMtoAlbaranesCompra.cxgrdLineasAlbaranExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoAlbaranesCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Append;
end;

procedure TfrmMtoAlbaranesCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Delete;
end;

// =============================================================================
//   Modo PIVOTE — vista por (articulo + color), tallas en horizontal
// =============================================================================
// El modelo de fza_albaranes_compra_lineas es 1 fila por SKU (articulo +
// color + talla) porque cada SKU genera un movimiento de stock. En modo
// pivote NO cambiamos el modelo: agrupamos visualmente las lineas SKU
// que comparten (articulo + color), dejamos solo una representante por
// grupo via OnFilterRecord y publicamos las cantidades de cada SKU en
// la columna talla correspondiente como Values[] no-bound del cxGrid.
//
// Al volver a vista plana, OnFilterRecord se desconecta y todas las
// lineas SKU vuelven a aparecer con su columna Cantidad / SKU.

// Lanza una sola query que devuelve por cada SKU del albaran activo su
// articulo, AV de color, AV de talla y CANTIDAD_ALBCLIN. Itera el result
// set para:
//   - construir FPivotLineasRepr (la primera LINEA_ALBCLIN encontrada
//     para cada par articulo + color);
//   - construir FPivotCantidades indexado por (LINEA_REPR, AV_TALLA) =>
//     CANTIDAD acumulada.
// El SQL usa LEFT JOIN para que un SKU sin atributos de color o sin
// atributos de talla siga produciendo una fila (con AV=0). Asi los
// articulos planos (sin sistema de tallaje) tambien funcionan: se les
// considera 1 unico grupo y su cantidad queda fuera de columnas talla.
procedure TfrmMtoAlbaranesCompra.CargarCachePivot;
var
  q          : TUniQuery;
  dictRepr   : TDictionary<string,Integer>;
  sSerie     : string;
  sNumero    : string;
  sArt       : string;
  sKey       : string;
  iLinea     : Integer;
  iColorAv   : Integer;
  iTallaAv   : Integer;
  rCant      : Double;
  iLineaRepr : Integer;
  iKeyPivot  : Int64;
begin
  FPivotLineasRepr.Clear;
  FPivotCantidades.Clear;
  FPivotMaxAvTalla := 0;
  if dmmAlbaranesCompra = nil then Exit;
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then Exit;
  sSerie  := dsTablaG.DataSet.FieldByName('SERIE_ALBC').AsString;
  sNumero := dsTablaG.DataSet.FieldByName('NUMERO_ALBC').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  dictRepr := TDictionary<string,Integer>.Create;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT L.LINEA_ALBCLIN AS LINEA, ' +
      '       L.CODIGO_ART_ALBCLIN AS ART, ' +
      '       COALESCE(C.ID_AV_SA, 0) AS COLOR_AV, ' +
      '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
      '       L.CANTIDAD_ALBCLIN AS CANTIDAD ' +
      '  FROM fza_albaranes_compra_lineas L ' +
      '  LEFT JOIN fza_atributos_sku C ' +
      '    ON C.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_ALBCLIN ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVC ' +
      '                WHERE AVC.ID_AV = C.ID_AV_SA ' +
      '                  AND AVC.ID_VA_AV = ''CO'') ' +
      '  LEFT JOIN fza_atributos_sku T ' +
      '    ON T.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_ALBCLIN ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVT ' +
      '                WHERE AVT.ID_AV = T.ID_AV_SA ' +
      '                  AND AVT.ID_VA_AV = ''TAL'') ' +
      ' WHERE L.SERIE_ALBC_ALBCLIN = :SERIE ' +
      '   AND L.NUMERO_ALBC_ALBCLIN = :NUMERO ' +
      ' ORDER BY ART, COLOR_AV, L.LINEA_ALBCLIN';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      iLinea   := q.FieldByName('LINEA').AsInteger;
      sArt     := q.FieldByName('ART').AsString;
      iColorAv := q.FieldByName('COLOR_AV').AsInteger;
      iTallaAv := q.FieldByName('TALLA_AV').AsInteger;
      rCant    := q.FieldByName('CANTIDAD').AsFloat;
      sKey := sArt + '|' + IntToStr(iColorAv);
      if not dictRepr.TryGetValue(sKey, iLineaRepr) then
      begin
        iLineaRepr := iLinea;
        dictRepr.Add(sKey, iLineaRepr);
        FPivotLineasRepr.Add(iLineaRepr);
      end;
      if iTallaAv > 0 then
      begin
        iKeyPivot := Int64(iLineaRepr) * 100000 + iTallaAv;
        if FPivotCantidades.ContainsKey(iKeyPivot) then
          FPivotCantidades[iKeyPivot] := FPivotCantidades[iKeyPivot] + rCant
        else
          FPivotCantidades.Add(iKeyPivot, rCant);
        if iTallaAv > FPivotMaxAvTalla then FPivotMaxAvTalla := iTallaAv;
      end;
      q.Next;
    end;
    q.Close;
  finally
    FreeAndNil(q);
    FreeAndNil(dictRepr);
  end;
end;

// Filtra el dataset detail en cliente: solo deja pasar las lineas
// representantes. Se desconecta al volver a vista plana.
procedure TfrmMtoAlbaranesCompra.unqryLineasFilterRecord(DataSet: TDataSet;
                                                          var Accept: Boolean);
var
  iLinea: Integer;
begin
  if FPivotLineasRepr = nil then begin Accept := True; Exit; end;
  iLinea := DataSet.FieldByName('LINEA_ALBCLIN').AsInteger;
  Accept := FPivotLineasRepr.Contains(iLinea);
end;

// Recorre los records visibles (representantes) y publica las cantidades
// del cache en las columnas talla. La traduccion AV_TALLA -> posicion de
// columna la da el gestor a partir del ID_AC_PIVOT_ALBCLIN de la linea.
procedure TfrmMtoAlbaranesCompra.PublicarCantidadesPivot;
var
  ds       : TUniQuery;
  bk       : TBookmark;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  i        : Integer;
  iKey     : Int64;
  rCant    : Double;
  recIdx   : Integer;
begin
  if FGestorTallas = nil then Exit;
  if dmmAlbaranesCompra = nil then Exit;
  ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
  if (ds = nil) or not ds.Active then Exit;
  tvLineasAlbaran.DataController.BeginUpdate;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    recIdx := 0;
    while not ds.Eof do
    begin
      iLinea := ds.FieldByName('LINEA_ALBCLIN').AsInteger;
      iAc    := ds.FieldByName('ID_AC_PIVOT_ALBCLIN').AsInteger;
      if iAc > 0 then
      begin
        arr := FGestorTallas.GetPosicionesConjunto(iAc);
        for i := 0 to High(arr) do
        begin
          if i >= CANT_TALLAS_MAX then Break;
          if FTallaColumns[i] = nil then Continue;
          iKey := Int64(iLinea) * 100000 + arr[i].IdAv;
          if FPivotCantidades.TryGetValue(iKey, rCant) and (rCant <> 0) then
            tvLineasAlbaran.DataController.Values[recIdx,
                                            FTallaColumns[i].Index] := rCant;
        end;
      end;
      Inc(recIdx);
      ds.Next;
    end;
  finally
    if ds.BookmarkValid(bk) then ds.GotoBookmark(bk);
    ds.FreeBookmark(bk);
    ds.EnableControls;
    tvLineasAlbaran.DataController.EndUpdate;
  end;
end;

// Oculta las columnas SKU / Cantidad / Total en modo pivote — los datos
// expandidos viven ahora en las columnas talla. En vista plana se
// restauran.
procedure TfrmMtoAlbaranesCompra.AplicarVisibilidadColumnasPivot(
                                                       AModoPivot: Boolean);
const
  CAMPOS_OCULTOS_PIVOTE: array[0..2] of string = (
    'CODIGO_UNIDAD_ALBCLIN',
    'CANTIDAD_ALBCLIN',
    'TOTAL_ALBCLIN');
var
  i   : Integer;
  col : TcxGridColumn;
begin
  for i := 0 to High(CAMPOS_OCULTOS_PIVOTE) do
  begin
    col := tvLineasAlbaran.GetColumnByFieldName(CAMPOS_OCULTOS_PIVOTE[i]);
    if col <> nil then
      col.Visible := not AModoPivot;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoAlbaranesCompra);
end.
