-- =============================================================================
-- Ampliar fza_inventarios_lineas.LINEA_INVLIN a varchar(8)
-- =============================================================================
-- La columna esta declarada varchar(4) (rango '0001'..'9999') pero un
-- inventario inicial migrado desde un legacy grande puede tener decenas
-- de miles de lineas en el mismo (Empresa, Almacen). Al pasar la fila
-- 10000 el migrador genera "10000" (5 chars) y el INSERT revienta con:
--
--   EMySqlNetException #22001 'Data too long for column LINEA_INVLIN'
--
-- Ampliamos a varchar(8): cabe hasta 99 999 999 lineas por documento,
-- mas que suficiente y sigue siendo compacto.
--
-- Idempotente: el ALTER solo se ejecuta si la columna actual mide < 8.
-- =============================================================================

SET @sLen := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_inventarios_lineas'
     AND COLUMN_NAME  = 'LINEA_INVLIN'
);

SET @sSql := IF(@sLen IS NOT NULL AND @sLen < 8,
  'ALTER TABLE fza_inventarios_lineas
     MODIFY COLUMN LINEA_INVLIN varchar(8) NOT NULL
       COMMENT ''Secuencial de la línea (00000001, 00000002...)''',
  'SELECT ''LINEA_INVLIN ya tiene >= 8, se omite'' AS info');

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
