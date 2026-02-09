{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoModalImpFac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxClass,
  frxExportBaseDialog, frxExportPDF, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls,
  cxControls, cxContainer, cxEdit, Vcl.ComCtrls, dxCore, cxDateUtils,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxRadioGroup, cxGroupBox, cxLabel,
  cxTextEdit, UniDataFacturas, inMtoFacturas, DB, frxExportXLSX, MemDS,
  DBAccess, Uni, frxDesgn, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  dxSkinsCore, dxSkinBlue, JvComponentBase, JvEnterTab, dxSkinBasic,
  dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue,   dxSpreadSheet, dxSpreadSheetCore,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxHashUtils;

type
  TfrmPrintFac = class(TfrmPrint)
    edtNroFac: TcxTextEdit;
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbRangoFechas: TcxRadioButton;
    dedDesde: TcxDateEdit;
    dedHasta: TcxDateEdit;
    lblcxlbl2: TcxLabel;
    lblcxlbl3: TcxLabel;
    procedure rbRangoFechasClick(Sender: TObject);
    procedure rbActualClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  public
    procedure preparar_consulta; override;
    procedure ConfigurarNombrePDF;
    function ObtenerNombreFactura(ADataSet: TDataSet;
                                  const AExtension: string): string;
    procedure ExportarFacturaADevExpress(ASheetControl: TdxSpreadSheet;
                                         const QMaster, QLineas: TDataSet);
  public
    { Public declarations }
  end;

var
  frmPrintFac: TfrmPrintFac;

implementation

{$R *.dfm}

uses inMtoPreviewExcel;

{ TfrmPrintFac }

procedure TfrmPrintFac.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel; // El formulario que creaste en el paso 1
begin
  fPreview := TfrmMtoPreviewExcel.Create(Application);
  try
    var NombreSugerido := ObtenerNombreFactura(dmmFacturas.unqryTablaG,
                                               '.xlsx');
    fPreview.DialogoGuardar.FileName := NombreSugerido;
    ExportarFacturaADevExpress(fPreview.dxSpreadSheet1,
                               dmmFacturas.unqryTablaG,
                               dmmFacturas.unqryLinFac);
    fPreview.ShowModal;
  finally
    fPreview.Free;
  end;
end;

procedure TfrmPrintFac.ExportarFacturaADevExpress(ASheetControl: TdxSpreadSheet;
                                                  const QMaster,
                                                        QLineas: TDataSet);
var
  //SSheet: TdxSpreadSheet;
  Sheet: TdxSpreadSheetTableView;
  iRow: Integer;
  Cell: TdxSpreadSheetCell;
  NombreSugerido: string;

  procedure Merge(ARow, ACol, ColCount, RowCount: Integer);
  begin
    // TRect.Create(Left, Top, Right, Bottom)
    var R := Rect(ACol, ARow, ACol + ColCount - 1, ARow + RowCount - 1);
    Sheet.MergedCells.Add(R);
  end;

  // Helper para escribir celdas
  procedure W(ARow, ACol: Integer;
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

  procedure WFormula(ARow, ACol: Integer;
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
  function GetRef(R, C: Integer; Absolute: Boolean = False): string;
  var
    ColStr: string;
  begin
    // Convertimos 0->A, 1->B...
    ColStr := Chr(Ord('A') + C);
    if Absolute then
      Result := '$' + ColStr + '$' + IntToStr(R + 1)
    else
      Result := ColStr + IntToStr(R + 1);
  end;

  procedure PintarImpuesto(TipoLetra: string; PctIVA, PctRE: Double;
                         RangoTL, RangoBR: String);
  var RefBase: string;
  begin
     Inc(iRow);

     // 1. EL PORCENTAJE DE IVA
     W(iRow, 1, PctIVA, False, ssahCenter);
     // APLICAMOS EL TRUCO: Comillas alrededor del %
     if Frac(PctIVA) = 0 then
       Sheet.Cells[iRow, 1].Style.DataFormat.FormatCode := '0"%"'
     else
       Sheet.Cells[iRow, 1].Style.DataFormat.FormatCode := '0.##"%"';
     // ... (Tu SUMIF y Cuota IVA siguen igual) ...
     WFormula(iRow, 0, '=SUMIF(' + RangoTL + ';"' + TipoLetra + '";' + RangoBR +
                                                           ')', '#,##0.00" €"');
     RefBase := GetRef(iRow, 0);
     WFormula(iRow, 2, '=' + RefBase + '*' + FloatToStr(PctIVA) + '/100',
                                                                '#,##0.00" €"');
     if PctRE > 0 then
     begin
       W(iRow, 3, PctRE, False, ssahCenter);
       if Frac(PctRE) = 0 then
            Sheet.Cells[iRow, 3].Style.DataFormat.FormatCode := '0"%"'
         else
            Sheet.Cells[iRow, 3].Style.DataFormat.FormatCode := '0.##"%"';
       WFormula(iRow, 4, '=' + RefBase + '*' + GetRef(iRow, 3) + '/100',
                                                                '#,##0.00" €"');
     end
     else
     begin
       W(iRow, 3, '-', False, ssahCenter);
       W(iRow, 4, '-', False, ssahCenter);
     end;
  end;

begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Factura', TdxSpreadSheetTableView)
                                                     as TdxSpreadSheetTableView;
  if not QMaster.FieldByName('NRO_FACTURA').IsNull then
    Sheet.Caption := 'Factura ' + QMaster.FieldByName('NRO_FACTURA').AsString;
  var ImpuestosIncluidos :=
    (QMaster.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FACTURA').AsString = 'S');
  // --- ENCABEZADO ---
  W(1, 0, 'FACTURA', True);
  Sheet.Cells[1, 0].Style.Font.Size := 18;

  W(1, 4, 'Fecha: ' + QMaster.FieldByName('FECHA_FACTURA').AsString,
           False, ssahRight);
  W(2, 4, 'Número: ' + QMaster.FieldByName('SERIE_FACTURA').AsString + '.' +
           QMaster.FieldByName('NRO_FACTURA').AsString, True, ssahRight);

  // --- EMISOR Y RECEPTOR ---
  W(4, 0, 'EMISOR', True);
  Merge(4, 0, 3, 1);
  W(5, 0, QMaster.FieldByName('RAZONSOCIAL_EMPRESA_FACTURA').AsString);
  Merge(5, 0, 3, 1);
  W(6, 0, 'NIF: ' + QMaster.FieldByName('NIF_EMPRESA_FACTURA').AsString);
  W(7, 0, QMaster.FieldByName('DIRECCION1_EMPRESA_FACTURA').AsString);
  W(8, 0, QMaster.FieldByName('CPOSTAL_EMPRESA_FACTURA').AsString + ' ' + QMaster.FieldByName('POBLACION_EMPRESA_FACTURA').AsString);

  W(4, 3, 'RECEPTOR', True);
  Merge(4, 3, 2, 1);
  W(5, 3, QMaster.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString);
  Merge(5, 3, 2, 1);
  W(6, 3, 'NIF: ' + QMaster.FieldByName('NIF_CLIENTE_FACTURA').AsString);
  Merge(6, 3, 2, 1);
  W(7, 3, QMaster.FieldByName('DIRECCION1_CLIENTE_FACTURA').AsString);
  Merge(7, 3, 2, 1);
  W(8, 3, QMaster.FieldByName('CPOSTAL_CLIENTE_FACTURA').AsString + ' ' + QMaster.FieldByName('POBLACION_CLIENTE_FACTURA').AsString);
  Merge(8, 3, 2, 1);
  // --- TABLA DE LÍNEAS (CORREGIDO: 5 COLUMNAS AHORA) ---
  iRow := 11;
  W(iRow, 0, 'Descripción', True);   // Col A
  W(iRow, 1, 'Cantidad', True, ssahRight); // Col B (Antes estaba vacía)
  W(iRow, 2, 'Precio', True, ssahRight);   // Col C
  W(iRow, 3, '% IVA', True, ssahRight);    // Col D (Nueva)
  W(iRow, 4, 'Total', True, ssahRight);    // Col E
  // Columnas Ocultas (Títulos para referencia)
  W(iRow, 6, 'Tipo Letra', False); // Col G (Oculta)

  // Bordes inferiores cabecera
  if Sheet.Cells[iRow, 0] <> nil then
               Sheet.Cells[iRow, 0].Style.Borders[bBottom].Style := sscbsThin;
  if Sheet.Cells[iRow, 1] <> nil then
               Sheet.Cells[iRow, 1].Style.Borders[bBottom].Style := sscbsThin;
  if Sheet.Cells[iRow, 2] <> nil then
               Sheet.Cells[iRow, 2].Style.Borders[bBottom].Style := sscbsThin;
  if Sheet.Cells[iRow, 3] <> nil then
               Sheet.Cells[iRow, 3].Style.Borders[bBottom].Style := sscbsThin;
  if Sheet.Cells[iRow, 4] <> nil then
               Sheet.Cells[iRow, 4].Style.Borders[bBottom].Style := sscbsThin;
  var FilaInicioLineas := iRow + 1;
  QLineas.First;
  while not QLineas.Eof do
  begin
    Inc(iRow);
    // Col A: Descripción
    with Sheet.CreateCell(iRow, 0) do
    begin
      AsString :=
           QLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
      Style.WordWrap := True;
    end;

    // Col B: Cantidad
    W(iRow, 1,
      QLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat,
      False, ssahRight);

    // Col C: Precio Unitario
    W(iRow, 2,
      QLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsFloat,
      False, ssahRight);

    // Col D: % IVA (Desde la línea)
    W(iRow, 3,
      QLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat,
      False, ssahRight);
    if Sheet.Cells[iRow, 3] <> nil then
       Sheet.Cells[iRow, 3].Style.DataFormat.FormatCode := '0.##"%"';

    // Col E: Total Línea
//    W(iRow, 4,
//      QLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsFloat,
//      False, ssahRight);
    WFormula(iRow, 4, '=' + GetRef(iRow, 1) + '*' +
                                             GetRef(iRow, 2), '#,##0.00" €"');
    // Formatos
    if Sheet.Cells[iRow, 2] <> nil then
      Sheet.Cells[iRow, 2].Style.DataFormat.FormatCode := '#,##0.00" €"';
    if Sheet.Cells[iRow, 4] <> nil then
      Sheet.Cells[iRow, 4].Style.DataFormat.FormatCode := '#,##0.00" €"';
    if ImpuestosIncluidos then
    begin
       // Caso IVA INCLUIDO: Base = Total / (1 + %/100)
       // Ejemplo: 121 / 1.21 = 100
       WFormula(iRow, 5, '=' + GetRef(iRow, 4) + '/(1+' + GetRef(iRow, 3) +
                                                                     '/100)');
    end
    else
    begin
       // Caso IVA NO INCLUIDO: Base = Total
       WFormula(iRow, 5, '=' + GetRef(iRow, 4));
    end;

    // G: TIPO IVA LETRA (Columna G - Oculta)
    W(iRow, 6, QLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString,
      False, ssahCenter);
    QLineas.Next;
  end;
  var FilaFinLineas := iRow;
  Inc(iRow, 3);
  var RowInicioTabla := iRow;
  var RangoBasesReales :=
     GetRef(FilaInicioLineas, 5, True) + ':' + GetRef(FilaFinLineas, 5, True);
  var RangoTiposLetra  :=
     GetRef(FilaInicioLineas, 6, True) + ':' + GetRef(FilaFinLineas, 6, True);
  // ==========================================
  // 1. TABLA DETALLADA DE IMPUESTOS (Izquierda)
  // ==========================================
  W(iRow, 0, 'Base Imponible', True, ssahRight);
  W(iRow, 1, 'Tipo IVA', True, ssahRight);
  W(iRow, 2, 'Cuota IVA', True, ssahRight);
  W(iRow, 3, '% RE', True, ssahRight);
  W(iRow, 4, 'Total RE', True, ssahRight);
  var FilaInicioTablaImp := iRow;
  // Bordes inferiores cabecera impuestos
  for var i := 0 to 4 do
    if Sheet.Cells[iRow, i] <> nil then
       Sheet.Cells[iRow, i].Style.Borders[bBottom].Style := sscbsThin;

  // Iteramos por los tipos de IVA (Normal, Reducido, Super)
  if QMaster.FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsFloat > 0 then
     PintarImpuesto('N', QMaster.FieldByName('PORCEN_IVAN_FACTURA').AsFloat,
                    QMaster.FieldByName('PORCEN_REN_FACTURA').AsFloat,
                    RangoTiposLetra, RangoBasesReales);

  if QMaster.FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsFloat > 0 then
     PintarImpuesto('R', QMaster.FieldByName('PORCEN_IVAR_FACTURA').AsFloat,
                    QMaster.FieldByName('PORCEN_RER_FACTURA').AsFloat,
                    RangoTiposLetra, RangoBasesReales );

  if QMaster.FieldByName('TOTAL_BASEI_IVAS_FACTURA').AsFloat > 0 then
     PintarImpuesto('S', QMaster.FieldByName('PORCEN_IVAS_FACTURA').AsFloat,
                    QMaster.FieldByName('PORCEN_RES_FACTURA').AsFloat,
                    RangoTiposLetra, RangoBasesReales);

  // Si hay Exento (E)
  if QMaster.FieldByName('TOTAL_BASEI_IVAE_FACTURA').AsFloat > 0 then
     PintarImpuesto('E', 0, 0, RangoTiposLetra, RangoBasesReales);

  var FilaFinTablaImp := iRow;

  // Marco Light
  PintarCuadro(Sheet, FilaInicioTablaImp, 0, FilaFinTablaImp, 4, sscbsThin);
  var RowFinTabla: Integer := iRow;
  PintarCuadro(Sheet, RowInicioTabla, 0, RowFinTabla, 4, sscbsMedium);

  // ==========================================
  // 4. RESUMEN FINAL CON FÓRMULAS
  // ==========================================
  Inc(iRow, 2);

  // A. TOTAL BASE IMPONIBLE (Fórmula SUM de la columna 0 del cuadro)
  W(iRow, 3, 'Total Base Imponible:', True, ssahRight);

  with Sheet.CreateCell(iRow, 4) do
  begin
    // Fórmula: =SUM(A_Inicio : A_Fin)
    SetText('=SUM(' + GetRef(RowInicioTabla + 1, 0) + ':' +
            GetRef(RowFinTabla, 0) + ')', True);
    Style.DataFormat.FormatCode := '#,##0.00" €"';
    Style.AlignHorz := ssahRight;
  end;
  var RefTotalBase := GetRef(iRow, 4); // Guardamos "E15" (ejemplo) para usarlo luego

  // B. TOTAL IMPUESTOS (Fórmula SUM Columna Cuota + SUM Columna RE)
  Inc(iRow);
  W(iRow, 3, 'Total Impuestos (IVA+RE):', True, ssahRight);

  with Sheet.CreateCell(iRow, 4) do
  begin
    // Fórmula: =SUM(C_Inicio : C_Fin) + SUM(E_Inicio : E_Fin)
    // Col 2 es 'C' (Cuota), Col 4 es 'E' (RE)
    SetText('=SUM(' + GetRef(RowInicioTabla + 1, 2) + ':' +
             GetRef(RowFinTabla, 2) + ')+' +
             'SUM(' + GetRef(RowInicioTabla + 1, 4) + ':' +
             GetRef(RowFinTabla, 4) + ')', True);
    Style.DataFormat.FormatCode := '#,##0.00" €"';
    Style.AlignHorz := ssahRight;
  end;
  var RefTotalImpuestos := GetRef(iRow, 4);

  // C. RETENCIONES (Calculada sobre el total de base imponible)
  var RefRetenciones := '';
  if Abs(QMaster.FieldByName('TOTAL_RETENCION_FACTURA').AsFloat) > 0.001 then
  begin
     Inc(iRow);
     var PctIRPF: Double :=
                      QMaster.FieldByName('PORCEN_RETENCION_FACTURA').AsFloat;

     // Ponemos el % IRPF en columna 5 (oculta pero editable)
     W(iRow, 5, PctIRPF, False, ssahCenter);

     // Título con fórmula que concatena el % desde la columna 5
     with Sheet.CreateCell(iRow, 3) do
     begin
       SetText('="Retención IRPF ("&' + GetRef(iRow, 5) + '&"%):"', True);
       Style.Font.Style := [fsBold];
       Style.AlignHorz := ssahRight;
     end;

     // Fórmula: Total Base * Celda_F / 100 (negativo)
     with Sheet.CreateCell(iRow, 4) do
     begin
       SetText('=-(' + RefTotalBase + '*' + GetRef(iRow, 5) + '/100)', True);
       Style.DataFormat.FormatCode := '#,##0.00" €"';
       Style.Font.Color := clRed;
       Style.AlignHorz := ssahRight;
     end;

     RefRetenciones := GetRef(iRow, 4);
  end;

  // D. TOTAL A PAGAR (Fórmula suma de los anteriores)
  Inc(iRow);
  W(iRow, 3, 'TOTAL A PAGAR:', True, ssahRight);
  with Sheet.CreateCell(iRow, 4) do
  begin
    var FormulaStr: string := '=' + RefTotalBase + '+' + RefTotalImpuestos;
    if RefRetenciones <> '' then
       FormulaStr := FormulaStr + '+' + RefRetenciones;
    SetText(FormulaStr, True);
    Style.Font.Style := [fsBold];
    Style.Font.Size := 14;
    Style.DataFormat.FormatCode := '#,##0.00" €"';
    Style.AlignHorz := ssahRight;
  end;
  PintarCuadro(Sheet, iRow, 4, iRow, 4, sscbsMedium);
  // --- FORMA DE PAGO ---
  Inc(iRow, 3);
  W(iRow, 0, 'Forma de Pago: ' +
    QMaster.FieldByName('FORMA_PAGO_FACTURA').AsString, True);
  Sheet.Columns[0].Size := 280; // Base
  Sheet.Columns[1].Size := 60;  // Tipo
  Sheet.Columns[2].Size := 80;  // Cuota
  Sheet.Columns[3].Size := 180; // Etiqueta ancha ("Total Impuestos...")
  Sheet.Columns[4].Size := 110; // Importes finales
  Sheet.Columns.CreateItem(5);
  Sheet.Columns.CreateItem(6);
  if Sheet.Columns[5] <> nil then
    Sheet.Columns[5].Visible := False;
  if Sheet.Columns[6] <> nil then
    Sheet.Columns[6].Visible := False;
end;

procedure TfrmPrintFac.ConfigurarNombrePDF;
begin
  frxpdfxprtPedWeb.FileName := ObtenerNombreFactura(dmmFacturas.unqrytablaG,
                                                    'pdf');
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet; const AExtension: string): string;
var
  RazonSocialCorta: string;
  sFecha: string;
  TotalFormateado: string;
  SerieFormateada: string;
  sNro: string;
begin
  // 1. Razón Social (Primeros 12 caracteres, sin espacios)
  RazonSocialCorta := Copy(ADataSet.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString, 1, 12);
  RazonSocialCorta := StringReplace(RazonSocialCorta, ' ', '', [rfReplaceAll]);

  // 2. Fecha (dd_mm)
  if not ADataSet.FieldByName('FECHA_FACTURA').IsNull then
    sFecha := FormatDateTime('dd_mm', ADataSet.FieldByName('FECHA_FACTURA').AsDateTime)
  else
    sFecha := '00_00';

  // 3. Total (0.00, cambiando , y . por _)
  TotalFormateado := FormatFloat('0.00', ADataSet.FieldByName('TOTAL_LIQUIDO_FACTURA').AsFloat);
  TotalFormateado := StringReplace(TotalFormateado, ',', '_', [rfReplaceAll]);
  TotalFormateado := StringReplace(TotalFormateado, '.', '_', [rfReplaceAll]);

  // 4. Serie (cambiando . por _)
  SerieFormateada := StringReplace(ADataSet.FieldByName('SERIE_FACTURA').AsString, '.', '_', [rfReplaceAll]);

  // 5. Número
  sNro := ADataSet.FieldByName('NRO_FACTURA').AsString;

  // Construcción final: FECHA_SERIE_NUMERO_CLIENTE_TOTAL.extensión
  Result := sFecha + '_' + SerieFormateada + '_' + sNro + '_' + RazonSocialCorta + '_' + TotalFormateado + AExtension;
end;

procedure TfrmPrintFac.preparar_consulta;
begin
  if rbActual.Checked = true then
  begin
    with dmmFacturas.unqryFacPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT *  ' +
                  '       FROM vi_FACTURAS_print f' +
                  '      WHERE NRO_FACTURA = :numfac' +
                  '        AND SERIE_FACTURA = :serie';
      Params.ParamByName('numfac').Value := edtNroFac.text;
      Params.ParamByName('serie').Value := edtSerie.text;
    end;
    dmmFacturas.unqryFacPrint.Open;
    //dmmFacturas.fxdsPrintFac.OpenDataSource;
    dmmFacturas.fxdsPrintFac.UpdateBounds;
    with dmmFacturas.unqryLinFacPrint do
    begin
      Params.Clear;
      SQL.Text := '       SELECT * ' +
                  '         FROM vi_FACTURAS_LINEAS_print V  ' +
                  '        WHERE V.NRO_FACTURA_LINEA = :numfac' +
                  '          AND V.SERIE_FACTURA_LINEA = :serie ' +
                  '     order by V.LINEA_FACTURA_LINEA';
      Params.ParamByName('numfac').Value := edtNroFac.text;
      Params.ParamByName('serie').Value := edtSerie.text;
      end;
    dmmFacturas.unqryLinFacPrint.MasterSource := dmmFacturas.dsFacPrint;
    dmmFacturas.unqryLinFacPrint.Open;
    //dmmFacturas.fxdstPrintLinFac.OpenDataSource;
    dmmFacturas.fxdstPrintLinFac.UpdateBounds;
  end;

  if rbRangoFechas.Checked = true then
  begin
    with dmmFacturas.unqryFacPrint do
    begin
      Params.Clear;
      SQL.Text := '     SELECT *  ' +
                  '       FROM VI_FACTURAS_PRINT' +
                  '      WHERE FECHA_FACTURA >= :fecha_ini ' +
                  '        AND  FECHA_FACTURA <= :fecha_fin ' +
                  '   order by NRO_FACTURA';
      Params.ParamByName('fecha_ini').Value := dedDesde.Date;
      Params.ParamByName('fecha_fin').Value := dedHasta.Date;
    end;
    dmmFacturas.unqryFacPrint.Open;
    //dmmFacturas.fxdsPrintFac.OpenDataSource;
    dmmFacturas.fxdsPrintFac.UpdateBounds;
    with dmmFacturas.unqryLinFacPrint do
    begin
      Params.Clear;
      SQL.Text := '    SELECT *  ' +
                  '      FROM vi_FACTURAS_LINEAS_print L ' +
                  'INNER JOIN vi_FACTURAS_print F ' +
                  '        ON F.NRO_FACTURA = L.NRO_FACTURA_LINEA ' +
                  '       AND F.SERIE_FACTURA = L.SERIE_FACTURA_LINEA ' +
                  '     WHERE F.fecha_FACTURA >= :fecha_ini ' +
                  '       AND  F.fecha_FACTURA <= :fecha_fin ' +
                  '  order by L.NRO_FACTURA_LINEA, ' +
                  '           L.SERIE_FACTURA_LINEA, ' +
                  '           L.LINEA_FACTURA_LINEA';
      Params.ParamByName('fecha_ini').DataType := ftDate;
      Params.ParamByName('fecha_ini').Value := dedDesde.date;
      Params.ParamByName('fecha_fin').DataType := ftDate;
      Params.ParamByName('fecha_fin').Value := dedHasta.date;
      end;
    dmmFacturas.unqryLinFacPrint.Open;
    dmmFacturas.fxdstPrintLinFac.UpdateBounds;
  end;
  ConfigurarNombrePDF;
end;

procedure TfrmPrintFac.rbActualClick(Sender: TObject);
begin
  inherited;
   dedDesde.Enabled := false;
   dedHasta.Enabled := false;
end;

procedure TfrmPrintFac.rbRangoFechasClick(Sender: TObject);
begin
  inherited;
  dedDesde.Enabled := true;
  dedHasta.Enabled := true;
end;

end.
