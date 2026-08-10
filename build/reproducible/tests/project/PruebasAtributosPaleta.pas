{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasAtributosPaleta                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de la consulta común de básicos usados por un artículo.           }
{******************************************************************************}
unit PruebasAtributosPaleta;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasAtributosPaleta = class
  public
    [Test]
    procedure SqlBasicos_ConservaRelacionesYActivos;
    [Test]
    procedure ObtenerBasicos_SinArticuloNoConsulta;
  end;

implementation

uses
  System.SysUtils, inLibAtributosPaleta,
  UniDataAtributosPaletaRepositorio;

procedure TPruebasAtributosPaleta.
  SqlBasicos_ConservaRelacionesYActivos;
var
  sSql: string;
begin
  sSql := SqlBasicosArticuloAtributosPaleta;
  Assert.IsTrue(Pos('FROM fza_articulos_skus SK', sSql) > 0);
  Assert.IsTrue(Pos('AV.ID_VA_AV = :va', sSql) > 0);
  Assert.IsTrue(Pos('SK.CODIGO_ART_SKU = :art', sSql) > 0);
  Assert.IsTrue(Pos('COALESCE(SK.ESACTIVO_SKU', sSql) > 0);
  Assert.IsTrue(Pos('COALESCE(AV.ESACTIVO_AV', sSql) > 0);
  Assert.IsTrue(Pos('COALESCE(ATB.ESACTIVO_ATB', sSql) > 0);
  Assert.IsTrue(Pos(
    'ORDER BY ORDEN_ATB, NOMBRE_ATB, ATB.CODIGO_ATB',
    sSql) > 0);
end;

procedure TPruebasAtributosPaleta.
  ObtenerBasicos_SinArticuloNoConsulta;
begin
  Assert.IsTrue(Length(
    ObtenerBasicosArticulo(nil, '  ', 'CO')) = 0);
end;

end.
