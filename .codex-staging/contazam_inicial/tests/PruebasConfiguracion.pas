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
    procedure RutaIni_UsaLaCarpetaLocalDeContazam;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, inLibConfiguracion;

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
