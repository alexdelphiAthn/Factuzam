-- =============================================================================
-- Catálogo de traducciones de Factuzam
-- =============================================================================
-- Mantiene las traducciones separadas de los perfiles de usuario. CLAVE_TRAD
-- identifica de forma estable un mensaje o una propiedad visual; IDIOMA_TRAD
-- usa una etiqueta de idioma como es-ES o en-GB.
--
-- Idempotente: comprueba por separado la tabla y sus índices.
-- =============================================================================
SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_traducciones'
);
SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE `fza_traducciones` (
     `ID_TRAD` bigint unsigned NOT NULL AUTO_INCREMENT,
     `CLAVE_TRAD` varchar(255) NOT NULL,
     `IDIOMA_TRAD` varchar(20) NOT NULL,
     `TEXTO_TRAD` text NOT NULL,
     `CONTEXTO_TRAD` varchar(500) DEFAULT NULL,
     `ESACTIVO_TRAD` varchar(1) NOT NULL DEFAULT ''S'',
     `INSTANTE_ALTA` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
     `USUARIO_ALTA` varchar(50) NOT NULL,
     `INSTANTE_MODIF` datetime DEFAULT NULL,
     `USUARIO_MODIF` varchar(50) DEFAULT NULL,
     PRIMARY KEY (`ID_TRAD`)
   ) ENGINE=InnoDB
     DEFAULT CHARSET=utf8mb4
     COLLATE=utf8mb4_spanish_ci',
  'SELECT ''fza_traducciones ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_traducciones'
     AND INDEX_NAME = 'UQ_TRAD_CLAVE_IDIOMA'
);
SET @sSql := IF(@sExisteIndice = 0,
  'ALTER TABLE `fza_traducciones`
     ADD UNIQUE INDEX `UQ_TRAD_CLAVE_IDIOMA`
       (`CLAVE_TRAD`, `IDIOMA_TRAD`)',
  'SELECT ''UQ_TRAD_CLAVE_IDIOMA ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_traducciones'
     AND INDEX_NAME = 'IDX_TRAD_IDIOMA_ACTIVO'
);
SET @sSql := IF(@sExisteIndice = 0,
  'ALTER TABLE `fza_traducciones`
     ADD INDEX `IDX_TRAD_IDIOMA_ACTIVO`
       (`IDIOMA_TRAD`, `ESACTIVO_TRAD`)',
  'SELECT ''IDX_TRAD_IDIOMA_ACTIVO ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
