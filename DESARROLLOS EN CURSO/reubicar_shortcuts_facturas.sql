-- Reubicar shortcuts de Facturas en fza_winforms
-- Ctrl+F pasa a Fotos, Ctrl+Alt+F a Facturas Normales,
-- Ctrl+Shift+F a Simplificadas, Ctrl+Alt+Shift+F a Compras.
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+F'
 WHERE CALL_WINF = 'Facturas'
   AND SHORTCUT_WINF = 'Ctrl+F';
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Shift+F'
 WHERE CALL_WINF = 'FacturasSimplif'
   AND SHORTCUT_WINF <> 'Ctrl+Shift+F';
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+Shift+F'
 WHERE CALL_WINF = 'AlbaranesCompra'
   AND SHORTCUT_WINF = 'Ctrl+Alt+C';
