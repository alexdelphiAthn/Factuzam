-- ============================================================================
-- pedidos_albaranes_compra_pivote_default_horizontal.sql
--
-- Hace que los PEDIDOS y ALBARANES de compra se abran por defecto en
-- "Tallas en horizontal" (vista pivote). Antes el valor por defecto de
-- ESPIVOTE_HORIZONTAL_* era 'N' (vertical); ahora es 'S' (horizontal).
--
-- Semantica nueva del campo (la aplica el Mto en dsTablaGDataChangeHook):
--   'N'             -> vertical   (excepcion explicita que el usuario guardo)
--   'S' / NULL / '' -> horizontal (valor por defecto)
--
-- La parte de esquema (cambiar el DEFAULT) es idempotente: no falla si ya
-- esta puesto a 'S'. El backfill de filas existentes es de UNA SOLA
-- EJECUCION: convierte los documentos ya creados (que tienen 'N' por el
-- default antiguo) a horizontal. NO re-ejecutar despues de haber marcado
-- documentos como verticales a mano, o se perderian esas excepciones.
--
-- Dependencia de orden: aplicar DESPUES de los scripts que crean las
-- columnas (pedidos_compra.sql y albc_pivote_tarifa.sql).
--
-- Rollback: volver a poner el DEFAULT a 'N' con ALTER ... SET DEFAULT ''N''.
-- El backfill no es reversible al detalle (no se guarda el valor previo);
-- si hiciera falta, UPDATE ... SET = 'N' deja todo en vertical.
-- ============================================================================
-- 1) PEDIDOS DE COMPRA -------------------------------------------------------
-- 1a. Cambiar el DEFAULT a 'S' (solo si la columna existe).
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_pedidos_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_PEDC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_pedidos_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_PEDC` SET DEFAULT ''S''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- 1b. Backfill (una sola vez): documentos existentes a horizontal.
SET @s := IF(@c = 1,
  'UPDATE `fza_pedidos_compra`
      SET `ESPIVOTE_HORIZONTAL_PEDC` = ''S''
    WHERE `ESPIVOTE_HORIZONTAL_PEDC` = ''N''
       OR `ESPIVOTE_HORIZONTAL_PEDC` IS NULL',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- 2) ALBARANES DE COMPRA -----------------------------------------------------
-- 2a. Cambiar el DEFAULT a 'S' (solo si la columna existe).
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_ALBC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_albaranes_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_ALBC` SET DEFAULT ''S''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
-- 2b. Backfill (una sola vez): documentos existentes a horizontal.
SET @s := IF(@c = 1,
  'UPDATE `fza_albaranes_compra`
      SET `ESPIVOTE_HORIZONTAL_ALBC` = ''S''
    WHERE `ESPIVOTE_HORIZONTAL_ALBC` = ''N''
       OR `ESPIVOTE_HORIZONTAL_ALBC` IS NULL',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
