inherited dmArticulos: TdmArticulos
  Height = 459
  Width = 1129
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos`'
      
        '  (`CODIGO_ART_ART`, `ESACTIVO_ART`, `ORDEN_ART`, `DESCRIPCION_A' +
        'RT`, `CODIGO_FAM_ART`, `TIPO_IVA_ART`, `ESACTIVO_FIJO_ART`, `TIP' +
        'O_CANTIDAD_ART`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALT' +
        'A`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`CODIGO_ART_ART`, :`ESACTIVO_ART`, :`ORDEN_ART`, :`DESCRIPCI' +
        'ON_ART`, :`CODIGO_FAM_ART`, :`TIPO_IVA_ART`, :`ESACTIVO_FIJO_ART' +
        '`, :`TIPO_CANTIDAD_ART`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`' +
        'USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`Old_CODIGO_ART_ART`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos`'
      'SET'
      
        '  `CODIGO_ART_ART` = :`CODIGO_ART_ART`, `ESACTIVO_ART` = :`ESACT' +
        'IVO_ART`, `ORDEN_ART` = :`ORDEN_ART`, `DESCRIPCION_ART` = :`DESC' +
        'RIPCION_ART`, `CODIGO_FAM_ART` = :`CODIGO_FAM_ART`, `TIPO_IVA_AR' +
        'T` = :`TIPO_IVA_ART`, `ESACTIVO_FIJO_ART` = :`ESACTIVO_FIJO_ART`' +
        ', `TIPO_CANTIDAD_ART` = :`TIPO_CANTIDAD_ART`, `INSTANTE_MODIF` =' +
        ' :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO' +
        '_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`Old_CODIGO_ART_ART`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos'
      'WHERE'
      '  `CODIGO_ART_ART` = :`Old_CODIGO_ART_ART`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `CODIGO_ART_ART`, `ESACTIVO_ART`, `ORDEN_ART`, `DESCRIPCI' +
        'ON_ART`, `CODIGO_FAM_ART`, `TIPO_IVA_ART`, `ESACTIVO_FIJO_ART`, ' +
        '`TIPO_CANTIDAD_ART`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO' +
        '_ALTA`, `USUARIO_MODIF` FROM `fza_articulos`'
      'WHERE'
      '  `CODIGO_ART_ART` = :`CODIGO_ART_ART`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_articulos '
      '')
    Active = True
    BeforeInsert = nil
    AfterInsert = unqryTablaGAfterInsert
    AfterDelete = unqryTablaGAfterDelete
    Left = 48
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_USUPER = Nothing)')
    Left = 136
  end
  inherited dsPerfiles: TDataSource
    Left = 136
  end
  object unqryFamiliaArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_familias_list')
    Left = 448
    Top = 176
  end
  object dsFamiliaArticulos: TDataSource
    DataSet = unqryFamiliaArticulos
    Left = 448
    Top = 256
  end
  object unqryTarifasArticulos: TUniQuery
    KeyFields = 'CODIGO_UNICO_ARTTAR'
    SQLInsert.Strings = (
      'INSERT INTO FZA_articulos_tarifas'
      
        '  (CODIGO_ART_ARTTAR, CODIGO_UNICO_ARTTAR, CODIGO_UNIDAD_ARTTAR,' +
        ' CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECI' +
        'O_FINAL_ARTTAR, PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, FECHA_' +
        'DESDE_ARTTAR, FECHA_HASTA_ARTTAR, INSTANTE_MODIF, INSTANTE_ALTA,' +
        ' USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ART_ARTTAR, :CODIGO_UNICO_ARTTAR, :CODIGO_UNIDAD_ARTT' +
        'AR, :CODIGO_TAR_ARTTAR, :ESACTIVO_ARTTAR, :PRECIO_SALIDA_ARTTAR,' +
        ' :PRECIO_FINAL_ARTTAR, :PRECIO_DTO_ARTTAR, :PORCENTAJE_DTO_ARTTA' +
        'R, :FECHA_DESDE_ARTTAR, :FECHA_HASTA_ARTTAR, :INSTANTE_MODIF, :I' +
        'NSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM FZA_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :Old_CODIGO_UNICO_ARTTAR')
    SQLUpdate.Strings = (
      'UPDATE FZA_articulos_tarifas'
      'SET'
      
        '  CODIGO_ART_ARTTAR = :CODIGO_ART_ARTTAR, CODIGO_UNICO_ARTTAR = ' +
        ':CODIGO_UNICO_ARTTAR, CODIGO_UNIDAD_ARTTAR = :CODIGO_UNIDAD_ARTT' +
        'AR, CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR = :E' +
        'SACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR = :PRECIO_SALIDA_ARTTAR, PR' +
        'ECIO_FINAL_ARTTAR = :PRECIO_FINAL_ARTTAR, PRECIO_DTO_ARTTAR = :P' +
        'RECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR = :PORCENTAJE_DTO_ARTTAR' +
        ', FECHA_DESDE_ARTTAR = :FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR =' +
        ' :FECHA_HASTA_ARTTAR, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE' +
        '_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MO' +
        'DIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :Old_CODIGO_UNICO_ARTTAR')
    SQLLock.Strings = (
      
        'SELECT CODIGO_ART_ARTTAR, CODIGO_UNICO_ARTTAR, CODIGO_UNIDAD_ART' +
        'TAR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, P' +
        'RECIO_FINAL_ARTTAR, PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, FE' +
        'CHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR, INSTANTE_MODIF, INSTANTE_A' +
        'LTA, USUARIO_ALTA, USUARIO_MODIF FROM FZA_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :Old_CODIGO_UNICO_ARTTAR'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ART_ARTTAR, CODIGO_UNICO_ARTTAR, CODIGO_UNIDAD_ART' +
        'TAR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, P' +
        'RECIO_FINAL_ARTTAR, PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, FE' +
        'CHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR, INSTANTE_MODIF, INSTANTE_A' +
        'LTA, USUARIO_ALTA, USUARIO_MODIF FROM FZA_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :CODIGO_UNICO_ARTTAR')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM FZA_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_tarifas')
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_ARTTAR'
    Active = True
    BeforePost = unqryTarifasArticulosBeforePost
    Left = 384
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = ''
      end>
  end
  object dsTarifasArticulos: TDataSource
    DataSet = unqryTarifasArticulos
    Left = 392
    Top = 80
  end
  object unqryProveedoresArticulos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos_proveedores`'
      '      (`CODIGO_PRV_AP`, '
      '       `CODIGO_ART_AP`, '
      '       `PRECIO_ULT_COMPRA_AP`, '
      '       `FECHA_VALIDEZ_AP`, '
      '       `ESPROVEEDORPRINCIPAL_AP`,'
      '       `INSTANTE_MODIF`, '
      '       `INSTANTE_ALTA`, '
      '       `USUARIO_ALTA`, '
      '       `USUARIO_MODIF`)'
      'VALUES'
      '      (:`CODIGO_PRV_PRV`, '
      '       :`CODIGO_ART_ART`, '
      '       :`PRECIO_ULT_COMPRA`, '
      '       :`FECHA_VALIDEZ`, '
      '       :`ESPROVEEDORPRINCIPAL`,'
      '       :`INSTANTE_MODIF`, '
      '       :`INSTANTE_ALTA`, '
      '       :`USUARIO_ALTA`, '
      '       :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_proveedores'
      'WHERE'
      '  CODIGO_PRV_AP = :Old_CODIGO_PRV_PRV'
      '  AND CODIGO_ART_AP = :Old_CODIGO_ART_ART')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_proveedores'
      'SET'
      '  CODIGO_PRV_AP           = :CODIGO_PRV_PRV,'
      '  CODIGO_ART_AP           = :CODIGO_ART_ART,'
      '  PRECIO_ULT_COMPRA_AP    = :PRECIO_ULT_COMPRA,'
      '  FECHA_VALIDEZ_AP        = :FECHA_VALIDEZ,'
      '  ESPROVEEDORPRINCIPAL_AP = :ESPROVEEDORPRINCIPAL,'
      '  INSTANTE_MODIF          = :INSTANTE_MODIF,'
      '  INSTANTE_ALTA           = :INSTANTE_ALTA,'
      '  USUARIO_ALTA            = :USUARIO_ALTA,'
      '  USUARIO_MODIF           = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_PRV_AP = :Old_CODIGO_PRV_PRV'
      '  AND CODIGO_ART_AP = :Old_CODIGO_ART_ART')
    SQLLock.Strings = (
      'SELECT *'
      '  FROM fza_articulos_proveedores'
      ' WHERE'
      '       CODIGO_PRV_AP = :Old_CODIGO_PRV_PRV'
      '   AND CODIGO_ART_AP = :Old_CODIGO_ART_ART'
      '   FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT *'
      '  FROM vi_articulos_proveedores'
      'WHERE'
      '      `CODIGO_PRV_AP` = :`CODIGO_PRV_PRV` '
      '  AND `CODIGO_ART_AP`  = :`CODIGO_ART_ART`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_proveedores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_proveedores')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_ART'
    Active = True
    BeforePost = unqryProveedoresArticulosBeforePost
    Left = 504
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'BOLSO-PIEL'
      end>
  end
  object dsProveedoresArticulos: TDataSource
    DataSet = unqryProveedoresArticulos
    Left = 496
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
      'from vi_fac_lin_busquedas l'
      'INNER JOIN vi_fac_busquedas f'
      'ON l.NUMERO_FAC_FACLIN = f.NUMERO_FAC'
      'AND l.SERIE_FAC_FACLIN = f.SERIE_FAC')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_FACLIN'
    Active = True
    BeforePost = unqryPerfilesBeforePost
    Left = 656
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'BOLSO-PIEL'
      end>
  end
  object dsLinFacturasArticulos: TDataSource
    DataSet = unqryLinFacturasArticulos
    Left = 656
    Top = 80
  end
  object unqryProveedores: TUniQuery
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES`'
      
        ' AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTI' +
        'CULO_ARTICULOS_PROVEEDORES`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PRV_PRV`, '
      '  `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ART_ART`, '
      
        '  `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES` = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES` = :`FECHA_VALIDEZ`, '
      '  `INSTANTE_MODIF` = :`INSTANTE_MODIF`, '
      '  `INSTANTE_ALTA` = :`INSTANTE_ALTA`, '
      '  `USUARIO_ALTA` = :`USUARIO_ALTA`, '
      '  `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO_ARTICULOS_PROVEEDORES`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO_ARTICULOS_PROVEEDORES`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES`, '
      '       `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES`, '
      '       `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES`, '
      '       `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES`, '
      '       `INSTANTE_MODIF`, '
      '       `INSTANTE_ALTA`, '
      '       `USUARIO_ALTA`, '
      '       `USUARIO_MODIF` '
      'FROM `fza_articulos_proveedores`'
      'WHERE'
      '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PRV_PRV` '
      'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ART_ART`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_proveedores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_proveedores')
    Left = 768
    Top = 16
  end
  object dsProveedores: TDataSource
    DataSet = unqryProveedores
    Left = 768
    Top = 80
  end
  object unqryTiposIVA: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_ivas_tipos'
      
        '  (CODIGO_ABREVIATURA_IVA_IVATIP, NOMBRE_TIPO_IVA_IVATIP, INSTAN' +
        'TE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ABREVIATURA_IVA_IVATIP, :NOMBRE_TIPO_IVA_IVATIP, :INS' +
        'TANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES`'
      
        ' AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTI' +
        'CULO_ARTICULOS_PROVEEDORES`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PRV_PRV`, '
      '  `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ART_ART`, '
      
        '  `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES` = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES` = :`FECHA_VALIDEZ`, '
      '  `INSTANTE_MODIF` = :`INSTANTE_MODIF`, '
      '  `INSTANTE_ALTA` = :`INSTANTE_ALTA`, '
      '  `USUARIO_ALTA` = :`USUARIO_ALTA`, '
      '  `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO_ARTICULOS_PROVEEDORES`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO_ARTICULOS_PROVEEDORES`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES`, '
      '       `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES`, '
      '       `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES`, '
      '       `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES`, '
      '       `INSTANTE_MODIF`, '
      '       `INSTANTE_ALTA`, '
      '       `USUARIO_ALTA`, '
      '       `USUARIO_MODIF` '
      'FROM `fza_articulos_proveedores`'
      'WHERE'
      '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PRV_PRV` '
      'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ART_ART`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ivas_tipos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from fza_ivas_tipos')
    ReadOnly = True
    Left = 880
    Top = 16
  end
  object dsTiposIVA: TDataSource
    DataSet = unqryTiposIVA
    Left = 880
    Top = 80
  end
  object unqryTarifas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_ivas_tipos'
      
        '  (CODIGO_ABREVIATURA_IVA_IVATIP, NOMBRE_TIPO_IVA_IVATIP, INSTAN' +
        'TE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ABREVIATURA_IVA_IVATIP, :NOMBRE_TIPO_IVA_IVATIP, :INS' +
        'TANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_proveedores`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES`'
      
        ' AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTI' +
        'CULO_ARTICULOS_PROVEEDORES`')
    SQLUpdate.Strings = (
      'UPDATE `fza_articulos_proveedores`'
      'SET'
      '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PRV_PRV`, '
      '  `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ART_ART`, '
      
        '  `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES` = :`PRECIO_ULT_COMPR' +
        'A`, '
      '  `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES` = :`FECHA_VALIDEZ`, '
      '  `INSTANTE_MODIF` = :`INSTANTE_MODIF`, '
      '  `INSTANTE_ALTA` = :`INSTANTE_ALTA`, '
      '  `USUARIO_ALTA` = :`USUARIO_ALTA`, '
      '  `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO_ARTICULOS_PROVEEDORES`')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE'
      
        '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_PROVEE' +
        'DOR_ARTICULOS_PROVEEDORES` '
      
        'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`Old_CODIGO_ARTIC' +
        'ULO_ARTICULOS_PROVEEDORES`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES`, '
      '       `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES`, '
      '       `PRECIO_ULT_COMPRA_ARTICULOS_PROVEEDORES`, '
      '       `FECHA_VALIDEZ_ARTICULOS_PROVEEDORES`, '
      '       `INSTANTE_MODIF`, '
      '       `INSTANTE_ALTA`, '
      '       `USUARIO_ALTA`, '
      '       `USUARIO_MODIF` '
      'FROM `fza_articulos_proveedores`'
      'WHERE'
      '  `CODIGO_PROVEEDOR_ARTICULOS_PROVEEDORES` = :`CODIGO_PRV_PRV` '
      'AND `CODIGO_ARTICULO_ARTICULOS_PROVEEDORES` = :`CODIGO_ART_ART`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ivas_tipos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR, ESDEFAULT_TAR '
      'FROM fza_tarifas '
      'WHERE CODIGO_TAR_ARTTAR NOT IN ( SELECT CODIGO_TAR_ARTTAR '
      '                               FROM fza_articulos_tarifas '
      
        '                              WHERE CODIGO_ART_ARTTAR = :CODIGO_' +
        'ART_ART)'
      'AND ESACTIVO_ARTTAR ='#39'S'#39
      'ORDER BY ORDEN_TAR')
    ReadOnly = True
    Left = 984
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_ART_ART'
        Value = nil
      end>
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 984
    Top = 80
  end
  object unqryVariaciones: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_variaciones')
    Active = True
    Left = 288
    Top = 176
  end
  object dsVariaciones: TDataSource
    DataSet = unqryVariaciones
    Left = 288
    Top = 264
  end
  object unqryVariacionesArticulos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_codigos_barras'
      '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB,'
      '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      '  (:CODIGO_BARRAS_CB, :CODIGO_UNIDAD_SKU,'
      '   COALESCE(NULLIF(:TIPO_CODIGO_CB, ''''), ''EAN13''),'
      '   COALESCE(NULLIF(:ESPRINCIPAL_CB, ''''), ''N''),'
      '   CURRENT_TIMESTAMP, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_codigos_barras'
      'WHERE ID_CB = :Old_ID_CB')
    SQLUpdate.Strings = (
      'UPDATE fza_codigos_barras'
      'SET'
      '  CODIGO_BARRAS_CB = :CODIGO_BARRAS_CB,'
      '  TIPO_CODIGO_CB = COALESCE(NULLIF(:TIPO_CODIGO_CB, ''''), ''EAN13''),'
      '  ESPRINCIPAL_CB = COALESCE(NULLIF(:ESPRINCIPAL_CB, ''''), ''N''),'
      '  USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE ID_CB = :Old_ID_CB')
    SQLLock.Strings = (
      'SELECT * FROM fza_codigos_barras'
      'WHERE ID_CB = :Old_ID_CB'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM vi_articulos_skus_extendida'
      'WHERE ID_CB = :ID_CB')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM vi_articulos_skus_extendida')
    BeforePost = unqryVariacionesArticulosBeforePost
    BeforeDelete = unqryVariacionesArticulosBeforeDelete
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_skus_extendida')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_SKU'
    Active = True
    Left = 144
    Top = 216
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'BOLSO-PIEL'
      end>
  end
  object dsVariacionesArticulos: TDataSource
    DataSet = unqryVariacionesArticulos
    Left = 144
    Top = 296
  end
  object unqryStockArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'CALL '
      'PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ(:CODIGO_ART_ART)')
    ReadOnly = True
    Active = True
    Left = 888
    Top = 176
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'ZAP-OXFORD'
      end>
  end
  object dsStockArticulos: TDataSource
    DataSet = unqryStockArticulos
    Left = 888
    Top = 256
  end
  object unqryMovimientosArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM '
      'vi_movimientos')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_MOV'
    ReadOnly = True
    Active = True
    Left = 744
    Top = 184
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'BOLSO-PIEL'
      end>
  end
  object dsMovimientosArticulos: TDataSource
    DataSet = unqryMovimientosArticulos
    Left = 744
    Top = 264
  end
  object unqryDetallesAtributos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_variaciones_def'
      
        '  (CODIGO_VARIACION_VARIACION, CODIGO_VARIACION, CODIGO_ARTICULO' +
        '_VARIACION, CODIGO_COLUMNA_VARIACION, CODIGO_UNIDAD_VARIACION, C' +
        'ODIGO_UNICO_UNIDAD_VARIACION, VALOR_VARIACION, VALOR2_VARIACION,' +
        ' INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_VARIACION_VARIACION, :CODIGO_VARIACION, :CODIGO_ARTIC' +
        'ULO_VARIACION, :CODIGO_COLUMNA_VARIACION, :CODIGO_UNIDAD_VARIACI' +
        'ON, :CODIGO_UNICO_UNIDAD_VARIACION, :VALOR_VARIACION, :VALOR2_VA' +
        'RIACION, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARI' +
        'O_MODIF)')
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
        'R2_VARIACION, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = ' +
        ':INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :U' +
        'SUARIO_MODIF'
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
        'ION, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF ' +
        'FROM fza_articulos_variaciones_def'
      'WHERE'
      '  CODIGO_UNIDAD_VARIACION = :CODIGO_UNIDAD_VARIACION')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_variaciones_def')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT '
      '    sku.CODIGO_ART_SKU,'
      '    sku.CODIGO_UNIDAD_SKU,'
      
        '    val.ID_VA_AV AS ATRIBUTO,        -- Ej: '#39'CO'#39' (Color) o '#39'TAL'#39 +
        ' (Talla)'
      '    val.AV AS VALOR_INTERNO,   -- Ej: '#39'ROJO'#39
      '    inf.CLAVE_AVI AS META_CLAVE,    -- Ej: '#39'COLOR_PROVEEDOR'#39
      '    inf.VALOR_AVI AS META_VALOR     -- Ej: '#39'RED-01'#39
      'FROM fza_articulos_skus sku'
      
        '-- 1. Enlazamos con la tabla intermedia para saber qu'#233' valores c' +
        'omponen el SKU'
      'INNER JOIN fza_atributos_sku rel '
      '    ON sku.CODIGO_UNIDAD_SKU = rel.CODIGO_UNIDAD_SKU_SA'
      
        '-- 2. Enlazamos con la tabla maestra de valores para sacar el no' +
        'mbre del valor'
      'INNER JOIN fza_atributos_valores val '
      '    ON rel.ID_AV_SA = val.ID_AV'
      '-- 3. Enlazamos con tu tabla detalle de informaci'#243'n extra'
      'LEFT JOIN fza_atributos_valores_info inf '
      '    ON val.ID_AV = inf.ID_AV_AVI;')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_SKU'
    Left = 1040
    Top = 184
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'ZAP-OXFORD'
      end>
  end
  object dsDetallesAtributos: TDataSource
    DataSet = unqryDetallesAtributos
    Left = 1040
    Top = 264
  end
end
