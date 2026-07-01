-- =============================================================================
-- Filtros guardados de mantenimientos (derivados de inMtoGen)
-- =============================================================================
-- Permite guardar el filtro aplicado en la lista de un mantenimiento con un
-- nombre propio, independiente del layout de columnas (que ya guarda su
-- propio filtro incidental en fza_usuarios_perfiles). Los filtros guardados
-- se listan desde un desplegable junto al icono de exportar a Excel y se
-- pueden asignar a otros usuarios o grupos para que los reutilicen.
-- No toca factuzam_original.sql. Idempotente: se puede ejecutar varias veces.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `fza_filtros_guardados` (
  `ID_FILT` bigint(20) NOT NULL AUTO_INCREMENT,
  -- Identifican el mantenimiento y el grid a los que pertenece el filtro.
  -- MTO_FILT = Self.Name del TfrmMtoXxx (mismo valor que KEY_USUPER en el
  -- layout). VISTA_FILT = Name de la TcxGridDBTableView (misma convencion
  -- que <Vista>_Filtro en fza_usuarios_perfiles).
  `MTO_FILT` varchar(100) NOT NULL,
  `VISTA_FILT` varchar(100) NOT NULL,
  `NOMBRE_FILT` varchar(100) NOT NULL,
  `DESCRIPCION_FILT` varchar(255) DEFAULT NULL,
  -- DataController.Filter.SaveToStream volcado a Base64 en texto, igual que
  -- SUBKEY '<Vista>_Filtro' en fza_usuarios_perfiles (CollectSettingsColumn-
  -- Profile en inLibDevExp.pas). StoreItemLinkNames por defecto en True:
  -- identifica cada condicion por el NOMBRE del item, no por su posicion
  -- visual, asi que sobrevive a que cada usuario tenga las columnas en un
  -- orden distinto.
  `FILTRO_FILT` mediumtext NOT NULL,
  -- FK logica a fza_usuarios.USUARIO_USU. El propietario siempre puede
  -- aplicar, renombrar y borrar su filtro aunque no este compartido.
  `USUARIO_PROPIETARIO_FILT` varchar(100) NOT NULL,
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp()
    ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`ID_FILT`),
  UNIQUE KEY `UQ_FILT_MTO_VISTA_NOMBRE_PROP`
    (`MTO_FILT`, `VISTA_FILT`, `NOMBRE_FILT`, `USUARIO_PROPIETARIO_FILT`)
);

CREATE TABLE IF NOT EXISTS `fza_filtros_guardados_compartidos` (
  `ID_FILTC` bigint(20) NOT NULL AUTO_INCREMENT,
  -- FK logica a fza_filtros_guardados.ID_FILT.
  `ID_FILT_FILTC` bigint(20) NOT NULL,
  -- Usuario o grupo destino segun TIPO_DESTINO_FILTC. Vacio si el destino
  -- es 'TODOS'. Mismo patron que fza_documentos_trabajo_compartidos.
  `USUARIO_GRUPO_FILTC` varchar(200) NOT NULL DEFAULT '',
  -- 'USUARIO' | 'GRUPO' | 'TODOS'.
  `TIPO_DESTINO_FILTC` varchar(20) NOT NULL DEFAULT 'USUARIO',
  `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp()
    ON UPDATE CURRENT_TIMESTAMP,
  `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  `USUARIO_MODIF` varchar(100) NOT NULL DEFAULT 'SISTEMA',
  PRIMARY KEY (`ID_FILTC`),
  UNIQUE KEY `UQ_FILTC_FILT_TIPO_DESTINO`
    (`ID_FILT_FILTC`, `TIPO_DESTINO_FILTC`, `USUARIO_GRUPO_FILTC`)
);

-- -----------------------------------------------------------------------------
-- Indices
-- -----------------------------------------------------------------------------

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_filtros_guardados'
     AND INDEX_NAME = 'IDX_FILT_MTO_VISTA'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_FILT_MTO_VISTA ON fza_filtros_guardados (MTO_FILT, VISTA_FILT)',
  'SELECT ''IDX_FILT_MTO_VISTA ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_filtros_guardados'
     AND INDEX_NAME = 'IDX_FILT_PROPIETARIO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_FILT_PROPIETARIO ON fza_filtros_guardados (USUARIO_PROPIETARIO_FILT)',
  'SELECT ''IDX_FILT_PROPIETARIO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_filtros_guardados_compartidos'
     AND INDEX_NAME = 'IDX_FILTC_FILT'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_FILTC_FILT ON fza_filtros_guardados_compartidos (ID_FILT_FILTC)',
  'SELECT ''IDX_FILTC_FILT ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_filtros_guardados_compartidos'
     AND INDEX_NAME = 'IDX_FILTC_TIPO_DESTINO_USUARIO_GRUPO'
);
SET @sSql := IF(@sExisteIdx = 0,
  'CREATE INDEX IDX_FILTC_TIPO_DESTINO_USUARIO_GRUPO ON fza_filtros_guardados_compartidos (TIPO_DESTINO_FILTC, USUARIO_GRUPO_FILTC)',
  'SELECT ''IDX_FILTC_TIPO_DESTINO_USUARIO_GRUPO ya existe, se omite'' AS info');
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
