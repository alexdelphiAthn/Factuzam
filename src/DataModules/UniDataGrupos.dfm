inherited dmGrupos: TdmGrupos
  OldCreateOrder = True
  Width = 360
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_usuarios_grupos'
      '')
    Left = 24
  end
  inherited unqryPerfiles: TUniQuery
    Left = 128
  end
  inherited dsPerfiles: TDataSource
    Left = 128
  end
  object unqryUsuariosGrupo: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_usuarios'
      'WHERE GRUPO_USUARIO = :GRUPO_USUARIO'
      '')
    MasterSource = frmMtoGrupos.dsTablaG
    MasterFields = 'GRUPO_USUARIO'
    DetailFields = 'GRUPO_USUARIO'
    BeforePost = unqryTablaGBeforePost
    Left = 224
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'GRUPO_USUARIO'
        ParamType = ptInput
        Value = 'Administradores'
      end>
  end
  object dsUsuariosGrupo: TDataSource
    DataSet = unqryUsuariosGrupo
    Left = 224
    Top = 80
  end
end
