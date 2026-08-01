inherited frmModalGenPass: TfrmModalGenPass
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Establecer Password Usuario'
  ClientHeight = 194
  ClientWidth = 425
  Position = poMainFormCenter
  OnClose = FormClose
  ExplicitWidth = 441
  ExplicitHeight = 233
  TextHeight = 19
  object edtUsuario: TcxTextEdit [0]
    Left = 163
    Top = 24
    Enabled = False
    TabOrder = 0
    Width = 238
  end
  object lbl1: TcxLabel [1]
    Left = 21
    Top = 25
    Caption = 'Nombre usuario'
    Transparent = True
  end
  object edtPassword: TcxTextEdit [2]
    Left = 163
    Top = 64
    Properties.EchoMode = eemPassword
    Properties.PasswordChar = #10026
    TabOrder = 2
    Width = 238
  end
  object lbl2: TcxLabel [3]
    Left = 61
    Top = 65
    Caption = 'Contrase'#241'a'
    Transparent = True
  end
  object edtPasswordCon: TcxTextEdit [4]
    Left = 163
    Top = 104
    Properties.EchoMode = eemPassword
    Properties.PasswordChar = #9679
    TabOrder = 4
    Width = 238
  end
  object lbl3: TcxLabel [5]
    Left = 3
    Top = 105
    Caption = 'Repita Contrase'#241'a'
    Transparent = True
  end
  object btnGuardar: TcxButton [6]
    Left = 256
    Top = 146
    Width = 145
    Height = 25
    Caption = '&Guardar'
    TabOrder = 6
    OnClick = btnGuardarClick
  end
  object btnCancelar: TcxButton [7]
    Left = 42
    Top = 146
    Width = 137
    Height = 25
    Caption = '&Cancelar'
    TabOrder = 7
    OnClick = btnCancelarClick
  end
end
