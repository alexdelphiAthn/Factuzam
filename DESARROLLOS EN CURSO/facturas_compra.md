# Facturas de Compra — agrupación de albaranes (hito 1: BBDD)

Materializa la **factura de compra** (factura de proveedor) como destino de
la **agrupación de albaranes de compra**. Es el eslabón que faltaba en la
cadena de compras:

```
sesión de compra → pedido de compra → albarán de compra → FACTURA DE COMPRA
                                                              → efectos → remesas
```

Solo esquema de BBDD (script idempotente). Los formularios Delphi (`inMto*`
/ `UniData*`) y los informes quedan como hito siguiente (ver abajo).

---

## Por qué ahora

`fza_albaranes_compra` y `fza_devoluciones_compra` ya traían
`NUMERO_FAC_*` / `SERIE_FAC_*` comentadas como *"FK lógica a
fza_facturas_compras"* (plural) apuntando a una tabla que **nunca se creó**.
`ESTADO_ALBC` ya contempla el valor `FACTURADO`. Este script cierra ese
hueco creando la tabla en **singular** (`fza_facturas_compra`), igual que el
resto de documentos de compra (`fza_pedidos_compra`, `fza_albaranes_compra`,
`fza_devoluciones_compra`).

El modelo se inspira en el legacy `ocfacpro` (ver
`DESARROLLOS EN CURSO/migracion/dbo.ocfacpro.Table.sql`): documento externo
del proveedor, descuentos (comercial, pronto pago, rappel), retención,
financiación, portes y datos de domiciliación bancaria para generar los
efectos.

---

## Esquema (`facturas_compra.sql`)

Sufijos (registrados en `LIBRO_DE_ESTILO_BBDD.md §2` y en
`UNormalizerEngine.pas / InitDefaults`):

- `fza_facturas_compra`        → `FACC`    (cabecera)
- `fza_facturas_compra_lineas` → `FACCLIN` (líneas, snapshot de albarán)

Cabecera: empresa receptora y proveedor **denormalizados** (snapshot, igual
que ventas), bandas de IVA **N/R/S/E** (sin RE en compra, según la migración
de compras), descuentos/retención/portes, totales
(`TOTAL_BASES_FACC`, `TOTAL_IMPUESTOS_FACC`, `TOTAL_FACC`,
`TOTAL_LIQUIDO_FACC`), forma de pago, domiciliación (entidad/oficina/DC/
cuenta/IBAN) e `INSTANTE_CONTABILIZACION_FACC` para el control contable.
Las líneas son **espejo de `fza_albaranes_compra_lineas`** (proveedor +
precio de compra) más la procedencia `NUMERO_ALBC_FACCLIN` /
`SERIE_ALBC_FACCLIN` / `LINEA_ALBC_FACCLIN`.

Numeración: tipo de documento **`'FP'`** ("FACTURA DE COMPRAS"), que ya
existía en `fza_tipos_documentos` apuntando al nombre plural inexistente. El
script lo **realinea** a `fza_facturas_compra` y provisiona su contador
(`SERIE_CON='-'`, `DEFAULT_CON='S'`) para `PRC_FNC_GET_NEXT_NRO_DOC`, igual
que hizo `pedidos_compra.sql` con `'PC'`.

Vista `vi_facturas_compra`: cabecera + nombre de proveedor + razón social de
empresa (lectura para el grid de lista).

---

## Agrupación de albaranes → factura

`PRC_FACC_FACTURAR_ALBARAN(pSerieAlb, pNumAlb, pSerieFac, pNumFac, pUsuario,
OUT pSerieFacOut, OUT pNumFacOut, OUT pResultado)`:

- Si `pNumFac` viene **vacío/NULL** → crea una factura nueva numerada con el
  contador `'FP'`, copiando el snapshot de empresa/proveedor del albarán.
- Si viene **informada** → añade a esa factura, validando que sea el **mismo
  proveedor y empresa** (no se pueden mezclar proveedores).
- Copia las líneas del albarán a `fza_facturas_compra_lineas` continuando el
  contador de líneas (de 10 en 10), marca el albarán `ESTADO_ALBC='FACTURADO'`
  (+ `NUMERO_FAC_ALBC`/`SERIE_FAC_ALBC` y, a nivel de línea,
  `ESFACTURADA_ALBCLIN='S'`) y recalcula los totales.

**Agrupar N albaranes en 1 factura** = llamar al SP una vez por cada albarán
seleccionado pasando la **misma** factura destino (la 1ª llamada la crea, las
siguientes acumulan). `pResultado`: 1 ok, 0 nada que hacer (albarán
inexistente / ya facturado / cabecera incompatible), -1 error.

`PRC_FACC_RECALCULAR_TOTALES(pSerie, pNumero)`: reagrega las líneas en bandas
de IVA (criterio `<=0` Exento, `<6` Super, `<13` Reducido, resto Normal) y
recalcula bases, impuestos, total, retención y líquido.

---

## Pendiente / hitos siguientes

1. **Mto `inMtoFacturasCompra` + `UniDataFacturasCompra`** (hereda de
   `TfrmMtoGen`): pestañas Cabecera / Líneas / Observaciones, panel de
   totales read-only. Registrar entonces el `fza_winforms`
   (`CALL_WINF='FacturasCompra'`) — **no** se registra aquí porque la unit
   aún no existe.
2. **Modal "Facturar albaranes"**: selector de albaranes `CERRADO` de un
   proveedor + botón que itera `PRC_FACC_FACTURAR_ALBARAN`.
3. **Informe** de factura de compra (FastReport) y vista de impresión
   `vi_facturas_compra_print` (espejo de `vi_albaranes_compra_print`).
4. **Generación de efectos** al cerrar la factura → ver
   `efectos_remesas_compra.md` (`PRC_EFEC_GENERAR_DESDE_FACTURA`).
5. **Asiento/contabilización**: `INSTANTE_CONTABILIZACION_FACC` está previsto
   pero el volcado contable es otro hito.

---

## Notas de ejecución

- **Idempotente**: comprueba `INFORMATION_SCHEMA` antes de cada DDL; se puede
  reejecutar sin error. Las SP usan `DROP ... IF EXISTS`.
- Requiere un **cliente que entienda `DELIMITER`** (mysql CLI, HeidiSQL,
  DBeaver), porque define stored procedures, igual que el propio
  `factuzam_original.sql`.
- Las stored procedures **no se han podido probar contra una BBDD viva** en
  esta entrega: revisar con datos reales antes de cablear el Mto.
- **No** toca `factuzam_original.sql` (regla dura del repo).
