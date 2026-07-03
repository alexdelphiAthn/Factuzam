-- ============================================================================
-- Anyade el almacen de salida a la cabecera del albaran de venta mayor.
-- Idempotente: no toca factuzam_original.sql.
-- ============================================================================

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes'
              AND COLUMN_NAME  = 'CODIGO_ALM_ALB');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_albaranes`
     ADD COLUMN `CODIGO_ALM_ALB` varchar(10) NULL DEFAULT NULL
     COMMENT ''Almacen de salida de la mercancia''
     AFTER `CODIGO_EMP_ALB`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes'
              AND INDEX_NAME   = 'IDX_ALB_ALMACEN');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_albaranes`
     ADD INDEX `IDX_ALB_ALMACEN` (`CODIGO_ALM_ALB`)',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- MariaDB congela las columnas de una vista creada con a.*. Rehacerla recoge
-- CODIGO_ALM_ALB y el nombre del almacen para listado y cabecera.
CREATE OR REPLACE VIEW `vi_albaranes` AS
SELECT a.*,
       alm.NOMBRE_ALM_ALM AS NOMBRE_ALM_ALB
  FROM fza_albaranes a
  LEFT JOIN fza_almacenes alm
    ON alm.CODIGO_ALM_ALM = a.CODIGO_ALM_ALB;
