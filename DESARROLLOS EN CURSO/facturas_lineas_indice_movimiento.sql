-- =============================================================================
-- Indice IDX_FACLIN_NUMMOV en fza_facturas_lineas (NUMERO_MOV_FACLIN)
-- =============================================================================
-- El post-proceso de la migracion de facturas (tickets simplificados y venta
-- mayor) enlaza cada movimiento de almacen con su linea de factura:
--
--   UPDATE fza_movimientos_almacen m
--     JOIN fza_facturas_lineas l ON l.NUMERO_MOV_FACLIN = m.NUMERO_MOV
--      SET ...
--
-- fza_movimientos_almacen.NUMERO_MOV es PK, pero NUMERO_MOV_FACLIN no estaba
-- indexado, asi que el optimizador escaneaba la tabla entera de movimientos y
-- mantenia bloqueos durante minutos -> "Lock wait timeout exceeded", la
-- transaccion del dominio hacia ROLLBACK y fza_facturas quedaba VACIA.
--
-- Con el indice el UPDATE conduce desde la linea a su movimiento por PK y
-- termina en segundos. El migrador tambien lo crea por su cuenta
-- (UMigEngine.AsegurarIndice) antes del enlace; este script permite tenerlo
-- ya creado de antemano.
--
-- Idempotente: se crea solo si no existe.
-- =============================================================================

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_lineas'
     AND INDEX_NAME   = 'IDX_FACLIN_NUMMOV'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_facturas_lineas
     ADD INDEX IDX_FACLIN_NUMMOV (NUMERO_MOV_FACLIN)',
  'SELECT ''IDX_FACLIN_NUMMOV ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
