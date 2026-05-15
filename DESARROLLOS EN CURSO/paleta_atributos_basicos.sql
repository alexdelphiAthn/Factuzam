-- ============================================================================
--  Paleta de atributos básicos (fza_atributos_basicos)
-- ----------------------------------------------------------------------------
--  Rellena la "paleta" de colores básicos para que la caja/ficha de artículo
--  puedan pintar un cuadradito de color delante del nombre del atributo.
--
--  Para cada (ID_VA_ATB, CODIGO_ATB) almacenamos:
--    NOMBRE_ATB  → Texto descriptivo que usa el hint del grid.
--    EXTRA_ATB   → Color hex '#RRGGBB' (campo varchar(7)).
--
--  La librería `inLibAtributosPaleta` hace match con los valores del SKU por
--  (fza_atributos_valores.ID_VA_AV, fza_atributos_valores.AV).
--
--  Idempotente: hace upsert con la unique (ID_VA_ATB, CODIGO_ATB).
-- ============================================================================

START TRANSACTION;

-- 1. Colores (ID_VA_ATB = 'CO') ----------------------------------------------
INSERT INTO `fza_atributos_basicos`
  (`ID_VA_ATB`, `CODIGO_ATB`, `NOMBRE_ATB`, `EXTRA_ATB`,
   `ORDEN_ATB`, `ESACTIVO_ATB`)
VALUES
  ('CO', 'ROJO',        'Rojo bandera',     '#D32F2F', 10, 'S'),
  ('CO', 'NEGRO',       'Negro',            '#000000', 20, 'S'),
  ('CO', 'BLANCO',      'Blanco roto',      '#FAFAFA', 30, 'S'),
  ('CO', 'VERDE',       'Verde botella',    '#2E7D32', 40, 'S'),
  ('CO', 'MARRON',      'Marrón chocolate', '#5D4037', 50, 'S'),
  ('CO', 'AZUL',        'Azul',             '#1976D2', 60, 'S'),
  ('CO', 'AZUL MARINO', 'Azul marino',      '#0D1B45', 70, 'S'),
  ('CO', 'GRIS',        'Gris medio',       '#9E9E9E', 80, 'S'),
  ('CO', 'BEIGE',       'Beige',            '#D7C7A8', 90, 'S'),
  ('CO', 'ROSA',        'Rosa',             '#F48FB1',100, 'S'),
  ('CO', 'CAMEL',       'Camel',            '#C19A6B',110, 'S'),
  ('CO', 'AMARILLO',    'Amarillo',         '#FBC02D',120, 'S'),
  ('CO', 'CACAO',       'Cacao',            '#6F4E37',130, 'S'),
  ('CO', 'BONIATO',     'Boniato',          '#E27D60',140, 'S'),
  ('CO', 'FUCSIA',      'Fucsia',           '#C2185B',150, 'S'),
  ('CO', 'BURDEOS',     'Burdeos',          '#7B1D26',160, 'S'),
  ('CO', 'PEPINO',      'Pepino',           '#7CB342',170, 'S'),
  ('CO', 'VAQUERO',     'Vaquero',          '#3B5998',180, 'S'),
  ('CO', 'COLORAO',     'Colorao',          '#E64A19',190, 'S')
ON DUPLICATE KEY UPDATE
  NOMBRE_ATB   = VALUES(NOMBRE_ATB),
  EXTRA_ATB    = VALUES(EXTRA_ATB),
  ORDEN_ATB    = VALUES(ORDEN_ATB),
  ESACTIVO_ATB = VALUES(ESACTIVO_ATB);

COMMIT;
