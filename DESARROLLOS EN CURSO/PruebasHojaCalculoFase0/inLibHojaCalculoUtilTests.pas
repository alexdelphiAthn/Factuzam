{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoUtilTests                                     }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los helpers puros de inLibHojaCalculoUtil. No dependen de      }
{    DevExpress ni de UI, por eso corren en cualquier runner de consola.       }
{******************************************************************************}
unit inLibHojaCalculoUtilTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasHojaCalculoUtil = class
  public
    [Test]
    procedure ColumnaALetras_PrimeraColumnaEsA;
    [Test]
    procedure ColumnaALetras_VeintiseisEsAA;
    [Test]
    procedure ColumnaALetras_VeintisieteEsAB;
    [Test]
    procedure ReferenciaCelda_RelativaA1;
    [Test]
    procedure ReferenciaCelda_RelativaD5;
    [Test]
    procedure ReferenciaCelda_AbsolutaDobleDolar;
    [Test]
    procedure SeparadorFormula_ComaDecimalDevuelvePuntoYComa;
    [Test]
    procedure SeparadorFormula_PuntoDecimalDevuelveComa;
  end;

implementation

uses
  System.SysUtils, inLibHojaCalculoUtil;

procedure TPruebasHojaCalculoUtil.ColumnaALetras_PrimeraColumnaEsA;
begin
  Assert.AreEqual('A', ColumnaALetras(0));
end;

procedure TPruebasHojaCalculoUtil.ColumnaALetras_VeintiseisEsAA;
begin
  Assert.AreEqual('AA', ColumnaALetras(26));
end;

procedure TPruebasHojaCalculoUtil.ColumnaALetras_VeintisieteEsAB;
begin
  Assert.AreEqual('AB', ColumnaALetras(27));
end;

procedure TPruebasHojaCalculoUtil.ReferenciaCelda_RelativaA1;
begin
  Assert.AreEqual('A1', ReferenciaCelda(0, 0));
end;

procedure TPruebasHojaCalculoUtil.ReferenciaCelda_RelativaD5;
begin
  Assert.AreEqual('D5', ReferenciaCelda(4, 3));
end;

procedure TPruebasHojaCalculoUtil.ReferenciaCelda_AbsolutaDobleDolar;
begin
  Assert.AreEqual('$AA$10', ReferenciaCelda(9, 26, True));
end;

procedure TPruebasHojaCalculoUtil.SeparadorFormula_ComaDecimalDevuelvePuntoYComa;
var
  cAnterior: Char;
  sResultado: string;
begin
  cAnterior := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := ',';
    sResultado := SeparadorFormula;
    Assert.AreEqual(';', sResultado);
  finally
    FormatSettings.DecimalSeparator := cAnterior;
  end;
end;

procedure TPruebasHojaCalculoUtil.SeparadorFormula_PuntoDecimalDevuelveComa;
var
  cAnterior: Char;
  sResultado: string;
begin
  cAnterior := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := '.';
    sResultado := SeparadorFormula;
    Assert.AreEqual(',', sResultado);
  finally
    FormatSettings.DecimalSeparator := cAnterior;
  end;
end;

end.
