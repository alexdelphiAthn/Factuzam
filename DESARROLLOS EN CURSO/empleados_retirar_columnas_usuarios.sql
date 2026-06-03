-- =============================================================================
-- Script: empleados_retirar_columnas_usuarios.sql
-- Objetivo: FASE 2 de empleados. Completa la independencia empleado/usuario
--           retirando de fza_usuarios las dos columnas que ya viven en
--           fza_empleados (FASE 1, empleados.sql):
--             - CODIGO_EMPLEADO_USU
--             - DIMINUTIVO_TICKET_USU
--           Caja, traspasos y arqueos leen ya de fza_empleados (lado app).
--
-- Prerrequisito: empleados.sql ejecutado -> fza_empleados existe y contiene el
--   volcado. Por seguridad este script lo re-vuelca antes de borrar nada.
--
-- Rollback SIN PÉRDIDA: antes de borrar se guarda el mapeo
--   (USUARIO_USU -> CODIGO_EMPLEADO_USU, DIMINUTIVO_TICKET_USU) en
--   fza_usuarios_empl_bak. Para deshacer: empleados_retirar_columnas_usuarios_rollback.sql.
--
-- Idempotente: cada borrado va guardado por INFORMATION_SCHEMA; se puede lanzar
--   varias veces aunque las columnas ya no existan.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Re-volcado de seguridad a fza_empleados (solo si origen y destino existen).
-- -----------------------------------------------------------------------------
SET @nColOrigen := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'CODIGO_EMPLEADO_USU'
);
SET @nTablaDestino := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_empleados'
);
SET @sSql := IF(@nColOrigen = 1 AND @nTablaDestino = 1,
  'INSERT IGNORE INTO fza_empleados
     (CODIGO_EMPL, NOMBRE_EMPL, DIMINUTIVO_TICKET_EMPL, ESACTIVO_EMPL,
      INSTANTE_ALTA, USUARIO_ALTA)
   SELECT u.CODIGO_EMPLEADO_USU, u.USUARIO_USU, u.DIMINUTIVO_TICKET_USU,
          COALESCE(u.ESACTIVO_USU, ''S''), NOW(), ''SISTEMA''
     FROM fza_usuarios u
    WHERE u.CODIGO_EMPLEADO_USU IS NOT NULL
      AND TRIM(u.CODIGO_EMPLEADO_USU) <> ''''',
  'SELECT ''Volcado omitido (origen o destino no disponible)'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 2. Backup del mapeo usuario->empleado para un rollback sin pérdida. Snapshot
--    solo mientras las columnas existan (INSERT IGNORE -> re-ejecutable).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_usuarios_empl_bak` (
  `USUARIO_USU`           varchar(100) NOT NULL,
  `CODIGO_EMPLEADO_USU`   varchar(10)  NULL DEFAULT NULL,
  `DIMINUTIVO_TICKET_USU` varchar(10)  NULL DEFAULT NULL,
  PRIMARY KEY (`USUARIO_USU`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SET @nColBak := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'CODIGO_EMPLEADO_USU'
);
SET @sSql := IF(@nColBak = 1,
  'INSERT IGNORE INTO fza_usuarios_empl_bak
     (USUARIO_USU, CODIGO_EMPLEADO_USU, DIMINUTIVO_TICKET_USU)
   SELECT USUARIO_USU, CODIGO_EMPLEADO_USU, DIMINUTIVO_TICKET_USU
     FROM fza_usuarios',
  'SELECT ''Backup omitido (columnas ya retiradas)'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 3. Recrear vi_usuarios SIN las dos columnas (la vista las referenciaba). Se
--    hace antes de borrarlas para no dejar la vista inválida.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_usuarios` AS
SELECT `fza_usuarios`.`USUARIO_USU`              AS `USUARIO_USU`,
       `fza_usuarios`.`PASSWORD_USU`             AS `PASSWORD_USU`,
       `fza_usuarios`.`GRUPO_USU`                AS `GRUPO_USU`,
       `fza_usuarios`.`ESACTIVO_USU`             AS `ESACTIVO_USU`,
       `fza_usuarios`.`EMPRESA_DEFECTO_USU`      AS `EMPRESA_DEFECTO_USU`,
       `fza_usuarios`.`ULTIMO_LOGIN_USU`         AS `ULTIMO_LOGIN_USU`,
       `fza_usuarios`.`INSTANTE_MODIF`           AS `INSTANTE_MODIF`,
       `fza_usuarios`.`INSTANTE_ALTA`            AS `INSTANTE_ALTA`,
       `fza_usuarios`.`USUARIO_ALTA`             AS `USUARIO_ALTA`,
       `fza_usuarios`.`USUARIO_MODIF`            AS `USUARIO_MODIF`,
       `fza_usuarios`.`ALMACEN_DEFECTO_USU`      AS `ALMACEN_DEFECTO_USU`,
       `fza_usuarios`.`CAJA_DEFECTO_USU`         AS `CAJA_DEFECTO_USU`,
       `vi_empresas`.`RAZON_SOCIAL_EMP`          AS `RAZON_SOCIAL_EMP`,
       `fza_usuarios_grupos`.`GRUPO_USUGRP`      AS `GRUPO_USUGRP`,
       `fza_usuarios_grupos`.`ESGRUPOADMINISTRADOR_USUGRP`
                                                 AS `ESGRUPOADMINISTRADOR_USUGRP`
  FROM ((`fza_usuarios`
         JOIN `fza_usuarios_grupos`
           ON(`fza_usuarios`.`GRUPO_USU` = `fza_usuarios_grupos`.`GRUPO_USUGRP`))
        LEFT JOIN `vi_empresas`
           ON(`fza_usuarios`.`EMPRESA_DEFECTO_USU` = `vi_empresas`.`CODIGO_EMP_EMP`));

-- -----------------------------------------------------------------------------
-- 4. Retirar CODIGO_EMPLEADO_USU de fza_usuarios (guardado -> idempotente).
-- -----------------------------------------------------------------------------
SET @nDrop1 := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'CODIGO_EMPLEADO_USU'
);
SET @sSql := IF(@nDrop1 = 1,
  'ALTER TABLE fza_usuarios DROP COLUMN CODIGO_EMPLEADO_USU',
  'SELECT ''CODIGO_EMPLEADO_USU ya retirada, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 5. Retirar DIMINUTIVO_TICKET_USU de fza_usuarios (guardado -> idempotente).
-- -----------------------------------------------------------------------------
SET @nDrop2 := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'DIMINUTIVO_TICKET_USU'
);
SET @sSql := IF(@nDrop2 = 1,
  'ALTER TABLE fza_usuarios DROP COLUMN DIMINUTIVO_TICKET_USU',
  'SELECT ''DIMINUTIVO_TICKET_USU ya retirada, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 6. Limpiar la config de columnas visibles de esas dos columnas (si existía).
-- -----------------------------------------------------------------------------
DELETE FROM `fza_config_campos`
 WHERE `TABLA_OBJETIVO_CC` = 'fza_usuarios'
   AND `OBJETIVO_CC` IN ('CODIGO_EMPLEADO_USU', 'DIMINUTIVO_TICKET_USU');
