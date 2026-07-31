{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDocumento                                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de configuración y estrategia de la familia de documentos.        }
{******************************************************************************}
unit PruebasDocumento;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasDocumento = class
  public
    [Test]
    procedure Albaranes_ConfiguranCompraYVenta;
    [Test]
    procedure Pedidos_NoMuevenStock;
    [Test]
    procedure FacturaVenta_EmiteVerifactuYAsiento;
    [Test]
    procedure FacturaCompra_NoDuplicaMovimientoDelAlbaran;
    [Test]
    procedure DevolucionCompra_InvierteStock;
    [Test]
    procedure Estrategia_CalculaImportes;
    [Test]
    procedure Estrategia_EliminaImpuestosIncluidos;
    [Test]
    procedure Estrategia_FormateaNumeracion;
  end;

implementation

uses
  inLibDocumento, inLibDocumentoIntf;

procedure TPruebasDocumento.Albaranes_ConfiguranCompraYVenta;
var
  oCompra: TConfiguracionDocumento;
  oVenta: TConfiguracionDocumento;
begin
  oCompra := CrearConfiguracionDocumento(tdAlbaran, sdCompra);
  oVenta := CrearConfiguracionDocumento(tdAlbaran, sdVenta);
  Assert.AreEqual('fza_albaranes_compra', oCompra.TablaCabecera);
  Assert.AreEqual('ALBCLIN', oCompra.PrefijoLineas);
  Assert.AreEqual(1, oCompra.SignoStock);
  Assert.AreEqual('AB', oCompra.TipoContador);
  Assert.AreEqual('AC', oCompra.TipoDocumentoMovimientoStock);
  Assert.AreEqual('fza_albaranes', oVenta.TablaCabecera);
  Assert.AreEqual('ALBLIN', oVenta.PrefijoLineas);
  Assert.AreEqual(-1, oVenta.SignoStock);
  Assert.AreEqual('AV', oVenta.TipoContador);
  Assert.AreEqual('AV', oVenta.TipoDocumentoMovimientoStock);
end;

procedure TPruebasDocumento.Pedidos_NoMuevenStock;
var
  oConfiguracion: TConfiguracionDocumento;
  oEstrategia: IEstrategiaDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(tdPedido, sdCompra);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  Assert.IsFalse(oConfiguracion.MueveStock);
  Assert.AreEqual(0, oConfiguracion.SignoStock);
  Assert.AreEqual(
    0.0,
    Double(oEstrategia.CantidadMovimientoStock(12)),
    0.0001);
  Assert.AreEqual('', oEstrategia.TipoDocumentoMovimientoStock);
  Assert.AreEqual('', oEstrategia.TipoMovimientoStock);
end;

procedure TPruebasDocumento.FacturaVenta_EmiteVerifactuYAsiento;
var
  oConfiguracion: TConfiguracionDocumento;
  oEstrategia: IEstrategiaDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(tdFactura, sdVenta);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  Assert.AreEqual('FAC', oConfiguracion.PrefijoCabecera);
  Assert.AreEqual('FC', oConfiguracion.TipoContador);
  Assert.IsTrue(oEstrategia.DebeEmitirVerifactu);
  Assert.IsTrue(oEstrategia.DebeGenerarAsiento);
end;

procedure TPruebasDocumento.FacturaCompra_NoDuplicaMovimientoDelAlbaran;
var
  oConfiguracion: TConfiguracionDocumento;
  oEstrategia: IEstrategiaDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(tdFactura, sdCompra);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  Assert.IsFalse(oConfiguracion.MueveStock);
  Assert.AreEqual(0, oConfiguracion.SignoStock);
  Assert.AreEqual('', oEstrategia.TipoDocumentoMovimientoStock);
  Assert.AreEqual('', oEstrategia.TipoMovimientoStock);
  Assert.IsTrue(oEstrategia.DebeGenerarAsiento);
  Assert.IsFalse(oEstrategia.DebeEmitirVerifactu);
end;

procedure TPruebasDocumento.DevolucionCompra_InvierteStock;
var
  oConfiguracion: TConfiguracionDocumento;
  oEstrategia: IEstrategiaDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(
    tdDevolucion,
    sdCompra);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  Assert.AreEqual('DEVC', oConfiguracion.PrefijoCabecera);
  Assert.AreEqual(
    -3.0,
    Double(oEstrategia.CantidadMovimientoStock(3)),
    0.0001);
  Assert.AreEqual('DC', oEstrategia.TipoDocumentoMovimientoStock);
  Assert.AreEqual('S', oEstrategia.TipoMovimientoStock);
end;

procedure TPruebasDocumento.Estrategia_CalculaImportes;
var
  oConfiguracion: TConfiguracionDocumento;
  oEntrada: TEntradaCalculoDocumento;
  oEstrategia: IEstrategiaDocumento;
  oResultado: TResultadoCalculoDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(tdAlbaran, sdVenta);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  oEntrada := Default(TEntradaCalculoDocumento);
  oEntrada.Cantidad := 2;
  oEntrada.Precio := 100;
  oEntrada.PorcentajeDescuento := 10;
  oEntrada.PorcentajeImpuesto := 21;
  oResultado := oEstrategia.CalcularLinea(oEntrada);
  Assert.AreEqual(90.0, Double(oResultado.PrecioNeto), 0.0001);
  Assert.AreEqual(180.0, Double(oResultado.BaseImponible), 0.0001);
  Assert.AreEqual(37.8, Double(oResultado.CuotaImpuesto), 0.0001);
  Assert.AreEqual(217.8, Double(oResultado.Total), 0.0001);
end;

procedure TPruebasDocumento.Estrategia_EliminaImpuestosIncluidos;
var
  oConfiguracion: TConfiguracionDocumento;
  oEntrada: TEntradaCalculoDocumento;
  oEstrategia: IEstrategiaDocumento;
  oResultado: TResultadoCalculoDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(tdFactura, sdVenta);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  oEntrada := Default(TEntradaCalculoDocumento);
  oEntrada.Cantidad := 1;
  oEntrada.Precio := 121;
  oEntrada.PorcentajeImpuesto := 21;
  oEntrada.PrecioIncluyeImpuestos := True;
  oResultado := oEstrategia.CalcularLinea(oEntrada);
  Assert.AreEqual(100.0, Double(oResultado.PrecioNeto), 0.0001);
  Assert.AreEqual(121.0, Double(oResultado.Total), 0.0001);
end;

procedure TPruebasDocumento.Estrategia_FormateaNumeracion;
var
  oConfiguracion: TConfiguracionDocumento;
  oEstrategia: IEstrategiaDocumento;
begin
  oConfiguracion := CrearConfiguracionDocumento(tdPedido, sdVenta);
  oEstrategia := CrearEstrategiaDocumento(oConfiguracion);
  Assert.AreEqual('42', oEstrategia.FormatearNumero(42));
end;

end.
