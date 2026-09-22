{******************************************************************************}
{                                                                              }
{                        Módulo: inLibInformeDocumento                         }
{                                Versión: 1.1.0                                }
{                              Fecha: 22/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibInformeDocumento;

interface

uses
  frxClass, frxDBSet;

// Informe base de presupuestos, pedidos y albaranes, con la misma
// estructura que la factura: cajas de emisor y tercero, lineas, desglose
// de IVA junto a los totales, forma de pago y observaciones.
// AEtiquetaTercero rotula la caja del cliente o del proveedor.
procedure CrearInformeDocumento(AInforme: TfrxReport;
  ACabecera, ALineas, AImpuestos: TfrxDBDataset;
  const ATitulo, AEtiquetaTercero: string);

implementation

uses
  inLibMsgPresupuestos,
  System.SysUtils, System.Classes, Vcl.Graphics, frBaseGraphicsTypes;

const
  PIXELES_POR_MM = 3.77953;
  COLOR_FONDO = $00EAEAEA;
  COLOR_LINEA = $00C8C8C8;
  COLOR_TENUE = $00666666;
  ANCHO_CAJA = 350;
  ALTO_FILA = 18;
  FORMATO_IMPORTE = '#,##0.00';
  SCRIPT_INFORME =
    'procedure NotasOnBeforePrint(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible := <Cabecera."NOTAS"> <> '''';'#13#10 +
    'end;'#13#10 +
    'procedure FormaPagoOnBeforePrint(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible :='#13#10 +
    '    <Cabecera."FORMA_PAGO_DESCRIPCION"> <> '''';'#13#10 +
    'end;'#13#10 +
    'procedure RetencionOnBeforePrint(Sender: TfrxComponent);'#13#10 +
    'begin'#13#10 +
    '  TfrxView(Sender).Visible := <Cabecera."RETENCION"> <> 0;'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.';

type
  TInformeDocumento = class
  private
    FInforme: TfrxReport;
    FCabecera: TfrxDBDataset;
    FLineas: TfrxDBDataset;
    FImpuestos: TfrxDBDataset;
    FTitulo: string;
    FEtiquetaTercero: string;
    FAncho: Extended;
    function Memo(AParent: TfrxComponent; const ATexto: string;
      ALeft, ATop, AWidth, AHeight: Extended): TfrxMemoView;
    function Importe(const ACampo: string): string;
    procedure Caja(AParent: TfrxComponent; ALeft, ATop, AWidth,
      AHeight: Extended);
    procedure CeldaTitulo(AParent: TfrxComponent; const ATexto: string;
      ALeft, AWidth: Extended; AAlineacion: TfrxHAlign);
    procedure CeldaLinea(AParent: TfrxComponent; const ATexto: string;
      ALeft, AWidth: Extended; AAlineacion: TfrxHAlign);
    procedure CrearSujeto(ABanda: TfrxBand; const AEtiqueta, ANombre,
      ABloque: string; ALeft: Extended);
    procedure CrearCabecera(APagina: TfrxReportPage);
    procedure CrearDetalle(APagina: TfrxReportPage);
    procedure CrearDesgloseIva(AResumen: TfrxBand);
    procedure CrearFilaTotal(AResumen: TfrxBand; const AEtiqueta,
      AValor: string; ATop: Extended; const AAlVisualizar: string);
    procedure CrearTotales(APagina: TfrxReportPage);
    procedure CrearPie(APagina: TfrxReportPage);
    procedure CrearInforme;
  end;

function TInformeDocumento.Memo(AParent: TfrxComponent;
  const ATexto: string; ALeft, ATop, AWidth,
  AHeight: Extended): TfrxMemoView;
begin
  Result := TfrxMemoView.Create(AParent);
  Result.CreateUniqueName;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
  Result.Font.Name := 'Arial';
  Result.Font.Size := 9;
  Result.Font.Color := clBlack;
  Result.WordWrap := False;
  Result.VAlign := vaCenter;
  Result.Text := ATexto;
end;

function TInformeDocumento.Importe(const ACampo: string): string;
begin
  Result := '[FormatFloat(''' + FORMATO_IMPORTE + ''', <' + ACampo +
    '>)]';
end;

procedure TInformeDocumento.Caja(AParent: TfrxComponent; ALeft, ATop,
  AWidth, AHeight: Extended);
var
  oCaja: TfrxMemoView;
begin
  oCaja := Memo(AParent, '', ALeft, ATop, AWidth, AHeight);
  oCaja.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  oCaja.Frame.Color := COLOR_LINEA;
end;

procedure TInformeDocumento.CeldaTitulo(AParent: TfrxComponent;
  const ATexto: string; ALeft, AWidth: Extended; AAlineacion: TfrxHAlign);
var
  oCelda: TfrxMemoView;
begin
  oCelda := Memo(AParent, ATexto, ALeft, 0, AWidth, 22);
  oCelda.Font.Style := [fsBold];
  oCelda.Color := COLOR_FONDO;
  oCelda.Frame.Typ := [ftTop, ftBottom];
  oCelda.Frame.Color := COLOR_LINEA;
  oCelda.GapX := 5;
  oCelda.HAlign := AAlineacion;
end;

procedure TInformeDocumento.CeldaLinea(AParent: TfrxComponent;
  const ATexto: string; ALeft, AWidth: Extended; AAlineacion: TfrxHAlign);
var
  oCelda: TfrxMemoView;
begin
  oCelda := Memo(AParent, ATexto, ALeft, 0, AWidth, ALTO_FILA + 4);
  oCelda.WordWrap := AAlineacion = haLeft;
  oCelda.StretchMode := smMaxHeight;
  oCelda.VAlign := vaTop;
  oCelda.GapX := 5;
  oCelda.GapY := 4;
  oCelda.Frame.Typ := [ftBottom];
  oCelda.Frame.Color := COLOR_LINEA;
  oCelda.HAlign := AAlineacion;
end;

procedure TInformeDocumento.CrearSujeto(ABanda: TfrxBand;
  const AEtiqueta, ANombre, ABloque: string; ALeft: Extended);
var
  oTexto: TfrxMemoView;
begin
  oTexto := Memo(ABanda, AEtiqueta, ALeft, 100, ANCHO_CAJA, 18);
  oTexto.Font.Style := [fsBold];
  oTexto.Font.Color := COLOR_TENUE;
  Caja(ABanda, ALeft, 120, ANCHO_CAJA, 118);
  oTexto := Memo(ABanda, ANombre, ALeft + 10, 126, ANCHO_CAJA - 20, 20);
  oTexto.Font.Size := 10;
  oTexto.Font.Style := [fsBold];
  oTexto := Memo(ABanda, ABloque, ALeft + 10, 148, ANCHO_CAJA - 20, 86);
  oTexto.WordWrap := True;
  oTexto.VAlign := vaTop;
end;

procedure TInformeDocumento.CrearCabecera(APagina: TfrxReportPage);
var
  oBanda: TfrxReportTitle;
  oTexto: TfrxMemoView;
begin
  oBanda := TfrxReportTitle.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.Height := 252;
  oTexto := Memo(oBanda, UpperCase(FTitulo), 0, 0, FAncho, 30);
  oTexto.Font.Size := 16;
  oTexto.Font.Style := [fsBold, fsUnderline];
  oTexto.HAlign := haCenter;
  oTexto := Memo(oBanda, SInformeNumeroDocumento, 0, 44, ANCHO_CAJA, 18);
  oTexto.Font.Size := 10;
  oTexto.Font.Style := [fsBold];
  Memo(oBanda, SInformeFechaDocumento, 0, 62, ANCHO_CAJA, 18).Font.Size :=
    10;
  Memo(oBanda, '[Cabecera."VALIDEZ"]', 0, 80, ANCHO_CAJA, 18).Font.Size :=
    10;
  CrearSujeto(oBanda, SInformeEmisorDocumento, '[Cabecera."EMPRESA"]',
    '[Cabecera."BLOQUE_EMPRESA"]', 0);
  CrearSujeto(oBanda, FEtiquetaTercero, '[Cabecera."TERCERO"]',
    '[Cabecera."BLOQUE_TERCERO"]', FAncho - ANCHO_CAJA);
end;

procedure TInformeDocumento.CrearDetalle(APagina: TfrxReportPage);
var
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
  Columnas: array[0..6] of Extended;
begin
  // Bordes de columna: codigo, descripcion, cantidad, precio, IVA,
  // importe y final de la tabla.
  Columnas[0] := 0;
  Columnas[1] := 95;
  Columnas[2] := FAncho - 322;
  Columnas[3] := FAncho - 247;
  Columnas[4] := FAncho - 167;
  Columnas[5] := FAncho - 112;
  Columnas[6] := FAncho;
  oCabecera := TfrxHeader.Create(APagina);
  oCabecera.CreateUniqueName;
  oCabecera.Top := 270;
  oCabecera.Height := 26;
  oCabecera.ReprintOnNewPage := True;
  CeldaTitulo(oCabecera, SInformeCodigoDocumento, Columnas[0],
    Columnas[1] - Columnas[0], haLeft);
  CeldaTitulo(oCabecera, SInformeDescripcionDocumento, Columnas[1],
    Columnas[2] - Columnas[1], haLeft);
  CeldaTitulo(oCabecera, SInformeCantidadDocumento, Columnas[2],
    Columnas[3] - Columnas[2], haRight);
  CeldaTitulo(oCabecera, SInformePrecioDocumento, Columnas[3],
    Columnas[4] - Columnas[3], haRight);
  CeldaTitulo(oCabecera, SInformeIvaDocumento, Columnas[4],
    Columnas[5] - Columnas[4], haRight);
  CeldaTitulo(oCabecera, SInformeImporteDocumento, Columnas[5],
    Columnas[6] - Columnas[5], haRight);
  oDetalle := TfrxMasterData.Create(APagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 310;
  oDetalle.DataSet := FLineas;
  oDetalle.Height := ALTO_FILA + 4;
  oDetalle.Stretched := True;
  // Una linea no se parte entre paginas.
  oDetalle.AllowSplit := False;
  CeldaLinea(oDetalle, '[Lineas."ARTICULO"]', Columnas[0],
    Columnas[1] - Columnas[0], haLeft);
  CeldaLinea(oDetalle, '[Lineas."DETALLE"]', Columnas[1],
    Columnas[2] - Columnas[1], haLeft);
  CeldaLinea(oDetalle,
    '[FormatFloat(''#,##0.##'', <Lineas."CANTIDAD">)] [Lineas."UNIDAD"]',
    Columnas[2], Columnas[3] - Columnas[2], haRight);
  CeldaLinea(oDetalle, Importe('Lineas."PRECIO"'), Columnas[3],
    Columnas[4] - Columnas[3], haRight);
  CeldaLinea(oDetalle, '[FormatFloat(''0.##'', <Lineas."IVA">)]',
    Columnas[4], Columnas[5] - Columnas[4], haRight);
  CeldaLinea(oDetalle, Importe('Lineas."TOTAL"'), Columnas[5],
    Columnas[6] - Columnas[5], haRight);
end;

// Tabla de IVA por tipo en un subinforme, a la izquierda de los
// totales: solo salen los tipos usados en el documento.
procedure TInformeDocumento.CrearDesgloseIva(AResumen: TfrxBand);
var
  oSubinforme: TfrxSubreport;
  oPagina: TfrxReportPage;
  oCabecera: TfrxHeader;
  oDetalle: TfrxMasterData;
begin
  oPagina := TfrxReportPage.Create(FInforme);
  oPagina.CreateUniqueName;
  oSubinforme := TfrxSubreport.Create(AResumen);
  oSubinforme.CreateUniqueName;
  oSubinforme.SetBounds(0, 12, 380, 104);
  oSubinforme.Page := oPagina;
  oCabecera := TfrxHeader.Create(oPagina);
  oCabecera.CreateUniqueName;
  oCabecera.Height := 22;
  CeldaTitulo(oCabecera, SInformeTipoIvaDocumento, 0, 110, haLeft);
  CeldaTitulo(oCabecera, SInformeBaseImponibleDocumento, 110, 100,
    haRight);
  CeldaTitulo(oCabecera, SInformePorcentajeIvaDocumento, 210, 70,
    haRight);
  CeldaTitulo(oCabecera, SInformeCuotaIvaDocumento, 280, 100, haRight);
  oDetalle := TfrxMasterData.Create(oPagina);
  oDetalle.CreateUniqueName;
  oDetalle.Top := 30;
  oDetalle.Height := ALTO_FILA + 4;
  oDetalle.DataSet := FImpuestos;
  CeldaLinea(oDetalle, '[Impuestos."NOMBRE"]', 0, 110, haLeft);
  CeldaLinea(oDetalle, Importe('Impuestos."BASE"'), 110, 100, haRight);
  CeldaLinea(oDetalle, '[FormatFloat(''0.##'', <Impuestos."PORCENTAJE">)]',
    210, 70, haRight);
  CeldaLinea(oDetalle, Importe('Impuestos."CUOTA"'), 280, 100, haRight);
end;

procedure TInformeDocumento.CrearFilaTotal(AResumen: TfrxBand;
  const AEtiqueta, AValor: string; ATop: Extended;
  const AAlVisualizar: string);
var
  oEtiqueta, oValor: TfrxMemoView;
begin
  oEtiqueta := Memo(AResumen, AEtiqueta, FAncho - 280, ATop, 160, 20);
  oEtiqueta.GapX := 5;
  oValor := Memo(AResumen, AValor + ' €', FAncho - 120, ATop, 120, 20);
  oValor.HAlign := haRight;
  oValor.GapX := 5;
  oEtiqueta.Frame.Typ := [ftBottom];
  oEtiqueta.Frame.Color := COLOR_LINEA;
  oValor.Frame.Typ := [ftBottom];
  oValor.Frame.Color := COLOR_LINEA;
  oEtiqueta.OnBeforePrint := AAlVisualizar;
  oValor.OnBeforePrint := AAlVisualizar;
end;

procedure TInformeDocumento.CrearTotales(APagina: TfrxReportPage);
var
  oResumen: TfrxReportSummary;
  oTotal: TfrxMemoView;
  oTexto: TfrxMemoView;
begin
  oResumen := TfrxReportSummary.Create(APagina);
  oResumen.CreateUniqueName;
  oResumen.Top := 350;
  oResumen.Height := 200;
  oResumen.Stretched := True;
  CrearDesgloseIva(oResumen);
  CrearFilaTotal(oResumen, SInformeBaseImponibleDocumento,
    Importe('Cabecera."BASES"'), 12, '');
  CrearFilaTotal(oResumen, SInformeTotalIvaDocumento,
    Importe('Cabecera."IMPUESTOS"'), 32, '');
  CrearFilaTotal(oResumen, SInformeRetencionIrpfDocumento,
    '-' + Importe('Cabecera."RETENCION"'), 52, 'RetencionOnBeforePrint');
  oTotal := Memo(oResumen, SInformeTotalLiquidoDocumento, FAncho - 280, 80,
    280, 28);
  oTotal.Font.Size := 11;
  oTotal.Font.Style := [fsBold];
  oTotal.Color := COLOR_FONDO;
  oTotal.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  oTotal.Frame.Width := 1.5;
  oTotal.GapX := 8;
  oTotal := Memo(oResumen, Importe('Cabecera."TOTAL"') + ' €',
    FAncho - 160, 80, 160, 28);
  oTotal.Font.Size := 11;
  oTotal.Font.Style := [fsBold];
  oTotal.HAlign := haRight;
  oTotal.GapX := 8;
  oTexto := Memo(oResumen, SInformeFormaPagoDescDocumento, 0, 126, FAncho,
    20);
  oTexto.OnBeforePrint := 'FormaPagoOnBeforePrint';
  oTexto := Memo(oResumen, SInformeObservacionesDocumento, 0, 152,
    FAncho, 20);
  oTexto.Font.Style := [fsBold];
  oTexto.Font.Color := COLOR_TENUE;
  oTexto.OnBeforePrint := 'NotasOnBeforePrint';
  oTexto := Memo(oResumen, '[Cabecera."NOTAS"]', 0, 172, FAncho, 24);
  oTexto.WordWrap := True;
  oTexto.VAlign := vaTop;
  oTexto.GapX := 8;
  oTexto.GapY := 5;
  oTexto.StretchMode := smActualHeight;
  oTexto.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
  oTexto.Frame.Color := COLOR_LINEA;
  oTexto.OnBeforePrint := 'NotasOnBeforePrint';
end;

procedure TInformeDocumento.CrearPie(APagina: TfrxReportPage);
var
  oPie: TfrxPageFooter;
  oTexto: TfrxMemoView;
begin
  oPie := TfrxPageFooter.Create(APagina);
  oPie.CreateUniqueName;
  oPie.Top := 700;
  oPie.Height := 24;
  oTexto := Memo(oPie, '[Cabecera."EMPRESA"] · ' + SInformeNifDocumento +
    '[Cabecera."NIF_EMPRESA"]', 0, 4, FAncho - 150, 18);
  oTexto.Font.Size := 8;
  oTexto.Font.Color := COLOR_TENUE;
  oTexto.Frame.Typ := [ftTop];
  oTexto.Frame.Color := COLOR_LINEA;
  oTexto := Memo(oPie, SInformePaginaDocumento, FAncho - 150, 4, 150, 18);
  oTexto.Font.Size := 8;
  oTexto.Font.Color := COLOR_TENUE;
  oTexto.HAlign := haRight;
  oTexto.Frame.Typ := [ftTop];
  oTexto.Frame.Color := COLOR_LINEA;
end;

procedure TInformeDocumento.CrearInforme;
var
  oPagina: TfrxReportPage;
begin
  FInforme.Clear;
  FInforme.DataSets.Add(FCabecera);
  FInforme.DataSets.Add(FLineas);
  FInforme.DataSets.Add(FImpuestos);
  FInforme.EngineOptions.DoublePass := True;
  FInforme.ScriptLanguage := 'PascalScript';
  FInforme.ScriptText.Text := SCRIPT_INFORME;
  oPagina := TfrxReportPage.Create(FInforme);
  oPagina.CreateUniqueName;
  oPagina.SetDefaults;
  oPagina.LeftMargin := 10;
  oPagina.RightMargin := 10;
  oPagina.TopMargin := 10;
  oPagina.BottomMargin := 10;
  FAncho := (oPagina.PaperWidth - oPagina.LeftMargin -
    oPagina.RightMargin) * PIXELES_POR_MM;
  CrearCabecera(oPagina);
  CrearDetalle(oPagina);
  CrearTotales(oPagina);
  CrearPie(oPagina);
end;

procedure CrearInformeDocumento(AInforme: TfrxReport;
  ACabecera, ALineas, AImpuestos: TfrxDBDataset;
  const ATitulo, AEtiquetaTercero: string);
var
  oConstructor: TInformeDocumento;
begin
  oConstructor := TInformeDocumento.Create;
  try
    oConstructor.FInforme := AInforme;
    oConstructor.FCabecera := ACabecera;
    oConstructor.FLineas := ALineas;
    oConstructor.FImpuestos := AImpuestos;
    oConstructor.FTitulo := ATitulo;
    oConstructor.FEtiquetaTercero := AEtiquetaTercero;
    oConstructor.CrearInforme;
  finally
    FreeAndNil(oConstructor);
  end;
end;

end.
