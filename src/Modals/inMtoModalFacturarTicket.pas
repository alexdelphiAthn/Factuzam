{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacturarTicket                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Crea una factura NORMAL en sustitución de un ticket.                      }
{******************************************************************************}
unit inMtoModalFacturarTicket;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxCalendar, cxLabel,
  cxButtons, cxButtonEdit, dxCore, cxDateUtils,
  inMtoFrmBase, dxCoreGraphics, Vcl.ComCtrls, Vcl.Menus, Vcl.StdCtrls,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization,
  inLibSerieFechaFacturaPersistenciaIntf,
  inLibFacturacionTicketPersistenciaIntf;

type
  TFacturarTicketResult = record
    Aceptado: Boolean;
    SerieNueva: string;
    NumeroNueva: string;
  end;

  TfrmModalFacturarTicket = class(TfrmBase)
    lblTicket: TcxLabel;
    edtTicket: TcxTextEdit;
    lblCliente: TcxLabel;
    btnCliente: TcxButtonEdit;
    lblSerie: TcxLabel;
    cbbSerie: TcxLookupComboBox;
    lblFecha: TcxLabel;
    dtFecha: TcxDateEdit;
    pnlButton: TPanel;
    btnGenerar: TcxButton;
    btnCancelar: TcxButton;
    dsSeries: TDataSource;
    procedure btnGenerarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnClientePropertiesButtonClick(
      Sender: TObject;
      AButtonIndex: Integer);
  private
    FResultado: TFacturarTicketResult;
    FSerieTicket: string;
    FNumeroTicket: string;
    FEmpresa: string;
    FCliente: string;
    FRepositorioSeries: IRepositorioSerieFechaFactura;
    FConsultaSeries: IConsultaSeriesFactura;
    FServicioFacturacion: IServicioFacturacionTicket;
    FSeries: TDataSet;
    procedure BuscarCliente;
    procedure ValidarClienteFacturaNormal(const ACliente: string);
    procedure CrearFacturaNormal(
      const ASerie: string;
      const ACliente: string;
      AFecha: TDateTime);
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ASerieTicket: string;
      const ANumeroTicket: string;
      const AEmpresa: string;
      const AAlmacen: string;
      AFechaTicket: TDateTime): TFacturarTicketResult;
  end;

implementation

uses
  inMtoGenSearch, inLibDocumentoFiscal, inLibMsgComun,
  inLibMsgFacturas, inLibMsgVentas;

{$R *.dfm}

class function TfrmModalFacturarTicket.Ejecutar(
  AOwner: TComponent;
  const ASerieTicket: string;
  const ANumeroTicket: string;
  const AEmpresa: string;
  const AAlmacen: string;
  AFechaTicket: TDateTime): TFacturarTicketResult;
var
  oFormulario: TfrmModalFacturarTicket;
  sSerie: string;
begin
  oFormulario := TfrmModalFacturarTicket.Create(AOwner);
  try
    oFormulario.FSerieTicket := ASerieTicket;
    oFormulario.FNumeroTicket := ANumeroTicket;
    oFormulario.FEmpresa := AEmpresa;
    oFormulario.edtTicket.Text := ASerieTicket + '\' + ANumeroTicket;
    oFormulario.FRepositorioSeries :=
      oFormulario.ContextoRepositoriosPantalla.Documentos.
        CrearRepositorioSerieFechaFactura;
    oFormulario.FConsultaSeries :=
      oFormulario.FRepositorioSeries.ConsultarSeries;
    oFormulario.FSeries := oFormulario.FConsultaSeries.DataSet;
    oFormulario.dsSeries.DataSet := oFormulario.FSeries;
    oFormulario.FServicioFacturacion :=
      oFormulario.ContextoRepositoriosPantalla.Documentos.
        CrearServicioFacturacionTicket;
    sSerie := oFormulario.FRepositorioSeries.ObtenerSerieAlmacen(
      AEmpresa,
      AAlmacen);
    if sSerie = '' then
    begin
      sSerie := oFormulario.FSeries.FieldByName('SERIE_CON').AsString;
    end;
    oFormulario.cbbSerie.EditValue := sSerie;
    if AFechaTicket > 0 then
    begin
      oFormulario.dtFecha.Date := Trunc(AFechaTicket);
    end
    else
    begin
      oFormulario.dtFecha.Date := Trunc(Now);
    end;
    oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    oFormulario.dsSeries.DataSet := nil;
    oFormulario.FSeries := nil;
    oFormulario.FServicioFacturacion := nil;
    oFormulario.FConsultaSeries := nil;
    oFormulario.FRepositorioSeries := nil;
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalFacturarTicket.btnCancelarClick(Sender: TObject);
begin
  FResultado.Aceptado := False;
  Close;
end;

procedure TfrmModalFacturarTicket.btnClientePropertiesButtonClick(
  Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarCliente;
end;

procedure TfrmModalFacturarTicket.BuscarCliente;
var
  oClientes: TDataSet;
  oConsulta: IConsultaClientesFacturacionTicket;
  oFormulario: TfrmMtoSearch;
begin
  oConsulta := FServicioFacturacion.ConsultarClientes;
  oClientes := oConsulta.DataSet;
  oFormulario := TfrmMtoSearch.Create(nil);
  try
    oFormulario.Name := 'frmMtoCliSearch';
    oFormulario.Caption := STituloBusquedaClientes;
    oFormulario.dsTablaG.DataSet := oClientes;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    if oFormulario.sFicha = 'S' then
    begin
      FCliente := oClientes.FieldByName('Código').AsString;
      btnCliente.Text := FCliente + ' - ' +
        oClientes.FieldByName('Razón Social').AsString;
    end;
  finally
    oFormulario.dsTablaG.DataSet := nil;
    FreeAndNil(oFormulario);
    oConsulta := nil;
  end;
end;

procedure TfrmModalFacturarTicket.btnGenerarClick(Sender: TObject);
var
  sCliente: string;
  sSerie: string;
begin
  sCliente := FCliente;
  sSerie := VarToStr(cbbSerie.EditValue);
  if Trim(sCliente) = '' then
  begin
    ShowMessage(SErrorClienteBorradorNoSeleccionado);
  end
  else if Trim(sSerie) = '' then
  begin
    ShowMessage(SErrorSerieBorradorNoSeleccionada);
  end
  else if dtFecha.Date <= 0 then
  begin
    ShowMessage(SErrorFechaBorradorNoIndicada);
  end
  else
  begin
    ValidarClienteFacturaNormal(sCliente);
    CrearFacturaNormal(sSerie, sCliente, dtFecha.Date);
    FResultado.Aceptado := True;
    Close;
  end;
end;

procedure TfrmModalFacturarTicket.ValidarClienteFacturaNormal(
  const ACliente: string);
var
  oCliente: TClienteFacturacionTicket;
begin
  oCliente := FServicioFacturacion.ConsultarCliente(ACliente);
  if not oCliente.Existe then
  begin
    raise Exception.Create(SErrorClienteFacturarTicketNoExiste);
  end;
  if Trim(oCliente.RazonSocial) = '' then
  begin
    raise Exception.Create(SErrorRazonSocialFacturarTicketObligatoria);
  end;
  if PaisEsEspana(oCliente.CodigoPais, oCliente.NombrePais) and
     (not DocumentoFiscalValido(oCliente.Nif)) then
  begin
    raise Exception.Create(
      SErrorDocumentoFiscalFacturarTicketNoValido +
      MensajeDocumentoFiscalInvalido(oCliente.Nif));
  end;
end;

procedure TfrmModalFacturarTicket.CrearFacturaNormal(
  const ASerie: string;
  const ACliente: string;
  AFecha: TDateTime);
var
  oSolicitud: TSolicitudFacturacionTicket;
begin
  oSolicitud := Default(TSolicitudFacturacionTicket);
  oSolicitud.SerieNueva := ASerie;
  oSolicitud.Cliente := ACliente;
  oSolicitud.Fecha := AFecha;
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.SerieTicket := FSerieTicket;
  oSolicitud.NumeroTicket := FNumeroTicket;
  oSolicitud.Usuario := IdentidadSesion.Usuario;
  FResultado.NumeroNueva :=
    FServicioFacturacion.CrearFactura(oSolicitud);
  FResultado.SerieNueva := ASerie;
end;

end.
