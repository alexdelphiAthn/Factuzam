-- =============================================================================
-- Vistas para la impresion de la factura de compra
-- Analogo a las vistas *_print de compras, contra el modelo de facturas
-- de compra (cabecera + lineas; sin tabla de celdas separada - los SKUs
-- viven directamente en fza_facturas_compra_lineas y la talla se deduce
-- del atributo CO/TAL del SKU).
--
-- Script idempotente: CREATE OR REPLACE, se puede aplicar repetidamente.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Cabecera enriquecida (empresa + proveedor + almacen destino + totales)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_facturas_compra_cab_print` AS
SELECT
  fac.`SERIE_FACC`,
  fac.`NUMERO_FACC`,
  CASE
    WHEN TRIM(COALESCE(fac.`SERIE_FACC`, '')) = ''
      THEN TRIM(COALESCE(fac.`NUMERO_FACC`, ''))
    WHEN TRIM(COALESCE(fac.`NUMERO_FACC`, '')) = ''
      THEN TRIM(COALESCE(fac.`SERIE_FACC`, ''))
    ELSE CONCAT(TRIM(COALESCE(fac.`SERIE_FACC`, '')), '.',
                TRIM(COALESCE(fac.`NUMERO_FACC`, '')))
  END AS `DOCUMENTO_FORMATO`,
  fac.`FECHA_FACC`,
  fac.`ESTADO_FACC`,
  fac.`REF_PROVEEDOR_FACC`,
  fac.`COMENTARIOS_FACC`,
  fac.`OBSERVACIONES_FACC`,
  fac.`CODIGO_EMP_FACC`,
  emp.`RAZON_SOCIAL_EMP`,
  emp.`DIRECCION1_EMP`,
  emp.`CODIGO_POSTAL_EMP`,
  emp.`POBLACION_EMP`,
  emp.`PROVINCIA_EMP`,
  emp.`NIF_EMP`        AS `CIF_EMP`,
  emp.`MOVIL_EMP`      AS `TELEFONO1_EMP`,
  fac.`CODIGO_PRV_FACC`,
  prv.`RAZON_SOCIAL_PRV`,
  prv.`DIRECCION1_PRV`,
  prv.`CODIGO_POSTAL_PRV`,
  prv.`POBLACION_PRV`,
  prv.`PROVINCIA_PRV`,
  prv.`NIF_PRV`        AS `CIF_PRV`,
  COALESCE(prv.`TELEFONO_PRV`, prv.`MOVIL_PRV`) AS `TELEFONO1_PRV`,
  -- Almacen destino: el codigo vive en la cabecera (CODIGO_ALM_FACC) y
  -- los datos descriptivos se resuelven via JOIN a fza_almacenes. No
  -- snapshoteamos como con empresa/proveedor: si cambia la direccion
  -- del almacen, las facturas historicas mostraran la actual.
  fac.`CODIGO_ALM_FACC`,
  alm.`NOMBRE_ALM_ALM`  AS `NOMBRE_ALM_FACC`,
  alm.`DIRECCION_ALM`   AS `DIRECCION_ALM_FACC`,
  alm.`CODIGO_POSTAL_ALM` AS `CODIGO_POSTAL_ALM_FACC`,
  alm.`POBLACION_ALM`   AS `POBLACION_ALM_FACC`,
  alm.`PROVINCIA_ALM`   AS `PROVINCIA_ALM_FACC`,
  alm.`TELEFONO_ALM`    AS `TELEFONO_ALM_FACC`,
  alm.`EMAIL_ALM`       AS `EMAIL_ALM_FACC`,
  fac.`CODIGO_IVA_FACC`,
  fac.`ESIVA_RECARGO_COMPRAS_FACC`,
  fac.`PORCENTAJE_IVAN_FACC`,
  fac.`TOTAL_BASEI_IVAN_FACC`,
  fac.`TOTAL_IVAN_FACC`,
  fac.`PORCENTAJE_REN_FACC`,
  fac.`TOTAL_REN_FACC`,
  fac.`PORCENTAJE_IVAR_FACC`,
  fac.`TOTAL_BASEI_IVAR_FACC`,
  fac.`TOTAL_IVAR_FACC`,
  fac.`PORCENTAJE_RER_FACC`,
  fac.`TOTAL_RER_FACC`,
  fac.`PORCENTAJE_IVAS_FACC`,
  fac.`TOTAL_BASEI_IVAS_FACC`,
  fac.`TOTAL_IVAS_FACC`,
  fac.`PORCENTAJE_RES_FACC`,
  fac.`TOTAL_RES_FACC`,
  fac.`PORCENTAJE_IVAE_FACC`,
  fac.`TOTAL_BASEI_IVAE_FACC`,
  fac.`TOTAL_IVAE_FACC`,
  fac.`PORCENTAJE_REE_FACC`,
  fac.`TOTAL_REE_FACC`,
  fac.`PORCENTAJE_RETENCION_FACC`,
  fac.`TOTAL_RETENCION_FACC`,
  fac.`TOTAL_BASES_FACC`,
  fac.`TOTAL_IMPUESTOS_FACC`,
  fac.`TOTAL_LIQUIDO_FACC`,
  fac.`INSTANTE_ALTA`,
  fac.`USUARIO_ALTA`,
  -- Agregados de las lineas
  (SELECT COALESCE(SUM(`CANTIDAD_FACCLIN`), 0)
     FROM `fza_facturas_compra_lineas` lin
    WHERE lin.`SERIE_FACC_FACCLIN`  = fac.`SERIE_FACC`
      AND lin.`NUMERO_FACC_FACCLIN` = fac.`NUMERO_FACC`) AS `TOTAL_UNIDADES_FACC`,
  (SELECT COALESCE(SUM(`TOTAL_FACCLIN`), 0)
     FROM `fza_facturas_compra_lineas` lin
    WHERE lin.`SERIE_FACC_FACCLIN`  = fac.`SERIE_FACC`
      AND lin.`NUMERO_FACC_FACCLIN` = fac.`NUMERO_FACC`) AS `TOTAL_LINEAS_FACC`,
  (SELECT COUNT(*)
     FROM `fza_facturas_compra_lineas` lin
    WHERE lin.`SERIE_FACC_FACCLIN`  = fac.`SERIE_FACC`
      AND lin.`NUMERO_FACC_FACCLIN` = fac.`NUMERO_FACC`) AS `NUM_LINEAS_FACC`
FROM `fza_facturas_compra` fac
LEFT JOIN `fza_empresas`     emp ON emp.`CODIGO_EMP_EMP` = fac.`CODIGO_EMP_FACC`
LEFT JOIN `fza_proveedores`  prv ON prv.`CODIGO_PRV_PRV` = fac.`CODIGO_PRV_FACC`
LEFT JOIN `fza_almacenes`    alm ON alm.`CODIGO_ALM_ALM` = fac.`CODIGO_ALM_FACC`;

-- ---------------------------------------------------------------------------
-- 2. Lineas con T01..T20 pivotadas por talla
-- ---------------------------------------------------------------------------
-- Como en factura cada linea ya es un SKU, agrupamos por (articulo, color
-- derivado del SKU, ID_AC_PIVOT, almacen destino) y sumamos
-- CANTIDAD_FACCLIN en la posicion correspondiente del conjunto pivot. La
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
-- Tambien forma parte de la clave el CODIGO_ALMACEN_FACCLIN: en facturas
-- agrupadas (mezclan varios almacenes destino aunque la cabecera tenga
-- uno principal) las lineas de un mismo articulo en distintos almacenes
-- aparecen como filas separadas, una por almacen, para que el .frx pueda
-- imprimir junto a cada linea el almacen al que va destinada.
CREATE OR REPLACE VIEW `vi_facturas_compra_lin_print` AS
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
  L.`SERIE_FACC_FACCLIN`            AS `SERIE_FACC`,
  L.`NUMERO_FACC_FACCLIN`           AS `NUMERO_FACC`,
  MIN(L.`LINEA_FACCLIN`)            AS `LINEA_FACC`,
  L.`CODIGO_ART_FACCLIN`            AS `CODIGO_ART`,
  COALESCE(MIN(L.`REF_PRV_FACCLIN`), '') AS `REF_PRV`,
  MIN(L.`DESCRIPCION_ARTICULO_FACCLIN`) AS `DESCRIPCION`,
  COALESCE(MIN(sc.`NOMBRE_COLOR`),
           SUBSTRING_INDEX(SUBSTRING_INDEX(MIN(L.`CODIGO_UNIDAD_FACCLIN`), '/', 2), '/', -1),
           '')                      AS `COLOR_TEXTO`,
  COALESCE(MIN(sc.`CODIGO_ATB_COLOR`), '') AS `CODIGO_ATB_COLOR`,
  AVG(L.`PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN`) AS `PRECIO_COMPRA`,
  0                                 AS `PRECIO_VENTA`,
  L.`ID_AC_PIVOT_FACCLIN`           AS `ID_AC_PIVOT`,
  ac.`NOMBRE_AC`,
  COALESCE(ac.`NOMBRE_CORTO_AC`, UPPER(LEFT(ac.`NOMBRE_AC`, 8))) AS `NOMBRE_CORTO_AC`,
  -- Almacen destino de la linea (clave de agrupacion). El JOIN a
  -- fza_almacenes expone los campos descriptivos del almacen para
  -- que el .frx los pueda imprimir junto a cada linea. Si la
  -- cabecera CODIGO_ALM_FACC coincide con todas las lineas, ambos
  -- niveles muestran lo mismo; en facturas agrupadas con varios
  -- almacenes, cada linea reflejara su propio destino.
  L.`CODIGO_ALMACEN_FACCLIN`        AS `CODIGO_ALM_FACCLIN`,
  MIN(alm.`CODIGO_EMP_ALM`)         AS `CODIGO_EMP_ALM_FACCLIN`,
  MIN(alm.`NOMBRE_ALM_ALM`)         AS `NOMBRE_ALM_FACCLIN`,
  MIN(alm.`DIRECCION_ALM`)          AS `DIRECCION_ALM_FACCLIN`,
  MIN(alm.`CODIGO_POSTAL_ALM`)      AS `CODIGO_POSTAL_ALM_FACCLIN`,
  MIN(alm.`POBLACION_ALM`)          AS `POBLACION_ALM_FACCLIN`,
  MIN(alm.`PROVINCIA_ALM`)          AS `PROVINCIA_ALM_FACCLIN`,
  MIN(alm.`TELEFONO_ALM`)           AS `TELEFONO_ALM_FACCLIN`,
  MIN(alm.`EMAIL_ALM`)              AS `EMAIL_ALM_FACCLIN`,
  SUM(L.`CANTIDAD_FACCLIN`)         AS `TOTAL_UNIDADES`,
  SUM(L.`TOTAL_FACCLIN`)            AS `TOTAL_LINEA`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  1 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T01`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  2 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T02`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  3 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T03`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  4 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T04`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  5 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T05`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  6 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T06`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  7 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T07`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  8 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T08`,
  COALESCE(SUM(CASE WHEN p.`POSICION` =  9 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T09`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 10 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T10`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 11 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T11`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 12 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T12`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 13 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T13`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 14 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T14`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 15 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T15`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 16 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T16`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 17 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T17`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 18 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T18`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 19 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T19`,
  COALESCE(SUM(CASE WHEN p.`POSICION` = 20 THEN L.`CANTIDAD_FACCLIN` END), 0) AS `T20`
FROM `fza_facturas_compra_lineas` L
LEFT JOIN `fza_atributos_conjuntos` ac
       ON ac.`ID_AC` = L.`ID_AC_PIVOT_FACCLIN`
LEFT JOIN `sku_talla` st
       ON st.`CODIGO_UNIDAD` = L.`CODIGO_UNIDAD_FACCLIN`
LEFT JOIN `pos_acd` p
       ON p.`ID_AC` = L.`ID_AC_PIVOT_FACCLIN`
      AND p.`ID_AV` = st.`ID_AV_TALLA`
LEFT JOIN `sku_color` sc
       ON sc.`CODIGO_UNIDAD` = L.`CODIGO_UNIDAD_FACCLIN`
LEFT JOIN `fza_almacenes` alm
       ON alm.`CODIGO_ALM_ALM` = L.`CODIGO_ALMACEN_FACCLIN`
GROUP BY
  L.`SERIE_FACC_FACCLIN`, L.`NUMERO_FACC_FACCLIN`,
  L.`CODIGO_ART_FACCLIN`,
  L.`ID_AC_PIVOT_FACCLIN`, ac.`NOMBRE_AC`, ac.`NOMBRE_CORTO_AC`,
  sc.`CODIGO_ATB_COLOR`, sc.`NOMBRE_COLOR`,
  SUBSTRING_INDEX(SUBSTRING_INDEX(L.`CODIGO_UNIDAD_FACCLIN`, '/', 2), '/', -1),
  L.`CODIGO_ALMACEN_FACCLIN`;

-- ---------------------------------------------------------------------------
-- 3. Guias de tallas (dependen solo de conjuntos)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vi_facturas_compra_guias_print` AS
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
