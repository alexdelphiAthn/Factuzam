-- =============================================================================
-- Menu Verifactu: registro de pantallas y permisos
-- =============================================================================
-- Nuevo menu principal 'Verifactu' (inMtoPrincipal) con tres items:
--   1. Declaracion Responsable -> modal inMtoModalVerifactuDecl (sin
--      registro en fza_winforms: no es un Mto, solo muestra texto).
--   2. Cola de Envios          -> inMtoVerifactuCola (fza_verifactu_cola)
--   3. Verifactu Log           -> inMtoVerifactuLog (fza_verifactu_eventos)
--
-- Sigue el patron de registro_facturas_simplif.sql: las pantallas se
-- resuelven via ShowMto + fza_winforms, y los permisos de menu cuelgan
-- de fza_permisos (codigo 'menu.<CALL>'; el modal usa 'menu.<Name>').
--
-- Idempotente: ON DUPLICATE KEY UPDATE / INSERT IGNORE.
-- =============================================================================

INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('VerifactuCola',
   'Verifactu - Cola de Envíos',
   'mnuVerifactuCola',
   'inMtoVerifactuCola.TfrmMtoVerifactuCola',
   '',
   'UniDataVerifactuCola.TdmVerifactuCola',
   5)
ON DUPLICATE KEY UPDATE
  CAPTION_WINF      = VALUES(CAPTION_WINF),
  MENUITEM_WINF     = VALUES(MENUITEM_WINF),
  UNITF_WINF        = VALUES(UNITF_WINF),
  SHORTCUT_WINF     = VALUES(SHORTCUT_WINF),
  DATAMODULE_WINF   = VALUES(DATAMODULE_WINF),
  NUM_VENTANAS_WINF = VALUES(NUM_VENTANAS_WINF);

INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('VerifactuLog',
   'Verifactu - Log',
   'mnuVerifactuLog',
   'inMtoVerifactuLog.TfrmMtoVerifactuLog',
   '',
   'UniDataVerifactuLog.TdmVerifactuLog',
   5)
ON DUPLICATE KEY UPDATE
  CAPTION_WINF      = VALUES(CAPTION_WINF),
  MENUITEM_WINF     = VALUES(MENUITEM_WINF),
  UNITF_WINF        = VALUES(UNITF_WINF),
  SHORTCUT_WINF     = VALUES(SHORTCUT_WINF),
  DATAMODULE_WINF   = VALUES(DATAMODULE_WINF),
  NUM_VENTANAS_WINF = VALUES(NUM_VENTANAS_WINF);

-- Permisos de menu (por defecto visibles para Todos; TienePermiso ya
-- devuelve True si la fila no existe, las filas dejan el permiso
-- gobernable desde el mantenimiento de permisos)
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM,
   INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'menu.mnuVerifactuDeclaracion', 'S',
   'Verifactu: Declaración Responsable', NOW(), 'SISTEMA'),
  ('Todos', 'menu.VerifactuCola', 'S',
   'Verifactu: Cola de Envíos', NOW(), 'SISTEMA'),
  ('Todos', 'menu.VerifactuLog', 'S',
   'Verifactu: Log de eventos', NOW(), 'SISTEMA');
