-- =============================================================================
-- Cadena de huellas Verifactu (fza_verifactu_cadena)
-- =============================================================================
-- Una fila por obligado de emision (NIF de empresa). Guarda el ultimo
-- eslabon de la cadena de registros de facturacion enviados a la AEAT:
-- contador, identificacion de la ultima factura y su huella SHA-256.
--
-- El cliente de envio (inLibVerifactuEnvio.ObtenerCadenaParaEnvio) hace
-- INSERT IGNORE + SELECT ... FOR UPDATE sobre esta fila dentro de la
-- transaccion del envio: eso serializa el encadenamiento entre puestos
-- (dos cajas no pueden encadenar a la vez sobre el mismo NIF). La fila
-- solo avanza cuando la AEAT acepta el registro.
--
-- Sufijo de tabla: VFCAD (registrado en LIBRO_DE_ESTILO_BBDD.md §2 y en
-- UNormalizerEngine.InitDefaults).
--
-- Idempotente: la tabla solo se crea si no existe.
-- =============================================================================

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_verifactu_cadena'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_verifactu_cadena (
     NIF_VFCAD        varchar(50) NOT NULL
       COMMENT ''NIF del obligado de emision'',
     CONTADOR_VFCAD   bigint(20)  NOT NULL DEFAULT 0
       COMMENT ''Numero de registros aceptados (eslabones)'',
     SERIE_FAC_VFCAD  varchar(20) NULL DEFAULT NULL
       COMMENT ''Serie de la ultima factura encadenada'',
     NUMERO_FAC_VFCAD varchar(20) NULL DEFAULT NULL
       COMMENT ''Numero de la ultima factura encadenada'',
     FECHA_FAC_VFCAD  date        NULL DEFAULT NULL
       COMMENT ''Fecha de expedicion de la ultima factura'',
     HUELLA_VFCAD     char(64)    NULL DEFAULT NULL
       COMMENT ''Huella SHA-256 del ultimo registro aceptado'',
     INSTANTE_ALTA    datetime    NOT NULL,
     USUARIO_ALTA     varchar(50) NULL DEFAULT NULL,
     INSTANTE_MODIF   datetime    NULL DEFAULT NULL,
     USUARIO_MODIF    varchar(50) NULL DEFAULT NULL,
     PRIMARY KEY (NIF_VFCAD)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci',
  'SELECT ''fza_verifactu_cadena ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
