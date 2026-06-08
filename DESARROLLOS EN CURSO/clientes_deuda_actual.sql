-- ============================================================================
--  clientes_deuda_actual.sql
--  Calcula la DEUDA ACTUAL de cada cliente y la guarda en fza_clientes.
--  ------------------------------------------------------------------------
--  Deuda = suma de (PRECIO_VENTA_DEP - IMPORTE_ANTICIPO_DEP) de sus depositos
--  /prestamos PENDIENTE (positivos): lo que le falta por pagar de lo que se
--  ha llevado. Los clientes sin prestamos abiertos quedan a 0.
--
--  IMPORTANTE: ejecutar DESPUES de depositos_netear_devoluciones.sql, para que
--  los PENDIENTE sean solo prestamos reales (con las devoluciones ya cerradas).
--  Idempotente (recalcula desde cero en cada ejecucion). Sobrescribe
--  TOTAL_DEUDA_CLI de TODOS los clientes con la deuda de sus prestamos.
-- ============================================================================

UPDATE fza_clientes c
LEFT JOIN (
  SELECT CODIGO_CLI_DEP,
         SUM(PRECIO_VENTA_DEP - IMPORTE_ANTICIPO_DEP) AS deuda
    FROM fza_depositos_cliente
   WHERE ESTADO_DEP = 'PENDIENTE' AND CANTIDAD_PENDIENTE_DEP > 0
   GROUP BY CODIGO_CLI_DEP
) d ON d.CODIGO_CLI_DEP = c.CODIGO_CLI_CLI
   SET c.TOTAL_DEUDA_CLI = COALESCE(d.deuda, 0),
       c.INSTANTE_MODIF  = NOW();

-- Verificacion (opcional): la deuda de un cliente concreto (debe dar 498).
-- SELECT CODIGO_CLI_CLI, RAZON_SOCIAL_CLI, TOTAL_DEUDA_CLI
--   FROM fza_clientes WHERE CODIGO_CLI_CLI = '0008';
