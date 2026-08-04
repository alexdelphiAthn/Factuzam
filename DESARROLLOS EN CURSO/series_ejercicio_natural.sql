-- Series de empresa resueltas por fecha natural
-- Tokens reservados: yyyy, q, mm y dd
SET @iExisteColumna = (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas'
     AND COLUMN_NAME = 'ESTOKENS_CALENDARIO_NATURAL_EMP'
);
SET @sSql = IF(
  @iExisteColumna = 0,
  'ALTER TABLE fza_empresas ADD COLUMN ESTOKENS_CALENDARIO_NATURAL_EMP varchar(1) NOT NULL DEFAULT ''N''',
  'SELECT 1'
);
PREPARE oSentencia FROM @sSql;
EXECUTE oSentencia;
DEALLOCATE PREPARE oSentencia;
SET @iExisteColumna = (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_empresas_series'
     AND COLUMN_NAME = 'SERIE_TOKENIZADA_EMPSER'
);
SET @sSql = IF(
  @iExisteColumna = 0,
  'ALTER TABLE fza_empresas_series ADD COLUMN SERIE_TOKENIZADA_EMPSER varchar(12) NULL DEFAULT NULL AFTER EMPSER',
  'SELECT 1'
);
PREPARE oSentencia FROM @sSql;
EXECUTE oSentencia;
DEALLOCATE PREPARE oSentencia;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_empresas` AS
SELECT e.*,
       g.`DESCRIPCION_IVA_IVAGRP` AS `DESCRIPCION_IVA_IVAGRP`
  FROM `fza_empresas` e
  LEFT JOIN `fza_ivas_grupos` g
    ON e.`GRUPO_ZONA_IVA_EMP` = g.`IVA_IVAGRP`
 ORDER BY e.`ORDEN_EMP`;
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_empresas_series` AS
SELECT s.`CODIGO_SERIE_EMPSER` AS `CODIGO_SERIE_EMPSER`,
       s.`CODIGO_EMP_EMPSER` AS `CODIGO_EMP_EMPSER`,
       s.`CODIGO_ALM_EMPSER` AS `CODIGO_ALM_EMPSER`,
       s.`CODIGO_CAJA_EMPSER` AS `CODIGO_CAJA_EMPSER`,
       CASE
         WHEN e.`ESTOKENS_CALENDARIO_NATURAL_EMP` = 'S'
          AND NULLIF(TRIM(s.`SERIE_TOKENIZADA_EMPSER`), '') IS NOT NULL
          AND CHAR_LENGTH(TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) -
              CHAR_LENGTH(REPLACE(
                TRIM(s.`SERIE_TOKENIZADA_EMPSER`), 'yyyy', ''))
              IN (0, 4)
          AND CHAR_LENGTH(TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) -
              CHAR_LENGTH(REPLACE(
                TRIM(s.`SERIE_TOKENIZADA_EMPSER`), 'q', ''))
              IN (0, 1)
          AND CHAR_LENGTH(TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) -
              CHAR_LENGTH(REPLACE(
                TRIM(s.`SERIE_TOKENIZADA_EMPSER`), 'mm', ''))
              IN (0, 2)
          AND CHAR_LENGTH(TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) -
              CHAR_LENGTH(REPLACE(
                TRIM(s.`SERIE_TOKENIZADA_EMPSER`), 'dd', ''))
              IN (0, 2)
          AND (LOCATE(BINARY 'yyyy',
                      BINARY TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) > 0
            OR LOCATE(BINARY 'q',
                      BINARY TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) > 0
            OR LOCATE(BINARY 'mm',
                      BINARY TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) > 0
            OR LOCATE(BINARY 'dd',
                      BINARY TRIM(s.`SERIE_TOKENIZADA_EMPSER`)) > 0)
         THEN REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      TRIM(s.`SERIE_TOKENIZADA_EMPSER`),
                      'yyyy', CAST(YEAR(CURDATE()) AS CHAR)),
                    'mm', DATE_FORMAT(CURDATE(), '%m')),
                  'dd', DATE_FORMAT(CURDATE(), '%d')),
                'q', CAST(QUARTER(CURDATE()) AS CHAR))
         ELSE s.`EMPSER`
       END AS `EMPSER`,
       s.`SERIE_TOKENIZADA_EMPSER` AS `SERIE_TOKENIZADA_EMPSER`,
       s.`TIPO_DOC_EMPSER` AS `TIPO_DOC_EMPSER`,
       s.`SUBTIPO_EMPSER` AS `SUBTIPO_EMPSER`,
       s.`FECHA_DESDE_EMPSER` AS `FECHA_DESDE_EMPSER`,
       s.`FECHA_HASTA_EMPSER` AS `FECHA_HASTA_EMPSER`,
       s.`INSTANTE_MODIF` AS `INSTANTE_MODIF`,
       s.`INSTANTE_ALTA` AS `INSTANTE_ALTA`,
       s.`USUARIO_ALTA` AS `USUARIO_ALTA`,
       s.`USUARIO_MODIF` AS `USUARIO_MODIF`
  FROM `fza_empresas_series` s
  LEFT JOIN `fza_empresas` e
    ON e.`CODIGO_EMP_EMP` = s.`CODIGO_EMP_EMPSER`;
SELECT `CODIGO_EMP_EMPSER`,
       `EMPSER`,
       `SERIE_TOKENIZADA_EMPSER`
  FROM `vi_empresas_series`
 WHERE NULLIF(TRIM(`SERIE_TOKENIZADA_EMPSER`), '') IS NOT NULL;
