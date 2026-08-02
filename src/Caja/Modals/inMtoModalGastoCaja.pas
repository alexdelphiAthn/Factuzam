{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGastoCaja                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       4.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F7 del menú de caja: gastos por caja y retiradas de efectivo.       }
{    Tipos: Pago proveedor, Gastos limpieza, Retirada banco, Retirada         }
{    encargado, Caja fuerte. Campo empleado con búsqueda (...).               }
{******************************************************************************}
unit inMtoModalGastoCaja;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxRadioGroup, cxButtonEdit, Uni,
  inMtoFrmBase, dxCoreGraphics, Vcl.Menus, cxMaskEdit, cxGroupBox,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization,
  inLibCajaVentaIntf, inLibGastoCajaPersistenciaIntf;

type
  TfrmModalGastoCaja = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblTipoLbl: TcxLabel;
    rgTipo: TcxRadioGroup;
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
    FRepositorioPersistencia: IRepositorioGastoCaja;
    procedure BuscarEmpleados;
    procedure ValidarEmpleado;
    procedure Grabar;
    function ObtenerTipoTexto: string;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaOperacion: TDateTime = 0): Boolean;
    class function EjecutarConImporte(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AImporte: Currency;
      AFechaOperacion: TDateTime = 0): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibGenerarTicketCaja, inMtoGenSearch, Data.DB,
  inLibMsgCaja, inLibMsgComun;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalGastoCaja.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime = 0): Boolean;
var
  frm: TfrmModalGastoCaja;
begin
  Result := False;
  frm := TfrmModalGastoCaja.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.FRepositorioConsultas :=
      frm.ContextoRepositoriosPantalla.Caja.
        CrearRepositorioConsultasCaja(AConn);
    frm.FRepositorioPersistencia :=
      frm.ContextoRepositoriosPantalla.TicketsCaja.
        CrearRepositorioGastoCaja(AConn);
    frm.btnEmpleado.Text := frm.IdentidadSesion.Usuario;
    frm.ValidarEmpleado;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

class function TfrmModalGastoCaja.EjecutarConImporte(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AImporte: Currency;
  AFechaOperacion: TDateTime = 0): Boolean;
var
  frm: TfrmModalGastoCaja;
begin
  Result := False;
  frm := TfrmModalGastoCaja.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.FRepositorioConsultas :=
      frm.ContextoRepositoriosPantalla.Caja.
        CrearRepositorioConsultasCaja(AConn);
    frm.FRepositorioPersistencia :=
      frm.ContextoRepositoriosPantalla.TicketsCaja.
        CrearRepositorioGastoCaja(AConn);
    frm.btnEmpleado.Text := frm.IdentidadSesion.Usuario;
    frm.ValidarEmpleado;
    frm.txtImporte.Value := Double(AImporte);
    frm.lblTitulo.Caption := SCaptionRetirarSobranteRecuento;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalGastoCaja.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalGastoCaja.btnEmpleadoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmModalGastoCaja.btnEmpleadoPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  ValidarEmpleado;
end;

procedure TfrmModalGastoCaja.BuscarEmpleados;
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

procedure TfrmModalGastoCaja.ValidarEmpleado;
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

function TfrmModalGastoCaja.ObtenerTipoTexto: string;
begin
  case rgTipo.ItemIndex of
    0: Result := 'Pago proveedor';
    1: Result := 'Gastos limpieza';
    2: Result := 'Retirada banco';
    3: Result := 'Retirada encargado';
    4: Result := 'Caja fuerte';
  else
    Result := '';
  end;
end;

procedure TfrmModalGastoCaja.actAceptarExecute(Sender: TObject);
begin
  if Trim(btnEmpleado.Text) = '' then
  begin
    Application.MessageBox(
      PChar(SErrorEmpleadoGastoCajaNoIndicado),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
    Exit;
  end;
  if txtImporte.Value <= 0 then
  begin
    Application.MessageBox(
      PChar(SErrorImporteGastoCajaNoValido),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    txtImporte.SetFocus;
    Exit;
  end;
  Grabar;
  ModalResult := mrOk;
end;

procedure TfrmModalGastoCaja.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalGastoCaja.Grabar;
var
  oSolicitud: TSolicitudGastoCaja;
  sNumOp: string;
  sTipo: string;
begin
  oSolicitud := Default(TSolicitudGastoCaja);
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.Almacen := FAlmacen;
  oSolicitud.Caja := FCaja;
  oSolicitud.Empleado := Trim(btnEmpleado.Text);
  oSolicitud.FechaOperacion := FFechaOperacion;
  oSolicitud.Importe := Currency(txtImporte.Value);
  sTipo := ObtenerTipoTexto;
  oSolicitud.Concepto := Trim(txtConcepto.Text);
  if oSolicitud.Concepto <> '' then
  begin
    oSolicitud.Concepto := sTipo + ': ' + oSolicitud.Concepto;
  end
  else
  begin
    oSolicitud.Concepto := sTipo;
  end;
  sNumOp := FRepositorioPersistencia.Registrar(oSolicitud);
  ImprimirTicketOperacionCaja(
    PreviewTicket,
    ConexionPrincipal,
    ContextoRepositoriosPantalla.TicketsCaja.
      CrearLecturasImpresionTicketCaja(ConexionPrincipal),
    FEmpresa,
    FAlmacen,
    FCaja,
    sNumOp,
    ParametrosCaja.ImpresoraCaja);
end;

initialization
  ForceReferenceToClass(TfrmModalGastoCaja);
end.
