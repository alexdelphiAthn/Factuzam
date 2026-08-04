-- =============================================================================
-- Rollback de auto_increment_a_string.sql
-- =============================================================================
-- Ejecutar con Factuzam detenido. Fallara si un ID ya no cabe en el tipo
-- numerico original. Los contadores tecnicos se conservan para no retroceder.
-- No recrea claves foraneas: las relaciones continuan siendo logicas.
-- =============================================================================

DROP PROCEDURE IF EXISTS `PRC_MIG_COLUMNA_ID_NUMERO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_COLUMNA_ID_NUMERO`(
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pTipoDestino varchar(64),
  IN pAutoIncremento varchar(1)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vEsNullable varchar(3);
  DECLARE vValorDefecto longtext;
  DECLARE vComentario longtext;
  DECLARE vTipoActual varchar(64);
  DECLARE vExtra varchar(255);
  DECLARE vDefinicion longtext;
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME = pColumna;
  IF vExiste > 0 THEN
    SELECT IS_NULLABLE,
           COLUMN_DEFAULT,
           COLUMN_COMMENT,
           COLUMN_TYPE,
           EXTRA
      INTO vEsNullable,
           vValorDefecto,
           vComentario,
           vTipoActual,
           vExtra
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = pTabla
       AND COLUMN_NAME = pColumna;
    IF vEsNullable = 'YES'
       AND vValorDefecto = '''NULL''' THEN
      SET vValorDefecto = 'NULL';
    END IF;
    IF LOWER(vTipoActual) <> LOWER(pTipoDestino)
       OR (pAutoIncremento = 'S'
           AND vExtra NOT LIKE '%auto_increment%')
       OR (pAutoIncremento = 'N'
           AND vExtra LIKE '%auto_increment%') THEN
      SET vDefinicion = CONCAT(
        pTipoDestino, ' ',
        IF(vEsNullable = 'YES', 'NULL', 'NOT NULL'));
      IF pAutoIncremento = 'N'
         AND vValorDefecto IS NOT NULL THEN
        SET vDefinicion = CONCAT(
          vDefinicion, ' DEFAULT ', vValorDefecto);
      ELSEIF pAutoIncremento = 'N'
             AND vEsNullable = 'YES' THEN
        SET vDefinicion = CONCAT(vDefinicion, ' DEFAULT NULL');
      END IF;
      IF pAutoIncremento = 'S' THEN
        SET vDefinicion = CONCAT(vDefinicion, ' AUTO_INCREMENT');
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
  END IF;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_MIG_IDS_A_NUMERO`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_IDS_A_NUMERO`()
BEGIN
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_articulos_tarifas', 'CODIGO_UNICO_ARTTAR', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_articulos_vinculos', 'ID_ARTVIN', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_basicos', 'ID_ATB', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_conjuntos', 'ID_AC', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_valores', 'ID_AV', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_valores_info', 'ID_AVI', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_caja_arqueos_recuento', 'ID_ARQR', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_caja_operaciones', 'ID_OPCAJA', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_codigos_barras', 'ID_CB', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo', 'ID_DTR', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_compartidos', 'ID_DTC', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_lineas', 'ID_DTL', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_facturas_relaciones', 'ID_FACREL', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_filtros_guardados', 'ID_FILT', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_filtros_guardados_compartidos', 'ID_FILTC', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_inventarios_recuentos', 'ID_INVREC', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_metadatos', 'CODIGO_META_META', 'int(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_propiedades_valores', 'ID_PV_ARTPROP', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_tarifas_cambios', 'CODIGO_TARC', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_tarifas_cambios_lineas', 'ID_TARCLIN', 'int(11)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_traducciones', 'ID_TRAD', 'bigint(20) unsigned', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_ventas_ws_cola', 'ID_VWSC', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_verifactu_cola', 'ID_VFCOLA', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_verifactu_eventos', 'ID_LOG', 'bigint(20)', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_almacenes', 'id', 'bigint(20) unsigned', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_catalogo', 'id', 'bigint(20) unsigned', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_dispositivos', 'id', 'bigint(20) unsigned', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_eventos', 'id', 'bigint(20) unsigned', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_recuentos', 'id', 'bigint(20) unsigned', 'S');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_tarifas_cambios_lineas',
    'CODIGO_UNICO_ARTTAR_TARCLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_articulos_atributos_basicos', 'ID_ATB_AAB', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_conjuntos_det', 'ID_ATB_ACD', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_valores', 'ID_ATB_AV', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_albaranes_compra_lineas', 'ID_AC_PIVOT_ALBCLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_albaranes_lineas', 'ID_AC_PIVOT_ALBLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_articulos_conjuntos_asign', 'ID_AC_ACA', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_conjuntos_det', 'ID_AC_ACD', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_plantillas', 'ID_AC_PIVOT_SESPL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_plantillas', 'ID_AC_FILA_SESPL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones', 'ID_AC_PIVOT_SES', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones', 'ID_AC_FILA_SES', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones_lineas', 'ID_AC_PIVOT_SESLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones_lineas', 'ID_AC_FILA_SESLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_devoluciones_compra_lineas', 'ID_AC_PIVOT_DEVCLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_lineas', 'ID_AC_PIVOT_DTL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_facturas_compra_lineas', 'ID_AC_PIVOT_FACCLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_inventarios_lineas', 'ID_AC_PIVOT_INVLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_pedidos_compra_lineas', 'ID_AC_PIVOT_PEDCLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_pedidos_lineas', 'ID_AC_PIVOT_PEDLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_proveedores', 'ID_AC_TALLAS_PRV', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_proveedores_familias_conjuntos', 'ID_AC_PFC', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_proveedores_kits', 'ID_AC_TALLAS_PRVKIT', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'bak_atributos_sku_tallas_dup', 'ID_AV_SA_ORIG', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'bak_atributos_sku_tallas_dup', 'ID_AV_SA_NUEVO', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_albaranes_celdas', 'ID_AV_PIVOT_ALBCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_albaranes_compra_celdas', 'ID_AV_PIVOT_ALBCCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_articulos_atributos_basicos', 'ID_AV_AAB', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_conjuntos_det', 'ID_AV_ACD', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_sku', 'ID_AV_SA', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_atributos_valores_info', 'ID_AV_AVI', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones_celdas', 'ID_AV_PIVOT_SESCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones_lineas_filas_atr', 'ID_AV_SESFILAT', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_compras_sesiones_lineas_skus_precios',
    'ID_AV_PIVOT_SESLINSKU', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_devoluciones_compra_celdas', 'ID_AV_PIVOT_DEVCCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_celdas', 'ID_AV_PIVOT_DTRCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_facturas_compra_celdas', 'ID_AV_PIVOT_FACCCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_inventarios_celdas', 'ID_AV_PIVOT_INVCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_pedidos_celdas', 'ID_AV_PIVOT_PEDCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_pedidos_compra_celdas', 'ID_AV_PIVOT_PEDCCEL', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_prueba_skucel', 'ID_AV_PIVOT_PSC', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_celdas', 'ID_DTR_DTRCEL', 'bigint(20)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_compartidos', 'ID_DTR_DTC', 'bigint(20)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_documentos_trabajo_lineas', 'ID_DTR_DTL', 'bigint(20)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_filtros_guardados_compartidos', 'ID_FILT_FILTC', 'bigint(20)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_articulos_propiedades', 'ID_PV_ARTPROP', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'fza_tarifas_cambios_lineas', 'CODIGO_TARC_TARCLIN', 'int(11)', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_catalogo', 'id_recuento', 'bigint(20) unsigned', 'N');
  CALL `PRC_MIG_COLUMNA_ID_NUMERO`(
    'inv_eventos', 'id_recuento', 'bigint(20) unsigned', 'N');
  UPDATE `fza_metadatos`
     SET `PARENT_META` = CAST(
       CAST(`PARENT_META` AS UNSIGNED) AS char)
   WHERE TRIM(`PARENT_META`) REGEXP '^[0-9]+$'
     AND CAST(`PARENT_META` AS DECIMAL(20,0)) > 0;
END ;;
DELIMITER ;

CALL `PRC_MIG_IDS_A_NUMERO`();
DROP PROCEDURE IF EXISTS `PRC_MIG_IDS_A_NUMERO`;
DROP PROCEDURE IF EXISTS `PRC_MIG_COLUMNA_ID_NUMERO`;

SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, EXTRA
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND EXTRA LIKE '%auto_increment%'
 ORDER BY TABLE_NAME, ORDINAL_POSITION;
