object frmMtoOpeCaja: TfrmMtoOpeCaja
  Left = 0
  Top = 0
  Caption = 'Operaci'#243'n de Caja'
  ClientHeight = 437
  ClientWidth = 1366
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -19
  Font.Name = 'Lucida Sans'
  Font.Style = []
  KeyPreview = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 22
  object pnlUp1: TPanel
    Left = 0
    Top = 0
    Width = 1366
    Height = 89
    Align = alTop
    TabOrder = 0
    object lblFecha: TcxLabel
      Left = 11
      Top = 27
      AutoSize = False
      Caption = 'Empleado'
      ParentFont = False
      Style.BorderStyle = ebsNone
      Style.Edges = []
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clNavy
      Style.Font.Height = -20
      Style.Font.Name = 'Arial Black'
      Style.Font.Style = [fsBold]
      Style.Shadow = True
      Style.IsFontAssigned = True
      Properties.LineOptions.Alignment = cxllaBottom
      Properties.LineOptions.Visible = True
      Properties.Orientation = cxoRight
      Properties.WordWrap = True
      TabOrder = 0
      Height = 36
      Width = 121
    end
    object lblNombreEmpleado: TcxLabel
      Left = 254
      Top = 31
      AutoSize = False
      Caption = 'NOMBRE EMPLEADO'
      Style.BorderStyle = ebsFlat
      Properties.LabelStyle = cxlsLowered
      TabOrder = 1
      Height = 29
      Width = 203
    end
    object lblNombreCliente: TcxLabel
      Left = 694
      Top = 31
      AutoSize = False
      Caption = 'NOMBRE CLIENTE'
      Style.BorderStyle = ebsFlat
      Properties.LabelStyle = cxlsLowered
      TabOrder = 2
      Height = 29
      Width = 412
    end
    object lblFechaCaja: TcxLabel
      Left = 764
      Top = 64
      AutoSize = False
      Caption = 'NOMBRE CLIENTE'
      ParentFont = False
      Style.BorderStyle = ebsFlat
      Style.Font.Charset = ANSI_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -14
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      Properties.LabelStyle = cxlsLowered
      TabOrder = 3
      Height = 19
      Width = 342
    end
    object lblTarifa: TcxLabel
      Left = 764
      Top = 6
      AutoSize = False
      Caption = 'NOMBRE CLIENTE'
      ParentFont = False
      Style.BorderStyle = ebsFlat
      Style.Font.Charset = ANSI_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -14
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      Properties.LabelStyle = cxlsLowered
      TabOrder = 4
      Height = 19
      Width = 342
    end
    object lblInstrucciones: TcxLabel
      Left = 11
      Top = 66
      ParentFont = False
      Style.Font.Charset = ANSI_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -13
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 5
    end
  end
  object pnlCli1: TPanel
    Left = 0
    Top = 89
    Width = 1366
    Height = 348
    Align = alClient
    TabOrder = 3
    object Panel1: TPanel
      Left = 1
      Top = 257
      Width = 1366
      Height = 98
      Align = alBottom
      TabOrder = 1
      ExplicitTop = 249
      ExplicitWidth = 1364
      DesignSize = (
        1364
        98)
      object btnF12: TcxButton
        Left = 10
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F12'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 1
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = btnF12Click
      end
      object btnF3: TcxButton
        Left = 117
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F3'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 2
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object btnF6: TcxButton
        Left = 331
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F6'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 4
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object btnF5: TcxButton
        Left = 645
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F5'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 6
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = btnF5Click
      end
      object btnF7: TcxButton
        Left = 542
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F7'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 5
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object cxLabel1: TcxLabel
        Left = 31
        Top = 71
        Caption = 'Cobro'
        TabOrder = 7
        Transparent = True
      end
      object cxLabel2: TcxLabel
        Left = 136
        Top = 71
        Caption = 'Buscar'
        TabOrder = 8
        Transparent = True
      end
      object cxLabel3: TcxLabel
        Left = 354
        Top = 71
        Caption = 'Tarifa'
        TabOrder = 10
        Transparent = True
      end
      object cxLabel4: TcxLabel
        Left = 555
        Top = 71
        Caption = 'Ind. IVA'
        TabOrder = 11
        Transparent = True
      end
      object cxLabel5: TcxLabel
        Left = 673
        Top = 71
        Caption = 'Otro'
        TabOrder = 12
        Transparent = True
      end
      object lblTotal: TcxLabel
        Left = 882
        Top = 4
        Anchors = [akTop, akRight]
        AutoSize = False
        Caption = 'Total 0,00 '#8364
        ParentFont = False
        Style.BorderStyle = ebsOffice11
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clNavy
        Style.Font.Height = -50
        Style.Font.Name = 'Arial Black'
        Style.Font.Style = [fsBold]
        Style.Shadow = True
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Properties.LabelEffect = cxleFun
        Properties.LabelStyle = cxlsLowered
        Properties.LineOptions.Alignment = cxllaTop
        Properties.LineOptions.Visible = True
        Properties.Orientation = cxoRight
        Properties.WordWrap = True
        TabOrder = 0
        Height = 80
        Width = 423
        AnchorX = 1305
      end
      object btnF8: TcxButton
        Left = 224
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F8'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 3
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object cxLabel6: TcxLabel
        Left = 235
        Top = 71
        Caption = 'Eliminar'
        TabOrder = 9
        Transparent = True
      end
      object btnF61: TcxButton
        Left = 437
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F4'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 13
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object lbl1: TcxLabel
        Left = 452
        Top = 71
        Caption = 'B'#250'sq Tick'
        TabOrder = 14
        Transparent = True
      end
      object btnF2: TcxButton
        Left = 763
        Top = 6
        Width = 103
        Height = 57
        Caption = 'F2'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 15
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -27
        Font.Name = 'Segoe UI Black'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = btnF2Click
      end
      object cxLabel7: TcxLabel
        Left = 763
        Top = 69
        Caption = 'Cargar cta.'
        TabOrder = 16
        Transparent = True
      end
    end
    object Panel2: TPanel
      Left = 1
      Top = 1
      Width = 1364
      Height = 248
      Align = alClient
      TabOrder = 0
      object cxGrid1: TcxGrid
        Left = 1
        Top = 1
        Width = 1364
        Height = 128
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Lucida Sans'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnEnter = cxGrid1Enter
        OnExit = cxGrid1Exit
        ExplicitWidth = 1362
        ExplicitHeight = 120
        object cxGrid1DBTableView1: TcxGridDBTableView
          OnKeyDown = cxGrid1DBTableView1KeyDown
          OnMouseDown = cxGrid1DBTableView1MouseDown
          OnCanFocusRecord = cxGrid1DBTableView1CanFocusRecord
          OnEditing = cxGrid1DBTableView1Editing
          OnEditKeyDown = cxGrid1DBTableView1EditKeyDown
          OnFocusedRecordChanged = cxGrid1DBTableView1FocusedRecordChanged
          OnInitEdit = cxGrid1DBTableView1InitEdit
          DataController.DataSource = dsLineas
          OptionsBehavior.GoToNextCellOnEnter = True
          OptionsBehavior.FocusCellOnCycle = True
          OptionsData.Appending = True
          OptionsView.NoDataToDisplayInfoText = 'No hay art'#237'culos'
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          Styles.Header = cxstyl2
          object tvEmpleado: TcxGridDBColumn
            Caption = 'Vend.'
            DataBinding.FieldName = 'CODIGO_VENDEDOR_FACTURA_LINEA'
            PropertiesClassName = 'TcxTextEditProperties'
            Width = 66
          end
          object tvArticulo: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
            PropertiesClassName = 'TcxExtLookupComboBoxProperties'
            Properties.DropDownListStyle = lsEditList
            Properties.View = dbtvBusqDBTableView1
            Properties.KeyFieldNames = 'CODIGO_PADRE'
            Properties.ListFieldItem = cxgrdbclmnBusqDBTableView1INPUT_BUSQUEDA
            Properties.OnCloseUp = tvArticuloPropertiesCloseUp
            Properties.OnValidate = tvArticuloPropertiesValidate
            OnGetProperties = tvArticuloGetProperties
            Width = 135
          end
          object tvDescripcion: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
            Width = 306
          end
          object tvUds: TcxGridDBColumn
            Caption = 'Uds.'
            DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.OnEditValueChanged = tvUdsPropertiesEditValueChanged
            Properties.OnValidate = tvUdsPropertiesValidate
            BestFitMaxWidth = 50
          end
          object tvPrecioUni: TcxGridDBColumn
            Caption = 'Precio'
            DataBinding.FieldName = 'PRECIOSALIDA_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.OnEditValueChanged = tvPrecioUniPropertiesEditValueChanged
            Width = 91
          end
          object tvDescuento: TcxGridDBColumn
            Caption = '%'
            DataBinding.FieldName = 'PORCEN_DTO_FACTURA_LINEA'
            PropertiesClassName = 'TcxSpinEditProperties'
            Properties.DisplayFormat = '0.00 %'
            Properties.EditFormat = '0.00 %'
            Properties.Increment = 0.100000000000000000
            Properties.LargeIncrement = 1.000000000000000000
            Properties.MaxValue = 100.000000000000000000
            Properties.OnEditValueChanged = tvDescuentoPropertiesEditValueChanged
            Width = 43
          end
          object tvDescuentoMenos: TcxGridDBColumn
            Caption = 'Menos'
            DataBinding.FieldName = 'PRECIO_DTO_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.OnEditValueChanged = tvDescuentoMenosPropertiesEditValueChanged
            Width = 152
          end
          object tvTotal: TcxGridDBColumn
            Caption = 'Total'
            DataBinding.FieldName = 'TOTAL_FACTURA_LINEA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.ReadOnly = False
            Properties.OnEditValueChanged = tvTotalPropertiesEditValueChanged
            Width = 137
          end
        end
        object cxGrid1Level1: TcxGridLevel
          GridView = cxGrid1DBTableView1
        end
      end
      object pnl1: TPanel
        Left = 1
        Top = 139
        Width = 1364
        Height = 116
        Align = alBottom
        TabOrder = 1
        ExplicitTop = 131
        ExplicitWidth = 1362
        object cxgrdStock: TcxGrid
          Left = 1
          Top = 1
          Width = 1362
          Height = 114
          Align = alClient
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Lucida Sans'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnEnter = cxGrid1Enter
          OnExit = cxGrid1Exit
          ExplicitWidth = 1360
          object dbtvStock: TcxGridDBTableView
            OnKeyDown = cxGrid1DBTableView1KeyDown
            OnEditKeyDown = cxGrid1DBTableView1EditKeyDown
            OnInitEdit = cxGrid1DBTableView1InitEdit
            DataController.DataSource = dsStock
            OptionsBehavior.GoToNextCellOnEnter = True
            OptionsBehavior.FocusCellOnCycle = True
            OptionsData.CancelOnExit = False
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
            OptionsView.NoDataToDisplayInfoText = 'Sin stock'
            OptionsView.ColumnAutoWidth = True
            OptionsView.GroupByBox = False
            Styles.Content = cxstyl1
            Styles.Header = cxstyl
          end
          object cxgrdlvl1: TcxGridLevel
            GridView = dbtvStock
          end
        end
      end
      object cxspltr1: TcxSplitter
        Left = 1
        Top = 129
        Width = 1364
        Height = 10
        HotZoneClassName = 'TcxMediaPlayer8Style'
        AlignSplitter = salBottom
        AutoSnap = True
        ExplicitTop = 121
        ExplicitWidth = 1362
      end
    end
  end
  object cxLabel8: TcxLabel
    Left = 463
    Top = 27
    AutoSize = False
    Caption = 'Cliente'
    ParentFont = False
    Style.BorderStyle = ebsNone
    Style.Edges = []
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clNavy
    Style.Font.Height = -20
    Style.Font.Name = 'Arial Black'
    Style.Font.Style = [fsBold]
    Style.Shadow = True
    Style.IsFontAssigned = True
    Properties.LineOptions.Alignment = cxllaBottom
    Properties.LineOptions.Visible = True
    Properties.Orientation = cxoRight
    Properties.WordWrap = True
    TabOrder = 1
    Height = 36
    Width = 85
  end
  object btnCodigoCliente: TcxButtonEdit
    Left = 554
    Top = 30
    Properties.AutoSelect = False
    Properties.Buttons = <
      item
        Default = True
        Kind = bkEllipsis
      end>
    Properties.OnValidate = btnCodigoClientePropertiesValidate
    TabOrder = 2
    OnExit = btnCodigoClienteExit
    Width = 121
  end
  object btnCodigoEmpleado: TcxButtonEdit
    Left = 127
    Top = 30
    Properties.AutoSelect = False
    Properties.Buttons = <
      item
        Default = True
        Kind = bkEllipsis
      end>
    Properties.OnButtonClick = btnCodigoEmpleadoPropertiesButtonClick
    Properties.OnValidate = btnCodigoEmpleadoPropertiesValidate
    TabOrder = 4
    OnExit = btnCodigoEmpleadoExit
    Width = 121
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 1040
    Top = 32
  end
  object dsLineas: TDataSource
    Left = 648
    Top = 136
  end
  object jvntrstb1: TJvEnterAsTab
    Left = 840
    Top = 432
  end
  object dsStock: TDataSource
    DataSet = dmCajaOpe.qryStock
    Left = 960
    Top = 432
  end
  object cxstylrpstry: TcxStyleRepository
    Left = 896
    Top = 432
    PixelsPerInch = 96
    object cxstyl: TcxStyle
      AssignedValues = [svColor, svFont]
      Color = 11529442
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Lucida Sans'
      Font.Style = [fsBold]
    end
    object cxstyl1: TcxStyle
      AssignedValues = [svFont]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clOlive
      Font.Height = -12
      Font.Name = 'Lucida Sans'
      Font.Style = []
    end
    object cxstyl2: TcxStyle
      AssignedValues = [svColor, svFont, svTextColor]
      Color = 11529442
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 20
      Font.Name = 'Lucida Sans'
      Font.Style = [fsBold]
      TextColor = clDefault
    end
  end
  object tmrBusq: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrBusqTimer
    Left = 80
    Top = 136
  end
  object dsBusq: TDataSource
    DataSet = qryBusq
    Left = 80
    Top = 192
  end
  object qryBusq: TUniQuery
    SQL.Strings = (
      'SELECT '
      '    CODIGO_ARTICULO as INPUT_BUSQUEDA,'
      
        '    CODIGO_ARTICULO AS CODIGO_PADRE,   -- El valor real que guar' +
        'daremos'
      '    DESCRIPCION_ARTICULO'
      'FROM vi_articulos_list'
      'WHERE CODIGO_ARTICULO LIKE :TOKEN'
      'ORDER BY CODIGO_ARTICULO'
      'LIMIT 20')
    Left = 80
    Top = 256
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'TOKEN'
        Value = nil
      end>
  end
  object tvrBusq: TcxGridViewRepository
    Left = 80
    Top = 312
    object dbtvBusqDBTableView1: TcxGridDBTableView
      DataController.DataModeController.SyncMode = False
      DataController.DataSource = dsBusq
      DataController.KeyFieldNames = 'CODIGO_PADRE'
      Filtering.MRUItemsList = False
      Filtering.ColumnAddValueItems = False
      Filtering.ColumnFilteredItemsListShowFilteredItemsOnly = False
      Filtering.ColumnMRUItemsList = False
      OptionsBehavior.ColumnHeaderHints = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Header = False
      object cxgrdbclmnBusqDBTableView1INPUT_BUSQUEDA: TcxGridDBColumn
        DataBinding.FieldName = 'INPUT_BUSQUEDA'
        PropertiesClassName = 'TcxTextEditProperties'
        Properties.IncrementalSearch = False
        Visible = False
        Options.Filtering = False
        Options.FilteringWithFindPanel = False
        Options.IncSearch = False
        Options.FilteringAddValueItems = False
        Options.FilteringFilteredItemsList = False
        Options.FilteringFilteredItemsListShowFilteredItemsOnly = False
        Options.FilteringMRUItemsList = False
        Options.FilteringPopup = False
        Options.FilteringPopupMultiSelect = False
        Options.GroupFooters = False
        Options.Grouping = False
      end
      object cxgrdbclmnBusqDBTableView1CODIGO_ARTICULO: TcxGridDBColumn
        DataBinding.FieldName = 'CODIGO_PADRE'
      end
      object cxgrdbclmnBusqDBTableView1DESCRIPCION_ARTICULO: TcxGridDBColumn
        DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
      end
    end
  end
  object edtrepArticulo: TcxEditRepository
    Left = 80
    Top = 368
    PixelsPerInch = 96
    object repSoloTexto: TcxEditRepositoryTextItem
    end
    object repComboBox: TcxEditRepositoryExtLookupComboBoxItem
      Properties.AutoSearchOnPopup = False
      Properties.DropDownListStyle = lsEditList
      Properties.DropDownRows = 15
      Properties.DropDownSizeable = True
      Properties.DropDownWidth = 400
      Properties.ImmediateDropDownWhenActivated = True
      Properties.ImmediateDropDownWhenKeyPressed = False
      Properties.IncrementalFiltering = False
      Properties.View = dbtvBusqDBTableView1
      Properties.KeyFieldNames = 'CODIGO_PADRE'
      Properties.ListFieldItem = cxgrdbclmnBusqDBTableView1INPUT_BUSQUEDA
      Properties.OnInitPopup = repComboBoxPropertiesInitPopup
      Properties.OnValidate = tvArticuloPropertiesValidate
    end
  end
  object actlst1: TActionList
    Left = 312
    Top = 168
    object actBuscarEmpleados: TAction
      Caption = 'actBuscarEmpleados'
      SecondaryShortCuts.Strings = (
        'F3')
      ShortCut = 16397
      OnExecute = actBuscarEmpleadosExecute
    end
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
    object actEliminarLinea: TAction
      Caption = 'Eliminar'
      ShortCut = 119
      OnExecute = actEliminarLineaExecute
    end
    object actCobro: TAction
      Caption = 'actCobro'
      ShortCut = 123
      OnExecute = actCobroExecute
    end
    object actCargarCta: TAction
      Caption = 'CargarCta'
      ShortCut = 113
      OnExecute = actCargarCtaExecute
    end
    object actGuardarLayout: TAction
      Caption = 'Guardar Layout'
      ShortCut = 32891
      OnExecute = actGuardarLayoutExecute
    end
  end
end
