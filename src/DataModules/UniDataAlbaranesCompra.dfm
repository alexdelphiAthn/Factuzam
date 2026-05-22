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
    Left = 48
    Top = 24
  end
  object unqryAlbaranesCompraLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_albaranes_compra_lineas')
    MasterFields = 'NUMERO_ALBC;SERIE_ALBC'
    DetailFields = 'NUMERO_ALBC_ALBCLIN;SERIE_ALBC_ALBCLIN'
    AfterInsert = unqryAlbaranesCompraLineasAfterInsert
    BeforePost = unqryAlbaranesCompraLineasBeforePost
    AfterPost = unqryAlbaranesCompraLineasAfterPost
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALBC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALBC'
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
end
