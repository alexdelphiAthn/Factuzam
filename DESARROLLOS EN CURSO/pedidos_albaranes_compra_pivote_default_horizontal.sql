-- ============================================================================
-- pedidos_albaranes_compra_pivote_default_horizontal.sql
--
-- Script historico del cambio de preferencia de pivote. La regla actual
-- vuelve a dejar las altas nuevas en vertical: se podra activar "Tallas en
-- horizontal" cuando la linea en curso tenga sistema de tallas.
--
-- Semantica nueva del campo (la aplica el Mto en dsTablaGDataChangeHook):
--   'N'             -> vertical
--   'S'             -> horizontal si todas las lineas tienen sistema de tallas
--   NULL / ''       -> vertical en altas nuevas
--
-- La parte de esquema (cambiar el DEFAULT) es idempotente: no falla si ya
-- esta puesto a 'N'. No se cambia la preferencia de documentos existentes.
--
-- Dependencia de orden: aplicar DESPUES de los scripts que crean las
-- columnas (pedidos_compra.sql y albc_pivote_tarifa.sql).
--
-- Rollback: volver a poner el DEFAULT anterior con ALTER ... SET DEFAULT.
-- ============================================================================
-- 1) PEDIDOS DE COMPRA -------------------------------------------------------
-- 1a. Cambiar el DEFAULT a 'N' (solo si la columna existe).
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_pedidos_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_PEDC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_pedidos_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_PEDC` SET DEFAULT ''N''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- 1b. Normalizar valores vacios a vertical sin tocar preferencias explicitas.
SET @s := IF(@c = 1,
  'UPDATE `fza_pedidos_compra`
      SET `ESPIVOTE_HORIZONTAL_PEDC` = ''N''
    WHERE `ESPIVOTE_HORIZONTAL_PEDC` IS NULL
       OR TRIM(`ESPIVOTE_HORIZONTAL_PEDC`) = ''''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- 2) ALBARANES DE COMPRA -----------------------------------------------------
-- 2a. Cambiar el DEFAULT a 'N' (solo si la columna existe).
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_ALBC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_albaranes_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_ALBC` SET DEFAULT ''N''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- 2b. Normalizar valores vacios a vertical sin tocar preferencias explicitas.
SET @s := IF(@c = 1,
  'UPDATE `fza_albaranes_compra`
      SET `ESPIVOTE_HORIZONTAL_ALBC` = ''N''
    WHERE `ESPIVOTE_HORIZONTAL_ALBC` IS NULL
       OR TRIM(`ESPIVOTE_HORIZONTAL_ALBC`) = ''''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
