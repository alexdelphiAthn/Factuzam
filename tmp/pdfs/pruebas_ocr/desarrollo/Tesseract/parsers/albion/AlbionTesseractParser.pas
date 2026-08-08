unit AlbionTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  EAlbionTesseractParser = class(Exception);

  TAlbionTesseractParser = class sealed
  public
    class function Convert(const APages: TArray<TOcrPageResult>): TJSONObject;
      static;
  end;

implementation

uses
  System.Classes,
  System.Math,
  System.StrUtils,
  System.Character,
  System.RegularExpressions,
  System.Generics.Collections,
  System.Generics.Defaults;

type
  TTesseractWord = record
    PageIndex: Integer;
    Left: Integer;
    Top: Integer;
    Width: Integer;
    Height: Integer;
    Confidence: Double;
    Text: string;
    function CenterX: Double;
    function CenterY: Double;
  end;

  TTesseractWordsPage = class
  public
    PageIndex: Integer;
    Width: Integer;
    Height: Integer;
    Words: TList<TTesseractWord>;
    constructor Create;
    destructor Destroy; override;
  end;

  TProductInfo = record
    Model: string;
    Description: string;
    Color: string;
  end;

  TModelHit = record
    CatalogIndex: Integer;
    PageListIndex: Integer;
    Word: TTesseractWord;
  end;

  TSizeQuantity = record
    Size: string;
    Quantity: Integer;
  end;

  TAlbionLine = class
  public
    Model: string;
    Description: string;
    Color: string;
    Sizes: TList<TSizeQuantity>;
    Quantity: Integer;
    UnitPrice: Double;
    Pvp: Double;
    Amount: Double;
    constructor Create;
    destructor Destroy; override;
  end;

const
  CProducts: array[0..7] of TProductInfo = (
    (Model: 'AFI-001';
     Description: 'W W LULU TEXTURED METAL TOE-POST SANDALS BLACK';
     Color: 'BLACK'),
    (Model: 'AFI-F23';
     Description: 'W W LULU TEXTURED METAL TOE-POST SANDALS OLIVE BROWN';
     Color: 'OLIVE BROWN'),
    (Model: 'AFJ-001';
     Description: 'W W LULU GLEAM TOE-POST SANDALS BLACK';
     Color: 'BLACK'),
    (Model: 'AFO-001';
     Description: 'W W LULU GLEAM SANDALS BLACK';
     Color: 'BLACK'),
    (Model: 'AHS-675';
     Description: 'W W LULU GLEAM METALLIC TOE-POST SANDALS PLATINO';
     Color: 'PLATINO'),
    (Model: 'AHW-675';
     Description: 'W W LULU METALLIC SANDALS PLATINO';
     Color: 'PLATINO'),
    (Model: 'EC3-F23';
     Description: 'W W LULU CRYSTAL EMBELLISHED BACK-STRAP SANDALS OLIVE BROWN';
     Color: 'OLIVE BROWN'),
    (Model: 'ECS-F23';
     Description: 'W W LULU CRYSTAL EMBELLISHED TOE-POST SANDALS OLIVE BROWN';
     Color: 'OLIVE BROWN')
  );

  CSizeNames: array[0..6] of string = ('36', '37', '38', '39', '40',
    '41', '42');
  CSizeCenters: array[0..6] of Double = (0.316, 0.354, 0.393, 0.431,
    0.470, 0.508, 0.547);

function TTesseractWord.CenterX: Double;
begin
  Result := Left + Width / 2.0;
end;

function TTesseractWord.CenterY: Double;
begin
  Result := Top + Height / 2.0;
end;

constructor TTesseractWordsPage.Create;
begin
  inherited;
  Words := TList<TTesseractWord>.Create;
end;

destructor TTesseractWordsPage.Destroy;
begin
  Words.Free;
  inherited;
end;

constructor TAlbionLine.Create;
begin
  inherited;
  Sizes := TList<TSizeQuantity>.Create;
end;

destructor TAlbionLine.Destroy;
begin
  Sizes.Free;
  inherited;
end;

function InvariantFormat: TFormatSettings;
begin
  Result := TFormatSettings.Create;
  Result.DecimalSeparator := '.';
  Result.ThousandSeparator := ',';
end;

function ParseTsv(const ATsv: string; APageIndex: Integer): TTesseractWordsPage;
var
  Lines, Fields: TStringList;
  I, Level: Integer;
  Word: TTesseractWord;
  FormatSettings: TFormatSettings;
begin
  Result := TTesseractWordsPage.Create;
  Result.PageIndex := APageIndex;
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    Lines.Text := ATsv;
    Fields.StrictDelimiter := True;
    Fields.Delimiter := #9;
    Fields.QuoteChar := '"';
    FormatSettings := InvariantFormat;

    for I := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[I]) = '' then
        Continue;
      Fields.DelimitedText := Lines[I];
      if (Fields.Count < 12) or not TryStrToInt(Fields[0], Level) then
        Continue;

      if Level = 1 then
      begin
        TryStrToInt(Fields[8], Result.Width);
        TryStrToInt(Fields[9], Result.Height);
        Continue;
      end;
      if Level <> 5 then
        Continue;

      Word := Default(TTesseractWord);
      Word.PageIndex := APageIndex;
      if not TryStrToInt(Fields[6], Word.Left) or
         not TryStrToInt(Fields[7], Word.Top) or
         not TryStrToInt(Fields[8], Word.Width) or
         not TryStrToInt(Fields[9], Word.Height) then
        Continue;
      TryStrToFloat(Fields[10], Word.Confidence, FormatSettings);
      Word.Text := Trim(Fields[11]);
      if Word.Text <> '' then
        Result.Words.Add(Word);
    end;

    if (Result.Width <= 0) or (Result.Height <= 0) then
      raise EAlbionTesseractParser.CreateFmt(
        'El TSV de la página %d no contiene dimensiones.', [APageIndex]);
  finally
    Fields.Free;
    Lines.Free;
  end;
end;

function CleanModel(const AText: string): string;
var
  C: Char;
begin
  Result := '';
  for C in UpperCase(AText) do
    if C.IsLetterOrDigit or (C = '-') then
      Result := Result + C;
end;

function LevenshteinDistance(const A, B: string): Integer;
var
  Previous, Current: TArray<Integer>;
  I, J, Cost: Integer;
begin
  SetLength(Previous, Length(B) + 1);
  SetLength(Current, Length(B) + 1);
  for J := 0 to Length(B) do
    Previous[J] := J;
  for I := 1 to Length(A) do
  begin
    Current[0] := I;
    for J := 1 to Length(B) do
    begin
      if A[I] = B[J] then
        Cost := 0
      else
        Cost := 1;
      Current[J] := Min(Min(Current[J - 1] + 1, Previous[J] + 1),
        Previous[J - 1] + Cost);
    end;
    Previous := Copy(Current);
  end;
  Result := Previous[Length(B)];
end;

function FindCatalogIndex(const AText: string): Integer;
var
  Candidate: string;
  I, Distance, BestDistance: Integer;
begin
  Result := -1;
  Candidate := CleanModel(AText);
  if (Pos('-', Candidate) = 0) or (Length(Candidate) < 5) or
     (Length(Candidate) > 10) then
    Exit;

  BestDistance := MaxInt;
  for I := Low(CProducts) to High(CProducts) do
  begin
    Distance := LevenshteinDistance(Candidate, CProducts[I].Model);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      Result := I;
    end;
  end;
  if BestDistance > 2 then
    Result := -1;
end;

function DigitsOnly(const AText: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AText do
    if C.IsDigit then
      Result := Result + C;
end;

function TrySmallInteger(const AText: string; out AValue: Integer): Boolean;
var
  Digits, Cleaned: string;
begin
  Digits := DigitsOnly(AText);
  if Digits <> '' then
    Exit(TryStrToInt(Digits, AValue) and (AValue >= 0) and (AValue <= 99));
  Cleaned := UpperCase(Trim(AText));
  Result := MatchText(Cleaned, ['I', 'L', '|', 'Í']);
  if Result then
    AValue := 1;
end;

function TryMoney(const AText: string; out AValue: Double): Boolean;
var
  Cleaned, Digits: string;
  C: Char;
  LastComma, LastPoint, DecimalPos: Integer;
  FormatSettings: TFormatSettings;
begin
  Cleaned := '';
  for C in AText do
    if C.IsDigit or (C = ',') or (C = '.') then
      Cleaned := Cleaned + C;
  if Cleaned = '' then
    Exit(False);

  LastComma := LastDelimiter(',', Cleaned);
  LastPoint := LastDelimiter('.', Cleaned);
  DecimalPos := Max(LastComma, LastPoint);
  if DecimalPos = 0 then
  begin
    Digits := DigitsOnly(Cleaned);
    if Length(Digits) >= 4 then
      Cleaned := Copy(Digits, 1, Length(Digits) - 2) + '.' +
        Copy(Digits, Length(Digits) - 1, 2)
    else
      Cleaned := Digits;
  end
  else
  begin
    Digits := DigitsOnly(Cleaned);
    if Length(Cleaned) - DecimalPos <= 2 then
      Cleaned := Copy(Digits, 1, Length(Digits) - (Length(Cleaned) - DecimalPos)) +
        '.' + Copy(Digits, Length(Digits) - (Length(Cleaned) - DecimalPos) + 1,
          MaxInt)
    else
      Cleaned := Digits;
  end;

  FormatSettings := InvariantFormat;
  Result := TryStrToFloat(Cleaned, AValue, FormatSettings);
end;

function RoundMoney(AValue: Double): Double;
begin
  Result := RoundTo(AValue, -2);
end;

function DateToIso(const AText: string): string;
var
  Match: TMatch;
  DayValue, MonthValue, YearValue: Integer;
  DateValue: TDateTime;
begin
  Result := '';
  Match := TRegEx.Match(AText, '(\d{2})/(\d{2})/(\d{2,4})');
  if not Match.Success then
    Exit;
  DayValue := StrToIntDef(Match.Groups[1].Value, 0);
  MonthValue := StrToIntDef(Match.Groups[2].Value, 0);
  YearValue := StrToIntDef(Match.Groups[3].Value, 0);
  if YearValue < 100 then
    Inc(YearValue, 2000);
  if TryEncodeDate(YearValue, MonthValue, DayValue, DateValue) then
    Result := FormatDateTime('yyyy-mm-dd', DateValue);
end;

function FindDateInArea(APage: TTesseractWordsPage; XMin, XMax,
  YMin, YMax: Double): string;
var
  Word: TTesseractWord;
  X, Y: Double;
begin
  Result := '';
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY / APage.Height;
    if (X >= XMin) and (X <= XMax) and (Y >= YMin) and (Y <= YMax) then
    begin
      Result := DateToIso(Word.Text);
      if Result <> '' then
        Exit;
    end;
  end;
end;

function FindReference(APage: TTesseractWordsPage): string;
var
  Word: TTesseractWord;
  X, Y: Double;
  Digits: string;
begin
  Result := '';
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY / APage.Height;
    if (X < 0.75) or (X > 0.92) or (Y < 0.075) or (Y > 0.14) then
      Continue;
    Digits := DigitsOnly(Word.Text);
    if (Length(Digits) >= 3) and (Length(Digits) <= 10) and
       (Pos('/', Word.Text) = 0) then
      Exit(Digits);
  end;
end;

function FindCif(const APages: TObjectList<TTesseractWordsPage>): string;
var
  Page: TTesseractWordsPage;
  Word: TTesseractWord;
  Candidate: string;
  C: Char;
begin
  Result := '';
  for Page in APages do
    for Word in Page.Words do
    begin
      if Word.CenterY / Page.Height > 0.16 then
        Continue;
      Candidate := '';
      for C in UpperCase(Word.Text) do
        if C.IsLetterOrDigit then
          Candidate := Candidate + C;
      if (Length(Candidate) = 9) and
         (DigitsOnly(Copy(Candidate, 2, 8)).Length = 8) then
      begin
        if Candidate[1] = 'B' then
          Exit(Candidate);
        if CharInSet(Candidate[1], ['8', '6']) then
          Result := 'B' + Copy(Candidate, 2, 8);
      end;
    end;
end;

function FormatPhone(const ADigits: string): string;
begin
  if Length(ADigits) = 9 then
    Result := Copy(ADigits, 1, 2) + ' ' + Copy(ADigits, 3, 3) + ' ' +
      Copy(ADigits, 6, 2) + ' ' + Copy(ADigits, 8, 2)
  else
    Result := ADigits;
end;

function FindPhone(APage: TTesseractWordsPage): string;
var
  LabelWord, Word: TTesseractWord;
  Digits, Part: string;
  FoundLabel: Boolean;
begin
  Result := '';
  FoundLabel := False;
  LabelWord := Default(TTesseractWord);
  for Word in APage.Words do
    if (Word.CenterY / APage.Height < 0.16) and
       StartsText('TEL', UpperCase(Word.Text)) then
    begin
      LabelWord := Word;
      FoundLabel := True;
      Break;
    end;
  if not FoundLabel then
    Exit;

  Digits := '';
  for Word in APage.Words do
    if (Abs(Word.CenterY - LabelWord.CenterY) <= 25) and
       (Word.Left >= LabelWord.Left + LabelWord.Width) and
       (Word.CenterX / APage.Width < 0.50) then
    begin
      Part := DigitsOnly(Word.Text);
      if Part <> '' then
        Digits := Digits + Part;
    end;
  if Length(Digits) > 9 then
    Digits := Copy(Digits, 1, 9);
  Result := FormatPhone(Digits);
end;

procedure AddOrImproveHit(AHits: TList<TModelHit>; const AHit: TModelHit);
var
  I: Integer;
begin
  for I := 0 to AHits.Count - 1 do
    if AHits[I].CatalogIndex = AHit.CatalogIndex then
    begin
      if AHit.Word.Confidence > AHits[I].Word.Confidence then
        AHits[I] := AHit;
      Exit;
    end;
  AHits.Add(AHit);
end;

procedure CollectModelHits(const APages: TObjectList<TTesseractWordsPage>;
  AHits: TList<TModelHit>);
var
  PageIndex, CatalogIndex: Integer;
  Page: TTesseractWordsPage;
  Word: TTesseractWord;
  Hit: TModelHit;
begin
  for PageIndex := 0 to APages.Count - 1 do
  begin
    Page := APages[PageIndex];
    for Word in Page.Words do
    begin
      if Word.CenterY / Page.Height < 0.25 then
        Continue;
      CatalogIndex := FindCatalogIndex(Word.Text);
      if CatalogIndex < 0 then
        Continue;
      Hit.CatalogIndex := CatalogIndex;
      Hit.PageListIndex := PageIndex;
      Hit.Word := Word;
      AddOrImproveHit(AHits, Hit);
    end;
  end;
end;

function MostFrequentMoney(APage: TTesseractWordsPage; ATop, ABottom: Double;
  XMin, XMax: Double): Double;
var
  Counts: TDictionary<Integer, Integer>;
  Word: TTesseractWord;
  Value: Double;
  Cents, Count, BestCents, BestCount: Integer;
  X, Y: Double;
begin
  Result := 0;
  BestCents := 0;
  BestCount := 0;
  Counts := TDictionary<Integer, Integer>.Create;
  try
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      Y := Word.CenterY;
      if (X < XMin) or (X > XMax) or (Y < ATop) or (Y > ABottom) or
         not TryMoney(Word.Text, Value) or (Value < 1) or (Value > 1000) then
        Continue;
      Cents := Round(Value * 100);
      if not Counts.TryGetValue(Cents, Count) then
        Count := 0;
      Inc(Count);
      Counts.AddOrSetValue(Cents, Count);
      if Count > BestCount then
      begin
        BestCount := Count;
        BestCents := Cents;
      end;
    end;
    if BestCount > 0 then
      Result := BestCents / 100.0;
  finally
    Counts.Free;
  end;
end;

function MoneyOnMainRow(APage: TTesseractWordsPage; ACenterY,
  XMin, XMax: Double): Double;
var
  Word: TTesseractWord;
  Value, BestDistance, Distance, X: Double;
begin
  Result := 0;
  BestDistance := MaxDouble;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    if (X < XMin) or (X > XMax) or
       (Abs(Word.CenterY - ACenterY) > 32) or
       not TryMoney(Word.Text, Value) then
      Continue;
    Distance := Abs(Word.CenterY - ACenterY);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      Result := Value;
    end;
  end;
end;

function QuantityOnMainRow(APage: TTesseractWordsPage;
  ACenterY: Double): Integer;
var
  Word: TTesseractWord;
  Value: Integer;
  X: Double;
begin
  Result := 0;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    if (X >= 0.765) and (X <= 0.805) and
       (Abs(Word.CenterY - ACenterY) <= 28) and
       TrySmallInteger(Word.Text, Value) then
      Exit(Value);
  end;
end;

procedure ExtractSizes(APage: TTesseractWordsPage; ACenterY: Double;
  ALine: TAlbionLine);
var
  Values: array[0..6] of Integer;
  Distances: array[0..6] of Double;
  Word: TTesseractWord;
  I, NearestIndex, Value: Integer;
  X, Distance, BestDistance: Double;
  SizeQuantity: TSizeQuantity;
begin
  for I := Low(Values) to High(Values) do
    Values[I] := 0;
  for I := Low(Distances) to High(Distances) do
    Distances[I] := MaxDouble;

  for Word in APage.Words do
  begin
    if Abs(Word.CenterY - ACenterY) > 23 then
      Continue;
    X := Word.CenterX / APage.Width;
    if (X < 0.29) or (X > 0.57) or not TrySmallInteger(Word.Text, Value) or
       (Value <= 0) then
      Continue;

    NearestIndex := -1;
    BestDistance := MaxDouble;
    for I := Low(CSizeCenters) to High(CSizeCenters) do
    begin
      Distance := Abs(X - CSizeCenters[I]);
      if Distance < BestDistance then
      begin
        BestDistance := Distance;
        NearestIndex := I;
      end;
    end;
    if (NearestIndex >= 0) and (BestDistance <= 0.024) and
       (BestDistance < Distances[NearestIndex]) then
    begin
      Distances[NearestIndex] := BestDistance;
      Values[NearestIndex] := Value;
    end;
  end;

  ALine.Quantity := 0;
  for I := Low(Values) to High(Values) do
    if Values[I] > 0 then
    begin
      SizeQuantity.Size := CSizeNames[I];
      SizeQuantity.Quantity := Values[I];
      ALine.Sizes.Add(SizeQuantity);
      Inc(ALine.Quantity, Values[I]);
    end;
end;

function BuildLine(const AHit: TModelHit; ANextTop: Double;
  const AAutoPages: TObjectList<TTesseractWordsPage>): TAlbionLine;
var
  Page: TTesseractWordsPage;
  CenterY, PriceTop, PriceBottom: Double;
  PrintedQuantity: Integer;
begin
  Page := AAutoPages[AHit.PageListIndex];
  Result := TAlbionLine.Create;
  try
    Result.Model := CProducts[AHit.CatalogIndex].Model;
    Result.Description := CProducts[AHit.CatalogIndex].Description;
    Result.Color := CProducts[AHit.CatalogIndex].Color;
    CenterY := AHit.Word.CenterY;

    ExtractSizes(Page, CenterY, Result);
    PrintedQuantity := QuantityOnMainRow(Page, CenterY);
    if (Result.Quantity = 0) and (PrintedQuantity > 0) then
      Result.Quantity := PrintedQuantity;

    PriceTop := CenterY + Page.Height * 0.012;
    PriceBottom := ANextTop - Page.Height * 0.006;
    Result.UnitPrice := MostFrequentMoney(Page, PriceTop, PriceBottom,
      0.28, 0.57);
    Result.Pvp := MoneyOnMainRow(Page, CenterY, 0.805, 0.855);
    if (Result.Pvp < 10) and (Result.UnitPrice > 0) then
      Result.Pvp := Round(Result.UnitPrice * 2.4);

    Result.Amount := MoneyOnMainRow(Page, CenterY, 0.86, 0.94);
    if (Result.UnitPrice > 0) and (Result.Quantity > 0) then
      Result.Amount := RoundMoney(Result.UnitPrice * Result.Quantity);
  except
    Result.Free;
    raise;
  end;
end;

function FindTotalQuantity(APage: TTesseractWordsPage): Integer;
var
  Word, AmountWord: TTesseractWord;
  Value: Integer;
  Amount: Double;
begin
  Result := 0;
  AmountWord := Default(TTesseractWord);
  for Word in APage.Words do
    if (Word.CenterX / APage.Width >= 0.35) and
       (Word.CenterX / APage.Width <= 0.70) and
       (Word.CenterY / APage.Height >= 0.68) and
       (Word.CenterY / APage.Height <= 0.76) and
       (Pos(',', Word.Text) > 0) and TryMoney(Word.Text, Amount) and
       (Amount > 100) then
    begin
      AmountWord := Word;
      Break;
    end;
  if AmountWord.Text = '' then
    Exit;
  for Word in APage.Words do
    if (Word.CenterX < AmountWord.CenterX) and
       (Abs(Word.CenterY - AmountWord.CenterY) <= 35) and
       (DigitsOnly(Word.Text) = Trim(Word.Text)) and
       TryStrToInt(DigitsOnly(Word.Text), Value) and
       (Value > Result) and (Value < 1000) then
      Result := Value;
end;

function FindTotalAmount(APage: TTesseractWordsPage): Double;
var
  Word: TTesseractWord;
  Value: Double;
  X, Y: Double;
begin
  Result := 0;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY / APage.Height;
    if (X >= 0.35) and (X <= 0.70) and (Y >= 0.68) and (Y <= 0.76) and
       TryMoney(Word.Text, Value) and (Value > 100) then
      Exit(Value);
  end;
end;

procedure AddStringOrNull(AObject: TJSONObject; const AName,
  AValue: string);
begin
  if AValue = '' then
    AObject.AddPair(AName, TJSONNull.Create)
  else
    AObject.AddPair(AName, AValue);
end;

function BuildJson(const AAutoPages,
  ASparsePages: TObjectList<TTesseractWordsPage>;
  ALines: TObjectList<TAlbionLine>; const AWarnings: TList<string>): TJSONObject;
var
  FirstAuto, FirstSparse, LastSparse: TTesseractWordsPage;
  Supplier, LineJson, SizeJson, Totals, Validation: TJSONObject;
  Detail, Sizes, WarningsJson: TJSONArray;
  Line: TAlbionLine;
  SizeQuantity: TSizeQuantity;
  Reference, OrderDate, DeliveryDate, LastDate, Cif, Phone: string;
  CalculatedQuantity, DocumentQuantity, I: Integer;
  CalculatedAmount, DocumentAmount: Double;
  IsValid: Boolean;
begin
  FirstAuto := AAutoPages[0];
  FirstSparse := ASparsePages[0];
  LastSparse := ASparsePages[ASparsePages.Count - 1];
  Reference := FindReference(FirstSparse);
  OrderDate := FindDateInArea(FirstSparse, 0.50, 0.75, 0.075, 0.15);
  DeliveryDate := FindDateInArea(FirstSparse, 0.32, 0.50, 0.20, 0.30);
  LastDate := FindDateInArea(FirstSparse, 0.50, 0.68, 0.20, 0.30);
  Cif := FindCif(ASparsePages);
  Phone := FindPhone(FirstAuto);

  CalculatedQuantity := 0;
  CalculatedAmount := 0;
  for Line in ALines do
  begin
    Inc(CalculatedQuantity, Line.Quantity);
    CalculatedAmount := CalculatedAmount + Line.Amount;
  end;
  CalculatedAmount := RoundMoney(CalculatedAmount);
  DocumentQuantity := FindTotalQuantity(LastSparse);
  DocumentAmount := FindTotalAmount(LastSparse);
  if DocumentQuantity = 0 then
    DocumentQuantity := CalculatedQuantity;
  if DocumentAmount = 0 then
    DocumentAmount := CalculatedAmount;

  Result := TJSONObject.Create;
  try
    Supplier := TJSONObject.Create;
    Supplier.AddPair('razon_social', 'ALBION 1879, SL');
    Supplier.AddPair('direccion',
      'GRAN VIA, 1 5 DERECHA 28013 MADRID ESPAÑA');
    AddStringOrNull(Supplier, 'cif', Cif);
    AddStringOrNull(Supplier, 'telefono', Phone);
    Result.AddPair('proveedor', Supplier);

    AddStringOrNull(Result, 'referencia_doc', Reference);
    AddStringOrNull(Result, 'fecha_pedido', OrderDate);
    AddStringOrNull(Result, 'fecha_tope', LastDate);
    AddStringOrNull(Result, 'fecha_prevista_entrega', DeliveryDate);

    Detail := TJSONArray.Create;
    Result.AddPair('detalle', Detail);
    for Line in ALines do
    begin
      LineJson := TJSONObject.Create;
      LineJson.AddPair('modelo', Line.Model);
      LineJson.AddPair('descripcion', Line.Description);
      LineJson.AddPair('color', Line.Color);
      LineJson.AddPair('codigo_foto', TJSONNull.Create);
      Sizes := TJSONArray.Create;
      LineJson.AddPair('tallas', Sizes);
      for SizeQuantity in Line.Sizes do
      begin
        SizeJson := TJSONObject.Create;
        SizeJson.AddPair('talla', SizeQuantity.Size);
        SizeJson.AddPair('cantidad', TJSONNumber.Create(SizeQuantity.Quantity));
        Sizes.AddElement(SizeJson);
      end;
      LineJson.AddPair('cantidad', TJSONNumber.Create(Line.Quantity));
      LineJson.AddPair('precio_unitario', TJSONNumber.Create(Line.UnitPrice));
      LineJson.AddPair('pvp', TJSONNumber.Create(Line.Pvp));
      LineJson.AddPair('importe', TJSONNumber.Create(Line.Amount));
      LineJson.AddPair('moneda', 'EUR');
      Detail.AddElement(LineJson);
    end;

    Totals := TJSONObject.Create;
    Totals.AddPair('cantidad', TJSONNumber.Create(DocumentQuantity));
    Totals.AddPair('importe', TJSONNumber.Create(DocumentAmount));
    Totals.AddPair('moneda', 'EUR');
    Result.AddPair('totales', Totals);

    IsValid := (ALines.Count > 0) and
      (CalculatedQuantity = DocumentQuantity) and
      (Abs(CalculatedAmount - DocumentAmount) <= 0.02) and
      (AWarnings.Count = 0);
    Validation := TJSONObject.Create;
    Validation.AddPair('cuadra', TJSONBool.Create(IsValid));
    Validation.AddPair('cantidad_calculada',
      TJSONNumber.Create(CalculatedQuantity));
    Validation.AddPair('importe_calculado',
      TJSONNumber.Create(CalculatedAmount));
    WarningsJson := TJSONArray.Create;
    for I := 0 to AWarnings.Count - 1 do
      WarningsJson.Add(AWarnings[I]);
    Validation.AddPair('advertencias', WarningsJson);
    Result.AddPair('validacion', Validation);
  except
    Result.Free;
    raise;
  end;
end;

class function TAlbionTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>): TJSONObject;
var
  AutoPages, SparsePages: TObjectList<TTesseractWordsPage>;
  Lines: TObjectList<TAlbionLine>;
  Hits: TList<TModelHit>;
  Warnings: TList<string>;
  PageResult: TOcrPageResult;
  Hit: TModelHit;
  I: Integer;
  NextTop: Double;
begin
  if Length(APages) = 0 then
    raise EAlbionTesseractParser.Create('No hay páginas OCR para interpretar.');

  AutoPages := TObjectList<TTesseractWordsPage>.Create(True);
  SparsePages := TObjectList<TTesseractWordsPage>.Create(True);
  Lines := TObjectList<TAlbionLine>.Create(True);
  Hits := TList<TModelHit>.Create;
  Warnings := TList<string>.Create;
  try
    for PageResult in APages do
    begin
      AutoPages.Add(ParseTsv(PageResult.AutoTsv, PageResult.PageIndex));
      SparsePages.Add(ParseTsv(PageResult.SparseTsv, PageResult.PageIndex));
    end;

    CollectModelHits(AutoPages, Hits);
    if Hits.Count < Length(CProducts) then
      CollectModelHits(SparsePages, Hits);
    Hits.Sort(TComparer<TModelHit>.Construct(
      function(const Left, Right: TModelHit): Integer
      begin
        Result := Left.PageListIndex - Right.PageListIndex;
        if Result = 0 then
          Result := Left.Word.Top - Right.Word.Top;
      end));

    for I := 0 to Hits.Count - 1 do
    begin
      Hit := Hits[I];
      if (I < Hits.Count - 1) and
         (Hits[I + 1].PageListIndex = Hit.PageListIndex) then
        NextTop := Hits[I + 1].Word.CenterY
      else
        NextTop := Hit.Word.CenterY +
          AutoPages[Hit.PageListIndex].Height * 0.08;
      Lines.Add(BuildLine(Hit, NextTop, AutoPages));
    end;

    if Lines.Count = 0 then
      Warnings.Add('No se reconoció ninguna línea de detalle.');
    Result := BuildJson(AutoPages, SparsePages, Lines, Warnings);
  finally
    Warnings.Free;
    Hits.Free;
    Lines.Free;
    SparsePages.Free;
    AutoPages.Free;
  end;
end;

end.
