object dmBase: TdmBase
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 150
  Width = 215
  object unqryTablaG: TUniQuery
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 8
    Top = 24
  end
  object unqryPerfiles: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM fza_usuarios_perfiles '
      'WHERE USUARIO_GRUPO_PERFILES = '#39'Nothing'#39)
    BeforePost = unqryPerfilesBeforePost
    Left = 96
    Top = 24
  end
  object dsPerfiles: TDataSource
    DataSet = unqryPerfiles
    Left = 96
    Top = 80
  end
end
