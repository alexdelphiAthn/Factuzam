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
    class function CargarDesdeRuta(
      const ARuta: string;
      const AContrasenaEntorno: string): TConfiguracionContazam; static;
  end;

function EsIdentificadorMariaDBValido(
  const AIdentificador: string): Boolean;
function ResolverRutaConfiguracion(
  const ADirectorioLocal: string): string;

implementation

uses
  System.SysUtils, System.IniFiles, System.DateUtils, System.IOUtils,
  Vcl.Forms, inLibCifrado;

const
  SECCION_CONEXION = 'Conexion';
  CLAVE_CONTRASENA = 'Password';
  CLAVE_CONTRASENA_CIFRADA = 'PasswordEn';

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

procedure ComprobarEscrituraCifrada(
  const AIni: TIniFile;
  const ACifrado: string;
  const AContrasena: string);
var
  sGuardado: string;
begin
  sGuardado := AIni.ReadString(
    SECCION_CONEXION,
    CLAVE_CONTRASENA_CIFRADA,
    '');
  if (sGuardado <> ACifrado) or
    not EsCifradoAESValido(sGuardado) or
    (DescifrarAES(sGuardado) <> AContrasena) then
  begin
    raise EInOutError.Create(
      'No se pudo proteger la contraseña de la base de datos en el INI.');
  end;
end;

procedure EliminarContrasenaSinCifrar(
  const AIni: TIniFile);
begin
  AIni.DeleteKey(SECCION_CONEXION, CLAVE_CONTRASENA);
  AIni.UpdateFile;
  if AIni.ValueExists(SECCION_CONEXION, CLAVE_CONTRASENA) then
  begin
    raise EInOutError.Create(
      'No se pudo retirar la contraseña sin cifrar del INI.');
  end;
end;

procedure MigrarContrasenaSinCifrar(
  const AIni: TIniFile;
  const AContrasena: string);
var
  sCifrado: string;
begin
  if AContrasena <> '' then
  begin
    sCifrado := CifrarAES(AContrasena);
    AIni.WriteString(
      SECCION_CONEXION,
      CLAVE_CONTRASENA_CIFRADA,
      sCifrado);
    AIni.UpdateFile;
    ComprobarEscrituraCifrada(AIni, sCifrado, AContrasena);
  end;
  EliminarContrasenaSinCifrar(AIni);
end;

function LeerContrasenaCifrada(
  const AIni: TIniFile): string;
var
  sCifrado: string;
begin
  sCifrado := AIni.ReadString(
    SECCION_CONEXION,
    CLAVE_CONTRASENA_CIFRADA,
    '');
  if sCifrado = '' then
  begin
    Result := '';
  end
  else if EsCifradoAESValido(sCifrado) then
  begin
    Result := DescifrarAES(sCifrado);
  end
  else
  begin
    raise EConvertError.Create(
      'La contraseña cifrada de la base de datos no es válida.');
  end;
end;

function LeerContrasenaIni(
  const AIni: TIniFile): string;
var
  sContrasenaSinCifrar: string;
begin
  if AIni.ValueExists(SECCION_CONEXION, CLAVE_CONTRASENA) then
  begin
    sContrasenaSinCifrar := AIni.ReadString(
      SECCION_CONEXION,
      CLAVE_CONTRASENA,
      '');
    if sContrasenaSinCifrar <> '' then
    begin
      MigrarContrasenaSinCifrar(AIni, sContrasenaSinCifrar);
      Result := sContrasenaSinCifrar;
    end
    else
    begin
      EliminarContrasenaSinCifrar(AIni);
      Result := LeerContrasenaCifrada(AIni);
    end;
  end
  else
  begin
    Result := LeerContrasenaCifrada(AIni);
  end;
end;

class function TConfiguracionContazam.Cargar: TConfiguracionContazam;
var
  sRuta: string;
begin
  sRuta := ResolverRutaConfiguracion(
    GetEnvironmentVariable('LOCALAPPDATA'));
  Result := CargarDesdeRuta(
    sRuta,
    GetEnvironmentVariable('CONTAZAM_DB_PASSWORD'));
end;

class function TConfiguracionContazam.CargarDesdeRuta(
  const ARuta: string;
  const AContrasenaEntorno: string): TConfiguracionContazam;
var
  oIni: TIniFile;
  sContrasenaIni: string;
begin
  Result := Default(TConfiguracionContazam);
  ForceDirectories(ExtractFileDir(ARuta));
  if not FileExists(ARuta) then
  begin
    raise EFileNotFoundException.CreateFmt(
      'No se encuentra la configuración de Contazam en %s.',
      [ARuta]);
  end;
  oIni := TIniFile.Create(ARuta);
  try
    Result.Servidor := oIni.ReadString(
      'Conexion', 'Servidor', '127.0.0.1');
    Result.Puerto := oIni.ReadInteger('Conexion', 'Puerto', 3306);
    Result.Usuario := oIni.ReadString('Conexion', 'Usuario', 'root');
    sContrasenaIni := LeerContrasenaIni(oIni);
    Result.Contrasena := AContrasenaEntorno;
    if Result.Contrasena = '' then
    begin
      Result.Contrasena := sContrasenaIni;
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
    Result.RutaConfiguracion := ARuta;
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
