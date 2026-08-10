{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasVisorPedidoOriginal                                    }
{    Tipo:       Pruebas DUnitX                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica zoom, limites de pagina y validacion del visor del pedido.       }
{******************************************************************************}
unit PruebasVisorPedidoOriginal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasVisorPedidoOriginal = class
  public
    [Test]
    procedure LimitarZoom_ConservaValorIntermedio;
    [Test]
    procedure ResolverIndice_RespetaExtremos;
    [Test]
    procedure Crear_SinControlesGeneraError;
  end;

implementation

uses
  System.SysUtils,
  inMtoComprasSesionesPresentacionPedidoOriginal;

procedure TPruebasVisorPedidoOriginal.
  LimitarZoom_ConservaValorIntermedio;
begin
  Assert.AreEqual(1.25, LimitarZoomPedidoOriginal(1.25), 0.0001);
  Assert.AreEqual(0.10, LimitarZoomPedidoOriginal(0), 0.0001);
  Assert.AreEqual(5.0, LimitarZoomPedidoOriginal(8), 0.0001);
end;

procedure TPruebasVisorPedidoOriginal.ResolverIndice_RespetaExtremos;
begin
  Assert.AreEqual(1, ResolverIndicePedidoOriginal(0, 1, 3));
  Assert.AreEqual(0, ResolverIndicePedidoOriginal(0, -1, 3));
  Assert.AreEqual(2, ResolverIndicePedidoOriginal(2, 1, 3));
  Assert.AreEqual(0, ResolverIndicePedidoOriginal(0, 1, 0));
end;

procedure TPruebasVisorPedidoOriginal.Crear_SinControlesGeneraError;
var
  Entorno: TEntornoVisorPedidoOriginalSesion;
  Visor: TVisorPedidoOriginalSesion;
begin
  Entorno := Default(TEntornoVisorPedidoOriginalSesion);
  Visor := nil;
  Assert.WillRaise(
    procedure
    begin
      Visor := TVisorPedidoOriginalSesion.Create(Entorno);
    end,
    EArgumentNilException);
  Visor.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasVisorPedidoOriginal);

end.
