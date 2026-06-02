-- ---------------------------------------------------------------------------
-- Normaliza fza_almacenes.TIPO_USO_ALM a los 4 valores canonicos:
--   ESTANDAR / TARAS / DEPÓSITO / TRÁNSITO
-- ---------------------------------------------------------------------------
-- Motivo: el tipo de almacen se tecleaba a mano (campo libre) y hay datos mal
-- escritos en la BBDD de prueba (p.ej. 'ESTANDARD' con D de mas, que deja al
-- almacen fuera del filtro de destinos de traspaso, que compara = 'ESTANDAR').
-- A partir de ahora el mantenimiento de almacenes usa un combo cerrado
-- (lsFixedList) con estos 4 valores; este script alinea lo ya existente.
--
-- Idempotente: re-ejecutar no hace dano. La colacion utf8mb4_spanish_ci es
-- insensible a acentos/mayusculas, por eso comparar con 'DEPOSITO' agrupa
-- 'DEPÓSITO'/'deposito'/...; aun asi forzamos el valor canonico CON su tilde
-- para que quede escrito igual en toda la tabla.
-- ---------------------------------------------------------------------------

-- 1) Errata real (no es solo acento): 'ESTANDARD' / 'STANDARD' -> 'ESTANDAR'.
UPDATE fza_almacenes
   SET TIPO_USO_ALM = 'ESTANDAR'
 WHERE TIPO_USO_ALM IN ('ESTANDARD', 'STANDARD');

-- 2) Fija tilde y mayusculas canonicas del resto (la colacion agrupa variantes
--    como 'deposito' o 'transito' sin tilde; las dejamos con la forma final).
UPDATE fza_almacenes SET TIPO_USO_ALM = 'ESTANDAR' WHERE TIPO_USO_ALM = 'ESTANDAR';
UPDATE fza_almacenes SET TIPO_USO_ALM = 'TARAS'    WHERE TIPO_USO_ALM = 'TARAS';
UPDATE fza_almacenes SET TIPO_USO_ALM = 'DEPÓSITO' WHERE TIPO_USO_ALM = 'DEPOSITO';
UPDATE fza_almacenes SET TIPO_USO_ALM = 'TRÁNSITO' WHERE TIPO_USO_ALM = 'TRANSITO';

-- 3) Revision: lista los almacenes que sigan con un tipo fuera del catalogo
--    (para corregirlos a mano; el combo no podra mostrar valores no listados).
SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, TIPO_USO_ALM
  FROM fza_almacenes
 WHERE TIPO_USO_ALM IS NULL
    OR TIPO_USO_ALM NOT IN ('ESTANDAR', 'TARAS', 'DEPÓSITO', 'TRÁNSITO');
