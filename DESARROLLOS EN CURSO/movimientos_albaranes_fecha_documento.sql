-- Corrige movimientos de albaranes ya generados con fecha de sistema.
-- Idempotente: solo actualiza filas cuya fecha difiere del documento.
UPDATE fza_movimientos_almacen m
  JOIN fza_albaranes a
    ON a.SERIE_ALB = m.SERIE_DOC_MOV
   AND a.NUMERO_ALB = m.NUMERO_DOC_MOV
   SET m.FECHA_MOV = a.FECHA_ALB
 WHERE m.TIPO_DOC_MOV = 'AV'
   AND a.FECHA_ALB IS NOT NULL
   AND (m.FECHA_MOV IS NULL OR DATE(m.FECHA_MOV) <> a.FECHA_ALB);
UPDATE fza_movimientos_almacen m
  JOIN fza_albaranes_compra a
    ON a.SERIE_ALBC = m.SERIE_DOC_MOV
   AND a.NUMERO_ALBC = m.NUMERO_DOC_MOV
   SET m.FECHA_MOV = a.FECHA_ALBC
 WHERE m.TIPO_DOC_MOV = 'AC'
   AND a.FECHA_ALBC IS NOT NULL
   AND (m.FECHA_MOV IS NULL OR DATE(m.FECHA_MOV) <> a.FECHA_ALBC);
