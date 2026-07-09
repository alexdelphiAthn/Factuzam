-- =============================================================================
-- Contrato ColumnSKUcxGrid en FACTURAS DE COMPRA
-- =============================================================================
-- 1. fza_facturas_compra_lineas ya guarda SKU (CODIGO_UNIDAD_FACCLIN)
--    e ID_AC_PIVOT_FACCLIN; se anaden los atributos desglosados
--    (columnas reales, como en ventas y pedidos de compra).
--
-- 2. SIN tabla de celdas nueva: el modo "Tallas en horizontal" pasa a
--    ser inLibGridPivoteVenta (mcsTallasHorPed, pivot SOLO visual
--    sobre lineas SKU reales) con BANDA UNICA (Cantidad).
--
-- Sufijo: _FACCLIN. Idempotente.
-- =============================================================================

DROP PROCEDURE IF EXISTS prc_tmp_add_col_facclin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_facclin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_facturas_compra_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_facturas_compra_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_facclin('ATTR1_VALOR_FACCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR1_NOMBRE_FACCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR2_VALOR_FACCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR2_NOMBRE_FACCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR3_VALOR_FACCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR3_NOMBRE_FACCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR4_VALOR_FACCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR4_NOMBRE_FACCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR5_VALOR_FACCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('ATTR5_NOMBRE_FACCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_facclin('NUM_ATRIBUTOS_FACCLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_facclin;
