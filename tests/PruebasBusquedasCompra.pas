{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasBusquedasCompra                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los contratos comunes de búsqueda de compras.                  }
{******************************************************************************}
unit PruebasBusquedasCompra;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasBusquedasCompra = class
  public
    [Test]
    procedure SqlArticulos_ConservaProveedorYActivos;
    [Test]
    procedure SqlSku_ConservaAtributosYActivos;
    [Test]
    procedure ValorTexto_ValidaEstadoYCampo;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibBusquedasCompra;

procedure TPruebasBusquedasCompra.
  SqlArticulos_ConservaProveedorYActivos;
var
  sSql: string;
begin
  sSql := SqlBusquedaArticulosProveedorCompra;
  Assert.IsTrue(Pos('FROM fza_articulos_proveedores ap', sSql) > 0);
  Assert.IsTrue(Pos('ap.CODIGO_PRV_AP = :prv', sSql) > 0);
  Assert.IsTrue(Pos('COALESCE(art.ESACTIVO_ART', sSql) > 0);
  Assert.IsTrue(Pos('ap.REF_PROVEEDOR_AP AS REF_PROVEEDOR',
    sSql) > 0);
  Assert.AreEqual('', BuscarArticuloProveedorCompra(
    nil, 'PRV1', '', '', nil));
end;

procedure TPruebasBusquedasCompra.
  SqlSku_ConservaAtributosYActivos;
var
  sSql: string;
begin
  sSql := SqlBusquedaSkuCompra;
  Assert.IsTrue(Pos('FROM fza_articulos_skus SK', sSql) > 0);
  Assert.IsTrue(Pos('SK.CODIGO_ART_SKU = :art', sSql) > 0);
  Assert.IsTrue(Pos('COALESCE(SK.ESACTIVO_SKU', sSql) > 0);
  Assert.IsTrue(Pos('GROUP_CONCAT(AV.AV', sSql) > 0);
  Assert.AreEqual('', BuscarSkuArticuloCompra(
    nil, 'ART1', '', '', nil));
end;

procedure TPruebasBusquedasCompra.
  ValorTexto_ValidaEstadoYCampo;
var
  oDataSet: TClientDataSet;
begin
  Assert.AreEqual('', ValorTextoDataSetCompra(nil, 'CODIGO'));
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('CODIGO', ftString, 20);
    oDataSet.CreateDataSet;
    Assert.AreEqual('',
      ValorTextoDataSetCompra(oDataSet, 'CODIGO'));
    oDataSet.Append;
    oDataSet.FieldByName('CODIGO').AsString := ' ART1 ';
    oDataSet.Post;
    Assert.AreEqual('ART1',
      ValorTextoDataSetCompra(oDataSet, 'CODIGO'));
    Assert.AreEqual('',
      ValorTextoDataSetCompra(oDataSet, 'INEXISTENTE'));
    oDataSet.Close;
    Assert.AreEqual('',
      ValorTextoDataSetCompra(oDataSet, 'CODIGO'));
  finally
    oDataSet.Free;
  end;
end;

end.
