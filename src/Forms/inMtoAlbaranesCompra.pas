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
begin
  inherited;
  FMostrarTallas := not FMostrarTallas;
  RefrescarVisibilidadTallas;
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
begin
  if Field <> nil then Exit;
  if FGestorTallas = nil then Exit;
  if not FMostrarTallas then Exit;
  FGestorTallas.InvalidarCache;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.CargarCantidadesTodasLineas;
  FGestorTallas.ActualizarCaptionsLineaActiva;
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

initialization
  ForceReferenceToClass(TfrmMtoAlbaranesCompra);
end.
