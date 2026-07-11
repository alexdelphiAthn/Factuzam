{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBackupWorker                                             }
{    Tipo:       Librería (Lib)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Hilos para ejecutar copia de seguridad y restauración en segundo plano.   }
{    Cada worker crea su propia conexión a BBDD (thread-safe).                 }
{    Reporta progreso vía Synchronize y finalización vía Queue.                }
{******************************************************************************}
unit inLibBackupWorker;

interface

uses
  System.Classes, System.SysUtils, System.Diagnostics,
  Backup.Engine, Backup.Types, DAScript, Uni;

type
  TWorkerProgresoEvent = procedure(const AEtapa: string;
                                    APaso, ATotal: Integer;
                                    AFilaGlobal,
                                    AFilasGlobalTotal: Integer) of object;
  TWorkerFinalizarEvent = procedure(AExito: Boolean;
                                     const AError: string;
                                     ALogBuffer: TStringList) of object;

  TBackupWorker = class(TThread)
  private
    FHost: string;
    FPort: Integer;
    FDatabase: string;
    FUser: string;
    FPassword: string;
    FRutaFichero: string;
    FEncriptar: Boolean;
    FPassEncriptar: AnsiString;
    FExito: Boolean;
    FError: string;
    FProgresoEtapa: string;
    FProgresoPaso: Integer;
    FProgresoTotal: Integer;
    FProgresoFilaGlobal: Integer;
    FProgresoFilasGlobalTotal: Integer;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    procedure EngineProgress(const AEtapa: string;
                              APaso, ATotal: Integer;
                              AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(const AHost: string; APort: Integer;
                       const ADatabase, AUser, APassword: string;
                       const ARutaFichero: string;
                       AEncriptar: Boolean;
                       const APassEncriptar: AnsiString);
    property OnProgreso: TWorkerProgresoEvent
      read FOnProgreso write FOnProgreso;
    property OnFinalizar: TWorkerFinalizarEvent
      read FOnFinalizar write FOnFinalizar;
  end;

  TRestoreWorker = class(TThread)
  private
    FHost: string;
    FPort: Integer;
    FDatabase: string;
    FUser: string;
    FPassword: string;
    FRutaFichero: string;
    FDesencriptar: Boolean;
    FPassDesencriptar: AnsiString;
    FExito: Boolean;
    FError: string;
    FLogBuffer: TStringList;
    FStopwatch: TStopwatch;
    FErrores: Integer;
    FPosicion: Integer;
    FTotal: Integer;
    FSentenciasEjecutadas: Integer;
    FColacionesNormalizadas: Boolean;
    FProgresoEtapa: string;
    FPrimerError: string;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    procedure ActualizarProgresoFichero(AFichero: TFileStream);
    procedure EjecutarSQLStreaming(AConn: TUniConnection);
    procedure NormalizarColacionesRestauracion(AConn: TUniConnection);
    procedure ValidarEstructuraRestaurada(AConn: TUniConnection);
    function NombreBBDDSQL(const ANombre: string): string;
    function EsCreacionVista(const ASQL: string): Boolean;
    procedure ScriptBeforeExecute(Sender: TObject;
                                   var SQL: string;
                                   var Omit: Boolean);
    procedure ScriptAfterExecute(Sender: TObject; SQL: string);
    procedure ScriptError(Sender: TObject; E: Exception;
                           SQL: string; var Action: TErrorAction);
    procedure ComprobarCancelacion;
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(const AHost: string; APort: Integer;
                       const ADatabase, AUser, APassword: string;
                       const ARutaFichero: string;
                       const APassDesencriptar: AnsiString;
                       ADesencriptar: Boolean = False);
    property OnProgreso: TWorkerProgresoEvent
      read FOnProgreso write FOnProgreso;
    property OnFinalizar: TWorkerFinalizarEvent
      read FOnFinalizar write FOnFinalizar;
  end;

function CrearCopiaSeguridadBD(const AHost: string; APort: Integer;
                               const ADatabase, AUser, APassword: string;
                               const ARutaFichero: string;
                               AEncriptar: Boolean;
                               const APassEncriptar: AnsiString;
                               AOnProgreso: TWorkerProgresoEvent;
                               out AError: string): Boolean;

implementation

uses
  Core_Interfaces, Core_Helpers,
  Providers_MySQL, Providers_MySQL_Helpers, ScriptWriters,
  MySQLUniProvider, UniScript,
  System.StrUtils,
  inLibDBStructure,
  inLibtb;

const
  SOperacionCancelada = 'Operación cancelada por el usuario.';

function CrearCopiaSeguridadBD(const AHost: string; APort: Integer;
                               const ADatabase, AUser, APassword: string;
                               const ARutaFichero: string;
                               AEncriptar: Boolean;
                               const APassEncriptar: AnsiString;
                               AOnProgreso: TWorkerProgresoEvent;
                               out AError: string): Boolean;
var
  Conn: TUniConnection;
  Options: TBackupOptions;
  Provider: IDBMetadataProvider;
  Helpers: IDBHelpers;
  Writer: IScriptWriter;
  Engine: TDBBackupEngine;
  IncludeTables: TStringList;
  ExcludeTables: TStringList;
  s: string;
  MyText: TStringList;
begin
  AError := '';
  Conn := TUniConnection.Create(nil);
  try
    try
      Conn.ProviderName := 'MySQL';
      Conn.Server := AHost;
      Conn.Port := APort;
      Conn.Database := ADatabase;
      Conn.Username := AUser;
      Conn.Password := APassword;
      Conn.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
      Conn.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
      Conn.LoginPrompt := False;
      Conn.Connected := True;
      Conn.ExecSQL('SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
      Options.WithData := True;
      Options.WithTriggers := True;
      Options.WithProcedures := True;
      Options.WithFunctions := True;
      Options.WithViews := True;
      Options.DropTablesFirst := True;
      Options.UseTransactions := True;
      Options.ExtendedInsert := True;
      Options.ExtendedInsertRows := 500;
      IncludeTables := TStringList.Create;
      ExcludeTables := TStringList.Create;
      try
        Provider := TMySQLMetadataProvider.Create(Conn, ADatabase);
        Helpers := TMySQLHelpers.Create;
        if AEncriptar then
          Writer := TScriptWriter.Create('')
        else
          Writer := TScriptWriter.Create(ARutaFichero);
        Engine := TDBBackupEngine.Create(Provider, Writer, Helpers,
                                         Options,
                                         IncludeTables, ExcludeTables);
        try
          Engine.OnProgress := AOnProgreso;
          Engine.GenerateBackup;
          if AEncriptar then
          begin
            s := Writer.GetScript;
            s := StringReplace(s, 'DEFINER=`root`@`localhost`', '',
                               [rfReplaceAll, rfIgnoreCase]);
            s := EncriptAESPass(s, APassEncriptar);
            MyText := TStringList.Create;
            try
              MyText.Text := s;
              MyText.SaveToFile(ARutaFichero);
            finally
              FreeAndNil(MyText);
            end;
          end;
          Result := True;
        finally
          FreeAndNil(Engine);
        end;
      finally
        FreeAndNil(IncludeTables);
        FreeAndNil(ExcludeTables);
      end;
    except
      on E: Exception do
      begin
        if E is EAbort then
          AError := E.Message
        else
          AError := E.ClassName + ': ' + E.Message;
        Result := False;
      end;
    end;
  finally
    Conn.Free;
  end;
end;

{ TBackupWorker }

constructor TBackupWorker.Create(const AHost: string; APort: Integer;
  const ADatabase, AUser, APassword, ARutaFichero: string;
  AEncriptar: Boolean; const APassEncriptar: AnsiString);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FHost := AHost;
  FPort := APort;
  FDatabase := ADatabase;
  FUser := AUser;
  FPassword := APassword;
  FRutaFichero := ARutaFichero;
  FEncriptar := AEncriptar;
  FPassEncriptar := APassEncriptar;
  FExito := False;
end;

procedure TBackupWorker.EngineProgress(const AEtapa: string;
  APaso, ATotal, AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if Terminated then
    raise EAbort.Create(SOperacionCancelada)
  else
  begin
    FProgresoEtapa := AEtapa;
    FProgresoPaso := APaso;
    FProgresoTotal := ATotal;
    FProgresoFilaGlobal := AFilaGlobal;
    FProgresoFilasGlobalTotal := AFilasGlobalTotal;
    Synchronize(SyncProgreso);
  end;
end;

procedure TBackupWorker.SyncProgreso;
begin
  if Assigned(FOnProgreso) then
    FOnProgreso(FProgresoEtapa, FProgresoPaso, FProgresoTotal,
                FProgresoFilaGlobal, FProgresoFilasGlobalTotal);
end;

procedure TBackupWorker.SyncFinalizar;
begin
  if Assigned(FOnFinalizar) then
    FOnFinalizar(FExito, FError, nil);
end;

procedure TBackupWorker.Execute;
begin
  try
    FExito := CrearCopiaSeguridadBD(
      FHost,
      FPort,
      FDatabase,
      FUser,
      FPassword,
      FRutaFichero,
      FEncriptar,
      FPassEncriptar,
      EngineProgress,
      FError);
  finally
    Synchronize(SyncFinalizar);
  end;
end;

{ TRestoreWorker }

constructor TRestoreWorker.Create(const AHost: string; APort: Integer;
  const ADatabase, AUser, APassword, ARutaFichero: string;
  const APassDesencriptar: AnsiString; ADesencriptar: Boolean);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FHost := AHost;
  FPort := APort;
  FDatabase := ADatabase;
  FUser := AUser;
  FPassword := APassword;
  FRutaFichero := ARutaFichero;
  FDesencriptar := ADesencriptar;
  FPassDesencriptar := APassDesencriptar;
  FExito := False;
  FErrores := 0;
  FPosicion := 0;
  FTotal := 0;
  FSentenciasEjecutadas := 0;
  FColacionesNormalizadas := False;
  FProgresoEtapa := 'Restaurando';
  FPrimerError := '';
  FLogBuffer := TStringList.Create;
end;

procedure TRestoreWorker.ComprobarCancelacion;
begin
  if Terminated then
    raise EAbort.Create(SOperacionCancelada);
end;

function TRestoreWorker.EsCreacionVista(const ASQL: string): Boolean;
var
  sSQLNorm: string;
begin
  sSQLNorm := UpperCase(ASQL);
  sSQLNorm := StringReplace(sSQLNorm, #13, ' ', [rfReplaceAll]);
  sSQLNorm := StringReplace(sSQLNorm, #10, ' ', [rfReplaceAll]);
  Result := (Pos('CREATE ', sSQLNorm) > 0) and
            (Pos(' VIEW ', sSQLNorm) > 0);
end;

procedure TRestoreWorker.NormalizarColacionesRestauracion(
  AConn: TUniConnection);
var
  Q: TUniQuery;
  Tablas: TStringList;
  i: Integer;
begin
  if not FColacionesNormalizadas then
  begin
    FLogBuffer.Add(' -- Normalizando colaciones antes de crear vistas');
    AConn.ExecSQL(Format(
      'ALTER DATABASE %s CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci',
      [NombreBBDDSQL(FDatabase)]));
    Tablas := TStringList.Create;
    try
      Q := TUniQuery.Create(nil);
      try
        Q.Connection := AConn;
        Q.SQL.Text :=
          'SELECT DISTINCT T.TABLE_NAME ' +
          '  FROM INFORMATION_SCHEMA.TABLES T ' +
          ' WHERE T.TABLE_SCHEMA = DATABASE() ' +
          '   AND T.TABLE_TYPE = ''BASE TABLE'' ' +
          '   AND ( ' +
          '       (T.TABLE_COLLATION IS NOT NULL ' +
          '        AND T.TABLE_COLLATION <> ''utf8mb4_spanish_ci'') ' +
          '        OR EXISTS ( ' +
          '          SELECT 1 ' +
          '            FROM INFORMATION_SCHEMA.COLUMNS C ' +
          '           WHERE C.TABLE_SCHEMA = T.TABLE_SCHEMA ' +
          '             AND C.TABLE_NAME = T.TABLE_NAME ' +
          '             AND C.CHARACTER_SET_NAME IS NOT NULL ' +
          '             AND (C.CHARACTER_SET_NAME <> ''utf8mb4'' ' +
          '                  OR C.COLLATION_NAME <> ' +
          '                     ''utf8mb4_spanish_ci'') ' +
          '        ) ' +
          '       ) ' +
          ' ORDER BY T.TABLE_NAME';
        Q.Open;
        while not Q.Eof do
        begin
          Tablas.Add(Q.FieldByName('TABLE_NAME').AsString);
          Q.Next;
        end;
      finally
        FreeAndNil(Q);
      end;
      for i := 0 to Tablas.Count - 1 do
      begin
        ComprobarCancelacion;
        AConn.ExecSQL(
          'ALTER TABLE ' + NombreBBDDSQL(Tablas[i]) +
          ' CONVERT TO CHARACTER SET utf8mb4 ' +
          'COLLATE utf8mb4_spanish_ci');
      end;
      if Tablas.Count > 0 then
      begin
        FLogBuffer.Add(Format(' -- Tablas normalizadas: %d',
                              [Tablas.Count]));
      end;
    finally
      FreeAndNil(Tablas);
    end;
    FColacionesNormalizadas := True;
  end;
end;

procedure TRestoreWorker.ScriptBeforeExecute(Sender: TObject;
  var SQL: string; var Omit: Boolean);
begin
  ComprobarCancelacion;
  if EsCreacionVista(SQL) then
    NormalizarColacionesRestauracion((Sender as TUniScript).Connection);
  FLogBuffer.Add(' -- Ejecutando (' +
                  FormatDateTime('hh:nn:ss.zzz', Now) + '): ');
  FLogBuffer.Add(SQL);
  FStopwatch := TStopwatch.StartNew;
end;

procedure TRestoreWorker.ScriptAfterExecute(Sender: TObject; SQL: string);
begin
  FStopwatch.Stop;
  FLogBuffer.Add(
    Format(' -- [OK] Filas afectadas: %d | Tiempo: %d ms',
           [(Sender as TUniScript).RowsAffected,
           FStopwatch.ElapsedMilliseconds]));
  FLogBuffer.Add('--------------------------------------------------');
  Inc(FSentenciasEjecutadas);
  Inc(FPosicion);
  if (FPosicion mod 20) = 0 then
    Synchronize(SyncProgreso);
  ComprobarCancelacion;
end;

procedure TRestoreWorker.ScriptError(Sender: TObject; E: Exception;
  SQL: string; var Action: TErrorAction);
begin
  FStopwatch.Stop;
  Inc(FErrores);
  if FPrimerError = '' then
    FPrimerError := E.Message;
  FLogBuffer.Add(Format(' -- [ERROR] %s | Tiempo: %d ms',
                          [E.Message, FStopwatch.ElapsedMilliseconds]));
  FLogBuffer.Add('--------------------------------------------------');
  Action := eaFail;
end;

procedure TRestoreWorker.ActualizarProgresoFichero(AFichero: TFileStream);
begin
  if AFichero.Size > 0 then
    FTotal := Integer(AFichero.Size div 1024)
  else
    FTotal := 0;
  if FTotal <= 0 then
    FTotal := 1;
  FPosicion := Integer(AFichero.Position div 1024);
  if FPosicion > FTotal then
    FPosicion := FTotal;
end;

procedure TRestoreWorker.EjecutarSQLStreaming(AConn: TUniConnection);
const
  BYTES_ENTRE_PROGRESO = 4 * 1024 * 1024;
var
  Fichero: TFileStream;
  Lector: TStreamReader;
  Sentencia: TStringBuilder;
  sLinea: string;
  sDelimitador: string;
  sNuevoDelimitador: string;
  sSQL: string;
  sResumen: string;
  bEnCadena: Boolean;
  bEnComentarioBloque: Boolean;
  cCadena: Char;
  iSentencia: Integer;
  nUltimaPosicion: Int64;

  function EsLineaIgnorable(const ALinea: string): Boolean;
  var
    sTrim: string;
  begin
    sTrim := Trim(ALinea);
    Result := (sTrim = '') or StartsText('--', sTrim) or
              StartsText('#', sTrim);
  end;

  function EsDirectivaDelimitador(const ALinea: string;
                                  out ADelimitador: string): Boolean;
  const
    DIRECTIVA = 'DELIMITER';
  var
    sTrim: string;
  begin
    Result := False;
    ADelimitador := '';
    sTrim := Trim(ALinea);
    if Length(sTrim) >= Length(DIRECTIVA) then
    begin
      if SameText(Copy(sTrim, 1, Length(DIRECTIVA)), DIRECTIVA) then
      begin
        if Length(sTrim) = Length(DIRECTIVA) then
          Result := True
        else
          Result := CharInSet(sTrim[Length(DIRECTIVA) + 1], [' ', #9]);
        if Result then
        begin
          ADelimitador := Trim(Copy(sTrim, Length(DIRECTIVA) + 1, MaxInt));
          if ADelimitador = '' then
            ADelimitador := ';';
        end;
      end;
    end;
  end;

  function EsComentarioLinea(const ALinea: string; AIndice: Integer): Boolean;
  var
    bGuion: Boolean;
  begin
    Result := False;
    bGuion := (AIndice < Length(ALinea)) and
              (ALinea[AIndice] = '-') and (ALinea[AIndice + 1] = '-');
    if bGuion then
    begin
      if AIndice + 1 = Length(ALinea) then
        Result := True
      else
        Result := CharInSet(ALinea[AIndice + 2], [' ', #9, #13, #10]);
    end;
    if not Result then
      Result := ALinea[AIndice] = '#';
  end;

  procedure EjecutarSentenciaActual;
  var
    Reloj: TStopwatch;
  begin
    sSQL := Trim(Sentencia.ToString);
    Sentencia.Clear;
    if sSQL <> '' then
    begin
      ComprobarCancelacion;
      Inc(iSentencia);
      FSentenciasEjecutadas := iSentencia;
      Reloj := TStopwatch.StartNew;
      try
        if EsCreacionVista(sSQL) then
          NormalizarColacionesRestauracion(AConn);
        AConn.ExecSQL(sSQL);
        Reloj.Stop;
        if (iSentencia mod 250) = 0 then
        begin
          FLogBuffer.Add(Format(
            ' -- [OK] Sentencias ejecutadas: %d | %d / %d KB',
            [iSentencia, FPosicion, FTotal]));
        end;
      except
        on E: Exception do
        begin
          Reloj.Stop;
          Inc(FErrores);
          if FPrimerError = '' then
            FPrimerError := E.Message;
          sResumen := sSQL;
          if Length(sResumen) > 4000 then
          begin
            sResumen := Copy(sResumen, 1, 4000) + sLineBreak + '...';
          end;
          FLogBuffer.Add(Format(
            ' -- [ERROR] Sentencia %d: %s | Tiempo: %d ms',
            [iSentencia, E.Message, Reloj.ElapsedMilliseconds]));
          FLogBuffer.Add(sResumen);
          FLogBuffer.Add('--------------------------------------------------');
          raise;
        end;
      end;
      ComprobarCancelacion;
    end;
  end;

  function CoincideDelimitador(const ALinea: string;
                               AIndice: Integer): Boolean;
  begin
    Result := (sDelimitador <> '') and
              (Copy(ALinea, AIndice, Length(sDelimitador)) =
               sDelimitador);
  end;

  procedure ProcesarLineaSQL(const ALinea: string);
  var
    i: Integer;
    sResto: string;
  begin
    i := 1;
    while i <= Length(ALinea) do
    begin
      if bEnComentarioBloque then
      begin
        Sentencia.Append(ALinea[i]);
        if (ALinea[i] = '*') and (i < Length(ALinea)) and
           (ALinea[i + 1] = '/') then
        begin
          Sentencia.Append(ALinea[i + 1]);
          bEnComentarioBloque := False;
          Inc(i, 2);
        end
        else
          Inc(i);
      end
      else if bEnCadena then
      begin
        Sentencia.Append(ALinea[i]);
        if ALinea[i] = '\' then
        begin
          if i < Length(ALinea) then
          begin
            Sentencia.Append(ALinea[i + 1]);
            Inc(i, 2);
          end
          else
            Inc(i);
        end
        else if ALinea[i] = cCadena then
        begin
          if (i < Length(ALinea)) and (ALinea[i + 1] = cCadena) then
          begin
            Sentencia.Append(ALinea[i + 1]);
            Inc(i, 2);
          end
          else
          begin
            bEnCadena := False;
            Inc(i);
          end;
        end
        else
          Inc(i);
      end
      else if CoincideDelimitador(ALinea, i) then
      begin
        EjecutarSentenciaActual;
        Inc(i, Length(sDelimitador));
        sResto := Trim(Copy(ALinea, i, MaxInt));
        if (sResto = '') or StartsText('--', sResto) or
           StartsText('#', sResto) then
          Break;
      end
      else if (ALinea[i] = '/') and (i < Length(ALinea)) and
              (ALinea[i + 1] = '*') then
      begin
        Sentencia.Append(ALinea[i]);
        Sentencia.Append(ALinea[i + 1]);
        bEnComentarioBloque := True;
        Inc(i, 2);
      end
      else if EsComentarioLinea(ALinea, i) then
      begin
        Sentencia.Append(Copy(ALinea, i, MaxInt));
        Break;
      end
      else if CharInSet(ALinea[i], ['''', '"', '`']) then
      begin
        cCadena := ALinea[i];
        bEnCadena := True;
        Sentencia.Append(ALinea[i]);
        Inc(i);
      end
      else
      begin
        Sentencia.Append(ALinea[i]);
        Inc(i);
      end;
    end;
    if Sentencia.Length > 0 then
      Sentencia.AppendLine;
  end;

begin
  FProgresoEtapa := 'Restaurando SQL (KB)';
  Fichero := TFileStream.Create(FRutaFichero, fmOpenRead or fmShareDenyWrite);
  try
    Lector := TStreamReader.Create(Fichero, TEncoding.UTF8, True);
    try
      Sentencia := TStringBuilder.Create;
      try
        sDelimitador := ';';
        bEnCadena := False;
        bEnComentarioBloque := False;
        cCadena := #0;
        iSentencia := 0;
        nUltimaPosicion := 0;
        ActualizarProgresoFichero(Fichero);
        Synchronize(SyncProgreso);
        while not Lector.EndOfStream do
        begin
          ComprobarCancelacion;
          sLinea := Lector.ReadLine;
          if (Sentencia.Length = 0) and
             (not bEnCadena) and
             (not bEnComentarioBloque) and
             EsDirectivaDelimitador(sLinea, sNuevoDelimitador) then
          begin
            sDelimitador := sNuevoDelimitador;
          end
          else
          begin
            if not ((Sentencia.Length = 0) and EsLineaIgnorable(sLinea)) then
              ProcesarLineaSQL(sLinea);
          end;
          if Fichero.Position - nUltimaPosicion >= BYTES_ENTRE_PROGRESO then
          begin
            ActualizarProgresoFichero(Fichero);
            Synchronize(SyncProgreso);
            nUltimaPosicion := Fichero.Position;
          end;
        end;
        ComprobarCancelacion;
        if Trim(Sentencia.ToString) <> '' then
          EjecutarSentenciaActual;
        ActualizarProgresoFichero(Fichero);
        FPosicion := FTotal;
        Synchronize(SyncProgreso);
        FLogBuffer.Add(Format(' -- Restauración SQL completada. ' +
                              'Sentencias ejecutadas: %d',
                              [FSentenciasEjecutadas]));
      finally
        FreeAndNil(Sentencia);
      end;
    finally
      FreeAndNil(Lector);
    end;
  finally
    FreeAndNil(Fichero);
  end;
end;

procedure TRestoreWorker.ValidarEstructuraRestaurada(AConn: TUniConnection);
var
  CheckResult: TDBStructureCheckResult;
begin
  CheckResult := TDBStructureChecker.Check(AConn, FDatabase);
  if not CheckResult.IsOK then
  begin
    raise Exception.Create('La restauración terminó, pero la estructura ' +
                           'mínima no está completa.' + sLineBreak +
                           CheckResult.FormattedMessage);
  end;
end;

function TRestoreWorker.NombreBBDDSQL(const ANombre: string): string;
var
  sNombre: string;
begin
  sNombre := StringReplace(ANombre, '`', '``', [rfReplaceAll]);
  Result := '`' + sNombre + '`';
end;

procedure TRestoreWorker.SyncProgreso;
var
  sEtapa: string;
begin
  sEtapa := FProgresoEtapa;
  if sEtapa = '' then
    sEtapa := 'Restaurando';
  if Assigned(FOnProgreso) then
    FOnProgreso(sEtapa, FPosicion, FTotal, FPosicion, FTotal);
end;

procedure TRestoreWorker.SyncFinalizar;
begin
  if Assigned(FOnFinalizar) then
    FOnFinalizar(FExito, FError, FLogBuffer)
  else
    FreeAndNil(FLogBuffer);
end;

procedure TRestoreWorker.Execute;
var
  Conn: TUniConnection;
  SqlScript: TUniScript;
  MyText: TStringList;
  s: string;
  i: Integer;
  Linea: string;
begin
  try
    try
      Conn := TUniConnection.Create(nil);
      try
        Conn.ProviderName := 'MySQL';
        Conn.Server := FHost;
        Conn.Port := FPort;
        if Trim(FDatabase) = '' then
          raise Exception.Create('El nombre de la BBDD de destino está vacío.');
        if not FileExists(FRutaFichero) then
          raise Exception.Create('No existe el fichero de copia: ' +
                                 FRutaFichero);
        Conn.Database := 'information_schema';
        Conn.Username := FUser;
        Conn.Password := FPassword;
        Conn.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
        Conn.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
        Conn.LoginPrompt := False;
        Conn.Connected := True;
        Conn.ExecSQL('SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
        FLogBuffer.Add(' -- Preparando BBDD destino: ' + FDatabase);
        Conn.ExecSQL(Format(
          'CREATE DATABASE IF NOT EXISTS %s ' +
          'CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci',
          [NombreBBDDSQL(FDatabase)]));
        Conn.ExecSQL(Format(
          'ALTER DATABASE %s CHARACTER SET utf8mb4 ' +
          'COLLATE utf8mb4_spanish_ci',
          [NombreBBDDSQL(FDatabase)]));
        Conn.ExecSQL('USE ' + NombreBBDDSQL(FDatabase));
        Conn.Database := FDatabase;
        ComprobarCancelacion;
        try
          if FDesencriptar then
          begin
            SqlScript := TUniScript.Create(nil);
            try
              SqlScript.Connection := Conn;
              SqlScript.NoPreconnect := True;
              SqlScript.OnError := ScriptError;
              SqlScript.BeforeExecute := ScriptBeforeExecute;
              SqlScript.AfterExecute := ScriptAfterExecute;
              MyText := TStringList.Create;
              try
                MyText.LoadFromFile(FRutaFichero);
                s := DecriptAESPass(MyText.Text, FPassDesencriptar);
              finally
                FreeAndNil(MyText);
              end;
              if Trim(s) = '' then
              begin
                raise Exception.Create(
                  'No se pudo desencriptar la copia. Revise la contraseña ' +
                  'o seleccione un fichero SQL sin cifrar.');
              end;
              ComprobarCancelacion;
              SqlScript.SQL.Text := s;
              s := '';
              FTotal := 0;
              FPosicion := 0;
              for i := 0 to SqlScript.SQL.Count - 1 do
              begin
                Linea := SqlScript.SQL[i];
                if Pos(';', Linea) > 0 then
                  Inc(FTotal);
              end;
              FProgresoEtapa := 'Restaurando';
              Synchronize(SyncProgreso);
              SqlScript.Execute;
            finally
              FreeAndNil(SqlScript);
            end;
          end
          else
          begin
            EjecutarSQLStreaming(Conn);
          end;
          ComprobarCancelacion;
          ValidarEstructuraRestaurada(Conn);
          FExito := True;
        except
          on E: Exception do
          begin
            FExito := False;
            if E is EAbort then
              FError := E.Message
            else
              FError := E.ClassName + ': ' + E.Message;
          end;
        end;
      finally
        Conn.Free;
      end;
    except
      on E: Exception do
      begin
        FExito := False;
        if E is EAbort then
          FError := E.Message
        else
          FError := E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    if (FError = '') and (not FExito) then
    begin
      if FPrimerError <> '' then
        FError := FPrimerError
      else
        FError := 'La restauración no finalizó correctamente.';
    end;
    Synchronize(SyncFinalizar);
  end;
end;

end.
