-- Recalcula totales historicos de sesiones de compra desde celdas y lineas.
-- Ejecutar una vez despues de aplicar compras_sesiones_totales_iva.sql.
DROP TEMPORARY TABLE IF EXISTS tmp_ses_lineas_totales;
CREATE TEMPORARY TABLE tmp_ses_lineas_totales AS
SELECT L.SERIE_SES_SESLIN AS SERIE_SES,
       L.NUMERO_SES_SESLIN AS NUMERO_SES,
       L.LINEA_SESLIN AS LINEA_SES,
       COALESCE(SUM(C.CANTIDAD_SESCEL), 0) AS TOTAL_UNIDADES,
       COALESCE(SUM(C.CANTIDAD_SESCEL), 0) *
       COALESCE(L.PRECIO_COMPRA_SESLIN, 0) AS TOTAL_LINEA
  FROM fza_compras_sesiones_lineas L
  LEFT JOIN fza_compras_sesiones_celdas C
    ON C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN
   AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN
   AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN
 GROUP BY L.SERIE_SES_SESLIN,
          L.NUMERO_SES_SESLIN,
          L.LINEA_SESLIN,
          L.PRECIO_COMPRA_SESLIN;
UPDATE fza_compras_sesiones_lineas L
  JOIN tmp_ses_lineas_totales T
    ON T.SERIE_SES = L.SERIE_SES_SESLIN
   AND T.NUMERO_SES = L.NUMERO_SES_SESLIN
   AND T.LINEA_SES = L.LINEA_SESLIN
   SET L.TOTAL_UNIDADES_SESLIN = T.TOTAL_UNIDADES,
       L.TOTAL_LINEA_SESLIN = T.TOTAL_LINEA;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_iva_empresa;
CREATE TEMPORARY TABLE tmp_ses_iva_empresa AS
SELECT E.CODIGO_EMP_EMP,
       MIN(I.CODIGO_IVA) AS CODIGO_IVA
  FROM fza_empresas E
  JOIN fza_ivas_grupos G
    ON G.IVA_IVAGRP = E.GRUPO_ZONA_IVA_EMP
  JOIN fza_ivas I
    ON I.IVA_IVAGRP = G.IVA_IVAGRP
 WHERE G.ESDEFAULT_IVA_IVAGRP = 'S'
 GROUP BY E.CODIGO_EMP_EMP;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_iva;
CREATE TEMPORARY TABLE tmp_ses_iva AS
SELECT S.SERIE_SES,
       S.NUMERO_SES,
       COALESCE(NULLIF(S.CODIGO_IVA_SES, ''),
                IE.CODIGO_IVA) AS CODIGO_IVA,
       COALESCE(IVS.PORCENTAJE_NORMAL_IVA,
                IVE.PORCENTAJE_NORMAL_IVA,
                0) AS IVAN,
       COALESCE(IVS.PORCENTAJE_REDUCIDO_IVA,
                IVE.PORCENTAJE_REDUCIDO_IVA,
                0) AS IVAR,
       COALESCE(IVS.PORCENTAJE_SUPERREDUCIDO_IVA,
                IVE.PORCENTAJE_SUPERREDUCIDO_IVA,
                0) AS IVAS,
       COALESCE(IVS.PORCENTAJE_EXENTO_IVA,
                IVE.PORCENTAJE_EXENTO_IVA,
                0) AS IVAE,
       COALESCE(IVS.PORCENTAJE_NORMAL_RE_IVA,
                IVE.PORCENTAJE_NORMAL_RE_IVA,
                0) AS REN,
       COALESCE(IVS.PORCENTAJE_REDUCIDO_RE_IVA,
                IVE.PORCENTAJE_REDUCIDO_RE_IVA,
                0) AS RER,
       COALESCE(IVS.PORCENTAJE_SUPERREDUCIDO_RE_IVA,
                IVE.PORCENTAJE_SUPERREDUCIDO_RE_IVA,
                0) AS RES,
       COALESCE(IVS.PORCENTAJE_EXENTO_RE_IVA,
                IVE.PORCENTAJE_EXENTO_RE_IVA,
                0) AS REE,
       COALESCE(NULLIF(S.ESIVA_RECARGO_COMPRAS_SES, ''),
                NULLIF(E.ESIVA_RECARGO_COMPRAS_EMP, ''),
                'N') AS ESRECARGO,
       COALESCE(S.PORCENTAJE_RETENCION_SES, 0) AS PORRET
  FROM fza_compras_sesiones S
  LEFT JOIN fza_empresas E
    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES
  LEFT JOIN fza_ivas IVS
    ON IVS.CODIGO_IVA = NULLIF(S.CODIGO_IVA_SES, '')
  LEFT JOIN tmp_ses_iva_empresa IE
    ON IE.CODIGO_EMP_EMP = S.CODIGO_EMP_SES
  LEFT JOIN fza_ivas IVE
    ON IVE.CODIGO_IVA = IE.CODIGO_IVA;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_bases;
CREATE TEMPORARY TABLE tmp_ses_bases AS
SELECT L.SERIE_SES_SESLIN AS SERIE_SES,
       L.NUMERO_SES_SESLIN AS NUMERO_SES,
       CASE UPPER(TRIM(CASE
                         WHEN COALESCE(S.ESVARIOS_TIPOS_IVA_SES, 'N') = 'S' AND
                              COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''), '') <> '' THEN
                           L.TIPO_IVA_SESLIN
                         ELSE
                           S.TIPO_IVA_SES
                       END))
         WHEN 'R' THEN
           'R'
         WHEN 'S' THEN
           'S'
         WHEN 'E' THEN
           'E'
         ELSE
           'N'
       END AS TIPO_IVA,
       SUM(COALESCE(L.TOTAL_LINEA_SESLIN, 0)) AS BASE
  FROM fza_compras_sesiones_lineas L
  JOIN fza_compras_sesiones S
    ON S.SERIE_SES = L.SERIE_SES_SESLIN
   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN
 GROUP BY L.SERIE_SES_SESLIN,
          L.NUMERO_SES_SESLIN,
          CASE UPPER(TRIM(CASE
                            WHEN COALESCE(S.ESVARIOS_TIPOS_IVA_SES, 'N') = 'S' AND
                                 COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''), '') <> '' THEN
                              L.TIPO_IVA_SESLIN
                            ELSE
                              S.TIPO_IVA_SES
                          END))
            WHEN 'R' THEN
              'R'
            WHEN 'S' THEN
              'S'
            WHEN 'E' THEN
              'E'
            ELSE
              'N'
          END;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_resumen_base;
CREATE TEMPORARY TABLE tmp_ses_resumen_base AS
SELECT S.SERIE_SES,
       S.NUMERO_SES,
       I.CODIGO_IVA,
       I.IVAN,
       I.IVAR,
       I.IVAS,
       I.IVAE,
       I.REN,
       I.RER,
       I.RES,
       I.REE,
       I.ESRECARGO,
       I.PORRET,
       COALESCE(SUM(CASE WHEN B.TIPO_IVA = 'N' THEN B.BASE ELSE 0 END), 0) AS BASE_N,
       COALESCE(SUM(CASE WHEN B.TIPO_IVA = 'R' THEN B.BASE ELSE 0 END), 0) AS BASE_R,
       COALESCE(SUM(CASE WHEN B.TIPO_IVA = 'S' THEN B.BASE ELSE 0 END), 0) AS BASE_S,
       COALESCE(SUM(CASE WHEN B.TIPO_IVA = 'E' THEN B.BASE ELSE 0 END), 0) AS BASE_E
  FROM fza_compras_sesiones S
  LEFT JOIN tmp_ses_iva I
    ON I.SERIE_SES = S.SERIE_SES
   AND I.NUMERO_SES = S.NUMERO_SES
  LEFT JOIN tmp_ses_bases B
    ON B.SERIE_SES = S.SERIE_SES
   AND B.NUMERO_SES = S.NUMERO_SES
 GROUP BY S.SERIE_SES,
          S.NUMERO_SES,
          I.CODIGO_IVA,
          I.IVAN,
          I.IVAR,
          I.IVAS,
          I.IVAE,
          I.REN,
          I.RER,
          I.RES,
          I.REE,
          I.ESRECARGO,
          I.PORRET;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_resumen_importes;
CREATE TEMPORARY TABLE tmp_ses_resumen_importes AS
SELECT R.SERIE_SES,
       R.NUMERO_SES,
       R.CODIGO_IVA,
       R.IVAN,
       R.IVAR,
       R.IVAS,
       R.IVAE,
       CASE WHEN R.ESRECARGO = 'S' THEN R.REN ELSE 0 END AS REN,
       CASE WHEN R.ESRECARGO = 'S' THEN R.RER ELSE 0 END AS RER,
       CASE WHEN R.ESRECARGO = 'S' THEN R.RES ELSE 0 END AS RES,
       CASE WHEN R.ESRECARGO = 'S' THEN R.REE ELSE 0 END AS REE,
       R.PORRET,
       R.BASE_N,
       R.BASE_R,
       R.BASE_S,
       R.BASE_E,
       R.BASE_N * R.IVAN / 100 AS IVA_N,
       R.BASE_R * R.IVAR / 100 AS IVA_R,
       R.BASE_S * R.IVAS / 100 AS IVA_S,
       R.BASE_E * R.IVAE / 100 AS IVA_E,
       CASE WHEN R.ESRECARGO = 'S' THEN R.BASE_N * R.REN / 100 ELSE 0 END AS RE_N,
       CASE WHEN R.ESRECARGO = 'S' THEN R.BASE_R * R.RER / 100 ELSE 0 END AS RE_R,
       CASE WHEN R.ESRECARGO = 'S' THEN R.BASE_S * R.RES / 100 ELSE 0 END AS RE_S,
       CASE WHEN R.ESRECARGO = 'S' THEN R.BASE_E * R.REE / 100 ELSE 0 END AS RE_E
  FROM tmp_ses_resumen_base R;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_resumen;
CREATE TEMPORARY TABLE tmp_ses_resumen AS
SELECT R.SERIE_SES,
       R.NUMERO_SES,
       R.CODIGO_IVA,
       R.IVAN,
       R.IVAR,
       R.IVAS,
       R.IVAE,
       R.REN,
       R.RER,
       R.RES,
       R.REE,
       R.PORRET,
       R.BASE_N,
       R.BASE_R,
       R.BASE_S,
       R.BASE_E,
       R.IVA_N,
       R.IVA_R,
       R.IVA_S,
       R.IVA_E,
       R.RE_N,
       R.RE_R,
       R.RE_S,
       R.RE_E,
       R.BASE_N + R.BASE_R + R.BASE_S + R.BASE_E AS TOTAL_BASES,
       R.IVA_N + R.IVA_R + R.IVA_S + R.IVA_E +
       R.RE_N + R.RE_R + R.RE_S + R.RE_E AS TOTAL_IMPUESTOS,
       (R.BASE_N + R.BASE_R + R.BASE_S + R.BASE_E) *
       R.PORRET / 100 AS TOTAL_RETENCION
  FROM tmp_ses_resumen_importes R;
UPDATE fza_compras_sesiones S
  JOIN tmp_ses_resumen R
    ON R.SERIE_SES = S.SERIE_SES
   AND R.NUMERO_SES = S.NUMERO_SES
   SET S.CODIGO_IVA_SES = R.CODIGO_IVA,
       S.PORCENTAJE_IVAN_SES = R.IVAN,
       S.PORCENTAJE_IVAR_SES = R.IVAR,
       S.PORCENTAJE_IVAS_SES = R.IVAS,
       S.PORCENTAJE_IVAE_SES = R.IVAE,
       S.PORCENTAJE_REN_SES = R.REN,
       S.PORCENTAJE_RER_SES = R.RER,
       S.PORCENTAJE_RES_SES = R.RES,
       S.PORCENTAJE_REE_SES = R.REE,
       S.TOTAL_BASEI_IVAN_SES = R.BASE_N,
       S.TOTAL_BASEI_IVAR_SES = R.BASE_R,
       S.TOTAL_BASEI_IVAS_SES = R.BASE_S,
       S.TOTAL_BASEI_IVAE_SES = R.BASE_E,
       S.TOTAL_IVAN_SES = R.IVA_N,
       S.TOTAL_IVAR_SES = R.IVA_R,
       S.TOTAL_IVAS_SES = R.IVA_S,
       S.TOTAL_IVAE_SES = R.IVA_E,
       S.TOTAL_REN_SES = R.RE_N,
       S.TOTAL_RER_SES = R.RE_R,
       S.TOTAL_RES_SES = R.RE_S,
       S.TOTAL_REE_SES = R.RE_E,
       S.TOTAL_BRUTO_SES = R.TOTAL_BASES,
       S.TOTAL_BASES_SES = R.TOTAL_BASES,
       S.TOTAL_IMPUESTOS_SES = R.TOTAL_IMPUESTOS,
       S.TOTAL_RETENCION_SES = R.TOTAL_RETENCION,
       S.TOTAL_SES = R.TOTAL_BASES + R.TOTAL_IMPUESTOS,
       S.TOTAL_LIQUIDO_SES = R.TOTAL_BASES +
                             R.TOTAL_IMPUESTOS -
                             R.TOTAL_RETENCION;
SELECT COUNT(*) AS SESIONES_RECALCULADAS
  FROM tmp_ses_resumen;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_resumen;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_resumen_importes;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_resumen_base;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_bases;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_iva;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_iva_empresa;
DROP TEMPORARY TABLE IF EXISTS tmp_ses_lineas_totales;
