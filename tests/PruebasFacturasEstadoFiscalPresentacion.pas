{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasEstadoFiscalPresentacion                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza el bloqueo por fase fiscal de facturas sin usar BBDD.         }
{******************************************************************************}
unit PruebasFacturasEstadoFiscalPresentacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasEstadoFiscalPresentacion = class
  public
    [Test]
    procedure BorradorPendiente_EsEditableYConsolidable;
    [Test]
    procedure BorradorConsolidado_SeBloqueaYPermiteImprimir;
    [Test]
    procedure SinVerifactu_ConservaEdicionEImpresion;
    [Test]
    procedure FaseTerminal_QuedaBloqueadaTambienSinVerifactu;
    [Test]
    procedure Insercion_FuerzaEdicionSinActualizarBotones;
    [Test]
    procedure DataSetVacio_DeshabilitaAccionesSinVerifactu;
  end;

implementation

uses
  Data.DB, inLibFacturasEstadoFiscalPresentacion;

procedure TPruebasFacturasEstadoFiscalPresentacion.
  BorradorPendiente_EsEditableYConsolidable;
var
  Configuracion: TConfiguracionEstadoFiscalFactura;
begin
  Configuracion := CrearConfiguracionEstadoFiscalFactura(
    'borrador',
    False,
    False,
    False,
    dsBrowse);
  Assert.IsTrue(Configuracion.EsBorradorPendiente);
  Assert.IsTrue(Configuracion.Editable);
  Assert.IsTrue(Configuracion.ActualizarAcciones);
  Assert.IsTrue(Configuracion.PuedeConsolidar);
  Assert.IsFalse(Configuracion.PuedeImprimir);
end;

procedure TPruebasFacturasEstadoFiscalPresentacion.
  BorradorConsolidado_SeBloqueaYPermiteImprimir;
var
  Configuracion: TConfiguracionEstadoFiscalFactura;
begin
  Configuracion := CrearConfiguracionEstadoFiscalFactura(
    'BORRADOR',
    True,
    False,
    False,
    dsBrowse);
  Assert.IsFalse(Configuracion.EsBorradorPendiente);
  Assert.IsFalse(Configuracion.Editable);
  Assert.IsFalse(Configuracion.PuedeConsolidar);
  Assert.IsTrue(Configuracion.PuedeImprimir);
end;

procedure TPruebasFacturasEstadoFiscalPresentacion.
  SinVerifactu_ConservaEdicionEImpresion;
var
  Configuracion: TConfiguracionEstadoFiscalFactura;
begin
  Configuracion := CrearConfiguracionEstadoFiscalFactura(
    'SIN_VERIFACTU',
    True,
    True,
    False,
    dsBrowse);
  Assert.IsFalse(Configuracion.EsBorradorPendiente);
  Assert.IsTrue(Configuracion.Editable);
  Assert.IsFalse(Configuracion.PuedeConsolidar);
  Assert.IsTrue(Configuracion.PuedeImprimir);
end;

procedure TPruebasFacturasEstadoFiscalPresentacion.
  FaseTerminal_QuedaBloqueadaTambienSinVerifactu;
var
  Configuracion: TConfiguracionEstadoFiscalFactura;
begin
  Configuracion := CrearConfiguracionEstadoFiscalFactura(
    'ANULADA',
    True,
    True,
    False,
    dsBrowse);
  Assert.IsFalse(Configuracion.Editable);
  Assert.IsFalse(Configuracion.PuedeConsolidar);
  Assert.IsTrue(Configuracion.PuedeImprimir);
end;

procedure TPruebasFacturasEstadoFiscalPresentacion.
  Insercion_FuerzaEdicionSinActualizarBotones;
var
  Configuracion: TConfiguracionEstadoFiscalFactura;
begin
  Configuracion := CrearConfiguracionEstadoFiscalFactura(
    'ANULADA',
    True,
    False,
    False,
    dsInsert);
  Assert.IsTrue(Configuracion.Editable);
  Assert.IsFalse(Configuracion.ActualizarAcciones);
end;

procedure TPruebasFacturasEstadoFiscalPresentacion.
  DataSetVacio_DeshabilitaAccionesSinVerifactu;
var
  Configuracion: TConfiguracionEstadoFiscalFactura;
begin
  Configuracion := CrearConfiguracionEstadoFiscalFactura(
    '',
    False,
    True,
    True,
    dsBrowse);
  Assert.IsTrue(Configuracion.Editable);
  Assert.IsFalse(Configuracion.PuedeConsolidar);
  Assert.IsFalse(Configuracion.PuedeImprimir);
end;

initialization
  TDUnitX.RegisterTestFixture(
    TPruebasFacturasEstadoFiscalPresentacion);

end.
