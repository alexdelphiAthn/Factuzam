{******************************************************************************}
{                                                                              }
{                        Módulo: inLibInformeDocumento                         }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibInformeDocumento;

interface

uses
  frxClass, frxDBSet;

procedure CrearInformeDocumento(AInforme: TfrxReport;
  ACabecera, ALineas: TfrxDBDataset; const ATitulo: string);

implementation

uses
  inLibMsgPresupuestos,
  System.SysUtils, Vcl.Graphics, frBaseGraphicsTypes;

type
  TInformeDocumento = class
  private
    FInforme: TfrxReport;
    FCabecera: TfrxDBDataset;
    FLineas: TfrxDBDataset;
    FTitulo: string;
    procedure CrearCabecera(APagina: TfrxReportPage);
    procedure CrearDetalle(APagina: TfrxReportPage);
    procedure CrearTotales(APagina: TfrxReportPage);
    procedure Texto(ABanda: TfrxBand; const ATexto: string;
      ATop, ALeft, AWidth: Extended; ANegrita: Boolean = False);
    procedure CrearInforme;
  end;

procedure TInformeDocumento.Texto(ABanda: TfrxBand;
  const ATexto: string; ATop, ALeft, AWidth: Extended;
  ANegrita: Boolean);
var
  oTexto: TfrxMemoView;
begin
  oTexto := TfrxMemoView.Create(ABanda);
  oTexto.CreateUniqueName;
  oTexto.SetBounds(ALeft, ATop, AWidth, 21);
  oTexto.Font.Name := 'Arial';
  oTexto.Font.Size := 9;
  if ANegrita then
    oTexto.Font.Style := [fsBold];
  oTexto.WordWrap := True;
  oTexto.StretchMode := smActualHeight;
  oTexto.Text := ATexto;
  if ALeft >= 410 then
    oTexto.HAlign := haRight;
end;

procedure TInformeDocumento.CrearCabecera(APagina: TfrxReportPage);
var
  oBanda: TfrxReportTitle;
begin
  oBanda := TfrxReportTitle.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.Height := 200;
  Texto(oBanda, UpperCase(FTitulo), 0, 0, 450, True);
  Texto(oBanda, '[Cabecera."SERIE"] / [Cabecera."NUMERO"]',
    0, 450, 250, True);
  Texto(oBanda, SInformeFechaDocumento, 25, 450, 250);
  Texto(oBanda,
    '[Cabecera."EMPRESA"]' + #13#10 + '[Cabecera."NIF_EMPRESA"]' +
    #13#10 + '[Cabecera."DIRECCION_EMPRESA"]' + #13#10 +
    '[Cabecera."POBLACION_EMPRESA"]', 60, 0, 330);
  Texto(oBanda,
    '[Cabecera."TERCERO"]' + #13#10 + '[Cabecera."NIF_TERCERO"]' +
    #13#10 + '[Cabecera."DIRECCION_TERCERO"]' + #13#10 +
    '[Cabecera."POBLACION_TERCERO"]', 60, 350, 350);
end;

procedure TInformeDocumento.CrearDetalle(APagina: TfrxReportPage);
var
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
begin
  oCabecera := TfrxHeader.Create(APagina);
  oCabecera.CreateUniqueName;
  oCabecera.Top := 210;
  oCabecera.Height := 25;
  oCabecera.ReprintOnNewPage := True;
  Texto(oCabecera, SInformeArticuloDocumento, 0, 0, 410, True);
  Texto(oCabecera, SInformeCantidadDocumento, 0, 410, 65, True);
  Texto(oCabecera, SInformePrecioDocumento, 0, 480, 75, True);
  Texto(oCabecera, SInformeIvaDocumento, 0, 560, 55, True);
  Texto(oCabecera, SInformeImporteDocumento, 0, 620, 90, True);
  oDetalle := TfrxMasterData.Create(APagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 240;
  oDetalle.DataSet := FLineas;
  oDetalle.Height := 65;
  oDetalle.Stretched := True;
  oDetalle.AllowSplit := True;
  Texto(oDetalle,
    '[Lineas."ARTICULO"] — [Lineas."DESCRIPCION"]' + #13#10 +
    '[Lineas."SKU"] [Lineas."VARIACION"]' + #13#10 +
    '[Lineas."TALLAS"]', 0, 0, 405);
  Texto(oDetalle, '[Lineas."CANTIDAD"]', 0, 410, 65);
  Texto(oDetalle, '[FormatFloat(''0.00'', <Lineas."PRECIO">)]',
    0, 480, 75);
  Texto(oDetalle, '[Lineas."IVA"]', 0, 560, 55);
  Texto(oDetalle, '[FormatFloat(''0.00'', <Lineas."TOTAL">)]',
    0, 620, 90);
end;

procedure TInformeDocumento.CrearTotales(APagina: TfrxReportPage);
var
  oResumen: TfrxReportSummary;
  oPie: TfrxPageFooter;
begin
  oResumen := TfrxReportSummary.Create(APagina);
  oResumen.CreateUniqueName;
  oResumen.Top := 330;
  oResumen.Height := 170;
  oResumen.Stretched := True;
  Texto(oResumen, SInformeBaseDocumento,
    10, 430, 280);
  Texto(oResumen,
    SInformeImpuestosDocumento,
    33, 430, 280);
  Texto(oResumen,
    SInformeRetencionDocumento,
    56, 430, 280);
  Texto(oResumen, SInformeTotalDocumento,
    83, 430, 280, True);
  Texto(oResumen, SInformeFormaPagoDocumento, 10, 0, 420);
  Texto(oResumen, '[Cabecera."COMENTARIOS"]' + #13#10 +
    '[Cabecera."OBSERVACIONES"]', 120, 0, 710);
  oPie := TfrxPageFooter.Create(APagina);
  oPie.CreateUniqueName;
  oPie.Top := 700;
  oPie.Height := 25;
  Texto(oPie, SInformePaginaDocumento, 0, 480, 230);
end;

procedure TInformeDocumento.CrearInforme;
var
  oPagina: TfrxReportPage;
begin
  FInforme.Clear;
  FInforme.DataSets.Add(FCabecera);
  FInforme.DataSets.Add(FLineas);
  FInforme.EngineOptions.DoublePass := True;
  oPagina := TfrxReportPage.Create(FInforme);
  oPagina.CreateUniqueName;
  oPagina.SetDefaults;
  oPagina.LeftMargin := 10;
  oPagina.RightMargin := 10;
  CrearCabecera(oPagina);
  CrearDetalle(oPagina);
  CrearTotales(oPagina);
end;

procedure CrearInformeDocumento(AInforme: TfrxReport;
  ACabecera, ALineas: TfrxDBDataset; const ATitulo: string);
var
  oConstructor: TInformeDocumento;
begin
  oConstructor := TInformeDocumento.Create;
  try
    oConstructor.FInforme := AInforme;
    oConstructor.FCabecera := ACabecera;
    oConstructor.FLineas := ALineas;
    oConstructor.FTitulo := ATitulo;
    oConstructor.CrearInforme;
  finally
    FreeAndNil(oConstructor);
  end;
end;

end.
