-- =============================================================================
-- Pestaña 8_Stock del artículo: consulta limpia (sin ceros, sin sumatorios)
-- =============================================================================
-- Redefine PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ, que es el SP que alimenta la
-- rejilla tvStock de inMtoArticulos (pestaña 8_Stock). Es el ÚNICO sitio que
-- usa este SP — la caja y el traspaso usan PRC_GET_CAJA_STOCK_PIVOTADO.
--
-- Problema (lo que se veía antes en la pestaña):
--   1. Filas a cero: la versión _WITHZ arrancaba la query final desde
--      fza_almacenes con LEFT JOIN, así que pintaba TODOS los almacenes
--      activos aunque no tuvieran ni una unidad del artículo (AMAZON,
--      CENTRAL, CITY... todo a 0).
--   2. Filas de sumatorio "-": el desglose por color hacía
--      LEFT JOIN fza_atributos_sku ask_fila, que reengancha TODOS los
--      atributos del SKU (también la talla). La fila de la talla no casa
--      con el atributo color, así que av_fila quedaba NULL → COALESCE '-'.
--      Resultado: por cada almacén con stock aparecía una fila "-" cuya
--      cantidad era EXACTAMENTE la suma de las filas de color reales (un
--      duplicado del stock agrupado bajo color NULL). Eso es la "fila de
--      sumatorio" que el usuario no quiere.
--
-- Solución (deja la consulta "como la que sale en caja"):
--   1. Sin ceros: la query final arranca FROM la subconsulta de stock (src)
--      y hace JOIN a fza_almacenes. Solo salen los almacenes que tienen
--      stock real del artículo. Si el artículo no tiene stock, la rejilla
--      queda vacía (es lo correcto: "sólo lo que hay en el stock").
--   2. Sin sumatorios: el desglose por color pasa de LEFT JOIN a JOIN. La
--      fila fantasma de color NULL ('-') desaparece y cada unidad de stock
--      se cuenta una sola vez, bajo su color real.
--
-- Nota de modelo de datos: en Factuzam una variación de 2 atributos
-- (color × talla) genera SKUs que SIEMPRE llevan los dos valores, así que
-- el JOIN al color no esconde stock real — solo elimina el duplicado.
--
-- Se conservan las optimizaciones de perf de optimizar_caja_stock_pivotado.sql
-- (identificación vía COALESCE + atributos vía TIPO_VARIACION_ART). Este
-- script es autosuficiente: aplicarlo deja el SP en su estado final correcto
-- independientemente de si el de optimización ya se había aplicado.
--
-- Idempotente: DROP PROCEDURE IF EXISTS + CREATE PROCEDURE. Re-aplicable sin
-- riesgo. NO se toca factuzam_original.sql (regla del proyecto).
-- =============================================================================
DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;
    /* COLUMNAS (Pivot - Ej: Talla) */
    DECLARE v_id_atributo_pivot VARCHAR(20);
    DECLARE v_nombre_atributo_pivot VARCHAR(50);
    DECLARE v_columnas_dinamicas TEXT;
    /* FILAS (Desglose - Ej: Color) */
    DECLARE v_id_atributo_fila VARCHAR(20) DEFAULT NULL;
    DECLARE v_nombre_atributo_fila VARCHAR(50) DEFAULT NULL;
    DECLARE v_select_fila TEXT DEFAULT '';
    DECLARE v_join_fila TEXT DEFAULT '';
    DECLARE v_groupby_fila TEXT DEFAULT '';
    DECLARE v_src_select_fila TEXT DEFAULT '';
    DECLARE v_filtros_fijos TEXT DEFAULT '';
    DECLARE v_sql_query TEXT;
    /* 1. IDENTIFICAR ARTICULO O SKU — COALESCE en una sola sentencia. */
    SELECT COALESCE(
        (SELECT CODIGO_ART_ART
           FROM fza_articulos
          WHERE CODIGO_ART_ART = p_input
          LIMIT 1),
        (SELECT CODIGO_ART_SKU
           FROM fza_articulos_skus
          WHERE CODIGO_UNIDAD_SKU = p_input
          LIMIT 1)
    ) INTO v_codigo_articulo;
    IF v_codigo_articulo IS NOT NULL AND v_codigo_articulo <> p_input THEN
        SET v_es_sku = TRUE;
    END IF;
    /* 2. ATRIBUTO PIVOTE (columnas) vía TIPO_VARIACION_ART (PK + index seek). */
    IF v_codigo_articulo IS NOT NULL THEN
        SELECT vat.ID_ATB_VA, vat.NOMBRE_VA
          INTO v_id_atributo_pivot, v_nombre_atributo_pivot
          FROM fza_articulos art
          JOIN fza_variaciones_atributos vat
            ON vat.ID_VAR_VA = art.TIPO_VARIACION_ART
         WHERE art.CODIGO_ART_ART = v_codigo_articulo
         ORDER BY vat.ORDEN_VA DESC
         LIMIT 1;
    END IF;
    /* 2.1 ATRIBUTO DE FILA (Ej: Color) si es un artículo genérico. */
    IF v_codigo_articulo IS NOT NULL AND v_es_sku = FALSE THEN
        SELECT vat.ID_ATB_VA, vat.NOMBRE_VA
          INTO v_id_atributo_fila, v_nombre_atributo_fila
          FROM fza_articulos art
          JOIN fza_variaciones_atributos vat
            ON vat.ID_VAR_VA = art.TIPO_VARIACION_ART
         WHERE art.CODIGO_ART_ART = v_codigo_articulo
           AND vat.ID_ATB_VA <> v_id_atributo_pivot
         ORDER BY vat.ORDEN_VA ASC
         LIMIT 1;
    END IF;
    /* 3. CONSTRUCCION DE LA CONSULTA */
    IF v_id_atributo_pivot IS NOT NULL THEN
        /* Desglose del color en filas. JOIN (no LEFT JOIN): así la talla no
           genera la fila fantasma de color NULL ('-') que duplicaba el stock. */
        IF v_id_atributo_fila IS NOT NULL THEN
            SET v_select_fila = CONCAT(', src.VALOR_FILA AS `', v_nombre_atributo_fila, '`');
            SET v_src_select_fila = ', av_fila.AV AS VALOR_FILA';
            SET v_join_fila = CONCAT(' JOIN fza_atributos_sku ask_fila ON sk.CODIGO_UNIDAD_SKU = ask_fila.CODIGO_UNIDAD_SKU_SA JOIN fza_atributos_valores av_fila ON ask_fila.ID_AV_SA = av_fila.ID_AV AND av_fila.ID_VA_AV = ''', v_id_atributo_fila, ''' ');
            SET v_groupby_fila = ', src.VALOR_FILA';
        END IF;
        /* Columnas dinámicas (S, M, L...) apuntando a la subconsulta 'src'.
           Necesita los AV reales de los SKUs del artículo. */
        SELECT GROUP_CONCAT(DISTINCT
            CONCAT(
                'SUM(CASE WHEN src.AV = ''', av.AV,
                ''' THEN src.CANTIDAD_STK ELSE 0 END) AS `', av.AV, '`'
            )
            ORDER BY av.ID_AV
        ) INTO v_columnas_dinamicas
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
        JOIN fza_atributos_valores av ON ask.ID_AV_SA = av.ID_AV
        WHERE sk.CODIGO_ART_SKU = v_codigo_articulo
          AND av.ID_VA_AV = v_id_atributo_pivot;
        /* Filtros SKU (solo si se entra con un SKU específico). */
        IF v_es_sku = TRUE THEN
            SELECT GROUP_CONCAT(
                CONCAT(
                    ' AND EXISTS (SELECT 1 FROM fza_atributos_sku f_ask ',
                    ' JOIN fza_atributos_valores f_av ON f_ask.ID_AV_SA = f_av.ID_AV ',
                    ' WHERE f_ask.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ',
                    ' AND f_av.ID_VA_AV = ''', av.ID_VA_AV, ''' ',
                    ' AND f_av.AV = ''', av.AV, ''') '
                ) SEPARATOR ' '
            ) INTO v_filtros_fijos
            FROM fza_atributos_sku ask
            JOIN fza_atributos_valores av ON ask.ID_AV_SA = av.ID_AV
            WHERE ask.CODIGO_UNIDAD_SKU_SA = p_input
              AND av.ID_VA_AV <> v_id_atributo_pivot;
        END IF;
        IF v_filtros_fijos IS NULL THEN SET v_filtros_fijos = ''; END IF;
        /* Artículo con pivote pero sin SKUs aún → GROUP_CONCAT NULL → fallback. */
        IF v_columnas_dinamicas IS NOT NULL THEN
            /* QUERY FINAL: arranca FROM la subconsulta de stock (src) y JOIN a
               almacenes. Solo aparecen almacenes con stock real → sin ceros. */
            SET @sql = CONCAT(
                'SELECT
                    alm.NOMBRE_ALM_ALM AS Almacen',
                    v_select_fila, ', ',
                    v_columnas_dinamicas, ',
                    SUM(src.CANTIDAD_STK) AS Total
                 FROM (
                    SELECT stk.CODIGO_ALM_STK, av.AV, stk.CANTIDAD_STK', v_src_select_fila, '
                    FROM fza_articulos_stockactual stk
                    JOIN fza_articulos_skus sk ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
                    JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
                    JOIN fza_atributos_valores av ON ask.ID_AV_SA = av.ID_AV',
                    v_join_fila, '
                    WHERE sk.CODIGO_ART_SKU = ''', v_codigo_articulo, '''
                      AND av.ID_VA_AV = ''', v_id_atributo_pivot, ''' ',
                      v_filtros_fijos, '
                 ) src
                 JOIN fza_almacenes alm ON alm.CODIGO_ALM_ALM = src.CODIGO_ALM_STK
                 GROUP BY alm.NOMBRE_ALM_ALM', v_groupby_fila, '
                 ORDER BY alm.NOMBRE_ALM_ALM', v_groupby_fila
            );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
    END IF;
    /* Fallback: artículo simple, sin TIPO_VARIACION_ART o con pivote pero sin
       SKUs. Una fila por almacén CON stock (sin ceros: arranca FROM stock). */
    IF v_id_atributo_pivot IS NULL OR v_columnas_dinamicas IS NULL THEN
        SELECT
            alm.NOMBRE_ALM_ALM as Almacen,
            SUM(stk.CANTIDAD_STK) as `Stock Total`
        FROM fza_articulos_stockactual stk
        JOIN fza_almacenes alm ON stk.CODIGO_ALM_STK = alm.CODIGO_ALM_ALM
        WHERE stk.CODIGO_UNIDAD_STK = p_input
        GROUP BY alm.NOMBRE_ALM_ALM
        ORDER BY alm.NOMBRE_ALM_ALM;
    END IF;
END ;;
DELIMITER ;
-- =============================================================================
-- Smoke test (ejecutar manualmente):
--   CALL PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ('01010021');
--   CALL PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ('01010021/ORO/50');
-- Comprobaciones:
--   - No aparecen almacenes sin stock del artículo.
--   - No aparece ninguna fila con color '-' (la antigua fila de sumatorio).
--   - La suma de las filas de color de un almacén coincide con la que antes
--     mostraba la fila '-' de ese almacén.
-- =============================================================================
