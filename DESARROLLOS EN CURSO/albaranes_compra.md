# Albaranes de Compra — primer hito

Mantenimiento de albaranes de compra: cabecera + lineas, sin facturacion
ni generacion automatica de movimientos de stock en este primer paso.
Modelado en espejo de `inMtoAlbaranes` (venta) sustituyendo
**CLIENTE → PROVEEDOR** y **PRECIO_VENTA → PRECIO_COMPRA**.

---

## Esquema

Sufijos por tabla (registrados en compras_sesiones.md §3.1):

- `fza_albaranes_compra`        → `ALBC`
- `fza_albaranes_compra_lineas` → `ALBCLIN`

DDL idempotente en `albaranes_compra.sql`. Hace ademas:

1. `UPDATE fza_tipos_documentos` para que el codigo `'AB'` apunte a
   `fza_albaranes_compra` (antes apuntaba a `fza_albaranes_compras`,
   plural, que no existia).
2. `INSERT` en `fza_winforms` para registrar la pantalla nueva
   (`CALL_WINF = 'AlbaranesCompra'`).
3. `CREATE OR REPLACE VIEW vi_albaranes_compra` con joins a
   `fza_proveedores` y `fza_empresas`.

Las cabecera y lineas siguen las 4 columnas estandar de auditoria
(`INSTANTE_ALTA`, `INSTANTE_MODIF`, `USUARIO_ALTA`, `USUARIO_MODIF`),
sin sufijo, segun `LIBRO_DE_ESTILO_BBDD.md §3.7`.

---

## Pantalla

`src/Forms/inMtoAlbaranesCompra.pas` + `.dfm`. Hereda de `TfrmMtoGen`
igual que el resto de los Mtos. Estructura:

- `tsLista`: grid con cabeceras de albaranes filtrable.
- `tsFicha`:
  - Pestania **Cabecera**: numero / serie / fecha / estado, empresa,
    proveedor, ref. proveedor, almacen destino.
  - Pestania **Lineas**: grid de `fza_albaranes_compra_lineas` con
    articulo, SKU, descripcion, cantidad, precio compra, IVA, total,
    almacen.
  - Pestania **Observaciones**: memo libre.
  - Panel inferior con totales (bases / impuestos / liquido,
    read-only).

`UniDataAlbaranesCompra` calcula totales en el `BeforePost` de
cabecera y tras cada `AfterPost` de linea, igual que en venta.
Numeracion automatica via `PRC_GET_CONTADOR_FACTURA` con
`ptipodoc = 'AB'`.

---

## Cableado del menu

`Compras → Albaranes` (objeto `Albaranes1` en `inMtoPrincipal.dfm`)
abre `AlbaranesCompra` via `ShowMto`. El registro en `fza_winforms`
asocia `MENUITEM_WINF = 'Albaranes1'` para que el sistema de perfiles
gestione su visibilidad.

Shortcut sugerido: `Ctrl+Alt+C` (Compra). Se puede cambiar editando
el `SHORTCUT_WINF` en la BBDD.

---

## Pendiente / hitos siguientes

1. **Snapshot de proveedor y empresa al grabar cabecera**: copiar
   datos fiscales de `fza_proveedores` y `fza_empresas` a las
   columnas denormalizadas del albaran (similar a
   `CopiarClienteaAlbaran` / `CopiarEmpresaaAlbaran` del Mto de venta).
   Requiere `OnButtonClick` en los `cxDBButtonEdit` de empresa y
   proveedor.

2. **Generacion automatica de movimientos de entrada** al grabar
   cabecera: llamar a `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT` con
   `TIPO_DOC_REF_MOV = 'AB'` por cada linea con SKU. Patron en
   `UniDataAlbaranes.GenerarMovimientosSalida` (venta usa `'AV'`).

3. **Tabla `fza_pedidos_compra` + Mto** y enlace `albaran ←
   pedido_origen`. Hoy `NUMERO_PED_ALBC` / `SERIE_PED_ALBC` se
   pueden teclear pero no se valida FK.

4. **Facturacion de albaranes de compra** (modal seleccion lineas,
   `fza_facturas_compras` destino, procs analogos a
   `PRC_ALB_CREAR_FACTURA_*`).

5. **Mantenimiento comun para sesiones / pedidos / albaranes de
   compra**: la idea original era un solo Mto con selector de tipo
   de documento. Esta version mantiene el Mto separado siguiendo el
   patron existente; si se quiere unificar mas adelante hay tres
   caminos:

   a. **Refactor a base + descendientes**: similar a
      `inMtoFacturasBase` / `inMtoFacturasNormal` /
      `inMtoFacturasSimplif`. Una base con cabecera+lineas comunes y
      descendientes que solo cambian filtro y SQL de origen.

   b. **Tabla unica `fza_compras_docs` con TIPO_DOC**: sesion, pedido
      y albaran en una sola tabla con columna discriminadora; un solo
      Mto que se comporta distinto segun el tipo. Mas invasivo en
      BBDD.

   c. **Vista union + acciones por tipo**: dejar las tres tablas
      separadas pero exponer una `vi_compras_docs` que las une para
      visualizacion conjunta, y un Mto "centralita" que enruta a la
      pantalla concreta. Util si los flujos de edicion son
      suficientemente distintos.
