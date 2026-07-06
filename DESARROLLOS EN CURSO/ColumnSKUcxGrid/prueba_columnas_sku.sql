-- ============================================================================
-- prueba_columnas_sku.sql — infraestructura MINIMA para probar el modo
-- Tallas en horizontal (mcsTallasInline) del desarrollo ColumnSKUcxGrid.
--
-- Crea SOLO la tabla de celdas de prueba fza_prueba_skucel (sufijo PSC),
-- equivalente de juguete de fza_compras_sesiones_celdas. El "documento"
-- (master y lineas) vive en memoria en el banco de pruebas
-- (inMtoPruebaColumnasSku), con SERIE='PRU' y NUMERO=1 fijos.
--
-- Idempotente: se puede ejecutar tantas veces como haga falta.
-- Tabla desechable: cuando la prueba muera, DROP TABLE fza_prueba_skucel.
-- ============================================================================

CREATE TABLE IF NOT EXISTS fza_prueba_skucel (
  SERIE_PSC       VARCHAR(10)  NOT NULL,
  NUMERO_PSC      INT          NOT NULL,
  LINEA_PSC       INT          NOT NULL,
  ID_FILA_PSC     INT          NOT NULL DEFAULT 1,
  ID_AV_PIVOT_PSC INT          NOT NULL,
  CANTIDAD_PSC    DOUBLE       NOT NULL DEFAULT 0,
  INSTANTE_ALTA   DATETIME     NULL,
  INSTANTE_MODIF  DATETIME     NULL,
  USUARIO_ALTA    VARCHAR(50)  NULL,
  USUARIO_MODIF   VARCHAR(50)  NULL,
  PRIMARY KEY (SERIE_PSC, NUMERO_PSC, LINEA_PSC, ID_FILA_PSC,
               ID_AV_PIVOT_PSC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Limpieza opcional de datos de la prueba (documento PRU/1):
-- DELETE FROM fza_prueba_skucel WHERE SERIE_PSC = 'PRU' AND NUMERO_PSC = 1;
