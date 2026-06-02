-- =====================================================================
-- Script: permisos_arbol.sql
-- Objetivo: pantalla profesional de permisos en arbol (inMtoPermisosArbol).
--           Repunta la entrada 'Permisos' del menu a la nueva pantalla y
--           conserva la rejilla clasica como 'Permisos (tabla)'.
-- Idempotente: INSERT IGNORE + UPDATE (mismos valores al relanzar).
--
-- No cambia el esquema: la tabla fza_permisos ya existe (ver permisos.sql).
-- Aplicar despues de permisos.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Rejilla clasica como entrada separada del menu (mnuPermisosTabla).
--    Mantiene su data module (UniDataPermisosGrupo) para edicion directa.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF, SHORTCUT_WINF,
   DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('PermisosTabla', 'Permisos (tabla)', 'mnuPermisosTabla',
   'inMtoPermisos.TfrmMtoPermisos', '',
   'UniDataPermisosGrupo.TdmPermisosGrupo', 1);

-- ---------------------------------------------------------------------
-- 2. Repuntar 'Permisos' a la pantalla de arbol. DATAMODULE vacio a
--    proposito: la pantalla no usa data module (gestiona el arbol y las
--    consultas en codigo). Reusa el item de menu mnuPermisos y, por
--    tanto, el permiso menu.Permisos ya existente.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF, SHORTCUT_WINF,
   DATAMODULE_WINF, NUM_VENTANAS_WINF)
VALUES
  ('Permisos', 'Gestión de Permisos', 'mnuPermisos',
   'inMtoPermisosArbol.TfrmMtoPermisosArbol', '', '', 1);

UPDATE fza_winforms
   SET CAPTION_WINF    = 'Gestión de Permisos',
       MENUITEM_WINF   = 'mnuPermisos',
       UNITF_WINF      = 'inMtoPermisosArbol.TfrmMtoPermisosArbol',
       DATAMODULE_WINF = ''
 WHERE CALL_WINF = 'Permisos';

-- ---------------------------------------------------------------------
-- 3. Permiso de menu para la rejilla clasica. La pantalla de arbol
--    reutiliza menu.Permisos, que ya esta dado de alta en permisos.sql.
-- ---------------------------------------------------------------------
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM,
   INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'menu.PermisosTabla', 'S', 'Permisos (tabla)', NOW(), 'SISTEMA');
