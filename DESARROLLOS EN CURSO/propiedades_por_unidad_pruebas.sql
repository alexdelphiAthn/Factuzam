-- ============================================================================
-- propiedades_por_unidad_pruebas.sql
--
-- Bateria de verificacion de la feature "propiedades/temporada por unidad"
-- (Fases 1-4) contra la BBDD factuzam (MariaDB).
--
-- NO DESTRUCTIVA: las pruebas que insertan datos van dentro de una
-- transaccion que termina en ROLLBACK; no persiste nada. Las comprobaciones
-- de esquema y las llamadas a SP son de solo lectura.
--
-- Uso:  mysql factuzam < propiedades_por_unidad_pruebas.sql
--   (o pegar por secciones en tu cliente). Requiere Fases 1-4 aplicadas;
--   varias pruebas sirven justo para verificar que el despliegue esta hecho.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECCION 0. Fixtures: elige automaticamente un articulo de prueba con >= 2
-- colores y tallas (SKU tipo ART/COLOR/TALLA) y dos valores de temporada.
-- Si @art sale NULL, fijalo a mano: SET @art := 'TU_CODIGO_ART';
-- ----------------------------------------------------------------------------
SET @art := (
  SELECT s.CODIGO_ART_SKU
    FROM fza_articulos_skus s
   WHERE s.ESACTIVO_SKU = 'S'
     AND s.CODIGO_UNIDAD_SKU LIKE '%/%/%'
   GROUP BY s.CODIGO_ART_SKU
  HAVING COUNT(DISTINCT SUBSTRING_INDEX(s.CODIGO_UNIDAD_SKU, '/', 2)) >= 2
   LIMIT 1);
SET @color1 := (
  SELECT SUBSTRING_INDEX(s.CODIGO_UNIDAD_SKU, '/', 2)
    FROM fza_articulos_skus s
   WHERE s.CODIGO_ART_SKU = @art
     AND s.ESACTIVO_SKU = 'S'
     AND s.CODIGO_UNIDAD_SKU LIKE '%/%/%'
   ORDER BY s.CODIGO_UNIDAD_SKU
   LIMIT 1);
SET @sku1 := (
  SELECT s.CODIGO_UNIDAD_SKU
    FROM fza_articulos_skus s
   WHERE s.CODIGO_ART_SKU = @art
     AND s.ESACTIVO_SKU = 'S'
     AND s.CODIGO_UNIDAD_SKU LIKE CONCAT(@color1, '/%')
   ORDER BY s.CODIGO_UNIDAD_SKU
   LIMIT 1);
SET @pv1 := (SELECT ID_PV_ARTPROP FROM fza_propiedades_valores
              WHERE ID_PROP_PV = 'TEMPORADA' ORDER BY ID_PV_ARTPROP LIMIT 1);
SET @pv2 := (SELECT ID_PV_ARTPROP FROM fza_propiedades_valores
              WHERE ID_PROP_PV = 'TEMPORADA' ORDER BY ID_PV_ARTPROP
              LIMIT 1 OFFSET 1);
SELECT @art AS articulo_prueba, @color1 AS color_prueba, @sku1 AS sku_prueba,
       @pv1 AS temporada_art, @pv2 AS temporada_color,
       IF(@art IS NULL OR @color1 IS NULL OR @pv1 IS NULL OR @pv2 IS NULL,
          'FALTAN FIXTURES: fija @art/@pv a mano', 'OK fixtures') AS estado;

-- ----------------------------------------------------------------------------
-- SECCION 1. Esquema (Fase 1). Cada fila devuelve PASS/FAIL.
-- ----------------------------------------------------------------------------
SELECT 'col CODIGO_UNIDAD_ARTPROP' AS prueba,
       IF(COUNT(*) = 1, 'PASS', 'FAIL') AS resultado
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fza_articulos_propiedades'
   AND COLUMN_NAME = 'CODIGO_UNIDAD_ARTPROP'
UNION ALL
SELECT 'PK incluye CODIGO_UNIDAD_ARTPROP',
       IF(COUNT(*) = 1, 'PASS', 'FAIL')
  FROM INFORMATION_SCHEMA.STATISTICS
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fza_articulos_propiedades'
   AND INDEX_NAME = 'PRIMARY' AND COLUMN_NAME = 'CODIGO_UNIDAD_ARTPROP'
UNION ALL
SELECT 'indice IDX_ARTPROP_UNIDAD',
       IF(COUNT(*) >= 1, 'PASS', 'FAIL')
  FROM INFORMATION_SCHEMA.STATISTICS
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fza_articulos_propiedades'
   AND INDEX_NAME = 'IDX_ARTPROP_UNIDAD'
UNION ALL
SELECT 'col NIVEL_PROP en fza_propiedades',
       IF(COUNT(*) = 1, 'PASS', 'FAIL')
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fza_propiedades'
   AND COLUMN_NAME = 'NIVEL_PROP'
UNION ALL
SELECT 'TEMPORADA con NIVEL_PROP = COLOR',
       IF(COUNT(*) = 1, 'PASS', 'FAIL')
  FROM fza_propiedades
 WHERE CODIGO_PROP_ARTPROP = 'TEMPORADA' AND NIVEL_PROP = 'COLOR'
UNION ALL
SELECT 'vista vi_articulos_propiedades_efectivas',
       IF(COUNT(*) = 1, 'PASS', 'FAIL')
  FROM INFORMATION_SCHEMA.VIEWS
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'vi_articulos_propiedades_efectivas';

-- ----------------------------------------------------------------------------
-- SECCION 2. Resolucion efectiva SKU -> COLOR -> ARTICULO (Fase 1/3) y
-- no-duplicacion (Fase 3/4). Inyecta datos de prueba y hace ROLLBACK.
--   articulo ''        -> @pv1
--   color @color1      -> @pv2  (sobrescribe a los SKU de ese color)
--   sku  @sku1         -> @pv1  (vuelve a ganar a nivel SKU; ORIGEN lo prueba)
-- ----------------------------------------------------------------------------
START TRANSACTION;
INSERT INTO fza_articulos_propiedades
  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP,
   ID_PV_ARTPROP, VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  (@art, 'TEMPORADA', '',      @pv1, NULL, NOW(), 'PRUEBA'),
  (@art, 'TEMPORADA', @color1, @pv2, NULL, NOW(), 'PRUEBA'),
  (@art, 'TEMPORADA', @sku1,   @pv1, NULL, NOW(), 'PRUEBA');

-- 2a. Resolucion por SKU: ORIGEN_PROP esperado SKU/COLOR/ARTICULO.
SELECT e.CODIGO_UNIDAD_SKU,
       SUBSTRING_INDEX(e.CODIGO_UNIDAD_SKU, '/', 2) AS color_prefix,
       e.VALOR_PV AS temporada_efectiva,
       e.ORIGEN_PROP
  FROM vi_articulos_propiedades_efectivas e
 WHERE e.CODIGO_ART = @art AND e.CODIGO_PROP_ARTPROP = 'TEMPORADA'
 ORDER BY e.CODIGO_UNIDAD_SKU;

-- 2b. Asserts de precedencia.
SELECT 'SKU gana sobre COLOR' AS prueba,
       IF((SELECT ORIGEN_PROP FROM vi_articulos_propiedades_efectivas
            WHERE CODIGO_ART = @art AND CODIGO_PROP_ARTPROP = 'TEMPORADA'
              AND CODIGO_UNIDAD_SKU = @sku1) = 'SKU', 'PASS', 'FAIL') AS resultado
UNION ALL
SELECT 'COLOR gana sobre ARTICULO (resto del color)',
       IF((SELECT COUNT(*) FROM vi_articulos_propiedades_efectivas
            WHERE CODIGO_ART = @art AND CODIGO_PROP_ARTPROP = 'TEMPORADA'
              AND CODIGO_UNIDAD_SKU LIKE CONCAT(@color1, '/%')
              AND CODIGO_UNIDAD_SKU <> @sku1
              AND ORIGEN_PROP <> 'COLOR') = 0, 'PASS', 'FAIL')
UNION ALL
SELECT 'Otros colores caen a ARTICULO',
       IF((SELECT COUNT(*) FROM vi_articulos_propiedades_efectivas
            WHERE CODIGO_ART = @art AND CODIGO_PROP_ARTPROP = 'TEMPORADA'
              AND CODIGO_UNIDAD_SKU NOT LIKE CONCAT(@color1, '/%')
              AND ORIGEN_PROP <> 'ARTICULO') = 0, 'PASS', 'FAIL')
UNION ALL
SELECT 'La vista NO duplica por SKU (1 fila TEMPORADA/SKU)',
       IF((SELECT COUNT(*) FROM (
             SELECT CODIGO_UNIDAD_SKU
               FROM vi_articulos_propiedades_efectivas
              WHERE CODIGO_ART = @art AND CODIGO_PROP_ARTPROP = 'TEMPORADA'
              GROUP BY CODIGO_UNIDAD_SKU HAVING COUNT(*) > 1) d) = 0,
          'PASS', 'FAIL');

-- 2c. Temporada EFECTIVA por (articulo, color): es lo que calculan los
-- balances. Cada color debe salir con su temporada (color o, si no, art).
SELECT SUBSTRING_INDEX(e.CODIGO_UNIDAD_SKU, '/', 2) AS color_prefix,
       MAX(COALESCE(e.VALOR_PV, e.VALOR_LIBRE_ARTPROP)) AS temporada_color,
       MAX(e.ORIGEN_PROP) AS origen
  FROM vi_articulos_propiedades_efectivas e
 WHERE e.CODIGO_ART = @art AND e.CODIGO_PROP_ARTPROP = 'TEMPORADA'
 GROUP BY color_prefix
 ORDER BY color_prefix;

-- 2d. vi_articulos NO debe duplicar el articulo aunque haya temporada de
-- color. Si sale FAIL: falta reaplicar vi_articulos_nombre_proveedor.sql.
SELECT 'vi_articulos: 1 fila por articulo' AS prueba,
       IF((SELECT COUNT(*) FROM vi_articulos WHERE CODIGO_ART_ART = @art) = 1,
          'PASS', 'FAIL (reaplica vi_articulos)') AS resultado;

ROLLBACK;

-- 2e. Verifica que el ROLLBACK no dejo rastro (debe dar 0).
SELECT 'Sin rastro tras ROLLBACK' AS prueba,
       IF(COUNT(*) = 0, 'PASS', 'FAIL') AS resultado
  FROM fza_articulos_propiedades
 WHERE USUARIO_ALTA = 'PRUEBA';

-- ----------------------------------------------------------------------------
-- SECCION 3. Retrocompatibilidad: un articulo que HOY solo tiene temporada de
-- articulo ('') debe resolver TODOS sus SKU a ese valor con ORIGEN=ARTICULO.
-- ----------------------------------------------------------------------------
SET @art_art := (
  SELECT ap.CODIGO_ART_ART
    FROM fza_articulos_propiedades ap
    JOIN fza_articulos_skus s ON s.CODIGO_ART_SKU = ap.CODIGO_ART_ART
                             AND s.ESACTIVO_SKU = 'S'
   WHERE ap.CODIGO_PROP_ARTPROP = 'TEMPORADA'
     AND ap.CODIGO_UNIDAD_ARTPROP = ''
     AND NOT EXISTS (SELECT 1 FROM fza_articulos_propiedades ap2
                      WHERE ap2.CODIGO_ART_ART = ap.CODIGO_ART_ART
                        AND ap2.CODIGO_PROP_ARTPROP = 'TEMPORADA'
                        AND ap2.CODIGO_UNIDAD_ARTPROP <> '')
   LIMIT 1);
SELECT 'Retrocompat: todo a nivel ARTICULO' AS prueba,
       IF(@art_art IS NULL, 'SKIP (sin datos)',
          IF((SELECT COUNT(*) FROM vi_articulos_propiedades_efectivas
               WHERE CODIGO_ART = @art_art AND CODIGO_PROP_ARTPROP = 'TEMPORADA'
                 AND ORIGEN_PROP <> 'ARTICULO') = 0, 'PASS', 'FAIL')) AS resultado;

-- ----------------------------------------------------------------------------
-- SECCION 4. Humo de los SP de informes (solo lectura sobre datos actuales).
-- No asserts; revisa que devuelven filas y que, agrupando por TMP, la columna
-- de Temporada sale por color cuando haya datos de color en produccion.
-- Firmas: ver cabecera de cada .sql en DESARROLLOS EN CURSO/.
-- ----------------------------------------------------------------------------
-- Balance por tallas, acumulado, desglosado, agrupado por Temporada:
CALL PRC_GET_BALANCE_ALMACEN_TALLAS('A',NULL,NULL,'','','','','','PVP','S','',
                                    'TMP','','',0);
-- Balance sin tallas, mismo criterio:
CALL PRC_GET_BALANCE_ALMACEN_SIN_TALLAS('A',NULL,NULL,'','','','','','PVP','S','',
                                        'TMP','','',0);
-- Movimientos de ventas por articulos (ultimos ~2 meses), agrupado por Temporada:
CALL PRC_GET_MOV_VENTAS_ART(DATE_SUB(CURDATE(), INTERVAL 60 DAY), CURDATE(),
                            NULL,'','','','','','TMP','','',0);

-- ----------------------------------------------------------------------------
-- SECCION 5. Comprobacion POST-materializacion (manual, tras usar la app).
-- Materializa en la app una sesion de compra CON temporada de cabecera y un
-- articulo con color, y luego corre esto con @art_mat = ese articulo:
--   SET @art_mat := 'CODIGO_DEL_ARTICULO_MATERIALIZADO';
-- Esperado: 1 fila '' (articulo) + 1 fila por cada color comprado (ART/COLOR).
-- ----------------------------------------------------------------------------
-- SELECT CODIGO_UNIDAD_ARTPROP, ID_PV_ARTPROP, USUARIO_ALTA, INSTANTE_ALTA
--   FROM fza_articulos_propiedades
--  WHERE CODIGO_ART_ART = @art_mat AND CODIGO_PROP_ARTPROP = 'TEMPORADA'
--  ORDER BY CODIGO_UNIDAD_ARTPROP;
