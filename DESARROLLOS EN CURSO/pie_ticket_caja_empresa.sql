-- =============================================================================
-- Pie configurable del ticket de caja por empresa.
--
-- Anade cuatro lineas de texto a fza_empresas y las expone en vi_empresas.
-- Cada linea queda limitada a 42 caracteres, que es el ancho del ticket.
-- No modifica factuzam_original.sql.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas'
     AND COLUMN_NAME = 'TEXTO_PIE_TICKET_CAJA_1_EMP'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_empresas
     ADD COLUMN TEXTO_PIE_TICKET_CAJA_1_EMP varchar(42) NULL DEFAULT NULL
       COMMENT ''Linea 1 del pie del ticket de caja''
       AFTER TEXTO_LEGAL_FACTURA_EMP',
  'SELECT ''TEXTO_PIE_TICKET_CAJA_1_EMP ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas'
     AND COLUMN_NAME = 'TEXTO_PIE_TICKET_CAJA_2_EMP'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_empresas
     ADD COLUMN TEXTO_PIE_TICKET_CAJA_2_EMP varchar(42) NULL DEFAULT NULL
       COMMENT ''Linea 2 del pie del ticket de caja''
       AFTER TEXTO_PIE_TICKET_CAJA_1_EMP',
  'SELECT ''TEXTO_PIE_TICKET_CAJA_2_EMP ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas'
     AND COLUMN_NAME = 'TEXTO_PIE_TICKET_CAJA_3_EMP'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_empresas
     ADD COLUMN TEXTO_PIE_TICKET_CAJA_3_EMP varchar(42) NULL DEFAULT NULL
       COMMENT ''Linea 3 del pie del ticket de caja''
       AFTER TEXTO_PIE_TICKET_CAJA_2_EMP',
  'SELECT ''TEXTO_PIE_TICKET_CAJA_3_EMP ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas'
     AND COLUMN_NAME = 'TEXTO_PIE_TICKET_CAJA_4_EMP'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_empresas
     ADD COLUMN TEXTO_PIE_TICKET_CAJA_4_EMP varchar(42) NULL DEFAULT NULL
       COMMENT ''Linea 4 del pie del ticket de caja''
       AFTER TEXTO_PIE_TICKET_CAJA_3_EMP',
  'SELECT ''TEXTO_PIE_TICKET_CAJA_4_EMP ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE fza_empresas
   SET TEXTO_PIE_TICKET_CAJA_1_EMP =
       LEFT(TEXTO_PIE_TICKET_CAJA_1_EMP, 42)
 WHERE CHAR_LENGTH(IFNULL(TEXTO_PIE_TICKET_CAJA_1_EMP, '')) > 42;
UPDATE fza_empresas
   SET TEXTO_PIE_TICKET_CAJA_2_EMP =
       LEFT(TEXTO_PIE_TICKET_CAJA_2_EMP, 42)
 WHERE CHAR_LENGTH(IFNULL(TEXTO_PIE_TICKET_CAJA_2_EMP, '')) > 42;
UPDATE fza_empresas
   SET TEXTO_PIE_TICKET_CAJA_3_EMP =
       LEFT(TEXTO_PIE_TICKET_CAJA_3_EMP, 42)
 WHERE CHAR_LENGTH(IFNULL(TEXTO_PIE_TICKET_CAJA_3_EMP, '')) > 42;
UPDATE fza_empresas
   SET TEXTO_PIE_TICKET_CAJA_4_EMP =
       LEFT(TEXTO_PIE_TICKET_CAJA_4_EMP, 42)
 WHERE CHAR_LENGTH(IFNULL(TEXTO_PIE_TICKET_CAJA_4_EMP, '')) > 42;

ALTER TABLE fza_empresas
  MODIFY COLUMN TEXTO_PIE_TICKET_CAJA_1_EMP varchar(42) NULL DEFAULT NULL
    COMMENT 'Linea 1 del pie del ticket de caja'
    AFTER TEXTO_LEGAL_FACTURA_EMP;
ALTER TABLE fza_empresas
  MODIFY COLUMN TEXTO_PIE_TICKET_CAJA_2_EMP varchar(42) NULL DEFAULT NULL
    COMMENT 'Linea 2 del pie del ticket de caja'
    AFTER TEXTO_PIE_TICKET_CAJA_1_EMP;
ALTER TABLE fza_empresas
  MODIFY COLUMN TEXTO_PIE_TICKET_CAJA_3_EMP varchar(42) NULL DEFAULT NULL
    COMMENT 'Linea 3 del pie del ticket de caja'
    AFTER TEXTO_PIE_TICKET_CAJA_2_EMP;
ALTER TABLE fza_empresas
  MODIFY COLUMN TEXTO_PIE_TICKET_CAJA_4_EMP varchar(42) NULL DEFAULT NULL
    COMMENT 'Linea 4 del pie del ticket de caja'
    AFTER TEXTO_PIE_TICKET_CAJA_3_EMP;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_empresas` AS
SELECT `fza_empresas`.`CODIGO_EMP_EMP`                AS `CODIGO_EMP_EMP`,
       `fza_empresas`.`ORDEN_EMP`                     AS `ORDEN_EMP`,
       `fza_empresas`.`ESACTIVO_EMP`                  AS `ESACTIVO_EMP`,
       `fza_empresas`.`RAZON_SOCIAL_EMP`              AS `RAZON_SOCIAL_EMP`,
       `fza_empresas`.`NIF_EMP`                       AS `NIF_EMP`,
       `fza_empresas`.`MOVIL_EMP`                     AS `MOVIL_EMP`,
       `fza_empresas`.`EMAIL_EMP`                     AS `EMAIL_EMP`,
       `fza_empresas`.`DIRECCION1_EMP`                AS `DIRECCION1_EMP`,
       `fza_empresas`.`DIRECCION2_EMP`                AS `DIRECCION2_EMP`,
       `fza_empresas`.`CODIGO_POSTAL_EMP`             AS `CODIGO_POSTAL_EMP`,
       `fza_empresas`.`POBLACION_EMP`                 AS `POBLACION_EMP`,
       `fza_empresas`.`PROVINCIA_EMP`                 AS `PROVINCIA_EMP`,
       `fza_empresas`.`NOMBRE_PAI_EMP`                AS `NOMBRE_PAI_EMP`,
       `fza_empresas`.`CODIGO_PAI_EMP`                AS `CODIGO_PAI_EMP`,
       `fza_empresas`.`IBAN_EMP`                      AS `IBAN_EMP`,
       `fza_empresas`.`GRUPO_ZONA_IVA_EMP`            AS `GRUPO_ZONA_IVA_EMP`,
       `fza_ivas_grupos`.`DESCRIPCION_IVA_IVAGRP`
              AS `DESCRIPCION_IVA_IVAGRP`,
       `fza_empresas`.`ESRETENCIONES_EMP`             AS `ESRETENCIONES_EMP`,
       `fza_empresas`.`ESREGIMENESPECIALAGRICOLA_EMP`
              AS `ESREGIMENESPECIALAGRICOLA_EMP`,
       `fza_empresas`.`TEXTO_LEGAL_FACTURA_EMP`
              AS `TEXTO_LEGAL_FACTURA_EMP`,
       `fza_empresas`.`TEXTO_PIE_TICKET_CAJA_1_EMP`
              AS `TEXTO_PIE_TICKET_CAJA_1_EMP`,
       `fza_empresas`.`TEXTO_PIE_TICKET_CAJA_2_EMP`
              AS `TEXTO_PIE_TICKET_CAJA_2_EMP`,
       `fza_empresas`.`TEXTO_PIE_TICKET_CAJA_3_EMP`
              AS `TEXTO_PIE_TICKET_CAJA_3_EMP`,
       `fza_empresas`.`TEXTO_PIE_TICKET_CAJA_4_EMP`
              AS `TEXTO_PIE_TICKET_CAJA_4_EMP`,
       `fza_empresas`.`FORMATO_DOCUMENTO_EMP`
              AS `FORMATO_DOCUMENTO_EMP`,
       `fza_empresas`.`CODIGO_CERTIFICADO_EMP`
              AS `CODIGO_CERTIFICADO_EMP`,
       `fza_empresas`.`TITULAR_CERTIFICADO_EMP`
              AS `TITULAR_CERTIFICADO_EMP`,
       `fza_empresas`.`TIPO_CERTIFICADO_EMP`          AS `TIPO_CERTIFICADO_EMP`,
       `fza_empresas`.`FECHA_DESDE_CERTIFICADO_EMP`
              AS `FECHA_DESDE_CERTIFICADO_EMP`,
       `fza_empresas`.`FECHA_HASTA_CERTIFICADO_EMP`
              AS `FECHA_HASTA_CERTIFICADO_EMP`,
       `fza_empresas`.`INSTANTE_MODIF`                AS `INSTANTE_MODIF`,
       `fza_empresas`.`INSTANTE_ALTA`                 AS `INSTANTE_ALTA`,
       `fza_empresas`.`USUARIO_ALTA`                  AS `USUARIO_ALTA`,
       `fza_empresas`.`USUARIO_MODIF`                 AS `USUARIO_MODIF`
  FROM (`fza_empresas`
        LEFT JOIN `fza_ivas_grupos`
          ON (`fza_empresas`.`GRUPO_ZONA_IVA_EMP` =
              `fza_ivas_grupos`.`IVA_IVAGRP`))
 ORDER BY `fza_empresas`.`ORDEN_EMP`;
