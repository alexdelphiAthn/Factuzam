{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPreviewExcelContazam                                    }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Vista previa editable de libros XLSX mediante Developer Express.         }
{******************************************************************************}
unit inMtoPreviewExcelContazam;

interface

uses
  System.Classes, Vcl.Controls, Vcl.ExtCtrls, inMtoFrmBase, cxButtons,
  dxSpreadSheet, dxSpreadSheetFormulaBar;

type
  TfrmMtoPreviewExcelContazam = class(TfrmBase)
  private
    FBtnCerrar: TcxButton;
    FBtnGuardar: TcxButton;
    FBarraFormula: TdxSpreadSheetFormulaBar;
    FHoja: TdxSpreadSheet;
    FNombreArchivo: string;
    FPanelBotones: TPanel;
    procedure CerrarClick(Sender: TObject);
    procedure GuardarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Cargar(
      const ARuta: string;
      const ANombreArchivo: string);
  end;

implementation

uses
  System.SysUtils, Vcl.Dialogs, Vcl.Forms;

constructor TfrmMtoPreviewExcelContazam.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Vista previa de Excel';
  Width := 1200;
  Height := 780;
  FPanelBotones := TPanel.Create(Self);
  FPanelBotones.Parent := Self;
  FPanelBotones.Align := alTop;
  FPanelBotones.Height := 44;
  FPanelBotones.BevelOuter := bvNone;
  FBtnGuardar := TcxButton.Create(Self);
  FBtnGuardar.Parent := FPanelBotones;
  FBtnGuardar.SetBounds(8, 5, 150, 34);
  FBtnGuardar.Caption := 'Guardar Excel...';
  FBtnGuardar.OnClick := GuardarClick;
  FBtnCerrar := TcxButton.Create(Self);
  FBtnCerrar.Parent := FPanelBotones;
  FBtnCerrar.SetBounds(165, 5, 120, 34);
  FBtnCerrar.Caption := 'Cerrar';
  FBtnCerrar.Cancel := True;
  FBtnCerrar.OnClick := CerrarClick;
  FBarraFormula := TdxSpreadSheetFormulaBar.Create(Self);
  FBarraFormula.Parent := Self;
  FBarraFormula.Align := alTop;
  FBarraFormula.Height := 27;
  FHoja := TdxSpreadSheet.Create(Self);
  FHoja.Parent := Self;
  FHoja.Align := alClient;
  FBarraFormula.SpreadSheet := FHoja;
end;

procedure TfrmMtoPreviewExcelContazam.Cargar(
  const ARuta: string;
  const ANombreArchivo: string);
begin
  if not FileExists(ARuta) then
  begin
    raise EFileNotFoundException.Create(
      'No existe el libro temporal que se quiere previsualizar.');
  end;
  FNombreArchivo := ANombreArchivo;
  FHoja.LoadFromFile(ARuta);
  WindowState := wsMaximized;
end;

procedure TfrmMtoPreviewExcelContazam.CerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMtoPreviewExcelContazam.GuardarClick(Sender: TObject);
var
  oDialogo: TFileSaveDialog;
  oTipoFichero: TFileTypeItem;
  sRuta: string;
begin
  oDialogo := TFileSaveDialog.Create(nil);
  try
    oDialogo.Title := 'Guardar listado Excel';
    oDialogo.DefaultExtension := 'xlsx';
    oDialogo.FileName := FNombreArchivo;
    oTipoFichero := oDialogo.FileTypes.Add;
    oTipoFichero.DisplayName := 'Libro de Excel (*.xlsx)';
    oTipoFichero.FileMask := '*.xlsx';
    if oDialogo.Execute(Handle) then
    begin
      sRuta := oDialogo.FileName;
      if not SameText(ExtractFileExt(sRuta), '.xlsx') then
      begin
        sRuta := ChangeFileExt(sRuta, '.xlsx');
      end;
      FHoja.SaveToFile(sRuta);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

end.
