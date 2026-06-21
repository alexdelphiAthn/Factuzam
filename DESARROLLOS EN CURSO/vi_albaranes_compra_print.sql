-- =============================================================================
-- Vistas para la impresion del albaran de compra
-- Analogo a vi_compras_sesiones_*_print pero contra el modelo de albaranes
-- de compra (cabecera + lineas; sin tabla de celdas separada — los SKUs
-- viven directamente en fza_albaranes_compra_lineas y la talla se deduce
-- del atributo CO/TAL del SKU).
--
-- Script idempotente: CREATE OR REPLACE, se puede aplicar repetidamente.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Cabecera enriquecida (empresa + proveedor + almacen destino + totales)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_albaranes_compra_cab_print` AS
SELECT
  alb.`SERIE_ALBC`,
  alb.`NUMERO_ALBC`,
  alb.`FECHA_ALBC`,
  alb.`ESTADO_ALBC`,
  alb.`REF_PROVEEDOR_ALBC`,
  alb.`COMENTARIOS_ALBC`,
  alb.`OBSERVACIONES_ALBC`,
  alb.`CODIGO_EMP_ALBC`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  alb.`CODIGO_PRV_ALBC`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  -- Almacen destino: el codigo vive en la cabecera (CODIGO_ALM_ALBC) y
  -- los datos descriptivos se resuelven via JOIN a fza_almacenes. No
  -- snapshoteamos como con empresa/proveedor: si cambia la direccion
  -- del almacen, los albaranes historicos mostraran la actual.
  alb.`CODIGO_ALM_ALBC`,
  alm.`NOMBRE_ALM_ALM`  AS `NOMBRE_ALM_ALBC`,
  alm.`DIRECCION_ALM`   AS `DIRECCION_ALM_ALBC`,
  alm.`CODIGO_POSTAL_ALM` AS `CODIGO_POSTAL_ALM_ALBC`,
  alm.`POBLACION_ALM`   AS `POBLACION_ALM_ALBC`,
  alm.`PROVINCIA_ALM`   AS `PROVINCIA_ALM_ALBC`,
  alm.`TELEFONO_ALM`    AS `TELEFONO_ALM_ALBC`,
  alm.`EMAIL_ALM`       AS `EMAIL_ALM_ALBC`,
  alb.`CODIGO_IVA_ALBC`,
  alb.`ESIVA_RECARGO_COMPRAS_ALBC`,
  alb.`PORCENTAJE_IVAN_ALBC`,
  alb.`TOTAL_BASEI_IVAN_ALBC`,
  alb.`TOTAL_IVAN_ALBC`,
  alb.`PORCENTAJE_REN_ALBC`,
  alb.`TOTAL_REN_ALBC`,
  alb.`PORCENTAJE_IVAR_ALBC`,
  alb.`TOTAL_BASEI_IVAR_ALBC`,
  alb.`TOTAL_IVAR_ALBC`,
  alb.`PORCENTAJE_RER_ALBC`,
  alb.`TOTAL_RER_ALBC`,
  alb.`PORCENTAJE_IVAS_ALBC`,
  alb.`TOTAL_BASEI_IVAS_ALBC`,
  alb.`TOTAL_IVAS_ALBC`,
  alb.`PORCENTAJE_RES_ALBC`,
  alb.`TOTAL_RES_ALBC`,
  alb.`PORCENTAJE_IVAE_ALBC`,
  alb.`TOTAL_BASEI_IVAE_ALBC`,
  alb.`TOTAL_IVAE_ALBC`,
  alb.`PORCENTAJE_REE_ALBC`,
  alb.`TOTAL_REE_ALBC`,
  alb.`PORCENTAJE_RETENCION_ALBC`,
  alb.`TOTAL_RETENCION_ALBC`,
  alb.`TOTAL_BASES_ALBC`,
  alb.`TOTAL_IMPUESTOS_ALBC`,
  alb.`TOTAL_LIQUIDO_ALBC`,
  alb.`INSTANTE_ALTA`,
  alb.`USUARIO_ALTA`,
  -- Agregados de las lineas
  (SELECT COALESCE(SUM(`CANTIDAD_ALBCLIN`), 0)
     FROM `fza_albaranes_compra_lineas` lin
    WHERE lin.`SERIE_ALBC_ALBCLIN`  = alb.`SERIE_ALBC`
      AND lin.`NUMERO_ALBC_ALBCLIN` = alb.`NUMERO_ALBC`) AS `TOTAL_UNIDADES_SES`,
  (SELECT COALESCE(SUM(`TOTAL_ALBCLIN`), 0)
     FROM `fza_albaranes_compra_lineas` lin
    WHERE lin.`SERIE_ALBC_ALBCLIN`  = alb.`SERIE_ALBC`
      AND lin.`NUMERO_ALBC_ALBCLIN` = alb.`NUMERO_ALBC`) AS `TOTAL_LINEAS_SES`,
  (SELECT COUNT(*)
     FROM `fza_albaranes_compra_lineas` lin
    WHERE lin.`SERIE_ALBC_ALBCLIN`  = alb.`SERIE_ALBC`
      AND lin.`NUMERO_ALBC_ALBCLIN` = alb.`NUMERO_ALBC`) AS `NUM_LINEAS_SES`
FROM `fza_albaranes_compra` alb
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = alb.`CODIGO_EMP_ALBC`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = alb.`CODIGO_PRV_ALBC`
LEFT JOIN `fza_almacenes`    alm ON alm.`CODIGO_ALM_ALM` = alb.`CODIGO_ALM_ALBC`;

-- ---------------------------------------------------------------------------
-- 2. Lineas con T01..T20 pivotadas por talla
-- ---------------------------------------------------------------------------
-- Como en albaran cada linea ya es un SKU, agrupamos por (articulo, color
-- derivado del SKU, ID_AC_PIVOT, almacen destino) y sumamos
-- CANTIDAD_ALBCLIN en la posicion correspondiente del conjunto pivot. La
-- talla del SKU se obtiene de fza_atributos_sku (atributo con
-- ID_VA_AV='TAL'). El color se obtiene del mismo modo (atributo con
-- ID_VA_AV='CO' -> CODIGO_ATB/NOMBRE_ATB del atributo basico, o fallback
-- al segundo segmento del SKU).
-- IMPORTANTE: el color forma parte de la clave de agrupacion. Sin el, las
-- lineas de varios colores del mismo articulo + sistema de tallas se
-- colapsaban en una unica fila y los SUM por talla sumaban todas las
-- cantidades juntas (impresion horizontal mostraba 1 fila con la suma de
-- los 4 colores). El GROUP BY incluye CODIGO_ATB_COLOR + NOMBRE_COLOR
-- (color via atributo basico) y el segmento medio del SKU (fallback para
-- SKUs sin atributo CO).
-- Tambien forma parte de la clave el CODIGO_ALMACEN_ALBCLIN: en albaranes
-- agrupados (mezclan varios almacenes destino aunque la cabecera tenga
-- uno principal) las lineas de un mismo articulo en distintos almacenes
-- aparecen como filas separadas, una por almacen, para que el .frx pueda
-- imprimir junto a cada linea el almacen al que va destinada.
CREATE OR REPLACE VIEW `vi_albaranes_compra_lin_print` AS
WITH `pos_acd` AS (
  SELECT
    `ID_AC_ACD` AS `ID_AC`,
    `ID_AV_ACD` AS `ID_AV`,
    ROW_NUMBER() OVER (
      PARTITION BY `ID_AC_ACD`
      ORDER BY `ORDEN_ACD`, `ID_AV_ACD`
    ) AS `POSICION`
  FROM `fza_atributos_conjuntos_det`
),
`sku_talla` AS (
  SELECT
    sa.`CODIGO_UNIDAD_SKU_SA` AS `CODIGO_UNIDAD`,
    sa.`ID_AV_SA`             AS `ID_AV_TALLA`
  FROM `fza_atributos_sku` sa
  JOIN `fza_atributos_valores` av
    ON av.`ID_AV` = sa.`ID_AV_SA`
   AND av.`ID_VA_AV` = 'TAL'
),
`sku_color` AS (
  SELECT
    sa.`CODIGO_UNIDAD_SKU_SA` AS `CODIGO_UNIDAD`,
    atb.`CODIGO_ATB`          AS `CODIGO_ATB_COLOR`,
    atb.`NOMBRE_ATB`          AS `NOMBRE_COLOR`
  FROM `fza_atributos_sku` sa
  JOIN `fza_atributos_valores` av
    ON av.`ID_AV` = sa.`ID_AV_SA`
   AND av.`ID_VA_AV` = 'CO'
  LEFT JOIN `fza_atributos_basicos` atb
    ON atb.`ID_ATB` = av.`ID_ATB_AV`
)
SELECT
  L.`SERIE_ALBC_ALBCLIN`            AS `SERIE_ALBC`,
  L.`NUMERO_ALBC_ALBCLIN`           AS `NUMERO_ALBC`,
  MIN(L.`LINEA_ALBCLIN`)            AS `LINEA_ALBC`,
  L.`CODIGO_ART_ALBCLIN`            AS `CODIGO_ART`,
  COALESCE(MIN(L.`REF_PRV_ALBCLIN`), '') AS `REF_PRV`,
  MIN(L.`DESCRIPCION_ARTICULO_ALBCLIN`) AS `DESCRIPCION`,
  COALESCE(MIN(sc.`NOMBRE_COLOR`),
           SUBSTRING_INDEX(SUBSTRING_INDEX(MIN(L.`CODIGO_UNIDAD_ALBCLIN`), '/', 2), '/', -1),
           '')                      AS `COLOR_TEXTO`,
  COALESCE(MIN(sc.`CODIGO_ATB_COLOR`), '') AS `CODIGO_ATB_COLOR`,
  AVG(L.`PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN`) AS `PRECIO_COMPRA`,
  0                                 AS `PRECIO_VENTA`,
  L.`ID_AC_PIVOT_ALBCLIN`           AS `ID_AC_PIVOT`,
  ac.`NOMBRE_AC`,
  COALESCE(ac.`NOMBRE_CORTO_AC`, UPPER(LEFT(ac.`NOMBRE_AC`, 8))) AS `NOMBRE_CORTO_AC`,
  -- Almacen destino de la linea (clave de agrupacion). El JOIN a
  -- fza_almacenes expone los campos descriptivos del almacen para
  -- que el .frx los pueda imprimir junto a cada linea. Si la
  -- cabecera CODIGO_ALM_ALBC coincide con todas las lineas, ambos
  -- niveles muestran lo mismo; en albaranes agrupados con varios
  -- almacenes, cada linea reflejara su propio destino.
  L.`CODIGO_ALMACEN_ALBCLIN`        AS `CODIGO_ALM_ALBCLIN`,
  MIN(alm.`CODIGO_EMP_ALM`)         AS `CODIGO_EMP_ALM_ALBCLIN`,
  MIN(alm.`NOMBRE_ALM_ALM`)         AS `NOMBRE_ALM_ALBCLIN`,
  MIN(alm.`DIRECCION_ALM`)          AS `DIRECCION_ALM_ALBCLIN`,
  MIN(alm.`CODIGO_POSTAL_ALM`)      AS `CODIGO_POSTAL_ALM_ALBCLIN`,
  MIN(alm.`POBLACION_ALM`)          AS `POBLACION_ALM_ALBCLIN`,
  MIN(alm.`PROVINCIA_ALM`)          AS `PROVINCIA_ALM_ALBCLIN`,
  MIN(alm.`TELEFONO_ALM`)           AS `TELEFONO_ALM_ALBCLIN`,
  MIN(alm.`EMAIL_ALM`)              AS `EMAIL_ALM_ALBCLIN`,
  SUM(L.`CANTIDAD_ALBCLIN`)         AS `TOTAL_UNIDADES`,
  SUM(L.`TOTAL_ALBCLIN`)            AS `TOTAL_LINEA`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  1 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T01`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  2 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T02`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  3 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T03`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  4 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T04`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  5 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T05`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  6 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T06`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  7 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T07`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  8 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T08`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  9 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T09`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 10 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T10`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 11 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T11`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 12 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T12`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 13 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T13`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 14 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T14`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 15 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T15`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 16 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T16`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 17 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T17`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 18 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T18`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 19 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T19`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 20 THEN L.`CANTIDAD_ALBCLIN` END), 0) AS `T20`
FROM `fza_albaranes_compra_lineas` L
LEFT JOIN `fza_atributos_conjuntos` ac
       ON ac.`ID_AC` = L.`ID_AC_PIVOT_ALBCLIN`
LEFT JOIN `sku_talla` st
       ON st.`CODIGO_UNIDAD` = L.`CODIGO_UNIDAD_ALBCLIN`
LEFT JOIN `pos_acd` p
       ON p.`ID_AC` = L.`ID_AC_PIVOT_ALBCLIN`
      AND p.`ID_AV` = st.`ID_AV_TALLA`
LEFT JOIN `sku_color` sc
       ON sc.`CODIGO_UNIDAD` = L.`CODIGO_UNIDAD_ALBCLIN`
LEFT JOIN `fza_almacenes` alm
       ON alm.`CODIGO_ALM_ALM` = L.`CODIGO_ALMACEN_ALBCLIN`
GROUP BY
  L.`SERIE_ALBC_ALBCLIN`, L.`NUMERO_ALBC_ALBCLIN`,
  L.`CODIGO_ART_ALBCLIN`,
  L.`ID_AC_PIVOT_ALBCLIN`, ac.`NOMBRE_AC`, ac.`NOMBRE_CORTO_AC`,
  sc.`CODIGO_ATB_COLOR`, sc.`NOMBRE_COLOR`,
  SUBSTRING_INDEX(SUBSTRING_INDEX(L.`CODIGO_UNIDAD_ALBCLIN`, '/', 2), '/', -1),
  L.`CODIGO_ALMACEN_ALBCLIN`;

-- ---------------------------------------------------------------------------
-- 3. Guias de tallas (mismas que en sesiones — depende solo de conjuntos)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_albaranes_compra_guias_print` AS
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
