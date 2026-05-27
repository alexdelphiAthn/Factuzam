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
  Backup.Engine, Backup.Types;

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
    FPassDesencriptar: AnsiString;
    FExito: Boolean;
    FError: string;
    FLogBuffer: TStringList;
    FStopwatch: TStopwatch;
    FPosicion: Integer;
    FTotal: Integer;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    procedure ScriptBeforeExecute(Sender: TObject;
                                   var SQL: string;
                                   var Omit: Boolean);
    procedure ScriptAfterExecute(Sender: TObject; SQL: string);
    procedure ScriptError(Sender: TObject; E: Exception;
                           SQL: string; var Action: TErrorAction);
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(const AHost: string; APort: Integer;
                       const ADatabase, AUser, APassword: string;
                       const ARutaFichero: string;
                       const APassDesencriptar: AnsiString);
    property OnProgreso: TWorkerProgresoEvent
      read FOnProgreso write FOnProgreso;
    property OnFinalizar: TWorkerFinalizarEvent
      read FOnFinalizar write FOnFinalizar;
  end;

implementation

uses
  Core_Interfaces, Core_Helpers,
  Providers_MySQL, Providers_MySQL_Helpers, ScriptWriters,
  Uni, MySQLUniProvider, UniScript, DAScript,
  inLibtb;

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
    Exit;
  FProgresoEtapa := AEtapa;
  FProgresoPaso := APaso;
  FProgresoTotal := ATotal;
  FProgresoFilaGlobal := AFilaGlobal;
  FProgresoFilasGlobalTotal := AFilasGlobalTotal;
  Synchronize(SyncProgreso);
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
var
  Conn: TUniConnection;
  Options: TBackupOptions;
  Provider: IDBMetadataProvider;
  Helpers: IDBHelpers;
  Writer: IScriptWriter;
  Engine: TDBBackupEngine;
  IncludeTables, ExcludeTables: TStringList;
  s: string;
  MyText: TStringList;
begin
  Conn := TUniConnection.Create(nil);
  try
    Conn.ProviderName := 'MySQL';
    Conn.Server := FHost;
    Conn.Port := FPort;
    Conn.Database := FDatabase;
    Conn.Username := FUser;
    Conn.Password := FPassword;
    Conn.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
    Conn.LoginPrompt := False;
    Conn.Connected := True;
    try
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
      Provider := TMySQLMetadataProvider.Create(Conn, FDatabase);
      Helpers := TMySQLHelpers.Create;
      if FEncriptar then
        Writer := TScriptWriter.Create('')
      else
        Writer := TScriptWriter.Create(FRutaFichero);
      try
        Engine := TDBBackupEngine.Create(Provider, Writer, Helpers,
                                          Options,
                                          IncludeTables, ExcludeTables);
        try
          Engine.OnProgress := EngineProgress;
          Engine.GenerateBackup;
          if FEncriptar then
          begin
            s := Writer.GetScript;
            s := StringReplace(s, 'DEFINER=`root`@`localhost`', '',
              [rfReplaceAll, rfIgnoreCase]);
            s := EncriptAESPass(s, FPassEncriptar);
            MyText := TStringList.Create;
            try
              MyText.Text := s;
              MyText.SaveToFile(FRutaFichero);
            finally
              FreeAndNil(MyText);
            end;
          end;
          FExito := True;
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
        FExito := False;
        FError := E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    Conn.Free;
  end;
  Queue(SyncFinalizar);
end;

{ TRestoreWorker }

constructor TRestoreWorker.Create(const AHost: string; APort: Integer;
  const ADatabase, AUser, APassword, ARutaFichero: string;
  const APassDesencriptar: AnsiString);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FHost := AHost;
  FPort := APort;
  FDatabase := ADatabase;
  FUser := AUser;
  FPassword := APassword;
  FRutaFichero := ARutaFichero;
  FPassDesencriptar := APassDesencriptar;
  FExito := False;
  FLogBuffer := TStringList.Create;
end;

procedure TRestoreWorker.ScriptBeforeExecute(Sender: TObject;
  var SQL: string; var Omit: Boolean);
begin
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
  Inc(FPosicion);
  if (FPosicion mod 20) = 0 then
    Synchronize(SyncProgreso);
end;

procedure TRestoreWorker.ScriptError(Sender: TObject; E: Exception;
  SQL: string; var Action: TErrorAction);
begin
  FStopwatch.Stop;
  FLogBuffer.Add(Format(' -- [ERROR] %s | Tiempo: %d ms',
                         [E.Message, FStopwatch.ElapsedMilliseconds]));
  FLogBuffer.Add('--------------------------------------------------');
  Action := eaContinue;
end;

procedure TRestoreWorker.SyncProgreso;
begin
  if Assigned(FOnProgreso) then
    FOnProgreso('Restaurando', FPosicion, FTotal, FPosicion, FTotal);
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
begin
  Conn := TUniConnection.Create(nil);
  try
    Conn.ProviderName := 'MySQL';
    Conn.Server := FHost;
    Conn.Port := FPort;
    Conn.Database := FDatabase;
    Conn.Username := FUser;
    Conn.Password := FPassword;
    Conn.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
    Conn.LoginPrompt := False;
    Conn.Connected := True;
    try
      MyText := TStringList.Create;
      try
        MyText.LoadFromFile(FRutaFichero);
        s := MyText.Text;
      finally
        FreeAndNil(MyText);
      end;
      SqlScript := TUniScript.Create(nil);
      try
        SqlScript.Connection := Conn;
        SqlScript.NoPreconnect := True;
        SqlScript.OnError := ScriptError;
        SqlScript.BeforeExecute := ScriptBeforeExecute;
        SqlScript.AfterExecute := ScriptAfterExecute;
        if FPassDesencriptar <> '' then
          SqlScript.SQL.Text := DecriptAESPass(s, FPassDesencriptar)
        else
          SqlScript.SQL.Text := s;
        // Contar sentencias para progreso
        FTotal := 0;
        FPosicion := 0;
        for i := 1 to Length(SqlScript.SQL.Text) do
        begin
          if SqlScript.SQL.Text[i] = ';' then
            Inc(FTotal);
        end;
        Synchronize(SyncProgreso);
        SqlScript.Execute;
        FExito := True;
      finally
        FreeAndNil(SqlScript);
      end;
    except
      on E: Exception do
      begin
        FExito := False;
        FError := E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    Conn.Free;
  end;
  Queue(SyncFinalizar);
end;

end.
