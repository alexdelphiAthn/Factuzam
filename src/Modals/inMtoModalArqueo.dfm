inherited frmModalArqueo: TfrmModalArqueo
  Caption = 'Arqueo de caja'
  ClientHeight = 510
  ClientWidth = 880
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  TextHeight = 17
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 880
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 0
    object lblTituloDesde: TcxLabel
      Transparent = True
      Left = 16
      Top = 6
      Caption = 'Fecha desde'
      Style.TextColor = clNavy
    end
    object dteFechaDesde: TcxDateEdit
      Left = 16
      Top = 28
      TabOrder = 0
      Width = 130
      Properties.OnChange = dteFechaDesdePropertiesChange
    end
    object lblF10: TcxLabel
      Transparent = True
      Left = 152
      Top = 32
      Caption = 'F10'
      Style.Font.Style = [fsBold]
      Style.TextColor = clBlue
      Style.IsFontAssigned = True
    end
    object lblTituloHasta: TcxLabel
      Transparent = True
      Left = 210
      Top = 6
      Caption = 'Fecha hasta'
      Style.TextColor = clNavy
    end
    object dteFechaHasta: TcxDateEdit
      Left = 210
      Top = 28
      TabOrder = 1
      Width = 130
      Properties.OnChange = dteFechaHastaPropertiesChange
    end
    object lblF6: TcxLabel
      Transparent = True
      Left = 346
      Top = 32
      Caption = 'F6'
      Style.Font.Style = [fsBold]
      Style.TextColor = clBlue
      Style.IsFontAssigned = True
    end
    object lblTituloVentas: TcxLabel
      Transparent = True
      Left = 430
      Top = 6
      Caption = 'Ventas'
      Style.TextColor = clNavy
    end
    object lblVentas: TcxLabel
      Transparent = True
      Left = 430
      Top = 28
      AutoSize = False
      Caption = '0'
      Style.Font.Height = -19
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Properties.Alignment.Horz = taRightJustify
      Height = 28
      Width = 90
    end
    object btnRecalcular: TcxButton
      Left = 540
      Top = 22
      Width = 150
      Height = 35
      Caption = 'Recalcular (F5)'
      TabOrder = 2
      OnClick = btnRecalcularClick
    end
    object btnImprimir: TcxButton
      Left = 700
      Top = 22
      Width = 160
      Height = 35
      Caption = 'Imprimir (F11)'
      TabOrder = 3
      OnClick = btnImprimirClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 70
    Width = 880
    Height = 390
    Align = alClient
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 1
    object pcArqueo: TcxPageControl
      Left = 0
      Top = 0
      Width = 880
      Height = 390
      Align = alClient
      TabOrder = 0
      Properties.ActivePage = tsArqueo
      Properties.CustomButtons.Buttons = <>
      ClientRectBottom = 386
      ClientRectRight = 876
      ClientRectTop = 28
      object tsArqueo: TcxTabSheet
        Caption = 'Arqueo'
        object pnlLineas: TPanel
          Left = 8
          Top = 8
          Width = 360
          Height = 130
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 0
          object lblLineasTitulo: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'L'#237'neas art'#237'culos'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object lblLinBrutoLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 34
            Caption = '+ Bruto'
          end
          object lblLinBruto: TcxLabel
            Transparent = True
            Left = 190
            Top = 34
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblLinDescuentoLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 60
            Caption = '- Descuento'
          end
          object lblLinDescuento: TcxLabel
            Transparent = True
            Left = 190
            Top = 60
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblLinNetoLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 92
            Caption = '= Bruto'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
          end
          object lblLinNeto: TcxLabel
            Transparent = True
            Left = 190
            Top = 92
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
        end
        object pnlOperaciones: TPanel
          Left = 376
          Top = 8
          Width = 496
          Height = 130
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 1
          object lblOpeTitulo: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Operaciones'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object lblOpeVentasNormLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 30
            Caption = 'Ventas Normales'
          end
          object lblOpeVentasNorm: TcxLabel
            Transparent = True
            Left = 175
            Top = 30
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblOpeVentasPrestLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 54
            Caption = '+ Ventas Pr'#233'stamos'
          end
          object lblOpeVentasPrest: TcxLabel
            Transparent = True
            Left = 175
            Top = 54
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblOpeDevolLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 78
            Caption = #8722' Devoluciones'
          end
          object lblOpeDevol: TcxLabel
            Transparent = True
            Left = 175
            Top = 78
            AutoSize = False
            Caption = ''
            Style.TextColor = clRed
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblOpeTotalVentasLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 102
            Caption = '= Total Ventas'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
          end
          object lblOpeTotalVentas: TcxLabel
            Transparent = True
            Left = 175
            Top = 102
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
        end
        object pnlCobros: TPanel
          Left = 8
          Top = 146
          Width = 864
          Height = 230
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 2
          object lblCobrosTitulo: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Cobros'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object lblCobValesRecLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 34
            Caption = '- Vales recogidos'
          end
          object lblCobValesRec: TcxLabel
            Transparent = True
            Left = 190
            Top = 34
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblCobValesEmiLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 60
            Caption = '+ Vales emitidos'
          end
          object lblCobValesEmi: TcxLabel
            Transparent = True
            Left = 190
            Top = 60
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblCobClientesLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 86
            Caption = '+ Cobros clientes'
          end
          object lblCobClientes: TcxLabel
            Transparent = True
            Left = 190
            Top = 86
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblCobPendienteLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 112
            Caption = '- Pendiente cobro'
          end
          object lblCobPendiente: TcxLabel
            Transparent = True
            Left = 190
            Top = 112
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblCobIngresosLbl: TcxLabel
            Transparent = True
            Left = 16
            Top = 144
            Caption = '= Ingresos caja'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
          end
          object lblCobIngresos: TcxLabel
            Transparent = True
            Left = 190
            Top = 144
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 150
          end
          object lblEftIngresosLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 34
            Caption = 'Eftvo. ingresos'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
          end
          object lblEftIngresos: TcxLabel
            Transparent = True
            Left = 690
            Top = 34
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
          object lblEftEntradasLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 60
            Caption = '+ Efectivo entradas'
          end
          object lblEftEntradas: TcxLabel
            Transparent = True
            Left = 690
            Top = 60
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
          object lblEftSalidasLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 86
            Caption = '- Efectivo salidas'
          end
          object lblEftSalidas: TcxLabel
            Transparent = True
            Left = 690
            Top = 86
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
          object lblEftAnteriorLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 112
            Caption = '+ Efectivo anterior'
          end
          object lblEftAnterior: TcxLabel
            Transparent = True
            Left = 690
            Top = 112
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
          object lblEftCajaLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 138
            Caption = '= Efectivo en caja'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
          end
          object lblEftCaja: TcxLabel
            Transparent = True
            Left = 690
            Top = 138
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
          object lblTarjetasLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 164
            Caption = '+ Otros (tarj, bonos, divisa, cripto)'
          end
          object lblTarjetas: TcxLabel
            Transparent = True
            Left = 690
            Top = 164
            AutoSize = False
            Caption = ''
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
          object lblSaldoLbl: TcxLabel
            Transparent = True
            Left = 400
            Top = 196
            Caption = '= Saldo efectivo + otros (a recontar)'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
          end
          object lblSaldo: TcxLabel
            Transparent = True
            Left = 690
            Top = 196
            AutoSize = False
            Caption = ''
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Properties.Alignment.Horz = taRightJustify
            Height = 21
            Width = 160
          end
        end
      end
      object tsResumenes: TcxTabSheet
        Caption = 'Res'#250'menes'
        object pnlResEmpleado: TPanel
          Left = 8
          Top = 8
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 0
          object lblResEmpleadoTit: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Neto ventas por empleado'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object cxgrdResEmpleado: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResEmpleado: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              DataController.DataSource = dsResEmpleado
              DataController.Summary.DefaultGroupSummaryItems = <>
              DataController.Summary.FooterSummaryItems = <>
              DataController.Summary.SummaryGroups = <>
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResEmpleadoEMP: TcxGridDBColumn
                Caption = 'Empleado'
                DataBinding.FieldName = 'EMPLEADO'
                Width = 150
              end
              object tvResEmpleadoUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 70
              end
              object tvResEmpleadoNETO: TcxGridDBColumn
                Caption = 'Neto'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResEmpleado: TcxGridLevel
              GridView = tvResEmpleado
            end
          end
        end
        object pnlResFP: TPanel
          Left = 444
          Top = 8
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 1
          object lblResFPTit: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Neto ventas por forma de pago'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object cxgrdResFP: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResFP: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              DataController.DataSource = dsResFP
              DataController.Summary.DefaultGroupSummaryItems = <>
              DataController.Summary.FooterSummaryItems = <>
              DataController.Summary.SummaryGroups = <>
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResFPFP: TcxGridDBColumn
                Caption = 'Forma de pago'
                DataBinding.FieldName = 'FP'
                Width = 150
              end
              object tvResFPUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 70
              end
              object tvResFPNETO: TcxGridDBColumn
                Caption = 'Importe'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResFP: TcxGridLevel
              GridView = tvResFP
            end
          end
        end
        object pnlResFam: TPanel
          Left = 8
          Top = 186
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 2
          object lblResFamTit: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Neto ventas por familia'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object cxgrdResFam: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResFam: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              DataController.DataSource = dsResFam
              DataController.Summary.DefaultGroupSummaryItems = <>
              DataController.Summary.FooterSummaryItems = <>
              DataController.Summary.SummaryGroups = <>
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResFamFAM: TcxGridDBColumn
                Caption = 'Familia'
                DataBinding.FieldName = 'FAMILIA'
                Width = 200
              end
              object tvResFamUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 60
              end
              object tvResFamNETO: TcxGridDBColumn
                Caption = 'Neto'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResFam: TcxGridLevel
              GridView = tvResFam
            end
          end
        end
        object pnlResProp: TPanel
          Left = 444
          Top = 186
          Width = 428
          Height = 170
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 3
          object lblResPropTit: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Neto ventas por propiedad'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object cxgrdResProp: TcxGrid
            Left = 8
            Top = 30
            Width = 412
            Height = 130
            TabOrder = 0
            object tvResProp: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              DataController.DataSource = dsResProp
              DataController.Summary.DefaultGroupSummaryItems = <>
              DataController.Summary.FooterSummaryItems = <>
              DataController.Summary.SummaryGroups = <>
              OptionsBehavior.IncSearch = True
              OptionsView.GroupByBox = False
              object tvResPropPROP: TcxGridDBColumn
                Caption = 'Propiedad'
                DataBinding.FieldName = 'PROP'
                Width = 120
              end
              object tvResPropVAL: TcxGridDBColumn
                Caption = 'Valor'
                DataBinding.FieldName = 'VALOR'
                Width = 130
              end
              object tvResPropUDS: TcxGridDBColumn
                Caption = 'Uds'
                DataBinding.FieldName = 'UDS'
                Width = 50
              end
              object tvResPropNETO: TcxGridDBColumn
                Caption = 'Neto'
                DataBinding.FieldName = 'NETO'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 100
              end
            end
            object lvResProp: TcxGridLevel
              GridView = tvResProp
            end
          end
        end
      end
      object tsMasDatos: TcxTabSheet
        Caption = 'M'#225's datos'
        object pnlResIVA: TPanel
          Left = 8
          Top = 8
          Width = 864
          Height = 250
          BevelInner = bvLowered
          BevelOuter = bvNone
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 0
          object lblResIVATit: TcxLabel
            Transparent = True
            Left = 10
            Top = 6
            Caption = 'Resumen por IVA'
            Style.Font.Style = [fsBold]
            Style.TextColor = clNavy
            Style.IsFontAssigned = True
          end
          object cxgrdResIVA: TcxGrid
            Left = 8
            Top = 30
            Width = 848
            Height = 210
            TabOrder = 0
            object tvResIVA: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              DataController.DataSource = dsResIVA
              DataController.Summary.DefaultGroupSummaryItems = <>
              DataController.Summary.FooterSummaryItems = <>
              DataController.Summary.SummaryGroups = <>
              OptionsView.GroupByBox = False
              object tvResIVABASE: TcxGridDBColumn
                Caption = 'Bases'
                DataBinding.FieldName = 'BASE'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
              object tvResIVAPORC_IVA: TcxGridDBColumn
                Caption = '% IVA'
                DataBinding.FieldName = 'PORC_IVA'
                Width = 80
              end
              object tvResIVACUOTA_IVA: TcxGridDBColumn
                Caption = 'Cuota IVA'
                DataBinding.FieldName = 'CUOTA_IVA'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
              object tvResIVAPORC_RE: TcxGridDBColumn
                Caption = '% RE'
                DataBinding.FieldName = 'PORC_RE'
                Width = 80
              end
              object tvResIVACUOTA_RE: TcxGridDBColumn
                Caption = 'Cuota RE'
                DataBinding.FieldName = 'CUOTA_RE'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
              object tvResIVABASE_IVAS: TcxGridDBColumn
                Caption = 'Base + IVAS'
                DataBinding.FieldName = 'BASE_IVAS'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 130
              end
            end
            object lvResIVA: TcxGridLevel
              GridView = tvResIVA
            end
          end
        end
      end
    end
  end
  object pnlBottom: TPanel [2]
    Left = 0
    Top = 460
    Width = 880
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 2
    object lblESC: TcxLabel
      Transparent = True
      Left = 600
      Top = 14
      Caption = 'ESC'
      Style.Font.Style = [fsBold]
      Style.TextColor = clBlue
      Style.IsFontAssigned = True
    end
    object btnAtras: TcxButton
      Left = 650
      Top = 8
      Width = 200
      Height = 35
      Cancel = True
      Caption = 'Atr'#225's (ESC)'
      TabOrder = 0
      OnClick = btnAtrasClick
    end
  end
  object alArqueo: TActionList
    Left = 16
    Top = 540
    object actEscape: TAction
      Caption = 'Escape'
      ShortCut = 27
      OnExecute = actEscapeExecute
    end
    object actRecalcular: TAction
      Caption = 'Recalcular'
      ShortCut = 116
      OnExecute = actRecalcularExecute
    end
    object actImprimir: TAction
      Caption = 'Imprimir'
      ShortCut = 122
      OnExecute = actImprimirExecute
    end
  end
  object dsResEmpleado: TDataSource
    DataSet = qryResEmpleado
    Left = 760
    Top = 80
  end
  object qryResEmpleado: TUniQuery
    Left = 760
    Top = 120
    ParamData = <
      item
        DataType = ftString
        Name = 'pEMPRESA'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pALMACEN'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pCAJA'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFDESDE'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFHASTA'
        ParamType = ptInput
      end>
  end
  object dsResFP: TDataSource
    DataSet = qryResFP
    Left = 760
    Top = 160
  end
  object qryResFP: TUniQuery
    Left = 760
    Top = 200
    ParamData = <
      item
        DataType = ftString
        Name = 'pEMPRESA'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pALMACEN'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pCAJA'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFDESDE'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFHASTA'
        ParamType = ptInput
      end>
  end
  object dsResFam: TDataSource
    DataSet = qryResFam
    Left = 760
    Top = 240
  end
  object qryResFam: TUniQuery
    Left = 760
    Top = 280
    ParamData = <
      item
        DataType = ftString
        Name = 'pEMPRESA'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pALMACEN'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pCAJA'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFDESDE'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFHASTA'
        ParamType = ptInput
      end>
  end
  object dsResProp: TDataSource
    DataSet = qryResProp
    Left = 760
    Top = 320
  end
  object qryResProp: TUniQuery
    Left = 760
    Top = 360
    ParamData = <
      item
        DataType = ftString
        Name = 'pEMPRESA'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pALMACEN'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pCAJA'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFDESDE'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFHASTA'
        ParamType = ptInput
      end>
  end
  object dsResIVA: TDataSource
    DataSet = qryResIVA
    Left = 760
    Top = 400
  end
  object qryResIVA: TUniQuery
    Left = 760
    Top = 440
    ParamData = <
      item
        DataType = ftString
        Name = 'pEMPRESA'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pALMACEN'
        ParamType = ptInput
      end
      item
        DataType = ftString
        Name = 'pCAJA'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFDESDE'
        ParamType = ptInput
      end
      item
        DataType = ftDate
        Name = 'pFHASTA'
        ParamType = ptInput
      end>
  end
end
