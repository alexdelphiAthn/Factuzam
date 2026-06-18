-- ============================================================================
-- Bancos por empresa (fza_empresas_bancos, sufijo EMPBAN) y enganche en los
-- documentos de cobro/pago.
--
-- Cada empresa puede tener N cuentas bancarias. Cada cuenta lleva IBAN, un
-- nombre/alias y (deducible del IBAN) el codigo de entidad del catalogo
-- fza_bancos. Dos cuentas se pueden marcar "por defecto": una para COBRO
-- (donde se ingresa: recibos de venta) y otra para PAGO (cuenta de cargo:
-- efectos de compra). Pueden ser la misma o distintas.
--
-- Este script:
--   1. Crea fza_empresas_bancos (EMPBAN) + indice.
--   2. Anade la cuenta de la empresa al EFECTO de compra (cuenta de cargo):
--      fza_efectos_compra.CODIGO_EMPBAN_EFEC / IBAN_EMP_EFEC.
--   3. Anade la cuenta de la empresa al RECIBO de venta (cuenta de ingreso):
--      fza_recibos.CODIGO_EMPBAN_REC / IBAN_EMP_REC.
--   4. Crea la vista vi_empresas_bancos (con el nombre del banco resuelto).
--   5. Registra el contador 'EB' (BANCOS POR EMPRESA) para el alta automatica.
--
-- Requiere bancos_catalogo.sql (fza_bancos) ejecutado antes (la vista hace
-- LEFT JOIN, asi que no es bloqueante, pero el catalogo es su companero).
-- Idempotente (INFORMATION_SCHEMA / INSERT ... WHERE NOT EXISTS). NO toca
-- factuzam_original.sql.
-- ============================================================================
-- ----------------------------------------------------------------------------
-- 1. fza_empresas_bancos (EMPBAN): cuentas bancarias por empresa.
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_empresas_bancos'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_empresas_bancos` ('
  '  `CODIGO_EMPBAN`     varchar(8)  NOT NULL,'
  '  `CODIGO_EMP_EMPBAN` varchar(10) NOT NULL'
  '       COMMENT ''FK logica a fza_empresas'','
  '  `NOMBRE_EMPBAN`     varchar(100) NULL DEFAULT NULL'
  '       COMMENT ''Alias de la cuenta (p.ej. Nomina Santander)'','
  '  `CODIGO_BAN_EMPBAN` varchar(4)  NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_bancos (entidad, deducible del IBAN)'','
  '  `IBAN_EMPBAN`       varchar(34) NULL DEFAULT NULL,'
  '  `ENTIDAD_EMPBAN`        varchar(4)  NULL DEFAULT NULL,'
  '  `OFICINA_EMPBAN`        varchar(4)  NULL DEFAULT NULL,'
  '  `DIGITO_CONTROL_EMPBAN` varchar(2)  NULL DEFAULT NULL,'
  '  `CUENTA_EMPBAN`         varchar(10) NULL DEFAULT NULL,'
  '  `BIC_EMPBAN`        varchar(11) NULL DEFAULT NULL,'
  '  `ESDEFECTO_COBRO_EMPBAN` varchar(1) NOT NULL DEFAULT ''N'''
  '       COMMENT ''S/N — cuenta por defecto para COBRO (ingreso de ventas)'','
  '  `ESDEFECTO_PAGO_EMPBAN`  varchar(1) NOT NULL DEFAULT ''N'''
  '       COMMENT ''S/N — cuenta por defecto para PAGO (cargo de compras)'','
  '  `ESACTIVO_EMPBAN`   varchar(1)  NOT NULL DEFAULT ''S'','
  '  `ORDEN_EMPBAN`      int(11)     NULL DEFAULT 0,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`CODIGO_EMPBAN`)'
  ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_empresas_bancos'
     AND INDEX_NAME   = 'IDX_EMPBAN_EMP'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_empresas_bancos` '
  'ADD INDEX `IDX_EMPBAN_EMP` (`CODIGO_EMP_EMPBAN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. Cuenta de la empresa en el EFECTO de compra (cuenta de cargo / pago).
--    OJO: IBAN_EFEC (ya existente) es la cuenta del PROVEEDOR. Las columnas
--    nuevas guardan la cuenta de la EMPRESA desde la que se paga.
-- ----------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
     AND COLUMN_NAME  = 'CODIGO_EMPBAN_EFEC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_efectos_compra` '
  'ADD COLUMN `CODIGO_EMPBAN_EFEC` varchar(8) NULL DEFAULT NULL '
  'COMMENT ''Cuenta de la empresa (cargo) — FK a fza_empresas_bancos'' '
  'AFTER `IBAN_EFEC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_efectos_compra'
     AND COLUMN_NAME  = 'IBAN_EMP_EFEC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_efectos_compra` '
  'ADD COLUMN `IBAN_EMP_EFEC` varchar(34) NULL DEFAULT NULL '
  'COMMENT ''IBAN de la empresa (cargo), denormalizado del banco'' '
  'AFTER `CODIGO_EMPBAN_EFEC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. Cuenta de la empresa en el RECIBO de venta (cuenta de ingreso / cobro).
--    OJO: IBAN_CLI_REC (ya existente) es la cuenta del CLIENTE. Las columnas
--    nuevas guardan la cuenta de la EMPRESA donde se ingresa.
-- ----------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_recibos'
     AND COLUMN_NAME  = 'CODIGO_EMPBAN_REC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_recibos` '
  'ADD COLUMN `CODIGO_EMPBAN_REC` varchar(8) NULL DEFAULT NULL '
  'COMMENT ''Cuenta de la empresa (ingreso) — FK a fza_empresas_bancos'' '
  'AFTER `IBAN_CLI_REC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_recibos'
     AND COLUMN_NAME  = 'IBAN_EMP_REC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_recibos` '
  'ADD COLUMN `IBAN_EMP_REC` varchar(34) NULL DEFAULT NULL '
  'COMMENT ''IBAN de la empresa (ingreso), denormalizado del banco'' '
  'AFTER `CODIGO_EMPBAN_REC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 4. Vista vi_empresas_bancos: cuentas de empresa con el nombre del banco
--    resuelto desde el catalogo. La usa el Mto de empresas (pestana Bancos).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_empresas_bancos` AS
SELECT  eb.*,
        b.`NOMBRE_BAN` AS `NOMBRE_BAN_VIEW_EMPBAN`,
        b.`BIC_BAN`    AS `BIC_BAN_VIEW_EMPBAN`
  FROM  `fza_empresas_bancos` eb
  LEFT  JOIN `fza_bancos` b
         ON b.`CODIGO_BAN` = eb.`CODIGO_BAN_EMPBAN`;

-- ----------------------------------------------------------------------------
-- 5. Contador 'EB' (BANCOS POR EMPRESA) para el alta automatica de codigo,
--    igual patron que 'ES' (series por empresa).
-- ----------------------------------------------------------------------------
INSERT INTO `fza_tipos_documentos`
  (`CODIGO_TIPO_DOCUMENTO_TD`, `DESCRIPCION_TIPO_DOCUMENTO_TD`,
   `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`)
SELECT 'EB', 'BANCOS POR EMPRESA', 'fza_empresas_bancos'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_documentos`
    WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'EB'
 );

INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
   `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT 'EB', '-', '-', 0, 4, 'S', 'S',
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'EB' AND `SERIE_CON` = '-'
 );
