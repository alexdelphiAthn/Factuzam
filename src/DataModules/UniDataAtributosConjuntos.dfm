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
      'INSERT INTO fza_atributos_conjuntos_det'
      '  (ID_AC_ACD, ID_AV_ACD, ORDEN_ACD,'
      '   INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      '  (:ID_AC_ACD, :ID_AV_ACD, :ORDEN_ACD,'
      '   :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_atributos_conjuntos_det'
      'WHERE'
      '  ID_AC_ACD = :Old_ID_AC_ACD'
      '  AND ID_AV_ACD = :Old_ID_AV_ACD')
    SQLUpdate.Strings = (
      'UPDATE fza_atributos_conjuntos_det'
      'SET'
      '  ID_AC_ACD = :ID_AC_ACD, ID_AV_ACD = :ID_AV_ACD,'
      '  ORDEN_ACD = :ORDEN_ACD,'
      '  INSTANTE_MODIF = :INSTANTE_MODIF,'
      '  USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  ID_AC_ACD = :Old_ID_AC_ACD'
      '  AND ID_AV_ACD = :Old_ID_AV_ACD')
    SQLLock.Strings = (
      'SELECT ID_AC_ACD, ID_AV_ACD, ORDEN_ACD,'
      '       INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF'
      '  FROM fza_atributos_conjuntos_det'
      ' WHERE ID_AC_ACD = :Old_ID_AC_ACD'
      '   AND ID_AV_ACD = :Old_ID_AV_ACD'
      ' FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT ID_AC_ACD, ID_AV_ACD, ORDEN_ACD,'
      '       INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF'
      '  FROM fza_atributos_conjuntos_det'
      ' WHERE ID_AC_ACD = :ID_AC_ACD'
      '   AND ID_AV_ACD = :ID_AV_ACD')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_conjuntos_det')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_AC_ACD, ID_AV_ACD, ORDEN_ACD,'
      '       INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF'
      '  FROM fza_atributos_conjuntos_det'
      ' ORDER BY ORDEN_ACD, ID_AV_ACD')
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
  object unqryValoresLookup: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_AV, ID_VA_AV, AV, DESCRIPCION_AV, ORDEN_AV'
      '  FROM fza_atributos_valores'
      ' WHERE ESACTIVO_AV = ''S'''
      ' ORDER BY ID_VA_AV, ORDEN_AV, AV')
    Active = False
    Left = 376
    Top = 24
  end
  object dsValoresLookup: TDataSource
    DataSet = unqryValoresLookup
    Left = 376
    Top = 96
  end
  object unqryArticulosConjunto: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.ESACTIVO_ART,'
      '       a.CODIGO_FAM_ART, f.NOMBRE_FAM_FAM,'
      '       asg.ID_AC_ACA, asg.ID_VA_ACA, asg.ESGENERACION_AUTO_ACA'
      '  FROM fza_articulos_conjuntos_asign asg'
      '  INNER JOIN fza_articulos a ON a.CODIGO_ART_ART = asg.CODIGO_ART_ACA'
      '  LEFT JOIN fza_articulos_familias f ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART'
      ' ORDER BY a.CODIGO_ART_ART')
    MasterFields = 'ID_AC'
    DetailFields = 'ID_AC_ACA'
    Active = False
    Left = 552
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'ID_AC'
        ParamType = ptInput
      end>
  end
  object dsArticulosConjunto: TDataSource
    DataSet = unqryArticulosConjunto
    Left = 552
    Top = 96
  end
end
