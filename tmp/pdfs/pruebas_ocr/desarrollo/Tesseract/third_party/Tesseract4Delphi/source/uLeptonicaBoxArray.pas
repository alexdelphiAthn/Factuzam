unit uLeptonicaBoxArray;

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
  uLeptonicaTypes, uLeptonicaLibFunctions;

type
  /// <summary>
  /// Array of Box
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Boxa)</see></para>
  /// </remarks>
  TLeptonicaBoxArray = class
    protected
      FBoxa : PBoxa;

      function  GetInitialized : boolean;
      function  GetCount : integer;

      procedure DestroyBoxa;

    public
      /// <summary>
      /// Create a box array.
      /// </summary>
      constructor Create(n: l_int32); overload;
      /// <summary>
      /// Wrap an existing box array without incrementing the reference count.
      /// </summary>
      constructor Create(boxa_: PBoxa); overload;
      destructor  Destroy; override;
      /// <summary>
      /// Copy all the information in the boxes to a TRect array.
      /// </summary>
      procedure   CopyToArray(var aRectArray : TRectArray);
      /// <summary>
      /// Returns true when the TLeptonicaBoxArray instance is fully initialized.
      /// </summary>
      property Initialized   : boolean   read GetInitialized;
      /// <summary>
      /// Boxa pointer with all the array properties.
      /// </summary>
      property Boxa          : PBoxa     read FBoxa;
      /// <summary>
      /// Number of boxes in the array.
      /// </summary>
      property Count         : integer   read GetCount;
  end;

implementation

constructor TLeptonicaBoxArray.Create(n: l_int32);
begin
  inherited Create;

  FBoxa := boxaCreate(n);
end;

constructor TLeptonicaBoxArray.Create(boxa_: PBoxa);
begin
  inherited Create;

  FBoxa := boxa_;
end;

destructor TLeptonicaBoxArray.Destroy;
begin
  DestroyBoxa;
  inherited Destroy;
end;

procedure TLeptonicaBoxArray.DestroyBoxa;
begin
  if Initialized then
    begin
      boxaDestroy(FBoxa);
      FBoxa := nil;
    end;
end;

function TLeptonicaBoxArray.GetInitialized : boolean;
begin
  Result := assigned(FBoxa);
end;

function TLeptonicaBoxArray.GetCount : integer;
begin
  if Initialized then
    Result := FBoxa^.n
   else
    Result := 0;
end;

procedure TLeptonicaBoxArray.CopyToArray(var aRectArray : TRectArray);
var
  TempBox : PBox;
  i       : integer;
begin
  if (Count > 0) and assigned(FBoxa^.box) then
    begin
      SetLength(aRectArray, Count);
      TempBox := FBoxa^.box^;
      i       := 0;

      while assigned(TempBox) and (i < Count) do
        begin
          aRectArray[i].Left   := TempBox^.x;
          aRectArray[i].Top    := TempBox^.y;
          aRectArray[i].Right  := aRectArray[i].Left + TempBox^.w - 1;
          aRectArray[i].Bottom := aRectArray[i].Top  + TempBox^.h - 1;

          inc(TempBox);
          inc(i);
        end;
    end;
end;

end.
