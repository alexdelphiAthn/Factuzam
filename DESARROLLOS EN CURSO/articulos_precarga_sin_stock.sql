-- =============================================================================
-- Precarga de Articulos sin filtro de stock por defecto
-- =============================================================================
-- El mantenimiento de articulos debe abrir por defecto con articulos activos,
-- aunque no tengan stock. Si existe un perfil guardado con oFiltroConStock='S',
-- lo normalizamos a 'N'. Idempotente: repetirlo no cambia nada mas.
-- =============================================================================
UPDATE fza_usuarios_perfiles
   SET VALUE_USUPER = 'N',
       VALUE_TEXT_USUPER = NULL,
       INSTANTE_MODIF = CURRENT_TIMESTAMP,
       USUARIO_MODIF = 'script'
 WHERE (KEY_USUPER = 'frmMtoArticulos'
        OR KEY_USUPER REGEXP '^frmMtoArticulos_[0-9]+$')
   AND SUBKEY_USUPER = 'oFiltroConStock'
   AND COALESCE(VALUE_USUPER, '') <> 'N';
