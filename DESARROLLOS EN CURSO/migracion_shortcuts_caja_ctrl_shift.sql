-- =============================================================================
-- Migracion: shortcuts de Caja a Ctrl+Shift+ (convencion del proyecto)
-- =============================================================================
-- Los items del menu Caja con letra se migran de Ctrl+Alt+X a Ctrl+Shift+X
-- para liberar Ctrl+Alt+ (usado por el sistema de fotos y otros plugins)
-- y unificar la convencion. F5 y Ctrl+D se mantienen por hábito muscular.
--
-- Cambios:
--   CajaPagosHist:        Ctrl+Alt+P -> Ctrl+Shift+P
--   CajaValesHist:        Ctrl+Alt+L -> Ctrl+Shift+V   (V de Vales)
--   CajaOperacionesHist:  Ctrl+Alt+O -> Ctrl+Shift+O
--
-- Idempotente: solo actualiza si encuentra el valor antiguo.
-- =============================================================================

UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Shift+P'
 WHERE CALL_WINF     = 'CajaPagosHist'
   AND SHORTCUT_WINF = 'Ctrl+Alt+P';

UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Shift+V'
 WHERE CALL_WINF     = 'CajaValesHist'
   AND SHORTCUT_WINF = 'Ctrl+Alt+L';

UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Shift+O'
 WHERE CALL_WINF     = 'CajaOperacionesHist'
   AND SHORTCUT_WINF = 'Ctrl+Alt+O';
