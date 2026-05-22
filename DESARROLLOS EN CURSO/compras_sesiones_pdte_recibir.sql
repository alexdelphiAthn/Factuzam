-- ============================================================================
-- Compras / sesiones — stock "Pendiente de recibir" (pedidos de compra)
--
-- Cuando una sesion genera PEDIDO (no albaran), no mueve stock fisico
-- pero queda como compromiso futuro. Para reflejar esa cantidad sin
-- contaminar fza_movimientos_almacen ni los calculos de stock real,
-- usamos una tabla aparte.
--
-- Cada fila representa una linea de pedido por SKU y almacen. Cuando el
-- pedido se transforma en albaran (recepcion fisica) el cliente debera
-- borrar la fila correspondiente y crear el movimiento de entrada en
-- fza_movimientos_almacen — eso queda fuera de este script.
--
-- PK: (SKU, ALMACEN, SERIE_DOC, NUMERO_DOC, LINEA) — la misma sesion
-- puede tener varias lineas para el mismo SKU si el cliente declara
-- subtotales (raro pero posible).
--
-- Idempotente: el CREATE solo se ejecuta si la tabla no existe.
-- ============================================================================

SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_pdte_recibir'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_articulos_pdte_recibir` ('
  '  `CODIGO_UNIDAD_PDR`  varchar(50)   NOT NULL,'
  '  `CODIGO_ALM_PDR`     varchar(10)   NOT NULL,'
  '  `SERIE_DOC_PDR`      varchar(12)   NOT NULL'
  '       COMMENT ''Serie del pedido de compra'','
  '  `NUMERO_DOC_PDR`     varchar(12)   NOT NULL'
  '       COMMENT ''Numero del pedido de compra'','
  '  `LINEA_PDR`          int(11)       NOT NULL,'
  '  `CODIGO_ART_PDR`     varchar(20)   NOT NULL,'
  '  `CODIGO_PRV_PDR`     varchar(20)   NULL DEFAULT NULL,'
  '  `CODIGO_EMP_PDR`     varchar(20)   NULL DEFAULT NULL,'
  '  `CANTIDAD_PDR`       decimal(19,6) NOT NULL DEFAULT 0,'
  '  `PRECIO_COMPRA_PDR`  decimal(19,6) NULL DEFAULT NULL,'
  '  `FECHA_PEDIDO_PDR`   date          NULL DEFAULT NULL,'
  '  `FECHA_PREVISTA_PDR` date          NULL DEFAULT NULL'
  '       COMMENT ''Fecha estimada de recepcion (opcional)'','
  '  `INSTANTE_MODIF`     timestamp     NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`      timestamp     NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`       varchar(100)  NOT NULL,'
  '  `USUARIO_MODIF`      varchar(100)  NOT NULL,'
  '  PRIMARY KEY (`CODIGO_UNIDAD_PDR`,`CODIGO_ALM_PDR`,'
  '               `SERIE_DOC_PDR`,`NUMERO_DOC_PDR`,`LINEA_PDR`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_pdte_recibir'
     AND INDEX_NAME   = 'IDX_PDR_SKU_ALM'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_articulos_pdte_recibir` '
  'ADD INDEX `IDX_PDR_SKU_ALM` '
  '(`CODIGO_UNIDAD_PDR`,`CODIGO_ALM_PDR`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_pdte_recibir'
     AND INDEX_NAME   = 'IDX_PDR_DOC'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_articulos_pdte_recibir` '
  'ADD INDEX `IDX_PDR_DOC` (`SERIE_DOC_PDR`,`NUMERO_DOC_PDR`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_pdte_recibir'
     AND INDEX_NAME   = 'IDX_PDR_ART'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_articulos_pdte_recibir` '
  'ADD INDEX `IDX_PDR_ART` (`CODIGO_ART_PDR`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- Vista de stock pendiente de recibir, agregada por SKU + almacen
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_articulos_pdte_recibir` AS
SELECT  `CODIGO_UNIDAD_PDR` AS `CODIGO_UNIDAD_SKU`,
        `CODIGO_ALM_PDR`    AS `CODIGO_ALM_ALM`,
        `CODIGO_ART_PDR`    AS `CODIGO_ART_ART`,
        SUM(`CANTIDAD_PDR`) AS `CANTIDAD_PTE_RECIBIR`,
        COUNT(*)            AS `NUM_LINEAS_PDR`,
        MIN(`FECHA_PEDIDO_PDR`)   AS `FECHA_PEDIDO_MIN`,
        MIN(`FECHA_PREVISTA_PDR`) AS `FECHA_PREVISTA_MIN`
  FROM  `fza_articulos_pdte_recibir`
 GROUP  BY `CODIGO_UNIDAD_PDR`, `CODIGO_ALM_PDR`, `CODIGO_ART_PDR`;
