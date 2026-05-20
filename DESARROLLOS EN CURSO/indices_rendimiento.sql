-- =============================================================================
-- Indices de rendimiento para volumen real (20k articulos, 4k facturas)
-- =============================================================================
-- Cubre los gaps detectados al cruzar el esquema de factuzam_original.sql con
-- las consultas reales del codigo Delphi (carpeta src/). Cada bloque indica
-- el escenario que dejaba de hacer full-scan al aplicar el indice.
--
-- Nombrado segun el libro de estilo (LIBRO_DE_ESTILO_BBDD.md, seccion 6):
--   IDX_<SUFIJO_TABLA>_<columnas_abreviadas>
--
-- Idempotente: usa un procedimiento auxiliar que consulta information_schema
-- antes de crear cada indice. Si el indice ya existe lo deja igual; si no,
-- lo crea. Compatible con cualquier version de MariaDB/MySQL.
-- =============================================================================

DROP PROCEDURE IF EXISTS sp_add_index_if_not_exists;
DELIMITER $$
CREATE PROCEDURE sp_add_index_if_not_exists(
  IN p_tabla VARCHAR(64),
  IN p_indice VARCHAR(64),
  IN p_columnas VARCHAR(1000)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM information_schema.statistics
     WHERE table_schema = DATABASE()
       AND table_name   = p_tabla
       AND index_name   = p_indice
  ) THEN
    SET @ddl = CONCAT('ALTER TABLE `', p_tabla, '` ADD INDEX `', p_indice, '` (', p_columnas, ')');
    PREPARE stmt FROM @ddl;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;


-- -----------------------------------------------------------------------------
-- 1. fza_articulos_skus: solo tenia PK (CODIGO_UNIDAD_SKU). Los JOIN y WHERE
--    por CODIGO_ART_SKU (vi_articulos_skus_extendida, vi_caja_busqueda_unificada,
--    vi_articulos_tarifas, inMtoArticulos.pas:1425, inMtoCajaOpe.pas:1565,
--    UniDataInventarios.pas:989) hacian full-scan de la tabla de SKUs.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_articulos_skus',
  'IDX_SKU_ART_ACT',
  '`CODIGO_ART_SKU`, `ESACTIVO_SKU`'
);


-- -----------------------------------------------------------------------------
-- 2. fza_articulos_stockactual: PK = (CODIGO_ALM_STK, CODIGO_UNIDAD_STK, LOTE_STK).
--    Las consultas filtran solo por CODIGO_UNIDAD_STK (inMtoCajaOpe.pas:453,
--    UniDataArticulos.pas:850, UniDataInventarios.pas:917, vi_articulos_skus_extendida)
--    para sumar stock entre almacenes y la PK no puede atender ese filtro porque
--    CODIGO_ALM_STK va primero -> full-scan de toda la tabla en cada venta.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_articulos_stockactual',
  'IDX_STK_UNIDAD',
  '`CODIGO_UNIDAD_STK`'
);


-- -----------------------------------------------------------------------------
-- 3. fza_articulos_proveedores: PK = (CODIGO_PRV_AP, CODIGO_ART_AP). La consulta
--    inversa "que proveedores tiene este articulo" (UniDataArticulos.pas:391,
--    vi_articulos, vi_articulos_list, vi_art_busquedas, vi_articulos_tarifas)
--    no encuentra a CODIGO_PRV_AP como discriminante, lo que fuerza un full-scan.
--    Casi siempre se filtra ademas por ESPROVEEDORPRINCIPAL_AP='S'.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_articulos_proveedores',
  'IDX_AP_ART_PRINC',
  '`CODIGO_ART_AP`, `ESPROVEEDORPRINCIPAL_AP`'
);


-- -----------------------------------------------------------------------------
-- 4. fza_articulos_vinculos: solo tenia PK autonumerica (ID_ARTVIN). Cualquier
--    consulta para resolver los componentes de un articulo compuesto (busqueda
--    por padre) o donde se usa un componente (busqueda por hijo) escaneaba la
--    tabla entera. Con 20k articulos y kits, lista de materiales se vuelve lenta.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_articulos_vinculos',
  'IDX_ARTVIN_PADRE',
  '`CODIGO_ART_PADRE_ARTVIN`'
);

CALL sp_add_index_if_not_exists(
  'fza_articulos_vinculos',
  'IDX_ARTVIN_HIJO',
  '`CODIGO_ART_HIJO_ARTVIN`'
);


-- -----------------------------------------------------------------------------
-- 5. fza_recibos: PK = (NUMERO_FAC_REC, SERIE_FAC_REC, NUMERO_PLAZO_REC), sin
--    ningun indice secundario. Los listados de cartera pendiente filtran por
--    ESTADO_RECIBO_REC='Emitido' y ordenan por FECHA_VENCIMIENTO_RECIBO_REC;
--    los extractos de cliente filtran por CODIGO_CLI_REC. Con 4k facturas se
--    generan en orden de 6k-20k recibos: ya merece la pena indexarlo.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_recibos',
  'IDX_REC_ESTADO_VENC',
  '`ESTADO_RECIBO_REC`, `FECHA_VENCIMIENTO_RECIBO_REC`'
);

CALL sp_add_index_if_not_exists(
  'fza_recibos',
  'IDX_REC_CLI',
  '`CODIGO_CLI_REC`'
);


-- -----------------------------------------------------------------------------
-- 6. fza_facturas_lineas: ya tiene indice por CODIGO_ART_FACLIN (articulo padre)
--    pero no por CODIGO_UNIDAD_FACLIN (SKU concreto). Los informes de "que
--    talla/color se ha vendido" iteran linea a linea sin indice; con ~10 lineas
--    por factura y 4k facturas estamos en ~40k filas para escanear cada vez.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_facturas_lineas',
  'IDX_FACLIN_UNIDAD',
  '`CODIGO_UNIDAD_FACLIN`'
);


-- -----------------------------------------------------------------------------
-- 7. fza_albaranes_lineas: tenia indices por articulo y pedido, pero no por la
--    factura que las consolido. Al abrir una factura provenida de albaranes el
--    detalle necesita resolver "que lineas de albaran originaron esta factura"
--    y ese inverso no esta indexado.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_albaranes_lineas',
  'IDX_ALBLIN_FAC',
  '`SERIE_FAC_ALBLIN`, `NUMERO_FAC_ALBLIN`'
);


-- -----------------------------------------------------------------------------
-- Limpieza del procedimiento auxiliar.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_add_index_if_not_exists;


-- -----------------------------------------------------------------------------
-- Verificacion (opcional, ejecutar despues):
--
--   SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX)
--     FROM information_schema.statistics
--    WHERE TABLE_SCHEMA = DATABASE()
--      AND INDEX_NAME IN (
--        'IDX_SKU_ART_ACT','IDX_STK_UNIDAD','IDX_AP_ART_PRINC',
--        'IDX_ARTVIN_PADRE','IDX_ARTVIN_HIJO',
--        'IDX_REC_ESTADO_VENC','IDX_REC_CLI',
--        'IDX_FACLIN_UNIDAD','IDX_ALBLIN_FAC'
--      )
--    GROUP BY TABLE_NAME, INDEX_NAME
--    ORDER BY TABLE_NAME, INDEX_NAME;
-- -----------------------------------------------------------------------------
