-- ============================================================================
-- Devoluciones a Proveedor (devoluciones de compra) — esquema base
--
-- Crea las tablas `fza_devoluciones_compra` (cabecera),
-- `fza_devoluciones_compra_lineas` (lineas) y
-- `fza_devoluciones_compra_celdas` (tallas), espejo de
-- `fza_albaranes_compra` adaptado a un documento de DEVOLUCION al
-- proveedor: misma estructura (proveedor + precio de compra) pero al
-- cerrarlo el Mto genera movimientos de SALIDA (resta de stock) en vez de
-- entrada. Sufijos de columna: `_DEVC` cabecera, `_DEVCLIN` lineas,
-- `_DEVCCEL` celdas (registrados en LIBRO_DE_ESTILO_BBDD).
--
-- Idempotente: comprueba INFORMATION_SCHEMA antes de cada DDL para que
-- el script pueda volver a ejecutarse sin error si las tablas / indices
-- / filas ya existen.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. fza_devoluciones_compra: cabecera
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_devoluciones_compra` ('
  '  `NUMERO_DEVC` varchar(20) NOT NULL,'
  '  `SERIE_DEVC`  varchar(20) NOT NULL,'
  '  `FECHA_DEVC`  date NULL DEFAULT NULL,'
  '  `ESTADO_DEVC` varchar(20) NULL DEFAULT ''ABIERTO'''
  '       COMMENT ''ABIERTO, FACTURADO, CANCELADO'','
  '  `NUMERO_PED_DEVC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_pedidos_compra'','
  '  `SERIE_PED_DEVC`  varchar(20) NULL DEFAULT NULL,'
  '  `NUMERO_FAC_DEVC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_facturas_compras'','
  '  `SERIE_FAC_DEVC`  varchar(20) NULL DEFAULT NULL,'
  '  `CODIGO_EMP_DEVC` varchar(8) NULL DEFAULT NULL,'
  '  `RAZON_SOCIAL_EMPRESA_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_EMPRESA_DEVC`       varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_EMPRESA_DEVC`     varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_EMPRESA_DEVC`     varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_EMPRESA_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_EMPRESA_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_EMPRESA_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_EMPRESA_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_EMPRESA_DEVC` varchar(3)  NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_EMPRESA_DEVC` varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_EMPRESA_DEVC` varchar(15) NULL DEFAULT NULL,'
  '  `CODIGO_PRV_DEVC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_proveedores'','
  '  `RAZON_SOCIAL_PRV_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_PRV_DEVC`          varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_PRV_DEVC`        varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_PRV_DEVC`        varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_PRV_DEVC`   varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_PRV_DEVC`   varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_PRV_DEVC`    varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_PRV_DEVC`    varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_PRV_DEVC`   varchar(3)   NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_PRV_DEVC`   varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_PRV_DEVC` varchar(15) NULL DEFAULT NULL,'
  '  `REF_PROVEEDOR_DEVC` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''Numero de devolucion segun el proveedor'','
  '  `CODIGO_ALM_DEVC` varchar(10) NULL DEFAULT NULL'
  '       COMMENT ''Almacen destino de la entrada de mercancia'','
  '  `TRANSPORTISTA_DEVC` varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_IVA_DEVC` varchar(20) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAN_DEVC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAN_DEVC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAR_DEVC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAR_DEVC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAS_DEVC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAS_DEVC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAE_DEVC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAE_DEVC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASES_DEVC`     decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IMPUESTOS_DEVC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_LIQUIDO_DEVC`   decimal(18,6) NULL DEFAULT NULL,'
  '  `FORMA_PAGO_DEVC`      varchar(200)  NULL DEFAULT NULL,'
  '  `CONTADOR_LINEAS_DEVC` varchar(8)    NULL DEFAULT NULL,'
  '  `COMENTARIOS_DEVC`     varchar(1000) NULL DEFAULT '''','
  '  `OBSERVACIONES_DEVC`   varchar(2000) NULL DEFAULT '''','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_DEVC`,`SERIE_DEVC`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Indices de cabecera
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra'
     AND INDEX_NAME   = 'IDX_DEVC_PROVEEDOR_FECHA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra` '
  'ADD INDEX `IDX_DEVC_PROVEEDOR_FECHA` '
  '(`CODIGO_PRV_DEVC`,`FECHA_DEVC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra'
     AND INDEX_NAME   = 'IDX_DEVC_EMPRESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra` '
  'ADD INDEX `IDX_DEVC_EMPRESA` (`CODIGO_EMP_DEVC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra'
     AND INDEX_NAME   = 'IDX_DEVC_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra` '
  'ADD INDEX `IDX_DEVC_ESTADO` (`ESTADO_DEVC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra'
     AND INDEX_NAME   = 'IDX_DEVC_PEDIDO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra` '
  'ADD INDEX `IDX_DEVC_PEDIDO` '
  '(`SERIE_PED_DEVC`,`NUMERO_PED_DEVC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. fza_devoluciones_compra_lineas: detalle
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_lineas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_devoluciones_compra_lineas` ('
  '  `NUMERO_DEVC_DEVCLIN` varchar(20) NOT NULL,'
  '  `SERIE_DEVC_DEVCLIN`  varchar(20) NOT NULL,'
  '  `LINEA_DEVCLIN`       varchar(4)  NOT NULL,'
  '  `NUMERO_PEDC_DEVCLIN` varchar(20) NULL DEFAULT NULL,'
  '  `SERIE_PEDC_DEVCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `LINEA_PEDC_DEVCLIN`  varchar(4)  NULL DEFAULT NULL'
  '       COMMENT ''Linea de origen en fza_pedidos_compra_lineas'','
  '  `CODIGO_ART_DEVCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `CODIGO_UNIDAD_DEVCLIN` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''SKU del articulo'','
  '  `CODIGO_FAM_DEVCLIN`  varchar(20)  NULL DEFAULT NULL,'
  '  `NOMBRE_FAM_DEVCLIN`  varchar(200) NULL DEFAULT NULL,'
  '  `DESCRIPCION_ARTICULO_DEVCLIN` varchar(100) NULL DEFAULT NULL,'
  '  `TIPO_CANTIDAD_ARTICULO_DEVCLIN` varchar(20)'
  '       NULL DEFAULT ''Uds'','
  '  `CANTIDAD_DEVCLIN` decimal(19,6) NULL DEFAULT ''1.000000'','
  '  `TIPO_IVA_ARTICULO_DEVCLIN` varchar(2) NULL DEFAULT ''N'','
  '  `PORCENTAJE_IVA_DEVCLIN`    decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `TOTAL_DEVCLIN` decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `CODIGO_ALMACEN_DEVCLIN` varchar(10) NULL DEFAULT NULL,'
  '  `LOTE_DEVCLIN`           varchar(50) NULL DEFAULT NULL,'
  '  `FECHA_CADUCIDAD_DEVCLIN` date       NULL DEFAULT NULL,'
  '  `DESCRIPCION_VARIACION_DEVCLIN` varchar(200) NULL DEFAULT NULL,'
  '  `ESFACTURADA_DEVCLIN` varchar(1) NULL DEFAULT ''N'','
  '  `NUMERO_FAC_DEVCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `SERIE_FAC_DEVCLIN`   varchar(20) NULL DEFAULT NULL,'
  '  `LINEA_FAC_DEVCLIN`   varchar(4)  NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_DEVC_DEVCLIN`,`SERIE_DEVC_DEVCLIN`,'
  '               `LINEA_DEVCLIN`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_lineas'
     AND INDEX_NAME   = 'IDX_DEVCLIN_ARTICULO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra_lineas` '
  'ADD INDEX `IDX_DEVCLIN_ARTICULO` (`CODIGO_ART_DEVCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_lineas'
     AND INDEX_NAME   = 'IDX_DEVCLIN_PEDIDO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra_lineas` '
  'ADD INDEX `IDX_DEVCLIN_PEDIDO` '
  '(`SERIE_PEDC_DEVCLIN`,`NUMERO_PEDC_DEVCLIN`,`LINEA_PEDC_DEVCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2bis. Columnas para soporte de tallas pivotadas en linea
-- (igual que SESLIN: ID_AC_PIVOT identifica el conjunto de tallas
-- usado y TOTAL_UNIDADES es la suma de celdas de esa linea).
-- ----------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_lineas'
     AND COLUMN_NAME  = 'ID_AC_PIVOT_DEVCLIN'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra_lineas` '
  'ADD COLUMN `ID_AC_PIVOT_DEVCLIN` int(11) NULL DEFAULT NULL '
  '     COMMENT ''Conjunto de atributos pivot (fza_atributos_conjuntos)'' '
  'AFTER `CODIGO_UNIDAD_DEVCLIN`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_lineas'
     AND COLUMN_NAME  = 'TOTAL_UNIDADES_DEVCLIN'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra_lineas` '
  'ADD COLUMN `TOTAL_UNIDADES_DEVCLIN` decimal(19,6) NULL DEFAULT 0 '
  '     COMMENT ''SUM(CANTIDAD) de celdas cuando ID_AC_PIVOT esta '
  'fijado'' '
  'AFTER `CANTIDAD_DEVCLIN`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2ter. fza_devoluciones_compra_celdas: cantidad por (linea, fila, talla)
-- Espejo de fza_compras_sesiones_celdas. Sufijo DEVCCEL.
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_celdas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_devoluciones_compra_celdas` ('
  '  `SERIE_DEVC_DEVCCEL`  varchar(20)   NOT NULL,'
  '  `NUMERO_DEVC_DEVCCEL` varchar(20)   NOT NULL,'
  '  `LINEA_DEVC_DEVCCEL`  varchar(4)    NOT NULL,'
  '  `ID_FILA_DEVC_DEVCCEL` int(11)      NOT NULL DEFAULT 1,'
  '  `ID_AV_PIVOT_DEVCCEL` int(11)       NOT NULL'
  '       COMMENT ''ID del valor de atributo (talla) que pivota'','
  '  `CANTIDAD_DEVCCEL`    decimal(19,6) NOT NULL DEFAULT 0,'
  '  `CODIGO_ALM_DEVCCEL`  varchar(10)   NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`SERIE_DEVC_DEVCCEL`,`NUMERO_DEVC_DEVCCEL`,'
  '               `LINEA_DEVC_DEVCCEL`,`ID_FILA_DEVC_DEVCCEL`,'
  '               `ID_AV_PIVOT_DEVCCEL`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_devoluciones_compra_celdas'
     AND INDEX_NAME   = 'IDX_DEVCCEL_LINEA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_devoluciones_compra_celdas` '
  'ADD INDEX `IDX_DEVCCEL_LINEA` '
  '(`SERIE_DEVC_DEVCCEL`,`NUMERO_DEVC_DEVCCEL`,`LINEA_DEVC_DEVCCEL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. Registrar el tipo de documento 'DC' (DEVOLUCION A PROVEEDOR) idempotente.
-- El contador automatico (PRC_GET_CONTADOR_FACTURA) y la serie por defecto
-- usan este codigo. No existia ningun tipo que empiece por 'D', por eso lo
-- damos de alta nuevo en lugar de un UPDATE como en el albaran.
-- ----------------------------------------------------------------------------
INSERT INTO `fza_tipos_documentos`
  (`CODIGO_TIPO_DOCUMENTO_TD`, `DESCRIPCION_TIPO_DOCUMENTO_TD`,
   `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`)
SELECT 'DC', 'DEVOLUCION A PROVEEDOR', 'fza_devoluciones_compra'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_documentos`
    WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'DC'
 );

-- ----------------------------------------------------------------------------
-- 4. Registrar el nuevo Mto en fza_winforms (idempotente)
-- ----------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'DevolucionesCompra',
       'Devoluciones a Proveedor',
       'Devoluciones1',
       'inMtoDevolucionesCompra.TfrmMtoDevolucionesCompra',
       'Ctrl+Alt+D',
       'UniDataDevolucionesCompra.TdmDevolucionesCompra',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms`
    WHERE `CALL_WINF` = 'DevolucionesCompra'
 );

-- ----------------------------------------------------------------------------
-- 5. Vista basica vi_devoluciones_compra (lectura para tsLista)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_devoluciones_compra` AS
SELECT  a.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_DEVC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_DEVC
  FROM  fza_devoluciones_compra a
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = a.CODIGO_PRV_DEVC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = a.CODIGO_EMP_DEVC;

-- ----------------------------------------------------------------------------
-- 6. Columnas incrementales que usan el Mto y las vistas de impresion
--    (espejo de albc_pivote_tarifa.sql + ref_prv_albcli.sql):
--      ESPIVOTE_HORIZONTAL_DEVC : el Mto abre ya en modo "Tallas en
--                                 horizontal" cuando vale 'S'.
--      CODIGO_TAR_DEVC          : tarifa de venta sugerida al imprimir
--                                 pegatinas.
--      REF_PRV_DEVCLIN          : referencia del proveedor en la linea
--                                 (se ve en el grid y en el informe).
-- ----------------------------------------------------------------------------
SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_devoluciones_compra'
              AND COLUMN_NAME  = 'ESPIVOTE_HORIZONTAL_DEVC');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_devoluciones_compra`
     ADD COLUMN `ESPIVOTE_HORIZONTAL_DEVC` varchar(1) NOT NULL DEFAULT ''N''
     AFTER `OBSERVACIONES_DEVC`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_devoluciones_compra'
              AND COLUMN_NAME  = 'CODIGO_TAR_DEVC');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_devoluciones_compra`
     ADD COLUMN `CODIGO_TAR_DEVC` varchar(20) NULL DEFAULT NULL
     AFTER `ESPIVOTE_HORIZONTAL_DEVC`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_devoluciones_compra_lineas'
              AND COLUMN_NAME  = 'REF_PRV_DEVCLIN');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_devoluciones_compra_lineas`
     ADD COLUMN `REF_PRV_DEVCLIN` varchar(100) NULL DEFAULT NULL
     AFTER `CODIGO_UNIDAD_DEVCLIN`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- Re-crear la vista para que `a.*` exponga las columnas recien anyadidas
-- (MariaDB congela la lista de columnas al crear la vista).
CREATE OR REPLACE VIEW `vi_devoluciones_compra` AS
SELECT  a.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_DEVC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_DEVC
  FROM  fza_devoluciones_compra a
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = a.CODIGO_PRV_DEVC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = a.CODIGO_EMP_DEVC;
