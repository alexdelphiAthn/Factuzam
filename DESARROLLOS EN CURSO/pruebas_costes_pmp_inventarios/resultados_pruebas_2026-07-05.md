# Resultados de la batería — Costes por SKU, PMP, inventarios, traspasos e informe de ventas

Ejecución: 05/07/2026, sesión 012\GEN\1, BBDD `factuzam` (127.0.0.1:3306).
Método: documentos reales creados en la UI de Factuzam (albaranes, TPV,
traspasos, inventario) y verificaciones SQL ejecutadas en el Generador de
Procesos. Artículo de prueba `TESTSKU01` con 3 SKUs (NEGRO/S, NEGRO/M,
AZUL/S). Los bugs encontrados durante la ejecución se fueron corrigiendo
en caliente (recompilación) y se retomó la prueba tras cada arreglo.

---

## Resumen por prueba

| Prueba | Descripción | Resultado |
|---|---|---|
| P0 | Preparación: proveedor, artículo, SKUs y PVPs | OK (tras F0) |
| P1 | Compra en GEN con costes distintos por SKU | OK (tras F1/F2) |
| P2 | Segunda compra en GEN, ponderación del PMP | OK |
| P3 | Venta TPV capturando PMP por SKU | OK (tras F3, repetida al 12/07) |
| P4 | Traspaso GEN→BCN heredando PMP de origen | OK (tras F4) |
| P5 | Compra en BCN, divergencia de PMP por almacén | OK |
| P6 | Inventario en GEN con ajuste de cantidad | OK con reservas (F5/F6) |
| P7 | Informe PRC_GET_MOV_VENTAS_ART | **KO — F7 (regresión de margen)** |
| P8 | Recálculo PMP y cuadre final | **KO parcial — F8 (bug en SP)** |

Cuadre final de stock (bloque 6 del SQL de verificaciones): **5/5 OK**
tras restaurar manualmente el efecto de F8.

| ALM | SKU | Cant | PMP | Valor |
|---|---|---|---|---|
| GEN | NEGRO/S | 9 | 11,00 | 99,00 |
| GEN | NEGRO/M | 5 | 10,50 | 52,50 |
| GEN | AZUL/S | 3 | 15,00 | 45,00 |
| BCN | NEGRO/S | 8 | 13,00 | 104,00 |
| BCN | NEGRO/M | 6 | 8,75 | 52,50 |

Reconciliación de unidades: NEGRO/S 17 (9+8), NEGRO/M 11 (5+6), AZUL/S 3. Todo cuadra.

---

## Hallazgos

### F0 — Alta de proveedores rota (error SQL 1064)
El alta de proveedor fallaba con error de sintaxis. **Corregido en sesión.**

### F1 — FECHA_MOV con fecha de sistema en compras
Los movimientos de almacén de albaranes de compra se grababan con la fecha
del sistema en vez de la fecha del documento. **Corregido en sesión**
(los movimientos toman la fecha del documento).

### F2 — Contador de líneas de albarán duplicado
Dos líneas del mismo albarán recibían el mismo número (0010) provocando
"entrada duplicada". **Corregido en sesión** (líneas 0010/0020/0030).

### F3 — SP_RECALCULAR no restaura los acumuladores de venta
Al anular una venta y recalcular, `CANTIDAD_SAL_VENTA_STK` no se
restablece: el SP recalcula cantidad/PMP/valor pero no los acumuladores
por tipo de movimiento. Se corrigió a mano con UPDATE. **Pendiente.**

### F4 — Traspasos con fecha de sistema
Los movimientos TA se grababan con fecha de sistema en vez de la fecha
del documento (mismo patrón que F1). Se corrigieron 4 filas por SQL.
**Pendiente revisar el alta de traspasos.**

### F5 — Contador de líneas de inventario atascado
Las líneas del inventario se sobreescribían entre sí (contador fijo en
0001). **Corregido en sesión.**

### F6 — Regularización de inventario incompleta
La regularización solo generaba movimientos de ENTRADA por el recuento,
sin la SALIDA del stock teórico, movía también SKUs con diferencia 0 y
usaba fecha de sistema. El stock quedó duplicado (17/12/6). Se normalizó
por SQL (ajuste neto por diferencia + recálculo). **Pendiente revisar la
generación de movimientos de la regularización.**

### F7 — El informe de ventas no usa el coste capturado por SKU (objetivo de la batería)
`PRC_GET_MOV_VENTAS_ART` para la venta del 12/07 devuelve:

| Campo | Esperado | Obtenido |
|---|---|---|
| UDS_VENTA | 6 | 6 ✔ |
| IMP_VENTA | 170,00 | 170,00 ✔ |
| IMP_COSTE | **66,00** | **68,32 ✗** |
| BENEFICIO | 104,00 | 101,68 ✗ |
| MARGEN1 | 61,18 | 59,81 ✗ |

68,32 = 6 × 11,387 = 6 × COSTE_ART (media global actual del artículo,
353/31). Es decir, el informe **recalcula el coste con el coste medio
actual del artículo** en vez de sumar el `TOTAL_COSTE_MOV` capturado en
los movimientos VE de la venta (3×10 + 2×10,5 + 1×15 = 66). Con costes
distintos por SKU esto falsea beneficio y margen de toda venta histórica.
**Pendiente: PRC_GET_MOV_VENTAS_ART debe costear desde los movimientos.**

### F8 — SP_RECALCULAR_PMP_LOTE_ALMACEN corrompe el PMP (variables de sesión tipadas como INT)
Al recalcular BCN/NEGRO/M (traspaso 3@10,5 + compra 3@7, PMP correcto
8,75) el SP deja **9,00** (valor 54) en `fza_articulos_stockactual` y
reescribe `PRECIO_MEDIO_MOV=9` en el movimiento de compra. Reproducible:
el mismo CALL devuelve 9 aunque el movimiento tenga 8,75 grabado.

Diagnóstico (verificado con sonda):

```sql
SET @v := 0;                -- la variable queda tipada como ENTERO
UPDATE t SET a = (@v := 10.5), b = @v;   -- a = 10,5  pero  b = 11
```

En MariaDB, el tipo de una variable de usuario dentro de un UPDATE queda
fijado por su valor al inicio de la sentencia. Como el SP inicializa
`SET @pmp := 0;` (entero), al asignar `@pmp := 10,5` la variable guarda
**11**, y la siguiente entrada calcula (3×11 + 3×7)/6 = **9**. La columna
recibe el valor correcto de la expresión, pero la variable arrastra el
redondeado — por eso el error solo aflora cuando tras una entrada con PMP
fraccionario llega OTRA entrada (caso BCN). En GEN el PMP fraccionario
(10,5) apareció en la última entrada y solo le siguieron salidas, así que
el resultado fue correcto de casualidad: el bug queda enmascarado según
el orden de los movimientos.

Fix verificado con la misma réplica (da 8,75 correcto):

```sql
SET @sku_prev := '';
SET @stock    := CAST(0 AS DECIMAL(19,6));
SET @pmp      := CAST(0 AS DECIMAL(19,6));
```

Aplicar en `SP_RECALCULAR_PMP_LOTE_ALMACEN` (y revisar el mismo patrón en
`DESARROLLOS EN CURSO/optimizar_recalculo_pmp.sql` y en
`factuzam_original.sql`, que contienen el mismo código). Nota adicional:
el CALL reporta "17 filas afectadas" — conviene revisar también que el
UPDATE...JOIN por `NUMERO_MOV` del paso 3 no toque más filas de la cuenta.

Los datos de prueba quedaron **restaurados** (stockactual BCN/NEGRO/M
8,75/52,5 y PRECIO_MEDIO_MOV=8,75 en el mov 0000001125).

---

## Otras observaciones (menores)

- Un albarán FACTURADO permite edición in-place de sus líneas desde el
  grid (se editó por accidente y hubo que cancelar); convendría bloquearlo.
- Albarán 000007, línea 0010: la descripción contiene el texto
  "TESTSKU01/NEGRO/M" pegado por accidente; hay un "PUEBAS" (sic) en una
  descripción del artículo de prueba. Cosmético.
- En el Generador de Procesos quedaron con SQL modificado SIN grabar los
  procesos 470, 494 y 499 (se usaron como editor). No pulsar Grabar en
  ellos; al salir con Cancelar quedan como estaban.
- Los movimientos 1119/1125 (BCN) tienen `INSTANTE_ALTA` vacío/NULL; el
  ORDER BY del recálculo lo usa como criterio de desempate.

## Estado de los datos de prueba

Documentos vivos en la BBDD: albaranes de compra GEN y BCN, factura TPV
000166/2026.A1 (12/07), traspaso GEN→BCN (13/07), inventario GEN (15/07,
normalizado por SQL). La venta anulada de P3 (000165) se eliminó por SQL.
Para limpiar todo el escenario TESTSKU01 hará falta un script de borrado
específico (no incluido).
