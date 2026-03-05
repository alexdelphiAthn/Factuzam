/*
 Navicat Premium Dump SQL

 Source Server         : LOCAL
 Source Server Type    : MariaDB
 Source Server Version : 110408 (11.4.8-MariaDB)
 Source Host           : localhost:3306
 Source Schema         : factuzam

 Target Server Type    : MariaDB
 Target Server Version : 110408 (11.4.8-MariaDB)
 File Encoding         : 65001

 Date: 05/03/2026 07:35:54
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for fza_almacenes
-- ----------------------------
DROP TABLE IF EXISTS `fza_almacenes`;
CREATE TABLE `fza_almacenes`  (
  `CODIGO_ALMACEN_ALM` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_EMPRESA_ALM` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ESACTIVO_ALM` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `NOMBRE_ALMACEN_ALM` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PADRE_ALM` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESFISICO_ALM` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `TIPO_USO_ALM` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'ESTANDAR',
  `DIRECCION_ALM` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_ALM` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_POSTAL_ALM` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TELEFONO_ALM` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_ALM` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CLIENTE_ALM` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ALMACEN_DESTINO_ACTUAL_ALM` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Hacia dónde va la mercancía (Pendiente de recibir)',
  `ALMACEN_ORIGEN_ACTUAL_ALM` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'De dónde viene la mercancía cargada',
  `ORDEN_ALM` int(11) NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `PROVINCIA_ALM` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`CODIGO_ALMACEN_ALM`) USING BTREE,
  INDEX `IDX_PADRE_ALM`(`CODIGO_PADRE_ALM` ASC) USING BTREE,
  INDEX `IDX_CLIENTE_ALM`(`CODIGO_CLIENTE_ALM` ASC) USING BTREE,
  INDEX `IDX_EMPRESA_ALM`(`CODIGO_EMPRESA_ALM` ASC) USING BTREE,
  INDEX `IDX_ALMACENES_EMP`(`CODIGO_EMPRESA_ALM` ASC, `ESACTIVO_ALM` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_almacenes
-- ----------------------------
INSERT INTO `fza_almacenes` VALUES ('ALE', '012', 'S', 'GENERAL', NULL, 'S', 'ESTANDARD', 'CALLE CANUTO, 13', 'VILLARALBO', '49159', NULL, NULL, NULL, NULL, NULL, 1, '2026-02-06 06:34:30', '2026-02-06 06:34:30', 'Administrador', 'Administrador', NULL);
INSERT INTO `fza_almacenes` VALUES ('BCN', '1', 'S', 'Almacén Barcelona', NULL, 'S', 'ESTANDAR', 'AV. EIXAMPLE, 3', 'BARCELONA', NULL, '932312923', NULL, NULL, NULL, '', 2, '2026-01-05 06:01:06', '2026-01-29 06:12:21', 'DEMO', 'Administrador', NULL);
INSERT INTO `fza_almacenes` VALUES ('DEP_CL_GEN', '012', 'S', 'Depósitos Clientes Alm Cen', 'GEN', 'N', 'DEPÓSITO', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-03 18:25:17', '2026-02-06 06:47:51', 'DEMO', 'Administrador', NULL);
INSERT INTO `fza_almacenes` VALUES ('FGN', '1', 'S', 'Furgoneta GEN -> BCN', NULL, 'S', 'TRÁNSITO', NULL, NULL, NULL, NULL, NULL, NULL, 'BCN', 'GEN', NULL, '2026-01-29 05:42:51', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL);
INSERT INTO `fza_almacenes` VALUES ('GEN', '012', 'S', 'Almacén Central', NULL, 'S', 'ESTANDAR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, '2026-01-04 22:13:10', '2026-01-29 06:11:20', 'DEMO', 'Administrador', NULL);
INSERT INTO `fza_almacenes` VALUES ('TARAS_G', '1', 'S', 'Taras Almacén Central', 'GEN', 'S', 'TARAS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-05 07:21:37', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL);

-- ----------------------------
-- Table structure for fza_almacenes_cajas
-- ----------------------------
DROP TABLE IF EXISTS `fza_almacenes_cajas`;
CREATE TABLE `fza_almacenes_cajas`  (
  `CODIGO_ALMACEN_ALMCAJ` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_CAJA_ALMCAJ` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `DESCRIPCION_ALMCAJ` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`CODIGO_ALMACEN_ALMCAJ`, `CODIGO_CAJA_ALMCAJ`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_almacenes_cajas
-- ----------------------------
INSERT INTO `fza_almacenes_cajas` VALUES ('ALE', '1', 'CAJA DE VENTA AL PÚBLICO');
INSERT INTO `fza_almacenes_cajas` VALUES ('GEN', '1', 'CAJA PARA VENDER ARTÍCULOS AL DETALLE');

-- ----------------------------
-- Table structure for fza_articulos
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos`;
CREATE TABLE `fza_articulos`  (
  `CODIGO_ARTICULO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ACTIVO_ARTICULO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'S',
  `TIPO_ARTICULO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'ESTANDAR' COMMENT 'ESTANDAR=Físico (Control Stock), SERVICIO=Intangible (Sin Stock), KIT=Pack',
  `DESCRIPCION_ARTICULO` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_FAMILIA_ARTICULO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TIPOIVA_ARTICULO` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ESACTIVO_FIJO_ARTICULO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `TIPO_CANTIDAD_ARTICULO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'Uds',
  `ESVARIACION_ARTICULO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ESTRAZABLE_ARTICULO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'N' COMMENT 'S=Pide Lote/Caducidad, N=No pide',
  `ORDEN_ARTICULO` int(11) NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_ARTICULO`) USING BTREE,
  INDEX `CODIGO`(`CODIGO_ARTICULO` ASC) USING BTREE,
  INDEX `IDX_ARTICULOS_FAMILIA`(`CODIGO_FAMILIA_ARTICULO` ASC) USING BTREE,
  INDEX `IDX_ARTICULOS_FAMILIA_STAT`(`CODIGO_FAMILIA_ARTICULO` ASC, `ACTIVO_ARTICULO` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos
-- ----------------------------
INSERT INTO `fza_articulos` VALUES ('ABRIGO-PAÑO', 'S', 'ESTANDAR', 'Abrigo de Paño Caballero', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('BLUS-SEDA', 'S', 'ESTANDAR', 'Blusa de Seda Cuello V', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:18', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('BOLSO-PIEL', 'S', 'ESTANDAR', 'Bolso de Piel Mujer Grande', 'BOLSOS', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('BOTIN-ANIT', 'S', 'ESTANDAR', 'Botín Ante Mujer', 'CALZADO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:18', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('CAMI-BASICA', 'S', 'ESTANDAR', 'Camiseta de Algodón Básica', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:19', '0000-00-00 00:00:00', 'ADMIN', 'ADMIN');
INSERT INTO `fza_articulos` VALUES ('CAMI-POLO', 'S', 'ESTANDAR', 'Polo Manga Corta Hombre', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('CARTERA-PIEL', 'S', 'ESTANDAR', 'Cartera Piel Caballero', 'COMPLEMENTOS', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-01-07 19:47:30', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('CHAQ-CUERO', 'S', 'ESTANDAR', 'Chaqueta Biker Cuero', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:19', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('CINTURON-PIEL', 'S', 'ESTANDAR', 'Cinturón Piel Reversible', 'COMPLEMENTOS', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('FALD-JEAN', 'S', 'ESTANDAR', 'Minifalda Vaquera', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:19', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('FALD-PLIS', 'S', 'ESTANDAR', 'Falda Larga Plisada', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:19', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('JERSEY-LANA', 'S', 'ESTANDAR', 'Jersey de Lana Cuello Redondo', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('LEGGING-SPORT', 'S', 'ESTANDAR', 'Legging Deportivo Mujer', 'DEPORTIVO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('MOCHILA-SPORT', 'S', 'ESTANDAR', 'Mochila Deportiva 30L', 'BOLSOS', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('PANT-CHIN', 'S', 'ESTANDAR', 'Pantalón Chino Slim', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:19', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('SOMBRERO-PJM', 'S', 'ESTANDAR', 'Sombrero Panamá Verano', 'COMPLEMENTOS', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('SRV-ARREGLOS', 'S', 'SERVICIO', 'Arreglos y Modificaciones', 'OTR', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('SRV-ENVIO', 'S', 'SERVICIO', 'Gastos de Envío', 'OTR', 'N', 'N', 'Uds', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('SUDADERA-HOOD', 'S', 'ESTANDAR', 'Sudadera con Capucha Unisex', 'DEPORTIVO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('VEST-FLOR', 'S', 'ESTANDAR', 'Vestido Estampado Verano', 'ROPA', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:20', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('ZAP-BOTA-MT', 'S', 'ESTANDAR', 'Bota Montaña Impermeable', 'CALZADO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('ZAP-DEPOR', 'S', 'ESTANDAR', 'Zapatilla Deportiva Running', 'CALZADO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:20', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('ZAP-OXFORD', 'S', 'ESTANDAR', 'Zapato Oxford Piel Hombre', 'CALZADO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:20', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos` VALUES ('ZAP-TACÓN', 'S', 'ESTANDAR', 'Zapato Tacón Alto Señora', 'CALZADO', 'N', 'N', 'Uds', 'S', 'N', NULL, '2026-01-05 07:13:21', '0000-00-00 00:00:00', 'DEMO', 'DEMO');

-- ----------------------------
-- Table structure for fza_articulos_conjuntos_asign
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_conjuntos_asign`;
CREATE TABLE `fza_articulos_conjuntos_asign`  (
  `CODIGO_ARTICULO_ACA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ID_CONJUNTO_ACA` int(11) NOT NULL,
  `ID_ATRIBUTO_ACA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ES_GENERACION_AUTO` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `INSTANTEMODIF` datetime NULL DEFAULT NULL,
  `INSTANTEALTA` datetime NULL DEFAULT NULL,
  `USUARIOALTA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `USUARIOMODIF` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`CODIGO_ARTICULO_ACA`, `ID_CONJUNTO_ACA`, `ID_ATRIBUTO_ACA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_conjuntos_asign
-- ----------------------------
INSERT INTO `fza_articulos_conjuntos_asign` VALUES ('CAMI-BASICA', 1, 'CO', 'S', '2026-01-10 17:42:50', '2026-01-10 17:42:50', 'ADMIN', 'ADMIN');
INSERT INTO `fza_articulos_conjuntos_asign` VALUES ('ZAP-OXFORD', 1, 'CO', 'S', '2026-01-10 17:42:50', '2026-01-10 17:42:50', 'ADMIN', 'ADMIN');
INSERT INTO `fza_articulos_conjuntos_asign` VALUES ('ZAP-OXFORD', 2, 'TAL', 'S', '2026-01-10 17:42:50', '2026-01-10 17:42:50', 'ADMIN', 'ADMIN');

-- ----------------------------
-- Table structure for fza_articulos_familias
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_familias`;
CREATE TABLE `fza_articulos_familias`  (
  `CODIGO_FAMILIA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ACTIVO_FAMILIA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ORDEN_FAMILIA` int(11) NULL DEFAULT NULL,
  `ESDEFAULT_FAMILIA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_SUBFAMILIA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_FAMILIA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DESCRIPCION_FAMILIA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CONTADOR_ART_FAMILIA` int(11) NULL DEFAULT NULL,
  `ESCONTADOR_ART_FAMILIA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_FAMILIA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_familias
-- ----------------------------
INSERT INTO `fza_articulos_familias` VALUES ('BOLSOS', 'S', 5, 'N', NULL, 'Bolsos y Mochilas', 'Bolsos, bolsas y mochilas de señora', NULL, 'N', '2026-02-17 06:21:32', '2026-01-01 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_familias` VALUES ('CALZADO', 'S', 2, 'N', NULL, 'Calzado Elegante', 'Calzado Todo tiempo', NULL, 'N', '2026-01-04 21:43:37', '0000-00-00 00:00:00', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_familias` VALUES ('COMPLEMENTOS', 'S', 3, 'N', NULL, 'Complementos Accesorios', 'Complementos para el buen vestir', NULL, 'N', '2026-01-07 19:47:03', '0000-00-00 00:00:00', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_familias` VALUES ('DEPORTIVO', 'S', 4, 'N', NULL, 'Ropa Deportiva', 'Ropa y calzado deportivo', NULL, 'N', '2026-02-17 06:21:32', '2026-01-01 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_familias` VALUES ('OTR', 'S', 6, 'S', NULL, 'Otros articulos agrícolas', 'Otros articulos agrícolas', NULL, NULL, '2024-10-06 20:27:00', '2022-11-02 16:06:31', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_familias` VALUES ('ROPA', 'S', 1, 'N', NULL, 'Ropa de Vestir', 'Ropa de Vestir a la moda', NULL, 'N', '2026-01-04 21:42:50', '0000-00-00 00:00:00', 'Adminnistrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_articulos_propiedades
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_propiedades`;
CREATE TABLE `fza_articulos_propiedades`  (
  `CODIGO_ARTICULO_AP` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ID_VALOR_AP` int(11) NOT NULL COMMENT 'FK hacia fza_atributos_valores',
  `INSTANTEALTA` timestamp NOT NULL DEFAULT current_timestamp(),
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_ARTICULO_AP`, `ID_VALOR_AP`) USING BTREE,
  INDEX `IDX_VALOR_AP`(`ID_VALOR_AP` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_propiedades
-- ----------------------------
INSERT INTO `fza_articulos_propiedades` VALUES ('BLUS-SEDA', 203, '2026-01-06 12:31:02', 'Sistema');

-- ----------------------------
-- Table structure for fza_articulos_proveedores
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_proveedores`;
CREATE TABLE `fza_articulos_proveedores`  (
  `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ARTICULO_ARTICULO_PROVEEDOR` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR` decimal(19, 6) NULL DEFAULT NULL,
  `FECHA_VALIDEZ_ARTICULO_PROVEEDOR` datetime NULL DEFAULT NULL,
  `ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`, `CODIGO_ARTICULO_ARTICULO_PROVEEDOR`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_proveedores
-- ----------------------------
INSERT INTO `fza_articulos_proveedores` VALUES ('000', '.lmmlñlk', 2.000000, NULL, 'S', '2025-04-17 09:50:14', '2025-04-17 09:50:14', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('000', '.lmmlñlkasdfasdf', 2.000000, NULL, 'S', '2025-04-18 11:59:13', '2025-04-18 11:59:13', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('000', '016', 2.000000, NULL, 'S', '2025-04-12 16:27:40', '2024-10-06 20:27:00', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('000', 'MANO', 2.000000, NULL, 'S', '2025-04-18 12:05:44', '2025-04-18 12:05:44', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('000', 'MANODEOBRA', 2.000000, NULL, 'S', '2025-04-18 12:04:33', '2025-04-18 12:04:33', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('010', 'PAÑITOS', 1.000000, NULL, 'S', '2025-04-10 17:34:42', '2024-10-06 21:17:37', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('10', '016', 3.000000, NULL, 'N', '2024-10-06 20:13:41', '2024-10-06 20:13:41', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('10', 'CEBADA', 0.080000, '2023-03-16 00:00:00', 'S', '2023-11-04 17:27:48', '2023-03-16 15:34:56', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('11', 'ALFALFA', 0.250000, '2023-05-03 00:00:00', 'S', '2023-05-24 12:53:58', '2023-03-04 13:40:00', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('17', 'ALFALFA', 0.170000, '2023-05-25 00:00:00', 'N', '2023-03-03 14:30:45', '2023-03-03 14:30:45', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('20', 'ALFALFA', 0.100000, '2023-03-02 00:00:00', 'N', '2023-03-04 18:14:28', '2023-03-03 14:02:47', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('7', '013', 5.000000, '2023-10-20 00:00:00', 'S', '2023-11-04 14:56:50', '2023-11-04 14:56:50', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('ANGEL', 'ALFALFA', 0.170000, NULL, '', '2025-04-17 09:36:55', '2025-04-17 09:34:57', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('FER', '016', 25.000000, NULL, 'N', '2024-10-02 20:21:28', '2024-10-02 20:21:30', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('LAIBENSE', 'PATITORICO', 1.500000, NULL, '', '2025-09-19 11:23:01', '2024-10-06 20:54:23', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_proveedores` VALUES ('PEPI', 'PAPAFRITA', 0.200000, NULL, '', '2025-04-17 09:03:32', '2025-04-17 09:03:32', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_articulos_skus
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_skus`;
CREATE TABLE `fza_articulos_skus`  (
  `CODIGO_UNIDAD_SKU` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ARTICULO_SKU` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_VAR_SKU` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ESACTIVO_SKU` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_UNIDAD_SKU`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_skus
-- ----------------------------
INSERT INTO `fza_articulos_skus` VALUES ('ABRIGO-PAÑO/CAMEL/L', 'ABRIGO-PAÑO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ABRIGO-PAÑO/NEGRO/L', 'ABRIGO-PAÑO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ABRIGO-PAÑO/NEGRO/XL', 'ABRIGO-PAÑO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BLUS-SEDA/BLANCO/L', 'BLUS-SEDA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BLUS-SEDA/BLANCO/M', 'BLUS-SEDA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BLUS-SEDA/BLANCO/S', 'BLUS-SEDA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BLUS-SEDA/NEGRO/M', 'BLUS-SEDA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BLUS-SEDA/NEGRO/S', 'BLUS-SEDA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BLUS-SEDA/ROSA/M', 'BLUS-SEDA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BOTIN-ANIT/MARRON/37', 'BOTIN-ANIT', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BOTIN-ANIT/MARRON/38', 'BOTIN-ANIT', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BOTIN-ANIT/NEGRO/37', 'BOTIN-ANIT', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BOTIN-ANIT/NEGRO/38', 'BOTIN-ANIT', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('BOTIN-ANIT/NEGRO/40', 'BOTIN-ANIT', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-BASICA/BLANCO/L', 'CAMI-BASICA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-BASICA/BLANCO/S', 'CAMI-BASICA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-BASICA/NEGRO/L', 'CAMI-BASICA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-BASICA/NEGRO/S', 'CAMI-BASICA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-BASICA/ROJO/M', 'CAMI-BASICA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-BASICA/ROJO/S', 'CAMI-BASICA', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-POLO/AZUL/L', 'CAMI-POLO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-POLO/AZUL/M', 'CAMI-POLO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-POLO/BLANCO/M', 'CAMI-POLO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CAMI-POLO/BLANCO/S', 'CAMI-POLO', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CHAQ-CUERO/MARRON/L', 'CHAQ-CUERO', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CHAQ-CUERO/MARRON/XL', 'CHAQ-CUERO', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CHAQ-CUERO/NEGRO/L', 'CHAQ-CUERO', 'TC', 'S', '2026-01-08 18:34:51', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CHAQ-CUERO/NEGRO/M', 'CHAQ-CUERO', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('CHAQ-CUERO/NEGRO/XL', 'CHAQ-CUERO', 'TC', 'S', '2026-01-08 18:34:58', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-JEAN/VAQUERO/L', 'FALD-JEAN', 'TC', 'S', '2026-01-08 18:35:04', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-JEAN/VAQUERO/M', 'FALD-JEAN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-JEAN/VAQUERO/S', 'FALD-JEAN', 'TC', 'S', '2026-01-08 18:35:10', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-PLIS/BLANCO/L', 'FALD-PLIS', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-PLIS/BLANCO/M', 'FALD-PLIS', 'TC', 'S', '2026-01-08 18:35:17', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-PLIS/BLANCO/S', 'FALD-PLIS', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-PLIS/VERDE/M', 'FALD-PLIS', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('FALD-PLIS/VERDE/S', 'FALD-PLIS', 'TC', 'S', '2026-01-08 18:35:22', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('JERSEY-LANA/BEIGE/M', 'JERSEY-LANA', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('JERSEY-LANA/GRIS/L', 'JERSEY-LANA', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('JERSEY-LANA/GRIS/M', 'JERSEY-LANA', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('LEGGING-SPORT/NEGRO/M', 'LEGGING-SPORT', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('LEGGING-SPORT/NEGRO/S', 'LEGGING-SPORT', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('LEGGING-SPORT/ROSA/S', 'LEGGING-SPORT', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('PANT-CHIN/BEIGE/42', 'PANT-CHIN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('PANT-CHIN/BEIGE/44', 'PANT-CHIN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('PANT-CHIN/GRIS/40', 'PANT-CHIN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('PANT-CHIN/GRIS/42', 'PANT-CHIN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('PANT-CHIN/NEGRO/40', 'PANT-CHIN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('PANT-CHIN/NEGRO/42', 'PANT-CHIN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('SUDADERA-HOOD/GRIS/M', 'SUDADERA-HOOD', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('SUDADERA-HOOD/GRIS/S', 'SUDADERA-HOOD', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('SUDADERA-HOOD/NEGRO/L', 'SUDADERA-HOOD', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('VEST-FLOR/AZUL/L', 'VEST-FLOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('VEST-FLOR/AZUL/M', 'VEST-FLOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('VEST-FLOR/ROJO/S', 'VEST-FLOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('VEST-FLOR/VERDE/M', 'VEST-FLOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('VEST-FLOR/VERDE/S', 'VEST-FLOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-BOTA-MT/MARRON/43', 'ZAP-BOTA-MT', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-BOTA-MT/NEGRO/41', 'ZAP-BOTA-MT', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-BOTA-MT/NEGRO/42', 'ZAP-BOTA-MT', 'TC', 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/AZUL/41', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/AZUL/42', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/BLANCO/40', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/BLANCO/41', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/BLANCO/42', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/NEGRO/40', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/NEGRO/41', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-DEPOR/NEGRO/42', 'ZAP-DEPOR', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-OXFORD/MARRON/43', 'ZAP-OXFORD', 'TC', 'S', '2026-01-08 18:35:37', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-OXFORD/NEGRO/42', 'ZAP-OXFORD', 'TC', 'S', '2026-01-08 18:35:30', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-TACÓN/NEGRO/37', 'ZAP-TACÓN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-TACÓN/NEGRO/38', 'ZAP-TACÓN', 'TC', 'S', '2026-01-08 18:35:52', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-TACÓN/NEGRO/40', 'ZAP-TACÓN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-TACÓN/ROJO/37', 'ZAP-TACÓN', 'TC', 'S', '2026-01-08 18:35:43', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_skus` VALUES ('ZAP-TACÓN/ROJO/38', 'ZAP-TACÓN', 'TC', 'S', '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');

-- ----------------------------
-- Table structure for fza_articulos_stockactual
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_stockactual`;
CREATE TABLE `fza_articulos_stockactual`  (
  `CODIGO_ALMACEN_STK` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_UNIDAD_STK` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `LOTE_STK` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT '',
  `FECHA_CADUCIDAD_STK` date NULL DEFAULT NULL,
  `CANTIDAD_STK` decimal(19, 6) NULL DEFAULT 0.000000,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `VALOR_TOTAL_STK` decimal(19, 6) NULL DEFAULT 0.000000,
  `PRECIO_MEDIO_STK` decimal(19, 6) NULL DEFAULT 0.000000,
  PRIMARY KEY (`CODIGO_ALMACEN_STK`, `CODIGO_UNIDAD_STK`, `LOTE_STK`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_stockactual
-- ----------------------------
INSERT INTO `fza_articulos_stockactual` VALUES ('BCN', 'LEGGING-SPORT/NEGRO/S', '', NULL, 10.000000, '2026-02-17 06:21:32', 80.000000, 8.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('BCN', 'ZAP-DEPOR/BLANCO/43', '', NULL, 10.000000, '2026-02-22 06:13:04', 300.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('BCN', 'ZAP-DEPOR/NEGRO/44', '', NULL, 8.000000, '2026-02-22 06:13:04', 240.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ABRIGO-PAÑO/CAMEL/L', '', NULL, 3.000000, '2026-02-17 06:21:32', 240.000000, 80.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ABRIGO-PAÑO/NEGRO/L', '', NULL, 3.000000, '2026-02-17 06:21:32', 240.000000, 80.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ABRIGO-PAÑO/NEGRO/XL', '', NULL, 4.000000, '2026-02-17 06:21:32', 320.000000, 80.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BLUS-SEDA/BLANCO/L', '', NULL, 10.000000, '2026-02-22 06:13:04', 260.000000, 26.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BLUS-SEDA/BLANCO/M', '', NULL, 12.000000, '2026-02-22 06:13:04', 312.000000, 26.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BLUS-SEDA/BLANCO/S', '', NULL, 8.000000, '2026-02-22 06:13:04', 208.000000, 26.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BLUS-SEDA/NEGRO/M', '', NULL, 15.000000, '2026-02-22 06:13:04', 390.000000, 26.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BLUS-SEDA/NEGRO/S', '', NULL, 6.000000, '2026-02-22 06:13:04', 156.000000, 26.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BLUS-SEDA/ROSA/M', '', NULL, 5.000000, '2026-02-22 06:13:04', 130.000000, 26.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BOLSO-PIEL', '', NULL, 7.000000, '2026-02-17 06:21:32', 315.000000, 45.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BOTIN-ANIT/MARRON/37', '', NULL, 7.000000, '2026-02-22 06:13:04', 315.000000, 45.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BOTIN-ANIT/MARRON/38', '', NULL, 9.000000, '2026-02-22 06:13:04', 405.000000, 45.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BOTIN-ANIT/NEGRO/37', '', NULL, 6.000000, '2026-02-22 06:13:04', 270.000000, 45.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BOTIN-ANIT/NEGRO/38', '', NULL, 11.000000, '2026-02-22 06:13:04', 495.000000, 45.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'BOTIN-ANIT/NEGRO/40', '', NULL, 8.000000, '2026-02-22 06:13:04', 360.000000, 45.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/BLANCO/L', '', NULL, 22.000000, '2026-02-22 06:13:04', 154.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/BLANCO/M', '', NULL, 25.000000, '2026-02-17 06:21:32', 175.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/BLANCO/S', '', NULL, 30.000000, '2026-02-22 06:13:04', 210.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/NEGRO/L', '', NULL, 19.000000, '2026-02-22 06:13:04', 133.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/NEGRO/M', '', NULL, 25.000000, '2026-02-17 06:21:32', 175.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/NEGRO/S', '', NULL, 28.000000, '2026-02-22 06:13:04', 196.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/ROJO/L', '', NULL, 20.000000, '2026-02-17 06:21:32', 140.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/ROJO/M', '', NULL, 15.000000, '2026-02-22 06:13:04', 105.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-BASICA/ROJO/S', '', NULL, 18.000000, '2026-02-22 06:13:04', 126.000000, 7.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-POLO/AZUL/L', '', NULL, 11.000000, '2026-02-17 06:21:32', 132.000000, 12.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-POLO/AZUL/M', '', NULL, 18.000000, '2026-02-17 06:21:32', 216.000000, 12.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-POLO/BLANCO/M', '', NULL, 10.000000, '2026-02-17 06:21:32', 120.000000, 12.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CAMI-POLO/BLANCO/S', '', NULL, 15.000000, '2026-02-17 06:21:32', 180.000000, 12.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CARTERA-CUERO', '', NULL, 0.000000, '2026-01-08 18:42:39', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CARTERA-PIEL', '', NULL, 7.000000, '2026-02-17 06:21:32', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CHAQ-CUERO/MARRON/L', '', NULL, 3.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CHAQ-CUERO/MARRON/XL', '', NULL, 2.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CHAQ-CUERO/NEGRO/L', '', NULL, 2.000000, '2026-01-12 07:59:51', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CHAQ-CUERO/NEGRO/M', '', NULL, 4.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CHAQ-CUERO/NEGRO/XL', '', NULL, 3.000000, '2026-01-08 18:34:30', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'CINTURON-PIEL', '', NULL, 16.000000, '2026-02-17 06:21:32', 144.000000, 9.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'FALD-JEAN/VAQUERO/L', '', NULL, 15.000000, '2026-01-08 18:34:03', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'FALD-JEAN/VAQUERO/M', '', NULL, 18.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'FALD-PLIS/BLANCO/L', '', NULL, 15.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'FALD-PLIS/BLANCO/S', '', NULL, 12.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'FALD-PLIS/VERDE/M', '', NULL, 14.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'FALD-PLIS/VERDE/S', '', NULL, 20.000000, '2026-01-08 18:33:56', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'JERSEY-LANA/BEIGE/M', '', NULL, 3.000000, '2026-02-17 06:21:32', 75.000000, 25.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'JERSEY-LANA/GRIS/L', '', NULL, 6.000000, '2026-02-17 06:21:32', 150.000000, 25.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'JERSEY-LANA/GRIS/M', '', NULL, 8.000000, '2026-02-17 06:21:32', 200.000000, 25.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'LEGGING-SPORT/NEGRO/M', '', NULL, 20.000000, '2026-02-17 06:21:32', 160.000000, 8.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'LEGGING-SPORT/NEGRO/S', '', NULL, 18.000000, '2026-02-17 06:21:32', 144.000000, 8.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'LEGGING-SPORT/ROSA/S', '', NULL, 0.000000, '2026-02-17 06:21:32', 0.000000, 8.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'MOCHILA-SPORT', '', NULL, 3.000000, '2026-02-17 06:21:32', 54.000000, 18.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/BEIGE/38', '', NULL, 12.000000, '2026-02-17 06:21:32', 480.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/BEIGE/40', '', NULL, 10.000000, '2026-02-17 06:21:32', 400.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/BEIGE/42', '', NULL, 14.000000, '2026-02-22 06:13:04', 560.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/BEIGE/44', '', NULL, 11.000000, '2026-02-22 06:13:04', 440.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/GRIS/40', '', NULL, 9.000000, '2026-02-22 06:13:04', 360.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/GRIS/42', '', NULL, 10.000000, '2026-02-22 06:13:04', 400.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/NEGRO/40', '', NULL, 8.000000, '2026-02-22 06:13:04', 320.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'PANT-CHIN/NEGRO/42', '', NULL, 13.000000, '2026-02-22 06:13:04', 520.000000, 40.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'SOMBRERO-PJM', '', NULL, 7.000000, '2026-02-17 06:21:32', 105.000000, 15.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'SUDADERA-HOOD/GRIS/M', '', NULL, 9.000000, '2026-02-17 06:21:32', 180.000000, 20.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'SUDADERA-HOOD/GRIS/S', '', NULL, 0.000000, '2026-02-17 06:21:32', 0.000000, 20.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'SUDADERA-HOOD/NEGRO/L', '', NULL, 10.000000, '2026-02-17 06:21:32', 200.000000, 20.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/AZUL/L', '', NULL, 6.000000, '2026-02-22 06:13:04', 60.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/AZUL/M', '', NULL, 8.000000, '2026-02-22 06:13:04', 80.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/AZUL/S', '', NULL, 7.000000, '2026-02-17 06:21:32', 70.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/ROJO/M', '', NULL, 5.000000, '2026-02-17 06:21:32', 50.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/ROJO/S', '', NULL, 9.000000, '2026-02-22 06:13:04', 90.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/VERDE/M', '', NULL, 7.000000, '2026-02-22 06:13:04', 70.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'VEST-FLOR/VERDE/S', '', NULL, 5.000000, '2026-02-22 06:13:04', 50.000000, 10.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-BOTA-MT/MARRON/43', '', NULL, 6.000000, '2026-02-17 06:21:32', 252.000000, 42.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-BOTA-MT/NEGRO/41', '', NULL, 8.000000, '2026-02-17 06:21:32', 336.000000, 42.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-BOTA-MT/NEGRO/42', '', NULL, 9.000000, '2026-02-17 06:21:32', 378.000000, 42.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/AZUL/41', '', NULL, 8.000000, '2026-02-22 06:13:04', 240.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/AZUL/42', '', NULL, 9.000000, '2026-02-22 06:13:04', 270.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/BLANCO/40', '', NULL, 12.000000, '2026-02-22 06:13:04', 360.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/BLANCO/41', '', NULL, 15.000000, '2026-02-22 06:13:04', 450.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/BLANCO/42', '', NULL, 14.000000, '2026-02-22 06:13:04', 420.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/BLANCO/43', '', NULL, -1.000000, '2026-02-17 06:21:32', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/NEGRO/40', '', NULL, 10.000000, '2026-02-22 06:13:04', 300.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/NEGRO/41', '', NULL, 18.000000, '2026-02-22 06:13:04', 540.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-DEPOR/NEGRO/42', '', NULL, 16.000000, '2026-02-22 06:13:04', 480.000000, 30.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-OXFORD/MARRON/43', '', NULL, 8.000000, '2026-01-08 18:34:12', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-OXFORD/NEGRO/42', '', NULL, 9.000000, '2026-02-17 06:21:32', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-TACÓN/NEGRO/37', '', NULL, 6.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-TACÓN/NEGRO/40', '', NULL, 5.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-TACÓN/ROJO/37', '', NULL, 5.000000, '2026-01-08 18:34:22', 0.000000, 0.000000);
INSERT INTO `fza_articulos_stockactual` VALUES ('GEN', 'ZAP-TACÓN/ROJO/38', '', NULL, 7.000000, '2026-02-22 06:13:04', 0.000000, 0.000000);

-- ----------------------------
-- Table structure for fza_articulos_tarifas
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_tarifas`;
CREATE TABLE `fza_articulos_tarifas`  (
  `CODIGO_ARTICULO_TARIFA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_UNICO_TARIFA` int(11) NOT NULL AUTO_INCREMENT,
  `CODIGO_UNIDAD_TARIFA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT '' COMMENT 'fza_articulos_skus',
  `CODIGO_TARIFA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ACTIVO_TARIFA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `PRECIOSALIDA_TARIFA` decimal(19, 6) NULL DEFAULT NULL,
  `PRECIOFINAL_TARIFA` decimal(19, 6) NULL DEFAULT 0.000000,
  `PRECIO_DTO_TARIFA` decimal(19, 6) NULL DEFAULT NULL,
  `PORCEN_DTO_TARIFA` decimal(19, 6) NULL DEFAULT NULL,
  `FECHA_DESDE_TARIFA` date NULL DEFAULT NULL,
  `FECHA_HASTA_TARIFA` date NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_UNICO_TARIFA`) USING BTREE,
  INDEX `IDX_ART_TARIFAS_BUSQUEDA`(`CODIGO_ARTICULO_TARIFA` ASC, `CODIGO_TARIFA` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 48 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_tarifas
-- ----------------------------
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-OXFORD', 1, '', 'PVP', 'S', 89.900000, 89.900000, NULL, NULL, '2026-01-01', NULL, '2026-01-05 07:34:59', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-TACÓN', 2, '', 'PVP', 'S', 65.500000, 65.500000, NULL, NULL, '2026-01-01', NULL, '2026-01-05 07:35:04', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('FALD-PLIS', 3, '', 'PVP', 'S', 29.950000, 29.950000, NULL, NULL, '2026-01-01', NULL, '2026-01-05 07:35:10', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('FALD-JEAN', 4, '', 'PVP', 'S', 25.000000, 25.000000, NULL, NULL, '2026-01-01', NULL, '2026-01-05 07:35:15', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CHAQ-CUERO', 5, '', 'PVP', 'S', 120.000000, 120.000000, NULL, NULL, '2026-01-01', NULL, '2026-01-05 07:35:20', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CHAQ-CUERO', 6, 'CHAQ-CUERO/NEGRO/XL', 'PVP', 'S', 130.000000, 130.000000, NULL, NULL, '2026-01-01', NULL, '2026-01-08 18:36:48', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CAMI-BASICA', 7, '', 'PVP', 'S', 150.000000, 135.000000, 15.000000, 10.000000, '2026-01-01', NULL, '2026-01-07 18:04:11', '2026-02-02 06:35:13', 'DEMO', 'Administrador');
INSERT INTO `fza_articulos_tarifas` VALUES ('CARTERA-PIEL', 8, '', 'PVP', 'S', 50.000000, 50.000000, NULL, NULL, '2026-01-01', NULL, '2026-01-07 19:45:48', '0000-00-00 00:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('VEST-FLOR', 9, '', 'PVP', 'S', 20.000000, 20.000000, NULL, NULL, '2026-02-01', NULL, '2026-02-01 07:54:53', '2026-02-01 07:54:53', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_tarifas` VALUES ('VEST-FLOR', 10, '', 'VENTAMAYOR', 'S', 12.000000, 12.000000, NULL, NULL, '2026-02-01', NULL, '2026-02-01 07:54:53', '2026-02-01 07:54:53', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_tarifas` VALUES ('CARTERA-PIEL', 11, '', 'VENTAMAYOR', 'S', 12.000000, 12.000000, NULL, NULL, '2026-02-01', NULL, '2026-02-01 07:55:18', '2026-02-01 07:55:18', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_tarifas` VALUES ('PANT-CHIN', 12, '', 'PVP', 'S', 140.000000, 126.000000, 14.000000, 10.000000, '2026-02-02', NULL, '2026-02-02 06:34:47', '2026-02-02 06:34:47', 'Administrador', 'Administrador');
INSERT INTO `fza_articulos_tarifas` VALUES ('BOLSO-PIEL', 13, '', 'PVP', 'S', 85.000000, 85.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('MOCHILA-SPORT', 14, '', 'PVP', 'S', 39.950000, 39.950000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CAMI-POLO', 15, '', 'PVP', 'S', 28.000000, 28.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('JERSEY-LANA', 16, '', 'PVP', 'S', 55.000000, 55.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ABRIGO-PAÑO', 17, '', 'PVP', 'S', 180.000000, 180.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-BOTA-MT', 18, '', 'PVP', 'S', 95.000000, 95.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CINTURON-PIEL', 19, '', 'PVP', 'S', 22.000000, 22.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('SOMBRERO-PJM', 20, '', 'PVP', 'S', 35.000000, 35.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('LEGGING-SPORT', 21, '', 'PVP', 'S', 19.950000, 19.950000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('SUDADERA-HOOD', 22, '', 'PVP', 'S', 45.000000, 45.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('SRV-ARREGLOS', 23, '', 'PVP', 'S', 12.000000, 12.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('SRV-ENVIO', 24, '', 'PVP', 'S', 5.950000, 5.950000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('BOLSO-PIEL', 25, '', 'VENTAMAYOR', 'S', 55.000000, 55.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('JERSEY-LANA', 26, '', 'VENTAMAYOR', 'S', 35.000000, 35.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ABRIGO-PAÑO', 27, '', 'VENTAMAYOR', 'S', 120.000000, 120.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('SUDADERA-HOOD', 28, '', 'VENTAMAYOR', 'S', 28.000000, 28.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('BLUS-SEDA', 29, '', 'PVP', 'S', 49.950000, 49.950000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('BOTIN-ANIT', 30, '', 'PVP', 'S', 79.900000, 79.900000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-DEPOR', 31, '', 'PVP', 'S', 69.950000, 69.950000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('BLUS-SEDA', 32, '', 'VENTAMAYOR', 'S', 32.000000, 32.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('BOTIN-ANIT', 33, '', 'VENTAMAYOR', 'S', 52.000000, 52.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-DEPOR', 34, '', 'VENTAMAYOR', 'S', 45.000000, 45.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-OXFORD', 35, '', 'VENTAMAYOR', 'S', 58.000000, 58.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-TACÓN', 36, '', 'VENTAMAYOR', 'S', 42.000000, 42.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('FALD-PLIS', 37, '', 'VENTAMAYOR', 'S', 19.000000, 19.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('FALD-JEAN', 38, '', 'VENTAMAYOR', 'S', 16.000000, 16.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CHAQ-CUERO', 39, '', 'VENTAMAYOR', 'S', 78.000000, 78.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CAMI-BASICA', 40, '', 'VENTAMAYOR', 'S', 6.500000, 6.500000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('PANT-CHIN', 41, '', 'VENTAMAYOR', 'S', 75.000000, 75.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CAMI-POLO', 42, '', 'VENTAMAYOR', 'S', 18.000000, 18.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('ZAP-BOTA-MT', 43, '', 'VENTAMAYOR', 'S', 62.000000, 62.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('LEGGING-SPORT', 44, '', 'VENTAMAYOR', 'S', 12.500000, 12.500000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('MOCHILA-SPORT', 45, '', 'VENTAMAYOR', 'S', 25.000000, 25.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('CINTURON-PIEL', 46, '', 'VENTAMAYOR', 'S', 14.000000, 14.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');
INSERT INTO `fza_articulos_tarifas` VALUES ('SOMBRERO-PJM', 47, '', 'VENTAMAYOR', 'S', 22.000000, 22.000000, NULL, NULL, '2026-01-01', NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');

-- ----------------------------
-- Table structure for fza_articulos_vinculos
-- ----------------------------
DROP TABLE IF EXISTS `fza_articulos_vinculos`;
CREATE TABLE `fza_articulos_vinculos`  (
  `ID_VINCULO` int(11) NOT NULL AUTO_INCREMENT,
  `CODIGO_ARTICULO_PADRE` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ARTICULO_HIJO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CANTIDAD` decimal(10, 2) NULL DEFAULT 1.00,
  `ORDEN_VISUAL` int(11) NULL DEFAULT 1,
  `ES_OBLIGATORIO` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  PRIMARY KEY (`ID_VINCULO`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_articulos_vinculos
-- ----------------------------
INSERT INTO `fza_articulos_vinculos` VALUES (1, 'MOCASIN-340', 'MOCASIN-340-UPPER', 1.00, 1, 'S');
INSERT INTO `fza_articulos_vinculos` VALUES (2, 'MOCASIN-340', 'MOCASIN-340-SOLE', 1.00, 2, 'S');

-- ----------------------------
-- Table structure for fza_atributos_conjuntos
-- ----------------------------
DROP TABLE IF EXISTS `fza_atributos_conjuntos`;
CREATE TABLE `fza_atributos_conjuntos`  (
  `ID_CONJUNTO_AC` int(11) NOT NULL AUTO_INCREMENT,
  `NOMBRE_AC` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Nombre descriptivo del set',
  `ID_VA_AC` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'A qué tipo de variación pertenece (CO, TC...)',
  `ESACTIVO_AC` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`ID_CONJUNTO_AC`) USING BTREE,
  INDEX `IDX_VAR_AC`(`ID_VA_AC` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_atributos_conjuntos
-- ----------------------------
INSERT INTO `fza_atributos_conjuntos` VALUES (1, 'COLORES BÁSICOS', 'TC', 'S', '2026-01-04 12:18:01', '2026-01-04 12:17:51', 'Administrador', 'Adminstrador');
INSERT INTO `fza_atributos_conjuntos` VALUES (2, 'TALLAS CABALLERO (42-46)', 'TAL', 'S', '2026-01-28 06:35:28', '2026-01-10 17:42:19', 'ADMIN', 'ADMIN');
INSERT INTO `fza_atributos_conjuntos` VALUES (3, 'TALLAS AMERICANAS (S-XL)', 'TAL', 'S', '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');

-- ----------------------------
-- Table structure for fza_atributos_conjuntos_det
-- ----------------------------
DROP TABLE IF EXISTS `fza_atributos_conjuntos_det`;
CREATE TABLE `fza_atributos_conjuntos_det`  (
  `ID_CONJUNTO_ACD` int(11) NOT NULL COMMENT 'FK a la cabecera del conjunto',
  `ID_VALOR_ACD` int(11) NOT NULL COMMENT 'FK al valor individual (fza_atributos_valores)',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`ID_CONJUNTO_ACD`, `ID_VALOR_ACD`) USING BTREE,
  INDEX `IDX_VALOR_ACD`(`ID_VALOR_ACD` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_atributos_conjuntos_det
-- ----------------------------
INSERT INTO `fza_atributos_conjuntos_det` VALUES (1, 2, '2026-01-04 12:19:35', '2026-01-04 12:18:26', 'Administrador', 'Administrador');
INSERT INTO `fza_atributos_conjuntos_det` VALUES (2, 126, '2026-01-10 17:42:50', '2026-01-10 17:42:50', 'ADMIN', 'ADMIN');
INSERT INTO `fza_atributos_conjuntos_det` VALUES (2, 127, '2026-01-10 17:42:50', '2026-01-10 17:42:50', 'ADMIN', 'ADMIN');
INSERT INTO `fza_atributos_conjuntos_det` VALUES (3, 206, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_conjuntos_det` VALUES (3, 207, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_conjuntos_det` VALUES (3, 208, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_conjuntos_det` VALUES (3, 209, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');

-- ----------------------------
-- Table structure for fza_atributos_sku
-- ----------------------------
DROP TABLE IF EXISTS `fza_atributos_sku`;
CREATE TABLE `fza_atributos_sku`  (
  `CODIGO_UNIDAD_SA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'FK hacia fza_articulos_skus',
  `ID_VALOR_SA` int(11) NOT NULL COMMENT 'FK hacia fza_atributos_valores',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_UNIDAD_SA`, `ID_VALOR_SA`) USING BTREE,
  INDEX `IDX_VALOR_SA`(`ID_VALOR_SA` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_atributos_sku
-- ----------------------------
INSERT INTO `fza_atributos_sku` VALUES ('ABRIGO-PAÑO/CAMEL/L', 4, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ABRIGO-PAÑO/CAMEL/L', 222, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ABRIGO-PAÑO/NEGRO/L', 4, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ABRIGO-PAÑO/NEGRO/L', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ABRIGO-PAÑO/NEGRO/XL', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ABRIGO-PAÑO/NEGRO/XL', 111, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/BLANCO/L', 4, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/BLANCO/L', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/BLANCO/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/BLANCO/M', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/BLANCO/S', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/BLANCO/S', 110, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/NEGRO/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/NEGRO/M', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/NEGRO/S', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/NEGRO/S', 110, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/ROSA/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BLUS-SEDA/ROSA/M', 221, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/MARRON/37', 103, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/MARRON/37', 121, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/MARRON/38', 103, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/MARRON/38', 122, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/NEGRO/37', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/NEGRO/37', 121, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/NEGRO/38', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/NEGRO/38', 122, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/NEGRO/40', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('BOTIN-ANIT/NEGRO/40', 225, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/BLANCO/L', 4, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/BLANCO/L', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/BLANCO/S', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/BLANCO/S', 110, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/NEGRO/L', 4, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/NEGRO/L', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/NEGRO/S', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/NEGRO/S', 110, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/ROJO/M', 1, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/ROJO/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/ROJO/S', 1, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-BASICA/ROJO/S', 110, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/AZUL/L', 4, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/AZUL/L', 218, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/AZUL/M', 3, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/AZUL/M', 218, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/BLANCO/M', 3, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/BLANCO/M', 101, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/BLANCO/S', 101, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CAMI-POLO/BLANCO/S', 110, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/MARRON/L', 4, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/MARRON/L', 103, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/MARRON/XL', 103, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/MARRON/XL', 111, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/NEGRO/L', 4, '2026-01-08 18:54:55', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/NEGRO/L', 100, '2026-01-08 18:55:01', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/NEGRO/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/NEGRO/M', 100, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/NEGRO/XL', 100, '2026-01-08 18:55:08', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('CHAQ-CUERO/NEGRO/XL', 111, '2026-01-08 18:55:21', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-JEAN/VAQUERO/L', 4, '2026-01-08 18:55:32', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-JEAN/VAQUERO/L', 105, '2026-01-08 18:55:38', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-JEAN/VAQUERO/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-JEAN/VAQUERO/M', 105, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-JEAN/VAQUERO/S', 105, '2026-01-08 18:55:45', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-JEAN/VAQUERO/S', 110, '2026-01-08 18:55:51', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/BLANCO/L', 4, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/BLANCO/L', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/BLANCO/M', 3, '2026-01-08 18:55:59', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/BLANCO/M', 101, '2026-01-08 18:56:05', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/BLANCO/S', 101, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/BLANCO/S', 110, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/VERDE/M', 3, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/VERDE/M', 102, '2026-02-22 06:31:28', '2026-02-22 06:31:28', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/VERDE/S', 102, '2026-01-08 18:56:11', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('FALD-PLIS/VERDE/S', 110, '2026-01-08 18:56:18', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('JERSEY-LANA/BEIGE/M', 3, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('JERSEY-LANA/BEIGE/M', 220, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('JERSEY-LANA/GRIS/L', 4, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('JERSEY-LANA/GRIS/L', 219, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('JERSEY-LANA/GRIS/M', 3, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('JERSEY-LANA/GRIS/M', 219, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('LEGGING-SPORT/NEGRO/M', 3, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('LEGGING-SPORT/NEGRO/M', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('LEGGING-SPORT/NEGRO/S', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('LEGGING-SPORT/NEGRO/S', 110, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('LEGGING-SPORT/ROSA/S', 110, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('LEGGING-SPORT/ROSA/S', 221, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('SUDADERA-HOOD/GRIS/M', 3, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('SUDADERA-HOOD/GRIS/M', 219, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('SUDADERA-HOOD/GRIS/S', 110, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('SUDADERA-HOOD/GRIS/S', 219, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('SUDADERA-HOOD/NEGRO/L', 4, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('SUDADERA-HOOD/NEGRO/L', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/AZUL/L', 4, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/AZUL/L', 218, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/AZUL/M', 3, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/AZUL/M', 218, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/ROJO/S', 1, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/ROJO/S', 110, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/VERDE/M', 3, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/VERDE/M', 102, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/VERDE/S', 102, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('VEST-FLOR/VERDE/S', 110, '2026-02-22 06:26:50', '2026-02-22 06:26:50', 'SCRIPT_FIX', 'SCRIPT_FIX');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-BOTA-MT/MARRON/43', 103, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-BOTA-MT/MARRON/43', 127, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-BOTA-MT/NEGRO/41', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-BOTA-MT/NEGRO/41', 224, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-BOTA-MT/NEGRO/42', 100, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-BOTA-MT/NEGRO/42', 126, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-OXFORD/MARRON/43', 103, '2026-01-08 18:56:38', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-OXFORD/MARRON/43', 127, '2026-01-08 18:56:43', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-OXFORD/NEGRO/42', 100, '2026-01-08 18:56:25', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-OXFORD/NEGRO/42', 126, '2026-01-08 18:56:31', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-TACÓN/NEGRO/38', 100, '2026-01-08 18:57:05', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-TACÓN/NEGRO/38', 122, '2026-01-08 18:57:11', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-TACÓN/ROJO/37', 1, '2026-01-08 18:56:51', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_sku` VALUES ('ZAP-TACÓN/ROJO/37', 121, '2026-01-08 18:56:58', '2026-01-04 22:06:12', 'DEMO', 'DEMO');

-- ----------------------------
-- Table structure for fza_atributos_valores
-- ----------------------------
DROP TABLE IF EXISTS `fza_atributos_valores`;
CREATE TABLE `fza_atributos_valores`  (
  `ID_VALOR_AV` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del valor',
  `ID_VA_AV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Relación con fza_variaciones_atributos (ej: CO)',
  `VALOR_AV` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'El valor real (ej: Azul, XL, 42)',
  `DESCRIPCION_AV` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESACTIVO_AV` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `FACTOR_CONVERSION_AV` decimal(19, 6) NULL DEFAULT 1.000000 COMMENT 'Multiplicador respecto a la unidad base',
  `UNIDAD_MEDIDA_AV` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'L, Kg, m, m2, ud',
  `CODIGO_ARTICULO_EXTRA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Si se rellena, al elegir este valor se genera una linea aparte con un incremento por ejemplo',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`ID_VALOR_AV`) USING BTREE,
  INDEX `IDX_VAR_AV`(`ID_VA_AV` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 228 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_atributos_valores
-- ----------------------------
INSERT INTO `fza_atributos_valores` VALUES (1, 'CO', 'ROJO', 'Color ROJO', 'S', 1.000000, NULL, NULL, '2026-01-28 07:21:56', '2026-01-04 12:06:34', 'Sistema', 'Sistema');
INSERT INTO `fza_atributos_valores` VALUES (3, 'TAL', 'M', 'Talla M', 'S', 1.000000, NULL, NULL, '2026-01-28 07:22:01', '2026-01-04 12:11:37', 'Sistema', 'Sistema');
INSERT INTO `fza_atributos_valores` VALUES (4, 'TAL', 'L', 'Talla L (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:33', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (100, 'CO', 'NEGRO', 'Color Negro (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:34', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (101, 'CO', 'BLANCO', 'Color Blanco (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:35', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (102, 'CO', 'VERDE', 'Color Verde (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:36', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (103, 'CO', 'MARRON', 'Color Marron (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:37', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (105, 'CO', 'VAQUERO', 'Color/Acabado Vaquero (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:38', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (110, 'TAL', 'S', 'Talla S (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:40', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (111, 'TAL', 'XL', 'Talla XL (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:41', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (121, 'TAL', '37', 'Talla 37 (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:42', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (122, 'TAL', '38', 'Talla 38 (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:43', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (126, 'TAL', '42', 'Talla 42 (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:44', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (127, 'TAL', '43', 'Talla 43 (Deducido)', 'S', 1.000000, NULL, NULL, '2026-01-06 19:35:46', '0000-00-00 00:00:00', 'ScriptReparacion', 'ScriptReparacion');
INSERT INTO `fza_atributos_valores` VALUES (203, 'TEMP', 'PV26', 'Primavera/Verano 2026', 'S', 1.000000, NULL, NULL, '2026-01-06 12:29:59', '0000-00-00 00:00:00', 'Admin', 'Admin');
INSERT INTO `fza_atributos_valores` VALUES (204, 'TEMP', 'OI26', 'Otoño/Invierno 2026', 'S', 1.000000, NULL, NULL, '2026-01-06 12:29:59', '0000-00-00 00:00:00', 'Admin', 'Admin');
INSERT INTO `fza_atributos_valores` VALUES (205, 'TEMP', 'ATEMPORAL', 'Básicos / Continuidad', 'S', 1.000000, NULL, NULL, '2026-01-06 12:29:59', '0000-00-00 00:00:00', 'Admin', 'Admin');
INSERT INTO `fza_atributos_valores` VALUES (206, 'TAL', 'S', 'Small - Pequeña', 'S', 1.000000, NULL, NULL, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_valores` VALUES (207, 'TAL', 'M', 'Medium - Mediana', 'S', 1.000000, NULL, NULL, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_valores` VALUES (208, 'TAL', 'L', 'Large - Grande', 'S', 1.000000, NULL, NULL, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_valores` VALUES (209, 'TAL', 'XL', 'Extra Large - Extra G.', 'S', 1.000000, NULL, NULL, '2026-01-28 07:43:41', '2026-01-28 07:43:41', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_atributos_valores` VALUES (218, 'CO', 'AZUL', 'Color Azul', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (219, 'CO', 'GRIS', 'Color Gris', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (220, 'CO', 'BEIGE', 'Color Beige', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (221, 'CO', 'ROSA', 'Color Rosa', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (222, 'CO', 'CAMEL', 'Color Camel', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (223, 'CO', 'ROJO', 'Color Rojo (alias)', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (224, 'TAL', '41', 'Talla 41', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (225, 'TAL', '40', 'Talla 40', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (226, 'TAL', '44', 'Talla 44', 'S', 1.000000, NULL, NULL, '2026-02-17 06:27:34', '2026-02-17 06:27:34', 'DEMO', 'DEMO');
INSERT INTO `fza_atributos_valores` VALUES (227, 'TAL', '39', 'Talla 39', 'S', 1.000000, NULL, NULL, '2026-02-22 06:13:04', '2026-02-22 06:13:04', 'SCRIPT_DEMO', 'SCRIPT_DEMO');

-- ----------------------------
-- Table structure for fza_atributos_valores_info
-- ----------------------------
DROP TABLE IF EXISTS `fza_atributos_valores_info`;
CREATE TABLE `fza_atributos_valores_info`  (
  `ID_INFO` int(11) NOT NULL AUTO_INCREMENT,
  `ID_VALOR_AV_INFO` int(11) NOT NULL COMMENT 'Relación con fza_atributos_valores (El ID del Rojo o de la XL)',
  `CLAVE_INFO` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'El nombre del dato: COD_PROV, MEDIDA_CM, HEX, etc.',
  `VALOR_INFO` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'El valor del dato: RED-01, 50-70, #FF0000',
  PRIMARY KEY (`ID_INFO`) USING BTREE,
  INDEX `IDX_VALOR_INFO`(`ID_VALOR_AV_INFO` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_atributos_valores_info
-- ----------------------------

-- ----------------------------
-- Table structure for fza_caja_formas_pago
-- ----------------------------
DROP TABLE IF EXISTS `fza_caja_formas_pago`;
CREATE TABLE `fza_caja_formas_pago`  (
  `CODIGO_FORMAP` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Código identificativo (EFE, TARJ, etc)',
  `DESCRIPCION_FORMAP` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Nombre visual para el ticket',
  `ES_REQ_REFERENCIA_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'N' COMMENT 'S=Obliga a introducir un número (ej: cod barras bono, nro autorización tarjeta)',
  `ES_CRIPTO_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `RED_BLOCKCHAIN_FORMAP` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `HASH_BOCKCHAIN_FORMAP` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESDIVISA_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ES_DEVUELVE_CAMBIO_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'S=Permite dar cambio. N=No permite (el bono debe gastarse entero o se pierde el resto)',
  `ES_ABRE_CAJON_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'S=Lanza la secuencia de apertura de cajón',
  `ES_ACTIVO_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `PORCEN_COMISION_FORMAP` int(11) NULL DEFAULT NULL,
  `ESCOMISION_INCL_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NUM_COD_DIGIT_FORMAP` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ORDEN_VISUAL_FORMAP` int(11) NULL DEFAULT 99 COMMENT 'Para ordenar los botones en la pantalla F12',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_FORMAP`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_caja_formas_pago
-- ----------------------------
INSERT INTO `fza_caja_formas_pago` VALUES ('BONO', 'Bono ayuntamiento', 'S', 'N', NULL, NULL, 'N', 'N', 'N', 'S', NULL, NULL, NULL, 4, '2026-02-16 06:14:09', '0000-00-00 00:00:00', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_caja_formas_pago` VALUES ('BTC', 'Bitcoin', 'N', 'S', NULL, NULL, 'S', 'N', 'N', 'S', NULL, NULL, NULL, 3, '2026-02-18 16:35:05', '2026-02-18 16:34:57', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_caja_formas_pago` VALUES ('EFE', 'Efectivo', 'N', 'N', NULL, NULL, 'N', 'S', 'S', 'S', NULL, NULL, NULL, 1, '2026-02-16 06:14:10', '0000-00-00 00:00:00', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_caja_formas_pago` VALUES ('TARJ', 'Tarjeta BBVA', 'N', 'N', NULL, NULL, 'N', 'N', 'N', 'S', NULL, NULL, NULL, 2, '2026-02-16 06:14:12', '0000-00-00 00:00:00', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_caja_formas_pago` VALUES ('USD', 'Dólar Americano', 'N', 'N', NULL, NULL, 'S', 'N', 'N', 'S', NULL, NULL, NULL, 5, '2026-02-17 07:33:18', '0000-00-00 00:00:00', 'SISTEMA', 'SISTEMA');

-- ----------------------------
-- Table structure for fza_caja_operaciones
-- ----------------------------
DROP TABLE IF EXISTS `fza_caja_operaciones`;
CREATE TABLE `fza_caja_operaciones`  (
  `CODIGO_EMPRESA_OPCAJA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ALMACEN_OPCAJA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_CAJA_OPCAJA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Terminal físico (TPV1, TPV2...)',
  `NUMERO_OPERACION_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NRO_FACTURA_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SERIE_FACTURA_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_OPERACION_OPCAJA` datetime NOT NULL,
  `CODIGO_EMPLEADO_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TIPO_OPERACION_OPCAJA` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'VE, AL, CB, EC, GC, TR, AT',
  `IMPORTE_TOTAL_OPCAJA` decimal(19, 6) NOT NULL DEFAULT 0.000000,
  `CODIGO_CLIENTE_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESTADO_DEVOLUCION_OPCAJA` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'N',
  `IMPORTE_DEVUELTO_ACUM_OPCAJA` decimal(19, 6) NOT NULL DEFAULT 0.000000,
  `CONCEPTO_GASTO_INGRESO_OPCAJA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SERIE_REF_ORIGEN_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NUMERO_REF_ORIGEN_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOTIVO_DEVOLUCION_OPCAJA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_EMPRESA_CONTRA_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_ALMACEN_CONTRA_OPCAJA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ES_TRASPASO_OPCAJA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `CODIGO_ARQUEO_OPCAJA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'ID del Cierre Z al que pertenece esta línea',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_EMPRESA_OPCAJA`, `CODIGO_ALMACEN_OPCAJA`, `CODIGO_CAJA_OPCAJA`, `NUMERO_OPERACION_OPCAJA`) USING BTREE,
  INDEX `IDX_REF_ORIGEN_OPCAJA`(`SERIE_REF_ORIGEN_OPCAJA` ASC, `NUMERO_REF_ORIGEN_OPCAJA` ASC) USING BTREE,
  INDEX `IDX_CIERRE_OPCAJA`(`CODIGO_ARQUEO_OPCAJA` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_caja_operaciones
-- ----------------------------

-- ----------------------------
-- Table structure for fza_caja_pagos
-- ----------------------------
DROP TABLE IF EXISTS `fza_caja_pagos`;
CREATE TABLE `fza_caja_pagos`  (
  `CODIGO_EMPRESA_PAGO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ALMACEN_PAGO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_CAJA_PAGO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SERIE_OPERACION_PAGO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NUMERO_OPERACION_PAGO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NUMERO_LINEA_PAGO` int(11) NOT NULL DEFAULT 1 COMMENT 'Orden del pago: 1, 2, 3...',
  `CODIGO_FORMAP` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'FK a fza_formas_pago',
  `CODIGO_DIVISA_PAGO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código ISO o Ticker: USD, BTC, ETH',
  `RED_BLOCKCHAIN` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Ej: Bitcoin, Ethereum, TRC20, ERC20, Lightning',
  `FACTOR_CAMBIO_PAGO` decimal(24, 8) NOT NULL DEFAULT 1.00000000 COMMENT 'Valor de conversión respecto a la moneda base',
  `IMPORTE_DIVISA_PAGO` decimal(24, 8) NOT NULL DEFAULT 0.00000000 COMMENT 'Cantidad entregada en la divisa o crypto original',
  `IMPORTE_ENTREGADO_PAGO` decimal(19, 6) NOT NULL DEFAULT 0.000000,
  `IMPORTE_CAMBIO_PAGO` decimal(19, 6) NOT NULL DEFAULT 0.000000 COMMENT 'Solo para efectivo si entrega de más',
  `REFERENCIA_PAGO` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Hash de Transacción (TxID), Auth Tarjeta o Referencia',
  `OBSERVACIONES_PAGO` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_EMPRESA_PAGO`, `CODIGO_ALMACEN_PAGO`, `CODIGO_CAJA_PAGO`, `SERIE_OPERACION_PAGO`, `NUMERO_OPERACION_PAGO`, `NUMERO_LINEA_PAGO`) USING BTREE,
  INDEX `FK_PAGO_FORMAP`(`CODIGO_FORMAP` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_caja_pagos
-- ----------------------------

-- ----------------------------
-- Table structure for fza_caja_vales
-- ----------------------------
DROP TABLE IF EXISTS `fza_caja_vales`;
CREATE TABLE `fza_caja_vales`  (
  `CODIGO_VL` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Código de barras identificador',
  `CODIGO_PADRE_VL` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Si este vale es el cambio de otro anterior, aquí va el ID del padre',
  `PIN_SEGURIDAD_VL` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT '' COMMENT 'Código aleatorio tipo CVV para validar el vale',
  `ESTADO_VL` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'PENDIENTE' COMMENT 'PENDIENTE, REDIMIDO, ANULADO, CADUCADO',
  `IMPORTE_NOMINAL_VL` decimal(19, 6) NOT NULL DEFAULT 0.000000 COMMENT 'El valor monetario que tiene este vale',
  `FECHA_EMISION_VL` datetime NOT NULL,
  `FECHA_CADUCIDAD_VL` date NULL DEFAULT NULL,
  `CODIGO_EMPRESA_EMI_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ALMACEN_EMI_VL` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_CAJA_EMI_VL` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NUMERO_OPERACION_EMI_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'ID operación TPV donde se creó',
  `SERIE_FACTURA_EMI_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Factura de abono o ticket origen',
  `NRO_FACTURA_EMI_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_REDENCION_VL` datetime NULL DEFAULT NULL,
  `IMPORTE_REDIMIDO_VL` decimal(19, 6) NULL DEFAULT 0.000000 COMMENT 'Suele coincidir con el nominal al ser de uso único',
  `CODIGO_EMPRESA_RED_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_ALMACEN_RED_VL` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CAJA_RED_VL` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NUMERO_OPERACION_RED_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'ID operación TPV donde se gastó',
  `SERIE_FACTURA_RED_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Factura o ticket que se pagó con esto',
  `NRO_FACTURA_RED_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CLIENTE_VL` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `OBSERVACIONES_VL` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_VL`) USING BTREE,
  INDEX `IDX_CADUCIDAD_VL`(`FECHA_CADUCIDAD_VL` ASC) USING BTREE,
  INDEX `IDX_ESTADO_VL`(`ESTADO_VL` ASC) USING BTREE,
  INDEX `IDX_ORIGEN_VL`(`CODIGO_EMPRESA_EMI_VL` ASC, `NUMERO_OPERACION_EMI_VL` ASC) USING BTREE,
  INDEX `IDX_PADRE_VL`(`CODIGO_PADRE_VL` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_caja_vales
-- ----------------------------
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00001', NULL, '8342', 'REDIMIDO', 45.000000, '2026-01-15 14:30:00', '2027-01-15', '1', 'GEN', '1', '1_GEN_1_20260115001', 'A1', '000125', '2026-01-22 11:45:00', 45.000000, '1', 'GEN', '1', '1_GEN_1_20260122003', '000032', 'A1', 'CLI001', 'Vale usado en compra de jersey', '2026-02-22 07:56:52', '2026-01-15 14:30:00', 'ALEX', 'ALEX');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00002', NULL, '620163598', 'PENDIENTE', 89.000000, '2026-02-10 16:20:00', '2027-02-10', '1', 'GEN', '1', '1_GEN_1_20260210005', 'A1', '000198', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI045', 'Devolución zapatos talla incorrecta', '2026-02-22 22:48:15', '2026-02-10 16:20:00', 'MARIA', 'MARIA');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00003', NULL, '9234', 'CADUCADO', 25.000000, '2024-02-20 10:15:00', '2025-02-20', '1', 'GEN', '1', '1_GEN_1_20240220002', 'A1', '000089', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI012', 'Vale caducado por no uso', '2026-02-22 07:56:52', '2024-02-20 10:15:00', 'PEDRO', 'PEDRO');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00004', NULL, '5678', 'ANULADO', 150.000000, '2026-01-25 09:30:00', '2027-01-25', '1', 'GEN', '1', '1_GEN_1_20260125001', 'A1', '000165', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI023', 'Anulado por error - cliente prefirió reembolso en efectivo', '2026-02-22 07:56:52', '2026-01-25 09:35:00', 'LAURA', 'LAURA');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00005', NULL, '4521', 'REDIMIDO', 100.000000, '2026-01-05 12:00:00', '2027-01-05', '1', 'GEN', '1', '1_GEN_1_20260105002', 'A1', '000078', '2026-02-15 15:30:00', 100.000000, '1', 'GEN', '2', '1_GEN_2_20260215008', '000033', 'A1', 'CLI067', 'Usado parcialmente - generó vale de cambio', '2026-02-22 07:56:52', '2026-01-05 12:00:00', 'CARLOS', 'CARLOS');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00007', NULL, '3344', 'PENDIENTE', 12.500000, '2025-12-20 10:00:00', '2026-12-20', '1', 'GEN', '1', '1_GEN_1_20251220003', 'A1', '000045', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI089', 'Devolución camiseta', '2026-02-22 07:56:52', '2025-12-20 10:00:00', 'ANA', 'ANA');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00008', NULL, '5566', 'PENDIENTE', 8.750000, '2026-01-08 14:30:00', '2027-01-08', '1', 'GEN', '1', '1_GEN_1_20260108006', 'A1', '000091', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI089', 'Devolución accesorio', '2026-02-22 07:56:52', '2026-01-08 14:30:00', 'ANA', 'ANA');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00009', NULL, '7788', 'PENDIENTE', 15.000000, '2026-02-01 11:15:00', '2027-02-01', '1', 'GEN', '1', '1_GEN_1_20260201004', 'A1', '000187', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI089', 'Devolución artículo defectuoso', '2026-02-22 07:56:52', '2026-02-01 11:15:00', 'ANA', 'ANA');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-1-00010', NULL, '9012', 'PENDIENTE', 32.000000, '2026-02-18 17:45:00', '2026-08-18', '1', 'GEN', '1', '1_GEN_1_20260218012', '000031', 'A1', NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Venta contado - vale anónimo', '2026-02-22 07:56:52', '2026-02-18 17:45:00', 'SISTEMA', 'SISTEMA');
INSERT INTO `fza_caja_vales` VALUES ('VALE-1-GEN-2-00006', 'VALE-1-GEN-1-00005', '7823', 'PENDIENTE', 35.000000, '2026-02-15 15:35:00', '2027-02-15', '1', 'GEN', '2', '1_GEN_2_20260215008', NULL, NULL, NULL, 0.000000, NULL, NULL, NULL, NULL, NULL, NULL, 'CLI067', 'Vale de cambio generado de VALE-1-GEN-1-00005', '2026-02-22 07:56:52', '2026-02-15 15:35:00', 'SISTEMA', 'SISTEMA');

-- ----------------------------
-- Table structure for fza_clientes
-- ----------------------------
DROP TABLE IF EXISTS `fza_clientes`;
CREATE TABLE `fza_clientes`  (
  `CODIGO_CLIENTE` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ACTIVO_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ORDEN_CLIENTE` int(11) NULL DEFAULT NULL,
  `RAZONSOCIAL_CLIENTE` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NIF_CLIENTE` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_CLIENTE` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_CLIENTE` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_CLIENTE` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_CLIENTE` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_CLIENTE` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_CLIENTE` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_CLIENTE` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_CLIENTE` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_CLIENTE` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `OBSERVACIONES_CLIENTE` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `REFERENCIA_CLIENTE` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CONTACTO_CLIENTE` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TELEFONO_CONTACTO_CLIENTE` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TELEFONO_CLIENTE` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IBAN_CLIENTE` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESIVA_RECARGO_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESRETENCIONES_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `TOTAL_LIMITE_CREDITO_CLIENTE` decimal(19, 6) NULL DEFAULT NULL,
  `ESPERMITE_DEUDA_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TOTAL_DEUDA_CLIENTE` decimal(19, 6) NULL DEFAULT NULL,
  `ESIVA_EXENTO_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESINTRACOMUNITARIO_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESREGIMENESPECIALAGRICOLA_CLIENTE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `CODIGO_FORMA_PAGO_CLIENTE` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TARIFA_ARTICULO_CLIENTE` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SERIE_CONTADOR_CLIENTE` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TEXTO_LEGAL_FACTURA_CLIENTE` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_CLIENTE`) USING BTREE,
  INDEX `IDX_CLIENTES_EMAIL`(`EMAIL_CLIENTE` ASC) USING BTREE,
  INDEX `IDX_RAZONSOCIAL_CLIENTE`(`RAZONSOCIAL_CLIENTE` ASC) USING BTREE,
  INDEX `IDX_NIF_CLIENTE`(`EMAIL_CLIENTE` ASC) USING BTREE,
  INDEX `IDX_POBLACION_CLIENTE`(`NIF_CLIENTE` ASC) USING BTREE,
  INDEX `IDX_REFERENCIA_CLIENTE`(`REFERENCIA_CLIENTE` ASC) USING BTREE,
  INDEX `IDX_CLIENTES_LISTADO`(`CODIGO_CLIENTE` ASC, `RAZONSOCIAL_CLIENTE` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_clientes
-- ----------------------------
INSERT INTO `fza_clientes` VALUES ('293', 'S', 5, 'PEDRO COJOS', '46589963j', NULL, 'pedro.cojos@gmail.com', 'CALLE CAIDOS ', NULL, 'VILLAVEZA DEL AGUA', 'ZAMORA', '49760', '826', 'España', NULL, NULL, NULL, NULL, NULL, 'ES3201822305650206595350', 'N', 'N', 1000.000000, 'S', NULL, 'N', 'N', 'S', '60DIAS', '1', NULL, NULL, '2026-03-03 17:37:45', '2023-05-22 13:01:22', 'Administrador', 'Administrador');
INSERT INTO `fza_clientes` VALUES ('294', 'S', 4, 'AGUSTIN SEGURADO', '11632589R', '623356689', 'agustin.segurado@gmail.com', 'CALLE EL RIEGO, 33', '', 'ZAMORA', 'ZAMORA', '49019', NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 'S', 'S', NULL, NULL, NULL, 'N', 'N', 'N', NULL, '1', NULL, NULL, '2023-11-11 15:27:57', '2023-10-31 12:15:11', 'Administrador', 'Administrador');
INSERT INTO `fza_clientes` VALUES ('295', 'S', 6, 'AZUCENA MARTIN (KIOSKO PERLA)', '11356325E', '658963321', 'cliente.nuevo@gmail.om', 'CALLE POZO AMARILLO, 3', '', 'SALAMANCA', 'SALAMANCA', '37003', 'ES', 'España', NULL, NULL, NULL, NULL, NULL, 'ES50 0182 5632 3656 9872 0145               ', 'S', 'S', NULL, NULL, NULL, 'N', 'N', 'N', NULL, 'VENTAMAYOR', NULL, NULL, '2026-01-29 05:22:58', '2023-12-06 13:07:42', 'Administrador', 'Administrador');
INSERT INTO `fza_clientes` VALUES ('301', 'S', 10, 'LAURA FERNÁNDEZ GIL', '12345678A', '655101010', 'laura.fernandez@gmail.com', 'CALLE MAYOR, 15', '', 'MADRID', 'MADRID', '28001', '724', 'España', NULL, NULL, NULL, NULL, '912233445', NULL, 'N', 'S', 1000.000000, 'S', NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-03-03 17:56:25', '2026-01-15 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('302', 'S', 11, 'CARLOS HERRERO SANTOS', '23456789B', '666202020', 'carlos.herrero@hotmail.com', 'AVDA. LIBERTAD, 22', '2º A', 'BARCELONA', 'BARCELONA', '08001', '724', 'España', NULL, NULL, NULL, NULL, '934455667', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-15 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('303', 'S', 12, 'MARTA RUIZ LÓPEZ', '34567890C', '677303030', 'marta.ruiz@gmail.com', 'C/ CERVANTES, 8', '', 'VALENCIA', 'VALENCIA', '46001', '724', 'España', NULL, NULL, NULL, NULL, '963344556', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'TRANSFERENCIA', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-15 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('304', 'S', 13, 'JUAN MARTÍN PÉREZ', '45678901D', '688404040', 'juan.martin@empresa.es', 'C/ ALCALÁ, 100', '', 'MADRID', 'MADRID', '28009', '724', 'España', NULL, NULL, NULL, NULL, '915566778', NULL, 'S', 'S', NULL, NULL, NULL, 'N', 'N', 'N', '60DIAS', 'VENTAMAYOR', NULL, NULL, '2026-02-17 06:21:32', '2026-01-15 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('305', 'S', 14, 'ANA GARCÍA MORENO', '56789012E', '699505050', 'ana.garcia@yahoo.es', 'PLAZA ESPAÑA, 3', '1º B', 'SEVILLA', 'SEVILLA', '41001', '724', 'España', NULL, NULL, NULL, NULL, '954677889', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-15 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('306', 'S', 15, 'DISTRIBUCIONES VELÁZQUEZ SL', 'B12345678', '968606060', 'pedidos@distribuvelaz.es', 'POLÍGONO EL PINO, 5', 'NAVE 12', 'MURCIA', 'MURCIA', '30001', '724', 'España', NULL, NULL, 'PEDRO VELÁZQUEZ', '968606061', '968606060', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', '30DIAS', 'VENTAMAYOR', NULL, NULL, '2026-02-17 06:21:32', '2026-01-16 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('307', 'S', 16, 'ROSA JIMÉNEZ VILLA', '67890123F', '611707070', 'rosa.jimenez@gmail.com', 'C/ RÍO SEGURA, 12', '', 'ZARAGOZA', 'ZARAGOZA', '50001', '724', 'España', NULL, NULL, NULL, NULL, '976788990', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-16 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('308', 'S', 17, 'MANUEL TORRES BLANCO', '78901234G', '622808080', 'manuel.torres@icloud.com', 'AVDA. DEL MAR, 45', '', 'MÁLAGA', 'MÁLAGA', '29001', '724', 'España', NULL, NULL, NULL, NULL, '952899001', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-16 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('309', 'S', 18, 'PAULA SÁNCHEZ ROMERO', '89012345H', '633909090', 'paula.sanchez@gmail.com', 'C/ EL PILAR, 7', 'Bajo A', 'BILBAO', 'VIZCAYA', '48001', '724', 'España', NULL, NULL, NULL, NULL, '944910011', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'TRANSFERENCIA', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-16 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('310', 'S', 19, 'MODA FÁCIL SL', 'B87654321', '944010101', 'compras@modafacil.com', 'C/ INDUSTRIA, 33', 'POL. NORTE', 'BILBAO', 'VIZCAYA', '48008', '724', 'España', NULL, NULL, 'NURIA ARAMBURU', '944010102', '944010101', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', '30DIAS', 'VENTAMAYOR', NULL, NULL, '2026-02-17 06:21:32', '2026-01-16 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('311', 'S', 20, 'DAVID NAVARRO IBÁÑEZ', '90123456I', '644111111', 'd.navarro@gmail.com', 'C/ COLÓN, 18', '3ºC', 'ALICANTE', 'ALICANTE', '03001', '724', 'España', NULL, NULL, NULL, NULL, '965221122', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-17 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('312', 'S', 21, 'ISABEL MORALES CANO', '01234567J', '655222222', 'isabel.morales@outlook.com', 'AVDA. CONSTITUCIÓN, 9', '', 'GRANADA', 'GRANADA', '18001', '724', 'España', NULL, NULL, NULL, NULL, '958332233', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-17 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('313', 'S', 22, 'TEXTILES NORDESTE SL', 'B11223344', '937333333', 'gerencia@texnordeste.com', 'C/ ARGENTINA, 55', 'POL. PRAT', 'EL PRAT LLOBREGAT', 'BARCELONA', '08820', '724', 'España', NULL, NULL, 'ALBERT PUIG', '937333334', '937333333', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', '60DIAS', 'VENTAMAYOR', NULL, NULL, '2026-02-17 06:21:32', '2026-01-17 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('314', 'S', 23, 'ELENA VEGA CASTILLO', '12344321K', '666444444', 'elena.vega@gmail.com', 'C/ REAL, 2', '', 'VALLADOLID', 'VALLADOLID', '47001', '724', 'España', NULL, NULL, NULL, NULL, '983445544', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-17 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('315', 'S', 24, 'ANTONIO GUTIÉRREZ REYES', '23455432L', '677555555', 'antonio.gutierrez@hotmail.com', 'C/ CORREDERA, 31', '', 'CÓRDOBA', 'CÓRDOBA', '14001', '724', 'España', NULL, NULL, NULL, NULL, '957556655', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-18 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('316', 'S', 25, 'SOFÍA RAMÍREZ ORTEGA', '34566543M', '688666666', 'sofia.ramirez@gmail.com', 'AVDA. ARAGÓN, 14', '1ºD', 'VALENCIA', 'VALENCIA', '46021', '724', 'España', NULL, NULL, NULL, NULL, '963667766', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'TRANSFERENCIA', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-18 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('317', 'S', 26, 'IMPORTACIONES LA MODA SL', 'B99887766', '916777777', 'admin@importamoda.es', 'C/ ARTESANOS, 20', 'NAVE 3', 'ALCOBENDAS', 'MADRID', '28108', '724', 'España', NULL, NULL, 'JAVIER OLMEDO', '916777778', '916777777', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', '30DIAS', 'VENTAMAYOR', NULL, NULL, '2026-02-17 06:21:32', '2026-01-18 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('318', 'S', 27, 'MARCOS DELGADO SERRANO', '45677654N', '699888888', 'marcos.delgado@empresa.es', 'C/ LARGA, 77', '', 'SALAMANCA', 'SALAMANCA', '37001', '724', 'España', NULL, NULL, NULL, NULL, '923889988', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-18 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('319', 'S', 28, 'LUCÍA FLORES MENDOZA', '56788765O', '611999999', 'lucia.flores@gmail.com', 'PLAZA DEL SOL, 1', '', 'BURGOS', 'BURGOS', '09001', '724', 'España', NULL, NULL, NULL, NULL, '947990099', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', 'PVP', NULL, NULL, '2026-02-17 06:21:32', '2026-01-19 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_clientes` VALUES ('320', 'S', 29, 'TIENDAS MODA SPAIN SL', 'B55443322', '911000000', 'compras@modaspain.es', 'GRAN VÍA, 48', '', 'MADRID', 'MADRID', '28013', '724', 'España', NULL, NULL, 'BEATRIZ MORENO', '911000001', '911000000', NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', '60DIAS', 'VENTAMAYOR', NULL, NULL, '2026-02-26 19:56:12', '2026-01-19 09:00:00', 'DEMO', 'Administrador');
INSERT INTO `fza_clientes` VALUES ('321', 'S', NULL, 'añlsdfkjañlsdkfj', '337373837', '23923923932', '', 'alsdkjfalsdkjf', 'asldkjadslkfj', 'alskdfjadsklñjf', 'alsdkfjasdkñlfj', '21323', '', '', NULL, NULL, NULL, NULL, NULL, NULL, 'N', 'S', NULL, NULL, NULL, 'N', 'N', 'N', NULL, 'VENTAMAYOR', NULL, NULL, '2026-02-26 19:58:55', '2026-02-26 19:58:55', 'Administrador', 'Administrador');
INSERT INTO `fza_clientes` VALUES ('PUBLICO', 'S', 2, 'PUBLICO', 'NIF CLIENTE', 'TFNO CLIENTE', 'EMAIL DEL CLIENTE', 'DIRECCION DEL CLIENTE', '', 'POBLACION AGRICULTOR', 'PROVINCIA CLIENTE', 'POSCLI', NULL, 'PAIS DEL CLIENTE', NULL, NULL, NULL, NULL, NULL, 'ES2101822356985665446552', 'N', 'N', NULL, NULL, NULL, 'N', 'N', 'N', 'CONTADO', '0', NULL, NULL, '2023-12-24 14:10:14', '2022-11-02 20:28:28', 'Administrador', 'Administrador');
INSERT INTO `fza_clientes` VALUES ('TIENDA', 'S', 1, 'TIENDA DE ROSA', 'NIF', '658963325', 'EMAIL', 'CALLE MAYOR, 2', '', 'MORALES DEL VINO', 'ZAMORA', '49190', 'ES', 'España', '', NULL, NULL, NULL, NULL, NULL, 'S', 'S', NULL, NULL, NULL, 'N', 'N', 'N', 'TRANSFERENCIA', 'VENTAMAYOR', '', '', '2026-02-01 14:09:13', '2022-11-02 16:13:41', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_codigos_barras
-- ----------------------------
DROP TABLE IF EXISTS `fza_codigos_barras`;
CREATE TABLE `fza_codigos_barras`  (
  `CODIGO_BARRAS_CB` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_UNIDAD_CB` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TIPO_CODIGO_CB` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'EAN13',
  `ESPRINCIPAL_CB` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_BARRAS_CB`) USING BTREE,
  INDEX `IDX_UNIDAD_CB`(`CODIGO_UNIDAD_CB` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_codigos_barras
-- ----------------------------
INSERT INTO `fza_codigos_barras` VALUES ('8410000000100', 'ZAP-OXFORD/NEGRO/42', 'EAN13', 'S', '2026-01-08 20:30:32', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_codigos_barras` VALUES ('8410000000101', 'ZAP-OXFORD/MARRON/43', 'EAN13', 'S', '2026-01-08 20:30:41', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_codigos_barras` VALUES ('8410000000200', 'ZAP-TACÓN/ROJO/37', 'EAN13', 'S', '2026-01-08 20:31:00', '2026-01-04 22:06:12', 'DEMO', 'DEMO');
INSERT INTO `fza_codigos_barras` VALUES ('8410000000201', 'ZAP-TACÓN/38/NEGRO', 'EAN13', 'S', '2026-01-04 22:06:12', '2026-01-04 22:06:12', 'DEMO', 'DEMO');

-- ----------------------------
-- Table structure for fza_config_campos
-- ----------------------------
DROP TABLE IF EXISTS `fza_config_campos`;
CREATE TABLE `fza_config_campos`  (
  `TABLA_OBJETIVO_CC` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CAMPO_OBJETIVO_CC` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TITULO_VISUAL_CC` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'El texto bonito para el usuario',
  `ANCHO_COLUMNA_CC` int(11) NULL DEFAULT 100 COMMENT 'Ancho en píxeles',
  `ORDEN_VISUAL_CC` int(11) NULL DEFAULT 0 COMMENT 'Para ordenar columnas si quisieras',
  `VISIBLE_CC` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  PRIMARY KEY (`TABLA_OBJETIVO_CC`, `CAMPO_OBJETIVO_CC`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_config_campos
-- ----------------------------
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'ACTIVO_ARTICULO', 'Activo', 50, 3, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'CODIGO_ARTICULO', 'Código', 100, 1, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'DESCRIPCION_ARTICULO', 'Descripción del Artículo', 350, 2, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'ESVARIACION_ARTICULO', 'Tiene Tallas/Col', 90, 6, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'TIENE_TRAZABILIDAD', 'Trazabilidad', 80, 7, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'TIPO_ARTICULO', 'Tipo', 100, 8, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'TIPO_CANTIDAD_ARTICULO', 'Unidad Medida', 80, 5, 'S');
INSERT INTO `fza_config_campos` VALUES ('fza_articulos', 'TIPOIVA_ARTICULO', '% IVA', 60, 4, 'S');

-- ----------------------------
-- Table structure for fza_contadores
-- ----------------------------
DROP TABLE IF EXISTS `fza_contadores`;
CREATE TABLE `fza_contadores`  (
  `TIPODOC_CONTADOR` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `EMPRESA_CONTADOR` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SERIE_CONTADOR` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CONTADOR_CONTADOR` bigint(20) NOT NULL,
  `NUMDIGIT_CONTADOR` int(11) NOT NULL DEFAULT 0,
  `ACTIVO_CONTADOR` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'S',
  `DEFAULT_CONTADOR` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`TIPODOC_CONTADOR`, `SERIE_CONTADOR`, `EMPRESA_CONTADOR`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_contadores
-- ----------------------------
INSERT INTO `fza_contadores` VALUES ('AO', '-', '-', 38, 3, 'S', 'S', '2025-04-18 12:05:44', '2023-05-25 12:59:19', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('AR', '-', '-', 17, 3, 'S', 'S', '2026-01-21 17:22:15', '2023-05-25 12:51:52', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('CL', '-', '-', 322, 3, 'S', 'S', '2026-02-26 19:58:55', '0000-00-00 00:00:00', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('CO', '-', '-', 6, 3, 'S', 'S', '2023-06-30 12:49:26', '2023-05-15 12:54:31', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('EM', '-', '-', 13, 3, 'S', 'S', '2024-02-12 09:38:07', '0000-00-00 00:00:00', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('EO', '-', '-', 6, 3, 'S', 'S', '2023-12-06 12:59:23', '2023-05-19 15:02:02', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('ES', '-', '-', 12, 3, 'S', 'S', '2026-03-05 06:37:18', '2023-05-13 12:25:25', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FA', '-', '-', 4, 3, 'S', 'S', '2024-10-06 20:30:10', '2023-06-02 13:04:22', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '012', '2026.A1', 6, 6, 'S', 'N', '2026-02-26 19:59:49', '2026-02-01 07:03:46', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '1', 'A1', 35, 8, 'S', 'N', '2026-02-17 06:21:32', '2022-09-13 15:47:45', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '011', 'A1.2023', 6, 6, 'S', 'N', '2025-09-07 17:01:07', '2023-12-06 13:07:54', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '011', 'A1/1T/2024', 2, 6, 'S', 'N', '2025-09-07 17:01:09', '2024-02-12 09:40:18', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '1', 'A3', 0, 8, 'S', 'N', '2025-09-07 17:01:11', '2023-05-12 12:24:25', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '1', 'AGRO', 8, 6, 'S', 'N', '2025-09-07 17:01:12', '2023-06-01 13:45:24', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '1', 'AGRO/2023', 2, 6, 'S', 'N', '2025-09-07 17:01:14', '2023-12-06 13:26:05', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '008', 'ANA/2023', 5, 6, 'S', 'N', '2025-09-07 17:01:16', '2023-10-31 18:12:26', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '1', 'ATIE', 2, 6, 'S', 'N', '2025-09-07 17:01:18', '2023-05-17 14:12:45', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FC', '1', 'TICKA1', 0, 4, 'S', 'S', '2025-09-07 17:00:51', '2025-09-07 17:00:40', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('FO', '-', '-', 7, 3, 'S', 'S', '2025-04-17 09:34:57', '2023-07-07 13:54:00', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('GO', '-', '-', 5, 3, 'S', 'S', '2023-12-08 22:33:27', '2023-11-08 21:12:56', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('GP', '-', '-', 12, 3, 'S', 'S', '2023-10-28 13:39:47', '2023-04-27 12:30:24', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('IG', '-', '-', 4, 3, 'S', 'S', '2023-11-17 12:36:00', '2023-01-19 10:41:29', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('IV', '-', '-', 18, 3, 'S', 'S', '2023-11-17 12:36:55', '2021-06-10 20:11:25', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('PD', '1', 'PED', 3, 3, 'S', 'S', '2026-02-17 06:21:32', '2026-02-12 10:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_contadores` VALUES ('PG', '-', '-', 3, 3, 'S', 'S', '2023-12-06 18:58:55', '2023-11-08 21:12:56', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('PV', '-', '-', 25, 3, 'S', 'S', '2023-06-30 12:49:26', '2021-06-10 18:47:22', 'Administrador', 'Administrador');
INSERT INTO `fza_contadores` VALUES ('RT', '-', '-', 6, 3, 'S', 'S', '2026-02-01 07:20:07', '2023-10-26 16:34:31', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_depositos_cliente
-- ----------------------------
DROP TABLE IF EXISTS `fza_depositos_cliente`;
CREATE TABLE `fza_depositos_cliente`  (
  `ID_DEPOSITO_DEP` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_EMPRESA_DEP` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_CLIENTE_DEP` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ARTICULO_DEP` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_UNIDAD_DEP` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'SKU o Código de Barras único de la talla/color',
  `PRECIO_VENTA_DEP` decimal(19, 6) NOT NULL DEFAULT 0.000000 COMMENT 'Precio Unidad original de la venta',
  `IMPORTE_ANTICIPO_DEP` decimal(19, 6) NOT NULL DEFAULT 0.000000 COMMENT 'Dinero acumulado entregado a cuenta hasta la fecha',
  `ESTADO_DEP` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'PENDIENTE' COMMENT 'Valores: PENDIENTE, CERRADO',
  `FECHA_CREACION_DEP` datetime NOT NULL DEFAULT current_timestamp(),
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TIPO_IVA_DEP` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'N',
  `PORCEN_IVA_DEP` decimal(19, 6) NOT NULL DEFAULT 0.000000,
  `ESIMP_INCL_DEP` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'S',
  `CANTIDAD_PENDIENTE_DEP` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Cantidad de artículos comprados',
  `FECHA_ENTREGA_DEP` date NULL DEFAULT NULL,
  PRIMARY KEY (`ID_DEPOSITO_DEP`) USING BTREE,
  INDEX `IDX_DEP_CLIENTE`(`CODIGO_CLIENTE_DEP` ASC, `ESTADO_DEP` ASC) USING BTREE,
  INDEX `IDX_DEP_UNIDAD`(`CODIGO_UNIDAD_DEP` ASC, `ESTADO_DEP` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_depositos_cliente
-- ----------------------------
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-001', '1', '301', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/NEGRO/L', 189.000000, 94.500000, 'PENDIENTE', '2026-02-10 10:30:00', '2026-03-03 17:55:37', '2026-02-10 10:30:00', 'LAURA', 'LAURA', 'N', 21.000000, 'S', 1.000000, '2026-03-15');
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-002', '1', '302', 'CHAQ-CUERO', 'CHAQ-CUERO/NEGRO/XL', 299.000000, 0.000000, 'PENDIENTE', '2026-02-14 16:00:00', '2026-03-03 17:55:37', '2026-02-14 16:00:00', 'CARLOS', 'CARLOS', 'N', 21.000000, 'S', 1.000000, '2026-03-20');
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-003', '1', '303', 'BOTIN-ANIT', 'BOTIN-ANIT/NEGRO/38', 125.000000, 37.500000, 'PENDIENTE', '2026-02-18 11:15:00', '2026-03-03 17:55:37', '2026-02-18 11:15:00', 'ANA', 'ANA', 'N', 21.000000, 'S', 1.000000, '2026-03-10');
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-004', '1', '301', 'JERSEY-LANA', 'JERSEY-LANA/BEIGE/M', 79.000000, 79.000000, 'CERRADO', '2026-01-20 09:00:00', '2026-03-03 17:55:37', '2026-01-20 09:00:00', 'LAURA', 'LAURA', 'N', 21.000000, 'S', 1.000000, NULL);
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-005', '1', '302', 'ZAP-OXFORD', 'ZAP-OXFORD/NEGRO/42', 159.000000, 39.750000, 'PENDIENTE', '2026-02-20 17:30:00', '2026-03-03 17:55:37', '2026-02-20 17:30:00', 'CARLOS', 'CARLOS', 'N', 21.000000, 'S', 1.000000, '2026-04-01');
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-006', '1', '303', 'BLUS-SEDA', 'BLUS-SEDA/BLANCO/M', 95.000000, 20.000000, 'CANCELADO', '2026-01-28 12:00:00', '2026-03-03 17:55:37', '2026-01-28 12:00:00', 'ANA', 'ANA', 'N', 21.000000, 'S', 1.000000, NULL);
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-007', '1', '301', 'VEST-FLOR', 'VEST-FLOR/AZUL/L', 115.000000, 0.000000, 'PENDIENTE', '2026-03-01 10:00:00', '2026-03-03 17:55:37', '2026-03-01 10:00:00', 'LAURA', 'LAURA', 'N', 21.000000, 'S', 1.000000, '2026-03-25');
INSERT INTO `fza_depositos_cliente` VALUES ('DEP-008', '1', '302', 'CAMI-POLO', 'CAMI-POLO/AZUL/L', 49.000000, 49.000000, 'CERRADO', '2026-02-05 15:00:00', '2026-03-03 17:55:37', '2026-02-05 15:00:00', 'CARLOS', 'CARLOS', 'N', 21.000000, 'S', 1.000000, NULL);

-- ----------------------------
-- Table structure for fza_empresas
-- ----------------------------
DROP TABLE IF EXISTS `fza_empresas`;
CREATE TABLE `fza_empresas`  (
  `CODIGO_EMPRESA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ORDEN_EMPRESA` int(11) NULL DEFAULT NULL,
  `ACTIVO_EMPRESA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `RAZONSOCIAL_EMPRESA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NIF_EMPRESA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_EMPRESA` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_EMPRESA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_EMPRESA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_EMPRESA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_EMPRESA` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_EMPRESA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_EMPRESA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_EMPRESA` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'ES',
  `NOMBRE_PAIS_EMPRESA` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `SERIE_CONTADOR_EMPRESA` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IBAN_EMPRESA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `GRUPO_ZONA_IVA_EMPRESA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESRETENCIONES_EMPRESA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ESREGIMENESPECIALAGRICOLA_EMPRESA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `CODIGO_CERTIFICADO_EMPRESA` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TITULAR_CERTIFICADO_EMPRESA` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TIPO_CERTIFICADO_EMPRESA` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_DESDE_CERTIFICADO_EMPRESA` datetime NULL DEFAULT NULL,
  `FECHA_HASTA_CERTIFICADO_EMPRESA` datetime NULL DEFAULT NULL,
  `TEXTO_LEGAL_FACTURA_EMPRESA` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_EMPRESA`) USING BTREE,
  INDEX `IDX_EMPRESAS_ESTADO`(`ACTIVO_EMPRESA` ASC, `CODIGO_EMPRESA` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_empresas
-- ----------------------------
INSERT INTO `fza_empresas` VALUES ('012', NULL, 'S', 'ALEJANDRO LAORDEN HIDALGO', '4587545EQ', '65869556', 'miemail@gmail.com', 'CALLE POZO BLANCO, 2', '', '49750', 'SANTOVENIA', 'ZAMORA', 'ES', 'España', NULL, NULL, '1', 'S', 'N', NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-23 22:47:42', '2024-10-01 18:39:25', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas` VALUES ('1', 1, 'S', 'AGRICULTOR', 'NIF DEL AGRICULTOR', 'TFNO DEL AGRICULTOR', 'EMAIL DEL AGRICULTOR', 'DIRECCION DEL AGRICULTOR', '', 'POSAGRI', 'POBLACION DEL AGRICULTOR', 'PROVINCIA DEL AGRICULTOR', 'ES', 'España', NULL, 'ES5001825695365423253', '2', 'S', 'S', NULL, NULL, NULL, NULL, NULL, 'Empresario emisor acogido al régimen especial de agricultura ganadería y pesca', '2023-12-09 18:37:41', '2021-05-14 20:07:06', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas` VALUES ('MODAEJ', NULL, 'S', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', '28020', 'MADRID', 'MADRID', '724', 'España', NULL, NULL, '1', 'S', 'N', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 06:32:36', '2026-03-05 06:32:36', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_empresas_retenciones
-- ----------------------------
DROP TABLE IF EXISTS `fza_empresas_retenciones`;
CREATE TABLE `fza_empresas_retenciones`  (
  `CODIGO_RETENCION` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_EMPRESA_RETENCION` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `PORCENRETENCION_RETENCION` decimal(18, 6) NULL DEFAULT NULL,
  `FECHA_DESDE_RETENCION` date NULL DEFAULT NULL,
  `FECHA_HASTA_RETENCION` date NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_RETENCION`) USING BTREE,
  INDEX `IDX_RETENCIONES_CALCULO`(`CODIGO_EMPRESA_RETENCION` ASC, `FECHA_DESDE_RETENCION` ASC, `FECHA_HASTA_RETENCION` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_empresas_retenciones
-- ----------------------------
INSERT INTO `fza_empresas_retenciones` VALUES ('003', '011', 2.500000, '2023-12-06', '2024-12-06', '2023-12-06 12:59:43', '2023-12-06 12:59:43', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_retenciones` VALUES ('004', '011', 15.000000, '2024-12-07', NULL, '2023-12-06 12:59:57', '2023-12-06 12:59:57', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_retenciones` VALUES ('005', '012', 15.000000, '2026-01-01', NULL, '2026-02-01 07:20:07', '2026-02-01 07:20:07', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_retenciones` VALUES ('10', '1', 1.000000, '1999-12-31', '2023-10-01', '2023-10-31 18:20:15', '2023-01-29 10:31:19', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_retenciones` VALUES ('11', '007', 18.000000, '2022-12-01', NULL, '2023-02-01 09:53:16', '2023-02-01 09:53:16', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_retenciones` VALUES ('2', '1', 2.500000, '2023-10-01', NULL, '2022-10-17 16:19:29', '2021-05-14 19:57:40', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_empresas_series
-- ----------------------------
DROP TABLE IF EXISTS `fza_empresas_series`;
CREATE TABLE `fza_empresas_series`  (
  `CODIGO_SERIE` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_EMPRESA_SERIE` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ALMACEN_SERIE` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CAJA_SERIE` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SERIE_SERIE` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TIPODOC_SERIE` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SUBTIPO_SERIE` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_DESDE_SERIE` date NULL DEFAULT NULL,
  `FECHA_HASTA_SERIE` date NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_SERIE`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_empresas_series
-- ----------------------------
INSERT INTO `fza_empresas_series` VALUES ('003', '007', NULL, NULL, 'A7/2023', NULL, NULL, '2023-05-01', '2023-05-31', '2023-05-15 12:36:23', '2023-05-13 12:44:21', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('004', '1', NULL, NULL, 'AGRO/2023', NULL, NULL, '2023-01-01', NULL, '2023-06-01 13:44:51', '2023-06-01 13:44:51', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('005', '011', NULL, NULL, 'A1.2023', NULL, NULL, '2023-12-06', '2023-12-31', '2023-12-06 13:00:47', '2023-12-06 13:00:47', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('006', '011', NULL, NULL, 'A1/1T/2024', NULL, NULL, '2024-01-01', '2024-03-31', '2023-12-06 13:01:26', '2023-12-06 13:01:26', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('007', '011', NULL, NULL, 'A1/2T/2024', NULL, NULL, '2024-04-01', '2024-06-30', '2023-12-06 13:56:28', '2023-12-06 13:56:28', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('008', '011', NULL, NULL, 'A1/3T/2024', NULL, NULL, '2024-07-01', '2024-09-30', '2023-12-06 14:08:33', '2023-12-06 14:08:33', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('009', '012', 'GEN', '1', '2026.A1', 'FC', 'SIMPLIFICADA', '2026-01-01', '2026-12-31', '2026-01-29 05:31:11', '2026-01-29 05:24:21', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('010', '012', 'GEN', '1', 'OV', 'OV', NULL, '2026-01-01', NULL, '2026-03-04 16:20:33', '2026-03-04 16:20:33', 'Administrador', 'Administrador');
INSERT INTO `fza_empresas_series` VALUES ('011', 'MODAEJ', NULL, NULL, 'AM1', 'FC', 'NORMAL', '2026-01-01', NULL, '2026-03-05 06:37:18', '2026-03-05 06:37:18', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_facturas
-- ----------------------------
DROP TABLE IF EXISTS `fza_facturas`;
CREATE TABLE `fza_facturas`  (
  `NRO_FACTURA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Número de documento',
  `SERIE_FACTURA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Serie de documento',
  `FECHA_FACTURA` date NULL DEFAULT NULL COMMENT 'Fecha oficial del documento',
  `ESCONSOLIDADA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si la factura se ha emitido',
  `INSTANTECONSO_FACTURA` datetime NULL DEFAULT NULL COMMENT 'Fecha y Hora de la consolidación',
  `TIPO_FACTURA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'NORMAL' COMMENT 'NORMAL, SIMPLIFICADA, RECTIFICATIVA',
  `FASE_FACTURA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'BORRADOR, ONLINE, OFFLINE, ERROR, ERROR_BORRADOR, VERIFICADA, CANCELADA',
  `CODIGO_EMPRESA_FACTURA` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código de empresa del emisor del documento',
  `RAZONSOCIAL_EMPRESA_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NIF_EMPRESA_FACTURA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_EMPRESA_FACTURA` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_EMPRESA_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_EMPRESA_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_EMPRESA_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_EMPRESA_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_EMPRESA_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_EMPRESA_FACTURA` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_EMPRESA_FACTURA` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `CPOSTAL_EMPRESA_FACTURA` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESRETENCIONES_EMPRESA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'S o N si la empresa aplica retenciones como autónomos',
  `GRUPO_ZONA_IVA_EMPRESA_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `CODIGO_CLIENTE_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `RAZONSOCIAL_CLIENTE_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NIF_CLIENTE_FACTURA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_CLIENTE_FACTURA` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_CLIENTE_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_CLIENTE_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_CLIENTE_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_CLIENTE_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_CLIENTE_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_CLIENTE_FACTURA` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_CLIENTE_FACTURA` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_CLIENTE_FACTURA` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `CODIGO_IVA_FACTURA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código de IVA de la tabla fza_ivas',
  `ESIVA_RECARGO_CLIENTE_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'S o N si el cliente tiene RE',
  `ESIVA_EXENTO_CLIENTE_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'S o N si el cliente tiene IVA EXENTO',
  `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'S o N si el cliente tiene REAGP',
  `ESRETENCIONES_CLIENTE_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'S o N Si el cliente aplica retenciones',
  `TARIFA_ARTICULO_CLIENTE_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código de la tarifa que viene del cliente o configurada por el usuario',
  `ESIMP_INCL_TARIFA_CLIENTE_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'Si el precio de la tarifa del cliente es con impuestos incl o no',
  `ESINTRACOMUNITARIO_CLIENTE_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si la venta es hacia un país de la UE',
  `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si la base del cáculo del irpf se hace desde BI o BI con impuestos',
  `ESAPLICA_RE_ZONA_IVA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'Si el tipo de IVA aplica Recargo de Equivalencia o no',
  `ESIVAAGRICOLA_ZONA_IVA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si el tipo de IVA es compatible con REAGP',
  `PALABRA_REPORTS_ZONA_IVA_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'IVA' COMMENT 'Palabra que sustituye a IVA desde la tabla de fza_ivas_grupos',
  `ESVENTA_ACTIVO_FIJO_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Sólo REAGP cuando se vende activos fijos, exime irpf',
  `PORCEN_IVAN_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Normal',
  `TOTAL_IVAN_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total IVA Normal',
  `PORCEN_REN_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Normal',
  `TOTAL_REN_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE Normal',
  `TOTAL_BASEI_IVAN_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Normal',
  `PORCEN_IVAR_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Reducido',
  `TOTAL_IVAR_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'TotaL IVA Reducido',
  `PORCEN_RER_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Reducido',
  `TOTAL_RER_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE Reducido',
  `TOTAL_BASEI_IVAR_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Reducido',
  `PORCEN_IVAS_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido',
  `TOTAL_IVAS_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total IVA SuperReducido',
  `PORCEN_RES_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido',
  `TOTAL_RES_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE SuperReducido',
  `TOTAL_BASEI_IVAS_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total sin IVA SuperReducido',
  `PORCEN_IVAE_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Exento',
  `TOTAL_IVAE_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total IVA Exento',
  `PORCEN_REE_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA1 Exento',
  `TOTAL_REE_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE Exento',
  `TOTAL_BASEI_IVAE_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total sin IVA Exento',
  `TOTAL_BASES_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Todas las bases imponibles',
  `TOTAL_IMPUESTOS_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total de todos los impuestos iva + re',
  `FORMA_PAGO_FACTURA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Codigo Forma de Pago',
  `PORCEN_RETENCION_FACTURA` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje Retenciones',
  `TOTAL_RETENCION_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Retenciones Factura',
  `TOTAL_LIQUIDO_FACTURA` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Factura a pagar en el acto de emisión',
  `NRO_FACTURA_ABONO_FACTURA` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Nro Factura Abono',
  `SERIE_FACTURA_ABONO_FACTURA` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Serie Factura Abono',
  `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '' COMMENT 'Texto legal desde el cliente',
  `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '' COMMENT 'Texto legal desde la empresa',
  `DOCUMENTO_FACTURA` blob NULL DEFAULT NULL COMMENT 'Documento Factura (en desuso)',
  `COMENTARIOS_FACTURA` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '',
  `CONTADOR_LINEAS_FACTURA` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Contador de lineas para lineas de factura',
  `ESCREARARTICULOS_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'S o N si se crean articulos desde el detalle',
  `ESDESCRIPCIONES_AMP_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'S o N si la factura contiene una descripción larga',
  `ESFECHADEENTREGA_FACTURA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'S o N si las descripciones tienen fecha de entrega',
  `XML_FACTURA` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'xml de la factura electrónica firmado',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_CAJERO_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Usuario que cerró el ticket (fza_usuarios)',
  `CODIGO_ALMACEN_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CAJA_FACTURA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NUMERO_OPERACION_FACTURA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`SERIE_FACTURA`, `NRO_FACTURA`) USING BTREE,
  INDEX `IDX_FACTURAS_CLIENTE_FECHA`(`CODIGO_CLIENTE_FACTURA` ASC, `FECHA_FACTURA` ASC) USING BTREE,
  INDEX `IDX_FACTURAS_EMPRESA`(`CODIGO_EMPRESA_FACTURA` ASC) USING BTREE,
  INDEX `IDX_FACTURAS_FECHA`(`FECHA_FACTURA` ASC) USING BTREE,
  INDEX `IDX_FACTURAS_CLI_EMP`(`CODIGO_CLIENTE_FACTURA` ASC, `CODIGO_EMPRESA_FACTURA` ASC) USING BTREE,
  INDEX `IDX_FACTURAS_SERIE`(`SERIE_FACTURA` ASC, `NRO_FACTURA` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_facturas
-- ----------------------------
INSERT INTO `fza_facturas` VALUES ('000002', '2026.A1', '2026-02-01', 'N', NULL, 'NORMAL', 'BORRADOR', '012', 'ALEJANDRO LAORDEN HIDALGO', '4587545EQ', '65869556', 'miemail@gmail.com', 'CALLE POZO BLANCO, 2', '', 'SANTOVENIA', 'ZAMORA', 'ES', 'FRANCIA', '49750', 'S', '1', 'N', 'TIENDA', 'TIENDA DE ROSA', 'NIF', '658963325', 'EMAIL', 'CALLE MAYOR, 2', '', 'MORALES DEL VINO', 'ZAMORA', '49190', 'ES', 'España', '1', 'S', 'N', 'N', 'S', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 9.450000, 5.200000, 2.340000, 45.000000, 10.000000, 0.000000, 1.400000, 0.000000, 0.000000, 4.000000, 0.000000, 0.500000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 45.000000, 11.790000, 'CONTADO', 15.000000, 6.750000, 50.040000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'N', 'N', NULL, '2026-02-09 08:48:59', '2026-02-01 14:09:49', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas` VALUES ('000003', '2026.A1', '2026-02-01', 'S', '2026-02-23 06:23:26', 'NORMAL', 'BORRADOR', '012', 'ALEJANDRO LAORDEN HIDALGO', '4587545EQ', '65869556', 'miemail@gmail.com', 'CALLE POZO BLANCO, 2', '', 'SANTOVENIA', 'ZAMORA', 'ES', 'España', '49750', 'S', '1', 'N', 'TIENDA', 'TIENDA DE ROSA', 'NIF', '658963325', 'EMAIL', 'CALLE MAYOR, 2', '', 'MORALES DEL VINO', 'ZAMORA', '49190', 'ES', 'España', '1', 'S', 'N', 'N', 'S', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 37.800000, 5.200000, 9.360000, 180.000000, 10.000000, 0.000000, 1.400000, 0.000000, 0.000000, 4.000000, 0.000000, 0.500000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 180.000000, 47.160000, 'TRANSFERENCIA', 15.000000, 27.000000, 200.160000, NULL, NULL, NULL, '', NULL, NULL, '020', 'N', 'N', 'N', NULL, '2026-02-09 08:49:01', '2026-02-01 14:36:26', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas` VALUES ('000004', '2026.A1', '2026-02-26', 'N', NULL, 'NORMAL', 'BORRADOR', '012', 'ALEJANDRO LAORDEN HIDALGO', '4587545EQ', '65869556', 'miemail@gmail.com', 'CALLE POZO BLANCO, 2', '', 'SANTOVENIA', 'ZAMORA', 'ES', 'España', '49750', 'S', '1', 'N', '320', 'TIENDAS MODA SPAIN SL', 'B55443322', '911000000', 'compras@modaspain.es', 'GRAN VÍA, 48', '', 'MADRID', 'MADRID', '28013', '724', 'España', '1', 'S', 'N', 'N', 'S', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 16.380000, 5.200000, 4.056000, 78.000000, 10.000000, 0.000000, 1.400000, 0.000000, 0.000000, 4.000000, 0.000000, 0.500000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 78.000000, 20.436000, '60DIAS', 15.000000, 11.700000, 86.736000, NULL, NULL, NULL, '', NULL, NULL, '0', 'N', 'N', 'N', NULL, '2026-02-26 19:56:28', '2026-02-26 19:56:20', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas` VALUES ('000005', '2026.A1', '2026-02-26', 'N', NULL, 'NORMAL', 'BORRADOR', '012', 'ALEJANDRO LAORDEN HIDALGO', '4587545EQ', '65869556', 'miemail@gmail.com', 'CALLE POZO BLANCO, 2', '', 'SANTOVENIA', 'ZAMORA', 'ES', 'España', '49750', 'S', '1', 'N', '321', 'añlsdfkjañlsdkfj', '337373837', '23923923932', NULL, 'alsdkjfalsdkjf', 'asldkjadslkfj', 'alskdfjadsklñjf', 'alsdkfjasdkñlfj', '21323', 'ES', NULL, '1', 'N', 'N', 'N', 'N', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 29.820000, 5.200000, 0.000000, 142.000000, 10.000000, 0.000000, 1.400000, 0.000000, 0.000000, 4.000000, 0.000000, 0.500000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 142.000000, 29.820000, 'CONTADO', 15.000000, 0.000000, 171.820000, NULL, NULL, NULL, '', NULL, NULL, '020', 'N', 'N', 'N', NULL, '2026-02-26 20:32:10', '2026-02-26 19:59:49', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas` VALUES ('000026', 'A1', '2026-01-20', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '301', 'LAURA FERNÁNDEZ GIL', '12345678A', '655101010', 'laura.fernandez@gmail.com', 'CALLE MAYOR, 15', '', 'MADRID', 'MADRID', '28001', '724', 'España', '1', 'N', 'N', 'N', 'S', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 11.340000, 5.200000, 0.000000, 54.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 54.000000, 11.340000, 'CONTADO', 15.000000, 8.100000, 57.240000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-20 10:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000027', 'A1', '2026-01-21', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '302', 'CARLOS HERRERO SANTOS', '23456789B', '666202020', 'carlos.herrero@hotmail.com', 'AVDA. LIBERTAD, 22', '2º A', 'BARCELONA', 'BARCELONA', '08001', '724', 'España', '1', 'N', 'N', 'N', 'S', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 25.200000, 5.200000, 0.000000, 120.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 120.000000, 25.200000, 'CONTADO', 0.000000, 0.000000, 145.200000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000028', 'A1', '2026-01-23', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '306', 'DISTRIBUCIONES VELÁZQUEZ SL', 'B12345678', '968606060', 'pedidos@distribuvelaz.es', 'POLÍGONO EL PINO, 5', 'NAVE 12', 'MURCIA', 'MURCIA', '30001', '724', 'España', '1', 'N', 'N', 'N', 'S', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 126.000000, 5.200000, 0.000000, 600.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 600.000000, 126.000000, '30DIAS', 0.000000, 0.000000, 726.000000, NULL, NULL, NULL, 'Pedido PO-2026-0123', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000029', 'A1', '2026-01-25', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '305', 'ANA GARCÍA MORENO', '56789012E', '699505050', 'ana.garcia@yahoo.es', 'PLAZA ESPAÑA, 3', '1º B', 'SEVILLA', 'SEVILLA', '41001', '724', 'España', '1', 'N', 'N', 'N', 'S', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 9.492000, 5.200000, 0.000000, 45.200000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 45.200000, 9.492000, 'CONTADO', 0.000000, 0.000000, 54.692000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-25 12:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000030', 'A1', '2026-01-28', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '310', 'MODA FÁCIL SL', 'B87654321', '944010101', 'compras@modafacil.com', 'C/ INDUSTRIA, 33', 'POL. NORTE', 'BILBAO', 'VIZCAYA', '48008', '724', 'España', '1', 'N', 'N', 'N', 'S', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 201.600000, 5.200000, 0.000000, 960.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 960.000000, 201.600000, '30DIAS', 0.000000, 0.000000, 1161.600000, NULL, NULL, NULL, 'Ref. pedido MF-2026-008', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000031', 'A1', '2026-02-03', 'N', NULL, 'SIMPLIFICADA', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', 'PUBLICO', 'PUBLICO', 'NIF CLIENTE', '', '', '', '', '', '', '', '724', 'España', '1', 'N', 'N', 'N', 'N', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 7.602000, 5.200000, 0.000000, 36.200000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 36.200000, 7.602000, 'CONTADO', 0.000000, 0.000000, 43.802000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-02-03 11:30:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', '001');
INSERT INTO `fza_facturas` VALUES ('000032', 'A1', '2026-02-05', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '318', 'MARCOS DELGADO SERRANO', '45677654N', '699888888', 'marcos.delgado@empresa.es', 'C/ LARGA, 77', '', 'SALAMANCA', 'SALAMANCA', '37001', '724', 'España', '1', 'N', 'N', 'N', 'S', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 23.205000, 5.200000, 0.000000, 110.500000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 110.500000, 23.205000, 'CONTADO', 0.000000, 0.000000, 133.705000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-02-05 16:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000033', 'A1', '2026-02-07', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '319', 'LUCÍA FLORES MENDOZA', '56788765O', '611999999', 'lucia.flores@gmail.com', 'PLAZA DEL SOL, 1', '', 'BURGOS', 'BURGOS', '09001', '724', 'España', '1', 'N', 'N', 'N', 'S', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 12.600000, 5.200000, 0.000000, 60.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 65.950000, 13.849500, 'TRANSFERENCIA', 0.000000, 0.000000, 79.799500, NULL, NULL, NULL, 'Pedido web #W2026-0289', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-02-07 18:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);
INSERT INTO `fza_facturas` VALUES ('000034', 'A1', '2026-02-08', 'N', NULL, 'SIMPLIFICADA', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', 'PUBLICO', 'PUBLICO', 'NIF CLIENTE', '', '', '', '', '', '', '', '724', 'España', '1', 'N', 'N', 'N', 'N', 'PVP', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 14.490000, 5.200000, 0.000000, 69.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 69.000000, 14.490000, 'CONTADO', 0.000000, 0.000000, 83.490000, NULL, NULL, NULL, '', NULL, NULL, NULL, 'N', 'N', 'N', NULL, '2026-02-17 06:21:32', '2026-02-08 10:15:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', '002');
INSERT INTO `fza_facturas` VALUES ('000035', 'A1', '2026-02-10', 'N', NULL, 'NORMAL', 'BORRADOR', '1', 'MODA EJEMPLO SL', 'B11111111', '911000001', 'info@modaejemplo.es', 'AV. EUROPA, 10', '', 'MADRID', 'MADRID', '724', 'España', '28020', 'S', '1', 'N', '313', 'TEXTILES NORDESTE SL', 'B11223344', '937333333', 'gerencia@texnordeste.com', 'C/ ARGENTINA, 55', 'POL. PRAT', 'EL PRAT LLOBREGAT', 'BARCELONA', '08820', '724', 'España', '1', 'N', 'N', 'N', 'S', 'VENTAMAYOR', 'N', 'N', 'N', 'S', 'N', 'IVA', 'N', 21.000000, 100.800000, 5.200000, 0.000000, 480.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 480.000000, 100.800000, '60DIAS', 0.000000, 0.000000, 580.800000, NULL, NULL, NULL, 'Pedido TN-Feb26-001', NULL, NULL, NULL, 'N', 'S', 'N', NULL, '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', NULL, 'GEN', '1', NULL);

-- ----------------------------
-- Table structure for fza_facturas_consolidaciones
-- ----------------------------
DROP TABLE IF EXISTS `fza_facturas_consolidaciones`;
CREATE TABLE `fza_facturas_consolidaciones`  (
  `ID_CONSOLIDACION` int(11) NOT NULL,
  `SERIE_FACTURA_CONSOLIDACION` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NRO_FACTURA_CONSOLIDACION` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `REQUEST_ID_CONSOLIDACION` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'ID único de la petición',
  `QUEUE_ID_CONSOLIDACION` int(11) NULL DEFAULT NULL COMMENT 'ID de cola del sistema',
  `QUEUE_ID_CANCEL_CONSOLIDACION` int(11) NULL DEFAULT NULL COMMENT 'ID de cola del documento cancelado',
  `ISSUER_IRS_ID_CONSOLIDACION` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'NIF del emisor',
  `ISSUED_TIME_CONSOLIDACION` datetime NULL DEFAULT NULL COMMENT 'Fecha y hora de emisión',
  `CHAIN_NUMBER_CONSOLIDACION` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Número de cadena del sistema',
  `CHAIN_HASH_CONSOLIDACION` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Hash de la cadena blockchain',
  `VERIFACTU_URL_CONSOLIDACION` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'URL de verificación en AEAT',
  `QRCODE_BASE64_CONSOLIDACION` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código QR en base64',
  `QRCODE_PNG_CONSOLIDACION` blob NULL DEFAULT NULL COMMENT 'Código QR en PNG',
  `FECHA_PROCESAMIENTO_CONSOLIDACION` datetime NULL DEFAULT current_timestamp() COMMENT 'Fecha de procesamiento',
  `ESTADO_CONSOLIDACION` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'PROCESADO' COMMENT 'Estado del procesamiento',
  `RESPUESTA_COMPLETA_CONSOLIDACION` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'JSON completo de respuesta del webservice',
  `PETICION_COMPLETA_CONSOLIDACION` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'JSON completo de petición del webservice',
  PRIMARY KEY (`ID_CONSOLIDACION`) USING BTREE,
  UNIQUE INDEX `UK_FACTURA`(`SERIE_FACTURA_CONSOLIDACION` ASC, `NRO_FACTURA_CONSOLIDACION` ASC) USING BTREE,
  INDEX `IDX_REQUEST_ID`(`REQUEST_ID_CONSOLIDACION` ASC) USING BTREE,
  INDEX `IDX_FECHA_PROCESAMIENTO_CONSOLIDACION`(`FECHA_PROCESAMIENTO_CONSOLIDACION` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_facturas_consolidaciones
-- ----------------------------

-- ----------------------------
-- Table structure for fza_facturas_lineas
-- ----------------------------
DROP TABLE IF EXISTS `fza_facturas_lineas`;
CREATE TABLE `fza_facturas_lineas`  (
  `NRO_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SERIE_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `LINEA_FACTURA_LINEA` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ARTICULO_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_UNIDAD_FACTURA_LINEA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `LOTE_FACTURA_LINEA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_CADUCIDAD_FACTURA_LINEA` date NULL DEFAULT NULL,
  `CODIGO_FAMILIA_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_FAMILIA_FACTURA_LINEA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PRECIO_ULT_COMPRA_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT NULL,
  `CODIGO_PROVEEDOR_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESPROVEEDORPRINCIPAL_FACTURA_LINEA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_ENTREGA_FACTURA_LINEA` datetime NULL DEFAULT NULL,
  `TIPO_ARTICULO_FACTURA_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'ESTANDAR' COMMENT 'ESTANDAR=Físico (Control Stock), SERVICIO=Intangible (Sin Stock), KIT=Pack',
  `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'Uds',
  `CANTIDAD_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT 1.000000,
  `DESCRIPCION_ARTICULO_FACTURA_LINEA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DESCRIPCION_VARIACION_FACTURA_LINEA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_TARIFA_FACTURA_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESIMP_INCL_TARIFA_FACTURA_LINEA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `PRECIOSALIDA_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT NULL,
  `PORCEN_DTO_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT NULL,
  `PRECIO_DTO_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT NULL,
  `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `TIPOIVA_ARTICULO_FACTURA_LINEA` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `PORCEN_IVA_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `TOTAL_FACTURA_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `TOTAL_FACTURASIVA_LINEA` decimal(19, 6) NULL DEFAULT NULL,
  `CODIGO_VENDEDOR_FACTURA_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Usuario que se lleva la comisión',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ALMACEN_FACTURA_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CAJA_FACTURA_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NUMERO_OPERACION_FACTURA_LIENA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NUMERO_MOV_FACTURA_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`SERIE_FACTURA_LINEA`, `NRO_FACTURA_LINEA`, `LINEA_FACTURA_LINEA`) USING BTREE,
  INDEX `IDX_FAC_LIN_ARTICULO`(`CODIGO_ARTICULO_FACTURA_LINEA` ASC, `SERIE_FACTURA_LINEA` ASC) USING BTREE,
  INDEX `IDX_FAC_LIN_FAMILIA`(`CODIGO_FAMILIA_FACTURA_LINEA` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_facturas_lineas
-- ----------------------------
INSERT INTO `fza_facturas_lineas` VALUES ('000002', '2026.A1', '010', 'PETADA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds.', 1.000000, 'PETADA BILLI', NULL, NULL, 'N', 50.000000, 10.000000, 5.000000, 45.000000, 'N', 21.000000, 54.450000, 54.450000, 45.000000, NULL, '2026-02-01 14:38:48', '2026-02-01 14:38:48', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000003', '2026.A1', '010', 'pato', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds.', 1.000000, 'pato aparato', NULL, NULL, 'N', 5.000000, 0.000000, 0.000000, 5.000000, 'N', 21.000000, 6.050000, 6.050000, 5.000000, NULL, '2026-02-01 14:36:39', '2026-02-01 14:36:39', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000003', '2026.A1', '020', 'ZAP-TACÓN', NULL, NULL, NULL, 'CALZADO', 'Calzado Todo tiempo', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 1.000000, 'Zapato Tacón Alto Señora', NULL, 'VENTAMAYOR', 'N', 42.000000, 0.000000, 0.000000, 42.000000, 'N', 21.000000, 50.820000, 50.820000, 42.000000, NULL, '2026-02-23 06:21:01', '2026-02-23 06:21:01', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000003', '2026.A1', '030', 'BOLSO-PIEL', NULL, NULL, NULL, 'BOLSOS', 'Bolsos, bolsas y mochilas de señora', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 1.000000, 'Bolso de Piel Mujer Grande', NULL, 'VENTAMAYOR', 'N', 55.000000, 0.000000, 0.000000, 55.000000, 'N', 21.000000, 66.550000, 66.550000, 55.000000, NULL, '2026-02-23 06:22:50', '2026-02-23 06:22:50', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000003', '2026.A1', '040', 'CHAQ-CUERO', NULL, NULL, NULL, 'ROPA', 'Ropa de Vestir a la moda', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 1.000000, 'Chaqueta Biker Cuero', NULL, 'VENTAMAYOR', 'N', 78.000000, 0.000000, 0.000000, 78.000000, 'N', 21.000000, 94.380000, 94.380000, 78.000000, NULL, '2026-02-23 06:23:01', '2026-02-23 06:23:01', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000004', '2026.A1', '010', 'CHAQ-CUERO', NULL, NULL, NULL, 'ROPA', 'Ropa de Vestir a la moda', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 1.000000, 'Chaqueta Biker Cuero', NULL, 'VENTAMAYOR', 'N', 78.000000, 0.000000, 0.000000, 78.000000, 'N', 21.000000, 94.380000, 94.380000, 78.000000, NULL, '2026-02-26 19:56:25', '2026-02-26 19:56:25', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000005', '2026.A1', '0', 'BLUS-SEDA', NULL, NULL, NULL, 'ROPA', 'Ropa de Vestir a la moda', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 1.000000, 'Blusa de Seda Cuello V', NULL, 'VENTAMAYOR', 'N', 32.000000, 0.000000, 0.000000, 32.000000, 'N', 21.000000, 38.720000, 38.720000, 32.000000, NULL, '2026-02-26 20:32:10', '2026-02-26 20:32:10', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000005', '2026.A1', '010', 'ZAP-TACÓN', NULL, NULL, NULL, 'CALZADO', 'Calzado Todo tiempo', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 2.000000, 'Zapato Tacón Alto Señor<<a', NULL, 'VENTAMAYOR', 'N', 40.000000, 0.000000, 0.000000, 40.000000, 'N', 21.000000, 48.400000, 96.800000, 80.000000, NULL, '2026-02-26 19:59:49', '2026-02-26 19:59:49', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000005', '2026.A1', '020', 'ZAP-BOTA-MT', NULL, NULL, NULL, 'CALZADO', 'Calzado Todo tiempo', NULL, '', '', '', NULL, 'ESTANDAR', 'Uds', 1.000000, 'Bota Montaña Impermeable', NULL, 'VENTAMAYOR', 'N', 62.000000, 0.000000, 0.000000, 62.000000, 'N', 21.000000, 75.020000, 75.020000, 62.000000, NULL, '2026-02-26 20:11:53', '2026-02-26 20:11:53', 'Administrador', 'Administrador', NULL, NULL, NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000026', 'A1', '010', 'JERSEY-LANA', 'JERSEY-LANA/GRIS/M', NULL, NULL, 'ROPA', 'Ropa de Vestir', 25.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 2.000000, 'Jersey de Lana Cuello Redondo', NULL, 'PVP', 'N', 55.000000, 0.000000, 0.000000, 55.000000, 'N', 21.000000, 66.550000, 133.100000, 110.000000, NULL, '2026-02-17 06:21:32', '2026-01-20 10:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000026', 'A1', '020', 'CINTURON-PIEL', 'CINTURON-PIEL', NULL, NULL, 'COMPLEMENTOS', 'Complementos Accesorios', 9.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 2.000000, 'Cinturón Piel Reversible', NULL, 'PVP', 'N', 22.000000, 10.000000, 2.200000, 19.800000, 'N', 21.000000, 23.958000, 47.916000, 39.600000, NULL, '2026-02-17 06:21:32', '2026-01-20 10:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000027', 'A1', '010', 'ZAP-OXFORD', 'ZAP-OXFORD/NEGRO/42', NULL, NULL, 'CALZADO', 'Calzado Elegante', 40.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Zapato Oxford Piel Hombre', NULL, 'PVP', 'N', 89.900000, 0.000000, 0.000000, 89.900000, 'N', 21.000000, 108.779000, 108.779000, 89.900000, NULL, '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000027', 'A1', '020', 'CINTURON-PIEL', 'CINTURON-PIEL', NULL, NULL, 'COMPLEMENTOS', 'Complementos Accesorios', 9.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Cinturón Piel Reversible', NULL, 'PVP', 'N', 22.000000, 0.000000, 0.000000, 22.000000, 'N', 21.000000, 26.620000, 26.620000, 22.000000, NULL, '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000027', 'A1', '030', 'CARTERA-PIEL', 'CARTERA-PIEL', NULL, NULL, 'COMPLEMENTOS', 'Complementos Accesorios', 20.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Cartera Piel Caballero', NULL, 'PVP', 'N', 50.000000, 0.000000, 0.000000, 50.000000, 'N', 21.000000, 60.500000, 60.500000, 50.000000, NULL, '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000028', 'A1', '010', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/NEGRO/L', NULL, NULL, 'ROPA', 'Ropa de Vestir', 80.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 3.000000, 'Abrigo de Paño Caballero - Negro L', NULL, 'VENTAMAYOR', 'N', 120.000000, 0.000000, 0.000000, 120.000000, 'N', 21.000000, 145.200000, 435.600000, 360.000000, NULL, '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000028', 'A1', '020', 'SUDADERA-HOOD', 'SUDADERA-HOOD/GRIS/M', NULL, NULL, 'DEPORTIVO', 'Ropa Deportiva', 20.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 6.000000, 'Sudadera con Capucha Gris M', NULL, 'VENTAMAYOR', 'N', 28.000000, 0.000000, 0.000000, 28.000000, 'N', 21.000000, 33.880000, 203.280000, 168.000000, NULL, '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000028', 'A1', '030', 'BOLSO-PIEL', 'BOLSO-PIEL', NULL, NULL, 'BOLSOS', 'Bolsos y Mochilas', 45.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Bolso de Piel Mujer Grande', NULL, 'VENTAMAYOR', 'N', 55.000000, 0.000000, 0.000000, 55.000000, 'N', 21.000000, 66.550000, 66.550000, 55.000000, NULL, '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000028', 'A1', '040', 'JERSEY-LANA', 'JERSEY-LANA/BEIGE/M', NULL, NULL, 'ROPA', 'Ropa de Vestir', 25.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 5.000000, 'Jersey de Lana Beige M', NULL, 'VENTAMAYOR', 'N', 35.000000, 0.000000, 0.000000, 35.000000, 'N', 21.000000, 42.350000, 211.750000, 175.000000, NULL, '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000029', 'A1', '010', 'LEGGING-SPORT', 'LEGGING-SPORT/NEGRO/S', NULL, NULL, 'DEPORTIVO', 'Ropa Deportiva', 8.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 2.000000, 'Legging Deportivo Mujer - Negro S', NULL, 'PVP', 'N', 19.950000, 0.000000, 0.000000, 19.950000, 'N', 21.000000, 24.139500, 48.279000, 39.900000, NULL, '2026-02-17 06:21:32', '2026-01-25 12:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000029', 'A1', '020', 'SOMBRERO-PJM', 'SOMBRERO-PJM', NULL, NULL, 'COMPLEMENTOS', 'Complementos Accesorios', 15.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Sombrero Panamá Verano', NULL, 'PVP', 'N', 35.000000, 15.000000, 5.250000, 29.750000, 'N', 21.000000, 35.997500, 35.997500, 29.750000, NULL, '2026-02-17 06:21:32', '2026-01-25 12:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000030', 'A1', '010', 'SUDADERA-HOOD', 'SUDADERA-HOOD/GRIS/S', NULL, NULL, 'DEPORTIVO', 'Ropa Deportiva', 20.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 12.000000, 'Sudadera con Capucha Gris S', NULL, 'VENTAMAYOR', 'N', 28.000000, 0.000000, 0.000000, 28.000000, 'N', 21.000000, 33.880000, 406.560000, 336.000000, NULL, '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000030', 'A1', '020', 'LEGGING-SPORT', 'LEGGING-SPORT/ROSA/S', NULL, NULL, 'DEPORTIVO', 'Ropa Deportiva', 8.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 15.000000, 'Legging Deportivo Mujer - Rosa S', NULL, 'VENTAMAYOR', 'N', 12.000000, 0.000000, 0.000000, 12.000000, 'N', 21.000000, 14.520000, 217.800000, 180.000000, NULL, '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000030', 'A1', '030', 'CAMI-POLO', 'CAMI-POLO/BLANCO/M', NULL, NULL, 'ROPA', 'Ropa de Vestir', 12.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 10.000000, 'Polo Manga Corta - Blanco M', NULL, 'VENTAMAYOR', 'N', 18.000000, 0.000000, 0.000000, 18.000000, 'N', 21.000000, 21.780000, 217.800000, 180.000000, NULL, '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000030', 'A1', '040', 'MOCHILA-SPORT', 'MOCHILA-SPORT', NULL, NULL, 'BOLSOS', 'Bolsos y Mochilas', 18.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 8.000000, 'Mochila Deportiva 30L', NULL, 'VENTAMAYOR', 'N', 24.000000, 0.000000, 0.000000, 24.000000, 'N', 21.000000, 29.040000, 232.320000, 192.000000, NULL, '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000031', 'A1', '010', 'VEST-FLOR', 'VEST-FLOR/AZUL/S', NULL, NULL, 'ROPA', 'Ropa de Vestir', 10.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Vestido Estampado Verano - Azul S', NULL, 'PVP', 'N', 20.000000, 0.000000, 0.000000, 20.000000, 'N', 21.000000, 24.200000, 24.200000, 20.000000, NULL, '2026-02-17 06:21:32', '2026-02-03 11:30:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000031', 'A1', '020', 'CINTURON-PIEL', 'CINTURON-PIEL', NULL, NULL, 'COMPLEMENTOS', 'Complementos Accesorios', 9.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Cinturón Piel Reversible', NULL, 'PVP', 'N', 22.000000, 25.000000, 5.500000, 16.500000, 'N', 21.000000, 19.965000, 19.965000, 16.500000, NULL, '2026-02-17 06:21:32', '2026-02-03 11:30:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000032', 'A1', '010', 'ZAP-BOTA-MT', 'ZAP-BOTA-MT/NEGRO/42', NULL, NULL, 'CALZADO', 'Calzado Elegante', 42.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Bota Montaña Impermeable Negro 42', NULL, 'PVP', 'N', 95.000000, 0.000000, 0.000000, 95.000000, 'N', 21.000000, 114.950000, 114.950000, 95.000000, NULL, '2026-02-17 06:21:32', '2026-02-05 16:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000032', 'A1', '020', 'MOCHILA-SPORT', 'MOCHILA-SPORT', NULL, NULL, 'BOLSOS', 'Bolsos y Mochilas', 18.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Mochila Deportiva 30L', NULL, 'PVP', 'N', 39.950000, 25.000000, 9.987500, 29.962500, 'N', 21.000000, 36.254625, 36.254625, 29.962500, NULL, '2026-02-17 06:21:32', '2026-02-05 16:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000033', 'A1', '010', 'VEST-FLOR', 'VEST-FLOR/ROJO/M', NULL, NULL, 'ROPA', 'Ropa de Vestir', 10.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 3.000000, 'Vestido Estampado Verano - Rojo M', NULL, 'PVP', 'N', 20.000000, 0.000000, 0.000000, 20.000000, 'N', 21.000000, 24.200000, 72.600000, 60.000000, NULL, '2026-02-17 06:21:32', '2026-02-07 18:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000033', 'A1', '020', 'SRV-ENVIO', 'SRV-ENVIO', NULL, NULL, 'OTR', 'Otros', 0.000000, NULL, NULL, NULL, NULL, 'SERVICIO', 'Uds', 1.000000, 'Gastos de Envío - Burgos', NULL, 'PVP', 'N', 5.950000, 0.000000, 0.000000, 5.950000, 'N', 21.000000, 7.199500, 7.199500, 5.950000, NULL, '2026-02-17 06:21:32', '2026-02-07 18:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000034', 'A1', '010', 'CAMI-POLO', 'CAMI-POLO/AZUL/L', NULL, NULL, 'ROPA', 'Ropa de Vestir', 12.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Polo Manga Corta Azul L', NULL, 'PVP', 'N', 28.000000, 0.000000, 0.000000, 28.000000, 'N', 21.000000, 33.880000, 33.880000, 28.000000, NULL, '2026-02-17 06:21:32', '2026-02-08 10:15:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000034', 'A1', '020', 'ZAP-DEPOR', 'ZAP-DEPOR/BLANCO/43', NULL, NULL, 'CALZADO', 'Calzado Elegante', 30.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 1.000000, 'Zapatilla Deportiva Running B43', NULL, 'PVP', 'N', 55.000000, 25.000000, 13.750000, 41.250000, 'N', 21.000000, 49.912500, 49.912500, 41.250000, NULL, '2026-02-17 06:21:32', '2026-02-08 10:15:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000035', 'A1', '010', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/CAMEL/L', NULL, NULL, 'ROPA', 'Ropa de Vestir', 80.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 2.000000, 'Abrigo de Paño Caballero Camel L', NULL, 'VENTAMAYOR', 'N', 120.000000, 0.000000, 0.000000, 120.000000, 'N', 21.000000, 145.200000, 290.400000, 240.000000, NULL, '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000035', 'A1', '020', 'JERSEY-LANA', 'JERSEY-LANA/GRIS/L', NULL, NULL, 'ROPA', 'Ropa de Vestir', 25.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 4.000000, 'Jersey de Lana Gris L', NULL, 'VENTAMAYOR', 'N', 35.000000, 0.000000, 0.000000, 35.000000, 'N', 21.000000, 42.350000, 169.400000, 140.000000, NULL, '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);
INSERT INTO `fza_facturas_lineas` VALUES ('000035', 'A1', '030', 'BOLSO-PIEL', 'BOLSO-PIEL', NULL, NULL, 'BOLSOS', 'Bolsos y Mochilas', 45.000000, NULL, NULL, NULL, NULL, 'ESTANDAR', 'Uds', 2.000000, 'Bolso de Piel Mujer Grande', NULL, 'VENTAMAYOR', 'N', 55.000000, 0.000000, 0.000000, 55.000000, 'N', 21.000000, 66.550000, 133.100000, 110.000000, NULL, '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', 'GEN', '1', NULL, NULL);

-- ----------------------------
-- Table structure for fza_facturas_pagos
-- ----------------------------
DROP TABLE IF EXISTS `fza_facturas_pagos`;
CREATE TABLE `fza_facturas_pagos`  (
  `SERIE_FACTURA_PAGO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Vinculo con Cabecera SERIE',
  `NRO_FACTURA_PAGO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Vinculo con Cabecera NRO',
  `LINEA_PAGO` int(11) NOT NULL COMMENT 'Contador secuencial (1, 2, 3...) para permitir varios pagos',
  `TIPO_PAGO` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'EFECTIVO' COMMENT 'EFECTIVO, TARJETA, BONO_AYTO, VALE_TIENDA, ETC',
  `IMPORTE_PAGO` decimal(19, 6) NOT NULL DEFAULT 0.000000 COMMENT 'Cuantía pagada con este medio',
  `REFERENCIA_PAGO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Aquí guardas el CÓDIGO DE BARRAS del bono o ref de tarjeta',
  `DESCRIPCION_PAGO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Ej: Bono Comercio Campaña Navidad',
  `ENTIDAD_PAGO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Banco, Ayuntamiento X, Asoc. Comerciantes',
  `FECHA_PAGO` datetime NULL DEFAULT NULL COMMENT 'Instante exacto del cobro',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`SERIE_FACTURA_PAGO`, `NRO_FACTURA_PAGO`, `LINEA_PAGO`) USING BTREE,
  INDEX `IDX_TIPO_PAGO`(`TIPO_PAGO` ASC) USING BTREE,
  INDEX `IDX_FECHA_PAGO`(`FECHA_PAGO` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_facturas_pagos
-- ----------------------------
INSERT INTO `fza_facturas_pagos` VALUES ('A1', '000026', 1, 'EFECTIVO', 57.240000, NULL, 'Pago en efectivo', '', '2026-02-17 06:21:32', '2026-02-17 06:21:32', '2026-01-20 10:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_facturas_pagos` VALUES ('A1', '000027', 1, 'TARJETA', 145.200000, NULL, 'Pago con tarjeta débito', 'CAIXABANK', '2026-02-17 06:21:32', '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_facturas_pagos` VALUES ('A1', '000029', 1, 'EFECTIVO', 54.692000, NULL, 'Pago en efectivo', '', '2026-02-17 06:21:32', '2026-02-17 06:21:32', '2026-01-25 12:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_facturas_pagos` VALUES ('A1', '000031', 1, 'EFECTIVO', 50.000000, NULL, 'Pago en efectivo', '', '2026-02-17 06:21:32', '2026-02-17 06:21:32', '2026-02-03 11:30:00', 'DEMO', 'DEMO');
INSERT INTO `fza_facturas_pagos` VALUES ('A1', '000032', 1, 'TARJETA', 133.705000, NULL, 'Pago con tarjeta', 'SANTANDER', '2026-02-17 06:21:32', '2026-02-17 06:21:32', '2026-02-05 16:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_facturas_pagos` VALUES ('A1', '000034', 1, 'EFECTIVO', 90.000000, NULL, 'Pago en efectivo (vuelto 6,51€)', '', '2026-02-17 06:21:32', '2026-02-17 06:21:32', '2026-02-08 10:15:00', 'DEMO', 'DEMO');

-- ----------------------------
-- Table structure for fza_formas_pago
-- ----------------------------
DROP TABLE IF EXISTS `fza_formas_pago`;
CREATE TABLE `fza_formas_pago`  (
  `CODIGO_FORMAPAGO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ACTIVO_FORMAPAGO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ORDEN_FORMAPAGO` int(11) NULL DEFAULT NULL,
  `DESCRIPCION_FORMAPAGO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `N_PLAZOS_FORMAPAGO` int(11) NULL DEFAULT 1,
  `N_DIAS_ENTRE_PLAZOS_FORMAPAGO` int(11) NULL DEFAULT 0,
  `PORCEN_ANTICIPO_FORMAPAGO` int(11) NULL DEFAULT NULL,
  `ESVERBANCOEMPRESA_FORMAPAGO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESCONTADO_FORMAPAGO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESDEFAULT_FORMAPAGO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_FORMAPAGO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_formas_pago
-- ----------------------------
INSERT INTO `fza_formas_pago` VALUES ('30_60_90', 'S', 4, 'RECIBO A 30, 60 y 90 DIAS', 3, 30, 0, 'N', 'N', 'N', '2023-12-14 12:04:03', '2023-12-08 22:33:27', 'Administrador', 'Administrador');
INSERT INTO `fza_formas_pago` VALUES ('30DIAS', 'S', 2, 'RECIBO A 30 DIAS', 1, 30, 0, 'N', 'N', 'N', '2023-12-09 18:25:02', '2022-11-02 16:13:08', 'Administrador', 'Administrador');
INSERT INTO `fza_formas_pago` VALUES ('30Y60', 'S', 1, 'RECIBO 30 DIAS Y 60 DIAS', 2, 30, 0, 'N', 'N', 'N', '2023-12-09 18:25:01', '2023-11-08 21:12:56', 'Administrador', 'Administrador');
INSERT INTO `fza_formas_pago` VALUES ('60DIAS', 'S', 3, 'RECIBO A 60 DIAS', 1, 60, 0, 'N', 'N', 'N', '2023-12-09 18:25:00', '2022-10-06 17:58:14', 'Administrador', 'Administrador');
INSERT INTO `fza_formas_pago` VALUES ('CONTADO', 'S', 1, 'CONTADO', 1, 0, 100, 'N', 'S', 'S', '2023-12-14 12:04:29', '2021-05-14 20:08:58', 'Administrador', 'Administrador');
INSERT INTO `fza_formas_pago` VALUES ('TRANSFERENCIA', 'S', 3, 'TRANSFERENCIA', 1, 0, 100, 'S', 'N', 'N', '2023-12-14 12:04:13', '2023-12-06 18:59:38', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_generadorprocesos
-- ----------------------------
DROP TABLE IF EXISTS `fza_generadorprocesos`;
CREATE TABLE `fza_generadorprocesos`  (
  `CODIGO_GENERADORPROCESO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NOMBRE_GENERADORPROCESO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROCESO_GENERADORPROCESO` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_GENERADORPROCESO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_generadorprocesos
-- ----------------------------
INSERT INTO `fza_generadorprocesos` VALUES ('001', 'INSERTAR CAMPOS GRID POR MTO', '  Select        USUARIO_GRUPO_PERFILES,\r\n                \'frmMtoFormasdePago\' AS KEY_PERFILES,\r\n                SUBKEY_PERFILES,\r\n                VALUE_PERFILES,\r\n                VALUE_TEXT_PERFILES,\r\n                TYPE_BLOB_PERFILES,\r\n                VALUE_BLOB_PERFILES,\r\n                INSTANTEMODIF,\r\n                INSTANTEALTA,\r\n                USUARIOMODIF,\r\n                USUARIOALTA\r\n	  from fza_usuarios_perfiles \r\n	 where KEY_PERFILES = \'frmMtoEmpresas\' \r\n	   and (SUBKEY_PERFILES like \'%tvFacturacion%\' or\r\n         SUBKEY_PERFILES like \'%tvLineasFacturacion%\') ', '2023-11-17 15:03:37', '2023-04-27 12:30:24', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('002', 'update cosas', 'UPDATE fza_ivas\r\n   SET PORCENEXENTO_RE_IVA = 0', '2023-04-28 21:13:07', '2023-04-28 12:28:56', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('003', 'ACTUALIZACION DE CAMPO FZA_IVAS', '           ALTER TABLE FZA_IVAS    MODIFY COLUMN   `GRUPO_ZONA_IVA` varchar(10) NOT NULL;', '2023-04-28 12:46:20', '2023-04-28 12:45:28', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('004', 'SELECT FACTURAS', 'SELECT * FROM FZA_USUARIOS_PERFILES\r\nWHERE KEY_PERFILES = \'frmMtoFormasdePago\'', '2023-05-08 13:44:52', '2023-04-29 12:04:43', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('005', 'borrado perfiles por mto', 'delete from fza_usuarios_perfiles \r\n      where key_perfiles = \'frmMtoFormasdePago\'\r\n        and subkey_perfiles like \'tvLineasFacturacion%\'', '2023-05-27 16:56:53', '2023-05-08 13:41:02', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('006', 'combo facturas', '   \r\nSELECT SERIE_CONTADOR_CLIENTE AS SERIE_CONTADOR \r\n  FROM vi_clientes                              \r\n WHERE SERIE_CONTADOR_CLIENTE IS NOT NULL       \r\n   AND CODIGO_CLIENTE = \'AGRICULTOR\'                \r\n UNION                                          \r\nSELECT SERIE_SERIE AS SERIE_CONTADOR            \r\n  FROM vi_empresas_series                       \r\n WHERE CODIGO_EMPRESA_SERIE = \'007\'          \r\n   AND (FECHA_DESDE_SERIE >= \'12-05-2023\'             \r\n        AND (FECHA_HASTA_SERIE <= \'12-05-2023\'        \r\n             OR FECHA_HASTA_SERIE IS NULL ))    \r\n UNION                                          \r\nSELECT SERIE_CONTADOR_EMPRESA AS SERIE_CONTADOR \r\n  FROM vi_empresas                              \r\n WHERE SERIE_CONTADOR_EMPRESA IS NOT NULL       \r\n   AND  CODIGO_EMPRESA = \'007\'               \r\n UNION                                          \r\n SELECT SERIE_CONTADOR                          \r\n   FROM vi_contadores                           \r\n  WHERE tipodoc_contador = \'FC\'\r\n  ', '2023-05-13 13:53:12', '2023-05-13 13:47:20', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('007', 'BORRADO DE SKINS EN PERFILES', 'DELETE FROM fza_usuarios_perfiles\r\nwhere SUBKEY_PERFILES LIKE \'%skin%\'                                               ', '2023-10-19 11:51:26', '2023-10-19 11:50:25', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('008', 'PROCEDURE CALCULAR NETOS', 'ALTER PROCEDURE `PRC_CALCULAR_FACTURA_NETOS` (IN `pSERIE_FACTURA` VARCHAR(8), \r\n                                              IN `pNRO_FACTURA` VARCHAR(12))\r\nBEGIN\r\n  DECLARE pPRECIOSIVA decimal(19,6);\r\n  DECLARE pPRECIOCIVA decimal(19,6);\r\n  DECLARE pPORCEN decimal(19,6);\r\n  DECLARE pTIPO VARCHAR(2);\r\n  DECLARE pIVA_RECARGO varchar(1) DEFAULT \'\';\r\n  DECLARE pAPLICA_RECARGO varchar(1) DEFAULT \'\';\r\n  DECLARE pIVA_EXENTO varchar(1) DEFAULT \'\';\r\n  DECLARE pREG_AG_EMP varchar(1) DEFAULT \'\';\r\n  DECLARE pREG_AG_CLI varchar(1) DEFAULT \'\';\r\n  DECLARE pINTRACOMUNITARIO varchar(1) DEFAULT \'\';\r\n  DECLARE pAPLICA_RETENCIONES_CLI varchar(1) DEFAULT \'\';\r\n  DECLARE pAPLICA_RETENCIONES_EMP varchar(1) DEFAULT \'\';\r\n  DECLARE pPORCENREN decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENRER decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENRES decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENREE decimal(19,6) DEFAULT 0;\r\n  DECLARE pSUMBASEN decimal(19,6) DEFAULT 0;\r\n  DECLARE pSUMBASER decimal(19,6) DEFAULT 0;\r\n  DECLARE pSUMBASES decimal(19,6) DEFAULT 0;\r\n  DECLARE pSUMBASEE decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTN decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTR decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTS decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTE decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTRECN decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTRECR decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTRECS decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTRECE decimal(19,6) DEFAULT 0;\r\n  DECLARE pSUMTOTREC decimal(19,6) DEFAULT 0;\r\n  DECLARE pSUMTOT decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENN decimal(19,6) DEFAULT 0;\r\n  DECLARE pTOTBASES decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENR decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENS decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENE decimal(19,6) DEFAULT 0;\r\n  DECLARE pPORCENRET decimal(19,6) DEFAULT 0;\r\n  DECLARE pGRUPO_ZONA_IVA int;\r\n  DECLARE pCODIGO_IVA int;\r\n  DECLARE pTOTALRET decimal(19,6) DEFAULT 0;\r\n  DECLARE pFECHA datetime;\r\n  DECLARE pLINEA varchar(3);\r\n  DECLARE pIMP_INCL varchar(1);\r\n  DECLARE pCANTIDAD decimal(19,6) DEFAULT 0;\r\n  DECLARE pCODART varchar(20);\r\n  DECLARE pTIPOIVAF varchar(1) DEFAULT \'X\';\r\n  DECLARE pIRPF_IMP_INCL VARCHAR(1);\r\n  DECLARE pVENTA_ACT_FIJ VARCHAR(1);\r\n  DECLARE finished INTEGER DEFAULT 0;\r\n  DECLARE pCODEMPRESA varchar(8);\r\n  DECLARE CUR_LINEAS \r\n          CURSOR FOR \r\n              SELECT LINEA_FACTURA_LINEA,\r\n                     CODIGO_ARTICULO_FACTURA_LINEA,\r\n                     PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA AS PRECIOSIVA,\r\n                     PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA AS PRECIOCIVA,\r\n                     PORCEN_IVA_FACTURA_LINEA AS PORCEN,\r\n                     TIPOIVA_ARTICULO_FACTURA_LINEA AS TIPO,\r\n                     ESIMP_INCL_TARIFA_FACTURA_LINEA AS IMP_INCL,\r\n                     CANTIDAD_FACTURA_LINEA as CANTIDAD\r\n                FROM FZA_FACTURAS_LINEAS \r\n               WHERE SERIE_FACTURA_LINEA = pSERIE_FACTURA \r\n                 AND NRO_FACTURA_LINEA = pNRO_FACTURA;\r\n  DECLARE CONTINUE HANDLER \r\n          FOR NOT FOUND SET finished = 1;\r\n  SELECT PORCEN_IVAN_FACTURA,\r\n         PORCEN_IVAR_FACTURA,\r\n         PORCEN_IVAS_FACTURA,\r\n         PORCEN_IVAE_FACTURA,\r\n         PORCEN_RETENCION_FACTURA,\r\n         ESAPLICA_RE_ZONA_IVA_FACTURA,\r\n         ESIVA_RECARGO_CLIENTE_FACTURA,\r\n         ESIVA_EXENTO_CLIENTE_FACTURA,\r\n         ESRETENCIONES_CLIENTE_FACTURA,\r\n         ESRETENCIONES_EMPRESA_FACTURA,\r\n         ESIRPF_IMP_INCL_ZONA_IVA_FACTURA,\r\n         PORCEN_REN_FACTURA,\r\n         PORCEN_RER_FACTURA,\r\n         PORCEN_RES_FACTURA,\r\n         PORCEN_REE_FACTURA,\r\n         ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA,\r\n         ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA,\r\n         GRUPO_ZONA_IVA_EMPRESA_FACTURA,\r\n         CODIGO_IVA_FACTURA,\r\n         ESINTRACOMUNITARIO_CLIENTE_FACTURA,\r\n         FECHA_FACTURA,\r\n         CODIGO_EMPRESA_FACTURA,\r\n         ESVENTA_ACTIVO_FIJO_FACTURA\r\n    INTO pPORCENN,\r\n         pPORCENR,\r\n         pPORCENS,\r\n         pPORCENE,\r\n         pPORCENRET,\r\n         pIVA_RECARGO,\r\n         pAPLICA_RECARGO,\r\n         pIVA_EXENTO,\r\n         pAPLICA_RETENCIONES_CLI,\r\n         pAPLICA_RETENCIONES_EMP,\r\n         pIRPF_IMP_INCL,\r\n         pPORCENREN,\r\n         pPORCENRER,\r\n         pPORCENRES,\r\n         pPORCENREE,\r\n         pREG_AG_EMP,\r\n         pREG_AG_CLI,\r\n         pGRUPO_ZONA_IVA,\r\n         pCODIGO_IVA,\r\n         pINTRACOMUNITARIO,\r\n         pFECHA,\r\n         pCODEMPRESA,\r\n         pVENTA_ACT_FIJ\r\n    FROM fza_facturas\r\n   WHERE SERIE_FACTURA = pSERIE_FACTURA\r\n     AND NRO_FACTURA = pNRO_FACTURA;\r\n  IF (pREG_AG_EMP = \'S\') THEN\r\n    SET pAPLICA_RETENCIONES_EMP = \'S\';\r\n    SET pAPLICA_RECARGO = \'N\';\r\n    IF ( EXISTS(SELECT CODIGO_EMPRESA \r\n                  FROM vi_ivas_empresa \r\n                 WHERE CODIGO_EMPRESA = pcodempresa \r\n                   AND ESIVAAGRICOLA_ZONA_IVA = \'S\') ) THEN\r\n      SELECT GRUPO_ZONA_IVA,\r\n             CODIGO_IVA, \r\n             PORCENNORMAL_IVA,\r\n             PORCENEXENTO_IVA,\r\n             PORCENREDUCIDO_IVA,\r\n             PORCENSUPERREDUCIDO_IVA\r\n        INTO pGRUPO_ZONA_IVA,\r\n             pCODIGO_IVA,\r\n             pPORCENN,\r\n             pPORCENE,\r\n             pPORCENR,\r\n             pPORCENS\r\n        FROM vi_ivas_empresa \r\n       WHERE ESIVAAGRICOLA_ZONA_IVA =\'S\'\r\n         AND CODIGO_EMPRESA = pCODEMPRESA\r\n         AND FECHA_DESDE_IVA <= pFECHA\r\n         AND (FECHA_HASTA_IVA IS NULL \r\n              OR FECHA_HASTA_IVA >= pFECHA);\r\n    END IF;\r\n  END IF;\r\n  IF (pINTRACOMUNITARIO = \'S\') THEN\r\n    SET pIVA_EXENTO = \'S\';\r\n    SET pAPLICA_RETENCIONES_CLI = \'N\';\r\n    SET pREG_AG_CLI = \'N\';\r\n  END IF;\r\n  IF ((pVENTA_ACT_FIJ = \'S\') AND (pREG_AG_EMP = \'S\')) THEN\r\n    SET pIVA_EXENTO = \'S\';   \r\n  END IF;    \r\n  IF ((pREG_AG_EMP = \'S\') AND (pREG_AG_CLI = \'S\')) THEN\r\n    SET pAPLICA_RETENCIONES_CLI = \'S\';\r\n    SET pIVA_EXENTO = \'S\';\r\n  END IF;\r\n  IF ((pREG_AG_EMP = \'S\') AND (pREG_AG_CLI = \'N\') AND \r\n      (pAPLICA_RETENCIONES_CLI=\'N\' )) THEN\r\n    SET pIVA_EXENTO = \'S\';\r\n  END IF;    \r\n  IF ((pREG_AG_EMP = \'S\') AND (pREG_AG_CLI = \'N\') AND \r\n      (pAPLICA_RETENCIONES_CLI=\'S\' )) THEN\r\n    SET pTIPOIVAF = \'N\';\r\n  END IF;\r\n  IF (pIVA_EXENTO = \'S\') THEN\r\n    SET pPORCENN = pPORCENE;\r\n    SET pPORCENR = pPORCENE;\r\n    SET pPORCENS = pPORCENE;\r\n    SET pPORCENE = pPORCENE;\r\n    SET pPORCENREN = 0;\r\n    SET pPORCENRER = 0;\r\n    SET pPORCENRES = 0;\r\n    SET pPORCENREE = 0;\r\n    SET pTIPOIVAF = \'E\';\r\n    SET pSUMBASEN = 0;\r\n    SET pSUMBASER = 0;\r\n    SET pSUMBASES = 0;\r\n    SET pSUMBASEE = pSUMBASEE +\r\n                    pSUMBASEN +\r\n                    pSUMBASER +\r\n                    pSUMBASES;\r\n  END IF;\r\n  OPEN CUR_LINEAS;\r\n  GETLINEAS: LOOP\r\n    FETCH CUR_LINEAS INTO pLINEA, \r\n                          pCODART, \r\n                          pPRECIOSIVA, \r\n                          pPRECIOCIVA, \r\n                          pPORCEN, \r\n                          pTIPO, \r\n                          pIMP_INCL, \r\n                          pCANTIDAD ;\r\n    IF finished = 1 THEN \r\n      LEAVE GETLINEAS;\r\n    END IF;\r\n    IF (pTIPOIVAF <> \'X\') THEN\r\n      SET pTIPO = pTIPOIVAF;\r\n    ELSE\r\n      IF (EXISTS( SELECT * \r\n                    FROM fza_articulos \r\n                   WHERE CODIGO_ARTICULO = pCODART ) ) THEN\r\n        SET pTIPO = (SELECT TIPOIVA_ARTICULO \r\n                       FROM fza_articulos \r\n                      WHERE CODIGO_ARTICULO = pCODART);\r\n      END IF;\r\n    END IF;\r\n    CASE pTIPO\r\n    WHEN  \'N\' THEN\r\n      SET pPORCEN = pPORCENN;\r\n      IF (pIMP_INCL = \'S\') THEN\r\n        SET pPRECIOSIVA = pPRECIOCIVA/(1+pPORCEN/100)*pCANTIDAD;\r\n      END IF;\r\n      SET pSUMBASEN = PSUMBASEN + pPRECIOSIVA;\r\n    WHEN \'R\' THEN\r\n      SET pPORCEN = pPORCENR;\r\n      IF (pIMP_INCL = \'S\') THEN\r\n        SET pPRECIOSIVA = pPRECIOCIVA/(1+pPORCEN/100)*pCANTIDAD;\r\n      END IF;\r\n      SET pSUMBASER = PSUMBASER + pPRECIOSIVA;\r\n    WHEN \'S\' THEN\r\n      SET pPORCEN = pPORCENS;\r\n      IF (pIMP_INCL = \'S\') THEN\r\n        SET pPRECIOSIVA = pPRECIOCIVA/(1+pPORCEN/100)*pCANTIDAD;\r\n      END IF;\r\n      SET pSUMBASES = PSUMBASES + pPRECIOSIVA;\r\n    WHEN \'E\' THEN\r\n       SET pPORCEN = pPORCENE;\r\n        IF (pIMP_INCL = \'S\') THEN\r\n          SET pPRECIOSIVA = pPRECIOCIVA/(1+pPORCEN/100)*pCANTIDAD;\r\n        END IF;\r\n        SET pSUMBASEE = PSUMBASEE + pPRECIOSIVA;\r\n    END CASE;\r\n    IF (pIMP_INCL = \'S\') THEN\r\n      UPDATE FZA_FACTURAS_LINEAS \r\n         SET PORCEN_IVA_FACTURA_LINEA = pPORCEN,\r\n             TIPOIVA_ARTICULO_FACTURA_LINEA = pTIPO,\r\n             PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA = \r\n                       PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA/(1+pPORCEN/100),\r\n             TOTAL_FACTURA_LINEA = \r\n               CANTIDAD_FACTURA_LINEA * PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA\r\n       WHERE SERIE_FACTURA_LINEA = pSERIE_FACTURA \r\n         AND NRO_FACTURA_LINEA = pNRO_FACTURA\r\n             AND LINEA_FACTURA_LINEA = pLINEA; \r\n    ELSE\r\n      UPDATE FZA_FACTURAS_LINEAS \r\n         SET PORCEN_IVA_FACTURA_LINEA = pPORCEN,\r\n             TIPOIVA_ARTICULO_FACTURA_LINEA = pTIPO,\r\n             PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA = \r\n                      PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA*(1+pPORCEN/100) ,\r\n             TOTAL_FACTURA_LINEA = \r\n               CANTIDAD_FACTURA_LINEA * PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA\r\n        WHERE SERIE_FACTURA_LINEA = pSERIE_FACTURA \r\n          AND NRO_FACTURA_LINEA = pNRO_FACTURA\r\n          AND LINEA_FACTURA_LINEA = pLINEA; \r\n    END IF;\r\n  END LOOP GETLINEAS;\r\n  SET PTOTBASES = pSUMBASEN + pSUMBASER + pSUMBASES + pSUMBASEE;\r\n  SET pTOTN = pSUMBASEN * (1 + pPORCENN/100) - pSUMBASEN;\r\n  SET pTOTR = pSUMBASER * (1 + pPORCENR/100) - pSUMBASER;\r\n  SET pTOTS = pSUMBASES * (1 + pPORCENS/100) - pSUMBASES;\r\n  SET pTOTE = pSUMBASEE * (1 + pPORCENE/100) - pSUMBASEE;\r\n  SET pSUMTOT = pTOTN + pTOTR + pTOTS + pTOTE;\r\n  IF ( (pIVA_RECARGO =\'S\') AND (pAPLICA_RECARGO = \'S\') ) THEN\r\n    SET pTOTRECN = pSUMBASEN * (1 + pPORCENREN/100) - pSUMBASEN;\r\n    SET pTOTRECS = pSUMBASES * (1 + pPORCENRES/100) - pSUMBASES;\r\n    SET pTOTRECE = pSUMBASEE * (1 + pPORCENREE/100) - pSUMBASEE;\r\n    SET pSUMTOTREC = pTOTRECN + pTOTRECR + pTOTRECS + pTOTRECE;\r\n  ELSE \r\n    SET pTOTRECN = 0;\r\n    SET pTOTRECR = 0;\r\n    SET pTOTRECS = 0;\r\n    SET pTOTRECE = 0;\r\n    SET pSUMTOTREC = 0;\r\n  END IF;\r\n  IF ( (pAPLICA_RETENCIONES_CLI = \'S\') AND\r\n       (pAPLICA_RETENCIONES_EMP = \'S\')        \r\n     ) THEN \r\n    IF (pPORCENRET = 0) THEN \r\n      SET pPORCENRET = (SELECT PORCENRETENCION_RETENCION \r\n                          FROM fza_empresas_retenciones \r\n                         WHERE CODIGO_EMPRESA_RETENCION = pCODEMPRESA\r\n                           AND FECHA_DESDE_RETENCION <= pFECHA\r\n                           AND (    FECHA_HASTA_RETENCION >= pFECHA\r\n                                OR FECHA_HASTA_RETENCION IS NULL) LIMIT 1); \r\n    END IF;\r\n    IF (pIRPF_IMP_INCL = \'S\') THEN\r\n      SET pTOTALRET = (pTOTBASES + pSUMTOT ) * (pPORCENRET/100);\r\n    ELSE\r\n      SET pTOTALRET = pTOTBASES * (pPORCENRET/100);\r\n    END IF;\r\n    IF ((pVENTA_ACT_FIJ = \'S\') AND (pREG_AG_EMP = \'S\')) THEN\r\n      SET pPORCENRET = 0;\r\n      SET PTOTALRET = 0;\r\n    END IF;\r\n  ELSE\r\n    SET pPORCENRET = 0;\r\n    SET PTOTALRET = 0;\r\n  END IF;\r\n  UPDATE fza_facturas \r\n     SET TOTAL_BASEI_IVAN_FACTURA = pSUMBASEN,\r\n         TOTAL_BASEI_IVAR_FACTURA = pSUMBASER,\r\n         TOTAL_BASEI_IVAS_FACTURA = pSUMBASES,\r\n         TOTAL_BASEI_IVAE_FACTURA = pSUMBASEE,\r\n         TOTAL_IVAN_FACTURA = pTOTN,\r\n         TOTAL_IVAR_FACTURA = pTOTR,\r\n         TOTAL_IVAS_FACTURA = pTOTS,\r\n         TOTAL_IVAE_FACTURA = pTOTE,\r\n         TOTAL_REN_FACTURA = PTOTRECN,\r\n         TOTAL_RER_FACTURA = PTOTRECR,\r\n         TOTAL_RES_FACTURA = PTOTRECS,\r\n         TOTAL_REE_FACTURA = PTOTRECE,\r\n         TOTAL_BASES_FACTURA = pTOTBASES,\r\n         TOTAL_RETENCION_FACTURA = pTOTALRET,\r\n         TOTAL_LIQUIDO_FACTURA = pTOTBASES + \r\n                                 pSUMTOT - \r\n                                 PTOTALRET + \r\n                                 pSUMTOTREC,\r\n         ESIVA_EXENTO_CLIENTE_FACTURA = pIVA_EXENTO,\r\n         ESRETENCIONES_CLIENTE_FACTURA = pAPLICA_RETENCIONES_CLI,\r\n         ESRETENCIONES_EMPRESA_FACTURA = pAPLICA_RETENCIONES_EMP,\r\n         ESIVA_RECARGO_CLIENTE_FACTURA = pAPLICA_RECARGO,\r\n         TOTAL_IMPUESTOS_FACTURA = pSUMTOTREC + pSUMTOT,\r\n         GRUPO_ZONA_IVA_EMPRESA_FACTURA = pGRUPO_ZONA_IVA,\r\n         CODIGO_IVA_FACTURA = pCODIGO_IVA,\r\n         PORCEN_IVAN_FACTURA = pPORCENN,\r\n         PORCEN_IVAE_FACTURA = pPORCENE,\r\n         PORCEN_IVAR_FACTURA = pPORCENR,\r\n         PORCEN_IVAS_FACTURA = pPORCENS,\r\n         PORCEN_RETENCION_FACTURA = pPORCENRET\r\n   WHERE NRO_FACTURA = pNRO_FACTURA \r\n     AND SERIE_FACTURA = pSERIE_FACTURA;\r\nEND', '2023-10-22 13:34:17', '2023-10-19 13:28:35', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('009', 'BORRADO PERFILES PANTALLAS', 'DELETE \r\n  FROM fza_usuarios_perfiles \r\n where KEY_PERFILES IN (\'frmMtoArticulos\', \r\n                        \'dmArticulos\', \r\n                        \'frmMtoEmpresas\', \r\n                        \'dmEmpresas\',\r\n                        \'frmMtoClientes\',\r\n                        \'dmClientes\',\r\n                        \'frmMtoFacturas\',\r\n                        \'dmFacturas\', \r\n                        \'frmMtoFamilias\',\r\n                        \'dmFamilias\', \r\n                        \'frmMtoUsuarios\',\r\n                        \'dmUsuarios\', \r\n                        \'frmMtoProveedores\',\r\n                        \'dmProveedores\', \r\n                        \'frmMtoFormasdePago\',\r\n                        \'dmFormasdePago\',\r\n                        \'frmMtoGeneradorProcesos\',\r\n                        \'frmMtoIvas\',\r\n                        \'dmIvas\', \r\n                        \'frmMtoContadores\',\r\n                        \'dmContadores\',\r\n                        \'frmMtoGrupos\',\r\n                        \'dmGrupos\',\r\n                        \'frmMtoIvasGrupos\',\r\n                        \'dmIvasGrupos\')\r\n                         ', '2023-12-14 11:58:15', '2023-10-22 13:29:02', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('010', 'MODICACION VISTA vi_fac_lin_busquedas', 'ALTER ALGORITHM = UNDEFINED DEFINER = `root`@`localhost`SQL SECURITY DEFINER VIEW`vi_fac_lin_busquedas`AS\r\nSELECT\r\n  `fza_facturas_lineas`.`NRO_FACTURA_LINEA` AS `NRO_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`SERIE_FACTURA_LINEA`AS`SERIE_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`LINEA_FACTURA_LINEA`AS`LINEA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`CODIGO_ARTICULO_FACTURA_LINEA`AS`CODIGO_ARTICULO_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`CODIGO_FAMILIA_FACTURA_LINEA`AS`CODIGO_FAMILIA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`NOMBRE_FAMILIA_FACTURA_LINEA`AS`NOMBRE_FAMILIA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`FECHA_ENTREGA_FACTURA_LINEA`AS`FECHA_ENTREGA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`AS`TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`ESIMP_INCL_TARIFA_FACTURA_LINEA`AS`ESIMP_INCL_TARIFA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`TIPOIVA_ARTICULO_FACTURA_LINEA`AS`TIPOIVA_ARTICULO_FACTURA_LINEA`\r\n, `fza_ivas_tipos`.`NOMBRE_TIPO_IVA`AS`NOMBRE_TIPO_IVA`\r\n, `fza_facturas_lineas`.`DESCRIPCION_ARTICULO_FACTURA_LINEA`AS`DESCRIPCION_ARTICULO_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`CODIGO_TARIFA_FACTURA_LINEA`AS`CODIGO_TARIFA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`CANTIDAD_FACTURA_LINEA`AS`CANTIDAD_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`AS`PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`PORCEN_IVA_FACTURA_LINEA`AS`PORCEN_IVA_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`AS`PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`\r\n, `fza_facturas_lineas`.`TOTAL_FACTURA_LINEA`AS`TOTAL_FACTURA_LINEA`\r\n, `fza_facturas`.`CODIGO_CLIENTE_FACTURA` AS `CODIGO_CLIENTE_FACTURA`\r\n, `fza_facturas`.CODIGO_EMPRESA_FACTURA AS `CODIGO_EMPRESA_FACTURA`\r\nFROM (`fza_facturas_lineas`\r\nLEFT JOIN fza_facturas \r\nON (fza_facturas_lineas.NRO_FACTURA_LINEA = fza_facturas.NRO_FACTURA AND fza_facturas_lineas.SERIE_FACTURA_LINEA = fza_facturas.SERIE_FACTURA)\r\nLEFT JOIN `fza_ivas_tipos`\r\n ON (`fza_facturas_lineas`.`TIPOIVA_ARTICULO_FACTURA_LINEA` = `fza_ivas_tipos`.`CODIGO_ABREVIATURA_TIPO_IVA`) )', '2023-10-28 13:44:21', '2023-10-28 13:37:20', 'Administrador', 'Administrador');
INSERT INTO `fza_generadorprocesos` VALUES ('011', 'IGUALAR TARIFAS EN FACTURAS', 'SELECT F.NRO_FACTURA, F.SERIE_FACTURA, L.CODIGO_TARIFA_FACTURA_LINEA,     F.TARIFA_ARTICULO_CLIENTE_FACTURA\r\nFROM\r\n fza_facturas_lineas AS L\r\nINNER JOIN vi_facturas AS F  \r\nON F.NRO_FACTURA = L.NRO_FACTURA_LINEA\r\nAND F.SERIE_FACTURA = L.SERIE_FACTURA_LINEA\r\n\r\n-- SET  CODIGO_TARIFA_FACTURA_LINEA = TARIFA_ARTICULO_CLIENTE_FACTURA\r\n\r\n-- WHERE F.TARIFA_ARTICULO_CLIENTE_FACTURA <> L.CODIGO_TARIFA_FACTURA_LINEA', '2024-10-10 18:49:29', '2023-10-28 13:39:47', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_ivas
-- ----------------------------
DROP TABLE IF EXISTS `fza_ivas`;
CREATE TABLE `fza_ivas`  (
  `CODIGO_IVA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT '0',
  `GRUPO_ZONA_IVA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `DESCRIPCION_ZONA_IVA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `PORCENEXENTO_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENEXENTO_RE_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENNORMAL_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENNORMAL_RE_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENREDUCIDO_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENREDUCIDO_RE_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENSUPERREDUCIDO_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `PORCENSUPERREDUCIDO_RE_IVA` decimal(18, 6) UNSIGNED NOT NULL DEFAULT 0.000000,
  `FECHA_DESDE_IVA` date NOT NULL,
  `FECHA_HASTA_IVA` date NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_IVA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_ivas
-- ----------------------------
INSERT INTO `fza_ivas` VALUES ('017', '003', 'IVA PORTUGAL', 0.000000, 0.000000, 20.000000, 2.000000, 9.000000, 1.000000, 2.000000, 1.000000, '1999-08-01', NULL, '2023-11-17 12:37:19', '2023-11-17 12:37:19', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas` VALUES ('1', '1', 'ESPAÑA PENINSULA', 0.000000, 0.000000, 21.000000, 5.200000, 10.000000, 1.400000, 4.000000, 0.500000, '1999-04-28', NULL, '2023-10-22 14:16:22', '2021-04-28 21:03:03', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas` VALUES ('2', '2', 'COMPENSACIÓN AGRARIA', 0.000000, 0.000000, 12.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, '1999-08-01', NULL, '2023-10-22 14:16:16', '2022-05-27 20:04:13', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas` VALUES ('3', '5', 'IGIC CANARIAS', 0.000000, 0.000000, 5.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, '1999-08-01', NULL, '2023-04-28 12:43:22', '2022-05-27 20:05:09', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas` VALUES ('4', '3', 'IPSI CEUTA Y MELILLA', 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, '1999-08-01', NULL, '2023-05-12 13:58:57', '2023-01-19 10:27:01', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_ivas_grupos
-- ----------------------------
DROP TABLE IF EXISTS `fza_ivas_grupos`;
CREATE TABLE `fza_ivas_grupos`  (
  `GRUPO_ZONA_IVA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT '0',
  `CODIGO_PAIS_ZONA_IVA` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT '724',
  `NOMBRE_PAIS_ZONA_IVA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL DEFAULT 'España',
  `DESCRIPCION_ZONA_IVA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ESIRPF_IMP_INCL_ZONA_IVA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESIVAAGRICOLA_ZONA_IVA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESAPLICA_RE_ZONA_IVA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'Cuando el grupo de iva no aplica RE en sus documentos',
  `ESDEFAULT_ZONA_IVA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `PALABRA_REPORTS_ZONA_IVA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'IVA',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`GRUPO_ZONA_IVA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_ivas_grupos
-- ----------------------------
INSERT INTO `fza_ivas_grupos` VALUES ('003', 'PT', 'Portugal', 'IVA PORTUGUES', 'N', 'N', 'S', 'N', 'IVAÇ', '2025-09-16 17:45:19', '2023-11-17 12:36:00', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_grupos` VALUES ('1', 'ES', 'España', 'ESPAÑA PENINSULA', 'N', 'N', 'S', 'S', 'IVA', '2025-09-16 17:45:20', '2022-08-31 15:18:11', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_grupos` VALUES ('2', 'ES', 'España', 'COMPENSACIÓN AGRARIA Y FORESTAL', 'S', 'S', 'N', 'N', 'REAGP', '2025-09-16 17:45:20', '2022-08-31 15:18:41', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_grupos` VALUES ('3', 'ES', 'España', 'IGIC CANARIAS', 'N', 'N', 'S', 'N', 'IGIC', '2025-09-16 17:45:21', '2022-08-31 15:19:52', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_grupos` VALUES ('5', 'ES', 'España', 'CEUTA Y MELILLA', 'N', 'N', 'S', 'N', 'IPSI', '2025-09-16 17:45:22', '2023-01-19 10:24:36', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_ivas_tipos
-- ----------------------------
DROP TABLE IF EXISTS `fza_ivas_tipos`;
CREATE TABLE `fza_ivas_tipos`  (
  `CODIGO_ABREVIATURA_TIPO_IVA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_TIPO_IVA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_ivas_tipos
-- ----------------------------
INSERT INTO `fza_ivas_tipos` VALUES ('N', 'Normal', '2023-03-09 18:12:55', '2023-03-09 18:12:47', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_tipos` VALUES ('R', 'Reducido', '2023-03-09 18:13:09', '2023-03-09 18:13:03', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_tipos` VALUES ('S', 'Súper Reducido', '2023-03-09 18:13:31', '2023-03-09 18:13:24', 'Administrador', 'Administrador');
INSERT INTO `fza_ivas_tipos` VALUES ('E', 'Exento', '2023-03-09 18:13:48', '2023-03-09 18:13:40', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_ivas_zonas
-- ----------------------------
DROP TABLE IF EXISTS `fza_ivas_zonas`;
CREATE TABLE `fza_ivas_zonas`  (
  `CODIGO_ZONA_IVA` int(11) NOT NULL,
  `DESCRIPCION_ZONA_IVA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESDEFAULT_ZONA_IVA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`CODIGO_ZONA_IVA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_ivas_zonas
-- ----------------------------
INSERT INTO `fza_ivas_zonas` VALUES (0, 'ESPAÑA PENÍNSULA', 'S');
INSERT INTO `fza_ivas_zonas` VALUES (1, 'INTRACOMUNITARIA', 'N');

-- ----------------------------
-- Table structure for fza_metadatos
-- ----------------------------
DROP TABLE IF EXISTS `fza_metadatos`;
CREATE TABLE `fza_metadatos`  (
  `CODIGO_METADATO` int(20) NOT NULL AUTO_INCREMENT,
  `NOMBRE_METADATO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `PARENT_METADATO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_METADATO`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 193 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_metadatos
-- ----------------------------
INSERT INTO `fza_metadatos` VALUES (1, 'Tablas', '-1');
INSERT INTO `fza_metadatos` VALUES (2, 'Vistas', '-1');
INSERT INTO `fza_metadatos` VALUES (3, 'Procedimientos', '-1');
INSERT INTO `fza_metadatos` VALUES (4, 'fza_almacenes', '1');
INSERT INTO `fza_metadatos` VALUES (5, 'fza_almacenes_cajas', '1');
INSERT INTO `fza_metadatos` VALUES (6, 'fza_articulos', '1');
INSERT INTO `fza_metadatos` VALUES (7, 'fza_articulos_conjuntos_asign', '1');
INSERT INTO `fza_metadatos` VALUES (8, 'fza_articulos_familias', '1');
INSERT INTO `fza_metadatos` VALUES (9, 'fza_articulos_propiedades', '1');
INSERT INTO `fza_metadatos` VALUES (10, 'fza_articulos_proveedores', '1');
INSERT INTO `fza_metadatos` VALUES (11, 'fza_articulos_skus', '1');
INSERT INTO `fza_metadatos` VALUES (12, 'fza_articulos_stockactual', '1');
INSERT INTO `fza_metadatos` VALUES (13, 'fza_articulos_tarifas', '1');
INSERT INTO `fza_metadatos` VALUES (14, 'fza_articulos_vinculos', '1');
INSERT INTO `fza_metadatos` VALUES (15, 'fza_atributos_conjuntos', '1');
INSERT INTO `fza_metadatos` VALUES (16, 'fza_atributos_conjuntos_det', '1');
INSERT INTO `fza_metadatos` VALUES (17, 'fza_atributos_sku', '1');
INSERT INTO `fza_metadatos` VALUES (18, 'fza_atributos_valores', '1');
INSERT INTO `fza_metadatos` VALUES (19, 'fza_atributos_valores_info', '1');
INSERT INTO `fza_metadatos` VALUES (20, 'fza_caja_formas_pago', '1');
INSERT INTO `fza_metadatos` VALUES (21, 'fza_caja_operaciones', '1');
INSERT INTO `fza_metadatos` VALUES (22, 'fza_caja_pagos', '1');
INSERT INTO `fza_metadatos` VALUES (23, 'fza_caja_vales', '1');
INSERT INTO `fza_metadatos` VALUES (24, 'fza_clientes', '1');
INSERT INTO `fza_metadatos` VALUES (25, 'fza_codigos_barras', '1');
INSERT INTO `fza_metadatos` VALUES (26, 'fza_config_campos', '1');
INSERT INTO `fza_metadatos` VALUES (27, 'fza_contadores', '1');
INSERT INTO `fza_metadatos` VALUES (28, 'fza_depositos_cliente', '1');
INSERT INTO `fza_metadatos` VALUES (29, 'fza_empresas', '1');
INSERT INTO `fza_metadatos` VALUES (30, 'fza_empresas_retenciones', '1');
INSERT INTO `fza_metadatos` VALUES (31, 'fza_empresas_series', '1');
INSERT INTO `fza_metadatos` VALUES (32, 'fza_facturas', '1');
INSERT INTO `fza_metadatos` VALUES (33, 'fza_facturas_consolidaciones', '1');
INSERT INTO `fza_metadatos` VALUES (34, 'fza_facturas_lineas', '1');
INSERT INTO `fza_metadatos` VALUES (35, 'fza_facturas_pagos', '1');
INSERT INTO `fza_metadatos` VALUES (36, 'fza_formas_pago', '1');
INSERT INTO `fza_metadatos` VALUES (37, 'fza_generadorprocesos', '1');
INSERT INTO `fza_metadatos` VALUES (38, 'fza_ivas', '1');
INSERT INTO `fza_metadatos` VALUES (39, 'fza_ivas_grupos', '1');
INSERT INTO `fza_metadatos` VALUES (40, 'fza_ivas_tipos', '1');
INSERT INTO `fza_metadatos` VALUES (41, 'fza_ivas_zonas', '1');
INSERT INTO `fza_metadatos` VALUES (42, 'fza_metadatos', '1');
INSERT INTO `fza_metadatos` VALUES (43, 'fza_movimientos_almacen', '1');
INSERT INTO `fza_metadatos` VALUES (44, 'fza_paises', '1');
INSERT INTO `fza_metadatos` VALUES (45, 'fza_pedidos', '1');
INSERT INTO `fza_metadatos` VALUES (46, 'fza_pedidos_lineas', '1');
INSERT INTO `fza_metadatos` VALUES (47, 'fza_pedidos_mensajes', '1');
INSERT INTO `fza_metadatos` VALUES (48, 'fza_proveedores', '1');
INSERT INTO `fza_metadatos` VALUES (49, 'fza_recibos', '1');
INSERT INTO `fza_metadatos` VALUES (50, 'fza_tarifas', '1');
INSERT INTO `fza_metadatos` VALUES (51, 'fza_tipos_documentos', '1');
INSERT INTO `fza_metadatos` VALUES (52, 'fza_usuarios', '1');
INSERT INTO `fza_metadatos` VALUES (53, 'fza_usuarios_grupos', '1');
INSERT INTO `fza_metadatos` VALUES (54, 'fza_usuarios_perfiles', '1');
INSERT INTO `fza_metadatos` VALUES (55, 'fza_valores_defecto', '1');
INSERT INTO `fza_metadatos` VALUES (56, 'fza_variaciones', '1');
INSERT INTO `fza_metadatos` VALUES (57, 'fza_variaciones_atributos', '1');
INSERT INTO `fza_metadatos` VALUES (58, 'fza_verifactu_eventos', '1');
INSERT INTO `fza_metadatos` VALUES (59, 'fza_winforms', '1');
INSERT INTO `fza_metadatos` VALUES (67, 'vi_articulos', '2');
INSERT INTO `fza_metadatos` VALUES (68, 'vi_articulos_familias', '2');
INSERT INTO `fza_metadatos` VALUES (69, 'vi_articulos_familias_list', '2');
INSERT INTO `fza_metadatos` VALUES (70, 'vi_articulos_list', '2');
INSERT INTO `fza_metadatos` VALUES (71, 'vi_articulos_proveedores', '2');
INSERT INTO `fza_metadatos` VALUES (72, 'vi_articulos_tarifas', '2');
INSERT INTO `fza_metadatos` VALUES (73, 'vi_art_busquedas', '2');
INSERT INTO `fza_metadatos` VALUES (74, 'vi_atributos_nombres', '2');
INSERT INTO `fza_metadatos` VALUES (75, 'vi_cajasdef', '2');
INSERT INTO `fza_metadatos` VALUES (76, 'vi_caja_busqueda_unificada', '2');
INSERT INTO `fza_metadatos` VALUES (77, 'vi_caja_tarifa_sku_articulos', '2');
INSERT INTO `fza_metadatos` VALUES (78, 'vi_caja_totalventas', '2');
INSERT INTO `fza_metadatos` VALUES (79, 'vi_caja_vales_ptes', '2');
INSERT INTO `fza_metadatos` VALUES (80, 'vi_clientes', '2');
INSERT INTO `fza_metadatos` VALUES (81, 'vi_cli_busquedas', '2');
INSERT INTO `fza_metadatos` VALUES (82, 'vi_contadores', '2');
INSERT INTO `fza_metadatos` VALUES (83, 'vi_empresas', '2');
INSERT INTO `fza_metadatos` VALUES (84, 'vi_empresas_retenciones', '2');
INSERT INTO `fza_metadatos` VALUES (85, 'vi_empresas_series', '2');
INSERT INTO `fza_metadatos` VALUES (86, 'vi_emp_busquedas', '2');
INSERT INTO `fza_metadatos` VALUES (87, 'vi_facturas', '2');
INSERT INTO `fza_metadatos` VALUES (88, 'vi_facturas_lineas', '2');
INSERT INTO `fza_metadatos` VALUES (89, 'vi_facturas_lineas_print', '2');
INSERT INTO `fza_metadatos` VALUES (90, 'vi_facturas_print', '2');
INSERT INTO `fza_metadatos` VALUES (91, 'vi_fac_busquedas', '2');
INSERT INTO `fza_metadatos` VALUES (92, 'vi_fac_lin_busquedas', '2');
INSERT INTO `fza_metadatos` VALUES (93, 'vi_formapago', '2');
INSERT INTO `fza_metadatos` VALUES (94, 'vi_info_tpv_completa', '2');
INSERT INTO `fza_metadatos` VALUES (95, 'vi_ivas', '2');
INSERT INTO `fza_metadatos` VALUES (96, 'vi_ivas_empresa', '2');
INSERT INTO `fza_metadatos` VALUES (97, 'vi_ivas_grupos', '2');
INSERT INTO `fza_metadatos` VALUES (98, 'vi_ivas_zonas', '2');
INSERT INTO `fza_metadatos` VALUES (99, 'vi_paises', '2');
INSERT INTO `fza_metadatos` VALUES (100, 'vi_proveedores', '2');
INSERT INTO `fza_metadatos` VALUES (101, 'vi_proveedores_articulos', '2');
INSERT INTO `fza_metadatos` VALUES (102, 'vi_proveedores_busquedas', '2');
INSERT INTO `fza_metadatos` VALUES (103, 'vi_recibos', '2');
INSERT INTO `fza_metadatos` VALUES (104, 'vi_tarifas', '2');
INSERT INTO `fza_metadatos` VALUES (105, 'vi_usuarios', '2');
INSERT INTO `fza_metadatos` VALUES (106, 'vi_usuarios_grupos', '2');
INSERT INTO `fza_metadatos` VALUES (107, 'vi_usuarios_perfiles', '2');
INSERT INTO `fza_metadatos` VALUES (130, 'PRC_AGREGAR_VALOR_CONJUNTO', '3');
INSERT INTO `fza_metadatos` VALUES (131, 'PRC_BUSQUEDA_ARTICULOS', '3');
INSERT INTO `fza_metadatos` VALUES (132, 'PRC_CALCULAR_FACTURA_NETOS', '3');
INSERT INTO `fza_metadatos` VALUES (133, 'PRC_CREAR_ACTUALIZAR_ARTICULO', '3');
INSERT INTO `fza_metadatos` VALUES (134, 'PRC_CREAR_ACTUALIZAR_ARTICULO_PROVEEDOR', '3');
INSERT INTO `fza_metadatos` VALUES (135, 'PRC_CREAR_ACTUALIZAR_CLIENTE', '3');
INSERT INTO `fza_metadatos` VALUES (136, 'PRC_CREAR_ACTUALIZAR_EMPRESA', '3');
INSERT INTO `fza_metadatos` VALUES (137, 'PRC_CREAR_ACTUALIZAR_FAMILIA', '3');
INSERT INTO `fza_metadatos` VALUES (138, 'PRC_CREAR_ACTUALIZAR_KEY', '3');
INSERT INTO `fza_metadatos` VALUES (139, 'PRC_CREAR_ACTUALIZAR_PROVEEDOR', '3');
INSERT INTO `fza_metadatos` VALUES (140, 'PRC_CREAR_ACTUALIZAR_TARIFA', '3');
INSERT INTO `fza_metadatos` VALUES (141, 'PRC_CREAR_ACTUALIZAR_TEST', '3');
INSERT INTO `fza_metadatos` VALUES (142, 'PRC_CREAR_FACTURA_ABONO', '3');
INSERT INTO `fza_metadatos` VALUES (143, 'PRC_CREAR_FACTURA_DUPLICADA', '3');
INSERT INTO `fza_metadatos` VALUES (144, 'PRC_CREAR_METADATOS', '3');
INSERT INTO `fza_metadatos` VALUES (145, 'PRC_CREAR_RECIBOS_FACTURA', '3');
INSERT INTO `fza_metadatos` VALUES (146, 'PRC_CREAR_TRASPASO', '3');
INSERT INTO `fza_metadatos` VALUES (147, 'PRC_FNC_GET_NEXT_LINEA_FACTURA', '3');
INSERT INTO `fza_metadatos` VALUES (148, 'PRC_FNC_GET_NEXT_NRO_DOC', '3');
INSERT INTO `fza_metadatos` VALUES (149, 'PRC_FNC_GET_PRECIO_ARTICULO_FECHA', '3');
INSERT INTO `fza_metadatos` VALUES (150, 'PRC_FNC_GET_SERIE_TIPODOC', '3');
INSERT INTO `fza_metadatos` VALUES (151, 'PRC_GENERAR_CODIGO_VALE', '3');
INSERT INTO `fza_metadatos` VALUES (152, 'PRC_GETPERFILFORMULARIO', '3');
INSERT INTO `fza_metadatos` VALUES (153, 'PRC_GET_CAJA_STOCK_PIVOTADO', '3');
INSERT INTO `fza_metadatos` VALUES (154, 'PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ', '3');
INSERT INTO `fza_metadatos` VALUES (155, 'PRC_GET_CREAR_VALOR', '3');
INSERT INTO `fza_metadatos` VALUES (156, 'PRC_GET_DATA_ARTICULO', '3');
INSERT INTO `fza_metadatos` VALUES (157, 'PRC_GET_DATA_CLIENTE', '3');
INSERT INTO `fza_metadatos` VALUES (158, 'PRC_GET_IVA_ZONA_FECHA', '3');
INSERT INTO `fza_metadatos` VALUES (159, 'PRC_GET_NEXT_CONT', '3');
INSERT INTO `fza_metadatos` VALUES (160, 'PRC_GET_NEXT_CONT_FACT_SERIE', '3');
INSERT INTO `fza_metadatos` VALUES (161, 'PRC_GET_NEXT_OP_CAJA', '3');
INSERT INTO `fza_metadatos` VALUES (162, 'PRC_GET_NUMEROS_A_LETRAS', '3');
INSERT INTO `fza_metadatos` VALUES (163, 'PRC_GET_NUMERO_MENOR_MIL', '3');
INSERT INTO `fza_metadatos` VALUES (164, 'PRC_REALIZAR_TRASPASO', '3');
INSERT INTO `fza_metadatos` VALUES (165, 'PRC_RECALCULAR_STOCK', '3');
INSERT INTO `fza_metadatos` VALUES (166, 'PRC_SETPERFILFORMULARIO', '3');
INSERT INTO `fza_metadatos` VALUES (167, 'SP_RECALCULAR_PMP_SKU', '3');
INSERT INTO `fza_metadatos` VALUES (168, 'SP_RECALCULAR_PMP_SKU_ALMACEN', '3');

-- ----------------------------
-- Table structure for fza_movimientos_almacen
-- ----------------------------
DROP TABLE IF EXISTS `fza_movimientos_almacen`;
CREATE TABLE `fza_movimientos_almacen`  (
  `NUMERO_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TIPO_DOC_MOV` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'VE, TR, AT, AL, IN, AC, AE',
  `SERIE_DOC_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NRO_DOC_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `LINEA_MOV` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Ahora es VARCHAR(4) según libro de estilo',
  `CODIGO_EMPRESA_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CODIGO_ALMACEN_MOV` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `FECHA_MOV` datetime NULL DEFAULT NULL,
  `CODIGO_ARTICULO_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código Padre (ej: 003)',
  `CODIGO_UNIDAD_MOV` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'SKU (ej: 003BLANCO45)',
  `DESCRIPCION_ARTICULO_MOV` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TIPO_MOVIMIENTO_MOV` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'E = Entrada, S = Salida',
  `CANTIDAD_MOV` decimal(19, 6) NULL DEFAULT 0.000000,
  `PRECIO_COSTE_UNITARIO_MOV` decimal(19, 6) NULL DEFAULT 0.000000,
  `TOTAL_COSTE_MOV` decimal(19, 6) NULL DEFAULT 0.000000 COMMENT 'Cantidad * Coste Unitario',
  `PRECIO_MEDIO_MOV` decimal(19, 6) NULL DEFAULT 0.000000 COMMENT 'PMP capturado en el momento de la transacción',
  `CODIGO_ALMACEN_CONTRA_MOV` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Para traspasos: a qué almacén va',
  `CODIGO_CLIENTE_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Para ventas o depósitos',
  `CODIGO_PROVEEDOR_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Para entradas de compra',
  `ESACTIVO_MOV` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TIPO_DOC_REF_MOV` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SERIE_DOC_REF_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NRO_DOC_REF_MOV` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `LINEA_REF_MOV` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `LOTE_MOV` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '' COMMENT 'Número de lote impreso',
  `FECHA_CADUCIDAD_MOV` date NULL DEFAULT NULL,
  PRIMARY KEY (`NUMERO_MOV`) USING BTREE,
  INDEX `IDX_SKU_ALM_MOV`(`CODIGO_UNIDAD_MOV` ASC, `CODIGO_ALMACEN_MOV` ASC, `FECHA_MOV` ASC) USING BTREE,
  INDEX `IDX_FECHA_MOV`(`FECHA_MOV` ASC) USING BTREE,
  INDEX `IDX_REF_MOV`(`TIPO_DOC_REF_MOV` ASC, `SERIE_DOC_REF_MOV` ASC, `NRO_DOC_REF_MOV` ASC, `LINEA_REF_MOV` ASC) USING BTREE,
  INDEX `IDX_MOV_ALMACEN_FECHA`(`CODIGO_ALMACEN_MOV` ASC, `FECHA_MOV` ASC) USING BTREE,
  INDEX `IDX_MOV_SKU_FECHA`(`CODIGO_UNIDAD_MOV` ASC, `FECHA_MOV` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_movimientos_almacen
-- ----------------------------
INSERT INTO `fza_movimientos_almacen` VALUES ('0', 'IN', 'A1', '2026001', '001', '1', 'GEN', '2026-01-04 22:13:10', 'ZAP-OXFORD', 'ZAP-OXFORD/NEGRO/42', 'Zapato Oxford Piel 42 Negro', 'E', 10.000000, 40.000000, 400.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:40:22', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('1', 'IN', 'A1', '2026001', '002', '1', 'GEN', '2026-01-04 22:13:10', 'ZAP-OXFORD', 'ZAP-OXFORD/MARRON/43', 'Zapato Oxford Piel 43 Marrón', 'E', 8.000000, 40.000000, 320.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:40:29', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('100', 'IN', 'A1', '2026001', '100', '1', 'GEN', '2026-01-10 08:00:00', 'CAMI-POLO', 'CAMI-POLO/BLANCO/S', 'Polo Blanco S', 'E', 15.000000, 12.000000, 180.000000, 12.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('101', 'IN', 'A1', '2026001', '101', '1', 'GEN', '2026-01-10 08:00:00', 'CAMI-POLO', 'CAMI-POLO/BLANCO/M', 'Polo Blanco M', 'E', 20.000000, 12.000000, 240.000000, 12.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('102', 'IN', 'A1', '2026001', '102', '1', 'GEN', '2026-01-10 08:00:00', 'CAMI-POLO', 'CAMI-POLO/AZUL/M', 'Polo Azul M', 'E', 18.000000, 12.000000, 216.000000, 12.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('103', 'IN', 'A1', '2026001', '103', '1', 'GEN', '2026-01-10 08:00:00', 'CAMI-POLO', 'CAMI-POLO/AZUL/L', 'Polo Azul L', 'E', 12.000000, 12.000000, 144.000000, 12.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('104', 'IN', 'A1', '2026001', '104', '1', 'GEN', '2026-01-10 08:00:00', 'JERSEY-LANA', 'JERSEY-LANA/GRIS/M', 'Jersey Gris M', 'E', 10.000000, 25.000000, 250.000000, 25.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('105', 'IN', 'A1', '2026001', '105', '1', 'GEN', '2026-01-10 08:00:00', 'JERSEY-LANA', 'JERSEY-LANA/GRIS/L', 'Jersey Gris L', 'E', 10.000000, 25.000000, 250.000000, 25.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('106', 'IN', 'A1', '2026001', '106', '1', 'GEN', '2026-01-10 08:00:00', 'JERSEY-LANA', 'JERSEY-LANA/BEIGE/M', 'Jersey Beige M', 'E', 8.000000, 25.000000, 200.000000, 25.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('107', 'IN', 'A1', '2026001', '107', '1', 'GEN', '2026-01-10 08:00:00', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/NEGRO/L', 'Abrigo Negro L', 'E', 6.000000, 80.000000, 480.000000, 80.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('108', 'IN', 'A1', '2026001', '108', '1', 'GEN', '2026-01-10 08:00:00', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/NEGRO/XL', 'Abrigo Negro XL', 'E', 4.000000, 80.000000, 320.000000, 80.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('109', 'IN', 'A1', '2026001', '109', '1', 'GEN', '2026-01-10 08:00:00', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/CAMEL/L', 'Abrigo Camel L', 'E', 5.000000, 80.000000, 400.000000, 80.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('110', 'IN', 'A1', '2026001', '110', '1', 'GEN', '2026-01-10 08:00:00', 'ZAP-BOTA-MT', 'ZAP-BOTA-MT/NEGRO/41', 'Bota Montana Neg 41', 'E', 8.000000, 42.000000, 336.000000, 42.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('111', 'IN', 'A1', '2026001', '111', '1', 'GEN', '2026-01-10 08:00:00', 'ZAP-BOTA-MT', 'ZAP-BOTA-MT/NEGRO/42', 'Bota Montana Neg 42', 'E', 10.000000, 42.000000, 420.000000, 42.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('112', 'IN', 'A1', '2026001', '112', '1', 'GEN', '2026-01-10 08:00:00', 'ZAP-BOTA-MT', 'ZAP-BOTA-MT/MARRON/43', 'Bota Montana Mrn 43', 'E', 6.000000, 42.000000, 252.000000, 42.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('113', 'IN', 'A1', '2026001', '113', '1', 'GEN', '2026-01-10 08:00:00', 'LEGGING-SPORT', 'LEGGING-SPORT/NEGRO/S', 'Legging Negro S', 'E', 20.000000, 8.000000, 160.000000, 8.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('114', 'IN', 'A1', '2026001', '114', '1', 'GEN', '2026-01-10 08:00:00', 'LEGGING-SPORT', 'LEGGING-SPORT/NEGRO/M', 'Legging Negro M', 'E', 20.000000, 8.000000, 160.000000, 8.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('115', 'IN', 'A1', '2026001', '115', '1', 'GEN', '2026-01-10 08:00:00', 'LEGGING-SPORT', 'LEGGING-SPORT/ROSA/S', 'Legging Rosa S', 'E', 15.000000, 8.000000, 120.000000, 8.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('116', 'IN', 'A1', '2026001', '116', '1', 'GEN', '2026-01-10 08:00:00', 'SUDADERA-HOOD', 'SUDADERA-HOOD/GRIS/S', 'Sudadera Gris S', 'E', 12.000000, 20.000000, 240.000000, 20.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('117', 'IN', 'A1', '2026001', '117', '1', 'GEN', '2026-01-10 08:00:00', 'SUDADERA-HOOD', 'SUDADERA-HOOD/GRIS/M', 'Sudadera Gris M', 'E', 15.000000, 20.000000, 300.000000, 20.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('118', 'IN', 'A1', '2026001', '118', '1', 'GEN', '2026-01-10 08:00:00', 'SUDADERA-HOOD', 'SUDADERA-HOOD/NEGRO/L', 'Sudadera Negra L', 'E', 10.000000, 20.000000, 200.000000, 20.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('119', 'IN', 'A1', '2026001', '119', '1', 'GEN', '2026-01-10 08:00:00', 'BOLSO-PIEL', 'BOLSO-PIEL', 'Bolso Piel Señora', 'E', 10.000000, 45.000000, 450.000000, 45.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('120', 'IN', 'A1', '2026001', '120', '1', 'GEN', '2026-01-10 08:00:00', 'MOCHILA-SPORT', 'MOCHILA-SPORT', 'Mochila Deportiva', 'E', 12.000000, 18.000000, 216.000000, 18.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('121', 'IN', 'A1', '2026001', '121', '1', 'GEN', '2026-01-10 08:00:00', 'CINTURON-PIEL', 'CINTURON-PIEL', 'Cinturon Piel', 'E', 20.000000, 9.000000, 180.000000, 9.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('122', 'IN', 'A1', '2026001', '122', '1', 'GEN', '2026-01-10 08:00:00', 'SOMBRERO-PJM', 'SOMBRERO-PJM', 'Sombrero Panama', 'E', 8.000000, 15.000000, 120.000000, 15.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-10 08:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('123', 'IN', 'A1', '2026002', '001', '1', 'GEN', '2026-01-20 09:00:00', 'CAMI-BASICA', 'CAMI-BASICA/BLANCO/M', 'Camiseta Blanca M', 'E', 25.000000, 7.000000, 175.000000, 7.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('124', 'IN', 'A1', '2026002', '002', '1', 'GEN', '2026-01-20 09:00:00', 'CAMI-BASICA', 'CAMI-BASICA/NEGRO/M', 'Camiseta Negra M', 'E', 25.000000, 7.000000, 175.000000, 7.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('125', 'IN', 'A1', '2026002', '003', '1', 'GEN', '2026-01-20 09:00:00', 'CAMI-BASICA', 'CAMI-BASICA/ROJO/L', 'Camiseta Roja L', 'E', 20.000000, 7.000000, 140.000000, 7.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('126', 'IN', 'A1', '2026002', '004', '1', 'GEN', '2026-01-20 09:00:00', 'PANT-CHIN', 'PANT-CHIN/BEIGE/38', 'Pantalon Chino Beige 38', 'E', 12.000000, 40.000000, 480.000000, 40.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('127', 'IN', 'A1', '2026002', '005', '1', 'GEN', '2026-01-20 09:00:00', 'PANT-CHIN', 'PANT-CHIN/BEIGE/40', 'Pantalon Chino Beige 40', 'E', 10.000000, 40.000000, 400.000000, 40.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('128', 'IN', 'A1', '2026002', '006', '1', 'GEN', '2026-01-20 09:00:00', 'VEST-FLOR', 'VEST-FLOR/AZUL/S', 'Vestido Flores Azul S', 'E', 8.000000, 10.000000, 80.000000, 10.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('129', 'IN', 'A1', '2026002', '007', '1', 'GEN', '2026-01-20 09:00:00', 'VEST-FLOR', 'VEST-FLOR/ROJO/M', 'Vestido Flores Rojo M', 'E', 8.000000, 10.000000, 80.000000, 10.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('130', 'IN', 'A1', '2026003', '001', '1', 'BCN', '2026-01-22 09:00:00', 'ZAP-DEPOR', 'ZAP-DEPOR/BLANCO/43', 'Zap Depor Blanco 43', 'E', 10.000000, 30.000000, 300.000000, 30.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-22 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('131', 'IN', 'A1', '2026003', '002', '1', 'BCN', '2026-01-22 09:00:00', 'ZAP-DEPOR', 'ZAP-DEPOR/NEGRO/44', 'Zap Depor Negro 44', 'E', 8.000000, 30.000000, 240.000000, 30.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-22 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('132', 'IN', 'A1', '2026003', '003', '1', 'BCN', '2026-01-22 09:00:00', 'LEGGING-SPORT', 'LEGGING-SPORT/NEGRO/S', 'Legging Negro S', 'E', 10.000000, 8.000000, 80.000000, 8.000000, NULL, NULL, NULL, 'S', '2026-02-17 06:21:32', '2026-01-22 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('2', 'IN', 'A1', '2026001', '003', '1', 'GEN', '2026-01-04 22:13:10', 'ZAP-TACÓN', 'ZAP-TACÓN/ROJO/37', 'Zapato Tacón 37 Rojo', 'E', 5.000000, 25.000000, 125.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:40:37', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('200', 'VE', 'A1', '000026', '010', '1', 'GEN', '2026-01-20 10:00:00', 'JERSEY-LANA', 'JERSEY-LANA/GRIS/M', 'Jersey de Lana Cuello Redondo', 'S', 2.000000, 25.000000, 50.000000, 25.000000, NULL, '301', NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 10:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('201', 'VE', 'A1', '000026', '020', '1', 'GEN', '2026-01-20 10:00:00', 'CINTURON-PIEL', 'CINTURON-PIEL', 'Cinturón Piel Reversible', 'S', 2.000000, 9.000000, 18.000000, 9.000000, NULL, '301', NULL, 'S', '2026-02-17 06:21:32', '2026-01-20 10:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('202', 'VE', 'A1', '000027', '010', '1', 'GEN', '2026-01-21 11:00:00', 'ZAP-OXFORD', 'ZAP-OXFORD/NEGRO/42', 'Zapato Oxford Piel 42 Negro', 'S', 1.000000, 40.000000, 0.000000, 0.000000, NULL, '302', NULL, 'S', '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('203', 'VE', 'A1', '000027', '020', '1', 'GEN', '2026-01-21 11:00:00', 'CINTURON-PIEL', 'CINTURON-PIEL', 'Cinturón Piel Reversible', 'S', 1.000000, 9.000000, 9.000000, 9.000000, NULL, '302', NULL, 'S', '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('204', 'VE', 'A1', '000027', '030', '1', 'GEN', '2026-01-21 11:00:00', 'CARTERA-PIEL', 'CARTERA-PIEL', 'Cartera Piel Caballero', 'S', 1.000000, 20.000000, 0.000000, 0.000000, NULL, '302', NULL, 'S', '2026-02-17 06:21:32', '2026-01-21 11:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('205', 'VE', 'A1', '000028', '010', '1', 'GEN', '2026-01-23 09:00:00', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/NEGRO/L', 'Abrigo Negro L', 'S', 3.000000, 80.000000, 240.000000, 80.000000, NULL, '306', NULL, 'S', '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('206', 'VE', 'A1', '000028', '020', '1', 'GEN', '2026-01-23 09:00:00', 'SUDADERA-HOOD', 'SUDADERA-HOOD/GRIS/M', 'Sudadera Gris M', 'S', 6.000000, 20.000000, 120.000000, 20.000000, NULL, '306', NULL, 'S', '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('207', 'VE', 'A1', '000028', '030', '1', 'GEN', '2026-01-23 09:00:00', 'BOLSO-PIEL', 'BOLSO-PIEL', 'Bolso Piel Señora', 'S', 1.000000, 45.000000, 45.000000, 45.000000, NULL, '306', NULL, 'S', '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('208', 'VE', 'A1', '000028', '040', '1', 'GEN', '2026-01-23 09:00:00', 'JERSEY-LANA', 'JERSEY-LANA/BEIGE/M', 'Jersey Beige M', 'S', 5.000000, 25.000000, 125.000000, 25.000000, NULL, '306', NULL, 'S', '2026-02-17 06:21:32', '2026-01-23 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('209', 'VE', 'A1', '000029', '010', '1', 'GEN', '2026-01-25 12:00:00', 'LEGGING-SPORT', 'LEGGING-SPORT/NEGRO/S', 'Legging Negro S', 'S', 2.000000, 8.000000, 16.000000, 8.000000, NULL, '305', NULL, 'S', '2026-02-17 06:21:32', '2026-01-25 12:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('210', 'VE', 'A1', '000029', '020', '1', 'GEN', '2026-01-25 12:00:00', 'SOMBRERO-PJM', 'SOMBRERO-PJM', 'Sombrero Panama', 'S', 1.000000, 15.000000, 15.000000, 15.000000, NULL, '305', NULL, 'S', '2026-02-17 06:21:32', '2026-01-25 12:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('211', 'VE', 'A1', '000030', '010', '1', 'GEN', '2026-01-28 09:00:00', 'SUDADERA-HOOD', 'SUDADERA-HOOD/GRIS/S', 'Sudadera Gris S', 'S', 12.000000, 20.000000, 240.000000, 20.000000, NULL, '310', NULL, 'S', '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('212', 'VE', 'A1', '000030', '020', '1', 'GEN', '2026-01-28 09:00:00', 'LEGGING-SPORT', 'LEGGING-SPORT/ROSA/S', 'Legging Rosa S', 'S', 15.000000, 8.000000, 120.000000, 8.000000, NULL, '310', NULL, 'S', '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('213', 'VE', 'A1', '000030', '030', '1', 'GEN', '2026-01-28 09:00:00', 'CAMI-POLO', 'CAMI-POLO/BLANCO/M', 'Polo Blanco M', 'S', 10.000000, 12.000000, 120.000000, 12.000000, NULL, '310', NULL, 'S', '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('214', 'VE', 'A1', '000030', '040', '1', 'GEN', '2026-01-28 09:00:00', 'MOCHILA-SPORT', 'MOCHILA-SPORT', 'Mochila Deportiva', 'S', 8.000000, 18.000000, 144.000000, 18.000000, NULL, '310', NULL, 'S', '2026-02-17 06:21:32', '2026-01-28 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('215', 'VE', 'A1', '000031', '010', '1', 'GEN', '2026-02-03 11:30:00', 'VEST-FLOR', 'VEST-FLOR/AZUL/S', 'Vestido Flores Azul S', 'S', 1.000000, 10.000000, 10.000000, 10.000000, NULL, 'PUBLICO', NULL, 'S', '2026-02-17 06:21:32', '2026-02-03 11:30:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('216', 'VE', 'A1', '000031', '020', '1', 'GEN', '2026-02-03 11:30:00', 'CINTURON-PIEL', 'CINTURON-PIEL', 'Cinturón Piel', 'S', 1.000000, 9.000000, 9.000000, 9.000000, NULL, 'PUBLICO', NULL, 'S', '2026-02-17 06:21:32', '2026-02-03 11:30:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('217', 'VE', 'A1', '000032', '010', '1', 'GEN', '2026-02-05 16:00:00', 'ZAP-BOTA-MT', 'ZAP-BOTA-MT/NEGRO/42', 'Bota Montana Neg 42', 'S', 1.000000, 42.000000, 42.000000, 42.000000, NULL, '318', NULL, 'S', '2026-02-17 06:21:32', '2026-02-05 16:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('218', 'VE', 'A1', '000032', '020', '1', 'GEN', '2026-02-05 16:00:00', 'MOCHILA-SPORT', 'MOCHILA-SPORT', 'Mochila Deportiva', 'S', 1.000000, 18.000000, 18.000000, 18.000000, NULL, '318', NULL, 'S', '2026-02-17 06:21:32', '2026-02-05 16:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('219', 'VE', 'A1', '000033', '010', '1', 'GEN', '2026-02-07 18:00:00', 'VEST-FLOR', 'VEST-FLOR/ROJO/M', 'Vestido Flores Rojo M', 'S', 3.000000, 10.000000, 30.000000, 10.000000, NULL, '319', NULL, 'S', '2026-02-17 06:21:32', '2026-02-07 18:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('220', 'VE', 'A1', '000034', '010', '1', 'GEN', '2026-02-08 10:15:00', 'CAMI-POLO', 'CAMI-POLO/AZUL/L', 'Polo Azul L', 'S', 1.000000, 12.000000, 12.000000, 12.000000, NULL, 'PUBLICO', NULL, 'S', '2026-02-17 06:21:32', '2026-02-08 10:15:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('221', 'VE', 'A1', '000034', '020', '1', 'GEN', '2026-02-08 10:15:00', 'ZAP-DEPOR', 'ZAP-DEPOR/BLANCO/43', 'Zap Depor Blanco 43', 'S', 1.000000, 30.000000, 0.000000, 0.000000, NULL, 'PUBLICO', NULL, 'S', '2026-02-17 06:21:32', '2026-02-08 10:15:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('222', 'VE', 'A1', '000035', '010', '1', 'GEN', '2026-02-10 09:00:00', 'ABRIGO-PAÑO', 'ABRIGO-PAÑO/CAMEL/L', 'Abrigo Camel L', 'S', 2.000000, 80.000000, 160.000000, 80.000000, NULL, '313', NULL, 'S', '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('223', 'VE', 'A1', '000035', '020', '1', 'GEN', '2026-02-10 09:00:00', 'JERSEY-LANA', 'JERSEY-LANA/GRIS/L', 'Jersey Gris L', 'S', 4.000000, 25.000000, 100.000000, 25.000000, NULL, '313', NULL, 'S', '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('224', 'VE', 'A1', '000035', '030', '1', 'GEN', '2026-02-10 09:00:00', 'BOLSO-PIEL', 'BOLSO-PIEL', 'Bolso Piel Señora', 'S', 2.000000, 45.000000, 90.000000, 45.000000, NULL, '313', NULL, 'S', '2026-02-17 06:21:32', '2026-02-10 09:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('3', 'IN', 'A1', '2026001', '004', '1', 'GEN', '2026-01-04 22:13:10', 'FALD-PLIS', 'FALD-PLIS/VERDE/S', 'Falda Plisada S Verde', 'E', 20.000000, 12.000000, 240.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:40:44', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('4', 'IN', 'A1', '2026001', '005', '1', 'GEN', '2026-01-04 22:13:10', 'FALD-JEAN', 'FALD-JEAN/VAQUERO/L', 'Falda Vaquera L', 'E', 15.000000, 10.000000, 150.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:40:50', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('5', 'IN', 'A1', '2026001', '006', '1', 'GEN', '2026-01-04 22:13:10', 'CHAQ-CUERO', 'CHAQ-CUERO/NEGRO/XL', 'Chaqueta Cuero XL Negra', 'E', 3.000000, 60.000000, 180.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:40:57', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);
INSERT INTO `fza_movimientos_almacen` VALUES ('6', 'IN', 'A1', '2026001', '007', '1', 'GEN', '2026-01-04 22:13:10', 'CARTERA-PIEL', 'CARTERA-PIEL', 'Cartera de Cuero Unisex', 'E', 8.000000, 20.000000, 160.000000, 0.000000, NULL, NULL, NULL, 'S', '2026-01-08 18:44:09', '0000-00-00 00:00:00', 'DEMO', 'DEMO', NULL, NULL, NULL, NULL, '', NULL);

-- ----------------------------
-- Table structure for fza_paises
-- ----------------------------
DROP TABLE IF EXISTS `fza_paises`;
CREATE TABLE `fza_paises`  (
  `COD_PAIS` char(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `COD_PAIS_ALPHA3` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `COD_PAIS_ALPHA2` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_SPA_PAIS` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_ENG_PAIS` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESMIEMBRO_UE_PAIS` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'S SI ES MIEMBRO DE LA UE, N CUANDO NO LO ES',
  `ORDEN_PAIS` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`COD_PAIS`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_paises
-- ----------------------------
INSERT INTO `fza_paises` VALUES ('004', 'AFG', 'AF', 'Afganistán', 'Afghanistan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('008', 'ALB', 'AL', 'Albania', 'Albania', 'N', 999);
INSERT INTO `fza_paises` VALUES ('010', 'ATA', 'AQ', 'Antártida', 'Antartic', 'N', 999);
INSERT INTO `fza_paises` VALUES ('012', 'DZA', 'DZ', 'Argelia', 'Algeria', 'N', 999);
INSERT INTO `fza_paises` VALUES ('020', 'AND', 'AD', 'Andorra', 'Andorra', 'N', 999);
INSERT INTO `fza_paises` VALUES ('024', 'AGO', 'AO', 'Angola', 'Angola', 'N', 999);
INSERT INTO `fza_paises` VALUES ('028', 'ATG', 'AG', 'Antigua y Barbuda', 'Antigua and Barbuda', 'N', 999);
INSERT INTO `fza_paises` VALUES ('031', 'AZE', 'AZ', 'Azerbaiyán', 'Azerbaijan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('032', 'ARG', 'AR', 'Argentina', 'Argentina', 'N', 999);
INSERT INTO `fza_paises` VALUES ('036', 'AUS', 'AU', 'Australia', 'Australia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('040', 'AUT', 'AT', 'Austria', 'Austria', 'S', 999);
INSERT INTO `fza_paises` VALUES ('044', 'BHS', 'BS', 'Bahamas', 'Bahamas', 'N', 999);
INSERT INTO `fza_paises` VALUES ('048', 'BHR', 'BH', 'Baréin', 'Bahrain', 'N', 999);
INSERT INTO `fza_paises` VALUES ('050', 'BGD', 'BD', 'Bangladés', 'Bangladesh', 'N', 999);
INSERT INTO `fza_paises` VALUES ('051', 'ARM', 'AM', 'Armenia', 'Armenia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('052', 'BRB', 'BB', 'Barbados', 'Barbados', 'N', 999);
INSERT INTO `fza_paises` VALUES ('056', 'BEL', 'BE', 'Bélgica', 'Belgium', 'S', 999);
INSERT INTO `fza_paises` VALUES ('060', 'BMU', 'BM', 'Bermudas', 'Bermuda', 'N', 999);
INSERT INTO `fza_paises` VALUES ('064', 'BTN', 'BT', 'Bután', 'Bhutan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('068', 'BOL', 'BO', 'Bolivia', 'Bolivia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('070', 'BIH', 'BA', 'Bosnia y Herzegovina', 'Bosnia and Herzegovina', 'N', 999);
INSERT INTO `fza_paises` VALUES ('072', 'BWA', 'BW', 'Botsuana', 'Botswana', 'N', 999);
INSERT INTO `fza_paises` VALUES ('074', 'BVT', 'BV', 'Isla Bouvet', 'Bouvet Island ', 'N', 999);
INSERT INTO `fza_paises` VALUES ('076', 'BRA', 'BR', 'Brasil', 'Brazil', 'N', 999);
INSERT INTO `fza_paises` VALUES ('084', 'BLZ', 'BZ', 'Belice', 'Belize', 'N', 999);
INSERT INTO `fza_paises` VALUES ('086', 'IOT', 'IO', 'Territorio Británico del Océano Índico', 'British Indian Ocean Territory', 'N', 999);
INSERT INTO `fza_paises` VALUES ('090', 'SLB', 'SB', 'Islas Salomón', 'Solomon Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('092', 'VGB', 'VG', 'Islas Vírgenes (UK)', 'Virgin Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('096', 'BRN', 'BN', 'Brunéi', 'Brunei', 'N', 999);
INSERT INTO `fza_paises` VALUES ('100', 'BGR', 'BG', 'Bulgaria', 'Bulgaria', 'S', 999);
INSERT INTO `fza_paises` VALUES ('104', 'MMR', 'MM', 'Birmania', 'Myanmar', 'N', 999);
INSERT INTO `fza_paises` VALUES ('108', 'BDI', 'BI', 'Burundi', 'Burundi', 'N', 999);
INSERT INTO `fza_paises` VALUES ('112', 'BLR', 'BY', 'Bielorrusia', 'Belarus', 'N', 999);
INSERT INTO `fza_paises` VALUES ('116', 'KHM', 'KH', 'Camboya', 'Cambodia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('120', 'CMR', 'CM', 'Camerún', 'Cameroon', 'N', 999);
INSERT INTO `fza_paises` VALUES ('124', 'CAN', 'CA', 'Canadá', 'Canada', 'N', 999);
INSERT INTO `fza_paises` VALUES ('132', 'CPV', 'CV', 'Cabo Verde', 'Cape Verde', 'N', 999);
INSERT INTO `fza_paises` VALUES ('136', 'CYM', 'KY', 'Islas Caimán', 'Cayman Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('140', 'CAF', 'CF', 'República Centroafricana', 'Central African Republic', 'N', 999);
INSERT INTO `fza_paises` VALUES ('144', 'LKA', 'LK', 'Sri Lanka', 'Sri Lanka', 'N', 999);
INSERT INTO `fza_paises` VALUES ('148', 'TCD', 'TD', 'Chad', 'Chad', 'N', 999);
INSERT INTO `fza_paises` VALUES ('152', 'CHL', 'CL', 'Chile', 'Chile', 'N', 999);
INSERT INTO `fza_paises` VALUES ('156', 'CHN', 'CN', 'China', 'China', 'N', 999);
INSERT INTO `fza_paises` VALUES ('158', 'TWN', 'TW', 'Taiwán', 'Taiwan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('162', 'CXR', 'CX', 'Isla de Navidad', 'Christmas Island', 'N', 999);
INSERT INTO `fza_paises` VALUES ('166', 'CCK', 'CC', 'Islas Cocos', 'Cocos Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('170', 'COL', 'CO', 'Colombia', 'Colombia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('174', 'COM', 'KM', 'Comoras', 'Comoros', 'N', 999);
INSERT INTO `fza_paises` VALUES ('175', 'MYT', 'YT', 'Mayotte', 'Mayotte', 'N', 999);
INSERT INTO `fza_paises` VALUES ('178', 'COG', 'CG', 'Congo', 'Congo', 'N', 999);
INSERT INTO `fza_paises` VALUES ('180', 'COD', 'CD', 'República Democrática del Congo', 'Democratic Republic of the Congo', 'N', 999);
INSERT INTO `fza_paises` VALUES ('184', 'COK', 'CK', 'Islas Cook', 'Cook Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('188', 'CRI', 'CR', 'Costa Rica', 'Costa Rica', 'N', 999);
INSERT INTO `fza_paises` VALUES ('191', 'HRV', 'HR', 'Croacia', 'Croatia', 'S', 999);
INSERT INTO `fza_paises` VALUES ('192', 'CUB', 'CU', 'Cuba', 'Cuba', 'N', 999);
INSERT INTO `fza_paises` VALUES ('196', 'CYP', 'CY', 'Chipre', 'Cyprus', 'S', 999);
INSERT INTO `fza_paises` VALUES ('203', 'CZE', 'CZ', 'República Checa', 'Czech Republic', 'S', 999);
INSERT INTO `fza_paises` VALUES ('204', 'BEN', 'BJ', 'Benín', 'Benin', 'N', 999);
INSERT INTO `fza_paises` VALUES ('208', 'DNK', 'DK', 'Dinamarca', 'Denmark', 'S', 999);
INSERT INTO `fza_paises` VALUES ('212', 'DMA', 'DM', 'Dominica', 'Dominica', 'N', 999);
INSERT INTO `fza_paises` VALUES ('214', 'DOM', 'DO', 'República Dominicana', 'Dominican Republic', 'N', 999);
INSERT INTO `fza_paises` VALUES ('218', 'ECU', 'EC', 'Ecuador', 'Ecuador', 'N', 999);
INSERT INTO `fza_paises` VALUES ('222', 'SLV', 'SV', 'El Salvador', 'El Salvador', 'N', 999);
INSERT INTO `fza_paises` VALUES ('226', 'GNQ', 'GQ', 'Guinea Ecuatorial', 'Equatorial Guinea', 'N', 999);
INSERT INTO `fza_paises` VALUES ('231', 'ETH', 'ET', 'Etiopía', 'Ethiopia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('232', 'ERI', 'ER', 'Eritrea', 'Eritrea', 'N', 999);
INSERT INTO `fza_paises` VALUES ('233', 'EST', 'EE', 'Estonia', 'Estonia', 'S', 999);
INSERT INTO `fza_paises` VALUES ('234', 'FRO', 'FO', 'Islas Feroe', 'Faroe Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('238', 'FLK', 'FK', 'Islas Malvinas', 'Falkland Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('239', 'SGS', 'GS', 'Georgia del Sur y las Islas Sandwich del Sur', 'South Georgia and the South Sandwich Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('242', 'FJI', 'FJ', 'Fiyi', 'Fiji', 'N', 999);
INSERT INTO `fza_paises` VALUES ('246', 'FIN', 'FI', 'Finlandia', 'Finland', 'S', 999);
INSERT INTO `fza_paises` VALUES ('248', 'ALA', 'AX', 'Islas Åland', 'Åland Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('250', 'FRA', 'FR', 'Francia', 'France', 'S', 3);
INSERT INTO `fza_paises` VALUES ('254', 'GUF', 'GF', 'Guayana Francesa', 'French Guiana', 'N', 999);
INSERT INTO `fza_paises` VALUES ('260', 'ATF', 'TF', 'Territorios Australes y Antárticos Franceses', 'French Southern and Antarctic Lands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('262', 'DJI', 'DJ', 'Yibuti', 'Djibouti', 'N', 999);
INSERT INTO `fza_paises` VALUES ('266', 'GAB', 'GA', 'Gabón', 'Gabon', 'N', 999);
INSERT INTO `fza_paises` VALUES ('268', 'GEO', 'GE', 'Georgia', 'Georgia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('270', 'GMB', 'GM', 'Gambia', 'Gambia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('276', 'DEU', 'DE', 'Alemania', 'Germany', 'S', 999);
INSERT INTO `fza_paises` VALUES ('288', 'GHA', 'GH', 'Ghana', 'Ghana', 'N', 999);
INSERT INTO `fza_paises` VALUES ('292', 'GIB', 'GI', 'Gibraltar', 'Gibraltar', 'N', 999);
INSERT INTO `fza_paises` VALUES ('296', 'KIR', 'KI', 'Kiribati', 'Kiribati', 'N', 999);
INSERT INTO `fza_paises` VALUES ('300', 'GRC', 'GR', 'Grecia', 'Greece', 'S', 999);
INSERT INTO `fza_paises` VALUES ('304', 'GRL', 'GL', 'Groenlandia', 'Greenland', 'N', 999);
INSERT INTO `fza_paises` VALUES ('308', 'GRD', 'GD', 'Granada', 'Grenada', 'N', 999);
INSERT INTO `fza_paises` VALUES ('312', 'GLP', 'GP', 'Guadalupe', 'Guadalupe', 'N', 999);
INSERT INTO `fza_paises` VALUES ('316', 'GUM', 'GU', 'Guam', 'Guam', 'N', 999);
INSERT INTO `fza_paises` VALUES ('320', 'GTM', 'GT', 'Guatemala', 'Guatemala', 'N', 999);
INSERT INTO `fza_paises` VALUES ('324', 'GIN', 'GN', 'Guinea', 'Guinea', 'N', 999);
INSERT INTO `fza_paises` VALUES ('328', 'GUY', 'GY', 'Guyana', 'Guiana', 'N', 999);
INSERT INTO `fza_paises` VALUES ('332', 'HTI', 'HT', 'Haití', 'Haiti', 'N', 999);
INSERT INTO `fza_paises` VALUES ('334', 'HMD', 'HM', 'Islas Heard y McDonald', 'Heard Island and McDonald Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('336', 'VAT', 'VA', 'Ciudad del Vaticano', 'Vatican City', 'N', 999);
INSERT INTO `fza_paises` VALUES ('340', 'HND', 'HN', 'Honduras', 'Honduras', 'N', 999);
INSERT INTO `fza_paises` VALUES ('344', 'HKG', 'HK', 'Hong Kong', 'Hong Kong', 'N', 999);
INSERT INTO `fza_paises` VALUES ('348', 'HUN', 'HU', 'Hungría', 'Hungary', 'S', 999);
INSERT INTO `fza_paises` VALUES ('352', 'ISL', 'IS', 'Islandia', 'Iceland', 'N', 999);
INSERT INTO `fza_paises` VALUES ('356', 'IND', 'IN', 'India', 'India', 'N', 999);
INSERT INTO `fza_paises` VALUES ('360', 'IDN', 'ID', 'Indonesia', 'Indonesia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('364', 'IRN', 'IR', 'Irán', 'Iran', 'N', 999);
INSERT INTO `fza_paises` VALUES ('368', 'IRQ', 'IQ', 'Irak', 'Iraq', 'N', 999);
INSERT INTO `fza_paises` VALUES ('372', 'IRL', 'IE', 'Irlanda', 'Ireland', 'S', 999);
INSERT INTO `fza_paises` VALUES ('376', 'ISR', 'IL', 'Israel', 'Israel', 'N', 999);
INSERT INTO `fza_paises` VALUES ('380', 'ITA', 'IT', 'Italia', 'Italy', 'S', 999);
INSERT INTO `fza_paises` VALUES ('384', 'CIV', 'CI', 'Costa de Marfil', 'Ivory Coast', 'N', 999);
INSERT INTO `fza_paises` VALUES ('388', 'JAM', 'JM', 'Jamaica', 'Jamaica', 'N', 999);
INSERT INTO `fza_paises` VALUES ('392', 'JPN', 'JP', 'Japón', 'Japan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('398', 'KAZ', 'KZ', 'Kazajistán', 'Kazakhstan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('400', 'JOR', 'JO', 'Jordania', 'Jordan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('404', 'KEN', 'KE', 'Kenia', 'Kenya', 'N', 999);
INSERT INTO `fza_paises` VALUES ('408', 'PRK', 'KP', 'Corea del Norte', 'North Korea', 'N', 999);
INSERT INTO `fza_paises` VALUES ('410', 'KOR', 'KR', 'Corea del Sur', 'South Korea', 'N', 999);
INSERT INTO `fza_paises` VALUES ('412', 'XXK', 'XK', 'Kosovo', 'Kosovo', 'N', 999);
INSERT INTO `fza_paises` VALUES ('414', 'KWT', 'KW', 'Kuwait', 'Kuwait', 'N', 999);
INSERT INTO `fza_paises` VALUES ('417', 'KGZ', 'KG', 'Kirguistán', 'Kyrgyzstan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('418', 'LAO', 'LA', 'Laos', 'Laos', 'N', 999);
INSERT INTO `fza_paises` VALUES ('422', 'LBN', 'LB', 'Líbano', 'Lebanon', 'N', 999);
INSERT INTO `fza_paises` VALUES ('426', 'LSO', 'LS', 'Lesoto', 'Lesotho', 'N', 999);
INSERT INTO `fza_paises` VALUES ('428', 'LVA', 'LV', 'Letonia', 'Latvia', 'S', 999);
INSERT INTO `fza_paises` VALUES ('430', 'LBR', 'LR', 'Liberia', 'Liberia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('434', 'LBY', 'LY', 'Libia', 'Libya', 'N', 999);
INSERT INTO `fza_paises` VALUES ('438', 'LIE', 'LI', 'Liechtenstein', 'Liechtenstein', 'N', 999);
INSERT INTO `fza_paises` VALUES ('440', 'LTU', 'LT', 'Lituania', 'Lithuania', 'S', 999);
INSERT INTO `fza_paises` VALUES ('442', 'LUX', 'LU', 'Luxemburgo', 'Luxembourg', 'S', 999);
INSERT INTO `fza_paises` VALUES ('446', 'MAC', 'MO', 'Macao', 'Macau', 'N', 999);
INSERT INTO `fza_paises` VALUES ('450', 'MDG', 'MG', 'Madagascar', 'Madagascar', 'N', 999);
INSERT INTO `fza_paises` VALUES ('454', 'MWI', 'MW', 'Malaui', 'Malawi', 'N', 999);
INSERT INTO `fza_paises` VALUES ('458', 'MYS', 'MY', 'Malasia', 'Malaysia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('462', 'MDV', 'MV', 'Maldivas', 'Maldives', 'N', 999);
INSERT INTO `fza_paises` VALUES ('466', 'MLI', 'ML', 'Malí', 'Mali', 'N', 999);
INSERT INTO `fza_paises` VALUES ('470', 'MLT', 'MT', 'Malta', 'Malta', 'S', 999);
INSERT INTO `fza_paises` VALUES ('474', 'MTK', 'MQ', 'Martinica', 'Martinique', 'N', 999);
INSERT INTO `fza_paises` VALUES ('478', 'MRT', 'MR', 'Mauritania', 'Mauritania', 'N', 999);
INSERT INTO `fza_paises` VALUES ('480', 'MUS', 'MU', 'Mauricio', 'Mauritius', 'N', 999);
INSERT INTO `fza_paises` VALUES ('484', 'MEX', 'MX', 'México', 'Mexico', 'N', 999);
INSERT INTO `fza_paises` VALUES ('492', 'MCO', 'MC', 'Mónaco', 'Monaco', 'N', 999);
INSERT INTO `fza_paises` VALUES ('496', 'MNG', 'MN', 'Mongolia', 'Mongolia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('498', 'MDA', 'MD', 'Moldavia', 'Moldova', 'N', 999);
INSERT INTO `fza_paises` VALUES ('499', 'MNE', 'ME', 'Montenegro', 'Montenegro', 'N', 999);
INSERT INTO `fza_paises` VALUES ('504', 'MAR', 'MA', 'Marruecos', 'Morocco', 'N', 999);
INSERT INTO `fza_paises` VALUES ('508', 'MOZ', 'MZ', 'Mozambique', 'Mozambique', 'N', 999);
INSERT INTO `fza_paises` VALUES ('512', 'OMN', 'OM', 'Omán', 'Oman', 'N', 999);
INSERT INTO `fza_paises` VALUES ('516', 'NAM', 'NA', 'Namibia', 'Namibia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('520', 'NRU', 'NR', 'Nauru', 'Nauru', 'N', 999);
INSERT INTO `fza_paises` VALUES ('524', 'NPL', 'NP', 'Nepal', 'Nepal', 'N', 999);
INSERT INTO `fza_paises` VALUES ('528', 'NLD', 'NL', 'Países Bajos', 'Netherlands', 'S', 999);
INSERT INTO `fza_paises` VALUES ('531', 'CUW', 'CW', 'Curaçao', 'Curaçao', 'N', 999);
INSERT INTO `fza_paises` VALUES ('533', 'ABW', 'AW', 'Aruba', 'Aruba', 'N', 999);
INSERT INTO `fza_paises` VALUES ('535', 'BES', 'BQ', 'Caribe Neerlandés', 'Caribbean netherlands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('548', 'VUT', 'VU', 'Vanuatu', 'Vanuatu', 'N', 999);
INSERT INTO `fza_paises` VALUES ('554', 'NZL', 'NZ', 'Nueva Zelanda', 'New Zealand', 'N', 999);
INSERT INTO `fza_paises` VALUES ('558', 'NIC', 'NI', 'Nicaragua', 'Nicaragua', 'N', 999);
INSERT INTO `fza_paises` VALUES ('562', 'NER', 'NE', 'Níger', 'Niger', 'N', 999);
INSERT INTO `fza_paises` VALUES ('566', 'NGA', 'NG', 'Nigeria', 'Nigeria', 'N', 999);
INSERT INTO `fza_paises` VALUES ('574', 'NFK', 'NF', 'Isla Nor Folk', 'Norfolk Island', 'N', 999);
INSERT INTO `fza_paises` VALUES ('578', 'NOR', 'NO', 'Noruega', 'Norway', 'N', 999);
INSERT INTO `fza_paises` VALUES ('580', 'MNP', 'MP', 'Islas Marianas del Norte', 'Northern Mariana Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('581', 'UMI', 'UM', 'Islas ultramarinas menores de los Estados Unidos', 'United States Minor Outlying Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('583', 'FSM', 'FM', 'Micronesia', 'Micronesia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('584', 'MHL', 'MH', 'Islas Marshall', 'Marshall Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('585', 'PLW', 'PW', 'Palaos', 'Palau', 'N', 999);
INSERT INTO `fza_paises` VALUES ('586', 'PAK', 'PK', 'Pakistán', 'Pakistan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('591', 'PAN', 'PA', 'Panamá', 'Panama', 'N', 999);
INSERT INTO `fza_paises` VALUES ('598', 'PNG', 'PG', 'Papúa Nueva Guinea', 'Papua New Guinea', 'N', 999);
INSERT INTO `fza_paises` VALUES ('600', 'PRY', 'PY', 'Paraguay', 'Paraguay', 'N', 999);
INSERT INTO `fza_paises` VALUES ('604', 'PER', 'PE', 'Perú', 'Peru', 'N', 999);
INSERT INTO `fza_paises` VALUES ('608', 'PHL', 'PH', 'Filipinas', 'Philippines', 'N', 999);
INSERT INTO `fza_paises` VALUES ('612', 'PCN', 'PN', 'Islas Pitcairn', 'Pitcairn Island', 'N', 999);
INSERT INTO `fza_paises` VALUES ('616', 'POL', 'PL', 'Polonia', 'Poland', 'S', 999);
INSERT INTO `fza_paises` VALUES ('620', 'PRT', 'PT', 'Portugal', 'Portugal', 'S', 2);
INSERT INTO `fza_paises` VALUES ('624', 'GNB', 'GW', 'Guinea-Bisáu', 'Guinea-Bissau', 'N', 999);
INSERT INTO `fza_paises` VALUES ('626', 'TLS', 'TL', 'Timor Oriental', 'East Timor', 'N', 999);
INSERT INTO `fza_paises` VALUES ('634', 'QAT', 'QA', 'Catar', 'Qatar', 'N', 999);
INSERT INTO `fza_paises` VALUES ('642', 'ROU', 'RO', 'Rumania', 'Romania', 'S', 999);
INSERT INTO `fza_paises` VALUES ('643', 'RUS', 'RU', 'Rusia', 'Russia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('646', 'RWA', 'RW', 'Ruanda', 'Rwanda', 'N', 999);
INSERT INTO `fza_paises` VALUES ('659', 'KNA', 'KN', 'San Cristóbal y Nieves', 'Saint Kitts and Nevis', 'N', 999);
INSERT INTO `fza_paises` VALUES ('660', 'AIA', 'AI', 'Anguila', 'Anguila', 'N', 999);
INSERT INTO `fza_paises` VALUES ('662', 'LCA', 'LC', 'Santa Lucía', 'Saint Lucia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('663', 'MAF', 'MF', 'Isla de San Martín', 'Island of Saint Martin', 'N', 999);
INSERT INTO `fza_paises` VALUES ('670', 'VCT', 'VC', 'San Vicente y las Granadinas', 'Saint Vincent and the Grenadines', 'N', 999);
INSERT INTO `fza_paises` VALUES ('674', 'SMR', 'SM', 'San Marino', 'San Marino', 'N', 999);
INSERT INTO `fza_paises` VALUES ('678', 'STP', 'ST', 'Santo Tomé y Príncipe', 'Sao Tome and Principe', 'N', 999);
INSERT INTO `fza_paises` VALUES ('682', 'SAU', 'SA', 'Arabia Saudita', 'Saudi Arabia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('686', 'SEN', 'SN', 'Senegal', 'Senegal', 'N', 999);
INSERT INTO `fza_paises` VALUES ('688', 'SRB', 'RS', 'Serbia', 'Serbia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('690', 'SYC', 'SC', 'Seychelles', 'Seychelles', 'N', 999);
INSERT INTO `fza_paises` VALUES ('694', 'SLE', 'SL', 'Sierra Leona', 'Sierra Leone', 'N', 999);
INSERT INTO `fza_paises` VALUES ('702', 'SGP', 'SG', 'Singapur', 'Singapore', 'N', 999);
INSERT INTO `fza_paises` VALUES ('703', 'SVK', 'SK', 'Eslovaquia', 'Slovakia', 'S', 999);
INSERT INTO `fza_paises` VALUES ('704', 'VNM', 'VN', 'Vietnam', 'Vietnam', 'N', 999);
INSERT INTO `fza_paises` VALUES ('705', 'SVN', 'SI', 'Eslovenia', 'Slovenia', 'S', 999);
INSERT INTO `fza_paises` VALUES ('706', 'SOM', 'SO', 'Somalia', 'Somalia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('710', 'ZAF', 'ZA', 'Sudáfrica', 'South Africa', 'N', 999);
INSERT INTO `fza_paises` VALUES ('716', 'ZWE', 'ZW', 'Zimbabue', 'Zimbabwe', 'N', 999);
INSERT INTO `fza_paises` VALUES ('724', 'ESP', 'ES', 'España', 'Spain', 'S', 1);
INSERT INTO `fza_paises` VALUES ('728', 'SSD', 'SS', 'Sudán del Sur', 'South Sudan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('729', 'SDN', 'SD', 'Sudán', 'Sudan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('740', 'SUR', 'SR', 'Surinam', 'Suriname', 'N', 999);
INSERT INTO `fza_paises` VALUES ('748', 'SWZ', 'SZ', 'Suazilandia', 'Eswatini', 'N', 999);
INSERT INTO `fza_paises` VALUES ('752', 'SWE', 'SE', 'Suecia', 'Sweden', 'S', 999);
INSERT INTO `fza_paises` VALUES ('756', 'CHE', 'CH', 'Suiza', 'Switzerland', 'N', 999);
INSERT INTO `fza_paises` VALUES ('760', 'SYR', 'SY', 'Siria', 'Syria', 'N', 999);
INSERT INTO `fza_paises` VALUES ('762', 'TJK', 'TJ', 'Tayikistán', 'Tajikistan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('764', 'THA', 'TH', 'Tailandia', 'Thailand', 'N', 999);
INSERT INTO `fza_paises` VALUES ('768', 'TGO', 'TG', 'Togo', 'Togo', 'N', 999);
INSERT INTO `fza_paises` VALUES ('772', 'TKL', 'TK', 'Tokelau', 'Tokelau', 'N', 999);
INSERT INTO `fza_paises` VALUES ('776', 'TON', 'TO', 'Tonga', 'Tonga', 'N', 999);
INSERT INTO `fza_paises` VALUES ('780', 'TTO', 'TT', 'Trinidad y Tobago', 'Trinidad and Tobago', 'N', 999);
INSERT INTO `fza_paises` VALUES ('784', 'ARE', 'AE', 'Emiratos Árabes Unidos', 'United Arab Emirates', 'N', 999);
INSERT INTO `fza_paises` VALUES ('788', 'TUN', 'TN', 'Túnez', 'Tunisia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('792', 'TUR', 'TR', 'Turquía', 'Turkey', 'N', 999);
INSERT INTO `fza_paises` VALUES ('795', 'TKM', 'TM', 'Turkmenistán', 'Turkmenistan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('796', 'TCA', 'TC', 'Islas Turcas y Caicos', 'Turks and Caicos Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('798', 'TUV', 'TV', 'Tuvalu', 'Tuvalu', 'N', 999);
INSERT INTO `fza_paises` VALUES ('800', 'UGA', 'UG', 'Uganda', 'Uganda', 'N', 999);
INSERT INTO `fza_paises` VALUES ('804', 'UKR', 'UA', 'Ucrania', 'Ukraine', 'N', 999);
INSERT INTO `fza_paises` VALUES ('807', 'MKD', 'MK', 'Macedonia del Norte', 'North Macedonia', 'N', 999);
INSERT INTO `fza_paises` VALUES ('818', 'EGY', 'EG', 'Egipto', 'Egypt', 'N', 999);
INSERT INTO `fza_paises` VALUES ('826', 'GBR', 'GB', 'Reino Unido', 'United Kingdom', 'N', 999);
INSERT INTO `fza_paises` VALUES ('831', 'GGY', 'GG', 'Bailía de Guernsey', 'Bailiwick of Guernsey', 'N', 999);
INSERT INTO `fza_paises` VALUES ('832', 'JEY', 'JE', 'Jersey', 'Bailiwick of Jersey', 'N', 999);
INSERT INTO `fza_paises` VALUES ('833', 'IMN', 'IM', 'Isla de Man', 'Isle of Man', 'N', 999);
INSERT INTO `fza_paises` VALUES ('834', 'TZA', 'TZ', 'Tanzania', 'Tanzania', 'N', 999);
INSERT INTO `fza_paises` VALUES ('840', 'USA', 'US', 'Estados Unidos', 'United States', 'N', 999);
INSERT INTO `fza_paises` VALUES ('850', 'MNP', 'VI', 'Islas Marianas del Norte', 'Northern Mariana Islands', 'N', 999);
INSERT INTO `fza_paises` VALUES ('854', 'BFA', 'BF', 'Burkina Faso', 'Burkina Faso', 'N', 999);
INSERT INTO `fza_paises` VALUES ('858', 'URY', 'UY', 'Uruguay', 'Uruguay', 'N', 999);
INSERT INTO `fza_paises` VALUES ('860', 'UZB', 'UZ', 'Uzbekistán', 'Uzbekistan', 'N', 999);
INSERT INTO `fza_paises` VALUES ('862', 'VEN', 'VE', 'Venezuela', 'Venezuela', 'N', 999);
INSERT INTO `fza_paises` VALUES ('876', 'WLF', 'WF', 'Wallis y Futuna', 'Wallis and Futuna', 'N', 999);
INSERT INTO `fza_paises` VALUES ('882', 'WSM', 'WS', 'Samoa', 'Samoa', 'N', 999);
INSERT INTO `fza_paises` VALUES ('887', 'YEM', 'YE', 'Yemen', 'Yemen', 'N', 999);
INSERT INTO `fza_paises` VALUES ('894', 'ZMB', 'ZM', 'Zambia', 'Zambia', 'N', 999);

-- ----------------------------
-- Table structure for fza_pedidos
-- ----------------------------
DROP TABLE IF EXISTS `fza_pedidos`;
CREATE TABLE `fza_pedidos`  (
  `NRO_PEDIDO` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SERIE_PEDIDO` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `FECHA_PEDIDO` date NULL DEFAULT NULL,
  `CODIGO_EMPRESA_PEDIDO` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `RAZONSOCIAL_EMPRESA_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NIF_EMPRESA_PEDIDO` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_EMPRESA_PEDIDO` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_EMPRESA_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_EMPRESA_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_EMPRESA_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_EMPRESA_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_EMPRESA_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_EMPRESA_PEDIDO` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_EMPRESA_PEDIDO` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `CPOSTAL_EMPRESA_PEDIDO` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESRETENCIONES_EMPRESA_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'S o N si la empresa aplica retenciones como autónomos',
  `GRUPO_ZONA_IVA_EMPRESA_PEDIDO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESREGIMENESPECIALAGRICOLA_EMPRESA_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `CODIGO_CLIENTE_PEDIDO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NIF_CLIENTE_PEDIDO` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_CLIENTE_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `REFERENCIAPS_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IDPS_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHAPS_PEDIDO` datetime NULL DEFAULT NULL,
  `FORMAPAGOPS_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TRANSPORTISTAPS_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESTADOPEDIDOPS_PEDIDO` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESTADOMENSAJEPS_PEDIDO` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IDHILOPS_MENSAJES_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_CLIENTE_ENVIO_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_CLIENTE_ENVIO_PEDIDO` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_CLIENTE_ENVIO_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_CLIENTE_ENVIO_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_CLIENTE_ENVIO_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_CLIENTE_ENVIO_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_CLIENTE_ENVIO_PEDIDO` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_CLIENTE_ENVIO_PEDIDO` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_CLIENTE_ENVIO_PEDIDO` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `RAZONSOCIAL_CLIENTE_FISCAL_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_CLIENTE_FISCAL_PEDIDO` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_CLIENTE_FISCAL_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_CLIENTE_FISCAL_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_CLIENTE_FISCAL_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_CLIENTE_FISCAL_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_CLIENTE_FISCAL_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_CLIENTE_FISCAL_PEDIDO` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_CLIENTE_FISCAL_PEDIDO` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_CLIENTE_FISCAL_PEDIDO` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `ESIVA_RECARGO_CLIENTE_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESIVA_EXENTO_CLIENTE_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESREGIMENESPECIALAGRICOLA_CLIENTE_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `ESRETENCIONES_CLIENTE_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'S o N Si el cliente aplica retenciones',
  `TARIFA_ARTICULO_CLIENTE_PEDIDO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código de la tarifa que viene del cliente o configurada por el usuario',
  `ESIMP_INCL_TARIFA_CLIENTE_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'Si el precio de la tarifa del cliente es con impuestos incl o no',
  `ESINTRACOMUNITARIO_CLIENTE_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si la venta es hacia un país de la UE',
  `ESIRPF_IMP_INCL_ZONA_IVA_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si la base del cáculo del irpf se hace desde BI o BI con impuestos',
  `ESAPLICA_RE_ZONA_IVA_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'Si el tipo de IVA aplica Recargo de Equivalencia o no',
  `ESIVAAGRICOLA_ZONA_IVA_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Si el tipo de IVA es compatible con REAGP',
  `PALABRA_REPORTS_ZONA_IVA_PEDIDO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'IVA' COMMENT 'Palabra que sustituye a IVA desde la tabla de fza_ivas_grupos',
  `CODIGO_IVA_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Código de IVA de la tabla fza_ivas',
  `ESVENTA_ACTIVO_FIJO_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N' COMMENT 'Sólo REAGP cuando se vende activos fijos, exime irpf',
  `PORCEN_IVAN_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Normal',
  `TOTAL_IVAN_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total IVA Normal',
  `PORCEN_REN_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Normal',
  `TOTAL_REN_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE Normal',
  `TOTAL_BASEI_IVAN_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Normal',
  `PORCEN_IVAR_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Reducido',
  `TOTAL_IVAR_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'TotaL IVA Reducido',
  `PORCEN_RER_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Reducido',
  `TOTAL_RER_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE Reducido',
  `TOTAL_BASEI_IVAR_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Reducido',
  `PORCEN_IVAS_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido',
  `TOTAL_IVAS_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total IVA SuperReducido',
  `PORCEN_RES_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido',
  `TOTAL_RES_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE SuperReducido',
  `TOTAL_BASEI_IVAS_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total sin IVA SuperReducido',
  `PORCEN_IVAE_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Exento',
  `TOTAL_IVAE_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total IVA Exento',
  `PORCEN_REE_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA1 Exento',
  `TOTAL_REE_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Total RE Exento',
  `TOTAL_BASEI_IVAE_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total sin IVA Exento',
  `TOTAL_BASES_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Todas las bases imponibles',
  `TOTAL_IMPUESTOS_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total de todos los impuestos iva + re',
  `FORMA_PAGO_PEDIDO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Codigo Forma de Pago',
  `PORCEN_RETENCION_PEDIDO` decimal(19, 6) NULL DEFAULT NULL COMMENT 'Porcentaje Retenciones',
  `TOTAL_RETENCION_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total Retenciones PEDIDO',
  `TOTAL_LIQUIDO_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total PEDIDO a pagar',
  `TOTAL_PAGADOREALPS_PEDIDO` decimal(18, 6) NULL DEFAULT NULL COMMENT 'Total pagado cliente',
  `NRO_PEDIDO_ABONO_PEDIDO` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Nro PEDIDO Abono',
  `SERIE_PEDIDO_ABONO_PEDIDO` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Serie PEDIDO Abono',
  `TEXTO_LEGAL_PEDIDO_CLIENTE_PEDIDO` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '',
  `TEXTO_LEGAL_PEDIDO_EMPRESA_PEDIDO` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '',
  `DOCUMENTO_PEDIDO` blob NULL DEFAULT NULL COMMENT 'Copia en PDF del documento final',
  `COMENTARIOS_PEDIDO` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '',
  `CONTADOR_LINEAS_PEDIDO` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Contador de lineas para lineas de PEDIDO',
  `ESCREARARTICULOS_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'S o N si se crean articulos desde el detalle',
  `ESDESCRIPCIONES_AMP_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S' COMMENT 'S o N si la PEDIDO contiene una descripción larga',
  `ESFECHADEENTREGA_PEDIDO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'S o N si las descripciones tienen fecha de entrega',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`SERIE_PEDIDO`, `NRO_PEDIDO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_pedidos
-- ----------------------------
INSERT INTO `fza_pedidos` VALUES ('000001', 'PED', '2026-02-12', '1', 'MODA EJEMPLO SL', 'B11111111', NULL, NULL, NULL, NULL, NULL, NULL, '724', 'España', NULL, 'N', NULL, 'N', '317', 'B99887766', 'admin@importamoda.es', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'IMPORTACIONES LA MODA SL', NULL, 'C/ ARTESANOS, 20 NAVE 3', NULL, 'ALCOBENDAS', 'MADRID', '28108', '724', 'España', 'IMPORTACIONES LA MODA SL', NULL, NULL, 'C/ ARTESANOS, 20 NAVE 3', NULL, 'ALCOBENDAS', 'MADRID', '28108', '724', 'España', 'N', 'N', 'N', 'S', 'VENTAMAYOR', 'S', 'N', 'N', 'S', 'N', 'IVA', NULL, 'N', 21.000000, 100.800000, NULL, NULL, 480.000000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 480.000000, 100.800000, '30DIAS', NULL, NULL, 580.800000, NULL, NULL, NULL, '', '', NULL, 'Pedido urgente - Reposición colección primavera', NULL, NULL, 'S', NULL, '2026-02-17 06:21:32', '2026-02-12 10:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos` VALUES ('000002', 'PED', '2026-02-13', '1', 'MODA EJEMPLO SL', 'B11111111', NULL, NULL, NULL, NULL, NULL, NULL, '724', 'España', NULL, 'N', NULL, 'N', '320', 'B55443322', 'compras@modaspain.es', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'TIENDAS MODA SPAIN SL', NULL, 'GRAN VÍA, 48', NULL, 'MADRID', 'MADRID', '28013', '724', 'España', 'TIENDAS MODA SPAIN SL', NULL, NULL, 'GRAN VÍA, 48', NULL, 'MADRID', 'MADRID', '28013', '724', 'España', 'N', 'N', 'N', 'S', 'VENTAMAYOR', 'S', 'N', 'N', 'S', 'N', 'IVA', NULL, 'N', 21.000000, 176.400000, NULL, NULL, 840.000000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 840.000000, 176.400000, '60DIAS', NULL, NULL, 1016.400000, NULL, NULL, NULL, '', '', NULL, 'Colección verano 2026 - 1ª entrega', NULL, NULL, 'S', NULL, '2026-02-17 06:21:32', '2026-02-13 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos` VALUES ('000003', 'PED', '2026-02-14', '1', 'MODA EJEMPLO SL', 'B11111111', NULL, NULL, NULL, NULL, NULL, NULL, '724', 'España', NULL, 'N', NULL, 'N', '304', '45678901D', 'juan.martin@empresa.es', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'JUAN MARTÍN PÉREZ', NULL, 'C/ ALCALÁ, 100', NULL, 'MADRID', 'MADRID', '28009', '724', 'España', 'JUAN MARTÍN PÉREZ', NULL, NULL, 'C/ ALCALÁ, 100', NULL, 'MADRID', 'MADRID', '28009', '724', 'España', 'N', 'N', 'N', 'S', 'VENTAMAYOR', 'S', 'N', 'N', 'S', 'N', 'IVA', NULL, 'N', 21.000000, 42.000000, NULL, NULL, 200.000000, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 200.000000, 42.000000, '60DIAS', NULL, NULL, 242.000000, NULL, NULL, NULL, '', '', NULL, '', NULL, NULL, 'S', NULL, '2026-02-17 06:21:32', '2026-02-14 11:00:00', 'DEMO', 'DEMO');

-- ----------------------------
-- Table structure for fza_pedidos_lineas
-- ----------------------------
DROP TABLE IF EXISTS `fza_pedidos_lineas`;
CREATE TABLE `fza_pedidos_lineas`  (
  `NRO_PEDIDO_LINEA` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SERIE_PEDIDO_LINEA` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `LINEA_PEDIDO_LINEA` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `IDLINEAPS_PEDIDO_LINEA` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IDPRODPS_PEDIDO_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGOPRODPS_PEDIDO_LINEA` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IDATRIBPRODPS_PEDIDO_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODEAN13PRODPS_PEDIDO_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_ARTICULO_PEDIDO_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_FAMILIA_PEDIDO_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NOMBRE_FAMILIA_PEDIDO_LINEA` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_ENTREGA_PEDIDO_LINEA` datetime NULL DEFAULT NULL,
  `TIPO_CANTIDAD_ARTICULO_PEDIDO_LINEA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'Uds',
  `ESIMP_INCL_TARIFA_PEDIDO_LINEA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `TIPOIVA_ARTICULO_PEDIDO_LINEA` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `DESCRIPCION_ARTICULO_PEDIDO_LINEA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_TARIFA_PEDIDO_LINEA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CANTIDAD_PEDIDO_LINEA` decimal(19, 6) NULL DEFAULT 1.000000,
  `PRECIOVENTA_SIVA_ARTICULO_PEDIDO_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `PORCEN_IVA_PEDIDO_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `PRECIOVENTA_CIVA_ARTICULO_PEDIDO_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `TOTAL_PEDIDO_LINEA` decimal(19, 6) NULL DEFAULT 0.000000,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`SERIE_PEDIDO_LINEA`, `NRO_PEDIDO_LINEA`, `LINEA_PEDIDO_LINEA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_pedidos_lineas
-- ----------------------------
INSERT INTO `fza_pedidos_lineas` VALUES ('000001', 'PED', '010', NULL, NULL, NULL, NULL, NULL, 'SUDADERA-HOOD', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Sudadera con Capucha Negro L', NULL, 10.000000, 28.000000, 21.000000, 0.000000, 280.000000, '2026-02-17 06:21:32', '2026-02-12 10:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000001', 'PED', '020', NULL, NULL, NULL, NULL, NULL, 'LEGGING-SPORT', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Legging Deportivo Negro M', NULL, 20.000000, 12.000000, 21.000000, 0.000000, 240.000000, '2026-02-17 06:21:32', '2026-02-12 10:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000001', 'PED', '030', NULL, NULL, NULL, NULL, NULL, 'CAMI-POLO', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Polo Manga Corta Blanco S', NULL, 10.000000, 18.000000, 21.000000, 0.000000, 180.000000, '2026-02-17 06:21:32', '2026-02-12 10:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000002', 'PED', '010', NULL, NULL, NULL, NULL, NULL, 'VEST-FLOR', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Vestido Estampado Verano Azul S', NULL, 15.000000, 12.000000, 21.000000, 0.000000, 180.000000, '2026-02-17 06:21:32', '2026-02-13 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000002', 'PED', '020', NULL, NULL, NULL, NULL, NULL, 'VEST-FLOR', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Vestido Estampado Verano Rojo M', NULL, 15.000000, 12.000000, 21.000000, 0.000000, 180.000000, '2026-02-17 06:21:32', '2026-02-13 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000002', 'PED', '030', NULL, NULL, NULL, NULL, NULL, 'BLUS-SEDA', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Blusa de Seda Cuello V', NULL, 10.000000, 22.000000, 21.000000, 0.000000, 220.000000, '2026-02-17 06:21:32', '2026-02-13 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000002', 'PED', '040', NULL, NULL, NULL, NULL, NULL, 'FALD-PLIS', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Falda Larga Plisada Blanco M', NULL, 10.000000, 18.000000, 21.000000, 0.000000, 180.000000, '2026-02-17 06:21:32', '2026-02-13 09:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000003', 'PED', '010', NULL, NULL, NULL, NULL, NULL, 'ABRIGO-PAÑO', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Abrigo de Paño Negro XL', NULL, 1.000000, 120.000000, 21.000000, 0.000000, 120.000000, '2026-02-17 06:21:32', '2026-02-14 11:00:00', 'DEMO', 'DEMO');
INSERT INTO `fza_pedidos_lineas` VALUES ('000003', 'PED', '020', NULL, NULL, NULL, NULL, NULL, 'ZAP-BOTA-MT', NULL, NULL, NULL, 'Uds', 'S', 'N', 'Bota Montaña Marrón 43', NULL, 1.000000, 60.000000, 21.000000, 0.000000, 60.000000, '2026-02-17 06:21:32', '2026-02-14 11:00:00', 'DEMO', 'DEMO');

-- ----------------------------
-- Table structure for fza_pedidos_mensajes
-- ----------------------------
DROP TABLE IF EXISTS `fza_pedidos_mensajes`;
CREATE TABLE `fza_pedidos_mensajes`  (
  `IDPS_MENSAJES_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `IDMENSAJEPS_MENSAJE_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IDEMPLEADOPS_MENSAJE_PEDIDO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MENSAJEPS_MENSAJE_PEDIDO` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHAPS_MENSAJE_PEDIDO` datetime NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`IDPS_MENSAJES_PEDIDO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_pedidos_mensajes
-- ----------------------------

-- ----------------------------
-- Table structure for fza_proveedores
-- ----------------------------
DROP TABLE IF EXISTS `fza_proveedores`;
CREATE TABLE `fza_proveedores`  (
  `CODIGO_PROVEEDOR` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ACTIVO_PROVEEDOR` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ORDEN_PROVEEDOR` int(11) NULL DEFAULT NULL,
  `RAZONSOCIAL_PROVEEDOR` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `NIF_PROVEEDOR` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MOVIL_PROVEEDOR` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMAIL_PROVEEDOR` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_PROVEEDOR` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION2_PROVEEDOR` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_PROVEEDOR` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_PROVEEDOR` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_PROVEEDOR` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PAIS_PROVEEDOR` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `OBSERVACIONES_PROVEEDOR` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `REFERENCIA_PROVEEDOR` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CONTACTO_PROVEEDOR` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TELEFONO_CONTACTO_PROVEEDOR` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TELEFONO_PROVEEDOR` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `IBAN_PROVEEDOR` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_PROVEEDOR`) USING BTREE,
  INDEX `IDX_PROVEEDORES_LISTADO`(`CODIGO_PROVEEDOR` ASC, `RAZONSOCIAL_PROVEEDOR` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_proveedores
-- ----------------------------
INSERT INTO `fza_proveedores` VALUES ('000', 'S', NULL, 'ANTONIO BAZOS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-18 12:05:44', '2024-10-06 20:26:38', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('010', 'S', NULL, 'RODRIGO ANTON', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-10 17:34:42', '2024-10-06 21:17:37', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('10', 'S', NULL, 'Gai pâturage', NULL, '38.76.98.06', NULL, 'Bat. B 3, rue des Alpes', NULL, 'Annecy', '', '74000', 'France', NULL, NULL, 'Eliane Noz', NULL, NULL, NULL, '2024-10-06 20:13:41', '2021-06-10 19:36:20', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('11', 'S', NULL, 'Escargots Nouveaux', NULL, '85.57.00.07', NULL, '22, rue H. Voiron', NULL, 'Montceau', '', '71300', 'France', NULL, NULL, 'Marie Delamare', NULL, NULL, NULL, '2021-06-10 19:36:25', '2021-06-10 19:36:25', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('12', 'S', NULL, 'Pasta Buttini s.r.l.', NULL, '(089) 6547665', NULL, 'Via dei Gelsomini, 153', NULL, 'Salerno', '', '84100', 'Italy', NULL, NULL, 'Giovanni Giudici', NULL, NULL, NULL, '2021-06-10 19:36:35', '2021-06-10 19:36:35', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('13', 'S', NULL, 'Ma Maison', NULL, '(514) 555-9022', NULL, '2960 Rue St. Laurent', NULL, 'Montréal', 'Québec', 'H1J 1C3', 'Canada', NULL, NULL, 'Jean-Guy Lauzon', NULL, NULL, NULL, '2021-06-10 19:36:46', '2021-06-10 19:36:46', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('14', 'S', NULL, 'Karkki Oy', NULL, '(953) 10956', NULL, 'Valtakatu 12', NULL, 'Lappeenranta', '', '53120', 'Finland', NULL, NULL, 'Anne Heikkonen', NULL, NULL, NULL, '2021-06-10 19:37:22', '2021-06-10 19:37:22', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('15', 'S', NULL, 'Leka Trading', NULL, '555-8787', NULL, '471 Serangoon Loop, Suite #402', NULL, 'Singapore', '', '0512', 'Singapore', NULL, NULL, 'Chandra Leka', NULL, NULL, NULL, '2021-06-10 19:37:28', '2021-06-10 19:37:28', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('16', 'S', NULL, 'Lyngbysild', NULL, '43844108', NULL, 'Lyngbysild Fiskebakken 10', NULL, 'Lyngby', '', '2800', 'Denmark', NULL, NULL, 'Niels Petersen', NULL, NULL, NULL, '2021-06-10 19:37:28', '2021-06-10 19:37:28', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('17', 'S', NULL, 'Zaanse Snoepfabriek', NULL, '(12345) 1212', NULL, 'Verkoop Rijnweg 22', NULL, 'Zaandam', '', '9999 ZZ', 'Netherlands', NULL, NULL, 'Dirk Luchte', NULL, NULL, NULL, '2021-06-10 19:37:28', '2021-06-10 19:37:28', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('18', 'S', NULL, 'Formaggi Fortini s.r.l.', NULL, '(0544) 60323', NULL, 'Viale Dante, 75', NULL, 'Ravenna', '', '48100', 'Italy', NULL, NULL, 'Elio Rossi', NULL, NULL, NULL, '2021-06-10 19:37:39', '2021-06-10 19:37:39', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('19', 'S', NULL, 'Norske Meierier', NULL, '(0)2-953010', NULL, 'Hatlevegen 5', NULL, 'Sandvika', '', '1320', 'Norway', NULL, NULL, 'Beate Vileid', NULL, NULL, NULL, '2021-06-10 19:37:39', '2021-06-10 19:37:39', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('20', 'S', NULL, 'Bigfoot Breweries', NULL, '(503) 555-9931', NULL, '3400 - 8th Avenue Suite 210', NULL, 'Bend', 'OR', '97101', 'USA', NULL, NULL, 'Cheryl Saylor', NULL, NULL, NULL, '2021-06-10 19:37:39', '2021-06-10 19:37:39', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('21', 'S', NULL, 'Svensk Sjöföda AB', NULL, '08-123 45 67', NULL, 'Brovallavägen 231', NULL, 'Stockholm', '', 'S-123 45', 'Sweden', NULL, NULL, 'Michael Björn', NULL, NULL, NULL, '2021-06-10 19:37:39', '2021-06-10 19:37:39', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('22', 'S', NULL, 'Aux joyeux ecclésiastiques', NULL, '(1) 03.83.00.68', NULL, '203, Rue des Francs-Bourgeois', NULL, 'Paris', '', '75004', 'France', NULL, NULL, 'Guylène Nodier', NULL, NULL, NULL, '2021-06-10 19:37:39', '2021-06-10 19:37:39', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('23', 'S', NULL, 'New England Seafood Cannery', NULL, '(617) 555-3267', NULL, 'Order Processing Dept. 2100 Paul Revere Blvd.', NULL, 'Boston', 'MA', '02134', 'USA', NULL, NULL, 'Robb Merchant', NULL, NULL, NULL, '2021-06-15 19:40:07', '2021-06-10 19:37:39', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('3', 'S', NULL, 'Exotic Liquids', NULL, '(171) 555-2222', NULL, '49 Gilbert St.', NULL, 'London', '', 'EC1 4SD', 'UK', NULL, NULL, 'Charlotte Cooper', NULL, NULL, NULL, '2021-06-10 19:30:28', '2021-06-10 19:30:28', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('4', 'S', NULL, 'New Orleans Cajun Delights', NULL, '(100) 555-4822', NULL, 'P.O. Box 78934', NULL, 'New Orleans', 'LA', '70117', 'USA', NULL, NULL, 'Shelley Burke', NULL, NULL, NULL, '2021-06-10 19:30:28', '2021-06-10 19:30:28', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('5', 'S', NULL, 'Tokyo Traders', NULL, '(03) 3555-5011', NULL, '9-8 Sekimai Musashino-shi', NULL, 'Tokyo', '', '100', 'Japan', NULL, NULL, 'Yoshi Nagase', NULL, NULL, NULL, '2021-06-10 19:31:17', '2021-06-10 19:31:17', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('6', 'S', NULL, 'Mayumis', NULL, '(06) 431-7877', NULL, '92 Setsuko Chuo-ku', NULL, 'Osaka', '', '545', 'Japan', NULL, NULL, 'Mayumi Ohno', NULL, NULL, NULL, '2021-06-10 19:33:41', '2021-06-10 19:33:41', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('7', 'S', NULL, 'Pavlova, Ltd.', NULL, '(03) 444-2343', NULL, '74 Rose St. Moonie Ponds', NULL, 'Melbourne', 'Victoria', '3058', 'Australia', NULL, NULL, 'Ian Devling', NULL, NULL, NULL, '2021-06-10 19:33:48', '2021-06-10 19:33:48', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('8', 'S', NULL, 'Cooperativa de Quesos Las Cabras', NULL, '(98) 598 76 54', NULL, 'Calle del Rosal 4', NULL, 'Oviedo', 'Asturias', '33007', 'Spain', NULL, NULL, 'Antonio del Valle Saavedra', NULL, NULL, NULL, '2021-06-10 19:34:56', '2021-06-10 19:34:56', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('9', 'S', NULL, 'Forêts dérables', NULL, '(514) 555-2955', NULL, '148 rue Chasseur', NULL, 'Ste-Hyacinthe', 'Québec', 'J2S 7S8', 'Canada', NULL, NULL, 'Chantal Goulet', NULL, NULL, NULL, '2021-06-10 19:36:14', '2021-06-10 19:36:14', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('ANGEL', 'S', NULL, 'ANGEL MARTIN JULIÁN', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-17 09:36:55', '2025-04-17 09:34:57', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('FER', 'S', NULL, 'FERNANDO E HIJOS, SL', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2024-10-02 20:21:28', '2024-10-02 20:21:30', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('LAIBENSE', 'S', NULL, 'LA IBENSE JUGUETERA', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-09-19 11:23:01', '2024-10-06 20:36:59', 'Administrador', 'Administrador');
INSERT INTO `fza_proveedores` VALUES ('PEPI', 'S', NULL, 'PEPINO RODRÍGUEZ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-17 09:03:32', '2025-04-17 09:03:32', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_recibos
-- ----------------------------
DROP TABLE IF EXISTS `fza_recibos`;
CREATE TABLE `fza_recibos`  (
  `NRO_FACTURA_RECIBO` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SERIE_FACTURA_RECIBO` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NRO_PLAZO_RECIBO` int(11) NOT NULL,
  `FORMA_PAGO_ORIGEN_RECIBO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EUROS_RECIBO` decimal(18, 6) NULL DEFAULT NULL,
  `STADO_RECIBO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_EXPEDICION_RECIBO` date NULL DEFAULT NULL,
  `FECHA_VENCIMIENTO_RECIBO` date NULL DEFAULT NULL,
  `IBAN_CLIENTE_RECIBO` varchar(34) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `FECHA_PAGO_RECIBO` date NULL DEFAULT NULL,
  `LOCALIDAD_EXPEDICION_RECIBO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_CLIENTE_RECIBO` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `RAZONSOCIAL_CLIENTE_RECIBO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIRECCION1_CLIENTE_RECIBO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `POBLACION_CLIENTE_RECIBO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `PROVINCIA_CLIENTE_RECIBO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CPOSTAL_CLIENTE_RECIBO` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_PAIS_CLIENTE_RECIBO` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT '724',
  `NOMBRE_PAIS_CLIENTE_RECIBO` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'España',
  `IMPORTE_LETRA_RECIBO` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`NRO_FACTURA_RECIBO`, `SERIE_FACTURA_RECIBO`, `NRO_PLAZO_RECIBO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_recibos
-- ----------------------------
INSERT INTO `fza_recibos` VALUES ('00000021', 'A1', 1, '30Y60', '30Y60', 2663.885900, 'Emitido', '2023-05-12', '2023-06-11', NULL, NULL, 'POBLACION DEL AGRICULTOR', 'PUBLICO', 'PUBLICO', 'DIRECCION DEL CLIENTE', 'POBLACION AGRICULTOR', 'PROVINCIA CLIENTE', 'POSCLI', '724', 'España', 'DOS MIL SEISCIENTOS SESENTA Y TRES CON OCHENTA Y NUEVE CÉNTIMOS ', '2024-09-26 23:00:00', '2023-11-09 04:22:30', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('00000021', 'A1', 2, '30Y60', '30Y60', 2663.885900, 'Emitido', '2023-05-12', '2023-07-11', NULL, NULL, 'POBLACION DEL AGRICULTOR', 'PUBLICO', 'PUBLICO', 'DIRECCION DEL CLIENTE', 'POBLACION AGRICULTOR', 'PROVINCIA CLIENTE', 'POSCLI', NULL, NULL, 'DOS MIL SEISCIENTOS SESENTA Y TRES CON OCHENTA Y NUEVE CÉNTIMOS ', '2023-11-09 04:22:30', '2023-11-09 04:22:30', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000001', 'A0', 1, 'CONTADO', 'CONTADO', 433.444800, 'Pagado', '2024-02-12', '2024-02-12', 'ES50018256323656987201452', '2024-02-12', 'SANTOVENIA', '295', 'AZUCENA MARTIN (KIOSKO PERLA)', 'CALLE POZO AMARILLO, 3', 'SALAMANCA', 'SALAMANCA', '37003', '724', 'España', 'CUATROCIENTOS TREINTA Y TRES CON CUARENTA Y CUATRO CÉNTIMOS ', '2025-04-03 23:42:25', '2025-04-03 23:42:25', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000001', 'A1.2023', 1, '30_60_90', '30_60_90', 144.474350, 'Emitido', '2023-12-07', '2024-01-06', 'ES50018256323656987201452', NULL, 'SANTOVENIA', '295', 'AZUCENA MARTIN (KIOSKO PERLA)', 'CALLE POZO AMARILLO, 3', 'SALAMANCA', 'SALAMANCA', '37003', '724', 'España', 'CIENTO CUARENTA Y CUATRO CON CUARENTA Y SIETE CÉNTIMOS ', '2024-10-06 21:31:09', '2024-10-06 21:31:09', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000001', 'A1.2023', 2, '30_60_90', '30_60_90', 144.474350, 'Emitido', '2023-12-07', '2024-02-05', 'ES50018256323656987201452', NULL, 'SANTOVENIA', '295', 'AZUCENA MARTIN (KIOSKO PERLA)', 'CALLE POZO AMARILLO, 3', 'SALAMANCA', 'SALAMANCA', '37003', '724', 'España', 'CIENTO CUARENTA Y CUATRO CON CUARENTA Y SIETE CÉNTIMOS ', '2024-10-06 21:31:09', '2024-10-06 21:31:09', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000001', 'A1.2023', 3, '30_60_90', '30_60_90', 144.474350, 'Emitido', '2023-12-07', '2024-03-06', 'ES50018256323656987201452', NULL, 'SANTOVENIA', '295', 'AZUCENA MARTIN (KIOSKO PERLA)', 'CALLE POZO AMARILLO, 3', 'SALAMANCA', 'SALAMANCA', '37003', '724', 'España', 'CIENTO CUARENTA Y CUATRO CON CUARENTA Y SIETE CÉNTIMOS ', '2024-10-06 21:31:09', '2024-10-06 21:31:09', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000001', 'AGRO/2023', 1, 'TRANSFEREN', 'TRANSFERENCIA', 589.680000, 'Pagado', '2023-12-06', '2023-12-06', NULL, '2023-12-06', 'POBLACION DEL AGRICULTOR', '296', 'ANGEL MARTIN', 'CL TRES CRUCES, 23, 3C', 'ZAMORA', 'ZAMORA', '49002', NULL, NULL, 'QUINIENTOS OCHENTA Y NUEVE CON SESENTA Y OCHO CÉNTIMOS ', '2023-12-09 18:32:44', '2023-12-09 18:32:44', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000002', 'ANA/2023', 1, 'CONTADO', 'CONTADO', 1194.450000, 'Pagado', '2023-10-31', '2023-10-31', NULL, '2023-10-31', 'MORALES DEL VINO', 'TIENDA', 'TIENDA DE ROSA', 'CALLE MAYOR, 2', 'MORALES DEL VINO', 'ZAMORA', '49190', NULL, NULL, 'MIL CIENTO NOVENTA Y CUATRO CON CUARENTA Y CINCO CÉNTIMOS ', '2023-12-04 14:16:59', '2023-12-04 14:16:59', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000003', 'A1.2023', 1, 'CONTADO', 'CONTADO', 568.760000, 'Pagado', '2023-12-22', '2023-12-22', 'ES50018256323656987201452', '2023-12-22', 'SANTOVENIA', '295', 'AZUCENA MARTIN (KIOSKO PERLA)', 'CALLE POZO AMARILLO, 3', 'SALAMANCA', 'SALAMANCA', '37003', NULL, NULL, 'QUINIENTOS SESENTA Y OCHO CON SETENTA Y SEIS CÉNTIMOS ', '2024-07-30 12:38:11', '2024-07-30 12:38:11', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000006', 'AGRO', 1, '30DIAS', '30DIAS', 9313.920000, 'Emitido', '2023-10-22', '2023-11-21', NULL, NULL, 'POBLACION AGRICULTOR', '293', 'PEDRO COJOS', 'CALLE CAIDOS ', 'VILLAVEZA DEL AGUA', 'ZAMORA', '49760', NULL, NULL, 'NUEVE MIL TRESCIENTOS TRECE CON NOVENTA Y DOS CÉNTIMOS ', '2023-11-08 22:45:00', '2023-11-08 22:45:00', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000007', 'AGRO', 1, '30_60_90', '30_60_90', 6882.666667, 'Emitido', '2023-10-26', '2023-11-25', NULL, NULL, 'POBLACION', 'PUBLICO', 'PUBLICO', 'DIRECCION', 'POBLACION', 'PROVINCIA', 'CODPOSTAL', NULL, NULL, 'SEIS MIL OCHOCIENTOS OCHENTA Y DOS CON SESENTA Y SIETE CÉNTIMOS ', '2023-12-09 11:26:57', '2023-12-09 11:26:57', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000007', 'AGRO', 2, '30_60_90', '30_60_90', 6882.666667, 'Emitido', '2023-10-26', '2023-12-25', NULL, NULL, 'POBLACION', 'PUBLICO', 'PUBLICO', 'DIRECCION', 'POBLACION', 'PROVINCIA', 'CODPOSTAL', NULL, NULL, 'SEIS MIL OCHOCIENTOS OCHENTA Y DOS CON SESENTA Y SIETE CÉNTIMOS ', '2023-12-09 11:26:57', '2023-12-09 11:26:57', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('000007', 'AGRO', 3, '30_60_90', '30_60_90', 6882.666667, 'Emitido', '2023-10-26', '2024-01-24', NULL, NULL, 'POBLACION', 'PUBLICO', 'PUBLICO', 'DIRECCION', 'POBLACION', 'PROVINCIA', 'CODPOSTAL', NULL, NULL, 'SEIS MIL OCHOCIENTOS OCHENTA Y DOS CON SESENTA Y SIETE CÉNTIMOS ', '2023-12-09 11:26:57', '2023-12-09 11:26:57', 'Administrador', 'Administrador');
INSERT INTO `fza_recibos` VALUES ('24', 'A1', 1, 'CONTADO', 'CONTADO', 19.834711, 'Pagado', '2023-05-16', '2023-05-16', NULL, '2023-05-16', '', '291', 'PEDRO CACHAS', NULL, NULL, NULL, NULL, NULL, NULL, 'DIECINUEVE CON OCHENTA Y TRES CÉNTIMOS ', '2023-05-17 13:12:06', '2023-05-17 13:12:06', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_tarifas
-- ----------------------------
DROP TABLE IF EXISTS `fza_tarifas`;
CREATE TABLE `fza_tarifas`  (
  `CODIGO_TARIFA` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ACTIVO_TARIFA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ORDEN_TARIFA` int(11) NULL DEFAULT NULL,
  `NOMBRE_TARIFA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESIMP_INCL_TARIFA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ESDEFAULT_TARIFA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_TARIFA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_tarifas
-- ----------------------------
INSERT INTO `fza_tarifas` VALUES ('PVP', 'S', 1, 'PVP', 'S', 'S', '2026-01-04 22:09:22', '2022-09-05 09:30:49', 'Administrador', 'Administrador');
INSERT INTO `fza_tarifas` VALUES ('VENTAMAYOR', 'S', 2, 'VENTA MAYOR', 'N', 'N', '2026-01-04 22:09:26', '2022-09-05 09:31:19', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_tipos_documentos
-- ----------------------------
DROP TABLE IF EXISTS `fza_tipos_documentos`;
CREATE TABLE `fza_tipos_documentos`  (
  `CODIGO_TIPODOCUMENTO` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `DESCRIPCION_TIPODOCUMENTO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `TABLAORIGEN_TIPODOCUMENTO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`CODIGO_TIPODOCUMENTO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_tipos_documentos
-- ----------------------------
INSERT INTO `fza_tipos_documentos` VALUES ('AO', 'ORDEN ARTICULOS', 'fza_articulos');
INSERT INTO `fza_tipos_documentos` VALUES ('AR', 'ARTICULOS', 'fza_articulos');
INSERT INTO `fza_tipos_documentos` VALUES ('CL', 'CLIENTES', 'fza_clientes');
INSERT INTO `fza_tipos_documentos` VALUES ('CO', 'ORDEN CLIENTES', 'fza_clientes');
INSERT INTO `fza_tipos_documentos` VALUES ('EM', 'EMPRESAS', 'fza_empresas');
INSERT INTO `fza_tipos_documentos` VALUES ('EO', 'ORDEN EMPRESAS', 'fza_empresas');
INSERT INTO `fza_tipos_documentos` VALUES ('ES', 'SERIES POR EMPRESA', 'fza_empresas_series');
INSERT INTO `fza_tipos_documentos` VALUES ('FA', 'FAMILIAS', 'fza_articulos_familias');
INSERT INTO `fza_tipos_documentos` VALUES ('FC', 'FACTURAS DE CLIENTE', 'fza_facturas');
INSERT INTO `fza_tipos_documentos` VALUES ('FO', 'ORDEN FAMILIAS', 'fza_articulos_familias');
INSERT INTO `fza_tipos_documentos` VALUES ('GO', 'ORDEN DE FORMAS DE PAGO', 'fza_formas_pago');
INSERT INTO `fza_tipos_documentos` VALUES ('GP', 'GENERADOR DE PROCESOS', 'fza_generadorprocesos');
INSERT INTO `fza_tipos_documentos` VALUES ('IG', 'ZONAS IVA', 'fza_iva_grupos');
INSERT INTO `fza_tipos_documentos` VALUES ('IV', 'IVAS', 'fza_ivas');
INSERT INTO `fza_tipos_documentos` VALUES ('PG', 'FORMAS DE PAGO', 'fza_formas_pago');
INSERT INTO `fza_tipos_documentos` VALUES ('PO', 'ORDEN PROVEEDORES', 'fza_proveedores');
INSERT INTO `fza_tipos_documentos` VALUES ('PV', 'PROVEEDORES', 'fza_proveedores');
INSERT INTO `fza_tipos_documentos` VALUES ('RT', 'RETENCIONES POR EMPRESA', 'fza_empresas_retenciones');

-- ----------------------------
-- Table structure for fza_usuarios
-- ----------------------------
DROP TABLE IF EXISTS `fza_usuarios`;
CREATE TABLE `fza_usuarios`  (
  `USUARIO_USUARIO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `PASSWORD_USUARIO` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `GRUPO_USUARIO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ACTIVO_USUARIO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `EMPRESADEF_USUARIO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DIMINUTIVO_TICKET_USUARIO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CODIGO_EMPLEADO_USUARIO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ULTIMOLOGIN_USUARIO` timestamp NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ALMACENDEF_USUARIO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `CAJADEF_USUARIO` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`USUARIO_USUARIO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_usuarios
-- ----------------------------
INSERT INTO `fza_usuarios` VALUES ('Administrador', '4F8239A5B05A0E22D3DD4D7853808AF3', 'Administradores', 'S', '012', 'ALEX', '1', '2026-03-05 06:57:23', '2026-03-05 06:57:23', '2021-05-14 19:54:29', 'Administrador', 'Administrador', 'GEN', '1');

-- ----------------------------
-- Table structure for fza_usuarios_grupos
-- ----------------------------
DROP TABLE IF EXISTS `fza_usuarios_grupos`;
CREATE TABLE `fza_usuarios_grupos`  (
  `GRUPO_GRUPO` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ESGRUPOADMINISTRADOR_GRUPO` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'N',
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`GRUPO_GRUPO`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_usuarios_grupos
-- ----------------------------
INSERT INTO `fza_usuarios_grupos` VALUES ('Administradores', 'S', '2023-01-21 08:29:44', '2021-05-14 19:55:13', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_grupos` VALUES ('Usuarios', 'N', '2021-05-24 20:53:04', '2021-05-24 20:52:52', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_usuarios_perfiles
-- ----------------------------
DROP TABLE IF EXISTS `fza_usuarios_perfiles`;
CREATE TABLE `fza_usuarios_perfiles`  (
  `USUARIO_GRUPO_PERFILES` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `KEY_PERFILES` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `SUBKEY_PERFILES` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `VALUE_PERFILES` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `VALUE_TEXT_PERFILES` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `TYPE_BLOB_PERFILES` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `VALUE_BLOB_PERFILES` blob NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`USUARIO_GRUPO_PERFILES`, `KEY_PERFILES`, `SUBKEY_PERFILES`) USING BTREE,
  INDEX `IDX_KEYPERFIL`(`KEY_PERFILES` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_usuarios_perfiles
-- ----------------------------
INSERT INTO `fza_usuarios_perfiles` VALUES ('Administrador', 'frmPrintFac', 'frxrprt1_FACTURA DURA', 'FACTURA DURA', NULL, NULL, 0x3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D227574662D3822207374616E64616C6F6E653D226E6F223F3E0D0A3C546672785265706F72742056657273696F6E3D22323032322E332220446F744D61747269785265706F72743D2246616C73652220456E67696E654F7074696F6E732E446F75626C65506173733D22547275652220496E6946696C653D225C536F6674776172655C46617374205265706F7274732220507265766965774F7074696F6E732E427574746F6E733D22343039352220507265766965774F7074696F6E732E5A6F6F6D3D223122205072696E744F7074696F6E732E5072696E7465723D22506F72206465666563746F22205072696E744F7074696F6E732E5072696E744F6E53686565743D223022205265706F72744F7074696F6E732E417574686F723D2246616374755A616D22205265706F72744F7074696F6E732E437265617465446174653D2234323438312C3633343637353734303722205265706F72744F7074696F6E732E4465736372697074696F6E2E546578743D2222205265706F72744F7074696F6E732E4C6173744368616E67653D2234353333342C3430353430353931343422205363726970744C616E67756167653D2250617363616C5363726970742220536372697074546578742E546578743D2270726F63656475726520526574656E63696F6E546F74616C4F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F524554454E43494F4E5F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B20202020526574656E63696F6E546F74616C2E56697369626C65203A3D20547275653B262331333B262331303B20202020526574656E63696F6E2E56697369626C653A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B20202020526574656E63696F6E546F74616C2E56697369626C65203A3D2046616C73653B262331333B262331303B20202020526574656E63696F6E2E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F63656475726520496D70756573746F73546F74616C4F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F494D50554553544F535F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B20202020496D70756573746F73546F74616C2E56697369626C65203A3D20547275653B262331333B262331303B20202020496D70756573746F732E56697369626C653A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B20202020496D70756573746F73546F74616C2E56697369626C65203A3D2046616C73653B262331333B262331303B20202020496D70756573746F732E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652042617365496D706F6E69626C654E4F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F42415345495F4956414E5F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C654E2E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F4956414E5F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F4956414E5F464143545552412E56697369626C653A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F52454E5F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F52454E5F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C654E2E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F4956414E5F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F4956414E5F464143545552412E56697369626C653A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F52454E5F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F52454E5F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652042617365496D706F6E69626C65524F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F42415345495F495641525F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C65522E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F495641525F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F495641525F464143545552412E56697369626C653A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F5245525F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F5245525F46414354555241312E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C65522E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F495641525F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F495641525F464143545552412E56697369626C653A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F5245525F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F5245525F46414354555241312E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652042617365496D706F6E69626C65534F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F42415345495F495641535F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C65532E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F495641535F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F495641535F464143545552412E56697369626C653A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F5245535F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F5245535F46414354555241312E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C65532E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F495641535F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F495641535F464143545552412E56697369626C653A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F5245535F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F5245535F46414354555241312E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652042617365496D706F6E69626C65454F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B20202020696620262336303B46616374757261732E262333343B544F54414C5F42415345495F495641455F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C65452E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F495641455F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F495641455F464143545552412E56697369626C653A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F5245455F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F5245455F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B2020202042617365496D706F6E69626C65452E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F495641455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F495641455F464143545552412E56697369626C653A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F5245455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F5245455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B202069662028262336303B46616374757261732E262333343B544F54414C5F42415345495F495641455F46414354555241262333343B262336323B203D20262336303B46616374757261732E262333343B544F54414C5F42415345535F46414354555241262333343B262336323B29207468656E262331333B262331303B2020626567696E262331333B262331303B2020202043616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B2020202043616A61546974756C6F734956412E56697369626C65203A3D2046616C73653B262331333B262331303B2020202042617365496D706F6E69626C65452E56697369626C65203A3D2046616C73653B262331333B262331303B20202020546974756C6F506F7263656E43616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F495641455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F495641455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B2020202042617365496D706F6E69626C6543616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B20202020546974756C6F546F74616C43616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F636564757265204661637475726173544F54414C5F52454E5F464143545552414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F52454E5F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F52454E5F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F52454E5F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F52454E5F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F52454E5F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F636564757265204661637475726173544F54414C5F5245525F464143545552414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F5245525F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F5245525F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F5245525F46414354555241312E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F5245525F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F5245525F46414354555241312E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F636564757265204661637475726173544F54414C5F5245535F464143545552414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020696620262336303B46616374757261732E262333343B544F54414C5F5245535F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F5245535F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F5245535F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F5245535F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F5245535F46414354555241312E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F636564757265204661637475726173544F54414C5F5245455F464143545552414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B20202020696620262336303B46616374757261732E262333343B544F54414C5F5245455F46414354555241262333343B262336323B20262336303B262336323B2030207468656E262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F5245455F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173544F54414C5F5245455F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B202020204661637475726173504F5243454E5F5245455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173544F54414C5F5245455F464143545552412E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E643B262331333B262331303B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F63656475726520526574656E63696F6E506F72634F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020496620282820262336303B46616374757261732E262333343B544F54414C5F5245455F46414354555241262333343B262336323B202B262331333B262331303B2020202020202020262336303B46616374757261732E262333343B544F54414C5F5245535F46414354555241262333343B262336323B202B262331333B262331303B2020202020202020262336303B46616374757261732E262333343B544F54414C5F5245525F46414354555241262333343B262336323B202B262331333B262331303B2020202020202020262336303B46616374757261732E262333343B544F54414C5F52454E5F46414354555241262333343B262336323B2029203D203029207468656E262331333B262331303B2020626567696E262331333B262331303B20202020526574656E63696F6E506F72632E56697369626C65203A3D2046616C73653B262331333B262331303B20202020526574656E63696F6E546F742E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B20202020526574656E63696F6E506F72632E56697369626C65203A3D20547275653B262331333B262331303B20202020526574656E63696F6E546F742E56697369626C65203A3D20547275653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652050616765466F6F746572314F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020456E67696E652E43757259203A3D20283230202A20667231636D293B262331333B262331303B20206966202828262336303B546F74616C5061676573262336323B20262336323B20312920616E642028262336303B50616765262336323B20262336303B262336323B20262336303B546F74616C5061676573262336323B2929207468656E262331333B262331303B2020626567696E262331333B262331303B2020202043616A61546974756C6F734956412E56697369626C65203A3D2046616C73653B262331333B262331303B2020202042617365496D706F6E69626C6543616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B20202020546974756C6F506F7263656E43616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B20202020546974756C6F546F74616C43616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B20202020546F74616C42617365732E56697369626C65203A3D2046616C73653B262331333B262331303B20202020496D70756573746F732E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B20202020496D70756573746F73546F74616C2E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B20202020526574656E63696F6E546F742E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020206D546F74616C466163747572612E56697369626C65203A3D2046616C73653B262331333B262331303B202020206D546F74616C466163747572614374642E56697369626C65203A3D2046616C73653B262331333B262331303B20202020526574656E63696F6E546F74616C2E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B20202020526574656E63696F6E2E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B20202020526574656E63696F6E506F72632E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B2020202043616A614956412E56697369626C65203A3D2046616C73653B262331333B262331303B20202020466F726D615061676F2E56697369626C65203A3D2046616C73653B262331333B262331303B20202020436F6E74696E75612E56697369626C65203A3D20547275653B262331333B262331303B2020202042617365496D706F6E69626C654E2E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B2020202042617365496D706F6E69626C65522E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B2020202042617365496D706F6E69626C65532E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B2020202042617365496D706F6E69626C65452E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B20202020546F74616C42617365496D706F6E69626C652E56697369626C65203A3D2046616C73653B262331333B262331303B202020204661637475726173504F5243454E5F4956414E5F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F495641525F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F495641535F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F495641455F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F4956414E5F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F495641525F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F495641535F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F495641455F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F52454E5F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F5245525F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F5245535F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173504F5243454E5F5245455F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F52454E5F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F5245525F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F5245535F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F5245455F464143545552412E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F5245525F46414354555241312E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B202020204661637475726173544F54414C5F5245535F46414354555241312E466F6E742E436F6C6F72203A3D20636C57686974653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B20202020436F6E74696E75612E56697369626C65203A3D2046616C73653B262331333B262331303B2020202043616A61546974756C6F734956412E56697369626C65203A3D20547275653B262331333B262331303B2020202042617365496D706F6E69626C6543616A614956412E56697369626C65203A3D20547275653B262331333B262331303B20202020546974756C6F506F7263656E43616A614956412E56697369626C65203A3D20547275653B262331333B262331303B20202020546974756C6F546F74616C43616A614956412E56697369626C65203A3D20547275653B262331333B262331303B20202020546F74616C42617365732E56697369626C65203A3D20547275653B262331333B262331303B20202020496D70756573746F732E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B20202020496D70756573746F73546F74616C2E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B20202020526574656E63696F6E546F742E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020206D546F74616C466163747572612E56697369626C65203A3D20547275653B262331333B262331303B202020206D546F74616C466163747572614374642E56697369626C65203A3D20547275653B262331333B262331303B2020202043616A614956412E56697369626C65203A3D20547275653B262331333B262331303B20202020526574656E63696F6E546F74616C2E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B20202020526574656E63696F6E2E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B20202020526574656E63696F6E506F72632E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B20202020466F726D615061676F2E56697369626C65203A3D20547275653B262331333B262331303B2020202042617365496D706F6E69626C654E2E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B2020202042617365496D706F6E69626C65522E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B2020202042617365496D706F6E69626C65532E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B2020202042617365496D706F6E69626C65452E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B20202020546F74616C42617365496D706F6E69626C652E56697369626C65203A3D20547275653B262331333B262331303B202020204661637475726173504F5243454E5F4956414E5F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F495641525F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F495641535F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F495641455F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F4956414E5F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F495641525F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F495641535F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F495641455F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F52454E5F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F5245525F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F5245535F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173504F5243454E5F5245455F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F52454E5F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F5245525F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F5245535F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F5245455F464143545552412E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F5245525F46414354555241312E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B202020204661637475726173544F54414C5F5245535F46414354555241312E466F6E742E436F6C6F72203A3D20636C426C61636B3B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652044657461696C44617461314F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202049662028262336303B46616374757261732E262333343B455346454348414445454E54524547415F46414354555241262333343B262336323B20262336303B262336323B2027532729207468656E262331333B262331303B202020626567696E262331333B262331303B202020202F2F204C696E65617346616374757261734445534352495043494F4E5F4152544943554C4F5F464143545552415F4C494E45412E5769647468203A3D2037363B262331333B262331303B202020204C696E656173466163747572617346454348415F454E54524547415F464143545552415F4C494E45412E56697369626C65203A3D2046616C73653B262331333B262331303B2020656E64262331333B262331303B2020656C7365262331333B262331303B2020626567696E262331333B262331303B202020202F2F204C696E65617346616374757261734445534352495043494F4E5F4152544943554C4F5F464143545552415F4C494E45412E5769647468203A3D2039383B262331333B262331303B202020204C696E656173466163747572617346454348415F454E54524547415F464143545552415F4C494E45412E56697369626C65203A3D20547275653B262331333B262331303B2020656E643B262331333B262331303B656E643B262331333B262331303B70726F636564757265204665636861456E7472656761546974746C654F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202049662028262336303B46616374757261732E262333343B455346454348414445454E54524547415F46414354555241262333343B262336323B20262336303B262336323B2027532729207468656E262331333B262331303B202020204665636861456E7472656761546974746C652E56697369626C65203A3D2046616C7365262331333B262331303B2020656C7365262331333B262331303B202020204665636861456E7472656761546974746C652E56697369626C65203A3D20547275653B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F63656475726520466163747572617350524F56494E4349415F454D50524553415F464143545552414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202049462028262336303B46616374757261732E262333343B504F424C4143494F4E5F454D50524553415F46414354555241262333343B262336323B203D20262336303B46616374757261732E262333343B50524F56494E4349415F454D50524553415F46414354555241262333343B262336323B29207468656E262331333B262331303B20202020466163747572617350524F56494E4349415F454D50524553415F464143545552412E56697369626C65203A3D2046616C7365262331333B262331303B2020656C7365262331333B262331303B20202020466163747572617350524F56494E4349415F454D50524553415F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B656E643B262331333B262331303B262331333B262331303B262331333B262331303B70726F63656475726520466163747572617350524F56494E4349415F434C49454E54455F464143545552414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202049462028262336303B46616374757261732E262333343B504F424C4143494F4E5F434C49454E54455F46414354555241262333343B262336323B203D20262336303B46616374757261732E262333343B50524F56494E4349415F434C49454E54455F46414354555241262333343B262336323B29207468656E262331333B262331303B20202020466163747572617350524F56494E4349415F434C49454E54455F464143545552412E56697369626C65203A3D2046616C7365262331333B262331303B2020656C7365262331333B262331303B20202020466163747572617350524F56494E4349415F434C49454E54455F464143545552412E56697369626C65203A3D20547275653B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F63656475726520496D70756573746F734F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B2020496620282820262336303B46616374757261732E262333343B544F54414C5F5245455F46414354555241262333343B262336323B202B262331333B262331303B2020202020202020262336303B46616374757261732E262333343B544F54414C5F5245535F46414354555241262333343B262336323B202B262331333B262331303B2020202020202020262336303B46616374757261732E262333343B544F54414C5F5245525F46414354555241262333343B262336323B202B262331333B262331303B2020202020202020262336303B46616374757261732E262333343B544F54414C5F52454E5F46414354555241262333343B262336323B2029203D203029207468656E262331333B262331303B20202020496D70756573746F732E4D656D6F2E54657874203A3D2027546F74616C205B46616374757261732E262333343B50414C414252415F5245504F5254535F5A4F4E415F4956415F46414354555241262333343B5D27262331333B262331303B2020656C7365262331333B262331303B20202020496D70756573746F732E4D656D6F2E54657874203A3D2027546F74616C205B46616374757261732E262333343B50414C414252415F5245504F5254535F5A4F4E415F4956415F46414354555241262333343B5D202B20522E452E27262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F636564757265206D4E756D506167696E61734F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202069662028262336303B546F74616C5061676573262336323B20262336323B203129207468656E262331333B262331303B202020206D4E756D506167696E61732E56697369626C65203A3D2054727565262331333B262331303B2020656C7365262331333B262331303B202020206D4E756D506167696E61732E56697369626C65203A3D2046616C73653B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F63656475726520466F726D615061676F4F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B20206966202828262336303B46616374757261732E262333343B455356455242414E434F454D50524553415F464F524D415041474F262333343B262336323B203D202753272920616E64262331333B262331303B20202020202028262336303B46616374757261732E262333343B4553434F4E5441444F5F464F524D415041474F262333343B262336323B203D20274E272920616E64262331333B262331303B20202020202028262336303B46616374757261732E262333343B4942414E5F454D5052455341262333343B262336323B20262336303B262336323B202727292920207468656E262331333B262331303B20202020466F726D615061676F2E4D656D6F2E54657874203A3D205472696D28466F726D615061676F2E4D656D6F2E5465787429202B2027202020202027202B20466F726D61744D61736B546578742827262336323B4C4C303020616161612061616161206161616120616161612061616161206161616120616161612061613B303B272C262336303B46616374757261732E262333343B4942414E5F454D5052455341262333343B262336323B293B262331333B262331303B20206966202828262336303B46616374757261732E262333343B455356455242414E434F454D50524553415F464F524D415041474F262333343B262336323B203D20274E272920616E64262331333B262331303B20202020202028262336303B46616374757261732E262333343B4553434F4E5441444F5F464F524D415041474F262333343B262336323B203D20274E272920616E64262331333B262331303B20202020202028262336303B46616374757261732E262333343B4942414E5F434C49454E5445262333343B262336323B20262336303B262336323B2027272929207468656E262331333B262331303B20202020466F726D615061676F2E4D656D6F2E54657874203A3D205472696D28466F726D615061676F2E4D656D6F2E5465787429202B2027202020202027202B20466F726D61744D61736B546578742827262336323B4C4C303020616161612061616161206161616120616161612061616161206161616120616161612061613B303B272C262336303B46616374757261732E262333343B4942414E5F434C49454E5445262333343B262336323B293B262331333B262331303B202069662028262336303B46616374757261732E262333343B56454E43494D49454E544F535F52454349424F53262333343B262336323B20262336303B262336323B20272729207468656E262331333B262331303B20202020466F726D615061676F2E4D656D6F2E54657874203A3D20466F726D615061676F2E4D656D6F2E54657874202B202756656E63696D69656E746F2F733A2027202B20262336303B46616374757261732E262333343B56454E43494D49454E544F535F52454349424F53262333343B262336323B3B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F636564757265204C696E6561734661637475726173544F54414C5F4C494E45414F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202069662028262336303B4C696E6561732046616374757261732E262333343B4553494D505F494E434C5F5441524946415F464143545552415F4C494E4541262333343B262336323B203D2027532729207468656E262331333B262331303B202020204C696E6561734661637475726173544F54414C5F4C494E45412E4D656D6F2E54657874203A3D20275B4C696E6561732046616374757261732E262333343B544F54414C5F464143545552415F4C494E4541262333343B5D27262331333B262331303B2020656C7365262331333B262331303B202020204C696E6561734661637475726173544F54414C5F4C494E45412E4D656D6F2E54657874203A3D20275B262336303B4C696E6561732046616374757261732E262333343B43414E54494441445F464143545552415F4C494E4541262333343B262336323B20272B262331333B262331303B20202020202020202020202020202020202020202020202020202020202020202020202020202020202020272A262336303B4C696E6561732046616374757261732E262333343B50524543494F56454E54415F534956415F4152544943554C4F5F464143545552415F4C494E4541262333343B262336323B5D273B262331333B262331303B656E643B262331333B262331303B262331333B262331303B70726F6365647572652050726563696F556E69746172696F4C696E65617346616374757261734F6E4265666F72655072696E742853656E6465723A2054667278436F6D706F6E656E74293B262331333B262331303B626567696E262331333B262331303B202069662028262336303B4C696E6561732046616374757261732E262333343B4553494D505F494E434C5F5441524946415F464143545552415F4C494E4541262333343B262336323B203D2027532729207468656E262331333B262331303B2020202050726563696F556E69746172696F4C696E65617346616374757261732E4D656D6F2E54657874203A3D20275B262336303B4C696E6561732046616374757261732E262333343B50524543494F56454E54415F434956415F4152544943554C4F5F464143545552415F4C494E4541262333343B262336323B5D27262331333B262331303B2020656C7365262331333B262331303B2020202050726563696F556E69746172696F4C696E65617346616374757261732E4D656D6F2E54657874203A3D20275B262336303B4C696E6561732046616374757261732E262333343B50524543494F56454E54415F534956415F4152544943554C4F5F464143545552415F4C494E4541262333343B262336323B5D27262331333B262331303B656E643B262331333B262331303B262331333B262331303B626567696E262331333B262331303B656E642E223E0D0A20203C44617461736574733E0D0A202020203C6974656D20446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D224661637475726173222F3E0D0A202020203C6974656D20446174615365743D22646D46616374757261732E66786473745072696E744C696E4661632220446174615365744E616D653D224C696E656173204661637475726173222F3E0D0A20203C2F44617461736574733E0D0A20203C546672784461746150616765204E616D653D22446174612220484775696465732E546578743D222220564775696465732E546578743D2222204865696768743D223130303022204C6566743D22302220546F703D2230222057696474683D2231303030223E0D0A202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F5245525F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339382C34303937312220546F703D223530342C3033313534222057696474683D2236342C323532303122204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224661637475726173544F54414C5F5245525F464143545552414F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F5245525F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E336D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F5245525F46414354555241262333343B5D222F3E0D0A202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F5245535F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339382C34303937312220546F703D223533302C3438383235222057696474683D2236342C323532303122204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224661637475726173544F54414C5F5245535F464143545552414F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F5245535F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E336D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F5245535F46414354555241262333343B5D222F3E0D0A20203C2F5466727844617461506167653E0D0A20203C546672785265706F727450616765204E616D653D2250616765312220484775696465732E546578743D222220564775696465732E546578743D222220506170657257696474683D22323130222050617065724865696768743D223239372220506170657253697A653D223922204C6566744D617267696E3D223130222052696768744D617267696E3D22352220546F704D617267696E3D2232302220426F74746F6D4D617267696E3D2232302220436F6C756D6E57696474683D22302220436F6C756D6E506F736974696F6E732E546578743D2222204672616D652E5479703D223022204D6972726F724D6F64653D2230223E0D0A202020203C5466727844657461696C44617461204E616D653D2244657461696C4461746131222046696C6C547970653D2266744272757368222046696C6C4761702E546F703D2230222046696C6C4761702E4C6566743D2230222046696C6C4761702E426F74746F6D3D2230222046696C6C4761702E52696768743D223022204672616D652E5479703D223022204865696768743D2232362C343536373122204C6566743D22302220546F703D223532352C3335343637222057696474683D223733372C303038333522204F6E4265666F72655072696E743D2244657461696C44617461314F6E4265666F72655072696E742220436F6C756D6E57696474683D22302220436F6C756D6E4761703D22302220446174615365743D22646D46616374757261732E66786473745072696E744C696E4661632220446174615365744E616D653D224C696E6561732046616374757261732220526F77436F756E743D2230223E0D0A2020202020203C546672784D656D6F56696577204E616D653D224C696E6561734661637475726173544F54414C5F4C494E45412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223634342C38353836392220546F703D22342C3333383539222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224C696E6561734661637475726173544F54414C5F4C494E45414F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D22262331333B262331303B5B262336303B4C696E6561732046616374757261732E262333343B43414E54494441445F464143545552415F4C494E4541262333343B262336323B2A262336303B4C696E6561732046616374757261732E262333343B50524543494F56454E54415F534956415F4152544943554C4F5F464143545552415F4C494E4541262333343B262336323B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224C696E656173466163747572617343414E54494441445F464143545552415F4C494E45412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223338362C30353533352220546F703D22332C3737393533222057696474683D2237392C333730313322204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B4C696E6561732046616374757261732E262333343B43414E54494441445F464143545552415F4C494E4541262333343B5D205B4C696E6561732046616374757261732E262333343B5449504F5F43414E54494441445F4152544943554C4F5F464143545552415F4C494E4541262333343B5D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D2250726563696F556E69746172696F4C696E65617346616374757261732220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223437392C39383435342220546F703D22332C3737393533222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D2250726563696F556E69746172696F4C696E65617346616374757261734F6E4265666F72655072696E742220446174614669656C643D2250524543494F56454E54415F534956415F4152544943554C4F5F464143545552415F4C494E45412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B4C696E6561732046616374757261732E262333343B50524543494F56454E54415F534956415F4152544943554C4F5F464143545552415F4C494E4541262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224C696E6561734661637475726173504F5243454E5F4956415F464143545552415F4C494E45412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223538322C30343736322220546F703D22332C3737393533222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D22256720252220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686143656E7465722220506172656E74466F6E743D2246616C73652220546578743D225B4C696E6561732046616374757261732E262333343B504F5243454E5F4956415F464143545552415F4C494E4541262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224C696E656173466163747572617346454348415F454E54524547415F464143545552415F4C494E45412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223330362C31323631362220546F703D22332C3737393533222057696474683D2237392C333730313322204865696768743D2231382C38393736352220446174614669656C643D2246454348415F454E54524547415F464143545552415F4C494E45412220446174615365743D22646D46616374757261732E66786473745072696E744C696E4661632220446174615365744E616D653D224C696E6561732046616374757261732220446973706C6179466F726D61742E466F726D61745374723D2264642F6D6D2F797979792220446973706C6179466F726D61742E4B696E643D22666B4461746554696D652220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D222D31363737373230382220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B4C696E6561732046616374757261732E262333343B46454348415F454E54524547415F464143545552415F4C494E4541262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224C696E65617346616374757261734445534352495043494F4E5F4152544943554C4F5F464143545552415F4C494E45412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232322C36373731382220546F703D22332C3737393533222057696474683D223237322C313236313622204865696768743D2231382C38393736352220537472657463684D6F64653D22736D4D61784865696768742220446174614669656C643D224445534352495043494F4E5F4152544943554C4F5F464143545552415F4C494E45412220446174615365743D22646D46616374757261732E66786473745072696E744C696E4661632220446174615365744E616D653D224C696E6561732046616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D223022204C696E6553706163696E673D22342220506172656E74466F6E743D2246616C73652220576F7264427265616B3D22547275652220546578743D225B4C696E6561732046616374757261732E262333343B4445534352495043494F4E5F4152544943554C4F5F464143545552415F4C494E4541262333343B5D222F3E0D0A202020203C2F5466727844657461696C446174613E0D0A202020203C546672784D656D6F56696577204E616D653D224D656D6F31392220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223837362C38353039373436352220546F703D223631392C3834323932222057696474683D2237392C333730313322204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F4C49515549444F5F46414354555241262333343B5D222F3E0D0A202020203C546672784D656D6F56696577204E616D653D224D656D6F32312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223837362C38353039373436352220546F703D223538322C3034373632222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22526574656E63696F6E546F74616C4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B262336303B46616374757261732E262333343B544F54414C5F524554454E43494F4E5F46414354555241262333343B262336323B202A20282D31295D222F3E0D0A202020203C546672784D656D6F56696577204E616D653D224D656D6F32332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223837372C39363930393436352220546F703D223535332C373031313435222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22496D70756573746F73546F74616C4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F494D50554553544F535F46414354555241262333343B5D222F3E0D0A202020203C546672784D656D6F56696577204E616D653D224D656D6F32352220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223837372C39363930393436352220546F703D223532352C3335343637222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22496D70756573746F73546F74616C4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F42415345535F46414354555241262333343B5D222F3E0D0A202020203C5466727850616765486561646572204E616D653D225061676548656164657231222046696C6C547970653D2266744272757368222046696C6C4761702E546F703D2230222046696C6C4761702E4C6566743D2230222046696C6C4761702E426F74746F6D3D2230222046696C6C4761702E52696768743D223022204672616D652E5479703D223022204865696768743D223430302C363330313822204C6566743D22302220546F703D2231382C3839373635222057696474683D223733372C3030383335223E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F372220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231332C35353930362220546F703D223336322C3833343838222057696474683D223731302C353531363422204865696768743D2232362C34353637312220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223331392C37303039392220546F703D2230222057696474683D223234392C343438393822204865696768743D2236382C303331353422204175746F57696474683D22547275652220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D32312220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223522204672616D652E5479703D2230222048416C69676E3D22686143656E7465722220506172656E74466F6E743D2246616C73652220546578743D2246414354555241262331333B262331303B44555241222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F322220416C6C6F77566563746F724578706F72743D225472756522204C6566743D22372C35353930362220546F703D223230372C3837343135222057696474683D223335352C323735383222204865696768743D223133362C30363330382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223337392C35313230362220546F703D223230372C3837343135222057696474683D223334332C393337323322204865696768743D223133362C30363330382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617352415A4F4E534F4349414C5F454D50524553415F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C37373935332220546F703D223231312C3635333638222057696474683D223334302C3135373722204865696768743D2231382C38393736352220446174614669656C643D2252415A4F4E534F4349414C5F454D50524553415F464143545552412220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B52415A4F4E534F4349414C5F454D50524553415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173444952454343494F4E315F454D50524553415F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C37373935332220546F703D223233342C3333303836222057696474683D223334302C3135373722204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B444952454343494F4E315F454D50524553415F46414354555241262333343B5D205B46616374757261732E262333343B444952454343494F4E325F454D50524553415F46414354555241262333343B5D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617343504F5354414C5F454D50524553415F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C37373935332220546F703D223235362C3232383531222057696474683D223334302C3135373722204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B43504F5354414C5F454D50524553415F46414354555241262333343B5D2020205B46616374757261732E262333343B504F424C4143494F4E5F454D50524553415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617350524F56494E4349415F454D50524553415F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C37373935332220546F703D223237382C33363234222057696474683D223334302C3135373722204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22466163747572617350524F56494E4349415F454D50524553415F464143545552414F6E4265666F72655072696E7422204F6E50726576696577436C69636B3D22466163747572617350524F56494E4349415F454D50524553415F464143545552414F6E50726576696577436C69636B2220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B50524F56494E4349415F454D50524553415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734D4F56494C5F454D50524553415F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C37373935332220546F703D223330312C3033393538222057696474683D2238332C313439363622204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B4D4F56494C5F454D50524553415F46414354555241262333343B5D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F342220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231332C35353930362220546F703D223137332C3835383338222057696474683D2235322C393133343222204865696768743D2232322C36373731382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31362220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D22456D69736F72222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F352220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223338302C31373334372220546F703D223137332C3835383338222057696474683D2237352C3539303622204865696768743D2232322C36373731382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31362220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225265636570746F72222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617352415A4F4E534F4349414C5F434C49454E54455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339322C3935332220546F703D223231312C3635333638222057696474683D223334372C373136373622204865696768743D2231382C38393736352220446174614669656C643D2252415A4F4E534F4349414C5F434C49454E54455F464143545552412220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B52415A4F4E534F4349414C5F434C49454E54455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173444952454343494F4E315F454D50524553415F46414354555241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339322C3935332220546F703D223233342C3333303836222057696474683D223334372C373136373622204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B444952454343494F4E315F434C49454E54455F46414354555241262333343B5D205B46616374757261732E262333343B444952454343494F4E325F434C49454E54455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617343504F5354414C5F434C49454E54455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339322C3935332220546F703D223235362C3232383531222057696474683D223330322C3336323422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B43504F5354414C5F434C49454E54455F46414354555241262333343B5D2020205B46616374757261732E262333343B504F424C4143494F4E5F434C49454E54455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617350524F56494E4349415F434C49454E54455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339322C3935332220546F703D223237382C33363234222057696474683D223334372C373136373622204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22466163747572617350524F56494E4349415F434C49454E54455F464143545552414F6E4265666F72655072696E742220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B50524F56494E4349415F434C49454E54455F46414354555241262333343B5D2020205B46616374757261732E262333343B504149535F434C49454E54455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734D4F56494C5F434C49454E54455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339322C3935332220546F703D223332322C3436343735222057696474683D223236342C3536373122204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224E49463A205B46616374757261732E262333343B4E49465F434C49454E54455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F362220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231332C35353930362220546F703D2239302C3730383732222057696474683D223334302C3135373722204865696768743D2232322C36373731382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31352220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D2246656368613A205B46616374757261732E262333343B46454348415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734E524F5F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231332C35353930362220546F703D223132302C3934343936222057696474683D223334302C3135373722204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31352220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224EC3BA6D65726F20646520466163747572613A205B46616374757261732E262333343B53455249455F46414354555241262333343B5D2E5B46616374757261732E262333343B4E524F5F46414354555241262333343B5D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F382220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231372C37373935332220546F703D223336362C3631343431222057696474683D2237392C333730313322204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22446573637269706369C3B36E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F392220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223633352C37343035372220546F703D223336362C3631343431222057696474683D2237392C333730313322204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D22546F74616C222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31302220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223338392C38333438382220546F703D223336362C3631343431222057696474683D2237352C3539303622204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D2243616E7469646164222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223437362C32303530312220546F703D223336362C3631343431222057696474683D2238332C313439363622204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D2250726563696F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22546974756C6F497661436F6C756D6E612220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223537322C393239352220546F703D223336362C3631343431222057696474683D2237352C3539303622204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D2230222048416C69676E3D22686143656E7465722220506172656E74466F6E743D2246616C73652220546578743D2225205B46616374757261732E262333343B50414C414252415F5245504F5254535F5A4F4E415F4956415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224665636861456E7472656761546974746C652220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223330362C31323631362220546F703D223336362C3631343431222057696474683D2239302C373038373222204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224665636861456E7472656761546974746C654F6E4265666F72655072696E742220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22466563686120456E7472656761222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734D4F56494C5F434C49454E54455F46414354555241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339322C3935332220546F703D223330312C3033393538222057696474683D2239342C343838323522204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B4D4F56494C5F434C49454E54455F46414354555241262333343B5D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734E49465F454D50524553415F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C37373935332220546F703D223332322C3436343735222057696474683D223237322C313236313622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D223022204672616D652E57696474683D22312C352220506172656E74466F6E743D2246616C73652220546578743D224E49463A205B46616374757261732E262333343B4E49465F454D50524553415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31322220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223436382C36363137322220546F703D223330312C30333935393232222057696474683D223234392C343438393822204865696768743D2231382C383937363337382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D222D31363737373230382220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B454D41494C5F434C49454E54455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530362C34353730322220546F703D2239342C3438383235222057696474683D223022204865696768743D2232322C36373731382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D222D31363737373230382220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31342220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223130392C36303633372220546F703D223330312C33363234222057696474683D223234392C343438393822204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B454D41494C5F454D50524553415F46414354555241262333343B5D222F3E0D0A202020203C2F54667278506167654865616465723E0D0A202020203C546672784D617374657244617461204E616D653D224D61737465724461746131222046696C6C547970653D2266744272757368222046696C6C4761702E546F703D2230222046696C6C4761702E4C6566743D2230222046696C6C4761702E426F74746F6D3D2230222046696C6C4761702E52696768743D223022204672616D652E5479703D223022204865696768743D2232322C363737313822204C6566743D22302220546F703D223438302C3030303331222056697369626C653D2246616C7365222057696474683D223733372C30303833352220436F6C756D6E57696474683D22302220436F6C756D6E4761703D22302220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220526F77436F756E743D2230223E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734E524F5F46414354555241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2236342C32353230312220546F703D2230222057696474683D2239342C343838323522204865696768743D2231382C38393736352220446174614669656C643D224E524F5F464143545552412220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D222D31363737373230382220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B4E524F5F46414354555241262333343B5D222F3E0D0A202020203C2F546672784D6173746572446174613E0D0A202020203C5466727850616765466F6F746572204E616D653D2250616765466F6F74657231222046696C6C547970653D2266744272757368222046696C6C4761702E546F703D2230222046696C6C4761702E4C6566743D2230222046696C6C4761702E426F74746F6D3D2230222046696C6C4761702E52696768743D223022204672616D652E5479703D223022204865696768743D223234392C343438393822204C6566743D22302220546F703D223631322C3238333836222057696474683D223733372C303038333522204F6E4265666F72655072696E743D2250616765466F6F746572314F6E4265666F72655072696E74223E0D0A2020202020203C546672784D656D6F56696577204E616D653D2243616A614956412220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231382C38393736352220546F703D2233322C3637373138222057696474683D223436382C363631343137333222204865696768743D223131332C333835392220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2243616A61546974756C6F734956412220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231382C38393736352220546F703D22362C3232303437222057696474683D223436382C363631343137333222204865696768743D2232362C34353637312220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D226D546F74616C466163747572612220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530372C36373735303436352220546F703D223132342C3732343439222057696474683D223231352C343333323122204865696768743D2232322C36373731382220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31362220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22313522204672616D652E57696474683D22312C352220506172656E74466F6E743D2246616C73652220546578743D22546F74616C204661637475726120222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2242617365496D706F6E69626C654E2220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232322C36373731393436352220546F703D2233362C3435363731222057696474683D2239302C373038373222204865696768743D2231352C313138313222204F6E4265666F72655072696E743D2242617365496D706F6E69626C654E4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F42415345495F4956414E5F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2242617365496D706F6E69626C6543616A614956412220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232362C34353637323436352220546F703D223130222057696474683D223130322C303437333122204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224261736520496D706F6E69626C65222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2242617365496D706F6E69626C65452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231382C38393736363436352220546F703D223131352C3832363834222057696474683D2239342C343838323522204865696768743D2231382C383937363522204F6E4265666F72655072696E743D2242617365496D706F6E69626C65454F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F42415345495F495641455F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F42415345495F495641455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22546974756C6F506F7263656E43616A614956412220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223134372C34303136383436352220546F703D223130222057696474683D2236382C303331353422204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D2225205B46616374757261732E262333343B50414C414252415F5245504F5254535F5A4F4E415F4956415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22546974756C6F546F74616C43616A614956412220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232383436352220546F703D223130222057696474683D2238362C393239313922204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22546F74616C205B46616374757261732E262333343B50414C414252415F5245504F5254535F5A4F4E415F4956415F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22526574656E63696F6E506F72632220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223331332C37303130303436352220546F703D223130222057696474683D2237312C383131303722204865696768743D2231352C313138313222204F6E4265666F72655072696E743D22526574656E63696F6E506F72634F6E4265666F72655072696E742220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D222520522E452E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22526574656E63696F6E546F742220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339342C36333031393436352220546F703D223130222057696474683D2237312C383131303722204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22546F74616C20522E452E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F4956414E5F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232383436352220546F703D2233362C3435363731222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F4956414E5F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F4956414E5F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223134372C34303136383436352220546F703D2233362C3435363731222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F4956414E5F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F495641525F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223134372C34303136383436352220546F703D2236322C3931333432222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F495641525F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F495641535F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223134372C34303136383436352220546F703D2238392C3337303133222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F495641535F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F495641455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223134372C34303136383436352220546F703D223131352C3832363834222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F495641455F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F495641525F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232383436352220546F703D2236322C3931333432222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446174614669656C643D22544F54414C5F495641525F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F495641525F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F495641535F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232383436352220546F703D2238392C3337303133222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446174614669656C643D22544F54414C5F495641535F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F495641535F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F495641455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232383436352220546F703D223131352C3832363834222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446174614669656C643D22544F54414C5F495641455F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F495641455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F52454E5F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223331332C37303130303436352220546F703D2233362C3435363731222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F52454E5F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F5245525F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223331332C37303130303436352220546F703D2236322C3931333432222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F5245525F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F5245455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223331332C37303130303436352220546F703D223131352C3832363834222057696474683D2235362C363932393522204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F5245455F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F5243454E5F5245535F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223331332C37303130303436352220546F703D2238392C3337303133222057696474683D2235322C393133343222204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B504F5243454E5F5245535F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F52454E5F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339342C36333031393436352220546F703D2233362C3435363731222057696474683D2236342C323532303122204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224661637475726173544F54414C5F52454E5F464143545552414F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F52454E5F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F52454E5F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F5245455F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339342C36333031393436352220546F703D223131352C3832363834222057696474683D2236342C323532303122204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224661637475726173544F54414C5F5245455F464143545552414F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F5245455F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F5245455F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2242617365496D706F6E69626C65522220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231382C38393736363436352220546F703D2236322C3931333432222057696474683D2239342C343838323522204865696768743D2231382C383937363522204F6E4265666F72655072696E743D2242617365496D706F6E69626C65524F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F42415345495F495641525F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F42415345495F495641525F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2242617365496D706F6E69626C65532220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231382C38393736363436352220546F703D2238392C3337303133222057696474683D2239342C343838323522204865696768743D2231382C383937363522204F6E4265666F72655072696E743D2242617365496D706F6E69626C65534F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F42415345495F495641535F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F42415345495F495641535F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F5245525F46414354555241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339342C36333031393436352220546F703D2236322C3931333432222057696474683D2236382C303331353422204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224661637475726173544F54414C5F5245525F464143545552414F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F5245525F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F5245525F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173544F54414C5F5245535F46414354555241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223339342C36333031393436352220546F703D2238392C3337303133222057696474683D2236382C303331353422204865696768743D2231382C383937363522204F6E4265666F72655072696E743D224661637475726173544F54414C5F5245535F464143545552414F6E4265666F72655072696E742220446174614669656C643D22544F54414C5F5245535F464143545552412220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F5245535F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22526574656E63696F6E2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530372C31313834343436352220546F703D2238362C3932393139222057696474683D223134332C363232313422204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22526574656E6369C3B36E2049525046205B46616374757261732E262333343B504F5243454E5F524554454E43494F4E5F46414354555241262333343B5D25222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22526574656E63696F6E546F74616C2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223634312C30373931373436352220546F703D2238362C3932393139222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22526574656E63696F6E546F74616C4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B262336303B46616374757261732E262333343B544F54414C5F524554454E43494F4E5F46414354555241262333343B262336323B202A20282D31295D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22496D70756573746F73546F74616C2220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223634322C31393732393436352220546F703D2235382C353832373135222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22496D70756573746F73546F74616C4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F494D50554553544F535F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22496D70756573746F732220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530382C32333635363436352220546F703D2235382C353832373135222057696474683D223134332C363232313422204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22496D70756573746F734F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22546F74616C20495641202B205245222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22546F74616C42617365732220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223634322C31393732393436352220546F703D2233302C3233363234222057696474683D2237392C333730313322204865696768743D2231382C383937363522204F6E4265666F72655072696E743D22496D70756573746F73546F74616C4F6E4265666F72655072696E742220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F42415345535F46414354555241262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22546F74616C42617365496D706F6E69626C652220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530382C32333635363436352220546F703D2233302C3233363234222057696474683D223134332C363232313422204865696768743D2231382C38393736352220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225672220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22546F74616C204261736520496D706F6E69626C65222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173434F4D454E544152494F535F464143545552412220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2231392C38393736363436352220546F703D223138382C3430313637222057696474683D223731302C353531363422204865696768743D2233302C32333632342220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D222D31363737373230382220466F6E742E4865696768743D222D31312220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B566172546F53747228262336303B46616374757261732E262333343B544558544F5F4C4547414C5F464143545552415F434C49454E54455F46414354555241262333343B262336323B292B272020272B262331333B262331303B20566172546F53747228262336303B46616374757261732E262333343B544558544F5F4C4547414C5F464143545552415F454D50524553415F46414354555241262333343B262336323B29202B272020272B262331333B262331303B20566172546F53747228262336303B46616374757261732E262333343B434F4D454E544152494F535F46414354555241262333343B262336323B295D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466F726D615061676F2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232322C36373731393436352220546F703D223135372C3430313637222057696474683D223639392C323133303522204865696768743D2233372C3739353322204F6E4265666F72655072696E743D22466F726D615061676F4F6E4265666F72655072696E742220537472657463684D6F64653D22736D41637475616C48656967687422204175746F57696474683D22547275652220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22466F726D61206465205061676F3A205B46616374757261732E262333343B4445534352495043494F4E5F464F524D415041474F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D226D4E756D506167696E61732220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223631362C32383338362220546F703D223231392C37373138222057696474683D223131332C3338353922204865696768743D2232322C363737313822204F6E4265666F72655072696E743D226D4E756D506167696E61734F6E4265666F72655072696E742220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D2250C3A167696E61205B262336303B50616765262336323B5D206465205B262336303B546F74616C506167657323262336323B5D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D22436F6E74696E75612220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232322C36373731382220546F703D2230222057696474683D223330392C393231343622204865696768743D2232322C36373731382220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D2231363737373231352220466F6E742E4865696768743D222D31362220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D22436F6E74696EC3BA6120656E206C61207369677569656E74652070C3A167696E61202E2E2E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D226D546F74616C466163747572614374642220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223539362C36303636382220546F703D223132342C3732343439222057696474683D223132342C373234343922204865696768743D2232322C36373731382220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31362220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D223022204672616D652E57696474683D22312C35222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B46616374757261732E262333343B544F54414C5F4C49515549444F5F46414354555241262333343B5D222F3E0D0A202020203C2F5466727850616765466F6F7465723E0D0A20203C2F546672785265706F7274506167653E0D0A3C2F546672785265706F72743E0D0A, '2024-02-12 09:43:59', '2024-02-12 09:43:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Administradores', 'inLibtb', 'oSimbolosProhibidos', '+-%/\\?*€\"\',', NULL, NULL, NULL, '2026-02-16 18:28:13', '2026-02-16 18:02:33', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmLogon', 'DataBaseVersion', '1.0.0.20231204.alpha', NULL, NULL, NULL, '2023-12-01 19:54:58', '2023-12-01 19:54:49', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnAceptar_Caption', '&Aceptar', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnCancelar_Caption', '&Cancelar', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnCancelar1_Caption', '&Cancelar', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnCargarCaptions_Caption', '&Cargar captions', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnCargarColumnas_Caption', '&Cargar columnas', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnCargarVblesGlob_Caption', '&Cargar Vbles Globales', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnGrabar_Caption', '&Grabar', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'btnSalir_Caption', '出来', '', NULL, NULL, '2023-08-28 14:49:47', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin__oApplyWidth', 'True', NULL, NULL, NULL, '2023-05-16 13:10:31', '2023-05-16 13:10:23', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_ACTIVO_ARTICULO_Caption', 'ACTIVO_ARTICULO', '', NULL, NULL, '2022-10-26 19:35:37', '2022-10-26 19:35:37', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_ACTIVO_ARTICULO_Index', '1', '', NULL, NULL, '2022-10-26 19:35:37', '2022-10-26 19:35:37', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_ACTIVO_ARTICULO_Visible', 'False', '', NULL, NULL, '2023-01-25 13:19:33', '2022-10-26 19:35:37', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_ACTIVO_ARTICULO_Width', '153', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:37', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_ARTICULO_Caption', 'Código Artículo', '', NULL, NULL, '2023-01-25 13:19:54', '2022-10-26 19:35:27', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_ARTICULO_Index', '0', '', NULL, NULL, '2022-10-26 19:35:12', '2022-10-26 19:35:12', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_ARTICULO_Visible', 'True', '', NULL, NULL, '2022-10-26 19:35:07', '2022-10-26 19:35:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_ARTICULO_Width', '156', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:27', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_FAMILIA_ARTICULO_Caption', 'Código Familia', '', NULL, NULL, '2023-01-25 13:22:04', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_FAMILIA_ARTICULO_Index', '5', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_FAMILIA_ARTICULO_Visible', 'True', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_FAMILIA_ARTICULO_Width', '118', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_TARIFA_Caption', 'Tarifa', '', NULL, NULL, '2023-01-25 13:26:26', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_TARIFA_Index', '8', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_TARIFA_Visible', 'True', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_CODIGO_TARIFA_Width', '134', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_ARTICULO_Caption', 'Descripción', '', NULL, NULL, '2023-01-25 13:20:18', '2022-10-26 19:35:40', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_ARTICULO_Index', '2', '', NULL, NULL, '2022-10-26 19:35:40', '2022-10-26 19:35:40', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_ARTICULO_Visible', 'True', '', NULL, NULL, '2022-10-26 19:35:40', '2022-10-26 19:35:40', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_ARTICULO_Width', '197', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:40', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_FAMILIA_Caption', 'Familia', '', NULL, NULL, '2023-01-25 13:22:11', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_FAMILIA_Index', '6', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_FAMILIA_Visible', 'True', '', NULL, NULL, '2022-10-26 19:35:45', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_DESCRIPCION_FAMILIA_Width', '438', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_IMP_INCL_TARIFA_Caption', 'Incluye IVA', '', NULL, NULL, '2023-01-25 13:24:27', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_IMP_INCL_TARIFA_Index', '9', '', NULL, NULL, '2022-10-26 19:35:45', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_IMP_INCL_TARIFA_Visible', 'True', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_IMP_INCL_TARIFA_Width', '143', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Caption', 'INSTANTEALTA', '', NULL, NULL, '2022-10-26 19:35:46', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Index', '11', '', NULL, NULL, '2022-10-26 19:35:46', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Visible', 'False', '', NULL, NULL, '2023-01-25 13:20:37', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Width', '161', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Caption', 'INSTANTEMODIF', '', NULL, NULL, '2022-10-26 19:35:46', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Index', '12', '', NULL, NULL, '2022-10-26 19:35:46', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Visible', 'False', '', NULL, NULL, '2023-01-25 13:20:41', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Width', '161', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_PRECIOFINAL_Caption', 'Precio', '', NULL, NULL, '2023-01-25 13:23:38', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_PRECIOFINAL_Index', '3', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_PRECIOFINAL_Visible', 'True', '', NULL, NULL, '2022-10-26 19:35:45', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_PRECIOFINAL_Width', '107', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPO_CANTIDAD_ARTICULO_Caption', 'Tipo Cantidad', '', NULL, NULL, '2023-01-25 13:22:57', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPO_CANTIDAD_ARTICULO_Index', '4', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPO_CANTIDAD_ARTICULO_Visible', 'True', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPO_CANTIDAD_ARTICULO_Width', '113', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPOIVA_ARTICULO_Caption', 'Tipo IVA', '', NULL, NULL, '2023-01-25 13:25:48', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPOIVA_ARTICULO_Index', '7', '', NULL, NULL, '2023-01-25 13:27:23', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPOIVA_ARTICULO_Visible', 'True', '', NULL, NULL, '2022-10-26 19:35:45', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_TIPOIVA_ARTICULO_Width', '158', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOALTA_Caption', 'USUARIOALTA', '', NULL, NULL, '2022-10-26 19:35:46', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOALTA_Index', '13', '', NULL, NULL, '2022-10-26 19:35:46', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOALTA_Visible', 'False', '', NULL, NULL, '2023-01-25 13:20:53', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOALTA_Width', '117', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:46', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Caption', 'USUARIOMODIF', '', NULL, NULL, '2022-10-26 19:35:45', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Index', '10', '', NULL, NULL, '2022-10-26 19:35:45', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Visible', 'False', '', NULL, NULL, '2023-01-25 13:20:56', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Width', '126', '', NULL, NULL, '2023-01-25 13:19:18', '2022-10-26 19:35:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'lblEditMode_Caption', 'Navegando', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'lblTablaOrigen_Caption', 'TablaOrigen', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'lblTextoaBuscar_Caption', 'Texto a buscar', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'lblTextoaBuscarPerfil_Caption', 'Texto a buscar', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'oApplyWidth', 'True', '', NULL, NULL, '2023-01-25 13:21:22', '2022-10-26 19:51:03', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'oBusqGlobal', 'Grid', '', NULL, NULL, '2023-01-25 12:59:29', '2022-10-26 19:51:03', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'oCreateItems', 'True', '', NULL, NULL, '2023-01-25 13:19:10', '2022-10-26 19:51:03', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'tsFicha_Caption', '&Ficha', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'tsLista_Caption', '&Lista', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSearch', 'tsPerfil_Caption', 'Perfil', '', NULL, NULL, '2022-10-26 19:50:59', '2022-10-26 19:50:59', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtFacSerach', 'cxGrdDBTabPrin_PRECIOFINAL_PropertiesClass', 'TcxCurrencyEditProperties', NULL, NULL, NULL, '2022-10-26 20:39:55', '2022-10-26 20:37:01', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnAceptar_Caption', '&Aceptar', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnCancelar_Caption', '&Cancelar', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnCancelar1_Caption', '&Cancelar', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnCargarCaptions_Caption', '&Cargar captions', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnCargarColumnas_Caption', '&Cargar columnas', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnCargarVblesGlob_Caption', '&Cargar Vbles Globales', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnGrabar_Caption', '&Grabar', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'btnSalir_Caption', '出来', '', NULL, NULL, '2023-08-28 14:49:51', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin__oApplyWidth', 'True', NULL, NULL, NULL, '2023-05-25 13:06:55', '2023-05-25 13:05:19', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_ACTIVO_PROVEEDOR_Caption', 'Activo', '', NULL, NULL, '2023-05-25 13:01:53', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_ACTIVO_PROVEEDOR_Index', '1', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_ACTIVO_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_ACTIVO_PROVEEDOR_Width', '175', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CODIGO_PROVEEDOR_Caption', 'Código Proveedor', '', NULL, NULL, '2023-05-25 13:01:58', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CODIGO_PROVEEDOR_Index', '0', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CODIGO_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CODIGO_PROVEEDOR_Width', '181', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CONTACTO_PROVEEDOR_Caption', 'Contacto Proveedor', '', NULL, NULL, '2023-05-25 13:02:03', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CONTACTO_PROVEEDOR_Index', '14', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CONTACTO_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CONTACTO_PROVEEDOR_Width', '227', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CPOSTAL_PROVEEDOR_Caption', 'Código Postal', '', NULL, NULL, '2023-05-25 13:02:11', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CPOSTAL_PROVEEDOR_Index', '10', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CPOSTAL_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_CPOSTAL_PROVEEDOR_Width', '185', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION1_PROVEEDOR_Caption', 'Dirección', '', NULL, NULL, '2023-05-25 13:02:14', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION1_PROVEEDOR_Index', '6', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION1_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION1_PROVEEDOR_Width', '392', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION2_PROVEEDOR_Caption', 'Dirección 2', '', NULL, NULL, '2023-05-25 13:02:20', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION2_PROVEEDOR_Index', '7', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION2_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_DIRECCION2_PROVEEDOR_Width', '218', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_EMAIL_PROVEEDOR_Caption', 'Email', '', NULL, NULL, '2023-05-25 13:02:23', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_EMAIL_PROVEEDOR_Index', '5', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_EMAIL_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_EMAIL_PROVEEDOR_Width', '164', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_IBAN_PROVEEDOR_Caption', 'IBAN', '', NULL, NULL, '2023-05-25 13:02:26', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_IBAN_PROVEEDOR_Index', '17', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_IBAN_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_IBAN_PROVEEDOR_Width', '152', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Caption', 'INSTANTEALTA', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Index', '19', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Visible', 'False', '', NULL, NULL, '2023-05-25 13:02:30', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Width', '193', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Caption', 'INSTANTEMODIF', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Index', '18', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Visible', 'False', '', NULL, NULL, '2023-05-25 13:02:33', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Width', '193', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_MOVIL_PROVEEDOR_Caption', 'Móvil', '', NULL, NULL, '2023-05-25 13:02:39', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_MOVIL_PROVEEDOR_Index', '4', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_MOVIL_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_MOVIL_PROVEEDOR_Width', '168', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_NIF_PROVEEDOR_Caption', 'Nif', '', NULL, NULL, '2023-05-25 13:02:43', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_NIF_PROVEEDOR_Index', '3', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_NIF_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_NIF_PROVEEDOR_Width', '141', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_OBSERVACIONES_PROVEEDOR_Caption', 'Observaciones', '', NULL, NULL, '2023-05-25 13:02:47', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_OBSERVACIONES_PROVEEDOR_Index', '12', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_OBSERVACIONES_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_OBSERVACIONES_PROVEEDOR_Width', '248', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PAIS_PROVEEDOR_Caption', 'País', '', NULL, NULL, '2023-05-25 13:02:55', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PAIS_PROVEEDOR_Index', '11', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PAIS_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PAIS_PROVEEDOR_Width', '147', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_POBLACION_PROVEEDOR_Caption', 'Población', '', NULL, NULL, '2023-05-25 13:02:59', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_POBLACION_PROVEEDOR_Index', '8', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_POBLACION_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_POBLACION_PROVEEDOR_Width', '208', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PROVINCIA_PROVEEDOR_Caption', 'Provincia', '', NULL, NULL, '2023-05-25 13:03:02', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PROVINCIA_PROVEEDOR_Index', '9', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PROVINCIA_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_PROVINCIA_PROVEEDOR_Width', '204', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_PROVEEDOR_Caption', 'Razón Social', '', NULL, NULL, '2023-05-25 13:03:05', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_PROVEEDOR_Index', '2', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_PROVEEDOR_Width', '292', '', NULL, NULL, '2023-05-25 13:00:04', '2023-05-25 13:00:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_REFERENCIA_PROVEEDOR_Caption', 'Referencia', '', NULL, NULL, '2023-05-25 13:03:08', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_REFERENCIA_PROVEEDOR_Index', '13', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_REFERENCIA_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_REFERENCIA_PROVEEDOR_Width', '213', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_PROVEEDOR_Caption', 'Teléfono Contacto', '', NULL, NULL, '2023-05-25 13:03:30', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_PROVEEDOR_Index', '15', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_PROVEEDOR_Width', '300', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_PROVEEDOR_Caption', 'Teléfono', '', NULL, NULL, '2023-05-25 13:03:33', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_PROVEEDOR_Index', '16', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_PROVEEDOR_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_TELEFONO_PROVEEDOR_Width', '198', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOALTA_Caption', 'USUARIOALTA', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOALTA_Index', '20', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOALTA_Visible', 'False', '', NULL, NULL, '2023-05-25 13:03:37', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOALTA_Width', '127', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Caption', 'USUARIOMODIF', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Index', '21', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Visible', 'False', '', NULL, NULL, '2023-05-25 13:03:42', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Width', '140', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'lblEditMode_Caption', 'Navegando', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'lblTablaOrigen_Caption', 'vi_proveedores', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'lblTextoaBuscar_Caption', 'Texto a buscar', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'lblTextoaBuscarPerfil_Caption', 'Texto a buscar', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'oApplyWidth', 'True', '', NULL, NULL, '2023-05-25 13:01:22', '2023-05-25 13:01:22', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'oBusqGlobal', 'Grid', '', NULL, NULL, '2023-05-25 13:01:22', '2023-05-25 13:01:22', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'oCreateItems', 'False', '', NULL, NULL, '2023-05-25 13:01:22', '2023-05-25 13:01:22', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tsFicha_Caption', '&Ficha', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tsLista_Caption', '&Lista', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tsPerfil_Caption', 'Perfil', '', NULL, NULL, '2023-05-25 13:01:17', '2023-05-25 13:01:17', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_KEY_PERFILES_Caption', 'KEY_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_KEY_PERFILES_Index', '1', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_KEY_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_KEY_PERFILES_Width', '132', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_SUBKEY_PERFILES_Caption', 'SUBKEY_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_SUBKEY_PERFILES_Index', '2', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_SUBKEY_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_SUBKEY_PERFILES_Width', '190', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_TYPE_BLOB_PERFILES_Caption', 'TYPE_BLOB_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_TYPE_BLOB_PERFILES_Index', '5', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_TYPE_BLOB_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_TYPE_BLOB_PERFILES_Width', '114', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_USUARIO_GRUPO_PERFILES_Caption', 'USUARIO_GRUPO_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_USUARIO_GRUPO_PERFILES_Index', '0', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_USUARIO_GRUPO_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_USUARIO_GRUPO_PERFILES_Width', '167', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_BLOB_PERFILES_Caption', 'VALUE_BLOB_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_BLOB_PERFILES_Index', '6', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_BLOB_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_BLOB_PERFILES_Width', '114', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_PERFILES_Caption', 'VALUE_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_PERFILES_Index', '3', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_PERFILES_Width', '112', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_TEXT_PERFILES_Caption', 'VALUE_TEXT_PERFILES', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_TEXT_PERFILES_Index', '4', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_TEXT_PERFILES_Visible', 'True', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoArtProvSearch', 'tvPerfil_VALUE_TEXT_PERFILES_Width', '140', '', NULL, NULL, '2023-05-25 13:00:05', '2023-05-25 13:00:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerAvisoStockWarning', 'Artículo sin Stock. Compruebe Stock en almacén', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerBusqArtStockOnly', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerBusqArtTarifaOnly', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerCaducidadDefVale', 'False', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerChkExistOnly', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerChkStockOnly', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerCodEmpleadoDefecto', '1', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerDefPrinter', 'Generic', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerDefTarifa', 'PVP', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerDiasCaducidadVale', '365', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerFillEmpleadoDefecto', 'False', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerFormatoImpPredet', '', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerMaxOpPending', '5', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerMoverLineaIdentif', 'False', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerRecuperaValePIN', 'False', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerReqRefDevolucion', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerShowCajaSelection', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerShowEmpleadoLinea', 'True', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCajaParam', 'vgerTipoImpresion', 'ESC POS', NULL, NULL, NULL, '2026-02-21 07:32:45', '2026-02-21 07:32:45', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnAceptar_Caption', '&Aceptar', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnCancelar_Caption', '&Cancelar', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnCancelar1_Caption', '&Cancelar', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnCargarCaptions_Caption', '&Cargar captions', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnCargarColumnas_Caption', '&Cargar columnas', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnCargarVblesGlob_Caption', '&Cargar Vbles Globales', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnGrabar_Caption', '&Grabar', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'btnSalir_Caption', '出来', '', NULL, NULL, '2023-08-28 14:49:56', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin__oApplyWidth', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ACTIVO_CLIENTE_Index', '1', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ACTIVO_CLIENTE_Visible', 'False', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_CLIENTE_Caption', 'Código Cliente', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_CLIENTE_Index', '0', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_CLIENTE_Width', '131', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_FORMA_PAGO_CLIENTE_Caption', 'Forma de Pago', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_FORMA_PAGO_CLIENTE_Index', '23', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_FORMA_PAGO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CODIGO_FORMA_PAGO_CLIENTE_Width', '139', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CONTACTO_CLIENTE_Caption', 'Contacto', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CONTACTO_CLIENTE_Index', '14', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CONTACTO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CONTACTO_CLIENTE_Width', '164', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CPOSTAL_CLIENTE_Caption', 'Código Postal', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CPOSTAL_CLIENTE_Index', '10', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CPOSTAL_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_CPOSTAL_CLIENTE_Width', '141', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION1_CLIENTE_Caption', 'Dirección 1', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION1_CLIENTE_Index', '6', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION1_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION1_CLIENTE_Width', '312', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION2_CLIENTE_Caption', 'Dirección 2', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION2_CLIENTE_Index', '7', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION2_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_DIRECCION2_CLIENTE_Width', '86', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_EMAIL_CLIENTE_Caption', 'Email', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_EMAIL_CLIENTE_Index', '5', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_EMAIL_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_EMAIL_CLIENTE_Width', '249', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESINTRACOMUNITARIO_CLIENTE_Caption', 'Intracomunitario', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESINTRACOMUNITARIO_CLIENTE_Index', '22', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESINTRACOMUNITARIO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESINTRACOMUNITARIO_CLIENTE_Width', '256', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_EXENTO_CLIENTE_Caption', 'IVA Exento', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_EXENTO_CLIENTE_Index', '20', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_EXENTO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_EXENTO_CLIENTE_Width', '193', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_RECARGO_CLIENTE_Caption', 'Tiene Recargo', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_RECARGO_CLIENTE_Index', '18', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_RECARGO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESIVA_RECARGO_CLIENTE_Width', '206', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_CLIENTE_Caption', 'Es Agricultor REAGP', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_CLIENTE_Index', '21', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_CLIENTE_Width', '315', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_CLIENTE_Caption', 'Retiene IRPF', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_CLIENTE_Index', '19', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_CLIENTE_Width', '203', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_IBAN_CLIENTE_Caption', 'Nro Cuenta IBAN', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_IBAN_CLIENTE_Index', '17', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_IBAN_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_IBAN_CLIENTE_Width', '143', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Index', '28', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_INSTANTEALTA_Visible', 'False', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Index', '27', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_INSTANTEMODIF_Visible', 'False', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_MOVIL_CLIENTE_Caption', 'Móvil', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_MOVIL_CLIENTE_Index', '4', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_MOVIL_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_MOVIL_CLIENTE_Width', '136', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_NIF_CLIENTE_Caption', 'Nif', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_NIF_CLIENTE_Index', '3', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_NIF_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_NIF_CLIENTE_Width', '142', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_OBSERVACIONES_CLIENTE_Caption', 'Observaciones', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_OBSERVACIONES_CLIENTE_Index', '12', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_OBSERVACIONES_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_OBSERVACIONES_CLIENTE_Width', '196', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PAIS_CLIENTE_Caption', 'País', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PAIS_CLIENTE_Index', '11', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PAIS_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PAIS_CLIENTE_Width', '56', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_POBLACION_CLIENTE_Caption', 'Población', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_POBLACION_CLIENTE_Index', '8', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_POBLACION_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_POBLACION_CLIENTE_Width', '227', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PROVINCIA_CLIENTE_Caption', 'Provincia', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PROVINCIA_CLIENTE_Index', '9', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PROVINCIA_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_PROVINCIA_CLIENTE_Width', '177', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_CLIENTE_Caption', 'Razón Social', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_CLIENTE_Index', '2', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_CLIENTE_Width', '292', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_REFERENCIA_CLIENTE_Caption', 'Referencia', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_REFERENCIA_CLIENTE_Index', '13', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_REFERENCIA_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_REFERENCIA_CLIENTE_Width', '87', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_CLIENTE_Caption', 'Serie Particular de Facturación', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_CLIENTE_Index', '24', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_CLIENTE_Width', '227', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TARIFA_ARTICULO_CLIENTE_Caption', 'Tarifa Artículos', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TARIFA_ARTICULO_CLIENTE_Index', '25', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TARIFA_ARTICULO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TARIFA_ARTICULO_CLIENTE_Width', '209', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CLIENTE_Caption', 'Teléfono', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CLIENTE_Index', '16', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CLIENTE_Width', '161', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_CLIENTE_Caption', 'Teléfono Contacto', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_CLIENTE_Index', '15', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TELEFONO_CONTACTO_CLIENTE_Width', '151', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_CLIENTE_Caption', 'Texto en Factura', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_CLIENTE_Index', '26', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_CLIENTE_Visible', 'True', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_CLIENTE_Width', '605', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_USUARIOALTA_Index', '29', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_USUARIOALTA_Visible', 'False', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Index', '30', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'cxGrdDBTabPrin_USUARIOMODIF_Visible', 'False', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'lblEditMode_Caption', 'Navegando', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'lblTablaOrigen_Caption', 'vi_cli_busquedas', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'lblTextoaBuscar_Caption', 'Texto a buscar', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'lblTextoaBuscarPerfil_Caption', 'Texto a buscar', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'oApplyWidth', 'True', '', NULL, NULL, '2023-12-14 17:40:51', '2023-01-24 21:08:27', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'oBusqGlobal', 'Grid', '', NULL, NULL, '2023-01-24 21:09:20', '2023-01-24 21:08:27', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'oCreateItems', 'True', '', NULL, NULL, '2023-12-14 17:40:55', '2023-01-24 21:08:27', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'oGetSQLFromDB', 'False', '', NULL, NULL, '2023-12-14 17:40:15', '2023-12-14 17:40:15', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'oMostrarPerfil', 'False', '', NULL, NULL, '2023-12-14 17:40:15', '2023-12-14 17:40:15', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'oRenameComponents', 'False', '', NULL, NULL, '2023-12-14 17:40:15', '2023-12-14 17:40:15', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'rbBBDD_Caption', 'Buscar BBDD', '', NULL, NULL, '2023-12-14 17:40:15', '2023-12-14 17:40:15', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'rbGrid_Caption', 'Buscar Grid', '', NULL, NULL, '2023-12-14 17:40:15', '2023-12-14 17:40:15', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'tsFicha_Caption', '&Ficha', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'tsLista_Caption', '&Lista', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'tsPerfil_Caption', 'Perfil', '', NULL, NULL, '2023-01-24 19:26:16', '2023-01-24 19:26:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoCliFacSearch', 'tvPerfil__oApplyWidth', 'False', '', NULL, NULL, '2023-12-14 17:40:16', '2023-12-14 17:40:16', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnAceptar_Caption', '&Aceptar', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnCancelar_Caption', '&Cancelar', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnCancelar1_Caption', '&Cancelar', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnCargarCaptions_Caption', '&Cargar captions', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnCargarColumnas_Caption', '&Cargar columnas', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnCargarVblesGlob_Caption', '&Cargar Vbles Globales', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnGrabar_Caption', '&Grabar', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'btnSalir_Caption', '出来', '', NULL, NULL, '2023-08-28 14:50:00', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin__oApplyWidth', 'True', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CODIGO_EMPRESA_Caption', 'Código Empresa', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CODIGO_EMPRESA_Index', '0', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CODIGO_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CODIGO_EMPRESA_Width', '142', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CPOSTAL_EMPRESA_Caption', 'Código Postal', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CPOSTAL_EMPRESA_Index', '7', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CPOSTAL_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_CPOSTAL_EMPRESA_Width', '122', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION1_EMPRESA_Caption', 'Dirección Principal', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION1_EMPRESA_Index', '5', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION1_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION1_EMPRESA_Width', '137', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION2_EMPRESA_Caption', 'Dirección Complementaria', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION2_EMPRESA_Index', '6', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION2_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_DIRECCION2_EMPRESA_Width', '193', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_EMAIL_EMPRESA_Caption', 'Email', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_EMAIL_EMPRESA_Index', '4', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_EMAIL_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_EMAIL_EMPRESA_Width', '204', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA_Caption', 'Es Agricultor REAGP', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA_Index', '14', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA_Width', '321', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_EMPRESA_Caption', 'Aplica retenciones IRPF', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_EMPRESA_Index', '13', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_ESRETENCIONES_EMPRESA_Width', '209', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_GRUPO_ZONA_IVA_EMPRESA_Caption', 'Grupo Iva', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_GRUPO_ZONA_IVA_EMPRESA_Index', '12', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_GRUPO_ZONA_IVA_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_GRUPO_ZONA_IVA_EMPRESA_Width', '226', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_MOVIL_EMPRESA_Caption', 'Teléfono Móvil', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_MOVIL_EMPRESA_Index', '3', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_MOVIL_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_MOVIL_EMPRESA_Width', '133', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_NIF_EMPRESA_Caption', 'Nif', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_NIF_EMPRESA_Index', '2', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_NIF_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_NIF_EMPRESA_Width', '110', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PAIS_EMPRESA_Caption', 'País', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PAIS_EMPRESA_Index', '10', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PAIS_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PAIS_EMPRESA_Width', '120', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_POBLACION_EMPRESA_Caption', 'Población', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_POBLACION_EMPRESA_Index', '8', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_POBLACION_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_POBLACION_EMPRESA_Width', '189', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PROVINCIA_EMPRESA_Caption', 'Provincia', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PROVINCIA_EMPRESA_Index', '9', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PROVINCIA_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_PROVINCIA_EMPRESA_Width', '170', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_EMPRESA_Caption', 'Razón Social', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_EMPRESA_Index', '1', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_RAZONSOCIAL_EMPRESA_Width', '248', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_EMPRESA_Caption', 'Serie Documentos', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_EMPRESA_Index', '11', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_SERIE_CONTADOR_EMPRESA_Width', '144', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_EMPRESA_Caption', 'Texto legal facturas', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_EMPRESA_Index', '15', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_EMPRESA_Visible', 'True', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'cxGrdDBTabPrin_TEXTO_LEGAL_FACTURA_EMPRESA_Width', '572', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'lblEditMode_Caption', 'Navegando', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'lblTablaOrigen_Caption', 'VI_EMP_BUSQUEDAS', '', NULL, NULL, '2023-01-27 09:39:13', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'lblTextoaBuscar_Caption', 'Texto a buscar', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'lblTextoaBuscarPerfil_Caption', 'Texto a buscar', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'oApplyWidth', 'True', '', NULL, NULL, '2023-12-14 17:36:43', '2022-10-26 16:29:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'oBusqGlobal', 'Grid', '', NULL, NULL, '2023-12-14 17:32:06', '2022-10-26 16:29:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'oCreateItems', 'False', '', NULL, NULL, '2023-12-14 17:32:06', '2022-10-26 16:29:04', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'oGetSQLFromDB', 'False', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'oMostrarPerfil', 'False', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'oRenameComponents', 'False', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'rbBBDD_Caption', 'Buscar BBDD', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'rbGrid_Caption', 'Buscar Grid', '', NULL, NULL, '2023-12-14 17:32:06', '2023-12-14 17:32:06', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'tsFicha_Caption', '&Ficha', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'tsLista_Caption', '&Lista', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'tsPerfil_Caption', 'Perfil', '', NULL, NULL, '2022-10-26 16:29:05', '2022-10-26 16:29:05', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmMtoEmpFacSearch', 'tvPerfil__oApplyWidth', 'False', '', NULL, NULL, '2023-12-14 17:32:07', '2023-12-14 17:32:07', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmPrintRecFac', 'frxrprt1_Buena', 'Buena', NULL, NULL, 0x3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D227574662D3822207374616E64616C6F6E653D226E6F223F3E0D0A3C546672785265706F72742056657273696F6E3D22362E392E332220446F744D61747269785265706F72743D2246616C73652220496E6946696C653D225C536F6674776172655C46617374205265706F7274732220507265766965774F7074696F6E732E427574746F6E733D22343039352220507265766965774F7074696F6E732E5A6F6F6D3D223122205072696E744F7074696F6E732E5072696E7465723D22506F72206465666563746F22205072696E744F7074696F6E732E5072696E744F6E53686565743D223022205265706F72744F7074696F6E732E417574686F723D2266616374757A616D22205265706F72744F7074696F6E732E437265617465446174653D2234323438312C3633343637353734303722205265706F72744F7074696F6E732E4465736372697074696F6E2E546578743D2222205265706F72744F7074696F6E732E4C6173744368616E67653D2234353033372C35353634323037303622205363726970744C616E67756167653D2250617363616C5363726970742220536372697074546578742E546578743D22626567696E262331333B262331303B262331333B262331303B656E642E223E0D0A20203C44617461736574733E0D0A202020203C6974656D20446174615365743D22646D46616374757261732E6678647352656369626F732220446174615365744E616D653D2252656369626F73222F3E0D0A20203C2F44617461736574733E0D0A20203C546672784461746150616765204E616D653D22446174612220484775696465732E546578743D222220564775696465732E546578743D2222204865696768743D223130303022204C6566743D22302220546F703D2230222057696474683D2231303030222F3E0D0A20203C546672785265706F727450616765204E616D653D2250616765312220484775696465732E546578743D222220564775696465732E546578743D222220506170657257696474683D22323130222050617065724865696768743D223239372220506170657253697A653D223922204C6566744D617267696E3D2235222052696768744D617267696E3D22352220546F704D617267696E3D2232302220426F74746F6D4D617267696E3D2232302220436F6C756D6E57696474683D22302220436F6C756D6E506F736974696F6E732E546578743D2222204672616D652E5479703D223022204D6972726F724D6F64653D2230223E0D0A202020203C546672784D617374657244617461204E616D653D224D61737465724461746131222046696C6C547970653D2266744272757368222046696C6C4761702E546F703D2230222046696C6C4761702E4C6566743D2230222046696C6C4761702E426F74746F6D3D2230222046696C6C4761702E52696768743D223022204672616D652E5479703D223022204865696768743D223334332C393337323322204C6566743D22302220546F703D2231382C3839373635222057696474683D223735352C3930362220436F6C756D6E57696474683D22302220436F6C756D6E4761703D22302220446174615365743D22646D46616374757261732E6678647352656369626F732220446174615365744E616D653D2252656369626F732220526F77436F756E743D2230223E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31302220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D2235392C3235323031222057696474683D223334332C393337323322204865696768743D2234392C31333338392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D22392C3839373635222057696474683D223135382C373430323622204865696768743D2234392C31333338392220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F322220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2233352C33353433362220546F703D2233362C3335343336222057696474683D223132342C373234343922204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686143656E7465722220506172656E74466F6E743D2246616C73652220546578743D225B262336303B52656369626F732E262333343B53455249455F464143545552415F52454349424F262333343B262336323B5D5C5B262336303B52656369626F732E262333343B4E524F5F464143545552415F52454349424F262333343B262336323B5D5C5B496E74546F53747228262336303B52656369626F732E262333343B4E524F5F504C415A4F5F52454349424F262333343B262336323B295D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D2231332C3637373138222057696474683D223131332C3338353922204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D2252454349424F204E524F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F342220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223137382C393736352220546F703D22392C3839373635222057696474683D223332312C323630303522204865696768743D2234392C31333338392220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F352220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232302C35353133332220546F703D2233362C3335343336222057696474683D223232362C3737313822204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B4C4F43414C494441445F45585045444943494F4E5F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F362220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223139302C33313530392220546F703D2231332C3637373138222057696474683D223137332C383538333822204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224C4F43414C49444144204445204558504544494349C3934E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F372220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530302C32333635352220546F703D22392C3839373635222057696474683D223232322C393932323722204865696768743D2234392C31333338392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F382220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223532322C39313337332220546F703D2231332C3637373138222057696474683D223137332C383538333822204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22494D504F5254452052454349424F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31322220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D2236362C35393036222057696474683D223138312C343137343422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224645434841204445204558504544494349C3934E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223336342C31373334372220546F703D2235392C3033313534222057696474683D223335392C303535333522204865696768743D2234392C31333338392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223337392C32393135392220546F703D2236362C3337303133222057696474683D223138312C343137343422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D2246454348412044452056454E43494D49454E544F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31342220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2233352C33353433362220546F703D223131332C33383539222057696474683D2237392C333730313322204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D22534F4E2045553A222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31352220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D223135382C3231323734222057696474683D223730322C393932353822204865696768743D2233302C32333632342220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31362220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223136322C37373138222057696474683D223138312C343137343422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22504147414445524F20454E202020262336303B4942414E262336323B20203A222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31382220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D223139352C3032333831222057696474683D223436382C363631373222204865696768743D223132342C37323434392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31392220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223230322C33363234222057696474683D223234312C383839393222204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22444F4D4943494C494F2059204E4F4D4252452044454C204C49425241444F3A222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617352415A4F4E534F4349414C5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223232352C3236303035222057696474683D223430302C363330313822204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B52415A4F4E534F4349414C5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173444952454343494F4E315F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223234372C3933373233222057696474683D223430302C363330313822204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B444952454343494F4E315F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617343504F5354414C5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223236362C3833343838222057696474683D223132302C393434393622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B43504F5354414C5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F424C4143494F4E5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223135362C32393933322220546F703D223236362C3833343838222057696474683D223237322C313236313622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B504F424C4143494F4E5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617350524F56494E4349415F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223238392C3531323036222057696474683D223332382C383139313122204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B50524F56494E4349415F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173434F4449474F5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223430352C373438332220546F703D223139382C3830333334222057696474683D2237392C333730313322204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B434F4449474F5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F32302220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530362C34353730322220546F703D223139382C3433333231222057696474683D223138382C3937363522204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31312220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22434F4E464F524D452C20454C204C49425241444F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173494D504F5254455F4C45545241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223132302C39343439362220546F703D223131332C33383539222057696474683D223531342C303136303822204865696768743D2233372C373935332220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B494D504F5254455F4C455452415F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734942414E2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232372220546F703D223136322C37373138222057696474683D223237322C313236313622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B4942414E5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617346454348415F45585045444943494F4E2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232372220546F703D2238312C35393036222057696474683D223130392C363036333722204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220446973706C6179466F726D61742E466F726D61745374723D2264642F6D6D2F797979792220446973706C6179466F726D61742E4B696E643D22666B4461746554696D6522204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B46454348415F45585045444943494F4E5F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617346454348415F56454E43494D49454E544F2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223537342C34383835362220546F703D2238312C35393036222057696474683D223130322C303437333122204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220446973706C6179466F726D61742E466F726D61745374723D2264642F6D6D2F797979792220446973706C6179466F726D61742E4B696E643D22666B4461746554696D6522204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B46454348415F56454E43494D49454E544F5F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734555524F535F52454349424F2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223532312C35373531342220546F703D2233322C3435363731222057696474683D223137332C383538333822204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B4555524F535F52454349424F262333343B5D222F3E0D0A2020202020203C546672784C696E6556696577204E616D653D224C696E65312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D22302220546F703D223333342C3831393131222057696474683D223735392C363835353322204865696768743D22302220436F6C6F723D223022204672616D652E5374796C653D2266734461736822204672616D652E5479703D2234222F3E0D0A202020203C2F546672784D6173746572446174613E0D0A20203C2F546672785265706F7274506167653E0D0A3C2F546672785265706F72743E0D0A, '2023-04-21 13:21:21', '2023-04-21 13:21:21', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'frmPrintRecFac', 'frxrprt1_cola cao', 'cola cao', NULL, NULL, 0x3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D227574662D3822207374616E64616C6F6E653D226E6F223F3E0D0A3C546672785265706F72742056657273696F6E3D22323032322E332220446F744D61747269785265706F72743D2246616C73652220496E6946696C653D225C536F6674776172655C46617374205265706F7274732220507265766965774F7074696F6E732E427574746F6E733D22343039352220507265766965774F7074696F6E732E5A6F6F6D3D223122205072696E744F7074696F6E732E5072696E7465723D22506F72206465666563746F22205072696E744F7074696F6E732E5072696E744F6E53686565743D223022205265706F72744F7074696F6E732E417574686F723D2246616374755A616D22205265706F72744F7074696F6E732E437265617465446174653D2234323438312C3633343637353734303722205265706F72744F7074696F6E732E4465736372697074696F6E2E546578743D2222205265706F72744F7074696F6E732E4C6173744368616E67653D2234353639342C3836363236303532303822205363726970744C616E67756167653D2250617363616C5363726970742220536372697074546578742E546578743D22626567696E262331333B262331303B262331333B262331303B656E642E223E0D0A20203C44617461736574733E0D0A202020203C6974656D20446174615365743D22646D46616374757261732E6678647352656369626F732220446174615365744E616D653D2252656369626F73222F3E0D0A20203C2F44617461736574733E0D0A20203C546672784461746150616765204E616D653D22446174612220484775696465732E546578743D222220564775696465732E546578743D2222204865696768743D223130303022204C6566743D22302220546F703D2230222057696474683D2231303030222F3E0D0A20203C546672785265706F727450616765204E616D653D2250616765312220484775696465732E546578743D222220564775696465732E546578743D222220506170657257696474683D22323130222050617065724865696768743D223239372220506170657253697A653D223922204C6566744D617267696E3D2235222052696768744D617267696E3D22352220546F704D617267696E3D2232302220426F74746F6D4D617267696E3D2232302220436F6C756D6E57696474683D22302220436F6C756D6E506F736974696F6E732E546578743D2222204672616D652E5479703D223022204D6972726F724D6F64653D2230223E0D0A202020203C546672784D617374657244617461204E616D653D224D61737465724461746131222046696C6C547970653D2266744272757368222046696C6C4761702E546F703D2230222046696C6C4761702E4C6566743D2230222046696C6C4761702E426F74746F6D3D2230222046696C6C4761702E52696768743D223022204672616D652E5479703D223022204865696768743D223334332C393337323322204C6566743D22302220546F703D2231382C3839373635222057696474683D223735352C3930362220436F6C756D6E57696474683D22302220436F6C756D6E4761703D22302220446174615365743D22646D46616374757261732E6678647352656369626F732220446174615365744E616D653D2252656369626F732220526F77436F756E743D2230223E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31302220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D2235392C3235323031222057696474683D223334332C393337323322204865696768743D2234392C31333338392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D22392C3839373635222057696474683D223135382C373430323622204865696768743D2234392C31333338392220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F322220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2233352C33353433362220546F703D2233362C3335343336222057696474683D223132342C373234343922204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686143656E7465722220506172656E74466F6E743D2246616C73652220546578743D225B262336303B52656369626F732E262333343B53455249455F464143545552415F52454349424F262333343B262336323B5D5C5B262336303B52656369626F732E262333343B4E524F5F464143545552415F52454349424F262333343B262336323B5D5C5B496E74546F53747228262336303B52656369626F732E262333343B4E524F5F504C415A4F5F52454349424F262333343B262336323B295D223E0D0A20202020202020203C466F726D6174733E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A202020202020202020203C6974656D2F3E0D0A20202020202020203C2F466F726D6174733E0D0A2020202020203C2F546672784D656D6F566965773E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D2231332C3637373138222057696474683D223131332C3338353922204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D2252454349424F204E524F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F342220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223137382C393736352220546F703D22392C3839373635222057696474683D223332312C323630303522204865696768743D2234392C31333338392220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F352220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232302C35353133332220546F703D2233362C3335343336222057696474683D223232362C3737313822204865696768743D2231352C31313831322220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B4C4F43414C494441445F45585045444943494F4E5F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F362220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223139302C33313530392220546F703D2231332C3637373138222057696474683D223137332C383538333822204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224C4F43414C49444144204445204558504544494349C3934E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F372220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530302C32333635352220546F703D22392C3839373635222057696474683D223232322C393932323722204865696768743D2234392C31333338392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F382220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223532322C39313337332220546F703D2231332C3637373138222057696474683D223137332C383538333822204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22494D504F5254452052454349424F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31322220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D2236362C35393036222057696474683D223138312C343137343422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D224645434841204445204558504544494349C3934E222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223336342C31373334372220546F703D2235392C3033313534222057696474683D223335392C303535333522204865696768743D2234392C31333338392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31332220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223337392C32393135392220546F703D2236362C3337303133222057696474683D223138312C343137343422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D2246454348412044452056454E43494D49454E544F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31342220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2233352C33353433362220546F703D223131332C33383539222057696474683D2237392C333730313322204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D22534F4E2045553A222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31352220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D223135382C3231323734222057696474683D223730322C393932353822204865696768743D2233302C32333632342220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31362220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223136322C37373138222057696474683D223138312C343137343422204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22504147414445524F20454E202020262336303B4942414E262336323B20203A222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31382220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232302C32333632342220546F703D223139352C3032333831222057696474683D223436382C363631373222204865696768743D223132342C37323434392220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2231352220506172656E74466F6E743D2246616C73652220546578743D22222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F31392220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223230322C33363234222057696474683D223234312C383839393222204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31322220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22444F4D4943494C494F2059204E4F4D4252452044454C204C49425241444F3A222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617352415A4F4E534F4349414C5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223232352C3236303035222057696474683D223430302C363330313822204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223122204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B52415A4F4E534F4349414C5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173444952454343494F4E315F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223234372C3933373233222057696474683D223430302C363330313822204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B444952454343494F4E315F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617343504F5354414C5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223236362C3833343838222057696474683D223132302C393434393622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B43504F5354414C5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173504F424C4143494F4E5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223135362C32393933322220546F703D223236362C3833343838222057696474683D223237322C313236313622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B504F424C4143494F4E5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617350524F56494E4349415F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D2232372C373935332220546F703D223238392C3531323036222057696474683D223332382C383139313122204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B50524F56494E4349415F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173434F4449474F5F434C49454E54452220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223430352C373438332220546F703D223139382C3830333334222057696474683D2237392C333730313322204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B434F4449474F5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F32302220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223530362C34353730322220546F703D223139382C3433333231222057696474683D223138382C3937363522204865696768743D2231382C38393736352220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31312220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22434F4E464F524D452C20454C204C49425241444F222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224661637475726173494D504F5254455F4C45545241312220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223132302C39343439362220546F703D223131332C33383539222057696474683D223531342C303136303822204865696768743D2233372C373935332220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B494D504F5254455F4C455452415F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734942414E2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232372220546F703D223136322C37373138222057696474683D223237322C313236313622204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D22466163747572617322204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B4942414E5F434C49454E54455F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617346454348415F45585045444943494F4E2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223232322C39393232372220546F703D2238312C35393036222057696474683D223130392C363036333722204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220446973706C6179466F726D61742E466F726D61745374723D2264642F6D6D2F797979792220446973706C6179466F726D61742E4B696E643D22666B4461746554696D6522204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B46454348415F45585045444943494F4E5F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D22466163747572617346454348415F56454E43494D49454E544F2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223537342C34383835362220546F703D2238312C35393036222057696474683D223130322C303437333122204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220446973706C6179466F726D61742E466F726D61745374723D2264642F6D6D2F797979792220446973706C6179466F726D61742E4B696E643D22666B4461746554696D6522204672616D652E5479703D22302220546578743D225B52656369626F732E262333343B46454348415F56454E43494D49454E544F5F52454349424F262333343B5D222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D2246616374757261734555524F535F52454349424F2220496E6465785461673D22312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223532312C35373531342220546F703D2233322C3435363731222057696474683D223137332C383538333822204865696768743D2231382C38393736352220446174615365743D22646D46616374757261732E667864735072696E744661632220446174615365744E616D653D2246616374757261732220446973706C6179466F726D61742E446563696D616C536570617261746F723D222C2220446973706C6179466F726D61742E466F726D61745374723D2225322E326D2220446973706C6179466F726D61742E4B696E643D22666B4E756D657269632220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D22302220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D2230222048416C69676E3D22686152696768742220506172656E74466F6E743D2246616C73652220546578743D225B52656369626F732E262333343B4555524F535F52454349424F262333343B5D222F3E0D0A2020202020203C546672784C696E6556696577204E616D653D224C696E65312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D22302220546F703D223333342C3831393131222057696474683D223735392C363835353322204865696768743D22302220436F6C6F723D223022204672616D652E5374796C653D2266734461736822204672616D652E5479703D2234222F3E0D0A2020202020203C546672784D656D6F56696577204E616D653D224D656D6F32312220416C6C6F77566563746F724578706F72743D225472756522204C6566743D223533322C39313337332220546F703D223239342C3830333334222057696474683D223135312C3138313222204865696768743D2233302C32333632342220466F6E742E436861727365743D22312220466F6E742E436F6C6F723D222D31363737373230382220466F6E742E4865696768743D222D31332220466F6E742E4E616D653D22417269616C2220466F6E742E5374796C653D223022204672616D652E5479703D22302220506172656E74466F6E743D2246616C73652220546578743D22636F6C612063616F222F3E0D0A202020203C2F546672784D6173746572446174613E0D0A20203C2F546672785265706F7274506167653E0D0A3C2F546672785265706F72743E0D0A, '2025-02-06 20:47:48', '2025-02-06 20:47:48', 'Administrador', 'Administrador');
INSERT INTO `fza_usuarios_perfiles` VALUES ('Todos', 'inLibtb', 'oSimbolosProhibidos', ',\"\'+-€%*', NULL, NULL, NULL, '2023-04-26 11:50:56', '2023-04-26 11:50:48', 'Administrador', 'Administrador');

-- ----------------------------
-- Table structure for fza_valores_defecto
-- ----------------------------
DROP TABLE IF EXISTS `fza_valores_defecto`;
CREATE TABLE `fza_valores_defecto`  (
  `TABLA_OBJETIVO_DEF` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Nombre de la tabla, ej: fza_articulos',
  `CAMPO_OBJETIVO_DEF` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL COMMENT 'Nombre del campo, ej: TIPOIVA_ARTICULO',
  `VALOR_DEFECTO_DEF` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'El valor fijo a insertar',
  `TIPO_DATO_DEF` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'STRING' COMMENT 'STRING, INTEGER, FLOAT, BOOLEAN, MACRO',
  `DESCRIPCION_DEF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Para que sepas qué es esto',
  `VALORES_POSIBLES_DEF` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL COMMENT 'Lista separada por comas (ej: S,N o 21,10,4)',
  PRIMARY KEY (`TABLA_OBJETIVO_DEF`, `CAMPO_OBJETIVO_DEF`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_valores_defecto
-- ----------------------------
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'ACTIVO_ARTICULO', 'S', 'STRING', 'Activo por defecto', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'CODIGO_ARTICULO', '0', 'STRING', 'Código Artículo', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'ESACTIVO_FIJO_ARTICULO', 'N', 'STRING', 'No es inmovilizado REAGP', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'ESTRAZABLE_ARTICULO', 'N', 'STRING', 'Tiene lote o caducidad', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'ESVARIACION_ARTICULO', 'N', 'STRING', 'Tiene Variaciones', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'ORDEN_ARTICULO', '0', 'INTEGER', 'Orden de aparición', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'TIPO_ARTICULO', 'ESTANDAR', 'STRING', 'Tipo de Artículo', 'ESTANDAR,SERVICIO,KIT');
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'TIPO_CANTIDAD_ARTICULO', 'Uds', 'STRING', 'Unidad de medida', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_articulos', 'TIPOIVA_ARTICULO', 'N', 'STRING', 'Tipo IVA', 'N,R,SR,E');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ACTIVO_CLIENTE', 'S', 'STRING', 'Cliente activo por defecto', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'CODIGO_CLIENTE', '0', 'STRING', 'Código Cliente', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ESINTRACOMUNITARIO_CLIENTE', 'N', 'STRING', 'Es intracomunitario', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ESIVA_EXENTO_CLIENTE', 'N', 'STRING', 'Está exento de IVA', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ESIVA_RECARGO_CLIENTE', 'N', 'STRING', 'Aplica recargo de equivalencia', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ESREGIMENESPECIALAGRICOLA_CLIENTE', 'N', 'STRING', 'Es régimen agrícola', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ESRETENCIONES_CLIENTE', 'N', 'STRING', 'Sin retenciones IRPF', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_clientes', 'ORDEN_CLIENTE', '0', 'INTEGER', 'Orden de aparición', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_empresas', 'ACTIVO_EMPRESA', 'S', 'STRING', 'Activo por defecto', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_empresas', 'CODIGO_EMPRESA', '0', 'STRING', 'Código Empresa', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_empresas', 'ESREGIMENESPECIALAGRICOLA_EMPRESA', 'N', 'STRING', 'Es REAGP', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_empresas', 'ESRETENCIONES_EMPRESA', 'N', 'STRING', 'Es AutoEmpresa (IRPF)', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_empresas', 'ORDEN_EMPRESA', '0', 'INTEGER', 'Orden de aparición', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'CODIGO_CLIENTE_FACTURA', '0', 'STRING', 'Código de Cliente', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'CODIGO_EMPRESA_FACTURA', '0', 'STRING', 'Código de Emisor', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'CONTADOR_LINEAS_FACTURA', '0', 'STRING', 'Contador de Lineas de Facturas', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESAPLICA_RE_ZONA_IVA_FACTURA', 'S', 'STRING', 'Zona de IVA Aplica RE', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESCONSOLIDADA_FACTURA', 'N', 'STRING', 'Consolidación de Factura', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESCREARARTICULOS_FACTURA', 'N', 'STRING', 'Factura crea/actualiza artículos', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESDESCRIPCIONES_AMP_FACTURA', 'N', 'STRING', 'Factura tiene descripciones ampliadas', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESFECHADEENTREGA_FACTURA', 'N', 'STRING', 'La factura tiene fecha de entrega', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESINTRACOMUNITARIO_CLIENTE_FACTURA', 'N', 'STRING', 'Cliente es intracomunitario', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESIVA_EXENTO_CLIENTE_FACTURA', 'N', 'STRING', 'Cliente Exento de IVA', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESIVA_RECARGO_CLIENTE_FACTURA', 'N', 'STRING', 'Cliente tiene Recargo de Equivalencia', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA', 'N', 'STRING', 'Cliente es REAGP', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA', 'N', 'STRING', 'Emisor es REAGP', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESRETENCIONES_CLIENTE_FACTURA', 'N', 'STRING', 'Cliente es profesional Retiene IRPF', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'ESVENTA_ACTIVO_FIJO_FACTURA', 'N', 'STRING', 'La factura es venta activo fijo REAGP', 'S,N');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'FASE_FACTURA', 'BORRADOR', 'STRING', 'Fase inicial de Factura', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'NRO_FACTURA', '0', 'STRING', 'Número de Factura', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'TIPO_FACTURA', 'NORMAL', 'STRING', 'Tipo de Factura nueva', 'NORMAL,SIMPLIFICADA');
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'TOTAL_BASES_FACTURA', '0', 'FLOAT', 'Bases inicial', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'TOTAL_IMPUESTOS_FACTURA', '0', 'FLOAT', 'Impùestos inicial', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas', 'TOTAL_LIQUIDO_FACTURA', '0', 'FLOAT', 'Total inicial', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas_lineas', 'CANTIDAD_FACTURA_LINEA', '1', 'FLOAT', 'Cantidad', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas_lineas', 'LINEA_FACTURA_LINEA', '0', 'STRING', 'Número de Linea', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas_lineas', 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA', 'Uds.', 'STRING', 'Unidad de medida', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas_lineas', 'TIPOIVA_ARTICULO_FACTURA_LINEA', 'N', 'STRING', 'Tipo IVA', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas_lineas', 'TOTAL_FACTURA_LINEA', '0', 'INTEGER', 'Total Linea Con IVA', NULL);
INSERT INTO `fza_valores_defecto` VALUES ('fza_facturas_lineas', 'TOTAL_FACTURASIVA_LINEA', '0', 'INTEGER', 'Total Linea Sin IVA', NULL);

-- ----------------------------
-- Table structure for fza_variaciones
-- ----------------------------
DROP TABLE IF EXISTS `fza_variaciones`;
CREATE TABLE `fza_variaciones`  (
  `CODIGO_VAR` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NOMBRE_VAR` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESACTIVO_VAR` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT 'S',
  `ORDEN_VAR` int(11) NULL DEFAULT NULL,
  `INSTANTEMODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTEALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIOALTA` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `USUARIOMODIF` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  PRIMARY KEY (`CODIGO_VAR`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_variaciones
-- ----------------------------
INSERT INTO `fza_variaciones` VALUES ('TC', 'TALLAS Y COLORES', 'S', 1, '2026-01-04 07:47:35', '2026-01-04 07:39:32', 'Administrador', 'Administrador');
INSERT INTO `fza_variaciones` VALUES ('TEMP', 'Temporadas y Colecciones', 'S', 2, '2026-01-06 12:28:59', '0000-00-00 00:00:00', 'Admin', 'Admin');

-- ----------------------------
-- Table structure for fza_variaciones_atributos
-- ----------------------------
DROP TABLE IF EXISTS `fza_variaciones_atributos`;
CREATE TABLE `fza_variaciones_atributos`  (
  `ID_VA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `ID_ATRIBUTO_VA` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `NOMBRE_VA` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ESDEFINITORIO` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `ORDEN_VA` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`ID_VA`, `ID_ATRIBUTO_VA`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_variaciones_atributos
-- ----------------------------
INSERT INTO `fza_variaciones_atributos` VALUES ('TC', 'CO', 'Color', 'S', 1);
INSERT INTO `fza_variaciones_atributos` VALUES ('TC', 'TAL', 'Talla', 'S', 2);
INSERT INTO `fza_variaciones_atributos` VALUES ('TEMP', 'TEMP', 'Temporada', 'N', 1);

-- ----------------------------
-- Table structure for fza_verifactu_eventos
-- ----------------------------
DROP TABLE IF EXISTS `fza_verifactu_eventos`;
CREATE TABLE `fza_verifactu_eventos`  (
  `ID_LOG` bigint(20) NOT NULL AUTO_INCREMENT,
  `TIMESTAMP_LOG` datetime(3) NOT NULL,
  `TIPO_EVENTO_LOG` tinyint(3) UNSIGNED NOT NULL,
  `USUARIO_LOG` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `VERSION_LOG` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `DESCRIPCION_LOG` text CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `DATOS_ADICIONALES_LOG` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL,
  `HASH_ANTERIOR_LOG` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `HASH_PROPIO_LOG` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `FIRMA_DIGITAL_LOG` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CREATED_AT_LOG` timestamp NULL DEFAULT current_timestamp(),
  `NRO_FACTURA_LOG` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SERIE_FACTURA_LOG` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`ID_LOG`) USING BTREE,
  INDEX `idx_timestamp`(`TIMESTAMP_LOG` ASC) USING BTREE,
  INDEX `idx_tipo_evento`(`TIPO_EVENTO_LOG` ASC) USING BTREE,
  INDEX `idx_usuario`(`USUARIO_LOG` ASC) USING BTREE,
  INDEX `idx_hash_propio`(`HASH_PROPIO_LOG` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2770 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_verifactu_eventos
-- ----------------------------

-- ----------------------------
-- Table structure for fza_winforms
-- ----------------------------
DROP TABLE IF EXISTS `fza_winforms`;
CREATE TABLE `fza_winforms`  (
  `CALL_WINF` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL,
  `CAPTION_WINF` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `MENUITEM_WINF` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `UNITF_WINF` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `SHORTCUT_WINF` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `DATAMODULE_WINF` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`CALL_WINF`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fza_winforms
-- ----------------------------
INSERT INTO `fza_winforms` VALUES ('Almacenes', 'Almacenes', 'mnuAlmacenes', 'inMtoAlmacenes.TfrmMtoAlmacenes', 'Ctrl+L', 'UniDataAlmacenes.TdmAlmacenes');
INSERT INTO `fza_winforms` VALUES ('Articulos', 'Artículos', 'mnuArticulos', 'inMtoArticulos.TfrmMtoArticulos', 'Ctrl+A', 'UniDataArticulos.TdmArticulos');
INSERT INTO `fza_winforms` VALUES ('Clientes', 'Clientes', 'mnuClientes', 'inMtoClientes.TfrmMtoClientes', 'Ctrl+K', 'UniDataClientes.TdmClientes');
INSERT INTO `fza_winforms` VALUES ('Contadores', 'Contadores', 'mnuContadores', 'inMtoContadores.TfrmMtoContadores', 'Ctrl+R', 'UniDataContadores.TdmContadores');
INSERT INTO `fza_winforms` VALUES ('Empresas', 'Empresas', 'mnuEmpresas', 'inMtoEmpresas.TfrmMtoEmpresas', 'Ctrl+E', 'UniDataEmpresas.TdmEmpresas');
INSERT INTO `fza_winforms` VALUES ('Facturas', 'Facturas', 'mnuFacturas', 'inMtoFacturas.TfrmMtoFacturas', 'Ctrl+F', 'UniDataFacturas.TdmFacturas');
INSERT INTO `fza_winforms` VALUES ('Familias', 'Familias', 'mnuFamilias', 'inMtoFamilias.TfrmMtoFamilias', 'Ctrl+N', 'UniDataFamilias.TdmFamilias');
INSERT INTO `fza_winforms` VALUES ('FormasdePago', 'Formas de Pago', 'mnuFormasdePago', 'inMtoFormasdePago.TfrmMtoFormasdePago', 'Ctrl+Q', 'UniDataFormasdePago.TdmFormasdePago');
INSERT INTO `fza_winforms` VALUES ('GeneradorProcesos', 'Generador de Procesos', 'mnuGeneradorProcesos', 'inMtoGeneradorProcesos.TfrmMtoGeneradorProcesos', 'Ctrl+G', 'UniDataGeneradorProcesos.TdmGeneradorProcesos');
INSERT INTO `fza_winforms` VALUES ('Grupos', 'Grupos de Usuarios', 'mnuGrupos', 'inMtoGrupos.TfrmMtoGrupos', 'Ctrl+J', 'UniDataGrupos.TdmGrupos');
INSERT INTO `fza_winforms` VALUES ('Ivas', 'Impuestos IVA', 'mnuIvas', 'inMtoIvas.TfrmMtoIvas', 'Ctrl+I', 'UniDataIvas.TdmIvas');
INSERT INTO `fza_winforms` VALUES ('IvasGrupos', 'Grupos de Impuestos IVA', 'mnuGruposdeIVA', 'inMtoIvasGrupos.TfrmMtoIvasGrupos', 'Ctrl+O', 'UniDataIvasGrupos.TdmIvasGrupos');
INSERT INTO `fza_winforms` VALUES ('MenuCaja', 'Menú de Caja', 'mnuMenuCaja', 'inMtoCajaMenu.TfrmMtoMenuCaja', 'F5', NULL);
INSERT INTO `fza_winforms` VALUES ('Paises', 'Países', 'mnuPaises', 'inMtoPaises.TfrmMtoPaises', 'Ctrl+L', 'UniDataPaises.TdmPaises');
INSERT INTO `fza_winforms` VALUES ('Proveedores', 'Proveedores', 'mnuProveedores', 'inMtoProveedores.TfrmMtoProveedores', 'Ctrl+P', 'UniDataProveedores.TdmProveedores');
INSERT INTO `fza_winforms` VALUES ('Tarifas', 'Tarifas', 'mnuTarifas', 'inMtoTarifas.TfrmMtoTarifas', 'Ctrl+T', 'UniDataTarifas.TdmTarifas');
INSERT INTO `fza_winforms` VALUES ('Usuarios', 'Usuarios', 'mnuUsuarios', 'inMtoUsuarios.TfrmMtoUsuarios', 'Ctrl+H', 'UniDataUsuarios.TdmUsuarios');
INSERT INTO `fza_winforms` VALUES ('UsuariosPerfiles', 'Perfiles de Usuarios', 'mnuPerfiles', 'inMtoUsuariosPerfiles.TfrmMtoUsuariosPerfiles', 'Ctrl+M', 'UniDataUsuariosPerfiles.TdmUsuariosPerfiles');

-- ----------------------------
-- View structure for vi_articulos
-- ----------------------------
DROP VIEW IF EXISTS `vi_articulos`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_articulos` AS SELECT
  `fza_articulos`.`CODIGO_ARTICULO` AS `CODIGO_ARTICULO`,
  `fza_articulos`.`ACTIVO_ARTICULO` AS `ACTIVO_ARTICULO`,
  `fza_articulos`.`ORDEN_ARTICULO` AS `ORDEN_ARTICULO`,
  `fza_articulos`.`DESCRIPCION_ARTICULO` AS `DESCRIPCION_ARTICULO`,
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` AS `CODIGO_FAMILIA_ARTICULO`,
  `fza_articulos_familias`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,
  `fza_articulos_familias`.`NOMBRE_FAMILIA` AS `NOMBRE_FAMILIA`,
  `fza_articulos`.`TIPOIVA_ARTICULO` AS `TIPOIVA_ARTICULO`,
  `fza_ivas_tipos`.`NOMBRE_TIPO_IVA` AS `NOMBRE_TIPO_IVA`,
  `fza_articulos`.`ESACTIVO_FIJO_ARTICULO` AS `ESACTIVO_FIJO_ARTICULO`,
  `fza_articulos`.`TIPO_CANTIDAD_ARTICULO` AS `TIPO_CANTIDAD_ARTICULO`,
  `fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZONSOCIAL_PROVEEDOR`,
  `fza_articulos`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
  `fza_articulos`.`INSTANTEALTA` AS `INSTANTEALTA`,
  `fza_articulos`.`USUARIOALTA` AS `USUARIOALTA`,
  `fza_articulos`.`USUARIOMODIF` AS `USUARIOMODIF`
FROM
  ((((
  `fza_articulos`
  LEFT JOIN `fza_articulos_familias` ON ((
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` = `fza_articulos_familias`.`CODIGO_FAMILIA`
  )))
  LEFT JOIN `fza_articulos_proveedores` ON (((
  `fza_articulos`.`CODIGO_ARTICULO` = `fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR`
  )
  AND (
  `fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` = 'S'
  ))))
  LEFT JOIN `fza_proveedores` ON ((
  `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` = `fza_proveedores`.`CODIGO_PROVEEDOR`
  )))
  LEFT JOIN `fza_ivas_tipos` ON ((
  `fza_articulos`.`TIPOIVA_ARTICULO` = `fza_ivas_tipos`.`CODIGO_ABREVIATURA_TIPO_IVA`
  )))
ORDER BY
  `fza_articulos`.`ORDEN_ARTICULO` ;

-- ----------------------------
-- View structure for vi_articulos_familias
-- ----------------------------
DROP VIEW IF EXISTS `vi_articulos_familias`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_articulos_familias` AS SELECT
  `fza_articulos_familias`.`CODIGO_FAMILIA` AS `CODIGO_FAMILIA`,
  `fza_articulos_familias`.`ACTIVO_FAMILIA` AS `ACTIVO_FAMILIA`,
  `fza_articulos_familias`.`ORDEN_FAMILIA` AS `ORDEN_FAMILIA`,
  `fza_articulos_familias`.`ESDEFAULT_FAMILIA` AS `ESDEFAULT_FAMILIA`,
  `fza_articulos_familias`.`CODIGO_SUBFAMILIA` AS `CODIGO_SUBFAMILIA`,
  `fza_articulos_familias2`.`NOMBRE_FAMILIA` AS `NOMBRE_SUBFAMILIA`,
  `fza_articulos_familias`.`NOMBRE_FAMILIA` AS `NOMBRE_FAMILIA`,
  `fza_articulos_familias`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,
  `fza_articulos_familias`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
  `fza_articulos_familias`.`INSTANTEALTA` AS `INSTANTEALTA`,
  `fza_articulos_familias`.`USUARIOALTA` AS `USUARIOALTA`,
  `fza_articulos_familias`.`USUARIOMODIF` AS `USUARIOMODIF`
FROM
  (
  `fza_articulos_familias`
  LEFT JOIN `fza_articulos_familias` `fza_articulos_familias2` ON ((
  `fza_articulos_familias`.`CODIGO_SUBFAMILIA` = `fza_articulos_familias2`.`CODIGO_FAMILIA`
  ))) ;

-- ----------------------------
-- View structure for vi_articulos_familias_list
-- ----------------------------
DROP VIEW IF EXISTS `vi_articulos_familias_list`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_articulos_familias_list` AS select `fza_articulos_familias`.`CODIGO_FAMILIA` AS `CODIGO_FAMILIA`,`fza_articulos_familias`.`ACTIVO_FAMILIA` AS `ACTIVO_FAMILIA`,`fza_articulos_familias`.`ORDEN_FAMILIA` AS `ORDEN_FAMILIA`,`fza_articulos_familias`.`ESDEFAULT_FAMILIA` AS `ESDEFAULT_FAMILIA`,`fza_articulos_familias`.`CODIGO_SUBFAMILIA` AS `CODIGO_SUBFAMILIA`,`fza_articulos_familias`.`NOMBRE_FAMILIA` AS `NOMBRE_FAMILIA`,`fza_articulos_familias`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,`fza_articulos_familias`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_articulos_familias`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_articulos_familias`.`USUARIOALTA` AS `USUARIOALTA`,`fza_articulos_familias`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_articulos_familias` where (`fza_articulos_familias`.`ACTIVO_FAMILIA` = 'S') order by `fza_articulos_familias`.`ORDEN_FAMILIA` ;

-- ----------------------------
-- View structure for vi_articulos_list
-- ----------------------------
DROP VIEW IF EXISTS `vi_articulos_list`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_articulos_list` AS SELECT
  `fza_articulos`.`CODIGO_ARTICULO` AS `CODIGO_ARTICULO`,
  `fza_articulos`.`ACTIVO_ARTICULO` AS `ACTIVO_ARTICULO`,
  `fza_articulos`.`ORDEN_ARTICULO` AS `ORDEN_ARTICULO`,
  `fza_articulos`.`DESCRIPCION_ARTICULO` AS `DESCRIPCION_ARTICULO`,
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` AS `CODIGO_FAMILIA_ARTICULO`,
  `fza_articulos_familias`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,
  `fza_articulos`.`TIPOIVA_ARTICULO` AS `TIPOIVA_ARTICULO`,
  `fza_articulos`.`ESACTIVO_FIJO_ARTICULO` AS `ESACTIVO_FIJO_ARTICULO`,
  `fza_articulos`.`TIPO_CANTIDAD_ARTICULO` AS `TIPO_CANTIDAD_ARTICULO`,
  `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,
  `fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZONSOCIAL_PROVEEDOR`,
  `fza_articulos`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
  `fza_articulos`.`INSTANTEALTA` AS `INSTANTEALTA`,
  `fza_articulos`.`USUARIOALTA` AS `USUARIOALTA`,
  `fza_articulos`.`USUARIOMODIF` AS `USUARIOMODIF`
FROM
  (((
  `fza_articulos`
  LEFT JOIN `fza_articulos_familias` ON ((
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` = `fza_articulos_familias`.`CODIGO_FAMILIA`
  )))
  LEFT JOIN `fza_articulos_proveedores` ON (((
  `fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR` = `fza_articulos`.`CODIGO_ARTICULO`
  )
  AND (
  `fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` = 'S'
  ))))
  LEFT JOIN `fza_proveedores` ON ((
  `fza_proveedores`.`CODIGO_PROVEEDOR` = `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`
  )))
WHERE
  (`fza_articulos`.`ACTIVO_ARTICULO` = 'S')
ORDER BY
  `fza_articulos`.`ORDEN_ARTICULO` ;

-- ----------------------------
-- View structure for vi_articulos_proveedores
-- ----------------------------
DROP VIEW IF EXISTS `vi_articulos_proveedores`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_articulos_proveedores` AS select `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,`fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZONSOCIAL_PROVEEDOR`,`fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR` AS `CODIGO_ARTICULO`,`fza_articulos_proveedores`.`PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR` AS `PRECIO_ULT_COMPRA`,`fza_articulos_proveedores`.`FECHA_VALIDEZ_ARTICULO_PROVEEDOR` AS `FECHA_VALIDEZ`,`fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` AS `ESPROVEEDORPRINCIPAL`,`fza_articulos_proveedores`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_articulos_proveedores`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_articulos_proveedores`.`USUARIOALTA` AS `USUARIOALTA`,`fza_articulos_proveedores`.`USUARIOMODIF` AS `USUARIOMODIF` from (`fza_articulos_proveedores` left join `fza_proveedores` on((`fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` = `fza_proveedores`.`CODIGO_PROVEEDOR`))) ;

-- ----------------------------
-- View structure for vi_articulos_tarifas
-- ----------------------------
DROP VIEW IF EXISTS `vi_articulos_tarifas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_articulos_tarifas` AS SELECT
  `fza_articulos_tarifas`.`CODIGO_UNICO_TARIFA` AS `CODIGO_UNICO_TARIFA`,
  `fza_articulos_tarifas`.`CODIGO_ARTICULO_TARIFA` AS `CODIGO_ARTICULO_TARIFA`,
  `fza_tarifas`.`ESIMP_INCL_TARIFA` AS `ESIMP_INCL_TARIFA`,
  `fza_tarifas`.`ESDEFAULT_TARIFA` AS `ESDEFAULT_TARIFA`,
  `fza_articulos`.`DESCRIPCION_ARTICULO` AS `DESCRIPCION_ARTICULO`,
  `fza_articulos`.`TIPO_CANTIDAD_ARTICULO` AS `TIPO_CANTIDAD_ARTICULO`,
  `fza_articulos`.ESVARIACION_ARTICULO` AS ESVARIACION_ARTICULO`,
  `fza_ivas_tipos`.`CODIGO_ABREVIATURA_TIPO_IVA` AS `TIPO_IVA_ARTICULO`,
  `fza_articulos_tarifas`.`ACTIVO_TARIFA` AS `ACTIVO_TARIFA`,
  `fza_articulos_tarifas`.`CODIGO_TARIFA` AS `CODIGO_TARIFA`,
  `fza_tarifas`.`NOMBRE_TARIFA` AS `NOMBRE_TARIFA`,
  `fza_articulos_tarifas`.`FECHA_DESDE_TARIFA` AS `FECHA_DESDE_TARIFA`,
  `fza_articulos_tarifas`.`FECHA_HASTA_TARIFA` AS `FECHA_HASTA_TARIFA`,
  `fza_articulos_tarifas`.`PRECIOFINAL_TARIFA` AS `PRECIOFINAL_TARIFA`,
  `fza_articulos_tarifas`.`PRECIOSALIDA_TARIFA` AS `PRECIOSALIDA_TARIFA`,
  `fza_articulos_tarifas`.`PORCEN_DTO_TARIFA` AS `PORCEN_DTO_TARIFA`,
  `fza_articulos_tarifas`.`PRECIO_DTO_TARIFA` AS `PRECIO_DTO_TARIFA`,
  `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,
  `fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZONSOCIAL_PROVEEDOR`,
  `fza_articulos_proveedores`.`PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR` AS `PRECIO_ULT_COMPRA`,
  `fza_articulos_proveedores`.`FECHA_VALIDEZ_ARTICULO_PROVEEDOR` AS `FECHA_VALIDEZ`,
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` AS `CODIGO_FAMILIA_ARTICULO`,
  `fza_articulos_familias`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,
  (SELECT COUNT(DISTINCT VA.ID_ATRIBUTO_VA) 
   FROM `fza_articulos_skus` SK 
   JOIN `fza_variaciones_atributos` VA ON SK.CODIGO_VAR_SKU = VA.ID_VA 
   WHERE SK.CODIGO_ARTICULO_SKU = `fza_articulos`.`CODIGO_ARTICULO` 
     AND VA.ESDEFINITORIO = 'S') AS `NUM_ATRIBUTOS_REQ`,
  `fza_articulos_tarifas`.`INSTANTEALTA` AS `INSTANTEALTA`,
  `fza_articulos_tarifas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
  `fza_articulos_tarifas`.`USUARIOALTA` AS `USUARIOALTA`,
  `fza_articulos_tarifas`.`USUARIOMODIF` AS `USUARIOMODIF`
FROM
  ((((((
  `fza_articulos_tarifas`
  LEFT JOIN `fza_articulos_proveedores` ON (((
  `fza_articulos_tarifas`.`CODIGO_ARTICULO_TARIFA` = `fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR`
  )
  AND (
  `fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` = 'S'
  ))))
  LEFT JOIN `fza_tarifas` ON ((
  `fza_articulos_tarifas`.`CODIGO_TARIFA` = `fza_tarifas`.`CODIGO_TARIFA`
  )))
  LEFT JOIN `fza_articulos` ON ((
  `fza_articulos_tarifas`.`CODIGO_ARTICULO_TARIFA` = `fza_articulos`.`CODIGO_ARTICULO`
  )))
  LEFT JOIN `fza_articulos_familias` ON ((
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` = `fza_articulos_familias`.`CODIGO_FAMILIA`
  )))
  LEFT JOIN `fza_proveedores` ON ((
  `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` = `fza_proveedores`.`CODIGO_PROVEEDOR`
  )))
  LEFT JOIN `fza_ivas_tipos` ON ((
  `fza_articulos`.`TIPOIVA_ARTICULO` = `fza_ivas_tipos`.`CODIGO_ABREVIATURA_TIPO_IVA`
  )))
ORDER BY
  `fza_tarifas`.`ORDEN_TARIFA`,
  `fza_articulos`.`ORDEN_ARTICULO` ;

-- ----------------------------
-- View structure for vi_art_busquedas
-- ----------------------------
DROP VIEW IF EXISTS `vi_art_busquedas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_art_busquedas` AS SELECT
  `fza_articulos`.`CODIGO_ARTICULO` AS `CODIGO_ARTICULO`,
  `fza_articulos`.`ACTIVO_ARTICULO` AS `ACTIVO_ARTICULO`,
  `fza_articulos`.`DESCRIPCION_ARTICULO` AS `DESCRIPCION_ARTICULO`,
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` AS `CODIGO_FAMILIA_ARTICULO`,
  `fza_articulos_familias`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,
  `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,
  `fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZON_SOCIAL_PROVEEDOR`,
  `fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` AS `ESPROVEEDORPRINCIPAL`,
  `fza_articulos_proveedores`.`PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR` AS `PRECIO_ULT_COMPRA`,
  `fza_articulos_tarifas`.`CODIGO_TARIFA` AS `CODIGO_TARIFA`,
  `fza_tarifas`.`NOMBRE_TARIFA` AS `NOMBRE_TARIFA`,
  `fza_articulos_tarifas`.`PRECIOSALIDA_TARIFA` AS `PRECIOSALIDA_TARIFA`,
  `fza_articulos_tarifas`.`PRECIO_DTO_TARIFA` AS `PRECIO_DTO_TARIFA`,
  `fza_articulos_tarifas`.`PORCEN_DTO_TARIFA` AS `PORCEN_DTO_TARIFA`,
  `fza_articulos_tarifas`.`PRECIOFINAL_TARIFA` AS `PRECIOFINAL_TARIFA`,
  `fza_articulos_tarifas`.`FECHA_DESDE_TARIFA` AS `FECHA_DESDE_TARIFA`,
  `fza_articulos_tarifas`.`FECHA_HASTA_TARIFA` AS `FECHA_HASTA_TARIFA`,
  `fza_tarifas`.`ESIMP_INCL_TARIFA` AS `ESIMP_INCL_TARIFA`,
  `fza_ivas_tipos`.`NOMBRE_TIPO_IVA` AS `NOMBRE_TIPO_IVA`,
  `fza_articulos`.`TIPOIVA_ARTICULO` AS `TIPOIVA_ARTICULO`,
  `fza_articulos`.`TIPO_CANTIDAD_ARTICULO` AS `TIPO_CANTIDAD_ARTICULO`,
  `fza_articulos`.`USUARIOMODIF` AS `USUARIOMODIF`,
  `fza_articulos`.`INSTANTEALTA` AS `INSTANTEALTA`,
  `fza_articulos`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
  `fza_articulos`.`USUARIOALTA` AS `USUARIOALTA`,
  `fza_articulos`.`ESACTIVO_FIJO_ARTICULO` AS `ESACTIVO_FIJO_ARTICULO`
FROM
  ((((((
  `fza_articulos`
  LEFT JOIN `fza_articulos_familias` ON ((
  `fza_articulos`.`CODIGO_FAMILIA_ARTICULO` = `fza_articulos_familias`.`CODIGO_FAMILIA`
  )))
  LEFT JOIN `fza_articulos_tarifas` ON ((
  `fza_articulos`.`CODIGO_ARTICULO` = `fza_articulos_tarifas`.`CODIGO_ARTICULO_TARIFA`
  )))
  LEFT JOIN `fza_tarifas` ON (((
  `fza_articulos_tarifas`.`CODIGO_TARIFA` = `fza_tarifas`.`CODIGO_TARIFA`
  )
  AND (
  `fza_tarifas`.`ESDEFAULT_TARIFA` = 'S'
  ))))
  LEFT JOIN `fza_ivas_tipos` ON ((
  `fza_articulos`.`TIPOIVA_ARTICULO` = `fza_ivas_tipos`.`CODIGO_ABREVIATURA_TIPO_IVA`
  )))
  LEFT JOIN `fza_articulos_proveedores` ON (((
  `fza_articulos`.`CODIGO_ARTICULO` = `fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR`
  )
  AND (
  `fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` = 'S'
  ))))
  LEFT JOIN `fza_proveedores` ON ((
  `fza_proveedores`.`CODIGO_PROVEEDOR` = `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`
  )))
WHERE
  (`fza_articulos`.`ACTIVO_ARTICULO` = 'S')
ORDER BY
  `fza_articulos`.`ORDEN_ARTICULO` ;

-- ----------------------------
-- View structure for vi_atributos_nombres
-- ----------------------------
DROP VIEW IF EXISTS `vi_atributos_nombres`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_atributos_nombres` AS SELECT DISTINCT ASK.CODIGO_ARTICULO_SKU as CODIGO_ARTICULO_PADRE, 
       VAT.ID_ATRIBUTO_VA AS ID_ATRIBUTO,
       VAT.NOMBRE_VA as NOMBRE_ATRIBUTO, 
       VAT.ORDEN_VA as ORDEN_VISUAL_ATRIBUTO 

FROM fza_articulos_skus ASK
JOIN fza_variaciones_atributos VAT ON VAT.ID_VA = ASK.CODIGO_VAR_SKU 
WHERE VAT.ESDEFINITORIO = 'S' 
ORDER BY ASK.CODIGO_ARTICULO_SKU, VAT.ORDEN_VA ;

-- ----------------------------
-- View structure for vi_cajasdef
-- ----------------------------
DROP VIEW IF EXISTS `vi_cajasdef`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_cajasdef` AS SELECT 
    e.CODIGO_EMPRESA AS Empresa, 
    e.RAZONSOCIAL_EMPRESA AS NombreEmpresa, 
    a.CODIGO_ALMACEN_ALM AS Almacen, 
    a.NOMBRE_ALMACEN_ALM AS NombreAlmacén, 
    c.CODIGO_CAJA_ALMCAJ AS Caja, 
    c.DESCRIPCION_ALMCAJ AS NombreCaja
FROM fza_empresas e
INNER JOIN fza_almacenes a 
    ON e.CODIGO_EMPRESA = a.CODIGO_EMPRESA_ALM
INNER JOIN fza_almacenes_cajas c 
    ON a.CODIGO_ALMACEN_ALM = c.CODIGO_ALMACEN_ALMCAJ
WHERE e.ACTIVO_EMPRESA = 'S' 
  AND a.ESACTIVO_ALM = 'S' ;

-- ----------------------------
-- View structure for vi_caja_busqueda_unificada
-- ----------------------------
DROP VIEW IF EXISTS `vi_caja_busqueda_unificada`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_caja_busqueda_unificada` AS -- 2. BÚSQUEDA POR CÓDIGO DE ARTÍCULO PADRE (Manual)
SELECT 
    A.CODIGO_ARTICULO   AS INPUT_BUSQUEDA,
    'CODIGO'            AS TIPO_COINCIDENCIA,
    A.CODIGO_ARTICULO   AS CODIGO_PADRE,
    NULL                AS CODIGO_SKU,     -- No sabemos talla aún, habrá que pedirla
    A.DESCRIPCION_ARTICULO,
    A.TIPO_ARTICULO
FROM fza_articulos A
WHERE A.ACTIVO_ARTICULO = 'S'
UNION ALL
-- 3. BÚSQUEDA POR SKU EXACTO (Para expertos que saben el código interno)
SELECT 
    SKU.CODIGO_UNIDAD_SKU AS INPUT_BUSQUEDA, -- Ej: 'MOCASIN-42-NEGRO'
    'SKU'                 AS TIPO_COINCIDENCIA,
    A.CODIGO_ARTICULO     AS CODIGO_PADRE,
    SKU.CODIGO_UNIDAD_SKU AS CODIGO_SKU,
    A.DESCRIPCION_ARTICULO,
    A.TIPO_ARTICULO
FROM fza_articulos_skus SKU
JOIN fza_articulos A ON SKU.CODIGO_ARTICULO_SKU = A.CODIGO_ARTICULO
WHERE SKU.ESACTIVO_SKU = 'S' 
UNION ALL
-- 1. BÚSQUEDA POR CÓDIGO DE BARRAS (Prioritaria)
SELECT 
    CB.CODIGO_BARRAS_CB AS INPUT_BUSQUEDA, -- Lo que el usuario escribe/escanea
    'EAN'               AS TIPO_COINCIDENCIA,
    A.CODIGO_ARTICULO   AS CODIGO_PADRE,   -- El artículo genérico para sacar precios
    SKU.CODIGO_UNIDAD_SKU AS CODIGO_SKU,   -- La variante exacta (para saber talla)
    A.DESCRIPCION_ARTICULO,
    A.TIPO_ARTICULO
FROM fza_codigos_barras CB
JOIN fza_articulos_skus SKU ON CB.CODIGO_UNIDAD_CB = SKU.CODIGO_UNIDAD_SKU
JOIN fza_articulos A ON SKU.CODIGO_ARTICULO_SKU = A.CODIGO_ARTICULO ;

-- ----------------------------
-- View structure for vi_caja_tarifa_sku_articulos
-- ----------------------------
DROP VIEW IF EXISTS `vi_caja_tarifa_sku_articulos`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_caja_tarifa_sku_articulos` AS SELECT
  -- Identificación del SKU y Tarifa
  skus.CODIGO_UNIDAD_SKU AS CODIGO_UNIDAD_TARIFA,
  skus.CODIGO_ARTICULO_SKU AS CODIGO_ARTICULO,
  tarifas.CODIGO_TARIFA AS CODIGO_TARIFA,
  tarifas.NOMBRE_TARIFA AS NOMBRE_TARIFA,

  -- LÓGICA DE PRECIOS (La clave de tu pregunta):
  -- Si existe precio específico (tarifa_sku), úsalo. Si no, usa el del padre (tarifa_padre).
  COALESCE(tarifa_sku.PRECIOFINAL_TARIFA, tarifa_padre.PRECIOFINAL_TARIFA) AS PRECIOFINAL_TARIFA,
  COALESCE(tarifa_sku.PRECIOSALIDA_TARIFA, tarifa_padre.PRECIOSALIDA_TARIFA) AS PRECIOSALIDA_TARIFA,
  
  -- Información extra para saber de dónde viene el precio
  CASE 
    WHEN tarifa_sku.PRECIOFINAL_TARIFA IS NOT NULL THEN 'ESPECIFICO_SKU'
    WHEN tarifa_padre.PRECIOFINAL_TARIFA IS NOT NULL THEN 'HEREDADO_PADRE'
    ELSE 'SIN_PRECIO'
  END AS ORIGEN_PRECIO,

  -- Descripción concatenada (como vimos antes)
  CONCAT(articulos.DESCRIPCION_ARTICULO, ' (', skus.CODIGO_UNIDAD_SKU, ')') AS DESCRIPCION_COMPLETA,

  -- Resto de columnas útiles
  tarifas.ESIMP_INCL_TARIFA,
  articulos.TIPO_CANTIDAD_ARTICULO,
  articulos.CODIGO_FAMILIA_ARTICULO
  
FROM
  fza_articulos_skus AS skus
  -- Unimos con el artículo padre para sacar datos generales
  INNER JOIN fza_articulos AS articulos 
    ON skus.CODIGO_ARTICULO_SKU = articulos.CODIGO_ARTICULO
  
  -- CROSS JOIN con Tarifas: Esto genera una fila para cada SKU y cada Tarifa existente
  -- (Si tienes muchas tarifas y solo quieres ver la PVP, podrías filtrar aquí)
  CROSS JOIN fza_tarifas AS tarifas

  -- Buscamos si existe tarifa específica para el SKU
  LEFT JOIN fza_articulos_tarifas AS tarifa_sku 
    ON skus.CODIGO_UNIDAD_SKU = tarifa_sku.CODIGO_UNIDAD_TARIFA 
    AND tarifas.CODIGO_TARIFA = tarifa_sku.CODIGO_TARIFA

  -- Buscamos la tarifa del padre (para usarla si falla la del SKU)
  LEFT JOIN fza_articulos_tarifas AS tarifa_padre 
    ON articulos.CODIGO_ARTICULO = tarifa_padre.CODIGO_ARTICULO_TARIFA 
    AND tarifas.CODIGO_TARIFA = tarifa_padre.CODIGO_TARIFA
    AND (tarifa_padre.CODIGO_UNIDAD_TARIFA IS NULL OR tarifa_padre.CODIGO_UNIDAD_TARIFA = '')

-- Opcional: Mostrar solo activos
WHERE skus.ESACTIVO_SKU = 'S'
ORDER BY skus.CODIGO_ARTICULO_SKU, skus.CODIGO_UNIDAD_SKU, tarifas.ORDEN_TARIFA ;

-- ----------------------------
-- View structure for vi_caja_totalventas
-- ----------------------------
DROP VIEW IF EXISTS `vi_caja_totalventas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_caja_totalventas` AS select `fza_facturas`.`FECHA_FACTURA` AS `FECHA`,count(0) AS `TOTAL_VENTAS`,sum(`fza_facturas`.`TOTAL_LIQUIDO_FACTURA`) AS `TOTAL_COBRADO` from `fza_facturas` group by `fza_facturas`.`FECHA_FACTURA` order by `fza_facturas`.`FECHA_FACTURA` ;

-- ----------------------------
-- View structure for vi_caja_vales_ptes
-- ----------------------------
DROP VIEW IF EXISTS `vi_caja_vales_ptes`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_caja_vales_ptes` AS SELECT 
    CODIGO_VL AS codigo_vale,
    PIN_SEGURIDAD_VL AS pin,
    IMPORTE_NOMINAL_VL AS importe,
    FECHA_EMISION_VL AS fecha_emision,
    FECHA_CADUCIDAD_VL AS fecha_caducidad,
    CODIGO_CAJA_EMI_VL AS caja,
    CODIGO_ALMACEN_EMI_VL AS almacen,
    NUMERO_OPERACION_EMI_VL AS num_operacion,
    SERIE_FACTURA_EMI_VL AS serie_factura,
    NRO_FACTURA_EMI_VL AS num_factura,
    CODIGO_CLIENTE_VL AS cliente,
    OBSERVACIONES_VL AS observaciones,
    DATEDIFF(FECHA_CADUCIDAD_VL, CURDATE()) AS dias_hasta_caducidad
FROM 
    fza_caja_vales
WHERE 
    ESTADO_VL = 'PENDIENTE'
    AND (FECHA_CADUCIDAD_VL IS NULL OR FECHA_CADUCIDAD_VL >= CURDATE())
ORDER BY 
    FECHA_EMISION_VL DESC ;

-- ----------------------------
-- View structure for vi_clientes
-- ----------------------------
DROP VIEW IF EXISTS `vi_clientes`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_clientes` AS select * from fza_clientes order by orden_cliente ;

-- ----------------------------
-- View structure for vi_cli_busquedas
-- ----------------------------
DROP VIEW IF EXISTS `vi_cli_busquedas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_cli_busquedas` AS select `fza_clientes`.`CODIGO_CLIENTE` AS `CODIGO_CLIENTE`,`fza_clientes`.`ACTIVO_CLIENTE` AS `ACTIVO_CLIENTE`,`fza_clientes`.`RAZONSOCIAL_CLIENTE` AS `RAZONSOCIAL_CLIENTE`,`fza_clientes`.`NIF_CLIENTE` AS `NIF_CLIENTE`,`fza_clientes`.`MOVIL_CLIENTE` AS `MOVIL_CLIENTE`,`fza_clientes`.`EMAIL_CLIENTE` AS `EMAIL_CLIENTE`,`fza_clientes`.`DIRECCION1_CLIENTE` AS `DIRECCION1_CLIENTE`,`fza_clientes`.`DIRECCION2_CLIENTE` AS `DIRECCION2_CLIENTE`,`fza_clientes`.`POBLACION_CLIENTE` AS `POBLACION_CLIENTE`,`fza_clientes`.`PROVINCIA_CLIENTE` AS `PROVINCIA_CLIENTE`,`fza_clientes`.`CPOSTAL_CLIENTE` AS `CPOSTAL_CLIENTE`,`fza_clientes`.`CODIGO_PAIS_CLIENTE` AS `CODIGO_PAIS_CLIENTE`,`fza_clientes`.`NOMBRE_PAIS_CLIENTE` AS `NOMBRE_PAIS_CLIENTE`,`fza_clientes`.`OBSERVACIONES_CLIENTE` AS `OBSERVACIONES_CLIENTE`,`fza_clientes`.`REFERENCIA_CLIENTE` AS `REFERENCIA_CLIENTE`,`fza_clientes`.`CONTACTO_CLIENTE` AS `CONTACTO_CLIENTE`,`fza_clientes`.`TELEFONO_CONTACTO_CLIENTE` AS `TELEFONO_CONTACTO_CLIENTE`,`fza_clientes`.`TELEFONO_CLIENTE` AS `TELEFONO_CLIENTE`,`fza_clientes`.`IBAN_CLIENTE` AS `IBAN_CLIENTE`,`fza_clientes`.`ESIVA_RECARGO_CLIENTE` AS `ESIVA_RECARGO_CLIENTE`,`fza_clientes`.`ESRETENCIONES_CLIENTE` AS `ESRETENCIONES_CLIENTE`,`fza_clientes`.`ESIVA_EXENTO_CLIENTE` AS `ESIVA_EXENTO_CLIENTE`,`fza_clientes`.`ESREGIMENESPECIALAGRICOLA_CLIENTE` AS `ESREGIMENESPECIALAGRICOLA_CLIENTE`,`fza_clientes`.`ESINTRACOMUNITARIO_CLIENTE` AS `ESINTRACOMUNITARIO_CLIENTE`,`fza_clientes`.`CODIGO_FORMA_PAGO_CLIENTE` AS `CODIGO_FORMA_PAGO_CLIENTE`,`fza_clientes`.`SERIE_CONTADOR_CLIENTE` AS `SERIE_CONTADOR_CLIENTE`,`fza_clientes`.`TARIFA_ARTICULO_CLIENTE` AS `TARIFA_ARTICULO_CLIENTE`,`fza_clientes`.`TEXTO_LEGAL_FACTURA_CLIENTE` AS `TEXTO_LEGAL_FACTURA_CLIENTE`,`fza_clientes`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_clientes`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_clientes`.`USUARIOALTA` AS `USUARIOALTA`,`fza_clientes`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_clientes` where (`fza_clientes`.`ACTIVO_CLIENTE` = 'S') order by `fza_clientes`.`CODIGO_CLIENTE` desc ;

-- ----------------------------
-- View structure for vi_contadores
-- ----------------------------
DROP VIEW IF EXISTS `vi_contadores`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_contadores` AS SELECT
    `fza_contadores`.`TIPODOC_CONTADOR` AS `TIPODOC_CONTADOR`,
    `fza_contadores`.`SERIE_CONTADOR` AS `SERIE_CONTADOR`,
    `fza_contadores`.`CONTADOR_CONTADOR` AS `CONTADOR_CONTADOR`,
    `fza_contadores`.`EMPRESA_CONTADOR` AS `EMPRESA_CONTADOR`,
    `fza_tipos_documentos`.`DESCRIPCION_TIPODOCUMENTO` AS `DESCRIPCION_TIPODOCUMENTO`,
    `fza_tipos_documentos`.`TABLAORIGEN_TIPODOCUMENTO` AS `TABLAORIGEN_TIPODOCUMENTO`,
    `fza_contadores`.`DEFAULT_CONTADOR` AS `DEFAULT_CONTADOR`,
    `fza_contadores`.`NUMDIGIT_CONTADOR` AS `NUMDIGIT_CONTADOR`,
    `fza_contadores`.`ACTIVO_CONTADOR` AS `ACTIVO_CONTADOR`,
    `fza_contadores`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
    `fza_contadores`.`INSTANTEALTA` AS `INSTANTEALTA`,
    `fza_contadores`.`USUARIOALTA` AS `USUARIOALTA`,
    `fza_contadores`.`USUARIOMODIF` AS `USUARIOMODIF`
  FROM
    (
    `fza_contadores`
    LEFT JOIN `fza_tipos_documentos` ON (
    `fza_contadores`.`TIPODOC_CONTADOR` = `fza_tipos_documentos`.`CODIGO_TIPODOCUMENTO`
    )) ;

-- ----------------------------
-- View structure for vi_empresas
-- ----------------------------
DROP VIEW IF EXISTS `vi_empresas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_empresas` AS select `fza_empresas`.`CODIGO_EMPRESA` AS `CODIGO_EMPRESA`,`fza_empresas`.`ORDEN_EMPRESA` AS `ORDEN_EMPRESA`,`fza_empresas`.`ACTIVO_EMPRESA` AS `ACTIVO_EMPRESA`,`fza_empresas`.`RAZONSOCIAL_EMPRESA` AS `RAZONSOCIAL_EMPRESA`,`fza_empresas`.`NIF_EMPRESA` AS `NIF_EMPRESA`,`fza_empresas`.`MOVIL_EMPRESA` AS `MOVIL_EMPRESA`,`fza_empresas`.`EMAIL_EMPRESA` AS `EMAIL_EMPRESA`,`fza_empresas`.`DIRECCION1_EMPRESA` AS `DIRECCION1_EMPRESA`,`fza_empresas`.`DIRECCION2_EMPRESA` AS `DIRECCION2_EMPRESA`,`fza_empresas`.`CPOSTAL_EMPRESA` AS `CPOSTAL_EMPRESA`,`fza_empresas`.`POBLACION_EMPRESA` AS `POBLACION_EMPRESA`,`fza_empresas`.`PROVINCIA_EMPRESA` AS `PROVINCIA_EMPRESA`,`fza_empresas`.`NOMBRE_PAIS_EMPRESA` AS `NOMBRE_PAIS_EMPRESA`,`fza_empresas`.`CODIGO_PAIS_EMPRESA` AS `CODIGO_PAIS_EMPRESA`,`fza_empresas`.`IBAN_EMPRESA` AS `IBAN_EMPRESA`,`fza_empresas`.`GRUPO_ZONA_IVA_EMPRESA` AS `GRUPO_ZONA_IVA_EMPRESA`,`fza_ivas_grupos`.`DESCRIPCION_ZONA_IVA` AS `DESCRIPCION_ZONA_IVA`,`fza_empresas`.`ESRETENCIONES_EMPRESA` AS `ESRETENCIONES_EMPRESA`,`fza_empresas`.`ESREGIMENESPECIALAGRICOLA_EMPRESA` AS `ESREGIMENESPECIALAGRICOLA_EMPRESA`,`fza_empresas`.`TEXTO_LEGAL_FACTURA_EMPRESA` AS `TEXTO_LEGAL_FACTURA_EMPRESA`,`fza_empresas`.`CODIGO_CERTIFICADO_EMPRESA` AS `CODIGO_CERTIFICADO_EMPRESA`,`fza_empresas`.`TITULAR_CERTIFICADO_EMPRESA` AS `TITULAR_CERTIFICADO_EMPRESA`,`fza_empresas`.`TIPO_CERTIFICADO_EMPRESA` AS `TIPO_CERTIFICADO_EMPRESA`,`fza_empresas`.`FECHA_DESDE_CERTIFICADO_EMPRESA` AS `FECHA_DESDE_CERTIFICADO_EMPRESA`,`fza_empresas`.`FECHA_HASTA_CERTIFICADO_EMPRESA` AS `FECHA_HASTA_CERTIFICADO_EMPRESA`,`fza_empresas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_empresas`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_empresas`.`USUARIOALTA` AS `USUARIOALTA`,`fza_empresas`.`USUARIOMODIF` AS `USUARIOMODIF` from (`fza_empresas` left join `fza_ivas_grupos` on((`fza_empresas`.`GRUPO_ZONA_IVA_EMPRESA` = `fza_ivas_grupos`.`GRUPO_ZONA_IVA`))) ;

-- ----------------------------
-- View structure for vi_empresas_retenciones
-- ----------------------------
DROP VIEW IF EXISTS `vi_empresas_retenciones`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_empresas_retenciones` AS select `fza_empresas_retenciones`.`CODIGO_RETENCION` AS `CODIGO_RETENCION`,`fza_empresas_retenciones`.`CODIGO_EMPRESA_RETENCION` AS `CODIGO_EMPRESA_RETENCION`,`fza_empresas_retenciones`.`PORCENRETENCION_RETENCION` AS `PORCENRETENCION_RETENCION`,`fza_empresas_retenciones`.`FECHA_DESDE_RETENCION` AS `FECHA_DESDE_RETENCION`,`fza_empresas_retenciones`.`FECHA_HASTA_RETENCION` AS `FECHA_HASTA_RETENCION`,`fza_empresas_retenciones`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_empresas_retenciones`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_empresas_retenciones`.`USUARIOALTA` AS `USUARIOALTA`,`fza_empresas_retenciones`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_empresas_retenciones` ;

-- ----------------------------
-- View structure for vi_empresas_series
-- ----------------------------
DROP VIEW IF EXISTS `vi_empresas_series`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_empresas_series` AS select * from fza_empresas_series ;

-- ----------------------------
-- View structure for vi_emp_busquedas
-- ----------------------------
DROP VIEW IF EXISTS `vi_emp_busquedas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_emp_busquedas` AS select `fza_empresas`.`CODIGO_EMPRESA` AS `CODIGO_EMPRESA`,`fza_empresas`.`RAZONSOCIAL_EMPRESA` AS `RAZONSOCIAL_EMPRESA`,`fza_empresas`.`NIF_EMPRESA` AS `NIF_EMPRESA`,`fza_empresas`.`MOVIL_EMPRESA` AS `MOVIL_EMPRESA`,`fza_empresas`.`EMAIL_EMPRESA` AS `EMAIL_EMPRESA`,`fza_empresas`.`DIRECCION1_EMPRESA` AS `DIRECCION1_EMPRESA`,`fza_empresas`.`DIRECCION2_EMPRESA` AS `DIRECCION2_EMPRESA`,`fza_empresas`.`CPOSTAL_EMPRESA` AS `CPOSTAL_EMPRESA`,`fza_empresas`.`POBLACION_EMPRESA` AS `POBLACION_EMPRESA`,`fza_empresas`.`PROVINCIA_EMPRESA` AS `PROVINCIA_EMPRESA`,`fza_empresas`.`CODIGO_PAIS_EMPRESA` AS `CODIGO_PAIS_EMPRESA`,`fza_empresas`.`NOMBRE_PAIS_EMPRESA` AS `NOMBRE_PAIS_EMPRESA`,`fza_empresas`.`SERIE_CONTADOR_EMPRESA` AS `SERIE_CONTADOR_EMPRESA`,`fza_empresas`.`GRUPO_ZONA_IVA_EMPRESA` AS `GRUPO_ZONA_IVA_EMPRESA`,`fza_empresas`.`ESRETENCIONES_EMPRESA` AS `ESRETENCIONES_EMPRESA`,`fza_empresas`.`ESREGIMENESPECIALAGRICOLA_EMPRESA` AS `ESREGIMENESPECIALAGRICOLA_EMPRESA`,`fza_empresas`.`TEXTO_LEGAL_FACTURA_EMPRESA` AS `TEXTO_LEGAL_FACTURA_EMPRESA` from `fza_empresas` where (`fza_empresas`.`ACTIVO_EMPRESA` = 'S') order by `fza_empresas`.`ORDEN_EMPRESA` ;

-- ----------------------------
-- View structure for vi_facturas
-- ----------------------------
DROP VIEW IF EXISTS `vi_facturas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_facturas` AS SELECT
    `fza_facturas`.`FECHA_FACTURA` AS `FECHA_FACTURA`,
    `fza_facturas`.`NRO_FACTURA` AS `NRO_FACTURA`,
    `fza_facturas`.`SERIE_FACTURA` AS `SERIE_FACTURA`,
    `fza_facturas`.`TIPO_FACTURA` AS `TIPO_FACTURA`,
    `fza_facturas`.`FASE_FACTURA` AS `FASE_FACTURA`,
    `fza_facturas`.`TOTAL_LIQUIDO_FACTURA` AS `TOTAL_LIQUIDO_FACTURA`,
    `fza_facturas`.`PORCEN_RETENCION_FACTURA` AS `PORCEN_RETENCION_FACTURA`,
    `fza_facturas`.`TOTAL_RETENCION_FACTURA` AS `TOTAL_RETENCION_FACTURA`,
    `fza_facturas`.`TOTAL_IMPUESTOS_FACTURA` AS `TOTAL_IMPUESTOS_FACTURA`,
    `fza_facturas`.`TOTAL_BASES_FACTURA` AS `TOTAL_BASES_FACTURA`,
    `fza_facturas`.`CODIGO_CAJERO_FACTURA` AS `CODIGO_CAJERO_FACTURA`, 
    `fza_facturas`.`FORMA_PAGO_FACTURA` AS `FORMA_PAGO_FACTURA`,
    `fza_facturas`.`CODIGO_EMPRESA_FACTURA` AS `CODIGO_EMPRESA_FACTURA`,
    `fza_facturas`.`RAZONSOCIAL_EMPRESA_FACTURA` AS `RAZONSOCIAL_EMPRESA_FACTURA`,
    `fza_facturas`.`NIF_EMPRESA_FACTURA` AS `NIF_EMPRESA_FACTURA`,
    `fza_facturas`.`MOVIL_EMPRESA_FACTURA` AS `MOVIL_EMPRESA_FACTURA`,
    `fza_facturas`.`EMAIL_EMPRESA_FACTURA` AS `EMAIL_EMPRESA_FACTURA`,
    `fza_facturas`.`DIRECCION1_EMPRESA_FACTURA` AS `DIRECCION1_EMPRESA_FACTURA`,
    `fza_facturas`.`DIRECCION2_EMPRESA_FACTURA` AS `DIRECCION2_EMPRESA_FACTURA`,
    `fza_facturas`.`POBLACION_EMPRESA_FACTURA` AS `POBLACION_EMPRESA_FACTURA`,
    `fza_facturas`.`PROVINCIA_EMPRESA_FACTURA` AS `PROVINCIA_EMPRESA_FACTURA`,
    `fza_facturas`.`NOMBRE_PAIS_EMPRESA_FACTURA` AS `NOMBRE_PAIS_EMPRESA_FACTURA`,
    `fza_facturas`.`CODIGO_PAIS_EMPRESA_FACTURA` AS `CODIGO_PAIS_EMPRESA_FACTURA`,
    `fza_facturas`.`CPOSTAL_EMPRESA_FACTURA` AS `CPOSTAL_EMPRESA_FACTURA`,
    `fza_facturas`.`ESRETENCIONES_EMPRESA_FACTURA` AS `ESRETENCIONES_EMPRESA_FACTURA`,
    `fza_facturas`.`GRUPO_ZONA_IVA_EMPRESA_FACTURA` AS `GRUPO_ZONA_IVA_EMPRESA_FACTURA`,
    `fza_facturas`.`ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA` AS `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`,
    `fza_facturas`.`CODIGO_CLIENTE_FACTURA` AS `CODIGO_CLIENTE_FACTURA`,
    `fza_facturas`.`RAZONSOCIAL_CLIENTE_FACTURA` AS `RAZONSOCIAL_CLIENTE_FACTURA`,
    `fza_facturas`.`NIF_CLIENTE_FACTURA` AS `NIF_CLIENTE_FACTURA`,
    `fza_facturas`.`MOVIL_CLIENTE_FACTURA` AS `MOVIL_CLIENTE_FACTURA`,
    `fza_facturas`.`EMAIL_CLIENTE_FACTURA` AS `EMAIL_CLIENTE_FACTURA`,
    `fza_facturas`.`DIRECCION1_CLIENTE_FACTURA` AS `DIRECCION1_CLIENTE_FACTURA`,
    `fza_facturas`.`DIRECCION2_CLIENTE_FACTURA` AS `DIRECCION2_CLIENTE_FACTURA`,
    `fza_facturas`.`POBLACION_CLIENTE_FACTURA` AS `POBLACION_CLIENTE_FACTURA`,
    `fza_facturas`.`PROVINCIA_CLIENTE_FACTURA` AS `PROVINCIA_CLIENTE_FACTURA`,
    `fza_facturas`.`CPOSTAL_CLIENTE_FACTURA` AS `CPOSTAL_CLIENTE_FACTURA`,
    `fza_facturas`.`NOMBRE_PAIS_CLIENTE_FACTURA` AS `NOMBRE_PAIS_CLIENTE_FACTURA`,
    `fza_facturas`.`CODIGO_PAIS_CLIENTE_FACTURA` AS `CODIGO_PAIS_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIVA_RECARGO_CLIENTE_FACTURA` AS `ESIVA_RECARGO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIVA_EXENTO_CLIENTE_FACTURA` AS `ESIVA_EXENTO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA` AS `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`,
    `fza_facturas`.`ESRETENCIONES_CLIENTE_FACTURA` AS `ESRETENCIONES_CLIENTE_FACTURA`,
    `fza_facturas`.`TARIFA_ARTICULO_CLIENTE_FACTURA` AS `TARIFA_ARTICULO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIMP_INCL_TARIFA_CLIENTE_FACTURA` AS `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`,
    `fza_facturas`.`ESINTRACOMUNITARIO_CLIENTE_FACTURA` AS `ESINTRACOMUNITARIO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIRPF_IMP_INCL_ZONA_IVA_FACTURA` AS `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`,
    `fza_facturas`.`ESAPLICA_RE_ZONA_IVA_FACTURA` AS `ESAPLICA_RE_ZONA_IVA_FACTURA`,
    `fza_facturas`.`ESIVAAGRICOLA_ZONA_IVA_FACTURA` AS `ESIVAAGRICOLA_ZONA_IVA_FACTURA`,
    `fza_facturas`.`PALABRA_REPORTS_ZONA_IVA_FACTURA` AS `PALABRA_REPORTS_ZONA_IVA_FACTURA`,
    `fza_facturas`.`CODIGO_IVA_FACTURA` AS `CODIGO_IVA_FACTURA`,
    `fza_facturas`.`ESVENTA_ACTIVO_FIJO_FACTURA` AS `ESVENTA_ACTIVO_FIJO_FACTURA`,
    `fza_facturas`.`PORCEN_IVAN_FACTURA` AS `PORCEN_IVAN_FACTURA`,
    `fza_facturas`.`TOTAL_IVAN_FACTURA` AS `TOTAL_IVAN_FACTURA`,
    `fza_facturas`.`PORCEN_REN_FACTURA` AS `PORCEN_REN_FACTURA`,
    `fza_facturas`.`TOTAL_REN_FACTURA` AS `TOTAL_REN_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAN_FACTURA` AS `TOTAL_BASEI_IVAN_FACTURA`,
    `fza_facturas`.`PORCEN_IVAR_FACTURA` AS `PORCEN_IVAR_FACTURA`,
    `fza_facturas`.`TOTAL_IVAR_FACTURA` AS `TOTAL_IVAR_FACTURA`,
    `fza_facturas`.`PORCEN_RER_FACTURA` AS `PORCEN_RER_FACTURA`,
    `fza_facturas`.`TOTAL_RER_FACTURA` AS `TOTAL_RER_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAR_FACTURA` AS `TOTAL_BASEI_IVAR_FACTURA`,
    `fza_facturas`.`PORCEN_IVAS_FACTURA` AS `PORCEN_IVAS_FACTURA`,
    `fza_facturas`.`TOTAL_IVAS_FACTURA` AS `TOTAL_IVAS_FACTURA`,
    `fza_facturas`.`PORCEN_RES_FACTURA` AS `PORCEN_RES_FACTURA`,
    `fza_facturas`.`TOTAL_RES_FACTURA` AS `TOTAL_RES_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAS_FACTURA` AS `TOTAL_BASEI_IVAS_FACTURA`,
    `fza_facturas`.`PORCEN_IVAE_FACTURA` AS `PORCEN_IVAE_FACTURA`,
    `fza_facturas`.`TOTAL_IVAE_FACTURA` AS `TOTAL_IVAE_FACTURA`,
    `fza_facturas`.`PORCEN_REE_FACTURA` AS `PORCEN_REE_FACTURA`,
    `fza_facturas`.`TOTAL_REE_FACTURA` AS `TOTAL_REE_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAE_FACTURA` AS `TOTAL_BASEI_IVAE_FACTURA`,
    `fza_facturas`.`NRO_FACTURA_ABONO_FACTURA` AS `NRO_FACTURA_ABONO_FACTURA`,
    `fza_facturas`.`SERIE_FACTURA_ABONO_FACTURA` AS `SERIE_FACTURA_ABONO_FACTURA`,
    `fza_facturas`.`TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA` AS `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA`,
    `fza_facturas`.`TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA` AS `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA`,
    `fza_facturas`.`DOCUMENTO_FACTURA` AS `DOCUMENTO_FACTURA`,
    `fza_facturas`.`XML_FACTURA` AS `XML_FACTURA`,
    `fza_facturas`.`COMENTARIOS_FACTURA` AS `COMENTARIOS_FACTURA`,
    `fza_facturas`.`CONTADOR_LINEAS_FACTURA` AS `CONTADOR_LINEAS_FACTURA`,
    `fza_facturas`.`ESCREARARTICULOS_FACTURA` AS `ESCREARARTICULOS_FACTURA`,
    `fza_facturas`.`ESDESCRIPCIONES_AMP_FACTURA` AS `ESDESCRIPCIONES_AMP_FACTURA`,
    `fza_facturas`.`ESFECHADEENTREGA_FACTURA` AS `ESFECHADEENTREGA_FACTURA`,
    `fza_facturas`.`CODIGO_ALMACEN_FACTURA` AS `CODIGO_ALMACEN_FACTURA`,
    `fza_facturas`.`CODIGO_CAJA_FACTURA` AS `CODIGO_CAJA_FACTURA`,
    `fza_facturas`.`NUMERO_OPERACION_FACTURA` AS `NUMERO_OPERACION_FACTURA`,
    `fza_facturas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
    `fza_facturas`.`INSTANTEALTA` AS `INSTANTEALTA`,
    `fza_facturas`.`USUARIOALTA` AS `USUARIOALTA`,
    `fza_facturas`.`USUARIOMODIF` AS `USUARIOMODIF`,
    `fza_formas_pago`.`DESCRIPCION_FORMAPAGO` AS `DESCRIPCION_FORMAPAGO`,
    `fza_facturas`.`ESCONSOLIDADA_FACTURA` AS `ESCONSOLIDADA_FACTURA`,
    `fza_facturas`.`INSTANTECONSO_FACTURA` AS `INSTANTECONSO_FACTURA`
   
  FROM
    (
    `fza_facturas`
    LEFT JOIN `fza_formas_pago` ON ((
    `fza_facturas`.`FORMA_PAGO_FACTURA` = `fza_formas_pago`.`CODIGO_FORMAPAGO`
    )))
  ORDER BY
    `fza_facturas`.`FECHA_FACTURA` DESC ;

-- ----------------------------
-- View structure for vi_facturas_lineas
-- ----------------------------
DROP VIEW IF EXISTS `vi_facturas_lineas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_facturas_lineas` AS select `fza_facturas_lineas`.`NRO_FACTURA_LINEA` AS `NRO_FACTURA_LINEA`,`fza_facturas_lineas`.`SERIE_FACTURA_LINEA` AS `SERIE_FACTURA_LINEA`,`fza_facturas_lineas`.`LINEA_FACTURA_LINEA` AS `LINEA_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_ARTICULO_FACTURA_LINEA` AS `CODIGO_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_FAMILIA_FACTURA_LINEA` AS `CODIGO_FAMILIA_FACTURA_LINEA`,`fza_facturas_lineas`.`NOMBRE_FAMILIA_FACTURA_LINEA` AS `NOMBRE_FAMILIA_FACTURA_LINEA`,`fza_facturas_lineas`.`ESPROVEEDORPRINCIPAL_FACTURA_LINEA` AS `ESPROVEEDORPRINCIPAL_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_PROVEEDOR_FACTURA_LINEA` AS `CODIGO_PROVEEDOR_FACTURA_LINEA`,`fza_facturas_lineas`.`RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA` AS `RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIO_ULT_COMPRA_FACTURA_LINEA` AS `PRECIO_ULT_COMPRA_FACTURA_LINEA`,`fza_facturas_lineas`.`FECHA_ENTREGA_FACTURA_LINEA` AS `FECHA_ENTREGA_FACTURA_LINEA`,`fza_facturas_lineas`.`TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA` AS `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`ESIMP_INCL_TARIFA_FACTURA_LINEA` AS `ESIMP_INCL_TARIFA_FACTURA_LINEA`,`fza_facturas_lineas`.`TIPOIVA_ARTICULO_FACTURA_LINEA` AS `TIPOIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`DESCRIPCION_ARTICULO_FACTURA_LINEA` AS `DESCRIPCION_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_TARIFA_FACTURA_LINEA` AS `CODIGO_TARIFA_FACTURA_LINEA`,`fza_facturas_lineas`.`CANTIDAD_FACTURA_LINEA` AS `CANTIDAD_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOSALIDA_FACTURA_LINEA` AS `PRECIOSALIDA_FACTURA_LINEA`,`fza_facturas_lineas`.`PORCEN_DTO_FACTURA_LINEA` AS `PORCEN_DTO_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIO_DTO_FACTURA_LINEA` AS `PRECIO_DTO_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` AS `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`PORCEN_IVA_FACTURA_LINEA` AS `PORCEN_IVA_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA` AS `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`TOTAL_FACTURA_LINEA` AS `TOTAL_FACTURA_LINEA`,`fza_facturas_lineas`.`TOTAL_FACTURASIVA_LINEA` AS `TOTAL_FACTURASIVA_LINEA`,`fza_facturas_lineas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_facturas_lineas`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_facturas_lineas`.`USUARIOALTA` AS `USUARIOALTA`,`fza_facturas_lineas`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_facturas_lineas` ;

-- ----------------------------
-- View structure for vi_facturas_lineas_print
-- ----------------------------
DROP VIEW IF EXISTS `vi_facturas_lineas_print`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_facturas_lineas_print` AS select `fza_facturas_lineas`.`NRO_FACTURA_LINEA` AS `NRO_FACTURA_LINEA`,`fza_facturas_lineas`.`SERIE_FACTURA_LINEA` AS `SERIE_FACTURA_LINEA`,`fza_facturas_lineas`.`LINEA_FACTURA_LINEA` AS `LINEA_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_ARTICULO_FACTURA_LINEA` AS `CODIGO_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_FAMILIA_FACTURA_LINEA` AS `CODIGO_FAMILIA_FACTURA_LINEA`,`fza_facturas_lineas`.`NOMBRE_FAMILIA_FACTURA_LINEA` AS `NOMBRE_FAMILIA_FACTURA_LINEA`,`fza_facturas_lineas`.`FECHA_ENTREGA_FACTURA_LINEA` AS `FECHA_ENTREGA_FACTURA_LINEA`,`fza_facturas_lineas`.`TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA` AS `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`ESIMP_INCL_TARIFA_FACTURA_LINEA` AS `ESIMP_INCL_TARIFA_FACTURA_LINEA`,`fza_facturas_lineas`.`TIPOIVA_ARTICULO_FACTURA_LINEA` AS `TIPOIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`DESCRIPCION_ARTICULO_FACTURA_LINEA` AS `DESCRIPCION_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_TARIFA_FACTURA_LINEA` AS `CODIGO_TARIFA_FACTURA_LINEA`,`fza_facturas_lineas`.`CANTIDAD_FACTURA_LINEA` AS `CANTIDAD_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOSALIDA_FACTURA_LINEA` AS `PRECIOSALIDA_FACTURA_LINEA`,`fza_facturas_lineas`.`PORCEN_DTO_FACTURA_LINEA` AS `PORCEN_DTO_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIO_DTO_FACTURA_LINEA` AS `PRECIO_DTO_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` AS `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`PORCEN_IVA_FACTURA_LINEA` AS `PORCEN_IVA_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA` AS `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`TOTAL_FACTURA_LINEA` AS `TOTAL_FACTURA_LINEA`,`fza_facturas_lineas`.`TOTAL_FACTURASIVA_LINEA` AS `TOTAL_FACTURASIVA_LINEA`,`fza_facturas_lineas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_facturas_lineas`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_facturas_lineas`.`USUARIOALTA` AS `USUARIOALTA`,`fza_facturas_lineas`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_facturas_lineas` ;

-- ----------------------------
-- View structure for vi_facturas_print
-- ----------------------------
DROP VIEW IF EXISTS `vi_facturas_print`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_facturas_print` AS SELECT
    `fza_facturas`.`FECHA_FACTURA` AS `FECHA_FACTURA`,
    `fza_facturas`.`NRO_FACTURA` AS `NRO_FACTURA`,
    `fza_facturas`.`SERIE_FACTURA` AS `SERIE_FACTURA`,
    `fza_facturas`.`TOTAL_LIQUIDO_FACTURA` AS `TOTAL_LIQUIDO_FACTURA`,
    `fza_facturas`.`PORCEN_RETENCION_FACTURA` AS `PORCEN_RETENCION_FACTURA`,
    `fza_facturas`.`TOTAL_RETENCION_FACTURA` AS `TOTAL_RETENCION_FACTURA`,
    `fza_facturas`.`TOTAL_IMPUESTOS_FACTURA` AS `TOTAL_IMPUESTOS_FACTURA`,
    `fza_facturas`.`TOTAL_BASES_FACTURA` AS `TOTAL_BASES_FACTURA`,
    `fza_facturas`.`FORMA_PAGO_FACTURA` AS `FORMA_PAGO_FACTURA`,
    `fza_facturas`.`CODIGO_EMPRESA_FACTURA` AS `CODIGO_EMPRESA_FACTURA`,
    `fza_facturas`.`RAZONSOCIAL_EMPRESA_FACTURA` AS `RAZONSOCIAL_EMPRESA_FACTURA`,
    `fza_facturas`.`NIF_EMPRESA_FACTURA` AS `NIF_EMPRESA_FACTURA`,
    `fza_facturas`.`MOVIL_EMPRESA_FACTURA` AS `MOVIL_EMPRESA_FACTURA`,
    `fza_facturas`.`EMAIL_EMPRESA_FACTURA` AS `EMAIL_EMPRESA_FACTURA`,
    `fza_facturas`.`DIRECCION1_EMPRESA_FACTURA` AS `DIRECCION1_EMPRESA_FACTURA`,
    `fza_facturas`.`DIRECCION2_EMPRESA_FACTURA` AS `DIRECCION2_EMPRESA_FACTURA`,
    `fza_facturas`.`POBLACION_EMPRESA_FACTURA` AS `POBLACION_EMPRESA_FACTURA`,
    `fza_facturas`.`PROVINCIA_EMPRESA_FACTURA` AS `PROVINCIA_EMPRESA_FACTURA`,
    `fza_facturas`.`NOMBRE_PAIS_EMPRESA_FACTURA` AS `NOMBRE_PAIS_EMPRESA_FACTURA`,
    `fza_facturas`.`CODIGO_PAIS_EMPRESA_FACTURA` AS `CODIGO_PAIS_EMPRESA_FACTURA`,
    `fza_facturas`.`CPOSTAL_EMPRESA_FACTURA` AS `CPOSTAL_EMPRESA_FACTURA`,
    `fza_facturas`.`ESRETENCIONES_EMPRESA_FACTURA` AS `ESRETENCIONES_EMPRESA_FACTURA`,
    `fza_facturas`.`GRUPO_ZONA_IVA_EMPRESA_FACTURA` AS `GRUPO_ZONA_IVA_EMPRESA_FACTURA`,
    `fza_facturas`.`ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA` AS `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`,
    `fza_facturas`.`CODIGO_CLIENTE_FACTURA` AS `CODIGO_CLIENTE_FACTURA`,
    `fza_facturas`.`RAZONSOCIAL_CLIENTE_FACTURA` AS `RAZONSOCIAL_CLIENTE_FACTURA`,
    `fza_facturas`.`NIF_CLIENTE_FACTURA` AS `NIF_CLIENTE_FACTURA`,
    `fza_facturas`.`MOVIL_CLIENTE_FACTURA` AS `MOVIL_CLIENTE_FACTURA`,
    `fza_facturas`.`EMAIL_CLIENTE_FACTURA` AS `EMAIL_CLIENTE_FACTURA`,
    `fza_facturas`.`DIRECCION1_CLIENTE_FACTURA` AS `DIRECCION1_CLIENTE_FACTURA`,
    `fza_facturas`.`DIRECCION2_CLIENTE_FACTURA` AS `DIRECCION2_CLIENTE_FACTURA`,
    `fza_facturas`.`POBLACION_CLIENTE_FACTURA` AS `POBLACION_CLIENTE_FACTURA`,
    `fza_facturas`.`PROVINCIA_CLIENTE_FACTURA` AS `PROVINCIA_CLIENTE_FACTURA`,
    `fza_facturas`.`CPOSTAL_CLIENTE_FACTURA` AS `CPOSTAL_CLIENTE_FACTURA`,
    `fza_facturas`.`NOMBRE_PAIS_CLIENTE_FACTURA` AS `NOMBRE_PAIS_CLIENTE_FACTURA`,
    `fza_facturas`.`CODIGO_PAIS_CLIENTE_FACTURA` AS `CODIGO_PAIS_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIVA_RECARGO_CLIENTE_FACTURA` AS `ESIVA_RECARGO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIVA_EXENTO_CLIENTE_FACTURA` AS `ESIVA_EXENTO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA` AS `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`,
    `fza_facturas`.`ESRETENCIONES_CLIENTE_FACTURA` AS `ESRETENCIONES_CLIENTE_FACTURA`,
    `fza_facturas`.`TARIFA_ARTICULO_CLIENTE_FACTURA` AS `TARIFA_ARTICULO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIMP_INCL_TARIFA_CLIENTE_FACTURA` AS `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`,
    `fza_facturas`.`ESINTRACOMUNITARIO_CLIENTE_FACTURA` AS `ESINTRACOMUNITARIO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIRPF_IMP_INCL_ZONA_IVA_FACTURA` AS `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`,
    `fza_facturas`.`ESAPLICA_RE_ZONA_IVA_FACTURA` AS `ESAPLICA_RE_ZONA_IVA_FACTURA`,
    `fza_facturas`.`ESIVAAGRICOLA_ZONA_IVA_FACTURA` AS `ESIVAAGRICOLA_ZONA_IVA_FACTURA`,
    `fza_facturas`.`PALABRA_REPORTS_ZONA_IVA_FACTURA` AS `PALABRA_REPORTS_ZONA_IVA_FACTURA`,
    `fza_facturas`.`CODIGO_IVA_FACTURA` AS `CODIGO_IVA_FACTURA`,
    `fza_facturas`.`ESVENTA_ACTIVO_FIJO_FACTURA` AS `ESVENTA_ACTIVO_FIJO_FACTURA`,
    `fza_facturas`.`PORCEN_IVAN_FACTURA` AS `PORCEN_IVAN_FACTURA`,
    `fza_facturas`.`TOTAL_IVAN_FACTURA` AS `TOTAL_IVAN_FACTURA`,
    `fza_facturas`.`PORCEN_REN_FACTURA` AS `PORCEN_REN_FACTURA`,
    `fza_facturas`.`TOTAL_REN_FACTURA` AS `TOTAL_REN_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAN_FACTURA` AS `TOTAL_BASEI_IVAN_FACTURA`,
    `fza_facturas`.`PORCEN_IVAR_FACTURA` AS `PORCEN_IVAR_FACTURA`,
    `fza_facturas`.`TOTAL_IVAR_FACTURA` AS `TOTAL_IVAR_FACTURA`,
    `fza_facturas`.`PORCEN_RER_FACTURA` AS `PORCEN_RER_FACTURA`,
    `fza_facturas`.`TOTAL_RER_FACTURA` AS `TOTAL_RER_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAR_FACTURA` AS `TOTAL_BASEI_IVAR_FACTURA`,
    `fza_facturas`.`PORCEN_IVAS_FACTURA` AS `PORCEN_IVAS_FACTURA`,
    `fza_facturas`.`TOTAL_IVAS_FACTURA` AS `TOTAL_IVAS_FACTURA`,
    `fza_facturas`.`PORCEN_RES_FACTURA` AS `PORCEN_RES_FACTURA`,
    `fza_facturas`.`TOTAL_RES_FACTURA` AS `TOTAL_RES_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAS_FACTURA` AS `TOTAL_BASEI_IVAS_FACTURA`,
    `fza_facturas`.`PORCEN_IVAE_FACTURA` AS `PORCEN_IVAE_FACTURA`,
    `fza_facturas`.`TOTAL_IVAE_FACTURA` AS `TOTAL_IVAE_FACTURA`,
    `fza_facturas`.`PORCEN_REE_FACTURA` AS `PORCEN_REE_FACTURA`,
    `fza_facturas`.`TOTAL_REE_FACTURA` AS `TOTAL_REE_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAE_FACTURA` AS `TOTAL_BASEI_IVAE_FACTURA`,
    `fza_facturas`.`NRO_FACTURA_ABONO_FACTURA` AS `NRO_FACTURA_ABONO_FACTURA`,
    `fza_facturas`.`SERIE_FACTURA_ABONO_FACTURA` AS `SERIE_FACTURA_ABONO_FACTURA`,
    `fza_facturas`.`TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA` AS `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA`,
    `fza_facturas`.`TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA` AS `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA`,
    `fza_facturas`.`DOCUMENTO_FACTURA` AS `DOCUMENTO_FACTURA`,
    `fza_facturas`.`COMENTARIOS_FACTURA` AS `COMENTARIOS_FACTURA`,
    `fza_facturas`.`CONTADOR_LINEAS_FACTURA` AS `CONTADOR_LINEAS_FACTURA`,
    `fza_facturas`.`ESCREARARTICULOS_FACTURA` AS `ESCREARARTICULOS_FACTURA`,
    `fza_facturas`.`ESDESCRIPCIONES_AMP_FACTURA` AS `ESDESCRIPCIONES_AMP_FACTURA`,
    `fza_facturas`.`ESFECHADEENTREGA_FACTURA` AS `ESFECHADEENTREGA_FACTURA`,
    `fza_facturas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
    `fza_facturas`.`INSTANTEALTA` AS `INSTANTEALTA`,
    `fza_facturas`.`USUARIOALTA` AS `USUARIOALTA`,
    `fza_facturas`.`USUARIOMODIF` AS `USUARIOMODIF`,
    `fza_formas_pago`.`DESCRIPCION_FORMAPAGO` AS `DESCRIPCION_FORMAPAGO`,
    `fza_formas_pago`.`ESCONTADO_FORMAPAGO` AS `ESCONTADO_FORMAPAGO`,(
  SELECT
    group_concat(
    ' ',
    date_format(
    `fza_recibos`.`FECHA_VENCIMIENTO_RECIBO`,
    '%d/%m/%Y'
    ),
    '=> ',
    format(`fza_recibos`.`EUROS_RECIBO`, 2), '€' SEPARATOR ',')
  FROM
    `fza_recibos`
  WHERE
    ((
    `fza_recibos`.`NRO_FACTURA_RECIBO` = `fza_facturas`.`NRO_FACTURA`
    )
    AND (
    `fza_recibos`.`SERIE_FACTURA_RECIBO` = `fza_facturas`.`SERIE_FACTURA`
    ))) AS `VENCIMIENTOS_RECIBOS`,
    `fza_empresas`.`IBAN_EMPRESA` AS `IBAN_EMPRESA`,
    `fza_clientes`.`IBAN_CLIENTE` AS `IBAN_CLIENTE`,
    `fza_formas_pago`.`ESVERBANCOEMPRESA_FORMAPAGO` AS `ESVERBANCOEMPRESA_FORMAPAGO`
  FROM
    (((
    `fza_facturas`
    LEFT JOIN `fza_formas_pago` ON ((
    `fza_facturas`.`FORMA_PAGO_FACTURA` = `fza_formas_pago`.`CODIGO_FORMAPAGO`
    )))
    LEFT JOIN `fza_empresas` ON ((
    `fza_facturas`.`CODIGO_EMPRESA_FACTURA` = `fza_empresas`.`CODIGO_EMPRESA`
    )))
    LEFT JOIN `fza_clientes` ON ((
    `fza_facturas`.`CODIGO_CLIENTE_FACTURA` = `fza_clientes`.`CODIGO_CLIENTE`
    )))
  ORDER BY
    `fza_facturas`.`FECHA_FACTURA` DESC ;

-- ----------------------------
-- View structure for vi_fac_busquedas
-- ----------------------------
DROP VIEW IF EXISTS `vi_fac_busquedas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_fac_busquedas` AS SELECT
    `fza_facturas`.`FECHA_FACTURA` AS `FECHA_FACTURA`,
    `fza_facturas`.`NRO_FACTURA` AS `NRO_FACTURA`,
    `fza_facturas`.`SERIE_FACTURA` AS `SERIE_FACTURA`,
    `fza_facturas`.`TOTAL_LIQUIDO_FACTURA` AS `TOTAL_LIQUIDO_FACTURA`,
    `fza_facturas`.`PORCEN_RETENCION_FACTURA` AS `PORCEN_RETENCION_FACTURA`,
    `fza_facturas`.`TOTAL_RETENCION_FACTURA` AS `TOTAL_RETENCION_FACTURA`,
    `fza_facturas`.`TOTAL_IMPUESTOS_FACTURA` AS `TOTAL_IMPUESTOS_FACTURA`,
    `fza_facturas`.`TOTAL_BASES_FACTURA` AS `TOTAL_BASES_FACTURA`,
    `fza_facturas`.`FORMA_PAGO_FACTURA` AS `FORMA_PAGO_FACTURA`,
    `fza_formas_pago`.`DESCRIPCION_FORMAPAGO` AS `DESCRIPCION_FORMAPAGO`,
    `fza_facturas`.`CODIGO_EMPRESA_FACTURA` AS `CODIGO_EMPRESA_FACTURA`,
    `fza_facturas`.`RAZONSOCIAL_EMPRESA_FACTURA` AS `RAZONSOCIAL_EMPRESA_FACTURA`,
    `fza_facturas`.`NIF_EMPRESA_FACTURA` AS `NIF_EMPRESA_FACTURA`,
    `fza_facturas`.`MOVIL_EMPRESA_FACTURA` AS `MOVIL_EMPRESA_FACTURA`,
    `fza_facturas`.`EMAIL_EMPRESA_FACTURA` AS `EMAIL_EMPRESA_FACTURA`,
    `fza_facturas`.`DIRECCION1_EMPRESA_FACTURA` AS `DIRECCION1_EMPRESA_FACTURA`,
    `fza_facturas`.`DIRECCION2_EMPRESA_FACTURA` AS `DIRECCION2_EMPRESA_FACTURA`,
    `fza_facturas`.`POBLACION_EMPRESA_FACTURA` AS `POBLACION_EMPRESA_FACTURA`,
    `fza_facturas`.`PROVINCIA_EMPRESA_FACTURA` AS `PROVINCIA_EMPRESA_FACTURA`,
    `fza_facturas`.`NOMBRE_PAIS_EMPRESA_FACTURA` AS `NOMBRE_PAIS_EMPRESA_FACTURA`,
    `fza_facturas`.`CPOSTAL_EMPRESA_FACTURA` AS `CPOSTAL_EMPRESA_FACTURA`,
    `fza_facturas`.`ESRETENCIONES_EMPRESA_FACTURA` AS `ESRETENCIONES_EMPRESA_FACTURA`,
    `fza_facturas`.`GRUPO_ZONA_IVA_EMPRESA_FACTURA` AS `GRUPO_ZONA_IVA_EMPRESA_FACTURA`,
    `fza_facturas`.`ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA` AS `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`,
    `fza_facturas`.`CODIGO_CLIENTE_FACTURA` AS `CODIGO_CLIENTE_FACTURA`,
    `fza_facturas`.`RAZONSOCIAL_CLIENTE_FACTURA` AS `RAZONSOCIAL_CLIENTE_FACTURA`,
    `fza_facturas`.`NIF_CLIENTE_FACTURA` AS `NIF_CLIENTE_FACTURA`,
    `fza_facturas`.`MOVIL_CLIENTE_FACTURA` AS `MOVIL_CLIENTE_FACTURA`,
    `fza_facturas`.`EMAIL_CLIENTE_FACTURA` AS `EMAIL_CLIENTE_FACTURA`,
    `fza_facturas`.`DIRECCION1_CLIENTE_FACTURA` AS `DIRECCION1_CLIENTE_FACTURA`,
    `fza_facturas`.`DIRECCION2_CLIENTE_FACTURA` AS `DIRECCION2_CLIENTE_FACTURA`,
    `fza_facturas`.`POBLACION_CLIENTE_FACTURA` AS `POBLACION_CLIENTE_FACTURA`,
    `fza_facturas`.`PROVINCIA_CLIENTE_FACTURA` AS `PROVINCIA_CLIENTE_FACTURA`,
    `fza_facturas`.`CPOSTAL_CLIENTE_FACTURA` AS `CPOSTAL_CLIENTE_FACTURA`,
    `fza_facturas`.`NOMBRE_PAIS_CLIENTE_FACTURA` AS `NOMBRE_PAIS_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIVA_RECARGO_CLIENTE_FACTURA` AS `ESIVA_RECARGO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIVA_EXENTO_CLIENTE_FACTURA` AS `ESIVA_EXENTO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA` AS `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`,
    `fza_facturas`.`ESRETENCIONES_CLIENTE_FACTURA` AS `ESRETENCIONES_CLIENTE_FACTURA`,
    `fza_facturas`.`TARIFA_ARTICULO_CLIENTE_FACTURA` AS `TARIFA_ARTICULO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIMP_INCL_TARIFA_CLIENTE_FACTURA` AS `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`,
    `fza_facturas`.`ESINTRACOMUNITARIO_CLIENTE_FACTURA` AS `ESINTRACOMUNITARIO_CLIENTE_FACTURA`,
    `fza_facturas`.`ESIRPF_IMP_INCL_ZONA_IVA_FACTURA` AS `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`,
    `fza_facturas`.`ESAPLICA_RE_ZONA_IVA_FACTURA` AS `ESAPLICA_RE_ZONA_IVA_FACTURA`,
    `fza_facturas`.`ESIVAAGRICOLA_ZONA_IVA_FACTURA` AS `ESIVAAGRICOLA_ZONA_IVA_FACTURA`,
    `fza_facturas`.`PALABRA_REPORTS_ZONA_IVA_FACTURA` AS `PALABRA_REPORTS_ZONA_IVA_FACTURA`,
    `fza_facturas`.`CODIGO_IVA_FACTURA` AS `CODIGO_IVA_FACTURA`,
    `fza_facturas`.`ESVENTA_ACTIVO_FIJO_FACTURA` AS `ESVENTA_ACTIVO_FIJO_FACTURA`,
    `fza_facturas`.`PORCEN_IVAN_FACTURA` AS `PORCEN_IVAN_FACTURA`,
    `fza_facturas`.`TOTAL_IVAN_FACTURA` AS `TOTAL_IVAN_FACTURA`,
    `fza_facturas`.`PORCEN_REN_FACTURA` AS `PORCEN_REN_FACTURA`,
    `fza_facturas`.`TOTAL_REN_FACTURA` AS `TOTAL_REN_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAN_FACTURA` AS `TOTAL_BASEI_IVAN_FACTURA`,
    `fza_facturas`.`PORCEN_IVAR_FACTURA` AS `PORCEN_IVAR_FACTURA`,
    `fza_facturas`.`TOTAL_IVAR_FACTURA` AS `TOTAL_IVAR_FACTURA`,
    `fza_facturas`.`PORCEN_RER_FACTURA` AS `PORCEN_RER_FACTURA`,
    `fza_facturas`.`TOTAL_RER_FACTURA` AS `TOTAL_RER_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAR_FACTURA` AS `TOTAL_BASEI_IVAR_FACTURA`,
    `fza_facturas`.`PORCEN_IVAS_FACTURA` AS `PORCEN_IVAS_FACTURA`,
    `fza_facturas`.`TOTAL_IVAS_FACTURA` AS `TOTAL_IVAS_FACTURA`,
    `fza_facturas`.`PORCEN_RES_FACTURA` AS `PORCEN_RES_FACTURA`,
    `fza_facturas`.`TOTAL_RES_FACTURA` AS `TOTAL_RES_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAS_FACTURA` AS `TOTAL_BASEI_IVAS_FACTURA`,
    `fza_facturas`.`PORCEN_IVAE_FACTURA` AS `PORCEN_IVAE_FACTURA`,
    `fza_facturas`.`TOTAL_IVAE_FACTURA` AS `TOTAL_IVAE_FACTURA`,
    `fza_facturas`.`PORCEN_REE_FACTURA` AS `PORCEN_REE_FACTURA`,
    `fza_facturas`.`TOTAL_REE_FACTURA` AS `TOTAL_REE_FACTURA`,
    `fza_facturas`.`TOTAL_BASEI_IVAE_FACTURA` AS `TOTAL_BASEI_IVAE_FACTURA`
  FROM
    (
    `fza_facturas`
    LEFT JOIN `fza_formas_pago` ON ((
    `fza_facturas`.`FORMA_PAGO_FACTURA` = `fza_formas_pago`.`CODIGO_FORMAPAGO`
    ))) ;

-- ----------------------------
-- View structure for vi_fac_lin_busquedas
-- ----------------------------
DROP VIEW IF EXISTS `vi_fac_lin_busquedas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_fac_lin_busquedas` AS select `fza_facturas_lineas`.`NRO_FACTURA_LINEA` AS `NRO_FACTURA_LINEA`,`fza_facturas_lineas`.`SERIE_FACTURA_LINEA` AS `SERIE_FACTURA_LINEA`,`fza_facturas_lineas`.`LINEA_FACTURA_LINEA` AS `LINEA_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_ARTICULO_FACTURA_LINEA` AS `CODIGO_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_FAMILIA_FACTURA_LINEA` AS `CODIGO_FAMILIA_FACTURA_LINEA`,`fza_facturas_lineas`.`NOMBRE_FAMILIA_FACTURA_LINEA` AS `NOMBRE_FAMILIA_FACTURA_LINEA`,`fza_facturas_lineas`.`FECHA_ENTREGA_FACTURA_LINEA` AS `FECHA_ENTREGA_FACTURA_LINEA`,`fza_facturas_lineas`.`TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA` AS `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`ESIMP_INCL_TARIFA_FACTURA_LINEA` AS `ESIMP_INCL_TARIFA_FACTURA_LINEA`,`fza_facturas_lineas`.`TIPOIVA_ARTICULO_FACTURA_LINEA` AS `TIPOIVA_ARTICULO_FACTURA_LINEA`,`fza_ivas_tipos`.`NOMBRE_TIPO_IVA` AS `NOMBRE_TIPO_IVA`,`fza_facturas_lineas`.`DESCRIPCION_ARTICULO_FACTURA_LINEA` AS `DESCRIPCION_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`CODIGO_TARIFA_FACTURA_LINEA` AS `CODIGO_TARIFA_FACTURA_LINEA`,`fza_facturas_lineas`.`CANTIDAD_FACTURA_LINEA` AS `CANTIDAD_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOSALIDA_FACTURA_LINEA` AS `PRECIOSALIDA_FACTURA_LINEA`,`fza_facturas_lineas`.`PORCEN_DTO_FACTURA_LINEA` AS `PORCEN_DTO_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIO_DTO_FACTURA_LINEA` AS `PRECIO_DTO_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` AS `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`PORCEN_IVA_FACTURA_LINEA` AS `PORCEN_IVA_FACTURA_LINEA`,`fza_facturas_lineas`.`PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA` AS `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`,`fza_facturas_lineas`.`TOTAL_FACTURA_LINEA` AS `TOTAL_FACTURA_LINEA`,`fza_facturas_lineas`.`TOTAL_FACTURASIVA_LINEA` AS `TOTAL_FACTURASIVA_LINEA`,`fza_facturas`.`CODIGO_CLIENTE_FACTURA` AS `CODIGO_CLIENTE_FACTURA_LINEA`,`fza_facturas`.`CODIGO_EMPRESA_FACTURA` AS `CODIGO_EMPRESA_FACTURA_LINEA` from ((`fza_facturas_lineas` left join `fza_facturas` on(((`fza_facturas_lineas`.`NRO_FACTURA_LINEA` = `fza_facturas`.`NRO_FACTURA`) and (`fza_facturas_lineas`.`SERIE_FACTURA_LINEA` = `fza_facturas`.`SERIE_FACTURA`)))) left join `fza_ivas_tipos` on((`fza_facturas_lineas`.`TIPOIVA_ARTICULO_FACTURA_LINEA` = `fza_ivas_tipos`.`CODIGO_ABREVIATURA_TIPO_IVA`))) ;

-- ----------------------------
-- View structure for vi_formapago
-- ----------------------------
DROP VIEW IF EXISTS `vi_formapago`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_formapago` AS SELECT
    `fza_formas_pago`.`CODIGO_FORMAPAGO` AS `CODIGO_FORMAPAGO`,
    `fza_formas_pago`.`ACTIVO_FORMAPAGO` AS `ACTIVO_FORMAPAGO`,
    `fza_formas_pago`.`ORDEN_FORMAPAGO` AS `ORDEN_FORMAPAGO`,
    `fza_formas_pago`.`DESCRIPCION_FORMAPAGO` AS `DESCRIPCION_FORMAPAGO`,
    `fza_formas_pago`.`N_PLAZOS_FORMAPAGO` AS `N_PLAZOS_FORMAPAGO`,
    `fza_formas_pago`.`N_DIAS_ENTRE_PLAZOS_FORMAPAGO` AS `N_DIAS_ENTRE_PLAZOS_FORMAPAGO`,
    `fza_formas_pago`.`PORCEN_ANTICIPO_FORMAPAGO` AS `PORCEN_ANTICIPO_FORMAPAGO`,
    `fza_formas_pago`.`ESVERBANCOEMPRESA_FORMAPAGO` AS `ESVERBANCOEMPRESA_FORMAPAGO`,
    `fza_formas_pago`.`ESDEFAULT_FORMAPAGO` AS `ESDEFAULT_FORMAPAGO`,
    `fza_formas_pago`.`INSTANTEMODIF` AS `INSTANTEMODIF`,
    `fza_formas_pago`.`INSTANTEALTA` AS `INSTANTEALTA`,
    `fza_formas_pago`.`USUARIOALTA` AS `USUARIOALTA`,
    `fza_formas_pago`.`USUARIOMODIF` AS `USUARIOMODIF`
  FROM
    `fza_formas_pago` ;

-- ----------------------------
-- View structure for vi_info_tpv_completa
-- ----------------------------
DROP VIEW IF EXISTS `vi_info_tpv_completa`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_info_tpv_completa` AS SELECT 
    A.CODIGO_ARTICULO,
    A.DESCRIPCION_ARTICULO,
    A.TIPO_ARTICULO,       -- 'ESTANDAR', 'SERVICIO'
    A.ESTRAZABLE_ARTICULO as TIENE_TRAZABILIDAD,  -- 'S' / 'N'
    
    -- DATOS ECONÓMICOS (Asumiendo Tarifa General 'PVP')
   --  COALESCE(T.PRECIO_TARIFA, 0) AS PRECIO_VENTA,
   -- COALESCE(IVA.PORCEN_IVA, 21) AS PORCEN_IVA,
    
    -- METADATOS: SEMÁFORO DE ATRIBUTOS (Cuenta cuántos tiene definidos)
    (SELECT COUNT(*) FROM vi_atributos_nombres N 
     WHERE N.CODIGO_ARTICULO_PADRE = A.CODIGO_ARTICULO) AS NUM_ATRIBUTOS_REQ,

    -- METADATOS: NOMBRES DE LAS COLUMNAS (Para pintar la cabecera del Grid)
    -- Subconsultas para sacar el nombre del Atributo 1, 2, 3, 4 y 5
    (SELECT NOMBRE_ATRIBUTO FROM vi_atributos_nombres N 
     WHERE N.CODIGO_ARTICULO_PADRE = A.CODIGO_ARTICULO AND N.ORDEN_VISUAL_ATRIBUTO = 1 LIMIT 1) AS ATTR1_NOMBRE,
     
    (SELECT NOMBRE_ATRIBUTO FROM vi_atributos_nombres N 
     WHERE N.CODIGO_ARTICULO_PADRE = A.CODIGO_ARTICULO AND N.ORDEN_VISUAL_ATRIBUTO = 2 LIMIT 1) AS ATTR2_NOMBRE,

    (SELECT NOMBRE_ATRIBUTO FROM vi_atributos_nombres N 
     WHERE N.CODIGO_ARTICULO_PADRE = A.CODIGO_ARTICULO AND N.ORDEN_VISUAL_ATRIBUTO = 3 LIMIT 1) AS ATTR3_NOMBRE,
     
    (SELECT NOMBRE_ATRIBUTO FROM vi_atributos_nombres N 
     WHERE N.CODIGO_ARTICULO_PADRE = A.CODIGO_ARTICULO AND N.ORDEN_VISUAL_ATRIBUTO = 4 LIMIT 1) AS ATTR4_NOMBRE,
     
    (SELECT NOMBRE_ATRIBUTO FROM vi_atributos_nombres N 
     WHERE N.CODIGO_ARTICULO_PADRE = A.CODIGO_ARTICULO AND N.ORDEN_VISUAL_ATRIBUTO = 5 LIMIT 1) AS ATTR5_NOMBRE

FROM fza_articulos A ;

-- ----------------------------
-- View structure for vi_ivas
-- ----------------------------
DROP VIEW IF EXISTS `vi_ivas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_ivas` AS select `fza_ivas`.`CODIGO_IVA` AS `CODIGO_IVA`,`fza_ivas`.`GRUPO_ZONA_IVA` AS `GRUPO_ZONA_IVA`,`fza_ivas`.`DESCRIPCION_ZONA_IVA` AS `DESCRIPCION_ZONA_IVA`,`fza_ivas`.`PORCENEXENTO_IVA` AS `PORCENEXENTO_IVA`,`fza_ivas`.`PORCENEXENTO_RE_IVA` AS `PORCENEXENTO_RE_IVA`,`fza_ivas`.`PORCENNORMAL_IVA` AS `PORCENNORMAL_IVA`,`fza_ivas`.`PORCENNORMAL_RE_IVA` AS `PORCENNORMAL_RE_IVA`,`fza_ivas`.`PORCENREDUCIDO_IVA` AS `PORCENREDUCIDO_IVA`,`fza_ivas`.`PORCENREDUCIDO_RE_IVA` AS `PORCENREDUCIDO_RE_IVA`,`fza_ivas`.`PORCENSUPERREDUCIDO_IVA` AS `PORCENSUPERREDUCIDO_IVA`,`fza_ivas`.`PORCENSUPERREDUCIDO_RE_IVA` AS `PORCENSUPERREDUCIDO_RE_IVA`,`fza_ivas`.`FECHA_DESDE_IVA` AS `FECHA_DESDE_IVA`,`fza_ivas`.`FECHA_HASTA_IVA` AS `FECHA_HASTA_IVA`,`fza_ivas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_ivas`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_ivas`.`USUARIOALTA` AS `USUARIOALTA`,`fza_ivas`.`USUARIOMODIF` AS `USUARIOMODIF`,`fza_ivas_grupos`.`ESAPLICA_RE_ZONA_IVA` AS `ESAPLICA_RE_ZONA_IVA`,`fza_ivas_grupos`.`ESIVAAGRICOLA_ZONA_IVA` AS `ESIVAAGRICOLA_ZONA_IVA`,`fza_ivas_grupos`.`ESDEFAULT_ZONA_IVA` AS `ESDEFAULT_ZONA_IVA`,`fza_ivas_grupos`.`ESIRPF_IMP_INCL_ZONA_IVA` AS `ESIRPF_IMP_INCL_ZONA_IVA`,`fza_ivas_grupos`.`PALABRA_REPORTS_ZONA_IVA` AS `PALABRA_REPORTS_ZONA_IVA` from (`fza_ivas` join `fza_ivas_grupos` on((`fza_ivas`.`GRUPO_ZONA_IVA` = `fza_ivas_grupos`.`GRUPO_ZONA_IVA`))) ;

-- ----------------------------
-- View structure for vi_ivas_empresa
-- ----------------------------
DROP VIEW IF EXISTS `vi_ivas_empresa`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_ivas_empresa` AS select `i`.`CODIGO_IVA` AS `CODIGO_IVA`,`i`.`GRUPO_ZONA_IVA` AS `GRUPO_ZONA_IVA`,`i`.`DESCRIPCION_ZONA_IVA` AS `DESCRIPCION_ZONA_IVA`,`i`.`PORCENEXENTO_IVA` AS `PORCENEXENTO_IVA`,`i`.`PORCENEXENTO_RE_IVA` AS `PORCENEXENTO_RE_IVA`,`i`.`PORCENNORMAL_IVA` AS `PORCENNORMAL_IVA`,`i`.`PORCENNORMAL_RE_IVA` AS `PORCENNORMAL_RE_IVA`,`i`.`PORCENREDUCIDO_IVA` AS `PORCENREDUCIDO_IVA`,`i`.`PORCENREDUCIDO_RE_IVA` AS `PORCENREDUCIDO_RE_IVA`,`i`.`PORCENSUPERREDUCIDO_IVA` AS `PORCENSUPERREDUCIDO_IVA`,`i`.`PORCENSUPERREDUCIDO_RE_IVA` AS `PORCENSUPERREDUCIDO_RE_IVA`,`i`.`FECHA_DESDE_IVA` AS `FECHA_DESDE_IVA`,`i`.`FECHA_HASTA_IVA` AS `FECHA_HASTA_IVA`,`ig`.`ESAPLICA_RE_ZONA_IVA` AS `ESAPLICA_RE_ZONA_IVA`,`ig`.`ESIVAAGRICOLA_ZONA_IVA` AS `ESIVAAGRICOLA_ZONA_IVA`,`ig`.`ESDEFAULT_ZONA_IVA` AS `ESDEFAULT_ZONA_IVA`,`em`.`CODIGO_EMPRESA` AS `CODIGO_EMPRESA`,`ig`.`ESIRPF_IMP_INCL_ZONA_IVA` AS `ESIRPF_IMP_INCL_ZONA_IVA`,`ig`.`PALABRA_REPORTS_ZONA_IVA` AS `PALABRA_REPORTS_ZONA_IVA` from ((`fza_ivas` `i` join `fza_ivas_grupos` `ig` on((`i`.`GRUPO_ZONA_IVA` = `ig`.`GRUPO_ZONA_IVA`))) join `fza_empresas` `em` on((`em`.`GRUPO_ZONA_IVA_EMPRESA` = `ig`.`GRUPO_ZONA_IVA`))) ;

-- ----------------------------
-- View structure for vi_ivas_grupos
-- ----------------------------
DROP VIEW IF EXISTS `vi_ivas_grupos`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_ivas_grupos` AS select `fza_ivas_grupos`.`GRUPO_ZONA_IVA` AS `GRUPO_ZONA_IVA`,`fza_ivas_grupos`.`DESCRIPCION_ZONA_IVA` AS `DESCRIPCION_ZONA_IVA`,`fza_ivas_grupos`.`ESIRPF_IMP_INCL_ZONA_IVA` AS `ESIRPF_IMP_INCL_ZONA_IVA`,`fza_ivas_grupos`.`ESIVAAGRICOLA_ZONA_IVA` AS `ESIVAAGRICOLA_ZONA_IVA`,`fza_ivas_grupos`.`ESAPLICA_RE_ZONA_IVA` AS `ESAPLICA_RE_ZONA_IVA`,`fza_ivas_grupos`.`ESDEFAULT_ZONA_IVA` AS `ESDEFAULT_ZONA_IVA`,`fza_ivas_grupos`.`PALABRA_REPORTS_ZONA_IVA` AS `PALABRA_REPORTS_ZONA_IVA`,`fza_ivas_grupos`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_ivas_grupos`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_ivas_grupos`.`USUARIOALTA` AS `USUARIOALTA`,`fza_ivas_grupos`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_ivas_grupos` ;

-- ----------------------------
-- View structure for vi_ivas_zonas
-- ----------------------------
DROP VIEW IF EXISTS `vi_ivas_zonas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_ivas_zonas` AS select `fza_ivas_zonas`.`CODIGO_ZONA_IVA` AS `CODIGO_ZONA_IVA`,`fza_ivas_zonas`.`DESCRIPCION_ZONA_IVA` AS `DESCRIPCION_ZONA_IVA`,`fza_ivas_zonas`.`ESDEFAULT_ZONA_IVA` AS `ESDEFAULT_ZONA_IVA` from `fza_ivas_zonas` ;

-- ----------------------------
-- View structure for vi_paises
-- ----------------------------
DROP VIEW IF EXISTS `vi_paises`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_paises` AS select `fza_paises`.`COD_PAIS_ALPHA2` AS `CODIGO`,`fza_paises`.`NOMBRE_SPA_PAIS` AS `NOMBRE` from `fza_paises` order by `fza_paises`.`ORDEN_PAIS`,`fza_paises`.`NOMBRE_SPA_PAIS` ;

-- ----------------------------
-- View structure for vi_proveedores
-- ----------------------------
DROP VIEW IF EXISTS `vi_proveedores`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_proveedores` AS select `fza_proveedores`.`CODIGO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,`fza_proveedores`.`ACTIVO_PROVEEDOR` AS `ACTIVO_PROVEEDOR`,`fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZONSOCIAL_PROVEEDOR`,`fza_proveedores`.`NIF_PROVEEDOR` AS `NIF_PROVEEDOR`,`fza_proveedores`.`MOVIL_PROVEEDOR` AS `MOVIL_PROVEEDOR`,`fza_proveedores`.`EMAIL_PROVEEDOR` AS `EMAIL_PROVEEDOR`,`fza_proveedores`.`DIRECCION1_PROVEEDOR` AS `DIRECCION1_PROVEEDOR`,`fza_proveedores`.`DIRECCION2_PROVEEDOR` AS `DIRECCION2_PROVEEDOR`,`fza_proveedores`.`POBLACION_PROVEEDOR` AS `POBLACION_PROVEEDOR`,`fza_proveedores`.`PROVINCIA_PROVEEDOR` AS `PROVINCIA_PROVEEDOR`,`fza_proveedores`.`CPOSTAL_PROVEEDOR` AS `CPOSTAL_PROVEEDOR`,`fza_proveedores`.`PAIS_PROVEEDOR` AS `PAIS_PROVEEDOR`,`fza_proveedores`.`OBSERVACIONES_PROVEEDOR` AS `OBSERVACIONES_PROVEEDOR`,`fza_proveedores`.`REFERENCIA_PROVEEDOR` AS `REFERENCIA_PROVEEDOR`,`fza_proveedores`.`CONTACTO_PROVEEDOR` AS `CONTACTO_PROVEEDOR`,`fza_proveedores`.`TELEFONO_CONTACTO_PROVEEDOR` AS `TELEFONO_CONTACTO_PROVEEDOR`,`fza_proveedores`.`TELEFONO_PROVEEDOR` AS `TELEFONO_PROVEEDOR`,`fza_proveedores`.`IBAN_PROVEEDOR` AS `IBAN_PROVEEDOR`,`fza_proveedores`.`ORDEN_PROVEEDOR` AS `ORDEN_PROVEEDOR`,`fza_proveedores`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_proveedores`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_proveedores`.`USUARIOALTA` AS `USUARIOALTA`,`fza_proveedores`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_proveedores` ;

-- ----------------------------
-- View structure for vi_proveedores_articulos
-- ----------------------------
DROP VIEW IF EXISTS `vi_proveedores_articulos`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_proveedores_articulos` AS select `fza_articulos_proveedores`.`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,`fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR` AS `CODIGO_ARTICULO`,`vi_articulos`.`DESCRIPCION_ARTICULO` AS `DESCRIPCION_ARTICULO`,`vi_articulos`.`CODIGO_FAMILIA_ARTICULO` AS `CODIGO_FAMILIA`,`vi_articulos`.`DESCRIPCION_FAMILIA` AS `DESCRIPCION_FAMILIA`,`vi_articulos`.`TIPO_CANTIDAD_ARTICULO` AS `TIPO_CATNTIDAD_ARTICULO`,`vi_articulos`.`ESACTIVO_FIJO_ARTICULO` AS `ESACTIVO_FIJO_ARTICULO`,`fza_articulos_proveedores`.`PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR` AS `PRECIO_ULT_COMPRA`,`fza_articulos_proveedores`.`FECHA_VALIDEZ_ARTICULO_PROVEEDOR` AS `FECHA_VALIDEZ`,`fza_articulos_proveedores`.`ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` AS `ESPROVEEDORPRINCIPAL`,`fza_articulos_proveedores`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_articulos_proveedores`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_articulos_proveedores`.`USUARIOALTA` AS `USUARIOALTA`,`fza_articulos_proveedores`.`USUARIOMODIF` AS `USUARIOMODIF` from (`fza_articulos_proveedores` left join `vi_articulos` on((`fza_articulos_proveedores`.`CODIGO_ARTICULO_ARTICULO_PROVEEDOR` = `vi_articulos`.`CODIGO_ARTICULO`))) ;

-- ----------------------------
-- View structure for vi_proveedores_busquedas
-- ----------------------------
DROP VIEW IF EXISTS `vi_proveedores_busquedas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_proveedores_busquedas` AS select `fza_proveedores`.`CODIGO_PROVEEDOR` AS `CODIGO_PROVEEDOR`,`fza_proveedores`.`ACTIVO_PROVEEDOR` AS `ACTIVO_PROVEEDOR`,`fza_proveedores`.`RAZONSOCIAL_PROVEEDOR` AS `RAZONSOCIAL_PROVEEDOR`,`fza_proveedores`.`NIF_PROVEEDOR` AS `NIF_PROVEEDOR`,`fza_proveedores`.`MOVIL_PROVEEDOR` AS `MOVIL_PROVEEDOR`,`fza_proveedores`.`EMAIL_PROVEEDOR` AS `EMAIL_PROVEEDOR`,`fza_proveedores`.`DIRECCION1_PROVEEDOR` AS `DIRECCION1_PROVEEDOR`,`fza_proveedores`.`DIRECCION2_PROVEEDOR` AS `DIRECCION2_PROVEEDOR`,`fza_proveedores`.`POBLACION_PROVEEDOR` AS `POBLACION_PROVEEDOR`,`fza_proveedores`.`PROVINCIA_PROVEEDOR` AS `PROVINCIA_PROVEEDOR`,`fza_proveedores`.`CPOSTAL_PROVEEDOR` AS `CPOSTAL_PROVEEDOR`,`fza_proveedores`.`PAIS_PROVEEDOR` AS `PAIS_PROVEEDOR`,`fza_proveedores`.`OBSERVACIONES_PROVEEDOR` AS `OBSERVACIONES_PROVEEDOR`,`fza_proveedores`.`REFERENCIA_PROVEEDOR` AS `REFERENCIA_PROVEEDOR`,`fza_proveedores`.`CONTACTO_PROVEEDOR` AS `CONTACTO_PROVEEDOR`,`fza_proveedores`.`TELEFONO_CONTACTO_PROVEEDOR` AS `TELEFONO_CONTACTO_PROVEEDOR`,`fza_proveedores`.`TELEFONO_PROVEEDOR` AS `TELEFONO_PROVEEDOR`,`fza_proveedores`.`IBAN_PROVEEDOR` AS `IBAN_PROVEEDOR`,`fza_proveedores`.`ORDEN_PROVEEDOR` AS `ORDEN_PROVEEDOR`,`fza_proveedores`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_proveedores`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_proveedores`.`USUARIOALTA` AS `USUARIOALTA`,`fza_proveedores`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_proveedores` where (`fza_proveedores`.`ACTIVO_PROVEEDOR` = 'S') order by `fza_proveedores`.`ORDEN_PROVEEDOR` ;

-- ----------------------------
-- View structure for vi_recibos
-- ----------------------------
DROP VIEW IF EXISTS `vi_recibos`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_recibos` AS select `fza_recibos`.`NRO_FACTURA_RECIBO` AS `NRO_FACTURA_RECIBO`,`fza_recibos`.`SERIE_FACTURA_RECIBO` AS `SERIE_FACTURA_RECIBO`,`fza_recibos`.`NRO_PLAZO_RECIBO` AS `NRO_PLAZO_RECIBO`,`fza_recibos`.`FORMA_PAGO_ORIGEN_RECIBO` AS `FORMA_PAGO_ORIGEN_RECIBO`,`fza_recibos`.`FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO` AS `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO`,`fza_recibos`.`EUROS_RECIBO` AS `EUROS_RECIBO`,`fza_recibos`.`STADO_RECIBO` AS `STADO_RECIBO`,`fza_recibos`.`FECHA_EXPEDICION_RECIBO` AS `FECHA_EXPEDICION_RECIBO`,`fza_recibos`.`FECHA_VENCIMIENTO_RECIBO` AS `FECHA_VENCIMIENTO_RECIBO`,`fza_recibos`.`IBAN_CLIENTE_RECIBO` AS `IBAN_CLIENTE_RECIBO`,`fza_recibos`.`FECHA_PAGO_RECIBO` AS `FECHA_PAGO_RECIBO`,`fza_recibos`.`LOCALIDAD_EXPEDICION_RECIBO` AS `LOCALIDAD_EXPEDICION_RECIBO`,`fza_recibos`.`CODIGO_CLIENTE_RECIBO` AS `CODIGO_CLIENTE_RECIBO`,`fza_recibos`.`RAZONSOCIAL_CLIENTE_RECIBO` AS `RAZONSOCIAL_CLIENTE_RECIBO`,`fza_recibos`.`DIRECCION1_CLIENTE_RECIBO` AS `DIRECCION1_CLIENTE_RECIBO`,`fza_recibos`.`POBLACION_CLIENTE_RECIBO` AS `POBLACION_CLIENTE_RECIBO`,`fza_recibos`.`PROVINCIA_CLIENTE_RECIBO` AS `PROVINCIA_CLIENTE_RECIBO`,`fza_recibos`.`CPOSTAL_CLIENTE_RECIBO` AS `CPOSTAL_CLIENTE_RECIBO`,`fza_recibos`.`IMPORTE_LETRA_RECIBO` AS `IMPORTE_LETRA_RECIBO`,`fza_recibos`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_recibos`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_recibos`.`USUARIOALTA` AS `USUARIOALTA`,`fza_recibos`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_recibos` order by `fza_recibos`.`SERIE_FACTURA_RECIBO`,`fza_recibos`.`NRO_FACTURA_RECIBO`,`fza_recibos`.`NRO_PLAZO_RECIBO` ;

-- ----------------------------
-- View structure for vi_tarifas
-- ----------------------------
DROP VIEW IF EXISTS `vi_tarifas`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_tarifas` AS select `fza_tarifas`.`CODIGO_TARIFA` AS `CODIGO_TARIFA`,`fza_tarifas`.`NOMBRE_TARIFA` AS `NOMBRE_TARIFA`,`fza_tarifas`.`ACTIVO_TARIFA` AS `ACTIVO_TARIFA`,`fza_tarifas`.`ORDEN_TARIFA` AS `ORDEN_TARIFA`,`fza_tarifas`.`ESIMP_INCL_TARIFA` AS `ESIMP_INCL_TARIFA`,`fza_tarifas`.`ESDEFAULT_TARIFA` AS `ESDEFAULT_TARIFA`,`fza_tarifas`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_tarifas`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_tarifas`.`USUARIOALTA` AS `USUARIOALTA`,`fza_tarifas`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_tarifas` where (`fza_tarifas`.`ACTIVO_TARIFA` = 'S') order by `fza_tarifas`.`ORDEN_TARIFA` ;

-- ----------------------------
-- View structure for vi_usuarios
-- ----------------------------
DROP VIEW IF EXISTS `vi_usuarios`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_usuarios` AS SELECT
  `fza_usuarios`.*,
  `vi_empresas`.`RAZONSOCIAL_EMPRESA` AS `RAZONSOCIAL_EMPRESA`,
  `fza_usuarios_grupos`.`GRUPO_GRUPO` AS `GRUPO_GRUPO`,
  `fza_usuarios_grupos`.`ESGRUPOADMINISTRADOR_GRUPO` AS `ESGRUPOADMINISTRADOR_GRUPO`
FROM
  ((
  `fza_usuarios`
  JOIN `fza_usuarios_grupos` ON (
  `fza_usuarios`.`GRUPO_USUARIO` = `fza_usuarios_grupos`.`GRUPO_GRUPO`
  ))
  LEFT JOIN `vi_empresas` ON (
  `fza_usuarios`.`EMPRESADEF_USUARIO` = `vi_empresas`.`CODIGO_EMPRESA`
  )) ;

-- ----------------------------
-- View structure for vi_usuarios_grupos
-- ----------------------------
DROP VIEW IF EXISTS `vi_usuarios_grupos`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_usuarios_grupos` AS select `fza_usuarios_grupos`.`GRUPO_GRUPO` AS `GRUPO_GRUPO`,`fza_usuarios_grupos`.`ESGRUPOADMINISTRADOR_GRUPO` AS `ESGRUPOADMINISTRADOR_GRUPO`,`fza_usuarios_grupos`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_usuarios_grupos`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_usuarios_grupos`.`USUARIOALTA` AS `USUARIOALTA`,`fza_usuarios_grupos`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_usuarios_grupos` ;

-- ----------------------------
-- View structure for vi_usuarios_perfiles
-- ----------------------------
DROP VIEW IF EXISTS `vi_usuarios_perfiles`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vi_usuarios_perfiles` AS select `fza_usuarios_perfiles`.`USUARIO_GRUPO_PERFILES` AS `USUARIO_GRUPO_PERFILES`,`fza_usuarios_perfiles`.`KEY_PERFILES` AS `KEY_PERFILES`,`fza_usuarios_perfiles`.`SUBKEY_PERFILES` AS `SUBKEY_PERFILES`,`fza_usuarios_perfiles`.`VALUE_PERFILES` AS `VALUE_PERFILES`,`fza_usuarios_perfiles`.`VALUE_TEXT_PERFILES` AS `VALUE_TEXT_PERFILES`,`fza_usuarios_perfiles`.`TYPE_BLOB_PERFILES` AS `TYPE_BLOB_PERFILES`,`fza_usuarios_perfiles`.`VALUE_BLOB_PERFILES` AS `VALUE_BLOB_PERFILES`,`fza_usuarios_perfiles`.`INSTANTEMODIF` AS `INSTANTEMODIF`,`fza_usuarios_perfiles`.`INSTANTEALTA` AS `INSTANTEALTA`,`fza_usuarios_perfiles`.`USUARIOALTA` AS `USUARIOALTA`,`fza_usuarios_perfiles`.`USUARIOMODIF` AS `USUARIOMODIF` from `fza_usuarios_perfiles` ;

-- ----------------------------
-- Procedure structure for PRC_AGREGAR_VALOR_CONJUNTO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_AGREGAR_VALOR_CONJUNTO`;
delimiter ;;
CREATE PROCEDURE `PRC_AGREGAR_VALOR_CONJUNTO`(IN `p_id_conjunto` INT,         -- ID de la Paleta (ej: 5 para 'Verano 2026')
    IN `p_valor_texto` VARCHAR(100), -- Lo que escribió el usuario (ej: 'VERDE RADIOACTIVO')
    IN `p_usuario` VARCHAR(100))
BEGIN
    DECLARE v_id_valor INT;
    DECLARE v_tipo_variacion VARCHAR(20);
    
    -- 1. Averiguamos de qué tipo es esta paleta (¿Es de Colores CO o Tallas TC?)
    SELECT ID_VA_AC INTO v_tipo_variacion
    FROM fza_atributos_conjuntos
    WHERE ID_CONJUNTO_AC = p_id_conjunto;
    
    -- 2. Usamos el truco del "Find or Create" que vimos antes
    -- Esto busca el ID de 'VERDE RADIOACTIVO'. Si no existe, lo crea en fza_atributos_valores
    CALL PRC_GET_CREAR_VALOR(v_tipo_variacion, p_valor_texto, p_usuario, v_id_valor);
    
    -- 3. Ahora que SEGURO tenemos un ID (v_id_valor), lo vinculamos a la paleta
    -- Usamos INSERT IGNORE para que si ya estaba en la paleta, no de error
    INSERT IGNORE INTO fza_atributos_conjuntos_det (
        ID_CONJUNTO_ACD, 
        ID_VALOR_ACD, 
        USUARIOALTA, 
        USUARIOMODIF, 
        INSTANTEALTA
    ) VALUES (
        p_id_conjunto, 
        v_id_valor, 
        p_usuario, 
        p_usuario, 
        NOW()
    );
    
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_BUSQUEDA_ARTICULOS
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_BUSQUEDA_ARTICULOS`;
delimiter ;;
CREATE PROCEDURE `PRC_BUSQUEDA_ARTICULOS`(IN p_tarifa     VARCHAR(10),
    IN p_almacen    VARCHAR(10),
    IN p_fecha      DATE,
    IN p_token      VARCHAR(100),
    IN p_solostock  TINYINT,
    IN p_solotarifa TINYINT)
BEGIN
    IF p_tarifa IS NULL OR TRIM(p_tarifa) = '' THEN
        SET p_tarifa := 'PVP';
    END IF;
    IF p_fecha IS NULL THEN
        SET p_fecha := CURDATE();
    END IF;

    SELECT
        v.*,
        COALESCE(stk.STOCK_DISPONIBLE, 0) AS STOCK_DISPONIBLE
    FROM vi_art_busquedas v

    -- Stock unificado: por SKU + por código directo
    LEFT JOIN (
        SELECT COD_ART, SUM(STOCK) AS STOCK_DISPONIBLE
        FROM (
            -- Artículos CON SKU: sumar por artículo padre
            SELECT sku.CODIGO_ARTICULO_SKU AS COD_ART,
                   s.CANTIDAD_STK          AS STOCK
              FROM fza_articulos_stockactual s
              JOIN fza_articulos_skus sku
                ON s.CODIGO_UNIDAD_STK = sku.CODIGO_UNIDAD_SKU
             WHERE s.CODIGO_ALMACEN_STK = p_almacen
            UNION ALL
            -- Artículos SIN SKU: código directo no existe en fza_articulos_skus
            SELECT s.CODIGO_UNIDAD_STK AS COD_ART,
                   s.CANTIDAD_STK      AS STOCK
              FROM fza_articulos_stockactual s
             WHERE s.CODIGO_ALMACEN_STK = p_almacen
               AND NOT EXISTS (
                   SELECT 1 FROM fza_articulos_skus sku2
                    WHERE sku2.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK
               )
        ) t
        GROUP BY COD_ART
    ) stk ON v.CODIGO_ARTICULO = stk.COD_ART

    WHERE (v.CODIGO_TARIFA = p_tarifa OR v.CODIGO_TARIFA IS NULL)
      AND v.FECHA_DESDE_TARIFA <= p_fecha
      AND (v.FECHA_HASTA_TARIFA IS NULL OR v.FECHA_HASTA_TARIFA >= p_fecha)
      AND (p_token IS NULL OR p_token = ''
           OR v.CODIGO_ARTICULO      LIKE p_token
           OR v.DESCRIPCION_ARTICULO LIKE p_token
           OR v.DESCRIPCION_FAMILIA  LIKE p_token)
      AND (p_solostock  = 0 OR COALESCE(stk.STOCK_DISPONIBLE, 0) > 0)
      AND (p_solotarifa = 0 OR v.CODIGO_TARIFA IS NOT NULL)

    ORDER BY v.CODIGO_ARTICULO;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CALCULAR_FACTURA_NETOS
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CALCULAR_FACTURA_NETOS`;
delimiter ;;
CREATE PROCEDURE `PRC_CALCULAR_FACTURA_NETOS`(IN `pSERIE_FACTURA` VARCHAR(12), 
  IN `pNRO_FACTURA` VARCHAR(12))
BEGIN
  DECLARE pPRECIOSIVA decimal(19,6);
  DECLARE pPRECIOCIVA decimal(19,6);
  DECLARE pPORCEN decimal(19,6);
  DECLARE pTIPO VARCHAR(2);
  DECLARE pZONAIVA_RE varchar(1) DEFAULT '';          -- CAMBIADO
  DECLARE pAPLICA_RE_CLIENTE varchar(1) DEFAULT '';   -- CAMBIADO
  DECLARE pIVA_EXENTO varchar(1) DEFAULT '';
  DECLARE pREG_AG_EMP varchar(1) DEFAULT '';
  DECLARE pREG_AG_CLI varchar(1) DEFAULT '';
  DECLARE pINTRACOMUNITARIO varchar(1) DEFAULT '';
  DECLARE pAPLICA_RETENCIONES_CLI varchar(1) DEFAULT '';
  DECLARE pAPLICA_RETENCIONES_EMP varchar(1) DEFAULT '';
  DECLARE pPORCENREN decimal(19,6) DEFAULT 0;
  DECLARE pPORCENRER decimal(19,6) DEFAULT 0;
  DECLARE pPORCENRES decimal(19,6) DEFAULT 0;
  DECLARE pPORCENREE decimal(19,6) DEFAULT 0;
  DECLARE pSUMBASEN decimal(19,6) DEFAULT 0;
  DECLARE pSUMBASER decimal(19,6) DEFAULT 0;
  DECLARE pSUMBASES decimal(19,6) DEFAULT 0;
  DECLARE pSUMBASEE decimal(19,6) DEFAULT 0;
  DECLARE pTOTN decimal(19,6) DEFAULT 0;
  DECLARE pTOTR decimal(19,6) DEFAULT 0;
  DECLARE pTOTS decimal(19,6) DEFAULT 0;
  DECLARE pTOTE decimal(19,6) DEFAULT 0;
  DECLARE pTOTRECN decimal(19,6) DEFAULT 0;
  DECLARE pTOTRECR decimal(19,6) DEFAULT 0;
  DECLARE pTOTRECS decimal(19,6) DEFAULT 0;
  DECLARE pTOTRECE decimal(19,6) DEFAULT 0;
  DECLARE pSUMTOTREC decimal(19,6) DEFAULT 0;
  DECLARE pSUMTOT decimal(19,6) DEFAULT 0;
  DECLARE pPORCENN decimal(19,6) DEFAULT 0;
  DECLARE pTOTBASES decimal(19,6) DEFAULT 0;
  DECLARE pPORCENR decimal(19,6) DEFAULT 0;
  DECLARE pPORCENS decimal(19,6) DEFAULT 0;
  DECLARE pPORCENE decimal(19,6) DEFAULT 0;
  DECLARE pPORCENRET decimal(19,6) DEFAULT 0;
  DECLARE pGRUPO_ZONA_IVA varchar(12);
  DECLARE pCODIGO_IVA varchar(12);
  DECLARE pTOTALRET decimal(19,6) DEFAULT 0;
  DECLARE pFECHA datetime;
  DECLARE pLINEA varchar(3);
  DECLARE pIMP_INCL varchar(1);
  DECLARE pCANTIDAD decimal(19,6) DEFAULT 0;
  DECLARE pCODART varchar(20);
  DECLARE pTIPOIVAF varchar(1) DEFAULT 'X';
  DECLARE pIRPF_IMP_INCL VARCHAR(1);
  DECLARE pVENTA_ACT_FIJ VARCHAR(1);
  DECLARE finished INTEGER DEFAULT 0;
  DECLARE pCODEMPRESA varchar(8);
  
  DECLARE CUR_LINEAS 
          CURSOR FOR 
              SELECT LINEA_FACTURA_LINEA,
                     CODIGO_ARTICULO_FACTURA_LINEA,
                     PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA AS PRECIOSIVA,
                     PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA AS PRECIOCIVA,
                     PORCEN_IVA_FACTURA_LINEA AS PORCEN,
                     TIPOIVA_ARTICULO_FACTURA_LINEA AS TIPO,
                     ESIMP_INCL_TARIFA_FACTURA_LINEA AS IMP_INCL,
                     CANTIDAD_FACTURA_LINEA as CANTIDAD
                FROM FZA_FACTURAS_LINEAS 
               WHERE SERIE_FACTURA_LINEA = pSERIE_FACTURA 
                 AND NRO_FACTURA_LINEA = pNRO_FACTURA;
                 
  DECLARE CONTINUE HANDLER 
          FOR NOT FOUND SET finished = 1;
          
  START TRANSACTION;
  
  SELECT PORCEN_IVAN_FACTURA,
         PORCEN_IVAR_FACTURA,
         PORCEN_IVAS_FACTURA,
         PORCEN_IVAE_FACTURA,
         PORCEN_RETENCION_FACTURA,
         ESAPLICA_RE_ZONA_IVA_FACTURA,
         ESIVA_RECARGO_CLIENTE_FACTURA,
         ESIVA_EXENTO_CLIENTE_FACTURA,
         ESRETENCIONES_CLIENTE_FACTURA,
         ESRETENCIONES_EMPRESA_FACTURA,
         ESIRPF_IMP_INCL_ZONA_IVA_FACTURA,
         PORCEN_REN_FACTURA,
         PORCEN_RER_FACTURA,
         PORCEN_RES_FACTURA,
         PORCEN_REE_FACTURA,
         ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA,
         ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA,
         GRUPO_ZONA_IVA_EMPRESA_FACTURA,
         CODIGO_IVA_FACTURA,
         ESINTRACOMUNITARIO_CLIENTE_FACTURA,
         FECHA_FACTURA,
         CODIGO_EMPRESA_FACTURA,
         ESVENTA_ACTIVO_FIJO_FACTURA
    INTO pPORCENN,
         pPORCENR,
         pPORCENS,
         pPORCENE,
         pPORCENRET,
         pZONAIVA_RE,              -- CAMBIADO
         pAPLICA_RE_CLIENTE,       -- CAMBIADO
         pIVA_EXENTO,
         pAPLICA_RETENCIONES_CLI,
         pAPLICA_RETENCIONES_EMP,
         pIRPF_IMP_INCL,
         pPORCENREN,
         pPORCENRER,
         pPORCENRES,
         pPORCENREE,
         pREG_AG_EMP,
         pREG_AG_CLI,
         pGRUPO_ZONA_IVA,
         pCODIGO_IVA,
         pINTRACOMUNITARIO,
         pFECHA,
         pCODEMPRESA,
         pVENTA_ACT_FIJ
    FROM fza_facturas
   WHERE SERIE_FACTURA = pSERIE_FACTURA
     AND NRO_FACTURA = pNRO_FACTURA;
     
  -- Resto de la lógica igual hasta el cálculo de recargos...
  
  -- CAMBIO EN LA CONDICIÓN DE RECARGOS:
  IF ( (pZONAIVA_RE ='S') AND (pAPLICA_RE_CLIENTE = 'S') ) THEN
    SET pTOTRECN = pSUMBASEN * (1 + pPORCENREN/100) - pSUMBASEN;
    SET pTOTRECR = pSUMBASER * (1 + pPORCENRER/100) - pSUMBASER;
    SET pTOTRECS = pSUMBASES * (1 + pPORCENRES/100) - pSUMBASES;
    SET pTOTRECE = pSUMBASEE * (1 + pPORCENREE/100) - pSUMBASEE;
    SET pSUMTOTREC = pTOTRECN + pTOTRECR + pTOTRECS + pTOTRECE;
  ELSE 
    SET pTOTRECN = 0;
    SET pTOTRECR = 0;
    SET pTOTRECS = 0;
    SET pTOTRECE = 0;
    SET pSUMTOTREC = 0;
  END IF;
  
  -- ... resto de código ...
  
  -- CAMBIO EN EL UPDATE FINAL:
  UPDATE fza_facturas 
     SET TOTAL_BASEI_IVAN_FACTURA = pSUMBASEN,
         TOTAL_BASEI_IVAR_FACTURA = pSUMBASER,
         TOTAL_BASEI_IVAS_FACTURA = pSUMBASES,
         TOTAL_BASEI_IVAE_FACTURA = pSUMBASEE,
         TOTAL_IVAN_FACTURA = pTOTN,
         TOTAL_IVAR_FACTURA = pTOTR,
         TOTAL_IVAS_FACTURA = pTOTS,
         TOTAL_IVAE_FACTURA = pTOTE,
         TOTAL_REN_FACTURA = PTOTRECN,
         TOTAL_RER_FACTURA = PTOTRECR,
         TOTAL_RES_FACTURA = PTOTRECS,
         TOTAL_REE_FACTURA = PTOTRECE,
         TOTAL_BASES_FACTURA = pTOTBASES,
         TOTAL_RETENCION_FACTURA = pTOTALRET,
         TOTAL_LIQUIDO_FACTURA = pTOTBASES + pSUMTOT - PTOTALRET + pSUMTOTREC,
         ESIVA_EXENTO_CLIENTE_FACTURA = pIVA_EXENTO,
         ESRETENCIONES_CLIENTE_FACTURA = pAPLICA_RETENCIONES_CLI,
         ESRETENCIONES_EMPRESA_FACTURA = pAPLICA_RETENCIONES_EMP,
         -- NO ACTUALIZAR: ESIVA_RECARGO_CLIENTE_FACTURA
         TOTAL_IMPUESTOS_FACTURA = pSUMTOTREC + pSUMTOT,
         GRUPO_ZONA_IVA_EMPRESA_FACTURA = pGRUPO_ZONA_IVA,
         CODIGO_IVA_FACTURA = pCODIGO_IVA,
         PORCEN_IVAN_FACTURA = pPORCENN,
         PORCEN_IVAE_FACTURA = pPORCENE,
         PORCEN_IVAR_FACTURA = pPORCENR,
         PORCEN_IVAS_FACTURA = pPORCENS,
         PORCEN_RETENCION_FACTURA = pPORCENRET
   WHERE NRO_FACTURA = pNRO_FACTURA 
     AND SERIE_FACTURA = pSERIE_FACTURA;
     
  COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_ARTICULO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_ARTICULO`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_ARTICULO`(IN pCODIGO_ARTICULO 									varchar(20),
																																						IN pDESCRIPCION_ARTICULO							varchar(1000),
																																						IN pTIPOIVA_ARTICULO                  varchar(2),
																																						IN pTIPO_CANTIDAD_ARTICULO            varchar(20),
																																						IN pESACTIVO_FIJO_ARTICULO            varchar(1),
																																						                    
																																						IN pCODIGO_FAMILIA                    varchar(20),
																																						IN pNOMBRE_FAMILIA                    varchar(200),
																																						
																																						IN pCODIGO_PROVEEDOR                  varchar(20),
																																						IN pRAZONSOCIAL_PROVEEDOR             varchar(200),
																																						IN pESPROVEEDORPRINCIPAL              varchar(1),
																																						IN pPRECIO_ULT_COMPRA                 decimal(19,6),
																																						
																																						IN pCODIGO_TARIFA                     varchar(20),
																																						IN pPRECIOSALIDA_TARIFA								decimal(19,6),
																																						IN pPRECIOFINAL_TARIFA  							decimal(19,6),
																																						IN pPRECIO_DTO_TARIFA		  						decimal(19,6),
																																						IN pPORCEN_DTO_TARIFA			  					decimal(19,6),
																																						
																																						IN `pUSUARIO`                         varchar(100))
BEGIN
DECLARE pCONT BIGINT;
START TRANSACTION;


IF (TRIM(pCODIGO_ARTICULO) <> '') THEN
BEGIN
	IF( EXISTS( SELECT *
								 FROM fza_articulos
								WHERE `CODIGO_ARTICULO` =  pCODIGO_ARTICULO) ) THEN
	 BEGIN
		 UPDATE fza_articulos
				SET 
						DESCRIPCION_ARTICULO              = pDESCRIPCION_ARTICULO   ,
						ESACTIVO_FIJO_ARTICULO            = pESACTIVO_FIJO_ARTICULO,
						TIPOIVA_ARTICULO                  = pTIPOIVA_ARTICULO       ,
						TIPO_CANTIDAD_ARTICULO            = pTIPO_CANTIDAD_ARTICULO ,
						CODIGO_FAMILIA_ARTICULO           = pCODIGO_FAMILIA         ,
						USUARIOMODIF                      = pUSUARIO                ,
						INSTANTEMODIF                     = CURRENT_TIMESTAMP 
			WHERE CODIGO_ARTICULO = pCODIGO_ARTICULO;
		END;
		ELSE
		BEGIN
		  CALL PRC_FNC_GET_NEXT_NRO_DOC('AO', pCONT);
			INSERT INTO fza_articulos (CODIGO_ARTICULO                  ,
														    ORDEN_ARTICULO                    ,		
																DESCRIPCION_ARTICULO              ,
																TIPOIVA_ARTICULO                  ,
																TIPO_CANTIDAD_ARTICULO            ,
																CODIGO_FAMILIA_ARTICULO           ,
																ESACTIVO_FIJO_ARTICULO            ,
																USUARIOMODIF                      ,
																INSTANTEMODIF                     ,
																USUARIOALTA                       ,
																INSTANTEALTA                      
												) VALUES
															 (pCODIGO_ARTICULO                  ,														 
															  pCONT                             ,
																pDESCRIPCION_ARTICULO             , 
																pTIPOIVA_ARTICULO                 ,
																pTIPO_CANTIDAD_ARTICULO           ,
																pCODIGO_FAMILIA                   ,
																pESACTIVO_FIJO_ARTICULO           ,
																pUSUARIO                          ,
																CURRENT_TIMESTAMP			            ,
																pUSUARIO                          ,
																CURRENT_TIMESTAMP			 
																);
		END;
		END IF;
		CALL PRC_CREAR_ACTUALIZAR_FAMILIA(pCODIGO_FAMILIA, pNOMBRE_FAMILIA, pUSUARIO);
		CALL PRC_CREAR_ACTUALIZAR_PROVEEDOR(pCODIGO_PROVEEDOR, pRAZONSOCIAL_PROVEEDOR, pUSUARIO);
		CALL PRC_CREAR_ACTUALIZAR_ARTICULO_PROVEEDOR(pCODIGO_ARTICULO, pCODIGO_PROVEEDOR, pESPROVEEDORPRINCIPAL, pPRECIO_ULT_COMPRA, pUSUARIO);
		CALL PRC_CREAR_ACTUALIZAR_TARIFA(pCODIGO_ARTICULO, pCODIGO_TARIFA, pPRECIOSALIDA_TARIFA, pPRECIOFINAL_TARIFA, pPRECIO_DTO_TARIFA, pPORCEN_DTO_TARIFA, pUSUARIO);
END;
END IF;	
  COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_ARTICULO_PROVEEDOR
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_ARTICULO_PROVEEDOR`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_ARTICULO_PROVEEDOR`(IN pCODIGO_ARTICULO 									varchar(20),
                                                    IN pCODIGO_PROVEEDOR                  varchar(20),
																										IN pESPROVEEDORPRINCIPAL               varchar(1),
																									  IN pPRECIO_ULT_COMPRA                  decimal(19,6),
																										
																										IN `pUSUARIO`                         varchar(100))
BEGIN
START TRANSACTION;
IF ((TRIM(pCODIGO_PROVEEDOR) <> '') AND 
    (TRIM(pCODIGO_ARTICULO) <> '')) THEN
BEGIN
	 IF( EXISTS( SELECT *
								 FROM fza_articulos_proveedores
								WHERE `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` =  pCODIGO_PROVEEDOR
								  AND CODIGO_ARTICULO_ARTICULO_PROVEEDOR = pCODIGO_ARTICULO )) THEN
	 BEGIN
		 UPDATE fza_articulos_proveedores
				SET 
						PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR     = pPRECIO_ULT_COMPRA   ,
						ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR = pESPROVEEDORPRINCIPAL ,
						USUARIOMODIF              = pUSUARIO                            ,
						INSTANTEMODIF             = CURRENT_TIMESTAMP			 
				WHERE `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` =  pCODIGO_PROVEEDOR
				  AND CODIGO_ARTICULO_ARTICULO_PROVEEDOR = pCODIGO_ARTICULO;
		END;
		ELSE
		BEGIN
			INSERT INTO fza_articulos_proveedores (  CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR , 
			                                         CODIGO_ARTICULO_ARTICULO_PROVEEDOR  ,  				
																							 PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR,
																							 ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR,																 
																				  
																					USUARIOMODIF                     ,
																					INSTANTEMODIF                    ,
																					USUARIOALTA                      ,
																          INSTANTEALTA                      
												                 ) VALUES
																				(pCODIGO_PROVEEDOR                   ,
																				 pCODIGO_ARTICULO                    ,
																				 pPRECIO_ULT_COMPRA             ,		
																				 pESPROVEEDORPRINCIPAL           ,																			
																				 pUSUARIO                         ,
																				 CURRENT_TIMESTAMP			             ,
																				 pUSUARIO                         ,
																				 CURRENT_TIMESTAMP			 
																					);
		END;
		END IF;
END;
END IF;		
COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_CLIENTE
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_CLIENTE`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_CLIENTE`(IN `pCODIGO_CLIENTE`                       varchar(20),
                            IN `pRAZONSOCIAL_CLIENTE`             varchar(200),
                            IN `pNIF_CLIENTE`                      varchar(50),
                            IN `pMOVIL_CLIENTE`                    varchar(40),
                            IN `pEMAIL_CLIENTE`                   varchar(200),
                            IN `pDIRECCION1_CLIENTE`              varchar(200),
                            IN `pDIRECCION2_CLIENTE`              varchar(200),
                            IN `pPOBLACION_CLIENTE`               varchar(200),
                            IN `pPROVINCIA_CLIENTE`               varchar(200),
                            IN `pCPOSTAL_CLIENTE`                  varchar(15),
														IN `pCOD_PAIS_CLIENTE`								 varchar(3),
                            IN `pPAIS_CLIENTE`                    varchar(150),
                            IN `pESIVA_EXENTO_CLIENTE`              varchar(1),
                            IN `pESRETENCIONES_CLIENTE`             varchar(1),
                            IN `pESIVA_RECARGO_CLIENTE`             varchar(1),
                            IN `pESINTRACOMUNITARIO_CLIENTE`        varchar(1),
                            IN `pESREGIMENESPECIALAGRICOLA_CLIENTE` varchar(1),
                            IN `pTARIFA_ARTICULO_CLIENTE`          varchar(20),
                            IN `pUSUARIO`                         varchar(100))
BEGIN
START TRANSACTION;
 IF( EXISTS( SELECT *
               FROM fza_clientes
              WHERE `CODIGO_CLIENTE` =  pCODIGO_CLIENTE) ) THEN
 BEGIN
   UPDATE fza_clientes
      SET RAZONSOCIAL_CLIENTE               = pRAZONSOCIAL_CLIENTE ,
          NIF_CLIENTE                       = pNIF_CLIENTE         ,
          MOVIL_CLIENTE                     = pMOVIL_CLIENTE       ,
          EMAIL_CLIENTE                     = pEMAIL_CLIENTE       ,
          DIRECCION1_CLIENTE                = pDIRECCION1_CLIENTE  ,
          DIRECCION2_CLIENTE                = pDIRECCION2_CLIENTE  ,
          POBLACION_CLIENTE                 = pPOBLACION_CLIENTE   ,
          PROVINCIA_CLIENTE                 = pPROVINCIA_CLIENTE   ,
          CPOSTAL_CLIENTE                   = pCPOSTAL_CLIENTE     ,
          NOMBRE_PAIS_CLIENTE               = pPAIS_CLIENTE        ,
					CODIGO_PAIS_CLIENTE               = pCOD_PAIS_CLIENTE    ,
          ESIVA_EXENTO_CLIENTE              = pESIVA_EXENTO_CLIENTE  ,
          ESRETENCIONES_CLIENTE             = pESRETENCIONES_CLIENTE ,
          ESIVA_RECARGO_CLIENTE             = pESIVA_RECARGO_CLIENTE ,
          ESREGIMENESPECIALAGRICOLA_CLIENTE = pESREGIMENESPECIALAGRICOLA_CLIENTE,
          ESINTRACOMUNITARIO_CLIENTE        = pESINTRACOMUNITARIO_CLIENTE,
          TARIFA_ARTICULO_CLIENTE           = pTARIFA_ARTICULO_CLIENTE,
          USUARIOMODIF                      = pUSUARIO,
				  INSTANTEMODIF                     = CURRENT_TIMESTAMP
    WHERE CODIGO_cliente = pCODIGO_CLIENTE;
  END;
  ELSE
  BEGIN
    INSERT INTO fza_clientes (CODIGO_CLIENTE                    ,
                              RAZONSOCIAL_CLIENTE               ,
                              NIF_CLIENTE                       ,
                              MOVIL_CLIENTE                     ,
                              EMAIL_CLIENTE                     ,
                              DIRECCION1_CLIENTE                ,
                              DIRECCION2_CLIENTE                ,
                              POBLACION_CLIENTE                 ,
                              PROVINCIA_CLIENTE                 ,
                              CPOSTAL_CLIENTE                   ,
                              NOMBRE_PAIS_CLIENTE               ,
															CODIGO_PAIS_CLIENTE               ,
                              ESIVA_EXENTO_CLIENTE              ,
                              ESRETENCIONES_CLIENTE             ,
                              ESIVA_RECARGO_CLIENTE             ,
                              ESREGIMENESPECIALAGRICOLA_CLIENTE ,
                              ESINTRACOMUNITARIO_CLIENTE        ,
                              TARIFA_ARTICULO_CLIENTE           ,
                              USUARIOMODIF                      ,
                              USUARIOALTA                       ,
                              INSTANTEALTA                      ,
                              INSTANTEMODIF
                      ) VALUES
                             (pCODIGO_CLIENTE                   ,
                              pRAZONSOCIAL_CLIENTE              ,
                              pNIF_CLIENTE                      ,
                              pMOVIL_CLIENTE                    ,
                              pEMAIL_CLIENTE                    ,
                              pDIRECCION1_CLIENTE               ,
                              pDIRECCION2_CLIENTE               ,
                              pPOBLACION_CLIENTE                ,
                              pPROVINCIA_CLIENTE                ,
                              pCPOSTAL_CLIENTE                  ,
                              pPAIS_CLIENTE                     ,
															pCOD_PAIS_CLIENTE                 ,
                              pESIVA_EXENTO_CLIENTE             ,
                              pESRETENCIONES_CLIENTE            ,
                              pESIVA_RECARGO_CLIENTE            ,
                              pESREGIMENESPECIALAGRICOLA_CLIENTE,
                              pESINTRACOMUNITARIO_CLIENTE       ,
                              pTARIFA_ARTICULO_CLIENTE          ,
                              pUSUARIO                          ,
                              pUSUARIO                          ,
                              CURRENT_TIMESTAMP                 ,
                              CURRENT_TIMESTAMP           
                              );
  END;
  END IF;
  COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_EMPRESA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_EMPRESA`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_EMPRESA`(IN `pCODIGO_EMPRESA`                varchar(10), 
																																					 IN `pRAZONSOCIAL_EMPRESA`           varchar(200),
																																					 IN `pNIF_EMPRESA`                   varchar(50),
																																					 IN `pMOVIL_EMPRESA`                 varchar(40),
																																					 IN `pEMAIL_EMPRESA`                 varchar(200),
																																					 IN `pDIRECCION1_EMPRESA`            varchar(200),
																																					 IN `pDIRECCION2_EMPRESA`            varchar(200),
																																					 IN `pPOBLACION_EMPRESA`             varchar(200),
																																					 IN `pPROVINCIA_EMPRESA`             varchar(200),
																																					 IN `pCPOSTAL_EMPRESA`               varchar(15),
																																					 IN `pPAIS_EMPRESA`                  varchar(150),
																																					 IN `pCODPAIS_EMPRESA`               varchar(150),
																																					 IN `pRETENCIONES_EMPRESA`           varchar(1),
																																					 IN `pIVA_RECARGO_EMPRESA`           varchar(1),
																																					 IN `pREGIMENESPECIALAGRICOLA_EMPRESA` varchar(1),
																																					 IN `pGRUPO_ZONA_IVA_EMPRESA`        varchar(10),
																																					 IN `pUSUARIO`                       varchar(100))
BEGIN
START TRANSACTION;
 IF( EXISTS(
             SELECT *
             FROM fza_empresas
             WHERE `CODIGO_EMPRESA` =  pCODIGO_EMPRESA) ) THEN
  UPDATE fza_EMPRESAs
    SET  RAZONSOCIAL_EMPRESA               = pRAZONSOCIAL_EMPRESA            ,
         NIF_EMPRESA                       = pNIF_EMPRESA                    ,
         MOVIL_EMPRESA                     = pMOVIL_EMPRESA                  ,
         EMAIL_EMPRESA                     = pEMAIL_EMPRESA                  ,
         DIRECCION1_EMPRESA                = pDIRECCION1_EMPRESA             ,
         DIRECCION2_EMPRESA                = pDIRECCION2_EMPRESA             ,
         POBLACION_EMPRESA                 = pPOBLACION_EMPRESA              ,
         PROVINCIA_EMPRESA                 = pPROVINCIA_EMPRESA              ,
         CPOSTAL_EMPRESA                   = pCPOSTAL_EMPRESA                ,
         NOMBRE_PAIS_EMPRESA                      = pPAIS_EMPRESA            ,
				 CODIGO_PAIS_EMPRESA							 = pCODPAIS_EMPRESA                ,
         ESRETENCIONES_EMPRESA             = pRETENCIONES_EMPRESA            ,
         ESREGIMENESPECIALAGRICOLA_EMPRESA = pREGIMENESPECIALAGRICOLA_EMPRESA,
         GRUPO_ZONA_IVA_EMPRESA            = pGRUPO_ZONA_IVA_EMPRESA,
         USUARIOMODIF                      = pUSUARIO,
			   INSTANTEMODIF                     = CURRENT_TIMESTAMP			
  WHERE CODIGO_EMPRESA = pCODIGO_EMPRESA;
  ELSE
  INSERT INTO fza_EMPRESAs (CODIGO_EMPRESA                    ,
                            RAZONSOCIAL_EMPRESA               ,
                            NIF_EMPRESA                       ,
                            MOVIL_EMPRESA                     ,
                            EMAIL_EMPRESA                     ,
                            DIRECCION1_EMPRESA                ,
                            DIRECCION2_EMPRESA                ,
                            POBLACION_EMPRESA                 ,
                            PROVINCIA_EMPRESA                 ,
                            CPOSTAL_EMPRESA                   ,
                            NOMBRE_PAIS_EMPRESA               ,
														CODIGO_PAIS_EMPRESA               ,
                            ESRETENCIONES_EMPRESA             ,
                            ESREGIMENESPECIALAGRICOLA_EMPRESA ,
                            GRUPO_ZONA_IVA_EMPRESA            ,
                            USUARIOMODIF                      ,
                            USUARIOALTA                       ,
                            INSTANTEALTA                      ,
													  INSTANTEMODIF		
                    ) VALUES
                           (pCODIGO_EMPRESA      ,
                            pRAZONSOCIAL_EMPRESA ,
                            pNIF_EMPRESA         ,
                            pMOVIL_EMPRESA       ,
                            pEMAIL_EMPRESA       ,
                            pDIRECCION1_EMPRESA  ,
                            pDIRECCION2_EMPRESA  ,
                            pPOBLACION_EMPRESA   ,
                            pPROVINCIA_EMPRESA   ,
                            pCPOSTAL_EMPRESA     ,
                            pPAIS_EMPRESA        ,
														pCODPAIS_EMPRESA     ,
                            pRETENCIONES_EMPRESA ,
                            pREGIMENESPECIALAGRICOLA_EMPRESA,
                            pGRUPO_ZONA_IVA_EMPRESA,
                            pUSUARIO             ,
                            pUSUARIO             ,
                            CURRENT_TIMESTAMP,
											      CURRENT_TIMESTAMP						
                            );
  END IF;
  COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_FAMILIA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_FAMILIA`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_FAMILIA`(IN pCODIGO_FAMILIA                     varchar(20),
																																						IN pNOMBRE_FAMILIA                    varchar(200),
																																					
																																						IN `pUSUARIO`                         varchar(100))
BEGIN
DECLARE pCONT BIGINT;
START TRANSACTION;
IF (TRIM(pCODIGO_FAMILIA) <> '') THEN
BEGIN
	 IF( EXISTS( SELECT *
								 FROM fza_articulos_familias
								WHERE `CODIGO_FAMILIA` =  pCODIGO_FAMILIA) ) THEN
	 BEGIN
		 UPDATE fza_articulos_familias
				SET 
						NOMBRE_FAMILIA                    = pNOMBRE_FAMILIA   ,
						DESCRIPCION_FAMILIA               = pNOMBRE_FAMILIA       ,
						USUARIOMODIF                      = pUSUARIO                ,
						INSTANTEMODIF                     = CURRENT_TIMESTAMP			 
			WHERE CODIGO_FAMILIA = pCODIGO_FAMILIA;
		END;
		ELSE
		BEGIN
			CALL PRC_FNC_GET_NEXT_NRO_DOC('FO', pCONT);
			INSERT INTO fza_articulos_familias (CODIGO_FAMILIA                   ,
																					ORDEN_FAMILIA                    ,
																				  NOMBRE_FAMILIA                   ,
                                          DESCRIPCION_FAMILIA              ,
																					USUARIOMODIF                     ,
																					INSTANTEMODIF                    ,
																					USUARIOALTA                      ,
																          INSTANTEALTA                      
												                 ) VALUES
																				(pCODIGO_FAMILIA                   ,
																				 pCONT                             ,
																				 pNOMBRE_FAMILIA                    ,
																				 pNOMBRE_FAMILIA                    ,
																				 pUSUARIO                         ,
																				 CURRENT_TIMESTAMP			             ,
																				 pUSUARIO                         ,
																				 CURRENT_TIMESTAMP			 
																					);
		END;
		END IF;
END;
END IF;		
COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_KEY
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_KEY`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_KEY`(IN `pUSUARIO`       varchar(200),
                                              IN `pKEY`           varchar(100),
                                              IN `pSUBKEY`        varchar(100),
                                              IN `pVALUE`         varchar(200),
                                              IN `pVALUE_TEXT`    text,
                                              IN `pUSUARIO_MODIF` varchar(100))
BEGIN
START TRANSACTION;
 IF( EXISTS(
             SELECT *
               FROM `fza_usuarios_perfiles`
              WHERE `USUARIO_GRUPO_PERFILES` = `pUSUARIO`
                AND `KEY_PERFILES`           = `pKEY` 
                AND `SUBKEY_PERFILES`        = `pSUBKEY` )) THEN
  BEGIN
    UPDATE `fza_usuarios_perfiles`
      SET `VALUE_PERFILES`      = `pVALUE`,
          `VALUE_TEXT_PERFILES` = `pVALUE_TEXT`,
          `USUARIOMODIF`        = `pUSUARIO_MODIF`
    WHERE `USUARIO_GRUPO_PERFILES` = `pUSUARIO`
      AND `KEY_PERFILES`           = `pKEY` 
      AND `SUBKEY_PERFILES`        = `pSUBKEY`;
  END;
  ELSE
  BEGIN
    INSERT INTO fza_usuarios_perfiles (`USUARIO_GRUPO_PERFILES`, 
                                       `KEY_PERFILES`          , 
                                       `SUBKEY_PERFILES`       , 
                                       `VALUE_PERFILES`        , 
                                       `VALUE_TEXT_PERFILES`   , 
                                       `INSTANTEALTA`          , 
                                       `USUARIOALTA`           , 
                                       `USUARIOMODIF`
                                      ) VALUES
                             (`pUSUARIO`         ,
                              `pKEY`             ,
                              `pSUBKEY`          ,
                              `pVALUE`           ,
                              `pVALUE_TEXT`      ,
                              CURRENT_TIMESTAMP  ,
                              `pUSUARIO_MODIF`   ,
                              `pUSUARIO_MODIF`
                             );
  END;
  END IF;
  COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_PROVEEDOR
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_PROVEEDOR`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_PROVEEDOR`(IN pCODIGO_PROVEEDOR                  varchar(20),
																										IN pRAZONSOCIAL_PROVEEDOR             varchar(200),
																									
																										IN `pUSUARIO`                         varchar(100))
BEGIN
DECLARE pCONT BIGINT;
START TRANSACTION;
IF (TRIM(pCODIGO_PROVEEDOR) <> '') THEN
BEGIN
	 IF( EXISTS( SELECT *
								 FROM fza_proveedores
								WHERE `CODIGO_PROVEEDOR` =  pCODIGO_PROVEEDOR) ) THEN
	 BEGIN
		 UPDATE fza_proveedores
				SET 
						RAZONSOCIAL_PROVEEDOR     = pRAZONSOCIAL_PROVEEDOR   ,
						USUARIOMODIF              = pUSUARIO                ,
						INSTANTEMODIF             = CURRENT_TIMESTAMP			 
			WHERE CODIGO_PROVEEDOR = pCODIGO_PROVEEDOR;
		END;
		ELSE
		BEGIN
			CALL PRC_FNC_GET_NEXT_NRO_DOC('PO', pCONT);
			INSERT INTO fza_proveedores (  CODIGO_PROVEEDOR                      ,
																					ORDEN_PROVEEDOR                  ,
																				  RAZONSOCIAL_PROVEEDOR            ,																				
																					USUARIOMODIF                     ,
																					INSTANTEMODIF                    ,
																					USUARIOALTA                      ,
																          INSTANTEALTA                      
												                 ) VALUES
																				(pCODIGO_PROVEEDOR                   ,
																				 pCONT                             ,
																				 pRAZONSOCIAL_PROVEEDOR             ,																				 
																				 pUSUARIO                         ,
																				 CURRENT_TIMESTAMP			             ,
																				 pUSUARIO                         ,
																				 CURRENT_TIMESTAMP			 
																					);
		END;
		END IF;
END;
END IF;		
COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_TARIFA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_TARIFA`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_TARIFA`(IN pCODIGO_ARTICULO                   varchar(20),
																										                        IN pCODIGO_TARIFA                     varchar(20),
																																						IN pPRECIOSALIDA_TARIFA								decimal(19,6),
																																						IN pPRECIOFINAL_TARIFA  							decimal(19,6),
																																						IN pPRECIO_DTO_TARIFA		  						decimal(19,6),
																																						IN pPORCEN_DTO_TARIFA			  					decimal(19,6),
																										                        IN `pUSUARIO`                         varchar(100))
BEGIN

DECLARE ppPRECIOSALIDA_TARIFA    decimal(19,6);
DECLARE	ppPRECIOFINAL_TARIFA     decimal(19,6);
DECLARE	ppPORCEN_DTO_TARIFA      decimal(19,6);
DECLARE	ppPRECIO_DTO_TARIFA      decimal(19,6);

START TRANSACTION;

IF (TRIM(pCODIGO_TARIFA) <> '') THEN
BEGIN
	CALL PRC_FNC_GET_PRECIO_ARTICULO_FECHA(pCODIGO_ARTICULO, 
	                                       CURRENT_DATE, 
																				 ppPRECIOSALIDA_TARIFA, 
																				 ppPRECIOFINAL_TARIFA,
																				 ppPORCEN_DTO_TARIFA,
																				 ppPRECIO_DTO_TARIFA);

	IF (ppPRECIOFINAL_TARIFA IS NOT NULL) THEN
	BEGIN
		 UPDATE fza_articulos_tarifas
				SET 
						PRECIOSALIDA_TARIFA	   = pPRECIOSALIDA_TARIFA,
            PRECIOFINAL_TARIFA     = pPRECIOFINAL_TARIFA,
            PRECIO_DTO_TARIFA		   = pPRECIO_DTO_TARIFA,
            PORCEN_DTO_TARIFA		   = pPORCEN_DTO_TARIFA,
						USUARIOMODIF           = pUSUARIO          ,
						INSTANTEMODIF          = CURRENT_TIMESTAMP			 
			WHERE CODIGO_ARTICULO_TARIFA =  pCODIGO_ARTICULO
				AND  CODIGO_TARIFA = pCODIGO_TARIFA;
		END;
		ELSE
		BEGIN
			IF (ppPRECIOFINAL_TARIFA IS NULL) THEN
			BEGIN
				INSERT INTO fza_articulos_tarifas ( CODIGO_ARTICULO_TARIFA,
																						CODIGO_TARIFA,
																						PRECIOSALIDA_TARIFA	,
																						PRECIOFINAL_TARIFA  ,
																						PRECIO_DTO_TARIFA		,
																						PORCEN_DTO_TARIFA		,
																						FECHA_DESDE_TARIFA  ,
																						USUARIOMODIF                     ,
																						INSTANTEMODIF                    ,
																						USUARIOALTA                      ,
																						INSTANTEALTA                      
																					 ) VALUES
																					(pCODIGO_ARTICULO                   ,
																					 pCODIGO_TARIFA                     ,
																					 pPRECIOSALIDA_TARIFA             ,
																					 pPRECIOFINAL_TARIFA              ,
																					 pPRECIO_DTO_TARIFA               ,
																					 pPORCEN_DTO_TARIFA               ,
																					 CURRENT_TIMESTAMP               ,
																					 pUSUARIO                         ,
																					 CURRENT_TIMESTAMP			             ,
																					 pUSUARIO                         ,
																					 CURRENT_TIMESTAMP			 
																						);
			END;
			END IF;
		END;
		END IF;
END;
END IF;		
COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_ACTUALIZAR_TEST
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_ACTUALIZAR_TEST`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_ACTUALIZAR_TEST`()
BEGIN
  CALL PRC_FNC_GET_PRECIO_ARTICULO_FECHA('PAÑITOS', CURRENT_DATE, @PRECIOFINAL, @PRECIO_INICIAL, @PORCEN_DTO, @PRECIO_DTO);
  /* SELECT @PRECIOFINAL, @PRECIO_INICIAL, @PORCEN_DTO, @PRECIO_DTO; */
			IF (@PRECIOFINAL IS NULL) THEN
			BEGIN
			 SELECT 'HOLA';
		 END;
		 ELSE
	   BEGIN
		   SELECT 'NO HAY';
		 END;
		 END IF;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_FACTURA_ABONO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_FACTURA_ABONO`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_FACTURA_ABONO`(IN `pidseriefactura`      varchar(200),
                                      IN `pidnumfactura`        varchar(200),
                                      IN `pidseriefacturaabono` varchar(200),
																			IN `pidcodigo_empresa`    varchar(200),
                                      IN `pfechafacturaabono`   date,
                                     OUT `pidnumfacturaabono`   varchar(200),
                                      IN `pUSUARIO`             varchar(100))
BEGIN
   DECLARE contadorped varchar(200);
   START TRANSACTION;
   CALL PRC_GET_NEXT_CONT_FACT_SERIE(pidseriefacturaabono, 'FC', pidcodigo_empresa, pUSUARIO, @cont);   
   SET @pFecha = (SELECT DATE_FORMAT(pfechafacturaabono, '%Y-%m-%d'));
   SET contadorped = @cont;     
   SET pidnumfacturaabono = contadorped;
   INSERT INTO fza_facturas  (`NRO_FACTURA`                                  ,
                              `SERIE_FACTURA`                                ,
                              `FECHA_FACTURA`                                ,
                              `CODIGO_EMPRESA_FACTURA`                       ,
                              `RAZONSOCIAL_EMPRESA_FACTURA`                  ,
                              `NIF_EMPRESA_FACTURA`                          ,
                              `MOVIL_EMPRESA_FACTURA`                        ,
                              `EMAIL_EMPRESA_FACTURA`                        ,
                              `DIRECCION1_EMPRESA_FACTURA`                   ,
                              `DIRECCION2_EMPRESA_FACTURA`                   ,
                              `POBLACION_EMPRESA_FACTURA`                    ,
                              `PROVINCIA_EMPRESA_FACTURA`                    ,
                              `NOMBRE_PAIS_EMPRESA_FACTURA`                         ,
															`CODIGO_PAIS_EMPRESA_FACTURA`                         ,
                              `CPOSTAL_EMPRESA_FACTURA`                      ,
                              `ESRETENCIONES_EMPRESA_FACTURA`                ,
                              `GRUPO_ZONA_IVA_EMPRESA_FACTURA`               ,
                              `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`    ,
                              `CODIGO_CLIENTE_FACTURA`                       ,
                              `RAZONSOCIAL_CLIENTE_FACTURA`                  ,
                              `NIF_CLIENTE_FACTURA`                          ,
                              `MOVIL_CLIENTE_FACTURA`                        ,
                              `EMAIL_CLIENTE_FACTURA`                        ,
                              `DIRECCION1_CLIENTE_FACTURA`                   ,
                              `DIRECCION2_CLIENTE_FACTURA`                   ,
                              `POBLACION_CLIENTE_FACTURA`                    ,
                              `PROVINCIA_CLIENTE_FACTURA`                    ,
                              `CPOSTAL_CLIENTE_FACTURA`                      ,
                              `NOMBRE_PAIS_CLIENTE_FACTURA`                         ,
															`CODIGO_PAIS_CLIENTE_FACTURA`                         ,
                              `ESIVA_RECARGO_CLIENTE_FACTURA`                ,
                              `ESIVA_EXENTO_CLIENTE_FACTURA`                 ,
                              `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`    ,
                              `ESRETENCIONES_CLIENTE_FACTURA`                ,
                              `TARIFA_ARTICULO_CLIENTE_FACTURA`              ,
                              `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`            ,
                              `ESINTRACOMUNITARIO_CLIENTE_FACTURA`           ,
                              `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`             ,
                              `ESAPLICA_RE_ZONA_IVA_FACTURA`                 ,
                              `ESIVAAGRICOLA_ZONA_IVA_FACTURA`               ,
                              `PALABRA_REPORTS_ZONA_IVA_FACTURA`             ,
                              `CODIGO_IVA_FACTURA`                           ,
                              `ESVENTA_ACTIVO_FIJO_FACTURA`                  ,
                              `PORCEN_IVAN_FACTURA`                          ,
                              `TOTAL_IVAN_FACTURA`                           ,
                              `PORCEN_REN_FACTURA`                           ,
                              `TOTAL_REN_FACTURA`                            ,
                              `TOTAL_BASEI_IVAN_FACTURA`                     ,
                              `PORCEN_IVAR_FACTURA`                          ,
                              `TOTAL_IVAR_FACTURA`                           ,
                              `PORCEN_RER_FACTURA`                           ,
                              `TOTAL_RER_FACTURA`                            ,
                              `TOTAL_BASEI_IVAR_FACTURA`                     ,
                              `PORCEN_IVAS_FACTURA`                          ,
                              `TOTAL_IVAS_FACTURA`                           ,
                              `PORCEN_RES_FACTURA`                           ,
                              `TOTAL_RES_FACTURA`                            ,
                              `TOTAL_BASEI_IVAS_FACTURA`                     ,
                              `PORCEN_IVAE_FACTURA`                          ,
                              `TOTAL_IVAE_FACTURA`                           ,
                              `PORCEN_REE_FACTURA`                           ,
                              `TOTAL_REE_FACTURA`                            ,
                              `TOTAL_BASEI_IVAE_FACTURA`                     ,
                              `TOTAL_BASES_FACTURA`                          ,
                              `TOTAL_IMPUESTOS_FACTURA`                      ,
                              `FORMA_PAGO_FACTURA`                           ,
                              `PORCEN_RETENCION_FACTURA`                     ,
                              `TOTAL_RETENCION_FACTURA`                      ,
                              `TOTAL_LIQUIDO_FACTURA`                        ,
                              `NRO_FACTURA_ABONO_FACTURA`                    ,
                              `SERIE_FACTURA_ABONO_FACTURA`                  ,
                              `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA`          ,
                              `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA`          ,
                              `DOCUMENTO_FACTURA`                            ,
                              `COMENTARIOS_FACTURA`                          ,
                              `CONTADOR_LINEAS_FACTURA`                      ,
															`ESCREARARTICULOS_FACTURA`										 ,	
                              `ESDESCRIPCIONES_AMP_FACTURA`	                 ,
                              `ESFECHADEENTREGA_FACTURA`	                   ,
                              `INSTANTEMODIF`                                ,
                              `INSTANTEALTA`                                 ,
                              `USUARIOALTA`                                  ,                        
                              `USUARIOMODIF`
                             )                                 
                     SELECT `contadorped`                                    ,
                            `pidseriefacturaabono`                           ,
                            `@pFecha`                                        ,
                            `CODIGO_EMPRESA_FACTURA`                         ,
                            `RAZONSOCIAL_EMPRESA_FACTURA`                    ,
                            `NIF_EMPRESA_FACTURA`                            ,
                            `MOVIL_EMPRESA_FACTURA`                          ,
                            `EMAIL_EMPRESA_FACTURA`                          ,
                            `DIRECCION1_EMPRESA_FACTURA`                     ,
                            `DIRECCION2_EMPRESA_FACTURA`                     ,
                            `POBLACION_EMPRESA_FACTURA`                      ,
                            `PROVINCIA_EMPRESA_FACTURA`                      ,
                            `NOMBRE_PAIS_EMPRESA_FACTURA`                           ,
														`CODIGO_PAIS_EMPRESA_FACTURA`                           ,
                            `CPOSTAL_EMPRESA_FACTURA`                        ,
                            `ESRETENCIONES_EMPRESA_FACTURA`                  ,
                            `GRUPO_ZONA_IVA_EMPRESA_FACTURA`                 ,
                            `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`      ,
                            `CODIGO_CLIENTE_FACTURA`                         ,
                            `RAZONSOCIAL_CLIENTE_FACTURA`                    ,
                            `NIF_CLIENTE_FACTURA`                            ,
                            `MOVIL_CLIENTE_FACTURA`                          ,
                            `EMAIL_CLIENTE_FACTURA`                          ,
                            `DIRECCION1_CLIENTE_FACTURA`                     ,
                            `DIRECCION2_CLIENTE_FACTURA`                     ,
                            `POBLACION_CLIENTE_FACTURA`                      ,
                            `PROVINCIA_CLIENTE_FACTURA`                      ,
                            `CPOSTAL_CLIENTE_FACTURA`                        ,
                            `NOMBRE_PAIS_CLIENTE_FACTURA`                           ,
														`CODIGO_PAIS_CLIENTE_FACTURA`                           ,
                            `ESIVA_RECARGO_CLIENTE_FACTURA`                  ,
                            `ESIVA_EXENTO_CLIENTE_FACTURA`                   ,
                            `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`      ,
                            `ESRETENCIONES_CLIENTE_FACTURA`                  ,
                            `TARIFA_ARTICULO_CLIENTE_FACTURA`                ,
                            `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`              ,
                            `ESINTRACOMUNITARIO_CLIENTE_FACTURA`             ,
                            `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`               ,
                            `ESAPLICA_RE_ZONA_IVA_FACTURA`                   ,
                            `ESIVAAGRICOLA_ZONA_IVA_FACTURA`                 ,
                            `PALABRA_REPORTS_ZONA_IVA_FACTURA`               ,
                            `CODIGO_IVA_FACTURA`                             ,
                            `ESVENTA_ACTIVO_FIJO_FACTURA`                    ,
                            `PORCEN_IVAN_FACTURA`                            ,
                            `TOTAL_IVAN_FACTURA`                             ,
                            `PORCEN_REN_FACTURA`                             ,
                            `TOTAL_REN_FACTURA`                              ,
                            `TOTAL_BASEI_IVAN_FACTURA`                       ,
                            `PORCEN_IVAR_FACTURA`                            ,
                            `TOTAL_IVAR_FACTURA`                             ,
                            `PORCEN_RER_FACTURA`                             ,
                            `TOTAL_RER_FACTURA`                              ,
                            `TOTAL_BASEI_IVAR_FACTURA`                       ,
                            `PORCEN_IVAS_FACTURA`                            ,
                            `TOTAL_IVAS_FACTURA`                             ,
                            `PORCEN_RES_FACTURA`                             ,
                            `TOTAL_RES_FACTURA`                              ,
                            `TOTAL_BASEI_IVAS_FACTURA`                       ,
                            `PORCEN_IVAE_FACTURA`                            ,
                            `TOTAL_IVAE_FACTURA`                             ,
                            `PORCEN_REE_FACTURA`                             ,
                            `TOTAL_REE_FACTURA`                              ,
                            `TOTAL_BASEI_IVAE_FACTURA`                       ,
                            `TOTAL_BASES_FACTURA`                            ,
                            `TOTAL_IMPUESTOS_FACTURA`                        ,
                            `FORMA_PAGO_FACTURA`                             ,
                            `PORCEN_RETENCION_FACTURA`                       ,
                            `TOTAL_RETENCION_FACTURA`                        ,
                            `TOTAL_LIQUIDO_FACTURA`                          ,
                            `NRO_FACTURA_ABONO_FACTURA`                      ,
                            `SERIE_FACTURA_ABONO_FACTURA`                    ,
                            `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA`            ,
                            `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA`            ,
                            `DOCUMENTO_FACTURA`                              ,
                            `COMENTARIOS_FACTURA`                            ,
                            `CONTADOR_LINEAS_FACTURA`                        ,
														`ESCREARARTICULOS_FACTURA`											 ,	
                            `ESDESCRIPCIONES_AMP_FACTURA`	                   ,
                            `ESFECHADEENTREGA_FACTURA`	                     , 
                            CURRENT_TIMESTAMP                                 ,
                            CURRENT_TIMESTAMP                                 ,
                            `pUSUARIO`                                       ,
                            `pUSUARIO`
                       FROM `fza_facturas` 
                      WHERE `NRO_FACTURA`   = `pidnumfactura` 
                        AND `SERIE_FACTURA` = `pidseriefactura`;  
  INSERT INTO `fza_facturas_lineas` (`NRO_FACTURA_LINEA`                      ,
                                     `SERIE_FACTURA_LINEA`                    ,
                                     `LINEA_FACTURA_LINEA`                    ,
                                     `CODIGO_ARTICULO_FACTURA_LINEA`          ,
                                     `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`   ,
                                     `ESIMP_INCL_TARIFA_FACTURA_LINEA`        ,
                                     `TIPOIVA_ARTICULO_FACTURA_LINEA`         ,
                                     `DESCRIPCION_ARTICULO_FACTURA_LINEA`     ,
                                     `CANTIDAD_FACTURA_LINEA`                 ,
                                     `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`,
                                     `PORCEN_IVA_FACTURA_LINEA`               ,
                                     `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`,
                                     `TOTAL_FACTURA_LINEA`                    ,
                                     `INSTANTEMODIF`                          ,
                                     `INSTANTEALTA`                           ,
                                     `USUARIOALTA`                            ,                        
                                     `USUARIOMODIF`                  
                                      ) 
                              SELECT `contadorped`                             ,
                                     `pidseriefacturaabono`                    ,
                                     `LINEA_FACTURA_LINEA`                     ,
                                     `CODIGO_ARTICULO_FACTURA_LINEA`           ,
                                     `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`    ,
                                     `ESIMP_INCL_TARIFA_FACTURA_LINEA`         ,
                                     `TIPOIVA_ARTICULO_FACTURA_LINEA`          ,
                                     `DESCRIPCION_ARTICULO_FACTURA_LINEA`      ,
                                     (`CANTIDAD_FACTURA_LINEA`*-1)             ,
                                     `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` ,
                                     `PORCEN_IVA_FACTURA_LINEA`                ,
                                     `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA` ,
                                     (`TOTAL_FACTURA_LINEA` * -1)              ,
                                     CURRENT_TIMESTAMP                          ,
                                     CURRENT_TIMESTAMP                          ,
                                     `pUSUARIO`                                ,
                                     `pUSUARIO`
                               FROM  `fza_facturas_lineas` 
                              WHERE  `SERIE_FACTURA_LINEA`  = `pidseriefactura`
                                AND  `NRO_FACTURA_LINEA`    = `pidnumfactura`  ;                 
   CALL `PRC_CALCULAR_FACTURA_NETOS`(`pidseriefacturaabono`, `contadorped`);
   COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_FACTURA_DUPLICADA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_FACTURA_DUPLICADA`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_FACTURA_DUPLICADA`(IN `pidseriefactura`      varchar(200),
                                        IN `pidnumfactura`        varchar(200),
                                        IN `pidseriefacturaabono` varchar(200),
																				IN `pidcodigo_empresa`    varchar(200),
                                        IN `pfechafacturaabono`   date,
                                        IN `pUSUARIO`             varchar(100),
                                       OUT `pidnumfacturaabono`   varchar(200))
BEGIN
   DECLARE `contadorped` varchar(200);
   DECLARE `pfecha` date;
   START TRANSACTION;
   CALL PRC_GET_NEXT_CONT_FACT_SERIE(`pidseriefacturaabono`, 
                                     'FC', 
																		 pidcodigo_empresa,
																		 pUSUARIO,
                                     `contadorped`);
   SET pFecha = (SELECT DATE_FORMAT(`pfechafacturaabono`, '%Y-%m-%d'));
   SET pidnumfacturaabono = contadorped;
   INSERT INTO fza_facturas (`NRO_FACTURA`                                  ,
                             `SERIE_FACTURA`                                ,
                             `FECHA_FACTURA`                                ,
                             `CODIGO_EMPRESA_FACTURA`                       ,
                             `RAZONSOCIAL_EMPRESA_FACTURA`                  ,
                             `NIF_EMPRESA_FACTURA`                          ,
                             `MOVIL_EMPRESA_FACTURA`                        ,
                             `EMAIL_EMPRESA_FACTURA`                        ,
                             `DIRECCION1_EMPRESA_FACTURA`                   ,
                             `DIRECCION2_EMPRESA_FACTURA`                   ,
                             `POBLACION_EMPRESA_FACTURA`                    ,
                             `PROVINCIA_EMPRESA_FACTURA`                    ,
                             `NOMBRE_PAIS_EMPRESA_FACTURA`                  ,
														 `CODIGO_PAIS_EMPRESA_FACTURA`                  ,
                             `CPOSTAL_EMPRESA_FACTURA`                      ,
                             `ESRETENCIONES_EMPRESA_FACTURA`                ,
                             `GRUPO_ZONA_IVA_EMPRESA_FACTURA`               ,
                             `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`    ,
                             `CODIGO_CLIENTE_FACTURA`                       ,
                             `RAZONSOCIAL_CLIENTE_FACTURA`                  ,
                             `NIF_CLIENTE_FACTURA`                          ,
                             `MOVIL_CLIENTE_FACTURA`                        ,
                             `EMAIL_CLIENTE_FACTURA`                        ,
                             `DIRECCION1_CLIENTE_FACTURA`                   ,
                             `DIRECCION2_CLIENTE_FACTURA`                   ,
                             `POBLACION_CLIENTE_FACTURA`                    ,
                             `PROVINCIA_CLIENTE_FACTURA`                    ,
                             `CPOSTAL_CLIENTE_FACTURA`                      ,
                             `NOMBRE_PAIS_CLIENTE_FACTURA`                         ,
														 `CODIGO_PAIS_CLIENTE_FACTURA`                         ,
                             `ESIVA_RECARGO_CLIENTE_FACTURA`                ,
                             `ESIVA_EXENTO_CLIENTE_FACTURA`                 ,
                             `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`    ,
                             `ESRETENCIONES_CLIENTE_FACTURA`                ,
                             `TARIFA_ARTICULO_CLIENTE_FACTURA`              ,
                             `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`            ,
                             `ESINTRACOMUNITARIO_CLIENTE_FACTURA`           ,
                             `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`             ,
                             `ESAPLICA_RE_ZONA_IVA_FACTURA`                 ,
                             `ESIVAAGRICOLA_ZONA_IVA_FACTURA`               ,
                             `PALABRA_REPORTS_ZONA_IVA_FACTURA`             ,
                             `CODIGO_IVA_FACTURA`                           ,
                             `ESVENTA_ACTIVO_FIJO_FACTURA`                  ,
                             `PORCEN_IVAN_FACTURA`                          ,
                             `TOTAL_IVAN_FACTURA`                           ,
                             `PORCEN_REN_FACTURA`                           ,
                             `TOTAL_REN_FACTURA`                            ,
                             `TOTAL_BASEI_IVAN_FACTURA`                     ,
                             `PORCEN_IVAR_FACTURA`                          ,
                             `TOTAL_IVAR_FACTURA`                           ,
                             `PORCEN_RER_FACTURA`                           ,
                             `TOTAL_RER_FACTURA`                            ,
                             `TOTAL_BASEI_IVAR_FACTURA`                     ,
                             `PORCEN_IVAS_FACTURA`                          ,
                             `TOTAL_IVAS_FACTURA`                           ,
                             `PORCEN_RES_FACTURA`                           ,
                             `TOTAL_RES_FACTURA`                            ,
                             `TOTAL_BASEI_IVAS_FACTURA`                     ,
                             `PORCEN_IVAE_FACTURA`                          ,
                             `TOTAL_IVAE_FACTURA`                           ,
                             `PORCEN_REE_FACTURA`                           ,
                             `TOTAL_REE_FACTURA`                            ,
                             `TOTAL_BASEI_IVAE_FACTURA`                     ,
                             `TOTAL_BASES_FACTURA`                          ,
                             `TOTAL_IMPUESTOS_FACTURA`                      ,
                             `FORMA_PAGO_FACTURA`                           ,
                             `PORCEN_RETENCION_FACTURA`                     ,
                             `TOTAL_RETENCION_FACTURA`                      ,
                             `TOTAL_LIQUIDO_FACTURA`                        ,
                             `NRO_FACTURA_ABONO_FACTURA`                    ,
                             `SERIE_FACTURA_ABONO_FACTURA`                  ,
                             `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA`          ,
                             `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA`          ,
                             `DOCUMENTO_FACTURA`                            ,
                             `COMENTARIOS_FACTURA`                          ,
                             `CONTADOR_LINEAS_FACTURA`                      ,
														 `ESCREARARTICULOS_FACTURA`											,	
                             `ESDESCRIPCIONES_AMP_FACTURA`	                ,
                             `ESFECHADEENTREGA_FACTURA`	                    ,
                             `INSTANTEMODIF`                                ,
                             `INSTANTEALTA`                                 ,
                             `USUARIOALTA`                                  ,
                             `USUARIOMODIF`
                        )
                          SELECT `contadorped`                                ,
                                 `pidseriefacturaabono`                       ,
                                 `pFecha`                                     ,
                                 `CODIGO_EMPRESA_FACTURA`                     ,
                                 `RAZONSOCIAL_EMPRESA_FACTURA`                ,
                                 `NIF_EMPRESA_FACTURA`                        ,
                                 `MOVIL_EMPRESA_FACTURA`                      ,
                                 `EMAIL_EMPRESA_FACTURA`                      ,
                                 `DIRECCION1_EMPRESA_FACTURA`                 ,
                                 `DIRECCION2_EMPRESA_FACTURA`                 ,
                                 `POBLACION_EMPRESA_FACTURA`                  ,
                                 `PROVINCIA_EMPRESA_FACTURA`                  ,
                                 `NOMBRE_PAIS_EMPRESA_FACTURA`                       ,
																 `CODIGO_PAIS_EMPRESA_FACTURA`                       ,
                                 `CPOSTAL_EMPRESA_FACTURA`                    ,
                                 `ESRETENCIONES_EMPRESA_FACTURA`              ,
                                 `GRUPO_ZONA_IVA_EMPRESA_FACTURA`             ,
                                 `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA`  ,
                                 `CODIGO_CLIENTE_FACTURA`                     ,
                                 `RAZONSOCIAL_CLIENTE_FACTURA`                ,
                                 `NIF_CLIENTE_FACTURA`                        ,
                                 `MOVIL_CLIENTE_FACTURA`                      ,
                                 `EMAIL_CLIENTE_FACTURA`                      ,
                                 `DIRECCION1_CLIENTE_FACTURA`                 ,
                                 `DIRECCION2_CLIENTE_FACTURA`                 ,
                                 `POBLACION_CLIENTE_FACTURA`                  ,
                                 `PROVINCIA_CLIENTE_FACTURA`                  ,
                                 `CPOSTAL_CLIENTE_FACTURA`                    ,
                                 `NOMBRE_PAIS_CLIENTE_FACTURA`                       ,
																 `CODIGO_PAIS_CLIENTE_FACTURA`                       ,
                                 `ESIVA_RECARGO_CLIENTE_FACTURA`              ,
                                 `ESIVA_EXENTO_CLIENTE_FACTURA`               ,
                                 `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA`  ,
                                 `ESRETENCIONES_CLIENTE_FACTURA`              ,
                                 `TARIFA_ARTICULO_CLIENTE_FACTURA`            ,
                                 `ESIMP_INCL_TARIFA_CLIENTE_FACTURA`          ,
                                 `ESINTRACOMUNITARIO_CLIENTE_FACTURA`         ,
                                 `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA`           ,
                                 `ESAPLICA_RE_ZONA_IVA_FACTURA`               ,
                                 `ESIVAAGRICOLA_ZONA_IVA_FACTURA`             ,
                                 `PALABRA_REPORTS_ZONA_IVA_FACTURA`           ,
                                 `CODIGO_IVA_FACTURA`                         ,
                                 `ESVENTA_ACTIVO_FIJO_FACTURA`                ,
                                 `PORCEN_IVAN_FACTURA`                        ,
                                 `TOTAL_IVAN_FACTURA`                         ,
                                 `PORCEN_REN_FACTURA`                         ,
                                 `TOTAL_REN_FACTURA`                          ,
                                 `TOTAL_BASEI_IVAN_FACTURA`                   ,
                                 `PORCEN_IVAR_FACTURA`                        ,
                                 `TOTAL_IVAR_FACTURA`                         ,
                                 `PORCEN_RER_FACTURA`                         ,
                                 `TOTAL_RER_FACTURA`                          ,
                                 `TOTAL_BASEI_IVAR_FACTURA`                   ,
                                 `PORCEN_IVAS_FACTURA`                        ,
                                 `TOTAL_IVAS_FACTURA`                         ,
                                 `PORCEN_RES_FACTURA`                         ,
                                 `TOTAL_RES_FACTURA`                          ,
                                 `TOTAL_BASEI_IVAS_FACTURA`                   ,
                                 `PORCEN_IVAE_FACTURA`                        ,
                                 `TOTAL_IVAE_FACTURA`                         ,
                                 `PORCEN_REE_FACTURA`                         ,
                                 `TOTAL_REE_FACTURA`                          ,
                                 `TOTAL_BASEI_IVAE_FACTURA`                   ,
                                 `TOTAL_BASES_FACTURA`                        ,
                                 `TOTAL_IMPUESTOS_FACTURA`                    ,
                                 `FORMA_PAGO_FACTURA`                         ,
                                 `PORCEN_RETENCION_FACTURA`                   ,
                                 `TOTAL_RETENCION_FACTURA`                    ,
                                 `TOTAL_LIQUIDO_FACTURA`                      ,
                                 `NRO_FACTURA_ABONO_FACTURA`                  ,
                                 `SERIE_FACTURA_ABONO_FACTURA`                ,
                                 `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA`        ,
                                 `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA`        ,
                                 `DOCUMENTO_FACTURA`                          ,
                                 `COMENTARIOS_FACTURA`                        ,
                                 `CONTADOR_LINEAS_FACTURA`                    ,
																 `ESCREARARTICULOS_FACTURA`										,	
                                 `ESDESCRIPCIONES_AMP_FACTURA`	              ,
                                 `ESFECHADEENTREGA_FACTURA`	                  ,
                                 CURRENT_TIMESTAMP                             ,
                                 CURRENT_TIMESTAMP                            ,
                                 `pUSUARIO`                                   ,
                                 `pUSUARIO`
                            FROM `fza_facturas` 
                           WHERE `NRO_FACTURA`   = `pidnumfactura` 
                             AND `SERIE_FACTURA` = `pidseriefactura`;  
  INSERT INTO fza_facturas_lineas (`NRO_FACTURA_LINEA`                        ,
                                   `SERIE_FACTURA_LINEA`                      ,
                                   `LINEA_FACTURA_LINEA`                      ,
                                   `CODIGO_ARTICULO_FACTURA_LINEA`            ,
                                   `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`     ,
                                   `ESIMP_INCL_TARIFA_FACTURA_LINEA`          ,
                                   `TIPOIVA_ARTICULO_FACTURA_LINEA`           ,
                                   `DESCRIPCION_ARTICULO_FACTURA_LINEA`       ,
                                   `CANTIDAD_FACTURA_LINEA`                   ,
                                   `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`  ,
                                   `PORCEN_IVA_FACTURA_LINEA`                 ,
                                   `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`  ,
                                   `TOTAL_FACTURA_LINEA`                      ,
                                   `INSTANTEMODIF`                            ,
                                   `INSTANTEALTA`                             ,
                                   `USUARIOALTA`                              ,
                                   `USUARIOMODIF`
                                  )
                           SELECT `contadorped`                               ,
                                  `pidseriefacturaabono`                      ,
                                  `LINEA_FACTURA_LINEA`                       ,
                                  `CODIGO_ARTICULO_FACTURA_LINEA`             ,
                                  `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`      ,
                                  `ESIMP_INCL_TARIFA_FACTURA_LINEA`           ,
                                  `TIPOIVA_ARTICULO_FACTURA_LINEA`            ,
                                  `DESCRIPCION_ARTICULO_FACTURA_LINEA`        ,
                                  `CANTIDAD_FACTURA_LINEA`                    ,
                                  `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`   ,
                                  `PORCEN_IVA_FACTURA_LINEA`                  ,
                                  `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA`   ,
                                  `TOTAL_FACTURA_LINEA`                       ,
                                  CURRENT_TIMESTAMP                           ,
                                  CURRENT_TIMESTAMP                           ,
                                  `pUSUARIO`                                  ,
                                  `pUSUARIO`
                             FROM `fza_facturas_lineas`
                            WHERE `SERIE_FACTURA_LINEA`      = `pidseriefactura`
                              AND `NRO_FACTURA_LINEA`        = `pidnumfactura` ;
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_METADATOS
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_METADATOS`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_METADATOS`(IN `pDATABASENAME` varchar(100))
BEGIN
START TRANSACTION;
  DROP TABLE IF EXISTS `fza_metadatos`;
  CREATE TABLE `fza_metadatos`  (
    `CODIGO_METADATO` int(20) NOT NULL AUTO_INCREMENT,
    `NOMBRE_METADATO` varchar(100) CHARACTER SET utf8mb4 
                               COLLATE utf8mb4_spanish_ci NOT NULL,
    `PARENT_METADATO` varchar(20) CHARACTER SET utf8mb4 
                               COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (`CODIGO_METADATO`) USING BTREE
  ) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 
             COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;
  INSERT INTO `fza_metadatos` (`PARENT_METADATO`, `NOMBRE_METADATO`)
  SELECT '1' AS `PARENT_METADATO`,
         `table_name` as `NOMBRE_METADATO`
    FROM `information_schema`.`TABLES` 
   WHERE `table_schema` = `pDATABASENAME`  
     AND `table_type` = 'BASE TABLE';
  INSERT INTO `fza_metadatos` (`PARENT_METADATO`, `NOMBRE_METADATO`)    
  SELECT '2' AS `PARENT_METADATO`,
         `table_name` as `NOMBRE_METADATO`
    FROM `information_schema`.`TABLES` 
   WHERE `table_schema` = `pDATABASENAME`
     AND `table_type` = 'VIEW';
   INSERT INTO `fza_metadatos` (`PARENT_METADATO`, `NOMBRE_METADATO`) 
   SELECT '3' AS `PARENT_METADATO`,
          `SPECIFIC_NAME` AS `NOMBRE_METADATO`
     FROM `information_schema`.`ROUTINES` 
    WHERE `ROUTINE_SCHEMA` = pDATABASENAME  
      AND `ROUTINE_TYPE` = 'PROCEDURE';     
   
   INSERT INTO `fza_metadatos` (`CODIGO_METADATO`, 
                                `PARENT_METADATO`, 
                                `NOMBRE_METADATO`) 
                        VALUES (1, '-1','Tablas');  
   INSERT INTO `fza_metadatos` (`CODIGO_METADATO`, 
                                `PARENT_METADATO`, 
                                `NOMBRE_METADATO`) 
                        VALUES (2, '-1','Vistas');
   INSERT INTO `fza_metadatos` (`CODIGO_METADATO`, 
                                `PARENT_METADATO`, 
                                `NOMBRE_METADATO`) 
                        VALUES (3, '-1','Procedimientos');
COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_RECIBOS_FACTURA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_RECIBOS_FACTURA`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_RECIBOS_FACTURA`(IN `pSERIE_FACTURA` varchar(12),
	                                        IN `pNRO_FACTURA` varchar(12),
																					IN `pUSUARIO`             varchar(100))
BEGIN
  DECLARE pCODIGO_FORMAPAGO VARCHAR(20);
	DECLARE pFORMA_PAGO_FACTURA VARCHAR(100);
	DECLARE pN_PLAZOS int(10); 
	DECLARE I int(10);
	DECLARE pDIAS_ENTRE_PLAZOS int(10);
	DECLARE pPORCEN_ANTICIPO decimal(5,2);
	DECLARE pCODIGO_CLIENTE  varchar(20);
	DECLARE pIBAN varchar(34);
	DECLARE pRAZONSOCIAL_CLIENTE varchar(200);
	DECLARE pDIRECCION1_CLIENTE  varchar(200);
	DECLARE pPOBLACION_CLIENTE  varchar(200);
	DECLARE pPOBLACION_EMPRESA varchar(200);
	DECLARE pPROVINCIA_CLIENTE  varchar(200);
	DECLARE pCPOSTAL_CLIENTE  varchar(15);
	DECLARE pIMPORTE_LETRA  varchar(150);
	DECLARE pTOTAL_LIQUIDO_FACTURA decimal(18,6);
	DECLARE pIMPORTE_RECIBO decimal(18,6);
	DECLARE pIMPORTE_RESTO decimal(18,6);
	DECLARE pIMPORTE_ANTICIPO decimal(18,6);
	DECLARE pFECHA_VENCIMIENTO date;
	DECLARE pFECHA_FACTURA date;
	DECLARE finished INTEGER DEFAULT 0;
	/* DECLARE pTRATAMIENTO_LINEA VARCHAR(100); */
  /* DECLARE pTRATAMIENTOS varchar(1000) DEFAULT ""; */
  /* DECLARE curTratamientos 
        CURSOR FOR 
            SELECT DESCRIPCION_ARTICULO_LINEA 
						  FROM suboc_facturas_lineas 
						 WHERE SERIE_FACTURA_LINEA = pSERIE_FACTURA 
						   AND NRO_FACTURA_LINEA = pNRO_FACTURA;
  DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1; */
	START TRANSACTION;
	DELETE FROM fza_recibos 
   WHERE NRO_FACTURA_RECIBO = pNRO_FACTURA
	   AND SERIE_FACTURA_RECIBO = pSERIE_FACTURA;	
  /* OPEN curTratamientos;
  getTratamientos: LOOP
		FETCH curTratamientos INTO pTRATAMIENTO_LINEA;
		IF finished = 1 THEN 
				LEAVE getTratamientos;
		END IF;
		-- build email list
		SET pTRATAMIENTOS = CONCAT(pTRATAMIENTOS,'\n',pTRATAMIENTO_LINEA);
  END LOOP getTratamientos;
	*/
	SELECT FORMA_PAGO_FACTURA, 
				 CODIGO_CLIENTE_FACTURA,
				 TOTAL_LIQUIDO_FACTURA,
				 RAZONSOCIAL_CLIENTE_FACTURA,
				 DIRECCION1_CLIENTE_FACTURA,
				 POBLACION_CLIENTE_FACTURA,
				 PROVINCIA_CLIENTE_FACTURA,
				 CPOSTAL_CLIENTE_FACTURA,
				 FECHA_FACTURA,
				 POBLACION_EMPRESA_FACTURA
		INTO pFORMA_PAGO_FACTURA,
				 pCODIGO_CLIENTE,
				 pTOTAL_LIQUIDO_FACTURA,
				 pRAZONSOCIAL_CLIENTE,
				 pDIRECCION1_CLIENTE,
				 pPOBLACION_CLIENTE,
				 pPROVINCIA_CLIENTE,
				 pCPOSTAL_CLIENTE,
				 pFECHA_FACTURA,
				 pPOBLACION_EMPRESA
		FROM fza_facturas
   WHERE SERIE_FACTURA = pSERIE_FACTURA
	   AND NRO_FACTURA = pNRO_FACTURA;
     /*select pFORMA_PAGO_FACTURA;*/		 
		 SELECT IBAN_CLIENTE 
		  INTO pIBAN
		 FROM fza_clientes
		 WHERE CODIGO_CLIENTE = pCODIGO_CLIENTE;
		 /* select pforma_pago_factura; */
		 IF( EXISTS(
							 SELECT *
							 FROM fza_formas_pago
							 WHERE CODIGO_FORMAPAGO =  pFORMA_PAGO_FACTURA) ) THEN
		BEGIN
			SELECT CODIGO_FORMAPAGO, 
			       N_PLAZOS_FORMAPAGO, 
						 N_DIAS_ENTRE_PLAZOS_FORMAPAGO, 
						 PORCEN_ANTICIPO_FORMAPAGO 
				INTO pCODIGO_FORMAPAGO,
				     pN_PLAZOS, 
						 pDIAS_ENTRE_PLAZOS,  
						 pPORCEN_ANTICIPO
				FROM fza_formas_pago
				WHERE CODIGO_FORMAPAGO = pFORMA_PAGO_FACTURA;
				
			IF ((pPORCEN_ANTICIPO = 100)) THEN
			BEGIN
				CALL PRC_GET_NUMEROS_A_LETRAS(pTOTAL_LIQUIDO_FACTURA, pIMPORTE_LETRA);
				INSERT INTO  fza_recibos 
				       (NRO_FACTURA_RECIBO					        ,
								SERIE_FACTURA_RECIBO                ,
								NRO_PLAZO_RECIBO                    ,
								FORMA_PAGO_ORIGEN_RECIBO            ,
								FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO,								
								EUROS_RECIBO                        ,
								STADO_RECIBO                       ,
								FECHA_EXPEDICION_RECIBO             ,
								FECHA_VENCIMIENTO_RECIBO            ,
								IBAN_CLIENTE_RECIBO                 ,
								FECHA_PAGO_RECIBO                   ,
								LOCALIDAD_EXPEDICION_RECIBO         ,
								CODIGO_CLIENTE_RECIBO               ,
								RAZONSOCIAL_CLIENTE_RECIBO          ,
								DIRECCION1_CLIENTE_RECIBO           ,
								POBLACION_CLIENTE_RECIBO            ,
								PROVINCIA_CLIENTE_RECIBO            ,
								CPOSTAL_CLIENTE_RECIBO              ,
								IMPORTE_LETRA_RECIBO                ,
								INSTANTEALTA,
								INSTANTEMODIF,
								USUARIOALTA,
								USUARIOMODIF	)
				VALUES( pNRO_FACTURA                        ,
				        pSERIE_FACTURA                      ,
								1                                   ,
								pCODIGO_FORMAPAGO                   ,
								pFORMA_PAGO_FACTURA                 ,
								pTOTAL_LIQUIDO_FACTURA              ,
								'Pagado'                            ,
								pFECHA_FACTURA                      ,
								pFECHA_FACTURA                      ,
								pIBAN                               ,
								pFECHA_FACTURA                      ,
								pPOBLACION_EMPRESA                  ,
								pCODIGO_CLIENTE                     ,
								pRAZONSOCIAL_CLIENTE                ,
								pDIRECCION1_CLIENTE                 ,
								pPOBLACION_CLIENTE                  ,
								pPROVINCIA_CLIENTE                  ,
								pCPOSTAL_CLIENTE                    ,
								pIMPORTE_LETRA                      ,
								CURRENT_TIMESTAMP                   ,
								CURRENT_TIMESTAMP                   ,
								pUSUARIO                            ,
								pUSUARIO
							);
			END;
			ELSE 
			  IF (pN_PLAZOS >= 1) THEN
				BEGIN
			    SET I = 1;
					WHILE (I<=pN_PLAZOS) DO
					BEGIN
					      IF ((I = 1)) THEN 
								BEGIN
								  SET pFECHA_VENCIMIENTO  =  ADDDATE(pFECHA_FACTURA, INTERVAL pDIAS_ENTRE_PLAZOS DAY);
								  SET pIMPORTE_ANTICIPO = pTOTAL_LIQUIDO_FACTURA * (pPORCEN_ANTICIPO/100);
								  SET pIMPORTE_RESTO = (pTOTAL_LIQUIDO_FACTURA - pIMPORTE_ANTICIPO);
									/* SELECT pTOTAL_LIQUIDO_FACTURA, pIMPORTE_RESTO, pIMPORTE_ANTICIPO; */
								END;	
								END IF;									
								IF ((I= 1) AND (pPORCEN_ANTICIPO > 0)) THEN
									SET pIMPORTE_RECIBO = pIMPORTE_ANTICIPO;
								ELSE
								  IF pN_PLAZOS > 1 THEN 
									  /* SELECT pN_PLAZOS, pIMPORTE_RESTO, I AS iteracion; */
									  SET pIMPORTE_RECIBO = pIMPORTE_RESTO / (pN_PLAZOS);
									ELSE
										SET pIMPORTE_RECIBO = pIMPORTE_RESTO;
									END IF;
								END IF;
							  CALL PRC_GET_NUMEROS_A_LETRAS(pIMPORTE_RECIBO, pIMPORTE_LETRA);	
								IF (I <> 1) THEN
								  SET pFECHA_VENCIMIENTO = ADDDATE(pFECHA_VENCIMIENTO, INTERVAL pDIAS_ENTRE_PLAZOS DAY);
								END IF;
								INSERT INTO  fza_recibos 
												 (NRO_FACTURA_RECIBO					        ,
													SERIE_FACTURA_RECIBO                ,
													NRO_PLAZO_RECIBO                    ,
													FORMA_PAGO_ORIGEN_RECIBO            ,													
													FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO,
													EUROS_RECIBO                        ,
													STADO_RECIBO                       ,
													FECHA_EXPEDICION_RECIBO             ,
													FECHA_VENCIMIENTO_RECIBO            ,
													IBAN_CLIENTE_RECIBO                 ,
													FECHA_PAGO_RECIBO                   ,
													LOCALIDAD_EXPEDICION_RECIBO         ,
													CODIGO_CLIENTE_RECIBO               ,
													RAZONSOCIAL_CLIENTE_RECIBO          ,
													DIRECCION1_CLIENTE_RECIBO           ,
													POBLACION_CLIENTE_RECIBO            ,
													PROVINCIA_CLIENTE_RECIBO            ,
													CPOSTAL_CLIENTE_RECIBO              ,
													IMPORTE_LETRA_RECIBO                ,	
													INSTANTEALTA                        ,
													INSTANTEMODIF                       ,
          								USUARIOALTA                         ,
					          			USUARIOMODIF	)
								VALUES(   pNRO_FACTURA,
													pSERIE_FACTURA,
													I,
													pCODIGO_FORMAPAGO,										
													pFORMA_PAGO_FACTURA,
													pIMPORTE_RECIBO,
													'Emitido',
													pFECHA_FACTURA,
													pFECHA_VENCIMIENTO,
													pIBAN,
													NULL,
													pPOBLACION_EMPRESA,
													pCODIGO_CLIENTE,
													pRAZONSOCIAL_CLIENTE,
													pDIRECCION1_CLIENTE,
													pPOBLACION_CLIENTE,
													pPROVINCIA_CLIENTE,
													pCPOSTAL_CLIENTE,
													pIMPORTE_LETRA,
													CURRENT_TIMESTAMP,
													CURRENT_TIMESTAMP,
													pUSUARIO,
													PUSUARIO
												);
								SET I = I + 1;
					END;
					END WHILE;
				END;
				END IF;
			END IF;
		END;
		END IF;
		COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_CREAR_TRASPASO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_CREAR_TRASPASO`;
delimiter ;;
CREATE PROCEDURE `PRC_CREAR_TRASPASO`(IN pUsuario VARCHAR(50),
    IN pEmpresa VARCHAR(20),
    IN pAlmacenOrigen VARCHAR(10),
    IN pAlmacenDestino VARCHAR(10),
    IN pSku VARCHAR(50),
    IN pCantidad DECIMAL(19,6))
BEGIN
    DECLARE vSerie VARCHAR(20) DEFAULT 'TRAS';
    DECLARE vNroDoc VARCHAR(20);
    
    -- Generamos un número de documento único basado en la fecha y hora (simplificado)
    SET vNroDoc = DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');

    START TRANSACTION;

    -- 1. SALIDA DEL ORIGEN (Resta stock en Origen)
    INSERT INTO `fza_movimientos_almacen` 
    (TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV, LINEA_MOV, CODIGO_EMPRESA_MOV, 
     CODIGO_ALMACEN_MOV, CODIGO_ALMACEN_CONTRA_MOV, FECHA_MOV, 
     CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, 
     DESCRIPCION_ARTICULO_MOV, USUARIOALTA, USUARIOMODIF)
    VALUES 
    ('TR', vSerie, vNroDoc, '001', pEmpresa, 
     pAlmacenOrigen, pAlmacenDestino, NOW(), 
     pSku, 'S', pCantidad, 
     CONCAT('Traspaso a ', pAlmacenDestino), pUsuario, pUsuario);

    -- 2. ENTRADA EN DESTINO (Suma stock en Destino)
    -- Referenciamos al movimiento anterior para trazabilidad
    INSERT INTO `fza_movimientos_almacen` 
    (TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV, LINEA_MOV, CODIGO_EMPRESA_MOV, 
     CODIGO_ALMACEN_MOV, CODIGO_ALMACEN_CONTRA_MOV, FECHA_MOV, 
     CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, 
     DESCRIPCION_ARTICULO_MOV, USUARIOALTA, USUARIOMODIF,
     TIPO_DOC_REF_MOV, SERIE_DOC_REF_MOV, NRO_DOC_REF_MOV, LINEA_REF_MOV)
    VALUES 
    ('TR', vSerie, vNroDoc, '002', pEmpresa, 
     pAlmacenDestino, pAlmacenOrigen, NOW(), 
     pSku, 'E', pCantidad, 
     CONCAT('Traspaso desde ', pAlmacenOrigen), pUsuario, pUsuario,
     'TR', vSerie, vNroDoc, '001');

    COMMIT;
    
    SELECT CONCAT('Traspaso realizado. Doc: ', vSerie, '-', vNroDoc) as MENSAJE;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_FNC_GET_NEXT_LINEA_FACTURA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_FNC_GET_NEXT_LINEA_FACTURA`;
delimiter ;;
CREATE PROCEDURE `PRC_FNC_GET_NEXT_LINEA_FACTURA`(IN  `pnumfac` VARCHAR(12), 
    IN  `pserie`  VARCHAR(12), 
    OUT `presul`  VARCHAR(3))
BEGIN
    DECLARE v_temp VARCHAR(3);
    START TRANSACTION;
    
    -- 1. Buscamos el valor actual
    SELECT `CONTADOR_LINEAS_FACTURA` INTO v_temp
      FROM `fza_facturas`
     WHERE `NRO_FACTURA`  = `pnumfac`
       AND `SERIE_FACTURA` = `pserie`
       FOR UPDATE;
    
    -- 2. Si es NULL, vacío o '0', la primera línea será '010'
    IF (v_temp IS NULL OR v_temp = '' OR v_temp = '0') THEN
        SET v_temp = '010';
    END IF;
    
    -- 3. Asignamos a la salida el valor que acabamos de leer/calcular
    SET `presul` = v_temp;
    
    -- 4. Actualizamos la tabla sumando 10 para la PRÓXIMA línea
    UPDATE `fza_facturas`
       SET `CONTADOR_LINEAS_FACTURA` = LPAD((CAST(v_temp AS UNSIGNED) + 10), 3, '0')
     WHERE `SERIE_FACTURA` = `pserie`
       AND `NRO_FACTURA`   = `pnumfac`;
    
    COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_FNC_GET_NEXT_NRO_DOC
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_FNC_GET_NEXT_NRO_DOC`;
delimiter ;;
CREATE PROCEDURE `PRC_FNC_GET_NEXT_NRO_DOC`(IN  `ptipodoc` VARCHAR(8), 
                                             INOUT `ppresul`   BIGINT)
BEGIN
START TRANSACTION;
UPDATE `fza_contadores`
   SET `CONTADOR_CONTADOR` = CONTADOR_CONTADOR + 1
 WHERE `SERIE_CONTADOR` = '-'
   AND `TIPODOC_CONTADOR` = `pTipoDoc`;
  SET `ppresul` = (SELECT `CONTADOR_CONTADOR` - 1
                     FROM `fza_contadores`
                    WHERE `SERIE_CONTADOR` = '-'
                      AND `DEFAULT_CONTADOR` = 'S'
                      AND `TIPODOC_CONTADOR` = `pTipoDoc` 
                    LIMIT 1);
COMMIT;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_FNC_GET_PRECIO_ARTICULO_FECHA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_FNC_GET_PRECIO_ARTICULO_FECHA`;
delimiter ;;
CREATE PROCEDURE `PRC_FNC_GET_PRECIO_ARTICULO_FECHA`(IN  `pCODIGO_ARTICULO`              VARCHAR(20), 
																																								IN `pFECHA`                         DATE, 
                                                                                INOUT `pPRECIOSALIDA_TARIFA`        decimal(19,6),
																																								INOUT `pPRECIOFINAL_TARIFA`         decimal(19,6),
																																								INOUT `pPORCEN_DTO_TARIFA`         decimal(19,6),
																																								INOUT `pPRECIO_DTO_TARIFA`         decimal(19,6))
BEGIN
SELECT  PRECIOSALIDA_TARIFA,
			  PRECIOFINAL_TARIFA,
				PORCEN_DTO_TARIFA,
				PRECIO_DTO_TARIFA
	INTO 
				pPRECIOSALIDA_TARIFA,
				pPRECIOFINAL_TARIFA,
				pPORCEN_DTO_TARIFA,
				pPRECIO_DTO_TARIFA
	 FROM fza_articulos_tarifas
	 WHERE CODIGO_ARTICULO_TARIFA = pCODIGO_ARTICULO
	   AND FECHA_DESDE_TARIFA <= pFECHA 
	   AND (FECHA_HASTA_TARIFA IS NULL OR
					FECHA_HASTA_TARIFA >= pFECHA);
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_FNC_GET_SERIE_TIPODOC
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_FNC_GET_SERIE_TIPODOC`;
delimiter ;;
CREATE PROCEDURE `PRC_FNC_GET_SERIE_TIPODOC`(IN `ptipodoc` VARCHAR(8), 
                                                OUT `presul` VARCHAR(3))
BEGIN


DECLARE pserie varchar(3);
SET pserie = (select SERIE_CONTADOR
FROM fza_contadores
  where DEFAULT_CONTADOR = 'S'
and TIPODOC_CONTADOR = ptipodoc);
IF (pserie IS NULL) THEN
   SET presul = '-';
ELSE
   SET presul = pserie;
END IF;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GENERAR_CODIGO_VALE
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GENERAR_CODIGO_VALE`;
delimiter ;;
CREATE PROCEDURE `PRC_GENERAR_CODIGO_VALE`(IN pEmpresa VARCHAR(10),
    IN pAlmacen VARCHAR(10),
    IN pCaja VARCHAR(10),
    IN pNumOperacion VARCHAR(20),
    IN pUsuario VARCHAR(100),
    OUT pCodigoFinal VARCHAR(100))
BEGIN
    -- DECLARE vContador VARCHAR(20);
    
    -- 1. Obtenemos el contador secuencial (Le pasamos 'VL' y el Usuario)
    -- CALL PRC_GET_NEXT_CONT('VL', pUsuario, vContador);
    
    -- 2. Construimos el código final concatenando todo
    -- Resultado ejemplo: 00014_VL_1_ALM01_CAJ1_4509
    SET pCodigoFinal = CONCAT('VALE_', pEmpresa, '_', pAlmacen, '_', pCaja, '_', pNumOperacion);
    
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GETPERFILFORMULARIO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GETPERFILFORMULARIO`;
delimiter ;;
CREATE PROCEDURE `PRC_GETPERFILFORMULARIO`(IN `p_usuario` VARCHAR(200),
    IN `p_grupo` VARCHAR(200),
    IN `p_formulario` VARCHAR(100))
BEGIN
    -- Usamos una CTE para calcular la prioridad y luego filtrar
    WITH perfiles_con_prioridad AS (
        SELECT 
            USUARIO_GRUPO_PERFILES,
            KEY_PERFILES,
            SUBKEY_PERFILES,
            VALUE_PERFILES,
            VALUE_TEXT_PERFILES,
            TYPE_BLOB_PERFILES,
            VALUE_BLOB_PERFILES,
            CASE USUARIO_GRUPO_PERFILES
                WHEN p_usuario THEN 1
                WHEN p_grupo   THEN 2
                WHEN 'Todos'   THEN 3
            END AS prioridad,
            ROW_NUMBER() OVER (
                PARTITION BY SUBKEY_PERFILES 
                ORDER BY CASE USUARIO_GRUPO_PERFILES
                    WHEN p_usuario THEN 1
                    WHEN p_grupo   THEN 2
                    WHEN 'Todos'   THEN 3
                END
            ) AS rn
        FROM fza_usuarios_perfiles
        WHERE KEY_PERFILES = p_formulario 
          AND USUARIO_GRUPO_PERFILES IN (p_usuario, p_grupo, 'Todos')
    )
    SELECT 
        USUARIO_GRUPO_PERFILES,
        KEY_PERFILES,
        SUBKEY_PERFILES,
        VALUE_PERFILES,
        VALUE_TEXT_PERFILES,
        TYPE_BLOB_PERFILES,
        VALUE_BLOB_PERFILES
    FROM perfiles_con_prioridad
    WHERE rn = 1
    ORDER BY SUBKEY_PERFILES;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_CAJA_STOCK_PIVOTADO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;
    
    -- Variables para identificar qué es Talla (Pivot) y qué es Color (Grupo)
    DECLARE v_id_atributo_pivot VARCHAR(20); -- Ej: TAL
    DECLARE v_id_atributo_grupo VARCHAR(20); -- Ej: CO
    
    -- Variable para filtrar si entramos con un SKU específico (Ej: NEGRO)
    DECLARE v_valor_grupo_filtro VARCHAR(50) DEFAULT NULL;

    DECLARE v_columnas_dinamicas TEXT;
    DECLARE v_sql_query TEXT;

    -- 1. RESOLUCIÓN DE IDENTIDAD (¿Es Padre o SKU?)
    SELECT CODIGO_ARTICULO INTO v_codigo_articulo 
    FROM fza_articulos WHERE CODIGO_ARTICULO = p_input;

    IF v_codigo_articulo IS NULL THEN
        SELECT CODIGO_ARTICULO_SKU INTO v_codigo_articulo 
        FROM fza_articulos_skus WHERE CODIGO_UNIDAD_SKU = p_input;
        
        IF v_codigo_articulo IS NOT NULL THEN
            SET v_es_sku = TRUE;
        END IF;
    END IF;

    -- 2. ESTRATEGIA DE ATRIBUTOS
    -- Buscamos los 2 atributos más importantes. 
    -- Asumimos: Mayor Orden Visual = Pivot (Columnas/Talla), Segundo Orden = Grupo (Filas/Color)
    IF v_codigo_articulo IS NOT NULL THEN
        -- A. Identificar atributo para COLUMNAS (El de mayor orden, ej. Talla)
        SELECT va.ID_ATRIBUTO_VA INTO v_id_atributo_pivot
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SA
        JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
        JOIN fza_variaciones_atributos va ON av.ID_VA_AV = va.ID_ATRIBUTO_VA
        WHERE sk.CODIGO_ARTICULO_SKU = v_codigo_articulo
        ORDER BY va.ORDEN_VA DESC
        LIMIT 1;

        -- B. Identificar atributo para FILAS (El siguiente, ej. Color)
        SELECT va.ID_ATRIBUTO_VA INTO v_id_atributo_grupo
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SA
        JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
        JOIN fza_variaciones_atributos va ON av.ID_VA_AV = va.ID_ATRIBUTO_VA
        WHERE sk.CODIGO_ARTICULO_SKU = v_codigo_articulo
          AND va.ID_ATRIBUTO_VA <> v_id_atributo_pivot -- Que no sea el mismo que usamos para columnas
        ORDER BY va.ORDEN_VA DESC
        LIMIT 1;
    END IF;

    -- 3. SI TENEMOS ESTRUCTURA PARA PIVOTAR...
    IF v_id_atributo_pivot IS NOT NULL THEN
    
        -- 3.1 Si es SKU, detectamos el valor del atributo "Grupo" (Ej. detectar que es 'NEGRO')
        IF v_es_sku = TRUE AND v_id_atributo_grupo IS NOT NULL THEN
            SELECT av.VALOR_AV INTO v_valor_grupo_filtro
            FROM fza_atributos_sku ask
            JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
            WHERE ask.CODIGO_UNIDAD_SA = p_input -- El SKU exacto que escaneó el usuario
              AND av.ID_VA_AV = v_id_atributo_grupo;
        END IF;

        -- 3.2 Construir columnas dinámicas (S, M, L...) usando el alias 'av_p' (Atributo Pivot)
        SELECT GROUP_CONCAT(DISTINCT
            CONCAT(
                'SUM(CASE WHEN av_p.VALOR_AV = ''', REPLACE(av.VALOR_AV, "'", "''"), 
                ''' THEN stk.CANTIDAD_STK ELSE 0 END) AS `', REPLACE(av.VALOR_AV, "`", "``"), '`'
            )
            ORDER BY av.ID_VALOR_AV
        ) INTO v_columnas_dinamicas
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SA
        JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
        WHERE sk.CODIGO_ARTICULO_SKU = v_codigo_articulo
          AND av.ID_VA_AV = v_id_atributo_pivot;

        -- 3.3 Construir Query Final
        IF v_columnas_dinamicas IS NOT NULL THEN
            SET @sql = CONCAT(
                'SELECT 
                    -- Construimos el código: PADRE o PADRE/COLOR
                    CONCAT(''', v_codigo_articulo, ''', 
                        CASE 
                            WHEN av_g.VALOR_AV IS NOT NULL THEN CONCAT(''/'', av_g.VALOR_AV) 
                            ELSE '''' 
                        END
                    ) AS Codigo,
                    alm.NOMBRE_ALMACEN_ALM AS Almacen, ', 
                    v_columnas_dinamicas, ',
                    SUM(stk.CANTIDAD_STK) AS Total
                 FROM fza_articulos_stockactual stk
                 JOIN fza_almacenes alm ON stk.CODIGO_ALMACEN_STK = alm.CODIGO_ALMACEN_ALM
                 JOIN fza_articulos_skus sk ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
                 
                 -- JOIN 1: Para obtener el valor de la columna (Talla) -> av_p
                 JOIN fza_atributos_sku ask_p ON sk.CODIGO_UNIDAD_SKU = ask_p.CODIGO_UNIDAD_SA
                 JOIN fza_atributos_valores av_p ON ask_p.ID_VALOR_SA = av_p.ID_VALOR_AV 
                    AND av_p.ID_VA_AV = ''', v_id_atributo_pivot, '''
                 
                 -- JOIN 2: Para obtener el valor de la fila (Color) -> av_g
                 LEFT JOIN fza_atributos_sku ask_g ON sk.CODIGO_UNIDAD_SKU = ask_g.CODIGO_UNIDAD_SA
                 LEFT JOIN fza_atributos_valores av_g ON ask_g.ID_VALOR_SA = av_g.ID_VALOR_AV 
                    AND av_g.ID_VA_AV = ''', IFNULL(v_id_atributo_grupo, 'xxx'), '''

                 WHERE sk.CODIGO_ARTICULO_SKU = ''', v_codigo_articulo, '''
                 -- Si hay filtro de grupo (ej. escaneó NEGRO), filtramos aquí
                 ', CASE WHEN v_valor_grupo_filtro IS NOT NULL THEN 
                        CONCAT(' AND av_g.VALOR_AV = ''', REPLACE(v_valor_grupo_filtro, "'", "''"), ''' ') 
                        ELSE '' END, '
                 
                 GROUP BY av_g.VALOR_AV, alm.NOMBRE_ALMACEN_ALM
                 ORDER BY alm.NOMBRE_ALMACEN_ALM, av_g.VALOR_AV'
            );

            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            SET v_id_atributo_pivot = NULL; -- Evitar entrar al fallback
        END IF;
    END IF;

    -- CASO B: FALLBACK (Si no tiene atributos complejos)
    IF v_id_atributo_pivot IS NOT NULL OR v_columnas_dinamicas IS NULL THEN 
        SELECT stk.CODIGO_UNIDAD_STK as Codigo,  
            alm.NOMBRE_ALMACEN_ALM as Almacen, 
            SUM(stk.CANTIDAD_STK) as Stock_Total
        FROM fza_articulos_stockactual stk
        JOIN fza_almacenes alm ON stk.CODIGO_ALMACEN_STK = alm.CODIGO_ALMACEN_ALM
        WHERE stk.CODIGO_UNIDAD_STK = p_input 
        GROUP BY alm.NOMBRE_ALMACEN_ALM
        ORDER BY alm.NOMBRE_ALMACEN_ALM;
    END IF;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;
    DECLARE v_id_atributo_pivot VARCHAR(20);
    DECLARE v_nombre_atributo_pivot VARCHAR(50);
    DECLARE v_columnas_dinamicas TEXT;
    DECLARE v_filtros_fijos TEXT DEFAULT '';
    DECLARE v_sql_query TEXT;

    -- 1. IDENTIFICAR ARTÍCULO O SKU
    SELECT CODIGO_ARTICULO INTO v_codigo_articulo 
    FROM fza_articulos WHERE CODIGO_ARTICULO = p_input;

    IF v_codigo_articulo IS NULL THEN
        SELECT CODIGO_ARTICULO_SKU INTO v_codigo_articulo 
        FROM fza_articulos_skus WHERE CODIGO_UNIDAD_SKU = p_input;
        
        IF v_codigo_articulo IS NOT NULL THEN SET v_es_sku = TRUE; END IF;
    END IF;

    -- 2. BUSCAR ATRIBUTO PIVOTE
    IF v_codigo_articulo IS NOT NULL THEN
        SELECT va.ID_ATRIBUTO_VA, va.NOMBRE_VA
        INTO v_id_atributo_pivot, v_nombre_atributo_pivot
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SA
        JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
        JOIN fza_variaciones_atributos va ON av.ID_VA_AV = va.ID_ATRIBUTO_VA
        WHERE sk.CODIGO_ARTICULO_SKU = v_codigo_articulo
        ORDER BY va.ORDEN_VA DESC
        LIMIT 1;
    END IF;

    -- 3. CONSTRUCCIÓN DE LA CONSULTA
    IF v_id_atributo_pivot IS NOT NULL THEN
        -- CASO A: CON ATRIBUTOS (PIVOT)
        
        -- Generamos columnas dinámicas apuntando a la subconsulta 'src'
        SELECT GROUP_CONCAT(DISTINCT
            CONCAT(
                'SUM(CASE WHEN src.VALOR_AV = ''', av.VALOR_AV, 
                ''' THEN src.CANTIDAD_STK ELSE 0 END) AS `', av.VALOR_AV, '`'
            )
            ORDER BY av.ID_VALOR_AV
        ) INTO v_columnas_dinamicas
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SA
        JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
        WHERE sk.CODIGO_ARTICULO_SKU = v_codigo_articulo
          AND av.ID_VA_AV = v_id_atributo_pivot;

        -- Filtros SKU
        IF v_es_sku = TRUE THEN
            SELECT GROUP_CONCAT(
                CONCAT(
                    ' AND EXISTS (SELECT 1 FROM fza_atributos_sku f_ask ',
                    ' JOIN fza_atributos_valores f_av ON f_ask.ID_VALOR_SA = f_av.ID_VALOR_AV ',
                    ' WHERE f_ask.CODIGO_UNIDAD_SA = sk.CODIGO_UNIDAD_SKU ',
                    ' AND f_av.ID_VA_AV = ''', av.ID_VA_AV, ''' ',
                    ' AND f_av.VALOR_AV = ''', av.VALOR_AV, ''') '
                ) SEPARATOR ' '
            ) INTO v_filtros_fijos
            FROM fza_atributos_sku ask
            JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
            WHERE ask.CODIGO_UNIDAD_SA = p_input 
              AND av.ID_VA_AV <> v_id_atributo_pivot;
        END IF;
        IF v_filtros_fijos IS NULL THEN SET v_filtros_fijos = ''; END IF;

        -- QUERY FINAL: Desde Almacenes LEFT JOIN Subconsulta de Stock
        SET @sql = CONCAT(
            'SELECT 
                alm.NOMBRE_ALMACEN_ALM AS Almacen, ', 
                v_columnas_dinamicas, ',
                COALESCE(SUM(src.CANTIDAD_STK), 0) AS Total
             FROM fza_almacenes alm
             LEFT JOIN (
                SELECT stk.CODIGO_ALMACEN_STK, av.VALOR_AV, stk.CANTIDAD_STK
                FROM fza_articulos_stockactual stk
                JOIN fza_articulos_skus sk ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
                JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SA
                JOIN fza_atributos_valores av ON ask.ID_VALOR_SA = av.ID_VALOR_AV
                WHERE sk.CODIGO_ARTICULO_SKU = ''', v_codigo_articulo, '''
                  AND av.ID_VA_AV = ''', v_id_atributo_pivot, ''' ',
                  v_filtros_fijos, '
             ) src ON alm.CODIGO_ALMACEN_ALM = src.CODIGO_ALMACEN_STK
             WHERE alm.ESACTIVO_ALM = ''S'' 
             GROUP BY alm.NOMBRE_ALMACEN_ALM
             ORDER BY alm.NOMBRE_ALMACEN_ALM'
        );

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSE
        -- CASO B: ARTÍCULO SIMPLE (Sin atributos)
        SELECT 
            alm.NOMBRE_ALMACEN_ALM as Almacen, 
            COALESCE(SUM(stk.CANTIDAD_STK), 0) as `Stock Total`
        FROM fza_almacenes alm
        LEFT JOIN fza_articulos_stockactual stk 
            ON alm.CODIGO_ALMACEN_ALM = stk.CODIGO_ALMACEN_STK
            AND stk.CODIGO_UNIDAD_STK = p_input -- Filtro en el ON para no romper el LEFT JOIN
        WHERE alm.ESACTIVO_ALM = 'S'
        GROUP BY alm.NOMBRE_ALMACEN_ALM
        ORDER BY alm.NOMBRE_ALMACEN_ALM;
        
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_CREAR_VALOR
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_CREAR_VALOR`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_CREAR_VALOR`(IN `p_id_va` VARCHAR(20),       -- Tipo de Variación (ej: 'CO')
    IN `p_valor` VARCHAR(100),      -- El valor escrito (ej: 'VERDE LIMA')
    IN `p_usuario` VARCHAR(100),    -- Usuario que hace la acción
    OUT `p_id_resultado` INT)
BEGIN
    -- 1. Intentamos buscar el ID si ya existe
    SELECT `ID_VALOR_AV` INTO p_id_resultado
    FROM `fza_atributos_valores`
    WHERE `ID_VA_AV` = p_id_va 
      AND UPPER(`VALOR_AV`) = UPPER(p_valor) -- Comparamos ignorando mayúsculas
    LIMIT 1;

    -- 2. Si p_id_resultado sigue siendo NULL, significa que no existe. LO CREAMOS.
    IF p_id_resultado IS NULL THEN
        INSERT INTO `fza_atributos_valores` (
            `ID_VA_AV`, 
            `VALOR_AV`, 
            `USUARIOALTA`, 
            `USUARIOMODIF`, 
            `INSTANTEALTA`
        ) VALUES (
            p_id_va, 
            p_valor, 
            p_usuario, 
            p_usuario, 
            NOW()
        );
        
        -- Obtenemos el ID que se acaba de generar
        SET p_id_resultado = LAST_INSERT_ID();
    END IF;

    -- Al final, p_id_resultado siempre tiene un número válido (viejo o nuevo).
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_DATA_ARTICULO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_DATA_ARTICULO`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_DATA_ARTICULO`(IN `pidcodarticulo` varchar(200), 
                                         OUT `pidnomarticulo` varchar(1000), 
                                         OUT `ptipoiva` varchar(2))
BEGIN
   IF( EXISTS(
             SELECT *
               FROM `fza_articulos`
              WHERE `CODIGO_ARTICULO` =  `pidcodarticulo`) ) THEN
  BEGIN
    SELECT `DESCRIPCION_ARTICULO`, `TIPOIVA_ARTICULO` 
      INTO `pidnomarticulo`, `ptipoiva`
      FROM `fza_articulos`
     WHERE `CODIGO_ARTICULO` = `pidcodarticulo`;
  END;
  ELSE
  BEGIN
    SET `pidnomarticulo` = 'NO EXISTE';
    SET `ptipoiva` = 'N';
  END;
  END IF;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_DATA_CLIENTE
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_DATA_CLIENTE`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_DATA_CLIENTE`(IN `pCODIGO_CLIENTE`                    varchar(10),
                         OUT `pRAZONSOCIAL_CLIENTE`               varchar(200),
                         OUT `pNIF_CLIENTE`                       varchar(50),
                         OUT `pCODIGO_ZONA_IVA_CLIENTE`           int,
                         OUT `pMOVIL_CLIENTE`                     varchar(40),
                         OUT `pESIVA_RECARGO_CLIENTE`             varchar(1),
                         OUT `pESRETENCIONES_CLIENTE`             varchar(1),
                         OUT `pESIVA_EXENTO_CLIENTE`              varchar(1),
                         OUT `pESINTRACOMUNITARIO_CLIENTE`        varchar(1),
                         OUT `pESREGIMENESPECIALAGRICOLA_CLIENTE` varchar(1),
                         OUT `pEMAIL_CLIENTE`                     varchar(200),
                         OUT `pDIRECCION1_CLIENTE`                varchar(200),
                         OUT `pDIRECCION2_CLIENTE`                varchar(200),
                         OUT `pPOBLACION_CLIENTE`                 varchar(200),
                         OUT `pPROVINCIA_CLIENTE`                 varchar(200),
                         OUT `pCPOSTAL_CLIENTE`                   varchar(15),
                         OUT `pTARIFA_ARTICULO_CLIENTE`           varchar(10),
                         OUT `pTEXTO_LEGAL_FACTURA_CLIENTE`       varchar(1000),
                         OUT `pPAIS_CLIENTE`                      varchar(150),
												 OUT `pCOD_PAIS_CLIENTE`                      varchar(150))
BEGIN
   IF( EXISTS(
             SELECT *
             FROM `fza_clientes`
             WHERE `CODIGO_CLIENTE` =  `pCODIGO_CLIENTE`) ) THEN
  BEGIN
    SELECT  `RAZONSOCIAL_CLIENTE`               ,
            `NIF_CLIENTE`                       ,
            `CODIGO_ZONA_IVA_CLIENTE`           ,
            `ESIVA_RECARGO_CLIENTE`             ,
            `ESRETENCIONES_CLIENTE`             ,
            `ESIVA_EXENTO_CLIENTE`              ,
            `ESINTRACOMUNITARIO_CLIENTE`        ,
            `ESREGIMENESPECIALAGRICOLA_CLIENTE` ,
            `MOVIL_CLIENTE`                     ,
            `EMAIL_CLIENTE`                     ,
            `DIRECCION1_CLIENTE`                ,
            `DIRECCION2_CLIENTE`                ,
            `POBLACION_CLIENTE`                 ,
            `PROVINCIA_CLIENTE`                 ,
            `CPOSTAL_CLIENTE`                   ,
            `TARIFA_ARTICULO_CLIENTE`           ,
            `TEXTO_LEGAL_FACTURA_CLIENTE`       ,
            `NOMBRE_PAIS_CLIENTE`               ,
						`CODIGO_PAIS_CLIENTE`    
      INTO  `pRAZONSOCIAL_CLIENTE`              ,
            `pNIF_CLIENTE`                      ,
            `pCODIGO_ZONA_IVA_CLIENTE`          ,
            `pESIVA_RECARGO_CLIENTE`            ,
            `pESRETENCIONES_CLIENTE`            ,
            `pESIVA_EXENTO_CLIENTE`             ,
            `pESINTRACOMUNITARIO_CLIENTE`       ,
            `pESREGIMENESPECIALAGRICOLA_CLIENTE`,
            `pMOVIL_CLIENTE`                    ,
            `pEMAIL_CLIENTE`                    ,
            `pDIRECCION1_CLIENTE`               ,
            `pDIRECCION2_CLIENTE`               ,
            `pPOBLACION_CLIENTE`                ,
            `pPROVINCIA_CLIENTE`                ,
            `pCPOSTAL_CLIENTE`                  ,
            `pTARIFA_ARTICULO_CLIENTE`          ,
            `pTEXTO_LEGAL_FACTURA_CLIENTE`      ,
            `pPAIS_CLIENTE`                     ,
						`pCOD_PAIS_CLIENTE`
      FROM `fza_clientes`
     WHERE `CODIGO_CLIENTE` =  `pCODIGO_CLIENTE`;
  END;
  ELSE
  BEGIN
    SET `pRAZONSOCIAL_CLIENTE` = 'CLIENTE NO ENCONTRADO';
  END;
  END IF;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_IVA_ZONA_FECHA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_IVA_ZONA_FECHA`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_IVA_ZONA_FECHA`(IN `pFECHA` DATE, 
                                       IN `pZONA` INT, 
                                       OUT `pRESUL` INT, 
                                       OUT `pEXENTO_IVA` DECIMAL(18,6), 
                                       OUT `pEXENTO_RE_IVA` DECIMAL(18,6), 
                                       OUT `pNORMAL_IVA` DECIMAL(18,6), 
                                       OUT `pNORMAL_RE_IVA` DECIMAL(18,6), 
                                       OUT `pREDUCIDO_IVA` DECIMAL(18,6), 
                                       OUT `pREDUCIDO_RE_IVA` DECIMAL(18,6), 
                                       OUT `pSUPERREDUCIDO_IVA` DECIMAL(18,6), 
                                       OUT `pSUPERREDUCIDO_RE_IVA` DECIMAL(18,6))
BEGIN
    IF( EXISTS(
             SELECT *
               FROM fza_ivas
              WHERE FECHA_DESDE_IVA >=  FECHA
                AND (FECHA_HASTA_IVA <= FECHA 
                 OR FECHA_HASTA_IVA IS NULL)
                AND  GRUPO_ZONA_IVA = pZONA)) THEN
  SELECT `PORCENEXENTO_IVA` ,
         `PORCENEXENTO_RE_IVA`,
         `PORCENNORMAL_IVA` ,
         `PORCENNORMAL_RE_IVA`,
         `PORCENREDUCIDO_IVA` ,
         `PORCENREDUCIDO_RE_IVA` ,
         `PORCENSUPERREDUCIDO_IVA` ,
         `PORCENSUPERREDUCIDO_RE_IVA`
    INTO
         pEXENTO_IVA,
         pEXENTO_RE_IVA,
         pNORMAL_IVA ,
         pNORMAL_RE_IVA,
         pREDUCIDO_IVA,
         pREDUCIDO_RE_IVA ,
         pSUPERREDUCIDO_IVA,
         pSUPERREDUCIDO_RE_IVA
    FROM fza_ivas
   WHERE (FECHA_DESDE_IVA >=  FECHA
     AND (FECHA_HASTA_IVA <= FECHA OR 
          FECHA_HASTA_IVA IS NULL))
     AND CODIGO_ZONA_IVA = pZONA;
ELSE
    SELECT `PORCENEXENTO_IVA` ,
           `PORCENEXENTO_RE_IVA`,
           `PORCENNORMAL_IVA` ,
           `PORCENNORMAL_RE_IVA`,
           `PORCENREDUCIDO_IVA` ,
           `PORCENREDUCIDO_RE_IVA` ,
           `PORCENSUPERREDUCIDO_IVA` ,
           `PORCENSUPERREDUCIDO_RE_IVA`
       INTO
            pEXENTO_IVA,
            pEXENTO_RE_IVA,
            pNORMAL_IVA ,
            pNORMAL_RE_IVA,
            pREDUCIDO_IVA,
            pREDUCIDO_RE_IVA ,
            pSUPERREDUCIDO_IVA,
            pSUPERREDUCIDO_RE_IVA
      FROM  fza_ivas
     WHERE (FECHA_DESDE_IVA >=  FECHA
       AND FECHA_HASTA_IVA IS NULL )
       AND CODIGO_ZONA_IVA = pZONA;
  END IF;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_NEXT_CONT
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_CONT`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_NEXT_CONT`(IN  pTipoDoc varchar(2), 
                                         IN  pUSUARIO_MODIF varchar(100),
                                         OUT pcont varchar(20))
BEGIN
DECLARE pPADD bigint;
DECLARE pEMPRESA_CONTADOR varchar(10);
START TRANSACTION;
  IF ( pEMPRESA_CONTADOR = '' OR pEMPRESA_CONTADOR IS NULL ) THEN 
	  SET pEMPRESA_CONTADOR = '-'; 
	END IF;

  IF( NOT( EXISTS(
             SELECT *
             FROM fza_contadores
             WHERE `TIPODOC_CONTADOR` =  pTipoDoc
						   AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR) ) ) THEN
    BEGIN
      INSERT INTO fza_contadores (TIPODOC_CONTADOR, 
                                  SERIE_CONTADOR,
																  EMPRESA_CONTADOR,	
                                  CONTADOR_CONTADOR, 
                                  DEFAULT_CONTADOR,
                                  NUMDIGIT_CONTADOR,
                                  INSTANTEALTA, 
                                  USUARIOALTA,
                                  USUARIOMODIF) 
                          VALUES
                                 (pTipoDoc, 
                                  '-', 
																	pEMPRESA_CONTADOR,
                                   1, 
                                  'S', 
                                   3,
                                  CURRENT_TIMESTAMP,
                                  pUSUARIO_MODIF, 
                                  pUSUARIO_MODIF);
    END;
    END IF;
    SET pPADD = (SELECT NUMDIGIT_CONTADOR 
                   FROM fza_contadores 
                  WHERE TIPODOC_CONTADOR = pTipoDoc 
									  AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR
                    AND DEFAULT_CONTADOR = 'S' 
                  LIMIT 1);
     
     UPDATE fza_contadores 
        SET CONTADOR_CONTADOR = CONTADOR_CONTADOR + 1,
            USUARIOMODIF = pUSUARIO_MODIF
      WHERE TIPODOC_CONTADOR = pTipoDoc
			  AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR;            
      SELECT LPAD( (SELECT CONTADOR_CONTADOR - 1 
                      FROM fza_contadores         
                     WHERE TIPODOC_CONTADOR = pTipoDoc 
										   AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR
                     LIMIT 1) , pPADD, '0') INTO pcont;
COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_NEXT_CONT_FACT_SERIE
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_CONT_FACT_SERIE`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_NEXT_CONT_FACT_SERIE`(IN  `pserie` VARCHAR(12), 
                                                                           IN  `pTipoDoc` VARCHAR(2), 
																																					 IN  `pEMPRESA_CONTADOR` VARCHAR(10), 
																																					 IN  `pUSUARIOMODIF` varchar(100),
																																					 OUT `pcont` varchar(12))
BEGIN
DECLARE pNUMDIGIT varchar(12);
START TRANSACTION;
  IF ( pEMPRESA_CONTADOR = ''  OR pEMPRESA_CONTADOR IS NULL) THEN 
	  SET pEMPRESA_CONTADOR = '-'; 
	END IF;
  IF( NOT( EXISTS(
             SELECT *
             FROM fza_contadores
             WHERE `TIPODOC_CONTADOR` =  pTipoDoc
						   AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR
						   AND `SERIE_CONTADOR` = pserie) ) ) THEN
	BEGIN
	   INSERT INTO fza_contadores (TIPODOC_CONTADOR, 
		                            SERIE_CONTADOR, 
																CONTADOR_CONTADOR, 
																EMPRESA_CONTADOR,
																DEFAULT_CONTADOR,
																NUMDIGIT_CONTADOR,
																INSTANTEALTA, 
																USUARIOALTA,
																USUARIOMODIF) 
												VALUES
																(pTipoDoc, 
																 pserie, 
																 1, 
																 pEMPRESA_CONTADOR,
																 'N', 
																 6,
																 CURRENT_TIMESTAMP,
																 pUSUARIOMODIF, 
																 pUSUARIOMODIF);
	END;
	END IF;

UPDATE fza_contadores
    SET CONTADOR_CONTADOR = CONTADOR_CONTADOR + 1
  WHERE SERIE_CONTADOR = pserie
		  AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR
      AND TIPODOC_CONTADOR = pTipoDoc;
  
	SELECT CONTADOR_CONTADOR - 1 , 
 	 			 NUMDIGIT_CONTADOR
		INTO pcont,
				 pNUMDIGIT
	  from fza_contadores
	 where SERIE_CONTADOR = pserie
		 and TIPODOC_CONTADOR = pTipoDoc
		 AND EMPRESA_CONTADOR = pEMPRESA_CONTADOR 
		 LIMIT 1;
		 
 IF (NOT(pNUMDIGIT IS NULL) AND (pNUMDIGIT <> 0)) THEN
   SET pcont = LPAD(pcont, pNUMDIGIT, '0');
 END IF;								 

COMMIT;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_NEXT_OP_CAJA
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_NEXT_OP_CAJA`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_NEXT_OP_CAJA`(IN  pEmpresa  VARCHAR(10),
    IN  pAlmacen  VARCHAR(10),
    IN  pCaja     VARCHAR(10),
    IN  pUsuario  VARCHAR(100),
    OUT pSerie    VARCHAR(12),
    OUT pcont     VARCHAR(20))
BEGIN
    DECLARE pPADD    BIGINT;
    DECLARE vSerie   VARCHAR(12);

    START TRANSACTION;

        -- 1. Obtener serie vigente
        SELECT SERIE_SERIE
          INTO vSerie
          FROM fza_empresas_series
         WHERE TIPODOC_SERIE        = 'OV'
           AND CODIGO_EMPRESA_SERIE = pEmpresa
           AND CODIGO_ALMACEN_SERIE = pAlmacen
           AND CODIGO_CAJA_SERIE    = pCaja
           AND FECHA_DESDE_SERIE   <= CURDATE()
           AND (FECHA_HASTA_SERIE  >= CURDATE() OR FECHA_HASTA_SERIE IS NULL)
         LIMIT 1;

        IF vSerie IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'No existe serie OV vigente para esta empresa/almacen/caja';
        END IF;

        -- 2. Crear fila de contador si no existe
        IF NOT EXISTS (
            SELECT 1
              FROM fza_contadores
             WHERE TIPODOC_CONTADOR = 'OV'
               AND EMPRESA_CONTADOR = pEmpresa
               AND SERIE_CONTADOR   = vSerie
        ) THEN
            INSERT INTO fza_contadores (
                TIPODOC_CONTADOR,
                EMPRESA_CONTADOR,
                SERIE_CONTADOR,
                CONTADOR_CONTADOR,
                NUMDIGIT_CONTADOR,
                ACTIVO_CONTADOR,
                DEFAULT_CONTADOR,
                INSTANTEALTA,
                USUARIOALTA,
                USUARIOMODIF)
            VALUES (
                'OV',
                pEmpresa,
                vSerie,
                1,
                8,
                'S',
                'S',
                CURRENT_TIMESTAMP,
                pUsuario,
                pUsuario);
        END IF;

        -- 3. Bloquear fila y leer dígitos
        SELECT NUMDIGIT_CONTADOR
          INTO pPADD
          FROM fza_contadores
         WHERE TIPODOC_CONTADOR = 'OV'
           AND EMPRESA_CONTADOR = pEmpresa
           AND SERIE_CONTADOR   = vSerie
         LIMIT 1
           FOR UPDATE;

        -- 4. Incrementar
        UPDATE fza_contadores
           SET CONTADOR_CONTADOR = CONTADOR_CONTADOR + 1,
               USUARIOMODIF      = pUsuario
         WHERE TIPODOC_CONTADOR  = 'OV'
           AND EMPRESA_CONTADOR  = pEmpresa
           AND SERIE_CONTADOR    = vSerie;

        -- 5. Devolver serie y número formateado
        SET pSerie := vSerie;

        SELECT LPAD(CONTADOR_CONTADOR - 1, pPADD, '0')
          INTO pcont
          FROM fza_contadores
         WHERE TIPODOC_CONTADOR = 'OV'
           AND EMPRESA_CONTADOR = pEmpresa
           AND SERIE_CONTADOR   = vSerie
         LIMIT 1;

    COMMIT;

END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_NUMEROS_A_LETRAS
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_NUMEROS_A_LETRAS`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_NUMEROS_A_LETRAS`(IN NUMERO DECIMAL(12,2), OUT pResul varchar(200))
BEGIN
	DECLARE MILLARES INT;
	DECLARE CENTENAS INT;
	DECLARE CENTIMOS INT;
	DECLARE CENTIMO_AUX VARCHAR(200);
	DECLARE CENTIMO_AUX_CON VARCHAR(200);
	DECLARE MIL_AUX VARCHAR(200);
	DECLARE EN_LETRAS VARCHAR(200);
	DECLARE ENTERO INT;
	DECLARE AUX VARCHAR(15);
	DECLARE INTER VARCHAR(200);
	
	SET EN_LETRAS = '';
	SET CENTIMO_AUX_CON = '';
	SET ENTERO = TRUNCATE(NUMERO,0);
	SET MILLARES = TRUNCATE(ENTERO / 1000,0);
	SET CENTENAS = ENTERO MOD 1000;
	SET CENTIMOS = (TRUNCATE(NUMERO,2) * 100) MOD 100;
	
	IF ((MILLARES = 1)) THEN
		SET EN_LETRAS = 'MIL ';
	ELSE 
		IF (MILLARES > 0) THEN
        CALL PRC_GET_NUMERO_MENOR_MIL(MILLARES, INTER); 
				SET EN_LETRAS = CONCAT(EN_LETRAS , INTER ,'MIL ');
				SET EN_LETRAS = REPLACE(EN_LETRAS,'UNO ','UN ');
		END IF;
	END IF;
	
	IF ((CENTENAS > 0) OR ((ENTERO = 0) AND (CENTIMOS = 0))) THEN
		BEGIN
      CALL PRC_GET_NUMERO_MENOR_MIL(CENTENAS, INTER);
			SET EN_LETRAS = CONCAT(EN_LETRAS, INTER);			
		END;
	END IF;
	IF (CENTIMOS > 0) THEN
	BEGIN
		IF (CENTIMOS = 1) THEN
			SET  AUX = 'CÉNTIMO ';
		ELSE
			SET AUX = 'CÉNTIMOS ';
		END IF;	
		IF (CENTIMOS > 0) THEN
            CALL PRC_GET_NUMERO_MENOR_MIL(CENTIMOS, INTER);
			SET CENTIMO_AUX = INTER;
			SET CENTIMO_AUX = REPLACE(CENTIMO_AUX,'UNO ','UN '); 
			IF ENTERO <> 0 THEN 
			  SET CENTIMO_AUX_CON = 'CON ' ; 
			END IF;
			SET EN_LETRAS = CONCAT(EN_LETRAS, CENTIMO_AUX_CON, CENTIMO_AUX , AUX);
		ELSE
			SET EN_LETRAS = CONCAT(EN_LETRAS, CENTIMO_AUX, AUX);		
		END IF;
	END;
	END IF;
	SET pResul = EN_LETRAS;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_GET_NUMERO_MENOR_MIL
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_NUMERO_MENOR_MIL`;
delimiter ;;
CREATE PROCEDURE `PRC_GET_NUMERO_MENOR_MIL`(IN NUMERO DECIMAL(4), OUT pResul varchar(100))
BEGIN
       DECLARE CENTENAS INT;
       DECLARE DECENAS INT;
       DECLARE UNIDADES INT;
       DECLARE EN_LETRAS VARCHAR(100);
       DECLARE UNIR VARCHAR(2);
			 SET EN_LETRAS = '';
        IF (NUMERO = 100) THEN
            SET pResul = ('CIEN ');
        ELSEIF NUMERO = 0 THEN
            SET pResul = ('CERO ');
        ELSEIF NUMERO = 1 THEN
            SET pResul = ('UNO ');
        ELSE
            SET CENTENAS = TRUNCATE(NUMERO / 100,0);
            SET DECENAS  = TRUNCATE((NUMERO MOD 100)/10,0);
            SET UNIDADES = NUMERO MOD 10;
            SET UNIR = 'Y ';
            
						IF CENTENAS = 1 THEN
                SET EN_LETRAS = 'CIENTO ';
            ELSEIF CENTENAS = 2 THEN
                SET EN_LETRAS = 'DOSCIENTOS ';
            ELSEIF CENTENAS = 3 THEN
                SET EN_LETRAS = 'TRESCIENTOS ';
            ELSEIF CENTENAS = 4 THEN
                SET EN_LETRAS = 'CUATROCIENTOS ';
            ELSEIF CENTENAS = 5 THEN
                SET EN_LETRAS = 'QUINIENTOS ';
            ELSEIF CENTENAS = 6 THEN
                SET EN_LETRAS = 'SEISCIENTOS ';
            ELSEIF CENTENAS = 7 THEN
                SET EN_LETRAS = 'SETECIENTOS ';
            ELSEIF CENTENAS = 8 THEN
                SET EN_LETRAS = 'OCHOCIENTOS ';
            ELSEIF CENTENAS = 9 THEN
                SET EN_LETRAS = 'NOVECIENTOS ';
            END IF;
            
						IF DECENAS = 3 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'TREINTA ');
            ELSEIF DECENAS = 4 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'CUARENTA ');
            ELSEIF DECENAS = 5 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'CINCUENTA ');
            ELSEIF DECENAS = 6 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'SESENTA ');
            ELSEIF DECENAS = 7 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'SETENTA ');
            ELSEIF DECENAS = 8 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'OCHENTA ');
            ELSEIF DECENAS = 9 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , 'NOVENTA ');
            ELSEIF DECENAS = 1 THEN
                IF UNIDADES < 6 THEN
                    IF UNIDADES = 0 THEN
                        SET EN_LETRAS = CONCAT(EN_LETRAS , 'DIEZ ');
                    ELSEIF UNIDADES = 1 THEN
                        SET EN_LETRAS = CONCAT(EN_LETRAS , 'ONCE ');
                    ELSEIF UNIDADES = 2 THEN
                        SET EN_LETRAS = CONCAT(EN_LETRAS , 'DOCE ');
                    ELSEIF UNIDADES = 3 THEN
                        SET EN_LETRAS = CONCAT(EN_LETRAS , 'TRECE ');
                    ELSEIF UNIDADES = 4 THEN
                        SET EN_LETRAS = CONCAT(EN_LETRAS , 'CATORCE ');
                    ELSEIF UNIDADES = 5 THEN
                        SET EN_LETRAS = CONCAT(EN_LETRAS , 'QUINCE ');
                    END IF;
                    SET UNIDADES = 0;
                ELSE
                    SET EN_LETRAS = CONCAT(EN_LETRAS, 'DIECI');
                    SET UNIR = '';
                END IF;
            ELSEIF (DECENAS = 2) THEN
                IF (UNIDADES = 0) THEN
                    SET EN_LETRAS = CONCAT(EN_LETRAS, 'VEINTE ');
                ELSE
                    SET EN_LETRAS = CONCAT(EN_LETRAS, 'VEINTI');
                END IF;
                SET UNIR = '';
            ELSEIF (DECENAS = 0) THEN
                SET UNIR = '';
            END IF;
						
            IF (UNIDADES = 1) THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'UNO ');
            ELSEIF UNIDADES = 2 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'DOS ');
            ELSEIF UNIDADES = 3 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'TRES ');
            ELSEIF UNIDADES = 4 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'CUATRO ');
            ELSEIF UNIDADES = 5 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'CINCO ');
            ELSEIF UNIDADES = 6 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'SEIS ');
            ELSEIF UNIDADES = 7 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'SIETE ');
            ELSEIF UNIDADES = 8 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS, UNIR, 'OCHO ');
            ELSEIF UNIDADES = 9 THEN
                SET EN_LETRAS = CONCAT(EN_LETRAS , UNIR , 'NUEVE ');
            END IF;
        END IF;
        SET pResul = EN_LETRAS;
    END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_REALIZAR_TRASPASO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_REALIZAR_TRASPASO`;
delimiter ;;
CREATE PROCEDURE `PRC_REALIZAR_TRASPASO`(IN pUsuario VARCHAR(50),
    IN pEmpresa VARCHAR(20),
    IN pAlmacenOrigen VARCHAR(10),
    IN pAlmacenDestino VARCHAR(10),
    IN pSku VARCHAR(50),
    IN pCantidad DECIMAL(19,6))
BEGIN
    DECLARE vSerie VARCHAR(20) DEFAULT 'TRAS';
    DECLARE vNroDoc VARCHAR(20);
    
    -- Generamos un número de documento único basado en la fecha y hora (simplificado)
    SET vNroDoc = DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');

    START TRANSACTION;

    -- 1. SALIDA DEL ORIGEN (Resta stock en Origen)
    INSERT INTO `fza_movimientos_almacen` 
    (TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV, LINEA_MOV, CODIGO_EMPRESA_MOV, 
     CODIGO_ALMACEN_MOV, CODIGO_ALMACEN_CONTRA_MOV, FECHA_MOV, 
     CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, 
     DESCRIPCION_ARTICULO_MOV, USUARIOALTA, USUARIOMODIF)
    VALUES 
    ('TR', vSerie, vNroDoc, '001', pEmpresa, 
     pAlmacenOrigen, pAlmacenDestino, NOW(), 
     pSku, 'S', pCantidad, 
     CONCAT('Traspaso a ', pAlmacenDestino), pUsuario, pUsuario);

    -- 2. ENTRADA EN DESTINO (Suma stock en Destino)
    -- Referenciamos al movimiento anterior para trazabilidad
    INSERT INTO `fza_movimientos_almacen` 
    (TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV, LINEA_MOV, CODIGO_EMPRESA_MOV, 
     CODIGO_ALMACEN_MOV, CODIGO_ALMACEN_CONTRA_MOV, FECHA_MOV, 
     CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, 
     DESCRIPCION_ARTICULO_MOV, USUARIOALTA, USUARIOMODIF,
     TIPO_DOC_REF_MOV, SERIE_DOC_REF_MOV, NRO_DOC_REF_MOV, LINEA_REF_MOV)
    VALUES 
    ('TR', vSerie, vNroDoc, '002', pEmpresa, 
     pAlmacenDestino, pAlmacenOrigen, NOW(), 
     pSku, 'E', pCantidad, 
     CONCAT('Traspaso desde ', pAlmacenOrigen), pUsuario, pUsuario,
     'TR', vSerie, vNroDoc, '001');

    COMMIT;
    
    SELECT CONCAT('Traspaso realizado. Doc: ', vSerie, '-', vNroDoc) as MENSAJE;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_RECALCULAR_STOCK
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_RECALCULAR_STOCK`;
delimiter ;;
CREATE PROCEDURE `PRC_RECALCULAR_STOCK`()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- En caso de error, deshacer cambios
        ROLLBACK;
        SELECT 'ERROR: No se pudo recalcular el stock' as MENSAJE;
    END;

    START TRANSACTION;
    
        -- Borramos la tabla de saldos
        DELETE FROM fza_articulos_stockactual;
        
        -- Volcamos los datos recalculados
        INSERT INTO fza_articulos_stockactual 
        (CODIGO_ALMACEN_STK, CODIGO_UNIDAD_STK, CANTIDAD_STK, INSTANTEMODIF)
        SELECT 
            CODIGO_ALMACEN_MOV,
            CODIGO_UNIDAD_MOV,
            SUM(IF(TIPO_MOVIMIENTO_MOV = 'E', CANTIDAD_MOV, -CANTIDAD_MOV)),
            NOW()
        FROM fza_movimientos_almacen
        GROUP BY CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV;
        
    COMMIT;
    
    SELECT 'Stock recalculado correctamente.' as MENSAJE;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for PRC_SETPERFILFORMULARIO
-- ----------------------------
DROP PROCEDURE IF EXISTS `PRC_SETPERFILFORMULARIO`;
delimiter ;;
CREATE PROCEDURE `PRC_SETPERFILFORMULARIO`(IN p_usuario_grupo  VARCHAR(200),
    IN p_formulario     VARCHAR(100),
    IN p_subkey         VARCHAR(100),
    IN p_value          VARCHAR(200))
BEGIN
    INSERT INTO fza_usuarios_perfiles 
        (USUARIO_GRUPO_PERFILES, KEY_PERFILES, SUBKEY_PERFILES, 
         VALUE_PERFILES, INSTANTEMODIF, INSTANTEALTA, USUARIOMODIF, USUARIOALTA)
    VALUES 
        (p_usuario_grupo, p_formulario, p_subkey, 
         p_value, NOW(), NOW(), p_usuario_grupo, p_usuario_grupo)
    ON DUPLICATE KEY UPDATE
        VALUE_PERFILES  = p_value,
        INSTANTEMODIF   = NOW(),
        USUARIOMODIF    = p_usuario_grupo;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for SP_RECALCULAR_PMP_SKU
-- ----------------------------
DROP PROCEDURE IF EXISTS `SP_RECALCULAR_PMP_SKU`;
delimiter ;;
CREATE PROCEDURE `SP_RECALCULAR_PMP_SKU`(IN `p_CodigoEmpresa` VARCHAR(20),
    IN `p_CodigoSKU` VARCHAR(50),
    IN `p_FechaDesde` DATETIME)
BEGIN
    -- Variables para el bucle
    DECLARE done INT DEFAULT FALSE;
    DECLARE vIdTipo VARCHAR(5);
    DECLARE vIdSerie VARCHAR(20);
    DECLARE vIdNro VARCHAR(20);
    DECLARE vIdLinea VARCHAR(4);
    
    DECLARE vTipoMov VARCHAR(1);
    DECLARE vCantidad DECIMAL(19,6);
    DECLARE vPrecioCoste DECIMAL(19,6);
    
    -- Variables para el cálculo acumulado
    DECLARE vStockAcumulado DECIMAL(19,6) DEFAULT 0;
    DECLARE vPMP_Actual DECIMAL(19,6) DEFAULT 0;
    
    -- CURSOR: Seleccionamos TODOS los movimientos de ese SKU ordenados cronológicamente
    -- Es vital incluir movimientos ANTERIORES a la fecha para coger el saldo inicial correcto
    DECLARE curMovimientos CURSOR FOR 
        SELECT 
            TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV, LINEA_MOV,
            TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, PRECIO_COSTE_UNITARIO_MOV, FECHA_MOV
        FROM fza_movimientos_almacen
        WHERE CODIGO_EMPRESA_MOV = p_CodigoEmpresa
          AND CODIGO_UNIDAD_MOV = p_CodigoSKU
        ORDER BY FECHA_MOV ASC, INSTANTEALTA ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 1. Inicialización: Limpiamos variables
    SET vStockAcumulado = 0;
    SET vPMP_Actual = 0;

    OPEN curMovimientos;

    read_loop: LOOP
        FETCH curMovimientos INTO vIdTipo, vIdSerie, vIdNro, vIdLinea, vTipoMov, vCantidad, vPrecioCoste, p_FechaDesde; -- Reusamos p_FechaDesde solo para leer fecha, no afecta lógica
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- ---------------------------------------------------------
        -- LÓGICA DE CÁLCULO (Idéntica a la del Trigger, pero en bucle)
        -- ---------------------------------------------------------
        
        IF vTipoMov = 'E' THEN
            -- Es ENTRADA
            -- Si el stock venía de negativo o cero, reiniciamos precio
            IF vStockAcumulado <= 0 THEN
                SET vPMP_Actual = vPrecioCoste;
            ELSE
                -- Fórmula PMP
                SET vPMP_Actual = (
                    (vStockAcumulado * vPMP_Actual) + (vCantidad * vPrecioCoste)
                ) / (vStockAcumulado + vCantidad);
            END IF;
            
            -- Actualizamos el Stock Acumulado sumando
            SET vStockAcumulado = vStockAcumulado + vCantidad;
            
        ELSE
            -- Es SALIDA
            -- El PMP no cambia, se mantiene el que traíamos
            -- Pero el stock baja
            SET vStockAcumulado = vStockAcumulado - vCantidad;
        END IF;

        -- ---------------------------------------------------------
        -- ACTUALIZACIÓN DE LA FILA
        -- ---------------------------------------------------------
        -- Actualizamos el campo PRECIO_MEDIO_MOV de esta fila específica
        -- Nota: Esto disparará el Trigger UPDATE. Para evitar bucles,
        -- el trigger UPDATE debería detectar si el valor ya es igual para no hacer nada,
        -- o deshabilitar triggers temporalmente si fuera necesario.
        
        UPDATE fza_movimientos_almacen 
        SET PRECIO_MEDIO_MOV = vPMP_Actual
        WHERE TIPO_DOC_MOV = vIdTipo 
          AND SERIE_DOC_MOV = vIdSerie
          AND NRO_DOC_MOV = vIdNro
          AND LINEA_MOV = vIdLinea;
          
    END LOOP;

    CLOSE curMovimientos;
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for SP_RECALCULAR_PMP_SKU_ALMACEN
-- ----------------------------
DROP PROCEDURE IF EXISTS `SP_RECALCULAR_PMP_SKU_ALMACEN`;
delimiter ;;
CREATE PROCEDURE `SP_RECALCULAR_PMP_SKU_ALMACEN`(IN `p_CodigoEmpresa` VARCHAR(20),
    IN `p_CodigoSKU` VARCHAR(50),
    IN `p_CodigoAlmacen` VARCHAR(10))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE vIdTipo, vIdSerie, vIdNro, vIdLinea VARCHAR(20);
    DECLARE vTipoMov VARCHAR(1);
    DECLARE vCantidad, vPrecioCoste DECIMAL(19,6);
    
    -- Variables de cálculo
    DECLARE vStockAcumulado DECIMAL(19,6) DEFAULT 0;
    DECLARE vValorAcumulado DECIMAL(19,6) DEFAULT 0; -- Usar valor total es más preciso
    DECLARE vPMP_Actual DECIMAL(19,6) DEFAULT 0;

    -- CURSOR: Filtrado estrictamente por Almacén
    DECLARE curMovimientos CURSOR FOR 
        SELECT 
               TIPO_DOC_MOV, SERIE_DOC_MOV, NRO_DOC_MOV, LINEA_MOV,
               TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, PRECIO_COSTE_UNITARIO_MOV
        FROM   fza_movimientos_almacen
        WHERE  CODIGO_EMPRESA_MOV = p_CodigoEmpresa
          AND  CODIGO_UNIDAD_MOV = p_CodigoSKU
          AND  CODIGO_ALMACEN_MOV = p_CodigoAlmacen
        ORDER BY FECHA_MOV ASC, INSTANTEALTA ASC 
          FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN curMovimientos;

    read_loop: LOOP
        FETCH curMovimientos INTO vIdTipo, vIdSerie, vIdNro, vIdLinea, vTipoMov, vCantidad, vPrecioCoste;
        IF done THEN
            LEAVE read_loop;
        END IF;

        IF vTipoMov = 'E' THEN
            -- ENTRADA: Actualizamos stock y valor acumulado
            SET vStockAcumulado = vStockAcumulado + vCantidad;
            SET vValorAcumulado = vValorAcumulado + (vCantidad * vPrecioCoste);
            
            -- Recalcular PMP (evitando división por cero)
            IF vStockAcumulado > 0 THEN
                SET vPMP_Actual = vValorAcumulado / vStockAcumulado;
            ELSE
                SET vPMP_Actual = vPrecioCoste;
            END IF;
        ELSE
            -- SALIDA: El PMP no cambia, pero el valor acumulado baja proporcionalmente
            -- Importante: La salida debe valorarse al PMP que tenemos en ese momento
            SET vValorAcumulado = vValorAcumulado - (vCantidad * vPMP_Actual);
            SET vStockAcumulado = vStockAcumulado - vCantidad;
        END IF;

        -- Actualizar el movimiento con el PMP calculado en ese instante
        UPDATE fza_movimientos_almacen 
        SET PRECIO_MEDIO_MOV = vPMP_Actual,
            TOTAL_COSTE_MOV = IF(vTipoMov = 'E', vCantidad * vPrecioCoste, vCantidad * vPMP_Actual)
        WHERE TIPO_DOC_MOV = vIdTipo 
          AND SERIE_DOC_MOV = vIdSerie
          AND NRO_DOC_MOV = vIdNro
          AND LINEA_MOV = vIdLinea;
          
    END LOOP;

    CLOSE curMovimientos;

    -- AL FINAL: Sincronizar la tabla de stock actual con los resultados finales
    INSERT INTO fza_articulos_stockactual 
        (CODIGO_ALMACEN_STK, CODIGO_UNIDAD_STK, CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTEMODIF)
    VALUES (p_CodigoAlmacen, p_CodigoSKU, vStockAcumulado, vValorAcumulado, vPMP_Actual, NOW())
    ON DUPLICATE KEY UPDATE 
        CANTIDAD_STK = vStockAcumulado,
        VALOR_TOTAL_STK = vValorAcumulado,
        PRECIO_MEDIO_STK = vPMP_Actual,
        INSTANTEMODIF = NOW();

END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table fza_depositos_cliente
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_fza_depositos_after_insert`;
delimiter ;;
CREATE TRIGGER `trg_fza_depositos_after_insert` AFTER INSERT ON `fza_depositos_cliente` FOR EACH ROW BEGIN
    DECLARE v_deuda_generada DECIMAL(19,6) DEFAULT 0;

    -- Solo generamos deuda si el depósito nace con estado 'PENDIENTE'
    IF NEW.ESTADO_DEP = 'PENDIENTE' THEN
        
        -- Calculamos la deuda: (Precio * Cantidad) - Anticipo
        -- Usamos COALESCE por si la cantidad viene a NULL, asumimos 1.
        SET v_deuda_generada = (NEW.PRECIO_VENTA_DEP * COALESCE(NEW.CANTIDAD_PENDIENTE_DEP, 1)) - NEW.IMPORTE_ANTICIPO_DEP;

        -- Si hay una deuda real a favor de la empresa, actualizamos el cliente
        IF v_deuda_generada > 0 THEN
            UPDATE fza_clientes
            SET TOTAL_DEUDA_CLIENTE = COALESCE(TOTAL_DEUDA_CLIENTE, 0) + v_deuda_generada
            WHERE CODIGO_CLIENTE = NEW.CODIGO_CLIENTE_DEP;
        END IF;
        
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table fza_depositos_cliente
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_fza_depositos_after_update`;
delimiter ;;
CREATE TRIGGER `trg_fza_depositos_after_update` AFTER UPDATE ON `fza_depositos_cliente` FOR EACH ROW BEGIN
    DECLARE v_deuda_antigua DECIMAL(19,6) DEFAULT 0;
    DECLARE v_deuda_nueva DECIMAL(19,6) DEFAULT 0;
    DECLARE v_diferencia DECIMAL(19,6) DEFAULT 0;

    -- 1. Calculamos la deuda que tenía el depósito ANTES de guardar
    -- Solo contabiliza si antes estaba PENDIENTE
    IF OLD.ESTADO_DEP = 'PENDIENTE' THEN
        SET v_deuda_antigua = (OLD.PRECIO_VENTA_DEP * COALESCE(OLD.CANTIDAD_PENDIENTE_DEP, 1)) - OLD.IMPORTE_ANTICIPO_DEP;
    END IF;

    -- 2. Calculamos la deuda que tiene el depósito AHORA (con los nuevos datos)
    -- Si pasa a estar CERRADO o CANCELADO, esto no se ejecuta y v_deuda_nueva se queda en 0
    IF NEW.ESTADO_DEP = 'PENDIENTE' THEN
        SET v_deuda_nueva = (NEW.PRECIO_VENTA_DEP * COALESCE(NEW.CANTIDAD_PENDIENTE_DEP, 1)) - NEW.IMPORTE_ANTICIPO_DEP;
    END IF;

    -- 3. Comprobamos si el cliente sigue siendo el mismo
    IF OLD.CODIGO_CLIENTE_DEP = NEW.CODIGO_CLIENTE_DEP THEN
        
        -- Misma persona: Solo sumamos/restamos la diferencia si ha cambiado el importe o el estado
        SET v_diferencia = v_deuda_nueva - v_deuda_antigua;
        
        IF v_diferencia <> 0 THEN
            UPDATE fza_clientes
            SET TOTAL_DEUDA_CLIENTE = COALESCE(TOTAL_DEUDA_CLIENTE, 0) + v_diferencia
            WHERE CODIGO_CLIENTE = NEW.CODIGO_CLIENTE_DEP;
        END IF;

    ELSE
        -- Han cambiado el cliente del depósito (Poco común, pero evita descuadres)
        
        -- Restamos la deuda antigua al cliente anterior
        IF v_deuda_antigua <> 0 THEN
            UPDATE fza_clientes
            SET TOTAL_DEUDA_CLIENTE = COALESCE(TOTAL_DEUDA_CLIENTE, 0) - v_deuda_antigua
            WHERE CODIGO_CLIENTE = OLD.CODIGO_CLIENTE_DEP;
        END IF;
        
        -- Sumamos la deuda nueva al nuevo cliente
        IF v_deuda_nueva <> 0 THEN
            UPDATE fza_clientes
            SET TOTAL_DEUDA_CLIENTE = COALESCE(TOTAL_DEUDA_CLIENTE, 0) + v_deuda_nueva
            WHERE CODIGO_CLIENTE = NEW.CODIGO_CLIENTE_DEP;
        END IF;
        
    END IF;

END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table fza_movimientos_almacen
-- ----------------------------
DROP TRIGGER IF EXISTS `TRG_MOVIMIENTOS_BI`;
delimiter ;;
CREATE TRIGGER `TRG_MOVIMIENTOS_BI` BEFORE INSERT ON `fza_movimientos_almacen` FOR EACH ROW BEGIN
    DECLARE vStockActual DECIMAL(19,6) DEFAULT 0;
    DECLARE vValorActual DECIMAL(19,6) DEFAULT 0;
    DECLARE vPMPActual   DECIMAL(19,6) DEFAULT 0;

    -- -------------------------------------------------------------------------
    -- 1. Obtener stock y PMP actuales para este almacén + SKU.
    --    FOR UPDATE bloquea la fila durante la transacción para evitar
    --    condiciones de carrera en entornos multiusuario.
    -- -------------------------------------------------------------------------
    SELECT IFNULL(CANTIDAD_STK,     0),
           IFNULL(VALOR_TOTAL_STK,  0),
           IFNULL(PRECIO_MEDIO_STK, 0)
      INTO vStockActual, vValorActual, vPMPActual
      FROM fza_articulos_stockactual
     WHERE CODIGO_ALMACEN_STK = NEW.CODIGO_ALMACEN_MOV
       AND CODIGO_UNIDAD_STK  = NEW.CODIGO_UNIDAD_MOV
     LIMIT 1 FOR UPDATE;

    -- -------------------------------------------------------------------------
    -- 2. Lógica según tipo de movimiento
    -- -------------------------------------------------------------------------
    IF NEW.TIPO_MOVIMIENTO_MOV = 'E' THEN

        -- ENTRADA ------------------------------------------------------------
        -- Si no viene coste informado (traspaso interno, entrada a depósito,
        -- devolución de depósito a tienda...) usar el PMP vigente como coste
        -- para no distorsionar el precio medio ponderado.
        IF NEW.PRECIO_COSTE_UNITARIO_MOV = 0 AND vPMPActual > 0 THEN
            SET NEW.PRECIO_COSTE_UNITARIO_MOV = vPMPActual;
        END IF;

        SET NEW.TOTAL_COSTE_MOV = NEW.CANTIDAD_MOV * NEW.PRECIO_COSTE_UNITARIO_MOV;

        -- Recalcular PMP: (ValorAcumulado + NuevoValor) / (StockActual + NuevaCantidad)
        IF (vStockActual + NEW.CANTIDAD_MOV) != 0 THEN
            SET NEW.PRECIO_MEDIO_MOV = (vValorActual + NEW.TOTAL_COSTE_MOV)
                                     / (vStockActual + NEW.CANTIDAD_MOV);
        ELSE
            -- Stock resultante = 0: conservar el coste unitario como referencia
            SET NEW.PRECIO_MEDIO_MOV = NEW.PRECIO_COSTE_UNITARIO_MOV;
        END IF;

    ELSE

        -- SALIDA -------------------------------------------------------------
        -- El coste de la salida es siempre el PMP vigente.
        -- PRECIO_COSTE_UNITARIO_MOV puede llegar a 0 desde la aplicación,
        -- el trigger lo corrige aquí.
        SET NEW.PRECIO_MEDIO_MOV  = vPMPActual;
        SET NEW.TOTAL_COSTE_MOV   = NEW.CANTIDAD_MOV * vPMPActual;

    END IF;

    -- -------------------------------------------------------------------------
    -- 3. Actualizar tabla de stock actual (INSERT ... ON DUPLICATE KEY UPDATE)
    --    La clave única es (CODIGO_ALMACEN_STK, CODIGO_UNIDAD_STK).
    -- -------------------------------------------------------------------------
    INSERT INTO fza_articulos_stockactual
        (CODIGO_ALMACEN_STK, CODIGO_UNIDAD_STK,
         CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK,
         INSTANTEMODIF)
    VALUES (
        NEW.CODIGO_ALMACEN_MOV,
        NEW.CODIGO_UNIDAD_MOV,
        IF(NEW.TIPO_MOVIMIENTO_MOV = 'E',  NEW.CANTIDAD_MOV, -NEW.CANTIDAD_MOV),
        IF(NEW.TIPO_MOVIMIENTO_MOV = 'E',  NEW.TOTAL_COSTE_MOV, -NEW.TOTAL_COSTE_MOV),
        NEW.PRECIO_MEDIO_MOV,
        NOW()
    )
    ON DUPLICATE KEY UPDATE
        CANTIDAD_STK    = CANTIDAD_STK    + IF(NEW.TIPO_MOVIMIENTO_MOV = 'E',  NEW.CANTIDAD_MOV,    -NEW.CANTIDAD_MOV),
        VALOR_TOTAL_STK = VALOR_TOTAL_STK + IF(NEW.TIPO_MOVIMIENTO_MOV = 'E',  NEW.TOTAL_COSTE_MOV, -NEW.TOTAL_COSTE_MOV),
        PRECIO_MEDIO_STK = NEW.PRECIO_MEDIO_MOV,
        INSTANTEMODIF    = NOW();

END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
