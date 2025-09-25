inherited dmProveedores: TdmProveedores
  OldCreateOrder = True
  Height = 142
  Width = 386
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from fza_proveedores')
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select * from fza_usuarios_perfiles '
      'where ( KEY_PERFILES = '#39'frmMtoProveedores'#39' OR'
      '        KEY_PERFILES = '#39'dmProveedores'#39
      '       )')
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT(:pTipoDoc, @pcont); SELECT CAST(@pcont AS' +
        ' SIGNED) AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 8
    Top = 84
    ParamData = <
      item
        DataType = ftString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftInteger
        Name = 'pcont'
        ParamType = ptOutput
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT'
    StoredProcIsQuery = True
  end
  object unqryArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_proveedores_articulos')
    MasterSource = frmMtoProveedores.dsTablaG
    MasterFields = 'CODIGO_PROVEEDOR'
    DetailFields = 'CODIGO_PROVEEDOR'
    Left = 184
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_PROVEEDOR'
        ParamType = ptInput
        Value = '10'
      end>
  end
  object dsArticulos: TDataSource
    DataSet = unqryArticulos
    Left = 176
    Top = 80
  end
  object unqryLinFacturasArticulos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_tarifas'
      
        '  (CODIGO_ARTICULO_TARIFA, ACTIVO_TARIFA, PRECIOVENTA_IVAINCL_TA' +
        'RIFA, PRECIOVENTA_SIVA_TARIFA, FECHA_DESDE_TARIFA, FECHA_HASTA_T' +
        'ARIFA, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_ARTICULO_TARIFA, :ACTIVO_TARIFA, :PRECIOVENTA_IVAINCL' +
        '_TARIFA, :PRECIOVENTA_SIVA_TARIFA, :FECHA_DESDE_TARIFA, :FECHA_H' +
        'ASTA_TARIFA, :INSTANTEMODIF, :INSTANTEALTA, :USUARIOALTA, :USUAR' +
        'IOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ARTICULO_TARIFA = :Old_CODIGO_ARTICULO_TARIFA')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_tarifas'
      'SET'
      
        '  CODIGO_ARTICULO_TARIFA = :CODIGO_ARTICULO_TARIFA, ACTIVO_TARIF' +
        'A = :ACTIVO_TARIFA, PRECIOVENTA_IVAINCL_TARIFA = :PRECIOVENTA_IV' +
        'AINCL_TARIFA, PRECIOVENTA_SIVA_TARIFA = :PRECIOVENTA_SIVA_TARIFA' +
        ', FECHA_DESDE_TARIFA = :FECHA_DESDE_TARIFA, FECHA_HASTA_TARIFA =' +
        ' :FECHA_HASTA_TARIFA, INSTANTEMODIF = :INSTANTEMODIF, INSTANTEAL' +
        'TA = :INSTANTEALTA, USUARIOALTA = :USUARIOALTA, USUARIOMODIF = :' +
        'USUARIOMODIF'
      'WHERE'
      '  CODIGO_ARTICULO_TARIFA = :Old_CODIGO_ARTICULO_TARIFA')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ARTICULO_TARIFA = :Old_CODIGO_ARTICULO_TARIFA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ARTICULO_TARIFA, ACTIVO_TARIFA, PRECIOVENTA_IVAINC' +
        'L_TARIFA, PRECIOVENTA_SIVA_TARIFA, FECHA_DESDE_TARIFA, FECHA_HAS' +
        'TA_TARIFA, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODI' +
        'F FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ARTICULO_TARIFA = :CODIGO_ARTICULO_TARIFA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_fac_lin_busquedas'
      'INNER JOIN vi_articulos_proveedores '
      'ON vi_fac_lin_busquedas.CODIGO_ARTICULO_FACTURA_LINEA = '
      '   vi_articulos_proveedores.CODIGO_ARTICULO'
      'INNER JOIN vi_fac_busquedas'
      
        'ON vi_fac_lin_busquedas.NRO_FACTURA_LINEA = vi_fac_busquedas.NRO' +
        '_FACTURA'
      
        'AND vi_fac_lin_busquedas.SERIE_FACTURA_LINEA = vi_fac_busquedas.' +
        'SERIE_FACTURA')
    MasterSource = frmMtoProveedores.dsTablaG
    MasterFields = 'CODIGO_PROVEEDOR'
    DetailFields = 'CODIGO_PROVEEDOR'
    Left = 297
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'CODIGO_PROVEEDOR'
        ParamType = ptInput
        Value = 3
      end>
  end
  object dsLinFacturasArticulos: TDataSource
    DataSet = unqryLinFacturasArticulos
    Left = 297
    Top = 80
  end
end
