inherited dmArticulos: TdmArticulos
  Height = 256
  Width = 1012
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos`'
      
        '  (`CODIGO_ARTICULO`, `ACTIVO_ARTICULO`, `ORDEN_ARTICULO`, `DESC' +
        'RIPCION_ARTICULO`, `CODIGO_FAMILIA_ARTICULO`, `TIPOIVA_ARTICULO`' +
        ', `ESACTIVO_FIJO_ARTICULO`, `TIPO_CANTIDAD_ARTICULO`, `INSTANTEM' +
        'ODIF`, `INSTANTEALTA`, `USUARIOALTA`, `USUARIOMODIF`)'
      'VALUES'
      
        '  (:`CODIGO_ARTICULO`, :`ACTIVO_ARTICULO`, :`ORDEN_ARTICULO`, :`' +
        'DESCRIPCION_ARTICULO`, :`CODIGO_FAMILIA_ARTICULO`, :`TIPOIVA_ART' +
        'ICULO`, :`ESACTIVO_FIJO_ARTICULO`, :`TIPO_CANTIDAD_ARTICULO`, :`' +
        'INSTANTEMODIF`, :`INSTANTEALTA`, :`USUARIOALTA`, :`USUARIOMODIF`' +
        ')')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos`'
      'WHERE'
      '  `CODIGO_ARTICULO` = :`Old_CODIGO_ARTICULO`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos`'
      'SET'
      
        '  `CODIGO_ARTICULO` = :`CODIGO_ARTICULO`, `ACTIVO_ARTICULO` = :`' +
        'ACTIVO_ARTICULO`, `ORDEN_ARTICULO` = :`ORDEN_ARTICULO`, `DESCRIP' +
        'CION_ARTICULO` = :`DESCRIPCION_ARTICULO`, `CODIGO_FAMILIA_ARTICU' +
        'LO` = :`CODIGO_FAMILIA_ARTICULO`, `TIPOIVA_ARTICULO` = :`TIPOIVA' +
        '_ARTICULO`, `ESACTIVO_FIJO_ARTICULO` = :`ESACTIVO_FIJO_ARTICULO`' +
        ', `TIPO_CANTIDAD_ARTICULO` = :`TIPO_CANTIDAD_ARTICULO`, `INSTANT' +
        'EMODIF` = :`INSTANTEMODIF`, `INSTANTEALTA` = :`INSTANTEALTA`, `U' +
        'SUARIOALTA` = :`USUARIOALTA`, `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      '  `CODIGO_ARTICULO` = :`Old_CODIGO_ARTICULO`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos'
      'WHERE'
      '  `CODIGO_ARTICULO` = :`Old_CODIGO_ARTICULO`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `CODIGO_ARTICULO`, `ACTIVO_ARTICULO`, `ORDEN_ARTICULO`, `' +
        'DESCRIPCION_ARTICULO`, `CODIGO_FAMILIA_ARTICULO`, `TIPOIVA_ARTIC' +
        'ULO`, `ESACTIVO_FIJO_ARTICULO`, `TIPO_CANTIDAD_ARTICULO`, `INSTA' +
        'NTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`, `USUARIOMODIF` FROM `f' +
        'za_articulos`'
      'WHERE'
      '  `CODIGO_ARTICULO` = :`CODIGO_ARTICULO`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_articulos '
      '')
    BeforeInsert = nil
    AfterInsert = unqryTablaGAfterInsert
    AfterDelete = unqryTablaGAfterDelete
    Left = 48
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_PERFILES = Nothing)')
    Left = 136
  end
  inherited dsPerfiles: TDataSource
    Left = 136
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT(:pTipoDoc, :pUSUARIO_MODIF, @pcont); SELE' +
        'CT @pcont AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 48
    Top = 84
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = 'AR'
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO_MODIF'
        ParamType = ptInput
        Size = 100
        Value = 'Administrador'
      end
      item
        DataType = ftWideString
        Name = 'pcont'
        ParamType = ptOutput
        Size = 20
        Value = '002'
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT'
  end
  object unqryFamiliaArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_familias_list')
    Left = 224
    Top = 24
  end
  object dsFamiliaArticulos: TDataSource
    DataSet = unqryFamiliaArticulos
    Left = 224
    Top = 80
  end
  object unqryTarifasArticulos: TUniQuery
    KeyFields = 'CODIGO_UNICO_TARIFA'
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_tarifas'
      
        '  (CODIGO_ARTICULO_TARIFA, CODIGO_UNICO_TARIFA, CODIGO_TARIFA, A' +
        'CTIVO_TARIFA, PRECIOSALIDA_TARIFA, PRECIOFINAL_TARIFA, PRECIO_DT' +
        'O_TARIFA, PORCEN_DTO_TARIFA, FECHA_DESDE_TARIFA, FECHA_HASTA_TAR' +
        'IFA, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_ARTICULO_TARIFA, :CODIGO_UNICO_TARIFA, :CODIGO_TARIFA' +
        ', :ACTIVO_TARIFA, :PRECIOSALIDA_TARIFA, :PRECIOFINAL_TARIFA, :PR' +
        'ECIO_DTO_TARIFA, :PORCEN_DTO_TARIFA, :FECHA_DESDE_TARIFA, :FECHA' +
        '_HASTA_TARIFA, :INSTANTEMODIF, :INSTANTEALTA, :USUARIOALTA, :USU' +
        'ARIOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :Old_CODIGO_UNICO_TARIFA')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_tarifas'
      'SET'
      
        '  CODIGO_ARTICULO_TARIFA = :CODIGO_ARTICULO_TARIFA, CODIGO_UNICO' +
        '_TARIFA = :CODIGO_UNICO_TARIFA, CODIGO_TARIFA = :CODIGO_TARIFA, ' +
        'ACTIVO_TARIFA = :ACTIVO_TARIFA, PRECIOSALIDA_TARIFA = :PRECIOSAL' +
        'IDA_TARIFA, PRECIOFINAL_TARIFA = :PRECIOFINAL_TARIFA, PRECIO_DTO' +
        '_TARIFA = :PRECIO_DTO_TARIFA, PORCEN_DTO_TARIFA = :PORCEN_DTO_TA' +
        'RIFA, FECHA_DESDE_TARIFA = :FECHA_DESDE_TARIFA, FECHA_HASTA_TARI' +
        'FA = :FECHA_HASTA_TARIFA, INSTANTEMODIF = :INSTANTEMODIF, INSTAN' +
        'TEALTA = :INSTANTEALTA, USUARIOALTA = :USUARIOALTA, USUARIOMODIF' +
        ' = :USUARIOMODIF'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :Old_CODIGO_UNICO_TARIFA')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :Old_CODIGO_UNICO_TARIFA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ARTICULO_TARIFA, CODIGO_UNICO_TARIFA, CODIGO_TARIF' +
        'A, ACTIVO_TARIFA, PRECIOSALIDA_TARIFA, PRECIOFINAL_TARIFA, PRECI' +
        'O_DTO_TARIFA, PORCEN_DTO_TARIFA, FECHA_DESDE_TARIFA, FECHA_HASTA' +
        '_TARIFA, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF ' +
        'FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_TARIFA = :CODIGO_UNICO_TARIFA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_tarifas')
    MasterFields = 'CODIGO_ARTICULO'
    DetailFields = 'CODIGO_ARTICULO_TARIFA'
    BeforePost = unqryTarifasArticulosBeforePost
    Left = 328
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ARTICULO'
        ParamType = ptInput
        Value = ''
      end>
  end
  object dsTarifasArticulos: TDataSource
    DataSet = unqryTarifasArticulos
    Left = 336
    Top = 80
  end
  object unqryProveedoresArticulos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos_proveedores`'
      '      (`CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`, '
      '       `CODIGO_ARTICULO_ARTICULO_PROVEEDOR`, '
      '       `PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR`, '
      '       `FECHA_VALIDEZ_ARTICULO_PROVEEDOR`, '
      '       `ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR`,'
      '       `INSTANTEMODIF`, '
      '       `INSTANTEALTA`, '
      '       `USUARIOALTA`, '
      '       `USUARIOMODIF`)'
      'VALUES'
      '      (:`CODIGO_PROVEEDOR`, '
      '       :`CODIGO_ARTICULO`, '
      '       :`PRECIO_ULT_COMPRA`, '
      '       :`FECHA_VALIDEZ`, '
      '       :`ESPROVEEDORPRINCIPAL`,'
      '       :`INSTANTEMODIF`, '
      '       :`INSTANTEALTA`, '
      '       :`USUARIOALTA`, '
      '       :`USUARIOMODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` = :`Old_CODIGO_PROVEEDOR' +
        '`'
      
        ' AND `CODIGO_ARTICULO_ARTICULO_PROVEEDOR` = :`Old_CODIGO_ARTICUL' +
        'O`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      
        '  `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`     = :`CODIGO_PROVEEDOR' +
        '`, '
      
        '  `CODIGO_ARTICULO_ARTICULO_PROVEEDOR`      = :`CODIGO_ARTICULO`' +
        ', '
      
        '  `PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR`    = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULO_PROVEEDOR`        = :`FECHA_VALIDEZ`, '
      
        '  `ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` = :`ESPROVEEDORPRINC' +
        'IPAL`,'
      '  `INSTANTEMODIF`                           = :`INSTANTEMODIF`, '
      '  `INSTANTEALTA`                            = :`INSTANTEALTA`, '
      '  `USUARIOALTA`                             = :`USUARIOALTA`, '
      '  `USUARIOMODIF`                            = :`USUARIOMODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`  = :`Old_CODIGO_PROVEEDO' +
        'R` '
      
        'AND `CODIGO_ARTICULO_ARTICULO_PROVEEDOR` = :`Old_CODIGO_ARTICULO' +
        '`')
    SQLLock.Strings = (
      'SELECT * '
      '  FROM fza_articulos_proveedores'
      ' WHERE'
      
        '       `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR`  = :`Old_CODIGO_PRO' +
        'VEEDOR` '
      
        '   AND `CODIGO_ARTICULO_ARTICULO_PROVEEDOR`   = :`Old_CODIGO_ART' +
        'ICULO`'
      '   FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT *'
      '  FROM vi_articulos_proveedores'
      'WHERE'
      
        '      `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` = :`CODIGO_PROVEEDOR' +
        '` '
      '  AND `CODIGO_ARTICULO_ARTICULO_PROVEEDOR`  = :`CODIGO_ARTICULO`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_proveedores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_proveedores')
    MasterFields = 'CODIGO_ARTICULO'
    DetailFields = 'CODIGO_ARTICULO'
    BeforePost = unqryProveedoresArticulosBeforePost
    Left = 448
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ARTICULO'
        ParamType = ptInput
        Value = 'ALFALFA'
      end>
  end
  object dsProveedoresArticulos: TDataSource
    DataSet = unqryProveedoresArticulos
    Left = 440
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
      'from vi_fac_lin_busquedas l'
      'INNER JOIN vi_fac_busquedas f'
      'ON l.NRO_FACTURA_LINEA = f.NRO_FACTURA'
      'AND l.SERIE_FACTURA_LINEA = f.SERIE_FACTURA')
    MasterFields = 'CODIGO_ARTICULO'
    DetailFields = 'CODIGO_ARTICULO_FACTURA_LINEA'
    BeforePost = unqryPerfilesBeforePost
    Left = 600
    Top = 16
  end
  object dsLinFacturasArticulos: TDataSource
    DataSet = unqryLinFacturasArticulos
    Left = 600
    Top = 80
  end
  object unqryProveedores: TUniQuery
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR`'
      
        ' AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTI' +
        'CULO`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PROVEEDOR`' +
        ', '
      '  `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ARTICULO`, '
      
        '  `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES` = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES` = :`FECHA_VALIDEZ`, '
      '  `INSTANTEMODIF` = :`INSTANTEMODIF`, '
      '  `INSTANTEALTA` = :`INSTANTEALTA`, '
      '  `USUARIOALTA` = :`USUARIOALTA`, '
      '  `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES`, '
      '       `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES`, '
      '       `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES`, '
      '       `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES`, '
      '       `INSTANTEMODIF`, '
      '       `INSTANTEALTA`, '
      '       `USUARIOALTA`, '
      '       `USUARIOMODIF` '
      'FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PROVEEDOR`' +
        ' '
      'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ARTICULO`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_proveedores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_proveedores')
    Left = 712
    Top = 16
  end
  object dsProveedores: TDataSource
    DataSet = unqryProveedores
    Left = 712
    Top = 80
  end
  object unqryTiposIVA: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_ivas_tipos'
      
        '  (CODIGO_ABREVIATURA_TIPO_IVA, NOMBRE_TIPO_IVA, INSTANTEMODIF, ' +
        'INSTANTEALTA, USUARIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_ABREVIATURA_TIPO_IVA, :NOMBRE_TIPO_IVA, :INSTANTEMODI' +
        'F, :INSTANTEALTA, :USUARIOALTA, :USUARIOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR`'
      
        ' AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTI' +
        'CULO`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PROVEEDOR`' +
        ', '
      '  `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ARTICULO`, '
      
        '  `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES` = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES` = :`FECHA_VALIDEZ`, '
      '  `INSTANTEMODIF` = :`INSTANTEMODIF`, '
      '  `INSTANTEALTA` = :`INSTANTEALTA`, '
      '  `USUARIOALTA` = :`USUARIOALTA`, '
      '  `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES`, '
      '       `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES`, '
      '       `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES`, '
      '       `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES`, '
      '       `INSTANTEMODIF`, '
      '       `INSTANTEALTA`, '
      '       `USUARIOALTA`, '
      '       `USUARIOMODIF` '
      'FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PROVEEDOR`' +
        ' '
      'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ARTICULO`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ivas_tipos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from fza_ivas_tipos')
    ReadOnly = True
    Left = 824
    Top = 16
  end
  object dsTiposIVA: TDataSource
    DataSet = unqryTiposIVA
    Left = 824
    Top = 80
  end
  object unqryTarifas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_ivas_tipos'
      
        '  (CODIGO_ABREVIATURA_TIPO_IVA, NOMBRE_TIPO_IVA, INSTANTEMODIF, ' +
        'INSTANTEALTA, USUARIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_ABREVIATURA_TIPO_IVA, :NOMBRE_TIPO_IVA, :INSTANTEMODI' +
        'F, :INSTANTEALTA, :USUARIOALTA, :USUARIOMODIF)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR`'
      
        ' AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTI' +
        'CULO`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PROVEEDOR`' +
        ', '
      '  `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ARTICULO`, '
      
        '  `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES` = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES` = :`FECHA_VALIDEZ`, '
      '  `INSTANTEMODIF` = :`INSTANTEMODIF`, '
      '  `INSTANTEALTA` = :`INSTANTEALTA`, '
      '  `USUARIOALTA` = :`USUARIOALTA`, '
      '  `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES`, '
      '       `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES`, '
      '       `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES`, '
      '       `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES`, '
      '       `INSTANTEMODIF`, '
      '       `INSTANTEALTA`, '
      '       `USUARIOALTA`, '
      '       `USUARIOMODIF` '
      'FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PROVEEDOR`' +
        ' '
      'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ARTICULO`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ivas_tipos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_TARIFA, NOMBRE_TARIFA, ESDEFAULT_TARIFA '
      'FROM fza_tarifas '
      'WHERE CODIGO_TARIFA NOT IN ( SELECT CODIGO_TARIFA '
      '                               FROM fza_articulos_tarifas '
      
        '                              WHERE CODIGO_ARTICULO_TARIFA = :CO' +
        'DIGO_ARTICULO)'
      'AND ACTIVO_TARIFA ='#39'S'#39
      'ORDER BY ORDEN_TARIFA')
    ReadOnly = True
    Left = 928
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_ARTICULO'
        Value = nil
      end>
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 928
    Top = 80
  end
  object unqryVariaciones: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_variaciones')
    Left = 48
    Top = 136
  end
  object dsVariaciones: TDataSource
    DataSet = unqryVariaciones
    Left = 48
    Top = 192
  end
  object unqryVariacionesArticulos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_variaciones_def'
      
        '  (CODIGO_VARIACION_VARIACION, CODIGO_VARIACION, CODIGO_ARTICULO' +
        '_VARIACION, CODIGO_COLUMNA_VARIACION, CODIGO_UNIDAD_VARIACION, C' +
        'ODIGO_UNICO_UNIDAD_VARIACION, VALOR_VARIACION, VALOR2_VARIACION,' +
        ' INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF)'
      'VALUES'
      
        '  (:CODIGO_VARIACION_VARIACION, :CODIGO_VARIACION, :CODIGO_ARTIC' +
        'ULO_VARIACION, :CODIGO_COLUMNA_VARIACION, :CODIGO_UNIDAD_VARIACI' +
        'ON, :CODIGO_UNICO_UNIDAD_VARIACION, :VALOR_VARIACION, :VALOR2_VA' +
        'RIACION, :INSTANTEMODIF, :INSTANTEALTA, :USUARIOALTA, :USUARIOMO' +
        'DIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_variaciones_def'
      'WHERE'
      '  CODIGO_UNIDAD_VARIACION = :Old_CODIGO_UNIDAD_VARIACION')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_variaciones_def'
      'SET'
      
        '  CODIGO_VARIACION_VARIACION = :CODIGO_VARIACION_VARIACION, CODI' +
        'GO_VARIACION = :CODIGO_VARIACION, CODIGO_ARTICULO_VARIACION = :C' +
        'ODIGO_ARTICULO_VARIACION, CODIGO_COLUMNA_VARIACION = :CODIGO_COL' +
        'UMNA_VARIACION, CODIGO_UNIDAD_VARIACION = :CODIGO_UNIDAD_VARIACI' +
        'ON, CODIGO_UNICO_UNIDAD_VARIACION = :CODIGO_UNICO_UNIDAD_VARIACI' +
        'ON, VALOR_VARIACION = :VALOR_VARIACION, VALOR2_VARIACION = :VALO' +
        'R2_VARIACION, INSTANTEMODIF = :INSTANTEMODIF, INSTANTEALTA = :IN' +
        'STANTEALTA, USUARIOALTA = :USUARIOALTA, USUARIOMODIF = :USUARIOM' +
        'ODIF'
      'WHERE'
      '  CODIGO_UNIDAD_VARIACION = :Old_CODIGO_UNIDAD_VARIACION')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_variaciones_def'
      'WHERE'
      '  CODIGO_UNIDAD_VARIACION = :Old_CODIGO_UNIDAD_VARIACION'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_VARIACION_VARIACION, CODIGO_VARIACION, CODIGO_ARTI' +
        'CULO_VARIACION, CODIGO_COLUMNA_VARIACION, CODIGO_UNIDAD_VARIACIO' +
        'N, CODIGO_UNICO_UNIDAD_VARIACION, VALOR_VARIACION, VALOR2_VARIAC' +
        'ION, INSTANTEMODIF, INSTANTEALTA, USUARIOALTA, USUARIOMODIF FROM' +
        ' fza_articulos_variaciones_def'
      'WHERE'
      '  CODIGO_UNIDAD_VARIACION = :CODIGO_UNIDAD_VARIACION')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_variaciones_def')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_variaciones_articulos')
    Left = 136
    Top = 136
  end
  object dsVariacionesArticulos: TDataSource
    DataSet = unqryVariacionesArticulos
    Left = 136
    Top = 192
  end
end
