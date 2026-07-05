-- ============================================================================
-- Contador de lineas en cabecera de inventarios
-- ============================================================================
-- Anade fza_inventarios.CONTADOR_LINEAS_INV para reservar LINEA_INVLIN desde
-- cabecera, igual que el resto de documentos con lineas. El codigo ya no
-- calcula la siguiente linea desde el buffer ni desde la tabla de lineas.
--
-- Idempotente: se puede ejecutar varias veces.
-- ============================================================================
SET @existe_col := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_inventarios'
     AND COLUMN_NAME = 'CONTADOR_LINEAS_INV'
);
SET @sql := IF(@existe_col = 0,
  'ALTER TABLE `fza_inventarios`
     ADD COLUMN `CONTADOR_LINEAS_INV` varchar(8) NOT NULL
       DEFAULT ''00000000''
       COMMENT ''Contador de lineas de inventario''
       AFTER `TOTAL_EUROS_DIFERENCIA_INV`',
  'SELECT ''fza_inventarios.CONTADOR_LINEAS_INV ya existe'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_inventarios AS H
  JOIN fza_inventarios_lineas AS L
    ON L.CODIGO_EMP_INVLIN = H.CODIGO_EMP_INV
   AND L.CODIGO_ALM_INVLIN = H.CODIGO_ALM_INV
   AND L.SERIE_INV_INVLIN = H.SERIE_INV
   AND L.NUMERO_INV_INVLIN = H.NUMERO_INV
   SET H.CONTADOR_LINEAS_INV =
       LPAD(CAST(L.LINEA_INVLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_INVLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_inventarios_lineas AS L2
        WHERE L2.CODIGO_EMP_INVLIN = L.CODIGO_EMP_INVLIN
          AND L2.CODIGO_ALM_INVLIN = L.CODIGO_ALM_INVLIN
          AND L2.SERIE_INV_INVLIN = L.SERIE_INV_INVLIN
          AND L2.NUMERO_INV_INVLIN = L.NUMERO_INV_INVLIN
          AND TRIM(L2.LINEA_INVLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_INVLIN AS UNSIGNED) >
              CAST(L.LINEA_INVLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_INV IS NULL
        OR H.CONTADOR_LINEAS_INV = ''
        OR CAST(H.CONTADOR_LINEAS_INV AS UNSIGNED) <
           CAST(L.LINEA_INVLIN AS UNSIGNED));
