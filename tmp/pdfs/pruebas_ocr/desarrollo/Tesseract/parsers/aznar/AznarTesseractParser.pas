unit AznarTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  EAznarTesseractParser = class(Exception);

  TAznarTesseractParser = class sealed
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
  TAznarHit = record
    PageListIndex: Integer;
    Word: TPedidoTesseractWord;
    Model: string;
  end;

  TSizeLabel = record
    Name: string;
    Word: TPedidoTesseractWord;
  end;

function CompareHits(const ALeft, ARight: TAznarHit): Integer;
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
  if Cleaned = 'XS' then
    Result := 'XS'
  else if MatchText(Cleaned, ['S', 'SS']) then
    Result := 'S'
  else if Cleaned = 'M' then
    Result := 'M'
  else if Cleaned = 'L' then
    Result := 'L'
  else if Cleaned = 'XL' then
    Result := 'XL'
  else if Cleaned = 'XXL' then
    Result := 'XXL'
  else if Cleaned = 'U' then
    Result := 'U';
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
  OtherY: Double;
  Score: Integer;
  BestScore: Integer;
  BestTop: Double;
  LabelValue: TSizeLabel;
begin
  Result := 0;
  BestScore := 0;
  BestTop := 0;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY;
    SizeName := CanonicalSize(Word.Text);
    if (SizeName <> '') and (X >= 0.32) and (X <= 0.70) and
       (Y >= ATop) and (Y <= ABottom) then
    begin
      Score := 0;
      for OtherWord in APage.Words do
      begin
        OtherX := OtherWord.CenterX / APage.Width;
        OtherY := OtherWord.CenterY;
        OtherSize := CanonicalSize(OtherWord.Text);
        if (OtherSize <> '') and (OtherX >= 0.32) and
           (OtherX <= 0.70) and (Abs(OtherY - Y) <= 18) then
          Inc(Score);
      end;
      if Score > BestScore then
      begin
        BestScore := Score;
        BestTop := Y;
      end;
    end;
  end;
  if BestScore > 0 then
  begin
    Result := BestTop;
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      SizeName := CanonicalSize(Word.Text);
      if (SizeName <> '') and (X >= 0.32) and (X <= 0.70) and
         (Abs(Word.CenterY - BestTop) <= 18) then
      begin
        LabelValue.Name := SizeName;
        LabelValue.Word := Word;
        ALabels.Add(LabelValue);
      end;
    end;
  end;
end;

procedure ExtractSizes(APage: TPedidoTesseractPage; ATop,
  ABottom: Double; ALine: TPedidoTesseractLine; out ALabelY: Double);
var
  Labels: TList<TSizeLabel>;
  LabelValue: TSizeLabel;
  Word: TPedidoTesseractWord;
  CandidateValue: Integer;
  BestValue: Integer;
  Distance: Double;
  BestDistance: Double;
  X: Double;
  Y: Double;
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
    ALabelY := FindBestSizeRow(APage, ATop, ABottom, Labels);
    for LabelValue in Labels do
    begin
      BestValue := 0;
      BestDistance := MaxDouble;
      for Word in APage.Words do
      begin
        X := Word.CenterX / APage.Width;
        Y := Word.CenterY;
        if (Y > ALabelY + 8) and (Y < ABottom) and
           (Abs(X - LabelValue.Word.CenterX / APage.Width) <= 0.025) and
           TryIntegerToken(Word.Text, CandidateValue) and
           (CandidateValue > 0) and (CandidateValue < 100) then
        begin
          Distance := Abs(Y - ALabelY) +
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
      if (X >= 0.80) and (X <= 0.88) and (Y > ALabelY + 8) and
         (Y < ABottom) and TryIntegerToken(Word.Text, CandidateValue) and
         (CandidateValue > PrintedTotal) then
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
  AYMin, AYMax: Double): Double;
var
  Word: TPedidoTesseractWord;
  X: Double;
  Y: Double;
  Value: Double;
begin
  Result := 0;
  for Word in APage.Words do
  begin
    X := Word.CenterX / APage.Width;
    Y := Word.CenterY;
    if (X >= AXMin) and (X <= AXMax) and (Y >= AYMin) and (Y <= AYMax) and
       TryMoneyToken(Word.Text, Value) and (Value > 0) then
      Result := Value;
  end;
end;

function BuildLine(APage: TPedidoTesseractPage; const AHit: TAznarHit;
  ABandBottom: Double; const AReference: string;
  ASequence: Integer): TPedidoTesseractLine;
var
  BandTop: Double;
  LabelY: Double;
begin
  Result := TPedidoTesseractLine.Create;
  try
    BandTop := AHit.Word.CenterY - APage.Height * 0.006;
    Result.Modelo := AHit.Model;
    Result.Descripcion := WordsNearRow(APage, AHit.Word.CenterY,
      0.27, 0.78, APage.Height * 0.012);
    ExtractSizes(APage, AHit.Word.CenterY + APage.Height * 0.006,
      ABandBottom, Result, LabelY);
    if LabelY > 0 then
      Result.Color := WordsNearRow(APage, LabelY, 0.17, 0.32, 20);
    Result.PrecioUnitario := FindMoneyInBand(APage, 0.88, 0.96,
      BandTop, ABandBottom);
    Result.Pvp := 0;
    Result.Importe := RoundMoney(Result.Cantidad * Result.PrecioUnitario);
    Result.CodigoFoto := BuildPhotoCode('AZNAR', AReference, ASequence);
  except
    Result.Free;
    raise;
  end;
end;

function FindFooterQuantity(const AText: string): Integer;
var
  ValueText: string;
begin
  Result := 0;
  ValueText := FirstRegexValue(AText,
    'TOTAL\s*\r?\nForma de pago[^\r\n]*?\b(\d+)\s*$');
  TryStrToInt(ValueText, Result);
end;

function LineQuality(ALine: TPedidoTesseractLine): Integer;
var
  SizeQuantity: TTallaCantidad;
begin
  Result := ALine.Tallas.Count * 10;
  for SizeQuantity in ALine.Tallas do
    if SizeQuantity.Talla = 'SIN_DETERMINAR' then
      Dec(Result, 1000);
end;

class function TAznarTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>): TJSONObject;
var
  AutoPages: TObjectList<TPedidoTesseractPage>;
  SparsePages: TObjectList<TPedidoTesseractPage>;
  Hits: TList<TAznarHit>;
  Document: TPedidoTesseractDocument;
  PageResult: TOcrPageResult;
  Page: TPedidoTesseractPage;
  Word: TPedidoTesseractWord;
  Hit: TAznarHit;
  ModelCode: string;
  AllText: string;
  Reference: string;
  DateText: string;
  Bottom: Double;
  AutoLine: TPedidoTesseractLine;
  SparseLine: TPedidoTesseractLine;
  I: Integer;
  CalculatedQuantity: Integer;
  CalculatedAmount: Double;
begin
  if Length(APages) = 0 then
    raise EAznarTesseractParser.Create(
      'No hay páginas OCR para interpretar el pedido Aznar.');
  AutoPages := TObjectList<TPedidoTesseractPage>.Create(True);
  SparsePages := TObjectList<TPedidoTesseractPage>.Create(True);
  Hits := TList<TAznarHit>.Create;
  Document := TPedidoTesseractDocument.Create;
  try
    AllText := '';
    for PageResult in APages do
    begin
      AutoPages.Add(ParseTsvPage(PageResult.AutoTsv,
        PageResult.PageIndex));
      SparsePages.Add(ParseTsvPage(PageResult.SparseTsv,
        PageResult.PageIndex));
      AllText := AllText + sLineBreak + PageResult.AutoText;
    end;
    for I := 0 to AutoPages.Count - 1 do
    begin
      Page := AutoPages[I];
      for Word in Page.Words do
      begin
        ModelCode := CleanCode(Word.Text);
        if TRegEx.IsMatch(ModelCode, '^\d{5}[A-Z]?[-_]\d$') then
        begin
          Hit.PageListIndex := I;
          Hit.Word := Word;
          Hit.Model := StringReplace(ModelCode, '_', '-', []);
          Hits.Add(Hit);
        end;
      end;
    end;
    Hits.Sort(TComparer<TAznarHit>.Construct(CompareHits));
    Reference := FirstRegexValue(AllText, '\b(\d{3}-\d{3})\b');
    DateText := FirstRegexValue(AllText,
      '\b\d{3}-\d{3}\s+(\d{2}-\d{2}-\d{4})\b');
    Document.Proveedor := 'AZNAR INNOVA, S.L.';
    Document.Direccion :=
      'AVDA. ENRIQUE GIMENO, 108 12006 CASTELLON';
    Document.Cif := 'B12648531';
    Document.Telefono := '964 20 14 14';
    Document.Referencia := Reference;
    Document.FechaPedido := DateToIso(DateText);
    for I := 0 to Hits.Count - 1 do
    begin
      Hit := Hits[I];
      Page := AutoPages[Hit.PageListIndex];
      if (I < Hits.Count - 1) and
         (Hits[I + 1].PageListIndex = Hit.PageListIndex) then
        Bottom := Hits[I + 1].Word.CenterY - Page.Height * 0.006
      else
        Bottom := Hit.Word.CenterY + Page.Height * 0.055;
      AutoLine := BuildLine(Page, Hit, Bottom, Reference, I + 1);
      SparseLine := BuildLine(SparsePages[Hit.PageListIndex], Hit, Bottom,
        Reference, I + 1);
      if LineQuality(SparseLine) > LineQuality(AutoLine) then
      begin
        AutoLine.Free;
        Document.Lineas.Add(SparseLine);
      end
      else
      begin
        SparseLine.Free;
        Document.Lineas.Add(AutoLine);
      end;
    end;
    CalculatedQuantity := 0;
    CalculatedAmount := 0;
    for I := 0 to Document.Lineas.Count - 1 do
    begin
      Inc(CalculatedQuantity, Document.Lineas[I].Cantidad);
      CalculatedAmount := CalculatedAmount + Document.Lineas[I].Importe;
    end;
    Document.CantidadDocumento := FindFooterQuantity(
      APages[High(APages)].AutoText);
    if Document.CantidadDocumento = 0 then
      Document.CantidadDocumento := CalculatedQuantity;
    Document.ImporteDocumento := RoundMoney(CalculatedAmount);
    if Document.Lineas.Count = 0 then
      Document.Advertencias.Add(
        'No se reconoció ninguna línea de detalle Aznar.');
    Result := BuildPedidoJson(Document);
  finally
    Document.Free;
    Hits.Free;
    SparsePages.Free;
    AutoPages.Free;
  end;
end;

end.
