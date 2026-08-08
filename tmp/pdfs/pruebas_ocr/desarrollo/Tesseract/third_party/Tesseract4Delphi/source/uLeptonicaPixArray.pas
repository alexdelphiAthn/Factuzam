unit uLeptonicaPixArray;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Classes, System.SysUtils,
  {$ELSE}
    Classes, SysUtils,
  {$ENDIF}
  uLeptonicaTypes, uLeptonicaLibFunctions, uLeptonicaPix;

type
  /// <summary>
  /// Array of pix
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Pixa)</see></para>
  /// </remarks>
  TLeptonicaPixArray = class
    protected
      FPixa : PPixa;

      function  GetInitialized : boolean;
      function  GetCount : integer;

      procedure DestroyPixa;

    public
      /// <summary>
      /// Create a pix array.
      /// </summary>
      constructor Create(n: l_int32); overload;
      /// <summary>
      /// Wrap an existing pix array without incrementing the reference count.
      /// </summary>
      constructor Create(pixa_: PPixa); overload;
      destructor  Destroy; override;
      /// <summary>
      /// Copy all the information in the images to a TLeptonicaPix array.
      /// </summary>
      procedure   CopyToArray(var aPixArray : TLeptonicaPixClassArray);
      /// <summary>
      /// Returns true when the TLeptonicaBoxArray instance is fully initialized.
      /// </summary>
      property Initialized   : boolean   read GetInitialized;
      /// <summary>
      /// Pixa pointer with all the array properties.
      /// </summary>
      property Pixa          : PPixa     read FPixa;
      /// <summary>
      /// Number of images in the array.
      /// </summary>
      property Count         : integer   read GetCount;
  end;

implementation

constructor TLeptonicaPixArray.Create(n: l_int32);
begin
  inherited Create;

  FPixa := pixaCreate(n);
end;

constructor TLeptonicaPixArray.Create(pixa_: PPixa);
begin
  inherited Create;

  FPixa := pixa_;
end;

destructor TLeptonicaPixArray.Destroy;
begin
  DestroyPixa;
  inherited Destroy;
end;

procedure TLeptonicaPixArray.DestroyPixa;
begin
  if Initialized then
    begin
      pixaDestroy(FPixa);
      FPixa := nil;
    end;
end;

function TLeptonicaPixArray.GetInitialized : boolean;
begin
  Result := assigned(FPixa);
end;

function TLeptonicaPixArray.GetCount : integer;
begin
  if Initialized then
    Result := FPixa^.n
   else
    Result := 0;
end;

procedure TLeptonicaPixArray.CopyToArray(var aPixArray : TLeptonicaPixClassArray);
var
  TempPix : PPix;
  i       : integer;
begin
  if (Count > 0) and assigned(FPixa^.pix) then
    begin
      SetLength(aPixArray, Count);
      TempPix := FPixa^.pix^;
      i       := 0;

      while assigned(TempPix) and (i < Count) do
        begin
          aPixArray[i] := TLeptonicaPix.Create(TempPix);

          inc(TempPix);
          inc(i);
        end;
    end;
end;

end.
