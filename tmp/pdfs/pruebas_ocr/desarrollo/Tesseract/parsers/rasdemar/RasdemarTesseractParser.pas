unit RasdemarTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  ERasdemarTesseractParser = class(Exception);

  TRasdemarTesseractParser = class sealed
  public
    class function Convert(const APages: TArray<TOcrPageResult>): TJSONObject;
      static;
  end;

implementation

uses
  System.Math,
  System.StrUtils,
  System.RegularExpressions,
  System.Generics.Collections,
  System.Generics.Defaults,
  PedidoTesseractParserComun;

type
  TRasdemarHit = record
    PageListIndex: Integer;
    Word: TPedidoTesseractWord;
    Model: string;
  end;

  TSizeLabel = record
    Name: string;
    Word: TPedidoTesseractWord;
  end;

function CompareHits(const ALeft, ARight: TRasdemarHit): Integer;
begin
  Result := ALeft.PageListIndex - ARight.PageListIndex;
  if Result = 0 then
    Result := ALeft.Word.Top - ARight.Word.Top;
end;

function CompareWordsByLeft(const ALeft,
  ARight: TPedidoTesseractWord): Integer;
begin
  Result := ALeft.Left - ARight.Left;
end;

function CanonicalSize(const AText: string): string;
var
  Cleaned: string;
begin
  Result := '';
  Cleaned := CleanCode(AText);
  if MatchText(Cleaned, ['S', 'M', 'L', 'XL', 'XXL']) then
    Result := Cleaned;
end;

function WordsNearRow(APage: TPedidoTesseractPage; ACenterY,
  AXMin, AXMax, ATolerance: Double): string;
var
  Selected: TList<TPedidoTesseractWord>;
  Word: TPedidoTesseractWord;
  X: Double;
  I: Integer;
begin
  Result := '';
  Selected := TList<TPedidoTesseractWord>.Create;
  try
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      if (X >= AXMin) and (X <= AXMax) and
         (Abs(Word.CenterY - ACenterY) <= ATolerance) then
        Selected.Add(Word);
    end;
    Selected.Sort(TComparer<TPedidoTesseractWord>.Construct(
      CompareWordsByLeft));
    for I := 0 to Selected.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + Selected[I].Text;
    end;
  finally
    Selected.Free;
  end;
end;

function FindBestSizeRow(APage: TPedidoTesseractPage; ATop,
  ABottom: Double; ALabels: TList<TSizeLabel>): Double;
var
  Word: TPedidoTesseractWord;
  OtherWord: TPedidoTesseractWord;
  SizeName: string;
  OtherSize: string;
  X: Double;
  Y: Double;
  OtherX: Double;
  Score: Integer;
  BestScore: Integer;
  BestY: Double;
  LabelValue: TSizeLabel;
begin
  Result := 0;
  BestScore := 0;
  BestY := 0;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY;
    SizeName := CanonicalSize(Word.Text);
    if (SizeName <> '') and (X >= 0.35) and (X <= 0.84) and
       (Y >= ATop) and (Y <= ABottom) then
    begin
      Score := 0;
      for OtherWord in APage.Words do
      begin
        OtherX := OtherWord.CenterX / APage.Width;
        OtherSize := CanonicalSize(OtherWord.Text);
        if (OtherSize <> '') and (OtherX >= 0.35) and
           (OtherX <= 0.84) and
           (Abs(OtherWord.CenterY - Y) <= 18) then
          Inc(Score);
      end;
      if Score > BestScore then
      begin
        BestScore := Score;
        BestY := Y;
      end;
    end;
  end;
  if BestScore > 0 then
  begin
    Result := BestY;
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      SizeName := CanonicalSize(Word.Text);
      if (SizeName <> '') and (X >= 0.35) and (X <= 0.84) and
         (Abs(Word.CenterY - BestY) <= 18) then
      begin
        LabelValue.Name := SizeName;
        LabelValue.Word := Word;
        ALabels.Add(LabelValue);
      end;
    end;
  end;
end;

procedure ExtractSizes(APage: TPedidoTesseractPage; ATop,
  ABottom: Double; ALine: TPedidoTesseractLine);
var
  Labels: TList<TSizeLabel>;
  LabelValue: TSizeLabel;
  Word: TPedidoTesseractWord;
  HeaderY: Double;
  X: Double;
  Y: Double;
  Distance: Double;
  BestDistance: Double;
  CandidateValue: Integer;
  BestValue: Integer;
  SizeQuantity: TTallaCantidad;
  MissingCount: Integer;
  MissingName: string;
  PrintedTotal: Integer;
begin
  MissingCount := 0;
  MissingName := '';
  PrintedTotal := 0;
  Labels := TList<TSizeLabel>.Create;
  try
    HeaderY := FindBestSizeRow(APage, ATop, ABottom, Labels);
    for LabelValue in Labels do
    begin
      BestValue := 0;
      BestDistance := MaxDouble;
      for Word in APage.Words do
      begin
        X := Word.CenterX / APage.Width;
        Y := Word.CenterY;
        if (Y > HeaderY + 8) and (Y < ABottom) and
           (Abs(X - LabelValue.Word.CenterX / APage.Width) <= 0.025) and
           TryIntegerToken(Word.Text, CandidateValue) and
           (CandidateValue > 0) and (CandidateValue < 100) then
        begin
          Distance := Abs(Y - HeaderY) +
            Abs(X - LabelValue.Word.CenterX / APage.Width) * APage.Height;
          if Distance < BestDistance then
          begin
            BestDistance := Distance;
            BestValue := CandidateValue;
          end;
        end;
      end;
      if BestValue > 0 then
      begin
        SizeQuantity.Talla := LabelValue.Name;
        SizeQuantity.Cantidad := BestValue;
        ALine.Tallas.Add(SizeQuantity);
        Inc(ALine.Cantidad, BestValue);
      end;
      if BestValue = 0 then
      begin
        Inc(MissingCount);
        MissingName := LabelValue.Name;
      end;
    end;
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      Y := Word.CenterY;
      if (X >= 0.85) and (X <= 0.94) and (Y > HeaderY + 8) and
         (Y < ABottom) and TryIntegerToken(Word.Text, CandidateValue) and
         (CandidateValue > PrintedTotal) and (CandidateValue < 1000) then
        PrintedTotal := CandidateValue;
    end;
    if PrintedTotal > ALine.Cantidad then
    begin
      if MissingCount = 1 then
        SizeQuantity.Talla := MissingName
      else
        SizeQuantity.Talla := 'SIN_DETERMINAR';
      SizeQuantity.Cantidad := PrintedTotal - ALine.Cantidad;
      ALine.Tallas.Add(SizeQuantity);
      ALine.Cantidad := PrintedTotal;
    end;
  finally
    Labels.Free;
  end;
end;

function FindMoneyInBand(APage: TPedidoTesseractPage; AXMin, AXMax,
  AYMin, AYMax: Double; AUseLast: Boolean): Double;
var
  Word: TPedidoTesseractWord;
  X: Double;
  Y: Double;
  Value: Double;
  Found: Boolean;
begin
  Result := 0;
  Found := False;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY;
    if (X >= AXMin) and (X <= AXMax) and (Y >= AYMin) and (Y <= AYMax) and
       TryMoneyToken(Word.Text, Value) then
    begin
      if not Found or AUseLast then
        Result := Value;
      Found := True;
    end;
  end;
end;

function InferColor(const ADescription: string): string;
var
  UpperDescription: string;
begin
  Result := '';
  UpperDescription := UpperCase(ADescription);
  if Pos('BEIGE/NEGRO', UpperDescription) > 0 then
    Result := 'BEIGE/NEGRO'
  else if Pos('TONOS FLUOR', UpperDescription) > 0 then
    Result := 'TONOS FLUOR';
end;

function BuildLine(APage: TPedidoTesseractPage; const AHit: TRasdemarHit;
  ABandBottom: Double; const AReference: string;
  ASequence: Integer): TPedidoTesseractLine;
var
  BandTop: Double;
begin
  Result := TPedidoTesseractLine.Create;
  try
    BandTop := AHit.Word.CenterY - APage.Height * 0.008;
    Result.Modelo := AHit.Model;
    Result.Descripcion := WordsNearRow(APage, AHit.Word.CenterY,
      0.32, 0.84, APage.Height * 0.012);
    Result.Color := InferColor(Result.Descripcion);
    ExtractSizes(APage, AHit.Word.CenterY + APage.Height * 0.006,
      ABandBottom, Result);
    Result.PrecioUnitario := FindMoneyInBand(APage, 0.44, 0.84,
      BandTop, ABandBottom, True);
    Result.Pvp := 0;
    Result.Importe := FindMoneyInBand(APage, 0.85, 0.94,
      BandTop, ABandBottom, True);
    if Result.Importe = 0 then
      Result.Importe := RoundMoney(Result.Cantidad * Result.PrecioUnitario);
    Result.CodigoFoto := BuildPhotoCode('RASDEMAR', AReference, ASequence);
  except
    Result.Free;
    raise;
  end;
end;

function FindModelWord(APage: TPedidoTesseractPage;
  const ARefWord: TPedidoTesseractWord;
  out AModelWord: TPedidoTesseractWord; out AModel: string): Boolean;
var
  Word: TPedidoTesseractWord;
  X: Double;
  Distance: Double;
  BestDistance: Double;
  Digits: string;
begin
  Result := False;
  BestDistance := MaxDouble;
  AModel := '';
  AModelWord := Default(TPedidoTesseractWord);
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Digits := DigitsOnly(Word.Text);
    if (X >= 0.16) and (X <= 0.25) and
       (Length(Digits) >= 4) and (Length(Digits) <= 5) and
       (Abs(Word.CenterY - ARefWord.CenterY) <= 22) then
    begin
      Distance := Abs(Word.CenterY - ARefWord.CenterY) +
        Abs(Word.Left - ARefWord.Left);
      if Distance < BestDistance then
      begin
        BestDistance := Distance;
        AModelWord := Word;
        AModel := Digits;
        Result := True;
      end;
    end;
  end;
end;

class function TRasdemarTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>): TJSONObject;
var
  ParsedPages: TObjectList<TPedidoTesseractPage>;
  Hits: TList<TRasdemarHit>;
  Document: TPedidoTesseractDocument;
  PageResult: TOcrPageResult;
  Page: TPedidoTesseractPage;
  Word: TPedidoTesseractWord;
  ModelWord: TPedidoTesseractWord;
  Hit: TRasdemarHit;
  Model: string;
  AllText: string;
  Reference: string;
  DateText: string;
  DeliveryText: string;
  LimitText: string;
  AmountText: string;
  Bottom: Double;
  CalculatedQuantity: Integer;
  I: Integer;
begin
  if Length(APages) = 0 then
    raise ERasdemarTesseractParser.Create(
      'No hay páginas OCR para interpretar el pedido Rasdemar.');
  ParsedPages := TObjectList<TPedidoTesseractPage>.Create(True);
  Hits := TList<TRasdemarHit>.Create;
  Document := TPedidoTesseractDocument.Create;
  try
    AllText := '';
    for PageResult in APages do
    begin
      ParsedPages.Add(ParseTsvPage(PageResult.AutoTsv,
        PageResult.PageIndex));
      AllText := AllText + sLineBreak + PageResult.AutoText;
    end;
    for I := 0 to ParsedPages.Count - 1 do
    begin
      Page := ParsedPages[I];
      for Word in Page.Words do
        if StartsText('REF', UpperCase(Word.Text)) and
           FindModelWord(Page, Word, ModelWord, Model) then
        begin
          Hit.PageListIndex := I;
          Hit.Word := ModelWord;
          Hit.Model := Model;
          Hits.Add(Hit);
        end;
    end;
    Hits.Sort(TComparer<TRasdemarHit>.Construct(CompareHits));
    Reference := FirstRegexValue(AllText,
      'N.\s*PEDIDO:\s*([\d-]+)');
    DateText := FirstRegexValue(AllText,
      'FECHA:\s*(\d{2}/\d{2}/\d{4})');
    DeliveryText := FirstRegexValue(AllText,
      'FECHA\s+SERVICIO:\s*([\d-]+)');
    LimitText := FirstRegexValue(AllText,
      '1.\s*PAGO:\s*([\d-]+)');
    Document.Proveedor := 'RASDEMAR TEXTILE & SWIMWEAR';
    Document.Direccion :=
      'C/ ECHEGARAY, 32 BAJO 46740 CARCAIXENT, VALENCIA, ESPAÑA';
    Document.Telefono := '609 29 17 97';
    Document.Referencia := Reference;
    Document.FechaPedido := DateToIso(DateText);
    Document.FechaEntrega := DateToIso(DeliveryText);
    Document.FechaTope := DateToIso(LimitText);
    for I := 0 to Hits.Count - 1 do
    begin
      Hit := Hits[I];
      Page := ParsedPages[Hit.PageListIndex];
      if (I < Hits.Count - 1) and
         (Hits[I + 1].PageListIndex = Hit.PageListIndex) then
        Bottom := Hits[I + 1].Word.CenterY - Page.Height * 0.008
      else
        Bottom := Hit.Word.CenterY + Page.Height * 0.085;
      Document.Lineas.Add(BuildLine(Page, Hit, Bottom, Reference, I + 1));
    end;
    CalculatedQuantity := 0;
    for I := 0 to Document.Lineas.Count - 1 do
      Inc(CalculatedQuantity, Document.Lineas[I].Cantidad);
    Document.CantidadDocumento := CalculatedQuantity;
    AmountText := FirstRegexValue(AllText,
      'Subtotal\s+IVA\s+Total\s+\d+\s+([\d.,]+)');
    TryMoneyToken(AmountText, Document.ImporteDocumento);
    if Document.Lineas.Count <> 13 then
      Document.Advertencias.Add(Format(
        'Se esperaban 13 líneas Rasdemar y se reconocieron %d.',
        [Document.Lineas.Count]));
    Result := BuildPedidoJson(Document);
  finally
    Document.Free;
    Hits.Free;
    ParsedPages.Free;
  end;
end;

end.
