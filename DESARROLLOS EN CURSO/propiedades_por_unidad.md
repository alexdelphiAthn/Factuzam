# Propiedades por unidad (artículo / color / SKU)

Estado: **Fase 1 aplicada (modelo de datos)**. Fases 2-4 pendientes.

## Objetivo

Que una propiedad de artículo pueda fijarse no solo a nivel artículo, sino
también a nivel **color** (sku parcial) y **SKU** completo. El motor de negocio
es la **temporada**: una misma prenda se repite cada año pero se compra en
temporada distinta, y el check de temporada debe vivir **a nivel color**, no a
nivel artículo. El informe, la consulta de stock y la estadística de venta
deben filtrar por esa temporada de color.

## Idea: es el mismo patrón que tarifas y fotos

`fza_articulos_tarifas` y `fza_articulos_fotos` ya resuelven esto con una
columna `CODIGO_UNIDAD_*`:

- `''` → registro del **artículo** (padre).
- código de SKU → registro **específico** de esa unidad.

Y la resolución coge la fila más específica que exista, cayendo al padre si no
hay (ver `inLibArticulosResolver.ResolverPrecio` y `vi_articulos_tarifas`).

Aquí se generaliza ese mismo mecanismo a **todas** las propiedades, con un
nivel intermedio de **color**:

```
CODIGO_UNIDAD_ARTPROP = ''                 -> ARTICULO (padre, = lo de hoy)
CODIGO_UNIDAD_ARTPROP = 'ART/COLOR'        -> COLOR  (sku parcial)
CODIGO_UNIDAD_ARTPROP = 'ART/COLOR/TALLA'  -> SKU    (completo)

resolución efectiva:  SKU completo  ->  COLOR  ->  ARTICULO ('')
```

El "color" es el prefijo del SKU hasta antes de la talla, igual que el fallback
de fotos (`BLUS-SEDA/BLANCO` para el SKU `BLUS-SEDA/BLANCO/L`).

## Cambios de esquema (Fase 1)

Script idempotente: `propiedades_por_unidad.sql`.

1. **`fza_articulos_propiedades`**
   - Nueva columna `CODIGO_UNIDAD_ARTPROP varchar(50) NOT NULL DEFAULT ''`.
   - PK ampliada a `(CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP)`.
   - Índice `IDX_ARTPROP_UNIDAD (CODIGO_UNIDAD_ARTPROP)`.
2. **`fza_propiedades`**
   - Nueva columna `NIVEL_PROP varchar(10) NOT NULL DEFAULT 'ARTICULO'`.
   - Declara hasta qué nivel admite desglose cada propiedad:
     `ARTICULO < COLOR < SKU`. `TEMPORADA` se actualiza a `COLOR`.
3. **`vi_articulos_propiedades_efectivas`** (nueva vista)
   - Por cada SKU activo y propiedad, devuelve el valor vigente y su `ORIGEN_PROP`
     (`SKU` / `COLOR` / `ARTICULO`), con el mismo `COALESCE` por especificidad
     que `vi_articulos_tarifas`.

### Por qué no es traumático

La columna entra con `DEFAULT ''`, así que **todas las filas actuales pasan a
ser "nivel artículo"** = exactamente el comportamiento de hoy. No hay migración
destructiva y la aplicación sigue funcionando sin tocar nada tras la Fase 1.

## Roadmap

- **Fase 1 — Modelo (BBDD).** Este script. *(hecho)*
- **Fase 2 — Edición (app).** En `inMtoArticulos` / `UniDataArticulos`, permitir
  asignar la temporada a nivel color/SKU, replicando el grid de tarifas-por-SKU
  y su modal (`inMtoModalAddPreciosTar`). La UI ofrece el desglose según
  `NIVEL_PROP`.
- **Fase 3 — Lectura.** Reapuntar a la temporada efectiva por color:
  - `inMtoStockConsulta` (consulta de stock).
  - `inMtoCajaOpe`, `inMtoInventarios` (búsquedas).
  - SP de informes `PRC_GET_BALANCE_ALMACEN_TALLAS`, `PRC_GET_MOV_VENTAS_ART`.
  Retrocompatible: sin datos de color, resuelve al valor de artículo.
- **Fase 4 — Propagación compras + pulido.** Las sesiones de compra (ya llevan
  `ID_PV_TEMPORADA_SES`) propagan a nivel color al materializar; revisión de
  otros lectores de temporada; documentación.

## Rollback

Al final del `.sql` (comentado). Revierte PK, índice, columnas y vista. Borrar
`CODIGO_UNIDAD_ARTPROP` pierde las propiedades fijadas a color/SKU.
