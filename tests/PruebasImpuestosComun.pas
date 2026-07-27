{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasImpuestosComun                                         }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas unitarias de las utilidades fiscales comunes extraídas durante    }
{    la refactorización de compras y ventas.                                   }
{******************************************************************************}
unit PruebasImpuestosComun;

interface

uses
  System.SysUtils, Data.DB, Datasnap.DBClient, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasImpuestosComun = class
  private
    FDataSet: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure CampoFloat_AdmiteAusenciaNuloYValor;
    [Test]
    procedure CampoString_AdmiteAusenciaNuloYValor;
    [Test]
    procedure Difiere_DetectaCambiosReales;
    [Test]
    procedure Poner_ActualizaSoloCuandoDifiere;
    [Test]
    procedure TipoIva_NormalizaValidaEIndexa;
    [Test]
    procedure PorcentajeCabecera_SeleccionaTipo;
    [Test]
    procedure ConversionIva_ConservaDecimalesYEvitaDivisionPorCero;
    [Test]
    procedure SufijoFiscal_ExtraeSoloElPrefijoEsperado;
    [Test]
    procedure LecturasConConexionNula_DevuelvenValoresNeutros;
  end;

implementation

uses
  inLibImpuestosComun;

const
  MARGEN: Double = 0.000001;

procedure TPruebasImpuestosComun.Preparar;
begin
  FDataSet := TClientDataSet.Create(nil);
  FDataSet.FieldDefs.Add('FLOAT_TEST', ftFloat);
  FDataSet.FieldDefs.Add('STRING_TEST', ftString, 50);
  FDataSet.FieldDefs.Add('PORCENTAJE_IVAN_DOC', ftFloat);
  FDataSet.FieldDefs.Add('PORCENTAJE_IVAR_DOC', ftFloat);
  FDataSet.FieldDefs.Add('PORCENTAJE_IVAS_DOC', ftFloat);
  FDataSet.FieldDefs.Add('PORCENTAJE_IVAE_DOC', ftFloat);
  FDataSet.CreateDataSet;
  FDataSet.Append;
end;

procedure TPruebasImpuestosComun.Limpiar;
begin
  FreeAndNil(FDataSet);
end;

procedure TPruebasImpuestosComun.CampoFloat_AdmiteAusenciaNuloYValor;
begin
  Assert.AreEqual(Double(0), CampoFloat(nil, 'FLOAT_TEST'), MARGEN);
  Assert.AreEqual(Double(0), CampoFloat(FDataSet, 'NO_EXISTE'), MARGEN);
  Assert.AreEqual(Double(0), CampoFloat(FDataSet, 'FLOAT_TEST'), MARGEN);
  FDataSet.FieldByName('FLOAT_TEST').AsFloat := 12.75;
  Assert.AreEqual(Double(12.75),
    CampoFloat(FDataSet, 'FLOAT_TEST'), MARGEN);
end;

procedure TPruebasImpuestosComun.CampoString_AdmiteAusenciaNuloYValor;
begin
  Assert.AreEqual('', CampoString(nil, 'STRING_TEST'));
  Assert.AreEqual('', CampoString(FDataSet, 'NO_EXISTE'));
  Assert.AreEqual('', CampoString(FDataSet, 'STRING_TEST'));
  FDataSet.FieldByName('STRING_TEST').AsString := 'Texto fiscal';
  Assert.AreEqual('Texto fiscal',
    CampoString(FDataSet, 'STRING_TEST'));
end;

procedure TPruebasImpuestosComun.Difiere_DetectaCambiosReales;
begin
  Assert.IsFalse(CampoFloatDifiere(nil, 'FLOAT_TEST', 1));
  Assert.IsFalse(CampoFloatDifiere(FDataSet, 'NO_EXISTE', 1));
  Assert.IsTrue(CampoFloatDifiere(FDataSet, 'FLOAT_TEST', 1));
  FDataSet.FieldByName('FLOAT_TEST').AsFloat := 5.5;
  Assert.IsFalse(CampoFloatDifiere(FDataSet, 'FLOAT_TEST', 5.5));
  Assert.IsTrue(CampoFloatDifiere(FDataSet, 'FLOAT_TEST', 5.6));
  Assert.IsFalse(CampoStringDifiere(nil, 'STRING_TEST', 'A'));
  Assert.IsFalse(CampoStringDifiere(FDataSet, 'NO_EXISTE', 'A'));
  Assert.IsTrue(CampoStringDifiere(FDataSet, 'STRING_TEST', 'A'));
  FDataSet.FieldByName('STRING_TEST').AsString := 'A';
  Assert.IsFalse(CampoStringDifiere(FDataSet, 'STRING_TEST', 'A'));
  Assert.IsTrue(CampoStringDifiere(FDataSet, 'STRING_TEST', 'B'));
end;

procedure TPruebasImpuestosComun.Poner_ActualizaSoloCuandoDifiere;
begin
  FDataSet.FieldByName('FLOAT_TEST').AsFloat := 10;
  FDataSet.FieldByName('STRING_TEST').AsString := 'Inicial';
  FDataSet.Post;
  PonerFloat(FDataSet, 'FLOAT_TEST', 10);
  Assert.AreEqual(Integer(dsBrowse), Integer(FDataSet.State));
  PonerFloat(FDataSet, 'FLOAT_TEST', 12.5);
  Assert.AreEqual(Integer(dsEdit), Integer(FDataSet.State));
  Assert.AreEqual(Double(12.5),
    FDataSet.FieldByName('FLOAT_TEST').AsFloat, MARGEN);
  FDataSet.Post;
  PonerString(FDataSet, 'STRING_TEST', 'Inicial');
  Assert.AreEqual(Integer(dsBrowse), Integer(FDataSet.State));
  PonerString(FDataSet, 'STRING_TEST', 'Modificado');
  Assert.AreEqual(Integer(dsEdit), Integer(FDataSet.State));
  Assert.AreEqual('Modificado',
    FDataSet.FieldByName('STRING_TEST').AsString);
  PonerFloat(nil, 'FLOAT_TEST', 1);
  PonerString(nil, 'STRING_TEST', 'A');
end;

procedure TPruebasImpuestosComun.TipoIva_NormalizaValidaEIndexa;
begin
  Assert.IsTrue(TipoIvaValido('N'));
  Assert.IsTrue(TipoIvaValido(' r '));
  Assert.IsTrue(TipoIvaValido('s'));
  Assert.IsTrue(TipoIvaValido('E'));
  Assert.IsFalse(TipoIvaValido('X'));
  Assert.IsFalse(TipoIvaValido(''));
  Assert.AreEqual('R', NormalizarTipoIva(' r '));
  Assert.AreEqual('N', NormalizarTipoIva('X'));
  Assert.AreEqual(0, IndiceTipoIva('N'));
  Assert.AreEqual(1, IndiceTipoIva('R'));
  Assert.AreEqual(2, IndiceTipoIva('S'));
  Assert.AreEqual(3, IndiceTipoIva('E'));
  Assert.AreEqual(0, IndiceTipoIva('X'));
end;

procedure TPruebasImpuestosComun.PorcentajeCabecera_SeleccionaTipo;
begin
  FDataSet.FieldByName('PORCENTAJE_IVAN_DOC').AsFloat := 21;
  FDataSet.FieldByName('PORCENTAJE_IVAR_DOC').AsFloat := 10;
  FDataSet.FieldByName('PORCENTAJE_IVAS_DOC').AsFloat := 4;
  FDataSet.FieldByName('PORCENTAJE_IVAE_DOC').AsFloat := 0;
  Assert.AreEqual(Double(21),
    PorcentajeIvaCabecera(FDataSet, 'DOC', 'N'), MARGEN);
  Assert.AreEqual(Double(10),
    PorcentajeIvaCabecera(FDataSet, 'DOC', 'R'), MARGEN);
  Assert.AreEqual(Double(4),
    PorcentajeIvaCabecera(FDataSet, 'DOC', 'S'), MARGEN);
  Assert.AreEqual(Double(0),
    PorcentajeIvaCabecera(FDataSet, 'DOC', 'E'), MARGEN);
  Assert.AreEqual(Double(21),
    PorcentajeIvaCabecera(FDataSet, 'DOC', 'X'), MARGEN);
  Assert.AreEqual(Double(0),
    PorcentajeIvaCabecera(nil, 'DOC', 'N'), MARGEN);
end;

procedure TPruebasImpuestosComun.
  ConversionIva_ConservaDecimalesYEvitaDivisionPorCero;
var
  rPrecioConIva: Double;
  rPrecioSinIva: Double;
begin
  rPrecioConIva := PrecioConIvaDesdeSinIva(100, 10.5);
  Assert.AreEqual(Double(110.5), rPrecioConIva, MARGEN);
  rPrecioSinIva := PrecioSinIvaDesdeConIva(rPrecioConIva, 10.5);
  Assert.AreEqual(Double(100), rPrecioSinIva, MARGEN);
  Assert.AreEqual(Double(100),
    PrecioSinIvaDesdeConIva(100, -100), MARGEN);
  Assert.AreEqual(Double(0),
    PrecioSinIvaDesdeConIva(0, 21), MARGEN);
end;

procedure TPruebasImpuestosComun.
  SufijoFiscal_ExtraeSoloElPrefijoEsperado;
begin
  Assert.AreEqual('LIN',
    SufijoLineaFiscalDesdeCampo('TIPO_IVA_ARTICULO_LIN'));
  Assert.AreEqual('',
    SufijoLineaFiscalDesdeCampo('TIPO_IVA_ARTICULO_'));
  Assert.AreEqual('',
    SufijoLineaFiscalDesdeCampo('TIPO_IVA_LIN'));
  Assert.AreEqual('',
    SufijoLineaFiscalDesdeCampo('tipo_iva_articulo_lin'));
end;

procedure TPruebasImpuestosComun.
  LecturasConConexionNula_DevuelvenValoresNeutros;
var
  rIvaN, rIvaR, rIvaS, rIvaE: Double;
  rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva: string;
begin
  rIvaN := 1;
  rIvaR := 1;
  rIvaS := 1;
  rIvaE := 1;
  rRecN := 1;
  rRecR := 1;
  rRecS := 1;
  rRecE := 1;
  Assert.IsFalse(LeerPorcentajesIvaPorCodigo(nil, '01', rIvaN,
    rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE));
  Assert.AreEqual(Double(0), rIvaN, MARGEN);
  Assert.AreEqual(Double(0), rIvaR, MARGEN);
  Assert.AreEqual(Double(0), rIvaS, MARGEN);
  Assert.AreEqual(Double(0), rIvaE, MARGEN);
  Assert.AreEqual(Double(0), rRecN, MARGEN);
  Assert.AreEqual(Double(0), rRecR, MARGEN);
  Assert.AreEqual(Double(0), rRecS, MARGEN);
  Assert.AreEqual(Double(0), rRecE, MARGEN);
  sCodigoIva := 'XX';
  Assert.IsFalse(LeerPorcentajesIvaPorEmpresa(nil, '01', sCodigoIva,
    rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE));
  Assert.AreEqual('', sCodigoIva);
  Assert.IsFalse(LeerPorcentajesIvaPorCodigo(nil, '', rIvaN, rIvaR,
    rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE));
  Assert.AreEqual('', ObtenerTipoIvaArticulo(nil, 'ART'));
  Assert.AreEqual('', ObtenerTipoIvaArticulo(nil, ''));
end;

end.
