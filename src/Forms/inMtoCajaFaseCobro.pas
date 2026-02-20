unit inMtoCajaFaseCobro;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB, Math,
  // Componentes DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxGrid, cxDropDownEdit, dxDateRanges, dxScrollbarAnnotations,
  // Acceso a Datos y Librerías Propias
  Uni, MemDS, VirtualTable,
  inLibGlobalVar, inMtoFrmBase, inLibFacturas, inLibFaseCobro,
  inMtoCajaReferenciaPago;
type
  TfrmMtoCajaFaseCobro = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlIzquierdo: TPanel;
    pnlDerecho: TPanel;
    dsFormasPago: TDataSource;
    txtTotalPagar: TcxCurrencyEdit;
    txtPendienteCobro: TcxCurrencyEdit;
    txtCantidadLineas: TcxTextEdit;
    txtBrutoLineas: TcxCurrencyEdit;
    txtPorcenDtoLineal: TcxTextEdit;
    txtTotalDtoLineal: TcxCurrencyEdit;
    txtPorcenDtoGlobal: TcxCurrencyEdit;
    txtDtoGlobal: TcxCurrencyEdit;
    lblNumDoc: TcxLabel;
    edtNumeroDoc: TcxTextEdit;
    cbbSerie1: TcxComboBox;
    pnl11: TPanel;
    lblDescuento3: TcxLabel;
    lblSuma1: TcxLabel;
    txtDejarCuenta: TcxCurrencyEdit;
    txtPendienteCuenta: TcxCurrencyEdit;
    pnl111: TPanel;
    lblDescuento31: TcxLabel;
    lblSuma11: TcxLabel;
    txtValeRecogido: TcxCurrencyEdit;
    txtValeEmitido: TcxCurrencyEdit;
    txtCambio: TcxCurrencyEdit;
    cxgrdFormasPago: TcxGrid;
    dbtvFormasPago: TcxGridDBTableView;
    dbmImporte: TcxGridDBColumn;
    btnSinTicket: TcxButton;
    btnF11: TcxButton;
    btnConTicket: TcxButton;
    btnF12: TcxButton;
    btnSinPrecios: TcxButton;
    btnF10: TcxButton;
    btnDeposito: TcxButton;
    btnF7: TcxButton;
    btnFactura: TcxButton;
    btnF8: TcxButton;
    btnBuscarVale: TcxButton;
    btnF6: TcxButton;
    btnMasDatos: TcxButton;
    btnF2: TcxButton;
    btnBuscarT: TcxButton;
    btnF3: TcxButton;
    btnAtras: TcxButton;
    btnESC: TcxButton;
    ActionList1: TActionList;
    actSalir: TAction;
    pnlLogoLeft: TPanel;
    Panel2: TPanel;
    pnl1: TPanel;
    lblDescuento1: TcxLabel;
    lblDescuento2: TcxLabel;
    lblDescuento: TcxLabel;
    lblSuma: TcxLabel;
    // Edits de Importes
    cxgrdlvlFormasPago: TcxGridLevel;
    // Columnas Grid
    cxgrdbclmnCodigo: TcxGridDBColumn;
    dbmDescripcion: TcxGridDBColumn;
    // Panel Inferior (Totales finales)
    lblDescuento4: TcxLabel;
    cxLabel2: TcxLabel;
    cxLabel1: TcxLabel;
    cxStyleRepository1: TcxStyleRepository;
    cxStyle1: TcxStyle;
    dbtvFormasPagoColumn1: TcxGridDBColumn;
    dbtvFormasPagoColumn2: TcxGridDBColumn;
    dbtvFormasPagoColumn3: TcxGridDBColumn;
    actBuscarT: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dbmImportePropertiesEditValueChanged(Sender: TObject);
    procedure btnConTicketClick(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure txtPorcenDtoGlobalPropertiesEditValueChanged(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure btnESCClick(Sender: TObject);
    procedure dbmImporteGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure txtValeEmitidoPropertiesEditValueChanged(Sender: TObject);
    procedure dbtvFormasPagoEditChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure btnBuscarTClick(Sender: TObject);
    procedure btnF3Click(Sender: TObject);
    procedure actBuscarTExecute(Sender: TObject);
  private
    FTotalFactura: Currency;
    FDatosCobro: TDatosFaseCobro;
    FMemTablePagos: TVirtualTable;
    FActualizandoVale: Boolean;  // evita bucle en OnEditValueChanged de txtValeEmitido
    procedure CargarFormasPago;
    procedure AjustarFormatoEditorActivo;
    procedure ActualizarInterfaz;
    function  ValidarIntegridad: Boolean;
    procedure ConfigurarTablaVirtual;
    procedure ConfigurarModoDevolucion;
    procedure ConfigurarModoCobroNormal;
    procedure RellenarPendienteEnFormaActual;
    procedure EscribirImporteEnFormaActual(AImporte: Double);
  public
    procedure CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
    procedure AlRecalcularDatos(Sender: TObject);
    function AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                  ADatosActuales: TDatosReferencia): Boolean;
  end;
implementation
{$R *.dfm}
function TfrmMtoCajaFaseCobro.AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                     ADatosActuales: TDatosReferencia): Boolean;
var
  DatosRef: TDatosReferencia;
begin
  DatosRef := ADatosActuales;
  // Llamamos a tu formulario modal existente
  Result := TfrmCajaReferenciaPago.Ejecutar(AInfo,
                                            txtPendienteCobro.value,
                                            DatosRef);
end;
procedure TfrmMtoCajaFaseCobro.FormCreate(Sender: TObject);
begin
  inherited;
  ConfigurarTablaVirtual; // Crea FMemTablePagos
  // 1. Instanciamos la lógica pasándole la tabla que acabamos de crear
  FDatosCobro := TDatosFaseCobro.Create(FMemTablePagos);
  // 2. Asignamos los eventos para que la lógica "hable" con el formulario
  FDatosCobro.OnRecalculado := AlRecalcularDatos;
  FDatosCobro.OnRequiereReferencia := AlRequerirReferencia;
  CargarFormasPago;
  dsFormasPago.DataSet := FMemTablePagos;
end;
procedure TfrmMtoCajaFaseCobro.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FDatosCobro) then
    FDatosCobro.Free;
end;
procedure TfrmMtoCajaFaseCobro.CargarFormasPago;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := '  SELECT * ' +
                    '    FROM fza_caja_formas_pago ' +
                      ' WHERE ES_ACTIVO_FORMAP = ''S'' ' +
                    'ORDER BY ORDEN_VISUAL_FORMAP';
    qry.Open;
    with FMemTablePagos do
    begin
      Clear;
      Assign(qry);
      FieldDefs.Add('FACTOR_CAMBIO', ftCurrency);
      FieldDefs.Add('ESIMPORTE_DIVISA', ftString, 1);
      FieldDefs.Add('REFERENCIA', ftString, 255);
      FieldDefs.Add('IMPORTE_ENTREGADO', ftFloat);
      FieldDefs.Add('IMPORTE_DIVISA', ftFloat);
      FieldDefs.Add('IMPORTE_CAMBIO', ftCurrency);
      Open;
    end;
  finally
    qry.Free;
  end;
end;
procedure TfrmMtoCajaFaseCobro.RellenarPendienteEnFormaActual;
var
  Pendiente: Currency;
begin
  if not (FMemTablePagos.Active and not FMemTablePagos.IsEmpty) then Exit;
  if FDatosCobro.EsDevolucion then
    Pendiente := FDatosCobro.ImporteDevolucionPendiente
  else
    Pendiente := FDatosCobro.ImportePendiente;
  if Pendiente <= 0.01 then Exit;
  // En devolución el importe va negativo (se entrega dinero al cliente)
  if FDatosCobro.EsDevolucion then
    EscribirImporteEnFormaActual(-Pendiente)
  else
    EscribirImporteEnFormaActual(Pendiente);
end;
procedure TfrmMtoCajaFaseCobro.ConfigurarTablaVirtual;
begin
  FMemTablePagos := TVirtualTable.Create(Self);
end;
procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesEditValueChanged(Sender: TObject);
var
  ImporteActual: Double;
  v: Variant;
begin
  // Origen: teclado del usuario
  ImporteActual := 0;
  if Sender is TcxCurrencyEdit then
  begin
    v := TcxCurrencyEdit(Sender).EditingValue;
    if not (VarIsNull(v) or VarIsEmpty(v)) then
      ImporteActual := Double(v);
  end
  else if Sender is TcxCustomEdit then
  begin
    TcxCustomEdit(Sender).PostEditValue;
    ImporteActual := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat;
  end;
  if Abs(ImporteActual) < 0.0000000001 then
    Exit;
  // En devolución: si el usuario escribió positivo, lo invertimos
  if FDatosCobro.EsDevolucion then
  begin
    FDatosCobro.Recalcular; // actualiza pendiente antes de abrir diálogo
    EscribirImporteEnFormaActual(-Abs(ImporteActual));
  end
  else
    EscribirImporteEnFormaActual(ImporteActual);
end;
procedure TfrmMtoCajaFaseCobro.AjustarFormatoEditorActivo;
var
  EsCripto, EsDivisa: Boolean;
  EditProps: TcxCurrencyEditProperties;
  ActiveEdit: TcxCustomEdit;
begin
  EsCripto := (FMemTablePagos.FieldByName('ES_CRIPTO_FORMAP').AsString = 'S');
  EsDivisa := (FMemTablePagos.FieldByName('ESDIVISA_FORMAP').AsString = 'S');
  // Accedemos al editor activo del grid, que YA existe y tiene handle
  ActiveEdit := dbtvFormasPago.Controller.EditingController.Edit;
  if not Assigned(ActiveEdit) then Exit;
  if not (ActiveEdit is TcxCurrencyEdit) then Exit;
  EditProps := TcxCurrencyEditProperties(
                 TcxCurrencyEdit(ActiveEdit).ActiveProperties);
  if EsCripto then
  begin
    EditProps.DecimalPlaces := 9;
    EditProps.DisplayFormat := '#,##0.#########';
    EditProps.EditFormat    := '#########0.#########';
  end
  else
    if EsDivisa then
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00';
      EditProps.EditFormat    := ',0.00';
    end
    else
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00 €';
      EditProps.EditFormat    := ',0.00 €';
    end;
end;
procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoEditChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
begin
  inherited;
  if AItem <> dbmImporte then
    Exit;
  AjustarFormatoEditorActivo;
end;

procedure TfrmMtoCajaFaseCobro.EscribirImporteEnFormaActual(AImporte: Double);
var
  fp: TFormaPagoInfo;
  dr: TDatosReferencia;
  EsDivisa, EsCripto: Boolean;
begin
  EsDivisa := FMemTablePagos.FieldByName('ESDIVISA_FORMAP').AsString = 'S';
  EsCripto  := FMemTablePagos.FieldByName('ES_CRIPTO_FORMAP').AsString = 'S';
  fp.Codigo             := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
  fp.Descripcion        :=
                      FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString;
  fp.RequiereReferencia :=
          FMemTablePagos.FieldByName('ES_REQ_REFERENCIA_FORMAP').AsString = 'S';
  dr.Init;
  dr.EsDivisa  := EsDivisa;
  dr.EsCripto  := EsCripto;
  dr.Pendiente := txtPendienteCobro.Value;
  if EsDivisa or EsCripto or fp.RequiereReferencia then
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := AImporte;
    FMemTablePagos.Post;
    if TfrmCajaReferenciaPago.Ejecutar(fp, Abs(AImporte), dr) then
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString       := dr.Referencia;
      if EsDivisa then
      begin
        FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat    :=
                                                               dr.ImporteDivisa;
        FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency  :=
                                                                dr.FactorCambio;
        FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
        FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat :=
                                                                dr.ImporteEuros;
      end;
      FMemTablePagos.Post;
    end
    else
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString       := '';
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := 0;
      FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat    := 0;
      FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
      FMemTablePagos.Post;
    end;
  end
  else
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := AImporte;
    FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
    FMemTablePagos.Post;
  end;
  FDatosCobro.Recalcular;
end;
procedure TfrmMtoCajaFaseCobro.dbmImporteGetDisplayText(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AText: string);
var
  EsDivisa: Boolean;
  Importe: Currency;
  RecordIndex: Integer;
//  DC: TcxGridDBDataController;
  IdxDivisa, IdxCripto, IdxImporte, IdxEsDivisa: Integer;
  vImporte, vEsDivisa: Variant;
begin
  RecordIndex := ARecord.RecordIndex;
  if RecordIndex < 0 then Exit;
  var DC := dbtvFormasPago.DataController;
  IdxDivisa  := DC.GetItemByFieldName('ESDIVISA_FORMAP').Index;
  IdxCripto  := DC.GetItemByFieldName('ES_CRIPTO_FORMAP').Index;
  IdxImporte := DC.GetItemByFieldName('IMPORTE_ENTREGADO').Index;
  IdxEsDivisa := DC.GetItemByFieldName('ESIMPORTE_DIVISA').Index;
  EsDivisa :=
    (VarToStr(DC.Values[RecordIndex, IdxDivisa]) = 'S') or
    (VarToStr(DC.Values[RecordIndex, IdxCripto]) = 'S');
  if EsDivisa then
  begin
    vImporte := DC.Values[RecordIndex, IdxImporte];
    // Protegemos el cast si el valor es Null
    if VarIsNull(vImporte) or VarIsEmpty(vImporte) then
      Importe := 0
    else
      Importe := Currency(vImporte);
    vEsDivisa := DC.Values[RecordIndex, IdxEsDivisa];
    if VarIsNull(vEsDivisa) or VarIsEmpty(vEsDivisa) then
    begin
      AText := ''
    end
    else
    begin
      if Importe > 0 then
        AText := FormatFloat('#,##0.000000000', Importe);
      if (vEsDivisa = 'N') then
        AText := FormatCurr(',0.00 €', Importe);
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura:
                                                       TFacturaTotales);
var
  PorcentajeMedio: Double;
begin
if TotalesFactura = nil then Exit;
  FDatosCobro.CargarDatosFactura(TotalesFactura);
  txtCantidadLineas.Text := FormatFloat('0.##',
                                        TotalesFactura.Totales.TotalCantidades);
  txtBrutoLineas.Value := TotalesFactura.Totales.TotalBruto;
  txtTotalDtoLineal.Value := TotalesFactura.Totales.TotalDescuentosLineas;
  if TotalesFactura.Totales.TotalBruto <> 0 then
    txtPorcenDtoLineal.Text := FormatFloat('0.## %',
                             (TotalesFactura.Totales.TotalDescuentosLineas /
                              TotalesFactura.Totales.TotalBruto) * 100)
  else
    txtPorcenDtoLineal.Text := '0 %';
  FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.AlRecalcularDatos(Sender: TObject);
var
  EsTotal0: Boolean;
begin
  txtDtoGlobal.Value    := FDatosCobro.ImporteDescuentoGlobal;
  txtTotalPagar.Value   := FDatosCobro.ImporteTotalPagar;
  txtCambio.Value       := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value := FDatosCobro.ImporteValeRecogido;
  FActualizandoVale := True;
  try
    txtValeEmitido.Value := FDatosCobro.ImporteValeEmitido;
  finally
    FActualizandoVale := False;
  end;
  EsTotal0 := (Abs(FDatosCobro.ImporteTotalPagar) < 0.01);
  if FDatosCobro.EsDevolucion then
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImporteDevolucionPendiente;
    txtPendienteCuenta.Value := 0;
    btnConTicket.Enabled  := (FDatosCobro.ImporteDevolucionPendiente <= 0.01) or EsTotal0;
    btnSinTicket.Enabled  := (FDatosCobro.ImporteDevolucionPendiente <= 0.01) or EsTotal0;
    btnSinPrecios.Enabled := (FDatosCobro.ImporteDevolucionPendiente <= 0.01) or EsTotal0;
  end
  else
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImportePendiente;
    txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
    btnConTicket.Enabled  := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnSinTicket.Enabled  := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnSinPrecios.Enabled := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
  end;
  btnBuscarT.Enabled := (txtPendienteCobro.Value > 0.01) and not EsTotal0;
  btnF3.Enabled      := btnBuscarT.Enabled;
  btnF12.Enabled := btnConTicket.Enabled;
  btnF11.Enabled := btnSinTicket.Enabled;
  btnF10.Enabled := btnSinPrecios.Enabled;
end;

function TfrmMtoCajaFaseCobro.ValidarIntegridad: Boolean;
var
  EsTotal0: Boolean;
begin
  EsTotal0 := (Abs(FDatosCobro.ImporteTotalPagar) < 0.01);
  if EsTotal0 then
    Result := True
  else if FDatosCobro.EsDevolucion then
    Result := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
  else
    Result := (txtPendienteCobro.Value <= 0.01);
end;

procedure TfrmMtoCajaFaseCobro.ActualizarInterfaz;
begin
  txtDtoGlobal.Value      := FDatosCobro.ImporteDescuentoGlobal;
  txtTotalPagar.Value     := FDatosCobro.ImporteTotalPagar;
  txtCambio.Value         := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value   := FDatosCobro.ImporteValeRecogido;
  txtValeEmitido.Value    := FDatosCobro.ImporteValeEmitido;
  if FDatosCobro.EsDevolucion then
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImporteDevolucionPendiente;
    txtPendienteCuenta.Value := 0;
    btnConTicket.Enabled := (FDatosCobro.ImporteDevolucionPendiente <= 0.01);
  end
  else
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImportePendiente;
    txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
    btnConTicket.Enabled := (FDatosCobro.ImportePendiente <= 0.01);
  end;
  btnF12.Enabled := btnConTicket.Enabled;
  if FDatosCobro.EsDevolucion then
    ConfigurarModoDevolucion
  else
    ConfigurarModoCobroNormal;
end;
procedure TfrmMtoCajaFaseCobro.ConfigurarModoDevolucion;
begin
  // Descuento global no aplica en devolución
  txtPorcenDtoGlobal.Enabled := False;
  // El cajero puede escribir directamente el importe del vale a emitir
  txtValeEmitido.Properties.ReadOnly := False;
  txtValeEmitido.Style.Color := clWindow;
  // Etiqueta "Pendiente de cobro" → "Pendiente de devolver"
  lblDescuento4.Caption := 'Pendiente de devolver';
end;
procedure TfrmMtoCajaFaseCobro.ConfigurarModoCobroNormal;
begin
  txtPorcenDtoGlobal.Enabled := True;
  txtValeEmitido.Properties.ReadOnly := True;
  txtValeEmitido.Style.Color := clWhite;
  lblDescuento4.Caption := 'Pendiente de cobro';
end;

procedure TfrmMtoCajaFaseCobro.txtValeEmitidoPropertiesEditValueChanged(
  Sender: TObject);
begin
  if not FDatosCobro.EsDevolucion then Exit;
  if FActualizandoVale then Exit;
  FActualizandoVale := True;
  try
    FDatosCobro.EmitirVale(txtValeEmitido.Value);
  finally
    FActualizandoVale := False;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnConTicketClick(Sender: TObject);
var
  Res: TResultadoValidacion;
begin
  Res := FDatosCobro.ValidarParaCobro;
  if not Res.Valido then
  begin
    MessageDlg(Res.Mensaje, mtError, [mbOK], 0);
    Exit;
  end;
  ModalResult := mrOk;
end;
procedure TfrmMtoCajaFaseCobro.btnESCClick(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;
procedure TfrmMtoCajaFaseCobro.btnF3Click(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.btnAtrasClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;
procedure TfrmMtoCajaFaseCobro.btnBuscarTClick(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
begin
  inherited;
  CargarFormasPago;
  ActualizarInterfaz;
  if cxgrdFormasPago.CanFocus then
  begin
    cxgrdFormasPago.SetFocus;
    if dbtvFormasPago.Controller.SelectedRecordCount > 0 then
      dbtvFormasPago.Controller.FocusedColumn := dbmImporte;
  end;
end;
procedure TfrmMtoCajaFaseCobro.actBuscarTExecute(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;
procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesEditValueChanged(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
begin
  if (Sender is TcxCustomEdit) then
  begin
    Edit := TcxCustomEdit(Sender);
    Edit.PostEditValue;
  end;
  FDatosCobro.AplicarDescuentoGlobal(txtPorcenDtoGlobal.Value);
  FDatosCobro.Recalcular;
end;

end.
