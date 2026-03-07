inherited dmUsuarios: TdmUsuarios
  Height = 187
  Width = 399
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_usuarios'
      
        '  (USUARIO_USUARIO, PASSWORD_USUARIO, GRUPO_USUARIO, EMPRESADEF_' +
        'USUARIO, ESCAJA_USUARIO, DIMINUTIVO_TICKET, ULTIMOLOGIN_USUARIO,' +
        ' INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:USUARIO_USUARIO, :PASSWORD_USUARIO, :GRUPO_USUARIO, :EMPRESA' +
        'DEF_USUARIO, :ESCAJA_USUARIO, :DIMINUTIVO_TICKET, :ULTIMOLOGIN_U' +
        'SUARIO, :INSTANTEMODIF, :INSTANTEALTA, :USUARIOALTA, :USUARIOMOD' +
        'IF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_usuarios'
      'WHERE'
      '  USUARIO_USUARIO = :Old_USUARIO_USUARIO')
    SQLUpdate.Strings = (
      'UPDATE fza_usuarios'
      'SET'
      
        '  USUARIO_USUARIO = :USUARIO_USUARIO, PASSWORD_USUARIO = :PASSWO' +
        'RD_USUARIO, GRUPO_USUARIO = :GRUPO_USUARIO, EMPRESADEF_USUARIO =' +
        ' :EMPRESADEF_USUARIO, ESCAJA_USUARIO = :ESCAJA_USUARIO, DIMINUTI' +
        'VO_TICKET = :DIMINUTIVO_TICKET, ULTIMOLOGIN_USUARIO = :ULTIMOLOG' +
        'IN_USUARIO, INSTANTEMODIF = :INSTANTEMODIF, INSTANTEALTA = :INST' +
        'ANTEALTA, USUARIOALTA = :USUARIOALTA, USUARIOMODIF = :USUARIOMOD' +
        'IF'
      'WHERE'
      '  USUARIO_USUARIO = :Old_USUARIO_USUARIO')
    SQLLock.Strings = (
      
        'SELECT USUARIO_USUARIO, PASSWORD_USUARIO, GRUPO_USUARIO, EMPRESA' +
        'DEF_USUARIO, ESCAJA_USUARIO, DIMINUTIVO_TICKET, ULTIMOLOGIN_USUA' +
        'RIO, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF FROM' +
        ' fza_usuarios'
      'WHERE'
      '  USUARIO_USUARIO = :Old_USUARIO_USUARIO'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT USUARIO_USUARIO, PASSWORD_USUARIO, GRUPO_USUARIO, EMPRESA' +
        'DEF_USUARIO, ESCAJA_USUARIO, DIMINUTIVO_TICKET, ULTIMOLOGIN_USUA' +
        'RIO, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF FROM' +
        ' fza_usuarios'
      'WHERE'
      '  USUARIO_USUARIO = :USUARIO_USUARIO')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_usuarios')
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
