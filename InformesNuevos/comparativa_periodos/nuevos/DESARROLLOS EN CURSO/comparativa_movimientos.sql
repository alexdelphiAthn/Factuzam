-- =============================================================================
-- Informes > Comparativa de periodos: registro de pantalla y permiso
-- =============================================================================
-- Nuevo menu principal 'Informes' (inMtoPrincipal) con un item:
--   1. Comparativa de periodos -> inMtoComparativaMovimientos
--      (cuadro de mando interanual sobre fza_movimientos_almacen y
--       fza_facturas). No tiene data module propio: usa la conexion
--       global oConn con consultas bajo demanda, por eso DATAMODULE_WINF
--       queda vacio.
--
-- Sigue el patron de verifactu_menu.sql: la pantalla se resuelve via
-- ShowMto + fza_winforms, y el permiso de menu cuelga de fza_permisos
-- (codigo 'menu.<CALL>').
--
-- Idempotente: ON DUPLICATE KEY UPDATE / INSERT IGNORE.
-- =============================================================================
INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('ComparativaMovimientos',
   'Comparativa de periodos',
   'mnuComparativaMovimientos',
   'inMtoComparativaMovimientos.TfrmMtoComparativaMovimientos',
   '',
   '',
   1)
ON DUPLICATE KEY UPDATE
  CAPTION_WINF      = VALUES(CAPTION_WINF),
  MENUITEM_WINF     = VALUES(MENUITEM_WINF),
  UNITF_WINF        = VALUES(UNITF_WINF),
  SHORTCUT_WINF     = VALUES(SHORTCUT_WINF),
  DATAMODULE_WINF   = VALUES(DATAMODULE_WINF),
  NUM_VENTANAS_WINF = VALUES(NUM_VENTANAS_WINF);
-- Permiso de menu (por defecto visible para Todos; TienePermiso devuelve
-- True si la fila no existe, la fila deja el permiso gobernable desde el
-- mantenimiento de permisos)
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM,
   INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'menu.ComparativaMovimientos', 'S',
   'Informes: Comparativa de periodos', NOW(), 'SISTEMA');
