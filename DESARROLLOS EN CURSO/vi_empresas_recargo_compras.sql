-- =============================================================================
-- Repara vi_empresas para exponer ESIVA_RECARGO_COMPRAS_EMP
-- =============================================================================
-- El mantenimiento de empresas lee SELECT * FROM vi_empresas y graba contra
-- fza_empresas usando ESIVA_RECARGO_COMPRAS_EMP. Si la vista no expone el
-- campo, UniDAC no encuentra el parametro al grabar.
-- Idempotente: anade la columna si falta y recrea la vista.
-- =============================================================================
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_empresas'
     AND COLUMN_NAME  = 'ESIVA_RECARGO_COMPRAS_EMP'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_empresas
     ADD COLUMN ESIVA_RECARGO_COMPRAS_EMP varchar(1) NULL DEFAULT ''N''
     AFTER ESRETENCIONES_EMP',
  'SELECT ''ESIVA_RECARGO_COMPRAS_EMP ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_empresas
   SET ESIVA_RECARGO_COMPRAS_EMP = 'N'
 WHERE ESIVA_RECARGO_COMPRAS_EMP IS NULL
    OR ESIVA_RECARGO_COMPRAS_EMP = '';
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
       `fza_ivas_grupos`.`DESCRIPCION_IVA_IVAGRP`     AS `DESCRIPCION_IVA_IVAGRP`,
       `fza_empresas`.`ESRETENCIONES_EMP`             AS `ESRETENCIONES_EMP`,
       `fza_empresas`.`ESIVA_RECARGO_COMPRAS_EMP`     AS `ESIVA_RECARGO_COMPRAS_EMP`,
       `fza_empresas`.`ESREGIMENESPECIALAGRICOLA_EMP` AS `ESREGIMENESPECIALAGRICOLA_EMP`,
       `fza_empresas`.`TEXTO_LEGAL_FACTURA_EMP`       AS `TEXTO_LEGAL_FACTURA_EMP`,
       `fza_empresas`.`FORMATO_DOCUMENTO_EMP`         AS `FORMATO_DOCUMENTO_EMP`,
       `fza_empresas`.`CODIGO_CERTIFICADO_EMP`        AS `CODIGO_CERTIFICADO_EMP`,
       `fza_empresas`.`TITULAR_CERTIFICADO_EMP`       AS `TITULAR_CERTIFICADO_EMP`,
       `fza_empresas`.`TIPO_CERTIFICADO_EMP`          AS `TIPO_CERTIFICADO_EMP`,
       `fza_empresas`.`FECHA_DESDE_CERTIFICADO_EMP`   AS `FECHA_DESDE_CERTIFICADO_EMP`,
       `fza_empresas`.`FECHA_HASTA_CERTIFICADO_EMP`   AS `FECHA_HASTA_CERTIFICADO_EMP`,
       `fza_empresas`.`INSTANTE_MODIF`                AS `INSTANTE_MODIF`,
       `fza_empresas`.`INSTANTE_ALTA`                 AS `INSTANTE_ALTA`,
       `fza_empresas`.`USUARIO_ALTA`                  AS `USUARIO_ALTA`,
       `fza_empresas`.`USUARIO_MODIF`                 AS `USUARIO_MODIF`
  FROM (`fza_empresas`
        LEFT JOIN `fza_ivas_grupos`
          ON (`fza_empresas`.`GRUPO_ZONA_IVA_EMP` =
              `fza_ivas_grupos`.`IVA_IVAGRP`))
 ORDER BY `fza_empresas`.`ORDEN_EMP`;
