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
{      SKU=CANTIDAD para que el DM los cargue via CargarDesdeListaSkus. }
{******************************************************************************}
unit inLibInventarioExcel;

interface

uses
  DB, System.SysUtils, System.Classes,
  dxSpreadSheet, dxSpreadSheetCore, cxGraphics, Vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics,
  dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel, inLibHojaCalculoIntf;

type
  TLineaImportada = record
    Sku: string;
    Cantidad: Double;
    PmpNuevo: Double;
    TienePmp: Boolean;
  end;
  TLineasImportadas = TArray<TLineaImportada>;

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);

// Lee la hoja a través del lector (ILectorHojaCalculo). Busca columnas SKU,
// Cantidad y PMP Nuevo por cabecera (fila 0). Si no encuentra cabecera, asume
// col A=SKU, col B=Cantidad. Devuelve un array de registros y un mensaje.
procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasImportadas;
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
  Sheet.BeginUpdate;
  try
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
    QLineas.DisableControls;
    try
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
      Sheet.Cells[iRow, COL_TEOR].Style.DataFormat.FormatCode := '0';
      // Uds fisicas
      rVal := QLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsFloat;
      W(Sheet, iRow, COL_FISIC, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_FISIC].Style.DataFormat.FormatCode := '0';
      // Diferencia (formula)
      WFormula(Sheet, iRow, COL_DIF,
        '=' + GetRef(iRow, COL_FISIC) + '-' + GetRef(iRow, COL_TEOR),
        '0');
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
    finally
      QLineas.EnableControls;
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
                GetRef(iFilaFinLineas, COL_TEOR) + ')', '0');
    Sheet.Cells[iRow, COL_TEOR].Style.Font.Style := [fsBold];
    WFormula(Sheet, iRow, COL_FISIC,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_FISIC) + ':' +
                GetRef(iFilaFinLineas, COL_FISIC) + ')', '0');
    Sheet.Cells[iRow, COL_FISIC].Style.Font.Style := [fsBold];
    WFormula(Sheet, iRow, COL_DIF,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_DIF) + ':' +
                GetRef(iFilaFinLineas, COL_DIF) + ')', '0');
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
  finally
    Sheet.EndUpdate;
  end;
end;

// =============================================================================
//   IMPORTAR
// =============================================================================

procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AMsg: string);
var
  iColSku, iColCant, iColPmp: Integer;
  r, c, iLastRow: Integer;
  sSku, sCant, sPmp: string;
  iLeidas, iVacias: Integer;
  lin: TLineaImportada;

  function CellText(ARow, ACol: Integer): string;
  var
    vCelda: Variant;
  begin
    Result := '';
    if ACol >= 0 then
    begin
      vCelda := ALector.LeerCelda(ARow, ACol);
      if not VarIsNull(vCelda) then
        Result := Trim(VarToStr(vCelda));
    end;
  end;

begin
  ALista := TStringList.Create;
  SetLength(ALineas, 0);
  AMsg := '';
  // Buscar columnas por cabecera (fila 0)
  iColSku  := -1;
  iColCant := -1;
  iColPmp  := -1;
  for c := 0 to 20 do
  begin
    var sHdr := UpperCase(CellText(0, c));
    if (sHdr = 'SKU') or (sHdr = 'CODIGO_UNIDAD') or
       (sHdr = 'CODIGO UNIDAD') or (sHdr = 'UNIDAD') then
      iColSku := c
    else if (sHdr = 'CANTIDAD') or
            (sHdr = 'UDS') or (sHdr = 'UDS. FISICAS') or
            (sHdr = 'FISICAS') or (sHdr = 'QTY') then
      iColCant := c
    else if (sHdr = 'PMP NUEVO') or (sHdr = 'PMP_NUEVO') or
            (sHdr = 'PRECIO_MEDIO_NUEVO') or (sHdr = 'PMP') then
      iColPmp := c;
  end;
  var iFilaInicio := 1;
  if iColSku < 0 then
  begin
    iColSku := 0;
    iColCant := 1;
    iFilaInicio := 0;
  end;
  iLastRow := ALector.UltimaFila;
  if iLastRow < iFilaInicio then
  begin
    AMsg := 'La hoja está vacía o no tiene datos.';
  end
  else
  begin
    iLeidas := 0;
    iVacias := 0;
    for r := iFilaInicio to iLastRow do
    begin
      sSku := CellText(r, iColSku);
      if sSku = '' then
        Inc(iVacias)
      else
      begin
        sCant := CellText(r, iColCant);
        if sCant = '' then
          sCant := '1';
        ALista.Add(sSku + '=' + sCant);
        lin := Default(TLineaImportada);
        lin.Sku := sSku;
        lin.Cantidad := StrToFloatDef(sCant, 1);
        sPmp := CellText(r, iColPmp);
        if sPmp <> '' then
        begin
          lin.PmpNuevo := StrToFloatDef(sPmp, 0);
          lin.TienePmp := True;
        end;
        SetLength(ALineas, Length(ALineas) + 1);
        ALineas[High(ALineas)] := lin;
        Inc(iLeidas);
      end;
    end;
    AMsg := Format('Leidas %d lineas (%d vacias ignoradas).',
      [iLeidas, iVacias]);
  end;
end;

end.
