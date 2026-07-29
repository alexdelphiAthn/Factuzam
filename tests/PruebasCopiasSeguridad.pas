{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCopiasSeguridad                                        }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de la política de protección y restauración de copias.            }
{******************************************************************************}
unit PruebasCopiasSeguridad;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCopiasSeguridad = class
  public
    [Test]
    procedure Administrador_CreaTextoPlano;
    [Test]
    procedure Usuario_CreaCifrada;
    [Test]
    procedure Administrador_RestauraSqlYCifrada;
    [Test]
    procedure Usuario_SoloRestauraCifrada;
  end;

implementation

uses
  inLibCopiasSeguridadIntf,
  inLibCopiasSeguridadReglas;

procedure TPruebasCopiasSeguridad.Administrador_CreaTextoPlano;
begin
  Assert.AreEqual(
    Integer(mpcTextoPlano),
    Integer(
      TPoliticaCopiasSeguridad.ModoCreacion(True)));
  Assert.AreEqual(
    '.sql',
    TPoliticaCopiasSeguridad.ExtensionCreacion(True));
end;

procedure TPruebasCopiasSeguridad.Usuario_CreaCifrada;
begin
  Assert.AreEqual(
    Integer(mpcCifrada),
    Integer(
      TPoliticaCopiasSeguridad.ModoCreacion(False)));
  Assert.AreEqual(
    '.crypt',
    TPoliticaCopiasSeguridad.ExtensionCreacion(False));
end;

procedure TPruebasCopiasSeguridad.
  Administrador_RestauraSqlYCifrada;
begin
  Assert.IsTrue(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      True,
      'copia.sql'));
  Assert.IsTrue(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      True,
      'copia.crypt'));
end;

procedure TPruebasCopiasSeguridad.
  Usuario_SoloRestauraCifrada;
begin
  Assert.IsFalse(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      False,
      'copia.sql'));
  Assert.IsTrue(
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      False,
      'copia.crypt'));
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasCopiasSeguridad);

end.
