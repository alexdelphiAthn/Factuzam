-- ============================================================================
--  depositos_netear_devoluciones.sql
--  Cuadra las DEVOLUCIONES de prestamos/depositos en fza_depositos_cliente.
--  ------------------------------------------------------------------------
--  Contexto: la migracion crea un deposito por cada linea de albaran (AL),
--  copiando la Cantidad tal cual. Las lineas de DEVOLUCION (Cantidad -1)
--  quedaban como un deposito -1 PENDIENTE y NO cerraban su prestamo +1
--  original. Resultado: pares (+1 / -1) del mismo cliente y SKU abiertos
--  cuando deberian netear a cero y quedar ambos CERRADO.
--
--  Este script, por (cliente, SKU = CODIGO_UNIDAD_DEP) y FIFO por fecha:
--    1) cierra los N prestamos +1 mas antiguos (N = nº de devoluciones del SKU)
--    2) cierra todas las devoluciones -1 (incluidas las huerfanas sin +1)
--  Asume 1 ud por linea (CANTIDAD_PENDIENTE_DEP = ±1).
--  Idempotente: re-ejecutar no hace nada (ya no quedan -1 PENDIENTE).
--  IMPORTANTE el ORDEN: (1) ANTES que (2), porque (1) cuenta las devoluciones
--  mientras siguen PENDIENTE. (Si solo quieres tocar los depositos migrados,
--  anade  AND USUARIO_ALTA = '<usuario_migracion>'  en los tres WHERE.)
-- ============================================================================

-- 1) Cerrar los N prestamos +1 mas antiguos por (cliente, SKU).
UPDATE fza_depositos_cliente d
JOIN (
  SELECT p.ID_DEPOSITO_DEP
    FROM (
      SELECT ID_DEPOSITO_DEP, CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP,
             ROW_NUMBER() OVER (
               PARTITION BY CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP
               ORDER BY FECHA_CREACION_DEP, ID_DEPOSITO_DEP) AS rn
        FROM fza_depositos_cliente
       WHERE CANTIDAD_PENDIENTE_DEP > 0 AND ESTADO_DEP = 'PENDIENTE'
    ) p
    JOIN (
      SELECT CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP, COUNT(*) AS n_ret
        FROM fza_depositos_cliente
       WHERE CANTIDAD_PENDIENTE_DEP < 0 AND ESTADO_DEP = 'PENDIENTE'
       GROUP BY CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP
    ) r ON r.CODIGO_CLI_DEP = p.CODIGO_CLI_DEP
       AND r.CODIGO_UNIDAD_DEP = p.CODIGO_UNIDAD_DEP
   WHERE p.rn <= r.n_ret
) m ON m.ID_DEPOSITO_DEP = d.ID_DEPOSITO_DEP
   SET d.ESTADO_DEP = 'CERRADO', d.INSTANTE_MODIF = NOW();

-- 2) Cerrar todas las devoluciones -1 (incluidas las huerfanas sin +1).
UPDATE fza_depositos_cliente
   SET ESTADO_DEP = 'CERRADO', INSTANTE_MODIF = NOW()
 WHERE CANTIDAD_PENDIENTE_DEP < 0 AND ESTADO_DEP = 'PENDIENTE';

-- Verificacion (opcional): deberia devolver 0 devoluciones PENDIENTE.
-- SELECT COUNT(*) AS devoluciones_pendientes
--   FROM fza_depositos_cliente
--  WHERE CANTIDAD_PENDIENTE_DEP < 0 AND ESTADO_DEP = 'PENDIENTE';
