-- ============================================================================
-- Facturas de Compra (factura de proveedor) — esquema base (hito 1)
--
-- Crea las tablas `fza_facturas_compra` (cabecera) y
-- `fza_facturas_compra_lineas` (lineas), destino de la AGRUPACION de
-- albaranes de compra en una factura. Es el espejo de compra de
-- `fza_facturas` / `fza_facturas_lineas` (venta), reutilizando la forma
-- de linea de `fza_albaranes_compra_lineas` (proveedor + precio de
-- compra) y anyadiendo los campos de factura de proveedor del legacy
-- `ocfacpro` (documento externo, descuentos, retencion, domiciliacion).
--
-- Cierra el hueco que ya anticipaban `fza_albaranes_compra` y
-- `fza_devoluciones_compra`: ambas tienen `NUMERO_FAC_*` / `SERIE_FAC_*`
-- comentadas como "FK logica a fza_facturas_compras" (plural) hacia una
-- tabla que nunca se creo. Aqui se materializa en SINGULAR
-- (`fza_facturas_compra`), igual que el resto de documentos de compra
-- (`fza_pedidos_compra`, `fza_albaranes_compra`, `fza_devoluciones_compra`).
--
-- El codigo de tipo de documento 'FP' ("FACTURA DE COMPRAS") ya existe en
-- `fza_tipos_documentos`; este script lo realinea a la tabla singular y
-- provisiona su contador, igual que hizo `pedidos_compra.sql` con 'PC'.
--
-- Sufijos de columna: `_FACC` cabecera, `_FACCLIN` lineas (registrados en
-- LIBRO_DE_ESTILO_BBDD.md §2 y en UNormalizerEngine.pas / InitDefaults).
--
-- Idempotente: comprueba INFORMATION_SCHEMA antes de cada DDL para que el
-- script pueda volver a ejecutarse sin error si las tablas / indices /
-- filas ya existen. Las stored procedures usan DROP ... IF EXISTS, asi que
-- requieren un cliente que entienda DELIMITER (mysql CLI, HeidiSQL,
-- DBeaver), igual que el propio dump factuzam_original.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. fza_facturas_compra: cabecera
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_facturas_compra` ('
  '  `NUMERO_FACC` varchar(20) NOT NULL,'
  '  `SERIE_FACC`  varchar(20) NOT NULL,'
  '  `FECHA_FACC`  date NULL DEFAULT NULL'
  '       COMMENT ''Fecha de la factura del proveedor'','
  '  `FECHA_VALOR_FACC` date NULL DEFAULT NULL'
  '       COMMENT ''Fecha valor / contable (legacy FechaValor)'','
  '  `ESTADO_FACC` varchar(20) NULL DEFAULT ''ABIERTA'''
  '       COMMENT ''ABIERTA, CERRADA, CONTABILIZADA, PAGADA, CANCELADA'','
  '  `DOC_EXTERNO_FACC` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''Nro de factura segun el proveedor (legacy DocExterno)'','
  '  `CODIGO_EMP_FACC` varchar(8) NULL DEFAULT NULL,'
  '  `RAZON_SOCIAL_EMPRESA_FACC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_EMPRESA_FACC`        varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_EMPRESA_FACC`      varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_EMPRESA_FACC`      varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_EMPRESA_FACC` varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_EMPRESA_FACC` varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_EMPRESA_FACC`  varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_EMPRESA_FACC`  varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_EMPRESA_FACC` varchar(3)   NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_EMPRESA_FACC` varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_EMPRESA_FACC` varchar(15) NULL DEFAULT NULL,'
  '  `CODIGO_PRV_FACC` varchar(20) NULL DEFAULT NULL'
  '       COMMENT ''FK logica a fza_proveedores'','
  '  `RAZON_SOCIAL_PRV_FACC` varchar(200) NULL DEFAULT NULL,'
  '  `NIF_PRV_FACC`          varchar(50)  NULL DEFAULT NULL,'
  '  `MOVIL_PRV_FACC`        varchar(40)  NULL DEFAULT NULL,'
  '  `EMAIL_PRV_FACC`        varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION1_PRV_FACC`   varchar(200) NULL DEFAULT NULL,'
  '  `DIRECCION2_PRV_FACC`   varchar(200) NULL DEFAULT NULL,'
  '  `POBLACION_PRV_FACC`    varchar(200) NULL DEFAULT NULL,'
  '  `PROVINCIA_PRV_FACC`    varchar(200) NULL DEFAULT NULL,'
  '  `CODIGO_PAI_PRV_FACC`   varchar(3)   NULL DEFAULT ''724'','
  '  `NOMBRE_PAI_PRV_FACC`   varchar(150) NULL DEFAULT ''Espana'','
  '  `CODIGO_POSTAL_PRV_FACC` varchar(15) NULL DEFAULT NULL,'
  '  `CODIGO_ALM_FACC` varchar(10) NULL DEFAULT NULL,'
  '  `CODIGO_IVA_FACC` varchar(20) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAN_FACC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASEI_IVAN_FACC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAN_FACC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAR_FACC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASEI_IVAR_FACC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAR_FACC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAS_FACC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASEI_IVAS_FACC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAS_FACC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_IVAE_FACC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_BASEI_IVAE_FACC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IVAE_FACC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_DTO_COMERCIAL_FACC` decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_DTO_COMERCIAL_FACC`      decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_PRONTO_PAGO_FACC`   decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_PRONTO_PAGO_FACC`        decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_RAPPEL_FACC`        decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_RAPPEL_FACC`             decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_FINANCIACION_FACC`  decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_FINANCIACION_FACC`       decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_PORTES_FACC`             decimal(18,6) NULL DEFAULT NULL,'
  '  `PORCENTAJE_RETENCION_FACC`     decimal(19,6) NULL DEFAULT NULL,'
  '  `TOTAL_RETENCION_FACC`          decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_BRUTO_FACC`     decimal(18,6) NULL DEFAULT NULL'
  '       COMMENT ''Suma de lineas antes de descuentos'','
  '  `TOTAL_BASES_FACC`     decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_IMPUESTOS_FACC` decimal(18,6) NULL DEFAULT NULL,'
  '  `TOTAL_FACC`           decimal(18,6) NULL DEFAULT NULL'
  '       COMMENT ''Total factura = bases + impuestos'','
  '  `TOTAL_LIQUIDO_FACC`   decimal(18,6) NULL DEFAULT NULL'
  '       COMMENT ''A pagar al proveedor (con retencion / descuentos)'','
  '  `FORMA_PAGO_FACC`      varchar(200)  NULL DEFAULT NULL'
  '       COMMENT ''Codigo de forma de pago (fza_formas_pago)'','
  '  `ESAGRUPAR_ALBARANES_FACC` varchar(1) NULL DEFAULT ''S'''
  '       COMMENT ''S/N — agrupa varios albaranes en esta factura'','
  '  `ENTIDAD_FACC`         varchar(4)  NULL DEFAULT NULL,'
  '  `OFICINA_FACC`         varchar(4)  NULL DEFAULT NULL,'
  '  `DIGITO_CONTROL_FACC`  varchar(2)  NULL DEFAULT NULL,'
  '  `CUENTA_FACC`          varchar(10) NULL DEFAULT NULL,'
  '  `IBAN_FACC`            varchar(34) NULL DEFAULT NULL'
  '       COMMENT ''Cuenta del proveedor para domiciliar el pago'','
  '  `CONTADOR_LINEAS_FACC` varchar(8)    NULL DEFAULT NULL,'
  '  `COMENTARIOS_FACC`     varchar(1000) NULL DEFAULT '''','
  '  `OBSERVACIONES_FACC`   varchar(2000) NULL DEFAULT '''','
  '  `INSTANTE_CONTABILIZACION_FACC` datetime NULL DEFAULT NULL'
  '       COMMENT ''Control contable: cuando se contabilizo la factura'','
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_FACC`,`SERIE_FACC`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Indices de cabecera
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
     AND INDEX_NAME   = 'IDX_FACC_PROVEEDOR_FECHA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra` '
  'ADD INDEX `IDX_FACC_PROVEEDOR_FECHA` '
  '(`CODIGO_PRV_FACC`,`FECHA_FACC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
     AND INDEX_NAME   = 'IDX_FACC_EMPRESA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra` '
  'ADD INDEX `IDX_FACC_EMPRESA` (`CODIGO_EMP_FACC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
     AND INDEX_NAME   = 'IDX_FACC_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra` '
  'ADD INDEX `IDX_FACC_ESTADO` (`ESTADO_FACC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
     AND INDEX_NAME   = 'IDX_FACC_DOC_EXTERNO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra` '
  'ADD INDEX `IDX_FACC_DOC_EXTERNO` (`CODIGO_PRV_FACC`,`DOC_EXTERNO_FACC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. fza_facturas_compra_lineas: detalle (snapshot de las lineas de albaran)
-- ----------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra_lineas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_facturas_compra_lineas` ('
  '  `NUMERO_FACC_FACCLIN` varchar(20) NOT NULL,'
  '  `SERIE_FACC_FACCLIN`  varchar(20) NOT NULL,'
  '  `LINEA_FACCLIN`       varchar(4)  NOT NULL,'
  '  `NUMERO_ALBC_FACCLIN` varchar(20) NULL DEFAULT NULL,'
  '  `SERIE_ALBC_FACCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `LINEA_ALBC_FACCLIN`  varchar(4)  NULL DEFAULT NULL'
  '       COMMENT ''Linea de origen en fza_albaranes_compra_lineas'','
  '  `CODIGO_ART_FACCLIN`  varchar(20) NULL DEFAULT NULL,'
  '  `CODIGO_UNIDAD_FACCLIN` varchar(50) NULL DEFAULT NULL'
  '       COMMENT ''SKU del articulo'','
  '  `REF_PRV_FACCLIN`     varchar(100) NULL DEFAULT NULL,'
  '  `ID_AC_PIVOT_FACCLIN` int(11)      NULL DEFAULT NULL'
  '       COMMENT ''Conjunto de atributos pivot (fza_atributos_conjuntos)'','
  '  `CODIGO_FAM_FACCLIN`  varchar(20)  NULL DEFAULT NULL,'
  '  `NOMBRE_FAM_FACCLIN`  varchar(200) NULL DEFAULT NULL,'
  '  `DESCRIPCION_ARTICULO_FACCLIN` varchar(100) NULL DEFAULT NULL,'
  '  `TIPO_CANTIDAD_ARTICULO_FACCLIN` varchar(20) NULL DEFAULT ''Uds'','
  '  `CANTIDAD_FACCLIN` decimal(19,6) NULL DEFAULT ''1.000000'','
  '  `TOTAL_UNIDADES_FACCLIN` decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `TIPO_IVA_ARTICULO_FACCLIN` varchar(2) NULL DEFAULT ''N'','
  '  `PORCENTAJE_IVA_FACCLIN`    decimal(19,6) NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `PRECIO_COMPRA_CIVA_ARTICULO_FACCLIN` decimal(19,6)'
  '       NULL DEFAULT ''0.000000'','
  '  `TOTAL_FACCLIN` decimal(19,6) NULL DEFAULT ''0.000000'''
  '       COMMENT ''Base imponible de la linea (precio compra siva x cantidad)'','
  '  `CODIGO_ALMACEN_FACCLIN` varchar(10) NULL DEFAULT NULL,'
  '  `LOTE_FACCLIN`           varchar(50) NULL DEFAULT NULL,'
  '  `FECHA_CADUCIDAD_FACCLIN` date       NULL DEFAULT NULL,'
  '  `DESCRIPCION_VARIACION_FACCLIN` varchar(200) NULL DEFAULT NULL,'
  '  `INSTANTE_MODIF` timestamp NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`  timestamp NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`   varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`  varchar(100) NOT NULL,'
  '  PRIMARY KEY (`NUMERO_FACC_FACCLIN`,`SERIE_FACC_FACCLIN`,'
  '               `LINEA_FACCLIN`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra_lineas'
     AND INDEX_NAME   = 'IDX_FACCLIN_ARTICULO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra_lineas` '
  'ADD INDEX `IDX_FACCLIN_ARTICULO` (`CODIGO_ART_FACCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra_lineas'
     AND INDEX_NAME   = 'IDX_FACCLIN_ALBARAN'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra_lineas` '
  'ADD INDEX `IDX_FACCLIN_ALBARAN` '
  '(`SERIE_ALBC_FACCLIN`,`NUMERO_ALBC_FACCLIN`,`LINEA_ALBC_FACCLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 3. Realinear fza_tipos_documentos: el codigo 'FP' (FACTURA DE COMPRAS)
--    apunta a la tabla singular. El dump lo trae apuntando a
--    'fza_facturas_compras' (plural) que no existe; mismo arreglo que
--    pedidos_compra.sql hizo con 'PC'.
-- ----------------------------------------------------------------------------
UPDATE `fza_tipos_documentos`
   SET `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` = 'fza_facturas_compra'
 WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'FP'
   AND `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` <> 'fza_facturas_compra';

INSERT INTO `fza_tipos_documentos`
  (`CODIGO_TIPO_DOCUMENTO_TD`, `DESCRIPCION_TIPO_DOCUMENTO_TD`,
   `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`)
SELECT 'FP', 'FACTURA DE COMPRAS', 'fza_facturas_compra'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_tipos_documentos`
    WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'FP'
 );

-- ----------------------------------------------------------------------------
-- 3bis. Provisionar contador 'FP' en fza_contadores si no existe.
--    SERIE_CON='-' y DEFAULT_CON='S' para que PRC_FNC_GET_NEXT_NRO_DOC lo
--    localice (mismo patron que el resto de documentos).
-- ----------------------------------------------------------------------------
INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
   `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `INSTANTE_MODIF`, `USUARIO_MODIF`)
SELECT 'FP', '-', '-', 0, 6, 'S', 'S',
       NOW(), 'SISTEMA', NOW(), 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'FP' AND `SERIE_CON` = '-'
 );

-- ----------------------------------------------------------------------------
-- 4. Vista basica vi_facturas_compra (lectura para tsLista)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_facturas_compra` AS
SELECT  f.*,
        prv.NOMBRE_PRV         AS NOMBRE_PRV_VIEW_FACC,
        emp.RAZON_SOCIAL_EMP   AS RAZON_SOCIAL_EMPRESA_VIEW_FACC
  FROM  fza_facturas_compra f
  LEFT  JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = f.CODIGO_PRV_FACC
  LEFT  JOIN fza_empresas    emp
         ON emp.CODIGO_EMP_EMP = f.CODIGO_EMP_FACC;

-- ----------------------------------------------------------------------------
-- 5. PRC_FACC_RECALCULAR_TOTALES: recalcula bandas de IVA y totales de la
--    cabecera a partir de las lineas. Clasifica cada linea por su % de IVA:
--      <= 0   -> Exento (E)
--      < 6    -> Superreducido (S)
--      < 13   -> Reducido (R)
--      resto  -> Normal (N)
--    (mismo criterio que la migracion de compras). En compra no hay RE.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_FACC_RECALCULAR_TOTALES`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FACC_RECALCULAR_TOTALES`(
    IN p_SERIE  varchar(20),
    IN p_NUMERO varchar(20))
BEGIN
  DECLARE v_baseN, v_baseR, v_baseS, v_baseE decimal(18,6) DEFAULT 0;
  DECLARE v_cuoN, v_cuoR, v_cuoS             decimal(18,6) DEFAULT 0;
  DECLARE v_pN, v_pR, v_pS                   decimal(19,6) DEFAULT 0;
  DECLARE v_bases, v_impuestos, v_total      decimal(18,6) DEFAULT 0;
  DECLARE v_reten, v_liquido, v_pRet         decimal(18,6) DEFAULT 0;
  DECLARE v_dto, v_pp, v_rap, v_fin, v_por   decimal(18,6) DEFAULT 0;
  SELECT
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN >= 13
                      THEN TOTAL_FACCLIN END), 0),
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN >= 6
                       AND PORCENTAJE_IVA_FACCLIN < 13
                      THEN TOTAL_FACCLIN END), 0),
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN > 0
                       AND PORCENTAJE_IVA_FACCLIN < 6
                      THEN TOTAL_FACCLIN END), 0),
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN <= 0
                      THEN TOTAL_FACCLIN END), 0),
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN >= 13
                      THEN TOTAL_FACCLIN * PORCENTAJE_IVA_FACCLIN / 100
                 END), 0),
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN >= 6
                       AND PORCENTAJE_IVA_FACCLIN < 13
                      THEN TOTAL_FACCLIN * PORCENTAJE_IVA_FACCLIN / 100
                 END), 0),
    COALESCE(SUM(CASE WHEN PORCENTAJE_IVA_FACCLIN > 0
                       AND PORCENTAJE_IVA_FACCLIN < 6
                      THEN TOTAL_FACCLIN * PORCENTAJE_IVA_FACCLIN / 100
                 END), 0),
    COALESCE(MAX(CASE WHEN PORCENTAJE_IVA_FACCLIN >= 13
                      THEN PORCENTAJE_IVA_FACCLIN END), 0),
    COALESCE(MAX(CASE WHEN PORCENTAJE_IVA_FACCLIN >= 6
                       AND PORCENTAJE_IVA_FACCLIN < 13
                      THEN PORCENTAJE_IVA_FACCLIN END), 0),
    COALESCE(MAX(CASE WHEN PORCENTAJE_IVA_FACCLIN > 0
                       AND PORCENTAJE_IVA_FACCLIN < 6
                      THEN PORCENTAJE_IVA_FACCLIN END), 0)
    INTO v_baseN, v_baseR, v_baseS, v_baseE,
         v_cuoN, v_cuoR, v_cuoS, v_pN, v_pR, v_pS
    FROM fza_facturas_compra_lineas
   WHERE SERIE_FACC_FACCLIN  = p_SERIE
     AND NUMERO_FACC_FACCLIN = p_NUMERO;
  -- Descuentos/cargos ya tecleados en la cabecera (el Mto los fija).
  SELECT COALESCE(PORCENTAJE_RETENCION_FACC, 0),
         COALESCE(TOTAL_DTO_COMERCIAL_FACC, 0),
         COALESCE(TOTAL_PRONTO_PAGO_FACC, 0),
         COALESCE(TOTAL_RAPPEL_FACC, 0),
         COALESCE(TOTAL_FINANCIACION_FACC, 0),
         COALESCE(TOTAL_PORTES_FACC, 0)
    INTO v_pRet, v_dto, v_pp, v_rap, v_fin, v_por
    FROM fza_facturas_compra
   WHERE SERIE_FACC = p_SERIE AND NUMERO_FACC = p_NUMERO;
  SET v_bases     = v_baseN + v_baseR + v_baseS + v_baseE;
  SET v_impuestos = v_cuoN + v_cuoR + v_cuoS;
  SET v_total     = v_bases + v_impuestos;
  SET v_reten     = ROUND(v_bases * v_pRet / 100, 2);
  SET v_liquido   = v_total - v_reten - v_dto - v_pp - v_rap + v_fin + v_por;
  UPDATE fza_facturas_compra
     SET PORCENTAJE_IVAN_FACC  = v_pN,
         TOTAL_BASEI_IVAN_FACC = v_baseN,
         TOTAL_IVAN_FACC       = v_cuoN,
         PORCENTAJE_IVAR_FACC  = v_pR,
         TOTAL_BASEI_IVAR_FACC = v_baseR,
         TOTAL_IVAR_FACC       = v_cuoR,
         PORCENTAJE_IVAS_FACC  = v_pS,
         TOTAL_BASEI_IVAS_FACC = v_baseS,
         TOTAL_IVAS_FACC       = v_cuoS,
         PORCENTAJE_IVAE_FACC  = 0,
         TOTAL_BASEI_IVAE_FACC = v_baseE,
         TOTAL_IVAE_FACC       = 0,
         TOTAL_BRUTO_FACC      = v_bases,
         TOTAL_BASES_FACC      = v_bases,
         TOTAL_IMPUESTOS_FACC  = v_impuestos,
         TOTAL_FACC            = v_total,
         TOTAL_RETENCION_FACC  = v_reten,
         TOTAL_LIQUIDO_FACC    = v_liquido
   WHERE SERIE_FACC = p_SERIE AND NUMERO_FACC = p_NUMERO;
END ;;
DELIMITER ;

-- ----------------------------------------------------------------------------
-- 6. PRC_FACC_FACTURAR_ALBARAN: AGRUPA un albaran de compra en una factura
--    de compra. Llamando una vez por cada albaran seleccionado (con la
--    misma factura destino) se consigue la agrupacion de N albaranes en 1
--    factura. Si p_NUMERO_FAC viene vacio/NULL crea una factura nueva
--    (numerada con el contador 'FP'); si viene informada anyade a esa
--    factura validando que sea el mismo proveedor y empresa.
--
--    Efectos:
--      - copia las lineas del albaran a fza_facturas_compra_lineas
--        (continuando el contador de lineas, de 10 en 10),
--      - marca el albaran ESTADO_ALBC='FACTURADO' y rellena
--        NUMERO_FAC_ALBC / SERIE_FAC_ALBC (y a nivel de linea
--        ESFACTURADA_ALBCLIN='S' + NUMERO_FAC_ALBCLIN / SERIE_FAC_ALBCLIN),
--      - recalcula los totales de la factura.
--    p_RESULTADO: 1 ok, 0 nada que hacer (albaran inexistente / ya
--    facturado / cabecera destino incompatible), -1 error.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_FACC_FACTURAR_ALBARAN`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FACC_FACTURAR_ALBARAN`(
    IN  p_SERIE_ALB    varchar(20),
    IN  p_NUMERO_ALB   varchar(20),
    IN  p_SERIE_FAC    varchar(20),
    IN  p_NUMERO_FAC   varchar(20),
    IN  p_USUARIO      varchar(100),
    OUT p_SERIE_FAC_OUT  varchar(20),
    OUT p_NUMERO_FAC_OUT varchar(20),
    OUT p_RESULTADO    int)
BEGIN
  DECLARE v_existe       int DEFAULT 0;
  DECLARE v_prv_alb      varchar(20);
  DECLARE v_emp_alb      varchar(8);
  DECLARE v_prv_fac      varchar(20);
  DECLARE v_emp_fac      varchar(8);
  DECLARE v_cont         bigint DEFAULT 0;
  DECLARE v_nlineas      int DEFAULT 0;
  DECLARE v_nro          bigint DEFAULT 0;
  DECLARE v_serie        varchar(3);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  SET p_RESULTADO = 0;
  -- ¿El albaran existe y es facturable?
  SELECT COUNT(*), MAX(CODIGO_PRV_ALBC), MAX(CODIGO_EMP_ALBC)
    INTO v_existe, v_prv_alb, v_emp_alb
    FROM fza_albaranes_compra
   WHERE SERIE_ALBC  = p_SERIE_ALB
     AND NUMERO_ALBC = p_NUMERO_ALB
     AND COALESCE(ESTADO_ALBC, '') NOT IN ('FACTURADO', 'CANCELADO');
  IF v_existe > 0 THEN
    START TRANSACTION;
    IF p_NUMERO_FAC IS NULL OR p_NUMERO_FAC = '' THEN
      -- Crear factura nueva numerada con el contador 'FP'.
      CALL PRC_FNC_GET_NEXT_NRO_DOC('FP', v_nro);
      CALL PRC_FNC_GET_SERIE_TIPODOC('FP', v_serie);
      SET p_NUMERO_FAC_OUT = LPAD(v_nro, 6, '0');
      SET p_SERIE_FAC_OUT  = v_serie;
      INSERT INTO fza_facturas_compra
        (NUMERO_FACC, SERIE_FACC, FECHA_FACC, ESTADO_FACC,
         CODIGO_EMP_FACC, RAZON_SOCIAL_EMPRESA_FACC, NIF_EMPRESA_FACC,
         MOVIL_EMPRESA_FACC, EMAIL_EMPRESA_FACC, DIRECCION1_EMPRESA_FACC,
         DIRECCION2_EMPRESA_FACC, POBLACION_EMPRESA_FACC,
         PROVINCIA_EMPRESA_FACC, CODIGO_PAI_EMPRESA_FACC,
         NOMBRE_PAI_EMPRESA_FACC, CODIGO_POSTAL_EMPRESA_FACC,
         CODIGO_PRV_FACC, RAZON_SOCIAL_PRV_FACC, NIF_PRV_FACC,
         MOVIL_PRV_FACC, EMAIL_PRV_FACC, DIRECCION1_PRV_FACC,
         DIRECCION2_PRV_FACC, POBLACION_PRV_FACC, PROVINCIA_PRV_FACC,
         CODIGO_PAI_PRV_FACC, NOMBRE_PAI_PRV_FACC, CODIGO_POSTAL_PRV_FACC,
         CODIGO_ALM_FACC, CODIGO_IVA_FACC, FORMA_PAGO_FACC,
         ESAGRUPAR_ALBARANES_FACC, CONTADOR_LINEAS_FACC,
         INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
      SELECT p_NUMERO_FAC_OUT, p_SERIE_FAC_OUT, CURDATE(), 'ABIERTA',
         CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC,
         MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, DIRECCION1_EMPRESA_ALBC,
         DIRECCION2_EMPRESA_ALBC, POBLACION_EMPRESA_ALBC,
         PROVINCIA_EMPRESA_ALBC, CODIGO_PAI_EMPRESA_ALBC,
         NOMBRE_PAI_EMPRESA_ALBC, CODIGO_POSTAL_EMPRESA_ALBC,
         CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC,
         MOVIL_PRV_ALBC, EMAIL_PRV_ALBC, DIRECCION1_PRV_ALBC,
         DIRECCION2_PRV_ALBC, POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC,
         CODIGO_PAI_PRV_ALBC, NOMBRE_PAI_PRV_ALBC, CODIGO_POSTAL_PRV_ALBC,
         CODIGO_ALM_ALBC, CODIGO_IVA_ALBC, FORMA_PAGO_ALBC,
         'S', '0',
         NOW(), p_USUARIO, NOW(), p_USUARIO
        FROM fza_albaranes_compra
       WHERE SERIE_ALBC = p_SERIE_ALB AND NUMERO_ALBC = p_NUMERO_ALB;
      SET v_existe = 1;
    ELSE
      -- Anyadir a una factura existente: validar mismo proveedor+empresa.
      SELECT COUNT(*), MAX(CODIGO_PRV_FACC), MAX(CODIGO_EMP_FACC)
        INTO v_existe, v_prv_fac, v_emp_fac
        FROM fza_facturas_compra
       WHERE SERIE_FACC  = p_SERIE_FAC
         AND NUMERO_FACC = p_NUMERO_FAC;
      IF v_existe > 0
         AND COALESCE(v_prv_fac, '') = COALESCE(v_prv_alb, '')
         AND COALESCE(v_emp_fac, '') = COALESCE(v_emp_alb, '') THEN
        SET p_SERIE_FAC_OUT  = p_SERIE_FAC;
        SET p_NUMERO_FAC_OUT = p_NUMERO_FAC;
      ELSE
        SET v_existe = 0;
      END IF;
    END IF;
    IF v_existe > 0 THEN
      -- Contador de lineas actual de la factura destino.
      SELECT CAST(COALESCE(NULLIF(CONTADOR_LINEAS_FACC, ''), '0')
                  AS UNSIGNED)
        INTO v_cont
        FROM fza_facturas_compra
       WHERE SERIE_FACC = p_SERIE_FAC_OUT AND NUMERO_FACC = p_NUMERO_FAC_OUT;
      -- Copiar lineas del albaran (numerando de 10 en 10 desde v_cont).
      INSERT INTO fza_facturas_compra_lineas
        (NUMERO_FACC_FACCLIN, SERIE_FACC_FACCLIN, LINEA_FACCLIN,
         NUMERO_ALBC_FACCLIN, SERIE_ALBC_FACCLIN, LINEA_ALBC_FACCLIN,
         CODIGO_ART_FACCLIN, CODIGO_UNIDAD_FACCLIN, REF_PRV_FACCLIN,
         ID_AC_PIVOT_FACCLIN, CODIGO_FAM_FACCLIN, NOMBRE_FAM_FACCLIN,
         DESCRIPCION_ARTICULO_FACCLIN, TIPO_CANTIDAD_ARTICULO_FACCLIN,
         CANTIDAD_FACCLIN, TOTAL_UNIDADES_FACCLIN,
         TIPO_IVA_ARTICULO_FACCLIN, PORCENTAJE_IVA_FACCLIN,
         PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN,
         PRECIO_COMPRA_CIVA_ARTICULO_FACCLIN, TOTAL_FACCLIN,
         CODIGO_ALMACEN_FACCLIN, LOTE_FACCLIN, FECHA_CADUCIDAD_FACCLIN,
         DESCRIPCION_VARIACION_FACCLIN,
         INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
      SELECT p_NUMERO_FAC_OUT, p_SERIE_FAC_OUT,
         LPAD(v_cont + 10 * ROW_NUMBER() OVER (ORDER BY LINEA_ALBCLIN),
              4, '0'),
         NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN,
         CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN,
         ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN,
         DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN,
         CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN,
         TIPO_IVA_ARTICULO_ALBCLIN, PORCENTAJE_IVA_ALBCLIN,
         PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN,
         PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, TOTAL_ALBCLIN,
         CODIGO_ALMACEN_ALBCLIN, LOTE_ALBCLIN, FECHA_CADUCIDAD_ALBCLIN,
         DESCRIPCION_VARIACION_ALBCLIN,
         NOW(), p_USUARIO, NOW(), p_USUARIO
        FROM fza_albaranes_compra_lineas
       WHERE SERIE_ALBC_ALBCLIN = p_SERIE_ALB
         AND NUMERO_ALBC_ALBCLIN = p_NUMERO_ALB;
      SET v_nlineas = ROW_COUNT();
      -- Avanzar el contador de lineas de la cabecera.
      UPDATE fza_facturas_compra
         SET CONTADOR_LINEAS_FACC = CAST(v_cont + 10 * v_nlineas AS CHAR),
             USUARIO_MODIF        = p_USUARIO
       WHERE SERIE_FACC = p_SERIE_FAC_OUT
         AND NUMERO_FACC = p_NUMERO_FAC_OUT;
      -- Marcar las lineas del albaran como facturadas.
      UPDATE fza_albaranes_compra_lineas
         SET ESFACTURADA_ALBCLIN = 'S',
             NUMERO_FAC_ALBCLIN  = p_NUMERO_FAC_OUT,
             SERIE_FAC_ALBCLIN   = p_SERIE_FAC_OUT,
             USUARIO_MODIF       = p_USUARIO
       WHERE SERIE_ALBC_ALBCLIN = p_SERIE_ALB
         AND NUMERO_ALBC_ALBCLIN = p_NUMERO_ALB;
      -- Marcar la cabecera del albaran como facturada.
      UPDATE fza_albaranes_compra
         SET ESTADO_ALBC     = 'FACTURADO',
             NUMERO_FAC_ALBC = p_NUMERO_FAC_OUT,
             SERIE_FAC_ALBC  = p_SERIE_FAC_OUT,
             USUARIO_MODIF   = p_USUARIO
       WHERE SERIE_ALBC = p_SERIE_ALB AND NUMERO_ALBC = p_NUMERO_ALB;
      -- Recalcular bandas de IVA y totales de la factura.
      CALL PRC_FACC_RECALCULAR_TOTALES(p_SERIE_FAC_OUT, p_NUMERO_FAC_OUT);
      SET p_RESULTADO = 1;
    END IF;
    COMMIT;
  END IF;
END ;;
DELIMITER ;
