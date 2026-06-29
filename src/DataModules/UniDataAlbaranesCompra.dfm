inherited dmAlbaranesCompra: TdmAlbaranesCompra
  Height = 480
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQLDelete.Strings = (
      'DELETE FROM fza_albaranes_compra'
      'WHERE'
      '  NUMERO_ALBC = :Old_NUMERO_ALBC'
      '  AND SERIE_ALBC = :Old_SERIE_ALBC')
    SQL.Strings = (
      'SELECT * FROM vi_albaranes_compra'
      ' ORDER BY INSTANTE_ALTA DESC, NUMERO_ALBC DESC')
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
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
  object unqryMovimientosProveedor: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT NUMERO_MOV, FECHA_MOV, LINEA_MOV, '
      '       CODIGO_ALM_MOV, NOMBRE_ALMACEN_ORIGEN, '
      '       CODIGO_ART_MOV, CODIGO_UNIDAD_MOV, '
      '       DESCRIPCION_ARTICULO_MOV, '
      '       TIPO_MOV, CANTIDAD_MOV, '
      '       PRECIO_MEDIO_MOV, TOTAL_COSTE_MOV '
      '  FROM vi_movimientos '
      ' WHERE TIPO_DOC_MOV   = '#39'AC'#39' '
      '   AND NUMERO_DOC_MOV = :NUMERO_ALBC '
      '   AND SERIE_DOC_MOV  = :SERIE_ALBC '
      ' ORDER BY LINEA_MOV')
    MasterFields = 'NUMERO_ALBC;SERIE_ALBC'
    ReadOnly = True
    Left = 520
    Top = 136
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
  object dsMovimientosProveedor: TDataSource
    DataSet = unqryMovimientosProveedor
    Left = 520
    Top = 200
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
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
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
      'SELECT * FROM vi_albaranes_compra_cab_print'
      'WHERE SERIE_ALBC = :SERIE_ALBC'
      '  AND NUMERO_ALBC = :NUMERO_ALBC')
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
      'SELECT * FROM vi_albaranes_compra_lin_print'
      'WHERE SERIE_ALBC = :SERIE_ALBC'
      '  AND NUMERO_ALBC = :NUMERO_ALBC'
      'ORDER BY CODIGO_ART, COLOR_TEXTO, LINEA_ALBC')
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
  object unqryGuiasAlbcPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT'
      '  g.ID_AC, g.NOMBRE_CORTO_AC, g.NOMBRE_AC,'
      '  g.T01, g.T02, g.T03, g.T04, g.T05,'
      '  g.T06, g.T07, g.T08, g.T09, g.T10,'
      '  g.T11, g.T12, g.T13, g.T14, g.T15,'
      '  g.T16, g.T17, g.T18, g.T19, g.T20'
      'FROM vi_albaranes_compra_guias_print g'
      'WHERE g.ID_AC IN ('
      '  SELECT L.ID_AC_PIVOT_ALBCLIN'
      '    FROM fza_albaranes_compra_lineas L'
      '   WHERE L.SERIE_ALBC_ALBCLIN  = :SERIE_ALBC'
      '     AND L.NUMERO_ALBC_ALBCLIN = :NUMERO_ALBC'
      '     AND L.ID_AC_PIVOT_ALBCLIN IS NOT NULL'
      ')'
      'ORDER BY g.NOMBRE_CORTO_AC, g.ID_AC')
    Left = 552
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
  object dsGuiasAlbcPrint: TDataSource
    DataSet = unqryGuiasAlbcPrint
    Left = 552
    Top = 64
  end
  object fxdsGuiasAlbc: TfrxDBDataset
    UserName = 'GuiasTallas'
    CloseDataSource = False
    DataSource = dsGuiasAlbcPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 552
    Top = 104
  end
  object unqryLinAlbcSkuPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT L.*'
      '  FROM fza_albaranes_compra_lineas L'
      ' WHERE L.SERIE_ALBC_ALBCLIN = :SERIE_ALBC'
      '   AND L.NUMERO_ALBC_ALBCLIN = :NUMERO_ALBC'
      ' ORDER BY L.LINEA_ALBCLIN')
    Left = 648
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
  object dsLinAlbcSkuPrint: TDataSource
    DataSet = unqryLinAlbcSkuPrint
    Left = 648
    Top = 64
  end
  object fxdsLinAlbcSku: TfrxDBDataset
    UserName = 'LineasAlbaranSku'
    CloseDataSource = False
    DataSource = dsLinAlbcSkuPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 648
    Top = 104
  end
  object unqryFormasPago: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_formapago')
    ReadOnly = True
    Left = 648
    Top = 160
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormasPago
    Left = 648
    Top = 216
  end
end
