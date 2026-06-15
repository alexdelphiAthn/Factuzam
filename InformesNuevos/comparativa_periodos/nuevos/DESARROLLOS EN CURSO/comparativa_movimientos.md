# Informes > Comparativa de periodos (BI interanual)

Cuadro de mando para comparar un mismo rango de fechas entre **este año** y
**el año anterior**. El usuario elige un rango (p.ej. 01/01 a 31/01) y la
pantalla dibuja dos series solapadas (línea), una por cada periodo.

## Qué compara

Selector **Magnitud**:

| Magnitud                 | Origen                    | Agregado             |
|--------------------------|---------------------------|----------------------|
| Ventas facturadas (€)    | `fza_facturas_lineas`     | `SUM(TOTAL_FACLIN)`      |
| Coste movido (€)         | `fza_movimientos_almacen` | `SUM(TOTAL_COSTE_MOV)`   |
| Unidades movidas         | `fza_movimientos_almacen` | `SUM(CANTIDAD_MOV)`      |
| Nº de movimientos        | `fza_movimientos_almacen` | `COUNT(*)`               |

> Nota de negocio: la tabla de movimientos guarda **coste** y **unidades**,
> no el **PVP** de venta. El importe de venta real sale de facturas. Por eso
> "Ventas facturadas (€)" consulta las líneas de factura
> (`fza_facturas_lineas.TOTAL_FACLIN`) y el resto de magnitudes consultan
> movimientos.

Selector **Agrupación** del eje X: Día / Semana / Mes.

## Filtros

Tres combos (primer elemento `(Todos)` = sin filtro):

| Filtro     | Origen del combo                              | Cómo se filtra |
|------------|-----------------------------------------------|----------------|
| Almacén    | `fza_almacenes` (NOMBRE_ALM_ALM)              | mov `CODIGO_ALMACEN_MOV` / línea `CODIGO_ALM_FACLIN` |
| Familia    | `fza_articulos_familias` (NOMBRE_FAM_FAM)     | `fza_articulos.CODIGO_FAM_ART` (nivel artículo) |
| Temporada  | propiedad `'TEMPORADA'` (`fza_articulos_propiedades` + `fza_propiedades_valores`) | resolución por **color** con *fallback* a artículo |

- **Familia** es atributo de **artículo** (`CODIGO_FAM_ART`). En movimientos
  se llega al artículo vía `fza_articulos_skus` (`CODIGO_UNIDAD_MOV` →
  `CODIGO_ART_SKU`, *fallback* a `CODIGO_ARTICULO_MOV`); en ventas, vía
  `l.CODIGO_ART_FACLIN`.
- **Temporada** NO es columna de `fza_articulos`: es la propiedad
  `'TEMPORADA'` (`fza_propiedades`, `NIVEL_PROP = 'COLOR'` → **2º nivel**),
  cuyos valores están en `fza_articulos_propiedades` según
  `CODIGO_UNIDAD_ARTPROP` (`''`=artículo, `ART/COLOR`=color,
  `ART/COLOR/TALLA`=sku). **La temporada puede variar por color**, así que se
  resuelve por la clave de color del SKU (`SUBSTRING_INDEX(sku,'/',2)`) con
  *fallback* a nivel artículo. **No** se usa `vi_articulos` (colapsa la
  temporada a un valor por artículo).
- **Ventas** se calculan a **nivel de línea** (`fza_facturas_lineas`,
  `SUM(TOTAL_FACLIN)`) — única forma de segmentar por familia/temporada.
  Cambia el importe respecto al total de cabecera (`TOTAL_LIQUIDO_FAC`), pero
  es la granularidad correcta.

Los `JOIN` (artículo para familia; propiedad de temporada por color) solo se
añaden cuando ese filtro está activo; almacén no necesita `JOIN`. Los
parámetros de filtro solo se enlazan si aparecen en la consulta (`FindParam`).

## Cómo se alinean los dos periodos

Cada periodo se agrega en *buckets* por desplazamiento entero desde su fecha
de inicio (`DATEDIFF`, `FLOOR(.../7)` o `PERIOD_DIFF` de `YEAR_MONTH`). El
número de buckets se calcula a partir del rango actual y se reutiliza para el
periodo anterior, de modo que ambas series quedan alineadas punto a punto
aunque las fechas reales difieran (años bisiestos incluidos).

## Arquitectura

- **Formulario**: `src/Forms/inMtoComparativaMovimientos.pas` (+ `.dfm`),
  clase `TfrmMtoComparativaMovimientos`, hereda de `TfrmBase`.
- **Gráfico**: `TChart` (TeeChart) creado en código en `CrearGrafico` para
  evitar serializar las series en el `.dfm`. Dos `TLineSeries` (actual azul,
  anterior rojo). Si en algún entorno el *unit scope* de TeeChart no fuese
  `VCLTee`, ajustar el `uses` (units `TeEngine`, `Series`, `TeeProcs`,
  `Chart`).
- **Datos**: sólo lectura, bajo demanda, sobre la conexión global `oConn`
  (sin data module propio, por eso `DATAMODULE_WINF` queda vacío).
- **Apertura**: menú `Informes > Comparativa de periodos` ->
  `ShowMto(Self, 'ComparativaMovimientos')`. La pantalla se resuelve por
  RTTI desde `fza_winforms`; la clase se retiene con `ForceReferenceToClass`.

## Pasos para desplegar en una BBDD existente

1. Aplicar `comparativa_movimientos.sql` (idempotente).
2. Compilar y desplegar el ejecutable con la nueva unit.

## Posibles mejoras futuras

- Filtro por tipo de movimiento (E/S), descartado de momento. Los filtros
  por almacén, familia y temporada ya están disponibles.
- Excluir fases de factura no definitivas (`FASE_FAC`) si procede; ahora se
  suman todas las facturas del rango.
- Exportar la comparativa a Excel / imprimir.
