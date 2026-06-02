object frmStockConsulta: TfrmStockConsulta
  Left = 0
  Top = 0
  Caption = 'Consulta de stock (Ctrl+U)'
  ClientHeight = 612
  ClientWidth = 898
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
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
    Height = 256
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      898
      256)
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
  object pnlBody: TPanel
    Left = 0
    Top = 244
    Width = 898
    Height = 368
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object pnlIzq: TPanel
      Left = 0
      Top = 0
      Width = 280
      Height = 368
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object pcFiltros: TcxPageControl
        Left = 0
        Top = 0
        Width = 280
        Height = 368
        Align = alClient
        TabOrder = 0
        Properties.ActivePage = tsColores
        Properties.CustomButtons.Buttons = <>
        object tsColores: TcxTabSheet
          Caption = '1 Colores'
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
            Width = 260
            Height = 301
            Anchors = [akLeft, akTop, akRight, akBottom]
            Items = <>
            TabOrder = 0
            OnClickCheck = clbColoresClickCheck
          end
        end
        object tsAlmacenes: TcxTabSheet
          Caption = '2 Almacenes'
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
            Width = 260
            Height = 301
            Anchors = [akLeft, akTop, akRight, akBottom]
            Items = <>
            TabOrder = 0
            OnClickCheck = clbAlmacenesClickCheck
          end
        end
      end
    end
    object splVert: TSplitter
      Left = 280
      Top = 0
      Height = 368
      ExplicitLeft = 280
      ExplicitTop = 0
      ExplicitHeight = 368
    end
    object pnlDer: TPanel
      Left = 283
      Top = 0
      Width = 615
      Height = 368
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object pcVistas: TcxPageControl
        Left = 0
        Top = 0
        Width = 615
        Height = 30
        Align = alTop
        TabOrder = 0
        Properties.ActivePage = tsPorAlmacen
        Properties.CustomButtons.Buttons = <>
        OnChange = pcVistasChange
        object tsPorAlmacen: TcxTabSheet
          Caption = '3 Por almacenes'
          ImageIndex = 0
        end
        object tsPorColor: TcxTabSheet
          Caption = '4 Por colores'
          ImageIndex = 1
        end
      end
      object grdStock: TcxGrid
        Left = 0
        Top = 30
        Width = 615
        Height = 338
        Align = alClient
        TabOrder = 1
        object tvStock: TcxGridDBTableView
          OptionsCustomize.ColumnMoving = False
          OptionsData.Editing = False
          OptionsView.GroupByBox = False
        end
        object glStock: TcxGridLevel
          GridView = tvStock
        end
      end
    end
  end
  object pnlLeyenda: TPanel
    Left = 0
    Top = 584
    Width = 898
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
  end
end
