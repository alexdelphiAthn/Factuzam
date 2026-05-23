-- Anyade CODIGO_EMP_SESDOC a fza_compras_sesiones_documentos (idempotente).
-- Necesario para que el trace de docs generados por la sesion incluya la
-- empresa, no solo serie+numero. Permite que el revertir borre con un
-- filtro completo (TIPO_DOC + EMP + ALM + SERIE + NUMERO_DOC).

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_documentos'
     AND COLUMN_NAME  = 'CODIGO_EMP_SESDOC');
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_documentos`
     ADD COLUMN `CODIGO_EMP_SESDOC` varchar(20) NULL DEFAULT NULL
     AFTER `CODIGO_ALM_SESDOC`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
