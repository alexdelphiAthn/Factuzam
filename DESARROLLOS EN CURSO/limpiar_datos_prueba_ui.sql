-- ============================================================================
-- limpiar_datos_prueba_ui.sql
-- ----------------------------------------------------------------------------
-- Deshace los datos que se crearon durante las pruebas funcionales de
-- interfaz del 26/07/2026 en la BBDD de DESARROLLO (127.0.0.1 / Factuzam):
--
--   * 1 efecto de cobro de 726,00 EUR generado desde la factura A1/000028
--     (empresa 1), vencimiento 22/02/2026.
--   * Remesa de cobro serie '-' numero '000001' (fecha 26/07/2026, ABIERTA)
--     que quedo con ese efecto dentro.
--
-- NO ejecutar en produccion. Revisar los SELECT de comprobacion antes de
-- lanzar los DELETE: si en tu BBDD la remesa '-'/'000001' es real, para.
-- ============================================================================

-- 1) Comprobacion previa: que hay exactamente lo que esperamos borrar
SELECT 'efecto de la prueba' AS que, e.*
  FROM fza_efectos_venta e
 WHERE e.SERIE_FAC_EFV  = 'A1'
   AND e.NUMERO_FAC_EFV = '000028';

SELECT 'remesa de la prueba' AS que, r.*
  FROM fza_remesas_venta r
 WHERE r.SERIE_REMV  = '-'
   AND r.NUMERO_REMV = '000001'
   AND r.FECHA_REMV  = '2026-07-26';

-- 2) Soltar el efecto de la remesa (deja el efecto como PENDIENTE)
UPDATE fza_efectos_venta
   SET SERIE_REMV_EFV  = NULL,
       NUMERO_REMV_EFV = NULL,
       ESTADO_EFV      = 'PENDIENTE',
       INSTANTE_MODIF  = NOW(),
       USUARIO_MODIF   = 'LIMPIEZA'
 WHERE SERIE_FAC_EFV  = 'A1'
   AND NUMERO_FAC_EFV = '000028';

-- 3) Borrar la remesa vacia
DELETE FROM fza_remesas_venta
 WHERE SERIE_REMV  = '-'
   AND NUMERO_REMV = '000001'
   AND FECHA_REMV  = '2026-07-26';

-- 4) Borrar el efecto generado en la prueba
DELETE FROM fza_efectos_venta
 WHERE SERIE_FAC_EFV  = 'A1'
   AND NUMERO_FAC_EFV = '000028';

-- 5) Comprobacion final: las dos consultas deben devolver 0 filas
SELECT COUNT(*) AS efectos_restantes
  FROM fza_efectos_venta
 WHERE SERIE_FAC_EFV = 'A1' AND NUMERO_FAC_EFV = '000028';

SELECT COUNT(*) AS remesas_restantes
  FROM fza_remesas_venta
 WHERE SERIE_REMV = '-' AND NUMERO_REMV = '000001'
   AND FECHA_REMV = '2026-07-26';
