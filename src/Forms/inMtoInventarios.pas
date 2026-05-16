{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoInventarios                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de inventarios de almacen.                                  }
{    Recuento de stock por almacen y articulo con regularizacion.              }
{******************************************************************************}
unit inMtoInventarios;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  Data.DB, cxDBData, cxContainer, cxCheckBox, cxTextEdit, cxGridLevel,
  cxClasses, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxMaskEdit,
  cxDropDownEdit, cxDBEdit, cxLabel, cxGridBandedTableView,
  cxGridDBBandedTableView, cxLocalization, cxCurrencyEdit,
  dxBevel, cxDBNavigator, UniDataInventarios, cxGridExportLink,
  dxDateRanges, MemDS, DBAccess, Uni, inMtoGen, Vcl.Menus, cxButtons,
  cxMemo, cxSpinEdit, cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  System.Actions, Vcl.ActnList, cxButtonEdit, cxSplitter, cxRadioGroup,
  cxGroupBox, JvComponentBase, JvEnterTab, dxShellDialogs, system.UITypes,
  dxCoreGraphics, strUtils, cxCalc, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan;

type
  TfrmMtoInventarios = class(TfrmMtoGen)
    dlgAbrir: TOpenDialog;
    // Columnas del grid de la pestana Lista (view heredado cxGrdDBTabPrin)
    colCODIGO_EMP_INV: TcxGridDBColumn;
    colCODIGO_ALM_INV: TcxGridDBColumn;
    colSERIE_INV: TcxGridDBColumn;
    colNUMERO_INV: TcxGridDBColumn;
    colFECHA_INV: TcxGridDBColumn;
    colESTADO_INV: TcxGridDBColumn;
    colDESCRIPCION_INV: TcxGridDBColumn;
    colTOT_UDS_DIF_INV: TcxGridDBColumn;
    colTOT_EUR_DIF_INV: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblEmpresa: TcxLabel;
    cbbCODIGO_EMPRESA_INVENTARIO: TcxDBLookupComboBox;
    lblAlmacen: TcxLabel;
    cbbCODIGO_ALMACEN_INVENTARIO: TcxDBLookupComboBox;
    lblSerie: TcxLabel;
    cbbSERIE_INVENTARIO: TcxDBLookupComboBox;
    lblNumero: TcxLabel;
    txtNRO_INVENTARIO: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dtFECHA_INVENTARIO: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_INVENTARIO: TcxDBTextEdit;
    btnAplicar: TcxButton;
    lblDescripcion: TcxLabel;
    txtDESCRIPCION_INVENTARIO: TcxDBTextEdit;
    btnCargar: TcxButton;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsDetalle: TcxTabSheet;
    pnlDetalleTop: TPanel;
    btnAnadirLinea: TcxButton;
    btnAnadirSkusArt: TcxButton;
    btnEliminarLinea: TcxButton;
    btnRecalcularDetalle: TcxButton;
    btnCargarExcel: TcxButton;
    btnExportarInv: TcxButton;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    tvLineasLINEA: TcxGridDBColumn;
    tvLineasARTICULO: TcxGridDBColumn;
    tvLineasUNIDAD: TcxGridDBColumn;
    tvLineasDESCRIPCION: TcxGridDBColumn;
    tvLineasSKU1: TcxGridDBColumn;
    tvLineasSKU2: TcxGridDBColumn;
    tvLineasSKU3: TcxGridDBColumn;
    tvLineasSKU4: TcxGridDBColumn;
    tvLineasSKU5: TcxGridDBColumn;
    tvLineasLOTE: TcxGridDBColumn;
    tvLineasCADUCIDAD: TcxGridDBColumn;
    tvLineasUDS_TEORICAS: TcxGridDBColumn;
    tvLineasUDS_FISICAS: TcxGridDBColumn;
    tvLineasPMP_ACTUAL: TcxGridDBColumn;
    tvLineasPMP_NUEVO: TcxGridDBColumn;
    tvLineasDIF_UNIDADES: TcxGridDBColumn;
    tvLineasDIF_COSTE: TcxGridDBColumn;
    tvLineasUDS_REGULARIZADAS: TcxGridDBColumn;
    tvLineasFECHA_RECUENTO: TcxGridDBColumn;
    tvLineasUSUARIO: TcxGridDBColumn;
    cxgrdlvlLineas: TcxGridLevel;
    tsMovsRegul: TcxTabSheet;
    pnlMovsTop: TPanel;
    lblInfoMovs: TcxLabel;
    btnEliminarRegularizacion: TcxButton;
    cxgrdMovs: TcxGrid;
    tvMovs: TcxGridDBTableView;
    tvMovsNUMERO: TcxGridDBColumn;
    tvMovsTIPO: TcxGridDBColumn;
    tvMovsARTICULO: TcxGridDBColumn;
    tvMovsUNIDAD: TcxGridDBColumn;
    tvMovsCANTIDAD: TcxGridDBColumn;
    tvMovsPRECIO: TcxGridDBColumn;
    tvMovsCOSTE: TcxGridDBColumn;
    tvMovsFECHA: TcxGridDBColumn;
    tvMovsACTIVO: TcxGridDBColumn;
    cxgrdlvlMovs: TcxGridLevel;
    tsCabecera: TcxTabSheet;
    pnlCabecera: TPanel;
    lblObservaciones: TcxLabel;
    mmoOBSERVACIONES_INVENTARIO: TcxDBMemo;
    pnlTotales: TGroupBox;
    lblTotalUnidades: TcxLabel;
    txtTOTAL_UNIDADES_DIFERENCIA: TcxDBTextEdit;
    lblTotalEuros: TcxLabel;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    curTOTAL_EUROS_DIFERENCIA_INV: TcxDBCurrencyEdit;
    btnIraArticulo: TcxButton;
    pnlBotonesAccion: TPanel;
    btnExportarExcel: TcxButton;
    btnIraArticuloMov: TcxButton;
    ActionList1: TActionList;
    actIraArticulo: TAction;

    // === EVENTOS ===
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AplicarEtiquetas; override;
    procedure pcDetailChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);

    // Cabecera
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);

    // Detalle
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnAnadirSkusArtClick(Sender: TObject);
    procedure btnEliminarLineaClick(Sender: TObject);
    procedure btnRecalcularDetalleClick(Sender: TObject);
    procedure tvLineasArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure tvLineasUdsFisicasPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasGetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
    procedure tvLineasFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvLineasInitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure tvLineasEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    procedure OnAtributoChanged(Sender: TObject);
    procedure ForzarDespliegue(Sender: TObject);

    // Movs Regularizados
    procedure btnEliminarRegularizacionClick(Sender: TObject);
    procedure btnExportarInvClick(Sender: TObject);

    // Cargas masivas
    procedure btnCargarPorFamiliaClick(Sender: TObject);
    procedure btnCargarPorProveedorClick(Sender: TObject);
    procedure btnCompletarClick(Sender: TObject);
    procedure btnCargarTodoClick(Sender: TObject);
    procedure btnCargarExcelClick(Sender: TObject);
    procedure edtRutaExcelPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnCargarClick(Sender: TObject);
    procedure cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnIraArticuloMovClick(Sender: TObject);
    procedure actIraArticuloExecute(Sender: TObject);

  private
    FNumAtributosActual: Integer;
    FUltimoArticuloPadre: string;
    FProcesandoAtributo: Boolean;
    FInicializandoCombo: Boolean;

    // === LÓGICA DINÁMICA SKUs (mismo patrón que inMtoCajaOpe) ===
    procedure ActualizarColumnasDinamicas(const ArticuloPadre: string);
    procedure RellenarAtributosDesdeSku(const Sku: string);
    function ObtenerColumnaSkuPorTag(NumColumn: Integer): TcxGridDBColumn;
//    procedure ConstruirSkuDesdeAtributos;

    // === BUSQUEDA UNIFICADA DE ARTICULOS (codigo, SKU o codigo de barras) ===
    procedure ResolverInputArticulo(const AInput: string;
                                    out ACodigoPadre: string;
                                    out ACodigoSku: string;
                                    out ADescripcion: string;
                                    out ATipoArt: string;
                                    out AEncontrado: Boolean);
    procedure RellenarLineaDesdeBusqueda(const AInput: string;
                                         var AResolvedValue: string;
                                         var AError: Boolean;
                                         var AErrorText: TCaption);
    function BuscarArticuloDialog: string;

    // === ACTUALIZACIÓN UI SEGÚN ESTADO ===
    procedure ActualizarEstadoUI;
    procedure HabilitarEdicionLineas(Habilitado: Boolean);

    // === HELPERS ===
    function EstadoActual: string;
    function PuedeEditar: Boolean;
    procedure CargarLineasYRefrescar;

  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoInventarios: TfrmMtoInventarios;
  dmmInventarios: TdmInventarios;

implementation

uses
  inLibWin,
  inLibUser,
  inLibShowMto,
  inLibDevExp,
  inLibGenBusq,
  inLibGlobalVar,
  inLibArticulosValidador,
  inLibArticulosAtributosLookup,
  inMtoPrincipal, inMtoModalAddBlockInventario;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoInventarios }

procedure TfrmMtoInventarios.CrearTablaPrincipal;
begin
  dmmInventarios := nil;
  inherited;
  dmmInventarios := tdmDataModule as TdmInventarios;
  // Datasources locales que apuntan a queries del data module
  cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource :=
                                                      dmmInventarios.dsEmpresas;
  cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource :=
                                                     dmmInventarios.dsAlmacenes;
  cbbSERIE_INVENTARIO.Properties.ListSource := dmmInventarios.dsSeries;
  tvLineas.DataController.DataSource := dmmInventarios.dsLineas;
  tvMovs.DataController.DataSource   := dmmInventarios.dsMovsRegul;
end;

procedure TfrmMtoInventarios.FormCreate(Sender: TObject);
begin
  inherited;
//  pcDetail.ActivePage := tsCabecera;
  FNumAtributosActual := 0;
  FUltimoArticuloPadre := '';
  FProcesandoAtributo := False;
  FInicializandoCombo := False;
  // Inicialmente ocultas las columnas dinámicas
  ActualizarColumnasDinamicas('');
end;

procedure TfrmMtoInventarios.AplicarEtiquetas;
begin
  inherited;
  // Solo queremos UNA columna de input para el articulo (la unificada
  // tvLineasUNIDAD, que admite codigo de articulo, SKU o codigo de barras).
  // Forzamos a que la antigua columna de articulo no se vea aunque algun
  // perfil de usuario la haya marcado como visible.
  if Assigned(tvLineasARTICULO) then
  begin
    tvLineasARTICULO.Visible := False;
    tvLineasARTICULO.VisibleForCustomization := False;
  end;
end;

procedure TfrmMtoInventarios.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(cbbCODIGO_EMPRESA_INVENTARIO) then
    cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource := nil;
  if Assigned(cbbCODIGO_ALMACEN_INVENTARIO) then
    cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource := nil;
  if Assigned(cbbSERIE_INVENTARIO) then
    cbbSERIE_INVENTARIO.Properties.ListSource := nil;
  if Assigned(tvLineas) then
    tvLineas.DataController.DataSource := nil;
  if Assigned(tvMovs) then
    tvMovs.DataController.DataSource := nil;
  dmmInventarios := nil;
end;

procedure TfrmMtoInventarios.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsDetalle;
end;

procedure TfrmMtoInventarios.pcDetailChange(Sender: TObject);
var
  ds: TDataSet;
begin
  if pcDetail.ActivePage = tsDetalle then
  begin
    // Si la cabecera está sin grabar (dsInsert/dsEdit), la grabamos
    // automáticamente: las líneas referencian (EMP/ALM/SERIE/NRO) y el
    // número definitivo se asigna en unqryTablaGBeforePost desde
    // fza_contadores.
    ds := dsTablaG.DataSet;
    if (ds <> nil) and ds.Active and (ds.State in [dsInsert, dsEdit]) then
    begin
      try
        ds.Post;
      except
        on E: Exception do
        begin
          ShowMessage(
            'No se ha podido grabar automáticamente la cabecera del '+
            'inventario:'#13#10 + E.Message + #13#10#13#10 +
            'Completa los datos en la pestaña Cabecera y vuelve a entrar '+
            'en Detalle.');
          pcDetail.ActivePage := tsCabecera;
          Exit;
        end;
      end;
    end;
    CargarLineasYRefrescar;
  end
  else if pcDetail.ActivePage = tsMovsRegul then
  begin
    ds := dsTablaG.DataSet;
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
      dmmInventarios.SetClavesActivas(
        ds.FieldByName('CODIGO_EMP_INV').AsString,
        ds.FieldByName('CODIGO_ALM_INV').AsString,
        ds.FieldByName('SERIE_INV').AsString,
        ds.FieldByName('NUMERO_INV').AsString
      );
    dmmInventarios.CargarMovimientosRegularizacion;
  end;

  ActualizarEstadoUI;
end;

procedure TfrmMtoInventarios.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  ActualizarEstadoUI;
end;

procedure TfrmMtoInventarios.dsTablaGDataChange(Sender: TObject; Field: TField);
var
  emp: string;
begin
  inherited;
  if (csDestroying in ComponentState) then Exit;

  // Si cambia el registro activo, recargamos el lookup de almacenes
  if (Field = nil) or
     ((Field <> nil) and (Field.FieldName = 'CODIGO_EMP_INV')) then
  begin
    if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
       not dsTablaG.DataSet.IsEmpty then
    begin
      emp := dsTablaG.DataSet.FieldByName('CODIGO_EMP_INV').AsString;
      if dmmInventarios <> nil then
      begin
        dmmInventarios.CargarAlmacenesPorEmpresa(emp);
      end;
    end;
  end;
  if Field = nil then
    ActualizarEstadoUI;
end;

function TfrmMtoInventarios.EstadoActual: string;
begin
  Result := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) then
    Result := dsTablaG.DataSet.FieldByName('ESTADO_INV').AsString;
end;

function TfrmMtoInventarios.PuedeEditar: Boolean;
begin
  Result := EstadoActual = 'ABIERTO';
end;

procedure TfrmMtoInventarios.ActualizarEstadoUI;
var
  Estado: string;
  Edicion: Boolean;
begin
  Estado := EstadoActual;
  Edicion := PuedeEditar;

  // Etiqueta visual del estado
  //lblEstadoDetalle.Caption := 'Estado del inventario: ' + Estado;

  // Botones de acciones globales
{  btnRecalcular.Enabled               := Edicion;
  btnAplicar.Enabled                  := Edicion;
  btnRecalcularDetalle.Enabled        := Edicion;
  btnAnadirLinea.Enabled              := Edicion;
  btnEliminarLinea.Enabled            := Edicion;
  btnCargarPorFamilia.Enabled         := Edicion;
  btnCargarPorProveedor.Enabled       := Edicion;
  btnCompletar.Enabled                := Edicion;
  btnCargarTodo.Enabled               := Edicion;
  btnCargarExcel.Enabled              := Edicion;
  btnEliminarRegularizacion.Enabled   := Estado = 'APLICADO';
 }
  HabilitarEdicionLineas(Edicion);
end;

procedure TfrmMtoInventarios.HabilitarEdicionLineas(Habilitado: Boolean);
begin
  // Si está APLICADO o CANCELADO, el grid de líneas es solo lectura
  tvLineas.OptionsData.Editing  := Habilitado;
  tvLineas.OptionsData.Inserting := Habilitado;
  tvLineas.OptionsData.Deleting := Habilitado;
end;

procedure TfrmMtoInventarios.CargarLineasYRefrescar;
var
  ds: TDataSet;
begin
  ds := dsTablaG.DataSet;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then
    Exit;

  // IMPORTANTE: tras un Post de cabecera nueva, AfterScroll NO siempre se
  // dispara (no hay cambio de registro real). Si no resincronizamos las
  // claves del data module con los valores actuales de la cabecera, las
  // líneas recién insertadas por la modal de carga no se ven, porque
  // unqryLineas se reabre con parámetros desactualizados.
  dmmInventarios.SetClavesActivas(
    ds.FieldByName('CODIGO_EMP_INV').AsString,
    ds.FieldByName('CODIGO_ALM_INV').AsString,
    ds.FieldByName('SERIE_INV').AsString,
    ds.FieldByName('NUMERO_INV').AsString
  );
  dmmInventarios.CargarLineasInventario;
  if dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
  begin
    ActualizarColumnasDinamicas(dmmInventarios.cdsLineas.FieldByName(
                                                 'CODIGO_ART_INVLIN').AsString);
  end;
end;

procedure TfrmMtoInventarios.cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged(
  Sender: TObject);
var
  emp: string;
begin
  // Guards: este evento puede dispararse durante el cierre de la ventana
  // (cuando el manager hace AForm.Hide y AForm.Parent := nil), antes y después
  // de FormDestroy. Si el ciclo de vida ha desmontado el dataset principal
  // o el data module, no podemos tocar el data module.
  if (csDestroying in ComponentState) then
    Exit;
  if dmmInventarios = nil then
    Exit;
  if (dsTablaG = nil) or (dsTablaG.DataSet = nil) then
    Exit;
  emp := VarToStr(cbbCODIGO_EMPRESA_INVENTARIO.EditValue);
  dmmInventarios.CargarAlmacenesPorEmpresa(emp);
  // Si el almacén ya escrito no pertenece a la nueva empresa, lo limpiamos
  if dsTablaG.DataSet.State in [dsEdit, dsInsert] then
    dsTablaG.DataSet.FieldByName('CODIGO_ALM_INV').Clear;
end;

// ============================================================================
//   GESTIÓN DE COLUMNAS DINÁMICAS DE SKU (mismo patrón que inMtoCajaOpe)
// ============================================================================

function TfrmMtoInventarios.ObtenerColumnaSkuPorTag(
  NumColumn: Integer): TcxGridDBColumn;
begin
  case NumColumn of
    1: Result := tvLineasSKU1;
    2: Result := tvLineasSKU2;
    3: Result := tvLineasSKU3;
    4: Result := tvLineasSKU4;
    5: Result := tvLineasSKU5;
  else
    Result := nil;
  end;
end;

procedure TfrmMtoInventarios.actIraArticuloExecute(Sender: TObject);
begin
  inherited;
   if (pcDetail.ActivePage = tsDetalle) then
      with tvLineas.DataController.DataSet do
  ShowMto(Self.Owner,
          'Articulos',
          FieldByName('CODIGO_ART_INVLIN').AsString)
  else
      with tvMovs.DataController.DataSet do
  ShowMto(Self.Owner,
          'Articulos',
          FieldByName('CODIGO_ART_MOV').AsString);
end;

procedure TfrmMtoInventarios.ActualizarColumnasDinamicas(
  const ArticuloPadre: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
  NombresAtributos: TStringList;
begin
  // Optimización: si es el mismo padre, no repintamos
  if SameText(ArticuloPadre, FUltimoArticuloPadre) then Exit;
  FUltimoArticuloPadre := ArticuloPadre;

  // Guard: durante FormCreate puede llamarse antes de que dmmInventarios
  // esté asignado, o tras FormDestroy. En ese caso solo ocultamos columnas.
  if dmmInventarios = nil then
  begin
    if Assigned(tvLineas) then
    begin
      tvLineas.BeginUpdate;
      try
        for i := 1 to 5 do
        begin
          Col := ObtenerColumnaSkuPorTag(i);
          if Col <> nil then
          begin
            Col.Visible := False;
            Col.Options.Editing := False;
            Col.Caption := '-';
          end;
        end;
      finally
        tvLineas.EndUpdate;
      end;
    end;
    Exit;
  end;

  NombresAtributos := TStringList.Create;
  try
    if (ArticuloPadre <> '') then
    begin
      dmmInventarios.unqryDefinicionArticulo.Close;
      dmmInventarios.unqryDefinicionArticulo.SQL.Text :=
        'SELECT DISTINCT '                                             +
        '       N.NOMBRE_ATRIBUTO, '                                   +
        '       N.ORDEN_VISUAL_ATRIBUTO '                              +
        '  FROM fza_articulos_skus SKU '                               +
        '  JOIN fza_atributos_sku AT '                                 +
        '    ON SKU.CODIGO_UNIDAD_SKU = AT.CODIGO_UNIDAD_SKU_SA '          +
        '  JOIN fza_atributos_valores V '                              +
        '    ON AT.ID_AV_SA = V.ID_AV '                       +
        '  JOIN vi_atributos_nombres N '                               +
        '    ON V.ID_VA_AV = N.ID_ATRIBUTO '                           +
        ' WHERE SKU.CODIGO_ART_SKU = :ARTICULO '                  +
        ' ORDER BY N.ORDEN_VISUAL_ATRIBUTO LIMIT 5';
      dmmInventarios.unqryDefinicionArticulo.ParamByName('ARTICULO').AsString :=
        ArticuloPadre;
      dmmInventarios.unqryDefinicionArticulo.Open;
      while not dmmInventarios.unqryDefinicionArticulo.Eof do
      begin
        NombresAtributos.Add(dmmInventarios.unqryDefinicionArticulo.FieldByName(
          'NOMBRE_ATRIBUTO').AsString);
        dmmInventarios.unqryDefinicionArticulo.Next;
      end;
    end;

    FNumAtributosActual := NombresAtributos.Count;

    if dmmInventarios.cdsLineas.Active and
       (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
      dmmInventarios.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := NombresAtributos.Count;

    tvLineas.BeginUpdate;
    try
      for i := 1 to 5 do
      begin
        Col := ObtenerColumnaSkuPorTag(i);
        if Col <> nil then
        begin
          if i <= NombresAtributos.Count then
          begin
            Col.Caption := NombresAtributos[i - 1];
            Col.Visible := True;
            Col.Options.Editing := True;
          end
          else
          begin
            Col.Visible := False;
            Col.Options.Editing := False;
            Col.Caption := '-';
          end;
        end;
      end;
    finally
      tvLineas.EndUpdate;
    end;
  finally
    FreeAndNil(NombresAtributos);
  end;
end;

procedure TfrmMtoInventarios.RellenarAtributosDesdeSku(const Sku: string);
var
  Lookup  : TArticulosAtributosLookup;
  Valores : TArray<TArticuloAtributoValor>;
  V       : TArticuloAtributoValor;
  i       : Integer;
begin
  // Carga los valores de cada atributo del SKU en las columnas ATTR1..ATTR5,
  // mapeadas por ORDEN_VISUAL_ATRIBUTO (= ORDEN_VA del atributo).
  if Sku = '' then Exit;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  Lookup := TArticulosAtributosLookup.Create(inLibGlobalVar.oConn);
  try
    Valores := Lookup.ObtenerAtributosDeSku(Sku);
    for V in Valores do
    begin
      i := V.Orden;
      if (i >= 1) and (i <= 5) then
        dmmInventarios.cdsLineas.FieldByName('ATTR' + IntToStr(
          i) + '_VALOR').AsString
                                                                       := V.Valor;
    end;
  finally
    FreeAndNil(Lookup);
  end;
end;


// ============================================================================
//   EVENTOS DE EDICIÓN DEL GRID DE LÍNEAS
// ============================================================================

procedure TfrmMtoInventarios.tvLineasEditing(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
begin
  if not PuedeEditar then
  begin
    AAllow := False;
    ShowMessage('El inventario no está ABIERTO. No se puede editar.');
  end;
end;

procedure TfrmMtoInventarios.tvLineasInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
var
  Combo: TcxComboBox;
  Qry: TUniQuery;
  ArticuloPadre: string;
  OrdenColumna: Integer;
  ValorActual: Variant;
begin
  // Solo nos interesan las columnas dinamicas SKU1..SKU5 (Tag = 1..5).
  // Al iniciar la edicion, poblamos el combo con los valores validos del
  // atributo correspondiente para el articulo padre actual.
  if (AItem.Tag < 1) or (AItem.Tag > 5) then Exit;
  if not (AEdit is TcxComboBox) then Exit;

  Combo := TcxComboBox(AEdit);
  Combo.Tag := AItem.Tag;
  Combo.Properties.OnEditValueChanged := OnAtributoChanged;
  Combo.OnEnter := nil;
  OrdenColumna := AItem.Tag;

  if dmmInventarios.cdsLineas.Active then
    ArticuloPadre :=
      dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString
  else
    ArticuloPadre := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn;
    Qry.SQL.Text :=
        '  SELECT DISTINCT V.AV ' +
        '    FROM fza_atributos_valores V ' +
        '    JOIN vi_atributos_nombres N ' +
        '      ON V.ID_VA_AV = N.ID_ATRIBUTO ' +
        '    JOIN fza_atributos_sku REL ' +
        '      ON V.ID_AV = REL.ID_AV_SA ' +
        '    JOIN fza_articulos_skus S ' +
        '      ON REL.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU ' +
        '     AND S.CODIGO_ART_SKU = N.CODIGO_ART_PADRE_ARTVIN ' +
        '   WHERE N.CODIGO_ART_PADRE_ARTVIN = :PADRE ' +
        '     AND N.ORDEN_VISUAL_ATRIBUTO   = :ORDEN ' +
        '   ORDER BY V.AV';
    Qry.ParamByName('PADRE').AsString  := ArticuloPadre;
    Qry.ParamByName('ORDEN').AsInteger := OrdenColumna;
    Qry.Open;
    Combo.Properties.Items.BeginUpdate;
    try
      Combo.Properties.Items.Clear;
      while not Qry.Eof do
      begin
        Combo.Properties.Items.Add(Qry.FieldByName('AV').AsString);
        Qry.Next;
      end;
    finally
      Combo.Properties.Items.EndUpdate;
    end;
  finally
    FreeAndNil(Qry);
  end;

  // Si la celda esta vacia, preseleccionamos la primera opcion y, al entrar
  // el editor, abrimos el dropdown automaticamente (igual que inMtoCajaOpe).
  if Combo.Properties.Items.Count > 0 then
  begin
    ValorActual := Sender.Controller.FocusedRecord.Values[AItem.Index];
    if VarIsNull(ValorActual) or (Trim(VarToStr(ValorActual)) = '') then
    begin
      // Mismo patron que inMtoCajaOpe: NO ponemos guard FInicializandoCombo
      // alrededor de ItemIndex := 0 aqui. El fin es justamente que la
      // asignacion dispare OnAtributoChanged, que a su vez hace PostEditValue
      // (commit del valor al campo ATTR1_VALOR via la DataLink) y rebuild
      // del SKU. Si ponemos guard, el campo se queda vacio y al salir de
      // la celda no hay valor (que era el bug previo).
      Combo.OnEnter := ForzarDespliegue;
      Combo.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmMtoInventarios.tvLineasEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  Combo: TcxComboBox;
begin
  // Pulsar Enter en una columna de atributo (Color, Talla, ...) sin valor
  // seleccionado debe coger la primera opcion de la lista, igual que en
  // inMtoCajaOpe. Sin esto, el usuario que da Enter encadenado por las
  // celdas se queda con los atributos vacios y la linea no se puede grabar.
  if Key <> VK_RETURN then Exit;
  if (AItem.Tag < 1) or (AItem.Tag > 5) then Exit;
  if not (AEdit is TcxComboBox) then Exit;
  Combo := TcxComboBox(AEdit);
  if (Combo.ItemIndex = -1) and (Trim(Combo.Text) = '') and
     (Combo.Properties.Items.Count > 0) then
    Combo.ItemIndex := 0;
  if Combo.DroppedDown then
    Combo.DroppedDown := False;
  Combo.PostEditValue;
end;

procedure TfrmMtoInventarios.ForzarDespliegue(Sender: TObject);
var
  Combo: TcxComboBox;
begin
  if not (Sender is TcxComboBox) then Exit;
  Combo := TcxComboBox(Sender);
  // Reasignamos ItemIndex con el guard FInicializandoCombo para que
  // OnAtributoChanged no recalcule un SKU intermedio antes de que el usuario
  // confirme.
  FInicializandoCombo := True;
  try
    if Combo.Properties.Items.Count > 0 then
      Combo.ItemIndex := 0;
  finally
    FInicializandoCombo := False;
  end;
  if not Combo.DroppedDown then
    Combo.DroppedDown := True;
  Combo.OnEnter := nil;
end;

procedure TfrmMtoInventarios.OnAtributoChanged(Sender: TObject);
var
  Edit: TcxCustomEdit;
  SkuNuevo: string;
  CantTeo, PMPAct: Currency;
  NumAtributosRequeridos, NumSeparadores, i: Integer;
begin
  // Cada vez que se selecciona un valor en una columna de atributo (Color,
  // Talla, ...) reconstruimos el SKU (CODIGO_ART/ATTR1/ATTR2/...). Si tras
  // la edicion el SKU es ya completo (tantos '/' como atributos requeridos)
  // disparamos el recalculo teorico/PMP de la linea automaticamente.
  if FInicializandoCombo or FProcesandoAtributo then Exit;
  if not (Sender is TcxCustomEdit) then Exit;
  Edit := TcxCustomEdit(Sender);
  if not dmmInventarios.cdsLineas.Active then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;
  // El TcxComboBox de cxGrid puede disparar OnEditValueChanged mientras el
  // dataset sigue en dsBrowse (al cambiar de valor en una línea ya guardada).
  // Forzamos la transición a dsEdit para que PostEditValue/escritura de campos
  // y el rebuild del SKU se realicen sobre un registro editable.
  if dmmInventarios.cdsLineas.State = dsBrowse then
    dmmInventarios.cdsLineas.Edit;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  Edit.PostEditValue;

  // Defensa: aseguramos que el campo ATTRn_VALOR tiene el valor del editor.
  // Aunque la DataLink deberia hacerlo, en algunos casos no se sincroniza
  // antes de que GenerarSkuFinal lea, dejando el SKU sin atributos.
  if (Edit is TcxComboBox) then
  begin
    var ColIdx := TcxComboBox(Edit).Tag;
    if (ColIdx >= 1) and (ColIdx <= 5) then
      dmmInventarios.cdsLineas.FieldByName(
        'ATTR' + IntToStr(ColIdx) + '_VALOR').AsString :=
                                          VarToStr(TcxComboBox(Edit).EditValue);
  end;

  SkuNuevo := dmmInventarios.GenerarSkuFinal(
                dmmInventarios.cdsLineas.FieldByName(
                  'CODIGO_ART_INVLIN').AsString);
  // Si por algun motivo el SKU sale vacio (no deberia), nos quedamos con
  // el codigo del articulo. CODIGO_UNIDAD_INVLIN es NOT NULL en BD y dejarlo
  // vacio dispararia "Field value required" al hacer Post.
  if Trim(SkuNuevo) = '' then
    SkuNuevo :=
      dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;
  dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
    SkuNuevo;

  NumAtributosRequeridos :=
        dmmInventarios.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  NumSeparadores := 0;
  for i := 1 to Length(SkuNuevo) do
    if SkuNuevo[i] = '/' then
      Inc(NumSeparadores);

  if (NumAtributosRequeridos > 0)
     and (NumSeparadores = NumAtributosRequeridos) then
  begin
    dmmInventarios.RellenarDatosSku(SkuNuevo, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'FECHA_RECUENTO_INVLIN').AsDateTime    := Now;
  end;
end;

procedure TfrmMtoInventarios.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  ArtPadre: string;
begin
  if (AFocusedRecord = nil) or (dmmInventarios = nil) or
     (not dmmInventarios.cdsLineas.Active) or
     dmmInventarios.cdsLineas.IsEmpty then
    Exit;
  ArtPadre :=
    dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;
  ActualizarColumnasDinamicas(ArtPadre);
end;


procedure TfrmMtoInventarios.tvLineasArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodArticulo, Descripcion, TipoArt: string;
  NumAtr: Integer;
begin
  Error := False;
  CodArticulo := Trim(VarToStr(DisplayValue));
  if CodArticulo = '' then Exit;

  dmmInventarios.RellenarDatosArticulo(CodArticulo,
                                       Descripcion,
                                       NumAtr,
                                       TipoArt);

  if Descripcion = '' then
  begin
    Error := True;
    ErrorText := 'El artículo no existe';
    Exit;
  end;

  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  dmmInventarios.cdsLineas.FieldByName(
    'DESCRIPCION_ARTICULO_INVLIN').AsString := Descripcion;
  dmmInventarios.cdsLineas.FieldByName(
    'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := NumAtr;

  // Refrescar columnas SKU dinámicas
  ActualizarColumnasDinamicas(CodArticulo);

  // Si no hay atributos (artículo sin SKUs), el SKU = código artículo
  if NumAtr = 0 then
  begin
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodArticulo;
    // Y rellenamos teóricas y PMP directamente
    var CantTeo, PMPAct: Currency;
    dmmInventarios.RellenarDatosSku(CodArticulo, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency := CantTeo;
    // por defecto
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency       := PMPAct;
    // por defecto
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := PMPAct;
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Input, Resolved: string;
begin
  Error := False;
  Input := Trim(VarToStr(DisplayValue));
  if Input = '' then Exit;
  Resolved := Input;
  RellenarLineaDesdeBusqueda(Input, Resolved, Error, ErrorText);
  if not Error then
    DisplayValue := Resolved;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesButtonClick(
  Sender: TObject;
  AButtonIndex: Integer);
var
  Edit: TcxCustomEdit;
  Codigo, Resolved: string;
  ErrText: TCaption;
  Err: Boolean;
begin
  Codigo := BuscarArticuloDialog;
  if Codigo = '' then Exit;
  Resolved := Codigo;
  Err := False;
  ErrText := '';
  RellenarLineaDesdeBusqueda(Codigo, Resolved, Err, ErrText);
  if Err then
  begin
    ShowMessage(ErrText);
    Exit;
  end;
  // Reflejamos el SKU resuelto en el editor en pantalla
  if Sender is TcxCustomEdit then
  begin
    Edit := TcxCustomEdit(Sender);
    Edit.EditValue := Resolved;
  end;
  // Si el articulo tiene variaciones (NUM_ATRIBUTOS > 0), movemos el foco
  // al primer atributo dinamico para que el usuario pueda elegir
  // Color/Talla/... directamente.
  if (dmmInventarios.cdsLineas.FieldByName(
       'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger > 0) and
     Assigned(tvLineasSKU1) and tvLineasSKU1.Visible then
  begin
    tvLineas.Controller.FocusedColumn := tvLineasSKU1;
    if tvLineas.Controller.EditingController <> nil then
      tvLineas.Controller.EditingController.ShowEdit;
  end;
end;

function TfrmMtoInventarios.BuscarArticuloDialog: string;
const
  SQL =
    'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.TIPO_ART, ' +
    '       a.CODIGO_FAM_ART, f.DESCRIPCION_FAM, ' +
    '       a.TIPO_CANTIDAD_ART, a.ESVARIACION_ART ' +
    '  FROM fza_articulos a ' +
    '  LEFT JOIN fza_articulos_familias f ' +
    '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
    ' WHERE a.ESACTIVO_ART = ''S'' ' +
    ' ORDER BY a.ORDEN_ART, a.CODIGO_ART_ART';
var
  sCodigo: string;
begin
  Result := '';
  if TBusquedaUtils.EjecutarBusqueda(
       'Búsqueda de Artículos',
       SQL,
       'CODIGO_ART_ART',
       sCodigo,
       'frmMtoArtInvSearch') then
    Result := sCodigo;
end;

procedure TfrmMtoInventarios.ResolverInputArticulo(const AInput: string;
                                                  out ACodigoPadre: string;
                                                  out ACodigoSku: string;
                                                  out ADescripcion: string;
                                                  out ATipoArt: string;
                                                  out AEncontrado: Boolean);
var
  Validador  : TArticulosValidador;
  Resolucion : TArtResolucionEntrada;
begin
  ACodigoPadre := '';
  ACodigoSku   := '';
  ADescripcion := '';
  ATipoArt     := '';
  AEncontrado  := False;
  if Trim(AInput) = '' then Exit;

  Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
  try
    Resolucion := Validador.Resolver(AInput);
    if not Resolucion.Encontrado then Exit;
    ACodigoPadre := Resolucion.CodigoArticulo;
    ACodigoSku   := Resolucion.CodigoSku;
    ADescripcion := Resolucion.DescripcionArticulo;
    ATipoArt     := Resolucion.TipoArticulo;
    AEncontrado  := True;
  finally
    FreeAndNil(Validador);
  end;
end;

procedure TfrmMtoInventarios.RellenarLineaDesdeBusqueda(const AInput: string;
                                                       var AResolvedValue: string;
                                                       var AError: Boolean;
                                                       var AErrorText: TCaption);
var
  CodPadre, CodSku, Desc, TipoArt, Tmp: string;
  Encontrado: Boolean;
  CantTeo, PMPAct: Currency;
  NumAtr: Integer;
begin
  AError := False;
  AErrorText := '';

  ResolverInputArticulo(AInput, CodPadre, CodSku, Desc, TipoArt, Encontrado);
  if not Encontrado then
  begin
    AError := True;
    AErrorText := 'No se ha encontrado ningún artículo con ese código, SKU o ' +
                  'código de barras';
    Exit;
  end;

  // Solo se admiten artículos físicos (TIPO_ART='ESTANDAR') en inventarios.
  // SERVICIO/KIT no llevan stock, así que no tiene sentido recontarlos.
  if not SameText(TipoArt, 'ESTANDAR') then
  begin
    AError := True;
    AErrorText := Format('El artículo %s es de tipo "%s" y no controla ' +
                         'stock; no se puede inventariar.',
                         [CodPadre, TipoArt]);
    Exit;
  end;

  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  // Conteo de atributos del articulo padre (para columnas dinamicas SKU1..5)
  dmmInventarios.RellenarDatosArticulo(CodPadre, Tmp, NumAtr, Tmp);

  dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString          :=
    CodPadre;
  dmmInventarios.cdsLineas.FieldByName(
    'DESCRIPCION_ARTICULO_INVLIN').AsString := Desc;
  dmmInventarios.cdsLineas.FieldByName(
    'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := NumAtr;

  ActualizarColumnasDinamicas(CodPadre);

  if CodSku <> '' then
  begin
    // Match por SKU o codigo de barras: ya tenemos el SKU concreto
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodSku;
    AResolvedValue := CodSku;
    dmmInventarios.RellenarDatosSku(CodSku, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'FECHA_RECUENTO_INVLIN').AsDateTime    := Now;
    RellenarAtributosDesdeSku(CodSku);
  end
  else if NumAtr = 0 then
  begin
    // Articulo sin variaciones: SKU = codigo articulo
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodPadre;
    AResolvedValue := CodPadre;
    dmmInventarios.RellenarDatosSku(CodPadre, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_TEORICA_INVLIN').AsCurrency  := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency   := CantTeo;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_INVLIN').AsCurrency      := PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency:= PMPAct;
    dmmInventarios.cdsLineas.FieldByName(
      'FECHA_RECUENTO_INVLIN').AsDateTime    := Now;
  end
  else
  begin
    // Articulo padre con variaciones: el SKU empieza siendo el codigo del
    // articulo (sin atributos todavia) para que el usuario tenga referencia
    // visual de la linea. Cada vez que rellene un atributo, OnAtributoChanged
    // reconstruira el SKU concatenando los valores.
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      CodPadre;
    AResolvedValue := CodPadre;
  end;
end;

procedure TfrmMtoInventarios.tvLineasUdsFisicasPropertiesValidate(
  Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Fis, Teo, PMPAct, PMPNue, DifUds, DifCoste: Currency;
begin
  Error := False;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  Fis    := StrToCurrDef(VarToStr(DisplayValue), 0);
  Teo    :=
    dmmInventarios.cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency;
  PMPAct :=
    dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency;
  PMPNue := dmmInventarios.cdsLineas.FieldByName(
    'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency;

  DifUds   := Fis - Teo;
  DifCoste := (Fis * PMPNue) - (Teo * PMPAct);

  dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_DIFERENCIA_INVLIN').AsCurrency := DifUds;
  dmmInventarios.cdsLineas.FieldByName(
    'TOTAL_COSTE_DIFERENCIA_INVLIN').AsCurrency           := DifCoste;
  dmmInventarios.cdsLineas.FieldByName(
    'FECHA_RECUENTO_INVLIN').AsDateTime         := Now;
end;

procedure TfrmMtoInventarios.tvLineasGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
begin
  // Tooltip explicativo en columnas clave
  if ACellViewInfo.Item = tvLineasUDS_TEORICAS then
    AHintText := 'Stock que el sistema cree que hay en el almacén'
  else if ACellViewInfo.Item = tvLineasUDS_FISICAS then
    AHintText := 'Lo que realmente has contado'
  else if ACellViewInfo.Item = tvLineasPMP_NUEVO then
    AHintText := 'Precio Medio que tendrá el SKU tras aplicar el inventario'
  else if ACellViewInfo.Item = tvLineasUDS_REGULARIZADAS then
    AHintText := 'Solo se rellena cuando el inventario está APLICADO';
end;

// ============================================================================
//   BOTONES DE PESTAÑA CABECERA
// ============================================================================

procedure TfrmMtoInventarios.btnRecalcularClick(Sender: TObject);
begin
  if MessageDlg(
       'Esto recalculará las cantidades teóricas y precios medios ' +
       'de todas las líneas a partir del Kardex actual.' + #13#10 + #13#10 +
       '¿Continuar?',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.RecalcularTeorico;
    ShowMessage('Recálculo completado correctamente.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnAplicarClick(Sender: TObject);
begin
  if MessageDlg(
       'Esto aplicará el inventario y generará movimientos de regularización'
         + #13#10 +
       'en el Kardex. La operación NO se podrá deshacer fácilmente.' + #13#10
         + #13#10 +
       '¿Aplicar el inventario?',
       mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.AplicarInventario;
    ShowMessage('Inventario aplicado correctamente.');
    pcDetail.ActivePage := tsMovsRegul;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnRecalcularDetalleClick(Sender: TObject);
begin
  btnRecalcularClick(Sender);
end;

// ============================================================================
//   BOTONES DE PESTAÑA DETALLE
// ============================================================================

procedure TfrmMtoInventarios.btnAnadirLineaClick(Sender: TObject);
begin
  if not PuedeEditar then Exit;

  if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    // Si la línea actual no tiene artículo, posteala dispara
    // cdsLineasBeforePost
    // y aborta con excepción. Como el usuario está pidiendo otra línea,
    // descartamos el placeholder vacío en vez de fallar.
    if Trim(dmmInventarios.cdsLineas.FieldByName(
                                'CODIGO_ART_INVLIN').AsString) = '' then
      dmmInventarios.cdsLineas.Cancel
    else
      dmmInventarios.cdsLineas.Post;
  end;
  dmmInventarios.cdsLineas.Append;

  // Foco en la columna unificada (SKU/Articulo)
  tvLineas.Controller.FocusedColumn := tvLineasUNIDAD;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoInventarios.btnAnadirSkusArtClick(Sender: TObject);
var
  CodigoArticulo: string;
  Insertados: Integer;
begin
  if not PuedeEditar then Exit;

  if dmmInventarios.cdsLineas.IsEmpty then
  begin
    ShowMessage('Sitúate sobre una línea con artículo para añadir sus SKUs.');
    Exit;
  end;

  // Comprobar el artículo ANTES de intentar postear: si la línea actual es
  // un placeholder sin artículo, postear lanzaría cdsLineasBeforePost.
  CodigoArticulo := Trim(dmmInventarios.cdsLineas.FieldByName(
                          'CODIGO_ART_INVLIN').AsString);
  if CodigoArticulo = '' then
  begin
    ShowMessage('La línea actual no tiene artículo asignado.');
    Exit;
  end;

  if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
    dmmInventarios.cdsLineas.Post;

  Insertados := 0;
  Screen.Cursor := crHourGlass;
  try
    try
      Insertados := dmmInventarios.CargarSkusConMovimientosArticulo(
                                                              CodigoArticulo);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        ShowMessage('Error al añadir SKUs: ' + E.Message);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  if Insertados = 0 then
    ShowMessage(Format('No se ha añadido ningún SKU. El artículo %s no tiene ' +
                       'movimientos en este almacén o todos sus SKUs ya están '
                         +
                       'en el inventario.', [CodigoArticulo]))
  else
    ShowMessage(Format('Añadidos %d SKUs del artículo %s.',
                       [Insertados, CodigoArticulo]));
end;

procedure TfrmMtoInventarios.btnEliminarLineaClick(Sender: TObject);
begin
  if not PuedeEditar then Exit;
  if dmmInventarios.cdsLineas.IsEmpty then Exit;

  if MessageDlg('¿Eliminar la línea seleccionada?',
       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    dmmInventarios.cdsLineas.Delete;
    dmmInventarios.cdsLineas.ApplyUpdates(0);
  end;
end;

// ============================================================================
//   BOTONES DE PESTAÑA MOVIMIENTOS REGULARIZADOS
// ============================================================================

procedure TfrmMtoInventarios.btnEliminarRegularizacionClick(Sender: TObject);
begin
  if EstadoActual <> 'APLICADO' then
  begin
    ShowMessage(
      'Solo puedes eliminar la regularización de un inventario APLICADO.');
    Exit;
  end;

  if MessageDlg(
       'Esto BORRARÁ todos los movimientos generados por este inventario,'
         + #13#10 +
       'devolverá el inventario al estado ABIERTO y recalculará el Kardex.'
         + #13#10 + #13#10 +
       '¿Continuar?',
       mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.EliminarRegularizacion;
    ShowMessage(
      'Regularización eliminada. El inventario vuelve a estar ABIERTO.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnExportarInvClick(Sender: TObject);
begin
  ExportarExcel(cxgrdMovs, 'Movimientos_Inventario_' +
                dmmInventarios.unqryTablaG.FieldByName('NUMERO_INV').AsString);
end;

procedure TfrmMtoInventarios.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  actIraArticuloExecute(Self);
end;

procedure TfrmMtoInventarios.btnIraArticuloMovClick(Sender: TObject);
begin
  inherited;
  actIraArticuloExecute(Self);
end;

// ============================================================================
//   BOTONES DE PESTAÑA CARGAS MASIVAS
// ============================================================================

procedure TfrmMtoInventarios.btnCargarPorFamiliaClick(Sender: TObject);
var
  Familia: string;
begin
  if not PuedeEditar then
  begin
    ShowMessage('El inventario debe estar ABIERTO.'); Exit;
  end;

  Familia :=
    dmmInventarios.unqryFamilias.FieldByName('CODIGO_FAM_FAM').AsString;
  if Familia = '' then
  begin
    ShowMessage('Selecciona primero una familia.'); Exit;
  end;

  if MessageDlg(
       Format('¿Cargar todos los SKUs de la familia "%s" al inventario?',
              [Familia]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CargarPorFamilia(Familia);
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnCargarPorProveedorClick(Sender: TObject);
var
  Proveedor: string;
begin
  if not PuedeEditar then
  begin
    ShowMessage('El inventario debe estar ABIERTO.'); Exit;
  end;

  Proveedor :=
    dmmInventarios.unqryProveedores.FieldByName('CODIGO_PRV_PRV').AsString;
  if Proveedor = '' then
  begin
    ShowMessage('Selecciona primero un proveedor.'); Exit;
  end;

  if MessageDlg(
       Format('¿Cargar todos los SKUs del proveedor "%s" al inventario?',
              [Proveedor]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CargarPorProveedor(Proveedor);
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnCompletarClick(Sender: TObject);
begin
  if not PuedeEditar then
  begin
    ShowMessage('El inventario debe estar ABIERTO.'); Exit;
  end;

  if MessageDlg(
       'Esto añadirá al inventario todos los SKUs con stock que NO ' + #13#10 +
       'estén ya en el inventario, con cantidad_artvin física = 0.' + #13#10
         + #13#10 +
       'Útil para detectar artículos que faltó contar.' + #13#10 + #13#10 +
       '¿Continuar?',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CompletarUnidadesNoLeidas;
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnCargarTodoClick(Sender: TObject);
begin
  if not PuedeEditar then
  begin
    ShowMessage('El inventario debe estar ABIERTO.'); Exit;
  end;

  if MessageDlg(
       'Esto cargará TODOS los SKUs con stock al inventario, ' + #13#10 +
       'con cantidad_artvin física = teórica. ¿Continuar?',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.CargarTodosArticulosConStock;
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.edtRutaExcelPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  dlgAbrir.Filter := 'Archivos Excel (*.xlsx;*.xls)|*.xlsx;*.xls|' +
                     'Archivos CSV (*.csv;*.txt)|*.csv;*.txt|' +
                     'Todos|*.*';
//  if dlgAbrir.Execute then
//    edtRutaExcel.Text := dlgAbrir.FileName;
end;

procedure TfrmMtoInventarios.btnCargarClick(Sender: TObject);
var
  res: TAddBlockInventarioResult;
  ds : TDataSet;
begin
  if not PuedeEditar then
  begin
    ShowMessage('El inventario debe estar ABIERTO.');
    Exit;
  end;

  ds := dsTablaG.DataSet;
  if (ds = nil) or ds.IsEmpty then
  begin
    ShowMessage('Selecciona primero un inventario.');
    Exit;
  end;

  if ds.State in [dsInsert, dsEdit] then
  begin
    if MessageDlg('El inventario esta en edicion. Guardar antes?',
                  mtConfirmation, [mbYes, mbNo, mbCancel], 0) = mrYes then
      ds.Post
    else
      Exit;
  end;

  res := TfrmModalAddBlockInventario.Ejecutar(
           Self,
           (ds as TUniQuery).Connection,
           ds.FieldByName('CODIGO_EMP_INV').AsString,
           ds.FieldByName('CODIGO_ALM_INV').AsString,
           ds.FieldByName('SERIE_INV').AsString,
           ds.FieldByName('NUMERO_INV').AsString);

  if res.Aceptado then
  begin
    // Refrescar el grid de lineas y proponer recalcular
    pcDetail.ActivePage := tsDetalle;
    CargarLineasYRefrescar;

    if MessageDlg(
         Format(
           'Se anadieron %d lineas (%d articulos distintos).' + sLineBreak +
                '?Quieres calcular ahora las cantidades teoricas y PMP?',
                [res.NumLineas, res.NumArticulos]),
         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      btnRecalcularDetalleClick(nil);
  end;
end;

procedure TfrmMtoInventarios.btnCargarExcelClick(Sender: TObject);
var
  Lista: TStringList;
  Archivo: string;
begin
  if not PuedeEditar then
  begin
    ShowMessage('El inventario debe estar ABIERTO.'); Exit;
  end;

//  Archivo := Trim(edtRutaExcel.Text);
  if (Archivo = '') or not FileExists(Archivo) then
  begin
    ShowMessage('Selecciona primero un archivo válido.'); Exit;
  end;

  // Por simplicidad: si es CSV/TXT lo cargamos directamente.
  // Para XLSX se debería usar un parser (p.ej. la unidad de Excel del
  // proyecto).
  // Formato esperado: SKU=CANTIDAD_ARTVIN por línea (o solo SKU)
  Lista := TStringList.Create;
  try
    if SameText(ExtractFileExt(Archivo), '.xlsx') or
       SameText(ExtractFileExt(Archivo), '.xls') then
    begin
      ShowMessage(
        'Para XLSX: utiliza la opción "Exportar a CSV" desde Excel y vuelve ' +
        'a cargar.' + #13#10 +
        'Formato esperado del CSV: SKU;CANTIDAD_ARTVIN por línea.');
      Exit;
    end;

    Lista.LoadFromFile(Archivo);
    // Convertimos ; en = para que TStringList interprete Names/Values
    var i: Integer;
    for i := 0 to Lista.Count - 1 do
      Lista[i] := StringReplace(Lista[i], ';', '=', [rfReplaceAll]);

    Screen.Cursor := crHourGlass;
    try
      dmmInventarios.CargarDesdeListaSkus(Lista);
      pcDetail.ActivePage := tsDetalle;
      CargarLineasYRefrescar;
      ShowMessage(Format('Procesadas %d líneas del archivo.', [Lista.Count]));
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    FreeAndNil(Lista);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoInventarios);

end.
