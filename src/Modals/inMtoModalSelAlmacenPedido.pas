{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelAlmacenPedido                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.1.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de "Crear albaran desde pedido". Estilo similar al modal de         }
{    materializar sesion de compras (inMtoModalCrearAlbaranSesion):            }
{                                                                              }
{    1. Selector de almacen destino: lista los almacenes con cantidad          }
{       pendiente de recibir en el pedido (calculada como                      }
{       CANTIDAD_PEDCLIN - CANTIDAD_RECIBIDA_PEDCLIN agregada por almacen).   }
{    2. Serie del albaran (texto, default = serie del pedido).                 }
{    3. Ref. proveedor (texto, default = ref del pedido).                      }
{    4. Temporada (lookup, de fza_propiedades_valores filtrado a               }
{       ID_PROP_PV='TEMPORADA').                                               }
{    5. Fecha de recepcion (default = hoy).                                    }
{                                                                              }
{    El usuario elige + completa y pulsa Aceptar. El form de pedidos          }
{    de compra lee los properties y crea el albaran via                       }
{    inLibPedidosCompra.CrearAlbaranDesdePedido.                              }
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
  cxGridTableView, cxGrid, cxTextEdit, cxLabel, cxCalendar,
  cxMaskEdit, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox,
  System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni;

type
  TfrmModalSelAlmacenPedido = class(TfrmBase)
    pnlButton:   TPanel;
    btnCancelar: TcxButton;
    btnAceptar:  TcxButton;
    pnlBody:     TPanel;
    lblPedido:   TLabel;
    lblAlmacen:  TcxLabel;
    cxgrdAlmacenes: TcxGrid;
    tvAlmacenes:    TcxGridTableView;
    cxgrdlvlAlm:    TcxGridLevel;
    colCodigoAlm:   TcxGridColumn;
    colNombreAlm:   TcxGridColumn;
    colPendiente:   TcxGridColumn;
    lblSerieAlb:    TcxLabel;
    txtSerieAlb:    TcxTextEdit;
    lblRefPrv:      TcxLabel;
    txtRefPrv:      TcxTextEdit;
    lblTemporada:   TcxLabel;
    cbbTemporada:   TcxLookupComboBox;
    dsTemporadas:   TDataSource;
    unqryTemporadas: TUniQuery;
    lblFecha:       TcxLabel;
    dteFecha:       TcxDateEdit;
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
    procedure ConfigurarLookupTemporada;
  public
    SeriePedc, NumPedc      : string;
    SerieAlbDefecto         : string;  // default texto serie
    RefProveedorDefecto     : string;
    IdPvTemporadaDefecto    : Integer;
    // Devueltos al cerrar con Aceptado=True:
    CodigoAlmacen           : string;
    SerieAlbaran            : string;
    RefProveedor            : string;
    IdPvTemporada           : Integer;
    FechaRecepcion          : TDateTime;
    Aceptado                : Boolean;
  end;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure TfrmModalSelAlmacenPedido.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Aceptado      := False;
  CodigoAlmacen := '';
  SerieAlbaran  := '';
  RefProveedor  := '';
  IdPvTemporada := 0;
  FechaRecepcion := Date;
  // Conexion de la query de temporadas (esta unica que la lib usa).
  unqryTemporadas.Connection := inLibGlobalVar.oConn;
end;

procedure TfrmModalSelAlmacenPedido.FormShow(Sender: TObject);
begin
  inherited;
  lblPedido.Caption := Format(
    'Crear albaran desde pedido %s/%s',
    [SeriePedc, NumPedc]);
  CargarAlmacenes;
  ConfigurarLookupTemporada;
  // Defaults.
  txtSerieAlb.Text := SerieAlbDefecto;
  txtRefPrv.Text   := RefProveedorDefecto;
  if IdPvTemporadaDefecto > 0 then
    cbbTemporada.EditValue := IdPvTemporadaDefecto
  else
    cbbTemporada.EditValue := Null;
  dteFecha.Date := Date;
  if tvAlmacenes.DataController.RecordCount > 0 then
    tvAlmacenes.Controller.FocusedRowIndex := 0;
  if txtSerieAlb.CanFocus then
    txtSerieAlb.SetFocus;
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
  i: Integer;
begin
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
    tvAlmacenes.DataController.RecordCount := q.RecordCount;
    i := 0;
    while not q.Eof do
    begin
      tvAlmacenes.DataController.Values[i, colCodigoAlm.Index] :=
        q.FieldByName('ALM').AsString;
      tvAlmacenes.DataController.Values[i, colNombreAlm.Index] :=
        q.FieldByName('NOMBRE').AsString;
      tvAlmacenes.DataController.Values[i, colPendiente.Index] :=
        q.FieldByName('PEND').AsFloat;
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmModalSelAlmacenPedido.ConfigurarLookupTemporada;
begin
  // El SQL ya esta en el DFM. Lo abrimos al show.
  if not unqryTemporadas.Active then
    unqryTemporadas.Open;
  cbbTemporada.Properties.ListSource    := dsTemporadas;
  cbbTemporada.Properties.KeyFieldNames := 'ID_PV_ARTPROP';
  cbbTemporada.Properties.ListColumns.Clear;
  with cbbTemporada.Properties.ListColumns.Add do
  begin
    FieldName := 'PV';
    Caption   := 'Temporada';
    Width     := 240;
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
  vTmp: Variant;
begin
  inherited;
  // Validaciones minimas.
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
  if Trim(txtSerieAlb.Text) = '' then
  begin
    MessageDlg('Indica la serie del albaran.', mtInformation, [mbOk], 0);
    if txtSerieAlb.CanFocus then txtSerieAlb.SetFocus;
    Exit;
  end;
  // Captura resultado.
  CodigoAlmacen := VarToStr(vAlm);
  SerieAlbaran  := Trim(txtSerieAlb.Text);
  RefProveedor  := Trim(txtRefPrv.Text);
  vTmp := cbbTemporada.EditValue;
  if VarIsNull(vTmp) or VarIsEmpty(vTmp) then
    IdPvTemporada := 0
  else
    IdPvTemporada := StrToIntDef(VarToStr(vTmp), 0);
  FechaRecepcion := dteFecha.Date;
  Aceptado := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

end.
