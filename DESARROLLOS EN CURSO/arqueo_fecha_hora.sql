-- =============================================================================
-- Arqueo de caja: conservar hora en el rango del cierre
-- =============================================================================
-- FECHA_DESDE_ARQ y FECHA_HASTA_ARQ nacieron como date porque el cierre se
-- trataba como un dia completo. El arqueo actual puede cerrarse por tramos
-- horarios, asi que el historico debe guardar el instante exacto.
--
-- Idempotente: solo modifica columnas si siguen siendo date. Si FECHA_HASTA_ARQ
-- venia de un cierre antiguo sin hora, se desplaza a 23:59:59 para mantener el
-- significado original de dia completo.
-- =============================================================================

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_caja_arqueos'
);

SET @sTipoDesde := (
  SELECT LOWER(DATA_TYPE)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_caja_arqueos'
     AND COLUMN_NAME  = 'FECHA_DESDE_ARQ'
);

SET @sSql := IF(@sExisteTabla > 0 AND @sTipoDesde = 'date',
  'ALTER TABLE fza_caja_arqueos
     MODIFY COLUMN FECHA_DESDE_ARQ datetime NOT NULL',
  'SELECT ''FECHA_DESDE_ARQ ya es datetime o no existe la tabla'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sTipoHasta := (
  SELECT LOWER(DATA_TYPE)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_caja_arqueos'
     AND COLUMN_NAME  = 'FECHA_HASTA_ARQ'
);

SET @sActualizarHasta := @sExisteTabla > 0 AND @sTipoHasta = 'date';

SET @sSql := IF(@sActualizarHasta,
  'ALTER TABLE fza_caja_arqueos
     MODIFY COLUMN FECHA_HASTA_ARQ datetime NOT NULL',
  'SELECT ''FECHA_HASTA_ARQ ya es datetime o no existe la tabla'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sSql := IF(@sActualizarHasta,
  'UPDATE fza_caja_arqueos
      SET FECHA_HASTA_ARQ = TIMESTAMP(DATE(FECHA_HASTA_ARQ), ''23:59:59'')
    WHERE FECHA_HASTA_ARQ = TIMESTAMP(DATE(FECHA_HASTA_ARQ), ''00:00:00'')',
  'SELECT ''No hay fechas antiguas que completar'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
