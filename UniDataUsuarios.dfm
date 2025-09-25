inherited dmUsuarios: TdmUsuarios
  Width = 330
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_usuarios'
      '')
    AfterInsert = unqryTablaGAfterInsert
    Left = 24
  end
  object unqryGrupos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_usuarios_grupos'
      '')
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 192
    Top = 24
  end
  object dsGrupos: TDataSource
    DataSet = unqryGrupos
    Left = 192
    Top = 80
  end
  object unqryEmpresas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_emp_busquedas'
      '')
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 272
    Top = 24
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 272
    Top = 80
  end
end
