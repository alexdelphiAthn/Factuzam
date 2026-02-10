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
  dxSpreadSheetStyles, dxHashUtils, inLibDevExcel, System.Actions, Vcl.ActnList;

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
                                              const QMaster, QLineas: TDataSet);
const
  // Columnas Visibles
  COL_DESC   = 0; // A: Descripción / Base Imponible (en tabla inferior)
  COL_CANT   = 1; // B: Cantidad / Tipo IVA (en tabla inferior)
  COL_PRECIO = 2; // C: Precio / Cuota IVA (en tabla inferior)
  COL_PIVA   = 3; // D: % IVA / % RE (en tabla inferior)
  COL_TOTAL  = 4; // E: Total Línea / Total RE (en tabla inferior)
  // Columnas Técnicas (Ocultas)
  COL_BASEI  = 5; // F: Base Imponible real de cada línea
  COL_TIPO_L = 6; // G: Tipo de IVA Letra (N, R, S, E)
var
  Sheet: TdxSpreadSheetTableView;
  iRow: Integer;
  NombreSugerido: string;
  PorcenREN, PorcenRER, PorcenRESR, PorcenREE: Double;
  TieneRE : Boolean;

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
  TieneRE := QMaster.FieldByName('ESIVA_RECARGO_CLIENTE_FACTURA').AsString = 'S';
  Sheet := ASheetControl.AddSheet('Factura',
                            TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  if not QMaster.FieldByName('NRO_FACTURA').IsNull then
    Sheet.Caption := 'Factura ' + QMaster.FieldByName('SERIE_FACTURA').AsString
                     + '_' + QMaster.FieldByName('NRO_FACTURA').AsString;
  var ImpuestosIncluidos :=
      (QMaster.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FACTURA').AsString = 'S');
  W(Sheet, 1, COL_DESC, 'FACTURA', True);
  Sheet.Cells[1, COL_DESC].Style.Font.Size := 18;
  W(Sheet, 1, COL_TOTAL, 'Fecha: ' +
               QMaster.FieldByName('FECHA_FACTURA').AsString, False, ssahRight);
  W(Sheet, 2, COL_TOTAL, 'Número: ' +
                           QMaster.FieldByName('SERIE_FACTURA').AsString + '.' +
                  QMaster.FieldByName('NRO_FACTURA').AsString, True, ssahRight);
  W(Sheet, 4, COL_DESC, 'EMISOR', True); // Negrita
  W(Sheet, 5, COL_DESC, QMaster.FieldByName(
                                       'RAZONSOCIAL_EMPRESA_FACTURA').AsString);
  Merge(Sheet, 5, COL_DESC, 3, 1);
  W(Sheet, 6, COL_DESC, 'NIF: ' + QMaster.FieldByName(
                                               'NIF_EMPRESA_FACTURA').AsString);
  Merge(Sheet, 6, COL_DESC, 3, 1);
  W(Sheet, 7, COL_DESC, QMaster.FieldByName(
                                        'DIRECCION1_EMPRESA_FACTURA').AsString);
  Merge(Sheet, 7, COL_DESC, 3, 1);
  W(Sheet, 8, COL_DESC, QMaster.FieldByName('CPOSTAL_EMPRESA_FACTURA').AsString
            +  ' ' + QMaster.FieldByName('POBLACION_EMPRESA_FACTURA').AsString);
  Merge(Sheet, 8, COL_DESC, 3, 1);
  W(Sheet, 4, COL_PIVA, 'RECEPTOR', True); // Negrita
  W(Sheet, 5, COL_PIVA, QMaster.FieldByName(
                                       'RAZONSOCIAL_CLIENTE_FACTURA').AsString);
  Merge(Sheet, 5, COL_PIVA, 2, 1);
  W(Sheet, 6, COL_PIVA, 'NIF: ' + QMaster.FieldByName(
                                               'NIF_CLIENTE_FACTURA').AsString);
  Merge(Sheet, 6, COL_PIVA, 2, 1);
  W(Sheet, 7, COL_PIVA, QMaster.FieldByName(
                                        'DIRECCION1_CLIENTE_FACTURA').AsString);
  Merge(Sheet, 7, COL_PIVA, 2, 1);
  W(Sheet, 8, COL_PIVA,
    QMaster.FieldByName('CPOSTAL_CLIENTE_FACTURA').AsString + ' ' +
    QMaster.FieldByName('POBLACION_CLIENTE_FACTURA').AsString);
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
  QLineas.First;
  while not QLineas.Eof do
  begin
    Inc(iRow);
    // Col A: Descripción
    with Sheet.CreateCell(iRow, COL_DESC) do
    begin
      AsString :=
             QLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
      Style.WordWrap := True;
      Style.AlignVert := ssavTop;
    end;
    W(Sheet, iRow, COL_CANT,
      QLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat, False, ssahRight);
    Sheet.Cells[iRow, COL_CANT].Style.AlignVert := ssavTop;
    W(Sheet, iRow, COL_PRECIO,
        QLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsFloat,
        False, ssahRight);
    Sheet.Cells[iRow, COL_PRECIO].Style.AlignVert := ssavTop;
    W(Sheet, iRow, COL_PIVA,
      QLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat,
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
                 'TIPOIVA_ARTICULO_FACTURA_LINEA').AsString, False, ssahCenter);
    QLineas.Next;
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
    PorcenREN := QMaster.FieldByName('PORCEN_REN_FACTURA').AsFloat;
    PorcenRER := QMaster.FieldByName('PORCEN_RER_FACTURA').AsFloat;
    PorcenRESR := QMaster.FieldByName('PORCEN_RES_FACTURA').AsFloat;
    PorcenREE := QMaster.FieldByName('PORCEN_REE_FACTURA').AsFloat;
  end
  else
  begin
    PorcenREN := 0;
    PorcenRER := 0;
    PorcenRESR := 0;
    PorcenREE := 0;
  end;
  if QMaster.FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsFloat > 0 then
      PintarImpuesto('N', QMaster.FieldByName('PORCEN_IVAN_FACTURA').AsFloat,
                      PorcenREN,
                      RangoTiposLetra, RangoBasesReales);
  if QMaster.FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsFloat > 0 then
      PintarImpuesto('R', QMaster.FieldByName('PORCEN_IVAR_FACTURA').AsFloat,
                      PorcenRER,
                      RangoTiposLetra, RangoBasesReales);
  if QMaster.FieldByName('TOTAL_BASEI_IVAS_FACTURA').AsFloat > 0 then
      PintarImpuesto('S', QMaster.FieldByName('PORCEN_IVAS_FACTURA').AsFloat,
                      PorcenRESR,
                      RangoTiposLetra, RangoBasesReales);
  if QMaster.FieldByName('TOTAL_BASEI_IVAE_FACTURA').AsFloat > 0 then
      PintarImpuesto('E', QMaster.FieldByName('PORCEN_IVAE_FACTURA').AsFloat,
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

  // 2. TOTAL IMPUESTOS
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
  if Abs(QMaster.FieldByName('TOTAL_RETENCION_FACTURA').AsFloat) > 0.001 then
  begin
     Inc(iRow);
     W(Sheet, iRow, COL_BASEI, QMaster.FieldByName(
                   'PORCEN_RETENCION_FACTURA').AsFloat);
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
    AsString := QMaster.FieldByName('FORMA_PAGO_FACTURA').AsString;
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
end;

procedure TfrmPrintFac.ConfigurarNombrePDF;
begin
  frxpdfxprtPedWeb.FileName := ObtenerNombreFactura(dmmFacturas.unqrytablaG,
                                                    'pdf');
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet;
                                           const AExtension: string): string;
var
  RazonSocialCorta: string;
  sFecha: string;
  TotalFormateado: string;
  SerieFormateada: string;
  sNro: string;
begin
  RazonSocialCorta := Copy(ADataSet.FieldByName(
                                'RAZONSOCIAL_CLIENTE_FACTURA').AsString, 1, 12);
  RazonSocialCorta := StringReplace(RazonSocialCorta, ' ', '', [rfReplaceAll]);
  if not ADataSet.FieldByName('FECHA_FACTURA').IsNull then
    sFecha := FormatDateTime('dd_mm', ADataSet.FieldByName(
                                                    'FECHA_FACTURA').AsDateTime)
  else
    sFecha := '00_00';
  TotalFormateado := FormatFloat('0.00', ADataSet.FieldByName(
                                              'TOTAL_LIQUIDO_FACTURA').AsFloat);
  TotalFormateado := StringReplace(TotalFormateado, ',', '_', [rfReplaceAll]);
  TotalFormateado := StringReplace(TotalFormateado, '.', '_', [rfReplaceAll]);
  SerieFormateada := StringReplace(ADataSet.FieldByName(
                           'SERIE_FACTURA').AsString, '.', '_', [rfReplaceAll]);
  sNro := ADataSet.FieldByName('NRO_FACTURA').AsString;
  Result := sFecha + '_' + SerieFormateada + '_' + sNro + '_' +
                          RazonSocialCorta + '_' + TotalFormateado + AExtension;
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
