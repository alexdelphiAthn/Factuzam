unit uTesseractMonitor;

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
  /// <para>This class is used as both a progress monitor and the final
  /// output header, since it needs to be a valid progress monitor while
  /// the OCR engine is storing its output to shared memory.</para>
  /// <para>During progress, all the buffer info is -1.</para>
  /// <para>Progress starts at 0 and increases to 100 during OCR. No other constraint.</para>
  /// <para>Additionally the progress callback contains the bounding box of the word that
  /// is currently being processed.</para>
  /// <para>Every progress callback, the OCR engine must set ocr_alive to 1.
  /// The HP side will set ocr_alive to 0. Repeated failure to reset
  /// to 1 indicates that the OCR engine is dead.</para>
  /// <para>If the cancel function is not null then it is called with the number of
  /// user words found. If it returns true then operation is cancelled.</para>
  /// </summary>
  TTesseractMonitor = class
    protected
      FHandle : PETEXT_DESC;

      function  GetInitialized : boolean;
      function  GetCancelThis : Pointer;
      function  GetProgress : integer;

      procedure SetCancelThis(cancelThis : Pointer);

    public
      constructor Create;
      destructor  Destroy; override;
      /// <summary>
      /// Sets the Cancel function.
      /// </summary>
      function    SetCancelFunc(const cancelFunc : TessCancelFunc) : boolean;
      /// <summary>
      /// Sets the progress function, which is called whenever progress increases.
      /// </summary>
      function    SetProgressFunc(const progressFunc : TessProgressFunc) : boolean;
      /// <summary>
      /// Time to stop.
      /// </summary>
      function    SetDeadlineMSecs(deadline : Integer) : boolean;

      property Handle       : PETEXT_DESC         read FHandle;
      /// <summary>
      /// Returns true when this instance is fully initialized.
      /// </summary>
      property Initialized  : boolean             read GetInitialized;
      /// <summary>
      /// Pointer used as an argument in the Cancel function.
      /// </summary>
      property CancelThis   : Pointer             read GetCancelThis      write SetCancelThis;
      /// <summary>
      /// Percent complete increasing (0-100). Progress monitor covers word recognition and it does not cover layout analysis.
      /// </summary>
      property Progress     : integer             read GetProgress;
  end;

implementation

uses
  uTesseractLoader;

constructor TTesseractMonitor.Create;
begin
  inherited Create;

  if assigned(GlobalTesseractLoader) and GlobalTesseractLoader.Initialized then
    FHandle := TessMonitorCreate()
   else
    FHandle := nil;
end;

destructor TTesseractMonitor.Destroy;
begin
  if Initialized then
    begin
      TessMonitorDelete(FHandle);
      FHandle := nil;
    end;

  inherited Destroy;
end;

function TTesseractMonitor.GetInitialized : boolean;
begin
  Result := (FHandle <> nil);
end;

function TTesseractMonitor.GetCancelThis : Pointer;
begin
  if Initialized then
    Result := TessMonitorGetCancelThis(FHandle)
   else
    Result := nil;
end;

function TTesseractMonitor.GetProgress : integer;
begin
  if Initialized then
    Result := TessMonitorGetProgress(FHandle)
   else
    Result := 0;
end;

function TTesseractMonitor.SetCancelFunc(const cancelFunc : TessCancelFunc) : boolean;
begin
  Result := False;

  if Initialized then
    begin
      TessMonitorSetCancelFunc(FHandle, cancelFunc);
      Result := True;
    end;
end;

procedure TTesseractMonitor.SetCancelThis(cancelThis : Pointer);
begin
  if Initialized then
    TessMonitorSetCancelThis(FHandle, cancelThis);
end;

function TTesseractMonitor.SetDeadlineMSecs(deadline : Integer) : boolean;
begin
  Result := False;

  if Initialized then
    begin
      TessMonitorSetDeadlineMSecs(FHandle, deadline);
      Result := True;
    end;
end;

function TTesseractMonitor.SetProgressFunc(const progressFunc : TessProgressFunc) : boolean;
begin
  Result := False;

  if Initialized then
    begin
      TessMonitorSetProgressFunc(FHandle, progressFunc);
      Result := True;
    end;
end;

end.

