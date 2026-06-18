-- =============================================================================
-- Script: empleados_ampliar_ocemp.sql
-- Objetivo: ampliar fza_empleados para guardar los datos de contacto e
--           identificación que vienen del legacy dbo.ocemp.
--
-- Idempotente: cada ALTER se guarda con INFORMATION_SCHEMA.
-- No toca fza_usuarios: vendedores/empleados viven en fza_empleados.
-- =============================================================================

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'RAZON_SOCIAL_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN RAZON_SOCIAL_EMPL varchar(100) NULL DEFAULT NULL
     AFTER NOMBRE_EMPL',
  'SELECT ''RAZON_SOCIAL_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'NIF_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN NIF_EMPL varchar(20) NULL DEFAULT NULL
     AFTER RAZON_SOCIAL_EMPL',
  'SELECT ''NIF_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'DIRECCION2_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN DIRECCION2_EMPL varchar(200) NULL DEFAULT NULL
     AFTER DIRECCION_EMPL',
  'SELECT ''DIRECCION2_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'CODIGO_POSTAL_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN CODIGO_POSTAL_EMPL varchar(10) NULL DEFAULT NULL
     AFTER DIRECCION2_EMPL',
  'SELECT ''CODIGO_POSTAL_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'POBLACION_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN POBLACION_EMPL varchar(100) NULL DEFAULT NULL
     AFTER CODIGO_POSTAL_EMPL',
  'SELECT ''POBLACION_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'PROVINCIA_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN PROVINCIA_EMPL varchar(100) NULL DEFAULT NULL
     AFTER POBLACION_EMPL',
  'SELECT ''PROVINCIA_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'TELEFONO2_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN TELEFONO2_EMPL varchar(20) NULL DEFAULT NULL
     AFTER TELEFONO_EMPL',
  'SELECT ''TELEFONO2_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'FAX_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN FAX_EMPL varchar(20) NULL DEFAULT NULL
     AFTER TELEFONO2_EMPL',
  'SELECT ''FAX_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'EMAIL_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN EMAIL_EMPL varchar(100) NULL DEFAULT NULL
     AFTER FAX_EMPL',
  'SELECT ''EMAIL_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'WEB_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN WEB_EMPL varchar(200) NULL DEFAULT NULL
     AFTER EMAIL_EMPL',
  'SELECT ''WEB_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'IBAN_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN IBAN_EMPL varchar(35) NULL DEFAULT NULL
     AFTER WEB_EMPL',
  'SELECT ''IBAN_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @nCol := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empleados'
     AND COLUMN_NAME = 'BIC_EMPL'
);
SET @sSql := IF(@nCol = 0,
  'ALTER TABLE fza_empleados
     ADD COLUMN BIC_EMPL varchar(11) NULL DEFAULT NULL
     AFTER IBAN_EMPL',
  'SELECT ''BIC_EMPL ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_empleados` AS
SELECT `fza_empleados`.`CODIGO_EMPL`            AS `CODIGO_EMPL`,
       `fza_empleados`.`NOMBRE_EMPL`            AS `NOMBRE_EMPL`,
       `fza_empleados`.`RAZON_SOCIAL_EMPL`      AS `RAZON_SOCIAL_EMPL`,
       `fza_empleados`.`NIF_EMPL`               AS `NIF_EMPL`,
       `fza_empleados`.`DIRECCION_EMPL`         AS `DIRECCION_EMPL`,
       `fza_empleados`.`DIRECCION2_EMPL`        AS `DIRECCION2_EMPL`,
       `fza_empleados`.`CODIGO_POSTAL_EMPL`     AS `CODIGO_POSTAL_EMPL`,
       `fza_empleados`.`POBLACION_EMPL`         AS `POBLACION_EMPL`,
       `fza_empleados`.`PROVINCIA_EMPL`         AS `PROVINCIA_EMPL`,
       `fza_empleados`.`TELEFONO_EMPL`          AS `TELEFONO_EMPL`,
       `fza_empleados`.`TELEFONO2_EMPL`         AS `TELEFONO2_EMPL`,
       `fza_empleados`.`FAX_EMPL`               AS `FAX_EMPL`,
       `fza_empleados`.`EMAIL_EMPL`             AS `EMAIL_EMPL`,
       `fza_empleados`.`WEB_EMPL`               AS `WEB_EMPL`,
       `fza_empleados`.`IBAN_EMPL`              AS `IBAN_EMPL`,
       `fza_empleados`.`BIC_EMPL`               AS `BIC_EMPL`,
       `fza_empleados`.`DIMINUTIVO_TICKET_EMPL` AS `DIMINUTIVO_TICKET_EMPL`,
       `fza_empleados`.`ESACTIVO_EMPL`          AS `ESACTIVO_EMPL`,
       `fza_empleados`.`INSTANTE_MODIF`         AS `INSTANTE_MODIF`,
       `fza_empleados`.`INSTANTE_ALTA`          AS `INSTANTE_ALTA`,
       `fza_empleados`.`USUARIO_ALTA`           AS `USUARIO_ALTA`,
       `fza_empleados`.`USUARIO_MODIF`          AS `USUARIO_MODIF`
  FROM `fza_empleados`;
