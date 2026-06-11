-- ============================================================================
-- Efectos de pago a proveedor, historico de pagos y remesas — esquema base
--
-- Segundo eslabon de la cadena de cuentas a pagar, despues de
-- facturas_compra.sql:
--
--   factura de compra  --(efectos)-->  vencimientos de pago
--        |                                   |
--        |                          historico de pagos (con fechas)
--        +-----------------------------> remesa (agrupa efectos)
--
-- Tablas (espejo MariaDB del legacy ocefepro / occobpro / ocrempro /
-- octipefe, acotado al lado de COMPRA / PAGO):
--
--   fza_tipos_efecto         (TEFE)    catalogo de tipos de efecto
--   fza_efectos_compra       (EFEC)    un efecto/vencimiento por plazo de
--                                      la factura, con fecha de vencimiento
--   fza_efectos_compra_pagos (EFECPAG) HISTORICO de pagos con fecha: varios
--                                      pagos por efecto (control contable)
--   fza_remesas_compra       (REMC)    remesa que agrupa efectos para pago
--
-- Sufijos registrados en LIBRO_DE_ESTILO_BBDD.md §2 y en
-- UNormalizerEngine.pas / InitDefaults. Idempotente (INFORMATION_SCHEMA);
-- las SP usan DROP ... IF EXISTS y DELIMITER (cliente DELIMITER-aware).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. fza_tipos_efecto (TEFE): catalogo de tipos de efecto
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_tipos_efecto'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_tipos_efecto` ('
  '  `CODIGO_TEFE`        varchar(20)  NOT NULL,'
  '  `DESCRIPCION_TEFE`   varchar(100) NOT NULL,'
  '  `ESDOMICILIADO_TEFE` varchar(1)   NULL DEFAULT ''N'''
  '       COMMENT ''S/N — el pago se domicilia en cuenta bancaria'','
  '  `ESREMESABLE_TEFE`   varchar(1)   NULL DEFAULT ''N'''
  '       COMMENT ''S/N — el efecto puede agruparse en una remesa'','
  '  `ORDEN_TEFE`         int(11)      NULL DEFAULT 0,'
  '  `ESACTIVO_TEFE`      varchar(1)   NULL DEFAULT ''S'','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`CODIGO_TEFE`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Semilla de tipos de efecto habituales (idempotente).
INSERT INTO `fza_tipos_efecto`
  (`CODIGO_TEFE`, `DESCRIPCION_TEFE`, `ESDOMICILIADO_TEFE`,
   `ESREMESABLE_TEFE`, `ORDEN_TEFE`, `ESACTIVO_TEFE`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT seed.c, seed.d, seed.dom, seed.rem, seed.o, seed.a,
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
  FROM (
  SELECT 'CONTADO'       AS c, 'Pago al contado'        AS d,
         'N' AS dom, 'N' AS rem, 1  AS o, 'S' AS a
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
-- 2. fza_efectos_compra (EFEC): un efecto/vencimiento por plazo de factura
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_efectos_compra` ('
  '  `SERIE_FACC_EFEC`  varchar(20) NOT NULL'
  '       COMMENT ''Factura de compra origen (serie)'','
  '  `NUMERO_FACC_EFEC` varchar(20) NOT NULL'
  '       COMMENT ''Factura de compra origen (numero)'','
  '  `NUMERO_EFEC`      int(11)     NOT NULL'
  '       COMMENT ''Secuencial del efecto dentro de la factura (1..N)'','
  '  `CODIGO_EMP_EFEC`  varchar(8)  NULL DEFAULT NULL,'
  '  `CODIGO_PRV_EFEC`  varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_proveedores (denormalizado)'','
  '  `RAZON_SOCIAL_PRV_EFEC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_PRV_EFEC`     varchar(50) NULL DEFAULT NULL,'
  '  `CODIGO_TEFE_EFEC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_tipos_efecto'','
  '  `ESTADO_EFEC`      varchar(20) NULL DEFAULT ''PENDIENTE'''
  '       COMMENT ''PENDIENTE, PARCIAL, PAGADO, REMESADO, DEVUELTO, ANULADO'','
  '  `ORDEN_PLAZO_EFEC` int(11)     NULL DEFAULT 1'
  '       COMMENT ''Numero de plazo segun la forma de pago'','
  '  `FECHA_EMISION_EFEC`     date NULL DEFAULT NULL,'
  '  `FECHA_VENCIMIENTO_EFEC` date NULL DEFAULT NULL'
  '       COMMENT ''Vencimiento del pago (clave para el control contable)'','
  '  `FECHA_PAGO_EFEC`        date NULL DEFAULT NULL'
  '       COMMENT ''Fecha del ultimo pago aplicado'','
  '  `IMPORTE_EFEC`           decimal(18,6) NULL DEFAULT ''0.000000'','
  '  `IMPORTE_PAGADO_EFEC`    decimal(18,6) NULL DEFAULT ''0.000000'''
  '       COMMENT ''Suma del historico de pagos del efecto'','
  '  `IMPORTE_PENDIENTE_EFEC` decimal(18,6) NULL DEFAULT ''0.000000'','
  '  `SERIE_REMC_EFEC`  varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_remesas_compra (si esta remesado)'','
  '  `NUMERO_REMC_EFEC` varchar(20) NULL DEFAULT NULL,'
  '  `ENTIDAD_EFEC`        varchar(4)  NULL DEFAULT NULL,'
  '  `OFICINA_EFEC`        varchar(4)  NULL DEFAULT NULL,'
  '  `DIGITO_CONTROL_EFEC` varchar(2)  NULL DEFAULT NULL,'
  '  `CUENTA_EFEC`         varchar(10) NULL DEFAULT NULL,'
  '  `IBAN_EFEC`           varchar(34) NULL DEFAULT NULL,'
  '  `DOC_EXTERNO_EFEC`    varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''Nro de factura del proveedor (traza)'','
  '  `OBSERVACIONES_EFEC`  varchar(1000) NULL DEFAULT '''','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`SERIE_FACC_EFEC`,`NUMERO_FACC_EFEC`,`NUMERO_EFEC`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
     AND INDEX_NAME   = 'IDX_EFEC_VENCIMIENTO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_compra` '
  'ADD INDEX `IDX_EFEC_VENCIMIENTO` (`FECHA_VENCIMIENTO_EFEC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
     AND INDEX_NAME   = 'IDX_EFEC_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_compra` '
  'ADD INDEX `IDX_EFEC_ESTADO` (`ESTADO_EFEC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
     AND INDEX_NAME   = 'IDX_EFEC_PROVEEDOR'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_compra` '
  'ADD INDEX `IDX_EFEC_PROVEEDOR` (`CODIGO_PRV_EFEC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
     AND INDEX_NAME   = 'IDX_EFEC_REMESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_compra` '
  'ADD INDEX `IDX_EFEC_REMESA` (`SERIE_REMC_EFEC`,`NUMERO_REMC_EFEC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. fza_efectos_compra_pagos (EFECPAG): historico de pagos con fecha
--    Varios pagos por efecto -> permite pagos parciales y trazabilidad
--    contable. PK incluye NUMERO_PAGO_EFECPAG (secuencial del pago).
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra_pagos'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_efectos_compra_pagos` ('
  '  `SERIE_FACC_EFECPAG`  varchar(20) NOT NULL,'
  '  `NUMERO_FACC_EFECPAG` varchar(20) NOT NULL,'
  '  `NUMERO_EFEC_EFECPAG` int(11)     NOT NULL'
  '       COMMENT ''Efecto al que se aplica el pago'','
  '  `NUMERO_PAGO_EFECPAG` int(11)     NOT NULL'
  '       COMMENT ''Secuencial del pago dentro del efecto (1..N)'','
  '  `FECHA_EFECPAG`   date NULL DEFAULT NULL'
  '       COMMENT ''Fecha del pago (control contable)'','
  '  `IMPORTE_EFECPAG` decimal(18,6) NULL DEFAULT ''0.000000'','
  '  `TIPO_EFECPAG`    varchar(50) NULL DEFAULT ''TRANSFERENCIA'''
  '       COMMENT ''Medio de pago: TRANSFERENCIA, EFECTIVO, CHEQUE, ...'','
  '  `CODIGO_FP_EFECPAG` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_formas_pago (opcional)'','
  '  `REFERENCIA_EFECPAG` varchar(100) NULL DEFAULT NULL'
  '       COMMENT ''Nro de transferencia / cheque / justificante'','
  '  `ENTIDAD_PAGO_EFECPAG` varchar(100) NULL DEFAULT NULL'
  '       COMMENT ''Banco / entidad desde la que se paga'','
  '  `ESCONCILIADO_EFECPAG` varchar(1) NULL DEFAULT ''N'''
  '       COMMENT ''S/N — conciliado con el extracto bancario'','
  '  `OBSERVACIONES_EFECPAG` varchar(500) NULL DEFAULT '''','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`SERIE_FACC_EFECPAG`,`NUMERO_FACC_EFECPAG`,'
  '               `NUMERO_EFEC_EFECPAG`,`NUMERO_PAGO_EFECPAG`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra_pagos'
     AND INDEX_NAME   = 'IDX_EFECPAG_FECHA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_efectos_compra_pagos` '
  'ADD INDEX `IDX_EFECPAG_FECHA` (`FECHA_EFECPAG`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 4. fza_remesas_compra (REMC): remesa de pagos que agrupa efectos
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_remesas_compra'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_remesas_compra` ('
  '  `NUMERO_REMC` varchar(20) NOT NULL,'
  '  `SERIE_REMC`  varchar(20) NOT NULL,'
  '  `FECHA_REMC`  date NULL DEFAULT NULL,'
  '  `ESTADO_REMC` varchar(20) NULL DEFAULT ''ABIERTA'''
  '       COMMENT ''ABIERTA, CERRADA, ENVIADA, PAGADA, CANCELADA'','
  '  `CODIGO_EMP_REMC` varchar(8) NULL DEFAULT NULL,'
  '  `TIPO_REMC`   varchar(20) NULL DEFAULT ''NORMA34'''
  '       COMMENT ''Norma SEPA de pago (p.ej. cuaderno 34)'','
  '  `NORMA_REMC`  varchar(10) NULL DEFAULT NULL,'
  '  `ENTIDAD_REMC`        varchar(4)  NULL DEFAULT NULL,'
  '  `OFICINA_REMC`        varchar(4)  NULL DEFAULT NULL,'
  '  `DIGITO_CONTROL_REMC` varchar(2)  NULL DEFAULT NULL,'
  '  `CUENTA_REMC`         varchar(10) NULL DEFAULT NULL,'
  '  `IBAN_REMC`           varchar(34) NULL DEFAULT NULL'
  '       COMMENT ''Cuenta de cargo de la empresa'','
  '  `CONTADOR_EFECTOS_REMC` int(11) NULL DEFAULT 0,'
  '  `TOTAL_REMC`          decimal(18,6) NULL DEFAULT ''0.000000'','
  '  `TOTAL_GASTOS_REMC`   decimal(18,6) NULL DEFAULT ''0.000000'','
  '  `TOTAL_COMISION_REMC` decimal(18,6) NULL DEFAULT ''0.000000'','
  '  `FECHA_CARGO_REMC`    date NULL DEFAULT NULL'
  '       COMMENT ''Fecha de cargo en cuenta'','
  '  `ARCHIVO_REMC`        varchar(200) NULL DEFAULT NULL'
  '       COMMENT ''Fichero SEPA generado'','
  '  `OBSERVACIONES_REMC`  varchar(1000) NULL DEFAULT '''','
  '  `INSTANTE_CONTABILIZACION_REMC` datetime NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_REMC`,`SERIE_REMC`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_remesas_compra'
     AND INDEX_NAME   = 'IDX_REMC_EMPRESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_remesas_compra` '
  'ADD INDEX `IDX_REMC_EMPRESA` (`CODIGO_EMP_REMC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_remesas_compra'
     AND INDEX_NAME   = 'IDX_REMC_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_remesas_compra` '
  'ADD INDEX `IDX_REMC_ESTADO` (`ESTADO_REMC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 5. Registrar el tipo de documento 'RP' (REMESA DE PAGOS) y su contador.
--    Codigo libre en fza_tipos_documentos. Las facturas usan 'FP'.
-- ----------------------------------------------------------------------------
INSERT INTO `fza_tipos_documentos`
  (`CODIGO_TIPO_DOCUMENTO_TD`, `DESCRIPCION_TIPO_DOCUMENTO_TD`,
   `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`)
SELECT 'RP', 'REMESA DE PAGOS', 'fza_remesas_compra'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_documentos`
    WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'RP'
 );

INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
   `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT 'RP', '-', '-', 0, 6, 'S', 'S',
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'RP' AND `SERIE_CON` = '-'
 );

-- ----------------------------------------------------------------------------
-- 6. Vistas de lectura
-- ----------------------------------------------------------------------------
-- 6a. Efectos con datos de factura, proveedor, tipo y remesa.
CREATE OR REPLACE VIEW `vi_efectos_compra` AS
SELECT  e.*,
        f.FECHA_FACC          AS FECHA_FACTURA_VIEW_EFEC,
        f.DOC_EXTERNO_FACC    AS DOC_EXTERNO_FACTURA_VIEW_EFEC,
        f.TOTAL_LIQUIDO_FACC  AS TOTAL_LIQUIDO_FACTURA_VIEW_EFEC,
        prv.NOMBRE_PRV        AS NOMBRE_PRV_VIEW_EFEC,
        t.DESCRIPCION_TEFE    AS DESCRIPCION_TEFE_VIEW_EFEC
  FROM  fza_efectos_compra e
  LEFT  JOIN fza_facturas_compra f
         ON f.SERIE_FACC  = e.SERIE_FACC_EFEC
        AND f.NUMERO_FACC = e.NUMERO_FACC_EFEC
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = e.CODIGO_PRV_EFEC
  LEFT  JOIN fza_tipos_efecto t
         ON t.CODIGO_TEFE = e.CODIGO_TEFE_EFEC;

-- 6b. Solo los efectos pendientes (cartera de pagos por vencimiento).
CREATE OR REPLACE VIEW `vi_efectos_compra_pendientes` AS
SELECT  e.*,
        prv.NOMBRE_PRV        AS NOMBRE_PRV_VIEW_EFEC
  FROM  fza_efectos_compra e
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = e.CODIGO_PRV_EFEC
 WHERE  COALESCE(e.ESTADO_EFEC, '') NOT IN ('PAGADO', 'ANULADO')
   AND  COALESCE(e.IMPORTE_PENDIENTE_EFEC, 0) > 0;

-- 6c. Remesas con datos de empresa.
CREATE OR REPLACE VIEW `vi_remesas_compra` AS
SELECT  r.*,
        emp.RAZON_SOCIAL_EMP  AS RAZON_SOCIAL_EMPRESA_VIEW_REMC
  FROM  fza_remesas_compra r
  LEFT  JOIN fza_empresas emp
         ON emp.CODIGO_EMP_EMP = r.CODIGO_EMP_REMC;

-- ----------------------------------------------------------------------------
-- 7. PRC_EFEC_GENERAR_DESDE_FACTURA: genera los efectos (vencimientos) de
--    una factura segun su forma de pago (N plazos x N dias entre plazos).
--    Reparte TOTAL_LIQUIDO_FACC entre los plazos (el ultimo absorbe el
--    redondeo). No toca efectos ya pagados / remesados (aborta con 0 para
--    no destruir historico).
--    p_RESULTADO: nº de efectos generados, 0 si no habia nada que hacer.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_EFEC_GENERAR_DESDE_FACTURA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_EFEC_GENERAR_DESDE_FACTURA`(
    IN  p_SERIE   varchar(20),
    IN  p_NUMERO  varchar(20),
    IN  p_USUARIO varchar(100),
    OUT p_RESULTADO int)
BEGIN
  DECLARE v_liquido  decimal(18,6) DEFAULT 0;
  DECLARE v_fp       varchar(200);
  DECLARE v_fecha    date;
  DECLARE v_emp      varchar(8);
  DECLARE v_prv      varchar(20);
  DECLARE v_razon    varchar(200);
  DECLARE v_nif      varchar(50);
  DECLARE v_docext   varchar(50);
  DECLARE v_ent      varchar(4);
  DECLARE v_ofi      varchar(4);
  DECLARE v_dc       varchar(2);
  DECLARE v_cta      varchar(10);
  DECLARE v_iban     varchar(34);
  DECLARE v_nplazos  int DEFAULT 1;
  DECLARE v_dias     int DEFAULT 0;
  DECLARE v_escontado varchar(1) DEFAULT 'N';
  DECLARE v_tefe     varchar(20);
  DECLARE v_bloqueados int DEFAULT 0;
  DECLARE v_i        int DEFAULT 1;
  DECLARE v_imp      decimal(18,6) DEFAULT 0;
  DECLARE v_acum     decimal(18,6) DEFAULT 0;
  DECLARE v_vto      date;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  -- ¿Hay efectos que no se pueden regenerar (pagados / remesados)?
  SELECT COUNT(*)
    INTO v_bloqueados
    FROM fza_efectos_compra
   WHERE SERIE_FACC_EFEC  = p_SERIE
     AND NUMERO_FACC_EFEC = p_NUMERO
     AND (COALESCE(ESTADO_EFEC, '') IN ('PAGADO', 'PARCIAL', 'REMESADO')
          OR COALESCE(IMPORTE_PAGADO_EFEC, 0) > 0
          OR SERIE_REMC_EFEC IS NOT NULL);
  IF v_bloqueados = 0 THEN
    -- Datos de la factura.
    SELECT COALESCE(TOTAL_LIQUIDO_FACC, 0), FORMA_PAGO_FACC,
           COALESCE(FECHA_FACC, CURDATE()), CODIGO_EMP_FACC,
           CODIGO_PRV_FACC, RAZON_SOCIAL_PRV_FACC, NIF_PRV_FACC,
           DOC_EXTERNO_FACC, ENTIDAD_FACC, OFICINA_FACC,
           DIGITO_CONTROL_FACC, CUENTA_FACC, IBAN_FACC
      INTO v_liquido, v_fp, v_fecha, v_emp, v_prv, v_razon, v_nif,
           v_docext, v_ent, v_ofi, v_dc, v_cta, v_iban
      FROM fza_facturas_compra
     WHERE SERIE_FACC = p_SERIE AND NUMERO_FACC = p_NUMERO;
    -- Parametros de la forma de pago (si existe).
    SELECT COALESCE(N_PLAZOS_FORMA_PAGO_FP, 1),
           COALESCE(N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, 0),
           COALESCE(ESCONTADO_FORMA_PAGO_FP, 'N')
      INTO v_nplazos, v_dias, v_escontado
      FROM fza_formas_pago
     WHERE CODIGO_FP_FP = v_fp;
    IF v_nplazos IS NULL OR v_nplazos < 1 THEN
      SET v_nplazos = 1;
    END IF;
    -- Tipo de efecto por defecto segun contado/aplazado.
    SET v_tefe = IF(v_escontado = 'S', 'CONTADO', 'RECIBO');
    -- Limpiar efectos previos (todos PENDIENTE en este punto).
    START TRANSACTION;
    DELETE FROM fza_efectos_compra_pagos
     WHERE SERIE_FACC_EFECPAG  = p_SERIE
       AND NUMERO_FACC_EFECPAG = p_NUMERO;
    DELETE FROM fza_efectos_compra
     WHERE SERIE_FACC_EFEC  = p_SERIE
       AND NUMERO_FACC_EFEC = p_NUMERO;
    SET v_acum = 0;
    WHILE v_i <= v_nplazos DO
      IF v_i = v_nplazos THEN
        SET v_imp = v_liquido - v_acum;          -- ultimo: resto exacto
      ELSE
        SET v_imp = ROUND(v_liquido / v_nplazos, 2);
        SET v_acum = v_acum + v_imp;
      END IF;
      SET v_vto = DATE_ADD(v_fecha, INTERVAL (v_i * v_dias) DAY);
      INSERT INTO fza_efectos_compra
        (SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC, CODIGO_EMP_EFEC,
         CODIGO_PRV_EFEC, RAZON_SOCIAL_PRV_EFEC, NIF_PRV_EFEC,
         CODIGO_TEFE_EFEC, ESTADO_EFEC, ORDEN_PLAZO_EFEC,
         FECHA_EMISION_EFEC, FECHA_VENCIMIENTO_EFEC, IMPORTE_EFEC,
         IMPORTE_PAGADO_EFEC, IMPORTE_PENDIENTE_EFEC, ENTIDAD_EFEC,
         OFICINA_EFEC, DIGITO_CONTROL_EFEC, CUENTA_EFEC, IBAN_EFEC,
         DOC_EXTERNO_EFEC, INSTANTE_ALTA, USUARIO_ALTA,
         INSTANTE_MODIF, USUARIO_MODIF)
      VALUES
        (p_SERIE, p_NUMERO, v_i, v_emp, v_prv, v_razon, v_nif,
         v_tefe, 'PENDIENTE', v_i, v_fecha, v_vto, v_imp,
         0, v_imp, v_ent, v_ofi, v_dc, v_cta, v_iban,
         v_docext, NOW(), p_USUARIO, NOW(), p_USUARIO);
      SET v_i = v_i + 1;
    END WHILE;
    COMMIT;
    SET p_RESULTADO = v_nplazos;
  END IF;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 8. PRC_EFEC_REGISTRAR_PAGO: anota un pago en el HISTORICO de un efecto y
--    recalcula importes/estado. Permite pagos parciales: el efecto pasa a
--    PARCIAL mientras quede pendiente y a PAGADO cuando se salda.
--    p_RESULTADO: numero de pago asignado (1..N), 0 si el efecto no existe.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_EFEC_REGISTRAR_PAGO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_EFEC_REGISTRAR_PAGO`(
    IN  p_SERIE      varchar(20),
    IN  p_NUMERO     varchar(20),
    IN  p_NUM_EFEC   int,
    IN  p_FECHA      date,
    IN  p_IMPORTE    decimal(18,6),
    IN  p_TIPO       varchar(50),
    IN  p_REFERENCIA varchar(100),
    IN  p_ENTIDAD    varchar(100),
    IN  p_USUARIO    varchar(100),
    OUT p_RESULTADO  int)
BEGIN
  DECLARE v_existe   int DEFAULT 0;
  DECLARE v_importe  decimal(18,6) DEFAULT 0;
  DECLARE v_pagado   decimal(18,6) DEFAULT 0;
  DECLARE v_pend     decimal(18,6) DEFAULT 0;
  DECLARE v_npago    int DEFAULT 0;
  DECLARE v_estado   varchar(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  SELECT COUNT(*), MAX(COALESCE(IMPORTE_EFEC, 0)),
         MAX(COALESCE(IMPORTE_PAGADO_EFEC, 0))
    INTO v_existe, v_importe, v_pagado
    FROM fza_efectos_compra
   WHERE SERIE_FACC_EFEC  = p_SERIE
     AND NUMERO_FACC_EFEC = p_NUMERO
     AND NUMERO_EFEC      = p_NUM_EFEC;
  IF v_existe > 0 THEN
    START TRANSACTION;
    SELECT COALESCE(MAX(NUMERO_PAGO_EFECPAG), 0) + 1
      INTO v_npago
      FROM fza_efectos_compra_pagos
     WHERE SERIE_FACC_EFECPAG  = p_SERIE
       AND NUMERO_FACC_EFECPAG = p_NUMERO
       AND NUMERO_EFEC_EFECPAG = p_NUM_EFEC;
    INSERT INTO fza_efectos_compra_pagos
      (SERIE_FACC_EFECPAG, NUMERO_FACC_EFECPAG, NUMERO_EFEC_EFECPAG,
       NUMERO_PAGO_EFECPAG, FECHA_EFECPAG, IMPORTE_EFECPAG, TIPO_EFECPAG,
       REFERENCIA_EFECPAG, ENTIDAD_PAGO_EFECPAG, INSTANTE_ALTA,
       USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
    VALUES
      (p_SERIE, p_NUMERO, p_NUM_EFEC, v_npago,
       COALESCE(p_FECHA, CURDATE()), COALESCE(p_IMPORTE, 0),
       COALESCE(p_TIPO, 'TRANSFERENCIA'), p_REFERENCIA, p_ENTIDAD,
       NOW(), p_USUARIO, NOW(), p_USUARIO);
    SET v_pagado = v_pagado + COALESCE(p_IMPORTE, 0);
    SET v_pend   = v_importe - v_pagado;
    IF v_pend <= 0 THEN
      SET v_estado = 'PAGADO';
    ELSE
      SET v_estado = 'PARCIAL';
    END IF;
    UPDATE fza_efectos_compra
       SET IMPORTE_PAGADO_EFEC    = v_pagado,
           IMPORTE_PENDIENTE_EFEC = v_pend,
           FECHA_PAGO_EFEC        = COALESCE(p_FECHA, CURDATE()),
           ESTADO_EFEC            = v_estado,
           USUARIO_MODIF          = p_USUARIO
     WHERE SERIE_FACC_EFEC  = p_SERIE
       AND NUMERO_FACC_EFEC = p_NUMERO
       AND NUMERO_EFEC      = p_NUM_EFEC;
    COMMIT;
    SET p_RESULTADO = v_npago;
  END IF;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 9. PRC_REMC_CREAR: crea una remesa de pagos vacia, numerada con el
--    contador 'RP'. Devuelve su serie/numero para ir anyadiendo efectos.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_REMC_CREAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REMC_CREAR`(
    IN  p_EMPRESA varchar(8),
    IN  p_IBAN    varchar(34),
    IN  p_USUARIO varchar(100),
    OUT p_SERIE_OUT  varchar(20),
    OUT p_NUMERO_OUT varchar(20))
BEGIN
  DECLARE v_nro   bigint DEFAULT 0;
  DECLARE v_serie varchar(3);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  CALL PRC_FNC_GET_NEXT_NRO_DOC('RP', v_nro);
  CALL PRC_FNC_GET_SERIE_TIPODOC('RP', v_serie);
  SET p_NUMERO_OUT = LPAD(v_nro, 6, '0');
  SET p_SERIE_OUT  = v_serie;
  INSERT INTO fza_remesas_compra
    (NUMERO_REMC, SERIE_REMC, FECHA_REMC, ESTADO_REMC, CODIGO_EMP_REMC,
     IBAN_REMC, CONTADOR_EFECTOS_REMC, TOTAL_REMC,
     INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
  VALUES
    (p_NUMERO_OUT, p_SERIE_OUT, CURDATE(), 'ABIERTA', p_EMPRESA,
     p_IBAN, 0, 0, NOW(), p_USUARIO, NOW(), p_USUARIO);
  COMMIT;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 10. PRC_REMC_ANYADIR_EFECTO: agrupa un efecto en una remesa (lo marca
--     REMESADO y enlaza) y recalcula los totales de la remesa. No re-remesa
--     un efecto ya remesado ni uno ya pagado.
--     p_RESULTADO: 1 ok, 0 nada que hacer, -1 error.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_REMC_ANYADIR_EFECTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REMC_ANYADIR_EFECTO`(
    IN  p_SERIE_REM  varchar(20),
    IN  p_NUMERO_REM varchar(20),
    IN  p_SERIE_FAC  varchar(20),
    IN  p_NUMERO_FAC varchar(20),
    IN  p_NUM_EFEC   int,
    IN  p_USUARIO    varchar(100),
    OUT p_RESULTADO  int)
BEGIN
  DECLARE v_rem  int DEFAULT 0;
  DECLARE v_efe  int DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  SELECT COUNT(*) INTO v_rem
    FROM fza_remesas_compra
   WHERE SERIE_REMC = p_SERIE_REM AND NUMERO_REMC = p_NUMERO_REM;
  SELECT COUNT(*) INTO v_efe
    FROM fza_efectos_compra
   WHERE SERIE_FACC_EFEC  = p_SERIE_FAC
     AND NUMERO_FACC_EFEC = p_NUMERO_FAC
     AND NUMERO_EFEC      = p_NUM_EFEC
     AND SERIE_REMC_EFEC IS NULL
     AND COALESCE(ESTADO_EFEC, '') NOT IN ('PAGADO', 'ANULADO');
  IF v_rem > 0 AND v_efe > 0 THEN
    START TRANSACTION;
    UPDATE fza_efectos_compra
       SET SERIE_REMC_EFEC  = p_SERIE_REM,
           NUMERO_REMC_EFEC = p_NUMERO_REM,
           ESTADO_EFEC      = 'REMESADO',
           USUARIO_MODIF    = p_USUARIO
     WHERE SERIE_FACC_EFEC  = p_SERIE_FAC
       AND NUMERO_FACC_EFEC = p_NUMERO_FAC
       AND NUMERO_EFEC      = p_NUM_EFEC;
    CALL PRC_REMC_RECALCULAR(p_SERIE_REM, p_NUMERO_REM);
    SET p_RESULTADO = 1;
    COMMIT;
  END IF;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 11. PRC_REMC_RECALCULAR: recuenta efectos e importe de una remesa a
--     partir de los efectos enlazados.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_REMC_RECALCULAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REMC_RECALCULAR`(
    IN p_SERIE  varchar(20),
    IN p_NUMERO varchar(20))
BEGIN
  DECLARE v_n     int DEFAULT 0;
  DECLARE v_total decimal(18,6) DEFAULT 0;
  SELECT COUNT(*), COALESCE(SUM(COALESCE(IMPORTE_PENDIENTE_EFEC,
                                         IMPORTE_EFEC)), 0)
    INTO v_n, v_total
    FROM fza_efectos_compra
   WHERE SERIE_REMC_EFEC  = p_SERIE
     AND NUMERO_REMC_EFEC = p_NUMERO;
  UPDATE fza_remesas_compra
     SET CONTADOR_EFECTOS_REMC = v_n,
         TOTAL_REMC            = v_total
   WHERE SERIE_REMC = p_SERIE AND NUMERO_REMC = p_NUMERO;
END ;;
DELIMITER ;


-- ----------------------------------------------------------------------------
-- 12. Registrar los Mtos de efectos y remesas en fza_winforms (idempotente).
--     Cablean 'Compras -> Efectos de pago' (EfectosCompra1) y
--     'Compras -> Remesas de pago' (RemesasCompra1).
-- ----------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'EfectosCompra',
       'Efectos de Pago a Proveedor',
       'EfectosCompra1',
       'inMtoEfectosCompra.TfrmMtoEfectosCompra',
       'Ctrl+Alt+E',
       'UniDataEfectosCompra.TdmEfectosCompra',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms` WHERE `CALL_WINF` = 'EfectosCompra'
 );

INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'RemesasCompra',
       'Remesas de Pago',
       'RemesasCompra1',
       'inMtoRemesasCompra.TfrmMtoRemesasCompra',
       'Ctrl+Alt+R',
       'UniDataRemesasCompra.TdmRemesasCompra',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms` WHERE `CALL_WINF` = 'RemesasCompra'
 );
