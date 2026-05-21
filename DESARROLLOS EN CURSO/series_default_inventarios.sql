-- ============================================================================
-- Series por defecto para inventarios (tipo IN) por empresa
-- ============================================================================
-- ObtenerSeriePorDefecto (UniDataInventarios.pas) busca en
-- fza_empresas_series la primera serie activa de tipo 'IN' para la empresa
-- del usuario y la mete en la cabecera al hacer 'Anadir inventario'. Si la
-- tabla no tiene ningun registro para esa empresa + 'IN', la cabecera se
-- crea con SERIE_INV='' y al grabar la primera linea revienta:
--
--   EDBClient 'Field value required.'
--
-- (Es la capa MidasLib/DSBase del TClientDataSet, que trata el string
-- vacio como missing para columnas NOT NULL.)
--
-- Este script crea una serie 'IN1' / tipo 'IN' / sin restriccion de
-- almacen / sin restriccion de fechas, para CADA empresa que NO tenga
-- ya alguna serie de tipo 'IN'. Las empresas que ya tienen serie de
-- inventario se quedan como estan.
--
-- Idempotente:
--   * INSERT ... SELECT ... LEFT JOIN ... WHERE existente IS NULL.
--   * Re-ejecutable: la segunda pasada no inserta nada.
--   * CODIGO_SERIE_EMPSER (PK) se construye como CONCAT('IN-', empresa)
--     para que no colisione con series existentes ni con futuras
--     ejecuciones.
-- ============================================================================

INSERT INTO fza_empresas_series (
    CODIGO_SERIE_EMPSER,
    CODIGO_EMP_EMPSER,
    CODIGO_ALM_EMPSER,
    CODIGO_CAJA_EMPSER,
    EMPSER,
    TIPO_DOC_EMPSER,
    SUBTIPO_EMPSER,
    FECHA_DESDE_EMPSER,
    FECHA_HASTA_EMPSER,
    INSTANTE_ALTA,
    INSTANTE_MODIF,
    USUARIO_ALTA,
    USUARIO_MODIF
)
SELECT
    CONCAT('IN-', e.CODIGO_EMP_EMP) AS CODIGO_SERIE_EMPSER,
    e.CODIGO_EMP_EMP                 AS CODIGO_EMP_EMPSER,
    NULL                             AS CODIGO_ALM_EMPSER,
    NULL                             AS CODIGO_CAJA_EMPSER,
    'IN1'                            AS EMPSER,
    'IN'                             AS TIPO_DOC_EMPSER,
    NULL                             AS SUBTIPO_EMPSER,
    NULL                             AS FECHA_DESDE_EMPSER,
    NULL                             AS FECHA_HASTA_EMPSER,
    NOW()                            AS INSTANTE_ALTA,
    NOW()                            AS INSTANTE_MODIF,
    'SCRIPT_SERIES_IN'               AS USUARIO_ALTA,
    'SCRIPT_SERIES_IN'               AS USUARIO_MODIF
FROM fza_empresas e
LEFT JOIN fza_empresas_series es
       ON es.CODIGO_EMP_EMPSER = e.CODIGO_EMP_EMP
      AND es.TIPO_DOC_EMPSER   = 'IN'
WHERE es.CODIGO_SERIE_EMPSER IS NULL
  AND NOT EXISTS (
      SELECT 1
        FROM fza_empresas_series es2
       WHERE es2.CODIGO_SERIE_EMPSER = CONCAT('IN-', e.CODIGO_EMP_EMP)
  );

-- ============================================================================
-- Arreglo de inventarios huerfanos: cabeceras con SERIE_INV=''
-- ============================================================================
-- Si ya creaste alguna cabecera de inventario antes de tener una serie
-- definida, su SERIE_INV quedo vacia y no puedes grabar lineas. Las
-- actualizamos para que apunten a la serie por defecto recien creada
-- (EMPSER='IN1') de su empresa.
--
-- Las lineas YA persistidas (fza_inventarios_lineas) con SERIE_INV_INVLIN=''
-- tambien se actualizan en cascada manual para no romper la PK compuesta.
--
-- Idempotente: el UPDATE solo afecta a filas con SERIE_INV=''.
-- ============================================================================

UPDATE fza_inventarios_lineas
   SET SERIE_INV_INVLIN = 'IN1'
 WHERE SERIE_INV_INVLIN = '';

UPDATE fza_inventarios
   SET SERIE_INV = 'IN1'
 WHERE SERIE_INV = '';
