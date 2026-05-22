-- ============================================================================
-- Albaranes de Compra — esquema base
--
-- Crea las tablas `fza_albaranes_compra` (cabecera) y
-- `fza_albaranes_compra_lineas` (lineas), espejo simplificado de
-- `fza_albaranes` / `fza_albaranes_lineas` adaptado a documento de
-- COMPRA: sustituye CLIENTE por PROVEEDOR y PRECIO_VENTA por
-- PRECIO_COMPRA. Sufijos de columna: `_ALBC` cabecera, `_ALBCLIN` lineas
-- (registrados en LIBRO_DE_ESTILO_BBDD para que el normalizador BBDD
-- los reconozca).
--
-- Idempotente: comprueba INFORMATION_SCHEMA antes de cada DDL para que
-- el script pueda volver a ejecutarse sin error si las tablas / indices
-- / filas ya existen.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. fza_albaranes_compra: cabecera
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_albaranes_compra` ('
  '  `NUMERO_ALBC` varchar(20) NOT NULL,'
  '  `SERIE_ALBC`  varchar(20) NOT NULL,'
  '  `FECHA_ALBC`  date NULL DEFAULT NULL,'
  '  `ESTADO_ALBC` varchar(20) NULL DEFAULT ''ABIERTO'''
  '       COMMENT ''ABIERTO, FACTURADO, CANCELADO'','
  '  `NUMERO_PED_ALBC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_pedidos_compra'','
  '  `SERIE_PED_ALBC`  varchar(20) NULL DEFAULT NULL,'
  '  `NUMERO_FAC_ALBC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_facturas_compras'','
  '  `SERIE_FAC_ALBC`  varchar(20) NULL DEFAULT NULL,'
  '  `CODIGO_EMP_ALBC` varchar(8) NULL DEFAULT NULL,'
  '  `RAZON_SOCIAL_EMPRESA_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_EMPRESA_ALBC`       varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_EMPRESA_ALBC`     varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_EMPRESA_ALBC`     varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_EMPRESA_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_EMPRESA_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_EMPRESA_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_EMPRESA_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_EMPRESA_ALBC` varchar(3)  NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_EMPRESA_ALBC` varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_EMPRESA_ALBC` varchar(15) NULL DEFAULT NULL,'
  '  `CODIGO_PRV_ALBC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_proveedores'','
  '  `RAZON_SOCIAL_PRV_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_PRV_ALBC`          varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_PRV_ALBC`        varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_PRV_ALBC`        varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_PRV_ALBC`   varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_PRV_ALBC`   varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_PRV_ALBC`    varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_PRV_ALBC`    varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_PRV_ALBC`   varchar(3)   NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_PRV_ALBC`   varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_PRV_ALBC` varchar(15) NULL DEFAULT NULL,'
  '  `REF_PROVEEDOR_ALBC` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''Numero de albaran segun el proveedor'','
  '  `CODIGO_ALM_ALBC` varchar(10) NULL DEFAULT NULL'
  '       COMMENT ''Almacen destino de la entrada de mercancia'','
  '  `TRANSPORTISTA_ALBC` varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_IVA_ALBC` varchar(20) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAN_ALBC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAN_ALBC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAR_ALBC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAR_ALBC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAS_ALBC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAS_ALBC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAE_ALBC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAE_ALBC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASES_ALBC`     decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IMPUESTOS_ALBC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_LIQUIDO_ALBC`   decimal(18,6) NULL DEFAULT NULL,'
  '  `FORMA_PAGO_ALBC`      varchar(200)  NULL DEFAULT NULL,'
  '  `CONTADOR_LINEAS_ALBC` varchar(8)    NULL DEFAULT NULL,'
  '  `COMENTARIOS_ALBC`     varchar(1000) NULL DEFAULT '''','
  '  `OBSERVACIONES_ALBC`   varchar(2000) NULL DEFAULT '''','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_ALBC`,`SERIE_ALBC`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Indices de cabecera
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra'
     AND INDEX_NAME   = 'IDX_ALBC_PROVEEDOR_FECHA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra` '
  'ADD INDEX `IDX_ALBC_PROVEEDOR_FECHA` '
  '(`CODIGO_PRV_ALBC`,`FECHA_ALBC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra'
     AND INDEX_NAME   = 'IDX_ALBC_EMPRESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra` '
  'ADD INDEX `IDX_ALBC_EMPRESA` (`CODIGO_EMP_ALBC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra'
     AND INDEX_NAME   = 'IDX_ALBC_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra` '
  'ADD INDEX `IDX_ALBC_ESTADO` (`ESTADO_ALBC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra'
     AND INDEX_NAME   = 'IDX_ALBC_PEDIDO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra` '
  'ADD INDEX `IDX_ALBC_PEDIDO` '
  '(`SERIE_PED_ALBC`,`NUMERO_PED_ALBC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. fza_albaranes_compra_lineas: detalle
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra_lineas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_albaranes_compra_lineas` ('
  '  `NUMERO_ALBC_ALBCLIN` varchar(20) NOT NULL,'
  '  `SERIE_ALBC_ALBCLIN`  varchar(20) NOT NULL,'
  '  `LINEA_ALBCLIN`       varchar(4)  NOT NULL,'
  '  `NUMERO_PEDC_ALBCLIN` varchar(20) NULL DEFAULT NULL,'
  '  `SERIE_PEDC_ALBCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `LINEA_PEDC_ALBCLIN`  varchar(4)  NULL DEFAULT NULL'
  '       COMMENT ''Linea de origen en fza_pedidos_compra_lineas'','
  '  `CODIGO_ART_ALBCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `CODIGO_UNIDAD_ALBCLIN` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''SKU del articulo'','
  '  `CODIGO_FAM_ALBCLIN`  varchar(20)  NULL DEFAULT NULL,'
  '  `NOMBRE_FAM_ALBCLIN`  varchar(200) NULL DEFAULT NULL,'
  '  `DESCRIPCION_ARTICULO_ALBCLIN` varchar(100) NULL DEFAULT NULL,'
  '  `TIPO_CANTIDAD_ARTICULO_ALBCLIN` varchar(20)'
  '       NULL DEFAULT ''Uds'','
  '  `CANTIDAD_ALBCLIN` decimal(19,6) NULL DEFAULT ''1.000000'','
  '  `TIPO_IVA_ARTICULO_ALBCLIN` varchar(2) NULL DEFAULT ''N'','
  '  `PORCENTAJE_IVA_ALBCLIN`    decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `TOTAL_ALBCLIN` decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `CODIGO_ALMACEN_ALBCLIN` varchar(10) NULL DEFAULT NULL,'
  '  `LOTE_ALBCLIN`           varchar(50) NULL DEFAULT NULL,'
  '  `FECHA_CADUCIDAD_ALBCLIN` date       NULL DEFAULT NULL,'
  '  `DESCRIPCION_VARIACION_ALBCLIN` varchar(200) NULL DEFAULT NULL,'
  '  `ESFACTURADA_ALBCLIN` varchar(1) NULL DEFAULT ''N'','
  '  `NUMERO_FAC_ALBCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `SERIE_FAC_ALBCLIN`   varchar(20) NULL DEFAULT NULL,'
  '  `LINEA_FAC_ALBCLIN`   varchar(4)  NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_ALBC_ALBCLIN`,`SERIE_ALBC_ALBCLIN`,'
  '               `LINEA_ALBCLIN`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra_lineas'
     AND INDEX_NAME   = 'IDX_ALBCLIN_ARTICULO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra_lineas` '
  'ADD INDEX `IDX_ALBCLIN_ARTICULO` (`CODIGO_ART_ALBCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_albaranes_compra_lineas'
     AND INDEX_NAME   = 'IDX_ALBCLIN_PEDIDO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_albaranes_compra_lineas` '
  'ADD INDEX `IDX_ALBCLIN_PEDIDO` '
  '(`SERIE_PEDC_ALBCLIN`,`NUMERO_PEDC_ALBCLIN`,`LINEA_PEDC_ALBCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. Alinear fza_tipos_documentos con el nombre real de la tabla
-- Antes apuntaba a 'fza_albaranes_compras' (plural) — corregimos a la
-- forma que usamos realmente.
-- ----------------------------------------------------------------------------
UPDATE `fza_tipos_documentos`
   SET `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` = 'fza_albaranes_compra'
 WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'AB'
   AND `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` <> 'fza_albaranes_compra';

-- ----------------------------------------------------------------------------
-- 4. Registrar el nuevo Mto en fza_winforms (idempotente)
-- ----------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'AlbaranesCompra',
       'Albaranes de Compra',
       'Albaranes1',
       'inMtoAlbaranesCompra.TfrmMtoAlbaranesCompra',
       'Ctrl+Alt+C',
       'UniDataAlbaranesCompra.TdmAlbaranesCompra',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms`
    WHERE `CALL_WINF` = 'AlbaranesCompra'
 );

-- ----------------------------------------------------------------------------
-- 5. Vista basica vi_albaranes_compra (lectura para tsLista)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_albaranes_compra` AS
SELECT  a.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_ALBC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_ALBC
  FROM  fza_albaranes_compra a
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = a.CODIGO_PRV_ALBC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = a.CODIGO_EMP_ALBC;
