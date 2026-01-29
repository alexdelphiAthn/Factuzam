inherited dmAlmacenes: TdmAlmacenes
  Height = 214
  Width = 534
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_almacenes'
      
        '  (CODIGO_ALMACEN_ALM, CODIGO_EMPRESA_ALM, ESACTIVO_ALM, NOMBRE_' +
        'ALMACEN_ALM, CODIGO_PADRE_ALM, ESFISICO_ALM, TIPO_USO_ALM, DIREC' +
        'CION_ALM, POBLACION_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EMAIL_' +
        'ALM, CODIGO_CLIENTE_ALM, ALMACEN_DESTINO_ACTUAL_ALM, ALMACEN_ORI' +
        'GEN_ACTUAL_ALM, ORDEN_ALM, INSTANTEMODIF, INSTANTEALTA, USUARIOA' +
        'LTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_ALMACEN_ALM, :CODIGO_EMPRESA_ALM, :ESACTIVO_ALM, :NOM' +
        'BRE_ALMACEN_ALM, :CODIGO_PADRE_ALM, :ESFISICO_ALM, :TIPO_USO_ALM' +
        ', :DIRECCION_ALM, :POBLACION_ALM, :CODIGO_POSTAL_ALM, :TELEFONO_' +
        'ALM, :EMAIL_ALM, :CODIGO_CLIENTE_ALM, :ALMACEN_DESTINO_ACTUAL_AL' +
        'M, :ALMACEN_ORIGEN_ACTUAL_ALM, :ORDEN_ALM, :INSTANTEMODIF, :INST' +
        'ANTEALTA, :USUARIOALTA, :USUARIOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_almacenes'
      'WHERE'
      '  CODIGO_ALMACEN_ALM = :Old_CODIGO_ALMACEN_ALM')
    SQLUpdate.Strings = (
      'UPDATE fza_almacenes'
      'SET'
      
        '  CODIGO_ALMACEN_ALM = :CODIGO_ALMACEN_ALM, CODIGO_EMPRESA_ALM =' +
        ' :CODIGO_EMPRESA_ALM, ESACTIVO_ALM = :ESACTIVO_ALM, NOMBRE_ALMAC' +
        'EN_ALM = :NOMBRE_ALMACEN_ALM, CODIGO_PADRE_ALM = :CODIGO_PADRE_A' +
        'LM, ESFISICO_ALM = :ESFISICO_ALM, TIPO_USO_ALM = :TIPO_USO_ALM, ' +
        'DIRECCION_ALM = :DIRECCION_ALM, POBLACION_ALM = :POBLACION_ALM, ' +
        'CODIGO_POSTAL_ALM = :CODIGO_POSTAL_ALM, TELEFONO_ALM = :TELEFONO' +
        '_ALM, EMAIL_ALM = :EMAIL_ALM, CODIGO_CLIENTE_ALM = :CODIGO_CLIEN' +
        'TE_ALM, ALMACEN_DESTINO_ACTUAL_ALM = :ALMACEN_DESTINO_ACTUAL_ALM' +
        ', ALMACEN_ORIGEN_ACTUAL_ALM = :ALMACEN_ORIGEN_ACTUAL_ALM, ORDEN_' +
        'ALM = :ORDEN_ALM, INSTANTEMODIF = :INSTANTEMODIF, INSTANTEALTA =' +
        ' :INSTANTEALTA, USUARIOALTA = :USUARIOALTA, USUARIOMODIF = :USUA' +
        'RIOMODIF'
      'WHERE'
      '  CODIGO_ALMACEN_ALM = :Old_CODIGO_ALMACEN_ALM')
    SQLLock.Strings = (
      
        'SELECT CODIGO_ALMACEN_ALM, CODIGO_EMPRESA_ALM, ESACTIVO_ALM, NOM' +
        'BRE_ALMACEN_ALM, CODIGO_PADRE_ALM, ESFISICO_ALM, TIPO_USO_ALM, D' +
        'IRECCION_ALM, POBLACION_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EM' +
        'AIL_ALM, CODIGO_CLIENTE_ALM, ALMACEN_DESTINO_ACTUAL_ALM, ALMACEN' +
        '_ORIGEN_ACTUAL_ALM, ORDEN_ALM, INSTANTEMODIF, INSTANTEALTA, USUA' +
        'RIOALTA, USUARIOMODIF FROM fza_almacenes'
      'WHERE'
      '  CODIGO_ALMACEN_ALM = :Old_CODIGO_ALMACEN_ALM'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ALMACEN_ALM, CODIGO_EMPRESA_ALM, ESACTIVO_ALM, NOM' +
        'BRE_ALMACEN_ALM, CODIGO_PADRE_ALM, ESFISICO_ALM, TIPO_USO_ALM, D' +
        'IRECCION_ALM, POBLACION_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EM' +
        'AIL_ALM, CODIGO_CLIENTE_ALM, ALMACEN_DESTINO_ACTUAL_ALM, ALMACEN' +
        '_ORIGEN_ACTUAL_ALM, ORDEN_ALM, INSTANTEMODIF, INSTANTEALTA, USUA' +
        'RIOALTA, USUARIOMODIF FROM fza_almacenes'
      'WHERE'
      '  CODIGO_ALMACEN_ALM = :CODIGO_ALMACEN_ALM')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_almacenes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_almacenes'
      '')
    Active = True
    Left = 16
  end
  object qryAlmacenesCajas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_almacenes_cajas'
      
        '  (CODIGO_ALMACEN_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ' +
        ')'
      'VALUES'
      
        '  (:CODIGO_ALMACEN_ALMCAJ, :CODIGO_CAJA_ALMCAJ, :DESCRIPCION_ALM' +
        'CAJ)')
    SQLDelete.Strings = (
      'DELETE FROM fza_almacenes_cajas'
      'WHERE'
      
        '  CODIGO_ALMACEN_ALMCAJ = :Old_CODIGO_ALMACEN_ALMCAJ AND CODIGO_' +
        'CAJA_ALMCAJ = :Old_CODIGO_CAJA_ALMCAJ')
    SQLUpdate.Strings = (
      'UPDATE fza_almacenes_cajas'
      'SET'
      
        '  CODIGO_ALMACEN_ALMCAJ = :CODIGO_ALMACEN_ALMCAJ, CODIGO_CAJA_AL' +
        'MCAJ = :CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ = :DESCRIPCION_AL' +
        'MCAJ'
      'WHERE'
      
        '  CODIGO_ALMACEN_ALMCAJ = :Old_CODIGO_ALMACEN_ALMCAJ AND CODIGO_' +
        'CAJA_ALMCAJ = :Old_CODIGO_CAJA_ALMCAJ')
    SQLLock.Strings = (
      
        'SELECT CODIGO_ALMACEN_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_AL' +
        'MCAJ FROM fza_almacenes_cajas'
      'WHERE'
      
        '  CODIGO_ALMACEN_ALMCAJ = :Old_CODIGO_ALMACEN_ALMCAJ AND CODIGO_' +
        'CAJA_ALMCAJ = :Old_CODIGO_CAJA_ALMCAJ'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ALMACEN_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_AL' +
        'MCAJ FROM fza_almacenes_cajas'
      'WHERE'
      
        '  CODIGO_ALMACEN_ALMCAJ = :CODIGO_ALMACEN_ALMCAJ AND CODIGO_CAJA' +
        '_ALMCAJ = :CODIGO_CAJA_ALMCAJ')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_almacenes_cajas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_almacenes_cajas'
      '')
    MasterSource = frmMtoAlmacenes.dsTablaG
    MasterFields = 'CODIGO_ALMACEN_ALM'
    DetailFields = 'CODIGO_ALMACEN_ALMCAJ'
    Active = True
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 256
    Top = 30
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ALMACEN_ALM'
        ParamType = ptInput
        Value = 'BCN'
      end>
  end
  object dsAlmacenesCajas: TDataSource
    DataSet = qryAlmacenesCajas
    Left = 256
    Top = 108
  end
end
