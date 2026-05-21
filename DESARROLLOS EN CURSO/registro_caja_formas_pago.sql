-- =============================================================================
-- Registro de TfrmMtoCajaFormasPago en fza_winforms
-- =============================================================================
-- Anade la entrada que ShowMto resuelve al hacer click en
-- 'Caja -> Formas de Pago Caja' (Ctrl+Shift+Q). La pantalla mantiene la
-- tabla fza_caja_formas_pago, que define los botones de la fase de cobro
-- (F12): efectivo, tarjeta, divisa, cripto, bono... con sus flags de
-- comportamiento (cajon, cambio, referencia obligatoria, comision, etc).
--
-- Se usa Ctrl+Shift+ para los items del menu Caja por convencion del
-- proyecto. Q es libre (Ctrl+Q queda para FormasdePago de venta).
--
-- Idempotente: ON DUPLICATE KEY UPDATE refresca los campos clave.
-- =============================================================================

INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('CajaFormasPago',
   'Formas de Pago Caja',
   'FormasdePagoCaja1',
   'inMtoCajaFormasPago.TfrmMtoCajaFormasPago',
   'Ctrl+Shift+Q',
   'UniDataCajaFormasPago.TdmCajaFormasPago',
   5)
ON DUPLICATE KEY UPDATE
  CAPTION_WINF      = VALUES(CAPTION_WINF),
  MENUITEM_WINF     = VALUES(MENUITEM_WINF),
  UNITF_WINF        = VALUES(UNITF_WINF),
  SHORTCUT_WINF     = VALUES(SHORTCUT_WINF),
  DATAMODULE_WINF   = VALUES(DATAMODULE_WINF),
  NUM_VENTANAS_WINF = VALUES(NUM_VENTANAS_WINF);
