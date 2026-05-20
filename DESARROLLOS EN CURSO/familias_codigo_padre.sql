-- =============================================================================
-- Anade columna CODIGO_PADRE_FAM a fza_articulos_familias
-- =============================================================================
-- El ERP legacy modela la jerarquia de familias en 2 niveles dentro de
-- la tabla ocniv:
--   - Nivel 2 = SECCION    (codigo de 2 chars: "01" SEÑORA, "14"
--                            UNIFORME INMACULADA CONCEP., ...)
--   - Nivel 4 = FAMILIA    (codigo de 4 chars: "1401" FALDA INMACULADA
--                            CONCEP., "1403" JERSEY..., "0101" BLUSA...)
--
-- Los 2 primeros chars del codigo Nivel=4 son SIEMPRE el codigo de la
-- seccion padre (Nivel=2). Para preservar esa jerarquia en destino
-- anadimos CODIGO_PADRE_FAM, que apunta a la familia padre dentro de
-- la propia tabla.
--
-- Convencion de nombre: CODIGO_PADRE_FAM (sin sufijo de tabla extra,
-- ver §3.3 de LIBRO_DE_ESTILO_BBDD.md — el sufijo de la tabla es FAM
-- y "PADRE" es el nucleo).
--
-- Idempotente: ALTER se ejecuta solo si la columna no existe.
-- =============================================================================

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_familias'
     AND COLUMN_NAME  = 'CODIGO_PADRE_FAM'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_articulos_familias
     ADD COLUMN CODIGO_PADRE_FAM varchar(20) NULL DEFAULT NULL
     AFTER CODIGO_FAM_FAM',
  'SELECT ''CODIGO_PADRE_FAM ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Indice para acelerar la navegacion padre → hijos
SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_articulos_familias'
     AND INDEX_NAME   = 'IDX_FAM_PADRE'
);

SET @sSqlIdx := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_articulos_familias
     ADD INDEX IDX_FAM_PADRE (CODIGO_PADRE_FAM)',
  'SELECT ''IDX_FAM_PADRE ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSqlIdx;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
