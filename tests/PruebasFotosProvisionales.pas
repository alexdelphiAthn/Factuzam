{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasFotosProvisionales                                     }
{    Tipo:       Pruebas DUnitX                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Caracteriza la seleccion usada por los flujos de fotos de una sesion.    }
{******************************************************************************}
unit PruebasFotosProvisionales;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFotosProvisionales = class
  public
    [Test]
    procedure Evaluar_ExitoAceptaSeleccionCompleta;
    [Test]
    procedure Evaluar_LimitePermiteCodigoPendienteEnVisor;
    [Test]
    procedure Evaluar_FalloPriorizaSesionAusente;
  end;

implementation

uses
  inMtoComprasSesionesPresentacionFotos;

procedure TPruebasFotosProvisionales.
  Evaluar_ExitoAceptaSeleccionCompleta;
var
  Seleccion: TSeleccionFotoSesion;
begin
  Seleccion := Default(TSeleccionFotoSesion);
  Seleccion.Serie := 'A';
  Seleccion.Numero := '42';
  Seleccion.Linea := 3;
  Seleccion.CodigoArticulo := 'ART-1';
  Assert.AreEqual(
    Integer(esfsValida),
    Integer(EvaluarSeleccionFotoSesion(Seleccion, True)));
end;

procedure TPruebasFotosProvisionales.
  Evaluar_LimitePermiteCodigoPendienteEnVisor;
var
  Seleccion: TSeleccionFotoSesion;
begin
  Seleccion := Default(TSeleccionFotoSesion);
  Seleccion.Serie := 'A';
  Seleccion.Numero := '42';
  Seleccion.Linea := 1;
  Assert.AreEqual(
    Integer(esfsValida),
    Integer(EvaluarSeleccionFotoSesion(Seleccion, False)));
  Assert.AreEqual(
    Integer(esfsSinCodigo),
    Integer(EvaluarSeleccionFotoSesion(Seleccion, True)));
end;

procedure TPruebasFotosProvisionales.
  Evaluar_FalloPriorizaSesionAusente;
var
  Seleccion: TSeleccionFotoSesion;
begin
  Seleccion := Default(TSeleccionFotoSesion);
  Seleccion.Linea := 1;
  Seleccion.CodigoArticulo := 'ART-1';
  Assert.AreEqual(
    Integer(esfsSinSesion),
    Integer(EvaluarSeleccionFotoSesion(Seleccion, True)));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosProvisionales);

end.
