-- =============================================================================
-- Fix CONTADOR_LINEAS_PEDC en fza_pedidos_compra
-- =============================================================================
-- Sincroniza el contador de lineas de la cabecera con la ultima LINEA real
-- almacenada en fza_pedidos_compra_lineas. Necesario al cambiar el alta de
-- lineas del Mto de pedidos de compra de un MAX(LINEA_PEDCLIN)+10 (que NO
-- tocaba el contador) al helper inLibContadorLineas.GetSiguienteLineaDoc
-- (UPDATE atomico de CONTADOR_LINEAS_PEDC +10).
--
-- Si un pedido tenia lineas anadidas a mano con el codigo viejo, su
-- CONTADOR_LINEAS_PEDC pudo quedar por detras del MAX(LINEA_PEDCLIN) real
-- (o NULL), y la primera linea nueva con el helper colisionaria con la PK
-- (NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN). Este script
-- resiembra el contador al maximo real para que el +10 siguiente no choque.
-- Los pedidos materializados ya tenian el contador sincronizado (la
-- materializacion lo fija a NLIN*10), asi que no se ven afectados.
--
-- CONTADOR_LINEAS_PEDC y LINEA_PEDCLIN son varchar: comparamos y guardamos
-- via CAST(... AS UNSIGNED) y LPAD a 8 digitos (formato del resto del
-- sistema).
--
-- Idempotente: se puede ejecutar varias veces sin efectos secundarios (tras
-- la primera pasada CONTADOR = ULTIMA_LINEA y el WHERE ya no casa).
-- =============================================================================

UPDATE fza_pedidos_compra AS C
   JOIN (
       SELECT SERIE_PEDC_PEDCLIN,
              NUMERO_PEDC_PEDCLIN,
              MAX(CAST(LINEA_PEDCLIN AS UNSIGNED)) AS ULTIMA_LINEA
         FROM fza_pedidos_compra_lineas
        GROUP BY SERIE_PEDC_PEDCLIN, NUMERO_PEDC_PEDCLIN
   ) AS L
     ON L.SERIE_PEDC_PEDCLIN  = C.SERIE_PEDC
    AND L.NUMERO_PEDC_PEDCLIN = C.NUMERO_PEDC
  SET C.CONTADOR_LINEAS_PEDC = LPAD(L.ULTIMA_LINEA, 8, '0')
WHERE C.CONTADOR_LINEAS_PEDC IS NULL
   OR CAST(C.CONTADOR_LINEAS_PEDC AS UNSIGNED) < L.ULTIMA_LINEA;
