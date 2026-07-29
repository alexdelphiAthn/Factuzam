{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasTotalesDocumentos                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de integración en memoria para los cálculos fiscales y de         }
{    prendas de los documentos de compras y ventas.                            }
{******************************************************************************}
unit PruebasTotalesDocumentos;

interface

uses
  System.SysUtils, Data.DB, Datasnap.DBClient, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasTotalesDocumentos = class
  private
    FCabecera: TClientDataSet;
    FLineas: TClientDataSet;
    FNumeroPostsLineas: Integer;
    procedure ContarPostLinea(DataSet: TDataSet);
    procedure AgregarCampoTexto(ADataSet: TClientDataSet;
      const ANombre: string; ATamano: Integer = 20);
    procedure AgregarCampoFloat(ADataSet: TClientDataSet;
      const ANombre: string);
    procedure AgregarCampoEntero(ADataSet: TClientDataSet;
      const ANombre: string);
    procedure AgregarCamposCabecera;
    procedure AgregarCamposLineas;
    procedure AgregarCamposFactura;
    procedure AgregarCamposLineasFactura;
    procedure AgregarLinea(const ATipoIva: string; APorcentajeIva,
      ATotal, ACantidad: Double; ATieneTotalUnidades: Boolean = False;
      ATotalUnidades: Double = 0; const AIncluir: string = 'S');
    procedure AgregarLineaFactura(const ATipoIva: string;
      APorcentajeIva, ACantidad, APrecioSinIva: Double;
      const AImpuestosIncluidos: string = 'N';
      APrecioConIva: Double = 0);
    procedure PonerFloatCabecera(const ACampo: string; AValor: Double);
    procedure PonerTextoCabecera(const ACampo, AValor: string);
    function TotalCabecera(const ACampo: string): Double;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Venta_AgrupaTiposYRestauraFiltro;
    [Test]
    procedure Compra_AplicaDescuentosYRetencionSinConexion;
    [Test]
    procedure Compra_ExentaClasificaLaBaseEnTipoE;
    [Test]
    procedure Venta_ExentaClasificaLaBaseEnTipoE;
    [Test]
    procedure Venta_AplicaRecargo;
    [Test]
    procedure Venta_AplicaRetencion;
    [Test]
    procedure Venta_RectificativaConImporteNegativo;
    [Test]
    procedure PrendasVenta_IgnoraFiltroYLoRestaura;
    [Test]
    procedure PrendasCompra_PriorizaTotalUnidades;
    [Test]
    procedure PrendasVenta_NoInterfiereConUnaEdicion;
    [Test]
    procedure Factura_PosponerCalculoMientrasResuelveReferencia;
    [Test]
    procedure Factura_PosponerCalculoMientrasResuelveSku;
    [Test]
    procedure Factura_SinLineasNoIntentaActualizar;
    [Test]
    procedure Factura_RecalcularLineaNoAcumulaDocumento;
    [Test]
    procedure Factura_AgrupaNormalReducidoYExento;
    [Test]
    procedure Factura_AplicaRetencionSinRecargoNoResuelto;
    [Test]
    procedure Factura_SimplificadaNoAplicaRecargoNiRetencion;
    [Test]
    procedure Factura_RectificativaConCantidadNegativa;
    [Test]
    procedure Factura_ImpuestoIncluidoCalculaCuotaPorDiferencia;
    [Test]
    procedure Factura_RecalculoEstableNoPosteaLineas;
    [Test]
    procedure Factura_CambioFiscalPosteaSoloLineasAfectadas;
    [Test]
    procedure Nucleo_AgrupaIvaRecargoYRetencion;
    [Test]
    procedure Nucleo_SimplificadaAnulaRecargoYRetencion;
    [Test]
    procedure Nucleo_ImpuestoIncluidoRedondeaPorDiferencia;
    [Test]
    procedure Nucleo_RectificativaConservaSigno;
  end;

implementation

uses
  inLibComprasImpuestos, inLibFacturas, inLibMotorFiscalVenta,
  inLibVentasImpuestos;

const
  MARGEN: Double = 0.000001;
  CODIGOS_IVA: array[0..3] of string =
    ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE: array[0..3] of string =
    ('REN', 'RER', 'RES', 'REE');

procedure TPruebasTotalesDocumentos.ContarPostLinea(
  DataSet: TDataSet);
begin
  Inc(FNumeroPostsLineas);
end;

procedure TPruebasTotalesDocumentos.AgregarCampoTexto(
  ADataSet: TClientDataSet; const ANombre: string; ATamano: Integer);
begin
  ADataSet.FieldDefs.Add(ANombre, ftString, ATamano);
end;

procedure TPruebasTotalesDocumentos.AgregarCampoFloat(
  ADataSet: TClientDataSet; const ANombre: string);
begin
  ADataSet.FieldDefs.Add(ANombre, ftFloat);
end;

procedure TPruebasTotalesDocumentos.AgregarCampoEntero(
  ADataSet: TClientDataSet; const ANombre: string);
begin
  ADataSet.FieldDefs.Add(ANombre, ftInteger);
end;

procedure TPruebasTotalesDocumentos.AgregarCamposCabecera;
const
  CAMPOS_TEXTO: array[0..15] of string = (
    'CODIGO_IVA_DOC',
    'CODIGO_EMP_DOC',
    'TIPO_IVA_DOC',
    'ESIVA_EXENTO_INTRACOMUNITARIO_DOC',
    'ESIVA_RECARGO_COMPRAS_DOC',
    'ESIVA_EXENTO_CLIENTE_DOC',
    'ESINTRACOMUNITARIO_CLIENTE_DOC',
    'ESIVA_RECARGO_CLIENTE_DOC',
    'ESAPLICA_RE_ZONA_IVA_DOC',
    'ESRETENCIONES_CLIENTE_DOC',
    'ESRETENCIONES_EMPRESA_DOC',
    'ESVENTA_ACTIVO_FIJO_DOC',
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_DOC',
    'NIF_CLIENTE_DOC',
    'RAZON_SOCIAL_CLIENTE_DOC',
    'DIRECCION1_CLIENTE_DOC');
  CAMPOS_FLOAT: array[0..16] of string = (
    'PORCENTAJE_IVAN_DOC',
    'PORCENTAJE_IVAR_DOC',
    'PORCENTAJE_IVAS_DOC',
    'PORCENTAJE_IVAE_DOC',
    'PORCENTAJE_REN_DOC',
    'PORCENTAJE_RER_DOC',
    'PORCENTAJE_RES_DOC',
    'PORCENTAJE_REE_DOC',
    'PORCENTAJE_RETENCION_DOC',
    'PORCENTAJE_DTO_COMERCIAL_DOC',
    'TOTAL_DTO_COMERCIAL_DOC',
    'PORCENTAJE_DTO_FINANCIERO_DOC',
    'TOTAL_DTO_FINANCIERO_DOC',
    'TOTAL_BRUTO_DOC',
    'TOTAL_BASES_DOC',
    'TOTAL_IMPUESTOS_DOC',
    'TOTAL_RETENCION_DOC');
var
  iIndice: Integer;
begin
  for iIndice := Low(CAMPOS_TEXTO) to High(CAMPOS_TEXTO) do
    AgregarCampoTexto(FCabecera, CAMPOS_TEXTO[iIndice], 80);
  AgregarCampoTexto(FCabecera, 'ESIRPF_IMP_INCL_ZONA_IVA_DOC');
  for iIndice := Low(CAMPOS_FLOAT) to High(CAMPOS_FLOAT) do
    AgregarCampoFloat(FCabecera, CAMPOS_FLOAT[iIndice]);
  AgregarCampoFloat(FCabecera, 'TOTAL_DOC');
  AgregarCampoFloat(FCabecera, 'TOTAL_LIQUIDO_DOC');
  for iIndice := Low(CODIGOS_IVA) to High(CODIGOS_IVA) do
  begin
    AgregarCampoFloat(FCabecera,
      'TOTAL_BASEI_' + CODIGOS_IVA[iIndice] + '_DOC');
    AgregarCampoFloat(FCabecera,
      'TOTAL_' + CODIGOS_IVA[iIndice] + '_DOC');
    AgregarCampoFloat(FCabecera,
      'TOTAL_' + CODIGOS_RE[iIndice] + '_DOC');
  end;
end;

procedure TPruebasTotalesDocumentos.AgregarCamposFactura;
const
  CAMPOS_TEXTO: array[0..17] of string = (
    'CODIGO_EMP_FAC',
    'TIPO_FAC',
    'RAZON_SOCIAL_EMPRESA_FAC',
    'CODIGO_CLI_FAC',
    'RAZON_SOCIAL_CLIENTE_FAC',
    'NIF_CLIENTE_FAC',
    'DIRECCION1_CLIENTE_FAC',
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC',
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC',
    'ESINTRACOMUNITARIO_CLIENTE_FAC',
    'ESVENTA_ACTIVO_FIJO_FAC',
    'ESRETENCIONES_CLIENTE_FAC',
    'ESRETENCIONES_EMPRESA_FAC',
    'ESIVA_EXENTO_CLIENTE_FAC',
    'ESIVA_RECARGO_CLIENTE_FAC',
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC',
    'ESAPLICA_RE_ZONA_IVA_FAC',
    'GRUPO_ZONA_IVA_EMPRESA_FAC');
  CAMPOS_FLOTANTES: array[0..17] of string = (
    'PORCENTAJE_IVAN_FAC',
    'PORCENTAJE_IVAR_FAC',
    'PORCENTAJE_IVAS_FAC',
    'PORCENTAJE_IVAE_FAC',
    'PORCENTAJE_REN_FAC',
    'PORCENTAJE_RER_FAC',
    'PORCENTAJE_RES_FAC',
    'PORCENTAJE_REE_FAC',
    'PORCENTAJE_RETENCION_FAC',
    'TOTAL_BASEI_IVAN_FAC',
    'TOTAL_BASEI_IVAR_FAC',
    'TOTAL_BASEI_IVAS_FAC',
    'TOTAL_BASEI_IVAE_FAC',
    'TOTAL_BASES_FAC',
    'TOTAL_IMPUESTOS_FAC',
    'TOTAL_RETENCION_FAC',
    'TOTAL_LIQUIDO_FAC',
    'TOTAL_IVAN_FAC');
var
  Indice: Integer;
begin
  for Indice := Low(CAMPOS_TEXTO) to High(CAMPOS_TEXTO) do
    AgregarCampoTexto(FCabecera, CAMPOS_TEXTO[Indice], 100);
  AgregarCampoTexto(FCabecera, 'CODIGO_IVA_FAC');
  FCabecera.FieldDefs.Add('FECHA_FAC', ftDate);
  for Indice := Low(CAMPOS_FLOTANTES) to High(CAMPOS_FLOTANTES) do
    AgregarCampoFloat(FCabecera, CAMPOS_FLOTANTES[Indice]);
  AgregarCampoFloat(FCabecera, 'TOTAL_IVAR_FAC');
  AgregarCampoFloat(FCabecera, 'TOTAL_IVAS_FAC');
  AgregarCampoFloat(FCabecera, 'TOTAL_IVAE_FAC');
  AgregarCampoFloat(FCabecera, 'TOTAL_REN_FAC');
  AgregarCampoFloat(FCabecera, 'TOTAL_RER_FAC');
  AgregarCampoFloat(FCabecera, 'TOTAL_RES_FAC');
  AgregarCampoFloat(FCabecera, 'TOTAL_REE_FAC');
end;

procedure TPruebasTotalesDocumentos.AgregarCamposLineas;
begin
  AgregarCampoTexto(FLineas, 'TIPO_IVA_ARTICULO_LIN');
  AgregarCampoFloat(FLineas, 'PORCENTAJE_IVA_LIN');
  AgregarCampoFloat(FLineas, 'TOTAL_LINEA_LIN');
  AgregarCampoTexto(FLineas, 'CODIGO_ART_LIN');
  AgregarCampoFloat(FLineas, 'CANTIDAD_LIN');
  AgregarCampoFloat(FLineas, 'TOTAL_UNIDADES_LIN');
  AgregarCampoTexto(FLineas, 'INCLUIR');
  AgregarCampoTexto(FLineas, 'CODIGO_ART_FACLIN');
  AgregarCampoTexto(FLineas, 'DESCRIPCION_ARTICULO_FACLIN', 100);
  AgregarCampoTexto(FLineas, 'CODIGO_UNIDAD_FACLIN', 100);
  AgregarCampoEntero(FLineas, 'NUM_ATRIBUTOS_REQ_FACTURA_LINEA');
end;

procedure TPruebasTotalesDocumentos.AgregarCamposLineasFactura;
begin
  AgregarCampoTexto(FLineas, 'LINEA_FACLIN');
  AgregarCampoFloat(FLineas, 'CANTIDAD_FACLIN');
  AgregarCampoTexto(FLineas, 'ESIMP_INCL_TARIFA_FACLIN');
  AgregarCampoTexto(FLineas, 'TIPO_IVA_ARTICULO_FACLIN');
  AgregarCampoFloat(FLineas, 'PORCENTAJE_IVA_FACLIN');
  AgregarCampoFloat(FLineas, 'PRECIO_SALIDA_FACLIN');
  AgregarCampoFloat(FLineas, 'PORCENTAJE_DTO_FACLIN');
  AgregarCampoFloat(FLineas, 'PRECIO_DTO_FACLIN');
  AgregarCampoFloat(FLineas, 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN');
  AgregarCampoFloat(FLineas, 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN');
  AgregarCampoFloat(FLineas, 'TOTAL_FACLIN');
  AgregarCampoFloat(FLineas, 'TOTAL_FAC_SIVA_FACLIN');
end;

procedure TPruebasTotalesDocumentos.AgregarLinea(
  const ATipoIva: string; APorcentajeIva, ATotal, ACantidad: Double;
  ATieneTotalUnidades: Boolean; ATotalUnidades: Double;
  const AIncluir: string);
begin
  FLineas.Append;
  FLineas.FieldByName('TIPO_IVA_ARTICULO_LIN').AsString := ATipoIva;
  FLineas.FieldByName('PORCENTAJE_IVA_LIN').AsFloat :=
    APorcentajeIva;
  FLineas.FieldByName('TOTAL_LINEA_LIN').AsFloat := ATotal;
  FLineas.FieldByName('CODIGO_ART_LIN').AsString := 'ART-' + ATipoIva;
  FLineas.FieldByName('CANTIDAD_LIN').AsFloat := ACantidad;
  if ATieneTotalUnidades then
    FLineas.FieldByName('TOTAL_UNIDADES_LIN').AsFloat :=
      ATotalUnidades;
  FLineas.FieldByName('INCLUIR').AsString := AIncluir;
  FLineas.Post;
end;

procedure TPruebasTotalesDocumentos.AgregarLineaFactura(
  const ATipoIva: string;
  APorcentajeIva, ACantidad, APrecioSinIva: Double;
  const AImpuestosIncluidos: string;
  APrecioConIva: Double);
begin
  FLineas.Append;
  FLineas.FieldByName('LINEA_FACLIN').AsString :=
    Format('%.4d', [FLineas.RecordCount * 10 + 10]);
  FLineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
    'ART-' + ATipoIva;
  FLineas.FieldByName(
    'DESCRIPCION_ARTICULO_FACLIN').AsString := 'Artículo fiscal';
  FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
    'SKU-' + ATipoIva;
  FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := ACantidad;
  FLineas.FieldByName(
    'ESIMP_INCL_TARIFA_FACLIN').AsString := AImpuestosIncluidos;
  FLineas.FieldByName(
    'TIPO_IVA_ARTICULO_FACLIN').AsString := ATipoIva;
  FLineas.FieldByName(
    'PORCENTAJE_IVA_FACLIN').AsFloat := APorcentajeIva;
  FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat :=
    APrecioSinIva;
  FLineas.FieldByName(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
    APrecioSinIva;
  FLineas.FieldByName(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
    APrecioConIva;
  FLineas.Post;
end;

procedure TPruebasTotalesDocumentos.PonerFloatCabecera(
  const ACampo: string; AValor: Double);
begin
  FCabecera.Edit;
  FCabecera.FieldByName(ACampo).AsFloat := AValor;
  FCabecera.Post;
end;

procedure TPruebasTotalesDocumentos.PonerTextoCabecera(
  const ACampo, AValor: string);
begin
  FCabecera.Edit;
  FCabecera.FieldByName(ACampo).AsString := AValor;
  FCabecera.Post;
end;

function TPruebasTotalesDocumentos.TotalCabecera(
  const ACampo: string): Double;
begin
  Result := FCabecera.FieldByName(ACampo).AsFloat;
end;

procedure TPruebasTotalesDocumentos.Preparar;
begin
  FCabecera := TClientDataSet.Create(nil);
  FLineas := TClientDataSet.Create(nil);
  AgregarCamposCabecera;
  AgregarCamposFactura;
  AgregarCamposLineas;
  AgregarCamposLineasFactura;
  FCabecera.CreateDataSet;
  FLineas.CreateDataSet;
  FCabecera.Append;
  FCabecera.FieldByName('CODIGO_IVA_DOC').AsString := '';
  FCabecera.FieldByName('CODIGO_EMP_DOC').AsString := '';
  FCabecera.FieldByName('TIPO_IVA_DOC').AsString := 'N';
  FCabecera.FieldByName('PORCENTAJE_IVAN_DOC').AsFloat := 21;
  FCabecera.FieldByName('PORCENTAJE_IVAR_DOC').AsFloat := 10;
  FCabecera.FieldByName('PORCENTAJE_IVAS_DOC').AsFloat := 4;
  FCabecera.FieldByName('PORCENTAJE_IVAE_DOC').AsFloat := 0;
  FCabecera.FieldByName('PORCENTAJE_REN_DOC').AsFloat := 5.2;
  FCabecera.FieldByName('PORCENTAJE_RER_DOC').AsFloat := 1.4;
  FCabecera.FieldByName('PORCENTAJE_RES_DOC').AsFloat := 0.5;
  FCabecera.FieldByName('PORCENTAJE_REE_DOC').AsFloat := 0;
  FCabecera.FieldByName(
    'ESIVA_EXENTO_INTRACOMUNITARIO_DOC').AsString := 'N';
  FCabecera.FieldByName('ESIVA_RECARGO_COMPRAS_DOC').AsString := 'N';
  FCabecera.FieldByName('ESIVA_EXENTO_CLIENTE_DOC').AsString := 'N';
  FCabecera.FieldByName('ESINTRACOMUNITARIO_CLIENTE_DOC').AsString := 'N';
  FCabecera.FieldByName('ESIVA_RECARGO_CLIENTE_DOC').AsString := 'N';
  FCabecera.FieldByName('ESAPLICA_RE_ZONA_IVA_DOC').AsString := 'S';
  FCabecera.FieldByName('ESRETENCIONES_CLIENTE_DOC').AsString := 'N';
  FCabecera.FieldByName('ESRETENCIONES_EMPRESA_DOC').AsString := 'N';
  FCabecera.FieldByName('ESVENTA_ACTIVO_FIJO_DOC').AsString := 'N';
  FCabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_DOC').AsString := 'N';
  FCabecera.FieldByName(
    'ESIRPF_IMP_INCL_ZONA_IVA_DOC').AsString := 'N';
  FCabecera.FieldByName('FECHA_FAC').AsDateTime := Date;
  FCabecera.FieldByName('CODIGO_EMP_FAC').AsString := 'EMP';
  FCabecera.FieldByName('TIPO_FAC').AsString := 'NORMAL';
  FCabecera.FieldByName(
    'RAZON_SOCIAL_EMPRESA_FAC').AsString := 'Empresa';
  FCabecera.FieldByName('CODIGO_CLI_FAC').AsString := 'CLI';
  FCabecera.FieldByName(
    'RAZON_SOCIAL_CLIENTE_FAC').AsString := 'Cliente';
  FCabecera.FieldByName('NIF_CLIENTE_FAC').AsString := '12345678Z';
  FCabecera.FieldByName(
    'DIRECCION1_CLIENTE_FAC').AsString := 'Dirección';
  FCabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESINTRACOMUNITARIO_CLIENTE_FAC').AsString := 'N';
  FCabecera.FieldByName('ESVENTA_ACTIVO_FIJO_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESRETENCIONES_CLIENTE_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESRETENCIONES_EMPRESA_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESIVA_EXENTO_CLIENTE_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESIVA_RECARGO_CLIENTE_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString := 'N';
  FCabecera.FieldByName(
    'ESAPLICA_RE_ZONA_IVA_FAC').AsString := 'S';
  FCabecera.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat := 21;
  FCabecera.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat := 10;
  FCabecera.FieldByName('PORCENTAJE_IVAS_FAC').AsFloat := 4;
  FCabecera.FieldByName('PORCENTAJE_IVAE_FAC').AsFloat := 0;
  FCabecera.FieldByName('PORCENTAJE_REN_FAC').AsFloat := 5.2;
  FCabecera.FieldByName('PORCENTAJE_RER_FAC').AsFloat := 1.4;
  FCabecera.FieldByName('PORCENTAJE_RES_FAC').AsFloat := 0.5;
  FCabecera.FieldByName('PORCENTAJE_REE_FAC').AsFloat := 0;
  FCabecera.Post;
end;

procedure TPruebasTotalesDocumentos.Limpiar;
begin
  FreeAndNil(FLineas);
  FreeAndNil(FCabecera);
end;

procedure TPruebasTotalesDocumentos.Venta_AgrupaTiposYRestauraFiltro;
begin
  AgregarLinea('N', 21, 100, 1, False, 0, 'S');
  AgregarLinea('R', 10, 50, 1, False, 0, 'N');
  FLineas.Filter := 'INCLUIR = ''S''';
  FLineas.Filtered := True;
  CalcularTotalesDocumentoVenta(nil, FCabecera, FLineas, 'DOC',
    'TOTAL_LINEA_LIN', 'TIPO_IVA_ARTICULO_LIN',
    'PORCENTAJE_IVA_LIN');
  Assert.IsTrue(FLineas.Filtered);
  Assert.AreEqual(1, FLineas.RecordCount);
  Assert.AreEqual(Double(100),
    TotalCabecera('TOTAL_BASEI_IVAN_DOC'), MARGEN);
  Assert.AreEqual(Double(50),
    TotalCabecera('TOTAL_BASEI_IVAR_DOC'), MARGEN);
  Assert.AreEqual(Double(21), TotalCabecera('TOTAL_IVAN_DOC'), MARGEN);
  Assert.AreEqual(Double(5), TotalCabecera('TOTAL_IVAR_DOC'), MARGEN);
  Assert.AreEqual(Double(150),
    TotalCabecera('TOTAL_BASES_DOC'), MARGEN);
  Assert.AreEqual(Double(26),
    TotalCabecera('TOTAL_IMPUESTOS_DOC'), MARGEN);
  Assert.AreEqual(Double(176), TotalCabecera('TOTAL_DOC'), MARGEN);
  Assert.AreEqual(Double(176),
    TotalCabecera('TOTAL_LIQUIDO_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Compra_AplicaDescuentosYRetencionSinConexion;
begin
  PonerTextoCabecera('ESIVA_RECARGO_COMPRAS_DOC', 'S');
  PonerFloatCabecera('PORCENTAJE_DTO_COMERCIAL_DOC', 10);
  PonerFloatCabecera('PORCENTAJE_DTO_FINANCIERO_DOC', 10);
  PonerFloatCabecera('PORCENTAJE_RETENCION_DOC', 2);
  AgregarLinea('N', 21, 100, 1);
  AgregarLinea('R', 10, 50, 1);
  CalcularTotalesDocumentoCompra(nil, FCabecera, FLineas, 'DOC',
    'TOTAL_LINEA_LIN', 'TIPO_IVA_ARTICULO_LIN',
    'PORCENTAJE_IVA_LIN');
  Assert.AreEqual(Double(150),
    TotalCabecera('TOTAL_BRUTO_DOC'), MARGEN);
  Assert.AreEqual(Double(15),
    TotalCabecera('TOTAL_DTO_COMERCIAL_DOC'), MARGEN);
  Assert.AreEqual(Double(13.5),
    TotalCabecera('TOTAL_DTO_FINANCIERO_DOC'), MARGEN);
  Assert.AreEqual(Double(135),
    TotalCabecera('TOTAL_BASES_DOC'), MARGEN);
  Assert.AreEqual(Double(23.4),
    TotalCabecera('TOTAL_IVAN_DOC') +
    TotalCabecera('TOTAL_IVAR_DOC'), MARGEN);
  Assert.AreEqual(Double(0),
    TotalCabecera('TOTAL_REN_DOC') +
    TotalCabecera('TOTAL_RER_DOC'), MARGEN);
  Assert.AreEqual(Double(23.4),
    TotalCabecera('TOTAL_IMPUESTOS_DOC'), MARGEN);
  Assert.AreEqual(Double(2.7),
    TotalCabecera('TOTAL_RETENCION_DOC'), MARGEN);
  Assert.AreEqual(Double(158.4), TotalCabecera('TOTAL_DOC'), MARGEN);
  Assert.AreEqual(Double(142.2),
    TotalCabecera('TOTAL_LIQUIDO_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Compra_ExentaClasificaLaBaseEnTipoE;
begin
  PonerTextoCabecera('ESIVA_EXENTO_INTRACOMUNITARIO_DOC', 'S');
  PonerTextoCabecera('ESIVA_RECARGO_COMPRAS_DOC', 'S');
  AgregarLinea('N', 21, 100, 1);
  CalcularTotalesDocumentoCompra(nil, FCabecera, FLineas, 'DOC',
    'TOTAL_LINEA_LIN', 'TIPO_IVA_ARTICULO_LIN',
    'PORCENTAJE_IVA_LIN');
  Assert.AreEqual(Double(100),
    TotalCabecera('TOTAL_BASEI_IVAE_DOC'), MARGEN);
  Assert.AreEqual(Double(0),
    TotalCabecera('TOTAL_BASEI_IVAN_DOC'), MARGEN);
  Assert.AreEqual(Double(0),
    TotalCabecera('TOTAL_IMPUESTOS_DOC'), MARGEN);
  Assert.AreEqual(Double(100), TotalCabecera('TOTAL_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Venta_ExentaClasificaLaBaseEnTipoE;
begin
  PonerTextoCabecera('ESIVA_EXENTO_CLIENTE_DOC', 'S');
  PonerTextoCabecera('ESIVA_RECARGO_CLIENTE_DOC', 'S');
  AgregarLinea('N', 21, 100, 1);
  CalcularTotalesDocumentoVenta(nil, FCabecera, FLineas, 'DOC',
    'TOTAL_LINEA_LIN', 'TIPO_IVA_ARTICULO_LIN',
    'PORCENTAJE_IVA_LIN');
  Assert.AreEqual(Double(100),
    TotalCabecera('TOTAL_BASEI_IVAE_DOC'), MARGEN);
  Assert.AreEqual(Double(0),
    TotalCabecera('TOTAL_BASEI_IVAN_DOC'), MARGEN);
  Assert.AreEqual(Double(0), TotalCabecera('TOTAL_REN_DOC'), MARGEN);
  Assert.AreEqual(Double(100), TotalCabecera('TOTAL_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.Venta_AplicaRecargo;
begin
  PonerTextoCabecera('ESIVA_RECARGO_CLIENTE_DOC', 'S');
  AgregarLinea('N', 21, 100, 1);
  CalcularTotalesDocumentoVenta(
    nil, FCabecera, FLineas, 'DOC', 'TOTAL_LINEA_LIN',
    'TIPO_IVA_ARTICULO_LIN', 'PORCENTAJE_IVA_LIN');
  Assert.AreEqual(
    Double(5.2), TotalCabecera('TOTAL_REN_DOC'), MARGEN);
  Assert.AreEqual(
    Double(26.2), TotalCabecera('TOTAL_IMPUESTOS_DOC'), MARGEN);
  Assert.AreEqual(
    Double(126.2), TotalCabecera('TOTAL_LIQUIDO_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.Venta_AplicaRetencion;
begin
  PonerTextoCabecera('ESRETENCIONES_CLIENTE_DOC', 'S');
  PonerTextoCabecera('ESRETENCIONES_EMPRESA_DOC', 'S');
  PonerTextoCabecera('NIF_CLIENTE_DOC', '12345678Z');
  PonerTextoCabecera('RAZON_SOCIAL_CLIENTE_DOC', 'Cliente');
  PonerTextoCabecera('DIRECCION1_CLIENTE_DOC', 'Dirección');
  PonerFloatCabecera('PORCENTAJE_RETENCION_DOC', 15);
  AgregarLinea('N', 21, 100, 1);
  CalcularTotalesDocumentoVenta(
    nil, FCabecera, FLineas, 'DOC', 'TOTAL_LINEA_LIN',
    'TIPO_IVA_ARTICULO_LIN', 'PORCENTAJE_IVA_LIN');
  Assert.AreEqual(
    Double(15), TotalCabecera('TOTAL_RETENCION_DOC'), MARGEN);
  Assert.AreEqual(
    Double(106), TotalCabecera('TOTAL_LIQUIDO_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Venta_RectificativaConImporteNegativo;
begin
  AgregarLinea('N', 21, -100, -1);
  CalcularTotalesDocumentoVenta(
    nil, FCabecera, FLineas, 'DOC', 'TOTAL_LINEA_LIN',
    'TIPO_IVA_ARTICULO_LIN', 'PORCENTAJE_IVA_LIN');
  Assert.AreEqual(
    Double(-100), TotalCabecera('TOTAL_BASES_DOC'), MARGEN);
  Assert.AreEqual(
    Double(-21), TotalCabecera('TOTAL_IMPUESTOS_DOC'), MARGEN);
  Assert.AreEqual(
    Double(-121), TotalCabecera('TOTAL_LIQUIDO_DOC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  PrendasVenta_IgnoraFiltroYLoRestaura;
var
  rTotal: Double;
begin
  AgregarLinea('N', 21, 10, 2, False, 0, 'S');
  AgregarLinea('R', 10, 20, 3, False, 0, 'N');
  FLineas.Filter := 'INCLUIR = ''S''';
  FLineas.Filtered := True;
  rTotal := TotalPrendasLineasVenta(FLineas,
    'TIPO_IVA_ARTICULO_LIN');
  Assert.AreEqual(Double(5), rTotal, MARGEN);
  Assert.IsTrue(FLineas.Filtered);
  Assert.AreEqual(1, FLineas.RecordCount);
end;

procedure TPruebasTotalesDocumentos.
  PrendasCompra_PriorizaTotalUnidades;
var
  rTotal: Double;
begin
  AgregarLinea('N', 21, 10, 2, False, 0, 'S');
  AgregarLinea('R', 10, 20, 3, True, 4, 'N');
  FLineas.Filter := 'INCLUIR = ''S''';
  FLineas.Filtered := True;
  rTotal := TotalPrendasLineasCompra(FLineas,
    'TIPO_IVA_ARTICULO_LIN', 'TOTAL_UNIDADES_LIN');
  Assert.AreEqual(Double(6), rTotal, MARGEN);
  Assert.IsTrue(FLineas.Filtered);
  Assert.AreEqual(1, FLineas.RecordCount);
end;

procedure TPruebasTotalesDocumentos.
  PrendasVenta_NoInterfiereConUnaEdicion;
var
  rTotal: Double;
begin
  AgregarLinea('N', 21, 10, 2);
  FLineas.Append;
  FLineas.FieldByName('TIPO_IVA_ARTICULO_LIN').AsString := 'R';
  FLineas.FieldByName('CANTIDAD_LIN').AsFloat := 3;
  rTotal := TotalPrendasLineasVenta(FLineas,
    'TIPO_IVA_ARTICULO_LIN');
  Assert.AreEqual(Double(0), rTotal, MARGEN);
  Assert.AreEqual(Integer(dsInsert), Integer(FLineas.State));
end;

procedure TPruebasTotalesDocumentos.
  Factura_PosponerCalculoMientrasResuelveReferencia;
var
  oTotales: TFacturaTotales;
begin
  FLineas.Append;
  FLineas.FieldByName('CODIGO_ART_FACLIN').AsString := '5050003';
  oTotales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(oTotales.ProcesarFacturaCompleta);
    Assert.AreEqual(Integer(dsInsert), Integer(FLineas.State));
    Assert.AreEqual('5050003',
      FLineas.FieldByName('CODIGO_ART_FACLIN').AsString);
  finally
    FreeAndNil(oTotales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_PosponerCalculoMientrasResuelveSku;
var
  oTotales: TFacturaTotales;
begin
  FLineas.Append;
  FLineas.FieldByName('CODIGO_ART_FACLIN').AsString := '5050003';
  FLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    'GAFAS UNISEX LINEA RECTA';
  FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := '5050003';
  FLineas.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := 2;
  oTotales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(oTotales.ProcesarFacturaCompleta);
    Assert.AreEqual(Integer(dsInsert), Integer(FLineas.State));
    Assert.AreEqual('5050003',
      FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
  finally
    FreeAndNil(oTotales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_SinLineasNoIntentaActualizar;
begin
  ActualizarLineaFactura(
    nil,
    nil,
    FCabecera,
    fpreciosal,
    10);
  Assert.IsTrue(FCabecera.Active);
end;

procedure TPruebasTotalesDocumentos.
  Factura_RecalcularLineaNoAcumulaDocumento;
begin
  AgregarLineaFactura('N', 21, 1, 100);
  PonerFloatCabecera('TOTAL_LIQUIDO_FAC', -1);
  Assert.IsTrue(
    RecalcularLineaFactura(
      FLineas,
      FCabecera,
      fpreciosal,
      200));
  Assert.AreEqual(
    Double(200),
    FLineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsFloat,
    MARGEN);
  Assert.AreEqual(
    Double(-1),
    TotalCabecera('TOTAL_LIQUIDO_FAC'),
    MARGEN);
  Assert.AreEqual(Integer(dsEdit), Integer(FLineas.State));
end;

procedure TPruebasTotalesDocumentos.
  Factura_AgrupaNormalReducidoYExento;
var
  Totales: TFacturaTotales;
begin
  AgregarLineaFactura('N', 21, 1, 100);
  AgregarLineaFactura('R', 10, 1, 50);
  AgregarLineaFactura('E', 0, 1, 25);
  Totales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(Totales.ProcesarFacturaCompleta);
    Assert.AreEqual(
      Double(100), Double(Totales.Totales.IVAN.BaseImponible), MARGEN);
    Assert.AreEqual(
      Double(50), Double(Totales.Totales.IVAR.BaseImponible), MARGEN);
    Assert.AreEqual(
      Double(25), Double(Totales.Totales.IVAE.BaseImponible), MARGEN);
    Assert.AreEqual(
      Double(26), Double(Totales.Totales.TotalImpuestos), MARGEN);
    Assert.AreEqual(
      Double(201), Double(Totales.Totales.TotalLiquido), MARGEN);
  finally
    FreeAndNil(Totales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_AplicaRetencionSinRecargoNoResuelto;
var
  Totales: TFacturaTotales;
begin
  PonerTextoCabecera('ESIVA_RECARGO_CLIENTE_FAC', 'S');
  PonerTextoCabecera('ESRETENCIONES_CLIENTE_FAC', 'S');
  PonerTextoCabecera('ESRETENCIONES_EMPRESA_FAC', 'S');
  PonerFloatCabecera('PORCENTAJE_RETENCION_FAC', 15);
  AgregarLineaFactura('N', 21, 1, 100);
  Totales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(Totales.ProcesarFacturaCompleta);
    Assert.AreEqual(
      Double(0), Double(Totales.Totales.IVAN.ImporteRE), MARGEN);
    Assert.AreEqual(
      Double(15), Double(Totales.Totales.TotalRetencion), MARGEN);
    Assert.AreEqual(
      Double(106), Double(Totales.Totales.TotalLiquido), MARGEN);
  finally
    FreeAndNil(Totales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_SimplificadaNoAplicaRecargoNiRetencion;
var
  Totales: TFacturaTotales;
begin
  PonerTextoCabecera('TIPO_FAC', 'SIMPLIFICADA');
  PonerTextoCabecera('ESIVA_RECARGO_CLIENTE_FAC', 'S');
  PonerTextoCabecera('ESRETENCIONES_CLIENTE_FAC', 'S');
  PonerTextoCabecera('ESRETENCIONES_EMPRESA_FAC', 'S');
  PonerFloatCabecera('PORCENTAJE_RETENCION_FAC', 15);
  AgregarLineaFactura('N', 21, 1, 100);
  Totales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(Totales.ProcesarFacturaCompleta);
    Assert.AreEqual(
      Double(0), Double(Totales.Totales.TotalREcargo), MARGEN);
    Assert.AreEqual(
      Double(0), Double(Totales.Totales.TotalRetencion), MARGEN);
    Assert.AreEqual(
      Double(121), Double(Totales.Totales.TotalLiquido), MARGEN);
  finally
    FreeAndNil(Totales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_RectificativaConCantidadNegativa;
var
  Totales: TFacturaTotales;
begin
  PonerTextoCabecera('TIPO_FAC', 'RECTIFICATIVA');
  AgregarLineaFactura('N', 21, -1, 100);
  Totales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(Totales.ProcesarFacturaCompleta);
    Assert.IsTrue(Totales.FTieneLineasNegativas);
    Assert.AreEqual(
      Double(-100), Double(Totales.Totales.TotalBases), MARGEN);
    Assert.AreEqual(
      Double(-21), Double(Totales.Totales.TotalImpuestos), MARGEN);
    Assert.AreEqual(
      Double(-121), Double(Totales.Totales.TotalLiquido), MARGEN);
  finally
    FreeAndNil(Totales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_ImpuestoIncluidoCalculaCuotaPorDiferencia;
var
  Totales: TFacturaTotales;
begin
  AgregarLineaFactura('N', 21, 1, 0, 'S', 100);
  Totales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(Totales.ProcesarFacturaCompleta);
    Assert.AreEqual(
      Double(82.64), Double(Totales.Totales.TotalBases), MARGEN);
    Assert.AreEqual(
      Double(17.36), Double(Totales.Totales.TotalImpuestos), MARGEN);
    Assert.AreEqual(
      Double(100), Double(Totales.Totales.TotalLiquido), MARGEN);
  finally
    FreeAndNil(Totales);
  end;
end;

procedure TPruebasTotalesDocumentos.
  Factura_RecalculoEstableNoPosteaLineas;
var
  oTotales: TFacturaTotales;
begin
  AgregarLineaFactura('N', 21, 1, 10);
  AgregarLineaFactura('R', 10, 1, 20);
  oTotales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(oTotales.ProcesarFacturaCompleta);
  finally
    FreeAndNil(oTotales);
  end;
  FNumeroPostsLineas := 0;
  FLineas.AfterPost := ContarPostLinea;
  oTotales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(oTotales.ProcesarFacturaCompleta);
  finally
    FreeAndNil(oTotales);
  end;
  Assert.AreEqual(0, FNumeroPostsLineas);
end;

procedure TPruebasTotalesDocumentos.
  Factura_CambioFiscalPosteaSoloLineasAfectadas;
var
  oTotales: TFacturaTotales;
begin
  AgregarLineaFactura('N', 21, 1, 100);
  AgregarLineaFactura('R', 10, 1, 50);
  oTotales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(oTotales.ProcesarFacturaCompleta);
  finally
    FreeAndNil(oTotales);
  end;
  PonerFloatCabecera('PORCENTAJE_IVAN_FAC', 22);
  FNumeroPostsLineas := 0;
  FLineas.AfterPost := ContarPostLinea;
  oTotales := TFacturaTotales.Create(nil, FCabecera, FLineas);
  try
    Assert.IsTrue(oTotales.ProcesarFacturaCompleta);
  finally
    FreeAndNil(oTotales);
  end;
  Assert.AreEqual(1, FNumeroPostsLineas);
  Assert.AreEqual(
    Double(22), TotalCabecera('TOTAL_IVAN_FAC'), MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Nucleo_AgrupaIvaRecargoYRetencion;
var
  Configuracion: TConfiguracionMotorFiscalVenta;
  Lineas: TLineasMotorFiscalVenta;
  Resultado: TResultadoMotorFiscalVenta;
begin
  FillChar(Configuracion, SizeOf(Configuracion), 0);
  Configuracion.AplicaRecargo := True;
  Configuracion.AplicaRetencion := True;
  Configuracion.ClienteConDatosFiscales := True;
  Configuracion.PorcentajeRetencion := 15;
  SetLength(Lineas, 3);
  Lineas[0].TipoIva := 'N';
  Lineas[0].Base := 100;
  Lineas[0].TotalConIva := 121;
  Lineas[0].PorcentajeIva := 21;
  Lineas[0].PorcentajeRecargo := 5.2;
  Lineas[1].TipoIva := 'R';
  Lineas[1].Base := 50;
  Lineas[1].TotalConIva := 55;
  Lineas[1].PorcentajeIva := 10;
  Lineas[1].PorcentajeRecargo := 1.4;
  Lineas[2].TipoIva := 'E';
  Lineas[2].Base := 25;
  Resultado := CalcularTotalesMotorFiscalVenta(
    Lineas, Configuracion);
  Assert.AreEqual(Double(175), Resultado.TotalBases, MARGEN);
  Assert.AreEqual(Double(26), Resultado.TotalIva, MARGEN);
  Assert.AreEqual(Double(5.9), Resultado.TotalRecargo, MARGEN);
  Assert.AreEqual(Double(26.25), Resultado.TotalRetencion, MARGEN);
  Assert.AreEqual(Double(180.65), Resultado.TotalLiquido, MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Nucleo_SimplificadaAnulaRecargoYRetencion;
var
  Configuracion: TConfiguracionMotorFiscalVenta;
  Lineas: TLineasMotorFiscalVenta;
  Resultado: TResultadoMotorFiscalVenta;
begin
  FillChar(Configuracion, SizeOf(Configuracion), 0);
  Configuracion.AplicaRecargo := True;
  Configuracion.AplicaRetencion := True;
  Configuracion.EsFacturaSimplificada := True;
  Configuracion.ClienteConDatosFiscales := True;
  Configuracion.PorcentajeRetencion := 15;
  SetLength(Lineas, 1);
  Lineas[0].TipoIva := 'N';
  Lineas[0].Base := 100;
  Lineas[0].TotalConIva := 121;
  Lineas[0].PorcentajeIva := 21;
  Lineas[0].PorcentajeRecargo := 5.2;
  Resultado := CalcularTotalesMotorFiscalVenta(
    Lineas, Configuracion);
  Assert.AreEqual(Double(21), Resultado.TotalIva, MARGEN);
  Assert.AreEqual(Double(0), Resultado.TotalRecargo, MARGEN);
  Assert.AreEqual(Double(0), Resultado.TotalRetencion, MARGEN);
  Assert.AreEqual(Double(121), Resultado.TotalLiquido, MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Nucleo_ImpuestoIncluidoRedondeaPorDiferencia;
var
  Configuracion: TConfiguracionMotorFiscalVenta;
  Lineas: TLineasMotorFiscalVenta;
  Resultado: TResultadoMotorFiscalVenta;
begin
  FillChar(Configuracion, SizeOf(Configuracion), 0);
  Configuracion.RedondearPorLinea := True;
  Configuracion.CalcularIvaIncluidoPorDiferencia := True;
  Configuracion.ClienteConDatosFiscales := True;
  SetLength(Lineas, 1);
  Lineas[0].TipoIva := 'N';
  Lineas[0].Base := 100 / 1.21;
  Lineas[0].TotalConIva := 100;
  Lineas[0].PorcentajeIva := 21;
  Lineas[0].ImpuestosIncluidos := True;
  Resultado := CalcularTotalesMotorFiscalVenta(
    Lineas, Configuracion);
  Assert.AreEqual(Double(82.64), Resultado.TotalBases, MARGEN);
  Assert.AreEqual(Double(17.36), Resultado.TotalIva, MARGEN);
  Assert.AreEqual(Double(100), Resultado.TotalLiquido, MARGEN);
end;

procedure TPruebasTotalesDocumentos.
  Nucleo_RectificativaConservaSigno;
var
  Configuracion: TConfiguracionMotorFiscalVenta;
  Lineas: TLineasMotorFiscalVenta;
  Resultado: TResultadoMotorFiscalVenta;
begin
  FillChar(Configuracion, SizeOf(Configuracion), 0);
  Configuracion.ClienteConDatosFiscales := True;
  SetLength(Lineas, 1);
  Lineas[0].TipoIva := 'N';
  Lineas[0].Base := -100;
  Lineas[0].TotalConIva := -121;
  Lineas[0].PorcentajeIva := 21;
  Lineas[0].Cantidad := -1;
  Resultado := CalcularTotalesMotorFiscalVenta(
    Lineas, Configuracion);
  Assert.IsTrue(Resultado.TieneImportesNegativos);
  Assert.AreEqual(Double(-100), Resultado.TotalBases, MARGEN);
  Assert.AreEqual(Double(-21), Resultado.TotalIva, MARGEN);
  Assert.AreEqual(Double(-121), Resultado.TotalLiquido, MARGEN);
end;

end.
