-- Añadir campo para persistir las columnas visibles de cada guía de grid.
-- Almacena los nombres de columna (alias) separados por punto y coma.
SET @col_exists = (
  SELECT COUNT(*)
    FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_informes_guias'
     AND COLUMN_NAME  = 'COLUMNAS_VISIBLES_INFGUI'
);
SET @do_alter = IF(@col_exists = 0,
  'ALTER TABLE fza_informes_guias ADD COLUMN COLUMNAS_VISIBLES_INFGUI TEXT DEFAULT NULL AFTER ESACTIVO_INFGUI',
  'SELECT ''COLUMNAS_VISIBLES_INFGUI ya existe''');
PREPARE stmt FROM @do_alter;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
