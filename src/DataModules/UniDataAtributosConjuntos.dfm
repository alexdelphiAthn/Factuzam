inherited dmAtributosConjuntos: TdmAtributosConjuntos
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_atributos_conjuntos`'
      '  (`NOMBRE_AC`, `ID_VARIACION_AC`, `ID_ATRIBUTO_AC`, `ESACTIVO_AC`, `INSTANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`, `USUARIOMODIF`)'
      'VALUES'
      '  (:`NOMBRE_AC`, :`ID_VARIACION_AC`, :`ID_ATRIBUTO_AC`, :`ESACTIVO_AC`, :`INSTANTEMODIF`, :`INSTANTEALTA`, :`USUARIOALTA`, :`USUARIOMODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_CONJUNTO_AC` = :`Old_ID_CONJUNTO_AC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_atributos_conjuntos`'
      'SET'
      '  `NOMBRE_AC` = :`NOMBRE_AC`, `ID_VARIACION_AC` = :`ID_VARIACION_AC`, `ID_ATRIBUTO_AC` = :`ID_ATRIBUTO_AC`, `ESACTIVO_AC` = :`ESACTIVO_AC`, `INSTANTEMODIF` = :`INSTANTEMODIF`, `INSTANTEALTA` = :`INSTANTEALTA`, `USUARIOALTA` = :`USUARIOALTA`, `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      '  `ID_CONJUNTO_AC` = :`Old_ID_CONJUNTO_AC`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_CONJUNTO_AC` = :`Old_ID_CONJUNTO_AC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_CONJUNTO_AC` = :`ID_CONJUNTO_AC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_conjuntos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_atributos_conjuntos'
      'ORDER BY ID_CONJUNTO_AC'
      '')
    Active = True
    Left = 24
  end
end
