-- =============================================================================
-- Cambia el atajo de menu de Propiedades a Ctrl+Alt+Y en fza_winforms
-- =============================================================================
-- El menu (TMenuItem.ShortCut en inMtoPrincipal.dfm) ya pasa de Ctrl+Y a
-- Ctrl+Alt+Y. La tabla fza_winforms guarda una copia del atajo en
-- SHORTCUT_WINF; este script la deja en sync para las BBDD ya instaladas.
--
-- Motivo: Ctrl+Y estaba duplicado entre Propiedades y la opcion
-- "Hacer Copia de Seguridad". Se libera Ctrl+Y para la copia y Propiedades
-- pasa a Ctrl+Alt+Y (formato de cadena igual al del resto de filas:
-- 'Ctrl+Alt+S', 'Ctrl+Alt+B'...).
--
-- Idempotente: un UPDATE deja el mismo resultado se ejecute las veces que
-- se ejecute. Solo toca la fila CALL_WINF = 'Propiedades' y unicamente si
-- aun no tiene el valor nuevo.
-- =============================================================================
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+Y'
 WHERE CALL_WINF = 'Propiedades'
   AND (SHORTCUT_WINF <> 'Ctrl+Alt+Y' OR SHORTCUT_WINF IS NULL);
