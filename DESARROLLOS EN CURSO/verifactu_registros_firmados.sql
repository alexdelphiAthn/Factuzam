-- =============================================================================
-- Registros VERI*FACTU / NO VERI*FACTU firmados
-- =============================================================================
-- Anade almacenamiento del XML oficial firmado XAdES en eventos y registros
-- de facturacion. No modifica factuzam_original.sql.
-- Idempotente: cada columna se crea solo si no existe.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_eventos'
     AND COLUMN_NAME  = 'REGISTRO_XML_LOG'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_verifactu_eventos
     ADD COLUMN REGISTRO_XML_LOG longtext NULL DEFAULT NULL
     AFTER SERIE_FAC_LOG',
  'SELECT ''REGISTRO_XML_LOG ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_eventos'
     AND COLUMN_NAME  = 'FIRMA_XADES_LOG'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_verifactu_eventos
     ADD COLUMN FIRMA_XADES_LOG longtext NULL DEFAULT NULL
     AFTER REGISTRO_XML_LOG',
  'SELECT ''FIRMA_XADES_LOG ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_eventos'
     AND COLUMN_NAME  = 'SERIE_CERTIFICADO_LOG'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_verifactu_eventos
     ADD COLUMN SERIE_CERTIFICADO_LOG varchar(128) NULL DEFAULT NULL
     AFTER FIRMA_XADES_LOG',
  'SELECT ''SERIE_CERTIFICADO_LOG ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_eventos'
     AND COLUMN_NAME  = 'TITULAR_CERTIFICADO_LOG'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_verifactu_eventos
     ADD COLUMN TITULAR_CERTIFICADO_LOG varchar(1000) NULL DEFAULT NULL
     AFTER SERIE_CERTIFICADO_LOG',
  'SELECT ''TITULAR_CERTIFICADO_LOG ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_eventos'
     AND COLUMN_NAME  = 'HUELLA_CERTIFICADO_LOG'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_verifactu_eventos
     ADD COLUMN HUELLA_CERTIFICADO_LOG char(40) NULL DEFAULT NULL
     AFTER TITULAR_CERTIFICADO_LOG',
  'SELECT ''HUELLA_CERTIFICADO_LOG ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_consolidaciones'
     AND COLUMN_NAME  = 'REGISTRO_XML_FACCON'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas_consolidaciones
     ADD COLUMN REGISTRO_XML_FACCON longtext NULL DEFAULT NULL
     AFTER PETICION_COMPLETA_FACCON',
  'SELECT ''REGISTRO_XML_FACCON ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_consolidaciones'
     AND COLUMN_NAME  = 'FIRMA_DIGITAL_FACCON'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas_consolidaciones
     ADD COLUMN FIRMA_DIGITAL_FACCON longtext NULL DEFAULT NULL
     AFTER REGISTRO_XML_FACCON',
  'SELECT ''FIRMA_DIGITAL_FACCON ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_consolidaciones'
     AND COLUMN_NAME  = 'SERIE_CERTIFICADO_FACCON'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas_consolidaciones
     ADD COLUMN SERIE_CERTIFICADO_FACCON varchar(128) NULL DEFAULT NULL
     AFTER FIRMA_DIGITAL_FACCON',
  'SELECT ''SERIE_CERTIFICADO_FACCON ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_consolidaciones'
     AND COLUMN_NAME  = 'TITULAR_CERTIFICADO_FACCON'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas_consolidaciones
     ADD COLUMN TITULAR_CERTIFICADO_FACCON varchar(1000) NULL DEFAULT NULL
     AFTER SERIE_CERTIFICADO_FACCON',
  'SELECT ''TITULAR_CERTIFICADO_FACCON ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_consolidaciones'
     AND COLUMN_NAME  = 'HUELLA_CERTIFICADO_FACCON'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas_consolidaciones
     ADD COLUMN HUELLA_CERTIFICADO_FACCON char(40) NULL DEFAULT NULL
     AFTER TITULAR_CERTIFICADO_FACCON',
  'SELECT ''HUELLA_CERTIFICADO_FACCON ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
