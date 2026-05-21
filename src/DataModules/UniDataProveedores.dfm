inherited dmProveedores: TdmProveedores
  Height = 142
  Width = 386
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from fza_proveedores')
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select * from fza_usuarios_perfiles '
      'where ( KEY_USUPER = '#39'frmMtoProveedores'#39' OR'
      '        KEY_USUPER = '#39'dmProveedores'#39
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
    MasterFields = 'CODIGO_PRV_PRV'
    DetailFields = 'CODIGO_PRV_PRV'
    Left = 184
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_PRV_PRV'
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
      
        '  (CODIGO_ART_ARTTAR, ESACTIVO_ARTTAR, PRECIOVENTA_IVAINCL_TARIF' +
        'A, PRECIOVENTA_SIVA_TARIFA, FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTT' +
        'AR, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ART_ARTTAR, :ESACTIVO_ARTTAR, :PRECIOVENTA_IVAINCL_TA' +
        'RIFA, :PRECIOVENTA_SIVA_TARIFA, :FECHA_DESDE_ARTTAR, :FECHA_HAST' +
        'A_ARTTAR, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUAR' +
        'IO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :Old_CODIGO_ART_ARTTAR')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_tarifas'
      'SET'
      
        '  CODIGO_ART_ARTTAR = :CODIGO_ART_ARTTAR, ESACTIVO_ARTTAR = :ESA' +
        'CTIVO_ARTTAR, PRECIOVENTA_IVAINCL_TARIFA = :PRECIOVENTA_IVAINCL_' +
        'TARIFA, PRECIOVENTA_SIVA_TARIFA = :PRECIOVENTA_SIVA_TARIFA, FECH' +
        'A_DESDE_ARTTAR = :FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR = :FECH' +
        'A_HASTA_ARTTAR, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA ' +
        '= :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = ' +
        ':USUARIO_MODIF'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :Old_CODIGO_ART_ARTTAR')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :Old_CODIGO_ART_ARTTAR'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ART_ARTTAR, ESACTIVO_ARTTAR, PRECIOVENTA_IVAINCL_T' +
        'ARIFA, PRECIOVENTA_SIVA_TARIFA, FECHA_DESDE_ARTTAR, FECHA_HASTA_' +
        'ARTTAR, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MOD' +
        'IF FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :CODIGO_ART_ARTTAR')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_fac_lin_busquedas'
      'INNER JOIN vi_articulos_proveedores '
      'ON vi_fac_lin_busquedas.CODIGO_ART_FACLIN = '
      '   vi_articulos_proveedores.CODIGO_ART_ART'
      'INNER JOIN vi_fac_busquedas'
      
        'ON vi_fac_lin_busquedas.NUMERO_FAC_FACLIN = vi_fac_busquedas.NUM' +
        'ERO_FAC'
      
        'AND vi_fac_lin_busquedas.SERIE_FAC_FACLIN = vi_fac_busquedas.SER' +
        'IE_FAC')
    MasterSource = frmMtoProveedores.dsTablaG
    MasterFields = 'CODIGO_PRV_PRV'
    DetailFields = 'CODIGO_PRV_PRV'
    Left = 297
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'CODIGO_PRV_PRV'
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
