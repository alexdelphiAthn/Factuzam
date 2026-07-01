-- ==========================================================================
-- Script: quitar_esdefault_tar.sql
-- Fecha:  2026-05-25
-- Desc:   Elimina la columna ESDEFAULT_TAR de fza_tarifas y actualiza
--         la vista vi_articulos_tarifas para que no la referencie.
--         La tarifa por defecto pasa a gestionarse via parametro de
--         aplicacion (appTarifaDefecto en inLibAppParam), no via flag
--         booleano en la tabla.
--         Idempotente: si la columna ya no existe, no hace nada.
-- ==========================================================================

-- 1. Recrear la vista vi_articulos_tarifas SIN la columna ESDEFAULT_TAR
--    (hay que hacerlo ANTES de borrar la columna para que el DROP no falle
--    si la vista se evalua durante el ALTER)
CREATE OR REPLACE VIEW vi_articulos_tarifas AS
SELECT
  at.CODIGO_ART_ARTTAR                        AS CODIGO_ART_ARTTAR,
  COALESCE(at.CODIGO_UNIDAD_ARTTAR, '')       AS CODIGO_UNIDAD_ARTTAR,
  at.CODIGO_TAR_ARTTAR                        AS CODIGO_TAR_ARTTAR,
  t.NOMBRE_TAR_TAR                            AS NOMBRE_TAR_TAR,
  at.CODIGO_UNICO_ARTTAR                      AS CODIGO_UNICO_ARTTAR,
  CASE WHEN COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') <> ''
       THEN at.CODIGO_UNICO_ARTTAR
       END                                    AS CODIGO_UNICO_TARIFA_SKU,
  CASE WHEN COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') = ''
       THEN at.CODIGO_UNICO_ARTTAR
       END                                    AS CODIGO_UNICO_TARIFA_PADRE,
  CASE WHEN COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') <> ''
       THEN 'ESPECIFICO_SKU'
       ELSE 'PADRE'
       END                                    AS ORIGEN_PRECIO,
  at.PRECIO_SALIDA_ARTTAR                     AS PRECIO_SALIDA_ARTTAR,
  at.PRECIO_FINAL_ARTTAR                      AS PRECIO_FINAL_ARTTAR,
  at.PRECIO_DTO_ARTTAR                        AS PRECIO_DTO_ARTTAR,
  at.PORCENTAJE_DTO_ARTTAR                    AS PORCENTAJE_DTO_ARTTAR,
  at.PORCENTAJE_MARGEN_ARTTAR                 AS PORCENTAJE_MARGEN_ARTTAR,
  at.VALOR_MULTIPLO_AJUSTE_ARTTAR             AS VALOR_MULTIPLO_AJUSTE_ARTTAR,
  at.VALOR_MENOS_AJUSTE_ARTTAR                AS VALOR_MENOS_AJUSTE_ARTTAR,
  COALESCE(at.PORCENTAJE_MARGEN_ARTTAR,
           t.PORCENTAJE_MARGEN_TAR)            AS PORCENTAJE_MARGEN_EFECTIVO,
  COALESCE(at.VALOR_MULTIPLO_AJUSTE_ARTTAR,
           t.VALOR_MULTIPLO_AJUSTE_TAR)        AS VALOR_MULTIPLO_AJUSTE_EFECTIVO,
  COALESCE(at.VALOR_MENOS_AJUSTE_ARTTAR,
           t.VALOR_MENOS_AJUSTE_TAR)           AS VALOR_MENOS_AJUSTE_EFECTIVO,
  at.FECHA_DESDE_ARTTAR                       AS FECHA_DESDE_ARTTAR,
  at.FECHA_HASTA_ARTTAR                       AS FECHA_HASTA_ARTTAR,
  t.ESACTIVO_ARTTAR                           AS ESACTIVO_ARTTAR,
  t.ESIMP_INCL_TAR                            AS ESIMP_INCL_TAR,
  a.DESCRIPCION_ART                           AS DESCRIPCION_ART,
  a.TIPO_CANTIDAD_ART                         AS TIPO_CANTIDAD_ART,
  a.ESVARIACION_ART                           AS ESVARIACION_ART,
  iv.CODIGO_ABREVIATURA_IVA_IVATIP            AS TIPO_IVA_ARTICULO,
  CASE WHEN tiene_sku.CODIGO_ART_SKU IS NOT NULL
       THEN 'S' ELSE 'N'
       END                                    AS TIENE_SKU,
  sku.ESACTIVO_SKU                            AS ESACTIVO_SKU,
  (SELECT GROUP_CONCAT(av.AV
                       ORDER BY av.ORDEN_AV ASC
                       SEPARATOR ' / ')
   FROM fza_atributos_sku sa
   JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA
   WHERE sa.CODIGO_UNIDAD_SKU_SA = at.CODIGO_UNIDAD_ARTTAR
  )                                            AS DESCRIPCION_SKU,
  ap.CODIGO_PRV_AP                             AS CODIGO_PRV_PRV,
  p.RAZON_SOCIAL_PRV                           AS RAZON_SOCIAL_PRV,
  CASE WHEN COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') <> ''
       THEN skuc.PRECIO_ULT_COMPRA_SKUC
       ELSE ap.PRECIO_ULT_COMPRA_AP
       END                                    AS PRECIO_ULT_COMPRA,
  CASE WHEN COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') <> ''
       THEN skuc.FECHA_ULT_COMPRA_SKUC
       ELSE ap.FECHA_VALIDEZ_AP
       END                                    AS FECHA_VALIDEZ,
  a.CODIGO_FAM_ART                            AS CODIGO_FAM_ART,
  af.DESCRIPCION_FAM                          AS DESCRIPCION_FAM,
  COALESCE(num_atr.NUM_ATRIBUTOS_REQ, 0)      AS NUM_ATRIBUTOS_REQ,
  at.INSTANTE_MODIF                           AS INSTANTE_MODIF,
  at.INSTANTE_ALTA                            AS INSTANTE_ALTA,
  at.USUARIO_ALTA                             AS USUARIO_ALTA,
  at.USUARIO_MODIF                            AS USUARIO_MODIF
FROM fza_articulos_tarifas at
  JOIN fza_articulos a ON a.CODIGO_ART_ART = at.CODIGO_ART_ARTTAR
  JOIN fza_tarifas    t ON t.CODIGO_TAR_ARTTAR = at.CODIGO_TAR_ARTTAR
  LEFT JOIN fza_articulos_skus sku
         ON sku.CODIGO_UNIDAD_SKU = at.CODIGO_UNIDAD_ARTTAR
        AND COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') <> ''
  LEFT JOIN fza_articulos_skus_costes skuc
         ON skuc.CODIGO_UNIDAD_SKU_SKUC = at.CODIGO_UNIDAD_ARTTAR
        AND COALESCE(at.CODIGO_UNIDAD_ARTTAR,'') <> ''
  LEFT JOIN fza_articulos_proveedores ap
         ON ap.CODIGO_ART_AP = a.CODIGO_ART_ART
        AND ap.ESPROVEEDORPRINCIPAL_AP = 'S'
  LEFT JOIN fza_proveedores p
         ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP
  LEFT JOIN fza_articulos_familias af
         ON af.CODIGO_FAM_FAM = a.CODIGO_FAM_ART
  LEFT JOIN fza_ivas_tipos iv
         ON iv.CODIGO_ABREVIATURA_IVA_IVATIP = a.TIPO_IVA_ART
  LEFT JOIN (SELECT DISTINCT CODIGO_ART_SKU
               FROM fza_articulos_skus
              WHERE ESACTIVO_SKU = 'S') tiene_sku
         ON tiene_sku.CODIGO_ART_SKU = a.CODIGO_ART_ART
  LEFT JOIN (SELECT sk.CODIGO_ART_SKU,
                    COUNT(DISTINCT va.ID_ATB_VA) AS NUM_ATRIBUTOS_REQ
               FROM fza_articulos_skus sk
               JOIN fza_variaciones_atributos va ON va.ID_VAR_VA = sk.CODIGO_VAR_SKU
              GROUP BY sk.CODIGO_ART_SKU) num_atr
         ON num_atr.CODIGO_ART_SKU = a.CODIGO_ART_ART
WHERE at.ESACTIVO_ARTTAR = 'S'
  AND t.ESACTIVO_ARTTAR  = 'S'
  AND (at.FECHA_HASTA_ARTTAR IS NULL OR at.FECHA_HASTA_ARTTAR >= CURDATE())
ORDER BY t.ORDEN_TAR, a.ORDEN_ART, at.CODIGO_UNIDAD_ARTTAR;

-- 2. Recrear vi_tarifas SIN ESDEFAULT_TAR
CREATE OR REPLACE VIEW vi_tarifas AS
SELECT
  CODIGO_TAR_ARTTAR,
  NOMBRE_TAR_TAR,
  ESACTIVO_ARTTAR,
  ORDEN_TAR,
  ESIMP_INCL_TAR,
  PORCENTAJE_MARGEN_TAR,
  VALOR_MULTIPLO_AJUSTE_TAR,
  VALOR_MENOS_AJUSTE_TAR,
  INSTANTE_MODIF,
  INSTANTE_ALTA,
  USUARIO_ALTA,
  USUARIO_MODIF
FROM fza_tarifas
WHERE ESACTIVO_ARTTAR = 'S'
ORDER BY ORDEN_TAR;

-- 3. Recrear vi_art_busquedas: el JOIN a fza_tarifas ya no filtra por
--    ESDEFAULT_TAR='S'; en su lugar filtra por la tarifa con menor ORDEN_TAR.
CREATE OR REPLACE VIEW vi_art_busquedas AS
SELECT
  a.CODIGO_ART_ART,
  a.ESACTIVO_ART,
  a.DESCRIPCION_ART,
  a.CODIGO_FAM_ART,
  af.DESCRIPCION_FAM,
  ap.CODIGO_PRV_AP                       AS CODIGO_PRV_PRV,
  p.RAZON_SOCIAL_PRV                     AS RAZON_SOCIAL_PROVEEDOR,
  ap.REF_PROVEEDOR_AP                    AS REF_PROVEEDOR,
  ap.ESPROVEEDORPRINCIPAL_AP             AS ESPROVEEDORPRINCIPAL,
  ap.PRECIO_ULT_COMPRA_AP               AS PRECIO_ULT_COMPRA,
  at2.CODIGO_TAR_ARTTAR,
  t.NOMBRE_TAR_TAR,
  at2.PRECIO_SALIDA_ARTTAR,
  at2.PRECIO_DTO_ARTTAR,
  at2.PORCENTAJE_DTO_ARTTAR,
  at2.PRECIO_FINAL_ARTTAR,
  at2.FECHA_DESDE_ARTTAR,
  at2.FECHA_HASTA_ARTTAR,
  t.ESIMP_INCL_TAR,
  iv.NOMBRE_TIPO_IVA_IVATIP,
  a.TIPO_IVA_ART,
  a.TIPO_CANTIDAD_ART,
  a.USUARIO_MODIF,
  a.INSTANTE_ALTA,
  a.INSTANTE_MODIF,
  a.USUARIO_ALTA,
  a.ESACTIVO_FIJO_ART
FROM fza_articulos a
LEFT JOIN fza_articulos_familias af
       ON af.CODIGO_FAM_FAM = a.CODIGO_FAM_ART
LEFT JOIN fza_articulos_tarifas at2
       ON at2.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART
      AND IFNULL(at2.CODIGO_UNIDAD_ARTTAR, '') = ''
      AND at2.ESACTIVO_ARTTAR = 'S'
LEFT JOIN fza_tarifas t
       ON t.CODIGO_TAR_ARTTAR = at2.CODIGO_TAR_ARTTAR
      AND t.ESACTIVO_ARTTAR = 'S'
      AND t.ORDEN_TAR = (SELECT MIN(t2.ORDEN_TAR)
                           FROM fza_tarifas t2
                          WHERE t2.ESACTIVO_ARTTAR = 'S')
LEFT JOIN fza_ivas_tipos iv
       ON iv.CODIGO_ABREVIATURA_IVA_IVATIP = a.TIPO_IVA_ART
LEFT JOIN fza_articulos_proveedores ap
       ON ap.CODIGO_ART_AP = a.CODIGO_ART_ART
      AND ap.ESPROVEEDORPRINCIPAL_AP = 'S'
LEFT JOIN fza_proveedores p
       ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP
WHERE a.ESACTIVO_ART = 'S'
ORDER BY a.ORDEN_ART;

-- 4. Eliminar la columna ESDEFAULT_TAR de fza_tarifas
SET @dbname = DATABASE();
SET @tablename = 'fza_tarifas';
SET @columnname = 'ESDEFAULT_TAR';

SET @col_exists = (SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @dbname
    AND TABLE_NAME   = @tablename
    AND COLUMN_NAME  = @columnname);

SET @ddl = IF(@col_exists > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP COLUMN `', @columnname, '`'),
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. Limpiar entradas huerfanas de ESDEFAULT_TARIFA en perfiles de grids
DELETE FROM fza_usuarios_perfiles
 WHERE SUBKEY_USUPER LIKE '%ESDEFAULT_TARIFA%';
