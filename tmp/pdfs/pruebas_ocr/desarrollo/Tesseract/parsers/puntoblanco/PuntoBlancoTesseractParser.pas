unit PuntoBlancoTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  EPuntoBlancoTesseractParser = class(Exception);

  TPuntoBlancoTesseractParser = class sealed
  public
    class function Convert(const APages: TArray<TOcrPageResult>): TJSONObject;
      static;
  end;

implementation

uses
  System.RegularExpressions,
  PedidoTesseractParserComun;

function BuildLine(const ABlock: string;
  AModelMatch: TMatch): TPedidoTesseractLine;
var
  RowMatches: TMatchCollection;
  RowMatch: TMatch;
  SizeQuantity: TTallaCantidad;
  Quantity: Integer;
  UnitPrice: Double;
begin
  Result := TPedidoTesseractLine.Create;
  try
    Result.Modelo := AModelMatch.Groups[1].Value;
    Result.Descripcion := Trim(AModelMatch.Groups[2].Value);
    Result.Color := '000 Duplo';
    RowMatches := TRegEx.Matches(ABlock,
      '(?m)^\s*(\d{2})\s+(\d+)\s+\d+\s+([\d.,]+)\s*$');
    for RowMatch in RowMatches do
    begin
      Quantity := 0;
      UnitPrice := 0;
      TryStrToInt(RowMatch.Groups[2].Value, Quantity);
      TryMoneyToken(RowMatch.Groups[3].Value, UnitPrice);
      SizeQuantity.Talla := RowMatch.Groups[1].Value;
      SizeQuantity.Cantidad := Quantity;
      Result.Tallas.Add(SizeQuantity);
      Inc(Result.Cantidad, Quantity);
      Result.PrecioUnitario := UnitPrice;
    end;
    Result.Pvp := 0;
    Result.Importe := RoundMoney(Result.Cantidad * Result.PrecioUnitario);
    Result.CodigoFoto := '';
  except
    Result.Free;
    raise;
  end;
end;

class function TPuntoBlancoTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>): TJSONObject;
var
  Document: TPedidoTesseractDocument;
  Page: TOcrPageResult;
  AllText: string;
  ModelMatches: TMatchCollection;
  ModelMatch: TMatch;
  Reference, DateText, DeliveryText, Block: string;
  NextIndex, I: Integer;
begin
  if Length(APages) = 0 then
    raise EPuntoBlancoTesseractParser.Create(
      'No hay páginas OCR para interpretar el pedido Punto Blanco.');
  AllText := '';
  for Page in APages do
    AllText := AllText + sLineBreak + Page.AutoText;
  ModelMatches := TRegEx.Matches(AllText,
    '(?m)^(\d{7})\s+(.+?)\s+000\s+Duplo\s*$');
  Document := TPedidoTesseractDocument.Create;
  try
    Reference := FirstRegexValue(AllText,
      'N\.\s*REF\.:\s*(\d+)');
    DateText := FirstRegexValue(AllText,
      '\b(\d{2}/\d{2}/\d{4})\s+N\.\s*REF');
    DeliveryText := FirstRegexValue(AllText,
      'Fecha Servicio:\s*(\d{2}/\d{2}/\d{4})');
    Document.Proveedor := 'INDUSTRIAS VALLS 1 S.A. - PUNTO BLANCO';
    Document.Direccion :=
      'Avda. Balmes, 16, 08700 Igualada, Barcelona, España';
    Document.Cif := 'A59060491';
    Document.Telefono := '+34 938 035 252';
    Document.Referencia := Reference;
    Document.FechaPedido := DateToIso(DateText);
    Document.FechaEntrega := DateToIso(DeliveryText);
    for I := 0 to ModelMatches.Count - 1 do
    begin
      ModelMatch := ModelMatches[I];
      if I + 1 < ModelMatches.Count then
        NextIndex := ModelMatches[I + 1].Index
      else
        NextIndex := Length(AllText);
      Block := Copy(AllText, ModelMatch.Index + 1,
        NextIndex - ModelMatch.Index);
      Document.Lineas.Add(BuildLine(Block, ModelMatch));
    end;
    if Document.Lineas.Count = 0 then
      Document.Advertencias.Add(
        'No se reconoció ninguna línea de detalle Punto Blanco.');
    Result := BuildPedidoJson(Document);
  finally
    Document.Free;
  end;
end;

end.
