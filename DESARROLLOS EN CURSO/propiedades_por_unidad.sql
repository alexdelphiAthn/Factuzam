-- ============================================================================
-- propiedades_por_unidad.sql  —  FASE 1 (modelo de datos)
--
-- Amplia el espectro de fza_articulos_propiedades para que CUALQUIER propiedad
-- (TEMPORADA, MATERIAL, ...) pueda vivir a tres niveles, replicando el mismo
-- mecanismo que ya usan tarifas (CODIGO_UNIDAD_ARTTAR) y fotos
-- (CODIGO_UNIDAD_FOT):
--
--   CODIGO_UNIDAD_ARTPROP = ''                 -> propiedad del ARTICULO (padre)
--   CODIGO_UNIDAD_ARTPROP = 'ART/COLOR'        -> propiedad del COLOR (sku parcial)
--   CODIGO_UNIDAD_ARTPROP = 'ART/COLOR/TALLA'  -> propiedad del SKU completo
--
-- Resolucion efectiva (igual que ResolverPrecio de tarifas): se coge la fila
-- mas especifica que exista y, si no hay, se cae al nivel superior:
--   SKU completo  ->  COLOR  ->  ARTICULO ('').
--
-- El "color" es el prefijo del SKU hasta antes de la talla, tal como ya hace
-- el fallback de fotos (ej: 'BLUS-SEDA/BLANCO' para el SKU 'BLUS-SEDA/BLANCO/L').
--
-- Que propiedades pueden bajar de nivel lo declara la nueva columna
-- NIVEL_PROP de fza_propiedades (ARTICULO < COLOR < SKU). TEMPORADA -> COLOR.
--
-- NO destruye datos: la columna nueva entra con DEFAULT '' , asi que todas las
-- filas actuales quedan como "nivel ARTICULO" = comportamiento de hoy. La app
-- no necesita cambios para seguir funcionando tras este script.
--
-- Todo idempotente: chequea INFORMATION_SCHEMA antes de aplicar; re-ejecutable.
-- NO se toca factuzam_original.sql (regla dura del repo).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna CODIGO_UNIDAD_ARTPROP en fza_articulos_propiedades
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_propiedades'
     AND COLUMN_NAME  = 'CODIGO_UNIDAD_ARTPROP'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_articulos_propiedades` '
  'ADD COLUMN `CODIGO_UNIDAD_ARTPROP` varchar(50) NOT NULL DEFAULT '''' '
  '  COMMENT ''FK logica fza_articulos_skus.CODIGO_UNIDAD_SKU. '
  'Vacio=articulo; ART/COLOR=color; ART/COLOR/TALLA=sku.'' '
  '  AFTER `CODIGO_PROP_ARTPROP`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Ampliar la PK para incluir el nivel (CODIGO_UNIDAD_ARTPROP)
--    Antes: (CODIGO_ART_ART, CODIGO_PROP_ARTPROP)
--    Ahora: (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP)
-- ---------------------------------------------------------------------------
SET @pk_tiene_unidad := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_propiedades'
     AND INDEX_NAME   = 'PRIMARY'
     AND COLUMN_NAME  = 'CODIGO_UNIDAD_ARTPROP'
);
SET @ddl := IF(@pk_tiene_unidad = 0,
  'ALTER TABLE `fza_articulos_propiedades` '
  'DROP PRIMARY KEY, '
  'ADD PRIMARY KEY (`CODIGO_ART_ART`,`CODIGO_PROP_ARTPROP`,`CODIGO_UNIDAD_ARTPROP`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 3. Indice por unidad (busqueda inversa: todas las props de un color/sku),
--    analogo a IDX_FOT_SKU de fotos.
-- ---------------------------------------------------------------------------
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_propiedades'
     AND INDEX_NAME   = 'IDX_ARTPROP_UNIDAD'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_articulos_propiedades` '
  'ADD INDEX `IDX_ARTPROP_UNIDAD` (`CODIGO_UNIDAD_ARTPROP`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 4. Flag NIVEL_PROP en fza_propiedades: hasta que nivel admite desglose cada
--    propiedad. Dominio: 'ARTICULO' (por defecto) < 'COLOR' < 'SKU'.
--    'COLOR' implica que se puede fijar a nivel articulo y color.
--    'SKU'    implica los tres niveles.
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_propiedades'
     AND COLUMN_NAME  = 'NIVEL_PROP'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_propiedades` '
  'ADD COLUMN `NIVEL_PROP` varchar(10) NOT NULL DEFAULT ''ARTICULO'' '
  '  COMMENT ''Nivel maximo de desglose: ARTICULO < COLOR < SKU'' '
  '  AFTER `TIPO_VALOR_PROP`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 5. TEMPORADA pasa a admitir nivel COLOR (idempotente: solo si sigue siendo
--    ARTICULO no la pisa si manana se sube a SKU a mano).
-- ---------------------------------------------------------------------------
UPDATE `fza_propiedades`
   SET `NIVEL_PROP` = 'COLOR'
 WHERE `CODIGO_PROP_ARTPROP` = 'TEMPORADA'
   AND `NIVEL_PROP` = 'ARTICULO';

-- ---------------------------------------------------------------------------
-- 6. Vista de resolucion efectiva por SKU.
--    Para cada SKU activo y cada propiedad que el articulo tenga a cualquier
--    nivel, devuelve el valor vigente con su origen (SKU/COLOR/ARTICULO),
--    mismo patron COALESCE-por-especificidad que vi_articulos_tarifas.
--    El consumidor (informe / stock / estadistica) filtra por
--    CODIGO_PROP_ARTPROP = 'TEMPORADA'.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_articulos_propiedades_efectivas` AS
SELECT
  sku.CODIGO_ART_SKU                                   AS CODIGO_ART,
  sku.CODIGO_UNIDAD_SKU                                AS CODIGO_UNIDAD_SKU,
  pr.CODIGO_PROP_ARTPROP                               AS CODIGO_PROP_ARTPROP,
  COALESCE(ps.ID_PV_ARTPROP, pc.ID_PV_ARTPROP,
           pa.ID_PV_ARTPROP)                           AS ID_PV_ARTPROP,
  COALESCE(ps.VALOR_LIBRE_ARTPROP, pc.VALOR_LIBRE_ARTPROP,
           pa.VALOR_LIBRE_ARTPROP)                     AS VALOR_LIBRE_ARTPROP,
  pv.PV                                                AS VALOR_PV,
  CASE WHEN ps.CODIGO_ART_ART IS NOT NULL THEN 'SKU'
       WHEN pc.CODIGO_ART_ART IS NOT NULL THEN 'COLOR'
       WHEN pa.CODIGO_ART_ART IS NOT NULL THEN 'ARTICULO'
       ELSE NULL END                                   AS ORIGEN_PROP
FROM fza_articulos_skus sku
JOIN (SELECT DISTINCT CODIGO_ART_ART, CODIGO_PROP_ARTPROP
        FROM fza_articulos_propiedades) pr
  ON pr.CODIGO_ART_ART = sku.CODIGO_ART_SKU
LEFT JOIN fza_articulos_propiedades ps
       ON ps.CODIGO_ART_ART        = sku.CODIGO_ART_SKU
      AND ps.CODIGO_PROP_ARTPROP   = pr.CODIGO_PROP_ARTPROP
      AND ps.CODIGO_UNIDAD_ARTPROP = sku.CODIGO_UNIDAD_SKU
LEFT JOIN fza_articulos_propiedades pc
       ON pc.CODIGO_ART_ART        = sku.CODIGO_ART_SKU
      AND pc.CODIGO_PROP_ARTPROP   = pr.CODIGO_PROP_ARTPROP
      AND pc.CODIGO_UNIDAD_ARTPROP = CASE
            WHEN CHAR_LENGTH(sku.CODIGO_UNIDAD_SKU)
               - CHAR_LENGTH(REPLACE(sku.CODIGO_UNIDAD_SKU, '/', '')) >= 2
            THEN SUBSTRING_INDEX(sku.CODIGO_UNIDAD_SKU, '/', 2)
            ELSE NULL END
LEFT JOIN fza_articulos_propiedades pa
       ON pa.CODIGO_ART_ART        = sku.CODIGO_ART_SKU
      AND pa.CODIGO_PROP_ARTPROP   = pr.CODIGO_PROP_ARTPROP
      AND pa.CODIGO_UNIDAD_ARTPROP = ''
LEFT JOIN fza_propiedades_valores pv
       ON pv.ID_PV_ARTPROP = COALESCE(ps.ID_PV_ARTPROP, pc.ID_PV_ARTPROP,
                                      pa.ID_PV_ARTPROP)
WHERE sku.ESACTIVO_SKU = 'S';

-- ---------------------------------------------------------------------------
-- 7. ROLLBACK (manual, no se ejecuta). Revierte al modelo de hoy.
--    OJO: borrar la columna pierde las propiedades fijadas a color/sku.
-- ---------------------------------------------------------------------------
-- DROP VIEW IF EXISTS `vi_articulos_propiedades_efectivas`;
-- ALTER TABLE `fza_articulos_propiedades`
--   DROP PRIMARY KEY,
--   ADD PRIMARY KEY (`CODIGO_ART_ART`,`CODIGO_PROP_ARTPROP`);
-- ALTER TABLE `fza_articulos_propiedades` DROP INDEX `IDX_ARTPROP_UNIDAD`;
-- ALTER TABLE `fza_articulos_propiedades` DROP COLUMN `CODIGO_UNIDAD_ARTPROP`;
-- ALTER TABLE `fza_propiedades` DROP COLUMN `NIVEL_PROP`;
