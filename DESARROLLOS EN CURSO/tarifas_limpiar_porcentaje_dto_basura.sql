-- =============================================================================
-- Limpiar PORCENTAJE_DTO_ARTTAR basura en tarifas sin descuento real
-- =============================================================================
-- Problema: la pestaña "Tarifas" del mantenimiento de artículos muestra
-- "% Descuento = 100 %" en muchas filas aunque la columna "Euros descuento"
-- esté vacía y "Precio Final" = "Precio Salida". Es decir, la tarifa NO
-- tiene descuento real pero el porcentaje almacenado dice lo contrario.
--
-- Causa raíz: bug en el migrador SQL Server -> MariaDB
-- (inLibMigArticulosTarifas.pas, líneas 348-357). Cuando el legacy no
-- tiene rebaja real (PrecioRebaja = 0 ó >= PrecioSalida), el migrador
-- resetea fFinal y fDto a sus valores correctos pero NO toca fPorDto.
-- Si la fila origen traía un PorDtoRebaja basura (típicamente 100), se
-- inserta tal cual en fza_articulos_tarifas.PORCENTAJE_DTO_ARTTAR.
--
-- El fix del migrador va aparte (commit del mismo branch). Este script
-- limpia los datos ya migrados poniendo a NULL cualquier porcentaje
-- almacenado en filas que no tienen descuento real en euros.
--
-- Criterio "sin descuento real":
--   PRECIO_DTO_ARTTAR IS NULL ó = 0
--   AND (PRECIO_FINAL_ARTTAR IS NULL
--        OR PRECIO_SALIDA_ARTTAR IS NULL
--        OR PRECIO_FINAL_ARTTAR = PRECIO_SALIDA_ARTTAR)
--   AND PORCENTAJE_DTO_ARTTAR > 0
--
-- Idempotente: las filas saneadas pasan a tener PORCENTAJE_DTO_ARTTAR
-- IS NULL, por lo que la condición PORCENTAJE_DTO_ARTTAR > 0 las
-- excluye en pasadas siguientes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): qué filas se sanean y con qué porcentaje fantasma
-- venían. Descomenta para inspeccionar antes del UPDATE.
-- -----------------------------------------------------------------------------
-- SELECT CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR,
--        PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR,
--        PRECIO_DTO_ARTTAR,    PORCENTAJE_DTO_ARTTAR
--   FROM fza_articulos_tarifas
--  WHERE (PRECIO_DTO_ARTTAR IS NULL OR PRECIO_DTO_ARTTAR = 0)
--    AND (PRECIO_FINAL_ARTTAR IS NULL
--         OR PRECIO_SALIDA_ARTTAR IS NULL
--         OR PRECIO_FINAL_ARTTAR = PRECIO_SALIDA_ARTTAR)
--    AND PORCENTAJE_DTO_ARTTAR > 0
--  ORDER BY CODIGO_ART_ARTTAR;

-- -----------------------------------------------------------------------------
-- UPDATE: pone a NULL el porcentaje fantasma cuando no hay descuento real
-- -----------------------------------------------------------------------------
-- Marcamos USUARIO_MODIF con una etiqueta reconocible para poder
-- auditarlo (y revertir si fuera necesario, aunque al ser NULL -> NULL
-- el rollback solo tiene sentido si guardas el valor previo aparte).
UPDATE fza_articulos_tarifas
   SET PORCENTAJE_DTO_ARTTAR = NULL,
       INSTANTE_MODIF        = CURRENT_TIMESTAMP,
       USUARIO_MODIF         = 'SCRIPT_LIMPIAR_PORCEN_DTO'
 WHERE (PRECIO_DTO_ARTTAR IS NULL OR PRECIO_DTO_ARTTAR = 0)
   AND (PRECIO_FINAL_ARTTAR IS NULL
        OR PRECIO_SALIDA_ARTTAR IS NULL
        OR PRECIO_FINAL_ARTTAR = PRECIO_SALIDA_ARTTAR)
   AND PORCENTAJE_DTO_ARTTAR > 0;

-- -----------------------------------------------------------------------------
-- Nota: no tocamos filas con descuento real (PRECIO_DTO_ARTTAR > 0 o
-- PRECIO_FINAL_ARTTAR < PRECIO_SALIDA_ARTTAR). Si en esas el porcentaje
-- está desincronizado con el resto, se trata aparte (no es el caso que
-- el migrador produce).
-- -----------------------------------------------------------------------------
