-- ============================================================================
-- Sesiones de compra — promocion del form de "prueba" a definitivo
--
-- El form inMtoPruebaSesionGrid / TfrmMtoPruebaSesionGrid + winform
-- "PruebaSesionGrid" pasa a ser el Mto definitivo de Sesiones de compra:
--
--   - Unit:   inMtoComprasSesiones  (ubicado en src/Forms/)
--   - Clase:  TfrmMtoComprasSesiones
--   - Winform:CALL_WINF = 'ComprasSesiones'
--
-- Este script reescribe la entrada de fza_winforms para reflejar los
-- nombres nuevos. Idempotente: INSERT del nuevo + DELETE del antiguo,
-- ambos pasos envueltos en checks de existencia.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Alta del nuevo CALL_WINF = 'ComprasSesiones'
-- ---------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`,
   `UNITF_WINF`, `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('ComprasSesiones',
   'Crear articulos y un pedido o un albaran',
   NULL,
   'inMtoComprasSesiones.TfrmMtoComprasSesiones',
   'Ctrl+Shift+S',
   'UniDataComprasSesiones.TdmComprasSesiones',
   1)
ON DUPLICATE KEY UPDATE
  `CAPTION_WINF`     = VALUES(`CAPTION_WINF`),
  `UNITF_WINF`       = VALUES(`UNITF_WINF`),
  `SHORTCUT_WINF`    = VALUES(`SHORTCUT_WINF`),
  `DATAMODULE_WINF`  = VALUES(`DATAMODULE_WINF`),
  `NUM_VENTANAS_WINF`= VALUES(`NUM_VENTANAS_WINF`);

-- ---------------------------------------------------------------------------
-- 2. Baja del antiguo CALL_WINF = 'PruebaSesionGrid' (si todavia existe)
-- ---------------------------------------------------------------------------
DELETE FROM `fza_winforms`
 WHERE `CALL_WINF` = 'PruebaSesionGrid';
