-- ============================================================================
-- Compras / sesiones — promocion definitiva (extras)
--
--   1. Cabecera fza_compras_sesiones: nueva columna ID_PV_TEMPORADA_SES
--      (FK logica a fza_propiedades_valores con ID_PROP_PV='TEMPORADA').
--      Una unica temporada por sesion. Se propaga a fza_articulos_propiedades
--      con CODIGO_PROP_ARTPROP='TEMPORADA' durante la materializacion.
--
--   2. Tabla fza_compras_sesiones_fotos — fotos por linea de sesion antes
--      de materializar el articulo. El usuario captura fotos en muestrario
--      contra (SERIE, NUMERO, LINEA[, CODIGO_UNIDAD]); al materializar
--      pasan a fza_articulos_fotos con CODIGO_ART = CODIGO_ART_REUSAR o
--      CODIGO_ART_TENTATIVO resuelto. Diseno alineado con
--      DESARROLLOS EN CURSO/fotos_sesiones.md.
--
-- Todo idempotente: pasa por INFORMATION_SCHEMA antes de aplicar.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna ID_PV_TEMPORADA_SES en cabecera
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones'
     AND COLUMN_NAME  = 'ID_PV_TEMPORADA_SES'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_compras_sesiones` '
  'ADD COLUMN `ID_PV_TEMPORADA_SES` int(11) NULL DEFAULT NULL '
  '  COMMENT ''FK logica fza_propiedades_valores.ID_PV_ARTPROP con '
  'ID_PROP_PV=TEMPORADA. Una unica temporada por sesion; se propaga a '
  'cada articulo creado en fza_articulos_propiedades.''',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones'
     AND INDEX_NAME   = 'IDX_SES_TEMPORADA'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_compras_sesiones` '
  'ADD INDEX `IDX_SES_TEMPORADA` (`ID_PV_TEMPORADA_SES`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Tabla fza_compras_sesiones_fotos
-- ---------------------------------------------------------------------------
-- Una fila por foto subida en sesion. CODIGO_UNIDAD_CSF='' = foto a nivel
-- de la linea (articulo "padre"); != '' = foto a nivel de SKU (o prefijo).
-- CODIGO_ART_TENTATIVO_CSF se guarda redundantemente para trazabilidad si
-- el codigo tentativo cambia (raro).
SET @tab_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_fotos'
);
SET @ddl := IF(@tab_exists = 0,
  'CREATE TABLE `fza_compras_sesiones_fotos` ('
  '  `SERIE_SES_CSF`            varchar(12)  NOT NULL,'
  '  `NUMERO_SES_CSF`           varchar(12)  NOT NULL,'
  '  `LINEA_CSF`                int(11)      NOT NULL,'
  '  `CODIGO_UNIDAD_CSF`        varchar(50)  NOT NULL DEFAULT '''','
  '  `CODIGO_ART_TENTATIVO_CSF` varchar(20)  NOT NULL,'
  '  `NOMBRE_FOT_CSF`           varchar(255) NOT NULL,'
  '  `EXTENSION_ORIGEN_CSF`     varchar(10)  NOT NULL DEFAULT ''png'','
  '  `INSTANTE_MODIF`           timestamp    NOT NULL '
  '       DEFAULT current_timestamp() ON UPDATE current_timestamp(),'
  '  `INSTANTE_ALTA`            timestamp    NOT NULL '
  '       DEFAULT ''0000-00-00 00:00:00'','
  '  `USUARIO_ALTA`             varchar(100) NOT NULL,'
  '  `USUARIO_MODIF`            varchar(100) NOT NULL,'
  '  PRIMARY KEY (`SERIE_SES_CSF`,`NUMERO_SES_CSF`,'
  '               `LINEA_CSF`,`CODIGO_UNIDAD_CSF`)'
  ')',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_fotos'
     AND INDEX_NAME   = 'IDX_CSF_LIN'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_fotos` '
  'ADD INDEX `IDX_CSF_LIN` '
  '(`SERIE_SES_CSF`,`NUMERO_SES_CSF`,`LINEA_CSF`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_compras_sesiones_fotos'
     AND INDEX_NAME   = 'IDX_CSF_TENT'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_compras_sesiones_fotos` '
  'ADD INDEX `IDX_CSF_TENT` (`CODIGO_ART_TENTATIVO_CSF`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
