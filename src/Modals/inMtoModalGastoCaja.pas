{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGastoCaja                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F7 del menú de caja: gastos por caja y retiradas de efectivo.       }
{    Crea una operación GC en fza_caja_operaciones + un pago EFE en            }
{    fza_caja_pagos para que el arqueo lo recoja como salida de efectivo.       }
{    El importe se graba positivo; el arqueo lo resta del efectivo en caja.    }
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
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
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

procedure TfrmModalGastoCaja.actAceptarExecute(Sender: TObject);
begin
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
  sConcepto: string;
begin
  dm := TdmCajaOpe.Create(nil);
  try
    dImporte  := Currency(txtImporte.Value);
    sConcepto := Trim(txtConcepto.Text);
    { Prefijo según tipo seleccionado }
    if rgTipo.ItemIndex = 1 then
      sConcepto := 'Retirada: ' + sConcepto;
    sNumOp := dm.SiguienteOpCaja(FEmpresa, FAlmacen, FCaja, oUser);
    FConn.StartTransaction;
    try
      QryTrx := TUniQuery.Create(nil);
      try
        QryTrx.Connection := FConn;
        { Operación tipo GC (Gasto de Caja) — importe positivo,
          el arqueo lo resta del efectivo en caja. }
        dm.InsertarOperacionCaja(
          QryTrx,
          FEmpresa, FAlmacen, FCaja,
          sNumOp,
          'GC',
          dImporte,
          oUser,
          '', '', '',
          sConcepto);
        { Pago en efectivo asociado (salida de caja) }
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
    { Ticket de confirmación }
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
