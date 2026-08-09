{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasConfiguracion                                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verifica la resolución del INI desde las carpetas de compilación.         }
{******************************************************************************}
unit PruebasConfiguracion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasConfiguracion = class
  public
    [Test]
    procedure CifradoAES_EsCompatibleConFactuzam;
    [Test]
    procedure Cargar_MigraPasswordPlano;
    [Test]
    procedure Cargar_LeePasswordEn;
    [Test]
    procedure RutaIni_UsaLaCarpetaLocalDeContazam;
  end;

implementation

uses
  System.SysUtils, System.IniFiles, System.IOUtils, inLibCifrado,
  inLibConfiguracion;

const
  CONTRASENA_PRUEBA = 'ClavePrueba#2026';
  CIFRADO_FACTUZAM_PRUEBA =
    '82a1JAeyWjkZ8dpFuAwtmaZvPuyqJC99+CHI1Jcd728=';

function CrearRutaIniTemporal: string;
var
  oId: TGUID;
  sRaiz: string;
begin
  CreateGUID(oId);
  sRaiz := TPath.Combine(
    TPath.GetTempPath,
    'contazam_config_' + GUIDToString(oId));
  TDirectory.CreateDirectory(sRaiz);
  Result := TPath.Combine(sRaiz, 'contazam.ini');
end;

procedure CrearIniPrueba(
  const ARuta: string;
  const APassword: string;
  const APasswordEn: string);
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(ARuta);
  try
    oIni.WriteString('Conexion', 'Servidor', '127.0.0.1');
    oIni.WriteInteger('Conexion', 'Puerto', 3306);
    oIni.WriteString('Conexion', 'Usuario', 'root');
    if APassword <> '' then
    begin
      oIni.WriteString('Conexion', 'Password', APassword);
    end;
    if APasswordEn <> '' then
    begin
      oIni.WriteString('Conexion', 'PasswordEn', APasswordEn);
    end;
    oIni.WriteString('Conexion', 'BaseDatos', 'contazam');
    oIni.WriteString(
      'Conexion',
      'BaseDatosFactuzam',
      'factuzam');
    oIni.WriteString('Aplicacion', 'Empresa', '001');
    oIni.WriteInteger('Aplicacion', 'Ejercicio', 2026);
    oIni.UpdateFile;
  finally
    FreeAndNil(oIni);
  end;
end;

procedure EliminarIniTemporal(const ARuta: string);
var
  sDirectorio: string;
begin
  sDirectorio := ExtractFileDir(ARuta);
  if TDirectory.Exists(sDirectorio) and
    sDirectorio.StartsWith(TPath.GetTempPath, True) then
  begin
    TDirectory.Delete(sDirectorio, True);
  end;
end;

procedure TPruebasConfiguracion.CifradoAES_EsCompatibleConFactuzam;
begin
  Assert.AreEqual(
    CIFRADO_FACTUZAM_PRUEBA,
    CifrarAES(CONTRASENA_PRUEBA));
  Assert.AreEqual(
    CONTRASENA_PRUEBA,
    DescifrarAES(CIFRADO_FACTUZAM_PRUEBA));
end;

procedure TPruebasConfiguracion.Cargar_MigraPasswordPlano;
var
  oConfiguracion: TConfiguracionContazam;
  oIni: TIniFile;
  sCifrado: string;
  sContenido: string;
  sRuta: string;
begin
  sRuta := CrearRutaIniTemporal;
  try
    CrearIniPrueba(sRuta, CONTRASENA_PRUEBA, '');
    oConfiguracion := TConfiguracionContazam.CargarDesdeRuta(sRuta, '');
    Assert.AreEqual(CONTRASENA_PRUEBA, oConfiguracion.Contrasena);
    oIni := TIniFile.Create(sRuta);
    try
      Assert.IsFalse(oIni.ValueExists('Conexion', 'Password'));
      sCifrado := oIni.ReadString('Conexion', 'PasswordEn', '');
    finally
      FreeAndNil(oIni);
    end;
    Assert.AreEqual(CIFRADO_FACTUZAM_PRUEBA, sCifrado);
    Assert.AreEqual(CONTRASENA_PRUEBA, DescifrarAES(sCifrado));
    sContenido := TFile.ReadAllText(sRuta, TEncoding.UTF8);
    Assert.IsFalse(sContenido.Contains(CONTRASENA_PRUEBA));
  finally
    EliminarIniTemporal(sRuta);
  end;
end;

procedure TPruebasConfiguracion.Cargar_LeePasswordEn;
var
  oConfiguracion: TConfiguracionContazam;
  sRuta: string;
begin
  sRuta := CrearRutaIniTemporal;
  try
    CrearIniPrueba(sRuta, '', CIFRADO_FACTUZAM_PRUEBA);
    oConfiguracion := TConfiguracionContazam.CargarDesdeRuta(sRuta, '');
    Assert.AreEqual(CONTRASENA_PRUEBA, oConfiguracion.Contrasena);
  finally
    EliminarIniTemporal(sRuta);
  end;
end;

procedure TPruebasConfiguracion.RutaIni_UsaLaCarpetaLocalDeContazam;
var
  oId: TGUID;
  sEjecutable: string;
  sEsperada: string;
  sRaiz: string;
  sRuta: string;
begin
  CreateGUID(oId);
  sRaiz := TPath.Combine(
    TPath.GetTempPath,
    'contazam_config_' + GUIDToString(oId));
  sEsperada := TPath.Combine(
    TPath.Combine(sRaiz, 'Contazam'),
    'contazam.ini');
  sEjecutable := TPath.Combine(
    TPath.Combine(
      TPath.Combine(
        TPath.Combine(sRaiz, 'build'),
        'bin'),
      'Base'),
    'contazam.exe');
  TDirectory.CreateDirectory(ExtractFileDir(sEjecutable));
  try
    sRuta := ResolverRutaConfiguracion(sRaiz);
    Assert.IsTrue(SameText(sEsperada, sRuta));
  finally
    if TDirectory.Exists(sRaiz) and
      sRaiz.StartsWith(TPath.GetTempPath, True) then
    begin
      TDirectory.Delete(sRaiz, True);
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasConfiguracion);

end.
