inherited dmArticulosPropiedades: TdmArticulosPropiedades
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos_propiedades`'
      '  (`CODIGO_ARTICULO_AP`, `ID_VALOR_AP`, `INSTANTEALTA`, `USUARIOALTA`)'
      'VALUES'
      '  (:`CODIGO_ARTICULO_AP`, :`ID_VALOR_AP`, :`INSTANTEALTA`, :`USUARIOALTA`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_propiedades`'
      'WHERE'
      '  `CODIGO_ARTICULO_AP` = :`Old_CODIGO_ARTICULO_AP` AND `ID_VALOR_AP` = :`Old_ID_VALOR_AP`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_propiedades`'
      'SET'
      '  `CODIGO_ARTICULO_AP` = :`CODIGO_ARTICULO_AP`, `ID_VALOR_AP` = :`ID_VALOR_AP`, `INSTANTEALTA` = :`INSTANTEALTA`, `USUARIOALTA` = :`USUARIOALTA`'
      'WHERE'
      '  `CODIGO_ARTICULO_AP` = :`Old_CODIGO_ARTICULO_AP` AND `ID_VALOR_AP` = :`Old_ID_VALOR_AP`')
    SQLLock.Strings = (
      'SELECT `CODIGO_ARTICULO_AP`, `ID_VALOR_AP`, `INSTANTEALTA`, `USUARIOALTA` FROM `fza_articulos_propiedades`'
      'WHERE'
      '  `CODIGO_ARTICULO_AP` = :`Old_CODIGO_ARTICULO_AP` AND `ID_VALOR_AP` = :`Old_ID_VALOR_AP`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_ARTICULO_AP`, `ID_VALOR_AP`, `INSTANTEALTA`, `USUARIOALTA` FROM `fza_articulos_propiedades`'
      'WHERE'
      '  `CODIGO_ARTICULO_AP` = :`CODIGO_ARTICULO_AP` AND `ID_VALOR_AP` = :`ID_VALOR_AP`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_propiedades')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_articulos_propiedades'
      '')
    Active = True
    Left = 24
  end
end
