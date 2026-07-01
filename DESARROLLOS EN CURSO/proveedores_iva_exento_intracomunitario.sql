-- ============================================================================
-- IVA exento intracomunitario en proveedores y documentos de compra.
-- ============================================================================
-- Proveedor:
--   ESIVA_EXENTO_INTRACOMUNITARIO_PRV = 'S' cuando sus documentos de compra
--   deben tratarse como exentos por operacion intracomunitaria.
--
-- Documentos de compra:
--   Se copia el valor del proveedor a la cabecera para que el documento quede
--   fiscalmente cerrado aunque luego cambie la ficha del proveedor.
--
-- Idempotente:
--   - cada columna se crea solo si falta;
--   - las vistas se recrean para recoger los SELECT * congelados por MariaDB;
--   - el autollenado inicial solo se ejecuta la primera vez que se crea cada
--     columna.
-- ============================================================================

SET @c_prv := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_proveedores'
     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_PRV'
);
SET @s := IF(@c_prv = 0,
  'ALTER TABLE `fza_proveedores`
     ADD COLUMN `ESIVA_EXENTO_INTRACOMUNITARIO_PRV` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = IVA exento por proveedor intracomunitario''
     AFTER `ESVARIOS_TIPOS_IVA_PRV`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c_ses := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_compras_sesiones'
     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_SES'
);
SET @s := IF(@c_ses = 0,
  'ALTER TABLE `fza_compras_sesiones`
     ADD COLUMN `ESIVA_EXENTO_INTRACOMUNITARIO_SES` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = IVA exento por proveedor intracomunitario''
     AFTER `ESIVA_RECARGO_COMPRAS_SES`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c_pedc := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_pedidos_compra'
     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC'
);
SET @s := IF(@c_pedc = 0,
  'ALTER TABLE `fza_pedidos_compra`
     ADD COLUMN `ESIVA_EXENTO_INTRACOMUNITARIO_PEDC` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = IVA exento por proveedor intracomunitario''
     AFTER `ESIVA_RECARGO_COMPRAS_PEDC`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c_albc := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_albaranes_compra'
     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC'
);
SET @s := IF(@c_albc = 0,
  'ALTER TABLE `fza_albaranes_compra`
     ADD COLUMN `ESIVA_EXENTO_INTRACOMUNITARIO_ALBC` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = IVA exento por proveedor intracomunitario''
     AFTER `ESIVA_RECARGO_COMPRAS_ALBC`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c_facc := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_facturas_compra'
     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_FACC'
);
SET @s := IF(@c_facc = 0,
  'ALTER TABLE `fza_facturas_compra`
     ADD COLUMN `ESIVA_EXENTO_INTRACOMUNITARIO_FACC` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = IVA exento por proveedor intracomunitario''
     AFTER `ESIVA_RECARGO_COMPRAS_FACC`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c_devc := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_devoluciones_compra'
     AND COLUMN_NAME = 'ESIVA_EXENTO_INTRACOMUNITARIO_DEVC'
);
SET @s := IF(@c_devc = 0,
  'ALTER TABLE `fza_devoluciones_compra`
     ADD COLUMN `ESIVA_EXENTO_INTRACOMUNITARIO_DEVC` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = IVA exento por proveedor intracomunitario''
     AFTER `ESIVA_RECARGO_COMPRAS_DEVC`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

-- Marcar proveedores existentes de la UE no espanoles al crear la columna.
SET @s := IF(@c_prv = 0,
  'UPDATE fza_proveedores p
      JOIN fza_paises pai
        ON UPPER(TRIM(p.PAIS_PRV)) IN
           (UPPER(TRIM(pai.CODIGO_PAI_PAI)),
            UPPER(TRIM(pai.COD_ALPHA2_PAI)),
            UPPER(TRIM(pai.COD_ALPHA3_PAI)),
            UPPER(TRIM(pai.NOMBRE_SPA_PAI)),
            UPPER(TRIM(pai.NOMBRE_ENG_PAI)))
       SET p.ESIVA_EXENTO_INTRACOMUNITARIO_PRV =
           CASE WHEN IFNULL(pai.ESMIEMBRO_UE_PAI, ''N'') = ''S''
                 AND pai.CODIGO_PAI_PAI <> ''724''
                THEN ''S'' ELSE ''N'' END',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @s := IF(@c_ses = 0,
  'UPDATE fza_compras_sesiones s
      LEFT JOIN fza_proveedores p
        ON p.CODIGO_PRV_PRV = s.CODIGO_PRV_SES
       SET s.ESIVA_EXENTO_INTRACOMUNITARIO_SES =
           IFNULL(NULLIF(p.ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''''), ''N'')',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @s := IF(@c_pedc = 0,
  'UPDATE fza_pedidos_compra d
      LEFT JOIN fza_proveedores p
        ON p.CODIGO_PRV_PRV = d.CODIGO_PRV_PEDC
       SET d.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC =
           IFNULL(NULLIF(p.ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''''), ''N'')',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @s := IF(@c_albc = 0,
  'UPDATE fza_albaranes_compra d
      LEFT JOIN fza_proveedores p
        ON p.CODIGO_PRV_PRV = d.CODIGO_PRV_ALBC
       SET d.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC =
           IFNULL(NULLIF(p.ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''''), ''N'')',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @s := IF(@c_facc = 0,
  'UPDATE fza_facturas_compra d
      LEFT JOIN fza_proveedores p
        ON p.CODIGO_PRV_PRV = d.CODIGO_PRV_FACC
       SET d.ESIVA_EXENTO_INTRACOMUNITARIO_FACC =
           IFNULL(NULLIF(p.ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''''), ''N'')',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @s := IF(@c_devc = 0,
  'UPDATE fza_devoluciones_compra d
      LEFT JOIN fza_proveedores p
        ON p.CODIGO_PRV_PRV = d.CODIGO_PRV_DEVC
       SET d.ESIVA_EXENTO_INTRACOMUNITARIO_DEVC =
           IFNULL(NULLIF(p.ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''''), ''N'')',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

CREATE OR REPLACE VIEW `vi_proveedores` AS
SELECT p.*
  FROM `fza_proveedores` p
 ORDER BY p.`ORDEN_PRV`;

CREATE OR REPLACE VIEW `vi_proveedores_busquedas` AS
SELECT p.*
  FROM `fza_proveedores` p
 WHERE p.`ESACTIVO_PRV` = 'S'
 ORDER BY p.`ORDEN_PRV`;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_compras_sesiones` AS
SELECT s.*,
       prv.`RAZON_SOCIAL_PRV` AS `RAZON_SOCIAL_PRV_SES`,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_SES`
  FROM `fza_compras_sesiones` s
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = s.`CODIGO_PRV_SES`;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_pedidos_compra` AS
SELECT p.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_PEDC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_PEDC`,
       t.`PV` AS `TEMPORADA_PEDC`
  FROM `fza_pedidos_compra` p
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = p.`CODIGO_PRV_PEDC`
  LEFT JOIN `fza_empresas` emp
    ON emp.`CODIGO_EMP_EMP` = p.`CODIGO_EMP_PEDC`
  LEFT JOIN `fza_propiedades_valores` t
    ON t.`ID_PV_ARTPROP` = p.`ID_PV_TEMPORADA_PEDC`
   AND t.`ID_PROP_PV` = 'TEMPORADA';

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_albaranes_compra` AS
SELECT a.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_ALBC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_ALBC`
  FROM `fza_albaranes_compra` a
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = a.`CODIGO_PRV_ALBC`
  LEFT JOIN `fza_empresas` emp
    ON emp.`CODIGO_EMP_EMP` = a.`CODIGO_EMP_ALBC`;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_facturas_compra` AS
SELECT f.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_VIEW_FACC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_FACC`
  FROM `fza_facturas_compra` f
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = f.`CODIGO_PRV_FACC`
  LEFT JOIN `fza_empresas` emp
    ON emp.`CODIGO_EMP_EMP` = f.`CODIGO_EMP_FACC`;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_devoluciones_compra` AS
SELECT d.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_DEVC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_DEVC`
  FROM `fza_devoluciones_compra` d
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = d.`CODIGO_PRV_DEVC`
  LEFT JOIN `fza_empresas` emp
    ON emp.`CODIGO_EMP_EMP` = d.`CODIGO_EMP_DEVC`;

DROP PROCEDURE IF EXISTS `PRC_FACC_RECALCULAR_TOTALES`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FACC_RECALCULAR_TOTALES`(
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20))
BEGIN
  DECLARE v_baseN, v_baseR, v_baseS, v_baseE decimal(18,6) DEFAULT 0;
  DECLARE v_ivaN, v_ivaR, v_ivaS decimal(18,6) DEFAULT 0;
  DECLARE v_reN, v_reR, v_reS, v_reE decimal(18,6) DEFAULT 0;
  DECLARE v_pN, v_pR, v_pS decimal(19,6) DEFAULT 0;
  DECLARE v_prN, v_prR, v_prS, v_prE decimal(19,6) DEFAULT 0;
  DECLARE v_suma_bases, v_impuestos, v_total decimal(18,6) DEFAULT 0;
  DECLARE v_reten, v_liquido, v_pRet decimal(18,6) DEFAULT 0;
  DECLARE v_dto, v_pp, v_rap, v_fin, v_por decimal(18,6) DEFAULT 0;
  DECLARE v_codIva varchar(20) DEFAULT '';
  DECLARE v_aplicaRe varchar(1) DEFAULT 'N';
  DECLARE v_exento varchar(1) DEFAULT 'N';
  SELECT COALESCE(NULLIF(ESIVA_RECARGO_COMPRAS_FACC, ''), 'N'),
         COALESCE(NULLIF(ESIVA_EXENTO_INTRACOMUNITARIO_FACC, ''), 'N'),
         COALESCE(CODIGO_IVA_FACC, ''),
         COALESCE(PORCENTAJE_RETENCION_FACC, 0),
         COALESCE(TOTAL_DTO_COMERCIAL_FACC, 0),
         COALESCE(TOTAL_PRONTO_PAGO_FACC, 0),
         COALESCE(TOTAL_RAPPEL_FACC, 0),
         COALESCE(TOTAL_FINANCIACION_FACC, 0),
         COALESCE(TOTAL_PORTES_FACC, 0)
    INTO v_aplicaRe, v_exento, v_codIva, v_pRet,
         v_dto, v_pp, v_rap, v_fin, v_por
    FROM fza_facturas_compra
   WHERE SERIE_FACC = p_SERIE
     AND NUMERO_FACC = p_NUMERO;
  IF v_exento = 'S' THEN
    SET v_aplicaRe = 'N';
  END IF;
  SELECT COALESCE(PORCENTAJE_NORMAL_RE_IVA, 0),
         COALESCE(PORCENTAJE_REDUCIDO_RE_IVA, 0),
         COALESCE(PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0),
         COALESCE(PORCENTAJE_EXENTO_RE_IVA, 0)
    INTO v_prN, v_prR, v_prS, v_prE
    FROM fza_ivas
   WHERE CODIGO_IVA = v_codIva;
  SELECT COALESCE(SUM(CASE WHEN TIPO = 'N' THEN TOTAL_FACCLIN END), 0),
         COALESCE(SUM(CASE WHEN TIPO = 'R' THEN TOTAL_FACCLIN END), 0),
         COALESCE(SUM(CASE WHEN TIPO = 'S' THEN TOTAL_FACCLIN END), 0),
         COALESCE(SUM(CASE WHEN TIPO = 'E' THEN TOTAL_FACCLIN END), 0),
         COALESCE(SUM(CASE WHEN TIPO = 'N'
                           THEN TOTAL_FACCLIN * PORCENTAJE_EFECTIVO / 100
                      END), 0),
         COALESCE(SUM(CASE WHEN TIPO = 'R'
                           THEN TOTAL_FACCLIN * PORCENTAJE_EFECTIVO / 100
                      END), 0),
         COALESCE(SUM(CASE WHEN TIPO = 'S'
                           THEN TOTAL_FACCLIN * PORCENTAJE_EFECTIVO / 100
                      END), 0),
         COALESCE(MAX(CASE WHEN TIPO = 'N'
                           THEN PORCENTAJE_EFECTIVO END), 0),
         COALESCE(MAX(CASE WHEN TIPO = 'R'
                           THEN PORCENTAJE_EFECTIVO END), 0),
         COALESCE(MAX(CASE WHEN TIPO = 'S'
                           THEN PORCENTAJE_EFECTIVO END), 0)
    INTO v_baseN, v_baseR, v_baseS, v_baseE,
         v_ivaN, v_ivaR, v_ivaS, v_pN, v_pR, v_pS
    FROM (
      SELECT TOTAL_FACCLIN,
             CASE WHEN v_exento = 'S'
                  THEN 0 ELSE PORCENTAJE_IVA_FACCLIN END AS PORCENTAJE_EFECTIVO,
             CASE
               WHEN v_exento = 'S' THEN 'E'
               WHEN COALESCE(TIPO_IVA_ARTICULO_FACCLIN, '') IN ('N','R','S','E')
                 THEN TIPO_IVA_ARTICULO_FACCLIN
               WHEN COALESCE(PORCENTAJE_IVA_FACCLIN, 0) <= 0 THEN 'E'
               WHEN COALESCE(PORCENTAJE_IVA_FACCLIN, 0) < 6 THEN 'S'
               WHEN COALESCE(PORCENTAJE_IVA_FACCLIN, 0) < 13 THEN 'R'
               ELSE 'N'
             END AS TIPO
        FROM fza_facturas_compra_lineas
       WHERE SERIE_FACC_FACCLIN = p_SERIE
         AND NUMERO_FACC_FACCLIN = p_NUMERO
    ) x;
  IF v_aplicaRe = 'S' THEN
    SET v_reN = v_baseN * v_prN / 100;
    SET v_reR = v_baseR * v_prR / 100;
    SET v_reS = v_baseS * v_prS / 100;
    SET v_reE = v_baseE * v_prE / 100;
  END IF;
  SET v_suma_bases = v_baseN + v_baseR + v_baseS + v_baseE;
  SET v_impuestos = v_ivaN + v_ivaR + v_ivaS + v_reN + v_reR + v_reS + v_reE;
  SET v_total = v_suma_bases + v_impuestos;
  SET v_reten = ROUND(v_suma_bases * v_pRet / 100, 2);
  SET v_liquido = v_total - v_reten - v_dto - v_pp - v_rap + v_fin + v_por;
  UPDATE fza_facturas_compra
     SET PORCENTAJE_IVAN_FACC = v_pN,
         TOTAL_BASEI_IVAN_FACC = v_baseN,
         TOTAL_IVAN_FACC = v_ivaN,
         PORCENTAJE_REN_FACC = v_prN,
         TOTAL_REN_FACC = v_reN,
         PORCENTAJE_IVAR_FACC = v_pR,
         TOTAL_BASEI_IVAR_FACC = v_baseR,
         TOTAL_IVAR_FACC = v_ivaR,
         PORCENTAJE_RER_FACC = v_prR,
         TOTAL_RER_FACC = v_reR,
         PORCENTAJE_IVAS_FACC = v_pS,
         TOTAL_BASEI_IVAS_FACC = v_baseS,
         TOTAL_IVAS_FACC = v_ivaS,
         PORCENTAJE_RES_FACC = v_prS,
         TOTAL_RES_FACC = v_reS,
         PORCENTAJE_IVAE_FACC = 0,
         TOTAL_BASEI_IVAE_FACC = v_baseE,
         TOTAL_IVAE_FACC = 0,
         PORCENTAJE_REE_FACC = v_prE,
         TOTAL_REE_FACC = v_reE,
         TOTAL_BRUTO_FACC = v_suma_bases,
         TOTAL_BASES_FACC = v_suma_bases,
         TOTAL_IMPUESTOS_FACC = v_impuestos,
         TOTAL_FACC = v_total,
         TOTAL_RETENCION_FACC = v_reten,
         TOTAL_LIQUIDO_FACC = v_liquido
   WHERE SERIE_FACC = p_SERIE
     AND NUMERO_FACC = p_NUMERO;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FACC_FACTURAR_ALBARAN`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FACC_FACTURAR_ALBARAN`(
  IN p_SERIE_ALB varchar(20),
  IN p_NUMERO_ALB varchar(20),
  IN p_SERIE_FAC varchar(20),
  IN p_NUMERO_FAC varchar(20),
  IN p_USUARIO varchar(100),
  OUT p_SERIE_FAC_OUT varchar(20),
  OUT p_NUMERO_FAC_OUT varchar(20),
  OUT p_RESULTADO int)
BEGIN
  DECLARE v_existe int DEFAULT 0;
  DECLARE v_prv_alb varchar(20);
  DECLARE v_emp_alb varchar(8);
  DECLARE v_re_alb varchar(1);
  DECLARE v_exento_alb varchar(1);
  DECLARE v_prv_fac varchar(20);
  DECLARE v_emp_fac varchar(8);
  DECLARE v_re_fac varchar(1);
  DECLARE v_exento_fac varchar(1);
  DECLARE v_cont bigint DEFAULT 0;
  DECLARE v_nlineas int DEFAULT 0;
  DECLARE v_nro bigint DEFAULT 0;
  DECLARE v_serie varchar(3);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  SELECT COUNT(*), MAX(CODIGO_PRV_ALBC), MAX(CODIGO_EMP_ALBC),
         MAX(COALESCE(NULLIF(ESIVA_RECARGO_COMPRAS_ALBC, ''), 'N')),
         MAX(COALESCE(NULLIF(ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''), 'N'))
    INTO v_existe, v_prv_alb, v_emp_alb, v_re_alb, v_exento_alb
    FROM fza_albaranes_compra
   WHERE SERIE_ALBC = p_SERIE_ALB
     AND NUMERO_ALBC = p_NUMERO_ALB
     AND COALESCE(ESTADO_ALBC, '') NOT IN ('FACTURADO', 'CANCELADO');
  IF v_existe > 0 THEN
    START TRANSACTION;
    IF p_NUMERO_FAC IS NULL OR p_NUMERO_FAC = '' THEN
      CALL PRC_FNC_GET_NEXT_NRO_DOC('FP', v_nro);
      CALL PRC_FNC_GET_SERIE_TIPODOC('FP', v_serie);
      SET p_NUMERO_FAC_OUT = LPAD(v_nro, 6, '0');
      SET p_SERIE_FAC_OUT = v_serie;
      INSERT INTO fza_facturas_compra
        (NUMERO_FACC, SERIE_FACC, FECHA_FACC, ESTADO_FACC,
         CODIGO_EMP_FACC, RAZON_SOCIAL_EMPRESA_FACC, NIF_EMPRESA_FACC,
         MOVIL_EMPRESA_FACC, EMAIL_EMPRESA_FACC, DIRECCION1_EMPRESA_FACC,
         DIRECCION2_EMPRESA_FACC, POBLACION_EMPRESA_FACC,
         PROVINCIA_EMPRESA_FACC, CODIGO_PAI_EMPRESA_FACC,
         NOMBRE_PAI_EMPRESA_FACC, CODIGO_POSTAL_EMPRESA_FACC,
         CODIGO_PRV_FACC, RAZON_SOCIAL_PRV_FACC, NIF_PRV_FACC,
         MOVIL_PRV_FACC, EMAIL_PRV_FACC, DIRECCION1_PRV_FACC,
         DIRECCION2_PRV_FACC, POBLACION_PRV_FACC, PROVINCIA_PRV_FACC,
         CODIGO_PAI_PRV_FACC, NOMBRE_PAI_PRV_FACC, CODIGO_POSTAL_PRV_FACC,
         CODIGO_ALM_FACC, CODIGO_IVA_FACC, ESIVA_RECARGO_COMPRAS_FACC,
         ESIVA_EXENTO_INTRACOMUNITARIO_FACC,
         PORCENTAJE_IVAN_FACC, PORCENTAJE_IVAR_FACC,
         PORCENTAJE_IVAS_FACC, PORCENTAJE_IVAE_FACC,
         PORCENTAJE_REN_FACC, PORCENTAJE_RER_FACC,
         PORCENTAJE_RES_FACC, PORCENTAJE_REE_FACC,
         PORCENTAJE_RETENCION_FACC, FORMA_PAGO_FACC,
         ESAGRUPAR_ALBARANES_FACC, CONTADOR_LINEAS_FACC,
         INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
      SELECT p_NUMERO_FAC_OUT, p_SERIE_FAC_OUT, CURDATE(), 'ABIERTA',
         CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC,
         MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, DIRECCION1_EMPRESA_ALBC,
         DIRECCION2_EMPRESA_ALBC, POBLACION_EMPRESA_ALBC,
         PROVINCIA_EMPRESA_ALBC, CODIGO_PAI_EMPRESA_ALBC,
         NOMBRE_PAI_EMPRESA_ALBC, CODIGO_POSTAL_EMPRESA_ALBC,
         CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC,
         MOVIL_PRV_ALBC, EMAIL_PRV_ALBC, DIRECCION1_PRV_ALBC,
         DIRECCION2_PRV_ALBC, POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC,
         CODIGO_PAI_PRV_ALBC, NOMBRE_PAI_PRV_ALBC, CODIGO_POSTAL_PRV_ALBC,
         CODIGO_ALM_ALBC, CODIGO_IVA_ALBC,
         COALESCE(NULLIF(ESIVA_RECARGO_COMPRAS_ALBC, ''), 'N'),
         COALESCE(NULLIF(ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''), 'N'),
         PORCENTAJE_IVAN_ALBC, PORCENTAJE_IVAR_ALBC,
         PORCENTAJE_IVAS_ALBC, PORCENTAJE_IVAE_ALBC,
         PORCENTAJE_REN_ALBC, PORCENTAJE_RER_ALBC,
         PORCENTAJE_RES_ALBC, PORCENTAJE_REE_ALBC,
         PORCENTAJE_RETENCION_ALBC, FORMA_PAGO_ALBC,
         'S', '0', NOW(), p_USUARIO, NOW(), p_USUARIO
        FROM fza_albaranes_compra
       WHERE SERIE_ALBC = p_SERIE_ALB
         AND NUMERO_ALBC = p_NUMERO_ALB;
      SET v_existe = 1;
    ELSE
      SELECT COUNT(*), MAX(CODIGO_PRV_FACC), MAX(CODIGO_EMP_FACC),
             MAX(COALESCE(NULLIF(ESIVA_RECARGO_COMPRAS_FACC, ''), v_re_alb)),
             MAX(COALESCE(NULLIF(ESIVA_EXENTO_INTRACOMUNITARIO_FACC, ''),
                          v_exento_alb))
        INTO v_existe, v_prv_fac, v_emp_fac, v_re_fac, v_exento_fac
        FROM fza_facturas_compra
       WHERE SERIE_FACC = p_SERIE_FAC
         AND NUMERO_FACC = p_NUMERO_FAC;
      IF v_existe > 0
         AND COALESCE(v_prv_fac, '') = COALESCE(v_prv_alb, '')
         AND COALESCE(v_emp_fac, '') = COALESCE(v_emp_alb, '')
         AND COALESCE(v_re_fac, 'N') = COALESCE(v_re_alb, 'N')
         AND COALESCE(v_exento_fac, 'N') = COALESCE(v_exento_alb, 'N') THEN
        SET p_SERIE_FAC_OUT = p_SERIE_FAC;
        SET p_NUMERO_FAC_OUT = p_NUMERO_FAC;
        UPDATE fza_facturas_compra
           SET ESIVA_RECARGO_COMPRAS_FACC =
               COALESCE(NULLIF(ESIVA_RECARGO_COMPRAS_FACC, ''), v_re_alb),
               ESIVA_EXENTO_INTRACOMUNITARIO_FACC =
               COALESCE(NULLIF(ESIVA_EXENTO_INTRACOMUNITARIO_FACC, ''),
                        v_exento_alb)
         WHERE SERIE_FACC = p_SERIE_FAC_OUT
           AND NUMERO_FACC = p_NUMERO_FAC_OUT;
      ELSE
        SET v_existe = 0;
      END IF;
    END IF;
    IF v_existe > 0 THEN
      SELECT CAST(COALESCE(NULLIF(CONTADOR_LINEAS_FACC, ''), '0')
                  AS UNSIGNED)
        INTO v_cont
        FROM fza_facturas_compra
       WHERE SERIE_FACC = p_SERIE_FAC_OUT
         AND NUMERO_FACC = p_NUMERO_FAC_OUT;
      INSERT INTO fza_facturas_compra_lineas
        (NUMERO_FACC_FACCLIN, SERIE_FACC_FACCLIN, LINEA_FACCLIN,
         NUMERO_ALBC_FACCLIN, SERIE_ALBC_FACCLIN, LINEA_ALBC_FACCLIN,
         CODIGO_ART_FACCLIN, CODIGO_UNIDAD_FACCLIN, REF_PRV_FACCLIN,
         ID_AC_PIVOT_FACCLIN, CODIGO_FAM_FACCLIN, NOMBRE_FAM_FACCLIN,
         DESCRIPCION_ARTICULO_FACCLIN, TIPO_CANTIDAD_ARTICULO_FACCLIN,
         CANTIDAD_FACCLIN, TOTAL_UNIDADES_FACCLIN,
         TIPO_IVA_ARTICULO_FACCLIN, PORCENTAJE_IVA_FACCLIN,
         PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN,
         PRECIO_COMPRA_CIVA_ARTICULO_FACCLIN, TOTAL_FACCLIN,
         CODIGO_ALMACEN_FACCLIN, LOTE_FACCLIN, FECHA_CADUCIDAD_FACCLIN,
         DESCRIPCION_VARIACION_FACCLIN,
         INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
      SELECT p_NUMERO_FAC_OUT, p_SERIE_FAC_OUT,
         LPAD(v_cont + 10 * ROW_NUMBER() OVER (ORDER BY LINEA_ALBCLIN),
              4, '0'),
         NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN,
         CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN,
         ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN,
         DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN,
         CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN,
         CASE WHEN v_exento_alb = 'S'
              THEN 'E' ELSE TIPO_IVA_ARTICULO_ALBCLIN END,
         CASE WHEN v_exento_alb = 'S'
              THEN 0 ELSE PORCENTAJE_IVA_ALBCLIN END,
         PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN,
         CASE WHEN v_exento_alb = 'S'
              THEN PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN
              ELSE PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN END,
         TOTAL_ALBCLIN,
         CODIGO_ALMACEN_ALBCLIN, LOTE_ALBCLIN, FECHA_CADUCIDAD_ALBCLIN,
         DESCRIPCION_VARIACION_ALBCLIN,
         NOW(), p_USUARIO, NOW(), p_USUARIO
        FROM fza_albaranes_compra_lineas
       WHERE SERIE_ALBC_ALBCLIN = p_SERIE_ALB
         AND NUMERO_ALBC_ALBCLIN = p_NUMERO_ALB;
      SET v_nlineas = ROW_COUNT();
      UPDATE fza_facturas_compra
         SET CONTADOR_LINEAS_FACC = CAST(v_cont + 10 * v_nlineas AS CHAR),
             USUARIO_MODIF = p_USUARIO
       WHERE SERIE_FACC = p_SERIE_FAC_OUT
         AND NUMERO_FACC = p_NUMERO_FAC_OUT;
      UPDATE fza_albaranes_compra_lineas
         SET ESFACTURADA_ALBCLIN = 'S',
             NUMERO_FAC_ALBCLIN = p_NUMERO_FAC_OUT,
             SERIE_FAC_ALBCLIN = p_SERIE_FAC_OUT,
             USUARIO_MODIF = p_USUARIO
       WHERE SERIE_ALBC_ALBCLIN = p_SERIE_ALB
         AND NUMERO_ALBC_ALBCLIN = p_NUMERO_ALB;
      UPDATE fza_albaranes_compra
         SET ESTADO_ALBC = 'FACTURADO',
             NUMERO_FAC_ALBC = p_NUMERO_FAC_OUT,
             SERIE_FAC_ALBC = p_SERIE_FAC_OUT,
             USUARIO_MODIF = p_USUARIO
       WHERE SERIE_ALBC = p_SERIE_ALB
         AND NUMERO_ALBC = p_NUMERO_ALB;
      CALL PRC_FACC_RECALCULAR_TOTALES(p_SERIE_FAC_OUT, p_NUMERO_FAC_OUT);
      SET p_RESULTADO = 1;
    END IF;
    COMMIT;
  END IF;
END ;;
DELIMITER ;
