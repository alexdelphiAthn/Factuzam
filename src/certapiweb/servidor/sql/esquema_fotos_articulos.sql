-- ============================================================================
--  Fotos de artículo que viajan dentro del evento de venta.
--
--  Idempotente. Base de datos: la del webservice (api_*).
--
--  Hasta ahora las fotos solo llegaban por el subsistema fotos_nube, que es
--  independiente y hay que montar aparte. Con esta tabla la foto viaja en el
--  propio evento de venta, así que el listado móvil funciona sin depender de
--  que esa otra pieza esté en marcha ni de tener el ámbito fotos:leer.
--
--  Una fila por (referencia, artículo, clave de unidad), NO por línea de
--  venta: el mismo artículo vendido cien veces guarda una sola foto. La
--  clave de unidad replica fza_articulos_fotos.CODIGO_UNIDAD_FOT:
--  '' = foto del artículo, ART/COLOR = foto de color, ART/COLOR/TALLA = SKU.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `api_articulos_fotos` (
  `referencia` varchar(100) NOT NULL,
  `codigo_articulo` varchar(20) NOT NULL,
  `clave_unidad` varchar(50) NOT NULL DEFAULT '',
  `nombre_archivo` varchar(255) NOT NULL,
  `tipo_mime` varchar(100) NOT NULL DEFAULT 'image/png',
  `tamano_bytes` bigint unsigned NOT NULL,
  `huella_sha256` char(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `contenido` longblob NOT NULL,
  `instante_alta` datetime NOT NULL,
  `instante_modif` datetime NOT NULL,
  PRIMARY KEY (`referencia`, `codigo_articulo`, `clave_unidad`),
  KEY `idx_api_art_fotos_articulo` (`referencia`, `codigo_articulo`),
  KEY `idx_api_art_fotos_huella` (`huella_sha256`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
