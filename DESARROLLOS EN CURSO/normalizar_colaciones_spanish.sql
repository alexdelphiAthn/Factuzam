-- =============================================================================
-- Normalizar colaciones a utf8mb4_spanish_ci (fix error 1267 en Arqueos)
-- =============================================================================
-- MariaDB >= 11.2 asigna a utf8mb4 la colacion por defecto
-- utf8mb4_uca1400_ai_ci (variable character_set_collations). Ademas, algunas
-- copias antiguas o imports ejecutados sin charset explicito pueden dejar
-- tablas en utf8/utf8mb3. Los CREATE TABLE sin COLLATE explicito crearon
-- tablas con otra colacion, mientras el resto de la BBDD es
-- utf8mb4_spanish_ci:
--
--   fza_empleados, fza_caja_arqueos, fza_caja_arqueos_recuento,
--   fza_permisos, fza_informes_guias, fza_inventarios_recuentos,
--   fza_usuarios_empl_bak
--
-- Consecuencia: cualquier JOIN columna-contra-columna entre una tabla
-- uca1400 y una spanish_ci lanza [1267] "Illegal mix of collations
-- (utf8mb4_uca1400_ai_ci,IMPLICIT) and (utf8mb4_spanish_ci,IMPLICIT) for
-- operation '='". Caso real: el resumen por empleado del Arqueo (F11) une
-- fza_caja_operaciones.CODIGO_EMPLEADO_OPCAJA (spanish_ci) con
-- fza_empleados.CODIGO_EMPL (uca1400). El "SET NAMES ... spanish_ci" de
-- TdmConn no cubre esto: solo afecta a literales y parametros, no a la
-- colacion fisica de las columnas.
--
-- Que hace:
--   1. Fija el default de la propia BBDD a utf8mb4_spanish_ci (los CREATE
--      TABLE futuros sin charset heredaran la colacion correcta).
--   2. Recorre INFORMATION_SCHEMA.TABLES/COLUMNS y convierte toda tabla base
--      cuyo default o columnas de texto no esten en utf8mb4_spanish_ci.
--      CONVERT TO actualiza tambien el charset y la colacion de todas las
--      columnas de texto.
--   3. Verificacion final: debe devolver 0 filas.
--
-- Idempotente: re-ejecutar no encuentra tablas que convertir.
-- Duracion: normalmente segundos si solo quedan tablas WIP pequenas. Si una
-- copia antigua dejo muchas tablas en utf8/utf8mb3, MariaDB reconstruira esas
-- tablas y puede tardar mas.
-- Los scripts que crearon estas tablas quedan corregidos con COLLATE
-- explicito para instalaciones nuevas (ver normalizar_colaciones_spanish.md).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Default de la propia base de datos
-- -----------------------------------------------------------------------------
SET @sSql := CONCAT('ALTER DATABASE `', DATABASE(),
                    '` CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 2. Convertir las tablas desviadas
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_NORMALIZAR_COLACIONES`;
DELIMITER ;;
CREATE PROCEDURE `PRC_NORMALIZAR_COLACIONES`()
BEGIN
    /* Convierte a utf8mb4_spanish_ci toda tabla base del esquema actual cuyo
       default o columnas de texto tengan otra colacion. */
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
               );
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET bFin = 1;
    OPEN curTablas;
    bucle: LOOP
        FETCH curTablas INTO sTabla;
        IF bFin = 1 THEN
            LEAVE bucle;
        END IF;
        SET @sDdl = CONCAT('ALTER TABLE `', sTabla,
                           '` CONVERT TO CHARACTER SET utf8mb4',
                           ' COLLATE utf8mb4_spanish_ci');
        PREPARE stmt FROM @sDdl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE curTablas;
END ;;
DELIMITER ;

CALL PRC_NORMALIZAR_COLACIONES();
DROP PROCEDURE IF EXISTS `PRC_NORMALIZAR_COLACIONES`;

-- -----------------------------------------------------------------------------
-- 3. Verificacion: debe devolver 0 filas
-- -----------------------------------------------------------------------------
SELECT DISTINCT T.TABLE_NAME, T.TABLE_COLLATION
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
