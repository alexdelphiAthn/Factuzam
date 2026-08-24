{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasProteccionDatosFacturacion                             }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Pruebas puras de deteccion y bloqueo de SQL sobre las tablas fiscales.    }
{******************************************************************************}
unit PruebasProteccionDatosFacturacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasProteccionDatosFacturacion = class
  public
    [Test]
    procedure ReconoceSoloTablasProtegidasExactas;
    [Test]
    procedure LocalizaReferenciasConEsquemaYDelimitadores;
    [Test]
    procedure IgnoraReferenciasEnComentariosYLiterales;
    [Test]
    procedure DetectaInsertEnTablasProtegidas;
    [Test]
    procedure PermiteInsertEnOtraTablaQueLeeFacturas;
    [Test]
    procedure DetectaUpdateEnTablasProtegidas;
    [Test]
    procedure PermiteUpdateDeOtraTablaConSubconsulta;
    [Test]
    procedure DetectaDeleteDirectoYPorAlias;
    [Test]
    procedure PermiteDeleteDeOtroObjetivoConJoinDeFacturas;
    [Test]
    procedure DetectaReplaceYTruncate;
    [Test]
    procedure DetectaCambiosEstructuralesDestructivos;
    [Test]
    procedure DetectaCargasMasivasYMerge;
    [Test]
    procedure PermiteMantenimientoSeguroSobreOtrasTablas;
    [Test]
    procedure DetectaSentenciaPeligrosaDentroDeScript;
    [Test]
    procedure DetectaDmlDentroDeDelimiterMySql;
    [Test]
    procedure DetectaDmlEnComentariosEjecutablesMySqlYMariaDb;
    [Test]
    procedure GuionesSinEspacioNoOcultanSentencias;
    [Test]
    procedure ComentariosOrdinariosSiguenIgnorandose;
    [Test]
    procedure ValidadorElevaExcepcionConMensajeLegal;
  end;

implementation

uses
  System.SysUtils,
  inLibProteccionDatosFacturacion;

procedure ComprobarDeteccion(
  const ASql, AOperacionEsperada, ATablaEsperada: string);
var
  sOperacion: string;
  sTabla: string;
begin
  Assert.IsTrue(
    DetectarModificacionTablaFacturacion(ASql, sOperacion, sTabla),
    'No se detecto la modificacion protegida: ' + ASql);
  Assert.AreEqual(AOperacionEsperada, sOperacion);
  Assert.AreEqual(ATablaEsperada, sTabla);
end;

procedure ComprobarPermitido(const ASql: string);
var
  sOperacion: string;
  sTabla: string;
begin
  Assert.IsFalse(
    DetectarModificacionTablaFacturacion(ASql, sOperacion, sTabla),
    'Se bloqueo una sentencia cuyo objetivo no esta protegido: ' + ASql);
  Assert.AreEqual('', sOperacion);
  Assert.AreEqual('', sTabla);
end;

procedure TPruebasProteccionDatosFacturacion.
  ReconoceSoloTablasProtegidasExactas;
begin
  Assert.IsTrue(EsTablaFacturacionProtegida('fza_facturas'));
  Assert.IsTrue(EsTablaFacturacionProtegida('FZA_FACTURAS_LINEAS'));
  Assert.IsTrue(EsTablaFacturacionProtegida('factuzam.`fza_facturas`'));
  Assert.IsTrue(EsTablaFacturacionProtegida('public."fza_facturas_lineas"'));
  Assert.IsFalse(EsTablaFacturacionProtegida('fza_facturas_compra'));
  Assert.IsFalse(EsTablaFacturacionProtegida('fza_facturas_consolidaciones'));
  Assert.IsFalse(EsTablaFacturacionProtegida('fza_facturas_lineas_bak'));
  Assert.IsFalse(EsTablaFacturacionProtegida('fza_facturaslineas'));
end;

procedure TPruebasProteccionDatosFacturacion.
  LocalizaReferenciasConEsquemaYDelimitadores;
var
  sTabla: string;
begin
  Assert.IsTrue(SqlReferenciaTablaFacturacionProtegida(
    'SELECT * FROM factuzam.`FZA_FACTURAS_LINEAS` fl', sTabla));
  Assert.AreEqual('fza_facturas_lineas', sTabla);
  Assert.IsTrue(SqlReferenciaTablaFacturacionProtegida(
    'SELECT * FROM public."fza_facturas"'));
  Assert.IsFalse(SqlReferenciaTablaFacturacionProtegida(
    'SELECT * FROM fza_facturas_compra'));
end;

procedure TPruebasProteccionDatosFacturacion.
  IgnoraReferenciasEnComentariosYLiterales;
const
  SQL_SEGURO =
    'SELECT ''UPDATE fza_facturas SET TOTAL_FAC = 0'' AS TEXTO;' +
    sLineBreak +
    '-- DELETE FROM fza_facturas_lineas' + sLineBreak +
    '# INSERT INTO fza_facturas VALUES (1)' + sLineBreak +
    '/* TRUNCATE TABLE fza_facturas; */' + sLineBreak +
    'SELECT * FROM fza_clientes';
  SQL_DOLLAR_SIN_ETIQUETA =
    'SELECT $$UPDATE fza_facturas SET TOTAL_FAC = 0$$ AS TEXTO';
  SQL_DOLLAR_CON_ETIQUETA =
    'DO $cuerpo$ BEGIN DELETE FROM fza_facturas_lineas; END $cuerpo$';
var
  sTabla: string;
begin
  Assert.IsFalse(SqlReferenciaTablaFacturacionProtegida(SQL_SEGURO, sTabla));
  Assert.AreEqual('', sTabla);
  ComprobarPermitido(SQL_SEGURO);
  Assert.IsFalse(SqlReferenciaTablaFacturacionProtegida(
    SQL_DOLLAR_SIN_ETIQUETA));
  ComprobarPermitido(SQL_DOLLAR_SIN_ETIQUETA);
  Assert.IsFalse(SqlReferenciaTablaFacturacionProtegida(
    SQL_DOLLAR_CON_ETIQUETA));
  ComprobarPermitido(SQL_DOLLAR_CON_ETIQUETA);
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaInsertEnTablasProtegidas;
begin
  ComprobarDeteccion(
    'insert low_priority ignore into `fza_facturas` (NUMERO_FAC) values (1)',
    'INSERT',
    'fza_facturas');
  ComprobarDeteccion(
    'INSERT INTO factuzam.`FZA_FACTURAS_LINEAS`' + sLineBreak +
    '(LINEA_FACLIN) VALUES (1)',
    'INSERT',
    'fza_facturas_lineas');
end;

procedure TPruebasProteccionDatosFacturacion.
  PermiteInsertEnOtraTablaQueLeeFacturas;
const
  SQL_INSERT_SELECT =
    'INSERT INTO fza_auditoria (CODIGO)' + sLineBreak +
    'SELECT NUMERO_FAC FROM fza_facturas';
begin
  Assert.IsTrue(SqlReferenciaTablaFacturacionProtegida(SQL_INSERT_SELECT));
  ComprobarPermitido(SQL_INSERT_SELECT);
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaUpdateEnTablasProtegidas;
begin
  ComprobarDeteccion(
    'UPDATE ONLY public."FZA_FACTURAS" AS f SET TOTAL_FAC = 0',
    'UPDATE',
    'fza_facturas');
  ComprobarDeteccion(
    'UPDATE fza_clientes c JOIN `fza_facturas_lineas` fl ' +
    'ON fl.CODIGO = c.CODIGO SET c.NOMBRE = ''X''',
    'UPDATE',
    'fza_facturas_lineas');
end;

procedure TPruebasProteccionDatosFacturacion.
  PermiteUpdateDeOtraTablaConSubconsulta;
begin
  ComprobarPermitido(
    'UPDATE fza_clientes SET NOMBRE = ''CLIENTE'' ' +
    'WHERE EXISTS (SELECT 1 FROM fza_facturas ' +
    'WHERE CODIGO_CLIENTE_FAC = CODIGO_CLIENTE_CLI)');
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaDeleteDirectoYPorAlias;
begin
  ComprobarDeteccion(
    'DELETE QUICK FROM factuzam.`fza_facturas_lineas` WHERE 1 = 0',
    'DELETE',
    'fza_facturas_lineas');
  ComprobarDeteccion(
    'DELETE f FROM `fza_facturas` AS f ' +
    'JOIN fza_clientes c ON c.CODIGO_CLIENTE_CLI = f.CODIGO_CLIENTE_FAC',
    'DELETE',
    'fza_facturas');
  ComprobarDeteccion(
    'DELETE FROM fl USING public."fza_facturas_lineas" fl WHERE 1 = 0',
    'DELETE',
    'fza_facturas_lineas');
end;

procedure TPruebasProteccionDatosFacturacion.
  PermiteDeleteDeOtroObjetivoConJoinDeFacturas;
begin
  ComprobarPermitido(
    'DELETE c FROM fza_clientes c ' +
    'JOIN fza_facturas f ON f.CODIGO_CLIENTE_FAC = c.CODIGO_CLIENTE_CLI');
  ComprobarPermitido(
    'DELETE FROM fza_clientes WHERE EXISTS ' +
    '(SELECT 1 FROM fza_facturas WHERE NUMERO_FAC = ''1'')');
end;

procedure TPruebasProteccionDatosFacturacion.DetectaReplaceYTruncate;
begin
  ComprobarDeteccion(
    'REPLACE DELAYED INTO fza_facturas (NUMERO_FAC) VALUES (1)',
    'REPLACE',
    'fza_facturas');
  ComprobarDeteccion(
    'TRUNCATE TABLE ONLY public."fza_facturas_lineas"',
    'TRUNCATE',
    'fza_facturas_lineas');
  ComprobarDeteccion(
    'TRUNCATE TABLE fza_temporal, `fza_facturas`',
    'TRUNCATE',
    'fza_facturas');
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaCambiosEstructuralesDestructivos;
begin
  ComprobarDeteccion(
    'DROP TEMPORARY TABLE IF EXISTS fza_temporal, ' +
    'public."fza_facturas"',
    'DROP',
    'fza_facturas');
  ComprobarDeteccion(
    'ALTER ONLINE IGNORE TABLE `fza_facturas_lineas` ' +
    'DROP COLUMN OBSOLETA',
    'ALTER',
    'fza_facturas_lineas');
  ComprobarDeteccion(
    'RENAME TABLE fza_facturas TO fza_facturas_historico',
    'RENAME',
    'fza_facturas');
  ComprobarDeteccion(
    'RENAME TABLE fza_temporal TO fza_facturas_lineas',
    'RENAME',
    'fza_facturas_lineas');
  ComprobarDeteccion(
    'CREATE OR REPLACE TABLE fza_facturas (NUMERO_FAC VARCHAR(20))',
    'CREATE OR REPLACE',
    'fza_facturas');
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaCargasMasivasYMerge;
begin
  ComprobarDeteccion(
    'LOAD DATA LOCAL INFILE ''facturas.csv'' REPLACE ' +
    'INTO TABLE factuzam.fza_facturas (NUMERO_FAC)',
    'LOAD',
    'fza_facturas');
  ComprobarDeteccion(
    'MERGE INTO public."fza_facturas_lineas" fl ' +
    'USING fza_temporal t ON t.ID = fl.ID ' +
    'WHEN MATCHED THEN UPDATE SET LINEA_FACLIN = t.LINEA',
    'MERGE',
    'fza_facturas_lineas');
  ComprobarDeteccion(
    'COPY public.fza_facturas (NUMERO_FAC) FROM STDIN',
    'COPY',
    'fza_facturas');
end;

procedure TPruebasProteccionDatosFacturacion.
  PermiteMantenimientoSeguroSobreOtrasTablas;
begin
  ComprobarPermitido('DROP TABLE IF EXISTS fza_temporal');
  ComprobarPermitido(
    'ALTER TABLE fza_clientes ADD CONSTRAINT fk_factura ' +
    'FOREIGN KEY (ULTIMA_FACTURA) REFERENCES fza_facturas (NUMERO_FAC)');
  ComprobarPermitido(
    'LOAD DATA INFILE ''clientes.csv'' INTO TABLE fza_clientes');
  ComprobarPermitido(
    'MERGE INTO fza_clientes c USING fza_facturas f ' +
    'ON f.CODIGO_CLIENTE_FAC = c.CODIGO_CLIENTE_CLI ' +
    'WHEN MATCHED THEN UPDATE SET c.NOMBRE = ''Leído''');
  ComprobarPermitido('COPY fza_facturas TO STDOUT');
  ComprobarPermitido(
    'CREATE TABLE IF NOT EXISTS fza_facturas (NUMERO_FAC VARCHAR(20))');
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaSentenciaPeligrosaDentroDeScript;
begin
  ComprobarDeteccion(
    'UPDATE fza_clientes SET NOMBRE = ''A'';' + sLineBreak +
    '/* segunda sentencia */' + sLineBreak +
    'DELETE FROM `FZA_FACTURAS` WHERE NUMERO_FAC = ''1'';',
    'DELETE',
    'fza_facturas');
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaDmlDentroDeDelimiterMySql;
const
  SQL_PROCEDIMIENTOS =
    'DELIMITER $$' + sLineBreak +
    'CREATE PROCEDURE permitido() BEGIN SELECT 1; END $$' + sLineBreak +
    'CREATE PROCEDURE bloqueado() BEGIN ' +
    'UPDATE fza_facturas SET TOTAL_FAC = 0; END $$' + sLineBreak +
    'DELIMITER ;';
begin
  ComprobarDeteccion(
    SQL_PROCEDIMIENTOS,
    'UPDATE',
    'fza_facturas');
end;

procedure TPruebasProteccionDatosFacturacion.
  DetectaDmlEnComentariosEjecutablesMySqlYMariaDb;
begin
  ComprobarDeteccion(
    '/*!50000 UPDATE fza_facturas SET TOTAL_FAC = 0 */',
    'UPDATE',
    'fza_facturas');
  ComprobarDeteccion(
    '/*! INSERT INTO fza_facturas_lineas (LINEA_FACLIN) VALUES (1) */',
    'INSERT',
    'fza_facturas_lineas');
  ComprobarDeteccion(
    '/*M!100100 DELETE FROM fza_facturas WHERE NUMERO_FAC = ''1'' */',
    'DELETE',
    'fza_facturas');
  ComprobarDeteccion(
    '/*m! TRUNCATE TABLE fza_facturas_lineas */',
    'TRUNCATE',
    'fza_facturas_lineas');
end;

procedure TPruebasProteccionDatosFacturacion.
  GuionesSinEspacioNoOcultanSentencias;
begin
  ComprobarDeteccion(
    'SELECT 1--1; UPDATE fza_facturas SET TOTAL_FAC = 0',
    'UPDATE',
    'fza_facturas');
end;

procedure TPruebasProteccionDatosFacturacion.
  ComentariosOrdinariosSiguenIgnorandose;
begin
  ComprobarPermitido(
    'SELECT 1; /* UPDATE fza_facturas SET TOTAL_FAC = 0 */ ' +
    'SELECT * FROM fza_clientes');
  ComprobarPermitido(
    'SELECT 1; -- DELETE FROM fza_facturas_lineas' + sLineBreak +
    'SELECT * FROM fza_clientes');
  ComprobarPermitido('SELECT 1; --');
end;

procedure TPruebasProteccionDatosFacturacion.
  ValidadorElevaExcepcionConMensajeLegal;
begin
  try
    ValidarSqlSinModificacionesFacturacion(
      'UPDATE fza_facturas SET TOTAL_FAC = 0');
    Assert.Fail('El validador no elevo la excepcion esperada');
  except
    on E: EModificacionTablaFacturacionProtegida do
    begin
      Assert.AreEqual('UPDATE', E.Operacion);
      Assert.AreEqual('fza_facturas', E.Tabla);
      Assert.IsTrue(Pos('Ley 58/2003', E.Message) > 0);
      Assert.IsTrue(Pos('Real Decreto 1007/2023', E.Message) > 0);
      Assert.IsTrue(Pos('Orden HAC/1177/2024', E.Message) > 0);
      Assert.IsTrue(Pos('VERI*FACTU', E.Message) > 0);
    end;
  end;
  ValidarSqlSinModificacionesFacturacion(
    'UPDATE fza_clientes SET NOMBRE = ''Permitido''');
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasProteccionDatosFacturacion);

end.
