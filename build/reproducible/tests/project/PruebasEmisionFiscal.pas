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
    [Test]
    procedure Reintento_AumentaEsperaSinSuperarTope;
    [Test]
    procedure Reintento_AgotadoQuedaEnError;
    [Test]
    procedure ConstruccionAlta_MismaEntradaEsIdempotente;
    [Test]
    procedure RespuestaDuplicada_SeConsideraAceptada;
    [Test]
    procedure RespuestaParcial_ConservaCodigoYDescripcion;
  end;

implementation

uses
  inLibVerifactu, inLibVerifactuTipos,
  inLibEmisionFiscalIntf, inLibEmisionFiscal,
  inLibVerifactuReintentos, inLibVerifactuConstruccionEnvio;

function CrearEntradaAlta: TEntradaConstruccionRegistroAlta;
begin
  Result := Default(TEntradaConstruccionRegistroAlta);
  Result.Serie := 'F';
  Result.Numero := '42';
  Result.NumSerieFactura := 'F42';
  Result.NifEmisor := 'B12345678';
  Result.NombreEmisor := 'Empresa & Pruebas';
  Result.FechaExpedicion := '05-08-2026';
  Result.TipoFactura := 'F1';
  Result.NifCliente := '12345678Z';
  Result.NombreCliente := 'Cliente de pruebas';
  Result.CuotaTotal := '21.00';
  Result.ImporteTotal := '121.00';
  Result.FechaHoraHuso := '2026-08-05T10:00:00+02:00';
  Result.SistemaInformaticoXml := '<sum1:SistemaInformatico/>';
  Result.DesgloseXml := '<sum1:DetalleDesglose/>';
  Result.DescripcionOperacion := 'Venta';
end;

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

procedure TPruebasEmisionFiscal.
  Reintento_AumentaEsperaSinSuperarTope;
begin
  Assert.AreEqual(60, CalcularEsperaReintentoVerifactu(0));
  Assert.AreEqual(120, CalcularEsperaReintentoVerifactu(1));
  Assert.AreEqual(1920, CalcularEsperaReintentoVerifactu(30));
end;

procedure TPruebasEmisionFiscal.Reintento_AgotadoQuedaEnError;
begin
  Assert.AreEqual(
    'PENDIENTE',
    CalcularEstadoReintentoVerifactu(8, 10));
  Assert.AreEqual(
    'ERROR',
    CalcularEstadoReintentoVerifactu(9, 10));
end;

procedure TPruebasEmisionFiscal.
  ConstruccionAlta_MismaEntradaEsIdempotente;
var
  oEntrada: TEntradaConstruccionRegistroAlta;
  oPrimera: TResultadoConstruccionRegistroAlta;
  oSegunda: TResultadoConstruccionRegistroAlta;
begin
  oEntrada := CrearEntradaAlta;
  oPrimera := ConstruirRegistroAltaVerifactu(oEntrada);
  oSegunda := ConstruirRegistroAltaVerifactu(oEntrada);
  Assert.AreEqual(oPrimera.Huella, oSegunda.Huella);
  Assert.AreEqual(oPrimera.Xml, oSegunda.Xml);
  Assert.AreEqual(
    '3C6EAE0660A1BC7DBAA75598E3B4AA105D0C3C23543A55FEFA04AA411D905175',
    oPrimera.Huella);
  Assert.Contains(oPrimera.Xml, 'Empresa &amp; Pruebas');
  Assert.Contains(oPrimera.Xml, '<sum1:PrimerRegistro>S');
end;

procedure TPruebasEmisionFiscal.
  RespuestaDuplicada_SeConsideraAceptada;
var
  oRespuesta: TInterpretacionRespuestaAeat;
begin
  oRespuesta := InterpretarRespuestaAeat(200,
    '<r:EstadoEnvio>Incorrecto</r:EstadoEnvio>' +
    '<r:EstadoRegistro>Incorrecto</r:EstadoRegistro>' +
    '<r:CodigoErrorRegistro>3000</r:CodigoErrorRegistro>' +
    '<r:DescripcionErrorRegistro>Registro duplicado' +
    '</r:DescripcionErrorRegistro>');
  Assert.IsTrue(oRespuesta.EsHttpCorrecto);
  Assert.IsTrue(oRespuesta.Duplicado);
  Assert.IsTrue(oRespuesta.Aceptado);
end;

procedure TPruebasEmisionFiscal.
  RespuestaParcial_ConservaCodigoYDescripcion;
var
  oRespuesta: TInterpretacionRespuestaAeat;
begin
  oRespuesta := InterpretarRespuestaAeat(200,
    '<EstadoEnvio>ParcialmenteCorrecto</EstadoEnvio>' +
    '<EstadoRegistro>AceptadoConErrores</EstadoRegistro>' +
    '<CodigoErrorRegistro>2001</CodigoErrorRegistro>' +
    '<DescripcionErrorRegistro>Aviso fiscal</DescripcionErrorRegistro>' +
    '<TiempoEsperaEnvio>60</TiempoEsperaEnvio>');
  Assert.IsTrue(oRespuesta.Aceptado);
  Assert.IsFalse(oRespuesta.Duplicado);
  Assert.AreEqual('AceptadoConErrores', oRespuesta.EstadoRegistro);
  Assert.AreEqual('2001', oRespuesta.CodigoError);
  Assert.AreEqual('Aviso fiscal', oRespuesta.DescripcionError);
  Assert.AreEqual(60, oRespuesta.EsperaSegundos);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasEmisionFiscal);

end.
