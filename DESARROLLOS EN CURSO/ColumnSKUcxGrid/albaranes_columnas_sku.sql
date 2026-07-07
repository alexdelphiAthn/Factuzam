-- =============================================================================
-- Contrato ColumnSKUcxGrid en ALBARANES DE VENTA (mayor)
-- =============================================================================
-- 1. fza_albaranes_lineas ya guarda el SKU (CODIGO_UNIDAD_ALBLIN);
--    se anaden los atributos desglosados (columnas reales, como en
--    pedidos) + conjunto pivotado del modo tallas en horizontal.
--
-- 2. fza_albaranes_celdas: cantidades por celda de talla del modo
--    tallas. Clave estandar SERIE+NUMERO del gestor (sin clave extra).
--
-- Sufijos: _ALBLIN en lineas; tabla nueva con sufijo ALBCEL.
-- El Mto lee de la TABLA (no hay vista que regenerar, a diferencia
-- de vi_pedidos_lineas en pedidos).
-- Idempotente.
-- =============================================================================

-- 1. Columnas nuevas en las lineas ----------------------------------------

DROP PROCEDURE IF EXISTS prc_tmp_add_col_alblin;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_alblin(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_albaranes_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_albaranes_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_alblin('ATTR1_VALOR_ALBLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR1_NOMBRE_ALBLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR2_VALOR_ALBLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR2_NOMBRE_ALBLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR3_VALOR_ALBLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR3_NOMBRE_ALBLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR4_VALOR_ALBLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR4_NOMBRE_ALBLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR5_VALOR_ALBLIN',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('ATTR5_NOMBRE_ALBLIN', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_alblin('NUM_ATRIBUTOS_ALBLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');
CALL prc_tmp_add_col_alblin('ID_AC_PIVOT_ALBLIN',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Conjunto pivotado en tallas horizontal (0 = sin pivote)''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_alblin;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_lineas'
     AND INDEX_NAME   = 'IDX_ALBLIN_UNIDAD'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_albaranes_lineas
     ADD INDEX IDX_ALBLIN_UNIDAD (CODIGO_UNIDAD_ALBLIN)',
  'SELECT ''IDX_ALBLIN_UNIDAD ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Tabla de celdas -------------------------------------------------------

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_celdas'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_albaranes_celdas (
     SERIE_ALB_ALBCEL    varchar(20)   NOT NULL,
     NUMERO_ALB_ALBCEL   varchar(20)   NOT NULL,
     LINEA_ALBCEL        int(11)       NOT NULL,
     ID_FILA_ALBCEL      int(11)       NOT NULL,
     ID_AV_PIVOT_ALBCEL  int(11)       NOT NULL
       COMMENT ''FK logica fza_atributos_valores del eje pivot (TALLA)'',
     CODIGO_ALM_ALBCEL   varchar(10)   NOT NULL DEFAULT '''',
     CANTIDAD_ALBCEL     decimal(19,6) NOT NULL,
     INSTANTE_ALTA       timestamp     NOT NULL DEFAULT ''0000-00-00 00:00:00'',
     USUARIO_ALTA        varchar(100)  NOT NULL DEFAULT '''',
     INSTANTE_MODIF      datetime      NULL DEFAULT NULL,
     USUARIO_MODIF       varchar(100)  NULL DEFAULT NULL,
     PRIMARY KEY (SERIE_ALB_ALBCEL, NUMERO_ALB_ALBCEL, LINEA_ALBCEL,
                  ID_FILA_ALBCEL, ID_AV_PIVOT_ALBCEL, CODIGO_ALM_ALBCEL)
   )',
  'SELECT ''fza_albaranes_celdas ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_celdas'
     AND INDEX_NAME   = 'IDX_ALBCEL_AV_PIVOT'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_albaranes_celdas
     ADD INDEX IDX_ALBCEL_AV_PIVOT (ID_AV_PIVOT_ALBCEL)',
  'SELECT ''IDX_ALBCEL_AV_PIVOT ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
