-- =============================================================================
-- Optimizar PRC_GET_CAJA_STOCK_PIVOTADO y PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ
-- =============================================================================
-- Estos SPs reciben un input (codigo de articulo o SKU) y devuelven el stock
-- pivotado (almacenes en filas, tallas en columnas) para la pantalla de caja.
--
-- Antes (medido en sesion real, ConsultarStock SP=627 ms):
--   El SP hacia 6 sub-queries antes del PREPARE de la query final:
--     1. SELECT CODIGO_ART_ART FROM fza_articulos WHERE = p_input
--     2. (Si NULL) SELECT CODIGO_ART_SKU FROM fza_articulos_skus WHERE = p_input
--     3. SELECT pivot via 4 JOINs (sk -> ask -> av -> va) ORDER BY ORDEN_VA DESC
--     4. SELECT grupo/fila via 4 JOINs (idem) ORDER BY ORDEN_VA <DIR>
--     5. (Si SKU) SELECT valor del grupo (2 JOINs)
--     6. SELECT GROUP_CONCAT de columnas dinamicas (3 JOINs)
--   La query final pivotada en si ejecutaba en <1 ms (medido con
--   ANALYZE FORMAT=JSON: r_total_time_ms = 0.327). Los 627 ms se iban
--   enteros en las queries previas + overhead PREPARE.
--
-- Despues (estimado 150-250 ms):
--   - 1+2 combinadas en COALESCE: 1 round-trip en lugar de 2.
--   - 3 reescrita usando fza_articulos.TIPO_VARIACION_ART + fza_variaciones_atributos:
--     PK seek + index seek por TIPO_VARIACION_ART (ya tiene indice). El
--     resultado es identico para articulos con variacion bien definida —
--     mismo principio que aplicamos en ActualizarColumnasDinamicas (bajado
--     de 9.6 s a 14 ms).
--   - 4 idem reescrita.
--   - 5 sin cambios (2 JOINs filtrados por PK del SKU, ya es rapida).
--   - 6 sin cambios (necesita los AV reales de los SKUs, no del catalogo).
--
-- Importante: NO TOCAMOS la query final pivotada — el plan es correcto y
-- ejecuta en sub-milisegundo segun ANALYZE.
--
-- Idempotente: usa DROP PROCEDURE IF EXISTS + CREATE PROCEDURE. Re-aplicar
-- el script no rompe nada — sobreescribe los SPs con la version optimizada.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- PRC_GET_CAJA_STOCK_PIVOTADO
--   Devuelve el stock solo de los almacenes que tienen alguna fila para el
--   articulo. Es la version "compacta" usada en inMtoCajaOpe.qryStock.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;

    /* Variables para identificar que es Talla (Pivot) y que es Color (Grupo) */
    DECLARE v_id_atributo_pivot VARCHAR(20);  /* Ej: TAL */
    DECLARE v_id_atributo_grupo VARCHAR(20);  /* Ej: CO */

    /* Variable para filtrar si entramos con un SKU especifico (Ej: NEGRO) */
    DECLARE v_valor_grupo_filtro VARCHAR(50) DEFAULT NULL;

    DECLARE v_columnas_dinamicas TEXT;

    /* 1. RESOLUCION DE IDENTIDAD (¿Es Padre o SKU?)
       Antes: 2 sub-queries secuenciales (~100ms cada una con overhead SP).
       Ahora: COALESCE en una sola sentencia. PK seek en fza_articulos
       primero (el caso comun); si devuelve NULL, PK seek en
       fza_articulos_skus. El optimizador evalua el segundo SELECT solo
       cuando el primero da NULL.
       Si el resultado difiere del input literal, era un SKU. */
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

    /* 2. ESTRATEGIA DE ATRIBUTOS
       Antes: SET v_id_atributo_pivot = (SELECT ... 4-way JOIN sk -> ask -> av -> va
              WHERE sk.CODIGO_ART_SKU = v_codigo_articulo ORDER BY va.ORDEN_VA DESC LIMIT 1)
              + idem para el grupo. 2 round-trips, 8 JOINs en total.
       Ahora: PK seek sobre fza_articulos para sacar TIPO_VARIACION_ART, y
              index seek sobre fza_variaciones_atributos. Los atributos de
              la variacion estan definidos ahi, no hace falta recorrer SKUs.
              Mismo cambio que metimos en ActualizarColumnasDinamicas. */
    IF v_codigo_articulo IS NOT NULL THEN
        SELECT vat.ID_ATB_VA
          INTO v_id_atributo_pivot
          FROM fza_articulos art
          JOIN fza_variaciones_atributos vat
            ON vat.ID_VAR_VA = art.TIPO_VARIACION_ART
         WHERE art.CODIGO_ART_ART = v_codigo_articulo
         ORDER BY vat.ORDEN_VA DESC
         LIMIT 1;

        SELECT vat.ID_ATB_VA
          INTO v_id_atributo_grupo
          FROM fza_articulos art
          JOIN fza_variaciones_atributos vat
            ON vat.ID_VAR_VA = art.TIPO_VARIACION_ART
         WHERE art.CODIGO_ART_ART = v_codigo_articulo
           AND vat.ID_ATB_VA <> COALESCE(v_id_atributo_pivot, '')
         ORDER BY vat.ORDEN_VA DESC
         LIMIT 1;
    END IF;

    /* 3. SI TENEMOS ESTRUCTURA PARA PIVOTAR... */
    IF v_id_atributo_pivot IS NOT NULL THEN

        /* 3.1 Si es SKU, detectamos el valor del atributo "Grupo".
           Sin cambios — 2 JOINs filtrados por PK del SKU. */
        IF v_es_sku = TRUE AND v_id_atributo_grupo IS NOT NULL THEN
            SET v_valor_grupo_filtro = (
                SELECT av.AV
                  FROM fza_atributos_sku ask
                  JOIN fza_atributos_valores av ON ask.ID_AV_SA = av.ID_AV
                 WHERE ask.CODIGO_UNIDAD_SKU_SA = p_input
                   AND av.ID_VA_AV = v_id_atributo_grupo
                 LIMIT 1
            );
        END IF;

        /* 3.2 Construir columnas dinamicas (S, M, L...).
           Sin cambios — necesitamos los AV REALES presentes en los SKUs del
           articulo, no los del catalogo (un articulo puede no usar todas las
           tallas posibles). Filtrado por CODIGO_ART_SKU (IDX_SKU_ART_ACT) y
           ID_VA_AV (IDX_VAR_AV). */
        SELECT GROUP_CONCAT(DISTINCT
            CONCAT(
                'SUM(CASE WHEN av_p.AV = ''', REPLACE(av.AV, '''', ''''''),
                ''' THEN stk.CANTIDAD_STK ELSE 0 END) AS `', REPLACE(av.AV, '`', '``'), '`'
            )
            ORDER BY av.ID_AV
        ) INTO v_columnas_dinamicas
        FROM fza_articulos_skus sk
        JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
        JOIN fza_atributos_valores av ON ask.ID_AV_SA = av.ID_AV
        WHERE sk.CODIGO_ART_SKU = v_codigo_articulo
          AND av.ID_VA_AV = v_id_atributo_pivot;

        /* 3.3 Construir Query Final — sin cambios. */
        IF v_columnas_dinamicas IS NOT NULL THEN
            SET @sql = CONCAT(
                'SELECT
                    CONCAT(''', v_codigo_articulo, ''',
                        CASE
                            WHEN av_g.AV IS NOT NULL THEN CONCAT(''/'', av_g.AV)
                            ELSE ''''
                        END
                    ) AS Codigo,
                    alm.NOMBRE_ALM_ALM AS Almacen, ',
                    v_columnas_dinamicas, ',
                    SUM(stk.CANTIDAD_STK) AS Total
                 FROM fza_articulos_stockactual stk
                 JOIN fza_almacenes alm ON stk.CODIGO_ALM_STK = alm.CODIGO_ALM_ALM
                 JOIN fza_articulos_skus sk ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU

                 JOIN fza_atributos_sku ask_p ON sk.CODIGO_UNIDAD_SKU = ask_p.CODIGO_UNIDAD_SKU_SA
                 JOIN fza_atributos_valores av_p ON ask_p.ID_AV_SA = av_p.ID_AV
                    AND av_p.ID_VA_AV = ''', v_id_atributo_pivot, '''

                 LEFT JOIN fza_atributos_sku ask_g ON sk.CODIGO_UNIDAD_SKU = ask_g.CODIGO_UNIDAD_SKU_SA
                 LEFT JOIN fza_atributos_valores av_g ON ask_g.ID_AV_SA = av_g.ID_AV
                    AND av_g.ID_VA_AV = ''', IFNULL(v_id_atributo_grupo, 'xxx'), '''

                 WHERE sk.CODIGO_ART_SKU = ''', v_codigo_articulo, '''
                 ',
                 CASE WHEN v_valor_grupo_filtro IS NOT NULL THEN
                    CONCAT(' AND av_g.AV = ''', REPLACE(v_valor_grupo_filtro, '''', ''''''), ''' ')
                 ELSE '' END, '

                 GROUP BY av_g.AV, alm.NOMBRE_ALM_ALM
                 ORDER BY alm.NOMBRE_ALM_ALM, av_g.AV'
            );

            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

        END IF;
    END IF;

    /* CASO B: FALLBACK (Si no tiene atributos complejos o falla el pivotado) */
    IF v_columnas_dinamicas IS NULL THEN
        SELECT stk.CODIGO_UNIDAD_STK as Codigo,
            alm.NOMBRE_ALM_ALM as Almacen,
            SUM(stk.CANTIDAD_STK) as Stock_Total
        FROM fza_articulos_stockactual stk
        JOIN fza_almacenes alm ON stk.CODIGO_ALM_STK = alm.CODIGO_ALM_ALM
        WHERE stk.CODIGO_UNIDAD_STK = p_input
        GROUP BY stk.CODIGO_UNIDAD_STK, alm.NOMBRE_ALM_ALM
        ORDER BY alm.NOMBRE_ALM_ALM;
    END IF;

END ;;
DELIMITER ;


-- -----------------------------------------------------------------------------
-- PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ
--   Misma logica pero la query final arranca desde fza_almacenes con LEFT
--   JOIN: muestra TODOS los almacenes activos aunque tengan cero stock.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;

    /* Variables para las COLUMNAS (Pivot - Ej: Talla) */
    DECLARE v_id_atributo_pivot VARCHAR(20);
    DECLARE v_nombre_atributo_pivot VARCHAR(50);
    DECLARE v_columnas_dinamicas TEXT;

    /* Variables para las FILAS (Desglose - Ej: Color) */
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

    /* 2. BUSCAR ATRIBUTO PIVOTE (Para las columnas).
       Optimizado: via TIPO_VARIACION_ART (PK seek + index seek). */
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

    /* 2.1 BUSCAR ATRIBUTO DE FILA (Ej: Color) SI ES UN ARTICULO GENERICO.
       Mantenemos ORDER BY ORDEN_VA ASC (la semantica original del SP _WITHZ
       difiere del PIVOTADO sin Z, que usaba DESC excluyendo el pivot).
       Para variaciones de 2 atributos da el mismo resultado. */
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

        /* Preparamos los textos dinamicos para desglosar el Color en filas */
        IF v_id_atributo_fila IS NOT NULL THEN
            SET v_select_fila = CONCAT(', COALESCE(src.VALOR_FILA, ''-'') AS `', v_nombre_atributo_fila, '`');
            SET v_src_select_fila = ', av_fila.AV AS VALOR_FILA';
            SET v_join_fila = CONCAT(' LEFT JOIN fza_atributos_sku ask_fila ON sk.CODIGO_UNIDAD_SKU = ask_fila.CODIGO_UNIDAD_SKU_SA LEFT JOIN fza_atributos_valores av_fila ON ask_fila.ID_AV_SA = av_fila.ID_AV AND av_fila.ID_VA_AV = ''', v_id_atributo_fila, ''' ');
            SET v_groupby_fila = ', src.VALOR_FILA';
        END IF;

        /* Generamos columnas dinamicas apuntando a la subconsulta 'src'.
           Sin cambios — necesita los AV reales de los SKUs. */
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

        /* Filtros SKU (Solo aplica si buscas un SKU especifico) */
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

        /* QUERY FINAL: Almacen + Atributo Fila (Color) + Columnas Dinamicas (Talla) */
        SET @sql = CONCAT(
            'SELECT
                alm.NOMBRE_ALM_ALM AS Almacen',
                v_select_fila, ', ',
                v_columnas_dinamicas, ',
                COALESCE(SUM(src.CANTIDAD_STK), 0) AS Total
             FROM fza_almacenes alm
             LEFT JOIN (
                SELECT stk.CODIGO_ALM_STK, av.AV, stk.CANTIDAD_STK', v_src_select_fila, '
                FROM fza_articulos_stockactual stk
                JOIN fza_articulos_skus sk ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
                JOIN fza_atributos_sku ask ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
                JOIN fza_atributos_valores av ON ask.ID_AV_SA = av.ID_AV',
                v_join_fila, '
                WHERE sk.CODIGO_ART_SKU = ''', v_codigo_articulo, '''
                  AND av.ID_VA_AV = ''', v_id_atributo_pivot, ''' ',
                  v_filtros_fijos, '
             ) src ON alm.CODIGO_ALM_ALM = src.CODIGO_ALM_STK
             WHERE alm.ESACTIVO_ALM = ''S''
             GROUP BY alm.NOMBRE_ALM_ALM', v_groupby_fila, '
             ORDER BY alm.NOMBRE_ALM_ALM', v_groupby_fila
        );

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSE
        /* CASO B: ARTICULO SIMPLE (Sin atributos) */
        SELECT
            alm.NOMBRE_ALM_ALM as Almacen,
            COALESCE(SUM(stk.CANTIDAD_STK), 0) as `Stock Total`
        FROM fza_almacenes alm
        LEFT JOIN fza_articulos_stockactual stk
            ON alm.CODIGO_ALM_ALM = stk.CODIGO_ALM_STK
            AND stk.CODIGO_UNIDAD_STK = p_input
        WHERE alm.ESACTIVO_ALM = 'S'
        GROUP BY alm.NOMBRE_ALM_ALM
        ORDER BY alm.NOMBRE_ALM_ALM;

    END IF;
END ;;
DELIMITER ;


-- =============================================================================
-- Smoke test (ejecutar manualmente para verificar):
-- =============================================================================
--   CALL PRC_GET_CAJA_STOCK_PIVOTADO('01010021');
--   CALL PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ('01010021');
--   CALL PRC_GET_CAJA_STOCK_PIVOTADO('01010021/ORO/50');
--   CALL PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ('01010021/ORO/50');
--
-- Si el articulo no tiene TIPO_VARIACION_ART (articulo simple sin atributos),
-- v_id_atributo_pivot queda NULL y caemos al fallback de la query simple.
-- Comportamiento identico al original.
