-- =============================================================================
-- Script: empleados.sql
-- Objetivo: tabla maestra de empleados (operarios de caja, traspasos y
--           arqueos) independiente de fza_usuarios + su pantalla en el menú.
--
-- Contexto:
--   Hoy la identidad del operario (quién cobra/traspasa/arquea) vive dentro de
--   fza_usuarios en dos columnas: CODIGO_EMPLEADO_USU (número de empleado en
--   caja) y DIMINUTIVO_TICKET_USU (diminutivo de caja / abreviatura del
--   ticket). Eso obliga a que todo operario tenga usuario de login. Las tablas
--   operativas ya guardan el código de empleado suelto (CODIGO_EMPLEADO_OPCAJA,
--   CODIGO_EMPLEADO_ARQ, CODIGO_EMPLEADO_TRSOL, CODIGO_CAJERO_FAC).
--
--   fza_empleados saca ese concepto a tabla propia, le añade datos básicos
--   (nombre, dirección, teléfono) y lo independiza del usuario de login: el
--   empleado y el usuario PUEDEN SER DISTINTOS. La auditoría (USUARIO_ALTA /
--   USUARIO_MODIF) sigue siendo el usuario logado (la sella el servicio
--   TServicioAuditoriaDatos), no el empleado.
--
-- Sufijo de tabla: EMPL (EMP ya es de fza_empresas). Registrado en el catálogo
--   §2 de LIBRO_DE_ESTILO_BBDD.md y en UNormalizerEngine.pas (InitDefaults).
--
-- Idempotente: CREATE TABLE IF NOT EXISTS + CREATE OR REPLACE VIEW +
--              INSERT IGNORE. Se puede lanzar varias veces sin efectos,
--              también después de la FASE 2 (el volcado desde fza_usuarios
--              va guardado por INFORMATION_SCHEMA).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tabla maestra de empleados
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fza_empleados` (
  `CODIGO_EMPL`             varchar(20)  NOT NULL
                            COMMENT 'Número de empleado en caja',
  `NOMBRE_EMPL`             varchar(100) NULL DEFAULT NULL,
  `DIRECCION_EMPL`          varchar(200) NULL DEFAULT NULL,
  `TELEFONO_EMPL`           varchar(20)  NULL DEFAULT NULL,
  `DIMINUTIVO_TICKET_EMPL`  varchar(10)  NULL DEFAULT NULL
                            COMMENT 'Diminutivo de caja / abreviatura del ticket',
  `ESACTIVO_EMPL`           char(1)      NOT NULL DEFAULT 'S'
                            COMMENT 'S/N. Caja/traspasos/arqueos listan solo S',
  `INSTANTE_MODIF`          datetime     DEFAULT NULL,
  `INSTANTE_ALTA`           datetime     NOT NULL,
  `USUARIO_ALTA`            varchar(100) NOT NULL,
  `USUARIO_MODIF`           varchar(100) DEFAULT NULL,
  PRIMARY KEY (`CODIGO_EMPL`),
  KEY `IDX_EMPL_ACTIVO`     (`ESACTIVO_EMPL`),
  KEY `IDX_EMPL_DIMINUTIVO` (`DIMINUTIVO_TICKET_EMPL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -----------------------------------------------------------------------------
-- 2. Vista de lectura para el Mto (mismo patrón que vi_usuarios: la pantalla
--    lee de la vista y escribe sobre la tabla). Passthrough, sin joins.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE ALGORITHM=UNDEFINED VIEW `vi_empleados` AS
SELECT `fza_empleados`.`CODIGO_EMPL`            AS `CODIGO_EMPL`,
       `fza_empleados`.`NOMBRE_EMPL`            AS `NOMBRE_EMPL`,
       `fza_empleados`.`DIRECCION_EMPL`         AS `DIRECCION_EMPL`,
       `fza_empleados`.`TELEFONO_EMPL`          AS `TELEFONO_EMPL`,
       `fza_empleados`.`DIMINUTIVO_TICKET_EMPL` AS `DIMINUTIVO_TICKET_EMPL`,
       `fza_empleados`.`ESACTIVO_EMPL`          AS `ESACTIVO_EMPL`,
       `fza_empleados`.`INSTANTE_MODIF`         AS `INSTANTE_MODIF`,
       `fza_empleados`.`INSTANTE_ALTA`          AS `INSTANTE_ALTA`,
       `fza_empleados`.`USUARIO_ALTA`           AS `USUARIO_ALTA`,
       `fza_empleados`.`USUARIO_MODIF`          AS `USUARIO_MODIF`
  FROM `fza_empleados`;

-- -----------------------------------------------------------------------------
-- 3. Volcado inicial desde fza_usuarios: cada usuario con CODIGO_EMPLEADO_USU
--    se convierte en un empleado, tomando su diminutivo de ticket. El NOMBRE
--    se siembra con el nombre de usuario como valor provisional (luego se edita
--    en la pantalla). INSERT IGNORE → idempotente y salta códigos duplicados.
--    Guardado por INFORMATION_SCHEMA: tras la FASE 2
--    (empleados_retirar_columnas_usuarios.sql) esas columnas ya no existen en
--    fza_usuarios y el volcado se omite (ya se hizo en su día).
-- -----------------------------------------------------------------------------
SET @nColOrigen := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_usuarios'
     AND COLUMN_NAME  = 'CODIGO_EMPLEADO_USU'
);
SET @sSql := IF(@nColOrigen = 1,
  'INSERT IGNORE INTO fza_empleados
     (CODIGO_EMPL, NOMBRE_EMPL, DIMINUTIVO_TICKET_EMPL, ESACTIVO_EMPL,
      INSTANTE_ALTA, USUARIO_ALTA)
   SELECT u.CODIGO_EMPLEADO_USU, u.USUARIO_USU, u.DIMINUTIVO_TICKET_USU,
          COALESCE(u.ESACTIVO_USU, ''S''), NOW(), ''SISTEMA''
     FROM fza_usuarios u
    WHERE u.CODIGO_EMPLEADO_USU IS NOT NULL
      AND TRIM(u.CODIGO_EMPLEADO_USU) <> ''''',
  'SELECT ''Volcado omitido (columnas ya retiradas en FASE 2)'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 4. Alta de la pantalla en el menú (fza_winforms). NUM_VENTANAS_WINF = 5 como
--    el resto de mantenimientos maestros (Usuarios, Grupos, Perfiles).
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`, `SHORTCUT_WINF`,
   `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('Empleados', 'Empleados', 'mnuEmpleados',
   'inMtoEmpleados.TfrmMtoEmpleados', '',
   'UniDataEmpleados.TdmEmpleados', 5);

-- -----------------------------------------------------------------------------
-- 5. Permiso de acceso al menú (por defecto permitido para 'Todos').
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `fza_permisos`
  (`USUARIO_GRUPO_PERM`, `CODIGO_PERM`, `VALOR_PERM`, `DESCRIPCION_PERM`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`)
VALUES
  ('Todos', 'menu.Empleados', 'S', 'Empleados', NOW(), 'SISTEMA');
