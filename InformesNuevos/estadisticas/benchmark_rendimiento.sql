-- =============================================================================
-- Lab de control de rendimiento: VISTA vs TABLA (vs tablas base en vivo)
-- =============================================================================
-- Mide el coste de la MISMA consulta del panel (comparativa diaria de ventas
-- de un rango) con tres estrategias y guarda los tiempos en un log:
--   1) VISTA  : viest_dia (vista unificada con GROUP BY -> TEMPTABLE)
--   2) BASE   : joins en vivo sobre tablas base, filtrando por fecha (lo que
--               hace HOY el panel .pas)
--   3) TABLA  : fzaest_estadisticas_dia (pre-agregado)
--
-- Namespace propio: tabla/SP con prefijo fzaest_, vistas viest_. Desechable.
-- Requiere haber cargado vistas_estadisticas.sql y fzaest_experimental.sql
-- (y un CALL fzaest_recalcular_rango(...) previo para llenar la tabla).
-- =============================================================================
CREATE TABLE IF NOT EXISTS fzaest_benchmark_log (
  ID            int AUTO_INCREMENT PRIMARY KEY,
  INSTANTE      datetime      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FDESDE        date          NOT NULL,
  FHASTA        date          NOT NULL,
  VUELTAS       int           NOT NULL,
  MS_VISTA      decimal(12,3) NULL,
  MS_BASE       decimal(12,3) NULL,
  MS_TABLA      decimal(12,3) NULL,
  FACTOR_V_T    decimal(12,2) NULL COMMENT 'MS_VISTA / MS_TABLA',
  FACTOR_B_T    decimal(12,2) NULL COMMENT 'MS_BASE  / MS_TABLA'
);
DROP PROCEDURE IF EXISTS fzaest_benchmark;
DELIMITER //
CREATE PROCEDURE fzaest_benchmark(IN pD1 date, IN pD2 date, IN pVueltas int)
BEGIN
  DECLARE i INT;
  -- 1) VISTA unificada (viest_dia)
  SET i = 0;
  SET @ini = NOW(6);
  WHILE i < pVueltas DO
    SELECT COUNT(*) INTO @x FROM (
      SELECT DATEDIFF(FECHA, pD1) AS B, SUM(IMPORTE_VENTA) AS V
        FROM viest_dia
       WHERE FECHA >= pD1 AND FECHA <= pD2
       GROUP BY B) q;
    SET i = i + 1;
  END WHILE;
  SET @ms_vista = TIMESTAMPDIFF(MICROSECOND, @ini, NOW(6)) / 1000.0 / pVueltas;
  -- 2) BASE en vivo (lo que hace el panel: líneas de factura por fecha)
  SET i = 0;
  SET @ini = NOW(6);
  WHILE i < pVueltas DO
    SELECT COUNT(*) INTO @x FROM (
      SELECT DATEDIFF(f.FECHA_FAC, pD1) AS B,
             COALESCE(SUM(l.TOTAL_FACLIN), 0) AS V
        FROM fza_facturas_lineas l
        JOIN fza_facturas f
          ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN
         AND f.SERIE_FAC  = l.SERIE_FAC_FACLIN
       WHERE f.FECHA_FAC >= pD1
         AND f.FECHA_FAC <  DATE_ADD(pD2, INTERVAL 1 DAY)
       GROUP BY B) q;
    SET i = i + 1;
  END WHILE;
  SET @ms_base = TIMESTAMPDIFF(MICROSECOND, @ini, NOW(6)) / 1000.0 / pVueltas;
  -- 3) TABLA pre-agregada (fzaest_estadisticas_dia)
  SET i = 0;
  SET @ini = NOW(6);
  WHILE i < pVueltas DO
    SELECT COUNT(*) INTO @x FROM (
      SELECT DATEDIFF(FECHA, pD1) AS B, SUM(IMPORTE_VENTA) AS V
        FROM fzaest_estadisticas_dia
       WHERE FECHA >= pD1 AND FECHA <= pD2
       GROUP BY B) q;
    SET i = i + 1;
  END WHILE;
  SET @ms_tabla = TIMESTAMPDIFF(MICROSECOND, @ini, NOW(6)) / 1000.0 / pVueltas;
  INSERT INTO fzaest_benchmark_log
    (FDESDE, FHASTA, VUELTAS, MS_VISTA, MS_BASE, MS_TABLA,
     FACTOR_V_T, FACTOR_B_T)
  VALUES
    (pD1, pD2, pVueltas, @ms_vista, @ms_base, @ms_tabla,
     CASE WHEN @ms_tabla > 0 THEN @ms_vista / @ms_tabla END,
     CASE WHEN @ms_tabla > 0 THEN @ms_base  / @ms_tabla END);
  -- Resumen de esta ejecución (ms medios por consulta)
  SELECT pD1 AS FDESDE, pD2 AS FHASTA, pVueltas AS VUELTAS,
         ROUND(@ms_vista, 2) AS MS_VISTA,
         ROUND(@ms_base,  2) AS MS_BASE,
         ROUND(@ms_tabla, 2) AS MS_TABLA,
         CASE WHEN @ms_tabla > 0
              THEN ROUND(@ms_vista / @ms_tabla, 1) END AS VISTA_x_TABLA,
         CASE WHEN @ms_tabla > 0
              THEN ROUND(@ms_base  / @ms_tabla, 1) END AS BASE_x_TABLA;
END //
DELIMITER ;
-- -----------------------------------------------------------------------------
-- Uso:
--   -- 1 mes:
--   CALL fzaest_benchmark('2026-01-01', '2026-01-31', 20);
--   -- 1 año:
--   CALL fzaest_benchmark('2025-01-01', '2025-12-31', 10);
--   -- 5 años (donde el pre-agregado debería despuntar):
--   CALL fzaest_benchmark('2021-01-01', '2025-12-31', 5);
--   -- Histórico de mediciones:
--   SELECT * FROM fzaest_benchmark_log ORDER BY ID DESC;
-- Limpieza:
--   DROP PROCEDURE IF EXISTS fzaest_benchmark;
--   DROP TABLE     IF EXISTS fzaest_benchmark_log;
-- -----------------------------------------------------------------------------
