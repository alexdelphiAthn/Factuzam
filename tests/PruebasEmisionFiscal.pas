{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasEmisionFiscal                                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de selección de estrategias y solicitudes de emisión fiscal.      }
{******************************************************************************}
unit PruebasEmisionFiscal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasEmisionFiscal = class
  public
    [Test]
    procedure Factoria_SeleccionaVerifactu;
    [Test]
    procedure Factoria_SeleccionaNoVerifactu;
    [Test]
    procedure Factoria_SeleccionaSinVerifactu;
    [Test]
    procedure Solicitud_OperacionConservaDatos;
    [Test]
    procedure Solicitud_OperacionPermiteDescripcion;
    [Test]
    procedure Solicitud_AltaPermiteOmitirEvento;
    [Test]
    procedure Solicitud_ConsolidacionUsaAlta;
  end;

implementation

uses
  inLibVerifactu, inLibEmisionFiscalIntf, inLibEmisionFiscal;

procedure TPruebasEmisionFiscal.Factoria_SeleccionaVerifactu;
var
  Servicio: IServicioEmisionFiscal;
begin
  Servicio := CrearServicioEmisionFiscalPorModo(
    mvVerifactu,
    nil,
    nil,
    nil);
  Assert.AreEqual(mvVerifactu, Servicio.Modo);
end;

procedure TPruebasEmisionFiscal.Factoria_SeleccionaNoVerifactu;
var
  Servicio: IServicioEmisionFiscal;
begin
  Servicio := CrearServicioEmisionFiscalPorModo(
    mvNoVerifactu,
    nil,
    nil,
    nil);
  Assert.AreEqual(mvNoVerifactu, Servicio.Modo);
end;

procedure TPruebasEmisionFiscal.Factoria_SeleccionaSinVerifactu;
var
  Servicio: IServicioEmisionFiscal;
begin
  Servicio := CrearServicioEmisionFiscalPorModo(
    mvSinVerifactu,
    nil,
    nil,
    nil);
  Assert.AreEqual(mvSinVerifactu, Servicio.Modo);
end;

procedure TPruebasEmisionFiscal.Solicitud_OperacionConservaDatos;
var
  Solicitud: TSolicitudEmisionFiscal;
begin
  Solicitud := TSolicitudEmisionFiscal.ParaOperacion(
    'F',
    '42',
    'USUARIO',
    'ANULACION',
    'Anulación',
    False);
  Assert.AreEqual(fefOperacion, Solicitud.Flujo);
  Assert.AreEqual('ANULACION', Solicitud.TipoOperacion);
  Assert.AreEqual('Anulación', Solicitud.Accion);
  Assert.IsFalse(Solicitud.BorrarMovimientos);
  Assert.IsTrue(Solicitud.RegistrarEvento);
  Assert.IsNotEmpty(Solicitud.DescripcionEvento);
end;

procedure TPruebasEmisionFiscal.Solicitud_OperacionPermiteDescripcion;
var
  Solicitud: TSolicitudEmisionFiscal;
begin
  Solicitud := TSolicitudEmisionFiscal.ParaOperacion(
    'F',
    '42',
    'USUARIO',
    'ANULACION',
    'Anulación',
    True,
    'Anulación desde caja');
  Assert.AreEqual(
    'Anulación desde caja',
    Solicitud.DescripcionEvento);
end;

procedure TPruebasEmisionFiscal.Solicitud_AltaPermiteOmitirEvento;
var
  Solicitud: TSolicitudEmisionFiscal;
begin
  Solicitud := TSolicitudEmisionFiscal.ParaAlta(
    'F',
    '42',
    'USUARIO',
    '',
    False);
  Assert.AreEqual(fefAlta, Solicitud.Flujo);
  Assert.AreEqual('ALTA', Solicitud.TipoOperacion);
  Assert.IsFalse(Solicitud.RegistrarEvento);
end;

procedure TPruebasEmisionFiscal.Solicitud_ConsolidacionUsaAlta;
var
  Solicitud: TSolicitudEmisionFiscal;
begin
  Solicitud := TSolicitudEmisionFiscal.ParaConsolidacion(
    'F',
    '42',
    'USUARIO');
  Assert.AreEqual(fefConsolidacion, Solicitud.Flujo);
  Assert.AreEqual('ALTA', Solicitud.TipoOperacion);
  Assert.IsTrue(Solicitud.BorrarMovimientos);
  Assert.IsTrue(Solicitud.RegistrarEvento);
  Assert.IsNotEmpty(Solicitud.DescripcionEvento);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasEmisionFiscal);

end.
