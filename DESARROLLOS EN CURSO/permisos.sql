-- =====================================================================
-- Script: permisos.sql
-- Objetivo: tabla de permisos por usuario, grupo y 'Todos' + pantalla.
-- Idempotente: CREATE TABLE IF NOT EXISTS + rename guardado por
--              INFORMATION_SCHEMA + INSERT IGNORE.
--
-- Diseño (paralelo a fza_usuarios_perfiles):
--   USUARIO_GRUPO_PERM = usuario, grupo (de fza_usuarios_grupos) o 'Todos'
--   CODIGO_PERM        = clave del permiso (ej. 'menu.Articulos')
--   VALOR_PERM         = 'S' / 'N'
--
-- Convención de códigos:
--   menu.<CALL_WINF>          -> acceso al item de menú
--   accion.exportarExcel      -> acción global en cualquier Mto
--   accion.modificarRegistro  -> acción global
--   accion.borrarRegistro     -> acción global
--   accion.imprimir           -> acción global
--   arqueo.<permiso>          -> permisos específicos de arqueo
--   caja.<permiso>            -> permisos específicos de caja
--
-- Resolución (inLibPermisos): administradores siempre S; despues usuario,
-- luego grupo, luego 'Todos'.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Tabla. En instalaciones nuevas se crea ya con USUARIO_GRUPO_PERM.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_permisos` (
  `USUARIO_GRUPO_PERM` varchar(200) NOT NULL COMMENT 'Usuario, grupo o Todos',
  `CODIGO_PERM`        varchar(60)  NOT NULL COMMENT 'Clave del permiso',
  `VALOR_PERM`         varchar(1)   NOT NULL DEFAULT 'S' COMMENT 'S=permitido N=denegado',
  `DESCRIPCION_PERM`   varchar(200) NULL DEFAULT NULL COMMENT 'Descripción para el Mto',
  `INSTANTE_MODIF` datetime    DEFAULT NULL,
  `INSTANTE_ALTA`  datetime    NOT NULL,
  `USUARIO_ALTA`   varchar(100) NOT NULL,
  `USUARIO_MODIF`  varchar(100) DEFAULT NULL,
  PRIMARY KEY (`USUARIO_GRUPO_PERM`, `CODIGO_PERM`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Migración de instalaciones existentes: renombrar GRUPO_PERM ->
--    USUARIO_GRUPO_PERM y ensancharla a varchar(200) (cabe cualquier
--    usuario/grupo). CHANGE COLUMN reubica la columna en la PK sola.
--    Sólo se ejecuta si existe la columna vieja y no la nueva.
-- ---------------------------------------------------------------------
SET @col_old := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME  = 'fza_permisos'
                    AND COLUMN_NAME = 'GRUPO_PERM');
SET @col_new := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME  = 'fza_permisos'
                    AND COLUMN_NAME = 'USUARIO_GRUPO_PERM');
SET @ddl := IF(@col_old = 1 AND @col_new = 0,
  'ALTER TABLE `fza_permisos` CHANGE COLUMN `GRUPO_PERM` `USUARIO_GRUPO_PERM` varchar(200) NOT NULL COMMENT ''Usuario, grupo o Todos''',
  'DO 0');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================================
-- 2. Permisos de acceso a menú (uno por cada item de fza_winforms)
--    Por defecto todos permitidos ('S'). Se deniegan por grupo/usuario.
-- =====================================================================
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'menu.Articulos',           'S', 'Artículos',                     NOW(), 'SISTEMA'),
  ('Todos', 'menu.ArticulosPropiedades','S', 'Propiedades de Artículos',      NOW(), 'SISTEMA'),
  ('Todos', 'menu.AtributosBasicos',    'S', 'Atributos básicos',             NOW(), 'SISTEMA'),
  ('Todos', 'menu.AtributosConjuntos',  'S', 'Colecciones de Atributos',      NOW(), 'SISTEMA'),
  ('Todos', 'menu.Familias',            'S', 'Familias',                      NOW(), 'SISTEMA'),
  ('Todos', 'menu.Variaciones',         'S', 'Variaciones',                   NOW(), 'SISTEMA'),
  ('Todos', 'menu.Propiedades',         'S', 'Propiedades',                   NOW(), 'SISTEMA'),
  ('Todos', 'menu.PropiedadesValores',  'S', 'Valores de Propiedades',        NOW(), 'SISTEMA'),
  ('Todos', 'menu.Clientes',            'S', 'Clientes',                      NOW(), 'SISTEMA'),
  ('Todos', 'menu.Proveedores',         'S', 'Proveedores',                   NOW(), 'SISTEMA'),
  ('Todos', 'menu.Empresas',            'S', 'Empresas',                      NOW(), 'SISTEMA'),
  ('Todos', 'menu.Almacenes',           'S', 'Almacenes',                     NOW(), 'SISTEMA'),
  ('Todos', 'menu.Facturas',            'S', 'Facturas',                      NOW(), 'SISTEMA'),
  ('Todos', 'menu.FacturasSimplif',     'S', 'Facturas Simplificadas',        NOW(), 'SISTEMA'),
  ('Todos', 'menu.Albaranes',           'S', 'Albaranes',                     NOW(), 'SISTEMA'),
  ('Todos', 'menu.AlbaranesCompra',     'S', 'Albaranes de Compra',           NOW(), 'SISTEMA'),
  ('Todos', 'menu.Pedidos',             'S', 'Pedidos',                       NOW(), 'SISTEMA'),
  ('Todos', 'menu.ComprasSesiones',     'S', 'Sesiones de Compra',            NOW(), 'SISTEMA'),
  ('Todos', 'menu.ComprasPlantillas',   'S', 'Plantillas de Compra',          NOW(), 'SISTEMA'),
  ('Todos', 'menu.Tarifas',             'S', 'Tarifas',                       NOW(), 'SISTEMA'),
  ('Todos', 'menu.FormasdePago',        'S', 'Formas de Pago',                NOW(), 'SISTEMA'),
  ('Todos', 'menu.Ivas',                'S', 'Impuestos IVA',                 NOW(), 'SISTEMA'),
  ('Todos', 'menu.IvasGrupos',          'S', 'Grupos de IVA',                 NOW(), 'SISTEMA'),
  ('Todos', 'menu.Contadores',          'S', 'Contadores',                    NOW(), 'SISTEMA'),
  ('Todos', 'menu.Paises',              'S', 'Países',                        NOW(), 'SISTEMA'),
  ('Todos', 'menu.Usuarios',            'S', 'Usuarios',                      NOW(), 'SISTEMA'),
  ('Todos', 'menu.Grupos',              'S', 'Grupos de Usuarios',            NOW(), 'SISTEMA'),
  ('Todos', 'menu.UsuariosPerfiles',    'S', 'Perfiles de Usuarios',          NOW(), 'SISTEMA'),
  ('Todos', 'menu.Permisos',            'S', 'Permisos',                      NOW(), 'SISTEMA'),
  ('Todos', 'menu.Inventarios',         'S', 'Inventarios',                   NOW(), 'SISTEMA'),
  ('Todos', 'menu.MovimientosAlmacen',  'S', 'Movimientos de Almacén',        NOW(), 'SISTEMA'),
  ('Todos', 'menu.DepositosCliente',    'S', 'Depósitos de Clientes',         NOW(), 'SISTEMA'),
  ('Todos', 'menu.GeneradorProcesos',   'S', 'Generador de Procesos',         NOW(), 'SISTEMA'),
  ('Todos', 'menu.MenuCaja',            'S', 'Menú de Caja',                  NOW(), 'SISTEMA'),
  ('Todos', 'menu.CajaFormasPago',      'S', 'Formas de Pago Caja',           NOW(), 'SISTEMA'),
  ('Todos', 'menu.CajaOperacionesHist', 'S', 'Histórico Operaciones Caja',    NOW(), 'SISTEMA'),
  ('Todos', 'menu.CajaPagosHist',       'S', 'Histórico Pagos Caja',          NOW(), 'SISTEMA'),
  ('Todos', 'menu.CajaValesHist',       'S', 'Histórico Vales',               NOW(), 'SISTEMA'),
  ('Todos', 'menu.CajaArqueosHist',     'S', 'Histórico Arqueos',             NOW(), 'SISTEMA');

-- =====================================================================
-- 3. Acciones globales en mantenimientos
-- =====================================================================
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'accion.exportarExcel',      'S', 'Exportar grid a Excel',                    NOW(), 'SISTEMA'),
  ('Todos', 'accion.modificarRegistro',  'S', 'Modificar registros',                      NOW(), 'SISTEMA'),
  ('Todos', 'accion.borrarRegistro',     'S', 'Borrar registros',                          NOW(), 'SISTEMA'),
  ('Todos', 'accion.insertarRegistro',   'S', 'Insertar registros nuevos',                 NOW(), 'SISTEMA'),
  ('Todos', 'accion.imprimir',           'S', 'Imprimir informes',                         NOW(), 'SISTEMA'),
  ('Todos', 'accion.grabarLayout',       'S', 'Guardar layout (Alt+F12)',                  NOW(), 'SISTEMA'),
  ('Todos', 'accion.resetLayout',        'S', 'Resetear layout (Ctrl+F12)',                NOW(), 'SISTEMA'),
  ('Todos', 'accion.crearGuias',         'S', 'Crear guías de grid/informes',              NOW(), 'SISTEMA');

-- =====================================================================
-- 4. Permisos de arqueo
-- =====================================================================
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'arqueo.verResumen',         'N', 'Ver resumen de cantidades en arqueo',       NOW(), 'SISTEMA'),
  ('Todos', 'arqueo.verImportes',        'N', 'Ver importes pre-rellenados en recuento',   NOW(), 'SISTEMA'),
  ('Todos', 'arqueo.grabar',             'S', 'Grabar cierre de arqueo',                   NOW(), 'SISTEMA');

-- =====================================================================
-- 5. Permisos de caja
-- =====================================================================
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'caja.cambiarFecha',         'N', 'Cambiar fecha de operación en caja',        NOW(), 'SISTEMA'),
  ('Todos', 'caja.anularOperacion',      'S', 'Anular una operación de caja',              NOW(), 'SISTEMA'),
  ('Todos', 'caja.devolverArticulo',     'S', 'Realizar devolución de artículo',           NOW(), 'SISTEMA'),
  ('Todos', 'caja.abrirCajon',           'S', 'Abrir cajón sin venta (F9)',                NOW(), 'SISTEMA'),
  ('Todos', 'caja.entradaCambio',        'S', 'Realizar entrada de cambio',                NOW(), 'SISTEMA'),
  ('Todos', 'caja.gastoCaja',            'S', 'Registrar gasto de caja',                   NOW(), 'SISTEMA'),
  ('Todos', 'caja.verCoste',             'S', 'Ver coste/importe en traspasos y caja',     NOW(), 'SISTEMA');

-- Refresca la descripcion de caja.abrirCajon para reflejar el atajo F9 en
-- instalaciones que ya tuvieran la fila (INSERT IGNORE no actualiza filas).
UPDATE fza_permisos
   SET DESCRIPCION_PERM = 'Abrir cajón sin venta (F9)'
 WHERE CODIGO_PERM      = 'caja.abrirCajon'
   AND DESCRIPCION_PERM = 'Abrir cajón sin venta';

-- =====================================================================
-- 6. Alta de la pantalla de Permisos en el menú (fza_winforms).
--    Reutiliza el data module ya existente UniDataPermisosGrupo.
-- =====================================================================
INSERT IGNORE INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF, SHORTCUT_WINF,
   DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  -- SHORTCUT_WINF vacío a propósito: el atajo Ctrl+Q de Permisos se define
  -- en el menú principal (mnuPermisos.ShortCut). No se registra aquí para no
  -- chocar con 'FormasdePago' (Ctrl+Q) en el OnShortCut del TPV de Caja.
  ('Permisos', 'Permisos', 'mnuPermisos',
   'inMtoPermisos.TfrmMtoPermisos', '',
   'UniDataPermisosGrupo.TdmPermisosGrupo', 1);
