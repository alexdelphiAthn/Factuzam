# Pestaña 8_Stock del artículo: consulta limpia (sin ceros, sin sumatorios)

## Qué se pedía

La consulta de stock de la pestaña **8_Stock** del mantenimiento de
artículos (`inMtoArticulos`) se veía cargada: pintaba todos los almacenes
aunque estuvieran a cero y, por cada almacén con stock, una fila extra de
color `-` que era el sumatorio del almacén. Se quería **más limpia, sólo lo
que hay en el stock, sin ceros y sin filas de sumatorio** — como la que sale
en la caja.

## Diagnóstico

La pestaña usa el SP `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`, que es el **único**
sitio del proyecto que lo usa (la caja y el traspaso usan
`PRC_GET_CAJA_STOCK_PIVOTADO`). El `_WITHZ` ("with zeros") tenía dos fuentes
de ruido:

1. **Ceros.** La query final arrancaba `FROM fza_almacenes alm LEFT JOIN
   (stock)`, así que listaba todos los almacenes activos aunque no tuvieran
   ni una unidad del artículo.

2. **Filas de sumatorio `-`.** El desglose por color hacía
   `LEFT JOIN fza_atributos_sku ask_fila`, que reengancha **todos** los
   atributos del SKU (también la talla). La fila de la talla no casa con el
   atributo color → `av_fila` quedaba `NULL` → `COALESCE(..., '-')`.
   Resultado: por cada almacén con stock aparecía una fila `-` con una
   cantidad igual a la **suma** de las filas de color reales (un duplicado
   del stock agrupado bajo color `NULL`). En la caja no se ve porque allí se
   escanea un SKU concreto y la query filtra por su color, descartando la
   fila `NULL`; en la ficha del artículo se entra por el código padre, así
   que salían todas.

## Cambio

`DESARROLLOS EN CURSO/articulos_stock_sin_ceros.sql` redefine
`PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ` (idempotente, `DROP IF EXISTS` +
`CREATE`):

- **Sin ceros**: la query final arranca `FROM` la subconsulta de stock
  (`src`) y hace `JOIN fza_almacenes`. Sólo aparecen almacenes con stock
  real. Si el artículo no tiene stock, la rejilla queda vacía (correcto:
  "sólo lo que hay en el stock"). El fallback de artículo simple hace lo
  mismo: arranca `FROM fza_articulos_stockactual`.
- **Sin sumatorios**: el desglose por color pasa de `LEFT JOIN` a `JOIN`.
  La fila fantasma de color `NULL` (`-`) desaparece y cada unidad de stock
  se cuenta una sola vez bajo su color real.
- Se conservan las optimizaciones de perf de
  `optimizar_caja_stock_pivotado.sql` (identificación por `COALESCE` y
  atributos vía `TIPO_VARIACION_ART`). El script es autosuficiente: deja el
  SP en su estado final correcto se haya aplicado o no el de optimización.

Además, en `src/Forms/inMtoArticulos.dfm` se ha quitado el footer de
sumatorio de la rejilla `tvStock` (`DataController.Summary.FooterSummaryItems`
+ `OptionsView.Footer`), que además arrastraba un item formateado en euros
copiado de otra rejilla. La pestaña no cambia de columnas: sigue siendo
`Almacén | Color | tallas | Total` con su cuadradito de color, sólo que
limpia.

## Por qué no se reutiliza directamente el SP de la caja

`PRC_GET_CAJA_STOCK_PIVOTADO` devuelve una columna `Codigo`
(`ARTÍCULO/COLOR`) en vez de columnas separadas `Almacén` + `Color`, y la
ficha del artículo pinta el cuadradito de color sobre la columna cuyo nombre
coincide con el atributo (`Color`). Apuntar la pestaña a ese SP perdería la
columna de color y su swatch. Por eso se mantiene el `_WITHZ` con su layout
y sólo se limpia el contenido.

## Supuesto de modelo de datos

Una variación de 2 atributos (color × talla) genera SKUs que **siempre**
llevan ambos valores, así que el `JOIN` al color no esconde stock real: sólo
elimina el duplicado. Si en alguna BBDD existieran SKUs de un artículo con
atributo color que no tengan valor de color asignado, ese stock dejaría de
verse (antes salía bajo `-`). No se ha detectado ese caso.

## Aplicar

```bash
mysql -u root -p herreras < "DESARROLLOS EN CURSO/articulos_stock_sin_ceros.sql"
```

## Verificar

Abrir un artículo con stock en varios almacenes/colores (p. ej. `01010021`),
ir a la pestaña **8_Stock** y comprobar:

- No aparecen almacenes sin stock del artículo.
- No aparece ninguna fila con color `-`.
- La suma de las filas de color de un almacén coincide con la que antes
  mostraba su fila `-`.
- No hay fila de footer con totales al pie de la rejilla.
