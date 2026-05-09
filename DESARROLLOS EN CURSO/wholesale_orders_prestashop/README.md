# Pedidos de Venta Mayor + Albaranes + Integración PrestaShop

Desarrollo del flujo completo de **pedidos de venta** con importación desde
PrestaShop y generación de **albaranes** parciales o totales a partir de las
cantidades entregadas en cada línea del pedido.

## Resumen funcional

1. **Mantenimiento de pedidos** (`inMtoPedidos`) con la misma estética que
   facturas (cabecera, datos empresa, datos cliente fiscal, datos cliente envío,
   líneas, albaranes asociados, mensajes, observaciones, totales).
2. Cada **línea del pedido** tiene tres cantidades:
   - `CANTIDAD_PEDLIN`            — pedido por el cliente
   - `CANTIDAD_ENTREGADA_PEDLIN`  — escrita por el usuario (parcial o total)
   - `CANTIDAD_PENDIENTE_PEDLIN`  — calculada
3. Al pulsar **Crear albarán**, las cantidades marcadas como entregadas se
   transforman en una nueva fila `fza_albaranes` + N filas `fza_albaranes_lineas`,
   y `CANTIDAD_ENTREGADA_PEDLIN` queda acumulada para que la siguiente entrega
   parta del nuevo pendiente.
4. **Importar de PrestaShop** abre un modal que lista los pedidos remotos y
   permite seleccionar cuáles incorporar a `fza_pedidos`.

## Archivos nuevos / modificados

### SQL (en este mismo directorio)
- `01_schema_pedidos_albaranes.sql` — `ALTER`s sobre `fza_pedidos` y
  `fza_pedidos_lineas`, creación de `fza_albaranes` y `fza_albaranes_lineas`,
  vistas `vi_*`, tres procedimientos para crear albarán (inicio/línea/fin),
  alta en `fza_winforms` y en `fza_tipos_documentos`.

### Librerías
- `src/Lib/inLibPresta.pas`           — copia para producción del modelo `TOrder`.
- `src/Lib/ScanDateTime.pas`          — utilidad de parseo de fechas.
- `src/Lib/inLibPrestaImporter.pas`   — wrapper REST sobre la API de PrestaShop
  (`TPrestaConn` + `ListarPedidosResumen`).

### Formularios y datos
- `src/DataModules/UniDataPedidos.pas / .dfm`        — actualizado con queries
  para mensajes, albaranes asociados, importación PrestaShop y stored procs
  `PRC_PED_CREAR_ALBARAN_*`.
- `src/DataModules/UniDataAlbaranes.pas / .dfm`      — nuevo data module.
- `src/Forms/inMtoPedidos.pas / .dfm`                — pantalla rediseñada con
  cabecera + tabs y los botones Crear Albarán / Importar PrestaShop.
- `src/Forms/inMtoAlbaranes.pas / .dfm`              — nueva pantalla de
  mantenimiento de albaranes.
- `src/Modals/inMtoModalImportarPedidosPS.pas / .dfm` — modal de selección de
  pedidos remotos a importar.

### Registro en proyecto y menú
- `fzam.dpr`, `fzam.dproj` — referencias a las nuevas unidades.
- `src/Core/inMtoPrincipal.pas / .dfm` — entradas de menú para Pedidos y
  Albaranes en "Ventas Mayor".

## Despliegue

1. Ejecutar `01_schema_pedidos_albaranes.sql` contra la base de datos.
2. Recompilar `fzam.dproj`.
3. Las pantallas de Pedidos y Albaranes están disponibles desde el menú
   `Ventas Mayor → Pedidos / Albaranes`.

## Notas de implementación

- Para hablar con PrestaShop el modal usa `THTTPBasicAuthenticator` con la API
  Key como usuario (sin password). La URL base la introduce el usuario y por
  ahora **no** se persiste; en una iteración posterior conviene leerla desde
  `inLibAppParam` (parámetros de aplicación).
- `PRC_PED_CREAR_ALBARAN_LINEA` recorta automáticamente la cantidad solicitada
  al máximo pendiente, así que aunque el usuario cargue una cifra superior nunca
  se sobre-entrega.
- El estado del pedido se actualiza solo a `PARCIAL` o `ENTREGADO` desde
  `PRC_PED_CREAR_ALBARAN_FIN` en función de las líneas pendientes.
- La nueva tabla `fza_albaranes` ya respeta el `LIBRO_DE_ESTILO_BBDD.md`
  (sufijo `ALB`, columnas auditoría con guion bajo). Las tablas legacy
  `fza_pedidos*` se mantienen con su nomenclatura actual para evitar que el
  cambio rompa el resto del código existente; cuando el normalizador se pase
  por la rama, las columnas se renombrarán en bloque.
