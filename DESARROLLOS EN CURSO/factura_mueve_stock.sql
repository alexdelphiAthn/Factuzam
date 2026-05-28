-- =============================================================================
-- Anade columna ESMUEVE_STOCK_FAC a fza_facturas
-- y propaga la columna en las vistas vi_facturas / vi_facturas_normales /
-- vi_facturas_simplificadas
-- =============================================================================
-- Por defecto las facturas SIMPLIFICADAS (TPV/caja) generan movimientos de
-- almacen al consolidarse (TIPO_DOC_MOV='FC'). Las facturas NORMALES no
-- mueven stock: el albaran asociado es quien lo hace. Para casos puntuales
-- (venta directa al mayor sin albaran previo) anadimos un check en la
-- pantalla de factura NORMAL para que el usuario opte por generar los
-- movimientos al consolidar.
--
-- ESMUEVE_STOCK_FAC: prefijo ES + nucleo MUEVE_STOCK + sufijo FAC, varchar(1)
-- con valores 'S'/'N' (§3.1 del LIBRO_DE_ESTILO_BBDD.md). Default 'N': el
-- comportamiento sigue siendo "no mover stock" en facturas existentes.
-- En SIMPLIFICADAS la columna no se usa: el AfterPost ya las trata por su
-- TIPO_FAC.
--
-- Las vistas vi_facturas / vi_facturas_normales / vi_facturas_simplificadas
-- listaban hasta ahora columnas explicitamente. Las recreamos con SELECT *
-- para que futuras columnas de fza_facturas se propaguen automaticamente
-- sin tocar este script.
--
-- Idempotente: la columna se anade solo si no existe; las vistas se
-- redefinen con CREATE OR REPLACE.
-- =============================================================================

-- 1. Columna ESMUEVE_STOCK_FAC
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'ESMUEVE_STOCK_FAC'
);

SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN ESMUEVE_STOCK_FAC varchar(1) NULL DEFAULT ''N''
       COMMENT ''Si la factura NORMAL genera movimientos de almacen al consolidar''
     AFTER TIPO_FAC',
  'SELECT ''ESMUEVE_STOCK_FAC ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Vistas con SELECT * para que ESMUEVE_STOCK_FAC (y futuras columnas) se
-- propaguen sin tocar mas el SQL.
CREATE OR REPLACE VIEW vi_facturas AS
  SELECT fza_facturas.*,
         fza_formas_pago.DESCRIPCION_FORMA_PAGO_FP AS DESCRIPCION_FORMA_PAGO_FP
    FROM fza_facturas
    LEFT JOIN fza_formas_pago
         ON fza_facturas.FORMA_PAGO_FAC = fza_formas_pago.CODIGO_FP_FP
   ORDER BY fza_facturas.FECHA_FAC DESC;

CREATE OR REPLACE VIEW vi_facturas_normales AS
  SELECT * FROM vi_facturas WHERE TIPO_FAC = 'NORMAL';

CREATE OR REPLACE VIEW vi_facturas_simplificadas AS
  SELECT * FROM vi_facturas WHERE TIPO_FAC = 'SIMPLIFICADA';
