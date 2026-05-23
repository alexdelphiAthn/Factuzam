-- Anyade INSTANTE_ALTA y USUARIO_ALTA a fza_compras_sesiones_celdas
-- (idempotente). La tabla quedo creada con solo INSTANTE_MODIF /
-- USUARIO_MODIF pero el libro de estilo §3.7 exige las 4 columnas de
-- auditoria en TODAS las tablas. Otras tablas de celdas
-- (fza_albaranes_compra_celdas) ya las tienen.

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_compras_sesiones_celdas'
              AND COLUMN_NAME  = 'INSTANTE_ALTA');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_compras_sesiones_celdas`
     ADD COLUMN `INSTANTE_ALTA` timestamp NOT NULL DEFAULT ''0000-00-00 00:00:00''
     AFTER `CANTIDAD_SESCEL`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_compras_sesiones_celdas'
              AND COLUMN_NAME  = 'USUARIO_ALTA');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_compras_sesiones_celdas`
     ADD COLUMN `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT ''''
     AFTER `INSTANTE_ALTA`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
