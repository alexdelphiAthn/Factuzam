inherited dmAlbaranes: TdmAlbaranes
  Height = 529
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQLDelete.Strings = (
      'DELETE FROM fza_albaranes'
      'WHERE'
      '  NUMERO_ALB = :Old_NUMERO_ALB'
      '  AND SERIE_ALB = :Old_SERIE_ALB')
    SQL.Strings = (
      'SELECT * FROM vi_albaranes'
      ' ORDER BY INSTANTE_ALTA DESC, NUMERO_ALB DESC')
    AfterInsert = unqryTablaGAfterInsert
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 48
    Top = 24
  end
  object unqryAlbaranesLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_albaranes_lineas')
    MasterFields = 'NUMERO_ALB;SERIE_ALB'
    DetailFields = 'NUMERO_ALB_ALBLIN;SERIE_ALB_ALBLIN'
    AfterInsert = unqryAlbaranesLineasAfterInsert
    BeforePost = unqryAlbaranesLineasBeforePost
    AfterPost = unqryAlbaranesLineasAfterPost
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALB'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALB'
        Value = nil
      end>
  end
  object dsAlbaranesLineas: TDataSource
    DataSet = unqryAlbaranesLineas
    Left = 520
    Top = 72
  end
  object unqryEmpDataAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_empresas')
    Left = 48
    Top = 192
  end
  object unqryCliDataAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_clientes')
    Left = 48
    Top = 248
  end
  object unqryArtDataLinAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_articulos')
    Left = 48
    Top = 304
  end
  object unqrySkusAlb: TUniQuery
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
  object unqryFacturas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT NUMERO_FAC, SERIE_FAC, FECHA_FAC, FASE_FAC, '
      '       TOTAL_LIQUIDO_FAC '
      '  FROM fza_facturas '
      ' WHERE (NUMERO_FAC, SERIE_FAC) IN ('
      '   SELECT NUMERO_FAC_ALB, SERIE_FAC_ALB '
      '     FROM fza_albaranes '
      '    WHERE NUMERO_ALB = :NUMERO_ALB '
      '      AND SERIE_ALB  = :SERIE_ALB '
      '      AND NUMERO_FAC_ALB IS NOT NULL '
      '   UNION '
      '   SELECT NUMERO_FAC_ALBLIN, SERIE_FAC_ALBLIN '
      '     FROM fza_albaranes_lineas '
      '    WHERE NUMERO_ALB_ALBLIN = :NUMERO_ALB '
      '      AND SERIE_ALB_ALBLIN  = :SERIE_ALB '
      '      AND NUMERO_FAC_ALBLIN IS NOT NULL '
      ' ) '
      ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC')
    MasterFields = 'NUMERO_ALB;SERIE_ALB'
    DetailFields = 'NUMERO_ALB;SERIE_ALB'
    Left = 384
    Top = 200
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALB'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALB'
        Value = nil
      end>
  end
  object dsFacturas: TDataSource
    DataSet = unqryFacturas
    Left = 464
    Top = 200
  end
  object unqryMovimientosAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT NUMERO_MOV, FECHA_MOV, LINEA_MOV, '
      '       CODIGO_ALM_MOV, NOMBRE_ALMACEN_ORIGEN, '
      '       CODIGO_ART_MOV, CODIGO_UNIDAD_MOV, '
      '       DESCRIPCION_ARTICULO_MOV, '
      '       TIPO_MOV, CANTIDAD_MOV, '
      '       PRECIO_MEDIO_MOV, TOTAL_COSTE_MOV '
      '  FROM vi_movimientos '
      ' WHERE TIPO_DOC_REF_MOV   = '#39'AV'#39' '
      '   AND SERIE_DOC_REF_MOV  = :SERIE_ALB '
      '   AND NUMERO_DOC_REF_MOV = :NUMERO_ALB '
      ' ORDER BY LINEA_MOV')
    MasterFields = 'NUMERO_ALB;SERIE_ALB'
    Left = 384
    Top = 256
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALB'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALB'
        Value = nil
      end>
  end
  object dsMovimientosAlb: TDataSource
    DataSet = unqryMovimientosAlb
    Left = 464
    Top = 256
  end
  object unstrdprcGetContadorAlbaran: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
  end
  object unstrdprcCrearFacturaInicio: TUniStoredProc
    StoredProcName = 'PRC_ALB_CREAR_FACTURA_INICIO'
    Connection = dmConn.conUni
    Left = 256
    Top = 200
  end
  object unstrdprcCrearFacturaLinea: TUniStoredProc
    StoredProcName = 'PRC_ALB_CREAR_FACTURA_LINEA'
    Connection = dmConn.conUni
    Left = 256
    Top = 256
  end
  object unstrdprcCrearFacturaFin: TUniStoredProc
    StoredProcName = 'PRC_ALB_CREAR_FACTURA_FIN'
    Connection = dmConn.conUni
    Left = 256
    Top = 312
  end
  object unstrdprcInsertarMovAlb: TUniStoredProc
    StoredProcName = 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT'
    Connection = dmConn.conUni
    Left = 256
    Top = 368
  end
  object fxdsPrintAlb: TfrxDBDataset
    UserName = 'frxDBDataset1'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 384
    Top = 24
  end
  object fxdstPrintLinAlb: TfrxDBDataset
    UserName = 'frxDBDataset2'
    CloseDataSource = False
    DataSet = unqryAlbaranesLineas
    BCDToCurrency = False
    DataSetOptions = []
    Left = 384
    Top = 80
  end
end
