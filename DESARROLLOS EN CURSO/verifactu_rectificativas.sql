-- =============================================================================
-- Rectificativas Verifactu: ensanchar el enlace factura original-abono
-- =============================================================================
-- Las columnas NUMERO_FAC_ABONO_FAC / SERIE_FAC_ABONO_FAC de fza_facturas
-- son varchar(8) y las series/numeros reales son varchar(20). La
-- rectificativa guarda en ellas la factura ORIGINAL que rectifica (lo usa
-- el registro Verifactu R1/R5 para el bloque FacturasRectificadas), asi
-- que se igualan a varchar(20).
--
-- Idempotente: solo modifica si el ancho actual es menor que 20.
-- =============================================================================

SET @sAncho := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'NUMERO_FAC_ABONO_FAC'
);

SET @sSql := IF(@sAncho < 20,
  'ALTER TABLE fza_facturas
     MODIFY COLUMN NUMERO_FAC_ABONO_FAC varchar(20) NULL DEFAULT NULL
       COMMENT ''Numero de la factura original que rectifica este abono''',
  'SELECT ''NUMERO_FAC_ABONO_FAC ya tiene ancho 20, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sAncho := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'SERIE_FAC_ABONO_FAC'
);

SET @sSql := IF(@sAncho < 20,
  'ALTER TABLE fza_facturas
     MODIFY COLUMN SERIE_FAC_ABONO_FAC varchar(20) NULL DEFAULT NULL
       COMMENT ''Serie de la factura original que rectifica este abono''',
  'SELECT ''SERIE_FAC_ABONO_FAC ya tiene ancho 20, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
