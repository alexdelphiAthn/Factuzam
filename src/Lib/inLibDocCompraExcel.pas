{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocCompraExcel                                           }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exporta documentos de compra (sesiones, albaranes) a hoja dxSpreadSheet.  }
{    Formato horizontal (tallas en columnas T01..T20) y vertical (una fila     }
{    por SKU). Reutiliza los helpers de inLibDevExcel (W, WFormula, Merge,     }
{    GetRef, ColToLetras, PintarCuadro).                                       }
{                                                                              }
{    Diseñado para ser llamado desde los modales de impresion                  }
{    (inMtoModalImpSesion, inMtoModalImpAlbCompra, inMtoModalImpAlbCompraV)    }
{    sobre los datasets de las vistas vi_*_print del DM correspondiente.       }
{******************************************************************************}
unit inLibDocCompraExcel;

interface

uses
  DB, System.SysUtils,
  dxSpreadSheet, dxSpreadSheetCore, cxGraphics, Vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics,
  dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel;

const
  MAX_TALLAS = 20;
  FMT_EUR = '#,##0.00" '#$20AC'"';

type
  // Mapeo de campos de cabecera. Permite que sesiones y albaranes
  // usen la misma logica con nombres de campo distintos.
  TDocCompraCabCfg = record
    Titulo: string;
    // Bloque izquierdo (empresa o almacen destino)
    EtiquetaIzq: string;
    FieldRazonIzq: string;
    FieldDirIzq: string;
    FieldCPIzq: string;
    FieldPobIzq: string;
    FieldCifIzq: string;
    FieldTelIzq: string;
    FieldProvIzq: string;
    // Bloque derecho (proveedor)
    FieldRazonPrv: string;
    FieldDirPrv: string;
    FieldCPPrv: string;
    FieldPobPrv: string;
    FieldCifPrv: string;
    FieldTelPrv: string;
    FieldProvPrv: string;
    // Datos del documento
    FieldSerie: string;
    FieldNumero: string;
    FieldFecha: string;
    FieldEstado: string;
    FieldRefPrv: string;
    // Lineas: si True muestra columna Pr. Venta
    MostrarPrecioVenta: Boolean;
  end;

procedure ExportarDocCompraHorizontal(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas, QGuias: TDataSet;
  const ACfg: TDocCompraCabCfg);

procedure ExportarDocCompraVertical(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet;
  const ACfg: TDocCompraCabCfg);

implementation

uses
  inLibFormatoDocumento;

// ===== Helpers internos =====================================================

procedure PintarCabeceraDoc(Sheet: TdxSpreadSheetTableView;
  const QMaster: TDataSet; const ACfg: TDocCompraCabCfg;
  AColMax: Integer; out AFilaSiguiente: Integer);
var
  iRow: Integer;
  sDocumento: string;
begin
  iRow := 1;
  // Titulo
  W(Sheet, iRow, 0, ACfg.Titulo, True);
  Sheet.Cells[iRow, 0].Style.Font.Size := 16;
  // Bloque izquierdo: empresa / almacen destino
  Inc(iRow, 2); // fila 3
  W(Sheet, iRow, 0, ACfg.EtiquetaIzq, True);
  Inc(iRow);
  W(Sheet, iRow, 0, QMaster.FieldByName(ACfg.FieldRazonIzq).AsString, True);
  Merge(Sheet, iRow, 0, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, 0, QMaster.FieldByName(ACfg.FieldDirIzq).AsString);
  Merge(Sheet, iRow, 0, 4, 1);
  Inc(iRow);
  var sCPPobIzq := QMaster.FieldByName(ACfg.FieldCPIzq).AsString + ' ' +
    QMaster.FieldByName(ACfg.FieldPobIzq).AsString;
  if (ACfg.FieldProvIzq <> '') and
     (QMaster.FindField(ACfg.FieldProvIzq) <> nil) then
    sCPPobIzq := sCPPobIzq + ' (' +
      QMaster.FieldByName(ACfg.FieldProvIzq).AsString + ')';
  W(Sheet, iRow, 0, sCPPobIzq);
  Merge(Sheet, iRow, 0, 4, 1);
  Inc(iRow);
  var sCifTelIzq := 'CIF: ' +
    QMaster.FieldByName(ACfg.FieldCifIzq).AsString;
  if (ACfg.FieldTelIzq <> '') and
     (QMaster.FindField(ACfg.FieldTelIzq) <> nil) and
     (Trim(QMaster.FieldByName(ACfg.FieldTelIzq).AsString) <> '') then
    sCifTelIzq := sCifTelIzq + '   Tel: ' +
      QMaster.FieldByName(ACfg.FieldTelIzq).AsString;
  W(Sheet, iRow, 0, sCifTelIzq);
  Merge(Sheet, iRow, 0, 4, 1);
  // Bloque derecho: proveedor (desde columna 5)
  iRow := 3;
  W(Sheet, iRow, 5, 'PROVEEDOR', True);
  Inc(iRow);
  W(Sheet, iRow, 5, QMaster.FieldByName(ACfg.FieldRazonPrv).AsString, True);
  Merge(Sheet, iRow, 5, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, 5, QMaster.FieldByName(ACfg.FieldDirPrv).AsString);
  Merge(Sheet, iRow, 5, 4, 1);
  Inc(iRow);
  var sCPPobPrv := QMaster.FieldByName(ACfg.FieldCPPrv).AsString + ' ' +
    QMaster.FieldByName(ACfg.FieldPobPrv).AsString;
  if (ACfg.FieldProvPrv <> '') and
     (QMaster.FindField(ACfg.FieldProvPrv) <> nil) then
    sCPPobPrv := sCPPobPrv + ' (' +
      QMaster.FieldByName(ACfg.FieldProvPrv).AsString + ')';
  W(Sheet, iRow, 5, sCPPobPrv);
  Merge(Sheet, iRow, 5, 4, 1);
  Inc(iRow);
  var sCifTelPrv := 'CIF: ' +
    QMaster.FieldByName(ACfg.FieldCifPrv).AsString;
  if (ACfg.FieldTelPrv <> '') and
     (QMaster.FindField(ACfg.FieldTelPrv) <> nil) and
     (Trim(QMaster.FieldByName(ACfg.FieldTelPrv).AsString) <> '') then
    sCifTelPrv := sCifTelPrv + '   Tel: ' +
      QMaster.FieldByName(ACfg.FieldTelPrv).AsString;
  W(Sheet, iRow, 5, sCifTelPrv);
  Merge(Sheet, iRow, 5, 4, 1);
  // Datos del documento (derecha, desde la columna alta)
  var cDoc := AColMax - 3;
  if cDoc < 10 then
    cDoc := 10;
  sDocumento := FormatearDocumentoDataSet(QMaster, ACfg.FieldSerie,
    ACfg.FieldNumero);
  iRow := 3;
  W(Sheet, iRow, cDoc, 'DOCUMENTO', True);
  Inc(iRow);
  W(Sheet, iRow, cDoc, sDocumento, True);
  Merge(Sheet, iRow, cDoc, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, cDoc, 'Fecha: ' +
    QMaster.FieldByName(ACfg.FieldFecha).AsString);
  Merge(Sheet, iRow, cDoc, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, cDoc, 'Estado: ' +
    QMaster.FieldByName(ACfg.FieldEstado).AsString);
  Merge(Sheet, iRow, cDoc, 4, 1);
  Inc(iRow);
  if ACfg.FieldRefPrv <> '' then
  begin
    W(Sheet, iRow, cDoc, 'Ref. Prv.: ' +
      QMaster.FieldByName(ACfg.FieldRefPrv).AsString);
    Merge(Sheet, iRow, cDoc, 4, 1);
  end;
  AFilaSiguiente := 9;
end;

function ContarTallasConDatos(const QGuias: TDataSet): Integer;
var
  i, iMax: Integer;
  sField: string;
begin
  // Recorre los sistemas de tallas y determina cuantas columnas T tienen dato
  iMax := 0;
  if (QGuias = nil) or (not QGuias.Active) or QGuias.IsEmpty then
  begin
    Result := 0;
    Exit;
  end;
  QGuias.First;
  while not QGuias.Eof do
  begin
    for i := MAX_TALLAS downto 1 do
    begin
      sField := Format('T%.2d', [i]);
      if (QGuias.FindField(sField) <> nil) and
         (Trim(QGuias.FieldByName(sField).AsString) <> '') then
      begin
        if i > iMax then
          iMax := i;
        Break;
      end;
    end;
    QGuias.Next;
  end;
  Result := iMax;
end;

// ===== Exportacion horizontal ===============================================

procedure ExportarDocCompraHorizontal(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas, QGuias: TDataSet;
  const ACfg: TDocCompraCabCfg);
var
  Sheet: TdxSpreadSheetTableView;
  iRow, c, i, iNumTallas: Integer;
  iFilaInicioGuias, iFilaFinGuias: Integer;
  iFilaHeaders, iFilaInicioLineas, iFilaFinLineas: Integer;
  // Columnas fijas
  COL_ART, COL_REF, COL_DESC, COL_COLOR, COL_SIS: Integer;
  COL_PV: Integer;    // precio venta (solo sesiones)
  COL_T01: Integer;   // primera columna de talla
  COL_UDS, COL_IMP: Integer;
  iColMax: Integer;
  rVal: Double;
  sField: string;
begin
  ASheetControl.ClearAll;
  iNumTallas := ContarTallasConDatos(QGuias);
  if iNumTallas = 0 then
    iNumTallas := 10;
  // Definir columnas
  COL_ART   := 0;
  COL_REF   := 1;
  COL_DESC  := 2;
  COL_COLOR := 3;
  COL_SIS   := 4;
  var COL_PC := 5; // precio compra siempre visible
  if ACfg.MostrarPrecioVenta then
  begin
    COL_PV  := 6;
    COL_T01 := 7;
  end
  else
  begin
    COL_PV  := -1;
    COL_T01 := 6;
  end;
  COL_UDS := COL_T01 + iNumTallas;
  COL_IMP := COL_UDS + 1;
  iColMax := COL_IMP;
  Sheet := ASheetControl.AddSheet(ACfg.Titulo,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Sheet.BeginUpdate;
  try
  // --- Cabecera ---
  PintarCabeceraDoc(Sheet, QMaster, ACfg, iColMax, iRow);
  // --- Guias de tallas (justo encima de las cabeceras de columna) ---
  Inc(iRow);
  iFilaInicioGuias := iRow;
  if (QGuias <> nil) and QGuias.Active and (not QGuias.IsEmpty) then
  begin
    QGuias.First;
    while not QGuias.Eof do
    begin
      // Sistema en la zona de columnas fijas
      W(Sheet, iRow, COL_SIS,
        QGuias.FieldByName('NOMBRE_CORTO_AC').AsString, True, ssahCenter);
      Sheet.Cells[iRow, COL_SIS].Style.Brush.BackgroundColor := $00E8E8E8;
      // Nombre completo del sistema
      var COL_PC_LOCAL := COL_SIS + 1;
      W(Sheet, iRow, COL_PC_LOCAL,
        QGuias.FieldByName('NOMBRE_AC').AsString, False, ssahLeft);
      Sheet.Cells[iRow, COL_PC_LOCAL].Style.Brush.BackgroundColor := $00E8E8E8;
      // Etiquetas de talla alineadas con T01..Txx
      for i := 1 to iNumTallas do
      begin
        sField := Format('T%.2d', [i]);
        if (QGuias.FindField(sField) <> nil) and
           (Trim(QGuias.FieldByName(sField).AsString) <> '') then
        begin
          W(Sheet, iRow, COL_T01 + i - 1,
            QGuias.FieldByName(sField).AsString, True, ssahCenter);
          Sheet.Cells[iRow, COL_T01 + i - 1].Style.Font.Size := 9;
          Sheet.Cells[iRow, COL_T01 + i - 1].Style.Brush.BackgroundColor :=
            $00E8E8E8;
        end;
      end;
      Inc(iRow);
      QGuias.Next;
    end;
  end;
  iFilaFinGuias := iRow - 1;
  // --- Cabecera de lineas ---
  iFilaHeaders := iRow;
  W(Sheet, iRow, COL_ART,   'Cod. Art.',    True, ssahCenter);
  W(Sheet, iRow, COL_REF,   'Ref. Prv.',    True, ssahCenter);
  W(Sheet, iRow, COL_DESC,  'Descripcion',  True, ssahCenter);
  W(Sheet, iRow, COL_COLOR, 'Color',        True, ssahCenter);
  W(Sheet, iRow, COL_SIS,   'Sis.',         True, ssahCenter);
  W(Sheet, iRow, COL_PC,   'Pr. Compra',   True, ssahRight);
  if COL_PV >= 0 then
    W(Sheet, iRow, COL_PV,  'Pr. Venta',    True, ssahRight);
  for i := 1 to iNumTallas do
    W(Sheet, iRow, COL_T01 + i - 1,
      Format('T%.2d', [i]), True, ssahCenter);
  W(Sheet, iRow, COL_UDS,   'Uds.',    True, ssahRight);
  W(Sheet, iRow, COL_IMP,   'Importe', True, ssahRight);
  // Fondo gris oscuro para la cabecera
  for c := 0 to iColMax do
    if Sheet.Cells[iRow, c] <> nil then
    begin
      Sheet.Cells[iRow, c].Style.Font.Color := clWhite;
      Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := $00666666;
      Sheet.Cells[iRow, c].Style.Borders[bBottom].Style := sscbsThin;
    end;
  // --- Datos de lineas ---
  Inc(iRow);
  iFilaInicioLineas := iRow;
  if (QLineas <> nil) and QLineas.Active and (not QLineas.IsEmpty) then
  begin
    QLineas.DisableControls;
    try
    QLineas.First;
    while not QLineas.Eof do
    begin
      W(Sheet, iRow, COL_ART,
        QLineas.FieldByName('CODIGO_ART').AsString);
      W(Sheet, iRow, COL_REF,
        QLineas.FieldByName('REF_PRV').AsString);
      W(Sheet, iRow, COL_DESC,
        QLineas.FieldByName('DESCRIPCION').AsString);
      W(Sheet, iRow, COL_COLOR,
        QLineas.FieldByName('COLOR_TEXTO').AsString);
      W(Sheet, iRow, COL_SIS,
        QLineas.FieldByName('NOMBRE_CORTO_AC').AsString, False, ssahCenter);
      // Precio compra
      rVal := QLineas.FieldByName('PRECIO_COMPRA').AsFloat;
      W(Sheet, iRow, COL_PC, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_PC].Style.DataFormat.FormatCode := FMT_EUR;
      if COL_PV >= 0 then
      begin
        rVal := QLineas.FieldByName('PRECIO_VENTA').AsFloat;
        W(Sheet, iRow, COL_PV, rVal, False, ssahRight);
        Sheet.Cells[iRow, COL_PV].Style.DataFormat.FormatCode := FMT_EUR;
      end;
      // Tallas T01..T20
      for i := 1 to iNumTallas do
      begin
        sField := Format('T%.2d', [i]);
        if QLineas.FindField(sField) <> nil then
        begin
          rVal := QLineas.FieldByName(sField).AsFloat;
          if rVal > 0 then
          begin
            W(Sheet, iRow, COL_T01 + i - 1, rVal, False, ssahCenter);
            Sheet.Cells[iRow, COL_T01 + i - 1].Style.DataFormat.FormatCode :=
              '0';
          end;
        end;
      end;
      // Total unidades
      rVal := QLineas.FieldByName('TOTAL_UNIDADES').AsFloat;
      W(Sheet, iRow, COL_UDS, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_UDS].Style.DataFormat.FormatCode := '0';
      // Importe
      rVal := QLineas.FieldByName('TOTAL_LINEA').AsFloat;
      W(Sheet, iRow, COL_IMP, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_IMP].Style.DataFormat.FormatCode := FMT_EUR;
      Inc(iRow);
      QLineas.Next;
    end;
    finally
      QLineas.EnableControls;
    end;
  end;
  iFilaFinLineas := iRow - 1;
  // --- Fila de totales con formulas SUM ---
  if iFilaFinLineas >= iFilaInicioLineas then
  begin
    Inc(iRow);
    W(Sheet, iRow, COL_SIS, 'TOTALES', True, ssahRight);
    // SUM de cada columna talla
    for i := 1 to iNumTallas do
    begin
      c := COL_T01 + i - 1;
      WFormula(Sheet, iRow, c,
        '=SUM(' + GetRef(iFilaInicioLineas, c) + ':' +
                  GetRef(iFilaFinLineas, c) + ')',
        '0');
      Sheet.Cells[iRow, c].Style.Font.Style := [fsBold];
    end;
    // SUM total unidades
    WFormula(Sheet, iRow, COL_UDS,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_UDS) + ':' +
                GetRef(iFilaFinLineas, COL_UDS) + ')',
      '0');
    Sheet.Cells[iRow, COL_UDS].Style.Font.Style := [fsBold];
    // SUM importe
    WFormula(Sheet, iRow, COL_IMP,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_IMP) + ':' +
                GetRef(iFilaFinLineas, COL_IMP) + ')',
      FMT_EUR);
    Sheet.Cells[iRow, COL_IMP].Style.Font.Style := [fsBold];
    Sheet.Cells[iRow, COL_IMP].Style.Font.Size := 13;
    // Borde superior en fila de totales
    for c := COL_SIS to iColMax do
      if Sheet.Cells[iRow, c] <> nil then
        Sheet.Cells[iRow, c].Style.Borders[bTop].Style := sscbsThin;
  end;
  // --- Anchos de columna ---
  Sheet.Columns[COL_ART].Size   := 90;
  Sheet.Columns[COL_REF].Size   := 70;
  Sheet.Columns[COL_DESC].Size  := 180;
  Sheet.Columns[COL_COLOR].Size := 90;
  Sheet.Columns[COL_SIS].Size   := 50;
  Sheet.Columns[COL_PC].Size   := 75;
  if COL_PV >= 0 then
    Sheet.Columns[COL_PV].Size := 75;
  for i := 0 to iNumTallas - 1 do
    Sheet.Columns[COL_T01 + i].Size := 38;
  Sheet.Columns[COL_UDS].Size := 55;
  Sheet.Columns[COL_IMP].Size := 80;
  finally
    Sheet.EndUpdate;
  end;
end;

// ===== Exportacion vertical (una fila por SKU) ==============================

procedure ExportarDocCompraVertical(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet;
  const ACfg: TDocCompraCabCfg);
const
  COL_LINEA = 0;
  COL_ART   = 1;
  COL_SKU   = 2;
  COL_REF   = 3;
  COL_DESC  = 4;
  COL_CANT  = 5;
  COL_PREC  = 6;
  COL_TOTAL = 7;
var
  Sheet: TdxSpreadSheetTableView;
  iRow: Integer;
  iFilaInicioLineas, iFilaFinLineas: Integer;
  c: Integer;
  rVal: Double;
begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet(ACfg.Titulo,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Sheet.BeginUpdate;
  try
  // --- Cabecera ---
  PintarCabeceraDoc(Sheet, QMaster, ACfg, COL_TOTAL, iRow);
  // --- Cabecera de lineas ---
  Inc(iRow, 2);
  W(Sheet, iRow, COL_LINEA, 'Linea',        True, ssahCenter);
  W(Sheet, iRow, COL_ART,   'Articulo',     True, ssahCenter);
  W(Sheet, iRow, COL_SKU,   'SKU',          True, ssahCenter);
  W(Sheet, iRow, COL_REF,   'Ref. Prv.',    True, ssahCenter);
  W(Sheet, iRow, COL_DESC,  'Descripcion',  True, ssahCenter);
  W(Sheet, iRow, COL_CANT,  'Cant.',        True, ssahRight);
  W(Sheet, iRow, COL_PREC,  'Precio',       True, ssahRight);
  W(Sheet, iRow, COL_TOTAL, 'Total',        True, ssahRight);
  for c := COL_LINEA to COL_TOTAL do
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
        QLineas.FieldByName('LINEA_ALBCLIN').AsString, False, ssahCenter);
      W(Sheet, iRow, COL_ART,
        QLineas.FieldByName('CODIGO_ART_ALBCLIN').AsString);
      W(Sheet, iRow, COL_SKU,
        QLineas.FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString);
      if QLineas.FindField('REF_PRV_ALBCLIN') <> nil then
        W(Sheet, iRow, COL_REF,
          QLineas.FieldByName('REF_PRV_ALBCLIN').AsString);
      W(Sheet, iRow, COL_DESC,
        QLineas.FieldByName('DESCRIPCION_ARTICULO_ALBCLIN').AsString);
      // Cantidad
      rVal := QLineas.FieldByName('CANTIDAD_ALBCLIN').AsFloat;
      W(Sheet, iRow, COL_CANT, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_CANT].Style.DataFormat.FormatCode := '#,##0.##';
      // Precio compra sin IVA
      rVal := QLineas.FieldByName(
        'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN').AsFloat;
      W(Sheet, iRow, COL_PREC, rVal, False, ssahRight);
      Sheet.Cells[iRow, COL_PREC].Style.DataFormat.FormatCode := FMT_EUR;
      // Total linea (formula)
      WFormula(Sheet, iRow, COL_TOTAL,
        '=' + GetRef(iRow, COL_CANT) + '*' + GetRef(iRow, COL_PREC),
        FMT_EUR);
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
    // Total base imponible
    W(Sheet, iRow, COL_PREC, 'Total Base:', True, ssahRight);
    WFormula(Sheet, iRow, COL_TOTAL,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_TOTAL) + ':' +
                GetRef(iFilaFinLineas, COL_TOTAL) + ')',
      FMT_EUR);
    Sheet.Cells[iRow, COL_TOTAL].Style.Font.Style := [fsBold];
    // Total unidades
    W(Sheet, iRow, COL_DESC, 'Total Uds:', True, ssahRight);
    WFormula(Sheet, iRow, COL_CANT,
      '=SUM(' + GetRef(iFilaInicioLineas, COL_CANT) + ':' +
                GetRef(iFilaFinLineas, COL_CANT) + ')',
      '0');
    Sheet.Cells[iRow, COL_CANT].Style.Font.Style := [fsBold];
    var RefTotalBase := GetRef(iRow, COL_TOTAL);
    // IVA (si la cabecera tiene datos de impuestos)
    if (QMaster.FindField('TOTAL_IMPUESTOS_ALBC') <> nil) then
    begin
      Inc(iRow);
      W(Sheet, iRow, COL_PREC, 'Total IVA:', True, ssahRight);
      W(Sheet, iRow, COL_TOTAL,
        QMaster.FieldByName('TOTAL_IMPUESTOS_ALBC').AsFloat,
        False, ssahRight);
      Sheet.Cells[iRow, COL_TOTAL].Style.DataFormat.FormatCode := FMT_EUR;
      var RefTotalIVA := GetRef(iRow, COL_TOTAL);
      // Total liquido
      Inc(iRow);
      W(Sheet, iRow, COL_PREC, 'TOTAL:', True, ssahRight);
      WFormula(Sheet, iRow, COL_TOTAL,
        '=' + RefTotalBase + '+' + RefTotalIVA,
        FMT_EUR);
      Sheet.Cells[iRow, COL_TOTAL].Style.Font.Style := [fsBold];
      Sheet.Cells[iRow, COL_TOTAL].Style.Font.Size := 14;
    end;
  end;
  // --- Anchos de columna ---
  Sheet.Columns[COL_LINEA].Size := 45;
  Sheet.Columns[COL_ART].Size   := 90;
  Sheet.Columns[COL_SKU].Size   := 140;
  Sheet.Columns[COL_REF].Size   := 80;
  Sheet.Columns[COL_DESC].Size  := 220;
  Sheet.Columns[COL_CANT].Size  := 55;
  Sheet.Columns[COL_PREC].Size  := 75;
  Sheet.Columns[COL_TOTAL].Size := 85;
  finally
    Sheet.EndUpdate;
  end;
end;

end.
