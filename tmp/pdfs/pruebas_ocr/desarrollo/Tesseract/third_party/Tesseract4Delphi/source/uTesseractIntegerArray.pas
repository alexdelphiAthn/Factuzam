unit uTesseractIntegerArray;

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
  uLeptonicaTypes;

type
  /// <summary>
  /// Array of integers
  /// </summary>
  TTesseractIntegerArray = class
    protected
      FPInteger : PInteger;
      FCount    : integer;

      function  GetInitialized : boolean;

      procedure DestroyPInteger;

    public
      /// <summary>
      /// Wrap an existing integer array.
      /// </summary>
      constructor Create(PInt_: PInteger; count_: integer);
      destructor  Destroy; override;
      /// <summary>
      /// Copy all the information to a dynamic integer array.
      /// </summary>
      procedure   CopyToArray(var aIntArray : TIntegerArray);
      /// <summary>
      /// Returns true when the TTesseractIntegerArray instance is fully initialized.
      /// </summary>
      property Initialized   : boolean   read GetInitialized;
      /// <summary>
      /// Number of elements in the array.
      /// </summary>
      property Count         : integer   read FCount;
  end;

implementation

uses
  uTesseractLibFunctions;

constructor TTesseractIntegerArray.Create(PInt_: PInteger; count_: integer);
begin
  inherited Create;

  FPInteger := PInt_;
  FCount    := count_;
end;

destructor TTesseractIntegerArray.Destroy;
begin
  DestroyPInteger;
  inherited Destroy;
end;

procedure TTesseractIntegerArray.DestroyPInteger;
begin
  if Initialized then
    begin
      TessDeleteIntArray(FPInteger);
      FPInteger := nil;
    end;
end;

function TTesseractIntegerArray.GetInitialized : boolean;
begin
  Result := assigned(FPInteger);
end;

procedure TTesseractIntegerArray.CopyToArray(var aIntArray : TIntegerArray);
var
  TempPInt : PInteger;
  i        : integer;
begin
  if (Count > 0) then
    begin
      SetLength(aIntArray, Count);
      TempPInt := FPInteger;
      i        := 0;

      while assigned(TempPInt) and (i < Count) do
        begin
          aIntArray[i] := TempPInt^;

          inc(TempPInt);
          inc(i);
        end;
    end;
end;

end.
