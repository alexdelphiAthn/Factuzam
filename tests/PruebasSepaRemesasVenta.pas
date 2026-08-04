{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasSepaRemesasVenta                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas puras de identificadores SEPA usados por remesas de venta.        }
{******************************************************************************}
unit PruebasSepaRemesasVenta;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasSepaRemesasVenta = class
  public
    [Test]
    procedure CodigoAcreedor_CalculaYValidaNifEspanol;
    [Test]
    procedure CodigoAcreedor_RechazaValorEspanolIncompleto;
  end;

implementation

uses
  inLibSepaRemesasVenta;

procedure TPruebasSepaRemesasVenta.
  CodigoAcreedor_CalculaYValidaNifEspanol;
var
  sCodigo: string;
begin
  sCodigo := CalcularCodigoAcreedorSepaEspanol('12345678Z');
  Assert.IsTrue(CodigoAcreedorSepaValido(sCodigo));
end;

procedure TPruebasSepaRemesasVenta.
  CodigoAcreedor_RechazaValorEspanolIncompleto;
begin
  Assert.IsFalse(CodigoAcreedorSepaValido('ES00'));
  Assert.IsFalse(CodigoAcreedorSepaValido('000000'));
end;

end.
