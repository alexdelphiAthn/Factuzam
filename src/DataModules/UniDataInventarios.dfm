inherited dmInventarios: TdmInventarios
  Height = 457
  Width = 1125
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQL.Strings = (
      'SELECT '
      '   CODIGO_EMPRESA_INVENTARIO,'
      '   CODIGO_ALMACEN_INVENTARIO,'
      '   SERIE_INVENTARIO,'
      '   NRO_INVENTARIO,'
      '   TIPO_DOC_INVENTARIO,'
      '   FECHA_INVENTARIO,'
      '   ESTADO_INVENTARIO,'
      '   DESCRIPCION_INVENTARIO,'
      '   OBSERVACIONES_INVENTARIO,'
      '   TOTAL_UNIDADES_DIFERENCIA_INVENTARIO,'
      '   TOTAL_EUROS_DIFERENCIA_INVENTARIO,'
      '   INSTANTEALTA, INSTANTEMODIF,'
      '   USUARIOALTA,  USUARIOMODIF'
      'FROM fza_inventarios'
      'ORDER BY FECHA_INVENTARIO DESC')
    AfterScroll = unqryTablaGAfterScroll
    Left = 50
    Top = 22
  end
  inherited unqryPerfiles: TUniQuery
    Left = 168
    Top = 22
  end
  inherited dsPerfiles: TDataSource
    Left = 168
  end
  object unqryLineas: TUniQuery
    SQL.Strings = (
      'SELECT *'
      'FROM fza_inventarios_lineas'
      'WHERE CODIGO_EMPRESA_INVENTARIO_LINEA  = :EMPRESA'
      '  AND CODIGO_ALMACEN_INVENTARIO_LINEA = :ALMACEN'
      '  AND SERIE_INVENTARIO_LINEA          = :SERIE'
      '  AND NRO_INVENTARIO_LINEA            = :NUMERO'
      'ORDER BY LINEA_INVENTARIO_LINEA')
    Left = 466
    Top = 22
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'NUMERO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object udspLineas: TDataSetProvider
    DataSet = unqryLineas
    Options = [poAllowCommandText, poUseQuoteChar]
    Left = 374
    Top = 22
  end
  object cdsLineas: TClientDataSet
    Aggregates = <>
    Params = <>
    ProviderName = 'udspLineas'
    AfterPost = cdsLineasAfterPost
    BeforeDelete = cdsLineasBeforeDelete
    OnCalcFields = cdsLineasCalcFields
    OnNewRecord = cdsLineasNewRecord
    Left = 282
    Top = 22
    object cdsLineasCODIGO_EMPRESA_INVENTARIO_LINEA: TStringField
      FieldName = 'CODIGO_EMPRESA_INVENTARIO_LINEA'
      Size = 10
    end
    object cdsLineasCODIGO_ALMACEN_INVENTARIO_LINEA: TStringField
      FieldName = 'CODIGO_ALMACEN_INVENTARIO_LINEA'
      Size = 10
    end
    object cdsLineasSERIE_INVENTARIO_LINEA: TStringField
      FieldName = 'SERIE_INVENTARIO_LINEA'
    end
    object cdsLineasNRO_INVENTARIO_LINEA: TStringField
      FieldName = 'NRO_INVENTARIO_LINEA'
    end
    object cdsLineasLINEA_INVENTARIO_LINEA: TStringField
      FieldName = 'LINEA_INVENTARIO_LINEA'
      Size = 4
    end
    object cdsLineasCODIGO_ARTICULO_INVENTARIO_LINEA: TStringField
      FieldName = 'CODIGO_ARTICULO_INVENTARIO_LINEA'
    end
    object cdsLineasCODIGO_UNIDAD_INVENTARIO_LINEA: TStringField
      FieldName = 'CODIGO_UNIDAD_INVENTARIO_LINEA'
      Size = 50
    end
    object cdsLineasLOTE_INVENTARIO_LINEA: TStringField
      FieldName = 'LOTE_INVENTARIO_LINEA'
      Size = 50
    end
    object cdsLineasFECHA_CADUCIDAD_INVENTARIO_LINEA: TDateField
      FieldName = 'FECHA_CADUCIDAD_INVENTARIO_LINEA'
    end
    object cdsLineasDESCRIPCION_ARTICULO_INVENTARIO_LINEA: TStringField
      FieldName = 'DESCRIPCION_ARTICULO_INVENTARIO_LINEA'
      Size = 200
    end
    object cdsLineasCANTIDAD_TEORICA_INVENTARIO_LINEA: TFMTBCDField
      FieldName = 'CANTIDAD_TEORICA_INVENTARIO_LINEA'
      DisplayFormat = ',0.00'
      Precision = 19
      Size = 6
    end
    object cdsLineasCANTIDAD_FISICA_INVENTARIO_LINEA: TFMTBCDField
      FieldName = 'CANTIDAD_FISICA_INVENTARIO_LINEA'
      DisplayFormat = ',0.00'
      Precision = 19
      Size = 6
    end
    object cdsLineasCANTIDAD_DIFERENCIA_INVENTARIO_LINEA: TFMTBCDField
      FieldName = 'CANTIDAD_DIFERENCIA_INVENTARIO_LINEA'
      DisplayFormat = '+,0.00;-,0.00'
      Precision = 19
      Size = 6
    end
    object cdsLineasPRECIO_MEDIO_INVENTARIO_LINEA: TFMTBCDField
      FieldName = 'PRECIO_MEDIO_INVENTARIO_LINEA'
      DisplayFormat = ',0.0000'
      Precision = 19
      Size = 6
    end
    object cdsLineasPRECIO_MEDIO_NUEVO_INVENTARIO_LINEA: TFMTBCDField
      FieldName = 'PRECIO_MEDIO_NUEVO_INVENTARIO_LINEA'
      DisplayFormat = ',0.0000'
      Precision = 19
      Size = 6
    end
    object cdsLineasTOTAL_COSTE_DIFERENCIA_LINEA: TFMTBCDField
      FieldName = 'TOTAL_COSTE_DIFERENCIA_LINEA'
      DisplayFormat = '+,0.00 '#8364';-,0.00 '#8364
      Precision = 19
      Size = 6
    end
    object cdsLineasFECHA_RECUENTO_INVENTARIO_LINEA: TDateTimeField
      FieldName = 'FECHA_RECUENTO_INVENTARIO_LINEA'
      DisplayFormat = 'dd/mm/yyyy hh:nn'
    end
    object cdsLineasNUM_ATRIBUTOS_REQ_INV_LINEA: TIntegerField
      FieldKind = fkInternalCalc
      FieldName = 'NUM_ATRIBUTOS_REQ_INV_LINEA'
    end
    object cdsLineasATTR1_NOMBRE: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR1_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR1_VALOR: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR1_VALOR'
      Size = 50
    end
    object cdsLineasATTR2_NOMBRE: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR2_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR2_VALOR: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR2_VALOR'
      Size = 50
    end
    object cdsLineasATTR3_NOMBRE: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR3_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR3_VALOR: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR3_VALOR'
      Size = 50
    end
    object cdsLineasATTR4_NOMBRE: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR4_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR4_VALOR: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR4_VALOR'
      Size = 50
    end
    object cdsLineasATTR5_NOMBRE: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR5_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR5_VALOR: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR5_VALOR'
      Size = 50
    end
    object cdsLineasUDS_REGULARIZADAS: TFMTBCDField
      FieldKind = fkCalculated
      FieldName = 'UDS_REGULARIZADAS'
      DisplayFormat = ',0.00'
      Precision = 19
      Size = 6
      Calculated = True
    end
  end
  object dsLineas: TDataSource
    DataSet = cdsLineas
    Left = 462
    Top = 110
  end
  object unqryMovsRegul: TUniQuery
    SQL.Strings = (
      'SELECT '
      '   m.NUMERO_MOV, m.TIPO_MOVIMIENTO_MOV,'
      '   m.CODIGO_ARTICULO_MOV, m.CODIGO_UNIDAD_MOV,'
      '   m.CANTIDAD_MOV, m.PRECIO_MEDIO_MOV,'
      '   (m.CANTIDAD_MOV * m.PRECIO_MEDIO_MOV) AS COSTE_MOV,'
      '   m.FECHA_MOV, m.ESACTIVO_MOV'
      'FROM fza_movimientos_almacen m'
      'WHERE m.CODIGO_ALMACEN_MOV = :ALMACEN'
      '  AND m.NUMERO_MOV LIKE :PATRON'
      '  AND m.TIPO_DOC_MOV = '#39'IN'#39
      '  AND m.SERIE_MOV    = :SERIE'
      '  AND m.NRO_DOC_MOV  = :NUMERO'
      'ORDER BY m.NUMERO_MOV')
    Left = 250
    Top = 198
    ParamData = <
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'PATRON'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'NUMERO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsMovsRegul: TDataSource
    DataSet = unqryMovsRegul
    Left = 254
    Top = 278
  end
  object unqryArticulo: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ARTICULO, DESCRIPCION_ARTICULO, TIPO_ARTICULO'
      'FROM fza_articulos'
      'WHERE CODIGO_ARTICULO = :CODIGO')
    Left = 778
    Top = 38
    ParamData = <
      item
        DataType = ftString
        Name = 'CODIGO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryDefinicionArticulo: TUniQuery
    SQL.Strings = (
      'SELECT DISTINCT N.NOMBRE_ATRIBUTO, N.ORDEN_VISUAL_ATRIBUTO'
      'FROM fza_articulos_skus SKU'
      'JOIN fza_atributos_sku AT'
      '  ON SKU.CODIGO_UNIDAD_SKU = AT.CODIGO_UNIDAD_SA'
      'JOIN fza_atributos_valores V'
      '  ON AT.ID_VALOR_SA = V.ID_VALOR_AV'
      'JOIN vi_atributos_nombres N'
      '  ON V.ID_VA_AV = N.ID_ATRIBUTO'
      'WHERE SKU.CODIGO_ARTICULO_SKU = :ARTICULO'
      'ORDER BY N.ORDEN_VISUAL_ATRIBUTO LIMIT 5')
    Left = 606
    Top = 110
    ParamData = <
      item
        DataType = ftString
        Name = 'ARTICULO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryStockActual: TUniQuery
    SQL.Strings = (
      'SELECT CANTIDAD_STK, PRECIO_MEDIO_STK'
      'FROM fza_articulos_stockactual'
      'WHERE CODIGO_ALMACEN_STK = :ALMACEN'
      '  AND CODIGO_UNIDAD_STK  = :SKU')
    Left = 602
    Top = 22
    ParamData = <
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SKU'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryEmpresas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_EMPRESA, RAZONSOCIAL_EMPRESA'
      'FROM fza_empresas'
      'WHERE ACTIVA_EMPRESA = '#39'S'#39
      'ORDER BY ORDEN_EMPRESA, CODIGO_EMPRESA')
    Left = 138
    Top = 198
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 142
    Top = 278
  end
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALMACEN, DESCRIPCION_ALMACEN'
      'FROM fza_almacenes'
      'ORDER BY CODIGO_ALMACEN')
    Left = 370
    Top = 198
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 374
    Top = 278
  end
  object unqrySeries: TUniQuery
    SQL.Strings = (
      'SELECT SERIE_SERIE'
      'FROM fza_series'
      'WHERE TIPODOC_SERIE = '#39'IN'#39
      'ORDER BY SERIE_SERIE')
    Left = 650
    Top = 198
  end
  object dsSeries: TDataSource
    DataSet = unqrySeries
    Left = 654
    Top = 278
  end
  object unqryFamilias: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_FAMILIA, DESCRIPCION_FAMILIA'
      'FROM fza_familias'
      'ORDER BY CODIGO_FAMILIA')
    Left = 26
    Top = 198
  end
  object dsFamilias: TDataSource
    DataSet = unqryFamilias
    Left = 22
    Top = 278
  end
  object unqryProveedores: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_PROVEEDOR, RAZONSOCIAL_PROVEEDOR'
      'FROM fza_proveedores'
      'ORDER BY RAZONSOCIAL_PROVEEDOR')
    Left = 506
    Top = 198
  end
  object dsProveedores: TDataSource
    DataSet = unqryProveedores
    Left = 510
    Top = 278
  end
  object unspActualizarTeorico: TUniStoredProc
    StoredProcName = 'PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO'
    Left = 82
    Top = 374
    ParamData = <
      item
        DataType = ftString
        Name = 'p_EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_NRO'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_USUARIO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unspAplicar: TUniStoredProc
    StoredProcName = 'PRC_FZA_INVENTARIOS_APLICAR'
    Left = 282
    Top = 374
    ParamData = <
      item
        DataType = ftString
        Name = 'p_EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_NRO'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_USUARIO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unspEliminarRegul: TUniStoredProc
    StoredProcName = 'PRC_FZA_INVENTARIOS_ELIMINAR_REGUL'
    Left = 482
    Top = 374
    ParamData = <
      item
        DataType = ftString
        Name = 'p_EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_NRO'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_USUARIO'
        ParamType = ptInput
        Value = nil
      end>
  end
end
