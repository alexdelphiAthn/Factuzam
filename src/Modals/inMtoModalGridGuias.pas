{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalGridGuias                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Mantenimiento de guias de grid (fza_informes_guias) filtrado por el       }
{    formulario que lo invoca. Permite alta/baja/edicion de las guias que      }
{    enganchan columnas de tablas auxiliares al grid mediante LEFT JOIN en     }
{    runtime, sin recompilar.                                                  }
{    Replica para grids el patron de inMtoModalInformesGuias.                  }
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
  cxDropDownEdit, cxBlobEdit,
  JvComponentBase, JvEnterTab;

type
  TfrmModalGridGuias = class(TfrmBase)
    pnlCabecera: TPanel;
    lblTitulo: TcxLabel;
    lblInfo: TcxLabel;
    pnlAyuda: TPanel;
    lblAyuda: TcxLabel;
    mmoCampos: TcxMemo;
    pnlBotones: TPanel;
    btnCerrar: TcxButton;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    unqryGuias: TUniQuery;
    dsGuias: TDataSource;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasTIPO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasSQL: TcxGridDBColumn;
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
    procedure unqryGuiasBeforePost(DataSet: TDataSet);
  private
    procedure ListarCamposDelGrid;
  public
    sFormulario: string;
    FDataSet: TDataSet;
  end;

implementation

{$R *.dfm}

uses
  UniDataConn, inLibUser, inLibGlobalVar;

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
  ListarCamposDelGrid;
end;

procedure TfrmModalGridGuias.ListarCamposDelGrid;
var
  i: Integer;
  sLine: string;
begin
  mmoCampos.Lines.BeginUpdate;
  try
    mmoCampos.Lines.Clear;
    if (FDataSet = nil) or (not FDataSet.Active) or
       (FDataSet.FieldCount = 0) then
    begin
      mmoCampos.Lines.Add('(Dataset no disponible.)');
      Exit;
    end;
    mmoCampos.Lines.Add('Campos del grid (usar en Master fields):');
    mmoCampos.Lines.Add('');
    sLine := '    ';
    for i := 0 to FDataSet.FieldCount - 1 do
    begin
      if Length(sLine) + Length(FDataSet.Fields[i].FieldName) > 95 then
      begin
        mmoCampos.Lines.Add(sLine);
        sLine := '    ';
      end;
      if sLine <> '    ' then
        sLine := sLine + ', ';
      sLine := sLine + FDataSet.Fields[i].FieldName;
    end;
    if sLine <> '    ' then
      mmoCampos.Lines.Add(sLine);
    mmoCampos.Lines.Add('');
    mmoCampos.Lines.Add(
      'Tip: copia los nombres de campo a "Master fields" / ' +
      '"Detail fields" separados por '';''.');
  finally
    mmoCampos.Lines.EndUpdate;
  end;
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

procedure TfrmModalGridGuias.unqryGuiasBeforePost(DataSet: TDataSet);
begin
  if DataSet.State = dsInsert then
  begin
    if DataSet.FieldByName('INFORME_INFGUI').IsNull or
       (DataSet.FieldByName('INFORME_INFGUI').AsString = '') then
      DataSet.FieldByName('INFORME_INFGUI').AsString :=
        'GRID:' + sFormulario;
    if DataSet.FieldByName('FORMATO_INFGUI').IsNull then
      DataSet.FieldByName('FORMATO_INFGUI').AsString := '';
    if DataSet.FieldByName('DATASET_MASTER_INFGUI').IsNull or
       (DataSet.FieldByName('DATASET_MASTER_INFGUI').AsString = '') then
      DataSet.FieldByName('DATASET_MASTER_INFGUI').AsString := 'TablaG';
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

end.
