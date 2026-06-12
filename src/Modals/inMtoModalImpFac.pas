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
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    procedure ConfigurarNombrePDF;
    function ObtenerNombreFactura(ADataSet: TDataSet): string;
  public
    dmFac: TdmFacturas;
  end;

var
  frmPrintFac: TfrmPrintFac;

implementation

{$R *.dfm}

uses inMtoPreviewExcel, inLibFacturaExcel, inLibAppParam, inLibVerifactu;

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
        ExportarFacturaADevExpress(fPreview.dxSpreadSheet1,
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
  // Hueco del QR tributario: si el formato (normal o simplificada) no
  // trae el TfrxPictureView 'qrverifactu', se inyecta arriba a la
  // derecha; el OnBeforePrint de la base lo rellena por factura
  AsegurarQRVerifactuEnReport(frxrprt1);
end;

procedure TfrmPrintFac.ConfigurarNombrePDF;
begin
  frxpdfxprtPedWeb.FileName := ObtenerNombreFactura(dmFac.unqrytablaG);
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet): string;
var
  RazonSocialCorta: string;
  sFecha: string;
  TotalFormateado: string;
  SerieFormateada: string;
  sNro: string;
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
  SerieFormateada := StringReplace(ADataSet.FieldByName(
                           'SERIE_FAC').AsString, '.', '_', [rfReplaceAll]);
  sNro := ADataSet.FieldByName('NUMERO_FAC').AsString;
  Result := sFecha + '_' + SerieFormateada + '_' + sNro + '_' +
                          RazonSocialCorta + '_' + TotalFormateado;
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
      SQL.Text := 'SELECT *  ' +
                  '  FROM vi_FACTURAS_print f' +
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
      Params.Clear;
      SQL.Text := '  SELECT * ' +
                  '    FROM vi_FACTURAS_LINEAS_print V  ' +
                  '   WHERE V.NUMERO_FAC_FACLIN = :numfac' +
                  '     AND V.SERIE_FAC_FACLIN = :serie ' +
                  'ORDER BY V.LINEA_FACLIN';
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
      SQL.Text := '  SELECT *  ' +
                  '    FROM VI_FACTURAS_PRINT' +
                  '   WHERE FECHA_FAC >= :fecha_ini ' +
                  '     AND  FECHA_FAC <= :fecha_fin ' +
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
      SQL.Text := '    SELECT *  ' +
                  '      FROM vi_FACTURAS_LINEAS_print L ' +
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
