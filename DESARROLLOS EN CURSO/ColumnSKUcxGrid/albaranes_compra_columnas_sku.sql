-- =============================================================================
-- Contrato ColumnSKUcxGrid en ALBARANES DE COMPRA
-- =============================================================================
-- 1. fza_albaranes_compra_lineas ya guarda SKU (CODIGO_UNIDAD_ALBCLIN)
--    e ID_AC_PIVOT_ALBCLIN; se anaden los atributos desglosados
--    (columnas reales, como en ventas y pedidos de compra).
--
-- 2. SIN tabla de celdas nueva: el modo "Tallas en horizontal" pasa a
--    ser inLibGridPivoteVenta (mcsTallasHorPed, pivot SOLO visual
--    sobre lineas SKU reales) con BANDA UNICA (Cantidad).
--
-- Sufijo: _ALBCLIN. Idempotente.
-- =============================================================================

DROP PROCEDURE IF EXISTS prc_tmp_add_col_albclin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_albclin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_albaranes_compra_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_albaranes_compra_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_albclin('ATTR1_VALOR_ALBCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR1_NOMBRE_ALBCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR2_VALOR_ALBCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR2_NOMBRE_ALBCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR3_VALOR_ALBCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR3_NOMBRE_ALBCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR4_VALOR_ALBCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR4_NOMBRE_ALBCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR5_VALOR_ALBCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('ATTR5_NOMBRE_ALBCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_albclin('NUM_ATRIBUTOS_ALBCLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_albclin;
