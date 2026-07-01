-- ============================================================================
-- Pais de proveedor como combo sobre fza_paises.
-- ============================================================================
-- Hasta ahora PAIS_PRV era texto libre. Se anade CODIGO_PAI_PRV (FK logica
-- a fza_paises.COD_ALPHA2_PAI, igual que CODIGO_PAI_CLI en fza_clientes) para
-- que el Mto de Proveedores pueda mostrar un combo en vez de texto libre.
-- PAIS_PRV se conserva como nombre denormalizado (impresos, ActualizarIva-
-- ExentoIntracomunitarioPorPais) y se refresca desde el combo.
--
-- Idempotente:
--   - la columna se crea solo si falta;
--   - el autorrelleno inicial (matching de PAIS_PRV contra fza_paises) solo
--     se ejecuta la primera vez que se crea la columna;
--   - las vistas se recrean para recoger los SELECT * congelados por MariaDB.
-- ============================================================================

SET @c_prv := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_proveedores'
     AND COLUMN_NAME = 'CODIGO_PAI_PRV'
);
SET @s := IF(@c_prv = 0,
  'ALTER TABLE `fza_proveedores`
     ADD COLUMN `CODIGO_PAI_PRV` varchar(3) NULL DEFAULT NULL
     COMMENT ''FK logica fza_paises.COD_ALPHA2_PAI (combo pais, ver vi_paises)''
     AFTER `PAIS_PRV`',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

-- Autorrelleno unico: emparejamos el texto libre PAIS_PRV que ya hubiera
-- contra fza_paises (codigo, alpha-2, alpha-3 o nombre ES/EN) y copiamos
-- el alpha-2 al nuevo campo. Mismo criterio que ya usa
-- ActualizarIvaExentoIntracomunitarioPorPais para no dejar huecos.
SET @s := IF(@c_prv = 0,
  'UPDATE fza_proveedores p
      JOIN fza_paises pai
        ON UPPER(TRIM(p.PAIS_PRV)) IN
           (UPPER(TRIM(pai.CODIGO_PAI_PAI)),
            UPPER(TRIM(pai.COD_ALPHA2_PAI)),
            UPPER(TRIM(pai.COD_ALPHA3_PAI)),
            UPPER(TRIM(pai.NOMBRE_SPA_PAI)),
            UPPER(TRIM(pai.NOMBRE_ENG_PAI)))
       SET p.CODIGO_PAI_PRV = pai.COD_ALPHA2_PAI
     WHERE NULLIF(TRIM(p.PAIS_PRV), '''') IS NOT NULL',
  'SELECT 1');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

CREATE OR REPLACE VIEW `vi_proveedores` AS
SELECT p.*
  FROM `fza_proveedores` p
 ORDER BY p.`ORDEN_PRV`;

CREATE OR REPLACE VIEW `vi_proveedores_busquedas` AS
SELECT p.*
  FROM `fza_proveedores` p
 WHERE p.`ESACTIVO_PRV` = 'S'
 ORDER BY p.`ORDEN_PRV`;
