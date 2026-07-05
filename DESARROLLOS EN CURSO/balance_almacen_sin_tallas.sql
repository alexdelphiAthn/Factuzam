-- =====================================================================
-- Balance de almacén SIN tallas (informe vertical con foto).
--
-- Procedimiento PRC_GET_BALANCE_ALMACEN_SIN_TALLAS: variante del balance
-- por tallas (PRC_GET_BALANCE_ALMACEN_TALLAS) que NO pivota por talla. Es
-- el informe "normal" (vertical): una fila por (artículo, color, banda)
-- con Cantidad / Precio / Importe, sin las columnas T01..T14. Por eso
-- incluye TODOS los artículos, también los que no son "tallables" (sin
-- conjunto pivote ni tallas en sus SKUs), que el informe horizontal deja
-- fuera. Mismos filtros, modos, bandas, agrupaciones y valoración.
--
-- Modos (parámetro p_MODO):
--   'F' = entre fechas (existencias iniciales, entradas, ventas, existencias
--         finales; desglosado abre los subtipos Ctrl+U). Sin banda Salidas:
--         los traspasos se netean en Entradas y los depósitos quedan fuera.
--   'A' = por acumulados (entradas, ventas, existencias finales).
--   Balance: Ex.ini + Entradas - Ventas = Ex.final.
--
-- Origen de datos y valoración: idénticos al balance por tallas (ver
-- balance_almacen_tallas.sql §). La única diferencia es el grano: aquí se
-- agrupa por (artículo, color) en vez de por (artículo, color, talla), y
-- no hay tabla de posiciones/etiquetas de talla.
--
-- Ventas: la banda de ventas (VEN) toma CANTIDAD e IMPORTE REALES (con
-- descuentos, con IVA = TOTAL_FACLIN) de fza_facturas_lineas, no del acumulado
-- de stock ni de la tarifa. La cantidad se sobrescribe (tmp_bst_ven) antes del
-- descarte, porque el acumulado CANTIDAD_SAL_VENTA_STK puede no estar al día.
-- Columna VENTAS (importe real solo en VEN, 0 en el resto) para acumular las
-- ventas por artículo/grupo/total. Existencias ini/fin y entradas, a PMP.
--
-- Foto: la columna del artículo se expone como CODIGO_ART_ART para que
-- EngancharFotosEnReport (inLibFotos) resuelva la foto del TfrxPictureView
-- "foto300" sin configuración extra.
--
-- Filas todo-a-cero: se descartan los (artículo, color) sin existencias ni
-- movimientos en el periodo (si no, al cubrir todo el catálogo saldría
-- ruido de artículos inactivos).
--
-- Script idempotente: DROP + CREATE del procedimiento. No toca esquema.
-- =====================================================================

DROP PROCEDURE IF EXISTS `PRC_GET_BALANCE_ALMACEN_SIN_TALLAS`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_BALANCE_ALMACEN_SIN_TALLAS`(
    IN `p_MODO`         VARCHAR(1),   -- 'F' entre fechas, 'A' por acumulados
    IN `p_DESDE`        DATE,         -- inclusive (solo modo 'F')
    IN `p_HASTA`        DATE,         -- inclusive (solo modo 'F')
    IN `p_ALMACENES`    TEXT,         -- CSV "01,50" o '' = todos los activos
    IN `p_FAMILIAS`     TEXT,         -- CSV; '' = todas. Una padre incluye sus hijas
    IN `p_PROVEEDORES`  TEXT,         -- CSV de códigos de proveedor; '' = todos
    IN `p_TEMPORADAS`   TEXT,         -- CSV de valores de temporada; '' = todas
    IN `p_ARTICULOS`    TEXT,         -- CSV de códigos de artículo; '' = todos
    IN `p_COD_TARIFA`   VARCHAR(20),  -- tarifa para valorar ventas/salidas
    IN `p_DESGLOSADO`   VARCHAR(1),   -- 'S'/'N' (solo aplica a modo 'F')
    IN `p_BANDAS`       TEXT,         -- CSV de códigos de banda; '' = todas
    IN `p_NIVEL1`       VARCHAR(3),   -- 1er nivel de agrupación: PRV/FAM/TMP/ALM/''
    IN `p_NIVEL2`       VARCHAR(3),   -- 2o nivel de agrupación
    IN `p_NIVEL3`       VARCHAR(3),   -- 3er nivel de agrupación
    IN `p_NIVEL_FAM`    INT           -- nivel del árbol de familias al agrupar
)                                     -- por FAM (1 = raíz; <1 = familia hoja)
BEGIN
    DECLARE v_alms      TEXT;
    DECLARE v_tarifa    VARCHAR(20);
    DECLARE v_desde     DATE;
    DECLARE v_hasta     DATE;
    DECLARE v_por_alm   BOOLEAN DEFAULT FALSE;  -- TRUE si se agrupa por almacén
    DECLARE v_nivel_fam INT;                    -- nivel efectivo del árbol fam.
    -- Normalización de parámetros.
    SET p_MODO       = IFNULL(NULLIF(p_MODO, ''), 'A');
    SET p_DESGLOSADO  = IFNULL(NULLIF(p_DESGLOSADO, ''), 'N');
    SET p_FAMILIAS    = IFNULL(p_FAMILIAS, '');
    SET p_PROVEEDORES = IFNULL(p_PROVEEDORES, '');
    SET p_TEMPORADAS  = IFNULL(p_TEMPORADAS, '');
    SET p_ARTICULOS   = IFNULL(p_ARTICULOS, '');
    SET p_BANDAS      = IFNULL(p_BANDAS, '');
    -- Niveles de agrupación: normalizados a mayúsculas. Se admiten PRV
    -- (proveedor), FAM (familia), TMP (temporada) y ALM (almacén); cualquier
    -- otro valor (o vacío) deshabilita ese nivel.
    SET p_NIVEL1      = UPPER(IFNULL(p_NIVEL1, ''));
    SET p_NIVEL2      = UPPER(IFNULL(p_NIVEL2, ''));
    SET p_NIVEL3      = UPPER(IFNULL(p_NIVEL3, ''));
    SET v_por_alm     = (p_NIVEL1 = 'ALM' OR p_NIVEL2 = 'ALM' OR p_NIVEL3 = 'ALM');
    SET v_nivel_fam   = IF(IFNULL(p_NIVEL_FAM, 0) < 1, 9999, p_NIVEL_FAM);
    SET v_tarifa      = IFNULL(NULLIF(p_COD_TARIFA, ''), 'PVP');
    SET v_desde      = IFNULL(p_DESDE, '1900-01-01');
    SET v_hasta      = IFNULL(p_HASTA, CURRENT_DATE);
    -- Almacenes efectivos en una tabla temporal INDEXADA (PK), para filtrar
    -- por IN en vez de FIND_IN_SET sobre las tablas grandes (no es sargable y
    -- obliga a escanear; fza_articulos_stockactual tiene CODIGO_ALM_STK como
    -- 1ª columna del PK). Sin selección = todos los almacenes activos.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_alm`;
    CREATE TEMPORARY TABLE `tmp_bst_alm` (
        `CODIGO_ALM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bst_alm` (`CODIGO_ALM`)
    SELECT `CODIGO_ALM_ALM` FROM `fza_almacenes`
     WHERE IF(IFNULL(p_ALMACENES, '') = '',
              `ESACTIVO_ALM` = 'S',
              FIND_IN_SET(`CODIGO_ALM_ALM`, p_ALMACENES));

    -- -----------------------------------------------------------------
    -- Filtros de artículo (familias con descendencia, proveedores,
    -- temporadas) + mapa de familia por nivel del árbol. Igual que el
    -- balance por tallas.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_fam`;
    CREATE TEMPORARY TABLE `tmp_bst_fam` (
        `CODIGO_FAM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bst_fam` (`CODIGO_FAM`)
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
    -- Mapa familia -> ancestro al nivel pedido (para agrupar por FAM "por
    -- nivel"). Ver balance_almacen_tallas.sql para el detalle.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_fam_grp`;
    CREATE TEMPORARY TABLE `tmp_bst_fam_grp` (
        `CODIGO_FAM` VARCHAR(20)  NOT NULL PRIMARY KEY,
        `COD_GRP`    VARCHAR(20)  NOT NULL,
        `DESC_GRP`   VARCHAR(200) NULL
    );
    INSERT IGNORE INTO `tmp_bst_fam_grp` (`CODIGO_FAM`, `COD_GRP`, `DESC_GRP`)
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
    UPDATE `tmp_bst_fam_grp` g
      JOIN `fza_articulos_familias` f ON f.`CODIGO_FAM_FAM` = g.`COD_GRP`
       SET g.`DESC_GRP` = COALESCE(f.`DESCRIPCION_FAM`, f.`NOMBRE_FAM_FAM`,
                                   g.`COD_GRP`);
    -- Conjunto de artículos activos que pasan familia, proveedor y temporada.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_arts`;
    CREATE TEMPORARY TABLE `tmp_bst_arts` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bst_arts` (`CODIGO_ART`)
    SELECT a.`CODIGO_ART_ART`
      FROM `fza_articulos` a
     WHERE a.`ESACTIVO_ART` = 'S'
       AND (p_ARTICULOS = ''
            OR FIND_IN_SET(a.`CODIGO_ART_ART`, p_ARTICULOS))
       AND (p_FAMILIAS = ''
            OR a.`CODIGO_FAM_ART` IN (SELECT `CODIGO_FAM` FROM `tmp_bst_fam`))
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
                                p_TEMPORADAS)));

    -- -----------------------------------------------------------------
    -- SKUs en juego: unidad -> (artículo, color). SIN posición de talla:
    -- entra cualquier SKU de los artículos filtrados (con o sin tallas),
    -- por eso el informe cubre todo el catálogo.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_sku`;
    CREATE TEMPORARY TABLE `tmp_bst_sku` (
        `CODIGO_UNIDAD` VARCHAR(50)  NOT NULL PRIMARY KEY,
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `COLOR`         VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR_HEX`     VARCHAR(7)   NULL,
        `ORDEN_COLOR`   INT          NOT NULL DEFAULT 0,
        KEY `IDX_BST_SKU_ART` (`CODIGO_ART`)
    );
    INSERT IGNORE INTO `tmp_bst_sku`
    SELECT sku.`CODIGO_UNIDAD_SKU`, sku.`CODIGO_ART_SKU`,
           COALESCE(co.`AV`, ''), COALESCE(atb.`HEX_ATB`, ''),
           COALESCE(co.`ORDEN_AV`, 0)
      FROM `fza_articulos_skus` sku
      JOIN `fza_articulos` a
        ON a.`CODIGO_ART_ART` = sku.`CODIGO_ART_SKU`
       AND a.`ESACTIVO_ART` = 'S'
       AND a.`CODIGO_ART_ART` IN (SELECT `CODIGO_ART` FROM `tmp_bst_arts`)
      -- Color del SKU: SOLO su fila de atributo de color. El discriminante
      -- ID_VA_AV='CO' DEBE ir también en el ON de `sac`; si solo se filtra en
      -- `co`, `sac` casa además la fila de talla (color NULL) y el SKU genera
      -- dos filas. Con INSERT IGNORE sobre la PK del SKU sobrevive una al azar
      -- y el SKU podía quedar SIN color (banda "sin color" fantasma).
      LEFT JOIN `fza_atributos_sku` sac
        ON sac.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU`
       AND sac.`ID_AV_SA` IN (SELECT `ID_AV` FROM `fza_atributos_valores`
                               WHERE `ID_VA_AV` = 'CO')
      LEFT JOIN `fza_atributos_valores` co
        ON co.`ID_AV` = sac.`ID_AV_SA` AND co.`ID_VA_AV` = 'CO'
      LEFT JOIN `fza_atributos_basicos` atb ON atb.`ID_ATB` = co.`ID_ATB_AV`;

    -- -----------------------------------------------------------------
    -- Base de medidas por (artículo, almacén, color). Igual lógica que el
    -- balance por tallas pero agrupando por color (no por talla).
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_base`;
    CREATE TEMPORARY TABLE `tmp_bst_base` (
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `CODIGO_ALM`    VARCHAR(20)  NOT NULL DEFAULT '',
        `COLOR`         VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR_HEX`     VARCHAR(7)   NULL,
        `ORDEN_COLOR`   INT          NOT NULL DEFAULT 0,
        `EXI_INI`       DECIMAL(19,6) NOT NULL DEFAULT 0,
        `ENT`           DECIMAL(19,6) NOT NULL DEFAULT 0,
        `SAL`           DECIMAL(19,6) NOT NULL DEFAULT 0,
        `VEN`           DECIMAL(19,6) NOT NULL DEFAULT 0,
        `EXI_FIN`       DECIMAL(19,6) NOT NULL DEFAULT 0,
        `ENT_COMPRA`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        `ENT_ALBENTRADA` DECIMAL(19,6) NOT NULL DEFAULT 0,
        `ENT_TRASPASO`  DECIMAL(19,6) NOT NULL DEFAULT 0,
        `ENT_DEPOSITO`  DECIMAL(19,6) NOT NULL DEFAULT 0,
        `ENT_REGULAR`   DECIMAL(19,6) NOT NULL DEFAULT 0,
        `SAL_TRASPASO`  DECIMAL(19,6) NOT NULL DEFAULT 0,
        `SAL_DEPOSITO`  DECIMAL(19,6) NOT NULL DEFAULT 0,
        `SAL_ALBVENTA`  DECIMAL(19,6) NOT NULL DEFAULT 0,
        `SAL_VENTA`     DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`)
    );

    IF p_MODO = 'A' THEN
        -- Acumulados denormalizados del stock actual.
        INSERT INTO `tmp_bst_base`
            (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
             `EXI_INI`, `ENT`, `SAL`, `VEN`, `EXI_FIN`,
             `ENT_COMPRA`, `ENT_ALBENTRADA`, `ENT_TRASPASO`, `ENT_DEPOSITO`,
             `ENT_REGULAR`, `SAL_TRASPASO`, `SAL_DEPOSITO`, `SAL_ALBVENTA`,
             `SAL_VENTA`)
        SELECT s.`CODIGO_ART`, IF(v_por_alm, st.`CODIGO_ALM_STK`, ''),
               s.`COLOR`, MIN(s.`COLOR_HEX`), MIN(s.`ORDEN_COLOR`),
               0,
               SUM(st.`CANTIDAD_ENT_COMPRA_STK` + st.`CANTIDAD_ENT_TRASPASO_STK`
                 + st.`CANTIDAD_ENT_DEPOSITO_STK` + st.`CANTIDAD_ENT_REGULAR_STK`
                 + st.`CANTIDAD_ENT_ALBENTRADA_STK`),
               SUM(st.`CANTIDAD_SAL_TRASPASO_STK` + st.`CANTIDAD_SAL_DEPOSITO_STK`
                 + st.`CANTIDAD_SAL_VENTA_STK` + st.`CANTIDAD_SAL_ALBVENTA_STK`),
               SUM(st.`CANTIDAD_SAL_VENTA_STK` + st.`CANTIDAD_SAL_ALBVENTA_STK`),
               SUM(st.`CANTIDAD_STK`),
               SUM(st.`CANTIDAD_ENT_COMPRA_STK`), SUM(st.`CANTIDAD_ENT_ALBENTRADA_STK`),
               SUM(st.`CANTIDAD_ENT_TRASPASO_STK`), SUM(st.`CANTIDAD_ENT_DEPOSITO_STK`),
               SUM(st.`CANTIDAD_ENT_REGULAR_STK`), SUM(st.`CANTIDAD_SAL_TRASPASO_STK`),
               SUM(st.`CANTIDAD_SAL_DEPOSITO_STK`), SUM(st.`CANTIDAD_SAL_ALBVENTA_STK`),
               SUM(st.`CANTIDAD_SAL_VENTA_STK`)
          FROM `tmp_bst_sku` s
          JOIN `fza_articulos_stockactual` st
            ON st.`CODIGO_UNIDAD_STK` = s.`CODIGO_UNIDAD`
           AND st.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_bst_alm`)
         GROUP BY s.`CODIGO_ART`, IF(v_por_alm, st.`CODIGO_ALM_STK`, ''),
                  s.`COLOR`;
    ELSE
        -- Entre fechas: stock actual + movimientos firmados unificados por
        -- (unidad, almacén). Si no se agrupa por almacén, ALM = '' y colapsa.
        INSERT INTO `tmp_bst_base`
            (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
             `EXI_INI`, `ENT`, `SAL`, `VEN`, `EXI_FIN`,
             `ENT_COMPRA`, `ENT_ALBENTRADA`, `ENT_TRASPASO`, `ENT_DEPOSITO`,
             `ENT_REGULAR`, `SAL_TRASPASO`, `SAL_DEPOSITO`, `SAL_ALBVENTA`,
             `SAL_VENTA`)
        SELECT s.`CODIGO_ART`, COALESCE(mv.`ALM`, ''),
               s.`COLOR`, MIN(s.`COLOR_HEX`), MIN(s.`ORDEN_COLOR`),
               SUM(COALESCE(mv.`STOCK_NOW`, 0) - COALESCE(mv.`DELTA_DESDE`, 0)),
               SUM(COALESCE(mv.`ENT`, 0)),
               SUM(COALESCE(mv.`SAL`, 0)),
               SUM(COALESCE(mv.`VEN`, 0)),
               SUM(COALESCE(mv.`STOCK_NOW`, 0) - COALESCE(mv.`DELTA_HASTA`, 0)),
               SUM(COALESCE(mv.`ENT_COMPRA`, 0)), SUM(COALESCE(mv.`ENT_ALBENTRADA`, 0)),
               SUM(COALESCE(mv.`ENT_TRASPASO`, 0)), SUM(COALESCE(mv.`ENT_DEPOSITO`, 0)),
               SUM(COALESCE(mv.`ENT_REGULAR`, 0)), SUM(COALESCE(mv.`SAL_TRASPASO`, 0)),
               SUM(COALESCE(mv.`SAL_DEPOSITO`, 0)), SUM(COALESCE(mv.`SAL_ALBVENTA`, 0)),
               SUM(COALESCE(mv.`SAL_VENTA`, 0))
          FROM `tmp_bst_sku` s
          LEFT JOIN (
                SELECT u.`CODIGO_UNIDAD`, u.`ALM`,
                       SUM(u.`STOCK_NOW`)      AS `STOCK_NOW`,
                       SUM(u.`ENT`)            AS `ENT`,
                       SUM(u.`SAL`)            AS `SAL`,
                       SUM(u.`VEN`)            AS `VEN`,
                       SUM(u.`ENT_COMPRA`)     AS `ENT_COMPRA`,
                       SUM(u.`ENT_ALBENTRADA`) AS `ENT_ALBENTRADA`,
                       SUM(u.`ENT_TRASPASO`)   AS `ENT_TRASPASO`,
                       SUM(u.`ENT_DEPOSITO`)   AS `ENT_DEPOSITO`,
                       SUM(u.`ENT_REGULAR`)    AS `ENT_REGULAR`,
                       SUM(u.`SAL_TRASPASO`)   AS `SAL_TRASPASO`,
                       SUM(u.`SAL_DEPOSITO`)   AS `SAL_DEPOSITO`,
                       SUM(u.`SAL_ALBVENTA`)   AS `SAL_ALBVENTA`,
                       SUM(u.`SAL_VENTA`)      AS `SAL_VENTA`,
                       SUM(u.`DELTA_DESDE`)    AS `DELTA_DESDE`,
                       SUM(u.`DELTA_HASTA`)    AS `DELTA_HASTA`
                  FROM (
                        SELECT st2.`CODIGO_UNIDAD_STK` AS `CODIGO_UNIDAD`,
                               IF(v_por_alm, st2.`CODIGO_ALM_STK`, '') AS `ALM`,
                               st2.`CANTIDAD_STK` AS `STOCK_NOW`,
                               0 AS `ENT`, 0 AS `SAL`, 0 AS `VEN`,
                               0 AS `ENT_COMPRA`, 0 AS `ENT_ALBENTRADA`,
                               0 AS `ENT_TRASPASO`, 0 AS `ENT_DEPOSITO`,
                               0 AS `ENT_REGULAR`, 0 AS `SAL_TRASPASO`,
                               0 AS `SAL_DEPOSITO`, 0 AS `SAL_ALBVENTA`,
                               0 AS `SAL_VENTA`, 0 AS `DELTA_DESDE`,
                               0 AS `DELTA_HASTA`
                          FROM `fza_articulos_stockactual` st2
                         WHERE st2.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_bst_alm`)
                           -- Solo los SKUs del informe (IDX_STK_UNIDAD): no
                           -- recorrer todo el stock para descartarlo al unir.
                           AND st2.`CODIGO_UNIDAD_STK` IN
                               (SELECT `CODIGO_UNIDAD` FROM `tmp_bst_sku`)
                        UNION ALL
                        SELECT m.`CODIGO_UNIDAD_MOV`,
                               IF(v_por_alm, m.`CODIGO_ALM_MOV`, ''),
                               0,
                               IF(m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_MOV` = 'S'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_MOV` = 'S'
                                  AND m.`TIPO_DOC_MOV` IN ('VE', 'FC', 'AV')
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'AC' AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'AE' AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` IN ('TR', 'AT', 'TA') AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'DP' AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'IN' AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` IN ('TR', 'AT', 'TA') AND m.`TIPO_MOV` = 'S'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'DP' AND m.`TIPO_MOV` = 'S'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'AV' AND m.`TIPO_MOV` = 'S'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` IN ('VE', 'FC') AND m.`TIPO_MOV` = 'S'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(DATE(m.`FECHA_MOV`) >= v_desde,
                                  IF(m.`TIPO_MOV` = 'E', m.`CANTIDAD_MOV`,
                                     -m.`CANTIDAD_MOV`), 0),
                               IF(DATE(m.`FECHA_MOV`) > v_hasta,
                                  IF(m.`TIPO_MOV` = 'E', m.`CANTIDAD_MOV`,
                                     -m.`CANTIDAD_MOV`), 0)
                          FROM `fza_movimientos_almacen` m
                         WHERE m.`ESACTIVO_MOV` = 'S'
                           AND m.`CODIGO_ALM_MOV` IN (SELECT `CODIGO_ALM` FROM `tmp_bst_alm`)
                           -- Solo los SKUs del informe (igual que el LEFT JOIN
                           -- de abajo): no agrega TODA la tabla de movimientos
                           -- para descartarla. Indexado por CODIGO_UNIDAD_MOV.
                           AND m.`CODIGO_UNIDAD_MOV` IN
                               (SELECT `CODIGO_UNIDAD` FROM `tmp_bst_sku`)
                           -- Movs. anteriores a 'desde' aportan 0 a las 16
                           -- medidas (todas exigen fecha >= desde): se podan.
                           AND m.`FECHA_MOV` >= v_desde
                       ) u
                 GROUP BY u.`CODIGO_UNIDAD`, u.`ALM`
               ) mv ON mv.`CODIGO_UNIDAD` = s.`CODIGO_UNIDAD`
         GROUP BY s.`CODIGO_ART`, COALESCE(mv.`ALM`, ''), s.`COLOR`;
    END IF;

    -- Ventas REALES por (artículo, almacén, color) desde las líneas de
    -- factura: fuente de verdad de las ventas (cantidad e importe). Los
    -- acumulados de stock (CANTIDAD_SAL_VENTA_STK) pueden no estar mantenidos
    -- y dar 0 aunque haya venta. Se sobrescribe VEN ANTES del descarte para
    -- que (a) la banda de ventas muestre la cantidad real y (b) no se borre un
    -- color que solo tiene ventas (existencias netas 0). Mismo filtro de
    -- almacén/periodo y mismos SKUs (tmp_bst_sku) que la valoración vt.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_ven`;
    CREATE TEMPORARY TABLE `tmp_bst_ven` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `COLOR`      VARCHAR(100)  NOT NULL DEFAULT '',
        `VEN_QTY`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`)
    );
    INSERT INTO `tmp_bst_ven`
    SELECT s.`CODIGO_ART`,
           IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, ''),
           s.`COLOR`,
           SUM(fl.`CANTIDAD_FACLIN`)
      FROM `fza_facturas_lineas` fl
      JOIN `fza_facturas` f
        ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`
       AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`
      JOIN `tmp_bst_sku` s
        ON s.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN`
     WHERE fl.`CODIGO_ALM_FACLIN` IN (SELECT `CODIGO_ALM` FROM `tmp_bst_alm`)
       AND (p_MODO = 'A'
            OR DATE(f.`FECHA_FAC`) BETWEEN v_desde AND v_hasta)
     GROUP BY s.`CODIGO_ART`,
              IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, ''), s.`COLOR`;
    -- Sobrescribir la cantidad de ventas del stock con la real de facturas.
    UPDATE `tmp_bst_base` b
      JOIN `tmp_bst_ven` v
        ON v.`CODIGO_ART` = b.`CODIGO_ART`
       AND v.`CODIGO_ALM` = b.`CODIGO_ALM`
       AND v.`COLOR` = b.`COLOR`
       SET b.`VEN` = v.`VEN_QTY`;

    -- Descartar (artículo, color) sin existencias ni movimientos: cubrir todo
    -- el catálogo si no llenaría el informe de artículos inactivos a cero.
    DELETE FROM `tmp_bst_base`
     WHERE `EXI_INI` = 0 AND `ENT` = 0 AND `SAL` = 0 AND `VEN` = 0
       AND `EXI_FIN` = 0 AND `ENT_COMPRA` = 0 AND `ENT_ALBENTRADA` = 0
       AND `ENT_TRASPASO` = 0 AND `ENT_DEPOSITO` = 0 AND `ENT_REGULAR` = 0
       AND `SAL_TRASPASO` = 0 AND `SAL_DEPOSITO` = 0 AND `SAL_ALBVENTA` = 0
       AND `SAL_VENTA` = 0;

    -- -----------------------------------------------------------------
    -- Desdoblar en bandas (forma larga), igual que el balance por tallas
    -- pero sin posición de talla.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_medidas`;
    CREATE TEMPORARY TABLE `tmp_bst_medidas` (
        `CODIGO_ART`     VARCHAR(20)  NOT NULL,
        `CODIGO_ALM`     VARCHAR(20)  NOT NULL DEFAULT '',
        `COLOR`          VARCHAR(100) NULL,
        `COLOR_HEX`      VARCHAR(7)   NULL,
        `ORDEN_COLOR`    INT          NOT NULL DEFAULT 0,
        `BANDA`          VARCHAR(20)  NOT NULL,
        `ORDEN_BANDA`    INT          NOT NULL,
        `ETIQUETA_BANDA` VARCHAR(40)  NOT NULL,
        `ES_COSTE`       TINYINT      NOT NULL DEFAULT 0,
        `CANTIDAD`       DECIMAL(19,6) NOT NULL DEFAULT 0,
        KEY `IDX_BST_MED` (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `ORDEN_BANDA`)
    );
    -- Existencias iniciales: solo entre fechas.
    IF p_MODO = 'F' THEN
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'EXIINI', 10, 'Existencias iniciales', 1, `EXI_INI`
          FROM `tmp_bst_base`;
    END IF;
    -- Simplificado (F) o acumulados (A). Entradas = albaranes (compra + alb.
    -- entrada) + recuentos + traspasos NETOS (entrada - salida). SIN depósitos
    -- y SIN banda Salidas: las ventas van en su banda. Balance: Ex.ini +
    -- Entradas - Ventas = Ex.final (los depósitos quedan fuera).
    IF (p_MODO = 'F' AND p_DESGLOSADO = 'N') OR p_MODO = 'A' THEN
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'ENT', 20, 'Entradas', 1,
               `ENT_COMPRA` + `ENT_ALBENTRADA` + `ENT_REGULAR`
                 + `ENT_TRASPASO` - `SAL_TRASPASO`
          FROM `tmp_bst_base`;
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'VEN', 50, 'Ventas', 0, `VEN`
          FROM `tmp_bst_base`;
    END IF;
    -- Entradas desglosadas: solo modo entre fechas desglosado. Traspasos y
    -- depósitos netos (entrada - salida), sin bandas de salida salvo alb.
    -- venta. Mismos subtipos que la consulta de stock (Ctrl+U).
    IF p_MODO = 'F' AND p_DESGLOSADO = 'S' THEN
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'ENTCMP', 21, 'Ent. compra', 1, `ENT_COMPRA`
          FROM `tmp_bst_base`;
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'ENTALB', 22, 'Alb. entrada', 1, `ENT_ALBENTRADA`
          FROM `tmp_bst_base`;
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'ENTTRA', 23, 'Traspasos (neto)', 1,
               `ENT_TRASPASO` - `SAL_TRASPASO`
          FROM `tmp_bst_base`;
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'ENTDEP', 24, 'Depósitos (neto)', 1,
               `ENT_DEPOSITO` - `SAL_DEPOSITO`
          FROM `tmp_bst_base`;
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'ENTREG', 25, 'Regulariz.', 1, `ENT_REGULAR`
          FROM `tmp_bst_base`;
        -- Sal. traspaso / Sal. depósito ya no salen: neteadas en sus bandas de
        -- entrada. Albarán de venta sí se mantiene (es una venta).
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'SALALB', 43, 'Alb. venta', 0, `SAL_ALBVENTA`
          FROM `tmp_bst_base`;
        -- Cantidad de ventas = VEN (ya sobrescrito con la cantidad real de
        -- facturas), igual que en simplificado/acumulados.
        INSERT INTO `tmp_bst_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               'VEN', 50, 'Ventas', 0, `VEN`
          FROM `tmp_bst_base`;
    END IF;
    -- Existencias finales: siempre.
    INSERT INTO `tmp_bst_medidas`
    SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
           'EXIFIN', 90, 'Existencias finales', 1, `EXI_FIN`
      FROM `tmp_bst_base`;
    -- Selección de bandas: sin selección = todas las de la configuración.
    IF p_BANDAS <> '' THEN
        DELETE FROM `tmp_bst_medidas` WHERE NOT FIND_IN_SET(`BANDA`, p_BANDAS);
    END IF;

    -- -----------------------------------------------------------------
    -- Salida final: una fila por (artículo, color, banda), enriquecida con
    -- familia, foto, valoración y columnas de agrupación.
    -- -----------------------------------------------------------------
    SELECT
        COALESCE(fam.`ORDEN_FAM`, 999999)             AS `ORDEN_FAM`,
        art.`CODIGO_FAM_ART`                          AS `CODIGO_FAM`,
        COALESCE(fam.`DESCRIPCION_FAM`,
                 fam.`NOMBRE_FAM_FAM`, art.`CODIGO_FAM_ART`) AS `DESCRIPCION_FAM`,
        p.`CODIGO_ART`                                AS `CODIGO_ART_ART`,
        art.`DESCRIPCION_ART`                         AS `DESCRIPCION_ART`,
        p.`CODIGO_ALM`                                AS `CODIGO_ALM`,
        COALESCE(alm.`NOMBRE_ALM_ALM`, '')            AS `NOMBRE_ALM`,
        prov.`REF_PROVEEDOR_AP`                       AS `REF_PRV`,
        ROUND(COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0), 2) AS `COSTE_ART`,
        ROUND(COALESCE(pvp.`PVP`, 0), 2)              AS `PVP_ART`,
        p.`ORDEN_COLOR`, p.`COLOR`, p.`COLOR_HEX`,
        p.`ORDEN_BANDA`, p.`BANDA`, p.`ETIQUETA_BANDA`, p.`ES_COSTE`,
        p.`CANTIDAD`,
        ROUND(IF(p.`BANDA` = 'VEN',
                 IF(p.`CANTIDAD` <> 0,
                    COALESCE(vt.`VEN_IMPORTE`, 0) / p.`CANTIDAD`, 0),
                 IF(p.`ES_COSTE` = 1,
                    COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0),
                    COALESCE(pvp.`PVP`, 0))), 2)        AS `PRECIO`,
        -- Importe de la banda. La banda de ventas (VEN) se valora al PRECIO
        -- REAL de venta (con descuentos, con IVA) tomado de fza_facturas_lineas;
        -- el resto a coste/PMP o a tarifa según ES_COSTE.
        ROUND(IF(p.`BANDA` = 'VEN',
                 COALESCE(vt.`VEN_IMPORTE`, 0),
                 p.`CANTIDAD` * IF(p.`ES_COSTE` = 1,
                   COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0),
                   COALESCE(pvp.`PVP`, 0))), 2)          AS `IMPORTE`,
        -- Ventas reales (con descuento, con IVA) solo en la banda de ventas
        -- (VEN); 0 en el resto. Al sumarla por artículo/grupo/total da el
        -- acumulado de ventas (las existencias se leen banda a banda; las
        -- ventas hay que irlas sumando).
        ROUND(IF(p.`BANDA` = 'VEN', COALESCE(vt.`VEN_IMPORTE`, 0), 0), 2)
                                                      AS `VENTAS`,
        -- Existencias finales aisladas (cantidad y valor a PMP) solo en la
        -- banda EXIFIN, 0 en el resto, para que el total por grupo/general
        -- muestre SOLO el stock final.
        IF(p.`BANDA` = 'EXIFIN', p.`CANTIDAD`, 0)     AS `EXIFIN_CANT`,
        ROUND(IF(p.`BANDA` = 'EXIFIN',
                 p.`CANTIDAD` * COALESCE(NULLIF(cst.`COSTE`, 0),
                                         prov.`COSTE_PRV`, 0),
                 0), 2)                               AS `EXIFIN_IMP`,
        CASE p_NIVEL1
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN p.`CODIGO_ALM`
            ELSE ''
        END                                           AS `GRUPO1_COD`,
        CASE p_NIVEL1
            WHEN 'PRV' THEN CONCAT('Proveedor: ',
                 COALESCE(NULLIF(prov.`RAZON`, ''), prov.`CODIGO_PRV`,
                          '(sin proveedor)'))
            WHEN 'FAM' THEN CONCAT('Familia: ',
                 COALESCE(fg.`DESC_GRP`, fg.`COD_GRP`,
                          art.`CODIGO_FAM_ART`))
            WHEN 'TMP' THEN CONCAT('Temporada: ',
                 COALESCE(NULLIF(tmp.`TEMPORADA`, ''), '(sin temporada)'))
            WHEN 'ALM' THEN CONCAT('Almacén: ',
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), p.`CODIGO_ALM`,
                          '(sin almacén)'))
            ELSE ''
        END                                           AS `GRUPO1_ETIQ`,
        CASE p_NIVEL2
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN p.`CODIGO_ALM`
            ELSE ''
        END                                           AS `GRUPO2_COD`,
        CASE p_NIVEL2
            WHEN 'PRV' THEN CONCAT('Proveedor: ',
                 COALESCE(NULLIF(prov.`RAZON`, ''), prov.`CODIGO_PRV`,
                          '(sin proveedor)'))
            WHEN 'FAM' THEN CONCAT('Familia: ',
                 COALESCE(fg.`DESC_GRP`, fg.`COD_GRP`,
                          art.`CODIGO_FAM_ART`))
            WHEN 'TMP' THEN CONCAT('Temporada: ',
                 COALESCE(NULLIF(tmp.`TEMPORADA`, ''), '(sin temporada)'))
            WHEN 'ALM' THEN CONCAT('Almacén: ',
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), p.`CODIGO_ALM`,
                          '(sin almacén)'))
            ELSE ''
        END                                           AS `GRUPO2_ETIQ`,
        CASE p_NIVEL3
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN p.`CODIGO_ALM`
            ELSE ''
        END                                           AS `GRUPO3_COD`,
        CASE p_NIVEL3
            WHEN 'PRV' THEN CONCAT('Proveedor: ',
                 COALESCE(NULLIF(prov.`RAZON`, ''), prov.`CODIGO_PRV`,
                          '(sin proveedor)'))
            WHEN 'FAM' THEN CONCAT('Familia: ',
                 COALESCE(fg.`DESC_GRP`, fg.`COD_GRP`,
                          art.`CODIGO_FAM_ART`))
            WHEN 'TMP' THEN CONCAT('Temporada: ',
                 COALESCE(NULLIF(tmp.`TEMPORADA`, ''), '(sin temporada)'))
            WHEN 'ALM' THEN CONCAT('Almacén: ',
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), p.`CODIGO_ALM`,
                          '(sin almacén)'))
            ELSE ''
        END                                           AS `GRUPO3_ETIQ`
      FROM (
            SELECT m.`CODIGO_ART`, m.`CODIGO_ALM`, m.`COLOR`,
                   MIN(m.`COLOR_HEX`) AS `COLOR_HEX`,
                   MIN(m.`ORDEN_COLOR`) AS `ORDEN_COLOR`,
                   m.`BANDA`, m.`ORDEN_BANDA`, m.`ETIQUETA_BANDA`, m.`ES_COSTE`,
                   SUM(m.`CANTIDAD`) AS `CANTIDAD`
              FROM `tmp_bst_medidas` m
             GROUP BY m.`CODIGO_ART`, m.`CODIGO_ALM`, m.`COLOR`, m.`BANDA`,
                      m.`ORDEN_BANDA`, m.`ETIQUETA_BANDA`, m.`ES_COSTE`
           ) p
      JOIN `fza_articulos` art ON art.`CODIGO_ART_ART` = p.`CODIGO_ART`
      LEFT JOIN `fza_articulos_familias` fam
        ON fam.`CODIGO_FAM_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `tmp_bst_fam_grp` fg ON fg.`CODIGO_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `fza_almacenes` alm ON alm.`CODIGO_ALM_ALM` = p.`CODIGO_ALM`
      LEFT JOIN (
            SELECT t.`CODIGO_ART_ARTTAR` AS `CODIGO_ART`,
                   MAX(t.`PRECIO_FINAL_ARTTAR`) AS `PVP`
              FROM `fza_articulos_tarifas` t
             WHERE t.`CODIGO_TAR_ARTTAR` = v_tarifa
               -- Solo los artículos del informe (se une por artículo filtrado).
               AND t.`CODIGO_ART_ARTTAR` IN
                   (SELECT `CODIGO_ART` FROM `tmp_bst_arts`)
               AND IFNULL(t.`CODIGO_UNIDAD_ARTTAR`, '') = ''
               AND t.`ESACTIVO_ARTTAR` = 'S'
               AND (t.`FECHA_DESDE_ARTTAR` IS NULL
                    OR t.`FECHA_DESDE_ARTTAR` <= CURRENT_DATE)
               AND (t.`FECHA_HASTA_ARTTAR` IS NULL
                    OR t.`FECHA_HASTA_ARTTAR` >= CURRENT_DATE)
             GROUP BY t.`CODIGO_ART_ARTTAR`
           ) pvp ON pvp.`CODIGO_ART` = p.`CODIGO_ART`
      LEFT JOIN (
            SELECT sk.`CODIGO_ART_SKU` AS `CODIGO_ART`,
                   IF(SUM(st.`CANTIDAD_STK`) <> 0,
                      SUM(st.`VALOR_TOTAL_STK`) / SUM(st.`CANTIDAD_STK`), 0) AS `COSTE`
              FROM `fza_articulos_stockactual` st
              JOIN `fza_articulos_skus` sk
                ON sk.`CODIGO_UNIDAD_SKU` = st.`CODIGO_UNIDAD_STK`
             WHERE st.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_bst_alm`)
               -- Solo los SKUs del informe (se une por artículo ya filtrado).
               AND st.`CODIGO_UNIDAD_STK` IN
                   (SELECT `CODIGO_UNIDAD` FROM `tmp_bst_sku`)
             GROUP BY sk.`CODIGO_ART_SKU`
           ) cst ON cst.`CODIGO_ART` = p.`CODIGO_ART`
      LEFT JOIN (
            SELECT ap.`CODIGO_ART_AP` AS `CODIGO_ART`,
                   MAX(ap.`REF_PROVEEDOR_AP`)   AS `REF_PROVEEDOR_AP`,
                   MAX(ap.`PRECIO_ULT_COMPRA_AP`) AS `COSTE_PRV`,
                   MAX(ap.`CODIGO_PRV_AP`)      AS `CODIGO_PRV`,
                   MAX(pr.`RAZON_SOCIAL_PRV`)   AS `RAZON`
              FROM `fza_articulos_proveedores` ap
              LEFT JOIN `fza_proveedores` pr
                ON pr.`CODIGO_PRV_PRV` = ap.`CODIGO_PRV_AP`
             WHERE ap.`ESPROVEEDORPRINCIPAL_AP` = 'S'
               -- Solo los artículos del informe (se une por artículo filtrado).
               AND ap.`CODIGO_ART_AP` IN
                   (SELECT `CODIGO_ART` FROM `tmp_bst_arts`)
             GROUP BY ap.`CODIGO_ART_AP`
           ) prov ON prov.`CODIGO_ART` = p.`CODIGO_ART`
      -- Temporada EFECTIVA por color (Fase 4): la vista de propiedades
      -- efectivas resuelve color -> articulo; tmp_bst_sku da el color del
      -- SKU. Los SKU de un mismo color comparten temporada (el MAX colapsa
      -- sin ambiguedad). Sin datos de color resuelve al valor de articulo.
      LEFT JOIN (
            SELECT s.`CODIGO_ART` AS `CODIGO_ART`, s.`COLOR` AS `COLOR`,
                   MAX(COALESCE(e.`VALOR_PV`,
                                e.`VALOR_LIBRE_ARTPROP`)) AS `TEMPORADA`
              FROM `tmp_bst_sku` s
              JOIN `vi_articulos_propiedades_efectivas` e
                ON e.`CODIGO_UNIDAD_SKU` = s.`CODIGO_UNIDAD`
               AND e.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
             GROUP BY s.`CODIGO_ART`, s.`COLOR`
           ) tmp ON tmp.`CODIGO_ART` = p.`CODIGO_ART`
                AND tmp.`COLOR` = p.`COLOR`
      LEFT JOIN (
            -- Ventas REALES (con descuento, con IVA) por (artículo, almacén,
            -- color), de las líneas de factura/ticket. Periodo por fecha de
            -- factura (entre fechas) o histórico (acumulados).
            SELECT s.`CODIGO_ART`,
                   IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, '') AS `CODIGO_ALM`,
                   s.`COLOR`,
                   SUM(fl.`CANTIDAD_FACLIN`) AS `VEN_QTY`,
                   SUM(fl.`TOTAL_FACLIN`)    AS `VEN_IMPORTE`
              FROM `fza_facturas_lineas` fl
              JOIN `fza_facturas` f
                ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`
               AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`
              JOIN `tmp_bst_sku` s
                ON s.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN`
             WHERE fl.`CODIGO_ALM_FACLIN` IN (SELECT `CODIGO_ALM` FROM `tmp_bst_alm`)
               AND (p_MODO = 'A'
                    OR DATE(f.`FECHA_FAC`) BETWEEN v_desde AND v_hasta)
             GROUP BY s.`CODIGO_ART`,
                      IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, ''), s.`COLOR`
           ) vt ON vt.`CODIGO_ART` = p.`CODIGO_ART`
               AND vt.`CODIGO_ALM` = p.`CODIGO_ALM`
               AND vt.`COLOR` = p.`COLOR`
     ORDER BY `GRUPO1_COD`, `GRUPO2_COD`, `GRUPO3_COD`,
              COALESCE(fam.`ORDEN_FAM`, 999999), art.`CODIGO_FAM_ART`,
              p.`CODIGO_ART`, p.`ORDEN_COLOR`, p.`COLOR`, p.`ORDEN_BANDA`;

    -- Limpieza de temporales.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_medidas`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_ven`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_base`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_sku`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_fam_grp`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_fam`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bst_alm`;
END ;;
DELIMITER ;

-- ---------------------------------------------------------------------
-- Parámetros: idénticos a PRC_GET_BALANCE_ALMACEN_TALLAS (p_MODO, p_DESDE,
-- p_HASTA, p_ALMACENES, p_FAMILIAS, p_PROVEEDORES, p_TEMPORADAS, p_ARTICULOS,
-- p_COD_TARIFA, p_DESGLOSADO, p_BANDAS, p_NIVEL1, p_NIVEL2, p_NIVEL3,
-- p_NIVEL_FAM). p_ARTICULOS restringe a una lista de códigos de artículo
-- (CSV; '' = todos). La salida NO trae columnas de talla (T01..T14 / ETIQ_T*):
-- una fila por (artículo, color, banda) con CANTIDAD / PRECIO / IMPORTE.
-- Ejemplos:
--   -- Entre fechas, simplificado, sin agrupación
--   CALL PRC_GET_BALANCE_ALMACEN_SIN_TALLAS('F','2026-05-01','2026-05-21','','','','','','PVP','N','','','','',0);
--   -- Acumulados agrupado por proveedor y, dentro, por familia raíz
--   CALL PRC_GET_BALANCE_ALMACEN_SIN_TALLAS('A',NULL,NULL,'','','','','','PVP','N','','PRV','FAM','',1);
--   -- Entre fechas restringido a un artículo concreto
--   CALL PRC_GET_BALANCE_ALMACEN_SIN_TALLAS('F','2026-05-01','2026-05-21','','','','','ART001','PVP','N','','','','',0);
-- ---------------------------------------------------------------------
