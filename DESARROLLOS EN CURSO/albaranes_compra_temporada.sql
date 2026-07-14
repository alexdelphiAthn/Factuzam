-- =============================================================================
-- albaranes_compra_temporada.sql
-- Conserva en la cabecera la temporada de ocalbpro.Temporada y permite
-- seleccionarla opcionalmente en el mantenimiento de albaranes de compra.
-- FK logica a fza_propiedades_valores.ID_PV_ARTPROP con propiedad TEMPORADA.
-- Requiere haber aplicado antes recepcion_tope_compras.sql.
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================================
SET @col_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_albaranes_compra'
     AND COLUMN_NAME = 'ID_PV_TEMPORADA_ALBC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_albaranes_compra` '
  'ADD COLUMN `ID_PV_TEMPORADA_ALBC` int(11) NULL DEFAULT NULL '
  '  COMMENT ''FK logica fza_propiedades_valores.ID_PV_ARTPROP con '
  'ID_PROP_PV=TEMPORADA. Procede de ocalbpro.Temporada en la migracion.'' '
  'AFTER `FORMA_PAGO_ALBC`',
  'SELECT ''ID_PV_TEMPORADA_ALBC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @idx_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_albaranes_compra'
     AND INDEX_NAME = 'IDX_ALBC_TEMPORADA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra` '
  'ADD INDEX `IDX_ALBC_TEMPORADA` (`ID_PV_TEMPORADA_ALBC`)',
  'SELECT ''IDX_ALBC_TEMPORADA ya existe, se omite'' AS info'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE `fza_albaranes_compra` a
  JOIN `fza_pedidos_compra` p
    ON p.`SERIE_PEDC` = a.`SERIE_PED_ALBC`
   AND p.`NUMERO_PEDC` = a.`NUMERO_PED_ALBC`
   SET a.`ID_PV_TEMPORADA_ALBC` = p.`ID_PV_TEMPORADA_PEDC`
 WHERE a.`ID_PV_TEMPORADA_ALBC` IS NULL
   AND p.`ID_PV_TEMPORADA_PEDC` IS NOT NULL;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_albaranes_compra` AS
SELECT a.*,
       prv.`NOMBRE_PRV` AS `NOMBRE_PRV_ALBC`,
       emp.`RAZON_SOCIAL_EMP` AS `RAZON_SOCIAL_EMPRESA_VIEW_ALBC`,
       ta.`PV` AS `TEMPORADA_ALBC`,
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
  LEFT JOIN `fza_propiedades_valores` ta
    ON ta.`ID_PV_ARTPROP` = a.`ID_PV_TEMPORADA_ALBC`
   AND ta.`ID_PROP_PV` = 'TEMPORADA'
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
