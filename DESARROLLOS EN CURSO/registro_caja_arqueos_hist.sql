-- =============================================================================
-- Registro de TfrmMtoCajaArqueosHist en fza_winforms
-- =============================================================================
-- Añade la entrada que ShowMto resuelve al hacer click en
-- 'Caja -> Histórico de Arqueos' (Ctrl+Shift+A). La pantalla muestra
-- los arqueos grabados (cierres Z) con columnas de recuento, diferencia,
-- y permite exportar a Excel.
--
-- Se usa Ctrl+Shift+A (A de Arqueo, libre en el menú Caja).
--
-- Idempotente: ON DUPLICATE KEY UPDATE refresca los campos clave.
-- =============================================================================

INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('CajaArqueosHist',
   'Histórico de Arqueos de Caja',
   'mnuCajaArqueosHist',
   'inMtoCajaArqueosHist.TfrmMtoCajaArqueosHist',
   'Ctrl+Shift+A',
   'UniDataCajaArqueosHist.TdmCajaArqueosHist',
   5)
ON DUPLICATE KEY UPDATE
  CAPTION_WINF      = VALUES(CAPTION_WINF),
  MENUITEM_WINF     = VALUES(MENUITEM_WINF),
  UNITF_WINF        = VALUES(UNITF_WINF),
  SHORTCUT_WINF     = VALUES(SHORTCUT_WINF),
  DATAMODULE_WINF   = VALUES(DATAMODULE_WINF),
  NUM_VENTANAS_WINF = VALUES(NUM_VENTANAS_WINF);
