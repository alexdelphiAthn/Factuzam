inherited frmMtoOpeTraspaso: TfrmMtoOpeTraspaso
  Caption = 'Traspasos'
  ClientHeight = 600
  ClientWidth = 900
  KeyPreview = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 89
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object lblOrigen: TcxLabel
      Left = 16
      Top = 18
      Caption = 'ALMAC'#201'N ORIGEN'
    end
    object txtOrigen: TcxTextEdit
      Left = 150
      Top = 15
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 220
    end
    object lblDestino: TcxLabel
      Left = 420
      Top = 18
      Caption = 'ALMAC'#201'N DESTINO'
    end
    object cboDestino: TcxComboBox
      Left = 560
      Top = 15
      TabOrder = 1
      Width = 300
    end
  end
  object pnlEntrada: TPanel
    Left = 0
    Top = 89
    Width = 900
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 1
    object lblSku: TcxLabel
      Left = 16
      Top = 16
      Caption = 'Art'#237'culo / SKU'
    end
    object txtSku: TcxTextEdit
      Left = 130
      Top = 13
      TabOrder = 0
      Width = 300
    end
    object lblCantidad: TcxLabel
      Left = 450
      Top = 16
      Caption = 'Uds'
    end
    object spnCantidad: TcxSpinEdit
      Left = 490
      Top = 13
      Properties.MinValue = 1.000000000000000000
      TabOrder = 1
      Value = 1
      Width = 70
    end
    object btnAnadir: TcxButton
      Left = 580
      Top = 11
      Width = 110
      Height = 25
      Caption = 'A'#241'adir (Intro)'
      Default = True
      TabOrder = 2
      OnClick = btnAnadirClick
    end
    object btnQuitar: TcxButton
      Left = 700
      Top = 11
      Width = 110
      Height = 25
      Caption = 'Quitar (F3)'
      TabOrder = 3
      OnClick = btnQuitarClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 540
    Width = 900
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 2
    object lblTotal: TcxLabel
      Left = 16
      Top = 20
      Caption = 'Importe traspaso: 0,00'
    end
    object btnF11: TcxButton
      Left = 520
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F11 '#183' Sin ticket'
      TabOrder = 0
      OnClick = btnF11Click
    end
    object btnF12: TcxButton
      Left = 700
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F12 '#183' Con ticket'
      TabOrder = 1
      OnClick = btnF12Click
    end
  end
  object pnlCentro: TPanel
    Left = 0
    Top = 138
    Width = 900
    Height = 402
    Align = alClient
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 3
  end
end
