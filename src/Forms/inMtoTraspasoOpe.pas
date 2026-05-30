{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraspasoOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de traspasos entre almacenes (TPV, F3 del menú de caja).        }
{    Tres modos en una barra superior: Traspaso (origen propio -> destino      }
{    ESTANDAR), Solicitar (pido a otro almacén) y Atender (sirvo una           }
{    solicitud que me han hecho). F12 con ticket / F11 sin ticket.             }
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
    pnlModos: TPanel;
    btnModoTraspaso: TcxButton;
    btnModoSolicitar: TcxButton;
    btnModoAtender: TcxButton;
    pnlTop: TPanel;
    lblOrigen: TcxLabel;
    txtOrigen: TcxTextEdit;
    lblDestino: TcxLabel;
    cboDestino: TcxComboBox;
    lblEmpleado: TcxLabel;
    txtEmpleado: TcxTextEdit;
    lblEmpleadoNombre: TcxLabel;
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
    procedure btnModoClick(Sender: TObject);
    procedure btnAnadirClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnF11Click(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure txtEmpleadoExit(Sender: TObject);
  private
    FDatos: TdmTraspaso;
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    FComboCodigos: TStringList;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFecha: TDateTime;
    FModo: TModoTraspaso;
    procedure ConstruirGrid;
    procedure AplicarModo(AModo: TModoTraspaso);
    procedure CargarCombo;
    procedure CargarAlmacenesDestino;
    function DestinoSeleccionado: string;
    procedure ActualizarTotal;
    procedure EjecutarTraspaso(AConTicket: Boolean);
    procedure EnviarSolicitud;
    procedure CargarSolicitudSeleccionada;
    function EmpleadoValido: Boolean;
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
  FComboCodigos := TStringList.Create;
  FDatos := TdmTraspaso.Create(Self);
  ConstruirGrid;
end;

procedure TfrmMtoOpeTraspaso.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FComboCodigos);
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
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFecha := AFecha;
  AplicarModo(AModo);
end;

procedure TfrmMtoOpeTraspaso.AplicarModo(AModo: TModoTraspaso);
begin
  FModo := AModo;
  FDatos.PrepararNuevo(AModo, FEmpresa, FAlmacen, FCaja, FFecha);
  txtOrigen.Text := FAlmacen;
  txtSku.Enabled := AModo <> mtAtender;
  spnCantidad.Enabled := AModo <> mtAtender;
  btnF11.Visible := AModo <> mtSolicitar;
  // Captions con tilde en literal: este .pas va en UTF-8 con BOM (igual que
  // inMtoCajaMenu.pas) para que el compilador las lea bien.
  case AModo of
    mtTraspaso:
    begin
      lblOrigen.Caption := 'ALMACÉN ORIGEN';
      lblDestino.Caption := 'ALMACÉN DESTINO';
      btnAnadir.Caption := 'Añadir (Intro)';
      btnF12.Caption := 'F12 · Con ticket';
    end;
    mtSolicitar:
    begin
      lblOrigen.Caption := 'ALMACÉN DESTINO (yo)';
      lblDestino.Caption := 'ALMACÉN ORIGEN (a quién pido)';
      btnAnadir.Caption := 'Añadir (Intro)';
      btnF12.Caption := 'F12 · Enviar solicitud';
    end;
    mtAtender:
    begin
      lblOrigen.Caption := 'ALMACÉN ORIGEN (yo)';
      lblDestino.Caption := 'SOLICITUD A ATENDER';
      btnAnadir.Caption := 'Cargar solicitud';
      btnF12.Caption := 'F12 · Servir con ticket';
    end;
  end;
  CargarCombo;
  cboDestino.ItemIndex := -1;
  ActualizarTotal;
end;

procedure TfrmMtoOpeTraspaso.btnModoClick(Sender: TObject);
begin
  AplicarModo(TModoTraspaso((Sender as TComponent).Tag));
end;

procedure TfrmMtoOpeTraspaso.CargarCombo;
begin
  cboDestino.Properties.Items.Clear;
  FComboCodigos.Clear;
  if FModo = mtAtender then
    FDatos.CargarSolicitudesPendientes(cboDestino.Properties.Items,
                                       FComboCodigos)
  else
    CargarAlmacenesDestino;
end;

procedure TfrmMtoOpeTraspaso.CargarAlmacenesDestino;
var
  q: TUniQuery;
begin
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
      FComboCodigos.Add(q.FieldByName('CODIGO_ALM_ALM').AsString);
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
     (cboDestino.ItemIndex < FComboCodigos.Count) then
    Result := FComboCodigos[cboDestino.ItemIndex]
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
  if FModo = mtAtender then
    CargarSolicitudSeleccionada
  else
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
end;

procedure TfrmMtoOpeTraspaso.CargarSolicitudSeleccionada;
var
  sCod, sNum, sSer: string;
  iSep: Integer;
begin
  sCod := DestinoSeleccionado;
  if sCod = '' then
    ShowMessage('Selecciona una solicitud pendiente.')
  else
  begin
    iSep := Pos('|', sCod);
    sNum := Copy(sCod, 1, iSep - 1);
    sSer := Copy(sCod, iSep + 1, Length(sCod));
    if FDatos.CargarSolicitud(sNum, sSer) then
    begin
      txtOrigen.Text :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
      ActualizarTotal;
    end
    else
      ShowMessage('No se pudo cargar la solicitud.');
  end;
end;

procedure TfrmMtoOpeTraspaso.EnviarSolicitud;
var
  sNum, sSer, sOrigen: string;
begin
  if EmpleadoValido then
  begin
    sOrigen := DestinoSeleccionado;
    if sOrigen = '' then
      ShowMessage('Selecciona el almacén al que solicitas.')
    else if FDatos.GrabarSolicitud(sOrigen, sNum, sSer) then
    begin
      ShowMessage(Format('Solicitud %s/%s enviada.', [sSer, sNum]));
      AplicarModo(mtSolicitar);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoExit(Sender: TObject);
var
  sCod, sNom: string;
begin
  if Trim(txtEmpleado.Text) = '' then
    lblEmpleadoNombre.Caption := ''
  else if FDatos.ValidarEmpleado(Trim(txtEmpleado.Text), sCod, sNom) then
    lblEmpleadoNombre.Caption := sNom
  else
    lblEmpleadoNombre.Caption := '(no encontrado)';
end;

function TfrmMtoOpeTraspaso.EmpleadoValido: Boolean;
var
  sCod, sNom: string;
begin
  if Trim(txtEmpleado.Text) = '' then
  begin
    ShowMessage('Indica el empleado responsable del traspaso.');
    Result := False;
  end
  else if FDatos.ValidarEmpleado(Trim(txtEmpleado.Text), sCod, sNom) then
  begin
    lblEmpleadoNombre.Caption := sNom;
    if FDatos.cdsCabecera.State = dsBrowse then
      FDatos.cdsCabecera.Edit;
    FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString := sCod;
    FDatos.cdsCabecera.Post;
    Result := True;
  end
  else
  begin
    ShowMessage('Empleado no encontrado: ' + txtEmpleado.Text);
    Result := False;
  end;
end;

procedure TfrmMtoOpeTraspaso.EjecutarTraspaso(AConTicket: Boolean);
var
  sNumOp, sDestino, sNumSol, sSerSol: string;
begin
  if EmpleadoValido then
  begin
    if FModo = mtAtender then
    begin
      sDestino :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString;
      sNumSol := FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString;
      sSerSol := FDatos.cdsCabecera.FieldByName('SERIE_SOL').AsString;
      if sDestino = '' then
        ShowMessage('Carga primero una solicitud (botón Cargar solicitud).')
      else if FDatos.GrabarTraspaso(sDestino, sNumOp, sNumSol, sSerSol) then
      begin
        ShowMessage(Format('Solicitud atendida. Traspaso %s grabado.',
                           [sNumOp]));
        AplicarModo(mtAtender);
      end;
    end
    else
    begin
      sDestino := DestinoSeleccionado;
      if sDestino = '' then
        ShowMessage('Selecciona el almacén destino.')
      else if FDatos.GrabarTraspaso(sDestino, sNumOp) then
      begin
        ShowMessage(Format('Traspaso %s grabado correctamente.', [sNumOp]));
        AplicarModo(mtTraspaso);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnQuitarClick(Sender: TObject);
begin
  if not FDatos.cdsLineas.IsEmpty then
  begin
    FDatos.cdsLineas.Delete;
    ActualizarTotal;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnF11Click(Sender: TObject);
begin
  if FModo <> mtSolicitar then
    EjecutarTraspaso(False);
end;

procedure TfrmMtoOpeTraspaso.btnF12Click(Sender: TObject);
begin
  if FModo = mtSolicitar then
    EnviarSolicitud
  else
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
