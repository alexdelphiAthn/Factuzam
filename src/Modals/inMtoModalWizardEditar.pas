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
  cxDropDownEdit, cxMaskEdit, cxMemo,
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
    pnlAyudaGuias: TPanel;
    lblAyudaGuias: TcxLabel;
    mmoDatasets: TcxMemo;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasMASTER_DS: TcxGridDBColumn;
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
  private
    procedure CargarFormatosExistentes;
    procedure CargarScopes;
    procedure RellenarMemoDatasets;
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
  // Hacemos que el wizard ocupe todo el form en runtime, sin tocar el
  // DFM (TJvWizard no expone Align como propiedad publicada en algunas
  // versiones de JVCL, lo cual provocaba EReadError al cargar el form).
  try
    wzWizard.Align := alClient;
  except
  end;
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
  try
    // En paso 1 solo Siguiente y Cancelar; en paso 2 solo Anterior,
    // Finalizar y Cancelar.
    pgFormato.EnabledButtons := [bkNext, bkCancel];
    pgGuias.EnabledButtons   := [bkBack, bkFinish, bkCancel];
  except
  end;
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
  RellenarMemoDatasets;
end;

procedure TfrmModalWizardEditar.RellenarMemoDatasets;
var
  i, j: Integer;
  oFrx: TfrxDBDataset;
  oDS: TDataSet;
  sLine, sUserName: string;
begin
  mmoDatasets.Lines.BeginUpdate;
  try
    mmoDatasets.Lines.Clear;
    if FReport = nil then
    begin
      mmoDatasets.Lines.Add('(El informe no se ha pasado al wizard: ' +
                            'sin info de datasets.)');
      Exit;
    end;
    mmoDatasets.Lines.Add(Format(
      'Datasets disponibles en el informe %s', [sInforme]));
    mmoDatasets.Lines.Add('');
    if FReport.Datasets.Count = 0 then
    begin
      mmoDatasets.Lines.Add('(El informe no tiene datasets registrados.)');
      Exit;
    end;
    for i := 0 to FReport.Datasets.Count - 1 do
    begin
      if not (FReport.Datasets[i].DataSet is TfrxDBDataset) then Continue;
      oFrx := TfrxDBDataset(FReport.Datasets[i].DataSet);
      sUserName := oFrx.UserName;
      if sUserName = '' then sUserName := '(sin UserName)';
      mmoDatasets.Lines.Add('• ' + sUserName);
      oDS := oFrx.DataSet;
      if (oDS = nil) or (not oDS.Active) or (oDS.FieldCount = 0) then
      begin
        mmoDatasets.Lines.Add('    (sin campos disponibles)');
        mmoDatasets.Lines.Add('');
        Continue;
      end;
      sLine := '    ';
      for j := 0 to oDS.FieldCount - 1 do
      begin
        if Length(sLine) + Length(oDS.Fields[j].FieldName) > 95 then
        begin
          mmoDatasets.Lines.Add(sLine);
          sLine := '    ';
        end;
        if sLine <> '    ' then sLine := sLine + ', ';
        sLine := sLine + oDS.Fields[j].FieldName;
      end;
      if sLine <> '    ' then
        mmoDatasets.Lines.Add(sLine);
      mmoDatasets.Lines.Add('');
    end;
    mmoDatasets.Lines.Add(
      'Tip: copia el UserName a "Dataset master" y los campos a ' +
      '"Master fields" / "Detail fields" separados por '';''.');
  finally
    mmoDatasets.Lines.EndUpdate;
  end;
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
