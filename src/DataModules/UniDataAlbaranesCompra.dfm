inherited dmAlbaranesCompra: TdmAlbaranesCompra
  Height = 480
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_albaranes_compra')
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    Left = 48
    Top = 24
  end
  object unqryAlbaranesCompraLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_albaranes_compra_lineas'
      ' WHERE NUMERO_ALBC_ALBCLIN = :NUMERO_ALBC'
      '   AND SERIE_ALBC_ALBCLIN  = :SERIE_ALBC'
      ' ORDER BY LINEA_ALBCLIN')
    MasterFields = 'NUMERO_ALBC;SERIE_ALBC'
    DetailFields = 'NUMERO_ALBC_ALBCLIN;SERIE_ALBC_ALBCLIN'
    AfterInsert = unqryAlbaranesCompraLineasAfterInsert
    BeforePost = unqryAlbaranesCompraLineasBeforePost
    AfterPost = unqryAlbaranesCompraLineasAfterPost
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_ALBC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_ALBC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlbaranesCompraLineas: TDataSource
    DataSet = unqryAlbaranesCompraLineas
    Left = 520
    Top = 72
  end
  object unqryEmpDataAlbc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_empresas')
    Left = 48
    Top = 192
  end
  object unqryPrvDataAlbc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_proveedores')
    Left = 48
    Top = 248
  end
  object unqryArtDataLinAlbc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_articulos')
    Left = 48
    Top = 304
  end
  object unqrySkusAlbc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIDAD_SKU, CODIGO_ART_SKU '
      '  FROM fza_articulos_skus '
      ' WHERE CODIGO_UNIDAD_SKU = :pSKU')
    Left = 48
    Top = 360
    ParamData = <
      item
        DataType = ftString
        Name = 'pSKU'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unstrdprcGetContadorAlbc: TUniStoredProc
    StoredProcName = 'PRC_GET_CONTADOR_FACTURA'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
  end
  object unqryDefArticuloAlbc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT NOMBRE_ATRIBUTO, ORDEN_VISUAL_ATRIBUTO '
      '  FROM vi_atributos_nombres '
      ' WHERE CODIGO_ART_PADRE_ARTVIN = :ARTICULO '
      ' ORDER BY ORDEN_VISUAL_ATRIBUTO')
    Left = 256
    Top = 96
    ParamData = <
      item
        DataType = ftString
        Name = 'ARTICULO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryCabAlbcPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT C.*, '
      '       E.RAZON_SOCIAL_EMP, E.NIF_EMP, E.DIRECCION1_EMP, '
      '       E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_POSTAL_EMP, '
      '       E.MOVIL_EMP, E.EMAIL_EMP, '
      '       P.RAZON_SOCIAL_PRV, P.NIF_PRV, P.DIRECCION1_PRV, '
      '       P.POBLACION_PRV, P.PROVINCIA_PRV, P.CODIGO_POSTAL_PRV, '
      '       P.MOVIL_PRV, P.EMAIL_PRV '
      '  FROM fza_albaranes_compra C '
      '  LEFT JOIN fza_empresas E ON E.CODIGO_EMP_EMP = C.CODIGO_EMP_ALBC '
      '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = C.CODIGO_PRV_ALBC '
      ' WHERE C.SERIE_ALBC = :SERIE_ALBC '
      '   AND C.NUMERO_ALBC = :NUMERO_ALBC')
    Left = 360
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_ALBC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALBC'
        Value = nil
      end>
  end
  object dsCabAlbcPrint: TDataSource
    DataSet = unqryCabAlbcPrint
    Left = 360
    Top = 64
  end
  object fxdsCabAlbc: TfrxDBDataset
    UserName = 'Albaran'
    CloseDataSource = False
    DataSource = dsCabAlbcPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 360
    Top = 104
  end
  object unqryLinAlbcPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT L.* '
      '  FROM fza_albaranes_compra_lineas L '
      ' WHERE L.SERIE_ALBC_ALBCLIN = :SERIE_ALBC '
      '   AND L.NUMERO_ALBC_ALBCLIN = :NUMERO_ALBC '
      ' ORDER BY L.LINEA_ALBCLIN')
    Left = 456
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_ALBC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALBC'
        Value = nil
      end>
  end
  object dsLinAlbcPrint: TDataSource
    DataSet = unqryLinAlbcPrint
    Left = 456
    Top = 64
  end
  object fxdsLinAlbc: TfrxDBDataset
    UserName = 'LineasAlbaran'
    CloseDataSource = False
    DataSource = dsLinAlbcPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 456
    Top = 104
  end
end
