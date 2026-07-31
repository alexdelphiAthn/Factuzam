{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGridPivoteCompraPersistencia                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la composicion segregada del pivote sin BBDD.                    }
{******************************************************************************}
unit PruebasGridPivoteCompraPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasGridPivoteCompraPersistencia = class
  public
    [Test]
    procedure ServiciosVacios_NoAsignanNingunPuerto;
  end;

implementation

uses
  inLibGridPivoteCompraPersistenciaIntf;

procedure TPruebasGridPivoteCompraPersistencia.
  ServiciosVacios_NoAsignanNingunPuerto;
var
  Repositorios: TRepositoriosGridPivoteCompra;
begin
  Repositorios := Default(TRepositoriosGridPivoteCompra);
  Assert.IsFalse(Assigned(Repositorios.Configuracion));
  Assert.IsFalse(Assigned(Repositorios.Colores));
  Assert.IsFalse(Assigned(Repositorios.Validacion));
  Assert.IsFalse(Assigned(Repositorios.Lineas));
  Assert.IsFalse(Assigned(Repositorios.Skus));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasGridPivoteCompraPersistencia);

end.
