# Optimizar recalculo PMP en aplicar / eliminar regularizacion

Reescribe los procedimientos almacenados que recalculan el PMP (Precio Medio
Ponderado) tras aplicar o eliminar una regularizacion de inventario. Sustituye
el patron de **cursores anidados con UPDATE por movimiento** por una pasada
**set-based** sobre todos los SKUs afectados.

El dump de referencia `factuzam_original.sql` **no** se toca. La migracion
vive en `DESARROLLOS EN CURSO/optimizar_recalculo_pmp.sql` y se aplica por
el cauce habitual a la BBDD existente.

---

## Sintoma

Al eliminar una regularizacion desde `inMtoInventarios`, el SP en BBDD se
quedaba bloqueado varios segundos / minutos en regularizaciones medianas
(decenas de SKUs con miles de movimientos historicos por SKU). El cliente
Delphi solo lanza una llamada (`unspEliminarRegul.ExecProc` en
`UniDataInventarios.pas:884-890`), asi que el problema vivia integramente
dentro de MariaDB.

## Diagnostico

Tres procedimientos involucrados (`factuzam_original.sql`):

- `PRC_FZA_INVENTARIOS_ELIMINAR_REGUL` (linea 17216) abria un cursor sobre
  los SKUs afectados por la regularizacion y llamaba en bucle a...
- `PRC_FZA_INVENTARIOS_APLICAR` (linea 17051) hacia lo mismo: por cada linea
  del cursor llamaba a...
- `SP_RECALCULAR_PMP_SKU_ALMACEN` (linea 18897), que a su vez abria **otro
  cursor** sobre los movimientos historicos del SKU con `FOR UPDATE` y
  lanzaba un `UPDATE fza_movimientos_almacen SET PRECIO_MEDIO_MOV...` por
  cada movimiento (linea 18941) + un `INSERT...ON DUPLICATE KEY UPDATE` en
  stockactual al final.

Para una regularizacion que afecte a 50 SKUs con media de 200 movimientos
historicos por SKU:

| Fase                                  | Statements                  |
|---------------------------------------|----------------------------:|
| Cursor exterior (skus)                | 1 OPEN + 50 FETCH + 50 CALL |
| Cursor interior x 50 (`RECALC_PMP`)   | 50 x (1 OPEN + 200 FETCH + 200 UPDATE) |
| `INSERT...ON DUPLICATE` por SKU       | 50                          |
| **UPDATE uno-a-uno (total)**          | **~10.000**                 |

Cada `UPDATE` carga parse, plan, X-lock de fila y log. Los X-locks `FOR
UPDATE` se mantenian hasta el `COMMIT`, bloqueando lecturas concurrentes
sobre `fza_movimientos_almacen` durante toda la operacion.

## Solucion

Reescribir los tres SPs en `DESARROLLOS EN CURSO/optimizar_recalculo_pmp.sql`:

1. **`SP_RECALCULAR_PMP_LOTE_ALMACEN(p_EMPRESA, p_ALMACEN)`** -- nuevo.
   Recalcula PMP y stockactual de todos los SKUs registrados en una tabla
   temporal `tmp_skus_recalc` que el llamante prepara.
2. **`SP_RECALCULAR_PMP_SKU_ALMACEN`** -- se conserva con la misma firma
   como wrapper que crea una temp de un solo SKU y llama al lote.
3. **`PRC_FZA_INVENTARIOS_ELIMINAR_REGUL`** -- recolecta los SKUs en
   `tmp_skus_recalc`, borra los movimientos del inventario en un solo
   `DELETE`, y llama una unica vez al lote.
4. **`PRC_FZA_INVENTARIOS_APLICAR`** -- conserva el cursor sobre lineas
   para generar los movimientos S/E (es lineal en numero de lineas, no
   de movimientos historicos), va anotando SKUs tocados en
   `tmp_skus_recalc`, y al cerrar el cursor llama una unica vez al lote.

El cuerpo de `SP_RECALCULAR_PMP_LOTE_ALMACEN` son **cinco bloques**:

1. `CREATE TEMPORARY tmp_movs_ord` con `RN BIGINT AUTO_INCREMENT PRIMARY KEY`
   y volcado con `INSERT...SELECT...ORDER BY CODIGO_UNIDAD_MOV, FECHA_MOV,
   INSTANTE_ALTA`. La PK clustered en InnoDB garantiza que el RN refleja el
   orden secuencial de proceso.
2. `UPDATE tmp_movs_ord SET PMP_NUEVO = ..., COSTE_NUEVO = ..., STOCK_NUEVO
   = ..., SKU_PREV = ... ORDER BY RN`, usando variables de sesion
   (`@sku_prev`, `@stock`, `@pmp`) que se resetean al detectar cambio de
   SKU. Las asignaciones del `SET` se evaluan de izquierda a derecha en
   MariaDB, asi que el orden es: PMP (lee `@stock`/`@pmp` viejos y compara
   con `@sku_prev` viejo) -> COSTE (lee `@pmp` recien actualizado) ->
   STOCK (actualiza `@stock`) -> SKU_PREV (actualiza `@sku_prev`).
3. `UPDATE fza_movimientos_almacen JOIN tmp_movs_ord` para volcar
   `PRECIO_MEDIO_MOV` y `TOTAL_COSTE_MOV` en bloque.
4. Agregacion de acumulados por subtipo desde `tmp_movs_ord`:
   compras, traspasos (`TR/AT/TA`), ventas, regularizaciones y albaranes.
5. `INSERT...ON DUPLICATE KEY UPDATE` en `fza_articulos_stockactual` con
   el ultimo movimiento de cada SKU (`MAX(RN)` por `CODIGO_UNIDAD_MOV`).
   Un segundo `INSERT...ON DUPLICATE` cubre los SKUs cuyos movs se borraron
   por completo (stock final a 0).

## Comportamiento funcional

Identico al original, palabra por palabra:

- Formula PMP: entrada con `stock<=0` => `pmp = coste`; entrada con
  `stock>0` => media ponderada con la formula clasica
  `((stock*pmp) + (cant*coste)) / (stock+cant)`; salida no toca el `pmp`.
- `TOTAL_COSTE_MOV`: `cant*coste` en entradas, `cant*pmp` en salidas.
- `fza_articulos_stockactual` con `CANTIDAD_STK`, `VALOR_TOTAL_STK`,
  `PRECIO_MEDIO_STK` y acumulados por subtipo finales por SKU.

## Mejoras

| Aspecto                                  | Antes               | Despues |
|------------------------------------------|---------------------|---------|
| Statements por SKU                       | O(movs historicos)  | O(1) compartido entre todos |
| Total statements (50 SKUs x 200 movs)    | ~10.000             | 5 bloques |
| Cursores                                 | 2 anidados          | 0 (en el recalculo) |
| X-locks `FOR UPDATE` por movimiento      | Si                  | No (UPDATE en rango) |
| Redundancia en `APLICAR` (mismo SKU en N lineas) | N recalculos completos | 1 recalculo |

## Bugs heredados corregidos al paso

`PRC_FZA_INVENTARIOS_APLICAR` declaraba `v_LINEA VARCHAR(4)`, pero la
columna `fza_inventarios_lineas.LINEA_INVLIN` ya es `VARCHAR(8)` (formato
`00000001`...) tras una ampliacion previa. El FETCH del cursor explotaba
con `#22001 Data too long for column 'v_LINEA'` en cuanto el contador de
linea pasaba de `9999`. La reescritura declara `v_LINEA VARCHAR(8)` para
casar con la columna real.

El lote inicializaba `@stock` y `@pmp` con `0`, quedando tipadas como
enteros en MariaDB dentro del `UPDATE`. Con PMP fraccionario seguido de
otra entrada, la variable arrastraba redondeo. Ahora se inicializan con
`CAST(0 AS DECIMAL(19,6))`.

El recálculo solo actualizaba cantidad/PMP/valor de `stockactual`. Ahora
también reconstruye los acumulados `CANTIDAD_*_STK` desde movimientos
activos, por lo que una anulación seguida de recálculo restaura también
`CANTIDAD_SAL_VENTA_STK`.

Nota: `fza_movimientos_almacen.LINEA_MOV` sigue declarado `VARCHAR(4)`
(linea 5942 de `factuzam_original.sql`), y `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`
inserta `p_LINEA_MOV` directamente. Con valores de linea > 4 caracteres el
INSERT truncara (`sql_mode` permisivo) o fallara (`sql_mode` estricto).
Resolver eso queda fuera del alcance de esta migracion: implicaria
ampliar `LINEA_MOV` y revisar todos los `CONCAT('IV-', NRO, '-', LINEA,
'S'/'E')` cuyo `LEFT(..., 20)` podria colisionar PKs si `NRO` y `LINEA`
son largos.

## Idempotencia y rollback

- Idempotente: solo recrea procedimientos con `DROP PROCEDURE IF EXISTS` +
  `CREATE PROCEDURE`. No cambia esquema.
- Rollback: re-ejecutar los `CREATE PROCEDURE` del bloque correspondiente
  de `factuzam_original.sql` (lineas 17048-17312 para los dos PRC_FZA_*
  y 18894-18968 para el SP_RECALCULAR_*).
- `Delphi` no necesita cambios: la firma de los SPs llamados desde
  `UniDataInventarios.pas` es identica.

## Aplicacion

```sh
mysql -u <usuario> -p <basedatos> < "DESARROLLOS EN CURSO/optimizar_recalculo_pmp.sql"
```

Sin downtime relevante: los `CREATE PROCEDURE` toman lock corto en el
catalogo. Mientras no haya una regularizacion en curso, la operacion es
instantanea.
