-- ============================================================================
-- Migración: nuevos mantenimientos auxiliares + reasignación de shortcut M/W
-- Fecha:   2026-05-09
-- PR:      #55  (rama claude/add-maintenance-modules-UMScB)
--
-- Aplica este script DESPUÉS de actualizar el ejecutable a la versión que
-- incluye los nuevos forms inMtoVariaciones, inMtoAtributosConjuntos,
-- inMtoMovimientosAlmacen, inMtoDepositosCliente, inMtoCajaPagosHist,
-- inMtoCajaValesHist, inMtoCajaOperacionesHist, inMtoPropiedades,
-- inMtoPropiedadesValores.
--
-- No toca el esquema (las tablas fza_propiedades / fza_propiedades_valores
-- ya estaban definidas en tu BBDD; el resto de tablas que usan los nuevos
-- forms también existen).
-- ============================================================================

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Reasignación: Ctrl+M ahora es Movimientos de Almacén
--    (UsuariosPerfiles libera Ctrl+M y pasa a Ctrl+W)
-- ----------------------------------------------------------------------------
UPDATE `fza_winforms`
   SET `SHORTCUT_WINF` = 'Ctrl+W'
 WHERE `CALL_WINF` = 'UsuariosPerfiles';

-- ----------------------------------------------------------------------------
-- 2. Alta de los nuevos mantenimientos en fza_winforms
--    (REPLACE para que sea idempotente: si ya existían, los reemplaza)
-- ----------------------------------------------------------------------------
REPLACE INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`, `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('Variaciones',         'Tipos de Variaciones',             'mnuVariaciones',         'inMtoVariaciones.TfrmMtoVariaciones',                  'Ctrl+Alt+T', 'UniDataVariaciones.TdmVariaciones',                  1),
  ('AtributosConjuntos',  'Colecciones de Atributos',         'mnuAtributosConjuntos',  'inMtoAtributosConjuntos.TfrmMtoAtributosConjuntos',    'Ctrl+S',     'UniDataAtributosConjuntos.TdmAtributosConjuntos',    1),
  ('MovimientosAlmacen',  'Movimientos de Almacén',           'Movimientosdealmacn1',   'inMtoMovimientosAlmacen.TfrmMtoMovimientosAlmacen',    'Ctrl+M',     'UniDataMovimientosAlmacen.TdmMovimientosAlmacen',    1),
  ('DepositosCliente',    'Depósitos de Clientes',            'mnuDepositosCliente',    'inMtoDepositosCliente.TfrmMtoDepositosCliente',        'Ctrl+D',     'UniDataDepositosCliente.TdmDepositosCliente',        1),
  ('CajaPagosHist',       'Histórico de Pagos de Caja',       'mnuCajaPagosHist',       'inMtoCajaPagosHist.TfrmMtoCajaPagosHist',              'Ctrl+Alt+P', 'UniDataCajaPagosHist.TdmCajaPagosHist',              1),
  ('CajaValesHist',       'Histórico de Vales',               'mnuCajaValesHist',       'inMtoCajaValesHist.TfrmMtoCajaValesHist',              'Ctrl+Alt+L', 'UniDataCajaValesHist.TdmCajaValesHist',              1),
  ('CajaOperacionesHist', 'Histórico de Operaciones de Caja', 'mnuCajaOperacionesHist', 'inMtoCajaOperacionesHist.TfrmMtoCajaOperacionesHist',  'Ctrl+Alt+O', 'UniDataCajaOperacionesHist.TdmCajaOperacionesHist',  1),
  ('Propiedades',         'Propiedades',                      'mnuPropiedades',         'inMtoPropiedades.TfrmMtoPropiedades',                  'Ctrl+Y',     'UniDataPropiedades.TdmPropiedades',                  1),
  ('PropiedadesValores',  'Valores de Propiedades',           'mnuPropiedadesValores',  'inMtoPropiedadesValores.TfrmMtoPropiedadesValores',    'Ctrl+Alt+Y', 'UniDataPropiedadesValores.TdmPropiedadesValores',    1);

-- ----------------------------------------------------------------------------
-- 3. Verificación rápida
-- ----------------------------------------------------------------------------
SELECT CALL_WINF, CAPTION_WINF, SHORTCUT_WINF
  FROM fza_winforms
 WHERE CALL_WINF IN ('UsuariosPerfiles','Variaciones','AtributosConjuntos','MovimientosAlmacen',
                     'DepositosCliente','CajaPagosHist','CajaValesHist','CajaOperacionesHist',
                     'Propiedades','PropiedadesValores')
 ORDER BY CALL_WINF;

COMMIT;
