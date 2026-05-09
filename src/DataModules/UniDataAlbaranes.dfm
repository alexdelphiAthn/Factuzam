inherited dmAlbaranes: TdmAlbaranes
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  ClientHeight = 480
  ClientWidth = 632
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_albaranes')
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    Left = 48
    Top = 24
  end
  object unqryAlbaranesLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_albaranes_lineas')
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
  object unstrdprcGetContadorAlbaran: TUniStoredProc
    StoredProcName = 'PRC_GET_CONTADOR_FACTURA'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
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
