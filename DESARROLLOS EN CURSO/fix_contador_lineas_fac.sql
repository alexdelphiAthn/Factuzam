-- =============================================================================
-- Fix CONTADOR_LINEAS_FAC en fza_facturas
-- =============================================================================
-- Sincroniza el contador de lineas de la cabecera con la ultima linea real
-- almacenada en fza_facturas_lineas. Sirve para reparar facturas creadas
-- antes del fix (sobre todo las grabadas desde caja, que no escribian
-- CONTADOR_LINEAS_FAC y lo dejaban en NULL).
--
-- Sin esta correccion, al reabrir una factura antigua y anadirle una
-- linea, el SP/calculo arrancaba en '010' y chocaba con la PK
-- (NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN).
--
-- Idempotente: se puede ejecutar varias veces sin efectos secundarios.
-- =============================================================================

UPDATE fza_facturas AS F
   JOIN (
       SELECT NUMERO_FAC_FACLIN,
              SERIE_FAC_FACLIN,
              LPAD(MAX(CAST(LINEA_FACLIN AS UNSIGNED)), 3, '0') AS ULTIMA_LINEA
         FROM fza_facturas_lineas
        GROUP BY NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN
   ) AS L
     ON L.NUMERO_FAC_FACLIN = F.NUMERO_FAC
    AND L.SERIE_FAC_FACLIN  = F.SERIE_FAC
  SET F.CONTADOR_LINEAS_FAC = L.ULTIMA_LINEA
WHERE F.CONTADOR_LINEAS_FAC IS NULL
   OR F.CONTADOR_LINEAS_FAC = ''
   OR F.CONTADOR_LINEAS_FAC = '0'
   OR CAST(F.CONTADOR_LINEAS_FAC AS UNSIGNED) <
      CAST(L.ULTIMA_LINEA      AS UNSIGNED);
