-- =============================================================================
-- Tipo fiscal de las facturas rectificativas
-- =============================================================================
-- Conserva la modalidad elegida al emitir una rectificativa:
-- I = por diferencias; S = sustitutiva.
-- Las rectificativas historicas sin valor se interpretan como I para mantener
-- el comportamiento anterior.
-- Idempotente: la columna solo se anade si no existe.
-- =============================================================================
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_facturas'
     AND COLUMN_NAME = 'TIPO_RECTIFICATIVA_FAC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN TIPO_RECTIFICATIVA_FAC varchar(1) NULL DEFAULT NULL
     COMMENT ''I=por diferencias; S=sustitutiva''
     AFTER TIPO_FAC',
  'SELECT ''TIPO_RECTIFICATIVA_FAC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
