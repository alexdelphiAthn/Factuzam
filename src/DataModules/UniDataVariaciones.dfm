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
      'SELECT CODIGO_ARTICULO, DESCRIPCION_ARTICULO, ACTIVO_ARTICULO,'
      '       CODIGO_FAMILIA_ARTICULO, NOMBRE_FAMILIA,'
      '       ESVARIACION_ARTICULO, TIPO_VARIACION_ARTICULO,'
      '       ORDEN_ARTICULO, INSTANTEALTA, INSTANTEMODIF,'
      '       USUARIOALTA, USUARIOMODIF'
      '  FROM vi_articulos'
      ' ORDER BY ORDEN_ARTICULO, CODIGO_ARTICULO')
    MasterFields = 'CODIGO_VAR'
    DetailFields = 'TIPO_VARIACION_ARTICULO'
    Left = 200
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_VAR'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsArticulosVariacion: TDataSource
    DataSet = unqryArticulosVariacion
    Left = 200
    Top = 80
  end
end
