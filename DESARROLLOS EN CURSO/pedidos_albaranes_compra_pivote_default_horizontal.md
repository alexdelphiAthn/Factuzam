# Tallas en horizontal por defecto (pedidos y albaranes de compra)

## Objetivo

Que al abrir un **pedido de compra** o un **albarán de compra** la vista
de tallas arranque **en horizontal** (modo pivote) por defecto, en vez de
en vertical (una fila por SKU).

Se mantiene la función de "recordar por documento" que ya existía: si en
un documento concreto cambias a vertical y grabas, ese documento volverá a
abrir en vertical. Solo cambia el valor por defecto.

## Semántica del campo `ESPIVOTE_HORIZONTAL_*`

Antes: `'S'` = horizontal, cualquier otra cosa = vertical (default `'N'`).

Ahora:

| Valor          | Vista      | Significado                                   |
|----------------|------------|-----------------------------------------------|
| `'N'`          | vertical   | excepción explícita que el usuario guardó     |
| `'S'`/NULL/`''`| horizontal | valor por defecto                             |

La decisión la toma el Mto en `dsTablaGDataChangeHook`: el pivote se
activa salvo que el campo sea exactamente `'N'`.

## Cambios

### Código (Delphi)

- `src/Forms/inMtoPedidosCompra.pas`
- `src/Forms/inMtoAlbaranesCompra.pas`

En ambos:

1. `dsTablaGDataChangeHook`: la condición pasa de `= 'S'` a `<> 'N'`
   (horizontal por defecto).
2. `btnTallasHorizontalClick`: al auto-abrir (`Sender = nil`) un documento
   que **no es pivotable** (artículos sin sistema de tallas, sistemas con
   demasiadas tallas, etc.) ya **no** se muestra el `MessageDlg` de aviso;
   se deja la vista vertical en silencio. El aviso solo sale cuando el
   usuario pulsa el botón a mano (`Sender <> nil`).

### BBDD

- `pedidos_albaranes_compra_pivote_default_horizontal.sql`
  - Cambia el `DEFAULT` de `ESPIVOTE_HORIZONTAL_PEDC` y
    `ESPIVOTE_HORIZONTAL_ALBC` de `'N'` a `'S'`.
  - Backfill **de una sola ejecución**: pone a `'S'` los documentos ya
    existentes (que tenían `'N'` por el default antiguo) para que también
    abran en horizontal.

## Cómo aplicar

1. Desplegar el binario con los cambios de los dos `inMto*`.
2. Ejecutar el `.sql` sobre cada BBDD existente. Aplicar **después** de
   `pedidos_compra.sql` y `albc_pivote_tarifa.sql` (que crean las
   columnas).

> ⚠️ El backfill (apartados 1b y 2b del `.sql`) es de **una sola vez**. No
> volver a ejecutarlo tras haber marcado documentos como verticales a mano,
> o esas excepciones se perderían (volverían a `'S'`).

## Rollback

- Esquema: `ALTER TABLE ... ALTER COLUMN ... SET DEFAULT 'N'`.
- Datos: el backfill no guarda el valor previo; si se quisiera dejar todo
  en vertical, `UPDATE ... SET = 'N'`.
