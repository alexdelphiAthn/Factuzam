-- =============================================================================
-- Rename de TfrmMtoFacturas a TfrmMtoFacturasBase en fza_winforms
-- =============================================================================
-- Tras el refactor que separa la pantalla de facturas en una base y dos
-- descendientes (Normal, Simplificada), la unidad y la clase pasan a
-- llamarse inMtoFacturasBase.TfrmMtoFacturasBase. Hay que actualizar
-- la entrada existente de la tabla fza_winforms para que ShowMto siga
-- abriendo correctamente la pantalla con Ctrl+F.
--
-- Idempotente: si ya esta apuntando al nuevo nombre, el UPDATE no
-- cambia nada.
-- =============================================================================

UPDATE fza_winforms
   SET UNITF_WINF = 'inMtoFacturasBase.TfrmMtoFacturasBase'
 WHERE CALL_WINF = 'Facturas'
   AND UNITF_WINF = 'inMtoFacturas.TfrmMtoFacturas';

-- Migra las preferencias UI (anchos de columna, orden, visibilidad...)
-- de la antigua pantalla a la nueva clase base. Idempotente.
UPDATE fza_usuarios_perfiles
   SET KEY_USUPER = 'frmMtoFacturasBase'
 WHERE KEY_USUPER = 'frmMtoFacturas';
