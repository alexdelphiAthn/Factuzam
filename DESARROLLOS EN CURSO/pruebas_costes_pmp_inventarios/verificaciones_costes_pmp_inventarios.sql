-- ============================================================================
-- Verificaciones - Costes por SKU, PMP, inventarios, traspasos e informe ventas
-- Ajustar las variables de cabecera si los codigos reales difieren.
-- No modifica datos persistentes. Solo usa SELECT y TEMPORARY TABLE.
-- ============================================================================
SET @ART := 'TESTSKU01';
SET @SKU1 := 'TESTSKU01/NEGRO/S';
SET @SKU2 := 'TESTSKU01/NEGRO/M';
SET @SKU3 := 'TESTSKU01/AZUL/S';
SET @EMP_GEN := '012';
SET @EMP_BCN := '1';
SET @ALM_GEN := 'GEN';
SET @ALM_BCN := 'BCN';
SET @F_DESDE := '2026-07-12';
SET @F_HASTA := '2026-07-12';
-- ---------------------------------------------------------------------------
-- 1. Ultimo coste por SKU y fallback articulo/proveedor
-- ---------------------------------------------------------------------------
SELECT sk.CODIGO_ART_SKU AS ART,
       sk.CODIGO_UNIDAD_SKU AS SKU,
       skuc.PRECIO_ULT_COMPRA_SKUC AS ULT_COSTE_SKU,
       skuc.FECHA_ULT_COMPRA_SKUC AS FECHA_ULT_COSTE_SKU
  FROM fza_articulos_skus sk
  LEFT JOIN fza_articulos_skus_costes skuc
    ON skuc.CODIGO_UNIDAD_SKU_SKUC = sk.CODIGO_UNIDAD_SKU
 WHERE sk.CODIGO_ART_SKU = @ART
 ORDER BY sk.CODIGO_UNIDAD_SKU;
SELECT CODIGO_PRV_AP AS PRV,
       CODIGO_ART_AP AS ART,
       REF_PROVEEDOR_AP AS REF_PRV,
       PRECIO_ULT_COMPRA_AP AS ULT_COSTE_ART,
       FECHA_VALIDEZ_AP AS FECHA_COSTE_ART,
       ESPROVEEDORPRINCIPAL_AP AS PRINCIPAL
  FROM fza_articulos_proveedores
 WHERE CODIGO_ART_AP = @ART
 ORDER BY ESPROVEEDORPRINCIPAL_AP DESC, CODIGO_PRV_AP;
-- ---------------------------------------------------------------------------
-- 2. Stock/PMP por almacen y SKU
-- ---------------------------------------------------------------------------
SELECT CODIGO_ALM_STK AS ALM,
       CODIGO_UNIDAD_STK AS SKU,
       ROUND(CANTIDAD_STK, 2) AS CANT,
       ROUND(PRECIO_MEDIO_STK, 2) AS PMP,
       ROUND(VALOR_TOTAL_STK, 2) AS VALOR,
       ROUND(CANTIDAD_ENT_COMPRA_STK, 2) AS ENT_COMPRA,
       ROUND(CANTIDAD_ENT_TRASPASO_STK, 2) AS ENT_TRASP,
       ROUND(CANTIDAD_SAL_TRASPASO_STK, 2) AS SAL_TRASP,
       ROUND(CANTIDAD_SAL_VENTA_STK, 2) AS SAL_VENTA,
       ROUND(CANTIDAD_SAL_ALBVENTA_STK, 2) AS SAL_ALBVENTA,
       ROUND(CANTIDAD_ENT_REGULAR_STK, 2) AS ENT_REG
  FROM fza_articulos_stockactual
 WHERE CODIGO_UNIDAD_STK IN (@SKU1, @SKU2, @SKU3)
   AND CODIGO_ALM_STK IN (@ALM_GEN, @ALM_BCN)
 ORDER BY CODIGO_ALM_STK, CODIGO_UNIDAD_STK;
-- ---------------------------------------------------------------------------
-- 3. Movimientos de almacen generados por las pruebas
-- ---------------------------------------------------------------------------
SELECT DATE(FECHA_MOV) AS FECHA,
       TIPO_DOC_MOV AS TD,
       SERIE_DOC_MOV AS SERIE,
       NUMERO_DOC_MOV AS NUMERO,
       LINEA_MOV AS LINEA,
       TIPO_MOV AS TM,
       CODIGO_EMP_MOV AS EMP,
       CODIGO_ALM_MOV AS ALM,
       CODIGO_ALM_CONTRA_MOV AS ALM_CONTRA,
       CODIGO_UNIDAD_MOV AS SKU,
       ROUND(CANTIDAD_MOV, 2) AS CANT,
       ROUND(PRECIO_COSTE_UNITARIO_MOV, 2) AS COSTE_UNIT,
       ROUND(PRECIO_MEDIO_MOV, 2) AS PMP_MOV,
       ROUND(TOTAL_COSTE_MOV, 2) AS TOTAL_COSTE
  FROM fza_movimientos_almacen
 WHERE CODIGO_UNIDAD_MOV IN (@SKU1, @SKU2, @SKU3)
   AND FECHA_MOV >= '2026-07-10'
 ORDER BY FECHA_MOV, INSTANTE_ALTA, NUMERO_MOV;
-- ---------------------------------------------------------------------------
-- 4. Coste real vendido por SKU desde movimientos de salida
-- ---------------------------------------------------------------------------
SELECT sk.CODIGO_ART_SKU AS ART,
       m.CODIGO_UNIDAD_MOV AS SKU,
       ROUND(SUM(m.CANTIDAD_MOV), 2) AS UDS_VENDIDAS,
       ROUND(SUM(m.TOTAL_COSTE_MOV), 2) AS COSTE_VENDIDO,
       ROUND(SUM(m.TOTAL_COSTE_MOV) / NULLIF(SUM(m.CANTIDAD_MOV), 0), 2)
         AS PMP_VENTA_MEDIO
  FROM fza_movimientos_almacen m
  JOIN fza_articulos_skus sk
    ON sk.CODIGO_UNIDAD_SKU = m.CODIGO_UNIDAD_MOV
 WHERE m.ESACTIVO_MOV = 'S'
   AND m.TIPO_MOV = 'S'
   AND m.TIPO_DOC_MOV IN ('VE', 'AV')
   AND DATE(m.FECHA_MOV) BETWEEN @F_DESDE AND @F_HASTA
   AND m.CODIGO_UNIDAD_MOV IN (@SKU1, @SKU2, @SKU3)
 GROUP BY sk.CODIGO_ART_SKU, m.CODIGO_UNIDAD_MOV
 ORDER BY m.CODIGO_UNIDAD_MOV;
SELECT ROUND(SUM(m.CANTIDAD_MOV), 2) AS UDS_VENDIDAS,
       ROUND(SUM(m.TOTAL_COSTE_MOV), 2) AS COSTE_VENDIDO
  FROM fza_movimientos_almacen m
 WHERE m.ESACTIVO_MOV = 'S'
   AND m.TIPO_MOV = 'S'
   AND m.TIPO_DOC_MOV IN ('VE', 'AV')
   AND DATE(m.FECHA_MOV) BETWEEN @F_DESDE AND @F_HASTA
   AND m.CODIGO_UNIDAD_MOV IN (@SKU1, @SKU2, @SKU3);
-- ---------------------------------------------------------------------------
-- 5. Informe oficial de ventas por articulo y fechas
-- Comparar IMP_COSTE con el coste real vendido del bloque 4. Con costes
-- distintos por SKU, para la venta del 12/07/2026 debe ser 66,00.
-- ---------------------------------------------------------------------------
CALL PRC_GET_MOV_VENTAS_ART(
  @F_DESDE,
  @F_HASTA,
  NULL,
  CONCAT(@ALM_GEN, ',', @ALM_BCN),
  '',
  '',
  '',
  @ART,
  '',
  '',
  '',
  0,
  'S'
);
-- ---------------------------------------------------------------------------
-- 6. Esperado final tras aplicar P1..P6 y antes de eliminar regularizacion
-- ---------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_pcpi_stock_esperado;
CREATE TEMPORARY TABLE tmp_pcpi_stock_esperado (
  ALM VARCHAR(20) NOT NULL,
  SKU VARCHAR(50) NOT NULL,
  CANT DECIMAL(19,6) NOT NULL,
  PMP DECIMAL(19,6) NOT NULL,
  VALOR DECIMAL(19,6) NOT NULL,
  PRIMARY KEY (ALM, SKU)
);
INSERT INTO tmp_pcpi_stock_esperado (ALM, SKU, CANT, PMP, VALOR) VALUES
(@ALM_GEN, @SKU1, 9, 11, 99),
(@ALM_GEN, @SKU2, 5, 10.5, 52.5),
(@ALM_GEN, @SKU3, 3, 15, 45),
(@ALM_BCN, @SKU1, 8, 13, 104),
(@ALM_BCN, @SKU2, 6, 8.75, 52.5);
SELECT e.ALM,
       e.SKU,
       e.CANT AS CANT_ESPERADA,
       ROUND(IFNULL(st.CANTIDAD_STK, 0), 2) AS CANT_REAL,
       e.PMP AS PMP_ESPERADO,
       ROUND(IFNULL(st.PRECIO_MEDIO_STK, 0), 2) AS PMP_REAL,
       e.VALOR AS VALOR_ESPERADO,
       ROUND(IFNULL(st.VALOR_TOTAL_STK, 0), 2) AS VALOR_REAL,
       CASE WHEN ABS(e.CANT - IFNULL(st.CANTIDAD_STK, 0)) < 0.01
              AND ABS(e.PMP - IFNULL(st.PRECIO_MEDIO_STK, 0)) < 0.01
              AND ABS(e.VALOR - IFNULL(st.VALOR_TOTAL_STK, 0)) < 0.01
            THEN 'OK' ELSE 'KO' END AS RESULTADO
  FROM tmp_pcpi_stock_esperado e
  LEFT JOIN fza_articulos_stockactual st
    ON st.CODIGO_ALM_STK = e.ALM
   AND st.CODIGO_UNIDAD_STK = e.SKU
 ORDER BY e.ALM, e.SKU;
DROP TEMPORARY TABLE IF EXISTS tmp_pcpi_stock_esperado;
