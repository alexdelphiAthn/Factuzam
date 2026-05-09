inherited dmAtributosConjuntos: TdmAtributosConjuntos
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_atributos_conjuntos`'
      '  (`NOMBRE_AC`, `ID_VAR_AC`, `ID_VA_AC`, `ESACTIVO_AC`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      '  (:`NOMBRE_AC`, :`ID_VAR_AC`, :`ID_VA_AC`, :`ESACTIVO_AC`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_AC` = :`Old_ID_AC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_atributos_conjuntos`'
      'SET'
      '  `NOMBRE_AC` = :`NOMBRE_AC`, `ID_VAR_AC` = :`ID_VAR_AC`, `ID_VA_AC` = :`ID_VA_AC`, `ESACTIVO_AC` = :`ESACTIVO_AC`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `ID_AC` = :`Old_ID_AC`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_AC` = :`Old_ID_AC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_AC` = :`ID_AC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_conjuntos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_atributos_conjuntos'
      'ORDER BY ID_AC'
      '')
    Active = True
    Left = 24
  end
end
