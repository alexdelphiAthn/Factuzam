-- Anyade campos a fza_albaranes_compra (idempotente):
--   ESPIVOTE_HORIZONTAL_ALBC : 'S' para que el Mto abra el albaran ya en
--                              modo 'Tallas en horizontal' por defecto.
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
