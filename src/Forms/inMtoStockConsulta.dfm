object frmStockConsulta: TfrmStockConsulta
  Left = 0
  Top = 0
  Caption = 'Consulta de stock (Ctrl+U)'
  ClientHeight = 612
  ClientWidth = 898
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Lucida Sans'
  Font.Style = []
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 19
  object pnlCabecera: TPanel
    Left = 0
    Top = 0
    Width = 898
    Height = 200
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      898
      200)
    object imgFoto: TImage
      Left = 740
      Top = 12
      Width = 138
      Height = 133
      Anchors = [akTop, akRight]
      Center = True
      Proportional = True
      Stretch = True
      ExplicitLeft = 744
    end
    object lblArt: TcxLabel
      Left = 16
      Top = 14
      Caption = 'Art'#237'culo'
      TabOrder = 1
      Transparent = True
    end
    object btnArt: TcxButtonEdit
      Left = 90
      Top = 12
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
      Top = 46
      Properties.WordWrap = False
      TabOrder = 2
      Transparent = True
      Width = 720
    end
    object lblInfo: TcxLabel
      Left = 16
      Top = 78
      Anchors = [akLeft, akTop, akRight]
      Properties.WordWrap = True
      TabOrder = 3
      Transparent = True
      Width = 734
    end
  end
  object pnlFiltros: TPanel
    Left = 0
    Top = 200
    Width = 898
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblEstado: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Estado del stock'
      TabOrder = 1
      Transparent = True
    end
    object cbbEstado: TcxComboBox
      Left = 162
      Top = 10
      Properties.DropDownListStyle = lsFixedList
      Properties.OnEditValueChanged = cbbEstadoPropertiesEditValueChanged
      TabOrder = 0
      Width = 188
    end
  end
  object grdStock: TcxGrid
    Left = 0
    Top = 244
    Width = 898
    Height = 148
    Align = alClient
    TabOrder = 2
    object tvStock: TcxGridDBTableView
      OptionsCustomize.ColumnMoving = False
      OptionsData.Editing = False
      OptionsView.GroupByBox = False
    end
    object glStock: TcxGridLevel
      GridView = tvStock
    end
  end
  object pnlEjes: TPanel
    Left = 0
    Top = 392
    Width = 898
    Height = 220
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object pcEje: TcxPageControl
      Left = 0
      Top = 0
      Width = 898
      Height = 220
      Align = alClient
      TabOrder = 0
      Properties.ActivePage = tsPorAlmacen
      Properties.CustomButtons.Buttons = <>
      OnChange = pcEjeChange
      ClientRectBottom = 218
      ClientRectLeft = 2
      ClientRectRight = 896
      ClientRectTop = 29
      object tsPorColor: TcxTabSheet
        Caption = 'Por Color'
        ImageIndex = 0
        object lblColores: TcxLabel
          Left = 8
          Top = 4
          Caption = 'Colores del art'#237'culo'
          Transparent = True
        end
        object clbColores: TcxCheckListBox
          Left = 8
          Top = 32
          Width = 878
          Height = 153
          Anchors = [akLeft, akTop, akRight, akBottom]
          Items = <>
          TabOrder = 0
          OnClickCheck = clbColoresClickCheck
        end
      end
      object tsPorAlmacen: TcxTabSheet
        Caption = 'Por Almac'#233'n'
        ImageIndex = 1
        object lblAlmacenes: TcxLabel
          Left = 8
          Top = 4
          Caption = 'Almacenes'
          Transparent = True
        end
        object clbAlmacenes: TcxCheckListBox
          Left = 8
          Top = 32
          Width = 878
          Height = 153
          Anchors = [akLeft, akTop, akRight, akBottom]
          Items = <>
          TabOrder = 0
          OnClickCheck = clbAlmacenesClickCheck
        end
      end
    end
  end
end
