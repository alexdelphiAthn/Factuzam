unit PedidoTesseractParserComun;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections;

type
  EPedidoTesseractParser = class(Exception);

  TPedidoTesseractWord = record
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

  TPedidoTesseractPage = class
  public
    PageIndex: Integer;
    Width: Integer;
    Height: Integer;
    Words: TList<TPedidoTesseractWord>;
    constructor Create;
    destructor Destroy; override;
  end;

  TTallaCantidad = record
    Talla: string;
    Cantidad: Integer;
  end;

  TPedidoTesseractLine = class
  public
    Modelo: string;
    Descripcion: string;
    Color: string;
    CodigoFoto: string;
    Tallas: TList<TTallaCantidad>;
    Cantidad: Integer;
    PrecioUnitario: Double;
    Pvp: Double;
    Importe: Double;
    constructor Create;
    destructor Destroy; override;
  end;

  TPedidoTesseractDocument = class
  public
    Proveedor: string;
    Direccion: string;
    Cif: string;
    Telefono: string;
    Referencia: string;
    FechaPedido: string;
    FechaTope: string;
    FechaEntrega: string;
    Lineas: TObjectList<TPedidoTesseractLine>;
    CantidadDocumento: Integer;
    ImporteDocumento: Double;
    Advertencias: TList<string>;
    constructor Create;
    destructor Destroy; override;
  end;

function ParseTsvPage(const ATsv: string;
  APageIndex: Integer): TPedidoTesseractPage;
function CleanCode(const AText: string): string;
function DigitsOnly(const AText: string): string;
function TryIntegerToken(const AText: string; out AValue: Integer): Boolean;
function TryMoneyToken(const AText: string; out AValue: Double): Boolean;
function RoundMoney(AValue: Double): Double;
function DateToIso(const AText: string): string;
function FirstRegexValue(const AText, APattern: string;
  AGroup: Integer = 1): string;
function TextInBand(APage: TPedidoTesseractPage; AXMin, AXMax,
  AYMin, AYMax: Double): string;
function BuildPhotoCode(const AProvider, AReference: string;
  ASequence: Integer): string;
function BuildPedidoJson(ADocument: TPedidoTesseractDocument): TJSONObject;

implementation

uses
  System.Classes,
  System.Math,
  System.StrUtils,
  System.Character,
  System.RegularExpressions,
  System.Generics.Defaults;

function TPedidoTesseractWord.CenterX: Double;
begin
  Result := Left + Width / 2.0;
end;

function TPedidoTesseractWord.CenterY: Double;
begin
  Result := Top + Height / 2.0;
end;

constructor TPedidoTesseractPage.Create;
begin
  inherited;
  Words := TList<TPedidoTesseractWord>.Create;
end;

destructor TPedidoTesseractPage.Destroy;
begin
  Words.Free;
  inherited;
end;

constructor TPedidoTesseractLine.Create;
begin
  inherited;
  Tallas := TList<TTallaCantidad>.Create;
end;

destructor TPedidoTesseractLine.Destroy;
begin
  Tallas.Free;
  inherited;
end;

constructor TPedidoTesseractDocument.Create;
begin
  inherited;
  Lineas := TObjectList<TPedidoTesseractLine>.Create(True);
  Advertencias := TList<string>.Create;
end;

destructor TPedidoTesseractDocument.Destroy;
begin
  Advertencias.Free;
  Lineas.Free;
  inherited;
end;

function InvariantFormat: TFormatSettings;
begin
  Result := TFormatSettings.Create;
  Result.DecimalSeparator := '.';
  Result.ThousandSeparator := ',';
end;

function ParseTsvPage(const ATsv: string;
  APageIndex: Integer): TPedidoTesseractPage;
var
  Lines: TStringList;
  Fields: TStringList;
  I: Integer;
  Level: Integer;
  Word: TPedidoTesseractWord;
  FormatSettings: TFormatSettings;
  ProcessLine: Boolean;
begin
  Result := TPedidoTesseractPage.Create;
  Result.PageIndex := APageIndex;
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    try
      Lines.Text := ATsv;
      Fields.StrictDelimiter := True;
      Fields.Delimiter := #9;
      Fields.QuoteChar := '"';
      FormatSettings := InvariantFormat;
      for I := 0 to Lines.Count - 1 do
      begin
        ProcessLine := Trim(Lines[I]) <> '';
        if ProcessLine then
        begin
          Fields.DelimitedText := Lines[I];
          ProcessLine := (Fields.Count >= 12) and
            TryStrToInt(Fields[0], Level);
        end;
        if ProcessLine and (Level = 1) then
        begin
          TryStrToInt(Fields[8], Result.Width);
          TryStrToInt(Fields[9], Result.Height);
        end;
        if ProcessLine and (Level = 5) then
        begin
          Word := Default(TPedidoTesseractWord);
          Word.PageIndex := APageIndex;
          ProcessLine := TryStrToInt(Fields[6], Word.Left) and
            TryStrToInt(Fields[7], Word.Top) and
            TryStrToInt(Fields[8], Word.Width) and
            TryStrToInt(Fields[9], Word.Height);
          if ProcessLine then
          begin
            TryStrToFloat(Fields[10], Word.Confidence, FormatSettings);
            Word.Text := Trim(Fields[11]);
            if Word.Text <> '' then
              Result.Words.Add(Word);
          end;
        end;
      end;
      if (Result.Width <= 0) or (Result.Height <= 0) then
        raise EPedidoTesseractParser.CreateFmt(
          'El TSV de la página %d no contiene dimensiones.', [APageIndex]);
    except
      Result.Free;
      raise;
    end;
  finally
    Fields.Free;
    Lines.Free;
  end;
end;

function CleanCode(const AText: string): string;
var
  C: Char;
begin
  Result := '';
  for C in UpperCase(AText) do
    if C.IsLetterOrDigit or CharInSet(C, ['-', '_']) then
      Result := Result + C;
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

function TryIntegerToken(const AText: string; out AValue: Integer): Boolean;
var
  Digits: string;
begin
  Digits := DigitsOnly(AText);
  Result := (Digits <> '') and TryStrToInt(Digits, AValue);
end;

function TryMoneyToken(const AText: string; out AValue: Double): Boolean;
var
  Cleaned: string;
  Digits: string;
  C: Char;
  LastComma: Integer;
  LastPoint: Integer;
  DecimalPos: Integer;
  DecimalCount: Integer;
  FormatSettings: TFormatSettings;
begin
  Cleaned := '';
  for C in AText do
    if C.IsDigit or CharInSet(C, [',', '.']) then
      Cleaned := Cleaned + C;
  Result := Cleaned <> '';
  if Result then
  begin
    LastComma := LastDelimiter(',', Cleaned);
    LastPoint := LastDelimiter('.', Cleaned);
    DecimalPos := Max(LastComma, LastPoint);
    Digits := DigitsOnly(Cleaned);
    if DecimalPos > 0 then
    begin
      DecimalCount := Length(Cleaned) - DecimalPos;
      if (DecimalCount > 0) and (DecimalCount <= 2) then
        Cleaned := Copy(Digits, 1, Length(Digits) - DecimalCount) + '.' +
          Copy(Digits, Length(Digits) - DecimalCount + 1, MaxInt)
      else
        Cleaned := Digits;
    end
    else
      Cleaned := Digits;
    FormatSettings := InvariantFormat;
    Result := TryStrToFloat(Cleaned, AValue, FormatSettings);
  end;
end;

function RoundMoney(AValue: Double): Double;
begin
  Result := RoundTo(AValue, -2);
end;

function DateToIso(const AText: string): string;
var
  Match: TMatch;
  DayValue: Integer;
  MonthValue: Integer;
  YearValue: Integer;
  DateValue: TDateTime;
begin
  Result := '';
  DayValue := 0;
  MonthValue := 0;
  YearValue := 0;
  Match := TRegEx.Match(AText,
    '\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b');
  if Match.Success then
  begin
    YearValue := StrToIntDef(Match.Groups[1].Value, 0);
    MonthValue := StrToIntDef(Match.Groups[2].Value, 0);
    DayValue := StrToIntDef(Match.Groups[3].Value, 0);
  end
  else
  begin
    Match := TRegEx.Match(AText,
      '\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b');
    if Match.Success then
    begin
      DayValue := StrToIntDef(Match.Groups[1].Value, 0);
      MonthValue := StrToIntDef(Match.Groups[2].Value, 0);
      YearValue := StrToIntDef(Match.Groups[3].Value, 0);
      if YearValue < 100 then
        Inc(YearValue, 2000);
    end;
  end;
  if Match.Success and
     TryEncodeDate(YearValue, MonthValue, DayValue, DateValue) then
    Result := FormatDateTime('yyyy-mm-dd', DateValue);
end;

function FirstRegexValue(const AText, APattern: string;
  AGroup: Integer): string;
var
  Match: TMatch;
begin
  Result := '';
  Match := TRegEx.Match(AText, APattern,
    [roIgnoreCase, roMultiLine, roSingleLine]);
  if Match.Success and (AGroup >= 0) and (AGroup < Match.Groups.Count) then
    Result := Trim(Match.Groups[AGroup].Value);
end;

function CompareWords(const ALeft,
  ARight: TPedidoTesseractWord): Integer;
begin
  Result := ALeft.Top - ARight.Top;
  if Result = 0 then
    Result := ALeft.Left - ARight.Left;
end;

function TextInBand(APage: TPedidoTesseractPage; AXMin, AXMax,
  AYMin, AYMax: Double): string;
var
  Selected: TList<TPedidoTesseractWord>;
  Word: TPedidoTesseractWord;
  X: Double;
  Y: Double;
  I: Integer;
begin
  Result := '';
  Selected := TList<TPedidoTesseractWord>.Create;
  try
    for Word in APage.Words do
    begin
      X := Word.CenterX / APage.Width;
      Y := Word.CenterY / APage.Height;
      if (X >= AXMin) and (X <= AXMax) and (Y >= AYMin) and (Y <= AYMax) then
        Selected.Add(Word);
    end;
    Selected.Sort(TComparer<TPedidoTesseractWord>.Construct(CompareWords));
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

function SafeCodePart(const AText: string): string;
var
  C: Char;
begin
  Result := '';
  for C in UpperCase(AText) do
    if C.IsLetterOrDigit or (C = '-') then
      Result := Result + C;
end;

function BuildPhotoCode(const AProvider, AReference: string;
  ASequence: Integer): string;
begin
  Result := SafeCodePart(AProvider) + '-' + SafeCodePart(AReference) + '-' +
    Format('%.3d', [ASequence]);
end;

procedure AddStringOrNull(AObject: TJSONObject; const AName,
  AValue: string);
begin
  if AValue = '' then
    AObject.AddPair(AName, TJSONNull.Create)
  else
    AObject.AddPair(AName, AValue);
end;

function BuildPedidoJson(ADocument: TPedidoTesseractDocument): TJSONObject;
var
  Supplier: TJSONObject;
  Detail: TJSONArray;
  LineJson: TJSONObject;
  Sizes: TJSONArray;
  SizeJson: TJSONObject;
  Totals: TJSONObject;
  Validation: TJSONObject;
  WarningsJson: TJSONArray;
  Line: TPedidoTesseractLine;
  SizeQuantity: TTallaCantidad;
  CalculatedQuantity: Integer;
  CalculatedAmount: Double;
  DocumentQuantity: Integer;
  DocumentAmount: Double;
  IsValid: Boolean;
  I: Integer;
begin
  CalculatedQuantity := 0;
  CalculatedAmount := 0;
  for Line in ADocument.Lineas do
  begin
    Inc(CalculatedQuantity, Line.Cantidad);
    CalculatedAmount := CalculatedAmount + Line.Importe;
  end;
  CalculatedAmount := RoundMoney(CalculatedAmount);
  DocumentQuantity := ADocument.CantidadDocumento;
  if DocumentQuantity = 0 then
    DocumentQuantity := CalculatedQuantity;
  DocumentAmount := ADocument.ImporteDocumento;
  if DocumentAmount = 0 then
    DocumentAmount := CalculatedAmount;
  Result := TJSONObject.Create;
  try
    Supplier := TJSONObject.Create;
    Supplier.AddPair('razon_social', ADocument.Proveedor);
    AddStringOrNull(Supplier, 'direccion', ADocument.Direccion);
    AddStringOrNull(Supplier, 'cif', ADocument.Cif);
    AddStringOrNull(Supplier, 'telefono', ADocument.Telefono);
    Result.AddPair('proveedor', Supplier);
    AddStringOrNull(Result, 'referencia_doc', ADocument.Referencia);
    AddStringOrNull(Result, 'fecha_pedido', ADocument.FechaPedido);
    AddStringOrNull(Result, 'fecha_tope', ADocument.FechaTope);
    AddStringOrNull(Result, 'fecha_prevista_entrega',
      ADocument.FechaEntrega);
    Detail := TJSONArray.Create;
    Result.AddPair('detalle', Detail);
    for Line in ADocument.Lineas do
    begin
      LineJson := TJSONObject.Create;
      LineJson.AddPair('modelo', Line.Modelo);
      LineJson.AddPair('descripcion', Line.Descripcion);
      LineJson.AddPair('color', Line.Color);
      AddStringOrNull(LineJson, 'codigo_foto', Line.CodigoFoto);
      Sizes := TJSONArray.Create;
      LineJson.AddPair('tallas', Sizes);
      for SizeQuantity in Line.Tallas do
      begin
        SizeJson := TJSONObject.Create;
        SizeJson.AddPair('talla', SizeQuantity.Talla);
        SizeJson.AddPair('cantidad',
          TJSONNumber.Create(SizeQuantity.Cantidad));
        Sizes.AddElement(SizeJson);
      end;
      LineJson.AddPair('cantidad', TJSONNumber.Create(Line.Cantidad));
      LineJson.AddPair('precio_unitario',
        TJSONNumber.Create(Line.PrecioUnitario));
      LineJson.AddPair('pvp', TJSONNumber.Create(Line.Pvp));
      LineJson.AddPair('importe', TJSONNumber.Create(Line.Importe));
      LineJson.AddPair('moneda', 'EUR');
      Detail.AddElement(LineJson);
    end;
    Totals := TJSONObject.Create;
    Totals.AddPair('cantidad', TJSONNumber.Create(DocumentQuantity));
    Totals.AddPair('importe', TJSONNumber.Create(DocumentAmount));
    Totals.AddPair('moneda', 'EUR');
    Result.AddPair('totales', Totals);
    IsValid := (ADocument.Lineas.Count > 0) and
      (CalculatedQuantity = DocumentQuantity) and
      (Abs(CalculatedAmount - DocumentAmount) <= 0.02) and
      (ADocument.Advertencias.Count = 0);
    Validation := TJSONObject.Create;
    Validation.AddPair('cuadra', TJSONBool.Create(IsValid));
    Validation.AddPair('cantidad_calculada',
      TJSONNumber.Create(CalculatedQuantity));
    Validation.AddPair('importe_calculado',
      TJSONNumber.Create(CalculatedAmount));
    WarningsJson := TJSONArray.Create;
    for I := 0 to ADocument.Advertencias.Count - 1 do
      WarningsJson.Add(ADocument.Advertencias[I]);
    Validation.AddPair('advertencias', WarningsJson);
    Result.AddPair('validacion', Validation);
  except
    Result.Free;
    raise;
  end;
end;

end.
