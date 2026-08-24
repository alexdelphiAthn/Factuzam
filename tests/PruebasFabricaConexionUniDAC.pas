{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFabricaConexionUniDAC                                 }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la traducción de perfiles a UniDAC sin abrir conexiones de red. }
{******************************************************************************}
unit PruebasFabricaConexionUniDAC;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFabricaConexionUniDAC = class
  public
    [Test]
    procedure ConfiguraMariaDBDesdePerfil;
    [Test]
    procedure ConfiguraPostgreSQLDesdePerfil;
    [Test]
    procedure ResuelvePerfilAdministrativoPorMotor;
    [Test]
    procedure RechazaVerificacionCompletaPostgreSQLSinSecureBridge;
    [Test]
    procedure LimpiaOpcionesDelMotorAnterior;
    [Test]
    procedure NoExponeCredencialEnPerfilSeguro;
    [Test]
    procedure RechazaSSLPreferidoEnMariaDB;
    [Test]
    procedure OcultaCredencialYDetalleTecnicoEnErroresPublicos;
    [Test]
    procedure SeparaReferenciaCredencialPorInstalacion;
    [Test]
    procedure RechazaSqlServerHastaDisponerDeAdaptador;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  inLibConexionPerfil,
  inLibConexionPerfilIni,
  inLibConexionPerfilIntf,
  inLibConexionesIntf,
  UniDataConexionFabrica;

function CrearConfiguracion(
  AMotor: TMotorBBDD;
  AModoSSL: TModoSSLConexion): TConfiguracionConexionResuelta;
begin
  Result := Default(TConfiguracionConexionResuelta);
  Result.Perfil := CrearPerfilConexionPredeterminado(AMotor);
  Result.Perfil.BaseDatos := 'factuzam_pruebas';
  Result.Perfil.Usuario := 'usuario_pruebas';
  Result.Perfil.SSL := AModoSSL;
  Result.Perfil.Pool.Habilitado := True;
  Result.Perfil.Pool.MinimoConexiones := 2;
  Result.Perfil.Pool.MaximoConexiones := 7;
  Result.Perfil.Pool.TiempoVidaSeg := 120;
  Result.ReferenciaCredencial := 'Factuzam/BBDD/pruebas';
  Result.Credencial := 'secreto-no-publicable';
end;

procedure TPruebasFabricaConexionUniDAC.
  SeparaReferenciaCredencialPorInstalacion;
var
  sReferenciaA: string;
  sReferenciaB: string;
begin
  sReferenciaA := ReferenciaCredencialConexionPredeterminada(
    'produccion',
    'C:\InstalacionA\fzam.ini');
  sReferenciaB := ReferenciaCredencialConexionPredeterminada(
    'produccion',
    'C:\InstalacionB\fzam.ini');

  Assert.AreNotEqual(sReferenciaA, sReferenciaB);
  Assert.IsTrue(Pos('Factuzam/BBDD/produccion/', sReferenciaA) = 1);
end;

procedure TPruebasFabricaConexionUniDAC.ConfiguraMariaDBDesdePerfil;
var
  oConfiguracion: TConfiguracionConexionResuelta;
  oConexion: TUniConnection;
  oFabrica: IFabricaConexionesUniDAC;
begin
  oConfiguracion := CrearConfiguracion(
    mbMariaDB,
    sslDesactivado);
  oConfiguracion.Perfil.Servidor := 'mariadb.local';
  oConfiguracion.Perfil.Puerto := 3310;
  oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  oConexion := oFabrica.CrearConexion(nil);
  try
    Assert.AreEqual('MySQL', oConexion.ProviderName);
    Assert.AreEqual('mariadb.local', oConexion.Server);
    Assert.AreEqual(3310, oConexion.Port);
    Assert.AreEqual('factuzam_pruebas', oConexion.Database);
    Assert.AreEqual('usuario_pruebas', oConexion.Username);
    Assert.AreEqual('mpDefault',
      oConexion.SpecificOptions.Values['MySQL.Protocol']);
    Assert.AreEqual('utf8mb4',
      oConexion.SpecificOptions.Values['MySQL.Charset']);
    Assert.IsTrue(oConexion.Pooling);
    Assert.IsFalse(oConexion.Options.LocalFailover);
    Assert.AreEqual(2, oConexion.PoolingOptions.MinPoolSize);
    Assert.AreEqual(7, oConexion.PoolingOptions.MaxPoolSize);
    Assert.AreEqual(120000,
      oConexion.PoolingOptions.ConnectionLifetime);
  finally
    oConexion.Free;
  end;
end;

procedure TPruebasFabricaConexionUniDAC.
  OcultaCredencialYDetalleTecnicoEnErroresPublicos;
var
  oConfiguracion: TConfiguracionConexionResuelta;
  oFabrica: IFabricaConexionesUniDAC;
  sError: string;
begin
  oConfiguracion := CrearConfiguracion(
    mbMariaDB,
    sslDesactivado);
  oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);

  sError := oFabrica.FormatearError(
    9999,
    'fallo secreto-no-publicable interno',
    False);
  Assert.IsTrue(Pos('secreto-no-publicable', sError) = 0);
  Assert.IsTrue(Pos('interno', sError) = 0);

  sError := oFabrica.FormatearError(
    9999,
    'fallo secreto-no-publicable interno',
    True);
  Assert.IsTrue(Pos('secreto-no-publicable', sError) = 0);
  Assert.IsTrue(Pos('***', sError) > 0);
end;

procedure TPruebasFabricaConexionUniDAC.ConfiguraPostgreSQLDesdePerfil;
var
  oConfiguracion: TConfiguracionConexionResuelta;
  oConexion: TUniConnection;
  oFabrica: IFabricaConexionesUniDAC;
begin
  oConfiguracion := CrearConfiguracion(
    mbPostgreSQL,
    sslVerificarCA);
  oConfiguracion.Perfil.Servidor := 'postgres.local';
  oConfiguracion.Perfil.RutaCertificadoCA := 'ca-pruebas.pem';
  oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  oConexion := oFabrica.CrearConexion(nil);
  try
    Assert.AreEqual('PostgreSQL', oConexion.ProviderName);
    Assert.AreEqual(5432, oConexion.Port);
    Assert.AreEqual('smVerifyCA',
      oConexion.SpecificOptions.Values['PostgreSQL.SSLMode']);
    Assert.AreEqual('UTF8',
      oConexion.SpecificOptions.Values['PostgreSQL.Charset']);
    Assert.AreEqual('public',
      oConexion.SpecificOptions.Values['PostgreSQL.Schema']);
    Assert.AreEqual('ca-pruebas.pem',
      oConexion.SpecificOptions.Values['PostgreSQL.SSLCACert']);
  finally
    oConexion.Free;
  end;
end;

procedure TPruebasFabricaConexionUniDAC.ResuelvePerfilAdministrativoPorMotor;
var
  oConfiguracion: TConfiguracionConexionResuelta;
  oFabrica: IFabricaConexionesUniDAC;
  oPerfil: TPerfilConexion;
begin
  oConfiguracion := CrearConfiguracion(
    mbMariaDB,
    sslDesactivado);
  oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  oPerfil := oFabrica.CrearPerfilAdministrativo(
    oConfiguracion.Perfil);
  Assert.AreEqual('information_schema', oPerfil.BaseDatos);

  oPerfil := CrearPerfilConexionPredeterminado(mbPostgreSQL);
  oPerfil.BaseDatos := 'factuzam_pruebas';
  oPerfil.Usuario := 'usuario_pruebas';
  oPerfil := oFabrica.CrearPerfilAdministrativo(oPerfil);
  Assert.AreEqual('postgres', oPerfil.BaseDatos);
  Assert.AreEqual('public', oPerfil.Esquema);
end;

procedure TPruebasFabricaConexionUniDAC.
  RechazaVerificacionCompletaPostgreSQLSinSecureBridge;
var
  bRechazado: Boolean;
  oConfiguracion: TConfiguracionConexionResuelta;
  oFabrica: IFabricaConexionesUniDAC;
begin
  oConfiguracion := CrearConfiguracion(
    mbPostgreSQL,
    sslVerificarCompleto);
  oConfiguracion.Perfil.RutaCertificadoCA := 'ca-pruebas.pem';
  bRechazado := False;
  try
    oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  except
    on EArgumentException do
      bRechazado := True;
  end;
  Assert.IsTrue(bRechazado);
end;

procedure TPruebasFabricaConexionUniDAC.LimpiaOpcionesDelMotorAnterior;
var
  oConfiguracion: TConfiguracionConexionResuelta;
  oConexion: TUniConnection;
  oFabrica: IFabricaConexionesUniDAC;
  oPerfilPostgreSQL: TPerfilConexion;
begin
  oConfiguracion := CrearConfiguracion(
    mbMariaDB,
    sslDesactivado);
  oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  oConexion := oFabrica.CrearConexion(nil);
  try
    oPerfilPostgreSQL := CrearPerfilConexionPredeterminado(
      mbPostgreSQL);
    oPerfilPostgreSQL.BaseDatos := 'factuzam_pruebas';
    oPerfilPostgreSQL.Usuario := 'usuario_pruebas';
    oFabrica.ConfigurarConexionTemporal(
      oConexion,
      oPerfilPostgreSQL,
      'otro-secreto');

    Assert.AreEqual('PostgreSQL', oConexion.ProviderName);
    Assert.AreEqual('',
      oConexion.SpecificOptions.Values['MySQL.Protocol']);
    Assert.AreEqual('smPrefer',
      oConexion.SpecificOptions.Values['PostgreSQL.SSLMode']);
  finally
    oConexion.Free;
  end;
end;

procedure TPruebasFabricaConexionUniDAC.NoExponeCredencialEnPerfilSeguro;
var
  oConfiguracion: TConfiguracionConexionResuelta;
  oConexion: TUniConnection;
  oFabrica: IFabricaConexionesUniDAC;
begin
  oConfiguracion := CrearConfiguracion(
    mbMariaDB,
    sslDesactivado);
  oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  oConexion := oFabrica.CrearConexion(nil);
  try
    Assert.AreEqual('secreto-no-publicable', oConexion.Password);
    Assert.IsTrue(
      Pos(
        'secreto-no-publicable',
        DescribirPerfilConexion(oFabrica.Perfil)) = 0);
  finally
    oConexion.Free;
  end;
end;

procedure TPruebasFabricaConexionUniDAC.RechazaSSLPreferidoEnMariaDB;
var
  bRechazado: Boolean;
  oConfiguracion: TConfiguracionConexionResuelta;
  oFabrica: IFabricaConexionesUniDAC;
begin
  oConfiguracion := CrearConfiguracion(
    mbMariaDB,
    sslPreferido);
  bRechazado := False;
  try
    oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  except
    on EArgumentException do
      bRechazado := True;
  end;
  Assert.IsTrue(bRechazado);
end;

procedure TPruebasFabricaConexionUniDAC.
  RechazaSqlServerHastaDisponerDeAdaptador;
var
  bRechazado: Boolean;
  oConfiguracion: TConfiguracionConexionResuelta;
  oFabrica: IFabricaConexionesUniDAC;
begin
  oConfiguracion := CrearConfiguracion(
    mbSQLServer,
    sslDesactivado);
  bRechazado := False;
  try
    oFabrica := CrearFabricaConexionesUniDAC(oConfiguracion);
  except
    on ENotSupportedException do
      bRechazado := True;
  end;
  Assert.IsTrue(bRechazado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFabricaConexionUniDAC);

end.
