inherited dmFormasdePago: TdmFormasdePago
  Height = 155
  Width = 522
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_formapago'
      '')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_PERFILES = '#39'dmFormasdePago'#39' '
      'OR KEY_PERFILES='#39'frmMtoFormasdePago'#39')')
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    Connection = dmConn.conUni
    Left = 8
    Top = 84
  end
  object unqryFacturasLineas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ARTICULO, DESCRIPCION_ARTICULO, CODIGO_CLIENTE, PR' +
        'ECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NRO_FACTU' +
        'RA, LINEA_LINEA, ODONTOLOGO, SERIE_FACTURA)'
      'VALUES'
      
        '  (:ID, :CODIGO_ARTICULO, :DESCRIPCION_ARTICULO, :CODIGO_CLIENTE' +
        ', :PRECIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :' +
        'NRO_FACTURA, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FACTURA)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ARTICULO = :CODIGO_ARTICULO, DESCRIPCION_ARTI' +
        'CULO = :DESCRIPCION_ARTICULO, CODIGO_CLIENTE = :CODIGO_CLIENTE, ' +
        'PRECIOVENTA_ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZO' +
        'NA = :ZONA, DESCRIPCION_HISTORIA = :DESCRIPCION_HISTORIA, NRO_FA' +
        'CTURA = :NRO_FACTURA, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :' +
        'ODONTOLOGO, SERIE_FACTURA = :SERIE_FACTURA'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ARTICULO, DESCRIPCION_ARTICULO, CODIGO_CLIENTE' +
        ', PRECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NRO_F' +
        'ACTURA, LINEA_LINEA, ODONTOLOGO, SERIE_FACTURA FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_fac_lin_busquedas l'
      'inner join vi_fac_busquedas f'
      'on l.NRO_FACTURA_LINEA = F.NRO_FACTURA'
      'AND l.SERIE_FACTURA_LINEA = F.SERIE_FACTURA'
      '')
    MasterFields = 'CODIGO_FORMAPAGO'
    DetailFields = 'FORMA_PAGO_FACTURA'
    ReadOnly = True
    Active = True
    Left = 215
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_FORMAPAGO'
        Value = nil
      end>
  end
  object unqryFacturas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ARTICULO, DESCRIPCION_ARTICULO, CODIGO_CLIENTE, PR' +
        'ECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NRO_FACTU' +
        'RA, LINEA_LINEA, ODONTOLOGO, SERIE_FACTURA)'
      'VALUES'
      
        '  (:ID, :CODIGO_ARTICULO, :DESCRIPCION_ARTICULO, :CODIGO_CLIENTE' +
        ', :PRECIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :' +
        'NRO_FACTURA, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FACTURA)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ARTICULO = :CODIGO_ARTICULO, DESCRIPCION_ARTI' +
        'CULO = :DESCRIPCION_ARTICULO, CODIGO_CLIENTE = :CODIGO_CLIENTE, ' +
        'PRECIOVENTA_ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZO' +
        'NA = :ZONA, DESCRIPCION_HISTORIA = :DESCRIPCION_HISTORIA, NRO_FA' +
        'CTURA = :NRO_FACTURA, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :' +
        'ODONTOLOGO, SERIE_FACTURA = :SERIE_FACTURA'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ARTICULO, DESCRIPCION_ARTICULO, CODIGO_CLIENTE' +
        ', PRECIOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NRO_F' +
        'ACTURA, LINEA_LINEA, ODONTOLOGO, SERIE_FACTURA FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_fac_busquedas')
    MasterFields = 'CODIGO_FORMAPAGO'
    DetailFields = 'FORMA_PAGO_FACTURA'
    ReadOnly = True
    Active = True
    Left = 359
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_FORMAPAGO'
        Value = nil
      end>
  end
  object dsFacturas: TDataSource
    DataSet = unqryFacturas
    Left = 215
    Top = 80
  end
  object dsFacturasLineas: TDataSource
    DataSet = unqryFacturasLineas
    Left = 359
    Top = 80
  end
end
