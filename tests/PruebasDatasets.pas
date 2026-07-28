{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDatasets                                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las utilidades de datasets y de la fachada inLibtb.            }
{******************************************************************************}
unit PruebasDatasets;

interface

uses
  System.Classes, Data.DB, Datasnap.DBClient,
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasDatasets = class
  private
    FModulo: TDataModule;
    FDataSet: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure ClaveSimple_FachadaCompatible;
    [Test]
    procedure ClaveCompuesta_RoundTripCompatible;
    [Test]
    procedure ClaveCompuesta_IncompletaRellenaNull;
    [Test]
    procedure ExtraerTabla_IgnoraSubconsultaYComillas;
    [Test]
    procedure ClavePrimaria_UsaProviderFlags;
    [Test]
    procedure EstadoDatasets_GrabaYCancelaPorFachada;
  end;

implementation

uses
  System.SysUtils, System.Variants,
  inLibDatasets, inLibtb;

procedure TPruebasDatasets.Preparar;
begin
  FModulo := TDataModule.Create(nil);
  FDataSet := TClientDataSet.Create(FModulo);
  FDataSet.FieldDefs.Add('ID', ftInteger);
  FDataSet.FieldDefs.Add('SERIE', ftString, 10);
  FDataSet.FieldDefs.Add('NOMBRE', ftString, 40);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord([1, 'A', 'Inicial']);
end;

procedure TPruebasDatasets.Limpiar;
begin
  FDataSet := nil;
  FreeAndNil(FModulo);
end;

procedure TPruebasDatasets.ClaveSimple_FachadaCompatible;
var
  vFachada: Variant;
  vNueva: Variant;
begin
  Assert.AreEqual(
    'ABC', inLibDatasets.KeyValuesToStr('ABC'));
  Assert.AreEqual(
    inLibDatasets.KeyValuesToStr('ABC'),
    inLibtb.KeyValuesToStr('ABC'));
  vNueva := inLibDatasets.StrToKeyValues(
    'ABC', 'CODIGO');
  vFachada := inLibtb.StrToKeyValues(
    'ABC', 'CODIGO');
  Assert.AreEqual('ABC', VarToStr(vNueva));
  Assert.AreEqual(
    VarToStr(vNueva), VarToStr(vFachada));
end;

procedure TPruebasDatasets.
  ClaveCompuesta_RoundTripCompatible;
var
  sClave: string;
  vClave: Variant;
  vValores: Variant;
begin
  vValores := VarArrayCreate(
    [0, 2], varVariant);
  vValores[0] := 'EMP';
  vValores[1] := 'A';
  vValores[2] := 15;
  sClave := inLibDatasets.KeyValuesToStr(
    vValores);
  Assert.AreEqual('EMP|A|15', sClave);
  Assert.AreEqual(
    sClave, inLibtb.KeyValuesToStr(vValores));
  vClave := inLibDatasets.StrToKeyValues(
    sClave, 'EMPRESA;SERIE;NUMERO');
  Assert.AreEqual('EMP', VarToStr(vClave[0]));
  Assert.AreEqual('A', VarToStr(vClave[1]));
  Assert.AreEqual('15', VarToStr(vClave[2]));
end;

procedure TPruebasDatasets.
  ClaveCompuesta_IncompletaRellenaNull;
var
  vClave: Variant;
begin
  vClave := inLibDatasets.StrToKeyValues(
    'EMP|A', 'EMPRESA;SERIE;NUMERO');
  Assert.IsTrue(VarIsNull(vClave[2]));
end;

procedure TPruebasDatasets.
  ExtraerTabla_IgnoraSubconsultaYComillas;
const
  SQL_CON_SUBCONSULTA =
    'SELECT (SELECT COUNT(*) FROM secundaria) AS TOTAL ' +
    'FROM `principal` p WHERE p.ID = :ID';
begin
  Assert.AreEqual(
    'principal',
    inLibDatasets.ExtraerTablaDeSQL(
      SQL_CON_SUBCONSULTA));
  Assert.AreEqual(
    inLibDatasets.ExtraerTablaDeSQL(
      SQL_CON_SUBCONSULTA),
    inLibtb.ExtraerTablaDeSQL(
      SQL_CON_SUBCONSULTA));
end;

procedure TPruebasDatasets.
  ClavePrimaria_UsaProviderFlags;
begin
  FDataSet.FieldByName('ID').ProviderFlags :=
    [pfInUpdate, pfInWhere, pfInKey];
  FDataSet.FieldByName('SERIE').ProviderFlags :=
    [pfInUpdate, pfInWhere, pfInKey];
  Assert.AreEqual(
    'ID;SERIE',
    inLibDatasets.ObtenerClavePrimaria(
      FDataSet));
  Assert.AreEqual(
    'ID;SERIE',
    inLibtb.ObtenerClavePrimaria(
      FDataSet));
end;

procedure TPruebasDatasets.
  EstadoDatasets_GrabaYCancelaPorFachada;
begin
  FDataSet.Edit;
  FDataSet.FieldByName(
    'NOMBRE').AsString := 'Cancelado';
  Assert.IsTrue(
    inLibDatasets.CheckOpenDatasets(
      FModulo));
  inLibtb.CancelarDatasets(FModulo);
  Assert.AreEqual(
    'Inicial',
    FDataSet.FieldByName(
      'NOMBRE').AsString);
  FDataSet.Edit;
  FDataSet.FieldByName(
    'NOMBRE').AsString := 'Grabado';
  inLibDatasets.GrabarDatasets(FModulo);
  Assert.AreEqual(dsBrowse, FDataSet.State);
  Assert.AreEqual(
    'Grabado',
    FDataSet.FieldByName(
      'NOMBRE').AsString);
  Assert.IsFalse(
    inLibtb.CheckOpenDatasets(FModulo));
end;

end.
