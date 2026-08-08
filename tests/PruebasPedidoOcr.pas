{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPedidoOcr                                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la lectura y consolidación del contrato JSON del extractor OCR. }
{******************************************************************************}
unit PruebasPedidoOcr;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasPedidoOcr = class
  private
    FFichero: string;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Cargar_ConsolidaModeloColorYPrecio;
    [Test]
    procedure NormalizarTalla_IgnoraEspaciosYComaDecimal;
    [Test]
    procedure Cargar_SinLineasImportablesGeneraError;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  inLibPedidoOcr;

procedure TPruebasPedidoOcr.Preparar;
begin
  FFichero := TPath.GetTempFileName;
end;

procedure TPruebasPedidoOcr.Limpiar;
begin
  if TFile.Exists(FFichero) then
    TFile.Delete(FFichero);
end;

procedure TPruebasPedidoOcr.Cargar_ConsolidaModeloColorYPrecio;
const
  JSON_PEDIDO =
    '{"proveedor":{"razon_social":"WONDERS"},' +
    '"referencia_doc":"P-1","detalle":[' +
    '{"modelo":"A-1","descripcion":"Zapato","color":"NEGRO",' +
    '"color_detectado":"negro","codigo_foto":"FOTO-1",' +
    '"tallas":[{"talla":"37","cantidad":1}],' +
    '"precio_unitario":20,"pvp":49.95,"moneda":"EUR"},' +
    '{"modelo":"A-1","descripcion":"Zapato","color":"NEGRO",' +
    '"color_detectado":"negro","codigo_foto":"FOTO-2",' +
    '"tallas":[{"talla":"37","cantidad":2},' +
    '{"talla":"38","cantidad":1}],' +
    '"precio_unitario":20,"pvp":49.95,"moneda":"EUR"},' +
    '{"modelo":"VACIA","color":"BLACK","tallas":[],' +
    '"cantidad":0,"precio_unitario":20}]}';
var
  Pedido: TPedidoOcr;
begin
  TFile.WriteAllText(FFichero, JSON_PEDIDO, TEncoding.UTF8);
  Pedido := TLectorPedidoOcr.Cargar(FFichero);
  Assert.AreEqual(1, Length(Pedido.Lineas));
  Assert.AreEqual('FOTO-1', Pedido.Lineas[0].CodigoFoto);
  Assert.AreEqual(2, Length(Pedido.Lineas[0].Tallas));
  Assert.AreEqual(3.0, Pedido.Lineas[0].Tallas[0].Cantidad, 0.001);
  Assert.AreEqual(1.0, Pedido.Lineas[0].Tallas[1].Cantidad, 0.001);
  Assert.AreEqual(4.0, Pedido.Lineas[0].Cantidad, 0.001);
end;

procedure TPruebasPedidoOcr.
  NormalizarTalla_IgnoraEspaciosYComaDecimal;
begin
  Assert.AreEqual('382/3', NormalizarTallaPedido(' 38 2/3 '));
  Assert.AreEqual('37.5', NormalizarTallaPedido('37,5'));
end;

procedure TPruebasPedidoOcr.Cargar_SinLineasImportablesGeneraError;
var
  Pedido: TPedidoOcr;
begin
  TFile.WriteAllText(
    FFichero,
    '{"detalle":[{"modelo":"VACIA","tallas":[],' +
    '"cantidad":0}]}',
    TEncoding.UTF8);
  Assert.WillRaise(
    procedure
    begin
      Pedido := TLectorPedidoOcr.Cargar(FFichero);
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPedidoOcr);

end.
