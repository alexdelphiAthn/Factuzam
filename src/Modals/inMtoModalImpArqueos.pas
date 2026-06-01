{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpArqueos                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del histórico de arqueos de caja (FastReport).         }
{    Informe A4 horizontal con los principales números de cada cierre. El      }
{    usuario puede retocar el formato con el diseñador (botón Editar) y         }
{    guardarlo como formato propio igual que el resto de informes.             }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo.        }
{******************************************************************************}
unit inMtoModalImpArqueos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, inLibGlobalVar;

type
  TfrmPrintArqueos = class(TfrmPrint)
    unqryArqueosPrint: TUniQuery;
    dsArqueosPrint: TDataSource;
    fxdsArqueos: TfrxDBDataset;
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintArqueos: TfrmPrintArqueos;

implementation

{$R *.dfm}

{ TfrmPrintArqueos }

procedure TfrmPrintArqueos.preparar_consulta;
begin
  inherited;
  with unqryArqueosPrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      ' SELECT *                                                          ' +
      '   FROM fza_caja_arqueos                                           ' +
      '  ORDER BY FECHA_DESDE_ARQ DESC, CODIGO_ARQ DESC                   ';
    Open;
  end;
  fxdsArqueos.UpdateBounds;
end;

end.
