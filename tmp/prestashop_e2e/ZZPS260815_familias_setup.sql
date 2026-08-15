-- Fixture QA para validar los niveles de familia en el alta de PrestaShop.
-- Solo datos locales: no invoca la cola ni realiza peticiones a PrestaShop.
-- El padre se llama ZZPS260815, sin sufijo P, porque la columna legacy
-- CODIGO_SUBFAMILIA_FAM admite como maximo 10 caracteres.
-- La rutina auxiliar garantiza ROLLBACK ante cualquier precondicion o error.
DROP PROCEDURE IF EXISTS ZZPS260815_FIXTURE_SETUP;
DELIMITER $$
CREATE PROCEDURE ZZPS260815_FIXTURE_SETUP(OUT p_error text)
bloque_principal: BEGIN
  DECLARE v_cantidad int DEFAULT 0;
  DECLARE v_error text DEFAULT NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_error = MESSAGE_TEXT;
    ROLLBACK;
    SET p_error = LEFT(
      CONCAT('ZZPS260815 setup cancelado: ', v_error),
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
           'fza_prestashop_cola'
         )) <> 9 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Faltan tablas requeridas para el fixture ZZPS260815';
  END IF;
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
           'fza_atributos_sku'
         )
         AND ENGINE = 'InnoDB') <> 8 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Las tablas del fixture deben usar InnoDB';
  END IF;
  IF COALESCE((SELECT CHARACTER_MAXIMUM_LENGTH
                 FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'fza_articulos_familias'
                  AND COLUMN_NAME = 'CODIGO_SUBFAMILIA_FAM'), 0) < 10 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CODIGO_SUBFAMILIA_FAM no admite ZZPS260815';
  END IF;
  IF COALESCE((SELECT CHARACTER_MAXIMUM_LENGTH
                 FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'fza_articulos_familias'
                  AND COLUMN_NAME = 'CODIGO_FAM_FAM'), 0) < 11 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CODIGO_FAM_FAM no admite ZZPS260815H';
  END IF;
  IF COALESCE((SELECT CHARACTER_MAXIMUM_LENGTH
                 FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'fza_articulos'
                  AND COLUMN_NAME = 'CODIGO_ART_ART'), 0) < 11 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'CODIGO_ART_ART no admite ZZPS260815C';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos
   WHERE CODIGO_ART_ART = 'DEMO-CAMISA'
     AND ESACTIVO_ART = 'S'
     AND TIPO_ART = 'ESTANDAR'
     AND ESVARIACION_ART = 'S'
     AND TIPO_VARIACION_ART = 'TC';
  IF v_cantidad <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'DEMO-CAMISA no cumple el modelo S/ESTANDAR/S/TC';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos_skus
   WHERE CODIGO_ART_SKU = 'DEMO-CAMISA'
     AND ESACTIVO_SKU = 'S';
  IF v_cantidad <> 12 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'DEMO-CAMISA debe tener exactamente 12 SKU activos';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos_skus
   WHERE CODIGO_ART_SKU = 'DEMO-CAMISA'
     AND ESACTIVO_SKU = 'S'
     AND (
       LEFT(CODIGO_UNIDAD_SKU, 12) <> 'DEMO-CAMISA/'
       OR CODIGO_VAR_SKU <> 'TC'
     );
  IF v_cantidad <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Los SKU activos de DEMO-CAMISA no tienen prefijo/variacion TC';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_atributos_sku sa
    JOIN fza_articulos_skus sku
      ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA
   WHERE sku.CODIGO_ART_SKU = 'DEMO-CAMISA'
     AND sku.ESACTIVO_SKU = 'S';
  IF v_cantidad <> 24 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Los 12 SKU activos de DEMO-CAMISA deben tener 24 atributos';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM (
      SELECT sku.CODIGO_UNIDAD_SKU
        FROM fza_articulos_skus sku
        LEFT JOIN fza_atributos_sku sa
          ON sa.CODIGO_UNIDAD_SKU_SA = sku.CODIGO_UNIDAD_SKU
       WHERE sku.CODIGO_ART_SKU = 'DEMO-CAMISA'
         AND sku.ESACTIVO_SKU = 'S'
       GROUP BY sku.CODIGO_UNIDAD_SKU
      HAVING COUNT(sa.ID_AV_SA) = 2
    ) skus_con_dos_atributos;
  IF v_cantidad <> 12 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cada SKU activo de DEMO-CAMISA debe tener 2 atributos';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos_atributos_basicos
   WHERE CODIGO_ART_AAB = 'DEMO-CAMISA';
  IF v_cantidad <> 5 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'DEMO-CAMISA debe tener 5 atributos basicos';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos_tarifas
   WHERE CODIGO_ART_ARTTAR = 'DEMO-CAMISA';
  IF v_cantidad <> 3 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'DEMO-CAMISA debe tener exactamente 3 tarifas';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos_tarifas tarifa
   WHERE tarifa.CODIGO_ART_ARTTAR = 'DEMO-CAMISA'
     AND COALESCE(tarifa.CODIGO_UNIDAD_ARTTAR, '') <> ''
     AND NOT EXISTS (
       SELECT 1
         FROM fza_articulos_skus sku
        WHERE sku.CODIGO_UNIDAD_SKU = tarifa.CODIGO_UNIDAD_ARTTAR
          AND sku.CODIGO_ART_SKU = 'DEMO-CAMISA'
          AND sku.ESACTIVO_SKU = 'S'
     );
  IF v_cantidad <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Una tarifa de DEMO-CAMISA apunta a un SKU no activo';
  END IF;
  SELECT COUNT(*)
    INTO v_cantidad
    FROM fza_articulos_fotos
   WHERE CODIGO_ART_FOT = 'DEMO-CAMISA'
     AND CODIGO_UNIDAD_FOT = ''
     AND COALESCE(NOMBRE_FOT_FOT, '') <> ''
     AND COALESCE(EXTENSION_ORIGEN_FOT, '') <> '';
  IF v_cantidad <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'DEMO-CAMISA debe tener una foto general valida';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_familias
       WHERE CODIGO_FAM_FAM IN ('ZZPS260815', 'ZZPS260815H')) <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existe alguna familia ZZPS260815 del fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos
       WHERE CODIGO_ART_ART = 'ZZPS260815C') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existe el articulo ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_skus
       WHERE CODIGO_ART_SKU = 'ZZPS260815C'
          OR LEFT(CODIGO_UNIDAD_SKU, 12) = 'ZZPS260815C/') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existen SKU reservados para ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_atributos_sku
       WHERE LEFT(CODIGO_UNIDAD_SKU_SA, 12) = 'ZZPS260815C/') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existen atributos SKU reservados para ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_stockactual
       WHERE LEFT(CODIGO_UNIDAD_STK, 12) = 'ZZPS260815C/') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existe stock reservado para ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_tarifas
       WHERE CODIGO_ART_ARTTAR = 'ZZPS260815C') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existen tarifas reservadas para ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_atributos_basicos
       WHERE CODIGO_ART_AAB = 'ZZPS260815C') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existen atributos basicos para ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_fotos
       WHERE CODIGO_ART_FOT = 'ZZPS260815C') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existen fotos reservadas para ZZPS260815C';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_prestashop_cola
       WHERE CODIGO_ART_PSCOLA = 'ZZPS260815C') <> 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ya existe trazabilidad PrestaShop para ZZPS260815C';
  END IF;
  INSERT INTO fza_articulos_familias (
    CODIGO_FAM_FAM,
    CODIGO_PADRE_FAM,
    ESACTIVO_FAM,
    ORDEN_FAM,
    ESDEFAULT_FAM,
    CODIGO_SUBFAMILIA_FAM,
    NOMBRE_FAM_FAM,
    DESCRIPCION_FAM,
    CONTADOR_ART_FAM,
    ESCONTADOR_ART_FAM,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF,
    PAD_ART_FAM
  ) VALUES
    (
      'ZZPS260815', NULL, 'S', 260815, 'N', NULL,
      'TEST PS PADRE 260815', 'Fixture QA PrestaShop: familia padre',
      0, 'N', NOW(), NOW(), 'ZZPS260815_FIXTURE',
      'ZZPS260815_FIXTURE', 5
    ),
    (
      'ZZPS260815H', 'ZZPS260815', 'S', 260816, 'N', 'ZZPS260815',
      'TEST PS HOJA 260815', 'Fixture QA PrestaShop: familia hoja',
      0, 'N', NOW(), NOW(), 'ZZPS260815_FIXTURE',
      'ZZPS260815_FIXTURE', 5
    );
  IF ROW_COUNT() <> 2 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se insertaron las 2 familias ZZPS260815';
  END IF;
  INSERT INTO fza_articulos (
    CODIGO_ART_ART,
    ESACTIVO_ART,
    ESWEB_ART,
    TIPO_ART,
    DESCRIPCION_ART,
    CODIGO_FAM_ART,
    TIPO_IVA_ART,
    ESACTIVO_FIJO_ART,
    TIPO_CANTIDAD_ART,
    ESVARIACION_ART,
    ESTRAZABLE_ART,
    ORDEN_ART,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF,
    TIPO_VARIACION_ART
  )
  SELECT
    'ZZPS260815C',
    'S',
    'N',
    origen.TIPO_ART,
    'TEST DEMO CAMISA PS 260815',
    'ZZPS260815H',
    origen.TIPO_IVA_ART,
    origen.ESACTIVO_FIJO_ART,
    origen.TIPO_CANTIDAD_ART,
    'S',
    origen.ESTRAZABLE_ART,
    NULL,
    NOW(),
    NOW(),
    'ZZPS260815_FIXTURE',
    'ZZPS260815_FIXTURE',
    'TC'
    FROM fza_articulos origen
   WHERE origen.CODIGO_ART_ART = 'DEMO-CAMISA';
  IF ROW_COUNT() <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se inserto el articulo ZZPS260815C';
  END IF;
  INSERT INTO fza_articulos_skus (
    CODIGO_UNIDAD_SKU,
    CODIGO_ART_SKU,
    CODIGO_VAR_SKU,
    ESACTIVO_SKU,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  )
  SELECT
    CONCAT('ZZPS260815C', SUBSTRING(origen.CODIGO_UNIDAD_SKU, 12)),
    'ZZPS260815C',
    origen.CODIGO_VAR_SKU,
    origen.ESACTIVO_SKU,
    NOW(),
    NOW(),
    'ZZPS260815_FIXTURE',
    'ZZPS260815_FIXTURE'
    FROM fza_articulos_skus origen
   WHERE origen.CODIGO_ART_SKU = 'DEMO-CAMISA'
     AND origen.ESACTIVO_SKU = 'S'
   ORDER BY origen.CODIGO_UNIDAD_SKU;
  IF ROW_COUNT() <> 12 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se insertaron los 12 SKU activos del fixture';
  END IF;
  INSERT INTO fza_atributos_sku (
    CODIGO_UNIDAD_SKU_SA,
    ID_AV_SA,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  )
  SELECT
    CONCAT('ZZPS260815C', SUBSTRING(sa.CODIGO_UNIDAD_SKU_SA, 12)),
    sa.ID_AV_SA,
    NOW(),
    NOW(),
    'ZZPS260815_FIXTURE',
    'ZZPS260815_FIXTURE'
    FROM fza_atributos_sku sa
    JOIN fza_articulos_skus sku
      ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA
   WHERE sku.CODIGO_ART_SKU = 'DEMO-CAMISA'
     AND sku.ESACTIVO_SKU = 'S'
   ORDER BY sa.CODIGO_UNIDAD_SKU_SA, sa.ID_AV_SA;
  IF ROW_COUNT() <> 24 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se insertaron los 24 atributos SKU del fixture';
  END IF;
  INSERT INTO fza_articulos_atributos_basicos (
    CODIGO_ART_AAB,
    ID_AV_AAB,
    ID_ATB_AAB,
    DESCRIPCION_AAB,
    ORDEN_AAB,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  )
  SELECT
    'ZZPS260815C',
    origen.ID_AV_AAB,
    origen.ID_ATB_AAB,
    origen.DESCRIPCION_AAB,
    origen.ORDEN_AAB,
    NOW(),
    NOW(),
    'ZZPS260815_FIXTURE',
    'ZZPS260815_FIXTURE'
    FROM fza_articulos_atributos_basicos origen
   WHERE origen.CODIGO_ART_AAB = 'DEMO-CAMISA'
   ORDER BY origen.ID_AV_AAB;
  IF ROW_COUNT() <> 5 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se insertaron los 5 atributos basicos del fixture';
  END IF;
  INSERT INTO fza_articulos_tarifas (
    CODIGO_ART_ARTTAR,
    CODIGO_UNIDAD_ARTTAR,
    CODIGO_TAR_ARTTAR,
    ESACTIVO_ARTTAR,
    PRECIO_SALIDA_ARTTAR,
    PRECIO_FINAL_ARTTAR,
    PRECIO_DTO_ARTTAR,
    PORCENTAJE_DTO_ARTTAR,
    PORCENTAJE_MARGEN_ARTTAR,
    VALOR_MULTIPLO_AJUSTE_ARTTAR,
    VALOR_MENOS_AJUSTE_ARTTAR,
    FECHA_DESDE_ARTTAR,
    FECHA_HASTA_ARTTAR,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  )
  SELECT
    'ZZPS260815C',
    CASE
      WHEN COALESCE(origen.CODIGO_UNIDAD_ARTTAR, '') = '' THEN ''
      ELSE CONCAT(
        'ZZPS260815C',
        SUBSTRING(origen.CODIGO_UNIDAD_ARTTAR, 12)
      )
    END,
    origen.CODIGO_TAR_ARTTAR,
    origen.ESACTIVO_ARTTAR,
    origen.PRECIO_SALIDA_ARTTAR,
    origen.PRECIO_FINAL_ARTTAR,
    origen.PRECIO_DTO_ARTTAR,
    origen.PORCENTAJE_DTO_ARTTAR,
    origen.PORCENTAJE_MARGEN_ARTTAR,
    origen.VALOR_MULTIPLO_AJUSTE_ARTTAR,
    origen.VALOR_MENOS_AJUSTE_ARTTAR,
    origen.FECHA_DESDE_ARTTAR,
    origen.FECHA_HASTA_ARTTAR,
    NOW(),
    NOW(),
    'ZZPS260815_FIXTURE',
    'ZZPS260815_FIXTURE'
    FROM fza_articulos_tarifas origen
   WHERE origen.CODIGO_ART_ARTTAR = 'DEMO-CAMISA'
   ORDER BY origen.CODIGO_UNICO_ARTTAR;
  IF ROW_COUNT() <> 3 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se insertaron las 3 tarifas del fixture';
  END IF;
  INSERT INTO fza_articulos_fotos (
    CODIGO_ART_FOT,
    CODIGO_UNIDAD_FOT,
    NOMBRE_FOT_FOT,
    EXTENSION_ORIGEN_FOT,
    INSTANTE_MODIF,
    INSTANTE_ALTA,
    USUARIO_ALTA,
    USUARIO_MODIF
  )
  SELECT
    'ZZPS260815C',
    '',
    origen.NOMBRE_FOT_FOT,
    origen.EXTENSION_ORIGEN_FOT,
    NOW(),
    NOW(),
    'ZZPS260815_FIXTURE',
    'ZZPS260815_FIXTURE'
    FROM fza_articulos_fotos origen
   WHERE origen.CODIGO_ART_FOT = 'DEMO-CAMISA'
     AND origen.CODIGO_UNIDAD_FOT = '';
  IF ROW_COUNT() <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se inserto la foto general del fixture';
  END IF;
  IF (SELECT COUNT(*)
        FROM fza_articulos_familias
       WHERE CODIGO_FAM_FAM IN ('ZZPS260815', 'ZZPS260815H')
         AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
         AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 2
     OR (SELECT COUNT(*)
           FROM fza_articulos
          WHERE CODIGO_ART_ART = 'ZZPS260815C'
            AND ESACTIVO_ART = 'S'
            AND ESWEB_ART = 'N'
            AND CODIGO_FAM_ART = 'ZZPS260815H'
            AND ESVARIACION_ART = 'S'
            AND TIPO_VARIACION_ART = 'TC'
            AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
            AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 1
     OR (SELECT COUNT(*)
           FROM fza_articulos_skus
          WHERE CODIGO_ART_SKU = 'ZZPS260815C'
            AND ESACTIVO_SKU = 'S'
            AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
            AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 12
     OR (SELECT COUNT(*)
           FROM fza_atributos_sku
          WHERE LEFT(CODIGO_UNIDAD_SKU_SA, 12) = 'ZZPS260815C/'
            AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
            AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 24
     OR (SELECT COUNT(*)
           FROM fza_articulos_atributos_basicos
          WHERE CODIGO_ART_AAB = 'ZZPS260815C'
            AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
            AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 5
     OR (SELECT COUNT(*)
           FROM fza_articulos_tarifas
          WHERE CODIGO_ART_ARTTAR = 'ZZPS260815C'
            AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
            AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 3
     OR (SELECT COUNT(*)
           FROM fza_articulos_fotos
          WHERE CODIGO_ART_FOT = 'ZZPS260815C'
            AND CODIGO_UNIDAD_FOT = ''
            AND USUARIO_ALTA = 'ZZPS260815_FIXTURE'
            AND USUARIO_MODIF = 'ZZPS260815_FIXTURE') <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Fallo la verificacion final del fixture ZZPS260815';
  END IF;
  COMMIT;
END$$
DELIMITER ;
CALL ZZPS260815_FIXTURE_SETUP(@ZZPS260815_ERROR);
DROP PROCEDURE ZZPS260815_FIXTURE_SETUP;
SET @ZZPS260815_RESULTADO = IF(
  @ZZPS260815_ERROR IS NULL,
  'SELECT ''PASA'' AS RESULTADO, ''Fixture ZZPS260815 creado'' AS DETALLE',
  CONCAT(
    'SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT = ',
    QUOTE(@ZZPS260815_ERROR)
  )
);
PREPARE ZZPS260815_STMT FROM @ZZPS260815_RESULTADO;
EXECUTE ZZPS260815_STMT;
DEALLOCATE PREPARE ZZPS260815_STMT;
