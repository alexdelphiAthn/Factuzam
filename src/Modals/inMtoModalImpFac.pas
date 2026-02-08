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
    DialogoGuardar: TdxSaveFileDialog;
    procedure rbRangoFechasClick(Sender: TObject);
    procedure rbActualClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  public
    procedure preparar_consulta; override;
    procedure ConfigurarNombrePDF;
    function ObtenerNombreFactura(ADataSet: TDataSet;
                                  const AExtension: string): string;
    procedure ExportarFacturaADevExpress(const QMaster, QLineas: TDataSet);
  public
    { Public declarations }
  end;

var
  frmPrintFac: TfrmPrintFac;

implementation

{$R *.dfm}

{ TfrmPrintFac }

procedure TfrmPrintFac.btnExcelClick(Sender: TObject);
begin
  //inherited;
  ExportarFacturaADevExpress(dmmFacturas.unqryTablaG,
                             dmmFacturas.unqryLinFac);
end;

procedure TfrmPrintFac.ExportarFacturaADevExpress(const QMaster,
                                                        QLineas: TDataSet);
var
  SSheet: TdxSpreadSheet;
  Sheet: TdxSpreadSheetTableView;
  Row: Integer;
  Cell: TdxSpreadSheetCell;
  NombreSugerido: string;

  // Helper para escribir celdas
  procedure W(ARow, ACol: Integer; const AValue: Variant; ABold: Boolean = False; AAlign: TdxSpreadSheetDataAlignHorz = ssahLeft);
  begin
    with Sheet.CreateCell(ARow, ACol) do
    begin
      AsVariant := AValue;
      if ABold then Style.Font.Style := [fsBold] else Style.Font.Style := [];
      Style.AlignHorz := AAlign;
      Style.AlignVert := ssavCenter; // Centrado vertical para que quede mejor
    end;
  end;

  // --- SUB-PROCEDIMIENTO PARA DESGLOSE DE IMPUESTOS (IVA + RECARGO) ---
  procedure PintarLineaImpuesto(Base, PctIVA, CuotaIVA, PctRE, CuotaRE: Double);
  begin
    if Abs(Base) > 0.001 then
    begin
      Inc(Row);
      // Col 0: Base
      W(Row, 0, Base, False, ssahRight);
      if Sheet.Cells[Row, 0] <> nil then Sheet.Cells[Row, 0].Style.DataFormat.FormatCode := '#,##0.00" €"';

      // Col 1: % IVA
      W(Row, 1, PctIVA, False, ssahRight); // Mostramos solo el número (21)

      // Col 2: Cuota IVA
      W(Row, 2, CuotaIVA, False, ssahRight);
      if Sheet.Cells[Row, 2] <> nil then Sheet.Cells[Row, 2].Style.DataFormat.FormatCode := '#,##0.00" €"';

      // Col 3: % RE (Si es 0 mostramos guion)
      if Abs(CuotaRE) > 0.001 then
         W(Row, 3, PctRE, False, ssahRight)
      else
         W(Row, 3, '-', False, ssahCenter);

      // Col 4: Cuota RE (Total RE)
      if Abs(CuotaRE) > 0.001 then
      begin
         W(Row, 4, CuotaRE, False, ssahRight);
         if Sheet.Cells[Row, 4] <> nil then Sheet.Cells[Row, 4].Style.DataFormat.FormatCode := '#,##0.00" €"';
      end
      else
      begin
         W(Row, 4, '-', False, ssahCenter);
      end;
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
begin
  SSheet := TdxSpreadSheet.Create(nil);
  try
    Sheet := SSheet.ActiveSheetAsTable;
    if not QMaster.FieldByName('NRO_FACTURA').IsNull then
       Sheet.Caption := 'Factura ' + QMaster.FieldByName('NRO_FACTURA').AsString;

    // --- ENCABEZADO ---
    W(1, 0, 'FACTURA', True);
    Sheet.Cells[1, 0].Style.Font.Size := 18;

    W(1, 4, 'Fecha: ' + QMaster.FieldByName('FECHA_FACTURA').AsString, False, ssahRight);
    W(2, 4, 'Número: ' + QMaster.FieldByName('SERIE_FACTURA').AsString + '.' +
             QMaster.FieldByName('NRO_FACTURA').AsString, True, ssahRight);

    // --- EMISOR Y RECEPTOR ---
    W(4, 0, 'EMISOR', True);
    W(5, 0, QMaster.FieldByName('RAZONSOCIAL_EMPRESA_FACTURA').AsString);
    W(6, 0, 'NIF: ' + QMaster.FieldByName('NIF_EMPRESA_FACTURA').AsString);
    W(7, 0, QMaster.FieldByName('DIRECCION1_EMPRESA_FACTURA').AsString);
    W(8, 0, QMaster.FieldByName('CPOSTAL_EMPRESA_FACTURA').AsString + ' ' + QMaster.FieldByName('POBLACION_EMPRESA_FACTURA').AsString);

    W(4, 3, 'RECEPTOR', True);
    W(5, 3, QMaster.FieldByName('RAZONSOCIAL_CLIENTE_FACTURA').AsString);
    W(6, 3, 'NIF: ' + QMaster.FieldByName('NIF_CLIENTE_FACTURA').AsString);
    W(7, 3, QMaster.FieldByName('DIRECCION1_CLIENTE_FACTURA').AsString);
    W(8, 3, QMaster.FieldByName('CPOSTAL_CLIENTE_FACTURA').AsString + ' ' + QMaster.FieldByName('POBLACION_CLIENTE_FACTURA').AsString);

    // --- TABLA DE LÍNEAS (CORREGIDO: 5 COLUMNAS AHORA) ---
    Row := 11;
    W(Row, 0, 'Descripción', True);   // Col A
    W(Row, 1, 'Cantidad', True, ssahRight); // Col B (Antes estaba vacía)
    W(Row, 2, 'Precio', True, ssahRight);   // Col C
    W(Row, 3, '% IVA', True, ssahRight);    // Col D (Nueva)
    W(Row, 4, 'Total', True, ssahRight);    // Col E

    // Bordes inferiores cabecera
    if Sheet.Cells[Row, 0] <> nil then Sheet.Cells[Row, 0].Style.Borders[bBottom].Style := sscbsThin;
    if Sheet.Cells[Row, 1] <> nil then Sheet.Cells[Row, 1].Style.Borders[bBottom].Style := sscbsThin;
    if Sheet.Cells[Row, 2] <> nil then Sheet.Cells[Row, 2].Style.Borders[bBottom].Style := sscbsThin;
    if Sheet.Cells[Row, 3] <> nil then Sheet.Cells[Row, 3].Style.Borders[bBottom].Style := sscbsThin;
    if Sheet.Cells[Row, 4] <> nil then Sheet.Cells[Row, 4].Style.Borders[bBottom].Style := sscbsThin;

    QLineas.First;
    while not QLineas.Eof do
    begin
      Inc(Row);
      // Col A: Descripción
      with Sheet.CreateCell(Row, 0) do
      begin
        AsString := QLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
        Style.WordWrap := True;
      end;

      // Col B: Cantidad
      W(Row, 1,
        QLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat,
        False, ssahRight);

      // Col C: Precio Unitario
      W(Row, 2,
        QLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsFloat,
        False, ssahRight);

      // Col D: % IVA (Desde la línea)
      W(Row, 3,
        QLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat,
        False, ssahRight);

      // Col E: Total Línea
      W(Row, 4,
        QLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsFloat,
        False, ssahRight);

      // Formatos
      if Sheet.Cells[Row, 2] <> nil then
        Sheet.Cells[Row, 2].Style.DataFormat.FormatCode := '#,##0.00" €"';
      if Sheet.Cells[Row, 4] <> nil then
        Sheet.Cells[Row, 4].Style.DataFormat.FormatCode := '#,##0.00" €"';

      QLineas.Next;
    end;
    Inc(Row, 3);
    // ==========================================
    // 1. TABLA DETALLADA DE IMPUESTOS (Izquierda)
    // ==========================================
    var RowInicioTabla: Integer := Row;
    W(Row, 0, 'Base Imponible', True, ssahRight);
    W(Row, 1, 'Tipo IVA', True, ssahRight);
    W(Row, 2, 'Cuota IVA', True, ssahRight);
    W(Row, 3, '% RE', True, ssahRight);
    W(Row, 4, 'Total RE', True, ssahRight);

    // Bordes inferiores cabecera impuestos
    for var i := 0 to 4 do
      if Sheet.Cells[Row, i] <> nil then
         Sheet.Cells[Row, i].Style.Borders[bBottom].Style := sscbsThin;

    // Función auxiliar para pintar líneas de impuestos

    // Iteramos por los tipos de IVA (Normal, Reducido, Super)
    PintarLineaImpuesto(
      QMaster.FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsFloat,
      QMaster.FieldByName('PORCEN_IVAN_FACTURA').AsFloat,
      QMaster.FieldByName('TOTAL_IVAN_FACTURA').AsFloat,
      QMaster.FieldByName('PORCEN_REN_FACTURA').AsFloat,
      QMaster.FieldByName('TOTAL_REN_FACTURA').AsFloat
    );
    PintarLineaImpuesto(
      QMaster.FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsFloat,
      QMaster.FieldByName('PORCEN_IVAR_FACTURA').AsFloat,
      QMaster.FieldByName('TOTAL_IVAR_FACTURA').AsFloat,
      QMaster.FieldByName('PORCEN_RER_FACTURA').AsFloat,
      QMaster.FieldByName('TOTAL_RER_FACTURA').AsFloat
    );
    PintarLineaImpuesto(
      QMaster.FieldByName('TOTAL_BASEI_IVAS_FACTURA').AsFloat,
      QMaster.FieldByName('PORCEN_IVAS_FACTURA').AsFloat,
      QMaster.FieldByName('TOTAL_IVAS_FACTURA').AsFloat,
      QMaster.FieldByName('PORCEN_RES_FACTURA').AsFloat,
      QMaster.FieldByName('TOTAL_RES_FACTURA').AsFloat
    );
    var RowFinTabla: Integer := Row;
    for var r := RowInicioTabla to RowFinTabla do
    begin
       // Borde Izquierdo (Col 0)
       if Sheet.Cells[r, 0] = nil then Sheet.CreateCell(r, 0);
       Sheet.Cells[r, 0].Style.Borders[bLeft].Style := sscbsMedium; // O sscbsMedium para más grosor

       // Borde Derecho (Col 4)
       if Sheet.Cells[r, 4] = nil then Sheet.CreateCell(r, 4);
       Sheet.Cells[r, 4].Style.Borders[bRight].Style := sscbsMedium;
    end;

    // Iteramos por las columnas para dibujar Techo y Suelo
    for var c := 0 to 4 do
    begin
       // Borde Superior
       if Sheet.Cells[RowInicioTabla, c] = nil then Sheet.CreateCell(RowInicioTabla, c);
       Sheet.Cells[RowInicioTabla, c].Style.Borders[bTop].Style := sscbsMedium;

       // Borde Inferior
       if Sheet.Cells[RowFinTabla, c] = nil then Sheet.CreateCell(RowFinTabla, c);
       Sheet.Cells[RowFinTabla, c].Style.Borders[bBottom].Style := sscbsMedium;
    end;

    // ==========================================
    // 4. RESUMEN FINAL CON FÓRMULAS
    // ==========================================
    Inc(Row, 2);

    // A. TOTAL BASE IMPONIBLE (Fórmula SUM de la columna 0 del cuadro)
    W(Row, 3, 'Total Base Imponible:', True, ssahRight);

    with Sheet.CreateCell(Row, 4) do
    begin
      // Fórmula: =SUM(A_Inicio : A_Fin)
      SetText('=SUM(' + GetRef(RowInicioTabla + 1, 0) + ':' + GetRef(RowFinTabla, 0) + ')', True);
      Style.DataFormat.FormatCode := '#,##0.00" €"';
      Style.AlignHorz := ssahRight;
    end;
    var RefTotalBase := GetRef(Row, 4); // Guardamos "E15" (ejemplo) para usarlo luego

    // B. TOTAL IMPUESTOS (Fórmula SUM Columna Cuota + SUM Columna RE)
    Inc(Row);
    W(Row, 3, 'Total Impuestos (IVA+RE):', True, ssahRight);

    with Sheet.CreateCell(Row, 4) do
    begin
      // Fórmula: =SUM(C_Inicio : C_Fin) + SUM(E_Inicio : E_Fin)
      // Col 2 es 'C' (Cuota), Col 4 es 'E' (RE)
      SetText('=SUM(' + GetRef(RowInicioTabla + 1, 2) + ':' + GetRef(RowFinTabla, 2) + ')+' +
                   'SUM(' + GetRef(RowInicioTabla + 1, 4) + ':' + GetRef(RowFinTabla, 4) + ')', True);
      Style.DataFormat.FormatCode := '#,##0.00" €"';
      Style.AlignHorz := ssahRight;
    end;
    var RefTotalImpuestos := GetRef(Row, 4);

    // C. RETENCIONES (Valor fijo o fórmula simple)
    var RefRetenciones := '';
    if Abs(QMaster.FieldByName('TOTAL_RETENCION_FACTURA').AsFloat) > 0.001 then
    begin
       Inc(Row);
       var PctIRPF: string := QMaster.FieldByName('PORCEN_RETENCION_FACTURA').AsString;
       W(Row, 3, 'Retención IRPF (' + PctIRPF + '%):', True, ssahRight);

       // Ponemos el valor negativo directo
       W(Row, 4, -QMaster.FieldByName('TOTAL_RETENCION_FACTURA').AsFloat, False, ssahRight);

       if Sheet.Cells[Row, 4] <> nil then
       begin
         Sheet.Cells[Row, 4].Style.DataFormat.FormatCode := '#,##0.00" €"';
         Sheet.Cells[Row, 4].Style.Font.Color := clRed;
       end;
       RefRetenciones := GetRef(Row, 4);
    end;

    // D. TOTAL A PAGAR (Fórmula suma de los anteriores)
    Inc(Row);
    W(Row, 3, 'TOTAL A PAGAR:', True, ssahRight);

    with Sheet.CreateCell(Row, 4) do
    begin
      // Fórmula: = TotalBase + TotalImpuestos + Retenciones
      // Nota: Retenciones ya es negativo en la celda, así que sumamos (+).
      // Si la celda fuera positiva, haríamos resta. En este código la puse negativa (-QMaster...)

      var FormulaStr: string := '=' + RefTotalBase + '+' + RefTotalImpuestos;
      if RefRetenciones <> '' then
         FormulaStr := FormulaStr + '+' + RefRetenciones;

      SetText(FormulaStr, True);

      Style.Font.Style := [fsBold];
      Style.Font.Size := 14;
      Style.DataFormat.FormatCode := '#,##0.00" €"';
      Style.Borders[bTop].Style := sscbsMedium;
      Style.Borders[bBottom].Style := sscbsMedium;
      Style.Borders[bLeft].Style := sscbsMedium;
      Style.Borders[bRight].Style := sscbsMedium;
    end;

    // --- FORMA DE PAGO ---
    Inc(Row, 3);
    W(Row, 0, 'Forma de Pago: ' +
      QMaster.FieldByName('FORMA_PAGO_FACTURA').AsString, True);


    Sheet.Columns[0].Size := 280; // Base
    Sheet.Columns[1].Size := 60;  // Tipo
    Sheet.Columns[2].Size := 80;  // Cuota
    Sheet.Columns[3].Size := 180; // Etiqueta ancha ("Total Impuestos...")
    Sheet.Columns[4].Size := 110; // Importes finales

    NombreSugerido := ObtenerNombreFactura(QMaster, '.xlsx');
    DialogoGuardar.FileName := NombreSugerido;
    DialogoGuardar.DefaultExt := 'xlsx';
    DialogoGuardar.Filter := 'Libro de Excel (*.xlsx)|*.xlsx';

    if DialogoGuardar.Execute then
      SSheet.SaveToFile(DialogoGuardar.FileName);
  finally
    SSheet.Free;
  end;
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
