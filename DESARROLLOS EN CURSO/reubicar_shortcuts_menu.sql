-- =============================================================================
-- Reubicar shortcuts de menú: Empresas, Empleados, Arqueos, Países,
-- Unidades y Efectos
-- =============================================================================
-- Sincroniza fza_winforms con los aceleradores definidos en inMtoPrincipal.dfm.
-- Da un atajo unico a opciones que antes chocaban o no tenian, y resuelve de
-- paso el conflicto de Ctrl+Alt+E moviendo Efectos de pago a Ctrl+Alt+C.
--
-- Cambios (CALL_WINF: antiguo -> nuevo):
--   EfectosCompra:    Ctrl+Alt+E   -> Ctrl+Alt+C   (antes era un valor
--                     huerfano sin atajo real; ahora con ShortCut en el DFM)
--   Empresas:         Ctrl+E       -> Ctrl+Alt+E
--   Empleados:        Ctrl+Alt+E   -> Ctrl+Shift+E
--   CajaArqueosHist:  Ctrl+Shift+A -> Ctrl+Shift+H (Ctrl+Shift+A lo usaba
--                     tambien Albaranes de compra)
--   Paises:           Ctrl+L       -> Ctrl+Alt+L   (Ctrl+L lo usa Almacenes)
--   UnidadesMedida:   (sin atajo)  -> Ctrl+Alt+U
--
-- Idempotente: cada UPDATE solo actua si el valor actual difiere del nuevo;
-- COALESCE cubre los casos NULL o cadena vacía.
-- =============================================================================
-- Efectos de pago: Ctrl+Alt+C.
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+C'
 WHERE CALL_WINF = 'EfectosCompra'
   AND COALESCE(SHORTCUT_WINF, '') <> 'Ctrl+Alt+C';
-- Empresas: Ctrl+Alt+E (libera Ctrl+E para Búsqueda de datos).
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+E'
 WHERE CALL_WINF = 'Empresas'
   AND COALESCE(SHORTCUT_WINF, '') <> 'Ctrl+Alt+E';
-- Empleados: Ctrl+Shift+E.
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Shift+E'
 WHERE CALL_WINF = 'Empleados'
   AND COALESCE(SHORTCUT_WINF, '') <> 'Ctrl+Shift+E';
-- Historico de Arqueos: Ctrl+Shift+H (libera Ctrl+Shift+A de Albaranes compra)
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Shift+H'
 WHERE CALL_WINF = 'CajaArqueosHist'
   AND COALESCE(SHORTCUT_WINF, '') <> 'Ctrl+Shift+H';
-- Paises: Ctrl+Alt+L (libera Ctrl+L de Almacenes)
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+L'
 WHERE CALL_WINF = 'Paises'
   AND COALESCE(SHORTCUT_WINF, '') <> 'Ctrl+Alt+L';
-- Unidades de Medida: Ctrl+Alt+U (antes sin atajo)
UPDATE fza_winforms
   SET SHORTCUT_WINF = 'Ctrl+Alt+U'
 WHERE CALL_WINF = 'UnidadesMedida'
   AND COALESCE(SHORTCUT_WINF, '') <> 'Ctrl+Alt+U';
