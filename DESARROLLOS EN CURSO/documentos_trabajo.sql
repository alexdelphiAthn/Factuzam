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
  `ESTADO_DTR` varchar(20) NOT NULL DEFAULT 'ABIERTO',
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
  `USUARIO_DTC` varchar(100) NOT NULL,
  `PERMISO_DTC` varchar(20) NOT NULL DEFAULT 'LECTURA',
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`ID_DTC`),
  UNIQUE KEY `UQ_DTC_DTR_USUARIO` (`ID_DTR_DTC`, `USUARIO_DTC`)
);

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
