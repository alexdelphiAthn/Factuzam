-- ============================================================================
-- limpiar_winform_articulospropiedades.sql
-- ----------------------------------------------------------------------------
-- Quita la fila huerfana 'ArticulosPropiedades' de fza_winforms y sus
-- permisos de menu asociados.
--
-- Motivo: esa fila apunta a
--   UNITF_WINF      = inMtoArticulosPropiedades.TfrmMtoArticulosPropiedades
--   DATAMODULE_WINF = UniDataArticulosPropiedades.TdmArticulosPropiedades
-- unidades que YA NO EXISTEN en el codigo (la funcionalidad de propiedades
-- de articulo son ahora los modales TfrmSelPropiedades / TfrmPropPorUnidad
-- de inLibArticulosPropiedades). Ademas su item de menu
-- 'mnuArticulosPropiedades' tampoco esta en inMtoPrincipal.dfm ni tiene
-- handler: es metadato muerto. El validador de arranque nuevo
-- (TfzaWinF.ComprobarRegistradas) la marca con ERROR en cada arranque.
--
-- Al borrarla no se pierde ninguna funcionalidad: no hay menu, ni atajo
-- activo, ni pantalla real detras.
--
-- Idempotente (el segundo pase no hace nada). NO tocar factuzam_original.sql.
-- ============================================================================

-- 1) Comprobacion previa: mira que se va a borrar antes de lanzar los DELETE.
SELECT 'winform a borrar' AS que, w.CALL_WINF, w.CAPTION_WINF,
       w.MENUITEM_WINF, w.UNITF_WINF, w.DATAMODULE_WINF
  FROM fza_winforms w
 WHERE w.CALL_WINF = 'ArticulosPropiedades';

SELECT 'permiso a borrar' AS que, p.USUARIO_GRUPO_PERM,
       p.CODIGO_PERM, p.VALOR_PERM
  FROM fza_permisos p
 WHERE p.CODIGO_PERM = 'menu.ArticulosPropiedades';

-- 2) Borrado (idempotente).
DELETE FROM fza_winforms
 WHERE CALL_WINF = 'ArticulosPropiedades';

DELETE FROM fza_permisos
 WHERE CODIGO_PERM = 'menu.ArticulosPropiedades';

-- 3) Verificacion: las dos consultas deben devolver 0.
SELECT COUNT(*) AS winforms_restantes
  FROM fza_winforms
 WHERE CALL_WINF = 'ArticulosPropiedades';

SELECT COUNT(*) AS permisos_restantes
  FROM fza_permisos
 WHERE CODIGO_PERM = 'menu.ArticulosPropiedades';

-- ============================================================================
-- ROLLBACK (solo si necesitas restaurar la fila; normalmente NO hace falta).
-- Los valores son los que tenia la demo; en tu BBDD los permisos por grupo
-- pueden variar, ajusta los USUARIO_GRUPO_PERM / VALOR_PERM a los tuyos.
-- ----------------------------------------------------------------------------
-- INSERT INTO fza_winforms
--   (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
--    SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF)
--   VALUES ('ArticulosPropiedades', 'Propiedades de Articulos',
--           'mnuArticulosPropiedades',
--           'inMtoArticulosPropiedades.TfrmMtoArticulosPropiedades',
--           'Ctrl+B',
--           'UniDataArticulosPropiedades.TdmArticulosPropiedades', 5);
-- INSERT INTO fza_permisos (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM)
--   VALUES ('Alfredo',    'menu.ArticulosPropiedades', 'S'),
--          ('Todos',      'menu.ArticulosPropiedades', 'S'),
--          ('Vendedores', 'menu.ArticulosPropiedades', 'N');
-- ============================================================================
