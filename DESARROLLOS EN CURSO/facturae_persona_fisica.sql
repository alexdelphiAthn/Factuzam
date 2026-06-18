-- =============================================================================
-- Añade datos explicitos de persona fisica para Facturae
-- =============================================================================
-- Facturae separa nombre y apellidos cuando el receptor es persona física.
-- No se rellena desde RAZON_SOCIAL_CLIENTE_FAC porque no hay forma segura de
-- partir nombres compuestos como "JOSE CARLOS RODRIGUEZ LOPEZ".
-- =============================================================================
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'NOMBRE_PERSONA_CLIENTE_CLI'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_clientes
     ADD COLUMN NOMBRE_PERSONA_CLIENTE_CLI varchar(80) NULL DEFAULT NULL
     AFTER NOMBRE_PAI_CLI',
  'SELECT ''NOMBRE_PERSONA_CLIENTE_CLI ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'APELLIDOS_PERSONA_CLIENTE_CLI'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_clientes
     ADD COLUMN APELLIDOS_PERSONA_CLIENTE_CLI varchar(120) NULL DEFAULT NULL
     AFTER NOMBRE_PERSONA_CLIENTE_CLI',
  'SELECT ''APELLIDOS_PERSONA_CLIENTE_CLI ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'NOMBRE_PERSONA_CLIENTE_FAC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN NOMBRE_PERSONA_CLIENTE_FAC varchar(80) NULL DEFAULT NULL
     AFTER NOMBRE_PAI_CLIENTE_FAC',
  'SELECT ''NOMBRE_PERSONA_CLIENTE_FAC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'APELLIDOS_PERSONA_CLIENTE_FAC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN APELLIDOS_PERSONA_CLIENTE_FAC varchar(120) NULL DEFAULT NULL
     AFTER NOMBRE_PERSONA_CLIENTE_FAC',
  'SELECT ''APELLIDOS_PERSONA_CLIENTE_FAC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_facturas f
  JOIN fza_clientes c
    ON c.CODIGO_CLI_CLI = f.CODIGO_CLI_FAC
   SET f.NOMBRE_PERSONA_CLIENTE_FAC =
       COALESCE(NULLIF(f.NOMBRE_PERSONA_CLIENTE_FAC, ''),
                c.NOMBRE_PERSONA_CLIENTE_CLI),
       f.APELLIDOS_PERSONA_CLIENTE_FAC =
       COALESCE(NULLIF(f.APELLIDOS_PERSONA_CLIENTE_FAC, ''),
                c.APELLIDOS_PERSONA_CLIENTE_CLI)
 WHERE (f.NOMBRE_PERSONA_CLIENTE_FAC IS NULL
        OR f.NOMBRE_PERSONA_CLIENTE_FAC = ''
        OR f.APELLIDOS_PERSONA_CLIENTE_FAC IS NULL
        OR f.APELLIDOS_PERSONA_CLIENTE_FAC = '')
   AND (c.NOMBRE_PERSONA_CLIENTE_CLI IS NOT NULL
        OR c.APELLIDOS_PERSONA_CLIENTE_CLI IS NOT NULL);
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_clientes AS
SELECT c.*
  FROM fza_clientes c
 ORDER BY c.ORDEN_CLI;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_cli_busquedas AS
SELECT c.*
  FROM fza_clientes c
 WHERE c.ESACTIVO_CLI = 'S'
 ORDER BY c.CODIGO_CLI_CLI DESC;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas AS
SELECT f.*,
       fp.DESCRIPCION_FORMA_PAGO_FP AS DESCRIPCION_FORMA_PAGO_FP
  FROM fza_facturas f
  LEFT JOIN fza_formas_pago fp
    ON f.FORMA_PAGO_FAC = fp.CODIGO_FP_FP
 ORDER BY f.FECHA_FAC DESC;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas_normales AS
SELECT *
  FROM vi_facturas
 WHERE TIPO_FAC = 'NORMAL';
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas_simplificadas AS
SELECT *
  FROM vi_facturas
 WHERE TIPO_FAC = 'SIMPLIFICADA';
