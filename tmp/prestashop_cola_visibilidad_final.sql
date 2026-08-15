-- =============================================================================
-- Cola de eventos para sincronizar Factuzam con PrestaShop
-- Aplicacion idempotente sobre el esquema Factuzam existente.
-- =============================================================================
-- Una fila representa el ultimo evento pendiente de un articulo para una
-- instalacion de PrestaShop y una tienda. Los cambios se incorporan en la
-- misma transaccion que modifica precio o stock. Un barrido completo poco
-- frecuente actua solo como red de seguridad ante productores heredados.
--
-- La migracion conserva una cola compatible. Si encuentra una estructura
-- anterior con datos, se detiene para no perderlos. Solo recrea una cola
-- incompatible cuando esta vacia.
-- =============================================================================

-- 1. Proteccion de datos frente a una cola de una version anterior.
SET @sExisteCola := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND TABLE_TYPE = 'BASE TABLE'
);
SET @sColumnasCola := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
);
SET @sColumnasCompatibles := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND COLUMN_NAME IN (
       'ID_PSCOLA',
       'CLAVE_INSTALACION_PSCOLA',
       'ID_TIENDA_PSCOLA',
       'CODIGO_ART_PSCOLA',
       'ESCAMBIO_PRECIO_PSCOLA',
       'ESCAMBIO_STOCK_PSCOLA',
       'ACCION_VISIBILIDAD_PSCOLA',
       'VERSION_DESEADA_PSCOLA',
       'VERSION_RECLAMADA_PSCOLA',
       'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA',
       'ESCAMBIO_STOCK_RECLAMADO_PSCOLA',
       'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA',
       'ESTADO_PSCOLA',
       'CONTADOR_INTENTOS_PSCOLA',
       'INSTANTE_PROXIMO_INTENTO_PSCOLA',
       'ID_RECLAMACION_PSCOLA',
       'INSTANTE_RECLAMACION_PSCOLA',
       'MENSAJE_ERROR_PSCOLA',
       'INSTANTE_ULTIMO_CAMBIO_PSCOLA',
       'INSTANTE_ULTIMO_ENVIO_PSCOLA',
       'INSTANTE_ALTA',
       'USUARIO_ALTA',
       'INSTANTE_MODIF',
       'USUARIO_MODIF'
     )
);
SET @sColumnasBase := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND COLUMN_NAME IN (
       'ID_PSCOLA',
       'CLAVE_INSTALACION_PSCOLA',
       'ID_TIENDA_PSCOLA',
       'CODIGO_ART_PSCOLA',
       'ESCAMBIO_PRECIO_PSCOLA',
       'ESCAMBIO_STOCK_PSCOLA',
       'VERSION_DESEADA_PSCOLA',
       'VERSION_RECLAMADA_PSCOLA',
       'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA',
       'ESCAMBIO_STOCK_RECLAMADO_PSCOLA',
       'ESTADO_PSCOLA',
       'CONTADOR_INTENTOS_PSCOLA',
       'INSTANTE_PROXIMO_INTENTO_PSCOLA',
       'ID_RECLAMACION_PSCOLA',
       'INSTANTE_RECLAMACION_PSCOLA',
       'MENSAJE_ERROR_PSCOLA',
       'INSTANTE_ULTIMO_CAMBIO_PSCOLA',
       'INSTANTE_ULTIMO_ENVIO_PSCOLA',
       'INSTANTE_ALTA',
       'USUARIO_ALTA',
       'INSTANTE_MODIF',
       'USUARIO_MODIF'
     )
);
SET @sColaCompatible := IF(
  @sExisteCola = 0,
  1,
  IF(@sColumnasBase = 22 AND
     @sColumnasCompatibles = @sColumnasCola, 1, 0)
);
SET @sSql := IF(
  @sExisteCola = 1,
  'SELECT COUNT(*) INTO @sFilasCola FROM fza_prestashop_cola',
  'SET @sFilasCola = 0'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sSql := IF(
  @sColaCompatible = 0 AND @sFilasCola > 0,
  'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT =
    ''fza_prestashop_cola tiene un formato anterior y contiene datos; se conserva sin cambios''',
  'SELECT ''Proteccion de datos de fza_prestashop_cola superada'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sSql := IF(
  @sColaCompatible = 0 AND @sFilasCola = 0,
  'DROP TABLE fza_prestashop_cola',
  'SELECT ''No es necesario recrear fza_prestashop_cola'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Marcas opt-in. Una instalacion nueva no publica nada por defecto.
SET @sExisteColumna := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_articulos'
     AND COLUMN_NAME = 'ESWEB_ART'
);
SET @sSql := IF(
  @sExisteColumna = 0,
  'ALTER TABLE fza_articulos
     ADD COLUMN ESWEB_ART varchar(1) NOT NULL DEFAULT ''N''
     AFTER ESACTIVO_ART',
  'SELECT ''ESWEB_ART ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_articulos
   SET ESWEB_ART = 'N'
 WHERE ESWEB_ART IS NULL
    OR ESWEB_ART NOT IN ('S', 'N');
ALTER TABLE fza_articulos
  MODIFY COLUMN ESWEB_ART varchar(1) NOT NULL DEFAULT 'N';
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_articulos'
     AND INDEX_NAME = 'IDX_ART_ESWEB'
);
SET @sSql := IF(
  @sExisteIndice = 0,
  'ALTER TABLE fza_articulos ADD INDEX IDX_ART_ESWEB (ESWEB_ART)',
  'SELECT ''IDX_ART_ESWEB ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteColumna := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_almacenes'
     AND COLUMN_NAME = 'ESWEB_ALM'
);
SET @sSql := IF(
  @sExisteColumna = 0,
  'ALTER TABLE fza_almacenes
     ADD COLUMN ESWEB_ALM varchar(1) NOT NULL DEFAULT ''N''
     AFTER ESFISICO_ALM',
  'SELECT ''ESWEB_ALM ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_almacenes
   SET ESWEB_ALM = 'N'
 WHERE ESWEB_ALM IS NULL
    OR ESWEB_ALM NOT IN ('S', 'N');
ALTER TABLE fza_almacenes
  MODIFY COLUMN ESWEB_ALM varchar(1) NOT NULL DEFAULT 'N';
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_almacenes'
     AND INDEX_NAME = 'IDX_ALM_EMP_WEB'
);
SET @sSql := IF(
  @sExisteIndice = 0,
  'ALTER TABLE fza_almacenes
     ADD INDEX IDX_ALM_EMP_WEB
       (CODIGO_EMP_ALM, ESWEB_ALM, ESACTIVO_ALM,
        ESFISICO_ALM, TIPO_USO_ALM)',
  'SELECT ''IDX_ALM_EMP_WEB ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. Cola de eventos: una fila por instalacion, tienda y articulo.
CREATE TABLE IF NOT EXISTS fza_prestashop_cola (
  ID_PSCOLA bigint(20) NOT NULL AUTO_INCREMENT,
  CLAVE_INSTALACION_PSCOLA char(64) NOT NULL,
  ID_TIENDA_PSCOLA int(11) NOT NULL,
  CODIGO_ART_PSCOLA varchar(20) NOT NULL,
  ESCAMBIO_PRECIO_PSCOLA varchar(1) NOT NULL DEFAULT 'N',
  ESCAMBIO_STOCK_PSCOLA varchar(1) NOT NULL DEFAULT 'N',
  ACCION_VISIBILIDAD_PSCOLA char(1) NOT NULL DEFAULT 'N',
  VERSION_DESEADA_PSCOLA bigint(20) unsigned NOT NULL DEFAULT 1,
  VERSION_RECLAMADA_PSCOLA bigint(20) unsigned NULL DEFAULT NULL,
  ESCAMBIO_PRECIO_RECLAMADO_PSCOLA varchar(1) NOT NULL DEFAULT 'N',
  ESCAMBIO_STOCK_RECLAMADO_PSCOLA varchar(1) NOT NULL DEFAULT 'N',
  ACCION_VISIBILIDAD_RECLAMADA_PSCOLA char(1) NOT NULL DEFAULT 'N',
  ESTADO_PSCOLA varchar(30) NOT NULL DEFAULT 'PENDIENTE',
  CONTADOR_INTENTOS_PSCOLA int(11) NOT NULL DEFAULT 0,
  INSTANTE_PROXIMO_INTENTO_PSCOLA datetime NULL DEFAULT NULL,
  ID_RECLAMACION_PSCOLA char(36) NULL DEFAULT NULL,
  INSTANTE_RECLAMACION_PSCOLA datetime NULL DEFAULT NULL,
  MENSAJE_ERROR_PSCOLA text NULL DEFAULT NULL,
  INSTANTE_ULTIMO_CAMBIO_PSCOLA datetime NOT NULL,
  INSTANTE_ULTIMO_ENVIO_PSCOLA datetime NULL DEFAULT NULL,
  INSTANTE_ALTA datetime NOT NULL,
  USUARIO_ALTA varchar(50) NULL DEFAULT NULL,
  INSTANTE_MODIF datetime NULL DEFAULT NULL,
  USUARIO_MODIF varchar(50) NULL DEFAULT NULL,
  PRIMARY KEY (ID_PSCOLA)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_spanish_ci;
SET @sExisteColumna := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND COLUMN_NAME = 'ACCION_VISIBILIDAD_PSCOLA'
);
SET @sSql := IF(
  @sExisteColumna = 0,
  'ALTER TABLE fza_prestashop_cola
     ADD COLUMN ACCION_VISIBILIDAD_PSCOLA char(1) NOT NULL DEFAULT ''N''
     AFTER ESCAMBIO_STOCK_PSCOLA',
  'SELECT ''ACCION_VISIBILIDAD_PSCOLA ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteColumna := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND COLUMN_NAME = 'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA'
);
SET @sSql := IF(
  @sExisteColumna = 0,
  'ALTER TABLE fza_prestashop_cola
     ADD COLUMN ACCION_VISIBILIDAD_RECLAMADA_PSCOLA char(1)
       NOT NULL DEFAULT ''N''
     AFTER ESCAMBIO_STOCK_RECLAMADO_PSCOLA',
  'SELECT ''ACCION_VISIBILIDAD_RECLAMADA_PSCOLA ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
UPDATE fza_prestashop_cola
   SET ACCION_VISIBILIDAD_PSCOLA = 'N'
 WHERE ACCION_VISIBILIDAD_PSCOLA IS NULL
    OR ACCION_VISIBILIDAD_PSCOLA NOT IN ('N', 'A', 'D');
UPDATE fza_prestashop_cola
   SET ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = 'N'
 WHERE ACCION_VISIBILIDAD_RECLAMADA_PSCOLA IS NULL
    OR ACCION_VISIBILIDAD_RECLAMADA_PSCOLA NOT IN ('N', 'A', 'D');
ALTER TABLE fza_prestashop_cola
  MODIFY COLUMN ACCION_VISIBILIDAD_PSCOLA char(1)
    NOT NULL DEFAULT 'N' AFTER ESCAMBIO_STOCK_PSCOLA,
  MODIFY COLUMN ACCION_VISIBILIDAD_RECLAMADA_PSCOLA char(1)
    NOT NULL DEFAULT 'N' AFTER ESCAMBIO_STOCK_RECLAMADO_PSCOLA,
  MODIFY COLUMN ESTADO_PSCOLA varchar(30)
    NOT NULL DEFAULT 'PENDIENTE';
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND INDEX_NAME = 'UQ_PSCOLA_INST_TIENDA_ART'
);
SET @sSql := IF(
  @sExisteIndice = 0,
  'ALTER TABLE fza_prestashop_cola
     ADD UNIQUE INDEX UQ_PSCOLA_INST_TIENDA_ART
       (CLAVE_INSTALACION_PSCOLA, ID_TIENDA_PSCOLA,
        CODIGO_ART_PSCOLA)',
  'SELECT ''UQ_PSCOLA_INST_TIENDA_ART ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND INDEX_NAME = 'IDX_PSCOLA_INST_TIENDA_PEND'
);
SET @sSql := IF(
  @sExisteIndice = 0,
  'ALTER TABLE fza_prestashop_cola
     ADD INDEX IDX_PSCOLA_INST_TIENDA_PEND
       (CLAVE_INSTALACION_PSCOLA, ID_TIENDA_PSCOLA, ESTADO_PSCOLA,
        INSTANTE_PROXIMO_INTENTO_PSCOLA, ID_PSCOLA)',
  'SELECT ''IDX_PSCOLA_INST_TIENDA_PEND ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND INDEX_NAME = 'IDX_PSCOLA_INST_TIENDA_LEASE'
);
SET @sSql := IF(
  @sExisteIndice = 0,
  'ALTER TABLE fza_prestashop_cola
     ADD INDEX IDX_PSCOLA_INST_TIENDA_LEASE
       (CLAVE_INSTALACION_PSCOLA, ID_TIENDA_PSCOLA, ESTADO_PSCOLA,
        INSTANTE_RECLAMACION_PSCOLA)',
  'SELECT ''IDX_PSCOLA_INST_TIENDA_LEASE ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteIndice := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_prestashop_cola'
     AND INDEX_NAME = 'IDX_PSCOLA_RECLAMACION'
);
SET @sSql := IF(
  @sExisteIndice = 0,
  'ALTER TABLE fza_prestashop_cola
     ADD INDEX IDX_PSCOLA_RECLAMACION (ID_RECLAMACION_PSCOLA)',
  'SELECT ''IDX_PSCOLA_RECLAMACION ya existe'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. Motor set-based. Cada alta recibe el destino ya resuelto.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_TEMP_DESTINO(
  IN p_CLAVE_INSTALACION char(64),
  IN p_ID_TIENDA int,
  IN p_ES_PRECIO varchar(1),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200)
)
BEGIN
  DECLARE v_es_precio varchar(1) DEFAULT 'N';
  DECLARE v_es_stock varchar(1) DEFAULT 'N';
  DECLARE v_usuario varchar(50);
  SET v_es_precio = IF(UPPER(TRIM(p_ES_PRECIO)) = 'S', 'S', 'N');
  SET v_es_stock = IF(UPPER(TRIM(p_ES_STOCK)) = 'S', 'S', 'N');
  SET v_usuario = LEFT(COALESCE(NULLIF(TRIM(p_USUARIO), ''),
    'PRESTASHOP'), 50);
  IF NULLIF(TRIM(p_CLAVE_INSTALACION), '') IS NOT NULL AND
     p_ID_TIENDA > 0 AND
     (v_es_precio = 'S' OR v_es_stock = 'S') THEN
    INSERT INTO fza_prestashop_cola (
      CLAVE_INSTALACION_PSCOLA,
      ID_TIENDA_PSCOLA,
      CODIGO_ART_PSCOLA,
      ESCAMBIO_PRECIO_PSCOLA,
      ESCAMBIO_STOCK_PSCOLA,
      VERSION_DESEADA_PSCOLA,
      ESTADO_PSCOLA,
      CONTADOR_INTENTOS_PSCOLA,
      INSTANTE_ULTIMO_CAMBIO_PSCOLA,
      INSTANTE_ALTA,
      USUARIO_ALTA
    )
    SELECT UPPER(TRIM(p_CLAVE_INSTALACION)),
           p_ID_TIENDA,
           T.codigo_art,
           v_es_precio,
           v_es_stock,
           1,
           'PENDIENTE',
           0,
           NOW(),
           NOW(),
           v_usuario
      FROM tmp_prestashop_encolar_articulos T
      JOIN fza_articulos A
        ON A.CODIGO_ART_ART = T.codigo_art
       AND A.ESWEB_ART = 'S'
    ON DUPLICATE KEY UPDATE
      ESCAMBIO_PRECIO_PSCOLA = IF(
        ESCAMBIO_PRECIO_PSCOLA = 'S' OR
        VALUES(ESCAMBIO_PRECIO_PSCOLA) = 'S', 'S', 'N'),
      ESCAMBIO_STOCK_PSCOLA = IF(
        ESCAMBIO_STOCK_PSCOLA = 'S' OR
        VALUES(ESCAMBIO_STOCK_PSCOLA) = 'S', 'S', 'N'),
      VERSION_DESEADA_PSCOLA = VERSION_DESEADA_PSCOLA + 1,
      CONTADOR_INTENTOS_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        CONTADOR_INTENTOS_PSCOLA, 0),
      INSTANTE_PROXIMO_INTENTO_PSCOLA = NULL,
      MENSAJE_ERROR_PSCOLA = IF(
        LEFT(COALESCE(MENSAJE_ERROR_PSCOLA, ''), 18) =
          '[ALTA_PRESTASHOP] ',
        MENSAJE_ERROR_PSCOLA, NULL),
      VERSION_RECLAMADA_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        VERSION_RECLAMADA_PSCOLA, NULL),
      ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ESCAMBIO_PRECIO_RECLAMADO_PSCOLA, 'N'),
      ESCAMBIO_STOCK_RECLAMADO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ESCAMBIO_STOCK_RECLAMADO_PSCOLA, 'N'),
      ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ACCION_VISIBILIDAD_RECLAMADA_PSCOLA, 'N'),
      ID_RECLAMACION_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ID_RECLAMACION_PSCOLA, NULL),
      INSTANTE_RECLAMACION_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        INSTANTE_RECLAMACION_PSCOLA, NULL),
      ESTADO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        IF(ESTADO_PSCOLA = 'PROCESANDO_VISIBILIDAD' OR
           ACCION_VISIBILIDAD_PSCOLA IN ('A', 'D'),
          'PROCESANDO_VISIBILIDAD', 'PROCESANDO'),
        IF(ACCION_VISIBILIDAD_PSCOLA IN ('A', 'D'),
          'PENDIENTE_VISIBILIDAD', 'PENDIENTE')),
      INSTANTE_ULTIMO_CAMBIO_PSCOLA = NOW(),
      INSTANTE_MODIF = NOW(),
      USUARIO_MODIF = v_usuario;
  END IF;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_TEMP(
  IN p_ES_PRECIO varchar(1),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200),
  IN p_CODIGO_ALM_EVENTO varchar(10)
)
BEGIN
  DECLARE v_url varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_tienda_texto varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_sincronizar_texto varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_crear_texto varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_empresa varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_tarifa varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_api_key varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_empresa_evento varchar(20) COLLATE utf8mb4_spanish_ci;
  DECLARE v_grupo varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_clave char(64);
  DECLARE v_tienda int DEFAULT 1;
  DECLARE v_es_usuario varchar(1) DEFAULT 'N';
  DECLARE v_peticion_precio varchar(1) DEFAULT 'N';
  DECLARE v_peticion_stock varchar(1) DEFAULT 'N';
  DECLARE v_sincronizar varchar(1) DEFAULT 'N';
  DECLARE v_crear varchar(1) DEFAULT 'N';
  DECLARE v_es_precio varchar(1) DEFAULT 'N';
  DECLARE v_es_stock varchar(1) DEFAULT 'N';
  DECLARE v_usuario_perfil varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_usuario_auditoria varchar(50) COLLATE utf8mb4_spanish_ci;
  SET v_usuario_perfil = TRIM(COALESCE(p_USUARIO, ''));
  SET v_usuario_auditoria = LEFT(COALESCE(
    NULLIF(TRIM(p_USUARIO), ''), 'PRESTASHOP'), 50);
  SELECT MAX(U.GRUPO_USU), IF(COUNT(*) > 0, 'S', 'N')
    INTO v_grupo, v_es_usuario
    FROM fza_usuarios U
   WHERE U.USUARIO_USU = v_usuario_perfil
     COLLATE utf8mb4_spanish_ci
     AND U.ESACTIVO_USU = 'S';
  IF v_es_usuario <> 'S' THEN
    SET v_usuario_perfil = '';
    SET v_grupo = '';
  END IF;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER = 'appPrestaShopUrl'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), '')
    INTO v_url;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER = 'appPrestaShopApiKey'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), '')
    INTO v_api_key;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER = 'appPrestaShopIdTienda'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), '1')
    INTO v_tienda_texto;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER =
         'appPrestaShopSincronizarStockPrecios'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), 'False')
    INTO v_sincronizar_texto;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER = 'appPrestaShopCrearArticulos'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), 'False')
    INTO v_crear_texto;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER = 'appPrestaShopEmpresa'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), '1')
    INTO v_empresa;
  SELECT COALESCE((
    SELECT TRIM(P.VALUE_USUPER)
      FROM fza_usuarios_perfiles P
     WHERE P.KEY_USUPER = 'frmMtoAppParam'
       AND P.SUBKEY_USUPER = 'appPrestaShopTarifa'
       AND (P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci OR
         (v_es_usuario = 'S' AND
          (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
             COLLATE utf8mb4_spanish_ci OR
           P.USUARIO_GRUPO_USUPER = v_grupo
             COLLATE utf8mb4_spanish_ci)))
     ORDER BY CASE P.USUARIO_GRUPO_USUPER
       WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
       WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
       ELSE 3 END
     LIMIT 1), 'PVP')
    INTO v_tarifa;
  SET v_url = TRIM(TRAILING '/' FROM TRIM(v_url));
  IF TRIM(v_tienda_texto) REGEXP '^[+-]?[0-9]+$' AND
     LENGTH(TRIM(v_tienda_texto)) <= 11 AND
     CAST(TRIM(v_tienda_texto) AS signed)
       BETWEEN -2147483648 AND 2147483647 THEN
    SET v_tienda = CAST(TRIM(v_tienda_texto) AS signed);
  END IF;
  SET v_clave = UPPER(SHA2(v_url, 256));
  SET v_peticion_precio = IF(
    UPPER(TRIM(p_ES_PRECIO)) = 'S', 'S', 'N');
  SET v_peticion_stock = IF(
    UPPER(TRIM(p_ES_STOCK)) = 'S', 'S', 'N');
  SET v_sincronizar = IF(
    UPPER(TRIM(v_sincronizar_texto)) IN ('TRUE', '1', 'S'), 'S', 'N');
  SET v_crear = IF(
    UPPER(TRIM(v_crear_texto)) IN ('TRUE', '1', 'S'), 'S', 'N');
  SET v_es_precio = IF(
    (v_sincronizar = 'S' AND v_peticion_precio = 'S') OR
    (v_crear = 'S' AND
     (v_peticion_precio = 'S' OR v_peticion_stock = 'S')),
    'S', 'N');
  SET v_es_stock = IF(
    v_sincronizar = 'S' AND v_peticion_stock = 'S', 'S', 'N');
  SET v_empresa_evento = '';
  IF NULLIF(TRIM(p_CODIGO_ALM_EVENTO), '') IS NOT NULL THEN
    SELECT MAX(A.CODIGO_EMP_ALM)
      INTO v_empresa_evento
      FROM fza_almacenes A
     WHERE A.CODIGO_ALM_ALM =
       TRIM(p_CODIGO_ALM_EVENTO) COLLATE utf8mb4_spanish_ci;
  END IF;
  UPDATE fza_prestashop_cola C
  JOIN tmp_prestashop_encolar_articulos T
    ON T.codigo_art = C.CODIGO_ART_PSCOLA
  LEFT JOIN fza_articulos A
    ON A.CODIGO_ART_ART = T.codigo_art
     SET C.ESCAMBIO_PRECIO_PSCOLA = 'N',
         C.ESCAMBIO_STOCK_PSCOLA = 'N',
         C.VERSION_DESEADA_PSCOLA = C.VERSION_DESEADA_PSCOLA + 1,
         C.VERSION_RECLAMADA_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.VERSION_RECLAMADA_PSCOLA, NULL),
         C.ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.ESCAMBIO_PRECIO_RECLAMADO_PSCOLA, 'N'),
         C.ESCAMBIO_STOCK_RECLAMADO_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.ESCAMBIO_STOCK_RECLAMADO_PSCOLA, 'N'),
         C.ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.ACCION_VISIBILIDAD_RECLAMADA_PSCOLA, 'N'),
         C.CONTADOR_INTENTOS_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.CONTADOR_INTENTOS_PSCOLA, 0),
         C.INSTANTE_PROXIMO_INTENTO_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.INSTANTE_PROXIMO_INTENTO_PSCOLA, NULL),
         C.ID_RECLAMACION_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.ID_RECLAMACION_PSCOLA, NULL),
         C.INSTANTE_RECLAMACION_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.INSTANTE_RECLAMACION_PSCOLA, NULL),
         C.MENSAJE_ERROR_PSCOLA = IF(
           LEFT(COALESCE(C.MENSAJE_ERROR_PSCOLA, ''), 18) =
             '[ALTA_PRESTASHOP] ',
           C.MENSAJE_ERROR_PSCOLA, NULL),
         C.ESTADO_PSCOLA = IF(
           C.ESTADO_PSCOLA IN
             ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
           C.ESTADO_PSCOLA, 'ENVIADA'),
         C.INSTANTE_ULTIMO_CAMBIO_PSCOLA = NOW(),
         C.INSTANTE_MODIF = NOW(),
         C.USUARIO_MODIF = v_usuario_auditoria
   WHERE ((v_peticion_precio = 'N' AND v_peticion_stock = 'N')
      OR COALESCE(A.ESWEB_ART, 'N') <> 'S')
     AND C.ACCION_VISIBILIDAD_PSCOLA = 'N';
  IF (v_es_precio = 'S' OR v_es_stock = 'S') AND
     NULLIF(v_url, '') IS NOT NULL AND
     NULLIF(TRIM(v_api_key), '') IS NOT NULL AND
     NULLIF(TRIM(v_empresa), '') IS NOT NULL AND
     NULLIF(TRIM(v_tarifa), '') IS NOT NULL AND
     v_tienda > 0 AND
     (NULLIF(TRIM(p_CODIGO_ALM_EVENTO), '') IS NULL OR
      UPPER(TRIM(v_empresa_evento)) = UPPER(TRIM(v_empresa))) THEN
    CALL PRC_PRESTASHOP_ENCOLAR_TEMP_DESTINO(
      v_clave,
      v_tienda,
      v_es_precio,
      v_es_stock,
      v_usuario_auditoria);
  END IF;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_VISIBILIDAD(
  IN p_CODIGO_ART varchar(20),
  IN p_ACCION varchar(1),
  IN p_USUARIO varchar(200)
)
BEGIN
  DECLARE v_accion char(1);
  DECLARE v_api_key varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_cancelacion_local char(1) DEFAULT 'N';
  DECLARE v_clave char(64);
  DECLARE v_codigo_art varchar(20) COLLATE utf8mb4_spanish_ci;
  DECLARE v_crear char(1) DEFAULT 'N';
  DECLARE v_crear_texto varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_empresa varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_es_precio char(1) DEFAULT 'N';
  DECLARE v_es_stock char(1) DEFAULT 'N';
  DECLARE v_es_usuario char(1) DEFAULT 'N';
  DECLARE v_esweb char(1) DEFAULT 'N';
  DECLARE v_existe_articulo int DEFAULT 0;
  DECLARE v_grupo varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_sincronizar char(1) DEFAULT 'N';
  DECLARE v_sincronizar_texto varchar(200)
    COLLATE utf8mb4_spanish_ci;
  DECLARE v_tarifa varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_tienda int DEFAULT 1;
  DECLARE v_tienda_texto varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_url varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_usuario_auditoria varchar(50)
    COLLATE utf8mb4_spanish_ci;
  DECLARE v_usuario_perfil varchar(200) COLLATE utf8mb4_spanish_ci;

  SET v_codigo_art = NULLIF(TRIM(p_CODIGO_ART), '');
  SET v_accion = UPPER(TRIM(COALESCE(p_ACCION, 'N')));
  IF v_codigo_art IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT =
        'La visibilidad PrestaShop no identifica el articulo';
  END IF;
  IF v_accion NOT IN ('N', 'A', 'D') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Accion de visibilidad PrestaShop no valida';
  END IF;

  SELECT COUNT(*), COALESCE(MAX(A.ESWEB_ART), 'N')
    INTO v_existe_articulo, v_esweb
    FROM fza_articulos A
   WHERE A.CODIGO_ART_ART = v_codigo_art;
  IF v_existe_articulo = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No existe el articulo indicado para PrestaShop';
  END IF;
  IF v_esweb = 'S' AND v_accion = 'D' THEN
    SET v_accion = 'N';
  END IF;
  IF v_esweb <> 'S' AND v_accion = 'A' THEN
    SET v_accion = 'N';
  END IF;
  IF v_esweb <> 'S' AND v_accion = 'N' THEN
    SET v_cancelacion_local = 'S';
    UPDATE fza_prestashop_cola
       SET ESCAMBIO_PRECIO_PSCOLA = 'N',
           ESCAMBIO_STOCK_PSCOLA = 'N',
           ACCION_VISIBILIDAD_PSCOLA = 'N',
           VERSION_DESEADA_PSCOLA = VERSION_DESEADA_PSCOLA + 1,
           VERSION_RECLAMADA_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             VERSION_RECLAMADA_PSCOLA, NULL),
           ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             ESCAMBIO_PRECIO_RECLAMADO_PSCOLA, 'N'),
           ESCAMBIO_STOCK_RECLAMADO_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             ESCAMBIO_STOCK_RECLAMADO_PSCOLA, 'N'),
           ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             ACCION_VISIBILIDAD_RECLAMADA_PSCOLA, 'N'),
           CONTADOR_INTENTOS_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             CONTADOR_INTENTOS_PSCOLA, 0),
           INSTANTE_PROXIMO_INTENTO_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             INSTANTE_PROXIMO_INTENTO_PSCOLA, NULL),
           ID_RECLAMACION_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             ID_RECLAMACION_PSCOLA, NULL),
           INSTANTE_RECLAMACION_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             INSTANTE_RECLAMACION_PSCOLA, NULL),
           MENSAJE_ERROR_PSCOLA = IF(
             LEFT(COALESCE(MENSAJE_ERROR_PSCOLA, ''), 18) =
               '[ALTA_PRESTASHOP] ',
             MENSAJE_ERROR_PSCOLA, NULL),
           ESTADO_PSCOLA = IF(
             ESTADO_PSCOLA IN
               ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
             ESTADO_PSCOLA, 'ENVIADA'),
           INSTANTE_ULTIMO_CAMBIO_PSCOLA = NOW(),
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = LEFT(COALESCE(
             NULLIF(TRIM(p_USUARIO), ''), 'PRESTASHOP'), 50)
     WHERE CODIGO_ART_PSCOLA = v_codigo_art;
  END IF;

  SET v_usuario_perfil = TRIM(COALESCE(p_USUARIO, ''));
  SET v_usuario_auditoria = LEFT(COALESCE(
    NULLIF(v_usuario_perfil, ''), 'PRESTASHOP'), 50);
  SELECT MAX(U.GRUPO_USU), IF(COUNT(*) > 0, 'S', 'N')
    INTO v_grupo, v_es_usuario
    FROM fza_usuarios U
   WHERE U.USUARIO_USU = v_usuario_perfil
     COLLATE utf8mb4_spanish_ci
     AND U.ESACTIVO_USU = 'S';
  IF v_es_usuario <> 'S' THEN
    SET v_usuario_perfil = '';
    SET v_grupo = '';
  END IF;

  SELECT
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER = 'appPrestaShopUrl'
      AND R.RN = 1 THEN TRIM(R.VALUE_USUPER) END), ''),
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER = 'appPrestaShopApiKey'
      AND R.RN = 1 THEN TRIM(R.VALUE_USUPER) END), ''),
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER = 'appPrestaShopIdTienda'
      AND R.RN = 1 THEN TRIM(R.VALUE_USUPER) END), '1'),
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER =
      'appPrestaShopSincronizarStockPrecios' AND R.RN = 1
      THEN TRIM(R.VALUE_USUPER) END), 'False'),
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER =
      'appPrestaShopCrearArticulos' AND R.RN = 1
      THEN TRIM(R.VALUE_USUPER) END), 'False'),
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER = 'appPrestaShopEmpresa'
      AND R.RN = 1 THEN TRIM(R.VALUE_USUPER) END), '1'),
    COALESCE(MAX(CASE WHEN R.SUBKEY_USUPER = 'appPrestaShopTarifa'
      AND R.RN = 1 THEN TRIM(R.VALUE_USUPER) END), 'PVP')
    INTO v_url, v_api_key, v_tienda_texto,
         v_sincronizar_texto, v_crear_texto, v_empresa, v_tarifa
    FROM (
      SELECT P.SUBKEY_USUPER, P.VALUE_USUPER,
             ROW_NUMBER() OVER (
               PARTITION BY P.SUBKEY_USUPER
               ORDER BY CASE P.USUARIO_GRUPO_USUPER
                 WHEN v_usuario_perfil COLLATE utf8mb4_spanish_ci THEN 1
                 WHEN v_grupo COLLATE utf8mb4_spanish_ci THEN 2
                 ELSE 3 END) AS RN
        FROM fza_usuarios_perfiles P
       WHERE P.KEY_USUPER = 'frmMtoAppParam'
         AND P.SUBKEY_USUPER IN (
           'appPrestaShopUrl',
           'appPrestaShopApiKey',
           'appPrestaShopIdTienda',
           'appPrestaShopSincronizarStockPrecios',
           'appPrestaShopCrearArticulos',
           'appPrestaShopEmpresa',
           'appPrestaShopTarifa')
         AND (P.USUARIO_GRUPO_USUPER =
                'Todos' COLLATE utf8mb4_spanish_ci OR
           (v_es_usuario = 'S' AND
            (P.USUARIO_GRUPO_USUPER = v_usuario_perfil
               COLLATE utf8mb4_spanish_ci OR
             P.USUARIO_GRUPO_USUPER = v_grupo
               COLLATE utf8mb4_spanish_ci)))
    ) R;

  SET v_url = TRIM(TRAILING '/' FROM TRIM(v_url));
  IF TRIM(v_tienda_texto) REGEXP '^[+]?[0-9]+$' AND
     LENGTH(TRIM(v_tienda_texto)) <= 10 AND
     CAST(TRIM(v_tienda_texto) AS unsigned) <= 2147483647 THEN
    SET v_tienda = CAST(TRIM(v_tienda_texto) AS signed);
  ELSE
    SET v_tienda = 0;
  END IF;
  SET v_sincronizar = IF(
    UPPER(TRIM(v_sincronizar_texto)) IN ('TRUE', '1', 'S'),
    'S', 'N');
  SET v_crear = IF(
    UPPER(TRIM(v_crear_texto)) IN ('TRUE', '1', 'S'),
    'S', 'N');
  IF v_esweb = 'S' THEN
    SET v_es_precio = IF(
      v_sincronizar = 'S' OR
      (v_accion <> 'A' AND v_crear = 'S'), 'S', 'N');
    SET v_es_stock = IF(v_sincronizar = 'S', 'S', 'N');
  ELSE
    SET v_es_precio = 'N';
    SET v_es_stock = 'N';
  END IF;

  IF v_cancelacion_local = 'N' AND v_accion IN ('A', 'D') AND
     (NULLIF(v_url, '') IS NULL OR v_tienda <= 0) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT =
        'Faltan URL o tienda para cambiar la visibilidad PrestaShop';
  END IF;

  IF v_cancelacion_local = 'N' AND
     NULLIF(v_url, '') IS NOT NULL AND
     v_tienda > 0 THEN
    SET v_clave = UPPER(SHA2(v_url, 256));
    INSERT INTO fza_prestashop_cola (
      CLAVE_INSTALACION_PSCOLA,
      ID_TIENDA_PSCOLA,
      CODIGO_ART_PSCOLA,
      ESCAMBIO_PRECIO_PSCOLA,
      ESCAMBIO_STOCK_PSCOLA,
      ACCION_VISIBILIDAD_PSCOLA,
      VERSION_DESEADA_PSCOLA,
      ESTADO_PSCOLA,
      CONTADOR_INTENTOS_PSCOLA,
      INSTANTE_ULTIMO_CAMBIO_PSCOLA,
      INSTANTE_ALTA,
      USUARIO_ALTA
    ) VALUES (
      v_clave,
      v_tienda,
      v_codigo_art,
      v_es_precio,
      v_es_stock,
      v_accion,
      1,
      CASE WHEN v_accion IN ('A', 'D')
        THEN 'PENDIENTE_VISIBILIDAD'
        WHEN v_es_precio = 'S' OR v_es_stock = 'S'
        THEN 'PENDIENTE' ELSE 'ENVIADA' END,
      0,
      NOW(),
      NOW(),
      v_usuario_auditoria
    )
    ON DUPLICATE KEY UPDATE
      ESCAMBIO_PRECIO_PSCOLA = VALUES(ESCAMBIO_PRECIO_PSCOLA),
      ESCAMBIO_STOCK_PSCOLA = VALUES(ESCAMBIO_STOCK_PSCOLA),
      ACCION_VISIBILIDAD_PSCOLA = VALUES(ACCION_VISIBILIDAD_PSCOLA),
      VERSION_DESEADA_PSCOLA = VERSION_DESEADA_PSCOLA + 1,
      CONTADOR_INTENTOS_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        CONTADOR_INTENTOS_PSCOLA, 0),
      INSTANTE_PROXIMO_INTENTO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        INSTANTE_PROXIMO_INTENTO_PSCOLA, NULL),
      MENSAJE_ERROR_PSCOLA = IF(
        LEFT(COALESCE(MENSAJE_ERROR_PSCOLA, ''), 18) =
          '[ALTA_PRESTASHOP] ',
        MENSAJE_ERROR_PSCOLA, NULL),
      VERSION_RECLAMADA_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        VERSION_RECLAMADA_PSCOLA, NULL),
      ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ESCAMBIO_PRECIO_RECLAMADO_PSCOLA, 'N'),
      ESCAMBIO_STOCK_RECLAMADO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ESCAMBIO_STOCK_RECLAMADO_PSCOLA, 'N'),
      ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ACCION_VISIBILIDAD_RECLAMADA_PSCOLA, 'N'),
      ID_RECLAMACION_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        ID_RECLAMACION_PSCOLA, NULL),
      INSTANTE_RECLAMACION_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        INSTANTE_RECLAMACION_PSCOLA, NULL),
      ESTADO_PSCOLA = IF(
        ESTADO_PSCOLA IN ('PROCESANDO', 'PROCESANDO_VISIBILIDAD'),
        IF(ESTADO_PSCOLA = 'PROCESANDO_VISIBILIDAD' OR
           VALUES(ACCION_VISIBILIDAD_PSCOLA) IN ('A', 'D'),
          'PROCESANDO_VISIBILIDAD', 'PROCESANDO'),
        CASE WHEN VALUES(ACCION_VISIBILIDAD_PSCOLA) IN ('A', 'D')
          THEN 'PENDIENTE_VISIBILIDAD'
          WHEN VALUES(ESCAMBIO_PRECIO_PSCOLA) = 'S' OR
               VALUES(ESCAMBIO_STOCK_PSCOLA) = 'S'
          THEN 'PENDIENTE' ELSE 'ENVIADA' END),
      INSTANTE_ULTIMO_CAMBIO_PSCOLA = NOW(),
      INSTANTE_MODIF = NOW(),
      USUARIO_MODIF = v_usuario_auditoria;
  END IF;
END ;;
DELIMITER ;

-- 5. Contratos publicos para cambios concretos y operaciones masivas.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_CAMBIO(
  IN p_CODIGO_ART varchar(20),
  IN p_CODIGO_UNIDAD varchar(50),
  IN p_ES_PRECIO varchar(1),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200)
)
BEGIN
  DECLARE v_codigo_art varchar(20) COLLATE utf8mb4_spanish_ci;
  SET v_codigo_art = NULLIF(TRIM(p_CODIGO_ART), '');
  IF v_codigo_art IS NULL AND
     NULLIF(TRIM(p_CODIGO_UNIDAD), '') IS NOT NULL THEN
    SELECT S.CODIGO_ART_SKU
      INTO v_codigo_art
      FROM fza_articulos_skus S
     WHERE S.CODIGO_UNIDAD_SKU = TRIM(p_CODIGO_UNIDAD)
     LIMIT 1;
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
  CREATE TEMPORARY TABLE tmp_prestashop_encolar_articulos (
    codigo_art varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (codigo_art)
  ) ENGINE=InnoDB;
  IF v_codigo_art IS NOT NULL THEN
    INSERT IGNORE INTO tmp_prestashop_encolar_articulos (codigo_art)
    VALUES (v_codigo_art);
  END IF;
  CALL PRC_PRESTASHOP_ENCOLAR_TEMP(
    p_ES_PRECIO, p_ES_STOCK, p_USUARIO, '');
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_CAMBIO_ALMACEN(
  IN p_CODIGO_ART varchar(20),
  IN p_CODIGO_UNIDAD varchar(50),
  IN p_ES_PRECIO varchar(1),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200),
  IN p_CODIGO_ALM varchar(10)
)
BEGIN
  DECLARE v_codigo_art varchar(20) COLLATE utf8mb4_spanish_ci;
  SET v_codigo_art = NULLIF(TRIM(p_CODIGO_ART), '');
  IF v_codigo_art IS NULL AND
     NULLIF(TRIM(p_CODIGO_UNIDAD), '') IS NOT NULL THEN
    SELECT S.CODIGO_ART_SKU
      INTO v_codigo_art
      FROM fza_articulos_skus S
     WHERE S.CODIGO_UNIDAD_SKU = TRIM(p_CODIGO_UNIDAD)
     LIMIT 1;
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
  CREATE TEMPORARY TABLE tmp_prestashop_encolar_articulos (
    codigo_art varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (codigo_art)
  ) ENGINE=InnoDB;
  IF v_codigo_art IS NOT NULL THEN
    INSERT IGNORE INTO tmp_prestashop_encolar_articulos (codigo_art)
    VALUES (v_codigo_art);
  END IF;
  CALL PRC_PRESTASHOP_ENCOLAR_TEMP(
    p_ES_PRECIO, p_ES_STOCK, p_USUARIO, p_CODIGO_ALM);
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_TODOS_WEB(
  IN p_ES_PRECIO varchar(1),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200)
)
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
  CREATE TEMPORARY TABLE tmp_prestashop_encolar_articulos (
    codigo_art varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (codigo_art)
  ) ENGINE=InnoDB;
  INSERT IGNORE INTO tmp_prestashop_encolar_articulos (codigo_art)
  SELECT A.CODIGO_ART_ART
    FROM fza_articulos A
   WHERE A.ESWEB_ART = 'S';
  CALL PRC_PRESTASHOP_ENCOLAR_TEMP(
    p_ES_PRECIO, p_ES_STOCK, p_USUARIO, '');
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_TODOS_WEB_DESTINO(
  IN p_CLAVE_INSTALACION char(64),
  IN p_ID_TIENDA int,
  IN p_ES_PRECIO varchar(1),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200)
)
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
  CREATE TEMPORARY TABLE tmp_prestashop_encolar_articulos (
    codigo_art varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (codigo_art)
  ) ENGINE=InnoDB;
  INSERT IGNORE INTO tmp_prestashop_encolar_articulos (codigo_art)
  SELECT A.CODIGO_ART_ART
    FROM fza_articulos A
   WHERE A.ESWEB_ART = 'S';
  CALL PRC_PRESTASHOP_ENCOLAR_TEMP_DESTINO(
    p_CLAVE_INSTALACION,
    p_ID_TIENDA,
    p_ES_PRECIO,
    p_ES_STOCK,
    p_USUARIO);
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_STOCK_ALMACEN(
  IN p_CODIGO_ALM varchar(10),
  IN p_USUARIO varchar(200)
)
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
  CREATE TEMPORARY TABLE tmp_prestashop_encolar_articulos (
    codigo_art varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (codigo_art)
  ) ENGINE=InnoDB;
  INSERT IGNORE INTO tmp_prestashop_encolar_articulos (codigo_art)
  SELECT A.CODIGO_ART_ART
    FROM fza_articulos_stockactual STK
    LEFT JOIN fza_articulos_skus S
      ON S.CODIGO_UNIDAD_SKU = STK.CODIGO_UNIDAD_STK
    JOIN fza_articulos A
      ON A.CODIGO_ART_ART = COALESCE(
        S.CODIGO_ART_SKU, STK.CODIGO_UNIDAD_STK)
     AND A.ESWEB_ART = 'S'
   WHERE STK.CODIGO_ALM_STK = p_CODIGO_ALM;
  CALL PRC_PRESTASHOP_ENCOLAR_TEMP(
    'N', 'S', p_USUARIO, p_CODIGO_ALM);
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_ENCOLAR_STOCK_RECALCULO(
  IN p_USUARIO varchar(200)
)
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
  CREATE TEMPORARY TABLE tmp_prestashop_encolar_articulos (
    codigo_art varchar(20) COLLATE utf8mb4_spanish_ci NOT NULL,
    PRIMARY KEY (codigo_art)
  ) ENGINE=InnoDB;
  INSERT IGNORE INTO tmp_prestashop_encolar_articulos (codigo_art)
  SELECT A.CODIGO_ART_ART
    FROM tmp_recalculo_final R
    JOIN fza_almacenes ALM
      ON ALM.CODIGO_ALM_ALM = R.almacen
     AND ALM.ESWEB_ALM = 'S'
     AND ALM.ESACTIVO_ALM = 'S'
     AND ALM.ESFISICO_ALM = 'S'
     AND UPPER(TRIM(ALM.TIPO_USO_ALM)) = 'ESTANDAR'
    LEFT JOIN fza_articulos_skus S
      ON S.CODIGO_UNIDAD_SKU = R.sku
    JOIN fza_articulos A
      ON A.CODIGO_ART_ART = COALESCE(S.CODIGO_ART_SKU, R.sku)
     AND A.ESWEB_ART = 'S';
  CALL PRC_PRESTASHOP_ENCOLAR_TEMP('N', 'S', p_USUARIO, '');
  DROP TEMPORARY TABLE IF EXISTS tmp_prestashop_encolar_articulos;
END ;;
DELIMITER ;


-- 6. Escritor directo de acumulados de stock.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_FZA_AJUSTAR_ACUMULADO_STK(
  IN p_TIPO_DOC_MOV varchar(20),
  IN p_TIPO_MOV varchar(1),
  IN p_CODIGO_ALM varchar(10),
  IN p_CODIGO_UNIDAD varchar(50),
  IN p_CANTIDAD decimal(19,6),
  IN p_VALOR decimal(19,6),
  IN p_MULT int
)
BEGIN
  DECLARE v_signo int;
  DECLARE v_filas int DEFAULT 0;
  SET v_signo = IF(p_TIPO_MOV = 'E', 1, -1);
  UPDATE fza_articulos_stockactual
     SET CANTIDAD_STK = CANTIDAD_STK +
           (v_signo * p_MULT * p_CANTIDAD),
         VALOR_TOTAL_STK = VALOR_TOTAL_STK +
           (v_signo * p_MULT * p_VALOR),
         PRECIO_MEDIO_STK = IF(
           CANTIDAD_STK > 0, VALOR_TOTAL_STK / CANTIDAD_STK, 0),
         INSTANTE_MODIF = NOW(),
         CANTIDAD_ENT_COMPRA_STK = CANTIDAD_ENT_COMPRA_STK +
           IF(p_TIPO_DOC_MOV = 'AC' AND p_TIPO_MOV = 'E',
             p_MULT * p_CANTIDAD, 0),
         CANTIDAD_ENT_TRASPASO_STK = CANTIDAD_ENT_TRASPASO_STK +
           IF(p_TIPO_DOC_MOV IN ('TR', 'AT', 'TA') AND
             p_TIPO_MOV = 'E', p_MULT * p_CANTIDAD, 0),
         CANTIDAD_SAL_TRASPASO_STK = CANTIDAD_SAL_TRASPASO_STK +
           IF(p_TIPO_DOC_MOV IN ('TR', 'AT', 'TA') AND
             p_TIPO_MOV = 'S', p_MULT * p_CANTIDAD, 0),
         CANTIDAD_ENT_DEPOSITO_STK = CANTIDAD_ENT_DEPOSITO_STK +
           IF(p_TIPO_DOC_MOV = 'DP' AND p_TIPO_MOV = 'E',
             p_MULT * p_CANTIDAD, 0),
         CANTIDAD_SAL_DEPOSITO_STK = CANTIDAD_SAL_DEPOSITO_STK +
           IF(p_TIPO_DOC_MOV = 'DP' AND p_TIPO_MOV = 'S',
             p_MULT * p_CANTIDAD, 0),
         CANTIDAD_SAL_VENTA_STK = CANTIDAD_SAL_VENTA_STK +
           IF(p_TIPO_DOC_MOV IN ('VE', 'FC') AND p_TIPO_MOV = 'S',
             p_MULT * p_CANTIDAD, 0),
         CANTIDAD_ENT_REGULAR_STK = CANTIDAD_ENT_REGULAR_STK +
           IF(p_TIPO_DOC_MOV = 'IN' AND p_TIPO_MOV = 'E',
             p_MULT * p_CANTIDAD, 0),
         CANTIDAD_SAL_ALBVENTA_STK = CANTIDAD_SAL_ALBVENTA_STK +
           IF(p_TIPO_DOC_MOV = 'AV' AND p_TIPO_MOV = 'S',
             p_MULT * p_CANTIDAD, 0),
         CANTIDAD_ENT_ALBENTRADA_STK = CANTIDAD_ENT_ALBENTRADA_STK +
           IF(p_TIPO_DOC_MOV = 'AE' AND p_TIPO_MOV = 'E',
             p_MULT * p_CANTIDAD, 0)
   WHERE CODIGO_ALM_STK = p_CODIGO_ALM
     AND CODIGO_UNIDAD_STK = p_CODIGO_UNIDAD;
  SET v_filas = ROW_COUNT();
  IF v_filas > 0 AND EXISTS (
    SELECT 1
      FROM fza_almacenes ALM
     WHERE ALM.CODIGO_ALM_ALM = p_CODIGO_ALM
       AND ALM.ESWEB_ALM = 'S'
       AND ALM.ESACTIVO_ALM = 'S'
       AND ALM.ESFISICO_ALM = 'S'
       AND UPPER(TRIM(ALM.TIPO_USO_ALM)) = 'ESTANDAR'
  ) THEN
    CALL PRC_PRESTASHOP_ENCOLAR_CAMBIO_ALMACEN(
      '', p_CODIGO_UNIDAD, 'N', 'S', '', p_CODIGO_ALM);
  END IF;
END ;;
DELIMITER ;

-- 7. Alta central de movimientos y actualizacion incremental de stock.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(
  IN p_NUMERO_MOV varchar(20),
  IN p_TIPO_DOC_MOV varchar(20),
  IN p_SERIE_DOC_MOV varchar(20),
  IN p_NRO_DOC_MOV varchar(20),
  IN p_LINEA_MOV varchar(10),
  IN p_CODIGO_EMPRESA_MOV varchar(20),
  IN p_CODIGO_ALMACEN_MOV varchar(10),
  IN p_CODIGO_ALMACEN_CONTRA_MOV varchar(10),
  IN p_CODIGO_UNIDAD_MOV varchar(50),
  IN p_TIPO_MOVIMIENTO_MOV varchar(1),
  IN p_CANTIDAD_MOV decimal(19,6),
  IN p_PRECIO_MEDIO_MOV decimal(19,6),
  IN p_TOTAL_COSTE_MOV decimal(19,6),
  IN p_USUARIO varchar(200),
  IN p_ALMACEN_DOC varchar(10),
  IN p_NUMOP_DOC varchar(20),
  IN p_CODIGO_CAJA_DOC_MOV varchar(10),
  IN p_CODCLIENTE varchar(20),
  IN p_CODARTICULO varchar(20)
)
BEGIN
  DECLARE v_PMPActual decimal(19,6) DEFAULT 0;
  DECLARE v_PrecioFinal decimal(19,6);
  DECLARE v_CosteFinal decimal(19,6);
  DECLARE v_dEntCompra decimal(19,6) DEFAULT 0;
  DECLARE v_dEntTraspaso decimal(19,6) DEFAULT 0;
  DECLARE v_dSalTraspaso decimal(19,6) DEFAULT 0;
  DECLARE v_dEntDeposito decimal(19,6) DEFAULT 0;
  DECLARE v_dSalDeposito decimal(19,6) DEFAULT 0;
  DECLARE v_dSalVenta decimal(19,6) DEFAULT 0;
  DECLARE v_dEntRegular decimal(19,6) DEFAULT 0;
  DECLARE v_dSalAlbVenta decimal(19,6) DEFAULT 0;
  DECLARE v_dEntAlbEntrada decimal(19,6) DEFAULT 0;
  SELECT IFNULL(PRECIO_MEDIO_STK, 0)
    INTO v_PMPActual
    FROM fza_articulos_stockactual
   WHERE CODIGO_ALM_STK = p_CODIGO_ALMACEN_MOV
     AND CODIGO_UNIDAD_STK = p_CODIGO_UNIDAD_MOV
   LIMIT 1;
  IF p_TIPO_MOVIMIENTO_MOV = 'S' THEN
    SET v_PrecioFinal = v_PMPActual;
    SET v_CosteFinal = p_CANTIDAD_MOV * v_PMPActual;
  ELSE
    SET v_PrecioFinal = p_PRECIO_MEDIO_MOV;
    SET v_CosteFinal = p_TOTAL_COSTE_MOV;
  END IF;
  IF p_TIPO_DOC_MOV = 'AC' AND p_TIPO_MOVIMIENTO_MOV = 'E' THEN
    SET v_dEntCompra = p_CANTIDAD_MOV;
  ELSEIF p_TIPO_DOC_MOV IN ('TR', 'AT', 'TA') THEN
    IF p_TIPO_MOVIMIENTO_MOV = 'E' THEN
      SET v_dEntTraspaso = p_CANTIDAD_MOV;
    ELSE
      SET v_dSalTraspaso = p_CANTIDAD_MOV;
    END IF;
  ELSEIF p_TIPO_DOC_MOV = 'DP' THEN
    IF p_TIPO_MOVIMIENTO_MOV = 'E' THEN
      SET v_dEntDeposito = p_CANTIDAD_MOV;
    ELSE
      SET v_dSalDeposito = p_CANTIDAD_MOV;
    END IF;
  ELSEIF p_TIPO_DOC_MOV IN ('VE', 'FC') AND
         p_TIPO_MOVIMIENTO_MOV = 'S' THEN
    SET v_dSalVenta = p_CANTIDAD_MOV;
  ELSEIF p_TIPO_DOC_MOV = 'IN' AND
         p_TIPO_MOVIMIENTO_MOV = 'E' THEN
    SET v_dEntRegular = p_CANTIDAD_MOV;
  ELSEIF p_TIPO_DOC_MOV = 'AV' AND
         p_TIPO_MOVIMIENTO_MOV = 'S' THEN
    SET v_dSalAlbVenta = p_CANTIDAD_MOV;
  ELSEIF p_TIPO_DOC_MOV = 'AE' AND
         p_TIPO_MOVIMIENTO_MOV = 'E' THEN
    SET v_dEntAlbEntrada = p_CANTIDAD_MOV;
  END IF;
  INSERT INTO fza_movimientos_almacen (
    NUMERO_MOV,
    TIPO_DOC_MOV,
    SERIE_DOC_MOV,
    NUMERO_DOC_MOV,
    LINEA_MOV,
    CODIGO_EMP_MOV,
    CODIGO_ALM_MOV,
    CODIGO_ALM_CONTRA_MOV,
    CODIGO_UNIDAD_MOV,
    TIPO_MOV,
    CANTIDAD_MOV,
    PRECIO_COSTE_UNITARIO_MOV,
    PRECIO_MEDIO_MOV,
    TOTAL_COSTE_MOV,
    FECHA_MOV,
    USUARIO_ALTA,
    USUARIO_MODIF,
    CODIGO_ALM_DOC_MOV,
    NUMERO_OPERACION_DOC_MOV,
    CODIGO_CAJA_DOC_MOV,
    CODIGO_CLI_MOV,
    CODIGO_ART_MOV
  ) VALUES (
    p_NUMERO_MOV,
    p_TIPO_DOC_MOV,
    p_SERIE_DOC_MOV,
    p_NRO_DOC_MOV,
    p_LINEA_MOV,
    p_CODIGO_EMPRESA_MOV,
    p_CODIGO_ALMACEN_MOV,
    p_CODIGO_ALMACEN_CONTRA_MOV,
    p_CODIGO_UNIDAD_MOV,
    p_TIPO_MOVIMIENTO_MOV,
    p_CANTIDAD_MOV,
    v_PrecioFinal,
    v_PrecioFinal,
    v_CosteFinal,
    NOW(),
    p_USUARIO,
    p_USUARIO,
    p_ALMACEN_DOC,
    p_NUMOP_DOC,
    p_CODIGO_CAJA_DOC_MOV,
    p_CODCLIENTE,
    p_CODARTICULO
  );
  INSERT INTO fza_articulos_stockactual (
    CODIGO_ALM_STK,
    CODIGO_UNIDAD_STK,
    CANTIDAD_STK,
    VALOR_TOTAL_STK,
    PRECIO_MEDIO_STK,
    INSTANTE_MODIF,
    CANTIDAD_ENT_COMPRA_STK,
    CANTIDAD_ENT_TRASPASO_STK,
    CANTIDAD_SAL_TRASPASO_STK,
    CANTIDAD_ENT_DEPOSITO_STK,
    CANTIDAD_SAL_DEPOSITO_STK,
    CANTIDAD_SAL_VENTA_STK,
    CANTIDAD_ENT_REGULAR_STK,
    CANTIDAD_SAL_ALBVENTA_STK,
    CANTIDAD_ENT_ALBENTRADA_STK
  ) VALUES (
    p_CODIGO_ALMACEN_MOV,
    p_CODIGO_UNIDAD_MOV,
    IF(p_TIPO_MOVIMIENTO_MOV = 'E',
      p_CANTIDAD_MOV, -p_CANTIDAD_MOV),
    IF(p_TIPO_MOVIMIENTO_MOV = 'E', v_CosteFinal, -v_CosteFinal),
    v_PrecioFinal,
    NOW(),
    v_dEntCompra,
    v_dEntTraspaso,
    v_dSalTraspaso,
    v_dEntDeposito,
    v_dSalDeposito,
    v_dSalVenta,
    v_dEntRegular,
    v_dSalAlbVenta,
    v_dEntAlbEntrada
  )
  ON DUPLICATE KEY UPDATE
    CANTIDAD_STK = CANTIDAD_STK + VALUES(CANTIDAD_STK),
    VALOR_TOTAL_STK = VALOR_TOTAL_STK + VALUES(VALOR_TOTAL_STK),
    PRECIO_MEDIO_STK = IF(
      CANTIDAD_STK > 0, VALOR_TOTAL_STK / CANTIDAD_STK, 0),
    INSTANTE_MODIF = NOW(),
    CANTIDAD_ENT_COMPRA_STK = CANTIDAD_ENT_COMPRA_STK +
      VALUES(CANTIDAD_ENT_COMPRA_STK),
    CANTIDAD_ENT_TRASPASO_STK = CANTIDAD_ENT_TRASPASO_STK +
      VALUES(CANTIDAD_ENT_TRASPASO_STK),
    CANTIDAD_SAL_TRASPASO_STK = CANTIDAD_SAL_TRASPASO_STK +
      VALUES(CANTIDAD_SAL_TRASPASO_STK),
    CANTIDAD_ENT_DEPOSITO_STK = CANTIDAD_ENT_DEPOSITO_STK +
      VALUES(CANTIDAD_ENT_DEPOSITO_STK),
    CANTIDAD_SAL_DEPOSITO_STK = CANTIDAD_SAL_DEPOSITO_STK +
      VALUES(CANTIDAD_SAL_DEPOSITO_STK),
    CANTIDAD_SAL_VENTA_STK = CANTIDAD_SAL_VENTA_STK +
      VALUES(CANTIDAD_SAL_VENTA_STK),
    CANTIDAD_ENT_REGULAR_STK = CANTIDAD_ENT_REGULAR_STK +
      VALUES(CANTIDAD_ENT_REGULAR_STK),
    CANTIDAD_SAL_ALBVENTA_STK = CANTIDAD_SAL_ALBVENTA_STK +
      VALUES(CANTIDAD_SAL_ALBVENTA_STK),
    CANTIDAD_ENT_ALBENTRADA_STK = CANTIDAD_ENT_ALBENTRADA_STK +
      VALUES(CANTIDAD_ENT_ALBENTRADA_STK);
  IF EXISTS (
    SELECT 1
      FROM fza_almacenes ALM
     WHERE ALM.CODIGO_ALM_ALM = p_CODIGO_ALMACEN_MOV
       AND ALM.ESWEB_ALM = 'S'
       AND ALM.ESACTIVO_ALM = 'S'
       AND ALM.ESFISICO_ALM = 'S'
       AND UPPER(TRIM(ALM.TIPO_USO_ALM)) = 'ESTANDAR'
  ) THEN
    CALL PRC_PRESTASHOP_ENCOLAR_CAMBIO_ALMACEN(
      p_CODARTICULO,
      p_CODIGO_UNIDAD_MOV,
      'N',
      'S',
      p_USUARIO,
      p_CODIGO_ALMACEN_MOV);
  END IF;
END ;;
DELIMITER ;

-- 8. Escritura set-based del recalculo cronologico de movimientos.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_FZA_MOVIMIENTOS_RECALCULO_ACTUALIZAR_STOCK()
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_final;
  CREATE TEMPORARY TABLE tmp_recalculo_final (
    almacen varchar(10) NOT NULL,
    sku varchar(50) NOT NULL,
    stock_final decimal(19,6) NOT NULL,
    pmp_final decimal(19,6) NOT NULL,
    PRIMARY KEY (almacen, sku)
  ) ENGINE=InnoDB;
  INSERT INTO tmp_recalculo_final (
    almacen,
    sku,
    stock_final,
    pmp_final
  )
  SELECT S.almacen,
         S.sku,
         IFNULL(O.stock_nuevo, S.stock_semilla),
         IFNULL(O.pmp_nuevo, S.pmp_semilla)
    FROM tmp_recalculo_semillas S
    LEFT JOIN (
      SELECT X.almacen,
             X.sku,
             X.stock_nuevo,
             X.pmp_nuevo
        FROM tmp_movimientos_ordenados X
        JOIN (
          SELECT almacen,
                 sku,
                 MAX(rn) AS rn
            FROM tmp_movimientos_ordenados
           GROUP BY almacen, sku
        ) U ON U.rn = X.rn
    ) O ON O.almacen = S.almacen
       AND O.sku = S.sku;
  INSERT INTO fza_articulos_stockactual (
    CODIGO_ALM_STK,
    CODIGO_UNIDAD_STK,
    CANTIDAD_STK,
    VALOR_TOTAL_STK,
    PRECIO_MEDIO_STK,
    INSTANTE_MODIF,
    CANTIDAD_ENT_COMPRA_STK,
    CANTIDAD_ENT_TRASPASO_STK,
    CANTIDAD_SAL_TRASPASO_STK,
    CANTIDAD_ENT_DEPOSITO_STK,
    CANTIDAD_SAL_DEPOSITO_STK,
    CANTIDAD_SAL_VENTA_STK,
    CANTIDAD_ENT_REGULAR_STK,
    CANTIDAD_SAL_ALBVENTA_STK,
    CANTIDAD_ENT_ALBENTRADA_STK
  )
  SELECT F.almacen,
         F.sku,
         F.stock_final,
         IF(F.stock_final > 0, F.stock_final * F.pmp_final, 0),
         IF(F.stock_final > 0, F.pmp_final, 0),
         NOW(),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV = 'AC' AND M.TIPO_MOV = 'E',
           M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV IN ('TR', 'AT', 'TA') AND
           M.TIPO_MOV = 'E', M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV IN ('TR', 'AT', 'TA') AND
           M.TIPO_MOV = 'S', M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV = 'DP' AND M.TIPO_MOV = 'E',
           M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV = 'DP' AND M.TIPO_MOV = 'S',
           M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV IN ('VE', 'FC') AND
           M.TIPO_MOV = 'S', M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV = 'IN' AND M.TIPO_MOV = 'E',
           M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV = 'AV' AND M.TIPO_MOV = 'S',
           M.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(M.TIPO_DOC_MOV = 'AE' AND M.TIPO_MOV = 'E',
           M.CANTIDAD_MOV, 0)), 0)
    FROM tmp_recalculo_final F
    LEFT JOIN fza_movimientos_almacen M
      ON M.CODIGO_ALM_MOV = F.almacen
     AND M.CODIGO_UNIDAD_MOV = F.sku
     AND M.ESACTIVO_MOV = 'S'
   GROUP BY F.almacen, F.sku, F.stock_final, F.pmp_final
  ON DUPLICATE KEY UPDATE
    CANTIDAD_STK = VALUES(CANTIDAD_STK),
    VALOR_TOTAL_STK = VALUES(VALOR_TOTAL_STK),
    PRECIO_MEDIO_STK = VALUES(PRECIO_MEDIO_STK),
    INSTANTE_MODIF = NOW(),
    CANTIDAD_ENT_COMPRA_STK = VALUES(CANTIDAD_ENT_COMPRA_STK),
    CANTIDAD_ENT_TRASPASO_STK = VALUES(CANTIDAD_ENT_TRASPASO_STK),
    CANTIDAD_SAL_TRASPASO_STK = VALUES(CANTIDAD_SAL_TRASPASO_STK),
    CANTIDAD_ENT_DEPOSITO_STK = VALUES(CANTIDAD_ENT_DEPOSITO_STK),
    CANTIDAD_SAL_DEPOSITO_STK = VALUES(CANTIDAD_SAL_DEPOSITO_STK),
    CANTIDAD_SAL_VENTA_STK = VALUES(CANTIDAD_SAL_VENTA_STK),
    CANTIDAD_ENT_REGULAR_STK = VALUES(CANTIDAD_ENT_REGULAR_STK),
    CANTIDAD_SAL_ALBVENTA_STK = VALUES(CANTIDAD_SAL_ALBVENTA_STK),
    CANTIDAD_ENT_ALBENTRADA_STK = VALUES(CANTIDAD_ENT_ALBENTRADA_STK);
  CALL PRC_PRESTASHOP_ENCOLAR_STOCK_RECALCULO('');
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_final;
  DROP TEMPORARY TABLE IF EXISTS tmp_movimientos_ordenados;
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_semillas;
END ;;
DELIMITER ;

-- 9. Recalculo completo explicito. No se ejecuta periodicamente.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_RECALCULAR_STOCK()
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  bloque_error: BEGIN
    ROLLBACK;
    SELECT 'ERROR: No se pudo recalcular el stock' AS MENSAJE;
  END bloque_error;
  START TRANSACTION;
  DELETE FROM fza_articulos_stockactual;
  INSERT INTO fza_articulos_stockactual (
    CODIGO_ALM_STK,
    CODIGO_UNIDAD_STK,
    CANTIDAD_STK,
    INSTANTE_MODIF
  )
  SELECT CODIGO_ALM_MOV,
         CODIGO_UNIDAD_MOV,
         SUM(IF(TIPO_MOV = 'E', CANTIDAD_MOV, -CANTIDAD_MOV)),
         NOW()
    FROM fza_movimientos_almacen
   WHERE ESACTIVO_MOV = 'S'
   GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV;
  CALL PRC_PRESTASHOP_ENCOLAR_TODOS_WEB(
    'N', 'S', '');
  COMMIT;
  SELECT 'Stock recalculado correctamente.' AS MENSAJE;
END ;;
DELIMITER ;

-- 10. Reclamacion coordinada del consumidor de recuperacion.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_RECLAMAR_RECUPERACION(
  IN p_SEGUNDOS int,
  IN p_CLAVE_INSTALACION char(64),
  IN p_TIENDA int,
  IN p_USUARIO varchar(200),
  OUT p_RECLAMADA tinyint
)
BEGIN
  DECLARE v_segundos int DEFAULT 60;
  DECLARE v_proxima bigint unsigned DEFAULT 0;
  DECLARE v_usuario varchar(100) COLLATE utf8mb4_spanish_ci;
  DECLARE v_clave char(64);
  DECLARE v_tienda int;
  DECLARE v_subclave varchar(100) COLLATE utf8mb4_spanish_ci;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RECLAMADA = 0;
    RESIGNAL;
  END;
  SET p_RECLAMADA = 0;
  SET v_segundos = LEAST(120, GREATEST(60, COALESCE(p_SEGUNDOS, 60)));
  SET v_clave = UPPER(TRIM(COALESCE(p_CLAVE_INSTALACION, '')));
  SET v_tienda = COALESCE(p_TIENDA, 0);
  IF v_clave = '' OR v_tienda <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT =
        'Destino PrestaShop incompleto para recuperar la cola';
  END IF;
  SET v_usuario = LEFT(COALESCE(NULLIF(TRIM(p_USUARIO), ''),
    'PRESTASHOP'), 100);
  SET v_subclave = CONCAT(
    'RECUPERACION_',
    UPPER(SHA2(CONCAT(v_clave, '|', v_tienda), 256)));
  START TRANSACTION;
  INSERT IGNORE INTO fza_usuarios_perfiles (
    USUARIO_GRUPO_USUPER,
    KEY_USUPER,
    SUBKEY_USUPER,
    VALUE_USUPER,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  ) VALUES (
    'Todos',
    'dmPrestaShopCola',
    v_subclave,
    '0',
    NOW(),
    NOW(),
    v_usuario,
    v_usuario
  );
  SELECT CAST(COALESCE(NULLIF(P.VALUE_USUPER, ''), '0') AS unsigned)
    INTO v_proxima
    FROM fza_usuarios_perfiles P
   WHERE P.USUARIO_GRUPO_USUPER =
           'Todos' COLLATE utf8mb4_spanish_ci
     AND P.KEY_USUPER =
           'dmPrestaShopCola' COLLATE utf8mb4_spanish_ci
     AND P.SUBKEY_USUPER =
           v_subclave COLLATE utf8mb4_spanish_ci
   FOR UPDATE;
  IF v_proxima <= UNIX_TIMESTAMP() THEN
    UPDATE fza_usuarios_perfiles P
       SET P.VALUE_USUPER = CAST(UNIX_TIMESTAMP() + v_segundos AS char),
           P.INSTANTE_MODIF = NOW(),
           P.USUARIO_MODIF = v_usuario
     WHERE P.USUARIO_GRUPO_USUPER =
             'Todos' COLLATE utf8mb4_spanish_ci
       AND P.KEY_USUPER =
             'dmPrestaShopCola' COLLATE utf8mb4_spanish_ci
       AND P.SUBKEY_USUPER =
             v_subclave COLLATE utf8mb4_spanish_ci;
    SET p_RECLAMADA = 1;
  END IF;
  COMMIT;
END ;;
DELIMITER ;

-- 11. Reconciliacion ocasional coordinada entre todos los terminales.
DELIMITER ;;
CREATE OR REPLACE PROCEDURE PRC_PRESTASHOP_RECONCILIAR(
  IN p_HORAS int,
  IN p_CLAVE_INSTALACION char(64),
  IN p_ID_TIENDA int,
  IN p_CODIGO_EMPRESA varchar(20),
  IN p_CODIGO_TARIFA varchar(20),
  IN p_ES_STOCK varchar(1),
  IN p_USUARIO varchar(200)
)
BEGIN
  DECLARE v_horas int DEFAULT 24;
  DECLARE v_ultimo bigint unsigned DEFAULT 0;
  DECLARE v_usuario varchar(50) COLLATE utf8mb4_spanish_ci;
  DECLARE v_empresa varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_tarifa varchar(200) COLLATE utf8mb4_spanish_ci;
  DECLARE v_clave char(64);
  DECLARE v_tienda int;
  DECLARE v_es_stock varchar(1) DEFAULT 'N';
  DECLARE v_subclave varchar(100) COLLATE utf8mb4_spanish_ci;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  IF p_HORAS BETWEEN 1 AND 720 THEN
    SET v_horas = p_HORAS;
  END IF;
  SET v_clave = UPPER(TRIM(p_CLAVE_INSTALACION));
  SET v_tienda = p_ID_TIENDA;
  SET v_empresa = TRIM(COALESCE(p_CODIGO_EMPRESA, ''));
  SET v_tarifa = TRIM(COALESCE(p_CODIGO_TARIFA, ''));
  IF v_clave = '' OR v_tienda <= 0 OR
     v_empresa = '' OR v_tarifa = '' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT =
        'Destino PrestaShop incompleto para el barrido';
  END IF;
  SET v_es_stock = IF(UPPER(TRIM(p_ES_STOCK)) = 'S', 'S', 'N');
  SET v_subclave = CONCAT(
    'ULTIMO_BARRIDO_',
    UPPER(SHA2(CONCAT(
      v_clave, '|', v_tienda, '|', v_empresa, '|', v_tarifa, '|',
      v_es_stock), 256)));
  SET v_usuario = LEFT(COALESCE(NULLIF(TRIM(p_USUARIO), ''),
    'PRESTASHOP'), 50);
  START TRANSACTION;
  INSERT IGNORE INTO fza_usuarios_perfiles (
    USUARIO_GRUPO_USUPER,
    KEY_USUPER,
    SUBKEY_USUPER,
    VALUE_USUPER,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  ) VALUES (
    'Todos',
    'dmPrestaShopCola',
    v_subclave,
    '0',
    NOW(),
    NOW(),
    v_usuario,
    v_usuario
  );
  SELECT CAST(COALESCE(NULLIF(P.VALUE_USUPER, ''), '0') AS unsigned)
    INTO v_ultimo
     FROM fza_usuarios_perfiles P
    WHERE P.USUARIO_GRUPO_USUPER =
            'Todos' COLLATE utf8mb4_spanish_ci
      AND P.KEY_USUPER =
            'dmPrestaShopCola' COLLATE utf8mb4_spanish_ci
      AND P.SUBKEY_USUPER =
            v_subclave COLLATE utf8mb4_spanish_ci
   FOR UPDATE;
  IF v_ultimo <= UNIX_TIMESTAMP() - (v_horas * 3600) THEN
    UPDATE fza_usuarios_perfiles P
       SET P.VALUE_USUPER = CAST(UNIX_TIMESTAMP() AS char),
           P.INSTANTE_MODIF = NOW(),
           P.USUARIO_MODIF = v_usuario
      WHERE P.USUARIO_GRUPO_USUPER =
              'Todos' COLLATE utf8mb4_spanish_ci
        AND P.KEY_USUPER =
              'dmPrestaShopCola' COLLATE utf8mb4_spanish_ci
        AND P.SUBKEY_USUPER =
              v_subclave COLLATE utf8mb4_spanish_ci;
    CALL PRC_PRESTASHOP_ENCOLAR_TODOS_WEB_DESTINO(
      v_clave,
      v_tienda,
      'S',
      v_es_stock,
      v_usuario);
  END IF;
  COMMIT;
END ;;
DELIMITER ;

-- 12. Vista de articulos: se conserva el contrato y se expone ESWEB_ART.
CREATE OR REPLACE VIEW vi_articulos AS
SELECT
  ART.CODIGO_ART_ART AS CODIGO_ART_ART,
  ART.ESACTIVO_ART AS ESACTIVO_ART,
  ART.ESWEB_ART AS ESWEB_ART,
  ART.ORDEN_ART AS ORDEN_ART,
  ART.DESCRIPCION_ART AS DESCRIPCION_ART,
  ART.ESVARIACION_ART AS ESVARIACION_ART,
  ART.ESTRAZABLE_ART AS ESTRAZABLE_ART,
  ART.TIPO_ART AS TIPO_ART,
  ART.TIPO_VARIACION_ART AS TIPO_VARIACION_ART,
  ART.CODIGO_FAM_ART AS CODIGO_FAM_ART,
  FAM.DESCRIPCION_FAM AS DESCRIPCION_FAM,
  FAM.NOMBRE_FAM_FAM AS NOMBRE_FAM_FAM,
  ART.TIPO_IVA_ART AS TIPO_IVA_ART,
  IVA.NOMBRE_TIPO_IVA_IVATIP AS NOMBRE_TIPO_IVA_IVATIP,
  ART.ESACTIVO_FIJO_ART AS ESACTIVO_FIJO_ART,
  ART.TIPO_CANTIDAD_ART AS TIPO_CANTIDAD_ART,
  AP.CODIGO_PRV_AP AS CODIGO_PRV_AP,
  PRV.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV,
  PRV.NOMBRE_PRV AS NOMBRE_PRV,
  AP.REF_PROVEEDOR_AP AS REF_PROVEEDOR,
  COALESCE(PV.PV, ATEMP.VALOR_LIBRE_ARTPROP) AS TEMPORADA_ART,
  ART.INSTANTE_MODIF AS INSTANTE_MODIF,
  ART.INSTANTE_ALTA AS INSTANTE_ALTA,
  ART.USUARIO_ALTA AS USUARIO_ALTA,
  ART.USUARIO_MODIF AS USUARIO_MODIF
FROM fza_articulos ART
LEFT JOIN fza_articulos_familias FAM
  ON ART.CODIGO_FAM_ART = FAM.CODIGO_FAM_FAM
LEFT JOIN fza_articulos_proveedores AP
  ON ART.CODIGO_ART_ART = AP.CODIGO_ART_AP
 AND AP.ESPROVEEDORPRINCIPAL_AP = 'S'
LEFT JOIN fza_proveedores PRV
  ON AP.CODIGO_PRV_AP = PRV.CODIGO_PRV_PRV
LEFT JOIN fza_ivas_tipos IVA
  ON ART.TIPO_IVA_ART = IVA.CODIGO_ABREVIATURA_IVA_IVATIP
LEFT JOIN fza_articulos_propiedades ATEMP
  ON ART.CODIGO_ART_ART = ATEMP.CODIGO_ART_ART
 AND ATEMP.CODIGO_PROP_ARTPROP = 'TEMPORADA'
LEFT JOIN fza_propiedades_valores PV
  ON ATEMP.ID_PV_ARTPROP = PV.ID_PV_ARTPROP
ORDER BY ART.ORDEN_ART;

-- 13. Verificacion estructural final.
SELECT
  (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fza_articulos'
      AND COLUMN_NAME = 'ESWEB_ART') AS EXISTE_ESWEB_ART,
  (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fza_almacenes'
      AND COLUMN_NAME = 'ESWEB_ALM') AS EXISTE_ESWEB_ALM,
  (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fza_prestashop_cola') AS COLUMNAS_PSCOLA,
  (SELECT COUNT(DISTINCT INDEX_NAME)
     FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fza_prestashop_cola'
      AND INDEX_NAME IN (
        'UQ_PSCOLA_INST_TIENDA_ART',
        'IDX_PSCOLA_INST_TIENDA_PEND',
        'IDX_PSCOLA_INST_TIENDA_LEASE',
        'IDX_PSCOLA_RECLAMACION'
      )) AS INDICES_PSCOLA,
  (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'vi_articulos'
      AND COLUMN_NAME = 'ESWEB_ART') AS VISTA_EXPONE_ESWEB_ART,
  (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.ROUTINES
    WHERE ROUTINE_SCHEMA = DATABASE()
      AND ROUTINE_TYPE = 'PROCEDURE'
      AND ROUTINE_NAME IN (
        'PRC_PRESTASHOP_ENCOLAR_TEMP',
        'PRC_PRESTASHOP_ENCOLAR_TEMP_DESTINO',
        'PRC_PRESTASHOP_ENCOLAR_CAMBIO',
        'PRC_PRESTASHOP_ENCOLAR_VISIBILIDAD',
        'PRC_PRESTASHOP_ENCOLAR_CAMBIO_ALMACEN',
        'PRC_PRESTASHOP_ENCOLAR_TODOS_WEB',
        'PRC_PRESTASHOP_ENCOLAR_TODOS_WEB_DESTINO',
        'PRC_PRESTASHOP_ENCOLAR_STOCK_ALMACEN',
        'PRC_PRESTASHOP_ENCOLAR_STOCK_RECALCULO',
        'PRC_PRESTASHOP_RECLAMAR_RECUPERACION',
        'PRC_PRESTASHOP_RECONCILIAR',
        'PRC_FZA_AJUSTAR_ACUMULADO_STK',
        'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT',
        'PRC_FZA_MOVIMIENTOS_RECALCULO_ACTUALIZAR_STOCK',
        'PRC_RECALCULAR_STOCK'
      )) AS PROCEDIMIENTOS_ESPERADOS;
-- Esperado: 1, 1, 24, 4, 1 y 15.
