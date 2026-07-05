# Acumulados de stock por subtipo en `fza_articulos_stockactual`

## Motivación

La consulta de stock (Ctrl+U → `TfrmStockConsulta`) calcula los estados
"Entradas / Salidas / Ventas / Regularizadas / Traspasos / ..." con
`SUM(CANTIDAD_MOV)` sobre `fza_movimientos_almacen`. En instalaciones con
muchos movimientos esto se vuelve lento.

La solución es **denormalizar** los acumulados directamente en la fila
de stock, de modo que cada SP de inserción de movimiento incremente el
acumulado correspondiente. La consulta queda en SELECT directo por PK.

## Modelo de subtipos y direcciones

| Categoría    | Dirección | `TIPO_DOC_MOV` | Columnas                                                |
|--------------|-----------|----------------|---------------------------------------------------------|
| COMPRA       | ENT       | AC             | `CANTIDAD_ENT_COMPRA_STK`                               |
| TRASPASO     | ENT + SAL | TR, AT, TA     | `CANTIDAD_ENT_TRASPASO_STK`, `CANTIDAD_SAL_TRASPASO_STK`|
| DEPÓSITO     | ENT + SAL | DP             | `CANTIDAD_ENT_DEPOSITO_STK`, `CANTIDAD_SAL_DEPOSITO_STK`|
| VENTA        | SAL       | VE             | `CANTIDAD_SAL_VENTA_STK`                                |
| REGULARIZ.   | ENT       | IN             | `CANTIDAD_ENT_REGULAR_STK`                              |
| ALB. VENTA   | SAL       | AV             | `CANTIDAD_SAL_ALBVENTA_STK`                             |
| ALB. ENTRADA | ENT       | AE             | `CANTIDAD_ENT_ALBENTRADA_STK`                           |

**Notas:**
- Depósito y préstamo se consideran lo mismo (`DP`).
- Albarán de entrada (`AE`) es siempre entrada, incluso si conceptualmente
  es una devolución de venta.
- Si un movimiento llega con un `(TIPO_DOC_MOV, TIPO_MOV)` que no encaja
  en ninguna fila de la tabla, **no incrementa ningún acumulado** (el
  `CANTIDAD_STK` y `VALOR_TOTAL_STK` sí se actualizan normalmente).

Total: **9 columnas nuevas** (`decimal(19,6) NOT NULL DEFAULT 0`).

Columnas existentes que se mantienen sin cambios:
- `CANTIDAD_STK` — stock disponible real (E−S agregado)
- `CANTIDAD_PTE_RECIBIR_STK`, `CANTIDAD_PTE_SERVIR_STK`
- `CANTIDAD_PTE_TRASPASAR_STK`, `CANTIDAD_PTE_RECTRASPASAR_STK`

## Flujo de actualización

`PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` (única vía oficial para insertar
en `fza_movimientos_almacen`) ahora hace en la misma transacción:
1. `INSERT INTO fza_movimientos_almacen` con el movimiento real.
2. `INSERT … ON DUPLICATE KEY UPDATE` sobre `fza_articulos_stockactual`
   incrementando `CANTIDAD_STK` (positivo o negativo) **y** el acumulado
   del subtipo correspondiente.

Reglas:
- El acumulado siempre suma cantidades **absolutas** (nunca negativas).
- `CANTIDAD_STK` sí refleja el signo (E suma, S resta).
- Si se revierte un movimiento (borrar/desactivar), conviene decrementar
  el acumulado — **pendiente** verificar
  `RevertirMovimientosDesdeAlbaranCompra`.

## Modos en Ctrl+U (Fase 1, pendiente)

- **Simplificado** (por defecto): `CANTIDAD_STK`, suma de todas las
  `CANTIDAD_ENT_*_STK`, suma de todas las `CANTIDAD_SAL_*_STK`,
  `CANTIDAD_PTE_SERVIR_STK`, `CANTIDAD_PTE_RECIBIR_STK`.
- **Desglosado**: los 9 acumulados por subtipo expuestos como columnas
  separadas.

Toggle persistido por usuario en `fza_usuarios_perfiles`.

## Reinicialización

El script `stocks_acumulados.sql` incluye al final un `UPDATE` que
recalcula los 9 acumulados desde cero a partir de
`fza_movimientos_almacen` (solo `ESACTIVO_MOV='S'`). Idempotente.

## Pendiente

1. Verificar SPs de reversión (`RevertirMovimientosDesdeAlbaranCompra`,
   etc.) para que decrementen los acumulados.
2. Implementar Fase 1 (UI de modo Simplificado/Desglosado en
   `TfrmStockConsulta`).
3. Definir flujo de inserción para `DP` (depósito) cuando se implemente.
