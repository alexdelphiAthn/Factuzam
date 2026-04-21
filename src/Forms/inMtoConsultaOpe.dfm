inherited frmConsultaOpe: TfrmConsultaOpe
  Caption = 'Buscar operaciones'
  ClientHeight = 720
  ClientWidth = 1200
  Font.Charset = ANSI_CHARSET
  Font.Height = -16
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  ExplicitLeft = 3
  ExplicitTop = -31
  ExplicitWidth = 1216
  ExplicitHeight = 759
  TextHeight = 18
  object splitter: TSplitter [0]
    Left = 0
    Top = 316
    Width = 1200
    Height = 5
    Cursor = crVSplit
    Align = alTop
  end
  object pnlFiltros: TPanel [1]
    Left = 0
    Top = 0
    Width = 1200
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 1198
    object lblFecha: TcxLabel
      Left = 12
      Top = 18
      Caption = 'Fecha:'
      TabOrder = 3
    end
    object dtpFecha: TcxDateEdit
      Left = 72
      Top = 16
      Properties.OnChange = dtpFechaPropertiesChange
      TabOrder = 0
      Width = 130
    end
    object lblBuscar: TcxLabel
      Left = 232
      Top = 18
      Caption = 'Buscar:'
      TabOrder = 4
    end
    object edtBuscar: TcxButtonEdit
      Left = 296
      Top = 16
      Properties.Buttons = <>
      Properties.OnChange = edtBuscarPropertiesChange
      TabOrder = 1
      Width = 500
    end
    object btnRefrescar: TButton
      Left = 812
      Top = 14
      Width = 173
      Height = 28
      Caption = 'Refrescar (F5)'
      TabOrder = 2
      OnClick = btnRefrescarClick
    end
  end
  object pnlMaestro: TPanel [2]
    Left = 0
    Top = 56
    Width = 1200
    Height = 260
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 1198
    object cxGridMaestro: TcxGrid
      Left = 0
      Top = 0
      Width = 1200
      Height = 260
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 1198
      object cxViewMaestro: TcxGridDBTableView
        OptionsBehavior.FocusCellOnCycle = True
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.NoDataToDisplayInfoText = 'No hay operaciones para esta fecha'
        OptionsView.ColumnAutoWidth = True
        OptionsView.GroupByBox = False
        object colFechaOp: TcxGridDBColumn
          Caption = 'Fecha/Hora'
          DataBinding.FieldName = 'FECHA_OP'
          PropertiesClassName = 'TcxDateEditProperties'
          Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
          Properties.Kind = ckDateTime
          Width = 128
        end
        object colNumOp: TcxGridDBColumn
          Caption = 'N'#186' Operaci'#243'n'
          DataBinding.FieldName = 'NUMERO_OPERACION_OPCAJA'
          Width = 118
        end
        object colTiposOp: TcxGridDBColumn
          Caption = 'Tipos'
          DataBinding.FieldName = 'TIPOS_OP'
          Width = 86
        end
        object colSerieFactura: TcxGridDBColumn
          Caption = 'Serie'
          DataBinding.FieldName = 'SERIE_FACTURA'
          Width = 78
        end
        object colNroFactura: TcxGridDBColumn
          Caption = 'N'#186' Factura'
          DataBinding.FieldName = 'NRO_FACTURA'
          Width = 97
        end
        object colCliente: TcxGridDBColumn
          Caption = 'Cliente'
          DataBinding.FieldName = 'CLIENTE'
          Width = 78
        end
        object colRazonSocial: TcxGridDBColumn
          Caption = 'Raz'#243'n social'
          DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
          Width = 182
        end
        object colImporte: TcxGridDBColumn
          Caption = 'Importe'
          DataBinding.FieldName = 'IMPORTE_TOTAL'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00 '#8364
          Width = 101
        end
        object colEmpleado: TcxGridDBColumn
          Caption = 'Empleado'
          DataBinding.FieldName = 'EMPLEADO'
          Width = 100
        end
        object colConceptos: TcxGridDBColumn
          Caption = 'Conceptos'
          DataBinding.FieldName = 'CONCEPTOS'
          Width = 230
        end
      end
      object cxLevelMaestro: TcxGridLevel
        GridView = cxViewMaestro
      end
    end
  end
  object pcHijos: TcxPageControl [3]
    Left = 0
    Top = 321
    Width = 1200
    Height = 360
    Align = alClient
    TabOrder = 2
    Properties.ActivePage = tsPagos
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 358
    ClientRectLeft = 2
    ClientRectRight = 1198
    ClientRectTop = 28
    object tsOperacion: TcxTabSheet
      Caption = 'Operaci'#243'n '
      ImageIndex = 0
      object cxGridOpe: TcxGrid
        Left = 0
        Top = 0
        Width = 1196
        Height = 330
        Align = alClient
        TabOrder = 0
        object cxViewOpe: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          object colOpeFecha: TcxGridDBColumn
            Caption = 'Fecha/Hora'
            DataBinding.FieldName = 'FECHA_OPERACION_OPCAJA'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
            Properties.Kind = ckDateTime
            Width = 140
          end
          object colOpeTipo: TcxGridDBColumn
            Caption = 'Tipo'
            DataBinding.FieldName = 'TIPO_OPERACION_OPCAJA'
            Width = 60
          end
          object colOpeImporte: TcxGridDBColumn
            Caption = 'Importe'
            DataBinding.FieldName = 'IMPORTE_TOTAL_OPCAJA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 110
          end
          object colOpeConcepto: TcxGridDBColumn
            Caption = 'Concepto'
            DataBinding.FieldName = 'CONCEPTO_GASTO_INGRESO_OPCAJA'
            Width = 340
          end
          object colOpeIdDep: TcxGridDBColumn
            Caption = 'Id dep'#243'sito'
            DataBinding.FieldName = 'ID_DEPOSITO_OPCAJA'
            Width = 160
          end
          object colOpeSerieRef: TcxGridDBColumn
            Caption = 'Serie ref.'
            DataBinding.FieldName = 'SERIE_REF_ORIGEN_OPCAJA'
            Width = 80
          end
          object colOpeNroRef: TcxGridDBColumn
            Caption = 'Nro ref.'
            DataBinding.FieldName = 'NUMERO_REF_ORIGEN_OPCAJA'
            Width = 80
          end
          object colOpeMotivo: TcxGridDBColumn
            Caption = 'Motivo dev.'
            DataBinding.FieldName = 'MOTIVO_DEVOLUCION_OPCAJA'
            Width = 130
          end
          object colOpeEstadoDev: TcxGridDBColumn
            Caption = 'Est.Dev.'
            DataBinding.FieldName = 'ESTADO_DEVOLUCION_OPCAJA'
            Width = 60
          end
        end
        object cxLevelOpe: TcxGridLevel
          GridView = cxViewOpe
        end
      end
    end
    object tsPagos: TcxTabSheet
      Caption = 'Pagos'
      ImageIndex = 1
      object cxGridPagos: TcxGrid
        Left = 0
        Top = 0
        Width = 1196
        Height = 330
        Align = alClient
        TabOrder = 0
        object cxViewPagos: TcxGridDBTableView
          DataController.Summary.FooterSummaryItems = <
            item
              Format = '#,##0.00 '#8364
              Kind = skSum
              Column = colPagNeto
            end>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.Footer = True
          OptionsView.GroupByBox = False
          object colPagLinea: TcxGridDBColumn
            Caption = 'L'#237'nea'
            DataBinding.FieldName = 'NUMERO_LINEA_PAGO'
            Width = 96
          end
          object colPagCodigo: TcxGridDBColumn
            Caption = 'C'#243'digo'
            DataBinding.FieldName = 'CODIGO_FORMAP'
            Width = 106
          end
          object colPagForma: TcxGridDBColumn
            Caption = 'Forma de pago'
            DataBinding.FieldName = 'DESCRIPCION_FORMAP'
            Width = 142
          end
          object colPagEntregado: TcxGridDBColumn
            Caption = 'Entregado'
            DataBinding.FieldName = 'IMPORTE_ENTREGADO_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 112
          end
          object colPagCambio: TcxGridDBColumn
            Caption = 'Cambio'
            DataBinding.FieldName = 'IMPORTE_CAMBIO_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 77
          end
          object colPagNeto: TcxGridDBColumn
            Caption = 'Neto'
            DataBinding.FieldName = 'IMPORTE_NETO_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 87
          end
          object colPagDivisa: TcxGridDBColumn
            Caption = 'Divisa'
            DataBinding.FieldName = 'CODIGO_DIVISA_PAGO'
            Width = 97
          end
          object colPagImpDivisa: TcxGridDBColumn
            Caption = 'Imp.divisa'
            DataBinding.FieldName = 'IMPORTE_DIVISA_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00000000'
            Width = 150
          end
          object colPagBlockchain: TcxGridDBColumn
            Caption = 'Red'
            DataBinding.FieldName = 'RED_BLOCKCHAIN'
            Width = 65
          end
          object colPagReferencia: TcxGridDBColumn
            Caption = 'Referencia'
            DataBinding.FieldName = 'REFERENCIA_PAGO'
            Width = 131
          end
          object colPagObs: TcxGridDBColumn
            Caption = 'Observaciones'
            DataBinding.FieldName = 'OBSERVACIONES_PAGO'
            Width = 131
          end
        end
        object cxLevelPagos: TcxGridLevel
          GridView = cxViewPagos
        end
      end
    end
    object tsMovimientos: TcxTabSheet
      Caption = 'Movimientos '
      ImageIndex = 1
      object cxGridMov: TcxGrid
        Left = 0
        Top = 0
        Width = 1196
        Height = 330
        Align = alClient
        TabOrder = 0
        object cxViewMov: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          object colMovNum: TcxGridDBColumn
            Caption = 'N'#186' Mov'
            DataBinding.FieldName = 'NUMERO_MOV'
            Width = 94
          end
          object colMovTipoDoc: TcxGridDBColumn
            Caption = 'Tipo Doc'
            DataBinding.FieldName = 'TIPO_DOC_MOV'
            Width = 132
          end
          object colMovLinea: TcxGridDBColumn
            Caption = 'L'#237'nea'
            DataBinding.FieldName = 'LINEA_MOV'
            Width = 90
          end
          object colMovAlmacen: TcxGridDBColumn
            Caption = 'Almac'#233'n'
            DataBinding.FieldName = 'CODIGO_ALMACEN_MOV'
            Width = 138
          end
          object colMovAlmacenContra: TcxGridDBColumn
            Caption = 'Contra'
            DataBinding.FieldName = 'CODIGO_ALMACEN_CONTRA_MOV'
            Width = 112
          end
          object colMovArticulo: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ARTICULO_MOV'
            Width = 88
          end
          object colMovSku: TcxGridDBColumn
            Caption = 'SKU'
            DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
            Width = 126
          end
          object colMovDesc: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
            Width = 206
          end
          object colMovTipo: TcxGridDBColumn
            Caption = 'E/S'
            DataBinding.FieldName = 'TIPO_MOVIMIENTO_MOV'
            Width = 89
          end
          object colMovCantidad: TcxGridDBColumn
            Caption = 'Cantidad'
            DataBinding.FieldName = 'CANTIDAD_MOV'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00'
            Width = 91
          end
          object colMovPMP: TcxGridDBColumn
            Caption = 'PMP'
            DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 25
          end
          object colMovCoste: TcxGridDBColumn
            Caption = 'Total coste'
            DataBinding.FieldName = 'TOTAL_COSTE_MOV'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 42
          end
        end
        object cxLevelMov: TcxGridLevel
          GridView = cxViewMov
        end
      end
    end
    object tsCliente: TcxTabSheet
      Caption = 'Cliente '
      ImageIndex = 2
      object cxGridCli: TcxGrid
        Left = 0
        Top = 0
        Width = 1196
        Height = 330
        Align = alClient
        TabOrder = 0
        object cxViewCli: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          object colCliCodigo: TcxGridDBColumn
            Caption = 'C'#243'digo'
            DataBinding.FieldName = 'CODIGO_CLIENTE'
            Width = 80
          end
          object colCliRazon: TcxGridDBColumn
            Caption = 'Raz'#243'n social'
            DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE'
            Width = 250
          end
          object colCliNif: TcxGridDBColumn
            Caption = 'NIF'
            DataBinding.FieldName = 'NIF_CLIENTE'
            Width = 100
          end
          object colCliMovil: TcxGridDBColumn
            Caption = 'M'#243'vil'
            DataBinding.FieldName = 'MOVIL_CLIENTE'
            Width = 100
          end
          object colCliEmail: TcxGridDBColumn
            Caption = 'Email'
            DataBinding.FieldName = 'EMAIL_CLIENTE'
            Width = 180
          end
          object colCliDir1: TcxGridDBColumn
            Caption = 'Direcci'#243'n'
            DataBinding.FieldName = 'DIRECCION1_CLIENTE'
            Width = 200
          end
          object colCliPobl: TcxGridDBColumn
            Caption = 'Poblaci'#243'n'
            DataBinding.FieldName = 'POBLACION_CLIENTE'
            Width = 130
          end
          object colCliProv: TcxGridDBColumn
            Caption = 'Provincia'
            DataBinding.FieldName = 'PROVINCIA_CLIENTE'
            Width = 120
          end
          object colCliCP: TcxGridDBColumn
            Caption = 'C.P.'
            DataBinding.FieldName = 'CPOSTAL_CLIENTE'
            Width = 60
          end
          object colCliDeuda: TcxGridDBColumn
            Caption = 'Deuda'
            DataBinding.FieldName = 'TOTAL_DEUDA_CLIENTE'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
        end
        object cxLevelCli: TcxGridLevel
          GridView = cxViewCli
        end
      end
    end
    object tsDepositos: TcxTabSheet
      Caption = 'Dep'#243'sitos'
      ImageIndex = 3
      object cxGridDep: TcxGrid
        Left = 0
        Top = 0
        Width = 1196
        Height = 330
        Align = alClient
        TabOrder = 0
        object cxViewDep: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          object colDepRol: TcxGridDBColumn
            Caption = 'Rol'
            DataBinding.FieldName = 'ROL_EN_OPERACION'
            Width = 80
          end
          object colDepId: TcxGridDBColumn
            Caption = 'Id dep'#243'sito'
            DataBinding.FieldName = 'ID_DEPOSITO_DEP'
            Width = 160
          end
          object colDepCli: TcxGridDBColumn
            Caption = 'Cliente'
            DataBinding.FieldName = 'CODIGO_CLIENTE_DEP'
            Width = 70
          end
          object colDepArt: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ARTICULO_DEP'
            Width = 110
          end
          object colDepSku: TcxGridDBColumn
            Caption = 'SKU'
            DataBinding.FieldName = 'CODIGO_UNIDAD_DEP'
            Width = 160
          end
          object colDepAlm: TcxGridDBColumn
            Caption = 'Almac'#233'n'
            DataBinding.FieldName = 'CODIGO_ALMACEN_DEP'
            Width = 70
          end
          object colDepCant: TcxGridDBColumn
            Caption = 'Cantidad pdte.'
            DataBinding.FieldName = 'CANTIDAD_PENDIENTE_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00'
            Width = 90
          end
          object colDepPvp: TcxGridDBColumn
            Caption = 'Precio venta'
            DataBinding.FieldName = 'PRECIO_VENTA_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colDepAnt: TcxGridDBColumn
            Caption = 'Anticipo'
            DataBinding.FieldName = 'IMPORTE_ANTICIPO_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colDepEstado: TcxGridDBColumn
            Caption = 'Estado'
            DataBinding.FieldName = 'ESTADO_DEP'
            Width = 80
          end
          object colDepFecha: TcxGridDBColumn
            Caption = 'Fecha alta'
            DataBinding.FieldName = 'FECHA_CREACION_DEP'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
            Properties.Kind = ckDateTime
            Width = 120
          end
        end
        object cxLevelDep: TcxGridLevel
          GridView = cxViewDep
        end
      end
    end
    object tsFactura: TcxTabSheet
      Caption = 'Factura '
      ImageIndex = 4
      object pnlFacCabecera: TPanel
        Left = 0
        Top = 0
        Width = 1196
        Height = 70
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 1194
        object cxGridFacCab: TcxGrid
          Left = 0
          Top = 0
          Width = 1196
          Height = 70
          Align = alClient
          TabOrder = 0
          ExplicitWidth = 1194
          object cxViewFacCab: TcxGridDBTableView
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.ColumnAutoWidth = True
            OptionsView.GroupByBox = False
            object colFacSerie: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FACTURA'
              Width = 80
            end
            object colFacNro: TcxGridDBColumn
              Caption = 'N'#186
              DataBinding.FieldName = 'NRO_FACTURA'
              Width = 80
            end
            object colFacFecha: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_FACTURA'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy'
              Width = 100
            end
            object colFacTipo: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_FACTURA'
              Width = 110
            end
            object colFacCliente: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLIENTE_FACTURA'
              Width = 80
            end
            object colFacRazon: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE_FACTURA'
              Width = 220
            end
            object colFacBases: TcxGridDBColumn
              Caption = 'Bases'
              DataBinding.FieldName = 'TOTAL_BASES_FACTURA'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object colFacImp: TcxGridDBColumn
              Caption = 'Impuestos'
              DataBinding.FieldName = 'TOTAL_IMPUESTOS_FACTURA'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object colFacLiq: TcxGridDBColumn
              Caption = 'L'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_FACTURA'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
          end
          object cxLevelFacCab: TcxGridLevel
            GridView = cxViewFacCab
          end
        end
      end
      object cxGridFacLin: TcxGrid
        Left = 0
        Top = 70
        Width = 1196
        Height = 260
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 1194
        ExplicitHeight = 252
        object cxViewFacLin: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          object colFlLinea: TcxGridDBColumn
            Caption = 'L'#237'n'
            DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
            Width = 50
          end
          object colFlArt: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
            Width = 110
          end
          object colFlSku: TcxGridDBColumn
            Caption = 'SKU'
            DataBinding.FieldName = 'CODIGO_UNIDAD_FACTURA_LINEA'
            Width = 160
          end
          object colFlDesc: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
            Width = 280
          end
          object colFlCant: TcxGridDBColumn
            Caption = 'Cant.'
            DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00'
            Width = 70
          end
          object colFlPrSiva: TcxGridDBColumn
            Caption = 'P.S.IVA'
            DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colFlPrCiva: TcxGridDBColumn
            Caption = 'P.C.IVA'
            DataBinding.FieldName = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colFlDto: TcxGridDBColumn
            Caption = '% Dto'
            DataBinding.FieldName = 'PORCEN_DTO_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '0.00 %'
            Width = 60
          end
          object colFlTipoIva: TcxGridDBColumn
            Caption = 'T.IVA'
            DataBinding.FieldName = 'TIPOIVA_ARTICULO_FACTURA_LINEA'
            Width = 50
          end
          object colFlPorcIva: TcxGridDBColumn
            Caption = '% IVA'
            DataBinding.FieldName = 'PORCEN_IVA_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '0.00'
            Width = 60
          end
          object colFlTotSiva: TcxGridDBColumn
            Caption = 'Tot. S.IVA'
            DataBinding.FieldName = 'TOTAL_FACTURASIVA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
          object colFlTotCiva: TcxGridDBColumn
            Caption = 'Tot. C.IVA'
            DataBinding.FieldName = 'TOTAL_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
        end
        object cxLevelFacLin: TcxGridLevel
          GridView = cxViewFacLin
        end
      end
    end
  end
  object pnlPie: TPanel [4]
    Left = 0
    Top = 681
    Width = 1200
    Height = 39
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 673
    ExplicitWidth = 1198
    object btnReimprimir: TButton
      Left = 12
      Top = 6
      Width = 160
      Height = 28
      Caption = 'Reimprimir'
      TabOrder = 0
      OnClick = btnReimprimirClick
    end
    object btnCerrar: TButton
      Left = 1080
      Top = 6
      Width = 108
      Height = 28
      Caption = 'Cerrar (ESC)'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
    object Button1: TButton
      Left = 220
      Top = 6
      Width = 226
      Height = 28
      Caption = 'Devolver Abonar Operaci'#243'n'
      TabOrder = 2
    end
    object Button2: TButton
      Left = 476
      Top = 6
      Width = 213
      Height = 28
      Caption = 'Anular Factura Verifactu'
      TabOrder = 3
    end
  end
  object tmrBusqueda: TTimer
    Enabled = False
    Interval = 400
    OnTimer = tmrBusquedaTimer
    Left = 840
    Top = 16
  end
end
