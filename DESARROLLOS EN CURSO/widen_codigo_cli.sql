-- =============================================================================
-- Ampliar columnas CODIGO_CLI_* de varchar(10) a varchar(20)
-- =============================================================================
-- El ERP origen (Herreras, occli.Cliente) guarda codigos de cliente en
-- varchar(15) — algunos llegan hasta 14-15 caracteres reales tras un
-- LTRIM. El destino actual los declara varchar(10), lo que provoca al
-- migrar:
--
--   EMySqlNetException #22001 'Data too long for column CODIGO_CLI_CLI'
--
-- La columna PK (`fza_clientes.CODIGO_CLI_CLI`) y todas las FK logicas
-- que la referencian (`fza_facturas.CODIGO_CLI_FAC`,
--  `fza_albaranes.CODIGO_CLI_ALB`, `fza_pedidos.CODIGO_CLI_PED`) pasan
-- a varchar(20), tamano estandar usado por el resto de codigos de la
-- BBDD (CODIGO_ALM_ALM, CODIGO_PRV_PRV, etc.).
--
-- Idempotente: cada ALTER se hace solo si la columna actual mide
-- menos de 20 caracteres.
-- =============================================================================

-- 1. fza_clientes.CODIGO_CLI_CLI (PK)
SET @sLen := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'CODIGO_CLI_CLI'
);
SET @sSql := IF(@sLen IS NOT NULL AND @sLen < 20,
  'ALTER TABLE fza_clientes
     MODIFY COLUMN CODIGO_CLI_CLI varchar(20) NOT NULL',
  'SELECT ''CODIGO_CLI_CLI ya tiene >= 20, se omite'' AS info');
PREPARE stmt FROM @sSql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. fza_facturas.CODIGO_CLI_FAC (FK logica)
SET @sLen := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'CODIGO_CLI_FAC'
);
SET @sSql := IF(@sLen IS NOT NULL AND @sLen < 20,
  'ALTER TABLE fza_facturas
     MODIFY COLUMN CODIGO_CLI_FAC varchar(20) NULL DEFAULT NULL',
  'SELECT ''CODIGO_CLI_FAC ya tiene >= 20, se omite'' AS info');
PREPARE stmt FROM @sSql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. fza_albaranes.CODIGO_CLI_ALB (FK logica)
SET @sLen := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes'
     AND COLUMN_NAME  = 'CODIGO_CLI_ALB'
);
SET @sSql := IF(@sLen IS NOT NULL AND @sLen < 20,
  'ALTER TABLE fza_albaranes
     MODIFY COLUMN CODIGO_CLI_ALB varchar(20) NULL DEFAULT NULL',
  'SELECT ''CODIGO_CLI_ALB ya tiene >= 20, se omite'' AS info');
PREPARE stmt FROM @sSql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4. fza_pedidos.CODIGO_CLI_PED (FK logica)
SET @sLen := (
  SELECT CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos'
     AND COLUMN_NAME  = 'CODIGO_CLI_PED'
);
SET @sSql := IF(@sLen IS NOT NULL AND @sLen < 20,
  'ALTER TABLE fza_pedidos
     MODIFY COLUMN CODIGO_CLI_PED varchar(20) NULL DEFAULT NULL',
  'SELECT ''CODIGO_CLI_PED ya tiene >= 20, se omite'' AS info');
PREPARE stmt FROM @sSql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
