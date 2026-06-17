-- =============================================================================
-- Añade datos explícitos de persona física para Facturae en facturas
-- =============================================================================
-- Facturae separa nombre y apellidos cuando el receptor es persona física.
-- No se rellena desde RAZON_SOCIAL_CLIENTE_FAC porque no hay forma segura de
-- partir nombres compuestos como "JOSE CARLOS RODRIGUEZ LOPEZ".
-- =============================================================================
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
     AFTER CODIGO_UNIDAD_TRAMITADORA_FAC',
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
