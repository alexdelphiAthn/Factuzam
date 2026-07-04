-- ============================================================================
-- Anyade el almacen de salida a la cabecera del pedido de venta mayor.
-- Idempotente: no toca factuzam_original.sql.
-- ============================================================================

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_pedidos'
              AND COLUMN_NAME  = 'CODIGO_ALM_PED');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_pedidos`
     ADD COLUMN `CODIGO_ALM_PED` varchar(10) NULL DEFAULT NULL
     COMMENT ''Almacen de salida por defecto del pedido''
     AFTER `CODIGO_EMP_PED`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_pedidos'
              AND INDEX_NAME   = 'IDX_PED_ALMACEN');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_pedidos`
     ADD INDEX `IDX_PED_ALMACEN` (`CODIGO_ALM_PED`)',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- MariaDB congela las columnas de una vista creada con p.*. Rehacerla recoge
-- CODIGO_ALM_PED y el nombre del almacen para listado y cabecera.
CREATE OR REPLACE VIEW `vi_pedidos` AS
SELECT p.*,
       alm.NOMBRE_ALM_ALM AS NOMBRE_ALM_PED
  FROM fza_pedidos p
  LEFT JOIN fza_almacenes alm
    ON alm.CODIGO_ALM_ALM = p.CODIGO_ALM_PED;
