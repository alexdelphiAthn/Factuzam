-- ============================================================================
-- temporada_pedido.sql
--
-- Anyade ID_PV_TEMPORADA_PEDC a la cabecera de pedidos de compra,
-- analogo a ID_PV_TEMPORADA_SES en sesiones. La temporada se propaga:
--   sesion (ID_PV_TEMPORADA_SES)
--     -> pedido (ID_PV_TEMPORADA_PEDC) al materializar
--     -> modal "Crear albaran" se pre-rellena con la del pedido
--
-- FK logica a fza_propiedades_valores.ID_PV_ARTPROP con ID_PROP_PV='TEMPORADA'.
--
-- Todo idempotente: chequea INFORMATION_SCHEMA antes de aplicar.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna ID_PV_TEMPORADA_PEDC en cabecera
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra'
     AND COLUMN_NAME  = 'ID_PV_TEMPORADA_PEDC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_pedidos_compra` '
  'ADD COLUMN `ID_PV_TEMPORADA_PEDC` int(11) NULL DEFAULT NULL '
  '  COMMENT ''FK logica fza_propiedades_valores.ID_PV_ARTPROP con '
  'ID_PROP_PV=TEMPORADA. Se hereda de la sesion al materializar y '
  'se pre-rellena en el modal Crear Albaran al generar albaran desde pedido.''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra'
     AND INDEX_NAME   = 'IDX_PEDC_TEMPORADA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra` '
  'ADD INDEX `IDX_PEDC_TEMPORADA` (`ID_PV_TEMPORADA_PEDC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Refrescar vi_pedidos_compra para exponer la nueva columna y el nombre
--    legible de la temporada (PV). Mantiene la forma original (p.*).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_pedidos_compra` AS
SELECT  p.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_PEDC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_PEDC,
        t.PV                   AS TEMPORADA_PEDC
  FROM  fza_pedidos_compra p
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = p.CODIGO_PRV_PEDC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = p.CODIGO_EMP_PEDC
  LEFT  JOIN fza_propiedades_valores t
         ON t.ID_PV_ARTPROP    = p.ID_PV_TEMPORADA_PEDC
        AND t.ID_PROP_PV       = 'TEMPORADA';
