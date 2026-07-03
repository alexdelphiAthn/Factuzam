-- =============================================================================
-- Lineas de documentos a varchar(4) y contadores de cabecera
-- =============================================================================
-- Asegura formato de cuatro digitos en las lineas de pedidos, albaranes,
-- devoluciones y facturas de compra. La columna que necesita ampliacion en
-- instalaciones limpias antiguas es fza_pedidos_lineas.LINEA_PEDLIN
-- (varchar(3) -> varchar(4)).
--
-- Tambien resiembra CONTADOR_LINEAS_* desde la ultima linea real de cada
-- documento sin usar agregados MAX: se toma la linea para la que no existe
-- otra linea numericamente superior dentro del mismo documento.
--
-- Idempotente: se puede ejecutar varias veces.
-- =============================================================================

DROP PROCEDURE IF EXISTS PRC_TMP_LINEA_VARCHAR4;
DELIMITER ;;
CREATE PROCEDURE PRC_TMP_LINEA_VARCHAR4(
  IN p_tabla varchar(64),
  IN p_columna varchar(64),
  IN p_not_null varchar(1)
)
BEGIN
  DECLARE iLen int;
  DECLARE sNulo varchar(30);
  SELECT CHARACTER_MAXIMUM_LENGTH
    INTO iLen
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = p_tabla
     AND COLUMN_NAME = p_columna;
  SET sNulo = IF(p_not_null = 'S', 'NOT NULL', 'NULL DEFAULT NULL');
  SET @sSql := IF(iLen IS NOT NULL AND iLen < 4,
    CONCAT('ALTER TABLE `', p_tabla, '` MODIFY COLUMN `',
           p_columna, '` varchar(4) ', sNulo),
    CONCAT('SELECT ''', p_tabla, '.', p_columna,
           ' no existe o ya mide >= 4, se omite'' AS info'));
  PREPARE stmt FROM @sSql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END;;
DELIMITER ;

CALL PRC_TMP_LINEA_VARCHAR4('fza_pedidos_lineas',
                            'LINEA_PEDLIN', 'S');
CALL PRC_TMP_LINEA_VARCHAR4('fza_albaranes_lineas',
                            'LINEA_ALBLIN', 'S');
CALL PRC_TMP_LINEA_VARCHAR4('fza_albaranes_lineas',
                            'LINEA_PED_ALBLIN', 'N');
CALL PRC_TMP_LINEA_VARCHAR4('fza_pedidos_compra_lineas',
                            'LINEA_PEDCLIN', 'S');
CALL PRC_TMP_LINEA_VARCHAR4('fza_albaranes_compra_lineas',
                            'LINEA_ALBCLIN', 'S');
CALL PRC_TMP_LINEA_VARCHAR4('fza_devoluciones_compra_lineas',
                            'LINEA_DEVCLIN', 'S');
CALL PRC_TMP_LINEA_VARCHAR4('fza_facturas_compra_lineas',
                            'LINEA_FACCLIN', 'S');

DROP PROCEDURE IF EXISTS PRC_TMP_LINEA_VARCHAR4;

UPDATE fza_pedidos_lineas
   SET LINEA_PEDLIN = LPAD(CAST(TRIM(LINEA_PEDLIN) AS UNSIGNED), 4, '0')
 WHERE TRIM(LINEA_PEDLIN) REGEXP '^[0-9]+$'
   AND LENGTH(TRIM(LINEA_PEDLIN)) < 4;

UPDATE fza_albaranes_lineas
   SET LINEA_PED_ALBLIN =
       LPAD(CAST(TRIM(LINEA_PED_ALBLIN) AS UNSIGNED), 4, '0')
 WHERE LINEA_PED_ALBLIN IS NOT NULL
   AND TRIM(LINEA_PED_ALBLIN) REGEXP '^[0-9]+$'
   AND LENGTH(TRIM(LINEA_PED_ALBLIN)) < 4;

UPDATE fza_pedidos AS H
  JOIN fza_pedidos_lineas AS L
    ON L.SERIE_PED_PEDLIN = H.SERIE_PED
   AND L.NUMERO_PED_PEDLIN = H.NUMERO_PED
   SET H.CONTADOR_LINEAS_PED =
       LPAD(CAST(L.LINEA_PEDLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_PEDLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_pedidos_lineas AS L2
        WHERE L2.SERIE_PED_PEDLIN = L.SERIE_PED_PEDLIN
          AND L2.NUMERO_PED_PEDLIN = L.NUMERO_PED_PEDLIN
          AND TRIM(L2.LINEA_PEDLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_PEDLIN AS UNSIGNED) >
              CAST(L.LINEA_PEDLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_PED IS NULL
        OR H.CONTADOR_LINEAS_PED = ''
        OR CAST(H.CONTADOR_LINEAS_PED AS UNSIGNED) <
           CAST(L.LINEA_PEDLIN AS UNSIGNED));

UPDATE fza_albaranes AS H
  JOIN fza_albaranes_lineas AS L
    ON L.SERIE_ALB_ALBLIN = H.SERIE_ALB
   AND L.NUMERO_ALB_ALBLIN = H.NUMERO_ALB
   SET H.CONTADOR_LINEAS_ALB =
       LPAD(CAST(L.LINEA_ALBLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_ALBLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_albaranes_lineas AS L2
        WHERE L2.SERIE_ALB_ALBLIN = L.SERIE_ALB_ALBLIN
          AND L2.NUMERO_ALB_ALBLIN = L.NUMERO_ALB_ALBLIN
          AND TRIM(L2.LINEA_ALBLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_ALBLIN AS UNSIGNED) >
              CAST(L.LINEA_ALBLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_ALB IS NULL
        OR H.CONTADOR_LINEAS_ALB = ''
        OR CAST(H.CONTADOR_LINEAS_ALB AS UNSIGNED) <
           CAST(L.LINEA_ALBLIN AS UNSIGNED));

UPDATE fza_pedidos_compra AS H
  JOIN fza_pedidos_compra_lineas AS L
    ON L.SERIE_PEDC_PEDCLIN = H.SERIE_PEDC
   AND L.NUMERO_PEDC_PEDCLIN = H.NUMERO_PEDC
   SET H.CONTADOR_LINEAS_PEDC =
       LPAD(CAST(L.LINEA_PEDCLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_PEDCLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_pedidos_compra_lineas AS L2
        WHERE L2.SERIE_PEDC_PEDCLIN = L.SERIE_PEDC_PEDCLIN
          AND L2.NUMERO_PEDC_PEDCLIN = L.NUMERO_PEDC_PEDCLIN
          AND TRIM(L2.LINEA_PEDCLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_PEDCLIN AS UNSIGNED) >
              CAST(L.LINEA_PEDCLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_PEDC IS NULL
        OR H.CONTADOR_LINEAS_PEDC = ''
        OR CAST(H.CONTADOR_LINEAS_PEDC AS UNSIGNED) <
           CAST(L.LINEA_PEDCLIN AS UNSIGNED));

UPDATE fza_albaranes_compra AS H
  JOIN fza_albaranes_compra_lineas AS L
    ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC
   AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC
   SET H.CONTADOR_LINEAS_ALBC =
       LPAD(CAST(L.LINEA_ALBCLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_ALBCLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_albaranes_compra_lineas AS L2
        WHERE L2.SERIE_ALBC_ALBCLIN = L.SERIE_ALBC_ALBCLIN
          AND L2.NUMERO_ALBC_ALBCLIN = L.NUMERO_ALBC_ALBCLIN
          AND TRIM(L2.LINEA_ALBCLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_ALBCLIN AS UNSIGNED) >
              CAST(L.LINEA_ALBCLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_ALBC IS NULL
        OR H.CONTADOR_LINEAS_ALBC = ''
        OR CAST(H.CONTADOR_LINEAS_ALBC AS UNSIGNED) <
           CAST(L.LINEA_ALBCLIN AS UNSIGNED));

UPDATE fza_devoluciones_compra AS H
  JOIN fza_devoluciones_compra_lineas AS L
    ON L.SERIE_DEVC_DEVCLIN = H.SERIE_DEVC
   AND L.NUMERO_DEVC_DEVCLIN = H.NUMERO_DEVC
   SET H.CONTADOR_LINEAS_DEVC =
       LPAD(CAST(L.LINEA_DEVCLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_DEVCLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_devoluciones_compra_lineas AS L2
        WHERE L2.SERIE_DEVC_DEVCLIN = L.SERIE_DEVC_DEVCLIN
          AND L2.NUMERO_DEVC_DEVCLIN = L.NUMERO_DEVC_DEVCLIN
          AND TRIM(L2.LINEA_DEVCLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_DEVCLIN AS UNSIGNED) >
              CAST(L.LINEA_DEVCLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_DEVC IS NULL
        OR H.CONTADOR_LINEAS_DEVC = ''
        OR CAST(H.CONTADOR_LINEAS_DEVC AS UNSIGNED) <
           CAST(L.LINEA_DEVCLIN AS UNSIGNED));

UPDATE fza_facturas_compra AS H
  JOIN fza_facturas_compra_lineas AS L
    ON L.SERIE_FACC_FACCLIN = H.SERIE_FACC
   AND L.NUMERO_FACC_FACCLIN = H.NUMERO_FACC
   SET H.CONTADOR_LINEAS_FACC =
       LPAD(CAST(L.LINEA_FACCLIN AS UNSIGNED), 8, '0')
 WHERE TRIM(L.LINEA_FACCLIN) REGEXP '^[0-9]+$'
   AND NOT EXISTS (
       SELECT 1
         FROM fza_facturas_compra_lineas AS L2
        WHERE L2.SERIE_FACC_FACCLIN = L.SERIE_FACC_FACCLIN
          AND L2.NUMERO_FACC_FACCLIN = L.NUMERO_FACC_FACCLIN
          AND TRIM(L2.LINEA_FACCLIN) REGEXP '^[0-9]+$'
          AND CAST(L2.LINEA_FACCLIN AS UNSIGNED) >
              CAST(L.LINEA_FACCLIN AS UNSIGNED)
   )
   AND (H.CONTADOR_LINEAS_FACC IS NULL
        OR H.CONTADOR_LINEAS_FACC = ''
        OR CAST(H.CONTADOR_LINEAS_FACC AS UNSIGNED) <
           CAST(L.LINEA_FACCLIN AS UNSIGNED));

DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_LINEA;
DELIMITER ;;
CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_LINEA(
  IN p_NUMERO_ALB varchar(20),
  IN p_SERIE_ALB varchar(20),
  IN p_NUMERO_PED varchar(20),
  IN p_SERIE_PED varchar(20),
  IN p_LINEA_PED varchar(4),
  IN p_CANTIDAD decimal(19,6),
  IN p_CODIGO_ALM varchar(10),
  IN p_USUARIO varchar(100)
)
PRC: BEGIN
  DECLARE v_linea varchar(4);
  DECLARE v_pendiente decimal(19,6);
  DECLARE v_cantidad decimal(19,6);
  SELECT (CANTIDAD_PEDLIN - IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0))
    INTO v_pendiente
    FROM fza_pedidos_lineas
   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED
     AND SERIE_PED_PEDLIN = p_SERIE_PED
     AND LINEA_PEDLIN = p_LINEA_PED;
  IF v_pendiente IS NULL OR v_pendiente <= 0 THEN
    LEAVE PRC;
  END IF;
  IF p_CANTIDAD > v_pendiente THEN
    SET v_cantidad = v_pendiente;
  ELSE
    SET v_cantidad = p_CANTIDAD;
  END IF;
  UPDATE fza_albaranes
     SET CONTADOR_LINEAS_ALB =
         LPAD(LAST_INSERT_ID(
           IFNULL(CAST(NULLIF(CONTADOR_LINEAS_ALB, '') AS UNSIGNED), 0) + 10
         ), 8, '0')
   WHERE NUMERO_ALB = p_NUMERO_ALB
     AND SERIE_ALB = p_SERIE_ALB;
  IF ROW_COUNT() = 0 THEN
    LEAVE PRC;
  END IF;
  SET v_linea = LPAD(LAST_INSERT_ID(), 4, '0');
  INSERT INTO fza_albaranes_lineas (
    NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN,
    NUMERO_PED_ALBLIN, SERIE_PED_ALBLIN, LINEA_PED_ALBLIN,
    CODIGO_ART_ALBLIN, CODIGO_FAM_ALBLIN, NOMBRE_FAM_ALBLIN,
    DESCRIPCION_ARTICULO_ALBLIN, TIPO_CANTIDAD_ARTICULO_ALBLIN,
    CANTIDAD_ALBLIN, CODIGO_TAR_ALBLIN, ESIMP_INCL_TARIFA_ALBLIN,
    TIPO_IVA_ARTICULO_ALBLIN, PORCENTAJE_IVA_ALBLIN,
    PRECIO_VENTA_SIVA_ARTICULO_ALBLIN,
    PRECIO_VENTA_CIVA_ARTICULO_ALBLIN,
    TOTAL_ALBLIN, CODIGO_ALMACEN_ALBLIN,
    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF
  )
  SELECT
    p_NUMERO_ALB, p_SERIE_ALB, v_linea,
    p_NUMERO_PED, p_SERIE_PED, p_LINEA_PED,
    PL.CODIGO_ART_PEDLIN, PL.CODIGO_FAM_PEDLIN, PL.NOMBRE_FAM_PEDLIN,
    PL.DESCRIPCION_ARTICULO_PEDLIN, PL.TIPO_CANTIDAD_ARTICULO_PEDLIN,
    v_cantidad, PL.CODIGO_TAR_PEDLIN, PL.ESIMP_INCL_TARIFA_PEDLIN,
    PL.TIPO_IVA_ARTICULO_PEDLIN, PL.PORCENTAJE_IVA_PEDLIN,
    PL.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN,
    PL.PRECIO_VENTA_CIVA_ARTICULO_PEDLIN,
    (v_cantidad * PL.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN),
    COALESCE(NULLIF(p_CODIGO_ALM, ''), PL.CODIGO_ALMACEN_PEDLIN),
    NOW(), p_USUARIO, p_USUARIO
  FROM fza_pedidos_lineas AS PL
  WHERE PL.NUMERO_PED_PEDLIN = p_NUMERO_PED
    AND PL.SERIE_PED_PEDLIN = p_SERIE_PED
    AND PL.LINEA_PEDLIN = p_LINEA_PED;
  UPDATE fza_pedidos_lineas
     SET CANTIDAD_ENTREGADA_PEDLIN =
           IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0) + v_cantidad,
         CANTIDAD_PENDIENTE_PEDLIN =
           CANTIDAD_PEDLIN -
           (IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0) + v_cantidad),
         ESENTREGADA_PEDLIN =
           CASE
             WHEN CANTIDAD_PEDLIN <=
                  IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0) + v_cantidad
             THEN 'S'
             ELSE 'N'
           END,
         INSTANTE_MODIF = NOW(),
         USUARIO_MODIF = p_USUARIO
   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED
     AND SERIE_PED_PEDLIN = p_SERIE_PED
     AND LINEA_PEDLIN = p_LINEA_PED;
END;;
DELIMITER ;
