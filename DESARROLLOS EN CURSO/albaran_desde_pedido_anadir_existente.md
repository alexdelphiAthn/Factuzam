# Crear albarán desde pedido — añadir a un albarán existente

Mejora del flujo de ventas "Crear albarán desde pedido" (`inMtoPedidos`):
además de crear un albarán nuevo, ahora se puede **añadir las líneas a un
albarán que ya existe** del propio pedido.

**Sin cambios de esquema.** Reutiliza los procedimientos
`PRC_PED_CREAR_ALBARAN_LINEA` y `PRC_PED_CREAR_ALBARAN_FIN` contra el
albarán destino; sólo se omite `PRC_PED_CREAR_ALBARAN_INICIO` cuando se
añade a uno existente.

---

## Albaranes elegibles

Sólo los albaranes **del mismo pedido** (`NUMERO_PED_ALB` / `SERIE_PED_ALB`
= pedido actual) que **no estén facturados** (`ESTADO_ALB <> 'FACTURADO'`).
Con esta restricción el cliente y la empresa siempre coinciden (proceden
del mismo pedido) y el enlace de cabecera `NUMERO_PED_ALB` sigue siendo
coherente, de modo que la pestaña «Albaranes» del pedido los sigue
mostrando.

---

## Pantalla

`inMtoModalSelAlmacenAlbaran` (modal "Crear albarán desde pedido") añade:

- Casilla **«Añadir a un albarán ya existente de este pedido»**
  (`chkAnadirExistente`). Se deshabilita si el pedido no tiene albaranes
  no facturados.
- Combo **«Albarán destino»** (`cbbAlbaran`) con los albaranes elegibles
  (número, serie, fecha, estado, total). Sólo activo con la casilla
  marcada.
- El **almacén** sigue siendo obligatorio en ambos modos: las líneas que
  se añaden necesitan almacén para generar los movimientos de salida.

El combo de albaranes se alimenta de `unqryAlbaranesPed` (mismo SELECT
descrito arriba).

---

## Lógica (`UniDataPedidos.CrearAlbaranDesdePedido`)

La función admite dos parámetros opcionales nuevos
(`AAlbExistenteNum` / `AAlbExistenteSerie`):

1. Si vienen informados, usa ese albarán como destino y **no** llama a
   `..._INICIO`; si no, crea cabecera nueva como hasta ahora.
2. Antes de insertar líneas, captura el mayor `LINEA_ALBLIN` del albarán
   destino (`nMaxLineaPrev`; 0 en un albarán nuevo).
3. Inserta las líneas con `..._LINEA` (numeración MAX+10, respeta lo
   pendiente del pedido).
4. Fija el almacén elegido **sólo en las líneas nuevas**
   (`LINEA_ALBLIN > nMaxLineaPrev`), sin tocar las que ya hubiera en un
   albarán existente.
5. Llama a `..._FIN`: recalcula los totales del albarán completo y
   actualiza el estado del pedido (PARCIAL / ENTREGADO).

---

## Pendiente / posibles mejoras

- Preseleccionar en el combo de almacén el almacén del albarán destino
  cuando todas sus líneas comparten uno.
- Avisar si el albarán destino tiene una fecha muy anterior (entrega en
  un albarán "antiguo").
