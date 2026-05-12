-- ============================================================================
--  Demo de fza_atributos_conjuntos + valores + asignación a artículos
-- ----------------------------------------------------------------------------
--  Restaura la cabecera de conjuntos (fza_atributos_conjuntos) que se borró
--  por error, y deja una demo coherente con artículos del catálogo.
--
--  Usa SOLO valores que ya existen en fza_atributos_valores:
--    Tallas letra (TAL): 9101=S, 9102=M, 9103=L, 9104=XL, 9210=XXL, 9212=XXXL
--    Tallas calzado (TAL): 121=37, 122=38, 227=39, 225=40, 224=41,
--                          126=42, 127=43, 226=44
--    Colores (CO):     9201=BLANCO, 9202=NEGRO, 9203=AZUL MARINO,
--                      9204=AMARILLO, 9207=BONIATO, 9208=FUCSIA,
--                      9209=BURDEOS, 9211=PEPINO, 218=AZUL, 221=ROSA,
--                      222=CAMEL
--
--  Idempotente: se puede re-ejecutar; vacía las 3 tablas relacionadas y
--  vuelve a cargar la demo desde cero.
-- ============================================================================

START TRANSACTION;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Limpieza para arrancar la demo desde cero ------------------------------
DELETE FROM `fza_articulos_conjuntos_asign`;
DELETE FROM `fza_atributos_conjuntos_det`;
DELETE FROM `fza_atributos_conjuntos`;
ALTER TABLE `fza_atributos_conjuntos` AUTO_INCREMENT = 1;

-- 2. Cabeceras de conjuntos -------------------------------------------------
INSERT INTO `fza_atributos_conjuntos`
  (`ID_AC`, `NOMBRE_AC`, `ID_VAR_AC`, `ID_VA_AC`, `ESACTIVO_AC`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (1, 'Tallas Ropa Hombre Standard',    'TC', 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  (2, 'Colores Básicos Verano',         'TC', 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  (3, 'Tallas Ropa Mujer (S-XL)',       'TC', 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  (4, 'Tallas Calzado Hombre EU 39-44', 'TC', 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  (5, 'Tallas Calzado Mujer EU 37-42',  'TC', 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  (6, 'Colores Vivos',                  'TC', 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO');

-- 3. Valores que componen cada conjunto ------------------------------------

-- 3.1 Tallas Ropa Hombre: S, M, L, XL, XXL, XXXL
INSERT INTO `fza_atributos_conjuntos_det`
  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (1, 9101, 10, NOW(), NOW(), 'DEMO', 'DEMO'),
  (1, 9102, 20, NOW(), NOW(), 'DEMO', 'DEMO'),
  (1, 9103, 30, NOW(), NOW(), 'DEMO', 'DEMO'),
  (1, 9104, 40, NOW(), NOW(), 'DEMO', 'DEMO'),
  (1, 9210, 50, NOW(), NOW(), 'DEMO', 'DEMO'),
  (1, 9212, 60, NOW(), NOW(), 'DEMO', 'DEMO');

-- 3.2 Colores Básicos Verano: BLANCO, NEGRO, AZUL MARINO, AMARILLO, BONIATO
INSERT INTO `fza_atributos_conjuntos_det`
  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (2, 9201, 10, NOW(), NOW(), 'DEMO', 'DEMO'),
  (2, 9202, 20, NOW(), NOW(), 'DEMO', 'DEMO'),
  (2, 9203, 30, NOW(), NOW(), 'DEMO', 'DEMO'),
  (2, 9204, 40, NOW(), NOW(), 'DEMO', 'DEMO'),
  (2, 9207, 50, NOW(), NOW(), 'DEMO', 'DEMO');

-- 3.3 Tallas Ropa Mujer: S, M, L, XL
INSERT INTO `fza_atributos_conjuntos_det`
  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (3, 9101, 10, NOW(), NOW(), 'DEMO', 'DEMO'),
  (3, 9102, 20, NOW(), NOW(), 'DEMO', 'DEMO'),
  (3, 9103, 30, NOW(), NOW(), 'DEMO', 'DEMO'),
  (3, 9104, 40, NOW(), NOW(), 'DEMO', 'DEMO');

-- 3.4 Tallas Calzado Hombre EU: 39, 40, 41, 42, 43, 44
INSERT INTO `fza_atributos_conjuntos_det`
  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (4, 227, 10, NOW(), NOW(), 'DEMO', 'DEMO'),
  (4, 225, 20, NOW(), NOW(), 'DEMO', 'DEMO'),
  (4, 224, 30, NOW(), NOW(), 'DEMO', 'DEMO'),
  (4, 126, 40, NOW(), NOW(), 'DEMO', 'DEMO'),
  (4, 127, 50, NOW(), NOW(), 'DEMO', 'DEMO'),
  (4, 226, 60, NOW(), NOW(), 'DEMO', 'DEMO');

-- 3.5 Tallas Calzado Mujer EU: 37, 38, 39, 40, 41, 42
INSERT INTO `fza_atributos_conjuntos_det`
  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (5, 121, 10, NOW(), NOW(), 'DEMO', 'DEMO'),
  (5, 122, 20, NOW(), NOW(), 'DEMO', 'DEMO'),
  (5, 227, 30, NOW(), NOW(), 'DEMO', 'DEMO'),
  (5, 225, 40, NOW(), NOW(), 'DEMO', 'DEMO'),
  (5, 224, 50, NOW(), NOW(), 'DEMO', 'DEMO'),
  (5, 126, 60, NOW(), NOW(), 'DEMO', 'DEMO');

-- 3.6 Colores Vivos: FUCSIA, BURDEOS, PEPINO, AZUL, ROSA, CAMEL
INSERT INTO `fza_atributos_conjuntos_det`
  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  (6, 9208, 10, NOW(), NOW(), 'DEMO', 'DEMO'),
  (6, 9209, 20, NOW(), NOW(), 'DEMO', 'DEMO'),
  (6, 9211, 30, NOW(), NOW(), 'DEMO', 'DEMO'),
  (6, 218,  40, NOW(), NOW(), 'DEMO', 'DEMO'),
  (6, 221,  50, NOW(), NOW(), 'DEMO', 'DEMO'),
  (6, 222,  60, NOW(), NOW(), 'DEMO', 'DEMO');

-- 4. Asignación a artículos del catálogo (todos con ESVARIACION_ART='S') ----
-- PK (CODIGO_ART_ACA, ID_VA_ACA) → cada artículo lleva un conjunto TAL
-- y un conjunto CO.
INSERT INTO `fza_articulos_conjuntos_asign`
  (`CODIGO_ART_ACA`, `ID_AC_ACA`, `ID_VA_ACA`, `ESGENERACION_AUTO_ACA`,
   `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  -- Ropa hombre: Tallas Hombre + Colores Básicos
  ('CAMI-BASICA',   1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('CAMI-BASICA',   2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('CAMI-POLO',     1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('CAMI-POLO',     2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('PANT-CHIN',     1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('PANT-CHIN',     2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('SUDADERA-HOOD', 1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('SUDADERA-HOOD', 6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('JERSEY-LANA',   1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('JERSEY-LANA',   2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('CHAQ-CUERO',    1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('CHAQ-CUERO',    2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ABRIGO-PAÑO',   1, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ABRIGO-PAÑO',   2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),

  -- Ropa mujer: Tallas Mujer + Colores Vivos
  ('BLUS-SEDA',     3, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('BLUS-SEDA',     6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('FALD-JEAN',     3, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('FALD-JEAN',     6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('FALD-PLIS',     3, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('FALD-PLIS',     6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('VEST-FLOR',     3, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('VEST-FLOR',     6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('LEGGING-SPORT', 3, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('LEGGING-SPORT', 2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),

  -- Calzado hombre: Tallas Calzado Hombre + Colores Básicos
  ('ZAP-OXFORD',    4, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-OXFORD',    2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-BOTA-MT',   4, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-BOTA-MT',   2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-DEPOR',     4, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-DEPOR',     6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),

  -- Calzado mujer: Tallas Calzado Mujer + Colores Vivos
  ('BOTIN-ANIT',    5, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('BOTIN-ANIT',    2, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-TACÓN',     5, 'TAL', 'S', NOW(), NOW(), 'DEMO', 'DEMO'),
  ('ZAP-TACÓN',     6, 'CO',  'S', NOW(), NOW(), 'DEMO', 'DEMO');

SET FOREIGN_KEY_CHECKS = 1;

COMMIT;

-- 5. Resumen ----------------------------------------------------------------
SELECT 'Demo Colecciones de Atributos cargada' AS resultado,
       (SELECT COUNT(*) FROM `fza_atributos_conjuntos`)        AS conjuntos,
       (SELECT COUNT(*) FROM `fza_atributos_conjuntos_det`)    AS valores_det,
       (SELECT COUNT(*) FROM `fza_articulos_conjuntos_asign`)  AS asignaciones;
