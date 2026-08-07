-- SPDX-License-Identifier: MPL-2.0
-- Conserva el orden de las tallas de cada articulo procedente de
-- dbo.ocarttal.Orden. Es idempotente y no altera las asignaciones existentes.

ALTER TABLE `fza_articulos_atributos_basicos`
  ADD COLUMN IF NOT EXISTS `ORDEN_AAB` int(11) NULL DEFAULT NULL
    COMMENT 'Orden del valor dentro del articulo; en tallas procede de ocarttal.Orden.'
    AFTER `DESCRIPCION_AAB`;

-- Fallback razonable hasta volver a ejecutar la migracion articulos_tallas.
-- Esa migracion sustituye este valor global por el Orden exacto de ocarttal.
UPDATE `fza_articulos_atributos_basicos` aab
JOIN `fza_atributos_valores` av ON av.ID_AV = aab.ID_AV_AAB
   SET aab.ORDEN_AAB = av.ORDEN_AV
 WHERE av.ID_VA_AV = 'TAL'
   AND aab.ORDEN_AAB IS NULL;

-- La consulta rapida de Caja genera las tallas como columnas dinamicas.
-- Se recrean las dos variantes porque el perfil SQL puede elegir la que
-- incluye almacenes sin stock (WITHZ). En ambas manda el orden del articulo.
DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;
    DECLARE v_id_atributo_pivot VARCHAR(20);
    DECLARE v_id_atributo_grupo VARCHAR(20);
    DECLARE v_valor_grupo_filtro VARCHAR(50) DEFAULT NULL;
    DECLARE v_columnas_dinamicas TEXT;
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
    IF v_id_atributo_pivot IS NOT NULL THEN
        IF v_es_sku = TRUE AND v_id_atributo_grupo IS NOT NULL THEN
            SET v_valor_grupo_filtro = (
                SELECT av.AV
                  FROM fza_atributos_sku ask
                  JOIN fza_atributos_valores av
                    ON ask.ID_AV_SA = av.ID_AV
                 WHERE ask.CODIGO_UNIDAD_SKU_SA = p_input
                   AND av.ID_VA_AV = v_id_atributo_grupo
                 LIMIT 1
            );
        END IF;
        SELECT GROUP_CONCAT(
            CONCAT(
                'SUM(CASE WHEN av_p.AV = ''',
                REPLACE(t.AV, '''', ''''''),
                ''' THEN stk.CANTIDAD_STK ELSE 0 END) AS `',
                REPLACE(t.AV, '`', '``'), '`'
            )
            ORDER BY t.ORDEN_TALLA, t.AV
        ) INTO v_columnas_dinamicas
        FROM (
            SELECT av.AV,
                   MIN(COALESCE(aab.ORDEN_AAB, av.ORDEN_AV))
                     AS ORDEN_TALLA
              FROM fza_articulos_skus sk
              JOIN fza_atributos_sku ask
                ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
              JOIN fza_atributos_valores av
                ON ask.ID_AV_SA = av.ID_AV
              LEFT JOIN fza_articulos_atributos_basicos aab
                ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU
               AND aab.ID_AV_AAB = av.ID_AV
             WHERE sk.CODIGO_ART_SKU = v_codigo_articulo
               AND av.ID_VA_AV = v_id_atributo_pivot
             GROUP BY av.AV
        ) t;
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
                 JOIN fza_almacenes alm
                   ON stk.CODIGO_ALM_STK = alm.CODIGO_ALM_ALM
                 JOIN fza_articulos_skus sk
                   ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
                 JOIN fza_atributos_sku ask_p
                   ON sk.CODIGO_UNIDAD_SKU = ask_p.CODIGO_UNIDAD_SKU_SA
                 JOIN fza_atributos_valores av_p
                   ON ask_p.ID_AV_SA = av_p.ID_AV
                  AND av_p.ID_VA_AV = ''', v_id_atributo_pivot, '''
                 LEFT JOIN fza_atributos_sku ask_g
                   ON sk.CODIGO_UNIDAD_SKU = ask_g.CODIGO_UNIDAD_SKU_SA
                 LEFT JOIN fza_atributos_valores av_g
                   ON ask_g.ID_AV_SA = av_g.ID_AV
                  AND av_g.ID_VA_AV = ''',
                    IFNULL(v_id_atributo_grupo, 'xxx'), '''
                 WHERE sk.CODIGO_ART_SKU = ''', v_codigo_articulo, ''' ',
                 CASE WHEN v_valor_grupo_filtro IS NOT NULL THEN
                    CONCAT(' AND av_g.AV = ''',
                           REPLACE(v_valor_grupo_filtro, '''', ''''''), ''' ')
                 ELSE '' END, '
                 GROUP BY av_g.AV, alm.NOMBRE_ALM_ALM
                 ORDER BY alm.NOMBRE_ALM_ALM, av_g.AV'
            );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
    END IF;
    IF v_columnas_dinamicas IS NULL THEN
        SELECT stk.CODIGO_UNIDAD_STK AS Codigo,
               alm.NOMBRE_ALM_ALM AS Almacen,
               SUM(stk.CANTIDAD_STK) AS Stock_Total
          FROM fza_articulos_stockactual stk
          JOIN fza_almacenes alm
            ON stk.CODIGO_ALM_STK = alm.CODIGO_ALM_ALM
         WHERE stk.CODIGO_UNIDAD_STK = p_input
         GROUP BY stk.CODIGO_UNIDAD_STK, alm.NOMBRE_ALM_ALM
         ORDER BY alm.NOMBRE_ALM_ALM;
    END IF;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ`(IN p_input VARCHAR(50))
BEGIN
    DECLARE v_codigo_articulo VARCHAR(20);
    DECLARE v_es_sku BOOLEAN DEFAULT FALSE;
    DECLARE v_id_atributo_pivot VARCHAR(20);
    DECLARE v_nombre_atributo_pivot VARCHAR(50);
    DECLARE v_columnas_dinamicas TEXT;
    DECLARE v_id_atributo_fila VARCHAR(20) DEFAULT NULL;
    DECLARE v_nombre_atributo_fila VARCHAR(50) DEFAULT NULL;
    DECLARE v_select_fila TEXT DEFAULT '';
    DECLARE v_join_fila TEXT DEFAULT '';
    DECLARE v_groupby_fila TEXT DEFAULT '';
    DECLARE v_src_select_fila TEXT DEFAULT '';
    DECLARE v_filtros_fijos TEXT DEFAULT '';
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
    IF v_id_atributo_pivot IS NOT NULL THEN
        IF v_id_atributo_fila IS NOT NULL THEN
            SET v_select_fila = CONCAT(
                ', COALESCE(src.VALOR_FILA, ''-'') AS `',
                v_nombre_atributo_fila, '`');
            SET v_src_select_fila = ', av_fila.AV AS VALOR_FILA';
            SET v_join_fila = CONCAT(
                ' LEFT JOIN fza_atributos_sku ask_fila',
                ' ON sk.CODIGO_UNIDAD_SKU = ask_fila.CODIGO_UNIDAD_SKU_SA',
                ' LEFT JOIN fza_atributos_valores av_fila',
                ' ON ask_fila.ID_AV_SA = av_fila.ID_AV',
                ' AND av_fila.ID_VA_AV = ''', v_id_atributo_fila, ''' ');
            SET v_groupby_fila = ', src.VALOR_FILA';
        END IF;
        SELECT GROUP_CONCAT(
            CONCAT(
                'SUM(CASE WHEN src.AV = ''',
                REPLACE(t.AV, '''', ''''''),
                ''' THEN src.CANTIDAD_STK ELSE 0 END) AS `',
                REPLACE(t.AV, '`', '``'), '`'
            )
            ORDER BY t.ORDEN_TALLA, t.AV
        ) INTO v_columnas_dinamicas
        FROM (
            SELECT av.AV,
                   MIN(COALESCE(aab.ORDEN_AAB, av.ORDEN_AV))
                     AS ORDEN_TALLA
              FROM fza_articulos_skus sk
              JOIN fza_atributos_sku ask
                ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
              JOIN fza_atributos_valores av
                ON ask.ID_AV_SA = av.ID_AV
              LEFT JOIN fza_articulos_atributos_basicos aab
                ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU
               AND aab.ID_AV_AAB = av.ID_AV
             WHERE sk.CODIGO_ART_SKU = v_codigo_articulo
               AND av.ID_VA_AV = v_id_atributo_pivot
             GROUP BY av.AV
        ) t;
        IF v_es_sku = TRUE THEN
            SELECT GROUP_CONCAT(
                CONCAT(
                    ' AND EXISTS (SELECT 1 FROM fza_atributos_sku f_ask ',
                    ' JOIN fza_atributos_valores f_av',
                    ' ON f_ask.ID_AV_SA = f_av.ID_AV ',
                    ' WHERE f_ask.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ',
                    ' AND f_av.ID_VA_AV = ''', av.ID_VA_AV, ''' ',
                    ' AND f_av.AV = ''',
                    REPLACE(av.AV, '''', ''''''), ''') '
                ) SEPARATOR ' '
            ) INTO v_filtros_fijos
              FROM fza_atributos_sku ask
              JOIN fza_atributos_valores av
                ON ask.ID_AV_SA = av.ID_AV
             WHERE ask.CODIGO_UNIDAD_SKU_SA = p_input
               AND av.ID_VA_AV <> v_id_atributo_pivot;
        END IF;
        IF v_filtros_fijos IS NULL THEN
            SET v_filtros_fijos = '';
        END IF;
        IF v_columnas_dinamicas IS NOT NULL THEN
            SET @sql = CONCAT(
                'SELECT
                    alm.NOMBRE_ALM_ALM AS Almacen',
                    v_select_fila, ', ',
                    v_columnas_dinamicas, ',
                    COALESCE(SUM(src.CANTIDAD_STK), 0) AS Total
                 FROM fza_almacenes alm
                 LEFT JOIN (
                    SELECT stk.CODIGO_ALM_STK, av.AV, stk.CANTIDAD_STK',
                    v_src_select_fila, '
                    FROM fza_articulos_stockactual stk
                    JOIN fza_articulos_skus sk
                      ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU
                    JOIN fza_atributos_sku ask
                      ON sk.CODIGO_UNIDAD_SKU = ask.CODIGO_UNIDAD_SKU_SA
                    JOIN fza_atributos_valores av
                      ON ask.ID_AV_SA = av.ID_AV',
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
        END IF;
    END IF;
    IF v_id_atributo_pivot IS NULL OR v_columnas_dinamicas IS NULL THEN
        SELECT alm.NOMBRE_ALM_ALM AS Almacen,
               COALESCE(SUM(stk.CANTIDAD_STK), 0) AS `Stock Total`
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
