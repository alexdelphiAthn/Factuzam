SELECT "=== estado cola verifactu ===" AS x;
SELECT ESTADO_VFCOLA, COUNT(*) AS n, MIN(NUMERO_FAC_VFCOLA) AS min_fac, MAX(NUMERO_FAC_VFCOLA) AS max_fac
  FROM fza_verifactu_cola GROUP BY ESTADO_VFCOLA;
SELECT "=== ultimos verifactu ===" AS x;
SELECT ID_VFCOLA, ESTADO_VFCOLA, NUMERO_FAC_VFCOLA, CONTADOR_INTENTOS_VFCOLA,
       DATE_FORMAT(INSTANTE_MODIF,"%H:%i:%s") AS modif
  FROM fza_verifactu_cola ORDER BY ID_VFCOLA DESC LIMIT 6;
SELECT "=== cola ventas ws ===" AS x;
SELECT ID_VWSC, ESTADO_VWSC, NUMERO_FAC_VWSC, TIPO_EVENTO_VWSC, CONTADOR_INTENTOS_VWSC,
       LEFT(MENSAJE_ERROR_VWSC,60) AS err
  FROM fza_ventas_ws_cola ORDER BY ID_VWSC DESC LIMIT 8;
SELECT "=== params API/ventas ws ===" AS x;
SELECT SUBKEY_USUPER, IF(VALUE_USUPER="","(vacio)",VALUE_USUPER) AS valor
  FROM fza_usuarios_perfiles
 WHERE KEY_USUPER="frmMtoAppParam"
   AND SUBKEY_USUPER IN ("appApiUrl","appApiToken","appApiReferencia",
       "appVentasWsSegundosCiclo","appVentasWsMaxIntentos",
       "appVerifactuActivo","appVerifactuEntorno","appVerifactuSegundosCiclo","appVerifactuMaxIntentos");
