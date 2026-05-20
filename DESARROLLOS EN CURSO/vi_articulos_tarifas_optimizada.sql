-- ============================================================================
--  vi_articulos_tarifas — Version optimizada
-- ----------------------------------------------------------------------------
--  Problema:
--    La version original tardaba ~6 segundos en un filtro como
--    WHERE CODIGO_ART_ARTTAR = '01010002'. El EXPLAIN revelaba tres cuellos:
--
--    1. DEPENDENT SUBQUERY TIENE_SKU      → 119 lookups por fila resultado
--    2. DEPENDENT SUBQUERY NUM_ATRIBUTOS_REQ → JOIN + GROUP por fila
--    3. CTE sku_desc materializado        → full scan av (3837 filas) +
--                                            Using temporary + Using filesort
--
--    Para 15 tarifas de un articulo, esto disparaba miles de operaciones
--    secundarias en cada apertura.
--
--  Cambios respecto al original:
--
--    A. CTE sku_desc eliminado. La descripcion del SKU se calcula con una
--       subquery escalar en el SELECT. Asi se evalua una vez por fila
--       resultado (~15) con indice por CODIGO_UNIDAD_SKU_SA, en lugar de
--       materializar todo el conjunto agrupado.
--
--    B. TIENE_SKU pasa a LEFT JOIN con sub-tabla derivada DISTINCT (un solo
--       paso por todos los artículos con SKU activo, vs N pasos individuales).
--
--    C. NUM_ATRIBUTOS_REQ pasa a LEFT JOIN agregado, calculado una sola vez
--       por articulo y reusable.
--
--    D. FECHA_HASTA_ARTTAR > = curdate() pasa a sargeable
--       (IS NULL OR >= curdate()) — usa indice si existe.
--
--  Resultado esperado: el WHERE en vi_articulos_tarifas debe pasar de ~6s
--  a < 200 ms tras crear los indices recomendados al final del script.
--
--  Idempotente: CREATE OR REPLACE VIEW + CREATE INDEX IF NOT EXISTS.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Reemplazo de la vista
-- ---------------------------------------------------------------------------
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
  t.ESDEFAULT_TAR                             AS ESDEFAULT_TAR,
  a.DESCRIPCION_ART                           AS DESCRIPCION_ART,
  a.TIPO_CANTIDAD_ART                         AS TIPO_CANTIDAD_ART,
  a.ESVARIACION_ART                           AS ESVARIACION_ART,
  iv.CODIGO_ABREVIATURA_IVA_IVATIP            AS TIPO_IVA_ARTICULO,
  -- (B) TIENE_SKU: antes DEPENDENT SUBQUERY; ahora LEFT JOIN DISTINCT.
  CASE WHEN tiene_sku.CODIGO_ART_SKU IS NOT NULL
       THEN 'S' ELSE 'N'
       END                                    AS TIENE_SKU,
  sku.ESACTIVO_SKU                            AS ESACTIVO_SKU,
  -- (A) DESCRIPCION_SKU: antes CTE sku_desc materializado;
  -- ahora subquery escalar (15 ejecuciones con indice vs 1 full-scan + filesort).
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
  -- (C) NUM_ATRIBUTOS_REQ: antes DEPENDENT SUBQUERY con JOIN + GROUP por fila;
  -- ahora LEFT JOIN agregado precalculado por articulo.
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
  -- (B) Sub-tabla DISTINCT de articulos con al menos un SKU activo.
  LEFT JOIN (
    SELECT DISTINCT CODIGO_ART_SKU
    FROM fza_articulos_skus
    WHERE ESACTIVO_SKU = 'S'
  ) tiene_sku ON tiene_sku.CODIGO_ART_SKU = a.CODIGO_ART_ART
  -- (C) Sub-tabla agregada con el numero de atributos requeridos por articulo.
  LEFT JOIN (
    SELECT sk.CODIGO_ART_SKU,
           COUNT(DISTINCT va.ID_ATB_VA) AS NUM_ATRIBUTOS_REQ
    FROM fza_articulos_skus sk
    JOIN fza_variaciones_atributos va ON va.ID_VAR_VA = sk.CODIGO_VAR_SKU
    GROUP BY sk.CODIGO_ART_SKU
  ) num_atr ON num_atr.CODIGO_ART_SKU = a.CODIGO_ART_ART
WHERE at.ESACTIVO_ARTTAR = 'S'
  AND t.ESACTIVO_ARTTAR = 'S'
  -- (D) Sargeable: usa indice sobre FECHA_HASTA_ARTTAR si existe.
  AND (at.FECHA_HASTA_ARTTAR IS NULL OR at.FECHA_HASTA_ARTTAR >= CURDATE())
ORDER BY t.ORDEN_TAR, a.ORDEN_ART, at.CODIGO_UNIDAD_ARTTAR;

-- ---------------------------------------------------------------------------
-- 2. Indices auxiliares (idempotentes — solo se crean si no existen)
--    MariaDB acepta CREATE INDEX IF NOT EXISTS desde 10.5.
-- ---------------------------------------------------------------------------

-- Para el WHERE sargeable de FECHA_HASTA_ARTTAR + ESACTIVO_ARTTAR:
CREATE INDEX IF NOT EXISTS IDX_ARTTAR_VIGENCIA
  ON fza_articulos_tarifas (ESACTIVO_ARTTAR, FECHA_HASTA_ARTTAR);

-- Para la subquery escalar DESCRIPCION_SKU sobre fza_atributos_sku:
-- el indice por CODIGO_UNIDAD_SKU_SA suele existir, pero por si acaso.
CREATE INDEX IF NOT EXISTS IDX_SA_UNIDAD
  ON fza_atributos_sku (CODIGO_UNIDAD_SKU_SA);

-- Para los LEFT JOIN tiene_sku / num_atr sobre fza_articulos_skus:
-- ya hay IDX_SKU_ART_ACT segun el EXPLAIN — no se crea de nuevo.

-- ---------------------------------------------------------------------------
-- 3. Verificacion manual (no se ejecuta automaticamente)
-- ---------------------------------------------------------------------------
-- Tras aplicar el script, comparar el plan antes/despues:
--
--   EXPLAIN SELECT * FROM vi_articulos_tarifas
--   WHERE CODIGO_ART_ARTTAR = '01010002';
--
-- Lo esperado:
--   - Ya no aparecen filas con select_type = DEPENDENT SUBQUERY.
--   - El DERIVED del CTE sku_desc desaparece.
--   - tiene_sku y num_atr aparecen como DERIVED (con id distinto al PRIMARY)
--     pero MariaDB los puede materializar en hash join eficiente.
--   - rows totales estimadas en miles, no en cientos de miles.
--
-- Y medir tiempos reales con:
--
--   ANALYZE FORMAT=JSON SELECT * FROM vi_articulos_tarifas
--   WHERE CODIGO_ART_ARTTAR = '01010002';
