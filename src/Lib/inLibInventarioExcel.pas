{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventarioExcel                                          }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exporta e importa inventarios via dxSpreadSheet.                          }
{    - ExportarInventarioExcel: vuelca cabecera + lineas a una hoja con        }
{      preview editable (mismo patron que inLibDocCompraExcel).                }
{    - ImportarInventarioExcel: lee un .xlsx y devuelve una lista de pares     }
{      SKU=CANTIDAD para que el DM los cargue via CargarDesdeListaSkus. }
{******************************************************************************}
unit inLibInventarioExcel;

interface

uses
  DB, System.SysUtils, System.Classes,
  dxSpreadSheet, dxSpreadSheetCore, cxGraphics, Vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics,
  dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel, inLibHojaCalculoIntf;

type
  TLineaImportada = record
    Sku: string;
    Cantidad: Double;
    PmpNuevo: Double;
    TienePmp: Boolean;
  end;
  TLineasImportadas = TArray<TLineaImportada>;

  TCampoIncidenciaImportacionInventario = (
    ciiCantidad,
    ciiPmpNuevo);

  TIncidenciaImportacionInventario = record
    Fila: Integer;
    Sku: string;
    Campo: TCampoIncidenciaImportacionInventario;
    Valor: string;
  end;
  TIncidenciasImportacionInventario =
    TArray<TIncidenciaImportacionInventario>;

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);

// Lee la hoja a través del lector (ILectorHojaCalculo). Busca columnas SKU,
// Cantidad y PMP Nuevo por cabecera (fila 0). Si no encuentra cabecera, asume
// col A=SKU, col B=Cantidad. Los valores no numericos se devuelven como
// incidencias y dejan vacias ambas salidas de datos para impedir una
// importacion parcial.
procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AIncidencias: TIncidenciasImportacionInventario;
  out AMsg: string);

implementation

uses
  System.Variants;

const
  FMT_EUR = '#,##0.00" '#$20AC'"';
  COL_LINEA = 0;
  COL_ART   = 1;
  COL_SKU   = 2;
  COL_DESC  = 3;
  COL_LOTE  = 4;
  COL_CADUC = 5;
  COL_TEOR  = 6;
  COL_FISIC = 7;
  COL_DIF   = 8;
  COL_PMP   = 9;
  COL_PMPN  = 10;
  COL_COSTE = 11;
  COL_MAX   = 11;

// =============================================================================
//   EXPORTAR
// =============================================================================

procedure EscribirCabeceraInventario(
  AHoja: TdxSpreadSheetTableView;
  const AMaestro: TDataSet;
  var AFila: Integer);
begin
  AFila := 1;
  W(AHoja, AFila, 0, 'INVENTARIO', True);
  AHoja.Cells[AFila, 0].Style.Font.Size := 16;
  Inc(AFila, 2);
  W(AHoja, AFila, 0, 'Empresa:', True);
  W(AHoja, AFila, 1, AMaestro.FieldByName('CODIGO_EMP_INV').AsString);
  W(AHoja, AFila, 3, 'Almacen:', True);
  W(AHoja, AFila, 4, AMaestro.FieldByName('CODIGO_ALM_INV').AsString);
  Inc(AFila);
  W(AHoja, AFila, 0, 'Serie:', True);
  W(AHoja, AFila, 1, AMaestro.FieldByName('SERIE_INV').AsString);
  W(AHoja, AFila, 3, 'Numero:', True);
  W(AHoja, AFila, 4, AMaestro.FieldByName('NUMERO_INV').AsString);
  Inc(AFila);
  W(AHoja, AFila, 0, 'Fecha:', True);
  W(AHoja, AFila, 1, AMaestro.FieldByName('FECHA_INV').AsString);
  W(AHoja, AFila, 3, 'Estado:', True);
  W(AHoja, AFila, 4, AMaestro.FieldByName('ESTADO_INV').AsString);
  if AMaestro.FindField('DESCRIPCION_INV') <> nil then
  begin
    Inc(AFila);
    W(AHoja, AFila, 0, 'Descripcion:', True);
    W(AHoja, AFila, 1,
      AMaestro.FieldByName('DESCRIPCION_INV').AsString);
    Merge(AHoja, AFila, 1, 5, 1);
  end;
end;

procedure EscribirTitulosInventario(
  AHoja: TdxSpreadSheetTableView;
  var AFila: Integer);
var
  iColumna: Integer;
begin
  Inc(AFila, 2);
  W(AHoja, AFila, COL_LINEA, 'Linea', True, ssahCenter);
  W(AHoja, AFila, COL_ART, 'Articulo', True, ssahCenter);
  W(AHoja, AFila, COL_SKU, 'SKU', True, ssahCenter);
  W(AHoja, AFila, COL_DESC, 'Descripcion', True, ssahCenter);
  W(AHoja, AFila, COL_LOTE, 'Lote', True, ssahCenter);
  W(AHoja, AFila, COL_CADUC, 'Caducidad', True, ssahCenter);
  W(AHoja, AFila, COL_TEOR, 'Uds. Teor.', True, ssahRight);
  W(AHoja, AFila, COL_FISIC, 'Uds. Fisicas', True, ssahRight);
  W(AHoja, AFila, COL_DIF, 'Diferencia', True, ssahRight);
  W(AHoja, AFila, COL_PMP, 'PMP Actual', True, ssahRight);
  W(AHoja, AFila, COL_PMPN, 'PMP Nuevo', True, ssahRight);
  W(AHoja, AFila, COL_COSTE, 'Dif. Coste', True, ssahRight);
  for iColumna := 0 to COL_MAX do
  begin
    if AHoja.Cells[AFila, iColumna] <> nil then
    begin
      AHoja.Cells[AFila, iColumna].Style.Font.Color := clWhite;
      AHoja.Cells[AFila, iColumna].Style.Brush.BackgroundColor :=
        $00666666;
      AHoja.Cells[AFila, iColumna].Style.Borders[bBottom].Style :=
        sscbsThin;
    end;
  end;
end;

procedure EscribirLineaInventario(
  AHoja: TdxSpreadSheetTableView;
  const ALineas: TDataSet;
  AFila: Integer);
var
  dValor: Double;
begin
  W(AHoja, AFila, COL_LINEA,
    ALineas.FieldByName('LINEA_INVLIN').AsString, False, ssahCenter);
  W(AHoja, AFila, COL_ART,
    ALineas.FieldByName('CODIGO_ART_INVLIN').AsString);
  W(AHoja, AFila, COL_SKU,
    ALineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString);
  W(AHoja, AFila, COL_DESC,
    ALineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString);
  if ALineas.FindField('LOTE_INVLIN') <> nil then
    W(AHoja, AFila, COL_LOTE,
      ALineas.FieldByName('LOTE_INVLIN').AsString);
  if (ALineas.FindField('FECHA_CADUCIDAD_INVLIN') <> nil) and
     (not ALineas.FieldByName('FECHA_CADUCIDAD_INVLIN').IsNull) then
    W(AHoja, AFila, COL_CADUC,
      ALineas.FieldByName('FECHA_CADUCIDAD_INVLIN').AsString);
  dValor := ALineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsFloat;
  W(AHoja, AFila, COL_TEOR, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_TEOR].Style.DataFormat.FormatCode := '0';
  dValor := ALineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsFloat;
  W(AHoja, AFila, COL_FISIC, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_FISIC].Style.DataFormat.FormatCode := '0';
  WFormula(AHoja, AFila, COL_DIF,
    '=' + GetRef(AFila, COL_FISIC) + '-' + GetRef(AFila, COL_TEOR),
    '0');
  dValor := ALineas.FieldByName('PRECIO_MEDIO_INVLIN').AsFloat;
  W(AHoja, AFila, COL_PMP, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_PMP].Style.DataFormat.FormatCode := FMT_EUR;
  dValor := ALineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsFloat;
  W(AHoja, AFila, COL_PMPN, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_PMPN].Style.DataFormat.FormatCode := FMT_EUR;
  dValor :=
    ALineas.FieldByName('TOTAL_COSTE_DIFERENCIA_INVLIN').AsFloat;
  W(AHoja, AFila, COL_COSTE, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_COSTE].Style.DataFormat.FormatCode := FMT_EUR;
end;

procedure EscribirLineasInventario(
  AHoja: TdxSpreadSheetTableView;
  const ALineas: TDataSet;
  var AFila: Integer;
  out AFilaInicial, AFilaFinal: Integer);
begin
  Inc(AFila);
  AFilaInicial := AFila;
  if (ALineas <> nil) and ALineas.Active and
     (not ALineas.IsEmpty) then
  begin
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        EscribirLineaInventario(AHoja, ALineas, AFila);
        Inc(AFila);
        ALineas.Next;
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
  AFilaFinal := AFila - 1;
end;

procedure EscribirTotalesInventario(
  AHoja: TdxSpreadSheetTableView;
  var AFila: Integer;
  AFilaInicial, AFilaFinal: Integer);
var
  iColumna: Integer;
begin
  if AFilaFinal >= AFilaInicial then
  begin
    Inc(AFila);
    W(AHoja, AFila, COL_DESC, 'TOTALES', True, ssahRight);
    WFormula(AHoja, AFila, COL_TEOR,
      '=SUM(' + GetRef(AFilaInicial, COL_TEOR) + ':' +
      GetRef(AFilaFinal, COL_TEOR) + ')', '0');
    AHoja.Cells[AFila, COL_TEOR].Style.Font.Style := [fsBold];
    WFormula(AHoja, AFila, COL_FISIC,
      '=SUM(' + GetRef(AFilaInicial, COL_FISIC) + ':' +
      GetRef(AFilaFinal, COL_FISIC) + ')', '0');
    AHoja.Cells[AFila, COL_FISIC].Style.Font.Style := [fsBold];
    WFormula(AHoja, AFila, COL_DIF,
      '=SUM(' + GetRef(AFilaInicial, COL_DIF) + ':' +
      GetRef(AFilaFinal, COL_DIF) + ')', '0');
    AHoja.Cells[AFila, COL_DIF].Style.Font.Style := [fsBold];
    WFormula(AHoja, AFila, COL_COSTE,
      '=SUM(' + GetRef(AFilaInicial, COL_COSTE) + ':' +
      GetRef(AFilaFinal, COL_COSTE) + ')', FMT_EUR);
    AHoja.Cells[AFila, COL_COSTE].Style.Font.Style := [fsBold];
    AHoja.Cells[AFila, COL_COSTE].Style.Font.Size := 13;
    for iColumna := COL_DESC to COL_MAX do
    begin
      if AHoja.Cells[AFila, iColumna] <> nil then
        AHoja.Cells[AFila, iColumna].Style.Borders[bTop].Style :=
          sscbsThin;
    end;
  end;
end;

procedure AjustarAnchosInventario(AHoja: TdxSpreadSheetTableView);
begin
  AHoja.Columns[COL_LINEA].Size := 50;
  AHoja.Columns[COL_ART].Size := 100;
  AHoja.Columns[COL_SKU].Size := 150;
  AHoja.Columns[COL_DESC].Size := 200;
  AHoja.Columns[COL_LOTE].Size := 80;
  AHoja.Columns[COL_CADUC].Size := 80;
  AHoja.Columns[COL_TEOR].Size := 70;
  AHoja.Columns[COL_FISIC].Size := 75;
  AHoja.Columns[COL_DIF].Size := 70;
  AHoja.Columns[COL_PMP].Size := 80;
  AHoja.Columns[COL_PMPN].Size := 80;
  AHoja.Columns[COL_COSTE].Size := 90;
end;

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);
var
  oHoja: TdxSpreadSheetTableView;
  iFila: Integer;
  iFilaInicial: Integer;
  iFilaFinal: Integer;
begin
  ASheetControl.ClearAll;
  oHoja := ASheetControl.AddSheet(
    'Inventario',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oHoja.BeginUpdate;
  try
    EscribirCabeceraInventario(oHoja, QMaster, iFila);
    EscribirTitulosInventario(oHoja, iFila);
    EscribirLineasInventario(
      oHoja,
      QLineas,
      iFila,
      iFilaInicial,
      iFilaFinal);
    EscribirTotalesInventario(
      oHoja,
      iFila,
      iFilaInicial,
      iFilaFinal);
    AjustarAnchosInventario(oHoja);
  finally
    oHoja.EndUpdate;
  end;
end;

// =============================================================================
//   IMPORTAR
// =============================================================================

procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AIncidencias: TIncidenciasImportacionInventario;
  out AMsg: string);
var
  iColSku, iColCant, iColPmp: Integer;
  r, c, iLastRow: Integer;
  sSku, sCant, sPmp: string;
  iLeidas, iVacias: Integer;
  lin: TLineaImportada;
  bCantidadValida, bPmpValido: Boolean;

  function CellText(ARow, ACol: Integer): string;
  var
    vCelda: Variant;
  begin
    Result := '';
    if ACol >= 0 then
    begin
      vCelda := ALector.LeerCelda(ARow, ACol);
      if not VarIsNull(vCelda) then
        Result := Trim(VarToStr(vCelda));
    end;
  end;

  procedure AgregarIncidencia(
    AFila: Integer;
    const ASku: string;
    ACampo: TCampoIncidenciaImportacionInventario;
    const AValor: string);
  var
    iIncidencia: Integer;
  begin
    iIncidencia := Length(AIncidencias);
    SetLength(AIncidencias, iIncidencia + 1);
    AIncidencias[iIncidencia].Fila := AFila;
    AIncidencias[iIncidencia].Sku := ASku;
    AIncidencias[iIncidencia].Campo := ACampo;
    AIncidencias[iIncidencia].Valor := AValor;
  end;

begin
  ALista := TStringList.Create;
  SetLength(ALineas, 0);
  SetLength(AIncidencias, 0);
  AMsg := '';
  // Buscar columnas por cabecera (fila 0)
  iColSku  := -1;
  iColCant := -1;
  iColPmp  := -1;
  for c := 0 to 20 do
  begin
    var sHdr := UpperCase(CellText(0, c));
    if (sHdr = 'SKU') or (sHdr = 'CODIGO_UNIDAD') or
       (sHdr = 'CODIGO UNIDAD') or (sHdr = 'UNIDAD') then
      iColSku := c
    else if (sHdr = 'CANTIDAD') or
            (sHdr = 'UDS') or (sHdr = 'UDS. FISICAS') or
            (sHdr = 'FISICAS') or (sHdr = 'QTY') then
      iColCant := c
    else if (sHdr = 'PMP NUEVO') or (sHdr = 'PMP_NUEVO') or
            (sHdr = 'PRECIO_MEDIO_NUEVO') or (sHdr = 'PMP') then
      iColPmp := c;
  end;
  var iFilaInicio := 1;
  if iColSku < 0 then
  begin
    iColSku := 0;
    iColCant := 1;
    iFilaInicio := 0;
  end;
  iLastRow := ALector.UltimaFila;
  if iLastRow < iFilaInicio then
  begin
    AMsg := 'La hoja está vacía o no tiene datos.';
  end
  else
  begin
    iLeidas := 0;
    iVacias := 0;
    for r := iFilaInicio to iLastRow do
    begin
      sSku := CellText(r, iColSku);
      if sSku = '' then
        Inc(iVacias)
      else
      begin
        sCant := CellText(r, iColCant);
        lin := Default(TLineaImportada);
        lin.Sku := sSku;
        bCantidadValida := True;
        if sCant = '' then
        begin
          sCant := '1';
          lin.Cantidad := 1;
        end
        else if not TryStrToFloat(sCant, lin.Cantidad) then
        begin
          AgregarIncidencia(r + 1, sSku, ciiCantidad, sCant);
          bCantidadValida := False;
        end;
        sPmp := CellText(r, iColPmp);
        bPmpValido := True;
        if sPmp <> '' then
        begin
          if TryStrToFloat(sPmp, lin.PmpNuevo) then
            lin.TienePmp := True
          else
          begin
            AgregarIncidencia(r + 1, sSku, ciiPmpNuevo, sPmp);
            bPmpValido := False;
          end;
        end;
        if bCantidadValida and bPmpValido then
        begin
          ALista.Add(sSku + '=' + sCant);
          SetLength(ALineas, Length(ALineas) + 1);
          ALineas[High(ALineas)] := lin;
          Inc(iLeidas);
        end;
      end;
    end;
    if Length(AIncidencias) > 0 then
    begin
      SetLength(ALineas, 0);
      ALista.Clear;
    end
    else
      AMsg := Format('Leidas %d lineas (%d vacias ignoradas).',
        [iLeidas, iVacias]);
  end;
end;

end.
