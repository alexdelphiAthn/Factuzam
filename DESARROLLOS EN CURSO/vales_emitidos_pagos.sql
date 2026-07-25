-- Apuntes de pago para vales emitidos ya migrados.
-- Idempotente: no duplica un apunte VALE negativo existente.
INSERT INTO `fza_caja_formas_pago`
  (`CODIGO_FP_CFP`,
   `DESCRIPCION_FORMA_PAGO_CFP`,
   `ESREQ_REFERENCIA_FORMA_PAGO_CFP`,
   `ESCRIPTO_FORMA_PAGO_CFP`,
   `ESDIVISA_FORMA_PAGO_CFP`,
   `ESACTIVO_FORMA_PAGO_CFP`,
   `ORDEN_VISUAL_FORMA_PAGO_CFP`,
   `INSTANTE_ALTA`,
   `INSTANTE_MODIF`,
   `USUARIO_ALTA`,
   `USUARIO_MODIF`)
SELECT 'VALE',
       'Vale tienda',
       'S',
       'N',
       'N',
       'S',
       90,
       NOW(),
       NOW(),
       'MIGRADOR',
       'MIGRADOR'
 WHERE NOT EXISTS (
       SELECT 1
         FROM `fza_caja_formas_pago`
        WHERE `CODIGO_FP_CFP` = 'VALE');
INSERT INTO `fza_caja_pagos`
  (`CODIGO_EMP_PAGO`,
   `CODIGO_ALM_PAGO`,
   `CODIGO_CAJA_PAGO`,
   `SERIE_OPERACION_PAGO`,
   `NUMERO_OPERACION_PAGO`,
   `NUMERO_LINEA_PAGO`,
   `CODIGO_FP_CFP`,
   `IMPORTE_ENTREGADO_PAGO`,
   `IMPORTE_CAMBIO_PAGO`,
   `CODIGO_DIVISA_PAGO`,
   `RED_BLOCKCHAIN_PAGO`,
   `FACTOR_CAMBIO_PAGO`,
   `IMPORTE_DIVISA_PAGO`,
   `REFERENCIA_FACPAG`,
   `OBSERVACIONES_PAGO`,
   `INSTANTE_ALTA`,
   `INSTANTE_MODIF`,
   `USUARIO_ALTA`)
SELECT v.`CODIGO_EMP_EMI_VL`,
       v.`CODIGO_ALM_EMI_VL`,
       v.`CODIGO_CAJA_EMI_VL`,
       '',
       v.`NUMERO_OPERACION_EMI_VL`,
       COALESCE((
         SELECT MAX(pm.`NUMERO_LINEA_PAGO`) + 1
           FROM `fza_caja_pagos` pm
          WHERE pm.`CODIGO_EMP_PAGO` = v.`CODIGO_EMP_EMI_VL`
            AND pm.`CODIGO_ALM_PAGO` = v.`CODIGO_ALM_EMI_VL`
            AND pm.`CODIGO_CAJA_PAGO` = v.`CODIGO_CAJA_EMI_VL`
            AND pm.`NUMERO_OPERACION_PAGO` =
                v.`NUMERO_OPERACION_EMI_VL`), 1),
       'VALE',
       -ABS(v.`IMPORTE_NOMINAL_VL`),
       0,
       NULL,
       NULL,
       1,
       0,
       v.`CODIGO_VL`,
       CONCAT('Vale emitido: ', v.`CODIGO_VL`),
       v.`INSTANTE_ALTA`,
       v.`INSTANTE_MODIF`,
       v.`USUARIO_ALTA`
  FROM `fza_caja_vales` v
 WHERE ABS(COALESCE(v.`IMPORTE_NOMINAL_VL`, 0)) >= 0.005
   AND NOT EXISTS (
       SELECT 1
         FROM `fza_caja_pagos` p
        WHERE p.`CODIGO_EMP_PAGO` = v.`CODIGO_EMP_EMI_VL`
          AND p.`CODIGO_ALM_PAGO` = v.`CODIGO_ALM_EMI_VL`
          AND p.`CODIGO_CAJA_PAGO` = v.`CODIGO_CAJA_EMI_VL`
          AND p.`NUMERO_OPERACION_PAGO` =
              v.`NUMERO_OPERACION_EMI_VL`
          AND p.`CODIGO_FP_CFP` = 'VALE'
          AND p.`IMPORTE_ENTREGADO_PAGO` < 0
          AND (
              p.`REFERENCIA_FACPAG` = v.`CODIGO_VL`
              OR ABS(p.`IMPORTE_ENTREGADO_PAGO`
                     + ABS(v.`IMPORTE_NOMINAL_VL`)) < 0.005));
