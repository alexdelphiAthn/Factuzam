{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasDialectosSql                                          }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos puros de composición SQL para los tres motores previstos.       }
{******************************************************************************}
unit PruebasDialectosSql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasDialectosSql = class
  public
    [Test]
    procedure DelimitaIdentificadoresPorMotor;
    [Test]
    procedure PaginaConOrdenDeterministaPorMotor;
    [Test]
    procedure ComponeFechasPorMotor;
    [Test]
    procedure ComponeAgregacionTextoPorMotor;
    [Test]
    procedure ComponeBloqueoPorMotor;
    [Test]
    procedure AislaInicializacionMariaDB;
    [Test]
    procedure ReconocePerfilSqlServerSinHabilitarProveedor;
    [Test]
    procedure AplicaListaBlancaConDialectoActivo;
  end;

implementation

uses
  System.SysUtils,
  inLibConexionPerfil,
  inLibConexionPerfilIntf,
  inLibDialectoSqlIntf,
  inLibDialectosSql,
  inLibSqlSeguro;

procedure TPruebasDialectosSql.DelimitaIdentificadoresPorMotor;
begin
  Assert.AreEqual(
    '`tabla``historica`',
    CrearDialectoSql(mbMariaDB).
      DelimitarIdentificador('tabla`historica'));
  Assert.AreEqual(
    '"public"."facturas"',
    CrearDialectoSql(mbPostgreSQL).
      DelimitarNombreCompuesto('public.facturas'));
  Assert.AreEqual(
    '[dbo].[facturas]]historicas]',
    CrearDialectoSql(mbSQLServer).
      DelimitarNombreCompuesto('dbo.facturas]historicas'));
end;

procedure TPruebasDialectosSql.PaginaConOrdenDeterministaPorMotor;
const
  SQL_BASE = 'SELECT ID, NOMBRE FROM TABLA';
begin
  Assert.AreEqual(
    SQL_BASE + ' ORDER BY ID LIMIT 25 OFFSET 50',
    CrearDialectoSql(mbMariaDB).
      AplicarLimiteOrdenado(SQL_BASE, 'ID', 25, 50));
  Assert.AreEqual(
    SQL_BASE + ' ORDER BY ID LIMIT 25 OFFSET 50',
    CrearDialectoSql(mbPostgreSQL).
      AplicarLimiteOrdenado(SQL_BASE, 'ID', 25, 50));
  Assert.AreEqual(
    SQL_BASE +
      ' ORDER BY ID OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY',
    CrearDialectoSql(mbSQLServer).
      AplicarLimiteOrdenado(SQL_BASE, 'ID', 25, 50));
end;

procedure TPruebasDialectosSql.ComponeFechasPorMotor;
begin
  Assert.AreEqual(
    'DATE_ADD(FECHA, INTERVAL :Dias day)',
    CrearDialectoSql(mbMariaDB).
      ExpresionSumarFecha('FECHA', ':Dias', uisDia));
  Assert.AreEqual(
    '(FECHA + ((:Dias) * INTERVAL ''1 day''))',
    CrearDialectoSql(mbPostgreSQL).
      ExpresionSumarFecha('FECHA', ':Dias', uisDia));
  Assert.AreEqual(
    'DATEADD(day, :Dias, FECHA)',
    CrearDialectoSql(mbSQLServer).
      ExpresionSumarFecha('FECHA', ':Dias', uisDia));
end;

procedure TPruebasDialectosSql.ComponeAgregacionTextoPorMotor;
begin
  Assert.AreEqual(
    'GROUP_CONCAT(CODIGO ORDER BY ORDEN SEPARATOR '','')',
    CrearDialectoSql(mbMariaDB).ExpresionAgregacionTexto(
      'CODIGO', ''',''', 'ORDEN', False));
  Assert.AreEqual(
    'STRING_AGG(CODIGO, '','' ORDER BY ORDEN)',
    CrearDialectoSql(mbPostgreSQL).ExpresionAgregacionTexto(
      'CODIGO', ''',''', 'ORDEN', False));
  Assert.AreEqual(
    'STRING_AGG(CODIGO, '','') WITHIN GROUP (ORDER BY ORDEN)',
    CrearDialectoSql(mbSQLServer).ExpresionAgregacionTexto(
      'CODIGO', ''',''', 'ORDEN', False));
end;

procedure TPruebasDialectosSql.ComponeBloqueoPorMotor;
begin
  Assert.AreEqual(
    'FOR UPDATE',
    CrearDialectoSql(mbPostgreSQL).
      ClausulaBloqueoActualizacion);
  Assert.AreEqual(
    'fza_contadores WITH (UPDLOCK, ROWLOCK)',
    CrearDialectoSql(mbSQLServer).
      TablaConBloqueoActualizacion('fza_contadores'));
  Assert.AreEqual(
    '',
    CrearDialectoSql(mbSQLServer).
      ClausulaBloqueoActualizacion);
end;

procedure TPruebasDialectosSql.AislaInicializacionMariaDB;
var
  oComandos: TComandosInicializacionSesionSql;
begin
  oComandos := CrearDialectoSql(mbMariaDB).
    ComandosInicializacionSesion;
  Assert.AreEqual(2, Integer(Length(oComandos)));
  Assert.IsTrue(Pos('SET NAMES', oComandos[0].Texto) = 1);
  Assert.IsFalse(oComandos[0].Obligatorio);
  Assert.AreEqual(
    0,
    Integer(Length(CrearDialectoSql(mbPostgreSQL).
      ComandosInicializacionSesion)));
end;

procedure TPruebasDialectosSql.
  ReconocePerfilSqlServerSinHabilitarProveedor;
var
  eMotor: TMotorBBDD;
  oCapacidades: TCapacidadesMotorBBDD;
  oPerfil: TPerfilConexion;
begin
  Assert.IsTrue(IntentarParsearMotorBBDD('MS_SQL', eMotor));
  Assert.AreEqual(Integer(mbSQLServer), Integer(eMotor));
  oPerfil := CrearPerfilConexionPredeterminado(eMotor);
  Assert.AreEqual(1433, oPerfil.Puerto);
  Assert.AreEqual('dbo', oPerfil.Esquema);
  oCapacidades := ResolverCapacidadesMotorBBDD(eMotor);
  Assert.IsFalse(oCapacidades.SoportaLimit);
  Assert.IsTrue(oCapacidades.SoportaIdentity);
end;

procedure TPruebasDialectosSql.
  AplicaListaBlancaConDialectoActivo;
begin
  Assert.AreEqual(
    '`orden`',
    DelimitarIdentificadorSql(
      'orden',
      ['orden', 'fecha']));
  Assert.AreEqual(
    '"orden"',
    DelimitarIdentificadorSql(
      CrearDialectoSql(mbPostgreSQL),
      'orden',
      ['orden', 'fecha']));
  Assert.AreEqual(
    '[orden]',
    DelimitarIdentificadorSql(
      CrearDialectoSql(mbSQLServer),
      'orden',
      ['orden', 'fecha']));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasDialectosSql);

end.
