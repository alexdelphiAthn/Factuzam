{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConfiguracion                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Carga y valida la configuración local de Contazam.                        }
{******************************************************************************}
unit inLibConfiguracion;

interface

type
  TConfiguracionContazam = record
    Servidor: string;
    Puerto: Integer;
    Usuario: string;
    Contrasena: string;
    BaseDatos: string;
    BaseDatosFactuzam: string;
    Empresa: string;
    EmpresaFactuzam: string;
    Ejercicio: Integer;
    UsuarioAplicacion: string;
    RutaConfiguracion: string;
    class function Cargar: TConfiguracionContazam; static;
  end;

function EsIdentificadorMariaDBValido(
  const AIdentificador: string): Boolean;
function ResolverRutaConfiguracion(
  const ADirectorioLocal: string): string;

implementation

uses
  System.SysUtils, System.IniFiles, System.DateUtils, System.IOUtils,
  Vcl.Forms;

function EsIdentificadorMariaDBValido(
  const AIdentificador: string): Boolean;
var
  cCaracter: Char;
begin
  Result := AIdentificador <> '';
  if Result then
  begin
    for cCaracter in AIdentificador do
    begin
      Result := CharInSet(
        cCaracter,
        ['A'..'Z', 'a'..'z', '0'..'9', '_']);
      if not Result then
        Break;
    end;
  end;
end;

function ResolverRutaConfiguracion(
  const ADirectorioLocal: string): string;
var
  sDirectorio: string;
begin
  sDirectorio := Trim(ADirectorioLocal);
  if sDirectorio = '' then
  begin
    sDirectorio := ExtractFileDir(ExpandFileName(Application.ExeName));
  end;
  sDirectorio := TPath.Combine(sDirectorio, 'Contazam');
  Result := TPath.Combine(sDirectorio, 'contazam.ini');
end;

class function TConfiguracionContazam.Cargar: TConfiguracionContazam;
var
  oIni: TIniFile;
  sRuta: string;
begin
  Result := Default(TConfiguracionContazam);
  sRuta := ResolverRutaConfiguracion(
    GetEnvironmentVariable('LOCALAPPDATA'));
  ForceDirectories(ExtractFileDir(sRuta));
  if not FileExists(sRuta) then
  begin
    raise EFileNotFoundException.CreateFmt(
      'No se encuentra la configuración de Contazam en %s.',
      [sRuta]);
  end;
  oIni := TIniFile.Create(sRuta);
  try
    Result.Servidor := oIni.ReadString(
      'Conexion', 'Servidor', '127.0.0.1');
    Result.Puerto := oIni.ReadInteger('Conexion', 'Puerto', 3306);
    Result.Usuario := oIni.ReadString('Conexion', 'Usuario', 'root');
    Result.Contrasena := GetEnvironmentVariable(
      'CONTAZAM_DB_PASSWORD');
    if Result.Contrasena = '' then
    begin
      Result.Contrasena := oIni.ReadString(
        'Conexion', 'Password', '');
    end;
    Result.BaseDatos := oIni.ReadString(
      'Conexion', 'BaseDatos', 'alexcontazam');
    Result.BaseDatosFactuzam := oIni.ReadString(
      'Conexion', 'BaseDatosFactuzam', 'factuzam');
    Result.Empresa := oIni.ReadString('Aplicacion', 'Empresa', '001');
    Result.EmpresaFactuzam := oIni.ReadString(
      'Aplicacion', 'EmpresaFactuzam', Result.Empresa);
    Result.Ejercicio := oIni.ReadInteger(
      'Aplicacion', 'Ejercicio', YearOf(Date));
    Result.UsuarioAplicacion := Trim(oIni.ReadString(
      'Aplicacion',
      'Usuario',
      GetEnvironmentVariable('USERNAME')));
    if Result.UsuarioAplicacion = '' then
    begin
      Result.UsuarioAplicacion := GetEnvironmentVariable('USERNAME');
    end;
    Result.RutaConfiguracion := sRuta;
  finally
    FreeAndNil(oIni);
  end;
  if not EsIdentificadorMariaDBValido(Result.BaseDatos) then
  begin
    raise EConvertError.Create(
      'El nombre de la base de datos de Contazam no es válido.');
  end;
  if not EsIdentificadorMariaDBValido(Result.BaseDatosFactuzam) then
  begin
    raise EConvertError.Create(
      'El nombre de la base de datos de Factuzam no es válido.');
  end;
end;

end.
