inherited dmFacturas: TdmFacturas
  Height = 590
  Width = 1241
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_facturas`'
      
        '  (`NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `ESCONSOLIDADA_FAC`, `INSTANTECONSO_FAC`, `TIPO_FAC`, `FASE_FAC`, `CODIGO_EMP_FAC`, `RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, `MOVIL_EMPRESA_FAC`, `EMAI' +
        'L_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC`, `DIRECCION2_EMPRESA_FAC`, `POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC`, `CODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_POSTAL_EMPRESA_FAC`, `' +
        'ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_EMPRESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_CLI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC`, `MOVIL_CLIENTE_FAC`, `EMAIL_CLIENTE_' +
        'FAC`, `DIRECCION1_CLIENTE_FAC`, `DIRECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC`, `PROVINCIA_CLIENTE_FAC`, `CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`, `NOMBRE_PAI_CLIENTE_FAC`, `CODIGO_IVA' +
        '_FAC`, `ESIVA_RECARGO_CLIENTE_FAC`, `ESIVA_EXENTO_CLIENTE_FAC`, `ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIENTE_FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC`, `E' +
        'SINTRACOMUNITARIO_CLIENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IVA_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_FAC`, `ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVAN_FA' +
        'C`, `TOTAL_IVAN_FAC`, `PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC`, `TOTAL_BASEI_IVAN_FAC`, `PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC`, `PORCENTAJE_RER_FAC`, `TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC`, `PORCENTAJE' +
        '_IVAS_FAC`, `TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC`, `TOTAL_RES_FAC`, `TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC`, `PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC`, `TO' +
        'TAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC`, `PORCENTAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC`, `NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL_CLIENTE_FAC' +
        '`, `TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC`, `COMENTARIOS_FAC`, `CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC`, `ESDESCRIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC`, `XML_FAC`, `INSTANTE_MODIF`, `INSTAN' +
        'TE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`, `CODIGO_CAJERO_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC`, `NUMERO_OPERACION_FAC`)'
      'VALUES'
      
        '  (:`NUMERO_FAC`, :`SERIE_FAC`, :`FECHA_FAC`, :`ESCONSOLIDADA_FAC`, :`INSTANTECONSO_FAC`, :`TIPO_FAC`, :`FASE_FAC`, :`CODIGO_EMP_FAC`, :`RAZON_SOCIAL_EMPRESA_FAC`, :`NIF_EMPRESA_FAC`, :`MOVIL_EMPRESA_' +
        'FAC`, :`EMAIL_EMPRESA_FAC`, :`DIRECCION1_EMPRESA_FAC`, :`DIRECCION2_EMPRESA_FAC`, :`POBLACION_EMPRESA_FAC`, :`PROVINCIA_EMPRESA_FAC`, :`CODIGO_PAI_EMPRESA_FAC`, :`NOMBRE_PAI_EMPRESA_FAC`, :`CODIGO_POS' +
        'TAL_EMPRESA_FAC`, :`ESRETENCIONES_EMPRESA_FAC`, :`GRUPO_ZONA_IVA_EMPRESA_FAC`, :`ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, :`CODIGO_CLI_FAC`, :`RAZON_SOCIAL_CLIENTE_FAC`, :`NIF_CLIENTE_FAC`, :`MOVIL_CLI' +
        'ENTE_FAC`, :`EMAIL_CLIENTE_FAC`, :`DIRECCION1_CLIENTE_FAC`, :`DIRECCION2_CLIENTE_FAC`, :`POBLACION_CLIENTE_FAC`, :`PROVINCIA_CLIENTE_FAC`, :`CODIGO_POSTAL_CLIENTE_FAC`, :`CODIGO_PAI_CLIENTE_FAC`, :`NO' +
        'MBRE_PAI_CLIENTE_FAC`, :`CODIGO_IVA_FAC`, :`ESIVA_RECARGO_CLIENTE_FAC`, :`ESIVA_EXENTO_CLIENTE_FAC`, :`ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC`, :`ESRETENCIONES_CLIENTE_FAC`, :`TARIFA_ARTICULO_CLIENTE_F' +
        'AC`, :`ESIMP_INCL_TARIFA_CLIENTE_FAC`, :`ESINTRACOMUNITARIO_CLIENTE_FAC`, :`ESIRPF_IMP_INCL_ZONA_IVA_FAC`, :`ESAPLICA_RE_ZONA_IVA_FAC`, :`ESIVAAGRICOLA_ZONA_IVA_FAC`, :`PALABRA_REPORTS_ZONA_IVA_FAC`, ' +
        ':`ESVENTA_ACTIVO_FIJO_FAC`, :`PORCENTAJE_IVAN_FAC`, :`TOTAL_IVAN_FAC`, :`PORCENTAJE_REN_FAC`, :`TOTAL_REN_FAC`, :`TOTAL_BASEI_IVAN_FAC`, :`PORCENTAJE_IVAR_FAC`, :`TOTAL_IVAR_FAC`, :`PORCENTAJE_RER_FAC' +
        '`, :`TOTAL_RER_FAC`, :`TOTAL_BASEI_IVAR_FAC`, :`PORCENTAJE_IVAS_FAC`, :`TOTAL_IVAS_FAC`, :`PORCENTAJE_RES_FAC`, :`TOTAL_RES_FAC`, :`TOTAL_BASEI_IVAS_FAC`, :`PORCENTAJE_IVAE_FAC`, :`TOTAL_IVAE_FAC`, :`' +
        'PORCENTAJE_REE_FAC`, :`TOTAL_REE_FAC`, :`TOTAL_BASEI_IVAE_FAC`, :`TOTAL_BASES_FAC`, :`TOTAL_IMPUESTOS_FAC`, :`FORMA_PAGO_FAC`, :`PORCENTAJE_RETENCION_FAC`, :`TOTAL_RETENCION_FAC`, :`TOTAL_LIQUIDO_FAC`' +
        ', :`NUMERO_FAC_ABONO_FAC`, :`SERIE_FAC_ABONO_FAC`, :`TEXTO_LEGAL_CLIENTE_FAC`, :`TEXTO_LEGAL_EMPRESA_FAC`, :`DOCUMENTO_FAC`, :`COMENTARIOS_FAC`, :`CONTADOR_LINEAS_FAC`, :`ESCREARARTICULOS_FAC`, :`ESDE' +
        'SCRIPCIONES_AMP_FAC`, :`ESFECHADEENTREGA_FAC`, :`XML_FAC`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`, :`CODIGO_CAJERO_FAC`, :`CODIGO_ALM_FAC`, :`CODIGO_CAJA_FAC`, :`NUMERO' +
        '_OPERACION_FAC`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_facturas`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`Old_NUMERO_FAC` AND `SERIE_FAC` = :`Old_SERIE_FAC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_facturas`'
      'SET'
      
        '  `NUMERO_FAC` = :`NUMERO_FAC`, `SERIE_FAC` = :`SERIE_FAC`, `FECHA_FAC` = :`FECHA_FAC`, `ESCONSOLIDADA_FAC` = :`ESCONSOLIDADA_FAC`, `INSTANTECONSO_FAC` = :`INSTANTECONSO_FAC`, `TIPO_FAC` = :`TIPO_FAC`' +
        ', `FASE_FAC` = :`FASE_FAC`, `CODIGO_EMP_FAC` = :`CODIGO_EMP_FAC`, `RAZON_SOCIAL_EMPRESA_FAC` = :`RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC` = :`NIF_EMPRESA_FAC`, `MOVIL_EMPRESA_FAC` = :`MOVIL_EMPRES' +
        'A_FAC`, `EMAIL_EMPRESA_FAC` = :`EMAIL_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC` = :`DIRECCION1_EMPRESA_FAC`, `DIRECCION2_EMPRESA_FAC` = :`DIRECCION2_EMPRESA_FAC`, `POBLACION_EMPRESA_FAC` = :`POBLACION_EM' +
        'PRESA_FAC`, `PROVINCIA_EMPRESA_FAC` = :`PROVINCIA_EMPRESA_FAC`, `CODIGO_PAI_EMPRESA_FAC` = :`CODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC` = :`NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_POSTAL_EMPRESA_FAC` ' +
        '= :`CODIGO_POSTAL_EMPRESA_FAC`, `ESRETENCIONES_EMPRESA_FAC` = :`ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_EMPRESA_FAC` = :`GRUPO_ZONA_IVA_EMPRESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC` = :`ES' +
        'REGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_CLI_FAC` = :`CODIGO_CLI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC` = :`RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC` = :`NIF_CLIENTE_FAC`, `MOVIL_CLIENTE_FAC` = :`MO' +
        'VIL_CLIENTE_FAC`, `EMAIL_CLIENTE_FAC` = :`EMAIL_CLIENTE_FAC`, `DIRECCION1_CLIENTE_FAC` = :`DIRECCION1_CLIENTE_FAC`, `DIRECCION2_CLIENTE_FAC` = :`DIRECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC` = :`PO' +
        'BLACION_CLIENTE_FAC`, `PROVINCIA_CLIENTE_FAC` = :`PROVINCIA_CLIENTE_FAC`, `CODIGO_POSTAL_CLIENTE_FAC` = :`CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC` = :`CODIGO_PAI_CLIENTE_FAC`, `NOMBRE_PAI_' +
        'CLIENTE_FAC` = :`NOMBRE_PAI_CLIENTE_FAC`, `CODIGO_IVA_FAC` = :`CODIGO_IVA_FAC`, `ESIVA_RECARGO_CLIENTE_FAC` = :`ESIVA_RECARGO_CLIENTE_FAC`, `ESIVA_EXENTO_CLIENTE_FAC` = :`ESIVA_EXENTO_CLIENTE_FAC`, `E' +
        'SREGIMENESPECIALAGRICOLA_CLIENTE_FAC` = :`ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC` = :`ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIENTE_FAC` = :`TARIFA_ARTICULO_CLIENTE_' +
        'FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC` = :`ESIMP_INCL_TARIFA_CLIENTE_FAC`, `ESINTRACOMUNITARIO_CLIENTE_FAC` = :`ESINTRACOMUNITARIO_CLIENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC` = :`ESIRPF_IMP_INCL_ZONA_' +
        'IVA_FAC`, `ESAPLICA_RE_ZONA_IVA_FAC` = :`ESAPLICA_RE_ZONA_IVA_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC` = :`ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_FAC` = :`PALABRA_REPORTS_ZONA_IVA_FAC`, `ESV' +
        'ENTA_ACTIVO_FIJO_FAC` = :`ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVAN_FAC` = :`PORCENTAJE_IVAN_FAC`, `TOTAL_IVAN_FAC` = :`TOTAL_IVAN_FAC`, `PORCENTAJE_REN_FAC` = :`PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC` ' +
        '= :`TOTAL_REN_FAC`, `TOTAL_BASEI_IVAN_FAC` = :`TOTAL_BASEI_IVAN_FAC`, `PORCENTAJE_IVAR_FAC` = :`PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC` = :`TOTAL_IVAR_FAC`, `PORCENTAJE_RER_FAC` = :`PORCENTAJE_RER_FAC`' +
        ', `TOTAL_RER_FAC` = :`TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC` = :`TOTAL_BASEI_IVAR_FAC`, `PORCENTAJE_IVAS_FAC` = :`PORCENTAJE_IVAS_FAC`, `TOTAL_IVAS_FAC` = :`TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC` = :`P' +
        'ORCENTAJE_RES_FAC`, `TOTAL_RES_FAC` = :`TOTAL_RES_FAC`, `TOTAL_BASEI_IVAS_FAC` = :`TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC` = :`PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC` = :`TOTAL_IVAE_FAC`, `PORCENT' +
        'AJE_REE_FAC` = :`PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC` = :`TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC` = :`TOTAL_BASEI_IVAE_FAC`, `TOTAL_BASES_FAC` = :`TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC` = :`TOTAL_IMPU' +
        'ESTOS_FAC`, `FORMA_PAGO_FAC` = :`FORMA_PAGO_FAC`, `PORCENTAJE_RETENCION_FAC` = :`PORCENTAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC` = :`TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC` = :`TOTAL_LIQUIDO_FAC`, ' +
        '`NUMERO_FAC_ABONO_FAC` = :`NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC` = :`SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL_CLIENTE_FAC` = :`TEXTO_LEGAL_CLIENTE_FAC`, `TEXTO_LEGAL_EMPRESA_FAC` = :`TEXTO_LEGAL_EMPR' +
        'ESA_FAC`, `DOCUMENTO_FAC` = :`DOCUMENTO_FAC`, `COMENTARIOS_FAC` = :`COMENTARIOS_FAC`, `CONTADOR_LINEAS_FAC` = :`CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC` = :`ESCREARARTICULOS_FAC`, `ESDESCRIPCIONES' +
        '_AMP_FAC` = :`ESDESCRIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC` = :`ESFECHADEENTREGA_FAC`, `XML_FAC` = :`XML_FAC`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALT' +
        'A` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`, `CODIGO_CAJERO_FAC` = :`CODIGO_CAJERO_FAC`, `CODIGO_ALM_FAC` = :`CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC` = :`CODIGO_CAJA_FAC`, `NUMERO_OPERACION_FA' +
        'C` = :`NUMERO_OPERACION_FAC`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`Old_NUMERO_FAC` AND `SERIE_FAC` = :`Old_SERIE_FAC`')
    SQLLock.Strings = (
      
        'SELECT `NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `ESCONSOLIDADA_FAC`, `INSTANTECONSO_FAC`, `TIPO_FAC`, `FASE_FAC`, `CODIGO_EMP_FAC`, `RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, `MOVIL_EMPRESA_FAC`, `' +
        'EMAIL_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC`, `DIRECCION2_EMPRESA_FAC`, `POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC`, `CODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_POSTAL_EMPRESA_FAC' +
        '`, `ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_EMPRESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_CLI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC`, `MOVIL_CLIENTE_FAC`, `EMAIL_CLIE' +
        'NTE_FAC`, `DIRECCION1_CLIENTE_FAC`, `DIRECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC`, `PROVINCIA_CLIENTE_FAC`, `CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`, `NOMBRE_PAI_CLIENTE_FAC`, `CODIGO' +
        '_IVA_FAC`, `ESIVA_RECARGO_CLIENTE_FAC`, `ESIVA_EXENTO_CLIENTE_FAC`, `ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIENTE_FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC`' +
        ', `ESINTRACOMUNITARIO_CLIENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IVA_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_FAC`, `ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVA' +
        'N_FAC`, `TOTAL_IVAN_FAC`, `PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC`, `TOTAL_BASEI_IVAN_FAC`, `PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC`, `PORCENTAJE_RER_FAC`, `TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC`, `PORCEN' +
        'TAJE_IVAS_FAC`, `TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC`, `TOTAL_RES_FAC`, `TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC`, `PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC`,' +
        ' `TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC`, `PORCENTAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC`, `NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL_CLIENTE' +
        '_FAC`, `TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC`, `COMENTARIOS_FAC`, `CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC`, `ESDESCRIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC`, `XML_FAC`, `INSTANTE_MODIF`, `IN' +
        'STANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`, `CODIGO_CAJERO_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC`, `NUMERO_OPERACION_FAC` FROM `fza_facturas`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`Old_NUMERO_FAC` AND `SERIE_FAC` = :`Old_SERIE_FAC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `ESCONSOLIDADA_FAC`, `INSTANTECONSO_FAC`, `TIPO_FAC`, `FASE_FAC`, `CODIGO_EMP_FAC`, `RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, `MOVIL_EMPRESA_FAC`, `' +
        'EMAIL_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC`, `DIRECCION2_EMPRESA_FAC`, `POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC`, `CODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_POSTAL_EMPRESA_FAC' +
        '`, `ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_EMPRESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_CLI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC`, `MOVIL_CLIENTE_FAC`, `EMAIL_CLIE' +
        'NTE_FAC`, `DIRECCION1_CLIENTE_FAC`, `DIRECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC`, `PROVINCIA_CLIENTE_FAC`, `CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`, `NOMBRE_PAI_CLIENTE_FAC`, `CODIGO' +
        '_IVA_FAC`, `ESIVA_RECARGO_CLIENTE_FAC`, `ESIVA_EXENTO_CLIENTE_FAC`, `ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIENTE_FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC`' +
        ', `ESINTRACOMUNITARIO_CLIENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IVA_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_FAC`, `ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVA' +
        'N_FAC`, `TOTAL_IVAN_FAC`, `PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC`, `TOTAL_BASEI_IVAN_FAC`, `PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC`, `PORCENTAJE_RER_FAC`, `TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC`, `PORCEN' +
        'TAJE_IVAS_FAC`, `TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC`, `TOTAL_RES_FAC`, `TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC`, `PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC`,' +
        ' `TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC`, `PORCENTAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC`, `NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL_CLIENTE' +
        '_FAC`, `TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC`, `COMENTARIOS_FAC`, `CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC`, `ESDESCRIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC`, `XML_FAC`, `INSTANTE_MODIF`, `IN' +
        'STANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`, `CODIGO_CAJERO_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC`, `NUMERO_OPERACION_FAC` FROM `fza_facturas`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`NUMERO_FAC` AND `SERIE_FAC` = :`SERIE_FAC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_facturas')
    BeforeInsert = nil
    AfterInsert = unqryTablaGAfterInsert
    BeforeEdit = unqryTablaGBeforeEdit
    BeforePost = unqryFacBeforePost
    AfterPost = unqryFacAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 45
    Top = 109
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles')
    Left = 275
    Top = 141
  end
  inherited dsPerfiles: TDataSource
    Left = 274
    Top = 61
  end
  object dsLinFac: TDataSource
    DataSet = unqryLinFac
    OnStateChange = dsLinFacStateChange
    Left = 134
    Top = 38
  end
  object dsFacPrint: TDataSource
    DataSet = unqryFacPrint
    Left = 454
    Top = 429
  end
  object dsLinFacPrint: TDataSource
    DataSet = unqryLinFacPrint
    Left = 574
    Top = 429
  end
  object dsSeries: TDataSource
    DataSet = unqrySeries
    Left = 435
    Top = 38
  end
  object fxdsPrintFac: TfrxDBDataset
    Description = 'Facturas'
    UserName = 'Facturas'
    CloseDataSource = False
    DataSource = dsFacPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 454
    Top = 346
    FieldDefs = <
      item
        FieldName = 'FECHA_FAC'
        FieldType = fftDateTime
      end
      item
        FieldName = 'NUMERO_FAC'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'SERIE_FAC'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'TOTAL_LIQUIDO_FAC'
      end
      item
        FieldName = 'PORCENTAJE_RETENCION_FAC'
      end
      item
        FieldName = 'TOTAL_RETENCION_FAC'
      end
      item
        FieldName = 'TOTAL_IMPUESTOS_FAC'
      end
      item
        FieldName = 'TOTAL_BASES_FAC'
      end
      item
        FieldName = 'FORMA_PAGO_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'CODIGO_EMP_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'RAZON_SOCIAL_EMPRESA_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'NIF_EMPRESA_FAC'
        FieldType = fftString
        Size = 50
      end
      item
        FieldName = 'MOVIL_EMPRESA_FAC'
        FieldType = fftString
        Size = 40
      end
      item
        FieldName = 'EMAIL_EMPRESA_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'DIRECCION1_EMPRESA_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'DIRECCION2_EMPRESA_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'POBLACION_EMPRESA_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'PROVINCIA_EMPRESA_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'NOMBRE_PAI_EMPRESA_FAC'
        FieldType = fftString
        Size = 150
      end
      item
        FieldName = 'CODIGO_PAI_EMPRESA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'CODIGO_POSTAL_EMPRESA_FAC'
        FieldType = fftString
        Size = 15
      end
      item
        FieldName = 'ESRETENCIONES_EMPRESA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'CODIGO_CLI_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'NIF_CLIENTE_FAC'
        FieldType = fftString
        Size = 50
      end
      item
        FieldName = 'MOVIL_CLIENTE_FAC'
        FieldType = fftString
        Size = 40
      end
      item
        FieldName = 'EMAIL_CLIENTE_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'DIRECCION1_CLIENTE_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'DIRECCION2_CLIENTE_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'POBLACION_CLIENTE_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'PROVINCIA_CLIENTE_FAC'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
        FieldType = fftString
        Size = 15
      end
      item
        FieldName = 'NOMBRE_PAI_CLIENTE_FAC'
        FieldType = fftString
        Size = 150
      end
      item
        FieldName = 'CODIGO_PAI_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESIVA_EXENTO_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESRETENCIONES_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'TARIFA_ARTICULO_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESAPLICA_RE_ZONA_IVA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'PALABRA_REPORTS_ZONA_IVA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'CODIGO_IVA_FAC'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'ESVENTA_ACTIVO_FIJO_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'PORCENTAJE_IVAN_FAC'
      end
      item
        FieldName = 'TOTAL_IVAN_FAC'
      end
      item
        FieldName = 'PORCENTAJE_REN_FAC'
      end
      item
        FieldName = 'TOTAL_REN_FAC'
      end
      item
        FieldName = 'TOTAL_BASEI_IVAN_FAC'
      end
      item
        FieldName = 'PORCENTAJE_IVAR_FAC'
      end
      item
        FieldName = 'TOTAL_IVAR_FAC'
      end
      item
        FieldName = 'PORCENTAJE_RER_FAC'
      end
      item
        FieldName = 'TOTAL_RER_FAC'
      end
      item
        FieldName = 'TOTAL_BASEI_IVAR_FAC'
      end
      item
        FieldName = 'PORCENTAJE_IVAS_FAC'
      end
      item
        FieldName = 'TOTAL_IVAS_FAC'
      end
      item
        FieldName = 'PORCENTAJE_RES_FAC'
      end
      item
        FieldName = 'TOTAL_RES_FAC'
      end
      item
        FieldName = 'TOTAL_BASEI_IVAS_FAC'
      end
      item
        FieldName = 'PORCENTAJE_IVAE_FAC'
      end
      item
        FieldName = 'TOTAL_IVAE_FAC'
      end
      item
        FieldName = 'PORCENTAJE_REE_FAC'
      end
      item
        FieldName = 'TOTAL_REE_FAC'
      end
      item
        FieldName = 'TOTAL_BASEI_IVAE_FAC'
      end
      item
        FieldName = 'NUMERO_FAC_ABONO_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'SERIE_FAC_ABONO_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'TEXTO_LEGAL_CLIENTE_FAC'
        FieldType = fftString
        Size = 1000
      end
      item
        FieldName = 'TEXTO_LEGAL_EMPRESA_FAC'
        FieldType = fftString
        Size = 1000
      end
      item
        FieldName = 'DOCUMENTO_FAC'
      end
      item
        FieldName = 'COMENTARIOS_FAC'
        FieldType = fftString
        Size = 1000
      end
      item
        FieldName = 'CONTADOR_LINEAS_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESCREARARTICULOS_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESDESCRIPCIONES_AMP_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'ESFECHADEENTREGA_FAC'
        FieldType = fftString
      end
      item
        FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'ESCONTADO_FORMA_PAGO_FP'
        FieldType = fftString
      end
      item
        FieldName = 'VENCIMIENTOS_RECIBOS'
      end
      item
        FieldName = 'IBAN_EMP'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'IBAN_CLI'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'ESVERBANCOEMPRESA_FORMA_PAGO_FP'
        FieldType = fftString
      end>
  end
  object fxdstPrintLinFac: TfrxDBDataset
    Description = 'Lineas Facturas'
    UserName = 'Lineas Facturas'
    CloseDataSource = False
    DataSource = dsLinFacPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 574
    Top = 346
    FieldDefs = <
      item
        FieldName = 'NUMERO_FAC_FACLIN'
        FieldAlias = 'NUMERO_FAC_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'SERIE_FAC_FACLIN'
        FieldAlias = 'SERIE_FAC_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'LINEA_FACLIN'
        FieldAlias = 'LINEA_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'CODIGO_ART_FACLIN'
        FieldAlias = 'CODIGO_ART_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'CODIGO_FAM_FACLIN'
        FieldAlias = 'CODIGO_FAM_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'NOMBRE_FAM_FACLIN'
        FieldAlias = 'NOMBRE_FAM_FACLIN'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'FECHA_ENTREGA_FACLIN'
        FieldAlias = 'FECHA_ENTREGA_FACLIN'
        FieldType = fftDateTime
      end
      item
        FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
        FieldAlias = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'ESIMP_INCL_TARIFA_FACLIN'
        FieldAlias = 'ESIMP_INCL_TARIFA_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
        FieldAlias = 'TIPO_IVA_ARTICULO_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
        FieldAlias = 'DESCRIPCION_ARTICULO_FACLIN'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'CODIGO_TAR_FACLIN'
        FieldAlias = 'CODIGO_TAR_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'CANTIDAD_FACLIN'
        FieldAlias = 'CANTIDAD_FACLIN'
      end
      item
        FieldName = 'PRECIO_SALIDA_FACLIN'
        FieldAlias = 'PRECIO_SALIDA_FACLIN'
      end
      item
        FieldName = 'PORCENTAJE_DTO_FACLIN'
        FieldAlias = 'PORCENTAJE_DTO_FACLIN'
      end
      item
        FieldName = 'PRECIO_DTO_FACLIN'
        FieldAlias = 'PRECIO_DTO_FACLIN'
      end
      item
        FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
        FieldAlias = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
      end
      item
        FieldName = 'PORCENTAJE_IVA_FACLIN'
        FieldAlias = 'PORCENTAJE_IVA_FACLIN'
      end
      item
        FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
        FieldAlias = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
      end
      item
        FieldName = 'TOTAL_FACLIN'
        FieldAlias = 'TOTAL_FACLIN'
      end
      item
        FieldName = 'INSTANTE_MODIF'
        FieldAlias = 'INSTANTE_MODIF'
        FieldType = fftDateTime
      end
      item
        FieldName = 'INSTANTE_ALTA'
        FieldAlias = 'INSTANTE_ALTA'
        FieldType = fftDateTime
      end
      item
        FieldName = 'USUARIO_ALTA'
        FieldAlias = 'USUARIO_ALTA'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'USUARIO_MODIF'
        FieldAlias = 'USUARIO_MODIF'
        FieldType = fftString
        Size = 100
      end>
  end
  object unqryFacPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'from VI_FACTURAS_PRINT'
      'where SERIE_FAC = '#39'ANA/2023'#39' '
      'AND NUMERO_FAC = '#39'000003'#39
      'order by NUMERO_FAC Asc')
    Active = True
    Left = 454
    Top = 506
  end
  object unqryLinFacPrint: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_FACTURAS_LINEAS`'
      
        '  (`SERIE_FAC_FACLIN`, `NUMERO_FAC_FACLIN`, `LINEA_LINEA`, `CODIGO_ARTICULO_LINEA`, `DESCRIPCION_ARTICULO_LINEA`, `ZONA`, `PRECIOVENTA_ARTICULO_LINEA`, `CANTIDAD_LINEA`, `SUM_TOTAL_LINEA`, `ODONTOLOGO`)'
      'VALUES'
      
        '  (:`SERIE_FAC_FACLIN`, :`NUMERO_FAC_FACLIN`, :`LINEA_LINEA`, :`CODIGO_ARTICULO_LINEA`, :`DESCRIPCION_ARTICULO_LINEA`, :`ZONA`, :`PRECIOVENTA_ARTICULO_LINEA`, :`CANTIDAD_LINEA`, :`SUM_TOTAL_LINEA`, :`ODONTOLOGO`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_FACTURAS_LINEAS`'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`Old_LINEA_LINEA`')
    SQLUpdate.Strings = (
      'UPDATE `fza_FACTURAS_LINEAS`'
      'SET'
      
        '  `SERIE_FAC_FACLIN` = :`SERIE_FAC_FACLIN`, `NUMERO_FAC_FACLIN` = :`NUMERO_FAC_FACLIN`, `LINEA_LINEA` = :`LINEA_LINEA`, `CODIGO_ARTICULO_LINEA` = :`CODIGO_ARTICULO_LINEA`, `DESCRIPCION_ARTICULO_LINEA`' +
        ' = :`DESCRIPCION_ARTICULO_LINEA`, `ZONA` = :`ZONA`, `PRECIOVENTA_ARTICULO_LINEA` = :`PRECIOVENTA_ARTICULO_LINEA`, `CANTIDAD_LINEA` = :`CANTIDAD_LINEA`, `SUM_TOTAL_LINEA` = :`SUM_TOTAL_LINEA`, `ODONTOL' +
        'OGO` = :`ODONTOLOGO`'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`Old_LINEA_LINEA`')
    SQLLock.Strings = (
      'SELECT * FROM fza_FACTURAS_LINEAS'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`Old_LINEA_LINEA`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `SERIE_FAC_FACLIN`, `NUMERO_FAC_FACLIN`, `LINEA_LINEA`, `CODIGO_ARTICULO_LINEA`, `DESCRIPCION_ARTICULO_LINEA`, `ZONA`, `PRECIOVENTA_ARTICULO_LINEA`, `CANTIDAD_LINEA`, `SUM_TOTAL_LINEA`, `ODONTO' +
        'LOGO` FROM `fza_FACTURAS_LINEAS`'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`SERIE_FAC_FACLIN` AND `NUMERO_FAC_FACLIN` = :`NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`LINEA_LINEA`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_FACTURAS_LINEAS')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      ' FROM vi_FACTURAS_LINEAS_print'
      'WHERE NUMERO_FAC_FACLIN = :NUMERO_FAC'
      '  AND SERIE_FAC_FACLIN = :SERIE_FAC'
      'ORDER BY LINEA_FACLIN;')
    MasterSource = dsFacPrint
    MasterFields = 'SERIE_FAC;NUMERO_FAC'
    DetailFields = 'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN'
    Active = True
    Left = 574
    Top = 506
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqrySeries: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT SERIE_CON, DEFAULT_CON'
      'FROM fza_CONTADORES'
      'WHERE TIPO_DOC_CON='#39'FC'#39' AND ESACTIVO_CON = '#39'S'#39
      'ORDER BY DEFAULT_CON DESC')
    Left = 435
    Top = 115
  end
  object unqryCliDataFac: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_clientes'
      
        '  (CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACIONES_CLI, REFE' +
        'RENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TELEFONO_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI, INSTANTE_MODIF, ' +
        'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_CLI_CLI, :ESACTIVO_CLI, :RAZON_SOCIAL_CLI, :NIF_CLI, :MOVIL_CLI, :EMAIL_CLI, :DIRECCION1_CLI, :DIRECCION2_CLI, :POBLACION_CLI, :PROVINCIA_CLI, :CODIGO_POSTAL_CLI, :PAIS_CLIENTE, :OBSERVACIO' +
        'NES_CLI, :REFERENCIA_CLI, :CONTACTO_CLI, :TELEFONO_CONTACTO_CLI, :TELEFONO_CLI, :IBAN_CLI, :IVA_RECARGO_CLIENTE, :RETENCIONES_CLIENTE, :CODIGO_FORMA_PAGO, :CODIGO_ZONA_IVA_CLIENTE, :TEXTO_LEGAL_FACTUR' +
        'A_CLI, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLUpdate.Strings = (
      'UPDATE fza_clientes'
      'SET'
      
        '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI, ESACTIVO_CLI = :ESACTIVO_CLI, RAZON_SOCIAL_CLI = :RAZON_SOCIAL_CLI, NIF_CLI = :NIF_CLI, MOVIL_CLI = :MOVIL_CLI, EMAIL_CLI = :EMAIL_CLI, DIRECCION1_CLI = :DIRECCION1' +
        '_CLI, DIRECCION2_CLI = :DIRECCION2_CLI, POBLACION_CLI = :POBLACION_CLI, PROVINCIA_CLI = :PROVINCIA_CLI, CODIGO_POSTAL_CLI = :CODIGO_POSTAL_CLI, PAIS_CLIENTE = :PAIS_CLIENTE, OBSERVACIONES_CLI = :OBSER' +
        'VACIONES_CLI, REFERENCIA_CLI = :REFERENCIA_CLI, CONTACTO_CLI = :CONTACTO_CLI, TELEFONO_CONTACTO_CLI = :TELEFONO_CONTACTO_CLI, TELEFONO_CLI = :TELEFONO_CLI, IBAN_CLI = :IBAN_CLI, IVA_RECARGO_CLIENTE = ' +
        ':IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE = :RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO = :CODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE = :CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI = :TEXTO_LEGAL_FAC' +
        'TURA_CLI, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLLock.Strings = (
      'SELECT * FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACIONES_CLI, ' +
        'REFERENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TELEFONO_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI, INSTANTE_MOD' +
        'IF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_clientes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_cli_busquedas')
    Left = 22
    Top = 429
  end
  object unqryArtDataLinFac: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * '
      '  from vi_art_busquedas'
      ' where (codigo_tar_arttar = :tarifa'
      '    or codigo_tar_arttar is null)'
      '   AND FECHA_DESDE_ARTTAR < :FECHA_FAC'
      '   AND (FECHA_HASTA_ARTTAR IS NULL'
      '        OR FECHA_HASTA_ARTTAR > :FECHA_FAC)')
    Left = 200
    Top = 429
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'tarifa'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'FECHA_FAC'
        Value = nil
      end>
  end
  object unqryLinFac: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_facturas_lineas`'
      
        '  (`NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`, `LINEA_FACLIN`, `CODIGO_ART_FACLIN`, `CODIGO_FAM_FACLIN`, `NOMBRE_FAM_FACLIN`, `PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PROVEEDOR_FACL' +
        'IN`, `ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_FACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACLIN`, `TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN`, `CODIGO_TAR_FACLIN`,' +
        ' `CANTIDAD_FACLIN`, `PRECIO_SALIDA_FACLIN`, `PORCENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN`, `PRECIO_VENTA_SIVA_ARTICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_ARTICULO_FACLIN`, `TOTAL_FACL' +
        'IN`, `TOTAL_FAC_SIVA_FACLIN`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`NUMERO_FAC_FACLIN`, :`SERIE_FAC_FACLIN`, :`LINEA_FACLIN`, :`CODIGO_ART_FACLIN`, :`CODIGO_FAM_FACLIN`, :`NOMBRE_FAM_FACLIN`, :`PRECIO_ULT_COMPRA_FACLIN`, :`CODIGO_PRV_FACLIN`, :`RAZON_SOCIAL_PROVE' +
        'EDOR_FACLIN`, :`ESPROVEEDORPRINCIPAL_FACLIN`, :`FECHA_ENTREGA_FACLIN`, :`TIPO_CANTIDAD_ARTICULO_FACLIN`, :`ESIMP_INCL_TARIFA_FACLIN`, :`TIPO_IVA_ARTICULO_FACLIN`, :`DESCRIPCION_ARTICULO_FACLIN`, :`COD' +
        'IGO_TAR_FACLIN`, :`CANTIDAD_FACLIN`, :`PRECIO_SALIDA_FACLIN`, :`PORCENTAJE_DTO_FACLIN`, :`PRECIO_DTO_FACLIN`, :`PRECIO_VENTA_SIVA_ARTICULO_FACLIN`, :`PORCENTAJE_IVA_FACLIN`, :`PRECIO_VENTA_CIVA_ARTICU' +
        'LO_FACLIN`, :`TOTAL_FACLIN`, :`TOTAL_FAC_SIVA_FACLIN`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_facturas_lineas`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`Old_LINEA_FACLIN`')
    SQLUpdate.Strings = (
      'UPDATE `fza_facturas_lineas`'
      'SET'
      
        '  `NUMERO_FAC_FACLIN` = :`NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN` = :`SERIE_FAC_FACLIN`, `LINEA_FACLIN` = :`LINEA_FACLIN`, `CODIGO_ART_FACLIN` = :`CODIGO_ART_FACLIN`, `CODIGO_FAM_FACLIN` = :`CODIGO_FAM' +
        '_FACLIN`, `NOMBRE_FAM_FACLIN` = :`NOMBRE_FAM_FACLIN`, `PRECIO_ULT_COMPRA_FACLIN` = :`PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN` = :`CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PROVEEDOR_FACLIN` = :`RAZON_SO' +
        'CIAL_PROVEEDOR_FACLIN`, `ESPROVEEDORPRINCIPAL_FACLIN` = :`ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_FACLIN` = :`FECHA_ENTREGA_FACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN` = :`TIPO_CANTIDAD_ARTICULO_FAC' +
        'LIN`, `ESIMP_INCL_TARIFA_FACLIN` = :`ESIMP_INCL_TARIFA_FACLIN`, `TIPO_IVA_ARTICULO_FACLIN` = :`TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN` = :`DESCRIPCION_ARTICULO_FACLIN`, `CODIGO_TAR_FA' +
        'CLIN` = :`CODIGO_TAR_FACLIN`, `CANTIDAD_FACLIN` = :`CANTIDAD_FACLIN`, `PRECIO_SALIDA_FACLIN` = :`PRECIO_SALIDA_FACLIN`, `PORCENTAJE_DTO_FACLIN` = :`PORCENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN` = :`PREC' +
        'IO_DTO_FACLIN`, `PRECIO_VENTA_SIVA_ARTICULO_FACLIN` = :`PRECIO_VENTA_SIVA_ARTICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN` = :`PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_ARTICULO_FACLIN` = :`PRECIO_VENTA_CIV' +
        'A_ARTICULO_FACLIN`, `TOTAL_FACLIN` = :`TOTAL_FACLIN`, `TOTAL_FAC_SIVA_FACLIN` = :`TOTAL_FAC_SIVA_FACLIN`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`U' +
        'SUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`Old_LINEA_FACLIN`')
    SQLLock.Strings = (
      
        'SELECT `NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`, `LINEA_FACLIN`, `CODIGO_ART_FACLIN`, `CODIGO_FAM_FACLIN`, `NOMBRE_FAM_FACLIN`, `PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PROVEEDOR_' +
        'FACLIN`, `ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_FACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACLIN`, `TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN`, `CODIGO_TAR_FACL' +
        'IN`, `CANTIDAD_FACLIN`, `PRECIO_SALIDA_FACLIN`, `PORCENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN`, `PRECIO_VENTA_SIVA_ARTICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_ARTICULO_FACLIN`, `TOTAL_' +
        'FACLIN`, `TOTAL_FAC_SIVA_FACLIN`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FROM `fza_facturas_lineas`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`Old_LINEA_FACLIN`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`, `LINEA_FACLIN`, `CODIGO_ART_FACLIN`, `CODIGO_FAM_FACLIN`, `NOMBRE_FAM_FACLIN`, `PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PROVEEDOR_' +
        'FACLIN`, `ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_FACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACLIN`, `TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN`, `CODIGO_TAR_FACL' +
        'IN`, `CANTIDAD_FACLIN`, `PRECIO_SALIDA_FACLIN`, `PORCENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN`, `PRECIO_VENTA_SIVA_ARTICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_ARTICULO_FACLIN`, `TOTAL_' +
        'FACLIN`, `TOTAL_FAC_SIVA_FACLIN`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FROM `fza_facturas_lineas`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`NUMERO_FAC_FACLIN` AND `SERIE_FAC_FACLIN` = :`SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`LINEA_FACLIN`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas_lineas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_FACTURAS_LINEAS'
      'where NUMERO_FAC_FACLIN = :NUMERO_FAC'
      'AND SERIE_FAC_FACLIN = :SERIE_FAC'
      
        'order by NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN ASC')
    MasterSource = dsFactura
    MasterFields = 'SERIE_FAC;NUMERO_FAC'
    DetailFields = 'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN'
    BeforeInsert = unqryLinFacBeforeInsert
    AfterInsert = unqryLinFacAfterInsert
    BeforeEdit = unqryLinFacBeforeEdit
    BeforePost = unqryLinFacBeforePost
    AfterPost = unqryLinFacAfterPost
    AfterDelete = unqryLinFacAfterDelete
    Left = 134
    Top = 109
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unstrdprcCrearFacturaAbono: TUniStoredProc
    StoredProcName = 'PRC_CREAR_FACTURA_ABONO'
    SQL.Strings = (
      
        'CALL PRC_CREAR_FACTURA_ABONO(:pidseriefactura, :pidnumfactura, :pidseriefacturaabono, :pidcodigo_empresa, :pfechafacturaabono, @pidnumfacturaabono, :pUSUARIO); SELECT @pidnumfacturaabono AS '#39'@pidnumfacturaabono'#39)
    Connection = dmConn.conUni
    Left = 958
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pidseriefactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidseriefacturaabono'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidcodigo_empresa'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftDate
        Name = 'pfechafacturaabono'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfacturaabono'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_FACTURA_ABONO'
  end
  object unstrdprcDuplicarFactura: TUniStoredProc
    StoredProcName = 'PRC_CREAR_FACTURA_DUPLICADA'
    SQL.Strings = (
      
        'CALL PRC_CREAR_FACTURA_DUPLICADA(:pidseriefactura, :pidnumfactura, :pidseriefacturaabono, :pidcodigo_empresa, :pfechafacturaabono, :pUSUARIO, @pidnumfacturaabono); SELECT @pidnumfacturaabono AS '#39'@pidnumfacturaabono'#39)
    Connection = dmConn.conUni
    Left = 838
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pidseriefactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidseriefacturaabono'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidcodigo_empresa'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftDate
        Name = 'pfechafacturaabono'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfacturaabono'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_FACTURA_DUPLICADA'
  end
  object unstrdprcCrearCliente: TUniStoredProc
    StoredProcName = 'PRC_CREAR_ACTUALIZAR_CLIENTE'
    SQL.Strings = (
      
        'CALL PRC_CREAR_ACTUALIZAR_CLIENTE(:pCODIGO_CLIENTE, :pRAZONSOCIAL_CLIENTE, :pNIF_CLIENTE, :pMOVIL_CLIENTE, :pEMAIL_CLIENTE, :pDIRECCION1_CLIENTE, :pDIRECCION2_CLIENTE, :pPOBLACION_CLIENTE, :pPROVINCIA' +
        '_CLIENTE, :pCPOSTAL_CLIENTE, :pCOD_PAIS_CLIENTE, :pPAIS_CLIENTE, :pESIVA_EXENTO_CLIENTE, :pESRETENCIONES_CLIENTE, :pESIVA_RECARGO_CLIENTE, :pESINTRACOMUNITARIO_CLIENTE, :pESREGIMENESPECIALAGRICOLA_CLI' +
        'ENTE, :pTARIFA_ARTICULO_CLIENTE, :pUSUARIO)')
    Connection = dmConn.conUni
    Left = 237
    Top = 211
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pCODIGO_CLIENTE'
        ParamType = ptInput
        Size = 20
        Value = ''
      end
      item
        DataType = ftWideString
        Name = 'pRAZONSOCIAL_CLIENTE'
        ParamType = ptInput
        Size = 200
        Value = ''
      end
      item
        DataType = ftWideString
        Name = 'pNIF_CLIENTE'
        ParamType = ptInput
        Size = 50
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pMOVIL_CLIENTE'
        ParamType = ptInput
        Size = 40
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pEMAIL_CLIENTE'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION1_CLIENTE'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION2_CLIENTE'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPOBLACION_CLIENTE'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPROVINCIA_CLIENTE'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCPOSTAL_CLIENTE'
        ParamType = ptInput
        Size = 15
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCOD_PAIS_CLIENTE'
        ParamType = ptInput
        Size = 3
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPAIS_CLIENTE'
        ParamType = ptInput
        Size = 150
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESIVA_EXENTO_CLIENTE'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESRETENCIONES_CLIENTE'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESIVA_RECARGO_CLIENTE'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESINTRACOMUNITARIO_CLIENTE'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESREGIMENESPECIALAGRICOLA_CLIENTE'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTARIFA_ARTICULO_CLIENTE'
        ParamType = ptInput
        Size = 20
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = ''
      end>
    CommandStoredProcName = 'PRC_CREAR_ACTUALIZAR_CLIENTE'
  end
  object unstrdprcGetDataArticulo: TUniStoredProc
    StoredProcName = 'PRC_GET_DATA_ARTICULO'
    SQL.Strings = (
      
        'CALL PRC_GET_DATA_ARTICULO(:pidcodarticulo, @pidnomarticulo, @ptipoiva); SELECT @pidnomarticulo AS '#39'@pidnomarticulo'#39', @ptipoiva AS '#39'@ptipoiva'#39)
    Connection = dmConn.conUni
    Left = 422
    Top = 218
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pidcodarticulo'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnomarticulo'
        ParamType = ptOutput
        Size = 1000
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'ptipoiva'
        ParamType = ptOutput
        Size = 2
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_DATA_ARTICULO'
  end
  object unstrdprcGetDataCliente: TUniStoredProc
    StoredProcName = 'PRC_GET_DATA_CLIENTE'
    SQL.Strings = (
      
        'CALL PRC_GET_DATA_CLIENTE(:pCODIGO_CLIENTE, @pRAZONSOCIAL_CLIENTE, @pNIF_CLIENTE, @pCODIGO_ZONA_IVA_CLIENTE, @pMOVIL_CLIENTE, @pESIVA_RECARGO_CLIENTE, @pESRETENCIONES_CLIENTE, @pESIVA_EXENTO_CLIENTE, ' +
        '@pESINTRACOMUNITARIO_CLIENTE, @pESREGIMENESPECIALAGRICOLA_CLIENTE, @pEMAIL_CLIENTE, @pDIRECCION1_CLIENTE, @pDIRECCION2_CLIENTE, @pPOBLACION_CLIENTE, @pPROVINCIA_CLIENTE, @pCPOSTAL_CLIENTE, @pTARIFA_AR' +
        'TICULO_CLIENTE, @pTEXTO_LEGAL_FACTURA_CLIENTE, @pPAIS_CLIENTE, @pCOD_PAIS_CLIENTE); SELECT @pRAZONSOCIAL_CLIENTE AS '#39'@pRAZONSOCIAL_CLIENTE'#39', @pNIF_CLIENTE AS '#39'@pNIF_CLIENTE'#39', CAST(@pCO' +
        'DIGO_ZONA_IVA_CLIENTE AS SIGNED) AS '#39'@pCODIGO_ZONA_IVA_CLIENTE'#39', @pMOVIL_CLIENTE AS '#39'@pMOVIL_CLIENTE'#39', @pESIVA_RECARGO_CLIENTE AS '#39'@pESIVA_RECARGO_CLIENTE'#39', @pESRETENCIONES_CLI' +
        'ENTE AS ' +
        #39'@pESRETENCIONES_CLIENTE'#39', @pESIVA_EXENTO_CLIENTE AS '#39'@pESIVA_EXENTO_CLIENTE'#39', @pESINTRACOMUNITARIO_CLIENTE AS '#39'@pESINTRACOMUNITARIO_CLIENTE'#39', @pESREGIMENESPECIALAGRICOLA_CLIENTE AS '#39'@pESREGIMENESPECIALAGRICOLA_CLIENTE'#39', @pEMAIL_CLIENTE AS '#39'@pEMAIL_CLIENTE' +
        #39', @pDIRECCION1_CLIENTE AS '#39'@pDIRECCION1_CLIENTE'#39', @pDIRECCION2_CLIENTE AS '#39'@pDIRECCION2_CLIENTE'#39', @pPOBLACION_CLIENTE AS '#39'@pPOBLACION_CLIENTE'#39', @pPROVINCIA_CLIENTE AS '#39'@pPROVINCIA_CLIENTE'#39', @pCPOSTAL_CLIENTE AS '#39'@pCPOSTAL_CLIENTE'#39', @pTARIFA_ARTICULO_CLIENTE AS '#39'@pTARIFA_ARTICULO_CLIENTE'#39', @pTEXTO_LEGAL_FACTURA_CLIENTE AS '#39'@pTEXTO_LEGAL_FACTURA_CLIENTE'#39', @pPAIS_CLIENTE AS '#39'@pPAIS_CLIENTE'#39', @pCOD_PAIS_CLIENTE AS '#39'@pCOD_PAIS_CLIENTE'#39)
    Connection = dmConn.conUni
    Left = 525
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pCODIGO_CLIENTE'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pRAZONSOCIAL_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pNIF_CLIENTE'
        ParamType = ptOutput
        Size = 50
        Value = nil
      end
      item
        DataType = ftInteger
        Name = 'pCODIGO_ZONA_IVA_CLIENTE'
        ParamType = ptOutput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pMOVIL_CLIENTE'
        ParamType = ptOutput
        Size = 40
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESIVA_RECARGO_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESRETENCIONES_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESIVA_EXENTO_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESINTRACOMUNITARIO_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESREGIMENESPECIALAGRICOLA_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pEMAIL_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION1_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION2_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPOBLACION_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPROVINCIA_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCPOSTAL_CLIENTE'
        ParamType = ptOutput
        Size = 15
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTARIFA_ARTICULO_CLIENTE'
        ParamType = ptOutput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTEXTO_LEGAL_FACTURA_CLIENTE'
        ParamType = ptOutput
        Size = 1000
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPAIS_CLIENTE'
        ParamType = ptOutput
        Size = 150
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCOD_PAIS_CLIENTE'
        ParamType = ptOutput
        Size = 150
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_DATA_CLIENTE'
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormaPago
    Left = 365
    Top = 64
  end
  object unqryFormaPago: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_formapago'
      
        '  (CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP, DESCRIPCION_FORMA_PAGO_FP, N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESDEFAULT_FORMA_P' +
        'AGO_FP, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_FP_FP, :ESACTIVO_FORMA_PAGO_FP, :ORDEN_FORMA_PAGO_FP, :DESCRIPCION_FORMA_PAGO_FP, :N_PLAZOS_FORMA_PAGO_FP, :N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, :PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, :ESDEFAULT' +
        '_FORMA_PAGO_FP, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_formapago'
      'WHERE'
      '  CODIGO_FP_FP = :Old_CODIGO_FP_FP')
    SQLUpdate.Strings = (
      'UPDATE fza_formapago'
      'SET'
      
        '  CODIGO_FP_FP = :CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP = :ESACTIVO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP = :ORDEN_FORMA_PAGO_FP, DESCRIPCION_FORMA_PAGO_FP = :DESCRIPCION_FORMA_PAGO_FP, N_PLAZOS_FORMA_PAG' +
        'O_FP = :N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP = :N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, PORCENTAJE_ANTICIPO_FORMA_PAGO_FP = :PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESDEFAULT_FORMA_PAGO_FP ' +
        '= :ESDEFAULT_FORMA_PAGO_FP, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_FP_FP = :Old_CODIGO_FP_FP')
    SQLLock.Strings = (
      'SELECT * FROM fza_formapago'
      'WHERE'
      '  CODIGO_FP_FP = :Old_CODIGO_FP_FP'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP, DESCRIPCION_FORMA_PAGO_FP, N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESDEFAULT_FOR' +
        'MA_PAGO_FP, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_formapago'
      'WHERE'
      '  CODIGO_FP_FP = :CODIGO_FP_FP')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_formapago')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_formapago'
      '')
    ReadOnly = True
    Left = 371
    Top = 141
  end
  object dsRecibos: TDataSource
    DataSet = unqryRecibos
    Left = 589
    Top = 64
  end
  object unqryRecibos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_recibos`'
      
        '  (`NUMERO_FAC_REC`, `SERIE_FAC_REC`, `NUMERO_PLAZO_REC`, `FORMA_PAGO_ORIGEN_RECIBO_REC`, `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC`, `EUROS_RECIBO_REC`, `ESTADO_RECIBO_REC`, `FECHA_EXPEDICION_RECIBO_' +
        'REC`, `FECHA_VENCIMIENTO_RECIBO_REC`, `IBAN_CLI_REC`, `FECHA_PAGO_RECIBO_REC`, `LOCALIDAD_EXPEDICION_RECIBO_REC`, `CODIGO_CLI_REC`, `RAZON_SOCIAL_CLI_REC`, `DIRECCION1_CLIENTE_RECIBO_REC`, `POBLACION_' +
        'CLI_REC`, `PROVINCIA_CLI_REC`, `CODIGO_POSTAL_CLI_REC`, `IMPORTE_LETRA_RECIBO_REC`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`NUMERO_FAC_REC`, :`SERIE_FAC_REC`, :`NUMERO_PLAZO_REC`, :`FORMA_PAGO_ORIGEN_RECIBO_REC`, :`FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC`, :`EUROS_RECIBO_REC`, :`ESTADO_RECIBO_REC`, :`FECHA_EXPEDICION' +
        '_RECIBO_REC`, :`FECHA_VENCIMIENTO_RECIBO_REC`, :`IBAN_CLI_REC`, :`FECHA_PAGO_RECIBO_REC`, :`LOCALIDAD_EXPEDICION_RECIBO_REC`, :`CODIGO_CLI_REC`, :`RAZON_SOCIAL_CLI_REC`, :`DIRECCION1_CLIENTE_RECIBO_RE' +
        'C`, :`POBLACION_CLI_REC`, :`PROVINCIA_CLI_REC`, :`CODIGO_POSTAL_CLI_REC`, :`IMPORTE_LETRA_RECIBO_REC`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_recibos`'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`Old_NUMERO_FAC_REC` AND `SERIE_FAC_REC` = :`Old_SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`Old_NUMERO_PLAZO_REC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_recibos`'
      'SET'
      
        '  `NUMERO_FAC_REC` = :`NUMERO_FAC_REC`, `SERIE_FAC_REC` = :`SERIE_FAC_REC`, `NUMERO_PLAZO_REC` = :`NUMERO_PLAZO_REC`, `FORMA_PAGO_ORIGEN_RECIBO_REC` = :`FORMA_PAGO_ORIGEN_RECIBO_REC`, `FORMA_PAGO_DESC' +
        'RIPCION_ORIGEN_RECIBO_REC` = :`FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC`, `EUROS_RECIBO_REC` = :`EUROS_RECIBO_REC`, `ESTADO_RECIBO_REC` = :`ESTADO_RECIBO_REC`, `FECHA_EXPEDICION_RECIBO_REC` = :`FECHA_' +
        'EXPEDICION_RECIBO_REC`, `FECHA_VENCIMIENTO_RECIBO_REC` = :`FECHA_VENCIMIENTO_RECIBO_REC`, `IBAN_CLI_REC` = :`IBAN_CLI_REC`, `FECHA_PAGO_RECIBO_REC` = :`FECHA_PAGO_RECIBO_REC`, `LOCALIDAD_EXPEDICION_RE' +
        'CIBO_REC` = :`LOCALIDAD_EXPEDICION_RECIBO_REC`, `CODIGO_CLI_REC` = :`CODIGO_CLI_REC`, `RAZON_SOCIAL_CLI_REC` = :`RAZON_SOCIAL_CLI_REC`, `DIRECCION1_CLIENTE_RECIBO_REC` = :`DIRECCION1_CLIENTE_RECIBO_RE' +
        'C`, `POBLACION_CLI_REC` = :`POBLACION_CLI_REC`, `PROVINCIA_CLI_REC` = :`PROVINCIA_CLI_REC`, `CODIGO_POSTAL_CLI_REC` = :`CODIGO_POSTAL_CLI_REC`, `IMPORTE_LETRA_RECIBO_REC` = :`IMPORTE_LETRA_RECIBO_REC`' +
        ', `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`Old_NUMERO_FAC_REC` AND `SERIE_FAC_REC` = :`Old_SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`Old_NUMERO_PLAZO_REC`')
    SQLLock.Strings = (
      'SELECT * FROM fza_recibos'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`Old_NUMERO_FAC_REC` AND `SERIE_FAC_REC` = :`Old_SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`Old_NUMERO_PLAZO_REC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `NUMERO_FAC_REC`, `SERIE_FAC_REC`, `NUMERO_PLAZO_REC`, `FORMA_PAGO_ORIGEN_RECIBO_REC`, `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC`, `EUROS_RECIBO_REC`, `ESTADO_RECIBO_REC`, `FECHA_EXPEDICION_REC' +
        'IBO_REC`, `FECHA_VENCIMIENTO_RECIBO_REC`, `IBAN_CLI_REC`, `FECHA_PAGO_RECIBO_REC`, `LOCALIDAD_EXPEDICION_RECIBO_REC`, `CODIGO_CLI_REC`, `RAZON_SOCIAL_CLI_REC`, `DIRECCION1_CLIENTE_RECIBO_REC`, `POBLAC' +
        'ION_CLI_REC`, `PROVINCIA_CLI_REC`, `CODIGO_POSTAL_CLI_REC`, `IMPORTE_LETRA_RECIBO_REC`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FROM `fza_recibos`'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`NUMERO_FAC_REC` AND `SERIE_FAC_REC` = :`SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`NUMERO_PLAZO_REC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_recibos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_recibos'
      '')
    MasterSource = dsFactura
    MasterFields = 'NUMERO_FAC;SERIE_FAC'
    DetailFields = 'NUMERO_FAC_REC;SERIE_FAC_REC'
    Left = 589
    Top = 141
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = '00000021'
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = 'A1'
      end>
  end
  object dsRecibosPrint: TDataSource
    DataSet = unqryRecibosPrint
    Left = 701
    Top = 429
  end
  object fxdsRecibos: TfrxDBDataset
    Description = 'Recibos'
    UserName = 'Recibos'
    CloseDataSource = False
    DataSource = dsRecibosPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 701
    Top = 346
    FieldDefs = <
      item
        FieldName = 'NUMERO_FAC_REC'
        FieldAlias = 'NUMERO_FAC_REC'
      end
      item
        FieldName = 'SERIE_FAC_REC'
        FieldAlias = 'SERIE_FAC_REC'
      end
      item
        FieldName = 'NUMERO_PLAZO_REC'
        FieldAlias = 'NUMERO_PLAZO_REC'
      end
      item
        FieldName = 'FORMA_PAGO_ORIGEN_RECIBO_REC'
        FieldAlias = 'FORMA_PAGO_ORIGEN_RECIBO_REC'
      end
      item
        FieldName = 'FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC'
        FieldAlias = 'FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC'
      end
      item
        FieldName = 'EUROS_RECIBO_REC'
        FieldAlias = 'EUROS_RECIBO_REC'
      end
      item
        FieldName = 'ESTADO_RECIBO_REC'
        FieldAlias = 'ESTADO_RECIBO_REC'
      end
      item
        FieldName = 'FECHA_EXPEDICION_RECIBO_REC'
        FieldAlias = 'FECHA_EXPEDICION_RECIBO_REC'
      end
      item
        FieldName = 'FECHA_VENCIMIENTO_RECIBO_REC'
        FieldAlias = 'FECHA_VENCIMIENTO_RECIBO_REC'
      end
      item
        FieldName = 'IBAN_CLI_REC'
        FieldAlias = 'IBAN_CLI_REC'
      end
      item
        FieldName = 'FECHA_PAGO_RECIBO_REC'
        FieldAlias = 'FECHA_PAGO_RECIBO_REC'
      end
      item
        FieldName = 'LOCALIDAD_EXPEDICION_RECIBO_REC'
        FieldAlias = 'LOCALIDAD_EXPEDICION_RECIBO_REC'
      end
      item
        FieldName = 'CODIGO_CLI_REC'
        FieldAlias = 'CODIGO_CLI_REC'
      end
      item
        FieldName = 'RAZON_SOCIAL_CLI_REC'
        FieldAlias = 'RAZON_SOCIAL_CLI_REC'
      end
      item
        FieldName = 'DIRECCION1_CLIENTE_RECIBO_REC'
        FieldAlias = 'DIRECCION1_CLIENTE_RECIBO_REC'
      end
      item
        FieldName = 'POBLACION_CLI_REC'
        FieldAlias = 'POBLACION_CLI_REC'
      end
      item
        FieldName = 'PROVINCIA_CLI_REC'
        FieldAlias = 'PROVINCIA_CLI_REC'
      end
      item
        FieldName = 'CODIGO_POSTAL_CLI_REC'
        FieldAlias = 'CODIGO_POSTAL_CLI_REC'
      end
      item
        FieldName = 'IMPORTE_LETRA_RECIBO_REC'
        FieldAlias = 'IMPORTE_LETRA_RECIBO_REC'
      end
      item
        FieldName = 'INSTANTE_MODIF'
        FieldAlias = 'INSTANTE_MODIF'
      end
      item
        FieldName = 'INSTANTE_ALTA'
        FieldAlias = 'INSTANTE_ALTA'
      end
      item
        FieldName = 'USUARIO_ALTA'
        FieldAlias = 'USUARIO_ALTA'
      end
      item
        FieldName = 'USUARIO_MODIF'
        FieldAlias = 'USUARIO_MODIF'
      end>
  end
  object unqryRecibosPrint: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_recibos'
      
        '  (NUMERO_FAC_REC, SERIE_FAC_REC, NUMERO_PLAZO_REC, FORMA_PAGO_ORIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, EUROS_RECIBO_REC, ESTADO_RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC, FECHA_VENCIMIE' +
        'NTO_RECIBO_REC, IBAN_CLI_REC, FECHA_PAGO_RECIBO_REC, LOCALIDAD_EXPEDICION_RECIBO_REC, CODIGO_CLI_REC, RAZON_SOCIAL_CLI_REC, DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC, PROVINCIA_CLI_REC, CODIGO_' +
        'POSTAL_CLI_REC, IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:NUMERO_FAC_REC, :SERIE_FAC_REC, :NUMERO_PLAZO_REC, :FORMA_PAGO_ORIGEN_RECIBO_REC, :FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, :EUROS_RECIBO_REC, :ESTADO_RECIBO_REC, :FECHA_EXPEDICION_RECIBO_REC, :FECHA' +
        '_VENCIMIENTO_RECIBO_REC, :IBAN_CLI_REC, :FECHA_PAGO_RECIBO_REC, :LOCALIDAD_EXPEDICION_RECIBO_REC, :CODIGO_CLI_REC, :RAZON_SOCIAL_CLI_REC, :DIRECCION1_CLIENTE_RECIBO_REC, :POBLACION_CLI_REC, :PROVINCIA' +
        '_CLI_REC, :CODIGO_POSTAL_CLI_REC, :IMPORTE_LETRA_RECIBO_REC, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_recibos'
      'WHERE'
      
        '  NUMERO_FAC_REC = :Old_NUMERO_FAC_REC AND SERIE_FAC_REC = :Old_SERIE_FAC_REC AND NUMERO_PLAZO_REC = :Old_NUMERO_PLAZO_REC')
    SQLUpdate.Strings = (
      'UPDATE fza_recibos'
      'SET'
      
        '  NUMERO_FAC_REC = :NUMERO_FAC_REC, SERIE_FAC_REC = :SERIE_FAC_REC, NUMERO_PLAZO_REC = :NUMERO_PLAZO_REC, FORMA_PAGO_ORIGEN_RECIBO_REC = :FORMA_PAGO_ORIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_ORIGEN_RE' +
        'CIBO_REC = :FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, EUROS_RECIBO_REC = :EUROS_RECIBO_REC, ESTADO_RECIBO_REC = :ESTADO_RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC = :FECHA_EXPEDICION_RECIBO_REC, FECHA_VENCIMIENT' +
        'O_RECIBO_REC = :FECHA_VENCIMIENTO_RECIBO_REC, IBAN_CLI_REC = :IBAN_CLI_REC, FECHA_PAGO_RECIBO_REC = :FECHA_PAGO_RECIBO_REC, LOCALIDAD_EXPEDICION_RECIBO_REC = :LOCALIDAD_EXPEDICION_RECIBO_REC, CODIGO_C' +
        'LI_REC = :CODIGO_CLI_REC, RAZON_SOCIAL_CLI_REC = :RAZON_SOCIAL_CLI_REC, DIRECCION1_CLIENTE_RECIBO_REC = :DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC = :POBLACION_CLI_REC, PROVINCIA_CLI_REC = :PRO' +
        'VINCIA_CLI_REC, CODIGO_POSTAL_CLI_REC = :CODIGO_POSTAL_CLI_REC, IMPORTE_LETRA_RECIBO_REC = :IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :' +
        'USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      
        '  NUMERO_FAC_REC = :Old_NUMERO_FAC_REC AND SERIE_FAC_REC = :Old_SERIE_FAC_REC AND NUMERO_PLAZO_REC = :Old_NUMERO_PLAZO_REC')
    SQLLock.Strings = (
      'SELECT * FROM fza_recibos'
      'WHERE'
      
        '  NUMERO_FAC_REC = :Old_NUMERO_FAC_REC AND SERIE_FAC_REC = :Old_SERIE_FAC_REC AND NUMERO_PLAZO_REC = :Old_NUMERO_PLAZO_REC'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT NUMERO_FAC_REC, SERIE_FAC_REC, NUMERO_PLAZO_REC, FORMA_PAGO_ORIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, EUROS_RECIBO_REC, ESTADO_RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC, FECHA_VENC' +
        'IMIENTO_RECIBO_REC, IBAN_CLI_REC, FECHA_PAGO_RECIBO_REC, LOCALIDAD_EXPEDICION_RECIBO_REC, CODIGO_CLI_REC, RAZON_SOCIAL_CLI_REC, DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC, PROVINCIA_CLI_REC, COD' +
        'IGO_POSTAL_CLI_REC, IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_recibos'
      'WHERE'
      
        '  NUMERO_FAC_REC = :NUMERO_FAC_REC AND SERIE_FAC_REC = :SERIE_FAC_REC AND NUMERO_PLAZO_REC = :NUMERO_PLAZO_REC')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_recibos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'from vi_recibos'
      '')
    DMLRefresh = True
    Left = 701
    Top = 506
  end
  object unstrdprcGetRecibos: TUniStoredProc
    StoredProcName = 'PRC_CREAR_RECIBOS_FACTURA'
    SQL.Strings = (
      
        'CALL PRC_CREAR_RECIBOS_FACTURA(:pSERIE_FACTURA, :pNRO_FACTURA, :pUSUARIO)')
    Connection = dmConn.conUni
    Left = 1024
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pSERIE_FACTURA'
        ParamType = ptInput
        Size = 12
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pNRO_FACTURA'
        ParamType = ptInput
        Size = 12
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_RECIBOS_FACTURA'
  end
  object unqryIvas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM VI_IVAS'
      '')
    Left = 537
    Top = 115
  end
  object dsIvas: TDataSource
    DataSet = unqryIvas
    Left = 538
    Top = 45
  end
  object unqryEmpDataFac: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_clientes'
      
        '  (CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACIONES_CLI, REFE' +
        'RENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TELEFONO_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI, INSTANTE_MODIF, ' +
        'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_CLI_CLI, :ESACTIVO_CLI, :RAZON_SOCIAL_CLI, :NIF_CLI, :MOVIL_CLI, :EMAIL_CLI, :DIRECCION1_CLI, :DIRECCION2_CLI, :POBLACION_CLI, :PROVINCIA_CLI, :CODIGO_POSTAL_CLI, :PAIS_CLIENTE, :OBSERVACIO' +
        'NES_CLI, :REFERENCIA_CLI, :CONTACTO_CLI, :TELEFONO_CONTACTO_CLI, :TELEFONO_CLI, :IBAN_CLI, :IVA_RECARGO_CLIENTE, :RETENCIONES_CLIENTE, :CODIGO_FORMA_PAGO, :CODIGO_ZONA_IVA_CLIENTE, :TEXTO_LEGAL_FACTUR' +
        'A_CLI, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLUpdate.Strings = (
      'UPDATE fza_clientes'
      'SET'
      
        '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI, ESACTIVO_CLI = :ESACTIVO_CLI, RAZON_SOCIAL_CLI = :RAZON_SOCIAL_CLI, NIF_CLI = :NIF_CLI, MOVIL_CLI = :MOVIL_CLI, EMAIL_CLI = :EMAIL_CLI, DIRECCION1_CLI = :DIRECCION1' +
        '_CLI, DIRECCION2_CLI = :DIRECCION2_CLI, POBLACION_CLI = :POBLACION_CLI, PROVINCIA_CLI = :PROVINCIA_CLI, CODIGO_POSTAL_CLI = :CODIGO_POSTAL_CLI, PAIS_CLIENTE = :PAIS_CLIENTE, OBSERVACIONES_CLI = :OBSER' +
        'VACIONES_CLI, REFERENCIA_CLI = :REFERENCIA_CLI, CONTACTO_CLI = :CONTACTO_CLI, TELEFONO_CONTACTO_CLI = :TELEFONO_CONTACTO_CLI, TELEFONO_CLI = :TELEFONO_CLI, IBAN_CLI = :IBAN_CLI, IVA_RECARGO_CLIENTE = ' +
        ':IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE = :RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO = :CODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE = :CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI = :TEXTO_LEGAL_FAC' +
        'TURA_CLI, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLLock.Strings = (
      'SELECT * FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACIONES_CLI, ' +
        'REFERENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TELEFONO_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI, INSTANTE_MOD' +
        'IF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_clientes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM VI_EMP_BUSQUEDAS')
    Left = 106
    Top = 429
  end
  object unstdCrearEmpresa: TUniStoredProc
    StoredProcName = 'PRC_CREAR_ACTUALIZAR_EMPRESA'
    SQL.Strings = (
      
        'CALL PRC_CREAR_ACTUALIZAR_EMPRESA(:pCODIGO_EMPRESA, :pRAZONSOCIAL_EMPRESA, :pNIF_EMPRESA, :pMOVIL_EMPRESA, :pEMAIL_EMPRESA, :pDIRECCION1_EMPRESA, :pDIRECCION2_EMPRESA, :pPOBLACION_EMPRESA, :pPROVINCIA' +
        '_EMPRESA, :pCPOSTAL_EMPRESA, :pPAIS_EMPRESA, :pCODPAIS_EMPRESA, :pRETENCIONES_EMPRESA, :pIVA_RECARGO_EMPRESA, :pREGIMENESPECIALAGRICOLA_EMPRESA, :pGRUPO_ZONA_IVA_EMPRESA, :pUSUARIO)')
    Connection = dmConn.conUni
    Left = 333
    Top = 256
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pCODIGO_EMPRESA'
        ParamType = ptInput
        Size = 10
        Value = ''
      end
      item
        DataType = ftWideString
        Name = 'pRAZONSOCIAL_EMPRESA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pNIF_EMPRESA'
        ParamType = ptInput
        Size = 50
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pMOVIL_EMPRESA'
        ParamType = ptInput
        Size = 40
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pEMAIL_EMPRESA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION1_EMPRESA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION2_EMPRESA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPOBLACION_EMPRESA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPROVINCIA_EMPRESA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCPOSTAL_EMPRESA'
        ParamType = ptInput
        Size = 15
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPAIS_EMPRESA'
        ParamType = ptInput
        Size = 150
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCODPAIS_EMPRESA'
        ParamType = ptInput
        Size = 150
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pRETENCIONES_EMPRESA'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pIVA_RECARGO_EMPRESA'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pREGIMENESPECIALAGRICOLA_EMPRESA'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pGRUPO_ZONA_IVA_EMPRESA'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = ''
      end>
    CommandStoredProcName = 'PRC_CREAR_ACTUALIZAR_EMPRESA'
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 486
    Top = 64
  end
  object unqryTarifas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_tarifas'
      '')
    Left = 486
    Top = 141
  end
  object unstdGetContadorLinea: TUniStoredProc
    StoredProcName = 'PRC_FNC_GET_NEXT_LINEA_FACTURA'
    SQL.Strings = (
      
        'CALL PRC_FNC_GET_NEXT_LINEA_FACTURA(:pnumfac, :pserie, @presul); SELECT @presul AS '#39'@presul'#39)
    Connection = dmConn.conUni
    Left = 627
    Top = 269
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pnumfac'
        ParamType = ptInput
        Size = 8
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pserie'
        ParamType = ptInput
        Size = 8
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'presul'
        ParamType = ptOutput
        Size = 3
        Value = '010'
      end>
    CommandStoredProcName = 'PRC_FNC_GET_NEXT_LINEA_FACTURA'
  end
  object unstdCalcularFactura: TUniStoredProc
    StoredProcName = 'PRC_CALCULAR_FACTURA_NETOS'
    SQL.Strings = (
      'CALL PRC_CALCULAR_FACTURA_NETOS(:pSERIE_FACTURA, :pNRO_FACTURA)')
    Connection = dmConn.conUni
    Left = 736
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pSERIE_FACTURA'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftInteger
        Name = 'pNRO_FACTURA'
        ParamType = ptInput
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CALCULAR_FACTURA_NETOS'
  end
  object dsSeriesEditCombo: TDataSource
    DataSet = unqrySeriesEditCombo
    Left = 678
    Top = 45
  end
  object unqrySeriesEditCombo: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      '')
    Left = 678
    Top = 115
  end
  object unstrdprcGetContadorFactura: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT_FACT_SERIE(:pserie, :pTipoDoc, :pEMPRESA_CONTADOR, :pUSUARIOMODIF, @pcont); SELECT @pcont AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 45
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pserie'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pEMPRESA_CONTADOR'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIOMODIF'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pcont'
        ParamType = ptOutput
        Size = 12
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
  end
  object unqryIvasTipos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM FZA_IVAS_TIPOS'
      '')
    Left = 767
    Top = 141
  end
  object dsIvasTipos: TDataSource
    DataSet = unqryIvasTipos
    Left = 768
    Top = 64
  end
  object dsFactura: TDataSource
    DataSet = unqryTablaG
    Left = 294
    Top = 352
  end
  object unstdCrearArticuloLin: TUniStoredProc
    StoredProcName = 'PRC_CREAR_ACTUALIZAR_ARTICULO'
    SQL.Strings = (
      
        'CALL PRC_CREAR_ACTUALIZAR_ARTICULO(:pCODIGO_ARTICULO, :pDESCRIPCION_ARTICULO, :pTIPOIVA_ARTICULO, :pTIPO_CANTIDAD_ARTICULO, :pESACTIVO_FIJO_ARTICULO, :pCODIGO_FAMILIA, :pNOMBRE_FAMILIA, :pCODIGO_PROVE' +
        'EDOR, :pRAZONSOCIAL_PROVEEDOR, :pESPROVEEDORPRINCIPAL, :pPRECIO_ULT_COMPRA, :pCODIGO_TARIFA, :pPRECIOSALIDA_TARIFA, :pPRECIOFINAL_TARIFA, :pPRECIO_DTO_TARIFA, :pPORCEN_DTO_TARIFA, :pUSUARIO)')
    Connection = dmConn.conUni
    Left = 1088
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pCODIGO_ARTICULO'
        ParamType = ptInput
        Size = 20
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDESCRIPCION_ARTICULO'
        ParamType = ptInput
        Size = 1000
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTIPOIVA_ARTICULO'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTIPO_CANTIDAD_ARTICULO'
        ParamType = ptInput
        Size = 20
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESACTIVO_FIJO_ARTICULO'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCODIGO_FAMILIA'
        ParamType = ptInput
        Size = 20
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pNOMBRE_FAMILIA'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCODIGO_PROVEEDOR'
        ParamType = ptInput
        Size = 20
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pRAZONSOCIAL_PROVEEDOR'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESPROVEEDORPRINCIPAL'
        ParamType = ptInput
        Size = 1
        Value = nil
      end
      item
        DataType = ftFloat
        Name = 'pPRECIO_ULT_COMPRA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCODIGO_TARIFA'
        ParamType = ptInput
        Size = 20
        Value = nil
      end
      item
        DataType = ftFloat
        Name = 'pPRECIOSALIDA_TARIFA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftFloat
        Name = 'pPRECIOFINAL_TARIFA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftFloat
        Name = 'pPRECIO_DTO_TARIFA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftFloat
        Name = 'pPORCEN_DTO_TARIFA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_ACTUALIZAR_ARTICULO'
  end
  object dsPaisesCli: TDataSource
    DataSet = unqryPaisesCli
    Left = 838
    Top = 51
  end
  object unqryPaisesCli: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LINEA_LINEA, ODONTOLOGO, SERIE_FAC)'
      'VALUES'
      
        '  (:ID, :CODIGO_ART_ART, :DESCRIPCION_ART, :CODIGO_CLI_CLI, :PRECIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :NUMERO_FAC, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FAC)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ART_ART = :CODIGO_ART_ART, DESCRIPCION_ART = :DESCRIPCION_ART, CODIGO_CLI_CLI = :CODIGO_CLI_CLI, PRECIOVENTA_ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZONA = :ZONA, DESCRIPC' +
        'ION_HISTORIA = :DESCRIPCION_HISTORIA, NUMERO_FAC = :NUMERO_FAC, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :ODONTOLOGO, SERIE_FAC = :SERIE_FAC'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LINEA_LINEA, ODONTOLOGO, SERIE_FAC FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_paises'
      '')
    ReadOnly = True
    Left = 838
    Top = 115
  end
  object unqryPaisesEmp: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LINEA_LINEA, ODONTOLOGO, SERIE_FAC)'
      'VALUES'
      
        '  (:ID, :CODIGO_ART_ART, :DESCRIPCION_ART, :CODIGO_CLI_CLI, :PRECIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :NUMERO_FAC, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FAC)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ART_ART = :CODIGO_ART_ART, DESCRIPCION_ART = :DESCRIPCION_ART, CODIGO_CLI_CLI = :CODIGO_CLI_CLI, PRECIOVENTA_ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZONA = :ZONA, DESCRIPC' +
        'ION_HISTORIA = :DESCRIPCION_HISTORIA, NUMERO_FAC = :NUMERO_FAC, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :ODONTOLOGO, SERIE_FAC = :SERIE_FAC'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LINEA_LINEA, ODONTOLOGO, SERIE_FAC FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_paises'
      '')
    ReadOnly = True
    Left = 896
    Top = 154
  end
  object dsPaisesEmp: TDataSource
    DataSet = unqryPaisesEmp
    Left = 896
    Top = 64
  end
  object dsConsolidacion: TDataSource
    DataSet = unqryConsolidacion
    Left = 1045
    Top = 54
  end
  object unqryConsolidacion: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_facturas_consolidaciones'
      
        '  (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, REQUEST_ID_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, CHAIN' +
        '_NUMBER_FACCON, CHAIN_HASH_FACCON, VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON)'
      'VALUES'
      
        '  (:ID_FACCON, :SERIE_FAC_FACCON, :NUMERO_FAC_FACCON, :REQUEST_ID_CONSOLIDACION_FACCON, :QUEUE_ID_CONSOLIDACION_FACCON, :QUEUE_ID_CANCEL_FACCON, :ISSUER_IRS_ID_CONSOLIDACION_FACCON, :ISSUED_TIME_FACCO' +
        'N, :CHAIN_NUMBER_FACCON, :CHAIN_HASH_FACCON, :VERIFACTU_URL_FACCON, :QRCODE_BASE64_FACCON, :QRCODE_PNG_FACCON, :FECHA_PROCESAMIENTO_FACCON, :ESTADO_FACCON, :RESPUESTA_COMPLETA_FACCON, :PETICION_COMPLE' +
        'TA_FACCON)')
    SQLDelete.Strings = (
      'DELETE FROM fza_facturas_consolidaciones'
      'WHERE'
      '  ID_FACCON = :Old_ID_FACCON')
    SQLUpdate.Strings = (
      'UPDATE fza_facturas_consolidaciones'
      'SET'
      
        '  ID_FACCON = :ID_FACCON, SERIE_FAC_FACCON = :SERIE_FAC_FACCON, NUMERO_FAC_FACCON = :NUMERO_FAC_FACCON, REQUEST_ID_CONSOLIDACION_FACCON = :REQUEST_ID_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCO' +
        'N = :QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_CANCEL_FACCON = :QUEUE_ID_CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON = :ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON = :ISSUED_TIME_FACCON' +
        ', CHAIN_NUMBER_FACCON = :CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON = :CHAIN_HASH_FACCON, VERIFACTU_URL_FACCON = :VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON = :QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON = :Q' +
        'RCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FACCON = :FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON = :ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON = :RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON = :PETICION' +
        '_COMPLETA_FACCON'
      'WHERE'
      '  ID_FACCON = :Old_ID_FACCON')
    SQLLock.Strings = (
      
        'SELECT ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, REQUEST_ID_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, C' +
        'HAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON FRO' +
        'M fza_facturas_consolidaciones'
      'WHERE'
      '  ID_FACCON = :Old_ID_FACCON'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, REQUEST_ID_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, C' +
        'HAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON FRO' +
        'M fza_facturas_consolidaciones'
      'WHERE'
      '  ID_FACCON = :ID_FACCON')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas_consolidaciones')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_facturas_consolidaciones'
      'WHERE NUMERO_FAC_FACCON = :NUMERO_FAC'
      'AND SERIE_FAC_FACCON = :SERIE_FAC'
      'ORDER BY ID_FACCON DESC')
    MasterSource = frmMtoFacturas.dsTablaG
    MasterFields = 'SERIE_FAC;NUMERO_FAC'
    DetailFields = 'ID_FACCON;NUMERO_FAC_FACCON'
    ReadOnly = True
    Left = 1045
    Top = 131
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = '000001'
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = 'A0'
      end>
  end
  object dsErrores: TDataSource
    DataSet = unqryErrores
    Left = 1155
    Top = 56
  end
  object unqryErrores: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'FROM fza_verifactu_eventos'
      'order by id_log desc')
    MasterSource = frmMtoFacturas.dsTablaG
    MasterFields = 'NUMERO_FAC;SERIE_FAC'
    DetailFields = 'NUMERO_FAC_LOG;SERIE_FAC_LOG'
    ReadOnly = True
    AutoCalcFields = False
    Left = 1155
    Top = 126
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
end
