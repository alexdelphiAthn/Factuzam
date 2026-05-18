-- ============================================================================
-- Pruebas — Sesiones de creación de artículos: Prueba 01 (grid plano)
--
-- Reutiliza por completo las tablas fza_compras_sesiones* del módulo
-- principal (ver DESARROLLOS EN CURSO/compras_sesiones.sql). Lo único
-- que esta prueba aporta al esquema:
--
--   1. Dos columnas nuevas en fza_compras_sesiones_lineas para almacenar
--      el atributo no-pivot "color" (texto libre + FK lógica al ATB
--      básico). Se denormaliza por simplicidad de la prueba; en
--      producción se moverá a tabla hija si crece el número de atributos.
--
--   2. Una entrada en fza_winforms para que TfrmMtoPruebaSesionGrid se
--      pueda invocar con ShowMto y resuelva su DataModule a
--      TdmComprasSesiones (el mismo del Mto real).
--
-- Idempotente: pasa el chequeo INFORMATION_SCHEMA antes de ALTER.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna COLOR_TEXTO_SESLIN — atributo no-pivot, texto libre
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_lineas'
     AND COLUMN_NAME  = 'COLOR_TEXTO_SESLIN'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_lineas` '
  'ADD COLUMN `COLOR_TEXTO_SESLIN` varchar(100) DEFAULT NULL '
  '  COMMENT ''Texto libre del color/atributo no-pivot de la linea '
  '(p. ej. AZUL TURQUESA PROV-XYZ). Para la prueba 01 del grid plano.''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Columna CODIGO_ATB_COLOR_SESLIN — codigo del basico (ATB) elegido
-- ---------------------------------------------------------------------------
-- Se guarda el CODIGO_ATB (varchar) en lugar del ID_ATB (int) porque el
-- selector reutilizado de inventarios (SeleccionarAvConPaleta de
-- inLibAtributosPaleta) trabaja con codigos: el usuario ve y elige
-- 'NEGRO', 'AZUL', 'AZUL_MARINO'... y la cache de paleta resuelve el
-- color HEX por (ID_VA_ATB='CO', CODIGO_ATB).
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_lineas'
     AND COLUMN_NAME  = 'CODIGO_ATB_COLOR_SESLIN'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_lineas` '
  'ADD COLUMN `CODIGO_ATB_COLOR_SESLIN` varchar(100) DEFAULT NULL '
  '  COMMENT ''CODIGO_ATB del color basico asociado a la linea '
  '(ID_VA_ATB=''''CO''''). NULL = sin mapeo.''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Indice por CODIGO_ATB_COLOR para futuras agregaciones por color basico.
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_lineas'
     AND INDEX_NAME   = 'IDX_SESLIN_ATB_COLOR'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_lineas` '
  'ADD INDEX `IDX_SESLIN_ATB_COLOR` (`CODIGO_ATB_COLOR_SESLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 3. Registro de la ventana en fza_winforms
-- ---------------------------------------------------------------------------
-- ShowMto(Self, 'PruebaSesionGrid') resuelve aqui. Reutiliza el mismo
-- DataModule que el Mto real (TdmComprasSesiones).
INSERT INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`,
   `UNITF_WINF`, `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('PruebaSesionGrid',
   'Prueba 01 - Sesion grid plano',
   NULL,
   'inMtoPruebaSesionGrid.TfrmMtoPruebaSesionGrid',
   'Ctrl+Shift+S',
   'UniDataComprasSesiones.TdmComprasSesiones',
   1)
ON DUPLICATE KEY UPDATE
  `CAPTION_WINF`     = VALUES(`CAPTION_WINF`),
  `UNITF_WINF`       = VALUES(`UNITF_WINF`),
  `SHORTCUT_WINF`    = VALUES(`SHORTCUT_WINF`),
  `DATAMODULE_WINF`  = VALUES(`DATAMODULE_WINF`),
  `NUM_VENTANAS_WINF`= VALUES(`NUM_VENTANAS_WINF`);
