-- =============================================================================
-- Contrato ColumnSKUcxGrid en DOCUMENTOS DE TRABAJO (Ctrl+W)
-- =============================================================================
-- 1. Atributos DESGLOSADOS en las lineas (columnas reales, decision
--    07/07/2026): ATTR1..5_VALOR/NOMBRE + NUM_ATRIBUTOS + conjunto
--    pivotado. Denormaliza lo derivable del SKU a cambio de un
--    desempaquetado persistente (las lineas van por TUniQuery directo,
--    sin buffer cliente donde guardar campos in-memory).
--
-- 2. fza_documentos_trabajo_celdas: cantidades por celda de talla del
--    modo tallas en horizontal. El documento tiene clave SIMPLE
--    (ID_DTR): el gestor de tallas usa ID_DTR como "serie" y deja el
--    par NUMERO vacio (soporte de numero opcional del gestor).
--
-- Sufijos: _DTL en lineas; tabla nueva con sufijo DTRCEL. Auditoria
-- estandar (LIBRO_DE_ESTILO_BBDD.md §3.7). Idempotente.
-- =============================================================================

-- 1. Columnas nuevas en las lineas ----------------------------------------

DROP PROCEDURE IF EXISTS prc_tmp_add_col_dtl;

DELIMITER //
CREATE PROCEDURE prc_tmp_add_col_dtl(
  IN pCol VARCHAR(64), IN pDef VARCHAR(200))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'fza_documentos_trabajo_lineas'
                    AND COLUMN_NAME = pCol) THEN
    SET @s := CONCAT('ALTER TABLE fza_documentos_trabajo_lineas ',
                     'ADD COLUMN ', pCol, ' ', pDef);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

CALL prc_tmp_add_col_dtl('ATTR1_VALOR_DTL',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR1_NOMBRE_DTL', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR2_VALOR_DTL',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR2_NOMBRE_DTL', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR3_VALOR_DTL',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR3_NOMBRE_DTL', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR4_VALOR_DTL',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR4_NOMBRE_DTL', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR5_VALOR_DTL',  'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('ATTR5_NOMBRE_DTL', 'varchar(100) NOT NULL DEFAULT ''''');
CALL prc_tmp_add_col_dtl('NUM_ATRIBUTOS_DTL',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Atributos requeridos del articulo''');
CALL prc_tmp_add_col_dtl('ID_AC_PIVOT_DTL',
  'int(11) NOT NULL DEFAULT 0 COMMENT ''Conjunto pivotado en tallas horizontal (0 = sin pivote)''');

DROP PROCEDURE IF EXISTS prc_tmp_add_col_dtl;

-- 2. Tabla de celdas -------------------------------------------------------

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_documentos_trabajo_celdas'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_documentos_trabajo_celdas (
     ID_DTR_DTRCEL       bigint(20)    NOT NULL,
     LINEA_DTRCEL        int(11)       NOT NULL,
     ID_FILA_DTRCEL      int(11)       NOT NULL,
     ID_AV_PIVOT_DTRCEL  int(11)       NOT NULL
       COMMENT ''FK logica fza_atributos_valores del eje pivot (TALLA)'',
     CODIGO_ALM_DTRCEL   varchar(10)   NOT NULL DEFAULT '''',
     CANTIDAD_DTRCEL     decimal(19,6) NOT NULL,
     INSTANTE_ALTA       timestamp     NOT NULL DEFAULT ''0000-00-00 00:00:00'',
     USUARIO_ALTA        varchar(100)  NOT NULL DEFAULT '''',
     INSTANTE_MODIF      datetime      NULL DEFAULT NULL,
     USUARIO_MODIF       varchar(100)  NULL DEFAULT NULL,
     PRIMARY KEY (ID_DTR_DTRCEL, LINEA_DTRCEL, ID_FILA_DTRCEL,
                  ID_AV_PIVOT_DTRCEL, CODIGO_ALM_DTRCEL)
   )',
  'SELECT ''fza_documentos_trabajo_celdas ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_documentos_trabajo_celdas'
     AND INDEX_NAME   = 'IDX_DTRCEL_AV_PIVOT'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_documentos_trabajo_celdas
     ADD INDEX IDX_DTRCEL_AV_PIVOT (ID_AV_PIVOT_DTRCEL)',
  'SELECT ''IDX_DTRCEL_AV_PIVOT ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
