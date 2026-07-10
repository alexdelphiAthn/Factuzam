-- =============================================================================
-- Reparacion de cantidades corruptas en pedidos de compra
-- =============================================================================
-- Sintoma (10/07/26): pedidos con "cantidades desorbitadas" (696, 572...)
-- y lineas duplicadas por SKU con precio 0. Origen: conversiones
-- fusion/des-pivote del modo tallas interrumpidas o con perdida, que
-- dejaron:
--   a) celdas huerfanas en fza_pedidos_compra_celdas (su linea ya no
--      existe) cuya suma machacaba CANTIDAD_PEDCLIN de lineas nuevas
--      que reutilizaban el numero;
--   b) lineas residuo de la expansion (una por talla, precio 0) que
--      nunca vuelven a fusionar con la linea original porque el precio
--      forma parte de la clave de fusion;
--   c) CANTIDAD_PEDCLIN desincronizada de la suma de sus celdas.
--
-- Este script LIMPIA (a) y (c). Las lineas (b) se LISTAN en el bloque
-- de diagnostico para revision manual: no hay forma mecanica segura de
-- distinguirlas de lineas legitimas con precio 0.
--
-- NOTA: LINEA_PEDCLIN es varchar(4) con relleno ('0010') pero la app
-- escribe LINEA_PEDC_PEDCCEL sin relleno ('10'): los cruces van por
-- valor numerico (CAST), nunca por igualdad de texto.
--
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. DIAGNOSTICO (solo lectura, ejecutar primero)
-- -----------------------------------------------------------------------------

-- 0.1 Celdas huerfanas: su linea ya no existe en el pedido.
SELECT c.SERIE_PEDC_PEDCCEL, c.NUMERO_PEDC_PEDCCEL,
       c.LINEA_PEDC_PEDCCEL, c.ID_AV_PIVOT_PEDCCEL,
       c.CANTIDAD_PEDCCEL
  FROM fza_pedidos_compra_celdas c
  LEFT JOIN fza_pedidos_compra_lineas l
    ON l.SERIE_PEDC_PEDCLIN  = c.SERIE_PEDC_PEDCCEL
   AND l.NUMERO_PEDC_PEDCLIN = c.NUMERO_PEDC_PEDCCEL
   AND CAST(l.LINEA_PEDCLIN AS UNSIGNED) =
       CAST(c.LINEA_PEDC_PEDCCEL AS UNSIGNED)
 WHERE l.LINEA_PEDCLIN IS NULL;

-- 0.2 Celdas cuyo ID_AV ya no existe en fza_atributos_valores: el
--     des-pivote las omitia y sus unidades se perdian.
SELECT c.SERIE_PEDC_PEDCCEL, c.NUMERO_PEDC_PEDCCEL,
       c.LINEA_PEDC_PEDCCEL, c.ID_AV_PIVOT_PEDCCEL,
       c.CANTIDAD_PEDCCEL
  FROM fza_pedidos_compra_celdas c
  LEFT JOIN fza_atributos_valores av
    ON av.ID_AV = c.ID_AV_PIVOT_PEDCCEL
 WHERE av.ID_AV IS NULL;

-- 0.3 Lineas cuya CANTIDAD no cuadra con la suma de sus celdas.
SELECT l.SERIE_PEDC_PEDCLIN, l.NUMERO_PEDC_PEDCLIN, l.LINEA_PEDCLIN,
       l.CODIGO_ART_PEDCLIN, l.CANTIDAD_PEDCLIN,
       c.TOTAL_CELDAS
  FROM fza_pedidos_compra_lineas l
  JOIN (SELECT SERIE_PEDC_PEDCCEL  AS SERIE,
               NUMERO_PEDC_PEDCCEL AS NUMERO,
               CAST(LINEA_PEDC_PEDCCEL AS UNSIGNED) AS LINEA,
               SUM(CANTIDAD_PEDCCEL) AS TOTAL_CELDAS
          FROM fza_pedidos_compra_celdas
         GROUP BY SERIE_PEDC_PEDCCEL, NUMERO_PEDC_PEDCCEL,
                  CAST(LINEA_PEDC_PEDCCEL AS UNSIGNED)) c
    ON c.SERIE  = l.SERIE_PEDC_PEDCLIN
   AND c.NUMERO = l.NUMERO_PEDC_PEDCLIN
   AND c.LINEA  = CAST(l.LINEA_PEDCLIN AS UNSIGNED)
 WHERE ABS(IFNULL(l.CANTIDAD_PEDCLIN, 0) - c.TOTAL_CELDAS) > 0.001;

-- 0.4 Lineas sospechosas de ser residuo de expansion: mismo pedido y
--     articulo con precio 0 conviviendo con otra linea del mismo
--     articulo con precio > 0. REVISAR Y BORRAR A MANO las que sobren
--     (desde la ficha del pedido, tras F1 para verlas fusionadas).
SELECT l0.SERIE_PEDC_PEDCLIN, l0.NUMERO_PEDC_PEDCLIN,
       l0.LINEA_PEDCLIN, l0.CODIGO_ART_PEDCLIN,
       l0.CODIGO_UNIDAD_PEDCLIN, l0.CANTIDAD_PEDCLIN,
       l0.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN
  FROM fza_pedidos_compra_lineas l0
 WHERE IFNULL(l0.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, 0) = 0
   AND EXISTS (SELECT 1
                 FROM fza_pedidos_compra_lineas l1
                WHERE l1.SERIE_PEDC_PEDCLIN  = l0.SERIE_PEDC_PEDCLIN
                  AND l1.NUMERO_PEDC_PEDCLIN = l0.NUMERO_PEDC_PEDCLIN
                  AND l1.CODIGO_ART_PEDCLIN  = l0.CODIGO_ART_PEDCLIN
                  AND IFNULL(
                        l1.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, 0) > 0)
 ORDER BY l0.SERIE_PEDC_PEDCLIN, l0.NUMERO_PEDC_PEDCLIN,
          l0.LINEA_PEDCLIN;

-- -----------------------------------------------------------------------------
-- 1. REPARACION: borrar celdas huerfanas (las de 0.1)
-- -----------------------------------------------------------------------------
DELETE c
  FROM fza_pedidos_compra_celdas c
  LEFT JOIN fza_pedidos_compra_lineas l
    ON l.SERIE_PEDC_PEDCLIN  = c.SERIE_PEDC_PEDCCEL
   AND l.NUMERO_PEDC_PEDCLIN = c.NUMERO_PEDC_PEDCCEL
   AND CAST(l.LINEA_PEDCLIN AS UNSIGNED) =
       CAST(c.LINEA_PEDC_PEDCCEL AS UNSIGNED)
 WHERE l.LINEA_PEDCLIN IS NULL;

-- -----------------------------------------------------------------------------
-- 2. REPARACION: resincronizar CANTIDAD/TOTAL de lineas con celdas
--    (las de 0.3). Solo lineas pivotadas: su cantidad es, por diseno,
--    la suma de sus celdas.
-- -----------------------------------------------------------------------------
UPDATE fza_pedidos_compra_lineas l
  JOIN (SELECT SERIE_PEDC_PEDCCEL  AS SERIE,
               NUMERO_PEDC_PEDCCEL AS NUMERO,
               CAST(LINEA_PEDC_PEDCCEL AS UNSIGNED) AS LINEA,
               SUM(CANTIDAD_PEDCCEL) AS TOTAL_CELDAS
          FROM fza_pedidos_compra_celdas
         GROUP BY SERIE_PEDC_PEDCCEL, NUMERO_PEDC_PEDCCEL,
                  CAST(LINEA_PEDC_PEDCCEL AS UNSIGNED)) c
    ON c.SERIE  = l.SERIE_PEDC_PEDCLIN
   AND c.NUMERO = l.NUMERO_PEDC_PEDCLIN
   AND c.LINEA  = CAST(l.LINEA_PEDCLIN AS UNSIGNED)
   SET l.CANTIDAD_PEDCLIN = c.TOTAL_CELDAS,
       l.TOTAL_PEDCLIN    = c.TOTAL_CELDAS *
         IFNULL(l.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, 0),
       l.INSTANTE_MODIF   = NOW()
 WHERE IFNULL(l.ID_AC_PIVOT_PEDCLIN, 0) > 0
   AND ABS(IFNULL(l.CANTIDAD_PEDCLIN, 0) - c.TOTAL_CELDAS) > 0.001;

-- -----------------------------------------------------------------------------
-- 3. Tras 1 y 2: abrir cada pedido afectado y GRABAR para que la
--    aplicacion recalcule los totales de cabecera (bases, impuestos,
--    liquido) y regenere fza_articulos_pdte_recibir. La columna
--    "Pedida" de la lista sale de la vista (suma de lineas) y queda
--    bien sin mas pasos.
-- -----------------------------------------------------------------------------
