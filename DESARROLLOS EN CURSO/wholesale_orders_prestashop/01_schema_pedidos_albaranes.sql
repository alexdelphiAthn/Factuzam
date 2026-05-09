-- ===================================================================
--  Pedidos de Venta Mayor + Albaranes + Integración PrestaShop
--  Sigue la convención de LIBRO_DE_ESTILO_BBDD.md
--  Sufijos:
--    fza_pedidos             -> PED
--    fza_pedidos_lineas      -> PEDLIN
--    fza_pedidos_mensajes    -> PEDMSG
--    fza_albaranes           -> ALB
--    fza_albaranes_lineas    -> ALBLIN
--
--  Este script contiene SÓLO DDL e INSERTs y se puede ejecutar con
--  el menú "Utilidades > Ejecutar Script" de Factuzam (TUniScript
--  divide por ';' y no admite DELIMITER).
--
--  La lógica de creación de albarán a partir de un pedido vive en
--  Pascal (UniDataPedidos.CrearAlbaranDesdePedido), no en stored
--  procedures, precisamente para evitar este problema.
-- ===================================================================

-- -------------------------------------------------------------------
--  fza_pedidos
--  Cabecera del pedido. Mantenemos los campos existentes y añadimos
--  columnas nuevas para gestionar el ciclo de entregas y la
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
--  Registro en fza_winforms para que ShowMto pueda abrir las pantallas
--  desde el menú principal. Si ya existen, los reemplazamos.
-- -------------------------------------------------------------------

REPLACE INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('Pedidos',   'Pedidos',   'mnuPedidosVenta',
   'inMtoPedidos.TfrmMtoPedidos', 'Ctrl+Alt+P',
   'UniDataPedidos.TdmPedidos', 99);

REPLACE INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('Albaranes', 'Albaranes', 'mnuAlbaranesVenta',
   'inMtoAlbaranes.TfrmMtoAlbaranes', 'Ctrl+Alt+A',
   'UniDataAlbaranes.TdmAlbaranes', 99);


-- -------------------------------------------------------------------
--  Tipo de documento Albarán para los contadores numéricos.
-- -------------------------------------------------------------------

INSERT IGNORE INTO `fza_tipos_documentos`
  (`CODIGO_TD`, `DESCRIPCION_TD`)
VALUES
  ('AL', 'Albarán de Venta');
