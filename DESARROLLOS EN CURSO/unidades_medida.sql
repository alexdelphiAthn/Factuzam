-- =============================================================================
-- Catalogo de unidades de medida: fza_unidades_medida (sufijo UNIMED)
-- =============================================================================
-- Un cliente que maneja telas por metros necesita cantidades con decimales
-- en todo el programa (entradas, ventas, informes). La BBDD ya guarda las
-- cantidades como DECIMAL(19,6), asi que el dato decimal ya cabe; lo que
-- faltaba es decidir CUANTOS decimales mostrar/teclear, y eso depende de la
-- unidad de medida del articulo (Uds = 0, metros = 2, kilos = 3...).
--
-- Hasta ahora la unidad (TIPO_CANTIDAD_ART y los TIPO_CANTIDAD_* de las
-- lineas) era texto libre. Esta tabla la convierte en un catalogo con:
--   - DECIMALES_UNIMED : cuantos decimales usa esa unidad.
--   - MAGNITUD/ESBASE/FACTOR_BASE : conversion a la unidad estandar de su
--     magnitud (cm/mm -> metros, g -> kilos...). valor_base = valor * FACTOR.
--
-- Sigue el libro de estilo: sufijo de tabla UNIMED tras el nucleo del
-- concepto; las cuatro columnas de auditoria van sin sufijo (ver §3.7).
--
-- Idempotente: se puede ejecutar varias veces.
--   - La tabla se crea solo si no existe (CREATE TABLE IF NOT EXISTS).
--   - La semilla usa INSERT IGNORE: no pisa filas ya editadas por el usuario.
-- NO toca factuzam_original.sql (regla dura n.1 de CLAUDE.md).
-- =============================================================================

-- 1) Tabla -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_unidades_medida` (
  `CODIGO_UNIMED` varchar(20) NOT NULL COMMENT 'Clave de la unidad: Uds, m, cm, kg, g, rollo...',
  `DESCRIPCION_UNIMED` varchar(100) NOT NULL COMMENT 'Nombre legible: Metros, Kilogramos...',
  `DECIMALES_UNIMED` int(11) NOT NULL DEFAULT 2 COMMENT 'Numero de decimales a mostrar/teclear para esta unidad',
  `MAGNITUD_UNIMED` varchar(20) NOT NULL DEFAULT 'OTROS' COMMENT 'Familia fisica: UNIDAD, LONGITUD, MASA, VOLUMEN... Solo se convierten entre si unidades de la misma magnitud',
  `ESBASE_UNIMED` varchar(1) NOT NULL DEFAULT 'N' COMMENT 'S = unidad estandar/base de su magnitud (metro, kilo...)',
  `FACTOR_BASE_UNIMED` decimal(19,6) NOT NULL DEFAULT 1.000000 COMMENT 'Factor a la unidad base: valor_base = valor * FACTOR (cm->m = 0.01, g->kg = 0.001)',
  `ORDEN_UNIMED` int(11) NULL DEFAULT 0 COMMENT 'Orden de presentacion en desplegables',
  `ESACTIVO_UNIMED` varchar(1) NOT NULL DEFAULT 'S' COMMENT 'S/N: unidad activa',
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`CODIGO_UNIMED`)
);

-- 2) Semilla estandar --------------------------------------------------------
-- INSERT IGNORE: si la unidad ya existe (misma PK) se respeta lo que haya.
INSERT IGNORE INTO `fza_unidades_medida`
  (`CODIGO_UNIMED`, `DESCRIPCION_UNIMED`, `DECIMALES_UNIMED`,
   `MAGNITUD_UNIMED`, `ESBASE_UNIMED`, `FACTOR_BASE_UNIMED`, `ORDEN_UNIMED`,
   `ESACTIVO_UNIMED`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  ('Uds', 'Unidades',    0, 'UNIDAD',   'S', 1.000000, 10, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('m',   'Metros',      2, 'LONGITUD', 'S', 1.000000, 20, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('cm',  'Centimetros', 2, 'LONGITUD', 'N', 0.010000, 21, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('mm',  'Milimetros',  2, 'LONGITUD', 'N', 0.001000, 22, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('kg',  'Kilogramos',  3, 'MASA',     'S', 1.000000, 30, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('g',   'Gramos',      3, 'MASA',     'N', 0.001000, 31, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('l',   'Litros',      3, 'VOLUMEN',  'S', 1.000000, 40, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA'),
  ('ml',  'Mililitros',  3, 'VOLUMEN',  'N', 0.001000, 41, 'S', current_timestamp(), 'SISTEMA', 'SISTEMA');

-- 3) Alta automatica de las unidades de texto libre ya existentes ------------
-- Los articulos actuales tienen TIPO_CANTIDAD_ART como texto libre. Para que
-- el desplegable no deje huerfanos, se dan de alta las que no esten ya en el
-- catalogo, con 2 decimales por defecto y magnitud OTROS (el usuario las
-- afina luego en el mantenimiento). INSERT IGNORE evita duplicar.
INSERT IGNORE INTO `fza_unidades_medida`
  (`CODIGO_UNIMED`, `DESCRIPCION_UNIMED`, `DECIMALES_UNIMED`,
   `MAGNITUD_UNIMED`, `ESBASE_UNIMED`, `FACTOR_BASE_UNIMED`,
   `ESACTIVO_UNIMED`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
SELECT DISTINCT
       TRIM(`TIPO_CANTIDAD_ART`), TRIM(`TIPO_CANTIDAD_ART`), 2,
       'OTROS', 'N', 1.000000,
       'S', current_timestamp(), 'SISTEMA', 'SISTEMA'
  FROM `fza_articulos`
 WHERE `TIPO_CANTIDAD_ART` IS NOT NULL
   AND TRIM(`TIPO_CANTIDAD_ART`) <> '';
