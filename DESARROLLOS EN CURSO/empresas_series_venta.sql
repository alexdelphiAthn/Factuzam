-- ============================================================================
--  empresas_series_venta.sql
--  Rellena las series de VENTA migradas (fza_empresas_series) con los valores
--  correctos: son facturas SIMPLIFICADAS (tickets) de caja.
--  ------------------------------------------------------------------------
--  La migracion las creaba con CODIGO_CAJA, TIPO_DOC, SUBTIPO y FECHA_DESDE
--  vacios (NULL). Este UPDATE los fija:
--    CODIGO_CAJA_EMPSER = '1'           (la serie es por empresa/almacen/caja;
--                                         la caja suele ser la 1)
--    TIPO_DOC_EMPSER    = 'FC'
--    SUBTIPO_EMPSER     = 'SIMPLIFICADA'
--    FECHA_DESDE_EMPSER = '2000-01-01'  (fija temprana: cubre TODO el historico;
--                                         con la de hoy las facturas antiguas
--                                         no encontrarian su serie)
--  Idempotente. Por defecto toca TODAS las filas de fza_empresas_series; si
--  quieres limitarlo a las migradas, anade  AND USUARIO_ALTA = '<usuario>'.
-- ============================================================================

UPDATE fza_empresas_series
   SET CODIGO_CAJA_EMPSER = '1',
       TIPO_DOC_EMPSER    = 'FC',
       SUBTIPO_EMPSER     = 'SIMPLIFICADA',
       FECHA_DESDE_EMPSER = '2000-01-01',
       INSTANTE_MODIF     = NOW();

-- Verificacion (opcional):
-- SELECT CODIGO_SERIE_EMPSER, CODIGO_EMP_EMPSER, CODIGO_ALM_EMPSER,
--        CODIGO_CAJA_EMPSER, TIPO_DOC_EMPSER, SUBTIPO_EMPSER, FECHA_DESDE_EMPSER
--   FROM fza_empresas_series ORDER BY CODIGO_EMP_EMPSER, CODIGO_SERIE_EMPSER;
