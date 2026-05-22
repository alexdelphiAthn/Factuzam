-- =============================================================================
-- Ajusta CONTADOR_ART_FAM al ultimo numero realmente usado por los articulos
-- =============================================================================
-- CONTADOR_ART_FAM guarda el ULTIMO numero emitido por la familia para
-- autogenerar el codigo del articulo. El proximo articulo creado usara
-- CONTADOR_ART_FAM + 1 rellenado a PAD_ART_FAM digitos (ver
-- inLibComprasSesiones.pas:1115 — `iCont := CONTADOR + 1`).
--
-- Patron del codigo de articulo autogenerado:
--   CODIGO_ART_ART = CODIGO_FAM_FAM || LPAD(n, PAD_ART_FAM, '0')
--
--   Ej (familia "0101", pad 5, contador 15):
--     proximo articulo -> "0101" + "00016" = "010100016"
--
-- Que hace este script:
--   Para cada familia, busca todos los articulos cuyo codigo:
--     - empiezan por el codigo de la familia, y
--     - el sufijo restante es enteramente numerico (REGEXP '^[0-9]+$').
--   El MAX de ese sufijo es "el ultimo numero usado realmente". Si es
--   mayor que el CONTADOR_ART_FAM actual (o este es NULL), lo sube.
--
--   No se filtra por ESCONTADOR_ART_FAM: si una familia tiene articulos
--   que siguen el patron, dejamos el contador al dia aunque la familia
--   no este marcada como autogeneradora — el dia que se active el flag
--   ya esta listo para emitir el siguiente sin colisionar.
--
-- Idempotente:
--   - El WHERE no actualiza si el contador ya es >= MAX.
--   - Re-ejecutar no hace cambios y nunca baja un contador.
--
-- Familias afectadas tipicas (Herreras):
--   "0101", "0202", "1401"... con articulos "010100015", "020200003"...
--   tras ejecutar este script, CONTADOR_ART_FAM = 15, 3, etc.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREVIEW (opcional): muestra el cambio que se aplicaria por familia.
-- -----------------------------------------------------------------------------
-- SELECT f.CODIGO_FAM_FAM,
--        f.NOMBRE_FAM_FAM,
--        f.CONTADOR_ART_FAM       AS CONTADOR_ACTUAL,
--        m.MAX_NUM                AS CONTADOR_NUEVO,
--        m.NUM_ARTICULOS          AS ARTICULOS_PATRON
--   FROM fza_articulos_familias f
--   JOIN (
--       SELECT a.CODIGO_FAM_ART AS CODIGO_FAM,
--              COUNT(*)         AS NUM_ARTICULOS,
--              MAX(CAST(SUBSTRING(a.CODIGO_ART_ART,
--                                 CHAR_LENGTH(a.CODIGO_FAM_ART) + 1)
--                       AS UNSIGNED))         AS MAX_NUM
--         FROM fza_articulos a
--        WHERE a.CODIGO_FAM_ART IS NOT NULL
--          AND a.CODIGO_FAM_ART <> ''
--          AND CHAR_LENGTH(a.CODIGO_ART_ART) >
--              CHAR_LENGTH(a.CODIGO_FAM_ART)
--          AND SUBSTRING(a.CODIGO_ART_ART, 1,
--                        CHAR_LENGTH(a.CODIGO_FAM_ART)) = a.CODIGO_FAM_ART
--          AND SUBSTRING(a.CODIGO_ART_ART,
--                        CHAR_LENGTH(a.CODIGO_FAM_ART) + 1) REGEXP '^[0-9]+$'
--        GROUP BY a.CODIGO_FAM_ART
--   ) m ON m.CODIGO_FAM = f.CODIGO_FAM_FAM
--  WHERE f.CONTADOR_ART_FAM IS NULL
--     OR f.CONTADOR_ART_FAM < m.MAX_NUM
--  ORDER BY f.CODIGO_FAM_FAM;

-- -----------------------------------------------------------------------------
-- UPDATE: sube CONTADOR_ART_FAM al MAX de los sufijos numericos reales
-- -----------------------------------------------------------------------------
UPDATE fza_articulos_familias f
  JOIN (
      SELECT a.CODIGO_FAM_ART AS CODIGO_FAM,
             MAX(CAST(SUBSTRING(a.CODIGO_ART_ART,
                                CHAR_LENGTH(a.CODIGO_FAM_ART) + 1)
                      AS UNSIGNED))         AS MAX_NUM
        FROM fza_articulos a
       WHERE a.CODIGO_FAM_ART IS NOT NULL
         AND a.CODIGO_FAM_ART <> ''
         AND CHAR_LENGTH(a.CODIGO_ART_ART) >
             CHAR_LENGTH(a.CODIGO_FAM_ART)
         AND SUBSTRING(a.CODIGO_ART_ART, 1,
                       CHAR_LENGTH(a.CODIGO_FAM_ART)) = a.CODIGO_FAM_ART
         AND SUBSTRING(a.CODIGO_ART_ART,
                       CHAR_LENGTH(a.CODIGO_FAM_ART) + 1) REGEXP '^[0-9]+$'
       GROUP BY a.CODIGO_FAM_ART
  ) m ON m.CODIGO_FAM = f.CODIGO_FAM_FAM
   SET f.CONTADOR_ART_FAM = m.MAX_NUM,
       f.INSTANTE_MODIF   = CURRENT_TIMESTAMP,
       f.USUARIO_MODIF    = 'SCRIPT_AJUSTAR_CONTADOR_FAM'
 WHERE f.CONTADOR_ART_FAM IS NULL
    OR f.CONTADOR_ART_FAM < m.MAX_NUM;

-- -----------------------------------------------------------------------------
-- ROLLBACK: no hay rollback util — este script SOLO sube contadores nunca
-- los baja. Si necesitas dejar un contador a un valor concreto, hazlo a
-- mano. Las filas tocadas quedan marcadas con USUARIO_MODIF para auditar:
--   SELECT CODIGO_FAM_FAM, CONTADOR_ART_FAM, INSTANTE_MODIF
--     FROM fza_articulos_familias
--    WHERE USUARIO_MODIF = 'SCRIPT_AJUSTAR_CONTADOR_FAM';
-- -----------------------------------------------------------------------------
