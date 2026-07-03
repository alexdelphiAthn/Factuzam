{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalGuiasBase                                           }
{    Tipo:       Formulario base (Modal)                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Base compartida del constructor visual de guias (fza_informes_guias).     }
{    Provee la UI comun (listboxes, combo tablas, botones anadir/eliminar)     }
{    y define hooks virtuales que los hijos implementan:                       }
{      - TfrmModalGridGuias:     guias para grids (LEFT JOIN runtime)          }
{      - TfrmModalInformesGuias: guias para informes FastReport                }
{******************************************************************************}
unit inMtoModalGuiasBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions,
  Vcl.ActnList, Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, dxCore, dxSkinsForm, dxSkinsCore, dxSkinBlue,
  cxClasses, cxContainer, cxEdit, cxControls, cxLookAndFeels, cxLocalization,
  cxGraphics, cxLookAndFeelPainters, cxButtons, cxStyles, cxLabel, cxTextEdit,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid, cxMemo,
  cxDropDownEdit, cxListBox,
  JvComponentBase, JvEnterTab;

type
  TfrmModalGuiasBase = class(TfrmBase)
    pnlCabecera: TPanel;
    lblTitulo: TcxLabel;
    lblInfo: TcxLabel;
    pnlConstructor: TPanel;
    pnlCamposGrid: TPanel;
    lblCamposMaster: TcxLabel;
    lbCamposMaster: TcxListBox;
    pnlTabla: TPanel;
    lblTabla: TcxLabel;
    cbbTabla: TcxComboBox;
    lblCamposTabla: TcxLabel;
    lbCamposTabla: TcxListBox;
    pnlAcciones: TPanel;
    lblCodigo: TcxLabel;
    edtCodigo: TcxTextEdit;
    lblResumen: TcxLabel;
    mmoResumen: TcxMemo;
    btnAnadir: TcxButton;
    btnEliminar: TcxButton;
    pnlBotones: TPanel;
    btnCerrar: TcxButton;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    unqryGuias: TUniQuery;
    dsGuias: TDataSource;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasMASTER_FIELDS: TcxGridDBColumn;
    tvGuiasDETAIL_FIELDS: TcxGridDBColumn;
    tvGuiasORDEN: TcxGridDBColumn;
    tvGuiasACTIVO: TcxGridDBColumn;
    ActionList1: TActionList;
    actSalir: TAction;
    cxStyleRepo: TcxStyleRepository;
    cxsHeader: TcxStyle;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure cbbTablaPropertiesChange(Sender: TObject);
    procedure btnAnadirClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure lbCamposMasterClick(Sender: TObject);
    procedure lbCamposTablaClick(Sender: TObject);
  protected
    // Hooks que los hijos implementan
    procedure CargarCamposMaster; virtual; abstract;
    function ObtenerClaveInforme: string; virtual; abstract;
    function ObtenerTitulo: string; virtual; abstract;
    function ObtenerInfoCaption: string; virtual; abstract;
    function ObtenerDatasetMaster: string; virtual;
    function ObtenerFormatoSugerido: string; virtual;
    function ObtenerCampoMasterSeleccionado: string; virtual;
    procedure ConfigurarGuiaNueva; virtual;
  private
    procedure CargarTablas;
    procedure CargarCamposTabla(const sTabla: string);
    procedure ActualizarResumen;
    procedure AutoGenerarCodigo;
  public
    sFormulario: string;
  end;

implementation

{$R *.dfm}

uses
  UniDataConn, inLibUser, inLibGlobalVar, inLibLog;

procedure TfrmModalGuiasBase.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalGuiasBase.FormShow(Sender: TObject);
begin
  inherited;
  unqryGuias.Connection := oConn;
  unqryGuias.Close;
  unqryGuias.ParamByName('INF').AsString := ObtenerClaveInforme;
  unqryGuias.Open;
  lblTitulo.Caption := ObtenerTitulo;
  lblInfo.Caption := ObtenerInfoCaption;
  CargarCamposMaster;
  CargarTablas;
  ActualizarResumen;
end;

procedure TfrmModalGuiasBase.CargarTablas;
var
  qry: TUniQuery;
begin
  cbbTabla.Properties.Items.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT TABLE_NAME FROM information_schema.TABLES ' +
      ' WHERE TABLE_SCHEMA = database() ' +
      '   AND TABLE_TYPE IN (''BASE TABLE'', ''VIEW'') ' +
      ' ORDER BY TABLE_NAME';
    qry.Open;
    while not qry.Eof do
    begin
      cbbTabla.Properties.Items.Add(
        qry.FieldByName('TABLE_NAME').AsString);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmModalGuiasBase.cbbTablaPropertiesChange(Sender: TObject);
begin
  CargarCamposTabla(cbbTabla.Text);
  ActualizarResumen;
end;

procedure TfrmModalGuiasBase.CargarCamposTabla(const sTabla: string);
var
  qry: TUniQuery;
begin
  lbCamposTabla.Items.Clear;
  if sTabla = '' then
    Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT COLUMN_NAME FROM information_schema.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = database() AND TABLE_NAME = :TAB ' +
      ' ORDER BY ORDINAL_POSITION';
    qry.ParamByName('TAB').AsString := sTabla;
    qry.Open;
    while not qry.Eof do
    begin
      lbCamposTabla.Items.Add(
        qry.FieldByName('COLUMN_NAME').AsString);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmModalGuiasBase.ActualizarResumen;
var
  sMaster, sDetail, sTabla: string;
begin
  mmoResumen.Lines.Clear;
  sTabla := cbbTabla.Text;
  if sTabla = '' then
  begin
    mmoResumen.Lines.Add('Selecciona una tabla.');
    Exit;
  end;
  sMaster := '';
  sDetail := '';
  if lbCamposMaster.ItemIndex >= 0 then
    sMaster := ObtenerCampoMasterSeleccionado;
  if lbCamposTabla.ItemIndex >= 0 then
    sDetail := lbCamposTabla.Items[lbCamposTabla.ItemIndex];
  mmoResumen.Lines.Add('LEFT JOIN ' + sTabla);
  if (sMaster <> '') and (sDetail <> '') then
    mmoResumen.Lines.Add('  ON ' + sDetail + ' = ' + sMaster)
  else
    mmoResumen.Lines.Add('  (selecciona campo master y detail)');
  AutoGenerarCodigo;
end;

procedure TfrmModalGuiasBase.AutoGenerarCodigo;
var
  sMaster, sTabla, sDetail, sBase, sCodigo: string;
  i: Integer;
begin
  sTabla := UpperCase(cbbTabla.Text);
  if (sTabla <> '') and (lbCamposMaster.ItemIndex >= 0) and
     (lbCamposTabla.ItemIndex >= 0) then
  begin
    sMaster := UpperCase(ObtenerCampoMasterSeleccionado);
    sDetail := UpperCase(
      lbCamposTabla.Items[lbCamposTabla.ItemIndex]);
    sBase := sMaster + '.' + sTabla + '.' + sDetail;
    sCodigo := sBase;
    // Si ya existe una guía con ese código, añadir sufijo numérico
    if unqryGuias.Active then
    begin
      i := 1;
      unqryGuias.DisableControls;
      try
        while unqryGuias.Locate('CODIGO_INFGUI', sCodigo,
                                 [loCaseInsensitive]) do
        begin
          sCodigo := sBase + IntToStr(i);
          Inc(i);
        end;
      finally
        unqryGuias.EnableControls;
      end;
    end;
    edtCodigo.Text := sCodigo;
  end;
end;

procedure TfrmModalGuiasBase.lbCamposMasterClick(Sender: TObject);
begin
  ActualizarResumen;
end;

procedure TfrmModalGuiasBase.lbCamposTablaClick(Sender: TObject);
begin
  ActualizarResumen;
end;

// Hooks con implementacion por defecto

function TfrmModalGuiasBase.ObtenerDatasetMaster: string;
begin
  Result := '';
end;

function TfrmModalGuiasBase.ObtenerFormatoSugerido: string;
begin
  Result := '';
end;

function TfrmModalGuiasBase.ObtenerCampoMasterSeleccionado: string;
begin
  if lbCamposMaster.ItemIndex >= 0 then
    Result := lbCamposMaster.Items[lbCamposMaster.ItemIndex]
  else
    Result := '';
end;

procedure TfrmModalGuiasBase.ConfigurarGuiaNueva;
begin
  // Los hijos pueden añadir campos extra
end;

procedure TfrmModalGuiasBase.btnAnadirClick(Sender: TObject);
var
  sCodigo, sTabla, sMaster, sDetail: string;
begin
  sCodigo := Trim(edtCodigo.Text);
  sTabla  := cbbTabla.Text;
  if sCodigo = '' then
  begin
    ShowMessage('Escribe un código para la guía.');
    edtCodigo.SetFocus;
    Exit;
  end;
  if sTabla = '' then
  begin
    ShowMessage('Selecciona una tabla externa.');
    Exit;
  end;
  if lbCamposMaster.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona el campo master.');
    Exit;
  end;
  if lbCamposTabla.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona el campo detail (de la tabla).');
    Exit;
  end;
  sMaster := ObtenerCampoMasterSeleccionado;
  sDetail := lbCamposTabla.Items[lbCamposTabla.ItemIndex];
  unqryGuias.Append;
  unqryGuias.FieldByName('CODIGO_INFGUI').AsString := sCodigo;
  unqryGuias.FieldByName('INFORME_INFGUI').AsString := ObtenerClaveInforme;
  unqryGuias.FieldByName('FORMATO_INFGUI').AsString := ObtenerFormatoSugerido;
  unqryGuias.FieldByName('DATASET_MASTER_INFGUI').AsString :=
    ObtenerDatasetMaster;
  unqryGuias.FieldByName('TIPO_INFGUI').AsString := 'TABLA';
  unqryGuias.FieldByName('TABLA_INFGUI').AsString := sTabla;
  unqryGuias.FieldByName('MASTER_FIELDS_INFGUI').AsString := sMaster;
  unqryGuias.FieldByName('DETAIL_FIELDS_INFGUI').AsString := sDetail;
  unqryGuias.FieldByName('ORDEN_INFGUI').AsInteger :=
    unqryGuias.RecordCount;
  unqryGuias.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
  unqryGuias.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  unqryGuias.FieldByName('USUARIO_ALTA').AsString := oUser;
  unqryGuias.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  unqryGuias.FieldByName('USUARIO_MODIF').AsString := oUser;
  ConfigurarGuiaNueva;
  unqryGuias.Post;
  ShowMessage(Format('Guía "%s" añadida: %s.%s → %s',
    [sCodigo, sTabla, sDetail, sMaster]));
  edtCodigo.Text := '';
end;

procedure TfrmModalGuiasBase.btnEliminarClick(Sender: TObject);
begin
  if unqryGuias.IsEmpty then
  begin
    ShowMessage('No hay guías para eliminar.');
    Exit;
  end;
  if MessageDlg(
    Format('¿Eliminar la guía "%s"?',
      [unqryGuias.FieldByName('CODIGO_INFGUI').AsString]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    unqryGuias.Delete;
end;

procedure TfrmModalGuiasBase.FormClose(Sender: TObject;
                                       var Action: TCloseAction);
begin
  inherited;
  if unqryGuias.State in [dsEdit, dsInsert] then
    unqryGuias.Post;
  unqryGuias.Close;
end;

procedure TfrmModalGuiasBase.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmModalGuiasBase.actSalirExecute(Sender: TObject);
begin
  btnCerrarClick(Sender);
end;

end.
