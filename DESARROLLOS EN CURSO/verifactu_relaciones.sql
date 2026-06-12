-- =============================================================================
-- Relaciones entre facturas (fza_facturas_relaciones)
-- =============================================================================
-- Historico N:1 de rectificaciones y sustituciones: cada factura "hija"
-- (rectificativa o factura completa F3) guarda su factura de origen.
-- Las columnas ABONO de fza_facturas siguen mostrando el ULTIMO enlace
-- (comodo en grids); esta tabla conserva TODOS, de modo que una factura
-- puede rectificarse varias veces sin perder trazabilidad y el envio
-- Verifactu de cada hija siempre localiza a su original (bloques
-- FacturasRectificadas / FacturasSustituidas).
--
-- TIPO_RELACION_FACREL: RECTIFICA | SUSTITUYE.
--
-- Sufijo de tabla: FACREL (registrado en LIBRO_DE_ESTILO_BBDD.md §2 y
-- en UNormalizerEngine.InitDefaults).
--
-- Idempotente: tabla e indices solo se crean si no existen.
-- =============================================================================

SET @sExisteTabla := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_relaciones'
);

SET @sSql := IF(@sExisteTabla = 0,
  'CREATE TABLE fza_facturas_relaciones (
     ID_FACREL                 bigint(20)  NOT NULL AUTO_INCREMENT,
     SERIE_FAC_FACREL          varchar(20) NOT NULL
       COMMENT ''Serie de la factura hija (rectificativa o F3)'',
     NUMERO_FAC_FACREL         varchar(20) NOT NULL
       COMMENT ''Numero de la factura hija'',
     SERIE_FAC_ORIGEN_FACREL   varchar(20) NOT NULL
       COMMENT ''Serie de la factura original'',
     NUMERO_FAC_ORIGEN_FACREL  varchar(20) NOT NULL
       COMMENT ''Numero de la factura original'',
     TIPO_RELACION_FACREL      varchar(20) NOT NULL DEFAULT ''RECTIFICA''
       COMMENT ''RECTIFICA o SUSTITUYE'',
     INSTANTE_ALTA             datetime    NOT NULL,
     USUARIO_ALTA              varchar(50) NULL DEFAULT NULL,
     INSTANTE_MODIF            datetime    NULL DEFAULT NULL,
     USUARIO_MODIF             varchar(50) NULL DEFAULT NULL,
     PRIMARY KEY (ID_FACREL)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci',
  'SELECT ''fza_facturas_relaciones ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Cada hija referencia a UNA original por tipo de relacion
SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_relaciones'
     AND INDEX_NAME   = 'UQ_FACREL_FACTURA_TIPO'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_facturas_relaciones
     ADD UNIQUE INDEX UQ_FACREL_FACTURA_TIPO
       (SERIE_FAC_FACREL, NUMERO_FAC_FACREL, TIPO_RELACION_FACREL)',
  'SELECT ''UQ_FACREL_FACTURA_TIPO ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Consulta N:1: todas las rectificativas/sustituciones de una original
SET @sExisteIdx := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas_relaciones'
     AND INDEX_NAME   = 'IDX_FACREL_ORIGEN'
);

SET @sSql := IF(@sExisteIdx = 0,
  'ALTER TABLE fza_facturas_relaciones
     ADD INDEX IDX_FACREL_ORIGEN
       (SERIE_FAC_ORIGEN_FACREL, NUMERO_FAC_ORIGEN_FACREL)',
  'SELECT ''IDX_FACREL_ORIGEN ya existe, se omite'' AS info'
);

PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
