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
    btnAddGuia: TcxButton;
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
    procedure btnAddGuiaClick(Sender: TObject);
  private
    procedure CargarFormatosExistentes;
    procedure CargarScopes;
    procedure RellenarListDatasets;
    procedure RellenarListCampos;
    procedure FiltrarGuiasPorDatasetSeleccionado;
    function DatasetMasterSeleccionado: string;
    function CamposMarcadosCsv(const aSep: string = ';'): string;
    function NombreFinal: string;
    function EsFormatoNuevo: Boolean;
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
  // Los botones Start/Last/Help quedan ocultos en cada pagina via
  // VisibleButtons (propiedad publicada de TJvWizardCustomPage).
  // TJvWizardNavigateButton no expone Visible.
end;

procedure TfrmModalWizardEditar.FormShow(Sender: TObject);
begin
  inherited;
  unqryFormatos.Connection := oConn;
  unqryGuias.Connection    := oConn;
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
end;

procedure TfrmModalWizardEditar.CargarFormatosExistentes;
begin
  unqryFormatos.Close;
  unqryFormatos.ParamByName('KEY').AsString := sInforme;
  unqryFormatos.ParamByName('USU').AsString := oUser;
  unqryFormatos.ParamByName('GRP').AsString := oGroup;
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
    cbbScope.Properties.Items.Add(oUser);
    cbbScope.Properties.Items.Add(oGroup);
    if (inLibGlobalVar.orootGroup = 'S') then
      cbbScope.Properties.Items.Add(oAll);
  finally
    cbbScope.Properties.Items.EndUpdate;
  end;
  cbbScope.Text := oUser;
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
  if sScope = '' then sScope := oUser;
  bExiste  := not EsFormatoNuevo;
end;

procedure TfrmModalWizardEditar.pgGuiasShow(Sender: TObject);
begin
  // Cabecera del paso 2 con el formato elegido.
  lblTituloGuias.Caption :=
    Format('Gu'#237'as ligadas al formato "%s"  ('#39'%s'#39')',
           [sFormato, sScope]);
  // Abrir las guias filtradas por (informe, formato elegido) +
  // las globales del informe.
  unqryGuias.Close;
  unqryGuias.ParamByName('INF').AsString := sInforme;
  unqryGuias.Open;
  // Pintar la lista de UserName del .frx. Al seleccionar uno se
  // pintan sus campos a la derecha y se filtran las guias del grid.
  RellenarListDatasets;
  if lstDatasets.Count > 0 then
  begin
    lstDatasets.ItemIndex := 0;
    lstDatasetsClick(lstDatasets);
  end;
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
  j: Integer;
  oFrx: TfrxDBDataset;
  oDS: TDataSet;
begin
  lstCampos.Items.BeginUpdate;
  try
    lstCampos.Items.Clear;
    if (lstDatasets.ItemIndex < 0) or
       (lstDatasets.ItemIndex >= lstDatasets.Count) then Exit;
    oFrx := TfrxDBDataset(lstDatasets.Items.Objects[lstDatasets.ItemIndex]);
    if oFrx = nil then Exit;
    oDS := oFrx.DataSet;
    if (oDS = nil) or (not oDS.Active) then Exit;
    for j := 0 to oDS.FieldCount - 1 do
      lstCampos.Items.Add(oDS.Fields[j].FieldName);
  finally
    lstCampos.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.lstDatasetsClick(Sender: TObject);
begin
  RellenarListCampos;
  FiltrarGuiasPorDatasetSeleccionado;
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
    if lstCampos.States[i] = cbsChecked then
    begin
      if Result <> '' then Result := Result + aSep;
      Result := Result + lstCampos.Items[i];
    end;
end;

procedure TfrmModalWizardEditar.btnAddGuiaClick(Sender: TObject);
var
  sDS, sCampos: string;
begin
  sDS := DatasetMasterSeleccionado;
  if sDS = '' then
  begin
    ShowMessage('Selecciona el dataset master (cabecera o detalle) en la ' +
                'lista de la izquierda antes de añadir una guía.');
    Exit;
  end;
  if not unqryGuias.Active then unqryGuias.Open;
  sCampos := CamposMarcadosCsv;
  unqryGuias.Append;
  unqryGuias.FieldByName('INFORME_INFGUI').AsString        := sInforme;
  unqryGuias.FieldByName('FORMATO_INFGUI').AsString        := sFormato;
  unqryGuias.FieldByName('DATASET_MASTER_INFGUI').AsString := sDS;
  if sCampos <> '' then
    unqryGuias.FieldByName('MASTER_FIELDS_INFGUI').AsString := sCampos;
  unqryGuias.FieldByName('TIPO_INFGUI').AsString    := 'TABLA';
  unqryGuias.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
  // Foco al grid para que el usuario complete CODIGO + TABLA + DETAIL.
  if grdGuias.CanFocus then grdGuias.SetFocus;
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
    DataSet.FieldByName('USUARIO_ALTA').AsString    := oUser;
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString    := oUser;
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
