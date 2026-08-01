{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelFamilia                                          }
{    Tipo:       Formulario (Modal)                                            }
{                                                                              }
{  Descripcion:                                                                }
{    Selector jerarquico de familias. Se invoca desde la sesion de compra      }
{    (Compras-Sesiones -> Lineas -> columna Codigo articulo, tecla F3) y       }
{    devuelve el CODIGO_FAM_FAM elegido.                                       }
{                                                                              }
{    Al pegarlo al codigo tentativo de la linea, el BeforePost de              }
{    UniDataComprasSesiones invoca ResolverCodigoFamilia y expande al          }
{    siguiente codigo de la serie.                                             }
{******************************************************************************}
unit inMtoModalSelFamilia;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase,
  cxClasses, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxLabel, cxButtons, cxTextEdit, cxLocalization,
  cxStyles, cxData, cxDataStorage, cxCustomData, cxFilter, cxNavigator,
  cxTL, cxTLData, cxDBTL, cxInplaceContainer,
  dxSkinsCore, dxSkinsForm, dxSkinsDefaultPainters, dxSkinBlue,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab;

type
  TfrmModalSelFamilia = class(TfrmBase)
    pnlBody           : TPanel;
    pnlButton         : TPanel;
    pnlFiltro         : TPanel;
    btnAceptar        : TcxButton;
    btnCancelar       : TcxButton;
    lblFiltro         : TcxLabel;
    txtFiltro         : TcxTextEdit;
    tlFamilias        : TcxDBTreeList;
    tlcNombre         : TcxDBTreeListColumn;
    tlcCodigo         : TcxDBTreeListColumn;
    dsFamilias        : TDataSource;
    unqryFamilias     : TUniQuery;
    ActionList1       : TActionList;
    actAceptar        : TAction;
    actCancelar       : TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure txtFiltroPropertiesChange(Sender: TObject);
    procedure tlFamiliasDblClick(Sender: TObject);
  private
    FCodigoFamilia : string;
    FNombreFamilia : string;
    procedure AplicarFiltro;
  public
    property CodigoFamilia : string read FCodigoFamilia;
    property NombreFamilia : string read FNombreFamilia;
  end;

implementation

{$R *.dfm}

procedure TfrmModalSelFamilia.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  unqryFamilias.Connection := ConexionPrincipal;
end;

procedure TfrmModalSelFamilia.FormShow(Sender: TObject);
begin
  inherited;
  AplicarFiltro;
  if txtFiltro.CanFocus then txtFiltro.SetFocus;
end;

procedure TfrmModalSelFamilia.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmModalSelFamilia.AplicarFiltro;
var
  sTxt : string;
begin
  sTxt := Trim(txtFiltro.Text);
  unqryFamilias.Close;
  if sTxt = '' then
  begin
    unqryFamilias.SQL.Text :=
      'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM, ' +
      '       COALESCE(CODIGO_SUBFAMILIA_FAM, '''') AS CODIGO_PADRE_FAM ' +
      '  FROM fza_articulos_familias ' +
      ' WHERE ESACTIVO_FAM = ''S'' ' +
      ' ORDER BY ORDEN_FAM, NOMBRE_FAM_FAM';
  end
  else
  begin
    // Con filtro mostramos plano (sin jerarquia)
    unqryFamilias.SQL.Text :=
      'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM, '''' AS CODIGO_PADRE_FAM ' +
      '  FROM fza_articulos_familias ' +
      ' WHERE ESACTIVO_FAM = ''S'' ' +
      '   AND (CODIGO_FAM_FAM LIKE :p OR NOMBRE_FAM_FAM LIKE :p) ' +
      ' ORDER BY ORDEN_FAM, NOMBRE_FAM_FAM';
    unqryFamilias.ParamByName('p').AsString := '%' + sTxt + '%';
  end;
  unqryFamilias.Open;
  tlFamilias.FullExpand;
end;

procedure TfrmModalSelFamilia.txtFiltroPropertiesChange(Sender: TObject);
begin
  inherited;
  AplicarFiltro;
end;

procedure TfrmModalSelFamilia.tlFamiliasDblClick(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelFamilia.btnAceptarClick(Sender: TObject);
begin
  inherited;
  if (unqryFamilias.IsEmpty) or
     (tlFamilias.FocusedNode = nil) then
  begin
    FCodigoFamilia := '';
    ModalResult := mrCancel;
    Exit;
  end;
  FCodigoFamilia := unqryFamilias.FieldByName('CODIGO_FAM_FAM').AsString;
  FNombreFamilia := unqryFamilias.FieldByName('NOMBRE_FAM_FAM').AsString;
  ModalResult := mrOk;
end;

procedure TfrmModalSelFamilia.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FCodigoFamilia := '';
  ModalResult := mrCancel;
end;

procedure TfrmModalSelFamilia.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelFamilia.actCancelarExecute(Sender: TObject);
begin
  inherited;
  btnCancelarClick(Sender);
end;

end.
