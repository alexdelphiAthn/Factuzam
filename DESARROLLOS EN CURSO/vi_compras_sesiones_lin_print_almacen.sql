-- Vista vi_compras_sesiones_lin_print con desglose por almacen.
-- ============================================================================
-- Modo NO distribuido: todas las celdas de la linea estan en el almacen
-- de cabecera (CODIGO_ALM_SES); el GROUP BY agrega tal cual y sale UNA fila
-- por (linea). Comportamiento original preservado.
-- Modo distribuido: celdas con CODIGO_ALM_SESCEL distintos producen UNA fila
-- por (linea, almacen). El report puede mostrar la columna CODIGO_ALM con
-- el almacen efectivo para distinguirlas.
--
-- Script idempotente: CREATE OR REPLACE VIEW.

CREATE OR REPLACE VIEW `vi_compras_sesiones_lin_print` AS
WITH `pos_acd` AS (
  SELECT
    `ID_AC_ACD` AS `ID_AC`,
    `ID_AV_ACD` AS `ID_AV`,
    ROW_NUMBER() OVER (
      PARTITION BY `ID_AC_ACD`
      ORDER BY `ORDEN_ACD`, `ID_AV_ACD`
    ) AS `POSICION`
  FROM `fza_atributos_conjuntos_det`
)
SELECT
  lin.`SERIE_SES_SESLIN`           AS `SERIE_SES`,
  lin.`NUMERO_SES_SESLIN`          AS `NUMERO_SES`,
  lin.`LINEA_SESLIN`               AS `LINEA_SES`,
  lin.`CODIGO_ART_TENTATIVO_SESLIN` AS `CODIGO_ART`,
  lin.`REF_PRV_SESLIN`             AS `REF_PRV`,
  lin.`DESCRIPCION_SESLIN`         AS `DESCRIPCION`,
  lin.`COLOR_TEXTO_SESLIN`         AS `COLOR_TEXTO`,
  lin.`CODIGO_ATB_COLOR_SESLIN`    AS `CODIGO_ATB_COLOR`,
  lin.`PRECIO_COMPRA_SESLIN`       AS `PRECIO_COMPRA`,
  lin.`PRECIO_VENTA_SESLIN`        AS `PRECIO_VENTA`,
  lin.`ID_AC_PIVOT_SESLIN`         AS `ID_AC_PIVOT`,
  ac.`NOMBRE_AC`,
  COALESCE(ac.`NOMBRE_CORTO_AC`, UPPER(LEFT(ac.`NOMBRE_AC`, 8))) AS `NOMBRE_CORTO_AC`,
  IFNULL(NULLIF(cel.`CODIGO_ALM_SESCEL`, ''), ses.`CODIGO_ALM_SES`) AS `CODIGO_ALM`,
  COALESCE(alm.`NOMBRE_ALM_ALM`,
           IFNULL(NULLIF(cel.`CODIGO_ALM_SESCEL`, ''),
                  ses.`CODIGO_ALM_SES`))                              AS `NOMBRE_ALM`,
  -- Totales por (linea, almacen). En modo NO distribuido todas las celdas
  -- comparten el mismo almacen -> coincide con el total de la linea entera.
  SUM(IFNULL(cel.`CANTIDAD_SESCEL`, 0)) AS `TOTAL_UNIDADES`,
  SUM(IFNULL(cel.`CANTIDAD_SESCEL`, 0)) * lin.`PRECIO_COMPRA_SESLIN` AS `TOTAL_LINEA`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  1 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T01`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  2 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T02`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  3 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T03`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  4 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T04`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  5 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T05`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  6 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T06`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  7 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T07`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  8 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T08`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  9 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T09`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 10 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T10`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 11 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T11`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 12 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T12`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 13 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T13`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 14 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T14`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 15 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T15`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 16 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T16`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 17 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T17`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 18 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T18`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 19 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T19`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 20 THEN cel.`CANTIDAD_SESCEL` END), 0) AS `T20`
FROM `fza_compras_sesiones_lineas` lin
JOIN `fza_compras_sesiones`        ses
  ON  ses.`SERIE_SES`  = lin.`SERIE_SES_SESLIN`
 AND  ses.`NUMERO_SES` = lin.`NUMERO_SES_SESLIN`
LEFT JOIN `fza_atributos_conjuntos` ac
       ON ac.`ID_AC` = lin.`ID_AC_PIVOT_SESLIN`
LEFT JOIN `fza_compras_sesiones_celdas` cel
       ON cel.`SERIE_SES_SESCEL`  = lin.`SERIE_SES_SESLIN`
      AND cel.`NUMERO_SES_SESCEL` = lin.`NUMERO_SES_SESLIN`
      AND cel.`LINEA_SES_SESCEL`  = lin.`LINEA_SESLIN`
LEFT JOIN `pos_acd` p
       ON p.`ID_AC` = lin.`ID_AC_PIVOT_SESLIN`
      AND p.`ID_AV` = cel.`ID_AV_PIVOT_SESCEL`
LEFT JOIN `fza_almacenes` alm
       ON alm.`CODIGO_ALM_ALM` = IFNULL(NULLIF(cel.`CODIGO_ALM_SESCEL`, ''),
                                        ses.`CODIGO_ALM_SES`)
GROUP BY
  lin.`SERIE_SES_SESLIN`,  lin.`NUMERO_SES_SESLIN`,  lin.`LINEA_SESLIN`,
  lin.`CODIGO_ART_TENTATIVO_SESLIN`, lin.`REF_PRV_SESLIN`,
  lin.`DESCRIPCION_SESLIN`, lin.`COLOR_TEXTO_SESLIN`,
  lin.`CODIGO_ATB_COLOR_SESLIN`,
  lin.`PRECIO_COMPRA_SESLIN`, lin.`PRECIO_VENTA_SESLIN`,
  lin.`ID_AC_PIVOT_SESLIN`, ac.`NOMBRE_AC`, ac.`NOMBRE_CORTO_AC`,
  IFNULL(NULLIF(cel.`CODIGO_ALM_SESCEL`, ''), ses.`CODIGO_ALM_SES`),
  alm.`NOMBRE_ALM_ALM`;
