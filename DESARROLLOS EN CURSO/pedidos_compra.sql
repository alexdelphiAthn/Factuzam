-- ============================================================================
-- Pedidos de Compra — esquema base (hito 1)
--
-- Crea las tablas `fza_pedidos_compra` (cabecera) y
-- `fza_pedidos_compra_lineas` (lineas), espejo simplificado de
-- `fza_albaranes_compra` / `fza_albaranes_compra_lineas` adaptado a
-- documento PEDIDO de COMPRA. A diferencia del albaran, el pedido NO
-- mueve stock fisico al grabarse: deposita compromiso en
-- `fza_articulos_pdte_recibir` (tabla ya existente, ver
-- `compras_sesiones_pdte_recibir.sql`). Cuando el usuario pulsa
-- "Crear albaran" en el Mto, se genera un albaran de compra para el
-- almacen elegido y se trasvasa la cantidad recibida.
--
-- Sufijos de columna: `_PEDC` cabecera, `_PEDCLIN` lineas (registrados en
-- LIBRO_DE_ESTILO_BBDD para que el normalizador BBDD los reconozca).
--
-- Idempotente: comprueba INFORMATION_SCHEMA antes de cada DDL para que
-- el script pueda volver a ejecutarse sin error si las tablas / indices
-- / filas ya existen.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. fza_pedidos_compra: cabecera
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_pedidos_compra` ('
  '  `NUMERO_PEDC` varchar(20) NOT NULL,'
  '  `SERIE_PEDC`  varchar(20) NOT NULL,'
  '  `FECHA_PEDC`  date NULL DEFAULT NULL,'
  '  `FECHA_PREVISTA_PEDC` date NULL DEFAULT NULL'
  '       COMMENT ''Fecha estimada de recepcion'','
  '  `ESTADO_PEDC` varchar(20) NULL DEFAULT ''ABIERTO'''
  '       COMMENT ''ABIERTO, PARCIAL, RECIBIDO, CANCELADO'','
  '  `CODIGO_EMP_PEDC` varchar(8) NULL DEFAULT NULL,'
  '  `RAZON_SOCIAL_EMPRESA_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_EMPRESA_PEDC`       varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_EMPRESA_PEDC`     varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_EMPRESA_PEDC`     varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_EMPRESA_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_EMPRESA_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_EMPRESA_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_EMPRESA_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_EMPRESA_PEDC` varchar(3)  NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_EMPRESA_PEDC` varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_EMPRESA_PEDC` varchar(15) NULL DEFAULT NULL,'
  '  `CODIGO_PRV_PEDC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_proveedores'','
  '  `RAZON_SOCIAL_PRV_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_PRV_PEDC`          varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_PRV_PEDC`        varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_PRV_PEDC`        varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_PRV_PEDC`   varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_PRV_PEDC`   varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_PRV_PEDC`    varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_PRV_PEDC`    varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_PRV_PEDC`   varchar(3)   NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_PRV_PEDC`   varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_PRV_PEDC` varchar(15) NULL DEFAULT NULL,'
  '  `REF_PROVEEDOR_PEDC` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''Numero de pedido segun el proveedor'','
  '  `CODIGO_ALM_PEDC` varchar(10) NULL DEFAULT NULL'
  '       COMMENT ''Almacen destino por defecto (cada linea puede tener el suyo)'','
  '  `TRANSPORTISTA_PEDC` varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_IVA_PEDC` varchar(20) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAN_PEDC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAN_PEDC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAR_PEDC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAR_PEDC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAS_PEDC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAS_PEDC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAE_PEDC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAE_PEDC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASES_PEDC`     decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IMPUESTOS_PEDC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_LIQUIDO_PEDC`   decimal(18,6) NULL DEFAULT NULL,'
  '  `FORMA_PAGO_PEDC`      varchar(200)  NULL DEFAULT NULL,'
  '  `CONTADOR_LINEAS_PEDC` varchar(8)    NULL DEFAULT NULL,'
  '  `COMENTARIOS_PEDC`     varchar(1000) NULL DEFAULT '''','
  '  `OBSERVACIONES_PEDC`   varchar(2000) NULL DEFAULT '''','
  '  `ESPIVOTE_HORIZONTAL_PEDC` varchar(1) NULL DEFAULT ''N'''
  '       COMMENT ''S/N — recordar vista pivote de tallas al reabrir'','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_PEDC`,`SERIE_PEDC`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Indices de cabecera
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra'
     AND INDEX_NAME   = 'IDX_PEDC_PROVEEDOR_FECHA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra` '
  'ADD INDEX `IDX_PEDC_PROVEEDOR_FECHA` '
  '(`CODIGO_PRV_PEDC`,`FECHA_PEDC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra'
     AND INDEX_NAME   = 'IDX_PEDC_EMPRESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra` '
  'ADD INDEX `IDX_PEDC_EMPRESA` (`CODIGO_EMP_PEDC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra'
     AND INDEX_NAME   = 'IDX_PEDC_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra` '
  'ADD INDEX `IDX_PEDC_ESTADO` (`ESTADO_PEDC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. fza_pedidos_compra_lineas: detalle
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_lineas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_pedidos_compra_lineas` ('
  '  `NUMERO_PEDC_PEDCLIN` varchar(20) NOT NULL,'
  '  `SERIE_PEDC_PEDCLIN`  varchar(20) NOT NULL,'
  '  `LINEA_PEDCLIN`       varchar(4)  NOT NULL,'
  '  `CODIGO_ART_PEDCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `CODIGO_UNIDAD_PEDCLIN` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''SKU del articulo'','
  '  `ID_AC_PIVOT_PEDCLIN` int(11)     NULL DEFAULT NULL'
  '       COMMENT ''Conjunto de atributos pivot (fza_atributos_conjuntos)'','
  '  `CODIGO_FAM_PEDCLIN`  varchar(20)  NULL DEFAULT NULL,'
  '  `NOMBRE_FAM_PEDCLIN`  varchar(200) NULL DEFAULT NULL,'
  '  `DESCRIPCION_ARTICULO_PEDCLIN` varchar(100) NULL DEFAULT NULL,'
  '  `TIPO_CANTIDAD_ARTICULO_PEDCLIN` varchar(20)'
  '       NULL DEFAULT ''Uds'','
  '  `CANTIDAD_PEDCLIN` decimal(19,6) NULL DEFAULT ''1.000000'''
  '       COMMENT ''Cantidad PEDIDA por el cliente'','
  '  `CANTIDAD_RECIBIDA_PEDCLIN` decimal(19,6) NULL DEFAULT ''0.000000'''
  '       COMMENT ''Suma de cantidades ya albaraneadas (acumulado)'','
  '  `TOTAL_UNIDADES_PEDCLIN` decimal(19,6) NULL DEFAULT 0'
  '       COMMENT ''SUM(CANTIDAD) celdas pedidas cuando hay pivote'','
  '  `TIPO_IVA_ARTICULO_PEDCLIN` varchar(2) NULL DEFAULT ''N'','
  '  `PORCENTAJE_IVA_PEDCLIN`    decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `TOTAL_PEDCLIN` decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `CODIGO_ALMACEN_PEDCLIN` varchar(10) NULL DEFAULT NULL'
  '       COMMENT ''Almacen destino de la linea — un pedido puede agrupar varios'','
  '  `REF_PRV_PEDCLIN` varchar(50)  NULL DEFAULT NULL,'
  '  `DESCRIPCION_VARIACION_PEDCLIN` varchar(200) NULL DEFAULT NULL,'
  '  `FECHA_ENTREGA_PEDCLIN` date  NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_PEDC_PEDCLIN`,`SERIE_PEDC_PEDCLIN`,'
  '               `LINEA_PEDCLIN`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_lineas'
     AND INDEX_NAME   = 'IDX_PEDCLIN_ARTICULO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra_lineas` '
  'ADD INDEX `IDX_PEDCLIN_ARTICULO` (`CODIGO_ART_PEDCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_lineas'
     AND INDEX_NAME   = 'IDX_PEDCLIN_ALMACEN'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra_lineas` '
  'ADD INDEX `IDX_PEDCLIN_ALMACEN` (`CODIGO_ALMACEN_PEDCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2ter. Columna COLOR_TEXTO_PEDCLIN: texto libre del color del articulo
-- del proveedor (espejo de COLOR_TEXTO_SESLIN). Imprescindible para que
-- en el grid de lineas se vea "AZUL TURQUESA PROV-XYZ" y no solo el
-- color basico ("AZUL").
-- ----------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_lineas'
     AND COLUMN_NAME  = 'COLOR_TEXTO_PEDCLIN'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_pedidos_compra_lineas` '
  'ADD COLUMN `COLOR_TEXTO_PEDCLIN` varchar(100) NULL DEFAULT NULL '
  '     COMMENT ''Texto libre del color del articulo del proveedor'' '
  'AFTER `NOMBRE_FAM_PEDCLIN`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill best-effort para pedidos ya materializados: rescata
-- COLOR_TEXTO_SESLIN desde la sesion origen via
-- fza_compras_sesiones_documentos. Solo escribe filas que ahora estan
-- NULL para no pisar tecleos manuales.
UPDATE fza_pedidos_compra_lineas P
  JOIN fza_compras_sesiones_documentos D
    ON D.TIPO_DOC_SESDOC = 'PEDC'
   AND D.SERIE_SESDOC    = P.SERIE_PEDC_PEDCLIN
   AND D.NUMERO_SESDOC   = P.NUMERO_PEDC_PEDCLIN
  JOIN fza_compras_sesiones_lineas S
    ON S.SERIE_SES_SESLIN  = D.SERIE_SES_SESDOC
   AND S.NUMERO_SES_SESLIN = D.NUMERO_SES_SESDOC
   AND ( S.CODIGO_ART_TENTATIVO_SESLIN = P.CODIGO_ART_PEDCLIN
      OR S.CODIGO_ART_REUSAR_SESLIN    = P.CODIGO_ART_PEDCLIN )
   SET P.COLOR_TEXTO_PEDCLIN = S.COLOR_TEXTO_SESLIN
 WHERE P.COLOR_TEXTO_PEDCLIN IS NULL
   AND S.COLOR_TEXTO_SESLIN IS NOT NULL
   AND S.COLOR_TEXTO_SESLIN <> '';

-- ----------------------------------------------------------------------------
-- 2bis. fza_pedidos_compra_celdas: cantidad por (linea, fila, talla)
-- Espejo de fza_albaranes_compra_celdas. Sufijo PEDCCEL. Soporta el modo
-- 'Tallas en horizontal' del Mto: una celda por SKU dentro de la matriz
-- pivote por talla x color.
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_celdas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_pedidos_compra_celdas` ('
  '  `SERIE_PEDC_PEDCCEL`  varchar(20)   NOT NULL,'
  '  `NUMERO_PEDC_PEDCCEL` varchar(20)   NOT NULL,'
  '  `LINEA_PEDC_PEDCCEL`  varchar(4)    NOT NULL,'
  '  `ID_FILA_PEDC_PEDCCEL` int(11)      NOT NULL DEFAULT 1,'
  '  `ID_AV_PIVOT_PEDCCEL` int(11)       NOT NULL'
  '       COMMENT ''ID del valor de atributo (talla) que pivota'','
  '  `CANTIDAD_PEDCCEL`    decimal(19,6) NOT NULL DEFAULT 0,'
  '  `CODIGO_ALM_PEDCCEL`  varchar(10)   NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`SERIE_PEDC_PEDCCEL`,`NUMERO_PEDC_PEDCCEL`,'
  '               `LINEA_PEDC_PEDCCEL`,`ID_FILA_PEDC_PEDCCEL`,'
  '               `ID_AV_PIVOT_PEDCCEL`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_pedidos_compra_celdas'
     AND INDEX_NAME   = 'IDX_PEDCCEL_LINEA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_pedidos_compra_celdas` '
  'ADD INDEX `IDX_PEDCCEL_LINEA` '
  '(`SERIE_PEDC_PEDCCEL`,`NUMERO_PEDC_PEDCCEL`,`LINEA_PEDC_PEDCCEL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. Alinear fza_tipos_documentos: el codigo 'PC' apunta a la tabla nueva.
--    Antes apuntaba a 'fza_pedidos_compras' (plural) que no existia.
-- ----------------------------------------------------------------------------
UPDATE `fza_tipos_documentos`
   SET `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` = 'fza_pedidos_compra'
 WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'PC'
   AND `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` <> 'fza_pedidos_compra';

-- Si no existe la entrada, la creamos para que el contador PRC_GET_CONTADOR_FACTURA
-- la conozca.
INSERT INTO `fza_tipos_documentos`
  (`CODIGO_TIPO_DOCUMENTO_TD`, `DESCRIPCION_TIPO_DOCUMENTO_TD`,
   `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`)
SELECT 'PC', 'PEDIDO DE COMPRAS', 'fza_pedidos_compra'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_documentos`
    WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'PC'
 );

-- ----------------------------------------------------------------------------
-- 3bis. Provisionar contador 'PC' en fza_contadores si no existe.
--    Mismo patron que los demas tipos de documento (SERIE_CON='-' y
--    DEFAULT_CON='S' para que PRC_FNC_GET_NEXT_NRO_DOC lo localice).
-- ----------------------------------------------------------------------------
INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
   `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT 'PC', '-', '-', 1, 6, 'S', 'S',
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'PC' AND `SERIE_CON` = '-'
 );

-- ----------------------------------------------------------------------------
-- 4. Registrar el nuevo Mto en fza_winforms (idempotente)
-- ----------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
SELECT 'PedidosCompra',
       'Pedidos de Compra',
       'Pedidos1',
       'inMtoPedidosCompra.TfrmMtoPedidosCompra',
       'Ctrl+Alt+P',
       'UniDataPedidosCompra.TdmPedidosCompra',
       5
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_winforms`
    WHERE `CALL_WINF` = 'PedidosCompra'
 );

-- ----------------------------------------------------------------------------
-- 5. Vista basica vi_pedidos_compra (lectura para tsLista)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_pedidos_compra` AS
SELECT  p.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_PEDC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_PEDC
  FROM  fza_pedidos_compra p
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = p.CODIGO_PRV_PEDC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = p.CODIGO_EMP_PEDC;
