-- =====================================================================
-- Balance de almacén por tallas (informe horizontal con foto).
--
-- Procedimiento PRC_GET_BALANCE_ALMACEN_TALLAS: devuelve las filas del
-- informe ya pivotadas por talla (columnas fijas T01..T14, igual que
-- vi_compras_sesiones_lin_print) y desdobladas en bandas. Una fila por
-- (artículo, color, banda). El informe FastReport agrupa por familia y
-- artículo y dibuja cada banda como una sub-línea (ent. / sal. / ex.).
--
-- Modos (parámetro p_MODO):
--   'F' = entre fechas. Bandas (simplificado): Existencias iniciales,
--         Entradas, Salidas, Ventas, Existencias finales. En desglosado
--         las entradas/salidas se abren en los subtipos de la consulta
--         Ctrl+U (compra, traspaso, depósito, regulariz., albaranes...).
--   'A' = por acumulados. Bandas: Entradas, Salidas, Ventas, Existencias
--         finales (sin existencias iniciales: el acumulado es "desde
--         siempre"). El desglosado no aplica.
--
-- Origen de datos:
--   - Modo 'F': se reconstruye desde fza_movimientos_almacen. Las
--     existencias a una fecha se calculan partiendo del stock actual
--     (fza_articulos_stockactual.CANTIDAD_STK) y restando los
--     movimientos firmados posteriores a esa fecha.
--   - Modo 'A': se leen los acumulados denormalizados de
--     fza_articulos_stockactual (CANTIDAD_ENT_*_STK / CANTIDAD_SAL_*_STK,
--     ver stocks_acumulados.sql) y CANTIDAD_STK.
--
-- Valoración (columnas Precio / Importe del informe):
--   - Entradas y existencias -> coste (precio medio ponderado del stock
--     actual del artículo; si es 0 se usa el último precio de compra del
--     proveedor principal).
--   - Salidas y ventas        -> PVP (tarifa por defecto vigente hoy).
--   IMPORTE = CANTIDAD * PRECIO de la banda.
--
-- Foto: la columna del artículo se expone como CODIGO_ART_ART para que
-- EngancharFotosEnReport (inLibFotos) resuelva la foto del TfrxPictureView
-- "foto300" sin configuración extra.
--
-- Script idempotente: DROP + CREATE del procedimiento. No toca esquema.
-- =====================================================================

DROP PROCEDURE IF EXISTS `PRC_GET_BALANCE_ALMACEN_TALLAS`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_BALANCE_ALMACEN_TALLAS`(
    IN `p_MODO`         VARCHAR(1),   -- 'F' entre fechas, 'A' por acumulados
    IN `p_DESDE`        DATE,         -- inclusive (solo modo 'F')
    IN `p_HASTA`        DATE,         -- inclusive (solo modo 'F')
    IN `p_ALMACENES`    TEXT,         -- CSV "01,50" o '' = todos los activos
    IN `p_FAMILIAS`     TEXT,         -- CSV; '' = todas. Una padre incluye sus hijas
    IN `p_PROVEEDORES`  TEXT,         -- CSV de códigos de proveedor; '' = todos
    IN `p_TEMPORADAS`   TEXT,         -- CSV de valores de temporada; '' = todas
    IN `p_COD_TARIFA`   VARCHAR(20),  -- tarifa para valorar ventas/salidas
    IN `p_DESGLOSADO`   VARCHAR(1)    -- 'S'/'N' (solo aplica a modo 'F')
)
BEGIN
    DECLARE v_alms   TEXT;
    DECLARE v_tarifa VARCHAR(20);
    DECLARE v_desde  DATE;
    DECLARE v_hasta  DATE;
    -- Normalización de parámetros.
    SET p_MODO       = IFNULL(NULLIF(p_MODO, ''), 'A');
    SET p_DESGLOSADO  = IFNULL(NULLIF(p_DESGLOSADO, ''), 'N');
    SET p_FAMILIAS    = IFNULL(p_FAMILIAS, '');
    SET p_PROVEEDORES = IFNULL(p_PROVEEDORES, '');
    SET p_TEMPORADAS  = IFNULL(p_TEMPORADAS, '');
    SET v_tarifa      = IFNULL(NULLIF(p_COD_TARIFA, ''), 'PVP');
    SET v_desde      = IFNULL(p_DESDE, '1900-01-01');
    SET v_hasta      = IFNULL(p_HASTA, CURRENT_DATE);
    -- Lista efectiva de almacenes (CSV sin comillas, para FIND_IN_SET).
    -- Sin selección = TODOS los almacenes activos (igual que la lista del
    -- checklist), no solo los de uso estándar: "nada marcado = todos".
    IF IFNULL(p_ALMACENES, '') <> '' THEN
        SET v_alms = p_ALMACENES;
    ELSE
        SELECT GROUP_CONCAT(`CODIGO_ALM_ALM`)
          INTO v_alms
          FROM `fza_almacenes`
         WHERE `ESACTIVO_ALM` = 'S';
    END IF;
    SET v_alms = IFNULL(v_alms, '');

    -- -----------------------------------------------------------------
    -- Filtros de artículo: familias (con su descendencia), proveedores y
    -- temporadas. Se materializa en tmp_bat_arts el conjunto de artículos
    -- que pasan los tres filtros; el resto del SP se restringe a él.
    -- -----------------------------------------------------------------
    -- Familias elegidas expandidas a TODA su descendencia: si se filtra una
    -- familia padre, entran también sus hijas (CTE recursivo por
    -- CODIGO_PADRE_FAM). Con p_FAMILIAS vacío sale vacía y no se aplica.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_fam`;
    CREATE TEMPORARY TABLE `tmp_bat_fam` (
        `CODIGO_FAM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bat_fam` (`CODIGO_FAM`)
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
    -- Conjunto de artículos activos que pasan familia, proveedor y temporada.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_arts`;
    CREATE TEMPORARY TABLE `tmp_bat_arts` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bat_arts` (`CODIGO_ART`)
    SELECT a.`CODIGO_ART_ART`
      FROM `fza_articulos` a
     WHERE a.`ESACTIVO_ART` = 'S'
       AND (p_FAMILIAS = ''
            OR a.`CODIGO_FAM_ART` IN (SELECT `CODIGO_FAM` FROM `tmp_bat_fam`))
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
    -- 1) Posiciones de talla por artículo (T01..T14).
    --    Mismo criterio que TfrmStockConsulta.TallasArticulo: el conjunto
    --    pivote del artículo (atributo no-color asignado) define el orden
    --    de las columnas; si el artículo no tiene asignación, se usan las
    --    tallas presentes en sus SKUs como respaldo.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_pos`;
    CREATE TEMPORARY TABLE `tmp_bat_pos` (
        `CODIGO_ART` VARCHAR(20)  NOT NULL,
        `ID_AV`      INT          NOT NULL,
        `ETIQ`       VARCHAR(100) NULL,
        `POSICION`   INT          NOT NULL,
        PRIMARY KEY (`CODIGO_ART`, `ID_AV`)
    );
    -- 1a) Artículos con conjunto pivote asignado.
    INSERT IGNORE INTO `tmp_bat_pos` (`CODIGO_ART`, `ID_AV`, `ETIQ`, `POSICION`)
    SELECT asg.`CODIGO_ART`, acd.`ID_AV_ACD`, av.`AV`,
           ROW_NUMBER() OVER (PARTITION BY asg.`CODIGO_ART`
                              ORDER BY acd.`ORDEN_ACD`, acd.`ID_AV_ACD`)
      FROM (SELECT a.`CODIGO_ART_ART` AS `CODIGO_ART`,
                   MIN(asa.`ID_AC_ACA`) AS `ID_AC`
              FROM `fza_articulos` a
              JOIN `fza_articulos_conjuntos_asign` asa
                ON asa.`CODIGO_ART_ACA` = a.`CODIGO_ART_ART`
               AND asa.`ID_VA_ACA` <> 'CO'
             WHERE a.`ESACTIVO_ART` = 'S'
               AND a.`CODIGO_ART_ART` IN (SELECT `CODIGO_ART` FROM `tmp_bat_arts`)
             GROUP BY a.`CODIGO_ART_ART`) asg
      JOIN `fza_atributos_conjuntos_det` acd ON acd.`ID_AC_ACD` = asg.`ID_AC`
      JOIN `fza_atributos_valores` av ON av.`ID_AV` = acd.`ID_AV_ACD`;
    -- Artículos ya resueltos (para excluirlos del respaldo sin
    -- autorreferenciar tmp_bat_pos en el mismo statement).
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_pos_arts`;
    CREATE TEMPORARY TABLE `tmp_bat_pos_arts` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bat_pos_arts`
    SELECT DISTINCT `CODIGO_ART` FROM `tmp_bat_pos`;
    -- 1b) Respaldo: artículos sin asignación -> tallas de sus SKUs.
    INSERT IGNORE INTO `tmp_bat_pos` (`CODIGO_ART`, `ID_AV`, `ETIQ`, `POSICION`)
    SELECT x.`CODIGO_ART`, x.`ID_AV`, x.`AV`,
           ROW_NUMBER() OVER (PARTITION BY x.`CODIGO_ART`
                              ORDER BY x.`ORDEN_AV`, x.`AV`)
      FROM (SELECT DISTINCT a.`CODIGO_ART_ART` AS `CODIGO_ART`,
                   av.`ID_AV`, av.`AV`, COALESCE(av.`ORDEN_AV`, 0) AS `ORDEN_AV`
              FROM `fza_articulos` a
              JOIN `fza_articulos_skus` sku
                ON sku.`CODIGO_ART_SKU` = a.`CODIGO_ART_ART`
              JOIN `fza_atributos_sku` sa
                ON sa.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU`
              JOIN `fza_atributos_valores` av
                ON av.`ID_AV` = sa.`ID_AV_SA` AND av.`ID_VA_AV` <> 'CO'
             WHERE a.`ESACTIVO_ART` = 'S'
               AND a.`CODIGO_ART_ART` IN (SELECT `CODIGO_ART` FROM `tmp_bat_arts`)
               AND a.`CODIGO_ART_ART` NOT IN
                   (SELECT `CODIGO_ART` FROM `tmp_bat_pos_arts`)) x;

    -- Etiquetas de cabecera por artículo (ETIQ_T01..ETIQ_T14).
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_etiq`;
    CREATE TEMPORARY TABLE `tmp_bat_etiq` AS
    SELECT `CODIGO_ART`,
           MAX(CASE WHEN `POSICION` =  1 THEN `ETIQ` END) AS `ETIQ_T01`,
           MAX(CASE WHEN `POSICION` =  2 THEN `ETIQ` END) AS `ETIQ_T02`,
           MAX(CASE WHEN `POSICION` =  3 THEN `ETIQ` END) AS `ETIQ_T03`,
           MAX(CASE WHEN `POSICION` =  4 THEN `ETIQ` END) AS `ETIQ_T04`,
           MAX(CASE WHEN `POSICION` =  5 THEN `ETIQ` END) AS `ETIQ_T05`,
           MAX(CASE WHEN `POSICION` =  6 THEN `ETIQ` END) AS `ETIQ_T06`,
           MAX(CASE WHEN `POSICION` =  7 THEN `ETIQ` END) AS `ETIQ_T07`,
           MAX(CASE WHEN `POSICION` =  8 THEN `ETIQ` END) AS `ETIQ_T08`,
           MAX(CASE WHEN `POSICION` =  9 THEN `ETIQ` END) AS `ETIQ_T09`,
           MAX(CASE WHEN `POSICION` = 10 THEN `ETIQ` END) AS `ETIQ_T10`,
           MAX(CASE WHEN `POSICION` = 11 THEN `ETIQ` END) AS `ETIQ_T11`,
           MAX(CASE WHEN `POSICION` = 12 THEN `ETIQ` END) AS `ETIQ_T12`,
           MAX(CASE WHEN `POSICION` = 13 THEN `ETIQ` END) AS `ETIQ_T13`,
           MAX(CASE WHEN `POSICION` = 14 THEN `ETIQ` END) AS `ETIQ_T14`
      FROM `tmp_bat_pos`
     GROUP BY `CODIGO_ART`;
    ALTER TABLE `tmp_bat_etiq` ADD PRIMARY KEY (`CODIGO_ART`);

    -- -----------------------------------------------------------------
    -- 2) SKUs en juego: artículo + color + posición de talla. Solo las
    --    tallas que están en el conjunto pivote (POSICION 1..14).
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_sku`;
    CREATE TEMPORARY TABLE `tmp_bat_sku` (
        `CODIGO_UNIDAD` VARCHAR(50)  NOT NULL PRIMARY KEY,
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `COLOR`         VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR_HEX`     VARCHAR(7)   NULL,
        `ORDEN_COLOR`   INT          NOT NULL DEFAULT 0,
        `POSICION`      INT          NOT NULL,
        KEY `IDX_BAT_SKU_ART` (`CODIGO_ART`)
    );
    INSERT IGNORE INTO `tmp_bat_sku`
    SELECT sku.`CODIGO_UNIDAD_SKU`, sku.`CODIGO_ART_SKU`,
           COALESCE(co.`AV`, ''), COALESCE(atb.`HEX_ATB`, ''),
           COALESCE(co.`ORDEN_AV`, 0), p.`POSICION`
      FROM `fza_articulos_skus` sku
      JOIN `fza_articulos` a
        ON a.`CODIGO_ART_ART` = sku.`CODIGO_ART_SKU`
       AND a.`ESACTIVO_ART` = 'S'
      JOIN `fza_atributos_sku` sat
        ON sat.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU`
      JOIN `fza_atributos_valores` ta
        ON ta.`ID_AV` = sat.`ID_AV_SA` AND ta.`ID_VA_AV` <> 'CO'
      JOIN `tmp_bat_pos` p
        ON p.`CODIGO_ART` = sku.`CODIGO_ART_SKU` AND p.`ID_AV` = ta.`ID_AV`
      LEFT JOIN `fza_atributos_sku` sac
        ON sac.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU`
      LEFT JOIN `fza_atributos_valores` co
        ON co.`ID_AV` = sac.`ID_AV_SA` AND co.`ID_VA_AV` = 'CO'
      LEFT JOIN `fza_atributos_basicos` atb ON atb.`ID_ATB` = co.`ID_ATB_AV`;

    -- -----------------------------------------------------------------
    -- 3) Base de medidas por (artículo, color, posición). Se rellena con
    --    ramas distintas según el modo para no calcular ventanas de
    --    movimientos cuando se pide acumulados.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_base`;
    CREATE TEMPORARY TABLE `tmp_bat_base` (
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `COLOR`         VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR_HEX`     VARCHAR(7)   NULL,
        `ORDEN_COLOR`   INT          NOT NULL DEFAULT 0,
        `POSICION`      INT          NOT NULL,
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
        PRIMARY KEY (`CODIGO_ART`, `POSICION`, `COLOR`)
    );

    IF p_MODO = 'A' THEN
        -- Acumulados denormalizados del stock actual.
        INSERT INTO `tmp_bat_base`
            (`CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
             `EXI_INI`, `ENT`, `SAL`, `VEN`, `EXI_FIN`,
             `ENT_COMPRA`, `ENT_ALBENTRADA`, `ENT_TRASPASO`, `ENT_DEPOSITO`,
             `ENT_REGULAR`, `SAL_TRASPASO`, `SAL_DEPOSITO`, `SAL_ALBVENTA`,
             `SAL_VENTA`)
        SELECT s.`CODIGO_ART`, s.`COLOR`, MIN(s.`COLOR_HEX`),
               MIN(s.`ORDEN_COLOR`), s.`POSICION`,
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
          FROM `tmp_bat_sku` s
          JOIN `fza_articulos_stockactual` st
            ON st.`CODIGO_UNIDAD_STK` = s.`CODIGO_UNIDAD`
           AND FIND_IN_SET(st.`CODIGO_ALM_STK`, v_alms)
         GROUP BY s.`CODIGO_ART`, s.`POSICION`, s.`COLOR`;
    ELSE
        -- Entre fechas: movimientos del periodo + existencias
        -- reconstruidas desde el stock actual.
        INSERT INTO `tmp_bat_base`
            (`CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
             `EXI_INI`, `ENT`, `SAL`, `VEN`, `EXI_FIN`,
             `ENT_COMPRA`, `ENT_ALBENTRADA`, `ENT_TRASPASO`, `ENT_DEPOSITO`,
             `ENT_REGULAR`, `SAL_TRASPASO`, `SAL_DEPOSITO`, `SAL_ALBVENTA`,
             `SAL_VENTA`)
        SELECT s.`CODIGO_ART`, s.`COLOR`, MIN(s.`COLOR_HEX`),
               MIN(s.`ORDEN_COLOR`), s.`POSICION`,
               -- Existencias iniciales: stock actual menos movimientos
               -- firmados desde p_DESDE (inclusive).
               SUM(COALESCE(st.`STOCK_NOW`, 0) - COALESCE(mv.`DELTA_DESDE`, 0)),
               SUM(COALESCE(mv.`ENT`, 0)),
               SUM(COALESCE(mv.`SAL`, 0)),
               SUM(COALESCE(mv.`VEN`, 0)),
               -- Existencias finales: stock actual menos movimientos
               -- firmados posteriores a p_HASTA.
               SUM(COALESCE(st.`STOCK_NOW`, 0) - COALESCE(mv.`DELTA_HASTA`, 0)),
               SUM(COALESCE(mv.`ENT_COMPRA`, 0)), SUM(COALESCE(mv.`ENT_ALBENTRADA`, 0)),
               SUM(COALESCE(mv.`ENT_TRASPASO`, 0)), SUM(COALESCE(mv.`ENT_DEPOSITO`, 0)),
               SUM(COALESCE(mv.`ENT_REGULAR`, 0)), SUM(COALESCE(mv.`SAL_TRASPASO`, 0)),
               SUM(COALESCE(mv.`SAL_DEPOSITO`, 0)), SUM(COALESCE(mv.`SAL_ALBVENTA`, 0)),
               SUM(COALESCE(mv.`SAL_VENTA`, 0))
          FROM `tmp_bat_sku` s
          LEFT JOIN (
                SELECT st2.`CODIGO_UNIDAD_STK` AS `CODIGO_UNIDAD`,
                       SUM(st2.`CANTIDAD_STK`) AS `STOCK_NOW`
                  FROM `fza_articulos_stockactual` st2
                 WHERE FIND_IN_SET(st2.`CODIGO_ALM_STK`, v_alms)
                 GROUP BY st2.`CODIGO_UNIDAD_STK`
               ) st ON st.`CODIGO_UNIDAD` = s.`CODIGO_UNIDAD`
          LEFT JOIN (
                SELECT m.`CODIGO_UNIDAD_MOV` AS `CODIGO_UNIDAD`,
                       SUM(IF(m.`TIPO_MOV` = 'E'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `ENT`,
                       SUM(IF(m.`TIPO_MOV` = 'S'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `SAL`,
                       SUM(IF(m.`TIPO_MOV` = 'S'
                              AND m.`TIPO_DOC_MOV` IN ('VE', 'FC', 'AV')
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `VEN`,
                       SUM(IF(m.`TIPO_DOC_MOV` = 'AC' AND m.`TIPO_MOV` = 'E'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `ENT_COMPRA`,
                       SUM(IF(m.`TIPO_DOC_MOV` = 'AE' AND m.`TIPO_MOV` = 'E'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `ENT_ALBENTRADA`,
                       SUM(IF(m.`TIPO_DOC_MOV` IN ('TR', 'AT') AND m.`TIPO_MOV` = 'E'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `ENT_TRASPASO`,
                       SUM(IF(m.`TIPO_DOC_MOV` = 'DP' AND m.`TIPO_MOV` = 'E'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `ENT_DEPOSITO`,
                       SUM(IF(m.`TIPO_DOC_MOV` = 'IN' AND m.`TIPO_MOV` = 'E'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `ENT_REGULAR`,
                       SUM(IF(m.`TIPO_DOC_MOV` IN ('TR', 'AT') AND m.`TIPO_MOV` = 'S'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `SAL_TRASPASO`,
                       SUM(IF(m.`TIPO_DOC_MOV` = 'DP' AND m.`TIPO_MOV` = 'S'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `SAL_DEPOSITO`,
                       SUM(IF(m.`TIPO_DOC_MOV` = 'AV' AND m.`TIPO_MOV` = 'S'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `SAL_ALBVENTA`,
                       SUM(IF(m.`TIPO_DOC_MOV` IN ('VE', 'FC') AND m.`TIPO_MOV` = 'S'
                              AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                              m.`CANTIDAD_MOV`, 0)) AS `SAL_VENTA`,
                       -- Delta firmado desde p_DESDE (para existencias iniciales).
                       SUM(IF(DATE(m.`FECHA_MOV`) >= v_desde,
                              IF(m.`TIPO_MOV` = 'E', m.`CANTIDAD_MOV`, -m.`CANTIDAD_MOV`),
                              0)) AS `DELTA_DESDE`,
                       -- Delta firmado posterior a p_HASTA (para existencias finales).
                       SUM(IF(DATE(m.`FECHA_MOV`) > v_hasta,
                              IF(m.`TIPO_MOV` = 'E', m.`CANTIDAD_MOV`, -m.`CANTIDAD_MOV`),
                              0)) AS `DELTA_HASTA`
                  FROM `fza_movimientos_almacen` m
                 WHERE m.`ESACTIVO_MOV` = 'S'
                   AND FIND_IN_SET(m.`CODIGO_ALM_MOV`, v_alms)
                 GROUP BY m.`CODIGO_UNIDAD_MOV`
               ) mv ON mv.`CODIGO_UNIDAD` = s.`CODIGO_UNIDAD`
         GROUP BY s.`CODIGO_ART`, s.`POSICION`, s.`COLOR`;
    END IF;

    -- -----------------------------------------------------------------
    -- 4) Desdoblar en bandas (forma larga). Cada banda es un INSERT
    --    independiente (referencia tmp_bat_base una sola vez) y se filtra
    --    por modo/desglosado. ES_COSTE marca cómo se valora la banda.
    --    ORDEN_BANDA fija el orden vertical del informe.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_medidas`;
    CREATE TEMPORARY TABLE `tmp_bat_medidas` (
        `CODIGO_ART`     VARCHAR(20)  NOT NULL,
        `COLOR`          VARCHAR(100) NULL,
        `COLOR_HEX`      VARCHAR(7)   NULL,
        `ORDEN_COLOR`    INT          NOT NULL DEFAULT 0,
        `POSICION`       INT          NOT NULL,
        `BANDA`          VARCHAR(20)  NOT NULL,
        `ORDEN_BANDA`    INT          NOT NULL,
        `ETIQUETA_BANDA` VARCHAR(40)  NOT NULL,
        `ES_COSTE`       TINYINT      NOT NULL DEFAULT 0,
        `CANTIDAD`       DECIMAL(19,6) NOT NULL DEFAULT 0,
        KEY `IDX_BAT_MED` (`CODIGO_ART`, `COLOR`, `ORDEN_BANDA`)
    );

    -- Existencias iniciales: solo entre fechas.
    IF p_MODO = 'F' THEN
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'EXIINI', 10, 'Existencias iniciales', 1, `EXI_INI`
          FROM `tmp_bat_base`;
    END IF;
    -- Entradas / Salidas agregadas: simplificado (F) o acumulados (A).
    IF (p_MODO = 'F' AND p_DESGLOSADO = 'N') OR p_MODO = 'A' THEN
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'ENT', 20, 'Entradas', 1, `ENT`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'SAL', 40, 'Salidas', 0, `SAL`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'VEN', 50, 'Ventas', 0, `VEN`
          FROM `tmp_bat_base`;
    END IF;
    -- Entradas / Salidas desglosadas: solo modo entre fechas desglosado.
    -- Mismos subtipos que la consulta de stock (Ctrl+U).
    IF p_MODO = 'F' AND p_DESGLOSADO = 'S' THEN
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'ENTCMP', 21, 'Ent. compra', 1, `ENT_COMPRA`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'ENTALB', 22, 'Alb. entrada', 1, `ENT_ALBENTRADA`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'ENTTRA', 23, 'Ent. traspaso', 1, `ENT_TRASPASO`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'ENTDEP', 24, 'Ent. depósito', 1, `ENT_DEPOSITO`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'ENTREG', 25, 'Regulariz.', 1, `ENT_REGULAR`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'SALTRA', 41, 'Sal. traspaso', 0, `SAL_TRASPASO`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'SALDEP', 42, 'Sal. depósito', 0, `SAL_DEPOSITO`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'SALALB', 43, 'Alb. venta', 0, `SAL_ALBVENTA`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
               'VEN', 50, 'Ventas', 0, `SAL_VENTA`
          FROM `tmp_bat_base`;
    END IF;
    -- Existencias finales: siempre.
    INSERT INTO `tmp_bat_medidas`
    SELECT `CODIGO_ART`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`, `POSICION`,
           'EXIFIN', 90, 'Existencias finales', 1, `EXI_FIN`
      FROM `tmp_bat_base`;

    -- -----------------------------------------------------------------
    -- 5) Pivote final por (artículo, color, banda) y enriquecido con
    --    familia, etiquetas de cabecera, foto y valoración. El pivote
    --    va en una subconsulta para no mezclar agregados con columnas
    --    de adorno (ONLY_FULL_GROUP_BY-safe).
    -- -----------------------------------------------------------------
    SELECT
        COALESCE(fam.`ORDEN_FAM`, 999999)             AS `ORDEN_FAM`,
        art.`CODIGO_FAM_ART`                          AS `CODIGO_FAM`,
        COALESCE(fam.`DESCRIPCION_FAM`,
                 fam.`NOMBRE_FAM_FAM`, art.`CODIGO_FAM_ART`) AS `DESCRIPCION_FAM`,
        p.`CODIGO_ART`                                AS `CODIGO_ART_ART`,
        art.`DESCRIPCION_ART`                         AS `DESCRIPCION_ART`,
        prov.`REF_PROVEEDOR_AP`                       AS `REF_PRV`,
        ROUND(COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0), 2) AS `COSTE_ART`,
        ROUND(COALESCE(pvp.`PVP`, 0), 2)              AS `PVP_ART`,
        p.`ORDEN_COLOR`, p.`COLOR`, p.`COLOR_HEX`,
        p.`ORDEN_BANDA`, p.`BANDA`, p.`ETIQUETA_BANDA`, p.`ES_COSTE`,
        et.`ETIQ_T01`, et.`ETIQ_T02`, et.`ETIQ_T03`, et.`ETIQ_T04`,
        et.`ETIQ_T05`, et.`ETIQ_T06`, et.`ETIQ_T07`, et.`ETIQ_T08`,
        et.`ETIQ_T09`, et.`ETIQ_T10`, et.`ETIQ_T11`, et.`ETIQ_T12`,
        et.`ETIQ_T13`, et.`ETIQ_T14`,
        p.`T01`, p.`T02`, p.`T03`, p.`T04`, p.`T05`, p.`T06`, p.`T07`,
        p.`T08`, p.`T09`, p.`T10`, p.`T11`, p.`T12`, p.`T13`, p.`T14`,
        p.`CANTIDAD`,
        ROUND(IF(p.`ES_COSTE` = 1,
                 COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0),
                 COALESCE(pvp.`PVP`, 0)), 2)          AS `PRECIO`,
        ROUND(p.`CANTIDAD` * IF(p.`ES_COSTE` = 1,
                 COALESCE(NULLIF(cst.`COSTE`, 0), prov.`COSTE_PRV`, 0),
                 COALESCE(pvp.`PVP`, 0)), 2)          AS `IMPORTE`
      FROM (
            SELECT m.`CODIGO_ART`, m.`COLOR`, MIN(m.`COLOR_HEX`) AS `COLOR_HEX`,
                   MIN(m.`ORDEN_COLOR`) AS `ORDEN_COLOR`,
                   m.`BANDA`, m.`ORDEN_BANDA`, m.`ETIQUETA_BANDA`, m.`ES_COSTE`,
                   SUM(IF(m.`POSICION` =  1, m.`CANTIDAD`, 0)) AS `T01`,
                   SUM(IF(m.`POSICION` =  2, m.`CANTIDAD`, 0)) AS `T02`,
                   SUM(IF(m.`POSICION` =  3, m.`CANTIDAD`, 0)) AS `T03`,
                   SUM(IF(m.`POSICION` =  4, m.`CANTIDAD`, 0)) AS `T04`,
                   SUM(IF(m.`POSICION` =  5, m.`CANTIDAD`, 0)) AS `T05`,
                   SUM(IF(m.`POSICION` =  6, m.`CANTIDAD`, 0)) AS `T06`,
                   SUM(IF(m.`POSICION` =  7, m.`CANTIDAD`, 0)) AS `T07`,
                   SUM(IF(m.`POSICION` =  8, m.`CANTIDAD`, 0)) AS `T08`,
                   SUM(IF(m.`POSICION` =  9, m.`CANTIDAD`, 0)) AS `T09`,
                   SUM(IF(m.`POSICION` = 10, m.`CANTIDAD`, 0)) AS `T10`,
                   SUM(IF(m.`POSICION` = 11, m.`CANTIDAD`, 0)) AS `T11`,
                   SUM(IF(m.`POSICION` = 12, m.`CANTIDAD`, 0)) AS `T12`,
                   SUM(IF(m.`POSICION` = 13, m.`CANTIDAD`, 0)) AS `T13`,
                   SUM(IF(m.`POSICION` = 14, m.`CANTIDAD`, 0)) AS `T14`,
                   SUM(m.`CANTIDAD`) AS `CANTIDAD`
              FROM `tmp_bat_medidas` m
             GROUP BY m.`CODIGO_ART`, m.`COLOR`, m.`BANDA`,
                      m.`ORDEN_BANDA`, m.`ETIQUETA_BANDA`, m.`ES_COSTE`
           ) p
      JOIN `fza_articulos` art ON art.`CODIGO_ART_ART` = p.`CODIGO_ART`
      LEFT JOIN `fza_articulos_familias` fam
        ON fam.`CODIGO_FAM_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `tmp_bat_etiq` et ON et.`CODIGO_ART` = p.`CODIGO_ART`
      LEFT JOIN (
            SELECT t.`CODIGO_ART_ARTTAR` AS `CODIGO_ART`,
                   MAX(t.`PRECIO_FINAL_ARTTAR`) AS `PVP`
              FROM `fza_articulos_tarifas` t
             WHERE t.`CODIGO_TAR_ARTTAR` = v_tarifa
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
                   SUM(st.`VALOR_TOTAL_STK`) AS `VAL`,
                   SUM(st.`CANTIDAD_STK`)    AS `CAN`,
                   IF(SUM(st.`CANTIDAD_STK`) <> 0,
                      SUM(st.`VALOR_TOTAL_STK`) / SUM(st.`CANTIDAD_STK`), 0) AS `COSTE`
              FROM `fza_articulos_stockactual` st
              JOIN `fza_articulos_skus` sk
                ON sk.`CODIGO_UNIDAD_SKU` = st.`CODIGO_UNIDAD_STK`
             WHERE FIND_IN_SET(st.`CODIGO_ALM_STK`, v_alms)
             GROUP BY sk.`CODIGO_ART_SKU`
           ) cst ON cst.`CODIGO_ART` = p.`CODIGO_ART`
      LEFT JOIN (
            SELECT ap.`CODIGO_ART_AP` AS `CODIGO_ART`,
                   MAX(ap.`REF_PROVEEDOR_AP`)   AS `REF_PROVEEDOR_AP`,
                   MAX(ap.`PRECIO_ULT_COMPRA_AP`) AS `COSTE_PRV`
              FROM `fza_articulos_proveedores` ap
             WHERE ap.`ESPROVEEDORPRINCIPAL_AP` = 'S'
             GROUP BY ap.`CODIGO_ART_AP`
           ) prov ON prov.`CODIGO_ART` = p.`CODIGO_ART`
     ORDER BY COALESCE(fam.`ORDEN_FAM`, 999999), art.`CODIGO_FAM_ART`,
              p.`CODIGO_ART`, p.`ORDEN_COLOR`, p.`COLOR`, p.`ORDEN_BANDA`;

    -- Limpieza de temporales para no arrastrarlas en la sesión.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_medidas`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_base`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_sku`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_etiq`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_pos_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_pos`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_fam`;
END ;;
DELIMITER ;

-- ---------------------------------------------------------------------
-- Parámetros: (p_MODO, p_DESDE, p_HASTA, p_ALMACENES, p_FAMILIAS,
--              p_PROVEEDORES, p_TEMPORADAS, p_COD_TARIFA, p_DESGLOSADO).
-- Todos los filtros multi-valor son CSV; '' = sin filtro (todos).
-- Ejemplos de uso (desde el modal de impresión preparar_consulta):
--   -- Entre fechas, simplificado, todos los almacenes, tarifa PVP
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('F','2026-05-01','2026-05-21','','','','','PVP','N');
--   -- Entre fechas, desglosado, almacenes 01 y 50, familias 0103 y 0104
--   -- (cada familia incluye su descendencia), proveedor PRV001, temporada V26
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('F','2026-05-01','2026-05-21','01,50','0103,0104','PRV001','V26','PVP','S');
--   -- Por acumulados (sin existencias iniciales)
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('A',NULL,NULL,'','','','','PVP','N');
-- ---------------------------------------------------------------------
