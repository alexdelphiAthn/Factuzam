-- ============================================================================
--  Atributos básicos para los SKUs de artículos (v2 — granularidad 3 niveles)
-- ----------------------------------------------------------------------------
--  Concepto:
--    Cada valor de atributo (XL, "001" del proveedor, REF-AB12…) tiene un
--    atributo básico asociado que actúa de helper / equivalente estándar.
--    PERO: el significado físico de un valor depende del contexto. Una XL
--    de bañador puede ser 56 cm y una XL de camisa 34 cm.
--
--  Resolución en 3 niveles (de mayor a menor prioridad):
--    1. Override por artículo  → fza_articulos_atributos_basicos.ID_ATB_AAB
--    2. Por conjunto           → fza_atributos_conjuntos_det.ID_ATB_ACD
--    3. Fallback global        → fza_atributos_valores.ID_ATB_AV
--
--  Ejemplos:
--    Conjunto "Tallas Bañador"   → XL → básico "BAÑO_XL = 56 cm"
--    Conjunto "Tallas Camisa H"  → XL → básico "CAMI_XL = 34 cm"
--    Override artículo BAÑO-XYZ  → XL → básico "BAÑO_XL_TALLAJE_USA"
--
--  Idempotente. Migra los ID_ATB_AV globales preexistentes a las filas del
--  detalle de los conjuntos que ya usan ese valor.
-- ============================================================================

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- 1. Ampliación de fza_atributos_basicos
-- ---------------------------------------------------------------------------
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
--    (nivel 3 / fallback global). Se conserva por compatibilidad.
-- ---------------------------------------------------------------------------
ALTER TABLE `fza_atributos_valores`
  ADD COLUMN IF NOT EXISTS `ID_ATB_AV` int(11) NULL DEFAULT NULL
        COMMENT 'FK lógica → fza_atributos_basicos.ID_ATB. Default global del valor cuando no hay conjunto ni override por artículo.'
        AFTER `CODIGO_ART_EXTRA_AV`;

ALTER TABLE `fza_atributos_valores`
  ADD INDEX IF NOT EXISTS `IDX_AV_ATB` (`ID_ATB_AV`);

-- ---------------------------------------------------------------------------
-- 3. FK lógica desde fza_atributos_conjuntos_det hacia fza_atributos_basicos
--    (nivel 2 / por conjunto). Aquí vive el caso XL bañador vs XL camisa.
-- ---------------------------------------------------------------------------
ALTER TABLE `fza_atributos_conjuntos_det`
  ADD COLUMN IF NOT EXISTS `ID_ATB_ACD` int(11) NULL DEFAULT NULL
        COMMENT 'FK → fza_atributos_basicos. Significado del valor dentro de ESTE conjunto (XL=56cm en bañador, XL=34cm en camisa).'
        AFTER `ORDEN_ACD`;

ALTER TABLE `fza_atributos_conjuntos_det`
  ADD INDEX IF NOT EXISTS `IDX_ACD_ATB` (`ID_ATB_ACD`);

-- ---------------------------------------------------------------------------
-- 4. Tabla nueva: override por artículo (nivel 1)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_articulos_atributos_basicos` (
  `CODIGO_ART_AAB` varchar(20) NOT NULL COMMENT 'FK lógica fza_articulos.CODIGO_ART_ART',
  `ID_AV_AAB`      int(11)     NOT NULL COMMENT 'FK lógica fza_atributos_valores.ID_AV',
  `ID_ATB_AAB`     int(11)     NOT NULL COMMENT 'FK lógica fza_atributos_basicos.ID_ATB. Override específico de este artículo.',
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp()
                                       ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`  timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`   varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF`  varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`CODIGO_ART_AAB`, `ID_AV_AAB`)
);
ALTER TABLE `fza_articulos_atributos_basicos`
  ADD INDEX IF NOT EXISTS `IDX_AAB_VAL` (`ID_AV_AAB`),
  ADD INDEX IF NOT EXISTS `IDX_AAB_ATB` (`ID_ATB_AAB`);

-- ---------------------------------------------------------------------------
-- 5. Catálogo demo de atributos básicos
-- ---------------------------------------------------------------------------
INSERT INTO `fza_atributos_basicos`
  (`ID_VA_ATB`, `CODIGO_ATB`, `NOMBRE_ATB`, `DESCRIPCION_ATB`,
   `HEX_ATB`, `VALOR_NUM_ATB`, `UNIDAD_ATB`, `ORDEN_ATB`, `ESACTIVO_ATB`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  -- Colores básicos con HEX de paleta (independiente del artículo)
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

  -- Tallajes "Ropa Standard" — medida pecho aproximada en cm
  ('TAL', 'ROPA_S',   'ROPA S',   'Ropa standard S (44 cm pecho)',  NULL, 44.0, 'cm',  10, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'ROPA_M',   'ROPA M',   'Ropa standard M (46 cm pecho)',  NULL, 46.0, 'cm',  20, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'ROPA_L',   'ROPA L',   'Ropa standard L (48 cm pecho)',  NULL, 48.0, 'cm',  30, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'ROPA_XL',  'ROPA XL',  'Ropa standard XL (50 cm pecho)', NULL, 50.0, 'cm',  40, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'ROPA_XXL', 'ROPA XXL', 'Ropa standard XXL (52 cm)',      NULL, 52.0, 'cm',  50, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'ROPA_XXXL','ROPA XXXL','Ropa standard XXXL (54 cm)',     NULL, 54.0, 'cm',  60, 'S', NOW(), 'SISTEMA', 'SISTEMA'),

  -- Tallajes "Bañador" — medida cintura cm
  ('TAL', 'BANIO_S',  'BAÑADOR S',  'Bañador S (70 cm cintura)',    NULL, 70.0, 'cm', 200, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'BANIO_M',  'BAÑADOR M',  'Bañador M (74 cm cintura)',    NULL, 74.0, 'cm', 210, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'BANIO_L',  'BAÑADOR L',  'Bañador L (78 cm cintura)',    NULL, 78.0, 'cm', 220, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'BANIO_XL', 'BAÑADOR XL', 'Bañador XL (56 cm)',           NULL, 56.0, 'cm', 230, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'BANIO_XXL','BAÑADOR XXL','Bañador XXL (60 cm)',          NULL, 60.0, 'cm', 240, 'S', NOW(), 'SISTEMA', 'SISTEMA'),

  -- Tallajes "Camisa Hombre" — medida cuello cm
  ('TAL', 'CAMI_S',   'CAMISA S',   'Camisa hombre S (36 cm cuello)',  NULL, 36.0, 'cm', 300, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'CAMI_M',   'CAMISA M',   'Camisa hombre M (38 cm cuello)',  NULL, 38.0, 'cm', 310, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'CAMI_L',   'CAMISA L',   'Camisa hombre L (40 cm cuello)',  NULL, 40.0, 'cm', 320, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'CAMI_XL',  'CAMISA XL',  'Camisa hombre XL (34 cm cuello)', NULL, 34.0, 'cm', 330, 'S', NOW(), 'SISTEMA', 'SISTEMA'),

  -- Tallajes calzado EU
  ('TAL', 'EU37',     'EU 37',      'Calzado europeo nº 37',           NULL, 23.5, 'cm', 410, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU38',     'EU 38',      'Calzado europeo nº 38',           NULL, 24.0, 'cm', 420, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU39',     'EU 39',      'Calzado europeo nº 39',           NULL, 24.5, 'cm', 430, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU40',     'EU 40',      'Calzado europeo nº 40',           NULL, 25.0, 'cm', 440, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU41',     'EU 41',      'Calzado europeo nº 41',           NULL, 26.0, 'cm', 450, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU42',     'EU 42',      'Calzado europeo nº 42',           NULL, 26.5, 'cm', 460, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU43',     'EU 43',      'Calzado europeo nº 43',           NULL, 27.0, 'cm', 470, 'S', NOW(), 'SISTEMA', 'SISTEMA'),
  ('TAL', 'EU44',     'EU 44',      'Calzado europeo nº 44',           NULL, 28.0, 'cm', 480, 'S', NOW(), 'SISTEMA', 'SISTEMA')
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
-- 6. Enlace inicial del fallback global por nombre del valor (sólo colores)
-- ---------------------------------------------------------------------------
UPDATE `fza_atributos_valores` av
  JOIN `fza_atributos_basicos` atb
    ON atb.ID_VA_ATB = av.ID_VA_AV
   AND atb.HEX_ATB IS NOT NULL
   AND (
        UPPER(REPLACE(av.AV, ' ', '_')) = UPPER(atb.CODIGO_ATB)
     OR UPPER(av.AV)                    = UPPER(atb.NOMBRE_ATB)
       )
   SET av.ID_ATB_AV = atb.ID_ATB
 WHERE av.ID_VA_AV  = 'CO'
   AND av.ID_ATB_AV IS NULL;

-- ---------------------------------------------------------------------------
-- 7. Migración: el ID_ATB_AV global existente se copia a cada conjunto-det
--    que use el valor (siempre que ese conjunto-det aún no tenga un básico
--    propio). El conjunto puede sobreescribirlo luego.
-- ---------------------------------------------------------------------------
UPDATE `fza_atributos_conjuntos_det` acd
  JOIN `fza_atributos_valores` av ON av.ID_AV = acd.ID_AV_ACD
   SET acd.ID_ATB_ACD = av.ID_ATB_AV
 WHERE acd.ID_ATB_ACD IS NULL
   AND av.ID_ATB_AV IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 8. Vista de apoyo: SKU × atributo × valor × atributo básico EFECTIVO
--    Resolución: override artículo > conjunto > global.
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
    aca.ID_AC_ACA                                 AS ID_AC,
    aab.ID_ATB_AAB                                AS ID_ATB_OVERRIDE,
    acd.ID_ATB_ACD                                AS ID_ATB_CONJUNTO,
    val.ID_ATB_AV                                 AS ID_ATB_GLOBAL,
    COALESCE(aab.ID_ATB_AAB, acd.ID_ATB_ACD, val.ID_ATB_AV) AS ID_ATB_AV,
    CASE
      WHEN aab.ID_ATB_AAB IS NOT NULL THEN 'A'
      WHEN acd.ID_ATB_ACD IS NOT NULL THEN 'C'
      WHEN val.ID_ATB_AV  IS NOT NULL THEN 'G'
      ELSE NULL
    END                                           AS FUENTE_ATB,
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
  FROM fza_articulos_skus       sku
  JOIN fza_atributos_sku        sa   ON sa.CODIGO_UNIDAD_SKU_SA = sku.CODIGO_UNIDAD_SKU
  JOIN fza_atributos_valores    val  ON val.ID_AV               = sa.ID_AV_SA
  LEFT JOIN fza_variaciones_atributos va
                                     ON va.ID_VAR_VA = sku.CODIGO_VAR_SKU
                                    AND va.ID_ATB_VA = val.ID_VA_AV
  -- Override por artículo (nivel 1)
  LEFT JOIN fza_articulos_atributos_basicos aab
                                     ON aab.CODIGO_ART_AAB = sku.CODIGO_ART_SKU
                                    AND aab.ID_AV_AAB      = val.ID_AV
  -- Conjunto asignado al artículo para este atributo (nivel 2)
  LEFT JOIN fza_articulos_conjuntos_asign aca
                                     ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU
                                    AND aca.ID_VA_ACA      = val.ID_VA_AV
  LEFT JOIN fza_atributos_conjuntos_det acd
                                     ON acd.ID_AC_ACD = aca.ID_AC_ACA
                                    AND acd.ID_AV_ACD = val.ID_AV
  -- Básico efectivo según prioridad
  LEFT JOIN fza_atributos_basicos atb
                                     ON atb.ID_ATB = COALESCE(
                                          aab.ID_ATB_AAB,
                                          acd.ID_ATB_ACD,
                                          val.ID_ATB_AV);

-- ---------------------------------------------------------------------------
-- 9. Registro del nuevo formulario en fza_winforms
-- ---------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('AtributosBasicos', 'Atributos básicos', 'mnuAtributosBasicos',
   'inMtoAtributosBasicos.TfrmMtoAtributosBasicos',
   'Ctrl+Alt+B',
   'UniDataAtributosBasicos.TdmAtributosBasicos', 1)
ON DUPLICATE KEY UPDATE
  `CAPTION_WINF` = VALUES(`CAPTION_WINF`),
  `UNITF_WINF`   = VALUES(`UNITF_WINF`),
  `DATAMODULE_WINF` = VALUES(`DATAMODULE_WINF`);

COMMIT;
