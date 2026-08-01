{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosVisibilidad                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las reglas de visibilidad de columnas de artículos.           }
{******************************************************************************}
unit PruebasArticulosVisibilidad;

interface

uses
  Data.DB, Datasnap.DBClient, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosVisibilidad = class
  private
    FTarifas: TClientDataSet;
    FSkus: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure SinDatos_OcultaColumnas;
    [Test]
    procedure TarifaConSku_MuestraColumnaSku;
    [Test]
    procedure PrecioSku_MuestraColumnasCompra;
    [Test]
    procedure Evaluar_ConservaRegistrosActivos;
  end;

implementation

uses
  System.SysUtils, inLibArticulosVisibilidad;

procedure TPruebasArticulosVisibilidad.Preparar;
begin
  FTarifas := TClientDataSet.Create(nil);
  FTarifas.FieldDefs.Add('CODIGO_UNIDAD_ARTTAR', ftString, 40);
  FTarifas.CreateDataSet;
  FSkus := TClientDataSet.Create(nil);
  FSkus.FieldDefs.Add('PRECIO_ULT_COMPRA_SKUC', ftFloat);
  FSkus.CreateDataSet;
end;

procedure TPruebasArticulosVisibilidad.Limpiar;
begin
  FreeAndNil(FSkus);
  FreeAndNil(FTarifas);
end;

procedure TPruebasArticulosVisibilidad.SinDatos_OcultaColumnas;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsFalse(Visibilidad.MostrarSkuTarifa);
  Assert.IsFalse(Visibilidad.MostrarCompraSku);
end;

procedure TPruebasArticulosVisibilidad.TarifaConSku_MuestraColumnaSku;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  FTarifas.AppendRecord(['']);
  FTarifas.AppendRecord(['ART-1/ROJO/L']);
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsTrue(Visibilidad.MostrarSkuTarifa);
  Assert.IsFalse(Visibilidad.MostrarCompraSku);
end;

procedure TPruebasArticulosVisibilidad.PrecioSku_MuestraColumnasCompra;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  FSkus.AppendRecord([0]);
  FSkus.AppendRecord([12.5]);
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsFalse(Visibilidad.MostrarSkuTarifa);
  Assert.IsTrue(Visibilidad.MostrarCompraSku);
end;

procedure TPruebasArticulosVisibilidad.Evaluar_ConservaRegistrosActivos;
var
  Visibilidad: TVisibilidadColumnasArticulo;
  iTarifaActiva: Integer;
  iSkuActivo: Integer;
begin
  FTarifas.AppendRecord(['ART-1/ROJO/L']);
  FTarifas.AppendRecord(['ART-1/AZUL/M']);
  FTarifas.First;
  FSkus.AppendRecord([10]);
  FSkus.AppendRecord([20]);
  FSkus.First;
  iTarifaActiva := FTarifas.RecNo;
  iSkuActivo := FSkus.RecNo;
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsTrue(Visibilidad.MostrarSkuTarifa);
  Assert.IsTrue(Visibilidad.MostrarCompraSku);
  Assert.AreEqual(iTarifaActiva, FTarifas.RecNo);
  Assert.AreEqual(iSkuActivo, FSkus.RecNo);
end;

end.
