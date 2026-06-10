-- =============================================================================
-- vi_articulos: anadir NOMBRE_PRV (nombre comercial del proveedor principal)
-- =============================================================================
-- Tras anadir NOMBRE_PRV a fza_proveedores (ver proveedores_nombre.sql), la
-- vista vi_articulos solo exponia RAZON_SOCIAL_PRV. Para que la lista del
-- Mto de Articulos pueda mostrar tambien el nombre comercial del proveedor
-- principal junto al codigo y la razon social, anadimos NOMBRE_PRV a la
-- proyeccion (mismo LEFT JOIN, no se altera el plan de ejecucion).
--
-- Solo se modifica la proyeccion: se mantienen JOINs, ESPROVEEDORPRINCIPAL_AP
-- = 'S' y el ORDER BY originales.
--
-- Fase 4 (propiedades por unidad): el JOIN a fza_articulos_propiedades para
-- TEMPORADA_ART filtra ahora CODIGO_UNIDAD_ARTPROP = '' (nivel articulo). Sin
-- ese filtro, las temporadas por color/SKU de la PK ampliada duplicarian cada
-- fila de articulo en el Mto de Articulos y demas consumidores de vi_articulos.
-- Reaplica este script tras desplegar la Fase 1.
--
-- Idempotente: CREATE OR REPLACE VIEW.
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
   -- Solo el nivel ARTICULO: sin este filtro, las temporadas por color
   -- (CODIGO_UNIDAD_ARTPROP <> '') multiplican las filas del articulo.
   AND atemp.CODIGO_UNIDAD_ARTPROP = ''
  LEFT JOIN fza_propiedades_valores pv
    ON atemp.ID_PV_ARTPROP = pv.ID_PV_ARTPROP
ORDER BY art.ORDEN_ART;
