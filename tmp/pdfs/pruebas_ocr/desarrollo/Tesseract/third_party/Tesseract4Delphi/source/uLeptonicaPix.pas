unit uLeptonicaPix;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

{$IFNDEF FPC}{$IFNDEF DELPHI12_UP}
  // Workaround for "Internal error" in old Delphi versions
  {$R-}
{$ENDIF}{$ENDIF}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Classes, System.SysUtils,
  {$ELSE}
    Classes, SysUtils,
  {$ENDIF}
  uLeptonicaTypes, uLeptonicaLibFunctions, uLeptonicaConstants;

type
  /// <summary>
  /// Basic Pix
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Pix)</see></para>
  /// </remarks>
  TLeptonicaPix = class
    protected
      FPix : PPix;

      function  GetInitialized : boolean;
      procedure DestroyPix;

    public
      /// <summary>
      /// Create the pix using a file.
      /// </summary>
      constructor Create(const aFileName : string); overload;
      /// <summary>
      /// Create the pix using the data in a memory buffer.
      /// </summary>
      constructor Create(aBuffer : Pointer; aSize : NativeUInt); overload;
      /// <summary>
      /// Create the pix using the data in a stream.
      /// </summary>
      constructor Create(const aStream : TStream); overload;
      /// <summary>
      /// Create the pix using an existing PPix.
      /// </summary>
      constructor Create(const aPix : PPix); overload;
      destructor  Destroy; override;
      /// <summary>
      /// <para>This binarizes if necessary and finds the skew angle. If the angle is
      /// large enough and there is sufficient confidence, it returns a deskewed
      /// image; otherwise, it returns a clone.</para>
      /// <para>Typical values at 300 ppi for %redsearch are 2 and 4.</para>
      /// <para>At 75 ppi, one should use %redsearch = 1.</para>
      /// </summary>
      /// <param name="redsearch">for binary search: reduction factor = 1, 2 or 4; use 0 for default.</param>
      /// <remarks>
      /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/skew.c">Leptonica source file: /src/skew.c (pixDeskew)</see></para>
      /// </remarks>
      function    Deskew(redsearch : integer = DEFAULT_REDUCTION_FACTOR) : TLeptonicaPix;
      /// <summary>
      /// Calls Deskew and replaces the Pix of this instance.
      /// </summary>
      function    DeskewImage : boolean;
      /// <summary>
      /// Save the image as a stream.
      /// </summary>
      function    SaveImageAsStream(var aStream : TStream; aFormat : TLeptonicaImageFormat = IFF_BMP): boolean;

      /// <summary>
      /// Returns true when the TLeptonicaPix instance is fully initialized.
      /// </summary>
      property Initialized   : boolean   read GetInitialized;
      /// <summary>
      /// Pix pointer with all the image properties.
      /// </summary>
      property Pix           : PPix      read FPix;
  end;
  TLeptonicaPixClassArray = array of TLeptonicaPix;

implementation

uses
  uLeptonicaMiscFunctions;

constructor TLeptonicaPix.Create(const aFileName : string);
begin
  inherited Create;

  FPix := nil;

  try
    if (length(aFileName) > 0) and FileExists(aFileName) then
      begin
        {$IFDEF FPC}
        FPix := pixRead(PUTF8Char(aFileName));
        {$ELSE}
        FPix := pixRead(PUTF8Char(UTF8Encode(aFileName)));
        {$ENDIF}
      end;
  except
    on e : exception do
      if CustomExceptionHandler('TLeptonicaPix.Create', e) then raise;
  end;
end;

constructor TLeptonicaPix.Create(aBuffer : Pointer; aSize : NativeUInt);
begin
  inherited Create;

  FPix := nil;

  if (aBuffer <> nil) and (aSize > 0) then
    FPix := pixReadMem(aBuffer, aSize);
end;

constructor TLeptonicaPix.Create(const aStream : TStream);
var
  TempBuffer : pointer;
begin
  inherited Create;

  FPix       := nil;
  TempBuffer := nil;

  try
    try
      if assigned(aStream) and (aStream.Size > 0) then
        begin
          TempBuffer := AllocMem(aStream.Size);
          aStream.Seek(0, soBeginning);
          aStream.ReadBuffer(TempBuffer^, aStream.Size);
          FPix := pixReadMem(TempBuffer, aStream.Size);
        end;
    except
      on e : exception do
        if CustomExceptionHandler('TLeptonicaPix.Create', e) then raise;
    end;
  finally
    if (TempBuffer <> nil) then
      FreeMem(TempBuffer);
  end;
end;

constructor TLeptonicaPix.Create(const aPix : PPix);
begin
  inherited Create;

  FPix := aPix;
end;

destructor TLeptonicaPix.Destroy;
begin
  DestroyPix;
  inherited Destroy;
end;

procedure TLeptonicaPix.DestroyPix;
begin
  if Initialized then
    begin
      pixDestroy(FPix);
      FPix := nil;
    end;
end;

function TLeptonicaPix.Deskew(redsearch : integer = DEFAULT_REDUCTION_FACTOR) : TLeptonicaPix;
var
  TempPix : PPix;
begin
  Result := nil;

  if Initialized and (redsearch in [0, 1, 2, 4]) then
    begin
      TempPix := pixDeskew(FPix, redsearch);
      if assigned(TempPix) then
        Result := TLeptonicaPix.Create(TempPix);
    end;
end;

function TLeptonicaPix.DeskewImage : boolean;
var
  TempPix : PPix;
begin
  Result := False;

  if Initialized then
    begin
      TempPix := pixDeskew(FPix, DEFAULT_REDUCTION_FACTOR);

      if (TempPix <> nil) then
        begin
          DestroyPix;
          FPix   := TempPix;
          Result := True;
        end;
    end;
end;

function TLeptonicaPix.SaveImageAsStream(var aStream : TStream; aFormat : TLeptonicaImageFormat): boolean;
var
  TempResult : l_ok;
  TempSize   : NativeUInt;
  TempBuffer : pl_uint8;
begin
  Result     := False;
  TempBuffer := nil;
  TempSize   := 0;

  if Initialized and assigned(aStream) then
    try
      TempResult := pixWriteMem(TempBuffer, TempSize, FPix, l_int32(aFormat));

      if (TempResult = 0) and (TempBuffer <> nil) and (TempSize > 0) then
        begin
          aStream.Seek(0, soBeginning);
          aStream.WriteBuffer(TempBuffer^, TempSize);
          Result := True;
        end;
    finally
      if (TempBuffer <> nil) then
        lept_free(TempBuffer);
    end;
end;

function TLeptonicaPix.GetInitialized : boolean;
begin
  Result := assigned(FPix);
end;

end.
