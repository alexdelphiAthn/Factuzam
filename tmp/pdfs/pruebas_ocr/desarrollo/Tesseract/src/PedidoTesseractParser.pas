unit PedidoTesseractParser;

interface

uses
  System.SysUtils,
  System.JSON,
  TesseractDocumentOCR;

type
  EPedidoTesseractParserNoSoportado = class(Exception);

  TPedidoTesseractParser = class sealed
  public
    class function Convert(const APages: TArray<TOcrPageResult>;
      out AProveedor: string): TJSONObject; static;
  end;

implementation

uses
  System.StrUtils,
  AlbionTesseractParser,
  AnitaTesseractParser,
  AznarTesseractParser,
  GuaschTesseractParser,
  PuntoBlancoTesseractParser,
  RasdemarTesseractParser;

class function TPedidoTesseractParser.Convert(
  const APages: TArray<TOcrPageResult>; out AProveedor: string): TJSONObject;
var
  Page: TOcrPageResult;
  RecognizedText: string;
begin
  RecognizedText := '';
  for Page in APages do
    RecognizedText := RecognizedText + sLineBreak +
      UpperCase(Page.AutoText) + sLineBreak + UpperCase(Page.SparseText);
  if ContainsText(RecognizedText, 'ANITA.NET') or
     ContainsText(RecognizedText, 'ROSA FAIA') then
  begin
    AProveedor := 'anita';
    Result := TAnitaTesseractParser.Convert(APages);
  end
  else if ContainsText(RecognizedText, 'AZNAR INNOVA') then
  begin
    AProveedor := 'aznar';
    Result := TAznarTesseractParser.Convert(APages);
  end
  else if ContainsText(RecognizedText, 'GUASCH FASHION') or
          ContainsText(RecognizedText, 'RED POINT') then
  begin
    AProveedor := 'guasch';
    Result := TGuaschTesseractParser.Convert(APages);
  end
  else if ContainsText(RecognizedText, 'TEXTILE & SWIMWEAR') or
          ContainsText(RecognizedText, 'PEDIDOS@RASDEMAR.ES') then
  begin
    AProveedor := 'rasdemar';
    Result := TRasdemarTesseractParser.Convert(APages);
  end
  else if ContainsText(RecognizedText, 'ALBION') then
  begin
    AProveedor := 'albion';
    Result := TAlbionTesseractParser.Convert(APages);
  end
  else if ContainsText(RecognizedText, 'PUNTO BLANCO') or
          ContainsText(RecognizedText, 'INDUSTRIAS VALLS 1') then
  begin
    AProveedor := 'puntoblanco';
    Result := TPuntoBlancoTesseractParser.Convert(APages);
  end
  else
    raise EPedidoTesseractParserNoSoportado.Create(
      'Tesseract no ha identificado un proveedor con parser registrado.');
end;

end.
