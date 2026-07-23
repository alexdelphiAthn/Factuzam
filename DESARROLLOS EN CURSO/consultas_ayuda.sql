-- =============================================================================
-- Consultas del menu Ayuda: permisos
-- =============================================================================
-- Las consultas de stocks (Ctrl+U) y de articulos similares (Ctrl+E) se
-- abren mediante handlers propios del menu principal. Al no usar ShowMto,
-- CodigoMenu genera el permiso a partir del nombre de cada TMenuItem.
-- Idempotente: INSERT IGNORE conserva cualquier configuracion existente.
-- =============================================================================
INSERT IGNORE INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM,
   INSTANTE_ALTA, USUARIO_ALTA)
VALUES
  ('Todos', 'menu.mnuConsultaStocks', 'S',
   'Ayuda: Consulta de stocks (Ctrl+U)', NOW(), 'SISTEMA'),
  ('Todos', 'menu.mnuArticulosSimilares', 'S',
   'Ayuda: Consulta de artículos similares (Ctrl+E)', NOW(), 'SISTEMA');
