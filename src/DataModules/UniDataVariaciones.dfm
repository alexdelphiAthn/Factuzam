inherited dmVariaciones: TdmVariaciones
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_variaciones`'
      
        '  (`CODIGO_VAR`, `NOMBRE_VAR`, `ESACTIVO_VAR`, `ORDEN_VAR`, `INS' +
        'TANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`, `USUARIOMODIF`)'
      'VALUES'
      
        '  (:`CODIGO_VAR`, :`NOMBRE_VAR`, :`ESACTIVO_VAR`, :`ORDEN_VAR`, ' +
        ':`INSTANTEMODIF`, :`INSTANTEALTA`, :`USUARIOALTA`, :`USUARIOMODI' +
        'F`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`')
    SQLUpdate.Strings = (
      'UPDATE `fza_variaciones`'
      'SET'
      
        '  `CODIGO_VAR` = :`CODIGO_VAR`, `NOMBRE_VAR` = :`NOMBRE_VAR`, `E' +
        'SACTIVO_VAR` = :`ESACTIVO_VAR`, `ORDEN_VAR` = :`ORDEN_VAR`, `INS' +
        'TANTEMODIF` = :`INSTANTEMODIF`, `INSTANTEALTA` = :`INSTANTEALTA`' +
        ', `USUARIOALTA` = :`USUARIOALTA`, `USUARIOMODIF` = :`USUARIOMODI' +
        'F`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`CODIGO_VAR`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_variaciones')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_variaciones'
      'ORDER BY ORDEN_VAR'
      '')
    Active = True
    Left = 24
  end
  object unqryArticulosVariacion: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.ESACTIVO_ART,'
      '       a.CODIGO_FAM_ART, f.NOMBRE_FAM_FAM,'
      '       a.ESVARIACION_ART, a.TIPO_VARIACION_ART,'
      '       a.ORDEN_ART'
      '  FROM fza_articulos a'
      '  LEFT JOIN fza_articulos_familias f'
      '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART'
      ' ORDER BY a.ORDEN_ART, a.CODIGO_ART_ART')
    MasterFields = 'CODIGO_VAR'
    DetailFields = 'TIPO_VARIACION_ART'
    Active = False
    Left = 200
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_VAR'
        ParamType = ptInput
      end>
  end
  object dsArticulosVariacion: TDataSource
    DataSet = unqryArticulosVariacion
    Left = 200
    Top = 80
  end
  object unqryAtributosVariacion: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_variaciones_atributos'
      '  (ID_VAR_VA, ID_ATB_VA, NOMBRE_VA, ORDEN_VA)'
      'VALUES'
      '  (:ID_VAR_VA, :ID_ATB_VA, :NOMBRE_VA, :ORDEN_VA)')
    SQLDelete.Strings = (
      'DELETE FROM fza_variaciones_atributos'
      'WHERE'
      '  ID_VAR_VA = :Old_ID_VAR_VA'
      '  AND ID_ATB_VA = :Old_ID_ATB_VA')
    SQLUpdate.Strings = (
      'UPDATE fza_variaciones_atributos'
      'SET'
      '  ID_VAR_VA = :ID_VAR_VA, ID_ATB_VA = :ID_ATB_VA,'
      '  NOMBRE_VA = :NOMBRE_VA, ORDEN_VA = :ORDEN_VA'
      'WHERE'
      '  ID_VAR_VA = :Old_ID_VAR_VA'
      '  AND ID_ATB_VA = :Old_ID_ATB_VA')
    SQLLock.Strings = (
      'SELECT * FROM fza_variaciones_atributos'
      'WHERE'
      '  ID_VAR_VA = :Old_ID_VAR_VA'
      '  AND ID_ATB_VA = :Old_ID_ATB_VA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM fza_variaciones_atributos'
      'WHERE'
      '  ID_VAR_VA = :ID_VAR_VA'
      '  AND ID_ATB_VA = :ID_ATB_VA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_variaciones_atributos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_VAR_VA, ID_ATB_VA, NOMBRE_VA, ORDEN_VA'
      '  FROM fza_variaciones_atributos'
      ' ORDER BY ORDEN_VA, ID_ATB_VA')
    MasterFields = 'CODIGO_VAR'
    DetailFields = 'ID_VAR_VA'
    Active = False
    AfterInsert = unqryAtributosVariacionAfterInsert
    BeforePost = unqryAtributosVariacionBeforePost
    Left = 24
    Top = 152
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_VAR'
        ParamType = ptInput
      end>
  end
  object dsAtributosVariacion: TDataSource
    DataSet = unqryAtributosVariacion
    Left = 24
    Top = 224
  end
  object unqrySkusArticulo: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIDAD_SKU, CODIGO_ART_SKU,'
      '       CODIGO_VAR_SKU, ESACTIVO_SKU'
      '  FROM fza_articulos_skus'
      ' ORDER BY CODIGO_UNIDAD_SKU')
    MasterSource = dsArticulosVariacion
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_SKU'
    Active = False
    Left = 376
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
      end>
  end
  object dsSkusArticulo: TDataSource
    DataSet = unqrySkusArticulo
    Left = 376
    Top = 80
  end
end
