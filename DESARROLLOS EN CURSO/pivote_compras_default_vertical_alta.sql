-- ============================================================================
-- pivote_compras_default_vertical_alta.sql
--
-- Las altas nuevas de documentos de compra deben arrancar en vista vertical.
-- El usuario podra activar tallas en horizontal cuando la linea en curso ya
-- tenga un articulo con sistema de tallas. No se cambia la preferencia de los
-- documentos existentes.
-- ============================================================================
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_pedidos_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_PEDC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_pedidos_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_PEDC` SET DEFAULT ''N''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_albaranes_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_ALBC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_albaranes_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_ALBC` SET DEFAULT ''N''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_facturas_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_FACC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_facturas_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_FACC` SET DEFAULT ''N''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_devoluciones_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_DEVC');
SET @s := IF(@c = 1,
  'ALTER TABLE `fza_devoluciones_compra`
     ALTER COLUMN `ESPIVOTE_HORIZONTAL_DEVC` SET DEFAULT ''N''',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
