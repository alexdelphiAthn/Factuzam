CREATE TABLE IF NOT EXISTS `api_credenciales` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `referencia` varchar(100) NOT NULL,
  `token_hash` char(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `token_prefijo` varchar(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `ambitos` text NOT NULL,
  `id_clave_emisora` varchar(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'ACTIVA',
  `instante_alta` datetime NOT NULL,
  `instante_ultimo_uso` datetime DEFAULT NULL,
  `instante_revocacion` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_credenciales_referencia` (`referencia`),
  UNIQUE KEY `uq_api_credenciales_token_hash` (`token_hash`),
  KEY `idx_api_credenciales_estado` (`estado`),
  KEY `idx_api_credenciales_emisora` (`id_clave_emisora`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
CREATE TABLE IF NOT EXISTS `api_nonces_admin` (
  `id_clave` varchar(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `nonce` varchar(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `instante_alta` datetime NOT NULL,
  PRIMARY KEY (`id_clave`, `nonce`),
  KEY `idx_api_nonces_admin_instante` (`instante_alta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
CREATE TABLE IF NOT EXISTS `api_instalaciones_sif` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `referencia` varchar(100) NOT NULL,
  `numero_instalacion` varchar(60) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `codigo_sif` varchar(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `version_actual` varchar(60) NOT NULL,
  `razon_social_ultima` varchar(200) NOT NULL,
  `nif_ultimo` varchar(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `instante_alta` datetime NOT NULL,
  `instante_modif` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_api_sif_referencia` (`referencia`),
  UNIQUE KEY `uq_api_sif_numero` (`numero_instalacion`),
  KEY `idx_api_sif_codigo` (`codigo_sif`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
