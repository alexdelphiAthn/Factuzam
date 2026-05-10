inherited dmAlbaranes: TdmAlbaranes
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_albaranes')
    AfterInsert = unqryTablaGAfterInsert
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
    Left = 48
    Top = 80
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
    Left = 128
    Top = 80
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
  object unstrdprcGetContadorAlbaran: TUniStoredProc
    StoredProcName = 'PRC_GET_CONTADOR_FACTURA'
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
