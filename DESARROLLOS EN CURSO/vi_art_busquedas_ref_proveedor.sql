-- =============================================================================
-- vi_art_busquedas: anadir referencia de proveedor a la busqueda de articulos
-- =============================================================================
-- Las busquedas modales de articulos usan esta vista como origen comun. Ya
-- exponen proveedor, familia, temporada y tarifas; faltaba REF_PROVEEDOR_AP
-- del proveedor principal para poder ver el modelo/referencia del proveedor.
--
-- Idempotente: CREATE OR REPLACE VIEW. NO se toca factuzam_original.sql.
-- =============================================================================
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
  ap.PRECIO_ULT_COMPRA_AP                AS PRECIO_ULT_COMPRA,
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
