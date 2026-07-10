-- =============================================================================
-- Normaliza colaciones de vi_caja_busqueda_unificada
-- =============================================================================
-- Evita [1271] Illegal mix of collations for operation 'case' al ordenar por
-- TIPO_COINCIDENCIA desde inLibArticulosValidador. Las columnas pueden venir
-- de backups antiguos como utf8/utf8mb3, asi que se convierten antes de
-- aplicar COLLATE utf8mb4_spanish_ci.
-- Idempotente: CREATE OR REPLACE VIEW puede ejecutarse varias veces.
-- =============================================================================
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_caja_busqueda_unificada` AS
SELECT CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `INPUT_BUSQUEDA`,
       _utf8mb4'CODIGO' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       CONVERT(`a`.`DESCRIPCION_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       CONVERT(`a`.`TIPO_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_articulos` `a`
 WHERE CONVERT(`a`.`ESACTIVO_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       _utf8mb4'S' COLLATE utf8mb4_spanish_ci
UNION ALL
SELECT CONVERT(`sku`.`CODIGO_UNIDAD_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
       AS `INPUT_BUSQUEDA`,
       _utf8mb4'SKU' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       CONVERT(`sku`.`CODIGO_UNIDAD_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `CODIGO_SKU`,
       CONVERT(`a`.`DESCRIPCION_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       CONVERT(`a`.`TIPO_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_articulos_skus` `sku`
  JOIN `fza_articulos` `a`
    ON CONVERT(`sku`.`CODIGO_ART_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
 WHERE CONVERT(`sku`.`ESACTIVO_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       _utf8mb4'S' COLLATE utf8mb4_spanish_ci
UNION ALL
SELECT CONVERT(`cb`.`CODIGO_BARRAS_CB` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
       AS `INPUT_BUSQUEDA`,
       _utf8mb4'EAN' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       CONVERT(`sku`.`CODIGO_UNIDAD_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `CODIGO_SKU`,
       CONVERT(`a`.`DESCRIPCION_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       CONVERT(`a`.`TIPO_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_codigos_barras` `cb`
  JOIN `fza_articulos_skus` `sku`
    ON CONVERT(`cb`.`CODIGO_UNIDAD_CB` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       CONVERT(`sku`.`CODIGO_UNIDAD_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
  JOIN `fza_articulos` `a`
    ON CONVERT(`sku`.`CODIGO_ART_SKU` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
UNION ALL
SELECT CONVERT(`ap`.`REF_PROVEEDOR_AP` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
       AS `INPUT_BUSQUEDA`,
       _utf8mb4'MODELO_PROV' COLLATE utf8mb4_spanish_ci
       AS `TIPO_COINCIDENCIA`,
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       CONVERT(`a`.`DESCRIPCION_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `DESCRIPCION_ART`,
       CONVERT(`a`.`TIPO_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci AS `TIPO_ART`
  FROM `fza_articulos_proveedores` `ap`
  JOIN `fza_articulos` `a`
    ON CONVERT(`ap`.`CODIGO_ART_AP` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       CONVERT(`a`.`CODIGO_ART_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci
 WHERE CONVERT(`a`.`ESACTIVO_ART` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci =
       _utf8mb4'S' COLLATE utf8mb4_spanish_ci
   AND `ap`.`REF_PROVEEDOR_AP` IS NOT NULL
   AND CONVERT(`ap`.`REF_PROVEEDOR_AP` USING utf8mb4)
       COLLATE utf8mb4_spanish_ci <>
       _utf8mb4'' COLLATE utf8mb4_spanish_ci;
