-- =============================================================================
-- Sesiones de compra: recargo, varios tipos de IVA y totales fiscales
-- =============================================================================
-- Idempotente. No tocar factuzam_original.sql: este script se aplica sobre
-- bases existentes y completa las columnas que usa inMtoComprasSesiones.
-- =============================================================================

DROP PROCEDURE IF EXISTS `PRC_TMP_ADD_COL_SES_IVA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_TMP_ADD_COL_SES_IVA`(
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pDefinicion text,
  IN pDespues varchar(64)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = pTabla
       AND COLUMN_NAME = pColumna
  ) THEN
    SET @sSql = CONCAT('ALTER TABLE `', pTabla, '` ADD COLUMN `',
                       pColumna, '` ', pDefinicion);
    IF pDespues IS NOT NULL AND pDespues <> '' AND EXISTS (
      SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = pTabla
         AND COLUMN_NAME = pDespues
    ) THEN
      SET @sSql = CONCAT(@sSql, ' AFTER `', pDespues, '`');
    END IF;
    PREPARE stmt FROM @sSql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END ;;
DELIMITER ;

CALL PRC_TMP_ADD_COL_SES_IVA('fza_empresas',
                             'ESIVA_RECARGO_COMPRAS_EMP',
                             'varchar(1) NOT NULL DEFAULT ''N''',
                             'ESRETENCIONES_EMP');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_proveedores',
                             'ESVARIOS_TIPOS_IVA_PRV',
                             'varchar(1) NOT NULL DEFAULT ''N''',
                             'PORCENTAJE_MARGEN_PRV');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'CODIGO_IVA_SES',
                             'varchar(20) NULL DEFAULT NULL',
                             'TIPO_IVA_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'ESVARIOS_TIPOS_IVA_SES',
                             'varchar(1) NOT NULL DEFAULT ''N''',
                             'CODIGO_IVA_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'ESIVA_RECARGO_COMPRAS_SES',
                             'varchar(1) NOT NULL DEFAULT ''N''',
                             'ESVARIOS_TIPOS_IVA_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_IVAN_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'ESIVA_RECARGO_COMPRAS_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_BASEI_IVAN_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_IVAN_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_IVAN_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_BASEI_IVAN_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_REN_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_IVAN_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_REN_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_REN_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_IVAR_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_REN_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_BASEI_IVAR_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_IVAR_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_IVAR_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_BASEI_IVAR_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_RER_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_IVAR_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_RER_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_RER_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_IVAS_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_RER_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_BASEI_IVAS_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_IVAS_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_IVAS_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_BASEI_IVAS_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_RES_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_IVAS_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_RES_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_RES_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_IVAE_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_RES_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_BASEI_IVAE_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_IVAE_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_IVAE_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_BASEI_IVAE_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_REE_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_IVAE_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_REE_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_REE_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'PORCENTAJE_RETENCION_SES',
                             'decimal(19,6) NULL DEFAULT NULL',
                             'TOTAL_REE_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_RETENCION_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'PORCENTAJE_RETENCION_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_BRUTO_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_RETENCION_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_BASES_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_BRUTO_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_IMPUESTOS_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_BASES_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_IMPUESTOS_SES');
CALL PRC_TMP_ADD_COL_SES_IVA('fza_compras_sesiones',
                             'TOTAL_LIQUIDO_SES',
                             'decimal(18,6) NULL DEFAULT NULL',
                             'TOTAL_SES');

UPDATE fza_empresas
   SET ESIVA_RECARGO_COMPRAS_EMP = 'N'
 WHERE ESIVA_RECARGO_COMPRAS_EMP IS NULL
    OR ESIVA_RECARGO_COMPRAS_EMP = '';

UPDATE fza_proveedores
   SET ESVARIOS_TIPOS_IVA_PRV = 'N'
 WHERE ESVARIOS_TIPOS_IVA_PRV IS NULL
    OR ESVARIOS_TIPOS_IVA_PRV = '';

UPDATE fza_compras_sesiones s
  LEFT JOIN fza_proveedores p
         ON p.CODIGO_PRV_PRV = s.CODIGO_PRV_SES
   SET s.ESVARIOS_TIPOS_IVA_SES =
       COALESCE(NULLIF(p.ESVARIOS_TIPOS_IVA_PRV, ''), 'N')
 WHERE s.ESVARIOS_TIPOS_IVA_SES IS NULL
    OR s.ESVARIOS_TIPOS_IVA_SES = '';

UPDATE fza_compras_sesiones s
  LEFT JOIN fza_empresas e
         ON e.CODIGO_EMP_EMP = s.CODIGO_EMP_SES
   SET s.ESIVA_RECARGO_COMPRAS_SES =
       COALESCE(NULLIF(e.ESIVA_RECARGO_COMPRAS_EMP, ''), 'N')
 WHERE s.ESIVA_RECARGO_COMPRAS_SES IS NULL
    OR s.ESIVA_RECARGO_COMPRAS_SES = '';

DROP PROCEDURE IF EXISTS `PRC_TMP_ADD_COL_SES_IVA`;
