{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelAlmacenPedido                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de seleccion de almacen al crear un albaran de compra desde un      }
{    pedido. Lista los distintos almacenes que aparecen en las lineas del      }
{    pedido (campo CODIGO_ALMACEN_PEDCLIN, con fallback al de cabecera) y      }
{    al lado la cantidad total pendiente de recibir para ese almacen.         }
{    El usuario elige uno; CodigoAlmacen se rellena al aceptar.                }
{******************************************************************************}
unit inMtoModalSelAlmacenPedido;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Menus,
  inMtoFrmBase,
  cxClasses, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxLocalization, cxButtons, cxControls, cxContainer, cxEdit,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxNavigator, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGrid,
  System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni;

type
  TfrmModalSelAlmacenPedido = class(TfrmBase)
    pnlButton:   TPanel;
    btnCancelar: TcxButton;
    btnAceptar:  TcxButton;
    pnlBody:     TPanel;
    lblPedido:   TLabel;
    cxgrdAlmacenes: TcxGrid;
    tvAlmacenes:    TcxGridTableView;
    cxgrdlvlAlm:    TcxGridLevel;
    colCodigoAlm:   TcxGridColumn;
    colNombreAlm:   TcxGridColumn;
    colPendiente:   TcxGridColumn;
    ActionList1: TActionList;
    actAceptar:  TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure tvAlmacenesDblClick(Sender: TObject);
  private
    procedure CargarAlmacenes;
  public
    SeriePedc, NumPedc: string;
    CodigoAlmacen: string;
    Aceptado: Boolean;
  end;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure TfrmModalSelAlmacenPedido.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Aceptado := False;
  CodigoAlmacen := '';
end;

procedure TfrmModalSelAlmacenPedido.FormShow(Sender: TObject);
begin
  inherited;
  lblPedido.Caption := Format(
    'Pedido %s/%s — selecciona el almacen al que vas a generar el albaran:',
    [SeriePedc, NumPedc]);
  CargarAlmacenes;
  if tvAlmacenes.DataController.RecordCount > 0 then
    tvAlmacenes.Controller.FocusedRowIndex := 0;
end;

procedure TfrmModalSelAlmacenPedido.FormClose(Sender: TObject;
                                              var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmModalSelAlmacenPedido.CargarAlmacenes;
var
  q: TUniQuery;
begin
  // Cargamos los almacenes distintos del pedido con la suma de cantidad
  // pendiente (CANTIDAD - CANTIDAD_RECIBIDA). Solo los que tienen
  // pendiente > 0 — si todo esta recibido no tiene sentido albaranear.
  tvAlmacenes.DataController.RecordCount := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN,''''), ' +
      '              P.CODIGO_ALM_PEDC) AS ALM, ' +
      '       IFNULL(A.NOMBRE_ALM_ALM, '''') AS NOMBRE, ' +
      '       SUM(L.CANTIDAD_PEDCLIN - ' +
      '           IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0)) AS PEND ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '  LEFT JOIN fza_almacenes A ' +
      '    ON A.CODIGO_ALM_ALM = IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN,''''), ' +
      '                                  P.CODIGO_ALM_PEDC) ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      ' GROUP BY ALM, NOMBRE ' +
      'HAVING PEND > 0 ' +
      ' ORDER BY ALM';
    q.ParamByName('s').AsString := SeriePedc;
    q.ParamByName('n').AsString := NumPedc;
    q.Open;
    while not q.Eof do
    begin
      tvAlmacenes.DataController.AppendRecord(
        [q.FieldByName('ALM').AsString,
         q.FieldByName('NOMBRE').AsString,
         q.FieldByName('PEND').AsFloat]);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmModalSelAlmacenPedido.tvAlmacenesDblClick(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelAlmacenPedido.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelAlmacenPedido.actCancelarExecute(Sender: TObject);
begin
  inherited;
  Aceptado := False;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalSelAlmacenPedido.btnAceptarClick(Sender: TObject);
var
  iIdx: Integer;
  vAlm: Variant;
begin
  inherited;
  iIdx := tvAlmacenes.Controller.FocusedRowIndex;
  if (iIdx < 0) or (iIdx >= tvAlmacenes.DataController.RecordCount) then
  begin
    MessageDlg('Selecciona un almacen.', mtInformation, [mbOk], 0);
    Exit;
  end;
  vAlm := tvAlmacenes.DataController.Values[iIdx, colCodigoAlm.Index];
  if VarIsNull(vAlm) or VarIsEmpty(vAlm) then
  begin
    MessageDlg('La fila seleccionada no tiene codigo de almacen.',
               mtWarning, [mbOk], 0);
    Exit;
  end;
  CodigoAlmacen := VarToStr(vAlm);
  Aceptado := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

end.
