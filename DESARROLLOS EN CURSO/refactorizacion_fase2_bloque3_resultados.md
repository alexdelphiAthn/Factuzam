# Fase 2, bloque 3 — Fusión de CrearAlbaranDesdePedido (compras)

Fecha: 26/07/2026. Fichero: `src/Lib/inLibPedidosCompra.pas` (1.665 → 1.387 líneas).

## Cambio

Las dos funciones gemelas de ~350 líneas cada una quedan en un solo camino de
código:

- **`CrearAlbaranDesdePedidoConCantidades`** es ahora el único motor (sin
  cambios en su cuerpo). Ya llevaba el tope de seguridad por línea (no recibir
  más que el pendiente real, con reparto entre celdas de la misma línea) y la
  limpieza de cabecera huérfana si ninguna línea es válida.
- **`CrearAlbaranDesdePedido`** (la clásica, "todo lo pendiente del almacén")
  es un wrapper de ~70 líneas: consulta las líneas pendientes del almacén
  (mismo SQL y mismo filtro `IFNULL(NULLIF(CODIGO_ALMACEN_PEDCLIN...))` que
  antes), construye una `TCeldaARecibir` por línea y delega. Mensaje de
  "no hay pendientes" idéntico al histórico.
- Firmas públicas intactas: los llamantes (`inMtoPedidosCompra`, sesiones) no
  se tocan.

Diferencia de comportamiento deliberada y menor: el mensaje de éxito del flujo
clásico ahora incluye "(N lineas)" como el de cantidades; y el flujo clásico
pasa por el tope de seguridad del pendiente (antes confiaba solo en el SQL) —
estrictamente más seguro.

## Compilación (en tu máquina, verificada a fondo)

Primera pasada dio una lectura confusa: el log referenciaba números de línea
del fichero VIEJO. Causa: carrera entre mi escritura del fichero y el
lanzamiento del build (y una caché del puente de ficheros sirviendo una copia
antigua). Se verificó con `md5sum` en tu disco que el fichero era el nuevo y
se relanzó:

- **0 errores.**
- Total compilado: **307.548 líneas = 307.826 − 278**, exactamente las líneas
  eliminadas por la fusión — la prueba aritmética de que el build vio la
  versión nueva.
- Hints de la unidad ahora en las posiciones nuevas (872/899, `Result := 0`
  de funciones preexistentes) y el hint del `iLinea` de la función clásica
  desapareció con ella.
- Código: 55.580.680 bytes (−16 KB).

## Pruebas manuales (UI)

| # | Prueba | Resultado esperado |
|---|---|---|
| P1 | Pedido de compra → Crear albarán "todo lo pendiente" de un almacén | Albarán con las mismas líneas/cantidades que antes de la fusión |
| P2 | Igual pero con cantidades tecleadas celda a celda en el pivote | Sin cambios (este camino no se ha tocado) |
| P3 | Almacén sin pendientes | Mensaje "No hay lineas pendientes de recibir para el almacen…" |
| P4 | Pedido con línea parcialmente recibida → crear albarán de todo lo pendiente | Recibe solo el pendiente; CANTIDAD_RECIBIDA correcta; estado del pedido CERRADO/PARCIAL correcto |
| P5 | Materializar sesión que genera albaranes (usa esta lib) | Sin cambios |

## Estado de la Fase 2

1. `inLibImpuestosComun` — hecho, compilado. 2. Modal remesas unificado —
hecho, compilado. 3. Fusión albarán-desde-pedido — hecho, compilado.
4. Conversión IVA única + bug `AsInteger` — pendiente (último bloque).
