-- Linea base para los puntos 5 a 8 de la Fase XII-D.
-- Solo lectura: no modifica datos ni esquema.
-- Guardar la salida antes de empezar; los valores cambian con
-- cualquier uso de la aplicacion.
-- Anotar tambien el instante exacto de inicio de las pruebas: la
-- limpieza se acota por INSTANTE_ALTA a partir de ese momento.
SELECT NOW() AS instante_inicio_pruebas;
SELECT "caja_operaciones" AS tabla, COUNT(*) AS filas,
       CAST(MAX(ID_OPCAJA) AS CHAR) AS ultimo
  FROM fza_caja_operaciones
UNION ALL
SELECT "caja_pagos", COUNT(*), CAST(MAX(NUMERO_OPERACION_PAGO) AS CHAR)
  FROM fza_caja_pagos
UNION ALL
SELECT "caja_vales", COUNT(*), CAST(MAX(CODIGO_VL) AS CHAR)
  FROM fza_caja_vales
UNION ALL
SELECT "caja_arqueos", COUNT(*), CAST(MAX(CODIGO_ARQ) AS CHAR)
  FROM fza_caja_arqueos
UNION ALL
SELECT "facturas_serie_009", COUNT(*), CAST(MAX(NUMERO_FAC) AS CHAR)
  FROM fza_facturas WHERE SERIE_FAC = "009"
UNION ALL
SELECT "movimientos_almacen", COUNT(*), CAST(MAX(NUMERO_MOV) AS CHAR)
  FROM fza_movimientos_almacen
UNION ALL
SELECT "verifactu_cola", COUNT(*), CAST(MAX(ID_VFCOLA) AS CHAR)
  FROM fza_verifactu_cola
UNION ALL
SELECT "ventas_ws_cola", COUNT(*), CAST(MAX(ID_VWSC) AS CHAR)
  FROM fza_ventas_ws_cola;
-- Stock de los SKUs implicados, para poder reponerlo despues.
SELECT CODIGO_ALM_STK, CODIGO_UNIDAD_STK, CANTIDAD_STK
  FROM fza_articulos_stockactual
 WHERE CODIGO_ALM_STK = "GEN"
   AND CODIGO_UNIDAD_STK IN ("CAMI-BASICA/BLANCO/M",
                             "CAMI-POLO/AZUL/M");
-- Contadores de la empresa y serie de venta usadas.
SELECT TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON
  FROM fza_contadores
 WHERE EMPRESA_CON = "012";
