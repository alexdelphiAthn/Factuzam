-- =============================================================================
-- Normaliza colaciones de vi_caja_busqueda_unificada
-- =============================================================================
-- Evita [1271] Illegal mix of collations for operation 'case' al ordenar por
-- TIPO_COINCIDENCIA desde inLibArticulosValidador.
-- Idempotente: CREATE OR REPLACE VIEW puede ejecutarse varias veces.
-- =============================================================================
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_caja_busqueda_unificada` AS
SELECT `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci AS `INPUT_BUSQUEDA`,
       'CODIGO' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_articulos` `a`
 WHERE `a`.`ESACTIVO_ART` COLLATE utf8mb4_spanish_ci =
       'S' COLLATE utf8mb4_spanish_ci
UNION ALL
SELECT `sku`.`CODIGO_UNIDAD_SKU` COLLATE utf8mb4_spanish_ci
       AS `INPUT_BUSQUEDA`,
       'SKU' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       `sku`.`CODIGO_UNIDAD_SKU` COLLATE utf8mb4_spanish_ci AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_articulos_skus` `sku`
  JOIN `fza_articulos` `a`
    ON `sku`.`CODIGO_ART_SKU` COLLATE utf8mb4_spanish_ci =
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci
 WHERE `sku`.`ESACTIVO_SKU` COLLATE utf8mb4_spanish_ci =
       'S' COLLATE utf8mb4_spanish_ci
UNION ALL
SELECT `cb`.`CODIGO_BARRAS_CB` COLLATE utf8mb4_spanish_ci
       AS `INPUT_BUSQUEDA`,
       'EAN' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       `sku`.`CODIGO_UNIDAD_SKU` COLLATE utf8mb4_spanish_ci AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_codigos_barras` `cb`
  JOIN `fza_articulos_skus` `sku`
    ON `cb`.`CODIGO_UNIDAD_CB` COLLATE utf8mb4_spanish_ci =
       `sku`.`CODIGO_UNIDAD_SKU` COLLATE utf8mb4_spanish_ci
  JOIN `fza_articulos` `a`
    ON `sku`.`CODIGO_ART_SKU` COLLATE utf8mb4_spanish_ci =
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci
UNION ALL
SELECT `ap`.`REF_PROVEEDOR_AP` COLLATE utf8mb4_spanish_ci
       AS `INPUT_BUSQUEDA`,
       'MODELO_PROV' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_articulos_proveedores` `ap`
  JOIN `fza_articulos` `a`
    ON `ap`.`CODIGO_ART_AP` COLLATE utf8mb4_spanish_ci =
       `a`.`CODIGO_ART_ART` COLLATE utf8mb4_spanish_ci
 WHERE `a`.`ESACTIVO_ART` COLLATE utf8mb4_spanish_ci =
       'S' COLLATE utf8mb4_spanish_ci
   AND `ap`.`REF_PROVEEDOR_AP` IS NOT NULL
   AND `ap`.`REF_PROVEEDOR_AP` COLLATE utf8mb4_spanish_ci <>
       '' COLLATE utf8mb4_spanish_ci;
