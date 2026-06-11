-- =============================================================================
-- ESARQUEO_PROP: marca de "sale en el resumen por propiedad del arqueo".
-- =============================================================================
-- Permite elegir, propiedad a propiedad, cuales se desglosan en el bloque
-- "Neto ventas por propiedad" del arqueo (pantalla F11 y ticket). Por defecto
-- NO sale ninguna (opt-in); TEMPORADA se marca de fabrica porque es el caso
-- de uso que motiva la funcion.
--
-- Idempotente: ALTER solo si la columna no existe; UPDATE de TEMPORADA solo
-- si sigue en 'N' (no pisa una decision manual posterior).
-- =============================================================================

-- 1. Columna ESARQUEO_PROP en fza_propiedades (DEFAULT 'N' = opt-in).
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_propiedades'
     AND COLUMN_NAME  = 'ESARQUEO_PROP'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_propiedades` '
  'ADD COLUMN `ESARQUEO_PROP` varchar(1) NOT NULL DEFAULT ''N'' '
  '  COMMENT ''S: la propiedad sale en el resumen por propiedad del arqueo'' '
  '  AFTER `ESACTIVO_PROP`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. TEMPORADA visible en el arqueo de fabrica (idempotente).
UPDATE `fza_propiedades`
   SET `ESARQUEO_PROP` = 'S'
 WHERE `CODIGO_PROP_ARTPROP` = 'TEMPORADA'
   AND `ESARQUEO_PROP` = 'N';

-- =============================================================================
-- ROLLBACK (manual, no se ejecuta):
--   ALTER TABLE `fza_propiedades` DROP COLUMN `ESARQUEO_PROP`;
-- =============================================================================
