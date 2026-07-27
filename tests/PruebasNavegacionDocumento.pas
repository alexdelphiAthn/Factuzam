{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasNavegacionDocumento                                  }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de claves de navegación entre mantenimientos.                     }
{******************************************************************************}
unit PruebasNavegacionDocumento;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasNavegacionDocumento = class
  public
    [Test]
    procedure Codigo_ValidaDataSetYRecorta;
    [Test]
    procedure Clave_ExigeSerieYNumero;
  end;

implementation

uses
  Data.DB, Datasnap.DBClient, inLibShowMto;

procedure TPruebasNavegacionDocumento.
  Codigo_ValidaDataSetYRecorta;
var
  oDataSet: TClientDataSet;
begin
  Assert.AreEqual('', CodigoMtoDataSet(nil, 'CODIGO'));
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('CODIGO', ftString, 20);
    oDataSet.CreateDataSet;
    Assert.AreEqual('', CodigoMtoDataSet(oDataSet, 'CODIGO'));
    oDataSet.AppendRecord([' ART1 ']);
    Assert.AreEqual('ART1', CodigoMtoDataSet(
      oDataSet, 'CODIGO'));
  finally
    oDataSet.Free;
  end;
end;

procedure TPruebasNavegacionDocumento.
  Clave_ExigeSerieYNumero;
var
  oDataSet: TClientDataSet;
begin
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('SERIE', ftString, 10);
    oDataSet.FieldDefs.Add('NUMERO', ftString, 10);
    oDataSet.CreateDataSet;
    oDataSet.AppendRecord([' A ', ' 15 ']);
    Assert.AreEqual('A,15', ClaveMtoDataSet(
      oDataSet, 'SERIE', 'NUMERO'));
    oDataSet.Edit;
    oDataSet.FieldByName('NUMERO').AsString := '';
    oDataSet.Post;
    Assert.AreEqual('', ClaveMtoDataSet(
      oDataSet, 'SERIE', 'NUMERO'));
  finally
    oDataSet.Free;
  end;
end;

end.
