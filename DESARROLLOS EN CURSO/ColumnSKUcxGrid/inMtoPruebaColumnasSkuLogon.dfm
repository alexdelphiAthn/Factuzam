object frmMtoPruebaColumnasSkuLogon: TfrmMtoPruebaColumnasSkuLogon
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Conexi'#243'n BBDD '#8212' Prueba ColumnSKUcxGrid'
  ClientHeight = 226
  ClientWidth = 334
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblServidor: TcxLabel
    Left = 16
    Top = 16
    Caption = 'Servidor'
  end
  object txtServidor: TcxTextEdit
    Left = 120
    Top = 14
    TabOrder = 0
    Text = 'localhost'
    Width = 145
  end
  object lblPuerto: TcxLabel
    Left = 16
    Top = 48
    Caption = 'Puerto'
  end
  object spnPuerto: TcxSpinEdit
    Left = 120
    Top = 46
    Properties.MaxValue = 65535.000000000000000000
    Properties.MinValue = 1.000000000000000000
    TabOrder = 1
    Value = 3306
    Width = 89
  end
  object lblBaseDatos: TcxLabel
    Left = 16
    Top = 80
    Caption = 'Base de datos'
  end
  object txtBaseDatos: TcxTextEdit
    Left = 120
    Top = 78
    TabOrder = 2
    Text = 'factuzam'
    Width = 145
  end
  object lblUsuario: TcxLabel
    Left = 16
    Top = 112
    Caption = 'Usuario'
  end
  object txtUsuario: TcxTextEdit
    Left = 120
    Top = 110
    TabOrder = 3
    Text = 'root'
    Width = 145
  end
  object lblPassword: TcxLabel
    Left = 16
    Top = 144
    Caption = 'Contrase'#241'a'
  end
  object txtPassword: TcxTextEdit
    Left = 120
    Top = 142
    Properties.EchoMode = eemPassword
    TabOrder = 4
    Text = ''
    Width = 145
  end
  object btnConectar: TcxButton
    Left = 120
    Top = 182
    Width = 90
    Height = 27
    Caption = 'Conectar'
    Default = True
    TabOrder = 5
    OnClick = btnConectarClick
  end
  object btnCancelar: TcxButton
    Left = 220
    Top = 182
    Width = 90
    Height = 27
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 6
  end
end
