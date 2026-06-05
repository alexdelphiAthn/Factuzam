-- ============================================================================
--  vi_articulos_tarifas_mto — Vista para el GRID DE MANTENIMIENTO de tarifas
--  del articulo (pestana Tarifas de TfrmMtoArticulos)
-- ----------------------------------------------------------------------------
--  Problema:
--    Al pulsar "crear tarifa" la linea se inserta con precio 0; el BeforePost
--    (unqryTarifasArticulosBeforePost) marca como inactiva (ESACTIVO_ARTTAR='N')
--    toda tarifa que nace a 0. La vista de ventas `vi_articulos_tarifas` filtra
--    `WHERE at.ESACTIVO_ARTTAR='S'`, asi que esa fila recien creada NO aparece
--    en el grid (parece que "no anade nada", aunque si esta en la BBDD).
--
--  Solucion:
--    Vista gemela SOLO para el mantenimiento, identica en columnas a
--    vi_articulos_tarifas pero SIN ocultar inactivas ni expiradas: asi el grid
--    muestra la tarifa recien anadida para poder ponerle precio y activarla.
--    La vista de ventas (vi_articulos_tarifas) NO se toca: el resolver de
--    precios sigue viendo solo las activas y vigentes.
--
--  Idempotente: CREATE OR REPLACE VIEW.
--  NO toca factuzam_original.sql.
-- ============================================================================
CREATE OR REPLACE VIEW vi_articulos_tarifas_mto AS
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
  LEFT JOIN (
    SELECT DISTINCT CODIGO_ART_SKU
    FROM fza_articulos_skus
    WHERE ESACTIVO_SKU = 'S'
  ) tiene_sku ON tiene_sku.CODIGO_ART_SKU = a.CODIGO_ART_ART
  LEFT JOIN (
    SELECT sk.CODIGO_ART_SKU,
           COUNT(DISTINCT va.ID_ATB_VA) AS NUM_ATRIBUTOS_REQ
    FROM fza_articulos_skus sk
    JOIN fza_variaciones_atributos va ON va.ID_VAR_VA = sk.CODIGO_VAR_SKU
    GROUP BY sk.CODIGO_ART_SKU
  ) num_atr ON num_atr.CODIGO_ART_SKU = a.CODIGO_ART_ART
-- Diferencia clave con vi_articulos_tarifas: NO se filtra por
-- at.ESACTIVO_ARTTAR ni por fechas, para que el mantenimiento muestre tambien
-- las tarifas inactivas / a precio 0 / expiradas y se puedan editar.
WHERE t.ESACTIVO_ARTTAR = 'S'
ORDER BY t.ORDEN_TAR, a.ORDEN_ART, at.CODIGO_UNIDAD_ARTTAR;
