object FormVisualizador: TFormVisualizador
  Left = 0
  Top = 0
  Caption = 'Visualizador de Ticket T'#233'rmico - ESC/POS'
  ClientHeight = 572
  ClientWidth = 402
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 522
    Width = 402
    Height = 50
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 531
    ExplicitWidth = 408
    object btnCerrar: TButton
      Left = 16
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
    object btnGuardar: TButton
      Left = 130
      Top = 10
      Width = 150
      Height = 30
      Caption = 'Guardar como Imagen'
      TabOrder = 1
      OnClick = btnGuardarClick
    end
  end
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 402
    Height = 522
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 408
    ExplicitHeight = 531
    object Image1: TImage
      Left = 14
      Top = 3
      Width = 384
      Height = 3500
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 344
    Top = 560
  end
end
