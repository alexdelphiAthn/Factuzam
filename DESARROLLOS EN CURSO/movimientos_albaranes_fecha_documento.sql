-- Corrige movimientos de albaranes ya generados con fecha de sistema.
-- Idempotente: solo actualiza filas cuya fecha difiere del documento.
UPDATE fza_movimientos_almacen m
  JOIN fza_albaranes a
    ON a.SERIE_ALB = m.SERIE_DOC_MOV
   AND a.NUMERO_ALB = m.NUMERO_DOC_MOV
   SET m.FECHA_MOV = COALESCE(a.INSTANTE_MOVIMIENTO_ALB, a.FECHA_ALB)
 WHERE m.TIPO_DOC_MOV = 'AV'
   AND a.FECHA_ALB IS NOT NULL
   AND (m.FECHA_MOV IS NULL OR m.FECHA_MOV <>
        COALESCE(a.INSTANTE_MOVIMIENTO_ALB, a.FECHA_ALB));
UPDATE fza_movimientos_almacen m
  JOIN fza_albaranes_compra a
    ON a.SERIE_ALBC = m.SERIE_DOC_MOV
   AND a.NUMERO_ALBC = m.NUMERO_DOC_MOV
   SET m.FECHA_MOV = COALESCE(a.INSTANTE_MOVIMIENTO_ALBC, a.FECHA_ALBC)
 WHERE m.TIPO_DOC_MOV = 'AC'
   AND a.FECHA_ALBC IS NOT NULL
   AND (m.FECHA_MOV IS NULL OR m.FECHA_MOV <>
        COALESCE(a.INSTANTE_MOVIMIENTO_ALBC, a.FECHA_ALBC));
UPDATE fza_movimientos_almacen m
  JOIN fza_devoluciones_compra d
    ON d.SERIE_DEVC = m.SERIE_DOC_MOV
   AND d.NUMERO_DEVC = m.NUMERO_DOC_MOV
   SET m.FECHA_MOV = COALESCE(d.INSTANTE_MOVIMIENTO_DEVC, d.FECHA_DEVC)
 WHERE m.TIPO_DOC_MOV = 'DC'
   AND d.FECHA_DEVC IS NOT NULL
   AND (m.FECHA_MOV IS NULL OR m.FECHA_MOV <>
        COALESCE(d.INSTANTE_MOVIMIENTO_DEVC, d.FECHA_DEVC));
