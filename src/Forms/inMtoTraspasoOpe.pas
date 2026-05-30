{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraspasoOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de traspasos entre almacenes (TPV, F3 del menú de caja).        }
{    Arriba ALMACÉN ORIGEN / ALMACÉN DESTINO; debajo el grid de líneas;        }
{    F12 graba con ticket y F11 sin ticket. Primer slice: traspaso directo.    }
{    Ver DESARROLLOS EN CURSO/traspasos_caja.md.                               }
{******************************************************************************}
unit inMtoTraspasoOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, inMtoFrmBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit,
  cxSpinEdit, cxDropDownEdit, cxButtons, cxClasses, cxGridLevel,
  cxGridCustomTableView, cxGridCustomView, cxGridTableView, cxGridDBTableView,
  cxGrid, Data.DB, Uni, inLibGlobalVar, UniDataTraspaso;

type
  TfrmMtoOpeTraspaso = class(TfrmBase)
    pnlTop: TPanel;
    lblOrigen: TcxLabel;
    txtOrigen: TcxTextEdit;
    lblDestino: TcxLabel;
    cboDestino: TcxComboBox;
    pnlEntrada: TPanel;
    lblSku: TcxLabel;
    txtSku: TcxTextEdit;
    lblCantidad: TcxLabel;
    spnCantidad: TcxSpinEdit;
    btnAnadir: TcxButton;
    btnQuitar: TcxButton;
    pnlCentro: TPanel;
    pnlBottom: TPanel;
    lblTotal: TcxLabel;
    btnF11: TcxButton;
    btnF12: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
                          Shift: TShiftState);
    procedure btnAnadirClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnF11Click(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
  private
    FDatos: TdmTraspaso;
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    FAlmDestinoCodigos: TStringList;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FModo: TModoTraspaso;
    procedure ConstruirGrid;
    procedure CargarAlmacenesDestino;
    function DestinoSeleccionado: string;
    procedure ActualizarTotal;
    procedure EjecutarTraspaso(AConTicket: Boolean);
  public
    procedure PrepararValores(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                              ACaja: string; AFecha: TDateTime);
  end;

var
  frmMtoOpeTraspaso: TfrmMtoOpeTraspaso;

implementation

{$R *.dfm}

procedure TfrmMtoOpeTraspaso.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  FAlmDestinoCodigos := TStringList.Create;
  FDatos := TdmTraspaso.Create(Self);
  ConstruirGrid;
end;

procedure TfrmMtoOpeTraspaso.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAlmDestinoCodigos);
  // FDatos lo libera el Owner (Self) automáticamente.
  inherited;
end;

procedure TfrmMtoOpeTraspaso.ConstruirGrid;
begin
  FGrid := TcxGrid.Create(Self);
  FGrid.Parent := pnlCentro;
  FGrid.Align := alClient;
  FView := FGrid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  FGrid.Levels.Add.GridView := FView;
  FView.DataController.DataSource := FDatos.dsLineas;
  FView.DataController.CreateAllItems;
  // El grid es de sólo lectura: el alta se hace por el panel de entrada.
  FView.OptionsData.Editing := False;
  FView.OptionsData.Deleting := False;
  FView.OptionsData.Inserting := False;
  FView.OptionsView.GroupByBox := False;
end;

procedure TfrmMtoOpeTraspaso.PrepararValores(AModo: TModoTraspaso;
                          const AEmpresa, AAlmacen, ACaja: string;
                          AFecha: TDateTime);
begin
  FModo := AModo;
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FDatos.PrepararNuevo(AModo, AEmpresa, AAlmacen, ACaja, AFecha);
  txtOrigen.Text := AAlmacen;
  CargarAlmacenesDestino;
  cboDestino.ItemIndex := -1;
  ActualizarTotal;
  if txtSku.CanFocus then
    txtSku.SetFocus;
end;

procedure TfrmMtoOpeTraspaso.CargarAlmacenesDestino;
var
  q: TUniQuery;
begin
  cboDestino.Properties.Items.Clear;
  FAlmDestinoCodigos.Clear;
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' AND TIPO_USO_ALM = ''ESTANDAR'' ' +
      '   AND CODIGO_EMP_ALM = :EMP AND CODIGO_ALM_ALM <> :PROPIO ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    q.ParamByName('EMP').AsString := FEmpresa;
    q.ParamByName('PROPIO').AsString := FAlmacen;
    q.Open;
    while not q.Eof do
    begin
      FAlmDestinoCodigos.Add(q.FieldByName('CODIGO_ALM_ALM').AsString);
      cboDestino.Properties.Items.Add(
        q.FieldByName('CODIGO_ALM_ALM').AsString + ' - ' +
        q.FieldByName('NOMBRE_ALM_ALM').AsString);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmMtoOpeTraspaso.DestinoSeleccionado: string;
begin
  if (cboDestino.ItemIndex >= 0) and
     (cboDestino.ItemIndex < FAlmDestinoCodigos.Count) then
    Result := FAlmDestinoCodigos[cboDestino.ItemIndex]
  else
    Result := '';
end;

procedure TfrmMtoOpeTraspaso.ActualizarTotal;
var
  cTotal: Currency;
  bm: TBookmark;
begin
  cTotal := 0;
  if not FDatos.cdsLineas.IsEmpty then
  begin
    FDatos.cdsLineas.DisableControls;
    bm := FDatos.cdsLineas.GetBookmark;
    try
      FDatos.cdsLineas.First;
      while not FDatos.cdsLineas.Eof do
      begin
        cTotal := cTotal + FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency;
        FDatos.cdsLineas.Next;
      end;
    finally
      FDatos.cdsLineas.GotoBookmark(bm);
      FDatos.cdsLineas.FreeBookmark(bm);
      FDatos.cdsLineas.EnableControls;
    end;
  end;
  lblTotal.Caption := Format('Importe traspaso: %m', [cTotal]);
end;

procedure TfrmMtoOpeTraspaso.btnAnadirClick(Sender: TObject);
var
  sSku: string;
  dCantidad: Double;
begin
  sSku := Trim(txtSku.Text);
  dCantidad := spnCantidad.Value;
  if (sSku = '') or (dCantidad <= 0) then
    ShowMessage('Indica un SKU y una cantidad mayor que cero.')
  else if FDatos.AnadirLinea(sSku, dCantidad) then
  begin
    txtSku.Clear;
    ActualizarTotal;
    if txtSku.CanFocus then
      txtSku.SetFocus;
  end
  else
    ShowMessage('Artículo no encontrado o no es de stock: ' + sSku);
end;

procedure TfrmMtoOpeTraspaso.btnQuitarClick(Sender: TObject);
begin
  if not FDatos.cdsLineas.IsEmpty then
  begin
    FDatos.cdsLineas.Delete;
    ActualizarTotal;
  end;
end;

procedure TfrmMtoOpeTraspaso.EjecutarTraspaso(AConTicket: Boolean);
var
  sNumOp, sDestino: string;
begin
  sDestino := DestinoSeleccionado;
  if sDestino = '' then
    ShowMessage('Selecciona el almacén destino.')
  else if FDatos.GrabarTraspaso(sDestino, sNumOp) then
  begin
    // TODO: si AConTicket, imprimir el albarán de traspaso
    // (inLibGenerarTicketBD), igual que el ticket de venta.
    ShowMessage(Format('Traspaso %s grabado correctamente.', [sNumOp]));
    PrepararValores(FModo, FEmpresa, FAlmacen, FCaja, Date);
  end;
end;

procedure TfrmMtoOpeTraspaso.btnF11Click(Sender: TObject);
begin
  EjecutarTraspaso(False);
end;

procedure TfrmMtoOpeTraspaso.btnF12Click(Sender: TObject);
begin
  EjecutarTraspaso(True);
end;

procedure TfrmMtoOpeTraspaso.FormKeyDown(Sender: TObject; var Key: Word;
                                         Shift: TShiftState);
begin
  case Key of
    VK_F3:
      btnQuitarClick(nil);
    VK_F11:
      btnF11Click(nil);
    VK_F12:
      btnF12Click(nil);
    VK_ESCAPE:
      Close;
  end;
end;

end.
