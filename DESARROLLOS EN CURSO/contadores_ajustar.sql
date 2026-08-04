-- =============================================================================
-- Ajuste manual de fza_contadores desde los datos existentes
-- =============================================================================
-- El contador guarda el siguiente numero disponible: MAX(origen) + 1.
-- MAX solo se usa en este script; el codigo Delphi llama al procedimiento.
-- Los UPSERT son monotonicos y no reducen contadores ni cambian su estado.
-- =============================================================================

DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADORES`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADORES_ID`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADORES_DOCUMENTOS`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADORES_MAESTROS`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADOR_PREFIJO`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADOR_EMPRESA`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADOR_DOCUMENTO`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADOR_ID`;
DROP PROCEDURE IF EXISTS `PRC_AJUSTAR_CONTADOR_GLOBAL`;

DELIMITER ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADOR_GLOBAL`(
  IN pTipo varchar(2),
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pDigitos int,
  IN pUsuario varchar(100)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vUsuario varchar(100);
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME = pColumna;
  IF vExiste = 1 THEN
    SET vUsuario = COALESCE(NULLIF(TRIM(pUsuario), ''), 'SISTEMA');
    SET @sSqlAjusteContador = CONCAT(
      'INSERT INTO `fza_contadores` (',
      '`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, ',
      '`NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, ',
      '`INSTANTE_ALTA`, `INSTANTE_MODIF`, ',
      '`USUARIO_ALTA`, `USUARIO_MODIF`) ',
      'SELECT ', QUOTE(pTipo), ', ''-'', ''-'', ',
      'COALESCE(MAX(CAST(TRIM(`', REPLACE(pColumna, '`', '``'),
      '`) AS UNSIGNED)), 0) + 1, ',
      'GREATEST(', GREATEST(pDigitos, 1), ', CHAR_LENGTH(CAST(',
      'COALESCE(MAX(CAST(TRIM(`', REPLACE(pColumna, '`', '``'),
      '`) AS UNSIGNED)), 0) + 1 AS CHAR))), ',
      '''S'', ''S'', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ',
      QUOTE(vUsuario), ', ', QUOTE(vUsuario), ' FROM `',
      REPLACE(pTabla, '`', '``'), '` WHERE TRIM(COALESCE(`',
      REPLACE(pColumna, '`', '``'), '`, '''')) REGEXP ''^[0-9]+$'' ',
      'ON DUPLICATE KEY UPDATE ',
      '`USUARIO_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'VALUES(`USUARIO_MODIF`), `USUARIO_MODIF`), ',
      '`INSTANTE_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'CURRENT_TIMESTAMP, `INSTANTE_MODIF`), ',
      '`CON` = GREATEST(`CON`, VALUES(`CON`)), ',
      '`NUM_DIGITOS_CON` = GREATEST(`NUM_DIGITOS_CON`, ',
      'VALUES(`NUM_DIGITOS_CON`))'
    );
    PREPARE oSentenciaAjusteContador FROM @sSqlAjusteContador;
    EXECUTE oSentenciaAjusteContador;
    DEALLOCATE PREPARE oSentenciaAjusteContador;
  END IF;
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADOR_ID`(
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pSerie varchar(12),
  IN pUsuario varchar(100)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vUsuario varchar(100);
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME = pColumna;
  IF vExiste = 1 THEN
    SET vUsuario = COALESCE(NULLIF(TRIM(pUsuario), ''), 'SISTEMA');
    SET @sSqlAjusteContador = CONCAT(
      'INSERT INTO `fza_contadores` (',
      '`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, ',
      '`NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, ',
      '`INSTANTE_ALTA`, `INSTANTE_MODIF`, ',
      '`USUARIO_ALTA`, `USUARIO_MODIF`) ',
      'SELECT ''ID'', ''-'', ', QUOTE(pSerie), ', ',
      'COALESCE(MAX(CAST(TRIM(`', REPLACE(pColumna, '`', '``'),
      '`) AS UNSIGNED)), 0) + 1, 20, ''S'', ''N'', ',
      'CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ', QUOTE(vUsuario), ', ',
      QUOTE(vUsuario), ' FROM `', REPLACE(pTabla, '`', '``'),
      '` WHERE TRIM(COALESCE(`', REPLACE(pColumna, '`', '``'),
      '`, '''')) REGEXP ''^[0-9]+$'' ',
      'ON DUPLICATE KEY UPDATE ',
      '`USUARIO_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'VALUES(`USUARIO_MODIF`), `USUARIO_MODIF`), ',
      '`INSTANTE_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'CURRENT_TIMESTAMP, `INSTANTE_MODIF`), ',
      '`CON` = GREATEST(`CON`, VALUES(`CON`)), ',
      '`NUM_DIGITOS_CON` = GREATEST(`NUM_DIGITOS_CON`, ',
      'VALUES(`NUM_DIGITOS_CON`))'
    );
    PREPARE oSentenciaAjusteContador FROM @sSqlAjusteContador;
    EXECUTE oSentenciaAjusteContador;
    DEALLOCATE PREPARE oSentenciaAjusteContador;
  END IF;
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
  IN pTipo varchar(2),
  IN pTabla varchar(64),
  IN pEmpresa varchar(64),
  IN pSerie varchar(64),
  IN pNumero varchar(64),
  IN pColumnaFiltro varchar(64),
  IN pValorFiltro varchar(20),
  IN pDigitos int,
  IN pUsuario varchar(100)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vExisteFiltro int DEFAULT 1;
  DECLARE vFiltro varchar(500) DEFAULT '';
  DECLARE vUsuario varchar(100);
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME IN (pEmpresa, pSerie, pNumero);
  IF COALESCE(pColumnaFiltro, '') <> '' THEN
    SELECT COUNT(*) INTO vExisteFiltro
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = pTabla
       AND COLUMN_NAME = pColumnaFiltro;
    SET vFiltro = CONCAT(' AND TRIM(`',
      REPLACE(pColumnaFiltro, '`', '``'), '`) = ', QUOTE(pValorFiltro));
  END IF;
  IF vExiste = 3 AND vExisteFiltro = 1 THEN
    SET vUsuario = COALESCE(NULLIF(TRIM(pUsuario), ''), 'SISTEMA');
    SET @sSqlAjusteContador = CONCAT(
      'INSERT INTO `fza_contadores` (',
      '`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, ',
      '`NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, ',
      '`INSTANTE_ALTA`, `INSTANTE_MODIF`, ',
      '`USUARIO_ALTA`, `USUARIO_MODIF`) SELECT ', QUOTE(pTipo), ', ',
      'TRIM(`', REPLACE(pEmpresa, '`', '``'), '`), TRIM(`',
      REPLACE(pSerie, '`', '``'), '`), MAX(CAST(TRIM(`',
      REPLACE(pNumero, '`', '``'), '`) AS UNSIGNED)) + 1, ',
      'GREATEST(', GREATEST(pDigitos, 1), ', CHAR_LENGTH(CAST(',
      'MAX(CAST(TRIM(`', REPLACE(pNumero, '`', '``'),
      '`) AS UNSIGNED)) + 1 AS CHAR))), ''S'', ''N'', ',
      'CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ', QUOTE(vUsuario), ', ',
      QUOTE(vUsuario), ' FROM `', REPLACE(pTabla, '`', '``'), '` ',
      'WHERE TRIM(COALESCE(`', REPLACE(pEmpresa, '`', '``'),
      '`, '''')) <> '''' AND TRIM(COALESCE(`',
      REPLACE(pSerie, '`', '``'), '`, '''')) <> '''' AND ',
      'TRIM(COALESCE(`', REPLACE(pNumero, '`', '``'),
      '`, '''')) REGEXP ''^[0-9]+$''', vFiltro, ' GROUP BY TRIM(`',
      REPLACE(pEmpresa, '`', '``'), '`), TRIM(`',
      REPLACE(pSerie, '`', '``'), '`) ON DUPLICATE KEY UPDATE ',
      '`USUARIO_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'VALUES(`USUARIO_MODIF`), `USUARIO_MODIF`), ',
      '`INSTANTE_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'CURRENT_TIMESTAMP, `INSTANTE_MODIF`), ',
      '`CON` = GREATEST(`CON`, VALUES(`CON`)), ',
      '`NUM_DIGITOS_CON` = GREATEST(`NUM_DIGITOS_CON`, ',
      'VALUES(`NUM_DIGITOS_CON`))'
    );
    PREPARE oSentenciaAjusteContador FROM @sSqlAjusteContador;
    EXECUTE oSentenciaAjusteContador;
    DEALLOCATE PREPARE oSentenciaAjusteContador;
  END IF;
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADOR_EMPRESA`(
  IN pTipo varchar(2),
  IN pTabla varchar(64),
  IN pEmpresa varchar(64),
  IN pNumero varchar(64),
  IN pSerie varchar(12),
  IN pDigitos int,
  IN pUsuario varchar(100)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vUsuario varchar(100);
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME IN (pEmpresa, pNumero);
  IF vExiste = 2 THEN
    SET vUsuario = COALESCE(NULLIF(TRIM(pUsuario), ''), 'SISTEMA');
    SET @sSqlAjusteContador = CONCAT(
      'INSERT INTO `fza_contadores` (',
      '`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, ',
      '`NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, ',
      '`INSTANTE_ALTA`, `INSTANTE_MODIF`, ',
      '`USUARIO_ALTA`, `USUARIO_MODIF`) SELECT ', QUOTE(pTipo), ', ',
      'TRIM(`', REPLACE(pEmpresa, '`', '``'), '`), ', QUOTE(pSerie),
      ', MAX(CAST(TRIM(`', REPLACE(pNumero, '`', '``'),
      '`) AS UNSIGNED)) + 1, GREATEST(', GREATEST(pDigitos, 1),
      ', CHAR_LENGTH(CAST(MAX(CAST(TRIM(`',
      REPLACE(pNumero, '`', '``'), '`) AS UNSIGNED)) + 1 AS CHAR))), ',
      '''S'', ''N'', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ',
      QUOTE(vUsuario), ', ', QUOTE(vUsuario), ' FROM `',
      REPLACE(pTabla, '`', '``'), '` WHERE TRIM(COALESCE(`',
      REPLACE(pEmpresa, '`', '``'), '`, '''')) <> '''' AND ',
      'TRIM(COALESCE(`', REPLACE(pNumero, '`', '``'),
      '`, '''')) REGEXP ''^[0-9]+$'' GROUP BY TRIM(`',
      REPLACE(pEmpresa, '`', '``'), '`) ON DUPLICATE KEY UPDATE ',
      '`USUARIO_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'VALUES(`USUARIO_MODIF`), `USUARIO_MODIF`), ',
      '`INSTANTE_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'CURRENT_TIMESTAMP, `INSTANTE_MODIF`), ',
      '`CON` = GREATEST(`CON`, VALUES(`CON`)), ',
      '`NUM_DIGITOS_CON` = GREATEST(`NUM_DIGITOS_CON`, ',
      'VALUES(`NUM_DIGITOS_CON`))'
    );
    PREPARE oSentenciaAjusteContador FROM @sSqlAjusteContador;
    EXECUTE oSentenciaAjusteContador;
    DEALLOCATE PREPARE oSentenciaAjusteContador;
  END IF;
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADOR_PREFIJO`(
  IN pTipo varchar(2),
  IN pTabla varchar(64),
  IN pColumna varchar(64),
  IN pPrefijo varchar(2),
  IN pUsuario varchar(100)
)
BEGIN
  DECLARE vExiste int DEFAULT 0;
  DECLARE vUsuario varchar(100);
  SELECT COUNT(*) INTO vExiste
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = pTabla
     AND COLUMN_NAME = pColumna;
  IF vExiste = 1 AND pPrefijo REGEXP '^[0-9]{2}$' THEN
    SET vUsuario = COALESCE(NULLIF(TRIM(pUsuario), ''), 'SISTEMA');
    SET @sSqlAjusteContador = CONCAT(
      'INSERT INTO `fza_contadores` (',
      '`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, ',
      '`NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, ',
      '`INSTANTE_ALTA`, `INSTANTE_MODIF`, ',
      '`USUARIO_ALTA`, `USUARIO_MODIF`) SELECT ', QUOTE(pTipo),
      ', ''-'', ''-'', COALESCE(MAX(CAST(SUBSTRING(TRIM(`',
      REPLACE(pColumna, '`', '``'), '`), 3, 10) AS UNSIGNED)), 0) + 1, ',
      '10, ''S'', ''S'', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ',
      QUOTE(vUsuario), ', ', QUOTE(vUsuario), ' FROM `',
      REPLACE(pTabla, '`', '``'), '` WHERE TRIM(`',
      REPLACE(pColumna, '`', '``'), '`) REGEXP ',
      QUOTE(CONCAT('^', pPrefijo, '[0-9]{11}$')), ' ',
      'ON DUPLICATE KEY UPDATE ',
      '`USUARIO_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'VALUES(`USUARIO_MODIF`), `USUARIO_MODIF`), ',
      '`INSTANTE_MODIF` = IF(VALUES(`CON`) > `CON` OR ',
      'VALUES(`NUM_DIGITOS_CON`) > `NUM_DIGITOS_CON`, ',
      'CURRENT_TIMESTAMP, `INSTANTE_MODIF`), ',
      '`CON` = GREATEST(`CON`, VALUES(`CON`)), ',
      '`NUM_DIGITOS_CON` = GREATEST(`NUM_DIGITOS_CON`, ',
      'VALUES(`NUM_DIGITOS_CON`))'
    );
    PREPARE oSentenciaAjusteContador FROM @sSqlAjusteContador;
    EXECUTE oSentenciaAjusteContador;
    DEALLOCATE PREPARE oSentenciaAjusteContador;
  END IF;
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADORES_MAESTROS`(
  IN pUsuario varchar(100)
)
BEGIN
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'AR', 'fza_articulos', 'CODIGO_ART_ART', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'AO', 'fza_articulos', 'ORDEN_ART', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'CL', 'fza_clientes', 'CODIGO_CLI_CLI', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'CO', 'fza_clientes', 'ORDEN_CLI', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'PV', 'fza_proveedores', 'CODIGO_PRV_PRV', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'PO', 'fza_proveedores', 'ORDEN_PRV', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'EM', 'fza_empresas', 'CODIGO_EMP_EMP', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'EO', 'fza_empresas', 'ORDEN_EMP', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'ES', 'fza_empresas_series', 'CODIGO_SERIE_EMPSER', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'EB', 'fza_empresas_bancos', 'CODIGO_EMPBAN', 4, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'RT', 'fza_empresas_retenciones', 'CODIGO_RETENCION_EMPRET', 3,
    pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'FA', 'fza_articulos_familias', 'CODIGO_FAM_FAM', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'FO', 'fza_articulos_familias', 'ORDEN_FAM', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'PG', 'fza_formas_pago', 'CODIGO_FP_FP', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'GO', 'fza_formas_pago', 'ORDEN_FORMA_PAGO_FP', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'GP', 'fza_generadorprocesos', 'CODIGO_GENERADOR_PROCESO_GP', 3,
    pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'IG', 'fza_ivas_grupos', 'IVA_IVAGRP', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'IV', 'fza_ivas', 'CODIGO_IVA', 3, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'MV', 'fza_movimientos_almacen', 'NUMERO_MOV', 10, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'RC', 'fza_remesas_venta', 'NUMERO_REMV', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'RP', 'fza_remesas_compra', 'NUMERO_REMC', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_GLOBAL`(
    'TS', 'fza_traspasos_solicitudes', 'NUMERO_TRSOL', 10, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_PREFIJO`(
    'BA', 'fza_codigos_barras', 'CODIGO_BARRAS_CB', '21', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_PREFIJO`(
    'TK', 'fza_facturas', 'CODIGO_BARRAS_FAC', '29', pUsuario);
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADORES_DOCUMENTOS`(
  IN pUsuario varchar(100)
)
BEGIN
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'FC', 'fza_facturas', 'CODIGO_EMP_FAC', 'SERIE_FAC', 'NUMERO_FAC',
    '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'PE', 'fza_pedidos', 'CODIGO_EMP_PED', 'SERIE_PED', 'NUMERO_PED',
    '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'AV', 'fza_albaranes', 'CODIGO_EMP_ALB', 'SERIE_ALB', 'NUMERO_ALB',
    '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'PC', 'fza_pedidos_compra', 'CODIGO_EMP_PEDC', 'SERIE_PEDC',
    'NUMERO_PEDC', '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'AB', 'fza_albaranes_compra', 'CODIGO_EMP_ALBC', 'SERIE_ALBC',
    'NUMERO_ALBC', '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'DC', 'fza_devoluciones_compra', 'CODIGO_EMP_DEVC', 'SERIE_DEVC',
    'NUMERO_DEVC', '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'FP', 'fza_facturas_compra', 'CODIGO_EMP_FACC', 'SERIE_FACC',
    'NUMERO_FACC', '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'IN', 'fza_inventarios', 'CODIGO_EMP_INV', 'SERIE_INV', 'NUMERO_INV',
    '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'SE', 'fza_compras_sesiones', 'CODIGO_EMP_SES', 'SERIE_SES',
    'NUMERO_SES', '', '', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'TR', 'fza_caja_operaciones', 'CODIGO_EMP_OPCAJA',
    'SERIE_FAC_OPCAJA', 'NUMERO_FAC_OPCAJA', 'TIPO_OPERACION_OPCAJA',
    'TR', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'TA', 'fza_caja_operaciones', 'CODIGO_EMP_OPCAJA',
    'SERIE_FAC_OPCAJA', 'NUMERO_FAC_OPCAJA', 'TIPO_OPERACION_OPCAJA',
    'TA', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_DOCUMENTO`(
    'TA', 'fza_caja_operaciones', 'CODIGO_EMP_OPCAJA',
    'SERIE_FAC_OPCAJA', 'NUMERO_FAC_OPCAJA', 'TIPO_OPERACION_OPCAJA',
    'AT', 6, pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_EMPRESA`(
    'OV', 'fza_caja_operaciones', 'CODIGO_EMP_OPCAJA',
    'NUMERO_OPERACION_OPCAJA', 'OV', 8, pUsuario);
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADORES_ID`(
  IN pUsuario varchar(100)
)
BEGIN
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_articulos_tarifas', 'CODIGO_UNICO_ARTTAR', 'ART_TAR', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_articulos_vinculos', 'ID_ARTVIN', 'ART_VINC', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_atributos_basicos', 'ID_ATB', 'ATR_BASIC', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_atributos_conjuntos', 'ID_AC', 'ATR_CONJ', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_atributos_valores', 'ID_AV', 'ATR_VAL', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_atributos_valores_info', 'ID_AVI', 'ATR_VALINF', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_caja_arqueos_recuento', 'ID_ARQR', 'CAJ_ARQREC', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_caja_operaciones', 'ID_OPCAJA', 'CAJ_OPER', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_codigos_barras', 'ID_CB', 'COD_BARRAS', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_documentos_trabajo', 'ID_DTR', 'DOC_TRAB', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_documentos_trabajo_compartidos', 'ID_DTC', 'DOC_COMP', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_documentos_trabajo_lineas', 'ID_DTL', 'DOC_LINEA', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_facturas_relaciones', 'ID_FACREL', 'FAC_REL', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_filtros_guardados', 'ID_FILT', 'FILTRO', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_filtros_guardados_compartidos', 'ID_FILTC', 'FILT_COMP',
    pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_inventarios_recuentos', 'ID_INVREC', 'FZA_INVREC', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_metadatos', 'CODIGO_META_META', 'METADATO', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_propiedades_valores', 'ID_PV_ARTPROP', 'PROP_VAL', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_tarifas_cambios', 'CODIGO_TARC', 'TAR_CAMBIO', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_tarifas_cambios_lineas', 'ID_TARCLIN', 'TAR_LINEA', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_traducciones', 'ID_TRAD', 'TRADUCCION', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_ventas_ws_cola', 'ID_VWSC', 'VENTAS_WS', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_verifactu_cola', 'ID_VFCOLA', 'VF_COLA', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'fza_verifactu_eventos', 'ID_LOG', 'VF_EVENTO', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'inv_almacenes', 'id', 'INV_ALM', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'inv_catalogo', 'id', 'INV_CAT', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'inv_dispositivos', 'id', 'INV_DISP', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'inv_eventos', 'id', 'INV_EVENTO', pUsuario);
  CALL `PRC_AJUSTAR_CONTADOR_ID`(
    'inv_recuentos', 'id', 'INV_RECUENTO', pUsuario);
END ;;

CREATE PROCEDURE `PRC_AJUSTAR_CONTADORES`(
  IN p_USUARIO varchar(100)
)
BEGIN
  CALL `PRC_AJUSTAR_CONTADORES_MAESTROS`(p_USUARIO);
  CALL `PRC_AJUSTAR_CONTADORES_DOCUMENTOS`(p_USUARIO);
  CALL `PRC_AJUSTAR_CONTADORES_ID`(p_USUARIO);
END ;;

DELIMITER ;

SELECT ROUTINE_NAME
  FROM INFORMATION_SCHEMA.ROUTINES
 WHERE ROUTINE_SCHEMA = DATABASE()
   AND ROUTINE_NAME LIKE 'PRC_AJUSTAR_CONTADOR%'
 ORDER BY ROUTINE_NAME;
