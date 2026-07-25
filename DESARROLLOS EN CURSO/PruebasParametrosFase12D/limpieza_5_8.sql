-- Limpieza acotada de los puntos 5 a 8 de la Fase XII-D.
-- NO ejecutar sin haber leido PLAN_PRUEBAS_5_8.md: este borrado no
-- devuelve la BBDD a su estado anterior. No rebobina contadores, no
-- recalcula stock y no puede reparar la cadena Verifactu.
-- Lo preferible es ejecutar las pruebas sobre una copia y restaurarla.
-- 1. Instante de inicio de las pruebas, tomado de la linea base. Se
--    borra todo lo dado de alta a partir de ese momento.
SET @FECHA_DESDE = NULL;
-- 2. Confirmacion explicita. Cambiar a "SI" para que el script actue.
SET @CONFIRMO = "NO";
-- 3. Salvaguarda: si falta la fecha o la confirmacion, no borra nada.
SET @SEGURO = ((@CONFIRMO = "SI") AND (@FECHA_DESDE IS NOT NULL));
SELECT IF(@SEGURO, "Se procede al borrado acotado",
          "Falta fecha o confirmacion: no se borra nada") AS aviso;
-- 4. Recuento previo de lo que se va a borrar, para dejar constancia.
SELECT "caja_pagos" AS tabla, COUNT(*) AS a_borrar
  FROM fza_caja_pagos WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "caja_operaciones", COUNT(*)
  FROM fza_caja_operaciones WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "caja_vales", COUNT(*)
  FROM fza_caja_vales WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "caja_arqueos", COUNT(*)
  FROM fza_caja_arqueos WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "facturas_lineas", COUNT(*)
  FROM fza_facturas_lineas WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "facturas", COUNT(*)
  FROM fza_facturas WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "movimientos_almacen", COUNT(*)
  FROM fza_movimientos_almacen WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "verifactu_cola", COUNT(*)
  FROM fza_verifactu_cola WHERE INSTANTE_ALTA >= @FECHA_DESDE
UNION ALL
SELECT "ventas_ws_cola", COUNT(*)
  FROM fza_ventas_ws_cola WHERE INSTANTE_ALTA >= @FECHA_DESDE;
-- 5. Borrado en orden de dependencia.
DELETE FROM fza_caja_pagos
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_caja_operaciones
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_caja_vales
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_caja_arqueos
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_facturas_lineas
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_facturas
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_movimientos_almacen
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_ventas_ws_cola
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
DELETE FROM fza_verifactu_cola
 WHERE @SEGURO AND INSTANTE_ALTA >= @FECHA_DESDE;
-- 6. Lo que este script NO arregla y hay que resolver aparte:
--    - el stock de fza_articulos_stockactual no se recalcula solo;
--    - los contadores de fza_contadores no se rebobinan;
--    - la cadena de fza_verifactu_cadena queda rota si el registro
--      llego a firmarse. Es la razon de no ejecutar el punto 8 aqui.
SELECT "Revisar stock, contadores y cadena Verifactu" AS pendiente;
