{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPresentacionDocumento                                 }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los textos comunes de presentación documental.                 }
{******************************************************************************}
unit PruebasPresentacionDocumento;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasPresentacionDocumento = class
  private
    FTotal: Double;
    function ObtenerTotal: Double;
  public
    [Test]
    procedure Proveedor_ComponeNombreYRazonSocial;
    [Test]
    procedure TotalPrendas_ValidaCabeceraYFormatea;
  end;

implementation

uses
  Data.DB, Datasnap.DBClient, inLibPresentacionDocumento;

function TPruebasPresentacionDocumento.ObtenerTotal: Double;
begin
  Result := FTotal;
end;

procedure TPruebasPresentacionDocumento.
  Proveedor_ComponeNombreYRazonSocial;
var
  oCabecera: TClientDataSet;
  oProveedores: TClientDataSet;
begin
  oCabecera := TClientDataSet.Create(nil);
  oProveedores := TClientDataSet.Create(nil);
  try
    oCabecera.FieldDefs.Add('CODIGO_PRV_DOC', ftString, 20);
    oCabecera.CreateDataSet;
    oProveedores.FieldDefs.Add('CODIGO_PRV_PRV', ftString, 20);
    oProveedores.FieldDefs.Add('NOMBRE_PRV', ftString, 80);
    oProveedores.FieldDefs.Add('RAZON_SOCIAL_PRV', ftString, 80);
    oProveedores.CreateDataSet;
    oCabecera.AppendRecord(['PR1']);
    oProveedores.AppendRecord(['PR1', 'Comercial', 'Razón legal']);
    Assert.AreEqual('PR1 - Comercial  (Razón legal)',
      TextoProveedorDocumento(
        oCabecera, oProveedores, 'CODIGO_PRV_DOC'));
    oProveedores.Edit;
    oProveedores.FieldByName('NOMBRE_PRV').AsString := '';
    oProveedores.Post;
    Assert.AreEqual('PR1 - Razón legal',
      TextoProveedorDocumento(
        oCabecera, oProveedores, 'CODIGO_PRV_DOC'));
    oCabecera.Edit;
    oCabecera.FieldByName('CODIGO_PRV_DOC').AsString := 'PR2';
    oCabecera.Post;
    Assert.AreEqual('PR2 - (proveedor no encontrado)',
      TextoProveedorDocumento(
        oCabecera, oProveedores, 'CODIGO_PRV_DOC'));
  finally
    oProveedores.Free;
    oCabecera.Free;
  end;
end;

procedure TPruebasPresentacionDocumento.
  TotalPrendas_ValidaCabeceraYFormatea;
var
  oCabecera: TClientDataSet;
begin
  oCabecera := TClientDataSet.Create(nil);
  try
    oCabecera.FieldDefs.Add('ID', ftInteger);
    oCabecera.CreateDataSet;
    FTotal := 12;
    Assert.AreEqual('0', TextoTotalPrendasDocumento(
      oCabecera, ObtenerTotal));
    oCabecera.AppendRecord([1]);
    Assert.AreEqual('12', TextoTotalPrendasDocumento(
      oCabecera, ObtenerTotal));
    Assert.AreEqual('0', TextoTotalPrendasDocumento(
      oCabecera, nil));
  finally
    oCabecera.Free;
  end;
end;

end.
