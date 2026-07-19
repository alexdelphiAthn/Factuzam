{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLog                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sistema de log con rotación y exclusión mutua entre procesos.             }
{    Niveles informativo, aviso, error y SQL, con retención configurable.      }
{******************************************************************************}
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
  // ltPerf: instrumentación de cronómetros (LogPerf). Apagado por defecto
  // para no ensuciar el log; se enciende con appModoDebug.
  // ltAvanzado: eventos de UI / dataset (LogEvento). Se enciende con
  // appLogAvanzado.
  TLogType = (ltInfo, ltWarning, ltError, ltSQL, ltPerf, ltAvanzado);
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
    function FechaLogArchivo(const AFileName: string): TDateTime;
    function FechaOrdenArchivo(const AFileName: string): TDateTime;
    function ClaveFechaLog(const AFecha: TDateTime): string;
    function FechaZipAnterior(const AFileName: string;
                              out AFecha: TDateTime): Boolean;
    procedure ConsolidarZipAnterior(const AZipAnterior: string;
                                    const AFechaLog: TDateTime);
    procedure MigrarZipsAnteriores;
    procedure ArchivarGrupoLogs(const AArchivos: TList<string>;
                                const AFechaLog: TDateTime);
  public
    constructor Create(ALogRetention: Integer = DEFAULT_LOG_RETENTION);
    destructor Destroy; override;
    procedure LogInfo(const AMessage: string); overload;
    procedure LogWarning(const AMessage: string);
    procedure LogError(const AMessage: string);
    procedure LogSQL(const ASQL: string);
    // Version detallada del log SQL. Registra el SQL ya ejecutado junto
    // con su tiempo en ms, filas afectadas/devueltas y exito/fallo.
    // AParams es opcional: si viene relleno (clave=valor;clave=valor)
    // se anade tras la query. Pensado para que el invocador decida si
    // se loguean valores reales segun appLogParamsSQL.
    procedure LogSQLExt(const ASQL: string; AElapsedMs: Int64; ARows: Integer;
                        AOk: Boolean; const AError: string = '';
                        const AParams: string = '');
    // Log avanzado de eventos de usuario / UI. Una linea por evento con
    // unidad (modulo Pascal), objeto (form / control / dataset), evento
    // (Click, Show, BeforePost, Execute...) y un detalle libre.
    procedure LogEvento(const AUnidad, AObjeto, AEvento, ADetalle: string);
    // Cronometro instrumentado. Escribe al log y, si el monitor SQL
    // (oMemoSQL) esta visible, tambien suelta una linea ahi para que el
    // usuario vea las metricas junto a las queries. Patron tipico:
    //   sw := TStopwatch.StartNew;
    //   ...trabajo...
    //   Log.LogPerf('Articulos.AfterScroll', 'CargarPropiedades',
    //               sw.ElapsedMilliseconds);
    procedure LogPerf(const ATag, ADetalle: string; AElapsedMs: Int64);
    procedure EnableLogType(ALogType: TLogType);
    procedure DisableLogType(ALogType: TLogType);
    function IsLogTypeEnabled(ALogType: TLogType): Boolean;
    property InstanceID: string read FInstanceID;
  end;
var
  Log: TLog;

// Aplica los flags de depuración leídos de oAppParams (appModoDebug y
// appModoDebugSQL) al log y al monitor SQL global. Idempotente: se puede
// invocar en arranque y cada vez que el usuario guarde los parámetros.
procedure AplicarModosDepuracion;

implementation

uses
  System.DateUtils, System.Generics.Defaults, inLibWin,
  inLibGlobalVar,                                // oMemoSQL para LogPerf
  inLibAppParam;                                 // oAppParams.GetBool

type
  TLogFileInfo = record
    Ruta: string;
    FechaLog: TDateTime;
    FechaOrden: TDateTime;
  end;

function CompararInfoLog(const AIzquierda, ADerecha: TLogFileInfo): Integer;
begin
  if AIzquierda.FechaOrden < ADerecha.FechaOrden then
    Result := -1
  else if AIzquierda.FechaOrden > ADerecha.FechaOrden then
    Result := 1
  else
    Result := CompareText(AIzquierda.Ruta, ADerecha.Ruta);
end;

{ TLog }

function TLog.LogTypeToString(ALogType: TLogType): string;
begin
  case ALogType of
    ltInfo: Result := 'INFO';
    ltWarning: Result := 'WARNING';
    ltError: Result := 'ERROR';
    ltSQL: Result := 'SQL';
    ltPerf: Result := 'PERF';
    ltAvanzado: Result := 'AVANZADO';
  else
    Result := 'DESCONOCIDO';
  end;
end;

function TLog.AcquireMutex: Boolean;
var
  WaitResult: DWORD;
begin
  WaitResult := WaitForSingleObject(FMutexHandle, MUTEX_TIMEOUT);
  Result := (WaitResult = WAIT_OBJECT_0) or
            (WaitResult = WAIT_ABANDONED);
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
  FLogFileName := TPath.Combine(GetLogFolder, 'LOG_' +
                                FormatDateTime('yyyy_mm_dd_hhnnss', Now) +
                                '_' + FInstanceID + '.log');
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
  WriteToLog('Inicio de sesión de log.', ltInfo);
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
  WriteToLog('Fin de sesión de log.', ltInfo);
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
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,
    0);
  Result := FileHandle <> INVALID_HANDLE_VALUE;
  if Result then
    CloseHandle(FileHandle);
end;

procedure TLog.WriteInitialInfo;
begin
  WriteToLogInternal('-------- Nuevo fichero de log --------');
  WriteToLogInternal('Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  WriteToLogInternal('Nombre del equipo: ' + GetComputerName);
  WriteToLogInternal('Usuario de Windows: ' + GetWindowsUserName);
  WriteToLogInternal('Versión de Windows: ' + GetWindowsVersion);
  WriteToLogInternal('Ruta del programa: ' + GetProgramPath);
  WriteToLogInternal('Carpeta de log: ' + GetLogFolder);
  WriteToLogInternal('Version de fzam: ' + inLibGlobalVar.oVersion);
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

procedure TLog.LogSQLExt(const ASQL: string; AElapsedMs: Int64; ARows: Integer;
                         AOk: Boolean; const AError: string = '';
                         const AParams: string = '');
var
  SQLOneLine, sEstado, sFilas, sLinea: string;
begin
  if not (ltSQL in FLogFlags) then
    Exit;

  SQLOneLine := StringReplace(ASQL, sLineBreak, ' ', [rfReplaceAll]);
  SQLOneLine := Trim(SQLOneLine);

  if AOk then
    sEstado := 'OK'
  else
    sEstado := 'ERR';

  if ARows >= 0 then
    sFilas := IntToStr(ARows)
  else
    sFilas := '-';

  sLinea := Format('SQL: [%s] %d ms | filas=%s | %s',
                   [sEstado, AElapsedMs, sFilas, SQLOneLine]);

  if AParams <> '' then
    sLinea := sLinea + ' | params=' + AParams;

  if not AOk and (AError <> '') then
    sLinea := sLinea + ' | error=' + AError;

  WriteToLog(sLinea, ltSQL);
end;

procedure TLog.LogEvento(const AUnidad, AObjeto, AEvento, ADetalle: string);
var
  sLinea: string;
begin
  if not (ltAvanzado in FLogFlags) then
    Exit;

  sLinea := Format('EVT: %s | %s | %s', [AUnidad, AObjeto, AEvento]);
  if ADetalle <> '' then
    sLinea := sLinea + ' | ' +
              StringReplace(ADetalle, sLineBreak, ' ', [rfReplaceAll]);

  WriteToLog(sLinea, ltAvanzado);
end;

procedure TLog.LogPerf(const ATag, ADetalle: string; AElapsedMs: Int64);
begin
  // Gateado por ltPerf: si appModoDebug está apagado, esta llamada es no-op.
  // Solo al archivo de log general — TLog.WriteToLog ya es thread-safe
  // (mutex interno). NO tocamos oMemoSQL: es un TcxMemo de DevExpress
  // y NO es thread-safe. Si necesitas ver las metricas junto al log
  // SQL en debug, abre el archivo de log LOG_yyyy_mm_dd_hhnnss_*.log
  // en paralelo.
  WriteToLog(Format('[PERF:%s] %s | %d ms',
                    [ATag, ADetalle, AElapsedMs]),
             ltPerf);
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

function TLog.FechaLogArchivo(const AFileName: string): TDateTime;
var
  sNombre: string;
  dFecha: TDateTime;
  function ProbarFecha(const ATexto: string; AAnioPrimero: Boolean;
                       out AFecha: TDateTime): Boolean;
  var
    iAnio: Integer;
    iMes: Integer;
    iDia: Integer;
    bFormato: Boolean;
  begin
    Result := False;
    if Length(ATexto) = 10 then
    begin
      if AAnioPrimero then
      begin
        bFormato := (ATexto[5] = '_') and (ATexto[8] = '_');
        if bFormato then
          bFormato := TryStrToInt(Copy(ATexto, 1, 4), iAnio) and
                      TryStrToInt(Copy(ATexto, 6, 2), iMes) and
                      TryStrToInt(Copy(ATexto, 9, 2), iDia);
      end
      else
      begin
        bFormato := (ATexto[3] = '_') and (ATexto[6] = '_');
        if bFormato then
          bFormato := TryStrToInt(Copy(ATexto, 1, 2), iDia) and
                      TryStrToInt(Copy(ATexto, 4, 2), iMes) and
                      TryStrToInt(Copy(ATexto, 7, 4), iAnio);
      end;
      if bFormato then
      begin
        try
          AFecha := EncodeDate(Word(iAnio), Word(iMes), Word(iDia));
          Result := True;
        except
          Result := False;
        end;
      end;
    end;
  end;
begin
  Result := Trunc(TFile.GetLastWriteTime(AFileName));
  sNombre := TPath.GetFileNameWithoutExtension(AFileName);
  if (Length(sNombre) >= 14) and
     SameText(Copy(sNombre, 1, 4), 'LOG_') then
  begin
    if ProbarFecha(Copy(sNombre, 5, 10), True, dFecha) then
      Result := dFecha
    else if Length(sNombre) >= 10 then
    begin
      if ProbarFecha(Copy(sNombre, Length(sNombre) - 9, 10), False,
                     dFecha) then
        Result := dFecha;
    end;
  end;
end;

function TLog.FechaOrdenArchivo(const AFileName: string): TDateTime;
var
  sNombre: string;
  sHora: string;
  iHora: Integer;
  iMinuto: Integer;
  iSegundo: Integer;
  dFecha: TDateTime;
  bHoraValida: Boolean;
begin
  dFecha := FechaLogArchivo(AFileName);
  Result := dFecha + Frac(TFile.GetLastWriteTime(AFileName));
  sNombre := TPath.GetFileNameWithoutExtension(AFileName);
  if (Length(sNombre) >= 21) and
     SameText(Copy(sNombre, 1, 4), 'LOG_') then
  begin
    sHora := Copy(sNombre, 16, 6);
    bHoraValida := TryStrToInt(Copy(sHora, 1, 2), iHora) and
                   TryStrToInt(Copy(sHora, 3, 2), iMinuto) and
                   TryStrToInt(Copy(sHora, 5, 2), iSegundo);
    if bHoraValida then
    begin
      if (iHora >= 0) and (iHora <= 23) and
         (iMinuto >= 0) and (iMinuto <= 59) and
         (iSegundo >= 0) and (iSegundo <= 59) then
        Result := dFecha + EncodeTime(Word(iHora), Word(iMinuto),
                                      Word(iSegundo), 0);
    end;
  end;
end;

function TLog.ClaveFechaLog(const AFecha: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', AFecha);
end;

function TLog.FechaZipAnterior(const AFileName: string;
                               out AFecha: TDateTime): Boolean;
var
  sNombre: string;
  sFecha: string;
  iAnio: Integer;
  iMes: Integer;
  iDia: Integer;
  bFormato: Boolean;
begin
  Result := False;
  sNombre := TPath.GetFileNameWithoutExtension(AFileName);
  if (Length(sNombre) >= 15) and
     SameText(Copy(sNombre, 1, 5), 'Logs_') then
  begin
    sFecha := Copy(sNombre, 6, 10);
    bFormato := (sFecha[5] = '-') and (sFecha[8] = '-');
    if bFormato then
      bFormato := TryStrToInt(Copy(sFecha, 1, 4), iAnio) and
                  TryStrToInt(Copy(sFecha, 6, 2), iMes) and
                  TryStrToInt(Copy(sFecha, 9, 2), iDia)
    else
    begin
      sFecha := Copy(sNombre, 6, 8);
      bFormato := TryStrToInt(Copy(sFecha, 1, 4), iAnio) and
                  TryStrToInt(Copy(sFecha, 5, 2), iMes) and
                  TryStrToInt(Copy(sFecha, 7, 2), iDia);
    end;
    if bFormato then
    begin
      try
        AFecha := EncodeDate(Word(iAnio), Word(iMes), Word(iDia));
        Result := True;
      except
        Result := False;
      end;
    end;
  end;
end;

procedure TLog.ConsolidarZipAnterior(const AZipAnterior: string;
                                     const AFechaLog: TDateTime);
var
  ArchiveFolder: string;
  ZipFileName: string;
  EntradaZip: string;
  ZipAnterior: TZipFile;
  ZipDiario: TZipFile;
  Datos: TBytes;
  I: Integer;
  bAnteriorAbierto: Boolean;
  bDiarioAbierto: Boolean;
  bCompletado: Boolean;
begin
  ArchiveFolder := TPath.Combine(GetLogFolder, 'archive');
  ArchiveFolder := TPath.Combine(ArchiveFolder,
                                 FormatDateTime('yyyy', AFechaLog));
  ArchiveFolder := TPath.Combine(ArchiveFolder,
                                 FormatDateTime('mm', AFechaLog));
  if not TDirectory.Exists(ArchiveFolder) then
    TDirectory.CreateDirectory(ArchiveFolder);
  ZipFileName := TPath.Combine(ArchiveFolder,
                               'Logs_' + ClaveFechaLog(AFechaLog) + '.zip');
  if not TZipFile.IsValid(AZipAnterior) then
    WriteToLog('WARNING: ZIP de logs anterior no válido: ' + AZipAnterior,
               ltWarning)
  else if not TFile.Exists(ZipFileName) then
    TFile.Move(AZipAnterior, ZipFileName)
  else
  begin
    ZipAnterior := nil;
    ZipDiario := nil;
    bAnteriorAbierto := False;
    bDiarioAbierto := False;
    bCompletado := True;
    try
      ZipAnterior := TZipFile.Create;
      ZipDiario := TZipFile.Create;
      ZipAnterior.Open(AZipAnterior, zmRead);
      bAnteriorAbierto := True;
      ZipDiario.Open(ZipFileName, zmReadWrite);
      bDiarioAbierto := True;
      for I := 0 to ZipAnterior.FileCount - 1 do
      begin
        EntradaZip := ZipAnterior.FileName[I];
        if ZipDiario.IndexOf(EntradaZip) < 0 then
        begin
          try
            ZipAnterior.Read(I, Datos);
            ZipDiario.Add(Datos, EntradaZip);
          except
            on E: Exception do
            begin
              bCompletado := False;
              WriteToLog('WARNING: No se pudo consolidar ' + EntradaZip +
                         ' desde ' + AZipAnterior + ': ' + E.Message,
                         ltWarning);
            end;
          end;
        end;
      end;
      ZipDiario.Close;
      bDiarioAbierto := False;
      ZipAnterior.Close;
      bAnteriorAbierto := False;
      if bCompletado then
        TFile.Delete(AZipAnterior);
    finally
      if bDiarioAbierto then
        ZipDiario.Close;
      if bAnteriorAbierto then
        ZipAnterior.Close;
      FreeAndNil(ZipDiario);
      FreeAndNil(ZipAnterior);
    end;
  end;
end;

procedure TLog.MigrarZipsAnteriores;
var
  ArchiveFolder: string;
  ZipFiles: TArray<string>;
  dFechaLog: TDateTime;
  I: Integer;
begin
  ArchiveFolder := TPath.Combine(GetLogFolder, 'archive');
  ZipFiles := TDirectory.GetFiles(ArchiveFolder, 'Logs_*.zip',
                                  TSearchOption.soTopDirectoryOnly);
  for I := 0 to Length(ZipFiles) - 1 do
  begin
    try
      if FechaZipAnterior(ZipFiles[I], dFechaLog) then
        ConsolidarZipAnterior(ZipFiles[I], dFechaLog)
      else
        WriteToLog('WARNING: No se reconoce la fecha del ZIP de logs: ' +
                   ZipFiles[I], ltWarning);
    except
      on E: Exception do
        WriteToLog('WARNING: No se pudo migrar el ZIP de logs ' + ZipFiles[I] +
                   ': ' + E.Message, ltWarning);
    end;
  end;
end;

procedure TLog.ArchivarGrupoLogs(const AArchivos: TList<string>;
                                 const AFechaLog: TDateTime);
var
  ArchiveFolder: string;
  ZipFileName: string;
  EntradaZip: string;
  Zip: TZipFile;
  ArchivosParaBorrar: TList<string>;
  I: Integer;
  bZipAbierto: Boolean;
begin
  if AArchivos.Count > 0 then
  begin
    ArchiveFolder := TPath.Combine(GetLogFolder, 'archive');
    ArchiveFolder := TPath.Combine(ArchiveFolder,
                                   FormatDateTime('yyyy', AFechaLog));
    ArchiveFolder := TPath.Combine(ArchiveFolder,
                                   FormatDateTime('mm', AFechaLog));
    if not TDirectory.Exists(ArchiveFolder) then
      TDirectory.CreateDirectory(ArchiveFolder);
    ZipFileName := TPath.Combine(ArchiveFolder,
                                 'Logs_' + ClaveFechaLog(AFechaLog) + '.zip');
    Zip := TZipFile.Create;
    ArchivosParaBorrar := TList<string>.Create;
    bZipAbierto := False;
    try
      if TFile.Exists(ZipFileName) then
        Zip.Open(ZipFileName, zmReadWrite)
      else
        Zip.Open(ZipFileName, zmWrite);
      bZipAbierto := True;
      for I := 0 to AArchivos.Count - 1 do
      begin
        EntradaZip := ExtractFileName(AArchivos[I]);
        try
          if Zip.IndexOf(EntradaZip) < 0 then
            Zip.Add(AArchivos[I], EntradaZip);
          ArchivosParaBorrar.Add(AArchivos[I]);
        except
          on E: Exception do
            WriteToLog('WARNING: No se pudo archivar ' + AArchivos[I] +
                       ': ' + E.Message, ltWarning);
        end;
      end;
      Zip.Close;
      bZipAbierto := False;
      for I := 0 to ArchivosParaBorrar.Count - 1 do
      begin
        try
          if TFile.Exists(ArchivosParaBorrar[I]) then
            TFile.Delete(ArchivosParaBorrar[I]);
        except
          on E: Exception do
            WriteToLog('WARNING: Log archivado pero no borrado ' +
                       ArchivosParaBorrar[I] + ': ' + E.Message, ltWarning);
        end;
      end;
    finally
      if bZipAbierto then
        Zip.Close;
      FreeAndNil(ArchivosParaBorrar);
      FreeAndNil(Zip);
    end;
  end;
end;

procedure TLog.RotateLogs;
var
  LogFiles: TArray<string>;
  ArchiveFolder: string;
  InfoFiles: TList<TLogFileInfo>;
  Grupo: TList<string>;
  Info: TLogFileInfo;
  I: Integer;
  iRetencion: Integer;
  iArchivar: Integer;
  dFechaGrupo: TDateTime;
  bHayGrupo: Boolean;
begin
  if AcquireMutex then
  try
    try
      ArchiveFolder := TPath.Combine(GetLogFolder, 'archive');
      if not TDirectory.Exists(ArchiveFolder) then
        TDirectory.CreateDirectory(ArchiveFolder);
      MigrarZipsAnteriores;
      LogFiles := TDirectory.GetFiles(GetLogFolder, '*.log');
      iRetencion := FLogRetention;
      if iRetencion < 1 then
        iRetencion := 1;
      iArchivar := Length(LogFiles) - iRetencion;
      if iArchivar > 0 then
      begin
        InfoFiles := TList<TLogFileInfo>.Create;
        try
          for I := 0 to Length(LogFiles) - 1 do
          begin
            if not SameText(ExpandFileName(LogFiles[I]),
                            ExpandFileName(FLogFileName)) then
            begin
              Info.Ruta := LogFiles[I];
              Info.FechaLog := FechaLogArchivo(LogFiles[I]);
              Info.FechaOrden := FechaOrdenArchivo(LogFiles[I]);
              InfoFiles.Add(Info);
            end;
          end;
          InfoFiles.Sort(TComparer<TLogFileInfo>.Construct(
            function(const AIzquierda, ADerecha: TLogFileInfo): Integer
            begin
              Result := CompararInfoLog(AIzquierda, ADerecha);
            end));
          if iArchivar > InfoFiles.Count then
            iArchivar := InfoFiles.Count;
          if iArchivar > 0 then
          begin
            Grupo := TList<string>.Create;
            try
              bHayGrupo := False;
              dFechaGrupo := 0;
              for I := 0 to iArchivar - 1 do
              begin
                Info := InfoFiles[I];
                if (not bHayGrupo) or
                   (Trunc(Info.FechaLog) <> Trunc(dFechaGrupo)) then
                begin
                  if bHayGrupo then
                  begin
                    ArchivarGrupoLogs(Grupo, dFechaGrupo);
                    Grupo.Clear;
                  end;
                  dFechaGrupo := Trunc(Info.FechaLog);
                  bHayGrupo := True;
                end;
                Grupo.Add(Info.Ruta);
              end;
              if bHayGrupo then
                ArchivarGrupoLogs(Grupo, dFechaGrupo);
            finally
              FreeAndNil(Grupo);
            end;
          end;
        finally
          FreeAndNil(InfoFiles);
        end;
      end;
    except
      on E: Exception do
        WriteToLog('WARNING: Error rotando logs: ' + E.Message, ltWarning);
    end;
  finally
    ReleaseMutex;
  end;
end;

procedure TLog.WriteToLog(const AMessage: string; ALogType: TLogType);
begin
  if (ALogType in FLogFlags) then
  begin
   WriteToLogInternal(Format('%s - %s', [AMessage, LogTypeToString(ALogType)]));
  end;
end;

procedure AplicarModosDepuracion;
var
  bDebug      : Boolean;
  bDebugSQL   : Boolean;
  bLogSQL     : Boolean;
  bLogAvanzado: Boolean;
  bSQLFinal   : Boolean;
begin
  if not Assigned(oAppParams) then Exit;
  // Flags 'Depuración' (modest-fermat-WUvkF): switches gordos.
  bDebug    := oAppParams.GetBool('appModoDebug',    False);
  bDebugSQL := oAppParams.GetBool('appModoDebugSQL', False) or bDebug;
  // Flags 'Log' (great-wright-Xs8yZ): controles finos por tipo.
  bLogSQL      := oAppParams.GetBool('appLogSQL',      False);
  bLogAvanzado := oAppParams.GetBool('appLogAvanzado', False);

  // ltSQL se enciende si CUALQUIERA de los modos relacionados con SQL
  // está activo. El cronómetro de UniSQLMonitor (LogSQLExt) y el dump
  // crudo (LogSQL) comparten el mismo flag.
  bSQLFinal := bDebugSQL or bLogSQL;
  {$IFDEF DEBUG}
  // En compilaciones DEBUG forzamos siempre el modo SQL
  bSQLFinal := True;
  {$ENDIF}

  if bSQLFinal then
    Log.EnableLogType(ltSQL)
  else
    Log.DisableLogType(ltSQL);

  // Cronómetros LogPerf enganchados al modo debug general.
  if bDebug then
    Log.EnableLogType(ltPerf)
  else
    Log.DisableLogType(ltPerf);

  // Eventos de UI (LogEvento) controlados por su propio flag.
  if bLogAvanzado then
    Log.EnableLogType(ltAvanzado)
  else
    Log.DisableLogType(ltAvanzado);

  if Assigned(odmConn) and Assigned(odmConn.UniSQLMonitor1) then
    odmConn.UniSQLMonitor1.Active := bSQLFinal;

  // El memo SQL en pantalla acompaña al modo: si se activa SQL, se muestra;
  // si se desactiva, se oculta junto con su panel contenedor.
  if Assigned(oMemoSQL) then
  begin
    oMemoSQL.Visible := bSQLFinal;
    if Assigned(oMemoSQL.Parent) then
      oMemoSQL.Parent.Visible := bSQLFinal;
  end;

  Log.LogInfo(Format(
    'Modos log aplicados: appModoDebug=%s, appModoDebugSQL=%s, ' +
    'appLogSQL=%s, appLogAvanzado=%s',
    [BoolToStr(bDebug,        True),
     BoolToStr(bDebugSQL,     True),
     BoolToStr(bLogSQL,       True),
     BoolToStr(bLogAvanzado,  True)]));
end;

initialization
  Log := TLog.Create;
finalization
  FreeAndNil(Log);
end.
