# Pedidos de Compra — primer hito

Mantenimiento de pedidos de compra: cabecera + lineas, sin facturacion,
sin generacion de movimientos de stock. Al grabar el pedido se anotan
cantidades en `fza_articulos_pdte_recibir` (compromiso futuro de
entrada). Cuando se pulsa **Crear albaran** se genera un albaran de
compra para un almacen elegido, se mueven los stocks y se descuenta la
cantidad recibida del pedido.

Modelado en espejo de `inMtoAlbaranesCompra` sustituyendo el flujo de
"cerrar para mover stock" por el flujo de "pedir / albaranear / mover".

---

## Esquema

Sufijos por tabla:

- `fza_pedidos_compra`        → `PEDC`
- `fza_pedidos_compra_lineas` → `PEDCLIN`

DDL idempotente en `pedidos_compra.sql`. Hace ademas:

1. `UPDATE fza_tipos_documentos` para que el codigo `'PC'` apunte a
   `fza_pedidos_compra` (antes apuntaba a `fza_pedidos_compras` plural,
   inexistente). Crea la entrada si no existia.
2. `INSERT` en `fza_winforms` para registrar la pantalla nueva
   (`CALL_WINF = 'PedidosCompra'`).
3. `CREATE OR REPLACE VIEW vi_pedidos_compra` con joins a
   `fza_proveedores` y `fza_empresas`.

La cabecera y lineas siguen las 4 columnas estandar de auditoria
(`INSTANTE_ALTA`, `INSTANTE_MODIF`, `USUARIO_ALTA`, `USUARIO_MODIF`),
sin sufijo, segun `LIBRO_DE_ESTILO_BBDD.md §3.7`.

### Diferencias respecto a albaranes_compra

- Estados de cabecera: `ABIERTO`, `PARCIAL`, `RECIBIDO`, `CANCELADO`.
  Se recalcula automaticamente al crear o anular albaranes desde el
  pedido (suma de CANTIDAD_RECIBIDA vs CANTIDAD).
- Cabecera trae `FECHA_PREVISTA_PEDC` (fecha estimada de recepcion).
- Lineas traen tres cantidades:
  - `CANTIDAD_PEDCLIN`          — lo que se pide al proveedor.
  - `CANTIDAD_RECIBIDA_PEDCLIN` — suma de cantidades albaraneadas.
  - Pendiente = `CANTIDAD - CANTIDAD_RECIBIDA` (calculo, no columna).
- `CODIGO_ALMACEN_PEDCLIN`: cada linea lleva su almacen. Un pedido
  puede agrupar lineas para varios almacenes; el boton **Crear albaran**
  elige uno y genera solo las lineas de ese almacen.
- Sin tabla de celdas en este hito. El pivote por tallas se anyadira
  en hito 2 (con la libreria `inLibGridTallasInline` que ya usa
  albaranes y sesiones).

---

## Pantalla

`src/Forms/inMtoPedidosCompra.pas` + `.dfm`. Hereda de `TfrmMtoGen`.
Estructura:

- `tsLista`: grid con cabeceras de pedidos filtrable.
- `tsFicha`:
  - Pestania **Cabecera**: numero / serie / fecha / fecha prevista /
    estado, empresa, proveedor, ref. proveedor, almacen destino por
    defecto.
  - Pestania **Lineas**: grid de `fza_pedidos_compra_lineas` con
    articulo, SKU, descripcion, cantidad pedida, cantidad recibida,
    pendiente, precio compra, IVA, total, almacen.
  - Pestania **Observaciones**: memo libre.
  - Panel inferior con totales (bases / impuestos / liquido,
    read-only).
- Panel derecho con botones:
  - **Crear albaran** — abre modal selector de almacen y genera
    albaran + movimientos + actualiza recibidos del pedido.
  - **Imprimir** / **Etiquetas** — pendientes (hito 3).

Numeracion automatica via `PRC_GET_CONTADOR_FACTURA` con
`ptipodoc = 'PC'`. Cabecera nace en estado `ABIERTO`.

`UniDataPedidosCompra` calcula totales en el `BeforePost` de cabecera
y tras cada `AfterPost` de linea. En `AfterPost` de cabecera dispara
`GenerarPdteRecibirDesdePedido` para sincronizar
`fza_articulos_pdte_recibir`. En `BeforeDelete` (cabecera o linea)
borra las filas correspondientes en `fza_articulos_pdte_recibir`.

---

## Flujo Crear Albaran

1. Usuario pulsa `btnCrearAlbaran` en la pestania Lineas.
2. Modal `TfrmModalSelAlmacenPedido` muestra todos los almacenes con
   cantidad pendiente > 0 en el pedido activo, con la pendiente
   agregada al lado del codigo. Usuario elige uno.
3. `inLibPedidosCompra.CrearAlbaranDesdePedido(pedido, almacen)`:
   - Genera `NUMERO_ALBC` con contador `'AB'`.
   - INSERT cabecera `fza_albaranes_compra` denormalizando
     proveedor / empresa del pedido. El estado nace `ABIERTO`.
   - Por cada linea del pedido con
     `CODIGO_ALMACEN_PEDCLIN = almacen` y `pendiente > 0`:
       - INSERT linea en `fza_albaranes_compra_lineas` con
         cantidad pendiente.
       - UPDATE `CANTIDAD_RECIBIDA_PEDCLIN += pendiente`.
   - Cambia el estado del albaran a `CERRADO` para que se disparen
     los movimientos via `inLibAlbaranesCompraMovimientos`. Esto
     entra el stock fisico en el almacen elegido.
   - Recalcula `ESTADO_PEDC` segun cuanto queda pendiente:
       - 0 = `RECIBIDO`
       - parcial = `PARCIAL`
       - todo = `ABIERTO`
   - DELETE / UPDATE de `fza_articulos_pdte_recibir` para drenar el
     compromiso pendiente.
4. UI: refresca el pedido en pantalla y muestra mensaje con el
   numero / serie del albaran generado.

Todo en una sola transaccion. Si algo falla, rollback completo
(el pedido se queda como estaba).

---

## Cableado del menu

`Compras → Pedidos` (objeto `Pedidos1` en `inMtoPrincipal.dfm`)
abre `PedidosCompra` via `ShowMto`. El registro en `fza_winforms`
asocia `MENUITEM_WINF = 'Pedidos1'` para que el sistema de perfiles
gestione su visibilidad.

Shortcut sugerido: `Ctrl+Alt+P` (Pedido). El menu padre ya tenia
`ShortCut = 24656` configurado (`Pedidos1` antes era un placeholder
sin handler).

---

## Pendiente / hitos siguientes

1. **Tallas en horizontal + fila extra recibidos**: el `btnTallasHorizontal`
   esta como TODO. Reutilizar `TGestorGridTallas` igual que albaranes /
   sesiones. La fila extra "Recibidos" en modo pivote sale solo
   cuando se pulsa `btnMostrarRecibidos`, oculta lineas totalmente
   recibidas y colorea filas:
       - **Amarillo**: nada recibido todavia (pendiente toda la linea)
       - **Verde**:    recibido parcial
       - **Azul**:     todo recibido
2. **Tabla de celdas `fza_pedidos_compra_celdas`**: igual que
   `fza_albaranes_compra_celdas`. Necesaria para que el pivote
   funcione con cantidades por talla.
3. **Imprimir / etiquetas**: copiar modales de albaranes adaptados.
4. **Recalculo automatico ESTADO_PEDC** ante reverso de albaran:
   si se reabre un albaran de compra creado desde un pedido, hay que
   restar la cantidad recibida del pedido y reinsertar la fila de
   `fza_articulos_pdte_recibir`. Hito 2.
5. **Snapshot proveedor/empresa al teclear**: copiar fiscal desde
   `fza_proveedores` / `fza_empresas` al hacer click en el button-edit.
   Igual que en albaranes (TODO compartido entre ambos).
6. **Facturacion de pedidos** (futuro): hoy se factura el albaran;
   facturar directamente el pedido queda fuera de scope.

---

## Tope automático del «A recibir» (junio 2026)

No se puede recibir más cantidad de la pedida. En cuanto el usuario
teclea un «A recibir» mayor que el pendiente (Pedido − Recibida), la
celda se ajusta sola al máximo y suena un beep:

- **Pivote expandido**: `TGridPivoteCompra.CapturarARecibirEditValueChanged`
  (inLibGridPivoteCompra) clampa contra el pendiente de la talla.
- **Modo vertical**: handler `ARecibirVerticalEditValueChanged`
  (inMtoPedidosCompra) clampa contra el pendiente de la línea.
- **Defensa en BBDD**: `CrearAlbaranDesdePedidoConCantidades` e
  `IncorporarAlbaranDesdePedidoConCantidades` (inLibPedidosCompra)
  recortan además cada celda al pendiente real de su línea leído de
  `fza_pedidos_compra_lineas`, repartiéndolo entre las celdas de la
  misma línea. Así nunca se crea un albarán con cantidad imposible
  aunque la UI no hubiera filtrado.
