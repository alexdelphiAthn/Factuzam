# Pruebas de compras — albarán desde pedido (capa de datos)

Fecha: 26/07/2026. Entorno: MariaDB local con la demo cargada
(`factuzam_test`). Script: `test_albaran_pedido_compra.py`.

## Resultado: 38 comprobaciones, 0 fallos

Estas pruebas atacan el refactor de compras más grande de la Fase 2: la
fusión de `CrearAlbaranDesdePedido` dentro de
`CrearAlbaranDesdePedidoConCantidades` (`inLibPedidosCompra`, −278 líneas).
Antes eran dos funciones gemelas de ~350 líneas; ahora el flujo "recibir
todo lo pendiente" construye una celda por línea y llama al mismo código
que usa el pivote celda a celda. **Si las dos rutas divergieran, el
albarán generado desde el botón normal no coincidiría con el generado
desde el pivote** — y eso es exactamente lo que mide la prueba T1.

He portado a Python el SQL literal de las dos funciones (la consulta de
pendientes, el `INSERT` de cabecera, el de líneas, el `UPDATE` de
`CANTIDAD_RECIBIDA_PEDCLIN`, el recálculo de totales y el de estado) y
lo he ejecutado sobre pedidos clonados del A1/000002 de la demo.

| # | Bloque | Qué valida | Resultado |
|---|---|---|---|
| T1 | Wrapper ≡ celdas | 12 líneas idénticas campo a campo, mismos totales de cabecera, mismas cantidades recibidas, mismo estado final | 6/6 |
| T2 | Tope por línea | 3 celdas sobre la misma línea pidiendo el triple del pendiente → se recibe el pendiente exacto y se crea 1 sola línea | 4/4 |
| T3 | Filtro de almacén | Una línea en otro almacén queda fuera del albarán, sigue con recibida 0 y el pedido queda PARCIAL | 5/5 |
| T4 | Sin pendiente | La segunda pasada devuelve False con "No hay líneas pendientes" y no crea cabecera | 4/4 |
| T5 | Cabecera huérfana | Con celdas ya servidas la cabecera se crea y **se borra sola**; 0 albaranes sin líneas | 3/3 |
| T6 | Estados | ABIERTO → PARCIAL → RECIBIDO, y un pedido CANCELADO no se reescribe | 4/4 |
| T7 | Numeración | Líneas 0010, 0020… y `CONTADOR_LINEAS_ALBC` = `LPAD(n*10,8,'0')`; albarán CERRADO | 4/4 |
| T8 | Atomicidad | Con la transacción de `UniDataPedidos` (`bTransPropia`), un fallo simulado en movimientos no deja ni albarán ni cantidades recibidas | 3/3 |
| T9 | Exento intracom. | Fuerza tipo IVA `E` al 0 %; la cabecera sale sin impuestos y líquido = bases | 5/5 |

### Control negativo (para que la prueba tenga dientes)

Sobre una copia del script quité el tope por línea (`dPdteLinea`) y el
filtro de almacén del bucle. La batería pasó de 38/38 a **33 OK y 5
fallos**, señalando justo lo que debía: cantidad recibida el triple del
pendiente, 3 líneas donde debía haber 1, `CANTIDAD_RECIBIDA` por encima
de `CANTIDAD_PEDCLIN`, y un albarán creado donde no debía haberlo. Es
decir: las comprobaciones no pasan "por casualidad".

Un detalle interesante del control: quitar el filtro de almacén del
bucle **no** rompió T3, porque el wrapper ya filtra en la consulta de
pendientes. Es defensa en profundidad, no redundancia inútil: el pivote
sí puede mandar celdas de otro almacén.

## Qué queda fuera a propósito

El script marca como STUB los dos pasos posteriores que el refactor no
tocó: `GenerarMovimientosDesdeAlbaranCompra` y
`GenerarPdteRecibirDesdePedido`. Los movimientos de compra ya se
validaron por su lado (índice único FC/VE, `test_indice_movimientos.py`)
y la reversión de sesiones en `test_revertir_sesion.py`.

## Lo que sigue necesitando pantalla

- Albarán desde pedido de compra **desde la aplicación**, en las dos
  rutas (botón "todo lo pendiente" y pivote celda a celda), para ver que
  el grid pivote manda las celdas que creemos.
- Materializar / revertir sesión de compra mirando la pestaña Log: que
  aparezcan los `AVISO:` nuevos en vez de silencios, y que rematerializar
  no duplique documentos.

Ambas quedaron bloqueadas al caducar el permiso de control del
escritorio.
