-- =============================================================================
-- Registro de TfrmMtoFacturasSimplif en fza_winforms (paso 3/4 del refactor)
-- =============================================================================
-- Anade la entrada que ShowMto resuelve al hacer click en
-- 'Caja -> Facturas Simplificadas' (Ctrl+Alt+F). La pantalla consulta
-- vi_facturas_simplificadas, asi que su contenido lo filtra el motor de BD.
--
-- Comparte DataModule (UniDataFacturas.TdmFacturas) con FacturasNormal
-- para no duplicar codigo de DataModule.
--
-- Idempotente: ON DUPLICATE KEY UPDATE refresca los campos clave.
-- =============================================================================

INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('FacturasSimplif',
   'Facturas Simplificadas',
   'mnuFacturasSimplif',
   'inMtoFacturasSimplif.TfrmMtoFacturasSimplif',
   'Ctrl+Alt+F',
   'UniDataFacturas.TdmFacturas',
   5)
ON DUPLICATE KEY UPDATE
  CAPTION_WINF      = VALUES(CAPTION_WINF),
  MENUITEM_WINF     = VALUES(MENUITEM_WINF),
  UNITF_WINF        = VALUES(UNITF_WINF),
  SHORTCUT_WINF     = VALUES(SHORTCUT_WINF),
  DATAMODULE_WINF   = VALUES(DATAMODULE_WINF),
  NUM_VENTANAS_WINF = VALUES(NUM_VENTANAS_WINF);
