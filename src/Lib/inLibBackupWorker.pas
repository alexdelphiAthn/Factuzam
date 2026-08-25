{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBackupWorker                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       23/08/2026                                                    }
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
    FModo: TModoProteccionCopia;
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
      AModo: TModoProteccionCopia;
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
    FModo: TModoProteccionCopia;
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
      AModo: TModoProteccionCopia;
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
  AModo: TModoProteccionCopia;
  const APassEncriptar: string;
  AOnProgreso: TWorkerProgresoEvent;
  out AError: string;
  const AFabricaPersistencia:
    IFabricaPersistenciaBackup = nil): TResultadoCopiaSeguridad;

implementation

uses
  Core_Interfaces, ScriptWriters, System.IOUtils, System.StrUtils,
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

function CrearRutaScriptBackup(
  const ARutaFichero: string;
  AModo: TModoProteccionCopia): string;
var
  sDirectorio: string;
begin
  if AModo = mpcTextoPlano then
    Result := ARutaFichero
  else
  begin
    sDirectorio := ExtractFilePath(ARutaFichero);
    if sDirectorio = '' then
      sDirectorio := GetCurrentDir;
    Result := TPath.Combine(
      sDirectorio,
      'fzam_sql_' + TGUID.NewGuid.ToString + '.tmp');
  end;
end;

function ObtenerContenidoCopia(
  const ARutaScript: string): string;
begin
  Result := TFile.ReadAllText(
    ARutaScript,
    TEncoding.UTF8);
  Result := StringReplace(
    Result,
    'DEFINER=`root`@`localhost`',
    '',
    [rfReplaceAll, rfIgnoreCase]);
end;

procedure GuardarBytesCopia(
  const ARutaFichero: string;
  const ADatos: TBytes);
var
  oFichero: TFileStream;
begin
  oFichero := TFileStream.Create(ARutaFichero, fmCreate);
  try
    if Length(ADatos) > 0 then
      oFichero.WriteBuffer(ADatos[0], Length(ADatos));
  finally
    FreeAndNil(oFichero);
  end;
end;

procedure GuardarTextoCopia(
  const ARutaFichero, AContenido: string);
begin
  GuardarBytesCopia(
    ARutaFichero,
    TEncoding.UTF8.GetBytes(AContenido));
end;

procedure GuardarCopiaGenerada(
  const ARutaScript, ARutaFichero, APassEncriptar: string;
  AModo: TModoProteccionCopia);
var
  aZip: TBytes;
  sContenido: string;
begin
  if AModo <> mpcTextoPlano then
  begin
    sContenido := ObtenerContenidoCopia(ARutaScript);
    case AModo of
      mpcZip:
      begin
        aZip := EmpaquetarCopiaSeguridadZip(
          TEncoding.UTF8.GetBytes(sContenido));
        GuardarBytesCopia(ARutaFichero, aZip);
      end;
      mpcCifrada:
        GuardarTextoCopia(
          ARutaFichero,
          CifrarCopiaSeguridadComprimida(
            sContenido,
            APassEncriptar));
    end;
  end;
end;

procedure NotificarGuardadoCopia(
  AModo: TModoProteccionCopia;
  AOnProgreso: TWorkerProgresoEvent);
var
  sEtapa: string;
begin
  if Assigned(AOnProgreso) then
  begin
    case AModo of
      mpcTextoPlano:
        sEtapa := SProgresoGuardandoCopiaTextoPlano;
      mpcZip:
        sEtapa := SProgresoComprimiendoCopiaZip;
      mpcCifrada:
        sEtapa := SProgresoComprimiendoCifrandoCopia;
    end;
    AOnProgreso(sEtapa, 1, 1, 1, 1);
  end;
end;

procedure GenerarCopia(
  const APersistencia: IPersistenciaCopiaBackup;
  const ARutaFichero, APassEncriptar: string;
  AModo: TModoProteccionCopia;
  AOnProgreso: TWorkerProgresoEvent);
var
  oEngine: TDBBackupEngine;
  oExcluirTablas: TStringList;
  oFiltrosDatos: TStringList;
  oIncluirTablas: TStringList;
  oWriter: IScriptWriter;
  sRutaScript: string;
begin
  oEngine := nil;
  oIncluirTablas := nil;
  oExcluirTablas := nil;
  oFiltrosDatos := nil;
  sRutaScript := '';
  try
    oIncluirTablas := TStringList.Create;
    oExcluirTablas := TStringList.Create;
    oFiltrosDatos := TStringList.Create;
    sRutaScript := CrearRutaScriptBackup(
      ARutaFichero,
      AModo);
    oFiltrosDatos.Values['fza_traducciones'] :=
      APersistencia.ObtenerFiltroTraducciones;
    oWriter := TScriptWriter.Create(sRutaScript);
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
      FreeAndNil(oEngine);
      oWriter := nil;
      NotificarGuardadoCopia(AModo, AOnProgreso);
      GuardarCopiaGenerada(
        sRutaScript,
        ARutaFichero,
        APassEncriptar,
        AModo);
    finally
      FreeAndNil(oEngine);
    end;
  finally
    oWriter := nil;
    if (AModo <> mpcTextoPlano) and
       FileExists(sRutaScript) then
    begin
      System.SysUtils.DeleteFile(sRutaScript);
    end;
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
  AModo: TModoProteccionCopia;
  const APassEncriptar: string;
  AOnProgreso: TWorkerProgresoEvent;
  out AError: string;
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
      AModo,
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
  AModo: TModoProteccionCopia;
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
  FModo := AModo;
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
      FModo,
      FPassEncriptar,
      EngineProgress,
      FError,
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
  AModo: TModoProteccionCopia;
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
  FModo := AModo;
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
  aDatos: TBytes;
  sContenido: string;
  stTexto: TStringList;
begin
  sContenido := '';
  if FModo = mpcCifrada then
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
  end
  else if FModo = mpcZip then
  begin
    aDatos := TFile.ReadAllBytes(FRutaFichero);
    aDatos := DesempaquetarCopiaSeguridadZip(aDatos);
    sContenido := TEncoding.UTF8.GetString(aDatos);
  end;
  if FModo = mpcTextoPlano then
  begin
    Result := TFileStream.Create(
      FRutaFichero,
      fmOpenRead or fmShareDenyWrite);
  end
  else
  begin
    if Trim(sContenido) = '' then
    begin
      raise Exception.Create(SErrorDesencriptarCopia);
    end;
    Result := TStringStream.Create(sContenido, TEncoding.UTF8);
  end;
end;

procedure TRestoreWorker.ActualizarProgresoSQL(
  APosicion, ATotal, ASentencias: Integer);
begin
  FProgresoEtapa := 'Restaurando SQL';
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
