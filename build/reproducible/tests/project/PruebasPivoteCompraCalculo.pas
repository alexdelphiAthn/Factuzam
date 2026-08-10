{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPivoteCompraCalculo                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza los cálculos puros extraídos del pivote de compra.           }
{******************************************************************************}
unit PruebasPivoteCompraCalculo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasPivoteCompraCalculo = class
  public
    [Test]
    procedure ClaveCeldaEsReversible;
    [Test]
    procedure ClaveSinTallaConservaLinea;
    [Test]
    procedure EstadosDeRecepcionCubrenLosCuatroCasos;
    [Test]
    procedure PendienteNuncaEsNegativo;
    [Test]
    procedure ARecibirSeLimitaAlPendiente;
    [Test]
    procedure PrefijoSkuEliminaLaUltimaTalla;
  end;

implementation

uses
  inLibGridPivoteCompraTipos, inLibPivoteCompraCalculo;

procedure TPruebasPivoteCompraCalculo.ClaveCeldaEsReversible;
var
  iClave: Int64;
begin
  iClave := ClaveCeldaPivoteCompra(42, 317);
  Assert.AreEqual(42, LineaClavePivoteCompra(iClave));
  Assert.AreEqual(317, AtributoClavePivoteCompra(iClave));
end;

procedure TPruebasPivoteCompraCalculo.ClaveSinTallaConservaLinea;
var
  iClave: Int64;
begin
  iClave := ClaveCeldaPivoteCompra(7, ID_AV_SIN_TALLA);
  Assert.AreEqual(7, LineaClavePivoteCompra(iClave));
  Assert.AreEqual(ID_AV_SIN_TALLA,
    AtributoClavePivoteCompra(iClave));
end;

procedure TPruebasPivoteCompraCalculo.
  EstadosDeRecepcionCubrenLosCuatroCasos;
begin
  Assert.AreEqual(Integer(efrIndefinido),
    Integer(EstadoRecepcionPivoteCompra(0, 0)));
  Assert.AreEqual(Integer(efrNada),
    Integer(EstadoRecepcionPivoteCompra(10, 0)));
  Assert.AreEqual(Integer(efrParcial),
    Integer(EstadoRecepcionPivoteCompra(10, 4)));
  Assert.AreEqual(Integer(efrTotal),
    Integer(EstadoRecepcionPivoteCompra(10, 10)));
end;

procedure TPruebasPivoteCompraCalculo.PendienteNuncaEsNegativo;
begin
  Assert.AreEqual(6.0, PendientePivoteCompra(10, 4), 0.0001);
  Assert.AreEqual(0.0, PendientePivoteCompra(10, 12), 0.0001);
end;

procedure TPruebasPivoteCompraCalculo.ARecibirSeLimitaAlPendiente;
begin
  Assert.AreEqual(0.0,
    LimitarARecibirPivoteCompra(10, 4, -2), 0.0001);
  Assert.AreEqual(3.0,
    LimitarARecibirPivoteCompra(10, 4, 3), 0.0001);
  Assert.AreEqual(6.0,
    LimitarARecibirPivoteCompra(10, 4, 9), 0.0001);
end;

procedure TPruebasPivoteCompraCalculo.PrefijoSkuEliminaLaUltimaTalla;
begin
  Assert.AreEqual('CAMISA/AZUL',
    PrefijoSkuTallaPivoteCompra('CAMISA/AZUL/XL'));
  Assert.AreEqual('', PrefijoSkuTallaPivoteCompra('CAMISA'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPivoteCompraCalculo);

end.
