{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalEntradaCambio                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       3.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F6 del menú de caja: entrada de cambio. Campo empleado con          }
{    búsqueda (...) igual que en operaciones de caja.                          }
{******************************************************************************}
unit inMtoModalEntradaCambio;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxButtonEdit, Uni,
  inMtoFrmBase, inLibCajaVentaIntf,
  inLibEntradaCambioPersistenciaIntf, inLibGenerarTicketIntf,
  UniDataCajaPantallaComposicion;

type
  TfrmModalEntradaCambio = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblEmpleadoLbl: TcxLabel;
    btnEmpleado: TcxButtonEdit;
    lblEmpleadoNombre: TcxLabel;
    lblImporteLbl: TcxLabel;
    txtImporte: TcxCurrencyEdit;
    lblConceptoLbl: TcxLabel;
    txtConcepto: TcxTextEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnEmpleadoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFechaOperacion: TDateTime;
    FRepositorioConsultas: IRepositorioConsultasCaja;
    FRepositorioEntrada: IRepositorioEntradaCambio;
    FLecturasImpresionTicket: ILecturasImpresionTicket;
    procedure ComponerDependencias;
    procedure BuscarEmpleados;
    procedure ValidarEmpleado;
    procedure Grabar;
  public
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const AEmpresa, AAlmacen, ACaja: string;
                            AFechaOperacion: TDateTime = 0
                            ): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibGenerarTicketCaja, inMtoGenSearch, inLibMsgComun;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalEntradaCambio.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime = 0): Boolean;
var
  frm: TfrmModalEntradaCambio;
begin
  Result := False;
  frm := TfrmModalEntradaCambio.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.ComponerDependencias;
    frm.btnEmpleado.Text := frm.IdentidadSesion.Usuario;
    frm.ValidarEmpleado;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalEntradaCambio.ComponerDependencias;
var
  oComposicion: TComposicionCajaPantalla;
begin
  oComposicion := ComponerCajaPantalla(Self);
  FRepositorioConsultas := oComposicion.Consultas.
    CrearRepositorioConsultasCaja(FConn);
  FRepositorioEntrada := oComposicion.Tickets.
    CrearRepositorioEntradaCambio(FConn);
  FLecturasImpresionTicket := oComposicion.Tickets.
    CrearLecturasImpresionTicketCaja(ConexionPrincipal);
end;

procedure TfrmModalEntradaCambio.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalEntradaCambio.btnEmpleadoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmModalEntradaCambio.btnEmpleadoPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  ValidarEmpleado;
end;

procedure TfrmModalEntradaCambio.BuscarEmpleados;
var
  formulario: TfrmMtoSearch;
  oResultado: IResultadoConsultaCaja;
begin
  oResultado := FRepositorioConsultas.ConsultarEmpleados;
  formulario := TfrmMtoSearch.Create(nil);
  try
    formulario.Caption := STituloBusquedaEmpleados;
    formulario.dsTablaG.DataSet := oResultado.DataSet;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
    begin
      btnEmpleado.Text := oResultado.DataSet.Fields[0].AsString;
      ValidarEmpleado;
    end;
  finally
    FreeAndNil(formulario);
  end;
end;

procedure TfrmModalEntradaCambio.ValidarEmpleado;
var
  oEmpleado: TEmpleadoCaja;
begin
  lblEmpleadoNombre.Caption := '';
  if Assigned(FRepositorioConsultas) and
     (Trim(btnEmpleado.Text) <> '') and
     FRepositorioConsultas.BuscarEmpleado(
       Trim(btnEmpleado.Text),
       oEmpleado) then
  begin
    lblEmpleadoNombre.Caption := oEmpleado.Nombre;
  end;
end;

procedure TfrmModalEntradaCambio.actAceptarExecute(Sender: TObject);
begin
  if Trim(btnEmpleado.Text) = '' then
  begin
    Application.MessageBox(
      PChar(SErrorEmpleadoEntradaCambioNoIndicado),
      PChar(STituloAvisoEntradaCambio), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
    Exit;
  end;
  if txtImporte.Value <= 0 then
  begin
    Application.MessageBox(
      PChar(SErrorImporteEntradaCambioNoValido),
      PChar(STituloAvisoEntradaCambio), MB_OK or MB_ICONWARNING);
    txtImporte.SetFocus;
    Exit;
  end;
  Grabar;
  ModalResult := mrOk;
end;

procedure TfrmModalEntradaCambio.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalEntradaCambio.Grabar;
var
  oSolicitud: TSolicitudEntradaCambio;
  sNumOp: string;
  sConcepto, sEmpleado: string;
begin
  sEmpleado := Trim(btnEmpleado.Text);
  sConcepto := Trim(txtConcepto.Text);
  if sConcepto = '' then
  begin
    sConcepto := 'Entrada de cambio';
  end;
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.Almacen := FAlmacen;
  oSolicitud.Caja := FCaja;
  oSolicitud.Empleado := sEmpleado;
  oSolicitud.Concepto := sConcepto;
  oSolicitud.FechaOperacion := FFechaOperacion;
  oSolicitud.Importe := Currency(txtImporte.Value);
  sNumOp := FRepositorioEntrada.Registrar(oSolicitud);
  ImprimirTicketOperacionCaja(
    PreviewTicket,
    ConexionPrincipal,
    FLecturasImpresionTicket,
    FEmpresa,
    FAlmacen,
    FCaja,
    sNumOp,
    ParametrosCaja.ImpresoraCaja);
end;

initialization
  ForceReferenceToClass(TfrmModalEntradaCambio);
end.
