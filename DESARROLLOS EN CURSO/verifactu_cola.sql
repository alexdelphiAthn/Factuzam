-- =============================================================================
-- Cola de envio Verifactu (fza_verifactu_cola)
-- =============================================================================
-- Esquema calcado de OdaVeriFactu: al grabar una venta en caja (factura
-- SIMPLIFICADA) se inserta una fila PENDIENTE dentro de la misma
-- transaccion de la venta. Un hilo en segundo plano (inLibVerifactuCola)
-- reclama las filas, delega el envio del registro de facturacion en
-- inLibVerifactuEnvio y, al confirmarse, persiste la respuesta en
-- fza_facturas_consolidaciones y marca la factura (ESCONSOLIDADA_FAC,
-- INSTANTECONSO_FAC, FASE_FAC).
--
-- Estados (ESTADO_VFCOLA): PENDIENTE, PROCESANDO, ENVIADA, ERROR.
-- TIPO_OPERACION_VFCOLA:   ALTA o ANULACION.
--
-- Sufijo de tabla: VFCOLA (registrado en LIBRO_DE_ESTILO_BBDD.md §2 y en
-- UNormalizerEngine.InitDefaults).
--
-- Idempotente: tabla e indices solo se crean si no existen.
-- =============================================================================

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_cola'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_verifactu_cola (
     ID_VFCOLA                       bigint(20)  NOT NULL AUTO_INCREMENT,
     SERIE_FAC_VFCOLA                varchar(20) NOT NULL,
     NUMERO_FAC_VFCOLA               varchar(20) NOT NULL,
     TIPO_OPERACION_VFCOLA           varchar(20) NOT NULL DEFAULT ''ALTA''
       COMMENT ''ALTA o ANULACION'',
     ESTADO_VFCOLA                   varchar(20) NOT NULL
       DEFAULT ''PENDIENTE''
       COMMENT ''PENDIENTE, PROCESANDO, ENVIADA, ERROR'',
     CONTADOR_INTENTOS_VFCOLA        int(11)     NOT NULL DEFAULT 0
       COMMENT ''Numero de intentos de envio realizados'',
     INSTANTE_PROXIMO_INTENTO_VFCOLA datetime    NULL DEFAULT NULL
       COMMENT ''No reintentar antes de este instante (backoff)'',
     INSTANTE_ENVIO_VFCOLA           datetime    NULL DEFAULT NULL
       COMMENT ''Instante del envio aceptado por la AEAT'',
     MENSAJE_ERROR_VFCOLA            text        NULL DEFAULT NULL,
     INSTANTE_ALTA                   datetime    NOT NULL,
     USUARIO_ALTA                    varchar(50) NULL DEFAULT NULL,
     INSTANTE_MODIF                  datetime    NULL DEFAULT NULL,
     USUARIO_MODIF                   varchar(50) NULL DEFAULT NULL,
     PRIMARY KEY (ID_VFCOLA)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci',
  'SELECT ''fza_verifactu_cola ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Unico por factura y tipo de operacion: una venta no se encola dos veces
SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_cola'
     AND INDEX_NAME   = 'UQ_VFCOLA_SERIE_NUMERO_TIPO'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_verifactu_cola
     ADD UNIQUE INDEX UQ_VFCOLA_SERIE_NUMERO_TIPO
       (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, TIPO_OPERACION_VFCOLA)',
  'SELECT ''UQ_VFCOLA_SERIE_NUMERO_TIPO ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Barrido del hilo: pendientes cuyo proximo intento ya ha vencido
SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_cola'
     AND INDEX_NAME   = 'IDX_VFCOLA_ESTADO_PROXIMO'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_verifactu_cola
     ADD INDEX IDX_VFCOLA_ESTADO_PROXIMO
       (ESTADO_VFCOLA, INSTANTE_PROXIMO_INTENTO_VFCOLA)',
  'SELECT ''IDX_VFCOLA_ESTADO_PROXIMO ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
