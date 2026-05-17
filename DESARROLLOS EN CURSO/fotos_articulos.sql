-- ============================================================================
-- Fotos de Articulo / SKU
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
--
-- Tabla de seguimiento de las fotos guardadas en disco bajo la carpeta de
-- parametros `appDirFotos`.  Las imagenes reales viven en el sistema de
-- ficheros (300 px, 600 px y original); la BBDD solo recuerda que un
-- articulo o SKU tiene foto y bajo que nombre.
--
-- Fallback: un SKU sin foto hereda la del articulo padre (fila con
-- CODIGO_UNIDAD_FOT = '').
-- ============================================================================

-- ---------------------------------------------------------------------------
-- IDEMPOTENCIA
-- ---------------------------------------------------------------------------
-- Re-ejecutable: DROP TABLE IF EXISTS + CREATE TABLE.  No incluye datos.
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS `fza_articulos_fotos`;
CREATE TABLE `fza_articulos_fotos` (
  `CODIGO_ART_FOT`        varchar(20)  NOT NULL
      COMMENT 'FK logica fza_articulos.CODIGO_ART_ART',
  `CODIGO_UNIDAD_FOT`     varchar(50)  NOT NULL DEFAULT ''
      COMMENT 'FK logica fza_articulos_skus.CODIGO_UNIDAD_SKU. '''' = foto del articulo',
  `NOMBRE_FOT_FOT`        varchar(255) NOT NULL
      COMMENT 'Nombre base del fichero (sin sufijo de tamaño ni extension)',
  `EXTENSION_ORIGEN_FOT`  varchar(10)  NOT NULL DEFAULT 'png'
      COMMENT 'Extension del fichero real, sin punto (png, jpg, jpeg, ...)',
  `INSTANTE_MODIF`        timestamp    NOT NULL
      DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`         timestamp    NOT NULL
      DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`          varchar(100) NOT NULL,
  `USUARIO_MODIF`         varchar(100) NOT NULL,
  PRIMARY KEY (`CODIGO_ART_FOT`, `CODIGO_UNIDAD_FOT`)
);
ALTER TABLE `fza_articulos_fotos`
  ADD INDEX `IDX_FOT_SKU` (`CODIGO_UNIDAD_FOT`);

-- ---------------------------------------------------------------------------
-- Vista vi_articulos_fotos
-- ---------------------------------------------------------------------------
-- Une fotos de SKU con la foto del articulo padre, exponiendo siempre la
-- mejor coincidencia (SKU > articulo).  Mantiene el patron de la vista
-- vi_articulos_tarifas: una sola consulta por (articulo, sku) devuelve la
-- foto vigente con su origen (SKU o ARTICULO).
-- ---------------------------------------------------------------------------

DROP VIEW IF EXISTS `vi_articulos_fotos`;
CREATE ALGORITHM=UNDEFINED VIEW `vi_articulos_fotos` AS
SELECT
  `sku`.`CODIGO_ART_SKU`             AS `CODIGO_ART`,
  `sku`.`CODIGO_UNIDAD_SKU`          AS `CODIGO_UNIDAD_SKU`,
  COALESCE(`fs`.`NOMBRE_FOT_FOT`,
           `fa`.`NOMBRE_FOT_FOT`)    AS `NOMBRE_FOT`,
  COALESCE(`fs`.`EXTENSION_ORIGEN_FOT`,
           `fa`.`EXTENSION_ORIGEN_FOT`) AS `EXTENSION_ORIGEN_FOT`,
  CASE
    WHEN `fs`.`NOMBRE_FOT_FOT` IS NOT NULL THEN 'SKU'
    WHEN `fa`.`NOMBRE_FOT_FOT` IS NOT NULL THEN 'ARTICULO'
    ELSE NULL
  END                                AS `ORIGEN_FOT`
FROM `fza_articulos_skus` `sku`
LEFT JOIN `fza_articulos_fotos` `fs`
       ON `fs`.`CODIGO_ART_FOT`    = `sku`.`CODIGO_ART_SKU`
      AND `fs`.`CODIGO_UNIDAD_FOT` = `sku`.`CODIGO_UNIDAD_SKU`
LEFT JOIN `fza_articulos_fotos` `fa`
       ON `fa`.`CODIGO_ART_FOT`    = `sku`.`CODIGO_ART_SKU`
      AND `fa`.`CODIGO_UNIDAD_FOT` = '';
