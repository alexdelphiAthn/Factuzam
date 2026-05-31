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
  cxGrid, Data.DB, Uni, inLibGlobalVar, UniDataTraspaso, inLibTraspasoTicket,
  inLibGridArticulos, inLibPermisos;

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
    procedure btnF11Click(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure txtEmpleadoExit(Sender: TObject);
    procedure cboDestinoPropertiesChange(Sender: TObject);
  private
    FDatos: TdmTraspaso;
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    FGridCtrl: TGridArticulosLineas;
    FComboCodigos: TStringList;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFecha: TDateTime;
    FModo: TModoTraspaso;
    FVerCoste: Boolean;
    procedure ConstruirGrid;
    procedure GridResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
    procedure AplicarModo(AModo: TModoTraspaso);
    procedure CargarCombo;
    procedure CargarAlmacenesDestino;
    function DestinoSeleccionado: string;
    procedure ActualizarTotal;
    procedure QuitarLinea;
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
  // Permiso de ver coste/importe (global TPV). Admin siempre; por defecto S
  // para no afectar instalaciones existentes hasta que se ponga a N por grupo.
  FVerCoste := (not Assigned(oPermisos)) or
               oPermisos.TienePermiso('caja.verCoste', True);
  ConstruirGrid;
  // Elegir una solicitud en el desplegable (modo Atender) la carga sola.
  cboDestino.Properties.OnChange := cboDestinoPropertiesChange;
end;

procedure TfrmMtoOpeTraspaso.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FGridCtrl);
  FreeAndNil(FComboCodigos);
  // FDatos lo libera el Owner (Self) automáticamente.
  inherited;
end;

procedure TfrmMtoOpeTraspaso.ConstruirGrid;
var
  Campos: TCamposGridArt;
  Col: TcxGridDBColumn;
  i: Integer;
begin
  FGrid := TcxGrid.Create(Self);
  FGrid.Parent := pnlCentro;
  FGrid.Align := alClient;
  FView := FGrid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  FGrid.Levels.Add.GridView := FView;
  FView.DataController.DataSource := FDatos.dsLineas;
  FView.OptionsData.Editing := True;
  FView.OptionsData.Inserting := True;
  FView.OptionsData.Deleting := True;
  FView.OptionsView.GroupByBox := False;
  Campos.CodigoArt := 'CODIGO_ART';
  Campos.CodigoUnidad := 'CODIGO_UNIDAD';
  Campos.Descripcion := 'DESCRIPCION';
  Campos.Cantidad := 'CANTIDAD';
  Campos.NumAtributos := 'NUM_ATRIBUTOS';
  for i := 1 to 5 do
  begin
    Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR';
    Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE';
  end;
  // La controladora crea la columna de artículo + las de talla/color.
  FGridCtrl := TGridArticulosLineas.Create(oConn, FView, FDatos.cdsLineas,
                                           Campos);
  FGridCtrl.OnResuelto := GridResuelto;
  FGridCtrl.Construir;
  // Columnas propias del traspaso.
  Col := FView.CreateColumn;
  Col.Caption := 'Descripción';
  Col.DataBinding.FieldName := 'DESCRIPCION';
  Col.Options.Editing := False;
  Col.Width := 200;
  Col := FView.CreateColumn;
  Col.Caption := 'Uds';
  Col.DataBinding.FieldName := 'CANTIDAD';
  Col.Width := 50;
  Col := FView.CreateColumn;
  Col.Caption := 'Coste';
  Col.DataBinding.FieldName := 'PRECIO_COSTE';
  Col.Options.Editing := False;
  Col.Width := 70;
  // Oculta el coste a empleados sin permiso (el valor se sigue calculando y
  // guardando en el movimiento; solo se oculta de la vista).
  Col.Visible := FVerCoste;
  Col := FView.CreateColumn;
  Col.Caption := 'Stock org';
  Col.DataBinding.FieldName := 'STOCK_ORIGEN';
  Col.Options.Editing := False;
  Col.Width := 70;
end;

procedure TfrmMtoOpeTraspaso.GridResuelto(const ACodArt, ASku,
                                          ADescripcion: string;
                                          ACompleto: Boolean);
var
  sAlmacenOrigen: string;
begin
  if ACompleto and (FDatos.cdsLineas.State in [dsEdit, dsInsert]) then
  begin
    sAlmacenOrigen :=
      FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
      FDatos.ObtenerCosteMedio(ASku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
      FDatos.ObtenerStock(ASku, sAlmacenOrigen);
  end;
  ActualizarTotal;
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
  btnF11.Visible := AModo <> mtSolicitar;
  // El grid solo es editable cuando se teclean lineas (traspaso / solicitar);
  // al atender, las lineas vienen de la solicitud y no se teclean a mano.
  FView.OptionsData.Editing := AModo <> mtAtender;
  FView.OptionsData.Inserting := AModo <> mtAtender;
  FView.NewItemRow.Visible := AModo <> mtAtender;
  // Captions con tilde en literal: este .pas va en UTF-8 con BOM (igual que
  // inMtoCajaMenu.pas) para que el compilador las lea bien.
  case AModo of
    mtTraspaso:
    begin
      lblOrigen.Caption := 'ALMACÉN ORIGEN';
      lblDestino.Caption := 'ALMACÉN DESTINO';
      btnF12.Caption := 'F12 · Con ticket';
    end;
    mtSolicitar:
    begin
      lblOrigen.Caption := 'ALMACÉN DESTINO (yo)';
      lblDestino.Caption := 'ALMACÉN ORIGEN (a quién pido)';
      btnF12.Caption := 'F12 · Enviar solicitud';
    end;
    mtAtender:
    begin
      lblOrigen.Caption := 'ALMACÉN ORIGEN (yo)';
      lblDestino.Caption := 'SOLICITUD A ATENDER';
      btnF12.Caption := 'F12 · Servir con ticket';
    end;
  end;
  CargarCombo;
  cboDestino.ItemIndex := -1;
  // La fila nueva del grid (NewItemRow) ya da la linea de entrada; no se
  // hace Append manual (creaba una linea en blanco extra que competia).
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
        cTotal := cTotal +
          FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
          FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
        FDatos.cdsLineas.Next;
      end;
    finally
      FDatos.cdsLineas.GotoBookmark(bm);
      FDatos.cdsLineas.FreeBookmark(bm);
      FDatos.cdsLineas.EnableControls;
    end;
  end;
  // Sin permiso de ver coste, no se muestra el importe (revela coste).
  if FVerCoste then
    lblTotal.Caption := Format('Importe traspaso: %m', [cTotal])
  else
    lblTotal.Caption := '';
end;

procedure TfrmMtoOpeTraspaso.cboDestinoPropertiesChange(Sender: TObject);
begin
  // Al atender, elegir una solicitud del desplegable la carga directamente
  // (antes habia un boton "Cargar solicitud"; ahora es automatico).
  if FModo = mtAtender then
    CargarSolicitudSeleccionada;
end;

procedure TfrmMtoOpeTraspaso.CargarSolicitudSeleccionada;
var
  sCod, sNum, sSer: string;
  iSep: Integer;
begin
  sCod := DestinoSeleccionado;
  // Sin seleccion (p.ej. al resetear el desplegable) no hace nada.
  if sCod <> '' then
  begin
    iSep := Pos('|', sCod);
    sNum := Copy(sCod, 1, iSep - 1);
    sSer := Copy(sCod, iSep + 1, Length(sCod));
    if FDatos.CargarSolicitud(sNum, sSer) then
    begin
      txtOrigen.Text :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
      ActualizarTotal;
      // Ticket de la solicitud recibida (stock origen / destino por SKU).
      TTraspasoTicket.ImprimirSolicitud(oConn, sNum, sSer, oNomImpresoraCaja);
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
      // Ticket de la solicitud: cada SKU con stock origen / destino.
      TTraspasoTicket.ImprimirSolicitud(oConn, sNum, sSer, oNomImpresoraCaja);
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
  sNumOp, sDestino, sOrigen, sEmpleado, sNumSol, sSerSol: string;
begin
  if EmpleadoValido then
  begin
    // Origen y empleado se capturan ya (la cabecera los tiene); el ticket se
    // imprime ANTES de AplicarModo, que reinicia el cds.
    sOrigen := FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    sEmpleado := FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
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
        if AConTicket then
          TTraspasoTicket.ImprimirTraspaso(oConn, sNumOp, sOrigen, sDestino,
            sEmpleado, FDatos.cdsLineas, oNomImpresoraCaja);
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
        if AConTicket then
          TTraspasoTicket.ImprimirTraspaso(oConn, sNumOp, sOrigen, sDestino,
            sEmpleado, FDatos.cdsLineas, oNomImpresoraCaja);
        AplicarModo(mtTraspaso);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.QuitarLinea;
begin
  // Borra la linea enfocada del grid (F3). No se borra al atender: las
  // lineas vienen de la solicitud.
  if (FModo <> mtAtender) and (not FDatos.cdsLineas.IsEmpty) then
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
      QuitarLinea;
    VK_F11:
      btnF11Click(nil);
    VK_F12:
      btnF12Click(nil);
    VK_ESCAPE:
      Close;
  end;
end;

end.
