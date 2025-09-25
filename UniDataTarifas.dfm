inherited dmTarifas: TdmTarifas
  OldCreateOrder = True
  Width = 400
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_tarifas'
      '')
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_PERFILES = '#39'dmFamilias'#39' '
      'OR KEY_PERFILES='#39'frmMtoFamilias'#39')')
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
  end
  object unqryArticulosTarifas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_tarifas'
      
        '  (CODIGO_ARTICULO_TARIFA, CODIGO_VARIACION_TARIFA, CODIGO_UNICO' +
        '_TARIFA, CODIGO_TARIFA, ACTIVO_TARIFA, PRECIOFINAL, FECHA_DESDE_' +
        'TARIFA, FECHA_HASTA_TARIFA, INSTANTEMODIF, INSTANTEALTA, USUARIO' +
        'ALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_ARTICULO_TARIFA, :CODIGO_VARIACION_TARIFA, :CODIGO_UN' +
        'ICO_TARIFA, :CODIGO_TARIFA, :ACTIVO_TARIFA, :PRECIOFINAL, :FECHA' +
        '_DESDE_TARIFA, :FECHA_HASTA_TARIFA, :INSTANTEMODIF, :INSTANTEALT' +
        'A, :USUARIOALTA, :USUARIOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :Old_CODIGO_UNICO_TARIFA')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_tarifas'
      'SET'
      
        '  CODIGO_ARTICULO_TARIFA = :CODIGO_ARTICULO_TARIFA, CODIGO_VARIA' +
        'CION_TARIFA = :CODIGO_VARIACION_TARIFA, CODIGO_UNICO_TARIFA = :C' +
        'ODIGO_UNICO_TARIFA, CODIGO_TARIFA = :CODIGO_TARIFA, ACTIVO_TARIF' +
        'A = :ACTIVO_TARIFA, PRECIOFINAL = :PRECIOFINAL, FECHA_DESDE_TARI' +
        'FA = :FECHA_DESDE_TARIFA, FECHA_HASTA_TARIFA = :FECHA_HASTA_TARI' +
        'FA, INSTANTEMODIF = :INSTANTEMODIF, INSTANTEALTA = :INSTANTEALTA' +
        ', USUARIOALTA = :USUARIOALTA, USUARIOMODIF = :USUARIOMODIF'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :Old_CODIGO_UNICO_TARIFA')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :Old_CODIGO_UNICO_TARIFA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ARTICULO_TARIFA, CODIGO_VARIACION_TARIFA, CODIGO_U' +
        'NICO_TARIFA, CODIGO_TARIFA, ACTIVO_TARIFA, PRECIOFINAL, FECHA_DE' +
        'SDE_TARIFA, FECHA_HASTA_TARIFA, INSTANTEMODIF, INSTANTEALTA, USU' +
        'ARIOALTA, USUARIOMODIF FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :CODIGO_UNICO_TARIFA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_articulos_tarifas'
      '')
    MasterSource = frmMtoTarifas.dsTablaG
    MasterFields = 'CODIGO_TARIFA'
    DetailFields = 'CODIGO_TARIFA'
    BeforeInsert = unqryTablaGBeforeInsert
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    Left = 200
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_TARIFA'
        ParamType = ptInput
        Value = '0'
      end>
  end
  object dsArticulosTarifas: TDataSource
    DataSet = unqryArticulosTarifas
    Left = 200
    Top = 80
  end
end
