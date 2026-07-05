-- =====================================================================
-- SPs de gestión de movimientos de almacén con mantenimiento automático
-- de los acumulados en fza_articulos_stockactual.
--
-- Procedimientos:
--   PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT  (ya existe, modificado en
--                                        stocks_acumulados.sql)
--   PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE  (nuevo: revierte uno por NUMERO_MOV)
--   PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC (nuevo: revierte todos los de un
--                                           documento)
--   PRC_FZA_MOVIMIENTOS_ALMACEN_UPDATE  (nuevo: cambia la cantidad de uno
--                                        existente, ajustando stock y
--                                        acumulado)
-- =====================================================================

-- Helper interno: calcula el delta del acumulado según TIPO_DOC_MOV/TIPO_MOV
-- y aplica un UPDATE al stock con un multiplicador (+1 para insert/restore,
-- -1 para delete/reverse).
DROP PROCEDURE IF EXISTS `PRC_FZA_AJUSTAR_ACUMULADO_STK`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_AJUSTAR_ACUMULADO_STK`(
    IN `p_TIPO_DOC_MOV` VARCHAR(20),
    IN `p_TIPO_MOV` VARCHAR(1),
    IN `p_CODIGO_ALM` VARCHAR(10),
    IN `p_CODIGO_UNIDAD` VARCHAR(50),
    IN `p_CANTIDAD` DECIMAL(19,6),
    IN `p_VALOR` DECIMAL(19,6),
    IN `p_MULT` INT  -- +1 para sumar, -1 para restar
)
BEGIN
    DECLARE v_signo INT;
    SET v_signo = IF(p_TIPO_MOV = 'E', 1, -1);
    UPDATE fza_articulos_stockactual SET
        CANTIDAD_STK      = CANTIDAD_STK      + (v_signo * p_MULT * p_CANTIDAD),
        VALOR_TOTAL_STK   = VALOR_TOTAL_STK   + (v_signo * p_MULT * p_VALOR),
        PRECIO_MEDIO_STK  = IF(CANTIDAD_STK > 0, VALOR_TOTAL_STK / CANTIDAD_STK, 0),
        INSTANTE_MODIF    = NOW(),
        CANTIDAD_ENT_COMPRA_STK = CANTIDAD_ENT_COMPRA_STK +
            IF(p_TIPO_DOC_MOV='AC' AND p_TIPO_MOV='E', p_MULT * p_CANTIDAD, 0),
        CANTIDAD_ENT_TRASPASO_STK = CANTIDAD_ENT_TRASPASO_STK +
            IF(p_TIPO_DOC_MOV IN ('TR','AT','TA') AND p_TIPO_MOV='E',
               p_MULT * p_CANTIDAD, 0),
        CANTIDAD_SAL_TRASPASO_STK = CANTIDAD_SAL_TRASPASO_STK +
            IF(p_TIPO_DOC_MOV IN ('TR','AT','TA') AND p_TIPO_MOV='S',
               p_MULT * p_CANTIDAD, 0),
        CANTIDAD_ENT_DEPOSITO_STK = CANTIDAD_ENT_DEPOSITO_STK +
            IF(p_TIPO_DOC_MOV='DP' AND p_TIPO_MOV='E', p_MULT * p_CANTIDAD, 0),
        CANTIDAD_SAL_DEPOSITO_STK = CANTIDAD_SAL_DEPOSITO_STK +
            IF(p_TIPO_DOC_MOV='DP' AND p_TIPO_MOV='S', p_MULT * p_CANTIDAD, 0),
        CANTIDAD_SAL_VENTA_STK = CANTIDAD_SAL_VENTA_STK +
            IF(p_TIPO_DOC_MOV IN ('VE','FC') AND p_TIPO_MOV='S', p_MULT * p_CANTIDAD, 0),
        CANTIDAD_ENT_REGULAR_STK = CANTIDAD_ENT_REGULAR_STK +
            IF(p_TIPO_DOC_MOV='IN' AND p_TIPO_MOV='E', p_MULT * p_CANTIDAD, 0),
        CANTIDAD_SAL_ALBVENTA_STK = CANTIDAD_SAL_ALBVENTA_STK +
            IF(p_TIPO_DOC_MOV='AV' AND p_TIPO_MOV='S', p_MULT * p_CANTIDAD, 0),
        CANTIDAD_ENT_ALBENTRADA_STK = CANTIDAD_ENT_ALBENTRADA_STK +
            IF(p_TIPO_DOC_MOV='AE' AND p_TIPO_MOV='E', p_MULT * p_CANTIDAD, 0)
    WHERE CODIGO_ALM_STK = p_CODIGO_ALM
      AND CODIGO_UNIDAD_STK = p_CODIGO_UNIDAD;
END ;;
DELIMITER ;

-- DELETE por NUMERO_MOV: borra físicamente y revierte stock + acumulado.
DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE`(
    IN `p_NUMERO_MOV` VARCHAR(20)
)
BEGIN
    DECLARE v_TIPO_DOC VARCHAR(20);
    DECLARE v_TIPO_MOV VARCHAR(1);
    DECLARE v_ALM VARCHAR(10);
    DECLARE v_UNI VARCHAR(50);
    DECLARE v_CANT DECIMAL(19,6);
    DECLARE v_VALOR DECIMAL(19,6);
    SELECT TIPO_DOC_MOV, TIPO_MOV, CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
           CANTIDAD_MOV, TOTAL_COSTE_MOV
      INTO v_TIPO_DOC, v_TIPO_MOV, v_ALM, v_UNI, v_CANT, v_VALOR
      FROM fza_movimientos_almacen
     WHERE NUMERO_MOV = p_NUMERO_MOV
       AND ESACTIVO_MOV = 'S'
     LIMIT 1;
    IF v_UNI IS NOT NULL THEN
        CALL PRC_FZA_AJUSTAR_ACUMULADO_STK(
            v_TIPO_DOC, v_TIPO_MOV, v_ALM, v_UNI, v_CANT, v_VALOR, -1);
        DELETE FROM fza_movimientos_almacen WHERE NUMERO_MOV = p_NUMERO_MOV;
    END IF;
END ;;
DELIMITER ;

-- DELETE por documento: revierte todos los movimientos de un documento
-- (todas las líneas). Útil al borrar un albarán / factura / traspaso.
DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC`(
    IN `p_TIPO_DOC_MOV` VARCHAR(20),
    IN `p_SERIE_DOC_MOV` VARCHAR(20),
    IN `p_NRO_DOC_MOV` VARCHAR(20)
)
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_NUM VARCHAR(20);
    DECLARE cur CURSOR FOR
        SELECT NUMERO_MOV
          FROM fza_movimientos_almacen
         WHERE TIPO_DOC_MOV   = p_TIPO_DOC_MOV
           AND SERIE_DOC_MOV  = p_SERIE_DOC_MOV
           AND NUMERO_DOC_MOV = p_NRO_DOC_MOV
           AND ESACTIVO_MOV   = 'S';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    OPEN cur;
    bucle: LOOP
        FETCH cur INTO v_NUM;
        IF v_done = 1 THEN
            LEAVE bucle;
        END IF;
        CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE(v_NUM);
    END LOOP;
    CLOSE cur;
END ;;
DELIMITER ;

-- UPDATE de cantidad: ajusta el movimiento existente y propaga el delta
-- al stock y al acumulado correspondiente. Útil para corregir cantidades
-- sin tener que borrar y reinsertar.
DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_UPDATE`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_UPDATE`(
    IN `p_NUMERO_MOV` VARCHAR(20),
    IN `p_NUEVA_CANTIDAD` DECIMAL(19,6),
    IN `p_NUEVO_PRECIO` DECIMAL(19,6),
    IN `p_USUARIO` VARCHAR(100)
)
BEGIN
    DECLARE v_TIPO_DOC VARCHAR(20);
    DECLARE v_TIPO_MOV VARCHAR(1);
    DECLARE v_ALM VARCHAR(10);
    DECLARE v_UNI VARCHAR(50);
    DECLARE v_CANT_ANT DECIMAL(19,6);
    DECLARE v_VALOR_ANT DECIMAL(19,6);
    DECLARE v_VALOR_NUEVO DECIMAL(19,6);
    SELECT TIPO_DOC_MOV, TIPO_MOV, CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
           CANTIDAD_MOV, TOTAL_COSTE_MOV
      INTO v_TIPO_DOC, v_TIPO_MOV, v_ALM, v_UNI, v_CANT_ANT, v_VALOR_ANT
      FROM fza_movimientos_almacen
     WHERE NUMERO_MOV = p_NUMERO_MOV
       AND ESACTIVO_MOV = 'S'
     LIMIT 1;
    IF v_UNI IS NOT NULL THEN
        SET v_VALOR_NUEVO = p_NUEVA_CANTIDAD * p_NUEVO_PRECIO;
        -- Revertir el movimiento original del stock
        CALL PRC_FZA_AJUSTAR_ACUMULADO_STK(
            v_TIPO_DOC, v_TIPO_MOV, v_ALM, v_UNI, v_CANT_ANT, v_VALOR_ANT, -1);
        -- Aplicar el nuevo
        CALL PRC_FZA_AJUSTAR_ACUMULADO_STK(
            v_TIPO_DOC, v_TIPO_MOV, v_ALM, v_UNI, p_NUEVA_CANTIDAD, v_VALOR_NUEVO, +1);
        -- Actualizar el registro del movimiento
        UPDATE fza_movimientos_almacen
           SET CANTIDAD_MOV = p_NUEVA_CANTIDAD,
               PRECIO_COSTE_UNITARIO_MOV = p_NUEVO_PRECIO,
               PRECIO_MEDIO_MOV          = p_NUEVO_PRECIO,
               TOTAL_COSTE_MOV           = v_VALOR_NUEVO,
               USUARIO_MODIF             = p_USUARIO,
               INSTANTE_MODIF            = NOW()
         WHERE NUMERO_MOV = p_NUMERO_MOV;
    END IF;
END ;;
DELIMITER ;
