-- =============================================================================
-- Fecha de aplicacion de descuento en tarifa (ventana de rebajas)
-- =============================================================================
-- Hasta ahora, si una linea articulo-tarifa estaba vigente (FECHA_DESDE_ARTTAR
-- .. FECHA_HASTA_ARTTAR) y activa, su descuento (PRECIO_DTO/PORCENTAJE_DTO) se
-- aplicaba SIEMPRE. El cliente pide acotar cuando aplica el descuento sin tener
-- que abrir otra tarifa: dos fechas a nivel de CABECERA de tarifa que definen
-- la ventana en la que el descuento es aplicable.
--
--   FECHA_DESDE_DTO_TAR / FECHA_HASTA_DTO_TAR  (cabecera fza_tarifas)
--
-- Semantica (la evalua el codigo en venta: caja y venta mayor):
--   - Ambas NULL  -> sin ventana: el descuento se aplica siempre (clasico).
--   - Una NULL    -> cota abierta por ese lado.
--   - Fecha del documento fuera de la ventana -> NO se aplica el descuento:
--     se cobra PRECIO_SALIDA y se anula el % / importe de descuento.
--
-- La sesion de cambios de tarifa (fza_tarifas_cambios) recibe las mismas dos
-- fechas (sufijo TARC) para poder fijar la ventana en la tarifa destino al
-- aplicar.
--
-- Idempotente:
--   - Columnas: se anaden solo si no existen (INFORMATION_SCHEMA.COLUMNS).
--   - Vista vi_tarifas: CREATE OR REPLACE.
--
-- NO toca factuzam_original.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Cabecera de tarifa: ventana de aplicacion del descuento
-- ---------------------------------------------------------------------------
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_tarifas'
     AND COLUMN_NAME  = 'FECHA_DESDE_DTO_TAR'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_tarifas
     ADD COLUMN FECHA_DESDE_DTO_TAR date NULL DEFAULT NULL
     AFTER VALOR_MENOS_AJUSTE_TAR',
  'SELECT ''FECHA_DESDE_DTO_TAR ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_tarifas'
     AND COLUMN_NAME  = 'FECHA_HASTA_DTO_TAR'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_tarifas
     ADD COLUMN FECHA_HASTA_DTO_TAR date NULL DEFAULT NULL
     AFTER FECHA_DESDE_DTO_TAR',
  'SELECT ''FECHA_HASTA_DTO_TAR ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Sesion de cambios: misma ventana para fijarla en la tarifa destino
-- ---------------------------------------------------------------------------
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_tarifas_cambios'
     AND COLUMN_NAME  = 'FECHA_DESDE_DTO_TARC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_tarifas_cambios
     ADD COLUMN FECHA_DESDE_DTO_TARC date NULL DEFAULT NULL
     AFTER FECHA_HASTA_TARC',
  'SELECT ''FECHA_DESDE_DTO_TARC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_tarifas_cambios'
     AND COLUMN_NAME  = 'FECHA_HASTA_DTO_TARC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_tarifas_cambios
     ADD COLUMN FECHA_HASTA_DTO_TARC date NULL DEFAULT NULL
     AFTER FECHA_DESDE_DTO_TARC',
  'SELECT ''FECHA_HASTA_DTO_TARC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 3. Recrear vi_tarifas para exponer la ventana (la cabecera de tarifas se
--    edita sobre esta vista: vista simple de una tabla -> actualizable).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vi_tarifas AS
SELECT
  CODIGO_TAR_ARTTAR,
  NOMBRE_TAR_TAR,
  ESACTIVO_ARTTAR,
  ORDEN_TAR,
  ESIMP_INCL_TAR,
  PORCENTAJE_MARGEN_TAR,
  VALOR_MULTIPLO_AJUSTE_TAR,
  VALOR_MENOS_AJUSTE_TAR,
  FECHA_DESDE_DTO_TAR,
  FECHA_HASTA_DTO_TAR,
  INSTANTE_MODIF,
  INSTANTE_ALTA,
  USUARIO_ALTA,
  USUARIO_MODIF
FROM fza_tarifas
WHERE ESACTIVO_ARTTAR = 'S'
ORDER BY ORDEN_TAR;
