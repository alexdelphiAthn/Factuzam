-- =============================================================================
-- Asigna el codigo padre de cada familia a partir del prefijo del codigo
-- =============================================================================
-- Regla de negocio:
--   El codigo de una familia "hoja" contiene como prefijo el codigo de su
--   familia padre. La convencion Herreras usa pares de chars (ver
--   inLibMigFamilias.pas §v1.2):
--     - "01"    SECCION (padre)
--     - "0101"  FAMILIA (hijo de "01")
--     - "0202"  FAMILIA (hijo de "02")
--     - "1401"  FAMILIA (hijo de "14")
--
--   Es decir, los primeros (LEN - 2) chars del codigo hijo coinciden con
--   el codigo del padre. Solo asignamos el padre si la familia candidata
--   realmente existe en la tabla.
--
-- Que rellena:
--   Ambas columnas de "padre" en fza_articulos_familias:
--     - CODIGO_SUBFAMILIA_FAM   columna legacy, la que lee la UI hoy
--                               (inMtoFamilias.dfm: grid y ficha)
--     - CODIGO_PADRE_FAM        columna nueva (DESARROLLOS EN CURSO/
--                               familias_codigo_padre.sql), la que
--                               rellena el migrador SQL Server -> MariaDB
--
--   Mantenerlas sincronizadas evita que la UI muestre vacio el "Codigo
--   Subfamilia" cuando solo se ha rellenado la columna nueva.
--
-- Idempotente:
--   - El WHERE solo actualiza si alguna de las dos columnas no coincide
--     con el padre calculado.
--   - Re-ejecutarlo no produce cambios si el estado ya es coherente.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): descomenta para ver que familias se actualizarian
-- y a que padre apuntarian, antes del UPDATE real.
-- -----------------------------------------------------------------------------
-- SELECT f.CODIGO_FAM_FAM                                  AS HIJO,
--        f.NOMBRE_FAM_FAM                                  AS NOMBRE_HIJO,
--        f.CODIGO_SUBFAMILIA_FAM                           AS SUBFAM_ACTUAL,
--        f.CODIGO_PADRE_FAM                                AS PADRE_ACTUAL,
--        p.CODIGO_FAM_FAM                                  AS PADRE_NUEVO,
--        p.NOMBRE_FAM_FAM                                  AS NOMBRE_PADRE
--   FROM fza_articulos_familias f
--   JOIN fza_articulos_familias p
--     ON p.CODIGO_FAM_FAM = SUBSTRING(f.CODIGO_FAM_FAM, 1,
--                                     CHAR_LENGTH(f.CODIGO_FAM_FAM) - 2)
--  WHERE CHAR_LENGTH(f.CODIGO_FAM_FAM) > 2
--    AND (COALESCE(f.CODIGO_SUBFAMILIA_FAM, '') <> p.CODIGO_FAM_FAM
--      OR COALESCE(f.CODIGO_PADRE_FAM, '')      <> p.CODIGO_FAM_FAM)
--  ORDER BY f.CODIGO_FAM_FAM;

-- -----------------------------------------------------------------------------
-- UPDATE: asigna el codigo padre deducido del prefijo en ambas columnas
-- -----------------------------------------------------------------------------
-- Usamos JOIN contra la propia tabla para validar que el padre candidato
-- existe — si "0101" tuviera prefijo "01" pero no hubiera fila "01" en la
-- tabla, no inventamos un padre inexistente y dejamos las columnas como
-- estan.
UPDATE fza_articulos_familias f
  JOIN fza_articulos_familias p
    ON p.CODIGO_FAM_FAM = SUBSTRING(f.CODIGO_FAM_FAM, 1,
                                    CHAR_LENGTH(f.CODIGO_FAM_FAM) - 2)
   SET f.CODIGO_SUBFAMILIA_FAM = p.CODIGO_FAM_FAM,
       f.CODIGO_PADRE_FAM      = p.CODIGO_FAM_FAM,
       f.INSTANTE_MODIF        = CURRENT_TIMESTAMP,
       f.USUARIO_MODIF         = 'SCRIPT_ASIGNAR_PADRE_FAM'
 WHERE CHAR_LENGTH(f.CODIGO_FAM_FAM) > 2
   AND (COALESCE(f.CODIGO_SUBFAMILIA_FAM, '') <> p.CODIGO_FAM_FAM
     OR COALESCE(f.CODIGO_PADRE_FAM, '')      <> p.CODIGO_FAM_FAM);

-- -----------------------------------------------------------------------------
-- ROLLBACK: si necesitas deshacerlo, vuelve a poner en NULL las filas
-- marcadas por este script:
--   UPDATE fza_articulos_familias
--      SET CODIGO_SUBFAMILIA_FAM = NULL,
--          CODIGO_PADRE_FAM      = NULL
--    WHERE USUARIO_MODIF = 'SCRIPT_ASIGNAR_PADRE_FAM';
-- -----------------------------------------------------------------------------
