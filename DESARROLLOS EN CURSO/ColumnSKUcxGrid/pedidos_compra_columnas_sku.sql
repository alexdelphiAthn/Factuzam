-- =============================================================================
-- Contrato ColumnSKUcxGrid en PEDIDOS DE COMPRA
-- =============================================================================
-- 1. fza_pedidos_compra_lineas ya guarda SKU (CODIGO_UNIDAD_PEDCLIN)
--    e ID_AC_PIVOT_PEDCLIN; se anaden los atributos desglosados
--    (columnas reales, como en ventas) y CANTIDAD_A_RECIBIR_PEDCLIN,
--    la banda "A recibir" del pivote tallashorped (equivalente a
--    CANTIDAD_A_ALBARANAR_PEDLIN en pedidos de venta).
--
-- 2. SIN tabla de celdas: el modo "Tallas en horizontal" pasa a ser
--    inLibGridPivoteVenta (mcsTallasHorPed, pivot SOLO visual sobre
--    lineas SKU reales) con las bandas Pedido / A recibir / Pendiente.
--
-- Sufijo: _PEDCLIN. Idempotente.
-- =============================================================================

DROP PROCEDURE IF EXISTS prc_tmp_add_col_pedclin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_pedclin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_pedidos_compra_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_pedidos_compra_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_pedclin('ATTR1_VALOR_PEDCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR1_NOMBRE_PEDCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR2_VALOR_PEDCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR2_NOMBRE_PEDCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR3_VALOR_PEDCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR3_NOMBRE_PEDCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR4_VALOR_PEDCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR4_NOMBRE_PEDCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR5_VALOR_PEDCLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('ATTR5_NOMBRE_PEDCLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedclin('NUM_ATRIBUTOS_PEDCLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');
CALL prc_tmp_add_col_pedclin('CANTIDAD_A_RECIBIR_PEDCLIN',
  'decimal(19,6) NOT NULL DEFAULT 0 COMMENT ''Marcada para recibir en el proximo albaran (banda A recibir del pivote)''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_pedclin;
