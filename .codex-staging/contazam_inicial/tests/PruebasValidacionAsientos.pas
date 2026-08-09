{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasValidacionAsientos                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Pruebas unitarias de las reglas puras del libro diario.                  }
{******************************************************************************}
unit PruebasValidacionAsientos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasValidacionAsientos = class
  public
    [Test]
    procedure AsientoCuadrado_EsValido;
    [Test]
    procedure AsientoConUnApunte_NoEsValido;
    [Test]
    procedure ApunteConDebeYHaber_NoEsValido;
    [Test]
    procedure AsientoDescuadrado_NoEsValido;
  end;

implementation

uses
  inLibContabilidadTipos, inLibValidacionAsientos;

procedure TPruebasValidacionAsientos.ApunteConDebeYHaber_NoEsValido;
var
  aLineas: TArray<TLineaAsiento>;
  oResultado: TResultadoValidacionAsiento;
begin
  SetLength(aLineas, 2);
  aLineas[0].Cuenta := '430000000000';
  aLineas[0].Debe := 121;
  aLineas[0].Haber := 21;
  aLineas[1].Cuenta := '700000000000';
  aLineas[1].Haber := 100;
  oResultado := TValidadorAsientos.Validar(aLineas);
  Assert.AreEqual(evaImporteInvalido, oResultado.Estado);
end;

procedure TPruebasValidacionAsientos.AsientoConUnApunte_NoEsValido;
var
  aLineas: TArray<TLineaAsiento>;
  oResultado: TResultadoValidacionAsiento;
begin
  SetLength(aLineas, 1);
  aLineas[0].Cuenta := '572000000000';
  aLineas[0].Debe := 100;
  oResultado := TValidadorAsientos.Validar(aLineas);
  Assert.AreEqual(evaSinLineasSuficientes, oResultado.Estado);
end;

procedure TPruebasValidacionAsientos.AsientoCuadrado_EsValido;
var
  aLineas: TArray<TLineaAsiento>;
  oResultado: TResultadoValidacionAsiento;
begin
  SetLength(aLineas, 3);
  aLineas[0].Cuenta := '430000000000';
  aLineas[0].Debe := 121;
  aLineas[1].Cuenta := '700000000000';
  aLineas[1].Haber := 100;
  aLineas[2].Cuenta := '477000000000';
  aLineas[2].Haber := 21;
  oResultado := TValidadorAsientos.Validar(aLineas);
  Assert.IsTrue(oResultado.EsValido);
  Assert.AreEqual(Currency(121), oResultado.TotalDebe);
  Assert.AreEqual(Currency(121), oResultado.TotalHaber);
end;

procedure TPruebasValidacionAsientos.AsientoDescuadrado_NoEsValido;
var
  aLineas: TArray<TLineaAsiento>;
  oResultado: TResultadoValidacionAsiento;
begin
  SetLength(aLineas, 2);
  aLineas[0].Cuenta := '430000000000';
  aLineas[0].Debe := 121;
  aLineas[1].Cuenta := '700000000000';
  aLineas[1].Haber := 100;
  oResultado := TValidadorAsientos.Validar(aLineas);
  Assert.AreEqual(evaDescuadrado, oResultado.Estado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasValidacionAsientos);

end.
