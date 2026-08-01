{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalDevolucionTicket                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Localiza el ticket de origen de una devolución (F4 en caja): por          }
{    código de barras EAN-13 (prefijo 29), por EMPRESA/ALMACÉN/CAJA/Nº de      }
{    operación o por SERIE/Nº de documento.                                    }
{******************************************************************************}
unit inMtoModalDevolucionTicket;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxGroupBox, cxButtons,
  inMtoFrmBase, inLibCajaVentaIntf, dxCoreGraphics, Vcl.Menus,
  cxClasses, cxLocalization, JvComponentBase, JvEnterTab;

type
  TTicketDevolucionSeleccionado = record
    Encontrado: Boolean;
    Serie: string;
    Numero: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
  end;
  TfrmModalDevolucionTicket = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    gbCodigo: TcxGroupBox;
    txtCodigoBarras: TcxTextEdit;
    gbOperacion: TcxGroupBox;
    lblEmpresaLbl: TcxLabel;
    txtEmpresa: TcxTextEdit;
    lblAlmacenLbl: TcxLabel;
    txtAlmacen: TcxTextEdit;
    lblCajaLbl: TcxLabel;
    txtCaja: TcxTextEdit;
    lblOperacionLbl: TcxLabel;
    txtOperacion: TcxTextEdit;
    btnBuscarOperacion: TcxButton;
    gbDocumento: TcxGroupBox;
    lblSerieLbl: TcxLabel;
    txtSerie: TcxTextEdit;
    lblNumeroLbl: TcxLabel;
    txtNumero: TcxTextEdit;
    btnBuscarDocumento: TcxButton;
    lblResultado: TcxLabel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure txtCodigoBarrasKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnBuscarOperacionClick(Sender: TObject);
    procedure btnBuscarDocumentoClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    FRepositorio: IRepositorioConsultasCaja;
    FSeleccion: TTicketDevolucionSeleccionado;
    procedure LimpiarSeleccion;
    procedure MostrarResultado(ADataSet: TDataSet);
    procedure AvisarNoEncontrado;
    procedure BuscarPorCodigoBarras;
    procedure BuscarPorOperacion;
    procedure BuscarPorDocumento;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioConsultasCaja;
      const AEmpresaDefecto, AAlmacenDefecto, ACajaDefecto: string;
      out ASeleccion: TTicketDevolucionSeleccionado): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalDevolucionTicket.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioConsultasCaja;
  const AEmpresaDefecto, AAlmacenDefecto, ACajaDefecto: string;
  out ASeleccion: TTicketDevolucionSeleccionado): Boolean;
var
  frm: TfrmModalDevolucionTicket;
begin
  Result := False;
  ASeleccion := Default(TTicketDevolucionSeleccionado);
  frm := TfrmModalDevolucionTicket.Create(AOwner);
  try
    frm.FRepositorio := ARepositorio;
    frm.txtEmpresa.Text := AEmpresaDefecto;
    frm.txtAlmacen.Text := AAlmacenDefecto;
    frm.txtCaja.Text := ACajaDefecto;
    if frm.ShowModal = mrOk then
    begin
      ASeleccion := frm.FSeleccion;
      Result := ASeleccion.Encontrado;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalDevolucionTicket.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
  LimpiarSeleccion;
end;

procedure TfrmModalDevolucionTicket.FormShow(Sender: TObject);
begin
  // El lector escribe el código y envía CR: foco directo al escaneo
  if txtCodigoBarras.CanFocus then
    txtCodigoBarras.SetFocus;
end;

procedure TfrmModalDevolucionTicket.LimpiarSeleccion;
begin
  FSeleccion := Default(TTicketDevolucionSeleccionado);
  lblResultado.Caption := '';
  actAceptar.Enabled := False;
end;

procedure TfrmModalDevolucionTicket.AvisarNoEncontrado;
begin
  LimpiarSeleccion;
  Application.MessageBox(
    PChar(SErrorTicketDevolucionCajaNoEncontrado),
    PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.MostrarResultado(
  ADataSet: TDataSet);
begin
  if (ADataSet = nil) or ADataSet.IsEmpty then
    AvisarNoEncontrado
  else if SameText(
    Trim(ADataSet.FieldByName('TIPO_FAC').AsString),
    'RECTIFICATIVA') then
  begin
    LimpiarSeleccion;
    Application.MessageBox(
      PChar(SErrorTicketDevolucionCajaEsRectificativa),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
  end
  else
  begin
    FSeleccion.Encontrado := True;
    FSeleccion.Serie :=
      ADataSet.FieldByName('SERIE_FAC').AsString;
    FSeleccion.Numero :=
      ADataSet.FieldByName('NUMERO_FAC').AsString;
    FSeleccion.Empresa :=
      ADataSet.FieldByName('CODIGO_EMP_FAC').AsString;
    FSeleccion.Almacen :=
      ADataSet.FieldByName('CODIGO_ALM_FAC').AsString;
    FSeleccion.Caja :=
      ADataSet.FieldByName('CODIGO_CAJA_FAC').AsString;
    FSeleccion.NumeroOperacion :=
      ADataSet.FieldByName('NUMERO_OPERACION_FAC').AsString;
    lblResultado.Caption := Format(
      SInfoTicketDevolucionCajaLocalizado,
      [FSeleccion.Serie,
       FSeleccion.Numero,
       FormatDateTime(
         'dd/mm/yyyy hh:nn',
         ADataSet.FieldByName('INSTANTE_ALTA').AsDateTime),
       FSeleccion.Almacen,
       FormatFloat(
         '#,##0.00',
         ADataSet.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency)]);
    actAceptar.Enabled := True;
  end;
end;

procedure TfrmModalDevolucionTicket.BuscarPorCodigoBarras;
var
  oConsulta: IResultadoConsultaCaja;
begin
  if Trim(txtCodigoBarras.Text) <> '' then
  begin
    oConsulta := FRepositorio.ConsultarFacturaPorCodigoBarras(
      Trim(txtCodigoBarras.Text));
    MostrarResultado(oConsulta.DataSet);
  end;
end;

procedure TfrmModalDevolucionTicket.BuscarPorOperacion;
var
  oConsulta: IResultadoConsultaCaja;
begin
  if (Trim(txtEmpresa.Text) <> '') and
     (Trim(txtAlmacen.Text) <> '') and
     (Trim(txtCaja.Text) <> '') and
     (Trim(txtOperacion.Text) <> '') then
  begin
    oConsulta := FRepositorio.ConsultarFacturaPorOperacion(
      Trim(txtEmpresa.Text),
      Trim(txtAlmacen.Text),
      Trim(txtCaja.Text),
      Trim(txtOperacion.Text));
    MostrarResultado(oConsulta.DataSet);
  end
  else
    Application.MessageBox(
      PChar(SErrorTicketDevolucionCajaDatosOperacion),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.BuscarPorDocumento;
var
  oConsulta: IResultadoConsultaCaja;
begin
  if (Trim(txtSerie.Text) <> '') and
     (Trim(txtNumero.Text) <> '') then
  begin
    oConsulta := FRepositorio.ConsultarCabeceraFactura(
      Trim(txtSerie.Text),
      Trim(txtNumero.Text));
    MostrarResultado(oConsulta.DataSet);
  end
  else
    Application.MessageBox(
      PChar(SErrorTicketDevolucionCajaDatosDocumento),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.txtCodigoBarrasKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // El lector remata la trama con CR
  if Key = VK_RETURN then
  begin
    Key := 0;
    BuscarPorCodigoBarras;
  end;
end;

procedure TfrmModalDevolucionTicket.btnBuscarOperacionClick(
  Sender: TObject);
begin
  BuscarPorOperacion;
end;

procedure TfrmModalDevolucionTicket.btnBuscarDocumentoClick(
  Sender: TObject);
begin
  BuscarPorDocumento;
end;

procedure TfrmModalDevolucionTicket.actAceptarExecute(Sender: TObject);
begin
  if FSeleccion.Encontrado then
    ModalResult := mrOk
  else
    Application.MessageBox(
      PChar(SErrorTicketDevolucionCajaSinSeleccion),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
end;

procedure TfrmModalDevolucionTicket.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalDevolucionTicket);
end.
