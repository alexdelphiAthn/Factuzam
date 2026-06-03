-- =============================================================================
-- Script: empleados_retirar_columnas_usuarios_rollback.sql
-- Objetivo: DESHACER empleados_retirar_columnas_usuarios.sql. Reañade a
--           fza_usuarios las columnas CODIGO_EMPLEADO_USU y
--           DIMINUTIVO_TICKET_USU y restaura sus valores desde el backup
--           fza_usuarios_empl_bak. Recrea vi_usuarios con esas columnas y
--           reinserta su config de columnas visibles.
--
-- Nota: el rollback NO retoca el lado app (caja/traspasos/arqueos quedan
--   leyendo de fza_empleados). Restaura solo el esquema y los datos de
--   fza_usuarios. fza_empleados y su pantalla se mantienen.
--
-- Idempotente: cada acción va guardada por INFORMATION_SCHEMA.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Reañadir DIMINUTIVO_TICKET_USU (en su posición original) si falta.
-- -----------------------------------------------------------------------------
SET @nCol1 := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'DIMINUTIVO_TICKET_USU'
);
SET @sSql := IF(@nCol1 = 0,
  'ALTER TABLE fza_usuarios
     ADD COLUMN DIMINUTIVO_TICKET_USU varchar(10) NULL DEFAULT NULL
     AFTER EMPRESA_DEFECTO_USU',
  'SELECT ''DIMINUTIVO_TICKET_USU ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 2. Reañadir CODIGO_EMPLEADO_USU (en su posición original) si falta.
-- -----------------------------------------------------------------------------
SET @nCol2 := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'CODIGO_EMPLEADO_USU'
);
SET @sSql := IF(@nCol2 = 0,
  'ALTER TABLE fza_usuarios
     ADD COLUMN CODIGO_EMPLEADO_USU varchar(10) NULL DEFAULT NULL
     AFTER DIMINUTIVO_TICKET_USU',
  'SELECT ''CODIGO_EMPLEADO_USU ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 3. Restaurar valores desde el backup (solo si la tabla de backup existe).
-- -----------------------------------------------------------------------------
SET @nBak := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios_empl_bak'
);
SET @sSql := IF(@nBak = 1,
  'UPDATE fza_usuarios u
     JOIN fza_usuarios_empl_bak b ON b.USUARIO_USU = u.USUARIO_USU
      SET u.CODIGO_EMPLEADO_USU   = b.CODIGO_EMPLEADO_USU,
          u.DIMINUTIVO_TICKET_USU = b.DIMINUTIVO_TICKET_USU',
  'SELECT ''Sin backup que restaurar'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 4. Recrear vi_usuarios CON las dos columnas (definición original).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_usuarios` AS
SELECT `fza_usuarios`.`USUARIO_USU`              AS `USUARIO_USU`,
       `fza_usuarios`.`PASSWORD_USU`             AS `PASSWORD_USU`,
       `fza_usuarios`.`GRUPO_USU`                AS `GRUPO_USU`,
       `fza_usuarios`.`ESACTIVO_USU`             AS `ESACTIVO_USU`,
       `fza_usuarios`.`EMPRESA_DEFECTO_USU`      AS `EMPRESA_DEFECTO_USU`,
       `fza_usuarios`.`DIMINUTIVO_TICKET_USU`    AS `DIMINUTIVO_TICKET_USU`,
       `fza_usuarios`.`CODIGO_EMPLEADO_USU`      AS `CODIGO_EMPLEADO_USU`,
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
-- 5. Reinsertar la config de columnas visibles de esas dos columnas.
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
VALUES
  ('fza_usuarios', 'DIMINUTIVO_TICKET_USU', 'Abrev. Ticket',  80, 7, 'N'),
  ('fza_usuarios', 'CODIGO_EMPLEADO_USU',   'Cód. Empleado', 100, 8, 'N');
