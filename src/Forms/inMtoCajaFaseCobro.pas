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
  cxGrid, cxDropDownEdit,
  // Acceso a Datos y Librerías Propias
  Uni, MemDS, VirtualTable,
  inLibGlobalVar, inMtoFrmBase, inLibFacturas, inLibFaseCobro, inMtoCajaReferenciaPago,
  dxDateRanges, dxScrollbarAnnotations;

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
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dbmImportePropertiesEditValueChanged(Sender: TObject);
    procedure btnConTicketClick(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure txtPorcenDtoGlobalPropertiesEditValueChanged(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure btnESCClick(Sender: TObject);
  private
    FTotalFactura: Currency;
    FDatosCobro: TDatosFaseCobro;
    FMemTablePagos: TVirtualTable;
    procedure CargarFormasPago;
    procedure ActualizarInterfaz;
//    procedure CalcularTotales;
    function  ValidarIntegridad: Boolean;
    procedure ConfigurarTablaVirtual;
  public
    procedure ConfigurarCobro(ATotal: Currency; ASerie, ANumero: string);
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
  Result := TfrmCajaReferenciaPago.Ejecutar(AInfo, 0, DatosRef);
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

//procedure TfrmMtoCajaFaseCobro.ConfigurarCobro(ATotal: Currency;
//                                               ASerie, ANumero: string);
//begin
//  FTotalFactura := ATotal;
//  txtTotalPagar.Value := ATotal;
//  CargarFormasPago;
//end;

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
      FieldDefs.Add('IMPORTE_DIVISA', ftCurrency);
      FieldDefs.Add('REFERENCIA', ftString, 255);
      FieldDefs.Add('IMPORTE_ENTREGADO', ftCurrency);
      FieldDefs.Add('IMPORTE_CAMBIO', ftCurrency);
      Open;
    end;
  finally
    qry.Free;
  end;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarCobro(ATotal: Currency; ASerie,
  ANumero: string);
begin

end;

procedure TfrmMtoCajaFaseCobro.ConfigurarTablaVirtual;
begin
  FMemTablePagos := TVirtualTable.Create(Self);
end;

procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesEditValueChanged(Sender: TObject);
var
  fp: TFormaPagoInfo;
  dr: TDatosReferencia;
  ImporteActual: Currency;
begin
  dbtvFormasPago.DataController.Post;
  dr.EsCripto :=
                (FMemTablePagos.FieldByName('ES_CRIPTO_FORMAP').AsString = 'S');
  dr.EsDivisa := (FMemTablePagos.FieldByName('ESDIVISA_FORMAP').AsString = 'S');
  ImporteActual := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
  if (ImporteActual > 0) and
     ((FMemTablePagos.FieldByName('ES_REQ_REFERENCIA_FORMAP').AsString = 'S') or
      dr.EsCripto or
      dr.EsDivisa ) then
  begin
    fp.Codigo := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
    fp.Descripcion := FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString;

    fp.RequiereReferencia := True;
    if TfrmCajaReferenciaPago.Ejecutar(fp, ImporteActual, dr) then
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString := dr.Referencia;
      FMemTablePagos.Post;
    end
    else
    begin
      // Si cancela la referencia, anulamos el importe por seguridad
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := 0;
      FMemTablePagos.Post;
    end;
  end;
  FDatosCobro.Recalcular;
//  CalcularTotales;
end;

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
var
  PorcentajeMedio: Double;
begin
if TotalesFactura = nil then Exit;

  // Pasamos los totales a la lógica
  FDatosCobro.CargarDatosFactura(TotalesFactura);

  // Configuramos datos del cliente si existen en la factura
  // Nota: Deberás ajustar estos campos según tu TFacturaTotales real
  // FDatosCobro.EstablecerCliente(...)

  // Pintamos datos estáticos (informativos)
  txtCantidadLineas.Text := FormatFloat('0.##',
                                        TotalesFactura.Totales.TotalCantidades);
  txtBrutoLineas.Value := TotalesFactura.Totales.TotalBruto;
  txtTotalDtoLineal.Value := TotalesFactura.Totales.TotalDescuentosLineas;
  if TotalesFactura.Totales.TotalBruto <> 0 then
    txtPorcenDtoLineal.Text := FormatFloat('0.## %', (TotalesFactura.Totales.TotalDescuentosLineas / TotalesFactura.Totales.TotalBruto) * 100)
  else
    txtPorcenDtoLineal.Text := '0 %';
  // Forzamos un recálculo inicial para llenar el resto de campos
  FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.AlRecalcularDatos(Sender: TObject);
begin
  txtDtoGlobal.Value := FDatosCobro.ImporteDescuentoGlobal;
  txtTotalPagar.Value := FDatosCobro.ImporteTotalPagar;
  txtPendienteCobro.Value := FDatosCobro.ImportePendiente;
  txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
  txtCambio.Value := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value := FDatosCobro.ImporteValeRecogido;
  txtValeEmitido.Value := FDatosCobro.ImporteValeEmitido;

  // Habilitar botón de ticket solo si está pagado
  btnConTicket.Enabled :=(FDatosCobro.ImportePendiente <= 0.01);
  btnF12.Enabled := btnConTicket.Enabled;
end;

//procedure TfrmMtoCajaFaseCobro.CalcularTotales;
//var
//  SumaEntregado, SumaPermiteCambio, Exceso, AlVale, AlCambio: Currency;
//begin
//  SumaEntregado := 0;
//  SumaPermiteCambio := 0;
//
//  FMemTablePagos.DisableControls;
//  try
//    FMemTablePagos.First;
//    while not FMemTablePagos.Eof do
//    begin
//      SumaEntregado := SumaEntregado +
//                     FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
//      if FMemTablePagos.FieldByName(
//                                'ES_DEVUELVE_CAMBIO_FORMAP').AsString = 'S' then
//        SumaPermiteCambio := SumaPermiteCambio +
//                     FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
//      FMemTablePagos.Next;
//    end;
//  finally
//    FMemTablePagos.EnableControls;
//  end;
//
//  // Cálculo de Pendiente
//  txtPendienteCobro.Value := Max(0, FTotalFactura - SumaEntregado);
//
//  // REQUISITO: Lógica de Vale vs Cambio
//  Exceso := Max(0, SumaEntregado - FTotalFactura);
//
//  if Exceso > 0 then
//  begin
//    // Si lo que sobra es más de lo que el cliente dio en "Efectivo", la diferencia es un Vale
//    if SumaPermiteCambio >= Exceso then
//    begin
//      AlCambio := Exceso;
//      AlVale := 0;
//    end
//    else
//    begin
//      AlCambio := SumaPermiteCambio;
//      AlVale := Exceso - SumaPermiteCambio;
//    end;
//  end
//  else
//  begin
//    AlCambio := 0;
//    AlVale := 0;
//  end;
//  txtCambio.Value := AlCambio;
//  txtValeEmitido.Value := AlVale;
//  btnConTicket.Enabled := (txtPendienteCobro.Value <= 0);
//end;

function TfrmMtoCajaFaseCobro.ValidarIntegridad: Boolean;
begin
  // Aquí puedes añadir validaciones finales antes de cerrar
  Result := txtPendienteCobro.Value <= 0.001;
end;

procedure TfrmMtoCajaFaseCobro.btnConTicketClick(Sender: TObject);
begin
  if ValidarIntegridad then
    ModalResult := mrOk;
end;

procedure TfrmMtoCajaFaseCobro.btnESCClick(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnAtrasClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
begin
  inherited;
//  cbbSerie1.Text := FSerieOperacion;
//  edtNumeroDoc.Text := FNumeroOperacion;

  // Cargar las formas de pago disponibles
  CargarFormasPago;

  // Actualizar interfaz
  ActualizarInterfaz;

  // Poner el foco en el grid
  if cxgrdFormasPago.CanFocus then
  begin
    cxgrdFormasPago.SetFocus;
    if dbtvFormasPago.Controller.SelectedRecordCount > 0 then
      dbtvFormasPago.Controller.FocusedColumn := dbmImporte;
  end;
end;

procedure TfrmMtoCajaFaseCobro.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.ActualizarInterfaz;
begin
  // Actualizar campos calculados
  txtDtoGlobal.Value := FDatosCobro.ImporteDescuentoGlobal;
  txtTotalPagar.Value := FDatosCobro.ImporteTotalPagar;
  txtPendienteCobro.Value := FDatosCobro.ImportePendiente;
  txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
  txtCambio.Value := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value := FDatosCobro.ImporteValeRecogido;
  txtValeEmitido.Value := FDatosCobro.ImporteValeEmitido;

  // Habilitar/deshabilitar botones
  btnConTicket.Enabled := (FDatosCobro.ImportePendiente <= 0.01);
  btnF12.Enabled := btnConTicket.Enabled;
end;


procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
//   CalcularTotales;
  FDatosCobro.Recalcular;
end;


end.
