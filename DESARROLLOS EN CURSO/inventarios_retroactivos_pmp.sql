-- =============================================================================
-- Motor cronologico de stock/PMP e inventarios retroactivos
-- =============================================================================
-- El motor trabaja con la tabla temporal tmp_movimientos_recalculo. Cada
-- clave conserva el primer instante afectado y respeta la transaccion del
-- llamante. AE solo se conserva como compatibilidad historica.

DELIMITER ;;
DROP PROCEDURE IF EXISTS tmp_invlin_pmp_corregido;;
CREATE PROCEDURE tmp_invlin_pmp_corregido()
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'fza_inventarios_lineas'
       AND COLUMN_NAME = 'ESPRECIO_MEDIO_CORREGIDO_INVLIN'
  ) THEN
    ALTER TABLE fza_inventarios_lineas
      ADD COLUMN ESPRECIO_MEDIO_CORREGIDO_INVLIN varchar(1)
      NOT NULL DEFAULT 'N'
      COMMENT 'S si el PMP nuevo fue indicado expresamente';
  END IF;
END;;
DELIMITER ;
CALL tmp_invlin_pmp_corregido();
DROP PROCEDURE tmp_invlin_pmp_corregido;

DELIMITER ;;
DROP PROCEDURE IF EXISTS tmp_mov_linea_ampliar;;
CREATE PROCEDURE tmp_mov_linea_ampliar()
BEGIN
  IF EXISTS (
    SELECT 1
      FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'fza_movimientos_almacen'
       AND COLUMN_NAME = 'LINEA_MOV'
       AND CHARACTER_MAXIMUM_LENGTH < 10
  ) THEN
    ALTER TABLE fza_movimientos_almacen
      MODIFY COLUMN LINEA_MOV varchar(10) NOT NULL
      COMMENT 'Linea del documento origen';
  END IF;
END;;
DELIMITER ;
CALL tmp_mov_linea_ampliar();
DROP PROCEDURE tmp_mov_linea_ampliar;

UPDATE fza_inventarios_lineas l
  JOIN fza_inventarios i
    ON i.CODIGO_EMP_INV = l.CODIGO_EMP_INVLIN
   AND i.CODIGO_ALM_INV = l.CODIGO_ALM_INVLIN
   AND i.SERIE_INV = l.SERIE_INV_INVLIN
   AND i.NUMERO_INV = l.NUMERO_INV_INVLIN
   SET l.ESPRECIO_MEDIO_CORREGIDO_INVLIN =
       IF(ABS(IFNULL(l.PRECIO_MEDIO_NUEVO_INVLIN, 0) -
              IFNULL(l.PRECIO_MEDIO_INVLIN, 0)) > 0.0000005, 'S', 'N')
 WHERE i.ESTADO_INV = 'ABIERTO';

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR`()
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_movimientos_recalculo;
  CREATE TEMPORARY TABLE tmp_movimientos_recalculo (
    empresa varchar(20) NOT NULL DEFAULT '',
    almacen varchar(10) NOT NULL,
    sku varchar(50) NOT NULL,
    instante_desde datetime NOT NULL,
    PRIMARY KEY (almacen, sku)
  ) ENGINE=InnoDB;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR`(
  IN p_EMPRESA varchar(20),
  IN p_ALMACEN varchar(10),
  IN p_SKU varchar(50),
  IN p_INSTANTE_DESDE datetime
)
BEGIN
  IF IFNULL(p_ALMACEN, '') <> '' AND IFNULL(p_SKU, '') <> '' THEN
    INSERT INTO tmp_movimientos_recalculo
      (empresa, almacen, sku, instante_desde)
    VALUES
      (IFNULL(p_EMPRESA, ''), p_ALMACEN, p_SKU,
       IFNULL(p_INSTANTE_DESDE, '1000-01-01 00:00:00'))
    ON DUPLICATE KEY UPDATE
      empresa = IF(empresa = '', VALUES(empresa), empresa),
      instante_desde = LEAST(instante_desde, VALUES(instante_desde));
  END IF;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_DOCUMENTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_DOCUMENTO`(
  IN p_TIPO varchar(5),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20)
)
BEGIN
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT MIN(IFNULL(CODIGO_EMP_MOV, '')),
         CODIGO_ALM_MOV,
         CODIGO_UNIDAD_MOV,
         MIN(IFNULL(FECHA_MOV, '1000-01-01 00:00:00'))
    FROM fza_movimientos_almacen
   WHERE TIPO_DOC_MOV = p_TIPO
     AND SERIE_DOC_MOV = p_SERIE
     AND NUMERO_DOC_MOV = p_NUMERO
   GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV
  ON DUPLICATE KEY UPDATE
    empresa = IF(empresa = '', VALUES(empresa), empresa),
    instante_desde = LEAST(instante_desde, VALUES(instante_desde));
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_OPERACION`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_OPERACION`(
  IN p_OPERACION varchar(20)
)
BEGIN
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT MIN(IFNULL(CODIGO_EMP_MOV, '')),
         CODIGO_ALM_MOV,
         CODIGO_UNIDAD_MOV,
         MIN(IFNULL(FECHA_MOV, '1000-01-01 00:00:00'))
    FROM fza_movimientos_almacen
   WHERE NUMERO_OPERACION_DOC_MOV = p_OPERACION
   GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV
  ON DUPLICATE KEY UPDATE
    empresa = IF(empresa = '', VALUES(empresa), empresa),
    instante_desde = LEAST(instante_desde, VALUES(instante_desde));
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR_COLA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR_COLA`()
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_semillas;
  CREATE TEMPORARY TABLE tmp_recalculo_semillas (
    almacen varchar(10) NOT NULL,
    sku varchar(50) NOT NULL,
    instante_desde datetime NOT NULL,
    stock_semilla decimal(19,6) NOT NULL DEFAULT 0,
    pmp_semilla decimal(19,6) NOT NULL DEFAULT 0,
    PRIMARY KEY (almacen, sku)
  ) ENGINE=InnoDB;
  INSERT INTO tmp_recalculo_semillas
    (almacen, sku, instante_desde, stock_semilla)
  SELECT r.almacen,
         r.sku,
         r.instante_desde,
         IFNULL(SUM(IF(m.TIPO_MOV = 'E', m.CANTIDAD_MOV,
                                         -m.CANTIDAD_MOV)), 0)
    FROM tmp_movimientos_recalculo r
    LEFT JOIN fza_movimientos_almacen m
      ON m.CODIGO_ALM_MOV = r.almacen
     AND m.CODIGO_UNIDAD_MOV = r.sku
     AND m.ESACTIVO_MOV = 'S'
     AND IFNULL(m.FECHA_MOV, '1000-01-01 00:00:00') < r.instante_desde
   GROUP BY r.almacen, r.sku, r.instante_desde;
  UPDATE tmp_recalculo_semillas s
     SET s.pmp_semilla = IFNULL((
       SELECT m.PRECIO_MEDIO_MOV
         FROM fza_movimientos_almacen m
        WHERE m.CODIGO_ALM_MOV = s.almacen
          AND m.CODIGO_UNIDAD_MOV = s.sku
          AND m.ESACTIVO_MOV = 'S'
          AND IFNULL(m.FECHA_MOV, '1000-01-01 00:00:00') <
              s.instante_desde
        ORDER BY IFNULL(m.FECHA_MOV, '1000-01-01 00:00:00') DESC,
                 IFNULL(m.INSTANTE_ALTA, '1000-01-01 00:00:00') DESC,
                 m.NUMERO_MOV DESC
        LIMIT 1), 0);
  DROP TEMPORARY TABLE IF EXISTS tmp_movimientos_ordenados;
  CREATE TEMPORARY TABLE tmp_movimientos_ordenados (
    rn bigint NOT NULL AUTO_INCREMENT,
    numero_mov varchar(20) NOT NULL,
    almacen varchar(10) NOT NULL,
    sku varchar(50) NOT NULL,
    clave varchar(101) NOT NULL,
    tipo_doc varchar(5) NOT NULL,
    tipo_mov varchar(1) NOT NULL,
    cantidad decimal(19,6) NOT NULL,
    coste_unitario decimal(19,6) NOT NULL,
    es_cierre_inventario varchar(1) NOT NULL DEFAULT 'N',
    es_pmp_manual varchar(1) NOT NULL DEFAULT 'N',
    stock_semilla decimal(19,6) NOT NULL,
    pmp_semilla decimal(19,6) NOT NULL,
    stock_nuevo decimal(19,6) NOT NULL DEFAULT 0,
    pmp_nuevo decimal(19,6) NOT NULL DEFAULT 0,
    coste_nuevo decimal(19,6) NOT NULL DEFAULT 0,
    clave_previa varchar(101) NULL,
    PRIMARY KEY (rn),
    KEY idx_movimiento (numero_mov),
    KEY idx_clave (almacen, sku)
  ) ENGINE=InnoDB;
  INSERT INTO tmp_movimientos_ordenados
    (numero_mov, almacen, sku, clave, tipo_doc, tipo_mov, cantidad,
     coste_unitario, es_cierre_inventario, es_pmp_manual,
     stock_semilla, pmp_semilla)
  SELECT m.NUMERO_MOV,
         m.CODIGO_ALM_MOV,
         m.CODIGO_UNIDAD_MOV,
         CONCAT(m.CODIGO_ALM_MOV, CHAR(31), m.CODIGO_UNIDAD_MOV),
         m.TIPO_DOC_MOV,
         m.TIPO_MOV,
         IFNULL(m.CANTIDAD_MOV, 0),
         IFNULL(m.PRECIO_COSTE_UNITARIO_MOV, 0),
         IF(i.NUMERO_INV IS NULL, 'N', 'S'),
         IFNULL(l.ESPRECIO_MEDIO_CORREGIDO_INVLIN, 'N'),
         s.stock_semilla,
         s.pmp_semilla
    FROM fza_movimientos_almacen m
    JOIN tmp_recalculo_semillas s
     ON s.almacen = m.CODIGO_ALM_MOV
     AND s.sku = m.CODIGO_UNIDAD_MOV
    LEFT JOIN fza_inventarios i
      ON m.TIPO_DOC_MOV = 'IN'
     AND i.CODIGO_ALM_INV = m.CODIGO_ALM_MOV
     AND i.SERIE_INV = m.SERIE_DOC_MOV
     AND i.NUMERO_INV = m.NUMERO_DOC_MOV
    LEFT JOIN fza_inventarios_lineas l
      ON l.CODIGO_EMP_INVLIN = i.CODIGO_EMP_INV
     AND l.CODIGO_ALM_INVLIN = i.CODIGO_ALM_INV
     AND l.SERIE_INV_INVLIN = i.SERIE_INV
     AND l.NUMERO_INV_INVLIN = i.NUMERO_INV
     AND CAST(l.LINEA_INVLIN AS UNSIGNED) =
         CAST(m.LINEA_MOV AS UNSIGNED)
   WHERE m.ESACTIVO_MOV = 'S'
     AND IFNULL(m.FECHA_MOV, '1000-01-01 00:00:00') >= s.instante_desde
   ORDER BY m.CODIGO_ALM_MOV,
            m.CODIGO_UNIDAD_MOV,
            IFNULL(m.FECHA_MOV, '1000-01-01 00:00:00'),
            IFNULL(m.INSTANTE_ALTA, '1000-01-01 00:00:00'),
            m.NUMERO_MOV;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_CALCULAR_COLA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_CALCULAR_COLA`()
BEGIN
  SET @clave_previa := '';
  SET @stock := CAST(0 AS DECIMAL(19,6));
  SET @pmp := CAST(0 AS DECIMAL(19,6));
  UPDATE tmp_movimientos_ordenados
     SET cantidad = IF(es_cierre_inventario = 'S' AND tipo_mov = 'S',
           IF(@clave_previa <> clave, stock_semilla, @stock), cantidad),
         coste_unitario = IF(es_cierre_inventario = 'S' AND
                              tipo_mov = 'E' AND es_pmp_manual <> 'S',
           IF(@clave_previa <> clave, pmp_semilla, @pmp), coste_unitario),
         pmp_nuevo = (@pmp := IF(
           @clave_previa <> clave,
           IF(tipo_mov = 'E',
              IF(stock_semilla <= 0, coste_unitario,
                 IF(stock_semilla + cantidad = 0, coste_unitario,
                    ((stock_semilla * pmp_semilla) +
                     (cantidad * coste_unitario)) /
                    (stock_semilla + cantidad))),
              pmp_semilla),
           IF(tipo_mov = 'E',
              IF(@stock <= 0, coste_unitario,
                 IF(@stock + cantidad = 0, coste_unitario,
                    ((@stock * @pmp) + (cantidad * coste_unitario)) /
                    (@stock + cantidad))),
              @pmp))),
         coste_nuevo = IF(tipo_mov = 'E', cantidad * coste_unitario,
                                           cantidad * @pmp),
         stock_nuevo = (@stock := IF(
           @clave_previa <> clave,
           stock_semilla + IF(tipo_mov = 'E', cantidad, -cantidad),
           @stock + IF(tipo_mov = 'E', cantidad, -cantidad))),
         clave_previa = (@clave_previa := clave)
   ORDER BY rn;
  UPDATE fza_movimientos_almacen m
  JOIN tmp_movimientos_ordenados o ON o.numero_mov = m.NUMERO_MOV
     SET m.CANTIDAD_MOV = o.cantidad,
         m.PRECIO_COSTE_UNITARIO_MOV = IF(
           o.es_cierre_inventario = 'S',
           IF(o.tipo_mov = 'S', o.pmp_nuevo, o.coste_unitario),
           m.PRECIO_COSTE_UNITARIO_MOV),
         m.PRECIO_MEDIO_MOV = o.pmp_nuevo,
         m.TOTAL_COSTE_MOV = o.coste_nuevo,
         m.INSTANTE_MODIF = NOW();
  UPDATE fza_inventarios_lineas l
  JOIN fza_inventarios i
    ON i.CODIGO_EMP_INV = l.CODIGO_EMP_INVLIN
   AND i.CODIGO_ALM_INV = l.CODIGO_ALM_INVLIN
   AND i.SERIE_INV = l.SERIE_INV_INVLIN
   AND i.NUMERO_INV = l.NUMERO_INV_INVLIN
  JOIN fza_movimientos_almacen s
    ON s.TIPO_DOC_MOV = 'IN'
   AND s.TIPO_MOV = 'S'
   AND s.CODIGO_ALM_MOV = l.CODIGO_ALM_INVLIN
   AND s.SERIE_DOC_MOV = l.SERIE_INV_INVLIN
   AND s.NUMERO_DOC_MOV = l.NUMERO_INV_INVLIN
   AND CAST(s.LINEA_MOV AS UNSIGNED) = CAST(l.LINEA_INVLIN AS UNSIGNED)
  JOIN tmp_movimientos_ordenados o
    ON o.numero_mov = s.NUMERO_MOV
   AND o.es_cierre_inventario = 'S'
  LEFT JOIN fza_movimientos_almacen e
    ON e.TIPO_DOC_MOV = 'IN'
   AND e.TIPO_MOV = 'E'
   AND e.CODIGO_ALM_MOV = l.CODIGO_ALM_INVLIN
   AND e.SERIE_DOC_MOV = l.SERIE_INV_INVLIN
   AND e.NUMERO_DOC_MOV = l.NUMERO_INV_INVLIN
   AND CAST(e.LINEA_MOV AS UNSIGNED) = CAST(l.LINEA_INVLIN AS UNSIGNED)
     SET l.CANTIDAD_TEORICA_INVLIN = s.CANTIDAD_MOV,
         l.PRECIO_MEDIO_INVLIN = s.PRECIO_MEDIO_MOV,
         l.PRECIO_MEDIO_NUEVO_INVLIN = IF(
           l.ESPRECIO_MEDIO_CORREGIDO_INVLIN = 'S',
           l.PRECIO_MEDIO_NUEVO_INVLIN,
           IFNULL(e.PRECIO_COSTE_UNITARIO_MOV, s.PRECIO_MEDIO_MOV)),
         l.CANTIDAD_DIFERENCIA_INVLIN =
           l.CANTIDAD_FISICA_INVLIN - s.CANTIDAD_MOV,
         l.TOTAL_COSTE_DIFERENCIA_INVLIN =
           (l.CANTIDAD_FISICA_INVLIN * IF(
             l.ESPRECIO_MEDIO_CORREGIDO_INVLIN = 'S',
             l.PRECIO_MEDIO_NUEVO_INVLIN,
             IFNULL(e.PRECIO_COSTE_UNITARIO_MOV, s.PRECIO_MEDIO_MOV))) -
           (s.CANTIDAD_MOV * s.PRECIO_MEDIO_MOV),
         l.INSTANTE_MODIF = NOW()
   WHERE i.ESTADO_INV = 'APLICADO' OR i.ESTADO_INV = 'ABIERTO';
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_ACTUALIZAR_STOCK`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_ACTUALIZAR_STOCK`()
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_final;
  CREATE TEMPORARY TABLE tmp_recalculo_final (
    almacen varchar(10) NOT NULL,
    sku varchar(50) NOT NULL,
    stock_final decimal(19,6) NOT NULL,
    pmp_final decimal(19,6) NOT NULL,
    PRIMARY KEY (almacen, sku)
  ) ENGINE=InnoDB;
  INSERT INTO tmp_recalculo_final
    (almacen, sku, stock_final, pmp_final)
  SELECT s.almacen,
         s.sku,
         IFNULL(o.stock_nuevo, s.stock_semilla),
         IFNULL(o.pmp_nuevo, s.pmp_semilla)
    FROM tmp_recalculo_semillas s
    LEFT JOIN (
      SELECT x.almacen, x.sku, x.stock_nuevo, x.pmp_nuevo
        FROM tmp_movimientos_ordenados x
        JOIN (
          SELECT almacen, sku, MAX(rn) AS rn
            FROM tmp_movimientos_ordenados
           GROUP BY almacen, sku
        ) u ON u.rn = x.rn
    ) o ON o.almacen = s.almacen AND o.sku = s.sku;
  INSERT INTO fza_articulos_stockactual
    (CODIGO_ALM_STK, CODIGO_UNIDAD_STK, CANTIDAD_STK,
     VALOR_TOTAL_STK, PRECIO_MEDIO_STK, INSTANTE_MODIF,
     CANTIDAD_ENT_COMPRA_STK, CANTIDAD_ENT_TRASPASO_STK,
     CANTIDAD_SAL_TRASPASO_STK, CANTIDAD_ENT_DEPOSITO_STK,
     CANTIDAD_SAL_DEPOSITO_STK, CANTIDAD_SAL_VENTA_STK,
     CANTIDAD_ENT_REGULAR_STK, CANTIDAD_SAL_ALBVENTA_STK,
     CANTIDAD_ENT_ALBENTRADA_STK)
  SELECT f.almacen,
         f.sku,
         f.stock_final,
         IF(f.stock_final > 0, f.stock_final * f.pmp_final, 0),
         IF(f.stock_final > 0, f.pmp_final, 0),
         NOW(),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV = 'AC' AND m.TIPO_MOV = 'E',
                       m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV IN ('TR', 'AT', 'TA') AND
                       m.TIPO_MOV = 'E', m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV IN ('TR', 'AT', 'TA') AND
                       m.TIPO_MOV = 'S', m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV = 'DP' AND m.TIPO_MOV = 'E',
                       m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV = 'DP' AND m.TIPO_MOV = 'S',
                       m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV IN ('VE', 'FC') AND
                       m.TIPO_MOV = 'S', m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV = 'IN' AND m.TIPO_MOV = 'E',
                       m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV = 'AV' AND m.TIPO_MOV = 'S',
                       m.CANTIDAD_MOV, 0)), 0),
         IFNULL(SUM(IF(m.TIPO_DOC_MOV = 'AE' AND m.TIPO_MOV = 'E',
                       m.CANTIDAD_MOV, 0)), 0)
    FROM tmp_recalculo_final f
    LEFT JOIN fza_movimientos_almacen m
      ON m.CODIGO_ALM_MOV = f.almacen
     AND m.CODIGO_UNIDAD_MOV = f.sku
     AND m.ESACTIVO_MOV = 'S'
   GROUP BY f.almacen, f.sku, f.stock_final, f.pmp_final
  ON DUPLICATE KEY UPDATE
    CANTIDAD_STK = VALUES(CANTIDAD_STK),
    VALOR_TOTAL_STK = VALUES(VALOR_TOTAL_STK),
    PRECIO_MEDIO_STK = VALUES(PRECIO_MEDIO_STK),
    INSTANTE_MODIF = NOW(),
    CANTIDAD_ENT_COMPRA_STK = VALUES(CANTIDAD_ENT_COMPRA_STK),
    CANTIDAD_ENT_TRASPASO_STK = VALUES(CANTIDAD_ENT_TRASPASO_STK),
    CANTIDAD_SAL_TRASPASO_STK = VALUES(CANTIDAD_SAL_TRASPASO_STK),
    CANTIDAD_ENT_DEPOSITO_STK = VALUES(CANTIDAD_ENT_DEPOSITO_STK),
    CANTIDAD_SAL_DEPOSITO_STK = VALUES(CANTIDAD_SAL_DEPOSITO_STK),
    CANTIDAD_SAL_VENTA_STK = VALUES(CANTIDAD_SAL_VENTA_STK),
    CANTIDAD_ENT_REGULAR_STK = VALUES(CANTIDAD_ENT_REGULAR_STK),
    CANTIDAD_SAL_ALBVENTA_STK = VALUES(CANTIDAD_SAL_ALBVENTA_STK),
    CANTIDAD_ENT_ALBENTRADA_STK = VALUES(CANTIDAD_ENT_ALBENTRADA_STK);
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_final;
  DROP TEMPORARY TABLE IF EXISTS tmp_movimientos_ordenados;
  DROP TEMPORARY TABLE IF EXISTS tmp_recalculo_semillas;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_PASADA`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_PASADA`()
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR_COLA();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_CALCULAR_COLA();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_ACTUALIZAR_STOCK();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_PROPAGAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_PROPAGAR`(
  OUT p_CAMBIOS int
)
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_traspasos_propagar;
  CREATE TEMPORARY TABLE tmp_traspasos_propagar (
    numero_entrada varchar(20) NOT NULL,
    empresa varchar(20) NOT NULL,
    almacen varchar(10) NOT NULL,
    sku varchar(50) NOT NULL,
    instante_desde datetime NOT NULL,
    coste_salida decimal(19,6) NOT NULL,
    PRIMARY KEY (numero_entrada)
  ) ENGINE=InnoDB;
  INSERT INTO tmp_traspasos_propagar
    (numero_entrada, empresa, almacen, sku, instante_desde, coste_salida)
  SELECT e.NUMERO_MOV,
         IFNULL(e.CODIGO_EMP_MOV, ''),
         e.CODIGO_ALM_MOV,
         e.CODIGO_UNIDAD_MOV,
         IFNULL(e.FECHA_MOV, '1000-01-01 00:00:00'),
         SUM(s.TOTAL_COSTE_MOV) / NULLIF(SUM(s.CANTIDAD_MOV), 0)
    FROM tmp_movimientos_recalculo r
    JOIN fza_movimientos_almacen s
      ON s.CODIGO_ALM_MOV = r.almacen
     AND s.CODIGO_UNIDAD_MOV = r.sku
     AND s.ESACTIVO_MOV = 'S'
     AND s.TIPO_DOC_MOV IN ('TR', 'AT', 'TA')
     AND s.TIPO_MOV = 'S'
     AND IFNULL(s.FECHA_MOV, '1000-01-01 00:00:00') >= r.instante_desde
    JOIN fza_movimientos_almacen e
      ON e.TIPO_DOC_MOV = s.TIPO_DOC_MOV
     AND e.SERIE_DOC_MOV = s.SERIE_DOC_MOV
     AND e.NUMERO_DOC_MOV = s.NUMERO_DOC_MOV
     AND e.CODIGO_UNIDAD_MOV = s.CODIGO_UNIDAD_MOV
     AND e.CODIGO_ALM_MOV = s.CODIGO_ALM_CONTRA_MOV
     AND e.CODIGO_ALM_CONTRA_MOV = s.CODIGO_ALM_MOV
     AND e.ESACTIVO_MOV = 'S'
     AND e.TIPO_MOV = 'E'
     AND (e.LINEA_MOV = s.LINEA_MOV OR
          (IFNULL(e.NUMERO_OPERACION_DOC_MOV, '') <> '' AND
           e.NUMERO_OPERACION_DOC_MOV = s.NUMERO_OPERACION_DOC_MOV))
   GROUP BY e.NUMERO_MOV, e.CODIGO_EMP_MOV, e.CODIGO_ALM_MOV,
            e.CODIGO_UNIDAD_MOV, e.FECHA_MOV,
            e.PRECIO_COSTE_UNITARIO_MOV
  HAVING ABS(IFNULL(e.PRECIO_COSTE_UNITARIO_MOV, 0) -
         (SUM(s.TOTAL_COSTE_MOV) / NULLIF(SUM(s.CANTIDAD_MOV), 0))) >
         0.0000005;
  SELECT COUNT(*) INTO p_CAMBIOS FROM tmp_traspasos_propagar;
  UPDATE fza_movimientos_almacen e
  JOIN tmp_traspasos_propagar p ON p.numero_entrada = e.NUMERO_MOV
     SET e.PRECIO_COSTE_UNITARIO_MOV = p.coste_salida,
         e.INSTANTE_MODIF = NOW();
  DELETE FROM tmp_movimientos_recalculo;
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT MIN(empresa), almacen, sku, MIN(instante_desde)
    FROM tmp_traspasos_propagar
   GROUP BY almacen, sku;
  DROP TEMPORARY TABLE IF EXISTS tmp_traspasos_propagar;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR`()
BEGIN
  DECLARE v_CAMBIOS int DEFAULT 1;
  DECLARE v_PASADAS int DEFAULT 0;
  WHILE EXISTS(SELECT 1 FROM tmp_movimientos_recalculo) AND
        v_CAMBIOS > 0 AND v_PASADAS < 100 DO
    CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PASADA();
    CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PROPAGAR(v_CAMBIOS);
    SET v_PASADAS = v_PASADAS + 1;
  END WHILE;
  IF v_CAMBIOS > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT =
        'No converge la propagacion cronologica de traspasos';
  END IF;
  DROP TEMPORARY TABLE IF EXISTS tmp_movimientos_recalculo;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULAR_DOCUMENTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULAR_DOCUMENTO`(
  IN p_TIPO varchar(5),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_DOCUMENTO(
    p_TIPO, p_SERIE, p_NUMERO);
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION`(
  IN p_OPERACION varchar(20)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_OPERACION(p_OPERACION);
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_RECALCULAR_MOVIMIENTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_RECALCULAR_MOVIMIENTO`(
  IN p_NUMERO varchar(20)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT IFNULL(CODIGO_EMP_MOV, ''), CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
         IFNULL(FECHA_MOV, '1000-01-01 00:00:00')
    FROM fza_movimientos_almacen
   WHERE NUMERO_MOV = p_NUMERO;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `SP_RECALCULAR_PMP_LOTE_ALMACEN`;
DELIMITER ;;
CREATE PROCEDURE `SP_RECALCULAR_PMP_LOTE_ALMACEN`(
  IN p_EMPRESA varchar(20),
  IN p_ALMACEN varchar(10)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT p_EMPRESA, p_ALMACEN, sku, '1000-01-01 00:00:00'
    FROM tmp_skus_recalc;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `SP_RECALCULAR_PMP_SKU_ALMACEN`;
DELIMITER ;;
CREATE PROCEDURE `SP_RECALCULAR_PMP_SKU_ALMACEN`(
  IN p_EMPRESA varchar(20),
  IN p_SKU varchar(50),
  IN p_ALMACEN varchar(10)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR(
    p_EMPRESA, p_ALMACEN, p_SKU, '1000-01-01 00:00:00');
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE`(
  IN p_NUMERO_MOV varchar(20)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT IFNULL(CODIGO_EMP_MOV, ''), CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
         IFNULL(FECHA_MOV, '1000-01-01 00:00:00')
    FROM fza_movimientos_almacen
   WHERE NUMERO_MOV = p_NUMERO_MOV;
  DELETE FROM fza_movimientos_almacen WHERE NUMERO_MOV = p_NUMERO_MOV;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC`(
  IN p_TIPO varchar(5),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_DOCUMENTO(
    p_TIPO, p_SERIE, p_NUMERO);
  DELETE FROM fza_movimientos_almacen
   WHERE TIPO_DOC_MOV = p_TIPO
     AND SERIE_DOC_MOV = p_SERIE
     AND NUMERO_DOC_MOV = p_NUMERO;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_MOVIMIENTOS_ALMACEN_UPDATE`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_MOVIMIENTOS_ALMACEN_UPDATE`(
  IN p_NUMERO_MOV varchar(20),
  IN p_NUEVA_CANTIDAD decimal(19,6),
  IN p_NUEVO_PRECIO decimal(19,6),
  IN p_USUARIO varchar(100)
)
BEGIN
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  INSERT INTO tmp_movimientos_recalculo
    (empresa, almacen, sku, instante_desde)
  SELECT IFNULL(CODIGO_EMP_MOV, ''), CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
         IFNULL(FECHA_MOV, '1000-01-01 00:00:00')
    FROM fza_movimientos_almacen
   WHERE NUMERO_MOV = p_NUMERO_MOV;
  UPDATE fza_movimientos_almacen
     SET CANTIDAD_MOV = p_NUEVA_CANTIDAD,
         PRECIO_COSTE_UNITARIO_MOV = p_NUEVO_PRECIO,
         USUARIO_MODIF = p_USUARIO,
         INSTANTE_MODIF = NOW()
   WHERE NUMERO_MOV = p_NUMERO_MOV;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_CALCULAR_LINEAS`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_INVENTARIOS_CALCULAR_LINEAS`(
  IN p_EMPRESA varchar(10),
  IN p_ALMACEN varchar(10),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20),
  IN p_USUARIO varchar(100),
  IN p_FECHA_DEFECTO datetime
)
BEGIN
  DECLARE v_FIN int DEFAULT 0;
  DECLARE v_LINEA varchar(8);
  DECLARE v_SKU varchar(50);
  DECLARE v_FISICA decimal(19,6);
  DECLARE v_PMP_NUEVO decimal(19,6);
  DECLARE v_ES_CORREGIDO varchar(1);
  DECLARE v_RECUENTO datetime;
  DECLARE v_STOCK decimal(19,6);
  DECLARE v_PMP decimal(19,6);
  DECLARE cur CURSOR FOR
    SELECT LINEA_INVLIN, CODIGO_UNIDAD_INVLIN, CANTIDAD_FISICA_INVLIN,
           PRECIO_MEDIO_NUEVO_INVLIN,
           ESPRECIO_MEDIO_CORREGIDO_INVLIN, FECHA_RECUENTO_INVLIN
      FROM fza_inventarios_lineas
     WHERE CODIGO_EMP_INVLIN = p_EMPRESA
       AND CODIGO_ALM_INVLIN = p_ALMACEN
       AND SERIE_INV_INVLIN = p_SERIE
       AND NUMERO_INV_INVLIN = p_NUMERO;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_FIN = 1;
  OPEN cur;
  bucle: LOOP
    FETCH cur INTO v_LINEA, v_SKU, v_FISICA, v_PMP_NUEVO,
                   v_ES_CORREGIDO, v_RECUENTO;
    IF v_FIN = 1 THEN
      LEAVE bucle;
    END IF;
    SET v_RECUENTO = IFNULL(v_RECUENTO, p_FECHA_DEFECTO);
    SELECT IFNULL(SUM(IF(TIPO_MOV = 'E', CANTIDAD_MOV, -CANTIDAD_MOV)), 0)
      INTO v_STOCK
      FROM fza_movimientos_almacen
     WHERE CODIGO_ALM_MOV = p_ALMACEN
       AND CODIGO_UNIDAD_MOV = v_SKU
       AND IFNULL(FECHA_MOV, '1000-01-01 00:00:00') <= v_RECUENTO
       AND ESACTIVO_MOV = 'S';
    SET v_PMP = IFNULL((
      SELECT PRECIO_MEDIO_MOV
        FROM fza_movimientos_almacen
       WHERE CODIGO_ALM_MOV = p_ALMACEN
         AND CODIGO_UNIDAD_MOV = v_SKU
         AND IFNULL(FECHA_MOV, '1000-01-01 00:00:00') <= v_RECUENTO
         AND ESACTIVO_MOV = 'S'
       ORDER BY IFNULL(FECHA_MOV, '1000-01-01 00:00:00') DESC,
                IFNULL(INSTANTE_ALTA, '1000-01-01 00:00:00') DESC,
                NUMERO_MOV DESC
       LIMIT 1), 0);
    IF IFNULL(v_ES_CORREGIDO, 'N') <> 'S' THEN
      SET v_PMP_NUEVO = v_PMP;
    END IF;
    UPDATE fza_inventarios_lineas
       SET CANTIDAD_TEORICA_INVLIN = v_STOCK,
           PRECIO_MEDIO_INVLIN = v_PMP,
           PRECIO_MEDIO_NUEVO_INVLIN = IFNULL(v_PMP_NUEVO, 0),
           CANTIDAD_DIFERENCIA_INVLIN = v_FISICA - v_STOCK,
           TOTAL_COSTE_DIFERENCIA_INVLIN =
             (v_FISICA * IFNULL(v_PMP_NUEVO, 0)) - (v_STOCK * v_PMP),
           FECHA_RECUENTO_INVLIN = v_RECUENTO,
           USUARIO_MODIF = p_USUARIO,
           INSTANTE_MODIF = NOW()
     WHERE CODIGO_EMP_INVLIN = p_EMPRESA
       AND CODIGO_ALM_INVLIN = p_ALMACEN
       AND SERIE_INV_INVLIN = p_SERIE
       AND NUMERO_INV_INVLIN = p_NUMERO
       AND LINEA_INVLIN = v_LINEA;
  END LOOP;
  CLOSE cur;
  UPDATE fza_inventarios i
     SET TOTAL_UNIDADES_DIFERENCIA_INV = (
           SELECT IFNULL(SUM(CANTIDAD_DIFERENCIA_INVLIN), 0)
             FROM fza_inventarios_lineas
            WHERE CODIGO_EMP_INVLIN = p_EMPRESA
              AND CODIGO_ALM_INVLIN = p_ALMACEN
              AND SERIE_INV_INVLIN = p_SERIE
              AND NUMERO_INV_INVLIN = p_NUMERO),
         TOTAL_EUROS_DIFERENCIA_INV = (
           SELECT IFNULL(SUM(TOTAL_COSTE_DIFERENCIA_INVLIN), 0)
             FROM fza_inventarios_lineas
            WHERE CODIGO_EMP_INVLIN = p_EMPRESA
              AND CODIGO_ALM_INVLIN = p_ALMACEN
              AND SERIE_INV_INVLIN = p_SERIE
              AND NUMERO_INV_INVLIN = p_NUMERO),
         USUARIO_MODIF = p_USUARIO,
         INSTANTE_MODIF = NOW()
   WHERE CODIGO_EMP_INV = p_EMPRESA
     AND CODIGO_ALM_INV = p_ALMACEN
     AND SERIE_INV = p_SERIE
     AND NUMERO_INV = p_NUMERO;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO`(
  IN p_EMPRESA varchar(10),
  IN p_ALMACEN varchar(10),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20),
  IN p_USUARIO varchar(100)
)
BEGIN
  DECLARE v_ESTADO varchar(20);
  DECLARE v_FECHA datetime;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT ESTADO_INV,
         TIMESTAMP(DATE_SUB(DATE(FECHA_INV), INTERVAL 1 DAY), '23:59:59')
    INTO v_ESTADO, v_FECHA
    FROM fza_inventarios
   WHERE CODIGO_EMP_INV = p_EMPRESA
     AND CODIGO_ALM_INV = p_ALMACEN
     AND SERIE_INV = p_SERIE
     AND NUMERO_INV = p_NUMERO
   FOR UPDATE;
  IF IFNULL(v_ESTADO, '') <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El inventario no esta ABIERTO';
  END IF;
  CALL PRC_FZA_INVENTARIOS_CALCULAR_LINEAS(
    p_EMPRESA, p_ALMACEN, p_SERIE, p_NUMERO, p_USUARIO, v_FECHA);
  COMMIT;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_APLICAR`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_INVENTARIOS_APLICAR`(
  IN p_EMPRESA varchar(10),
  IN p_ALMACEN varchar(10),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20),
  IN p_USUARIO varchar(100)
)
BEGIN
  DECLARE v_FIN int DEFAULT 0;
  DECLARE v_ESTADO varchar(20);
  DECLARE v_FECHA datetime;
  DECLARE v_LINEA varchar(8);
  DECLARE v_ARTICULO varchar(20);
  DECLARE v_SKU varchar(50);
  DECLARE v_TEORICA decimal(19,6);
  DECLARE v_FISICA decimal(19,6);
  DECLARE v_PMP_HIST decimal(19,6);
  DECLARE v_PMP_NUEVO decimal(19,6);
  DECLARE v_RECUENTO datetime;
  DECLARE v_SALIDA datetime;
  DECLARE v_NUM_SALIDA varchar(20);
  DECLARE v_NUM_ENTRADA varchar(20);
  DECLARE cur CURSOR FOR
    SELECT LINEA_INVLIN, CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN,
           CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN,
           PRECIO_MEDIO_INVLIN, PRECIO_MEDIO_NUEVO_INVLIN,
           FECHA_RECUENTO_INVLIN
      FROM fza_inventarios_lineas
     WHERE CODIGO_EMP_INVLIN = p_EMPRESA
       AND CODIGO_ALM_INVLIN = p_ALMACEN
       AND SERIE_INV_INVLIN = p_SERIE
       AND NUMERO_INV_INVLIN = p_NUMERO;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_FIN = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT ESTADO_INV,
         TIMESTAMP(DATE_SUB(DATE(FECHA_INV), INTERVAL 1 DAY), '23:59:59')
    INTO v_ESTADO, v_FECHA
    FROM fza_inventarios
   WHERE CODIGO_EMP_INV = p_EMPRESA
     AND CODIGO_ALM_INV = p_ALMACEN
     AND SERIE_INV = p_SERIE
     AND NUMERO_INV = p_NUMERO
   FOR UPDATE;
  IF IFNULL(v_ESTADO, '') <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El inventario no esta ABIERTO';
  END IF;
  CALL PRC_FZA_INVENTARIOS_CALCULAR_LINEAS(
    p_EMPRESA, p_ALMACEN, p_SERIE, p_NUMERO, p_USUARIO, v_FECHA);
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  OPEN cur;
  bucle: LOOP
    FETCH cur INTO v_LINEA, v_ARTICULO, v_SKU, v_TEORICA, v_FISICA,
                   v_PMP_HIST, v_PMP_NUEVO, v_RECUENTO;
    IF v_FIN = 1 THEN
      LEAVE bucle;
    END IF;
    SET v_RECUENTO = IFNULL(v_RECUENTO, v_FECHA);
    SET v_SALIDA = DATE_SUB(v_RECUENTO, INTERVAL 1 SECOND);
    SET v_NUM_SALIDA = LEFT(
      CONCAT('IV-', p_NUMERO, '-', v_LINEA, 'S'), 20);
    SET v_NUM_ENTRADA = LEFT(
      CONCAT('IV-', p_NUMERO, '-', v_LINEA, 'E'), 20);
    CALL PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(
      v_NUM_SALIDA, 'IN', p_SERIE, p_NUMERO, v_LINEA,
      p_EMPRESA, p_ALMACEN, NULL, v_SKU, 'S', v_TEORICA,
      v_PMP_HIST, v_TEORICA * v_PMP_HIST, p_USUARIO,
      p_ALMACEN, NULL, NULL, NULL, v_ARTICULO);
    UPDATE fza_movimientos_almacen
       SET FECHA_MOV = v_SALIDA
     WHERE NUMERO_MOV = v_NUM_SALIDA;
    CALL PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(
      v_NUM_ENTRADA, 'IN', p_SERIE, p_NUMERO, v_LINEA,
      p_EMPRESA, p_ALMACEN, NULL, v_SKU, 'E', v_FISICA,
      v_PMP_NUEVO, v_FISICA * v_PMP_NUEVO, p_USUARIO,
      p_ALMACEN, NULL, NULL, NULL, v_ARTICULO);
    UPDATE fza_movimientos_almacen
       SET FECHA_MOV = v_RECUENTO
     WHERE NUMERO_MOV = v_NUM_ENTRADA;
    CALL PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR(
      p_EMPRESA, p_ALMACEN, v_SKU, v_SALIDA);
  END LOOP;
  CLOSE cur;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
  UPDATE fza_inventarios
     SET ESTADO_INV = 'APLICADO',
         TOTAL_UNIDADES_DIFERENCIA_INV = (
           SELECT IFNULL(SUM(CANTIDAD_DIFERENCIA_INVLIN), 0)
             FROM fza_inventarios_lineas
            WHERE CODIGO_EMP_INVLIN = p_EMPRESA
              AND CODIGO_ALM_INVLIN = p_ALMACEN
              AND SERIE_INV_INVLIN = p_SERIE
              AND NUMERO_INV_INVLIN = p_NUMERO),
         TOTAL_EUROS_DIFERENCIA_INV = (
           SELECT IFNULL(SUM(TOTAL_COSTE_DIFERENCIA_INVLIN), 0)
             FROM fza_inventarios_lineas
            WHERE CODIGO_EMP_INVLIN = p_EMPRESA
              AND CODIGO_ALM_INVLIN = p_ALMACEN
              AND SERIE_INV_INVLIN = p_SERIE
              AND NUMERO_INV_INVLIN = p_NUMERO),
         USUARIO_MODIF = p_USUARIO,
         INSTANTE_MODIF = NOW()
   WHERE CODIGO_EMP_INV = p_EMPRESA
     AND CODIGO_ALM_INV = p_ALMACEN
     AND SERIE_INV = p_SERIE
     AND NUMERO_INV = p_NUMERO;
  COMMIT;
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_FZA_INVENTARIOS_ELIMINAR_REGUL`;
DELIMITER ;;
CREATE PROCEDURE `PRC_FZA_INVENTARIOS_ELIMINAR_REGUL`(
  IN p_EMPRESA varchar(10),
  IN p_ALMACEN varchar(10),
  IN p_SERIE varchar(20),
  IN p_NUMERO varchar(20),
  IN p_USUARIO varchar(100)
)
BEGIN
  DECLARE v_ESTADO varchar(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT ESTADO_INV INTO v_ESTADO
    FROM fza_inventarios
   WHERE CODIGO_EMP_INV = p_EMPRESA
     AND CODIGO_ALM_INV = p_ALMACEN
     AND SERIE_INV = p_SERIE
     AND NUMERO_INV = p_NUMERO
   FOR UPDATE;
  IF IFNULL(v_ESTADO, '') <> 'APLICADO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El inventario no esta APLICADO';
  END IF;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_PREPARAR();
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_MARCAR_DOCUMENTO(
    'IN', p_SERIE, p_NUMERO);
  DELETE FROM fza_movimientos_almacen
   WHERE TIPO_DOC_MOV = 'IN'
     AND SERIE_DOC_MOV = p_SERIE
     AND NUMERO_DOC_MOV = p_NUMERO;
  CALL PRC_FZA_MOVIMIENTOS_RECALCULO_EJECUTAR();
  UPDATE fza_inventarios
     SET ESTADO_INV = 'ABIERTO',
         USUARIO_MODIF = p_USUARIO,
         INSTANTE_MODIF = NOW()
   WHERE CODIGO_EMP_INV = p_EMPRESA
     AND CODIGO_ALM_INV = p_ALMACEN
     AND SERIE_INV = p_SERIE
     AND NUMERO_INV = p_NUMERO;
  COMMIT;
END;;
DELIMITER ;
