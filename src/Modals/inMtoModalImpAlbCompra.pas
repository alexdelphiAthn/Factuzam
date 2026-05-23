{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpAlbCompra                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de un albaran de compra. Hereda del modal generico     }
{    TfrmPrint. Misma logica que inMtoModalImpSesion pero contra los datasets  }
{    de albaranes (TdmAlbaranesCompra.PrepararPrint y los fxds* asociados).    }
{    La orientacion (horizontal / vertical) la decide el llamador via la       }
{    propiedad Orientacion; el report .fr3 embebido en frxrprt1 se disena      }
{    a mano con el FastReport designer.                                        }
{******************************************************************************}
unit inMtoModalImpAlbCompra;

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
  TOrientacionAlbCompra = (oacHorizontal, oacVertical);

  TfrmPrintAlbCompra = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
  public
    dmAlbc:      TdmAlbaranesCompra;
    Orientacion: TOrientacionAlbCompra;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

procedure TfrmPrintAlbCompra.FormCreate(Sender: TObject);
begin
  inherited;
  // El diseno FastReport vive embebido en frxrprt1 (.dfm). Lo
  // duplicamos en frxReportOrigen para que la opcion "Predeterminado"
  // de Consultar_Formularios (frxrprt1.AssignAll(frxReportOrigen))
  // restaure el diseno original en vez de vaciar el report. Mismo
  // patron que TfrmPrintSesion.
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintAlbCompra.preparar_consulta;
begin
  if dmAlbc = nil then Exit;
  dmAlbc.PrepararPrint(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintAlbCompra.AfterReportLoaded;
begin
  inherited;
  if dmAlbc <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmAlbc);
end;

end.
