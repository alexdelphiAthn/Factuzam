-- Reparar contadores de líneas desincronizados en facturas existentes.
-- NO modifica el SP (la lógica atómica con LAST_INSERT_ID es correcta).
-- La corrección de raíz está en el BeforePost de UniDataFacturas.pas:
-- ahora llama al SP siempre que DataSet.State = dsInsert.
UPDATE fza_facturas f
   SET CONTADOR_LINEAS_FAC = (
       SELECT LPAD(COALESCE(MAX(CAST(l.LINEA_FACLIN AS UNSIGNED)), 0) + 10, 3, '0')
         FROM fza_facturas_lineas l
        WHERE l.NUMERO_FAC_FACLIN = f.NUMERO_FAC
          AND l.SERIE_FAC_FACLIN  = f.SERIE_FAC
   )
 WHERE CONTADOR_LINEAS_FAC IS NULL
    OR CONTADOR_LINEAS_FAC = ''
    OR CONTADOR_LINEAS_FAC = '0'
    OR CAST(CONTADOR_LINEAS_FAC AS UNSIGNED) < (
       SELECT COALESCE(MAX(CAST(l2.LINEA_FACLIN AS UNSIGNED)), 0)
         FROM fza_facturas_lineas l2
        WHERE l2.NUMERO_FAC_FACLIN = f.NUMERO_FAC
          AND l2.SERIE_FAC_FACLIN  = f.SERIE_FAC
   );
