-- ============================================================================
-- limpiar_permisos_menu_huerfanos.sql
-- ----------------------------------------------------------------------------
-- Quita filas huerfanas de fza_permisos cuyo CODIGO_PERM 'menu.<X>' no
-- corresponde ya a NINGUNA pantalla (CALL_WINF de fza_winforms) NI a ningun
-- item de menu real de inMtoPrincipal.dfm.
--
-- Como se detecto (cruce en frio, 27/07/2026, pasada B2/B3):
--   codigos 'menu.%' de fza_permisos  ==  { menu.<CALL> }  U  { menu.<NombreItem> }
--   Los unicos codigos que no casan con nada son:
--     * menu.ArticulosPropiedades -> pantalla inexistente. Se limpia en su
--       propio script: limpiar_winform_articulospropiedades.sql.
--     * menu.mnuFormaPagoVenta    -> el item 'mnuFormaPagoVenta' NO existe en
--       el menu (solo aparece en src/Core/__history, era un item viejo
--       renombrado/retirado) y tampoco es un CALL. La forma de pago viva es
--       CALL='FormasdePago' (atajo Ctrl+Q) y el item 'Formasdepago2'
--       ('Formas de pago documentos'). CodigoMenu() nunca genera este codigo
--       y TienePermiso() nunca lo consulta: metadato muerto.
--
-- Al borrarlo NO se pierde control de acceso a ninguna pantalla real: el
-- permiso de Formas de Pago sigue en 'menu.FormasdePago' y 'menu.Formasdepago2'.
--
-- Idempotente (el segundo pase no borra nada). NO tocar factuzam_original.sql.
-- Aplicar a las BBDD existentes (desarrollo y clientes) tras revisar el
-- SELECT previo.
-- ============================================================================
-- 1) Comprobacion previa: mira que se va a borrar antes de lanzar el DELETE.
SELECT 'permiso huerfano a borrar' AS que, p.USUARIO_GRUPO_PERM,
       p.CODIGO_PERM, p.VALOR_PERM, p.DESCRIPCION_PERM
  FROM fza_permisos p
 WHERE p.CODIGO_PERM = 'menu.mnuFormaPagoVenta';
-- 2) Borrado (idempotente). Cubre todos los usuarios/grupos con ese codigo.
DELETE FROM fza_permisos
 WHERE CODIGO_PERM = 'menu.mnuFormaPagoVenta';
-- 3) Verificacion: debe devolver 0.
SELECT COUNT(*) AS filas_restantes
  FROM fza_permisos
 WHERE CODIGO_PERM = 'menu.mnuFormaPagoVenta';
-- ============================================================================
-- ROLLBACK (solo si necesitas restaurar; normalmente NO hace falta). Los
-- valores son los de la demo; en tu BBDD los grupos/usuarios pueden variar.
-- ----------------------------------------------------------------------------
-- INSERT INTO fza_permisos
--   (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM,
--    INSTANTE_ALTA, USUARIO_ALTA)
--   VALUES ('Alfredo',    'menu.mnuFormaPagoVenta', 'S', 'Formas de pago',
--           NOW(), 'Administrador'),
--          ('Vendedores', 'menu.mnuFormaPagoVenta', 'N', 'Formas de pago',
--           NOW(), 'Administrador');
-- ============================================================================
