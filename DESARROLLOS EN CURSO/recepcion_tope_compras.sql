-- ============================================================================
-- Compras: fecha tope de recepcion y resumenes de lista
--
-- Anade fecha limite de recepcion en sesiones y pedidos de compra. Reexpone
-- las vistas de pedidos y albaranes con temporada, fechas y totales agregados
-- para que las listas puedan pintar vencidos pendientes de recibir.
--
-- Idempotente: cada DDL comprueba INFORMATION_SCHEMA antes de aplicar.
-- ============================================================================

SET @col_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_compras_sesiones'
     AND COLUMN_NAME = 'FECHA_TOPE_RECEPCION_SES'
);

SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones`
     ADD COLUMN `FECHA_TOPE_RECEPCION_SES` date NULL DEFAULT NULL
       COMMENT ''Fecha limite prevista para recibir la mercancia''
       AFTER `FECHA_SES`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_compras_sesiones'
     AND INDEX_NAME = 'IDX_SES_FECHA_TOPE_RECEPCION'
);

SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_compras_sesiones`
     ADD INDEX `IDX_SES_FECHA_TOPE_RECEPCION`
       (`FECHA_TOPE_RECEPCION_SES`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_pedidos_compra'
     AND COLUMN_NAME = 'FECHA_TOPE_RECEPCION_PEDC'
);

SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_pedidos_compra`
     ADD COLUMN `FECHA_TOPE_RECEPCION_PEDC` date NULL DEFAULT NULL
       COMMENT ''Fecha limite prevista para recibir la mercancia''
       AFTER `FECHA_PREVISTA_PEDC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_pedidos_compra'
     AND INDEX_NAME = 'IDX_PEDC_FECHA_TOPE_RECEPCION'
);

SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra`
     ADD INDEX `IDX_PEDC_FECHA_TOPE_RECEPCION`
       (`FECHA_TOPE_RECEPCION_PEDC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_pedidos_compra` AS
SELECT p.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_PEDC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_PEDC`,
       t.`PV` AS `TEMPORADA_PEDC`,
       p.`FECHA_PEDC` AS `FECHA_REALIZACION_PEDC`,
       p.`FECHA_PREVISTA_PEDC` AS `FECHA_EFECTO_STOCK_PEDC`,
       COALESCE(r.`CANTIDAD_PEDIDA_PEDC`, 0) AS `CANTIDAD_PEDIDA_PEDC`,
       COALESCE(r.`CANTIDAD_PEDIDA_PEDC`, 0) AS `TOTAL_PRENDAS_PEDC`,
       COALESCE(r.`CANTIDAD_RECIBIDA_PEDC`, 0) AS `CANTIDAD_RECIBIDA_PEDC`,
       GREATEST(COALESCE(r.`CANTIDAD_PEDIDA_PEDC`, 0) -
                COALESCE(r.`CANTIDAD_RECIBIDA_PEDC`, 0), 0)
          AS `CANTIDAD_PENDIENTE_RECEPCION_PEDC`,
       COALESCE(r.`TOTAL_LINEAS_PEDC`, 0) AS `TOTAL_LINEAS_PEDC`
  FROM `fza_pedidos_compra` p
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = p.`CODIGO_PRV_PEDC`
  LEFT JOIN `fza_empresas` emp
    ON emp.`CODIGO_EMP_EMP` = p.`CODIGO_EMP_PEDC`
  LEFT JOIN `fza_propiedades_valores` t
    ON t.`ID_PV_ARTPROP` = p.`ID_PV_TEMPORADA_PEDC`
   AND t.`ID_PROP_PV` = 'TEMPORADA'
  LEFT JOIN (
    SELECT l.`SERIE_PEDC_PEDCLIN`,
           l.`NUMERO_PEDC_PEDCLIN`,
           COALESCE(SUM(l.`CANTIDAD_PEDCLIN`), 0)
              AS `CANTIDAD_PEDIDA_PEDC`,
           COALESCE(SUM(l.`CANTIDAD_RECIBIDA_PEDCLIN`), 0)
              AS `CANTIDAD_RECIBIDA_PEDC`,
           COALESCE(SUM(l.`TOTAL_PEDCLIN`), 0)
              AS `TOTAL_LINEAS_PEDC`
      FROM `fza_pedidos_compra_lineas` l
     GROUP BY l.`SERIE_PEDC_PEDCLIN`, l.`NUMERO_PEDC_PEDCLIN`
  ) r
    ON r.`SERIE_PEDC_PEDCLIN` = p.`SERIE_PEDC`
   AND r.`NUMERO_PEDC_PEDCLIN` = p.`NUMERO_PEDC`;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_albaranes_compra` AS
SELECT a.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_ALBC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_ALBC`,
       tp.`PV` AS `TEMPORADA_ALBC`,
       a.`FECHA_ALBC` AS `FECHA_REALIZACION_ALBC`,
       a.`FECHA_ALBC` AS `FECHA_EFECTO_STOCK_ALBC`,
       p.`FECHA_TOPE_RECEPCION_PEDC` AS `FECHA_TOPE_RECEPCION_ALBC`,
       COALESCE(r.`TOTAL_PRENDAS_ALBC`, 0) AS `TOTAL_PRENDAS_ALBC`,
       COALESCE(r.`TOTAL_LINEAS_ALBC`, 0) AS `TOTAL_LINEAS_ALBC`
  FROM `fza_albaranes_compra` a
  LEFT JOIN `fza_proveedores` prv
    ON prv.`CODIGO_PRV_PRV` = a.`CODIGO_PRV_ALBC`
  LEFT JOIN `fza_empresas` emp
    ON emp.`CODIGO_EMP_EMP` = a.`CODIGO_EMP_ALBC`
  LEFT JOIN `fza_pedidos_compra` p
    ON p.`SERIE_PEDC` = a.`SERIE_PED_ALBC`
   AND p.`NUMERO_PEDC` = a.`NUMERO_PED_ALBC`
  LEFT JOIN `fza_propiedades_valores` tp
    ON tp.`ID_PV_ARTPROP` = p.`ID_PV_TEMPORADA_PEDC`
   AND tp.`ID_PROP_PV` = 'TEMPORADA'
  LEFT JOIN (
    SELECT l.`SERIE_ALBC_ALBCLIN`,
           l.`NUMERO_ALBC_ALBCLIN`,
           COALESCE(SUM(COALESCE(l.`TOTAL_UNIDADES_ALBCLIN`,
                                 l.`CANTIDAD_ALBCLIN`, 0)), 0)
              AS `TOTAL_PRENDAS_ALBC`,
           COALESCE(SUM(l.`TOTAL_ALBCLIN`), 0)
              AS `TOTAL_LINEAS_ALBC`
      FROM `fza_albaranes_compra_lineas` l
     GROUP BY l.`SERIE_ALBC_ALBCLIN`, l.`NUMERO_ALBC_ALBCLIN`
  ) r
    ON r.`SERIE_ALBC_ALBCLIN` = a.`SERIE_ALBC`
   AND r.`NUMERO_ALBC_ALBCLIN` = a.`NUMERO_ALBC`;
