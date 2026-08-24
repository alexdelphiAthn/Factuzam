{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCatalogoSqlMotores                                    }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica que el catálogo selecciona y conserva el SQL del motor activo.  }
{******************************************************************************}
unit PruebasCatalogoSqlMotores;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCatalogoSqlMotores = class
  public
    [Test]
    procedure ConservaContratoMariaDB;
    [Test]
    procedure ResuelveVarianteDelMotorActivo;
    [Test]
    procedure FallaCerradoSiFaltaVariante;
    [Test]
    procedure FallbackDePerfilConservaMotor;
    [Test]
    procedure AusenciaDeVarianteNoInvocaEjecutor;
    [Test]
    procedure SeparaRaicesDePerfilPorMotor;
    [Test]
    procedure ValidaExecuteSqlServerYCastPostgreSQL;
  end;

implementation

uses
  System.SysUtils,
  inLibCatalogoSqlEjecucion,
  inLibCatalogoSqlIntf,
  inLibCatalogoSqlPerfiles,
  inLibCatalogoSqlValidacion,
  inLibConexionPerfilIntf,
  inLibPerfilesUsuarioIntf;

function CrearDefinicionLectura: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'PRUEBAS',
    'BUSCAR',
    'SELECT id FROM tabla_maria WHERE id = :id',
    'id',
    'id',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

procedure TPruebasCatalogoSqlMotores.ConservaContratoMariaDB;
var
  oDefinicion: TDefinicionSql;
  oResuelto: TSqlResuelto;
begin
  oDefinicion := CrearDefinicionLectura;
  oResuelto := ResolverSqlBase(oDefinicion);
  Assert.AreEqual(oDefinicion.SqlBase, oResuelto.Texto);
  Assert.AreEqual(oDefinicion.SqlBase, oResuelto.TextoBase);
  Assert.AreEqual(Integer(mbMariaDB), Integer(oResuelto.Motor));
end;

procedure TPruebasCatalogoSqlMotores.ResuelveVarianteDelMotorActivo;
const
  SQL_POSTGRESQL =
    'SELECT id FROM tabla_postgresql WHERE id = :id';
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResuelto: TSqlResuelto;
begin
  oDefinicion := ConVarianteSqlMotor(
    CrearDefinicionLectura,
    mbPostgreSQL,
    SQL_POSTGRESQL);
  oCatalogo := TCatalogoSqlPerfiles.Create(nil, mbPostgreSQL);
  oResuelto := oCatalogo.Resolver(oDefinicion);
  Assert.AreEqual(SQL_POSTGRESQL, oResuelto.Texto);
  Assert.AreEqual(SQL_POSTGRESQL, oResuelto.TextoBase);
  Assert.AreEqual(Integer(mbPostgreSQL), Integer(oCatalogo.Motor));
end;

procedure TPruebasCatalogoSqlMotores.FallaCerradoSiFaltaVariante;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  oDefinicion := CrearDefinicionLectura;
  oCatalogo := TCatalogoSqlPerfiles.Create(nil, mbPostgreSQL);
  Assert.WillRaise(
    procedure
    begin
      oCatalogo.Resolver(oDefinicion);
    end,
    EVarianteSqlMotorNoDisponible);
end;

procedure TPruebasCatalogoSqlMotores.FallbackDePerfilConservaMotor;
const
  SQL_BASE_POSTGRESQL =
    'SELECT id FROM tabla_postgresql WHERE id = :id';
  SQL_PERFIL_POSTGRESQL =
    'SELECT id FROM vista_postgresql WHERE id = :id';
var
  iEjecuciones: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oPerfil: TProfileDicc;
  oValor: TDictValue;
  sUltimoSql: string;
begin
  oDefinicion := ConVarianteSqlMotor(
    CrearDefinicionLectura,
    mbPostgreSQL,
    SQL_BASE_POSTGRESQL);
  oPerfil := TProfileDicc.Create;
  try
    oValor.sValue := 'S';
    oValor.sValueText := SQL_PERFIL_POSTGRESQL;
    oPerfil.Add(ClavePerfilSql(oDefinicion), oValor);
    oCatalogo := TCatalogoSqlPerfiles.Create(
      oPerfil,
      mbPostgreSQL);
  finally
    oPerfil.Free;
  end;
  iEjecuciones := 0;
  sUltimoSql := '';
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    oCatalogo,
    procedure(const ASql: string)
    begin
      Inc(iEjecuciones);
      sUltimoSql := ASql;
      if iEjecuciones = 1 then
        raise Exception.Create('fallo simulado del perfil');
    end);
  Assert.AreEqual(2, iEjecuciones);
  Assert.AreEqual(SQL_BASE_POSTGRESQL, sUltimoSql);
end;

procedure TPruebasCatalogoSqlMotores.
  AusenciaDeVarianteNoInvocaEjecutor;
var
  iEjecuciones: Integer;
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
begin
  iEjecuciones := 0;
  oDefinicion := CrearDefinicionLectura;
  oCatalogo := TCatalogoSqlPerfiles.Create(nil, mbSQLServer);
  Assert.WillRaise(
    procedure
    begin
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        oCatalogo,
        procedure(const ASql: string)
        begin
          Inc(iEjecuciones);
        end);
    end,
    EVarianteSqlMotorNoDisponible);
  Assert.AreEqual(0, iEjecuciones);
end;

procedure TPruebasCatalogoSqlMotores.SeparaRaicesDePerfilPorMotor;
begin
  Assert.AreEqual(
    'SQL_REPOSITORIOS',
    ClavePerfilCatalogoSql(mbMariaDB));
  Assert.AreEqual(
    'SQL_REPOSITORIOS_POSTGRESQL',
    ClavePerfilCatalogoSql(mbPostgreSQL));
  Assert.AreEqual(
    'SQL_REPOSITORIOS_SQLSERVER',
    ClavePerfilCatalogoSql(mbSQLServer));
end;

procedure TPruebasCatalogoSqlMotores.
  ValidaExecuteSqlServerYCastPostgreSQL;
var
  oDefinicion: TDefinicionSql;
  oValidacion: TResultadoValidacionSql;
begin
  oDefinicion := CrearDefinicionSql(
    'PRUEBAS',
    'PROCEDIMIENTO',
    'CALL procedimiento(:id)',
    'id',
    'id',
    tssCall,
    pesPerfilLecturaConFallback);
  oValidacion := ValidarSql(
    oDefinicion,
    'EXECUTE procedimiento :id',
    mbSQLServer);
  Assert.IsTrue(oValidacion.EsValido, oValidacion.Mensaje);

  oDefinicion := CrearDefinicionLectura;
  oValidacion := ValidarSql(
    oDefinicion,
    'SELECT id::bigint AS id FROM tabla WHERE id = :id',
    mbPostgreSQL);
  Assert.IsTrue(oValidacion.EsValido, oValidacion.Mensaje);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCatalogoSqlMotores);

end.
