-- =============================================================================
-- Contrato ColumnSKUcxGrid en PEDIDOS DE VENTA (mayor)
-- =============================================================================
-- 1. fza_pedidos_lineas no guardaba el SKU (solo articulo y la
--    variacion como texto en la descripcion): se anade
--    CODIGO_UNIDAD_PEDLIN + atributos desglosados (columnas reales,
--    como en documentos de trabajo) + conjunto pivotado del modo
--    tallas en horizontal.
--
-- 2. fza_pedidos_celdas: cantidades por celda de talla del modo
--    tallas. Clave estandar SERIE+NUMERO del gestor (sin clave extra).
--
-- Sufijos: _PEDLIN en lineas; tabla nueva con sufijo PEDCEL.
-- Idempotente.
-- =============================================================================

-- 1. Columnas nuevas en las lineas ----------------------------------------

DROP PROCEDURE IF EXISTS prc_tmp_add_col_pedlin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_pedlin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_pedidos_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_pedidos_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_pedlin('CODIGO_UNIDAD_PEDLIN',
  'varchar(50) NOT NULL DEFAULT '''' COMMENT ''SKU concreto de la linea (ColumnSKUcxGrid)''');
CALL prc_tmp_add_col_pedlin('ATTR1_VALOR_PEDLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR1_NOMBRE_PEDLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR2_VALOR_PEDLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR2_NOMBRE_PEDLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR3_VALOR_PEDLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR3_NOMBRE_PEDLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR4_VALOR_PEDLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR4_NOMBRE_PEDLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR5_VALOR_PEDLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('ATTR5_NOMBRE_PEDLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_pedlin('NUM_ATRIBUTOS_PEDLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');
CALL prc_tmp_add_col_pedlin('ID_AC_PIVOT_PEDLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Conjunto pivotado en tallas horizontal (0 = sin pivote)''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_pedlin;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_lineas'
     AND INDEX_NAME   = 'IDX_PEDLIN_UNIDAD'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_pedidos_lineas
     ADD INDEX IDX_PEDLIN_UNIDAD (CODIGO_UNIDAD_PEDLIN)',
  'SELECT ''IDX_PEDLIN_UNIDAD ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Tabla de celdas -------------------------------------------------------

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_celdas'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_pedidos_celdas (
     SERIE_PED_PEDCEL    varchar(12)   NOT NULL,
     NUMERO_PED_PEDCEL   varchar(12)   NOT NULL,
     LINEA_PEDCEL        int(11)       NOT NULL,
     ID_FILA_PEDCEL      int(11)       NOT NULL,
     ID_AV_PIVOT_PEDCEL  int(11)       NOT NULL
       COMMENT ''FK logica fza_atributos_valores del eje pivot (TALLA)'',
     CODIGO_ALM_PEDCEL   varchar(10)   NOT NULL DEFAULT '''',
     CANTIDAD_PEDCEL     decimal(19,6) NOT NULL,
     INSTANTE_ALTA       timestamp     NOT NULL DEFAULT ''0000-00-00 00:00:00'',
     USUARIO_ALTA        varchar(100)  NOT NULL DEFAULT '''',
     INSTANTE_MODIF      datetime      NULL DEFAULT NULL,
     USUARIO_MODIF       varchar(100)  NULL DEFAULT NULL,
     PRIMARY KEY (SERIE_PED_PEDCEL, NUMERO_PED_PEDCEL, LINEA_PEDCEL,
                  ID_FILA_PEDCEL, ID_AV_PIVOT_PEDCEL, CODIGO_ALM_PEDCEL)
   )',
  'SELECT ''fza_pedidos_celdas ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_celdas'
     AND INDEX_NAME   = 'IDX_PEDCEL_AV_PIVOT'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_pedidos_celdas
     ADD INDEX IDX_PEDCEL_AV_PIVOT (ID_AV_PIVOT_PEDCEL)',
  'SELECT ''IDX_PEDCEL_AV_PIVOT ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. Vista de lineas -------------------------------------------------------
-- El Mto lee de vi_pedidos_lineas, que listaba las columnas UNA a UNA
-- y no conocia las nuevas (sin ATTR1_VALOR_PEDLIN en el dataset, el
-- modo Auto degradaba a SKU y el contrato no podia escribir el SKU).
-- Se regenera con pl.* para que arrastre estas columnas y cualquier
-- futura. CREATE OR REPLACE es idempotente.

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_pedidos_lineas AS
SELECT pl.*,
       pl.CANTIDAD_PEDLIN - IFNULL(pl.CANTIDAD_ENTREGADA_PEDLIN, 0)
         AS CANTIDAD_PENDIENTE_CALC_PEDLIN
  FROM fza_pedidos_lineas pl;
