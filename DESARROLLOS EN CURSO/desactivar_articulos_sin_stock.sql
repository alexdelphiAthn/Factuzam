-- =============================================================================
-- Desactivar artículos sin stock + filtrar vi_articulos por activos
-- =============================================================================
-- Petición: en la pestaña de Artículos sólo deben salir los que tienen stock.
-- En lugar de filtrar la vista por stock (que recalcularía en cada SELECT),
-- marcamos los artículos sin stock como ESACTIVO_ART='N' y dejamos
-- vi_articulos restringida a los activos. Así el cxGrid de la pestaña
-- Artículos seguirá usando vi_articulos sin tocar nada en Delphi.
--
-- Pasos:
--   1) UPDATE fza_articulos SET ESACTIVO_ART='N' WHERE no_tiene_stock
--   2) CREATE OR REPLACE VIEW vi_articulos ... WHERE ESACTIVO_ART='S'
--
-- Sólo afecta a TIPO_ART = 'ESTANDAR' (artículos físicos). Los SERVICIO
-- y los KIT no se desactivan: por naturaleza no tienen stock propio y
-- deben seguir disponibles para venta/uso.
--
-- "Tiene stock" =  existe alguna fila en fza_articulos_stockactual con
-- CANTIDAD_STK > 0 cuyo CODIGO_UNIDAD_STK case con el artículo, ya sea
-- directamente (artículo simple) o a través de un SKU
-- (fza_articulos_skus.CODIGO_ART_SKU = artículo).
--
-- Idempotente: re-ejecutar no vuelve a marcar nada que ya esté
-- inactivo, y el CREATE OR REPLACE es naturalmente idempotente.
--
-- ROLLBACK del UPDATE: las filas afectadas quedan marcadas con
-- USUARIO_MODIF = 'SCRIPT_FILTRO_STOCK'. Para reactivarlas:
--   UPDATE fza_articulos
--      SET ESACTIVO_ART = 'S'
--    WHERE ESACTIVO_ART = 'N'
--      AND USUARIO_MODIF = 'SCRIPT_FILTRO_STOCK';
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): ejecuta este SELECT antes del UPDATE para ver cuántos
-- y cuáles artículos se desactivarían. Comenta las filas si no lo necesitas.
-- -----------------------------------------------------------------------------
-- SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.TIPO_ART
--   FROM fza_articulos a
--  WHERE a.ESACTIVO_ART = 'S'
--    AND a.TIPO_ART = 'ESTANDAR'
--    AND NOT EXISTS (
--          SELECT 1
--            FROM fza_articulos_stockactual stk
--           WHERE stk.CODIGO_UNIDAD_STK = a.CODIGO_ART_ART
--             AND stk.CANTIDAD_STK > 0
--    )
--    AND NOT EXISTS (
--          SELECT 1
--            FROM fza_articulos_skus sk
--            JOIN fza_articulos_stockactual stk
--              ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
--           WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART
--             AND stk.CANTIDAD_STK > 0
--    );

-- -----------------------------------------------------------------------------
-- Paso 1: Desactivar artículos ESTANDAR sin stock
-- -----------------------------------------------------------------------------
UPDATE fza_articulos a
   SET a.ESACTIVO_ART  = 'N',
       a.INSTANTE_MODIF = CURRENT_TIMESTAMP,
       a.USUARIO_MODIF  = 'SCRIPT_FILTRO_STOCK'
 WHERE a.ESACTIVO_ART = 'S'
   AND a.TIPO_ART = 'ESTANDAR'
   AND NOT EXISTS (
         SELECT 1
           FROM fza_articulos_stockactual stk
          WHERE stk.CODIGO_UNIDAD_STK = a.CODIGO_ART_ART
            AND stk.CANTIDAD_STK > 0
   )
   AND NOT EXISTS (
         SELECT 1
           FROM fza_articulos_skus sk
           JOIN fza_articulos_stockactual stk
             ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
          WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART
            AND stk.CANTIDAD_STK > 0
   );

-- -----------------------------------------------------------------------------
-- Paso 2: vi_articulos sólo devuelve activos
-- -----------------------------------------------------------------------------
-- Mismas columnas y JOINs que la versión original (factuzam_original.sql
-- linea 15117). Único cambio: WHERE art.ESACTIVO_ART = 'S'.
CREATE OR REPLACE VIEW vi_articulos AS
  SELECT  art.CODIGO_ART_ART          AS CODIGO_ART_ART,
          art.ESACTIVO_ART            AS ESACTIVO_ART,
          art.ORDEN_ART               AS ORDEN_ART,
          art.DESCRIPCION_ART         AS DESCRIPCION_ART,
          art.ESVARIACION_ART         AS ESVARIACION_ART,
          art.ESTRAZABLE_ART          AS ESTRAZABLE_ART,
          art.TIPO_ART                AS TIPO_ART,
          art.TIPO_VARIACION_ART      AS TIPO_VARIACION_ART,
          art.CODIGO_FAM_ART          AS CODIGO_FAM_ART,
          fam.DESCRIPCION_FAM         AS DESCRIPCION_FAM,
          fam.NOMBRE_FAM_FAM          AS NOMBRE_FAM_FAM,
          art.TIPO_IVA_ART            AS TIPO_IVA_ART,
          iva.NOMBRE_TIPO_IVA_IVATIP  AS NOMBRE_TIPO_IVA_IVATIP,
          art.ESACTIVO_FIJO_ART       AS ESACTIVO_FIJO_ART,
          art.TIPO_CANTIDAD_ART       AS TIPO_CANTIDAD_ART,
          prv.RAZON_SOCIAL_PRV        AS RAZON_SOCIAL_PRV,
          ap.REF_PROVEEDOR_AP         AS REF_PROVEEDOR,
          COALESCE(pv.PV, atemp.VALOR_LIBRE_ARTPROP) AS TEMPORADA_ART,
          art.INSTANTE_MODIF          AS INSTANTE_MODIF,
          art.INSTANTE_ALTA           AS INSTANTE_ALTA,
          art.USUARIO_ALTA            AS USUARIO_ALTA,
          art.USUARIO_MODIF           AS USUARIO_MODIF
    FROM  fza_articulos             art
    LEFT  JOIN fza_articulos_familias    fam
            ON art.CODIGO_FAM_ART = fam.CODIGO_FAM_FAM
    LEFT  JOIN fza_articulos_proveedores ap
            ON art.CODIGO_ART_ART = ap.CODIGO_ART_AP
           AND ap.ESPROVEEDORPRINCIPAL_AP = 'S'
    LEFT  JOIN fza_proveedores           prv
            ON ap.CODIGO_PRV_AP = prv.CODIGO_PRV_PRV
    LEFT  JOIN fza_ivas_tipos            iva
            ON art.TIPO_IVA_ART = iva.CODIGO_ABREVIATURA_IVA_IVATIP
    LEFT  JOIN fza_articulos_propiedades atemp
            ON art.CODIGO_ART_ART = atemp.CODIGO_ART_ART
           AND atemp.CODIGO_PROP_ARTPROP = 'TEMPORADA'
    LEFT  JOIN fza_propiedades_valores   pv
            ON atemp.ID_PV_ARTPROP = pv.ID_PV_ARTPROP
   WHERE  art.ESACTIVO_ART = 'S'
   ORDER  BY art.ORDEN_ART;
