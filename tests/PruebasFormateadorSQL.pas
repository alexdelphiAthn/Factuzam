{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFormateadorSQL                                         }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de regresión del parser y formateador de sentencias SQL.          }
{******************************************************************************}
unit PruebasFormateadorSQL;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFormateadorSQL = class
  public
    [Test]
    procedure FormateaInsertSelectSinFromConWhere;
    [Test]
    procedure ConservaPuntoEnLiteralDecimalSQL;
    [Test]
    procedure FormateaTablaMariaDB;
    [Test]
    procedure FormateaCallMariaDB;
    [Test]
    procedure FormateaTablaCualificadaYFuncionDatabase;
  end;

implementation

uses
  System.SysUtils,
  ts.Editor.CodeFormatters;

procedure TPruebasFormateadorSQL.FormateaInsertSelectSinFromConWhere;
var
  oFormateador: ICodeFormatter;
  sResultado: string;
  sSql: string;
begin
  sSql :=
    'INSERT INTO `fza_caja_formas_pago` ' +
    '(`CODIGO_FP_CFP`, `DESCRIPCION_FORMA_PAGO_CFP`) ' +
    'SELECT ''VALE'', ''Vale tienda'' ' +
    'WHERE NOT EXISTS (' +
    'SELECT 1 FROM `fza_caja_formas_pago` ' +
    'WHERE `CODIGO_FP_CFP` = ''VALE'');';
  oFormateador := GetSQLFormatter;
  sResultado := oFormateador.Format(sSql);
  Assert.IsFalse(
    sResultado.StartsWith('/* ERROR DEL PARSER:'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains(sLineBreak + 'select' + sLineBreak),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains(sLineBreak + 'where' + sLineBreak),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains(sLineBreak + '  ''Vale tienda'''),
    sResultado);
end;

procedure TPruebasFormateadorSQL.ConservaPuntoEnLiteralDecimalSQL;
var
  oFormateador: ICodeFormatter;
  sResultado: string;
begin
  oFormateador := GetSQLFormatter;
  sResultado := oFormateador.Format(
    'SELECT 1 FROM `fza_caja_vales` WHERE `IMPORTE_VL` >= 0.005;');
  Assert.IsFalse(
    sResultado.StartsWith('/* ERROR DEL PARSER:'),
    sResultado);
  Assert.IsTrue(sResultado.Contains('0.005'), sResultado);
  Assert.IsFalse(sResultado.Contains('0,005'), sResultado);
end;

procedure TPruebasFormateadorSQL.FormateaTablaMariaDB;
var
  oFormateador: ICodeFormatter;
  sResultado: string;
  sSql: string;
begin
  sSql :=
    'CREATE TABLE IF NOT EXISTS `fza_errores_envios` (' +
    '`ID_ERENV` bigint unsigned NOT NULL AUTO_INCREMENT, ' +
    '`INSTANTE_ERROR_ERENV` datetime NOT NULL, ' +
    '`INSTANTE_MODIF` datetime NULL DEFAULT NULL ' +
    'ON UPDATE CURRENT_TIMESTAMP, ' +
    'PRIMARY KEY (`ID_ERENV`), ' +
    'KEY `IDX_ERENV_INSTANTE` (`INSTANTE_ERROR_ERENV`)' +
    ') ENGINE=InnoDB;';
  oFormateador := GetSQLFormatter;
  sResultado := oFormateador.Format(sSql);
  Assert.IsFalse(
    sResultado.StartsWith('/* ERROR DEL PARSER:'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains(
      'ID_ERENV bigint unsigned NOT NULL AUTO_INCREMENT'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains('INSTANTE_ERROR_ERENV datetime NOT NULL'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains(
      'key IDX_ERENV_INSTANTE (INSTANTE_ERROR_ERENV)'),
    sResultado);
end;

procedure TPruebasFormateadorSQL.FormateaCallMariaDB;
var
  oFormateador: ICodeFormatter;
  sResultado: string;
  sSql: string;
begin
  sSql :=
    'DELIMITER ;;' + sLineBreak +
    'CREATE PROCEDURE `PRC_PRUEBA`()' + sLineBreak +
    'BEGIN' + sLineBreak +
    '  SET @s = ' + QuotedStr('SELECT ''ID''') + ';' + sLineBreak +
    'END ;;' + sLineBreak +
    'DELIMITER ;' + sLineBreak +
    'CALL `PRC_PRUEBA`();';
  oFormateador := GetSQLFormatter;
  sResultado := oFormateador.Format(sSql);
  Assert.IsFalse(
    sResultado.StartsWith('/* ERROR DEL PARSER:'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains('call PRC_PRUEBA();'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains(QuotedStr('SELECT ''ID''')),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains('delimiter ;'),
    sResultado);
end;

procedure TPruebasFormateadorSQL.FormateaTablaCualificadaYFuncionDatabase;
var
  oFormateador: ICodeFormatter;
  sResultado: string;
  sSql: string;
begin
  sSql :=
    'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE();';
  oFormateador := GetSQLFormatter;
  sResultado := oFormateador.Format(sSql);
  Assert.IsFalse(
    sResultado.StartsWith('/* ERROR DEL PARSER:'),
    sResultado);
  Assert.IsTrue(
    sResultado.Contains('INFORMATION_SCHEMA.COLUMNS'),
    sResultado);
  Assert.IsTrue(sResultado.Contains('database()'), sResultado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFormateadorSQL);

end.
