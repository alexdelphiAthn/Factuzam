-- =============================================================================
-- Recrea vi_caja_busqueda_unificada sin anular los indices
-- =============================================================================
-- Requisito: las tablas base deben usar utf8mb4_spanish_ci. Ejecutar antes
-- normalizar_colaciones_spanish.sql si la verificacion de ese script devuelve
-- tablas pendientes.
--
-- No aplicar CONVERT ni COLLATE a las columnas de filtros o JOIN. Esas
-- funciones impiden usar los indices y llegan a bloquear la caja con el
-- catalogo real. Idempotente: CREATE OR REPLACE puede repetirse.
-- =============================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_caja_busqueda_unificada` AS
SELECT `a`.`CODIGO_ART_ART` AS `INPUT_BUSQUEDA`,
       _utf8mb4'CODIGO' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_articulos` `a`
 WHERE `a`.`ESACTIVO_ART` = 'S'
UNION ALL
SELECT `sku`.`CODIGO_UNIDAD_SKU` AS `INPUT_BUSQUEDA`,
       _utf8mb4'SKU' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       `sku`.`CODIGO_UNIDAD_SKU` AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_articulos_skus` `sku`
  JOIN `fza_articulos` `a`
    ON `sku`.`CODIGO_ART_SKU` = `a`.`CODIGO_ART_ART`
 WHERE `sku`.`ESACTIVO_SKU` = 'S'
UNION ALL
SELECT `cb`.`CODIGO_BARRAS_CB` AS `INPUT_BUSQUEDA`,
       _utf8mb4'EAN' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       `sku`.`CODIGO_UNIDAD_SKU` AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_codigos_barras` `cb`
  JOIN `fza_articulos_skus` `sku`
    ON `cb`.`CODIGO_UNIDAD_CB` = `sku`.`CODIGO_UNIDAD_SKU`
  JOIN `fza_articulos` `a`
    ON `sku`.`CODIGO_ART_SKU` = `a`.`CODIGO_ART_ART`
UNION ALL
SELECT `ap`.`REF_PROVEEDOR_AP` AS `INPUT_BUSQUEDA`,
       _utf8mb4'MODELO_PROV' COLLATE utf8mb4_spanish_ci
       AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_articulos_proveedores` `ap`
  JOIN `fza_articulos` `a`
    ON `ap`.`CODIGO_ART_AP` = `a`.`CODIGO_ART_ART`
 WHERE `a`.`ESACTIVO_ART` = 'S'
   AND `ap`.`REF_PROVEEDOR_AP` IS NOT NULL
   AND `ap`.`REF_PROVEEDOR_AP` <> '';
