{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDiagnosticoMetadata                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del diagnóstico de metadata de campos booleanos ES*.              }
{******************************************************************************}
unit PruebasDiagnosticoMetadata;

interface

uses
  Datasnap.DBClient, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasDiagnosticoMetadata = class
  private
    FDataSet: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure DataSetNulo_NoDevuelveIncidencias;
    [Test]
    procedure DataSetInactivo_NoDevuelveIncidencias;
    [Test]
    procedure SoloDetectaCamposEsNumericos;
    [Test]
    procedure PrefijoEs_NoDistingueMayusculas;
    [Test]
    procedure Mensaje_IncluyeContextoCampoTipoYSolucion;
  end;

implementation

uses
  System.SysUtils, Data.DB, inLibDiag;

procedure TPruebasDiagnosticoMetadata.Preparar;
begin
  FDataSet := TClientDataSet.Create(nil);
end;

procedure TPruebasDiagnosticoMetadata.Limpiar;
begin
  FreeAndNil(FDataSet);
end;

procedure TPruebasDiagnosticoMetadata.
  DataSetNulo_NoDevuelveIncidencias;
var
  aIncidencias: TIncidenciasMetadataCampos;
begin
  aIncidencias :=
    DetectarCamposBooleanosNumericos(nil);
  Assert.AreEqual(
    0, Integer(Length(aIncidencias)));
end;

procedure TPruebasDiagnosticoMetadata.
  DataSetInactivo_NoDevuelveIncidencias;
var
  aIncidencias: TIncidenciasMetadataCampos;
begin
  FDataSet.FieldDefs.Add(
    'ESACTIVO_ART', ftInteger);
  aIncidencias :=
    DetectarCamposBooleanosNumericos(FDataSet);
  Assert.AreEqual(
    0, Integer(Length(aIncidencias)));
end;

procedure TPruebasDiagnosticoMetadata.
  SoloDetectaCamposEsNumericos;
var
  aIncidencias: TIncidenciasMetadataCampos;
begin
  FDataSet.FieldDefs.Add(
    'ESACTIVO_ART', ftInteger);
  FDataSet.FieldDefs.Add(
    'ESVENTA_ART', ftFloat);
  FDataSet.FieldDefs.Add(
    'ESVISIBLE_ART', ftString, 1);
  FDataSet.FieldDefs.Add(
    'NUMERO_ART', ftInteger);
  FDataSet.CreateDataSet;
  aIncidencias :=
    DetectarCamposBooleanosNumericos(FDataSet);
  Assert.AreEqual(
    2, Integer(Length(aIncidencias)));
  Assert.AreEqual(
    'ESACTIVO_ART', aIncidencias[0].NombreCampo);
  Assert.AreEqual(
    ftInteger, aIncidencias[0].TipoCampo);
  Assert.AreEqual(
    'ESVENTA_ART', aIncidencias[1].NombreCampo);
  Assert.AreEqual(
    ftFloat, aIncidencias[1].TipoCampo);
end;

procedure TPruebasDiagnosticoMetadata.
  PrefijoEs_NoDistingueMayusculas;
var
  aIncidencias: TIncidenciasMetadataCampos;
begin
  FDataSet.FieldDefs.Add(
    'esbaja_art', ftSmallint);
  FDataSet.CreateDataSet;
  aIncidencias :=
    DetectarCamposBooleanosNumericos(FDataSet);
  Assert.AreEqual(
    1, Integer(Length(aIncidencias)));
  Assert.AreEqual(
    'esbaja_art', aIncidencias[0].NombreCampo);
end;

procedure TPruebasDiagnosticoMetadata.
  Mensaje_IncluyeContextoCampoTipoYSolucion;
var
  oIncidencia: TIncidenciaMetadataCampo;
  sMensaje: string;
begin
  oIncidencia.NombreCampo := 'ESACTIVO_ART';
  oIncidencia.TipoCampo := ftInteger;
  sMensaje := MensajeCampoBooleanoNumerico(
    'TfrmMtoArticulos', oIncidencia);
  Assert.IsTrue(
    Pos('TfrmMtoArticulos', sMensaje) > 0);
  Assert.IsTrue(
    Pos('ESACTIVO_ART', sMensaje) > 0);
  Assert.IsTrue(
    Pos('ftInteger', sMensaje) > 0);
  Assert.IsTrue(
    Pos('regenerar (borrar y volver a definir)', sMensaje) > 0);
end;

end.
