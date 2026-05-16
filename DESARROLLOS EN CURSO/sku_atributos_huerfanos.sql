-- ============================================================================
--  vi_atributos_sku_basico — incluir filas virtuales para SKUs huérfanos
-- ----------------------------------------------------------------------------
--  Problema:
--    La vista actual hace INNER JOIN entre fza_articulos_skus y la tabla
--    puente fza_atributos_sku (SA). Un SKU sin filas en SA (creado a mano,
--    importado, migrado, etc.) NO aparece en la vista, así que el grid
--    "Atributos del SKU + Atributo básico (helper)" se queda vacío y no
--    hay forma de asignarle color/talla básica desde la UI sin tocar SQL.
--
--  Solución:
--    UNION ALL con filas "virtuales" (ID_AV NULL) para cada atributo de la
--    variación del SKU que NO tenga su correspondiente fila en SA. El
--    VALOR_AV de la fila virtual se deriva del propio código del SKU por
--    posición ORDEN_VA (ej. DEMO-CAMISA/BLANCO/M → 'BLANCO' para ORDEN=1
--    'CO', 'M' para ORDEN=2 'TAL').
--
--    Estas filas son sólo informativas. El primer EditValueChanged que
--    edite el básico dispara AsegurarFilaSA() en Delphi, que materializa
--    el AV (si no existía) y la fila SA, y a partir de ahí la fila pasa
--    a ser "real" (con ID_AV no nulo) y la vista la sirve por la primera
--    rama del UNION.
--
--  Idempotente — DROP + CREATE.
-- ============================================================================

DROP VIEW IF EXISTS `vi_atributos_sku_basico`;

CREATE ALGORITHM = UNDEFINED VIEW `vi_atributos_sku_basico` AS

-- ---------------------------------------------------------------------------
-- 1) Filas REALES: SKU con su atributo enlazado en fza_atributos_sku (SA).
-- ---------------------------------------------------------------------------
SELECT
    `sku`.`CODIGO_ART_SKU`                        AS `CODIGO_ART_SKU`,
    `sku`.`CODIGO_UNIDAD_SKU`                     AS `CODIGO_UNIDAD_SKU`,
    `sku`.`CODIGO_VAR_SKU`                        AS `CODIGO_VAR_SKU`,
    `val`.`ID_AV`                                 AS `ID_AV`,
    `val`.`ID_VA_AV`                              AS `ID_VA_AV`,
    `va`.`NOMBRE_VA`                              AS `NOMBRE_ATRIBUTO`,
    `va`.`ORDEN_VA`                               AS `ORDEN_ATRIBUTO`,
    `val`.`AV`                                    AS `VALOR_AV`,
    `val`.`DESCRIPCION_AV`                        AS `DESCRIPCION_AV`,
    `aca`.`ID_AC_ACA`                             AS `ID_AC`,
    `aab`.`ID_ATB_AAB`                            AS `ID_ATB_OVERRIDE`,
    `acd`.`ID_ATB_ACD`                            AS `ID_ATB_CONJUNTO`,
    `val`.`ID_ATB_AV`                             AS `ID_ATB_GLOBAL`,
    CASE
      WHEN `aab`.`CODIGO_ART_AAB` IS NOT NULL THEN `aab`.`ID_ATB_AAB`
      WHEN `acd`.`ID_ATB_ACD`     IS NOT NULL THEN `acd`.`ID_ATB_ACD`
      ELSE `val`.`ID_ATB_AV`
    END                                           AS `ID_ATB_AV`,
    CASE
      WHEN `aab`.`CODIGO_ART_AAB` IS NOT NULL THEN 'A'
      WHEN `acd`.`ID_ATB_ACD`     IS NOT NULL THEN 'C'
      WHEN `val`.`ID_ATB_AV`      IS NOT NULL THEN 'G'
      ELSE NULL
    END                                           AS `FUENTE_ATB`,
    `atb`.`CODIGO_ATB`                            AS `CODIGO_ATB`,
    `atb`.`NOMBRE_ATB`                            AS `NOMBRE_ATB`,
    `atb`.`DESCRIPCION_ATB`                       AS `DESCRIPCION_ATB`,
    `atb`.`HEX_ATB`                               AS `HEX_ATB`,
    `atb`.`VALOR_NUM_ATB`                         AS `VALOR_NUM_ATB`,
    `atb`.`UNIDAD_ATB`                            AS `UNIDAD_ATB`,
    CASE
      WHEN `atb`.`VALOR_NUM_ATB` IS NOT NULL THEN
        CONCAT(
          TRIM(TRAILING '0' FROM TRIM(TRAILING '.' FROM
            CAST(`atb`.`VALOR_NUM_ATB` AS CHAR CHARSET utf8mb4))),
          COALESCE(CONCAT(' ', `atb`.`UNIDAD_ATB`), '')
        )
      WHEN `atb`.`HEX_ATB` IS NOT NULL THEN
        CONCAT(`atb`.`NOMBRE_ATB`, ' ', `atb`.`HEX_ATB`)
      ELSE `atb`.`NOMBRE_ATB`
    END                                           AS `ETIQUETA_BASICO`
FROM             `fza_articulos_skus`              `sku`
JOIN             `fza_atributos_sku`               `sa`
              ON `sa`.`CODIGO_UNIDAD_SKU_SA` = `sku`.`CODIGO_UNIDAD_SKU`
JOIN             `fza_atributos_valores`           `val`
              ON `val`.`ID_AV` = `sa`.`ID_AV_SA`
LEFT JOIN        `fza_variaciones_atributos`       `va`
              ON `va`.`ID_VAR_VA` = `sku`.`CODIGO_VAR_SKU`
             AND `va`.`ID_ATB_VA` = `val`.`ID_VA_AV`
LEFT JOIN        `fza_articulos_atributos_basicos` `aab`
              ON `aab`.`CODIGO_ART_AAB` = `sku`.`CODIGO_ART_SKU`
             AND `aab`.`ID_AV_AAB`      = `val`.`ID_AV`
LEFT JOIN        `fza_articulos_conjuntos_asign`   `aca`
              ON `aca`.`CODIGO_ART_ACA` = `sku`.`CODIGO_ART_SKU`
             AND `aca`.`ID_VA_ACA`      = `val`.`ID_VA_AV`
LEFT JOIN        `fza_atributos_conjuntos_det`     `acd`
              ON `acd`.`ID_AC_ACD` = `aca`.`ID_AC_ACA`
             AND `acd`.`ID_AV_ACD` = `val`.`ID_AV`
LEFT JOIN        `fza_atributos_basicos`           `atb`
              ON `atb`.`ID_ATB` = CASE
                WHEN `aab`.`CODIGO_ART_AAB` IS NOT NULL THEN `aab`.`ID_ATB_AAB`
                WHEN `acd`.`ID_ATB_ACD`     IS NOT NULL THEN `acd`.`ID_ATB_ACD`
                ELSE `val`.`ID_ATB_AV`
              END

UNION ALL

-- ---------------------------------------------------------------------------
-- 2) Filas VIRTUALES: SKU con un atributo de su variación SIN fila en SA.
--    El VALOR_AV se obtiene del propio código del SKU por posición ORDEN_VA.
--    Se filtra por LIKE 'CODIGO_ART_SKU/%' para no parsear códigos que no
--    siguen la convención (CODIGO_ART/VAL1/VAL2…) y dar lugar a basura.
-- ---------------------------------------------------------------------------
SELECT
    `sku`.`CODIGO_ART_SKU`                        AS `CODIGO_ART_SKU`,
    `sku`.`CODIGO_UNIDAD_SKU`                     AS `CODIGO_UNIDAD_SKU`,
    `sku`.`CODIGO_VAR_SKU`                        AS `CODIGO_VAR_SKU`,
    NULL                                          AS `ID_AV`,
    `va`.`ID_ATB_VA`                              AS `ID_VA_AV`,
    `va`.`NOMBRE_VA`                              AS `NOMBRE_ATRIBUTO`,
    `va`.`ORDEN_VA`                               AS `ORDEN_ATRIBUTO`,
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(
        SUBSTRING(`sku`.`CODIGO_UNIDAD_SKU`,
                  CHAR_LENGTH(`sku`.`CODIGO_ART_SKU`) + 2),
        '/', `va`.`ORDEN_VA`),
      '/', -1)                                    AS `VALOR_AV`,
    NULL                                          AS `DESCRIPCION_AV`,
    NULL                                          AS `ID_AC`,
    NULL                                          AS `ID_ATB_OVERRIDE`,
    NULL                                          AS `ID_ATB_CONJUNTO`,
    NULL                                          AS `ID_ATB_GLOBAL`,
    NULL                                          AS `ID_ATB_AV`,
    NULL                                          AS `FUENTE_ATB`,
    NULL                                          AS `CODIGO_ATB`,
    NULL                                          AS `NOMBRE_ATB`,
    NULL                                          AS `DESCRIPCION_ATB`,
    NULL                                          AS `HEX_ATB`,
    NULL                                          AS `VALOR_NUM_ATB`,
    NULL                                          AS `UNIDAD_ATB`,
    NULL                                          AS `ETIQUETA_BASICO`
FROM             `fza_articulos_skus`         `sku`
JOIN             `fza_variaciones_atributos`  `va`
              ON `va`.`ID_VAR_VA` = `sku`.`CODIGO_VAR_SKU`
WHERE `sku`.`CODIGO_UNIDAD_SKU` LIKE CONCAT(`sku`.`CODIGO_ART_SKU`, '/%')
  AND NOT EXISTS (
        SELECT 1
          FROM `fza_atributos_sku`     `sa`
          JOIN `fza_atributos_valores` `v`
            ON `v`.`ID_AV` = `sa`.`ID_AV_SA`
         WHERE `sa`.`CODIGO_UNIDAD_SKU_SA` = `sku`.`CODIGO_UNIDAD_SKU`
           AND `v`.`ID_VA_AV`              = `va`.`ID_ATB_VA`
      );
