{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasFiltrosStockConsulta                                   }
{    Tipo:       Pruebas DUnitX                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Prueba las reglas puras y el contrato del presentador de filtros.         }
{******************************************************************************}
unit PruebasFiltrosStockConsulta;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFiltrosStockConsulta = class
  public
    [Test]
    procedure AlmacenEstandarSeSelecciona;
    [Test]
    procedure AlmacenEstandardConservaCompatibilidad;
    [Test]
    procedure AlmacenDeVentaNoSeSelecciona;
    [Test]
    procedure TextoCompuestoDevuelveCodigoAlmacen;
    [Test]
    procedure TextoSinSeparadorSeConserva;
    [Test]
    procedure ColorSinFiltroSkuSeSelecciona;
    [Test]
    procedure ColorAjenoAlSkuNoSeSelecciona;
    [Test]
    procedure ConstructorSinControlesFallaRapido;
  end;

implementation

uses
  System.SysUtils,
  inMtoStockConsultaPresentacionFiltrosVcl;

procedure TPruebasFiltrosStockConsulta.AlmacenEstandarSeSelecciona;
begin
  Assert.IsTrue(EsTipoAlmacenSeleccionadoPorDefecto('ESTANDAR'));
end;

procedure TPruebasFiltrosStockConsulta.
  AlmacenEstandardConservaCompatibilidad;
begin
  Assert.IsTrue(EsTipoAlmacenSeleccionadoPorDefecto('ESTANDARD'));
end;

procedure TPruebasFiltrosStockConsulta.AlmacenDeVentaNoSeSelecciona;
begin
  Assert.IsFalse(EsTipoAlmacenSeleccionadoPorDefecto('VENTA'));
end;

procedure TPruebasFiltrosStockConsulta.TextoCompuestoDevuelveCodigoAlmacen;
begin
  Assert.AreEqual(
    'A01',
    ExtraerCodigoAlmacenFiltro('A01 - Almacen central'));
end;

procedure TPruebasFiltrosStockConsulta.TextoSinSeparadorSeConserva;
begin
  Assert.AreEqual(
    'A01',
    ExtraerCodigoAlmacenFiltro('A01'));
end;

procedure TPruebasFiltrosStockConsulta.ColorSinFiltroSkuSeSelecciona;
begin
  Assert.IsTrue(DebeSeleccionarColorFiltro(False, False));
end;

procedure TPruebasFiltrosStockConsulta.ColorAjenoAlSkuNoSeSelecciona;
begin
  Assert.IsFalse(DebeSeleccionarColorFiltro(True, False));
end;

procedure TPruebasFiltrosStockConsulta.ConstructorSinControlesFallaRapido;
var
  Presentador: TPresentadorFiltrosListaStock;
  FalloEsperado: Boolean;
begin
  Presentador := nil;
  FalloEsperado := False;
  try
    Presentador := TPresentadorFiltrosListaStock.Create(nil, nil, nil);
  except
    on E: EArgumentNilException do
      FalloEsperado := True;
  end;
  Presentador.Free;
  Assert.IsTrue(FalloEsperado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFiltrosStockConsulta);

end.
