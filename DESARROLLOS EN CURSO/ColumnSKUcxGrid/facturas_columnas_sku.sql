-- =============================================================================
-- Contrato ColumnSKUcxGrid en FACTURAS DE VENTA (mayor y simplificadas)
-- =============================================================================
-- 1. fza_facturas_lineas ya guarda el SKU (CODIGO_UNIDAD_FACLIN, con
--    indice IDX_FACLIN_UNIDAD); se anaden los atributos desglosados
--    (columnas reales, como en pedidos/albaranes).
--
-- 2. SIN tabla de celdas y SIN ID_AC_PIVOT: el modo "Tallas en
--    horizontal" de facturas es inLibGridPivoteVenta (mcsTallasHorPed,
--    pivot SOLO visual sobre lineas SKU reales) con BandaUnica: las
--    lineas fiscales no se consolidan ni se transforman.
--
-- 3. vi_facturas_lineas listaba las columnas UNA a UNA y no conoce las
--    nuevas: se regenera con fl.* para que arrastre estas columnas y
--    cualquier futura (mismo criterio que vi_pedidos_lineas).
--    vi_facturas_lineas_print NO se toca (impresion).
--
-- Sufijo: _FACLIN. Idempotente.
-- =============================================================================

-- 1. Columnas nuevas en las lineas ----------------------------------------

DROP PROCEDURE IF EXISTS prc_tmp_add_col_faclin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_faclin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_facturas_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_facturas_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_faclin('ATTR1_VALOR_FACLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR1_NOMBRE_FACLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR2_VALOR_FACLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR2_NOMBRE_FACLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR3_VALOR_FACLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR3_NOMBRE_FACLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR4_VALOR_FACLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR4_NOMBRE_FACLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR5_VALOR_FACLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('ATTR5_NOMBRE_FACLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_faclin('NUM_ATRIBUTOS_FACLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_faclin;

-- 2. Vista de lineas -------------------------------------------------------
-- El Mto lee de vi_facturas_lineas; sin las ATTR en el dataset el modo
-- Auto degradaria a SKU y el desglose no podria pintar Color/Talla.
-- CREATE OR REPLACE es idempotente.

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas_lineas AS
SELECT fl.*
  FROM fza_facturas_lineas fl;
