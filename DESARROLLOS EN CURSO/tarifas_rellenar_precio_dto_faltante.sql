-- =============================================================================
-- Rellenar PRECIO_DTO_ARTTAR faltante en tarifas con descuento real
-- =============================================================================
-- Problema: la pestaña "Tarifas" del mantenimiento de artículos muestra
-- filas con "% Descuento" y "Precio Final" < "Precio Salida" pero con la
-- columna "Euros descuento" vacía. El descuento existe (final < salida)
-- pero PRECIO_DTO_ARTTAR está a NULL.
--
-- Causa raíz: bug en el modal "Añadir precio"
-- (inMtoModalAddBlockTarifa.pas). Su INSERT a fza_articulos_tarifas
-- grababa PRECIO_SALIDA, PRECIO_FINAL y PORCENTAJE_DTO pero omitía
-- PRECIO_DTO_ARTTAR, que quedaba a NULL. El grid no recalcula al
-- mostrar (solo al editar a mano), así que la celda sale vacía.
--
-- El fix del modal va aparte (commit del mismo branch). Este script
-- sanea los datos ya insertados rellenando los euros de descuento a
-- partir de salida y final.
--
-- Criterio "descuento real sin euros informados":
--   (PRECIO_DTO_ARTTAR IS NULL ó = 0)
--   AND PRECIO_SALIDA_ARTTAR IS NOT NULL
--   AND PRECIO_FINAL_ARTTAR IS NOT NULL
--   AND PRECIO_FINAL_ARTTAR < PRECIO_SALIDA_ARTTAR
--
-- Idempotente: las filas saneadas pasan a tener PRECIO_DTO_ARTTAR > 0,
-- por lo que la condición (IS NULL ó = 0) las excluye en pasadas
-- siguientes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): qué filas se sanean y con qué euros quedarían.
-- Descomenta para inspeccionar antes del UPDATE.
-- -----------------------------------------------------------------------------
-- SELECT CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR,
--        PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR,
--        PRECIO_DTO_ARTTAR,    PORCENTAJE_DTO_ARTTAR,
--        PRECIO_SALIDA_ARTTAR - PRECIO_FINAL_ARTTAR AS DTO_CALCULADO
--   FROM fza_articulos_tarifas
--  WHERE (PRECIO_DTO_ARTTAR IS NULL OR PRECIO_DTO_ARTTAR = 0)
--    AND PRECIO_SALIDA_ARTTAR IS NOT NULL
--    AND PRECIO_FINAL_ARTTAR IS NOT NULL
--    AND PRECIO_FINAL_ARTTAR < PRECIO_SALIDA_ARTTAR
--  ORDER BY CODIGO_ART_ARTTAR;

-- -----------------------------------------------------------------------------
-- UPDATE: rellena los euros de descuento donde falta y hay descuento real
-- -----------------------------------------------------------------------------
-- Marcamos USUARIO_MODIF con una etiqueta reconocible para poder
-- auditarlo (las filas tocadas se identifican por esa etiqueta).
UPDATE fza_articulos_tarifas
   SET PRECIO_DTO_ARTTAR = PRECIO_SALIDA_ARTTAR - PRECIO_FINAL_ARTTAR,
       INSTANTE_MODIF    = CURRENT_TIMESTAMP,
       USUARIO_MODIF     = 'SCRIPT_RELLENAR_PRECIO_DTO'
 WHERE (PRECIO_DTO_ARTTAR IS NULL OR PRECIO_DTO_ARTTAR = 0)
   AND PRECIO_SALIDA_ARTTAR IS NOT NULL
   AND PRECIO_FINAL_ARTTAR IS NOT NULL
   AND PRECIO_FINAL_ARTTAR < PRECIO_SALIDA_ARTTAR;

-- -----------------------------------------------------------------------------
-- Nota: no tocamos filas sin descuento real (final = salida o precios a
-- NULL): en esas lo correcto es que los euros queden a NULL/0. El caso
-- inverso (porcentaje basura sin descuento real) lo sanea el script
-- tarifas_limpiar_porcentaje_dto_basura.sql.
-- -----------------------------------------------------------------------------
