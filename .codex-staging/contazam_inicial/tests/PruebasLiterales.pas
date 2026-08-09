{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasLiterales                                            }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verifica la resolución de idiomas y las etiquetas comprensibles.         }
{******************************************************************************}
unit PruebasLiterales;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasLiterales = class
  public
    [Test]
    procedure IdiomaSolicitado_TienePrioridad;
    [Test]
    procedure IdiomaNoDisponible_UsaEspanol;
    [Test]
    procedure LiteralNoDisponible_UsaNombreAmigable;
    [Test]
    procedure AplicarEtiquetas_UsaLosAliasDelDataSet;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient, inLibLiteralesIntf,
  inLibLiterales, inLibLiteralesDataSet;

type
  TRepositorioLiteralesPrueba = class(
    TInterfacedObject,
    IRepositorioLiterales)
  public
    function Buscar(
      const AContexto: string;
      const AClave: string;
      const AIdioma: string;
      out ATexto: string): Boolean;
  end;

function TRepositorioLiteralesPrueba.Buscar(
  const AContexto: string;
  const AClave: string;
  const AIdioma: string;
  out ATexto: string): Boolean;
begin
  ATexto := '';
  if SameText(AContexto, 'LISTADO_BALANCE') and
     SameText(AClave, 'CUENTA') and
     SameText(AIdioma, 'en-GB') then
  begin
    ATexto := 'Account code';
  end
  else if SameText(AContexto, 'LISTADO_BALANCE') and
          SameText(AClave, 'CUENTA') and
          SameText(AIdioma, 'es-ES') then
  begin
    ATexto := 'Código de cuenta';
  end
  else if SameText(AContexto, 'LISTADO_BALANCE') and
          SameText(AClave, 'NOMBRE') and
          SameText(AIdioma, 'es-ES') then
  begin
    ATexto := 'Nombre de la cuenta';
  end;
  Result := ATexto <> '';
end;

procedure TPruebasLiterales.AplicarEtiquetas_UsaLosAliasDelDataSet;
var
  oDatos: TClientDataSet;
  oRepositorio: IRepositorioLiterales;
  oServicio: IServicioLiterales;
begin
  oRepositorio := TRepositorioLiteralesPrueba.Create;
  oServicio := CrearServicioLiterales(oRepositorio, 'fr-FR');
  oDatos := TClientDataSet.Create(nil);
  try
    oDatos.FieldDefs.Add('CUENTA', ftString, 15);
    oDatos.FieldDefs.Add('NOMBRE', ftString, 150);
    oDatos.CreateDataSet;
    AplicarEtiquetasLiterales(
      oDatos,
      'LISTADO_BALANCE',
      oServicio);
    Assert.AreEqual(
      'Código de cuenta',
      oDatos.FieldByName('CUENTA').DisplayLabel);
    Assert.AreEqual(
      'Nombre de la cuenta',
      oDatos.FieldByName('NOMBRE').DisplayLabel);
  finally
    FreeAndNil(oDatos);
  end;
end;

procedure TPruebasLiterales.IdiomaNoDisponible_UsaEspanol;
var
  oRepositorio: IRepositorioLiterales;
  oServicio: IServicioLiterales;
begin
  oRepositorio := TRepositorioLiteralesPrueba.Create;
  oServicio := CrearServicioLiterales(oRepositorio, 'fr_fr');
  Assert.AreEqual('fr-FR', oServicio.IdiomaActual);
  Assert.AreEqual(
    'Nombre de la cuenta',
    oServicio.Resolver('LISTADO_BALANCE', 'NOMBRE'));
end;

procedure TPruebasLiterales.IdiomaSolicitado_TienePrioridad;
var
  oRepositorio: IRepositorioLiterales;
  oServicio: IServicioLiterales;
begin
  oRepositorio := TRepositorioLiteralesPrueba.Create;
  oServicio := CrearServicioLiterales(oRepositorio, 'en_gb');
  Assert.AreEqual('en-GB', oServicio.IdiomaActual);
  Assert.AreEqual(
    'Account code',
    oServicio.Resolver('LISTADO_BALANCE', 'CUENTA'));
end;

procedure TPruebasLiterales.LiteralNoDisponible_UsaNombreAmigable;
var
  oRepositorio: IRepositorioLiterales;
  oServicio: IServicioLiterales;
begin
  oRepositorio := TRepositorioLiteralesPrueba.Create;
  oServicio := CrearServicioLiterales(oRepositorio, 'es-ES');
  Assert.AreEqual(
    'Campo inventado',
    oServicio.Resolver('LISTADO_BALANCE', 'CAMPO_INVENTADO'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasLiterales);

end.
