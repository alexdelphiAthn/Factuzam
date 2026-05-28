# Acumulados de stock por subtipo en `fza_articulos_stockactual`

## Motivación

La consulta de stock (Ctrl+U → `TfrmStockConsulta`) calcula los estados
"Entradas / Salidas / Ventas / Regularizadas / Traspasos / ..." con
`SUM(CANTIDAD_MOV)` sobre `fza_movimientos_almacen`. En instalaciones con
muchos movimientos esto se vuelve lento y obliga a recorrer toda la tabla.

La solución es **denormalizar** los acumulados directamente en la fila de
stock (`fza_articulos_stockactual`), de modo que cada SP de inserción de
movimiento incremente el acumulado correspondiente. La consulta queda en
SELECT directo por PK.

## Esquema añadido

`fza_articulos_stockactual` gana 12 columnas nuevas
(`decimal(19,6) NOT NULL DEFAULT 0`):

| Columna                       | Significado                              |
|-------------------------------|------------------------------------------|
| `CANTIDAD_ENT_COMPRA_STK`     | Entradas por compras (AC)                |
| `CANTIDAD_SAL_COMPRA_STK`     | Devoluciones a proveedor (AE/AC sal)     |
| `CANTIDAD_ENT_VENTA_STK`      | Devoluciones de cliente (AE ent, VE ent) |
| `CANTIDAD_SAL_VENTA_STK`      | Ventas (VE)                              |
| `CANTIDAD_ENT_TRASPASO_STK`   | Recepciones por traspaso (TR/AT ent)     |
| `CANTIDAD_SAL_TRASPASO_STK`   | Envíos por traspaso (TR/AT sal)          |
| `CANTIDAD_ENT_REGULAR_STK`    | Regularizaciones positivas (IN ent)      |
| `CANTIDAD_SAL_REGULAR_STK`    | Regularizaciones negativas (IN sal)      |
| `CANTIDAD_ENT_DEPOSITO_STK`   | Depósitos recibidos (DP ent, futuro)     |
| `CANTIDAD_SAL_DEPOSITO_STK`   | Depósitos enviados (DP sal, futuro)      |
| `CANTIDAD_ENT_PRESTAMO_STK`   | Préstamos recibidos (PR ent, futuro)     |
| `CANTIDAD_SAL_PRESTAMO_STK`   | Préstamos enviados (PR sal, futuro)      |

Las columnas existentes se mantienen sin cambios:
- `CANTIDAD_STK` — stock disponible real (entradas − salidas, agregado)
- `CANTIDAD_PTE_RECIBIR_STK`, `CANTIDAD_PTE_SERVIR_STK`
- `CANTIDAD_PTE_TRASPASAR_STK`, `CANTIDAD_PTE_RECTRASPASAR_STK`

## Mapeo `TIPO_DOC_MOV` → acumulado

| Doc | Significado            | E → ENT_*          | S → SAL_*          |
|-----|------------------------|--------------------|--------------------|
| AC  | Albarán compra         | `ENT_COMPRA`       | `SAL_COMPRA`       |
| AE  | Albarán entrada/devol. | `ENT_VENTA`        | `SAL_COMPRA`       |
| VE  | Venta                  | `ENT_VENTA`        | `SAL_VENTA`        |
| TR  | Traspaso               | `ENT_TRASPASO`     | `SAL_TRASPASO`     |
| AT  | Anti-traspaso          | `ENT_TRASPASO`     | `SAL_TRASPASO`     |
| IN  | Inventario             | `ENT_REGULAR`      | `SAL_REGULAR`      |
| DP  | Depósito (futuro)      | `ENT_DEPOSITO`     | `SAL_DEPOSITO`     |
| PR  | Préstamo (futuro)      | `ENT_PRESTAMO`     | `SAL_PRESTAMO`     |

## Flujo de actualización

El SP `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` (única vía oficial para
insertar en `fza_movimientos_almacen`) ahora hace en la misma transacción:
1. `INSERT INTO fza_movimientos_almacen` con el movimiento real.
2. `INSERT … ON DUPLICATE KEY UPDATE` sobre `fza_articulos_stockactual`,
   incrementando `CANTIDAD_STK` (positivo o negativo) **y** el acumulado
   `CANTIDAD_ENT_xxx_STK` o `CANTIDAD_SAL_xxx_STK` correspondiente.

Reglas:
- El acumulado siempre suma (cantidades absolutas, nunca negativas).
- El stock real (`CANTIDAD_STK`) sí refleja el signo.
- Eliminar un movimiento (revertir) debería decrementar el acumulado
  correspondiente — pendiente revisar `RevertirMovimientosDesdeAlbaranCompra`.

## Reinicialización para datos existentes

El script `stocks_acumulados.sql` incluye al final un `UPDATE` que
recalcula los acumulados desde cero a partir de `fza_movimientos_almacen`
(solo `ESACTIVO_MOV='S'`). Es idempotente: puedes lanzarlo cuantas veces
quieras.

## Modos de visualización en Ctrl+U (pendiente Fase 1 UI)

- **Simplificado** (por defecto): solo `CANTIDAD_STK`,
  `CANTIDAD_ENT_*_STK` agregado, `CANTIDAD_SAL_*_STK` agregado,
  `CANTIDAD_PTE_SERVIR_STK`, `CANTIDAD_PTE_RECIBIR_STK`.
- **Desglosado**: añade los 12 acumulados por subtipo.

El toggle de modo se persiste por usuario en `fza_usuarios_perfiles`.

## Notas pendientes

1. Verificar el SP de **reversión** de movimientos para que también
   decremente los acumulados.
2. Añadir códigos `DP` (depósito) y `PR` (préstamo) cuando se
   implementen esos flujos.
3. Migrar `TfrmStockConsulta` para leer del acumulado en lugar de hacer
   `SUM` (Fase siguiente).
