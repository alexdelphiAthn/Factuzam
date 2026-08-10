{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasConsolidacionPresentacion                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza los mensajes previos a consolidar una factura.                }
{******************************************************************************}
unit PruebasFacturasConsolidacionPresentacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasConsolidacionPresentacion = class
  public
    [Test]
    procedure ValidacionCorrecta_PermiteConfirmar;
    [Test]
    procedure ValidacionCorrecta_IdentificaElBorrador;
    [Test]
    procedure ValidacionIncorrecta_ConservaElMensaje;
    [Test]
    procedure ValidacionIncorrecta_NoGeneraPregunta;
  end;

implementation

uses
  System.SysUtils, inLibFacturasServiciosIntf,
  inLibFacturasConsolidacionPresentacion;

procedure TPruebasFacturasConsolidacionPresentacion.
  ValidacionCorrecta_PermiteConfirmar;
var
  Preparacion: TPreparacionConsolidacionFactura;
begin
  Preparacion := PrepararConsolidacionFactura(
    TResultadoOperacionFactura.Correcto,
    'F',
    '42');
  Assert.IsTrue(Preparacion.EsValida);
  Assert.IsEmpty(Preparacion.MensajeError);
end;

procedure TPruebasFacturasConsolidacionPresentacion.
  ValidacionCorrecta_IdentificaElBorrador;
var
  Preparacion: TPreparacionConsolidacionFactura;
begin
  Preparacion := PrepararConsolidacionFactura(
    TResultadoOperacionFactura.Correcto,
    'F',
    '42');
  Assert.AreEqual(
    '¿Lanzar fiscalmente el borrador F\42? Dejará de estar en borrador y ' +
    'de ser editable.',
    Preparacion.PreguntaConfirmacion);
end;

procedure TPruebasFacturasConsolidacionPresentacion.
  ValidacionIncorrecta_ConservaElMensaje;
var
  Preparacion: TPreparacionConsolidacionFactura;
begin
  Preparacion := PrepararConsolidacionFactura(
    TResultadoOperacionFactura.Error('No se puede consolidar.'),
    'F',
    '42');
  Assert.IsFalse(Preparacion.EsValida);
  Assert.AreEqual(
    'No se puede consolidar.',
    Preparacion.MensajeError);
end;

procedure TPruebasFacturasConsolidacionPresentacion.
  ValidacionIncorrecta_NoGeneraPregunta;
var
  Preparacion: TPreparacionConsolidacionFactura;
begin
  Preparacion := PrepararConsolidacionFactura(
    TResultadoOperacionFactura.Error('Error'),
    'F',
    '42');
  Assert.IsEmpty(Preparacion.PreguntaConfirmacion);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasFacturasConsolidacionPresentacion);

end.
