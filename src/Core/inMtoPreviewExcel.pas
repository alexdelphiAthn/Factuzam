{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPreviewExcel                                             }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para presentar la pantalla    }
{    de Previsualización de Hoja de Cálculo. Tiene una tradución propia.       }
{    que es inLibdxSpreadSheetStrs_ESP, ejecutando ApplySpanishTranslation;    }
{******************************************************************************}
unit inMtoPreviewExcel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, dxCore, dxCoreClasses, dxHashUtils,
  dxSpreadSheetCore, dxSpreadSheetCoreFormulas, dxSpreadSheetCoreHistory,
  dxSpreadSheetCoreStyles, dxSpreadSheetCoreStrs,
  dxSpreadSheetConditionalFormatting, dxSpreadSheetConditionalFormattingRules,
  dxSpreadSheetClasses, dxSpreadSheetContainers, dxSpreadSheetFormulas,
  dxSpreadSheetHyperlinks, dxSpreadSheetFunctions, dxSpreadSheetStyles,
  dxSpreadSheetGraphics, dxSpreadSheetPrinting, dxSpreadSheetTypes,
  dxSpreadSheetUtils, dxSpreadSheetFormattedTextUtils,
  Vcl.Menus, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, dxSpreadSheet,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization, dxShellDialogs,
  dxSpreadSheetFormulaBar, dxSpreadSheetFunctionsStatistical,
  dxSpreadSheetFunctionsMath, System.Actions, Vcl.ActnList;

type
  TfrmMtoPreviewExcel = class(TfrmBase)
    dxSpreadSheet1: TdxSpreadSheet;
    Panel1: TPanel;
    btnGuardar: TcxButton;
    btnCerrar: TcxButton;
    DialogoGuardar: TdxSaveFileDialog;
    dxSpreadSheetFormulaBar1: TdxSpreadSheetFormulaBar;
    ActionList1: TActionList;
    actSalir: TAction;
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMtoPreviewExcel: TfrmMtoPreviewExcel;

implementation

uses inLibdxSpreadSheetStrs_ESP;

{$R *.dfm}

procedure TfrmMtoPreviewExcel.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnCerrarClick(Sender);
end;

procedure TfrmMtoPreviewExcel.btnCerrarClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmMtoPreviewExcel.btnGuardarClick(Sender: TObject);
begin
  inherited;
  DialogoGuardar.DefaultExt := 'xlsx';
  DialogoGuardar.Filter := 'Libro de Excel (*.xlsx)|*.xlsx';
  if DialogoGuardar.Execute then
    dxSpreadSheet1.SaveToFile(DialogoGuardar.FileName);
end;

procedure TfrmMtoPreviewExcel.FormCreate(Sender: TObject);
begin
  inherited;
  ApplySpanishTranslation;

end;

procedure TfrmMtoPreviewExcel.FormShow(Sender: TObject);
begin
  inherited;
  Self.WindowState := wsMaximized;
end;

end.
