-- =============================================================================
-- Formato visible de documentos por empresa.
--
-- Anade FORMATO_DOCUMENTO_EMP a fza_empresas y expone DOCUMENTO_FORMATO en
-- las vistas de impresion. No altera factuzam_original.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Parametro de empresa
-- ---------------------------------------------------------------------------
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas'
     AND COLUMN_NAME = 'FORMATO_DOCUMENTO_EMP'
);

SET @sSql := IF(
  @sExisteCol = 0,
  'ALTER TABLE fza_empresas
     ADD COLUMN FORMATO_DOCUMENTO_EMP varchar(80) NOT NULL
       DEFAULT ''Serie.NroDocumento''
       COMMENT ''Formato visible de documentos. Tokens: Serie y NroDocumento''
       AFTER TEXTO_LEGAL_FACTURA_EMP',
  'SELECT ''FORMATO_DOCUMENTO_EMP ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE fza_empresas
   SET FORMATO_DOCUMENTO_EMP = 'Serie.NroDocumento'
 WHERE FORMATO_DOCUMENTO_EMP IS NULL
    OR FORMATO_DOCUMENTO_EMP = '';

-- ---------------------------------------------------------------------------
-- 2. Procedimiento comun de formato
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS FN_FORMATO_DOCUMENTO;
DROP PROCEDURE IF EXISTS PRC_FORMATO_DOCUMENTO;

DELIMITER ;;
CREATE PROCEDURE PRC_FORMATO_DOCUMENTO(
  IN p_FORMATO varchar(80),
  IN p_SERIE varchar(50),
  IN p_NUMERO varchar(50),
  OUT p_DOCUMENTO_FORMATO varchar(200)
)
BEGIN
  DECLARE v_formato varchar(80);
  DECLARE v_original varchar(200);
  DECLARE v_resultado varchar(200);
  DECLARE v_serie varchar(50);
  DECLARE v_numero varchar(50);

  SET v_serie = TRIM(COALESCE(p_SERIE, ''));
  SET v_numero = TRIM(COALESCE(p_NUMERO, ''));

  IF v_serie = '' THEN
    SET p_DOCUMENTO_FORMATO = v_numero;
  ELSEIF v_numero = '' THEN
    SET p_DOCUMENTO_FORMATO = v_serie;
  ELSE
    SET v_formato = NULLIF(TRIM(COALESCE(p_FORMATO, '')), '');

    IF v_formato IS NULL THEN
      SET v_formato = 'Serie.NroDocumento';
    END IF;

    SET v_resultado = v_formato;
    SET v_original = v_resultado;

    SET v_resultado = REPLACE(v_resultado, 'NroDocumento', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'nrodocumento', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NRODOCUMENTO', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NumeroDocumento', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'numerodocumento', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NUMERODOCUMENTO', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NúmeroDocumento', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'númerodocumento', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NÚMERODOCUMENTO', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NroFactura', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'nrofactura', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NROFACTURA', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NroDoc', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'nrodoc', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NRODOC', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'Numero', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'numero', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NUMERO', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'Número', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'número', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'NÚMERO', v_numero);
    SET v_resultado = REPLACE(v_resultado, 'Serie', v_serie);
    SET v_resultado = REPLACE(v_resultado, 'serie', v_serie);
    SET v_resultado = REPLACE(v_resultado, 'SERIE', v_serie);

    IF v_resultado = v_original THEN
      SET p_DOCUMENTO_FORMATO = CONCAT(v_serie, '.', v_numero);
    ELSE
      SET p_DOCUMENTO_FORMATO = v_resultado;
    END IF;
  END IF;
END;;
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 3. Empresas
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 4. Facturas emitidas
-- ---------------------------------------------------------------------------
-- Las vistas no pueden llamar al procedimiento; DOCUMENTO_FORMATO va en linea.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_facturas_print` AS
SELECT `fza_facturas`.*,
       `fza_formas_pago`.`DESCRIPCION_FORMA_PAGO_FP`
              AS `DESCRIPCION_FORMA_PAGO_FP`,
       `fza_formas_pago`.`ESCONTADO_FORMA_PAGO_FP`
              AS `ESCONTADO_FORMA_PAGO_FP`,
       (select group_concat(' ',
                 date_format(`fza_recibos`.`FECHA_VENCIMIENTO_RECIBO_REC`,
                             '%d/%m/%Y'),
                 '=> ',
                 format(`fza_recibos`.`EUROS_RECIBO_REC`, 2),
                 '€' separator ',')
          from `fza_recibos`
         where `fza_recibos`.`NUMERO_FAC_REC` = `fza_facturas`.`NUMERO_FAC`
           and `fza_recibos`.`SERIE_FAC_REC`  = `fza_facturas`.`SERIE_FAC`)
              AS `VENCIMIENTOS_RECIBOS`,
       `fza_empresas`.`IBAN_EMP` AS `IBAN_EMP`,
       `fza_empresas`.`FORMATO_DOCUMENTO_EMP` AS `FORMATO_DOCUMENTO_EMP`,
       CASE WHEN TRIM(COALESCE(`fza_facturas`.`SERIE_FAC`, '')) = '' THEN TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, '')) WHEN TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, '')) = '' THEN TRIM(COALESCE(`fza_facturas`.`SERIE_FAC`, '')) WHEN NOT (INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'serie') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'númerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrofactura') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodoc') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numero') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'número') > 0) THEN CONCAT(TRIM(COALESCE(`fza_facturas`.`SERIE_FAC`, '')), '.', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))) ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(NULLIF(TRIM(COALESCE(`fza_empresas`.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento'), 'NroDocumento', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'nrodocumento', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NRODOCUMENTO', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NumeroDocumento', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'numerodocumento', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NUMERODOCUMENTO', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NúmeroDocumento', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'númerodocumento', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NÚMERODOCUMENTO', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NroFactura', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'nrofactura', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NROFACTURA', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NroDoc', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'nrodoc', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NRODOC', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'Numero', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'numero', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NUMERO', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'Número', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'número', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'NÚMERO', TRIM(COALESCE(`fza_facturas`.`NUMERO_FAC`, ''))), 'Serie', TRIM(COALESCE(`fza_facturas`.`SERIE_FAC`, ''))), 'serie', TRIM(COALESCE(`fza_facturas`.`SERIE_FAC`, ''))), 'SERIE', TRIM(COALESCE(`fza_facturas`.`SERIE_FAC`, ''))) END
              AS `DOCUMENTO_FORMATO`,
       `fza_clientes`.`IBAN_CLI` AS `IBAN_CLI`,
       `fza_formas_pago`.`ESVERBANCOEMPRESA_FORMA_PAGO_FP`
              AS `ESVERBANCOEMPRESA_FORMA_PAGO_FP`,
       `c`.`ID_FACCON`                          AS `ID_FACCON`,
       `c`.`REQUEST_ID_CONSOLIDACION_FACCON`    AS `REQUEST_ID_CONSOLIDACION_FACCON`,
       `c`.`ISSUER_IRS_ID_CONSOLIDACION_FACCON` AS `ISSUER_IRS_ID_CONSOLIDACION_FACCON`,
       `c`.`ISSUED_TIME_FACCON`                 AS `ISSUED_TIME_FACCON`,
       `c`.`CHAIN_NUMBER_FACCON`                AS `CHAIN_NUMBER_FACCON`,
       `c`.`CHAIN_HASH_FACCON`                  AS `CHAIN_HASH_FACCON`,
       `c`.`VERIFACTU_URL_FACCON`               AS `VERIFACTU_URL_FACCON`,
       `c`.`QRCODE_BASE64_FACCON`               AS `QRCODE_BASE64_FACCON`,
       `c`.`QRCODE_PNG_FACCON`                  AS `QRCODE_PNG_FACCON`,
       `c`.`FECHA_PROCESAMIENTO_FACCON`         AS `FECHA_PROCESAMIENTO_FACCON`,
       `c`.`ESTADO_FACCON`                      AS `ESTADO_FACCON`
  from ((((`fza_facturas`
       left join `fza_formas_pago`
              on(`fza_facturas`.`FORMA_PAGO_FAC` =
                 `fza_formas_pago`.`CODIGO_FP_FP`))
       left join `fza_empresas`
              on(`fza_facturas`.`CODIGO_EMP_FAC` =
                 `fza_empresas`.`CODIGO_EMP_EMP`))
       left join `fza_clientes`
              on(`fza_facturas`.`CODIGO_CLI_FAC` =
                 `fza_clientes`.`CODIGO_CLI_CLI`))
       left join `fza_facturas_consolidaciones` `c`
              on(`c`.`SERIE_FAC_FACCON`  = `fza_facturas`.`SERIE_FAC`
             and `c`.`NUMERO_FAC_FACCON` = `fza_facturas`.`NUMERO_FAC`))
 order by `fza_facturas`.`FECHA_FAC` desc;

-- ---------------------------------------------------------------------------
-- 5. Compras: sesiones, albaranes y devoluciones
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_compras_sesiones_cab_print` AS
SELECT
  ses.`SERIE_SES`,
  ses.`NUMERO_SES`,
  ses.`FECHA_SES`,
  ses.`ESTADO_SES`,
  ses.`REF_PRV_SES`,
  ses.`COMENTARIOS_SES`,
  ses.`PORCENTAJE_MARGEN_SES`,
  ses.`MULTIPLO_REDONDEO_SES`,
  ses.`AJUSTE_FINAL_SES`,
  ses.`MONEDA_SES`,
  ses.`TIPO_IVA_SES`,
  ses.`CODIGO_IVA_SES`,
  ses.`ESVARIOS_TIPOS_IVA_SES`,
  ses.`ESIVA_RECARGO_COMPRAS_SES`,
  ses.`PORCENTAJE_IVAN_SES`,
  ses.`TOTAL_BASEI_IVAN_SES`,
  ses.`TOTAL_IVAN_SES`,
  ses.`PORCENTAJE_REN_SES`,
  ses.`TOTAL_REN_SES`,
  ses.`PORCENTAJE_IVAR_SES`,
  ses.`TOTAL_BASEI_IVAR_SES`,
  ses.`TOTAL_IVAR_SES`,
  ses.`PORCENTAJE_RER_SES`,
  ses.`TOTAL_RER_SES`,
  ses.`PORCENTAJE_IVAS_SES`,
  ses.`TOTAL_BASEI_IVAS_SES`,
  ses.`TOTAL_IVAS_SES`,
  ses.`PORCENTAJE_RES_SES`,
  ses.`TOTAL_RES_SES`,
  ses.`PORCENTAJE_IVAE_SES`,
  ses.`TOTAL_BASEI_IVAE_SES`,
  ses.`TOTAL_IVAE_SES`,
  ses.`PORCENTAJE_REE_SES`,
  ses.`TOTAL_REE_SES`,
  ses.`PORCENTAJE_RETENCION_SES`,
  ses.`TOTAL_RETENCION_SES`,
  ses.`TOTAL_BRUTO_SES`,
  ses.`TOTAL_BASES_SES`,
  ses.`TOTAL_IMPUESTOS_SES`,
  ses.`TOTAL_SES`,
  ses.`TOTAL_LIQUIDO_SES`,
  ses.`ESFORMATO_DISTRIBUIDO_SES`,
  ses.`CODIGO_EMP_SES`,
  emp.`FORMATO_DOCUMENTO_EMP`,
  CASE WHEN TRIM(COALESCE(ses.`SERIE_SES`, '')) = '' THEN TRIM(COALESCE(ses.`NUMERO_SES`, '')) WHEN TRIM(COALESCE(ses.`NUMERO_SES`, '')) = '' THEN TRIM(COALESCE(ses.`SERIE_SES`, '')) WHEN NOT (INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'serie') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'númerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrofactura') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodoc') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numero') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'número') > 0) THEN CONCAT(TRIM(COALESCE(ses.`SERIE_SES`, '')), '.', TRIM(COALESCE(ses.`NUMERO_SES`, ''))) ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento'), 'NroDocumento', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'nrodocumento', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NRODOCUMENTO', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NumeroDocumento', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'numerodocumento', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NUMERODOCUMENTO', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NúmeroDocumento', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'númerodocumento', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NÚMERODOCUMENTO', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NroFactura', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'nrofactura', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NROFACTURA', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NroDoc', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'nrodoc', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NRODOC', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'Numero', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'numero', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NUMERO', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'Número', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'número', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'NÚMERO', TRIM(COALESCE(ses.`NUMERO_SES`, ''))), 'Serie', TRIM(COALESCE(ses.`SERIE_SES`, ''))), 'serie', TRIM(COALESCE(ses.`SERIE_SES`, ''))), 'SERIE', TRIM(COALESCE(ses.`SERIE_SES`, ''))) END AS `DOCUMENTO_FORMATO`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  ses.`CODIGO_PRV_SES`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  ses.`CODIGO_TAR_SES`,
  ses.`CODIGO_FAM_SES`,
  ses.`CODIGO_ALM_SES`,
  ses.`INSTANTE_ALTA`,
  ses.`USUARIO_ALTA`,
  (SELECT COALESCE(SUM(`TOTAL_UNIDADES_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `TOTAL_UNIDADES_SES`,
  (SELECT COALESCE(SUM(`TOTAL_LINEA_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `TOTAL_LINEAS_SES`,
  (SELECT COUNT(*)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `NUM_LINEAS_SES`
FROM `fza_compras_sesiones` ses
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = ses.`CODIGO_EMP_SES`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = ses.`CODIGO_PRV_SES`;

CREATE OR REPLACE VIEW `vi_albaranes_compra_cab_print` AS
SELECT
  alb.`SERIE_ALBC`,
  alb.`NUMERO_ALBC`,
  alb.`FECHA_ALBC`,
  alb.`ESTADO_ALBC`,
  alb.`REF_PROVEEDOR_ALBC`,
  alb.`COMENTARIOS_ALBC`,
  alb.`OBSERVACIONES_ALBC`,
  alb.`CODIGO_EMP_ALBC`,
  emp.`FORMATO_DOCUMENTO_EMP`,
  CASE WHEN TRIM(COALESCE(alb.`SERIE_ALBC`, '')) = '' THEN TRIM(COALESCE(alb.`NUMERO_ALBC`, '')) WHEN TRIM(COALESCE(alb.`NUMERO_ALBC`, '')) = '' THEN TRIM(COALESCE(alb.`SERIE_ALBC`, '')) WHEN NOT (INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'serie') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'númerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrofactura') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodoc') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numero') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'número') > 0) THEN CONCAT(TRIM(COALESCE(alb.`SERIE_ALBC`, '')), '.', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))) ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento'), 'NroDocumento', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'nrodocumento', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NRODOCUMENTO', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NumeroDocumento', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'numerodocumento', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NUMERODOCUMENTO', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NúmeroDocumento', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'númerodocumento', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NÚMERODOCUMENTO', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NroFactura', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'nrofactura', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NROFACTURA', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NroDoc', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'nrodoc', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NRODOC', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'Numero', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'numero', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NUMERO', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'Número', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'número', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'NÚMERO', TRIM(COALESCE(alb.`NUMERO_ALBC`, ''))), 'Serie', TRIM(COALESCE(alb.`SERIE_ALBC`, ''))), 'serie', TRIM(COALESCE(alb.`SERIE_ALBC`, ''))), 'SERIE', TRIM(COALESCE(alb.`SERIE_ALBC`, ''))) END AS `DOCUMENTO_FORMATO`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  alb.`CODIGO_PRV_ALBC`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  alb.`CODIGO_ALM_ALBC`,
  alm.`NOMBRE_ALM_ALM`  AS `NOMBRE_ALM_ALBC`,
  alm.`DIRECCION_ALM`   AS `DIRECCION_ALM_ALBC`,
  alm.`CODIGO_POSTAL_ALM` AS `CODIGO_POSTAL_ALM_ALBC`,
  alm.`POBLACION_ALM`   AS `POBLACION_ALM_ALBC`,
  alm.`PROVINCIA_ALM`   AS `PROVINCIA_ALM_ALBC`,
  alm.`TELEFONO_ALM`    AS `TELEFONO_ALM_ALBC`,
  alm.`EMAIL_ALM`       AS `EMAIL_ALM_ALBC`,
  alb.`CODIGO_IVA_ALBC`,
  alb.`ESIVA_RECARGO_COMPRAS_ALBC`,
  alb.`PORCENTAJE_IVAN_ALBC`,
  alb.`TOTAL_BASEI_IVAN_ALBC`,
  alb.`TOTAL_IVAN_ALBC`,
  alb.`PORCENTAJE_REN_ALBC`,
  alb.`TOTAL_REN_ALBC`,
  alb.`PORCENTAJE_IVAR_ALBC`,
  alb.`TOTAL_BASEI_IVAR_ALBC`,
  alb.`TOTAL_IVAR_ALBC`,
  alb.`PORCENTAJE_RER_ALBC`,
  alb.`TOTAL_RER_ALBC`,
  alb.`PORCENTAJE_IVAS_ALBC`,
  alb.`TOTAL_BASEI_IVAS_ALBC`,
  alb.`TOTAL_IVAS_ALBC`,
  alb.`PORCENTAJE_RES_ALBC`,
  alb.`TOTAL_RES_ALBC`,
  alb.`PORCENTAJE_IVAE_ALBC`,
  alb.`TOTAL_BASEI_IVAE_ALBC`,
  alb.`TOTAL_IVAE_ALBC`,
  alb.`PORCENTAJE_REE_ALBC`,
  alb.`TOTAL_REE_ALBC`,
  alb.`PORCENTAJE_RETENCION_ALBC`,
  alb.`TOTAL_RETENCION_ALBC`,
  alb.`TOTAL_BASES_ALBC`,
  alb.`TOTAL_IMPUESTOS_ALBC`,
  alb.`TOTAL_LIQUIDO_ALBC`,
  alb.`INSTANTE_ALTA`,
  alb.`USUARIO_ALTA`,
  (SELECT COALESCE(SUM(`CANTIDAD_ALBCLIN`), 0)
     FROM `fza_albaranes_compra_lineas` lin
    WHERE lin.`SERIE_ALBC_ALBCLIN`  = alb.`SERIE_ALBC`
      AND lin.`NUMERO_ALBC_ALBCLIN` = alb.`NUMERO_ALBC`) AS `TOTAL_UNIDADES_SES`,
  (SELECT COALESCE(SUM(`TOTAL_ALBCLIN`), 0)
     FROM `fza_albaranes_compra_lineas` lin
    WHERE lin.`SERIE_ALBC_ALBCLIN`  = alb.`SERIE_ALBC`
      AND lin.`NUMERO_ALBC_ALBCLIN` = alb.`NUMERO_ALBC`) AS `TOTAL_LINEAS_SES`,
  (SELECT COUNT(*)
     FROM `fza_albaranes_compra_lineas` lin
    WHERE lin.`SERIE_ALBC_ALBCLIN`  = alb.`SERIE_ALBC`
      AND lin.`NUMERO_ALBC_ALBCLIN` = alb.`NUMERO_ALBC`) AS `NUM_LINEAS_SES`
FROM `fza_albaranes_compra` alb
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = alb.`CODIGO_EMP_ALBC`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = alb.`CODIGO_PRV_ALBC`
LEFT JOIN `fza_almacenes`    alm ON alm.`CODIGO_ALM_ALM` = alb.`CODIGO_ALM_ALBC`;

CREATE OR REPLACE VIEW `vi_devoluciones_compra_cab_print` AS
SELECT
  alb.`SERIE_DEVC`,
  alb.`NUMERO_DEVC`,
  alb.`FECHA_DEVC`,
  alb.`ESTADO_DEVC`,
  alb.`REF_PROVEEDOR_DEVC`,
  alb.`COMENTARIOS_DEVC`,
  alb.`OBSERVACIONES_DEVC`,
  alb.`CODIGO_EMP_DEVC`,
  emp.`FORMATO_DOCUMENTO_EMP`,
  CASE WHEN TRIM(COALESCE(alb.`SERIE_DEVC`, '')) = '' THEN TRIM(COALESCE(alb.`NUMERO_DEVC`, '')) WHEN TRIM(COALESCE(alb.`NUMERO_DEVC`, '')) = '' THEN TRIM(COALESCE(alb.`SERIE_DEVC`, '')) WHEN NOT (INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'serie') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'númerodocumento') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrofactura') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'nrodoc') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'numero') > 0 OR INSTR(LOWER(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento')), 'número') > 0) THEN CONCAT(TRIM(COALESCE(alb.`SERIE_DEVC`, '')), '.', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))) ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(NULLIF(TRIM(COALESCE(emp.`FORMATO_DOCUMENTO_EMP`, '')), ''), 'Serie.NroDocumento'), 'NroDocumento', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'nrodocumento', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NRODOCUMENTO', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NumeroDocumento', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'numerodocumento', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NUMERODOCUMENTO', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NúmeroDocumento', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'númerodocumento', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NÚMERODOCUMENTO', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NroFactura', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'nrofactura', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NROFACTURA', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NroDoc', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'nrodoc', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NRODOC', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'Numero', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'numero', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NUMERO', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'Número', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'número', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'NÚMERO', TRIM(COALESCE(alb.`NUMERO_DEVC`, ''))), 'Serie', TRIM(COALESCE(alb.`SERIE_DEVC`, ''))), 'serie', TRIM(COALESCE(alb.`SERIE_DEVC`, ''))), 'SERIE', TRIM(COALESCE(alb.`SERIE_DEVC`, ''))) END AS `DOCUMENTO_FORMATO`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  alb.`CODIGO_PRV_DEVC`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  alb.`CODIGO_ALM_DEVC`,
  alm.`NOMBRE_ALM_ALM`  AS `NOMBRE_ALM_DEVC`,
  alm.`DIRECCION_ALM`   AS `DIRECCION_ALM_DEVC`,
  alm.`CODIGO_POSTAL_ALM` AS `CODIGO_POSTAL_ALM_DEVC`,
  alm.`POBLACION_ALM`   AS `POBLACION_ALM_DEVC`,
  alm.`PROVINCIA_ALM`   AS `PROVINCIA_ALM_DEVC`,
  alm.`TELEFONO_ALM`    AS `TELEFONO_ALM_DEVC`,
  alm.`EMAIL_ALM`       AS `EMAIL_ALM_DEVC`,
  alb.`CODIGO_IVA_DEVC`,
  alb.`ESIVA_RECARGO_COMPRAS_DEVC`,
  alb.`PORCENTAJE_IVAN_DEVC`,
  alb.`TOTAL_BASEI_IVAN_DEVC`,
  alb.`TOTAL_IVAN_DEVC`,
  alb.`PORCENTAJE_REN_DEVC`,
  alb.`TOTAL_REN_DEVC`,
  alb.`PORCENTAJE_IVAR_DEVC`,
  alb.`TOTAL_BASEI_IVAR_DEVC`,
  alb.`TOTAL_IVAR_DEVC`,
  alb.`PORCENTAJE_RER_DEVC`,
  alb.`TOTAL_RER_DEVC`,
  alb.`PORCENTAJE_IVAS_DEVC`,
  alb.`TOTAL_BASEI_IVAS_DEVC`,
  alb.`TOTAL_IVAS_DEVC`,
  alb.`PORCENTAJE_RES_DEVC`,
  alb.`TOTAL_RES_DEVC`,
  alb.`PORCENTAJE_IVAE_DEVC`,
  alb.`TOTAL_BASEI_IVAE_DEVC`,
  alb.`TOTAL_IVAE_DEVC`,
  alb.`PORCENTAJE_REE_DEVC`,
  alb.`TOTAL_REE_DEVC`,
  alb.`PORCENTAJE_RETENCION_DEVC`,
  alb.`TOTAL_RETENCION_DEVC`,
  alb.`TOTAL_BASES_DEVC`,
  alb.`TOTAL_IMPUESTOS_DEVC`,
  alb.`TOTAL_LIQUIDO_DEVC`,
  alb.`INSTANTE_ALTA`,
  alb.`USUARIO_ALTA`,
  (SELECT COALESCE(SUM(`CANTIDAD_DEVCLIN`), 0)
     FROM `fza_devoluciones_compra_lineas` lin
    WHERE lin.`SERIE_DEVC_DEVCLIN`  = alb.`SERIE_DEVC`
      AND lin.`NUMERO_DEVC_DEVCLIN` = alb.`NUMERO_DEVC`) AS `TOTAL_UNIDADES_SES`,
  (SELECT COALESCE(SUM(`TOTAL_DEVCLIN`), 0)
     FROM `fza_devoluciones_compra_lineas` lin
    WHERE lin.`SERIE_DEVC_DEVCLIN`  = alb.`SERIE_DEVC`
      AND lin.`NUMERO_DEVC_DEVCLIN` = alb.`NUMERO_DEVC`) AS `TOTAL_LINEAS_SES`,
  (SELECT COUNT(*)
     FROM `fza_devoluciones_compra_lineas` lin
    WHERE lin.`SERIE_DEVC_DEVCLIN`  = alb.`SERIE_DEVC`
      AND lin.`NUMERO_DEVC_DEVCLIN` = alb.`NUMERO_DEVC`) AS `NUM_LINEAS_SES`
FROM `fza_devoluciones_compra` alb
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = alb.`CODIGO_EMP_DEVC`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = alb.`CODIGO_PRV_DEVC`
LEFT JOIN `fza_almacenes`    alm ON alm.`CODIGO_ALM_ALM` = alb.`CODIGO_ALM_DEVC`;
