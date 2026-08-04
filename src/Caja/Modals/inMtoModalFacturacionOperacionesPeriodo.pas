{******************************************************************************}
{  Módulo: inMtoModalFacturacionOperacionesPeriodo                            }
{  Tipo: Formulario modal                                                     }
{  Descripción: Selección y ejecución de la facturación TPV por periodo.      }
{******************************************************************************}
unit inMtoModalFacturacionOperacionesPeriodo;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCalendar, cxLabel, cxButtons, cxCheckBox, cxMemo,
  inMtoFrmBase, inLibFacturacionOperacionesPeriodoIntf;

type
  TfrmModalFacturacionOperacionesPeriodo = class(TfrmBase)
    lblContexto: TcxLabel;
    edtContexto: TcxTextEdit;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblFechaDocumento: TcxLabel;
    dteFechaDocumento: TcxDateEdit;
    chkVentasContado: TcxCheckBox;
    chkTraspasosEmpresas: TcxCheckBox;
    lblSerieFiscal: TcxLabel;
    edtSerieFiscal: TcxTextEdit;
    memResultado: TcxMemo;
    pnlBotones: TPanel;
    btnProcesar: TcxButton;
    btnInforme: TcxButton;
    btnCerrar: TcxButton;
    procedure btnCerrarClick(Sender: TObject);
    procedure btnInformeClick(Sender: TObject);
    procedure btnProcesarClick(Sender: TObject);
    procedure chkTraspasosEmpresasClick(Sender: TObject);
  private
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FInicializado: Boolean;
    FServicio: IServicioFacturacionOperacionesPeriodo;
    procedure ComponerDependencias;
    procedure Inicializar;
    procedure ActualizarSerieFiscal;
    function ConstruirSolicitud:
      TSolicitudFacturacionOperacionesPeriodo;
    procedure MostrarResultado(
      const AResultado: TResultadoFacturacionOperacionesPeriodo);
  protected
    procedure DoShow; override;
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      const AEmpresa, AAlmacen, ACaja: string);
  end;

implementation

uses
  System.SysUtils, Vcl.Dialogs,
  inLibMsgFacturacionOperacionesPeriodo,
  UniDataCajaPantallaComposicion,
  UniDataFacturacionOperacionesPeriodoRepositorio,
  inMtoModalImpFacturacionOperacionesPeriodo;

{$R *.dfm}

class procedure TfrmModalFacturacionOperacionesPeriodo.Ejecutar(
  AOwner: TComponent;
  const AEmpresa, AAlmacen, ACaja: string);
var
  oFormulario: TfrmModalFacturacionOperacionesPeriodo;
begin
  oFormulario := TfrmModalFacturacionOperacionesPeriodo.Create(AOwner);
  try
    oFormulario.FEmpresa := AEmpresa;
    oFormulario.FAlmacen := AAlmacen;
    oFormulario.FCaja := ACaja;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.DoShow;
begin
  inherited;
  ComponerDependencias;
  Inicializar;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.ComponerDependencias;
var
  oComposicion: TComposicionCajaPantalla;
begin
  if not Assigned(FServicio) then
  begin
    oComposicion := ComponerCajaPantalla(Self);
    FServicio := CrearServicioFacturacionOperacionesPeriodoUniDAC(
      ConexionPrincipal,
      ParametrosApp,
      oComposicion.Consultas.CrearServicioEmisionFiscal);
  end;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.Inicializar;
begin
  if not FInicializado then
  begin
    Caption := STituloFacturacionOperacionesPeriodo;
    edtContexto.Text := FEmpresa + ' / ' + FAlmacen + ' / ' + FCaja;
    dteDesde.Date := Date;
    dteHasta.Date := Date;
    dteFechaDocumento.Date := Date;
    chkVentasContado.Checked := True;
    chkTraspasosEmpresas.Checked := True;
    ActualizarSerieFiscal;
    FInicializado := True;
  end;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.ActualizarSerieFiscal;
begin
  edtSerieFiscal.Enabled := chkTraspasosEmpresas.Checked;
  lblSerieFiscal.Enabled := chkTraspasosEmpresas.Checked;
  if chkTraspasosEmpresas.Checked and
     (Trim(edtSerieFiscal.Text) = '') then
  begin
    edtSerieFiscal.Text := FServicio.ObtenerSerieFiscalDefecto(
      FEmpresa,
      dteFechaDocumento.Date);
  end;
end;

function TfrmModalFacturacionOperacionesPeriodo.ConstruirSolicitud:
  TSolicitudFacturacionOperacionesPeriodo;
begin
  Result := Default(TSolicitudFacturacionOperacionesPeriodo);
  Result.Empresa := FEmpresa;
  Result.Almacen := FAlmacen;
  Result.Caja := FCaja;
  Result.FechaDesde := Trunc(dteDesde.Date);
  Result.FechaHasta := Trunc(dteHasta.Date);
  Result.FechaDocumento := Trunc(dteFechaDocumento.Date);
  Result.SerieFiscal := Trim(edtSerieFiscal.Text);
  Result.Usuario := IdentidadSesion.Usuario;
  Result.IncluirVentasContado := chkVentasContado.Checked;
  Result.IncluirTraspasosEmpresas := chkTraspasosEmpresas.Checked;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.MostrarResultado(
  const AResultado: TResultadoFacturacionOperacionesPeriodo);
begin
  memResultado.Text := Format(
    SInfoResultadoFacturacionPeriodo,
    [AResultado.DocumentosInternos,
     AResultado.FacturasFiscales,
     AResultado.Ajustes,
     AResultado.OperacionesProcesadas]);
end;

procedure TfrmModalFacturacionOperacionesPeriodo.btnProcesarClick(
  Sender: TObject);
var
  iPendientes: Integer;
  oResultado: TResultadoFacturacionOperacionesPeriodo;
  oSolicitud: TSolicitudFacturacionOperacionesPeriodo;
begin
  oSolicitud := ConstruirSolicitud;
  iPendientes := FServicio.ContarOperacionesPendientes(oSolicitud);
  if iPendientes = 0 then
  begin
    memResultado.Text := SInfoSinOperacionesFacturacionPeriodo;
  end
  else if MessageDlg(
            Format(SPreguntaProcesarFacturacionPeriodo, [iPendientes]),
            mtConfirmation,
            [mbYes, mbNo],
            0) = mrYes then
  begin
    oResultado := FServicio.Procesar(oSolicitud);
    MostrarResultado(oResultado);
  end;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.btnInformeClick(
  Sender: TObject);
begin
  TfrmPrintFacturacionOperacionesPeriodo.Ejecutar(
    Self,
    FEmpresa,
    FAlmacen,
    FCaja,
    dteDesde.Date,
    dteHasta.Date);
end;

procedure TfrmModalFacturacionOperacionesPeriodo.btnCerrarClick(
  Sender: TObject);
begin
  Close;
end;

procedure TfrmModalFacturacionOperacionesPeriodo.
  chkTraspasosEmpresasClick(Sender: TObject);
begin
  ActualizarSerieFiscal;
end;

end.
