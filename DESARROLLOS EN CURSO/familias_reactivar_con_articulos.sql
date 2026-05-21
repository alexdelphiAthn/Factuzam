-- =============================================================================
-- Reactivar familias que tienen artículos asignados
-- =============================================================================
-- Problema: el combo "Familia" del mantenimiento de artículos aparece vacío
-- en muchos artículos, aunque el label inferior (DESCRIPCION_FAM) muestre el
-- nombre correcto de la familia.
--
-- Causa raíz: la vista vi_articulos_familias_list (alimenta el dropdown)
-- filtra por ESACTIVO_FAM = 'S'. El migrador SQL Server -> MariaDB
-- (inLibMigFamilias.pas) marca como ESACTIVO_FAM = 'N' cualquier familia
-- cuyo Estado en el legacy sea 'B' (baja). Resultado: artículos cuya
-- familia quedó "de baja" en el legacy referencian una familia que no
-- aparece en el combo (pero sí en el LEFT JOIN de vi_articulos, por eso
-- el label sí muestra DESCRIPCION_FAM).
--
-- Regla de negocio: si una familia tiene al menos un artículo apuntando
-- a ella, debe estar activa. El estado 'B' del legacy ya no es relevante
-- en cuanto el dato vivo (los artículos) la sigue usando.
--
-- Idempotente: el WHERE excluye las que ya están en 'S', así que
-- re-ejecutar no toca filas.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): cuántas familias se reactivarían y cuántos artículos
-- las usan. Descomenta para ver el impacto antes del UPDATE.
-- -----------------------------------------------------------------------------
-- SELECT f.CODIGO_FAM_FAM, f.NOMBRE_FAM_FAM, f.ESACTIVO_FAM,
--        COUNT(a.CODIGO_ART_ART) AS NUM_ARTICULOS
--   FROM fza_articulos_familias f
--   JOIN fza_articulos          a ON a.CODIGO_FAM_ART = f.CODIGO_FAM_FAM
--  WHERE f.ESACTIVO_FAM = 'N'
--  GROUP BY f.CODIGO_FAM_FAM, f.NOMBRE_FAM_FAM, f.ESACTIVO_FAM
--  ORDER BY NUM_ARTICULOS DESC;

-- -----------------------------------------------------------------------------
-- UPDATE: reactivar familias inactivas que tienen al menos un artículo
-- -----------------------------------------------------------------------------
-- No filtramos por ESACTIVO_ART: si un artículo (activo o no) sigue
-- apuntando a una familia, la familia debe ser visible en el combo
-- para poder reasignarla o consultarla. Marcamos USUARIO_MODIF con
-- una etiqueta reconocible para poder revertir si hiciera falta.
UPDATE fza_articulos_familias f
   SET f.ESACTIVO_FAM   = 'S',
       f.INSTANTE_MODIF = CURRENT_TIMESTAMP,
       f.USUARIO_MODIF  = 'SCRIPT_REACTIVAR_FAM'
 WHERE f.ESACTIVO_FAM = 'N'
   AND EXISTS (
         SELECT 1
           FROM fza_articulos a
          WHERE a.CODIGO_FAM_ART = f.CODIGO_FAM_FAM
   );

-- -----------------------------------------------------------------------------
-- ROLLBACK: si necesitas deshacer este script, vuelve a poner en 'N' las
-- filas marcadas:
--   UPDATE fza_articulos_familias
--      SET ESACTIVO_FAM = 'N'
--    WHERE USUARIO_MODIF = 'SCRIPT_REACTIVAR_FAM';
-- -----------------------------------------------------------------------------
