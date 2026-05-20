-- =============================================================================
-- Fix v_LINEA VARCHAR(4) -> VARCHAR(8) en las SPs de regularizacion
-- =============================================================================
-- Companero de widen_linea_invlin.sql. Aquel ampliaba la columna
-- fza_inventarios_lineas.LINEA_INVLIN a varchar(8) y el migrador empezo
-- a generar lineas con Format('%.8d', ...). Pero las stored procedures
-- de regularizacion seguian con:
--
--     DECLARE v_LINEA VARCHAR(4);
--
-- El FETCH del cursor trunca silenciosamente '00000001' -> '0000'.
-- Consecuencias:
--   1. PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO: el UPDATE final
--      "WHERE LINEA_INVLIN = v_LINEA" no matchea ninguna fila, asi que
--      ni CANTIDAD_TEORICA, ni DIFERENCIA, ni TOTAL_COSTE_DIFERENCIA se
--      actualizan jamas.
--   2. PRC_FZA_INVENTARIOS_APLICAR (que llama a la anterior) cree que
--      ninguna linea tiene diferencia, ejecuta la purga
--      (CANTIDAD_DIFERENCIA = 0 AND TOTAL_COSTE = 0) y deja el
--      inventario sin lineas, marca ESTADO_INV = 'APLICADO' y nunca
--      genera movimientos en el Kardex.
--
-- Sintoma percibido: "regularizar no hace nada, el inventario pasa a
-- APLICADO sin generar movimientos y las lineas desaparecen".
--
-- Recreamos ambas SPs identicas a las del dump, cambiando solo el ancho
-- de v_LINEA a VARCHAR(8). DROP IF EXISTS las hace idempotentes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO`;
DELIMITER ;;
CREATE  PROCEDURE `PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO`(
    IN p_EMPRESA VARCHAR(10),
    IN p_ALMACEN VARCHAR(10),
    IN p_SERIE   VARCHAR(20),
    IN p_NRO     VARCHAR(20),
    IN p_USUARIO VARCHAR(100)
)
BEGIN
    DECLARE v_DONE INT DEFAULT FALSE;
    DECLARE v_ESTADO VARCHAR(20);
    DECLARE v_FECHA_CABECERA DATETIME;
    DECLARE v_FECHA_DEFECTO  DATETIME;

    DECLARE v_LINEA          VARCHAR(8);
    DECLARE v_SKU            VARCHAR(50);
    DECLARE v_FISICA         DECIMAL(19,6);
    DECLARE v_PMP_NUEVO      DECIMAL(19,6);
    DECLARE v_FECHA_RECUENTO DATETIME;

    DECLARE v_STOCK_HIST     DECIMAL(19,6);
    DECLARE v_PMP_HIST       DECIMAL(19,6);
    DECLARE v_DIF_CANTIDAD   DECIMAL(19,6);
    DECLARE v_TOTAL_COSTE_DIF DECIMAL(19,6);

    DECLARE cur_lineas CURSOR FOR
        SELECT LINEA_INVLIN,
               CODIGO_UNIDAD_INVLIN,
               CANTIDAD_FISICA_INVLIN,
               PRECIO_MEDIO_NUEVO_INVLIN,
               FECHA_RECUENTO_INVLIN
          FROM fza_inventarios_lineas
         WHERE CODIGO_EMP_INVLIN = p_EMPRESA
           AND CODIGO_ALM_INVLIN = p_ALMACEN
           AND SERIE_INV_INVLIN  = p_SERIE
           AND NUMERO_INV_INVLIN = p_NRO;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_DONE = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT ESTADO_INV, FECHA_INV
      INTO v_ESTADO, v_FECHA_CABECERA
      FROM fza_inventarios
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO
       FOR UPDATE;

    IF v_ESTADO != 'ABIERTO' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Error: El inventario no esta ABIERTO, no se puede recalcular.';
    END IF;

    SET v_FECHA_DEFECTO = TIMESTAMP(DATE_SUB(DATE(v_FECHA_CABECERA), INTERVAL 1 DAY), '23:59:59');

    OPEN cur_lineas;

    read_loop: LOOP
        FETCH cur_lineas
         INTO v_LINEA, v_SKU, v_FISICA, v_PMP_NUEVO, v_FECHA_RECUENTO;

        IF v_DONE THEN
            LEAVE read_loop;
        END IF;

        IF v_FECHA_RECUENTO IS NULL THEN
            SET v_FECHA_RECUENTO = v_FECHA_DEFECTO;
        END IF;

        SET v_STOCK_HIST = 0;
        SET v_PMP_HIST   = 0;

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;
            SELECT IFNULL(SUM(IF(TIPO_MOV = 'E', CANTIDAD_MOV, -CANTIDAD_MOV)), 0)
              INTO v_STOCK_HIST
              FROM fza_movimientos_almacen
             WHERE CODIGO_ALM_MOV    = p_ALMACEN
               AND CODIGO_UNIDAD_MOV = v_SKU
               AND FECHA_MOV        <= v_FECHA_RECUENTO
               AND ESACTIVO_MOV      = 'S';
        END;

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;
            SELECT IFNULL(PRECIO_MEDIO_MOV, 0)
              INTO v_PMP_HIST
              FROM fza_movimientos_almacen
             WHERE CODIGO_ALM_MOV    = p_ALMACEN
               AND CODIGO_UNIDAD_MOV = v_SKU
               AND FECHA_MOV        <= v_FECHA_RECUENTO
               AND ESACTIVO_MOV      = 'S'
             ORDER BY FECHA_MOV DESC, NUMERO_MOV DESC
             LIMIT 1;
        END;

        SET v_DIF_CANTIDAD = v_FISICA - v_STOCK_HIST;

        IF v_PMP_NUEVO = 0 OR v_PMP_NUEVO IS NULL THEN
            SET v_PMP_NUEVO = v_PMP_HIST;
        END IF;

        SET v_TOTAL_COSTE_DIF = (v_FISICA * v_PMP_NUEVO) - (v_STOCK_HIST * v_PMP_HIST);

        UPDATE fza_inventarios_lineas
           SET CANTIDAD_TEORICA_INVLIN       = v_STOCK_HIST,
               PRECIO_MEDIO_INVLIN           = v_PMP_HIST,
               PRECIO_MEDIO_NUEVO_INVLIN     = v_PMP_NUEVO,
               CANTIDAD_DIFERENCIA_INVLIN    = v_DIF_CANTIDAD,
               TOTAL_COSTE_DIFERENCIA_INVLIN = v_TOTAL_COSTE_DIF,
               FECHA_RECUENTO_INVLIN         = v_FECHA_RECUENTO,
               USUARIO_MODIF                 = p_USUARIO,
               INSTANTE_MODIF                = NOW()
         WHERE CODIGO_EMP_INVLIN = p_EMPRESA
           AND CODIGO_ALM_INVLIN = p_ALMACEN
           AND SERIE_INV_INVLIN  = p_SERIE
           AND NUMERO_INV_INVLIN = p_NRO
           AND LINEA_INVLIN      = v_LINEA;

    END LOOP;

    CLOSE cur_lineas;

    /* NOTA: ya NO borramos lineas sin diferencia aqui. La purga se hace */
    /* en PRC_FZA_INVENTARIOS_APLICAR, justo antes de generar los movimientos. */

    UPDATE fza_inventarios
       SET TOTAL_UNIDADES_DIFERENCIA_INV = (
               SELECT IFNULL(SUM(CANTIDAD_DIFERENCIA_INVLIN), 0)
                 FROM fza_inventarios_lineas
                WHERE CODIGO_EMP_INVLIN = p_EMPRESA
                  AND CODIGO_ALM_INVLIN = p_ALMACEN
                  AND SERIE_INV_INVLIN  = p_SERIE
                  AND NUMERO_INV_INVLIN = p_NRO
           ),
           TOTAL_EUROS_DIFERENCIA_INV = (
               SELECT IFNULL(SUM(TOTAL_COSTE_DIFERENCIA_INVLIN), 0)
                 FROM fza_inventarios_lineas
                WHERE CODIGO_EMP_INVLIN = p_EMPRESA
                  AND CODIGO_ALM_INVLIN = p_ALMACEN
                  AND SERIE_INV_INVLIN  = p_SERIE
                  AND NUMERO_INV_INVLIN = p_NRO
           ),
           USUARIO_MODIF  = p_USUARIO,
           INSTANTE_MODIF = NOW()
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO;

    COMMIT;
END ;;
DELIMITER ;

-- -----------------------------------------------------------------------------
-- PRC_FZA_INVENTARIOS_APLICAR
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_APLICAR`;
DELIMITER ;;
CREATE  PROCEDURE `PRC_FZA_INVENTARIOS_APLICAR`(
    IN p_EMPRESA VARCHAR(10),
    IN p_ALMACEN VARCHAR(10),
    IN p_SERIE   VARCHAR(20),
    IN p_NRO     VARCHAR(20),
    IN p_USUARIO VARCHAR(100)
)
BEGIN
    DECLARE v_DONE   INT DEFAULT FALSE;
    DECLARE v_ESTADO VARCHAR(20);
    DECLARE v_FECHA_CABECERA DATETIME;
    DECLARE v_FECHA_DEFECTO  DATETIME;

    DECLARE v_LINEA     VARCHAR(8);
    DECLARE v_ARTICULO  VARCHAR(20);
    DECLARE v_SKU       VARCHAR(50);
    DECLARE v_TEORICA   DECIMAL(19,6);
    DECLARE v_FISICA    DECIMAL(19,6);
    DECLARE v_PMP_HIST  DECIMAL(19,6);
    DECLARE v_PMP_NUEVO DECIMAL(19,6);
    DECLARE v_FECHA_RECUENTO DATETIME;
    DECLARE v_FECHA_SALIDA   DATETIME;

    DECLARE v_MOV_SALIDA  VARCHAR(20);
    DECLARE v_MOV_ENTRADA VARCHAR(20);

    DECLARE cur_lineas CURSOR FOR
        SELECT l.LINEA_INVLIN,
               l.CODIGO_ART_INVLIN,
               l.CODIGO_UNIDAD_INVLIN,
               l.CANTIDAD_TEORICA_INVLIN,
               l.CANTIDAD_FISICA_INVLIN,
               l.PRECIO_MEDIO_INVLIN,
               l.PRECIO_MEDIO_NUEVO_INVLIN,
               l.FECHA_RECUENTO_INVLIN
          FROM fza_inventarios_lineas l
         WHERE l.CODIGO_EMP_INVLIN = p_EMPRESA
           AND l.CODIGO_ALM_INVLIN = p_ALMACEN
           AND l.SERIE_INV_INVLIN  = p_SERIE
           AND l.NUMERO_INV_INVLIN = p_NRO;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_DONE = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    CALL PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO(
        p_EMPRESA, p_ALMACEN, p_SERIE, p_NRO, p_USUARIO
    );

    START TRANSACTION;

    SELECT ESTADO_INV, FECHA_INV
      INTO v_ESTADO, v_FECHA_CABECERA
      FROM fza_inventarios
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO
       FOR UPDATE;

    IF v_ESTADO != 'ABIERTO' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Error: El inventario ya fue aplicado o esta cancelado.';
    END IF;

    SET v_FECHA_DEFECTO = TIMESTAMP(DATE_SUB(DATE(v_FECHA_CABECERA), INTERVAL 1 DAY), '23:59:59');

    DELETE FROM fza_inventarios_lineas
     WHERE CODIGO_EMP_INVLIN              = p_EMPRESA
       AND CODIGO_ALM_INVLIN              = p_ALMACEN
       AND SERIE_INV_INVLIN               = p_SERIE
       AND NUMERO_INV_INVLIN              = p_NRO
       AND IFNULL(CANTIDAD_DIFERENCIA_INVLIN,    0) = 0
       AND IFNULL(TOTAL_COSTE_DIFERENCIA_INVLIN, 0) = 0;

    UPDATE fza_inventarios
       SET TOTAL_UNIDADES_DIFERENCIA_INV = (
               SELECT IFNULL(SUM(CANTIDAD_DIFERENCIA_INVLIN), 0)
                 FROM fza_inventarios_lineas
                WHERE CODIGO_EMP_INVLIN = p_EMPRESA
                  AND CODIGO_ALM_INVLIN = p_ALMACEN
                  AND SERIE_INV_INVLIN  = p_SERIE
                  AND NUMERO_INV_INVLIN = p_NRO
           ),
           TOTAL_EUROS_DIFERENCIA_INV = (
               SELECT IFNULL(SUM(TOTAL_COSTE_DIFERENCIA_INVLIN), 0)
                 FROM fza_inventarios_lineas
                WHERE CODIGO_EMP_INVLIN = p_EMPRESA
                  AND CODIGO_ALM_INVLIN = p_ALMACEN
                  AND SERIE_INV_INVLIN  = p_SERIE
                  AND NUMERO_INV_INVLIN = p_NRO
           )
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO;

    OPEN cur_lineas;

    read_loop: LOOP
        FETCH cur_lineas
         INTO v_LINEA, v_ARTICULO, v_SKU, v_TEORICA, v_FISICA, v_PMP_HIST, v_PMP_NUEVO, v_FECHA_RECUENTO;

        IF v_DONE THEN
            LEAVE read_loop;
        END IF;

        IF v_FECHA_RECUENTO IS NULL THEN
            SET v_FECHA_RECUENTO = v_FECHA_DEFECTO;
        END IF;

        SET v_FECHA_SALIDA = DATE_SUB(v_FECHA_RECUENTO, INTERVAL 1 SECOND);
        SET v_MOV_SALIDA  = LEFT(CONCAT('IV-', p_NRO, '-', v_LINEA, 'S'), 20);
        SET v_MOV_ENTRADA = LEFT(CONCAT('IV-', p_NRO, '-', v_LINEA, 'E'), 20);

        IF v_TEORICA <> 0 THEN
            CALL PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(
                v_MOV_SALIDA, 'IN', p_SERIE, p_NRO, v_LINEA,
                p_EMPRESA, p_ALMACEN, NULL, v_SKU,
                'S', v_TEORICA, v_PMP_HIST, (v_TEORICA * v_PMP_HIST),
                p_USUARIO, p_ALMACEN, NULL, NULL, NULL, v_ARTICULO
            );
            UPDATE fza_movimientos_almacen
               SET FECHA_MOV = v_FECHA_SALIDA
             WHERE NUMERO_MOV = v_MOV_SALIDA;
        END IF;

        IF v_FISICA > 0 THEN
            CALL PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(
                v_MOV_ENTRADA, 'IN', p_SERIE, p_NRO, v_LINEA,
                p_EMPRESA, p_ALMACEN, NULL, v_SKU,
                'E', v_FISICA, v_PMP_NUEVO, (v_FISICA * v_PMP_NUEVO),
                p_USUARIO, p_ALMACEN, NULL, NULL, NULL, v_ARTICULO
            );
            UPDATE fza_movimientos_almacen
               SET FECHA_MOV = v_FECHA_RECUENTO
             WHERE NUMERO_MOV = v_MOV_ENTRADA;
        END IF;

        CALL SP_RECALCULAR_PMP_SKU_ALMACEN(p_EMPRESA, v_SKU, p_ALMACEN);

    END LOOP;

    CLOSE cur_lineas;

    UPDATE fza_inventarios
       SET ESTADO_INV     = 'APLICADO',
           USUARIO_MODIF  = p_USUARIO,
           INSTANTE_MODIF = NOW()
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO;

    COMMIT;
END ;;
DELIMITER ;
