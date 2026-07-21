-- =============================================================================
-- Anade a fza_facturas el PDF archivado de la factura (PDF_FAC + metadatos)
-- =============================================================================
-- Al consolidar una factura (y en cada exportacion manual a PDF de una
-- factura ya lanzada) la aplicacion guarda el PDF generado por FastReport
-- en la propia fila de fza_facturas. Objetivos:
--   * Servir la factura emitida tal cual se imprimio (inmutabilidad):
--     reimpresion, envio al cliente, consulta externa via MCP...
--   * No depender del ejecutable ni del formato .frx en el momento de
--     la consulta.
-- Metadatos junto al blob, mismo patron que fza_ventas_ws_cola
-- (FACTURA_PDF_VWSC / TAMANO / HUELLA / NOMBRE):
--   NOMBRE_PDF_FAC   nombre de fichero con el que se genero
--   TAMANO_PDF_FAC   bytes del PDF
--   HUELLA_PDF_FAC   SHA-256 en hexadecimal (integridad)
--   INSTANTE_PDF_FAC momento en que se guardo el PDF
--   FORMATO_PDF_FAC  formato de impresion usado (VALUE_USUPER de
--                    fza_usuarios_perfiles o 'Predeterminado')
-- El codigo que los rellena vive en src/Lib/inLibFacturaPdfBlob.pas.
-- Notas de diseno y flujo en facturas_pdf_blob.md.
--
-- Idempotente: el bloque inicial anade las cinco columnas base en un
-- solo ALTER solo si PDF_FAC no existe; FORMATO_PDF_FAC (anadida en una
-- segunda iteracion) lleva su propia guarda para las BBDD donde ya se
-- aplico la primera version.
-- =============================================================================
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'PDF_FAC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN PDF_FAC longblob NULL DEFAULT NULL
       COMMENT ''PDF de la factura tal como se genero al consolidar/exportar'',
     ADD COLUMN NOMBRE_PDF_FAC varchar(200) NULL DEFAULT NULL
       COMMENT ''Nombre de fichero del PDF archivado'',
     ADD COLUMN TAMANO_PDF_FAC bigint NULL DEFAULT NULL
       COMMENT ''Tamano en bytes del PDF archivado'',
     ADD COLUMN HUELLA_PDF_FAC varchar(64) NULL DEFAULT NULL
       COMMENT ''SHA-256 hexadecimal del PDF archivado'',
     ADD COLUMN INSTANTE_PDF_FAC datetime NULL DEFAULT NULL
       COMMENT ''Momento en que se archivo el PDF''',
  'SELECT ''PDF_FAC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'FORMATO_PDF_FAC'
);
SET @sSql := IF(@sExisteCol = 0,
  'ALTER TABLE fza_facturas
     ADD COLUMN FORMATO_PDF_FAC varchar(200) NULL DEFAULT NULL
       COMMENT ''Formato de impresion con el que se genero el PDF archivado''
     AFTER INSTANTE_PDF_FAC',
  'SELECT ''FORMATO_PDF_FAC ya existe, se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
