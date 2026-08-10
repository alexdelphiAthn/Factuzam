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
    [Test]
    procedure Fachada_ExitoExponeServicioSesion;
    [Test]
    procedure Fachada_LimiteConservaSesionAlLiberarServicios;
    [Test]
    procedure Fachada_FalloRechazaParametrosAusentes;
  end;

implementation

uses
  System.SysUtils,
  inLibFotos, inLibFotosPersistenciaIntf, inLibFotosSesion,
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

procedure TPruebasFotosProvisionales.
  Fachada_ExitoExponeServicioSesion;
var
  Fotos: TFotosArticulos;
begin
  Fotos := TFotosArticulos.Create;
  try
    Assert.IsTrue(Assigned(Fotos.Sesion));
  finally
    Fotos.Free;
  end;
end;

procedure TPruebasFotosProvisionales.
  Fachada_LimiteConservaSesionAlLiberarServicios;
var
  Fotos : TFotosArticulos;
  Sesion: TSesionFotos;
begin
  Fotos := TFotosArticulos.Create;
  try
    Sesion := Fotos.Sesion;
    Fotos.LiberarServicios;
    Assert.IsTrue(Fotos.Sesion = Sesion);
  finally
    Fotos.Free;
  end;
end;

procedure TPruebasFotosProvisionales.
  Fachada_FalloRechazaParametrosAusentes;
var
  Fotos       : TFotosArticulos;
  Repositorios: TRepositoriosFotos;
  Rechazado   : Boolean;
begin
  Fotos := TFotosArticulos.Create;
  try
    Repositorios := Default(TRepositoriosFotos);
    Rechazado := False;
    try
      Fotos.AsignarConexion(nil, nil, nil, Repositorios);
    except
      on E: EArgumentNilException do
        Rechazado := True;
    end;
    Assert.IsTrue(Rechazado);
  finally
    Fotos.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosProvisionales);

end.
