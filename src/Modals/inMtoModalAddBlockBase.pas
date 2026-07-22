{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockBase                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.1                                                         }
{   Fecha:       22/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal base para carga masiva de articulos con filtros.                    }
{    NO instanciar directamente; usar las clases hijas (Tarifa/Inventario).    }
{******************************************************************************}
unit inMtoModalAddBlockBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxClasses, cxContainer, cxEdit, cxLabel, cxButtons,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxCurrencyEdit,
  cxSpinEdit, cxCheckBox, cxRadioGroup, cxPC, cxSplitter,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxGridDBDataDefinitions,
  cxTL, cxTLData, cxDBTL, cxInplaceContainer,
  cxCheckListBox, cxCustomListBox,
  dxSkinsCore, dxSkinsForm, dxSkinsDefaultPainters, dxSkinBlue,
  dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges, dxCore,
  cxLocalization,
  inMtoFrmBase, Vcl.ComCtrls, cxDateUtils, cxGroupBox, JvComponentBase,
  JvEnterTab, System.UITypes;

type
  TStockCombinacion = (scCualquiera, scTodos, scSumaPositiva);

  // Resultado base. Los hijos pueden extender con un record propio si necesitan
  // mas campos (p.ej. tarifa: precio_dto, ajuste; inventario: numero_inv).
  TAddBlockBaseResult = record
    Aceptado          : Boolean;
    NumInsertados     : Integer;
    ArticulosCodigos  : TArray<string>;
  end;

  TfrmModalAddBlockBase = class(TfrmBase)
    // Cabecera EXTRA: panel vacio donde los hijos meten sus controles
    // especificos. La base solo coloca el panel, los hijos lo llenan.
    pnlCabeceraExtra: TPanel;

    // Cabecera comun: filtros base
    pnlCabeceraComun: TPanel;
      chkSoloActivos: TcxCheckBox;
      chkExcluirYaCargados: TcxCheckBox;   // hijos definen el texto y la query
      chkSoloConStock: TcxCheckBox;
      lblStockAviso: TcxLabel;
      btnPrevisualizar: TcxButton;
      btnLimpiarFiltros: TcxButton;

    // Filtros (pestañas)
    pcFiltros: TcxPageControl;
      tsFamilias: TcxTabSheet;
        pnlFamiliasTop: TPanel;
          chkPropagarHijos: TcxCheckBox;
          btnExpandirFamilias: TcxButton;
          btnContraerFamilias: TcxButton;
          btnQuitarSelFamilias: TcxButton;
          lblSelFamilias: TcxLabel;
        tlFamilias: TcxDBTreeList;
          tlcolFamiliasNombre: TcxDBTreeListColumn;
          tlcolFamiliasCodigo: TcxDBTreeListColumn;

      tsProveedores: TcxTabSheet;
        pnlProveedoresTop: TPanel;
          edtFiltroProveedor: TcxTextEdit;
          chkSoloPrincipal: TcxCheckBox;
          btnQuitarSelProveedores: TcxButton;
          lblSelProveedores: TcxLabel;
        grdProveedores: TcxGrid;
          tvProveedores: TcxGridDBTableView;
            colProvCodigo: TcxGridDBColumn;
            colProvRazonSocial: TcxGridDBColumn;
            colProvNif: TcxGridDBColumn;
          lvProveedores: TcxGridLevel;

      tsPropiedades: TcxTabSheet;
        pnlPropiedadesTop: TPanel;
          lblPropiedad: TcxLabel;
          cbxPropiedad: TcxComboBox;
          btnQuitarSelPropiedades: TcxButton;
          lblSelPropiedades: TcxLabel;
        grdPropValores: TcxGrid;
          tvPropValores: TcxGridDBTableView;
            colPropIdValor: TcxGridDBColumn;
            colPropPropiedad: TcxGridDBColumn;
            colPropValor: TcxGridDBColumn;
          lvPropValores: TcxGridLevel;

      tsAlmacenes: TcxTabSheet;
        pnlAlmacenesTop: TPanel;
          lblAlmacenInfo: TcxLabel;
          rgStockCombinacion: TcxRadioGroup;
          btnMarcarTodosAlm: TcxButton;
          btnDesmarcarTodosAlm: TcxButton;
          lblSelAlmacenes: TcxLabel;
        chkLstAlmacenes: TcxCheckListBox;

      tsFechaAlta: TcxTabSheet;
        chkAplicarFechaAlta: TcxCheckBox;
        lblAltaDesde: TcxLabel;
        dtAltaDesde: TcxDateEdit;
        lblAltaHasta: TcxLabel;
        dtAltaHasta: TcxDateEdit;

      tsVentas: TcxTabSheet;
        chkConVenta: TcxCheckBox;
        lblVtaDesde: TcxLabel;
        dtVtaDesde: TcxDateEdit;
        lblVtaHasta: TcxLabel;
        dtVtaHasta: TcxDateEdit;
        rgConSinVenta: TcxRadioGroup;
        lblNumMinVtas: TcxLabel;
        spnNumMinVtas: TcxSpinEdit;

    splitterPreview: TcxSplitter;
    pnlPreview: TPanel;
      lblPreviewInfo: TcxLabel;
      grdPreview: TcxGrid;
        tvPreview: TcxGridDBTableView;
          colPrevCodigo: TcxGridDBColumn;
          colPrevDescripcion: TcxGridDBColumn;
          colPrevFamilia: TcxGridDBColumn;
          colPrevProveedor: TcxGridDBColumn;
          colPrevStock: TcxGridDBColumn;
          colPrevYaCargado: TcxGridDBColumn;
        lvPreview: TcxGridLevel;

    pnlBotonera: TPanel;
      btnAceptar: TcxButton;
      btnCancelar: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure btnPrevisualizarClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnLimpiarFiltrosClick(Sender: TObject);

    procedure tlFamiliasNodeCheckChanged(Sender: TcxCustomTreeList;
                                         ANode: TcxTreeListNode;
                                         AState: TcxCheckBoxState);
    procedure btnExpandirFamiliasClick(Sender: TObject);
    procedure btnContraerFamiliasClick(Sender: TObject);
    procedure btnQuitarSelFamiliasClick(Sender: TObject);
    procedure btnQuitarSelProveedoresClick(Sender: TObject);
    procedure btnQuitarSelPropiedadesClick(Sender: TObject);
    procedure btnMarcarTodosAlmClick(Sender: TObject);
    procedure btnDesmarcarTodosAlmClick(Sender: TObject);

    procedure cbxPropiedadPropertiesChange(Sender: TObject);
    procedure edtFiltroProveedorPropertiesChange(Sender: TObject);
    procedure tvProveedoresSelectionChanged(Sender: TcxCustomGridTableView);
    procedure tvPropValoresSelectionChanged(Sender: TcxCustomGridTableView);
    procedure chkLstAlmacenesClickCheck(Sender: TObject);

  protected
    FConn          : TUniConnection;
    FBaseResultado : TAddBlockBaseResult;
    FPropagandoCheck: Boolean;

    FQryFamilias   : TUniQuery;
    FDsFamilias    : TDataSource;
    FQryProveedores: TUniQuery;
    FDsProveedores : TDataSource;
    FQryPropValores: TUniQuery;
    FDsPropValores : TDataSource;
    FSqlPreview    : TUniQuery;
    FDsPreview     : TDataSource;

    FCodigosPropiedades: TStringList;

    // === HOOKS para descendientes ============================================

    // Validaciones extra antes de previsualizar.
    // Si devuelve False, el preview no se ejecuta.
    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    virtual;

    // Columnas SELECT extra a inyectar antes de YA_CARGADO.
    // Cada hijo puede devolver lo suyo (precio_origen, stock_kardex...).
    // Debe terminar siempre en COMA si devuelve algo.
    // Por defecto: ''.
    function  ColumnasSelectExtra: string; virtual;

    // Filtros extra (joins, where adicionales) que el hijo necesite.
    // Por defecto: ''.
    function  FiltrosWhereExtra: string; virtual;

    // Subquery para el campo YA_CARGADO. Cada hijo decide qué significa
    // "ya cargado" (en tarifa X, en inventario Y...).
    // Si devuelve '', el preview no comprueba duplicados (todos = 'N').
    function  SubquerYaCargado: string; virtual;

    // Subquery para excluir los ya cargados (NOT EXISTS ...).
    // Por defecto: ''. Si SubquerYaCargado <> '', el WHERE lo usa.
    function  WhereExcluirYaCargados: string; virtual;

    // Vincular parametros que solo conoce el hijo (nombres P_TARIFA_xxx etc.)
    procedure VincularParametrosExtra(AQry: TUniQuery); virtual;

    // Mensaje de confirmacion antes de aceptar
    function  TextoConfirmacion(ANumPendientes: Integer): string; virtual;

    // Mensaje de exito tras insertar
    function  TextoExito(ANumInsertados: Integer): string; virtual;

    // Texto de los checkboxes "excluir ya en tarifa/inventario"
    function  TextoExcluirYaCargados: string; virtual;

    // Despues de cargar el preview, los hijos pueden ajustar columnas
    procedure ConfigurarPreviewExtra; virtual;

    // INSERCION REAL — el corazon especifico de cada hijo
    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean; virtual; abstract;

    // === API que los hijos pueden invocar ===================================

    // Metodos del preview
    function  ConstruirSQLPreview: string;
    procedure AplicarParametros(AQry: TUniQuery);

    // Recogida de selecciones (los hijos pueden usarlas en su
    // EjecutarInsercion)
    function  RecogerCodigosFamiliaSeleccionados: TArray<string>;
    function  RecogerCodigosProveedoresSeleccionados: TArray<string>;
    function  RecogerIdsValorPropiedadSeleccionados: TArray<Integer>;
    function  RecogerCodigosAlmacenesSeleccionados: TArray<string>;

    function  StockCombinacionActual: TStockCombinacion;

    // Helpers
    function  StrArrToCsvSql(const A: TArray<string>): string;
    function  IntArrToCsvSql(const A: TArray<Integer>): string;

    // Carga de datos auxiliares (los hijos las llaman desde su Ejecutar)
    procedure CargarFiltrosAuxiliares;
    procedure CargarFamilias;
    procedure CargarProveedores;
    procedure CargarPropiedades;
    procedure CargarValoresPropiedad(const ACodigoPropiedad: string);
    procedure CargarAlmacenes;

    // Estado del preview (los hijos lo necesitan en EjecutarInsercion)
    property  Conn: TUniConnection read FConn;
    property  QryPreview: TUniQuery read FSqlPreview;

  private
    function  EsNodoChecked(ANode: TcxTreeListNode): Boolean;
    procedure SetNodoChecked(ANode: TcxTreeListNode; AValue: Boolean);
    procedure PropagarCheckHijos(ANode: TcxTreeListNode; AValue: Boolean);
    procedure ActualizarContadores;

  public
    // El hijo establece la conexion y luego llama a Inicializar
    procedure Inicializar(AConn: TUniConnection);

    property BaseResultado: TAddBlockBaseResult read FBaseResultado;
  end;

implementation

{$R *.dfm}

uses
  inLibUser;

// ============================================================================
//   API publica del hijo
// ============================================================================

procedure TfrmModalAddBlockBase.Inicializar(AConn: TUniConnection);
begin
  FConn := AConn;
  CargarFiltrosAuxiliares;
end;

procedure TfrmModalAddBlockBase.CargarFiltrosAuxiliares;
begin
  CargarFamilias;
  CargarProveedores;
  CargarPropiedades;
  CargarAlmacenes;

  // Aplicar caption del checkbox excluir-ya-cargados
  chkExcluirYaCargados.Caption := TextoExcluirYaCargados;
end;

// ============================================================================
//   HOOKS por defecto
// ============================================================================

function TfrmModalAddBlockBase.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result   := True;
end;

function TfrmModalAddBlockBase.ColumnasSelectExtra: string;
begin
  Result := '';
end;

function TfrmModalAddBlockBase.FiltrosWhereExtra: string;
begin
  Result := '';
end;

function TfrmModalAddBlockBase.SubquerYaCargado: string;
begin
  Result := '';
end;

function TfrmModalAddBlockBase.WhereExcluirYaCargados: string;
begin
  Result := '';
end;

procedure TfrmModalAddBlockBase.VincularParametrosExtra(AQry: TUniQuery);
begin
  // override en hijos
end;

function TfrmModalAddBlockBase.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format('Se van a insertar %d articulos. Continuar?',
                   [ANumPendientes]);
end;

function TfrmModalAddBlockBase.TextoExito(ANumInsertados: Integer): string;
begin
  Result := Format('%d articulos anadidos correctamente.', [ANumInsertados]);
end;

function TfrmModalAddBlockBase.TextoExcluirYaCargados: string;
begin
  Result := 'Excluir articulos ya cargados';
end;

procedure TfrmModalAddBlockBase.ConfigurarPreviewExtra;
begin
  // override en hijos para añadir columnas extra al grid
end;

// ============================================================================
//   FORM CREATE / CLOSE
// ============================================================================

procedure TfrmModalAddBlockBase.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poMainFormCenter;
  FBaseResultado.Aceptado := False;
  FPropagandoCheck    := False;

  FCodigosPropiedades := TStringList.Create;

  FQryFamilias    := TUniQuery.Create(Self);
  FDsFamilias     := TDataSource.Create(Self);
  FDsFamilias.DataSet := FQryFamilias;

  FQryProveedores := TUniQuery.Create(Self);
  FDsProveedores  := TDataSource.Create(Self);
  FDsProveedores.DataSet := FQryProveedores;

  FQryPropValores := TUniQuery.Create(Self);
  FDsPropValores  := TDataSource.Create(Self);
  FDsPropValores.DataSet := FQryPropValores;

  FSqlPreview     := TUniQuery.Create(Self);
  FDsPreview      := TDataSource.Create(Self);
  FDsPreview.DataSet := FSqlPreview;

  // Defaults
  dtAltaDesde.Date := Date - 365;
  dtAltaHasta.Date := Date;
  dtVtaDesde.Date  := Date - 365;
  dtVtaHasta.Date  := Date;
  chkSoloActivos.Checked       := True;
  chkExcluirYaCargados.Checked := True;
  chkSoloConStock.Checked      := False;
  chkPropagarHijos.Checked     := True;
  rgStockCombinacion.ItemIndex := 0;
end;

procedure TfrmModalAddBlockBase.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
  i: Integer;
begin
  // Liberar los TStringList que cuelgan de los items del CheckListBox
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    if chkLstAlmacenes.Items[i].ItemObject is TStringList then
    begin
      chkLstAlmacenes.Items[i].ItemObject.Free;
      chkLstAlmacenes.Items[i].ItemObject := nil;
    end;

  FreeAndNil(FCodigosPropiedades);
  inherited;
  Action := caHide;
end;

// ============================================================================
//   CARGA DE DATOS
// ============================================================================

procedure TfrmModalAddBlockBase.CargarFamilias;

  // Habilita la casilla de verificacion en ANode y, recursivamente, en toda
  // su descendencia. OptionsView.CheckGroups solo activa el mecanismo: es el
  // CheckGroupType de cada nodo (ncgCheckGroup) el que hace que se pinte la
  // casilla de sus hijos. Con el valor por defecto (ncgNone) no se muestra
  // ninguna casilla y CheckState devuelve siempre cbsUnchecked, por lo que
  // el filtro de familias nunca recogia nada. Es idempotente, asi que da
  // igual si Count/Items recorre raices o nodos absolutos.
  procedure HabilitarCasillas(ANode: TcxTreeListNode);
  var
    j: Integer;
  begin
    ANode.CheckGroupType := ncgCheckGroup;
    for j := 0 to ANode.Count - 1 do
      HabilitarCasillas(ANode.Items[j]);
  end;

var
  i: Integer;
begin
  FQryFamilias.Connection := FConn;
  FQryFamilias.SQL.Text :=
    'SELECT CODIGO_FAM_FAM, ' +
    '       COALESCE(CODIGO_SUBFAMILIA_FAM, '''') AS CODIGO_PADRE, ' +
    '       NOMBRE_FAM_FAM, DESCRIPCION_FAM ' +
    'FROM fza_articulos_familias ' +
    'WHERE ESACTIVO_FAM = ''S'' ' +
    'ORDER BY COALESCE(CODIGO_SUBFAMILIA_FAM,''''), ORDEN_FAM, NOMBRE_FAM_FAM';
  FQryFamilias.Open;

  tlFamilias.BeginUpdate;
  try
    tlFamilias.DataController.DataSource := FDsFamilias;
    tlFamilias.DataController.KeyField    := 'CODIGO_FAM_FAM';
    tlFamilias.DataController.ParentField := 'CODIGO_PADRE';
    tlFamilias.RootValue := '';
  finally
    tlFamilias.EndUpdate;
  end;
  tlFamilias.FullExpand;
  // Pintar la casilla en los nodos raiz (lo gobierna el Root) y en el resto.
  tlFamilias.Root.CheckGroupType := ncgCheckGroup;
  for i := 0 to tlFamilias.Count - 1 do
    HabilitarCasillas(tlFamilias.Items[i]);
end;

procedure TfrmModalAddBlockBase.CargarProveedores;
begin
  FQryProveedores.Connection := FConn;
  FQryProveedores.SQL.Text :=
    'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV, NIF_PRV ' +
    'FROM fza_proveedores ' +
    'WHERE ESACTIVO_PRV = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_PRV';
  FQryProveedores.Open;
  tvProveedores.DataController.DataSource := FDsProveedores;
end;

procedure TfrmModalAddBlockBase.CargarPropiedades;
var
  qry             : TUniQuery;
  iPropiedadDefecto: Integer;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP ' +
      'FROM fza_propiedades ' +
      'WHERE ESACTIVO_PROP = ''S'' AND TIPO_VALOR_PROP = ''LISTA'' ' +
      'ORDER BY NOMBRE_PROP_PROP';
    qry.Open;
    cbxPropiedad.Properties.Items.Clear;
    FCodigosPropiedades.Clear;

    cbxPropiedad.Properties.Items.Add('(todas - ver todos los valores)');
    FCodigosPropiedades.Add('');

    while not qry.Eof do
    begin
      cbxPropiedad.Properties.Items.Add(qry.FieldByName(
        'NOMBRE_PROP_PROP').AsString);
      FCodigosPropiedades.Add(qry.FieldByName('CODIGO_PROP_ARTPROP').AsString);
      qry.Next;
    end;
    iPropiedadDefecto := FCodigosPropiedades.IndexOf('TEMPORADA');
    if iPropiedadDefecto < 0 then
      iPropiedadDefecto := 0;
    cbxPropiedad.ItemIndex := iPropiedadDefecto;
    CargarValoresPropiedad(FCodigosPropiedades[iPropiedadDefecto]);
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmModalAddBlockBase.CargarValoresPropiedad(
  const ACodigoPropiedad: string);
begin
  FQryPropValores.Close;
  FQryPropValores.Connection := FConn;
  if ACodigoPropiedad = '' then
  begin
    FQryPropValores.SQL.Text :=
      'SELECT v.ID_PV_ARTPROP, v.ID_PROP_PV, p.NOMBRE_PROP_PROP, v.PV ' +
      'FROM fza_propiedades_valores v ' +
      'JOIN fza_propiedades p ON p.CODIGO_PROP_ARTPROP = v.ID_PROP_PV ' +
      'WHERE v.ESACTIVO_PV = ''S'' AND p.TIPO_VALOR_PROP = ''LISTA'' ' +
      'ORDER BY p.NOMBRE_PROP_PROP, v.PV';
  end
  else
  begin
    FQryPropValores.SQL.Text :=
      'SELECT v.ID_PV_ARTPROP, v.ID_PROP_PV, p.NOMBRE_PROP_PROP, v.PV ' +
      'FROM fza_propiedades_valores v ' +
      'JOIN fza_propiedades p ON p.CODIGO_PROP_ARTPROP = v.ID_PROP_PV ' +
      'WHERE v.ESACTIVO_PV = ''S'' AND v.ID_PROP_PV = :PROP ' +
      'ORDER BY v.PV';
    FQryPropValores.ParamByName('PROP').AsString := ACodigoPropiedad;
  end;
  FQryPropValores.Open;
  tvPropValores.DataController.DataSource := FDsPropValores;
  // Al filtrar una propiedad queda un único grupo; debe mostrar sus valores.
  tvPropValores.DataController.Groups.FullExpand;
end;

procedure TfrmModalAddBlockBase.CargarAlmacenes;
var
  qry: TUniQuery;
  it : TcxCheckListBoxItem;
begin
  chkLstAlmacenes.Items.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, TIPO_USO_ALM ' +
      'FROM fza_almacenes ' +
      'WHERE ESACTIVO_ALM = ''S'' ' +
      '  AND (TIPO_USO_ALM IN ' +
      '(''ESTANDAR'',''ESTANDARD'',''DEPOSITO'',''DEPOSITO'')' +
      '       OR TIPO_USO_ALM IS NULL) ' +
      'ORDER BY ORDEN_ALM, NOMBRE_ALM_ALM';
    qry.Open;
    while not qry.Eof do
    begin
      it := chkLstAlmacenes.Items.Add;
      it.Text :=
        qry.FieldByName('CODIGO_ALM_ALM').AsString +
        ' - ' +
        qry.FieldByName('NOMBRE_ALM_ALM').AsString;
      it.ItemObject := TStringList.Create;
      TStringList(
        it.ItemObject).Add(qry.FieldByName('CODIGO_ALM_ALM').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

// ============================================================================
//   ARBOL DE FAMILIAS
// ============================================================================

function TfrmModalAddBlockBase.EsNodoChecked(ANode: TcxTreeListNode): Boolean;
begin
  // El arbol usa OptionsView.CheckGroups (casillas por nodo). El estado de
  // marcado vive en CheckState, NO en Selected (que es solo el resaltado de
  // fila). Leer Selected hacia que RecogerCodigosFamiliaSeleccionados saliera
  // vacio y el filtro de familias nunca se aplicara en la SQL del preview.
  Result := ANode.CheckState = cbsChecked;
end;

procedure TfrmModalAddBlockBase.SetNodoChecked(ANode: TcxTreeListNode;
  AValue: Boolean);
begin
  if AValue then
    ANode.CheckState := cbsChecked
  else
    ANode.CheckState := cbsUnchecked;
end;

procedure TfrmModalAddBlockBase.tlFamiliasNodeCheckChanged(
  Sender: TcxCustomTreeList; ANode: TcxTreeListNode;
  AState: TcxCheckBoxState);
begin
  // Al marcar/desmarcar una familia propagamos el mismo estado a todas sus
  // subfamilias (cuando el usuario tiene activado "Propagar seleccion a
  // subfamilias"). FPropagandoCheck evita la reentrada: al fijar el CheckState
  // de cada hijo se vuelve a disparar este mismo evento. El estado intermedio
  // cbsGrayed (familia con hijos parcialmente marcados) se ignora para no
  // desmarcar en cascada lo que el usuario acaba de marcar.
  if (not FPropagandoCheck) and chkPropagarHijos.Checked and
     (ANode <> nil) and (AState <> cbsGrayed) then
  begin
    FPropagandoCheck := True;
    try
      PropagarCheckHijos(ANode, AState = cbsChecked);
    finally
      FPropagandoCheck := False;
    end;
    ActualizarContadores;
  end;
end;

procedure TfrmModalAddBlockBase.PropagarCheckHijos(ANode: TcxTreeListNode;
  AValue: Boolean);
var
  i: Integer;
begin
  for i := 0 to ANode.Count - 1 do
  begin
    SetNodoChecked(ANode.Items[i], AValue);
    PropagarCheckHijos(ANode.Items[i], AValue);
  end;
end;

procedure TfrmModalAddBlockBase.btnExpandirFamiliasClick(Sender: TObject);
begin
  tlFamilias.FullExpand;
end;

procedure TfrmModalAddBlockBase.btnContraerFamiliasClick(Sender: TObject);
begin
  tlFamilias.FullCollapse;
end;

procedure TfrmModalAddBlockBase.btnQuitarSelFamiliasClick(Sender: TObject);

  procedure ClearRec(N: TcxTreeListNode);
  var i: Integer;
  begin
    SetNodoChecked(N, False);
    for i := 0 to N.Count - 1 do ClearRec(N.Items[i]);
  end;

var
  i: Integer;
begin
  FPropagandoCheck := True;
  try
    for i := 0 to tlFamilias.Count - 1 do
      ClearRec(tlFamilias.Items[i]);
  finally
    FPropagandoCheck := False;
  end;
  ActualizarContadores;
end;

// ============================================================================
//   RESTO DE EVENTOS
// ============================================================================

procedure TfrmModalAddBlockBase.btnQuitarSelProveedoresClick(Sender: TObject);
begin
  tvProveedores.DataController.ClearSelection;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnQuitarSelPropiedadesClick(Sender: TObject);
begin
  tvPropValores.DataController.ClearSelection;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnMarcarTodosAlmClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    chkLstAlmacenes.Items[i].Checked := True;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnDesmarcarTodosAlmClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    chkLstAlmacenes.Items[i].Checked := False;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.cbxPropiedadPropertiesChange(Sender: TObject);
var
  idx: Integer;
  cod: string;
begin
  idx := cbxPropiedad.ItemIndex;
  if (idx < 0) or (idx >= FCodigosPropiedades.Count) then Exit;
  cod := FCodigosPropiedades[idx];
  CargarValoresPropiedad(cod);
end;

procedure TfrmModalAddBlockBase.edtFiltroProveedorPropertiesChange(
  Sender: TObject);
var
  txt: string;
begin
  txt := Trim(edtFiltroProveedor.Text);
  if txt = '' then
    FQryProveedores.Filtered := False
  else
  begin
    FQryProveedores.Filter :=
      Format('RAZON_SOCIAL_PRV LIKE ''%%%s%%''',
             [StringReplace(txt, '''', '''''', [rfReplaceAll])]);
    FQryProveedores.Filtered := True;
  end;
end;

procedure TfrmModalAddBlockBase.tvProveedoresSelectionChanged(
  Sender: TcxCustomGridTableView);
begin
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.tvPropValoresSelectionChanged(
  Sender: TcxCustomGridTableView);
begin
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.chkLstAlmacenesClickCheck(Sender: TObject);
begin
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnLimpiarFiltrosClick(Sender: TObject);
var
  i: Integer;
begin
  if MessageDlg('Limpiar todos los filtros?', mtConfirmation,
                [mbYes, mbNo], 0) <> mrYes then
    Exit;
  btnQuitarSelFamiliasClick(nil);
  tvProveedores.DataController.ClearSelection;
  tvPropValores.DataController.ClearSelection;
  cbxPropiedad.ItemIndex := 0;
  CargarValoresPropiedad('');
  edtFiltroProveedor.Text := '';
  chkAplicarFechaAlta.Checked := False;
  chkConVenta.Checked := False;
  chkSoloConStock.Checked := False;
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    chkLstAlmacenes.Items[i].Checked := False;
  if FSqlPreview.Active then FSqlPreview.Close;
  lblPreviewInfo.Caption := '0 articulos';
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.ActualizarContadores;
var
  i, n: Integer;
begin
  lblSelFamilias.Caption :=
    Format('(%d sel.)', [Length(RecogerCodigosFamiliaSeleccionados)]);
  lblSelProveedores.Caption :=
    Format('(%d sel.)', [Length(RecogerCodigosProveedoresSeleccionados)]);
  lblSelPropiedades.Caption :=
    Format('(%d sel.)', [Length(RecogerIdsValorPropiedadSeleccionados)]);

  n := 0;
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    if chkLstAlmacenes.Items[i].Checked then Inc(n);
  lblSelAlmacenes.Caption := Format('(%d sel.)', [n]);

  if chkSoloConStock.Checked then
  begin
    if n = 0 then
      lblStockAviso.Caption := 'No hay almacenes seleccionados'
    else
      lblStockAviso.Caption := Format('%d almacen(es) seleccionados', [n]);
  end
  else
    lblStockAviso.Caption := '';
end;

// ============================================================================
//   RECOGIDA DE SELECCIONES
// ============================================================================

function TfrmModalAddBlockBase.RecogerCodigosFamiliaSeleccionados: TArray<string>;
var
  lst: TList<string>;

  procedure Recorrer(ANode: TcxTreeListNode);
  var
    i: Integer;
    v: Variant;
  begin
    if EsNodoChecked(ANode) then
    begin
      v := ANode.Values[tlcolFamiliasCodigo.ItemIndex];
      if not VarIsNull(v) then
        lst.Add(VarToStr(v));
    end;
    for i := 0 to ANode.Count - 1 do
      Recorrer(ANode.Items[i]);
  end;

var
  i: Integer;
begin
  lst := TList<string>.Create;
  try
    for i := 0 to tlFamilias.Count - 1 do
      Recorrer(tlFamilias.Items[i]);
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.RecogerCodigosProveedoresSeleccionados: TArray<string>;
var
  lst: TList<string>;
  i, n, recIdx: Integer;
  dc: TcxGridDBDataController;
begin
  lst := TList<string>.Create;
  try
    dc := tvProveedores.DataController;
    n  := dc.GetSelectedCount;
    for i := 0 to n - 1 do
    begin
      recIdx := dc.GetSelectedRowIndex(i);
      lst.Add(VarToStr(dc.Values[recIdx, colProvCodigo.Index]));
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.RecogerIdsValorPropiedadSeleccionados: TArray<Integer>;
var
  lst: TList<Integer>;
  i, n, recIdx: Integer;
  dc: TcxGridDBDataController;
  v: Variant;
begin
  lst := TList<Integer>.Create;
  try
    dc := tvPropValores.DataController;
    n  := dc.GetSelectedCount;
    for i := 0 to n - 1 do
    begin
      recIdx := dc.GetSelectedRowIndex(i);
      v := dc.Values[recIdx, colPropIdValor.Index];
      if not VarIsNull(v) then
        lst.Add(StrToIntDef(VarToStr(v), 0));
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.RecogerCodigosAlmacenesSeleccionados: TArray<string>;
var
  lst: TList<string>;
  i: Integer;
  it: TcxCheckListBoxItem;
begin
  lst := TList<string>.Create;
  try
    for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    begin
      it := chkLstAlmacenes.Items[i];
      if it.Checked and (it.ItemObject is TStringList) and
         (TStringList(it.ItemObject).Count > 0) then
        lst.Add(TStringList(it.ItemObject)[0]);
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.StockCombinacionActual: TStockCombinacion;
begin
  case rgStockCombinacion.ItemIndex of
    1: Result := scTodos;
    2: Result := scSumaPositiva;
  else
    Result := scCualquiera;
  end;
end;

// ============================================================================
//   HELPERS
// ============================================================================

function TfrmModalAddBlockBase.StrArrToCsvSql(const A: TArray<string>): string;
var
  i: Integer;
  s: string;
begin
  Result := '';
  for i := 0 to High(A) do
  begin
    s := StringReplace(A[i], '''', '''''', [rfReplaceAll]);
    if Result <> '' then Result := Result + ',';
    Result := Result + '''' + s + '''';
  end;
end;

function TfrmModalAddBlockBase.IntArrToCsvSql(const A: TArray<Integer>): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(A) do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + IntToStr(A[i]);
  end;
end;

// ============================================================================
//   CONSTRUCCION SQL
// ============================================================================

function TfrmModalAddBlockBase.ConstruirSQLPreview: string;
var
  sql       : TStringList;
  arrFam    : TArray<string>;
  arrProv   : TArray<string>;
  arrPropV  : TArray<Integer>;
  arrAlm    : TArray<string>;
  csvFam, csvProv, csvPropV, csvAlm: string;
  modoStock : TStockCombinacion;
  yaCargado : string;
  excluir   : string;
  selExtra  : string;
  whereExtra: string;
begin
  arrFam   := RecogerCodigosFamiliaSeleccionados;
  arrProv  := RecogerCodigosProveedoresSeleccionados;
  arrPropV := RecogerIdsValorPropiedadSeleccionados;
  arrAlm   := RecogerCodigosAlmacenesSeleccionados;

  csvFam   := StrArrToCsvSql(arrFam);
  csvProv  := StrArrToCsvSql(arrProv);
  csvPropV := IntArrToCsvSql(arrPropV);
  csvAlm   := StrArrToCsvSql(arrAlm);

  modoStock  := StockCombinacionActual;
  yaCargado  := SubquerYaCargado;
  excluir    := WhereExcluirYaCargados;
  selExtra   := ColumnasSelectExtra;
  whereExtra := FiltrosWhereExtra;

  sql := TStringList.Create;
  try
    sql.Add('SELECT a.CODIGO_ART_ART,');
    sql.Add('       a.DESCRIPCION_ART,');
    sql.Add('       a.CODIGO_FAM_ART,');
    sql.Add('       f.NOMBRE_FAM_FAM,');
    sql.Add('       (SELECT GROUP_CONCAT(ap.CODIGO_PRV_AP)');
    sql.Add('          FROM fza_articulos_proveedores ap');
    sql.Add('         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART');
    sql.Add('       ) AS PROVEEDORES,');

    // STOCK total filtrado por almacenes seleccionados (si hay)
    sql.Add('       COALESCE((SELECT SUM(s.CANTIDAD_STK)');
    sql.Add('                   FROM fza_articulos_stockactual s');
    sql.Add('                   LEFT JOIN fza_articulos_skus sk');
    sql.Add(
      '                          ON sk.CODIGO_UNIDAD_SKU = ' +
      's.CODIGO_UNIDAD_STK');
    sql.Add(
      '                  WHERE COALESCE(sk.CODIGO_ART_SKU, ' +
      's.CODIGO_UNIDAD_STK)');
    sql.Add('                        = a.CODIGO_ART_ART');
    if csvAlm <> '' then
      sql.Add('                    AND s.CODIGO_ALM_STK IN (' + csvAlm + ')');
    sql.Add('                ), 0) AS STOCK_TOTAL,');

    // Columnas extra del hijo (debe terminar en coma si las hay)
    if selExtra <> '' then
      sql.Add('       ' + selExtra);

    // YA_CARGADO: el hijo decide la subquery
    if yaCargado <> '' then
      sql.Add('       ' + yaCargado + ' AS YA_CARGADO')
    else
      sql.Add('       ''N'' AS YA_CARGADO');

    sql.Add('  FROM fza_articulos a');
    sql.Add('  LEFT JOIN fza_articulos_familias f');
    sql.Add('    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART');
    sql.Add(' WHERE 1 = 1');

    if chkSoloActivos.Checked then
      sql.Add('   AND a.ESACTIVO_ART = ''S''');

    if chkExcluirYaCargados.Checked and (excluir <> '') then
      sql.Add('   AND ' + excluir);

    // Filtros extra del hijo
    if whereExtra <> '' then
      sql.Add('   AND ' + whereExtra);

    // STOCK
    if chkSoloConStock.Checked and (csvAlm <> '') then
    begin
      case modoStock of
        scCualquiera:
          begin
            sql.Add(
              '   AND EXISTS (SELECT 1 FROM fza_articulos_stockactual s2');
            sql.Add('                LEFT JOIN fza_articulos_skus sk2');
            sql.Add(
              '                       ON sk2.CODIGO_UNIDAD_SKU = ' +
              's2.CODIGO_UNIDAD_STK');
            sql.Add(
              '                WHERE COALESCE(sk2.CODIGO_ART_SKU, ' +
              's2.CODIGO_UNIDAD_STK)');
            sql.Add('                      = a.CODIGO_ART_ART');
            sql.Add('                  AND s2.CANTIDAD_STK > 0');
            sql.Add(
              '                  AND s2.CODIGO_ALM_STK IN (' + csvAlm + '))');
          end;
        scTodos:
          begin
            sql.Add('   AND (SELECT COUNT(DISTINCT s2.CODIGO_ALM_STK)');
            sql.Add('          FROM fza_articulos_stockactual s2');
            sql.Add('          LEFT JOIN fza_articulos_skus sk2');
            sql.Add(
              '                 ON sk2.CODIGO_UNIDAD_SKU = ' +
              's2.CODIGO_UNIDAD_STK');
            sql.Add(
              '         WHERE COALESCE(sk2.CODIGO_ART_SKU, ' +
              's2.CODIGO_UNIDAD_STK)');
            sql.Add('               = a.CODIGO_ART_ART');
            sql.Add('           AND s2.CANTIDAD_STK > 0');
            sql.Add('           AND s2.CODIGO_ALM_STK IN (' + csvAlm + ')');
            sql.Add('       ) = ' + IntToStr(Length(arrAlm)));
          end;
        scSumaPositiva:
          begin
            sql.Add('   AND COALESCE((SELECT SUM(s2.CANTIDAD_STK)');
            sql.Add('                   FROM fza_articulos_stockactual s2');
            sql.Add('                   LEFT JOIN fza_articulos_skus sk2');
            sql.Add(
              '                          ON sk2.CODIGO_UNIDAD_SKU = ' +
              's2.CODIGO_UNIDAD_STK');
            sql.Add(
              '                  WHERE COALESCE(sk2.CODIGO_ART_SKU, ' +
              's2.CODIGO_UNIDAD_STK)');
            sql.Add('                        = a.CODIGO_ART_ART');
            sql.Add(
              '                    AND s2.CODIGO_ALM_STK IN (' + csvAlm + ')');
            sql.Add('                ), 0) > 0');
          end;
      end;
    end;

    // FAMILIAS
    if csvFam <> '' then
    begin
      if chkPropagarHijos.Checked then
      begin
        sql.Add('   AND a.CODIGO_FAM_ART IN (');
        sql.Add('     WITH RECURSIVE arbol AS (');
        sql.Add('       SELECT CODIGO_FAM_FAM, CODIGO_SUBFAMILIA_FAM');
        sql.Add('         FROM fza_articulos_familias');
        sql.Add('        WHERE CODIGO_FAM_FAM IN (' + csvFam + ')');
        sql.Add('       UNION ALL');
        sql.Add('       SELECT h.CODIGO_FAM_FAM, h.CODIGO_SUBFAMILIA_FAM');
        sql.Add('         FROM fza_articulos_familias h');
        sql.Add(
          '         JOIN arbol a2 ON h.CODIGO_SUBFAMILIA_FAM = ' +
          'a2.CODIGO_FAM_FAM');
        sql.Add('     )');
        sql.Add('     SELECT CODIGO_FAM_FAM FROM arbol');
        sql.Add('   )');
      end
      else
        sql.Add('   AND a.CODIGO_FAM_ART IN (' + csvFam + ')');
    end;

    // PROVEEDORES
    if csvProv <> '' then
    begin
      sql.Add('   AND EXISTS (SELECT 1 FROM fza_articulos_proveedores apx');
      sql.Add('                WHERE apx.CODIGO_ART_AP = a.CODIGO_ART_ART');
      sql.Add('                  AND apx.CODIGO_PRV_AP IN (' + csvProv + ')');
      if chkSoloPrincipal.Checked then
        sql.Add('                  AND apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
      sql.Add('              )');
    end;

    // PROPIEDADES
    if csvPropV <> '' then
    begin
      sql.Add('   AND EXISTS (SELECT 1 FROM fza_articulos_propiedades pp');
      sql.Add('                WHERE pp.CODIGO_ART_ART = a.CODIGO_ART_ART');
      sql.Add('                  AND pp.ID_PV_ARTPROP IN (' + csvPropV + '))');
    end;

    // FECHA DE ALTA
    if chkAplicarFechaAlta.Checked then
    begin
      sql.Add('   AND a.INSTANTE_ALTA >= :P_ALTA_DESDE');
      sql.Add('   AND a.INSTANTE_ALTA <  :P_ALTA_HASTA');
    end;

    // VENTAS
    if chkConVenta.Checked then
    begin
      if rgConSinVenta.ItemIndex = 0 then
      begin
        sql.Add('   AND (SELECT COUNT(*) FROM fza_facturas_lineas fl');
        sql.Add('         JOIN fza_facturas fc');
        sql.Add('           ON fc.NUMERO_FAC   = fl.NUMERO_FAC_FACLIN');
        sql.Add('          AND fc.SERIE_FAC = fl.SERIE_FAC_FACLIN');
        sql.Add('        WHERE fl.CODIGO_ART_FACLIN = a.CODIGO_ART_ART');
        sql.Add(
          '          AND fc.FECHA_FAC BETWEEN :P_VTA_DESDE AND :P_VTA_HASTA');
        sql.Add('       ) >= :P_NUM_MIN_VTAS');
      end
      else
      begin
        sql.Add('   AND NOT EXISTS (SELECT 1 FROM fza_facturas_lineas fl');
        sql.Add('         JOIN fza_facturas fc');
        sql.Add('           ON fc.NUMERO_FAC   = fl.NUMERO_FAC_FACLIN');
        sql.Add('          AND fc.SERIE_FAC = fl.SERIE_FAC_FACLIN');
        sql.Add('        WHERE fl.CODIGO_ART_FACLIN = a.CODIGO_ART_ART');
        sql.Add(
          '          AND fc.FECHA_FAC BETWEEN :P_VTA_DESDE AND :P_VTA_HASTA)');
      end;
    end;

    sql.Add(' ORDER BY a.CODIGO_FAM_ART, a.CODIGO_ART_ART');

    Result := sql.Text;
  finally
    FreeAndNil(sql);
  end;
end;

procedure TfrmModalAddBlockBase.AplicarParametros(AQry: TUniQuery);

  function HasParam(const N: string): Boolean;
  begin
    Result := AQry.Params.FindParam(N) <> nil;
  end;

begin
  if HasParam('P_ALTA_DESDE') then
    AQry.ParamByName('P_ALTA_DESDE').AsDateTime := dtAltaDesde.Date;
  if HasParam('P_ALTA_HASTA') then
    AQry.ParamByName('P_ALTA_HASTA').AsDateTime := dtAltaHasta.Date + 1;
  if HasParam('P_VTA_DESDE') then
    AQry.ParamByName('P_VTA_DESDE').AsDateTime := dtVtaDesde.Date;
  if HasParam('P_VTA_HASTA') then
    AQry.ParamByName('P_VTA_HASTA').AsDateTime := dtVtaHasta.Date;
  if HasParam('P_NUM_MIN_VTAS') then
    AQry.ParamByName('P_NUM_MIN_VTAS').AsInteger := spnNumMinVtas.Value;

  // El hijo añade los suyos (P_TARIFA_xxx, P_INVENTARIO_xxx...)
  VincularParametrosExtra(AQry);
end;

// ============================================================================
//   PREVIEW Y ACEPTAR
// ============================================================================

procedure TfrmModalAddBlockBase.btnPrevisualizarClick(Sender: TObject);
var
  sql      : string;
  msg      : string;
begin
  if not ValidarAntesDePrevisualizar(msg) then
  begin
    if msg <> '' then ShowMessage(msg);
    Exit;
  end;

  if chkSoloConStock.Checked and
     (Length(RecogerCodigosAlmacenesSeleccionados) = 0) then
  begin
    ShowMessage('Has activado "Solo con stock" pero no hay almacenes ' +
                'seleccionados en la pestana Almacenes.');
    pcFiltros.ActivePage := tsAlmacenes;
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    sql := ConstruirSQLPreview;

    FSqlPreview.Close;
    FSqlPreview.Connection := FConn;
    FSqlPreview.SQL.Text   := sql;
    AplicarParametros(FSqlPreview);
    FSqlPreview.Open;

    tvPreview.DataController.DataSource := FDsPreview;
    ConfigurarPreviewExtra;

    lblPreviewInfo.Caption :=
      Format('%d articulos coinciden con el filtro', [FSqlPreview.RecordCount]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalAddBlockBase.btnAceptarClick(Sender: TObject);
var
  numIns     : Integer;
  codigos    : TArray<string>;
  pendientes : Integer;
begin
  if (not FSqlPreview.Active) or (FSqlPreview.RecordCount = 0) then
  begin
    if MessageDlg('No has previsualizado. Previsualizar ahora?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      btnPrevisualizarClick(nil);
      if (not FSqlPreview.Active) or (FSqlPreview.RecordCount = 0) then Exit;
    end
    else
      Exit;
  end;

  pendientes := 0;
  FSqlPreview.DisableControls;
  try
    FSqlPreview.First;
    while not FSqlPreview.Eof do
    begin
      if FSqlPreview.FieldByName('YA_CARGADO').AsString <> 'S' then
        Inc(pendientes);
      FSqlPreview.Next;
    end;
    FSqlPreview.First;
  finally
    FSqlPreview.EnableControls;
  end;

  if pendientes = 0 then
  begin
    ShowMessage(
      'Todos los articulos del filtro ya estan cargados. Nada que insertar.');
    Exit;
  end;

  if MessageDlg(TextoConfirmacion(pendientes),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if EjecutarInsercion(numIns, codigos) then
  begin
    FBaseResultado.Aceptado         := True;
    FBaseResultado.NumInsertados    := numIns;
    FBaseResultado.ArticulosCodigos := codigos;
    ShowMessage(TextoExito(numIns));
    Self.ModalResult := mrOk;
  end;
end;

procedure TfrmModalAddBlockBase.btnCancelarClick(Sender: TObject);
begin
  FBaseResultado.Aceptado := False;
  Self.ModalResult := mrCancel;
end;

end.
