{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalWizardEditar                                        }
{    Tipo:       Formulario (Modal - Wizard)                                   }
{ Version:       0.1.0                                                         }
{   Fecha:       19/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Wizard de edicion de un informe FastReport. Usa TJvWizard con dos         }
{    paginas:                                                                  }
{      Paso 1 - Formato: elegir formato existente o nuevo + permiso.           }
{      Paso 2 - Guias  : ver datasets (cabecera + detalle) del informe         }
{                        con sus campos y configurar las guias que se          }
{                        ligaran al formato del Paso 1.                        }
{                                                                              }
{    Al pulsar Finalizar, el TfrmPrint que lo invoca recibe sFormato,          }
{    sScope y bExiste (si el formato ya existia en fza_usuarios_perfiles)      }
{    y abre el diseñador FastReport con esos datos fijados. Al guardar el      }
{    .frx, el TfrmPrint salta el dialogo de "Guardar Objeto Editado" y         }
{    persiste con el nombre/permiso que el usuario eligio aqui.                }
{******************************************************************************}
unit inMtoModalWizardEditar;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, dxCore, dxSkinsForm, dxSkinsCore, dxSkinBlue,
  cxClasses, cxContainer, cxEdit, cxControls, cxLookAndFeels, cxLocalization,
  cxGraphics, cxLookAndFeelPainters, cxButtons, cxStyles, cxLabel, cxTextEdit,
  cxDropDownEdit, cxMaskEdit, cxCustomListBox, cxListBox, cxCheckListBox,
  cxCheckBox,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid,
  frxClass, frxDBSet,
  JvComponentBase, JvEnterTab, JvWizard, JvWizardRouteMapNodes;

type
  TfrmModalWizardEditar = class(TfrmBase)
    wzWizard: TJvWizard;
    pgFormato: TJvWizardInteriorPage;
    pgGuias: TJvWizardInteriorPage;
    // --- Paso 1: Formato ---
    pnlPaso1: TPanel;
    lblOrigen: TcxLabel;
    edtOrigen: TcxTextEdit;
    lblFormato: TcxLabel;
    cbbFormato: TcxComboBox;
    lblNombreNuevo: TcxLabel;
    edtNombreNuevo: TcxTextEdit;
    lblScope: TcxLabel;
    cbbScope: TcxComboBox;
    lblAyudaPaso1: TcxLabel;
    // --- Paso 2: Guias ---
    pnlPaso2: TPanel;
    pnlInfoGuias: TPanel;
    lblTituloGuias: TcxLabel;
    pnlSelectorDS: TPanel;
    lblDatasets: TcxLabel;
    lstDatasets: TcxListBox;
    lblCampos: TcxLabel;
    lstCampos: TcxCheckListBox;
    lblTablas: TcxLabel;
    lstTablas: TcxListBox;
    lblCamposTabla: TcxLabel;
    lstCamposTabla: TcxListBox;
    pnlAddGuia: TPanel;
    lblCodigoNuevo: TcxLabel;
    btnAddGuia: TcxButton;
    unqryTablas: TUniQuery;
    unqryCamposTabla: TUniQuery;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasTIPO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasSQL: TcxGridDBColumn;
    tvGuiasMASTER_FIELDS: TcxGridDBColumn;
    tvGuiasDETAIL_FIELDS: TcxGridDBColumn;
    tvGuiasORDEN: TcxGridDBColumn;
    tvGuiasACTIVO: TcxGridDBColumn;
    // --- Datos ---
    unqryFormatos: TUniQuery;
    unqryGuias: TUniQuery;
    dsGuias: TDataSource;
    ActionList1: TActionList;
    actCancelar: TAction;
    cxStyleRepo: TcxStyleRepository;
    cxsHeader: TcxStyle;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actCancelarExecute(Sender: TObject);
    procedure cbbFormatoPropertiesChange(Sender: TObject);
    procedure wzWizardFinishButtonClick(Sender: TObject);
    procedure wzWizardCancelButtonClick(Sender: TObject);
    procedure pgFormatoNextButtonClick(Sender: TObject;
                                       var Stop: Boolean);
    procedure pgGuiasShow(Sender: TObject);
    procedure unqryGuiasBeforePost(DataSet: TDataSet);
    procedure lstDatasetsClick(Sender: TObject);
    procedure lstTablasClick(Sender: TObject);
    procedure lstCamposTablaClick(Sender: TObject);
    procedure btnAddGuiaClick(Sender: TObject);
  private
    // Orden de seleccion del usuario en lstCamposTabla (Shift/Ctrl).
    // TcxListBox.Selected[] solo expone que items estan seleccionados,
    // no en que orden — pero el ON clause del LEFT JOIN se construye
    // EXT.detail[k] = M.master[k] por posicion, asi que conservar el
    // orden de seleccion del usuario es critico.
    FOrdenDetail: TStringList;
    procedure CargarFormatosExistentes;
    procedure CargarScopes;
    procedure RellenarListDatasets;
    procedure RellenarListCampos;
    procedure RellenarListTablas;
    procedure RellenarListCamposTabla;
    procedure FiltrarGuiasPorDatasetSeleccionado;
    function DatasetMasterSeleccionado: string;
    function TablaSeleccionada: string;
    function CamposTablaMarcadosCsv(const aSep: string = ';'): string;
    function CamposMarcadosCsv(const aSep: string = ';'): string;
    // Quita el prefijo '* ' / '  ' que pintamos delante de cada campo
    // (PK marcada con '*'). Devuelve el nombre limpio.
    function LimpiarPrefijoPk(const aTexto: string): string;
    function NombreFinal: string;
    function EsFormatoNuevo: Boolean;
    // Cascada A->C->B para resolver los campos de un master:
    //  A: TfrxDBDataset.Fields o DataSet.Fields si esta abierto
    //  C: parsear "FROM <vista>" del SQL y leer information_schema
    //  B: abrir una query temporal con parametros dummy por tipo
    function CargarCamposDelInforme(oFrx: TfrxDBDataset): Boolean;
    function CargarCamposParseandoSql(const aSql: string): Boolean;
    function CargarCamposAbriendoTemporal(qrySrc: TUniQuery): Boolean;
    function ExtraerTablaFromSql(const aSql: string): string;
    procedure RellenarParametrosDummy(qry: TUniQuery);
    function ResolverDataSet(oFrx: TfrxDBDataset): TDataSet;
  public
    // El TfrmPrint rellena ANTES del ShowModal:
    sInforme: string;       // Self.Name del informe
    FReport:  TfrxReport;   // referencia al frxrprt1 para listar datasets
    // El wizard devuelve al cerrar:
    sFicha:   string;       // 'S' = Finalizar, 'N' = Cancelar
    sFormato: string;       // nombre del formato elegido / nuevo
    sScope:   string;       // permiso (USUARIO_GRUPO_USUPER)
    bExiste:  Boolean;      // si el formato ya estaba guardado
  end;

implementation

{$R *.dfm}

uses
  UniDataConn, inLibUser, inLibGlobalVar;

const
  ITEM_NUEVO = '<< Nuevo formato >>';

procedure TfrmModalWizardEditar.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  sFicha   := 'N';
  sFormato := '';
  sScope   := '';
  bExiste  := False;
  // Hacemos que el wizard ocupe todo el form en runtime. TJvWizard
  // hereda Align de TCustomControl pero no la publica, asi que la
  // setamos en codigo (en DFM daria 'Property Align does not exist').
  wzWizard.Align := alClient;
  // Default de TcxCheckListBox.EditValueFormat es cvfInteger -> tope
  // 64 items (los estados van empaquetados como bits de un integer).
  // VI_FACTURAS_PRINT y otras vistas del proyecto tienen mas. Usamos
  // cvfIndices, que serializa los indices marcados como string sin
  // limite. CamposMarcadosCsv sigue leyendo Items[i].Checked, asi
  // que el formato del EditValue es solo para almacenamiento interno.
  lstCampos.EditValueFormat := cvfIndices;
  // Lista de campos de la tabla externa seleccionados, en orden de
  // seleccion del usuario. Se rellena/reconcilia en lstCamposTablaClick.
  FOrdenDetail := TStringList.Create;
  // Los botones Start/Last/Help quedan ocultos en cada pagina via
  // VisibleButtons (propiedad publicada de TJvWizardCustomPage).
  // TJvWizardNavigateButton no expone Visible.
end;

procedure TfrmModalWizardEditar.FormShow(Sender: TObject);
begin
  inherited;
  unqryFormatos.Connection := ConexionPrincipal;
  unqryGuias.Connection    := ConexionPrincipal;
  edtOrigen.Text := sInforme;
  // Textos del header del wizard y botones habilitados por pagina:
  // los seteamos en codigo para no depender de propiedades anidadas
  // en el DFM que podrian variar entre versiones de TJvWizard.
  try
    pgFormato.Header.Title.Text :=
      'Paso 1 de 2 — Formato a editar';
    pgFormato.Header.Subtitle.Text :=
      'Elige un formato existente o crea uno nuevo. ' +
      'El nombre y el permiso quedan fijados durante toda la edición.';
    pgGuias.Header.Title.Text :=
      'Paso 2 de 2 — Guías de datos';
    pgGuias.Header.Subtitle.Text :=
      'Consulta los datasets disponibles del informe y configura ' +
      'las guías auxiliares que se ligarán al formato.';
  except
    // Si la version de TJvWizard difiere y estas propiedades no
    // existen, no es critico: el wizard sigue funcionando.
  end;
  // Botones visibles y habilitados por pagina. VisibleButtons oculta
  // los botones que no aparezcan en el set, por eso no hace falta
  // tocar Visible en cada TJvWizardNavigateButton (no esta publicada).
  pgFormato.VisibleButtons := [bkNext, bkCancel];
  pgFormato.EnabledButtons := [bkNext, bkCancel];
  pgGuias.VisibleButtons   := [bkBack, bkFinish, bkCancel];
  pgGuias.EnabledButtons   := [bkBack, bkFinish, bkCancel];
  CargarFormatosExistentes;
  CargarScopes;
  cbbFormato.ItemIndex := 0;
  cbbFormatoPropertiesChange(cbbFormato);
  if edtNombreNuevo.CanFocus then
    edtNombreNuevo.SetFocus;
end;

procedure TfrmModalWizardEditar.FormClose(Sender: TObject;
                                          var Action: TCloseAction);
begin
  inherited;
  if unqryGuias.State in [dsEdit, dsInsert] then
    unqryGuias.Post;
  unqryGuias.Close;
  FreeAndNil(FOrdenDetail);
end;

procedure TfrmModalWizardEditar.CargarFormatosExistentes;
begin
  unqryFormatos.Close;
  unqryFormatos.ParamByName('KEY').AsString := sInforme;
  unqryFormatos.ParamByName('USU').AsString := IdentidadSesion.Usuario;
  unqryFormatos.ParamByName('GRP').AsString := IdentidadSesion.Grupo;
  unqryFormatos.ParamByName('ALL').AsString := oAll;
  unqryFormatos.Open;
  cbbFormato.Properties.Items.BeginUpdate;
  try
    cbbFormato.Properties.Items.Clear;
    cbbFormato.Properties.Items.Add(ITEM_NUEVO);
    while not unqryFormatos.Eof do
    begin
      cbbFormato.Properties.Items.Add(
        unqryFormatos.FieldByName('VALUE_USUPER').AsString);
      unqryFormatos.Next;
    end;
  finally
    cbbFormato.Properties.Items.EndUpdate;
  end;
  unqryFormatos.Close;
end;

procedure TfrmModalWizardEditar.CargarScopes;
begin
  cbbScope.Properties.Items.BeginUpdate;
  try
    cbbScope.Properties.Items.Clear;
    cbbScope.Properties.Items.Add(IdentidadSesion.Usuario);
    cbbScope.Properties.Items.Add(IdentidadSesion.Grupo);
    if (IdentidadSesion.GrupoRaiz = 'S') then
      cbbScope.Properties.Items.Add(oAll);
  finally
    cbbScope.Properties.Items.EndUpdate;
  end;
  cbbScope.Text := IdentidadSesion.Usuario;
end;

function TfrmModalWizardEditar.EsFormatoNuevo: Boolean;
begin
  Result := (cbbFormato.ItemIndex <= 0) or
            SameText(Trim(cbbFormato.Text), ITEM_NUEVO);
end;

function TfrmModalWizardEditar.NombreFinal: string;
begin
  if EsFormatoNuevo then
    Result := Trim(edtNombreNuevo.Text)
  else
    Result := Trim(cbbFormato.Text);
end;

procedure TfrmModalWizardEditar.cbbFormatoPropertiesChange(Sender: TObject);
var
  bNuevo: Boolean;
begin
  bNuevo := EsFormatoNuevo;
  edtNombreNuevo.Enabled := bNuevo;
  edtNombreNuevo.Properties.ReadOnly := not bNuevo;
  if bNuevo then
    edtNombreNuevo.Style.Color := clWindow
  else
  begin
    edtNombreNuevo.Text := cbbFormato.Text;
    edtNombreNuevo.Style.Color := clBtnFace;
  end;
end;

procedure TfrmModalWizardEditar.pgFormatoNextButtonClick(Sender: TObject;
                                                         var Stop: Boolean);
begin
  // Validar que tenemos nombre antes de pasar al paso 2.
  if NombreFinal = '' then
  begin
    ShowMessage('Indique un nombre para el formato.');
    Stop := True;
    Exit;
  end;
  if SameText(NombreFinal, ITEM_NUEVO) then
  begin
    ShowMessage('Escriba un nombre nuevo para el formato.');
    Stop := True;
    Exit;
  end;
  // Fijar la informacion del paso 1 antes de mostrar paso 2.
  sFormato := NombreFinal;
  sScope   := cbbScope.Text;
  if sScope = '' then sScope := IdentidadSesion.Usuario;
  bExiste  := not EsFormatoNuevo;
end;

procedure TfrmModalWizardEditar.pgGuiasShow(Sender: TObject);
begin
  // Cabecera del paso 2 con el formato elegido.
  lblTituloGuias.Caption :=
    Format(string('Gu'#237'as ligadas al formato "%s"  ('#39'%s'#39')'),
           [sFormato, sScope]);
  // Aseguro conexion en los TUniQuery del wizard.
  unqryGuias.Connection         := ConexionPrincipal;
  unqryTablas.Connection        := ConexionPrincipal;
  unqryCamposTabla.Connection   := ConexionPrincipal;
  // Abrir las guias filtradas por (informe, formato elegido) +
  // las globales del informe.
  unqryGuias.Close;
  unqryGuias.ParamByName('INF').AsString := sInforme;
  unqryGuias.Open;
  // Pintar la lista de UserName del .frx. Al seleccionar uno se
  // pintan sus campos a la derecha y se filtran las guias del grid.
  RellenarListDatasets;
  // Al abrir no preseleccionamos ningun dataset: el grid muestra
  // TODAS las guias del informe (asi el usuario las ve aunque sean
  // de masters distintos al primero). En cuanto haga click en un
  // dataset, se aplica el filtro y se pintan sus campos.
  lstDatasets.ItemIndex := -1;
  FiltrarGuiasPorDatasetSeleccionado;
  // Cargar la lista de tablas y vistas del esquema. El click sobre
  // una pinta sus columnas (con la PK marcada con '*').
  RellenarListTablas;
end;

procedure TfrmModalWizardEditar.RellenarListDatasets;
var
  i: Integer;
  oFrx: TfrxDBDataset;
  sUserName: string;
begin
  lstDatasets.Items.BeginUpdate;
  try
    lstDatasets.Items.Clear;
    if FReport = nil then Exit;
    for i := 0 to FReport.Datasets.Count - 1 do
    begin
      if not (FReport.Datasets[i].DataSet is TfrxDBDataset) then Continue;
      oFrx := TfrxDBDataset(FReport.Datasets[i].DataSet);
      sUserName := oFrx.UserName;
      if sUserName = '' then Continue;
      lstDatasets.Items.AddObject(sUserName, oFrx);
    end;
  finally
    lstDatasets.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.RellenarListCampos;
var
  oFrx: TfrxDBDataset;
  oDS: TDataSet;
begin
  // Cascada: el usuario quiere que los campos salgan, en este orden:
  //   A) Del informe (DataSet.Fields del TDataSet asociado al
  //      TfrxDBDataset; resolvemos por DataSource si hace falta).
  //   C) Parseando el FROM del SQL del TUniQuery y consultando
  //      information_schema.COLUMNS de la vista origen.
  //   B) Como ultimo recurso: abrir una query temporal con dummies.
  lstCampos.Items.BeginUpdate;
  try
    lstCampos.Items.Clear;
    if (lstDatasets.ItemIndex < 0) or
       (lstDatasets.ItemIndex >= lstDatasets.Count) then Exit;
    oFrx := TfrxDBDataset(lstDatasets.Items.Objects[lstDatasets.ItemIndex]);
    if oFrx = nil then Exit;

    // A) Del informe (resuelve DataSet via DataSource si hace falta).
    if CargarCamposDelInforme(oFrx) then Exit;

    oDS := ResolverDataSet(oFrx);
    if (oDS = nil) or not (oDS is TUniQuery) then Exit;

    // C) Parsear FROM y leer information_schema.
    if CargarCamposParseandoSql(TUniQuery(oDS).SQL.Text) then Exit;

    // B) Abrir query temporal con dummies.
    CargarCamposAbriendoTemporal(TUniQuery(oDS));
  finally
    lstCampos.Items.EndUpdate;
  end;
end;

function TfrmModalWizardEditar.ResolverDataSet(
                                  oFrx: TfrxDBDataset): TDataSet;
begin
  // TfrxDBDataset puede engancharse al TDataSet de dos formas:
  //   * DataSet := tabla / consulta directamente.
  //   * DataSource := TDataSource, que apunta al TDataSet.
  // En Factuzam la convencion habitual es DataSource (asi enlaza
  // fxdsPrintFac con dsFacPrint en UniDataFacturas.dfm). Aqui
  // resolvemos ambos casos.
  Result := oFrx.DataSet;
  if (Result = nil) and (oFrx.DataSource <> nil) then
    Result := oFrx.DataSource.DataSet;
end;

function TfrmModalWizardEditar.CargarCamposDelInforme(
                                  oFrx: TfrxDBDataset): Boolean;
var
  j: Integer;
  oDS: TDataSet;
  qry: TUniQuery;
  bEraAbierto: Boolean;
  vOriginales: array of Variant;
begin
  // A) "Del informe": leer Fields del TDataSet asociado al TfrxDBDataset.
  //    Si esta cerrado lo abrimos NOSOTROS aqui — rellenando parametros
  //    con dummies por tipo — leemos los nombres, lo cerramos y
  //    restauramos los parametros originales para no romper la posterior
  //    impresion/PDF/Excel. Solo si Open lanza excepcion damos por
  //    fallido este nivel y caemos a C / B.
  Result := False;
  oDS := ResolverDataSet(oFrx);
  if oDS = nil then Exit;
  qry := nil;
  if oDS is TUniQuery then qry := TUniQuery(oDS);
  bEraAbierto := oDS.Active;
  try
    if not bEraAbierto then
    begin
      if qry <> nil then
      begin
        SetLength(vOriginales, qry.Params.Count);
        for j := 0 to qry.Params.Count - 1 do
          vOriginales[j] := qry.Params[j].Value;
        RellenarParametrosDummy(qry);
      end;
      try
        oDS.Open;
      except
        Exit;  // -> el caller intenta C, luego B
      end;
    end;
    for j := 0 to oDS.FieldCount - 1 do
      lstCampos.Items.Add.Text := oDS.Fields[j].FieldName;
    Result := oDS.FieldCount > 0;
  finally
    // Si nosotros lo abrimos, lo cerramos y restauramos parametros.
    // Si ya venia abierto, no tocamos.
    if (not bEraAbierto) and oDS.Active then
    begin
      oDS.Close;
      if (qry <> nil) and (Length(vOriginales) > 0) then
        for j := 0 to qry.Params.Count - 1 do
          qry.Params[j].Value := vOriginales[j];
    end;
  end;
end;

function TfrmModalWizardEditar.CargarCamposParseandoSql(
                                  const aSql: string): Boolean;
var
  sTabla: string;
begin
  Result := False;
  sTabla := ExtraerTablaFromSql(aSql);
  if sTabla = '' then Exit;
  try
    unqryCamposTabla.Close;
    unqryCamposTabla.ParamByName('TAB').AsString := sTabla;
    unqryCamposTabla.Open;
    while not unqryCamposTabla.Eof do
    begin
      lstCampos.Items.Add.Text :=
        unqryCamposTabla.FieldByName('COLUMN_NAME').AsString;
      unqryCamposTabla.Next;
    end;
    Result := lstCampos.Items.Count > 0;
  finally
    unqryCamposTabla.Close;
  end;
end;

function TfrmModalWizardEditar.CargarCamposAbriendoTemporal(
                                  qrySrc: TUniQuery): Boolean;
var
  j: Integer;
  qryTmp: TUniQuery;
  sSql: string;
begin
  Result := False;
  qryTmp := nil;
  try
    sSql := TrimRight(qrySrc.SQL.Text);
    while (sSql <> '') and (sSql[Length(sSql)] = ';') do
    begin
      SetLength(sSql, Length(sSql) - 1);
      sSql := TrimRight(sSql);
    end;
    if sSql = '' then Exit;
    qryTmp := TUniQuery.Create(nil);
    qryTmp.Connection := ConexionPrincipal;
    // Envoltorio para no traer filas reales aunque los parametros
    // dummy hagan match.
    qryTmp.SQL.Text :=
      'select * from (' + sSql + ') X_FZA_GUIAS where 1=0';
    RellenarParametrosDummy(qryTmp);
    try
      qryTmp.Open;
      for j := 0 to qryTmp.FieldCount - 1 do
        lstCampos.Items.Add.Text := qryTmp.Fields[j].FieldName;
      Result := qryTmp.FieldCount > 0;
    except
    end;
  finally
    if qryTmp <> nil then FreeAndNil(qryTmp);
  end;
end;

function TfrmModalWizardEditar.ExtraerTablaFromSql(
                                  const aSql: string): string;
var
  sLow: string;
  i, p, pStart, pEnd: Integer;
  c: Char;
begin
  Result := '';
  if Trim(aSql) = '' then Exit;
  sLow := LowerCase(aSql);
  // Buscar el primer "from" como token (con whitespace antes o BOL,
  // y whitespace/'(' despues).
  p := 0;
  for i := 1 to Length(sLow) - 3 do
    if (Copy(sLow, i, 4) = 'from') and
       ((i = 1) or (sLow[i - 1] = ' ') or (sLow[i - 1] = #9) or
        (sLow[i - 1] = #10) or (sLow[i - 1] = #13)) and
       ((i + 4 > Length(sLow)) or (sLow[i + 4] = ' ') or
        (sLow[i + 4] = #9) or (sLow[i + 4] = #10) or
        (sLow[i + 4] = #13) or (sLow[i + 4] = '(')) then
    begin
      p := i;
      Break;
    end;
  if p = 0 then Exit;
  pStart := p + 4;
  while (pStart <= Length(sLow)) and
        ((sLow[pStart] = ' ') or (sLow[pStart] = #9) or
         (sLow[pStart] = #10) or (sLow[pStart] = #13)) do
    Inc(pStart);
  if pStart > Length(sLow) then Exit;
  // Si arranca con '(' es subquery — no podemos sacar la tabla aqui.
  if sLow[pStart] = '(' then Exit;
  pEnd := pStart;
  while pEnd <= Length(sLow) do
  begin
    c := sLow[pEnd];
    if ((c >= 'a') and (c <= 'z')) or ((c >= '0') and (c <= '9')) or
       (c = '_') or (c = '`') or (c = '.') then
      Inc(pEnd)
    else
      Break;
  end;
  Result := Copy(aSql, pStart, pEnd - pStart);
  // schema.tabla -> tabla
  i := LastDelimiter('.', Result);
  if i > 0 then Result := Copy(Result, i + 1, MaxInt);
  Result := StringReplace(Result, '`', '', [rfReplaceAll]);
end;

procedure TfrmModalWizardEditar.RellenarParametrosDummy(qry: TUniQuery);
var
  j: Integer;
begin
  for j := 0 to qry.Params.Count - 1 do
    case qry.Params[j].DataType of
      ftDate, ftDateTime, ftTime, ftTimeStamp:
        qry.Params[j].AsDateTime := Date;
      ftInteger, ftSmallint, ftWord, ftLargeint, ftAutoInc:
        qry.Params[j].AsInteger := 0;
      ftFloat, ftCurrency, ftBCD, ftFMTBcd:
        qry.Params[j].AsFloat := 0;
      ftString, ftWideString, ftFixedChar, ftFixedWideChar,
        ftMemo, ftWideMemo:
        qry.Params[j].AsString := '';
    else
      qry.Params[j].Clear;
    end;
end;

procedure TfrmModalWizardEditar.lstDatasetsClick(Sender: TObject);
begin
  RellenarListCampos;
  FiltrarGuiasPorDatasetSeleccionado;
end;

procedure TfrmModalWizardEditar.RellenarListTablas;
begin
  lstTablas.Items.BeginUpdate;
  try
    lstTablas.Items.Clear;
    unqryTablas.Close;
    unqryTablas.Open;
    while not unqryTablas.Eof do
    begin
      lstTablas.Items.Add(unqryTablas.FieldByName('TABLE_NAME').AsString);
      unqryTablas.Next;
    end;
    unqryTablas.Close;
  finally
    lstTablas.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.RellenarListCamposTabla;
var
  sCol, sKey: string;
begin
  lstCamposTabla.Items.BeginUpdate;
  try
    lstCamposTabla.Items.Clear;
    // Cambio de tabla externa = reset del orden de seleccion previo.
    if FOrdenDetail <> nil then
      FOrdenDetail.Clear;
    if TablaSeleccionada = '' then Exit;
    unqryCamposTabla.Close;
    unqryCamposTabla.ParamByName('TAB').AsString := TablaSeleccionada;
    unqryCamposTabla.Open;
    while not unqryCamposTabla.Eof do
    begin
      sCol := unqryCamposTabla.FieldByName('COLUMN_NAME').AsString;
      sKey := unqryCamposTabla.FieldByName('COLUMN_KEY').AsString;
      // PK marcada con '*' delante, asi salta a la vista.
      if SameText(sKey, 'PRI') then
        lstCamposTabla.Items.Add('* ' + sCol)
      else
        lstCamposTabla.Items.Add('  ' + sCol);
      unqryCamposTabla.Next;
    end;
    unqryCamposTabla.Close;
  finally
    lstCamposTabla.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.lstTablasClick(Sender: TObject);
begin
  RellenarListCamposTabla;
end;

procedure TfrmModalWizardEditar.lstCamposTablaClick(Sender: TObject);
var
  i, idx: Integer;
  sCampo: string;
begin
  // Reconciliacion FOrdenDetail <-> Selected[]:
  // 1) Quitamos los campos que el usuario ya no tiene seleccionados.
  // 2) Anadimos los recien seleccionados al final de la lista, asi
  //    el orden de seleccion del usuario se preserva (lo necesita el
  //    pareo posicional master[k]=detail[k] del ON clause).
  if FOrdenDetail = nil then
    Exit;
  for i := FOrdenDetail.Count - 1 downto 0 do
  begin
    sCampo := FOrdenDetail[i];
    idx := lstCamposTabla.Items.IndexOf('* ' + sCampo);
    if idx < 0 then
      idx := lstCamposTabla.Items.IndexOf('  ' + sCampo);
    if (idx < 0) or (not lstCamposTabla.Selected[idx]) then
      FOrdenDetail.Delete(i);
  end;
  for i := 0 to lstCamposTabla.Items.Count - 1 do
  begin
    if not lstCamposTabla.Selected[i] then Continue;
    sCampo := LimpiarPrefijoPk(lstCamposTabla.Items[i]);
    if FOrdenDetail.IndexOf(sCampo) < 0 then
      FOrdenDetail.Add(sCampo);
  end;
end;

function TfrmModalWizardEditar.TablaSeleccionada: string;
begin
  if (lstTablas.ItemIndex >= 0) and
     (lstTablas.ItemIndex < lstTablas.Count) then
    Result := lstTablas.Items[lstTablas.ItemIndex]
  else
    Result := '';
end;

function TfrmModalWizardEditar.LimpiarPrefijoPk(const aTexto: string): string;
var
  s: string;
begin
  s := aTexto;
  if (Length(s) >= 2) and ((Copy(s, 1, 2) = '* ') or (Copy(s, 1, 2) = '  ')) then
    Delete(s, 1, 2);
  Result := Trim(s);
end;

function TfrmModalWizardEditar.CamposTablaMarcadosCsv(
                                        const aSep: string): string;
var
  i: Integer;
begin
  Result := '';
  if FOrdenDetail = nil then Exit;
  for i := 0 to FOrdenDetail.Count - 1 do
  begin
    if Result <> '' then Result := Result + aSep;
    Result := Result + FOrdenDetail[i];
  end;
end;

procedure TfrmModalWizardEditar.FiltrarGuiasPorDatasetSeleccionado;
var
  sDS: string;
begin
  sDS := DatasetMasterSeleccionado;
  unqryGuias.Filtered := False;
  if sDS = '' then
    unqryGuias.Filter := ''
  else
    unqryGuias.Filter :=
      'DATASET_MASTER_INFGUI = ' + QuotedStr(sDS);
  unqryGuias.Filtered := sDS <> '';
end;

function TfrmModalWizardEditar.DatasetMasterSeleccionado: string;
begin
  if (lstDatasets.ItemIndex >= 0) and
     (lstDatasets.ItemIndex < lstDatasets.Count) then
    Result := lstDatasets.Items[lstDatasets.ItemIndex]
  else
    Result := '';
end;

function TfrmModalWizardEditar.CamposMarcadosCsv(const aSep: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to lstCampos.Items.Count - 1 do
    if lstCampos.Items[i].Checked then
    begin
      if Result <> '' then Result := Result + aSep;
      Result := Result + lstCampos.Items[i].Text;
    end;
end;

procedure TfrmModalWizardEditar.btnAddGuiaClick(Sender: TObject);
var
  sDS, sCampos, sTabla, sCampoTabla, sCodigo: string;
  function Sanitizar(const aStr: string): string;
  var k: Integer;
  begin
    Result := '';
    for k := 1 to Length(aStr) do
      if CharInSet(aStr[k], ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
        Result := Result + aStr[k]
      else
        Result := Result + '_';
  end;
begin
  sDS         := DatasetMasterSeleccionado;
  sCampos     := CamposMarcadosCsv;
  sTabla      := TablaSeleccionada;
  sCampoTabla := CamposTablaMarcadosCsv;

  if sDS = '' then
  begin
    ShowMessage('1) Selecciona el dataset master (cabecera o detalle) ' +
                'en la lista de la izquierda.');
    Exit;
  end;
  if sCampos = '' then
  begin
    ShowMessage('2) Marca al menos un campo del master ' +
                '(Master fields).');
    Exit;
  end;
  if sTabla = '' then
  begin
    ShowMessage('3) Selecciona la tabla o vista externa que quieres ligar.');
    Exit;
  end;
  if sCampoTabla = '' then
  begin
    ShowMessage('4) Selecciona el campo (o campos) de la tabla externa ' +
                'que se cruzan con el master. Para seleccionar varios ' +
                'usa Ctrl o Mayus; el orden de seleccion determina el ' +
                'pareo con los Master fields (k=1,2,...).');
    Exit;
  end;

  // El UserName en el .frx ES el del dataset master (no inventamos otro):
  // las guias enriquecen el master via LEFT JOIN en runtime, y los nuevos
  // campos quedan disponibles como [<DATASET_MASTER>."CAMPO"]. El
  // CODIGO_INFGUI es un identificador interno unico por (informe,
  // formato, master, tabla), se compone automaticamente.
  sCodigo := Sanitizar(sDS) + '_' + Sanitizar(sTabla);

  if not unqryGuias.Active then unqryGuias.Open;
  unqryGuias.Append;
  unqryGuias.FieldByName('CODIGO_INFGUI').AsString         := sCodigo;
  unqryGuias.FieldByName('INFORME_INFGUI').AsString        := sInforme;
  unqryGuias.FieldByName('FORMATO_INFGUI').AsString        := sFormato;
  unqryGuias.FieldByName('DATASET_MASTER_INFGUI').AsString := sDS;
  unqryGuias.FieldByName('MASTER_FIELDS_INFGUI').AsString  := sCampos;
  unqryGuias.FieldByName('DETAIL_FIELDS_INFGUI').AsString  := sCampoTabla;
  unqryGuias.FieldByName('TABLA_INFGUI').AsString          := sTabla;
  unqryGuias.FieldByName('TIPO_INFGUI').AsString           := 'TABLA';
  unqryGuias.FieldByName('ESACTIVO_INFGUI').AsString       := 'S';
  unqryGuias.FieldByName('ORDEN_INFGUI').AsInteger         := 0;
  unqryGuias.Post;
end;

procedure TfrmModalWizardEditar.unqryGuiasBeforePost(DataSet: TDataSet);
begin
  if DataSet.State = dsInsert then
  begin
    if DataSet.FieldByName('INFORME_INFGUI').IsNull or
       (DataSet.FieldByName('INFORME_INFGUI').AsString = '') then
      DataSet.FieldByName('INFORME_INFGUI').AsString := sInforme;
    if DataSet.FieldByName('FORMATO_INFGUI').IsNull then
      DataSet.FieldByName('FORMATO_INFGUI').AsString := sFormato;
    if DataSet.FieldByName('ESACTIVO_INFGUI').IsNull or
       (DataSet.FieldByName('ESACTIVO_INFGUI').AsString = '') then
      DataSet.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
    if DataSet.FieldByName('TIPO_INFGUI').IsNull or
       (DataSet.FieldByName('TIPO_INFGUI').AsString = '') then
      DataSet.FieldByName('TIPO_INFGUI').AsString := 'TABLA';
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString    := IdentidadSesion.Usuario;
end;

procedure TfrmModalWizardEditar.wzWizardFinishButtonClick(Sender: TObject);
begin
  // Aseguramos que cualquier guia en edicion queda persistida.
  if unqryGuias.State in [dsEdit, dsInsert] then
    unqryGuias.Post;
  sFicha := 'S';
  ModalResult := mrOk;
end;

procedure TfrmModalWizardEditar.wzWizardCancelButtonClick(Sender: TObject);
begin
  sFicha := 'N';
  ModalResult := mrCancel;
end;

procedure TfrmModalWizardEditar.actCancelarExecute(Sender: TObject);
begin
  wzWizardCancelButtonClick(Sender);
end;

end.
