-- Prueba inicial zh-CN: opciones visibles del menú principal.
-- Idempotente: actualiza las traducciones si el paquete se ejecuta de nuevo.
SET NAMES utf8mb4;
INSERT INTO fza_traducciones (
  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,
  ESACTIVO_TRAD, INSTANTE_ALTA, USUARIO_ALTA
) VALUES
  ('inMtoPrincipal.TfrmMtoPrincipal.Archivo1.Caption',
   'zh-CN', CONVERT(0xE69687E4BBB6 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.mnuEmpresas.Caption',
   'zh-CN', CONVERT(0xE585ACE58FB8 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.mnuClientes.Caption',
   'zh-CN', CONVERT(0xE5AEA2E688B7 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.mnuArticulos.Caption',
   'zh-CN', CONVERT(0xE59586E59381 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.Salir1.Caption',
   'zh-CN', CONVERT(0xE98080E587BA USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.Compras1.Caption',
   'zh-CN', CONVERT(0xE98787E8B4AD USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.Ventas1.Caption',
   'zh-CN', CONVERT(0xE689B9E58F91E99480E594AE USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.mnuCaja.Caption',
   'zh-CN', CONVERT(0xE99480E594AEE7BB88E7ABAF USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.mnuAlmacen.Caption',
   'zh-CN', CONVERT(0xE4BB93E5BA93 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.Utilidades1.Caption',
   'zh-CN', CONVERT(0xE585B6E4BB96 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice'),
  ('inMtoPrincipal.TfrmMtoPrincipal.Ayuda1.Caption',
   'zh-CN', CONVERT(0xE5B8AEE58AA9 USING utf8mb4),
   'src/Core/inMtoPrincipal.dfm', 'S', CURRENT_TIMESTAMP, 'Webservice')
ON DUPLICATE KEY UPDATE
  TEXTO_TRAD = VALUES(TEXTO_TRAD),
  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),
  ESACTIVO_TRAD = 'S',
  INSTANTE_MODIF = CURRENT_TIMESTAMP,
  USUARIO_MODIF = VALUES(USUARIO_ALTA);
