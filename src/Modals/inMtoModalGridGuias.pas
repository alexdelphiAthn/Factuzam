{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalGridGuias                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.1.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Constructor visual de guias de grid. Muestra los campos del grid,        }
{    las tablas disponibles y los campos de la tabla seleccionada para        }
{    emparejar master/detail y crear la guia con un boton.                    }
{******************************************************************************}
unit inMtoModalGridGuias;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, dxCore, dxSkinsForm, dxSkinsCore, dxSkinBlue,
  cxClasses, cxContainer, cxEdit, cxControls, cxLookAndFeels, cxLocalization,
  cxGraphics, cxLookAndFeelPainters, cxButtons, cxStyles, cxLabel, cxTextEdit,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid, cxMemo,
  cxDropDownEdit, cxListBox,
  JvComponentBase, JvEnterTab;

type
  TfrmModalGridGuias = class(TfrmBase)
    pnlCabecera: TPanel;
    lblTitulo: TcxLabel;
    lblInfo: TcxLabel;
    pnlConstructor: TPanel;
    pnlCamposGrid: TPanel;
    lblCamposGrid: TcxLabel;
    lbCamposGrid: TcxListBox;
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
    procedure lbCamposGridClick(Sender: TObject);
    procedure lbCamposTablaClick(Sender: TObject);
  private
    procedure CargarCamposGrid;
    procedure CargarTablas;
    procedure CargarCamposTabla(const sTabla: string);
    procedure ActualizarResumen;
  public
    sFormulario: string;
    FDataSet: TDataSet;
  end;

implementation

{$R *.dfm}

uses
  UniDataConn, inLibUser, inLibGlobalVar, inLibLog;

procedure TfrmModalGridGuias.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalGridGuias.FormShow(Sender: TObject);
begin
  inherited;
  unqryGuias.Connection := oConn;
  unqryGuias.Close;
  unqryGuias.ParamByName('INF').AsString := 'GRID:' + sFormulario;
  unqryGuias.Open;
  lblInfo.Caption := Format('Formulario: %s', [sFormulario]);
  CargarCamposGrid;
  CargarTablas;
  ActualizarResumen;
end;

procedure TfrmModalGridGuias.CargarCamposGrid;
var
  i: Integer;
begin
  lbCamposGrid.Items.Clear;
  if (FDataSet = nil) or (not FDataSet.Active) then
    Exit;
  for i := 0 to FDataSet.FieldCount - 1 do
    lbCamposGrid.Items.Add(FDataSet.Fields[i].FieldName);
end;

procedure TfrmModalGridGuias.CargarTablas;
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
      '   AND TABLE_TYPE = ''BASE TABLE'' ' +
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

procedure TfrmModalGridGuias.cbbTablaPropertiesChange(Sender: TObject);
begin
  CargarCamposTabla(cbbTabla.Text);
  ActualizarResumen;
end;

procedure TfrmModalGridGuias.CargarCamposTabla(const sTabla: string);
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

procedure TfrmModalGridGuias.ActualizarResumen;
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
  if lbCamposGrid.ItemIndex >= 0 then
    sMaster := lbCamposGrid.Items[lbCamposGrid.ItemIndex];
  if lbCamposTabla.ItemIndex >= 0 then
    sDetail := lbCamposTabla.Items[lbCamposTabla.ItemIndex];
  mmoResumen.Lines.Add('LEFT JOIN ' + sTabla);
  if (sMaster <> '') and (sDetail <> '') then
    mmoResumen.Lines.Add('  ON ' + sDetail + ' = ' + sMaster)
  else
    mmoResumen.Lines.Add('  (selecciona campo master y detail)');
end;

procedure TfrmModalGridGuias.btnAnadirClick(Sender: TObject);
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
  if lbCamposGrid.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona el campo master (del grid).');
    Exit;
  end;
  if lbCamposTabla.ItemIndex < 0 then
  begin
    ShowMessage('Selecciona el campo detail (de la tabla).');
    Exit;
  end;
  sMaster := lbCamposGrid.Items[lbCamposGrid.ItemIndex];
  sDetail := lbCamposTabla.Items[lbCamposTabla.ItemIndex];
  // Insertar en la tabla
  unqryGuias.Append;
  unqryGuias.FieldByName('CODIGO_INFGUI').AsString := sCodigo;
  unqryGuias.FieldByName('INFORME_INFGUI').AsString :=
    'GRID:' + sFormulario;
  unqryGuias.FieldByName('FORMATO_INFGUI').AsString := '';
  unqryGuias.FieldByName('DATASET_MASTER_INFGUI').AsString := 'TablaG';
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
  unqryGuias.Post;
  ShowMessage(Format('Guía "%s" añadida: %s.%s → %s',
    [sCodigo, sTabla, sDetail, sMaster]));
  edtCodigo.Text := '';
end;

procedure TfrmModalGridGuias.btnEliminarClick(Sender: TObject);
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

procedure TfrmModalGridGuias.lbCamposGridClick(Sender: TObject);
begin
  ActualizarResumen;
end;

procedure TfrmModalGridGuias.lbCamposTablaClick(Sender: TObject);
begin
  ActualizarResumen;
end;

procedure TfrmModalGridGuias.FormClose(Sender: TObject;
                                       var Action: TCloseAction);
begin
  inherited;
  if unqryGuias.State in [dsEdit, dsInsert] then
    unqryGuias.Post;
  unqryGuias.Close;
end;

procedure TfrmModalGridGuias.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmModalGridGuias.actSalirExecute(Sender: TObject);
begin
  btnCerrarClick(Sender);
end;

end.
