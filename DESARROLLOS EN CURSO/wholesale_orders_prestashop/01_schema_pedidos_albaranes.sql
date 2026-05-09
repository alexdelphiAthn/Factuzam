-- ===================================================================
--  Pedidos de Venta Mayor + Albaranes + Integración PrestaShop
--  Sigue la convención de LIBRO_DE_ESTILO_BBDD.md
--  Sufijos:
--    fza_pedidos             -> PED
--    fza_pedidos_lineas      -> PEDLIN
--    fza_pedidos_mensajes    -> PEDMSG
--    fza_albaranes           -> ALB
--    fza_albaranes_lineas    -> ALBLIN
-- ===================================================================

-- -------------------------------------------------------------------
--  fza_pedidos
--  Cabecera del pedido. Mantenemos la mayoría de campos existentes y
--  añadimos columnas nuevas para gestionar el ciclo de entregas y la
--  integración con PrestaShop.
-- -------------------------------------------------------------------

ALTER TABLE `fza_pedidos`
  ADD COLUMN `ESCONSOLIDADO_PED` varchar(1) DEFAULT 'N'
      COMMENT 'S si el pedido ya no se puede modificar (todo entregado o cerrado)' AFTER `FECHA_PED`,
  ADD COLUMN `ESTADO_PED`        varchar(20) DEFAULT 'ABIERTO'
      COMMENT 'ABIERTO, PARCIAL, ENTREGADO, CANCELADO, IMPORTADO' AFTER `ESCONSOLIDADO_PED`,
  ADD COLUMN `FECHA_ENTREGA_PED` date NULL
      COMMENT 'Fecha prevista de entrega del pedido' AFTER `ESTADO_PED`,
  ADD COLUMN `OBSERVACIONES_PED` varchar(2000) DEFAULT '' AFTER `COMENTARIOS_PED`;

ALTER TABLE `fza_pedidos`
  ADD INDEX `IDX_PED_CLIENTE_FECHA` (`CODIGO_CLI_PED`, `FECHA_PED`),
  ADD INDEX `IDX_PED_EMPRESA`       (`CODIGO_EMP_PED`),
  ADD INDEX `IDX_PED_IDPS`          (`IDPS_PED`),
  ADD INDEX `IDX_PED_ESTADO`        (`ESTADO_PED`);


-- -------------------------------------------------------------------
--  fza_pedidos_lineas
--  Líneas con desglose de cantidad pedida / entregada / pendiente.
-- -------------------------------------------------------------------

ALTER TABLE `fza_pedidos_lineas`
  ADD COLUMN `CANTIDAD_ENTREGADA_PEDLIN` decimal(19,6) DEFAULT 0.000000
      COMMENT 'Total entregado acumulado de la línea' AFTER `CANTIDAD_PEDLIN`,
  ADD COLUMN `CANTIDAD_PENDIENTE_PEDLIN` decimal(19,6) DEFAULT 0.000000
      COMMENT 'Cantidad - entregada (campo calculado para reportes)' AFTER `CANTIDAD_ENTREGADA_PEDLIN`,
  ADD COLUMN `ESENTREGADA_PEDLIN` varchar(1) DEFAULT 'N'
      COMMENT 'S si pendiente=0' AFTER `CANTIDAD_PENDIENTE_PEDLIN`,
  ADD COLUMN `CODIGO_ALMACEN_PEDLIN` varchar(10) NULL AFTER `ESENTREGADA_PEDLIN`;

ALTER TABLE `fza_pedidos_lineas`
  ADD INDEX `IDX_PEDLIN_ARTICULO` (`CODIGO_ART_PEDLIN`),
  ADD INDEX `IDX_PEDLIN_PENDIENTE` (`ESENTREGADA_PEDLIN`);


-- -------------------------------------------------------------------
--  fza_albaranes
--  Albarán de entrega. Se construye a partir de las líneas del pedido
--  marcadas como "entregadas".
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS `fza_albaranes`;
CREATE TABLE `fza_albaranes` (
  `NUMERO_ALB`                              varchar(20) NOT NULL,
  `SERIE_ALB`                               varchar(20) NOT NULL,
  `FECHA_ALB`                               date NULL,
  `ESCONSOLIDADO_ALB`                       varchar(1) DEFAULT 'N',
  `ESTADO_ALB`                              varchar(20) DEFAULT 'ABIERTO'
       COMMENT 'ABIERTO, FACTURADO, CANCELADO',
  `NUMERO_PED_ALB`                          varchar(20) NULL
       COMMENT 'FK lógica a fza_pedidos.NUMERO_PED',
  `SERIE_PED_ALB`                           varchar(20) NULL
       COMMENT 'FK lógica a fza_pedidos.SERIE_PED',
  `NUMERO_FAC_ALB`                          varchar(20) NULL
       COMMENT 'FK lógica a fza_facturas.NUMERO_FAC (cuando se factura)',
  `SERIE_FAC_ALB`                           varchar(20) NULL
       COMMENT 'FK lógica a fza_facturas.SERIE_FAC',
  `CODIGO_EMP_ALB`                          varchar(8)  NULL,
  `RAZON_SOCIAL_EMPRESA_ALB`                varchar(200) NULL,
  `NIF_EMPRESA_ALB`                         varchar(50) NULL,
  `MOVIL_EMPRESA_ALB`                       varchar(40) NULL,
  `EMAIL_EMPRESA_ALB`                       varchar(200) NULL,
  `DIRECCION1_EMPRESA_ALB`                  varchar(200) NULL,
  `DIRECCION2_EMPRESA_ALB`                  varchar(200) NULL,
  `POBLACION_EMPRESA_ALB`                   varchar(200) NULL,
  `PROVINCIA_EMPRESA_ALB`                   varchar(200) NULL,
  `CODIGO_PAI_EMPRESA_ALB`                  varchar(3)  DEFAULT '724',
  `NOMBRE_PAI_EMPRESA_ALB`                  varchar(150) DEFAULT 'España',
  `CODIGO_POSTAL_EMPRESA_ALB`               varchar(15) NULL,
  `GRUPO_ZONA_IVA_EMPRESA_ALB`              varchar(10) NULL,
  `CODIGO_CLI_ALB`                          varchar(10) NULL,
  `RAZON_SOCIAL_CLIENTE_ALB`                varchar(200) NULL,
  `NIF_CLIENTE_ALB`                         varchar(50) NULL,
  `MOVIL_CLIENTE_ALB`                       varchar(40) NULL,
  `EMAIL_CLIENTE_ALB`                       varchar(200) NULL,
  `DIRECCION1_CLIENTE_ALB`                  varchar(200) NULL,
  `DIRECCION2_CLIENTE_ALB`                  varchar(200) NULL,
  `POBLACION_CLIENTE_ALB`                   varchar(200) NULL,
  `PROVINCIA_CLIENTE_ALB`                   varchar(200) NULL,
  `CODIGO_POSTAL_CLIENTE_ALB`               varchar(15) NULL,
  `CODIGO_PAI_CLIENTE_ALB`                  varchar(3) DEFAULT '724',
  `NOMBRE_PAI_CLIENTE_ALB`                  varchar(150) DEFAULT 'España',
  `NOMBRE_CLI_ENVIO_ALB`                    varchar(200) NULL
       COMMENT 'Datos de envío (si difieren del cliente fiscal)',
  `MOVIL_CLIENTE_ENVIO_ALB`                 varchar(40)  NULL,
  `DIRECCION1_CLIENTE_ENVIO_ALB`            varchar(200) NULL,
  `DIRECCION2_CLIENTE_ENVIO_ALB`            varchar(200) NULL,
  `POBLACION_CLIENTE_ENVIO_ALB`             varchar(200) NULL,
  `PROVINCIA_CLIENTE_ENVIO_ALB`             varchar(200) NULL,
  `CODIGO_POSTAL_CLIENTE_ENVIO_ALB`         varchar(15)  NULL,
  `CODIGO_PAI_CLIENTE_ENVIO_ALB`            varchar(3)   DEFAULT '724',
  `NOMBRE_PAI_CLIENTE_ENVIO_ALB`            varchar(150) DEFAULT 'España',
  `TRANSPORTISTA_ALB`                       varchar(200) NULL,
  `CODIGO_IVA_ALB`                          varchar(20) NULL,
  `ESIVA_RECARGO_CLIENTE_ALB`               varchar(1) DEFAULT 'N',
  `ESIVA_EXENTO_CLIENTE_ALB`                varchar(1) DEFAULT 'N',
  `ESINTRACOMUNITARIO_CLIENTE_ALB`          varchar(1) DEFAULT 'N',
  `TARIFA_ARTICULO_CLIENTE_ALB`             varchar(10) NULL,
  `ESIMP_INCL_TARIFA_CLIENTE_ALB`           varchar(1) DEFAULT 'S',
  `PORCENTAJE_IVAN_ALB`                     decimal(19,6) NULL,
  `TOTAL_IVAN_ALB`                          decimal(18,6) NULL,
  `PORCENTAJE_IVAR_ALB`                     decimal(19,6) NULL,
  `TOTAL_IVAR_ALB`                          decimal(18,6) NULL,
  `PORCENTAJE_IVAS_ALB`                     decimal(19,6) NULL,
  `TOTAL_IVAS_ALB`                          decimal(18,6) NULL,
  `PORCENTAJE_IVAE_ALB`                     decimal(19,6) NULL,
  `TOTAL_IVAE_ALB`                          decimal(18,6) NULL,
  `TOTAL_BASES_ALB`                         decimal(18,6) NULL,
  `TOTAL_IMPUESTOS_ALB`                     decimal(18,6) NULL,
  `TOTAL_LIQUIDO_ALB`                       decimal(18,6) NULL,
  `FORMA_PAGO_ALB`                          varchar(200) NULL,
  `CONTADOR_LINEAS_ALB`                     varchar(8) NULL,
  `COMENTARIOS_ALB`                         varchar(1000) DEFAULT '',
  `OBSERVACIONES_ALB`                       varchar(2000) DEFAULT '',
  `INSTANTE_MODIF`                          timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`                           timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`                            varchar(100) NOT NULL,
  `USUARIO_MODIF`                           varchar(100) NOT NULL,
  PRIMARY KEY (`SERIE_ALB`, `NUMERO_ALB`) USING BTREE,
  INDEX `IDX_ALB_PEDIDO`        (`SERIE_PED_ALB`, `NUMERO_PED_ALB`),
  INDEX `IDX_ALB_FACTURA`       (`SERIE_FAC_ALB`, `NUMERO_FAC_ALB`),
  INDEX `IDX_ALB_CLIENTE_FECHA` (`CODIGO_CLI_ALB`, `FECHA_ALB`),
  INDEX `IDX_ALB_EMPRESA`       (`CODIGO_EMP_ALB`),
  INDEX `IDX_ALB_ESTADO`        (`ESTADO_ALB`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci ROW_FORMAT=DYNAMIC;


-- -------------------------------------------------------------------
--  fza_albaranes_lineas
--  Detalle del albarán. Cada línea referencia opcionalmente la línea
--  del pedido del que procede.
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS `fza_albaranes_lineas`;
CREATE TABLE `fza_albaranes_lineas` (
  `NUMERO_ALB_ALBLIN`                       varchar(20) NOT NULL,
  `SERIE_ALB_ALBLIN`                        varchar(20) NOT NULL,
  `LINEA_ALBLIN`                            varchar(4)  NOT NULL,
  `NUMERO_PED_ALBLIN`                       varchar(20) NULL,
  `SERIE_PED_ALBLIN`                        varchar(20) NULL,
  `LINEA_PED_ALBLIN`                        varchar(4)  NULL
       COMMENT 'Línea de origen en fza_pedidos_lineas',
  `CODIGO_ART_ALBLIN`                       varchar(20) NULL,
  `CODIGO_FAM_ALBLIN`                       varchar(20) NULL,
  `NOMBRE_FAM_ALBLIN`                       varchar(200) NULL,
  `DESCRIPCION_ARTICULO_ALBLIN`             varchar(100) NULL,
  `TIPO_CANTIDAD_ARTICULO_ALBLIN`           varchar(20) DEFAULT 'Uds',
  `CANTIDAD_ALBLIN`                         decimal(19,6) DEFAULT 1.000000,
  `CODIGO_TAR_ALBLIN`                       varchar(10) NULL,
  `ESIMP_INCL_TARIFA_ALBLIN`                varchar(1) DEFAULT 'S',
  `TIPO_IVA_ARTICULO_ALBLIN`                varchar(2) DEFAULT 'N',
  `PORCENTAJE_IVA_ALBLIN`                   decimal(19,6) DEFAULT 0.000000,
  `PRECIO_VENTA_SIVA_ARTICULO_ALBLIN`       decimal(19,6) DEFAULT 0.000000,
  `PRECIO_VENTA_CIVA_ARTICULO_ALBLIN`       decimal(19,6) DEFAULT 0.000000,
  `TOTAL_ALBLIN`                            decimal(19,6) DEFAULT 0.000000,
  `CODIGO_ALMACEN_ALBLIN`                   varchar(10) NULL,
  `INSTANTE_MODIF`                          timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`                           timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`                            varchar(100) NOT NULL,
  `USUARIO_MODIF`                           varchar(100) NOT NULL,
  PRIMARY KEY (`SERIE_ALB_ALBLIN`, `NUMERO_ALB_ALBLIN`, `LINEA_ALBLIN`) USING BTREE,
  INDEX `IDX_ALBLIN_PEDIDO`   (`SERIE_PED_ALBLIN`, `NUMERO_PED_ALBLIN`, `LINEA_PED_ALBLIN`),
  INDEX `IDX_ALBLIN_ARTICULO` (`CODIGO_ART_ALBLIN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci ROW_FORMAT=DYNAMIC;


-- -------------------------------------------------------------------
--  Vistas auxiliares
-- -------------------------------------------------------------------

DROP VIEW IF EXISTS `vi_pedidos`;
CREATE VIEW `vi_pedidos` AS
SELECT * FROM `fza_pedidos`;

DROP VIEW IF EXISTS `vi_pedidos_lineas`;
CREATE VIEW `vi_pedidos_lineas` AS
SELECT
  PL.*,
  (PL.`CANTIDAD_PEDLIN` - IFNULL(PL.`CANTIDAD_ENTREGADA_PEDLIN`, 0)) AS `CANTIDAD_PENDIENTE_CALC_PEDLIN`
FROM `fza_pedidos_lineas` PL;

DROP VIEW IF EXISTS `vi_albaranes`;
CREATE VIEW `vi_albaranes` AS
SELECT * FROM `fza_albaranes`;

DROP VIEW IF EXISTS `vi_albaranes_lineas`;
CREATE VIEW `vi_albaranes_lineas` AS
SELECT * FROM `fza_albaranes_lineas`;


-- -------------------------------------------------------------------
--  Procedimiento PRC_PED_CREAR_ALBARAN
--  Crea un albarán a partir de las cantidades entregadas pendientes
--  de un pedido. La aplicación pasa una lista de líneas con la
--  cantidad a albaranar (puede ser parcial).
--
--  La aplicación llama:
--    1. PRC_PED_CREAR_ALBARAN_INICIO  -> reserva número
--    2. PRC_PED_CREAR_ALBARAN_LINEA   -> por cada línea entregada
--    3. PRC_PED_CREAR_ALBARAN_FIN     -> recalcula totales y estado
-- -------------------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS `PRC_PED_CREAR_ALBARAN_INICIO` $$
CREATE PROCEDURE `PRC_PED_CREAR_ALBARAN_INICIO` (
  IN  p_NUMERO_PED varchar(20),
  IN  p_SERIE_PED  varchar(20),
  IN  p_USUARIO    varchar(100),
  OUT p_NUMERO_ALB varchar(20),
  OUT p_SERIE_ALB  varchar(20)
)
BEGIN
  DECLARE v_serie  varchar(20);
  DECLARE v_numero varchar(20);

  -- Reusamos la serie del pedido para mantener consistencia
  SELECT `SERIE_PED` INTO v_serie
    FROM `fza_pedidos`
   WHERE `NUMERO_PED` = p_NUMERO_PED
     AND `SERIE_PED`  = p_SERIE_PED;

  -- Próximo número en esa serie para tipo doc 'AL'
  SELECT LPAD(IFNULL(MAX(CAST(`NUMERO_ALB` AS UNSIGNED)), 0) + 1, 6, '0')
    INTO v_numero
    FROM `fza_albaranes`
   WHERE `SERIE_ALB` = v_serie;

  INSERT INTO `fza_albaranes` (
    `NUMERO_ALB`, `SERIE_ALB`, `FECHA_ALB`, `ESTADO_ALB`,
    `NUMERO_PED_ALB`, `SERIE_PED_ALB`,
    `CODIGO_EMP_ALB`, `RAZON_SOCIAL_EMPRESA_ALB`, `NIF_EMPRESA_ALB`,
    `MOVIL_EMPRESA_ALB`, `EMAIL_EMPRESA_ALB`,
    `DIRECCION1_EMPRESA_ALB`, `DIRECCION2_EMPRESA_ALB`,
    `POBLACION_EMPRESA_ALB`, `PROVINCIA_EMPRESA_ALB`,
    `CODIGO_PAI_EMPRESA_ALB`, `NOMBRE_PAI_EMPRESA_ALB`,
    `CODIGO_POSTAL_EMPRESA_ALB`, `GRUPO_ZONA_IVA_EMPRESA_ALB`,
    `CODIGO_CLI_ALB`, `RAZON_SOCIAL_CLIENTE_ALB`, `NIF_CLIENTE_ALB`,
    `MOVIL_CLIENTE_ALB`, `EMAIL_CLIENTE_ALB`,
    `DIRECCION1_CLIENTE_ALB`, `DIRECCION2_CLIENTE_ALB`,
    `POBLACION_CLIENTE_ALB`, `PROVINCIA_CLIENTE_ALB`,
    `CODIGO_POSTAL_CLIENTE_ALB`,
    `CODIGO_PAI_CLIENTE_ALB`, `NOMBRE_PAI_CLIENTE_ALB`,
    `NOMBRE_CLI_ENVIO_ALB`, `MOVIL_CLIENTE_ENVIO_ALB`,
    `DIRECCION1_CLIENTE_ENVIO_ALB`, `DIRECCION2_CLIENTE_ENVIO_ALB`,
    `POBLACION_CLIENTE_ENVIO_ALB`, `PROVINCIA_CLIENTE_ENVIO_ALB`,
    `CODIGO_POSTAL_CLIENTE_ENVIO_ALB`,
    `CODIGO_PAI_CLIENTE_ENVIO_ALB`, `NOMBRE_PAI_CLIENTE_ENVIO_ALB`,
    `TRANSPORTISTA_ALB`, `CODIGO_IVA_ALB`,
    `ESIVA_RECARGO_CLIENTE_ALB`, `ESIVA_EXENTO_CLIENTE_ALB`,
    `ESINTRACOMUNITARIO_CLIENTE_ALB`,
    `TARIFA_ARTICULO_CLIENTE_ALB`, `ESIMP_INCL_TARIFA_CLIENTE_ALB`,
    `PORCENTAJE_IVAN_ALB`, `PORCENTAJE_IVAR_ALB`,
    `PORCENTAJE_IVAS_ALB`, `PORCENTAJE_IVAE_ALB`,
    `FORMA_PAGO_ALB`, `CONTADOR_LINEAS_ALB`,
    `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`
  )
  SELECT
    v_numero, v_serie, CURRENT_DATE(), 'ABIERTO',
    p_NUMERO_PED, p_SERIE_PED,
    P.`CODIGO_EMP_PED`, P.`RAZON_SOCIAL_EMPRESA_PED`, P.`NIF_EMPRESA_PED`,
    P.`MOVIL_EMPRESA_PED`, P.`EMAIL_EMPRESA_PED`,
    P.`DIRECCION1_EMPRESA_PED`, P.`DIRECCION2_EMPRESA_PED`,
    P.`POBLACION_EMPRESA_PED`, P.`PROVINCIA_EMPRESA_PED`,
    P.`CODIGO_PAI_EMPRESA_PED`, P.`NOMBRE_PAI_EMPRESA_PED`,
    P.`CODIGO_POSTAL_EMPRESA_PED`, P.`GRUPO_ZONA_IVA_EMPRESA_PED`,
    P.`CODIGO_CLI_PED`, P.`RAZON_SOCIAL_CLIENTE_FISCAL_PED`,
    P.`NIF_CLIENTE_PED`, P.`MOVIL_CLIENTE_FISCAL_PED`,
    P.`EMAIL_CLIENTE_PED`,
    P.`DIRECCION1_CLIENTE_FISCAL_PED`, P.`DIRECCION2_CLIENTE_FISCAL_PED`,
    P.`POBLACION_CLIENTE_FISCAL_PED`, P.`PROVINCIA_CLIENTE_FISCAL_PED`,
    P.`CODIGO_POSTAL_CLIENTE_FISCAL_PED`,
    P.`CODIGO_PAI_CLIENTE_FISCAL_PED`, P.`NOMBRE_PAI_CLIENTE_FISCAL_PED`,
    P.`NOMBRE_CLI_ENVIO_PED`, P.`MOVIL_CLIENTE_ENVIO_PED`,
    P.`DIRECCION1_CLIENTE_ENVIO_PED`, P.`DIRECCION2_CLIENTE_ENVIO_PED`,
    P.`POBLACION_CLIENTE_ENVIO_PED`, P.`PROVINCIA_CLIENTE_ENVIO_PED`,
    P.`CODIGO_POSTAL_CLIENTE_ENVIO_PED`,
    P.`CODIGO_PAI_CLIENTE_ENVIO_PED`, P.`NOMBRE_PAI_CLIENTE_ENVIO_PED`,
    P.`TRANSPORTISTAPS_PED`, P.`CODIGO_IVA_PED`,
    P.`ESIVA_RECARGO_CLIENTE_PED`, P.`ESIVA_EXENTO_CLIENTE_PED`,
    P.`ESINTRACOMUNITARIO_CLIENTE_PED`,
    P.`TARIFA_ARTICULO_CLIENTE_PED`, P.`ESIMP_INCL_TARIFA_CLIENTE_PED`,
    P.`PORCENTAJE_IVAN_PED`, P.`PORCENTAJE_IVAR_PED`,
    P.`PORCENTAJE_IVAS_PED`, P.`PORCENTAJE_IVAE_PED`,
    P.`FORMA_PAGO_PED`, '0',
    NOW(), p_USUARIO, p_USUARIO
  FROM `fza_pedidos` P
  WHERE P.`NUMERO_PED` = p_NUMERO_PED
    AND P.`SERIE_PED`  = p_SERIE_PED;

  SET p_NUMERO_ALB = v_numero;
  SET p_SERIE_ALB  = v_serie;
END$$

DROP PROCEDURE IF EXISTS `PRC_PED_CREAR_ALBARAN_LINEA` $$
CREATE PROCEDURE `PRC_PED_CREAR_ALBARAN_LINEA` (
  IN  p_NUMERO_ALB    varchar(20),
  IN  p_SERIE_ALB     varchar(20),
  IN  p_NUMERO_PED    varchar(20),
  IN  p_SERIE_PED     varchar(20),
  IN  p_LINEA_PED     varchar(4),
  IN  p_CANTIDAD      decimal(19,6),
  IN  p_USUARIO       varchar(100)
)
PRC: BEGIN
  DECLARE v_linea     varchar(4);
  DECLARE v_pendiente decimal(19,6);
  DECLARE v_cantidad  decimal(19,6);

  -- Cantidad pendiente disponible en la línea origen
  SELECT (`CANTIDAD_PEDLIN` - IFNULL(`CANTIDAD_ENTREGADA_PEDLIN`, 0))
    INTO v_pendiente
    FROM `fza_pedidos_lineas`
   WHERE `NUMERO_PED_PEDLIN` = p_NUMERO_PED
     AND `SERIE_PED_PEDLIN`  = p_SERIE_PED
     AND `LINEA_PEDLIN`      = p_LINEA_PED;

  IF v_pendiente IS NULL OR v_pendiente <= 0 THEN
    -- Nada que entregar
    LEAVE PRC;
  END IF;

  IF p_CANTIDAD > v_pendiente THEN
    SET v_cantidad = v_pendiente;
  ELSE
    SET v_cantidad = p_CANTIDAD;
  END IF;

  -- Próxima línea de albarán
  SELECT LPAD(IFNULL(MAX(CAST(`LINEA_ALBLIN` AS UNSIGNED)), 0) + 10, 4, '0')
    INTO v_linea
    FROM `fza_albaranes_lineas`
   WHERE `NUMERO_ALB_ALBLIN` = p_NUMERO_ALB
     AND `SERIE_ALB_ALBLIN`  = p_SERIE_ALB;

  INSERT INTO `fza_albaranes_lineas` (
    `NUMERO_ALB_ALBLIN`, `SERIE_ALB_ALBLIN`, `LINEA_ALBLIN`,
    `NUMERO_PED_ALBLIN`, `SERIE_PED_ALBLIN`, `LINEA_PED_ALBLIN`,
    `CODIGO_ART_ALBLIN`, `CODIGO_FAM_ALBLIN`, `NOMBRE_FAM_ALBLIN`,
    `DESCRIPCION_ARTICULO_ALBLIN`, `TIPO_CANTIDAD_ARTICULO_ALBLIN`,
    `CANTIDAD_ALBLIN`, `CODIGO_TAR_ALBLIN`, `ESIMP_INCL_TARIFA_ALBLIN`,
    `TIPO_IVA_ARTICULO_ALBLIN`, `PORCENTAJE_IVA_ALBLIN`,
    `PRECIO_VENTA_SIVA_ARTICULO_ALBLIN`,
    `PRECIO_VENTA_CIVA_ARTICULO_ALBLIN`,
    `TOTAL_ALBLIN`, `CODIGO_ALMACEN_ALBLIN`,
    `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`
  )
  SELECT
    p_NUMERO_ALB, p_SERIE_ALB, v_linea,
    p_NUMERO_PED, p_SERIE_PED, p_LINEA_PED,
    PL.`CODIGO_ART_PEDLIN`, PL.`CODIGO_FAM_PEDLIN`, PL.`NOMBRE_FAM_PEDLIN`,
    PL.`DESCRIPCION_ARTICULO_PEDLIN`, PL.`TIPO_CANTIDAD_ARTICULO_PEDLIN`,
    v_cantidad, PL.`CODIGO_TAR_PEDLIN`, PL.`ESIMP_INCL_TARIFA_PEDLIN`,
    PL.`TIPO_IVA_ARTICULO_PEDLIN`, PL.`PORCENTAJE_IVA_PEDLIN`,
    PL.`PRECIO_VENTA_SIVA_ARTICULO_PEDLIN`,
    PL.`PRECIO_VENTA_CIVA_ARTICULO_PEDLIN`,
    (v_cantidad * PL.`PRECIO_VENTA_SIVA_ARTICULO_PEDLIN`),
    PL.`CODIGO_ALMACEN_PEDLIN`,
    NOW(), p_USUARIO, p_USUARIO
  FROM `fza_pedidos_lineas` PL
  WHERE PL.`NUMERO_PED_PEDLIN` = p_NUMERO_PED
    AND PL.`SERIE_PED_PEDLIN`  = p_SERIE_PED
    AND PL.`LINEA_PEDLIN`      = p_LINEA_PED;

  -- Acumular en la línea del pedido
  UPDATE `fza_pedidos_lineas`
     SET `CANTIDAD_ENTREGADA_PEDLIN` = IFNULL(`CANTIDAD_ENTREGADA_PEDLIN`, 0) + v_cantidad,
         `CANTIDAD_PENDIENTE_PEDLIN` = `CANTIDAD_PEDLIN` - (IFNULL(`CANTIDAD_ENTREGADA_PEDLIN`, 0) + v_cantidad),
         `ESENTREGADA_PEDLIN`        = CASE WHEN `CANTIDAD_PEDLIN` <= IFNULL(`CANTIDAD_ENTREGADA_PEDLIN`, 0) + v_cantidad
                                            THEN 'S' ELSE 'N' END,
         `INSTANTE_MODIF`            = NOW(),
         `USUARIO_MODIF`             = p_USUARIO
   WHERE `NUMERO_PED_PEDLIN` = p_NUMERO_PED
     AND `SERIE_PED_PEDLIN`  = p_SERIE_PED
     AND `LINEA_PEDLIN`      = p_LINEA_PED;
END$$

DROP PROCEDURE IF EXISTS `PRC_PED_CREAR_ALBARAN_FIN` $$
CREATE PROCEDURE `PRC_PED_CREAR_ALBARAN_FIN` (
  IN p_NUMERO_ALB varchar(20),
  IN p_SERIE_ALB  varchar(20),
  IN p_NUMERO_PED varchar(20),
  IN p_SERIE_PED  varchar(20),
  IN p_USUARIO    varchar(100)
)
BEGIN
  DECLARE v_total_base    decimal(18,6) DEFAULT 0;
  DECLARE v_total_iva     decimal(18,6) DEFAULT 0;
  DECLARE v_total_liquido decimal(18,6) DEFAULT 0;
  DECLARE v_pendientes    int DEFAULT 0;

  -- Totales del albarán
  SELECT
    IFNULL(SUM(`CANTIDAD_ALBLIN` * `PRECIO_VENTA_SIVA_ARTICULO_ALBLIN`), 0),
    IFNULL(SUM(`CANTIDAD_ALBLIN` * (`PRECIO_VENTA_CIVA_ARTICULO_ALBLIN` -
                                    `PRECIO_VENTA_SIVA_ARTICULO_ALBLIN`)), 0)
    INTO v_total_base, v_total_iva
    FROM `fza_albaranes_lineas`
   WHERE `NUMERO_ALB_ALBLIN` = p_NUMERO_ALB
     AND `SERIE_ALB_ALBLIN`  = p_SERIE_ALB;

  SET v_total_liquido = v_total_base + v_total_iva;

  UPDATE `fza_albaranes`
     SET `TOTAL_BASES_ALB`     = v_total_base,
         `TOTAL_IMPUESTOS_ALB` = v_total_iva,
         `TOTAL_LIQUIDO_ALB`   = v_total_liquido,
         `INSTANTE_MODIF`      = NOW(),
         `USUARIO_MODIF`       = p_USUARIO
   WHERE `NUMERO_ALB` = p_NUMERO_ALB
     AND `SERIE_ALB`  = p_SERIE_ALB;

  -- Estado del pedido: ¿queda algo pendiente?
  SELECT COUNT(*) INTO v_pendientes
    FROM `fza_pedidos_lineas`
   WHERE `NUMERO_PED_PEDLIN` = p_NUMERO_PED
     AND `SERIE_PED_PEDLIN`  = p_SERIE_PED
     AND IFNULL(`ESENTREGADA_PEDLIN`, 'N') <> 'S';

  IF v_pendientes = 0 THEN
    UPDATE `fza_pedidos`
       SET `ESTADO_PED` = 'ENTREGADO',
           `INSTANTE_MODIF` = NOW(),
           `USUARIO_MODIF`  = p_USUARIO
     WHERE `NUMERO_PED` = p_NUMERO_PED
       AND `SERIE_PED`  = p_SERIE_PED;
  ELSE
    UPDATE `fza_pedidos`
       SET `ESTADO_PED` = 'PARCIAL',
           `INSTANTE_MODIF` = NOW(),
           `USUARIO_MODIF`  = p_USUARIO
     WHERE `NUMERO_PED` = p_NUMERO_PED
       AND `SERIE_PED`  = p_SERIE_PED;
  END IF;
END$$

DELIMITER ;


-- -------------------------------------------------------------------
--  Registro en fza_winforms para que ShowMto pueda abrir las pantallas
--  desde el menú principal. Si ya existen, los reemplazamos.
-- -------------------------------------------------------------------

REPLACE INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('Pedidos',   'Pedidos',   'mnuPedidosVenta',
   'inMtoPedidos.TfrmMtoPedidos', 'Ctrl+P',
   'UniDataPedidos.TdmPedidos', 99),
  ('Albaranes', 'Albaranes', 'mnuAlbaranesVenta',
   'inMtoAlbaranes.TfrmMtoAlbaranes', 'Ctrl+A',
   'UniDataAlbaranes.TdmAlbaranes', 99);


-- -------------------------------------------------------------------
--  Contador para albaranes en fza_contadores (igual que para FC)
--  Solo si no existe.
-- -------------------------------------------------------------------

INSERT IGNORE INTO `fza_tipos_documentos`
  (`CODIGO_TD`, `DESCRIPCION_TD`)
VALUES
  ('AL', 'Albarán de Venta');

