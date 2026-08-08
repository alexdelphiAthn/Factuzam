-- Añade la opción que decide qué descripción recibe un artículo nuevo
-- materializado desde una sesión de compra.
-- S: usa DESCRIPCION_FAM y conserva DESCRIPCION_SESLIN si la familia no
--    tiene descripción.
-- N: conserva siempre la descripción importada en DESCRIPCION_SESLIN.

SET @existe := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_compras_sesiones'
     AND COLUMN_NAME = 'ESCOPIAR_DESCRIPCION_FAM_SES'
);
SET @sql := IF(
  @existe = 0,
  'ALTER TABLE `fza_compras_sesiones`
     ADD COLUMN `ESCOPIAR_DESCRIPCION_FAM_SES` varchar(1) NOT NULL DEFAULT ''S''
     AFTER `ESFORMATO_DISTRIBUIDO_SES`',
  'SELECT 1'
);
PREPARE sentencia FROM @sql;
EXECUTE sentencia;
DEALLOCATE PREPARE sentencia;
