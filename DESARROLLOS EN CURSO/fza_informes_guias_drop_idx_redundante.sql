-- =====================================================================
-- Script: fza_informes_guias_drop_idx_redundante.sql
-- Objetivo: borrar el indice secundario IDX_INFGUI_INFORME sobre
--           fza_informes_guias porque es PREFIJO de la clave primaria
--           (INFORME_INFGUI, FORMATO_INFGUI, CODIGO_INFGUI) — InnoDB ya
--           sirve cualquier busqueda por INFORME / (INFORME, FORMATO) a
--           traves del PK sin coste adicional. Mantenerlo doblaba el
--           espacio del indice y el coste de cada INSERT / UPDATE de la
--           tabla sin ganancia de lectura.
--
-- Contexto: en el optimizado de 24/05/2026 se introdujo el cache en
--           memoria de fza_informes_guias (inLibInformesGuiasCache.pas),
--           con una unica lectura completa al login. Ya no se ejecutan
--           SELECTs filtrados por INFORME en cada print, asi que el
--           valor del indice secundario es cero.
--
-- Idempotente: solo borra el indice si existe.
-- =====================================================================

SET @schema := DATABASE();
SET @tabla  := 'fza_informes_guias';
SET @indice := 'IDX_INFGUI_INFORME';

SET @existe := (
  SELECT COUNT(*)
    FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = @schema
     AND TABLE_NAME   = @tabla
     AND INDEX_NAME   = @indice
);

SET @sql := IF(@existe > 0,
  CONCAT('ALTER TABLE `', @tabla, '` DROP INDEX `', @indice, '`'),
  'SELECT ''IDX_INFGUI_INFORME ya no existe, nada que hacer'' AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
