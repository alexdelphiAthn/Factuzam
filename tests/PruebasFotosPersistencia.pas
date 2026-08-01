{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFotosPersistencia                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la composicion segregada y los prefijos de fotos sin BBDD.       }
{******************************************************************************}
unit PruebasFotosPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFotosPersistencia = class
  public
    [Test]
    procedure ServiciosVacios_NoAsignanNingunPuerto;
    [Test]
    procedure PrefijosSku_OrdenaDeMasAMenosEspecifico;
    [Test]
    procedure Almacenamiento_ComponeNombreCanonico;
    [Test]
    procedure Fachada_SinServicios_SePuedeLiberar;
  end;

implementation

uses
  System.SysUtils,
  inLibFotosPersistenciaIntf, inLibFotosAlmacenamiento,
  inLibFotos;

procedure TPruebasFotosPersistencia.
  ServiciosVacios_NoAsignanNingunPuerto;
var
  Repositorios: TRepositoriosFotos;
begin
  Repositorios := Default(TRepositoriosFotos);
  Assert.IsFalse(Assigned(Repositorios.Consulta));
  Assert.IsFalse(Assigned(Repositorios.Edicion));
  Assert.IsFalse(Assigned(Repositorios.Sesion));
end;

procedure TPruebasFotosPersistencia.
  PrefijosSku_OrdenaDeMasAMenosEspecifico;
var
  Prefijos: TArray<string>;
begin
  Prefijos := GenerarPrefijosSku('BLUS-SEDA/BLANCO/L');
  Assert.AreEqual(2, Integer(Length(Prefijos)));
  Assert.AreEqual('BLUS-SEDA/BLANCO/L', Prefijos[0]);
  Assert.AreEqual('BLUS-SEDA/BLANCO', Prefijos[1]);
end;

procedure TPruebasFotosPersistencia.
  Almacenamiento_ComponeNombreCanonico;
var
  oAlmacenamiento: TAlmacenamientoFotos;
  sClave         : string;
  sNombre        : string;
begin
  oAlmacenamiento := TAlmacenamientoFotos.Create;
  try
    sClave := oAlmacenamiento.ClaveNombre(
      'BLUS-SEDA', 'BLUS-SEDA/BLANCO:L');
    sNombre := oAlmacenamiento.ComponerNombre(sClave, 7);
    Assert.AreEqual('BLUS-SEDA_BLANCO_L_007', sNombre);
    Assert.AreEqual(7, oAlmacenamiento.ExtraerIndice(sNombre));
    Assert.AreEqual('jpeg',
      oAlmacenamiento.ExtensionOrigen('foto.JPEG'));
  finally
    FreeAndNil(oAlmacenamiento);
  end;
end;

procedure TPruebasFotosPersistencia.
  Fachada_SinServicios_SePuedeLiberar;
var
  oFotos: TFotosArticulos;
begin
  oFotos := TFotosArticulos.Create;
  FreeAndNil(oFotos);
  Assert.IsFalse(Assigned(oFotos));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosPersistencia);

end.
