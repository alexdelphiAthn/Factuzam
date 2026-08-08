program ProbarParsersGuardados;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  TesseractDocumentOCR in
    'C:\DISCO_DURO\proyectos\PruebasOCR\Tesseract\src\TesseractDocumentOCR.pas',
  PedidoTesseractParserComun in 'src\PedidoTesseractParserComun.pas',
  PedidoTesseractParser in 'src\PedidoTesseractParser.pas',
  AlbionTesseractParser in 'parsers\albion\AlbionTesseractParser.pas',
  AznarTesseractParser in 'parsers\aznar\AznarTesseractParser.pas',
  GuaschTesseractParser in 'parsers\guasch\GuaschTesseractParser.pas',
  RasdemarTesseractParser in 'parsers\rasdemar\RasdemarTesseractParser.pas';

function LoadPages(const ADebugDirectory: string): TArray<TOcrPageResult>;
var
  PageIndex: Integer;
  BaseName: string;
  Page: TOcrPageResult;
begin
  Result := nil;
  PageIndex := 1;
  BaseName := TPath.Combine(ADebugDirectory,
    Format('pagina-%.3d', [PageIndex]));
  while TFile.Exists(BaseName + '.auto.tsv') do
  begin
    Page := Default(TOcrPageResult);
    Page.PageIndex := PageIndex;
    Page.AutoText := TFile.ReadAllText(BaseName + '.auto.txt',
      TEncoding.UTF8);
    Page.AutoTsv := TFile.ReadAllText(BaseName + '.auto.tsv',
      TEncoding.UTF8);
    Page.SparseText := TFile.ReadAllText(BaseName + '.sparse.txt',
      TEncoding.UTF8);
    Page.SparseTsv := TFile.ReadAllText(BaseName + '.sparse.tsv',
      TEncoding.UTF8);
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Page;
    Inc(PageIndex);
    BaseName := TPath.Combine(ADebugDirectory,
      Format('pagina-%.3d', [PageIndex]));
  end;
end;

var
  Pages: TArray<TOcrPageResult>;
  Json: TJSONObject;
  Provider: string;
  Encoding: TEncoding;
begin
  if ParamCount <> 2 then
    raise EArgumentException.Create(
      'Uso: ProbarParsersGuardados <diagnostico> <salida.json>');
  Pages := LoadPages(TPath.GetFullPath(ParamStr(1)));
  Json := TPedidoTesseractParser.Convert(Pages, Provider);
  try
    Encoding := TUTF8Encoding.Create(False);
    try
      TFile.WriteAllText(TPath.GetFullPath(ParamStr(2)), Json.Format(2),
        Encoding);
      Writeln('Proveedor=', Provider);
      Writeln('Paginas=', Length(Pages));
    finally
      Encoding.Free;
    end;
  finally
    Json.Free;
  end;
end.
