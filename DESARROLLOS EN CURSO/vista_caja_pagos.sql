-- ===========================================================================
-- Vista: vi_caja_pagos
-- ---------------------------------------------------------------------------
-- fza_caja_pagos no tiene columna de fecha propia (solo INSTANTE_ALTA, que es
-- el instante de grabacion de la fila). Esta vista expone FECHA_PAGO: la fecha
-- de la operacion de caja a la que pertenece el pago (fza_caja_operaciones) y,
-- si no se localiza, INSTANTE_ALTA como respaldo.
--
-- La usa el informe A4 de historico de pagos (inMtoModalImpPagos) para filtrar
-- por rango de fechas y mostrar la fecha del pago. NO modifica fza_caja_pagos
-- ni el dump base.
--
-- La fecha se resuelve con una subconsulta correlacionada (MIN) en lugar de un
-- JOIN para no multiplicar filas: una misma operacion puede tener varias lineas
-- en fza_caja_operaciones (p. ej. venta + vale comparten NUMERO_OPERACION).
--
-- Idempotente: CREATE OR REPLACE VIEW.
-- ===========================================================================
CREATE OR REPLACE VIEW vi_caja_pagos AS
SELECT
  p.*,
  COALESCE(
    (SELECT MIN(o.FECHA_OPERACION_OPCAJA)
       FROM fza_caja_operaciones o
      WHERE o.CODIGO_EMP_OPCAJA       = p.CODIGO_EMP_PAGO
        AND o.CODIGO_ALM_OPCAJA       = p.CODIGO_ALM_PAGO
        AND o.CODIGO_CAJA_OPCAJA      = p.CODIGO_CAJA_PAGO
        AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO),
    p.INSTANTE_ALTA
  ) AS FECHA_PAGO
FROM fza_caja_pagos p;
