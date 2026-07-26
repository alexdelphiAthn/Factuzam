-- ============================================================================
--  Proyección de líneas de venta para el listado móvil.
--
--  Idempotente: se puede lanzar tantas veces como haga falta.
--  Base de datos: la del webservice (api_*), NO la de Factuzam.
--
--  Antes de este script api_ventas_lineas solo guardaba datos_json, con lo
--  que no se podía filtrar ni sumar por SQL. Aquí se añaden las columnas que
--  consulta ventas/lineas.php, más la fecha real de venta (la de la factura,
--  no la de recepción del evento) para poder agrupar por día.
--
--  El agrupado por día usa fecha_venta (FECHA_FAC, la fecha oficial del
--  documento) y no el instante en UTC: así el corte del día es el del
--  negocio y no depende de husos horarios.
-- ============================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS fza_api_anadir_columna //
CREATE PROCEDURE fza_api_anadir_columna(
    IN pTabla   VARCHAR(64),
    IN pColumna VARCHAR(64),
    IN pDef     VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = pTabla
           AND COLUMN_NAME = pColumna
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', pTabla, '` ADD COLUMN `',
                          pColumna, '` ', pDef);
        PREPARE st FROM @sql;
        EXECUTE st;
        DEALLOCATE PREPARE st;
    END IF;
END //

DROP PROCEDURE IF EXISTS fza_api_anadir_indice //
CREATE PROCEDURE fza_api_anadir_indice(
    IN pTabla    VARCHAR(64),
    IN pIndice   VARCHAR(64),
    IN pColumnas VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = pTabla
           AND INDEX_NAME = pIndice
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', pTabla, '` ADD INDEX `',
                          pIndice, '` (', pColumnas, ')');
        PREPARE st FROM @sql;
        EXECUTE st;
        DEALLOCATE PREPARE st;
    END IF;
END //

DELIMITER ;

-- ---------------------------------------------------------------------------
--  api_ventas: fecha y hora reales de la venta
-- ---------------------------------------------------------------------------
CALL fza_api_anadir_columna('api_ventas', 'fecha_venta',
    'DATE NULL DEFAULT NULL COMMENT ''FECHA_FAC de la factura''');
CALL fza_api_anadir_columna('api_ventas', 'instante_venta',
    'DATETIME NULL DEFAULT NULL COMMENT ''INSTANTECONSO_FAC en UTC''');
CALL fza_api_anadir_columna('api_ventas', 'tipo_factura',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas', 'total_factura',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''TOTAL_LIQUIDO_FAC''');
CALL fza_api_anadir_indice('api_ventas', 'idx_api_ventas_fecha',
    '`referencia`, `fecha_venta`');

-- ---------------------------------------------------------------------------
--  api_ventas_lineas: campos proyectados del JSON de cada línea
--
--  referencia y fecha_venta van desnormalizadas a propósito: el listado del
--  móvil filtra siempre por esas dos, y así se resuelve con un único índice
--  sin tocar api_ventas.
-- ---------------------------------------------------------------------------
CALL fza_api_anadir_columna('api_ventas_lineas', 'referencia',
    'VARCHAR(100) NOT NULL DEFAULT ''''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'fecha_venta',
    'DATE NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'instante_venta',
    'DATETIME NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'codigo_empresa',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'serie_factura',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'numero_factura',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'linea',
    'VARCHAR(4) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'codigo_articulo',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'sku',
    'VARCHAR(50) NULL DEFAULT NULL COMMENT ''CODIGO_UNIDAD_FACLIN''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'color',
    'VARCHAR(50) NULL DEFAULT NULL COMMENT ''2o segmento del SKU''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'descripcion',
    'VARCHAR(200) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'descripcion_variacion',
    'VARCHAR(200) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'codigo_familia',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'nombre_familia',
    'VARCHAR(200) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'temporada',
    'VARCHAR(100) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'codigo_proveedor',
    'VARCHAR(20) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'nombre_proveedor',
    'VARCHAR(200) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'cantidad',
    'DECIMAL(19,6) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'precio_coste',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''PRECIO_ULT_COMPRA_FACLIN''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'pvp',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''PRECIO_SALIDA_FACLIN''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'porcentaje_descuento',
    'DECIMAL(19,6) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'precio_con_descuento',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''unitario cobrado''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'importe_descuento',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''pvp*cant - cobrado''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'precio_venta',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''unitario c/IVA''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'total_linea',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''TOTAL_FACLIN, c/IVA''');
CALL fza_api_anadir_columna('api_ventas_lineas', 'total_linea_siva',
    'DECIMAL(19,6) NULL DEFAULT NULL');
CALL fza_api_anadir_columna('api_ventas_lineas', 'total_coste',
    'DECIMAL(19,6) NULL DEFAULT NULL COMMENT ''precio_coste * cantidad''');

CALL fza_api_anadir_indice('api_ventas_lineas', 'idx_avl_ref_fecha',
    '`referencia`, `fecha_venta`');
CALL fza_api_anadir_indice('api_ventas_lineas', 'idx_avl_familia',
    '`referencia`, `codigo_familia`, `fecha_venta`');
CALL fza_api_anadir_indice('api_ventas_lineas', 'idx_avl_proveedor',
    '`referencia`, `codigo_proveedor`, `fecha_venta`');
CALL fza_api_anadir_indice('api_ventas_lineas', 'idx_avl_temporada',
    '`referencia`, `temporada`, `fecha_venta`');
CALL fza_api_anadir_indice('api_ventas_lineas', 'idx_avl_articulo',
    '`referencia`, `codigo_articulo`');

DROP PROCEDURE IF EXISTS fza_api_anadir_columna;
DROP PROCEDURE IF EXISTS fza_api_anadir_indice;

-- ============================================================================
--  Relleno de lo ya recibido
--
--  Las ventas que llegaron antes de este cambio tienen las columnas a NULL y
--  no saldrían en la app. Se rellenan desde el JSON que ya está guardado.
--  Solo toca las filas pendientes, así que repetirlo no hace nada.
--
--  Los textos se recortan con LEFT al ancho de cada columna: el camino
--  normal ya trunca en PHP, pero aquí el JSON viene sin recortar y con
--  STRICT_TRANS_TABLES un valor largo abortaría el UPDATE entero.
--
--  Aviso: la temporada NO se puede rellenar hacia atrás. Los eventos
--  antiguos se serializaron sin ella, así que esas líneas se quedan con
--  temporada vacía hasta que la venta se vuelva a enviar.
-- ============================================================================

UPDATE api_ventas
   SET fecha_venta = NULLIF(
           JSON_VALUE(cabecera_json, '$.FECHA_FAC'), ''),
       instante_venta = STR_TO_DATE(
           SUBSTRING(COALESCE(
               NULLIF(JSON_VALUE(cabecera_json, '$.INSTANTECONSO_FAC'), ''),
               JSON_VALUE(cabecera_json, '$.INSTANTE_ALTA')), 1, 19),
           '%Y-%m-%dT%H:%i:%s'),
       tipo_factura = JSON_VALUE(cabecera_json, '$.TIPO_FAC'),
       total_factura = JSON_VALUE(cabecera_json, '$.TOTAL_LIQUIDO_FAC')
 WHERE fecha_venta IS NULL;

UPDATE api_ventas_lineas L
  JOIN api_ventas V ON V.id = L.id_venta
   SET L.referencia = V.referencia,
       L.fecha_venta = V.fecha_venta,
       L.instante_venta = V.instante_venta,
       L.codigo_empresa = V.codigo_empresa,
       L.serie_factura = V.serie_factura,
       L.numero_factura = V.numero_factura,
       L.linea = LEFT(JSON_VALUE(L.datos_json, '$.LINEA_FACLIN'), 4),
       L.codigo_articulo =
           LEFT(JSON_VALUE(L.datos_json, '$.CODIGO_ART_FACLIN'), 20),
       L.sku = LEFT(JSON_VALUE(L.datos_json, '$.CODIGO_UNIDAD_FACLIN'), 50),
       L.color = CASE
           WHEN JSON_VALUE(L.datos_json, '$.CODIGO_UNIDAD_FACLIN')
                LIKE '%/%/%'
           THEN LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(
                    JSON_VALUE(L.datos_json, '$.CODIGO_UNIDAD_FACLIN'),
                    '/', 2), '/', -1), 50)
           ELSE '' END,
       L.descripcion = LEFT(
           JSON_VALUE(L.datos_json, '$.DESCRIPCION_ARTICULO_FACLIN'), 200),
       L.descripcion_variacion = LEFT(
           JSON_VALUE(L.datos_json, '$.DESCRIPCION_VARIACION_FACLIN'), 200),
       L.codigo_familia =
           LEFT(JSON_VALUE(L.datos_json, '$.CODIGO_FAM_FACLIN'), 20),
       L.nombre_familia =
           LEFT(JSON_VALUE(L.datos_json, '$.NOMBRE_FAM_FACLIN'), 200),
       L.temporada = LEFT(COALESCE(
           JSON_VALUE(L.datos_json, '$.TEMPORADA_CALC'), ''), 100),
       L.codigo_proveedor =
           LEFT(JSON_VALUE(L.datos_json, '$.CODIGO_PRV_FACLIN'), 20),
       L.nombre_proveedor = LEFT(
           JSON_VALUE(L.datos_json, '$.RAZON_SOCIAL_PROVEEDOR_FACLIN'), 200),
       L.cantidad = COALESCE(
           JSON_VALUE(L.datos_json, '$.CANTIDAD_FACLIN'), 0),
       L.precio_coste = COALESCE(
           JSON_VALUE(L.datos_json, '$.PRECIO_ULT_COMPRA_FACLIN'), 0),
       L.pvp = COALESCE(
           JSON_VALUE(L.datos_json, '$.PRECIO_SALIDA_FACLIN'), 0),
       L.porcentaje_descuento = COALESCE(
           JSON_VALUE(L.datos_json, '$.PORCENTAJE_DTO_FACLIN'), 0),
       L.precio_con_descuento = COALESCE(
           JSON_VALUE(L.datos_json, '$.PRECIO_DTO_FACLIN'), 0),
       L.precio_venta = COALESCE(
           JSON_VALUE(L.datos_json, '$.PRECIO_VENTA_CIVA_ARTICULO_FACLIN'), 0),
       L.total_linea = COALESCE(
           JSON_VALUE(L.datos_json, '$.TOTAL_FACLIN'), 0),
       L.total_linea_siva = COALESCE(
           JSON_VALUE(L.datos_json, '$.TOTAL_FAC_SIVA_FACLIN'), 0)
 WHERE L.referencia = '';

-- Derivados, una vez están los campos base.
--
-- Descuento = PVP de tarifa menos lo realmente cobrado, comparando sobre la
-- misma base de IVA que la tarifa. No se usa PRECIO_DTO_FACLIN porque ese
-- campo unas veces trae el precio ya rebajado y otras el importe rebajado.
--
-- Este UPDATE va SIN filtro a propósito: recalcula también las filas que ya
-- estaban rellenas, para corregir las que se proyectaron con la fórmula
-- anterior. Repetirlo es inocuo, solo cuesta un recorrido de la tabla.
UPDATE api_ventas_lineas
   SET total_coste = COALESCE(precio_coste, 0) * COALESCE(cantidad, 0),
       precio_con_descuento = CASE
           WHEN COALESCE(cantidad, 0) = 0 THEN 0
           ELSE (CASE WHEN UPPER(COALESCE(JSON_VALUE(
                          datos_json, '$.ESIMP_INCL_TARIFA_FACLIN'), 'S')) = 'N'
                      THEN COALESCE(total_linea_siva, 0)
                      ELSE COALESCE(total_linea, 0) END) / cantidad
           END,
       importe_descuento = GREATEST(0,
           COALESCE(pvp, 0) * COALESCE(cantidad, 0) -
           CASE WHEN UPPER(COALESCE(JSON_VALUE(
                        datos_json, '$.ESIMP_INCL_TARIFA_FACLIN'), 'S')) = 'N'
                THEN COALESCE(total_linea_siva, 0)
                ELSE COALESCE(total_linea, 0) END);
