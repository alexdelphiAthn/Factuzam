# Informes > Comparativa de periodos (BI interanual)

Cuadro de mando para comparar un mismo rango de fechas entre **este año** y
**el año anterior**. El usuario elige un rango (p.ej. 01/01 a 31/01) y la
pantalla dibuja dos series solapadas (línea), una por cada periodo.

## Qué compara

Selector **Magnitud**:

| Magnitud                 | Origen                    | Agregado             |
|--------------------------|---------------------------|----------------------|
| Ventas facturadas (€)    | `fza_facturas`            | `SUM(TOTAL_LIQUIDO_FAC)` |
| Coste movido (€)         | `fza_movimientos_almacen` | `SUM(TOTAL_COSTE_MOV)`   |
| Unidades movidas         | `fza_movimientos_almacen` | `SUM(CANTIDAD_MOV)`      |
| Nº de movimientos        | `fza_movimientos_almacen` | `COUNT(*)`               |

> Nota de negocio: la tabla de movimientos guarda **coste** y **unidades**,
> no el **PVP** de venta. El importe de venta real sale de `fza_facturas`
> (`TOTAL_LIQUIDO_FAC` = total a pagar). Por eso "Ventas facturadas (€)"
> consulta facturas y el resto de magnitudes consultan movimientos.

Selector **Agrupación** del eje X: Día / Semana / Mes.

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

- Filtro por almacén y por tipo de movimiento (E/S), descartados de momento
  para simplificar la primera versión.
- Excluir fases de factura no definitivas (`FASE_FAC`) si procede; ahora se
  suman todas las facturas del rango.
- Exportar la comparativa a Excel / imprimir.
