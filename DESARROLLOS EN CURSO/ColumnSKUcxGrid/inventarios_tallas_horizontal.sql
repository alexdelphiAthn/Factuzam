-- =============================================================================
-- Tallas en horizontal en INVENTARIOS: tabla de celdas + pivote en lineas
-- =============================================================================
-- Infraestructura del modo mcsTallasInline (ColumnSKUcxGrid) en el Mto de
-- inventarios:
--
--   1. fza_inventarios_celdas: cantidades CONTADAS por celda de talla,
--      modelo fza_compras_sesiones_celdas. La clave del documento de
--      inventario tiene 4 columnas (EMP + ALM + SERIE + NUMERO): las dos
--      primeras van como "clave de documento extra" del gestor
--      (TGridTallasConfig.CamposDocExtra*). El almacen de CELDA
--      (CODIGO_ALM_INVCEL) existe por uniformidad con el gestor pero un
--      inventario es de UN almacen: se persiste siempre ''.
--
--   2. fza_inventarios_lineas.ID_AC_PIVOT_INVLIN: conjunto de atributos
--      (FK logica a fza_atributos_conjuntos) que pivota la linea en modo
--      tallas horizontal; 0 = linea sin pivote.
--
-- Sufijo de tabla nueva: INVCEL (celdas de inventario), columnas con las
-- 4 de auditoria estandar (LIBRO_DE_ESTILO_BBDD.md §3.7).
--
-- Idempotente: comprueba INFORMATION_SCHEMA antes de crear.
-- =============================================================================

-- 1. Tabla de celdas -----------------------------------------------------

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_inventarios_celdas'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_inventarios_celdas (
     CODIGO_EMP_INVCEL   varchar(10)   NOT NULL,
     CODIGO_ALM_INV_INVCEL varchar(10) NOT NULL,
     SERIE_INV_INVCEL    varchar(20)   NOT NULL,
     NUMERO_INV_INVCEL   varchar(20)   NOT NULL,
     LINEA_INVCEL        int(11)       NOT NULL,
     ID_FILA_INVCEL      int(11)       NOT NULL,
     ID_AV_PIVOT_INVCEL  int(11)       NOT NULL
       COMMENT ''FK logica fza_atributos_valores del eje pivot (TALLA)'',
     CODIGO_ALM_INVCEL   varchar(10)   NOT NULL DEFAULT ''''
       COMMENT ''Almacen de celda (uniformidad gestor; en inventario va vacio)'',
     CANTIDAD_INVCEL     decimal(19,6) NOT NULL
       COMMENT ''Cantidad CONTADA en la celda'',
     INSTANTE_ALTA       timestamp     NOT NULL DEFAULT ''0000-00-00 00:00:00'',
     USUARIO_ALTA        varchar(100)  NOT NULL DEFAULT '''',
     INSTANTE_MODIF      datetime      NULL DEFAULT NULL,
     USUARIO_MODIF       varchar(100)  NULL DEFAULT NULL,
     PRIMARY KEY (CODIGO_EMP_INVCEL, CODIGO_ALM_INV_INVCEL,
                  SERIE_INV_INVCEL, NUMERO_INV_INVCEL, LINEA_INVCEL,
                  ID_FILA_INVCEL, ID_AV_PIVOT_INVCEL, CODIGO_ALM_INVCEL)
   )',
  'SELECT ''fza_inventarios_celdas ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_inventarios_celdas'
     AND INDEX_NAME   = 'IDX_INVCEL_AV_PIVOT'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_inventarios_celdas
     ADD INDEX IDX_INVCEL_AV_PIVOT (ID_AV_PIVOT_INVCEL)',
  'SELECT ''IDX_INVCEL_AV_PIVOT ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Campo de pivote en las lineas ----------------------------------------

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_inventarios_lineas'
     AND COLUMN_NAME  = 'ID_AC_PIVOT_INVLIN'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_inventarios_lineas
     ADD COLUMN ID_AC_PIVOT_INVLIN int(11) NOT NULL DEFAULT 0
       COMMENT ''Conjunto de atributos pivotado en tallas horizontal (0 = sin pivote)''
     AFTER CODIGO_UNIDAD_INVLIN',
  'SELECT ''ID_AC_PIVOT_INVLIN ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
