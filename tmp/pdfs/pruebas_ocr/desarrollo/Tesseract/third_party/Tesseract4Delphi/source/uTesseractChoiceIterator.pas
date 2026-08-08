unit uTesseractChoiceIterator;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Classes,
  {$ELSE}
    Classes,
  {$ENDIF}
  uTesseractTypes, uTesseractLibFunctions;

type
  /// <summary>
  /// Class to iterate over the classifier choices for a single RIL_SYMBOL.
  /// </summary>
  TTesseractChoiceIterator = class
    private
      FHandle : TessChoiceIterator;

      function GetInitialized : boolean;
      function GetText : string;

    public
      constructor Create(aHandle: TessChoiceIterator);
      destructor  Destroy; override;
      /// <summary>
      /// Moves to the next choice for the symbol and returns false if there are none left.
      /// </summary>
      function    Next : boolean;
      /// <summary>
      /// <para>Returns the confidence of the current choice depending on the used language
      /// data. If only LSTM traineddata is used the value range is 0.0f - 1.0f. All
      /// choices for one symbol should roughly add up to 1.0f.</para>
      /// <para>If only traineddata of the legacy engine is used, the number should be
      /// interpreted as a percent probability. (0.0f-100.0f) In this case
      /// probabilities won't add up to 100. Each one stands on its own.</para>
      /// </summary>
      function    Confidence : single;

      property Handle       : TessChoiceIterator    read FHandle;
      /// <summary>
      /// Returns true when the TTesseractChoiceIterator instance is fully initialized.
      /// </summary>
      property Initialized  : boolean               read GetInitialized;
      /// <summary>
      /// Returns the text string for the current choice.
      /// </summary>
      property Text         : string                read GetText;
  end;

implementation

uses
  uTesseractMiscFunctions;

constructor TTesseractChoiceIterator.Create(aHandle: TessChoiceIterator);
begin
  inherited Create;

  FHandle := aHandle;
end;

destructor TTesseractChoiceIterator.Destroy;
begin
  if Initialized then
    begin
      TessChoiceIteratorDelete(FHandle);
      FHandle := nil;
    end;

  inherited Destroy;
end;

function TTesseractChoiceIterator.GetInitialized : boolean;
begin
  Result := (FHandle <> nil);
end;

function TTesseractChoiceIterator.GetText : string;
begin
  // The code comments for ChoiceIterator::GetUTF8Text explicitly say that this
  // function must NOT delete the returned pointer.
  if Initialized then
    Result := TessUTF8ToString(TessChoiceIteratorGetUTF8Text(FHandle), False)
   else
    Result := '';
end;

function TTesseractChoiceIterator.Next : boolean;
begin
  Result := Initialized and
            TessChoiceIteratorNext(FHandle);
end;

function TTesseractChoiceIterator.Confidence : single;
begin
  if Initialized then
    Result := TessChoiceIteratorConfidence(FHandle)
   else
    Result := 0;
end;

end.
