-- Limpieza de movimientos de salida duplicados de facturas.
--
-- Causa: hasta la versión 1.0.15.202606120150, el control de
-- duplicados de GenerarMovimientosSalidaFactura miraba las columnas
-- *_REF_* (siempre NULL) o solo TIPO_DOC_MOV='FC'. Una factura
-- simplificada nacida en caja ya tiene su salida con
-- TIPO_DOC_MOV='VE', así que un Post posterior de la cabecera en el
-- Mto generaba OTRA salida 'FC' para la misma línea: stock descontado
-- dos veces.
--
-- Este script borra, con reversión de stock (vía
-- PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE, que ajusta los acumulados):
--   a) salidas 'FC' que duplican una salida 'VE' de la misma
--      factura/línea/SKU, y
--   b) salidas 'FC' repetidas entre sí (se conserva la de menor
--      NUMERO_MOV).
-- Idempotente: en una segunda pasada no encuentra nada.
--
-- 1) Informe previo: qué se va a borrar
SELECT m.NUMERO_MOV, m.SERIE_DOC_MOV, m.NUMERO_DOC_MOV, m.LINEA_MOV,
       m.CODIGO_UNIDAD_MOV, m.CANTIDAD_MOV, m.FECHA_MOV
  FROM fza_movimientos_almacen m
 WHERE m.TIPO_DOC_MOV = 'FC'
   AND m.TIPO_MOV = 'S'
   AND (EXISTS (SELECT 1 FROM fza_movimientos_almacen v
                 WHERE v.TIPO_DOC_MOV = 'VE'
                   AND v.TIPO_MOV = 'S'
                   AND v.SERIE_DOC_MOV     = m.SERIE_DOC_MOV
                   AND v.NUMERO_DOC_MOV    = m.NUMERO_DOC_MOV
                   AND v.LINEA_MOV         = m.LINEA_MOV
                   AND v.CODIGO_UNIDAD_MOV = m.CODIGO_UNIDAD_MOV)
        OR m.NUMERO_MOV >
           (SELECT MIN(f.NUMERO_MOV)
              FROM fza_movimientos_almacen f
             WHERE f.TIPO_DOC_MOV = 'FC'
               AND f.TIPO_MOV = 'S'
               AND f.SERIE_DOC_MOV     = m.SERIE_DOC_MOV
               AND f.NUMERO_DOC_MOV    = m.NUMERO_DOC_MOV
               AND f.LINEA_MOV         = m.LINEA_MOV
               AND f.CODIGO_UNIDAD_MOV = m.CODIGO_UNIDAD_MOV));
-- 2) Borrado con reversión de stock
DROP PROCEDURE IF EXISTS PRC_TMP_LIMPIAR_MOV_FAC_DUP;
DELIMITER ;;
CREATE PROCEDURE PRC_TMP_LIMPIAR_MOV_FAC_DUP()
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_num VARCHAR(20);
    DECLARE cur CURSOR FOR
        SELECT m.NUMERO_MOV
          FROM fza_movimientos_almacen m
         WHERE m.TIPO_DOC_MOV = 'FC'
           AND m.TIPO_MOV = 'S'
           AND (EXISTS (SELECT 1 FROM fza_movimientos_almacen v
                         WHERE v.TIPO_DOC_MOV = 'VE'
                           AND v.TIPO_MOV = 'S'
                           AND v.SERIE_DOC_MOV     = m.SERIE_DOC_MOV
                           AND v.NUMERO_DOC_MOV    = m.NUMERO_DOC_MOV
                           AND v.LINEA_MOV         = m.LINEA_MOV
                           AND v.CODIGO_UNIDAD_MOV =
                               m.CODIGO_UNIDAD_MOV)
                OR m.NUMERO_MOV >
                   (SELECT MIN(f.NUMERO_MOV)
                      FROM fza_movimientos_almacen f
                     WHERE f.TIPO_DOC_MOV = 'FC'
                       AND f.TIPO_MOV = 'S'
                       AND f.SERIE_DOC_MOV     = m.SERIE_DOC_MOV
                       AND f.NUMERO_DOC_MOV    = m.NUMERO_DOC_MOV
                       AND f.LINEA_MOV         = m.LINEA_MOV
                       AND f.CODIGO_UNIDAD_MOV =
                           m.CODIGO_UNIDAD_MOV));
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    OPEN cur;
    bucle: LOOP
        FETCH cur INTO v_num;
        IF v_done THEN
            LEAVE bucle;
        END IF;
        CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE(v_num);
    END LOOP;
    CLOSE cur;
END;;
DELIMITER ;
CALL PRC_TMP_LIMPIAR_MOV_FAC_DUP();
DROP PROCEDURE PRC_TMP_LIMPIAR_MOV_FAC_DUP;
-- 3) Comprobación: debe devolver 0 filas
SELECT m.NUMERO_MOV
  FROM fza_movimientos_almacen m
 WHERE m.TIPO_DOC_MOV = 'FC'
   AND m.TIPO_MOV = 'S'
   AND EXISTS (SELECT 1 FROM fza_movimientos_almacen v
                WHERE v.TIPO_DOC_MOV = 'VE'
                  AND v.TIPO_MOV = 'S'
                  AND v.SERIE_DOC_MOV     = m.SERIE_DOC_MOV
                  AND v.NUMERO_DOC_MOV    = m.NUMERO_DOC_MOV
                  AND v.LINEA_MOV         = m.LINEA_MOV
                  AND v.CODIGO_UNIDAD_MOV = m.CODIGO_UNIDAD_MOV);
