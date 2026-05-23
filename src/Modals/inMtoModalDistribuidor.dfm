inherited frmModalDistribuidor: TfrmModalDistribuidor
  Caption = 'Distribuidor por almac'#233'n / talla'
  ClientHeight = 360
  ClientWidth = 720
  StyleElements = [seFont, seClient, seBorder]
  Position = poScreenCenter
  ExplicitWidth = 736
  ExplicitHeight = 399
  TextHeight = 19
  object pnlCab: TPanel [0]
    Left = 0
    Top = 0
    Width = 720
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Distribuci'#243'n almac'#233'n / talla'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object lblLinea: TcxLabel
      Left = 320
      Top = 14
      Caption = 'L'#237'nea:'
      Transparent = True
    end
    object edtLinea: TcxTextEdit
      Left = 380
      Top = 12
      Enabled = False
      TabOrder = 0
      Width = 80
    end
  end
  object pnlCuadrante: TPanel [1]
    Left = 0
    Top = 50
    Width = 720
    Height = 250
    Align = alClient
    BevelOuter = bvNone
    Caption = '(cuadrante almac'#233'n x talla — pendiente de implementar)'
    TabOrder = 1
  end
  object pnlBot: TPanel [2]
    Left = 0
    Top = 300
    Width = 720
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnAceptar: TcxButton
      Left = 472
      Top = 12
      Width = 110
      Height = 38
      Caption = '&Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 590
      Top = 12
      Width = 110
      Height = 38
      Cancel = True
      Caption = '&Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
end
