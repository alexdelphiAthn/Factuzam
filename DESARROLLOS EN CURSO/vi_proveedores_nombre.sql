-- =============================================================================
-- Expone NOMBRE_PRV en la vista vi_proveedores
-- =============================================================================
-- vi_proveedores se definio antes de que la tabla fza_proveedores tuviera la
-- columna NOMBRE_PRV (anadida en proveedores_nombre.sql). El buscador de
-- proveedores de las Sesiones de Compra (inMtoComprasSesiones -> inMtoGenSearch
-- con `SELECT * FROM vi_proveedores`) necesita ver tanto el nombre comercial
-- (NOMBRE_PRV) como la razon social (RAZON_SOCIAL_PRV) para que se distinga
-- bien quien es el proveedor. Recreamos la vista anadiendo NOMBRE_PRV justo
-- detras de RAZON_SOCIAL_PRV (mismo orden que en la tabla).
--
-- Ademas se ordena la vista por ORDEN_PRV (el orden visual que el usuario fija
-- en el mantenimiento de proveedores) para que los lookups/combos que leen
-- `SELECT * FROM vi_proveedores` sin ORDER BY propio (p.ej. el combo de
-- proveedores de inMtoInventarios) salgan en el orden del usuario. El buscador
-- de Sesiones de Compra usa su propio `ORDER BY RAZON_SOCIAL_PRV`, que al ser
-- externo prevalece, asi que ese caso no cambia. La vista es de una sola tabla,
-- por lo que el ORDER BY no penaliza como en las vistas con joins grandes (ver
-- fix_vi_atributos_nombres_sin_orderby.sql).
--
-- Idempotente:
--   - El bloque que anade NOMBRE_PRV solo crea la columna si no existe
--     (mismo patron que proveedores_nombre.sql), por lo que este script se
--     puede lanzar aunque proveedores_nombre.sql no se haya ejecutado antes.
--   - CREATE OR REPLACE VIEW reescribe la definicion sin error al repetir.
-- =============================================================================

-- 1. Asegurar la columna NOMBRE_PRV en fza_proveedores (idempotente).
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_proveedores'
     AND COLUMN_NAME  = 'NOMBRE_PRV'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_proveedores
     ADD COLUMN NOMBRE_PRV varchar(200) NULL DEFAULT NULL
     AFTER RAZON_SOCIAL_PRV',
  'SELECT ''NOMBRE_PRV ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Recrear la vista incluyendo NOMBRE_PRV y ordenada por ORDEN_PRV.
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_proveedores` AS
SELECT `fza_proveedores`.`CODIGO_PRV_PRV`         AS `CODIGO_PRV_PRV`,
       `fza_proveedores`.`ESACTIVO_PRV`           AS `ESACTIVO_PRV`,
       `fza_proveedores`.`RAZON_SOCIAL_PRV`       AS `RAZON_SOCIAL_PRV`,
       `fza_proveedores`.`NOMBRE_PRV`             AS `NOMBRE_PRV`,
       `fza_proveedores`.`NIF_PRV`                AS `NIF_PRV`,
       `fza_proveedores`.`MOVIL_PRV`              AS `MOVIL_PRV`,
       `fza_proveedores`.`EMAIL_PRV`              AS `EMAIL_PRV`,
       `fza_proveedores`.`DIRECCION1_PRV`         AS `DIRECCION1_PRV`,
       `fza_proveedores`.`DIRECCION2_PRV`         AS `DIRECCION2_PRV`,
       `fza_proveedores`.`POBLACION_PRV`          AS `POBLACION_PRV`,
       `fza_proveedores`.`PROVINCIA_PRV`          AS `PROVINCIA_PRV`,
       `fza_proveedores`.`CODIGO_POSTAL_PRV`      AS `CODIGO_POSTAL_PRV`,
       `fza_proveedores`.`PAIS_PRV`               AS `PAIS_PRV`,
       `fza_proveedores`.`OBSERVACIONES_PRV`      AS `OBSERVACIONES_PRV`,
       `fza_proveedores`.`REFERENCIA_PRV`         AS `REFERENCIA_PRV`,
       `fza_proveedores`.`CONTACTO_PRV`           AS `CONTACTO_PRV`,
       `fza_proveedores`.`TELEFONO_CONTACTO_PRV`  AS `TELEFONO_CONTACTO_PRV`,
       `fza_proveedores`.`TELEFONO_PRV`           AS `TELEFONO_PRV`,
       `fza_proveedores`.`IBAN_PRV`               AS `IBAN_PRV`,
       `fza_proveedores`.`ORDEN_PRV`              AS `ORDEN_PRV`,
       `fza_proveedores`.`INSTANTE_MODIF`         AS `INSTANTE_MODIF`,
       `fza_proveedores`.`INSTANTE_ALTA`          AS `INSTANTE_ALTA`,
       `fza_proveedores`.`USUARIO_ALTA`           AS `USUARIO_ALTA`,
       `fza_proveedores`.`USUARIO_MODIF`          AS `USUARIO_MODIF`
  FROM `fza_proveedores`
 ORDER BY `ORDEN_PRV`;
