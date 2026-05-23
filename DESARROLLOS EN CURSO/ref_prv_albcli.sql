-- Anyadir REF_PRV_ALBCLIN a fza_albaranes_compra_lineas (idempotente)
-- Propaga la referencia del proveedor desde la linea de sesion al
-- albaran materializado para que se vea en el grid del Mto y en el
-- informe de impresion. La misma columna existe en sesion como
-- REF_PRV_SESLIN varchar(100).

SET @col_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra_lineas'
     AND COLUMN_NAME  = 'REF_PRV_ALBCLIN'
);

SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `fza_albaranes_compra_lineas`
     ADD COLUMN `REF_PRV_ALBCLIN` varchar(100) NULL DEFAULT NULL
     AFTER `CODIGO_UNIDAD_ALBCLIN`',
  'SELECT 1');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
