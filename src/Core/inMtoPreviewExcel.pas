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
  dxSpreadSheetUtils, dxSpreadSheetFormattedTextUtils, dxBarBuiltInMenu,
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

end.
