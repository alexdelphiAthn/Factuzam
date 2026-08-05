-- =============================================================================
-- Documento de Trabajo: cabecera + lineas reutilizables
-- =============================================================================
-- Documento operativo no fiscal y sin movimiento de stock. Sirve como bolsa de
-- unidades para preparar etiquetas, inventarios, traspasos o volcar articulos
-- a otros documentos.
-- No toca factuzam_original.sql. Idempotente: se puede ejecutar varias veces.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `fza_documentos_trabajo` (
  `ID_DTR` bigint(20) NOT NULL AUTO_INCREMENT,
  `TITULO_DTR` varchar(200) NOT NULL,
  `TIPO_DTR` varchar(20) NOT NULL DEFAULT 'GENERAL',
  `ESTADO_DTR` varchar(20) NOT NULL DEFAULT 'CREADO',
  `CODIGO_EMP_DTR` varchar(20) DEFAULT NULL,
  `CODIGO_ALM_DTR` varchar(10) DEFAULT NULL,
  `USUARIO_DTR` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `INSTANTE_DOCUMENTO_DTR` datetime NOT NULL,
  `OBSERVACIONES_DTR` text DEFAULT NULL,
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`ID_DTR`)
);

SET @sExisteTitulo := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND COLUMN_NAME = 'TITULO_DTR'
);
SET @sExisteDescripcion := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND COLUMN_NAME = 'DESCRIPCION_DTR'
);
SET @sSql := IF(@sExisteTitulo = 0 AND @sExisteDescripcion > 0,
  'ALTER TABLE fza_documentos_trabajo CHANGE COLUMN DESCRIPCION_DTR TITULO_DTR varchar(200) NOT NULL',
  IF(@sExisteTitulo = 0,
    'ALTER TABLE fza_documentos_trabajo ADD COLUMN TITULO_DTR varchar(200) NOT NULL DEFAULT ''Documento de trabajo'' AFTER ID_DTR',
    'SELECT ''TITULO_DTR ya existe, se omite'' AS info'));
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteEstadoDtr := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND COLUMN_NAME = 'ESTADO_DTR'
);
SET @sSql := IF(@sExisteEstadoDtr = 0,
  'ALTER TABLE fza_documentos_trabajo ADD COLUMN ESTADO_DTR varchar(20) NOT NULL DEFAULT ''CREADO'' AFTER TIPO_DTR',
  'SELECT ''ESTADO_DTR ya existe, se omite el alta'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `fza_documentos_trabajo`
   SET `ESTADO_DTR` = 'CREADO',
       `INSTANTE_MODIF` = `INSTANTE_MODIF`
 WHERE COALESCE(UPPER(TRIM(`ESTADO_DTR`)), '') IN ('', 'ABIERTO');

SET @sEstadoDtrConfigurado := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND COLUMN_NAME = 'ESTADO_DTR'
     AND DATA_TYPE = 'varchar'
     AND CHARACTER_MAXIMUM_LENGTH = 20
     AND IS_NULLABLE = 'NO'
     AND UPPER(REPLACE(COALESCE(COLUMN_DEFAULT, ''), '''', '')) = 'CREADO'
);
SET @sSql := IF(@sEstadoDtrConfigurado = 0,
  'ALTER TABLE fza_documentos_trabajo MODIFY COLUMN ESTADO_DTR varchar(20) NOT NULL DEFAULT ''CREADO''',
  'SELECT ''ESTADO_DTR ya esta configurado, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `fza_documentos_trabajo_lineas` (
  `ID_DTL` bigint(20) NOT NULL AUTO_INCREMENT,
  `ID_DTR_DTL` bigint(20) NOT NULL,
  `LINEA_DTL` varchar(8) NOT NULL,
  `CODIGO_ART_DTL` varchar(20) NOT NULL,
  `CODIGO_UNIDAD_DTL` varchar(50) NOT NULL DEFAULT '',
  `CODIGO_ALM_DTL` varchar(10) DEFAULT NULL,
  `LOTE_DTL` varchar(50) NOT NULL DEFAULT '',
  `FECHA_CADUCIDAD_DTL` date DEFAULT NULL,
  `DESCRIPCION_ARTICULO_DTL` varchar(200) DEFAULT NULL,
  `DESCRIPCION_UNIDAD_DTL` varchar(200) DEFAULT NULL,
  `CANTIDAD_STOCK_DTL` decimal(19,6) NOT NULL DEFAULT 0.000000,
  `CANTIDAD_DTL` decimal(19,6) NOT NULL DEFAULT 0.000000,
  `INSTANTE_STOCK_DTL` datetime NOT NULL,
  `ORIGEN_DTL` varchar(30) DEFAULT NULL,
  `OBSERVACIONES_DTL` varchar(500) DEFAULT NULL,
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`ID_DTL`),
  UNIQUE KEY `UQ_DTL_DTR_LINEA` (`ID_DTR_DTL`, `LINEA_DTL`)
);

CREATE TABLE IF NOT EXISTS `fza_documentos_trabajo_compartidos` (
  `ID_DTC` bigint(20) NOT NULL AUTO_INCREMENT,
  `ID_DTR_DTC` bigint(20) NOT NULL,
  `USUARIO_DTC` varchar(200) NOT NULL,
  `USUARIO_GRUPO_DTC` varchar(200) NOT NULL DEFAULT '',
  `TIPO_DESTINO_DTC` varchar(20) NOT NULL DEFAULT 'USUARIO',
  `PERMISO_DTC` varchar(20) NOT NULL DEFAULT 'LECTURA',
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`ID_DTC`),
  UNIQUE KEY `UQ_DTC_DTR_TIPO_DESTINO_USUARIO_GRUPO`
    (`ID_DTR_DTC`, `TIPO_DESTINO_DTC`, `USUARIO_GRUPO_DTC`)
);

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND INDEX_NAME = 'UQ_DTC_DTR_USUARIO'
);
SET @sSql := IF(@sExisteIdx > 0,
  'ALTER TABLE fza_documentos_trabajo_compartidos DROP INDEX UQ_DTC_DTR_USUARIO',
  'SELECT ''UQ_DTC_DTR_USUARIO no existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sLongUsuarioDtc := (
  SELECT COALESCE(MAX(CHARACTER_MAXIMUM_LENGTH), 0)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND COLUMN_NAME = 'USUARIO_DTC'
);
SET @sSql := IF(@sLongUsuarioDtc < 200,
  'ALTER TABLE fza_documentos_trabajo_compartidos MODIFY COLUMN USUARIO_DTC varchar(200) NOT NULL',
  'SELECT ''USUARIO_DTC ya tiene longitud suficiente, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND COLUMN_NAME = 'USUARIO_GRUPO_DTC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_documentos_trabajo_compartidos ADD COLUMN USUARIO_GRUPO_DTC varchar(200) NOT NULL DEFAULT '''' AFTER USUARIO_DTC',
  'SELECT ''USUARIO_GRUPO_DTC ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND COLUMN_NAME = 'TIPO_DESTINO_DTC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_documentos_trabajo_compartidos ADD COLUMN TIPO_DESTINO_DTC varchar(20) NOT NULL DEFAULT ''USUARIO'' AFTER USUARIO_GRUPO_DTC',
  'SELECT ''TIPO_DESTINO_DTC ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `fza_documentos_trabajo_compartidos`
   SET `USUARIO_GRUPO_DTC` = `USUARIO_DTC`
 WHERE COALESCE(`USUARIO_GRUPO_DTC`, '') = '';

UPDATE `fza_documentos_trabajo_compartidos`
   SET `TIPO_DESTINO_DTC` = 'USUARIO'
 WHERE COALESCE(`TIPO_DESTINO_DTC`, '') = '';

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND INDEX_NAME = 'UQ_DTC_DTR_TIPO_DESTINO_USUARIO_GRUPO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE UNIQUE INDEX UQ_DTC_DTR_TIPO_DESTINO_USUARIO_GRUPO ON fza_documentos_trabajo_compartidos (ID_DTR_DTC, TIPO_DESTINO_DTC, USUARIO_GRUPO_DTC)',
  'SELECT ''UQ_DTC_DTR_TIPO_DESTINO_USUARIO_GRUPO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND INDEX_NAME = 'IDX_DTR_ESTADO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTR_ESTADO ON fza_documentos_trabajo (ESTADO_DTR)',
  'SELECT ''IDX_DTR_ESTADO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND INDEX_NAME = 'IDX_DTR_USUARIO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTR_USUARIO ON fza_documentos_trabajo (USUARIO_DTR)',
  'SELECT ''IDX_DTR_USUARIO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo'
     AND INDEX_NAME = 'IDX_DTR_INSTANTE'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTR_INSTANTE ON fza_documentos_trabajo (INSTANTE_DOCUMENTO_DTR)',
  'SELECT ''IDX_DTR_INSTANTE ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_lineas'
     AND INDEX_NAME = 'IDX_DTL_DTR'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTL_DTR ON fza_documentos_trabajo_lineas (ID_DTR_DTL)',
  'SELECT ''IDX_DTL_DTR ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_lineas'
     AND INDEX_NAME = 'IDX_DTL_UNIDAD'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTL_UNIDAD ON fza_documentos_trabajo_lineas (CODIGO_UNIDAD_DTL)',
  'SELECT ''IDX_DTL_UNIDAD ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_lineas'
     AND INDEX_NAME = 'IDX_DTL_ART'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTL_ART ON fza_documentos_trabajo_lineas (CODIGO_ART_DTL)',
  'SELECT ''IDX_DTL_ART ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_lineas'
     AND INDEX_NAME = 'IDX_DTL_ALM'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTL_ALM ON fza_documentos_trabajo_lineas (CODIGO_ALM_DTL)',
  'SELECT ''IDX_DTL_ALM ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND INDEX_NAME = 'IDX_DTC_USUARIO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTC_USUARIO ON fza_documentos_trabajo_compartidos (USUARIO_DTC)',
  'SELECT ''IDX_DTC_USUARIO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND INDEX_NAME = 'IDX_DTC_TIPO_DESTINO_USUARIO_GRUPO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTC_TIPO_DESTINO_USUARIO_GRUPO ON fza_documentos_trabajo_compartidos (TIPO_DESTINO_DTC, USUARIO_GRUPO_DTC)',
  'SELECT ''IDX_DTC_TIPO_DESTINO_USUARIO_GRUPO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_documentos_trabajo_compartidos'
     AND INDEX_NAME = 'IDX_DTC_DTR'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_DTC_DTR ON fza_documentos_trabajo_compartidos (ID_DTR_DTC)',
  'SELECT ''IDX_DTC_DTR ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT IGNORE INTO `fza_winforms`
  (`CALL_WINF`, `CAPTION_WINF`, `MENUITEM_WINF`, `UNITF_WINF`,
   `SHORTCUT_WINF`, `DATAMODULE_WINF`, `NUM_VENTANAS_WINF`)
VALUES
  ('DocumentosTrabajo', 'Documentos de Trabajo', 'mnuDocumentosTrabajo',
   'inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo', 'Ctrl+W',
   'UniDataDocumentosTrabajo.TdmDocumentosTrabajo', 5);

UPDATE `fza_winforms`
   SET `CAPTION_WINF` = 'Documentos de Trabajo',
       `MENUITEM_WINF` = 'mnuDocumentosTrabajo',
       `UNITF_WINF` = 'inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo',
       `SHORTCUT_WINF` = 'Ctrl+W',
       `DATAMODULE_WINF` = 'UniDataDocumentosTrabajo.TdmDocumentosTrabajo',
       `NUM_VENTANAS_WINF` = 5
 WHERE `CALL_WINF` = 'DocumentosTrabajo'
   AND (COALESCE(`CAPTION_WINF`, '') <> 'Documentos de Trabajo'
        OR COALESCE(`MENUITEM_WINF`, '') <> 'mnuDocumentosTrabajo'
        OR COALESCE(`UNITF_WINF`, '') <>
           'inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo'
        OR COALESCE(`SHORTCUT_WINF`, '') <> 'Ctrl+W'
        OR COALESCE(`DATAMODULE_WINF`, '') <>
           'UniDataDocumentosTrabajo.TdmDocumentosTrabajo'
        OR COALESCE(`NUM_VENTANAS_WINF`, 0) <> 5);

UPDATE `fza_winforms`
   SET `SHORTCUT_WINF` = 'Ctrl+Alt+Shift+P'
 WHERE `CALL_WINF` = 'UsuariosPerfiles'
   AND COALESCE(`SHORTCUT_WINF`, '') <> 'Ctrl+Alt+Shift+P';

INSERT IGNORE INTO `fza_permisos`
  (`USUARIO_GRUPO_PERM`, `CODIGO_PERM`, `VALOR_PERM`, `DESCRIPCION_PERM`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
VALUES
  ('Todos', 'menu.DocumentosTrabajo', 'S', 'Documentos de Trabajo',
   current_timestamp(), 'SISTEMA', 'SISTEMA');
