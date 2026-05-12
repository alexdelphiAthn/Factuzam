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
    BeforePost = unqryTablaGBeforePost
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
    MasterSource = dsTablaG
    MasterFields = 'SERIE_SES;NUMERO_SES'
    DetailFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN'
    AfterInsert = unqrySesionLinAfterInsert
    BeforePost = unqrySesionLinBeforePost
    AfterPost = unqrySesionLinAfterPost
    AfterDelete = unqrySesionLinAfterDelete
    Left = 56
    Top = 16
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
    MasterSource = dsTablaG
    Left = 440
    Top = 16
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
    MasterSource = dsTablaG
    Left = 56
    Top = 128
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
    MasterSource = dsTablaG
    Left = 248
    Top = 128
  end
  object dsPreviewSkus: TDataSource
    DataSet = unqryPreviewSkus
    Left = 248
    Top = 184
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
    MasterSource = dsTablaG
    Left = 632
    Top = 128
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
      'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM FROM fza_articulos_familias'
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
      'SELECT VA.*, COALESCE(VA.NOMBRE_VISIBLE_VA, VA.NOMBRE_VA) AS LABEL_VA'
      '  FROM fza_variaciones_atributos VA'
      'WHERE VA.ID_VAR_VA = :CODIGO_VAR_SES'
      'ORDER BY VA.ORDEN_VA')
    MasterSource = dsTablaG
    Left = 56
    Top = 240
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
      'SELECT P.CODIGO_PROP_ARTPROP, P.NOMBRE_PROP_PROP, P.TIPO_VALOR_PROP,'
      '       FA.ESREQUERIDO_FA, FA.ORDEN_MOSTRAR_FA'
      '  FROM fza_familias_atributos FA'
      '  JOIN fza_propiedades P ON P.CODIGO_PROP_ARTPROP = FA.CODIGO_PROP_ARTPROP'
      'WHERE FA.CODIGO_FAM_FAM = :CODIGO_FAM_SES'
      'ORDER BY FA.ORDEN_MOSTRAR_FA')
    MasterSource = dsTablaG
    Left = 344
    Top = 240
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
  object unqryArticuloExiste: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ART_ART, DESCRIPCION_ART FROM fza_articulos'
      'WHERE CODIGO_ART_ART = :p')
    Left = 344
    Top = 352
  end
  object unstrdprcGetContadorSesion: TUniStoredProc
    StoredProcName = 'PRC_GET_CONTADOR'
    Left = 440
    Top = 352
  end
  object unstrdprcValidarSesion: TUniStoredProc
    StoredProcName = 'PRC_SES_VALIDAR'
    Left = 536
    Top = 352
  end
end
