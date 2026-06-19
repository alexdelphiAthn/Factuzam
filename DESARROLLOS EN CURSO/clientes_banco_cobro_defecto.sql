-- ============================================================================
-- Banco de cobro por defecto por cliente (fza_clientes.CODIGO_EMPBAN_CLI)
--
-- Espejo de proveedores_pagos_defecto.sql en el lado de COBRO (ventas):
--   * La forma de pago por defecto del cliente YA EXISTE (CODIGO_FP_CLI):
--     la factura de venta la hereda en FORMA_PAGO_FAC al cargar el cliente
--     (BuscarCliente) y el recibo se reparte segun esa forma de pago.
--   * Falta la cuenta de la EMPRESA (ingreso) por defecto para cobrar a ese
--     cliente -> CODIGO_EMPBAN_CLI (FK a fza_empresas_bancos). Al generar el
--     recibo, el modal de seleccion de banco la pre-selecciona si pertenece a
--     la empresa de la factura, y se estampa en CODIGO_EMPBAN_REC.
--
-- OJO: IBAN_CLI (ya existente) es la cuenta del CLIENTE; esta columna es la
-- cuenta de INGRESO de la empresa, no la del cliente.
--
-- Idempotente (INFORMATION_SCHEMA). NO toca factuzam_original.sql.
-- ============================================================================
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_clientes'
     AND COLUMN_NAME  = 'CODIGO_EMPBAN_CLI'
);
SET @sSql := IF(@col_exists = 0,
  'ALTER TABLE `fza_clientes`
     ADD COLUMN `CODIGO_EMPBAN_CLI` varchar(8) NULL DEFAULT NULL
     COMMENT ''Cuenta de la empresa (ingreso) por defecto — FK a fza_empresas_bancos''
     AFTER `CODIGO_FP_CLI`',
  'SELECT ''CODIGO_EMPBAN_CLI ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
