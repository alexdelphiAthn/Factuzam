-- =============================================================================
-- Redirige 'Facturas' al descendiente Normal (paso 2/4 del refactor)
-- =============================================================================
-- Tras crear TfrmMtoFacturasNormal (descendiente de Base con filtro
-- TIPO_FAC = 'NORMAL'), la entrada 'Facturas' del menu pasa a abrir el
-- descendiente en lugar de la base. La base queda sin entrada de menu
-- (sigue existiendo en codigo para que herede el Simplif del commit 3).
--
-- Tambien se migran las preferencias de UI (anchos/orden de columnas...)
-- de la base al descendiente Normal: tras el refactor, el form visible
-- para el usuario de venta mayor es Normal, no Base.
--
-- Idempotente. Correr DESPUES de migracion_facturas_base.sql.
-- =============================================================================

UPDATE fza_winforms
   SET UNITF_WINF = 'inMtoFacturasNormal.TfrmMtoFacturasNormal'
 WHERE CALL_WINF = 'Facturas'
   AND UNITF_WINF = 'inMtoFacturasBase.TfrmMtoFacturasBase';

UPDATE fza_usuarios_perfiles
   SET KEY_USUPER = 'frmMtoFacturasNormal'
 WHERE KEY_USUPER = 'frmMtoFacturasBase';
