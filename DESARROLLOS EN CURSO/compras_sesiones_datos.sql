-- ============================================================================
-- Módulo Compras → Sesiones — datos de configuración (post-DDL)
--
-- Idempotente: se puede ejecutar tantas veces como haga falta sin destruir
-- nada ni duplicar filas.
--
-- Aplicar DESPUÉS de compras_sesiones.sql (el DDL del esquema).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Contadores de Sesiones de Compra
-- ---------------------------------------------------------------------------
-- TIPO_DOC_CON = 'SE' (varchar(2)) — la app llama PRC_GET_CONTADOR con 'SE'.
--
-- Las series se crean en Mantenimiento > Empresas > pestaña "4_Series"
-- añadiendo filas en fza_empresas_series con TIPO_DOC_EMPSER='SE'. Cada
-- combinación (EMPRESA, SERIE) tiene su propio contador en fza_contadores.
--
-- El contador correspondiente se crea bajo demanda (la primera vez que se
-- pide el siguiente número). Como referencia/seed se inserta una fila
-- global ('SE', '-', '-') que el SP puede usar de fallback si la
-- (EMPRESA, SERIE) concreta aún no tiene entrada propia.
INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, `NUM_DIGITOS_CON`,
   `ESACTIVO_CON`, `DEFAULT_CON`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  ('SE', '-', '-', 0, 6, 'S', 'S',
   NOW(), 'Administrador', 'Administrador')
ON DUPLICATE KEY UPDATE
  `ESACTIVO_CON` = VALUES(`ESACTIVO_CON`),
  `INSTANTE_MODIF` = NOW(),
  `USUARIO_MODIF` = 'Administrador';

-- ---------------------------------------------------------------------------
-- 2. Registro de ventanas en fza_winforms
-- ---------------------------------------------------------------------------
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('ComprasSesiones', 'Sesiones de Compra', 'Sesiones1',
   'inMtoComprasSesiones.TfrmMtoComprasSesiones', 'Ctrl+S',
   'UniDataComprasSesiones.TdmComprasSesiones', 99),
  ('ComprasPlantillas', 'Plantillas de Compra', 'mnuComprasPlantillas',
   'inMtoComprasPlantillas.TfrmMtoComprasPlantillas', '',
   'UniDataComprasSesiones.TdmComprasSesiones', 1)
ON DUPLICATE KEY UPDATE
  `CAPTION_WINF`      = VALUES(`CAPTION_WINF`),
  `MENUITEM_WINF`     = VALUES(`MENUITEM_WINF`),
  `UNITF_WINF`        = VALUES(`UNITF_WINF`),
  `SHORTCUT_WINF`     = VALUES(`SHORTCUT_WINF`),
  `DATAMODULE_WINF`   = VALUES(`DATAMODULE_WINF`),
  `NUM_VENTANAS_WINF` = VALUES(`NUM_VENTANAS_WINF`);

-- Reasignar el atajo Ctrl+S de AtributosConjuntos a Ctrl+Alt+S para que
-- Sesiones de Compra pueda usar Ctrl+S sin colisión.
UPDATE `fza_winforms`
   SET `SHORTCUT_WINF` = 'Ctrl+Alt+S'
 WHERE `CALL_WINF` = 'AtributosConjuntos'
   AND `SHORTCUT_WINF` = 'Ctrl+S';

-- ---------------------------------------------------------------------------
-- 3. Etiquetas visibles del eje pivot (parametrizable por dominio)
-- ---------------------------------------------------------------------------
-- El campo NOMBRE_VISIBLE_VA se añade en compras_sesiones.sql; aquí solo
-- cargamos los valores por defecto. Si la app ya está en producción y
-- estos valores tienen otro significado, ajústalos a mano.
UPDATE `fza_variaciones_atributos`
   SET `NOMBRE_VISIBLE_VA` = 'Sistema de tallas'
 WHERE `ID_ATB_VA` = 'TAL'
   AND (`NOMBRE_VISIBLE_VA` IS NULL OR `NOMBRE_VISIBLE_VA` = '');

UPDATE `fza_variaciones_atributos`
   SET `NOMBRE_VISIBLE_VA` = 'Paleta'
 WHERE `ID_ATB_VA` = 'CO'
   AND (`NOMBRE_VISIBLE_VA` IS NULL OR `NOMBRE_VISIBLE_VA` = '');

-- ---------------------------------------------------------------------------
-- 4. Inicializar PAD_ART_FAM y CONTADOR_ART_FAM en familias ya existentes
-- ---------------------------------------------------------------------------
-- Las columnas se anaden via ALTER en compras_sesiones.sql con DEFAULT 0/5,
-- pero MySQL no aplica el DEFAULT a filas existentes; quedan en NULL para
-- los registros que ya estaban en la tabla antes de la migracion. Eso hace
-- que el TcxDBSpinEdit muestre vacio y no permita editar bien.
-- Los inicializamos a 0 y 5 respectivamente.

UPDATE `fza_articulos_familias`
   SET `CONTADOR_ART_FAM` = 0
 WHERE `CONTADOR_ART_FAM` IS NULL;

UPDATE `fza_articulos_familias`
   SET `PAD_ART_FAM` = 5
 WHERE `PAD_ART_FAM` IS NULL OR `PAD_ART_FAM` = 0;

UPDATE `fza_articulos_familias`
   SET `ESCONTADOR_ART_FAM` = 'N'
 WHERE `ESCONTADOR_ART_FAM` IS NULL OR `ESCONTADOR_ART_FAM` = '';

-- ---------------------------------------------------------------------------
-- Listo. Reabrir Factuzam para que cargue los nuevos winforms.
-- ---------------------------------------------------------------------------
