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
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxDateUtils,
  Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, inLibGlobalVar;

type
  TfrmPrintArqueos = class(TfrmPrint)
    unqryArqueosPrint: TUniQuery;
    dsArqueosPrint: TDataSource;
    fxdsArqueos: TfrxDBDataset;
    lblTitulo: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
  private
    // Fija el rango por defecto una sola vez al abrir el modal; evita
    // pisar lo que elija el usuario en el ciclo Hide/Show que hacen los
    // botones del padre (Imprimir / PDF / Vista Preliminar / Excel).
    FFechasInicializadas: Boolean;
  protected
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintArqueos: TfrmPrintArqueos;

implementation

{$R *.dfm}

{ TfrmPrintArqueos }

procedure TfrmPrintArqueos.DoShow;
begin
  inherited;
  // Por defecto el rango va del primer dia del mes en curso hasta hoy.
  // El usuario puede ampliarlo antes de imprimir / previsualizar.
  if not FFechasInicializadas then
  begin
    dteDesde.Date := EncodeDate(YearOf(Date), MonthOf(Date), 1);
    dteHasta.Date := Date;
    FFechasInicializadas := True;
  end;
end;

procedure TfrmPrintArqueos.preparar_consulta;
begin
  inherited;
  // Filtramos por la fecha de inicio del arqueo (FECHA_DESDE_ARQ es la
  // columna que muestra la rejilla y por la que se ordena). Al ser tipo
  // DATE el BETWEEN incluye ambos extremos del rango elegido.
  with unqryArqueosPrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      ' SELECT *                                                          ' +
      '   FROM fza_caja_arqueos                                           ' +
      '  WHERE FECHA_DESDE_ARQ BETWEEN :pDESDE AND :pHASTA                ' +
      '  ORDER BY FECHA_DESDE_ARQ DESC, CODIGO_ARQ DESC                   ';
    ParamByName('pDESDE').AsDateTime := dteDesde.Date;
    ParamByName('pHASTA').AsDateTime := dteHasta.Date;
    Open;
  end;
  fxdsArqueos.UpdateBounds;
end;

end.
