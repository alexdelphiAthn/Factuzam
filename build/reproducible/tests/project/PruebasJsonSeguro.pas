{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasJsonSeguro                                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de la lectura JSON con defecto explícito (inLibJsonSeguro),       }
{    extraída al eliminar los except vacíos de inLibCriptoCurr (Fase 1).       }
{******************************************************************************}
unit PruebasJsonSeguro;

interface

uses
  System.JSON, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasJsonSeguro = class
  private
    FObjeto: TJSONObject;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Double_ClaveInexistenteDevuelveDefecto;
    [Test]
    procedure Double_NullDevuelveDefecto;
    [Test]
    procedure Double_TextoNoNumericoDevuelveDefecto;
    [Test]
    procedure Double_ValorValidoSeLee;
    [Test]
    procedure Double_ObjetoNilDevuelveDefecto;
    [Test]
    procedure Entero_ValorValidoSeLee;
    [Test]
    procedure Entero_TextoNoNumericoDevuelveDefecto;
    [Test]
    procedure Fecha_IsoValidaSeParsea;
    [Test]
    procedure Fecha_MalformadaDevuelveDefecto;
    [Test]
    procedure Fecha_VaciaDevuelveDefecto;
  end;

implementation

uses
  System.SysUtils, System.DateUtils,
  inLibJsonSeguro;

procedure TPruebasJsonSeguro.Preparar;
begin
  FObjeto := TJSONObject.ParseJSONValue(
    '{"numero":1.5,"nulo":null,"texto":"abc","entero":7}')
    as TJSONObject;
end;

procedure TPruebasJsonSeguro.Limpiar;
begin
  FreeAndNil(FObjeto);
end;

procedure TPruebasJsonSeguro.
  Double_ClaveInexistenteDevuelveDefecto;
begin
  Assert.AreEqual(
    Double(-1),
    JsonDoubleODefecto(FObjeto, 'no_existe', -1),
    0.0001);
end;

procedure TPruebasJsonSeguro.
  Double_NullDevuelveDefecto;
begin
  Assert.AreEqual(
    Double(-1),
    JsonDoubleODefecto(FObjeto, 'nulo', -1),
    0.0001);
end;

procedure TPruebasJsonSeguro.
  Double_TextoNoNumericoDevuelveDefecto;
begin
  Assert.AreEqual(
    Double(-1),
    JsonDoubleODefecto(FObjeto, 'texto', -1),
    0.0001);
end;

procedure TPruebasJsonSeguro.
  Double_ValorValidoSeLee;
begin
  Assert.AreEqual(
    Double(1.5),
    JsonDoubleODefecto(FObjeto, 'numero', -1),
    0.0001);
end;

procedure TPruebasJsonSeguro.
  Double_ObjetoNilDevuelveDefecto;
begin
  Assert.AreEqual(
    Double(-1),
    JsonDoubleODefecto(nil, 'numero', -1),
    0.0001);
end;

procedure TPruebasJsonSeguro.
  Entero_ValorValidoSeLee;
begin
  Assert.AreEqual(
    7,
    JsonEnteroODefecto(FObjeto, 'entero', -1));
end;

procedure TPruebasJsonSeguro.
  Entero_TextoNoNumericoDevuelveDefecto;
begin
  Assert.AreEqual(
    -1,
    JsonEnteroODefecto(FObjeto, 'texto', -1));
end;

procedure TPruebasJsonSeguro.
  Fecha_IsoValidaSeParsea;
var
  dFecha: TDateTime;
begin
  // Mediodia UTC de mitad de anyo: la conversion a hora local nunca
  // cambia de mes en ninguna zona horaria real.
  dFecha := JsonFechaIsoODefecto('2024-06-15T12:00:00.000Z', 0);
  Assert.AreEqual(2024, YearOf(dFecha));
  Assert.AreEqual(6, MonthOf(dFecha));
end;

procedure TPruebasJsonSeguro.
  Fecha_MalformadaDevuelveDefecto;
begin
  Assert.AreEqual(
    Double(0),
    Double(JsonFechaIsoODefecto('no-es-una-fecha', 0)),
    0.0001);
end;

procedure TPruebasJsonSeguro.
  Fecha_VaciaDevuelveDefecto;
begin
  Assert.AreEqual(
    Double(0),
    Double(JsonFechaIsoODefecto('', 0)),
    0.0001);
end;

end.
