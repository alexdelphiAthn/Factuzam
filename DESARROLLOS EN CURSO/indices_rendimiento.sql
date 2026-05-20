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
--
-- BLOQUES:
--   PARTE 1: gaps estructurales (tablas sin indices secundarios). 9 indices.
--   PARTE 2: gaps detectados al leer las consultas calientes una a una. 5 mas.
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


-- =============================================================================
-- PARTE 1: gaps estructurales
-- =============================================================================


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


-- =============================================================================
-- PARTE 2: gaps detectados leyendo las consultas calientes
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 10. fza_articulos_proveedores: la vista `vi_caja_busqueda_unificada` filtra
--     `WHERE ap.REF_PROVEEDOR_AP = :input` cada vez que se teclea o escanea
--     algo en el TPV (camino "MODELO_PROV"). La PK es (CODIGO_PRV_AP,
--     CODIGO_ART_AP), no cubre busquedas por la referencia del proveedor.
--     Resultado: full-scan de la tabla en cada lectura del TPV.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_articulos_proveedores',
  'IDX_AP_REF',
  '`REF_PROVEEDOR_AP`'
);


-- -----------------------------------------------------------------------------
-- 11. fza_articulos_tarifas: la copia masiva de precios desde una tarifa
--     origen (`inMtoModalAddBlockTarifa.pas:374-385`) ejecuta una subconsulta
--     correlacionada por cada articulo del SELECT externo:
--
--       (SELECT t.PRECIO_SALIDA_ARTTAR
--          FROM fza_articulos_tarifas t
--         WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART
--           AND t.CODIGO_TAR_ARTTAR = :tar_orig
--           AND t.ESACTIVO_ARTTAR   = 'S'
--         ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1)
--
--     El indice `IDX_ART_TARIFAS_BUSQUEDA (art, tar)` ya existente cubre el
--     WHERE basico pero deja a MariaDB ordenando todas las tarifas activas
--     del par (art, tar). Para 20.000 articulos esto se multiplica.
--     El indice nuevo permite leer la primera fila directa.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_articulos_tarifas',
  'IDX_ARTTAR_BUSQ_VIGENTE',
  '`CODIGO_ART_ARTTAR`, `CODIGO_TAR_ARTTAR`, `ESACTIVO_ARTTAR`, `FECHA_DESDE_ARTTAR`'
);


-- -----------------------------------------------------------------------------
-- 12. fza_empresas_series: la PK es solo CODIGO_SERIE_EMPSER. La obtencion de
--     serie por defecto (`UniDataInventarios.pas:412-429` y otros sitios) hace:
--
--       WHERE CODIGO_EMP_EMPSER = :emp
--         AND TIPO_DOC_EMPSER   = :tipo
--         AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= NOW())
--         AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= NOW())
--       ORDER BY FECHA_DESDE_EMPSER DESC LIMIT 1
--
--     Sin indice = full-scan en cada creacion de factura/albaran/pedido/
--     inventario. La tabla es pequena pero la consulta es muy frecuente.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_empresas_series',
  'IDX_EMPSER_EMP_TIPO_FECHA',
  '`CODIGO_EMP_EMPSER`, `TIPO_DOC_EMPSER`, `FECHA_DESDE_EMPSER`'
);


-- -----------------------------------------------------------------------------
-- 13. fza_movimientos_almacen: hay indices por CODIGO_UNIDAD_MOV (SKU), por
--     CODIGO_ALM_MOV y combinados, pero ninguno por CODIGO_ART_MOV (articulo
--     padre). La pantalla de inventario `CargarMovimientosArticulo`
--     (`UniDataInventarios.pas:1213-1221`) filtra exactamente:
--
--       WHERE m.CODIGO_ART_MOV = :art AND m.CODIGO_ALM_MOV = :alm
--
--     Con potencialmente decenas de miles de movimientos historicos, esto
--     hace full-scan filtrado.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_movimientos_almacen',
  'IDX_MOV_ART_ALM',
  '`CODIGO_ART_MOV`, `CODIGO_ALM_MOV`'
);


-- -----------------------------------------------------------------------------
-- 14. fza_depositos_cliente: el calculo del arqueo de caja (`inLibArqueo.pas:
--     CalcularDepositos`, lineas 378-383) filtra:
--
--       WHERE CODIGO_EMP_DEP = :emp AND CODIGO_ALM_DEP = :alm
--         AND CODIGO_CAJA_DEP = :caja
--         AND FECHA_CREACION_DEP BETWEEN :desde AND :hasta
--
--     El indice existente `IDX_DEP_OP_ALTA` cubre el contexto + NUMERO_OPERACION_DEP
--     pero no FECHA_CREACION_DEP, asi que para arqueos de rango de fechas
--     ancho el plan acaba escaneando todos los depositos del contexto.
-- -----------------------------------------------------------------------------
CALL sp_add_index_if_not_exists(
  'fza_depositos_cliente',
  'IDX_DEP_OP_FECHA',
  '`CODIGO_EMP_DEP`, `CODIGO_ALM_DEP`, `CODIGO_CAJA_DEP`, `FECHA_CREACION_DEP`'
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
--        'IDX_FACLIN_UNIDAD','IDX_ALBLIN_FAC',
--        'IDX_AP_REF','IDX_ARTTAR_BUSQ_VIGENTE',
--        'IDX_EMPSER_EMP_TIPO_FECHA','IDX_MOV_ART_ALM','IDX_DEP_OP_FECHA'
--      )
--    GROUP BY TABLE_NAME, INDEX_NAME
--    ORDER BY TABLE_NAME, INDEX_NAME;
-- -----------------------------------------------------------------------------
--
-- ANTIPATRONES DE CONSULTA detectados al revisar el codigo. NO se arreglan
-- con indices: el codigo Delphi necesita reescribirse para que MariaDB
-- pueda usar los indices ya existentes. Se documentan aqui por trazabilidad
-- pero la correccion vive en src/.
--
-- A) src/DataModules/UniDataConsultaOpe.pas:144
--      WHERE DATE(o.FECHA_OPERACION_OPCAJA) = :PFECHA
--    Aplicar DATE() rompe el uso de `IDX_OPCAJA_CTX_FECHA`. Ya existe la
--    columna calculada `FECHA_OP_DIA_OPCAJA` con su propio indice
--    `IDX_OPCAJA_DIA_CTX`: la consulta deberia filtrar por
--    `FECHA_OP_DIA_OPCAJA = :PFECHA` para evitar el calculo por fila.
--
-- B) src/Lib/inLibArqueo.pas:444-445, 468-469
--      WHERE DATE(FECHA_EMISION_VL) >= :pFDESDE  -- y simetrico en redencion
--    Mismo antipatron. El filtro por contexto (EMP, ALM, CAJA) sigue
--    usando `IDX_VALES_EMI_OP`, pero el rango de fechas no aprovecha
--    el indice porque DATE() envuelve la columna. Reescribir con
--    comparacion directa contra `>= :pFDESDE AND < :pFHASTA + 1`.
--
-- C) Varias consultas con `(FECHA_X IS NULL OR FECHA_X <= NOW())`
--    El OR sobre IS NULL limita el uso del indice cuando la fecha es
--    parte del compuesto. Donde aparece (empresas_series, retenciones,
--    tarifas) la cardinalidad post-filtro previo es baja, asi que el
--    impacto es manejable; queda como mejora de segundo orden.
-- -----------------------------------------------------------------------------
