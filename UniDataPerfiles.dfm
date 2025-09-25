object dmPerfiles: TdmPerfiles
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 150
  Width = 285
  object unqryPerfiles: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM fza_usuarios_perfiles '
      'WHERE USUARIO_GRUPO_PERFILES = '#39'Nothing'#39)
    BeforePost = unqryPerfilesBeforePost
    Left = 88
    Top = 56
  end
  object unstdGrabarPerfil: TUniStoredProc
    StoredProcName = 'PRC_CREAR_ACTUALIZAR_KEY'
    SQL.Strings = (
      
        'CALL PRC_CREAR_ACTUALIZAR_KEY(:pUSUARIO, :pKEY, :pSUBKEY, :pVALU' +
        'E, :pVALUE_TEXT, :pUSUARIO_MODIF)')
    Connection = dmConn.conUni
    Left = 184
    Top = 56
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pKEY'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pSUBKEY'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pVALUE'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideMemo
        Name = 'pVALUE_TEXT'
        ParamType = ptInput
        Value = ''
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO_MODIF'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_ACTUALIZAR_KEY'
  end
end
