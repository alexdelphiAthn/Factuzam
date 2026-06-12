-- =============================================================================
-- Rectificativas Verifactu: ensanchar el enlace factura original-abono
-- =============================================================================
-- Las columnas NUMERO_FAC_ABONO_FAC / SERIE_FAC_ABONO_FAC de fza_facturas
-- son varchar(8) y las series/numeros reales son varchar(20). El
-- documento ANTECESOR guarda en ellas a su sucesor: la factura original
-- rectificada apunta a su rectificativa (y pasa a FASE_FAC='RECTIFICADA')
-- y el ticket sustituido apunta a la factura completa F3. El envio
-- Verifactu resuelve la relacion con el lookup inverso (IDX_FAC_ABONO).
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
       COMMENT ''Numero de la rectificativa o factura que sustituye a esta''',
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
       COMMENT ''Serie de la rectificativa o factura que sustituye a esta''',
  'SELECT ''SERIE_FAC_ABONO_FAC ya tiene ancho 20, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Lookup inverso del envio Verifactu: dada una rectificativa o una F3,
-- localizar a su antecesora (la fila cuyas columnas ABONO la apuntan)
SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND INDEX_NAME   = 'IDX_FAC_ABONO'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_facturas
     ADD INDEX IDX_FAC_ABONO
       (SERIE_FAC_ABONO_FAC, NUMERO_FAC_ABONO_FAC)',
  'SELECT ''IDX_FAC_ABONO ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
