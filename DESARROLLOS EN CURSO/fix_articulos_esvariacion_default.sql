-- =============================================================================
-- Fix: fza_articulos.ESVARIACION_ART sin DEFAULT
-- =============================================================================
-- Al dar de alta un articulo MySQL devuelve:
--   1364 Field 'ESVARIACION_ART' doesn't have a default value
-- Causa: la columna es NOT NULL sin DEFAULT y el INSERT de articulos
-- (UniDataArticulos.dfm) no la incluye en su lista de columnas. Marcar o
-- desmarcar el check "Tiene Tallas/Col" no ayuda porque ese valor no viaja
-- en el INSERT.
--
-- Solucion: darle DEFAULT 'N' (convencion de booleanos S/N del proyecto, el
-- articulo nuevo no es de variaciones por defecto). Asi el INSERT que omite
-- la columna ya no falla. No cambia el tipo ni el NOT NULL.
--
-- Idempotente: solo aplica el ALTER si la columna aun no tiene DEFAULT.
-- NO toca factuzam_original.sql.
-- =============================================================================
SET @sSinDefault := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos'
     AND COLUMN_NAME  = 'ESVARIACION_ART'
     AND COLUMN_DEFAULT IS NULL
);
SET @sSql := IF(@sSinDefault = 1,
  'ALTER TABLE `fza_articulos`
     ALTER COLUMN `ESVARIACION_ART` SET DEFAULT ''N''',
  'SELECT ''ESVARIACION_ART ya tiene DEFAULT, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
