-- =============================================================================
-- Vista vi_compras_sesiones (lista editable de la cabecera de sesiones)
-- =============================================================================
-- El Mto de Sesiones de Compra (inMtoComprasSesiones) necesita mostrar el
-- nombre y la razon social del proveedor en la lista (tsLista) y resolverlos
-- para el rotulo de la cabecera. En vez de meter subconsultas en el SELECT de
-- unqryTablaG (que confunden al parser de UniDAC al generar el SQL de
-- actualizacion -> "Field CODIGO_PRV_PRV not found"), seguimos el mismo patron
-- que vi_pedidos_compra: una vista MERGE con LEFT JOIN.
--
-- Al ser una vista MERGE (LEFT JOIN simple, sin agregados), MySQL expone en
-- la metadata el org_table real de cada columna, asi UniDAC detecta
-- fza_compras_sesiones como tabla base y genera INSERT/UPDATE/DELETE contra
-- ella (las columnas del proveedor quedan de solo lectura). La lista sigue
-- siendo editable y borrable exactamente igual que antes.
--
-- Idempotente:
--   - El bloque que asegura NOMBRE_PRV solo crea la columna si no existe.
--   - CREATE OR REPLACE VIEW reescribe la definicion sin error al repetir.
-- =============================================================================

-- 1. Asegurar la columna NOMBRE_PRV en fza_proveedores (idempotente).
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_proveedores'
     AND COLUMN_NAME  = 'NOMBRE_PRV'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_proveedores
     ADD COLUMN NOMBRE_PRV varchar(200) NULL DEFAULT NULL
     AFTER RAZON_SOCIAL_PRV',
  'SELECT ''NOMBRE_PRV ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Crear / reemplazar la vista. s.* + nombre y razon social del proveedor.
CREATE OR REPLACE VIEW `vi_compras_sesiones` AS
SELECT s.*,
       prv.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV_SES,
       prv.NOMBRE_PRV       AS NOMBRE_PRV_SES
  FROM fza_compras_sesiones s
  LEFT JOIN fza_proveedores prv
         ON prv.CODIGO_PRV_PRV = s.CODIGO_PRV_SES;
