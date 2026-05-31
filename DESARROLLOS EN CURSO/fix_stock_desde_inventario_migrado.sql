-- =====================================================================
-- Script: fix_stock_desde_inventario_migrado.sql
-- Objetivo: poner el PMP (y el valor) en fza_articulos_stockactual usando
--           el coste que el IMPORTADOR legacy dejó SOLO en las líneas de
--           inventario, pero que nunca llegó a articulos_stock.
--
-- Contexto:
--   El migrador SQL Server (utilmigsqlsrv / inLibMigInventarios.pas) carga
--   el stock inicial como un documento de INVENTARIO
--   (fza_inventarios + fza_inventarios_lineas) y lo deja directamente en
--   ESTADO_INV='APLICADO' SIN llamar a PRC_FZA_INVENTARIOS_APLICAR. Ese SP
--   es el que habría volcado cantidad/valor/PMP a fza_articulos_stockactual.
--   Resultado: en stockactual el PRECIO_MEDIO_STK y el VALOR_TOTAL_STK
--   quedan a 0, aunque la CANTIDAD ya está y el coste correcto SÍ está en
--   fza_inventarios_lineas.PRECIO_MEDIO_NUEVO_INVLIN.
--
--   Este script hace lo que el inventario debió hacer sobre articulos_stock,
--   SIN tocar el importador.
--
-- Criterio (seguro y re-ejecutable):
--   - Solo actúa sobre filas de stockactual cuyo PMP está a 0 (las rotas).
--     Así no pisa SKUs que ya tengan un PMP real de compras/ventas
--     posteriores a la migración.
--   - NO cambia la CANTIDAD_STK (se respeta la cantidad actual, que puede
--     haber evolucionado por ventas). Solo fija el PMP unitario y recalcula
--     VALOR_TOTAL = CANTIDAD_STK actual × PMP.
--   - Fuente del PMP: PRECIO_MEDIO_NUEVO_INVLIN del inventario migrado
--     (SERIE_INV='IN' y NUMERO_INV LIKE 'MIG%'); respaldo a
--     PRECIO_MEDIO_INVLIN si aquel viniera 0.
--
-- Idempotente: al filtrar por PMP=0, re-ejecutarlo no vuelve a tocar lo ya
--   corregido. NO cambia esquema. NO toca el importador ni los movimientos.
--
-- AVISO: afecta a la valoración de stock del ERP. Probar en copia antes de
--   producción.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Snapshot del coste por (almacén, SKU) desde el inventario migrado.
--    Un PMP unitario por par; si hubiera varias líneas, toma el mayor PMP
--    no nulo (no deberían existir duplicados por SKU/almacén).
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_pmp_inv_mig;
CREATE TEMPORARY TABLE tmp_pmp_inv_mig (
    ALM VARCHAR(10)   NOT NULL,
    SKU VARCHAR(50)   NOT NULL,
    PMP DECIMAL(19,6) NOT NULL DEFAULT 0,
    PRIMARY KEY (ALM, SKU)
) ENGINE=InnoDB;

INSERT INTO tmp_pmp_inv_mig (ALM, SKU, PMP)
SELECT L.CODIGO_ALM_INVLIN,
       L.CODIGO_UNIDAD_INVLIN,
       MAX(COALESCE(NULLIF(L.PRECIO_MEDIO_NUEVO_INVLIN, 0),
                    L.PRECIO_MEDIO_INVLIN, 0))
  FROM fza_inventarios_lineas L
  JOIN fza_inventarios C
    ON C.CODIGO_EMP_INV = L.CODIGO_EMP_INVLIN
   AND C.CODIGO_ALM_INV = L.CODIGO_ALM_INVLIN
   AND C.SERIE_INV      = L.SERIE_INV_INVLIN
   AND C.NUMERO_INV     = L.NUMERO_INV_INVLIN
 WHERE C.SERIE_INV  = 'IN'
   AND C.NUMERO_INV LIKE 'MIG%'
 GROUP BY L.CODIGO_ALM_INVLIN, L.CODIGO_UNIDAD_INVLIN
HAVING MAX(COALESCE(NULLIF(L.PRECIO_MEDIO_NUEVO_INVLIN, 0),
                    L.PRECIO_MEDIO_INVLIN, 0)) > 0;

-- ---------------------------------------------------------------------
-- 2. Fija el PMP y recalcula el valor en las filas de stock con PMP=0.
--    Se respeta la cantidad actual (CANTIDAD_STK).
-- ---------------------------------------------------------------------
UPDATE fza_articulos_stockactual S
  JOIN tmp_pmp_inv_mig T
    ON T.ALM = S.CODIGO_ALM_STK
   AND T.SKU = S.CODIGO_UNIDAD_STK
   SET S.PRECIO_MEDIO_STK = T.PMP,
       S.VALOR_TOTAL_STK  = S.CANTIDAD_STK * T.PMP,
       S.INSTANTE_MODIF   = NOW(),
       S.USUARIO_MODIF    = 'SCRIPT_FIX'
 WHERE COALESCE(S.PRECIO_MEDIO_STK, 0) = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_pmp_inv_mig;

-- ---------------------------------------------------------------------
-- 3. Comprobación (opcional): descomenta para ver un SKU concreto.
-- ---------------------------------------------------------------------
-- SELECT CODIGO_ALM_STK, CODIGO_UNIDAD_STK, CANTIDAD_STK,
--        VALOR_TOTAL_STK, PRECIO_MEDIO_STK
--   FROM fza_articulos_stockactual
--  WHERE CODIGO_UNIDAD_STK LIKE '02070173/%'
--  ORDER BY CODIGO_ALM_STK, CODIGO_UNIDAD_STK;
