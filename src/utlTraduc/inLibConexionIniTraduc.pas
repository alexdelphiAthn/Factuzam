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
  System.IniFiles, System.SysUtils,
  inLibCifrado, inLibMsgTraduc;

const
  CLAVE_PREDETERMINADA_CIFRADA =
    '2qJFaDfegP/9y6RDno1FRg==';

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
  Ini: TIniFile;
  ClaveCifrada: string;
begin
  if not FileExists(ARutaIni) then
    raise Exception.CreateFmt(
      SErrorIniFactuzamNoExiste,
      [ARutaIni]);
  Ini := TIniFile.Create(ARutaIni);
  try
    Result.BaseDatos := Ini.ReadString(
      'ConnData',
      'Database',
      'factuzam');
    Result.Servidor := Ini.ReadString(
      'ConnData',
      'HostName',
      '127.0.0.1');
    Result.Usuario := Ini.ReadString(
      'ConnData',
      'User',
      'root');
    Result.Puerto := StrToIntDef(
      Ini.ReadString(
        'ConnData',
        'Puerto',
        '3306'),
      3306);
    ClaveCifrada := Ini.ReadString(
      'ConnData',
      'PasswordEn',
      CLAVE_PREDETERMINADA_CIFRADA);
    Result.Clave := DescifrarAES(ClaveCifrada);
    if (ClaveCifrada <> '') and
       (Result.Clave = '') then
      raise Exception.Create(SErrorClaveIniFactuzam);
  finally
    FreeAndNil(Ini);
  end;
end;

end.
