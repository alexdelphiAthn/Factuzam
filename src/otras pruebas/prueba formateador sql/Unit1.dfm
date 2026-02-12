object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 440
  ClientWidth = 620
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object SpeedButton1: TSpeedButton
    Left = 224
    Top = 280
    Width = 241
    Height = 129
    Caption = 'formatear SQL'
    OnClick = SpeedButton1Click
  end
  object Memo1: TMemo
    Left = 192
    Top = 40
    Width = 329
    Height = 209
    Lines.Strings = (
      'SELECT id, nombre, apellido '
      'FROM usuarios '
      'WHERE activo = 1 AND edad > 18')
    TabOrder = 0
  end
end
