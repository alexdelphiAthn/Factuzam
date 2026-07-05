-- =============================================================================
-- Optimizar recalculo PMP en aplicar / eliminar regularizacion de inventario
-- =============================================================================
-- Sustituye el cursor anidado de SP_RECALCULAR_PMP_SKU_ALMACEN +
-- PRC_FZA_INVENTARIOS_ELIMINAR_REGUL + PRC_FZA_INVENTARIOS_APLICAR por una
-- pasada en conjunto (set-based) sobre todos los SKUs afectados.
--
-- Antes:
--   PRC_FZA_INVENTARIOS_ELIMINAR_REGUL recorre los SKUs afectados con cursor
--   y por cada uno llama a SP_RECALCULAR_PMP_SKU_ALMACEN, que a su vez abre
--   otro cursor y lanza N UPDATE individuales (uno por movimiento) +
--   1 INSERT...ON DUPLICATE en stockactual. Para 50 SKUs con 200 movs cada
--   uno son ~10.000 statements y otros tantos X-locks `FOR UPDATE`.
--
-- Despues:
--   SP_RECALCULAR_PMP_LOTE_ALMACEN procesa todos los SKUs registrados en una
--   tabla temporal `tmp_skus_recalc` con 4 statements grandes:
--     1) volcado ordenado a `tmp_movs_ord` (PK auto-incremental garantiza el
--        orden secuencial),
--     2) UPDATE en lote con variables de sesion para el PMP acumulado
--        (reset al cambiar de SKU),
--     3) UPDATE...JOIN para volcar PRECIO_MEDIO_MOV / TOTAL_COSTE_MOV,
--     4) agregacion de acumulados por subtipo desde movimientos activos,
--     5) INSERT...ON DUPLICATE KEY UPDATE en fza_articulos_stockactual desde
--        el ultimo movimiento de cada SKU.
--
-- SP_RECALCULAR_PMP_SKU_ALMACEN se conserva con la misma firma como wrapper
-- (algun llamante futuro podria seguir esperando esa interfaz; hoy solo lo
-- usan los dos PRC_FZA_INVENTARIOS_*, que pasan a llamar directamente al
-- lote, pero el wrapper sigue ahi por compatibilidad).
--
-- Comportamiento funcional identico al original:
--   - Misma formula de PMP (entrada con stock<=0: pmp=coste; entrada con
--     stock>0: media ponderada; salida: pmp invariable).
--   - Mismo TOTAL_COSTE_MOV (cant*coste en entradas, cant*pmp en salidas).
--   - Mismo stockactual final por SKU.
--   - SKUs cuyos movs se han borrado por completo quedan a 0 en stockactual.
--
-- Idempotente: solo recrea procedimientos. `DROP PROCEDURE IF EXISTS` antes
-- de cada `CREATE PROCEDURE`. No cambia esquema. Se puede ejecutar varias
-- veces sin efectos secundarios.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SP_RECALCULAR_PMP_LOTE_ALMACEN
-- -----------------------------------------------------------------------------
-- Recalcula PMP y stockactual de todos los SKUs presentes en la tabla
-- temporal `tmp_skus_recalc(sku VARCHAR(50) PRIMARY KEY)`, que el llamante
-- debe crear y poblar antes de invocar este procedimiento.
--
-- El procedimiento no abre transaccion: respeta la transaccion del llamante
-- (PRC_FZA_INVENTARIOS_APLICAR / PRC_FZA_INVENTARIOS_ELIMINAR_REGUL ya la
-- abren).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `SP_RECALCULAR_PMP_LOTE_ALMACEN`;
DELIMITER ;;
CREATE PROCEDURE `SP_RECALCULAR_PMP_LOTE_ALMACEN`(
    IN p_EMPRESA VARCHAR(20),
    IN p_ALMACEN VARCHAR(10)
)
BEGIN
    /* 1. Tabla con todos los movs de los SKUs afectados, ordenados.
       El INSERT...SELECT ORDER BY garantiza el orden de RN secuencial
       (RN es AUTO_INCREMENT como PK clustered en InnoDB). */
    DROP TEMPORARY TABLE IF EXISTS tmp_movs_ord;
    CREATE TEMPORARY TABLE tmp_movs_ord (
        RN                        BIGINT          NOT NULL AUTO_INCREMENT,
        NUMERO_MOV                VARCHAR(20)     NOT NULL,
        TIPO_DOC_MOV              VARCHAR(20)     NOT NULL,
        CODIGO_UNIDAD_MOV         VARCHAR(50)     NOT NULL,
        TIPO_MOV                  VARCHAR(1)      NOT NULL,
        CANTIDAD_MOV              DECIMAL(19,6)   NOT NULL,
        PRECIO_COSTE_UNITARIO_MOV DECIMAL(19,6)   NOT NULL,
        PMP_NUEVO                 DECIMAL(19,6)   NOT NULL DEFAULT 0,
        STOCK_NUEVO               DECIMAL(19,6)   NOT NULL DEFAULT 0,
        COSTE_NUEVO               DECIMAL(19,6)   NOT NULL DEFAULT 0,
        SKU_PREV                  VARCHAR(50)     NULL,
        PRIMARY KEY (RN),
        KEY IDX_NUMMOV (NUMERO_MOV),
        KEY IDX_SKU    (CODIGO_UNIDAD_MOV)
    ) ENGINE=InnoDB;

    INSERT INTO tmp_movs_ord
        (NUMERO_MOV, TIPO_DOC_MOV, CODIGO_UNIDAD_MOV, TIPO_MOV, CANTIDAD_MOV,
         PRECIO_COSTE_UNITARIO_MOV)
    SELECT m.NUMERO_MOV,
           m.TIPO_DOC_MOV,
           m.CODIGO_UNIDAD_MOV,
           m.TIPO_MOV,
           IFNULL(m.CANTIDAD_MOV, 0),
           IFNULL(m.PRECIO_COSTE_UNITARIO_MOV, 0)
      FROM fza_movimientos_almacen m
      JOIN tmp_skus_recalc s ON s.sku = m.CODIGO_UNIDAD_MOV
     WHERE m.CODIGO_ALM_MOV = p_ALMACEN
       AND m.ESACTIVO_MOV = 'S'
     ORDER BY m.CODIGO_UNIDAD_MOV, m.FECHA_MOV, m.INSTANTE_ALTA;

    /* 2. Calculo acumulado por SKU con variables de sesion. El ORDER BY RN
       fuerza el barrido secuencial por la PK clustered. Las asignaciones del
       SET se evaluan de izquierda a derecha: primero PMP_NUEVO (usa @stock y
       @pmp todavia con valor de la fila anterior + @sku_prev de la fila
       anterior para detectar cambio), luego COSTE_NUEVO (usa el @pmp recien
       calculado), luego STOCK_NUEVO (actualiza @stock), y al final SKU_PREV
       actualiza @sku_prev para la siguiente fila. */
    SET @sku_prev := '';
    SET @stock    := CAST(0 AS DECIMAL(19,6));
    SET @pmp      := CAST(0 AS DECIMAL(19,6));

    UPDATE tmp_movs_ord
       SET PMP_NUEVO = (
               @pmp := IF(
                   @sku_prev <> CODIGO_UNIDAD_MOV,
                   /* Cambio de SKU: empezamos desde cero */
                   IF(TIPO_MOV = 'E', PRECIO_COSTE_UNITARIO_MOV, 0),
                   /* Mismo SKU que la fila anterior */
                   IF(TIPO_MOV = 'E',
                       IF(@stock <= 0,
                           PRECIO_COSTE_UNITARIO_MOV,
                           ((@stock * @pmp)
                              + (CANTIDAD_MOV * PRECIO_COSTE_UNITARIO_MOV))
                            / (@stock + CANTIDAD_MOV)),
                       @pmp
                   )
               )
           ),
           COSTE_NUEVO = IF(TIPO_MOV = 'E',
                            CANTIDAD_MOV * PRECIO_COSTE_UNITARIO_MOV,
                            CANTIDAD_MOV * @pmp),
           STOCK_NUEVO = (
               @stock := IF(
                   @sku_prev <> CODIGO_UNIDAD_MOV,
                   /* Cambio de SKU: stock empieza en 0 y se suma este mov */
                   IF(TIPO_MOV = 'E', CANTIDAD_MOV, -CANTIDAD_MOV),
                   IF(TIPO_MOV = 'E', @stock + CANTIDAD_MOV,
                                       @stock - CANTIDAD_MOV)
               )
           ),
           SKU_PREV = (@sku_prev := CODIGO_UNIDAD_MOV)
     ORDER BY RN;

    /* 3. Volcado en lote a fza_movimientos_almacen. Un solo UPDATE...JOIN
       toma X-locks sobre los movs afectados y los libera al terminar. */
    UPDATE fza_movimientos_almacen m
      JOIN tmp_movs_ord t ON t.NUMERO_MOV = m.NUMERO_MOV
       SET m.PRECIO_MEDIO_MOV = t.PMP_NUEVO,
           m.TOTAL_COSTE_MOV  = t.COSTE_NUEVO;

    /* 4. Stock final y acumulados por SKU: el ultimo mov (RN maximo)
       tiene el stock y el PMP al final del historico. Volcamos tambien
       los acumulados por subtipo a stockactual. */
    INSERT INTO fza_articulos_stockactual
        (CODIGO_ALM_STK, CODIGO_UNIDAD_STK,
         CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTE_MODIF,
         CANTIDAD_ENT_COMPRA_STK,
         CANTIDAD_ENT_TRASPASO_STK, CANTIDAD_SAL_TRASPASO_STK,
         CANTIDAD_ENT_DEPOSITO_STK, CANTIDAD_SAL_DEPOSITO_STK,
         CANTIDAD_SAL_VENTA_STK,
         CANTIDAD_ENT_REGULAR_STK,
         CANTIDAD_SAL_ALBVENTA_STK,
         CANTIDAD_ENT_ALBENTRADA_STK)
    SELECT p_ALMACEN,
           t.CODIGO_UNIDAD_MOV,
           t.STOCK_NUEVO,
           IF(t.STOCK_NUEVO > 0, t.STOCK_NUEVO * t.PMP_NUEVO, 0),
           IF(t.STOCK_NUEVO > 0, t.PMP_NUEVO, 0),
           NOW(),
           IFNULL(ac.CANTIDAD_ENT_COMPRA_STK, 0),
           IFNULL(ac.CANTIDAD_ENT_TRASPASO_STK, 0),
           IFNULL(ac.CANTIDAD_SAL_TRASPASO_STK, 0),
           IFNULL(ac.CANTIDAD_ENT_DEPOSITO_STK, 0),
           IFNULL(ac.CANTIDAD_SAL_DEPOSITO_STK, 0),
           IFNULL(ac.CANTIDAD_SAL_VENTA_STK, 0),
           IFNULL(ac.CANTIDAD_ENT_REGULAR_STK, 0),
           IFNULL(ac.CANTIDAD_SAL_ALBVENTA_STK, 0),
           IFNULL(ac.CANTIDAD_ENT_ALBENTRADA_STK, 0)
      FROM tmp_movs_ord t
      JOIN (
            SELECT CODIGO_UNIDAD_MOV, MAX(RN) AS RN_MAX
              FROM tmp_movs_ord
             GROUP BY CODIGO_UNIDAD_MOV
           ) ult
        ON ult.CODIGO_UNIDAD_MOV = t.CODIGO_UNIDAD_MOV
       AND ult.RN_MAX             = t.RN
      LEFT JOIN (
            SELECT CODIGO_UNIDAD_MOV,
                   SUM(IF(TIPO_DOC_MOV = 'AC' AND TIPO_MOV = 'E',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_ENT_COMPRA_STK,
                   SUM(IF(TIPO_DOC_MOV IN ('TR', 'AT', 'TA')
                          AND TIPO_MOV = 'E',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_ENT_TRASPASO_STK,
                   SUM(IF(TIPO_DOC_MOV IN ('TR', 'AT', 'TA')
                          AND TIPO_MOV = 'S',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_SAL_TRASPASO_STK,
                   SUM(IF(TIPO_DOC_MOV = 'DP' AND TIPO_MOV = 'E',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_ENT_DEPOSITO_STK,
                   SUM(IF(TIPO_DOC_MOV = 'DP' AND TIPO_MOV = 'S',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_SAL_DEPOSITO_STK,
                   SUM(IF(TIPO_DOC_MOV IN ('VE', 'FC') AND TIPO_MOV = 'S',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_SAL_VENTA_STK,
                   SUM(IF(TIPO_DOC_MOV = 'IN' AND TIPO_MOV = 'E',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_ENT_REGULAR_STK,
                   SUM(IF(TIPO_DOC_MOV = 'AV' AND TIPO_MOV = 'S',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_SAL_ALBVENTA_STK,
                   SUM(IF(TIPO_DOC_MOV = 'AE' AND TIPO_MOV = 'E',
                          CANTIDAD_MOV, 0)) AS CANTIDAD_ENT_ALBENTRADA_STK
              FROM tmp_movs_ord
             GROUP BY CODIGO_UNIDAD_MOV
           ) ac
        ON ac.CODIGO_UNIDAD_MOV = t.CODIGO_UNIDAD_MOV
     ON DUPLICATE KEY UPDATE
        CANTIDAD_STK     = VALUES(CANTIDAD_STK),
        VALOR_TOTAL_STK  = VALUES(VALOR_TOTAL_STK),
        PRECIO_MEDIO_STK = VALUES(PRECIO_MEDIO_STK),
        INSTANTE_MODIF   = NOW(),
        CANTIDAD_ENT_COMPRA_STK   = VALUES(CANTIDAD_ENT_COMPRA_STK),
        CANTIDAD_ENT_TRASPASO_STK = VALUES(CANTIDAD_ENT_TRASPASO_STK),
        CANTIDAD_SAL_TRASPASO_STK = VALUES(CANTIDAD_SAL_TRASPASO_STK),
        CANTIDAD_ENT_DEPOSITO_STK = VALUES(CANTIDAD_ENT_DEPOSITO_STK),
        CANTIDAD_SAL_DEPOSITO_STK = VALUES(CANTIDAD_SAL_DEPOSITO_STK),
        CANTIDAD_SAL_VENTA_STK    = VALUES(CANTIDAD_SAL_VENTA_STK),
        CANTIDAD_ENT_REGULAR_STK  = VALUES(CANTIDAD_ENT_REGULAR_STK),
        CANTIDAD_SAL_ALBVENTA_STK = VALUES(CANTIDAD_SAL_ALBVENTA_STK),
        CANTIDAD_ENT_ALBENTRADA_STK =
            VALUES(CANTIDAD_ENT_ALBENTRADA_STK);

    /* 5. SKUs sin movs sobrevivientes (todos sus movs estaban en la
       regularizacion borrada): el stockactual queda a 0. */
    INSERT INTO fza_articulos_stockactual
        (CODIGO_ALM_STK, CODIGO_UNIDAD_STK,
         CANTIDAD_STK, VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTE_MODIF,
         CANTIDAD_ENT_COMPRA_STK,
         CANTIDAD_ENT_TRASPASO_STK, CANTIDAD_SAL_TRASPASO_STK,
         CANTIDAD_ENT_DEPOSITO_STK, CANTIDAD_SAL_DEPOSITO_STK,
         CANTIDAD_SAL_VENTA_STK,
         CANTIDAD_ENT_REGULAR_STK,
         CANTIDAD_SAL_ALBVENTA_STK,
         CANTIDAD_ENT_ALBENTRADA_STK)
    SELECT p_ALMACEN, s.sku, 0, 0, 0, NOW(), 0, 0, 0, 0, 0, 0, 0, 0, 0
      FROM tmp_skus_recalc s
      LEFT JOIN tmp_movs_ord t ON t.CODIGO_UNIDAD_MOV = s.sku
     WHERE t.CODIGO_UNIDAD_MOV IS NULL
     ON DUPLICATE KEY UPDATE
        CANTIDAD_STK     = 0,
        VALOR_TOTAL_STK  = 0,
        PRECIO_MEDIO_STK = 0,
        INSTANTE_MODIF   = NOW(),
        CANTIDAD_ENT_COMPRA_STK = 0,
        CANTIDAD_ENT_TRASPASO_STK = 0,
        CANTIDAD_SAL_TRASPASO_STK = 0,
        CANTIDAD_ENT_DEPOSITO_STK = 0,
        CANTIDAD_SAL_DEPOSITO_STK = 0,
        CANTIDAD_SAL_VENTA_STK = 0,
        CANTIDAD_ENT_REGULAR_STK = 0,
        CANTIDAD_SAL_ALBVENTA_STK = 0,
        CANTIDAD_ENT_ALBENTRADA_STK = 0;

    DROP TEMPORARY TABLE IF EXISTS tmp_movs_ord;
END ;;
DELIMITER ;


-- -----------------------------------------------------------------------------
-- SP_RECALCULAR_PMP_SKU_ALMACEN (compat: misma firma, delega en el lote)
-- -----------------------------------------------------------------------------
-- Se mantiene por si algun futuro llamante espera la interfaz por SKU.
-- Hoy ningun .pas la usa directamente.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `SP_RECALCULAR_PMP_SKU_ALMACEN`;
DELIMITER ;;
CREATE PROCEDURE `SP_RECALCULAR_PMP_SKU_ALMACEN`(
    IN p_CodigoEmpresa VARCHAR(20),
    IN p_CodigoSKU     VARCHAR(50),
    IN p_CodigoAlmacen VARCHAR(10)
)
BEGIN
    DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc;
    CREATE TEMPORARY TABLE tmp_skus_recalc (
        sku VARCHAR(50) NOT NULL PRIMARY KEY
    ) ENGINE=InnoDB;

    INSERT INTO tmp_skus_recalc (sku) VALUES (p_CodigoSKU);

    CALL SP_RECALCULAR_PMP_LOTE_ALMACEN(p_CodigoEmpresa, p_CodigoAlmacen);

    DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc;
END ;;
DELIMITER ;


-- -----------------------------------------------------------------------------
-- PRC_FZA_INVENTARIOS_ELIMINAR_REGUL (reescrito: una sola llamada al lote)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_ELIMINAR_REGUL`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_INVENTARIOS_ELIMINAR_REGUL`(
    IN p_EMPRESA VARCHAR(10),
    IN p_ALMACEN VARCHAR(10),
    IN p_SERIE   VARCHAR(20),
    IN p_NRO     VARCHAR(20),
    IN p_USUARIO VARCHAR(100)
)
BEGIN
    DECLARE v_ESTADO VARCHAR(20);
    DECLARE v_PATRON VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    /* 1. Verificar estado del inventario (debe estar APLICADO). */
    SELECT ESTADO_INV INTO v_ESTADO
      FROM fza_inventarios
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO
       FOR UPDATE;

    IF v_ESTADO IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
            'Error: el inventario no existe.';
    END IF;

    IF v_ESTADO <> 'APLICADO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
            'Error: el inventario debe estar APLICADO para eliminar la regularizacion.';
    END IF;

    SET v_PATRON = CONCAT('IV-', p_NRO, '-%');

    /* 2. Recoger en una temp los SKUs afectados ANTES de borrar. La temp
       sirve de input a SP_RECALCULAR_PMP_LOTE_ALMACEN. */
    DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc;
    CREATE TEMPORARY TABLE tmp_skus_recalc (
        sku VARCHAR(50) NOT NULL PRIMARY KEY
    ) ENGINE=InnoDB;

    INSERT INTO tmp_skus_recalc (sku)
    SELECT DISTINCT CODIGO_UNIDAD_MOV
      FROM fza_movimientos_almacen
     WHERE CODIGO_ALM_MOV = p_ALMACEN
       AND NUMERO_MOV LIKE v_PATRON;

    /* 3. Borrar los movimientos generados por el inventario. NUMERO_MOV es
       la PK; el LIKE con prefijo constante permite al optimizador usar la
       PK directamente. El AND CODIGO_ALM_MOV se mantiene por seguridad (un
       inventario solo genera movs en su almacen). */
    DELETE FROM fza_movimientos_almacen
     WHERE CODIGO_ALM_MOV = p_ALMACEN
       AND NUMERO_MOV LIKE v_PATRON;

    /* 4. Recalcular PMP y stockactual de todos los SKUs afectados en
       UNA sola pasada. */
    CALL SP_RECALCULAR_PMP_LOTE_ALMACEN(p_EMPRESA, p_ALMACEN);

    /* 5. Marcar el inventario como ABIERTO de nuevo. */
    UPDATE fza_inventarios
       SET ESTADO_INV     = 'ABIERTO',
           USUARIO_MODIF  = p_USUARIO,
           INSTANTE_MODIF = NOW()
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO;

    DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc;

    COMMIT;
END ;;
DELIMITER ;


-- -----------------------------------------------------------------------------
-- PRC_FZA_INVENTARIOS_APLICAR (reescrito: una sola llamada al lote al final)
-- -----------------------------------------------------------------------------
-- Conserva el cursor sobre lineas del inventario para generar los
-- movimientos S/E (esa parte sigue siendo lineal en numero de lineas, no de
-- movimientos historicos, asi que no es el cuello de botella). Lo que se
-- elimina es la llamada a SP_RECALCULAR_PMP_SKU_ALMACEN dentro del bucle.
-- Tras insertar todos los movimientos, una unica llamada al lote recalcula
-- el PMP de todos los SKUs tocados.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_APLICAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_INVENTARIOS_APLICAR`(
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

    /* fza_inventarios_lineas.LINEA_INVLIN es VARCHAR(8) (formato
       '00000001'...). El SP original tenia VARCHAR(4) aqui, lo que
       provocaba "#22001 Data too long for column 'v_LINEA'" en el FETCH
       cuando el contador de linea pasaba de 9999. */
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

    /* Temp para recolectar los SKUs tocados durante la generacion de movs.
       Se rellena dentro del bucle y se consume al final con una sola
       llamada al recalculo en lote. */
    DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc;
    CREATE TEMPORARY TABLE tmp_skus_recalc (
        sku VARCHAR(50) NOT NULL PRIMARY KEY
    ) ENGINE=InnoDB;

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

        /* Anotamos el SKU para el recalculo en lote. INSERT IGNORE evita
           duplicados si varias lineas tocan el mismo SKU. */
        INSERT IGNORE INTO tmp_skus_recalc (sku) VALUES (v_SKU);

    END LOOP;

    CLOSE cur_lineas;

    /* Recalculo set-based sobre todos los SKUs tocados. Reemplaza la
       llamada SP_RECALCULAR_PMP_SKU_ALMACEN por linea del cursor. */
    CALL SP_RECALCULAR_PMP_LOTE_ALMACEN(p_EMPRESA, p_ALMACEN);

    UPDATE fza_inventarios
       SET ESTADO_INV     = 'APLICADO',
           USUARIO_MODIF  = p_USUARIO,
           INSTANTE_MODIF = NOW()
     WHERE CODIGO_EMP_INV = p_EMPRESA
       AND CODIGO_ALM_INV = p_ALMACEN
       AND SERIE_INV      = p_SERIE
       AND NUMERO_INV     = p_NRO;

    DROP TEMPORARY TABLE IF EXISTS tmp_skus_recalc;

    COMMIT;
END ;;
DELIMITER ;
