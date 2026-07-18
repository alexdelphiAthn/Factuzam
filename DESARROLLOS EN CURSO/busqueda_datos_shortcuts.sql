-- =============================================================================
-- Atajos de Búsqueda de datos, Empresas y Empleados
-- =============================================================================
-- Sincroniza fza_winforms con los accesos definidos en la aplicación:
--   Ctrl+E       -> Búsqueda compleja de artículos y SKU.
--   Ctrl+Alt+E   -> Empresas.
--   Ctrl+Shift+E -> Empleados.
--
-- Búsqueda de datos no se registra en fza_winforms porque es un modal global
-- invocado desde TfrmMtoPrincipal.AppMessage, no un Mto abierto por ShowMto.
-- Los UPDATE son idempotentes y pueden reaplicarse sin efectos adicionales.
-- =============================================================================
UPDATE `fza_winforms`
   SET `SHORTCUT_WINF` = 'Ctrl+Alt+E'
 WHERE `CALL_WINF` = 'Empresas'
   AND COALESCE(`SHORTCUT_WINF`, '') <> 'Ctrl+Alt+E';
UPDATE `fza_winforms`
   SET `SHORTCUT_WINF` = 'Ctrl+Shift+E'
 WHERE `CALL_WINF` = 'Empleados'
   AND COALESCE(`SHORTCUT_WINF`, '') <> 'Ctrl+Shift+E';
