-- Habilita varias fotos por articulo y nivel de SKU.
-- MariaDB / MySQL. Es idempotente para facilitar el despliegue por fases.

SET @fza_tiene_orden_fot := (
  SELECT COUNT(*)
    FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_articulos_fotos'
     AND COLUMN_NAME = 'ORDEN_FOT'
);

SET @fza_sql := IF(
  @fza_tiene_orden_fot = 0,
  'ALTER TABLE `fza_articulos_fotos` ADD COLUMN `ORDEN_FOT` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT ''Posicion 1-based de la foto dentro del articulo/unidad'' AFTER `CODIGO_UNIDAD_FOT`',
  'SELECT 1'
);
PREPARE fza_stmt FROM @fza_sql;
EXECUTE fza_stmt;
DEALLOCATE PREPARE fza_stmt;

SET @fza_pk_fotos := (
  SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ',')
    FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_articulos_fotos'
     AND INDEX_NAME = 'PRIMARY'
);

SET @fza_sql := IF(
  COALESCE(@fza_pk_fotos, '') =
    'CODIGO_ART_FOT,CODIGO_UNIDAD_FOT,ORDEN_FOT',
  'SELECT 1',
  IF(
    COALESCE(@fza_pk_fotos, '') = '',
    'ALTER TABLE `fza_articulos_fotos` ADD PRIMARY KEY (`CODIGO_ART_FOT`, `CODIGO_UNIDAD_FOT`, `ORDEN_FOT`)',
    'ALTER TABLE `fza_articulos_fotos` DROP PRIMARY KEY, ADD PRIMARY KEY (`CODIGO_ART_FOT`, `CODIGO_UNIDAD_FOT`, `ORDEN_FOT`)'
  )
);
PREPARE fza_stmt FROM @fza_sql;
EXECUTE fza_stmt;
DEALLOCATE PREPARE fza_stmt;

-- La vista historica sigue exponiendo una sola foto determinista por SKU.
CREATE OR REPLACE VIEW `vi_articulos_fotos` AS
SELECT
  sku.CODIGO_ART_SKU AS CODIGO_ART,
  sku.CODIGO_UNIDAD_SKU AS CODIGO_UNIDAD_SKU,
  COALESCE(fs.NOMBRE_FOT_FOT, fa.NOMBRE_FOT_FOT) AS NOMBRE_FOT,
  COALESCE(fs.EXTENSION_ORIGEN_FOT,
           fa.EXTENSION_ORIGEN_FOT) AS EXTENSION_ORIGEN_FOT,
  CASE
    WHEN fs.NOMBRE_FOT_FOT IS NOT NULL THEN 'SKU'
    WHEN fa.NOMBRE_FOT_FOT IS NOT NULL THEN 'ARTICULO'
    ELSE NULL
  END AS ORIGEN_FOT
FROM fza_articulos_skus sku
LEFT JOIN fza_articulos_fotos fs
  ON fs.CODIGO_ART_FOT = sku.CODIGO_ART_SKU
 AND fs.CODIGO_UNIDAD_FOT = sku.CODIGO_UNIDAD_SKU
 AND fs.ORDEN_FOT = 1
LEFT JOIN fza_articulos_fotos fa
  ON fa.CODIGO_ART_FOT = sku.CODIGO_ART_SKU
 AND fa.CODIGO_UNIDAD_FOT = ''
 AND fa.ORDEN_FOT = 1;

SET @fza_sql := NULL;
SET @fza_pk_fotos := NULL;
SET @fza_tiene_orden_fot := NULL;
