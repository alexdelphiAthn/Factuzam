{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalEntradaCambio                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F6 del menú de caja: entrada de cambio (efectivo que se             }
{    introduce en el cajón al inicio del turno o como refuerzo).               }
{    Crea una operación EC en fza_caja_operaciones + un pago EFE en            }
{    fza_caja_pagos para que el arqueo lo recoja como efectivo entrante.        }
{******************************************************************************}
unit inMtoModalEntradaCambio;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxMemo, Uni,
  inMtoFrmBase;

type
  TfrmModalEntradaCambio = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
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
  inLibGlobalVar, UniDataCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalEntradaCambio.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string): Boolean;
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
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalEntradaCambio.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalEntradaCambio.actAceptarExecute(Sender: TObject);
begin
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

procedure TfrmModalEntradaCambio.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalEntradaCambio.Grabar;
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
    if sConcepto = '' then
      sConcepto := 'Entrada de cambio';
    sNumOp := dm.SiguienteOpCaja(FEmpresa, FAlmacen, FCaja, oUser);
    FConn.StartTransaction;
    try
      QryTrx := TUniQuery.Create(nil);
      try
        QryTrx.Connection := FConn;
        { Operación tipo EC (Entrada de Cambio) }
        dm.InsertarOperacionCaja(
          QryTrx,
          FEmpresa, FAlmacen, FCaja,
          sNumOp,
          'EC',
          dImporte,
          oUser,
          '', '', '',
          sConcepto);
        { Pago en efectivo asociado }
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
  finally
    FreeAndNil(dm);
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalEntradaCambio);
end.
