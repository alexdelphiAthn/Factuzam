{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasConexiones                                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de configuración UniDAC sin abrir conexiones reales.              }
{******************************************************************************}
unit PruebasConexiones;

interface

uses
  Uni, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasConexiones = class
  private
    FConexion: TUniConnection;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Configuracion_AsignaCredencialesYPuerto;
    [Test]
    procedure PuertoInvalido_UsaPuertoPredeterminado;
    [Test]
    procedure Configuracion_AplicaOpcionesDeProduccion;
  end;

implementation

uses
  System.SysUtils,
  inLibConexionesUniDAC;

procedure TPruebasConexiones.Preparar;
begin
  FConexion := TUniConnection.Create(nil);
end;

procedure TPruebasConexiones.Limpiar;
begin
  FreeAndNil(FConexion);
end;

procedure TPruebasConexiones.
  Configuracion_AsignaCredencialesYPuerto;
begin
  ConfigurarConexionMySQL(
    FConexion,
    'usuario',
    'secreto',
    'servidor',
    '3310',
    'datos');
  Assert.AreEqual(
    'servidor', FConexion.Server);
  Assert.AreEqual(
    'datos', FConexion.Database);
  Assert.AreEqual(
    'usuario', FConexion.Username);
  Assert.AreEqual(
    'secreto', FConexion.Password);
  Assert.AreEqual(
    3310, FConexion.Port);
end;

procedure TPruebasConexiones.
  PuertoInvalido_UsaPuertoPredeterminado;
begin
  ConfigurarConexionMySQL(
    FConexion,
    'usuario',
    'secreto',
    'servidor',
    'NO_VALIDO',
    'datos');
  Assert.AreEqual(
    3306, FConexion.Port);
end;

procedure TPruebasConexiones.
  Configuracion_AplicaOpcionesDeProduccion;
begin
  FConexion.PoolingOptions.Validate := False;
  ConfigurarConexionMySQL(
    FConexion,
    'usuario',
    'secreto',
    'servidor',
    '3306',
    'datos');
  Assert.AreEqual(
    'True',
    FConexion.SpecificOptions.Values[
      'MySQL.UseUnicode']);
  Assert.AreEqual(
    'utf8mb4',
    FConexion.SpecificOptions.Values[
      'MySQL.Charset']);
  Assert.AreEqual(
    'mpDefault',
    FConexion.SpecificOptions.Values[
      'MySQL.Protocol']);
  Assert.IsTrue(FConexion.Pooling);
  Assert.AreEqual(
    0,
    FConexion.PoolingOptions.ConnectionLifetime);
  Assert.IsTrue(
    FConexion.PoolingOptions.Validate);
  Assert.AreEqual(
    3,
    FConexion.PoolingOptions.MinPoolSize);
  Assert.AreEqual(
    20,
    FConexion.PoolingOptions.MaxPoolSize);
  Assert.AreEqual(
    'True',
    FConexion.SpecificOptions.Values[
      'MySQL.Interactive']);
  Assert.AreEqual(
    '5',
    FConexion.SpecificOptions.Values[
      'ConnectionTimeout']);
  Assert.IsTrue(
    FConexion.Options.LocalFailover);
  Assert.IsTrue(
    FConexion.Options.DisconnectedMode);
end;

end.
