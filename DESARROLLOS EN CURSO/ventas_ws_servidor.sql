-- Almacenamiento remoto de eventos y proyecciones de ventas.
-- Ejecutar en la base de datos del servidor CertApiWeb.
CREATE TABLE IF NOT EXISTS `api_ventas_eventos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `id_credencial` bigint unsigned NOT NULL,
  `referencia` varchar(100) NOT NULL,
  `id_evento` char(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `secuencia_evento` bigint unsigned NOT NULL,
  `tipo_evento` varchar(30) NOT NULL,
  `codigo_empresa` varchar(20) NOT NULL,
  `serie_factura` varchar(20) NOT NULL,
  `numero_factura` varchar(20) NOT NULL,
  `version_contrato` int unsigned NOT NULL,
  `huella_contenido` char(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `contenido_json` longtext NOT NULL,
  `instante_generacion` datetime DEFAULT NULL,
  `instante_recepcion` datetime NOT NULL,
  `id_peticion` varchar(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_ventas_evento` (`referencia`, `id_evento`),
  KEY `idx_api_ventas_eventos_documento`
    (`referencia`, `codigo_empresa`, `serie_factura`, `numero_factura`),
  KEY `idx_api_ventas_eventos_secuencia`
    (`referencia`, `secuencia_evento`),
  KEY `idx_api_ventas_eventos_recepcion` (`instante_recepcion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
CREATE TABLE IF NOT EXISTS `api_ventas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `referencia` varchar(100) NOT NULL,
  `codigo_empresa` varchar(20) NOT NULL,
  `serie_factura` varchar(20) NOT NULL,
  `numero_factura` varchar(20) NOT NULL,
  `ultima_secuencia` bigint unsigned NOT NULL,
  `ultimo_tipo_evento` varchar(30) NOT NULL,
  `ultimo_id_evento` char(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `cabecera_json` longtext NOT NULL,
  `pagos_factura_json` longtext NOT NULL,
  `recibos_json` longtext NOT NULL,
  `efectos_venta_json` longtext NOT NULL,
  `pagos_caja_json` longtext NOT NULL,
  `operaciones_caja_json` longtext NOT NULL,
  `movimientos_almacen_json` longtext NOT NULL,
  `vales_json` longtext NOT NULL,
  `depositos_json` longtext NOT NULL,
  `relaciones_json` longtext NOT NULL,
  `fiscal_json` longtext NOT NULL,
  `instante_alta` datetime NOT NULL,
  `instante_modif` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_ventas_documento`
    (`referencia`, `codigo_empresa`, `serie_factura`, `numero_factura`),
  KEY `idx_api_ventas_modif` (`instante_modif`),
  KEY `idx_api_ventas_tipo` (`ultimo_tipo_evento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
CREATE TABLE IF NOT EXISTS `api_ventas_lineas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `id_venta` bigint unsigned NOT NULL,
  `orden_linea` int unsigned NOT NULL,
  `datos_json` longtext NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_ventas_lineas_orden` (`id_venta`, `orden_linea`),
  KEY `idx_api_ventas_lineas_venta` (`id_venta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
CREATE TABLE IF NOT EXISTS `api_ventas_documentos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `id_venta` bigint unsigned NOT NULL,
  `tipo_documento` varchar(30) NOT NULL,
  `nombre_archivo` varchar(255) NOT NULL,
  `tipo_mime` varchar(100) NOT NULL,
  `tamano_bytes` bigint unsigned NOT NULL,
  `huella_sha256` char(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `contenido` longblob NOT NULL,
  `id_evento` char(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `secuencia_evento` bigint unsigned NOT NULL,
  `instante_alta` datetime NOT NULL,
  `instante_modif` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_ventas_documento_tipo` (`id_venta`, `tipo_documento`),
  KEY `idx_api_ventas_documentos_huella` (`huella_sha256`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
