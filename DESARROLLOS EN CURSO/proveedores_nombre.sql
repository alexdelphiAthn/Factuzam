-- =============================================================================
-- Anade columna NOMBRE_PRV a fza_proveedores
-- =============================================================================
-- La tabla destino solo tenia RAZON_SOCIAL_PRV. El ERP origen (Herreras,
-- ocpro) guarda dos campos: Nombre (nombre corto / comercial) y
-- RazonSocial (denominacion legal). Para no perder informacion en la
-- migracion, anadimos NOMBRE_PRV en destino y dejamos que el migrador
-- vuelque ambos campos.
--
-- Sigue la convencion del libro de estilo: sufijo de tabla (`PRV`) tras
-- el nucleo del concepto. NOMBRE_PRV (no NOMBRE_PROVEEDOR_PRV: redundante
-- — vease §3.3 de LIBRO_DE_ESTILO_BBDD.md).
--
-- Idempotente: se puede ejecutar varias veces. La columna se anade solo
-- si no existe.
-- =============================================================================

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
