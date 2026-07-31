{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasInventariosEntrada                                     }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las decisiones de entrada de artículos en inventarios.         }
{******************************************************************************}
unit PruebasInventariosEntrada;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInventariosEntrada = class
  public
    [Test]
    procedure SkuResuelto_CargaStockYAtributos;
    [Test]
    procedure ArticuloSimple_CargaStockSinAtributos;
    [Test]
    procedure PadreConVariaciones_EsperaAtributos;
  end;

implementation

uses
  inLibInventariosEntrada;

procedure TPruebasInventariosEntrada.SkuResuelto_CargaStockYAtributos;
var
  Decision: TDecisionEntradaInventario;
begin
  Decision := ResolverEntradaInventario('ART1', 'SKU1', 2);
  Assert.AreEqual('SKU1', Decision.CodigoUnidad);
  Assert.IsTrue(Decision.CargarStock);
  Assert.IsTrue(Decision.RellenarAtributos);
end;

procedure TPruebasInventariosEntrada.ArticuloSimple_CargaStockSinAtributos;
var
  Decision: TDecisionEntradaInventario;
begin
  Decision := ResolverEntradaInventario('ART1', '', 0);
  Assert.AreEqual('ART1', Decision.CodigoUnidad);
  Assert.IsTrue(Decision.CargarStock);
  Assert.IsFalse(Decision.RellenarAtributos);
end;

procedure TPruebasInventariosEntrada.PadreConVariaciones_EsperaAtributos;
var
  Decision: TDecisionEntradaInventario;
begin
  Decision := ResolverEntradaInventario('ART1', '', 2);
  Assert.AreEqual('ART1', Decision.CodigoUnidad);
  Assert.IsFalse(Decision.CargarStock);
  Assert.IsFalse(Decision.RellenarAtributos);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInventariosEntrada);

end.
