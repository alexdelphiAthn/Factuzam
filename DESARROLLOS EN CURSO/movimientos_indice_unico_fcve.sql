-- ============================================================================
-- movimientos_indice_unico_fcve.sql          (idempotente, re-ejecutable)
-- ----------------------------------------------------------------------------
-- Unicidad real de los movimientos de stock de FACTURA (FC/VE).
--
-- Problema: GenerarMovimientosSalidaFactura evita duplicados con un
-- SELECT ... LIMIT 1 sin bloqueo; dos puestos grabando la misma factura a
-- la vez pueden insertar el movimiento dos veces (stock descontado doble).
--
-- No se puede poner UNIQUE sobre (TIPO_DOC_MOV, SERIE, NUMERO, LINEA) a
-- pelo: traspasos (TR), inventarios (IN) y tarifas (TA) generan varios
-- movimientos legitimos por clave. La unicidad SOLO aplica a FC/VE, que
-- ademas comparten identidad (la caja registra 'VE' y el mantenimiento
-- 'FC' para el mismo documento). Solucion MariaDB: columna generada que
-- solo tiene valor para FC/VE (NULL en el resto; los NULL no colisionan
-- en un indice UNIQUE) + indice unico sobre ella.
--
-- ANTES DE APLICAR en una BBDD existente, comprobar duplicados FC/VE:
--
--   SELECT SERIE_DOC_MOV, NUMERO_DOC_MOV, LINEA_MOV, COUNT(*) AS N
--     FROM fza_movimientos_almacen
--    WHERE TIPO_DOC_MOV IN ('FC','VE')
--    GROUP BY 1, 2, 3
--   HAVING N > 1;
--
-- Si devuelve filas, hay stock descontado doble historico: decidir la
-- limpieza (conservar el movimiento 'VE' y borrar el 'FC' duplicado es
-- el criterio que aplica el propio codigo) antes de crear el indice.
-- ============================================================================

-- 1) Columna generada CLAVE_FCVE_MOV
SET @existe := (SELECT COUNT(*)
                  FROM INFORMATION_SCHEMA.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME   = 'fza_movimientos_almacen'
                   AND COLUMN_NAME  = 'CLAVE_FCVE_MOV');
SET @sql := IF(@existe = 0,
  CONCAT('ALTER TABLE fza_movimientos_almacen ',
         'ADD COLUMN CLAVE_FCVE_MOV VARCHAR(50) ',
         'GENERATED ALWAYS AS (IF(TIPO_DOC_MOV IN (''FC'',''VE''), ',
         'CONCAT_WS(''/'', SERIE_DOC_MOV, NUMERO_DOC_MOV, LINEA_MOV), ',
         'NULL)) PERSISTENT'),
  'SELECT ''CLAVE_FCVE_MOV ya existe'' AS resultado');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) Indice unico sobre la columna generada
SET @existe := (SELECT COUNT(*)
                  FROM INFORMATION_SCHEMA.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME   = 'fza_movimientos_almacen'
                   AND INDEX_NAME   = 'UX_MOV_CLAVE_FCVE');
SET @sql := IF(@existe = 0,
  CONCAT('ALTER TABLE fza_movimientos_almacen ',
         'ADD UNIQUE INDEX UX_MOV_CLAVE_FCVE (CLAVE_FCVE_MOV)'),
  'SELECT ''UX_MOV_CLAVE_FCVE ya existe'' AS resultado');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
