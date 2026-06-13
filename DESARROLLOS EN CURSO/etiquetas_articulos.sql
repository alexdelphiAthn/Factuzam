-- ============================================================================
-- Etiquetas de Articulo / SKU
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
--
-- Soporta el modal `TfrmPrintEtiqArt` (src/Modals/inMtoModalEtiqArt) lanzado
-- desde la pestaña Stock del mantenimiento de artículos. La pantalla cruza
-- esta vista con `fza_articulos_tarifas` (tarifa + fecha de aplicación) y con
-- `fza_articulos_stockactual` (almacenes seleccionados) en tiempo de consulta.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- IDEMPOTENCIA
-- ---------------------------------------------------------------------------
-- Re-ejecutable: DROP VIEW IF EXISTS + CREATE VIEW. Sin datos asociados.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. Vista vi_articulos_skus_etiquetas
-- ---------------------------------------------------------------------------
-- Una fila por SKU. Trae:
--   - Atributos pivotados (ATR_CO, ATR_TAL) más texto agregado ATRIBUTOS_TXT
--     y DESCRIPCION_SKU (los valores concatenados con " / ", orden ORDEN_VA).
--   - Propiedades pivotadas a NIVEL ARTÍCULO (PROP_MARCA, PROP_MATERIAL,
--     PROP_GENERO, PROP_ESTILO, PROP_ORIGEN, PROP_COMPOSICION). Resuelve
--     ID_PV_ARTPROP contra `fza_propiedades_valores`; si la propiedad es de
--     valor libre cae a VALOR_LIBRE_ARTPROP. Además expone PROPIEDADES_TXT
--     con TODAS las propiedades del artículo en un único campo
--     "Nombre: Valor | Nombre: Valor".
--   - TEMPORADA resuelta POR SKU (es propiedad de nivel COLOR), en el CTE
--     sku_temp por especificidad SKU -> COLOR -> ARTÍCULO, igual que
--     vi_articulos_propiedades_efectivas. Así la etiqueta de cada SKU muestra
--     la temporada de SU color:
--       * PROP_TEMPORADA: texto largo ("Primavera/Verano 2026").
--       * COD_TEMPORADA : código corto ("PV26"), guardado en DESCRIPCION_PV
--         del valor de la propiedad TEMPORADA.
--   - Proveedor principal (CODIGO_PRV_PRV, RAZON_SOCIAL_PRV, NOMBRE_PRV,
--     REF_PROVEEDOR). NOMBRE_PRV es el nombre comercial; la etiqueta por
--     defecto lo usa como "nombre de proveedor".
--   - Código de barras marcado como principal del SKU.
--
-- Nota sobre extensibilidad: el conjunto fijo de columnas PROP_* y ATR_*
-- cubre los casos más usados en etiquetas. Si se añade un nuevo atributo o
-- propiedad imprescindible para etiquetas, se amplía la vista aquí y se
-- vuelve a desplegar; PROPIEDADES_TXT/ATRIBUTOS_TXT cubren los demás como
-- texto agregado, sin tocar la vista.
-- ---------------------------------------------------------------------------

DROP VIEW IF EXISTS `vi_articulos_skus_etiquetas`;
CREATE ALGORITHM=UNDEFINED VIEW `vi_articulos_skus_etiquetas` AS
WITH
  sku_atrib AS (
    SELECT
      `sa`.`CODIGO_UNIDAD_SKU_SA`                                   AS `CODIGO_UNIDAD_SKU`,
      MAX(CASE WHEN `av`.`ID_VA_AV` = 'CO'  THEN `av`.`AV` END)     AS `ATR_CO`,
      MAX(CASE WHEN `av`.`ID_VA_AV` = 'TAL' THEN `av`.`AV` END)     AS `ATR_TAL`,
      GROUP_CONCAT(CONCAT(COALESCE(`va`.`NOMBRE_VA`, `av`.`ID_VA_AV`),
                          ': ', `av`.`AV`)
                   ORDER BY COALESCE(`va`.`ORDEN_VA`, 99), `av`.`ID_VA_AV`
                   SEPARATOR ' / ')                                 AS `ATRIBUTOS_TXT`,
      GROUP_CONCAT(`av`.`AV`
                   ORDER BY COALESCE(`va`.`ORDEN_VA`, 99), `av`.`ID_VA_AV`
                   SEPARATOR ' / ')                                 AS `DESCRIPCION_SKU`
    FROM `fza_atributos_sku` `sa`
    INNER JOIN `fza_atributos_valores` `av`
            ON `av`.`ID_AV` = `sa`.`ID_AV_SA`
    LEFT  JOIN `fza_variaciones_atributos` `va`
            ON `va`.`ID_ATB_VA` = `av`.`ID_VA_AV`
    GROUP BY `sa`.`CODIGO_UNIDAD_SKU_SA`
  ),
  art_prop AS (
    SELECT
      `ap`.`CODIGO_ART_ART`                                         AS `CODIGO_ART_ART`,
      MAX(CASE WHEN `ap`.`CODIGO_PROP_ARTPROP` = 'MARCA'
               THEN COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`) END) AS `PROP_MARCA`,
      MAX(CASE WHEN `ap`.`CODIGO_PROP_ARTPROP` = 'MATERIAL'
               THEN COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`) END) AS `PROP_MATERIAL`,
      -- TEMPORADA no se pivota aqui (nivel articulo): es propiedad de nivel
      -- COLOR y se resuelve POR SKU en el CTE sku_temp (PROP_TEMPORADA y
      -- COD_TEMPORADA), para que la etiqueta muestre la temporada del color.
      MAX(CASE WHEN `ap`.`CODIGO_PROP_ARTPROP` = 'GENERO'
               THEN COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`) END) AS `PROP_GENERO`,
      MAX(CASE WHEN `ap`.`CODIGO_PROP_ARTPROP` = 'ESTILO'
               THEN COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`) END) AS `PROP_ESTILO`,
      MAX(CASE WHEN `ap`.`CODIGO_PROP_ARTPROP` = 'ORIGEN'
               THEN COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`) END) AS `PROP_ORIGEN`,
      MAX(CASE WHEN `ap`.`CODIGO_PROP_ARTPROP` = 'COMPOSICION'
               THEN COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`) END) AS `PROP_COMPOSICION`,
      GROUP_CONCAT(
        CONCAT(COALESCE(`p`.`NOMBRE_PROP_PROP`, `ap`.`CODIGO_PROP_ARTPROP`),
               ': ',
               COALESCE(`pv`.`PV`, `ap`.`VALOR_LIBRE_ARTPROP`, ''))
        ORDER BY `ap`.`CODIGO_PROP_ARTPROP`
        SEPARATOR ' | '
      )                                                             AS `PROPIEDADES_TXT`
    FROM `fza_articulos_propiedades` `ap`
    LEFT JOIN `fza_propiedades` `p`
           ON `p`.`CODIGO_PROP_ARTPROP` = `ap`.`CODIGO_PROP_ARTPROP`
    LEFT JOIN `fza_propiedades_valores` `pv`
           ON `pv`.`ID_PV_ARTPROP` = `ap`.`ID_PV_ARTPROP`
    GROUP BY `ap`.`CODIGO_ART_ART`
  ),
  sku_temp AS (
    -- Temporada resuelta POR SKU con especificidad SKU -> COLOR -> ARTICULO
    -- (mismo patron que vi_articulos_propiedades_efectivas). TEMPORADA es de
    -- nivel COLOR: cada etiqueta muestra la temporada de SU color, no un
    -- agregado del articulo. El "color" es el prefijo ART/COLOR del
    -- CODIGO_UNIDAD_SKU (SUBSTRING_INDEX hasta antes de la talla).
    SELECT
      `sku`.`CODIGO_UNIDAD_SKU`                                   AS `CODIGO_UNIDAD_SKU`,
      COALESCE(`tpv`.`PV`,
               `tps`.`VALOR_LIBRE_ARTPROP`,
               `tpc`.`VALOR_LIBRE_ARTPROP`,
               `tpa`.`VALOR_LIBRE_ARTPROP`)                       AS `PROP_TEMPORADA`,
      `tpv`.`DESCRIPCION_PV`                                      AS `COD_TEMPORADA`
    FROM `fza_articulos_skus` `sku`
    LEFT JOIN `fza_articulos_propiedades` `tps`
           ON `tps`.`CODIGO_ART_ART`        = `sku`.`CODIGO_ART_SKU`
          AND `tps`.`CODIGO_PROP_ARTPROP`   = 'TEMPORADA'
          AND `tps`.`CODIGO_UNIDAD_ARTPROP` = `sku`.`CODIGO_UNIDAD_SKU`
    LEFT JOIN `fza_articulos_propiedades` `tpc`
           ON `tpc`.`CODIGO_ART_ART`        = `sku`.`CODIGO_ART_SKU`
          AND `tpc`.`CODIGO_PROP_ARTPROP`   = 'TEMPORADA'
          AND `tpc`.`CODIGO_UNIDAD_ARTPROP` = CASE
                WHEN CHAR_LENGTH(`sku`.`CODIGO_UNIDAD_SKU`)
                   - CHAR_LENGTH(REPLACE(`sku`.`CODIGO_UNIDAD_SKU`, '/', '')) >= 2
                THEN SUBSTRING_INDEX(`sku`.`CODIGO_UNIDAD_SKU`, '/', 2)
                ELSE NULL END
    LEFT JOIN `fza_articulos_propiedades` `tpa`
           ON `tpa`.`CODIGO_ART_ART`        = `sku`.`CODIGO_ART_SKU`
          AND `tpa`.`CODIGO_PROP_ARTPROP`   = 'TEMPORADA'
          AND `tpa`.`CODIGO_UNIDAD_ARTPROP` = ''
    LEFT JOIN `fza_propiedades_valores` `tpv`
           ON `tpv`.`ID_PV_ARTPROP` = COALESCE(`tps`.`ID_PV_ARTPROP`,
                                               `tpc`.`ID_PV_ARTPROP`,
                                               `tpa`.`ID_PV_ARTPROP`)
  ),
  cb_prin AS (
    SELECT `CODIGO_UNIDAD_CB`,
           MAX(`CODIGO_BARRAS_CB`) AS `CODIGO_BARRAS_CB`
    FROM `fza_codigos_barras`
    WHERE `ESPRINCIPAL_CB` = 'S'
    GROUP BY `CODIGO_UNIDAD_CB`
  )
SELECT
  `sku`.`CODIGO_UNIDAD_SKU`                                         AS `CODIGO_UNIDAD_SKU`,
  `sku`.`CODIGO_ART_SKU`                                            AS `CODIGO_ART_ART`,
  `sku`.`CODIGO_VAR_SKU`                                            AS `CODIGO_VAR_SKU`,
  `sku`.`ESACTIVO_SKU`                                              AS `ESACTIVO_SKU`,
  `art`.`ESACTIVO_ART`                                              AS `ESACTIVO_ART`,
  `art`.`DESCRIPCION_ART`                                           AS `DESCRIPCION_ART`,
  `art`.`TIPO_ART`                                                  AS `TIPO_ART`,
  `art`.`TIPO_IVA_ART`                                              AS `TIPO_IVA_ART`,
  `art`.`CODIGO_FAM_ART`                                            AS `CODIGO_FAM_ART`,
  `fam`.`NOMBRE_FAM_FAM`                                            AS `NOMBRE_FAM_FAM`,
  `fam`.`DESCRIPCION_FAM`                                           AS `DESCRIPCION_FAM`,
  `sa`.`ATR_CO`                                                     AS `ATR_CO`,
  `sa`.`ATR_TAL`                                                    AS `ATR_TAL`,
  `sa`.`ATRIBUTOS_TXT`                                              AS `ATRIBUTOS_TXT`,
  `sa`.`DESCRIPCION_SKU`                                            AS `DESCRIPCION_SKU`,
  `apr`.`PROP_MARCA`                                                AS `PROP_MARCA`,
  `apr`.`PROP_MATERIAL`                                             AS `PROP_MATERIAL`,
  `st`.`PROP_TEMPORADA`                                             AS `PROP_TEMPORADA`,
  `st`.`COD_TEMPORADA`                                              AS `COD_TEMPORADA`,
  `apr`.`PROP_GENERO`                                               AS `PROP_GENERO`,
  `apr`.`PROP_ESTILO`                                               AS `PROP_ESTILO`,
  `apr`.`PROP_ORIGEN`                                               AS `PROP_ORIGEN`,
  `apr`.`PROP_COMPOSICION`                                          AS `PROP_COMPOSICION`,
  `apr`.`PROPIEDADES_TXT`                                           AS `PROPIEDADES_TXT`,
  `ap`.`CODIGO_PRV_AP`                                              AS `CODIGO_PRV_PRV`,
  `prv`.`RAZON_SOCIAL_PRV`                                          AS `RAZON_SOCIAL_PRV`,
  `prv`.`NOMBRE_PRV`                                                AS `NOMBRE_PRV`,
  `ap`.`REF_PROVEEDOR_AP`                                           AS `REF_PROVEEDOR`,
  `cb`.`CODIGO_BARRAS_CB`                                           AS `CODIGO_BARRAS_CB`
FROM `fza_articulos_skus` `sku`
INNER JOIN `fza_articulos`            `art`
        ON `art`.`CODIGO_ART_ART` = `sku`.`CODIGO_ART_SKU`
LEFT  JOIN `fza_articulos_familias`   `fam`
        ON `fam`.`CODIGO_FAM_FAM` = `art`.`CODIGO_FAM_ART`
LEFT  JOIN `sku_atrib`                `sa`
        ON `sa`.`CODIGO_UNIDAD_SKU` = `sku`.`CODIGO_UNIDAD_SKU`
LEFT  JOIN `art_prop`                 `apr`
        ON `apr`.`CODIGO_ART_ART` = `sku`.`CODIGO_ART_SKU`
LEFT  JOIN `sku_temp`                 `st`
        ON `st`.`CODIGO_UNIDAD_SKU` = `sku`.`CODIGO_UNIDAD_SKU`
LEFT  JOIN `fza_articulos_proveedores` `ap`
        ON `ap`.`CODIGO_ART_AP` = `sku`.`CODIGO_ART_SKU`
       AND `ap`.`ESPROVEEDORPRINCIPAL_AP` = 'S'
LEFT  JOIN `fza_proveedores`          `prv`
        ON `prv`.`CODIGO_PRV_PRV` = `ap`.`CODIGO_PRV_AP`
LEFT  JOIN `cb_prin`                  `cb`
        ON `cb`.`CODIGO_UNIDAD_CB` = `sku`.`CODIGO_UNIDAD_SKU`;
