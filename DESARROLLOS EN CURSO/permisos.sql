-- =====================================================================
-- Script: permisos.sql
-- Objetivo: tabla de permisos por grupo de usuario.
-- Idempotente: CREATE TABLE IF NOT EXISTS.
--
-- Diseño simple:
--   GRUPO_PERM  = grupo de usuarios (de fza_usuarios_grupos)
--   CODIGO_PERM = clave del permiso (ej. 'exportarExcel', 'borrarRegistro')
--   VALOR_PERM  = 'S' / 'N'
--
-- Resolución: si el grupo del usuario no tiene el permiso definido,
-- se busca en 'Todos'. Si tampoco existe, el default del código decide.
-- Los administradores (ESGRUPOADMINISTRADOR_USUGRP = 'S') siempre 'S'.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `fza_permisos` (
  `GRUPO_PERM`    varchar(50)  NOT NULL COMMENT 'Grupo de usuarios',
  `CODIGO_PERM`   varchar(60)  NOT NULL COMMENT 'Clave del permiso',
  `VALOR_PERM`    varchar(1)   NOT NULL DEFAULT 'S' COMMENT 'S=permitido N=denegado',
  `DESCRIPCION_PERM` varchar(200) NULL DEFAULT NULL COMMENT 'Descripción para el Mto',
  `INSTANTE_MODIF` datetime    DEFAULT NULL,
  `INSTANTE_ALTA`  datetime    NOT NULL,
  `USUARIO_ALTA`   varchar(100) NOT NULL,
  `USUARIO_MODIF`  varchar(100) DEFAULT NULL,
  PRIMARY KEY (`GRUPO_PERM`, `CODIGO_PERM`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- Permisos iniciales para 'Todos' (defaults restrictivos)
-- =====================================================================
INSERT IGNORE INTO fza_permisos
  (GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM, INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'exportarExcel',         'S', 'Exportar grid a Excel',                        NOW(), 'SISTEMA'),
  ('Todos', 'modificarRegistro',     'S', 'Modificar registros en mantenimientos',         NOW(), 'SISTEMA'),
  ('Todos', 'borrarRegistro',        'S', 'Borrar registros en mantenimientos',            NOW(), 'SISTEMA'),
  ('Todos', 'verArqueoResumen',      'N', 'Ver resumen de cantidades en arqueo',           NOW(), 'SISTEMA'),
  ('Todos', 'verArqueoImportes',     'N', 'Ver importes de formas de pago en recuento',    NOW(), 'SISTEMA'),
  ('Todos', 'cambiarFechaOperacion', 'N', 'Cambiar la fecha de operación en caja',         NOW(), 'SISTEMA'),
  ('Todos', 'grabarLayout',          'S', 'Grabar layout de grids (Alt+F12)',              NOW(), 'SISTEMA'),
  ('Todos', 'resetLayout',           'S', 'Resetear layout de grids (Ctrl+F12)',           NOW(), 'SISTEMA'),
  ('Todos', 'crearGuias',            'S', 'Crear guías de grid/informes',                  NOW(), 'SISTEMA');
