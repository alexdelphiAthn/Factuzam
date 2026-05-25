-- ==========================================================================
-- Script: quitar_esdefault_tar.sql
-- Fecha:  2026-05-25
-- Desc:   Elimina la columna ESDEFAULT_TAR de fza_tarifas.
--         La tarifa por defecto pasa a gestionarse via parametro de
--         aplicacion (appTarifaDefecto en inLibAppParam), no via flag
--         booleano en la tabla.
--         Idempotente: si la columna ya no existe, no hace nada.
-- ==========================================================================

-- 1. Eliminar la columna ESDEFAULT_TAR de fza_tarifas
SET @dbname = DATABASE();
SET @tablename = 'fza_tarifas';
SET @columnname = 'ESDEFAULT_TAR';

SET @col_exists = (SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @dbname
    AND TABLE_NAME   = @tablename
    AND COLUMN_NAME  = @columnname);

SET @ddl = IF(@col_exists > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP COLUMN `', @columnname, '`'),
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
