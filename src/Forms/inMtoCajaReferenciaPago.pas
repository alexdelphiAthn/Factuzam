unit inMtoCajaReferenciaPago;
{
  Formulario para captura de referencia de pago y datos de divisa
  Usado para pagos con tarjeta, transferencias, criptomonedas, etc.
  que requieren información adicional como número de autorización,
  tipo de cambio, etc.
}
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit,
  cxCurrencyEdit, cxLabel, cxButtons, cxGroupBox, cxDropDownEdit,
  // Unidades propias
  inLibFaseCobro, inMtoFrmBase, Vcl.Menus;
type
  TfrmCajaReferenciaPago = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    // Información de la forma de pago
    gbInfoPago: TcxGroupBox;
    lblFormaPago: TcxLabel;
    lblFormaPagoValor: TcxLabel;
    lblImporte: TcxLabel;
    edtImporte: TcxCurrencyEdit;
    // Referencia
    gbReferencia: TcxGroupBox;
    lblReferencia: TcxLabel;
    edtReferencia: TcxTextEdit;
    lblEjemplo: TcxLabel;
    // Divisa (opcional)
    gbDivisa: TcxGroupBox;
    lblDivisa: TcxLabel;
    lblFactorCambio: TcxLabel;
    edtFactorCambio: TcxCurrencyEdit;
    lblImporteDivisa: TcxLabel;
    edtImporteDivisa: TcxCurrencyEdit;
    lblEquivale: TcxLabel;
    // Blockchain (para crypto)
    gbBlockchain: TcxGroupBox;
    lblRedBlockchain: TcxLabel;
    cbbRedBlockchain: TcxComboBox;
    lblTxHash: TcxLabel;
    edtTxHash: TcxTextEdit;
    txtDivisa: TcxTextEdit;
    btnGetDivisa: TcxButton;
    lblEquivale2: TcxLabel;
    txtPendiente: TcxCurrencyEdit;
    cxLabel1: TcxLabel;
    txtSobra: TcxCurrencyEdit;
    cxLabel2: TcxLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
//    procedure chkUsarOtraDivisaClick(Sender: TObject);
    procedure edtFactorCambioPropertiesChange(Sender: TObject);
    procedure edtImporteDivisaPropertiesChange(Sender: TObject);
    procedure edtImportePropertiesChange(Sender: TObject);
//    procedure cbbDivisaPropertiesChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnGetDivisaClick(Sender: TObject);
  private
    FFormaPagoInfo: TFormaPagoInfo;
    FImporteOriginal, FPendiente: Double;
    FDatosResultado: TDatosReferencia;
    procedure ConfigurarInterfaz;
    procedure ActualizarCalculosDivisa;
    procedure CargarDivisasDisponibles;
    procedure CargarRedesBlockchain;
    function ValidarDatos: Boolean;
    procedure GetDivisa;
    procedure GetCripto;
  public
    class function Ejecutar(const AFormaPago: TFormaPagoInfo;
                            AImporte: Double;
                            var ADatosRef: TDatosReferencia): Boolean;
  end;

var
  frmCajaReferenciaPago: TfrmCajaReferenciaPago;

implementation

{$R *.dfm}

uses
  System.Math, Vcl.Themes, inLibDivCurr, inLibCriptoCurr;

{ TfrmCajaReferenciaPago }

class function TfrmCajaReferenciaPago.Ejecutar(
  const AFormaPago: TFormaPagoInfo; AImporte: Double;
  var ADatosRef: TDatosReferencia): Boolean;
var
  Frm: TfrmCajaReferenciaPago;
begin
  Result := False;
  Frm := TfrmCajaReferenciaPago.Create(nil);
  try
    Frm.FFormaPagoInfo := AFormaPago;
    Frm.FDatosResultado := ADatosRef;
    if Frm.ShowModal = mrOk then
    begin
      ADatosRef := Frm.FDatosResultado;
      Result := True;
    end;
  finally
    Frm.Free;
  end;
end;

procedure TfrmCajaReferenciaPago.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  // Configurar valores por defecto
//  FDatosResultado.Init;
end;

procedure TfrmCajaReferenciaPago.FormShow(Sender: TObject);
begin
  inherited;
  ConfigurarInterfaz;
//  if FDatosResultado.EsDivisa then
//    btnGetDivisaClick(Sender);
  // Poner foco en referencia
//  if edtReferencia.Enabled and edtReferencia.Visible and edtReferencia.CanFocus then
//    edtReferencia.SetFocus;
end;

procedure TfrmCajaReferenciaPago.ConfigurarInterfaz;
//var
//  EsTarjeta, EsCripto, EsTransferencia: Boolean;
begin
  // Mostrar información de la forma de pago
  lblFormaPagoValor.Caption := FFormaPagoInfo.Descripcion;
  //edtImporte.Value := FImporteOriginal;
  edtImporte.Enabled := False; // No permitir cambiar el importe aquí
  // Determinar tipo de pago
//  EsTarjeta := SameText(FFormaPagoInfo.TipoComportamiento, 'TARJETA');
//  EsCripto := Pos('CRYPTO', UpperCase(FFormaPagoInfo.TipoComportamiento)) > 0;
//  EsTransferencia := SameText(FFormaPagoInfo.TipoComportamiento, 'TRANSFERENCIA');
  // Configurar grupo de referencia
  txtDivisa.Text := FFormaPagoInfo.Codigo + ' - ' + FFormaPagoInfo.Descripcion;
  gbReferencia.Visible := FFormaPagoInfo.RequiereReferencia;
  edtImporte.Value := FImporteOriginal;
  txtPendiente.Value := FDatosResultado.Pendiente;
  edtReferencia.Text := FDatosResultado.Referencia;
  if FDatosResultado.EsCripto then
  begin
    gbBlockChain.Enabled := True;
//    lblReferencia.Caption := 'Referencia:';
////    lblEjemplo.Caption := 'Ej: 0x...';
//    edtReferencia.Properties.MaxLength := 100;
  end
  else
  begin
    gbBlockChain.Enabled := False;
//    lblReferencia.Caption := 'Referencia:';
//    lblEjemplo.Caption := '';
//    edtReferencia.Properties.MaxLength := 255;
  end;
  // Configurar grupo blockchain
  gbBlockchain.Visible := FDatosResultado.EsCripto;
  if FDatosResultado.EsCripto then
    CargarRedesBlockchain;
  // Configurar grupo divisa
  if FDatosResultado.EsDivisa then
  begin
    gbDivisa.Enabled := True;
    gbDivisa.Visible := True;
//    chkUsarOtraDivisa.Checked := True;
    CargarDivisasDisponibles;
    lblDivisa.Enabled := True;
    txtDivisa.Enabled := True;
    lblFactorCambio.Enabled := True;
    edtFactorCambio.Enabled := True;
    lblImporteDivisa.Enabled := True;
    edtImporteDivisa.Enabled := True;
    lblEquivale.Enabled := True;
  end
  else
  begin
    gbDivisa.Enabled := False;
    gbDivisa.Visible := False;
//    chkUsarOtraDivisa.Checked := False;
    lblDivisa.Enabled := False;
    txtDivisa.Enabled := False;
    lblFactorCambio.Enabled := False;
    edtFactorCambio.Enabled := False;
    lblImporteDivisa.Enabled := False;
    edtImporteDivisa.Enabled := False;
    lblEquivale.Enabled := False;
  end;
end;

procedure TfrmCajaReferenciaPago.CargarDivisasDisponibles;
begin
//  cbbDivisa.Properties.Items.Clear;
//  cbbDivisa.Properties.Items.Add('USD - Dólar Estadounidense');
//  cbbDivisa.Properties.Items.Add('GBP - Libra Esterlina');
//  cbbDivisa.Properties.Items.Add('CHF - Franco Suizo');
//  cbbDivisa.Properties.Items.Add('JPY - Yen Japonés');
//  cbbDivisa.Properties.Items.Add('BTC - Bitcoin');
//  cbbDivisa.Properties.Items.Add('ETH - Ethereum');
//  cbbDivisa.Properties.Items.Add('USDT - Tether');
//  cbbDivisa.ItemIndex := 0;
end;

procedure TfrmCajaReferenciaPago.CargarRedesBlockchain;
begin
  cbbRedBlockchain.Properties.Items.Clear;
  cbbRedBlockchain.Properties.Items.Add('Bitcoin');
  cbbRedBlockchain.Properties.Items.Add('Ethereum');
  cbbRedBlockchain.Properties.Items.Add('Lightning Network');
  cbbRedBlockchain.Properties.Items.Add('Polygon');
  cbbRedBlockchain.Properties.Items.Add('BSC (Binance Smart Chain)');
  cbbRedBlockchain.Properties.Items.Add('Tron (TRC20)');
  cbbRedBlockchain.Properties.Items.Add('Solana');
  cbbRedBlockchain.ItemIndex := 0;
end;

procedure TfrmCajaReferenciaPago.edtFactorCambioPropertiesChange(Sender: TObject);
begin
  ActualizarCalculosDivisa;
end;

procedure TfrmCajaReferenciaPago.edtImporteDivisaPropertiesChange(Sender: TObject);
begin
  // Si cambia el importe en divisa, recalcular el factor
//  if (edtImporteDivisa.Value > 0) and (FImporteOriginal > 0) then
//  begin
//    edtFactorCambio.Value := FImporteOriginal / edtImporteDivisa.Value;
//  end;
end;

procedure TfrmCajaReferenciaPago.edtImportePropertiesChange(Sender: TObject);
begin
  ActualizarCalculosDivisa;
end;

procedure TfrmCajaReferenciaPago.ActualizarCalculosDivisa;
var
  sDivisa: string;
  ImporteEuros: Double;
begin
  sDivisa := Copy(txtDivisa.Text, 1, 3);
  if edtFactorCambio.Value > 0 then
  begin
    ImporteEuros := edtImporteDivisa.Value * edtFactorCambio.Value;
    edtImporteDivisa.Value := ImporteEuros;
  end;
  if edtFactorCambio.Value > 0 then
  begin
    lblEquivale.Caption := Format('1 EUR = %.9n %s',
      [edtFactorCambio.Value, sDivisa]);
    lblEquivale2.Caption := Format('1 %s = %.2n EUR',
        [sDivisa, 1/edtFactorCambio.Value]);
  end;
  FDatosResultado.FactorCambio  := edtFactorCambio.Value;  // precio mercado
  FDatosResultado.ImporteDivisa := edtImporteDivisa.Value; // BTC entregados
  FDatosResultado.ImporteEuros  := edtImporte.Value;       // EUR equivalentes
end;

function TfrmCajaReferenciaPago.ValidarDatos: Boolean;
begin
  Result := False;
  // Validar referencia si es requerida
  if FFormaPagoInfo.RequiereReferencia and
     (Trim(edtReferencia.Text) = '') and
     gbReferencia.Visible then
  begin
    ShowMessage('Debe introducir la referencia del pago.');
    if edtReferencia.CanFocus then
      edtReferencia.SetFocus;
    Exit;
  end;
  // Validar divisa si está activada
  if FDatosResultado.EsDivisa then
  begin
    if edtFactorCambio.Value <= 0 then
    begin
      ShowMessage('El factor de cambio debe ser mayor que cero.');
      if edtFactorCambio.CanFocus then
        edtFactorCambio.SetFocus;
      Exit;
    end;
//    if edtImporteDivisa.Value <= 0 then
//    begin
//      ShowMessage('El importe en divisa debe ser mayor que cero.');
//      if edtImporteDivisa.CanFocus then
//        edtImporteDivisa.SetFocus;
//      Exit;
//    end;
  end;
  // Validar blockchain si es cripto
  if FDatosResultado.EsCripto then
  begin
    if Trim(edtTxHash.Text) = '' then
    begin
      ShowMessage('Debe introducir el hash de la transacción blockchain.');
      if edtTxHash.CanFocus then
        edtTxHash.SetFocus;
      Exit;
    end;
  end;
  Result := True;
end;

procedure TfrmCajaReferenciaPago.btnAceptarClick(Sender: TObject);
var
  CodigoDivisa: string;
begin
  if not ValidarDatos then
    Exit;
  // Preparar datos de resultado
  FDatosResultado.Referencia := Trim(edtReferencia.Text);
  if FDatosResultado.EsDivisa then
  begin
    // Extraer código de divisa (primeros 3 caracteres)
    CodigoDivisa := Copy(txtDivisa.Text, 1, 3);
    FDatosResultado.CodigoDivisa := CodigoDivisa;
    FDatosResultado.FactorCambio := edtFactorCambio.Value;
    FDatosResultado.ImporteEuros := edtImporteDivisa.Value;
    FDatosResultado.ImporteDivisa := edtImporte.Value;
  end;
//  else
//  begin
//    FDatosResultado.CodigoDivisa := 'EUR';
//    FDatosResultado.FactorCambio := 1;
//    FDatosResultado.ImporteDivisa := edtImporte.Value;
//    FDatosResultado.ImporteEuros := edtImporte.Value;
//  end;
  if FDatosResultado.EsCripto then
  begin
    FDatosResultado.RedBlockchain := cbbRedBlockchain.Text;
    if Trim(edtTxHash.Text) <> '' then
      FDatosResultado.Referencia := Trim(edtTxHash.Text);
  end;
  ModalResult := mrOk;
end;

procedure TfrmCajaReferenciaPago.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmCajaReferenciaPago.GetCripto;
var
  Moneda: String;
  PrecioEnEuros: Double;  // 1 BTC = X EUR
begin
  Moneda := UpperCase(Copy(txtDivisa.Text, 1, 3));
  PrecioEnEuros := GetPriceBinance(Moneda + 'EUR');
  if (PrecioEnEuros > 0) then
  begin
    edtFactorCambio.Value  := 1 / PrecioEnEuros;
    edtImporteDivisa.Value := edtImporte.Value * PrecioEnEuros;
  end
  else
  begin
    //ShowMessage('No se pudo obtener el precio de ' + Moneda);
    edtFactorCambio.Value  := 0;
    edtImporteDivisa.Value := 0;
  end;
end;

procedure TfrmCajaReferenciaPago.GetDivisa;
var
  API: TFrankfurterAPI;
  Tasa: Double;
  Moneda:String;
begin
  API := TFrankfurterAPI.Create;
  try
    Moneda := Copy(txtDivisa.Text, 1, 3);
    Tasa := API.GetRate('EUR', Moneda);
    edtFactorCambio.Value := Tasa;
//    ShowMessage('1 EUR = ' + FormatFloat('0.0000', Tasa) + ' USD');
  finally
    API.Free;
  end;
end;

procedure TfrmCajaReferenciaPago.btnGetDivisaClick(Sender: TObject);
begin
  if FDatosResultado.EsCripto then
    GetCripto
  else
    if FDatosResultado.EsDivisa then
      GetDivisa;
end;

procedure TfrmCajaReferenciaPago.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: btnCancelar.Click;
    VK_F12: btnAceptar.Click;
  end;
end;

end.