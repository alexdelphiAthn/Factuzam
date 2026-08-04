{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalResolverIncidenciaVerifactu                         }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve una incidencia aceptada con errores por subsanación o R4.        }
{******************************************************************************}
unit inMtoModalResolverIncidenciaVerifactu;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ExtCtrls,
  cxButtons,
  cxCalendar,
  cxContainer,
  cxControls,
  cxEdit,
  cxGroupBox,
  cxLabel,
  cxMaskEdit,
  cxMemo,
  cxRadioGroup,
  cxTextEdit,
  inMtoFrmBase,
  inLibFacturasIncidenciaFiscalIntf;

type
  TfrmModalResolverIncidenciaVerifactu = class(TfrmBase)
    pnlBotones: TPanel;
    btnResolver: TcxButton;
    btnCancelar: TcxButton;
    grpIncidencia: TcxGroupBox;
    lblFacturaTitulo: TcxLabel;
    lblFactura: TcxLabel;
    lblErrorTitulo: TcxLabel;
    lblError: TcxLabel;
    lblClienteActualTitulo: TcxLabel;
    lblClienteActual: TcxLabel;
    grpResolucion: TcxGroupBox;
    rgResolucion: TcxRadioGroup;
    lblMotivo: TcxLabel;
    mMotivo: TcxMemo;
    grpRectificativa: TcxGroupBox;
    lblCodigoCliente: TcxLabel;
    edtCodigoCliente: TcxTextEdit;
    btnCargarCliente: TcxButton;
    lblClienteCorrecto: TcxLabel;
    lblSerieRectificativa: TcxLabel;
    edtSerieRectificativa: TcxTextEdit;
    lblFechaRectificativa: TcxLabel;
    dtFechaRectificativa: TcxDateEdit;
    procedure btnCancelarClick(Sender: TObject);
    procedure btnCargarClienteClick(Sender: TObject);
    procedure btnResolverClick(Sender: TObject);
    procedure rgResolucionPropertiesChange(Sender: TObject);
  private
    FDatos: TDatosIncidenciaFiscal;
    FResultado: TResultadoResolucionIncidenciaFiscal;
    FServicio: IServicioIncidenciaFiscalFactura;
    procedure CargarDatos(const ASerie, ANumero: string);
    procedure CargarClienteCorrecto;
    procedure ConfigurarTextos;
    procedure ActualizarModoResolucion;
    function CrearSolicitud: TSolicitudResolucionIncidenciaFiscal;
    procedure MostrarError(const AMensaje: string);
  public
    class function Ejecutar(
      AOwner: TComponent;
      const AServicio: IServicioIncidenciaFiscalFactura;
      const ASerie, ANumero: string):
      TResultadoResolucionIncidenciaFiscal;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  inLibMsgVerifactu;

{$R *.dfm}

class function TfrmModalResolverIncidenciaVerifactu.Ejecutar(
  AOwner: TComponent;
  const AServicio: IServicioIncidenciaFiscalFactura;
  const ASerie, ANumero: string): TResultadoResolucionIncidenciaFiscal;
var
  oFormulario: TfrmModalResolverIncidenciaVerifactu;
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  oFormulario := TfrmModalResolverIncidenciaVerifactu.Create(AOwner);
  try
    oFormulario.FServicio := AServicio;
    oFormulario.ConfigurarTextos;
    oFormulario.CargarDatos(ASerie, ANumero);
    oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalResolverIncidenciaVerifactu.ConfigurarTextos;
begin
  Caption := STituloResolverIncidenciaVerifactu;
  grpIncidencia.Caption := STextoIncidenciaErrorAeat;
  lblFacturaTitulo.Caption := STextoIncidenciaFactura;
  lblErrorTitulo.Caption := STextoIncidenciaErrorAeat;
  lblClienteActualTitulo.Caption := STextoIncidenciaClienteActual;
  grpResolucion.Caption := STextoIncidenciaDecision;
  rgResolucion.Properties.Items[0].Caption := STextoIncidenciaSubsanar;
  rgResolucion.Properties.Items[1].Caption := STextoIncidenciaRectificar;
  lblMotivo.Caption := STextoIncidenciaMotivo;
  grpRectificativa.Caption := STextoIncidenciaClienteCorrecto;
  btnCargarCliente.Caption := STextoIncidenciaCargarCliente;
  lblSerieRectificativa.Caption := STextoIncidenciaSerieRectificativa;
  lblFechaRectificativa.Caption := STextoIncidenciaFechaRectificativa;
  btnResolver.Caption := STextoIncidenciaResolver;
  btnCancelar.Caption := STextoIncidenciaCancelar;
end;

procedure TfrmModalResolverIncidenciaVerifactu.CargarDatos(
  const ASerie, ANumero: string);
begin
  FResultado := Default(TResultadoResolucionIncidenciaFiscal);
  FDatos := FServicio.CargarIncidencia(ASerie, ANumero);
  lblFactura.Caption := FDatos.Serie + '\' + FDatos.Numero;
  lblError.Caption := Trim(FDatos.CodigoError + ' ' +
    FDatos.DescripcionError);
  lblClienteActual.Caption := FDatos.Cliente.Codigo + ' - ' +
    FDatos.Cliente.RazonSocial + ' (' + FDatos.Cliente.Nif + ')';
  edtCodigoCliente.Text := FDatos.Cliente.Codigo;
  dtFechaRectificativa.Date := Date;
  rgResolucion.ItemIndex := 0;
  ActualizarModoResolucion;
end;

procedure TfrmModalResolverIncidenciaVerifactu.CargarClienteCorrecto;
var
  Cliente: TDatosClienteIncidenciaFiscal;
begin
  Cliente := FServicio.CargarCliente(edtCodigoCliente.Text);
  edtCodigoCliente.Text := Cliente.Codigo;
  lblClienteCorrecto.Caption := Cliente.RazonSocial + ' (' +
    Cliente.Nif + ')';
end;

procedure TfrmModalResolverIncidenciaVerifactu.ActualizarModoResolucion;
begin
  grpRectificativa.Enabled := rgResolucion.ItemIndex = 1;
end;

function TfrmModalResolverIncidenciaVerifactu.CrearSolicitud:
  TSolicitudResolucionIncidenciaFiscal;
begin
  Result := Default(TSolicitudResolucionIncidenciaFiscal);
  Result.Serie := FDatos.Serie;
  Result.Numero := FDatos.Numero;
  if rgResolucion.ItemIndex = 1 then
    Result.TipoResolucion := trifRectificarFactura
  else
    Result.TipoResolucion := trifSubsanarRegistro;
  Result.Motivo := mMotivo.Text;
  Result.CodigoClienteCorrecto := edtCodigoCliente.Text;
  Result.SerieRectificativa := edtSerieRectificativa.Text;
  Result.FechaRectificativa := dtFechaRectificativa.Date;
end;

procedure TfrmModalResolverIncidenciaVerifactu.MostrarError(
  const AMensaje: string);
begin
  MessageDlg(AMensaje, mtError, [mbOK], 0);
end;

procedure TfrmModalResolverIncidenciaVerifactu.btnCancelarClick(
  Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalResolverIncidenciaVerifactu.btnCargarClienteClick(
  Sender: TObject);
begin
  try
    CargarClienteCorrecto;
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
end;

procedure TfrmModalResolverIncidenciaVerifactu.btnResolverClick(
  Sender: TObject);
begin
  try
    if rgResolucion.ItemIndex = 1 then
      CargarClienteCorrecto;
    FResultado := FServicio.Resolver(CrearSolicitud);
    if FResultado.EsCorrecto then
      ModalResult := mrOk
    else
      MostrarError(FResultado.Mensaje);
  except
    on E: Exception do
    begin
      if Assigned(RegistroLog) then
        RegistroLog.RegistrarError(
          'Resolver incidencia VERI*FACTU: ' + E.Message);
      MostrarError(E.Message);
    end;
  end;
end;

procedure TfrmModalResolverIncidenciaVerifactu.
  rgResolucionPropertiesChange(Sender: TObject);
begin
  ActualizarModoResolucion;
end;

end.
