-- =============================================================================
-- vi_articulos: definicion UNIFICADA y definitiva
--   * Expone CODIGO_PRV_AP  (lo necesita el filtro por proveedor del Mto y las
--     guias de grid).                              [de vi_articulos_add_codigo_prv]
--   * Expone NOMBRE_PRV.                           [de vi_articulos_nombre_proveedor]
--   * TEMPORADA_ART a NIVEL ARTICULO unicamente (CODIGO_UNIDAD_ARTPROP = '').
--
-- POR QUE ESTE SCRIPT
-- -------------------
-- Habia dos scripts que hacian CREATE OR REPLACE de la misma vista y se
-- pisaban entre si:
--   - vi_articulos_add_codigo_prv.sql    -> con CODIGO_PRV_AP, SIN filtro de nivel
--   - vi_articulos_nombre_proveedor.sql  -> con filtro de nivel, SIN CODIGO_PRV_AP
-- Segun cual se aplicara el ultimo quedaba una vista incompleta. En las BBDD
-- donde gano "add_codigo_prv" (el caso del modelo actual) la vista NO filtra
-- el nivel de la propiedad TEMPORADA.
--
-- Tras la Fase 1 de "propiedades por unidad" (propiedades_por_unidad.sql) la
-- propiedad TEMPORADA pasa a NIVEL_PROP='COLOR': fza_articulos_propiedades tiene
-- ahora la PK ampliada con CODIGO_UNIDAD_ARTPROP y guarda una fila de TEMPORADA
-- POR COLOR. Si el LEFT JOIN no se restringe al nivel articulo
-- (CODIGO_UNIDAD_ARTPROP = ''), cada articulo se DUPLICA tantas veces como
-- colores con temporada tenga -> filas repetidas en el Mto de Articulos y en
-- cualquier consumidor de vi_articulos, y el COUNT de la precarga sale inflado.
--
-- Niveles de CODIGO_UNIDAD_ARTPROP:
--   ''                -> ARTICULO (padre)   <- el que muestra la lista
--   'ART/COLOR'       -> COLOR
--   'ART/COLOR/TALLA' -> SKU
-- El desglose por color/sku se consulta aparte en
-- vi_articulos_propiedades_efectivas (resolucion por especificidad).
--
-- Idempotente: CREATE OR REPLACE VIEW. NO se toca factuzam_original.sql.
-- Reaplicar este script DESPUES de propiedades_por_unidad.sql (Fase 1).
-- =============================================================================

CREATE OR REPLACE VIEW vi_articulos AS
SELECT
  art.CODIGO_ART_ART                            AS CODIGO_ART_ART,
  art.ESACTIVO_ART                              AS ESACTIVO_ART,
  art.ORDEN_ART                                 AS ORDEN_ART,
  art.DESCRIPCION_ART                           AS DESCRIPCION_ART,
  art.ESVARIACION_ART                           AS ESVARIACION_ART,
  art.ESTRAZABLE_ART                            AS ESTRAZABLE_ART,
  art.TIPO_ART                                  AS TIPO_ART,
  art.TIPO_VARIACION_ART                        AS TIPO_VARIACION_ART,
  art.CODIGO_FAM_ART                            AS CODIGO_FAM_ART,
  fam.DESCRIPCION_FAM                           AS DESCRIPCION_FAM,
  fam.NOMBRE_FAM_FAM                            AS NOMBRE_FAM_FAM,
  art.TIPO_IVA_ART                              AS TIPO_IVA_ART,
  iva.NOMBRE_TIPO_IVA_IVATIP                    AS NOMBRE_TIPO_IVA_IVATIP,
  art.ESACTIVO_FIJO_ART                         AS ESACTIVO_FIJO_ART,
  art.TIPO_CANTIDAD_ART                         AS TIPO_CANTIDAD_ART,
  ap.CODIGO_PRV_AP                              AS CODIGO_PRV_AP,
  prv.RAZON_SOCIAL_PRV                          AS RAZON_SOCIAL_PRV,
  prv.NOMBRE_PRV                                AS NOMBRE_PRV,
  ap.REF_PROVEEDOR_AP                           AS REF_PROVEEDOR,
  COALESCE(pv.PV, atemp.VALOR_LIBRE_ARTPROP)    AS TEMPORADA_ART,
  art.INSTANTE_MODIF                            AS INSTANTE_MODIF,
  art.INSTANTE_ALTA                             AS INSTANTE_ALTA,
  art.USUARIO_ALTA                              AS USUARIO_ALTA,
  art.USUARIO_MODIF                             AS USUARIO_MODIF
FROM fza_articulos art
  LEFT JOIN fza_articulos_familias fam
    ON art.CODIGO_FAM_ART = fam.CODIGO_FAM_FAM
  LEFT JOIN fza_articulos_proveedores ap
    ON art.CODIGO_ART_ART       = ap.CODIGO_ART_AP
   AND ap.ESPROVEEDORPRINCIPAL_AP = 'S'
  LEFT JOIN fza_proveedores prv
    ON ap.CODIGO_PRV_AP = prv.CODIGO_PRV_PRV
  LEFT JOIN fza_ivas_tipos iva
    ON art.TIPO_IVA_ART = iva.CODIGO_ABREVIATURA_IVA_IVATIP
  LEFT JOIN fza_articulos_propiedades atemp
    ON art.CODIGO_ART_ART          = atemp.CODIGO_ART_ART
   AND atemp.CODIGO_PROP_ARTPROP   = 'TEMPORADA'
   -- Clave del arreglo: solo el nivel ARTICULO. La PK ampliada
   -- (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP) garantiza
   -- como mucho UNA fila de TEMPORADA por articulo con este filtro, asi que
   -- no hay multiplicacion por color.
   AND atemp.CODIGO_UNIDAD_ARTPROP = ''
  LEFT JOIN fza_propiedades_valores pv
    ON atemp.ID_PV_ARTPROP = pv.ID_PV_ARTPROP
ORDER BY art.ORDEN_ART;
