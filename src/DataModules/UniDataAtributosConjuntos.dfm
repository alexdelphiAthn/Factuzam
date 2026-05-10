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
  object unqryConjuntoDetalle: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_atributos_conjuntos_det`'
      '  (`ID_AC_ACD`, `ID_AV_ACD`, `ORDEN_ACD`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      '  (:`ID_AC_ACD`, :`ID_AV_ACD`, :`ORDEN_ACD`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_atributos_conjuntos_det`'
      'WHERE'
      '  `ID_AC_ACD` = :`Old_ID_AC_ACD`'
      '  AND `ID_AV_ACD` = :`Old_ID_AV_ACD`')
    SQLUpdate.Strings = (
      'UPDATE `fza_atributos_conjuntos_det`'
      'SET'
      '  `ID_AC_ACD` = :`ID_AC_ACD`, `ID_AV_ACD` = :`ID_AV_ACD`, `ORDEN_ACD` = :`ORDEN_ACD`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `ID_AC_ACD` = :`Old_ID_AC_ACD`'
      '  AND `ID_AV_ACD` = :`Old_ID_AV_ACD`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos_det`'
      'WHERE'
      '  `ID_AC_ACD` = :`Old_ID_AC_ACD`'
      '  AND `ID_AV_ACD` = :`Old_ID_AV_ACD`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT d.ID_AC_ACD, d.ID_AV_ACD, d.ORDEN_ACD,'
      '       v.AV, v.DESCRIPCION_AV, v.ESACTIVO_AV'
      '  FROM fza_atributos_conjuntos_det d'
      '  LEFT JOIN fza_atributos_valores v ON v.ID_AV = d.ID_AV_ACD'
      ' WHERE d.ID_AC_ACD = :ID_AC_ACD'
      '   AND d.ID_AV_ACD = :ID_AV_ACD')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_conjuntos_det')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT d.ID_AC_ACD, d.ID_AV_ACD, d.ORDEN_ACD,'
      '       v.AV, v.DESCRIPCION_AV, v.ESACTIVO_AV'
      '  FROM fza_atributos_conjuntos_det d'
      '  LEFT JOIN fza_atributos_valores v ON v.ID_AV = d.ID_AV_ACD'
      ' ORDER BY d.ORDEN_ACD, d.ID_AV_ACD')
    MasterFields = 'ID_AC'
    DetailFields = 'ID_AC_ACD'
    Active = False
    AfterInsert = unqryConjuntoDetalleAfterInsert
    BeforePost = unqryConjuntoDetalleBeforePost
    Left = 200
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'ID_AC'
        ParamType = ptInput
      end>
  end
  object dsConjuntoDetalle: TDataSource
    DataSet = unqryConjuntoDetalle
    Left = 200
    Top = 96
  end
end
