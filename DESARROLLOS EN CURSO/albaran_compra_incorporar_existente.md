# Crear albarán de compra desde pedido — incorporar a uno existente

Mejora del flujo de compras "Crear albarán" (`inMtoPedidosCompra`):
además de crear un albarán de compra nuevo, ahora se pueden **incorporar
las líneas que se reciben a un albarán de compra que ya existe** del
propio pedido.

**Sin cambios de esquema.** Reutiliza la tabla `fza_albaranes_compra` y
las librerías de movimientos existentes.

---

## Albaranes elegibles

Sólo los albaranes **del mismo pedido** (`NUMERO_PED_ALBC` /
`SERIE_PED_ALBC` = pedido actual) que **no estén** `FACTURADO` ni
`CANCELADO`. En la práctica serán albaranes en estado `CERRADO` (los de
compra nacen cerrados al crearse, porque al cerrarse disparan los
movimientos de entrada de stock).

---

## Stock: cómo se incorpora sin duplicar

`GenerarMovimientosDesdeAlbaranCompra` bloquea la doble generación (si el
albarán ya tiene movimientos `AC`, lanza excepción). Por eso, al
incorporar a un albarán ya cerrado, el cierre común
(`RegenerarMovimientosYCerrarAlbaranCompra` en `inLibPedidosCompra`) hace:

1. Recalcular totales del albarán sobre **todas** sus líneas.
2. **Revertir** los movimientos previos del albarán
   (`RevertirMovimientosDesdeAlbaranCompra`, no-op si no hay).
3. **Regenerar** los movimientos para **todas** las líneas (viejas +
   nuevas) con `GenerarMovimientosDesdeAlbaranCompra` (el guard pasa
   porque acabamos de revertir).
4. Dejar el albarán `CERRADO`.
5. Resincronizar pendientes (`GenerarPdteRecibirDesdePedido`) y recalcular
   `ESTADO_PEDC`.
6. Aplicar la temporada del modal si procede.

Efecto neto en stock: las líneas viejas salen y vuelven a entrar (neto 0)
y las nuevas entran (neto +nuevas). Todo dentro de la transacción que ya
abre `btnCrearAlbaranClick`.

Las **funciones de creación** (`CrearAlbaranDesdePedido` /
`...ConCantidades`) quedan **intactas**; las de incorporar son nuevas:

- `IncorporarAlbaranDesdePedido` — líneas pendientes del almacén.
- `IncorporarAlbaranDesdePedidoConCantidades` — cantidades tecleadas
  celda a celda (modo pivote / vertical).

Ambas continúan la numeración `LINEA_ALBCLIN` desde el máximo ya presente
en el albarán destino (`MaxLineaAlbaranCompra`).

---

## Pantallas

- **Pestaña «Albaranes»** (solo lectura) en `inMtoPedidosCompra` con los
  albaranes creados desde el pedido (commit anterior).
- **Modal `inMtoModalSelAlmacenPedido`**: casilla **«Incorporar a un
  albarán ya existente de este pedido»** + **grid** con los albaranes
  elegibles (número, serie, fecha, estado, total). Al marcarla, se elige
  el albarán en el grid; la serie/ref/fecha del albarán nuevo se
  deshabilitan (no aplican). El almacén sigue siendo obligatorio (define
  qué líneas se reciben) y la temporada se mantiene.

`btnCrearAlbaranClick` enruta a las funciones de incorporar cuando
`form.Incorporar = True`, respetando el modo celdas/pendiente-total.

---

## Pendiente / posibles mejoras

- Selección explícita de fila en el grid del modal: hoy se toma el
  albarán con foco (el cursor del dataset sigue a la fila seleccionada).
- Avisar si el albarán destino tiene fecha muy anterior.
