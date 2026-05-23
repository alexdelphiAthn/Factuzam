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
  Vcl.Printers,
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
var
  i, j   : Integer;
  pg     : TfrxReportPage;
  obj    : TfrxComponent;
  view   : TfrxView;
  factor : Extended;
begin
  if dmAlbc = nil then Exit;
  dmAlbc.PrepararPrint(edtSerie.Text, edtNumero.Text);
  // Restauramos el diseno original ANTES de aplicar orientacion: si el
  // usuario ha imprimido vertical antes, los Left/Width estan reducidos
  // y aplicar otra vez el factor los reduciria de nuevo. frxReportOrigen
  // tiene el snapshot que se hizo en FormCreate (siempre el diseno
  // horizontal original).
  frxrprt1.AssignAll(frxReportOrigen);
  for i := 0 to frxrprt1.PagesCount - 1 do
  begin
    if not (frxrprt1.Pages[i] is TfrxReportPage) then Continue;
    pg := TfrxReportPage(frxrprt1.Pages[i]);
    if Orientacion = oacHorizontal then
    begin
      pg.Orientation := poLandscape;
      pg.PaperWidth  := 297;
      pg.PaperHeight := 210;
    end
    else
    begin
      pg.Orientation := poPortrait;
      pg.PaperWidth  := 210;
      pg.PaperHeight := 297;
      // Reescala todos los memos/views al 210/297 = ~0,707 de su ancho
      // y left originales. Las fuentes y altos no se tocan: lo que
      // queremos es que un diseno pensado para apaisado quepa tal cual
      // en vertical aunque con texto mas comprimido. Solucion pragmatica
      // hasta tener un .fr3 vertical especifico disenado a mano.
      factor := 210 / 297;
      for j := 0 to pg.AllObjects.Count - 1 do
      begin
        obj := TfrxComponent(pg.AllObjects[j]);
        if obj is TfrxView then
        begin
          view := TfrxView(obj);
          view.Left  := view.Left * factor;
          view.Width := view.Width * factor;
        end;
      end;
    end;
  end;
end;

procedure TfrmPrintAlbCompra.AfterReportLoaded;
begin
  inherited;
  if dmAlbc <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmAlbc);
end;

end.
