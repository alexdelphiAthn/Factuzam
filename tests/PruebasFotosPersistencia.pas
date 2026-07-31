{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFotosPersistencia                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la composicion segregada y los prefijos de fotos sin BBDD.       }
{******************************************************************************}
unit PruebasFotosPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFotosPersistencia = class
  public
    [Test]
    procedure ServiciosVacios_NoAsignanNingunPuerto;
    [Test]
    procedure PrefijosSku_OrdenaDeMasAMenosEspecifico;
  end;

implementation

uses
  inLibFotosPersistenciaIntf, inLibFotos;

procedure TPruebasFotosPersistencia.
  ServiciosVacios_NoAsignanNingunPuerto;
var
  Repositorios: TRepositoriosFotos;
begin
  Repositorios := Default(TRepositoriosFotos);
  Assert.IsFalse(Assigned(Repositorios.Consulta));
  Assert.IsFalse(Assigned(Repositorios.Edicion));
  Assert.IsFalse(Assigned(Repositorios.Sesion));
end;

procedure TPruebasFotosPersistencia.
  PrefijosSku_OrdenaDeMasAMenosEspecifico;
var
  Prefijos: TArray<string>;
begin
  Prefijos := GenerarPrefijosSku('BLUS-SEDA/BLANCO/L');
  Assert.AreEqual(2, Integer(Length(Prefijos)));
  Assert.AreEqual('BLUS-SEDA/BLANCO/L', Prefijos[0]);
  Assert.AreEqual('BLUS-SEDA/BLANCO', Prefijos[1]);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosPersistencia);

end.
