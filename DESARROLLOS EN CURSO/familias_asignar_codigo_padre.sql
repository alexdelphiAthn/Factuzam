-- =============================================================================
-- Asigna el codigo padre de cada familia a partir del prefijo del codigo
-- =============================================================================
-- Sintoma:
--   Tras la migracion de legacy, en el mantenimiento de Familias la columna
--   "Codigo Subfamilia" (que es el PADRE de la familia) aparece vacia. El
--   migrador rellenaba CODIGO_PADRE_FAM pero NO CODIGO_SUBFAMILIA_FAM, y la
--   UI (grid y ficha "Familia Padre" de inMtoFamilias) lee la segunda.
--
-- Regla de negocio (cliente-agnostica):
--   El padre de una familia es el codigo EXISTENTE mas largo que es prefijo
--   estricto del suyo. No depende de una longitud fija de nivel, asi que
--   vale para cualquier convencion. Ejemplo de jerarquia de 3 niveles con
--   codigos 1/3/5:
--     - "1"      ABUELO (raiz, sin padre)
--     - "101"    PADRE  (hijo de "1")
--     - "10101"  HIJO   (hijo de "101")
--   y tambien para la convencion Herreras 2/4 ("01" seccion -> "0101" familia)
--   o cualquier otra (3/7, etc.).
--
-- Que rellena:
--   Ambas columnas de "padre" en fza_articulos_familias, sincronizadas:
--     - CODIGO_SUBFAMILIA_FAM   columna legacy, la que LEE la UI hoy
--                               (inMtoFamilias.dfm: grid y ficha)
--     - CODIGO_PADRE_FAM        columna nueva (DESARROLLOS EN CURSO/
--                               familias_codigo_padre.sql), la que rellena
--                               el migrador SQL Server -> MariaDB
--   Mantenerlas sincronizadas evita que la UI muestre vacio el "Codigo
--   Subfamilia" cuando solo se ha rellenado la columna nueva.
--
-- Idempotente:
--   - Solo actualiza filas cuyo padre calculado difiere del almacenado.
--   - Las raices (sin prefijo existente) se dejan como estan (no se tocan).
--   - Re-ejecutarlo no produce cambios si el estado ya es coherente.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): descomenta para ver que familias se actualizarian y a
-- que padre apuntarian, antes del UPDATE real.
-- -----------------------------------------------------------------------------
-- SELECT f.CODIGO_FAM_FAM                          AS HIJO,
--        f.NOMBRE_FAM_FAM                          AS NOMBRE_HIJO,
--        f.CODIGO_SUBFAMILIA_FAM                   AS SUBFAM_ACTUAL,
--        f.CODIGO_PADRE_FAM                        AS PADRE_ACTUAL,
--        d.PADRE                                   AS PADRE_NUEVO
--   FROM fza_articulos_familias f
--   JOIN (
--     SELECT h.CODIGO_FAM_FAM AS HIJO,
--            (SELECT p.CODIGO_FAM_FAM
--               FROM fza_articulos_familias p
--              WHERE p.CODIGO_FAM_FAM <> h.CODIGO_FAM_FAM
--                AND CHAR_LENGTH(p.CODIGO_FAM_FAM)
--                    < CHAR_LENGTH(h.CODIGO_FAM_FAM)
--                AND LEFT(h.CODIGO_FAM_FAM,
--                         CHAR_LENGTH(p.CODIGO_FAM_FAM)) = p.CODIGO_FAM_FAM
--              ORDER BY CHAR_LENGTH(p.CODIGO_FAM_FAM) DESC
--              LIMIT 1) AS PADRE
--       FROM fza_articulos_familias h
--   ) d ON d.HIJO = f.CODIGO_FAM_FAM
--  WHERE d.PADRE IS NOT NULL
--    AND (COALESCE(f.CODIGO_SUBFAMILIA_FAM, '') <> d.PADRE
--      OR COALESCE(f.CODIGO_PADRE_FAM, '')      <> d.PADRE)
--  ORDER BY CHAR_LENGTH(f.CODIGO_FAM_FAM), f.CODIGO_FAM_FAM;

-- -----------------------------------------------------------------------------
-- UPDATE: asigna en ambas columnas el padre = prefijo existente mas largo.
-- -----------------------------------------------------------------------------
-- La subconsulta correlacionada del derived table calcula, por cada familia,
-- su padre real (prefijo existente mas largo). Al ser un derived table con
-- subconsulta en el SELECT, MariaDB lo materializa, asi que se puede leer la
-- misma tabla que estamos actualizando sin el error "target table ... in FROM".
UPDATE fza_articulos_familias f
  JOIN (
    SELECT h.CODIGO_FAM_FAM AS HIJO,
           (SELECT p.CODIGO_FAM_FAM
              FROM fza_articulos_familias p
             WHERE p.CODIGO_FAM_FAM <> h.CODIGO_FAM_FAM
               AND CHAR_LENGTH(p.CODIGO_FAM_FAM)
                   < CHAR_LENGTH(h.CODIGO_FAM_FAM)
               AND LEFT(h.CODIGO_FAM_FAM,
                        CHAR_LENGTH(p.CODIGO_FAM_FAM)) = p.CODIGO_FAM_FAM
             ORDER BY CHAR_LENGTH(p.CODIGO_FAM_FAM) DESC
             LIMIT 1) AS PADRE
      FROM fza_articulos_familias h
  ) d ON d.HIJO = f.CODIGO_FAM_FAM
   SET f.CODIGO_SUBFAMILIA_FAM = d.PADRE,
       f.CODIGO_PADRE_FAM      = d.PADRE,
       f.INSTANTE_MODIF        = CURRENT_TIMESTAMP,
       f.USUARIO_MODIF         = 'SCRIPT_ASIGNAR_PADRE_FAM'
 WHERE d.PADRE IS NOT NULL
   AND (COALESCE(f.CODIGO_SUBFAMILIA_FAM, '') <> d.PADRE
     OR COALESCE(f.CODIGO_PADRE_FAM, '')      <> d.PADRE);

-- -----------------------------------------------------------------------------
-- ROLLBACK: si necesitas deshacerlo, vuelve a poner en NULL las filas
-- marcadas por este script:
--   UPDATE fza_articulos_familias
--      SET CODIGO_SUBFAMILIA_FAM = NULL,
--          CODIGO_PADRE_FAM      = NULL
--    WHERE USUARIO_MODIF = 'SCRIPT_ASIGNAR_PADRE_FAM';
-- -----------------------------------------------------------------------------
