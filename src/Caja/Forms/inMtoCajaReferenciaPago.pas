{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaReferenciaPago                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Captura de referencia de pago y datos de divisa.                          }
{    Usado para tarjeta, transferencia, criptomonedas y similares.             }
{******************************************************************************}
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
    edtImporteDivisa: TcxCurrencyEdit;
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
    edtImporteEuros: TcxCurrencyEdit;
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
    FImporteOriginal: Double;
    FDatosResultado: TDatosReferencia;
    FRellenarDesdeEuros: Boolean;  // True cuando viene de F3
    FPendienteEuros: Currency;     // Importe en euros a cubrir
//    FActualizandoCotizacion : boolean;
    procedure ConfigurarInterfaz;
    procedure ActualizarCalculosDivisa;
    procedure ActualizarEtiquetasYResultado;
    procedure CargarDivisasDisponibles;
    procedure CargarRedesBlockchain;
    function ValidarDatos: Boolean;
    procedure GetDivisa;
    procedure GetCripto;
  public
    class function Ejecutar( const AFormaPago: TFormaPagoInfo;
                             AImporte: Double;
                             var ADatosRef: TDatosReferencia;
                             ARellenarDesdeEuros: Boolean = False): Boolean;
  end;
implementation

{$R *.dfm}

uses
  System.Math, Vcl.Themes, inLibDivCurr, inLibCriptoCurr,
  inLibMsgCaja;

{ TfrmCajaReferenciaPago }

class function TfrmCajaReferenciaPago.Ejecutar(
  const AFormaPago: TFormaPagoInfo;
  AImporte: Double;
  var ADatosRef: TDatosReferencia;
  ARellenarDesdeEuros: Boolean = False): Boolean;
var
  Frm: TfrmCajaReferenciaPago;
begin
  Result := False;
  Frm := TfrmCajaReferenciaPago.Create(nil);
  try
    Frm.FFormaPagoInfo       := AFormaPago;
    Frm.FDatosResultado      := ADatosRef;
    Frm.FRellenarDesdeEuros  := ARellenarDesdeEuros;
    Frm.FPendienteEuros      := AImporte;
    if ARellenarDesdeEuros then
      Frm.FImporteOriginal := 0
    else
      Frm.FImporteOriginal     := AImporte;
    if Frm.ShowModal = mrOk then
    begin
      ADatosRef := Frm.FDatosResultado;
      Result := True;
    end;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmCajaReferenciaPago.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
end;

procedure TfrmCajaReferenciaPago.FormShow(Sender: TObject);
begin
  inherited;
  ConfigurarInterfaz;
  if FRellenarDesdeEuros then
    btnGetDivisaClick(Self);
end;

procedure TfrmCajaReferenciaPago.ConfigurarInterfaz;
//var
//  EsTarjeta, EsCripto, EsTransferencia: Boolean;
begin
  lblFormaPagoValor.Caption := FFormaPagoInfo.Descripcion;
  txtDivisa.Text := FFormaPagoInfo.Codigo + ' - ' + FFormaPagoInfo.Descripcion;
  gbReferencia.Visible := FFormaPagoInfo.RequiereReferencia;
  if not FRellenarDesdeEuros then
    edtImporteDivisa.Value := FImporteOriginal;
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

procedure TfrmCajaReferenciaPago.edtFactorCambioPropertiesChange(
  Sender: TObject);
begin
//  if FActualizandoCotizacion then Exit;
    ActualizarCalculosDivisa;
end;

procedure TfrmCajaReferenciaPago.edtImporteDivisaPropertiesChange(
  Sender: TObject);
begin
  // TODO: recalcular el factor cuando cambia el importe en divisa
end;

procedure TfrmCajaReferenciaPago.edtImportePropertiesChange(Sender: TObject);
begin
  ActualizarCalculosDivisa;
end;

procedure TfrmCajaReferenciaPago.ActualizarCalculosDivisa;
begin
  if edtFactorCambio.Value > 0 then
  begin
      edtImporteDivisa.Value := FPendienteEuros * edtFactorCambio.Value;
  end;
  ActualizarEtiquetasYResultado;
end;

// Solo actualiza etiquetas y FDatosResultado (sin tocar edtImporteDivisa)
procedure TfrmCajaReferenciaPago.ActualizarEtiquetasYResultado;
var
  sDivisa: string;
begin
  sDivisa := Copy(txtDivisa.Text, 1, 3);
  if edtFactorCambio.Value > 0 then
  begin
    lblEquivale.Caption  := Format('1 EUR = %.9n %s',
                                   [edtFactorCambio.Value, sDivisa]);
    lblEquivale2.Caption := Format('1 %s = %.2n EUR',
                                [sDivisa, 1 / edtFactorCambio.Value]);
  end;
  FDatosResultado.FactorCambio  := edtFactorCambio.Value;
  FDatosResultado.ImporteEuros  := FPendienteEuros;
  if FRellenarDesdeEuros then
    edtImporteDivisa.Value := edtFactorCambio.Value * FPendienteEuros;
  FDatosResultado.ImporteDivisa := edtImporteDivisa.Value;
  edtImporteEuros.Value := edtImporteDivisa.Value * (1/edtFactorCambio.Value);
end;

function TfrmCajaReferenciaPago.ValidarDatos: Boolean;
begin
  Result := False;
  // Validar referencia si es requerida
  if FFormaPagoInfo.RequiereReferencia and
     (Trim(edtReferencia.Text) = '') and
     gbReferencia.Visible then
  begin
    ShowMessage(SErrorReferenciaPagoCajaNoIndicada);
    if edtReferencia.CanFocus then
      edtReferencia.SetFocus;
    Exit;
  end;
  // Validar divisa si está activada
  if FDatosResultado.EsDivisa then
  begin
    if edtFactorCambio.Value <= 0 then
    begin
      ShowMessage(SErrorFactorCambioCajaNoValido);
      if edtFactorCambio.CanFocus then
        edtFactorCambio.SetFocus;
      Exit;
    end;
  end;
  // Validar blockchain si es cripto
  if FDatosResultado.EsCripto then
  begin
    if Trim(edtTxHash.Text) = '' then
    begin
      ShowMessage(SErrorHashBlockchainCajaNoIndicado);
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
  if not ValidarDatos then Exit;
  FDatosResultado.Referencia := Trim(edtReferencia.Text);
  if FDatosResultado.EsDivisa then
  begin
    CodigoDivisa := Copy(txtDivisa.Text, 1, 3);
    FDatosResultado.CodigoDivisa  := CodigoDivisa;
    FDatosResultado.FactorCambio  := edtFactorCambio.Value;
    FDatosResultado.ImporteDivisa := edtImporteDivisa.Value;
    FDatosResultado.ImporteEuros  := edtImporteEuros.Value;
  end;
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
  PrecioEnEuros: Double;
  FactorCalculado: Double;
  ImporteCalculado: Double;
begin
  Moneda := UpperCase(Copy(txtDivisa.Text, 1, 3));
  PrecioEnEuros := GetPriceBinance(Moneda + 'EUR');
  if PrecioEnEuros <= 0 then
    Exit;
  FactorCalculado  := 1 / PrecioEnEuros;
  ImporteCalculado := FPendienteEuros / PrecioEnEuros;
  edtFactorCambio.Value  := FactorCalculado;
  if FRellenarDesdeEuros then
    edtImporteDivisa.Value := ImporteCalculado;
  edtImporteEuros.Value := edtImporteDivisa.Value * (1/FactorCalculado);
  var sDivisa := Copy(txtDivisa.Text, 1, 3);
  lblEquivale.Caption  := Format('1 EUR = %.9n %s', [FactorCalculado, sDivisa]);
  lblEquivale2.Caption := Format('1 %s = %.2n EUR',
                                 [sDivisa, 1 / FactorCalculado]);
  FDatosResultado.FactorCambio  := FactorCalculado;
  FDatosResultado.ImporteDivisa := edtImporteDivisa.Value;
  FDatosResultado.ImporteEuros  := FPendienteEuros;
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
    FreeAndNil(API);
  end;
end;

procedure TfrmCajaReferenciaPago.btnGetDivisaClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    if FDatosResultado.EsCripto then
      GetCripto
    else
      if FDatosResultado.EsDivisa then
        GetDivisa;
  finally
    Screen.Cursor := crDefault;
  end;
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
