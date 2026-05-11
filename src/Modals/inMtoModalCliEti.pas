{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCliEti                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de etiquetas de clientes.                              }
{    Permite codigo de cliente y numero de blancos a dejar.                    }
{******************************************************************************}
unit inMtoModalCliEti;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxDesgn, Data.DB, MemDS,
  DBAccess, Uni, frxExportXLSX, frxClass, frxExportBaseDialog, frxExportPDF,
  cxClasses, cxLocalization, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, dxSkinsCore,
  dxSkinBlue, cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit,
  cxSpinEdit, cxLabel, cxGroupBox, cxRadioGroup, UniDataClientes, inMtoClientes,
  JvComponentBase, JvEnterTab;

type
  TfrmPrintCliEti = class(TfrmPrint)
    cxRadioGroup1: TcxRadioGroup;
    cxlbl2: TcxLabel;
    speDejarBlancos: TcxSpinEdit;
    edtCodCli: TcxTextEdit;
    cxLabel1: TcxLabel;
  private
    { Private declarations }
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintCliEti: TfrmPrintCliEti;

implementation

{$R *.dfm}

procedure TfrmPrintCliEti.preparar_consulta;
begin
  dmmClientes.CrearDataSetEtiquetas(speDejarBlancos.Value, edtCodCli.text);
end;


end.
