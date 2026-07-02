# Preferencia de tallas en horizontal (pedidos y albaranes de compra)

## Objetivo

Este script queda como compatibilidad historica, pero la regla actual es que
las altas nuevas de pedidos y albaranes de compra arranquen en vertical
(`ESPIVOTE_HORIZONTAL_* = 'N'`).

El usuario puede activar **Tallas en horizontal** cuando la linea en curso ya
tiene un articulo con sistema de tallas. Si alguna linea del documento no
tiene sistema de tallas, el Mto bloquea la activacion horizontal.

## Semantica del campo `ESPIVOTE_HORIZONTAL_*`

| Valor | Vista |
|-------|-------|
| `'N'` | vertical |
| `'S'` | horizontal, solo si todas las lineas tienen sistema de tallas |
| NULL / `''` | vertical en altas nuevas |

## Cambios

- `pedidos_albaranes_compra_pivote_default_horizontal.sql`
  - Deja el `DEFAULT` de `ESPIVOTE_HORIZONTAL_PEDC` y
    `ESPIVOTE_HORIZONTAL_ALBC` en `'N'`.
  - Normaliza valores vacios a `'N'`.
  - No cambia preferencias explicitas ya grabadas como `'S'` o `'N'`.

## Aplicacion

Aplicar despues de los scripts que crean las columnas:
`pedidos_compra.sql` y `albc_pivote_tarifa.sql`.

Para bases que ya hubieran recibido el default horizontal, aplicar tambien
`pivote_compras_default_vertical_alta.sql`.
