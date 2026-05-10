-- ============================================================================
-- Migración: coste por SKU (fza_articulos_skus_costes) + adaptación de vistas
--            vi_articulos_skus_con_coste y vi_articulos_tarifas para que el
--            coste de un artículo CON SKUs salga del SKU concreto y no del
--            proveedor principal. Para artículos SIN SKU se conserva el
--            coste del proveedor principal.
-- Fecha:   2026-05-10
-- Rama:    claude/add-sku-cost-tracking-cQ2BE
--
-- Aplica este script DESPUÉS de actualizar el ejecutable a la versión que
-- incluye las columnas nuevas en la pestaña SKU del mantenimiento de
-- artículos y la lógica de upsert sobre fza_articulos_skus_costes.
--
-- Sin esta migración:
--   * la pestaña SKU pedirá columnas que aún no existen
--   * la pestaña Tarifa seguirá mostrando el coste del proveedor principal
--     incluso para artículos con SKUs
-- ============================================================================

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Tabla nueva: un coste y una fecha de última compra por SKU.
--    Sufijo SKUC (mnemo: SKU + Coste).
--    OJO: COLLATE explícito a utf8mb4_spanish_ci, igual que el resto del
--    esquema. Si se omite, MariaDB 10.11+ usa utf8mb4_uca1400_ai_ci por
--    defecto y los JOIN contra fza_articulos_skus revientan con
--    "Illegal mix of collations".
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_articulos_skus_costes` (
  `CODIGO_UNIDAD_SKU_SKUC`  varchar(50)   NOT NULL COMMENT 'FK hacia fza_articulos_skus.CODIGO_UNIDAD_SKU',
  `PRECIO_ULT_COMPRA_SKUC`  decimal(19,6) DEFAULT NULL,
  `FECHA_ULT_COMPRA_SKUC`   date          DEFAULT NULL,
  `INSTANTE_MODIF`          timestamp     NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`           timestamp     NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`            varchar(100)  NOT NULL,
  `USUARIO_MODIF`           varchar(100)  NOT NULL,
  PRIMARY KEY (`CODIGO_UNIDAD_SKU_SKUC`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Reparación idempotente: si la migración se aplicó antes de añadir el
-- COLLATE explícito, la tabla quedó en utf8mb4_uca1400_ai_ci y los JOIN
-- contra fza_articulos_skus.CODIGO_UNIDAD_SKU (utf8mb4_spanish_ci) fallan.
-- CONVERT TO afecta también a las columnas varchar de la tabla.
ALTER TABLE `fza_articulos_skus_costes`
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

-- Índice por fecha de última compra (consultas de "qué he comprado este mes").
-- Idempotente: si ya existe (por una pasada anterior de la migración) lo
-- saltamos.
SET @has_idx := (SELECT COUNT(*) FROM information_schema.statistics
                  WHERE table_schema = DATABASE()
                    AND table_name   = 'fza_articulos_skus_costes'
                    AND index_name   = 'IDX_SKUC_FECHA_ULT_COMPRA');
SET @sql := IF(@has_idx = 0,
  'ALTER TABLE fza_articulos_skus_costes ADD INDEX IDX_SKUC_FECHA_ULT_COMPRA (FECHA_ULT_COMPRA_SKUC)',
  'SELECT ''IDX_SKUC_FECHA_ULT_COMPRA ya existe'' AS info');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. Pre-poblado: para los SKUs ya existentes copiamos el coste / fecha del
--    proveedor principal del artículo padre. Así la pestaña Tarifa no pierde
--    el dato visible que ya mostraba antes del cambio.
--    A partir de ahora, cualquier nuevo coste de un SKU se gestionará en esta
--    tabla; el del proveedor principal sólo gobierna a artículos SIN SKU.
-- ----------------------------------------------------------------------------
INSERT IGNORE INTO `fza_articulos_skus_costes`
       (`CODIGO_UNIDAD_SKU_SKUC`, `PRECIO_ULT_COMPRA_SKUC`,
        `FECHA_ULT_COMPRA_SKUC`,
        `INSTANTE_ALTA`,         `USUARIO_ALTA`,
        `USUARIO_MODIF`)
SELECT sku.`CODIGO_UNIDAD_SKU`,
       ap.`PRECIO_ULT_COMPRA_AP`,
       DATE(ap.`FECHA_VALIDEZ_AP`),
       CURRENT_TIMESTAMP,
       'MIGRACION',
       'MIGRACION'
  FROM `fza_articulos_skus` sku
  JOIN `fza_articulos_proveedores` ap
    ON ap.`CODIGO_ART_AP`           = sku.`CODIGO_ART_SKU`
   AND ap.`ESPROVEEDORPRINCIPAL_AP` = 'S'
 WHERE ap.`PRECIO_ULT_COMPRA_AP` IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3. Vista auxiliar: SKU + coste resuelto. La pestaña SKU del mantenimiento
--    de artículos lee de aquí.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS `vi_articulos_skus_con_coste`;

CREATE ALGORITHM=UNDEFINED VIEW `vi_articulos_skus_con_coste` AS
SELECT
  sku.`CODIGO_UNIDAD_SKU`     AS `CODIGO_UNIDAD_SKU`,
  sku.`CODIGO_ART_SKU`        AS `CODIGO_ART_SKU`,
  sku.`CODIGO_VAR_SKU`        AS `CODIGO_VAR_SKU`,
  sku.`ESACTIVO_SKU`          AS `ESACTIVO_SKU`,
  skuc.`PRECIO_ULT_COMPRA_SKUC` AS `PRECIO_ULT_COMPRA_SKUC`,
  skuc.`FECHA_ULT_COMPRA_SKUC`  AS `FECHA_ULT_COMPRA_SKUC`,
  sku.`INSTANTE_MODIF`        AS `INSTANTE_MODIF`,
  sku.`INSTANTE_ALTA`         AS `INSTANTE_ALTA`,
  sku.`USUARIO_ALTA`          AS `USUARIO_ALTA`,
  sku.`USUARIO_MODIF`         AS `USUARIO_MODIF`
FROM `fza_articulos_skus` sku
LEFT JOIN `fza_articulos_skus_costes` skuc
  ON skuc.`CODIGO_UNIDAD_SKU_SKUC` = sku.`CODIGO_UNIDAD_SKU`;

-- ----------------------------------------------------------------------------
-- 4. Recreación de vi_articulos_tarifas: el coste / fecha vienen del SKU
--    cuando el artículo TIENE SKUs (TIENE_SKU='S'); del proveedor principal
--    cuando NO los tiene. Esto reemplaza la versión de la migración 137.
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

    -- Proveedor principal (sólo informativo; el coste no sale de aquí
    -- cuando el artículo tiene SKUs)
    ap.CODIGO_PRV_AP                                                AS CODIGO_PRV_PRV,
    p.RAZON_SOCIAL_PRV                                              AS RAZON_SOCIAL_PRV,

    -- Coste / fecha "última compra":
    --   * Si TIENE_SKU='S': coste de la fila SKU (fza_articulos_skus_costes).
    --   * Si TIENE_SKU='N': coste del proveedor principal.
    CASE WHEN u.TIENE_SKU = 'S'
         THEN skuc.PRECIO_ULT_COMPRA_SKUC
         ELSE ap.PRECIO_ULT_COMPRA_AP
    END                                                             AS PRECIO_ULT_COMPRA,
    CASE WHEN u.TIENE_SKU = 'S'
         THEN skuc.FECHA_ULT_COMPRA_SKUC
         ELSE ap.FECHA_VALIDEZ_AP
    END                                                             AS FECHA_VALIDEZ,

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
LEFT JOIN fza_articulos_skus_costes skuc
       ON skuc.CODIGO_UNIDAD_SKU_SKUC = u.CODIGO_UNIDAD

-- Sólo mostramos filas que ya tengan precio (específico o heredado del
-- padre). Para añadir precio a un SKU sin tarifa el usuario usa el botón
-- "Añadir precio" en la pestaña Tarifas.
WHERE ts.CODIGO_UNICO_ARTTAR IS NOT NULL
   OR tp.CODIGO_UNICO_ARTTAR IS NOT NULL

ORDER BY t.ORDEN_TAR, a.ORDEN_ART, u.CODIGO_UNIDAD;

-- ----------------------------------------------------------------------------
-- 5. Verificación rápida
-- ----------------------------------------------------------------------------
SELECT 'fza_articulos_skus_costes' AS objeto,
       COUNT(*)                    AS filas
  FROM fza_articulos_skus_costes
UNION ALL
SELECT 'vi_articulos_skus_con_coste',
       COUNT(*)
  FROM vi_articulos_skus_con_coste;

COMMIT;
