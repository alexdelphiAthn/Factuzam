# Fix: numeración de la retirada del cierre de arqueo

## Problema

Todas las operaciones de caja (ventas, entradas de cambio `EC`, gastos `GC`
manuales, traspasos) obtienen su `NUMERO_OPERACION_OPCAJA` del contador
centralizado vía el SP `PRC_GET_NEXT_OP_CAJA` (serie `'OV'`, tabla
`fza_contadores`), que devuelve el número **correlativo y formateado a 8
dígitos** (`LPAD(CON, NUM_DIGITOS_CON, '0')` → `00000162`).

La **retirada de efectivo que se graba al cerrar el arqueo** era la única
excepción: en `inLibArqueoPersistencia.GrabarArqueo` (bloque
`if AImporteRetirada > 0`) el número se calculaba dentro del propio INSERT con
`(SELECT IFNULL(MAX(CAST(NUMERO_OPERACION_OPCAJA AS UNSIGNED)),0)+1 …)`. Eso:

1. **No formateaba** → insertaba `162` en vez de `00000162`.
2. **No incrementaba `fza_contadores`** → el contador `'OV'` no avanzaba y la
   siguiente operación normal reusaba el mismo número → **duplicados** (p. ej.
   `162` retirada y `00000162` entrada de cambio).

Se ve en el informe A4 de operaciones: las filas «Retirada banco / encargado»
salían como `162`, `164`, `165`, `166`.

## Solución (Opción A)

`GrabarArqueo` reserva el número de la retirada con `PRC_GET_NEXT_OP_CAJA`
(igual que el resto de operaciones) **antes** de `AConn.StartTransaction`, y lo
usa en el INSERT (`:NUMOP`). Se hace antes de la transacción porque el SP
gestiona la suya propia (`START TRANSACTION` / `COMMIT`): invocarlo dentro de la
transacción del cierre provocaría un *commit* implícito y rompería su
atomicidad. Si el cierre se revierte después de reservar, queda un hueco en la
numeración, igual que en cualquier operación anulada (comportamiento normal de
un contador).

No toca el esquema ni el SP. **No hay SQL nuevo.**

## Pendiente

Los registros **ya grabados** con número mal formateado / duplicado (`162`,
`164`…) siguen como están. Sanearlos requiere un script de datos con cuidado por
las colisiones (un `162` crudo y un `00000162` del contador conviven). Queda a
la espera de decisión.
