{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGastoCaja                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       3.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F7 del menú de caja: gastos por caja y retiradas de efectivo.       }
{    Tipos: Pago proveedor, Gastos limpieza, Retirada banco, Retirada         }
{    encargado, Caja fuerte. Se puede abrir prerrellenado desde el             }
{    recuento con el sobrante.                                                 }
{******************************************************************************}
unit inMtoModalGastoCaja;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxRadioGroup, Uni,
  inMtoFrmBase;

type
  TfrmModalGastoCaja = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblTipoLbl: TcxLabel;
    rgTipo: TcxRadioGroup;
    lblEmpleadoLbl: TcxLabel;
    txtEmpleado: TcxTextEdit;
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
    procedure txtEmpleadoPropertiesChange(Sender: TObject);
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    procedure BuscarNombreEmpleado;
    procedure Grabar;
    function ObtenerTipoTexto: string;
  public
    { Llamada normal desde F7 }
    class function Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string): Boolean;
    { Llamada desde el recuento con importe prerrellenado }
    class function EjecutarConImporte(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AImporte: Currency): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibGlobalVar, UniDataCaja, inLibGenerarTicketCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalGastoCaja.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string): Boolean;
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
    frm.txtEmpleado.Text := oUser;
    frm.BuscarNombreEmpleado;
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
  AImporte: Currency): Boolean;
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
    frm.txtEmpleado.Text := oUser;
    frm.BuscarNombreEmpleado;
    frm.txtImporte.Value := Double(AImporte);
    frm.lblTitulo.Caption :=
      'Retirar sobrante del recuento';
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

procedure TfrmModalGastoCaja.txtEmpleadoPropertiesChange(
  Sender: TObject);
begin
  BuscarNombreEmpleado;
end;

procedure TfrmModalGastoCaja.BuscarNombreEmpleado;
var
  Q: TUniQuery;
begin
  lblEmpleadoNombre.Caption := '';
  if (FConn = nil) or (Trim(txtEmpleado.Text) = '') then
    Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT DIMINUTIVO_TICKET_USU' +
      '  FROM fza_usuarios' +
      ' WHERE USUARIO_USU = :pCOD';
    Q.ParamByName('pCOD').AsString := Trim(txtEmpleado.Text);
    Q.Open;
    if not Q.Eof then
      lblEmpleadoNombre.Caption :=
        Q.FieldByName('DIMINUTIVO_TICKET_USU').AsString;
  finally
    FreeAndNil(Q);
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
  if Trim(txtEmpleado.Text) = '' then
  begin
    Application.MessageBox(
      'Introduzca el empleado que realiza la operación.',
      'Aviso', MB_OK or MB_ICONWARNING);
    txtEmpleado.SetFocus;
    Exit;
  end;
  if txtImporte.Value <= 0 then
  begin
    Application.MessageBox(
      'Introduzca un importe mayor que cero.',
      'Aviso', MB_OK or MB_ICONWARNING);
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
  dm: TdmCajaOpe;
  sNumOp: string;
  QryTrx: TUniQuery;
  dImporte: Currency;
  sConcepto, sTipo, sEmpleado: string;
begin
  dm := TdmCajaOpe.Create(nil);
  try
    dImporte  := Currency(txtImporte.Value);
    sEmpleado := Trim(txtEmpleado.Text);
    sTipo     := ObtenerTipoTexto;
    sConcepto := Trim(txtConcepto.Text);
    if sConcepto <> '' then
      sConcepto := sTipo + ': ' + sConcepto
    else
      sConcepto := sTipo;
    sNumOp := dm.SiguienteOpCaja(
      FEmpresa, FAlmacen, FCaja, sEmpleado);
    FConn.StartTransaction;
    try
      QryTrx := TUniQuery.Create(nil);
      try
        QryTrx.Connection := FConn;
        dm.InsertarOperacionCaja(
          QryTrx,
          FEmpresa, FAlmacen, FCaja,
          sNumOp,
          'GC',
          dImporte,
          sEmpleado,
          '', '', '',
          sConcepto);
        dm.InsertarPagoCaja(
          QryTrx,
          FEmpresa, FAlmacen, FCaja,
          '',
          sNumOp,
          1,
          'EFE',
          dImporte,
          0);
      finally
        FreeAndNil(QryTrx);
      end;
      FConn.Commit;
    except
      FConn.Rollback;
      raise;
    end;
    ImprimirTicketOperacionCaja(
      FEmpresa, FAlmacen, FCaja, sNumOp,
      oNomImpresoraCaja);
  finally
    FreeAndNil(dm);
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalGastoCaja);
end.
