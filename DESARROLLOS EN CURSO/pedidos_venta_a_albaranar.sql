-- =============================================================================
-- Pedidos de venta: cantidad pendiente de albaranar por linea
-- =============================================================================
-- CANTIDAD_ENTREGADA_PEDLIN representa lo ya albaranado/entregado real.
-- El grid de pedidos necesita guardar una preparacion pendiente aunque el
-- albaran no se emita todavia. Para no mezclar ambos conceptos se anade
-- CANTIDAD_A_ALBARANAR_PEDLIN como borrador persistente por linea.
--
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_lineas'
     AND COLUMN_NAME  = 'CANTIDAD_A_ALBARANAR_PEDLIN'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_pedidos_lineas
     ADD COLUMN CANTIDAD_A_ALBARANAR_PEDLIN decimal(19,6) NULL DEFAULT 0
     AFTER CANTIDAD_ENTREGADA_PEDLIN',
  'SELECT ''CANTIDAD_A_ALBARANAR_PEDLIN ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_pedidos_lineas AS
SELECT pl.*,
       pl.CANTIDAD_PEDLIN - IFNULL(pl.CANTIDAD_ENTREGADA_PEDLIN, 0)
         AS CANTIDAD_PENDIENTE_CALC_PEDLIN,
       GREATEST(pl.CANTIDAD_PEDLIN -
                IFNULL(pl.CANTIDAD_ENTREGADA_PEDLIN, 0) -
                IFNULL(pl.CANTIDAD_A_ALBARANAR_PEDLIN, 0), 0)
         AS CANTIDAD_PENDIENTE_A_ALBARANAR_PEDLIN
  FROM fza_pedidos_lineas pl;
