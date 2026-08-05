{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasCargaMasivaDocumentoTrabajo                           }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas puras y contrato SQL de la reposicion por SKU en documentos de    }
{    trabajo. No requiere VCL ni conexion a base de datos.                     }
{******************************************************************************}
unit PruebasCargaMasivaDocumentoTrabajo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCargaMasivaDocumentoTrabajo = class
  public
    [Test]
    procedure CantidadServir_Defaults_StockUnoACinco;
    [Test]
    procedure CantidadServir_RespetaReservaYMaximoConfigurables;
    [Test]
    procedure RepartirCantidad_MismoSkuEnVariasFilas_NoSuperaMaximoGlobal;
    [Test]
    procedure StockAlmacenVenta_UmbralesCeroYUno;
    [Test]
    procedure PreviewSql_DevuelveUnaFilaYExcluyePorSku;
    [Test]
    procedure PreviewSql_SeparaOrigenVentaYUmbralDestino;
    [Test]
    procedure PreviewSql_SinFiltroStockVenta_NoAnadeUmbralDestino;
    [Test]
    procedure PreviewSql_PropiedadYActivoSeResuelvenPorSku;
  end;

implementation

uses
  System.SysUtils,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibCargaMasivaArticulosReglas,
  UniDataCargaMasivaArticulosRepositorio;

const
  TOLERANCIA_CANTIDAD = 0.0001;

function FiltrosSqlDocumentoTrabajo: TFiltrosCargaMasivaArticulos;
begin
  Result := Default(TFiltrosCargaMasivaArticulos);
  Result.SoloActivos := True;
  Result.ExcluirYaCargados := True;
  Result.SoloConStock := True;
  Result.FiltrarVentas := True;
  Result.ConVentas := True;
  Result.FiltrarStockAlmacenVenta := True;
  Result.NumeroMinimoVentas := 1;
  Result.ReservaStockOrigen := RESERVA_STOCK_ORIGEN_DEFECTO_DTR;
  Result.MaximoServirPorSku := MAXIMO_SERVIR_POR_SKU_DEFECTO_DTR;
  Result.StockMaximoAlmacenVenta :=
    STOCK_MAXIMO_ALMACEN_VENTA_DEFECTO_DTR;
  Result.StockCombinacion := scSumaPositiva;
  Result.CodigosAlmacen := TArray<string>.Create('GEN');
  Result.CodigosAlmacenVenta := TArray<string>.Create('BCN');
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  CantidadServir_Defaults_StockUnoACinco;
const
  STOCKS: array[0..4] of Double = (1, 2, 3, 4, 5);
  CANTIDADES_ESPERADAS: array[0..4] of Double = (0, 1, 2, 2, 2);
var
  i: Integer;
  dCantidad: Double;
begin
  Assert.AreEqual(
    Double(1),
    Double(RESERVA_STOCK_ORIGEN_DEFECTO_DTR),
    TOLERANCIA_CANTIDAD);
  Assert.AreEqual(
    Double(2),
    Double(MAXIMO_SERVIR_POR_SKU_DEFECTO_DTR),
    TOLERANCIA_CANTIDAD);
  for i := Low(STOCKS) to High(STOCKS) do
  begin
    dCantidad := CalcularCantidadServirSku(
      STOCKS[i],
      RESERVA_STOCK_ORIGEN_DEFECTO_DTR,
      MAXIMO_SERVIR_POR_SKU_DEFECTO_DTR);
    Assert.AreEqual(
      CANTIDADES_ESPERADAS[i],
      dCantidad,
      TOLERANCIA_CANTIDAD,
      Format('Stock %.0f', [STOCKS[i]]));
  end;
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  CantidadServir_RespetaReservaYMaximoConfigurables;
begin
  Assert.AreEqual(
    Double(3),
    CalcularCantidadServirSku(5, 1, 3),
    TOLERANCIA_CANTIDAD);
  Assert.AreEqual(
    Double(2),
    CalcularCantidadServirSku(5, 3, 10),
    TOLERANCIA_CANTIDAD);
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  RepartirCantidad_MismoSkuEnVariasFilas_NoSuperaMaximoGlobal;
var
  aReparto: TArray<Double>;
  aStocks: TArray<Double>;
  dTotal: Double;
  i: Integer;
begin
  // Tres filas del mismo SKU, por ejemplo lotes o almacenes distintos.
  aStocks := TArray<Double>.Create(1, 3, 5);
  aReparto := RepartirCantidadServirSku(aStocks, 1, 2);

  Assert.AreEqual(3, Integer(Length(aReparto)));
  Assert.AreEqual(Double(1), aReparto[0], TOLERANCIA_CANTIDAD);
  Assert.AreEqual(Double(1), aReparto[1], TOLERANCIA_CANTIDAD);
  Assert.AreEqual(Double(0), aReparto[2], TOLERANCIA_CANTIDAD);
  dTotal := 0;
  for i := 0 to High(aReparto) do
  begin
    Assert.IsTrue(
      aReparto[i] <= aStocks[i],
      Format('La fila %d supera su stock', [i]));
    dTotal := dTotal + aReparto[i];
  end;
  Assert.AreEqual(Double(2), dTotal, TOLERANCIA_CANTIDAD);
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  StockAlmacenVenta_UmbralesCeroYUno;
begin
  Assert.AreEqual(
    Double(0),
    Double(STOCK_MAXIMO_ALMACEN_VENTA_DEFECTO_DTR),
    TOLERANCIA_CANTIDAD);
  Assert.IsTrue(CumpleStockMaximoAlmacenVenta(0, 0));
  Assert.IsFalse(CumpleStockMaximoAlmacenVenta(1, 0));
  Assert.IsTrue(CumpleStockMaximoAlmacenVenta(0, 1));
  Assert.IsTrue(CumpleStockMaximoAlmacenVenta(1, 1));
  Assert.IsFalse(CumpleStockMaximoAlmacenVenta(2, 1));
  // El repositorio agrega los lotes antes de aplicar el umbral.
  Assert.IsTrue(CumpleStockMaximoAlmacenVenta(2 + (-1), 1));
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  PreviewSql_DevuelveUnaFilaYExcluyePorSku;
var
  sSql: string;
begin
  sSql := ConstruirSqlPreviewCargaMasivaDocumentoTrabajo(
    FiltrosSqlDocumentoTrabajo);

  Assert.Contains(
    sSql,
    'SELECT A.CODIGO_ART_ART, U.CODIGO_UNIDAD_SKU,');
  Assert.Contains(sSql, 'FROM (SELECT DISTINCT');
  Assert.Contains(
    sSql,
    'S0.CODIGO_UNIDAD_STK AS CODIGO_UNIDAD_SKU');
  Assert.Contains(
    sSql,
    'AND V.CODIGO_UNIDAD_SKU = U.CODIGO_UNIDAD_SKU');
  Assert.Contains(sSql, 'AND U.ESACTIVO_SKU = ''S''');
  Assert.Contains(
    sSql,
    'AND COALESCE(FC.FASE_FAC, '''') <> ''CANCELADA''');
  Assert.Contains(sSql, 'AND FL.CANTIDAD_FACLIN > 0');
  Assert.Contains(
    sSql,
    'AND DLX.CODIGO_UNIDAD_DTL = U.CODIGO_UNIDAD_SKU)');
  Assert.DoesNotContain(
    sSql,
    'AND DLX.CODIGO_ART_DTL = A.CODIGO_ART_ART');
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  PreviewSql_PropiedadYActivoSeResuelvenPorSku;
var
  oFiltros: TFiltrosCargaMasivaArticulos;
  sSql: string;
begin
  oFiltros := FiltrosSqlDocumentoTrabajo;
  oFiltros.IdsValorPropiedad := TArray<Integer>.Create(17);
  sSql := ConstruirSqlPreviewCargaMasivaDocumentoTrabajo(oFiltros);

  Assert.Contains(
    sSql,
    'LEFT JOIN fza_articulos_propiedades PPS');
  Assert.Contains(
    sSql,
    'THEN U.CODIGO_UNIDAD_SKU ELSE NULL END');
  Assert.Contains(
    sSql,
    'THEN SUBSTRING_INDEX(U.CODIGO_UNIDAD_SKU, ''/'', 2)');
  Assert.Contains(sSql, 'PPA.CODIGO_UNIDAD_ARTPROP = ''''');
  Assert.Contains(sSql, 'WHERE PVS.ID_PV_ARTPROP IN (17)');
  Assert.Contains(
    sSql,
    'PPS.ID_PV_ARTPROP, PPC.ID_PV_ARTPROP,');
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  PreviewSql_SeparaOrigenVentaYUmbralDestino;
var
  sSql: string;
begin
  sSql := ConstruirSqlPreviewCargaMasivaDocumentoTrabajo(
    FiltrosSqlDocumentoTrabajo);

  Assert.Contains(sSql, 'S0.CODIGO_ALM_STK IN (''GEN'')');
  Assert.Contains(sSql, 'SR.CODIGO_ALM_STK IN (''GEN'')');
  Assert.Contains(sSql, '), 0) > :P_RESERVA_STOCK_ORIGEN');
  Assert.Contains(
    sSql,
    'COALESCE(NULLIF(TRIM(FL.CODIGO_ALM_FACLIN), ''''), ' +
    'FC.CODIGO_ALM_FAC) IN (''BCN'')');
  Assert.Contains(sSql, 'SUM(SD.CANTIDAD_STK)');
  Assert.Contains(sSql, 'SD.CODIGO_ALM_STK IN (''BCN'')');
  Assert.Contains(
    sSql,
    '), 0) <= :P_STOCK_MAXIMO_ALMACEN_VENTA');
  Assert.DoesNotContain(sSql, 'SD.CODIGO_ALM_STK IN (''GEN'')');
  Assert.DoesNotContain(sSql, 'SR.CODIGO_ALM_STK IN (''BCN'')');
  Assert.DoesNotContain(sSql, ':P_MAXIMO_SERVIR_POR_SKU');
end;

procedure TPruebasCargaMasivaDocumentoTrabajo.
  PreviewSql_SinFiltroStockVenta_NoAnadeUmbralDestino;
var
  oFiltros: TFiltrosCargaMasivaArticulos;
  sSql: string;
begin
  oFiltros := FiltrosSqlDocumentoTrabajo;
  oFiltros.FiltrarStockAlmacenVenta := False;
  sSql := ConstruirSqlPreviewCargaMasivaDocumentoTrabajo(oFiltros);

  Assert.DoesNotContain(sSql, 'SUM(SD.CANTIDAD_STK)');
  Assert.DoesNotContain(sSql, ':P_STOCK_MAXIMO_ALMACEN_VENTA');
end;

initialization

TDUnitX.RegisterTestFixture(TPruebasCargaMasivaDocumentoTrabajo);

end.
