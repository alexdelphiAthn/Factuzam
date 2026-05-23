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
{    detecta transiciones de ESTADO_ALBC en BeforePost y dispara en            }
{    AfterPost la generacion (ABIERTO -> CERRADO) o reversion                  }
{    (CERRADO -> ABIERTO) via inLibAlbaranesCompraMovimientos.                 }
{    La generacion de factura sigue pendiente para un hito posterior.          }
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
    btnImprimirH:         TcxButton;
    btnImprimirV:         TcxButton;

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
    procedure AbrirModalImpresion(AHorizontal: Boolean);
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
    FPivotColorTexto : TDictionary<Integer,string>;
    FPivotColorCodigo: TDictionary<Integer,string>;
    FPivotIdAc       : TDictionary<Integer,Integer>;
    FPivotMaxAvTalla : Integer;
    FColColorPivot   : TcxGridDBColumn;
    FOrigColIndexAlmacen : Integer;
    FOrigColIndexColor   : Integer;
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
    procedure IntercambiarPosicionColorAlmacen(AModoPivot: Boolean);
    procedure tvLineasAlbaranColorCustomDrawCell(Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    function  ValidarPivotePosible(var AMensaje: string): Boolean;
  public
    dmmAlbaranesCompra: TdmAlbaranesCompra;
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoAlbaranesCompra: TfrmMtoAlbaranesCompra;

implementation

uses
  inLibGlobalVar,
  inLibAtributosPaleta,
  inMtoModalImpAlbCompra;

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
  FPivotColorTexto := TDictionary<Integer,string>.Create;
  FPivotColorCodigo:= TDictionary<Integer,string>.Create;
  FPivotIdAc       := TDictionary<Integer,Integer>.Create;
  FOrigColIndexAlmacen := -1;
  FOrigColIndexColor   := -1;
  // Columna no-bound 'Color' solo visible en modo pivote (los SKUs ya
  // no se ven y necesitamos algo que distinga visualmente las filas
  // representantes que comparten articulo).
  FColColorPivot := tvLineasAlbaran.CreateColumn;
  FColColorPivot.Name    := 'colLinAlbcColorPivot';
  FColColorPivot.Caption := 'Color';
  FColColorPivot.Width   := 110;
  FColColorPivot.Visible := False;
  FColColorPivot.Options.Editing := False;
  FColColorPivot.OnCustomDrawCell := tvLineasAlbaranColorCustomDrawCell;
  inherited;
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

procedure TfrmMtoAlbaranesCompra.CrearTablaPrincipal;
begin
  inherited;
  // El padre (TfrmMtoGen.CrearTablaPrincipal -> CrearDataModule) ya creo
  // la instancia del DM via RTTI desde fza_winforms y la dejo en
  // tdmDataModule, ademas de enganchar dsTablaG.DataSet a su unqryTablaG.
  // Tomamos esa misma instancia; antes haciamos TdmAlbaranesCompra.Create
  // en FormCreate y enlazabamos el grid de lineas a un segundo DM cuyo
  // unqryAlbaranesCompraLineas nunca recibia el .Open de
  // AbrirTablaPrincipalAsync. Fallback Create(Self) por si la BBDD no
  // tiene la entrada en fza_winforms (migracion no aplicada).
  dmmAlbaranesCompra := (tdmDataModule as TdmAlbaranesCompra);
  if not Assigned(dmmAlbaranesCompra) then
  begin
    dmmAlbaranesCompra := TdmAlbaranesCompra.Create(Self);
    dsTablaG.DataSet := dmmAlbaranesCompra.unqryTablaG;
    // Sin esta linea, TfrmMtoGen.AbrirTablaPrincipalAsync ve
    // tdmDataModule=nil y aborta -> la query principal nunca se abre y
    // el form se queda vacio. Solo pasa cuando fza_winforms NO tiene la
    // entrada de AlbaranesCompra (BBDD sin la migracion aplicada); con
    // la entrada presente, el padre rellena tdmDataModule antes de
    // entrar a CrearTablaPrincipal y este bloque no se ejecuta.
    tdmDataModule := dmmAlbaranesCompra;
  end;
  tvLineasAlbaran.DataController.DataSource :=
    dmmAlbaranesCompra.dsAlbaranesCompraLineas;
  // MasterSource se enlaza en DataModuleCreate del DM, pero lo
  // re-aseguramos por idempotencia.
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_ALBC;NUMERO_ALBC';
end;

procedure TfrmMtoAlbaranesCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FGestorTallas);
  FreeAndNil(FPivotLineasRepr);
  FreeAndNil(FPivotCantidades);
  FreeAndNil(FPivotColorTexto);
  FreeAndNil(FPivotColorCodigo);
  FreeAndNil(FPivotIdAc);
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
  // OJO: NO llamar a FGestorTallas.CargarCantidadesTodasLineas: el
  // gestor consulta fza_albaranes_compra_celdas (tabla inexistente —
  // en compras la cantidad por SKU vive directamente en la linea, no
  // en una tabla de celdas separada como en sesiones). La excepcion
  // resultante abortaba el flujo y la publicacion de Color y tallas
  // nunca llegaba a ejecutarse. La carga de cantidades del modo
  // pivote la hace PublicarCantidadesPivot desde btnTallasHorizontalClick.
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
  ds       : TUniQuery;
  sActivar : Boolean;
  sMensaje : string;
begin
  inherited;
  if dmmAlbaranesCompra = nil then Exit;
  sActivar := not FMostrarTallas;
  // Antes de activar, validar que TODAS las lineas son pivotables: no
  // articulos sin sistema de tallas, no conjuntos con > CANT_TALLAS_MAX,
  // no SKUs con tallas fuera del sistema asignado al articulo. Si hay
  // alguna incidencia, abortar el toggle y mantener vista plana — el
  // usuario corrige y vuelve a intentarlo.
  if sActivar then
  begin
    if not ValidarPivotePosible(sMensaje) then
    begin
      MessageDlg(sMensaje, mtWarning, [mbOk], 0);
      Exit;
    end;
  end;
  FMostrarTallas := sActivar;
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
    if Assigned(FPivotColorTexto) then FPivotColorTexto.Clear;
    if Assigned(FPivotColorCodigo) then FPivotColorCodigo.Clear;
    if Assigned(FPivotIdAc) then FPivotIdAc.Clear;
  end;
  AplicarVisibilidadColumnasPivot(FMostrarTallas);
  RefrescarVisibilidadTallas;
  if FMostrarTallas then
    PublicarCantidadesPivot;
end;

procedure TfrmMtoAlbaranesCompra.btnImprimirHClick(Sender: TObject);
begin
  inherited;
  AbrirModalImpresion(True);
end;

procedure TfrmMtoAlbaranesCompra.btnImprimirVClick(Sender: TObject);
begin
  inherited;
  AbrirModalImpresion(False);
end;

procedure TfrmMtoAlbaranesCompra.AbrirModalImpresion(AHorizontal: Boolean);
var
  form    : TfrmPrintAlbCompra;
  sSerie  : string;
  sNumero : string;
begin
  // Mismo patron que TfrmMtoComprasSesiones.btnImprimirClick: persistir
  // ediciones pendientes para que el report vea los ultimos cambios y
  // abrir el modal con serie + numero. La orientacion la usa el modal
  // para elegir entre dos diseños FastReport (a disenar a mano en el
  // .dfm con el FastReport designer; ambos viven en el mismo frxrprt1
  // como paginas distintas o el modal carga distinto fichero segun
  // valor de Orientacion — decision de diseño futura).
  if dmmAlbaranesCompra = nil then Exit;
  if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay albaran de compra activo que imprimir.');
    Exit;
  end;
  if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryTablaG.Post;
  if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Post;
  sSerie  := dmmAlbaranesCompra.unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
  form := TfrmPrintAlbCompra.Create(Application);
  try
    form.dmAlbc        := dmmAlbaranesCompra;
    if AHorizontal then
      form.Orientacion := oacHorizontal
    else
      form.Orientacion := oacVertical;
    form.edtSerie.Text := sSerie;
    form.edtNumero.Text:= sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
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
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
    dsTablaG.DataSet.Post;
  end;
  // Tras Grabar, cxGrid limpia los Values[] no-bound al redibujar el
  // row. Si estamos en modo pivote, republicamos cantidades y Color
  // desde el cache local (no hay tabla de celdas en compras, asi que
  // no podemos usar el gestor — leemos del propio fza_albaranes_compra_lineas).
  if FMostrarTallas then
  begin
    CargarCachePivot;
    PublicarCantidadesPivot;
  end;
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
  ds       : TUniQuery;
  sMensaje : string;
begin
  if Field <> nil then Exit;
  if FGestorTallas = nil then Exit;
  if not FMostrarTallas then Exit;
  ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
  // El albaran que acaba de tomar foco puede no ser pivotable (articulos
  // sin sistema, sistema demasiado largo, talla huerfana). En ese caso
  // auto-desactivamos el pivote y avisamos: el usuario corrige y vuelve
  // a activarlo manualmente.
  if not ValidarPivotePosible(sMensaje) then
  begin
    ds.Filtered       := False;
    ds.OnFilterRecord := nil;
    FPivotLineasRepr.Clear;
    FPivotCantidades.Clear;
    FMostrarTallas := False;
    AplicarVisibilidadColumnasPivot(False);
    RefrescarVisibilidadTallas;
    MessageDlg(sMensaje, mtWarning, [mbOk], 0);
    Exit;
  end;
  // Modo pivote activo + cambio de albaran activo: recargar el cache
  // (lineas representantes + cantidades por talla del nuevo albaran) y
  // reaplicar el filtro y la publicacion de cantidades sobre el grid.
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
  // Sin tabla de celdas en compras: republicamos via cache local en
  // vez de delegar en el gestor (mismo motivo que en btnGrabarClick).
  if FMostrarTallas then
  begin
    CargarCachePivot;
    PublicarCantidadesPivot;
  end;
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

// Comprueba que el albaran activo es pivotable. Bloquea el toggle si:
//   1. Algun articulo del albaran no tiene sistema de tallas asignado
//      (ID_AC_PIVOT_ALBCLIN NULL o 0). Sin sistema no hay donde meter
//      la cantidad de la celda.
//   2. Algun sistema de tallas referenciado tiene mas de CANT_TALLAS_MAX
//      valores. No tenemos columnas suficientes en el grid (hard-limit
//      de la lib de tallas inline).
//   3. Algun SKU tiene un AV con ID_VA_AV = 'TAL' que NO esta en el
//      conjunto pivot asignado a su linea (talla "huerfana": el sistema
//      cambio despues de crear el SKU).
// En cualquiera de los tres casos devuelve False con un mensaje
// descriptivo. El llamador (btnTallasHorizontalClick) muestra el aviso
// y mantiene la vista plana.
function TfrmMtoAlbaranesCompra.ValidarPivotePosible(
                                     var AMensaje: string): Boolean;
var
  q           : TUniQuery;
  incidencias : TStringList;
  sSerie      : string;
  sNumero     : string;
begin
  Result   := True;
  AMensaje := '';
  if dmmAlbaranesCompra = nil then Exit;
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then Exit;
  sSerie  := dsTablaG.DataSet.FieldByName('SERIE_ALBC').AsString;
  sNumero := dsTablaG.DataSet.FieldByName('NUMERO_ALBC').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  incidencias := TStringList.Create;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // 1. Articulos sin sistema de tallas asignado en la linea.
    q.SQL.Text :=
      'SELECT DISTINCT L.CODIGO_ART_ALBCLIN AS ART ' +
      '  FROM fza_albaranes_compra_lineas L ' +
      ' WHERE L.SERIE_ALBC_ALBCLIN = :SERIE ' +
      '   AND L.NUMERO_ALBC_ALBCLIN = :NUMERO ' +
      '   AND (L.ID_AC_PIVOT_ALBCLIN IS NULL ' +
      '        OR L.ID_AC_PIVOT_ALBCLIN = 0) ' +
      ' ORDER BY ART';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add('- Articulo SIN sistema de tallas: ' +
                      q.FieldByName('ART').AsString);
      q.Next;
    end;
    q.Close;
    // 2. Sistemas de tallas con mas valores que CANT_TALLAS_MAX.
    //    Subquery escalar para contar ACD UNA sola vez por conjunto.
    //    Antes haciamos JOIN a ACD desde el FROM y eso multiplicaba
    //    cartesianamente: N = #lineas_articulo x #tallas_conjunto, lo
    //    que daba falsos positivos del tipo "98 tallas" cuando en
    //    realidad eran 14 tallas x 7 SKUs.
    q.SQL.Text :=
      'SELECT DISTINCT L.CODIGO_ART_ALBCLIN AS ART, ' +
      '       AC.NOMBRE_AC AS SISTEMA, ' +
      '       (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
      '         WHERE ACD.ID_AC_ACD = L.ID_AC_PIVOT_ALBCLIN) AS N ' +
      '  FROM fza_albaranes_compra_lineas L ' +
      '  JOIN fza_atributos_conjuntos AC ' +
      '    ON AC.ID_AC = L.ID_AC_PIVOT_ALBCLIN ' +
      ' WHERE L.SERIE_ALBC_ALBCLIN = :SERIE ' +
      '   AND L.NUMERO_ALBC_ALBCLIN = :NUMERO ' +
      '   AND L.ID_AC_PIVOT_ALBCLIN > 0 ' +
      '   AND (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
      '         WHERE ACD.ID_AC_ACD = L.ID_AC_PIVOT_ALBCLIN) > :NMAX ' +
      ' ORDER BY ART';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.ParamByName('NMAX').AsInteger  := CANT_TALLAS_MAX;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add(Format(
        '- Articulo %s: sistema "%s" con %d tallas (maximo %d).',
        [q.FieldByName('ART').AsString,
         q.FieldByName('SISTEMA').AsString,
         q.FieldByName('N').AsInteger,
         CANT_TALLAS_MAX]));
      q.Next;
    end;
    q.Close;
    // 3. SKUs con talla "huerfana" (TAL no presente en el sistema
    //    asignado a la linea).
    q.SQL.Text :=
      'SELECT DISTINCT L.CODIGO_UNIDAD_ALBCLIN AS SKU, ' +
      '       L.CODIGO_ART_ALBCLIN AS ART, AV.AV AS TALLA ' +
      '  FROM fza_albaranes_compra_lineas L ' +
      '  JOIN fza_atributos_sku SAT ' +
      '    ON SAT.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_ALBCLIN ' +
      '  JOIN fza_atributos_valores AV ' +
      '    ON AV.ID_AV = SAT.ID_AV_SA ' +
      '   AND AV.ID_VA_AV = ''TAL'' ' +
      ' WHERE L.SERIE_ALBC_ALBCLIN = :SERIE ' +
      '   AND L.NUMERO_ALBC_ALBCLIN = :NUMERO ' +
      '   AND L.ID_AC_PIVOT_ALBCLIN > 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_atributos_conjuntos_det ACD ' +
      '          WHERE ACD.ID_AC_ACD = L.ID_AC_PIVOT_ALBCLIN ' +
      '            AND ACD.ID_AV_ACD = SAT.ID_AV_SA) ' +
      ' ORDER BY ART, SKU';
    q.ParamByName('SERIE').AsString  := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.Open;
    while not q.Eof do
    begin
      incidencias.Add(Format(
        '- SKU %s (art %s): talla "%s" fuera del sistema asignado.',
        [q.FieldByName('SKU').AsString,
         q.FieldByName('ART').AsString,
         q.FieldByName('TALLA').AsString]));
      q.Next;
    end;
    q.Close;
    if incidencias.Count > 0 then
    begin
      AMensaje := 'No se puede activar el modo pivote por tallas:' +
                  sLineBreak + sLineBreak +
                  incidencias.Text + sLineBreak +
                  'Se mantiene la vista plana (linea por SKU).';
      Result := False;
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(incidencias);
  end;
end;

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
  FPivotColorTexto.Clear;
  FPivotColorCodigo.Clear;
  FPivotIdAc.Clear;
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
    // JOINs directos a fza_atributos_sku / valores / basicos en vez
    // de a vi_atributos_sku_basico: la vista es un UNION ALL con
    // muchos LEFT JOIN que MySQL materializa entero (27 s observados
    // sobre un albaran de 100 lineas). Aqui solo necesitamos el AV
    // global (val.ID_ATB_AV) sin overrides por articulo / conjunto,
    // que es lo suficiente para mostrar nombre y hex del color.
    q.SQL.Text :=
      'SELECT L.LINEA_ALBCLIN AS LINEA, ' +
      '       L.CODIGO_ART_ALBCLIN AS ART, ' +
      '       COALESCE(L.ID_AC_PIVOT_ALBCLIN, 0) AS ID_AC, ' +
      '       COALESCE(AVC.ID_AV, 0) AS COLOR_AV, ' +
      '       COALESCE(ATBC.NOMBRE_ATB, AVC.AV, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.CODIGO_UNIDAD_ALBCLIN, ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_TXT, ' +
      '       COALESCE(ATBC.CODIGO_ATB, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.CODIGO_UNIDAD_ALBCLIN, ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_COD, ' +
      '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
      '       L.CANTIDAD_ALBCLIN AS CANTIDAD ' +
      '  FROM fza_albaranes_compra_lineas L ' +
      '  LEFT JOIN fza_atributos_sku SAC ' +
      '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_ALBCLIN ' +
      '  LEFT JOIN fza_atributos_valores AVC ' +
      '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
      '   AND AVC.ID_VA_AV = ''CO'' ' +
      '  LEFT JOIN fza_atributos_basicos ATBC ' +
      '    ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
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
        FPivotColorTexto.AddOrSetValue(iLineaRepr,
                                       q.FieldByName('COLOR_TXT').AsString);
        FPivotColorCodigo.AddOrSetValue(iLineaRepr,
                                        q.FieldByName('COLOR_COD').AsString);
        FPivotIdAc.AddOrSetValue(iLineaRepr,
                                 q.FieldByName('ID_AC').AsInteger);
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
  colLinea : TcxGridDBColumn;
  recIdx   : Integer;
  vLinea   : Variant;
  iLinea   : Integer;
  iAc      : Integer;
  arr      : TArrPosConjunto;
  i        : Integer;
  iKey     : Int64;
  rCant    : Double;
begin
  // Iteramos el DataController del grid (no el cursor del dataset) y
  // leemos LINEA via Values[] sin mover el cursor. El ID_AC NO se
  // puede leer del grid: no hay columna en el dfm para
  // ID_AC_PIVOT_ALBCLIN. Lo cogemos de FPivotIdAc que se rellena en
  // CargarCachePivot indexado por linea representante.
  if FGestorTallas = nil then Exit;
  if dmmAlbaranesCompra = nil then Exit;
  colLinea := tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBCLIN');
  if colLinea = nil then Exit;
  tvLineasAlbaran.DataController.BeginUpdate;
  try
    for recIdx := 0 to tvLineasAlbaran.DataController.RecordCount - 1 do
    begin
      vLinea := tvLineasAlbaran.DataController.Values[recIdx, colLinea.Index];
      if VarIsNull(vLinea) or VarIsEmpty(vLinea) then Continue;
      // LINEA_ALBCLIN es varchar(4) ('0010', '0070'...). Variant llega
      // como string; forzamos StrToIntDef para que las keys casen.
      iLinea := StrToIntDef(VarToStr(vLinea), 0);
      if iLinea <= 0 then Continue;
      if not FPivotIdAc.TryGetValue(iLinea, iAc) then Continue;
      if iAc <= 0 then Continue;
      // Publicar el color (no-bound) primero — no depende del conjunto.
      if Assigned(FColColorPivot) and Assigned(FPivotColorTexto) then
      begin
        if FPivotColorTexto.ContainsKey(iLinea) then
          tvLineasAlbaran.DataController.Values[recIdx,
                                FColColorPivot.Index] := FPivotColorTexto[iLinea];
      end;
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
  finally
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
  // Columna 'Color' no-bound: solo visible en modo pivote (en plano,
  // el color ya esta en el SKU y la columna seria redundante).
  if Assigned(FColColorPivot) then
    FColColorPivot.Visible := AModoPivot;
  // Intercambio Color <-> Almacen en modo pivote: el usuario quiere
  // ver el Color a la izquierda (donde estaba Almacen) y el Almacen
  // a la derecha (donde estaba Color). En plano se restaura el orden
  // original (Almacen junto al resto de la ficha, Color oculta).
  IntercambiarPosicionColorAlmacen(AModoPivot);
end;

procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranColorCustomDrawCell(
            Sender: TcxCustomGridTableView;
            ACanvas: TcxCanvas;
            AViewInfo: TcxGridTableDataCellViewInfo;
            var ADone: Boolean);
var
  colLinea : TcxGridDBColumn;
  vLinea   : Variant;
  iLinea   : Integer;
  recIdx   : Integer;
  sCodigo  : string;
  sTexto   : string;
  Info     : TInfoBasico;
begin
  // Mismo patron que inMtoComprasSesiones.tvLineasCustomDrawCell para
  // la celda dbcLinColorBasico: resolver el atributo basico por su
  // CODIGO_ATB y delegar el dibujo del swatch en
  // PintarCeldaConCuadradoColor (Lib/inLibAtributosPaleta). Asi
  // unificamos look & feel con sesiones y no duplicamos pintado.
  ADone := False;
  if FPivotColorCodigo = nil then Exit;
  if AViewInfo.GridRecord = nil then Exit;
  recIdx := AViewInfo.GridRecord.RecordIndex;
  colLinea := tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBCLIN');
  if colLinea = nil then Exit;
  vLinea := tvLineasAlbaran.DataController.Values[recIdx, colLinea.Index];
  if VarIsNull(vLinea) or VarIsEmpty(vLinea) then Exit;
  iLinea := StrToIntDef(VarToStr(vLinea), 0);
  if iLinea <= 0 then Exit;
  sCodigo := '';
  sTexto  := '';
  FPivotColorCodigo.TryGetValue(iLinea, sCodigo);
  FPivotColorTexto.TryGetValue(iLinea, sTexto);
  if (sCodigo = '') then Exit;
  Info := Default(TInfoBasico);
  if not ObtenerInfoBasico('CO', sCodigo, Info) then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info, sTexto) then
    ADone := True;
end;

procedure TfrmMtoAlbaranesCompra.IntercambiarPosicionColorAlmacen(
                                                       AModoPivot: Boolean);
var
  colAlm : TcxGridDBColumn;
  iTmp   : Integer;
begin
  if not Assigned(FColColorPivot) then Exit;
  colAlm := tvLineasAlbaran.GetColumnByFieldName('CODIGO_ALMACEN_ALBCLIN');
  if colAlm = nil then Exit;
  if AModoPivot then
  begin
    if FOrigColIndexAlmacen < 0 then
      FOrigColIndexAlmacen := colAlm.Index;
    if FOrigColIndexColor < 0 then
      FOrigColIndexColor := FColColorPivot.Index;
    iTmp := colAlm.Index;
    colAlm.Index := FColColorPivot.Index;
    FColColorPivot.Index := iTmp;
  end
  else
  begin
    if FOrigColIndexAlmacen >= 0 then
      colAlm.Index := FOrigColIndexAlmacen;
    if FOrigColIndexColor >= 0 then
      FColColorPivot.Index := FOrigColIndexColor;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoAlbaranesCompra);
end.
