-- =====================================================================
-- Script: fix_pmp_stock_desde_movimientos.sql
-- Objetivo: reconstruir PRECIO_MEDIO_STK y VALOR_TOTAL_STK (y CANTIDAD_STK)
--           de fza_articulos_stockactual a partir del historico real de
--           fza_movimientos_almacen, mediante REPLAY CRONOLOGICO (PMP real).
--
-- Contexto del problema:
--   En instalaciones existentes, fza_articulos_stockactual tiene
--   PRECIO_MEDIO_STK = 0 y VALOR_TOTAL_STK = 0 aunque los movimientos SI
--   llevan el coste. Como el coste de un traspaso (y de cualquier salida)
--   se valora con PRECIO_MEDIO_STK, el coste sale 0. Este script recompone
--   el PMP del stock desde los movimientos.
--
-- Modelo de coste (elegido):
--   - Coste UNITARIO de una ENTRADA = TOTAL_COSTE_MOV / CANTIDAD_MOV.
--     Si ese total viniera 0, se usa PRECIO_COSTE_UNITARIO_MOV como
--     respaldo (para no arrastrar 0 si el total no se grabo).
--   - PMP por capas: cada entrada sube la media ponderada; cada salida
--     sale al PMP del momento (no cambia el PMP).
--
-- Idempotente: es un recalculo puro. Se puede re-ejecutar las veces que
--   haga falta; siempre deja el mismo resultado. NO cambia esquema. Crea
--   y borra tablas temporales. NO toca fza_movimientos_almacen (el
--   historico de movimientos se considera correcto).
--
-- AVISO DE VOLUMEN: recorre TODOS los movimientos activos de TODOS los
--   almacenes. Con cientos de miles de filas puede tardar; lanzar en
--   ventana de mantenimiento y probar antes en una copia de la BBDD.
--
-- Alcance: afecta a la valoracion de stock de TODO el ERP (compras,
--   ventas, traspasos, inventarios). Revisar resultado antes de dar por
--   bueno.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Volcado ordenado de los movimientos activos a una tabla con RN
--    secuencial (AUTO_INCREMENT como PK clustered en InnoDB). El
--    ORDER BY del INSERT...SELECT garantiza el orden del RN.
--    Clave de agrupacion = ALMACEN + '|' + SKU (replay por cada par).
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_pmp_movs;
CREATE TEMPORARY TABLE tmp_pmp_movs (
    RN                BIGINT        NOT NULL AUTO_INCREMENT,
    CLAVE             VARCHAR(80)   NOT NULL,   -- ALM|SKU
    CODIGO_ALM_MOV    VARCHAR(10)   NOT NULL,
    CODIGO_UNIDAD_MOV VARCHAR(50)   NOT NULL,
    TIPO_MOV          VARCHAR(1)    NOT NULL,
    CANTIDAD_MOV      DECIMAL(19,6) NOT NULL DEFAULT 0,
    COSTE_UNIT_ENT    DECIMAL(19,6) NOT NULL DEFAULT 0,  -- solo para entradas
    PMP_NUEVO         DECIMAL(19,6) NOT NULL DEFAULT 0,
    STOCK_NUEVO       DECIMAL(19,6) NOT NULL DEFAULT 0,
    CLAVE_PREV        VARCHAR(80)   NULL,
    PRIMARY KEY (RN),
    KEY IDX_CLAVE (CLAVE)
) ENGINE=InnoDB;

INSERT INTO tmp_pmp_movs
    (CLAVE, CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV, TIPO_MOV,
     CANTIDAD_MOV, COSTE_UNIT_ENT)
SELECT CONCAT(m.CODIGO_ALM_MOV, '|', m.CODIGO_UNIDAD_MOV),
       m.CODIGO_ALM_MOV,
       m.CODIGO_UNIDAD_MOV,
       m.TIPO_MOV,
       IFNULL(m.CANTIDAD_MOV, 0),
       -- Coste unitario de entrada = TOTAL_COSTE_MOV / cantidad; si el total
       -- es 0 se usa PRECIO_COSTE_UNITARIO_MOV como respaldo. En salidas no
       -- se usa (el coste de salida sale del PMP del momento).
       CASE
         WHEN m.TIPO_MOV = 'E' AND IFNULL(m.CANTIDAD_MOV,0) > 0
              AND IFNULL(m.TOTAL_COSTE_MOV,0) <> 0
           THEN m.TOTAL_COSTE_MOV / m.CANTIDAD_MOV
         WHEN m.TIPO_MOV = 'E'
           THEN IFNULL(m.PRECIO_COSTE_UNITARIO_MOV, 0)
         ELSE 0
       END
  FROM fza_movimientos_almacen m
 WHERE m.ESACTIVO_MOV = 'S'
 ORDER BY m.CODIGO_ALM_MOV, m.CODIGO_UNIDAD_MOV,
          m.FECHA_MOV, m.INSTANTE_ALTA;

-- ---------------------------------------------------------------------
-- 2. Replay con variables de sesion. El ORDER BY RN fuerza el barrido
--    secuencial. Las asignaciones del SET se evaluan de izquierda a
--    derecha: primero PMP_NUEVO (usa @stock/@pmp de la fila anterior y
--    @clave_prev para detectar cambio de ALM|SKU), luego STOCK_NUEVO
--    (actualiza @stock), y por ultimo CLAVE_PREV (actualiza @clave_prev).
-- ---------------------------------------------------------------------
SET @clave_prev := '';
SET @stock      := 0;
SET @pmp        := 0;

UPDATE tmp_pmp_movs
   SET PMP_NUEVO = (
           @pmp := IF(
               @clave_prev <> CLAVE,
               /* Cambio de ALM|SKU: empezamos de cero */
               IF(TIPO_MOV = 'E', COSTE_UNIT_ENT, 0),
               /* Mismo ALM|SKU que la fila anterior */
               IF(TIPO_MOV = 'E',
                   IF(@stock <= 0,
                       COSTE_UNIT_ENT,
                       ((@stock * @pmp) + (CANTIDAD_MOV * COSTE_UNIT_ENT))
                         / (@stock + CANTIDAD_MOV)),
                   @pmp   /* salida: el PMP no cambia */
               )
           )
       ),
       STOCK_NUEVO = (
           @stock := IF(
               @clave_prev <> CLAVE,
               IF(TIPO_MOV = 'E', CANTIDAD_MOV, -CANTIDAD_MOV),
               IF(TIPO_MOV = 'E', @stock + CANTIDAD_MOV,
                                  @stock - CANTIDAD_MOV)
           )
       ),
       CLAVE_PREV = (@clave_prev := CLAVE)
 ORDER BY RN;

-- ---------------------------------------------------------------------
-- 3. Estado final por ALM|SKU = el ultimo movimiento (RN maximo).
--    Volcamos cantidad / valor / PMP a fza_articulos_stockactual.
--    Solo se tocan las filas (alm, sku) que tienen movimientos; las que
--    no, se dejan como esten (no se ponen a 0).
-- ---------------------------------------------------------------------
INSERT INTO fza_articulos_stockactual
    (CODIGO_ALM_STK, CODIGO_UNIDAD_STK,
     CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTE_MODIF)
SELECT t.CODIGO_ALM_MOV,
       t.CODIGO_UNIDAD_MOV,
       t.STOCK_NUEVO,
       IF(t.STOCK_NUEVO > 0, t.STOCK_NUEVO * t.PMP_NUEVO, 0),
       IF(t.STOCK_NUEVO > 0, t.PMP_NUEVO, 0),
       NOW()
  FROM tmp_pmp_movs t
  JOIN (
        SELECT CLAVE, MAX(RN) AS RN_MAX
          FROM tmp_pmp_movs
         GROUP BY CLAVE
       ) ult
    ON ult.CLAVE  = t.CLAVE
   AND ult.RN_MAX = t.RN
 ON DUPLICATE KEY UPDATE
    CANTIDAD_STK     = VALUES(CANTIDAD_STK),
    VALOR_TOTAL_STK  = VALUES(VALOR_TOTAL_STK),
    PRECIO_MEDIO_STK = VALUES(PRECIO_MEDIO_STK),
    INSTANTE_MODIF   = NOW();

DROP TEMPORARY TABLE IF EXISTS tmp_pmp_movs;

-- ---------------------------------------------------------------------
-- 4. Comprobacion (opcional): descomenta para ver el resultado de un SKU.
-- ---------------------------------------------------------------------
-- SELECT CODIGO_ALM_STK, CODIGO_UNIDAD_STK, CANTIDAD_STK,
--        VALOR_TOTAL_STK, PRECIO_MEDIO_STK
--   FROM fza_articulos_stockactual
--  WHERE CODIGO_UNIDAD_STK LIKE '02070173/%'
--  ORDER BY CODIGO_ALM_STK, CODIGO_UNIDAD_STK;
