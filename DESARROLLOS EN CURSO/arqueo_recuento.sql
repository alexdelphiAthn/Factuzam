-- ============================================================================
-- Arqueo de Caja: migración idempotente de columnas
-- ============================================================================
-- La tabla fza_caja_arqueos fue creada originalmente desde
-- factuzam_original.sql con un esquema base. Este script añade las
-- columnas que faltan para el módulo de recuento (cierre Z) sin
-- destruir datos existentes.
--
-- Idempotente: comprueba cada columna antes de crearla.
-- Re-ejecutable en cualquier momento.
-- ============================================================================

SET @sTabla = 'fza_caja_arqueos';

-- ---------------------------------------------------------------------------
-- Columnas de desglose de ventas (pueden faltar si la tabla viene de un
-- esquema anterior al desglose normales/préstamos/devoluciones)
-- ---------------------------------------------------------------------------

SET @c = 'TOTAL_PRESTAMOS_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''SUM TIPO=DE en el rango (compromiso bruto)'' ',
         'AFTER `TOTAL_NETO_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'TOTAL_VENTAS_NORMALES_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'AFTER `TOTAL_PRESTAMOS_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'TOTAL_VENTAS_PRESTAMOS_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'AFTER `TOTAL_VENTAS_NORMALES_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'TOTAL_DEVOLUCIONES_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'AFTER `TOTAL_VENTAS_PRESTAMOS_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'TOTAL_VENTAS_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'AFTER `TOTAL_DEVOLUCIONES_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- Ventas a crédito / albarán a cuenta (legacy ImpAlbaranCdo). El migrador
-- la escribe; sin esta columna la migración de arqueos aborta con 42S22.
SET @c = 'TOTAL_VENTA_CREDITO_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Ventas a crédito / albarán (legacy ImpAlbaranCdo)'' ',
         'AFTER `TOTAL_VENTAS_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Columnas de recuento y diferencia
-- ---------------------------------------------------------------------------

SET @c = 'TOTAL_RECUENTO_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Suma de los importes recontados por el usuario'' ',
         'AFTER `TOTAL_SALDO_RECONTAR_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'DIFERENCIA_TOTAL_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Recuento - Saldo teórico (positivo = sobrante)'' ',
         'AFTER `TOTAL_RECUENTO_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Efectivo dejado en caja (cambio para el día siguiente)
-- Este valor se usa como EfectivoAnterior en el siguiente arqueo.
-- ---------------------------------------------------------------------------

SET @c = 'EFECTIVO_DEJADO_CAJA_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Efectivo que se deja en caja como cambio para el día siguiente'' ',
         'AFTER `DIFERENCIA_TOTAL_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Desglose de billetes y monedas del recuento
-- ---------------------------------------------------------------------------

SET @c = 'DESGLOSE_BILLETES_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` text NULL DEFAULT NULL ',
         'COMMENT ''Desglose billetes/monedas formato denom:uds;...'' ',
         'AFTER `EFECTIVO_DEJADO_CAJA_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Importe y concepto de la retirada al cerrar
-- ---------------------------------------------------------------------------

SET @c = 'IMPORTE_RETIRADA_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'AFTER `DESGLOSE_BILLETES_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'CONCEPTO_RETIRADA_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` varchar(100) NULL DEFAULT NULL ',
         'AFTER `IMPORTE_RETIRADA_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Depósitos y encargos (importes del legacy que el arqueo conserva aparte)
-- El migrador los escribe; sin estas columnas la migración aborta con 42S22.
-- ---------------------------------------------------------------------------

SET @c = 'TOTAL_DEPOSITOS_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Depósitos (legacy ImpDeposito)'' ',
         'AFTER `TOTAL_OTROS_INGRESOS_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c = 'TOTAL_ENCARGOS_ARQ';
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=@sTabla AND COLUMN_NAME=@c);
SET @s = IF(@e=0,
  CONCAT('ALTER TABLE `',@sTabla,'` ADD COLUMN `',@c,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Encargos (legacy ImpEncargo)'' ',
         'AFTER `TOTAL_DEPOSITOS_ARQ`'),
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Tabla hija: detalle del recuento por forma de pago (sufijo _ARQR)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `fza_caja_arqueos_recuento` (
  `ID_ARQR`                  int(11)       NOT NULL AUTO_INCREMENT,
  `CODIGO_ARQ_ARQR`          varchar(30)   NOT NULL,
  `CODIGO_FP_CFP_ARQR`       varchar(20)   NOT NULL,
  `DESCRIPCION_FP_ARQR`      varchar(100)  NOT NULL DEFAULT '',
  `ESCAJON_ARQR`             varchar(1)    NOT NULL DEFAULT 'N',
  `IMPORTE_SISTEMA_ARQR`     decimal(19,6) NOT NULL DEFAULT '0.000000',
  `IMPORTE_RECUENTO_ARQR`    decimal(19,6) NOT NULL DEFAULT '0.000000',
  `DIFERENCIA_ARQR`          decimal(19,6) NOT NULL DEFAULT '0.000000',
  `INSTANTE_MODIF`           timestamp     NOT NULL
      DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA`            timestamp     NOT NULL
      DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`             varchar(100)  NOT NULL,
  `USUARIO_MODIF`            varchar(100)  NOT NULL,
  PRIMARY KEY (`ID_ARQR`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Índices de la tabla hija (idempotente)
SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
          WHERE TABLE_SCHEMA=DATABASE()
            AND TABLE_NAME='fza_caja_arqueos_recuento'
            AND INDEX_NAME='IDX_ARQR_ARQUEO');
SET @s = IF(@e=0,
  'ALTER TABLE `fza_caja_arqueos_recuento` ADD INDEX `IDX_ARQR_ARQUEO` (`CODIGO_ARQ_ARQR`)',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @e = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
          WHERE TABLE_SCHEMA=DATABASE()
            AND TABLE_NAME='fza_caja_arqueos_recuento'
            AND INDEX_NAME='UQ_ARQR_ARQ_FP');
SET @s = IF(@e=0,
  'ALTER TABLE `fza_caja_arqueos_recuento` ADD UNIQUE INDEX `UQ_ARQR_ARQ_FP` (`CODIGO_ARQ_ARQR`, `CODIGO_FP_CFP_ARQR`)',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
