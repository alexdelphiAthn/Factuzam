-- =============================================================================
-- Amplia el contenido SQL del generador de procesos
-- =============================================================================
-- TEXT admite 65.535 bytes y algunos scripts de traducciones superan ese
-- limite. MEDIUMTEXT permite guardar y ejecutar esos scripts completos.
-- Idempotente: solo modifica la columna si todavia no es MEDIUMTEXT/LONGTEXT.
-- =============================================================================
SET @sExisteColumna := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_generadorprocesos'
     AND COLUMN_NAME = 'PROCESO_GENERADOR_PROCESO_GP'
);
SET @sTipoActual := (
  SELECT DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_generadorprocesos'
     AND COLUMN_NAME = 'PROCESO_GENERADOR_PROCESO_GP'
   LIMIT 1
);
SET @sSql := IF(
  @sExisteColumna = 0,
  'SELECT ''No existe fza_generadorprocesos.PROCESO_GENERADOR_PROCESO_GP'' AS info',
  IF(
    @sTipoActual IN ('mediumtext', 'longtext'),
    'SELECT ''PROCESO_GENERADOR_PROCESO_GP ya admite scripts grandes, se omite'' AS info',
    'ALTER TABLE `fza_generadorprocesos`
       MODIFY COLUMN `PROCESO_GENERADOR_PROCESO_GP` MEDIUMTEXT NULL DEFAULT NULL'
  )
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
