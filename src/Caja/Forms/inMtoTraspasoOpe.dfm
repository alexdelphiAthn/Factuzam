inherited frmMtoOpeTraspaso: TfrmMtoOpeTraspaso
  Caption = 'Traspasos'
  ClientHeight = 639
  ClientWidth = 896
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 912
  ExplicitHeight = 678
  TextHeight = 17
  object pnlModos: TPanel [0]
    Left = 0
    Top = 0
    Width = 896
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 894
    object btnModoTraspaso: TcxButton
      Left = 12
      Top = 6
      Width = 200
      Height = 28
      Caption = 'Traspaso'
      TabOrder = 0
      OnClick = btnModoClick
    end
    object btnModoSolicitar: TcxButton
      Tag = 1
      Left = 220
      Top = 6
      Width = 220
      Height = 28
      Caption = 'F6 Solicitar a otro almac'#233'n'
      TabOrder = 1
      OnClick = btnModoClick
    end
    object btnModoAtender: TcxButton
      Tag = 2
      Left = 448
      Top = 6
      Width = 200
      Height = 28
      Caption = 'F8 Atender solicitudes'
      TabOrder = 2
      OnClick = btnModoClick
    end
  end
  object pnlTop: TPanel [1]
    Left = 0
    Top = 40
    Width = 896
    Height = 89
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 894
    object lblOrigen: TcxLabel
      Left = 16
      Top = 18
      Caption = 'ALMAC'#201'N ORIGEN'
      TabOrder = 3
    end
    object txtOrigen: TcxTextEdit
      Left = 163
      Top = 14
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 222
    end
    object lblDestino: TcxLabel
      Left = 420
      Top = 18
      Caption = 'ALMAC'#201'N DESTINO'
      TabOrder = 4
    end
    object cboDestino: TcxComboBox
      Left = 576
      Top = 14
      TabOrder = 1
      Width = 304
    end
    object lblEmpleado: TcxLabel
      Left = 16
      Top = 56
      Caption = 'Empleado (responsable)'
      TabOrder = 5
    end
    object txtEmpleado: TcxButtonEdit
      Left = 200
      Top = 52
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = txtEmpleadoButtonClick
      TabOrder = 2
      OnExit = txtEmpleadoExit
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 330
      Top = 56
      TabOrder = 6
    end
  end
  object pnlBottom: TPanel [2]
    Left = 0
    Top = 579
    Width = 896
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 571
    ExplicitWidth = 894
    object lblTotal: TcxLabel
      Left = 16
      Top = 20
      Caption = 'Importe traspaso: 0,00'
      TabOrder = 2
    end
    object btnF11: TcxButton
      Left = 520
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F11 Sin ticket'
      TabOrder = 0
      OnClick = btnF11Click
    end
    object btnF12: TcxButton
      Left = 700
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F12 Con ticket'
      TabOrder = 1
      OnClick = btnF12Click
    end
  end
  object pnlCentro: TPanel [3]
    Left = 0
    Top = 129
    Width = 896
    Height = 450
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 894
    ExplicitHeight = 442
    object FGrid: TcxGrid
      Left = 0
      Top = 0
      Width = 896
      Height = 272
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 894
      ExplicitHeight = 264
      object FView: TcxGridDBTableView
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.FocusFirstCellOnNewRecord = True
        OptionsBehavior.GoToNextCellOnEnter = True
      end
      object lvlLineas: TcxGridLevel
        GridView = FView
      end
    end
    object FStockPanel: TPanel
      Left = 0
      Top = 280
      Width = 896
      Height = 170
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 272
      ExplicitWidth = 894
      object FFotoPanel: TPanel
        Left = 736
        Top = 0
        Width = 160
        Height = 170
        Align = alRight
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitLeft = 734
        object FFotoImg: TImage
          Left = 0
          Top = 0
          Width = 160
          Height = 170
          Align = alClient
          Center = True
          Proportional = True
        end
      end
      object FFotoSplitter: TcxSplitter
        Left = 728
        Top = 0
        Width = 8
        Height = 170
        AlignSplitter = salRight
        Control = FFotoPanel
        ExplicitLeft = 726
      end
      object FStockGrid: TcxGrid
        Left = 0
        Top = 0
        Width = 728
        Height = 170
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 726
        object FStockView: TcxGridDBTableView
        end
        object lvlStock: TcxGridLevel
          GridView = FStockView
        end
      end
    end
    object FStockSplitter: TcxSplitter
      Left = 0
      Top = 272
      Width = 896
      Height = 8
      AlignSplitter = salBottom
      ExplicitTop = 264
      ExplicitWidth = 894
    end
  end
end
