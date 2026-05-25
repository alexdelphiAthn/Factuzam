object frmMtoOpeCaja: TfrmMtoOpeCaja
  Left = 0
  Top = 0
  Caption = 'Operaci'#243'n de Caja'
  ClientHeight = 479
  ClientWidth = 1126
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Lucida Sans'
  Font.Style = []
  TextHeight = 22
  object pnlUp1: TPanel
    Left = 0
    Top = 0
    Width = 1126
    Height = 89
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 1122
    object cmbEmpleados: TcxLookupComboBox
      Left = 127
      Top = 30
      Properties.ListColumns = <>
      TabOrder = 4
      Width = 131
    end
    object btEdtEmpleado: TcxButtonEdit
      Left = 127
      Top = 30
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      TabOrder = 0
      Text = 'EMPLEADO'
      Width = 131
    end
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
      Style.Font.Height = -17
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = [fsBold]
      Style.Shadow = True
      Style.IsFontAssigned = True
      Properties.LineOptions.Alignment = cxllaBottom
      Properties.LineOptions.Visible = True
      Properties.Orientation = cxoRight
      Properties.WordWrap = True
      Height = 36
      Width = 121
    end
    object lblNombreEmpresa: TcxLabel
      Left = 264
      Top = 31
      AutoSize = False
      Caption = 'NOMBRE_EMPRESA'
      Style.BorderStyle = ebsFlat
      Properties.LabelStyle = cxlsLowered
      Height = 29
      Width = 193
    end
    object lblfechaCaja: TcxLabel
      Left = 694
      Top = 31
      AutoSize = False
      Caption = 'Domingo, 7 de Septiembre de 2025'
      Style.BorderStyle = ebsFlat
      Properties.LabelStyle = cxlsLowered
      Height = 29
      Width = 412
    end
  end
  object pnlCli1: TPanel
    Left = 0
    Top = 89
    Width = 1126
    Height = 390
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 1122
    ExplicitHeight = 389
    object Panel1: TPanel
      Left = 1
      Top = 291
      Width = 1124
      Height = 98
      Align = alBottom
      TabOrder = 0
      ExplicitTop = 290
      ExplicitWidth = 1120
      object btF12: TcxButton
        Left = 10
        Top = 16
        Width = 103
        Height = 57
        Caption = 'F12'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 0
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object btF3: TcxButton
        Left = 116
        Top = 16
        Width = 103
        Height = 57
        Caption = 'F3'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 1
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object btF6: TcxButton
        Left = 328
        Top = 16
        Width = 103
        Height = 57
        Caption = 'F6'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 2
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object btF5: TcxButton
        Left = 541
        Top = 16
        Width = 103
        Height = 57
        Caption = 'F5'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 3
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object btF7: TcxButton
        Left = 434
        Top = 16
        Width = 103
        Height = 57
        Caption = 'F7'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 4
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object lblCobro: TcxLabel
        Left = 31
        Top = 71
        Caption = 'Cobro'
      end
      object lblBuscar: TcxLabel
        Left = 135
        Top = 71
        Caption = 'Buscar'
      end
      object lblTarifa: TcxLabel
        Left = 351
        Top = 71
        Caption = 'Tarifa'
      end
      object lblIndIVA: TcxLabel
        Left = 446
        Top = 71
        Caption = 'Ind. IVA'
      end
      object lblOtro: TcxLabel
        Left = 569
        Top = 71
        Caption = 'Otro'
      end
      object lblTotal: TcxLabel
        Left = 704
        Top = 5
        AutoSize = False
        Caption = 'Total'
        ParentFont = False
        Style.BorderStyle = ebsOffice11
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clNavy
        Style.Font.Height = -17
        Style.Font.Name = 'Lucida Sans'
        Style.Font.Style = [fsBold]
        Style.Shadow = True
        Style.IsFontAssigned = True
        Properties.LabelStyle = cxlsLowered
        Properties.LineOptions.Alignment = cxllaTop
        Properties.LineOptions.Visible = True
        Properties.Orientation = cxoRight
        Properties.WordWrap = True
        Height = 80
        Width = 401
      end
      object btF8: TcxButton
        Left = 222
        Top = 16
        Width = 103
        Height = 57
        Caption = 'F8'
        Colors.Default = clBlue
        Colors.Normal = clBlue
        Colors.NormalText = clNavy
        TabOrder = 11
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlue
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = [fsUnderline]
        ParentFont = False
      end
      object lblEliminar: TcxLabel
        Left = 233
        Top = 71
        Caption = 'Eliminar'
      end
    end
    object Panel2: TPanel
      Left = 1
      Top = 1
      Width = 1124
      Height = 290
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 1120
      ExplicitHeight = 289
      object grdLineasVenta: TcxGrid
        Left = 1
        Top = 1
        Width = 1122
        Height = 288
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        ExplicitWidth = 1118
        ExplicitHeight = 287
        object tvLineasCaja: TcxGridDBTableView
          Navigator.Buttons.CustomButtons = <>
          ScrollbarAnnotations.CustomAnnotations = <>
          DataController.Summary.DefaultGroupSummaryItems = <>
          DataController.Summary.FooterSummaryItems = <>
          DataController.Summary.SummaryGroups = <>
          OptionsView.GroupByBox = False
          object tvEmpleado: TcxGridDBColumn
            Caption = 'Empl.'
            DataBinding.IsNullValueType = True
            Width = 66
          end
          object tvArtículo: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.IsNullValueType = True
            Width = 135
          end
          object tvDescripción: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.IsNullValueType = True
            Width = 306
          end
          object tvUds: TcxGridDBColumn
            Caption = 'Uds.'
            DataBinding.IsNullValueType = True
          end
          object tvPrecioUni: TcxGridDBColumn
            Caption = 'Precio'
            DataBinding.IsNullValueType = True
            Width = 91
          end
          object tvDescuento: TcxGridDBColumn
            Caption = '%'
            DataBinding.IsNullValueType = True
            Width = 43
          end
          object tvDescuentoMenos: TcxGridDBColumn
            Caption = 'Menos'
            DataBinding.IsNullValueType = True
            Width = 152
          end
          object tvTotal: TcxGridDBColumn
            Caption = 'Total'
            DataBinding.IsNullValueType = True
            Width = 137
          end
        end
        object grdLineasVentaLv1: TcxGridLevel
          GridView = tvLineasCaja
        end
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
    Style.Font.Height = -17
    Style.Font.Name = 'Lucida Sans'
    Style.Font.Style = [fsBold]
    Style.Shadow = True
    Style.IsFontAssigned = True
    Properties.LineOptions.Alignment = cxllaBottom
    Properties.LineOptions.Visible = True
    Properties.Orientation = cxoRight
    Properties.WordWrap = True
    Height = 36
    Width = 85
  end
  object btedtCliente: TcxButtonEdit
    Left = 554
    Top = 30
    Properties.Buttons = <
      item
        Default = True
        Kind = bkEllipsis
      end>
    TabOrder = 3
    Text = 'cxButtonEdit1'
    Width = 134
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 1040
    Top = 32
  end
end
