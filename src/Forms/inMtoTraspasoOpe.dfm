inherited frmMtoOpeTraspaso: TfrmMtoOpeTraspaso
  Caption = 'Traspasos'
  ClientHeight = 640
  ClientWidth = 900
  KeyPreview = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pnlModos: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object btnModoTraspaso: TcxButton
      Tag = 0
      Left = 8
      Top = 6
      Width = 200
      Height = 28
      Caption = 'Traspaso'
      TabOrder = 0
      OnClick = btnModoClick
    end
    object btnModoSolicitar: TcxButton
      Tag = 1
      Left = 216
      Top = 6
      Width = 220
      Height = 28
      Caption = 'Solicitar a otro almacén'
      TabOrder = 1
      OnClick = btnModoClick
    end
    object btnModoAtender: TcxButton
      Tag = 2
      Left = 444
      Top = 6
      Width = 200
      Height = 28
      Caption = 'Atender solicitudes'
      TabOrder = 2
      OnClick = btnModoClick
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 40
    Width = 900
    Height = 89
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 1
    object lblOrigen: TcxLabel
      Left = 16
      Top = 18
      Caption = 'ALMACÉN ORIGEN'
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
      Caption = 'ALMACÉN DESTINO'
    end
    object cboDestino: TcxComboBox
      Left = 560
      Top = 15
      TabOrder = 1
      Width = 320
    end
    object lblEmpleado: TcxLabel
      Left = 16
      Top = 56
      Caption = 'Empleado (responsable)'
    end
    object txtEmpleado: TcxTextEdit
      Left = 200
      Top = 53
      TabOrder = 2
      OnExit = txtEmpleadoExit
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 330
      Top = 56
      Caption = ''
    end
  end
  object pnlEntrada: TPanel
    Left = 0
    Top = 129
    Width = 900
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 2
    object lblSku: TcxLabel
      Left = 16
      Top = 16
      Caption = 'Artículo / SKU'
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
      Width = 130
      Height = 25
      Caption = 'Añadir (Intro)'
      Default = True
      TabOrder = 2
      OnClick = btnAnadirClick
    end
    object btnQuitar: TcxButton
      Left = 720
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
    Top = 580
    Width = 900
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 3
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
      Caption = 'F11 · Sin ticket'
      TabOrder = 0
      OnClick = btnF11Click
    end
    object btnF12: TcxButton
      Left = 700
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F12 · Con ticket'
      TabOrder = 1
      OnClick = btnF12Click
    end
  end
  object pnlCentro: TPanel
    Left = 0
    Top = 178
    Width = 900
    Height = 402
    Align = alClient
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 4
  end
end
