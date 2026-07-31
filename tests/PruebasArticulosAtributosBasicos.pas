{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosAtributosBasicos                             }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los códigos globales y ad-hoc de atributos básicos.            }
{******************************************************************************}
unit PruebasArticulosAtributosBasicos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosAtributosBasicos = class
  public
    [Test]
    procedure Global_NormalizaEspacios;
    [Test]
    procedure AdHoc_IncluyeArticulo;
    [Test]
    procedure Codigo_SeTruncaACienCaracteres;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosAtributosBasicos;

procedure TPruebasArticulosAtributosBasicos.Global_NormalizaEspacios;
begin
  Assert.AreEqual(
    'AZUL_MARINO',
    ComponerCodigoAtributoBasico(
      acabGlobal, 'ART1', 'AZUL MARINO'));
end;

procedure TPruebasArticulosAtributosBasicos.AdHoc_IncluyeArticulo;
begin
  Assert.AreEqual(
    'AD_ART1_AZUL_MARINO',
    ComponerCodigoAtributoBasico(
      acabAdHoc, 'ART1', 'AZUL MARINO'));
end;

procedure TPruebasArticulosAtributosBasicos.
  Codigo_SeTruncaACienCaracteres;
var
  sCodigo: string;
begin
  sCodigo := ComponerCodigoAtributoBasico(
    acabAdHoc, 'ART1', StringOfChar('A', 120));
  Assert.AreEqual(100, Length(sCodigo));
  Assert.IsTrue(Pos('AD_ART1_', sCodigo) = 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosAtributosBasicos);

end.
