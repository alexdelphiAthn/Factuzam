-- =============================================================================
-- Convierte claves AUTO_INCREMENT y sus referencias logicas a varchar(20)
-- =============================================================================
-- Ejecutar despues de auto_increment_contadores.sql y con Factuzam detenido.
-- Los identificadores positivos se rellenan a 20 digitos para conservar el
-- orden numerico al ordenar como texto. El DDL de MariaDB no es transaccional.
-- Se eliminan todas las claves foraneas fisicas. Las relaciones son logicas.
-- =============================================================================

-- Mostrar la reversion exacta antes de eliminar las restricciones existentes.
SELECT CONCAT(
         'ALTER TABLE `', REPLACE(k.TABLE_NAME, '`', '``'),
         '` ADD CONSTRAINT `', REPLACE(k.CONSTRAINT_NAME, '`', '``'),
         '` FOREIGN KEY (`',
         GROUP_CONCAT(
           REPLACE(k.COLUMN_NAME, '`', '``')
           ORDER BY k.ORDINAL_POSITION SEPARATOR '`, `'),
         '`) REFERENCES `', REPLACE(k.REFERENCED_TABLE_NAME, '`', '``'),
         '` (`',
         GROUP_CONCAT(
           REPLACE(k.REFERENCED_COLUMN_NAME, '`', '``')
           ORDER BY k.ORDINAL_POSITION SEPARATOR '`, `'),
         '`) ON UPDATE ', r.UPDATE_RULE,
         ' ON DELETE ', r.DELETE_RULE, ';') AS SENTENCIA_REVERSION
  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE k
  JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS r
    ON r.CONSTRAINT_SCHEMA = k.CONSTRAINT_SCHEMA
   AND r.TABLE_NAME = k.TABLE_NAME
   AND r.CONSTRAINT_NAME = k.CONSTRAINT_NAME
 WHERE k.CONSTRAINT_SCHEMA = DATABASE()
   AND k.REFERENCED_TABLE_NAME IS NOT NULL
 GROUP BY k.TABLE_NAME,
          k.CONSTRAINT_NAME,
          k.REFERENCED_TABLE_NAME,
          r.UPDATE_RULE,
          r.DELETE_RULE
 ORDER BY k.TABLE_NAME, k.CONSTRAINT_NAME;

DROP PROCEDURE IF EXISTS `PRC_MIG_ELIMINAR_FOREIGN_KEYS`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_ELIMINAR_FOREIGN_KEYS`()
BEGIN
  DECLARE vPendientes int DEFAULT 0;
  DECLARE vTabla varchar(64);
  DECLARE vRestriccion varchar(64);
  SELECT COUNT(*) INTO vPendientes
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
   WHERE CONSTRAINT_SCHEMA = DATABASE()
     AND CONSTRAINT_TYPE = 'FOREIGN KEY';
  WHILE vPendientes > 0 DO
    SELECT TABLE_NAME, CONSTRAINT_NAME
      INTO vTabla, vRestriccion
      FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND CONSTRAINT_TYPE = 'FOREIGN KEY'
     ORDER BY TABLE_NAME, CONSTRAINT_NAME
     LIMIT 1;
    SET @sSqlForeignKey = CONCAT(
      'ALTER TABLE `', REPLACE(vTabla, '`', '``'),
      '` DROP FOREIGN KEY `', REPLACE(vRestriccion, '`', '``'), '`');
    PREPARE oSentenciaForeignKey FROM @sSqlForeignKey;
    EXECUTE oSentenciaForeignKey;
    DEALLOCATE PREPARE oSentenciaForeignKey;
    SET vPendientes = vPendientes - 1;
  END WHILE;
END ;;
DELIMITER ;

CALL `PRC_MIG_ELIMINAR_FOREIGN_KEYS`();
DROP PROCEDURE IF EXISTS `PRC_MIG_ELIMINAR_FOREIGN_KEYS`;

DROP PROCEDURE IF EXISTS `PRC_MIG_COLUMNA_ID_TEXTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_COLUMNA_ID_TEXTO`(
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pEsClave varchar(1)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vInvalidos bigint DEFAULT 0;
  DECLARE vTipo varchar(64);
  DECLARE vLongitud bigint;
  DECLARE vEsNullable varchar(3);
  DECLARE vValorDefecto longtext;
  DECLARE vComentario longtext;
  DECLARE vExtra varchar(255);
  DECLARE vDefinicion longtext;
  DECLARE vDefaultErroneo varchar(1) DEFAULT 'N';
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME = pColumna;
  IF vExiste > 0 THEN
    SET @iInvalidosId = 0;
    IF pEsClave = 'S' THEN
      SET @sSqlId = CONCAT(
        'SELECT COUNT(*) INTO @iInvalidosId FROM `',
        REPLACE(pTabla, '`', '``'), '` WHERE `',
        REPLACE(pColumna, '`', '``'), '` IS NULL OR ',
        'TRIM(CAST(`', REPLACE(pColumna, '`', '``'),
        '` AS CHAR)) NOT REGEXP ''^[0-9]+$'' OR ',
        'CHAR_LENGTH(TRIM(CAST(`', REPLACE(pColumna, '`', '``'),
        '` AS CHAR))) > 20');
    ELSE
      SET @sSqlId = CONCAT(
        'SELECT COUNT(*) INTO @iInvalidosId FROM `',
        REPLACE(pTabla, '`', '``'), '` WHERE `',
        REPLACE(pColumna, '`', '``'), '` IS NOT NULL AND ',
        'TRIM(CAST(`', REPLACE(pColumna, '`', '``'),
        '` AS CHAR)) <> '''' AND ',
        'TRIM(CAST(`', REPLACE(pColumna, '`', '``'),
        '` AS CHAR)) NOT REGEXP ''^-?[0-9]+$''');
    END IF;
    PREPARE oSentenciaId FROM @sSqlId;
    EXECUTE oSentenciaId;
    DEALLOCATE PREPARE oSentenciaId;
    SET vInvalidos = @iInvalidosId;
    IF vInvalidos > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Hay identificadores no numericos o demasiado largos';
    END IF;
    SELECT DATA_TYPE,
           CHARACTER_MAXIMUM_LENGTH,
           IS_NULLABLE,
           COLUMN_DEFAULT,
           COLUMN_COMMENT,
           EXTRA
      INTO vTipo,
           vLongitud,
           vEsNullable,
           vValorDefecto,
           vComentario,
           vExtra
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = pTabla
       AND COLUMN_NAME = pColumna;
    IF vEsNullable = 'YES'
       AND vValorDefecto = '''NULL''' THEN
      SET vDefaultErroneo = 'S';
      SET vValorDefecto = 'NULL';
    END IF;
    IF vTipo <> 'varchar'
       OR COALESCE(vLongitud, 0) <> 20
       OR vExtra LIKE '%auto_increment%'
       OR vDefaultErroneo = 'S' THEN
      SET vDefinicion = CONCAT(
        'varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci ',
        IF(vEsNullable = 'YES', 'NULL', 'NOT NULL'));
      IF vValorDefecto IS NOT NULL THEN
        SET vDefinicion = CONCAT(
          vDefinicion, ' DEFAULT ', vValorDefecto);
      ELSEIF vEsNullable = 'YES' THEN
        SET vDefinicion = CONCAT(vDefinicion, ' DEFAULT NULL');
      END IF;
      IF COALESCE(vComentario, '') <> '' THEN
        SET vDefinicion = CONCAT(
          vDefinicion, ' COMMENT ', QUOTE(vComentario));
      END IF;
      SET @sSqlId = CONCAT(
        'ALTER TABLE `', REPLACE(pTabla, '`', '``'),
        '` MODIFY COLUMN `', REPLACE(pColumna, '`', '``'),
        '` ', vDefinicion);
      PREPARE oSentenciaId FROM @sSqlId;
      EXECUTE oSentenciaId;
      DEALLOCATE PREPARE oSentenciaId;
    END IF;
    IF pEsClave = 'S' THEN
      SET @sSqlId = CONCAT(
        'UPDATE `', REPLACE(pTabla, '`', '``'), '` SET `',
        REPLACE(pColumna, '`', '``'), '` = LPAD(TRIM(`',
        REPLACE(pColumna, '`', '``'), '`), 20, ''0'') WHERE `',
        REPLACE(pColumna, '`', '``'), '` <> LPAD(TRIM(`',
        REPLACE(pColumna, '`', '``'), '`), 20, ''0'')');
    ELSE
      SET @sSqlId = CONCAT(
        'UPDATE `', REPLACE(pTabla, '`', '``'), '` SET `',
        REPLACE(pColumna, '`', '``'), '` = LPAD(TRIM(`',
        REPLACE(pColumna, '`', '``'), '`), 20, ''0'') WHERE `',
        REPLACE(pColumna, '`', '``'), '` IS NOT NULL AND TRIM(`',
        REPLACE(pColumna, '`', '``'), '`) REGEXP ''^[0-9]+$'' AND ',
        'CAST(TRIM(`', REPLACE(pColumna, '`', '``'),
        '`) AS DECIMAL(20,0)) > 0');
    END IF;
    PREPARE oSentenciaId FROM @sSqlId;
    EXECUTE oSentenciaId;
    DEALLOCATE PREPARE oSentenciaId;
  END IF;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_MIG_IDS_A_TEXTO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_IDS_A_TEXTO`()
BEGIN
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_tarifas_cambios_lineas', 'CODIGO_UNICO_ARTTAR_TARCLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_articulos_atributos_basicos', 'ID_ATB_AAB', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_conjuntos_det', 'ID_ATB_ACD', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_valores', 'ID_ATB_AV', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_albaranes_compra_lineas', 'ID_AC_PIVOT_ALBCLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_albaranes_lineas', 'ID_AC_PIVOT_ALBLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_articulos_conjuntos_asign', 'ID_AC_ACA', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_conjuntos_det', 'ID_AC_ACD', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_plantillas', 'ID_AC_PIVOT_SESPL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_plantillas', 'ID_AC_FILA_SESPL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones', 'ID_AC_PIVOT_SES', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones', 'ID_AC_FILA_SES', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones_lineas', 'ID_AC_PIVOT_SESLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones_lineas', 'ID_AC_FILA_SESLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_devoluciones_compra_lineas', 'ID_AC_PIVOT_DEVCLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_lineas', 'ID_AC_PIVOT_DTL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_facturas_compra_lineas', 'ID_AC_PIVOT_FACCLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_inventarios_lineas', 'ID_AC_PIVOT_INVLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_pedidos_compra_lineas', 'ID_AC_PIVOT_PEDCLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_pedidos_lineas', 'ID_AC_PIVOT_PEDLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_proveedores', 'ID_AC_TALLAS_PRV', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_proveedores_familias_conjuntos', 'ID_AC_PFC', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_proveedores_kits', 'ID_AC_TALLAS_PRVKIT', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'bak_atributos_sku_tallas_dup', 'ID_AV_SA_ORIG', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'bak_atributos_sku_tallas_dup', 'ID_AV_SA_NUEVO', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_albaranes_celdas', 'ID_AV_PIVOT_ALBCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_albaranes_compra_celdas', 'ID_AV_PIVOT_ALBCCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_articulos_atributos_basicos', 'ID_AV_AAB', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_conjuntos_det', 'ID_AV_ACD', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_sku', 'ID_AV_SA', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_valores_info', 'ID_AV_AVI', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones_celdas', 'ID_AV_PIVOT_SESCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones_lineas_filas_atr', 'ID_AV_SESFILAT', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_compras_sesiones_lineas_skus_precios',
    'ID_AV_PIVOT_SESLINSKU', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_devoluciones_compra_celdas', 'ID_AV_PIVOT_DEVCCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_celdas', 'ID_AV_PIVOT_DTRCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_facturas_compra_celdas', 'ID_AV_PIVOT_FACCCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_inventarios_celdas', 'ID_AV_PIVOT_INVCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_pedidos_celdas', 'ID_AV_PIVOT_PEDCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_pedidos_compra_celdas', 'ID_AV_PIVOT_PEDCCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_prueba_skucel', 'ID_AV_PIVOT_PSC', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_celdas', 'ID_DTR_DTRCEL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_compartidos', 'ID_DTR_DTC', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_lineas', 'ID_DTR_DTL', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_filtros_guardados_compartidos', 'ID_FILT_FILTC', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_articulos_propiedades', 'ID_PV_ARTPROP', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_tarifas_cambios_lineas', 'CODIGO_TARC_TARCLIN', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_metadatos', 'PARENT_META', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_catalogo', 'id_recuento', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_eventos', 'id_recuento', 'N');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_articulos_tarifas', 'CODIGO_UNICO_ARTTAR', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_articulos_vinculos', 'ID_ARTVIN', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_basicos', 'ID_ATB', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_conjuntos', 'ID_AC', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_valores', 'ID_AV', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_atributos_valores_info', 'ID_AVI', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_caja_arqueos_recuento', 'ID_ARQR', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_caja_operaciones', 'ID_OPCAJA', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_codigos_barras', 'ID_CB', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo', 'ID_DTR', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_compartidos', 'ID_DTC', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_documentos_trabajo_lineas', 'ID_DTL', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_facturas_relaciones', 'ID_FACREL', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_filtros_guardados', 'ID_FILT', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_filtros_guardados_compartidos', 'ID_FILTC', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_inventarios_recuentos', 'ID_INVREC', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_metadatos', 'CODIGO_META_META', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_propiedades_valores', 'ID_PV_ARTPROP', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_tarifas_cambios', 'CODIGO_TARC', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_tarifas_cambios_lineas', 'ID_TARCLIN', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_traducciones', 'ID_TRAD', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_ventas_ws_cola', 'ID_VWSC', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_verifactu_cola', 'ID_VFCOLA', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'fza_verifactu_eventos', 'ID_LOG', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_almacenes', 'id', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_catalogo', 'id', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_dispositivos', 'id', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_eventos', 'id', 'S');
  CALL `PRC_MIG_COLUMNA_ID_TEXTO`(
    'inv_recuentos', 'id', 'S');
END ;;
DELIMITER ;

CALL `PRC_MIG_IDS_A_TEXTO`();
DROP PROCEDURE IF EXISTS `PRC_MIG_IDS_A_TEXTO`;
DROP PROCEDURE IF EXISTS `PRC_MIG_COLUMNA_ID_TEXTO`;

SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, EXTRA
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND EXTRA LIKE '%auto_increment%'
 ORDER BY TABLE_NAME, ORDINAL_POSITION;

SELECT COUNT(*) AS FOREIGN_KEYS_RESTANTES
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
 WHERE CONSTRAINT_SCHEMA = DATABASE()
   AND CONSTRAINT_TYPE = 'FOREIGN KEY';
