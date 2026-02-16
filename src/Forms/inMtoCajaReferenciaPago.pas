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
    chkUsarOtraDivisa: TCheckBox;
    lblDivisa: TcxLabel;
    cbbDivisa: TcxComboBox;
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
    
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure chkUsarOtraDivisaClick(Sender: TObject);
    procedure edtFactorCambioPropertiesChange(Sender: TObject);
    procedure edtImporteDivisaPropertiesChange(Sender: TObject);
    procedure edtImportePropertiesChange(Sender: TObject);
    procedure cbbDivisaPropertiesChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    
  private
    FFormaPagoInfo: TFormaPagoInfo;
    FImporteOriginal: Currency;
    FDatosResultado: TDatosReferencia;
    
    procedure ConfigurarInterfaz;
    procedure ActualizarCalculosDivisa;
    procedure CargarDivisasDisponibles;
    procedure CargarRedesBlockchain;
    function ValidarDatos: Boolean;
    
  public
    class function Ejecutar(const AFormaPago: TFormaPagoInfo;
                            AImporte: Currency;
                            var ADatosRef: TDatosReferencia): Boolean;
  end;

var
  frmCajaReferenciaPago: TfrmCajaReferenciaPago;

implementation

{$R *.dfm}

uses
  System.Math, Vcl.Themes;

{ TfrmCajaReferenciaPago }

class function TfrmCajaReferenciaPago.Ejecutar(
  const AFormaPago: TFormaPagoInfo; AImporte: Currency;
  var ADatosRef: TDatosReferencia): Boolean;
var
  Frm: TfrmCajaReferenciaPago;
begin
  Result := False;
  
  Frm := TfrmCajaReferenciaPago.Create(nil);
  try
    Frm.FFormaPagoInfo := AFormaPago;
    Frm.FImporteOriginal := AImporte;
    Frm.FDatosResultado.Init;
    
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
  FDatosResultado.Init;
end;

procedure TfrmCajaReferenciaPago.FormShow(Sender: TObject);
begin
  inherited;
  
  ConfigurarInterfaz;
  
  // Poner foco en referencia
  if edtReferencia.Enabled and edtReferencia.Visible then
    edtReferencia.SetFocus;
end;

procedure TfrmCajaReferenciaPago.ConfigurarInterfaz;
var
  EsTarjeta, EsCripto, EsTransferencia: Boolean;
begin
  // Mostrar información de la forma de pago
  lblFormaPagoValor.Caption := FFormaPagoInfo.Descripcion;
  edtImporte.Value := FImporteOriginal;
  edtImporte.Enabled := False; // No permitir cambiar el importe aquí
  
  // Determinar tipo de pago
//  EsTarjeta := SameText(FFormaPagoInfo.TipoComportamiento, 'TARJETA');
//  EsCripto := Pos('CRYPTO', UpperCase(FFormaPagoInfo.TipoComportamiento)) > 0;
//  EsTransferencia := SameText(FFormaPagoInfo.TipoComportamiento, 'TRANSFERENCIA');

  // Configurar grupo de referencia
  gbReferencia.Visible := FFormaPagoInfo.RequiereReferencia;
  if EsCripto then
  begin
    lblReferencia.Caption := 'TX Hash:';
    lblEjemplo.Caption := 'Ej: 0x...';
    edtReferencia.Properties.MaxLength := 100;
  end
  else
  begin
    lblReferencia.Caption := 'Referencia:';
    lblEjemplo.Caption := '';
    edtReferencia.Properties.MaxLength := 255;
  end;

  // Configurar grupo blockchain
  gbBlockchain.Visible := EsCripto;
  if EsCripto then
    CargarRedesBlockchain;

  // Configurar grupo divisa
  gbDivisa.Visible := True;
  chkUsarOtraDivisa.Checked := False;
  CargarDivisasDisponibles;

  // Inicialmente ocultar controles de divisa
  lblDivisa.Enabled := False;
  cbbDivisa.Enabled := False;
  lblFactorCambio.Enabled := False;
  edtFactorCambio.Enabled := False;
  lblImporteDivisa.Enabled := False;
  edtImporteDivisa.Enabled := False;
  lblEquivale.Enabled := False;
  
  // Ajustar altura del formulario según visibilidad
  ClientHeight := pnlPrincipal.Height + pnlBotones.Height + 20;
end;

procedure TfrmCajaReferenciaPago.CargarDivisasDisponibles;
begin
  cbbDivisa.Properties.Items.Clear;
  cbbDivisa.Properties.Items.Add('USD - Dólar Estadounidense');
  cbbDivisa.Properties.Items.Add('GBP - Libra Esterlina');
  cbbDivisa.Properties.Items.Add('CHF - Franco Suizo');
  cbbDivisa.Properties.Items.Add('JPY - Yen Japonés');
  cbbDivisa.Properties.Items.Add('BTC - Bitcoin');
  cbbDivisa.Properties.Items.Add('ETH - Ethereum');
  cbbDivisa.Properties.Items.Add('USDT - Tether');
  
  cbbDivisa.ItemIndex := 0;
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

procedure TfrmCajaReferenciaPago.chkUsarOtraDivisaClick(Sender: TObject);
var
  Activar: Boolean;
begin
  Activar := chkUsarOtraDivisa.Checked;
  
  lblDivisa.Enabled := Activar;
  cbbDivisa.Enabled := Activar;
  lblFactorCambio.Enabled := Activar;
  edtFactorCambio.Enabled := Activar;
  lblImporteDivisa.Enabled := Activar;
  edtImporteDivisa.Enabled := Activar;
  lblEquivale.Enabled := Activar;
  
  if Activar then
  begin
    // Establecer factor de cambio por defecto
    if edtFactorCambio.Value = 0 then
      edtFactorCambio.Value := 1;
      
    // Calcular importe en divisa
    ActualizarCalculosDivisa;
    
    if edtFactorCambio.CanFocus then
      edtFactorCambio.SetFocus;
  end
  else
  begin
    // Limpiar valores
    edtFactorCambio.Value := 1;
    edtImporteDivisa.Value := 0;
  end;
end;

procedure TfrmCajaReferenciaPago.edtFactorCambioPropertiesChange(Sender: TObject);
begin
  ActualizarCalculosDivisa;
end;

procedure TfrmCajaReferenciaPago.edtImporteDivisaPropertiesChange(Sender: TObject);
begin
  // Si cambia el importe en divisa, recalcular el factor
  if (edtImporteDivisa.Value > 0) and (FImporteOriginal > 0) then
  begin
    edtFactorCambio.Value := FImporteOriginal / edtImporteDivisa.Value;
  end;
end;

procedure TfrmCajaReferenciaPago.edtImportePropertiesChange(Sender: TObject);
begin
  ActualizarCalculosDivisa;
end;

procedure TfrmCajaReferenciaPago.cbbDivisaPropertiesChange(Sender: TObject);
begin
  // Aquí podrías consultar el factor de cambio actual desde una API o BD
  // Por ahora dejamos que el usuario lo introduzca manualmente
end;

procedure TfrmCajaReferenciaPago.ActualizarCalculosDivisa;
var
  Factor: Currency;
begin
  if not chkUsarOtraDivisa.Checked then
    Exit;
    
  Factor := edtFactorCambio.Value;
  
  if Factor > 0 then
  begin
    // Calcular importe en divisa extranjera
    edtImporteDivisa.Value := FImporteOriginal / Factor;
    
    // Actualizar etiqueta de equivalencia
    lblEquivale.Caption := Format('%m EUR = %n %s',
      [FImporteOriginal, 
       edtImporteDivisa.Value,
       Copy(cbbDivisa.Text, 1, 3)]);
  end;
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
  if chkUsarOtraDivisa.Checked then
  begin
    if edtFactorCambio.Value <= 0 then
    begin
      ShowMessage('El factor de cambio debe ser mayor que cero.');
      if edtFactorCambio.CanFocus then
        edtFactorCambio.SetFocus;
      Exit;
    end;
    
    if edtImporteDivisa.Value <= 0 then
    begin
      ShowMessage('El importe en divisa debe ser mayor que cero.');
      if edtImporteDivisa.CanFocus then
        edtImporteDivisa.SetFocus;
      Exit;
    end;
  end;
  
  // Validar blockchain si es cripto
  if gbBlockchain.Visible then
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
  
  if chkUsarOtraDivisa.Checked then
  begin
    // Extraer código de divisa (primeros 3 caracteres)
    CodigoDivisa := Copy(cbbDivisa.Text, 1, 3);
    
    FDatosResultado.CodigoDivisa := CodigoDivisa;
    FDatosResultado.FactorCambio := edtFactorCambio.Value;
    FDatosResultado.ImporteDivisa := edtImporteDivisa.Value;
  end
  else
  begin
    FDatosResultado.CodigoDivisa := 'EUR';
    FDatosResultado.FactorCambio := 1;
    FDatosResultado.ImporteDivisa := 0;
  end;
  
  if gbBlockchain.Visible then
  begin
    FDatosResultado.RedBlockchain := cbbRedBlockchain.Text;
    // Sobrescribir referencia con TX Hash si es cripto
    if Trim(edtTxHash.Text) <> '' then
      FDatosResultado.Referencia := Trim(edtTxHash.Text);
  end;
  
  //FDatosResultado.Observaciones := Trim(memObservaciones.Text);
  
  ModalResult := mrOk;
end;

procedure TfrmCajaReferenciaPago.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmCajaReferenciaPago.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: btnCancelar.Click;
    VK_F10: btnAceptar.Click;
  end;
end;

end.