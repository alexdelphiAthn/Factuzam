{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasModoTallas                                             }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracterización del modo de entrada de tallas: composición de SKU,        }
{    atributos y conjunto pivote, clave de consolidación, invariante de        }
{    unidades, rederivación y des-pivote. Sin BBDD, sin controles.             }
{******************************************************************************}
unit PruebasModoTallas;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasModoTallasModelo = class
  public
    [Test]
    procedure Sku_InsertaLaTallaEnSuPosicionReal;
    [Test]
    procedure Sku_SinTallaConservaSoloLosAtributosConValor;
    [Test]
    procedure Partes_DevuelveVacioCuandoElSkuNoEsDelArticulo;
    [Test]
    procedure Partes_TroceaElSkuCerrado;
    [Test]
    procedure Atributo_DetectaTallaPorNombreYPorIdentificador;
    [Test]
    procedure Atributos_TomanElValorDelSkuLeido;
    [Test]
    procedure Atributos_FijanElUnicoValorPosible;
    [Test]
    procedure Atributos_PidenValorAlSelectorSoloSiNoEsSilencioso;
    [Test]
    procedure Pivote_ConservaElConjuntoAsignadoQueCubreLasTallas;
    [Test]
    procedure Pivote_CaeAlConjuntoAlternativoSiElAsignadoNoCubre;
    [Test]
    procedure Pivote_ConservaElAsignadoSiNingunoCubre;
    [Test]
    procedure Pivote_BuscaConjuntoCuandoElArticuloNoTieneAsignado;
    [Test]
    procedure Clave_ExcluyeElAlmacenEnFormatoDistribuido;
    [Test]
    procedure Clave_IncluyeElAlmacenSinFormatoDistribuido;
    [Test]
    procedure Clave_SeparaPreciosDistintos;
    [Test]
    procedure Unidades_SumanCeldasYLineasSinCeldas;
    [Test]
    procedure Unidades_NoCuentanLaCantidadDeUnaLineaPivotada;
    [Test]
    procedure Invariante_AceptaDiferenciasPorDebajoDeLaTolerancia;
    [Test]
    procedure Invariante_RompeCuandoLasUnidadesNoCuadran;
    [Test]
    procedure IdAv_ResuelveLaTallaPorSuValor;
  end;
  [TestFixture]
  TPruebasModoTallasConversion = class
  public
    [Test]
    procedure Rederivar_FusionaDuplicadasYVuelcaLaCantidadALaCelda;
    [Test]
    procedure Rederivar_ConservaLasUnidadesDelDocumento;
    [Test]
    procedure Rederivar_NoFusionaLineasConPrecioDistinto;
    [Test]
    procedure Rederivar_FusionaPorAlmacenEnFormatoDistribuido;
    [Test]
    procedure Rederivar_MueveLasCeldasDeUnaDuplicadaYaConvertida;
    [Test]
    procedure Rederivar_NoVuelveAVolcarLaCantidadDeUnaLineaConCeldas;
    [Test]
    procedure Desmontar_ExpandeCadaCeldaAUnaLineaPorSku;
    [Test]
    procedure Desmontar_ConservaLasUnidadesDelDocumento;
    [Test]
    procedure Desmontar_SinCeldasNoTocaLasLineas;
    [Test]
    procedure Desmontar_ConfirmaUnaSolaVezYNotificaLosPosts;
    [Test]
    procedure Desmontar_RevierteCuandoLaConversionPierdeUnidades;
    [Test]
    procedure Desmontar_RespetaUnaTransaccionYaActiva;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosAtributosIntf, inLibModoTallasIntf,
  inLibModoTallasModelo, inLibModoTallasConversion,
  DoblesModoTallas;

const
  ORDEN_COLOR = 1;
  ORDEN_TALLA = 2;

function ValoresDe(const AColor: string): TValoresAttrTallas;
var
  i: Integer;
begin
  for i := 1 to 5 do
    Result[i] := '';
  Result[1] := AColor;
end;

// Articulo con COLOR (orden 1) y TALLA (orden 2). El conjunto asignado
// al atributo talla es AConjuntoAsignado.
function LookupColorTalla(
  AConjuntoAsignado: Integer): TLookupAtributosMemoria;
begin
  Result := TLookupAtributosMemoria.Create;
  Result.DefinirAtributos('ART1', [
    Atributo('COL', 'Color', 0),
    Atributo('TAL', 'Talla', AConjuntoAsignado)]);
  Result.DefinirValores('ART1', ORDEN_COLOR,
    [ValorAtributo(11, 'ROJO'), ValorAtributo(12, 'AZUL')]);
  Result.DefinirValores('ART1', ORDEN_TALLA,
    [ValorAtributo(21, '38'), ValorAtributo(22, '40')]);
end;

procedure TPruebasModoTallasModelo.
  Sku_InsertaLaTallaEnSuPosicionReal;
var
  Valores: TValoresAttrTallas;
begin
  // La talla ocupa la posicion 1 (0-based): ART/COLOR/TALLA con la
  // talla insertada donde le toca, no al final.
  Valores := ValoresDe('ROJO');
  Assert.AreEqual('ART1/ROJO/38',
    TModeloTallas.ComponerSkuLinea('ART1', Valores, 1, '38'));
end;

procedure TPruebasModoTallasModelo.
  Sku_SinTallaConservaSoloLosAtributosConValor;
var
  Valores: TValoresAttrTallas;
begin
  Valores := ValoresDe('ROJO');
  Assert.AreEqual('ART1/ROJO',
    TModeloTallas.ComponerSkuLinea('ART1', Valores, -1, ''));
end;

procedure TPruebasModoTallasModelo.
  Partes_DevuelveVacioCuandoElSkuNoEsDelArticulo;
begin
  Assert.AreEqual(0,
    Integer(Length(
      TModeloTallas.PartesDeSku('ART1', 'ART2/ROJO/38'))));
  Assert.AreEqual(0,
    Integer(Length(
      TModeloTallas.PartesDeSku('ART1', 'ART1'))));
end;

procedure TPruebasModoTallasModelo.Partes_TroceaElSkuCerrado;
var
  Partes: TArray<string>;
begin
  Partes := TModeloTallas.PartesDeSku('ART1', 'ART1/ROJO/38');
  Assert.AreEqual(2, Integer(Length(Partes)));
  Assert.AreEqual('ROJO', Partes[0]);
  Assert.AreEqual('38', Partes[1]);
  Assert.AreEqual('38', TModeloTallas.ValorTallaDePartes(Partes, 1));
  Assert.AreEqual('', TModeloTallas.ValorTallaDePartes(Partes, -1));
end;

procedure TPruebasModoTallasModelo.
  Atributo_DetectaTallaPorNombreYPorIdentificador;
begin
  Assert.IsTrue(TModeloTallas.EsAtributoTalla(
    Atributo('XX', 'Talla europea', 0)));
  Assert.IsTrue(TModeloTallas.EsAtributoTalla(
    Atributo('TAL01', '', 0)));
  Assert.IsFalse(TModeloTallas.EsAtributoTalla(
    Atributo('COL', 'Color', 0)));
end;

procedure TPruebasModoTallasModelo.Atributos_TomanElValorDelSkuLeido;
var
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
  Atributos: TAtributosLineaTallas;
begin
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntosQueCubren.Add(7);
  Modelo := TModeloTallas.Create(LookupColorTalla(7), Persistencia,
                                 nil, nil);
  try
    Atributos := Modelo.CalcularAtributosLinea('ART1',
      TModeloTallas.PartesDeSku('ART1', 'ART1/AZUL/40'), True);
    Assert.AreEqual('AZUL', Atributos.Valores[1]);
    Assert.AreEqual('Color', Atributos.Nombres[1]);
    Assert.AreEqual(1, Atributos.OrdenTalla);
    Assert.AreEqual(7, Atributos.ConjuntoTalla);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.Atributos_FijanElUnicoValorPosible;
var
  Lookup: TLookupAtributosMemoria;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
  Atributos: TAtributosLineaTallas;
begin
  Lookup := LookupColorTalla(7);
  Lookup.DefinirValores('ART1', ORDEN_COLOR,
    [ValorAtributo(11, 'ROJO')]);
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntosQueCubren.Add(7);
  Modelo := TModeloTallas.Create(Lookup, Persistencia, nil, nil);
  try
    Atributos := Modelo.CalcularAtributosLinea('ART1', nil, True);
    Assert.AreEqual('ROJO', Atributos.Valores[1]);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.
  Atributos_PidenValorAlSelectorSoloSiNoEsSilencioso;
var
  Persistencia: TPersistenciaTallasMemoria;
  Selector: TSelectorAvFijo;
  Modelo: TModeloTallas;
  Atributos: TAtributosLineaTallas;
begin
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntosQueCubren.Add(7);
  Selector := TSelectorAvFijo.Create('AZUL', True);
  Modelo := TModeloTallas.Create(LookupColorTalla(7), Persistencia,
                                 Selector, nil);
  try
    // Silencioso (conversion masiva): sin paleta y sin valor.
    Atributos := Modelo.CalcularAtributosLinea('ART1', nil, True);
    Assert.AreEqual('', Atributos.Valores[1]);
    Assert.AreEqual(0, Selector.Llamadas);
    // Con interaccion: la paleta decide el color.
    Atributos := Modelo.CalcularAtributosLinea('ART1', nil, False);
    Assert.AreEqual('AZUL', Atributos.Valores[1]);
    Assert.AreEqual(1, Selector.Llamadas);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.
  Pivote_ConservaElConjuntoAsignadoQueCubreLasTallas;
var
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntosQueCubren.Add(7);
  Persistencia.ConjuntoPorAvs := 99;
  Modelo := TModeloTallas.Create(LookupColorTalla(7), Persistencia,
                                 nil, nil);
  try
    Assert.AreEqual(7,
      Modelo.ResolverConjuntoPivote('ART1', 7, ORDEN_TALLA));
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.
  Pivote_CaeAlConjuntoAlternativoSiElAsignadoNoCubre;
var
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  // Conjunto de LETRAS asignado a un articulo con tallas NUMERICAS: sin
  // el fallback las celdas quedarian invisibles.
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntoPorAvs := 99;
  Modelo := TModeloTallas.Create(LookupColorTalla(7), Persistencia,
                                 nil, nil);
  try
    Assert.AreEqual(99,
      Modelo.ResolverConjuntoPivote('ART1', 7, ORDEN_TALLA));
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.
  Pivote_ConservaElAsignadoSiNingunoCubre;
var
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntoPorAvs := 0;
  Modelo := TModeloTallas.Create(LookupColorTalla(7), Persistencia,
                                 nil, nil);
  try
    // Mejor un pivote parcial que perderlo.
    Assert.AreEqual(7,
      Modelo.ResolverConjuntoPivote('ART1', 7, ORDEN_TALLA));
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.
  Pivote_BuscaConjuntoCuandoElArticuloNoTieneAsignado;
var
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.ConjuntoPorAvs := 42;
  Modelo := TModeloTallas.Create(LookupColorTalla(0), Persistencia,
                                 nil, nil);
  try
    Assert.AreEqual(42,
      Modelo.ResolverConjuntoPivote('ART1', 0, ORDEN_TALLA));
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasModelo.
  Clave_ExcluyeElAlmacenEnFormatoDistribuido;
var
  Valores: TValoresAttrTallas;
begin
  Valores := ValoresDe('ROJO');
  Assert.AreEqual(
    TModeloTallas.ClaveConsolidacion(True, 'ART1', 'ALM1', Valores,
                                     False, 0),
    TModeloTallas.ClaveConsolidacion(True, 'ART1', 'ALM2', Valores,
                                     False, 0));
end;

procedure TPruebasModoTallasModelo.
  Clave_IncluyeElAlmacenSinFormatoDistribuido;
var
  Valores: TValoresAttrTallas;
begin
  Valores := ValoresDe('ROJO');
  Assert.AreNotEqual(
    TModeloTallas.ClaveConsolidacion(False, 'ART1', 'ALM1', Valores,
                                     False, 0),
    TModeloTallas.ClaveConsolidacion(False, 'ART1', 'ALM2', Valores,
                                     False, 0));
end;

procedure TPruebasModoTallasModelo.Clave_SeparaPreciosDistintos;
var
  Valores: TValoresAttrTallas;
begin
  Valores := ValoresDe('ROJO');
  Assert.AreNotEqual(
    TModeloTallas.ClaveConsolidacion(False, 'ART1', 'ALM1', Valores,
                                     True, 10.5),
    TModeloTallas.ClaveConsolidacion(False, 'ART1', 'ALM1', Valores,
                                     True, 11.5));
end;

procedure TPruebasModoTallasModelo.
  Unidades_SumanCeldasYLineasSinCeldas;
var
  Totales: TArray<TTotalLineaTallas>;
  Cantidades: TArray<TCantidadLineaTallas>;
begin
  SetLength(Totales, 1);
  Totales[0].Linea := 1;
  Totales[0].Total := 5;
  SetLength(Cantidades, 2);
  Cantidades[0].Linea := 1;
  Cantidades[0].Cantidad := 99;
  Cantidades[1].Linea := 2;
  Cantidades[1].Cantidad := 4;
  Assert.AreEqual(9.0,
    TModeloTallas.UnidadesDocumento(Totales, Cantidades), 0.0001);
end;

procedure TPruebasModoTallasModelo.
  Unidades_NoCuentanLaCantidadDeUnaLineaPivotada;
var
  Totales: TArray<TTotalLineaTallas>;
  Cantidades: TArray<TCantidadLineaTallas>;
begin
  // La CANTIDAD de una linea con celdas es un total derivado: contarla
  // duplicaria las unidades del documento.
  SetLength(Totales, 1);
  Totales[0].Linea := 1;
  Totales[0].Total := 5;
  SetLength(Cantidades, 1);
  Cantidades[0].Linea := 1;
  Cantidades[0].Cantidad := 5;
  Assert.AreEqual(5.0,
    TModeloTallas.UnidadesDocumento(Totales, Cantidades), 0.0001);
end;

procedure TPruebasModoTallasModelo.
  Invariante_AceptaDiferenciasPorDebajoDeLaTolerancia;
var
  bPaso: Boolean;
begin
  TModeloTallas.ComprobarInvarianteUnidades('Prueba', 10, 10.0005,
                                            nil);
  bPaso := True;
  Assert.IsTrue(bPaso);
end;

procedure TPruebasModoTallasModelo.
  Invariante_RompeCuandoLasUnidadesNoCuadran;
var
  bLanzoExcepcion: Boolean;
begin
  bLanzoExcepcion := False;
  try
    TModeloTallas.ComprobarInvarianteUnidades('Construir', 10, 12,
                                              nil);
  except
    bLanzoExcepcion := True;
  end;
  Assert.IsTrue(bLanzoExcepcion);
end;

procedure TPruebasModoTallasModelo.IdAv_ResuelveLaTallaPorSuValor;
var
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Persistencia := TPersistenciaTallasMemoria.Create;
  Modelo := TModeloTallas.Create(LookupColorTalla(7), Persistencia,
                                 nil, nil);
  try
    Assert.AreEqual(22, Modelo.IdAvDeTalla('ART1', 1, '40'));
    Assert.AreEqual(0, Modelo.IdAvDeTalla('ART1', 1, '99'));
    Assert.AreEqual(0, Modelo.IdAvDeTalla('ART1', -1, '40'));
  finally
    FreeAndNil(Modelo);
  end;
end;

function LineaHeredada(ANumero: Integer;
  const AArticulo, ASku, AAlmacen: string;
  ACantidad, APrecio: Double; ATienePrecio: Boolean): TLineaMemoria;
begin
  Result := Default(TLineaMemoria);
  Result.Numero := ANumero;
  Result.Articulo := AArticulo;
  Result.Sku := ASku;
  Result.Almacen := AAlmacen;
  Result.Cantidad := ACantidad;
  Result.Precio := APrecio;
  Result.TienePrecio := ATienePrecio;
  Result.TieneAlmacen := AAlmacen <> '';
  Result.TieneCantidad := True;
end;

function ModeloDePrueba(
  APersistencia: TPersistenciaTallasMemoria): TModeloTallas;
begin
  APersistencia.ConjuntosQueCubren.Add(7);
  Result := TModeloTallas.Create(LookupColorTalla(7), APersistencia,
                                 nil, nil);
end;

procedure EjecutarRederivacion(
  const ALineas: ILineasRederivacionTallas;
  const APersistencia: IPersistenciaRederivacionTallas;
  AModelo: TModeloTallas; ADistribuido: Boolean;
  const AAlmacenDefecto: string);
var
  Rederivacion: TRederivacionTallas;
begin
  Rederivacion := TRederivacionTallas.Create(ALineas, APersistencia,
    AModelo, ADistribuido, AAlmacenDefecto, nil, nil);
  try
    Rederivacion.Ejecutar;
  finally
    FreeAndNil(Rederivacion);
  end;
end;

procedure EjecutarDesmontaje(const ALineas: ILineasDesmontajeTallas;
  const APersistencia: IPersistenciaDesmontajeTallas;
  AModelo: TModeloTallas);
var
  Desmontaje: TDesmontajeTallas;
begin
  Desmontaje := TDesmontajeTallas.Create(ALineas, APersistencia,
                                         AModelo, nil);
  try
    Desmontaje.Ejecutar;
  finally
    FreeAndNil(Desmontaje);
  end;
end;

procedure TPruebasModoTallasConversion.
  Rederivar_FusionaDuplicadasYVuelcaLaCantidadALaCelda;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasRederivacionTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO/38', 'ALM1',
                                    2, 0, False));
  Lineas.AnyadirLinea(LineaHeredada(2, 'ART1', 'ART1/ROJO/40', 'ALM1',
                                    3, 0, False));
  Persistencia := TPersistenciaTallasMemoria.Create;
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarRederivacion(RefLineas, Persistencia, Modelo, False,
                         'ALM1');
    // Una sola linea maestra por articulo+color y las dos cantidades en
    // sus celdas de talla.
    Assert.AreEqual(1, Lineas.Contar);
    Assert.AreEqual(1, Lineas.LineaEn(0).Numero);
    Assert.AreEqual(0.0, Lineas.LineaEn(0).Cantidad, 0.0001);
    Assert.AreEqual(2, Persistencia.ContarCeldas);
    Assert.AreEqual(5.0, Persistencia.TotalCeldas, 0.0001);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Rederivar_ConservaLasUnidadesDelDocumento;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasRederivacionTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
  rAntes, rDespues: Double;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO/38', 'ALM1',
                                    2, 0, False));
  Lineas.AnyadirLinea(LineaHeredada(2, 'ART1', 'ART1/ROJO/40', 'ALM1',
                                    3, 0, False));
  Lineas.AnyadirLinea(LineaHeredada(3, 'ART1', 'ART1/AZUL/38', 'ALM1',
                                    4, 0, False));
  Persistencia := TPersistenciaTallasMemoria.Create;
  Modelo := ModeloDePrueba(Persistencia);
  try
    rAntes := TModeloTallas.UnidadesDocumento(
      Persistencia.ConsultarTotalesPorLinea,
      Lineas.CantidadesPorLinea);
    EjecutarRederivacion(RefLineas, Persistencia, Modelo, False,
                         'ALM1');
    rDespues := TModeloTallas.UnidadesDocumento(
      Persistencia.ConsultarTotalesPorLinea,
      Lineas.CantidadesPorLinea);
    Assert.AreEqual(9.0, rAntes, 0.0001);
    Assert.AreEqual(rAntes, rDespues, 0.0001);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Rederivar_NoFusionaLineasConPrecioDistinto;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasRederivacionTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO/38', 'ALM1',
                                    2, 10, True));
  Lineas.AnyadirLinea(LineaHeredada(2, 'ART1', 'ART1/ROJO/40', 'ALM1',
                                    3, 12, True));
  Persistencia := TPersistenciaTallasMemoria.Create;
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarRederivacion(RefLineas, Persistencia, Modelo, False,
                         'ALM1');
    // Una fila pivotada por precio: el des-pivote conserva el precio de
    // cada una y un precio no machaca al otro.
    Assert.AreEqual(2, Lineas.Contar);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Rederivar_FusionaPorAlmacenEnFormatoDistribuido;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasRederivacionTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO/38', 'ALM1',
                                    2, 0, False));
  Lineas.AnyadirLinea(LineaHeredada(2, 'ART1', 'ART1/ROJO/38', 'ALM2',
                                    5, 0, False));
  Persistencia := TPersistenciaTallasMemoria.Create;
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarRederivacion(RefLineas, Persistencia, Modelo, True,
                         'ALM1');
    // En distribuido la linea es unica por articulo+color; el reparto
    // por almacen vive en las celdas.
    Assert.AreEqual(1, Lineas.Contar);
    Assert.AreEqual(2, Persistencia.ContarCeldas);
    Assert.AreEqual('ALM1', Persistencia.CeldaEn(0).Almacen);
    Assert.AreEqual('ALM2', Persistencia.CeldaEn(1).Almacen);
    Assert.AreEqual(7.0, Persistencia.TotalCeldas, 0.0001);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Rederivar_MueveLasCeldasDeUnaDuplicadaYaConvertida;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasRederivacionTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO/38', 'ALM1',
                                    0, 0, False));
  Lineas.AnyadirLinea(LineaHeredada(2, 'ART1', 'ART1/ROJO/40', 'ALM1',
                                    6, 0, False));
  Persistencia := TPersistenciaTallasMemoria.Create;
  // La duplicada YA tiene celdas: se mueven SUS celdas, no su cantidad
  // (que es el total derivado y sumarla duplicaria).
  Persistencia.AnyadirCelda(2, 22, '40', '', 6);
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarRederivacion(RefLineas, Persistencia, Modelo, False,
                         'ALM1');
    Assert.AreEqual(1, Lineas.Contar);
    Assert.AreEqual(1, Persistencia.ContarCeldas);
    Assert.AreEqual(1, Persistencia.CeldaEn(0).Linea);
    Assert.AreEqual(6.0, Persistencia.TotalCeldas, 0.0001);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Rederivar_NoVuelveAVolcarLaCantidadDeUnaLineaConCeldas;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasRederivacionTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  // Reentrada al modo: la maestra ya esta convertida y su CANTIDAD es
  // el total mantenido por el refresco de totales.
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO/38', 'ALM1',
                                    4, 0, False));
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.AnyadirCelda(1, 21, '38', '', 4);
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarRederivacion(RefLineas, Persistencia, Modelo, False,
                         'ALM1');
    Assert.AreEqual(4.0, Persistencia.TotalCeldas, 0.0001);
    Assert.AreEqual(4.0, Lineas.LineaEn(0).Cantidad, 0.0001);
  finally
    FreeAndNil(Modelo);
  end;
end;

// Documento pivotado: una linea de ART1/ROJO con dos celdas de talla.
function LineaPivotada: TLineaMemoria;
begin
  Result := LineaHeredada(1, 'ART1', 'ART1/ROJO', 'ALM1', 0, 10, True);
  Result.Valores := ValoresDe('ROJO');
  Result.Nombres := ValoresDe('Color');
  Result.ConjuntoTalla := 7;
end;

procedure TPruebasModoTallasConversion.
  Desmontar_ExpandeCadaCeldaAUnaLineaPorSku;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasDesmontajeTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaPivotada);
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.AnyadirCelda(1, 21, '38', '', 2);
  Persistencia.AnyadirCelda(1, 22, '40', '', 3);
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarDesmontaje(RefLineas, Persistencia, Modelo);
    Assert.AreEqual(2, Lineas.Contar);
    Assert.AreEqual('ART1/ROJO/38', Lineas.LineaEn(0).Sku);
    Assert.AreEqual(2.0, Lineas.LineaEn(0).Cantidad, 0.0001);
    Assert.AreEqual('ART1/ROJO/40', Lineas.LineaEn(1).Sku);
    Assert.AreEqual(3.0, Lineas.LineaEn(1).Cantidad, 0.0001);
    // El precio de la linea de origen viaja a la linea creada.
    Assert.AreEqual(10.0, Lineas.LineaEn(1).Precio, 0.0001);
    Assert.IsTrue(Persistencia.BorradoDocumento);
    Assert.AreEqual(0, Persistencia.ContarCeldas);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Desmontar_ConservaLasUnidadesDelDocumento;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasDesmontajeTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
  rAntes, rDespues: Double;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaPivotada);
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.AnyadirCelda(1, 21, '38', '', 2);
  Persistencia.AnyadirCelda(1, 22, '40', '', 3);
  Modelo := ModeloDePrueba(Persistencia);
  try
    rAntes := TModeloTallas.UnidadesDocumento(
      Persistencia.ConsultarTotalesPorLinea,
      Lineas.CantidadesPorLinea);
    EjecutarDesmontaje(RefLineas, Persistencia, Modelo);
    rDespues := TModeloTallas.UnidadesDocumento(
      Persistencia.ConsultarTotalesPorLinea,
      Lineas.CantidadesPorLinea);
    Assert.AreEqual(5.0, rAntes, 0.0001);
    Assert.AreEqual(rAntes, rDespues, 0.0001);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Desmontar_SinCeldasNoTocaLasLineas;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasDesmontajeTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaHeredada(1, 'ART1', 'ART1/ROJO', 'ALM1',
                                    7, 0, False));
  Persistencia := TPersistenciaTallasMemoria.Create;
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarDesmontaje(RefLineas, Persistencia, Modelo);
    Assert.AreEqual(1, Lineas.Contar);
    Assert.AreEqual(0, Lineas.Creadas);
    Assert.AreEqual(0, Lineas.Actualizadas);
    Assert.IsFalse(Persistencia.BorradoDocumento);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Desmontar_ConfirmaUnaSolaVezYNotificaLosPosts;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasDesmontajeTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaPivotada);
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.AnyadirCelda(1, 21, '38', '', 2);
  Persistencia.AnyadirCelda(1, 22, '40', '', 3);
  Modelo := ModeloDePrueba(Persistencia);
  try
    EjecutarDesmontaje(RefLineas, Persistencia, Modelo);
    Assert.AreEqual(1, Persistencia.Inicios);
    Assert.AreEqual(1, Persistencia.Confirmaciones);
    Assert.AreEqual(0, Persistencia.Reversiones);
    // El proceso queda cerrado y el host recibe UN solo aviso.
    Assert.AreEqual(0, Lineas.Profundidad);
    Assert.AreEqual(1, Lineas.PostsNotificados);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Desmontar_RevierteCuandoLaConversionPierdeUnidades;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasDesmontajeTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
  bLanzoExcepcion: Boolean;
begin
  // Celdas sin su linea: la expansion no puede volcarlas y el
  // documento perderia unidades. El invariante lo detecta y el caso de
  // uso revierte.
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.AnyadirCelda(9, 21, '38', '', 2);
  Modelo := ModeloDePrueba(Persistencia);
  try
    bLanzoExcepcion := False;
    try
      EjecutarDesmontaje(RefLineas, Persistencia, Modelo);
    except
      bLanzoExcepcion := True;
    end;
    Assert.IsTrue(bLanzoExcepcion);
    Assert.AreEqual(1, Persistencia.Reversiones);
    Assert.AreEqual(0, Persistencia.Confirmaciones);
    Assert.AreEqual(0, Lineas.Profundidad);
  finally
    FreeAndNil(Modelo);
  end;
end;

procedure TPruebasModoTallasConversion.
  Desmontar_RespetaUnaTransaccionYaActiva;
var
  Lineas: TLineasTallasMemoria;
  RefLineas: ILineasDesmontajeTallas;
  Persistencia: TPersistenciaTallasMemoria;
  Modelo: TModeloTallas;
begin
  Lineas := TLineasTallasMemoria.Create;
  RefLineas := Lineas;
  Lineas.AnyadirLinea(LineaPivotada);
  Persistencia := TPersistenciaTallasMemoria.Create;
  Persistencia.AnyadirCelda(1, 21, '38', '', 2);
  Persistencia.AnyadirCelda(1, 22, '40', '', 3);
  Modelo := ModeloDePrueba(Persistencia);
  try
    Persistencia.MarcarTransaccionActiva;
    EjecutarDesmontaje(RefLineas, Persistencia, Modelo);
    // Transaccion ajena: ni se abre, ni se confirma, ni se revierte.
    Assert.AreEqual(0, Persistencia.Inicios);
    Assert.AreEqual(0, Persistencia.Confirmaciones);
    Assert.AreEqual(0, Persistencia.Reversiones);
  finally
    FreeAndNil(Modelo);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasModoTallasModelo);
  TDUnitX.RegisterTestFixture(TPruebasModoTallasConversion);

end.
