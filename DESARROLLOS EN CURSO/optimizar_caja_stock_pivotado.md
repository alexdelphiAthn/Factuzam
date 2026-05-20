# Optimizar `PRC_GET_CAJA_STOCK_PIVOTADO` y `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`

## Problema

Tras instrumentar `inMtoCajaOpe.ConsultarStock` con cronómetros (`-- PERF --`),
medimos en sesión real:

```
[PERF:CajaOpe.ConsultarStock] art=01010021 | SP=627 | Build=0 | Fit=2 | cols=11 | total=636 ms
```

627 ms en el `CALL` al SP. Con `ANALYZE FORMAT=JSON` sobre la query final
construida por `PREPARE/EXECUTE` confirmamos que **la query pivotada
ejecuta en 0.33 ms reales** (`r_total_time_ms = 0.327800502`). Plan limpio,
filas evaluadas ~600, todos los joins con índice.

Los 626 ms restantes se consumían **antes** del `PREPARE`, en las 6
sub-queries de preparación dentro del SP:

1. Identificar artículo (`SELECT CODIGO_ART_ART FROM fza_articulos`).
2. Si NULL, identificar como SKU (`SELECT CODIGO_ART_SKU FROM fza_articulos_skus`).
3. Identificar atributo PIVOT (Talla): **4 JOINs** sobre
   `fza_articulos_skus → fza_atributos_sku → fza_atributos_valores → fza_variaciones_atributos`
   con `ORDER BY ORDEN_VA DESC LIMIT 1`.
4. Identificar atributo GRUPO/FILA (Color): **4 JOINs** idénticos.
5. (Sólo si era SKU) Identificar valor del grupo: 2 JOINs.
6. `GROUP_CONCAT` de columnas dinámicas (S, M, L, 42, 44…): 3 JOINs.

Cada sub-query dentro del SP no es solo "el tiempo de la query" — también
añade overhead de parser, planner y context switch. Con 6 sub-queries en
serie llegamos a ~600 ms aunque cada una en frío costara sólo 50-100 ms.

## Solución

Misma idea que aplicamos en `ActualizarColumnasDinamicas` (Delphi) que
bajó de **9663 ms → 14 ms**: los atributos que tiene un artículo están
definidos en `fza_variaciones_atributos` (vinculados al artículo via
`fza_articulos.TIPO_VARIACION_ART`, que ya tiene índice). No hace falta
recorrer SKUs para descubrirlos.

Cambios concretos:

- **1 + 2 combinadas** en un único `SELECT COALESCE(...) INTO v_codigo_articulo`.
  Detección "era SKU" via `v_codigo_articulo <> p_input`. Ahorro: 1
  round-trip cuando el input es un padre (el caso común).
- **3 reescrita**: PK seek `fza_articulos` + index seek
  `fza_variaciones_atributos` (2 nodos en el plan en lugar de 4). De 4
  JOINs a 1.
- **4 idem**.
- **5 sin cambios** (ya era 2 JOINs filtrados por PK del SKU, suficientemente
  rápida).
- **6 sin cambios** — necesita los AV REALES presentes en los SKUs del
  artículo (un artículo puede no usar todas las tallas posibles), así que
  el JOIN sobre SKUs es obligatorio. Ya filtra por `CODIGO_ART_SKU`
  (`IDX_SKU_ART_ACT`) y `ID_VA_AV` (`IDX_VAR_AV`).
- **Query final del `PREPARE` sin cambios** — el plan es óptimo.

## Estimación

- Antes: 627 ms.
- Después (estimado): 150 - 250 ms.

La reducción no llega a un orden de magnitud porque mantenemos el
`GROUP_CONCAT` y el `PREPARE/EXECUTE`. Esos dos juntos rondan los 100 ms
de techo en MariaDB para queries con muchas expresiones `CASE WHEN`.

## Aplicar

Script idempotente — re-ejecutable sin riesgo:

```bash
mysql -u root -p herreras < "DESARROLLOS EN CURSO/optimizar_caja_stock_pivotado.sql"
```

O desde un cliente SQL (HeidiSQL, DBeaver) abriendo el `.sql` y dándole a
"Run All".

El script usa `DROP PROCEDURE IF EXISTS` + `CREATE PROCEDURE`, así que
sobreescribir los SPs es seguro.

## Verificar

Lanzar Caja, escanear un artículo (por ejemplo `01010021`), y observar la
nueva línea `-- PERF --` en `oMemoSQL`:

```
[PERF:CajaOpe.ConsultarStock] art=01010021 | SP=<NUEVO_TIEMPO> | ...
[PERF:CajaOpe.Art2Popup] total Enter->popup=<NUEVO_TOTAL> ms
```

Si tras aplicar el script `SP=` sigue por encima de 300 ms, el cuello
estará en el `GROUP_CONCAT` o en el `PREPARE/EXECUTE` (que sólo se
resolverían reescribiendo el SP sin SQL dinámico — opción más invasiva,
queda para una siguiente iteración si hace falta).

## Compatibilidad

- Comportamiento idéntico al original: se conservan firmas, columnas
  devueltas, casos de fallback (artículo sin atributos), y el `LEFT JOIN`
  de almacenes con cero stock en la versión `_WITHZ`.
- Requiere `fza_articulos.TIPO_VARIACION_ART` poblado para los artículos
  con variación. Si la BBDD tiene artículos con `ESVARIACION_ART = 'S'`
  pero `TIPO_VARIACION_ART = NULL`, los SPs caerán al fallback
  (comportamiento conservador: no peta, simplemente devuelve sólo
  total por almacén).
- No requiere índices nuevos. Los necesarios ya existen
  (`IDX_SKU_ART_ACT`, `IDX_STK_UNIDAD`, `IDX_VAR_AV`, `IDX_SA_UNIDAD`,
  `TIPO_VARIACION_ART`).
- **No se toca `factuzam_original.sql`** (regla del proyecto). El script
  vive en `DESARROLLOS EN CURSO/` y se aplica por separado a las BBDD
  existentes.
