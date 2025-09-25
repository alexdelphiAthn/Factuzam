unit inLibLog;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, //inLibGlobalVar,
  inLibDir, Windows, System.SyncObjs, Winapi.Messages,
  System.TypInfo, System.Zip, System.Generics.Collections;

const
  DEFAULT_LOG_RETENTION = 10;
  MUTEX_NAME = 'Global\DeleteFileLogMutex';
  MUTEX_TIMEOUT = 5000; // 5 segundos de timeout

type
  TLogType = (ltInfo, ltWarning, ltError, ltSQL);
  TLogFlags = set of TLogType;
  TLog = class
  private
    FLogFileName: string;
    FLogFlags: TLogFlags;
    FInstanceID: string;
    FLogRetention: Integer;
    FMutexHandle: THandle;
    function LogTypeToString(ALogType: TLogType): string;
    procedure WriteToLog(const AMessage: string; ALogType: TLogType);
    procedure WriteToLogInternal(const AMessage: string);
    procedure WriteInitialInfo;
    function GenerateInstanceID: string;
    procedure RotateLogs;
    function AcquireMutex: Boolean;
    procedure ReleaseMutex;
    function IsFileAccessible(const FileName: string): Boolean;
  public
    constructor Create(ALogRetention: Integer = DEFAULT_LOG_RETENTION);
    destructor Destroy; override;
    procedure LogInfo(const AMessage: string); overload;
    procedure LogWarning(const AMessage: string);
    procedure LogError(const AMessage: string);
    procedure LogSQL(const ASQL: string);
    procedure EnableLogType(ALogType: TLogType);
    procedure DisableLogType(ALogType: TLogType);
    function IsLogTypeEnabled(ALogType: TLogType): Boolean;
    property InstanceID: string read FInstanceID;
  end;
var
  Log: TLog;
implementation

uses
  System.DateUtils, inLibWin;

{ TLog }

function TLog.LogTypeToString(ALogType: TLogType): string;
begin
  case ALogType of
    ltInfo: Result := 'INFO';
    ltWarning: Result := 'WARNING';
    ltError: Result := 'ERROR';
    ltSQL: Result := 'SQL';
  else
    Result := 'UNKNOWN';
  end;
end;

function TLog.AcquireMutex: Boolean;
begin
  Result := WaitForSingleObject(FMutexHandle, MUTEX_TIMEOUT) = WAIT_OBJECT_0;
end;
procedure TLog.ReleaseMutex;
begin
  Windows.ReleaseMutex(FMutexHandle);
end;

constructor TLog.Create(ALogRetention: Integer = DEFAULT_LOG_RETENTION);
  function FileGetSize(const FileName: TFileName): Int64;
  var
   SearchRec: TSearchRec;
  begin
    if FindFirst(FileName, faAnyFile, SearchRec) = 0 then
    begin
      Result := SearchRec.Size;
      System.SysUtils.FindClose(SearchRec);
    end
    else
      Result := -1;
  end;
var
  IsNewFile: Boolean;
begin
  inherited Create;
  FInstanceID := GenerateInstanceID;
  FLogRetention := ALogRetention;
  FLogFileName := TPath.Combine(GetLogFolder, 'LOG_' + FInstanceID +'_' +
                                FormatDateTime('dd_mm_yyyy', Now) + '.log');
  if not IsFileAccessible(FLogFileName) then
    raise Exception.CreateFmt('No se puede acceder a %s. Faltan permisos.',
                              [FLogFileName]);
  FMutexHandle := CreateMutex(nil, False, PChar(MUTEX_NAME));
  if FMutexHandle = 0 then
    raise Exception.Create('Error al crear mutex: ' + MUTEX_NAME);
  // SQL logging desactivado por defecto
  FLogFlags := [ltInfo, ltWarning, ltError];
  IsNewFile := (FileGetSize(FLogFileName) = 0);
  if IsNewFile then
    WriteInitialInfo;
  WriteToLog('Logging session started.', ltInfo);
  RotateLogs;
end;

function TLog.GenerateInstanceID: string;
var
  GUID: TGUID;
begin
  if (CreateGUID(GUID) = S_OK) then
    Result := GUIDToString(GUID)
  else
    Result := IntToStr(DateTimeToUnix(Now, False)) + IntToStr(GetTickCount);
end;

destructor TLog.Destroy;
begin
  WriteToLog('Logging session ended.', ltInfo);
  if FMutexHandle <> 0 then
    CloseHandle(FMutexHandle);
  inherited;
end;


procedure TLog.WriteToLogInternal(const AMessage: string);
var
  LogFile: TextFile;
begin
  if AcquireMutex then
  try
    AssignFile(LogFile, FLogFileName);
    try
      if FileExists(FLogFileName) then
        Append(LogFile)
      else
        Rewrite(LogFile);
      WriteLn(LogFile, Format('%s - [Instance: %s] %s',
                              [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
                               FInstanceID,
                               AMessage]));
    finally
      CloseFile(LogFile);
    end;
  finally
    ReleaseMutex;
  end;
end;

function TLog.IsFileAccessible(const FileName: string): Boolean;
var
  FileHandle: THandle;
begin
  FileHandle := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  Result := FileHandle <> INVALID_HANDLE_VALUE;
  if Result then
    CloseHandle(FileHandle);
end;

procedure TLog.WriteInitialInfo;
begin
  WriteToLogInternal('-------- New Log File --------');
  WriteToLogInternal('Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  WriteToLogInternal('Computer Name: ' + GetComputerName);
  WriteToLogInternal('Windows User: ' + GetWindowsUserName);
  WriteToLogInternal('Windows Version: ' + GetWindowsVersion);
  WriteToLogInternal('Program Path: ' + GetProgramPath);
  WriteToLogInternal('Log Folder: ' + GetLogFolder);
  //WriteToLogInternal('Versión de fzam: '+ inlibGlobalVar.oVersion);
  WriteToLogInternal('-------------------------------');
end;
procedure TLog.LogInfo(const AMessage: string);
begin
  WriteToLog('INFO: ' + AMessage, ltInfo);
end;

procedure TLog.LogWarning(const AMessage: string);
begin
  WriteToLog('WARNING: ' + AMessage, ltWarning);
end;

procedure TLog.LogError(const AMessage: string);
begin
  WriteToLog('ERROR: ' + AMessage, ltError);
end;

procedure TLog.LogSQL(const ASQL: string);
var
  SQLOneLine: string;
begin
  SQLOneLine := StringReplace(ASQL, sLineBreak, ' ', [rfReplaceAll]);
  SQLOneLine := Trim(SQLOneLine);
  WriteToLog('SQL: ' + SQLOneLine, ltSQL);
end;

procedure TLog.EnableLogType(ALogType: TLogType);
begin
  Include(FLogFlags, ALogType);
end;

procedure TLog.DisableLogType(ALogType: TLogType);
begin
  Exclude(FLogFlags, ALogType);
end;

function TLog.IsLogTypeEnabled(ALogType: TLogType): Boolean;
begin
  Result := ALogType in FLogFlags;
end;

procedure TLog.RotateLogs;
var
  LogFiles: TArray<string>;
  ArchiveFolder: string;
  ZipFileName: string;
  Zip: TZipFile;
  I: Integer;
begin
  ArchiveFolder := TPath.Combine(GetLogFolder, 'archive');
  if not TDirectory.Exists(ArchiveFolder) then
    TDirectory.CreateDirectory(ArchiveFolder);
  LogFiles := TDirectory.GetFiles(GetLogFolder, '*.log');
  if Length(LogFiles) > FLogRetention then
  begin
    TArray.Sort<string>(LogFiles);
    ZipFileName := TPath.Combine(ArchiveFolder, 'Logs_' +
                               FormatDateTime('yyyymmdd_hhnnss', Now) + '.zip');
    Zip := TZipFile.Create;
    try
      Zip.Open(ZipFileName, zmWrite);
      for I := 0 to Length(LogFiles) - FLogRetention - 1 do
      begin
        Zip.Add(LogFiles[I], ExtractFileName(LogFiles[I]));
        TFile.Delete(LogFiles[I]);
      end;
    finally
      Zip.Close;
      FreeAndNil(Zip);
    end;
  end;
end;

procedure TLog.WriteToLog(const AMessage: string; ALogType: TLogType);
begin
  if (ALogType in FLogFlags) then
  begin
   WriteToLogInternal(Format('%s - %s', [AMessage, LogTypeToString(ALogType)]));
  end;
end;

initialization
  Log := TLog.Create;
finalization
  Log.Free;
end.
