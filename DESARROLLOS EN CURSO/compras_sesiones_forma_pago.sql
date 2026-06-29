-- =============================================================================
-- Forma de pago en sesiones de compra
-- =============================================================================
-- Anyade FORMA_PAGO_SES a fza_compras_sesiones y recrea la vista editable
-- para que la columna nueva aparezca en instalaciones existentes.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones'
     AND COLUMN_NAME  = 'FORMA_PAGO_SES'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE `fza_compras_sesiones`
     ADD COLUMN `FORMA_PAGO_SES` varchar(200) NULL DEFAULT NULL
       COMMENT ''Codigo de forma de pago (fza_formas_pago)''
     AFTER `REF_PRV_SES`',
  'SELECT ''FORMA_PAGO_SES ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE OR REPLACE VIEW `vi_compras_sesiones` AS
SELECT s.*,
       prv.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV_SES,
       prv.NOMBRE_PRV       AS NOMBRE_PRV_SES
  FROM fza_compras_sesiones s
  LEFT JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = s.CODIGO_PRV_SES;
