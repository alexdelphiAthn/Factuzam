{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRegistroPantallas                                     }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del registro compartido de pantallas y data modules.             }
{******************************************************************************}
unit PruebasRegistroPantallas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRegistroPantallas = class
  public
    [Test]
    procedure Pantalla_SeResuelvePorNombreCualificado;
    [Test]
    procedure DataModule_SeResuelveIgnorandoEspaciosYMayusculas;
  end;

implementation

uses
  System.SysUtils, System.Classes, Vcl.Forms,
  inLibRegistroPantallas;

type
  TPantallaRegistroPrueba = class(TForm);
  TDataModuleRegistroPrueba = class(TDataModule);

procedure TPruebasRegistroPantallas.
  Pantalla_SeResuelvePorNombreCualificado;
var
  sNombre: string;
begin
  RegistrarPantalla(TPantallaRegistroPrueba);
  sNombre := TPantallaRegistroPrueba.QualifiedClassName;
  Assert.IsTrue(
    ClasePantalla(sNombre) = TPantallaRegistroPrueba);
end;

procedure TPruebasRegistroPantallas.
  DataModule_SeResuelveIgnorandoEspaciosYMayusculas;
var
  sNombre: string;
begin
  RegistrarDataModule(TDataModuleRegistroPrueba);
  sNombre := '  ' + LowerCase(
    TDataModuleRegistroPrueba.QualifiedClassName) + '  ';
  Assert.IsTrue(
    ClaseDataModule(sNombre) = TDataModuleRegistroPrueba);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasRegistroPantallas);

end.
