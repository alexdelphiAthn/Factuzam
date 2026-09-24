{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionComparacion                                 }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Actualización por comparación: lanza el DBComparer.exe publicado con la   }
{    versión contra la base de trabajo y deja el script que la pone al nivel   }
{    del modelo, en el dialecto de su servidor (MariaDB 12, MariaDB 10 o       }
{    MySQL 8.0.41). DBComparer decide el dialecto; aquí no se repite.          }
{******************************************************************************}
unit inLibActualizacionComparacion;

interface

uses
  Uni;

const
  // Códigos de salida de DBComparer.
  cSalidaComparadorBien = 0;
  cSalidaComparadorAvisos = 2;

type
  TResultadoComparacionActualizacion = record
    Ok: Boolean;
    Codigo: Cardinal;
    RutaScript: string;
    // Lo que DBComparer escribe mientras trabaja: destino detectado,
    // esquema temporal del modelo y avisos.
    Salida: string;
    Error: string;
    function ConAvisos: Boolean;
  end;

// Nombre con el que el script generado queda anotado entre los aplicados.
function NombreScriptComparacion(const AVersion: string): string;
// Ejecuta DBComparer --modelo contra la base de AConexion y espera a que
// termine: llamar desde un hilo de trabajo. La contraseña viaja en la
// variable de entorno DBCOMPARER_PASSWORD, no en la línea de órdenes.
function GenerarScriptComparacion(
  AConexion: TUniConnection;
  const ARutaComparador, ARutaModelo, ARutaScript: string):
  TResultadoComparacionActualizacion;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  inLibActualizacionScripts,
  inLibMsgIntegraciones;

const
  cVariableClaveComparador = 'DBCOMPARER_PASSWORD';
  cPuertoMySqlPorDefecto = 3306;

{ TResultadoComparacionActualizacion }

function TResultadoComparacionActualizacion.ConAvisos: Boolean;
begin
  Result := Ok and (Codigo = cSalidaComparadorAvisos);
end;

function NombreScriptComparacion(const AVersion: string): string;
begin
  Result := 'comparacion_' + AVersion + '.sql';
end;

function EntreComillas(const ATexto: string): string;
begin
  Result := '"' + ATexto + '"';
end;

function LineaOrdenes(
  AConexion: TUniConnection;
  const ARutaComparador, ARutaModelo, ARutaScript: string): string;
var
  iPuerto: Integer;
begin
  iPuerto := AConexion.Port;
  if iPuerto <= 0 then
    iPuerto := cPuertoMySqlPorDefecto;
  Result := EntreComillas(ARutaComparador) +
    ' ' + EntreComillas('--modelo=' + ARutaModelo) +
    ' ' + EntreComillas(Format('%s:%d\%s',
      [AConexion.Server, iPuerto, AConexion.Database])) +
    ' ' + EntreComillas(AConexion.Username + '\*') +
    ' ' + EntreComillas('--output=' + ARutaScript) +
    ' --encoding=utf8bom';
  if SameText(AConexion.SpecificOptions.Values['MySQL.Protocol'],
       'mpSSL') then
    Result := Result + ' --ssl';
end;

function CrearFicheroSalida(const ARuta: string): THandle;
var
  oSeguridad: TSecurityAttributes;
begin
  ZeroMemory(@oSeguridad, SizeOf(oSeguridad));
  oSeguridad.nLength := SizeOf(oSeguridad);
  oSeguridad.bInheritHandle := True;
  Result := CreateFile(
    PChar(ARuta),
    GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE,
    @oSeguridad,
    CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,
    0);
  if Result = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
end;

// Arranca el proceso sin ventana, con la salida en AFicheroSalida, y
// devuelve su código de salida.
function EjecutarComparador(
  const ALinea, ADirectorio: string;
  AFicheroSalida: THandle): Cardinal;
var
  oInicio: TStartupInfo;
  oProceso: TProcessInformation;
  sLinea: string;
begin
  ZeroMemory(@oInicio, SizeOf(oInicio));
  ZeroMemory(@oProceso, SizeOf(oProceso));
  oInicio.cb := SizeOf(oInicio);
  oInicio.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  oInicio.wShowWindow := SW_HIDE;
  oInicio.hStdOutput := AFicheroSalida;
  oInicio.hStdError := AFicheroSalida;
  oInicio.hStdInput := 0;
  // CreateProcess puede escribir en la línea: tiene que ser una copia.
  sLinea := ALinea;
  UniqueString(sLinea);
  if not CreateProcess(nil, PChar(sLinea), nil, nil, True,
       CREATE_NO_WINDOW, nil, PChar(ADirectorio), oInicio, oProceso) then
    RaiseLastOSError;
  try
    WaitForSingleObject(oProceso.hProcess, INFINITE);
    if not GetExitCodeProcess(oProceso.hProcess, Result) then
      RaiseLastOSError;
  finally
    CloseHandle(oProceso.hThread);
    CloseHandle(oProceso.hProcess);
  end;
end;

function GenerarScriptComparacion(
  AConexion: TUniConnection;
  const ARutaComparador, ARutaModelo, ARutaScript: string):
  TResultadoComparacionActualizacion;
var
  hSalida: THandle;
  sRutaSalida: string;
begin
  Result := Default(TResultadoComparacionActualizacion);
  Result.RutaScript := ARutaScript;
  sRutaSalida := ChangeFileExt(ARutaScript, '.log');
  try
    if TFile.Exists(ARutaScript) then
      TFile.Delete(ARutaScript);
    hSalida := CrearFicheroSalida(sRutaSalida);
    try
      // El hijo hereda el entorno: la variable se quita en cuanto arranca
      // y termina, para que no quede en el del programa.
      SetEnvironmentVariable(PChar(cVariableClaveComparador),
        PChar(AConexion.Password));
      try
        Result.Codigo := EjecutarComparador(
          LineaOrdenes(AConexion, ARutaComparador, ARutaModelo, ARutaScript),
          ExtractFilePath(ARutaComparador),
          hSalida);
      finally
        SetEnvironmentVariable(PChar(cVariableClaveComparador), nil);
      end;
    finally
      CloseHandle(hSalida);
    end;
    Result.Salida := Trim(LeerTextoScriptSql(sRutaSalida));
    Result.Ok := ((Result.Codigo = cSalidaComparadorBien) or
      (Result.Codigo = cSalidaComparadorAvisos)) and
      TFile.Exists(ARutaScript);
    if not Result.Ok then
      Result.Error := Format(SErrorComparadorActualizacion,
        [Result.Codigo, Result.Salida]);
  except
    on E: Exception do
      Result.Error := Format(SErrorComparadorActualizacionNoArranca,
        [ARutaComparador, E.Message]);
  end;
end;

end.
