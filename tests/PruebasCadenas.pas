{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCadenas                                                }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de cadenas y símbolos prohibidos configurables.                   }
{******************************************************************************}
unit PruebasCadenas;

interface

uses
  DUnitX.TestFramework,
  inLibPerfilesUsuarioIntf,
  PruebasGestorPerfilesMto;

type
  [TestFixture]
  TPruebasCadenas = class
  private
    FServicioObjeto: TServicioPerfilesPrueba;
    FServicio: IPerfilesUsuario;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Coincidencia_DevuelvePrimeraDeLaCadena;
    [Test]
    procedure Simbolos_SinPerfilUsaPredeterminados;
    [Test]
    procedure Simbolos_PerfilSustituyePredeterminados;
    [Test]
    procedure Ocurrencias_NoCuentaSolapamientos;
    [Test]
    procedure Separar_AdmiteSeparadorMultipleYFinalVacio;
    [Test]
    procedure Separar_SinSeparadorDevuelveCadenaCompleta;
  end;

implementation

uses
  inLibCadenas;

procedure TPruebasCadenas.Preparar;
begin
  FServicioObjeto := TServicioPerfilesPrueba.Create;
  FServicio := FServicioObjeto;
end;

procedure TPruebasCadenas.Limpiar;
begin
  FServicio := nil;
  FServicioObjeto := nil;
end;

procedure TPruebasCadenas.
  Coincidencia_DevuelvePrimeraDeLaCadena;
begin
  Assert.AreEqual(
    'b',
    inLibCadenas.HayCoincidencia(
      'abc', 'zby'));
  Assert.AreEqual(
    '',
    inLibCadenas.HayCoincidencia(
      'abc', 'XYZ'));
end;

procedure TPruebasCadenas.
  Simbolos_SinPerfilUsaPredeterminados;
begin
  Assert.IsFalse(
    inLibCadenas.SimbolosProhibidos(
      'ABC123', nil));
  Assert.IsTrue(
    inLibCadenas.SimbolosProhibidos(
      'ABC/123', nil));
end;

procedure TPruebasCadenas.
  Simbolos_PerfilSustituyePredeterminados;
begin
  FServicioObjeto.DefinirValor(
    'oSimbolosProhibidos', '@');
  Assert.IsTrue(
    inLibCadenas.SimbolosProhibidos(
      'ABC@123', FServicio));
  Assert.IsFalse(
    inLibCadenas.SimbolosProhibidos(
      'ABC/123', FServicio));
end;

procedure TPruebasCadenas.
  Ocurrencias_NoCuentaSolapamientos;
begin
  Assert.AreEqual(
    2,
    inLibCadenas.ContarOcurrenciasAnsi(
      'aaaa', 'aa'));
  Assert.AreEqual(
    0,
    inLibCadenas.ContarOcurrenciasAnsi(
      'aaaa', ''));
end;

procedure TPruebasCadenas.
  Separar_AdmiteSeparadorMultipleYFinalVacio;
var
  aPartes: TArrayCadenas;
begin
  aPartes := inLibCadenas.SepararAnsi(
    'uno||dos||', '||');
  Assert.AreEqual(
    3, Integer(Length(aPartes)));
  Assert.AreEqual('uno', aPartes[0]);
  Assert.AreEqual('dos', aPartes[1]);
  Assert.AreEqual('', aPartes[2]);
end;

procedure TPruebasCadenas.
  Separar_SinSeparadorDevuelveCadenaCompleta;
var
  aPartes: TArrayCadenas;
begin
  aPartes := inLibCadenas.SepararAnsi(
    'completa', '|');
  Assert.AreEqual(
    1, Integer(Length(aPartes)));
  Assert.AreEqual('completa', aPartes[0]);
end;

end.
