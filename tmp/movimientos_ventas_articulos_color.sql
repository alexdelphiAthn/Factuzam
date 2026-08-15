-- =====================================================================
-- Movimientos de ventas por artículos y fechas, con desglose opcional
-- por color.
--
-- PRC_GET_MOV_VENTAS_ART devuelve una fila por artículo. Si alguno de los
-- niveles de agrupación es COL, el grano pasa a artículo + color y todas
-- las tallas del mismo color quedan consolidadas. Si se agrupa además por
-- almacén, el grano añade el almacén.
--
-- El color se identifica por la clave lógica UPPER(TRIM(AV)). Dos ID_AV con
-- el mismo texto de color se consolidan, mientras que valores distintos no
-- se mezclan aunque pertenezcan al mismo atributo básico. El mapa de SKU a
-- color contiene exactamente una fila por SKU; así, añadir el desglose no
-- duplica unidades ni importes. Cuando COL no está seleccionado, todos los
-- SKU reciben ID_COLOR = 0 y se conserva el grano histórico por artículo.
--
-- Periodos:
--   - p_DESDE / p_HASTA: periodo de ventas, por fecha de factura.
--   - p_INICIO_COMPRAS: primera compra AC/AE del artículo. Este criterio
--     sigue siendo por artículo aunque el resultado se desglose por color.
--
-- Importes:
--   - Entradas: movimientos E de AC/AE; unidades y coste histórico.
--   - Ventas: líneas de factura/ticket, con descuento e IVA.
--   - Coste vendido: movimiento S de VE/FC; si falta, unidades vendidas
--     por PMP actual del artículo/color y, después, coste del proveedor.
--
-- Temporada:
--   - Con COL, propiedad de la unidad-color (prefijo artículo/color del SKU)
--     y, si no existe, propiedad del artículo. Los overrides de talla/SKU se
--     ignoran y el filtro se aplica al valor resultante de cada color.
--   - Sin COL, temporada definida directamente en el artículo.
--
-- Script idempotente: sustituye el procedimiento y no modifica el esquema.
-- Archivo de trabajo en UTF-8.
-- =====================================================================

DROP PROCEDURE IF EXISTS `PRC_GET_MOV_VENTAS_ART`;
DELIMITER ;;
CREATE PROCEDURE `PRC_GET_MOV_VENTAS_ART`(
    IN `p_DESDE`          DATE,
    IN `p_HASTA`          DATE,
    IN `p_INICIO_COMPRAS` DATE,
    IN `p_ALMACENES`      TEXT,
    IN `p_FAMILIAS`       TEXT,
    IN `p_PROVEEDORES`    TEXT,
    IN `p_TEMPORADAS`     TEXT,
    IN `p_ARTICULOS`      TEXT,
    IN `p_NIVEL1`         VARCHAR(3),   -- PRV/FAM/TMP/ALM/COL/''
    IN `p_NIVEL2`         VARCHAR(3),
    IN `p_NIVEL3`         VARCHAR(3),
    IN `p_NIVEL_FAM`      INT,
    IN `p_SOLO_VENTAS`    VARCHAR(1)
)
BEGIN
    DECLARE v_desde      DATE;
    DECLARE v_hasta      DATE;
    DECLARE v_ini_cmp    DATE;
    DECLARE v_por_alm    BOOLEAN DEFAULT FALSE;
    DECLARE v_por_col    BOOLEAN DEFAULT FALSE;
    DECLARE v_filtra_cmp BOOLEAN DEFAULT FALSE;
    DECLARE v_nivel_fam  INT;
    -- Normalización de parámetros.
    SET p_FAMILIAS    = IFNULL(p_FAMILIAS, '');
    SET p_PROVEEDORES = IFNULL(p_PROVEEDORES, '');
    SET p_TEMPORADAS  = IFNULL(p_TEMPORADAS, '');
    SET p_ARTICULOS   = IFNULL(p_ARTICULOS, '');
    SET p_SOLO_VENTAS = IFNULL(NULLIF(p_SOLO_VENTAS, ''), 'N');
    SET p_NIVEL1      = UPPER(IFNULL(p_NIVEL1, ''));
    SET p_NIVEL2      = UPPER(IFNULL(p_NIVEL2, ''));
    SET p_NIVEL3      = UPPER(IFNULL(p_NIVEL3, ''));
    SET v_por_alm     = (p_NIVEL1 = 'ALM' OR p_NIVEL2 = 'ALM'
                         OR p_NIVEL3 = 'ALM');
    SET v_por_col     = (p_NIVEL1 = 'COL' OR p_NIVEL2 = 'COL'
                         OR p_NIVEL3 = 'COL');
    SET v_nivel_fam   = IF(IFNULL(p_NIVEL_FAM, 0) < 1, 9999, p_NIVEL_FAM);
    SET v_desde       = IFNULL(p_DESDE, '1900-01-01');
    SET v_hasta       = IFNULL(p_HASTA, CURRENT_DATE);
    SET v_ini_cmp     = p_INICIO_COMPRAS;
    SET v_filtra_cmp  = (v_ini_cmp IS NOT NULL);
    -- Almacenes efectivos en una tabla temporal indexada.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_alm`;
    CREATE TEMPORARY TABLE `tmp_mva_alm` (
        `CODIGO_ALM` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_mva_alm` (`CODIGO_ALM`)
    SELECT `CODIGO_ALM_ALM`
      FROM `fza_almacenes`
     WHERE IF(IFNULL(p_ALMACENES, '') = '',
              `ESACTIVO_ALM` = 'S',
              FIND_IN_SET(`CODIGO_ALM_ALM`, p_ALMACENES));
    -- Familias elegidas, expandidas a toda su descendencia.
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
    SELECT DISTINCT `CODIGO_FAM_FAM`
      FROM `fam_tree`;
    -- Mapa de cada familia a su ancestro en el nivel solicitado.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam_grp`;
    CREATE TEMPORARY TABLE `tmp_mva_fam_grp` (
        `CODIGO_FAM` VARCHAR(20)  NOT NULL PRIMARY KEY,
        `COD_GRP`    VARCHAR(20)  NOT NULL,
        `DESC_GRP`   VARCHAR(200) NULL
    );
    INSERT IGNORE INTO `tmp_mva_fam_grp`
        (`CODIGO_FAM`, `COD_GRP`, `DESC_GRP`)
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
           SUBSTRING_INDEX(SUBSTRING_INDEX(pa.`RUTA`, '>', v_nivel_fam),
                           '>', -1),
           NULL
      FROM `fam_path` pa;
    UPDATE `tmp_mva_fam_grp` g
      JOIN `fza_articulos_familias` f
        ON f.`CODIGO_FAM_FAM` = g.`COD_GRP`
       SET g.`DESC_GRP` = COALESCE(f.`DESCRIPCION_FAM`,
                                   f.`NOMBRE_FAM_FAM`, g.`COD_GRP`);
    -- Universo previo de artículos. Con COL no se preselecciona por cualquier
    -- temporada de un SKU: primero se calcula una temporada única por color y
    -- el filtro se aplica al final. Sin COL se conserva sin cambios el criterio
    -- histórico del catálogo.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_arts0`;
    CREATE TEMPORARY TABLE `tmp_mva_arts0` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_mva_arts0` (`CODIGO_ART`)
    SELECT a.`CODIGO_ART_ART`
      FROM `fza_articulos` a
     WHERE a.`ESACTIVO_ART` = 'S'
       AND (p_ARTICULOS = ''
            OR FIND_IN_SET(a.`CODIGO_ART_ART`, p_ARTICULOS))
       AND (p_FAMILIAS = ''
            OR a.`CODIGO_FAM_ART` IN
               (SELECT `CODIGO_FAM` FROM `tmp_mva_fam`))
       AND (p_PROVEEDORES = ''
            OR EXISTS (
                SELECT 1
                  FROM `fza_articulos_proveedores` ap
                 WHERE ap.`CODIGO_ART_AP` = a.`CODIGO_ART_ART`
                   AND FIND_IN_SET(ap.`CODIGO_PRV_AP`, p_PROVEEDORES)
            ))
       AND (p_TEMPORADAS = ''
            OR v_por_col
            OR EXISTS (
                SELECT 1
                  FROM `fza_articulos_propiedades` ta
                  LEFT JOIN `fza_propiedades_valores` tav
                    ON tav.`ID_PV_ARTPROP` = ta.`ID_PV_ARTPROP`
                 WHERE ta.`CODIGO_ART_ART` = a.`CODIGO_ART_ART`
                   AND ta.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
                   AND FIND_IN_SET(
                       COALESCE(tav.`PV`, ta.`VALOR_LIBRE_ARTPROP`),
                       p_TEMPORADAS)
            ));
    -- SKU de los artículos candidatos. Esta tabla limita el ranking posterior
    -- a los artículos filtrados, en vez de recorrer todos los SKU del catálogo.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_skus`;
    CREATE TEMPORARY TABLE `tmp_mva_skus` (
        `CODIGO_UNIDAD` VARCHAR(50) NOT NULL PRIMARY KEY,
        `CODIGO_ART`    VARCHAR(20) NOT NULL,
        KEY `IDX_MVA_SKUS_ART` (`CODIGO_ART`)
    );
    INSERT INTO `tmp_mva_skus` (`CODIGO_UNIDAD`, `CODIGO_ART`)
    SELECT sku.`CODIGO_UNIDAD_SKU`, sku.`CODIGO_ART_SKU`
      FROM `fza_articulos_skus` sku
      JOIN `tmp_mva_arts0` a0
        ON a0.`CODIGO_ART` = sku.`CODIGO_ART_SKU`;
    -- Atributo de color elegido por SKU. El discriminante ID_VA = 'CO' está
    -- en el JOIN, de modo que una talla nunca puede confundirse con un color.
    -- ROW_NUMBER resuelve de forma determinista un SKU anómalo con más de un
    -- color y solo se calcula sobre los SKU candidatos.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_sku_color_elegido`;
    CREATE TEMPORARY TABLE `tmp_mva_sku_color_elegido` (
        `CODIGO_UNIDAD` VARCHAR(50)  NOT NULL PRIMARY KEY,
        `ID_AV`         INT          NOT NULL,
        `CLAVE_COLOR`   VARCHAR(100) NOT NULL,
        KEY `IDX_MVA_COLOR_ELEGIDO_CLAVE` (`CLAVE_COLOR`)
    );
    -- Catálogo lógico de los colores usados. ID_COLOR es solo un representante
    -- compatible con el resto de temporales; la identidad estable del color es
    -- CLAVE_COLOR y el orden es el mínimo global de todos sus ID_AV equivalentes.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_color_global`;
    CREATE TEMPORARY TABLE `tmp_mva_color_global` (
        `CLAVE_COLOR` VARCHAR(100) NOT NULL PRIMARY KEY,
        `ID_COLOR`    INT          NOT NULL,
        `COLOR`       VARCHAR(100) NOT NULL,
        `ORDEN_COLOR` INT          NOT NULL DEFAULT 0,
        UNIQUE KEY `UK_MVA_COLOR_GLOBAL_ID` (`ID_COLOR`)
    );
    IF v_por_col THEN
        INSERT INTO `tmp_mva_sku_color_elegido`
            (`CODIGO_UNIDAD`, `ID_AV`, `CLAVE_COLOR`)
        SELECT elegido.`CODIGO_UNIDAD`, elegido.`ID_AV`,
               elegido.`CLAVE_COLOR`
          FROM (
                SELECT sac.`CODIGO_UNIDAD_SKU_SA` AS `CODIGO_UNIDAD`,
                       co.`ID_AV`, UPPER(TRIM(co.`AV`)) AS `CLAVE_COLOR`,
                       ROW_NUMBER() OVER (
                           PARTITION BY sac.`CODIGO_UNIDAD_SKU_SA`
                           ORDER BY COALESCE(co.`ORDEN_AV`, 0), co.`ID_AV`
                       ) AS `POSICION`
                  FROM `fza_atributos_sku` sac
                  JOIN `tmp_mva_skus` sku
                    ON sku.`CODIGO_UNIDAD` = sac.`CODIGO_UNIDAD_SKU_SA`
                  JOIN `fza_atributos_valores` co
                    ON co.`ID_AV` = sac.`ID_AV_SA`
                   AND co.`ID_VA_AV` = 'CO'
                 WHERE NULLIF(TRIM(co.`AV`), '') IS NOT NULL
               ) elegido
         WHERE elegido.`POSICION` = 1;
        INSERT INTO `tmp_mva_color_global`
            (`CLAVE_COLOR`, `ID_COLOR`, `COLOR`, `ORDEN_COLOR`)
        SELECT UPPER(TRIM(co.`AV`)), MIN(co.`ID_AV`), MIN(TRIM(co.`AV`)),
               MIN(COALESCE(co.`ORDEN_AV`, 0))
          FROM `fza_atributos_valores` co
          JOIN (
                SELECT DISTINCT e.`CLAVE_COLOR`
                  FROM `tmp_mva_sku_color_elegido` e
               ) usados
            ON usados.`CLAVE_COLOR` = UPPER(TRIM(co.`AV`))
         WHERE co.`ID_VA_AV` = 'CO'
           AND NULLIF(TRIM(co.`AV`), '') IS NOT NULL
         GROUP BY UPPER(TRIM(co.`AV`));
    END IF;
    -- Mapa único SKU -> artículo/color lógico. Dos ID_AV cuyo AV normalizado
    -- coincide reciben el mismo ID_COLOR representante y se consolidan. Dos
    -- AV distintos siguen separados aunque compartan cualquier ID_ATB.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_sku_color`;
    CREATE TEMPORARY TABLE `tmp_mva_sku_color` (
        `CODIGO_UNIDAD` VARCHAR(50)  NOT NULL PRIMARY KEY,
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `ID_COLOR`      INT          NOT NULL DEFAULT 0,
        `CLAVE_COLOR`   VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR`         VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR_ETIQUETA` VARCHAR(255) NOT NULL DEFAULT '',
        `ORDEN_COLOR`   INT          NOT NULL DEFAULT 0,
        KEY `IDX_MVA_SKU_COLOR_ART` (`CODIGO_ART`, `ID_COLOR`),
        KEY `IDX_MVA_SKU_COLOR_CLAVE` (`CODIGO_ART`, `CLAVE_COLOR`)
    );
    INSERT INTO `tmp_mva_sku_color`
        (`CODIGO_UNIDAD`, `CODIGO_ART`, `ID_COLOR`, `CLAVE_COLOR`,
         `COLOR`, `COLOR_ETIQUETA`, `ORDEN_COLOR`)
    SELECT sku.`CODIGO_UNIDAD`, sku.`CODIGO_ART`,
           IF(v_por_col, COALESCE(cg.`ID_COLOR`, 0), 0),
           IF(v_por_col, COALESCE(cg.`CLAVE_COLOR`, ''), ''),
           IF(v_por_col, COALESCE(cg.`COLOR`, ''), ''),
           IF(v_por_col,
              COALESCE(NULLIF(aab.`DESCRIPCION_AAB`, ''),
                       NULLIF(col_raw.`DESCRIPCION_AV`, ''), cg.`COLOR`, ''),
              ''),
           IF(v_por_col, COALESCE(cg.`ORDEN_COLOR`, 0), 0)
      FROM `tmp_mva_skus` sku
      LEFT JOIN `tmp_mva_sku_color_elegido` elegido
        ON elegido.`CODIGO_UNIDAD` = sku.`CODIGO_UNIDAD`
      LEFT JOIN `tmp_mva_color_global` cg
        ON cg.`CLAVE_COLOR` = elegido.`CLAVE_COLOR`
      LEFT JOIN `fza_atributos_valores` col_raw
        ON col_raw.`ID_AV` = elegido.`ID_AV`
      LEFT JOIN `fza_articulos_atributos_basicos` aab
        ON aab.`CODIGO_ART_AAB` = sku.`CODIGO_ART`
       AND aab.`ID_AV_AAB` = elegido.`ID_AV`;
    -- Metadatos únicos del color para el resultado y las agrupaciones.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_color`;
    CREATE TEMPORARY TABLE `tmp_mva_color` (
        `CODIGO_ART`    VARCHAR(20)  NOT NULL,
        `ID_COLOR`      INT          NOT NULL DEFAULT 0,
        `CLAVE_COLOR`   VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR`         VARCHAR(100) NOT NULL DEFAULT '',
        `COLOR_ETIQUETA` VARCHAR(255) NOT NULL DEFAULT '',
        `ORDEN_COLOR`   INT          NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`)
    );
    INSERT INTO `tmp_mva_color`
        (`CODIGO_ART`, `ID_COLOR`, `CLAVE_COLOR`, `COLOR`,
         `COLOR_ETIQUETA`, `ORDEN_COLOR`)
    SELECT s.`CODIGO_ART`, s.`ID_COLOR`, MIN(s.`CLAVE_COLOR`), MIN(s.`COLOR`),
           IF(v_por_col,
              COALESCE(NULLIF(MIN(s.`COLOR_ETIQUETA`), ''), '(sin color)'), ''),
           MIN(s.`ORDEN_COLOR`)
      FROM `tmp_mva_sku_color` s
     GROUP BY s.`CODIGO_ART`, s.`ID_COLOR`;
    -- Temporada al mismo grano artículo/color. Con COL se consulta únicamente
    -- la propiedad de la unidad-color (prefijo artículo/color), con fallback
    -- a la propiedad del artículo. No se usa la vista efectiva porque filtra
    -- SKU inactivos y antepone indebidamente el override de talla/SKU.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_temporada`;
    CREATE TEMPORARY TABLE `tmp_mva_temporada` (
        `CODIGO_ART` VARCHAR(20)  NOT NULL,
        `ID_COLOR`   INT          NOT NULL DEFAULT 0,
        `TEMPORADA`  VARCHAR(255) NOT NULL DEFAULT '',
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`)
    );
    IF v_por_col THEN
        INSERT INTO `tmp_mva_temporada`
            (`CODIGO_ART`, `ID_COLOR`, `TEMPORADA`)
        SELECT unidad.`CODIGO_ART`, unidad.`ID_COLOR`,
               COALESCE(
                   MAX(NULLIF(COALESCE(tpcv.`PV`,
                                       tpc.`VALOR_LIBRE_ARTPROP`), '')),
                   MAX(NULLIF(COALESCE(tpav.`PV`,
                                       tpa.`VALOR_LIBRE_ARTPROP`), '')),
                   '')
          FROM (
                SELECT DISTINCT s.`CODIGO_ART`, s.`ID_COLOR`,
                       CASE
                           WHEN s.`CLAVE_COLOR` <> '' THEN
                               SUBSTRING_INDEX(s.`CODIGO_UNIDAD`, '/', 2)
                           ELSE NULL
                       END AS `CODIGO_UNIDAD_COLOR`
                  FROM `tmp_mva_sku_color` s
               ) unidad
          LEFT JOIN `fza_articulos_propiedades` tpc
            ON tpc.`CODIGO_ART_ART` = unidad.`CODIGO_ART`
           AND tpc.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
           AND tpc.`CODIGO_UNIDAD_ARTPROP` = unidad.`CODIGO_UNIDAD_COLOR`
          LEFT JOIN `fza_propiedades_valores` tpcv
            ON tpcv.`ID_PV_ARTPROP` = tpc.`ID_PV_ARTPROP`
          LEFT JOIN `fza_articulos_propiedades` tpa
            ON tpa.`CODIGO_ART_ART` = unidad.`CODIGO_ART`
           AND tpa.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
           AND tpa.`CODIGO_UNIDAD_ARTPROP` = ''
          LEFT JOIN `fza_propiedades_valores` tpav
            ON tpav.`ID_PV_ARTPROP` = tpa.`ID_PV_ARTPROP`
         GROUP BY unidad.`CODIGO_ART`, unidad.`ID_COLOR`;
    ELSE
        INSERT INTO `tmp_mva_temporada`
            (`CODIGO_ART`, `ID_COLOR`, `TEMPORADA`)
        SELECT tp.`CODIGO_ART_ART`, 0,
               MAX(COALESCE(tpv.`PV`, tp.`VALOR_LIBRE_ARTPROP`, ''))
          FROM `fza_articulos_propiedades` tp
          LEFT JOIN `fza_propiedades_valores` tpv
            ON tpv.`ID_PV_ARTPROP` = tp.`ID_PV_ARTPROP`
         WHERE tp.`CODIGO_PROP_ARTPROP` = 'TEMPORADA'
           AND tp.`CODIGO_UNIDAD_ARTPROP` = ''
           AND tp.`CODIGO_ART_ART` IN
               (SELECT `CODIGO_ART` FROM `tmp_mva_arts0`)
         GROUP BY tp.`CODIGO_ART_ART`;
    END IF;
    -- Entradas reales de género, agrupadas por artículo/color y, si se ha
    -- solicitado, almacén. El JOIN al mapa es uno a uno por SKU.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ent`;
    CREATE TEMPORARY TABLE `tmp_mva_ent` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `ID_COLOR`   INT           NOT NULL DEFAULT 0,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `UNI_ENT`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        `IMP_ENT`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`)
    );
    INSERT INTO `tmp_mva_ent`
        (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`, `UNI_ENT`, `IMP_ENT`)
    SELECT sc.`CODIGO_ART`, sc.`ID_COLOR`,
           IF(v_por_alm, m.`CODIGO_ALM_MOV`, ''),
           SUM(m.`CANTIDAD_MOV`), SUM(m.`TOTAL_COSTE_MOV`)
      FROM `fza_movimientos_almacen` m
      JOIN `tmp_mva_sku_color` sc
        ON sc.`CODIGO_UNIDAD` = m.`CODIGO_UNIDAD_MOV`
     WHERE m.`ESACTIVO_MOV` = 'S'
       AND m.`TIPO_MOV` = 'E'
       AND m.`TIPO_DOC_MOV` IN ('AC', 'AE')
       AND m.`CODIGO_ALM_MOV` IN
           (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sc.`CODIGO_ART`, sc.`ID_COLOR`,
              IF(v_por_alm, m.`CODIGO_ALM_MOV`, '');
    -- Primera compra global a los almacenes filtrados. Deliberadamente no
    -- incluye ID_COLOR: Inicio compras continúa siendo un filtro por artículo.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_primera`;
    CREATE TEMPORARY TABLE `tmp_mva_primera` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY,
        `PRIMERA`    DATE        NULL
    );
    INSERT INTO `tmp_mva_primera` (`CODIGO_ART`, `PRIMERA`)
    SELECT sc.`CODIGO_ART`, MIN(DATE(m.`FECHA_MOV`))
      FROM `fza_movimientos_almacen` m
      JOIN `tmp_mva_sku_color` sc
        ON sc.`CODIGO_UNIDAD` = m.`CODIGO_UNIDAD_MOV`
     WHERE m.`ESACTIVO_MOV` = 'S'
       AND m.`TIPO_MOV` = 'E'
       AND m.`TIPO_DOC_MOV` IN ('AC', 'AE')
       AND m.`CODIGO_ALM_MOV` IN
           (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sc.`CODIGO_ART`;
    -- Ventas del periodo por artículo/color y almacén opcional.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ven`;
    CREATE TEMPORARY TABLE `tmp_mva_ven` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `ID_COLOR`   INT           NOT NULL DEFAULT 0,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `UDS_VEN`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        `IMP_VEN`    DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`)
    );
    INSERT INTO `tmp_mva_ven`
        (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`, `UDS_VEN`, `IMP_VEN`)
    SELECT sc.`CODIGO_ART`, sc.`ID_COLOR`,
           IF(v_por_alm,
              COALESCE(fl.`CODIGO_ALM_FACLIN`, f.`CODIGO_ALM_FAC`), ''),
           SUM(fl.`CANTIDAD_FACLIN`), SUM(fl.`TOTAL_FACLIN`)
      FROM `fza_facturas_lineas` fl
      JOIN `fza_facturas` f
        ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`
       AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`
      JOIN `tmp_mva_sku_color` sc
        ON sc.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN`
     WHERE COALESCE(fl.`CODIGO_ALM_FACLIN`, f.`CODIGO_ALM_FAC`)
           IN (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
       AND DATE(f.`FECHA_FAC`) BETWEEN v_desde AND v_hasta
       AND COALESCE(f.`FASE_FAC`, '') NOT IN (
           'SIN_VERIF_ANULADA',
           'VERIFACTU_ANULADA',
           'NOVERIFACTU_ANULADA'
       )
       AND NOT EXISTS (
           SELECT 1
             FROM `fza_verifactu_cola` va
            WHERE va.`SERIE_FAC_VFCOLA` = f.`SERIE_FAC`
              AND va.`NUMERO_FAC_VFCOLA` = f.`NUMERO_FAC`
              AND va.`TIPO_OPERACION_VFCOLA` = 'ANULACION'
       )
       -- Una sustitutiva S reemplaza íntegramente a la simplificada original.
       AND NOT EXISTS (
           SELECT 1
             FROM `fza_facturas` fo
             JOIN `fza_facturas_relaciones` fr
               ON fr.`SERIE_FAC_ORIGEN_FACREL` = fo.`SERIE_FAC`
              AND fr.`NUMERO_FAC_ORIGEN_FACREL` = fo.`NUMERO_FAC`
             JOIN `fza_facturas` fs
               ON fs.`CODIGO_EMP_FAC` = fo.`CODIGO_EMP_FAC`
              AND fs.`SERIE_FAC` = fr.`SERIE_FAC_FACREL`
              AND fs.`NUMERO_FAC` = fr.`NUMERO_FAC_FACREL`
            WHERE fo.`CODIGO_EMP_FAC` = f.`CODIGO_EMP_FAC`
              AND fo.`SERIE_FAC` = f.`SERIE_FAC`
              AND fo.`NUMERO_FAC` = f.`NUMERO_FAC`
              AND fo.`TIPO_FAC` = 'SIMPLIFICADA'
              AND fo.`FASE_FAC` = 'RECTIFICADA'
              AND fr.`TIPO_RELACION_FACREL` = 'RECTIFICA'
              AND fs.`TIPO_RECTIFICATIVA_FAC` = 'S'
       )
     GROUP BY sc.`CODIGO_ART`, sc.`ID_COLOR`,
              IF(v_por_alm,
                 COALESCE(fl.`CODIGO_ALM_FACLIN`, f.`CODIGO_ALM_FAC`), '');
    -- Coste histórico de las ventas, al mismo grano que las ventas.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_coste_ven`;
    CREATE TEMPORARY TABLE `tmp_mva_coste_ven` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `ID_COLOR`   INT           NOT NULL DEFAULT 0,
        `CODIGO_ALM` VARCHAR(20)   NOT NULL DEFAULT '',
        `COSTE_VEN`  DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`)
    );
    INSERT INTO `tmp_mva_coste_ven`
        (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`, `COSTE_VEN`)
    SELECT sc.`CODIGO_ART`, sc.`ID_COLOR`,
           IF(v_por_alm, m.`CODIGO_ALM_MOV`, ''),
           SUM(m.`TOTAL_COSTE_MOV`)
      FROM `fza_movimientos_almacen` m
      JOIN `fza_facturas` f
        ON f.`SERIE_FAC` = m.`SERIE_DOC_MOV`
       AND f.`NUMERO_FAC` = m.`NUMERO_DOC_MOV`
      JOIN `tmp_mva_sku_color` sc
        ON sc.`CODIGO_UNIDAD` = m.`CODIGO_UNIDAD_MOV`
     WHERE m.`ESACTIVO_MOV` = 'S'
       AND m.`TIPO_MOV` = 'S'
       AND m.`TIPO_DOC_MOV` IN ('VE', 'FC')
       AND DATE(f.`FECHA_FAC`) BETWEEN v_desde AND v_hasta
       AND COALESCE(f.`FASE_FAC`, '') NOT IN (
           'SIN_VERIF_ANULADA',
           'VERIFACTU_ANULADA',
           'NOVERIFACTU_ANULADA'
       )
       AND NOT EXISTS (
           SELECT 1
             FROM `fza_verifactu_cola` va
            WHERE va.`SERIE_FAC_VFCOLA` = f.`SERIE_FAC`
              AND va.`NUMERO_FAC_VFCOLA` = f.`NUMERO_FAC`
              AND va.`TIPO_OPERACION_VFCOLA` = 'ANULACION'
       )
       AND NOT EXISTS (
           SELECT 1
             FROM `fza_facturas` fo
             JOIN `fza_facturas_relaciones` fr
               ON fr.`SERIE_FAC_ORIGEN_FACREL` = fo.`SERIE_FAC`
              AND fr.`NUMERO_FAC_ORIGEN_FACREL` = fo.`NUMERO_FAC`
             JOIN `fza_facturas` fs
               ON fs.`CODIGO_EMP_FAC` = fo.`CODIGO_EMP_FAC`
              AND fs.`SERIE_FAC` = fr.`SERIE_FAC_FACREL`
              AND fs.`NUMERO_FAC` = fr.`NUMERO_FAC_FACREL`
            WHERE fo.`CODIGO_EMP_FAC` = f.`CODIGO_EMP_FAC`
              AND fo.`SERIE_FAC` = f.`SERIE_FAC`
              AND fo.`NUMERO_FAC` = f.`NUMERO_FAC`
              AND fo.`TIPO_FAC` = 'SIMPLIFICADA'
              AND fo.`FASE_FAC` = 'RECTIFICADA'
              AND fr.`TIPO_RELACION_FACREL` = 'RECTIFICA'
              AND fs.`TIPO_RECTIFICATIVA_FAC` = 'S'
       )
       AND m.`CODIGO_ALM_MOV` IN
           (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sc.`CODIGO_ART`, sc.`ID_COLOR`,
              IF(v_por_alm, m.`CODIGO_ALM_MOV`, '');
    -- Universo final de artículos tras aplicar Inicio compras por artículo.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_arts`;
    CREATE TEMPORARY TABLE `tmp_mva_arts` (
        `CODIGO_ART` VARCHAR(20) NOT NULL PRIMARY KEY
    );
    INSERT IGNORE INTO `tmp_mva_arts` (`CODIGO_ART`)
    SELECT a0.`CODIGO_ART`
      FROM `tmp_mva_arts0` a0
     WHERE NOT v_filtra_cmp
        OR EXISTS (
            SELECT 1
              FROM `tmp_mva_primera` pc
             WHERE pc.`CODIGO_ART` = a0.`CODIGO_ART`
               AND pc.`PRIMERA` >= v_ini_cmp
        );
    -- PMP actual por artículo/color. Sin COL, ID_COLOR vale cero y el cálculo
    -- coincide con el PMP histórico por artículo.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_coste`;
    CREATE TEMPORARY TABLE `tmp_mva_coste` (
        `CODIGO_ART` VARCHAR(20)   NOT NULL,
        `ID_COLOR`   INT           NOT NULL DEFAULT 0,
        `COSTE`      DECIMAL(19,6) NOT NULL DEFAULT 0,
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`)
    );
    INSERT INTO `tmp_mva_coste` (`CODIGO_ART`, `ID_COLOR`, `COSTE`)
    SELECT sc.`CODIGO_ART`, sc.`ID_COLOR`,
           IF(SUM(st.`CANTIDAD_STK`) <> 0,
              SUM(st.`VALOR_TOTAL_STK`) / SUM(st.`CANTIDAD_STK`), 0)
      FROM `fza_articulos_stockactual` st
      JOIN `tmp_mva_sku_color` sc
        ON sc.`CODIGO_UNIDAD` = st.`CODIGO_UNIDAD_STK`
     WHERE st.`CODIGO_ALM_STK` IN
           (SELECT `CODIGO_ALM` FROM `tmp_mva_alm`)
     GROUP BY sc.`CODIGO_ART`, sc.`ID_COLOR`;
    -- Base final: unión sin duplicados de los granos presentes en compras o
    -- ventas. ID_COLOR participa en la PK y en ambas inserciones.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_base`;
    CREATE TEMPORARY TABLE `tmp_mva_base` (
        `CODIGO_ART` VARCHAR(20) NOT NULL,
        `ID_COLOR`   INT         NOT NULL DEFAULT 0,
        `CODIGO_ALM` VARCHAR(20) NOT NULL DEFAULT '',
        PRIMARY KEY (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`)
    );
    INSERT IGNORE INTO `tmp_mva_base`
        (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`)
    SELECT e.`CODIGO_ART`, e.`ID_COLOR`, e.`CODIGO_ALM`
      FROM `tmp_mva_ent` e
     WHERE e.`CODIGO_ART` IN
           (SELECT `CODIGO_ART` FROM `tmp_mva_arts`);
    INSERT IGNORE INTO `tmp_mva_base`
        (`CODIGO_ART`, `ID_COLOR`, `CODIGO_ALM`)
    SELECT v.`CODIGO_ART`, v.`ID_COLOR`, v.`CODIGO_ALM`
      FROM `tmp_mva_ven` v
     WHERE v.`CODIGO_ART` IN
           (SELECT `CODIGO_ART` FROM `tmp_mva_arts`);
    -- Resultado final. Las magnitudes siguen siendo sumables; los porcentajes
    -- se recalculan en los totales del cliente.
    SELECT
        COALESCE(fam.`ORDEN_FAM`, 999999)             AS `ORDEN_FAM`,
        art.`CODIGO_FAM_ART`                          AS `CODIGO_FAM`,
        COALESCE(fam.`DESCRIPCION_FAM`,
                 fam.`NOMBRE_FAM_FAM`, art.`CODIGO_FAM_ART`)
                                                       AS `DESCRIPCION_FAM`,
        b.`CODIGO_ART`                                AS `CODIGO_ART_ART`,
        art.`DESCRIPCION_ART`                         AS `DESCRIPCION_ART`,
        prov.`REF_PROVEEDOR_AP`                       AS `REF_PRV`,
        ROUND(COALESCE(NULLIF(cst.`COSTE`, 0),
                       prov.`COSTE_PRV`, 0), 2)        AS `COSTE_ART`,
        ROUND(COALESCE(pvp.`PVP`, 0), 2)              AS `PVP_ART`,
        b.`CODIGO_ALM`                                AS `CODIGO_ALM`,
        COALESCE(alm.`NOMBRE_ALM_ALM`, '')            AS `NOMBRE_ALM`,
        ROUND(COALESCE(e.`UNI_ENT`, 0), 2)            AS `UNI_ENT_TOT`,
        ROUND(COALESCE(e.`IMP_ENT`, 0), 2)            AS `IMP_ENT_TOT`,
        ROUND(COALESCE(v.`UDS_VEN`, 0), 2)            AS `UDS_VENTA`,
        ROUND(COALESCE(v.`IMP_VEN`, 0), 2)            AS `IMP_VENTA`,
        ROUND(COALESCE(cv.`COSTE_VEN`,
              COALESCE(v.`UDS_VEN`, 0)
              * COALESCE(NULLIF(cst.`COSTE`, 0),
                         prov.`COSTE_PRV`, 0)), 2)     AS `IMP_COSTE`,
        ROUND(COALESCE(v.`IMP_VEN`, 0)
              - COALESCE(cv.`COSTE_VEN`,
                COALESCE(v.`UDS_VEN`, 0)
                * COALESCE(NULLIF(cst.`COSTE`, 0),
                           prov.`COSTE_PRV`, 0)), 2)   AS `BENEFICIO`,
        ROUND(COALESCE(v.`IMP_VEN`, 0)
              - COALESCE(e.`IMP_ENT`, 0), 2)          AS `VENTA_ENT`,
        ROUND(IF(COALESCE(cv.`COSTE_VEN`,
                 COALESCE(v.`UDS_VEN`, 0)
                 * COALESCE(NULLIF(cst.`COSTE`, 0),
                            prov.`COSTE_PRV`, 0)) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0)
                  - COALESCE(cv.`COSTE_VEN`,
                    COALESCE(v.`UDS_VEN`, 0)
                    * COALESCE(NULLIF(cst.`COSTE`, 0),
                               prov.`COSTE_PRV`, 0)))
                 / COALESCE(cv.`COSTE_VEN`,
                    COALESCE(v.`UDS_VEN`, 0)
                    * COALESCE(NULLIF(cst.`COSTE`, 0),
                               prov.`COSTE_PRV`, 0))
                 * 100, 0), 2)                        AS `PCT_BNFCO`,
        ROUND(IF(COALESCE(e.`IMP_ENT`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0) - COALESCE(e.`IMP_ENT`, 0))
                 / COALESCE(e.`IMP_ENT`, 0) * 100, 0), 2)
                                                       AS `VENT_ENT`,
        ROUND(IF(COALESCE(v.`IMP_VEN`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0)
                  - COALESCE(cv.`COSTE_VEN`,
                    COALESCE(v.`UDS_VEN`, 0)
                    * COALESCE(NULLIF(cst.`COSTE`, 0),
                               prov.`COSTE_PRV`, 0)))
                 / COALESCE(v.`IMP_VEN`, 0) * 100, 0), 2)
                                                       AS `MARGEN1`,
        ROUND(IF(COALESCE(v.`IMP_VEN`, 0) <> 0,
                 (COALESCE(v.`IMP_VEN`, 0) - COALESCE(e.`IMP_ENT`, 0))
                 / COALESCE(v.`IMP_VEN`, 0) * 100, 0), 2)
                                                       AS `MARGEN2`,
        ROUND(IF(COALESCE(e.`UNI_ENT`, 0) <> 0,
                 COALESCE(v.`UDS_VEN`, 0) / COALESCE(e.`UNI_ENT`, 0)
                 * 100, 0), 2)                        AS `PCT_VDTO`,
        ROUND(IF(COALESCE(e.`IMP_ENT`, 0) <> 0,
                 COALESCE(v.`IMP_VEN`, 0) / COALESCE(e.`IMP_ENT`, 0)
                 * 100, 0), 2)                        AS `PCT_VLAST`,
        -- Niveles de agrupación. La clave COL antepone el orden mínimo global
        -- a UPPER(TRIM(AV)), que es la identidad lógica y estable del color.
        -- No usa ID_AV ni ID_ATB. El detalle conserva COLOR_ETIQUETA, que sí
        -- puede personalizarse por artículo.
        CASE p_NIVEL1
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN b.`CODIGO_ALM`
            WHEN 'COL' THEN CONCAT(
                 LPAD(COALESCE(col.`ORDEN_COLOR`, 0), 10, '0'), ':',
                 COALESCE(col.`CLAVE_COLOR`, ''))
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
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), b.`CODIGO_ALM`,
                          '(sin almacén)'))
            WHEN 'COL' THEN CONCAT('Color: ',
                 COALESCE(NULLIF(col.`COLOR`, ''), '(sin color)'))
            ELSE ''
        END                                           AS `GRUPO1_ETIQ`,
        CASE p_NIVEL2
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN b.`CODIGO_ALM`
            WHEN 'COL' THEN CONCAT(
                 LPAD(COALESCE(col.`ORDEN_COLOR`, 0), 10, '0'), ':',
                 COALESCE(col.`CLAVE_COLOR`, ''))
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
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), b.`CODIGO_ALM`,
                          '(sin almacén)'))
            WHEN 'COL' THEN CONCAT('Color: ',
                 COALESCE(NULLIF(col.`COLOR`, ''), '(sin color)'))
            ELSE ''
        END                                           AS `GRUPO2_ETIQ`,
        CASE p_NIVEL3
            WHEN 'PRV' THEN COALESCE(prov.`CODIGO_PRV`, '')
            WHEN 'FAM' THEN COALESCE(fg.`COD_GRP`, art.`CODIGO_FAM_ART`)
            WHEN 'TMP' THEN COALESCE(tmp.`TEMPORADA`, '')
            WHEN 'ALM' THEN b.`CODIGO_ALM`
            WHEN 'COL' THEN CONCAT(
                 LPAD(COALESCE(col.`ORDEN_COLOR`, 0), 10, '0'), ':',
                 COALESCE(col.`CLAVE_COLOR`, ''))
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
                 COALESCE(NULLIF(alm.`NOMBRE_ALM_ALM`, ''), b.`CODIGO_ALM`,
                          '(sin almacén)'))
            WHEN 'COL' THEN CONCAT('Color: ',
                 COALESCE(NULLIF(col.`COLOR`, ''), '(sin color)'))
            ELSE ''
        END                                           AS `GRUPO3_ETIQ`,
        -- Los campos nuevos se añaden al final para conservar los ordinales
        -- históricos de todos los campos anteriores del procedimiento.
        b.`ID_COLOR`                                  AS `ID_COLOR`,
        COALESCE(col.`COLOR`, '')                     AS `COLOR`,
        COALESCE(col.`COLOR_ETIQUETA`, '')            AS `COLOR_ETIQUETA`,
        COALESCE(col.`ORDEN_COLOR`, 0)                AS `ORDEN_COLOR`
      FROM `tmp_mva_base` b
      JOIN `fza_articulos` art
        ON art.`CODIGO_ART_ART` = b.`CODIGO_ART`
      LEFT JOIN `tmp_mva_ent` e
        ON e.`CODIGO_ART` = b.`CODIGO_ART`
       AND e.`ID_COLOR` = b.`ID_COLOR`
       AND e.`CODIGO_ALM` = b.`CODIGO_ALM`
      LEFT JOIN `tmp_mva_ven` v
        ON v.`CODIGO_ART` = b.`CODIGO_ART`
       AND v.`ID_COLOR` = b.`ID_COLOR`
       AND v.`CODIGO_ALM` = b.`CODIGO_ALM`
      LEFT JOIN `tmp_mva_coste_ven` cv
        ON cv.`CODIGO_ART` = b.`CODIGO_ART`
       AND cv.`ID_COLOR` = b.`ID_COLOR`
       AND cv.`CODIGO_ALM` = b.`CODIGO_ALM`
      LEFT JOIN `tmp_mva_coste` cst
        ON cst.`CODIGO_ART` = b.`CODIGO_ART`
       AND cst.`ID_COLOR` = b.`ID_COLOR`
      LEFT JOIN `tmp_mva_color` col
        ON col.`CODIGO_ART` = b.`CODIGO_ART`
       AND col.`ID_COLOR` = b.`ID_COLOR`
      LEFT JOIN `tmp_mva_temporada` tmp
        ON tmp.`CODIGO_ART` = b.`CODIGO_ART`
       AND tmp.`ID_COLOR` = b.`ID_COLOR`
      LEFT JOIN `fza_articulos_familias` fam
        ON fam.`CODIGO_FAM_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `tmp_mva_fam_grp` fg
        ON fg.`CODIGO_FAM` = art.`CODIGO_FAM_ART`
      LEFT JOIN `fza_almacenes` alm
        ON alm.`CODIGO_ALM_ALM` = b.`CODIGO_ALM`
      LEFT JOIN (
            SELECT t.`CODIGO_ART_ARTTAR` AS `CODIGO_ART`,
                   MAX(t.`PRECIO_FINAL_ARTTAR`) AS `PVP`
              FROM `fza_articulos_tarifas` t
             WHERE IFNULL(t.`CODIGO_UNIDAD_ARTTAR`, '') = ''
               AND t.`CODIGO_ART_ARTTAR` IN
                   (SELECT `CODIGO_ART` FROM `tmp_mva_arts0`)
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
               AND ap.`CODIGO_ART_AP` IN
                   (SELECT `CODIGO_ART` FROM `tmp_mva_arts0`)
             GROUP BY ap.`CODIGO_ART_AP`
           ) prov ON prov.`CODIGO_ART` = b.`CODIGO_ART`
     WHERE (p_SOLO_VENTAS <> 'S' OR COALESCE(v.`UDS_VEN`, 0) <> 0)
       -- Sin COL se conserva exactamente el filtro histórico de temporada.
       -- Con COL, el filtro se aplica al único valor calculado para cada color,
       -- sin considerar temporadas de otros colores ni overrides de talla/SKU.
       AND (p_TEMPORADAS = '' OR NOT v_por_col
            OR FIND_IN_SET(COALESCE(tmp.`TEMPORADA`, ''), p_TEMPORADAS))
     ORDER BY `GRUPO1_COD`, `GRUPO2_COD`, `GRUPO3_COD`,
              COALESCE(fam.`ORDEN_FAM`, 999999), art.`CODIGO_FAM_ART`,
              b.`CODIGO_ART`, COALESCE(col.`ORDEN_COLOR`, 0),
              COALESCE(col.`CLAVE_COLOR`, ''), b.`CODIGO_ALM`;
    -- Limpieza completa de temporales para no contaminar la sesión.
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_base`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_coste`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_arts`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_coste_ven`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ven`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_primera`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_ent`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_temporada`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_color`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_sku_color`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_color_global`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_sku_color_elegido`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_skus`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_arts0`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam_grp`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_fam`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_mva_alm`;
END ;;
DELIMITER ;

-- Parámetros:
-- (p_DESDE, p_HASTA, p_INICIO_COMPRAS, p_ALMACENES, p_FAMILIAS,
--  p_PROVEEDORES, p_TEMPORADAS, p_ARTICULOS, p_NIVEL1, p_NIVEL2,
--  p_NIVEL3, p_NIVEL_FAM, p_SOLO_VENTAS).
--
-- Niveles: PRV, FAM, TMP, ALM, COL o ''. COL activa el grano por color.
-- Ejemplo: ventas de 2026, artículo desglosado por color y familia raíz.
-- CALL PRC_GET_MOV_VENTAS_ART(
--     '2026-01-01', '2026-12-31', NULL, '', '', '', '', '',
--     'FAM', 'COL', '', 1, 'N');
