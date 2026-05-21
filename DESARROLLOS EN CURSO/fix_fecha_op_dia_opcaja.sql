-- =============================================================================
-- Fix: FECHA_OP_DIA_OPCAJA no se rellenaba al insertar operaciones de caja
-- =============================================================================
-- La consulta de "Buscar / Modificar" (F10) del menu de caja filtra por
--
--     WHERE o.FECHA_OP_DIA_OPCAJA = :PFECHA
--
-- (ver src/DataModules/UniDataConsultaOpe.pas:144) para poder usar el indice
-- IDX_OPCAJA_DIA_CTX en lugar de envolver la columna con DATE().
--
-- Sin embargo, el INSERT en TdmCajaOpe.InsertarOperacionCaja
-- (src/DataModules/UniDataCaja.pas) no estaba rellenando FECHA_OP_DIA_OPCAJA,
-- asi que la columna quedaba NULL en las operaciones nuevas y la consulta
-- F10 no las encontraba. Sintoma reportado: "cuando voy a buscar/modificar
-- no salen mis operaciones".
--
-- Este script:
--   1. Rellena FECHA_OP_DIA_OPCAJA en las filas existentes donde sea NULL,
--      derivandolo de DATE(FECHA_OPERACION_OPCAJA).
--   2. Es idempotente: el WHERE filtra solo las filas que aun no tienen el
--      valor calculado, asi que volver a ejecutarlo no toca nada nuevo.
--
-- El INSERT del codigo Delphi ya queda corregido en el mismo commit para
-- que las operaciones futuras nazcan con el campo poblado (CURRENT_DATE
-- en el mismo statement que el NOW() de FECHA_OPERACION_OPCAJA).
-- =============================================================================

UPDATE fza_caja_operaciones
   SET FECHA_OP_DIA_OPCAJA = DATE(FECHA_OPERACION_OPCAJA)
 WHERE FECHA_OP_DIA_OPCAJA IS NULL;
