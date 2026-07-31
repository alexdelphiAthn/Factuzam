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
{    Pruebas de la exclusión de ventas anuladas o sustituidas.                 }
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
    procedure Filtro_ExcluyeVentasAnuladas;
    [Test]
    procedure Filtro_ExcluyeAnulacionEnCola;
    [Test]
    procedure Filtro_ExcluyeSimplificadaSustitutiva;
    [Test]
    procedure Filtro_UsaLosCamposIndicados;
    [Test]
    procedure Movimientos_SustitutivaNoSeDuplican;
  end;

implementation

uses
  System.SysUtils, inLibRectificativas;

procedure TPruebasRectificativas.
  Filtro_ExcluyeVentasAnuladas;
var
  sSql: string;
begin
  sSql := SQLExcluirVentaRetirada('o.EMP', 'o.SERIE', 'o.NUMERO');
  Assert.IsTrue(Pos('''SIN_VERIF_ANULADA''', sSql) > 0);
  Assert.IsTrue(Pos('''VERIFACTU_ANULADA''', sSql) > 0);
  Assert.IsTrue(Pos('''NOVERIFACTU_ANULADA''', sSql) > 0);
end;

procedure TPruebasRectificativas.Filtro_ExcluyeAnulacionEnCola;
var
  sSql: string;
begin
  sSql := SQLExcluirVentaRetirada('o.EMP', 'o.SERIE', 'o.NUMERO');
  Assert.IsTrue(Pos('fza_verifactu_cola va', sSql) > 0);
  Assert.IsTrue(
    Pos('va.TIPO_OPERACION_VFCOLA = ''ANULACION''', sSql) > 0);
end;

procedure TPruebasRectificativas.
  Filtro_ExcluyeSimplificadaSustitutiva;
var
  sSql: string;
begin
  sSql := SQLExcluirVentaRetirada('o.EMP', 'o.SERIE', 'o.NUMERO');
  Assert.IsTrue(Pos('fo.TIPO_FAC = ''SIMPLIFICADA''', sSql) > 0);
  Assert.IsTrue(Pos('fo.FASE_FAC = ''RECTIFICADA''', sSql) > 0);
  Assert.IsTrue(Pos('fs.TIPO_RECTIFICATIVA_FAC = ''S''', sSql) > 0);
  Assert.IsFalse(Pos('fs.TIPO_RECTIFICATIVA_FAC = ''I''', sSql) > 0);
end;

procedure TPruebasRectificativas.Filtro_UsaLosCamposIndicados;
var
  sSql: string;
begin
  sSql := SQLExcluirVentaRetirada(
    'ope.EMPRESA', 'ope.SERIE', 'ope.NUMERO');
  Assert.IsTrue(Pos('fa.CODIGO_EMP_FAC = ope.EMPRESA', sSql) > 0);
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
