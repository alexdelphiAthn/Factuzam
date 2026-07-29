{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasSqlSeguro                                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las listas blancas para identificadores SQL dinámicos.         }
{******************************************************************************}
unit PruebasSqlSeguro;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasSqlSeguro = class
  public
    [Test]
    procedure AceptaIdentificadorIncluidoEnListaBlanca;
    [Test]
    procedure RechazaIdentificadorNoIncluidoEnListaBlanca;
    [Test]
    procedure RechazaIntentoDeInyeccion;
  end;

implementation

uses
  inLibSqlSeguro;

procedure TPruebasSqlSeguro.AceptaIdentificadorIncluidoEnListaBlanca;
const
  CAMPOS: array[0..1] of string = ('CODIGO_ART', 'DESCRIPCION_ART');
begin
  Assert.AreEqual(
    '`CODIGO_ART`',
    DelimitarIdentificadorSql('CODIGO_ART', CAMPOS));
end;

procedure TPruebasSqlSeguro.RechazaIdentificadorNoIncluidoEnListaBlanca;
const
  CAMPOS: array[0..1] of string = ('CODIGO_ART', 'DESCRIPCION_ART');
begin
  Assert.WillRaise(
    procedure
    begin
      DelimitarIdentificadorSql('PRECIO_ART', CAMPOS);
    end,
    EIdentificadorSqlNoPermitido);
end;

procedure TPruebasSqlSeguro.RechazaIntentoDeInyeccion;
const
  CAMPOS: array[0..1] of string = ('CODIGO_ART', 'DESCRIPCION_ART');
begin
  Assert.WillRaise(
    procedure
    begin
      DelimitarIdentificadorSql(
        'CODIGO_ART`; DROP TABLE fza_articulos; --',
        CAMPOS);
    end,
    EIdentificadorSqlNoPermitido);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasSqlSeguro);

end.
