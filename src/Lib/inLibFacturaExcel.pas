{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturaExcel                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exporta una factura a hoja dxSpreadSheet de DevExpress.                   }
{    Maqueta cabecera, líneas y desglose de impuestos sobre la plantilla.      }
{******************************************************************************}
unit inLibFacturaExcel;

interface

uses
   Uni, DB, System.SysUtils, System.Classes,
   dxSpreadSheet, dxSpreadSheetCore, cxGraphics, vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxSpreadSheetContainers, dxHashUtils,
  dxGDIPlusClasses, dxSmartImage, inLibDevExcel, inLibVerifactu;

procedure ExportarFacturaADevExpress(ASheetControl: TdxSpreadSheet;
                                              const QMaster, QLineas: TDataSet);


implementation

procedure ExportarFacturaADevExpress(ASheetControl: TdxSpreadSheet;
                                              const QMaster, QLineas: TDataSet);
const
  // Columnas Visibles
  COL_DESC   = 0; // A: Descripción / Base Imponible (en tabla inferior)
  COL_CANT   = 1; // B: CANTIDAD / Tipo IVA (en tabla inferior)
  COL_PRECIO = 2; // C: Precio / Cuota IVA (en tabla inferior)
  COL_PIVA   = 3; // D: % IVA / % RE (en tabla inferior)
  COL_TOTAL  = 4; // E: Total Línea / Total RE (en tabla inferior)
  // Columnas Técnicas (Ocultas)
  COL_BASEI  = 5; // F: Base Imponible real de cada línea
  COL_TIPO_L = 6; // G: Tipo de IVA Letra (N, R, S, E)
const
  COL_QR = 7; // H: QR tributario Verifactu (a la derecha de la cabecera)
var
  Sheet: TdxSpreadSheetTableView;
  iRow: Integer;
  PorcenREN, PorcenRER, PorcenRESR, PorcenREE: Double;
  TieneRE : Boolean;
  sTitulo : string;

  // QR tributario fiscal arriba a la derecha (mismas reglas que el
  // ticket y el A4: URL de cotejo/remisión calculada en local). En modo
  // SIN o si falta algún dato, no pone nada.
  procedure IncrustarQRVerifactu;
  var
    aPng:    TBytes;
    oStream: TBytesStream;
    img:     TdxSmartImage;
    Pic:     TdxSpreadSheetPictureContainer;
    sUrl:    string;
  begin
    // El QR es opcional: cualquier fallo aquí NO debe tumbar la
    // exportación de la factura a Excel.
    if SinVerifactuActivo or
       (QMaster.FindField('NIF_EMPRESA_FAC') = nil) or
       (QMaster.FindField('SERIE_FAC') = nil) or
       (QMaster.FindField('NUMERO_FAC') = nil) or
       (QMaster.FindField('FECHA_FAC') = nil) or
       (QMaster.FindField('TOTAL_LIQUIDO_FAC') = nil) or
       (Trim(QMaster.FieldByName('NUMERO_FAC').AsString) = '') then
      Exit;
    sUrl := ConstruirUrlQR(
              QMaster.FieldByName('NIF_EMPRESA_FAC').AsString,
              QMaster.FieldByName('SERIE_FAC').AsString,
              QMaster.FieldByName('NUMERO_FAC').AsString,
              QMaster.FieldByName('FECHA_FAC').AsDateTime,
              QMaster.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency);
    aPng := GenerarQRPngVerifactu(sUrl);
    if Length(aPng) = 0 then
      Exit;
    img     := nil;
    oStream := nil;
    try
      try
        img     := TdxSmartImage.Create;
        oStream := TBytesStream.Create(aPng);
        oStream.Position := 0;
        img.LoadFromStream(oStream);
        if (img.Width > 0) and (img.Height > 0) then
        begin
          Pic := Sheet.Containers.Add(TdxSpreadSheetPictureContainer)
                   as TdxSpreadSheetPictureContainer;
          if Pic <> nil then
          begin
            Pic.Picture.Image := img; // el contenedor copia la imagen
            Pic.AnchorType := catTwoCell;
            Pic.AnchorPoint1.Cell := Sheet.CreateCell(1, COL_QR);
            Pic.AnchorPoint2.Cell := Sheet.CreateCell(7, COL_QR + 1);
            // Columna H ancha para que el QR quede ~cuadrado
            Sheet.Columns[COL_QR].Size := 120;
          end;
        end;
      except
        // QR opcional: si falla la incrustación, la factura sale sin QR
      end;
    finally
      FreeAndNil(oStream);
      FreeAndNil(img);
    end;
  end;

  procedure PintarImpuesto(TipoLetra: string; PctIVA, PctRE: Double;
                           RangoTL, RangoBR: String);
  var
    RefBase: string;
  begin
     Inc(iRow);
     WFormula(Sheet, iRow, COL_DESC,
              '=SUMIF(' + RangoTL + ';"' + TipoLetra + '";' + RangoBR + ')',
              '#,##0.00" €"');
     RefBase := GetRef(iRow, COL_DESC);
     W(Sheet, iRow, COL_CANT, PctIVA, False, ssahCenter);
     if Frac(PctIVA) = 0 then
       Sheet.Cells[iRow, COL_CANT].Style.DataFormat.FormatCode := '0"%"'
     else
       Sheet.Cells[iRow, COL_CANT].Style.DataFormat.FormatCode := '0.##"%"';
     WFormula(Sheet, iRow, COL_PRECIO,
              '=' + RefBase + '*' + FloatToStr(PctIVA) + '/100',
              '#,##0.00" €"');
     if PctRE > 0 then
     begin
       W(Sheet, iRow, COL_PIVA, PctRE, False, ssahCenter);
       Sheet.Cells[iRow, COL_PIVA].Style.DataFormat.FormatCode := '0.##"%"';
       WFormula(Sheet, iRow, COL_TOTAL, '=' + RefBase + '*' +
                GetRef(iRow, COL_PIVA) + '/100',
                '#,##0.00" €"');
     end
     else
     begin
       W(Sheet, iRow, COL_PIVA, '', False, ssahCenter);
       W(Sheet, iRow, COL_TOTAL, '', False, ssahCenter);
     end;
  end;

begin
  ASheetControl.ClearAll;
  TieneRE := QMaster.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString = 'S';
  Sheet := ASheetControl.AddSheet('Factura',
                            TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Sheet.BeginUpdate;
  try
  if not QMaster.FieldByName('NUMERO_FAC').IsNull then
    Sheet.Caption := 'Factura ' + QMaster.FieldByName('SERIE_FAC').AsString
                     + '_' + QMaster.FieldByName('NUMERO_FAC').AsString;
  var ImpuestosIncluidos :=
      (QMaster.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString = 'S');
  // Título según el tipo de factura del registro
  sTitulo := 'FACTURA';
  if QMaster.FindField('TIPO_FAC') <> nil then
  begin
    if SameText(QMaster.FieldByName('TIPO_FAC').AsString,
                'SIMPLIFICADA') then
      sTitulo := 'FACTURA SIMPLIFICADA'
    else if SameText(QMaster.FieldByName('TIPO_FAC').AsString,
                     'RECTIFICATIVA') then
      sTitulo := 'FACTURA RECTIFICATIVA';
  end;
  W(Sheet, 1, COL_DESC, sTitulo, True);
  Sheet.Cells[1, COL_DESC].Style.Font.Size := 18;
  IncrustarQRVerifactu;
  W(Sheet, 1, COL_TOTAL, 'Fecha: ' +
               QMaster.FieldByName('FECHA_FAC').AsString, False, ssahRight);
  W(Sheet, 2, COL_TOTAL, 'Número: ' +
                           QMaster.FieldByName('SERIE_FAC').AsString + '.' +
                  QMaster.FieldByName('NUMERO_FAC').AsString, True, ssahRight);
  W(Sheet, 4, COL_DESC, 'EMISOR', True); // Negrita
  W(Sheet, 5, COL_DESC, QMaster.FieldByName(
                                       'RAZON_SOCIAL_EMPRESA_FAC').AsString);
  Merge(Sheet, 5, COL_DESC, 3, 1);
  W(Sheet, 6, COL_DESC, 'NIF: ' + QMaster.FieldByName(
                                               'NIF_EMPRESA_FAC').AsString);
  Merge(Sheet, 6, COL_DESC, 3, 1);
  W(Sheet, 7, COL_DESC, QMaster.FieldByName(
                                        'DIRECCION1_EMPRESA_FAC').AsString);
  Merge(Sheet, 7, COL_DESC, 3, 1);
  W(Sheet,
    8,
    COL_DESC,
    QMaster.FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString
            +  ' ' + QMaster.FieldByName('POBLACION_EMPRESA_FAC').AsString);
  Merge(Sheet, 8, COL_DESC, 3, 1);
  W(Sheet, 4, COL_PIVA, 'RECEPTOR', True); // Negrita
  W(Sheet, 5, COL_PIVA, QMaster.FieldByName(
                                       'RAZON_SOCIAL_CLIENTE_FAC').AsString);
  Merge(Sheet, 5, COL_PIVA, 2, 1);
  W(Sheet, 6, COL_PIVA, 'NIF: ' + QMaster.FieldByName(
                                               'NIF_CLIENTE_FAC').AsString);
  Merge(Sheet, 6, COL_PIVA, 2, 1);
  W(Sheet, 7, COL_PIVA, QMaster.FieldByName(
                                        'DIRECCION1_CLIENTE_FAC').AsString);
  Merge(Sheet, 7, COL_PIVA, 2, 1);
  W(Sheet, 8, COL_PIVA,
    QMaster.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString + ' ' +
    QMaster.FieldByName('POBLACION_CLIENTE_FAC').AsString);
  Merge(Sheet, 8, COL_PIVA, 2, 1);
  iRow := 11;
  W(Sheet, iRow, COL_DESC,   'Descripción', True);
  W(Sheet, iRow, COL_CANT,   'Cantidad',    True, ssahRight);
  W(Sheet, iRow, COL_PRECIO, 'Precio',      True, ssahRight);
  W(Sheet, iRow, COL_PIVA,   '% IVA',       True, ssahRight);
  W(Sheet, iRow, COL_TOTAL,  'Total',       True, ssahRight);
  // Bordes cabecera
  for var c := COL_DESC to COL_TOTAL do
    if Sheet.Cells[iRow, c] <> nil then
      Sheet.Cells[iRow, c].Style.Borders[bBottom].Style := sscbsThin;
  var FilaInicioLineas := iRow + 1;
  QLineas.DisableControls;
  try
  QLineas.First;
  while not QLineas.Eof do
  begin
    Inc(iRow);
    // Col A: Descripción
    with Sheet.CreateCell(iRow, COL_DESC) do
    begin
      AsString :=
             QLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
      Style.WordWrap := True;
      Style.AlignVert := ssavTop;
    end;
    W(Sheet, iRow, COL_CANT,
      QLineas.FieldByName('CANTIDAD_FACLIN').AsFloat, False, ssahRight);
    Sheet.Cells[iRow, COL_CANT].Style.AlignVert := ssavTop;
    W(Sheet, iRow, COL_PRECIO,
        QLineas.FieldByName('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat,
        False, ssahRight);
    Sheet.Cells[iRow, COL_PRECIO].Style.AlignVert := ssavTop;
    W(Sheet, iRow, COL_PIVA,
      QLineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsFloat,
      False, ssahRight);
    Sheet.Cells[iRow, COL_PIVA].Style.AlignVert := ssavTop;
    if Sheet.Cells[iRow, COL_PIVA] <> nil then
       Sheet.Cells[iRow, COL_PIVA].Style.DataFormat.FormatCode := '0.##"%"';
    WFormula(Sheet, iRow, COL_TOTAL,
             '=' + GetRef(iRow, COL_CANT) + '*' + GetRef(iRow, COL_PRECIO),
             '#,##0.00" €"');
    Sheet.Cells[iRow, COL_TOTAL].Style.AlignVert := ssavTop;
    if ImpuestosIncluidos then
       WFormula(Sheet, iRow, COL_BASEI, '=' + GetRef(iRow, COL_TOTAL) +
                                      '/(1+' + GetRef(iRow, COL_PIVA) + '/100)')
    else
       WFormula(Sheet, iRow, COL_BASEI, '=' + GetRef(iRow, COL_TOTAL));
    W(Sheet, iRow, COL_TIPO_L, QLineas.FieldByName(
                 'TIPO_IVA_ARTICULO_FACLIN').AsString, False, ssahCenter);
    QLineas.Next;
  end;
  finally
    QLineas.EnableControls;
  end;

  var FilaFinLineas := iRow;
  Inc(iRow, 3);
  var RowInicioTabla := iRow;

  // RANGOS PARA LOS SUMIF (Usando las constantes de columnas ocultas)
  var RangoBasesReales := GetRef(FilaInicioLineas, COL_BASEI, True) + ':' +
                          GetRef(FilaFinLineas, COL_BASEI, True);
  var RangoTiposLetra  := GetRef(FilaInicioLineas, COL_TIPO_L, True) + ':' +
                          GetRef(FilaFinLineas, COL_TIPO_L, True);

  // --- TABLA DETALLADA DE IMPUESTOS ---
  W(Sheet, iRow, COL_DESC,   'Base Imponible', True, ssahRight);
  W(Sheet, iRow, COL_CANT,   'Tipo IVA',       True, ssahRight);
  W(Sheet, iRow, COL_PRECIO, 'Cuota IVA',      True, ssahRight);
  if TieneRE then
  begin
    W(Sheet, iRow, COL_PIVA,  '% RE',    True, ssahRight);
    W(Sheet, iRow, COL_TOTAL, 'Total RE', True, ssahRight);
  end
  else
  begin
    // Limpiar o dejar vacío si no hay RE
    W(Sheet, iRow, COL_PIVA,  '', False);
    W(Sheet, iRow, COL_TOTAL, '', False);
  end;

  for var b := 0 to 4 do
    if Sheet.Cells[iRow, b] <> nil then
       Sheet.Cells[iRow, b].Style.Borders[bBottom].Style := sscbsThin;
  if TieneRE then
  begin
    PorcenREN := QMaster.FieldByName('PORCENTAJE_REN_FAC').AsFloat;
    PorcenRER := QMaster.FieldByName('PORCENTAJE_RER_FAC').AsFloat;
    PorcenRESR := QMaster.FieldByName('PORCENTAJE_RES_FAC').AsFloat;
    PorcenREE := QMaster.FieldByName('PORCENTAJE_REE_FAC').AsFloat;
  end
  else
  begin
    PorcenREN := 0;
    PorcenRER := 0;
    PorcenRESR := 0;
    PorcenREE := 0;
  end;
  if QMaster.FieldByName('TOTAL_BASEI_IVAN_FAC').AsFloat > 0 then
      PintarImpuesto('N', QMaster.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat,
                      PorcenREN,
                      RangoTiposLetra, RangoBasesReales);
  if QMaster.FieldByName('TOTAL_BASEI_IVAR_FAC').AsFloat > 0 then
      PintarImpuesto('R', QMaster.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat,
                      PorcenRER,
                      RangoTiposLetra, RangoBasesReales);
  if QMaster.FieldByName('TOTAL_BASEI_IVAS_FAC').AsFloat > 0 then
      PintarImpuesto('S', QMaster.FieldByName('PORCENTAJE_IVAS_FAC').AsFloat,
                      PorcenRESR,
                      RangoTiposLetra, RangoBasesReales);
  if QMaster.FieldByName('TOTAL_BASEI_IVAE_FAC').AsFloat > 0 then
      PintarImpuesto('E', QMaster.FieldByName('PORCENTAJE_IVAE_FAC').AsFloat,
                      PorcenREE,
                      RangoTiposLetra, RangoBasesReales);
  var RowFinTabla := iRow;

  // --- RESUMEN FINAL ---
  Inc(iRow, 2);

  // 1. TOTAL BASE IMPONIBLE
  W(Sheet, iRow, COL_PIVA, 'Total Base Imponible:', True, ssahRight);
  with Sheet.CreateCell(iRow, COL_TOTAL) do
  begin
    SetText('=SUM(' + GetRef(RowInicioTabla + 1, COL_DESC) + ':' +
                                     GetRef(RowFinTabla, COL_DESC) + ')', True);
    Style.DataFormat.FormatCode := '#,##0.00" €"';
    Style.AlignHorz := ssahRight;
  end;
  var RefTotalBase := GetRef(iRow, COL_TOTAL);
  Inc(iRow);
  W(Sheet, iRow, COL_PIVA, 'Total Impuestos (IVA+RE):', True, ssahRight);
  with Sheet.CreateCell(iRow, COL_TOTAL) do
  begin
    SetText('=SUM(' + GetRef(RowInicioTabla + 1, COL_PRECIO) + ':' +
                                        GetRef(RowFinTabla, COL_PRECIO) + ')+' +
            'SUM(' + GetRef(RowInicioTabla + 1, COL_TOTAL) + ':' +
                                    GetRef(RowFinTabla, COL_TOTAL) + ')', True);
    Style.DataFormat.FormatCode := '#,##0.00" €"';
    Style.AlignHorz := ssahRight;
  end;
  var RefTotalImpuestos := GetRef(iRow, COL_TOTAL);
  var RefRetenciones := '';
  if Abs(QMaster.FieldByName('TOTAL_RETENCION_FAC').AsFloat) > 0.001 then
  begin
     Inc(iRow);
     W(Sheet, iRow, COL_BASEI, QMaster.FieldByName(
                   'PORCENTAJE_RETENCION_FAC').AsFloat);
     WFormula(Sheet, iRow, COL_PIVA, '="Retención IRPF ("&' +
                                            GetRef(iRow, COL_BASEI) + '&"%):"');
     with Sheet.CreateCell(iRow, COL_TOTAL) do
     begin
       SetText('=-(' + RefTotalBase + '*' +
                                       GetRef(iRow, COL_BASEI) + '/100)', True);
       Style.Font.Color := clRed;
       Style.AlignHorz := ssahRight;
       Style.DataFormat.FormatCode := '#,##0.00" €"';
     end;
     RefRetenciones := GetRef(iRow, COL_TOTAL);
  end;
  Inc(iRow);
  W(Sheet, iRow, COL_PIVA, 'TOTAL A PAGAR:', True, ssahRight);
  with Sheet.CreateCell(iRow, COL_TOTAL) do
  begin
    var FormulaStr := '=' + RefTotalBase + '+' + RefTotalImpuestos;
    if RefRetenciones <> '' then
                                FormulaStr := FormulaStr + '+' + RefRetenciones;
    SetText(FormulaStr, True);
    Style.Font.Style := [fsBold];
    Style.Font.Size := 14;
    Style.DataFormat.FormatCode := '#,##0.00" €"';
    Style.AlignHorz := ssahRight;
  end;
  Inc(iRow, 2);
  with Sheet.CreateCell(iRow, COL_DESC) do
  begin
    AsString := 'Forma de Pago:';
    Style.Font.Style := [fsBold];
    Style.AlignVert := ssavCenter;
  end;
  with Sheet.CreateCell(iRow, COL_CANT) do
  begin
    AsString := QMaster.FieldByName('FORMA_PAGO_FAC').AsString;
    Style.AlignVert := ssavCenter;
    Style.AlignHorz := ssahLeft;
    Style.WordWrap := False;
  end;
  Merge(Sheet, iRow, COL_CANT, 4, 1);
  Sheet.Columns[COL_DESC].Size := 280;
  Sheet.Columns[COL_CANT].Size := 60;
  Sheet.Columns[COL_PRECIO].Size := 80;
  Sheet.Columns[COL_PIVA].Size := 180;
  Sheet.Columns[COL_TOTAL].Size := 110;
  Sheet.Columns[COL_BASEI].Visible := False;
  Sheet.Columns[COL_TIPO_L].Visible := False;
  finally
    Sheet.EndUpdate;
  end;
end;

end.
