{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLog                                                      }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Log por ejecución, con exclusión entre procesos y rotación en ZIP.        }
{******************************************************************************}
unit inLibLog;

interface

uses
  inLibLogIntf;

const
  RetencionLogPredeterminada = 10;

function CrearRegistroLogContazam(
  const ADirectorio: string = '';
  ARetencion: Integer = RetencionLogPredeterminada
): IRegistroLogContazam;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  System.SyncObjs, System.Zip, inLibDir;

const
  NombreMutexLog = 'Global\ContazamLogMutex';
  EsperaMutexLogMs = 5000;

type
  TNivelLogContazam = (nlInformacion, nlAviso, nlError);

  TRegistroLogContazam = class(TInterfacedObject, IRegistroLogContazam)
  private
    FArchivo: string;
    FCarpeta: string;
    FExclusion: TCriticalSection;
    FIdentificador: string;
    FMutex: THandle;
    FRetencion: Integer;
    function AdquirirExclusion: Boolean;
    function CrearIdentificador: string;
    function NivelComoTexto(ANivel: TNivelLogContazam): string;
    procedure ArchivarLog(const AArchivo: string);
    procedure EscribirCabecera;
    procedure EscribirLinea(const AMensaje: string);
    procedure LiberarExclusion;
    procedure Registrar(
      ANivel: TNivelLogContazam;
      const AMensaje: string);
    procedure RotarLogs;
  public
    constructor Create(
      const ADirectorio: string;
      ARetencion: Integer);
    destructor Destroy; override;
    procedure RegistrarInformacion(const AMensaje: string);
    procedure RegistrarAviso(const AMensaje: string);
    procedure RegistrarError(const AMensaje: string);
    procedure RegistrarExcepcion(
      const AContexto: string;
      E: Exception);
    function RutaArchivo: string;
    function RutaCarpeta: string;
  end;

function CrearRegistroLogContazam(
  const ADirectorio: string;
  ARetencion: Integer): IRegistroLogContazam;
begin
  Result := TRegistroLogContazam.Create(ADirectorio, ARetencion);
end;

function TRegistroLogContazam.AdquirirExclusion: Boolean;
var
  dwResultado: DWORD;
begin
  FExclusion.Enter;
  Result := True;
  if FMutex <> 0 then
  begin
    dwResultado := WaitForSingleObject(FMutex, EsperaMutexLogMs);
    Result := (dwResultado = WAIT_OBJECT_0) or
      (dwResultado = WAIT_ABANDONED);
    if not Result then
    begin
      FExclusion.Leave;
    end;
  end;
end;

procedure TRegistroLogContazam.ArchivarLog(const AArchivo: string);
var
  oZip: TZipFile;
  sArchivoZip: string;
  sCarpetaArchivo: string;
  dFecha: TDateTime;
  bAbierto: Boolean;
begin
  dFecha := TFile.GetLastWriteTime(AArchivo);
  sCarpetaArchivo := TPath.Combine(FCarpeta, 'archive');
  sCarpetaArchivo := TPath.Combine(
    sCarpetaArchivo,
    FormatDateTime('yyyy', dFecha));
  sCarpetaArchivo := TPath.Combine(
    sCarpetaArchivo,
    FormatDateTime('mm', dFecha));
  ForceDirectories(sCarpetaArchivo);
  sArchivoZip := TPath.Combine(
    sCarpetaArchivo,
    'Logs_' + FormatDateTime('yyyy_mm_dd', dFecha) + '.zip');
  oZip := TZipFile.Create;
  bAbierto := False;
  try
    if TFile.Exists(sArchivoZip) then
    begin
      oZip.Open(sArchivoZip, zmReadWrite);
    end
    else
    begin
      oZip.Open(sArchivoZip, zmWrite);
    end;
    bAbierto := True;
    if oZip.IndexOf(ExtractFileName(AArchivo)) < 0 then
    begin
      oZip.Add(AArchivo, ExtractFileName(AArchivo));
    end;
    oZip.Close;
    bAbierto := False;
    TFile.Delete(AArchivo);
  finally
    if bAbierto then
    begin
      oZip.Close;
    end;
    FreeAndNil(oZip);
  end;
end;

constructor TRegistroLogContazam.Create(
  const ADirectorio: string;
  ARetencion: Integer);
begin
  inherited Create;
  FExclusion := TCriticalSection.Create;
  FMutex := CreateMutex(nil, False, PChar(NombreMutexLog));
  FIdentificador := CrearIdentificador;
  FRetencion := ARetencion;
  if FRetencion < 1 then
  begin
    FRetencion := 1;
  end;
  FCarpeta := Trim(ADirectorio);
  if FCarpeta = '' then
  begin
    FCarpeta := GetLogFolder;
  end;
  ForceDirectories(TPath.Combine(FCarpeta, 'archive'));
  ForceDirectories(FCarpeta);
  FArchivo := TPath.Combine(
    FCarpeta,
    'LOG_' + FormatDateTime('yyyy_mm_dd_hhnnss', Now) + '_' +
    FIdentificador + '.log');
  EscribirCabecera;
  RegistrarInformacion('Inicio de sesión de log.');
  RotarLogs;
end;

function TRegistroLogContazam.CrearIdentificador: string;
var
  oIdentificador: TGUID;
begin
  if CreateGUID(oIdentificador) = S_OK then
  begin
    Result := GUIDToString(oIdentificador);
  end
  else
  begin
    Result := IntToStr(GetCurrentProcessId) + '_' +
      IntToStr(GetTickCount);
  end;
end;

destructor TRegistroLogContazam.Destroy;
begin
  try
    RegistrarInformacion('Fin de sesión de log.');
  except
    on E: Exception do
    begin
      OutputDebugString(PChar(
        'Contazam: no se pudo cerrar el log: ' + E.Message));
    end;
  end;
  if FMutex <> 0 then
  begin
    CloseHandle(FMutex);
  end;
  FreeAndNil(FExclusion);
  inherited;
end;

procedure TRegistroLogContazam.EscribirCabecera;
begin
  EscribirLinea('-------- Nuevo fichero de log --------');
  EscribirLinea(
    'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  EscribirLinea(
    'Nombre del equipo: ' + GetEnvironmentVariable('COMPUTERNAME'));
  EscribirLinea(
    'Usuario de Windows: ' + GetEnvironmentVariable('USERNAME'));
  EscribirLinea('Versión de Windows: ' + TOSVersion.ToString);
  EscribirLinea('Ruta del programa: ' + ParamStr(0));
  EscribirLinea('Carpeta de log: ' + FCarpeta);
  EscribirLinea('Versión de Contazam: 1.0.0');
  EscribirLinea(
    'Proceso: ' + IntToStr(GetCurrentProcessId));
  EscribirLinea('---------------------------------------');
end;

procedure TRegistroLogContazam.EscribirLinea(const AMensaje: string);
var
  aDatos: TBytes;
  oArchivo: TFileStream;
  sLinea: string;
begin
  if AdquirirExclusion then
  begin
    try
      if TFile.Exists(FArchivo) then
      begin
        oArchivo := TFileStream.Create(
          FArchivo,
          fmOpenReadWrite or fmShareDenyNone);
      end
      else
      begin
        oArchivo := TFileStream.Create(
          FArchivo,
          fmCreate or fmShareDenyNone);
      end;
      try
        oArchivo.Seek(0, soEnd);
        sLinea := Format(
          '%s - [Instance: %s] %s%s',
          [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
           FIdentificador, AMensaje, sLineBreak]);
        aDatos := TEncoding.UTF8.GetBytes(sLinea);
        if Length(aDatos) > 0 then
        begin
          oArchivo.WriteBuffer(aDatos[0], Length(aDatos));
        end;
      finally
        FreeAndNil(oArchivo);
      end;
    finally
      LiberarExclusion;
    end;
  end;
end;

procedure TRegistroLogContazam.LiberarExclusion;
begin
  if FMutex <> 0 then
  begin
    ReleaseMutex(FMutex);
  end;
  FExclusion.Leave;
end;

function TRegistroLogContazam.NivelComoTexto(
  ANivel: TNivelLogContazam): string;
begin
  case ANivel of
    nlInformacion:
      Result := 'INFO';
    nlAviso:
      Result := 'WARNING';
    nlError:
      Result := 'ERROR';
  else
    Result := 'DESCONOCIDO';
  end;
end;

procedure TRegistroLogContazam.Registrar(
  ANivel: TNivelLogContazam;
  const AMensaje: string);
begin
  EscribirLinea(NivelComoTexto(ANivel) + ': ' + AMensaje);
end;

procedure TRegistroLogContazam.RegistrarAviso(const AMensaje: string);
begin
  Registrar(nlAviso, AMensaje);
end;

procedure TRegistroLogContazam.RegistrarError(const AMensaje: string);
begin
  Registrar(nlError, AMensaje);
end;

procedure TRegistroLogContazam.RegistrarExcepcion(
  const AContexto: string;
  E: Exception);
var
  oInterna: Exception;
  sDetalle: string;
begin
  if E = nil then
  begin
    RegistrarError(AContexto + ': excepción no disponible.');
  end
  else
  begin
    sDetalle := AContexto + ' - ' + E.ClassName + ': ' + E.Message;
    if E.StackTrace <> '' then
    begin
      sDetalle := sDetalle + sLineBreak + E.StackTrace;
    end;
    oInterna := E.InnerException;
    while oInterna <> nil do
    begin
      sDetalle := sDetalle + sLineBreak + 'Causa: ' +
        oInterna.ClassName + ': ' + oInterna.Message;
      oInterna := oInterna.InnerException;
    end;
    RegistrarError(sDetalle);
  end;
end;

procedure TRegistroLogContazam.RegistrarInformacion(
  const AMensaje: string);
begin
  Registrar(nlInformacion, AMensaje);
end;

procedure TRegistroLogContazam.RotarLogs;
var
  oArchivos: TStringList;
  aArchivos: TArray<string>;
  iIndice: Integer;
  iNumeroArchivar: Integer;
begin
  if AdquirirExclusion then
  begin
    try
      oArchivos := TStringList.Create;
      try
        oArchivos.Sorted := True;
        aArchivos := TDirectory.GetFiles(FCarpeta, 'LOG_*.log');
        for iIndice := 0 to Length(aArchivos) - 1 do
        begin
          if not SameText(aArchivos[iIndice], FArchivo) then
          begin
            oArchivos.Add(aArchivos[iIndice]);
          end;
        end;
        iNumeroArchivar := Length(aArchivos) - FRetencion;
        if iNumeroArchivar > oArchivos.Count then
        begin
          iNumeroArchivar := oArchivos.Count;
        end;
        iIndice := 0;
        while iIndice < iNumeroArchivar do
        begin
          ArchivarLog(oArchivos[iIndice]);
          Inc(iIndice);
        end;
      finally
        FreeAndNil(oArchivos);
      end;
    except
      on E: Exception do
      begin
        OutputDebugString(PChar(
          'Contazam: no se pudieron rotar los logs: ' + E.Message));
      end;
    end;
    LiberarExclusion;
  end;
end;

function TRegistroLogContazam.RutaArchivo: string;
begin
  Result := FArchivo;
end;

function TRegistroLogContazam.RutaCarpeta: string;
begin
  Result := FCarpeta;
end;

end.
