-- =====================================================================
-- Acumular en fza_articulos_stockactual los movimientos por subtipo.
-- Modelo simplificado:
--   COMPRA       → solo ENT      (AC)
--   TRASPASO     → ENT + SAL     (TR/AT/TA)
--   DEPOSITO     → ENT + SAL     (DP, incluye préstamos)
--   VENTA        → solo SAL      (VE caja POS, FC facturas)
--   REGULAR      → solo ENT      (IN)
--   ALBVENTA     → solo SAL      (AV - albaranes de venta)
--   ALBENTRADA   → solo ENT      (AE - albaranes de entrada/devolución)
-- =====================================================================

-- 1. Añadir columnas idempotentemente
DELIMITER ;;
DROP PROCEDURE IF EXISTS tmp_add_col_stk;;
CREATE PROCEDURE tmp_add_col_stk(IN col_name VARCHAR(64))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME   = 'fza_articulos_stockactual'
       AND COLUMN_NAME  = col_name
  ) THEN
    SET @sql = CONCAT(
      'ALTER TABLE fza_articulos_stockactual ADD COLUMN ',
      col_name, ' decimal(19,6) NOT NULL DEFAULT 0');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END;;
DELIMITER ;

CALL tmp_add_col_stk('CANTIDAD_ENT_COMPRA_STK');
CALL tmp_add_col_stk('CANTIDAD_ENT_TRASPASO_STK');
CALL tmp_add_col_stk('CANTIDAD_SAL_TRASPASO_STK');
CALL tmp_add_col_stk('CANTIDAD_ENT_DEPOSITO_STK');
CALL tmp_add_col_stk('CANTIDAD_SAL_DEPOSITO_STK');
CALL tmp_add_col_stk('CANTIDAD_SAL_VENTA_STK');
CALL tmp_add_col_stk('CANTIDAD_ENT_REGULAR_STK');
CALL tmp_add_col_stk('CANTIDAD_SAL_ALBVENTA_STK');
CALL tmp_add_col_stk('CANTIDAD_ENT_ALBENTRADA_STK');

DROP PROCEDURE tmp_add_col_stk;

-- 2. Reemplazar el SP para que también incremente los acumulados por subtipo
DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT`(
    IN `p_NUMERO_MOV` VARCHAR(20),
    IN `p_TIPO_DOC_MOV` VARCHAR(20),
    IN `p_SERIE_DOC_MOV` VARCHAR(20),
    IN `p_NRO_DOC_MOV` VARCHAR(20),
    IN `p_LINEA_MOV` VARCHAR(10),
    IN `p_CODIGO_EMPRESA_MOV` VARCHAR(20),
    IN `p_CODIGO_ALMACEN_MOV` VARCHAR(10),
    IN `p_CODIGO_ALMACEN_CONTRA_MOV` VARCHAR(10),
    IN `p_CODIGO_UNIDAD_MOV` VARCHAR(50),
    IN `p_TIPO_MOVIMIENTO_MOV` VARCHAR(1),
    IN `p_CANTIDAD_MOV` DECIMAL(19,6),
    IN `p_PRECIO_MEDIO_MOV` DECIMAL(19,6),
    IN `p_TOTAL_COSTE_MOV` DECIMAL(19,6),
    IN `p_USUARIO` VARCHAR(100),
    IN `p_ALMACEN_DOC` VARCHAR(10),
    IN `p_NUMOP_DOC` VARCHAR(20),
    IN `p_CODIGO_CAJA_DOC_MOV` VARCHAR(10),
    IN `p_CODCLIENTE` VARCHAR(20),
    IN `p_CODARTICULO` VARCHAR(20)
)
BEGIN
    DECLARE v_PMPActual DECIMAL(19,6) DEFAULT 0;
    DECLARE v_PrecioFinal DECIMAL(19,6);
    DECLARE v_CosteFinal DECIMAL(19,6);
    DECLARE v_dEntCompra DECIMAL(19,6) DEFAULT 0;
    DECLARE v_dEntTraspaso, v_dSalTraspaso DECIMAL(19,6) DEFAULT 0;
    DECLARE v_dEntDeposito, v_dSalDeposito DECIMAL(19,6) DEFAULT 0;
    DECLARE v_dSalVenta DECIMAL(19,6) DEFAULT 0;
    DECLARE v_dEntRegular DECIMAL(19,6) DEFAULT 0;
    DECLARE v_dSalAlbVenta DECIMAL(19,6) DEFAULT 0;
    DECLARE v_dEntAlbEntrada DECIMAL(19,6) DEFAULT 0;

    SELECT IFNULL(PRECIO_MEDIO_STK, 0)
      INTO v_PMPActual
      FROM fza_articulos_stockactual
     WHERE CODIGO_ALM_STK = p_CODIGO_ALMACEN_MOV
       AND CODIGO_UNIDAD_STK = p_CODIGO_UNIDAD_MOV
     LIMIT 1;

    IF p_TIPO_MOVIMIENTO_MOV = 'S' THEN
        SET v_PrecioFinal = v_PMPActual;
        SET v_CosteFinal  = p_CANTIDAD_MOV * v_PMPActual;
    ELSE
        SET v_PrecioFinal = p_PRECIO_MEDIO_MOV;
        SET v_CosteFinal  = p_TOTAL_COSTE_MOV;
    END IF;

    -- Delta de acumulado según TIPO_DOC_MOV
    IF p_TIPO_DOC_MOV = 'AC' AND p_TIPO_MOVIMIENTO_MOV = 'E' THEN
        SET v_dEntCompra = p_CANTIDAD_MOV;
    ELSEIF p_TIPO_DOC_MOV IN ('TR','AT','TA') THEN
        IF p_TIPO_MOVIMIENTO_MOV = 'E' THEN SET v_dEntTraspaso = p_CANTIDAD_MOV;
        ELSE SET v_dSalTraspaso = p_CANTIDAD_MOV; END IF;
    ELSEIF p_TIPO_DOC_MOV = 'DP' THEN
        IF p_TIPO_MOVIMIENTO_MOV = 'E' THEN SET v_dEntDeposito = p_CANTIDAD_MOV;
        ELSE SET v_dSalDeposito = p_CANTIDAD_MOV; END IF;
    ELSEIF p_TIPO_DOC_MOV IN ('VE','FC') AND p_TIPO_MOVIMIENTO_MOV = 'S' THEN
        SET v_dSalVenta = p_CANTIDAD_MOV;
    ELSEIF p_TIPO_DOC_MOV = 'IN' AND p_TIPO_MOVIMIENTO_MOV = 'E' THEN
        SET v_dEntRegular = p_CANTIDAD_MOV;
    ELSEIF p_TIPO_DOC_MOV = 'AV' AND p_TIPO_MOVIMIENTO_MOV = 'S' THEN
        SET v_dSalAlbVenta = p_CANTIDAD_MOV;
    ELSEIF p_TIPO_DOC_MOV = 'AE' AND p_TIPO_MOVIMIENTO_MOV = 'E' THEN
        SET v_dEntAlbEntrada = p_CANTIDAD_MOV;
    END IF;

    INSERT INTO fza_movimientos_almacen (
        NUMERO_MOV,
        TIPO_DOC_MOV, SERIE_DOC_MOV, NUMERO_DOC_MOV, LINEA_MOV,
        CODIGO_EMP_MOV, CODIGO_ALM_MOV, CODIGO_ALM_CONTRA_MOV,
        CODIGO_UNIDAD_MOV, TIPO_MOV, CANTIDAD_MOV,
        PRECIO_COSTE_UNITARIO_MOV,
        PRECIO_MEDIO_MOV, TOTAL_COSTE_MOV,
        FECHA_MOV, USUARIO_ALTA, USUARIO_MODIF,
        CODIGO_ALM_DOC_MOV, NUMERO_OPERACION_DOC_MOV, CODIGO_CAJA_DOC_MOV,
        CODIGO_CLI_MOV, CODIGO_ART_MOV
    ) VALUES (
        p_NUMERO_MOV,
        p_TIPO_DOC_MOV, p_SERIE_DOC_MOV, p_NRO_DOC_MOV, p_LINEA_MOV,
        p_CODIGO_EMPRESA_MOV, p_CODIGO_ALMACEN_MOV, p_CODIGO_ALMACEN_CONTRA_MOV,
        p_CODIGO_UNIDAD_MOV, p_TIPO_MOVIMIENTO_MOV, p_CANTIDAD_MOV,
        v_PrecioFinal,
        v_PrecioFinal, v_CosteFinal,
        NOW(), p_USUARIO, p_USUARIO,
        p_ALMACEN_DOC, p_NUMOP_DOC, p_CODIGO_CAJA_DOC_MOV,
        p_CODCLIENTE, p_CODARTICULO
    );

    INSERT INTO fza_articulos_stockactual (
        CODIGO_ALM_STK, CODIGO_UNIDAD_STK,
        CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTE_MODIF,
        CANTIDAD_ENT_COMPRA_STK,
        CANTIDAD_ENT_TRASPASO_STK, CANTIDAD_SAL_TRASPASO_STK,
        CANTIDAD_ENT_DEPOSITO_STK, CANTIDAD_SAL_DEPOSITO_STK,
        CANTIDAD_SAL_VENTA_STK,
        CANTIDAD_ENT_REGULAR_STK,
        CANTIDAD_SAL_ALBVENTA_STK,
        CANTIDAD_ENT_ALBENTRADA_STK
    ) VALUES (
        p_CODIGO_ALMACEN_MOV,
        p_CODIGO_UNIDAD_MOV,
        IF(p_TIPO_MOVIMIENTO_MOV = 'E', p_CANTIDAD_MOV, -p_CANTIDAD_MOV),
        IF(p_TIPO_MOVIMIENTO_MOV = 'E', v_CosteFinal, -v_CosteFinal),
        v_PrecioFinal,
        NOW(),
        v_dEntCompra,
        v_dEntTraspaso, v_dSalTraspaso,
        v_dEntDeposito, v_dSalDeposito,
        v_dSalVenta,
        v_dEntRegular,
        v_dSalAlbVenta,
        v_dEntAlbEntrada
    )
    ON DUPLICATE KEY UPDATE
        CANTIDAD_STK     = CANTIDAD_STK     + VALUES(CANTIDAD_STK),
        VALOR_TOTAL_STK  = VALOR_TOTAL_STK  + VALUES(VALOR_TOTAL_STK),
        PRECIO_MEDIO_STK = IF(CANTIDAD_STK > 0,
                              VALOR_TOTAL_STK / CANTIDAD_STK, 0),
        INSTANTE_MODIF   = NOW(),
        CANTIDAD_ENT_COMPRA_STK   = CANTIDAD_ENT_COMPRA_STK   + VALUES(CANTIDAD_ENT_COMPRA_STK),
        CANTIDAD_ENT_TRASPASO_STK = CANTIDAD_ENT_TRASPASO_STK + VALUES(CANTIDAD_ENT_TRASPASO_STK),
        CANTIDAD_SAL_TRASPASO_STK = CANTIDAD_SAL_TRASPASO_STK + VALUES(CANTIDAD_SAL_TRASPASO_STK),
        CANTIDAD_ENT_DEPOSITO_STK = CANTIDAD_ENT_DEPOSITO_STK + VALUES(CANTIDAD_ENT_DEPOSITO_STK),
        CANTIDAD_SAL_DEPOSITO_STK = CANTIDAD_SAL_DEPOSITO_STK + VALUES(CANTIDAD_SAL_DEPOSITO_STK),
        CANTIDAD_SAL_VENTA_STK    = CANTIDAD_SAL_VENTA_STK    + VALUES(CANTIDAD_SAL_VENTA_STK),
        CANTIDAD_ENT_REGULAR_STK  = CANTIDAD_ENT_REGULAR_STK  + VALUES(CANTIDAD_ENT_REGULAR_STK),
        CANTIDAD_SAL_ALBVENTA_STK   = CANTIDAD_SAL_ALBVENTA_STK   + VALUES(CANTIDAD_SAL_ALBVENTA_STK),
        CANTIDAD_ENT_ALBENTRADA_STK = CANTIDAD_ENT_ALBENTRADA_STK + VALUES(CANTIDAD_ENT_ALBENTRADA_STK);
END ;;
DELIMITER ;

-- 3. Reinicializar acumulados desde los movimientos existentes
UPDATE fza_articulos_stockactual SET
  CANTIDAD_ENT_COMPRA_STK   = 0,
  CANTIDAD_ENT_TRASPASO_STK = 0, CANTIDAD_SAL_TRASPASO_STK = 0,
  CANTIDAD_ENT_DEPOSITO_STK = 0, CANTIDAD_SAL_DEPOSITO_STK = 0,
  CANTIDAD_SAL_VENTA_STK    = 0,
  CANTIDAD_ENT_REGULAR_STK    = 0,
  CANTIDAD_SAL_ALBVENTA_STK   = 0,
  CANTIDAD_ENT_ALBENTRADA_STK = 0;

UPDATE fza_articulos_stockactual s
  INNER JOIN (
    SELECT
      CODIGO_ALM_MOV     AS alm,
      CODIGO_UNIDAD_MOV  AS uni,
      SUM(IF(TIPO_DOC_MOV='AC' AND TIPO_MOV='E', CANTIDAD_MOV, 0))         AS ent_compra,
      SUM(IF(TIPO_DOC_MOV IN ('TR','AT','TA') AND TIPO_MOV='E', CANTIDAD_MOV, 0)) AS ent_traspaso,
      SUM(IF(TIPO_DOC_MOV IN ('TR','AT','TA') AND TIPO_MOV='S', CANTIDAD_MOV, 0)) AS sal_traspaso,
      SUM(IF(TIPO_DOC_MOV='DP' AND TIPO_MOV='E', CANTIDAD_MOV, 0))         AS ent_deposito,
      SUM(IF(TIPO_DOC_MOV='DP' AND TIPO_MOV='S', CANTIDAD_MOV, 0))         AS sal_deposito,
      SUM(IF(TIPO_DOC_MOV IN ('VE','FC') AND TIPO_MOV='S', CANTIDAD_MOV, 0)) AS sal_venta,
      SUM(IF(TIPO_DOC_MOV='IN' AND TIPO_MOV='E', CANTIDAD_MOV, 0))         AS ent_regular,
      SUM(IF(TIPO_DOC_MOV='AV' AND TIPO_MOV='S', CANTIDAD_MOV, 0))         AS sal_albventa,
      SUM(IF(TIPO_DOC_MOV='AE' AND TIPO_MOV='E', CANTIDAD_MOV, 0))         AS ent_albentrada
    FROM fza_movimientos_almacen
    WHERE ESACTIVO_MOV = 'S'
    GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV
  ) m ON m.alm = s.CODIGO_ALM_STK AND m.uni = s.CODIGO_UNIDAD_STK
SET
  s.CANTIDAD_ENT_COMPRA_STK   = m.ent_compra,
  s.CANTIDAD_ENT_TRASPASO_STK = m.ent_traspaso,
  s.CANTIDAD_SAL_TRASPASO_STK = m.sal_traspaso,
  s.CANTIDAD_ENT_DEPOSITO_STK = m.ent_deposito,
  s.CANTIDAD_SAL_DEPOSITO_STK = m.sal_deposito,
  s.CANTIDAD_SAL_VENTA_STK    = m.sal_venta,
  s.CANTIDAD_ENT_REGULAR_STK    = m.ent_regular,
  s.CANTIDAD_SAL_ALBVENTA_STK   = m.sal_albventa,
  s.CANTIDAD_ENT_ALBENTRADA_STK = m.ent_albentrada;
