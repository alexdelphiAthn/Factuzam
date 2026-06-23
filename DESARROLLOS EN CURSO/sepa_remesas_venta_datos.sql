-- =============================================================================
-- Datos SEPA para remesas de venta
-- =============================================================================
-- Anade los datos maestros necesarios para generar adeudos SEPA 19.14:
--   - Codigo acreedor SEPA en la cuenta bancaria de la empresa.
--   - Mandato SEPA y fecha de firma en el cliente.
--   - Tipo de secuencia SEPA en la remesa de venta.
--
-- Idempotente: se puede ejecutar varias veces. Cada columna se anade solo
-- si no existe.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_empresas_bancos'
     AND COLUMN_NAME  = 'CODIGO_ACREEDOR_SEPA_EMPBAN'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE `fza_empresas_bancos`
     ADD COLUMN `CODIGO_ACREEDOR_SEPA_EMPBAN` varchar(35) NULL DEFAULT NULL
       COMMENT ''Identificador de acreedor SEPA para adeudos''
       AFTER `BIC_EMPBAN`',
  'SELECT ''CODIGO_ACREEDOR_SEPA_EMPBAN ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'ID_MANDATO_SEPA_CLI'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE `fza_clientes`
     ADD COLUMN `ID_MANDATO_SEPA_CLI` varchar(35) NULL DEFAULT NULL
       COMMENT ''Identificador del mandato SEPA de adeudo''
       AFTER `IBAN_CLI`',
  'SELECT ''ID_MANDATO_SEPA_CLI ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'FECHA_FIRMA_MANDATO_SEPA_CLI'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE `fza_clientes`
     ADD COLUMN `FECHA_FIRMA_MANDATO_SEPA_CLI` date NULL DEFAULT NULL
       COMMENT ''Fecha de firma del mandato SEPA de adeudo''
       AFTER `ID_MANDATO_SEPA_CLI`',
  'SELECT ''FECHA_FIRMA_MANDATO_SEPA_CLI ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_remesas_venta'
     AND COLUMN_NAME  = 'TIPO_SECUENCIA_SEPA_REMV'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE `fza_remesas_venta`
     ADD COLUMN `TIPO_SECUENCIA_SEPA_REMV` varchar(4) NULL DEFAULT ''RCUR''
       COMMENT ''Secuencia SEPA del adeudo: FRST, RCUR, OOFF o FNAL''
       AFTER `NORMA_REMV`',
  'SELECT ''TIPO_SECUENCIA_SEPA_REMV ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `fza_remesas_venta`
   SET `TIPO_SECUENCIA_SEPA_REMV` = 'RCUR'
 WHERE `TIPO_SECUENCIA_SEPA_REMV` IS NULL
    OR TRIM(`TIPO_SECUENCIA_SEPA_REMV`) = '';
