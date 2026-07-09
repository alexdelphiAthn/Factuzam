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

-- 2. Tabla de celdas del modo "Tallas horizontal" INLINE ------------------
-- (mcsTallasInline, estilo albaranes/sesiones: lineas consolidadas por
-- articulo+color y cantidades por celda de talla). El modo de bandas
-- (tallashorped) NO la usa. Sufijo PEDCCEL. Idempotente.

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_celdas'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_pedidos_compra_celdas (
     SERIE_PEDC_PEDCCEL   varchar(20)   NOT NULL,
     NUMERO_PEDC_PEDCCEL  varchar(20)   NOT NULL,
     LINEA_PEDCCEL        int(11)       NOT NULL,
     ID_FILA_PEDCCEL      int(11)       NOT NULL,
     ID_AV_PIVOT_PEDCCEL  int(11)       NOT NULL
       COMMENT ''FK logica fza_atributos_valores del eje pivot (TALLA)'',
     CODIGO_ALM_PEDCCEL   varchar(10)   NOT NULL DEFAULT '''',
     CANTIDAD_PEDCCEL     decimal(19,6) NOT NULL,
     INSTANTE_ALTA        timestamp     NOT NULL DEFAULT ''0000-00-00 00:00:00'',
     USUARIO_ALTA         varchar(100)  NOT NULL DEFAULT '''',
     INSTANTE_MODIF       datetime      NULL DEFAULT NULL,
     USUARIO_MODIF        varchar(100)  NULL DEFAULT NULL,
     PRIMARY KEY (SERIE_PEDC_PEDCCEL, NUMERO_PEDC_PEDCCEL,
                  LINEA_PEDCCEL, ID_FILA_PEDCCEL, ID_AV_PIVOT_PEDCCEL,
                  CODIGO_ALM_PEDCCEL)
   )',
  'SELECT ''fza_pedidos_compra_celdas ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_celdas'
     AND INDEX_NAME   = 'IDX_PEDCCEL_AV_PIVOT'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_pedidos_compra_celdas
     ADD INDEX IDX_PEDCCEL_AV_PIVOT (ID_AV_PIVOT_PEDCCEL)',
  'SELECT ''IDX_PEDCCEL_AV_PIVOT ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
