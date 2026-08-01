{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventarioImportTests                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prueba round-trip de ImportarInventarioDesdeSheet (Fase 3). Precarga el   }
{    doble como lector (ILectorHojaCalculo) con una hoja conocida y afirma el  }
{    parseo: detección de columnas por cabecera, fallback A=SKU/B=Cantidad,    }
{    PMP opcional y filas con SKU vacío ignoradas.                             }
{******************************************************************************}
unit inLibInventarioImportTests;

interface

uses
  DUnitX.TestFramework, inLibHojaCalculoIntf, inLibHojaCalculoFalso;

type
  [TestFixture]
  TPruebasInventarioImport = class
  private
    FFake: TEscritorHojaCalculoFalso;   // se precarga como hoja de origen
    FLector: ILectorHojaCalculo;        // dueño del ciclo de vida (refcount)
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure ConCabeceras_DetectaColumnasYLee;
    [Test]
    procedure SinCabeceras_UsaColumnasAyB;
  end;

implementation

uses
  System.SysUtils, System.Classes, inLibInventarioExcel;

procedure TPruebasInventarioImport.Preparar;
begin
  FFake := TEscritorHojaCalculoFalso.Create;
  FLector := FFake;   // refcount 0 -> 1
end;

procedure TPruebasInventarioImport.Limpiar;
begin
  FLector := nil;     // libera FFake
  FFake := nil;
end;

procedure TPruebasInventarioImport.ConCabeceras_DetectaColumnasYLee;
var
  Lineas: TLineasImportadas;
  Lista: TStringList;
  Msg: string;
begin
  FFake.Precargar(0, 0, 'SKU');
  FFake.Precargar(0, 1, 'Cantidad');
  FFake.Precargar(0, 2, 'PMP Nuevo');
  FFake.Precargar(1, 0, 'SKU-A');
  FFake.Precargar(1, 1, 5);
  FFake.Precargar(1, 2, 12);
  FFake.Precargar(2, 0, 'SKU-B');
  FFake.Precargar(2, 1, 3);
  FFake.Precargar(3, 1, 7);   // fila con SKU vacío: debe ignorarse
  Lista := nil;
  try
    ImportarInventarioDesdeSheet(FLector, Lineas, Lista, Msg);
    Assert.AreEqual(2, Lista.Count);
    Assert.AreEqual('SKU-A=5', Lista[0]);
    Assert.AreEqual('SKU-B=3', Lista[1]);
    Assert.AreEqual(2, Length(Lineas));
    Assert.AreEqual('SKU-A', Lineas[0].Sku);
    Assert.AreEqual(Double(5), Lineas[0].Cantidad, 0.001);
    Assert.IsTrue(Lineas[0].TienePmp);
    Assert.AreEqual(Double(12), Lineas[0].PmpNuevo, 0.001);
    Assert.AreEqual('SKU-B', Lineas[1].Sku);
    Assert.IsFalse(Lineas[1].TienePmp);
  finally
    Lista.Free;
  end;
end;

procedure TPruebasInventarioImport.SinCabeceras_UsaColumnasAyB;
var
  Lineas: TLineasImportadas;
  Lista: TStringList;
  Msg: string;
begin
  FFake.Precargar(0, 0, 'X1');
  FFake.Precargar(0, 1, 4);
  FFake.Precargar(1, 0, 'X2');
  FFake.Precargar(1, 1, 6);
  Lista := nil;
  try
    ImportarInventarioDesdeSheet(FLector, Lineas, Lista, Msg);
    Assert.AreEqual(2, Lista.Count);
    Assert.AreEqual('X1=4', Lista[0]);
    Assert.AreEqual('X2=6', Lista[1]);
    Assert.AreEqual(2, Length(Lineas));
  finally
    Lista.Free;
  end;
end;

end.
