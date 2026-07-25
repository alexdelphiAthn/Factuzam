{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpFac                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de facturas.                                           }
{    Hereda del modal generico de impresion y prepara la consulta.             }
{******************************************************************************}
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
  cxTextEdit, UniDataFacturas, inMtoFacturasBase, DB, frxExportXLSX, MemDS,
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
  dxSpreadSheetStyles, dxHashUtils, inLibDevExcel, System.Actions, Vcl.ActnList,
  frLocalization, frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, frxSmartMemo;

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
  protected
    procedure PdfExportado(const ARuta: string); override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    procedure ConfigurarNombrePDF;
    function ObtenerNombreFactura(ADataSet: TDataSet): string;
    procedure AplicarSkuDescripcionReport(AReport: TfrxReport);
  public
    dmFac: TdmFacturas;
  end;

var
  frmPrintFac: TfrmPrintFac;

implementation

{$R *.dfm}

uses inMtoPreviewExcel, inLibFacturaExcel, inLibAppParam, inLibVerifactu,
     inLibFormatoDocumento, inLibVentasWsCola, inLibFacturaPdfBlob;

{ TfrmPrintFac }

procedure TfrmPrintFac.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  NombreSugerido: string;
begin
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    with dmFac do
    begin
      NombreSugerido := ObtenerNombreFactura(unqryTablaG);
      fPreview.DialogoGuardar.InitialDir := oAppParams.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName := NombreSugerido;
      try
        ExportarFacturaADevExpress(ConexionPrincipal,fPreview.dxSpreadSheet1,
                                   unqryTablaG,
                                   unqryLinFac);
      finally
        Screen.Cursor := crDefault;
      end;
    end;
    fPreview.ShowModal;
  finally
    FreeAndNil(fPreview);
  end;
end;

procedure TfrmPrintFac.AfterReportLoaded;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  AplicarSkuDescripcionReport(frxrprt1);
  // Solo ajusta el título por tipo (FACTURA / FACTURA SIMPLIFICADA /
  // FACTURA RECTIFICATIVA). NO se inyecta ni se mueve ninguna banda:
  // el A4 conserva su layout original. El QR del A4 se replanteará en
  // limpio; el QR del Excel (que sí funciona) no se toca.
  if (dmFac <> nil) and dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
    AplicarVerifactuEnReportDirecto(frxrprt1, dmFac.unqryFacPrint);
end;

procedure TfrmPrintFac.AplicarSkuDescripcionReport(AReport: TfrxReport);
var
  oComponente: TfrxComponent;
  oMemo: TfrxMemoView;
begin
  if (AReport <> nil) and (dmFac <> nil) then
  begin
    oComponente :=
      AReport.FindObject('LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA');
    if oComponente is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(oComponente);
      oMemo.DataField := 'DESCRIPCION_PRINT_FACLIN';
      oMemo.DataSet := dmFac.fxdstPrintLinFac;
      oMemo.DataSetName := 'Lineas Facturas';
      oMemo.Memo.Text := '[Lineas Facturas."DESCRIPCION_PRINT_FACLIN"]';
    end;
  end;
end;

procedure TfrmPrintFac.ConfigurarNombrePDF;
begin
  frxpdfxprtPedWeb.FileName := ObtenerNombreFactura(dmFac.unqrytablaG);
end;

procedure TfrmPrintFac.PdfExportado(const ARuta: string);
var
  sSerie:  string;
  sNumero: string;
  sFase:   string;
  bLanzada: Boolean;
begin
  inherited;
  if (Trim(ARuta) <> '') and (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    sSerie  := dmFac.unqryFacPrint.FieldByName('SERIE_FAC').AsString;
    sNumero := dmFac.unqryFacPrint.FieldByName('NUMERO_FAC').AsString;
    TVentasWsCola.AdjuntarFacturaPdfSeguro(ConexionPrincipal,
      IdentidadSesion.Usuario,
      sSerie, sNumero, ARuta);
    // Archivado en fza_facturas.PDF_FAC: solo el PDF de UNA factura
    // (rbActual; un rango de fechas mezcla varias en un fichero) y solo
    // si ya salio de borrador (en modo SIN se imprimen borradores)
    sFase := dmFac.unqryFacPrint.FieldByName('FASE_FAC').AsString;
    bLanzada :=
      (dmFac.unqryFacPrint.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S')
      or ((sFase <> '') and (not SameText(sFase, 'BORRADOR')));
    if rbActual.Checked and bLanzada then
      GuardarPdfFacturaEnBlob(ConexionPrincipal, ContextoSesion,
        sSerie, sNumero, ARuta, FormatoElegido);
  end;
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet): string;
var
  RazonSocialCorta: string;
  sDocumento: string;
  sFecha: string;
  TotalFormateado: string;
begin
  RazonSocialCorta := Copy(ADataSet.FieldByName(
                                'RAZON_SOCIAL_CLIENTE_FAC').AsString, 1, 12);
  RazonSocialCorta := StringReplace(RazonSocialCorta, ' ', '', [rfReplaceAll]);
  if not ADataSet.FieldByName('FECHA_FAC').IsNull then
    sFecha := FormatDateTime('dd_mm', ADataSet.FieldByName(
                                                    'FECHA_FAC').AsDateTime)
  else
    sFecha := '00_00';
  TotalFormateado := FormatFloat('0.00', ADataSet.FieldByName(
                                              'TOTAL_LIQUIDO_FAC').AsFloat);
  TotalFormateado := StringReplace(TotalFormateado, ',', '_', [rfReplaceAll]);
  TotalFormateado := StringReplace(TotalFormateado, '.', '_', [rfReplaceAll]);
  sDocumento := FormatearDocumentoDataSet(
    ConexionPrincipal,
    ADataSet,
    'SERIE_FAC',
    'NUMERO_FAC');
  sDocumento := StringReplace(sDocumento, '\', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '/', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '.', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, ':', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '*', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '?', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, '[', '_', [rfReplaceAll]);
  sDocumento := StringReplace(sDocumento, ']', '_', [rfReplaceAll]);
  Result := sFecha + '_' + sDocumento + '_' + RazonSocialCorta + '_' +
                          TotalFormateado;
end;

procedure TfrmPrintFac.preparar_consulta;
begin
  with dmFac do
  begin
  if rbActual.Checked = true then
  begin
    with unqryFacPrint do
    begin
      Close;
      Params.Clear;
      // vi_facturas_print ya trae TIPO_FAC/FASE_FAC (de fza_facturas.*)
      // y la consolidación Verifactu por LEFT JOIN (QRCODE_PNG_FACCON…),// así que basta SELECT *: el título por tipo y el QR enlazado por
      // DataField salen de la propia vista.
      SQL.Text := 'SELECT * ' +
                  '  FROM vi_FACTURAS_print' +
                  ' WHERE NUMERO_FAC = :numfac' +
                  '   AND SERIE_FAC = :serie';
      Params.ParamByName('numfac').Value := edtNroFac.text;
      Params.ParamByName('serie').Value := edtSerie.text;
    end;
    unqryFacPrint.Open;
    //dmmFacturas.fxdsPrintFac.OpenDataSource;
    fxdsPrintFac.UpdateBounds;
    with unqryLinFacPrint do
    begin
      Close;
      Params.Clear;
      SQL.Text :=
        '  SELECT L.*, ' +
        '         CASE ' +
        '           WHEN COALESCE(CHAR_LENGTH(TRIM(' +
        '                  L.CODIGO_UNIDAD_FACLIN)), 0) > 0 ' +
        '             THEN CONCAT(L.CODIGO_UNIDAD_FACLIN, CHAR(32), ' +
        '                       L.DESCRIPCION_ARTICULO_FACLIN) ' +
        '           ELSE L.DESCRIPCION_ARTICULO_FACLIN ' +
        '         END AS DESCRIPCION_PRINT_FACLIN ' +
        '    FROM fza_facturas_lineas L ' +
        '   WHERE L.NUMERO_FAC_FACLIN = :numfac' +
        '     AND L.SERIE_FAC_FACLIN = :serie ' +
        'ORDER BY L.LINEA_FACLIN';
      Params.ParamByName('numfac').Value := edtNroFac.text;
      Params.ParamByName('serie').Value := edtSerie.text;
      end;
    unqryLinFacPrint.MasterSource := dsFacPrint;
    unqryLinFacPrint.Open;
    //dmmFacturas.fxdstPrintLinFac.OpenDataSource;
    fxdstPrintLinFac.UpdateBounds;
  end;
  if rbRangoFechas.Checked = true then
  begin
    with unqryFacPrint do
    begin
      Close;
      Params.Clear;
      SQL.Text := '  SELECT * ' +
                  '    FROM VI_FACTURAS_PRINT' +
                  '   WHERE FECHA_FAC >= :fecha_ini ' +
                  '     AND FECHA_FAC <= :fecha_fin ' +
                  'ORDER BY NUMERO_FAC';
      Params.ParamByName('fecha_ini').Value := dedDesde.Date;
      Params.ParamByName('fecha_fin').Value := dedHasta.Date;
    end;
    unqryFacPrint.Open;
    //dmmFacturas.fxdsPrintFac.OpenDataSource;
    fxdsPrintFac.UpdateBounds;
    with unqryLinFacPrint do
    begin
      Close;
      Params.Clear;
      SQL.Text :=
        '    SELECT L.*, ' +
        '           CASE ' +
        '             WHEN COALESCE(CHAR_LENGTH(TRIM(' +
        '                    L.CODIGO_UNIDAD_FACLIN)), 0) > 0 ' +
        '               THEN CONCAT(L.CODIGO_UNIDAD_FACLIN, CHAR(32), ' +
        '                         L.DESCRIPCION_ARTICULO_FACLIN) ' +
        '             ELSE L.DESCRIPCION_ARTICULO_FACLIN ' +
        '           END AS DESCRIPCION_PRINT_FACLIN ' +
        '      FROM fza_facturas_lineas L ' +
        'INNER JOIN vi_FACTURAS_print F ' +
        '        ON F.NUMERO_FAC = L.NUMERO_FAC_FACLIN ' +
        '       AND F.SERIE_FAC = L.SERIE_FAC_FACLIN ' +
        '     WHERE F.FECHA_FAC >= :fecha_ini ' +
        '       AND  F.FECHA_FAC <= :fecha_fin ' +
        '  order by L.NUMERO_FAC_FACLIN, ' +
        '           L.SERIE_FAC_FACLIN, ' +
        '           L.LINEA_FACLIN';
      Params.ParamByName('fecha_ini').DataType := ftDate;
      Params.ParamByName('fecha_ini').Value := dedDesde.date;
      Params.ParamByName('fecha_fin').DataType := ftDate;
      Params.ParamByName('fecha_fin').Value := dedHasta.date;
      end;
    unqryLinFacPrint.Open;
    fxdstPrintLinFac.UpdateBounds;
  end;
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
