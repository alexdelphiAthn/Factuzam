-- =============================================================================
-- Anade codigo Facturae a formas de pago
-- =============================================================================
-- Facturae exige PaymentMeans en cada vencimiento. Se guarda el codigo
-- oficial 01..19 en la forma de pago para que venta mayor no lo emita fijo.
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================================
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_formas_pago'
     AND COLUMN_NAME  = 'CODIGO_FACTURAE_FP'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_formas_pago
     ADD COLUMN CODIGO_FACTURAE_FP varchar(2) NULL DEFAULT ''01''
     AFTER ESVERBANCOEMPRESA_FORMA_PAGO_FP',
  'SELECT ''CODIGO_FACTURAE_FP ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_formas_pago
   SET CODIGO_FACTURAE_FP = '01'
 WHERE CODIGO_FACTURAE_FP IS NULL
    OR CODIGO_FACTURAE_FP = '';
INSERT INTO fza_config_campos
       (TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC,
        ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC)
SELECT 'fza_formas_pago', 'CODIGO_FACTURAE_FP', 'Codigo Facturae',
       120, 11, 'S'
 WHERE NOT EXISTS (
       SELECT 1
         FROM fza_config_campos
        WHERE TABLA_OBJETIVO_CC = 'fza_formas_pago'
          AND OBJETIVO_CC = 'CODIGO_FACTURAE_FP'
       );
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_formapago AS
SELECT fp.CODIGO_FP_FP,
       fp.ESACTIVO_FORMA_PAGO_FP,
       fp.ORDEN_FORMA_PAGO_FP,
       fp.DESCRIPCION_FORMA_PAGO_FP,
       fp.N_PLAZOS_FORMA_PAGO_FP,
       fp.N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP,
       fp.PORCENTAJE_ANTICIPO_FORMA_PAGO_FP,
       fp.ESVERBANCOEMPRESA_FORMA_PAGO_FP,
       fp.CODIGO_FACTURAE_FP,
       fp.ESDEFAULT_FORMA_PAGO_FP,
       fp.INSTANTE_MODIF,
       fp.INSTANTE_ALTA,
       fp.USUARIO_ALTA,
       fp.USUARIO_MODIF
  FROM fza_formas_pago fp
 ORDER BY fp.ORDEN_FORMA_PAGO_FP;
SELECT 'facturae_formas_pago_codigo aplicado' AS resultado;
