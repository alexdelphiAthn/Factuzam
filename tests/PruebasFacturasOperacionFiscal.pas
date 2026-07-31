{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasOperacionFiscal                                }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la preparación de operaciones fiscales sin usar BBDD.         }
{******************************************************************************}
unit PruebasFacturasOperacionFiscal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasOperacionFiscal = class
  public
    [Test]
    procedure SinNumero_AvisaQueNoHayBorradorSeleccionado;
    [Test]
    procedure SinConsolidar_DescribeLaAccionPendiente;
    [Test]
    procedure AnulacionSimplificada_ConfirmaLaAnulacion;
    [Test]
    procedure Solicitud_AnulacionRevierteMovimientos;
    [Test]
    procedure Solicitud_OtraOperacionNoRevierteMovimientos;
  end;

implementation

uses
  System.SysUtils, inLibEmisionFiscalIntf,
  inLibFacturasOperacionFiscal;

function CrearContextoPrueba: TContextoOperacionFiscalFactura;
begin
  Result := Default(TContextoOperacionFiscalFactura);
  Result.Serie := 'F';
  Result.Numero := '42';
  Result.TipoFactura := 'NORMAL';
  Result.TipoOperacion := 'ANULACION';
  Result.Accion := 'Anulación';
  Result.Usuario := 'PRUEBAS';
  Result.Consolidada := True;
end;

procedure TPruebasFacturasOperacionFiscal.
  SinNumero_AvisaQueNoHayBorradorSeleccionado;
var
  Contexto: TContextoOperacionFiscalFactura;
  Preparacion: TPreparacionOperacionFiscalFactura;
begin
  Contexto := CrearContextoPrueba;
  Contexto.Numero := '  ';
  Preparacion := PrepararOperacionFiscalFactura(Contexto);
  Assert.IsFalse(Preparacion.EsValida);
  Assert.AreEqual(
    'Seleccione un borrador en la lista.',
    Preparacion.MensajeError);
end;

procedure TPruebasFacturasOperacionFiscal.
  SinConsolidar_DescribeLaAccionPendiente;
var
  Contexto: TContextoOperacionFiscalFactura;
  Preparacion: TPreparacionOperacionFiscalFactura;
begin
  Contexto := CrearContextoPrueba;
  Contexto.Consolidada := False;
  Preparacion := PrepararOperacionFiscalFactura(Contexto);
  Assert.IsFalse(Preparacion.EsValida);
  Assert.IsTrue(Pos('F\42', Preparacion.MensajeError) > 0);
  Assert.IsTrue(Pos('anulación', Preparacion.MensajeError) > 0);
end;

procedure TPruebasFacturasOperacionFiscal.
  AnulacionSimplificada_ConfirmaLaAnulacion;
var
  Contexto: TContextoOperacionFiscalFactura;
  Preparacion: TPreparacionOperacionFiscalFactura;
begin
  Contexto := CrearContextoPrueba;
  Contexto.TipoFactura := 'simplificada';
  Contexto.TipoOperacion := 'anulacion';
  Preparacion := PrepararOperacionFiscalFactura(Contexto);
  Assert.IsTrue(Preparacion.EsValida);
  Assert.IsNotEmpty(Preparacion.PreguntaConfirmacion);
end;

procedure TPruebasFacturasOperacionFiscal.
  Solicitud_AnulacionRevierteMovimientos;
var
  Contexto: TContextoOperacionFiscalFactura;
  Solicitud: TSolicitudEmisionFiscal;
begin
  Contexto := CrearContextoPrueba;
  Solicitud := CrearSolicitudOperacionFiscalFactura(Contexto);
  Assert.AreEqual(fefOperacion, Solicitud.Flujo);
  Assert.AreEqual('F', Solicitud.Serie);
  Assert.AreEqual('42', Solicitud.Numero);
  Assert.AreEqual('PRUEBAS', Solicitud.Usuario);
  Assert.AreEqual('ANULACION', Solicitud.TipoOperacion);
  Assert.AreEqual('Anulación', Solicitud.Accion);
  Assert.IsTrue(Solicitud.BorrarMovimientos);
  Assert.IsTrue(Solicitud.RegistrarEvento);
end;

procedure TPruebasFacturasOperacionFiscal.
  Solicitud_OtraOperacionNoRevierteMovimientos;
var
  Contexto: TContextoOperacionFiscalFactura;
  Solicitud: TSolicitudEmisionFiscal;
begin
  Contexto := CrearContextoPrueba;
  Contexto.TipoOperacion := 'SUBSANACION';
  Solicitud := CrearSolicitudOperacionFiscalFactura(Contexto);
  Assert.IsFalse(Solicitud.BorrarMovimientos);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasOperacionFiscal);

end.
