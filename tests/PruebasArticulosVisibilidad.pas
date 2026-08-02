{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosVisibilidad                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las reglas de visibilidad de columnas de artículos.           }
{******************************************************************************}
unit PruebasArticulosVisibilidad;

interface

uses
  Data.DB, Datasnap.DBClient, DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosVisibilidad = class
  private
    FTarifas: TClientDataSet;
    FSkus: TClientDataSet;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure SinDatos_OcultaColumnas;
    [Test]
    procedure TarifaConSku_MuestraColumnaSku;
    [Test]
    procedure PrecioSku_MuestraColumnasCompra;
    [Test]
    procedure Evaluar_ConservaRegistrosActivos;
    [Test]
    procedure FiltroEstado_IdaYVueltaEntrePerfilYCombo;
    [Test]
    procedure FiltroEstado_ValorDesconocidoCaeEnSoloActivos;
    [Test]
    procedure CsvSeleccion_UneConPuntoYComa;
    [Test]
    procedure CodigosBarras_ClasificaValidosInvalidosYPendientes;
    [Test]
    procedure CodigosBarras_SinFilasNoInformaIncidencias;
    [Test]
    procedure SkusAltaTarifa_AgrupaPorColorYMuestraTallas;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosVisibilidad,
  inLibArticulosFiltro,
  inLibArticulosAltaTarifas,
  inLibEAN13,
  inLibArticulosPresentacionIntf,
  inLibArticulosPresentacion;

function CodigoEan13Valido(const APrefijo12: string): string;
begin
  Result := APrefijo12 + CalcularDigitoEAN13(APrefijo12);
end;

function CodigoEan8Valido(const APrefijo7: string): string;
begin
  Result := APrefijo7 + CalcularDigitoEAN8(APrefijo7);
end;

function FilaCodigoBarras(const ACodigo, ASku,
  ATipo: string): TCodigoBarrasSkuArticulo;
begin
  Result.Codigo := ACodigo;
  Result.Sku := ASku;
  Result.Tipo := ATipo;
end;

function DetalleSkuTarifa(const AColor, AHex,
  ATalla: string): TDetalleSkuTarifaArticulo;
begin
  Result.Color := AColor;
  Result.HexColor := AHex;
  Result.Talla := ATalla;
end;

procedure TPruebasArticulosVisibilidad.Preparar;
begin
  FTarifas := TClientDataSet.Create(nil);
  FTarifas.FieldDefs.Add('CODIGO_UNIDAD_ARTTAR', ftString, 40);
  FTarifas.CreateDataSet;
  FSkus := TClientDataSet.Create(nil);
  FSkus.FieldDefs.Add('PRECIO_ULT_COMPRA_SKUC', ftFloat);
  FSkus.CreateDataSet;
end;

procedure TPruebasArticulosVisibilidad.Limpiar;
begin
  FreeAndNil(FSkus);
  FreeAndNil(FTarifas);
end;

procedure TPruebasArticulosVisibilidad.SinDatos_OcultaColumnas;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsFalse(Visibilidad.MostrarSkuTarifa);
  Assert.IsFalse(Visibilidad.MostrarCompraSku);
end;

procedure TPruebasArticulosVisibilidad.TarifaConSku_MuestraColumnaSku;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  FTarifas.AppendRecord(['']);
  FTarifas.AppendRecord(['ART-1/ROJO/L']);
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsTrue(Visibilidad.MostrarSkuTarifa);
  Assert.IsFalse(Visibilidad.MostrarCompraSku);
end;

procedure TPruebasArticulosVisibilidad.PrecioSku_MuestraColumnasCompra;
var
  Visibilidad: TVisibilidadColumnasArticulo;
begin
  FSkus.AppendRecord([0]);
  FSkus.AppendRecord([12.5]);
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsFalse(Visibilidad.MostrarSkuTarifa);
  Assert.IsTrue(Visibilidad.MostrarCompraSku);
end;

procedure TPruebasArticulosVisibilidad.Evaluar_ConservaRegistrosActivos;
var
  Visibilidad: TVisibilidadColumnasArticulo;
  iTarifaActiva: Integer;
  iSkuActivo: Integer;
begin
  FTarifas.AppendRecord(['ART-1/ROJO/L']);
  FTarifas.AppendRecord(['ART-1/AZUL/M']);
  FTarifas.First;
  FSkus.AppendRecord([10]);
  FSkus.AppendRecord([20]);
  FSkus.First;
  iTarifaActiva := FTarifas.RecNo;
  iSkuActivo := FSkus.RecNo;
  Visibilidad := EvaluarVisibilidadColumnasArticulo(FTarifas, FSkus);
  Assert.IsTrue(Visibilidad.MostrarSkuTarifa);
  Assert.IsTrue(Visibilidad.MostrarCompraSku);
  Assert.AreEqual(iTarifaActiva, FTarifas.RecNo);
  Assert.AreEqual(iSkuActivo, FSkus.RecNo);
end;

procedure TPruebasArticulosVisibilidad.
  FiltroEstado_IdaYVueltaEntrePerfilYCombo;
var
  iIndice: Integer;
begin
  // T=Todos, S=Solo activos, N=Solo inactivos. El indice del combo es la
  // unica traduccion entre el perfil guardado y el WHERE del listado.
  iIndice := IndiceEstadoFiltroDesdeCodigo('T');
  Assert.AreEqual(0, iIndice);
  Assert.AreEqual('T', CodigoEstadoFiltroDesdeIndice(iIndice));
  Assert.AreEqual(Ord(efaTodos),
    Ord(EstadoFiltroArticulosDesdeIndice(iIndice)));
  iIndice := IndiceEstadoFiltroDesdeCodigo('S');
  Assert.AreEqual(1, iIndice);
  Assert.AreEqual('S', CodigoEstadoFiltroDesdeIndice(iIndice));
  Assert.AreEqual(Ord(efaActivos),
    Ord(EstadoFiltroArticulosDesdeIndice(iIndice)));
  iIndice := IndiceEstadoFiltroDesdeCodigo('N');
  Assert.AreEqual(2, iIndice);
  Assert.AreEqual('N', CodigoEstadoFiltroDesdeIndice(iIndice));
  Assert.AreEqual(Ord(efaInactivos),
    Ord(EstadoFiltroArticulosDesdeIndice(iIndice)));
end;

procedure TPruebasArticulosVisibilidad.
  FiltroEstado_ValorDesconocidoCaeEnSoloActivos;
begin
  Assert.AreEqual(1, IndiceEstadoFiltroDesdeCodigo(''));
  Assert.AreEqual(1, IndiceEstadoFiltroDesdeCodigo('Z'));
  Assert.AreEqual('S', CodigoEstadoFiltroDesdeIndice(7));
  Assert.AreEqual(Ord(efaTodos),
    Ord(EstadoFiltroArticulosDesdeIndice(7)));
end;

procedure TPruebasArticulosVisibilidad.CsvSeleccion_UneConPuntoYComa;
var
  oValores: TArray<string>;
begin
  SetLength(oValores, 0);
  Assert.AreEqual('', ComponerCsvSeleccion(oValores));
  oValores := TArray<string>.Create('INVIERNO');
  Assert.AreEqual('INVIERNO', ComponerCsvSeleccion(oValores));
  oValores := TArray<string>.Create('INVIERNO', 'VERANO');
  Assert.AreEqual('INVIERNO;VERANO', ComponerCsvSeleccion(oValores));
end;

procedure TPruebasArticulosVisibilidad.
  CodigosBarras_ClasificaValidosInvalidosYPendientes;
var
  oResumen: TResumenCodigosBarrasArticulo;
  oCodigos: TCodigosBarrasArticulo;
begin
  SetLength(oCodigos, 5);
  oCodigos[0] :=
    FilaCodigoBarras(CodigoEan13Valido('840000000001'), 'SKU1', 'EAN13');
  oCodigos[1] :=
    FilaCodigoBarras(CodigoEan8Valido('8400001'), 'SKU2', 'EAN8');
  oCodigos[2] := FilaCodigoBarras('', 'SKU3', 'FAB');
  oCodigos[3] := FilaCodigoBarras('_FAB_SKU4', 'SKU4', 'FAB');
  oCodigos[4] := FilaCodigoBarras('1234567890123', 'SKU5', 'EAN13');
  oResumen := VerificarCodigosBarrasArticulo(oCodigos);
  Assert.AreEqual(1, oResumen.Ean13Correctos);
  Assert.AreEqual(1, oResumen.Ean8Correctos);
  Assert.AreEqual(2, oResumen.Omitidos);
  Assert.AreEqual(1, oResumen.Invalidos);
  Assert.IsTrue(Pos('SKU5', oResumen.DetalleErrores) > 0);
  Assert.IsTrue(Pos('SKU1', oResumen.DetalleErrores) = 0);
end;

procedure TPruebasArticulosVisibilidad.
  CodigosBarras_SinFilasNoInformaIncidencias;
var
  oResumen: TResumenCodigosBarrasArticulo;
  oCodigos: TCodigosBarrasArticulo;
begin
  SetLength(oCodigos, 0);
  oResumen := VerificarCodigosBarrasArticulo(oCodigos);
  Assert.AreEqual(0, oResumen.Ean13Correctos);
  Assert.AreEqual(0, oResumen.Ean8Correctos);
  Assert.AreEqual(0, oResumen.Omitidos);
  Assert.AreEqual(0, oResumen.Invalidos);
  Assert.AreEqual('', oResumen.DetalleErrores);
end;

procedure TPruebasArticulosVisibilidad.
  SkusAltaTarifa_AgrupaPorColorYMuestraTallas;
var
  oDetalles: TDetallesSkuTarifaArticulo;
  oLista: TOpcionesSkuTarifaArticulo;
begin
  oDetalles := TDetallesSkuTarifaArticulo.Create(
    DetalleSkuTarifa('AMARILLO', '#FFFF00', '39'),
    DetalleSkuTarifa('AMARILLO', '#FFFF00', '40'),
    DetalleSkuTarifa('AMARILLO', '#FFFF00', '39'),
    DetalleSkuTarifa('ROJO', '#FF0000', '42'));
  oLista := ComponerListaSkusAltaTarifa('ART-1', oDetalles);
  Assert.AreEqual(3, Integer(Length(oLista)));
  Assert.AreEqual(cSkuFilaArticulo, oLista[0].CodigoSku);
  Assert.AreEqual('ART-1/AMARILLO', oLista[1].CodigoSku);
  Assert.AreEqual('#FFFF00', oLista[1].HexColor);
  Assert.AreEqual('39, 40', oLista[1].Tallas);
  Assert.AreEqual('ART-1/ROJO', oLista[2].CodigoSku);
  Assert.AreEqual('42', oLista[2].Tallas);
  SetLength(oDetalles, 0);
  oLista := ComponerListaSkusAltaTarifa('ART-1', oDetalles);
  Assert.AreEqual(1, Integer(Length(oLista)));
  Assert.AreEqual(cSkuFilaArticulo, oLista[0].CodigoSku);
end;

end.
