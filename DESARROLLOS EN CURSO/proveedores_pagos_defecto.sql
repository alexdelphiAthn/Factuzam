-- ============================================================================
-- Defectos de pago por proveedor: forma de pago y banco de la empresa (cargo)
--
-- Anade a fza_proveedores dos columnas para fijar, por proveedor, los valores
-- por defecto que dirigen el pago de sus compras:
--   * CODIGO_FP_PRV     -> forma de pago por defecto (FK a fza_formas_pago).
--                          Pre-rellena la forma de pago de la factura de compra
--                          (que es la que reparte plazos/vencimientos al
--                          generar los efectos).
--   * CODIGO_EMPBAN_PRV -> cuenta de la EMPRESA (cargo) por defecto para pagar
--                          a ese proveedor (FK a fza_empresas_bancos). Al
--                          generar el efecto, el modal de seleccion de banco
--                          la pre-selecciona si pertenece a la empresa de la
--                          factura.
--
-- OJO: IBAN_PRV (ya existente) es la cuenta del PROVEEDOR; estas columnas son
-- defectos de PAGO de la empresa, no la cuenta del proveedor.
--
-- Idempotente (INFORMATION_SCHEMA). NO toca factuzam_original.sql.
-- ============================================================================
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_proveedores'
     AND COLUMN_NAME  = 'CODIGO_FP_PRV'
);
SET @sSql := IF(@col_exists = 0,
  'ALTER TABLE `fza_proveedores`
     ADD COLUMN `CODIGO_FP_PRV` varchar(20) NULL DEFAULT NULL
     COMMENT ''Forma de pago por defecto — FK a fza_formas_pago''
     AFTER `IBAN_PRV`',
  'SELECT ''CODIGO_FP_PRV ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_proveedores'
     AND COLUMN_NAME  = 'CODIGO_EMPBAN_PRV'
);
SET @sSql := IF(@col_exists = 0,
  'ALTER TABLE `fza_proveedores`
     ADD COLUMN `CODIGO_EMPBAN_PRV` varchar(8) NULL DEFAULT NULL
     COMMENT ''Cuenta de la empresa (cargo) por defecto — FK a fza_empresas_bancos''
     AFTER `CODIGO_FP_PRV`',
  'SELECT ''CODIGO_EMPBAN_PRV ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
