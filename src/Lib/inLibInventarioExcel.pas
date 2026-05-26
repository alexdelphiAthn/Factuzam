{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventarioExcel                                          }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exporta e importa inventarios via dxSpreadSheet.                          }
{    - ExportarInventarioExcel: vuelca cabecera + lineas a una hoja con        }
{      preview editable (mismo patron que inLibDocCompraExcel).                }
{    - ImportarInventarioExcel: lee un .xlsx y devuelve una lista de pares     }
{      SKU=CANTIDAD_ARTVIN para que el DM los cargue via CargarDesdeListaSkus. }
{******************************************************************************}
unit inLibInventarioExcel;

interface

uses
  DB, System.SysUtils, System.Classes,
  dxSpreadSheet, dxSpreadSheetCore, cxGraphics, Vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics,
  dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel;

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);

// Lee la primera hoja del dxSpreadSheet y devuelve una TStringList
// con formato SKU=CANTIDAD_ARTVIN. Busca las columnas SKU y Cantidad
// por cabecera (fila 1). Si no encuentra cabecera, asume col A=SKU,
// col B=Cantidad. Ignora filas vacias.
procedure ImportarInventarioDesdeSheet(
  ASheetControl: TdxSpreadSheet;
  out ALista: TStringList;
  out AMsg: string);

implementation

uses
  System.Variants;

const
  FMT_EUR = '#,##0.00" '#$20AC'"';

// =============================================================================
//   EXPORTAR
// =============================================================================

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);
const
  COL_LINEA = 0;
  COL_ART   = 1;
  COL_SKU   = 2;
  COL_DESC  = 3;
  COL_LOTE  = 4;
  COL_CADUC = 5;
  COL_TEOR  = 6;
  COL_FISIC = 7;
  COL_DIF   = 8;
  COL_PMP   = 9;
  COL_PMPN  = 10;
  COL_COSTE = 11;
  COL_MAX   = 11;
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c: Integer;
  iFilaInicioLineas, iFilaFinLineas: Integer;
  rVal: Double;
begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Inventario',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  // --- Cabecera del documento ---
  iRow := 1;
  W(Sheet, iRow, 0, 'INVENTARIO', True);
  Sheet.Cells[iRow, 0].Style.Font.Size := 16;
  Inc(iRow, 2);
  W(Sheet, iRow, 0, 'Empresa:', True);
  W(Sheet, iRow, 1, QMaster.FieldByName('CODIGO_EMP_INV').AsString);
  W(Sheet, iRow, 3, 'Almacen:', True);
  W(Sheet, iRow, 4, QMaster.FieldByName('CODIGO_ALM_INV').AsString);
  Inc(iRow);
  W(Sheet, iRow, 0, 'Serie:', True);
  W(Sheet, iRow, 1, QMaster.FieldByName('SERIE_INV').AsString);
  W(Sheet, iRow, 3, 'Numero:', True);
  W(Sheet, iRow, 4, QMaster.FieldByName('NUMERO_INV').AsString);
  Inc(iRow);
  W(Sheet, iRow, 0, 'Fecha:', True);
  W(Sheet, iRow, 1, QMaster.FieldByName('FECHA_INV').AsString);
  W(Sheet, iRow, 3, 'Estado:', True);
  W(Sheet, iRow, 4, QMaster.FieldByName('ESTADO_INV').AsString);
  if QMaster.FindField('DESCRIPCION_INV') <> nil then
  begin
    Inc(iRow);
    W(Sheet, iRow, 0, 'Descripcion:', True);
    W(Sheet, iRow, 1, QMaster.FieldByName('DESCRIPCION_INV').AsString);
    Merge(Sheet, iRow, 1, 5, 1);
  end;
  // --- Cabecera de lineas ---
  Inc(iRow, 2);
  W(Sheet, iRow, COL_LINEA, 'Linea',       True, ssahCenter);
  W(Sheet, iRow, COL_ART,   'Articulo',    True, ssahCenter);
  W(Sheet, iRow, COL_SKU,   'SKU',         True, ssahCenter);
  W(Sheet, iRow, COL_DESC,  'Descripcion', True, ssahCenter);
  W(Sheet, iRow, COL_LOTE,  'Lote',        True, ssahCenter);
  W(Sheet, iRow, COL_CADUC, 'Caducidad',   True, ssahCenter);
  W(Sheet, iRow, COL_TEOR,  'Uds. Teor.',  True, ssahRight);
  W(Sheet, iRow, COL_FISIC, 'Uds. Fisicas',True, ssahRight);
  W(Sheet, iRow, COL_DIF,   'Diferencia',  True, ssahRight);
  W(Sheet, iRow, COL_PMP,   'PMP Actual',  True, ssahRight);
  W(Sheet, iRow, COL_PMPN,  'PMP Nuevo',   True, ssahRight);
  W(Sheet, iRow, COL_COSTE, 'Dif. Coste',  True, ssahRight);
  for c := 0 to COL_MAX do
    if Sheet.Cells[iRow, c] <> nil then
    begin
      Sheet.Cells[iRow, c].Style.Font.Color := clWhite;
      Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := $00666666;
      Sheet.Cells[iRow, c].Style.Borders[bBottom].Style := sscbsThin;
    end;
  // --- Datos ---
  Inc(iRow);
  iFilaInicioLineas := iRow;
  if (QLineas <> nil) and QLineas.Active and (not QLineas.IsEmpty) then
  begin
    QLineas.First;
    while not QLineas.Eof do
    begin
      W(Sheet, iRow, COL_LINEA,
        QLineas.FieldByName('LINEA_INVLIN').AsString, False, ssahCenter);
      W(Sheet, iRow, COL_ART,
        QLineas.FieldByName('CODIGO_ART_INVLIN').AsString);
      W(Sheet, iRow, COL_SKU,
        QLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString);
      W(Sheet, iRow, COL_DESC,
        QLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString);
      if QLineas.FindField('LOTE_INVLIN') <> nil then
        W(Sheet, iRow, COL_LOTE,
          QLineas.FieldByName('LOTE_INVLIN').AsString);
      if (QLineas.FindField('FECHA_CADUCIDAD_INVLIN') <> nil) and
         (not QLineas.FieldByName('FECHA_CADUCIDAD_INVLIN').IsNull) then
        W(Sheet, iRow, COL_CADUC,
          QLineas.FieldByName('FECHA_CADUCIDAD_INVLIN').AsString);
      // Uds teoricas
      rVal := QLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsFloat;
      W(Sheet, iRow, COL_TEOR, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_TEOR].Style.DataFormat.FormatCode := '#,##0.##';
      // Uds fisicas
      rVal := QLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsFloat;
      W(Sheet, iRow, COL_FISIC, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_FISIC].Style.DataFormat.FormatCode := '#,##0.##';
      // Diferencia (formula)
      WFormula(Sheet, iRow, COL_DIF,
        '=' + GetRef(iRow, COL_FISIC) + '-' + GetRef(iRow, COL_TEOR),
        '#,##0.##');
      // PMP actual
      rVal := QLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsFloat;
      W(Sheet, iRow, COL_PMP, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_PMP].Style.DataFormat.FormatCode := FMT_EUR;
      // PMP nuevo
      rVal := QLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsFloat;
      W(Sheet, iRow, COL_PMPN, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_PMPN].Style.DataFormat.FormatCode := FMT_EUR;
      // Coste diferencia
      rVal := QLineas.FieldByName('TOTAL_COSTE_DIFERENCIA_INVLIN').AsFloat;
      W(Sheet, iRow, COL_COSTE, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_COSTE].Style.DataFormat.FormatCode := FMT_EUR;
      Inc(iRow);
      QLineas.Next;
    end;
  end;
  iFilaFinLineas := iRow - 1;
  // --- Totales ---
  if iFilaFinLineas >= iFilaInicioLineas then
  begin
    Inc(iRow);
    W(Sheet, iRow, COL_DESC, 'TOTALES', True, ssahRight);
    WFormula(Sheet, iRow, COL_TEOR,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_TEOR) + ':' +
                GetRef(iFilaFinLineas, COL_TEOR) + ')', '#,##0.##');
    Sheet.Cells[iRow, COL_TEOR].Style.Font.Style := [fsBold];
    WFormula(Sheet, iRow, COL_FISIC,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_FISIC) + ':' +
                GetRef(iFilaFinLineas, COL_FISIC) + ')', '#,##0.##');
    Sheet.Cells[iRow, COL_FISIC].Style.Font.Style := [fsBold];
    WFormula(Sheet, iRow, COL_DIF,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_DIF) + ':' +
                GetRef(iFilaFinLineas, COL_DIF) + ')', '#,##0.##');
    Sheet.Cells[iRow, COL_DIF].Style.Font.Style := [fsBold];
    WFormula(Sheet, iRow, COL_COSTE,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_COSTE) + ':' +
                GetRef(iFilaFinLineas, COL_COSTE) + ')', FMT_EUR);
    Sheet.Cells[iRow, COL_COSTE].Style.Font.Style := [fsBold];
    Sheet.Cells[iRow, COL_COSTE].Style.Font.Size := 13;
    for c := COL_DESC to COL_MAX do
      if Sheet.Cells[iRow, c] <> nil then
        Sheet.Cells[iRow, c].Style.Borders[bTop].Style := sscbsThin;
  end;
  // --- Anchos ---
  Sheet.Columns[COL_LINEA].Size := 50;
  Sheet.Columns[COL_ART].Size   := 100;
  Sheet.Columns[COL_SKU].Size   := 150;
  Sheet.Columns[COL_DESC].Size  := 200;
  Sheet.Columns[COL_LOTE].Size  := 80;
  Sheet.Columns[COL_CADUC].Size := 80;
  Sheet.Columns[COL_TEOR].Size  := 70;
  Sheet.Columns[COL_FISIC].Size := 75;
  Sheet.Columns[COL_DIF].Size   := 70;
  Sheet.Columns[COL_PMP].Size   := 80;
  Sheet.Columns[COL_PMPN].Size  := 80;
  Sheet.Columns[COL_COSTE].Size := 90;
end;

// =============================================================================
//   IMPORTAR
// =============================================================================

procedure ImportarInventarioDesdeSheet(
  ASheetControl: TdxSpreadSheet;
  out ALista: TStringList;
  out AMsg: string);
var
  Sheet: TdxSpreadSheetTableView;
  iColSku, iColCant: Integer;
  r, c, iLastRow: Integer;
  sSku, sCant: string;
  iLeidas, iVacias: Integer;

  function CellText(ARow, ACol: Integer): string;
  begin
    Result := '';
    if (Sheet.Cells[ARow, ACol] <> nil) then
    begin
      if not VarIsNull(Sheet.Cells[ARow, ACol].AsVariant) then
        Result := Trim(VarToStr(Sheet.Cells[ARow, ACol].AsVariant));
    end;
  end;

begin
  ALista := TStringList.Create;
  AMsg := '';
  if ASheetControl.SheetCount = 0 then
  begin
    AMsg := 'El archivo no contiene hojas.';
    Exit;
  end;
  Sheet := ASheetControl.Sheets[0] as TdxSpreadSheetTableView;
  // Buscar columnas por cabecera (fila 0)
  iColSku  := -1;
  iColCant := -1;
  for c := 0 to 20 do
  begin
    var sHdr := UpperCase(CellText(0, c));
    if (sHdr = 'SKU') or (sHdr = 'CODIGO_UNIDAD') or
       (sHdr = 'CODIGO UNIDAD') or (sHdr = 'UNIDAD') then
      iColSku := c
    else if (sHdr = 'CANTIDAD') or (sHdr = 'CANTIDAD_ARTVIN') or
            (sHdr = 'UDS') or (sHdr = 'UDS. FISICAS') or
            (sHdr = 'FISICAS') or (sHdr = 'QTY') then
      iColCant := c;
  end;
  var iFilaInicio := 1; // saltar cabecera
  // Si no encontramos cabecera, asumir A=SKU B=Cantidad desde fila 0
  if iColSku < 0 then
  begin
    iColSku := 0;
    iColCant := 1;
    iFilaInicio := 0;
  end;
  // Ultima fila con datos
  iLastRow := Sheet.Dimensions.Bottom;
  if iLastRow < iFilaInicio then
  begin
    AMsg := 'La hoja esta vacia.';
    Exit;
  end;
  iLeidas := 0;
  iVacias := 0;
  for r := iFilaInicio to iLastRow do
  begin
    sSku := CellText(r, iColSku);
    if sSku = '' then
    begin
      Inc(iVacias);
      Continue;
    end;
    if iColCant >= 0 then
      sCant := CellText(r, iColCant)
    else
      sCant := '1';
    if sCant = '' then
      sCant := '1';
    // Formato SKU=CANTIDAD_ARTVIN compatible con CargarDesdeListaSkus
    ALista.Add(sSku + '=' + sCant);
    Inc(iLeidas);
  end;
  AMsg := Format('Leidas %d lineas (%d vacias ignoradas).', [iLeidas, iVacias]);
end;

end.
