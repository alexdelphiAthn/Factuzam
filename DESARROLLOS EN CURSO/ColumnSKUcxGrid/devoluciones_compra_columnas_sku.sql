-- =============================================================================
-- Contrato ColumnSKUcxGrid en DEVOLUCIONES DE COMPRA
-- =============================================================================
-- 1. fza_devoluciones_compra_lineas ya guarda SKU (CODIGO_UNIDAD_DEVCLIN)
--    e ID_AC_PIVOT_DEVCLIN; se anaden los atributos desglosados
--    (columnas reales, como en el resto de documentos de compra).
--
-- 2. SIN tabla de celdas nueva: el modo "Tallas en horizontal" pasa a
--    ser inLibGridPivoteVenta (mcsTallasHorPed, pivot SOLO visual
--    sobre lineas SKU reales) con BANDA UNICA (Cantidad).
--
-- Sufijo: _DEVCLIN. Idempotente.
-- =============================================================================

DROP PROCEDURE IF EXISTS prc_tmp_add_col_devclin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_devclin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_devoluciones_compra_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_devoluciones_compra_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_devclin('ATTR1_VALOR_DEVCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR1_NOMBRE_DEVCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR2_VALOR_DEVCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR2_NOMBRE_DEVCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR3_VALOR_DEVCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR3_NOMBRE_DEVCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR4_VALOR_DEVCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR4_NOMBRE_DEVCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR5_VALOR_DEVCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('ATTR5_NOMBRE_DEVCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_devclin('NUM_ATRIBUTOS_DEVCLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_devclin;
