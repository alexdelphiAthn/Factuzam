-- =============================================================================
-- Reparacion de colaciones para factuzam
-- =============================================================================
-- Caso cubierto:
--   - La BBDD tiene default utf8mb4_spanish_ci, pero la sesion de MariaDB 12.x
--     queda en utf8mb4_uca1400_ai_ci o alguna vista/literal queda como utf8mb3.
--   - Al recrear vi_caja_busqueda_unificada falla:
--       COLLATION 'utf8mb4_spanish_ci' is not valid for CHARACTER SET 'utf8mb3'
--
-- Ejecutar conectado al servidor destino. El script falla si no existe la BBDD
-- factuzam, para evitar reparar otra BBDD por accidente. Esta BBDD puede venir
-- importada desde el dump factuzam_oficial.sql.
--
-- Idempotente: puede re-ejecutarse.
-- =============================================================================

USE `factuzam`;
SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci;

-- -----------------------------------------------------------------------------
-- 1. Default de la BBDD
-- -----------------------------------------------------------------------------
ALTER DATABASE `factuzam`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;

-- -----------------------------------------------------------------------------
-- 2. Convertir tablas base con default o columnas de texto desviadas
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_REPARAR_COLACIONES_FACTUZAM`;
DELIMITER ;;
CREATE PROCEDURE `PRC_REPARAR_COLACIONES_FACTUZAM`()
BEGIN
    DECLARE bFin   INT DEFAULT 0;
    DECLARE sTabla VARCHAR(64);
    DECLARE curTablas CURSOR FOR
        SELECT DISTINCT T.TABLE_NAME
          FROM INFORMATION_SCHEMA.TABLES T
         WHERE T.TABLE_SCHEMA = DATABASE()
           AND T.TABLE_TYPE = 'BASE TABLE'
           AND (
                 (T.TABLE_COLLATION IS NOT NULL
                  AND T.TABLE_COLLATION <> 'utf8mb4_spanish_ci')
                 OR EXISTS (
                    SELECT 1
                      FROM INFORMATION_SCHEMA.COLUMNS C
                     WHERE C.TABLE_SCHEMA = T.TABLE_SCHEMA
                       AND C.TABLE_NAME = T.TABLE_NAME
                       AND C.CHARACTER_SET_NAME IS NOT NULL
                       AND (C.CHARACTER_SET_NAME <> 'utf8mb4'
                            OR C.COLLATION_NAME <>
                               'utf8mb4_spanish_ci')
                 )
               )
         ORDER BY T.TABLE_NAME;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET bFin = 1;
    OPEN curTablas;
    bucle: LOOP
        FETCH curTablas INTO sTabla;
        IF bFin = 1 THEN
            LEAVE bucle;
        END IF;
        SET @sDdl = CONCAT('ALTER TABLE `', REPLACE(sTabla, '`', '``'),
                           '` CONVERT TO CHARACTER SET utf8mb4',
                           ' COLLATE utf8mb4_spanish_ci');
        PREPARE stmt FROM @sDdl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE curTablas;
END ;;
DELIMITER ;

CALL PRC_REPARAR_COLACIONES_FACTUZAM();
DROP PROCEDURE IF EXISTS `PRC_REPARAR_COLACIONES_FACTUZAM`;

-- -----------------------------------------------------------------------------
-- 3. Recrear vi_caja_busqueda_unificada conservando los indices
-- -----------------------------------------------------------------------------
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_caja_busqueda_unificada` AS
SELECT `a`.`CODIGO_ART_ART` AS `INPUT_BUSQUEDA`,
       _utf8mb4'CODIGO' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_articulos` `a`
 WHERE `a`.`ESACTIVO_ART` = 'S'
UNION ALL
SELECT `sku`.`CODIGO_UNIDAD_SKU` AS `INPUT_BUSQUEDA`,
       _utf8mb4'SKU' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       `sku`.`CODIGO_UNIDAD_SKU` AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_articulos_skus` `sku`
  JOIN `fza_articulos` `a`
    ON `sku`.`CODIGO_ART_SKU` = `a`.`CODIGO_ART_ART`
 WHERE `sku`.`ESACTIVO_SKU` = 'S'
UNION ALL
SELECT `cb`.`CODIGO_BARRAS_CB` AS `INPUT_BUSQUEDA`,
       _utf8mb4'EAN' COLLATE utf8mb4_spanish_ci AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       `sku`.`CODIGO_UNIDAD_SKU` AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_codigos_barras` `cb`
  JOIN `fza_articulos_skus` `sku`
    ON `cb`.`CODIGO_UNIDAD_CB` = `sku`.`CODIGO_UNIDAD_SKU`
  JOIN `fza_articulos` `a`
    ON `sku`.`CODIGO_ART_SKU` = `a`.`CODIGO_ART_ART`
UNION ALL
SELECT `ap`.`REF_PROVEEDOR_AP` AS `INPUT_BUSQUEDA`,
       _utf8mb4'MODELO_PROV' COLLATE utf8mb4_spanish_ci
       AS `TIPO_COINCIDENCIA`,
       `a`.`CODIGO_ART_ART` AS `CODIGO_PADRE`,
       CAST(NULL AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_spanish_ci
       AS `CODIGO_SKU`,
       `a`.`DESCRIPCION_ART` AS `DESCRIPCION_ART`,
       `a`.`TIPO_ART` AS `TIPO_ART`
  FROM `fza_articulos_proveedores` `ap`
  JOIN `fza_articulos` `a`
    ON `ap`.`CODIGO_ART_AP` = `a`.`CODIGO_ART_ART`
 WHERE `a`.`ESACTIVO_ART` = 'S'
   AND `ap`.`REF_PROVEEDOR_AP` IS NOT NULL
   AND `ap`.`REF_PROVEEDOR_AP` <> '';

-- -----------------------------------------------------------------------------
-- 4. Verificacion
-- -----------------------------------------------------------------------------
SELECT 'TABLAS_O_COLUMNAS_DESVIADAS' AS comprobacion,
       COUNT(*) AS pendientes
  FROM INFORMATION_SCHEMA.TABLES T
 WHERE T.TABLE_SCHEMA = DATABASE()
   AND T.TABLE_TYPE = 'BASE TABLE'
   AND (
         (T.TABLE_COLLATION IS NOT NULL
          AND T.TABLE_COLLATION <> 'utf8mb4_spanish_ci')
         OR EXISTS (
            SELECT 1
              FROM INFORMATION_SCHEMA.COLUMNS C
             WHERE C.TABLE_SCHEMA = T.TABLE_SCHEMA
               AND C.TABLE_NAME = T.TABLE_NAME
               AND C.CHARACTER_SET_NAME IS NOT NULL
               AND (C.CHARACTER_SET_NAME <> 'utf8mb4'
                    OR C.COLLATION_NAME <> 'utf8mb4_spanish_ci')
         )
       );

SELECT TABLE_NAME, COLUMN_NAME, CHARACTER_SET_NAME, COLLATION_NAME
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'vi_caja_busqueda_unificada'
 ORDER BY ORDINAL_POSITION;

SELECT T.TABLE_NAME, C.COLUMN_NAME, C.CHARACTER_SET_NAME, C.COLLATION_NAME
  FROM INFORMATION_SCHEMA.COLUMNS C
  JOIN INFORMATION_SCHEMA.TABLES T
    ON T.TABLE_SCHEMA = C.TABLE_SCHEMA
   AND T.TABLE_NAME = C.TABLE_NAME
 WHERE C.TABLE_SCHEMA = DATABASE()
   AND T.TABLE_TYPE = 'VIEW'
   AND C.CHARACTER_SET_NAME IS NOT NULL
   AND (C.CHARACTER_SET_NAME <> 'utf8mb4'
        OR C.COLLATION_NAME <> 'utf8mb4_spanish_ci')
 ORDER BY T.TABLE_NAME, C.ORDINAL_POSITION;
