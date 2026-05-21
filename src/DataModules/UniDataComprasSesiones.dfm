inherited dmComprasSesiones: TdmComprasSesiones
  Height = 480
  Width = 720
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones'
      'ORDER BY FECHA_SES DESC, NUMERO_SES DESC')
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_USUPER = '#39'dmComprasSesiones'#39
      'OR KEY_USUPER='#39'frmMtoComprasSesiones'#39')')
  end
  object unqrySesionLin: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas'
      'WHERE SERIE_SES_SESLIN = :SERIE_SES'
      '  AND NUMERO_SES_SESLIN = :NUMERO_SES'
      'ORDER BY LINEA_SESLIN')
    MasterFields = 'SERIE_SES;NUMERO_SES'
    DetailFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN'
    AfterInsert = unqrySesionLinAfterInsert
    BeforePost = unqrySesionLinBeforePost
    AfterPost = unqrySesionLinAfterPost
    AfterDelete = unqrySesionLinAfterDelete
    Left = 56
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionLin: TDataSource
    DataSet = unqrySesionLin
    Left = 56
    Top = 72
  end
  object unqrySesionFil: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas_filas'
      'WHERE SERIE_SES_SESFIL = :SERIE_SES_SESLIN'
      '  AND NUMERO_SES_SESFIL = :NUMERO_SES_SESLIN'
      '  AND LINEA_SES_SESFIL = :LINEA_SESLIN'
      'ORDER BY ORDEN_SESFIL, ID_FILA_SESFIL')
    MasterSource = dsSesionLin
    MasterFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN;LINEA_SESLIN'
    DetailFields = 'SERIE_SES_SESFIL;NUMERO_SES_SESFIL;LINEA_SES_SESFIL'
    Left = 152
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsSesionFil: TDataSource
    DataSet = unqrySesionFil
    Left = 152
    Top = 72
  end
  object unqrySesionFilAtr: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas_filas_atr'
      'WHERE SERIE_SES_SESFILAT = :SERIE_SES_SESFIL'
      '  AND NUMERO_SES_SESFILAT = :NUMERO_SES_SESFIL'
      '  AND LINEA_SES_SESFILAT = :LINEA_SES_SESFIL'
      '  AND ID_FILA_SESFILAT = :ID_FILA_SESFIL')
    MasterSource = dsSesionFil
    Left = 248
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESFIL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESFIL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SES_SESFIL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'ID_FILA_SESFIL'
        Value = nil
      end>
  end
  object dsSesionFilAtr: TDataSource
    DataSet = unqrySesionFilAtr
    Left = 248
    Top = 72
  end
  object unqrySesionCel: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_celdas'
      'WHERE SERIE_SES_SESCEL = :SERIE_SES_SESLIN'
      '  AND NUMERO_SES_SESCEL = :NUMERO_SES_SESLIN'
      '  AND LINEA_SES_SESCEL = :LINEA_SESLIN')
    MasterSource = dsSesionLin
    MasterFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN;LINEA_SESLIN'
    DetailFields = 'SERIE_SES_SESCEL;NUMERO_SES_SESCEL;LINEA_SES_SESCEL'
    AfterPost = unqrySesionCelAfterPost
    Left = 344
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsSesionCel: TDataSource
    DataSet = unqrySesionCel
    Left = 344
    Top = 72
  end
  object unqrySesionProps: TUniQuery
    SQL.Strings = (
      'SELECT P.*, PR.NOMBRE_PROP_PROP, PR.TIPO_VALOR_PROP'
      '  FROM fza_compras_sesiones_props P'
      '  LEFT JOIN fza_propiedades PR'
      '    ON PR.CODIGO_PROP_ARTPROP = P.CODIGO_PROP_SESPROP'
      'WHERE P.SERIE_SES_SESPROP = :SERIE_SES'
      '  AND P.NUMERO_SES_SESPROP = :NUMERO_SES'
      'ORDER BY P.ORDEN_SESPROP')
    Left = 440
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionProps: TDataSource
    DataSet = unqrySesionProps
    Left = 440
    Top = 72
  end
  object unqrySesionLinProps: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas_props'
      'WHERE SERIE_SES_SESLPROP = :SERIE_SES_SESLIN'
      '  AND NUMERO_SES_SESLPROP = :NUMERO_SES_SESLIN'
      '  AND LINEA_SES_SESLPROP = :LINEA_SESLIN')
    MasterSource = dsSesionLin
    Left = 536
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsSesionLinProps: TDataSource
    DataSet = unqrySesionLinProps
    Left = 536
    Top = 72
  end
  object unqrySesionKits: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_kits'
      'WHERE SERIE_SES_SESKIT = :SERIE_SES'
      '  AND NUMERO_SES_SESKIT = :NUMERO_SES'
      'ORDER BY ORDEN_SESKIT')
    Left = 56
    Top = 128
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionKits: TDataSource
    DataSet = unqrySesionKits
    Left = 56
    Top = 184
  end
  object unqrySesionKitsDet: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_kits_det'
      'WHERE SERIE_SES_SESKITD = :SERIE_SES_SESKIT'
      '  AND NUMERO_SES_SESKITD = :NUMERO_SES_SESKIT'
      '  AND CODIGO_SESKIT_SESKITD = :CODIGO_SESKIT'
      'ORDER BY ORDEN_SESKITD')
    MasterSource = dsSesionKits
    Left = 152
    Top = 128
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESKIT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESKIT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'CODIGO_SESKIT'
        Value = nil
      end>
  end
  object dsSesionKitsDet: TDataSource
    DataSet = unqrySesionKitsDet
    Left = 152
    Top = 184
  end
  object unqryPreviewSkus: TUniQuery
    SQL.Strings = (
      'SELECT * FROM VI_SES_PREVIEW_SKUS'
      'WHERE SERIE = :SERIE_SES'
      '  AND NUMERO = :NUMERO_SES'
      'ORDER BY CODIGO_ALM, LINEA, ID_FILA, ID_AV_PIVOT')
    Left = 248
    Top = 128
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsPreviewSkus: TDataSource
    DataSet = unqryPreviewSkus
    Left = 248
    Top = 184
  end
  object unqryLineaSkusPrecios: TUniQuery
    SQL.Strings = (
      'SELECT C.ID_FILA_SES_SESCEL                      AS ID_FILA,'
      '       C.ID_AV_PIVOT_SESCEL                      AS ID_AV_PIVOT,'
      '       AVP.AV                                    AS VAL_PIVOT,'
      '       (SELECT GROUP_CONCAT(AV2.AV SEPARATOR '#39'/'#39')'
      '          FROM fza_compras_sesiones_lineas_filas_atr FA'
      
        '          JOIN fza_atributos_valores AV2 ON AV2.ID_AV = FA.ID_AV' +
        '_SESFILAT'
      '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL'
      '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL'
      '           AND FA.LINEA_SES_SESFILAT  = C.LINEA_SES_SESCEL'
      '           AND FA.ID_FILA_SESFILAT    = C.ID_FILA_SES_SESCEL'
      '       )                                         AS VAL_FILA,'
      '       P.PRECIO_COMPRA_SESLINSKU,'
      '       P.PRECIO_VENTA_SESLINSKU'
      '  FROM fza_compras_sesiones_celdas C'
      '  JOIN fza_atributos_valores AVP'
      '    ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL'
      '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P'
      '    ON P.SERIE_SES_SESLINSKU    = C.SERIE_SES_SESCEL'
      '   AND P.NUMERO_SES_SESLINSKU   = C.NUMERO_SES_SESCEL'
      '   AND P.LINEA_SES_SESLINSKU    = C.LINEA_SES_SESCEL'
      '   AND P.ID_FILA_SES_SESLINSKU  = C.ID_FILA_SES_SESCEL'
      '   AND P.ID_AV_PIVOT_SESLINSKU  = C.ID_AV_PIVOT_SESCEL'
      ' WHERE C.SERIE_SES_SESCEL  = :SERIE_SES_SESLIN'
      '   AND C.NUMERO_SES_SESCEL = :NUMERO_SES_SESLIN'
      '   AND C.LINEA_SES_SESCEL  = :LINEA_SESLIN'
      ' GROUP BY C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL'
      ' ORDER BY C.ID_FILA_SES_SESCEL, AVP.AV')
    MasterSource = dsSesionLin
    Left = 632
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsLineaSkusPrecios: TDataSource
    DataSet = unqryLineaSkusPrecios
    Left = 632
    Top = 72
  end
  object unqryResumenAlmacen: TUniQuery
    SQL.Strings = (
      'SELECT R.CODIGO_ALM, A.NOMBRE_ALM_ALM,'
      '       R.NUM_SKUS, R.UNIDADES_TOTAL'
      '  FROM VI_SES_RESUMEN_ALMACEN R'
      '  LEFT JOIN fza_almacenes A'
      '    ON A.CODIGO_ALM_ALM = R.CODIGO_ALM'
      ' WHERE R.SERIE  = :SERIE_SES'
      '   AND R.NUMERO = :NUMERO_SES'
      ' ORDER BY R.CODIGO_ALM')
    Left = 632
    Top = 128
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsResumenAlmacen: TDataSource
    DataSet = unqryResumenAlmacen
    Left = 632
    Top = 184
  end
  object unqryProveedores: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV FROM fza_proveedores'
      'WHERE ESACTIVO_PRV = '#39'S'#39
      'ORDER BY RAZON_SOCIAL_PRV')
    Left = 344
    Top = 128
  end
  object dsProveedores: TDataSource
    DataSet = unqryProveedores
    Left = 344
    Top = 184
  end
  object unqryFamilias: TUniQuery
    SQL.Strings = (
      
        'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM FROM fza_articulos_familia' +
        's'
      'WHERE ESACTIVO_FAM = '#39'S'#39
      'ORDER BY ORDEN_FAM, NOMBRE_FAM_FAM')
    Left = 440
    Top = 128
  end
  object dsFamilias: TDataSource
    DataSet = unqryFamilias
    Left = 440
    Top = 184
  end
  object unqryVariaciones: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_VAR, NOMBRE_VAR FROM fza_variaciones'
      'ORDER BY CODIGO_VAR')
    Left = 536
    Top = 128
  end
  object dsVariaciones: TDataSource
    DataSet = unqryVariaciones
    Left = 536
    Top = 184
  end
  object unqryVariacionesAtributos: TUniQuery
    SQL.Strings = (
      
        'SELECT VA.*, COALESCE(VA.NOMBRE_VISIBLE_VA, VA.NOMBRE_VA) AS LAB' +
        'EL_VA'
      '  FROM fza_variaciones_atributos VA'
      'WHERE VA.ID_VAR_VA = :CODIGO_VAR_SES'
      'ORDER BY VA.ORDEN_VA')
    Left = 56
    Top = 240
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_VAR_SES'
        Value = nil
      end>
  end
  object dsVariacionesAtributos: TDataSource
    DataSet = unqryVariacionesAtributos
    Left = 56
    Top = 296
  end
  object unqryAtributosConjuntos: TUniQuery
    SQL.Strings = (
      'SELECT ID_AC, NOMBRE_AC, ID_VAR_AC, ID_VA_AC'
      '  FROM fza_atributos_conjuntos'
      'WHERE ESACTIVO_AC = '#39'S'#39
      'ORDER BY NOMBRE_AC')
    Left = 152
    Top = 240
  end
  object dsAtributosConjuntos: TDataSource
    DataSet = unqryAtributosConjuntos
    Left = 152
    Top = 296
  end
  object unqryAtributosValores: TUniQuery
    SQL.Strings = (
      'SELECT ID_AV, AV, ID_VA_AV FROM fza_atributos_valores'
      'ORDER BY ID_VA_AV, AV')
    Left = 248
    Top = 240
  end
  object dsAtributosValores: TDataSource
    DataSet = unqryAtributosValores
    Left = 248
    Top = 296
  end
  object unqryPropiedades: TUniQuery
    SQL.Strings = (
      
        'SELECT P.CODIGO_PROP_ARTPROP, P.NOMBRE_PROP_PROP, P.TIPO_VALOR_P' +
        'ROP,'
      '       FA.ESREQUERIDO_FA, FA.ORDEN_MOSTRAR_FA'
      '  FROM fza_familias_atributos FA'
      
        '  JOIN fza_propiedades P ON P.CODIGO_PROP_ARTPROP = FA.CODIGO_PR' +
        'OP_ARTPROP'
      'WHERE FA.CODIGO_FAM_FAM = :CODIGO_FAM_SES'
      'ORDER BY FA.ORDEN_MOSTRAR_FA')
    Left = 344
    Top = 240
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_FAM_SES'
        Value = nil
      end>
  end
  object dsPropiedades: TDataSource
    DataSet = unqryPropiedades
    Left = 344
    Top = 296
  end
  object unqryPropiedadesValores: TUniQuery
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, ID_PROP_PV, PV'
      '  FROM fza_propiedades_valores'
      'ORDER BY ID_PROP_PV, PV')
    Left = 440
    Top = 240
  end
  object dsPropiedadesValores: TDataSource
    DataSet = unqryPropiedadesValores
    Left = 440
    Top = 296
  end
  object unqryIvas: TUniQuery
    SQL.Strings = (
      'SELECT IVA_IVAGRP, DESCRIPCION_IVA_IVAGRP FROM fza_ivas_grupos'
      'ORDER BY IVA_IVAGRP')
    Left = 536
    Top = 240
  end
  object dsIvas: TDataSource
    DataSet = unqryIvas
    Left = 536
    Top = 296
  end
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM FROM fza_almacenes'
      'WHERE ESACTIVO_ALM = '#39'S'#39
      'ORDER BY NOMBRE_ALM_ALM')
    Left = 56
    Top = 352
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 56
    Top = 408
  end
  object unqryTarifas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR FROM vi_tarifas'
      'ORDER BY NOMBRE_TAR_TAR')
    Left = 152
    Top = 352
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 152
    Top = 408
  end
  object unqryEmpresas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP FROM fza_empresas'
      'ORDER BY RAZON_SOCIAL_EMP')
    Left = 248
    Top = 352
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 248
    Top = 408
  end
  object unqryTemporadas: TUniQuery
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, PV'
      '  FROM fza_propiedades_valores'
      ' WHERE ID_PROP_PV = '#39'TEMPORADA'#39
      '   AND ESACTIVO_PV = '#39'S'#39
      ' ORDER BY PV')
    Left = 344
    Top = 352
  end
  object dsTemporadas: TDataSource
    DataSet = unqryTemporadas
    Left = 344
    Top = 408
  end
  object unqryEmpresaSeries: TUniQuery
    SQL.Strings = (
      'SELECT EMPSER, SUBTIPO_EMPSER, CODIGO_ALM_EMPSER'
      '  FROM fza_empresas_series'
      ' WHERE TIPO_DOC_EMPSER = '#39'SE'#39
      '   AND CODIGO_EMP_EMPSER = :CODIGO_EMP_SES'
      '   AND (FECHA_HASTA_EMPSER IS NULL'
      '        OR FECHA_HASTA_EMPSER >= CURDATE())'
      ' ORDER BY EMPSER')
    Left = 712
    Top = 352
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_EMP_SES'
        Value = nil
      end>
  end
  object dsEmpresaSeries: TDataSource
    DataSet = unqryEmpresaSeries
    Left = 712
    Top = 408
  end
  object unqryArticuloExiste: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ART_ART, DESCRIPCION_ART FROM fza_articulos'
      'WHERE CODIGO_ART_ART = :p')
    Left = 344
    Top = 352
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'p'
        Value = nil
      end>
  end
  object unstrdprcGetContadorSesion: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT_FACT_SERIE(:pserie, :pTipoDoc, :pEMPRESA_' +
        'CONTADOR, :pUSUARIOMODIF, @pcont); SELECT @pcont AS '#39'@pcont'#39)
    Left = 440
    Top = 352
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'pserie'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'pTipoDoc'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'pEMPRESA_CONTADOR'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'pUSUARIOMODIF'
        Value = nil
      end>
  end
  object unstrdprcValidarSesion: TUniStoredProc
    StoredProcName = 'PRC_SES_VALIDAR'
    Left = 536
    Top = 352
  end
  object unqryCabSesionPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_compras_sesiones_cab_print'
      'WHERE SERIE_SES = :SERIE_SES'
      '  AND NUMERO_SES = :NUMERO_SES')
    Left = 56
    Top = 392
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsCabSesionPrint: TDataSource
    DataSet = unqryCabSesionPrint
    Left = 56
    Top = 432
  end
  object unqryLinSesionPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_compras_sesiones_lin_print'
      'WHERE SERIE_SES = :SERIE_SES'
      '  AND NUMERO_SES = :NUMERO_SES'
      'ORDER BY LINEA_SES')
    Left = 152
    Top = 392
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsLinSesionPrint: TDataSource
    DataSet = unqryLinSesionPrint
    Left = 152
    Top = 432
  end
  object unqryGuiasSesionPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT'
      '  g.ID_AC,'
      '  g.NOMBRE_CORTO_AC,'
      '  g.NOMBRE_AC,'
      '  g.T01, g.T02, g.T03, g.T04, g.T05,'
      '  g.T06, g.T07, g.T08, g.T09, g.T10,'
      '  g.T11, g.T12, g.T13, g.T14, g.T15,'
      '  g.T16, g.T17, g.T18, g.T19, g.T20'
      'FROM vi_compras_sesiones_guias_print g'
      'WHERE g.ID_AC IN ('
      '  SELECT lin.ID_AC_PIVOT_SESLIN'
      '    FROM fza_compras_sesiones_lineas lin'
      '   WHERE lin.SERIE_SES_SESLIN = :SERIE_SES'
      '     AND lin.NUMERO_SES_SESLIN = :NUMERO_SES'
      '     AND lin.ID_AC_PIVOT_SESLIN IS NOT NULL'
      ')'
      'ORDER BY g.NOMBRE_CORTO_AC, g.ID_AC')
    Left = 248
    Top = 392
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsGuiasSesionPrint: TDataSource
    DataSet = unqryGuiasSesionPrint
    Left = 248
    Top = 432
  end
  object fxdsCabSesion: TfrxDBDataset
    Description = 'Sesiones'
    UserName = 'Sesiones'
    CloseDataSource = False
    DataSource = dsCabSesionPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 344
    Top = 392
  end
  object fxdsLinSesion: TfrxDBDataset
    Description = 'LineasSesiones'
    UserName = 'LineasSesiones'
    CloseDataSource = False
    DataSource = dsLinSesionPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 344
    Top = 432
  end
  object fxdsGuiasSesion: TfrxDBDataset
    Description = 'GuiasTallas'
    UserName = 'GuiasTallas'
    CloseDataSource = False
    DataSource = dsGuiasSesionPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 440
    Top = 392
  end
end
