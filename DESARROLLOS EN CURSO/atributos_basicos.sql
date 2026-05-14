-- ============================================================================
--  Atributos básicos para los SKUs de artículos
-- ----------------------------------------------------------------------------
--  Concepto:
--    Cada valor de atributo (fza_atributos_valores) puede tener un atributo
--    básico asociado, que actúa como helper / equivalente "estándar" que
--    ayuda a entender el valor real.
--
--  Ejemplos:
--    TALLA "XL"            → atributo básico "XL = 47 cm"     (medida real)
--    COLOR "001" proveedor → atributo básico "AZUL CIELO + #87CEEB"
--    COLOR "REF-AB12"      → atributo básico "ROJO + #FF0000"
--
--  Tablas implicadas:
--    fza_atributos_basicos          Catálogo de atributos básicos / estándar.
--    fza_atributos_valores          Recibe nueva FK ID_ATB_AV → ATB.
--    fza_atributos_sku              Sin cambios (ya enlaza SKU↔valor).
--    fza_articulos_skus             Sin cambios (cabecera del SKU).
--
--  Idempotente: las ALTER usan IF NOT EXISTS (MariaDB 10.4+/MySQL 8) o se
--  envuelven en bloques PREPARE; ejecutables varias veces sin error.
-- ============================================================================

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- 1. Ampliación de fza_atributos_basicos
-- ---------------------------------------------------------------------------
--   Estructura previa: ID_ATB, ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, EXTRA_ATB,
--   ORDEN_ATB, ESACTIVO_ATB.
--
--   EXTRA_ATB se queda como legacy. Las nuevas columnas son explícitas para
--   poder representar bien el color (HEX) y la medida básica (47 cm, 50 mm…).
ALTER TABLE `fza_atributos_basicos`
  ADD COLUMN IF NOT EXISTS `DESCRIPCION_ATB` varchar(255) NULL DEFAULT NULL
        COMMENT 'Descripción larga: AZUL CIELO, Talla XL Hombre, etc.'
        AFTER `NOMBRE_ATB`,
  ADD COLUMN IF NOT EXISTS `HEX_ATB` varchar(7) NULL DEFAULT NULL
        COMMENT 'Color paleta en formato #RRGGBB (sólo para atributos de color)'
        AFTER `DESCRIPCION_ATB`,
  ADD COLUMN IF NOT EXISTS `VALOR_NUM_ATB` decimal(12,4) NULL DEFAULT NULL
        COMMENT 'Valor numérico básico (47 cm de talla XL, 50 mm de diámetro…)'
        AFTER `HEX_ATB`,
  ADD COLUMN IF NOT EXISTS `UNIDAD_ATB` varchar(10) NULL DEFAULT NULL
        COMMENT 'Unidad de VALOR_NUM_ATB: cm, mm, kg, ml…'
        AFTER `VALOR_NUM_ATB`,
  ADD COLUMN IF NOT EXISTS `INSTANTE_MODIF` timestamp NOT NULL
        DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  ADD COLUMN IF NOT EXISTS `INSTANTE_ALTA` timestamp NOT NULL
        DEFAULT '0000-00-00 00:00:00',
  ADD COLUMN IF NOT EXISTS `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  ADD COLUMN IF NOT EXISTS `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA';

-- ---------------------------------------------------------------------------
-- 2. FK lógica desde fza_atributos_valores hacia fza_atributos_basicos
-- ---------------------------------------------------------------------------
ALTER TABLE `fza_atributos_valores`
  ADD COLUMN IF NOT EXISTS `ID_ATB_AV` int(11) NULL DEFAULT NULL
        COMMENT 'FK lógica → fza_atributos_basicos.ID_ATB. Asocia este valor concreto (p. ej. "001" del proveedor) con su atributo básico estándar ("AZUL CIELO").'
        AFTER `CODIGO_ART_EXTRA_AV`;

ALTER TABLE `fza_atributos_valores`
  ADD INDEX IF NOT EXISTS `IDX_AV_ATB` (`ID_ATB_AV`);

-- ---------------------------------------------------------------------------
-- 3. Catálogo demo de atributos básicos
-- ---------------------------------------------------------------------------
--   Los CODIGO_ATB se eligen de modo que sean estables y reusables. Si la
--   fila ya existe (mismo ID_VA_ATB + CODIGO_ATB) se actualiza el resto.

INSERT INTO `fza_atributos_basicos`
  (`ID_VA_ATB`, `CODIGO_ATB`, `NOMBRE_ATB`, `DESCRIPCION_ATB`,
   `HEX_ATB`, `VALOR_NUM_ATB`, `UNIDAD_ATB`, `ORDEN_ATB`, `ESACTIVO_ATB`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  -- Colores básicos con HEX de paleta
  ('CO',  'NEGRO',       'NEGRO',       'Color negro',              '#000000', NULL, NULL,  10, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'BLANCO',      'BLANCO',      'Color blanco',             '#FFFFFF', NULL, NULL,  20, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'ROJO',        'ROJO',        'Color rojo',               '#FF0000', NULL, NULL,  30, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'AZUL',        'AZUL',        'Color azul',               '#0066CC', NULL, NULL,  40, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'AZUL_CIELO',  'AZUL CIELO',  'Color azul cielo',         '#87CEEB', NULL, NULL,  41, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'AZUL_MARINO', 'AZUL MARINO', 'Color azul marino',        '#1B2A49', NULL, NULL,  42, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'VERDE',       'VERDE',       'Color verde',              '#1D8B3A', NULL, NULL,  50, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'AMARILLO',    'AMARILLO',    'Color amarillo',           '#FFD400', NULL, NULL,  60, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'MARRON',      'MARRÓN',      'Color marrón',             '#7B4B2A', NULL, NULL,  70, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'GRIS',        'GRIS',        'Color gris',               '#808080', NULL, NULL,  80, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'BEIGE',       'BEIGE',       'Color beige',              '#E8D8B5', NULL, NULL,  90, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'ROSA',        'ROSA',        'Color rosa',               '#F4A6C0', NULL, NULL, 100, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'CAMEL',       'CAMEL',       'Color camel / tostado',    '#C19A6B', NULL, NULL, 110, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'FUCSIA',      'FUCSIA',      'Color fucsia',             '#FF00FF', NULL, NULL, 120, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'BURDEOS',     'BURDEOS',     'Color burdeos',            '#7A1F2B', NULL, NULL, 130, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('CO',  'VAQUERO',     'VAQUERO',     'Acabado vaquero / denim',  '#3F6BAA', NULL, NULL, 140, 'S', NOW(), 'SISTEMA', 'SISTEMA'),

  -- Tallas básicas de ropa con medida pecho aproximada en cm
  ('TAL', 'S',           'TALLA S',     'Talla S (small)',          NULL,  44.0, 'cm',  10, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'M',           'TALLA M',     'Talla M (medium)',         NULL,  46.0, 'cm',  20, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'L',           'TALLA L',     'Talla L (large)',          NULL,  48.0, 'cm',  30, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'XL',          'TALLA XL',    'Talla XL (extra large)',   NULL,  50.0, 'cm',  40, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'XXL',         'TALLA XXL',   'Talla XXL',                NULL,  52.0, 'cm',  50, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'XXXL',        'TALLA XXXL',  'Talla XXXL',               NULL,  54.0, 'cm',  60, 'S', NOW(), 'SISTEMA', 'SISTEMA'),

  -- Tallas básicas de calzado europeo
  ('TAL', 'EU37',        'EU 37',       'Calzado europeo nº 37',    NULL,  23.5, 'cm',  70, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU38',        'EU 38',       'Calzado europeo nº 38',    NULL,  24.0, 'cm',  80, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU39',        'EU 39',       'Calzado europeo nº 39',    NULL,  24.5, 'cm',  90, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU40',        'EU 40',       'Calzado europeo nº 40',    NULL,  25.0, 'cm', 100, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU41',        'EU 41',       'Calzado europeo nº 41',    NULL,  26.0, 'cm', 110, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU42',        'EU 42',       'Calzado europeo nº 42',    NULL,  26.5, 'cm', 120, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU43',        'EU 43',       'Calzado europeo nº 43',    NULL,  27.0, 'cm', 130, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU44',        'EU 44',       'Calzado europeo nº 44',    NULL,  28.0, 'cm', 140, 'S', NOW(), 'SISTEMA', 'SISTEMA')
ON DUPLICATE KEY UPDATE
  `NOMBRE_ATB`      = VALUES(`NOMBRE_ATB`),
  `DESCRIPCION_ATB` = VALUES(`DESCRIPCION_ATB`),
  `HEX_ATB`         = VALUES(`HEX_ATB`),
  `VALOR_NUM_ATB`   = VALUES(`VALOR_NUM_ATB`),
  `UNIDAD_ATB`      = VALUES(`UNIDAD_ATB`),
  `ORDEN_ATB`       = VALUES(`ORDEN_ATB`),
  `ESACTIVO_ATB`    = VALUES(`ESACTIVO_ATB`),
  `USUARIO_MODIF`   = 'SISTEMA';

-- ---------------------------------------------------------------------------
-- 4. Enlace inicial de valores existentes con su atributo básico
-- ---------------------------------------------------------------------------
--   Heurística: si el nombre del valor coincide (mayúsculas sin espacios)
--   con el CODIGO_ATB o NOMBRE_ATB de un atributo básico del mismo
--   ID_VA_AV, se enlaza. Para "AZUL MARINO" en valor → "AZUL_MARINO" en
--   código básico (espacios → guion bajo).
UPDATE `fza_atributos_valores` av
  JOIN `fza_atributos_basicos` atb
    ON atb.ID_VA_ATB = av.ID_VA_AV
   AND (
        UPPER(REPLACE(av.AV, ' ', '_')) = UPPER(atb.CODIGO_ATB)
     OR UPPER(av.AV)                    = UPPER(atb.NOMBRE_ATB)
       )
   SET av.ID_ATB_AV = atb.ID_ATB
 WHERE av.ID_ATB_AV IS NULL;

-- Las tallas de calzado existentes (121=37, 122=38, …) referencian los
-- atributos básicos EU37..EU44 generados arriba.
UPDATE `fza_atributos_valores` av
  JOIN `fza_atributos_basicos` atb
    ON atb.ID_VA_ATB = av.ID_VA_AV
   AND atb.CODIGO_ATB = CONCAT('EU', av.AV)
   SET av.ID_ATB_AV = atb.ID_ATB
 WHERE av.ID_VA_AV  = 'TAL'
   AND av.ID_ATB_AV IS NULL;

-- ---------------------------------------------------------------------------
-- 5. Vista de apoyo: SKU × atributo × valor × atributo básico
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS `vi_atributos_sku_basico`;
CREATE VIEW `vi_atributos_sku_basico` AS
SELECT
    sku.CODIGO_ART_SKU                            AS CODIGO_ART_SKU,
    sku.CODIGO_UNIDAD_SKU                         AS CODIGO_UNIDAD_SKU,
    sku.CODIGO_VAR_SKU                            AS CODIGO_VAR_SKU,
    val.ID_AV                                     AS ID_AV,
    val.ID_VA_AV                                  AS ID_VA_AV,
    va.NOMBRE_VA                                  AS NOMBRE_ATRIBUTO,
    va.ORDEN_VA                                   AS ORDEN_ATRIBUTO,
    val.AV                                        AS VALOR_AV,
    val.DESCRIPCION_AV                            AS DESCRIPCION_AV,
    val.ID_ATB_AV                                 AS ID_ATB_AV,
    atb.CODIGO_ATB                                AS CODIGO_ATB,
    atb.NOMBRE_ATB                                AS NOMBRE_ATB,
    atb.DESCRIPCION_ATB                           AS DESCRIPCION_ATB,
    atb.HEX_ATB                                   AS HEX_ATB,
    atb.VALOR_NUM_ATB                             AS VALOR_NUM_ATB,
    atb.UNIDAD_ATB                                AS UNIDAD_ATB,
    CASE
      WHEN atb.VALOR_NUM_ATB IS NOT NULL
        THEN CONCAT(
               TRIM(TRAILING '0' FROM TRIM(TRAILING '.' FROM
                    CAST(atb.VALOR_NUM_ATB AS CHAR))),
               COALESCE(CONCAT(' ', atb.UNIDAD_ATB), ''))
      WHEN atb.HEX_ATB IS NOT NULL
        THEN CONCAT(atb.NOMBRE_ATB, ' ', atb.HEX_ATB)
      ELSE atb.NOMBRE_ATB
    END                                           AS ETIQUETA_BASICO
  FROM fza_articulos_skus      sku
  JOIN fza_atributos_sku       sa  ON sa.CODIGO_UNIDAD_SKU_SA = sku.CODIGO_UNIDAD_SKU
  JOIN fza_atributos_valores   val ON val.ID_AV               = sa.ID_AV_SA
  LEFT JOIN fza_variaciones_atributos va
                                  ON va.ID_VAR_VA = sku.CODIGO_VAR_SKU
                                 AND va.ID_ATB_VA = val.ID_VA_AV
  LEFT JOIN fza_atributos_basicos atb
                                  ON atb.ID_ATB    = val.ID_ATB_AV;

COMMIT;
