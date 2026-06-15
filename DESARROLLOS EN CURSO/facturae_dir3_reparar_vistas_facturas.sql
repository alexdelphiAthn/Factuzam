-- =============================================================================
-- Reparacion de vistas de facturas tras anadir parametros DIR3 Facturae
-- =============================================================================
-- Objetivo: dejar `vi_facturas`, `vi_facturas_normales` y
-- `vi_facturas_simplificadas` en la definicion minima que necesita el
-- mantenimiento de Borradores. No depende de tablas de consolidacion,
-- recibos ni columnas Verifactu opcionales.
--
-- Idempotente: se puede ejecutar varias veces. No toca factuzam_original.sql.
-- =============================================================================

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas AS
SELECT f.*,
       fp.DESCRIPCION_FORMA_PAGO_FP AS DESCRIPCION_FORMA_PAGO_FP
  FROM fza_facturas f
  LEFT JOIN fza_formas_pago fp
    ON f.FORMA_PAGO_FAC = fp.CODIGO_FP_FP
 ORDER BY f.FECHA_FAC DESC;

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas_normales AS
SELECT *
  FROM vi_facturas
 WHERE TIPO_FAC = 'NORMAL';

CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW vi_facturas_simplificadas AS
SELECT *
  FROM vi_facturas
 WHERE TIPO_FAC = 'SIMPLIFICADA';

SELECT 'vi_facturas reparada' AS resultado;
SELECT *
  FROM vi_facturas_normales
 LIMIT 1;
