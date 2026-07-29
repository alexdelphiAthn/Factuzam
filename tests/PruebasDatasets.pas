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
{    Pruebas de las utilidades de datasets.                                    }
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
    procedure ClaveSimple_ConvierteEnAmbosSentidos;
    [Test]
    procedure ClaveCompuesta_RoundTrip;
    [Test]
    procedure ClaveCompuesta_IncompletaRellenaNull;
    [Test]
    procedure ExtraerTabla_IgnoraSubconsultaYComillas;
    [Test]
    procedure ClavePrimaria_UsaProviderFlags;
    [Test]
    procedure EstadoDatasets_GrabaYCancela;
    [Test]
    procedure PeriodoUnico_UnRegistroEsValido;
    [Test]
    procedure PeriodoUnico_DetectaSolapamiento;
  end;

implementation

uses
  System.SysUtils, System.Variants,
  inLibDatasets;

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

procedure TPruebasDatasets.ClaveSimple_ConvierteEnAmbosSentidos;
var
  vNueva: Variant;
begin
  Assert.AreEqual(
    'ABC', inLibDatasets.KeyValuesToStr('ABC'));
  vNueva := inLibDatasets.StrToKeyValues(
    'ABC', 'CODIGO');
  Assert.AreEqual('ABC', VarToStr(vNueva));
end;

procedure TPruebasDatasets.
  ClaveCompuesta_RoundTrip;
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
end;

procedure TPruebasDatasets.
  EstadoDatasets_GrabaYCancela;
begin
  FDataSet.Edit;
  FDataSet.FieldByName(
    'NOMBRE').AsString := 'Cancelado';
  Assert.IsTrue(
    inLibDatasets.CheckOpenDatasets(
      FModulo));
  inLibDatasets.CancelarDatasets(FModulo);
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
    inLibDatasets.CheckOpenDatasets(FModulo));
end;

procedure TPruebasDatasets.
  PeriodoUnico_UnRegistroEsValido;
var
  oCandidato: TClientDataSet;
  oPeriodos: TClientDataSet;
begin
  oCandidato := TClientDataSet.Create(nil);
  oPeriodos := TClientDataSet.Create(nil);
  try
    oCandidato.FieldDefs.Add(
      'FECHA_INICIO', ftDate);
    oCandidato.FieldDefs.Add(
      'FECHA_FIN', ftDate);
    oCandidato.CreateDataSet;
    oCandidato.AppendRecord([
      EncodeDate(2026, 2, 1),
      EncodeDate(2026, 2, 28)]);
    oPeriodos.FieldDefs.Assign(
      oCandidato.FieldDefs);
    oPeriodos.CreateDataSet;
    oPeriodos.AppendRecord([
      EncodeDate(2026, 1, 1),
      EncodeDate(2026, 1, 31)]);
    Assert.IsTrue(
      inLibDatasets.ExistePeriodoUnico(
        oPeriodos,
        oCandidato.FieldByName('FECHA_INICIO'),
        oCandidato.FieldByName('FECHA_FIN')));
  finally
    FreeAndNil(oPeriodos);
    FreeAndNil(oCandidato);
  end;
end;

procedure TPruebasDatasets.
  PeriodoUnico_DetectaSolapamiento;
var
  oCandidato: TClientDataSet;
  oPeriodos: TClientDataSet;
begin
  oCandidato := TClientDataSet.Create(nil);
  oPeriodos := TClientDataSet.Create(nil);
  try
    oCandidato.FieldDefs.Add(
      'FECHA_INICIO', ftDate);
    oCandidato.FieldDefs.Add(
      'FECHA_FIN', ftDate);
    oCandidato.CreateDataSet;
    oCandidato.AppendRecord([
      EncodeDate(2026, 1, 15),
      EncodeDate(2026, 2, 15)]);
    oPeriodos.FieldDefs.Assign(
      oCandidato.FieldDefs);
    oPeriodos.CreateDataSet;
    oPeriodos.AppendRecord([
      EncodeDate(2026, 1, 1),
      EncodeDate(2026, 1, 31)]);
    oPeriodos.AppendRecord([
      EncodeDate(2026, 3, 1),
      EncodeDate(2026, 3, 31)]);
    Assert.AreEqual(2, oPeriodos.RecordCount);
    oPeriodos.First;
    Assert.IsFalse(
      inLibDatasets.ExistePeriodoUnico(
        oPeriodos,
        oCandidato.FieldByName('FECHA_INICIO'),
        oCandidato.FieldByName('FECHA_FIN')));
  finally
    FreeAndNil(oPeriodos);
    FreeAndNil(oCandidato);
  end;
end;

end.
