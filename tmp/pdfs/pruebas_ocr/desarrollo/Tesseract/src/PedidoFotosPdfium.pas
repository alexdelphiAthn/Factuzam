unit PedidoFotosPdfium;

interface

uses
  System.SysUtils,
  System.JSON;

type
  EPedidoFotosPdfium = class(Exception);

  TPedidoFotosPdfium = class sealed
  public
    class function Extract(const APdfFile: string; ADocument: TJSONObject;
      const AProveedor, APdfiumDll, AFotosDirectory,
      AManifestFile: string): Integer; static;
  end;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  Vcl.Graphics;

const
  CPageObjectImage = 3;
  CBitmapGray = 1;
  CBitmapBgr = 2;
  CBitmapBgrx = 3;
  CBitmapBgra = 4;

type
  TPhotoLine = record
    Code: string;
    Model: string;
    Description: string;
  end;

  TImageMetadata = record
    Width: Cardinal;
    Height: Cardinal;
    HorizontalDpi: Single;
    VerticalDpi: Single;
    BitsPerPixel: Cardinal;
    ColorSpace: Integer;
    MarkedContentId: Integer;
  end;
  PImageMetadata = ^TImageMetadata;

  TFPDF_InitLibrary = procedure; stdcall;
  TFPDF_DestroyLibrary = procedure; stdcall;
  TFPDF_LoadDocument = function(FilePath, Password: PAnsiChar): Pointer; stdcall;
  TFPDF_CloseDocument = procedure(Document: Pointer); stdcall;
  TFPDF_GetLastError = function: Cardinal; stdcall;
  TFPDF_GetPageCount = function(Document: Pointer): Integer; stdcall;
  TFPDF_LoadPage = function(Document: Pointer; PageIndex: Integer): Pointer; stdcall;
  TFPDF_ClosePage = procedure(Page: Pointer); stdcall;
  TFPDFPage_CountObjects = function(Page: Pointer): Integer; stdcall;
  TFPDFPage_GetObject = function(Page: Pointer; Index: Integer): Pointer; stdcall;
  TFPDFPageObj_GetType = function(PageObject: Pointer): Integer; stdcall;
  TFPDFImageObj_GetImageMetadata = function(ImageObject, Page: Pointer;
    Metadata: PImageMetadata): Integer; stdcall;
  TFPDFImageObj_GetRenderedBitmap = function(Document, Page,
    ImageObject: Pointer): Pointer; stdcall;
  TFPDFBitmap_Destroy = procedure(Bitmap: Pointer); stdcall;
  TFPDFBitmap_GetBuffer = function(Bitmap: Pointer): Pointer; stdcall;
  TFPDFBitmap_GetWidth = function(Bitmap: Pointer): Integer; stdcall;
  TFPDFBitmap_GetHeight = function(Bitmap: Pointer): Integer; stdcall;
  TFPDFBitmap_GetStride = function(Bitmap: Pointer): Integer; stdcall;
  TFPDFBitmap_GetFormat = function(Bitmap: Pointer): Integer; stdcall;

  TPhotoPdfiumApi = class
  private
    FModule: HMODULE;
    FInitialized: Boolean;
    FPDF_InitLibrary: TFPDF_InitLibrary;
    FPDF_DestroyLibrary: TFPDF_DestroyLibrary;
    FPDF_LoadDocument: TFPDF_LoadDocument;
    FPDF_CloseDocument: TFPDF_CloseDocument;
    FPDF_GetLastError: TFPDF_GetLastError;
    FPDF_GetPageCount: TFPDF_GetPageCount;
    FPDF_LoadPage: TFPDF_LoadPage;
    FPDF_ClosePage: TFPDF_ClosePage;
    FPDFPage_CountObjects: TFPDFPage_CountObjects;
    FPDFPage_GetObject: TFPDFPage_GetObject;
    FPDFPageObj_GetType: TFPDFPageObj_GetType;
    FPDFImageObj_GetImageMetadata: TFPDFImageObj_GetImageMetadata;
    FPDFImageObj_GetRenderedBitmap: TFPDFImageObj_GetRenderedBitmap;
    FPDFBitmap_Destroy: TFPDFBitmap_Destroy;
    FPDFBitmap_GetBuffer: TFPDFBitmap_GetBuffer;
    FPDFBitmap_GetWidth: TFPDFBitmap_GetWidth;
    FPDFBitmap_GetHeight: TFPDFBitmap_GetHeight;
    FPDFBitmap_GetStride: TFPDFBitmap_GetStride;
    FPDFBitmap_GetFormat: TFPDFBitmap_GetFormat;
    procedure Bind(var ATarget; const AName: AnsiString);
    procedure Load(const APdfiumDll: string);
    procedure Unload;
    function IsProductPhoto(const AProveedor: string;
      const AMetadata: TImageMetadata): Boolean;
    function CountCandidates(ADocument: Pointer;
      const AProveedor: string): Integer;
    procedure SaveBitmapAsPng(ABitmap: Pointer; const AFileName: string);
    procedure ExtractCandidates(ADocument: Pointer; const AProveedor,
      AFotosDirectory: string; ALines: TList<TPhotoLine>;
      AManifest: TJSONArray);
  public
    constructor Create;
    destructor Destroy; override;
    function Extract(const APdfFile: string; const AProveedor,
      APdfiumDll, AFotosDirectory, AManifestFile: string;
      ALines: TList<TPhotoLine>): Integer;
  end;

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

function JsonText(AObject: TJSONObject; const AName: string): string;
var
  Value: TJSONValue;
begin
  Result := '';
  Value := AObject.GetValue(AName);
  if (Value <> nil) and not (Value is TJSONNull) then
    Result := Value.Value;
end;

function CollectPhotoLines(ADocument: TJSONObject): TList<TPhotoLine>;
var
  DetailValue: TJSONValue;
  Detail: TJSONArray;
  LineValue: TJSONValue;
  LineObject: TJSONObject;
  PhotoLine: TPhotoLine;
begin
  Result := TList<TPhotoLine>.Create;
  try
    DetailValue := ADocument.GetValue('detalle');
    if not (DetailValue is TJSONArray) then
      raise EPedidoFotosPdfium.Create(
        'El JSON del pedido no contiene el array detalle.');
    Detail := TJSONArray(DetailValue);
    for LineValue in Detail do
    begin
      if not (LineValue is TJSONObject) then
        raise EPedidoFotosPdfium.Create(
          'El JSON del pedido contiene una línea de detalle no válida.');
      LineObject := TJSONObject(LineValue);
      PhotoLine.Code := JsonText(LineObject, 'codigo_foto');
      if PhotoLine.Code <> '' then
      begin
        PhotoLine.Model := JsonText(LineObject, 'modelo');
        PhotoLine.Description := JsonText(LineObject, 'descripcion');
        Result.Add(PhotoLine);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure WriteUtf8Json(const AFileName, AText: string);
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

constructor TPhotoPdfiumApi.Create;
begin
  inherited;
  FModule := 0;
  FInitialized := False;
end;

destructor TPhotoPdfiumApi.Destroy;
begin
  Unload;
  inherited;
end;

procedure TPhotoPdfiumApi.Bind(var ATarget; const AName: AnsiString);
var
  Address: Pointer;
begin
  Address := GetProcAddress(FModule, PAnsiChar(AName));
  if Address = nil then
    raise EPedidoFotosPdfium.CreateFmt('PDFium no exporta %s.',
      [string(AName)]);
  Pointer(ATarget) := Address;
end;

procedure TPhotoPdfiumApi.Load(const APdfiumDll: string);
begin
  if FModule <> 0 then
    Exit;
  if not TFile.Exists(APdfiumDll) then
    raise EPedidoFotosPdfium.Create('No existe pdfium.dll: ' + APdfiumDll);
  FModule := LoadLibrary(PChar(APdfiumDll));
  if FModule = 0 then
    raise EPedidoFotosPdfium.CreateFmt(
      'No se pudo cargar pdfium.dll para extraer fotos (Win32=%d).',
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
    Bind(FPDFPage_CountObjects, 'FPDFPage_CountObjects');
    Bind(FPDFPage_GetObject, 'FPDFPage_GetObject');
    Bind(FPDFPageObj_GetType, 'FPDFPageObj_GetType');
    Bind(FPDFImageObj_GetImageMetadata, 'FPDFImageObj_GetImageMetadata');
    Bind(FPDFImageObj_GetRenderedBitmap, 'FPDFImageObj_GetRenderedBitmap');
    Bind(FPDFBitmap_Destroy, 'FPDFBitmap_Destroy');
    Bind(FPDFBitmap_GetBuffer, 'FPDFBitmap_GetBuffer');
    Bind(FPDFBitmap_GetWidth, 'FPDFBitmap_GetWidth');
    Bind(FPDFBitmap_GetHeight, 'FPDFBitmap_GetHeight');
    Bind(FPDFBitmap_GetStride, 'FPDFBitmap_GetStride');
    Bind(FPDFBitmap_GetFormat, 'FPDFBitmap_GetFormat');
    FPDF_InitLibrary;
    FInitialized := True;
  except
    Unload;
    raise;
  end;
end;

procedure TPhotoPdfiumApi.Unload;
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

function TPhotoPdfiumApi.IsProductPhoto(const AProveedor: string;
  const AMetadata: TImageMetadata): Boolean;
begin
  if SameText(AProveedor, 'aznar') then
    Result := (AMetadata.Width = 160) and (AMetadata.Height = 160)
  else if SameText(AProveedor, 'anita') then
    Result := (AMetadata.Width = 800) and (AMetadata.Height = 800)
  else if SameText(AProveedor, 'guasch') then
    Result := (AMetadata.Width = 375) and (AMetadata.Height = 375)
  else if SameText(AProveedor, 'rasdemar') then
    Result := (AMetadata.Width >= 1000) and (AMetadata.Height >= 1500)
  else
    Result := False;
end;

function TPhotoPdfiumApi.CountCandidates(ADocument: Pointer;
  const AProveedor: string): Integer;
var
  Page, PageObject: Pointer;
  PageIndex, ObjectIndex, PageCount, ObjectCount: Integer;
  Metadata: TImageMetadata;
begin
  Result := 0;
  PageCount := FPDF_GetPageCount(ADocument);
  for PageIndex := 0 to PageCount - 1 do
  begin
    Page := FPDF_LoadPage(ADocument, PageIndex);
    if Page = nil then
      raise EPedidoFotosPdfium.CreateFmt('No se pudo abrir la página %d.',
        [PageIndex + 1]);
    try
      ObjectCount := FPDFPage_CountObjects(Page);
      for ObjectIndex := 0 to ObjectCount - 1 do
      begin
        PageObject := FPDFPage_GetObject(Page, ObjectIndex);
        if (PageObject <> nil) and
           (FPDFPageObj_GetType(PageObject) = CPageObjectImage) and
           (FPDFImageObj_GetImageMetadata(PageObject, Page, @Metadata) <> 0) and
           IsProductPhoto(AProveedor, Metadata) then
          Inc(Result);
      end;
    finally
      FPDF_ClosePage(Page);
    end;
  end;
end;

procedure TPhotoPdfiumApi.SaveBitmapAsPng(ABitmap: Pointer;
  const AFileName: string);
var
  Source, SourcePixel, Target, TargetPixel: PByte;
  Width, Height, Stride, BitmapFormat, X, Y: Integer;
  Bitmap: TBitmap;
  Image: TWICImage;
begin
  Source := FPDFBitmap_GetBuffer(ABitmap);
  Width := FPDFBitmap_GetWidth(ABitmap);
  Height := FPDFBitmap_GetHeight(ABitmap);
  Stride := FPDFBitmap_GetStride(ABitmap);
  BitmapFormat := FPDFBitmap_GetFormat(ABitmap);
  if (Source = nil) or (Width <= 0) or (Height <= 0) or (Stride <= 0) then
    raise EPedidoFotosPdfium.Create(
      'PDFium devolvió un búfer de foto no válido.');
  if not (BitmapFormat in [CBitmapGray, CBitmapBgr, CBitmapBgrx,
      CBitmapBgra]) then
    raise EPedidoFotosPdfium.CreateFmt(
      'PDFium devolvió un formato de foto no admitido: %d.', [BitmapFormat]);

  Bitmap := TBitmap.Create;
  try
    Bitmap.PixelFormat := pf24bit;
    Bitmap.SetSize(Width, Height);
    for Y := 0 to Height - 1 do
    begin
      Target := Bitmap.ScanLine[Y];
      SourcePixel := PByte(NativeUInt(Source) + NativeUInt(Y * Stride));
      if BitmapFormat = CBitmapBgr then
        Move(SourcePixel^, Target^, Width * 3)
      else
      begin
        for X := 0 to Width - 1 do
        begin
          TargetPixel := PByte(NativeUInt(Target) + NativeUInt(X * 3));
          if BitmapFormat = CBitmapGray then
          begin
            TargetPixel^ := SourcePixel^;
            PByte(NativeUInt(TargetPixel) + 1)^ := SourcePixel^;
            PByte(NativeUInt(TargetPixel) + 2)^ := SourcePixel^;
            Inc(SourcePixel);
          end
          else
          begin
            TargetPixel^ := SourcePixel^;
            PByte(NativeUInt(TargetPixel) + 1)^ :=
              PByte(NativeUInt(SourcePixel) + 1)^;
            PByte(NativeUInt(TargetPixel) + 2)^ :=
              PByte(NativeUInt(SourcePixel) + 2)^;
            Inc(SourcePixel, 4);
          end;
        end;
      end;
    end;

    Image := TWICImage.Create;
    try
      Image.Assign(Bitmap);
      Image.ImageFormat := wifPng;
      Image.SaveToFile(AFileName);
    finally
      Image.Free;
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TPhotoPdfiumApi.ExtractCandidates(ADocument: Pointer;
  const AProveedor, AFotosDirectory: string; ALines: TList<TPhotoLine>;
  AManifest: TJSONArray);
var
  Page, PageObject, RenderedBitmap: Pointer;
  PageIndex, ObjectIndex, PageCount, ObjectCount, PhotoIndex: Integer;
  Metadata: TImageMetadata;
  PhotoLine: TPhotoLine;
  OutputFile, FileName: string;
  ManifestEntry: TJSONObject;
begin
  PhotoIndex := 0;
  PageCount := FPDF_GetPageCount(ADocument);
  for PageIndex := 0 to PageCount - 1 do
  begin
    Page := FPDF_LoadPage(ADocument, PageIndex);
    if Page = nil then
      raise EPedidoFotosPdfium.CreateFmt('No se pudo abrir la página %d.',
        [PageIndex + 1]);
    try
      ObjectCount := FPDFPage_CountObjects(Page);
      for ObjectIndex := 0 to ObjectCount - 1 do
      begin
        PageObject := FPDFPage_GetObject(Page, ObjectIndex);
        if (PageObject <> nil) and
           (FPDFPageObj_GetType(PageObject) = CPageObjectImage) and
           (FPDFImageObj_GetImageMetadata(PageObject, Page, @Metadata) <> 0) and
           IsProductPhoto(AProveedor, Metadata) then
        begin
          PhotoLine := ALines[PhotoIndex];
          FileName := PhotoLine.Code + '.png';
          OutputFile := TPath.Combine(AFotosDirectory, FileName);
          RenderedBitmap := FPDFImageObj_GetRenderedBitmap(ADocument, Page,
            PageObject);
          if RenderedBitmap = nil then
            raise EPedidoFotosPdfium.CreateFmt(
              'No se pudo renderizar la foto %s.', [PhotoLine.Code]);
          try
            SaveBitmapAsPng(RenderedBitmap, OutputFile);
          finally
            FPDFBitmap_Destroy(RenderedBitmap);
          end;

          ManifestEntry := TJSONObject.Create;
          ManifestEntry.AddPair('codigo_foto', PhotoLine.Code);
          ManifestEntry.AddPair('archivo', FileName);
          ManifestEntry.AddPair('modelo', PhotoLine.Model);
          ManifestEntry.AddPair('descripcion', PhotoLine.Description);
          ManifestEntry.AddPair('pagina', TJSONNumber.Create(PageIndex + 1));
          ManifestEntry.AddPair('objeto_pdf',
            TJSONNumber.Create(ObjectIndex + 1));
          ManifestEntry.AddPair('ancho',
            TJSONNumber.Create(Integer(Metadata.Width)));
          ManifestEntry.AddPair('alto',
            TJSONNumber.Create(Integer(Metadata.Height)));
          AManifest.AddElement(ManifestEntry);
          Inc(PhotoIndex);
        end;
      end;
    finally
      FPDF_ClosePage(Page);
    end;
  end;
end;

function TPhotoPdfiumApi.Extract(const APdfFile, AProveedor, APdfiumDll,
  AFotosDirectory, AManifestFile: string;
  ALines: TList<TPhotoLine>): Integer;
var
  PdfPathUtf8: UTF8String;
  Document: Pointer;
  CandidateCount: Integer;
  Manifest: TJSONArray;
begin
  Result := 0;
  if ALines.Count = 0 then
    Exit;
  Load(APdfiumDll);
  PdfPathUtf8 := UTF8Encode(TPath.GetFullPath(APdfFile));
  Document := FPDF_LoadDocument(PAnsiChar(PdfPathUtf8), nil);
  if Document = nil then
    raise EPedidoFotosPdfium.CreateFmt(
      'No se pudo abrir el PDF para extraer fotos: %s (%d).',
      [PdfiumErrorText(FPDF_GetLastError), FPDF_GetLastError]);
  try
    CandidateCount := CountCandidates(Document, AProveedor);
    if CandidateCount <> ALines.Count then
      raise EPedidoFotosPdfium.CreateFmt(
        'El pedido contiene %d códigos de foto, pero PDFium ha detectado %d fotos de producto.',
        [ALines.Count, CandidateCount]);
    TDirectory.CreateDirectory(AFotosDirectory);
    Manifest := TJSONArray.Create;
    try
      ExtractCandidates(Document, AProveedor, AFotosDirectory, ALines,
        Manifest);
      WriteUtf8Json(AManifestFile, Manifest.Format(2));
    finally
      Manifest.Free;
    end;
    Result := CandidateCount;
  finally
    FPDF_CloseDocument(Document);
  end;
end;

class function TPedidoFotosPdfium.Extract(const APdfFile: string;
  ADocument: TJSONObject; const AProveedor, APdfiumDll,
  AFotosDirectory, AManifestFile: string): Integer;
var
  Lines: TList<TPhotoLine>;
  Api: TPhotoPdfiumApi;
begin
  Lines := CollectPhotoLines(ADocument);
  try
    Api := TPhotoPdfiumApi.Create;
    try
      Result := Api.Extract(APdfFile, AProveedor, APdfiumDll,
        AFotosDirectory, AManifestFile, Lines);
    finally
      Api.Free;
    end;
  finally
    Lines.Free;
  end;
end;

end.
