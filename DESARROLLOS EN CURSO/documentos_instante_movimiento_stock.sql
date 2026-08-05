-- Instante efectivo de stock para albaranes y devoluciones activas.
-- FECHA_* conserva la fecha documental; INSTANTE_MOVIMIENTO_* ordena stock.
SET @existe := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_albaranes'
     AND COLUMN_NAME = 'INSTANTE_MOVIMIENTO_ALB'
);
SET @sql := IF(
  @existe = 0,
  'ALTER TABLE fza_albaranes ADD COLUMN INSTANTE_MOVIMIENTO_ALB datetime NULL COMMENT ''Instante efectivo del movimiento de stock'' AFTER FECHA_ALB',
  'SELECT 1'
);
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
SET @existe := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_albaranes_compra'
     AND COLUMN_NAME = 'INSTANTE_MOVIMIENTO_ALBC'
);
SET @sql := IF(
  @existe = 0,
  'ALTER TABLE fza_albaranes_compra ADD COLUMN INSTANTE_MOVIMIENTO_ALBC datetime NULL COMMENT ''Instante efectivo del movimiento de stock'' AFTER FECHA_ALBC',
  'SELECT 1'
);
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
SET @existe := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_devoluciones_compra'
     AND COLUMN_NAME = 'INSTANTE_MOVIMIENTO_DEVC'
);
SET @sql := IF(
  @existe = 0,
  'ALTER TABLE fza_devoluciones_compra ADD COLUMN INSTANTE_MOVIMIENTO_DEVC datetime NULL COMMENT ''Instante efectivo del movimiento de stock'' AFTER FECHA_DEVC',
  'SELECT 1'
);
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
-- No se inventa una hora histórica: los documentos existentes conservan
-- el comportamiento anterior, situado al inicio de su fecha documental.
UPDATE fza_albaranes
   SET INSTANTE_MOVIMIENTO_ALB = CAST(FECHA_ALB AS datetime)
 WHERE INSTANTE_MOVIMIENTO_ALB IS NULL
   AND FECHA_ALB IS NOT NULL;
UPDATE fza_albaranes_compra
   SET INSTANTE_MOVIMIENTO_ALBC = CAST(FECHA_ALBC AS datetime)
 WHERE INSTANTE_MOVIMIENTO_ALBC IS NULL
   AND FECHA_ALBC IS NOT NULL;
UPDATE fza_devoluciones_compra
   SET INSTANTE_MOVIMIENTO_DEVC = CAST(FECHA_DEVC AS datetime)
 WHERE INSTANTE_MOVIMIENTO_DEVC IS NULL
   AND FECHA_DEVC IS NOT NULL;
