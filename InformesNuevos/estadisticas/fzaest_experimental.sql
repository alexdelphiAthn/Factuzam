-- =============================================================================
-- Experimento de pre-agregado — namespace PROPIO 'fzaest_' (NO 'fza_')
-- =============================================================================
-- Para PROBAR si una tabla de acumulados acelera frente a la vista en vivo,
-- sin tocar el esquema real. Todo lo de aquí usa el prefijo 'fzaest_' (tablas)
-- para diferenciarlo de 'fza_'. Es desechable: un DROP de las fzaest_* deja la
-- BBDD como estaba. Depende de vistas_estadisticas.sql (lee viest_dia).
--
-- Al ser un sandbox aislado, NO se siguen las convenciones de columnas de
-- 'fza_' (sufijo por tabla, etc.): nombres planos para legibilidad.
-- =============================================================================
-- Tabla de acumulado diario (mismo grano y medidas que viest_dia)
CREATE TABLE IF NOT EXISTS fzaest_estadisticas_dia (
  FECHA            date          NOT NULL,
  CODIGO_ALMACEN   varchar(10)   NOT NULL,
  CODIGO_FAMILIA   varchar(20)   NOT NULL DEFAULT '',
  TEMPORADA        varchar(100)  NOT NULL DEFAULT '',
  NUM_MOVIMIENTOS  int           NOT NULL DEFAULT 0,
  UNIDADES_MOV     decimal(19,6) NOT NULL DEFAULT 0,
  COSTE_MOV        decimal(19,6) NOT NULL DEFAULT 0,
  NUM_LINEAS_VENTA int           NOT NULL DEFAULT 0,
  UNIDADES_VENTA   decimal(19,6) NOT NULL DEFAULT 0,
  IMPORTE_VENTA    decimal(19,6) NOT NULL DEFAULT 0,
  INSTANTE_REFRESCO timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA),
  KEY IDX_FZAEST_FAM_FECHA  (CODIGO_FAMILIA, FECHA),
  KEY IDX_FZAEST_TEMP_FECHA (TEMPORADA, FECHA)
);
-- Recálculo incremental de un rango: borra y reinserta solo esos días, de modo
-- que tolera correcciones retroactivas (movimientos anulados, reclasificación
-- de familia/temporada). Se alimenta de la vista unificada.
DROP PROCEDURE IF EXISTS fzaest_recalcular_rango;
DELIMITER //
CREATE PROCEDURE fzaest_recalcular_rango(IN pD1 date, IN pD2 date)
BEGIN
  DELETE FROM fzaest_estadisticas_dia WHERE FECHA BETWEEN pD1 AND pD2;
  INSERT INTO fzaest_estadisticas_dia
    (FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA,
     NUM_MOVIMIENTOS, UNIDADES_MOV, COSTE_MOV,
     NUM_LINEAS_VENTA, UNIDADES_VENTA, IMPORTE_VENTA)
  SELECT FECHA, CODIGO_ALMACEN, CODIGO_FAMILIA, TEMPORADA,
         NUM_MOVIMIENTOS, UNIDADES_MOV, COSTE_MOV,
         NUM_LINEAS_VENTA, UNIDADES_VENTA, IMPORTE_VENTA
    FROM viest_dia
   WHERE FECHA BETWEEN pD1 AND pD2;
END //
DELIMITER ;
-- -----------------------------------------------------------------------------
-- Uso / benchmark:
--   CALL fzaest_recalcular_rango('2020-01-01', CURDATE());   -- carga inicial
--   -- Comparar tiempos del MISMO rango largo:
--   --   en vivo:        SELECT ... FROM viest_dia      WHERE ...
--   --   pre-agregado:   SELECT ... FROM fzaest_estadisticas_dia  WHERE ...
-- Limpieza total del experimento:
--   DROP PROCEDURE IF EXISTS fzaest_recalcular_rango;
--   DROP TABLE     IF EXISTS fzaest_estadisticas_dia;
-- -----------------------------------------------------------------------------
