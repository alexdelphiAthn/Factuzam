program ExtraerPedidoAlbionTesseract;

{$APPTYPE CONSOLE}
{$R 'resources\EmbeddedRuntime.res'}

uses
  Winapi.Windows,
  Winapi.ActiveX,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Win.ComObj,
  EmbeddedOcrRuntime in 'src\EmbeddedOcrRuntime.pas',
  PdfiumToTiff in 'src\PdfiumToTiff.pas',
  TesseractDocumentOCR in 'src\TesseractDocumentOCR.pas',
  PedidoTesseractParserComun in 'src\PedidoTesseractParserComun.pas',
  PedidoTesseractParser in 'src\PedidoTesseractParser.pas',
  PedidoFotosPdfium in 'src\PedidoFotosPdfium.pas',
  AlbionTesseractParser in 'parsers\albion\AlbionTesseractParser.pas',
  AnitaTesseractParser in 'parsers\anita\AnitaTesseractParser.pas',
  AznarTesseractParser in 'parsers\aznar\AznarTesseractParser.pas',
  GuaschTesseractParser in 'parsers\guasch\GuaschTesseractParser.pas',
  PuntoBlancoTesseractParser in 'parsers\puntoblanco\PuntoBlancoTesseractParser.pas',
  RasdemarTesseractParser in 'parsers\rasdemar\RasdemarTesseractParser.pas';

type
  TOptions = record
    InputPdf: string;
    OutputJson: string;
    DebugDirectory: string;
    Force: Boolean;
    Help: Boolean;
  end;

procedure WriteUtf8Line(const AText: string = '');
var
  Utf8Text: UTF8String;
begin
  Utf8Text := UTF8Encode(AText);
  Writeln(Utf8Text);
  Flush(Output);
end;

procedure ShowHelp;
begin
  WriteUtf8Line('Extrae un pedido desde PDF con Tesseract y parser por proveedor.');
  WriteUtf8Line;
  WriteUtf8Line('Uso:');
  WriteUtf8Line('  ExtraerPedidoAlbionTesseract.exe <entrada.pdf> [opciones]');
  WriteUtf8Line;
  WriteUtf8Line('Opciones:');
  WriteUtf8Line('  --output <archivo.json>   Ruta del JSON de salida.');
  WriteUtf8Line('  --debug-dir <carpeta>     Conserva TIFF, texto y TSV de diagnóstico.');
  WriteUtf8Line('  --force                   Permite sobrescribir la salida.');
  WriteUtf8Line('  --help                    Muestra esta ayuda.');
  WriteUtf8Line;
  WriteUtf8Line('Sin entrada selecciona el único PDF de la carpeta actual.');
  WriteUtf8Line('Las DLL, PDFium y los modelos spa+eng están incrustados en el EXE.');
end;

function NextValue(var AIndex: Integer; const AOption: string): string;
begin
  Inc(AIndex);
  if AIndex > ParamCount then
    raise EArgumentException.Create('Falta el valor de ' + AOption + '.');
  Result := ParamStr(AIndex);
end;

function ReadOptions: TOptions;
var
  I: Integer;
  Parameter: string;
begin
  Result := Default(TOptions);
  I := 1;
  while I <= ParamCount do
  begin
    Parameter := ParamStr(I);
    if SameText(Parameter, '--help') or SameText(Parameter, '-h') then
      Result.Help := True
    else if SameText(Parameter, '--force') then
      Result.Force := True
    else if SameText(Parameter, '--output') then
      Result.OutputJson := NextValue(I, Parameter)
    else if SameText(Parameter, '--debug-dir') then
      Result.DebugDirectory := NextValue(I, Parameter)
    else if Parameter.StartsWith('--') then
      raise EArgumentException.Create('Opción desconocida: ' + Parameter)
    else if Result.InputPdf = '' then
      Result.InputPdf := Parameter
    else
      raise EArgumentException.Create('Solo se admite un PDF de entrada.');
    Inc(I);
  end;
end;

function FindOnlyPdf: string;
var
  Files: TArray<string>;
begin
  Files := TDirectory.GetFiles(GetCurrentDir, '*.pdf',
    TSearchOption.soTopDirectoryOnly);
  if Length(Files) = 0 then
    raise EFileNotFoundException.Create(
      'No hay ningún PDF en la carpeta actual.');
  if Length(Files) > 1 then
    raise EArgumentException.Create(
      'Hay varios PDF; indica el archivo de entrada.');
  Result := Files[0];
end;

function DefaultOutputName(const APdfFile: string): string;
begin
  Result := TPath.ChangeExtension(APdfFile, '') +
    '.tesseract.pedido.json';
end;

function NewTemporaryWorkDirectory: string;
var
  Id: TGUID;
  IdText: string;
begin
  CreateGUID(Id);
  IdText := GUIDToString(Id).Replace('{', '').Replace('}', '');
  Result := TPath.Combine(TPath.GetTempPath,
    TPath.Combine('PedidoTesseract',
      Format('%d-%s', [GetCurrentProcessId, IdText])));
  TDirectory.CreateDirectory(Result);
end;

procedure WriteUtf8File(const AFileName, AText: string);
var
  Encoding: TEncoding;
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(AFileName));
  Encoding := TUTF8Encoding.Create(False);
  try
    TFile.WriteAllText(AFileName, AText, Encoding);
  finally
    Encoding.Free;
  end;
end;

procedure SaveDebugPage(const ADebugDirectory: string;
  const APage: TOcrPageResult);
var
  BaseName: string;
begin
  BaseName := TPath.Combine(ADebugDirectory,
    Format('pagina-%.3d', [APage.PageIndex]));
  WriteUtf8File(BaseName + '.auto.txt', APage.AutoText);
  WriteUtf8File(BaseName + '.auto.tsv', APage.AutoTsv);
  WriteUtf8File(BaseName + '.sparse.txt', APage.SparseText);
  WriteUtf8File(BaseName + '.sparse.tsv', APage.SparseTsv);
end;

procedure CopyTiffsToDebug(const ATiffFiles: TArray<string>;
  const ADebugDirectory: string);
var
  FileName, Destination: string;
begin
  TDirectory.CreateDirectory(ADebugDirectory);
  for FileName in ATiffFiles do
  begin
    Destination := TPath.Combine(ADebugDirectory,
      TPath.GetFileName(FileName));
    TFile.Copy(FileName, Destination, True);
  end;
end;

procedure ProcessPdf(const AOptions: TOptions);
var
  InputPdf, OutputJson, RuntimeDirectory, WorkDirectory: string;
  OutputDirectory, FotosDirectory, FotosManifest: string;
  Proveedor: string;
  DeleteWorkDirectory: Boolean;
  Extractor: TPdfToTiff;
  Ocr: TTesseractDocumentOCR;
  TiffFiles: TArray<string>;
  Pages: TArray<TOcrPageResult>;
  Json: TJSONObject;
  I, PhotoCount: Integer;
begin
  if AOptions.InputPdf = '' then
    InputPdf := FindOnlyPdf
  else
    InputPdf := TPath.GetFullPath(AOptions.InputPdf);
  if not TFile.Exists(InputPdf) then
    raise EFileNotFoundException.Create('No existe el PDF: ' + InputPdf);
  if not SameText(TPath.GetExtension(InputPdf), '.pdf') then
    raise EArgumentException.Create('La entrada debe ser un archivo PDF.');

  if AOptions.OutputJson = '' then
    OutputJson := DefaultOutputName(InputPdf)
  else
    OutputJson := TPath.GetFullPath(AOptions.OutputJson);
  if TFile.Exists(OutputJson) and not AOptions.Force then
    raise EInOutError.Create(
      'La salida ya existe; usa --force: ' + OutputJson);

  WorkDirectory := NewTemporaryWorkDirectory;
  DeleteWorkDirectory := True;
  try
    WriteUtf8Line('Preparando componentes incrustados...');
    RuntimeDirectory := TEmbeddedOcrRuntime.EnsureAvailable;

    WriteUtf8Line('Convirtiendo PDF a TIFF a 300 DPI...');
    Extractor := TPdfToTiff.Create(nil);
    try
      Extractor.Dpi := 300;
      Extractor.PdfiumDll := TPath.Combine(RuntimeDirectory,
        'bin\pdfium.dll');
      TiffFiles := Extractor.ExtractPages(InputPdf, WorkDirectory);
    finally
      Extractor.Free;
    end;
    WriteUtf8Line(Format('Páginas convertidas: %d', [Length(TiffFiles)]));

    SetLength(Pages, Length(TiffFiles));
    Ocr := TTesseractDocumentOCR.Create(RuntimeDirectory, 'spa+eng', 300);
    try
      for I := 0 to High(TiffFiles) do
      begin
        WriteUtf8Line(Format('OCR página %d/%d (AUTO + SPARSE)...',
          [I + 1, Length(TiffFiles)]));
        Pages[I] := Ocr.RecognizePage(TiffFiles[I], I + 1);
        WriteUtf8Line(Format('  confianza AUTO=%d, SPARSE=%d',
          [Pages[I].AutoConfidence, Pages[I].SparseConfidence]));
        if AOptions.DebugDirectory <> '' then
          SaveDebugPage(TPath.GetFullPath(AOptions.DebugDirectory), Pages[I]);
      end;
    finally
      Ocr.Free;
    end;

    if AOptions.DebugDirectory <> '' then
      CopyTiffsToDebug(TiffFiles,
        TPath.GetFullPath(AOptions.DebugDirectory));

    WriteUtf8Line('Detectando proveedor y reconstruyendo tabla...');
    Json := TPedidoTesseractParser.Convert(Pages, Proveedor);
    try
      WriteUtf8Line('Parser aplicado: ' + Proveedor);
      OutputDirectory := TPath.GetDirectoryName(OutputJson);
      FotosDirectory := TPath.Combine(OutputDirectory, 'fotos');
      FotosManifest := TPath.Combine(OutputDirectory,
        TPath.GetFileNameWithoutExtension(OutputJson) + '.fotos.json');
      WriteUtf8Line('Extrayendo fotos de producto con PDFium...');
      PhotoCount := TPedidoFotosPdfium.Extract(InputPdf, Json, Proveedor,
        TPath.Combine(RuntimeDirectory, 'bin\pdfium.dll'), FotosDirectory,
        FotosManifest);
      WriteUtf8File(OutputJson, Json.Format(2));
    finally
      Json.Free;
    end;
    WriteUtf8Line('JSON generado: ' + OutputJson);
    if PhotoCount > 0 then
    begin
      WriteUtf8Line(Format('Fotos generadas: %d', [PhotoCount]));
      WriteUtf8Line('Carpeta de fotos: ' + FotosDirectory);
      WriteUtf8Line('Relación de fotos: ' + FotosManifest);
    end
    else
      WriteUtf8Line('El pedido no contiene fotos de producto enlazadas.');
    if AOptions.DebugDirectory <> '' then
      WriteUtf8Line('Diagnóstico: ' +
        TPath.GetFullPath(AOptions.DebugDirectory));
  finally
    if DeleteWorkDirectory and TDirectory.Exists(WorkDirectory) then
      TDirectory.Delete(WorkDirectory, True);
  end;
end;

var
  Options: TOptions;
  ComResult: HRESULT;
begin
  SetConsoleOutputCP(CP_UTF8);
  ExitCode := 1;
  ComResult := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  try
    try
      if Failed(ComResult) then
        OleCheck(ComResult);
      Options := ReadOptions;
      if Options.Help then
      begin
        ShowHelp;
        ExitCode := 0;
        Exit;
      end;
      ProcessPdf(Options);
      ExitCode := 0;
    except
      on E: Exception do
      begin
        WriteUtf8Line('ERROR ' + E.ClassName + ': ' + E.Message);
        ExitCode := 2;
      end;
    end;
  finally
    if Succeeded(ComResult) then
      CoUninitialize;
  end;
end.
