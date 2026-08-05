{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPedidosVentaPresentacion                              }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Pruebas de reglas de presentación y edición de pedidos de venta.          }
{******************************************************************************}
unit PruebasPedidosVentaPresentacion;

interface

uses
  DUnitX.TestFramework,
  inLibPedidosVentaPresentacionReglas;

type
  [TestFixture]
  TPruebasPedidosVentaPresentacion = class
  public
    [Test]
    procedure ModoSkuNoDesempaquetaAtributos;
    [Test]
    procedure ModoTallasPreparaColumnasAntesDeMontar;
    [Test]
    procedure ModoDesgloseMuestraAtributos;
    [Test]
    procedure CantidadParcialConservaPendiente;
    [Test]
    procedure CantidadEntregadaNoDejaPendienteNegativo;
    [Test]
    procedure CantidadAAlbaranarSeLimitaAlPendiente;
  end;

implementation

procedure TPruebasPedidosVentaPresentacion.ModoSkuNoDesempaquetaAtributos;
var
  oPlan: TPlanModoEntradaPedidoVenta;
begin
  oPlan := CrearPlanModoEntradaPedidoVenta(mpvSku);
  Assert.IsFalse(oPlan.DesempaquetarAtributos);
  Assert.IsFalse(oPlan.MostrarAtributos);
  Assert.AreEqual('&1_Líneas [SKU]', oPlan.TituloLineas);
end;

procedure TPruebasPedidosVentaPresentacion.
  ModoTallasPreparaColumnasAntesDeMontar;
var
  oPlan: TPlanModoEntradaPedidoVenta;
begin
  oPlan := CrearPlanModoEntradaPedidoVenta(mpvTallas);
  Assert.IsTrue(oPlan.DesempaquetarAtributos);
  Assert.IsTrue(oPlan.CrearColumnasAntes);
  Assert.IsTrue(oPlan.MostrarBandaPedida);
  Assert.AreEqual('', oPlan.TituloLineas);
end;

procedure TPruebasPedidosVentaPresentacion.ModoDesgloseMuestraAtributos;
var
  oPlan: TPlanModoEntradaPedidoVenta;
begin
  oPlan := CrearPlanModoEntradaPedidoVenta(mpvDesglose);
  Assert.IsTrue(oPlan.DesempaquetarAtributos);
  Assert.IsTrue(oPlan.MostrarAtributos);
  Assert.IsFalse(oPlan.MostrarBandaPedida);
end;

procedure TPruebasPedidosVentaPresentacion.CantidadParcialConservaPendiente;
var
  oEntrada: TEntradaEstadoLineaPedidoVenta;
  oEstado: TEstadoLineaPedidoVenta;
begin
  oEntrada := Default(TEntradaEstadoLineaPedidoVenta);
  oEntrada.Cantidad := 10;
  oEntrada.CantidadEntregada := 4;
  oEntrada.CantidadAAlbaranar := 3;
  oEstado := CalcularEstadoLineaPedidoVenta(oEntrada);
  Assert.AreEqual(Double(6), oEstado.CantidadPendiente, 0.001);
  Assert.AreEqual(Double(3), oEstado.CantidadAAlbaranar, 0.001);
  Assert.IsFalse(oEstado.EsEntregada);
end;

procedure TPruebasPedidosVentaPresentacion.
  CantidadEntregadaNoDejaPendienteNegativo;
var
  oEntrada: TEntradaEstadoLineaPedidoVenta;
  oEstado: TEstadoLineaPedidoVenta;
begin
  oEntrada := Default(TEntradaEstadoLineaPedidoVenta);
  oEntrada.Cantidad := 2;
  oEntrada.CantidadEntregada := 4;
  oEstado := CalcularEstadoLineaPedidoVenta(oEntrada);
  Assert.AreEqual(Double(0), oEstado.CantidadPendiente, 0.001);
  Assert.IsTrue(oEstado.EsEntregada);
end;

procedure TPruebasPedidosVentaPresentacion.
  CantidadAAlbaranarSeLimitaAlPendiente;
var
  oEntrada: TEntradaEstadoLineaPedidoVenta;
  oEstado: TEstadoLineaPedidoVenta;
begin
  oEntrada := Default(TEntradaEstadoLineaPedidoVenta);
  oEntrada.Cantidad := 10;
  oEntrada.CantidadEntregada := 7;
  oEntrada.CantidadAAlbaranar := 9;
  oEstado := CalcularEstadoLineaPedidoVenta(oEntrada);
  Assert.AreEqual(Double(3), oEstado.CantidadAAlbaranar, 0.001);
  oEntrada.CantidadAAlbaranar := -2;
  oEstado := CalcularEstadoLineaPedidoVenta(oEntrada);
  Assert.AreEqual(Double(0), oEstado.CantidadAAlbaranar, 0.001);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPedidosVentaPresentacion);

end.
