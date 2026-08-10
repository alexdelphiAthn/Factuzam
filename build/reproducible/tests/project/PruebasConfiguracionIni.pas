{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasConfiguracionIni                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de resolución, lectura y escritura del INI de la aplicación.      }
{******************************************************************************}
unit PruebasConfiguracionIni;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasConfiguracionIni = class
  private
    FDirectorio: string;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure SinParametro_UsaNombreDelEjecutable;
    [Test]
    procedure ParametroPosicional_UsaNombreAlternativo;
    [Test]
    procedure Interruptor_ConservaNombrePredeterminado;
    [Test]
    procedure ValorAusente_SeDevuelveYSePersiste;
    [Test]
    procedure Escritura_SeRecuperaSinCambios;
    [Test]
    procedure Licencia_ComparteLaRutaDeConfiguracion;
  end;

implementation

uses
  System.IniFiles, System.IOUtils, System.SysUtils,
  inLibConfiguracionIni, inLibDir,
  inLibLicenciaAplicacion;

procedure TPruebasConfiguracionIni.Preparar;
begin
  FDirectorio := TPath.Combine(
    TPath.GetTempPath,
    TPath.GetRandomFileName);
  TDirectory.CreateDirectory(FDirectorio);
  FDirectorio := IncludeTrailingPathDelimiter(
    FDirectorio);
end;

procedure TPruebasConfiguracionIni.Limpiar;
begin
  if TDirectory.Exists(FDirectorio) then
  begin
    TDirectory.Delete(
      FDirectorio,
      True);
  end;
end;

procedure TPruebasConfiguracionIni.
  SinParametro_UsaNombreDelEjecutable;
begin
  Assert.AreEqual(
    FDirectorio + 'fzam.ini',
    ConstruirRutaIni(
      FDirectorio,
      'C:\Factuzam\fzam.exe',
      ''));
end;

procedure TPruebasConfiguracionIni.
  ParametroPosicional_UsaNombreAlternativo;
begin
  Assert.AreEqual(
    FDirectorio + 'cliente.ini',
    ConstruirRutaIni(
      FDirectorio,
      'C:\Factuzam\fzam.exe',
      ' cliente.ini '));
end;

procedure TPruebasConfiguracionIni.
  Interruptor_ConservaNombrePredeterminado;
begin
  Assert.AreEqual(
    FDirectorio + 'fzam.ini',
    ConstruirRutaIni(
      FDirectorio,
      'C:\Factuzam\fzam.exe',
      '-depurar'));
  Assert.AreEqual(
    FDirectorio + 'fzam.ini',
    ConstruirRutaIni(
      FDirectorio,
      'C:\Factuzam\fzam.exe',
      '/depurar'));
end;

procedure TPruebasConfiguracionIni.
  ValorAusente_SeDevuelveYSePersiste;
var
  oIni: TIniFile;
  sRutaIni: string;
begin
  Assert.AreEqual(
    'predeterminado',
    LeerCadenaIni(
      'Seccion',
      'Clave',
      'predeterminado',
      FDirectorio));
  sRutaIni := RutaIniAplicacion(
    FDirectorio);
  Assert.IsTrue(
    TFile.Exists(sRutaIni));
  oIni := TIniFile.Create(sRutaIni);
  try
    Assert.AreEqual(
      'predeterminado',
      oIni.ReadString(
        'Seccion',
        'Clave',
        ''));
  finally
    FreeAndNil(oIni);
  end;
end;

procedure TPruebasConfiguracionIni.
  Escritura_SeRecuperaSinCambios;
begin
  EscribirCadenaIni(
    'Seccion',
    'Clave',
    'valor ñ',
    FDirectorio);
  Assert.AreEqual(
    'valor ñ',
    LeerCadenaIni(
      'Seccion',
      'Clave',
      '',
      FDirectorio));
end;

procedure TPruebasConfiguracionIni.
  Licencia_ComparteLaRutaDeConfiguracion;
begin
  Assert.AreEqual(
    RutaIniAplicacion(GetUserFolder),
    RutaIniLicenciaAplicacion);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasConfiguracionIni);

end.
