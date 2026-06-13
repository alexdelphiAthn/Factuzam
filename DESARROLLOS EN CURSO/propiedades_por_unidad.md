# Propiedades por unidad (artículo / color / SKU)

Estado: **Fases 1-4 aplicadas** (modelo, edición, lectura y propagación).
Funcionalidad completa; queda solo el extra opcional de la grilla de stock.

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
- **Fase 2 — Edición (app).** *(hecho)* En la pestaña Propiedades de
  `inMtoArticulos`, cada propiedad con `NIVEL_PROP` = `COLOR`/`SKU` muestra un
  botón **"Por color…"** que abre el modal `TfrmPropPorUnidad`: un combo (o
  texto/número/check según `TIPO_VALOR_PROP`) por cada color (`ART/COLOR`) o
  SKU del artículo, prefijado con lo ya fijado. Al aceptar, persiste en
  `fza_articulos_propiedades` con su `CODIGO_UNIDAD_ARTPROP` (upsert si hay
  valor, delete si se deja en blanco → hereda del nivel superior). Todo vive en
  `inLibArticulosPropiedades.pas`, construido en código (sin `.dfm`, sin tocar
  el form, el DataModule ni la versión). El editor de nivel artículo se ajustó
  para no duplicar filas tras la PK ampliada de Fase 1 (`CargarPropiedades` y el
  lookup `inLibArticulosAtributosLookup.ObtenerPropiedades` filtran
  `CODIGO_UNIDAD_ARTPROP = ''`).
  - El riesgo de **duplicado de filas** que esto abría (lectores que hacían
    `JOIN fza_articulos_propiedades` por `(artículo, 'TEMPORADA')` sin filtrar
    `CODIGO_UNIDAD_ARTPROP`) lo cierra la Fase 3.
- **Fase 3 — Lectura.** *(hecho)* La temporada de **artículo** y la de **color
  conviven**: la de color solo sobrescribe donde está fijada; si no, hereda la
  de artículo (mismo `COALESCE` por especificidad de
  `vi_articulos_propiedades_efectivas`). Ningún lector duplica filas.
  - **`PRC_GET_BALANCE_ALMACEN_TALLAS`** (balance por tallas, grano por color):
    la temporada se resuelve **por (artículo, color)** uniendo la vista efectiva
    a `tmp_bat_sku`. Cada color cae en su temporada efectiva (color, o artículo
    si el color no la fija) y la agrupación por temporada (`TMP`) reparte cada
    color en su bucket.
  - **`PRC_GET_MOV_VENTAS_ART`** (grano por artículo, sin desglose de color):
    muestra la temporada de **nivel artículo** (`CODIGO_UNIDAD_ARTPROP = ''`);
    el desglose por color vive en el balance de tallas.
  - **`inMtoStockConsulta`** (cabecera de propiedades) y las **búsquedas** de
    `inMtoStockConsulta` / `inMtoCajaOpe` / `inMtoInventarios`: filtran
    `CODIGO_UNIDAD_ARTPROP = ''` (temporada de artículo, sin duplicar): son
    listas/cabeceras por artículo, sin grano de color donde resolver.
  - **Filtro de temporada de los informes**: el `EXISTS` sobre
    `fza_articulos_propiedades` ya considera cualquier nivel; un artículo entra
    si **alguno** de sus niveles (artículo/color/SKU) casa la temporada pedida.
  Retrocompatible: sin datos de color todo resuelve al valor de artículo. Pumpa
  versión (toca forms reales).
- **Fase 4 — Propagación compras + pulido.** *(hecho)*
  - **Propagación al materializar** (`inLibComprasSesionesMaterializar`): al
    crear los SKUs de una sesión, cada **color** comprado recibe la temporada
    de cabecera (`ID_PV_TEMPORADA_SES`) en su propio `CODIGO_UNIDAD_ARTPROP`
    (= `ART/COLOR`, los dos primeros segmentos del SKU, idéntico a
    `SUBSTRING_INDEX(sku,'/',2)` de la vista efectiva). `INSERT IGNORE`: no
    pisa el color ya fijado en una sesión anterior y **convive** con la
    temporada de artículo (`InsertarTemporadaCabecera`, que se mantiene). Así,
    al re-comprar la misma prenda en otra temporada, los colores nuevos llevan
    la nueva y los viejos conservan la suya. El helper `PrefijoColorSku`
    calcula el prefijo igual que la vista (sin color → SKU `ART/TALLA` → se
    queda a nivel artículo).
  - **Revisión de otros lectores de temporada** (lo que la Fase 3 no cubrió):
    - **`vi_articulos`** (`vi_articulos_nombre_proveedor.sql`): su JOIN a
      `fza_articulos_propiedades` para `TEMPORADA_ART` **no** filtraba unidad y
      **duplicaba cada fila de artículo** (Mto de Artículos, `frmMtoArtFacSearch`)
      en cuanto hay temporadas de color. Ahora filtra `CODIGO_UNIDAD_ARTPROP =
      ''`. **Reaplicar el script** (es `CREATE OR REPLACE VIEW`). OJO: hay otros
      `.sql` que también redefinen `vi_articulos` (`vi_articulos_add_codigo_prv`,
      `desactivar_articulos_sin_stock`); si alguno de esos fuese el vigente,
      aplicarle el mismo filtro.
    - **`PRC_GET_BALANCE_ALMACEN_SIN_TALLAS`**: hermano del balance por tallas y
      también por color; reapuntado a la temporada efectiva por (artículo,
      color) vía `vi_articulos_propiedades_efectivas` + `tmp_bst_sku`.
    - **`inLibPedidosCompra`** (temporada al recibir albarán): ya escribía a
      nivel artículo (`ON DUPLICATE KEY` sobre la PK ampliada apunta a
      `(art,'TEMPORADA','')`); correcto, ajusta el **default** de artículo sin
      tocar los colores. Sin cambios.
    - Filtros de temporada de informes (`inMtoModalImpMultiFiltro`): listan los
      valores maestros de `fza_propiedades_valores`; sin duplicación. Sin cambios.
  - **Aviso de temporada por color en `inMtoStockConsulta`** *(hecho)*: la
    consulta de stock (Ctrl+U) lleva un **letrero** rojo bajo la cabecera que
    "canta" cuando alguno de los colores marcados tiene temporada propia (nivel
    COLOR) distinta a la del artículo: `«¡Ojo! Temporada distinta a la del
    artículo (Primavera-Verano 2026): NEGRO → Otoño-Invierno 2026»`. Se calcula
    al cargar el artículo (`CargarTemporadasColores`, comparando la temporada de
    color `SUBSTRING_INDEX(sku,'/',2)` con la de nivel artículo) y se recompone
    al marcar/desmarcar colores (`ActualizarLetreroTemporada`). Solo lectura, sin
    cambios de esquema.
  - **Pendiente opcional:** columna de temporada efectiva por color en la grilla
    de `inMtoStockConsulta` (hoy la cabecera muestra la de artículo; el letrero
    ya avisa de las diferencias).

## Rollback

Al final del `.sql` (comentado). Revierte PK, índice, columnas y vista. Borrar
`CODIGO_UNIDAD_ARTPROP` pierde las propiedades fijadas a color/SKU.
