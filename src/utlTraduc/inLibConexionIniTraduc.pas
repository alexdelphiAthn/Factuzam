{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionIniTraduc                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lee del INI de fzam los datos de conexión usados por el editor.           }
{******************************************************************************}
unit inLibConexionIniTraduc;

interface

type
  TConfiguracionConexionTraduc = record
    BaseDatos: string;
    Clave: string;
    Servidor: string;
    Usuario: string;
    Puerto: Integer;
  end;

function RutaIniFactuzamPredeterminada: string;
function LeerConfiguracionConexionFactuzam(
  const ARutaIni: string): TConfiguracionConexionTraduc;

implementation

uses
  Winapi.ShlObj, Winapi.Windows,
  System.SysUtils,
  inLibConexionPerfilIni,
  inLibConexionPerfilIntf,
  inLibMsgTraduc;

function CarpetaConfiguracionFactuzam: string;
var
  Ruta: array[0..MAX_PATH] of Char;
begin
  SHGetFolderPath(
    0,
    CSIDL_LOCAL_APPDATA,
    0,
    0,
    Ruta);
  Result :=
    IncludeTrailingPathDelimiter(Ruta) +
    'factuzam\';
end;

function RutaIniFactuzamPredeterminada: string;
var
  Parametro: string;
begin
  Parametro := Trim(ParamStr(1));
  if (Parametro <> '') and
     not CharInSet(Parametro[1], ['/', '-']) then
  begin
    if ExtractFilePath(Parametro) = '' then
      Result := CarpetaConfiguracionFactuzam + Parametro
    else
      Result := ExpandFileName(Parametro);
  end
  else
    Result := CarpetaConfiguracionFactuzam + 'fzam.ini';
end;

function LeerConfiguracionConexionFactuzam(
  const ARutaIni: string): TConfiguracionConexionTraduc;
var
  Configuracion: TConfiguracionConexionResuelta;
begin
  if not FileExists(ARutaIni) then
    raise Exception.CreateFmt(
      SErrorIniFactuzamNoExiste,
      [ARutaIni]);
  Configuracion := CargarConfiguracionConexionIni(ARutaIni);
  if Configuracion.Perfil.Motor <> mbMariaDB then
    raise EInvalidOpException.Create(
      SErrorMotorConexionEditorNoSoportado);
  Result.BaseDatos := Configuracion.Perfil.BaseDatos;
  Result.Servidor := Configuracion.Perfil.Servidor;
  Result.Usuario := Configuracion.Perfil.Usuario;
  Result.Puerto := Configuracion.Perfil.Puerto;
  Result.Clave := Configuracion.Credencial;
end;

end.
