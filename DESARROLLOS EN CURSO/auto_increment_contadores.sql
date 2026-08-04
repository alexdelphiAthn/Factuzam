-- =============================================================================
-- Inicializa en fza_contadores los IDs que sustituyen AUTO_INCREMENT
-- =============================================================================
-- MAX solo se usa aqui, durante la siembra. El programa no calculara MAX.
-- CON guarda el siguiente numero disponible y nunca retrocede al relanzar.
-- =============================================================================

DROP PROCEDURE IF EXISTS `PRC_MIG_REGISTRAR_CONTADOR_ID`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_REGISTRAR_CONTADOR_ID`(
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pSerie varchar(12)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME = pColumna;
  IF vExiste > 0 THEN
    SET @sSqlContador = CONCAT(
      'INSERT INTO `fza_contadores` (',
      '`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, ',
      '`NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, ',
      '`INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`) ',
      'SELECT ''ID'', ''-'', ', QUOTE(pSerie), ', ',
      'GREATEST(COALESCE(MAX(CAST(`',
      REPLACE(pColumna, '`', '``'), '` AS UNSIGNED)), 0) + 1, 1), ',
      '20, ''S'', ''N'', CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'' ',
      'FROM `', REPLACE(pTabla, '`', '``'), '` ',
      'ON DUPLICATE KEY UPDATE ',
      '`CON` = GREATEST(`CON`, VALUES(`CON`)), ',
      '`NUM_DIGITOS_CON` = 20, `ESACTIVO_CON` = ''S'', ',
      '`USUARIO_MODIF` = ''SISTEMA'''
    );
    PREPARE oSentenciaContador FROM @sSqlContador;
    EXECUTE oSentenciaContador;
    DEALLOCATE PREPARE oSentenciaContador;
  END IF;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `PRC_MIG_PREPARAR_CONTADORES_ID`;
DELIMITER ;;
CREATE PROCEDURE `PRC_MIG_PREPARAR_CONTADORES_ID`()
BEGIN
  DECLARE vExisteTipo int DEFAULT 0;
  DECLARE vOrigenTipo varchar(100);
  SET vOrigenTipo = NULL;
  SELECT COUNT(*) INTO vExisteTipo
    FROM `fza_tipos_documentos`
   WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'ID';
  SELECT `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` INTO vOrigenTipo
    FROM `fza_tipos_documentos`
   WHERE `CODIGO_TIPO_DOCUMENTO_TD` = 'ID'
   LIMIT 1;
  IF vExisteTipo > 0
     AND COALESCE(vOrigenTipo, '') <> 'fza_contadores' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El tipo documental ID ya esta reservado para otro uso';
  END IF;
  INSERT INTO `fza_tipos_documentos` (
    `CODIGO_TIPO_DOCUMENTO_TD`,
    `DESCRIPCION_TIPO_DOCUMENTO_TD`,
    `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`
  ) VALUES (
    'ID', 'IDENTIFICADORES TECNICOS', 'fza_contadores'
  )
  ON DUPLICATE KEY UPDATE
    `DESCRIPCION_TIPO_DOCUMENTO_TD` = VALUES(
      `DESCRIPCION_TIPO_DOCUMENTO_TD`),
    `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` = VALUES(
      `TABLA_ORIGEN_TIPO_DOCUMENTO_TD`);
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_articulos_tarifas', 'CODIGO_UNICO_ARTTAR', 'ART_TAR');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_articulos_vinculos', 'ID_ARTVIN', 'ART_VINC');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_atributos_basicos', 'ID_ATB', 'ATR_BASIC');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_atributos_conjuntos', 'ID_AC', 'ATR_CONJ');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_atributos_valores', 'ID_AV', 'ATR_VAL');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_atributos_valores_info', 'ID_AVI', 'ATR_VALINF');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_caja_arqueos_recuento', 'ID_ARQR', 'CAJ_ARQREC');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_caja_operaciones', 'ID_OPCAJA', 'CAJ_OPER');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_codigos_barras', 'ID_CB', 'COD_BARRAS');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_documentos_trabajo', 'ID_DTR', 'DOC_TRAB');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_documentos_trabajo_compartidos', 'ID_DTC', 'DOC_COMP');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_documentos_trabajo_lineas', 'ID_DTL', 'DOC_LINEA');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_facturas_relaciones', 'ID_FACREL', 'FAC_REL');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_filtros_guardados', 'ID_FILT', 'FILTRO');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_filtros_guardados_compartidos', 'ID_FILTC', 'FILT_COMP');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_inventarios_recuentos', 'ID_INVREC', 'FZA_INVREC');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_metadatos', 'CODIGO_META_META', 'METADATO');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_propiedades_valores', 'ID_PV_ARTPROP', 'PROP_VAL');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_tarifas_cambios', 'CODIGO_TARC', 'TAR_CAMBIO');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_tarifas_cambios_lineas', 'ID_TARCLIN', 'TAR_LINEA');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_traducciones', 'ID_TRAD', 'TRADUCCION');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_ventas_ws_cola', 'ID_VWSC', 'VENTAS_WS');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_verifactu_cola', 'ID_VFCOLA', 'VF_COLA');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'fza_verifactu_eventos', 'ID_LOG', 'VF_EVENTO');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'inv_almacenes', 'id', 'INV_ALM');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'inv_catalogo', 'id', 'INV_CAT');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'inv_dispositivos', 'id', 'INV_DISP');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'inv_eventos', 'id', 'INV_EVENTO');
  CALL `PRC_MIG_REGISTRAR_CONTADOR_ID`(
    'inv_recuentos', 'id', 'INV_RECUENTO');
END ;;
DELIMITER ;

CALL `PRC_MIG_PREPARAR_CONTADORES_ID`();
DROP PROCEDURE IF EXISTS `PRC_MIG_PREPARAR_CONTADORES_ID`;
DROP PROCEDURE IF EXISTS `PRC_MIG_REGISTRAR_CONTADOR_ID`;

SELECT `TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`,
       `NUM_DIGITOS_CON`, `ESACTIVO_CON`
  FROM `fza_contadores`
 WHERE `TIPO_DOC_CON` = 'ID'
 ORDER BY `SERIE_CON`;
