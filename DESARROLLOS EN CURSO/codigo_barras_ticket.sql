-- ============================================================================
-- Código de barras EAN-13 por ticket (prefijo 29) para devoluciones en caja
-- Diseño DDL siguiendo LIBRO_DE_ESTILO_BBDD.md
-- (detalle funcional en DESARROLLOS EN CURSO/codigo_barras_ticket.md).
--
-- Añade a fza_facturas la columna CODIGO_BARRAS_FAC: EAN-13 con prefijo 29
-- (uso interno de tienda) + contador global de 10 dígitos + dígito de
-- control. Se genera al grabar la factura simplificada del ticket y se
-- imprime en el ticket ESC/POS si el parámetro de caja
-- vgerImprimirCodBarrasTicket está activo. F4 en operaciones de caja
-- resuelve el escaneo contra esta columna para cargar la devolución.
--
-- Siembra el contador global 'TK' (mismo patrón que 'BA' de los códigos
-- de barras de artículo, prefijo 21). PRC_GET_NEXT_CONT crearía la fila
-- solo, pero se siembra aquí para fijar NUM_DIGITOS_CON = 10.
--
-- Idempotente: pasa por INFORMATION_SCHEMA (COLUMNS / STATISTICS) antes de
-- crear la columna y el índice; el contador se siembra solo si no existe.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Columna CODIGO_BARRAS_FAC en fza_facturas
-- ---------------------------------------------------------------------------
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND COLUMN_NAME  = 'CODIGO_BARRAS_FAC'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `fza_facturas`'
  '  ADD COLUMN `CODIGO_BARRAS_FAC` varchar(13) NULL DEFAULT NULL'
  '      COMMENT ''EAN-13 del ticket (prefijo 29) para devoluciones'''
  '  AFTER `NUMERO_OPERACION_FAC`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Índice único para resolver el escaneo (F4) en O(1)
--    Único: dos tickets no pueden compartir código; NULL no indexa.
-- ---------------------------------------------------------------------------
SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'fza_facturas'
     AND INDEX_NAME   = 'UQ_FAC_CODIGO_BARRAS'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `fza_facturas`'
  '  ADD UNIQUE INDEX `UQ_FAC_CODIGO_BARRAS` (`CODIGO_BARRAS_FAC`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 3. Contador global 'TK' (ticket) de 10 dígitos, serie/empresa globales '-'
-- ---------------------------------------------------------------------------
INSERT INTO fza_contadores (
  TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON,
  NUM_DIGITOS_CON, ESACTIVO_CON, DEFAULT_CON,
  INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)
SELECT 'TK', '-', '-', 0, 10, 'S', 'S',
       NOW(), 'SISTEMA', 'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM fza_contadores
    WHERE TIPO_DOC_CON = 'TK'
      AND EMPRESA_CON  = '-'
      AND SERIE_CON    = '-'
 );

-- ---------------------------------------------------------------------------
-- Verificación rápida
-- ---------------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fza_facturas'
      AND COLUMN_NAME = 'CODIGO_BARRAS_FAC')  AS columna_ok,
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fza_facturas'
      AND INDEX_NAME = 'UQ_FAC_CODIGO_BARRAS') AS indice_ok,
  (SELECT COUNT(*) FROM fza_contadores
    WHERE TIPO_DOC_CON = 'TK')                 AS contador_ok;
