{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasInventariosEntrada                                     }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.1.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de las decisiones de entrada de artículos en inventarios y de     }
{    la presentación de columnas (modos Auto/SKU/Tallas).                      }
{******************************************************************************}
unit PruebasInventariosEntrada;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInventariosEntrada = class
  public
    [Test]
    procedure SkuResuelto_CargaStockYAtributos;
    [Test]
    procedure ArticuloSimple_CargaStockSinAtributos;
    [Test]
    procedure PadreConVariaciones_EsperaAtributos;
  end;

  [TestFixture]
  TPruebasInventariosPresentacion = class
  public
    [Test]
    procedure ModoAutoMuestraAtributosYDesempaqueta;
    [Test]
    procedure ModoSkuOcultaAtributosYNoDesempaqueta;
    [Test]
    procedure ModosDeTallasNoEstanSoportadosEnInventarios;
    [Test]
    procedure F1CiclaEntreAutoYSku;
    [Test]
    procedure PlanNombraLasColumnasVisiblesYOcultaElResto;
    [Test]
    procedure PlanNombraConAtributoNCuandoFaltaElNombre;
    [Test]
    procedure PlanNuncaSuperaLasCincoColumnas;
    [Test]
    procedure ContratoConstruidoCortocircuitaElRepintado;
    [Test]
    procedure MismoArticuloPadreNoRepinta;
    [Test]
    procedure LineaEnEdicionUsaLasColumnasDelArticulo;
    [Test]
    procedure VistaSinAplicarCalculaLasColumnasDelInventario;
    [Test]
    procedure SinAtributosVisiblesSeOcultanTodasLasColumnas;
    [Test]
    procedure AnchoDeColumnaSoloCrece;
    [Test]
    procedure SkuCompletoExigeUnSeparadorPorAtributo;
    [Test]
    procedure SkuVacioSeSustituyePorElCodigoDeArticulo;
    [Test]
    procedure DiferenciasDeRecuentoSeCalculanConLosDosPmp;
  end;

implementation

uses
  inLibColumnasSkuIntf,
  inLibInventariosEntrada,
  inLibInventariosPresentacion,
  inLibInventariosPresentacionIntf;

function SituacionBase: TSituacionColumnasInventario;
begin
  Result.ContratoConstruido := False;
  Result.MostrarAtributos := True;
  Result.HayOrigenDeDatos := True;
  Result.LineasEnEdicion := False;
  Result.MismoArticuloPadre := False;
  Result.VistaAplicada := False;
end;

procedure TPruebasInventariosEntrada.SkuResuelto_CargaStockYAtributos;
var
  Decision: TDecisionEntradaInventario;
begin
  Decision := ResolverEntradaInventario('ART1', 'SKU1', 2);
  Assert.AreEqual('SKU1', Decision.CodigoUnidad);
  Assert.IsTrue(Decision.CargarStock);
  Assert.IsTrue(Decision.RellenarAtributos);
end;

procedure TPruebasInventariosEntrada.ArticuloSimple_CargaStockSinAtributos;
var
  Decision: TDecisionEntradaInventario;
begin
  Decision := ResolverEntradaInventario('ART1', '', 0);
  Assert.AreEqual('ART1', Decision.CodigoUnidad);
  Assert.IsTrue(Decision.CargarStock);
  Assert.IsFalse(Decision.RellenarAtributos);
end;

procedure TPruebasInventariosEntrada.PadreConVariaciones_EsperaAtributos;
var
  Decision: TDecisionEntradaInventario;
begin
  Decision := ResolverEntradaInventario('ART1', '', 2);
  Assert.AreEqual('ART1', Decision.CodigoUnidad);
  Assert.IsFalse(Decision.CargarStock);
  Assert.IsFalse(Decision.RellenarAtributos);
end;

procedure TPruebasInventariosPresentacion.
  ModoAutoMuestraAtributosYDesempaqueta;
begin
  Assert.IsTrue(MuestraAtributosEnModoInventario(mcsAuto));
  Assert.IsTrue(DesempaquetarAlCargarEnModoInventario(mcsAuto));
  Assert.IsTrue(ModoEntradaInventarioSoportado(mcsAuto));
end;

procedure TPruebasInventariosPresentacion.
  ModoSkuOcultaAtributosYNoDesempaqueta;
begin
  Assert.IsFalse(MuestraAtributosEnModoInventario(mcsSku));
  Assert.IsFalse(DesempaquetarAlCargarEnModoInventario(mcsSku));
  Assert.IsTrue(ModoEntradaInventarioSoportado(mcsSku));
end;

procedure TPruebasInventariosPresentacion.
  ModosDeTallasNoEstanSoportadosEnInventarios;
begin
  // Cada linea lleva dos cantidades (teorica y recuento) y una celda de
  // pivote solo puede representar una: el pivote quedo descartado.
  Assert.IsFalse(ModoEntradaInventarioSoportado(mcsTallasInline));
  Assert.IsFalse(ModoEntradaInventarioSoportado(mcsTallasHorPed));
  Assert.AreEqual(Ord(mcsAuto),
    Ord(ModoEntradaInventarioSiguiente(mcsTallasInline)));
end;

procedure TPruebasInventariosPresentacion.F1CiclaEntreAutoYSku;
begin
  Assert.AreEqual(Ord(mcsSku),
    Ord(ModoEntradaInventarioSiguiente(mcsAuto)));
  Assert.AreEqual(Ord(mcsAuto),
    Ord(ModoEntradaInventarioSiguiente(mcsSku)));
end;

procedure TPruebasInventariosPresentacion.
  PlanNombraLasColumnasVisiblesYOcultaElResto;
var
  Plan: TPlanColumnasAtributosInventario;
begin
  Plan := PlanColumnasAtributosInventario(
    TArray<string>.Create('Color', 'Talla'), 2);
  Assert.AreEqual('Color', Plan[1].Caption);
  Assert.IsTrue(Plan[1].Visible);
  Assert.IsTrue(Plan[1].Editable);
  Assert.AreEqual('Talla', Plan[2].Caption);
  Assert.IsTrue(Plan[2].Visible);
  Assert.AreEqual('-', Plan[3].Caption);
  Assert.IsFalse(Plan[3].Visible);
  Assert.IsFalse(Plan[3].Editable);
end;

procedure TPruebasInventariosPresentacion.
  PlanNombraConAtributoNCuandoFaltaElNombre;
var
  Plan: TPlanColumnasAtributosInventario;
begin
  Plan := PlanColumnasAtributosInventario(
    TArray<string>.Create('Color'), 2);
  Assert.AreEqual('Color', Plan[1].Caption);
  Assert.IsTrue(Plan[2].Visible);
  Assert.AreEqual('Atributo 2', Plan[2].Caption);
end;

procedure TPruebasInventariosPresentacion.PlanNuncaSuperaLasCincoColumnas;
var
  Plan: TPlanColumnasAtributosInventario;
begin
  Plan := PlanColumnasAtributosInventario(nil, 9);
  Assert.IsTrue(Plan[MAX_ATRIBUTOS_INVENTARIO].Visible);
  Assert.AreEqual('Atributo 5', Plan[MAX_ATRIBUTOS_INVENTARIO].Caption);
end;

procedure TPruebasInventariosPresentacion.
  ContratoConstruidoCortocircuitaElRepintado;
var
  Situacion: TSituacionColumnasInventario;
begin
  Situacion := SituacionBase;
  Situacion.ContratoConstruido := True;
  Assert.AreEqual(Ord(aciNinguna),
    Ord(DecidirAccionColumnasInventario(Situacion)));
end;

procedure TPruebasInventariosPresentacion.MismoArticuloPadreNoRepinta;
var
  Situacion: TSituacionColumnasInventario;
begin
  Situacion := SituacionBase;
  Situacion.MismoArticuloPadre := True;
  Assert.AreEqual(Ord(aciNinguna),
    Ord(DecidirAccionColumnasInventario(Situacion)));
end;

procedure TPruebasInventariosPresentacion.
  LineaEnEdicionUsaLasColumnasDelArticulo;
var
  Situacion: TSituacionColumnasInventario;
begin
  Situacion := SituacionBase;
  Situacion.LineasEnEdicion := True;
  Situacion.MismoArticuloPadre := True;
  // La edicion manda sobre la memoizacion por articulo padre.
  Assert.AreEqual(Ord(aciColumnasDelArticulo),
    Ord(DecidirAccionColumnasInventario(Situacion)));
end;

procedure TPruebasInventariosPresentacion.
  VistaSinAplicarCalculaLasColumnasDelInventario;
var
  Situacion: TSituacionColumnasInventario;
begin
  Situacion := SituacionBase;
  Assert.AreEqual(Ord(aciColumnasDeLaVista),
    Ord(DecidirAccionColumnasInventario(Situacion)));
  Situacion.VistaAplicada := True;
  Assert.AreEqual(Ord(aciSoloModoEntrada),
    Ord(DecidirAccionColumnasInventario(Situacion)));
end;

procedure TPruebasInventariosPresentacion.
  SinAtributosVisiblesSeOcultanTodasLasColumnas;
var
  Situacion: TSituacionColumnasInventario;
begin
  Situacion := SituacionBase;
  Situacion.MostrarAtributos := False;
  Assert.AreEqual(Ord(aciOcultarTodas),
    Ord(DecidirAccionColumnasInventario(Situacion)));
  Situacion := SituacionBase;
  Situacion.HayOrigenDeDatos := False;
  Assert.AreEqual(Ord(aciOcultarTodas),
    Ord(DecidirAccionColumnasInventario(Situacion)));
end;

procedure TPruebasInventariosPresentacion.AnchoDeColumnaSoloCrece;
begin
  Assert.AreEqual(100 + MARGEN_SWATCH_INVENTARIO,
    AnchoColumnaAtributoInventario(100, 60));
  Assert.AreEqual(500, AnchoColumnaAtributoInventario(100, 500));
end;

procedure TPruebasInventariosPresentacion.
  SkuCompletoExigeUnSeparadorPorAtributo;
begin
  Assert.IsTrue(EsSkuCompletoInventario('ART1/ROJO/M', 2));
  Assert.IsFalse(EsSkuCompletoInventario('ART1/ROJO', 2));
  // Sin atributos requeridos nunca se considera cerrado.
  Assert.IsFalse(EsSkuCompletoInventario('ART1', 0));
end;

procedure TPruebasInventariosPresentacion.
  SkuVacioSeSustituyePorElCodigoDeArticulo;
begin
  Assert.AreEqual('ART1', SkuEfectivoInventario('   ', 'ART1'));
  Assert.AreEqual('ART1/ROJO',
    SkuEfectivoInventario('ART1/ROJO', 'ART1'));
end;

procedure TPruebasInventariosPresentacion.
  DiferenciasDeRecuentoSeCalculanConLosDosPmp;
begin
  Assert.AreEqual(Double(-2),
    Double(DiferenciaUnidadesInventario(8, 10)), 0.0001);
  // Fisicas por PMP nuevo menos teoricas por PMP actual.
  Assert.AreEqual(Double(-4),
    Double(DiferenciaCosteInventario(8, 10, 2, 2)), 0.0001);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInventariosEntrada);
  TDUnitX.RegisterTestFixture(TPruebasInventariosPresentacion);

end.
