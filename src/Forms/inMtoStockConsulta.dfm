object frmStockConsulta: TfrmStockConsulta
  Left = 0
  Top = 0
  Caption = 'Consulta de stock (Ctrl+U)'
  ClientHeight = 620
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnClose = FormClose
  TextHeight = 17
  object pnlCabecera: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 130
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblArt: TcxLabel
      Left = 16
      Top = 16
      Caption = 'Art'#237'culo'
      Transparent = True
    end
    object btnArt: TcxButtonEdit
      Left = 90
      Top = 14
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnArtPropertiesButtonClick
      Properties.OnEditValueChanged = btnArtPropertiesEditValueChanged
      TabOrder = 0
      Width = 200
    end
    object lblDescr: TcxLabel
      Left = 16
      Top = 56
      Caption = ''
      Style.IsFontAssigned = True
      Style.Font.Style = [fsBold]
      Properties.WordWrap = True
      Transparent = True
      Width = 600
    end
    object imgFoto: TImage
      Left = 770
      Top = 8
      Width = 114
      Height = 114
      Anchors = [akTop, akRight]
      Center = True
      Proportional = True
      Stretch = True
    end
  end
  object pnlFiltros: TPanel
    Left = 0
    Top = 130
    Width = 900
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblEstado: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Estado del stock'
      Transparent = True
    end
    object cbbEstado: TcxComboBox
      Left = 150
      Top = 10
      Properties.DropDownListStyle = lsFixedList
      Properties.OnEditValueChanged = cbbEstadoPropertiesEditValueChanged
      TabOrder = 0
      Width = 200
    end
  end
  object grdStock: TcxGrid
    Left = 0
    Top = 174
    Width = 900
    Height = 226
    Align = alClient
    TabOrder = 2
    object tvStock: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      OptionsBehavior.IncSearch = True
      OptionsView.GroupByBox = False
      object colSku: TcxGridDBColumn
        Caption = 'SKU'
        DataBinding.FieldName = 'CODIGO_UNIDAD_SKU'
        Width = 200
      end
      object colColorAv: TcxGridDBColumn
        Caption = 'Color'
        DataBinding.FieldName = 'COLOR_AV'
        Width = 140
      end
      object colTallaAv: TcxGridDBColumn
        Caption = 'Talla'
        DataBinding.FieldName = 'TALLA_AV'
        Width = 100
      end
      object colAlmacen: TcxGridDBColumn
        Caption = 'Almac'#233'n'
        DataBinding.FieldName = 'CODIGO_ALM_ALM'
        Width = 120
      end
      object colCantidad: TcxGridDBColumn
        Caption = 'Cantidad'
        DataBinding.FieldName = 'CANTIDAD'
        PropertiesClassName = 'TcxCurrencyEditProperties'
        Properties.DisplayFormat = '#,##0.##'
        HeaderAlignmentHorz = taRightJustify
        Width = 100
      end
    end
    object glStock: TcxGridLevel
      GridView = tvStock
    end
  end
  object pnlEjes: TPanel
    Left = 0
    Top = 400
    Width = 900
    Height = 220
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object pcEje: TcxPageControl
      Left = 0
      Top = 0
      Width = 240
      Height = 220
      Align = alLeft
      TabOrder = 0
      Properties.ActivePage = tsPorAlmacen
      Properties.CustomButtons.Buttons = <>
      OnChange = pcEjeChange
      ClientRectBottom = 218
      ClientRectRight = 238
      ClientRectTop = 29
      object tsPorColor: TcxTabSheet
        Caption = 'Por Color'
        ImageIndex = 0
      end
      object tsPorAlmacen: TcxTabSheet
        Caption = 'Por Almac'#233'n'
        ImageIndex = 1
      end
    end
    object lblAlmacenes: TcxLabel
      Left = 248
      Top = 6
      Caption = 'Almacenes'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object clbAlmacenes: TcxCheckListBox
      Left = 248
      Top = 30
      Width = 645
      Height = 184
      Anchors = [akLeft, akTop, akRight, akBottom]
      OnClickCheck = clbAlmacenesClickCheck
      TabOrder = 2
    end
  end
end
