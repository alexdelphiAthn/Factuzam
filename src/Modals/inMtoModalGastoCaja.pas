{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGastoCaja                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F7 del menú de caja: gastos por caja y retiradas de efectivo.       }
{    Pide empleado (con búsqueda + etiqueta nombre), destino del dinero        }
{    (caja fuerte, banco, encargado), importe y concepto.                      }
{    Crea una operación GC en fza_caja_operaciones + un pago EFE en            }
{    fza_caja_pagos para que el arqueo lo recoja como salida de efectivo.       }
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
    rgTipo: TcxRadioGroup;
    lblEmpleadoLbl: TcxLabel;
    txtEmpleado: TcxTextEdit;
    lblEmpleadoNombre: TcxLabel;
    lblDestinoLbl: TcxLabel;
    rgDestino: TcxRadioGroup;
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
  public
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const AEmpresa, AAlmacen, ACaja: string
                            ): Boolean;
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
      'SELECT NOMBRE_USU' +
      '  FROM fza_usuarios' +
      ' WHERE CODIGO_USU_USU = :pCOD';
    Q.ParamByName('pCOD').AsString := Trim(txtEmpleado.Text);
    Q.Open;
    if not Q.Eof then
      lblEmpleadoNombre.Caption :=
        Q.FieldByName('NOMBRE_USU').AsString;
  finally
    FreeAndNil(Q);
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
  if Trim(txtConcepto.Text) = '' then
  begin
    Application.MessageBox(
      'Introduzca un concepto para el gasto o retirada.',
      'Aviso', MB_OK or MB_ICONWARNING);
    txtConcepto.SetFocus;
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
  sConcepto, sDestino, sEmpleado: string;
begin
  dm := TdmCajaOpe.Create(nil);
  try
    dImporte  := Currency(txtImporte.Value);
    sEmpleado := Trim(txtEmpleado.Text);
    sConcepto := Trim(txtConcepto.Text);
    { Destino }
    case rgDestino.ItemIndex of
      0: sDestino := 'Caja fuerte';
      1: sDestino := 'Banco';
      2: sDestino := 'Encargado';
    else
      sDestino := '';
    end;
    { Prefijo según tipo }
    if rgTipo.ItemIndex = 1 then
      sConcepto := 'Retirada (' + sDestino + '): ' + sConcepto
    else
      sConcepto := sConcepto + ' [' + sDestino + ']';
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
