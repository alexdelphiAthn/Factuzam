unit EmbeddedOcrRuntime;

interface

uses
  System.SysUtils;

type
  EEmbeddedOcrRuntime = class(Exception);

  TEmbeddedOcrRuntime = class sealed
  private
    class function CacheDirectory: string; static;
    class function IsComplete(const ADirectory: string): Boolean; static;
    class procedure Extract(const ADirectory: string); static;
  public
    class function EnsureAvailable: string; static;
  end;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.Zip;

const
  CRuntimeResourceName = 'OCR_RUNTIME';
  CRuntimeVersion = '2026.08.06.2';
  CReadyFile = 'runtime.ready';

class function TEmbeddedOcrRuntime.CacheDirectory: string;
var
  BaseDirectory: string;
begin
  BaseDirectory := GetEnvironmentVariable('ALBION_TESSERACT_CACHE');
  if BaseDirectory = '' then
    BaseDirectory := GetEnvironmentVariable('LOCALAPPDATA');
  if BaseDirectory = '' then
    BaseDirectory := TPath.GetTempPath;
  Result := TPath.Combine(BaseDirectory,
    TPath.Combine('AlbionTesseract', 'runtime-' + CRuntimeVersion));
end;

class function TEmbeddedOcrRuntime.IsComplete(
  const ADirectory: string): Boolean;
var
  Marker: string;
begin
  Marker := TPath.Combine(ADirectory, CReadyFile);
  Result := TFile.Exists(Marker) and
    SameText(Trim(TFile.ReadAllText(Marker, TEncoding.ASCII)),
      CRuntimeVersion) and
    TFile.Exists(TPath.Combine(ADirectory, 'bin\pdfium.dll')) and
    TFile.Exists(TPath.Combine(ADirectory,
      'bin\google.tesseract.libtesseract-main.dll')) and
    TFile.Exists(TPath.Combine(ADirectory,
      'bin\org.sw.demo.danbloomberg.leptonica-1.87.0.dll')) and
    TFile.Exists(TPath.Combine(ADirectory, 'tessdata\spa.traineddata')) and
    TFile.Exists(TPath.Combine(ADirectory, 'tessdata\eng.traineddata'));
end;

class procedure TEmbeddedOcrRuntime.Extract(const ADirectory: string);
var
  ResourceStream: TResourceStream;
  ZipPath, ReadyPath: string;
begin
  if FindResource(HInstance, CRuntimeResourceName, RT_RCDATA) = 0 then
    raise EEmbeddedOcrRuntime.Create(
      'El ejecutable no contiene el recurso OCR_RUNTIME.');

  TDirectory.CreateDirectory(ADirectory);
  ZipPath := TPath.Combine(ADirectory, 'runtime.extracting.zip');
  ReadyPath := TPath.Combine(ADirectory, CReadyFile);
  if TFile.Exists(ReadyPath) then
    TFile.Delete(ReadyPath);

  ResourceStream := TResourceStream.Create(HInstance,
    CRuntimeResourceName, RT_RCDATA);
  try
    ResourceStream.SaveToFile(ZipPath);
  finally
    ResourceStream.Free;
  end;

  try
    TZipFile.ExtractZipFile(ZipPath, ADirectory);
  finally
    if TFile.Exists(ZipPath) then
      TFile.Delete(ZipPath);
  end;

  TFile.WriteAllText(ReadyPath, CRuntimeVersion, TEncoding.ASCII);
  if not IsComplete(ADirectory) then
    raise EEmbeddedOcrRuntime.Create(
      'La extracción del runtime OCR quedó incompleta.');
end;

class function TEmbeddedOcrRuntime.EnsureAvailable: string;
begin
  Result := CacheDirectory;
  if not IsComplete(Result) then
    Extract(Result);
end;

end.
