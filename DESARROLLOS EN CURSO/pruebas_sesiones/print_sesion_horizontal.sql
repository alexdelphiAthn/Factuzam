-- ============================================================================
-- Pruebas — Sesion de compra: impresion HORIZONTAL (apaisado) con tallas
-- pivotadas en columnas (max 20 = CANT_TALLAS_MAX).
--
-- Esta prueba aporta SOLO objetos de impresion (no toca el modelo
-- transaccional). Todo idempotente.
--
--   1. ALTER fza_atributos_conjuntos: nueva columna NOMBRE_CORTO_AC
--      (abreviatura del sistema de tallas para que quepa en el informe:
--      CAB, SRA, EUR, LETR, NUM, etc.). Si esta NULL, el informe pinta
--      las primeras letras de NOMBRE_AC (fallback en la vista).
--
--   2. Vista vi_compras_sesiones_cab_print
--      Cabecera de sesion enriquecida (empresa + proveedor + datos
--      fiscales + serie/numero/fecha/totales).
--
--   3. Vista vi_compras_sesiones_lin_print
--      Lineas con las 20 columnas T01..T20 pivotadas desde
--      fza_compras_sesiones_celdas. La posicion T01..T20 = ROW_NUMBER()
--      sobre fza_atributos_conjuntos_det ordenado por ORDEN_ACD.
--
--   4. Vista vi_compras_sesiones_guias_print
--      Cada sistema de tallas usado en la sesion + sus rotulos T01..T20
--      (de fza_atributos_valores). Se pinta en una banda Header del
--      informe como "leyenda" para que el lector sepa, p.ej., que la
--      columna T03 en el sistema SRA es la talla 38 y en CAB es la M.
--      Devuelve TODOS los conjuntos activos; el modal filtra por sesion.
--
--   5. UPDATE inicial de NOMBRE_CORTO_AC para los conjuntos demo.
--
-- Requiere MariaDB >= 10.2 (ROW_NUMBER OVER) o MySQL >= 8.0.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna NOMBRE_CORTO_AC en fza_atributos_conjuntos
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_atributos_conjuntos'
     AND COLUMN_NAME  = 'NOMBRE_CORTO_AC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_atributos_conjuntos` '
  'ADD COLUMN `NOMBRE_CORTO_AC` varchar(12) DEFAULT NULL '
  '  COMMENT ''Abreviatura del sistema para impresion (CAB, SRA, EUR, LETR, NUM). '
  'NULL = fallback al inicio de NOMBRE_AC.'' '
  'AFTER `NOMBRE_AC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Vista de cabecera para impresion
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_compras_sesiones_cab_print` AS
SELECT
  ses.`SERIE_SES`,
  ses.`NUMERO_SES`,
  ses.`FECHA_SES`,
  ses.`ESTADO_SES`,
  ses.`REF_PRV_SES`,
  ses.`COMENTARIOS_SES`,
  ses.`PORCENTAJE_MARGEN_SES`,
  ses.`MULTIPLO_REDONDEO_SES`,
  ses.`AJUSTE_FINAL_SES`,
  ses.`MONEDA_SES`,
  ses.`TIPO_IVA_SES`,
  ses.`CODIGO_EMP_SES`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  ses.`CODIGO_PRV_SES`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  ses.`CODIGO_TAR_SES`,
  ses.`CODIGO_FAM_SES`,
  ses.`CODIGO_ALM_SES`,
  ses.`INSTANTE_ALTA`,
  ses.`USUARIO_ALTA`,
  -- Totales agregados de la sesion (suma de cantidades y totales)
  (SELECT COALESCE(SUM(`TOTAL_UNIDADES_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `TOTAL_UNIDADES_SES`,
  (SELECT COALESCE(SUM(`TOTAL_LINEA_SESLIN`), 0)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `TOTAL_LINEAS_SES`,
  (SELECT COUNT(*)
     FROM `fza_compras_sesiones_lineas` lin
    WHERE lin.`SERIE_SES_SESLIN`  = ses.`SERIE_SES`
      AND lin.`NUMERO_SES_SESLIN` = ses.`NUMERO_SES`) AS `NUM_LINEAS_SES`
FROM `fza_compras_sesiones` ses
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = ses.`CODIGO_EMP_SES`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = ses.`CODIGO_PRV_SES`;

-- ---------------------------------------------------------------------------
-- 3. Vista de lineas con tallas pivotadas T01..T20
-- ---------------------------------------------------------------------------
-- El pivot usa ROW_NUMBER() sobre fza_atributos_conjuntos_det para
-- mapear cada valor (ID_AV) del conjunto pivot de la linea a una
-- posicion 1..20 estable independiente de ORDEN_ACD. Si el conjunto
-- tiene >20 valores, las posiciones 21+ se descartan (consistente con
-- CANT_TALLAS_MAX del form de prueba).
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
  lin.`TOTAL_UNIDADES_SESLIN`      AS `TOTAL_UNIDADES`,
  lin.`TOTAL_LINEA_SESLIN`         AS `TOTAL_LINEA`,
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
LEFT JOIN `fza_atributos_conjuntos` ac
       ON ac.`ID_AC` = lin.`ID_AC_PIVOT_SESLIN`
LEFT JOIN `fza_compras_sesiones_celdas` cel
       ON cel.`SERIE_SES_SESCEL`  = lin.`SERIE_SES_SESLIN`
      AND cel.`NUMERO_SES_SESCEL` = lin.`NUMERO_SES_SESLIN`
      AND cel.`LINEA_SES_SESCEL`  = lin.`LINEA_SESLIN`
LEFT JOIN `pos_acd` p
       ON p.`ID_AC` = lin.`ID_AC_PIVOT_SESLIN`
      AND p.`ID_AV` = cel.`ID_AV_PIVOT_SESCEL`
GROUP BY
  lin.`SERIE_SES_SESLIN`,  lin.`NUMERO_SES_SESLIN`,  lin.`LINEA_SESLIN`,
  lin.`CODIGO_ART_TENTATIVO_SESLIN`, lin.`REF_PRV_SESLIN`,
  lin.`DESCRIPCION_SESLIN`, lin.`COLOR_TEXTO_SESLIN`,
  lin.`CODIGO_ATB_COLOR_SESLIN`,
  lin.`PRECIO_COMPRA_SESLIN`, lin.`PRECIO_VENTA_SESLIN`,
  lin.`ID_AC_PIVOT_SESLIN`, ac.`NOMBRE_AC`, ac.`NOMBRE_CORTO_AC`,
  lin.`TOTAL_UNIDADES_SESLIN`, lin.`TOTAL_LINEA_SESLIN`;

-- ---------------------------------------------------------------------------
-- 4. Vista de guias de tallas (leyenda en cabecera del informe)
-- ---------------------------------------------------------------------------
-- Devuelve por cada sistema (conjunto) sus rotulos T01..T20 (los valores
-- AV de fza_atributos_valores). El modal filtra a los sistemas que
-- realmente aparecen en las lineas de la sesion en curso.
CREATE OR REPLACE VIEW `vi_compras_sesiones_guias_print` AS
WITH `pos_acd` AS (
  SELECT
    acd.`ID_AC_ACD` AS `ID_AC`,
    acd.`ID_AV_ACD` AS `ID_AV`,
    av.`AV`,
    ROW_NUMBER() OVER (
      PARTITION BY acd.`ID_AC_ACD`
      ORDER BY acd.`ORDEN_ACD`, acd.`ID_AV_ACD`
    ) AS `POSICION`
  FROM `fza_atributos_conjuntos_det` acd
  INNER JOIN `fza_atributos_valores` av ON av.`ID_AV` = acd.`ID_AV_ACD`
)
SELECT
  ac.`ID_AC`,
  ac.`NOMBRE_AC`,
  COALESCE(ac.`NOMBRE_CORTO_AC`, UPPER(LEFT(ac.`NOMBRE_AC`, 8))) AS `NOMBRE_CORTO_AC`,
  MAX(CASE WHEN p.`POSICION` =  1 THEN p.`AV` END) AS `T01`,
  MAX(CASE WHEN p.`POSICION` =  2 THEN p.`AV` END) AS `T02`,
  MAX(CASE WHEN p.`POSICION` =  3 THEN p.`AV` END) AS `T03`,
  MAX(CASE WHEN p.`POSICION` =  4 THEN p.`AV` END) AS `T04`,
  MAX(CASE WHEN p.`POSICION` =  5 THEN p.`AV` END) AS `T05`,
  MAX(CASE WHEN p.`POSICION` =  6 THEN p.`AV` END) AS `T06`,
  MAX(CASE WHEN p.`POSICION` =  7 THEN p.`AV` END) AS `T07`,
  MAX(CASE WHEN p.`POSICION` =  8 THEN p.`AV` END) AS `T08`,
  MAX(CASE WHEN p.`POSICION` =  9 THEN p.`AV` END) AS `T09`,
  MAX(CASE WHEN p.`POSICION` = 10 THEN p.`AV` END) AS `T10`,
  MAX(CASE WHEN p.`POSICION` = 11 THEN p.`AV` END) AS `T11`,
  MAX(CASE WHEN p.`POSICION` = 12 THEN p.`AV` END) AS `T12`,
  MAX(CASE WHEN p.`POSICION` = 13 THEN p.`AV` END) AS `T13`,
  MAX(CASE WHEN p.`POSICION` = 14 THEN p.`AV` END) AS `T14`,
  MAX(CASE WHEN p.`POSICION` = 15 THEN p.`AV` END) AS `T15`,
  MAX(CASE WHEN p.`POSICION` = 16 THEN p.`AV` END) AS `T16`,
  MAX(CASE WHEN p.`POSICION` = 17 THEN p.`AV` END) AS `T17`,
  MAX(CASE WHEN p.`POSICION` = 18 THEN p.`AV` END) AS `T18`,
  MAX(CASE WHEN p.`POSICION` = 19 THEN p.`AV` END) AS `T19`,
  MAX(CASE WHEN p.`POSICION` = 20 THEN p.`AV` END) AS `T20`
FROM `fza_atributos_conjuntos` ac
INNER JOIN `pos_acd` p ON p.`ID_AC` = ac.`ID_AC`
WHERE p.`POSICION` <= 20
  AND ac.`ESACTIVO_AC` = 'S'
GROUP BY ac.`ID_AC`, ac.`NOMBRE_AC`, ac.`NOMBRE_CORTO_AC`;

-- ---------------------------------------------------------------------------
-- 5. Abreviaturas iniciales (datos demo)
-- ---------------------------------------------------------------------------
UPDATE `fza_atributos_conjuntos`
   SET `NOMBRE_CORTO_AC` = CASE
     WHEN `NOMBRE_AC` LIKE '%Hombre%Standard%' OR `NOMBRE_AC` LIKE '%Hombre%(%)%'
       THEN 'CAB'
     WHEN `NOMBRE_AC` LIKE '%Mujer%(%)%' OR `NOMBRE_AC` LIKE '%Mujer%Standard%'
       THEN 'SRA'
     WHEN `NOMBRE_AC` LIKE 'Tallas Calzado Hombre%'
       THEN 'EUR-H'
     WHEN `NOMBRE_AC` LIKE 'Tallas Calzado Mujer%'
       THEN 'EUR-M'
     WHEN `NOMBRE_AC` LIKE 'Colores%'
       THEN 'COL'
     ELSE `NOMBRE_CORTO_AC`
   END
 WHERE `NOMBRE_CORTO_AC` IS NULL;
