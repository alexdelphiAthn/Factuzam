-- ===========================================================================
-- Vista: vi_caja_pagos
-- ---------------------------------------------------------------------------
-- fza_caja_pagos no tiene columna de fecha propia (solo INSTANTE_ALTA, que es
-- el instante de grabacion de la fila) ni el numero de factura. Esta vista
-- enriquece cada pago con datos de la operacion de caja a la que pertenece
-- (fza_caja_operaciones):
--   FECHA_PAGO       : FECHA_OPERACION_OPCAJA de la operacion (o INSTANTE_ALTA
--                      como respaldo si no se localiza).
--   NUMERO_FAC_PAGO  : numero de factura de la operacion.
--   SERIE_FAC_PAGO   : serie de factura de la operacion.
--
-- La usa el informe A4 de historico de pagos (inMtoModalImpPagos) para filtrar
-- por rango de fechas / forma de pago y mostrar fecha y numero de factura. NO
-- modifica fza_caja_pagos ni el dump base.
--
-- Se enlaza con una subconsulta agregada (GROUP BY) en lugar de un JOIN directo
-- para no multiplicar filas: una misma operacion puede tener varias lineas en
-- fza_caja_operaciones (p. ej. venta + vale comparten NUMERO_OPERACION).
--
-- Idempotente: CREATE OR REPLACE VIEW.
-- ===========================================================================
CREATE OR REPLACE VIEW vi_caja_pagos AS
SELECT
  p.*,
  COALESCE(o.FECHA_OP, p.INSTANTE_ALTA) AS FECHA_PAGO,
  o.NUM_FAC                             AS NUMERO_FAC_PAGO,
  o.SERIE_FAC                           AS SERIE_FAC_PAGO
FROM fza_caja_pagos p
LEFT JOIN (
  SELECT
    CODIGO_EMP_OPCAJA,
    CODIGO_ALM_OPCAJA,
    CODIGO_CAJA_OPCAJA,
    NUMERO_OPERACION_OPCAJA,
    MIN(FECHA_OPERACION_OPCAJA) AS FECHA_OP,
    MAX(NUMERO_FAC_OPCAJA)      AS NUM_FAC,
    MAX(SERIE_FAC_OPCAJA)       AS SERIE_FAC
  FROM fza_caja_operaciones
  GROUP BY
    CODIGO_EMP_OPCAJA,
    CODIGO_ALM_OPCAJA,
    CODIGO_CAJA_OPCAJA,
    NUMERO_OPERACION_OPCAJA
) o
  ON  o.CODIGO_EMP_OPCAJA       = p.CODIGO_EMP_PAGO
  AND o.CODIGO_ALM_OPCAJA       = p.CODIGO_ALM_PAGO
  AND o.CODIGO_CAJA_OPCAJA      = p.CODIGO_CAJA_PAGO
  AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO;
