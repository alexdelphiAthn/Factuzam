-- ============================================================================
--  Drop EXTRA_ATB de fza_atributos_basicos
-- ----------------------------------------------------------------------------
--  La tabla tenia dos campos hex (HEX_ATB y EXTRA_ATB) con valores distintos.
--  HEX_ATB es el bueno (lo rellena el mantenimiento de basicos). EXTRA_ATB
--  era legacy de versiones anteriores y solo daba confusion.
--
--  Antes de borrar, hacemos un sanity-check: si hay filas con EXTRA_ATB
--  rellenado y HEX_ATB vacio, copiamos EXTRA_ATB -> HEX_ATB para no perder
--  el dato.
--
--  Idempotente.
-- ============================================================================

START TRANSACTION;

-- 1. Backstop: rellenar HEX_ATB con EXTRA_ATB si HEX_ATB esta vacio
UPDATE fza_atributos_basicos
   SET HEX_ATB = EXTRA_ATB
 WHERE (HEX_ATB IS NULL OR HEX_ATB = '')
   AND  EXTRA_ATB IS NOT NULL
   AND  EXTRA_ATB <> '';

-- 2. Dropear la columna
ALTER TABLE fza_atributos_basicos DROP COLUMN EXTRA_ATB;

COMMIT;

-- Verificacion (opcional, ejecutar despues):
-- DESCRIBE fza_atributos_basicos;
-- SELECT ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, HEX_ATB
--   FROM fza_atributos_basicos ORDER BY ID_VA_ATB, ORDEN_ATB;
