{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalTiraCaja                                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pregunta las opciones de la "tira de caja" antes de imprimirla: la serie  }
{    (cuando hay más de una; por defecto todas) y si se imprime el QR          }
{    tributario por operación (solo cuando Verifactu está activo con envío     }
{    PRE o PRO). Además ofrece incluir, de forma opcional, bloques aparte de   }
{    las ventas facturadas: traspasos salientes (origen), ingresos por caja,   }
{    gastos por caja y ventas a crédito (depósitos). Devuelve la elección a    }
{    través de Ejecutar.                                                        }
{******************************************************************************}
unit inMtoModalTiraCaja;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCheckBox, cxLabel, cxButtons, cxClasses, cxStyles,
  inMtoFrmBase;

type
  TfrmModalTiraCaja = class(TfrmBase)
    lblTitulo: TcxLabel;
    lblSerie: TcxLabel;
    cbSerie: TcxComboBox;
    chkQR: TcxCheckBox;
    chkTraspasos: TcxCheckBox;
    chkIngresos: TcxCheckBox;
    chkGastos: TcxCheckBox;
    chkCredito: TcxCheckBox;
    btnImprimir: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
  private
    FVerifactu: Boolean;
  public
    // Devuelve True si el usuario pulsa Imprimir. ASerie = '' significa todas
    // las series. AImprimirQR solo puede salir True si AVerifactu lo era.
    // Los cuatro últimos out indican qué bloques opcionales adjuntar tras las
    // ventas: traspasos salientes, ingresos, gastos y ventas a crédito.
    class function Ejecutar(AOwner: TComponent;
                            const ACaja: string;
                            const ASeries: TArray<string>;
                            AVerifactu: Boolean;
                            out ASerie: string;
                            out AImprimirQR: Boolean;
                            out AIncluirTraspasos: Boolean;
                            out AIncluirIngresos: Boolean;
                            out AIncluirGastos: Boolean;
                            out AIncluirCredito: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmModalTiraCaja }

class function TfrmModalTiraCaja.Ejecutar(AOwner: TComponent;
                                          const ACaja: string;
                                          const ASeries: TArray<string>;
                                          AVerifactu: Boolean;
                                          out ASerie: string;
                                          out AImprimirQR: Boolean;
                                          out AIncluirTraspasos: Boolean;
                                          out AIncluirIngresos: Boolean;
                                          out AIncluirGastos: Boolean;
                                          out AIncluirCredito: Boolean): Boolean;
var
  Frm: TfrmModalTiraCaja;
  i: Integer;
begin
  Result            := False;
  ASerie            := '';
  AImprimirQR       := False;
  AIncluirTraspasos := False;
  AIncluirIngresos  := False;
  AIncluirGastos    := False;
  AIncluirCredito   := False;
  Frm := TfrmModalTiraCaja.Create(AOwner);
  try
    Frm.FVerifactu := AVerifactu;
    Frm.lblTitulo.Caption := Format('Tira de Caja · Caja %s', [ACaja]);
    // El índice 0 es siempre "Todas las series"; el resto, una por serie.
    Frm.cbSerie.Properties.Items.Clear;
    Frm.cbSerie.Properties.Items.Add('Todas las series');
    for i := 0 to High(ASeries) do
      Frm.cbSerie.Properties.Items.Add(ASeries[i]);
    Frm.cbSerie.ItemIndex := 0;
    // El QR solo se ofrece (y marca por defecto) si Verifactu está activo.
    Frm.chkQR.Enabled := AVerifactu;
    Frm.chkQR.Checked := AVerifactu;
    if not AVerifactu then
      Frm.chkQR.Caption := 'Imprimir QR Verifactu (no disponible)';
    // Bloques opcionales: desmarcados por defecto, son ampliaciones de la tira.
    Frm.chkTraspasos.Checked := False;
    Frm.chkIngresos.Checked  := False;
    Frm.chkGastos.Checked    := False;
    Frm.chkCredito.Checked   := False;
    if Frm.ShowModal = mrOk then
    begin
      if Frm.cbSerie.ItemIndex <= 0 then
        ASerie := ''
      else
        ASerie := ASeries[Frm.cbSerie.ItemIndex - 1];
      AImprimirQR       := Frm.chkQR.Checked and AVerifactu;
      AIncluirTraspasos := Frm.chkTraspasos.Checked;
      AIncluirIngresos  := Frm.chkIngresos.Checked;
      AIncluirGastos    := Frm.chkGastos.Checked;
      AIncluirCredito   := Frm.chkCredito.Checked;
      Result := True;
    end;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmModalTiraCaja.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

initialization
  ForceReferenceToClass(TfrmModalTiraCaja);
end.
