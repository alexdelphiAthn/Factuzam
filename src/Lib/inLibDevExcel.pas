{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevExcel                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Helpers para escribir en hojas dxSpreadSheet de DevExpress.               }
{    Funciones de fusión, escritura y formato de celdas y fórmulas.            }
{******************************************************************************}
unit inLibDevExcel;

interface

uses
  dxSpreadSheet, dxSpreadSheetCore, Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, cxGraphics,
  System.Classes, Vcl.Graphics, system.Types,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxHashUtils;

  procedure Merge(Sheet: TdxSpreadSheetTableView;
                  ARow, ACol, ColCount, RowCount: Integer);
  procedure W(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
              const AValue: Variant;
              ABold: Boolean = False;
              AAlign: TdxSpreadSheetDataAlignHorz = ssahLeft);
  procedure WFormula(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
                     const AFormula: string;
                     AFormat: string = '');
  procedure PintarCuadro(Sheet: TdxSpreadSheetTableView;
                         R1, C1, R2, C2: Integer;
                         DxStyle: TdxSpreadSheetCellBorderStyle);
  function GetRef(R, C: Integer; Absolute: Boolean = False): string;
  function ColToLetras(C: Integer): string;
  function SepFormula: string;

implementation
  procedure Merge(Sheet: TdxSpreadSheetTableView;
                  ARow, ACol, ColCount, RowCount: Integer);
  var
    R: TRect;
  begin
    // Definimos el rectángulo explícitamente para evitar errores de cálculo
    // TRect(Left, Top, Right, Bottom) -> (X1, Y1, X2, Y2)

    R.Left   := ACol;                // Columna Inicial
    R.Top    := ARow;                // Fila Inicial
    R.Right  := ACol + ColCount - 1; // Columna Final (Inclusive)
    R.Bottom := ARow + RowCount - 1; // Fila Final (Inclusive)

    Sheet.MergedCells.Add(R);
  end;

  // Helper para escribir celdas
  procedure W(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
              const AValue: Variant;
              ABold: Boolean = False;
              AAlign: TdxSpreadSheetDataAlignHorz = ssahLeft);
  begin
    with Sheet.CreateCell(ARow, ACol) do
    begin
      AsVariant := AValue;
      if ABold then Style.Font.Style := [fsBold] else Style.Font.Style := [];
      Style.AlignHorz := AAlign;
      Style.AlignVert := ssavCenter; // Centrado vertical para que quede mejor
    end;
  end;

//  function N(const AValue: Double): string;
//  var
//    fs: TFormatSettings;
//  begin
//    //fs := TFormatSettings.Invariant; // Fuerza el punto (5.2)
//    Result := FloatToStr(AValue, fs);
//  end;

  procedure WFormula(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
                     const AFormula: string;
                     AFormat: string = '');
  begin
    with Sheet.CreateCell(ARow, ACol) do
    begin
      // SetText(..., True) es CRÍTICO para que interprete la fórmula
      SetText(AFormula, True);
      Style.AlignHorz := ssahRight;
      if AFormat <> '' then Style.DataFormat.FormatCode := AFormat;
    end;
  end;

  procedure PintarCuadro(Sheet: TdxSpreadSheetTableView;
                         R1, C1, R2, C2: Integer;
                         DxStyle: TdxSpreadSheetCellBorderStyle);
  var
    r, c: Integer;
  begin

    // 2. Pintamos Bordes Superior e Inferior (Techo y Suelo)
    for c := C1 to C2 do
    begin
      // Borde Superior
      if Sheet.Cells[R1, c] = nil then Sheet.CreateCell(R1, c);
      Sheet.Cells[R1, c].Style.Borders[bTop].Style := DxStyle;

      // Borde Inferior
      if Sheet.Cells[R2, c] = nil then Sheet.CreateCell(R2, c);
      Sheet.Cells[R2, c].Style.Borders[bBottom].Style := DxStyle;
    end;

    // 3. Pintamos Bordes Izquierdo y Derecho (Paredes)
    for r := R1 to R2 do
    begin
      // Borde Izquierdo
      if Sheet.Cells[r, C1] = nil then Sheet.CreateCell(r, C1);
      Sheet.Cells[r, C1].Style.Borders[bLeft].Style := DxStyle;

      // Borde Derecho
      if Sheet.Cells[r, C2] = nil then Sheet.CreateCell(r, C2);
      Sheet.Cells[r, C2].Style.Borders[bRight].Style := DxStyle;
    end;
  end;

  function ColToLetras(C: Integer): string;
  begin
    Result := '';
    repeat
      Result := Chr(Ord('A') + (C mod 26)) + Result;
      C := C div 26 - 1;
    until C < 0;
  end;

  function GetRef(R, C: Integer; Absolute: Boolean = False): string;
  var
    ColStr: string;
  begin
    ColStr := ColToLetras(C);
    if Absolute then
      Result := '$' + ColStr + '$' + IntToStr(R + 1)
    else
      Result := ColStr + IntToStr(R + 1);
  end;

  // Separador de argumentos de fórmula que espera dxSpreadSheet según el
  // locale. Con la coma como separador decimal (España) el separador de
  // argumentos es ';'. Emitir ',' en ese caso hace que dxSpreadSheet
  // interprete SUM(A1,A2) como el RANGO SUM(A1:A2) y sume las celdas
  // intermedias (totales contaminados con bandas vecinas). El .xlsx
  // exportado se ve bien igualmente porque OOXML usa siempre la coma; el
  // fallo es solo en la previsualización.
  function SepFormula: string;
  begin
    if FormatSettings.DecimalSeparator = ',' then
      Result := ';'
    else
      Result := ',';
  end;


end.
