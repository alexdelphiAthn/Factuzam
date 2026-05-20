# Optimizacion de `vi_articulos_tarifas`

## Sintoma

Al abrir el mantenimiento de Articulos (`TfrmMtoArticulos`), la sub-pestaña
**Tarifas** tarda ~2-6 segundos en mostrar datos para un articulo. La query
que dispara el cuello es:

```sql
SELECT * FROM vi_articulos_tarifas WHERE CODIGO_ART_ARTTAR = '01010002';
```

## Diagnostico

`EXPLAIN` revelo tres patrones costosos en la vista original:

1. **`DEPENDENT SUBQUERY` para `TIENE_SKU`** — un `EXISTS(...)` dentro del
   `SELECT` que se evalua una vez por fila resultado, escaneando 119 filas
   en `fza_articulos_skus` cada vez.

2. **`DEPENDENT SUBQUERY` para `NUM_ATRIBUTOS_REQ`** — peor todavia: un
   `JOIN` interno + `COUNT(DISTINCT ...)` por fila. Para 15 tarifas son
   15 × (119 + JOIN) lookups.

3. **CTE `sku_desc` materializado** — full scan de `fza_atributos_valores`
   (3.837 filas) + `Using temporary; Using filesort` para agrupar.

Y un detalle menor:

4. `COALESCE(FECHA_HASTA_ARTTAR, '9999-12-31') >= CURDATE()` no es
   *sargeable* (no aprovecha indice porque `COALESCE` envuelve la columna).

## Solucion

Script: [`vi_articulos_tarifas_optimizada.sql`](./vi_articulos_tarifas_optimizada.sql).

| Cambio | Antes | Despues |
|---|---|---|
| `TIENE_SKU` | `case when exists (...)` por fila | `LEFT JOIN (SELECT DISTINCT ...)` |
| `NUM_ATRIBUTOS_REQ` | `(SELECT COUNT(...) JOIN ...)` por fila | `LEFT JOIN (... GROUP BY)` agregado |
| `DESCRIPCION_SKU` | `WITH sku_desc AS (... GROUP BY ALL)` materializado | Subquery escalar con `WHERE` por unidad SKU (15 lookups con indice) |
| `FECHA_HASTA_ARTTAR` | `COALESCE(...,'9999-12-31') >= CURDATE()` no-sargeable | `IS NULL OR ... >= CURDATE()` sargeable |

Tambien se crean dos indices auxiliares idempotentes:

- `IDX_ARTTAR_VIGENCIA(ESACTIVO_ARTTAR, FECHA_HASTA_ARTTAR)` para el WHERE.
- `IDX_SA_UNIDAD(CODIGO_UNIDAD_SKU_SA)` para la subquery escalar.

## Aplicacion

El script es idempotente (CREATE OR REPLACE VIEW + CREATE INDEX IF NOT
EXISTS). Se puede ejecutar directamente en MariaDB:

```cmd
mysql -h 127.0.0.1 -P 3306 -u root -p herreras < "DESARROLLOS EN CURSO/vi_articulos_tarifas_optimizada.sql"
```

O abrirlo en HeidiSQL y pulsar F9.

## Verificacion

Tras aplicar:

```sql
EXPLAIN SELECT * FROM vi_articulos_tarifas WHERE CODIGO_ART_ARTTAR = '01010002';
```

Lo esperado:

- Cero filas con `select_type = DEPENDENT SUBQUERY`.
- El `DERIVED` del CTE `sku_desc` desaparece (en su lugar aparecen los
  derivados de `tiene_sku` y `num_atr`, pero materializados una sola vez).
- `rows` totales pasan de cientos de miles a miles.

Tiempo real:

```sql
ANALYZE FORMAT=JSON SELECT * FROM vi_articulos_tarifas
WHERE CODIGO_ART_ARTTAR = '01010002';
```

Objetivo: bajar de ~2-6 segundos a < 200 ms.

## Compatibilidad

La firma de la vista no cambia — mismas columnas con los mismos nombres.
El cliente Delphi (`TdmArticulos.unqryTarifasArticulos`) NO necesita
modificacion. Si el resultado funcional cambia por algun caso borde,
revertir es trivial: borrar la vista y volver a crearla con la version
original.
