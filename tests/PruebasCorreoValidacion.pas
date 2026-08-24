{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCorreoValidacion                                      }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas unitarias de la validación común de destinatarios de correo.      }
{******************************************************************************}
unit PruebasCorreoValidacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCorreoValidacion = class
  public
    [Test]
    procedure AceptaDireccionesHabituales;
    [Test]
    procedure RechazaLocalesInvalidos;
    [Test]
    procedure RechazaDominiosInvalidos;
    [Test]
    procedure NormalizaEmailRespuestaOpcional;
  end;

implementation

uses
  inLibCorreoValidacion;

procedure TPruebasCorreoValidacion.AceptaDireccionesHabituales;
begin
  Assert.IsTrue(EmailDocumentoValido('a@example.com'));
  Assert.IsTrue(EmailDocumentoValido(
    'nombre.apellido+facturas@sub.example.co.uk'));
  Assert.IsTrue(EmailDocumentoValido(' ventas-2026@example-domain.es '));
end;

procedure TPruebasCorreoValidacion.RechazaLocalesInvalidos;
begin
  Assert.IsFalse(EmailDocumentoValido(''));
  Assert.IsFalse(EmailDocumentoValido('.a@example.com'));
  Assert.IsFalse(EmailDocumentoValido('a.@example.com'));
  Assert.IsFalse(EmailDocumentoValido('a..b@example.com'));
  Assert.IsFalse(EmailDocumentoValido('a,b@example.com'));
  Assert.IsFalse(EmailDocumentoValido('a@@example.com'));
end;

procedure TPruebasCorreoValidacion.RechazaDominiosInvalidos;
begin
  Assert.IsFalse(EmailDocumentoValido('a@example..com'));
  Assert.IsFalse(EmailDocumentoValido('a@-example.com'));
  Assert.IsFalse(EmailDocumentoValido('a@example-.com'));
  Assert.IsFalse(EmailDocumentoValido('a@example'));
  Assert.IsFalse(EmailDocumentoValido('a@example.com.'));
end;

procedure TPruebasCorreoValidacion.NormalizaEmailRespuestaOpcional;
begin
  Assert.AreEqual(
    '',
    NormalizarEmailRespuestaDocumento(''));
  Assert.AreEqual(
    'facturas@example.com',
    NormalizarEmailRespuestaDocumento('  facturas@example.com  '));
  Assert.AreEqual(
    '',
    NormalizarEmailRespuestaDocumento('direccion-no-valida'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCorreoValidacion);

end.
