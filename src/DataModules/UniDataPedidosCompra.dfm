inherited dmPedidosCompra: TdmPedidosCompra
  Height = 480
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_pedidos_compra')
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 48
    Top = 24
  end
  object unqryPedidosCompraLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_pedidos_compra_lineas'
      ' WHERE NUMERO_PEDC_PEDCLIN = :NUMERO_PEDC'
      '   AND SERIE_PEDC_PEDCLIN  = :SERIE_PEDC'
      ' ORDER BY LINEA_PEDCLIN')
    MasterFields = 'NUMERO_PEDC;SERIE_PEDC'
    DetailFields = 'NUMERO_PEDC_PEDCLIN;SERIE_PEDC_PEDCLIN'
    AfterInsert = unqryPedidosCompraLineasAfterInsert
    BeforePost = unqryPedidosCompraLineasBeforePost
    AfterPost = unqryPedidosCompraLineasAfterPost
    BeforeDelete = unqryPedidosCompraLineasBeforeDelete
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_PEDC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_PEDC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsPedidosCompraLineas: TDataSource
    DataSet = unqryPedidosCompraLineas
    Left = 520
    Top = 72
  end
  object unqryEmpDataPedc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_empresas')
    Left = 48
    Top = 192
  end
  object unqryPrvDataPedc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_proveedores')
    Left = 48
    Top = 248
  end
  object unqrySkusPedc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIDAD_SKU, CODIGO_ART_SKU '
      '  FROM fza_articulos_skus '
      ' WHERE CODIGO_UNIDAD_SKU = :pSKU')
    Left = 48
    Top = 304
    ParamData = <
      item
        DataType = ftString
        Name = 'pSKU'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unstrdprcGetContadorPedc: TUniStoredProc
    StoredProcName = 'PRC_GET_CONTADOR_FACTURA'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
  end
  object unqryDefArticuloPedc: TUniQuery
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
  object unqryTemporadasPedc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, PV'
      '  FROM fza_propiedades_valores'
      ' WHERE ID_PROP_PV = '#39'TEMPORADA'#39
      '   AND ESACTIVO_PV = '#39'S'#39
      ' ORDER BY PV')
    Left = 360
    Top = 96
  end
  object dsTemporadasPedc: TDataSource
    DataSet = unqryTemporadasPedc
    Left = 360
    Top = 160
  end
  object unqryAlbaranesPedc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC,'
      '       REF_PROVEEDOR_ALBC, TOTAL_LIQUIDO_ALBC'
      '  FROM fza_albaranes_compra'
      ' WHERE NUMERO_PED_ALBC = :NUMERO_PEDC'
      '   AND SERIE_PED_ALBC  = :SERIE_PEDC'
      ' ORDER BY FECHA_ALBC DESC, NUMERO_ALBC DESC')
    MasterFields = 'NUMERO_PEDC;SERIE_PEDC'
    DetailFields = 'NUMERO_PED_ALBC;SERIE_PED_ALBC'
    Left = 360
    Top = 224
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_PEDC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_PEDC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlbaranesPedc: TDataSource
    DataSet = unqryAlbaranesPedc
    Left = 360
    Top = 288
  end
end
