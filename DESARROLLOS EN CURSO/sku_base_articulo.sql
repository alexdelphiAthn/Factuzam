-- ============================================================================
--  SKU base para articulos sin variaciones (backfill)
-- ----------------------------------------------------------------------------
--  Un articulo sin SKU no puede llevar stock ni aparece en la consulta
--  (Ctrl+U), porque todo el stock se apoya en fza_articulos_skus. Para los
--  articulos simples (ESVARIACION_ART = 'N') creamos una unidad/SKU base con
--  CODIGO_UNIDAD_SKU = CODIGO_ART_ART y CODIGO_VAR_SKU = '-' (marcador de
--  "sin variacion", convencion ya usada en la BBDD).
--
--  El alta automatica de nuevos articulos la hace el programa
--  (UniDataArticulos.AsegurarSkuBase en AfterPost). Este script cubre los
--  articulos YA existentes que se quedaron sin SKU.
--
--  Idempotente: solo inserta para articulos sin ningun SKU (NOT EXISTS) y con
--  INSERT IGNORE. Se puede ejecutar varias veces.
--  NO toca factuzam_original.sql.
-- ============================================================================
INSERT IGNORE INTO `fza_articulos_skus`
  (`CODIGO_UNIDAD_SKU`, `CODIGO_ART_SKU`, `CODIGO_VAR_SKU`, `ESACTIVO_SKU`,
   `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)
SELECT a.`CODIGO_ART_ART`, a.`CODIGO_ART_ART`, '-', 'S',
       CURRENT_TIMESTAMP, 'SISTEMA', 'SISTEMA'
  FROM `fza_articulos` a
 WHERE a.`ESVARIACION_ART` = 'N'
   AND NOT EXISTS (SELECT 1 FROM `fza_articulos_skus` s
                    WHERE s.`CODIGO_ART_SKU` = a.`CODIGO_ART_ART`);
