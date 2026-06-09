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
--         Entradas, Ventas, Existencias finales. NO hay banda Salidas: los
--         traspasos se netean (entrada - salida) dentro de Entradas y los
--         depósitos quedan fuera de la ecuación. En desglosado las entradas
--         se abren en los subtipos de la consulta Ctrl+U (compra, alb.
--         entrada, traspasos neto, depósitos neto, regulariz., alb. venta).
--   'A' = por acumulados. Bandas: Entradas, Ventas, Existencias finales
--         (sin existencias iniciales: el acumulado es "desde siempre"). El
--         desglosado no aplica.
--   Balance en todos los modos: Ex.ini + Entradas - Ventas = Ex.final.
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
--   - Entradas y existencias (ini/fin) -> coste = precio medio ponderado
--     (PMP) del stock actual del artículo; si es 0 se usa el último precio
--     de compra del proveedor principal.
--   - Alb. venta     -> PVP (tarifa por defecto vigente hoy), valoración
--     nocional de la salida por albarán de venta (solo en desglosado).
--   - Ventas (VEN)   -> CANTIDAD e IMPORTE REALES de venta (con descuentos,
--     con IVA) de fza_facturas_lineas; NO el acumulado de stock ni la tarifa.
--     La cantidad por talla sale de las líneas de factura (tmp_bat_ven),
--     porque el acumulado CANTIDAD_SAL_VENTA_STK puede no estar mantenido.
--   VENTAS: columna con el importe real de venta SOLO en la banda VEN (0 en
--   el resto), para acumular las ventas por artículo/grupo/total (en los
--   totales se muestran las ventas, no el margen).
--   IMPORTE = CANTIDAD * PRECIO de la banda (salvo VEN, importe real).
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
    -- Si algún nivel es ALM hay que conservar el almacén en el grano de los
    -- cálculos (si no, se agregan todos los almacenes filtrados en uno).
    SET v_por_alm     = (p_NIVEL1 = 'ALM' OR p_NIVEL2 = 'ALM' OR p_NIVEL3 = 'ALM');
    -- Nivel del árbol de familias para agrupar por FAM. <1 (o NULL) = familia
    -- hoja del artículo (comportamiento clásico); 1 = familia raíz, etc.
    SET v_nivel_fam   = IF(IFNULL(p_NIVEL_FAM, 0) < 1, 9999, p_NIVEL_FAM);
    SET v_tarifa      = IFNULL(NULLIF(p_COD_TARIFA, ''), 'PVP');
    SET v_desde      = IFNULL(p_DESDE, '1900-01-01');
    SET v_hasta      = IFNULL(p_HASTA, CURRENT_DATE);
    -- Almacenes efectivos en una tabla temporal INDEXADA (PK), para filtrar
    -- por IN en vez de FIND_IN_SET sobre las tablas grandes: FIND_IN_SET no es
    -- sargable y obliga a escanear (p. ej. fza_articulos_stockactual, cuyo PK
    -- empieza por CODIGO_ALM_STK). Con el IN, MariaDB puede usar el índice.
    -- Sin selección = todos los almacenes activos ("nada marcado = todos").
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_alm`;
    CREATE TEMPORARY TABLE `tmp_bat_alm` (
        `CODIGO_ALM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bat_alm` (`CODIGO_ALM`)
    SELECT `CODIGO_ALM_ALM` FROM `fza_almacenes`
     WHERE IF(IFNULL(p_ALMACENES, '') = '',
              `ESACTIVO_ALM` = 'S',
              FIND_IN_SET(`CODIGO_ALM_ALM`, p_ALMACENES));

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
    -- Mapa de cada familia a su ancestro al nivel pedido (v_nivel_fam), para
    -- agrupar por FAM "por nivel": si el árbol tiene padres-hijos se puede
    -- agrupar por la familia raíz (nivel 1), la de 2º nivel, etc. Se construye
    -- el camino raíz->familia y se toma el código del nivel solicitado (o la
    -- propia familia si es menos profunda que el nivel pedido).
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_fam_grp`;
    CREATE TEMPORARY TABLE `tmp_bat_fam_grp` (
        `CODIGO_FAM` VARCHAR(20)  NOT NULL PRIMARY KEY,
        `COD_GRP`    VARCHAR(20)  NOT NULL,
        `DESC_GRP`   VARCHAR(200) NULL
    );
    INSERT IGNORE INTO `tmp_bat_fam_grp` (`CODIGO_FAM`, `COD_GRP`, `DESC_GRP`)
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
    -- Descripción del grupo (familia ancestro elegida).
    UPDATE `tmp_bat_fam_grp` g
      JOIN `fza_articulos_familias` f ON f.`CODIGO_FAM_FAM` = g.`COD_GRP`
       SET g.`DESC_GRP` = COALESCE(f.`DESCRIPCION_FAM`, f.`NOMBRE_FAM_FAM`,
                                   g.`COD_GRP`);
    -- Conjunto de artículos activos que pasan familia, proveedor y temporada.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_arts`;
    CREATE TEMPORARY TABLE `tmp_bat_arts` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_bat_arts` (`CODIGO_ART`)
    SELECT a.`CODIGO_ART_ART`
      FROM `fza_articulos` a
     WHERE a.`ESACTIVO_ART` = 'S'
       AND (p_ARTICULOS = ''
            OR FIND_IN_SET(a.`CODIGO_ART_ART`, p_ARTICULOS))
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
    -- 3) Base de medidas por (artículo, color, posición). Se rellena con
    --    ramas distintas según el modo para no calcular ventanas de
    --    movimientos cuando se pide acumulados.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_base`;
    CREATE TEMPORARY TABLE `tmp_bat_base` (
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `CODIGO_ALM`    VARCHAR(20)  NOT NULL DEFAULT '',
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
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`, `POSICION`, `COLOR`)
    );

    IF p_MODO = 'A' THEN
        -- Acumulados denormalizados del stock actual.
        INSERT INTO `tmp_bat_base`
            (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
             `POSICION`,
             `EXI_INI`, `ENT`, `SAL`, `VEN`, `EXI_FIN`,
             `ENT_COMPRA`, `ENT_ALBENTRADA`, `ENT_TRASPASO`, `ENT_DEPOSITO`,
             `ENT_REGULAR`, `SAL_TRASPASO`, `SAL_DEPOSITO`, `SAL_ALBVENTA`,
             `SAL_VENTA`)
        SELECT s.`CODIGO_ART`, IF(v_por_alm, st.`CODIGO_ALM_STK`, ''),
               s.`COLOR`, MIN(s.`COLOR_HEX`),
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
           AND st.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_bat_alm`)
         GROUP BY s.`CODIGO_ART`, IF(v_por_alm, st.`CODIGO_ALM_STK`, ''),
                  s.`POSICION`, s.`COLOR`;
    ELSE
        -- Entre fechas: movimientos del periodo + existencias
        -- reconstruidas desde el stock actual.
        INSERT INTO `tmp_bat_base`
            (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
             `POSICION`,
             `EXI_INI`, `ENT`, `SAL`, `VEN`, `EXI_FIN`,
             `ENT_COMPRA`, `ENT_ALBENTRADA`, `ENT_TRASPASO`, `ENT_DEPOSITO`,
             `ENT_REGULAR`, `SAL_TRASPASO`, `SAL_DEPOSITO`, `SAL_ALBVENTA`,
             `SAL_VENTA`)
        SELECT s.`CODIGO_ART`, COALESCE(mv.`ALM`, ''),
               s.`COLOR`, MIN(s.`COLOR_HEX`),
               MIN(s.`ORDEN_COLOR`), s.`POSICION`,
               -- Existencias iniciales: stock actual menos movimientos
               -- firmados desde p_DESDE (inclusive).
               SUM(COALESCE(mv.`STOCK_NOW`, 0) - COALESCE(mv.`DELTA_DESDE`, 0)),
               SUM(COALESCE(mv.`ENT`, 0)),
               SUM(COALESCE(mv.`SAL`, 0)),
               SUM(COALESCE(mv.`VEN`, 0)),
               -- Existencias finales: stock actual menos movimientos
               -- firmados posteriores a p_HASTA.
               SUM(COALESCE(mv.`STOCK_NOW`, 0) - COALESCE(mv.`DELTA_HASTA`, 0)),
               SUM(COALESCE(mv.`ENT_COMPRA`, 0)), SUM(COALESCE(mv.`ENT_ALBENTRADA`, 0)),
               SUM(COALESCE(mv.`ENT_TRASPASO`, 0)), SUM(COALESCE(mv.`ENT_DEPOSITO`, 0)),
               SUM(COALESCE(mv.`ENT_REGULAR`, 0)), SUM(COALESCE(mv.`SAL_TRASPASO`, 0)),
               SUM(COALESCE(mv.`SAL_DEPOSITO`, 0)), SUM(COALESCE(mv.`SAL_ALBVENTA`, 0)),
               SUM(COALESCE(mv.`SAL_VENTA`, 0))
          FROM `tmp_bat_sku` s
          LEFT JOIN (
                -- Stock actual y movimientos firmados unificados por unidad y
                -- almacén (UNION ALL para sumarlos en el mismo grano). Si no se
                -- agrupa por almacén, ALM = '' y todo colapsa en un único
                -- bucket (resultado idéntico al cálculo agregado anterior).
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
                         WHERE st2.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_bat_alm`)
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
                               IF(m.`TIPO_DOC_MOV` IN ('TR', 'AT') AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'DP' AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` = 'IN' AND m.`TIPO_MOV` = 'E'
                                  AND DATE(m.`FECHA_MOV`) BETWEEN v_desde AND v_hasta,
                                  m.`CANTIDAD_MOV`, 0),
                               IF(m.`TIPO_DOC_MOV` IN ('TR', 'AT') AND m.`TIPO_MOV` = 'S'
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
                           AND m.`CODIGO_ALM_MOV` IN (SELECT `CODIGO_ALM` FROM `tmp_bat_alm`)
                       ) u
                 GROUP BY u.`CODIGO_UNIDAD`, u.`ALM`
               ) mv ON mv.`CODIGO_UNIDAD` = s.`CODIGO_UNIDAD`
         GROUP BY s.`CODIGO_ART`, COALESCE(mv.`ALM`, ''),
                  s.`POSICION`, s.`COLOR`;
    END IF;

    -- -----------------------------------------------------------------
    -- 3b) Ventas REALES por (artículo, almacén, color, posición) desde las
    --     líneas de factura. Es la fuente de verdad de las ventas (cantidad
    --     E importe): los acumulados de stock (CANTIDAD_SAL_VENTA_STK) pueden
    --     no estar mantenidos y dar cantidad 0 aunque haya venta. La banda VEN
    --     toma de aquí su CANTIDAD por talla (antes salía del acumulado y no
    --     cuadraba con el importe, que ya venía de facturas). Mismo filtro de
    --     almacén/periodo y mismo conjunto de SKUs (tmp_bat_sku) que la
    --     valoración de ventas (vt) del SELECT final, para que cantidad e
    --     importe sean coherentes.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_ven`;
    CREATE TEMPORARY TABLE `tmp_bat_ven` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `COLOR`      VARCHAR(100)  NOT NULL DEFAULT '',
        `POSICION`   INT           NOT NULL,
        `VEN_QTY`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `POSICION`)
    );
    INSERT INTO `tmp_bat_ven`
    SELECT s.`CODIGO_ART`,
           IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, ''),
           s.`COLOR`, s.`POSICION`,
           SUM(fl.`CANTIDAD_FACLIN`)
      FROM `fza_facturas_lineas` fl
      JOIN `fza_facturas` f
        ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`
       AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`
      JOIN `tmp_bat_sku` s
        ON s.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN`
     WHERE fl.`CODIGO_ALM_FACLIN` IN (SELECT `CODIGO_ALM` FROM `tmp_bat_alm`)
       AND (p_MODO = 'A'
            OR DATE(f.`FECHA_FAC`) BETWEEN v_desde AND v_hasta)
     GROUP BY s.`CODIGO_ART`,
              IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, ''),
              s.`COLOR`, s.`POSICION`;

    -- -----------------------------------------------------------------
    -- 4) Desdoblar en bandas (forma larga). Cada banda es un INSERT
    --    independiente (referencia tmp_bat_base una sola vez) y se filtra
    --    por modo/desglosado. ES_COSTE marca cómo se valora la banda.
    --    ORDEN_BANDA fija el orden vertical del informe.
    -- -----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_medidas`;
    CREATE TEMPORARY TABLE `tmp_bat_medidas` (
        `CODIGO_ART`     VARCHAR(20)  NOT NULL,
        `CODIGO_ALM`     VARCHAR(20)  NOT NULL DEFAULT '',
        `COLOR`          VARCHAR(100) NULL,
        `COLOR_HEX`      VARCHAR(7)   NULL,
        `ORDEN_COLOR`    INT          NOT NULL DEFAULT 0,
        `POSICION`       INT          NOT NULL,
        `BANDA`          VARCHAR(20)  NOT NULL,
        `ORDEN_BANDA`    INT          NOT NULL,
        `ETIQUETA_BANDA` VARCHAR(40)  NOT NULL,
        `ES_COSTE`       TINYINT      NOT NULL DEFAULT 0,
        `CANTIDAD`       DECIMAL(19,6) NOT NULL DEFAULT 0,
        KEY `IDX_BAT_MED` (`CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `ORDEN_BANDA`)
    );

    -- Existencias iniciales: solo entre fechas.
    IF p_MODO = 'F' THEN
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'EXIINI', 10, 'Existencias iniciales', 1, `EXI_INI`
          FROM `tmp_bat_base`;
    END IF;
    -- Simplificado (F) o acumulados (A). Entradas = albaranes (compra + alb.
    -- entrada) + recuentos (regularizaciones) + traspasos NETOS (entrada -
    -- salida). SIN depósitos y SIN banda Salidas: las ventas van en su banda.
    -- Balance: Ex.ini + Entradas - Ventas = Ex.final (los depósitos quedan
    -- fuera de la ecuación, según lo pedido).
    IF (p_MODO = 'F' AND p_DESGLOSADO = 'N') OR p_MODO = 'A' THEN
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'ENT', 20, 'Entradas', 1,
               `ENT_COMPRA` + `ENT_ALBENTRADA` + `ENT_REGULAR`
                 + `ENT_TRASPASO` - `SAL_TRASPASO`
          FROM `tmp_bat_base`;
        -- Cantidad de la banda de ventas: de facturas (tmp_bat_ven) por talla,
        -- no del acumulado de stock. LEFT JOIN sobre la base para conservar la
        -- fila de ventas de cada color (0 si no hubo venta).
        INSERT INTO `tmp_bat_medidas`
        SELECT b.`CODIGO_ART`, b.`CODIGO_ALM`, b.`COLOR`, b.`COLOR_HEX`,
               b.`ORDEN_COLOR`, b.`POSICION`,
               'VEN', 50, 'Ventas', 0, COALESCE(v.`VEN_QTY`, 0)
          FROM `tmp_bat_base` b
          LEFT JOIN `tmp_bat_ven` v
            ON v.`CODIGO_ART` = b.`CODIGO_ART`
           AND v.`CODIGO_ALM` = b.`CODIGO_ALM`
           AND v.`COLOR` = b.`COLOR`
           AND v.`POSICION` = b.`POSICION`;
    END IF;
    -- Entradas desglosadas: solo modo entre fechas desglosado. Mismos
    -- subtipos que la consulta de stock (Ctrl+U), con traspasos y depósitos
    -- netos (entrada - salida) y sin bandas de salida salvo alb. venta.
    IF p_MODO = 'F' AND p_DESGLOSADO = 'S' THEN
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'ENTCMP', 21, 'Ent. compra', 1, `ENT_COMPRA`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'ENTALB', 22, 'Alb. entrada', 1, `ENT_ALBENTRADA`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'ENTTRA', 23, 'Traspasos (neto)', 1,
               `ENT_TRASPASO` - `SAL_TRASPASO`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'ENTDEP', 24, 'Depósitos (neto)', 1,
               `ENT_DEPOSITO` - `SAL_DEPOSITO`
          FROM `tmp_bat_base`;
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'ENTREG', 25, 'Regulariz.', 1, `ENT_REGULAR`
          FROM `tmp_bat_base`;
        -- Sal. traspaso / Sal. depósito ya no salen: se han neteado en sus
        -- bandas de entrada (Traspasos/Depósitos neto). Albarán de venta sí se
        -- mantiene (es una venta).
        INSERT INTO `tmp_bat_medidas`
        SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
               `POSICION`,
               'SALALB', 43, 'Alb. venta', 0, `SAL_ALBVENTA`
          FROM `tmp_bat_base`;
        -- Cantidad de ventas: de facturas (tmp_bat_ven) por talla, igual que
        -- en simplificado/acumulados (no del acumulado SAL_VENTA del stock).
        INSERT INTO `tmp_bat_medidas`
        SELECT b.`CODIGO_ART`, b.`CODIGO_ALM`, b.`COLOR`, b.`COLOR_HEX`,
               b.`ORDEN_COLOR`, b.`POSICION`,
               'VEN', 50, 'Ventas', 0, COALESCE(v.`VEN_QTY`, 0)
          FROM `tmp_bat_base` b
          LEFT JOIN `tmp_bat_ven` v
            ON v.`CODIGO_ART` = b.`CODIGO_ART`
           AND v.`CODIGO_ALM` = b.`CODIGO_ALM`
           AND v.`COLOR` = b.`COLOR`
           AND v.`POSICION` = b.`POSICION`;
    END IF;
    -- Existencias finales: siempre.
    INSERT INTO `tmp_bat_medidas`
    SELECT `CODIGO_ART`, `CODIGO_ALM`, `COLOR`, `COLOR_HEX`, `ORDEN_COLOR`,
           `POSICION`,
           'EXIFIN', 90, 'Existencias finales', 1, `EXI_FIN`
      FROM `tmp_bat_base`;
    -- Selección de bandas: sin selección = todas las de la configuración
    -- (modo/detalle). FIND_IN_SET sobre el código de banda.
    IF p_BANDAS <> '' THEN
        DELETE FROM `tmp_bat_medidas` WHERE NOT FIND_IN_SET(`BANDA`, p_BANDAS);
    END IF;

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
        p.`CODIGO_ALM`                                AS `CODIGO_ALM`,
        COALESCE(alm.`NOMBRE_ALM_ALM`, '')            AS `NOMBRE_ALM`,
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
        -- banda EXIFIN, 0 en el resto. Permite que el total por grupo/general
        -- muestre SOLO el stock final, sin mezclar entradas/salidas/ventas.
        IF(p.`BANDA` = 'EXIFIN', p.`CANTIDAD`, 0)     AS `EXIFIN_CANT`,
        ROUND(IF(p.`BANDA` = 'EXIFIN',
                 p.`CANTIDAD` * COALESCE(NULLIF(cst.`COSTE`, 0),
                                         prov.`COSTE_PRV`, 0),
                 0), 2)                               AS `EXIFIN_IMP`,
        -- Niveles de agrupación configurables. GRUPOn_COD identifica el grupo
        -- (para el corte y el orden); GRUPOn_ETIQ es la etiqueta a mostrar en
        -- la cabecera/resumen. Si el nivel no está activo (''), salen vacíos y
        -- el cliente no dibuja banda de grupo a ese nivel.
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
             GROUP BY m.`CODIGO_ART`, m.`CODIGO_ALM`, m.`COLOR`, m.`BANDA`,
                      m.`ORDEN_BANDA`, m.`ETIQUETA_BANDA`, m.`ES_COSTE`
           ) p
      JOIN `fza_articulos` art ON art.`CODIGO_ART_ART` = p.`CODIGO_ART`
      LEFT JOIN `fza_articulos_familias` fam
        ON fam.`CODIGO_FAM_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `tmp_bat_fam_grp` fg ON fg.`CODIGO_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `fza_almacenes` alm ON alm.`CODIGO_ALM_ALM` = p.`CODIGO_ALM`
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
             WHERE st.`CODIGO_ALM_STK` IN (SELECT `CODIGO_ALM` FROM `tmp_bat_alm`)
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
             GROUP BY ap.`CODIGO_ART_AP`
           ) prov ON prov.`CODIGO_ART` = p.`CODIGO_ART`
      -- Temporada EFECTIVA por color (Fase 3): la vista de propiedades
      -- efectivas resuelve color -> articulo; tmp_bat_sku da el color del
      -- SKU. Los SKU de un mismo color comparten temporada (el MAX colapsa
      -- sin ambiguedad). Sin datos de color resuelve al valor de articulo.
      LEFT JOIN (
            SELECT s.`CODIGO_ART` AS `CODIGO_ART`, s.`COLOR` AS `COLOR`,
                   MAX(COALESCE(e.`VALOR_PV`,
                                e.`VALOR_LIBRE_ARTPROP`)) AS `TEMPORADA`
              FROM `tmp_bat_sku` s
              JOIN `vi_articulos_propiedades_efectivas` e
                ON e.`CODIGO_UNIDAD_SKU` = s.`CODIGO_UNIDAD`
               AND e.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
             GROUP BY s.`CODIGO_ART`, s.`COLOR`
           ) tmp ON tmp.`CODIGO_ART` = p.`CODIGO_ART`
                AND tmp.`COLOR` = p.`COLOR`
      LEFT JOIN (
            -- Ventas REALES (con descuento, con IVA) por (artículo, almacén,
            -- color), de las líneas de factura/ticket. Periodo por fecha de
            -- factura (entre fechas) o histórico (acumulados). Se enlaza el SKU
            -- de la línea a tmp_bat_sku para resolver artículo/color y restringir
            -- a los artículos filtrados.
            SELECT s.`CODIGO_ART`,
                   IF(v_por_alm, fl.`CODIGO_ALM_FACLIN`, '') AS `CODIGO_ALM`,
                   s.`COLOR`,
                   SUM(fl.`CANTIDAD_FACLIN`) AS `VEN_QTY`,
                   SUM(fl.`TOTAL_FACLIN`)    AS `VEN_IMPORTE`
              FROM `fza_facturas_lineas` fl
              JOIN `fza_facturas` f
                ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`
               AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`
              JOIN `tmp_bat_sku` s
                ON s.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN`
             WHERE fl.`CODIGO_ALM_FACLIN` IN (SELECT `CODIGO_ALM` FROM `tmp_bat_alm`)
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

    -- Limpieza de temporales para no arrastrarlas en la sesión.
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_medidas`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_ven`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_base`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_sku`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_etiq`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_pos_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_pos`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_fam_grp`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_fam`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_bat_alm`;
END ;;
DELIMITER ;

-- ---------------------------------------------------------------------
-- Parámetros: (p_MODO, p_DESDE, p_HASTA, p_ALMACENES, p_FAMILIAS,
--              p_PROVEEDORES, p_TEMPORADAS, p_ARTICULOS, p_COD_TARIFA,
--              p_DESGLOSADO, p_BANDAS, p_NIVEL1, p_NIVEL2, p_NIVEL3,
--              p_NIVEL_FAM).
-- Todos los filtros multi-valor son CSV; '' = sin filtro (todos). p_ARTICULOS
-- restringe el informe a una lista de códigos de artículo (FIND_IN_SET sobre
-- CODIGO_ART_ART). p_BANDAS limita qué bandas salen (códigos
-- EXIINI/ENT/SAL/VEN/EXIFIN y, en desglosado,
-- ENTCMP/ENTALB/ENTTRA/ENTDEP/ENTREG/SALTRA/SALDEP/SALALB).
-- p_NIVEL1/2/3 definen la jerarquía de agrupación con resumen por grupo:
-- PRV (proveedor), FAM (familia), TMP (temporada), ALM (almacén) o ''
-- (nivel inactivo). El orden importa: NIVEL1 es el grupo más externo. La
-- salida añade GRUPO1_COD/GRUPO1_ETIQ..GRUPO3_COD/GRUPO3_ETIQ y ordena por
-- ellas; el cliente (FastReport / Excel) dibuja las cabeceras y la línea
-- de resumen (cantidad + importe) en cada corte de grupo. Si algún nivel es
-- ALM, los cálculos se desglosan por almacén (si no, se agregan todos los
-- almacenes filtrados). p_NIVEL_FAM elige el nivel del árbol de familias al
-- agrupar por FAM (1 = familia raíz; <1 o NULL = familia hoja del artículo).
-- Ejemplos de uso (desde el modal de impresión preparar_consulta):
--   -- Entre fechas, simplificado, todos los almacenes, todas las bandas,
--   -- sin agrupación adicional
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('F','2026-05-01','2026-05-21','','','','','','PVP','N','','','','',0);
--   -- Entre fechas, desglosado, almacenes 01 y 50, familias 0103 y 0104
--   -- (cada familia incluye su descendencia), proveedor PRV001, temporada V26,
--   -- solo las bandas de existencias y ventas, agrupando por proveedor y
--   -- dentro de cada proveedor por la familia raíz (nivel 1 del árbol)
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('F','2026-05-01','2026-05-21','01,50','0103,0104','PRV001','V26','','PVP','S','EXIINI,VEN,EXIFIN','PRV','FAM','',1);
--   -- Por acumulados, todas las bandas, agrupado por almacén y temporada
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('A',NULL,NULL,'','','','','','PVP','N','','ALM','TMP','',0);
--   -- Acumulados restringido a dos artículos concretos (resto de filtros
--   -- vacíos = todos)
--   CALL PRC_GET_BALANCE_ALMACEN_TALLAS('A',NULL,NULL,'','','','','ART001,ART002','PVP','N','','','','',0);
-- ---------------------------------------------------------------------
