-- =============================================================================
-- Anade parametros DIR3 Facturae a clientes y facturas
-- =============================================================================
-- FACe valida los tres centros administrativos del receptor publico:
-- oficina contable, organo gestor y unidad tramitadora.
--
-- Cliente: valores por defecto para nuevos eDoc.
-- Factura: foto usada en esa factura concreta.
--
-- Idempotente: se puede ejecutar varias veces. Cada columna se anade solo si
-- no existe y las vistas se recrean para exponer los campos nuevos.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'CODIGO_OFICINA_CONTABLE_CLI'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_clientes
     ADD COLUMN CODIGO_OFICINA_CONTABLE_CLI varchar(10) NULL DEFAULT NULL
     AFTER NOMBRE_PAI_CLI',
  'SELECT ''CODIGO_OFICINA_CONTABLE_CLI ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'CODIGO_ORGANO_GESTOR_CLI'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_clientes
     ADD COLUMN CODIGO_ORGANO_GESTOR_CLI varchar(10) NULL DEFAULT NULL
     AFTER CODIGO_OFICINA_CONTABLE_CLI',
  'SELECT ''CODIGO_ORGANO_GESTOR_CLI ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'CODIGO_UNIDAD_TRAMITADORA_CLI'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_clientes
     ADD COLUMN CODIGO_UNIDAD_TRAMITADORA_CLI varchar(10) NULL DEFAULT NULL
     AFTER CODIGO_ORGANO_GESTOR_CLI',
  'SELECT ''CODIGO_UNIDAD_TRAMITADORA_CLI ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'CODIGO_OFICINA_CONTABLE_FAC'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN CODIGO_OFICINA_CONTABLE_FAC varchar(10) NULL DEFAULT NULL
     AFTER NOMBRE_PAI_CLIENTE_FAC',
  'SELECT ''CODIGO_OFICINA_CONTABLE_FAC ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'CODIGO_ORGANO_GESTOR_FAC'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN CODIGO_ORGANO_GESTOR_FAC varchar(10) NULL DEFAULT NULL
     AFTER CODIGO_OFICINA_CONTABLE_FAC',
  'SELECT ''CODIGO_ORGANO_GESTOR_FAC ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'CODIGO_UNIDAD_TRAMITADORA_FAC'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN CODIGO_UNIDAD_TRAMITADORA_FAC varchar(10) NULL DEFAULT NULL
     AFTER CODIGO_ORGANO_GESTOR_FAC',
  'SELECT ''CODIGO_UNIDAD_TRAMITADORA_FAC ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE fza_facturas f
  JOIN fza_clientes c
    ON c.CODIGO_CLI_CLI = f.CODIGO_CLI_FAC
   SET f.CODIGO_OFICINA_CONTABLE_FAC =
       COALESCE(NULLIF(f.CODIGO_OFICINA_CONTABLE_FAC, ''),
                c.CODIGO_OFICINA_CONTABLE_CLI),
       f.CODIGO_ORGANO_GESTOR_FAC =
       COALESCE(NULLIF(f.CODIGO_ORGANO_GESTOR_FAC, ''),
                c.CODIGO_ORGANO_GESTOR_CLI),
       f.CODIGO_UNIDAD_TRAMITADORA_FAC =
       COALESCE(NULLIF(f.CODIGO_UNIDAD_TRAMITADORA_FAC, ''),
                c.CODIGO_UNIDAD_TRAMITADORA_CLI)
 WHERE (f.CODIGO_OFICINA_CONTABLE_FAC IS NULL
        OR f.CODIGO_OFICINA_CONTABLE_FAC = ''
        OR f.CODIGO_ORGANO_GESTOR_FAC IS NULL
        OR f.CODIGO_ORGANO_GESTOR_FAC = ''
        OR f.CODIGO_UNIDAD_TRAMITADORA_FAC IS NULL
        OR f.CODIGO_UNIDAD_TRAMITADORA_FAC = '')
   AND (c.CODIGO_OFICINA_CONTABLE_CLI IS NOT NULL
        OR c.CODIGO_ORGANO_GESTOR_CLI IS NOT NULL
        OR c.CODIGO_UNIDAD_TRAMITADORA_CLI IS NOT NULL);

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
