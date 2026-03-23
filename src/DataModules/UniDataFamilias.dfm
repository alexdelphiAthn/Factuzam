inherited dmFamilias: TdmFamilias
  Height = 282
  Width = 887
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos_familias`'
      
        '  (`CODIGO_FAMILIA`, `ACTIVO_FAMILIA`, `ORDEN_FAMILIA`, `ESDEFAU' +
        'LT_FAMILIA`, `CODIGO_SUBFAMILIA`, `NOMBRE_FAMILIA`, `DESCRIPCION' +
        '_FAMILIA`, `INSTANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`, `USUA' +
        'RIOMODIF`)'
      'VALUES'
      
        '  (:`CODIGO_FAMILIA`, :`ACTIVO_FAMILIA`, :`ORDEN_FAMILIA`, :`ESD' +
        'EFAULT_FAMILIA`, :`CODIGO_SUBFAMILIA`, :`NOMBRE_FAMILIA`, :`DESC' +
        'RIPCION_FAMILIA`, :`INSTANTEMODIF`, :`INSTANTEALTA`, :`USUARIOAL' +
        'TA`, :`USUARIOMODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_familias`'
      'WHERE'
      '  `CODIGO_FAMILIA` = :`Old_CODIGO_FAMILIA`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_familias`'
      'SET'
      
        '  `CODIGO_FAMILIA` = :`CODIGO_FAMILIA`, `ACTIVO_FAMILIA` = :`ACT' +
        'IVO_FAMILIA`, `ORDEN_FAMILIA` = :`ORDEN_FAMILIA`, `ESDEFAULT_FAM' +
        'ILIA` = :`ESDEFAULT_FAMILIA`, `CODIGO_SUBFAMILIA` = :`CODIGO_SUB' +
        'FAMILIA`, `NOMBRE_FAMILIA` = :`NOMBRE_FAMILIA`, `DESCRIPCION_FAM' +
        'ILIA` = :`DESCRIPCION_FAMILIA`, `INSTANTEMODIF` = :`INSTANTEMODI' +
        'F`, `INSTANTEALTA` = :`INSTANTEALTA`, `USUARIOALTA` = :`USUARIOA' +
        'LTA`, `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      '  `CODIGO_FAMILIA` = :`Old_CODIGO_FAMILIA`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_familias'
      'WHERE'
      '  `CODIGO_FAMILIA` = :`Old_CODIGO_FAMILIA`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `CODIGO_FAMILIA`, `ACTIVO_FAMILIA`, `ORDEN_FAMILIA`, `ESD' +
        'EFAULT_FAMILIA`, `CODIGO_SUBFAMILIA`, `NOMBRE_FAMILIA`, `DESCRIP' +
        'CION_FAMILIA`, `INSTANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`, `' +
        'USUARIOMODIF` FROM `fza_articulos_familias`'
      'WHERE'
      '  `CODIGO_FAMILIA` = :`CODIGO_FAMILIA`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_familias')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_articulos_familias'
      '')
    Active = True
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
    Connection = dmConn.conUni
    Left = 8
    Top = 84
  end
  object unqryArticulosFamilias: TUniQuery
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
      '  FROM vi_art_busquedas'
      '')
    MasterSource = frmMtoFamilias.dsTablaG
    MasterFields = 'CODIGO_FAMILIA'
    DetailFields = 'CODIGO_FAMILIA_ARTICULO'
    Active = True
    BeforeInsert = unqryTablaGBeforeInsert
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    Left = 256
    Top = 32
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_FAMILIA'
        ParamType = ptInput
        Value = 'BOLSOS'
      end>
  end
  object dsArticulosFamilias: TDataSource
    DataSet = unqryArticulosFamilias
    Left = 256
    Top = 104
  end
  object unqrySubFamilias: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_familias_list')
    Left = 424
    Top = 32
  end
  object dsSubFamilias: TDataSource
    DataSet = unqrySubFamilias
    Left = 424
    Top = 96
  end
  object unqryFamiliasAtributos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_familias_atributos'
      
        '  (CODIGO_FAMILIA, CODIGO_PROPIEDAD, ES_REQUERIDO, ORDEN_MOSTRAR' +
        ')'
      'VALUES'
      
        '  (:CODIGO_FAMILIA, :CODIGO_PROPIEDAD, :ES_REQUERIDO, :ORDEN_MOS' +
        'TRAR)')
    SQLDelete.Strings = (
      'DELETE FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAMILIA = :Old_CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :O' +
        'ld_CODIGO_PROPIEDAD')
    SQLUpdate.Strings = (
      'UPDATE fza_familias_atributos'
      'SET'
      
        '  CODIGO_FAMILIA = :CODIGO_FAMILIA, CODIGO_PROPIEDAD = :CODIGO_P' +
        'ROPIEDAD, ES_REQUERIDO = :ES_REQUERIDO, ORDEN_MOSTRAR = :ORDEN_M' +
        'OSTRAR'
      'WHERE'
      
        '  CODIGO_FAMILIA = :Old_CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :O' +
        'ld_CODIGO_PROPIEDAD')
    SQLLock.Strings = (
      
        'SELECT CODIGO_FAMILIA, CODIGO_PROPIEDAD, ES_REQUERIDO, ORDEN_MOS' +
        'TRAR FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAMILIA = :Old_CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :O' +
        'ld_CODIGO_PROPIEDAD'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_FAMILIA, CODIGO_PROPIEDAD, ES_REQUERIDO, ORDEN_MOS' +
        'TRAR FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAMILIA = :CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :CODIG' +
        'O_PROPIEDAD')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_familias_atributos')
    Connection = dmConn.conUni
    SQL.Strings = (
      
        'SELECT fa.CODIGO_FAMILIA, fa.CODIGO_PROPIEDAD, p.NOMBRE_PROPIEDA' +
        'D, '
      '       fa.ES_REQUERIDO, fa.ORDEN_MOSTRAR'
      'FROM fza_familias_atributos fa'
      
        'LEFT JOIN fza_propiedades p ON p.CODIGO_PROPIEDAD = fa.CODIGO_PR' +
        'OPIEDAD'
      'ORDER BY fa.ORDEN_MOSTRAR, p.NOMBRE_PROPIEDAD')
    MasterSource = frmMtoFamilias.dsTablaG
    MasterFields = 'CODIGO_FAMILIA'
    DetailFields = 'CODIGO_FAMILIA'
    Active = True
    AfterInsert = unqryFamiliasAtributosAfterInsert
    BeforePost = unqryFamiliasAtributosBeforePost
    AfterPost = unqryFamiliasAtributosAfterPost
    Left = 648
    Top = 32
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_FAMILIA'
        ParamType = ptInput
        Value = 'BOLSOS'
      end>
  end
  object dsFamiliasAtributos: TDataSource
    DataSet = unqryFamiliasAtributos
    Left = 648
    Top = 104
  end
  object unqryPropiedades: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_familias_atributos'
      
        '  (CODIGO_FAMILIA, CODIGO_PROPIEDAD, ES_REQUERIDO, ORDEN_MOSTRAR' +
        ')'
      'VALUES'
      
        '  (:CODIGO_FAMILIA, :CODIGO_PROPIEDAD, :ES_REQUERIDO, :ORDEN_MOS' +
        'TRAR)')
    SQLDelete.Strings = (
      'DELETE FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAMILIA = :Old_CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :O' +
        'ld_CODIGO_PROPIEDAD')
    SQLUpdate.Strings = (
      'UPDATE fza_familias_atributos'
      'SET'
      
        '  CODIGO_FAMILIA = :CODIGO_FAMILIA, CODIGO_PROPIEDAD = :CODIGO_P' +
        'ROPIEDAD, ES_REQUERIDO = :ES_REQUERIDO, ORDEN_MOSTRAR = :ORDEN_M' +
        'OSTRAR'
      'WHERE'
      
        '  CODIGO_FAMILIA = :Old_CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :O' +
        'ld_CODIGO_PROPIEDAD')
    SQLLock.Strings = (
      
        'SELECT CODIGO_FAMILIA, CODIGO_PROPIEDAD, ES_REQUERIDO, ORDEN_MOS' +
        'TRAR FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAMILIA = :Old_CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :O' +
        'ld_CODIGO_PROPIEDAD'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_FAMILIA, CODIGO_PROPIEDAD, ES_REQUERIDO, ORDEN_MOS' +
        'TRAR FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAMILIA = :CODIGO_FAMILIA AND CODIGO_PROPIEDAD = :CODIG' +
        'O_PROPIEDAD')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_familias_atributos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT '
      '  CODIGO_PROPIEDAD, '
      '  NOMBRE_PROPIEDAD '
      'FROM fza_propiedades '
      
        'WHERE ACTIVO_PROPIEDAD = '#39'S'#39' -- Solo mostramos las que est'#233'n act' +
        'ivas'
      
        'ORDER BY NOMBRE_PROPIEDAD ASC; -- Ordenado alfab'#233'ticamente para ' +
        'el combo')
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 792
    Top = 32
  end
  object dsPropiedades: TDataSource
    DataSet = unqryPropiedades
    Left = 792
    Top = 104
  end
end
