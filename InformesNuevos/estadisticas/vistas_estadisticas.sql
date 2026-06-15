-- =============================================================================
-- Vistas de estadísticas para informes (BI) — solo lectura sobre fza_*
-- =============================================================================
-- Grano: día x almacén x familia x temporada.
-- No alteran el esquema: CREATE OR REPLACE VIEW (idempotente). No materializan
-- (MariaDB no tiene vistas materializadas); encapsulan la lógica y dejan al
-- panel un SELECT simple.
--
-- IMPORTANTE sobre TEMPORADA:
--   No es columna de fza_articulos. Es la PROPIEDAD 'TEMPORADA'
--   (fza_propiedades, NIVEL_PROP = 'COLOR' -> propiedad de 2º nivel) cuyos
--   valores viven en fza_articulos_propiedades con CODIGO_UNIDAD_ARTPROP:
--     ''            -> valor a nivel ARTÍCULO
--     ART/COLOR     -> valor a nivel COLOR  (puede variar por color)
--     ART/COLOR/TALLA -> valor a nivel SKU
--   Se resuelve por la clave de color derivada del SKU con SUBSTRING_INDEX,
--   con fallback a nivel artículo. NO se usa vi_articulos (colapsa temporada
--   a un único valor por artículo y multiplicaría filas).
--   Familia SÍ es de artículo (fza_articulos.CODIGO_FAM_ART).
-- =============================================================================
-- 0) Resolver de temporada: una fila por (artículo, clave de nivel)
CREATE OR REPLACE VIEW viest_temporada AS
SELECT
  p.CODIGO_ART_ART                          AS CODIGO_ART,
  p.CODIGO_UNIDAD_ARTPROP                    AS CLAVE_NIVEL,
  COALESCE(pv.PV, p.VALOR_LIBRE_ARTPROP)    AS TEMPORADA
FROM fza_articulos_propiedades p
LEFT JOIN fza_propiedades_valores pv
  ON pv.ID_PV_ARTPROP = p.ID_PV_ARTPROP
WHERE p.CODIGO_PROP_ARTPROP = 'TEMPORADA';
-- 1) Movimientos de almacén agregados por día
CREATE OR REPLACE VIEW viest_movimientos_dia AS
SELECT
  DATE(m.FECHA_MOV)                              AS FECHA,
  m.CODIGO_ALM_MOV                           AS CODIGO_ALMACEN,
  COALESCE(a.CODIGO_FAM_ART, '')               AS CODIGO_FAMILIA,
  COALESCE(tcol.TEMPORADA, tart.TEMPORADA, '') AS TEMPORADA,
  COUNT(*)                                       AS NUM_MOVIMIENTOS,
  COALESCE(SUM(m.CANTIDAD_MOV), 0)             AS UNIDADES_MOV,
  COALESCE(SUM(m.TOTAL_COSTE_MOV), 0)         AS COSTE_MOV
FROM fza_movimientos_almacen m
LEFT JOIN fza_articulos_skus s
  ON s.CODIGO_UNIDAD_SKU = m.CODIGO_UNIDAD_MOV
LEFT JOIN fza_articulos a
  ON a.CODIGO_ART_ART = COALESCE(m.CODIGO_ART_MOV, s.CODIGO_ART_SKU)
LEFT JOIN viest_temporada tcol
  ON tcol.CODIGO_ART  = SUBSTRING_INDEX(m.CODIGO_UNIDAD_MOV, '/', 1)
 AND tcol.CLAVE_NIVEL = SUBSTRING_INDEX(m.CODIGO_UNIDAD_MOV, '/', 2)
LEFT JOIN viest_temporada tart
  ON tart.CODIGO_ART  = SUBSTRING_INDEX(m.CODIGO_UNIDAD_MOV, '/', 1)
 AND tart.CLAVE_NIVEL = ''
WHERE m.ESACTIVO_MOV = 'S'
GROUP BY DATE(m.FECHA_MOV), m.CODIGO_ALM_MOV,
         COALESCE(a.CODIGO_FAM_ART, ''),
         COALESCE(tcol.TEMPORADA, tart.TEMPORADA, '');
-- 2) Ventas (líneas de factura) agregadas por día
CREATE OR REPLACE VIEW viest_ventas_dia AS
SELECT
  f.FECHA_FAC                                    AS FECHA,
  l.CODIGO_ALM_FACLIN                            AS CODIGO_ALMACEN,
  COALESCE(a.CODIGO_FAM_ART, '')               AS CODIGO_FAMILIA,
  COALESCE(tcol.TEMPORADA, tart.TEMPORADA, '') AS TEMPORADA,
  COUNT(*)                                       AS NUM_LINEAS_VENTA,
  COALESCE(SUM(l.CANTIDAD_FACLIN), 0)         AS UNIDADES_VENTA,
  COALESCE(SUM(l.TOTAL_FACLIN), 0)            AS IMPORTE_VENTA
FROM fza_facturas_lineas l
JOIN fza_facturas f
  ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN
 AND f.SERIE_FAC  = l.SERIE_FAC_FACLIN
LEFT JOIN fza_articulos a
  ON a.CODIGO_ART_ART = l.CODIGO_ART_FACLIN
LEFT JOIN viest_temporada tcol
  ON tcol.CODIGO_ART  = SUBSTRING_INDEX(l.CODIGO_UNIDAD_FACLIN, '/', 1)
 AND tcol.CLAVE_NIVEL = SUBSTRING_INDEX(l.CODIGO_UNIDAD_FACLIN, '/', 2)
LEFT JOIN viest_temporada tart
  ON tart.CODIGO_ART  = SUBSTRING_INDEX(l.CODIGO_UNIDAD_FACLIN, '/', 1)
 AND tart.CLAVE_NIVEL = ''
GROUP BY f.FECHA_FAC, l.CODIGO_ALM_FACLIN,
         COALESCE(a.CODIGO_FAM_ART, ''),
         COALESCE(tcol.TEMPORADA, tart.TEMPORADA, '');
-- 3) Vista unificada: una fila por (día, almacén, familia, temporada) con
--    todas las medidas. Es la que consultaría el panel/lab.
CREATE OR REPLACE VIEW viest_dia AS
SELECT
  FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA,
  SUM(NUM_MOVIMIENTOS)  AS NUM_MOVIMIENTOS,
  SUM(UNIDADES_MOV)     AS UNIDADES_MOV,
  SUM(COSTE_MOV)        AS COSTE_MOV,
  SUM(NUM_LINEAS_VENTA) AS NUM_LINEAS_VENTA,
  SUM(UNIDADES_VENTA)   AS UNIDADES_VENTA,
  SUM(IMPORTE_VENTA)    AS IMPORTE_VENTA
FROM (
  SELECT FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA,
         NUM_MOVIMIENTOS, UNIDADES_MOV, COSTE_MOV,
         0 AS NUM_LINEAS_VENTA, 0 AS UNIDADES_VENTA, 0 AS IMPORTE_VENTA
    FROM viest_movimientos_dia
  UNION ALL
  SELECT FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA,
         0, 0, 0,
         NUM_LINEAS_VENTA, UNIDADES_VENTA, IMPORTE_VENTA
    FROM viest_ventas_dia
) u
GROUP BY FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA;
-- 4) Lista de temporadas (para el combo de filtro del panel)
CREATE OR REPLACE VIEW viest_temporadas AS
SELECT DISTINCT TEMPORADA
FROM viest_temporada
WHERE TEMPORADA IS NOT NULL AND TEMPORADA <> '';
-- -----------------------------------------------------------------------------
-- Ejemplo de consulta del panel (comparativa diaria de un rango):
--   SELECT DATEDIFF(FECHA, :pD1) AS BUCKET, SUM(IMPORTE_VENTA) AS VALOR
--     FROM viest_dia
--    WHERE FECHA >= :pD1 AND FECHA <= :pD2
--      AND (:pALM  = '' OR CODIGO_ALMACEN = :pALM)
--      AND (:pFAM  = '' OR CODIGO_FAMILIA = :pFAM)
--      AND (:pTEMP = '' OR TEMPORADA      = :pTEMP)
--    GROUP BY BUCKET ORDER BY BUCKET;
-- OJO rendimiento: una vista con GROUP BY no empuja el filtro de fecha antes
-- de agregar (algoritmo TEMPTABLE), así que para el panel EN VIVO conviene
-- filtrar por fecha sobre las tablas base (como hace el .pas). Estas vistas
-- valen para encapsular la lógica y para el experimento fzaest_.
-- -----------------------------------------------------------------------------
