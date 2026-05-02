{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2026 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

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
  dxCoreGraphics, strUtils;

type
  TfrmMtoInventarios = class(TfrmMtoGen)
    dlgAbrir: TOpenDialog;
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
    cxButton1: TcxButton;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsDetalle: TcxTabSheet;
    pnlDetalleTop: TPanel;
    btnAnadirLinea: TcxButton;
    btnEliminarLinea: TcxButton;
    btnRecalcularDetalle: TcxButton;
    btnCargarExcel: TcxButton;
    btnExportarMovs: TcxButton;
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
    txtTOTAL_EUROS_DIFERENCIA: TcxDBTextEdit;
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

    // === EVENTOS ===
    procedure FormCreate(Sender: TObject);
    procedure pcDetailChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);

    // Cabecera
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);

    // Detalle
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnEliminarLineaClick(Sender: TObject);
    procedure btnRecalcularDetalleClick(Sender: TObject);
    procedure tvLineasArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
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

    // Movs Regularizados
    procedure btnEliminarRegularizacionClick(Sender: TObject);
    procedure btnExportarMovsClick(Sender: TObject);

    // Cargas masivas
    procedure btnCargarPorFamiliaClick(Sender: TObject);
    procedure btnCargarPorProveedorClick(Sender: TObject);
    procedure btnCompletarClick(Sender: TObject);
    procedure btnCargarTodoClick(Sender: TObject);
    procedure btnCargarExcelClick(Sender: TObject);
    procedure edtRutaExcelPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure txtUSUARIOALTAPropertiesChange(Sender: TObject);

  private
    FNumAtributosActual: Integer;
    FUltimoArticuloPadre: string;
    FProcesandoAtributo: Boolean;
    FInicializandoCombo: Boolean;

    // === LÓGICA DINÁMICA SKUs (mismo patrón que inMtoCajaOpe) ===
    procedure ActualizarColumnasDinamicas(const ArticuloPadre: string);
    procedure RellenarAtributosDesdeSku(const Sku: string);
    function ObtenerColumnaSkuPorTag(NumColumn: Integer): TcxGridDBColumn;
    procedure ConstruirSkuDesdeAtributos;

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
  inMtoPrincipal;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoInventarios }

procedure TfrmMtoInventarios.CrearTablaPrincipal;
begin
  // Llamado por TfrmMtoGen — aquí se crea el DataModule de la pantalla
  dmmInventarios := TdmInventarios.Create(Self);
  tdmDataModule := dmmInventarios;

  // Vinculamos el dataset principal al heredado dsTablaG
  dsTablaG.DataSet := dmmInventarios.unqryTablaG;

  // Datasources locales que apuntan a queries del DataModule
   cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource :=
                                                      dmmInventarios.dsEmpresas;
   cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource :=
                                                     dmmInventarios.dsAlmacenes;
   cbbSERIE_INVENTARIO.Properties.ListSource := dmmInventarios.dsSeries;
//    dmmInventarios.dsLineasLocal;
//   dmmInventarios.dsMovsLocal;
//    dmmInventarios.dsFamilias;
//    dmmInventarios.dsProveedores;
end;

procedure TfrmMtoInventarios.FormCreate(Sender: TObject);
begin
  inherited;
  pcDetail.ActivePage := tsCabecera;
  FNumAtributosActual := 0;
  FUltimoArticuloPadre := '';
  FProcesandoAtributo := False;
  FInicializandoCombo := False;

  // Inicialmente ocultas las columnas dinámicas
  ActualizarColumnasDinamicas('');
end;

procedure TfrmMtoInventarios.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsCabecera;
end;

procedure TfrmMtoInventarios.pcDetailChange(Sender: TObject);
begin
  if pcDetail.ActivePage = tsDetalle then
    CargarLineasYRefrescar
  else if pcDetail.ActivePage = tsMovsRegul then
    dmmInventarios.CargarMovimientosRegularizacion;

  ActualizarEstadoUI;
end;

procedure TfrmMtoInventarios.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  ActualizarEstadoUI;
end;

procedure TfrmMtoInventarios.dsTablaGDataChange(Sender: TObject; Field: TField);
begin
  inherited;
  // Cuando cambia el registro activo (no un campo concreto), refrescamos UI
  if Field = nil then
    ActualizarEstadoUI;
end;

function TfrmMtoInventarios.EstadoActual: string;
begin
  Result := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) then
    Result := dsTablaG.DataSet.FieldByName('ESTADO_INVENTARIO').AsString;
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
  lblEstadoDetalle.Caption := 'Estado del inventario: ' + Estado;
  case IndexStr(Estado, ['ABIERTO', 'APLICADO', 'CANCELADO']) of
    0: lblEstadoDetalle.Style.TextColor := clGreen;
    1: lblEstadoDetalle.Style.TextColor := clBlue;
    2: lblEstadoDetalle.Style.TextColor := clRed;
  else
    lblEstadoDetalle.Style.TextColor := clGray;
  end;

  // Botones de acciones globales
  btnRecalcular.Enabled               := Edicion;
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
begin
  if (dsTablaG.DataSet = nil) or dsTablaG.DataSet.IsEmpty then Exit;
  dmmInventarios.CargarLineasInventario;

  // Tras cargar, intentamos detectar el artículo padre del primer registro
  // y ajustar las columnas dinámicas
  if dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
  begin
    ActualizarColumnasDinamicas(
      dmmInventarios.cdsLineas.FieldByName('CODIGO_ARTICULO_INVENTARIO_LINEA').AsString
    );
  end;
end;

// ============================================================================
//   GESTIÓN DE COLUMNAS DINÁMICAS DE SKU (mismo patrón que inMtoCajaOpe)
// ============================================================================

function TfrmMtoInventarios.ObtenerColumnaSkuPorTag(NumColumn: Integer): TcxGridDBColumn;
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

procedure TfrmMtoInventarios.ActualizarColumnasDinamicas(const ArticuloPadre: string);
var
  i: Integer;
  Col: TcxGridDBColumn;
  NombresAtributos: TStringList;
begin
  // Optimización: si es el mismo padre, no repintamos
  if SameText(ArticuloPadre, FUltimoArticuloPadre) then Exit;
  FUltimoArticuloPadre := ArticuloPadre;

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
        '    ON SKU.CODIGO_UNIDAD_SKU = AT.CODIGO_UNIDAD_SA '          +
        '  JOIN fza_atributos_valores V '                              +
        '    ON AT.ID_VALOR_SA = V.ID_VALOR_AV '                       +
        '  JOIN vi_atributos_nombres N '                               +
        '    ON V.ID_VA_AV = N.ID_ATRIBUTO '                           +
        ' WHERE SKU.CODIGO_ARTICULO_SKU = :ARTICULO '                  +
        ' ORDER BY N.ORDEN_VISUAL_ATRIBUTO LIMIT 5';
      dmmInventarios.unqryDefinicionArticulo.ParamByName('ARTICULO').AsString := ArticuloPadre;
      dmmInventarios.unqryDefinicionArticulo.Open;
      while not dmmInventarios.unqryDefinicionArticulo.Eof do
      begin
        NombresAtributos.Add(dmmInventarios.unqryDefinicionArticulo.FieldByName('NOMBRE_ATRIBUTO').AsString);
        dmmInventarios.unqryDefinicionArticulo.Next;
      end;
    end;

    FNumAtributosActual := NombresAtributos.Count;

    if dmmInventarios.cdsLineas.Active and
       (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
      dmmInventarios.cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := NombresAtributos.Count;

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
    NombresAtributos.Free;
  end;
end;

procedure TfrmMtoInventarios.RellenarAtributosDesdeSku(const Sku: string);
var
  qry: TUniQuery;
  i: Integer;
begin
  // Carga los valores de cada atributo del SKU en las columnas ATTR1..ATTR5
  if Sku = '' then Exit;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmInventarios.unqryArticulo.Connection;
    qry.SQL.Text :=
      'SELECT V.NOMBRE_VALOR_AV, N.ORDEN_VISUAL_ATRIBUTO ' +
      '  FROM fza_atributos_sku AT ' +
      '  JOIN fza_atributos_valores V ON AT.ID_VALOR_SA = V.ID_VALOR_AV ' +
      '  JOIN vi_atributos_nombres N  ON V.ID_VA_AV = N.ID_ATRIBUTO ' +
      ' WHERE AT.CODIGO_UNIDAD_SA = :SKU ' +
      ' ORDER BY N.ORDEN_VISUAL_ATRIBUTO LIMIT 5';
    qry.ParamByName('SKU').AsString := Sku;
    qry.Open;

    i := 1;
    while not qry.Eof and (i <= 5) do
    begin
      dmmInventarios.cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString :=
        qry.FieldByName('NOMBRE_VALOR_AV').AsString;
      Inc(i);
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

procedure TfrmMtoInventarios.ConstruirSkuDesdeAtributos;
var
  i: Integer;
  ArticuloPadre, Sku, Valor: string;
begin
  // Concatena: CODIGO_ARTICULO/VAL1/VAL2/...
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then Exit;

  ArticuloPadre := dmmInventarios.cdsLineas.FieldByName('CODIGO_ARTICULO_INVENTARIO_LINEA').AsString;
  if ArticuloPadre = '' then Exit;

  Sku := ArticuloPadre;
  for i := 1 to FNumAtributosActual do
  begin
    Valor := dmmInventarios.cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString;
    if Valor = '' then Exit; // SKU incompleto — todavía falta algún atributo
    Sku := Sku + '/' + Valor;
  end;

  dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVENTARIO_LINEA').AsString := Sku;
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

procedure TfrmMtoInventarios.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  ArtPadre: string;
begin
  // Cuando cambia la fila activa, ajustamos columnas dinámicas a su artículo
  if (AFocusedRecord <> nil) and dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
  begin
    ArtPadre := dmmInventarios.cdsLineas.FieldByName(
                            'CODIGO_ARTICULO_INVENTARIO_LINEA').AsString;
    ActualizarColumnasDinamicas(ArtPadre);
  end;
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

  dmmInventarios.RellenarDatosArticulo(CodArticulo, Descripcion, NumAtr, TipoArt);

  if Descripcion = '' then
  begin
    Error := True;
    ErrorText := 'El artículo no existe';
    Exit;
  end;

  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  dmmInventarios.cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVENTARIO_LINEA').AsString := Descripcion;
  dmmInventarios.cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := NumAtr;

  // Refrescar columnas SKU dinámicas
  ActualizarColumnasDinamicas(CodArticulo);

  // Si no hay atributos (artículo sin SKUs), el SKU = código artículo
  if NumAtr = 0 then
  begin
    dmmInventarios.cdsLineas.FieldByName('CODIGO_UNIDAD_INVENTARIO_LINEA').AsString := CodArticulo;
    // Y rellenamos teóricas y PMP directamente
    var CantTeo, PMPAct: Currency;
    dmmInventarios.RellenarDatosSku(CodArticulo, CantTeo, PMPAct);
    dmmInventarios.cdsLineas.FieldByName('CANTIDAD_TEORICA_INVENTARIO_LINEA').AsCurrency := CantTeo;
    dmmInventarios.cdsLineas.FieldByName('CANTIDAD_FISICA_INVENTARIO_LINEA').AsCurrency  := CantTeo; // por defecto
    dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_INVENTARIO_LINEA').AsCurrency       := PMPAct;
    dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVENTARIO_LINEA').AsCurrency := PMPAct; // por defecto
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Sku: string;
  CantTeo, PMPAct: Currency;
begin
  Error := False;
  Sku := Trim(VarToStr(DisplayValue));
  if Sku = '' then Exit;

  // Cuando se introduce un SKU directamente (escaneo), validamos
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  dmmInventarios.RellenarDatosSku(Sku, CantTeo, PMPAct);
  dmmInventarios.cdsLineas.FieldByName('CANTIDAD_TEORICA_INVENTARIO_LINEA').AsCurrency := CantTeo;
  dmmInventarios.cdsLineas.FieldByName('CANTIDAD_FISICA_INVENTARIO_LINEA').AsCurrency  := CantTeo;
  dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_INVENTARIO_LINEA').AsCurrency       := PMPAct;
  dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVENTARIO_LINEA').AsCurrency := PMPAct;
  dmmInventarios.cdsLineas.FieldByName('FECHA_RECUENTO_INVENTARIO_LINEA').AsDateTime     := Now;

  RellenarAtributosDesdeSku(Sku);
end;

pprocedure TfrmMtoInventarios.txtUSUARIOALTAPropertiesChange(Sender: TObject);
begin
  inherited;

end;

rocedure TfrmMtoInventarios.tvLineasUdsFisicasPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Fis, Teo, PMPAct, PMPNue, DifUds, DifCoste: Currency;
begin
  Error := False;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;

  Fis    := StrToCurrDef(VarToStr(DisplayValue), 0);
  Teo    := dmmInventarios.cdsLineas.FieldByName('CANTIDAD_TEORICA_INVENTARIO_LINEA').AsCurrency;
  PMPAct := dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_INVENTARIO_LINEA').AsCurrency;
  PMPNue := dmmInventarios.cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVENTARIO_LINEA').AsCurrency;

  DifUds   := Fis - Teo;
  DifCoste := (Fis * PMPNue) - (Teo * PMPAct);

  dmmInventarios.cdsLineas.FieldByName('CANTIDAD_DIFERENCIA_INVENTARIO_LINEA').AsCurrency := DifUds;
  dmmInventarios.cdsLineas.FieldByName('TOTAL_COSTE_DIFERENCIA_LINEA').AsCurrency           := DifCoste;
  dmmInventarios.cdsLineas.FieldByName('FECHA_RECUENTO_INVENTARIO_LINEA').AsDateTime         := Now;
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
       'Esto aplicará el inventario y generará movimientos de regularización' + #13#10 +
       'en el Kardex. La operación NO se podrá deshacer fácilmente.' + #13#10 + #13#10 +
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
    dmmInventarios.cdsLineas.Post;
  dmmInventarios.cdsLineas.Append;

  // Foco en la columna artículo
  tvLineas.Controller.FocusedColumn := tvLineasARTICULO;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
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
    ShowMessage('Solo puedes eliminar la regularización de un inventario APLICADO.');
    Exit;
  end;

  if MessageDlg(
       'Esto BORRARÁ todos los movimientos generados por este inventario,' + #13#10 +
       'devolverá el inventario al estado ABIERTO y recalculará el Kardex.' + #13#10 + #13#10 +
       '¿Continuar?',
       mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  try
    dmmInventarios.EliminarRegularizacion;
    ShowMessage('Regularización eliminada. El inventario vuelve a estar ABIERTO.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoInventarios.btnExportarMovsClick(Sender: TObject);
begin
  ExportarExcel(cxgrdMovs, 'Movimientos_Inventario_' +
                dmmInventarios.unqryTablaG.FieldByName('NRO_INVENTARIO').AsString);
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

  Familia := dmmInventarios.unqryFamilias.FieldByName('CODIGO_FAMILIA').AsString;
  if Familia = '' then
  begin
    ShowMessage('Selecciona primero una familia.'); Exit;
  end;

  if MessageDlg(
       Format('¿Cargar todos los SKUs de la familia "%s" al inventario?', [Familia]),
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

  Proveedor := dmmInventarios.unqryProveedores.FieldByName('CODIGO_PROVEEDOR').AsString;
  if Proveedor = '' then
  begin
    ShowMessage('Selecciona primero un proveedor.'); Exit;
  end;

  if MessageDlg(
       Format('¿Cargar todos los SKUs del proveedor "%s" al inventario?', [Proveedor]),
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
       'estén ya en el inventario, con cantidad física = 0.' + #13#10 + #13#10 +
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
       'con cantidad física = teórica. ¿Continuar?',
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
  if dlgAbrir.Execute then
    edtRutaExcel.Text := dlgAbrir.FileName;
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

  Archivo := Trim(edtRutaExcel.Text);
  if (Archivo = '') or not FileExists(Archivo) then
  begin
    ShowMessage('Selecciona primero un archivo válido.'); Exit;
  end;

  // Por simplicidad: si es CSV/TXT lo cargamos directamente.
  // Para XLSX se debería usar un parser (p.ej. la unidad de Excel del proyecto).
  // Formato esperado: SKU=CANTIDAD por línea (o solo SKU)
  Lista := TStringList.Create;
  try
    if SameText(ExtractFileExt(Archivo), '.xlsx') or
       SameText(ExtractFileExt(Archivo), '.xls') then
    begin
      ShowMessage(
        'Para XLSX: utiliza la opción "Exportar a CSV" desde Excel y vuelve a cargar.' + #13#10 +
        'Formato esperado del CSV: SKU;CANTIDAD por línea.');
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
    Lista.Free;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoInventarios);

end.
