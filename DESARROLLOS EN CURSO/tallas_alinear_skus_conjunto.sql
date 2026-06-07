-- ============================================================================
--  Alinear el tag de talla de cada SKU con el ID_AV que usa su conjunto
-- ----------------------------------------------------------------------------
--  Problema:
--    El catálogo fza_atributos_valores puede tener VALORES DUPLICADOS para la
--    misma talla (mismo ID_VA_AV='TAL' y mismo texto AV, distinto ID_AV): un
--    lote "limpio" (p.ej. 91xx) y otro "deducido" antiguo (p.ej. 110/4/111).
--    El migrador etiquetaba el SKU (fza_atributos_sku.ID_AV_SA) con un lote y
--    construía el conjunto (fza_atributos_conjuntos_det.ID_AV_ACD) con el otro.
--    El pivote de tallas casa por ID_AV EXACTO, así que para esas tallas no
--    encuentra el SKU y no muestra la rejilla en horizontal.
--
--  Estrategia (canónico = el conjunto):
--    Se re-apunta SOLO el tag del SKU al ID_AV que su conjunto asignado usa
--    para esa talla, casando por TEXTO (AV). NO se tocan las definiciones de
--    conjunto (son compartidas) ni el catálogo de valores. Vale para todos los
--    artículos afectados, no sólo uno.
--
--    En el migrador, para datos NUEVOS, el equivalente ya está corregido:
--    BuscarIdAV / CargarMapaAV resuelven (ID_VA, AV) -> MIN(ID_AV) en todos
--    los paths, así que el SKU y el conjunto coinciden sin este script.
--
--  Idempotente y con rollback. Re-ejecutarlo no cambia nada una vez alineado.
-- ============================================================================
-- 0) BACKUP (rollback): guarda orig->nuevo de cada tag que se vaya a tocar.
CREATE TABLE IF NOT EXISTS bak_atributos_sku_tallas_dup (
  CODIGO_UNIDAD_SKU_SA varchar(50) NOT NULL,
  ID_AV_SA_ORIG        int(11)     NOT NULL,
  ID_AV_SA_NUEVO       int(11)     NOT NULL,
  INSTANTE_BAK         timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (CODIGO_UNIDAD_SKU_SA, ID_AV_SA_ORIG)
);
INSERT IGNORE INTO bak_atributos_sku_tallas_dup
       (CODIGO_UNIDAD_SKU_SA, ID_AV_SA_ORIG, ID_AV_SA_NUEVO)
SELECT sa.CODIGO_UNIDAD_SKU_SA, sa.ID_AV_SA, cv.ID_AV
  FROM fza_atributos_sku sa
  JOIN fza_atributos_valores v   ON v.ID_AV = sa.ID_AV_SA AND v.ID_VA_AV='TAL'
  JOIN fza_articulos_skus sku    ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA
  JOIN fza_articulos_conjuntos_asign aca
    ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU AND aca.ID_VA_ACA='TAL'
  JOIN fza_atributos_conjuntos_det acd ON acd.ID_AC_ACD = aca.ID_AC_ACA
  JOIN fza_atributos_valores cv  ON cv.ID_AV = acd.ID_AV_ACD AND cv.AV = v.AV
 WHERE cv.ID_AV <> v.ID_AV;
-- 1) PREVIEW: revisa qué va a cambiar ANTES de aplicar.
--    (para probar un solo artículo: añade AND sku.CODIGO_ART_SKU = '...')
SELECT sku.CODIGO_ART_SKU AS ART, sa.CODIGO_UNIDAD_SKU_SA AS SKU, v.AV AS TALLA,
       sa.ID_AV_SA AS IDAV_ACTUAL, cv.ID_AV AS IDAV_CONJUNTO
  FROM fza_atributos_sku sa
  JOIN fza_atributos_valores v   ON v.ID_AV = sa.ID_AV_SA AND v.ID_VA_AV='TAL'
  JOIN fza_articulos_skus sku    ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA
  JOIN fza_articulos_conjuntos_asign aca
    ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU AND aca.ID_VA_ACA='TAL'
  JOIN fza_atributos_conjuntos_det acd ON acd.ID_AC_ACD = aca.ID_AC_ACA
  JOIN fza_atributos_valores cv  ON cv.ID_AV = acd.ID_AV_ACD AND cv.AV = v.AV
 WHERE cv.ID_AV <> v.ID_AV
 ORDER BY ART, SKU;
-- 2) APPLY: re-apunta el tag al ID_AV del conjunto. UPDATE IGNORE por si el
--    SKU ya tuviera además el tag correcto (doble tag) -> salta esa fila.
UPDATE IGNORE fza_atributos_sku sa
  JOIN fza_atributos_valores v   ON v.ID_AV = sa.ID_AV_SA AND v.ID_VA_AV='TAL'
  JOIN fza_articulos_skus sku    ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA
  JOIN fza_articulos_conjuntos_asign aca
    ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU AND aca.ID_VA_ACA='TAL'
  JOIN fza_atributos_conjuntos_det acd ON acd.ID_AC_ACD = aca.ID_AC_ACA
  JOIN fza_atributos_valores cv  ON cv.ID_AV = acd.ID_AV_ACD AND cv.AV = v.AV
   SET sa.ID_AV_SA = cv.ID_AV,
       sa.USUARIO_MODIF = 'FIX_TALLAS_DUP', sa.INSTANTE_MODIF = NOW()
 WHERE cv.ID_AV <> v.ID_AV;
-- 3) VERIFY: tallas que SIGUEN fuera del conjunto (debería ser 0, salvo
--    huérfanas reales cuyo texto no exista en el conjunto asignado).
SELECT sku.CODIGO_ART_SKU AS ART, sa.CODIGO_UNIDAD_SKU_SA AS SKU, v.AV AS TALLA
  FROM fza_atributos_sku sa
  JOIN fza_atributos_valores v ON v.ID_AV = sa.ID_AV_SA AND v.ID_VA_AV='TAL'
  JOIN fza_articulos_skus sku  ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA
  JOIN fza_articulos_conjuntos_asign aca
    ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU AND aca.ID_VA_ACA='TAL'
 WHERE NOT EXISTS (SELECT 1 FROM fza_atributos_conjuntos_det acd
                    WHERE acd.ID_AC_ACD = aca.ID_AC_ACA
                      AND acd.ID_AV_ACD = sa.ID_AV_SA)
 ORDER BY ART, SKU;
-- ROLLBACK (si hiciera falta):
-- UPDATE fza_atributos_sku sa
--   JOIN bak_atributos_sku_tallas_dup bak
--     ON bak.CODIGO_UNIDAD_SKU_SA = sa.CODIGO_UNIDAD_SKU_SA
--    AND sa.ID_AV_SA = bak.ID_AV_SA_NUEVO
--    SET sa.ID_AV_SA = bak.ID_AV_SA_ORIG;
