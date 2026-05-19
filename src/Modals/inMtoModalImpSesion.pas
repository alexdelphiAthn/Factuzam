{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpSesion                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       19/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion HORIZONTAL (apaisado) de una sesion de compra.         }
{    Hereda del modal generico de impresion (TfrmPrint). Las tallas viven      }
{    en columnas T01..T20 — el limite coincide con CANT_TALLAS_MAX del         }
{    form de prueba inMtoPruebaSesionGrid.                                     }
{                                                                              }
{    Datos: tres TfrxDBDataset montados en TdmComprasSesiones                  }
{      - Sesiones      : cabecera enriquecida (empresa + proveedor + totales)  }
{      - LineasSesiones: una linea = un articulo, con T01..T20 cantidades      }
{      - GuiasTallas   : leyenda con T01..T20 rotulos por sistema usado        }
{                                                                              }
{    Documentado en                                                            }
{    DESARROLLOS EN CURSO/pruebas_sesiones/pruebas_sesiones.md (§15).          }
{******************************************************************************}
unit inMtoModalImpSesion;

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
  inMtoModalGenImp, UniDataComprasSesiones;

type
  TfrmPrintSesion = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
  public
    dmSesion: TdmComprasSesiones;
    procedure preparar_consulta;   override;
    procedure AfterReportLoaded;   override;
  end;

implementation

{$R *.dfm}

procedure TfrmPrintSesion.FormCreate(Sender: TObject);
begin
  inherited;
  // El diseño FastReport vive embebido en frxrprt1 (.dfm). Lo
  // duplicamos en frxReportOrigen para que la opcion "Predeterminado"
  // de Consultar_Formularios (frxrprt1.AssignAll(frxReportOrigen))
  // restaure el diseño original en vez de vaciar el report.
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintSesion.preparar_consulta;
begin
  if dmSesion = nil then
    Exit;
  dmSesion.PrepararPrint(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintSesion.AfterReportLoaded;
begin
  inherited;
  if dmSesion <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmSesion);
end;

end.
