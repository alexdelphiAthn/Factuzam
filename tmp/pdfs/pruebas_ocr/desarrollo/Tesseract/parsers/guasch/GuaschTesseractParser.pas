unit GuaschTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  EGuaschTesseractParser = class(Exception);

  TGuaschTesseractParser = class sealed
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
  TGuaschHit = record
    PageListIndex: Integer;
    Word: TPedidoTesseractWord;
    Model: string;
  end;

  TSizeLabel = record
    Name: string;
    Word: TPedidoTesseractWord;
  end;

function CompareHits(const ALeft, ARight: TGuaschHit): Integer;
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
  NumberValue: Integer;
begin
  Result := '';
  Cleaned := CleanCode(AText);
  if MatchText(Cleaned, ['S', 'M', 'L', 'XL', 'XXL', 'U']) then
    Result := Cleaned
  else if TryStrToInt(Cleaned, NumberValue) and
          (NumberValue >= 30) and (NumberValue <= 120) then
    Result := IntToStr(NumberValue);
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
    if (SizeName <> '') and (X >= 0.41) and (X <= 0.72) and
       (Y >= ATop) and (Y <= ABottom) then
    begin
      Score := 0;
      for OtherWord in APage.Words do
      begin
        OtherX := OtherWord.CenterX / APage.Width;
        OtherSize := CanonicalSize(OtherWord.Text);
        if (OtherSize <> '') and (OtherX >= 0.41) and
           (OtherX <= 0.72) and
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
      if (SizeName <> '') and (X >= 0.41) and (X <= 0.72) and
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
  ABottom: Double; ALine: TPedidoTesseractLine; out AQuantityY: Double);
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
  QuantityYTotal: Double;
  QuantityCount: Integer;
  MissingCount: Integer;
  MissingName: string;
  PrintedTotal: Integer;
begin
  AQuantityY := 0;
  QuantityYTotal := 0;
  QuantityCount := 0;
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
            AQuantityY := Y;
          end;
        end;
      end;
      if BestValue > 0 then
      begin
        SizeQuantity.Talla := LabelValue.Name;
        SizeQuantity.Cantidad := BestValue;
        ALine.Tallas.Add(SizeQuantity);
        Inc(ALine.Cantidad, BestValue);
        QuantityYTotal := QuantityYTotal + AQuantityY;
        Inc(QuantityCount);
      end;
      if BestValue = 0 then
      begin
        Inc(MissingCount);
        MissingName := LabelValue.Name;
      end;
    end;
    if QuantityCount > 0 then
      AQuantityY := QuantityYTotal / QuantityCount;
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      Y := Word.CenterY;
      if (X >= 0.90) and (X <= 0.99) and (Y > HeaderY + 8) and
         (Y < ABottom) and TryIntegerToken(Word.Text, CandidateValue) and
         (CandidateValue > PrintedTotal) and (CandidateValue < 1000) then
      begin
        PrintedTotal := CandidateValue;
        if AQuantityY = 0 then
          AQuantityY := Y;
      end;
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

function BuildLine(APage: TPedidoTesseractPage; const AHit: TGuaschHit;
  ABandBottom: Double; const AReference: string;
  ASequence: Integer): TPedidoTesseractLine;
var
  BandTop: Double;
  QuantityY: Double;
begin
  Result := TPedidoTesseractLine.Create;
  try
    BandTop := AHit.Word.CenterY - APage.Height * 0.008;
    Result.Modelo := AHit.Model;
    Result.Descripcion := WordsNearRow(APage, AHit.Word.CenterY,
      0.40, 0.69, APage.Height * 0.012);
    ExtractSizes(APage, AHit.Word.CenterY + APage.Height * 0.004,
      ABandBottom, Result, QuantityY);
    if QuantityY > 0 then
      Result.Color := WordsNearRow(APage, QuantityY, 0.22, 0.40, 20);
    Result.PrecioUnitario := FindMoneyInBand(APage, 0.77, 0.88,
      BandTop, ABandBottom, False);
    Result.Pvp := Result.PrecioUnitario;
    Result.Importe := FindMoneyInBand(APage, 0.90, 0.99,
      BandTop, ABandBottom, True);
    if Pos('PROMOCI', UpperCase(Result.Descripcion)) = 0 then
      Result.CodigoFoto := BuildPhotoCode('GUASCH', AReference, ASequence);
  except
    Result.Free;
    raise;
  end;
end;

class function TGuaschTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>): TJSONObject;
var
  HitPages: TObjectList<TPedidoTesseractPage>;
  DataPages: TObjectList<TPedidoTesseractPage>;
  Hits: TList<TGuaschHit>;
  Document: TPedidoTesseractDocument;
  PageResult: TOcrPageResult;
  Page: TPedidoTesseractPage;
  Word: TPedidoTesseractWord;
  Hit: TGuaschHit;
  Code: string;
  AllText: string;
  Reference: string;
  DateText: string;
  DeliveryText: string;
  QuantityText: string;
  AmountText: string;
  Bottom: Double;
  X: Double;
  Y: Double;
  I: Integer;
begin
  if Length(APages) = 0 then
    raise EGuaschTesseractParser.Create(
      'No hay páginas OCR para interpretar el pedido Guasch.');
  HitPages := TObjectList<TPedidoTesseractPage>.Create(True);
  DataPages := TObjectList<TPedidoTesseractPage>.Create(True);
  Hits := TList<TGuaschHit>.Create;
  Document := TPedidoTesseractDocument.Create;
  try
    AllText := '';
    for PageResult in APages do
    begin
      HitPages.Add(ParseTsvPage(PageResult.SparseTsv,
        PageResult.PageIndex));
      DataPages.Add(ParseTsvPage(PageResult.AutoTsv,
        PageResult.PageIndex));
      AllText := AllText + sLineBreak + PageResult.AutoText;
    end;
    for I := 0 to HitPages.Count - 1 do
    begin
      Page := HitPages[I];
      for Word in Page.Words do
      begin
        X := Word.CenterX / Page.Width;
        Y := Word.CenterY / Page.Height;
        Code := DigitsOnly(Word.Text);
        if (Length(Code) = 7) and (X >= 0.25) and (X <= 0.34) and
           (Y >= 0.34) and (Y <= 0.93) then
        begin
          Hit.PageListIndex := I;
          Hit.Word := Word;
          Hit.Model := Code;
          Hits.Add(Hit);
        end;
      end;
    end;
    Hits.Sort(TComparer<TGuaschHit>.Construct(CompareHits));
    Reference := FirstRegexValue(AllText,
      'N.\s*de\s+Pedido[\s\S]{0,120}?\b(\d{3,10})\b');
    if Reference = '' then
      Reference := FirstRegexValue(AllText,
        '\b(8167)\b');
    DateText := FirstRegexValue(AllText, '\b' + Reference +
      '\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}/\d{2}/\d{4})', 1);
    DeliveryText := FirstRegexValue(AllText, '\b' + Reference +
      '\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}/\d{2}/\d{4})', 2);
    Document.Proveedor := 'GUASCH FASHION GROUP, S.L.';
    Document.Direccion :=
      'CTRA. CALDES KM 0,2 17240 LLAGOSTERA, GIRONA';
    Document.Cif := 'B64584857';
    Document.Referencia := Reference;
    Document.FechaPedido := DateToIso(DateText);
    Document.FechaEntrega := DateToIso(DeliveryText);
    for I := 0 to Hits.Count - 1 do
    begin
      Hit := Hits[I];
      Page := DataPages[Hit.PageListIndex];
      if (I < Hits.Count - 1) and
         (Hits[I + 1].PageListIndex = Hit.PageListIndex) then
        Bottom := Hits[I + 1].Word.CenterY - Page.Height * 0.008
      else
        Bottom := Hit.Word.CenterY + Page.Height * 0.095;
      Document.Lineas.Add(BuildLine(Page, Hit, Bottom, Reference, I + 1));
    end;
    QuantityText := FirstRegexValue(AllText,
      '\b(\d+)\s+TOTAL\s+UNIDADES');
    AmountText := FirstRegexValue(AllText,
      'TOTAL\s+UNIDADES\s+TOTAL\s+IMPORTE\s+\d+\s+([\d.,]+)');
    TryStrToInt(QuantityText, Document.CantidadDocumento);
    TryMoneyToken(AmountText, Document.ImporteDocumento);
    if Document.Lineas.Count <> 46 then
      Document.Advertencias.Add(Format(
        'Se esperaban 46 líneas Guasch y se reconocieron %d.',
        [Document.Lineas.Count]));
    Result := BuildPedidoJson(Document);
  finally
    Document.Free;
    Hits.Free;
    DataPages.Free;
    HitPages.Free;
  end;
end;

end.
