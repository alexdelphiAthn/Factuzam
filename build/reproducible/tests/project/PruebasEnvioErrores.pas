{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasEnvioErrores                                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de contacto y completitud del diagnóstico de errores.             }
{******************************************************************************}
unit PruebasEnvioErrores;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasEnvioErrores = class
  public
    [Test]
    procedure Email_ValidaFormatoBasico;
    [Test]
    procedure Telefono_ValidaDigitosYSeparadores;
    [Test]
    procedure Evidencias_ExigenLasTresTrazas;
  end;

implementation

uses
  inLibEnvioErroresIntf,
  inLibLogIntf;

procedure TPruebasEnvioErrores.Email_ValidaFormatoBasico;
begin
  Assert.IsTrue(EmailSoporteValido('cliente@ejemplo.es'));
  Assert.IsFalse(EmailSoporteValido('cliente@'));
  Assert.IsFalse(EmailSoporteValido('cliente ejemplo.es'));
end;

procedure TPruebasEnvioErrores.Telefono_ValidaDigitosYSeparadores;
begin
  Assert.IsTrue(TelefonoSoporteValido('+34 980 123 456'));
  Assert.IsFalse(TelefonoSoporteValido('123'));
  Assert.IsFalse(TelefonoSoporteValido('980-ABC-456'));
end;

procedure TPruebasEnvioErrores.Evidencias_ExigenLasTresTrazas;
var
  Evidencias: TEvidenciasLog;
begin
  Evidencias.SQLActivo := True;
  Evidencias.RendimientoActivo := True;
  Evidencias.AvanzadoActivo := False;
  Assert.IsFalse(Evidencias.Completo);
  Evidencias.AvanzadoActivo := True;
  Assert.IsTrue(Evidencias.Completo);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasEnvioErrores);

end.
