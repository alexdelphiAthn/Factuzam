-- ============================================================================
-- Traspasos en caja — solicitudes de traspaso entre almacenes
-- Diseno DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
-- (detalle funcional en DESARROLLOS EN CURSO/traspasos_caja.md).
--
-- Crea las dos tablas del CICLO DE SOLICITUDES (peticion -> atencion):
--   fza_traspasos_solicitudes         (cabecera, sufijo TRSOL)
--   fza_traspasos_solicitudes_lineas  (lineas,   sufijo TRSOLLIN)
-- y siembra el contador global 'TS' para numerar las solicitudes.
--
-- El TRASPASO EJECUTADO no necesita tablas nuevas: se graba en
-- fza_caja_operaciones (TIPO_OPERACION_OPCAJA TR/AT) + fza_movimientos_almacen
-- (par S+E). Estas tablas solo guardan la PETICION pendiente y su estado.
--
-- Idempotente: pasa por INFORMATION_SCHEMA (TABLES / STATISTICS) antes de crear
-- cada tabla e indice; el contador se siembra solo si no existe la fila global.
-- Sufijos TRSOL / TRSOLLIN dados de alta en LIBRO_DE_ESTILO_BBDD.md (§2) y en
-- src/utilnormbbdd/UNormalizerEngine.pas (InitDefaults).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Cabecera de la solicitud (TRSOL)
-- ---------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_traspasos_solicitudes` ('
  '  `NUMERO_TRSOL`             varchar(20)   NOT NULL,'
  '  `SERIE_TRSOL`              varchar(20)   NOT NULL,'
  '  `FECHA_TRSOL`              date          NULL DEFAULT NULL,'
  '  `ESTADO_TRSOL`             varchar(20)   NOT NULL DEFAULT ''PENDIENTE'''
  '       COMMENT ''PENDIENTE, PARCIAL, ATENDIDA, RECHAZADA, CANCELADA'','
  '  `CODIGO_EMP_TRSOL`         varchar(20)   NOT NULL,'
  '  `CODIGO_ALM_ORIGEN_TRSOL`  varchar(10)   NOT NULL'
  '       COMMENT ''A quien se pide = origen del futuro traspaso'','
  '  `CODIGO_ALM_DESTINO_TRSOL` varchar(10)   NOT NULL'
  '       COMMENT ''Quien pide = propio = destino del futuro traspaso'','
  '  `CODIGO_EMP_CONTRA_TRSOL`  varchar(20)   NULL DEFAULT NULL,'
  '  `CODIGO_CAJA_TRSOL`        varchar(10)   NULL DEFAULT NULL,'
  '  `CODIGO_EMPLEADO_TRSOL`    varchar(20)   NULL DEFAULT NULL,'
  '  `OBSERVACIONES_TRSOL`      varchar(1000) NULL DEFAULT '''','
  '  `INSTANTE_MODIF`           timestamp     NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`            timestamp     NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`             varchar(100)  NOT NULL,'
  '  `USUARIO_MODIF`            varchar(100)  NOT NULL,'
  '  PRIMARY KEY (`NUMERO_TRSOL`,`SERIE_TRSOL`)'
  ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes'
     AND INDEX_NAME   = 'IDX_TRSOL_ESTADO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_traspasos_solicitudes` '
  'ADD INDEX `IDX_TRSOL_ESTADO` (`ESTADO_TRSOL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes'
     AND INDEX_NAME   = 'IDX_TRSOL_ORIGEN'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_traspasos_solicitudes` '
  'ADD INDEX `IDX_TRSOL_ORIGEN` (`CODIGO_ALM_ORIGEN_TRSOL`,`ESTADO_TRSOL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes'
     AND INDEX_NAME   = 'IDX_TRSOL_DESTINO'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_traspasos_solicitudes` '
  'ADD INDEX `IDX_TRSOL_DESTINO` (`CODIGO_ALM_DESTINO_TRSOL`,`ESTADO_TRSOL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes'
     AND INDEX_NAME   = 'IDX_TRSOL_EMP'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_traspasos_solicitudes` '
  'ADD INDEX `IDX_TRSOL_EMP` (`CODIGO_EMP_TRSOL`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Lineas de la solicitud (TRSOLLIN)
-- ---------------------------------------------------------------------------
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes_lineas'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_traspasos_solicitudes_lineas` ('
  '  `NUMERO_TRSOL_TRSOLLIN`         varchar(20)   NOT NULL,'
  '  `SERIE_TRSOL_TRSOLLIN`          varchar(20)   NOT NULL,'
  '  `LINEA_TRSOLLIN`                varchar(4)    NOT NULL,'
  '  `CODIGO_ART_TRSOLLIN`           varchar(20)   NULL DEFAULT NULL,'
  '  `CODIGO_UNIDAD_TRSOLLIN`        varchar(50)   NOT NULL'
  '       COMMENT ''SKU solicitado'','
  '  `DESCRIPCION_ARTICULO_TRSOLLIN` varchar(100)  NULL DEFAULT NULL,'
  '  `CANTIDAD_PEDIDA_TRSOLLIN`      decimal(19,6) NOT NULL DEFAULT ''0.000000'','
  '  `CANTIDAD_SERVIDA_TRSOLLIN`     decimal(19,6) NOT NULL DEFAULT ''0.000000'''
  '       COMMENT ''Unidades ya atendidas (para estado PARCIAL)'','
  '  `ESATENDIDA_TRSOLLIN`           varchar(1)    NOT NULL DEFAULT ''N'','
  '  `MOTIVO_RECHAZO_TRSOLLIN`       varchar(255)  NULL DEFAULT NULL'
  '       COMMENT ''Motivo si la linea se deniega (servida=0)'','
  '  `INSTANTE_MODIF`                timestamp     NOT NULL'
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`                 timestamp     NOT NULL'
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`                  varchar(100)  NOT NULL,'
  '  `USUARIO_MODIF`                 varchar(100)  NOT NULL,'
  '  PRIMARY KEY (`NUMERO_TRSOL_TRSOLLIN`,`SERIE_TRSOL_TRSOLLIN`,'
  '               `LINEA_TRSOLLIN`)'
  ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes_lineas'
     AND INDEX_NAME   = 'IDX_TRSOLLIN_SKU'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_traspasos_solicitudes_lineas` '
  'ADD INDEX `IDX_TRSOLLIN_SKU` (`CODIGO_UNIDAD_TRSOLLIN`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Columna MOTIVO_RECHAZO_TRSOLLIN: anadida despues de la creacion original,
-- por eso va con guarda idempotente (sirve para BBDD ya existentes y para las
-- nuevas). Guarda el motivo cuando se deniega una linea (cantidad servida = 0).
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes_lineas'
     AND COLUMN_NAME  = 'MOTIVO_RECHAZO_TRSOLLIN'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_traspasos_solicitudes_lineas` '
  'ADD COLUMN `MOTIVO_RECHAZO_TRSOLLIN` varchar(255) NULL DEFAULT NULL '
  'COMMENT ''Motivo si la linea se deniega (servida=0)'' '
  'AFTER `ESATENDIDA_TRSOLLIN`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 3. Contador global de solicitudes de traspaso (TIPO_DOC = 'TS')
-- Lo consume inLibtb.ObtenerSiguienteContador('TS') (SP PRC_GET_NEXT_CONT).
-- Se siembra solo si no existe ya la fila global ('TS','-','-').
-- ---------------------------------------------------------------------------
INSERT INTO `fza_contadores`
  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, `NUM_DIGITOS_CON`,
   `ESACTIVO_CON`, `DEFAULT_CON`, `INSTANTE_ALTA`, `USUARIO_ALTA`,
   `USUARIO_MODIF`)
SELECT 'TS', '-', '-', 0, 10, 'S', 'S', NOW(), 'SISTEMA', 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM `fza_contadores`
    WHERE `TIPO_DOC_CON` = 'TS'
      AND `EMPRESA_CON` = '-'
      AND `SERIE_CON` = '-');

-- ---------------------------------------------------------------------------
-- 4. Alinear la colacion de las tablas con la del resto del modelo
--    (utf8mb4_spanish_ci). Si MariaDB las creo con su colacion por defecto
--    (utf8mb4_uca1400_ai_ci), los JOIN/'=' contra fza_articulos_* fallan con
--    "Illegal mix of collations". Solo se convierte si la tabla no esta ya
--    en spanish_ci (idempotente).
-- ---------------------------------------------------------------------------
SET @col := (
  SELECT TABLE_COLLATION FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes');
SET @ddl := IF(@col IS NOT NULL AND @col <> 'utf8mb4_spanish_ci',
  'ALTER TABLE `fza_traspasos_solicitudes` '
  'CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col := (
  SELECT TABLE_COLLATION FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_traspasos_solicitudes_lineas');
SET @ddl := IF(@col IS NOT NULL AND @col <> 'utf8mb4_spanish_ci',
  'ALTER TABLE `fza_traspasos_solicitudes_lineas` '
  'CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 5. Titulos de columna para el formateador (fza_config_campos), usados por
--    el buscador de solicitudes abiertas (frmMtoSolicitudesSearch). Asi no se
--    hardcodean captions: el buscador titula via oConfigCampos. Idempotente
--    (INSERT ... WHERE NOT EXISTS por PK TABLA_OBJETIVO_CC+OBJETIVO_CC).
-- ---------------------------------------------------------------------------
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'NUMERO_TRSOL' AS o, 'Número' AS v,
  90 AS a, 1 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'NUMERO_TRSOL');
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'SERIE_TRSOL' AS o, 'Serie' AS v,
  60 AS a, 2 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'SERIE_TRSOL');
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'FECHA_TRSOL' AS o, 'Fecha' AS v,
  90 AS a, 3 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'FECHA_TRSOL');
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'CODIGO_ALM_DESTINO_TRSOL' AS o,
  'Solicitante' AS v, 110 AS a, 4 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'CODIGO_ALM_DESTINO_TRSOL');
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'ESTADO_TRSOL' AS o, 'Estado' AS v,
  90 AS a, 5 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'ESTADO_TRSOL');
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'LINEAS_PEND_TRSOL' AS o,
  'Líneas pend.' AS v, 90 AS a, 6 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'LINEAS_PEND_TRSOL');
-- Almacen ORIGEN: a quien pedi. Lo usa el historico "Mis peticiones" (F7),
-- donde yo soy el destino. Mismo slot (orden 4) que el Solicitante, ya que
-- nunca aparecen juntos en el mismo buscador.
INSERT INTO `fza_config_campos`
  (`TABLA_OBJETIVO_CC`, `OBJETIVO_CC`, `TITULO_VISUAL_CC`,
   `ANCHO_COLUMNA_CC`, `ORDEN_VISUAL_CC`, `VISIBLE_CC`)
SELECT * FROM (SELECT
  'fza_traspasos_solicitudes' AS t, 'CODIGO_ALM_ORIGEN_TRSOL' AS o,
  'Pedido a' AS v, 110 AS a, 4 AS ord, 'S' AS vis) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_config_campos`
   WHERE TABLA_OBJETIVO_CC = 'fza_traspasos_solicitudes'
     AND OBJETIVO_CC = 'CODIGO_ALM_ORIGEN_TRSOL');

-- ---------------------------------------------------------------------------
-- 6. Perfil del buscador de solicitudes (frmMtoSolicitudesSearch): activar
--    oApplyWidth para que aplique anchos/orden de columna desde el perfil
--    (igual que el resto de buscadores). Se siembra para el grupo 'Todos'.
--    Idempotente (PK USUARIO_GRUPO+KEY+SUBKEY; INSERT ... WHERE NOT EXISTS).
-- ---------------------------------------------------------------------------
INSERT INTO `fza_usuarios_perfiles`
  (`USUARIO_GRUPO_USUPER`, `KEY_USUPER`, `SUBKEY_USUPER`, `VALUE_USUPER`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
SELECT * FROM (SELECT
  'Todos' AS g, 'frmMtoSolicitudesSearch' AS k, 'oApplyWidth' AS s,
  'True' AS v, NOW() AS ia, 'SISTEMA' AS ua, 'SISTEMA' AS um) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_usuarios_perfiles`
   WHERE USUARIO_GRUPO_USUPER = 'Todos'
     AND KEY_USUPER = 'frmMtoSolicitudesSearch'
     AND SUBKEY_USUPER = 'oApplyWidth');
INSERT INTO `fza_usuarios_perfiles`
  (`USUARIO_GRUPO_USUPER`, `KEY_USUPER`, `SUBKEY_USUPER`, `VALUE_USUPER`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
SELECT * FROM (SELECT
  'Todos' AS g, 'frmMtoSolicitudesSearch' AS k,
  'cxGrdDBTabPrin__oApplyWidth' AS s, 'True' AS v, NOW() AS ia,
  'SISTEMA' AS ua, 'SISTEMA' AS um) x
 WHERE NOT EXISTS (SELECT 1 FROM `fza_usuarios_perfiles`
   WHERE USUARIO_GRUPO_USUPER = 'Todos'
     AND KEY_USUPER = 'frmMtoSolicitudesSearch'
     AND SUBKEY_USUPER = 'cxGrdDBTabPrin__oApplyWidth');
