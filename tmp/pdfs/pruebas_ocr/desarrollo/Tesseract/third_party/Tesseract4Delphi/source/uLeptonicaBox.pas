unit uLeptonicaBox;

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
  /// Basic rectangle
  /// </summary>
  /// <remarks>
  /// <para><see href="https://github.com/DanBloomberg/leptonica/blob/master/src/pix_internal.h">Leptonica source file: /src/pix_internal.h (Box)</see></para>
  /// </remarks>
  TLeptonicaBox = class
    protected
      FBox : PBox;

      function  GetInitialized : boolean;
      procedure DestroyBox;

    public
      /// <summary>
      /// Create a box.
      /// </summary>
      constructor Create(x, y, w, h: l_int32); overload;
      /// <summary>
      /// Wrap an existing box without incrementing the reference count.
      /// </summary>
      constructor Create(box_: PBox); overload;
      destructor  Destroy; override;

      /// <summary>
      /// Returns true when the TLeptonicaBox instance is fully initialized.
      /// </summary>
      property Initialized   : boolean   read GetInitialized;
      /// <summary>
      /// Box pointer with all the image properties.
      /// </summary>
      property Box           : PBox      read FBox;
  end;
  TLeptonicaBoxArray = array of TLeptonicaBox;

implementation

constructor TLeptonicaBox.Create(x, y, w, h: l_int32);
begin
  inherited Create;

  FBox := boxCreate(x, y, w, h);
end;

constructor TLeptonicaBox.Create(box_: PBox);
begin
  inherited Create;

  FBox := box_;
end;

destructor TLeptonicaBox.Destroy;
begin
  DestroyBox;
  inherited Destroy;
end;

procedure TLeptonicaBox.DestroyBox;
begin
  if Initialized then
    begin
      boxDestroy(FBox);
      FBox := nil;
    end;
end;

function TLeptonicaBox.GetInitialized : boolean;
begin
  Result := assigned(FBox);
end;

end.
