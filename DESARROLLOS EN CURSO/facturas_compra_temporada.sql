-- =============================================================================
-- facturas_compra_temporada.sql
--
-- Anade la temporada de cabecera a fza_facturas_compra. En el legacy Herreras
-- viene en ocfacpro.Temporada y se traduce al catalogo TEMPORADA de
-- fza_propiedades_valores, igual que ID_PV_TEMPORADA_PEDC en pedidos.
--
-- FK logica a fza_propiedades_valores.ID_PV_ARTPROP con ID_PROP_PV='TEMPORADA'.
--
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================================

SET @col_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
     AND COLUMN_NAME  = 'ID_PV_TEMPORADA_FACC'
);

SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_facturas_compra` '
  'ADD COLUMN `ID_PV_TEMPORADA_FACC` int(11) NULL DEFAULT NULL '
  '  COMMENT ''FK logica fza_propiedades_valores.ID_PV_ARTPROP con '
  'ID_PROP_PV=TEMPORADA. Procede de ocfacpro.Temporada en la migracion.'' '
  'AFTER `FORMA_PAGO_FACC`',
  'SELECT ''ID_PV_TEMPORADA_FACC ya existe, se omite'' AS info'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_compra'
     AND INDEX_NAME   = 'IDX_FACC_TEMPORADA'
);

SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas_compra` '
  'ADD INDEX `IDX_FACC_TEMPORADA` (`ID_PV_TEMPORADA_FACC`)',
  'SELECT ''IDX_FACC_TEMPORADA ya existe, se omite'' AS info'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
