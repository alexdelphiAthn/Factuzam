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
  cxTextEdit, UniDataFacturas, DB, frxExportXLSX, MemDS,
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
  frxExportBaseImageSettingsDialog, frxSmartMemo,
  inLibInformeFacturaPersistenciaIntf, inLibComandoImprimirFacturas;

type
  TEjecutarLoteFacturas = reference to function(
    const AReferencias: TReferenciasComandoFactura;
    const AFormato: string): Boolean;
  TObtenerLoteFacturas = reference to function:
    TReferenciasComandoFactura;

  TfrmPrintFac = class(TfrmPrint)
    edtNroFac: TcxTextEdit;
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbProcesarFiltrados: TcxRadioButton;
    procedure rbProcesarFiltradosClick(Sender: TObject);
    procedure rbActualClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject); override;
    procedure btnImprimirClick(Sender: TObject); override;
    procedure btnExcelClick(Sender: TObject);
  private
    FPreparadorInforme: IPreparadorInformeFactura;
    FObtenerReferenciasFiltradas: TObtenerLoteFacturas;
    FExportarLotePdf: TEjecutarLoteFacturas;
    FImprimirLote: TEjecutarLoteFacturas;
    procedure AplicarModoSeleccionado;
    function PrepararLote(
      const AAccion: TEjecutarLoteFacturas): Boolean;
  protected
    function TraducirContenidoInforme: Boolean; override;
    procedure PdfExportado(const ARuta: string); override;
    procedure ReportBeforePrintFactura(
      Component: TfrxReportComponent);
  public
    class procedure ArchivarFacturaConsolidada(
      ADataModule: TdmFacturas;
      const ASerie, ANumero: string); static;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    procedure ConfigurarDataModule(ADataModule: TdmFacturas);
    procedure ConfigurarNombrePDF;
    procedure ConfigurarLote(
      APuedeUsarActual: Boolean;
      const AObtenerFiltradas: TObtenerLoteFacturas;
      const AExportarPdf, AImprimir: TEjecutarLoteFacturas);
    function ObtenerNombreFactura(ADataSet: TDataSet): string;
    procedure AplicarSkuDescripcionReport(AReport: TfrxReport);
  public
    dmFac: TdmFacturas;
  end;

implementation

{$R *.dfm}

uses
  inMtoPreviewExcel, inLibFacturaExcel, inLibVerifactu,
  inLibFormatoDocumento, inLibVentasWsCola, inLibFacturaPdfBlob,
  inLibDir, inLibFacturasPersistenciaIntf,
  UniDataFacturasOperaciones, UniDataVentasWsCola,
  UniDataInformeFacturaRepositorio, inLibMsgFacturas;

{ TfrmPrintFac }

procedure TfrmPrintFac.ConfigurarDataModule(ADataModule: TdmFacturas);
begin
  dmFac := ADataModule;
  if dmFac <> nil then
  begin
    // Se enlaza tambien la plantilla origen antes de cualquier AssignAll.
    // Asi, tanto el formato predeterminado como los formatos guardados se
    // cargan dentro del ambito local del data module de esta instancia.
    RebindReportDataSetsByDataModule(frxReportOrigen, dmFac);
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  end;
end;

function TfrmPrintFac.TraducirContenidoInforme: Boolean;
begin
  // Las facturas de venta son documentos fiscales para el mercado español.
  Result := False;
end;

class procedure TfrmPrintFac.ArchivarFacturaConsolidada(
  ADataModule: TdmFacturas;
  const ASerie, ANumero: string);
var
  Formulario: TfrmPrintFac;
  sRutaPdf: string;
begin
  Formulario := TfrmPrintFac.Create(Application);
  try
    Formulario.edtSerie.Text := ASerie;
    Formulario.edtNroFac.Text := ANumero;
    Formulario.dmFac := ADataModule;
    Formulario.Consultar_Formularios;
    sRutaPdf := GetUserFolderTickets + 'Factura_' +
      FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.pdf';
    if Formulario.ExportarPdfActual(sRutaPdf) then
      System.SysUtils.DeleteFile(sRutaPdf);
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmPrintFac.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  NombreSugerido: string;
begin
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    NombreSugerido := ObtenerNombreFactura(dmFac.unqryTablaG);
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName := NombreSugerido;
    try
      ExportarFacturaADevExpress(
        ParametrosApp, RegistroLog, ConexionPrincipal,
        fPreview.dxSpreadSheet1,
        dmFac.unqryTablaG,
        dmFac.unqryLinFac);
    finally
      Screen.Cursor := crDefault;
    end;
    fPreview.ShowModal;
  finally
    FreeAndNil(fPreview);
  end;
end;

procedure TfrmPrintFac.AfterReportLoaded;
var
  oGrupoOperacion: TfrxComponent;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  oGrupoOperacion := frxrprt1.FindObject('GroupHeaderOperacionCaja');
  if oGrupoOperacion is TfrxGroupHeader then
  begin
    // Un formato guardado puede conservar una definicion antigua del
    // dataset. Evitamos que FastReport evalue un campo inexistente y solo
    // activamos la agrupacion cuando la consulta abierta expone el ID.
    TfrxGroupHeader(oGrupoOperacion).Condition := '0';
    TfrxGroupHeader(oGrupoOperacion).Visible := False;
    if (dmFac <> nil) and dmFac.unqryLinFacPrint.Active and
       (dmFac.unqryLinFacPrint.FindField(
          'ID_OPERACION_CAJA_FACTURA') <> nil) then
    begin
      TfrxGroupHeader(oGrupoOperacion).Condition :=
        'Lineas Facturas."ID_OPERACION_CAJA_FACTURA"';
      TfrxGroupHeader(oGrupoOperacion).Visible := True;
    end;
  end;
  AplicarSkuDescripcionReport(frxrprt1);
  // Solo ajusta el título por tipo (FACTURA / FACTURA SIMPLIFICADA /
  // FACTURA RECTIFICATIVA). NO se inyecta ni se mueve ninguna banda:
  // el A4 conserva su layout original. El QR del A4 se replanteará en
  // limpio; el QR del Excel (que sí funciona) no se toca.
  if (dmFac <> nil) and dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
    AplicarVerifactuEnReportDirecto(ParametrosApp, frxrprt1,
      dmFac.unqryFacPrint);
  frxrprt1.OnBeforePrint := ReportBeforePrintFactura;
end;

procedure TfrmPrintFac.ReportBeforePrintFactura(
  Component: TfrxReportComponent);
var
  oCampo: TField;
begin
  ReportBeforePrintConQR(Component);
  if (Component <> nil) and
     SameText(Component.Name, 'GroupHeaderOperacionCaja') then
  begin
    Component.Visible := False;
    if (dmFac <> nil) and dmFac.unqryLinFacPrint.Active then
    begin
      oCampo := dmFac.unqryLinFacPrint.FindField('ESFACTURA_TA_CAJA');
      if oCampo <> nil then
        Component.Visible := SameText(oCampo.AsString, 'S');
    end;
  end;
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
  frxpdfxprtPedWeb.FileName := '';
  if (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and
     (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    frxpdfxprtPedWeb.FileName :=
      ObtenerNombreFactura(dmFac.unqryFacPrint);
  end;
end;

procedure TfrmPrintFac.ConfigurarLote(
  APuedeUsarActual: Boolean;
  const AObtenerFiltradas: TObtenerLoteFacturas;
  const AExportarPdf, AImprimir: TEjecutarLoteFacturas);
begin
  FObtenerReferenciasFiltradas := AObtenerFiltradas;
  FExportarLotePdf := AExportarPdf;
  FImprimirLote := AImprimir;
  rbActual.Enabled := APuedeUsarActual;
  rbProcesarFiltrados.Enabled := Assigned(FObtenerReferenciasFiltradas);
  if rbActual.Enabled then
    rbActual.Checked := True
  else if rbProcesarFiltrados.Enabled then
    rbProcesarFiltrados.Checked := True;
  AplicarModoSeleccionado;
end;

procedure TfrmPrintFac.AplicarModoSeleccionado;
var
  bActual: Boolean;
begin
  bActual := rbActual.Checked;
  btnPDF.Enabled := True;
  btnImprimir.Enabled := True;
  btnVistaPreliminar.Enabled := bActual;
  btnEditar.Enabled := bActual;
  btnExcel.Enabled := bActual;
end;

function TfrmPrintFac.PrepararLote(
  const AAccion: TEjecutarLoteFacturas): Boolean;
var
  oReferencias: TReferenciasComandoFactura;
begin
  Result := False;
  if not Assigned(AAccion) then
  begin
    ShowMessage(SErrorServicioLoteImpresionFacturas);
    Exit;
  end;
  Consultar_Formularios(True);
  if FormatoElegido = '' then
    Exit;
  try
    if Assigned(FObtenerReferenciasFiltradas) then
      oReferencias := FObtenerReferenciasFiltradas()
    else
      oReferencias := nil;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;
  if Length(oReferencias) = 0 then
  begin
    ShowMessage(SErrorFacturasFiltradasVacias);
    Exit;
  end;
  Result := AAccion(oReferencias, FormatoElegido);
end;

procedure TfrmPrintFac.btnPDFClick(Sender: TObject);
begin
  if rbProcesarFiltrados.Checked then
  begin
    if PrepararLote(FExportarLotePdf) then
      ModalResult := mrOk;
  end
  else
    inherited btnPDFClick(Sender);
end;

procedure TfrmPrintFac.btnImprimirClick(Sender: TObject);
begin
  if rbProcesarFiltrados.Checked then
  begin
    if PrepararLote(FImprimirLote) then
      ModalResult := mrOk;
  end
  else
    inherited btnImprimirClick(Sender);
end;

procedure TfrmPrintFac.PdfExportado(const ARuta: string);
var
  sSerie:  string;
  sNumero: string;
  sFase:   string;
  bLanzada: Boolean;
  oRepositorioPdf: IRepositorioPdfFactura;
begin
  inherited;
  if (Trim(ARuta) <> '') and (dmFac <> nil) and
     dmFac.unqryFacPrint.Active and (not dmFac.unqryFacPrint.IsEmpty) then
  begin
    sSerie  := dmFac.unqryFacPrint.FieldByName('SERIE_FAC').AsString;
    sNumero := dmFac.unqryFacPrint.FieldByName('NUMERO_FAC').AsString;
    TVentasWsCola.AdjuntarFacturaPdfSeguro(
      ParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(ConexionPrincipal),
      IdentidadSesion.Usuario,
      sSerie, sNumero, ARuta, RegistroLog);
    // Archivado en fza_facturas.PDF_FAC: solo el PDF de UNA factura
    // (rbActual; un rango de fechas mezcla varias en un fichero) y solo
    // si ya salio de borrador (en modo SIN se imprimen borradores)
    sFase := dmFac.unqryFacPrint.FieldByName('FASE_FAC').AsString;
    bLanzada :=
      (dmFac.unqryFacPrint.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S')
      or ((sFase <> '') and (not SameText(sFase, 'BORRADOR')));
    if rbActual.Checked and bLanzada then
    begin
      oRepositorioPdf :=
        CrearPersistenciaFacturasUniDAC(ConexionPrincipal).Pdf;
      GuardarPdfFacturaEnBlob(oRepositorioPdf, ContextoSesion,
        sSerie, sNumero, ARuta, FormatoElegido, RegistroLog);
    end;
  end;
end;

function TfrmPrintFac.ObtenerNombreFactura(ADataSet: TDataSet): string;
var
  iCaracter: Integer;
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
  iCaracter := 1;
  while iCaracter <= Length(Result) do
  begin
    if CharInSet(Result[iCaracter],
      [#0..#31, '<', '>', ':', '"', '/', '\', '|', '?', '*']) then
    begin
      Result[iCaracter] := '_';
    end;
    Inc(iCaracter);
  end;
end;

procedure TfrmPrintFac.preparar_consulta;
var
  criterios: TCriteriosInformeFactura;
begin
  criterios := Default(TCriteriosInformeFactura);
  criterios.FacturaActual := True;
  criterios.Serie := edtSerie.Text;
  criterios.Numero := edtNroFac.Text;
  if FPreparadorInforme = nil then
    FPreparadorInforme := CrearPreparadorInformeFacturaUniDAC(
      dmFac.unqryFacPrint,
      dmFac.unqryLinFacPrint);
  FPreparadorInforme.Preparar(criterios);
  // FieldDefs era una fotografia de diseno. La consulta de impresion
  // incorpora campos calculados, por lo que FastReport debe reconstruir
  // su catalogo desde los TField reales despues de cada apertura.
  dmFac.fxdstPrintLinFac.ResetFieldDefs;
  dmFac.fxdsPrintFac.UpdateBounds;
  dmFac.fxdstPrintLinFac.UpdateBounds;
  ConfigurarNombrePDF;
end;

procedure TfrmPrintFac.rbActualClick(Sender: TObject);
begin
  AplicarModoSeleccionado;
end;

procedure TfrmPrintFac.rbProcesarFiltradosClick(Sender: TObject);
begin
  AplicarModoSeleccionado;
end;

end.
