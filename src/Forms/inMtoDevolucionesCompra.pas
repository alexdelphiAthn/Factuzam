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
{    detecta transiciones de ESTADO_DEVC en BeforePost y dispara en            }
{    AfterPost la generacion (ABIERTO -> CERRADO) o reversion                  }
{    (CERRADO -> ABIERTO) via inLibDevolucionesCompraMovimientos.                 }
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
  cxGridDBBandedTableView,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  UniDataDevolucionesCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;

type
  TfrmMtoDevolucionesCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
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

    // Cabecera
    lblNroDevolucion:    TcxLabel;
    txtNUMERO_DEVC:   TcxDBTextEdit;
    lblSerieDevolucion:  TcxLabel;
    txtSERIE_DEVC:    TcxDBTextEdit;
    lblFechaDevolucion:  TcxLabel;
    dteFECHA_DEVC:    TcxDBDateEdit;
    lblEstadoDevolucion: TcxLabel;
    txtESTADO_DEVC:   TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_DEVC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    btnCODIGO_PRV_DEVC: TcxDBButtonEdit;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_DEVC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_DEVC: TcxDBTextEdit;

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
    grpDesgloseImpuestos: TGroupBox;

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
    procedure tvLineasDevolucionFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
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
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    FColColorPivot   : TcxGridDBColumn;
    // Guarda contra reentrada del toggle desde dsTablaGDataChangeHook
    // disparado por el Edit/Post de PersistirPreferenciaPivote (entre
    // el Edit y el set, la cabecera tiene el ESPIVOTE viejo y el hook
    // veria discrepancia con Activo).
    FInToggleClick   : Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure PersistirPreferenciaPivote;
  public
    dmmDevolucionesCompra: TdmDevolucionesCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoDevolucionesCompra: TfrmMtoDevolucionesCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFotos,
  UniDataArticulos,
  inMtoModalImpDevCompra,
  inMtoModalImpDevCompraV,
  inMtoModalEtiqDev, inLibShowMto;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

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
begin
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
  FColColorPivot.Options.Editing := False;
  inherited;
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre devoluciones, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesDevolucionCompra).
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
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
  // MasterSource se enlaza en DataModuleCreate del DM, pero lo
  // re-aseguramos por idempotencia.
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_DEVC;NUMERO_DEVC';
end;

procedure TfrmMtoDevolucionesCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
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
  cfgT.Conexion           := inLibGlobalVar.oConn;
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
  // Hookea el OnEditValueChanged de cada columna talla al gestor para
  // que persista la celda y refresque totales al teclear.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnEditValueChanged := FGestorTallas.PersistirCeldaActiva;
  // 2. Orquestador de pivote (libreria nueva, compartida con pedidos).
  cfgP := Default(TGridPivoteCompraConfig);
  cfgP.Conexion             := inLibGlobalVar.oConn;
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

procedure TfrmMtoDevolucionesCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcDevolucion.ActivePage := tsLineasDevolucion;
end;

procedure TfrmMtoDevolucionesCompra.btnGrabarClick(Sender: TObject);
begin
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
var
  bDeberiaEstarActivo: Boolean;
begin
  if Field <> nil then Exit;
  if FPivote = nil then Exit;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) and
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil) then
  begin
    // Por defecto la vista es horizontal: solo un 'N' explicito
    // (excepcion que el usuario guardo a mano) la mantiene vertical.
    // NULL / vacio / 'S' abren en horizontal.
    bDeberiaEstarActivo :=
      dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString <> 'N';
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
// (CalcularTotalesDevolucionCompra) con la republicacion del controlador.
procedure TfrmMtoDevolucionesCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmDevolucionesCompra) then
    dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
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
end;

procedure TfrmMtoDevolucionesCompra.cxgrdLineasDevolucionExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoDevolucionesCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  with tvLineasDevolucion.DataController.DataSet do
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ART_DEVCLIN').AsString);
end;

procedure TfrmMtoDevolucionesCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Append;
end;

procedure TfrmMtoDevolucionesCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Delete;
end;

initialization
  ForceReferenceToClass(TfrmMtoDevolucionesCompra);
end.
