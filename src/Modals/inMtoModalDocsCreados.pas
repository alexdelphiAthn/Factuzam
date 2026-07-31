{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalDocsCreados                                         }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       24/05/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal que lista los documentos (pedidos / albaranes) creados al           }
{    materializar una sesion de compras. En modo distribuido se generan        }
{    N albaranes (uno por almacen); el usuario los ve aqui y con               }
{    "Ir a documento" / doble-click navega al elegido via ShowMto.             }
{    La navegacion la hace el llamador leyendo SeleccionadoTipo/Serie/         }
{    Numero tras Confirmado, para no acoplar este modal a frmMtoPrincipal.    }
{******************************************************************************}
unit inMtoModalDocsCreados;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls,
  System.Actions, Vcl.ActnList,
  Data.DB, DBClient, MemDS, DBAccess,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses, cxLocalization,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxStyles,
  dxSkinsCore, dxSkinBlue,
  inMtoModalAceptCancel,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inLibComprasSesionesIntf;

type
  TfrmModalDocsCreados = class(TfrmModalAceptCancel)
    pnlCab       : TPanel;
    lblTitulo    : TcxLabel;
    cdsDocs      : TClientDataSet;
    dsDocs       : TDataSource;
    cxgrdDocs    : TcxGrid;
    cxlvlDocs    : TcxGridLevel;
    tvDocs       : TcxGridDBTableView;
    procedure FormCreate(Sender: TObject);
    procedure tvDocsDblClick(Sender: TObject);
  protected
    // DoShow es dynamic en TCustomForm; lo overrideamos para llevar el
    // foco al grid (el ancestro lo deja en btnAceptar) y que Enter / doble
    // click navegue inmediatamente al doc.
    procedure DoShow; override;
  private
    FSelTipo   : string;
    FSelSerie  : string;
    FSelNumero : string;
    procedure PrepararEstructura;
    function GetConfirmado: Boolean;
  public
    class function Seleccionar(
      AOwner: TComponent;
      const ADocumentos: TDocumentosMaterializados;
      out ASeleccionado: TDocumentoMaterializado): Boolean; static;
    // Captura la fila seleccionada antes de cerrar si se confirma.
    function CloseQuery: Boolean; override;
    property Confirmado: Boolean read GetConfirmado;
    property SeleccionadoTipo:   string read FSelTipo;
    property SeleccionadoSerie:  string read FSelSerie;
    property SeleccionadoNumero: string read FSelNumero;
    procedure Agregar(const ATipo, ASerie, ANumero, AAlmacen: string);
  end;

implementation

{$R *.dfm}

class function TfrmModalDocsCreados.Seleccionar(
  AOwner: TComponent;
  const ADocumentos: TDocumentosMaterializados;
  out ASeleccionado: TDocumentoMaterializado): Boolean;
var
  Formulario: TfrmModalDocsCreados;
  i: Integer;
begin
  ASeleccionado := Default(TDocumentoMaterializado);
  Formulario := TfrmModalDocsCreados.Create(AOwner);
  Formulario.OnClose := nil;
  try
    for i := 0 to High(ADocumentos) do
    begin
      Formulario.Agregar(
        ADocumentos[i].Tipo,
        ADocumentos[i].Serie,
        ADocumentos[i].Numero,
        ADocumentos[i].Almacen);
    end;
    Formulario.ShowModal;
    Result := Formulario.Confirmado;
    if Result then
    begin
      ASeleccionado.Tipo := Formulario.SeleccionadoTipo;
      ASeleccionado.Serie := Formulario.SeleccionadoSerie;
      ASeleccionado.Numero := Formulario.SeleccionadoNumero;
    end;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalDocsCreados.FormCreate(Sender: TObject);
begin
  inherited;
  PrepararEstructura;
end;

procedure TfrmModalDocsCreados.PrepararEstructura;
begin
  // ClientDataSet en memoria + columnas del grid. Estructura fija
  // (TIPO/SERIE/NUMERO/ALMACEN), no depende de datos externos.
  cdsDocs.Close;
  cdsDocs.FieldDefs.Clear;
  cdsDocs.FieldDefs.Add('TIPO',    ftString, 20);
  cdsDocs.FieldDefs.Add('SERIE',   ftString, 10);
  cdsDocs.FieldDefs.Add('NUMERO',  ftString, 20);
  cdsDocs.FieldDefs.Add('ALMACEN', ftString, 20);
  cdsDocs.CreateDataSet;
  tvDocs.ClearItems;
  with tvDocs.CreateColumn do
  begin
    DataBinding.FieldName := 'TIPO';
    Caption := 'Tipo';
    Width := 110;
  end;
  with tvDocs.CreateColumn do
  begin
    DataBinding.FieldName := 'SERIE';
    Caption := 'Serie';
    Width := 80;
  end;
  with tvDocs.CreateColumn do
  begin
    DataBinding.FieldName := 'NUMERO';
    Caption := 'Numero';
    Width := 120;
  end;
  with tvDocs.CreateColumn do
  begin
    DataBinding.FieldName := 'ALMACEN';
    Caption := 'Almacen';
    Width := 140;
  end;
end;

procedure TfrmModalDocsCreados.Agregar(const ATipo, ASerie, ANumero,
                                       AAlmacen: string);
begin
  cdsDocs.Append;
  cdsDocs.FieldByName('TIPO').AsString    := ATipo;
  cdsDocs.FieldByName('SERIE').AsString   := ASerie;
  cdsDocs.FieldByName('NUMERO').AsString  := ANumero;
  cdsDocs.FieldByName('ALMACEN').AsString := AAlmacen;
  cdsDocs.Post;
end;

function TfrmModalDocsCreados.GetConfirmado: Boolean;
begin
  Result := sFicha = 'S';
end;

procedure TfrmModalDocsCreados.DoShow;
begin
  inherited;
  cdsDocs.First;
  if cxgrdDocs.CanFocus then
    cxgrdDocs.SetFocus;
end;

procedure TfrmModalDocsCreados.tvDocsDblClick(Sender: TObject);
begin
  // Doble click sobre una fila = confirmar y "Ir a". sFicha + WM_CLOSE
  // es justo lo que hace el ancestro en btnAceptarClick; reutilizamos
  // su flujo para que CloseQuery capture la fila igual que con Aceptar.
  sFicha := 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

function TfrmModalDocsCreados.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if not Result then
    Exit;
  if sFicha <> 'S' then
    Exit;
  if cdsDocs.IsEmpty then
    Exit;
  FSelTipo   := cdsDocs.FieldByName('TIPO').AsString;
  FSelSerie  := cdsDocs.FieldByName('SERIE').AsString;
  FSelNumero := cdsDocs.FieldByName('NUMERO').AsString;
end;

end.
