unit AnitaTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  EAnitaTesseractParser = class(Exception);

  TAnitaTesseractParser = class sealed
  public
    class function Convert(const APages: TArray<TOcrPageResult>): TJSONObject;
      static;
  end;

implementation

uses
  System.Classes,
  System.RegularExpressions,
  System.Generics.Collections,
  PedidoTesseractParserComun;

function IsDescriptionNoise(const AText: string): Boolean;
var
  TextUpper: string;
begin
  TextUpper := UpperCase(Trim(AText));
  Result := (Length(TextUpper) <= 1) or
    TextUpper.StartsWith('P. COMPRA') or
    TextUpper.StartsWith('DESCUENTO') or
    (TextUpper = 'RED') or
    TextUpper.StartsWith('P.V.P') or
    TextUpper.StartsWith('SERVICIO A PARTIR') or
    TextUpper.StartsWith('TIPO DE PEDIDO') or
    TextUpper.StartsWith('CANTIDAD') or
    TextUpper.StartsWith('TOTAL NETO') or
    (TextUpper = 'FREE') or
    TextUpper.StartsWith('€') or
    TRegEx.IsMatch(TextUpper, '^[-0-9.,% ]+$') or
    TRegEx.IsMatch(TextUpper, '^[A-Z0-9]+\s*-\s*\d{3}\b');
end;

function DescriptionBefore(const AText: string; AMatchIndex: Integer): string;
var
  PreviousText: string;
  Lines: TStringList;
  I: Integer;
begin
  Result := '';
  PreviousText := Copy(AText, 1, AMatchIndex);
  Lines := TStringList.Create;
  try
    Lines.Text := PreviousText;
    I := Lines.Count - 1;
    while (I >= 0) and (Result = '') do
    begin
      if not IsDescriptionNoise(Lines[I]) then
        Result := Trim(TRegEx.Replace(Lines[I],
          '\s+Tipo de pedido:?\s*$', '', [roIgnoreCase]));
      Dec(I);
    end;
  finally
    Lines.Free;
  end;
end;

procedure AddUndeterminedSize(ALine: TPedidoTesseractLine);
var
  SizeQuantity: TTallaCantidad;
begin
  if ALine.Cantidad > 0 then
  begin
    SizeQuantity.Talla := 'SIN_DETERMINAR';
    SizeQuantity.Cantidad := ALine.Cantidad;
    ALine.Tallas.Add(SizeQuantity);
  end;
end;

procedure ExtractSizes(const ABlock: string; ALine: TPedidoTesseractLine);
var
  ServiceMatch, QuantityMatch, TailMatch, CupMatch: TMatch;
  SizeMatches, NumberMatches: TMatchCollection;
  Match: TMatch;
  Sizes: TList<string>;
  Quantities: TList<Integer>;
  LabelsText, TailText, Cup: string;
  SizeQuantity: TTallaCantidad;
  LabelStart, RemoveIndex, Value, Sum, I: Integer;
begin
  Sizes := TList<string>.Create;
  Quantities := TList<Integer>.Create;
  try
    ServiceMatch := TRegEx.Match(ABlock,
      '\d{2}-\d{2}-\d{4}');
    QuantityMatch := TRegEx.Match(ABlock, '\bCantidad\b',
      [roIgnoreCase]);
    if ServiceMatch.Success and QuantityMatch.Success and
       (QuantityMatch.Index > ServiceMatch.Index + ServiceMatch.Length) then
    begin
      LabelStart := ServiceMatch.Index + ServiceMatch.Length;
      LabelsText := Copy(ABlock, LabelStart + 1,
        QuantityMatch.Index - LabelStart);
      SizeMatches := TRegEx.Matches(LabelsText,
        '(?m)^\s*(0|[5-9]\d|1[0-4]\d)\s*$');
      for Match in SizeMatches do
        Sizes.Add(Match.Groups[1].Value);
    end;

    TailMatch := TRegEx.Match(ABlock,
      'Cantidad\s+Total neto(.*?)€\s*[\d.,]+',
      [roIgnoreCase, roSingleLine]);
    if TailMatch.Success then
    begin
      TailText := TailMatch.Groups[1].Value;
      CupMatch := TRegEx.Match(TailText, '(?m)^\s*([CD])\s*$');
      Cup := '';
      if CupMatch.Success then
        Cup := UpperCase(CupMatch.Groups[1].Value);
      NumberMatches := TRegEx.Matches(TailText,
        '(?m)^\s*(\d+)\s*$');
      for Match in NumberMatches do
      begin
        Value := 0;
        TryStrToInt(Match.Groups[1].Value, Value);
        Quantities.Add(Value);
      end;
    end;

    if Quantities.Count = Sizes.Count + 1 then
    begin
      RemoveIndex := -1;
      I := Quantities.Count - 1;
      while (I >= 0) and (RemoveIndex < 0) do
      begin
        if Quantities[I] = ALine.Cantidad then
          RemoveIndex := I;
        Dec(I);
      end;
      if RemoveIndex >= 0 then
        Quantities.Delete(RemoveIndex);
    end;

    Sum := 0;
    for Value in Quantities do
      Inc(Sum, Value);
    if (Sizes.Count > 0) and (Sizes.Count = Quantities.Count) and
       (Sum = ALine.Cantidad) then
    begin
      for I := 0 to Sizes.Count - 1 do
      begin
        SizeQuantity.Talla := Sizes[I] + Cup;
        SizeQuantity.Cantidad := Quantities[I];
        ALine.Tallas.Add(SizeQuantity);
      end;
    end
    else
      AddUndeterminedSize(ALine);
  finally
    Quantities.Free;
    Sizes.Free;
  end;
end;

function BuildLine(const AAllText, ABlock: string; AMatch: TMatch;
  const AReference: string; var APhotoSequence: Integer): TPedidoTesseractLine;
var
  TotalMatch: TMatch;
  MoneyMatches: TMatchCollection;
  Quantity, InferredQuantity: Integer;
  Amount, NetPrice, Pvp: Double;
begin
  Result := TPedidoTesseractLine.Create;
  try
    Result.Modelo := UpperCase(AMatch.Groups[1].Value);
    Result.Color := Trim(AMatch.Groups[2].Value + ' ' +
      AMatch.Groups[3].Value);
    Result.Descripcion := DescriptionBefore(AAllText, AMatch.Index);
    TotalMatch := TRegEx.Match(ABlock,
      'Cantidad\s+Total neto.*\b(\d+)\s+€\s*([\d.,]+)',
      [roIgnoreCase, roSingleLine]);
    Quantity := 0;
    Amount := 0;
    if TotalMatch.Success then
    begin
      TryStrToInt(TotalMatch.Groups[1].Value, Quantity);
      TryMoneyToken(TotalMatch.Groups[2].Value, Amount);
    end;
    MoneyMatches := TRegEx.Matches(ABlock, '€\s*([\d.,]+)');
    NetPrice := 0;
    if MoneyMatches.Count >= 2 then
      TryMoneyToken(MoneyMatches[1].Groups[1].Value, NetPrice);
    InferredQuantity := 0;
    if (Amount > 0) and (NetPrice > 0) then
      InferredQuantity := Round(Amount / NetPrice);
    if (InferredQuantity > 0) and
       (Abs(InferredQuantity * NetPrice - Amount) <= 0.05) then
      Quantity := InferredQuantity;
    Result.Cantidad := Quantity;
    Result.Importe := RoundMoney(Amount);
    Result.PrecioUnitario := NetPrice;
    Pvp := 0;
    if MoneyMatches.Count >= 3 then
      TryMoneyToken(MoneyMatches[2].Groups[1].Value, Pvp);
    Result.Pvp := Pvp;
    ExtractSizes(ABlock, Result);
    if TRegEx.IsMatch(Result.Modelo, '^\d{4}$') then
    begin
      Inc(APhotoSequence);
      Result.CodigoFoto := BuildPhotoCode('ANITA', AReference,
        APhotoSequence);
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TAnitaTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>): TJSONObject;
var
  Document: TPedidoTesseractDocument;
  Page: TOcrPageResult;
  AllText: string;
  ModelMatches: TMatchCollection;
  ModelMatch: TMatch;
  FooterMatch: TMatch;
  Reference, DateText, Block: string;
  NextIndex, I, PhotoSequence: Integer;
  Amount: Double;
begin
  if Length(APages) = 0 then
    raise EAnitaTesseractParser.Create(
      'No hay páginas OCR para interpretar el pedido Anita.');
  AllText := '';
  for Page in APages do
    AllText := AllText + sLineBreak + Page.SparseText;
  ModelMatches := TRegEx.Matches(AllText,
    '(?m)^([A-Z0-9]+)\s*-\s*(\d{3})\s+([^\r\n]+)$');
  Document := TPedidoTesseractDocument.Create;
  try
    Reference := FirstRegexValue(AllText,
      'Numero de pedido\s*([A-Z0-9]+)');
    DateText := FirstRegexValue(AllText,
      'Numero de pedido\s*[A-Z0-9]+\s*(\d{1,2}-\d{1,2}-\d{4})');
    Document.Proveedor := 'ANITA DR. HELBIG GMBH';
    Document.Direccion := 'Grafenstrasse 23, 83098 Brannenburg, Alemania';
    Document.Telefono := '';
    Document.Cif := '';
    Document.Referencia := Reference;
    Document.FechaPedido := DateToIso(DateText);
    PhotoSequence := 0;
    for I := 0 to ModelMatches.Count - 1 do
    begin
      ModelMatch := ModelMatches[I];
      if I + 1 < ModelMatches.Count then
        NextIndex := ModelMatches[I + 1].Index
      else
        NextIndex := Length(AllText);
      Block := Copy(AllText, ModelMatch.Index + 1,
        NextIndex - ModelMatch.Index);
      Document.Lineas.Add(BuildLine(AllText, Block, ModelMatch, Reference,
        PhotoSequence));
    end;
    FooterMatch := TRegEx.Match(AllText,
      'Total\s+(\d+)\s+([\d.,]+)\s+Base imponible',
      [roIgnoreCase, roSingleLine]);
    if FooterMatch.Success then
    begin
      TryStrToInt(FooterMatch.Groups[1].Value,
        Document.CantidadDocumento);
      Amount := 0;
      TryMoneyToken(FooterMatch.Groups[2].Value, Amount);
      Document.ImporteDocumento := RoundMoney(Amount);
    end;
    if Document.Lineas.Count = 0 then
      Document.Advertencias.Add(
        'No se reconoció ninguna línea de detalle Anita.');
    if PhotoSequence <> 10 then
      Document.Advertencias.Add(Format(
        'Se esperaban 10 líneas con foto Anita y se reconocieron %d.',
        [PhotoSequence]));
    Result := BuildPedidoJson(Document);
  finally
    Document.Free;
  end;
end;

end.
