inherited dmDevolucionesCompra: TdmDevolucionesCompra
  Height = 480
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    UpdatingTable = 'fza_devoluciones_compra'
    KeyFields = 'NUMERO_DEVC;SERIE_DEVC'
    SQL.Strings = (
      'SELECT D.*,'
      '       COALESCE(R.TOTAL_PRENDAS_DEVC, 0) AS TOTAL_PRENDAS_DEVC'
      '  FROM fza_devoluciones_compra D'
      '  LEFT JOIN ('
      '    SELECT L.SERIE_DEVC_DEVCLIN, L.NUMERO_DEVC_DEVCLIN,'
      '           SUM(COALESCE(L.TOTAL_UNIDADES_DEVCLIN,'
      '                        L.CANTIDAD_DEVCLIN, 0)) AS TOTAL_PRENDAS_DEVC'
      '      FROM fza_devoluciones_compra_lineas L'
      '     GROUP BY L.SERIE_DEVC_DEVCLIN, L.NUMERO_DEVC_DEVCLIN'
      '  ) R'
      '    ON R.SERIE_DEVC_DEVCLIN = D.SERIE_DEVC'
      '   AND R.NUMERO_DEVC_DEVCLIN = D.NUMERO_DEVC'
      ' ORDER BY D.INSTANTE_MOVIMIENTO_DEVC DESC, D.NUMERO_DEVC DESC')
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 48
    Top = 24
  end
  object unqryDevolucionesCompraLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_devoluciones_compra_lineas'
      ' WHERE NUMERO_DEVC_DEVCLIN = :NUMERO_DEVC'
      '   AND SERIE_DEVC_DEVCLIN  = :SERIE_DEVC'
      ' ORDER BY LINEA_DEVCLIN')
    MasterFields = 'NUMERO_DEVC;SERIE_DEVC'
    DetailFields = 'NUMERO_DEVC_DEVCLIN;SERIE_DEVC_DEVCLIN'
    AfterInsert = unqryDevolucionesCompraLineasAfterInsert
    BeforePost = unqryDevolucionesCompraLineasBeforePost
    AfterPost = unqryDevolucionesCompraLineasAfterPost
    AfterDelete = unqryDevolucionesCompraLineasAfterDelete
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_DEVC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_DEVC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsDevolucionesCompraLineas: TDataSource
    DataSet = unqryDevolucionesCompraLineas
    Left = 520
    Top = 72
  end
  object unqryEmpDataDevc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_empresas')
    Left = 48
    Top = 192
  end
  object unqryPrvDataDevc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_proveedores ORDER BY CODIGO_PRV_PRV')
    Left = 48
    Top = 248
  end
  object dsPrvDataDevc: TDataSource
    DataSet = unqryPrvDataDevc
    Left = 112
    Top = 248
  end
  object unqryArtDataLinDevc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_articulos')
    Left = 48
    Top = 304
  end
  object unqrySkusDevc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIDAD_SKU, CODIGO_ART_SKU '
      '  FROM fza_articulos_skus '
      ' WHERE CODIGO_UNIDAD_SKU = :pSKU')
    Left = 48
    Top = 360
    ParamData = <
      item
        DataType = ftString
        Name = 'pSKU'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryAlmacenesDevc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      '   AND (CODIGO_EMP_ALM = :EMPRESA OR :EMPRESA = '#39#39')'
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM')
    Left = 160
    Top = 360
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlmacenesDevc: TDataSource
    DataSet = unqryAlmacenesDevc
    Left = 160
    Top = 424
  end
  object unqryMovimientosProveedor: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT NUMERO_MOV, FECHA_MOV, LINEA_MOV, '
      '       CODIGO_ALM_MOV, NOMBRE_ALMACEN_ORIGEN, '
      '       CODIGO_ART_MOV, CODIGO_UNIDAD_MOV, '
      '       DESCRIPCION_ARTICULO_MOV, '
      '       TIPO_MOV, CANTIDAD_MOV, '
      '       PRECIO_MEDIO_MOV, TOTAL_COSTE_MOV '
      '  FROM vi_movimientos '
      ' WHERE TIPO_DOC_MOV   = '#39'DC'#39' '
      '   AND NUMERO_DOC_MOV = :NUMERO_DEVC '
      '   AND SERIE_DOC_MOV  = :SERIE_DEVC '
      ' ORDER BY LINEA_MOV')
    MasterFields = 'NUMERO_DEVC;SERIE_DEVC'
    ReadOnly = True
    Left = 256
    Top = 360
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_DEVC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_DEVC'
        Value = nil
      end>
  end
  object dsMovimientosProveedor: TDataSource
    DataSet = unqryMovimientosProveedor
    Left = 256
    Top = 424
  end
  object unstrdprcGetContadorDevc: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
  end
  object unqryDefArticuloDevc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT NOMBRE_ATRIBUTO, ORDEN_VISUAL_ATRIBUTO '
      '  FROM vi_atributos_nombres '
      ' WHERE CODIGO_ART_PADRE_ARTVIN = :ARTICULO '
      ' ORDER BY ORDEN_VISUAL_ATRIBUTO')
    Left = 256
    Top = 96
    ParamData = <
      item
        DataType = ftString
        Name = 'ARTICULO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryCabDevcPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT V.*,'
      '       D.TOTAL_BRUTO_DEVC AS TOTAL_BRUTO_DEVC_PRINT,'
      '       D.PORCENTAJE_DTO_COMERCIAL_DEVC AS PORCENTAJE_DTO_COMERCIAL_DEVC_PRINT,'
      '       D.TOTAL_DTO_COMERCIAL_DEVC AS TOTAL_DTO_COMERCIAL_DEVC_PRINT,'
      '       D.PORCENTAJE_DTO_FINANCIERO_DEVC AS PORCENTAJE_DTO_FINANCIERO_DEVC_PRINT,'
      '       D.TOTAL_DTO_FINANCIERO_DEVC AS TOTAL_DTO_FINANCIERO_DEVC_PRINT'
      '  FROM vi_devoluciones_compra_cab_print V'
      '  LEFT JOIN fza_devoluciones_compra D'
      '    ON D.SERIE_DEVC = V.SERIE_DEVC'
      '   AND D.NUMERO_DEVC = V.NUMERO_DEVC'
      ' WHERE V.SERIE_DEVC = :SERIE_DEVC'
      '   AND V.NUMERO_DEVC = :NUMERO_DEVC')
    Left = 360
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_DEVC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_DEVC'
        Value = nil
      end>
  end
  object dsCabDevcPrint: TDataSource
    DataSet = unqryCabDevcPrint
    Left = 360
    Top = 64
  end
  object fxdsCabDevc: TfrxDBDataset
    UserName = 'Devolucion'
    CloseDataSource = False
    DataSource = dsCabDevcPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 360
    Top = 104
  end
  object unqryLinDevcPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_devoluciones_compra_lin_print'
      'WHERE SERIE_DEVC = :SERIE_DEVC'
      '  AND NUMERO_DEVC = :NUMERO_DEVC'
      'ORDER BY CODIGO_ART, COLOR_TEXTO, LINEA_DEVC')
    Left = 456
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_DEVC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_DEVC'
        Value = nil
      end>
  end
  object dsLinDevcPrint: TDataSource
    DataSet = unqryLinDevcPrint
    Left = 456
    Top = 64
  end
  object fxdsLinDevc: TfrxDBDataset
    UserName = 'LineasDevolucion'
    CloseDataSource = False
    DataSource = dsLinDevcPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 456
    Top = 104
  end
  object unqryGuiasDevcPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT'
      '  g.ID_AC, g.NOMBRE_CORTO_AC, g.NOMBRE_AC,'
      '  g.T01, g.T02, g.T03, g.T04, g.T05,'
      '  g.T06, g.T07, g.T08, g.T09, g.T10,'
      '  g.T11, g.T12, g.T13, g.T14, g.T15,'
      '  g.T16, g.T17, g.T18, g.T19, g.T20'
      'FROM vi_devoluciones_compra_guias_print g'
      'WHERE g.ID_AC IN ('
      '  SELECT L.ID_AC_PIVOT_DEVCLIN'
      '    FROM fza_devoluciones_compra_lineas L'
      '   WHERE L.SERIE_DEVC_DEVCLIN  = :SERIE_DEVC'
      '     AND L.NUMERO_DEVC_DEVCLIN = :NUMERO_DEVC'
      '     AND L.ID_AC_PIVOT_DEVCLIN IS NOT NULL'
      ')'
      'ORDER BY g.NOMBRE_CORTO_AC, g.ID_AC')
    Left = 552
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_DEVC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_DEVC'
        Value = nil
      end>
  end
  object dsGuiasDevcPrint: TDataSource
    DataSet = unqryGuiasDevcPrint
    Left = 552
    Top = 64
  end
  object fxdsGuiasDevc: TfrxDBDataset
    UserName = 'GuiasTallas'
    CloseDataSource = False
    DataSource = dsGuiasDevcPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 552
    Top = 104
  end
  object unqryLinDevcSkuPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT L.*'
      '  FROM fza_devoluciones_compra_lineas L'
      ' WHERE L.SERIE_DEVC_DEVCLIN = :SERIE_DEVC'
      '   AND L.NUMERO_DEVC_DEVCLIN = :NUMERO_DEVC'
      ' ORDER BY L.LINEA_DEVCLIN')
    Left = 648
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_DEVC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_DEVC'
        Value = nil
      end>
  end
  object dsLinDevcSkuPrint: TDataSource
    DataSet = unqryLinDevcSkuPrint
    Left = 648
    Top = 64
  end
  object fxdsLinDevcSku: TfrxDBDataset
    UserName = 'LineasDevolucionSku'
    CloseDataSource = False
    DataSource = dsLinDevcSkuPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 648
    Top = 104
  end
end
