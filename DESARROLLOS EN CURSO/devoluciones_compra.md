# Devoluciones a Proveedor (devoluciones de compra)

Documento de **devolución de mercancía al proveedor**. Es un espejo del
albarán de compra (`inMtoAlbaranesCompra` / `UniDataAlbaranesCompra` /
`inLibAlbaranesCompraMovimientos`) con **dos diferencias de fondo**:

1. **Mueve stock en negativo.** Las cantidades del documento van en
   **positivo** (igual que el albarán), pero al cerrarlo se generan
   movimientos de **SALIDA** (`TIPO_MOV='S'`), que el SP
   `PRC_FZA_AJUSTAR_ACUMULADO_STK` **resta** de `CANTIDAD_STK` y
   `VALOR_TOTAL_STK`. Es la mercancía que sale del almacén de vuelta al
   proveedor.
2. **Pantalla y permisos propios.** Es un Mto independiente
   (`CALL_WINF='DevolucionesCompra'`, menú `Compras → Devoluciones a
   Proveedor`), por lo que el árbol de permisos genera automáticamente
   `menu.DevolucionesCompra` y los 6 sub-permisos
   (`.consultar/.insertar/.modificar/.borrar/.excel/.imprimir`). Así se
   puede dar a un empleado el albarán de compra sin la devolución, o al
   revés.

---

## Códigos

- **Tipo de documento** (`fza_tipos_documentos`): `'DC'` →
  `fza_devoluciones_compra`. Lo usa la numeración automática
  (`PRC_GET_CONTADOR_FACTURA`, `ptipodoc='DC'`) y la serie por defecto.
- **Tipo de documento de movimiento** (`fza_movimientos_almacen`):
  `TIPO_DOC_MOV='DC'`, `TIPO_MOV='S'`.

No se añade acumulador de subtipo a `fza_articulos_stockactual`: la
salida se refleja solo en `CANTIDAD_STK` / `VALOR_TOTAL_STK` (ninguna
rama de `PRC_FZA_AJUSTAR_ACUMULADO_STK` casa con `'DC'`, así que el SP
compartido no se toca). Si más adelante se quiere desglose por subtipo en
informes, habría que añadir una columna `CANTIDAD_SAL_DEVCOMPRA_STK` y su
rama en el SP.

---

## Esquema

Sufijos: cabecera `DEVC`, líneas `DEVCLIN`, celdas `DEVCCEL`
(registrados en `LIBRO_DE_ESTILO_BBDD.md §2`).

- `fza_devoluciones_compra`        → `DEVC`
- `fza_devoluciones_compra_lineas` → `DEVCLIN`
- `fza_devoluciones_compra_celdas` → `DEVCCEL`

DDL idempotente consolidado en `devoluciones_compra.sql` (incluye las
columnas que el albarán tenía repartidas en scripts incrementales:
`ESPIVOTE_HORIZONTAL_DEVC`, `CODIGO_TAR_DEVC`, `REF_PRV_DEVCLIN`). El
script además:

1. Da de alta el tipo de documento `'DC'` (idempotente, `INSERT … WHERE
   NOT EXISTS`).
2. Registra la pantalla en `fza_winforms` (`CALL_WINF='DevolucionesCompra'`,
   `MENUITEM_WINF='Devoluciones1'`, atajo `Ctrl+Alt+D`).
3. Crea la vista `vi_devoluciones_compra` para `tsLista`.

Las vistas de impresión están en `vi_devoluciones_compra_print.sql`
(`vi_devoluciones_compra_cab_print`, `_lin_print`, `_guias_print`).

### Aplicar a una BBDD existente

```sql
SOURCE DESARROLLOS EN CURSO/devoluciones_compra.sql;
SOURCE DESARROLLOS EN CURSO/vi_devoluciones_compra_print.sql;
```

Idempotente: se puede relanzar sin efectos secundarios.

---

## Ficheros Delphi

- `src/Forms/inMtoDevolucionesCompra.pas` + `.dfm` — Mto (hereda
  `TfrmMtoGen`), con tallas en horizontal / atributo por columna, igual
  que el albarán.
- `src/DataModules/UniDataDevolucionesCompra.pas` + `.dfm` — data module.
  Detecta `ABIERTO → CERRADO` en `BeforePost` y en `AfterPost` genera
  (cerrar) o revierte (reabrir) los movimientos de salida.
- `src/Lib/inLibDevolucionesCompraMovimientos.pas` — generación y
  reversión de movimientos `TIPO_DOC_MOV='DC'`, `TIPO_MOV='S'`.
- `src/Modals/inMtoModalImpDevCompra(.pas/.dfm)` — impresión horizontal.
- `src/Modals/inMtoModalImpDevCompraV(.pas/.dfm)` — impresión vertical.
- `src/Modals/inMtoModalEtiqDev(.pas/.dfm)` — etiquetas.

El menú `Compras → Devoluciones a Proveedor` (objeto `Devoluciones1` en
`inMtoPrincipal`) abre `DevolucionesCompra` vía `ShowMto`.

---

## Pendiente / hitos siguientes

Hereda los mismos pendientes que el albarán (snapshot de proveedor /
empresa al grabar cabecera, facturación de la devolución, valores de
atributo por SKU en modo «atributo por columna», F3 sobre el conjunto
pivot). Específicos de devolución:

1. **Origen desde albarán/factura de compra**: hoy la devolución se pica
   a mano. Sería útil partir de las líneas de un albarán de compra ya
   recibido para no recapturar SKUs y precios.
2. **Acumulador de subtipo** `CANTIDAD_SAL_DEVCOMPRA_STK` si se quiere
   separar en informes la salida por devolución de las demás salidas.
