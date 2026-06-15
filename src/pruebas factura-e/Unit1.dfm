object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'Convertir Borrador en XML electr'#243'nico'
  ClientHeight = 488
  ClientWidth = 1091
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  TextHeight = 15
  object DBGrid1: TDBGrid
    Left = 24
    Top = 40
    Width = 585
    Height = 273
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -15
    TitleFont.Name = 'Lucida Sans'
    TitleFont.Style = []
  end
  object DBGrid2: TDBGrid
    Left = 24
    Top = 319
    Width = 585
    Height = 115
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -15
    TitleFont.Name = 'Lucida Sans'
    TitleFont.Style = []
  end
  object MemoXML: TMemo
    Left = 632
    Top = 40
    Width = 451
    Height = 394
    TabOrder = 2
  end
  object ButtonGenerate: TButton
    Left = 176
    Top = 440
    Width = 625
    Height = 25
    Caption = 'Generar XML'
    TabOrder = 3
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 304
    Top = 224
  end
  object UniConnection1: TUniConnection
    Left = 416
    Top = 224
  end
  object UniQuery1: TUniQuery
    Connection = UniConnection1
    Left = 192
    Top = 232
  end
  object DataSource1: TDataSource
    Left = 80
    Top = 240
  end
  object UniQuery2: TUniQuery
    Connection = UniConnection1
    Left = 192
    Top = 296
  end
end
