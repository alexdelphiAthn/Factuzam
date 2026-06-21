-- ============================================================================
-- Efectos de cobro a cliente, conciliacion y remesas
--
-- Espejo funcional de efectos_remesas_compra.sql para Venta Mayor:
--
--   factura de venta  --(efectos)-->  vencimientos de cobro / cobros
--                                            |
--                                   remesa (agrupa efectos)
--
-- Tablas:
--   fza_tipos_efecto       (TEFE)  catalogo comun de tipos de efecto
--   fza_efectos_venta      (EFV)   efectos de cobro a cliente
--   fza_remesas_venta      (REMV)  remesas de cobro
--
-- No modifica factuzam_original.sql. Idempotente por INFORMATION_SCHEMA.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Catalogo comun de tipos de efecto, si no existe.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_tipos_efecto` (
  `CODIGO_TEFE`        varchar(20)  NOT NULL,
  `DESCRIPCION_TEFE`   varchar(100) NOT NULL,
  `ESDOMICILIADO_TEFE` varchar(1)   NULL DEFAULT 'N'
       COMMENT 'S/N - el efecto se domicilia en cuenta bancaria',
  `ESREMESABLE_TEFE`   varchar(1)   NULL DEFAULT 'N'
       COMMENT 'S/N - el efecto puede agruparse en una remesa',
  `ORDEN_TEFE`         int(11)      NULL DEFAULT 0,
  `ESACTIVO_TEFE`      varchar(1)   NULL DEFAULT 'S',
  `INSTANTE_MODIF` timestamp NOT NULL
       DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`  timestamp NOT NULL
       DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`   varchar(100) NOT NULL,
  `USUARIO_MODIF`  varchar(100) NOT NULL,
  PRIMARY KEY (`CODIGO_TEFE`)
);

INSERT INTO `fza_tipos_efecto`
  (`CODIGO_TEFE`, `DESCRIPCION_TEFE`, `ESDOMICILIADO_TEFE`,
   `ESREMESABLE_TEFE`, `ORDEN_TEFE`, `ESACTIVO_TEFE`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT seed.c, seed.d, seed.dom, seed.rem, seed.o, seed.a,
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
  FROM (
  SELECT 'CONTADO' AS c, 'Contado' AS d, 'N' AS dom, 'N' AS rem,
         1 AS o, 'S' AS a
  UNION ALL SELECT 'TRANSFERENCIA', 'Transferencia bancaria',
         'N', 'N', 2, 'S'
  UNION ALL SELECT 'RECIBO', 'Recibo domiciliado',
         'S', 'S', 3, 'S'
  UNION ALL SELECT 'PAGARE', 'Pagare',
         'N', 'S', 4, 'S'
  UNION ALL SELECT 'CONFIRMING', 'Confirming',
         'S', 'S', 5, 'S'
) seed
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_efecto`
    WHERE `CODIGO_TEFE` = seed.c
 );

-- ----------------------------------------------------------------------------
-- 2. fza_efectos_venta (EFV): efecto/vencimiento de cobro por plazo.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_efectos_venta` (
  `SERIE_FAC_EFV`  varchar(20) NOT NULL
       COMMENT 'Factura de venta origen (serie)',
  `NUMERO_FAC_EFV` varchar(20) NOT NULL
       COMMENT 'Factura de venta origen (numero)',
  `NUMERO_EFV`     int(11)     NOT NULL
       COMMENT 'Secuencial del efecto dentro de la factura (1..N)',
  `CODIGO_EMP_EFV` varchar(8)  NULL DEFAULT NULL,
  `CODIGO_CLI_EFV` varchar(20) NULL DEFAULT NULL
       COMMENT 'FK logica a fza_clientes (denormalizado)',
  `RAZON_SOCIAL_CLI_EFV` varchar(200) NULL DEFAULT NULL,
  `NIF_CLI_EFV` varchar(50) NULL DEFAULT NULL,
  `CODIGO_TEFE_EFV` varchar(20) NULL DEFAULT NULL
       COMMENT 'FK logica a fza_tipos_efecto',
  `ESTADO_EFV` varchar(20) NULL DEFAULT 'PENDIENTE'
       COMMENT 'PENDIENTE, COBRADO, REMESADO, DEVUELTO, ANULADO, CONCILIADO',
  `ORDEN_PLAZO_EFV` int(11) NULL DEFAULT 1,
  `FECHA_EMISION_EFV` date NULL DEFAULT NULL,
  `FECHA_VENCIMIENTO_EFV` date NULL DEFAULT NULL,
  `FECHA_COBRO_EFV` date NULL DEFAULT NULL,
  `TIPO_COBRO_EFV` varchar(50) NULL DEFAULT NULL,
  `REFERENCIA_COBRO_EFV` varchar(100) NULL DEFAULT NULL,
  `ENTIDAD_COBRO_EFV` varchar(100) NULL DEFAULT NULL,
  `ESCONCILIADO_EFV` varchar(1) NULL DEFAULT 'N',
  `IMPORTE_EFV` decimal(18,6) NULL DEFAULT '0.000000',
  `IMPORTE_COBRADO_EFV` decimal(18,6) NULL DEFAULT '0.000000',
  `IMPORTE_PENDIENTE_EFV` decimal(18,6) NULL DEFAULT '0.000000',
  `SERIE_REMV_EFV` varchar(20) NULL DEFAULT NULL
       COMMENT 'FK logica a fza_remesas_venta (si esta remesado)',
  `NUMERO_REMV_EFV` varchar(20) NULL DEFAULT NULL,
  `ENTIDAD_EFV` varchar(4) NULL DEFAULT NULL,
  `OFICINA_EFV` varchar(4) NULL DEFAULT NULL,
  `DIGITO_CONTROL_EFV` varchar(2) NULL DEFAULT NULL,
  `CUENTA_EFV` varchar(10) NULL DEFAULT NULL,
  `IBAN_EFV` varchar(34) NULL DEFAULT NULL
       COMMENT 'IBAN del cliente',
  `CODIGO_EMPBAN_EFV` varchar(8) NULL DEFAULT NULL
       COMMENT 'Cuenta de la empresa (ingreso)',
  `IBAN_EMP_EFV` varchar(34) NULL DEFAULT NULL
       COMMENT 'IBAN de la empresa (ingreso)',
  `DOC_EXTERNO_EFV` varchar(50) NULL DEFAULT NULL,
  `REFERENCIA_DOCUMENTO_EFV` varchar(100) NULL DEFAULT NULL,
  `SERIE_FAC_CONCILIACION_EFV` varchar(20) NULL DEFAULT NULL,
  `NUMERO_FAC_CONCILIACION_EFV` varchar(20) NULL DEFAULT NULL,
  `NUMERO_EFV_CONCILIACION_EFV` int(11) NULL DEFAULT NULL,
  `OBSERVACIONES_EFV` varchar(1000) NULL DEFAULT '',
  `INSTANTE_MODIF` timestamp NOT NULL
       DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL,
  `USUARIO_MODIF` varchar(100) NOT NULL,
  PRIMARY KEY (`SERIE_FAC_EFV`, `NUMERO_FAC_EFV`, `NUMERO_EFV`)
);

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_efectos_venta'
     AND INDEX_NAME = 'IDX_EFV_VENCIMIENTO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_venta` '
  'ADD INDEX `IDX_EFV_VENCIMIENTO` (`FECHA_VENCIMIENTO_EFV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_efectos_venta'
     AND INDEX_NAME = 'IDX_EFV_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_venta` '
  'ADD INDEX `IDX_EFV_ESTADO` (`ESTADO_EFV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_efectos_venta'
     AND INDEX_NAME = 'IDX_EFV_CLIENTE'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_venta` '
  'ADD INDEX `IDX_EFV_CLIENTE` (`CODIGO_CLI_EFV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_efectos_venta'
     AND INDEX_NAME = 'IDX_EFV_REMESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_venta` '
  'ADD INDEX `IDX_EFV_REMESA` (`SERIE_REMV_EFV`, `NUMERO_REMV_EFV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_efectos_venta'
     AND INDEX_NAME = 'IDX_EFV_CONCILIACION'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_venta` '
  'ADD INDEX `IDX_EFV_CONCILIACION` '
  '(`SERIE_FAC_CONCILIACION_EFV`, '
  '`NUMERO_FAC_CONCILIACION_EFV`, '
  '`NUMERO_EFV_CONCILIACION_EFV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. fza_remesas_venta (REMV): remesa de cobro que agrupa efectos.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_remesas_venta` (
  `NUMERO_REMV` varchar(20) NOT NULL,
  `SERIE_REMV` varchar(20) NOT NULL,
  `FECHA_REMV` date NULL DEFAULT NULL,
  `ESTADO_REMV` varchar(20) NULL DEFAULT 'ABIERTA'
       COMMENT 'ABIERTA, PARCIAL, CERRADA, ENVIADA, COBRADA, CANCELADA',
  `CODIGO_EMP_REMV` varchar(8) NULL DEFAULT NULL,
  `TIPO_REMV` varchar(20) NULL DEFAULT 'NORMA19'
       COMMENT 'Norma SEPA de cobro (p.ej. cuaderno 19)',
  `NORMA_REMV` varchar(10) NULL DEFAULT NULL,
  `ENTIDAD_REMV` varchar(4) NULL DEFAULT NULL,
  `OFICINA_REMV` varchar(4) NULL DEFAULT NULL,
  `DIGITO_CONTROL_REMV` varchar(2) NULL DEFAULT NULL,
  `CUENTA_REMV` varchar(10) NULL DEFAULT NULL,
  `IBAN_REMV` varchar(34) NULL DEFAULT NULL
       COMMENT 'Cuenta de ingreso de la empresa',
  `CONTADOR_EFECTOS_REMV` int(11) NULL DEFAULT 0,
  `TOTAL_REMV` decimal(18,6) NULL DEFAULT '0.000000',
  `TOTAL_GASTOS_REMV` decimal(18,6) NULL DEFAULT '0.000000',
  `TOTAL_COMISION_REMV` decimal(18,6) NULL DEFAULT '0.000000',
  `FECHA_CARGO_REMV` date NULL DEFAULT NULL,
  `ARCHIVO_REMV` varchar(200) NULL DEFAULT NULL,
  `OBSERVACIONES_REMV` varchar(1000) NULL DEFAULT '',
  `INSTANTE_CONTABILIZACION_REMV` datetime NULL DEFAULT NULL,
  `INSTANTE_MODIF` timestamp NOT NULL
       DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL,
  `USUARIO_MODIF` varchar(100) NOT NULL,
  PRIMARY KEY (`NUMERO_REMV`, `SERIE_REMV`)
);

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_remesas_venta'
     AND INDEX_NAME = 'IDX_REMV_EMPRESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_remesas_venta` '
  'ADD INDEX `IDX_REMV_EMPRESA` (`CODIGO_EMP_REMV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_remesas_venta'
     AND INDEX_NAME = 'IDX_REMV_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_remesas_venta` '
  'ADD INDEX `IDX_REMV_ESTADO` (`ESTADO_REMV`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 4. Tipo de documento 'RC' (REMESA DE COBROS) y contador.
-- ----------------------------------------------------------------------------
INSERT INTO `fza_tipos_documentos`
  (`CODIGO_TIPO_DOCUMENTO_TD`, `DESCRIPCION_TIPO_DOCUMENTO_TD`,
   `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`)
SELECT 'RC', 'REMESA DE COBROS', 'fza_remesas_venta'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_documentos`
    WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'RC'
 );

INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
   `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT 'RC', '-', '-', 0, 6, 'S', 'S',
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'RC' AND `SERIE_CON` = '-'
 );

-- ----------------------------------------------------------------------------
-- 5. Vistas de lectura.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_efectos_venta` AS
SELECT e.*,
       f.FECHA_FAC AS FECHA_FACTURA_VIEW_EFV,
       f.TOTAL_LIQUIDO_FAC AS TOTAL_LIQUIDO_FACTURA_VIEW_EFV,
       f.DOCUMENTO_FAC AS DOCUMENTO_FACTURA_VIEW_EFV,
       cli.RAZON_SOCIAL_CLI AS NOMBRE_CLI_VIEW_EFV,
       t.DESCRIPCION_TEFE AS DESCRIPCION_TEFE_VIEW_EFV
  FROM fza_efectos_venta e
  LEFT JOIN fza_facturas f
    ON f.SERIE_FAC = e.SERIE_FAC_EFV
   AND f.NUMERO_FAC = e.NUMERO_FAC_EFV
  LEFT JOIN fza_clientes cli
    ON cli.CODIGO_CLI_CLI = e.CODIGO_CLI_EFV
  LEFT JOIN fza_tipos_efecto t
    ON t.CODIGO_TEFE = e.CODIGO_TEFE_EFV;

CREATE OR REPLACE VIEW `vi_efectos_venta_pendientes` AS
SELECT e.*,
       cli.RAZON_SOCIAL_CLI AS NOMBRE_CLI_VIEW_EFV,
       t.DESCRIPCION_TEFE AS DESCRIPCION_TEFE_VIEW_EFV
  FROM fza_efectos_venta e
  LEFT JOIN fza_clientes cli
    ON cli.CODIGO_CLI_CLI = e.CODIGO_CLI_EFV
  LEFT JOIN fza_tipos_efecto t
    ON t.CODIGO_TEFE = e.CODIGO_TEFE_EFV
 WHERE COALESCE(e.ESTADO_EFV, '') NOT IN
       ('COBRADO', 'ANULADO', 'CONCILIADO')
   AND COALESCE(e.IMPORTE_PENDIENTE_EFV, 0) > 0;

CREATE OR REPLACE VIEW `vi_remesas_venta` AS
SELECT r.*,
       emp.RAZON_SOCIAL_EMP AS RAZON_SOCIAL_EMPRESA_VIEW_REMV
  FROM fza_remesas_venta r
  LEFT JOIN fza_empresas emp
    ON emp.CODIGO_EMP_EMP = r.CODIGO_EMP_REMV;

-- ----------------------------------------------------------------------------
-- 6. PRC_EFV_GENERAR_DESDE_FACTURA.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_EFV_GENERAR_DESDE_FACTURA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_EFV_GENERAR_DESDE_FACTURA`(
    IN p_SERIE varchar(20),
    IN p_NUMERO varchar(20),
    IN p_USUARIO varchar(100),
    IN p_CODIGO_EMPBAN varchar(8),
    IN p_IBAN_EMP varchar(34),
    OUT p_RESULTADO int)
BEGIN
  DECLARE v_liquido decimal(18,6) DEFAULT 0;
  DECLARE v_fp varchar(200);
  DECLARE v_fecha date;
  DECLARE v_emp varchar(8);
  DECLARE v_cli varchar(20);
  DECLARE v_razon varchar(200);
  DECLARE v_nif varchar(50);
  DECLARE v_iban varchar(34);
  DECLARE v_nplazos int DEFAULT 1;
  DECLARE v_dias int DEFAULT 0;
  DECLARE v_escontado varchar(1) DEFAULT 'N';
  DECLARE v_tefe varchar(20);
  DECLARE v_bloqueados int DEFAULT 0;
  DECLARE v_i int DEFAULT 1;
  DECLARE v_imp decimal(18,6) DEFAULT 0;
  DECLARE v_acum decimal(18,6) DEFAULT 0;
  DECLARE v_vto date;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  SELECT COUNT(*)
    INTO v_bloqueados
    FROM fza_efectos_venta
   WHERE SERIE_FAC_EFV = p_SERIE
     AND NUMERO_FAC_EFV = p_NUMERO
     AND (COALESCE(ESTADO_EFV, '') IN
          ('COBRADO', 'REMESADO', 'CONCILIADO')
          OR COALESCE(IMPORTE_COBRADO_EFV, 0) > 0
          OR COALESCE(ESCONCILIADO_EFV, 'N') = 'S'
          OR COALESCE(SERIE_REMV_EFV, '') <> ''
          OR COALESCE(SERIE_FAC_CONCILIACION_EFV, '') <> '');
  IF v_bloqueados = 0 THEN
    SELECT COALESCE(f.TOTAL_LIQUIDO_FAC, 0), f.FORMA_PAGO_FAC,
           COALESCE(f.FECHA_FAC, CURDATE()), f.CODIGO_EMP_FAC,
           f.CODIGO_CLI_FAC, f.RAZON_SOCIAL_CLIENTE_FAC,
           f.NIF_CLIENTE_FAC, cli.IBAN_CLI,
           COALESCE(fp.N_PLAZOS_FORMA_PAGO_FP, 1),
           COALESCE(fp.N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, 0),
           COALESCE(fp.ESCONTADO_FORMA_PAGO_FP, 'N')
      INTO v_liquido, v_fp, v_fecha, v_emp, v_cli, v_razon, v_nif,
           v_iban, v_nplazos, v_dias, v_escontado
      FROM fza_facturas f
      LEFT JOIN fza_clientes cli
        ON cli.CODIGO_CLI_CLI = f.CODIGO_CLI_FAC
      LEFT JOIN fza_formas_pago fp
        ON fp.CODIGO_FP_FP = f.FORMA_PAGO_FAC
     WHERE f.SERIE_FAC = p_SERIE
       AND f.NUMERO_FAC = p_NUMERO;
    IF v_nplazos IS NULL OR v_nplazos < 1 THEN
      SET v_nplazos = 1;
    END IF;
    SET v_tefe = IF(v_escontado = 'S', 'CONTADO', 'RECIBO');
    IF v_liquido > 0 THEN
      START TRANSACTION;
      DELETE FROM fza_efectos_venta
       WHERE SERIE_FAC_EFV = p_SERIE
         AND NUMERO_FAC_EFV = p_NUMERO;
      SET v_acum = 0;
      WHILE v_i <= v_nplazos DO
        IF v_i = v_nplazos THEN
          SET v_imp = v_liquido - v_acum;
        ELSE
          SET v_imp = ROUND(v_liquido / v_nplazos, 2);
          SET v_acum = v_acum + v_imp;
        END IF;
        SET v_vto = DATE_ADD(v_fecha, INTERVAL (v_i * v_dias) DAY);
        INSERT INTO fza_efectos_venta
          (SERIE_FAC_EFV, NUMERO_FAC_EFV, NUMERO_EFV, CODIGO_EMP_EFV,
           CODIGO_CLI_EFV, RAZON_SOCIAL_CLI_EFV, NIF_CLI_EFV,
           CODIGO_TEFE_EFV, ESTADO_EFV, ORDEN_PLAZO_EFV,
           FECHA_EMISION_EFV, FECHA_VENCIMIENTO_EFV, IMPORTE_EFV,
           IMPORTE_COBRADO_EFV, IMPORTE_PENDIENTE_EFV, IBAN_EFV,
           CODIGO_EMPBAN_EFV, IBAN_EMP_EFV, REFERENCIA_DOCUMENTO_EFV,
           INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
        VALUES
          (p_SERIE, p_NUMERO, v_i, v_emp, v_cli, v_razon, v_nif,
           v_tefe, 'PENDIENTE', v_i, v_fecha, v_vto, v_imp,
           0, v_imp, v_iban, NULLIF(p_CODIGO_EMPBAN, ''),
           NULLIF(p_IBAN_EMP, ''), CONCAT(p_SERIE, '/', p_NUMERO),
           NOW(), p_USUARIO, NOW(), p_USUARIO);
        SET v_i = v_i + 1;
      END WHILE;
      COMMIT;
      SET p_RESULTADO = v_nplazos;
    END IF;
  END IF;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 7. PRC_EFV_CONCILIAR_COBRO.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_EFV_CONCILIAR_COBRO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_EFV_CONCILIAR_COBRO`(
    IN p_SERIE varchar(20),
    IN p_NUMERO varchar(20),
    IN p_NUM_EFV int,
    IN p_FECHA date,
    IN p_IMPORTE decimal(18,6),
    IN p_TIPO varchar(50),
    IN p_REFERENCIA varchar(100),
    IN p_ENTIDAD varchar(100),
    IN p_USUARIO varchar(100),
    OUT p_RESULTADO int)
BEGIN
  DECLARE v_existe int DEFAULT 0;
  DECLARE v_importe decimal(18,6) DEFAULT 0;
  DECLARE v_pend decimal(18,6) DEFAULT 0;
  DECLARE v_cobro decimal(18,6) DEFAULT 0;
  DECLARE v_resto decimal(18,6) DEFAULT 0;
  DECLARE v_nuevo int DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  START TRANSACTION;
  SELECT COUNT(*)
    INTO v_existe
    FROM fza_efectos_venta
   WHERE SERIE_FAC_EFV = p_SERIE
     AND NUMERO_FAC_EFV = p_NUMERO
     AND NUMERO_EFV = p_NUM_EFV
     AND COALESCE(ESTADO_EFV, '') NOT IN
         ('COBRADO', 'ANULADO', 'DEVUELTO', 'CONCILIADO')
     AND COALESCE(IMPORTE_PENDIENTE_EFV, IMPORTE_EFV, 0) > 0;
  IF v_existe > 0 AND COALESCE(p_IMPORTE, 0) > 0 THEN
    SELECT COALESCE(IMPORTE_EFV, 0),
           COALESCE(IMPORTE_PENDIENTE_EFV, IMPORTE_EFV, 0)
      INTO v_importe, v_pend
      FROM fza_efectos_venta
     WHERE SERIE_FAC_EFV = p_SERIE
       AND NUMERO_FAC_EFV = p_NUMERO
       AND NUMERO_EFV = p_NUM_EFV
       FOR UPDATE;
    SET v_cobro = COALESCE(p_IMPORTE, 0);
    IF v_cobro > v_pend THEN
      SET v_cobro = v_pend;
    END IF;
    SET v_resto = v_pend - v_cobro;
    IF v_resto <= 0.000001 THEN
      UPDATE fza_efectos_venta
         SET IMPORTE_COBRADO_EFV = v_importe,
             IMPORTE_PENDIENTE_EFV = 0,
             FECHA_COBRO_EFV = COALESCE(p_FECHA, CURDATE()),
             TIPO_COBRO_EFV = NULLIF(p_TIPO, ''),
             REFERENCIA_COBRO_EFV = NULLIF(p_REFERENCIA, ''),
             ENTIDAD_COBRO_EFV = NULLIF(p_ENTIDAD, ''),
             ESCONCILIADO_EFV = 'S',
             ESTADO_EFV = 'COBRADO',
             INSTANTE_MODIF = NOW(),
             USUARIO_MODIF = p_USUARIO
       WHERE SERIE_FAC_EFV = p_SERIE
         AND NUMERO_FAC_EFV = p_NUMERO
         AND NUMERO_EFV = p_NUM_EFV;
      SET p_RESULTADO = 1;
    ELSE
      SELECT COALESCE(MAX(NUMERO_EFV), 0) + 1
        INTO v_nuevo
        FROM fza_efectos_venta
       WHERE SERIE_FAC_EFV = p_SERIE
         AND NUMERO_FAC_EFV = p_NUMERO;
      UPDATE fza_efectos_venta
         SET IMPORTE_EFV = v_cobro,
             IMPORTE_COBRADO_EFV = v_cobro,
             IMPORTE_PENDIENTE_EFV = 0,
             FECHA_COBRO_EFV = COALESCE(p_FECHA, CURDATE()),
             TIPO_COBRO_EFV = NULLIF(p_TIPO, ''),
             REFERENCIA_COBRO_EFV = NULLIF(p_REFERENCIA, ''),
             ENTIDAD_COBRO_EFV = NULLIF(p_ENTIDAD, ''),
             ESCONCILIADO_EFV = 'S',
             ESTADO_EFV = 'COBRADO',
             INSTANTE_MODIF = NOW(),
             USUARIO_MODIF = p_USUARIO
       WHERE SERIE_FAC_EFV = p_SERIE
         AND NUMERO_FAC_EFV = p_NUMERO
         AND NUMERO_EFV = p_NUM_EFV;
      INSERT INTO fza_efectos_venta
        (SERIE_FAC_EFV, NUMERO_FAC_EFV, NUMERO_EFV,
         CODIGO_EMP_EFV, CODIGO_CLI_EFV, RAZON_SOCIAL_CLI_EFV,
         NIF_CLI_EFV, CODIGO_TEFE_EFV, ESTADO_EFV,
         ORDEN_PLAZO_EFV, FECHA_EMISION_EFV, FECHA_VENCIMIENTO_EFV,
         ESCONCILIADO_EFV, IMPORTE_EFV, IMPORTE_COBRADO_EFV,
         IMPORTE_PENDIENTE_EFV, SERIE_REMV_EFV, NUMERO_REMV_EFV,
         ENTIDAD_EFV, OFICINA_EFV, DIGITO_CONTROL_EFV, CUENTA_EFV,
         IBAN_EFV, CODIGO_EMPBAN_EFV, IBAN_EMP_EFV, DOC_EXTERNO_EFV,
         REFERENCIA_DOCUMENTO_EFV, SERIE_FAC_CONCILIACION_EFV,
         NUMERO_FAC_CONCILIACION_EFV, NUMERO_EFV_CONCILIACION_EFV,
         OBSERVACIONES_EFV, INSTANTE_ALTA, USUARIO_ALTA,
         INSTANTE_MODIF, USUARIO_MODIF)
      SELECT SERIE_FAC_EFV, NUMERO_FAC_EFV, v_nuevo,
             CODIGO_EMP_EFV, CODIGO_CLI_EFV, RAZON_SOCIAL_CLI_EFV,
             NIF_CLI_EFV, CODIGO_TEFE_EFV,
             CASE
               WHEN COALESCE(SERIE_REMV_EFV, '') <> '' THEN 'REMESADO'
               ELSE 'PENDIENTE'
             END,
             ORDEN_PLAZO_EFV, FECHA_EMISION_EFV,
             FECHA_VENCIMIENTO_EFV, 'N', v_resto, 0, v_resto,
             SERIE_REMV_EFV, NUMERO_REMV_EFV, ENTIDAD_EFV, OFICINA_EFV,
             DIGITO_CONTROL_EFV, CUENTA_EFV, IBAN_EFV, CODIGO_EMPBAN_EFV,
             IBAN_EMP_EFV, DOC_EXTERNO_EFV, REFERENCIA_DOCUMENTO_EFV,
             SERIE_FAC_CONCILIACION_EFV, NUMERO_FAC_CONCILIACION_EFV,
             NUMERO_EFV_CONCILIACION_EFV, OBSERVACIONES_EFV,
             NOW(), p_USUARIO, NOW(), p_USUARIO
        FROM fza_efectos_venta
       WHERE SERIE_FAC_EFV = p_SERIE
         AND NUMERO_FAC_EFV = p_NUMERO
         AND NUMERO_EFV = p_NUM_EFV;
      SET p_RESULTADO = 2;
    END IF;
  END IF;
  COMMIT;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 8. Remesas de cobro.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_REMV_CREAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REMV_CREAR`(
    IN p_EMPRESA varchar(8),
    IN p_IBAN varchar(34),
    IN p_USUARIO varchar(100),
    OUT p_SERIE_OUT varchar(20),
    OUT p_NUMERO_OUT varchar(20))
BEGIN
  DECLARE v_nro bigint DEFAULT 0;
  DECLARE v_serie varchar(3);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  CALL PRC_FNC_GET_NEXT_NRO_DOC('RC', v_nro);
  CALL PRC_FNC_GET_SERIE_TIPODOC('RC', v_serie);
  SET p_NUMERO_OUT = LPAD(v_nro, 6, '0');
  SET p_SERIE_OUT = v_serie;
  INSERT INTO fza_remesas_venta
    (NUMERO_REMV, SERIE_REMV, FECHA_REMV, ESTADO_REMV, CODIGO_EMP_REMV,
     IBAN_REMV, CONTADOR_EFECTOS_REMV, TOTAL_REMV,
     INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
  VALUES
    (p_NUMERO_OUT, p_SERIE_OUT, CURDATE(), 'ABIERTA', p_EMPRESA,
     p_IBAN, 0, 0, NOW(), p_USUARIO, NOW(), p_USUARIO);
  COMMIT;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_REMV_ANYADIR_EFECTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REMV_ANYADIR_EFECTO`(
    IN p_SERIE_REM varchar(20),
    IN p_NUMERO_REM varchar(20),
    IN p_SERIE_FAC varchar(20),
    IN p_NUMERO_FAC varchar(20),
    IN p_NUM_EFV int,
    IN p_USUARIO varchar(100),
    OUT p_RESULTADO int)
BEGIN
  DECLARE v_rem int DEFAULT 0;
  DECLARE v_efe int DEFAULT 0;
  DECLARE v_iban varchar(34);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  SELECT COUNT(*), MAX(IBAN_REMV)
    INTO v_rem, v_iban
    FROM fza_remesas_venta
   WHERE SERIE_REMV = p_SERIE_REM
     AND NUMERO_REMV = p_NUMERO_REM;
  SELECT COUNT(*)
    INTO v_efe
    FROM fza_efectos_venta
   WHERE SERIE_FAC_EFV = p_SERIE_FAC
     AND NUMERO_FAC_EFV = p_NUMERO_FAC
     AND NUMERO_EFV = p_NUM_EFV
     AND SERIE_REMV_EFV IS NULL
     AND COALESCE(ESTADO_EFV, '') NOT IN
         ('COBRADO', 'ANULADO', 'CONCILIADO')
     AND COALESCE(IMPORTE_PENDIENTE_EFV, 0) > 0;
  IF v_rem > 0 AND v_efe > 0 THEN
    START TRANSACTION;
    UPDATE fza_efectos_venta
       SET SERIE_REMV_EFV = p_SERIE_REM,
           NUMERO_REMV_EFV = p_NUMERO_REM,
           ESTADO_EFV = 'REMESADO',
           IBAN_EMP_EFV = COALESCE(NULLIF(v_iban, ''), IBAN_EMP_EFV),
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE SERIE_FAC_EFV = p_SERIE_FAC
       AND NUMERO_FAC_EFV = p_NUMERO_FAC
       AND NUMERO_EFV = p_NUM_EFV;
    CALL PRC_REMV_RECALCULAR(p_SERIE_REM, p_NUMERO_REM);
    SET p_RESULTADO = 1;
    COMMIT;
  END IF;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_REMV_RECALCULAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REMV_RECALCULAR`(
    IN p_SERIE varchar(20),
    IN p_NUMERO varchar(20))
BEGIN
  DECLARE v_n int DEFAULT 0;
  DECLARE v_total decimal(18,6) DEFAULT 0;
  SELECT COUNT(*), COALESCE(SUM(COALESCE(IMPORTE_EFV, 0)), 0)
    INTO v_n, v_total
    FROM fza_efectos_venta
   WHERE SERIE_REMV_EFV = p_SERIE
     AND NUMERO_REMV_EFV = p_NUMERO;
  UPDATE fza_remesas_venta
     SET CONTADOR_EFECTOS_REMV = v_n,
         TOTAL_REMV = v_total,
         INSTANTE_MODIF = NOW()
   WHERE SERIE_REMV = p_SERIE
     AND NUMERO_REMV = p_NUMERO;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 9. Registro de mantenimientos.
-- ----------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'EfectosVenta',
       'Efectos de Cobro a Cliente',
       'EfectosVenta1',
       'inMtoEfectosVenta.TfrmMtoEfectosVenta',
       '',
       'UniDataEfectosVenta.TdmEfectosVenta',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms` WHERE `CALL_WINF` = 'EfectosVenta'
 );

INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'RemesasVenta',
       'Remesas de Cobro',
       'RemesasVenta1',
       'inMtoRemesasVenta.TfrmMtoRemesasVenta',
       '',
       'UniDataRemesasVenta.TdmRemesasVenta',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms` WHERE `CALL_WINF` = 'RemesasVenta'
 );
