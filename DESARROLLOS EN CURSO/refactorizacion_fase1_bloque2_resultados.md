# Fase 1, bloque 2 (paso 1.3) — Transacción en CrearAlbaranDesdePedido (venta)

Fecha: 26/07/2026.

## Cambio aplicado

`DataModules/UniDataPedidos.pas` — `TdmPedidos.CrearAlbaranDesdePedido` envuelve
ahora los pasos 1–3 (cabecera vía `PRC_PED_CREAR_ALBARAN_INICIO`, líneas vía
`…_LINEA`, totales y estado del pedido vía `…_FIN`) en el idiom `bTransPropia`
(mismo patrón que `TdmAlbaranes`): commit si todo va bien, rollback + `raise` si
algo falla. Detalles del diseño:

- `InstalarProcedimientos` queda **fuera** de la transacción (es DDL:
  `CREATE PROCEDURE` haría commit implícito en MySQL/MariaDB). Comentado en el código.
- El refresco de queries de pantalla (paso 4) queda fuera, tras el commit.
- El contrato externo no cambia: las excepciones ya se propagaban antes
  (el método no tenía try/except); ahora además revierten lo hecho.

## Alcance comprobado de las variantes de compra

`inLibPedidosCompra.CrearAlbaranDesdePedido(-ConCantidades)` no abren transacción
**por diseño documentado** (cabecera de la unidad: "ninguna abre ni cierra
StartTransaction") y su llamante ya las envuelve
(`inMtoPedidosCompra.pas:2870`, patrón `bTxOwned`). El hueco real era solo la
variante de venta. No se ha tocado compras.

## Verificaciones previas del entorno de pruebas

- `PRC_PED_CREAR_ALBARAN_INICIO/LINEA/FIN`: sin `COMMIT`/`START TRANSACTION`
  internos — envolvibles con seguridad.
- Tablas implicadas (`fza_albaranes`, `fza_albaranes_lineas`, `fza_pedidos`,
  `fza_pedidos_lineas`): InnoDB.
- El SP `LINEA` recalcula el pendiente desde las líneas de albarán reales
  (no desde `CANTIDAD_PENDIENTE_PEDLIN`), y usa `LAST_INSERT_ID()` para el
  contador de líneas — compatible con transacción.

## Resultados (MariaDB 10.11 + factuzam_demo.sql recién cargado)

Secuencia replicada exactamente como la ejecuta el código nuevo; script
reproducible `test_albaran_pedido.py` en esta carpeta.

| # | Prueba | Datos | Resultado |
|---|---|---|---|
| T1 | Creación feliz | PED/000001 | **PASA**: albarán + línea creados, pedido pasa a PARCIAL, entregada 10 |
| T2 | Fallo en FIN (tabla inexistente) antes de insertar líneas | PED/000002 | **PASA**: sin albarán fantasma, estado del pedido intacto |
| T3 | Tras el rollback, la siguiente creación funciona | PED/000002 | **PASA**: sin errores de "transacción activa"; contador no corrupto |
| T4 | Dos creaciones consecutivas | PED/000003 | **PASA**: números de albarán distintos (000003/000004) |
| T5 | **La crítica**: fallo en FIN con líneas YA insertadas y contadores del pedido ya actualizados (fila del pedido bloqueada por otra sesión, lock wait 2s) | PED/000002, 4 líneas | **PASA**: líneas de albarán revertidas y `CANTIDAD_ENTREGADA`/`ESENTREGADA` del pedido intactos |

**5/5 superadas.** T5 es el escenario que el código antiguo dejaba corrupto:
líneas de albarán insertadas y cantidades entregadas del pedido actualizadas,
pero totales y estado sin refrescar.

## Notas de laboratorio

- Inyectar el fallo renombrando `fza_albaranes_lineas` NO sirve cuando la
  transacción ya insertó líneas: el metadata-lock de InnoDB bloquea el RENAME
  y se produce un interbloqueo. La inyección correcta es bloquear la fila de
  `fza_pedidos` desde otra sesión (el `UPDATE` del paso FIN caduca por
  `innodb_lock_wait_timeout`). Mismo apunte aplica a pruebas manuales.
- En la demo, `CANTIDAD_PENDIENTE_PEDLIN` está a 0 en líneas nunca albaranadas;
  el SP no la usa (recalcula), pero cualquier pantalla que filtre por esa
  columna mostrará pendientes vacíos con estos datos.

## Pendiente manual (requiere la app compilada)

- Compilar `UniDataPedidos.pas`.
- Flujo UI completo: botón "Crear albarán" del Mto de Pedidos con cantidades
  parciales y con albarán existente (parámetro `AAlbExistenteNum`), y
  comprobación de que el refresco de pantalla tras crear sigue correcto.
