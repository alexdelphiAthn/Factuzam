inherited dmArticulos: TdmArticulos
  Height = 665
  Width = 1640
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_articulos`'
      
        '  (`CODIGO_ART_ART`, `ESACTIVO_ART`, `ORDEN_ART`, `DESCRIPCION_A' +
        'RT`, `CODIGO_FAM_ART`, `TIPO_IVA_ART`, `ESACTIVO_FIJO_ART`, `TIP' +
        'O_CANTIDAD_ART`, `ESVARIACION_ART`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALT' +
        'A`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`CODIGO_ART_ART`, :`ESACTIVO_ART`, :`ORDEN_ART`, :`DESCRIPCI' +
        'ON_ART`, :`CODIGO_FAM_ART`, :`TIPO_IVA_ART`, :`ESACTIVO_FIJO_ART' +
        '`, :`TIPO_CANTIDAD_ART`, :`ESVARIACION_ART`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`' +
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
        ', `TIPO_CANTIDAD_ART` = :`TIPO_CANTIDAD_ART`, `ESVARIACION_ART` = :`ESVARIACION_ART`, `INSTANTE_MODIF` =' +
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
    Active = False
    BeforeInsert = nil
    AfterInsert = unqryTablaGAfterInsert
    AfterDelete = unqryTablaGAfterDelete
    AfterPost = unqryTablaGAfterPost
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
      'from vi_articulos_tarifas_mto')
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_ARTTAR'
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
      'INSERT INTO fza_articulos_proveedores'
      '  (CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP,'
      
        '   PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ESPROVEEDORPRINCIPAL_' +
        'AP,'
      '   INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      '  (:CODIGO_PRV_PRV, :CODIGO_ART_ART, :REF_PROVEEDOR,'
      '   :PRECIO_ULT_COMPRA, :FECHA_VALIDEZ, :ESPROVEEDORPRINCIPAL,'
      
        '   :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODI' +
        'F)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_proveedores'
      'WHERE CODIGO_PRV_AP = :Old_CODIGO_PRV_PRV'
      '  AND CODIGO_ART_AP = :Old_CODIGO_ART_ART')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_proveedores SET'
      '  CODIGO_PRV_AP           = :CODIGO_PRV_PRV,'
      '  CODIGO_ART_AP           = :CODIGO_ART_ART,'
      '  REF_PROVEEDOR_AP        = :REF_PROVEEDOR,'
      '  PRECIO_ULT_COMPRA_AP    = :PRECIO_ULT_COMPRA,'
      '  FECHA_VALIDEZ_AP        = :FECHA_VALIDEZ,'
      '  ESPROVEEDORPRINCIPAL_AP = :ESPROVEEDORPRINCIPAL,'
      '  INSTANTE_MODIF          = :INSTANTE_MODIF,'
      '  INSTANTE_ALTA           = :INSTANTE_ALTA,'
      '  USUARIO_ALTA            = :USUARIO_ALTA,'
      '  USUARIO_MODIF           = :USUARIO_MODIF'
      'WHERE CODIGO_PRV_AP = :Old_CODIGO_PRV_PRV'
      '  AND CODIGO_ART_AP = :Old_CODIGO_ART_ART')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_proveedores'
      'WHERE CODIGO_PRV_AP = :Old_CODIGO_PRV_PRV'
      '  AND CODIGO_ART_AP = :Old_CODIGO_ART_ART'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM vi_articulos_proveedores'
      'WHERE CODIGO_PRV_PRV = :CODIGO_PRV_PRV'
      '  AND CODIGO_ART_ART = :CODIGO_ART_ART')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_proveedores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_proveedores')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_ART'
    BeforePost = unqryProveedoresArticulosBeforePost
    Left = 504
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'DEMO-CAMISA'
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
    BeforePost = unqryPerfilesBeforePost
    Left = 656
    Top = 16
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'DEMO-CAMISA'
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
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR '
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
      '   COALESCE(NULLIF(:TIPO_CODIGO_CB, '#39#39'), '#39'EAN13'#39'),'
      '   COALESCE(NULLIF(:ESPRINCIPAL_CB, '#39#39'), '#39'N'#39'),'
      '   CURRENT_TIMESTAMP, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_codigos_barras'
      'WHERE ID_CB = :Old_ID_CB')
    SQLUpdate.Strings = (
      'UPDATE fza_codigos_barras'
      'SET'
      '  CODIGO_BARRAS_CB = :CODIGO_BARRAS_CB,'
      
        '  TIPO_CODIGO_CB = COALESCE(NULLIF(:TIPO_CODIGO_CB, '#39#39'), '#39'EAN13'#39 +
        '),'
      '  ESPRINCIPAL_CB = COALESCE(NULLIF(:ESPRINCIPAL_CB, '#39#39'), '#39'N'#39'),'
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
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_skus_extendida')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_SKU'
    BeforePost = unqryVariacionesArticulosBeforePost
    BeforeDelete = unqryVariacionesArticulosBeforeDelete
    Left = 144
    Top = 216
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'DEMO-CAMISA'
      end>
  end
  object dsVariacionesArticulos: TDataSource
    DataSet = unqryVariacionesArticulos
    Left = 144
    Top = 296
  end
  object unqrySkus: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_skus'
      
        '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_S' +
        'KU,'
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      '  (:CODIGO_UNIDAD_SKU, :CODIGO_ART_SKU,'
      '   COALESCE(NULLIF(:CODIGO_VAR_SKU, '#39#39'), '#39'TC'#39'),'
      '   COALESCE(NULLIF(:ESACTIVO_SKU, '#39#39'), '#39'S'#39'),'
      '   CURRENT_TIMESTAMP, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_skus'
      'WHERE CODIGO_UNIDAD_SKU = :Old_CODIGO_UNIDAD_SKU')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_skus'
      'SET'
      '  ESACTIVO_SKU = :ESACTIVO_SKU,'
      '  USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE CODIGO_UNIDAD_SKU = :Old_CODIGO_UNIDAD_SKU')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_skus'
      'WHERE CODIGO_UNIDAD_SKU = :Old_CODIGO_UNIDAD_SKU'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM vi_articulos_skus_con_coste'
      'WHERE CODIGO_UNIDAD_SKU = :CODIGO_UNIDAD_SKU')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_skus_con_coste')
    MasterSource = frmMtoArticulos.dsTablaG
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_SKU'
    BeforePost = unqrySkusBeforePost
    BeforeDelete = unqrySkusBeforeDelete
    Left = 112
    Top = 416
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'DEMO-CAMISA'
      end>
  end
  object dsSkus: TDataSource
    DataSet = unqrySkus
    Left = 128
    Top = 496
  end
  object unqryStockArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'CALL '
      'PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ(:CODIGO_ART_ART)')
    ReadOnly = True
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
    Left = 744
    Top = 184
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = 'DEMO-CAMISA'
      end>
  end
  object dsMovimientosArticulos: TDataSource
    DataSet = unqryMovimientosArticulos
    Left = 744
    Top = 264
  end
  object unqryDetallesAtributos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT'
      '    CODIGO_ART_SKU,'
      '    CODIGO_UNIDAD_SKU,'
      '    CODIGO_VAR_SKU,'
      '    ID_AV,'
      '    ID_VA_AV,'
      '    NOMBRE_ATRIBUTO,'
      '    ORDEN_ATRIBUTO,'
      '    VALOR_AV,'
      '    DESCRIPCION_AV,'
      '    ID_ATB_AV,'
      '    CODIGO_ATB,'
      '    NOMBRE_ATB,'
      '    DESCRIPCION_ATB,'
      '    HEX_ATB,'
      '    VALOR_NUM_ATB,'
      '    UNIDAD_ATB,'
      '    ETIQUETA_BASICO'
      '  FROM vi_atributos_sku_basico'
      ' ORDER BY ORDEN_ATRIBUTO, ID_VA_AV')
    MasterFields = 'CODIGO_UNIDAD_SKU'
    DetailFields = 'CODIGO_UNIDAD_SKU'
    BeforePost = unqryDetallesAtributosBeforePost
    Left = 1040
    Top = 184
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_UNIDAD_SKU'
        ParamType = ptInput
        Value = ''
      end>
  end
  object unqryAtributosBasicosLookup: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_ATB, ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB,'
      '       DESCRIPCION_ATB, HEX_ATB, VALOR_NUM_ATB, UNIDAD_ATB'
      '  FROM fza_atributos_basicos'
      ' WHERE ESACTIVO_ATB = '#39'S'#39
      ' ORDER BY ID_VA_ATB, ORDEN_ATB, NOMBRE_ATB')
    Left = 1160
    Top = 184
  end
  object dsAtributosBasicosLookup: TDataSource
    DataSet = unqryAtributosBasicosLookup
    Left = 1160
    Top = 264
  end
  object unqryUnidadesMedidaLookup: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIMED, DESCRIPCION_UNIMED, DECIMALES_UNIMED'
      '  FROM fza_unidades_medida'
      ' WHERE ESACTIVO_UNIMED = '#39'S'#39
      ' ORDER BY ORDEN_UNIMED, MAGNITUD_UNIMED, CODIGO_UNIMED')
    Left = 1280
    Top = 184
  end
  object dsUnidadesMedidaLookup: TDataSource
    DataSet = unqryUnidadesMedidaLookup
    Left = 1280
    Top = 264
  end
  object dsDetallesAtributos: TDataSource
    DataSet = unqryDetallesAtributos
    Left = 1040
    Top = 264
  end
  object unqryArtPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_articulos_skus_etiquetas')
    Left = 888
    Top = 360
  end
  object dtstprvEtiquetasArt: TDataSetProvider
    DataSet = unqryArtPrint
    Constraints = False
    Options = []
    Left = 888
    Top = 448
  end
  object cdsEtiquetasArt: TClientDataSet
    Aggregates = <>
    AutoCalcFields = False
    Params = <>
    Left = 1040
    Top = 360
  end
  object dsEtiquetasArt: TDataSource
    DataSet = cdsEtiquetasArt
    Left = 1040
    Top = 448
  end
  object fxdsEtiquetasArt: TfrxDBDataset
    Description = 'EtiquetasArt'
    UserName = 'EtiquetasArt'
    CloseDataSource = False
    OpenDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 1184
    Top = 360
  end
  object unqryAlmacenesPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      ' ORDER BY COALESCE(ORDEN_ALM, 999999),'
      '          NOMBRE_ALM_ALM,'
      '          CODIGO_ALM_ALM')
    Left = 1184
    Top = 408
  end
  object unqryTarifasPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR'
      '  FROM fza_tarifas'
      ' WHERE ESACTIVO_ARTTAR = '#39'S'#39
      ' ORDER BY COALESCE(ORDEN_TAR, 999999),'
      '          NOMBRE_TAR_TAR,'
      '          CODIGO_TAR_ARTTAR')
    Left = 1184
    Top = 504
  end
end
