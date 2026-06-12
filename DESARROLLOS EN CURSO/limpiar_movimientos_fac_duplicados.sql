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
-- Borra los duplicados revirtiendo el stock. Para un movimiento
-- 'FC'+'S', PRC_FZA_AJUSTAR_ACUMULADO_STK solo toca CANTIDAD_STK,
-- VALOR_TOTAL_STK y PRECIO_MEDIO_STK (ningún acumulado por tipo de
-- documento aplica a 'FC'), así que la reversión se hace aquí en SQL
-- plano: sin DELIMITER ni procedimientos, ejecutable desde cualquier
-- cliente (incluido el ejecutor SQL de fzam).
-- Idempotente: en una segunda pasada no encuentra nada.
--
-- 1) Duplicados a borrar:
--    a) salidas 'FC' que duplican una salida 'VE' de la misma
--       factura/línea/SKU (el caso caja), y
--    b) salidas 'FC' repetidas entre sí (se conserva la de menor
--       NUMERO_MOV).
DROP TEMPORARY TABLE IF EXISTS tmp_mov_dup;
CREATE TEMPORARY TABLE tmp_mov_dup AS
SELECT m.NUMERO_MOV, m.SERIE_DOC_MOV, m.NUMERO_DOC_MOV, m.LINEA_MOV,
       m.CODIGO_ALM_MOV, m.CODIGO_UNIDAD_MOV,
       m.CANTIDAD_MOV, m.TOTAL_COSTE_MOV, m.FECHA_MOV
  FROM fza_movimientos_almacen m
 WHERE m.TIPO_DOC_MOV = 'FC'
   AND m.TIPO_MOV = 'S'
   AND m.ESACTIVO_MOV = 'S'
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
-- 2) Informe previo: qué se va a borrar
SELECT * FROM tmp_mov_dup;
-- 3) Revertir el stock de las salidas que se van a borrar (la
--    cantidad vuelve al almacén; el PMP se recalcula con los valores
--    ya repuestos)
UPDATE fza_articulos_stockactual s
  JOIN (SELECT CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
               SUM(CANTIDAD_MOV)    AS CANT,
               SUM(TOTAL_COSTE_MOV) AS VALOR
          FROM tmp_mov_dup
         GROUP BY CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV) d
    ON d.CODIGO_ALM_MOV    = s.CODIGO_ALM_STK
   AND d.CODIGO_UNIDAD_MOV = s.CODIGO_UNIDAD_STK
   SET s.PRECIO_MEDIO_STK = IF(s.CANTIDAD_STK + d.CANT > 0,
                               (s.VALOR_TOTAL_STK + d.VALOR) /
                               (s.CANTIDAD_STK + d.CANT), 0),
       s.CANTIDAD_STK     = s.CANTIDAD_STK + d.CANT,
       s.VALOR_TOTAL_STK  = s.VALOR_TOTAL_STK + d.VALOR,
       s.INSTANTE_MODIF   = NOW();
-- 4) Borrar los movimientos duplicados
DELETE m
  FROM fza_movimientos_almacen m
  JOIN tmp_mov_dup d
    ON d.NUMERO_MOV = m.NUMERO_MOV;
DROP TEMPORARY TABLE IF EXISTS tmp_mov_dup;
-- 5) Comprobación: debe devolver 0 filas
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
