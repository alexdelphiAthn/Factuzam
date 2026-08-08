unit PdfiumToTiff;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes;

type
  EPdfiumError = class(Exception);

  TPdfPageProgressEvent = procedure(Sender: TObject; APageIndex,
    APageCount: Integer; const AFileName: string) of object;

  TPdfToTiff = class(TComponent)
  private
    FDpi: Integer;
    FPdfiumDll: string;
    FOnPage: TPdfPageProgressEvent;
    FModule: HMODULE;
    FInitialized: Boolean;
    procedure SetDpi(const Value: Integer);
    procedure LoadApi;
    procedure UnloadApi;
    procedure SaveBitmapAsTiff(ABitmap: Pointer; AWidth, AHeight: Integer;
      const AFileName: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExtractPages(const APdfFile, AOutputDirectory: string): TArray<string>;
  published
    property Dpi: Integer read FDpi write SetDpi default 300;
    property PdfiumDll: string read FPdfiumDll write FPdfiumDll;
    property OnPage: TPdfPageProgressEvent read FOnPage write FOnPage;
  end;

implementation

uses
  System.IOUtils,
  System.Math,
  Vcl.Graphics;

type
  TFPDF_InitLibrary = procedure; stdcall;
  TFPDF_DestroyLibrary = procedure; stdcall;
  TFPDF_LoadDocument = function(FilePath, Password: PAnsiChar): Pointer; stdcall;
  TFPDF_CloseDocument = procedure(Document: Pointer); stdcall;
  TFPDF_GetLastError = function: Cardinal; stdcall;
  TFPDF_GetPageCount = function(Document: Pointer): Integer; stdcall;
  TFPDF_LoadPage = function(Document: Pointer; PageIndex: Integer): Pointer; stdcall;
  TFPDF_ClosePage = procedure(Page: Pointer); stdcall;
  TFPDF_GetPageWidthF = function(Page: Pointer): Single; stdcall;
  TFPDF_GetPageHeightF = function(Page: Pointer): Single; stdcall;
  TFPDFBitmap_Create = function(Width, Height, Alpha: Integer): Pointer; stdcall;
  TFPDFBitmap_Destroy = procedure(Bitmap: Pointer); stdcall;
  TFPDFBitmap_FillRect = function(Bitmap: Pointer; Left, Top, Width,
    Height: Integer; Color: Cardinal): Integer; stdcall;
  TFPDFBitmap_GetBuffer = function(Bitmap: Pointer): Pointer; stdcall;
  TFPDFBitmap_GetStride = function(Bitmap: Pointer): Integer; stdcall;
  TFPDF_RenderPageBitmap = procedure(Bitmap, Page: Pointer; StartX, StartY,
    SizeX, SizeY, Rotate, Flags: Integer); stdcall;

var
  FPDF_InitLibrary: TFPDF_InitLibrary;
  FPDF_DestroyLibrary: TFPDF_DestroyLibrary;
  FPDF_LoadDocument: TFPDF_LoadDocument;
  FPDF_CloseDocument: TFPDF_CloseDocument;
  FPDF_GetLastError: TFPDF_GetLastError;
  FPDF_GetPageCount: TFPDF_GetPageCount;
  FPDF_LoadPage: TFPDF_LoadPage;
  FPDF_ClosePage: TFPDF_ClosePage;
  FPDF_GetPageWidthF: TFPDF_GetPageWidthF;
  FPDF_GetPageHeightF: TFPDF_GetPageHeightF;
  FPDFBitmap_Create: TFPDFBitmap_Create;
  FPDFBitmap_Destroy: TFPDFBitmap_Destroy;
  FPDFBitmap_FillRect: TFPDFBitmap_FillRect;
  FPDFBitmap_GetBuffer: TFPDFBitmap_GetBuffer;
  FPDFBitmap_GetStride: TFPDFBitmap_GetStride;
  FPDF_RenderPageBitmap: TFPDF_RenderPageBitmap;

function PdfiumErrorText(AError: Cardinal): string;
begin
  case AError of
    1: Result := 'error desconocido';
    2: Result := 'archivo no encontrado o inaccesible';
    3: Result := 'formato PDF no válido';
    4: Result := 'contraseña requerida o incorrecta';
    5: Result := 'seguridad del documento no admitida';
    6: Result := 'error de página';
  else
    Result := 'sin detalle';
  end;
end;

constructor TPdfToTiff.Create(AOwner: TComponent);
begin
  inherited;
  FDpi := 300;
  FModule := 0;
  FInitialized := False;
end;

destructor TPdfToTiff.Destroy;
begin
  UnloadApi;
  inherited;
end;

procedure TPdfToTiff.SetDpi(const Value: Integer);
begin
  if (Value < 72) or (Value > 600) then
    raise EArgumentOutOfRangeException.Create('Dpi debe estar entre 72 y 600.');
  FDpi := Value;
end;

procedure TPdfToTiff.LoadApi;

  procedure Bind(var ATarget; const AName: AnsiString);
  var
    Address: Pointer;
  begin
    Address := GetProcAddress(FModule, PAnsiChar(AName));
    if Address = nil then
      raise EPdfiumError.CreateFmt('PDFium no exporta %s.', [string(AName)]);
    Pointer(ATarget) := Address;
  end;

begin
  if FModule <> 0 then
    Exit;
  if (FPdfiumDll = '') or not TFile.Exists(FPdfiumDll) then
    raise EPdfiumError.Create('No existe pdfium.dll: ' + FPdfiumDll);

  FModule := LoadLibrary(PChar(FPdfiumDll));
  if FModule = 0 then
    raise EPdfiumError.CreateFmt('No se pudo cargar pdfium.dll (Win32=%d).',
      [GetLastError]);
  try
    Bind(FPDF_InitLibrary, 'FPDF_InitLibrary');
    Bind(FPDF_DestroyLibrary, 'FPDF_DestroyLibrary');
    Bind(FPDF_LoadDocument, 'FPDF_LoadDocument');
    Bind(FPDF_CloseDocument, 'FPDF_CloseDocument');
    Bind(FPDF_GetLastError, 'FPDF_GetLastError');
    Bind(FPDF_GetPageCount, 'FPDF_GetPageCount');
    Bind(FPDF_LoadPage, 'FPDF_LoadPage');
    Bind(FPDF_ClosePage, 'FPDF_ClosePage');
    Bind(FPDF_GetPageWidthF, 'FPDF_GetPageWidthF');
    Bind(FPDF_GetPageHeightF, 'FPDF_GetPageHeightF');
    Bind(FPDFBitmap_Create, 'FPDFBitmap_Create');
    Bind(FPDFBitmap_Destroy, 'FPDFBitmap_Destroy');
    Bind(FPDFBitmap_FillRect, 'FPDFBitmap_FillRect');
    Bind(FPDFBitmap_GetBuffer, 'FPDFBitmap_GetBuffer');
    Bind(FPDFBitmap_GetStride, 'FPDFBitmap_GetStride');
    Bind(FPDF_RenderPageBitmap, 'FPDF_RenderPageBitmap');
    FPDF_InitLibrary;
    FInitialized := True;
  except
    UnloadApi;
    raise;
  end;
end;

procedure TPdfToTiff.UnloadApi;
begin
  if FInitialized then
  begin
    FPDF_DestroyLibrary;
    FInitialized := False;
  end;
  if FModule <> 0 then
  begin
    FreeLibrary(FModule);
    FModule := 0;
  end;
end;

procedure TPdfToTiff.SaveBitmapAsTiff(ABitmap: Pointer; AWidth,
  AHeight: Integer; const AFileName: string);
var
  Source: PByte;
  SourceStride, Y: Integer;
  Bitmap: TBitmap;
  Image: TWICImage;
begin
  Source := FPDFBitmap_GetBuffer(ABitmap);
  SourceStride := FPDFBitmap_GetStride(ABitmap);
  if (Source = nil) or (SourceStride < AWidth * 4) then
    raise EPdfiumError.Create('PDFium devolvió un búfer de imagen no válido.');

  Bitmap := TBitmap.Create;
  try
    Bitmap.PixelFormat := pf32bit;
    Bitmap.SetSize(AWidth, AHeight);
    for Y := 0 to AHeight - 1 do
      Move(PByte(NativeUInt(Source) + NativeUInt(Y * SourceStride))^,
        Bitmap.ScanLine[Y]^, AWidth * 4);

    Image := TWICImage.Create;
    try
      Image.Assign(Bitmap);
      Image.ImageFormat := wifTiff;
      Image.SaveToFile(AFileName);
    finally
      Image.Free;
    end;
  finally
    Bitmap.Free;
  end;
end;

function TPdfToTiff.ExtractPages(const APdfFile,
  AOutputDirectory: string): TArray<string>;
var
  PdfPathUtf8: UTF8String;
  Document, Page, Bitmap: Pointer;
  PageCount, PageIndex, Width, Height: Integer;
  WidthPoints, HeightPoints: Single;
  OutputFile: string;
begin
  if not TFile.Exists(APdfFile) then
    raise EFileNotFoundException.Create('No existe el PDF: ' + APdfFile);
  TDirectory.CreateDirectory(AOutputDirectory);
  LoadApi;

  PdfPathUtf8 := UTF8Encode(TPath.GetFullPath(APdfFile));
  Document := FPDF_LoadDocument(PAnsiChar(PdfPathUtf8), nil);
  if Document = nil then
    raise EPdfiumError.CreateFmt('No se pudo abrir el PDF: %s (%d).',
      [PdfiumErrorText(FPDF_GetLastError), FPDF_GetLastError]);
  try
    PageCount := FPDF_GetPageCount(Document);
    if PageCount <= 0 then
      raise EPdfiumError.Create('El PDF no contiene páginas.');
    SetLength(Result, PageCount);

    for PageIndex := 0 to PageCount - 1 do
    begin
      Page := FPDF_LoadPage(Document, PageIndex);
      if Page = nil then
        raise EPdfiumError.CreateFmt('No se pudo abrir la página %d.',
          [PageIndex + 1]);
      try
        WidthPoints := FPDF_GetPageWidthF(Page);
        HeightPoints := FPDF_GetPageHeightF(Page);
        Width := Ceil(WidthPoints * FDpi / 72.0);
        Height := Ceil(HeightPoints * FDpi / 72.0);
        Bitmap := FPDFBitmap_Create(Width, Height, 0);
        if Bitmap = nil then
          raise EPdfiumError.CreateFmt(
            'No se pudo reservar la imagen de la página %d.', [PageIndex + 1]);
        try
          if FPDFBitmap_FillRect(Bitmap, 0, 0, Width, Height, $FFFFFFFF) = 0 then
            raise EPdfiumError.Create('No se pudo inicializar el fondo TIFF.');
          FPDF_RenderPageBitmap(Bitmap, Page, 0, 0, Width, Height, 0, 0);
          OutputFile := TPath.Combine(AOutputDirectory,
            Format('pagina-%.3d.tif', [PageIndex + 1]));
          SaveBitmapAsTiff(Bitmap, Width, Height, OutputFile);
          Result[PageIndex] := OutputFile;
          if Assigned(FOnPage) then
            FOnPage(Self, PageIndex + 1, PageCount, OutputFile);
        finally
          FPDFBitmap_Destroy(Bitmap);
        end;
      finally
        FPDF_ClosePage(Page);
      end;
    end;
  finally
    FPDF_CloseDocument(Document);
  end;
end;

end.
