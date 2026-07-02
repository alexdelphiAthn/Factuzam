-- Anyade campos a fza_albaranes_compra (idempotente):
--   ESPIVOTE_HORIZONTAL_ALBC : recuerda si el documento abre en modo
--                              'Tallas en horizontal'. Las altas nacen en
--                              vertical ('N').
--   CODIGO_TAR_ALBC          : tarifa de venta sugerida al imprimir
--                              pegatinas (PVP calculado a partir de ella).
-- ============================================================================

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_ALBC');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_albaranes_compra`
     ADD COLUMN `ESPIVOTE_HORIZONTAL_ALBC` varchar(1) NOT NULL DEFAULT ''N''
     AFTER `OBSERVACIONES_ALBC`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes_compra'
              AND COLUMN_NAME  = 'CODIGO_TAR_ALBC');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_albaranes_compra`
     ADD COLUMN `CODIGO_TAR_ALBC` varchar(20) NULL DEFAULT NULL
     AFTER `ESPIVOTE_HORIZONTAL_ALBC`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- ----------------------------------------------------------------------------
-- Recrear la vista para que EXPONGA las columnas recien anyadidas.
-- vi_albaranes_compra se define con `a.*`, pero MariaDB CONGELA la lista de
-- columnas al crear la vista: si la vista ya existia antes de estos ADD
-- COLUMN, NO incluye ESPIVOTE_HORIZONTAL_ALBC ni CODIGO_TAR_ALBC, y el Mto no
-- las ve (FindField=nil -> la preferencia de pivote horizontal no persiste al
-- reabrir el albaran). Re-ejecutar el CREATE OR REPLACE recoge las columnas
-- actuales de la tabla. Idempotente.
CREATE OR REPLACE VIEW `vi_albaranes_compra` AS
SELECT  a.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_ALBC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_ALBC
  FROM  fza_albaranes_compra a
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = a.CODIGO_PRV_ALBC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = a.CODIGO_EMP_ALBC;
