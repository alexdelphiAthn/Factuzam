inherited dmArticulosPropiedades: TdmArticulosPropiedades
  OnCreate = DataModuleCreate
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos_propiedades`'
      '  (`CODIGO_ART_ART`, `CODIGO_PROP_ARTPROP`, `ID_PV_ARTPROP`, `VALOR_LIBRE_ARTPROP`, `INSTANTE_ALTA`, `USUARIO_ALTA`)'
      'VALUES'
      '  (:`CODIGO_ART_ART`, :`CODIGO_PROP_ARTPROP`, :`ID_PV_ARTPROP`, :`VALOR_LIBRE_ARTPROP`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_propiedades`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`Old_CODIGO_ART_ART` AND `CODIGO_PROP_ARTPROP` = :`Old_CODIGO_PROP_ARTPROP`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_propiedades`'
      'SET'
      '  `CODIGO_ART_ART` = :`CODIGO_ART_ART`, `CODIGO_PROP_ARTPROP` = :`CODIGO_PROP_ARTPROP`, `ID_PV_ARTPROP` = :`ID_PV_ARTPROP`, `VALOR_LIBRE_ARTPROP` = :`VALOR_LIBRE_ARTPROP`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`Old_CODIGO_ART_ART` AND `CODIGO_PROP_ARTPROP` = :`Old_CODIGO_PROP_ARTPROP`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_articulos_propiedades`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`Old_CODIGO_ART_ART` AND `CODIGO_PROP_ARTPROP` = :`Old_CODIGO_PROP_ARTPROP`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_articulos_propiedades`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`CODIGO_ART_ART` AND `CODIGO_PROP_ARTPROP` = :`CODIGO_PROP_ARTPROP`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_propiedades')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_articulos_propiedades'
      'ORDER BY CODIGO_ART_ART, CODIGO_PROP_ARTPROP'
      '')
    Active = True
    Left = 24
  end
  object unqryPropiedades: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP'
      'FROM fza_propiedades'
      'WHERE ESACTIVO_PROP = '#39'S'#39
      'ORDER BY CODIGO_PROP_ARTPROP')
    Left = 144
    Top = 24
  end
  object dsPropiedades: TDataSource
    DataSet = unqryPropiedades
    Left = 144
    Top = 88
  end
  object unqryValores: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, ID_PROP_PV, PV'
      'FROM fza_propiedades_valores'
      'WHERE ESACTIVO_PV = '#39'S'#39
      'ORDER BY ID_PROP_PV, PV')
    Left = 248
    Top = 24
  end
  object dsValores: TDataSource
    DataSet = unqryValores
    Left = 248
    Top = 88
  end
end
