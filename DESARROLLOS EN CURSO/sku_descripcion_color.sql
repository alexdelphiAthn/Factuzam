-- ============================================================================
--  Descripcion del color por-articulo + activar/desactivar SKU por color
-- ----------------------------------------------------------------------------
--  Cambios sobre la ficha SKU del articulo (pestana "2_SKUs" de inMtoArticulos):
--
--  1) DESCRIPCION_AAB: texto libre del color a nivel de ARTICULO. Es distinto
--     para cada articulo aunque el color (AV) o el basico (ATB) se compartan.
--     Vive en fza_articulos_atributos_basicos (la tabla puente articulo<->valor),
--     junto al override del basico por-articulo (ID_ATB_AAB). Asi un mismo color
--     "011-AZ" puede describirse distinto en cada articulo sin tocar el catalogo
--     global (fza_atributos_basicos.DESCRIPCION_ATB, que es compartida).
--
--  2) Se expone DESCRIPCION_AAB en la vista vi_atributos_sku_basico para que el
--     grid "Atributos del SKU + Atributo basico (helper)" muestre los tres
--     campos: Color proveedor (VALOR_AV) + Color basico (ID_ATB_AV) +
--     Descripcion del color (DESCRIPCION_AAB).
--
--  La activacion/desactivacion en bloque de todos los SKU de un color NO
--  necesita esquema nuevo: reutiliza ESACTIVO_SKU (ya existente en
--  fza_articulos_skus) con un UPDATE filtrado por color a traves de esta misma
--  vista (lo lanza el Delphi en TdmArticulos.ActualizarSkusColorActivo).
--
--  Idempotente:
--    - La columna se anade solo si no existe (INFORMATION_SCHEMA).
--    - La vista se recrea con DROP + CREATE (idempotente por definicion).
--  No se toca factuzam_original.sql (regla 1 de CLAUDE.md).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) Columna DESCRIPCION_AAB en fza_articulos_atributos_basicos
-- ----------------------------------------------------------------------------
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_atributos_basicos'
     AND COLUMN_NAME  = 'DESCRIPCION_AAB'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_articulos_atributos_basicos
     ADD COLUMN DESCRIPCION_AAB varchar(255) NULL DEFAULT NULL
     AFTER ID_ATB_AAB',
  'SELECT ''DESCRIPCION_AAB ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2) Vista vi_atributos_sku_basico: misma definicion que
--    sku_atributos_huerfanos.sql con DESCRIPCION_AAB anadido como ultimo campo
--    (filas reales -> aab.DESCRIPCION_AAB; filas virtuales -> NULL).
-- ----------------------------------------------------------------------------
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
    END                                           AS `ETIQUETA_BASICO`,
    `aab`.`DESCRIPCION_AAB`                        AS `DESCRIPCION_AAB`
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
-- 2) Filas VIRTUALES: SKU con un atributo de su variacion SIN fila en SA.
--    El VALOR_AV se obtiene del propio codigo del SKU por posicion ORDEN_VA.
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
    NULL                                          AS `ETIQUETA_BASICO`,
    NULL                                          AS `DESCRIPCION_AAB`
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
