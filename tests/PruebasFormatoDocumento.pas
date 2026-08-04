{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFormatoDocumento                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas puras del formateo de documentos previamente cargados.           }
{******************************************************************************}
unit PruebasFormatoDocumento;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFormatoDocumento = class
  public
    [Test]
    procedure Formato_ReemplazaSerieYNumero;
    [Test]
    procedure DataSet_UsaFormatoYaCargado;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibFormatoDocumento;

procedure TPruebasFormatoDocumento.Formato_ReemplazaSerieYNumero;
begin
  Assert.AreEqual('2026-F/15',
    FormatearDocumento('Serie/NroDocumento', '2026-F', '15'));
  Assert.AreEqual('2026-F.15',
    FormatearDocumento('', '2026-F', '15'));
end;

procedure TPruebasFormatoDocumento.DataSet_UsaFormatoYaCargado;
var
  oDataSet: TClientDataSet;
begin
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('SERIE', ftString, 20);
    oDataSet.FieldDefs.Add('NUMERO', ftString, 20);
    oDataSet.FieldDefs.Add('FORMATO_DOCUMENTO_EMP', ftString, 50);
    oDataSet.CreateDataSet;
    oDataSet.AppendRecord(['A', '25', 'NroDocumento-Serie']);
    Assert.AreEqual('25-A', FormatearDocumentoDataSet(
      oDataSet, 'SERIE', 'NUMERO'));
  finally
    FreeAndNil(oDataSet);
  end;
end;

end.
