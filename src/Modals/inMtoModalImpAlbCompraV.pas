{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpAlbCompraV                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion VERTICAL del albaran de compra. Estilo factura:        }
{    una fila por SKU sin pivotar tallas. Hereda de TfrmPrint igual que        }
{    el modal horizontal pero usa LineasAlbaranSku (no LineasAlbaran) y        }
{    tiene su propio diseno FastReport embebido (a disenar con el FR          }
{    designer la primera vez que se abra).                                     }
{******************************************************************************}
unit inMtoModalImpAlbCompraV;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.ActnList,
  System.Actions,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses, cxLocalization, cxStyles,
  cxMaskEdit,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxSkinsDefaultPainters,
  frxClass, frxDBSet, frxDesgn, frxExportBaseDialog, frxExportPDF,
  frxExportXLSX, frxExportBaseImageSettingsDialog, frCoreClasses,
  frLocalization, frLanguageSpanish, frxSmartMemo,
  JvComponentBase, JvEnterTab,
  inMtoModalGenImp, UniDataAlbaranesCompra;

type
  TfrmPrintAlbCompraV = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
  public
    dmAlbc: TdmAlbaranesCompra;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

procedure TfrmPrintAlbCompraV.FormCreate(Sender: TObject);
begin
  inherited;
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintAlbCompraV.preparar_consulta;
begin
  if dmAlbc = nil then Exit;
  dmAlbc.PrepararPrintSku(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintAlbCompraV.AfterReportLoaded;
begin
  inherited;
  if dmAlbc <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmAlbc);
end;

end.
