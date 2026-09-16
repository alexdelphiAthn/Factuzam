{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImporteSubsanacion                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Solicita un descuento global para las líneas existentes de Caja.     }
{******************************************************************************}
unit inMtoModalImporteSubsanacion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit,
  cxCurrencyEdit, cxButtons, cxLabel,
  inMtoFrmBase;

type
  TfrmModalImporteSubsanacion = class(TfrmBase)
    lblTotalActual: TcxLabel;
    lblExplicacion: TcxLabel;
    lblTotalCorregido: TcxLabel;
    edtTotalCorregido: TcxCurrencyEdit;
    btnAplicar: TcxButton;
    btnCancelar: TcxButton;
    procedure btnAplicarClick(Sender: TObject);
  private
    FTotalNuevo: Currency;
    FTotalActual: Currency;
    procedure Preparar(ATotalActual: Currency);
  protected
    procedure DoShow; override;
  public
    class function Ejecutar(AOwner: TComponent;
      ATotalActual: Currency; out ATotalNuevo: Currency): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils, inLibMsgSubsanacionCaja;

class function TfrmModalImporteSubsanacion.Ejecutar(
  AOwner: TComponent; ATotalActual: Currency;
  out ATotalNuevo: Currency): Boolean;
var
  oFormulario: TfrmModalImporteSubsanacion;
begin
  ATotalNuevo := ATotalActual;
  oFormulario := TfrmModalImporteSubsanacion.Create(AOwner);
  try
    oFormulario.Preparar(ATotalActual);
    Result := oFormulario.ShowModal = mrOk;
    if Result then
      ATotalNuevo := oFormulario.FTotalNuevo;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalImporteSubsanacion.Preparar(ATotalActual: Currency);
begin
  Self.Caption := SSubsanacionTitulo;
  lblTotalActual.Caption := Format(SSubsanacionTotalActual,
    [CurrToStrF(ATotalActual, ffCurrency, 2)]);
  lblExplicacion.Caption := SSubsanacionExplicacion;
  lblTotalCorregido.Caption := SSubsanacionTotalCorregido;
  btnAplicar.Caption := SSubsanacionAplicar;
  btnCancelar.Caption := SSubsanacionCancelar;
  FTotalActual := ATotalActual;
  FTotalNuevo := ATotalActual;
  edtTotalCorregido.EditValue := 0;
end;

procedure TfrmModalImporteSubsanacion.DoShow;
begin
  inherited;
  edtTotalCorregido.SetFocus;
  edtTotalCorregido.SelectAll;
end;

procedure TfrmModalImporteSubsanacion.btnAplicarClick(Sender: TObject);
begin
  edtTotalCorregido.ValidateEdit(True);
  edtTotalCorregido.PostEditValue;
  if (edtTotalCorregido.Value < 0) or
     (edtTotalCorregido.Value > FTotalActual) or (FTotalActual <= 0) then
    raise EcxEditValidationError.Create(SSubsanacionDescuentoInvalido);
  FTotalNuevo := FTotalActual - Currency(edtTotalCorregido.Value);
  Self.ModalResult := mrOk;
end;

end.
