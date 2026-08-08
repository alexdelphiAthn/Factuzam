unit TesseractDocumentOCR;

interface

uses
  System.SysUtils,
  uTesseractTypes;

type
  ETesseractDocumentOCR = class(Exception);

  TOcrPageResult = record
    PageIndex: Integer;
    ImageFile: string;
    AutoText: string;
    AutoTsv: string;
    AutoConfidence: Integer;
    SparseText: string;
    SparseTsv: string;
    SparseConfidence: Integer;
  end;

  TTesseractDocumentOCR = class
  private
    FEngine: TObject;
    FRuntimeDirectory: string;
    FDpi: Integer;
    FLanguage: string;
    function Engine: TObject;
    procedure RecognizeMode(const AImageFile: string; APageIndex: Integer;
      AMode: TessPageSegMode; out AText, ATsv: string;
      out AConfidence: Integer);
  public
    constructor Create(const ARuntimeDirectory: string;
      const ALanguage: string = 'spa+eng'; ADpi: Integer = 300);
    destructor Destroy; override;
    function RecognizePage(const AImageFile: string;
      APageIndex: Integer): TOcrPageResult;
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  uTesseractOCR;

const
  CTsvHeader = 'level'#9'page_num'#9'block_num'#9'par_num'#9'line_num'#9 +
    'word_num'#9'left'#9'top'#9'width'#9'height'#9'conf'#9'text';

constructor TTesseractDocumentOCR.Create(const ARuntimeDirectory,
  ALanguage: string; ADpi: Integer);
var
  BinDirectory, TessdataDirectory: string;
  Ocr: TTesseractOCR;
begin
  inherited Create;
  FRuntimeDirectory := IncludeTrailingPathDelimiter(ARuntimeDirectory);
  FLanguage := ALanguage;
  FDpi := ADpi;
  BinDirectory := TPath.Combine(FRuntimeDirectory, 'bin');
  TessdataDirectory := IncludeTrailingPathDelimiter(
    TPath.Combine(FRuntimeDirectory, 'tessdata'));

  SetDllDirectory(PChar(BinDirectory));
  Ocr := TTesseractOCR.Create(nil);
  try
    if not Ocr.Initialize(
      TPath.Combine(BinDirectory,
        'org.sw.demo.danbloomberg.leptonica-1.87.0.dll'),
      TPath.Combine(BinDirectory,
        'google.tesseract.libtesseract-main.dll'),
      TessdataDirectory, FLanguage) then
      raise ETesseractDocumentOCR.Create(
        'No se pudo inicializar Tesseract/Leptonica.');
    FEngine := Ocr;
    Ocr := nil;
  finally
    Ocr.Free;
  end;
end;

destructor TTesseractDocumentOCR.Destroy;
begin
  FEngine.Free;
  SetDllDirectory(nil);
  inherited;
end;

function TTesseractDocumentOCR.Engine: TObject;
begin
  if FEngine = nil then
    raise ETesseractDocumentOCR.Create('Tesseract no está inicializado.');
  Result := FEngine;
end;

procedure TTesseractDocumentOCR.RecognizeMode(const AImageFile: string;
  APageIndex: Integer; AMode: TessPageSegMode; out AText, ATsv: string;
  out AConfidence: Integer);
var
  Ocr: TTesseractOCR;
begin
  if not TFile.Exists(AImageFile) then
    raise EFileNotFoundException.Create('No existe el TIFF: ' + AImageFile);
  Ocr := TTesseractOCR(Engine);
  Ocr.BaseAPI.Clear;
  Ocr.BaseAPI.PageSegMode := AMode;
  if not Ocr.BaseAPI.SetImage(AImageFile) then
    raise ETesseractDocumentOCR.Create('Leptonica no pudo cargar: ' + AImageFile);
  Ocr.BaseAPI.SetSourceResolution(FDpi);
  if not Ocr.Recognize then
    raise ETesseractDocumentOCR.Create('Tesseract no pudo reconocer: ' + AImageFile);

  AText := Ocr.BaseAPI.GetText;
  ATsv := CTsvHeader + sLineBreak + Ocr.BaseAPI.GetTsvText(APageIndex - 1);
  AConfidence := Ocr.BaseAPI.MeanTextConf;
end;

function TTesseractDocumentOCR.RecognizePage(const AImageFile: string;
  APageIndex: Integer): TOcrPageResult;
begin
  Result.PageIndex := APageIndex;
  Result.ImageFile := AImageFile;
  RecognizeMode(AImageFile, APageIndex, PSM_AUTO, Result.AutoText,
    Result.AutoTsv, Result.AutoConfidence);
  RecognizeMode(AImageFile, APageIndex, PSM_SPARSE_TEXT, Result.SparseText,
    Result.SparseTsv, Result.SparseConfidence);
end;

end.
