-- ============================================================================
-- Arqueo de Caja: Recuento + Tabla hija de detalle por forma de pago
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
--
-- Añade a fza_caja_arqueos las columnas de recuento global y crea la tabla
-- hija fza_caja_arqueos_recuento con una fila por forma de pago por arqueo.
-- Permite comparar lo que el sistema ha calculado con lo que el usuario ha
-- contado físicamente en caja.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Columnas nuevas en fza_caja_arqueos (idempotente)
-- ---------------------------------------------------------------------------

-- Total que el usuario ha contado (suma de todos los recuentos por forma)
SET @sTabla = 'fza_caja_arqueos';
SET @sColumna = 'TOTAL_RECUENTO_ARQ';
SET @sExiste = (SELECT COUNT(*)
                  FROM INFORMATION_SCHEMA.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME   = @sTabla
                   AND COLUMN_NAME  = @sColumna);
SET @sSQL = IF(@sExiste = 0,
  CONCAT('ALTER TABLE `', @sTabla, '` ADD COLUMN `', @sColumna,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Suma de los importes recontados por el usuario'' ',
         'AFTER `TOTAL_SALDO_RECONTAR_ARQ`'),
  'SELECT 1');
PREPARE stmt FROM @sSQL;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Diferencia total = recuento - saldo teórico
SET @sColumna = 'DIFERENCIA_TOTAL_ARQ';
SET @sExiste = (SELECT COUNT(*)
                  FROM INFORMATION_SCHEMA.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME   = @sTabla
                   AND COLUMN_NAME  = @sColumna);
SET @sSQL = IF(@sExiste = 0,
  CONCAT('ALTER TABLE `', @sTabla, '` ADD COLUMN `', @sColumna,
         '` decimal(19,6) NOT NULL DEFAULT ''0.000000'' ',
         'COMMENT ''Recuento − Saldo teórico (positivo = sobrante)'' ',
         'AFTER `TOTAL_RECUENTO_ARQ`'),
  'SELECT 1');
PREPARE stmt FROM @sSQL;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2) Tabla hija: detalle del recuento por forma de pago (sufijo _ARQR)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `fza_caja_arqueos_recuento` (
  `ID_ARQR`                  int(11)       NOT NULL AUTO_INCREMENT
      COMMENT 'PK autoincremental',
  `CODIGO_ARQ_ARQR`          varchar(30)   NOT NULL
      COMMENT 'FK lógica a fza_caja_arqueos.CODIGO_ARQ',
  `CODIGO_FP_CFP_ARQR`       varchar(20)   NOT NULL
      COMMENT 'FK lógica a fza_caja_formas_pago.CODIGO_FP_CFP',
  `DESCRIPCION_FP_ARQR`      varchar(100)  NOT NULL DEFAULT ''
      COMMENT 'Snapshot de DESCRIPCION_FORMA_PAGO_CFP al momento del arqueo',
  `ESCAJON_ARQR`             varchar(1)    NOT NULL DEFAULT 'N'
      COMMENT 'Snapshot de ESABRE_CAJON_FORMA_PAGO_CFP (S/N)',
  `IMPORTE_SISTEMA_ARQR`     decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'Importe calculado por el sistema para esta forma de pago',
  `IMPORTE_RECUENTO_ARQR`    decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'Importe que el usuario ha contado físicamente',
  `DIFERENCIA_ARQR`          decimal(19,6) NOT NULL DEFAULT '0.000000'
      COMMENT 'Recuento − Sistema (positivo = sobrante)',
  `INSTANTE_MODIF`           timestamp     NOT NULL
      DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA`            timestamp     NOT NULL
      DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`             varchar(100)  NOT NULL,
  `USUARIO_MODIF`            varchar(100)  NOT NULL,
  PRIMARY KEY (`ID_ARQR`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Índice por arqueo (para listar el detalle de un arqueo dado)
SET @sExiste = (SELECT COUNT(*)
                  FROM INFORMATION_SCHEMA.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME   = 'fza_caja_arqueos_recuento'
                   AND INDEX_NAME   = 'IDX_ARQR_ARQUEO');
SET @sSQL = IF(@sExiste = 0,
  'ALTER TABLE `fza_caja_arqueos_recuento` ADD INDEX `IDX_ARQR_ARQUEO` (`CODIGO_ARQ_ARQR`)',
  'SELECT 1');
PREPARE stmt FROM @sSQL;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Índice único para evitar duplicados (un arqueo + una forma de pago)
SET @sExiste = (SELECT COUNT(*)
                  FROM INFORMATION_SCHEMA.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME   = 'fza_caja_arqueos_recuento'
                   AND INDEX_NAME   = 'UQ_ARQR_ARQ_FP');
SET @sSQL = IF(@sExiste = 0,
  'ALTER TABLE `fza_caja_arqueos_recuento` ADD UNIQUE INDEX `UQ_ARQR_ARQ_FP` (`CODIGO_ARQ_ARQR`, `CODIGO_FP_CFP_ARQR`)',
  'SELECT 1');
PREPARE stmt FROM @sSQL;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
