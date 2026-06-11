-- ============================================================================
-- Anyade ESDEPOSITO_ALBC a fza_albaranes_compra (idempotente):
--   'S' = el albaran de compra es mercancia en DEPOSITO (a nivel
--   informativo: no cambia stock, facturacion ni estados). Por defecto
--   'N'. Se marca con un check en la cabecera del Mto y se muestra como
--   columna en el listado.
-- ============================================================================

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes_compra'
              AND COLUMN_NAME  = 'ESDEPOSITO_ALBC');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_albaranes_compra`
     ADD COLUMN `ESDEPOSITO_ALBC` varchar(1) NOT NULL DEFAULT ''N''
     COMMENT ''S = albaran de compra en deposito (informativo)''
     AFTER `CODIGO_TAR_ALBC`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- ----------------------------------------------------------------------------
-- Recrear la vista para que EXPONGA la columna recien anyadida.
-- vi_albaranes_compra se define con `a.*`, pero MariaDB CONGELA la lista de
-- columnas al crear la vista: si la vista ya existia antes de este ADD
-- COLUMN, NO incluye ESDEPOSITO_ALBC y el Mto no la ve (FindField=nil ->
-- el check de deposito no funcionaria). Re-ejecutar el CREATE OR REPLACE
-- recoge las columnas actuales de la tabla. Idempotente.
CREATE OR REPLACE VIEW `vi_albaranes_compra` AS
SELECT  a.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_ALBC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_ALBC
  FROM  fza_albaranes_compra a
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = a.CODIGO_PRV_ALBC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = a.CODIGO_EMP_ALBC;
