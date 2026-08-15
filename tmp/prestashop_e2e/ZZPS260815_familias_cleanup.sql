-- Limpieza local del fixture QA ZZPS260815.
-- No borra cola/historial de PrestaShop ni intenta eliminar el producto remoto.
-- Si ya existe trazabilidad de sincronizacion, se detiene y exige revision o
-- restauracion separada para conservar la evidencia funcional.
-- Orden: fotos, atributos SKU, stock, tarifas, atributos basicos, SKU,
-- articulo, familia hoja y familia padre.
DROP PROCEDURE IF EXISTS ZZPS260815_FIXTURE_CLEANUP;
DELIMITER $$
CREATE PROCEDURE ZZPS260815_FIXTURE_CLEANUP(OUT p_error text)
bloque_principal: BEGIN
  DECLARE v_error text DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_error = MESSAGE_TEXT;
    ROLLBACK;
    SET p_error = LEFT(
      CONCAT('ZZPS260815 cleanup cancelado: ', v_error),
      128
    );
  END;
  SET p_error = NULL;
  START TRANSACTION;
  IF (SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.TABLES
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME IN (
           'fza_articulos',
           'fza_articulos_atributos_basicos',
           'fza_articulos_familias',
           'fza_articulos_fotos',
           'fza_articulos_skus',
           'fza_articulos_stockactual',
           'fza_articulos_tarifas',
           'fza_atributos_sku',
           'fza_prestashop_cola',
           'fza_prestashop_cola_eventos'
         )) <> 10 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Faltan tablas requeridas para limpiar ZZPS260815';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_prestashop_cola
       WHERE CODIGO_ART_PSCOLA = 'ZZPS260815C') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Existe cola/historial de ZZPS260815C: revisar o restaurar checkpoint por separado';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_familias
       WHERE CODIGO_FAM_FAM IN ('ZZPS260815', 'ZZPS260815H')
         AND (
           USUARIO_ALTA <> 'ZZPS260815_FIXTURE'
           OR NOMBRE_FAM_FAM NOT IN (
             'TEST PS PADRE 260815',
             'TEST PS HOJA 260815'
           )
         )) <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Una familia ZZPS260815 no pertenece al fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos
       WHERE CODIGO_ART_ART = 'ZZPS260815C'
         AND (
           USUARIO_ALTA <> 'ZZPS260815_FIXTURE'
           OR DESCRIPCION_ART <> 'TEST DEMO CAMISA PS 260815'
         )) <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El articulo ZZPS260815C no pertenece al fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_skus
       WHERE (
         CODIGO_ART_SKU = 'ZZPS260815C'
         OR LEFT(CODIGO_UNIDAD_SKU, 12) = 'ZZPS260815C/'
       )
       AND (
         CODIGO_ART_SKU <> 'ZZPS260815C'
         OR LEFT(CODIGO_UNIDAD_SKU, 12) <> 'ZZPS260815C/'
         OR USUARIO_ALTA <> 'ZZPS260815_FIXTURE'
       )) <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un SKU ZZPS260815C no pertenece al fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_atributos_sku
       WHERE LEFT(CODIGO_UNIDAD_SKU_SA, 12) = 'ZZPS260815C/'
         AND USUARIO_ALTA <> 'ZZPS260815_FIXTURE') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un atributo SKU ZZPS260815C no pertenece al fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_tarifas
       WHERE CODIGO_ART_ARTTAR = 'ZZPS260815C'
         AND USUARIO_ALTA <> 'ZZPS260815_FIXTURE') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Una tarifa ZZPS260815C no pertenece al fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_atributos_basicos
       WHERE CODIGO_ART_AAB = 'ZZPS260815C'
         AND USUARIO_ALTA <> 'ZZPS260815_FIXTURE') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un atributo basico ZZPS260815C no pertenece al fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_fotos
       WHERE CODIGO_ART_FOT = 'ZZPS260815C'
         AND USUARIO_ALTA <> 'ZZPS260815_FIXTURE') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Una foto ZZPS260815C no pertenece al fixture';
  END IF;
  DELETE FROM fza_articulos_fotos
   WHERE CODIGO_ART_FOT = 'ZZPS260815C';
  DELETE FROM fza_atributos_sku
   WHERE LEFT(CODIGO_UNIDAD_SKU_SA, 12) = 'ZZPS260815C/';
  DELETE FROM fza_articulos_stockactual
   WHERE LEFT(CODIGO_UNIDAD_STK, 12) = 'ZZPS260815C/';
  DELETE FROM fza_articulos_tarifas
   WHERE CODIGO_ART_ARTTAR = 'ZZPS260815C';
  DELETE FROM fza_articulos_atributos_basicos
   WHERE CODIGO_ART_AAB = 'ZZPS260815C';
  DELETE FROM fza_articulos_skus
   WHERE CODIGO_ART_SKU = 'ZZPS260815C';
  DELETE FROM fza_articulos
   WHERE CODIGO_ART_ART = 'ZZPS260815C';
  DELETE FROM fza_articulos_familias
   WHERE CODIGO_FAM_FAM = 'ZZPS260815H';
  DELETE FROM fza_articulos_familias
   WHERE CODIGO_FAM_FAM = 'ZZPS260815';
  IF (SELECT COUNT(*)
        FROM fza_articulos_fotos
       WHERE CODIGO_ART_FOT = 'ZZPS260815C') <> 0
     OR (SELECT COUNT(*)
           FROM fza_atributos_sku
          WHERE LEFT(CODIGO_UNIDAD_SKU_SA, 12) = 'ZZPS260815C/') <> 0
     OR (SELECT COUNT(*)
           FROM fza_articulos_stockactual
          WHERE LEFT(CODIGO_UNIDAD_STK, 12) = 'ZZPS260815C/') <> 0
     OR (SELECT COUNT(*)
           FROM fza_articulos_tarifas
          WHERE CODIGO_ART_ARTTAR = 'ZZPS260815C') <> 0
     OR (SELECT COUNT(*)
           FROM fza_articulos_atributos_basicos
          WHERE CODIGO_ART_AAB = 'ZZPS260815C') <> 0
     OR (SELECT COUNT(*)
           FROM fza_articulos_skus
          WHERE CODIGO_ART_SKU = 'ZZPS260815C') <> 0
     OR (SELECT COUNT(*)
           FROM fza_articulos
          WHERE CODIGO_ART_ART = 'ZZPS260815C') <> 0
     OR (SELECT COUNT(*)
           FROM fza_articulos_familias
          WHERE CODIGO_FAM_FAM IN ('ZZPS260815', 'ZZPS260815H')) <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Fallo la verificacion final del cleanup ZZPS260815';
  END IF;
  COMMIT;
END$$
DELIMITER ;
CALL ZZPS260815_FIXTURE_CLEANUP(@ZZPS260815_ERROR);
DROP PROCEDURE ZZPS260815_FIXTURE_CLEANUP;
SET @ZZPS260815_RESULTADO = IF(
  @ZZPS260815_ERROR IS NULL,
  'SELECT ''PASA'' AS RESULTADO, ''Fixture ZZPS260815 eliminado'' AS DETALLE',
  CONCAT(
    'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT = ',
    QUOTE(@ZZPS260815_ERROR)
  )
);
PREPARE ZZPS260815_STMT FROM @ZZPS260815_RESULTADO;
EXECUTE ZZPS260815_STMT;
DEALLOCATE PREPARE ZZPS260815_STMT;
