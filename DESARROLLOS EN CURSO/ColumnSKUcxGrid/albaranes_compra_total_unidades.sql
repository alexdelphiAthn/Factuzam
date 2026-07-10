-- =============================================================================
-- Nº de prendas en ALBARANES DE COMPRA (vi_albaranes_compra)
-- =============================================================================
-- La vista cuenta prendas con COALESCE(TOTAL_UNIDADES, CANTIDAD): el
-- TOTAL_UNIDADES venia del pivote antiguo (linea consolidada). En el
-- modelo contrato (una linea por SKU) la cantidad real es CANTIDAD y
-- TOTAL_UNIDADES quedaba desfasado (DEFAULT 0) al editar celdas o al
-- generar el albaran desde pedido / sesion (INSERT sin la columna).
--
-- El codigo sincroniza TOTAL_UNIDADES := CANTIDAD en cada post
-- (UniDataAlbaranesCompra.BeforePost, con o sin SKU) y los INSERT
-- directos (inLibPedidosCompra, inLibComprasSesionesMaterializar)
-- ya graban la columna. Este script corrige los datos existentes:
-- TODAS las lineas SIN celdas de pivote antiguo (las consolidadas
-- antiguas conservan su TOTAL_UNIDADES agregado).
--
-- Idempotente.
-- =============================================================================

UPDATE fza_albaranes_compra_lineas L
   SET L.TOTAL_UNIDADES_ALBCLIN = L.CANTIDAD_ALBCLIN
 WHERE COALESCE(L.TOTAL_UNIDADES_ALBCLIN, -1) <> L.CANTIDAD_ALBCLIN
   AND NOT EXISTS (SELECT 1
                     FROM fza_albaranes_compra_celdas C
                    WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN
                      AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN
                      AND C.LINEA_ALBC_ALBCCEL  = L.LINEA_ALBCLIN);
