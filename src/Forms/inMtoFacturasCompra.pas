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
  UniDataFacturasCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;

type
  TfrmMtoFacturasCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcFactura:           TcxPageControl;
    tsLineasFactura:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    pnlBottomTotales:    TPanel;
    cxgrdLineasFactura:  TcxGrid;
    tvLineasFactura:     TcxGridDBTableView;
    cxgrdlvlLineasFactura: TcxGridLevel;

    // Cabecera
    lblNroFactura:    TcxLabel;
    txtNUMERO_FACC:   TcxDBTextEdit;
    lblSerieFactura:  TcxLabel;
    txtSERIE_FACC:    TcxDBTextEdit;
    lblFechaFactura:  TcxLabel;
    dteFECHA_FACC:    TcxDBDateEdit;
    lblEstadoFactura: TcxLabel;
    txtESTADO_FACC:   TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_FACC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    btnCODIGO_PRV_FACC: TcxDBButtonEdit;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_FACC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_FACC: TcxDBTextEdit;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_FACC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_FACC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_FACC: TcxDBCurrencyEdit;

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
    dmmFacturasCompra: TdmFacturasCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoFacturasCompra: TfrmMtoFacturasCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFotos,
  UniDataArticulos,
  inLibShowMto;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// dsTablaG apunta a la cabecera del factura de compra. El articulo
// activo vive en la fila del sub-grid tvLineasFactura
// (CODIGO_ART_FACCLIN / CODIGO_UNIDAD_FACCLIN).
procedure TfrmMtoFacturasCompra.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasFactura.DataController.DataSource) then
  begin
    ds := tvLineasFactura.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// factura, ademas de dsTablaG (cabecera) enganchamos
// dsFacturasCompraLineas.
function TfrmMtoFacturasCompra.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmFacturasCompra) then
    Result := [dsTablaG, dmmFacturasCompra.dsFacturasCompraLineas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoFacturasCompra.FormCreate(Sender: TObject);
begin
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := tvLineasFactura.CreateColumn;
  FColColorPivot.Name    := 'colLinFaccColorPivot';
  FColColorPivot.Caption := 'Color';
  FColColorPivot.Width   := 110;
  FColColorPivot.Visible := False;
  FColColorPivot.Options.Editing := False;
  inherited;
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre facturas, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesFacturaCompra).
  dmmFacturasCompra.unqryFacturasCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoFacturasCompra.CrearTablaPrincipal;
begin
  inherited;
  // El padre (TfrmMtoGen.CrearTablaPrincipal -> CrearDataModule) ya creo
  // la instancia del DM via RTTI desde fza_winforms y la dejo en
  // tdmDataModule, ademas de enganchar dsTablaG.DataSet a su unqryTablaG.
  // Tomamos esa misma instancia; antes haciamos TdmFacturasCompra.Create
  // en FormCreate y enlazabamos el grid de lineas a un segundo DM cuyo
  // unqryFacturasCompraLineas nunca recibia el .Open de
  // AbrirTablaPrincipalAsync. Fallback Create(Self) por si la BBDD no
  // tiene la entrada en fza_winforms (migracion no aplicada).
  dmmFacturasCompra := (tdmDataModule as TdmFacturasCompra);
  if not Assigned(dmmFacturasCompra) then
  begin
    dmmFacturasCompra := TdmFacturasCompra.Create(Self);
    dsTablaG.DataSet := dmmFacturasCompra.unqryTablaG;
    // Sin esta linea, TfrmMtoGen.AbrirTablaPrincipalAsync ve
    // tdmDataModule=nil y aborta -> la query principal nunca se abre y
    // el form se queda vacio. Solo pasa cuando fza_winforms NO tiene la
    // entrada de FacturasCompra (BBDD sin la migracion aplicada); con
    // la entrada presente, el padre rellena tdmDataModule antes de
    // entrar a CrearTablaPrincipal y este bloque no se ejecuta.
    tdmDataModule := dmmFacturasCompra;
  end;
  tvLineasFactura.DataController.DataSource :=
    dmmFacturasCompra.dsFacturasCompraLineas;
  // MasterSource se enlaza en DataModuleCreate del DM, pero lo
  // re-aseguramos por idempotencia.
  dmmFacturasCompra.unqryFacturasCompraLineas.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_FACC;NUMERO_FACC';
end;

procedure TfrmMtoFacturasCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoFacturasCompra.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineasFactura.CreateColumn;
    col.Name    := 'dbcLinFaccTalla' + Format('%.2d', [i + 1]);
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
procedure TfrmMtoFacturasCompra.CrearColumnasAtributos;
var
  i: Integer;
  col: TcxGridDBColumn;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
  begin
    col := tvLineasFactura.CreateColumn;
    col.Name    := 'dbcLinFaccAtrib' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 90;
    col.Tag     := -(i + 1);  // tag negativo para no chocar con tallas
    col.Visible := False;
    col.Options.Editing := False;
    FAtribColumns[i] := col;
  end;
end;

procedure TfrmMtoFacturasCompra.InicializarGestorYPivote;
var
  cfgT : TGridTallasConfig;
  cfgP : TGridPivoteCompraConfig;
  i    : Integer;
  arr  : TArray<TcxGridDBColumn>;
begin
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if FPivote       <> nil then FreeAndNil(FPivote);
  if dmmFacturasCompra = nil then Exit;
  SetLength(arr, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arr[i] := FTallaColumns[i];
  // 1. Gestor inline de tallas (libreria existente). Mismo patron que
  //    Sesiones, con los nombres FACC/FACCLIN/FACCCEL.
  cfgT := Default(TGridTallasConfig);
  cfgT.Conexion           := inLibGlobalVar.oConn;
  cfgT.Usuario            := oUser;
  cfgT.Grid               := tvLineasFactura;
  cfgT.SourceMaster       := dsTablaG;
  cfgT.SourceLineas       := dmmFacturasCompra.dsFacturasCompraLineas;
  cfgT.ColumnasTallas     := arr;
  cfgT.FieldSerieMaster   := 'SERIE_FACC';
  cfgT.FieldNumeroMaster  := 'NUMERO_FACC';
  cfgT.FieldLinea         := 'LINEA_FACCLIN';
  cfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_FACCLIN';
  cfgT.FieldPrecioBase    := 'PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN';
  cfgT.FieldTotalUds      := 'TOTAL_UNIDADES_FACCLIN';
  cfgT.FieldTotalLinea    := 'TOTAL_FACCLIN';
  cfgT.TablaCeldas        := 'fza_facturas_compra_celdas';
  cfgT.FieldSerieCel      := 'SERIE_FACC_FACCCEL';
  cfgT.FieldNumeroCel     := 'NUMERO_FACC_FACCCEL';
  cfgT.FieldLineaCel      := 'LINEA_FACC_FACCCEL';
  cfgT.FieldFilaCel       := 'ID_FILA_FACC_FACCCEL';
  cfgT.FieldAvPivotCel    := 'ID_AV_PIVOT_FACCCEL';
  cfgT.FieldCantidadCel   := 'CANTIDAD_FACCCEL';
  cfgT.FieldAlmacenCel    := 'CODIGO_ALM_FACCCEL';
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
  cfgP.Grid                 := tvLineasFactura;
  cfgP.SourceMaster         := dsTablaG;
  cfgP.SourceLineas         := dmmFacturasCompra.unqryFacturasCompraLineas;
  cfgP.Gestor               := FGestorTallas;
  cfgP.ColColorPivot        := FColColorPivot;
  cfgP.ColumnasTallas       := arr;
  cfgP.MaxColumnasTallas    := CANT_TALLAS_MAX;
  cfgP.TablaLineas          := 'fza_facturas_compra_lineas';
  cfgP.FieldSerieMaster     := 'SERIE_FACC';
  cfgP.FieldNumeroMaster    := 'NUMERO_FACC';
  cfgP.FieldSerieLin        := 'SERIE_FACC_FACCLIN';
  cfgP.FieldNumeroLin       := 'NUMERO_FACC_FACCLIN';
  cfgP.FieldLinea           := 'LINEA_FACCLIN';
  cfgP.FieldArt             := 'CODIGO_ART_FACCLIN';
  cfgP.FieldSku             := 'CODIGO_UNIDAD_FACCLIN';
  cfgP.FieldCantidad        := 'CANTIDAD_FACCLIN';
  cfgP.FieldIdAcPivot       := 'ID_AC_PIVOT_FACCLIN';
  cfgP.FieldAlmacen         := 'CODIGO_ALMACEN_FACCLIN';
  cfgP.FieldAlmacenMaster   := 'CODIGO_ALM_FACC';
  cfgP.CamposOcultosEnPivote := TArray<string>.Create(
    'CODIGO_UNIDAD_FACCLIN',
    'CANTIDAD_FACCLIN',
    'TOTAL_FACCLIN');
  FPivote := TGridPivoteCompra.Create(cfgP);
end;

procedure TfrmMtoFacturasCompra.RefrescarVisibilidadTallas;
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

procedure TfrmMtoFacturasCompra.RefrescarVisibilidadAtributos;
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
procedure TfrmMtoFacturasCompra.CargarCaptionsAtributosLineaActiva;
var
  i: Integer;
  sArt: string;
  qry: TUniQuery;
  iCol: Integer;
begin
  if dmmFacturasCompra = nil then Exit;
  qry := dmmFacturasCompra.unqryDefArticuloFacc;
  if qry = nil then Exit;

  // Reset de captions a placeholder.
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Caption := 'Atributo ' + IntToStr(i + 1);

  if (dmmFacturasCompra.unqryFacturasCompraLineas = nil) or
     (not dmmFacturasCompra.unqryFacturasCompraLineas.Active) or
     (dmmFacturasCompra.unqryFacturasCompraLineas.IsEmpty) then Exit;
  sArt := dmmFacturasCompra.unqryFacturasCompraLineas.
            FieldByName('CODIGO_ART_FACCLIN').AsString;
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

procedure TfrmMtoFacturasCompra.PersistirPreferenciaPivote;
begin
  // Persiste el modo en la cabecera para que la proxima apertura del
  // factura arranque ya en el modo elegido.
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty or
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_FACC') = nil) then
    Exit;
  if not (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
    dsTablaG.DataSet.Edit;
  dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString :=
    IfThen(FPivote.Activo, 'S', 'N');
  dsTablaG.DataSet.Post;
end;

procedure TfrmMtoFacturasCompra.btnImprimirHClick(Sender: TObject);
begin
  inherited;
  ShowMessage('Impresion de factura de compra: pendiente (hito de informes).');
end;

procedure TfrmMtoFacturasCompra.btnImprimirVClick(Sender: TObject);
begin
  inherited;
  ShowMessage('Impresion de factura de compra: pendiente (hito de informes).');
end;

procedure TfrmMtoFacturasCompra.btnPegatinasClick(Sender: TObject);
begin
  inherited;
  ShowMessage('Etiquetas de factura de compra: pendiente (hito de informes).');
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
begin
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

// Hook del OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field=nil) que dispara cxGrid al cambiar de record activo. Sincroniza
// el toggle con la preferencia guardada en la cabecera y dispara la
// recarga del controlador de pivote.
procedure TfrmMtoFacturasCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
var
  bDeberiaEstarActivo: Boolean;
begin
  if Field <> nil then Exit;
  if FPivote = nil then Exit;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) and
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_FACC') <> nil) then
  begin
    // Por defecto la vista es horizontal: solo un 'N' explicito
    // (excepcion que el usuario guardo a mano) la mantiene vertical.
    // NULL / vacio / 'S' abren en horizontal.
    bDeberiaEstarActivo :=
      dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString <> 'N';
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
// (CalcularTotalesFacturaCompra) con la republicacion del controlador.
procedure TfrmMtoFacturasCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmFacturasCompra) then
    dmmFacturasCompra.CalcularTotalesFacturaCompra;
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
  if Assigned(FGestorTallas) and Assigned(FPivote) and FPivote.Activo then
    FGestorTallas.ActualizarCaptionsLineaActiva;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
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
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;

procedure TfrmMtoFacturasCompra.cxgrdLineasFacturaExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoFacturasCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  with tvLineasFactura.DataController.DataSet do
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ART_FACCLIN').AsString);
end;

procedure TfrmMtoFacturasCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmFacturasCompra.unqryFacturasCompraLineas.Append;
end;

procedure TfrmMtoFacturasCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmFacturasCompra.unqryFacturasCompraLineas.Delete;
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasCompra);
end.
