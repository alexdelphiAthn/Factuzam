{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBackupWorker                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Hilos para ejecutar copia y restauración segura en segundo plano.         }
{******************************************************************************}
unit inLibBackupWorker;

interface

uses
  System.Classes, System.SysUtils,
  Backup.Engine, Backup.Types,
  inLibBackupPersistenciaIntf,
  inLibCopiasSeguridadIntf;

type
  TWorkerProgresoEvent = TProgresoCopiaSeguridadEvent;
  TWorkerFinalizarEvent = TFinalizarCopiaSeguridadEvent;

  TBackupWorker = class(TThread)
  private
    FHost: string;
    FPort: Integer;
    FDatabase: string;
    FUser: string;
    FPassword: string;
    FRutaFichero: string;
    FEncriptar: Boolean;
    FPassEncriptar: string;
    FResultado: TResultadoCopiaSeguridad;
    FError: string;
    FProgresoEtapa: string;
    FProgresoPaso: Integer;
    FProgresoTotal: Integer;
    FProgresoFilaGlobal: Integer;
    FProgresoFilasGlobalTotal: Integer;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    FFabricaPersistencia: IFabricaPersistenciaBackup;
    procedure EngineProgress(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AHost: string;
      APort: Integer;
      const ADatabase, AUser, APassword: string;
      const ARutaFichero: string;
      AEncriptar: Boolean;
      const APassEncriptar: string;
      const AFabricaPersistencia:
        IFabricaPersistenciaBackup = nil);
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
    FPassDesencriptar: string;
    FResultado: TResultadoCopiaSeguridad;
    FError: string;
    FLogBuffer: TStringList;
    FErrores: Integer;
    FPosicion: Integer;
    FTotal: Integer;
    FSentenciasEjecutadas: Integer;
    FProgresoEtapa: string;
    FPrimerError: string;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    FFabricaPersistencia: IFabricaPersistenciaBackup;
    function CrearFlujoRestauracion: TStream;
    procedure EjecutarSQLStreaming(
      const APersistencia: IPersistenciaRestauracionBackup);
    procedure ActualizarProgresoSQL(
      APosicion, ATotal, ASentencias: Integer);
    procedure ComprobarCancelacion;
    procedure RegistrarExcepcion(E: Exception);
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AHost: string;
      APort: Integer;
      const ADatabase, AUser, APassword: string;
      const ARutaFichero: string;
      const APassDesencriptar: string;
      ADesencriptar: Boolean = False;
      const AFabricaPersistencia:
        IFabricaPersistenciaBackup = nil);
    destructor Destroy; override;
    property OnProgreso: TWorkerProgresoEvent
      read FOnProgreso write FOnProgreso;
    property OnFinalizar: TWorkerFinalizarEvent
      read FOnFinalizar write FOnFinalizar;
  end;

function CrearCopiaSeguridadBD(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  AEncriptar: Boolean;
  const APassEncriptar: string;
  AOnProgreso: TWorkerProgresoEvent;
  out AError: string;
  AComprimirAntesCifrado: Boolean = True;
  const AFabricaPersistencia:
    IFabricaPersistenciaBackup = nil): TResultadoCopiaSeguridad;

implementation

uses
  Core_Interfaces, ScriptWriters, System.StrUtils,
  inLibCifradoCopias,
  inLibMsgConfiguracion;

function CrearConfiguracionConexion(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string):
  TConfiguracionConexionBackup;
begin
  Result := Default(TConfiguracionConexionBackup);
  Result.Host := AHost;
  Result.Puerto := APort;
  Result.BaseDatos := ADatabase;
  Result.Usuario := AUser;
  Result.Contrasena := APassword;
end;

function ResolverFabricaPersistencia(
  const AFabrica: IFabricaPersistenciaBackup):
  IFabricaPersistenciaBackup;
begin
  Result := AFabrica;
  if not Assigned(Result) then
  begin
    Result := CrearFabricaPersistenciaBackupPredeterminada;
  end;
end;

function CrearOpcionesBackup: TBackupOptions;
begin
  Result := Default(TBackupOptions);
  Result.WithData := True;
  Result.WithTriggers := True;
  Result.WithProcedures := True;
  Result.WithFunctions := True;
  Result.WithViews := True;
  Result.DropTablesFirst := True;
  Result.UseTransactions := True;
  Result.ExtendedInsert := True;
  Result.ExtendedInsertRows := 500;
end;

function CrearWriterBackup(
  const ARutaFichero: string;
  AEncriptar: Boolean): IScriptWriter;
begin
  if AEncriptar then
  begin
    Result := TScriptWriter.Create('');
  end
  else
  begin
    Result := TScriptWriter.Create(ARutaFichero);
  end;
end;

procedure GuardarCopiaCifrada(
  const AWriter: IScriptWriter;
  const ARutaFichero, APassEncriptar: string;
  AComprimirAntesCifrado: Boolean);
var
  sContenido: string;
  stTexto: TStringList;
begin
  sContenido := AWriter.GetScript;
  sContenido := StringReplace(
    sContenido,
    'DEFINER=`root`@`localhost`',
    '',
    [rfReplaceAll, rfIgnoreCase]);
  if AComprimirAntesCifrado then
  begin
    sContenido := CifrarCopiaSeguridadComprimida(
      sContenido,
      APassEncriptar);
  end
  else
  begin
    sContenido := CifrarCopiaSeguridad(
      sContenido,
      APassEncriptar);
  end;
  stTexto := TStringList.Create;
  try
    stTexto.Text := sContenido;
    stTexto.SaveToFile(ARutaFichero);
  finally
    FreeAndNil(stTexto);
  end;
end;

procedure GenerarCopia(
  const APersistencia: IPersistenciaCopiaBackup;
  const ARutaFichero, APassEncriptar: string;
  AEncriptar, AComprimirAntesCifrado: Boolean;
  AOnProgreso: TWorkerProgresoEvent);
var
  oEngine: TDBBackupEngine;
  oExcluirTablas: TStringList;
  oFiltrosDatos: TStringList;
  oIncluirTablas: TStringList;
  oWriter: IScriptWriter;
begin
  oIncluirTablas := TStringList.Create;
  oExcluirTablas := TStringList.Create;
  oFiltrosDatos := TStringList.Create;
  try
    oFiltrosDatos.Values['fza_traducciones'] :=
      APersistencia.ObtenerFiltroTraducciones;
    oWriter := CrearWriterBackup(ARutaFichero, AEncriptar);
    oEngine := TDBBackupEngine.Create(
      APersistencia.ObtenerServiciosLectura,
      oWriter,
      APersistencia.ObtenerServiciosSql,
      CrearOpcionesBackup,
      oIncluirTablas,
      oExcluirTablas,
      oFiltrosDatos);
    try
      oEngine.OnProgress := AOnProgreso;
      oEngine.GenerateBackup;
      if AEncriptar then
      begin
        GuardarCopiaCifrada(
          oWriter,
          ARutaFichero,
          APassEncriptar,
          AComprimirAntesCifrado);
      end;
    finally
      FreeAndNil(oEngine);
    end;
  finally
    FreeAndNil(oFiltrosDatos);
    FreeAndNil(oExcluirTablas);
    FreeAndNil(oIncluirTablas);
  end;
end;

function CrearCopiaSeguridadBD(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  AEncriptar: Boolean;
  const APassEncriptar: string;
  AOnProgreso: TWorkerProgresoEvent;
  out AError: string;
  AComprimirAntesCifrado: Boolean;
  const AFabricaPersistencia: IFabricaPersistenciaBackup):
  TResultadoCopiaSeguridad;
var
  oFabrica: IFabricaPersistenciaBackup;
  oPersistencia: IPersistenciaCopiaBackup;
begin
  AError := '';
  oFabrica := ResolverFabricaPersistencia(AFabricaPersistencia);
  try
    oPersistencia := oFabrica.CrearCopia(
      CrearConfiguracionConexion(
        AHost,
        APort,
        ADatabase,
        AUser,
        APassword));
    oPersistencia.Preparar;
    GenerarCopia(
      oPersistencia,
      ARutaFichero,
      APassEncriptar,
      AEncriptar,
      AComprimirAntesCifrado,
      AOnProgreso);
    Result := rcsCompletada;
  except
    on E: Exception do
    begin
      if E is EAbort then
      begin
        AError := E.Message;
        Result := rcsCancelada;
      end
      else
      begin
        AError := E.ClassName + ': ' + E.Message;
        Result := rcsFallida;
      end;
    end;
  end;
end;

constructor TBackupWorker.Create(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  AEncriptar: Boolean;
  const APassEncriptar: string;
  const AFabricaPersistencia: IFabricaPersistenciaBackup);
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
  FFabricaPersistencia := AFabricaPersistencia;
  FResultado := rcsFallida;
end;

procedure TBackupWorker.EngineProgress(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if Terminated then
  begin
    raise EAbort.Create(SErrorOperacionCanceladaUsuario);
  end;
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
  begin
    FOnProgreso(
      FProgresoEtapa,
      FProgresoPaso,
      FProgresoTotal,
      FProgresoFilaGlobal,
      FProgresoFilasGlobalTotal);
  end;
end;

procedure TBackupWorker.SyncFinalizar;
begin
  if Assigned(FOnFinalizar) then
  begin
    FOnFinalizar(FResultado, FError, nil);
  end;
end;

procedure TBackupWorker.Execute;
begin
  try
    FResultado := CrearCopiaSeguridadBD(
      FHost,
      FPort,
      FDatabase,
      FUser,
      FPassword,
      FRutaFichero,
      FEncriptar,
      FPassEncriptar,
      EngineProgress,
      FError,
      True,
      FFabricaPersistencia);
  finally
    Synchronize(SyncFinalizar);
  end;
end;

constructor TRestoreWorker.Create(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  const APassDesencriptar: string;
  ADesencriptar: Boolean;
  const AFabricaPersistencia: IFabricaPersistenciaBackup);
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
  FFabricaPersistencia := AFabricaPersistencia;
  FResultado := rcsFallida;
  FProgresoEtapa := 'Restaurando';
  FLogBuffer := TStringList.Create;
end;

destructor TRestoreWorker.Destroy;
begin
  FreeAndNil(FLogBuffer);
  inherited Destroy;
end;

procedure TRestoreWorker.ComprobarCancelacion;
begin
  if Terminated then
  begin
    raise EAbort.Create(SErrorOperacionCanceladaUsuario);
  end;
end;

procedure TRestoreWorker.RegistrarExcepcion(E: Exception);
begin
  if E is EAbort then
  begin
    FResultado := rcsCancelada;
    FError := E.Message;
  end
  else
  begin
    FResultado := rcsFallida;
    FError := E.ClassName + ': ' + E.Message;
  end;
end;

function TRestoreWorker.CrearFlujoRestauracion: TStream;
var
  sContenido: string;
  stTexto: TStringList;
begin
  if FDesencriptar then
  begin
    stTexto := TStringList.Create;
    try
      stTexto.LoadFromFile(FRutaFichero);
      sContenido := DescifrarCopiaSeguridad(
        stTexto.Text,
        FPassDesencriptar);
    finally
      FreeAndNil(stTexto);
    end;
    if Trim(sContenido) = '' then
    begin
      raise Exception.Create(SErrorDesencriptarCopia);
    end;
    Result := TStringStream.Create(sContenido, TEncoding.UTF8);
  end
  else
  begin
    Result := TFileStream.Create(
      FRutaFichero,
      fmOpenRead or fmShareDenyWrite);
  end;
end;

procedure TRestoreWorker.ActualizarProgresoSQL(
  APosicion, ATotal, ASentencias: Integer);
begin
  FProgresoEtapa := 'Restaurando SQL (KB)';
  FPosicion := APosicion;
  FTotal := ATotal;
  FSentenciasEjecutadas := ASentencias;
  Synchronize(SyncProgreso);
end;

procedure TRestoreWorker.EjecutarSQLStreaming(
  const APersistencia: IPersistenciaRestauracionBackup);
var
  oEjecutor: TEjecutorRestauracionSQL;
  oFlujo: TStream;
begin
  oFlujo := CrearFlujoRestauracion;
  try
    oEjecutor := TEjecutorRestauracionSQL.Create(
      APersistencia,
      ComprobarCancelacion,
      ActualizarProgresoSQL,
      FLogBuffer);
    try
      try
        oEjecutor.Ejecutar(oFlujo);
      finally
        FErrores := oEjecutor.Errores;
        FSentenciasEjecutadas := oEjecutor.SentenciasEjecutadas;
        FPrimerError := oEjecutor.PrimerError;
      end;
    finally
      FreeAndNil(oEjecutor);
    end;
  finally
    FreeAndNil(oFlujo);
  end;
end;

procedure TRestoreWorker.SyncProgreso;
var
  sEtapa: string;
begin
  sEtapa := FProgresoEtapa;
  if sEtapa = '' then
  begin
    sEtapa := 'Restaurando';
  end;
  if Assigned(FOnProgreso) then
  begin
    FOnProgreso(
      sEtapa,
      FPosicion,
      FTotal,
      FPosicion,
      FTotal);
  end;
end;

procedure TRestoreWorker.SyncFinalizar;
var
  stLog: TStringList;
begin
  stLog := FLogBuffer;
  FLogBuffer := nil;
  if Assigned(FOnFinalizar) then
  begin
    FOnFinalizar(FResultado, FError, stLog);
  end
  else
  begin
    FreeAndNil(stLog);
  end;
end;

procedure TRestoreWorker.Execute;
var
  oFabrica: IFabricaPersistenciaBackup;
  oPersistencia: IPersistenciaRestauracionBackup;
begin
  try
    try
      if Trim(FDatabase) = '' then
      begin
        raise Exception.Create(SErrorNombreBBDDDestinoVacio);
      end;
      if not FileExists(FRutaFichero) then
      begin
        raise Exception.Create(Format(
          SErrorFicheroCopiaNoExiste,
          [FRutaFichero]));
      end;
      ComprobarCancelacion;
      oFabrica := ResolverFabricaPersistencia(FFabricaPersistencia);
      oPersistencia := oFabrica.CrearRestauracion(
        CrearConfiguracionConexion(
          FHost,
          FPort,
          FDatabase,
          FUser,
          FPassword));
      EjecutarSQLStreaming(oPersistencia);
      ComprobarCancelacion;
      FResultado := rcsCompletada;
    except
      on E: Exception do
      begin
        RegistrarExcepcion(E);
      end;
    end;
  finally
    if (FError = '') and (FResultado = rcsFallida) then
    begin
      if FPrimerError <> '' then
      begin
        FError := FPrimerError;
      end
      else
      begin
        FError := SErrorRestauracionNoFinalizada;
      end;
    end;
    Synchronize(SyncFinalizar);
  end;
end;

end.
