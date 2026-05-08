-- ============================================================================
-- Migración: pestaña CB de Artículos
-- ----------------------------------------------------------------------------
-- 1) Limpia placeholders obsoletos `_FAB_xxx` de fza_codigos_barras.
-- 2) Convierte la PK de fza_codigos_barras en autonumérica (ID_CB) para
--    eliminar las colisiones por CODIGO_BARRAS_CB y permitir múltiples
--    códigos por SKU sin restricciones artificiales.
-- 3) Reconstruye vi_articulos_skus_extendida para exponer ID_CB y elegir
--    el código representativo (principal > menor ID).
-- ----------------------------------------------------------------------------
-- Idempotente: se puede ejecutar dos veces sin romper nada.
-- ============================================================================

-- 1) Eliminamos placeholders obsoletos. El CB del fabricante queda vacío
--    hasta que el usuario lo introduzca manualmente desde la pestaña CB.
DELETE FROM fza_codigos_barras
 WHERE LEFT(CODIGO_BARRAS_CB, 5) = '_FAB_';

-- 2) Añadimos ID_CB autonumérico como nueva PK. CODIGO_BARRAS_CB pasa a ser
--    columna normal con índice no único.
SET @has_id := (
  SELECT COUNT(*)
    FROM information_schema.columns
   WHERE table_schema = DATABASE()
     AND table_name   = 'fza_codigos_barras'
     AND column_name  = 'ID_CB'
);
SET @sql := IF(@has_id = 0,
  'ALTER TABLE fza_codigos_barras
     DROP PRIMARY KEY,
     ADD COLUMN ID_CB INT NOT NULL AUTO_INCREMENT FIRST,
     ADD PRIMARY KEY (ID_CB)',
  'SELECT ''ID_CB ya existe, se omite ALTER'' AS info');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (
  SELECT COUNT(*)
    FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name   = 'fza_codigos_barras'
     AND index_name   = 'IDX_BARRAS_CB'
);
SET @sql := IF(@has_idx = 0,
  'ALTER TABLE fza_codigos_barras ADD INDEX IDX_BARRAS_CB (CODIGO_BARRAS_CB)',
  'SELECT ''IDX_BARRAS_CB ya existe, se omite'' AS info');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) Reconstruimos la vista para que la rejilla de la pestaña CB pueda
--    usar ID_CB como clave de UPDATE/DELETE y muestre el barcode principal
--    de cada SKU (en su defecto, el de menor ID).
DROP VIEW IF EXISTS vi_articulos_skus_extendida;
CREATE ALGORITHM=UNDEFINED VIEW vi_articulos_skus_extendida AS
SELECT
  sku.CODIGO_UNIDAD_SKU,
  sku.CODIGO_ART_SKU,
  sku.CODIGO_VAR_SKU,
  sku.ESACTIVO_SKU,
  cb.ID_CB,
  cb.CODIGO_BARRAS_CB,
  cb.TIPO_CODIGO_CB,
  cb.ESPRINCIPAL_CB,
  COALESCE(stk.STOCK_TOTAL, 0) AS STOCK_TOTAL,
  sku.INSTANTE_MODIF,
  sku.INSTANTE_ALTA,
  sku.USUARIO_ALTA,
  sku.USUARIO_MODIF
FROM fza_articulos_skus sku
LEFT JOIN fza_codigos_barras cb
  ON cb.ID_CB = (
    SELECT cb2.ID_CB
      FROM fza_codigos_barras cb2
     WHERE cb2.CODIGO_UNIDAD_CB = sku.CODIGO_UNIDAD_SKU
     ORDER BY (cb2.ESPRINCIPAL_CB = 'S') DESC, cb2.ID_CB ASC
     LIMIT 1
  )
LEFT JOIN (
  SELECT CODIGO_UNIDAD_STK, SUM(CANTIDAD_STK) AS STOCK_TOTAL
    FROM fza_articulos_stockactual
   GROUP BY CODIGO_UNIDAD_STK
) stk ON sku.CODIGO_UNIDAD_SKU = stk.CODIGO_UNIDAD_STK;
