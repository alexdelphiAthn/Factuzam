{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRectificativas                                        }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de la exclusión de facturas simplificadas sustituidas.            }
{******************************************************************************}
unit PruebasRectificativas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRectificativas = class
  public
    [Test]
    procedure Filtro_ExcluyeSoloSimplificadaSustitutiva;
    [Test]
    procedure Filtro_UsaLosCamposIndicados;
    [Test]
    procedure Movimientos_SustitutivaNoSeDuplican;
  end;

implementation

uses
  System.SysUtils, inLibRectificativas;

procedure TPruebasRectificativas.
  Filtro_ExcluyeSoloSimplificadaSustitutiva;
var
  sSql: string;
begin
  sSql := SQLExcluirSimplificadaSustituida('o.EMP', 'o.SERIE', 'o.NUMERO');
  Assert.IsTrue(Pos('fo.TIPO_FAC = ''SIMPLIFICADA''', sSql) > 0);
  Assert.IsTrue(Pos('fo.FASE_FAC = ''RECTIFICADA''', sSql) > 0);
  Assert.IsTrue(Pos('fs.TIPO_RECTIFICATIVA_FAC = ''S''', sSql) > 0);
  Assert.IsFalse(Pos('fs.TIPO_RECTIFICATIVA_FAC = ''I''', sSql) > 0);
end;

procedure TPruebasRectificativas.Filtro_UsaLosCamposIndicados;
var
  sSql: string;
begin
  sSql := SQLExcluirSimplificadaSustituida(
    'ope.EMPRESA', 'ope.SERIE', 'ope.NUMERO');
  Assert.IsTrue(Pos('fo.CODIGO_EMP_FAC = ope.EMPRESA', sSql) > 0);
  Assert.IsTrue(Pos('fo.SERIE_FAC = ope.SERIE', sSql) > 0);
  Assert.IsTrue(Pos('fo.NUMERO_FAC = ope.NUMERO', sSql) > 0);
end;

procedure TPruebasRectificativas.Movimientos_SustitutivaNoSeDuplican;
begin
  Assert.IsTrue(DebeGenerarMovimientosRectificativa('', False));
  Assert.IsTrue(DebeGenerarMovimientosRectificativa('I', False));
  Assert.IsFalse(DebeGenerarMovimientosRectificativa('S', False));
  Assert.IsTrue(DebeGenerarMovimientosRectificativa('S', True));
end;

end.
