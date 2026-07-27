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
    procedure AgregarCampoTexto(ADataSet: TClientDataSet;
      const ANombre: string; ATamano: Integer = 20);
    procedure AgregarCampoFloat(ADataSet: TClientDataSet;
      const ANombre: string);
    procedure AgregarCamposCabecera;
    procedure AgregarCamposLineas;
    procedure AgregarLinea(const ATipoIva: string; APorcentajeIva,
      ATotal, ACantidad: Double; ATieneTotalUnidades: Boolean = False;
      ATotalUnidades: Double = 0; const AIncluir: string = 'S');
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
    procedure PrendasVenta_IgnoraFiltroYLoRestaura;
    [Test]
    procedure PrendasCompra_PriorizaTotalUnidades;
    [Test]
    procedure PrendasVenta_NoInterfiereConUnaEdicion;
  end;

implementation

uses
  inLibComprasImpuestos, inLibVentasImpuestos;

const
  MARGEN: Double = 0.000001;
  CODIGOS_IVA: array[0..3] of string =
    ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE: array[0..3] of string =
    ('REN', 'RER', 'RES', 'REE');

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

procedure TPruebasTotalesDocumentos.AgregarCamposCabecera;
const
  CAMPOS_TEXTO: array[0..12] of string = (
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
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_DOC');
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

procedure TPruebasTotalesDocumentos.AgregarCamposLineas;
begin
  AgregarCampoTexto(FLineas, 'TIPO_IVA_ARTICULO_LIN');
  AgregarCampoFloat(FLineas, 'PORCENTAJE_IVA_LIN');
  AgregarCampoFloat(FLineas, 'TOTAL_LINEA_LIN');
  AgregarCampoTexto(FLineas, 'CODIGO_ART_LIN');
  AgregarCampoFloat(FLineas, 'CANTIDAD_LIN');
  AgregarCampoFloat(FLineas, 'TOTAL_UNIDADES_LIN');
  AgregarCampoTexto(FLineas, 'INCLUIR');
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
  AgregarCamposLineas;
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

end.
