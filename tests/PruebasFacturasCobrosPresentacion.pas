{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasCobrosPresentacion                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la presentación de efectos y recibos sin usar BBDD.           }
{******************************************************************************}
unit PruebasFacturasCobrosPresentacion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasCobrosPresentacion = class
  public
    [Test]
    procedure FacturaNormal_ConfiguraEfectosSoloLectura;
    [Test]
    procedure FacturaSimplificada_ConfiguraRecibosEditables;
    [Test]
    procedure TipoDesconocido_ConservaComportamientoDeRecibos;
    [Test]
    procedure TodasLasColumnas_TienenCampoEnAmbosOrigenes;
  end;

implementation

uses
  inLibFacturasCobrosPresentacion;

procedure TPruebasFacturasCobrosPresentacion.
  FacturaNormal_ConfiguraEfectosSoloLectura;
var
  Configuracion: TConfiguracionCobrosFactura;
begin
  Configuracion := CrearConfiguracionCobrosFactura('NORMAL');
  Assert.IsTrue(Configuracion.EsEfectosVenta);
  Assert.IsFalse(Configuracion.PermiteEdicion);
  Assert.IsFalse(Configuracion.MostrarImprimir);
  Assert.AreEqual('efectos de cobro', Configuracion.TextoPlural);
  Assert.AreEqual(
    'EfectosCobro_Borrador_',
    Configuracion.PrefijoExportacion);
  Assert.AreEqual(
    'NUMERO_FAC_EFV',
    Configuracion.Campos[ccfNumeroFactura]);
  Assert.AreEqual(
    'REFERENCIA_DOCUMENTO_EFV',
    Configuracion.Campos[ccfLocalidad]);
  Assert.AreEqual('&3_Efectos', Configuracion.CaptionPestana);
  Assert.AreEqual(
    'Referencia',
    Configuracion.Captions[ccfLocalidad]);
  Assert.IsTrue(
    Configuracion.ColumnasDetalleVisibles = [ccfLocalidad]);
end;

procedure TPruebasFacturasCobrosPresentacion.
  FacturaSimplificada_ConfiguraRecibosEditables;
var
  Configuracion: TConfiguracionCobrosFactura;
begin
  Configuracion := CrearConfiguracionCobrosFactura('SIMPLIFICADA');
  Assert.IsFalse(Configuracion.EsEfectosVenta);
  Assert.IsTrue(Configuracion.PermiteEdicion);
  Assert.IsTrue(Configuracion.MostrarImprimir);
  Assert.AreEqual('recibos', Configuracion.TextoPlural);
  Assert.AreEqual(
    'Recibos_Borrador_',
    Configuracion.PrefijoExportacion);
  Assert.AreEqual(
    'NUMERO_FAC_REC',
    Configuracion.Campos[ccfNumeroFactura]);
  Assert.AreEqual(
    'LOCALIDAD_EXPEDICION_RECIBO_REC',
    Configuracion.Campos[ccfLocalidad]);
  Assert.AreEqual('&3_Recibos', Configuracion.CaptionPestana);
  Assert.AreEqual(
    'Localidad Expedición',
    Configuracion.Captions[ccfLocalidad]);
  Assert.IsTrue(
    Configuracion.ColumnasDetalleVisibles = [
      ccfLocalidad,
      ccfDireccionCliente,
      ccfPoblacionCliente,
      ccfProvinciaCliente,
      ccfCodigoPostalCliente,
      ccfImporteLetra]);
end;

procedure TPruebasFacturasCobrosPresentacion.
  TipoDesconocido_ConservaComportamientoDeRecibos;
var
  Configuracion: TConfiguracionCobrosFactura;
begin
  Configuracion := CrearConfiguracionCobrosFactura('OTRA');
  Assert.IsFalse(Configuracion.EsEfectosVenta);
  Assert.AreEqual(
    'NUMERO_PLAZO_REC',
    Configuracion.Campos[ccfNumeroPlazo]);
end;

procedure TPruebasFacturasCobrosPresentacion.
  TodasLasColumnas_TienenCampoEnAmbosOrigenes;
var
  Campo: TCampoCobroFactura;
  Efectos: TConfiguracionCobrosFactura;
  Recibos: TConfiguracionCobrosFactura;
begin
  Efectos := CrearConfiguracionCobrosFactura('NORMAL');
  Recibos := CrearConfiguracionCobrosFactura('SIMPLIFICADA');
  for Campo := Low(TCampoCobroFactura) to
    High(TCampoCobroFactura) do
  begin
    Assert.IsNotEmpty(Efectos.Campos[Campo]);
    Assert.IsNotEmpty(Recibos.Campos[Campo]);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasCobrosPresentacion);

end.
