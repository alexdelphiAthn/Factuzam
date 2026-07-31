-- D26: distingue las traducciones descargadas de los textos de trabajo.
-- Idempotente: comprueba la columna y el indice antes de crearlos.
SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_traducciones'
);
SET @sExisteColumna := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_traducciones'
     AND COLUMN_NAME = 'ESDESCARGADA_TRAD'
);
SET @sSql := IF(
  @sExisteTabla = 1 AND @sExisteColumna = 0,
  'ALTER TABLE `fza_traducciones`
     ADD COLUMN `ESDESCARGADA_TRAD` varchar(1) NOT NULL DEFAULT ''N''
     AFTER `ESACTIVO_TRAD`',
  'SELECT ''ESDESCARGADA_TRAD ya existe o falta la tabla, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_traducciones'
     AND INDEX_NAME = 'IDX_TRAD_DESCARGADA_IDIOMA'
);
SET @sSql := IF(
  @sExisteTabla = 1 AND @sExisteIndice = 0,
  'ALTER TABLE `fza_traducciones`
     ADD INDEX `IDX_TRAD_DESCARGADA_IDIOMA`
       (`ESDESCARGADA_TRAD`, `IDIOMA_TRAD`)',
  'SELECT ''IDX_TRAD_DESCARGADA_IDIOMA ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
