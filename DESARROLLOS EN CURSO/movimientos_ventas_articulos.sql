-- =====================================================================
-- Movimientos de ventas por artículos y fechas (ranking de ventas).
--
-- Procedimiento PRC_GET_MOV_VENTAS_ART: devuelve UNA fila por artículo
-- (o por artículo+almacén si se agrupa por almacén) con las magnitudes
-- de compra (entradas) y venta del periodo y los dos márgenes pedidos.
-- Es la capa de datos del informe "Movimientos de ventas por artículos
-- y fechas", con el mismo estilo de filtrado que el balance de almacén
-- (almacenes / familias / proveedores / temporadas / artículos) más una
-- fecha extra: "Inicio compras".
--
-- Periodos / fechas:
--   - p_DESDE / p_HASTA  : periodo de VENTAS (fecha de factura). Las
--     columnas Uds Venta / Imp Venta se calculan en esta ventana.
--   - p_INICIO_COMPRAS   : filtra QUÉ artículos salen. Solo aparecen los
--     artículos cuya PRIMERA compra (movimiento de compra AC, entrada) es
--     igual o posterior a esta fecha (p. ej. "artículos comprados a partir
--     de la temporada"). Vacío / NULL = sin restricción. Como el filtro es
--     sobre la primera compra, TODAS las compras del artículo caen dentro
--     de la ventana, así que las entradas totales no necesitan recorte.
--
-- Origen de datos:
--   - Entradas: fza_movimientos_almacen con TIPO_MOV='E' y TIPO_DOC_MOV IN
--     ('AC','AE') = adquisición real de género (compra y albarán de entrada).
--     Se EXCLUYEN: los traspasos (TR/AT/TA), movimientos internos entre
--     almacenes (no es género nuevo); los depósitos (DP), que no son gasto
--     hasta venderse; y el inventario/regularización ('IN'), que es un ajuste,
--     no una compra. Unidades = SUM(CANTIDAD_MOV); importe (coste) =
--     SUM(TOTAL_COSTE_MOV). El filtro "Inicio compras" usa los mismos tipos
--     (AC/AE). (Nota: el dump factuzam_original usa 'IN' para el stock inicial
--     y no tiene 'AE'; en producción las entradas son AC/AE.)
--   - Ventas: fza_facturas_lineas (líneas de factura/ticket) por fecha de
--     factura. Uds = SUM(CANTIDAD_FACLIN); importe = SUM(TOTAL_FACLIN)
--     (venta real, con descuento y con IVA).
--   - Coste de lo vendido: Uds Venta * coste medio ponderado (PMP) del
--     stock actual del artículo (respaldo: último precio de compra del
--     proveedor principal). Misma valoración que el balance de almacén.
--
-- Columnas y márgenes (una fila por artículo):
--   UNI_ENT_TOT = unidades compradas         IMP_ENT_TOT = coste comprado
--   UDS_VENTA   = unidades vendidas           IMP_VENTA   = venta real
--   IMP_COSTE   = coste de lo vendido         BENEFICIO   = IMP_VENTA-IMP_COSTE
--   PCT_BNFCO   = BENEFICIO / IMP_COSTE * 100   (beneficio sobre coste)
--   VENTA_ENT   = IMP_VENTA - IMP_ENT_TOT       (venta menos lo comprado)
--   VENT_ENT    = VENTA_ENT / IMP_ENT_TOT * 100 (sobre lo comprado)
--   MARGEN1     = BENEFICIO / IMP_VENTA * 100   (margen de LO VENDIDO)
--   MARGEN2     = VENTA_ENT / IMP_VENTA * 100   (margen contando TODO lo
--                 comprado como gasto: el stock no vendido cuenta como gasto)
--   PCT_VDTO    = UDS_VENTA / UNI_ENT_TOT * 100 (% unidades vendidas)
--   PCT_VLAST   = IMP_VENTA / IMP_ENT_TOT * 100 (% venta sobre compra)
--
--   NOTA: MARGEN2 cuenta TODO lo comprado en el periodo como gasto. Como el
--   stock no vendido = comprado - vendido, restar el coste de TODO lo
--   comprado equivale a contar el stock actual (lo no vendido) como gasto,
--   que es lo pedido ("el segundo margen cuenta el stock actual como gasto").
--
-- Las columnas auxiliares VENT_ENT, PCT_VDTO y PCT_VLAST se han definido con
-- el criterio anterior (simétrico a BENEFICIO/%Bnfco/Margen1); si el cliente
-- las quiere con otra fórmula, se ajusta SOLO el SELECT final (un sitio).
--
-- Foto: la columna del artículo se expone como CODIGO_ART_ART para que
-- EngancharFotosEnReport (inLibFotos) resuelva la foto sin configuración.
--
-- Script idempotente: DROP + CREATE del procedimiento. No toca esquema.
-- =====================================================================

DROP PROCEDURE IF EXISTS `PRC_GET_MOV_VENTAS_ART`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_MOV_VENTAS_ART`(
    IN `p_DESDE`          DATE,         -- inicio periodo de VENTAS (inclusive)
    IN `p_HASTA`          DATE,         -- fin periodo de VENTAS (inclusive)
    IN `p_INICIO_COMPRAS` DATE,         -- 1a compra del artículo >= esta fecha
    IN `p_ALMACENES`      TEXT,         -- CSV "01,50" o '' = todos los activos
    IN `p_FAMILIAS`       TEXT,         -- CSV; '' = todas. Una padre incluye sus hijas
    IN `p_PROVEEDORES`    TEXT,         -- CSV de códigos de proveedor; '' = todos
    IN `p_TEMPORADAS`     TEXT,         -- CSV de valores de temporada; '' = todas
    IN `p_ARTICULOS`      TEXT,         -- CSV de códigos de artículo; '' = todos
    IN `p_NIVEL1`         VARCHAR(3),   -- 1er nivel de agrupación: PRV/FAM/TMP/ALM/''
    IN `p_NIVEL2`         VARCHAR(3),   -- 2o nivel de agrupación
    IN `p_NIVEL3`         VARCHAR(3),   -- 3er nivel de agrupación
    IN `p_NIVEL_FAM`      INT           -- nivel del árbol de familias al agrupar
)                                       -- por FAM (1 = raíz; <1 = familia hoja)
BEGIN
    DECLARE v_desde     DATE;
    DECLARE v_hasta     DATE;
    DECLARE v_ini_cmp   DATE;
    DECLARE v_por_alm   BOOLEAN DEFAULT FALSE;  -- TRUE si se agrupa por almacén
    DECLARE v_filtra_cmp BOOLEAN DEFAULT FALSE; -- TRUE si hay filtro inicio compras
    DECLARE v_nivel_fam INT;                    -- nivel efectivo del árbol fam.
    -- Normalización de parámetros.
    SET p_FAMILIAS    = IFNULL(p_FAMILIAS, '');
    SET p_PROVEEDORES = IFNULL(p_PROVEEDORES, '');
    SET p_TEMPORADAS  = IFNULL(p_TEMPORADAS, '');
    SET p_ARTICULOS   = IFNULL(p_ARTICULOS, '');
    SET p_NIVEL1      = UPPER(IFNULL(p_NIVEL1, ''));
    SET p_NIVEL2      = UPPER(IFNULL(p_NIVEL2, ''));
    SET p_NIVEL3      = UPPER(IFNULL(p_NIVEL3, ''));
    SET v_por_alm     = (p_NIVEL1 = 'ALM' OR p_NIVEL2 = 'ALM' OR p_NIVEL3 = 'ALM');
    SET v_nivel_fam   = IF(IFNULL(p_NIVEL_FAM, 0) < 1, 9999, p_NIVEL_FAM);
    SET v_desde       = IFNULL(p_DESDE, '1900-01-01');
    SET v_hasta       = IFNULL(p_HASTA, CURRENT_DATE);
    SET v_ini_cmp     = p_INICIO_COMPRAS;
    SET v_filtra_cmp  = (v_ini_cmp IS NOT NULL);

    -- Almacenes efectivos en tabla temporal indexada (filtrar por IN, no por
    -- FIND_IN_SET sobre tablas grandes). Sin selección = todos los activos.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_alm`;
    CREATE TEMPORARY TABLE `tmp_mva_alm` (
        `CODIGO_ALM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_mva_alm` (`CODIGO_ALM`)
    SELECT `CODIGO_ALM_ALM` FROM `fza_almacenes`
     WHERE IF(IFNULL(p_ALMACENES, '') = '',
              `ESACTIVO_ALM` = 'S',
              FIND_IN_SET(`CODIGO_ALM_ALM`, p_ALMACENES));

    -- Familias elegidas expandidas a TODA su descendencia (CTE recursivo).
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam`;
    CREATE TEMPORARY TABLE `tmp_mva_fam` (
        `CODIGO_FAM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_mva_fam` (`CODIGO_FAM`)
    WITH RECURSIVE `fam_tree` AS (
        SELECT `CODIGO_FAM_FAM`
          FROM `fza_articulos_familias`
         WHERE FIND_IN_SET(`CODIGO_FAM_FAM`, p_FAMILIAS)
        UNION ALL
        SELECT f.`CODIGO_FAM_FAM`
          FROM `fza_articulos_familias` f
          JOIN `fam_tree` t ON f.`CODIGO_PADRE_FAM` = t.`CODIGO_FAM_FAM`
    )
    SELECT DISTINCT `CODIGO_FAM_FAM` FROM `fam_tree`;

    -- Mapa de cada familia a su ancestro al nivel pedido (para agrupar por FAM
    -- "por nivel": raíz, intermedio o familia hoja).
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam_grp`;
    CREATE TEMPORARY TABLE `tmp_mva_fam_grp` (
        `CODIGO_FAM` VARCHAR(20)  NOT NULL PRIMARY KEY,
        `COD_GRP`    VARCHAR(20)  NOT NULL,
        `DESC_GRP`   VARCHAR(200) NULL
    );
    INSERT IGNORE INTO `tmp_mva_fam_grp` (`CODIGO_FAM`, `COD_GRP`, `DESC_GRP`)
    WITH RECURSIVE `fam_path` AS (
        SELECT `CODIGO_FAM_FAM` AS `COD`,
               CAST(`CODIGO_FAM_FAM` AS CHAR(1000)) AS `RUTA`
          FROM `fza_articulos_familias`
         WHERE `CODIGO_PADRE_FAM` IS NULL OR `CODIGO_PADRE_FAM` = ''
        UNION ALL
        SELECT f.`CODIGO_FAM_FAM`,
               CONCAT(pa.`RUTA`, '>', f.`CODIGO_FAM_FAM`)
          FROM `fza_articulos_familias` f
          JOIN `fam_path` pa ON f.`CODIGO_PADRE_FAM` = pa.`COD`
    )
    SELECT pa.`COD`,
           SUBSTRING_INDEX(SUBSTRING_INDEX(pa.`RUTA`, '>', v_nivel_fam), '>', -1),
           NULL
      FROM `fam_path` pa;
    UPDATE `tmp_mva_fam_grp` g
      JOIN `fza_articulos_familias` f ON f.`CODIGO_FAM_FAM` = g.`COD_GRP`
       SET g.`DESC_GRP` = COALESCE(f.`DESCRIPCION_FAM`, f.`NOMBRE_FAM_FAM`,
                                   g.`COD_GRP`);

    -- Entradas de stock por artículo y, si procede, almacén: totales de
    -- unidades y coste. Se cuentan las entradas que representan adquisición
    -- REAL de género: compra (AC) y albarán de entrada (AE). Se EXCLUYEN los
    -- traspasos (TR/AT/TA), movimientos internos entre almacenes (doble
    -- conteo); los depósitos (DP), que no son gasto hasta venderse; y el
    -- inventario/regularización (IN), que es un ajuste, no una compra. El
    -- artículo del movimiento se resuelve por su SKU (CODIGO_UNIDAD_MOV) para
    -- no depender de CODIGO_ART_MOV, que puede venir nulo.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ent`;
    CREATE TEMPORARY TABLE `tmp_mva_ent` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `UNI_ENT`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        `IMP_ENT`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`)
    );
    INSERT INTO `tmp_mva_ent`
    SELECT sk.`CODIGO_ART_SKU`,
           IF(v_por_alm, m.`CODIGO_ALM_MOV`, ''),
           SUM(m.`CANTIDAD_MOV`),
           SUM(m.`TOTAL_COSTE_MOV`)
      FROM `fza_movimientos_almacen` m
      JOIN `fza_articulos_skus` sk
        ON sk.`CODIGO_UNIDAD_SKU` = m.`CODIGO_UNIDAD_MOV`
     WHERE m.`ESACTIVO_MOV` = 'S'
       AND m.`TIPO_MOV` = 'E'
       AND m.`TIPO_DOC_MOV` IN ('AC', 'AE')
       AND m.`CODIGO_ALM_MOV` IN (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sk.`CODIGO_ART_SKU`, IF(v_por_alm, m.`CODIGO_ALM_MOV`, '');

    -- Primera ENTRADA por artículo, para el filtro Inicio compras: el artículo
    -- entra solo si su primera entrada de género (global a los almacenes
    -- filtrados) es >= v_ini_cmp. Usa los MISMOS tipos que las entradas
    -- (AC compra, AE albarán de entrada): si mirara solo 'AC', los artículos
    -- que entran por albarán de entrada se caerían del informe aunque tengan
    -- entradas y ventas.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_primera`;
    CREATE TEMPORARY TABLE `tmp_mva_primera` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY,
        `PRIMERA`    DATE        NULL
    );
    INSERT INTO `tmp_mva_primera`
    SELECT sk.`CODIGO_ART_SKU`, MIN(DATE(m.`FECHA_MOV`))
      FROM `fza_movimientos_almacen` m
      JOIN `fza_articulos_skus` sk
        ON sk.`CODIGO_UNIDAD_SKU` = m.`CODIGO_UNIDAD_MOV`
     WHERE m.`ESACTIVO_MOV` = 'S'
       AND m.`TIPO_MOV` = 'E'
       AND m.`TIPO_DOC_MOV` IN ('AC', 'AE')
       AND m.`CODIGO_ALM_MOV` IN (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sk.`CODIGO_ART_SKU`;

    -- Ventas del periodo por artículo y, si procede, almacén (líneas de
    -- factura/ticket por fecha de factura). El artículo se resuelve por SKU.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ven`;
    CREATE TEMPORARY TABLE `tmp_mva_ven` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `UDS_VEN`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        `IMP_VEN`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`)
    );
    -- El almacén de la venta puede venir vacío en la línea
    -- (CODIGO_ALM_FACLIN nulo); se cae a la cabecera de la factura
    -- (CODIGO_ALM_FAC). Sin esto las líneas sin almacén de línea quedan fuera
    -- del filtro de almacenes y la venta no cuenta.
    INSERT INTO `tmp_mva_ven`
    SELECT sk.`CODIGO_ART_SKU`,
           IF(v_por_alm, COALESCE(fl.`CODIGO_ALM_FACLIN`, f.`CODIGO_ALM_FAC`), ''),
           SUM(fl.`CANTIDAD_FACLIN`),
           SUM(fl.`TOTAL_FACLIN`)
      FROM `fza_facturas_lineas` fl
      JOIN `fza_facturas` f
        ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`
       AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`
      JOIN `fza_articulos_skus` sk
        ON sk.`CODIGO_UNIDAD_SKU` = fl.`CODIGO_UNIDAD_FACLIN`
     WHERE COALESCE(fl.`CODIGO_ALM_FACLIN`, f.`CODIGO_ALM_FAC`)
           IN (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
       AND DATE(f.`FECHA_FAC`) BETWEEN v_desde AND v_hasta
     GROUP BY sk.`CODIGO_ART_SKU`,
              IF(v_por_alm, COALESCE(fl.`CODIGO_ALM_FACLIN`, f.`CODIGO_ALM_FAC`), '');

    -- Conjunto de artículos activos que pasan familia, proveedor, temporada,
    -- lista de artículos e Inicio compras (primera compra >= v_ini_cmp).
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_arts`;
    CREATE TEMPORARY TABLE `tmp_mva_arts` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_mva_arts` (`CODIGO_ART`)
    SELECT a.`CODIGO_ART_ART`
      FROM `fza_articulos` a
     WHERE a.`ESACTIVO_ART` = 'S'
       AND (p_ARTICULOS = ''
            OR FIND_IN_SET(a.`CODIGO_ART_ART`, p_ARTICULOS))
       AND (p_FAMILIAS = ''
            OR a.`CODIGO_FAM_ART` IN (SELECT `CODIGO_FAM` FROM `tmp_mva_fam`))
       AND (p_PROVEEDORES = ''
            OR EXISTS (SELECT 1 FROM `fza_articulos_proveedores` ap
                        WHERE ap.`CODIGO_ART_AP` = a.`CODIGO_ART_ART`
                          AND FIND_IN_SET(ap.`CODIGO_PRV_AP`, p_PROVEEDORES)))
       AND (p_TEMPORADAS = ''
            OR EXISTS (SELECT 1 FROM `fza_articulos_propiedades` tp
                        LEFT JOIN `fza_propiedades_valores` tpv
                          ON tpv.`ID_PV_ARTPROP` = tp.`ID_PV_ARTPROP`
                        WHERE tp.`CODIGO_ART_ART` = a.`CODIGO_ART_ART`
                          AND tp.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
                          AND FIND_IN_SET(
                                COALESCE(tpv.`PV`, tp.`VALOR_LIBRE_ARTPROP`),
                                p_TEMPORADAS)))
       AND (NOT v_filtra_cmp
            OR EXISTS (SELECT 1 FROM `tmp_mva_primera` pc
                        WHERE pc.`CODIGO_ART` = a.`CODIGO_ART_ART`
                          AND pc.`PRIMERA` >= v_ini_cmp));

    -- Coste medio ponderado (PMP) por artículo desde el stock actual de los
    -- almacenes filtrados (respaldo: último precio de compra del proveedor).
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_coste`;
    CREATE TEMPORARY TABLE `tmp_mva_coste` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL PRIMARY KEY,
        `COSTE`      DECIMAL(19,6) NOT NULL DEFAULT 0
    );
    INSERT INTO `tmp_mva_coste`
    SELECT sk.`CODIGO_ART_SKU`,
           IF(SUM(st.`CANTIDAD_STK`) <> 0,
              SUM(st.`VALOR_TOTAL_STK`) / SUM(st.`CANTIDAD_STK`), 0)
      FROM `fza_articulos_stockactual` st
      JOIN `fza_articulos_skus` sk
        ON sk.`CODIGO_UNIDAD_SKU` = st.`CODIGO_UNIDAD_STK`
     WHERE st.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sk.`CODIGO_ART_SKU`;

    -- Universo de filas del informe: (artículo, almacén) presentes en compras
    -- o ventas, restringido a los artículos filtrados. Una fila por artículo
    -- (o por artículo+almacén si se agrupa por ALM).
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_base`;
    CREATE TEMPORARY TABLE `tmp_mva_base` (
        `CODIGO_ART` VARCHAR(20) NOT NULL,
        `CODIGO_ALM` VARCHAR(20) NOT NULL DEFAULT '',
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`)
    );
    INSERT IGNORE INTO `tmp_mva_base`
    SELECT e.`CODIGO_ART`, e.`CODIGO_ALM`
      FROM `tmp_mva_ent` e
     WHERE e.`CODIGO_ART` IN (SELECT `CODIGO_ART` FROM `tmp_mva_arts`);
    INSERT IGNORE INTO `tmp_mva_base`
    SELECT v.`CODIGO_ART`, v.`CODIGO_ALM`
      FROM `tmp_mva_ven` v
     WHERE v.`CODIGO_ART` IN (SELECT `CODIGO_ART` FROM `tmp_mva_arts`);

    -- -----------------------------------------------------------------
    -- Resultado final: una fila por artículo (o artículo+almacén), con las
    -- magnitudes de compra y venta y los dos márgenes. Los porcentajes se
    -- calculan aquí; en los totales por grupo el cliente los recalcula a
    -- partir de las sumas de las bases (no se pueden sumar porcentajes).
    -- -----------------------------------------------------------------
    SELECT
        COALESCE(fam.`ORDEN_FAM`, 999999)             AS `ORDEN_FAM`,
        art.`CODIGO_FAM_ART`                          AS `CODIGO_FAM`,
        COALESCE(fam.`DESCRIPCION_FAM`,
                 fam.`NOMBRE_FAM_FAM`, art.`CODIGO_FAM_ART`) AS `DESCRIPCION_FAM`,
        b.`CODIGO_ART`                                AS `CODIGO_ART_ART`,
        art.`DESCRIPCION_ART`                         AS `DESCRIPCION_ART`,
        prov.`REF_PROVEEDOR_AP`                       AS `REF_PRV`,
        ROUND(COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0), 2) AS `COSTE_ART`,
        ROUND(COALESCE(pvp.`PVP`, 0), 2)              AS `PVP_ART`,
        b.`CODIGO_ALM`                                AS `CODIGO_ALM`,
        COALESCE(alm.`NOMBRE_ALM_ALM`, '')            AS `NOMBRE_ALM`,
        -- Magnitudes base (sumables en los totales).
        ROUND(COALESCE(e.`UNI_ENT`, 0), 2)            AS `UNI_ENT_TOT`,
        ROUND(COALESCE(e.`IMP_ENT`, 0), 2)            AS `IMP_ENT_TOT`,
        ROUND(COALESCE(v.`UDS_VEN`, 0), 2)            AS `UDS_VENTA`,
        ROUND(COALESCE(v.`IMP_VEN`, 0), 2)            AS `IMP_VENTA`,
        ROUND(COALESCE(v.`UDS_VEN`, 0)
              * COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0), 2)
                                                      AS `IMP_COSTE`,
        ROUND(COALESCE(v.`IMP_VEN`, 0)
              - COALESCE(v.`UDS_VEN`, 0)
                * COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0), 2)
                                                      AS `BENEFICIO`,
        ROUND(COALESCE(v.`IMP_VEN`, 0) - COALESCE(e.`IMP_ENT`, 0), 2)
                                                      AS `VENTA_ENT`,
        -- Porcentajes / márgenes (no sumables; se recalculan en los totales).
        ROUND(IF(COALESCE(v.`UDS_VEN`, 0)
                 * COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0)
                  - COALESCE(v.`UDS_VEN`, 0)
                    * COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0))
                 / (COALESCE(v.`UDS_VEN`, 0)
                    * COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0))
                 * 100, 0), 2)                        AS `PCT_BNFCO`,
        ROUND(IF(COALESCE(e.`IMP_ENT`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0) - COALESCE(e.`IMP_ENT`, 0))
                 / COALESCE(e.`IMP_ENT`, 0) * 100, 0), 2) AS `VENT_ENT`,
        ROUND(IF(COALESCE(v.`IMP_VEN`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0)
                  - COALESCE(v.`UDS_VEN`, 0)
                    * COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0))
                 / COALESCE(v.`IMP_VEN`, 0) * 100, 0), 2) AS `MARGEN1`,
        ROUND(IF(COALESCE(v.`IMP_VEN`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0) - COALESCE(e.`IMP_ENT`, 0))
                 / COALESCE(v.`IMP_VEN`, 0) * 100, 0), 2) AS `MARGEN2`,
        ROUND(IF(COALESCE(e.`UNI_ENT`, 0) <> 0,
                 COALESCE(v.`UDS_VEN`, 0) / COALESCE(e.`UNI_ENT`, 0) * 100, 0), 2)
                                                      AS `PCT_VDTO`,
        ROUND(IF(COALESCE(e.`IMP_ENT`, 0) <> 0,
                 COALESCE(v.`IMP_VEN`, 0) / COALESCE(e.`IMP_ENT`, 0) * 100, 0), 2)
                                                      AS `PCT_VLAST`,
        -- Niveles de agrupación configurables (mismo criterio que el balance).
        CASE p_NIVEL1
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN b.`CODIGO_ALM`
            ELSE ''
        END                                           AS `GRUPO1_COD`,
        CASE p_NIVEL1
            WHEN 'PRV' THEN CONCAT('Proveedor: ',
                 COALESCE(NULLIF(prov.`RAZON`, ''), prov.`CODIGO_PRV`,
                          '(sin proveedor)'))
            WHEN 'FAM' THEN CONCAT('Familia: ',
                 COALESCE(fg.`DESC_GRP`, fg.`COD_GRP`, art.`CODIGO_FAM_ART`))
            WHEN 'TMP' THEN CONCAT('Temporada: ',
                 COALESCE(NULLIF(tmp.`TEMPORADA`, ''), '(sin temporada)'))
            WHEN 'ALM' THEN CONCAT('Almacén: ',
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), b.`CODIGO_ALM`,
                          '(sin almacén)'))
            ELSE ''
        END                                           AS `GRUPO1_ETIQ`,
        CASE p_NIVEL2
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN b.`CODIGO_ALM`
            ELSE ''
        END                                           AS `GRUPO2_COD`,
        CASE p_NIVEL2
            WHEN 'PRV' THEN CONCAT('Proveedor: ',
                 COALESCE(NULLIF(prov.`RAZON`, ''), prov.`CODIGO_PRV`,
                          '(sin proveedor)'))
            WHEN 'FAM' THEN CONCAT('Familia: ',
                 COALESCE(fg.`DESC_GRP`, fg.`COD_GRP`, art.`CODIGO_FAM_ART`))
            WHEN 'TMP' THEN CONCAT('Temporada: ',
                 COALESCE(NULLIF(tmp.`TEMPORADA`, ''), '(sin temporada)'))
            WHEN 'ALM' THEN CONCAT('Almacén: ',
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), b.`CODIGO_ALM`,
                          '(sin almacén)'))
            ELSE ''
        END                                           AS `GRUPO2_ETIQ`,
        CASE p_NIVEL3
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN b.`CODIGO_ALM`
            ELSE ''
        END                                           AS `GRUPO3_COD`,
        CASE p_NIVEL3
            WHEN 'PRV' THEN CONCAT('Proveedor: ',
                 COALESCE(NULLIF(prov.`RAZON`, ''), prov.`CODIGO_PRV`,
                          '(sin proveedor)'))
            WHEN 'FAM' THEN CONCAT('Familia: ',
                 COALESCE(fg.`DESC_GRP`, fg.`COD_GRP`, art.`CODIGO_FAM_ART`))
            WHEN 'TMP' THEN CONCAT('Temporada: ',
                 COALESCE(NULLIF(tmp.`TEMPORADA`, ''), '(sin temporada)'))
            WHEN 'ALM' THEN CONCAT('Almacén: ',
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), b.`CODIGO_ALM`,
                          '(sin almacén)'))
            ELSE ''
        END                                           AS `GRUPO3_ETIQ`
      FROM `tmp_mva_base` b
      JOIN `fza_articulos` art ON art.`CODIGO_ART_ART` = b.`CODIGO_ART`
      LEFT JOIN `tmp_mva_ent` e
        ON e.`CODIGO_ART` = b.`CODIGO_ART` AND e.`CODIGO_ALM` = b.`CODIGO_ALM`
      LEFT JOIN `tmp_mva_ven` v
        ON v.`CODIGO_ART` = b.`CODIGO_ART` AND v.`CODIGO_ALM` = b.`CODIGO_ALM`
      LEFT JOIN `tmp_mva_coste` cst ON cst.`CODIGO_ART` = b.`CODIGO_ART`
      LEFT JOIN `fza_articulos_familias` fam
        ON fam.`CODIGO_FAM_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `tmp_mva_fam_grp` fg ON fg.`CODIGO_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `fza_almacenes` alm ON alm.`CODIGO_ALM_ALM` = b.`CODIGO_ALM`
      LEFT JOIN (
            SELECT t.`CODIGO_ART_ARTTAR` AS `CODIGO_ART`,
                   MAX(t.`PRECIO_FINAL_ARTTAR`) AS `PVP`
              FROM `fza_articulos_tarifas` t
             WHERE IFNULL(t.`CODIGO_UNIDAD_ARTTAR`, '') = ''
               AND t.`ESACTIVO_ARTTAR` = 'S'
               AND (t.`FECHA_DESDE_ARTTAR` IS NULL
                    OR t.`FECHA_DESDE_ARTTAR` <= CURRENT_DATE)
               AND (t.`FECHA_HASTA_ARTTAR` IS NULL
                    OR t.`FECHA_HASTA_ARTTAR` >= CURRENT_DATE)
             GROUP BY t.`CODIGO_ART_ARTTAR`
           ) pvp ON pvp.`CODIGO_ART` = b.`CODIGO_ART`
      LEFT JOIN (
            SELECT ap.`CODIGO_ART_AP` AS `CODIGO_ART`,
                   MAX(ap.`REF_PROVEEDOR_AP`)     AS `REF_PROVEEDOR_AP`,
                   MAX(ap.`PRECIO_ULT_COMPRA_AP`) AS `COSTE_PRV`,
                   MAX(ap.`CODIGO_PRV_AP`)        AS `CODIGO_PRV`,
                   MAX(pr.`RAZON_SOCIAL_PRV`)     AS `RAZON`
              FROM `fza_articulos_proveedores` ap
              LEFT JOIN `fza_proveedores` pr
                ON pr.`CODIGO_PRV_PRV` = ap.`CODIGO_PRV_AP`
             WHERE ap.`ESPROVEEDORPRINCIPAL_AP` = 'S'
             GROUP BY ap.`CODIGO_ART_AP`
           ) prov ON prov.`CODIGO_ART` = b.`CODIGO_ART`
      -- Temporada a nivel ARTICULO (Fase 3): este informe es por articulo,
      -- sin desglose de color, asi que usa la temporada del articulo. El
      -- filtro CODIGO_UNIDAD_ARTPROP = '' evita mezclar/duplicar con las
      -- temporadas de color (el color se ve en el balance de tallas).
      LEFT JOIN (
            SELECT tp.`CODIGO_ART_ART` AS `CODIGO_ART`,
                   MAX(COALESCE(tpv.`PV`, tp.`VALOR_LIBRE_ARTPROP`)) AS `TEMPORADA`
              FROM `fza_articulos_propiedades` tp
              LEFT JOIN `fza_propiedades_valores` tpv
                ON tpv.`ID_PV_ARTPROP` = tp.`ID_PV_ARTPROP`
             WHERE tp.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
               AND tp.`CODIGO_UNIDAD_ARTPROP` = ''
             GROUP BY tp.`CODIGO_ART_ART`
           ) tmp ON tmp.`CODIGO_ART` = b.`CODIGO_ART`
     ORDER BY `GRUPO1_COD`, `GRUPO2_COD`, `GRUPO3_COD`,
              COALESCE(fam.`ORDEN_FAM`, 999999), art.`CODIGO_FAM_ART`,
              b.`CODIGO_ART`, b.`CODIGO_ALM`;

    -- Limpieza de temporales.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_base`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_coste`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ven`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_primera`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ent`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam_grp`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_alm`;
END ;;
DELIMITER ;

-- ---------------------------------------------------------------------
-- Parámetros: (p_DESDE, p_HASTA, p_INICIO_COMPRAS, p_ALMACENES, p_FAMILIAS,
--              p_PROVEEDORES, p_TEMPORADAS, p_ARTICULOS, p_NIVEL1, p_NIVEL2,
--              p_NIVEL3, p_NIVEL_FAM).
-- p_DESDE/p_HASTA = periodo de ventas (fecha de factura). p_INICIO_COMPRAS
-- filtra los artículos por su primera compra (NULL = sin filtro). El resto
-- de filtros multi-valor son CSV; '' = todos. p_NIVEL1/2/3 = jerarquía de
-- agrupación (PRV/FAM/TMP/ALM/''); el orden importa. p_NIVEL_FAM = nivel del
-- árbol de familias al agrupar por FAM.
-- Ejemplos:
--   -- Ventas de 2026 de todos los artículos, sin agrupación
--   CALL PRC_GET_MOV_VENTAS_ART('2026-01-01','2026-12-31',NULL,'','','','','','','','',0);
--   -- Artículos comprados desde 01/01/2026, ventas de mayo, almacén 01,
--   -- agrupando por proveedor y, dentro, por familia raíz
--   CALL PRC_GET_MOV_VENTAS_ART('2026-05-01','2026-05-31','2026-01-01','01','','','','','PRV','FAM','',1);
-- ---------------------------------------------------------------------
