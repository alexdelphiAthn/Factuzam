{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasMetodosLargosOla20B                                  }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza el cálculo de bases usado al cargar depósitos en caja.       }
{******************************************************************************}
unit PruebasMetodosLargosOla20B;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasMetodosLargosOla20B = class
  public
    [Test]
    procedure ImporteSinIva_CuotaCeroConservaElImporte;
    [Test]
    procedure ImporteSinIva_CuotaGeneralRecuperaLaBase;
    [Test]
    procedure ImporteSinIva_ImporteNegativoConservaElSigno;
    [Test]
    procedure ImporteSinIva_CuotaMenosCienDevuelveMinimoCurrency;
  end;

implementation

uses
  inLibCajaDepositos;

const
  CMinimoCurrency: Currency = -922337203685477.5808;

procedure TPruebasMetodosLargosOla20B.
  ImporteSinIva_CuotaCeroConservaElImporte;
begin
  Assert.AreEqual<Currency>(
    47.5,
    CalcularImporteSinIvaDeposito(47.5, 0));
end;

procedure TPruebasMetodosLargosOla20B.
  ImporteSinIva_CuotaGeneralRecuperaLaBase;
begin
  Assert.AreEqual<Currency>(
    100,
    CalcularImporteSinIvaDeposito(121, 21));
end;

procedure TPruebasMetodosLargosOla20B.
  ImporteSinIva_ImporteNegativoConservaElSigno;
begin
  Assert.AreEqual<Currency>(
    -100,
    CalcularImporteSinIvaDeposito(-121, 21));
end;

procedure TPruebasMetodosLargosOla20B.
  ImporteSinIva_CuotaMenosCienDevuelveMinimoCurrency;
begin
  Assert.AreEqual<Currency>(
    CMinimoCurrency,
    CalcularImporteSinIvaDeposito(100, -100));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasMetodosLargosOla20B);

end.
