{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasPerfilConexion                                        }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas unitarias puras del perfil, su validación y las capacidades de    }
{    los motores soportados.                                                   }
{******************************************************************************}
unit PruebasPerfilConexion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasPerfilConexion = class
  public
    [Test]
    procedure PredeterminadosMariaDB;
    [Test]
    procedure PredeterminadosPostgreSQL;
    [Test]
    procedure ParseaNombresTolerantes;
    [Test]
    procedure RechazaNombreMotorDesconocido;
    [Test]
    procedure ParseaModosSSL;
    [Test]
    procedure ValidaPerfilCompleto;
    [Test]
    procedure RechazaPerfilIncompleto;
    [Test]
    procedure ExigeCAParaVerificacionSSL;
    [Test]
    procedure ValidaLimitesDelPool;
    [Test]
    procedure DescribeSinDatosDeAutenticacion;
    [Test]
    procedure ResuelveCapacidadesPorMotor;
  end;

implementation

uses
  System.SysUtils,
  inLibConexionPerfilIntf,
  inLibConexionPerfil;

procedure TPruebasPerfilConexion.PredeterminadosMariaDB;
var
  oPerfil: TPerfilConexion;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbMariaDB);

  Assert.AreEqual(Integer(mbMariaDB), Integer(oPerfil.Motor));
  Assert.AreEqual('mariadb', oPerfil.Id);
  Assert.AreEqual('localhost', oPerfil.Servidor);
  Assert.AreEqual(3306, oPerfil.Puerto);
  Assert.AreEqual('', oPerfil.Esquema);
  Assert.AreEqual(Integer(sslDesactivado), Integer(oPerfil.SSL));
  Assert.IsFalse(oPerfil.Pool.Habilitado);
  Assert.IsTrue(oPerfil.Pool.Validar);
end;

procedure TPruebasPerfilConexion.PredeterminadosPostgreSQL;
var
  oPerfil: TPerfilConexion;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbPostgreSQL);

  Assert.AreEqual(Integer(mbPostgreSQL), Integer(oPerfil.Motor));
  Assert.AreEqual('postgresql', oPerfil.Id);
  Assert.AreEqual(5432, oPerfil.Puerto);
  Assert.AreEqual('public', oPerfil.Esquema);
  Assert.AreEqual(15, oPerfil.TimeoutConexionSeg);
  Assert.AreEqual(30, oPerfil.TimeoutComandoSeg);
end;

procedure TPruebasPerfilConexion.ParseaNombresTolerantes;
var
  eMotor: TMotorBBDD;
begin
  Assert.IsTrue(IntentarParsearMotorBBDD(' My_SQL ', eMotor));
  Assert.AreEqual(Integer(mbMariaDB), Integer(eMotor));
  Assert.IsTrue(IntentarParsearMotorBBDD('maria-db', eMotor));
  Assert.AreEqual(Integer(mbMariaDB), Integer(eMotor));
  Assert.IsTrue(IntentarParsearMotorBBDD('POSTGRES', eMotor));
  Assert.AreEqual(Integer(mbPostgreSQL), Integer(eMotor));
  Assert.AreEqual('PostgreSQL', NombreMotorBBDD(eMotor));
end;

procedure TPruebasPerfilConexion.RechazaNombreMotorDesconocido;
var
  eMotor: TMotorBBDD;
begin
  Assert.IsFalse(IntentarParsearMotorBBDD('oracle', eMotor));
end;

procedure TPruebasPerfilConexion.ParseaModosSSL;
var
  eModo: TModoSSLConexion;
begin
  Assert.IsTrue(IntentarParsearModoSSLConexion('verify-full', eModo));
  Assert.AreEqual(Integer(sslVerificarCompleto), Integer(eModo));
  Assert.IsTrue(IntentarParsearModoSSLConexion('VERIFY_CA', eModo));
  Assert.AreEqual(Integer(sslVerificarCA), Integer(eModo));
  Assert.IsTrue(IntentarParsearModoSSLConexion('off', eModo));
  Assert.AreEqual(Integer(sslDesactivado), Integer(eModo));
  Assert.IsFalse(IntentarParsearModoSSLConexion('quizá', eModo));
end;

procedure TPruebasPerfilConexion.ValidaPerfilCompleto;
var
  oPerfil: TPerfilConexion;
  sMotivo: string;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbPostgreSQL);
  oPerfil.BaseDatos := 'factuzam';
  oPerfil.Usuario := 'factuzam_app';

  Assert.IsTrue(ValidarPerfilConexion(oPerfil, sMotivo), sMotivo);
  Assert.AreEqual('', sMotivo);
end;

procedure TPruebasPerfilConexion.RechazaPerfilIncompleto;
var
  oPerfil: TPerfilConexion;
  sMotivo: string;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbMariaDB);
  oPerfil.Usuario := 'factuzam_app';

  Assert.IsFalse(ValidarPerfilConexion(oPerfil, sMotivo));
  Assert.IsTrue(Pos('base de datos', LowerCase(sMotivo)) > 0);
end;

procedure TPruebasPerfilConexion.ExigeCAParaVerificacionSSL;
var
  oPerfil: TPerfilConexion;
  sMotivo: string;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbPostgreSQL);
  oPerfil.BaseDatos := 'factuzam';
  oPerfil.Usuario := 'factuzam_app';
  oPerfil.SSL := sslVerificarCompleto;

  Assert.IsFalse(ValidarPerfilConexion(oPerfil, sMotivo));
  oPerfil.RutaCertificadoCA := 'ca.pem';
  Assert.IsTrue(ValidarPerfilConexion(oPerfil, sMotivo), sMotivo);
end;

procedure TPruebasPerfilConexion.ValidaLimitesDelPool;
var
  oPerfil: TPerfilConexion;
  sMotivo: string;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbMariaDB);
  oPerfil.BaseDatos := 'factuzam';
  oPerfil.Usuario := 'factuzam_app';
  oPerfil.Pool.Habilitado := True;
  oPerfil.Pool.MinimoConexiones := 11;
  oPerfil.Pool.MaximoConexiones := 10;

  Assert.IsFalse(ValidarPerfilConexion(oPerfil, sMotivo));
  oPerfil.Pool.MinimoConexiones := 1;
  Assert.IsTrue(ValidarPerfilConexion(oPerfil, sMotivo), sMotivo);
  oPerfil.Pool.TiempoVidaSeg := (MaxInt div 1000) + 1;
  Assert.IsFalse(ValidarPerfilConexion(oPerfil, sMotivo));
end;

procedure TPruebasPerfilConexion.DescribeSinDatosDeAutenticacion;
var
  oPerfil: TPerfilConexion;
  sDescripcion: string;
begin
  oPerfil := CrearPerfilConexionPredeterminado(mbPostgreSQL);
  oPerfil.BaseDatos := 'factuzam';
  oPerfil.Usuario := 'usuario-no-publicable';
  oPerfil.RutaCertificadoCA := 'ruta-no-publicable';
  sDescripcion := DescribirPerfilConexion(oPerfil);

  Assert.IsTrue(Pos('localhost:5432/factuzam', sDescripcion) > 0);
  Assert.IsFalse(Pos(oPerfil.Usuario, sDescripcion) > 0);
  Assert.IsFalse(Pos(oPerfil.RutaCertificadoCA, sDescripcion) > 0);
end;

procedure TPruebasPerfilConexion.ResuelveCapacidadesPorMotor;
var
  oMariaDB: TCapacidadesMotorBBDD;
  oPostgreSQL: TCapacidadesMotorBBDD;
begin
  oMariaDB := ResolverCapacidadesMotorBBDD(mbMariaDB);
  oPostgreSQL := ResolverCapacidadesMotorBBDD(mbPostgreSQL);

  Assert.IsFalse(oMariaDB.SoportaReturning);
  Assert.IsFalse(oMariaDB.SoportaEsquemas);
  Assert.IsTrue(oMariaDB.SoportaLimit);
  Assert.IsTrue(oMariaDB.SoportaInformationSchema);
  Assert.IsTrue(oPostgreSQL.SoportaReturning);
  Assert.IsTrue(oPostgreSQL.SoportaEsquemas);
  Assert.IsTrue(oPostgreSQL.SoportaJsonNativo);
  Assert.IsTrue(oPostgreSQL.SoportaBloqueoSkipLocked);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasPerfilConexion);

end.
