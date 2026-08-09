{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasExportadorXlsx                                         }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verifica que la exportación produce un contenedor OOXML válido.           }
{******************************************************************************}
unit PruebasExportadorXlsx;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasExportadorXlsx = class
  public
    [Test]
    procedure Exportar_CreaLasPartesObligatorias;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Zip, Data.DB,
  Datasnap.DBClient, inLibExportadorXlsx;

function ContieneEntrada(
  AZip: TZipFile;
  const ANombre: string): Boolean;
var
  sNombre: string;
begin
  Result := False;
  for sNombre in AZip.FileNames do
  begin
    if SameText(sNombre, ANombre) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure TPruebasExportadorXlsx.Exportar_CreaLasPartesObligatorias;
var
  oDatos: TClientDataSet;
  oZip: TZipFile;
  oId: TGUID;
  sRuta: string;
begin
  CreateGUID(oId);
  sRuta := TPath.Combine(
    TPath.GetTempPath,
    'contazam_' + GUIDToString(oId) + '.xlsx');
  oDatos := TClientDataSet.Create(nil);
  oZip := TZipFile.Create;
  try
    oDatos.FieldDefs.Add('CUENTA', ftString, 15);
    oDatos.FieldDefs.Add('NOMBRE', ftString, 80);
    oDatos.FieldDefs.Add('SALDO', ftCurrency);
    oDatos.CreateDataSet;
    oDatos.AppendRecord([
      '430000000000',
      'Clientes & asociados',
      Currency(121.50)
    ]);
    TExportadorXlsx.Exportar(
      oDatos,
      sRuta,
      'Balance de sumas y saldos',
      'Empresa 001');
    Assert.IsTrue(TFile.Exists(sRuta));
    oZip.Open(sRuta, zmRead);
    Assert.IsTrue(ContieneEntrada(oZip, '[Content_Types].xml'));
    Assert.IsTrue(ContieneEntrada(oZip, '_rels/.rels'));
    Assert.IsTrue(ContieneEntrada(oZip, 'xl/workbook.xml'));
    Assert.IsTrue(
      ContieneEntrada(oZip, 'xl/_rels/workbook.xml.rels'));
    Assert.IsTrue(
      ContieneEntrada(oZip, 'xl/worksheets/sheet1.xml'));
    oZip.Close;
  finally
    FreeAndNil(oZip);
    FreeAndNil(oDatos);
    if TFile.Exists(sRuta) then
    begin
      TFile.Delete(sRuta);
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasExportadorXlsx);

end.
