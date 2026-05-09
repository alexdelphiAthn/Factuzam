inherited dmVariaciones: TdmVariaciones
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_variaciones`'
      
        '  (`CODIGO_VAR`, `NOMBRE_VAR`, `ESACTIVO_VAR`, `ORDEN_VAR`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`CODIGO_VAR`, :`NOMBRE_VAR`, :`ESACTIVO_VAR`, :`ORDEN_VAR`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`')
    SQLUpdate.Strings = (
      'UPDATE `fza_variaciones`'
      'SET'
      
        '  `CODIGO_VAR` = :`CODIGO_VAR`, `NOMBRE_VAR` = :`NOMBRE_VAR`, `ESACTIVO_VAR` = :`ESACTIVO_VAR`, `ORDEN_VAR` = :`ORDEN_VAR`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `U' +
        'SUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
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
      'SELECT CODIGO_ART, DESCRIPCION_ART, ESACTIVO_ART,'
      '       CODIGO_FAM_ART, NOMBRE_FAM,'
      '       ESVARIACION_ART, TIPO_VARIACION_ART,'
      '       ORDEN_ART, INSTANTE_ALTA, INSTANTE_MODIF,'
      '       USUARIO_ALTA, USUARIO_MODIF'
      '  FROM vi_articulos'
      ' ORDER BY ORDEN_ART, CODIGO_ART')
    MasterFields = 'CODIGO_VAR'
    DetailFields = 'TIPO_VARIACION_ART'
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
