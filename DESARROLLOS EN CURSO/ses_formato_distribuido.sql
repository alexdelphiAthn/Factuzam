-- Anyade ESFORMATO_DISTRIBUIDO_SES a fza_compras_sesiones (idempotente).
-- 'S' = la sesion captura cantidades por (linea, talla, almacen) usando
--       un modal distribuidor (almacen x talla). En el grid principal de
--       la sesion la cantidad mostrada por talla es la SUMA de todos los
--       almacenes. Al materializar se crea un SKU por almacen.
-- 'N' = comportamiento clasico: una celda = una cantidad en el almacen
--       de cabecera (CODIGO_ALM_SES).

SET @c := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'fza_compras_sesiones'
              AND COLUMN_NAME  = 'ESFORMATO_DISTRIBUIDO_SES');
SET @s := IF(@c = 0,
  'ALTER TABLE `fza_compras_sesiones`
     ADD COLUMN `ESFORMATO_DISTRIBUIDO_SES` varchar(1) NOT NULL DEFAULT ''N''
     AFTER `ESGENERA_ALBARAN_SES`',
  'SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
