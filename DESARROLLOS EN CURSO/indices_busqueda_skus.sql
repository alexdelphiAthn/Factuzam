-- =============================================================================
-- Indices de apoyo para la busqueda de SKU (traspasos y buscadores)
-- =============================================================================
-- El desplegable de SKU del grid de traspasos (inLibGridArticulos.pas)
-- resuelve por cada SKU sus codigos de barras, referencias de proveedor
-- y stock con subconsultas correladas. Sin indices de apoyo cada
-- subconsulta es un full-scan por fila: entrar en traspasos tardaba ~9 s
-- con catalogo real (LOG de FAUSTINO 10/06/2026).
--
-- factuzam_original.sql ya incluye estos indices; este script alinea las
-- instalaciones existentes que se crearon antes:
--
--   - fza_codigos_barras: solo tenia PK (ID_CB). IDX_UNIDAD_CB atiende el
--     lookup por SKU del desplegable; IDX_BARRAS_CB la resolucion de
--     pistola por codigo de barras (validador).
--   - fza_articulos_proveedores / fza_articulos_stockactual /
--     fza_articulos_skus: mismos indices que indices_rendimiento.sql; se
--     repiten aqui (son idempotentes) por si ese script no se aplico.
--
-- Idempotente: reutiliza el patron PRC_ADD_INDEX_IF_NOT_EXISTS de
-- indices_rendimiento.sql. Compatible MariaDB/MySQL.
-- Nota: el ALTER de cada indice nuevo puede tardar unos segundos en
-- tablas grandes; se paga una sola vez.
-- =============================================================================

-- Procedimiento: PRC_ADD_INDEX_IF_NOT_EXISTS
DROP PROCEDURE IF EXISTS `PRC_ADD_INDEX_IF_NOT_EXISTS`;
DELIMITER ;;
CREATE  PROCEDURE `PRC_ADD_INDEX_IF_NOT_EXISTS`(IN `p_tabla` VARCHAR(64),    /* Nombre de la tabla destino, sin backticks */
    IN `p_indice` VARCHAR(64),       /* Nombre del indice a crear (convencion IDX_<SUF>_<col>) */
    IN `p_columnas` VARCHAR(1000))   /* Lista de columnas entre backticks: '`COL1`, `COL2`' */
BEGIN
    /* Crea un indice si no existe ya en la BBDD actual. Idempotente y
       seguro de re-ejecutar. Pensado para migraciones de rendimiento. */
    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.statistics
         WHERE table_schema = DATABASE()
           AND table_name   = p_tabla
           AND index_name   = p_indice
    ) THEN
        SET @ddl = CONCAT('ALTER TABLE `', p_tabla,
                          '` ADD INDEX `', p_indice,
                          '` (', p_columnas, ')');
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END ;;
DELIMITER ;


-- -----------------------------------------------------------------------------
-- 1. fza_codigos_barras: lookup inverso "barras de este SKU" (desplegable
--    de traspasos, etiquetas). Sin el, full-scan de la tabla por cada SKU.
-- -----------------------------------------------------------------------------
CALL PRC_ADD_INDEX_IF_NOT_EXISTS(
  'fza_codigos_barras',
  'IDX_UNIDAD_CB',
  '`CODIGO_UNIDAD_CB`'
);


-- -----------------------------------------------------------------------------
-- 2. fza_codigos_barras: resolucion de pistola "que SKU tiene este codigo"
--    (inLibArticulosValidador, vi_caja_busqueda_unificada).
-- -----------------------------------------------------------------------------
CALL PRC_ADD_INDEX_IF_NOT_EXISTS(
  'fza_codigos_barras',
  'IDX_BARRAS_CB',
  '`CODIGO_BARRAS_CB`'
);


-- -----------------------------------------------------------------------------
-- 3. fza_articulos_proveedores: "referencias de este articulo". La PK
--    (CODIGO_PRV_AP, CODIGO_ART_AP) no sirve para filtrar por articulo.
--    Mismo indice que indices_rendimiento.sql bloque 3.
-- -----------------------------------------------------------------------------
CALL PRC_ADD_INDEX_IF_NOT_EXISTS(
  'fza_articulos_proveedores',
  'IDX_AP_ART_PRINC',
  '`CODIGO_ART_AP`, `ESPROVEEDORPRINCIPAL_AP`'
);


-- -----------------------------------------------------------------------------
-- 4. fza_articulos_stockactual: suma de stock por SKU entre almacenes.
--    Mismo indice que indices_rendimiento.sql bloque 2.
-- -----------------------------------------------------------------------------
CALL PRC_ADD_INDEX_IF_NOT_EXISTS(
  'fza_articulos_stockactual',
  'IDX_STK_UNIDAD',
  '`CODIGO_UNIDAD_STK`'
);


-- -----------------------------------------------------------------------------
-- 5. fza_articulos_skus: JOIN/WHERE por articulo padre.
--    Mismo indice que indices_rendimiento.sql bloque 1.
-- -----------------------------------------------------------------------------
CALL PRC_ADD_INDEX_IF_NOT_EXISTS(
  'fza_articulos_skus',
  'IDX_SKU_ART_ACT',
  '`CODIGO_ART_SKU`, `ESACTIVO_SKU`'
);


-- -----------------------------------------------------------------------------
-- Verificacion rapida (opcional): debe devolver los 5 indices.
-- -----------------------------------------------------------------------------
--   SELECT TABLE_NAME, INDEX_NAME,
--          GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS COLS
--     FROM information_schema.statistics
--    WHERE table_schema = DATABASE()
--      AND INDEX_NAME IN ('IDX_UNIDAD_CB', 'IDX_BARRAS_CB',
--                         'IDX_AP_ART_PRINC', 'IDX_STK_UNIDAD',
--                         'IDX_SKU_ART_ACT')
--    GROUP BY TABLE_NAME, INDEX_NAME
--    ORDER BY TABLE_NAME, INDEX_NAME;
