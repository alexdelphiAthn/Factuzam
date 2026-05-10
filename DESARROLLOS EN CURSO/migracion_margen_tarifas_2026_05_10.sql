-- ============================================================================
-- Migración: margen comercial y ajustes (múltiplo / menos) en tarifas y
--            artículos-tarifa, más recreación de vi_articulos_tarifas para
--            exponer el valor efectivo (artículo > tarifa).
-- Fecha:   2026-05-10
-- Rama:    claude/add-margin-column-nGUim
--
-- Aplica este script DESPUÉS de actualizar el ejecutable a la versión que
-- incluye el formulario de margen y el modal de cálculo (Aceptar -> calcula
-- precio de salida según coste, margen y ajustes).
--
-- Cambios:
--   1. fza_tarifas: añade PORCENTAJE_MARGEN_TAR, VALOR_MULTIPLO_AJUSTE_TAR,
--      VALOR_MENOS_AJUSTE_TAR (defaults heredables por los artículos).
--   2. fza_articulos_tarifas: añade PORCENTAJE_MARGEN_ARTTAR,
--      VALOR_MULTIPLO_AJUSTE_ARTTAR, VALOR_MENOS_AJUSTE_ARTTAR (override).
--   3. Recrea vi_articulos_tarifas exponiendo:
--        - PORCENTAJE_MARGEN_ARTTAR / VALOR_MULTIPLO_AJUSTE_ARTTAR /
--          VALOR_MENOS_AJUSTE_ARTTAR (override en articulo-tarifa).
--        - PORCENTAJE_MARGEN_EFECTIVO / VALOR_MULTIPLO_AJUSTE_EFECTIVO /
--          VALOR_MENOS_AJUSTE_EFECTIVO (lo que el modal aplicará: override
--          si existe, si no el valor de la tarifa).
-- ============================================================================

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Nuevas columnas en fza_tarifas
-- ----------------------------------------------------------------------------
ALTER TABLE `fza_tarifas`
  ADD COLUMN `PORCENTAJE_MARGEN_TAR`        decimal(19,6) NULL DEFAULT NULL AFTER `ESDEFAULT_TAR`,
  ADD COLUMN `VALOR_MULTIPLO_AJUSTE_TAR`    decimal(19,6) NULL DEFAULT NULL AFTER `PORCENTAJE_MARGEN_TAR`,
  ADD COLUMN `VALOR_MENOS_AJUSTE_TAR`       decimal(19,6) NULL DEFAULT NULL AFTER `VALOR_MULTIPLO_AJUSTE_TAR`;

-- ----------------------------------------------------------------------------
-- 2. Nuevas columnas en fza_articulos_tarifas (override por artículo+tarifa)
-- ----------------------------------------------------------------------------
ALTER TABLE `fza_articulos_tarifas`
  ADD COLUMN `PORCENTAJE_MARGEN_ARTTAR`     decimal(19,6) NULL DEFAULT NULL AFTER `PORCENTAJE_DTO_ARTTAR`,
  ADD COLUMN `VALOR_MULTIPLO_AJUSTE_ARTTAR` decimal(19,6) NULL DEFAULT NULL AFTER `PORCENTAJE_MARGEN_ARTTAR`,
  ADD COLUMN `VALOR_MENOS_AJUSTE_ARTTAR`    decimal(19,6) NULL DEFAULT NULL AFTER `VALOR_MULTIPLO_AJUSTE_ARTTAR`;

-- ----------------------------------------------------------------------------
-- 3. Recreación de vi_articulos_tarifas exponiendo margen + ajustes
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS `vi_articulos_tarifas`;

CREATE ALGORITHM=UNDEFINED VIEW `vi_articulos_tarifas` AS
WITH
unidades AS (
    SELECT
        a.CODIGO_ART_ART       AS CODIGO_ART,
        skus.CODIGO_UNIDAD_SKU AS CODIGO_UNIDAD,
        skus.CODIGO_VAR_SKU    AS CODIGO_VAR_SKU,
        skus.ESACTIVO_SKU      AS ESACTIVO_SKU,
        'S'                    AS TIENE_SKU
    FROM fza_articulos a
    JOIN fza_articulos_skus skus
      ON skus.CODIGO_ART_SKU = a.CODIGO_ART_ART
     AND skus.ESACTIVO_SKU   = 'S'
    UNION ALL
    SELECT
        a.CODIGO_ART_ART,
        ''   AS CODIGO_UNIDAD,
        NULL AS CODIGO_VAR_SKU,
        NULL AS ESACTIVO_SKU,
        'N'  AS TIENE_SKU
    FROM fza_articulos a
    WHERE NOT EXISTS (
        SELECT 1 FROM fza_articulos_skus s
         WHERE s.CODIGO_ART_SKU = a.CODIGO_ART_ART
           AND s.ESACTIVO_SKU   = 'S'
    )
),
sku_desc AS (
    SELECT
        sa.CODIGO_UNIDAD_SKU_SA AS CODIGO_UNIDAD,
        GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV SEPARATOR ' / ') AS DESCRIPCION_SKU
    FROM fza_atributos_sku sa
    JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA
    GROUP BY sa.CODIGO_UNIDAD_SKU_SA
)
SELECT
    -- Identificación
    u.CODIGO_ART                                                    AS CODIGO_ART_ARTTAR,
    u.CODIGO_UNIDAD                                                 AS CODIGO_UNIDAD_ARTTAR,
    t.CODIGO_TAR_ARTTAR                                             AS CODIGO_TAR_ARTTAR,
    t.NOMBRE_TAR_TAR                                                AS NOMBRE_TAR_TAR,

    -- PK del registro existente (SKU si lo hay, padre si no)
    ts.CODIGO_UNICO_ARTTAR                                          AS CODIGO_UNICO_TARIFA_SKU,
    tp.CODIGO_UNICO_ARTTAR                                          AS CODIGO_UNICO_TARIFA_PADRE,
    COALESCE(ts.CODIGO_UNICO_ARTTAR, tp.CODIGO_UNICO_ARTTAR)        AS CODIGO_UNICO_ARTTAR,

    -- Origen del precio
    CASE
        WHEN ts.CODIGO_UNICO_ARTTAR IS NOT NULL THEN 'ESPECIFICO_SKU'
        WHEN tp.CODIGO_UNICO_ARTTAR IS NOT NULL THEN 'HEREDADO_PADRE'
        ELSE 'SIN_PRECIO'
    END                                                             AS ORIGEN_PRECIO,

    -- Precios resueltos (SKU > padre > NULL)
    COALESCE(ts.PRECIO_SALIDA_ARTTAR,    tp.PRECIO_SALIDA_ARTTAR)    AS PRECIO_SALIDA_ARTTAR,
    COALESCE(ts.PRECIO_FINAL_ARTTAR,     tp.PRECIO_FINAL_ARTTAR)     AS PRECIO_FINAL_ARTTAR,
    COALESCE(ts.PRECIO_DTO_ARTTAR,       tp.PRECIO_DTO_ARTTAR)       AS PRECIO_DTO_ARTTAR,
    COALESCE(ts.PORCENTAJE_DTO_ARTTAR,   tp.PORCENTAJE_DTO_ARTTAR)   AS PORCENTAJE_DTO_ARTTAR,

    -- Margen y ajustes (override en artículo-tarifa, sin defaultear todavía)
    COALESCE(ts.PORCENTAJE_MARGEN_ARTTAR,     tp.PORCENTAJE_MARGEN_ARTTAR)     AS PORCENTAJE_MARGEN_ARTTAR,
    COALESCE(ts.VALOR_MULTIPLO_AJUSTE_ARTTAR, tp.VALOR_MULTIPLO_AJUSTE_ARTTAR) AS VALOR_MULTIPLO_AJUSTE_ARTTAR,
    COALESCE(ts.VALOR_MENOS_AJUSTE_ARTTAR,    tp.VALOR_MENOS_AJUSTE_ARTTAR)    AS VALOR_MENOS_AJUSTE_ARTTAR,

    -- Margen y ajustes EFECTIVOS = override en artículo-tarifa o, si no, los de la tarifa
    COALESCE(ts.PORCENTAJE_MARGEN_ARTTAR,     tp.PORCENTAJE_MARGEN_ARTTAR,     t.PORCENTAJE_MARGEN_TAR)     AS PORCENTAJE_MARGEN_EFECTIVO,
    COALESCE(ts.VALOR_MULTIPLO_AJUSTE_ARTTAR, tp.VALOR_MULTIPLO_AJUSTE_ARTTAR, t.VALOR_MULTIPLO_AJUSTE_TAR) AS VALOR_MULTIPLO_AJUSTE_EFECTIVO,
    COALESCE(ts.VALOR_MENOS_AJUSTE_ARTTAR,    tp.VALOR_MENOS_AJUSTE_ARTTAR,    t.VALOR_MENOS_AJUSTE_TAR)    AS VALOR_MENOS_AJUSTE_EFECTIVO,

    -- Vigencia
    COALESCE(ts.FECHA_DESDE_ARTTAR, tp.FECHA_DESDE_ARTTAR)          AS FECHA_DESDE_ARTTAR,
    COALESCE(ts.FECHA_HASTA_ARTTAR, tp.FECHA_HASTA_ARTTAR)          AS FECHA_HASTA_ARTTAR,

    -- Flags de tarifa y artículo
    t.ESACTIVO_ARTTAR                                               AS ESACTIVO_ARTTAR,
    t.ESIMP_INCL_TAR                                                AS ESIMP_INCL_TAR,
    t.ESDEFAULT_TAR                                                 AS ESDEFAULT_TAR,
    a.DESCRIPCION_ART                                               AS DESCRIPCION_ART,
    a.TIPO_CANTIDAD_ART                                             AS TIPO_CANTIDAD_ART,
    a.ESVARIACION_ART                                               AS ESVARIACION_ART,
    iv.CODIGO_ABREVIATURA_IVA_IVATIP                                AS TIPO_IVA_ARTICULO,

    -- Datos del SKU
    u.TIENE_SKU                                                     AS TIENE_SKU,
    u.ESACTIVO_SKU                                                  AS ESACTIVO_SKU,
    sd.DESCRIPCION_SKU                                              AS DESCRIPCION_SKU,

    -- Proveedor principal
    ap.CODIGO_PRV_AP                                                AS CODIGO_PRV_PRV,
    p.RAZON_SOCIAL_PRV                                              AS RAZON_SOCIAL_PRV,
    ap.PRECIO_ULT_COMPRA_AP                                         AS PRECIO_ULT_COMPRA,
    ap.FECHA_VALIDEZ_AP                                             AS FECHA_VALIDEZ,

    -- Familia
    a.CODIGO_FAM_ART                                                AS CODIGO_FAM_ART,
    af.DESCRIPCION_FAM                                              AS DESCRIPCION_FAM,

    -- Nº atributos requeridos para validar SKU completo
    (SELECT COUNT(DISTINCT va.ID_ATB_VA)
       FROM fza_articulos_skus sk
       JOIN fza_variaciones_atributos va ON sk.CODIGO_VAR_SKU = va.ID_VAR_VA
      WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART)                   AS NUM_ATRIBUTOS_REQ,

    -- Auditoría: la del registro que aporta el precio
    COALESCE(ts.INSTANTE_MODIF, tp.INSTANTE_MODIF)                  AS INSTANTE_MODIF,
    COALESCE(ts.INSTANTE_ALTA,  tp.INSTANTE_ALTA)                   AS INSTANTE_ALTA,
    COALESCE(ts.USUARIO_ALTA,   tp.USUARIO_ALTA)                    AS USUARIO_ALTA,
    COALESCE(ts.USUARIO_MODIF,  tp.USUARIO_MODIF)                   AS USUARIO_MODIF

FROM unidades u
JOIN fza_articulos a    ON a.CODIGO_ART_ART = u.CODIGO_ART
JOIN fza_tarifas    t   ON t.ESACTIVO_ARTTAR = 'S'

LEFT JOIN fza_articulos_tarifas ts
       ON ts.CODIGO_ART_ARTTAR    = u.CODIGO_ART
      AND ts.CODIGO_UNIDAD_ARTTAR = u.CODIGO_UNIDAD
      AND ts.CODIGO_TAR_ARTTAR    = t.CODIGO_TAR_ARTTAR
      AND ts.ESACTIVO_ARTTAR      = 'S'
      AND u.CODIGO_UNIDAD <> ''
      AND COALESCE(ts.FECHA_HASTA_ARTTAR, '9999-12-31') >= CURDATE()

LEFT JOIN fza_articulos_tarifas tp
       ON tp.CODIGO_ART_ARTTAR    = u.CODIGO_ART
      AND (tp.CODIGO_UNIDAD_ARTTAR IS NULL OR tp.CODIGO_UNIDAD_ARTTAR = '')
      AND tp.CODIGO_TAR_ARTTAR    = t.CODIGO_TAR_ARTTAR
      AND tp.ESACTIVO_ARTTAR      = 'S'
      AND COALESCE(tp.FECHA_HASTA_ARTTAR, '9999-12-31') >= CURDATE()

LEFT JOIN fza_articulos_proveedores ap
       ON ap.CODIGO_ART_AP            = a.CODIGO_ART_ART
      AND ap.ESPROVEEDORPRINCIPAL_AP  = 'S'
LEFT JOIN fza_proveedores p
       ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP
LEFT JOIN fza_articulos_familias af
       ON af.CODIGO_FAM_FAM = a.CODIGO_FAM_ART
LEFT JOIN fza_ivas_tipos iv
       ON iv.CODIGO_ABREVIATURA_IVA_IVATIP = a.TIPO_IVA_ART
LEFT JOIN sku_desc sd
       ON sd.CODIGO_UNIDAD = u.CODIGO_UNIDAD

ORDER BY t.ORDEN_TAR, a.ORDEN_ART, u.CODIGO_UNIDAD;

-- ----------------------------------------------------------------------------
-- 4. Recreación de vi_tarifas para exponer las nuevas columnas
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS `vi_tarifas`;

CREATE ALGORITHM=UNDEFINED VIEW `vi_tarifas` AS
SELECT
    `fza_tarifas`.`CODIGO_TAR_ARTTAR`         AS `CODIGO_TAR_ARTTAR`,
    `fza_tarifas`.`NOMBRE_TAR_TAR`            AS `NOMBRE_TAR_TAR`,
    `fza_tarifas`.`ESACTIVO_ARTTAR`           AS `ESACTIVO_ARTTAR`,
    `fza_tarifas`.`ORDEN_TAR`                 AS `ORDEN_TAR`,
    `fza_tarifas`.`ESIMP_INCL_TAR`            AS `ESIMP_INCL_TAR`,
    `fza_tarifas`.`ESDEFAULT_TAR`             AS `ESDEFAULT_TAR`,
    `fza_tarifas`.`PORCENTAJE_MARGEN_TAR`     AS `PORCENTAJE_MARGEN_TAR`,
    `fza_tarifas`.`VALOR_MULTIPLO_AJUSTE_TAR` AS `VALOR_MULTIPLO_AJUSTE_TAR`,
    `fza_tarifas`.`VALOR_MENOS_AJUSTE_TAR`    AS `VALOR_MENOS_AJUSTE_TAR`,
    `fza_tarifas`.`INSTANTE_MODIF`            AS `INSTANTE_MODIF`,
    `fza_tarifas`.`INSTANTE_ALTA`             AS `INSTANTE_ALTA`,
    `fza_tarifas`.`USUARIO_ALTA`              AS `USUARIO_ALTA`,
    `fza_tarifas`.`USUARIO_MODIF`             AS `USUARIO_MODIF`
FROM `fza_tarifas`
WHERE `fza_tarifas`.`ESACTIVO_ARTTAR` = 'S'
ORDER BY `fza_tarifas`.`ORDEN_TAR`;

-- ----------------------------------------------------------------------------
-- 5. Verificación rápida
-- ----------------------------------------------------------------------------
SELECT COLUMN_NAME, DATA_TYPE
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'fza_tarifas'
   AND COLUMN_NAME IN ('PORCENTAJE_MARGEN_TAR','VALOR_MULTIPLO_AJUSTE_TAR','VALOR_MENOS_AJUSTE_TAR');

SELECT COLUMN_NAME, DATA_TYPE
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'fza_articulos_tarifas'
   AND COLUMN_NAME IN ('PORCENTAJE_MARGEN_ARTTAR','VALOR_MULTIPLO_AJUSTE_ARTTAR','VALOR_MENOS_AJUSTE_ARTTAR');

COMMIT;
