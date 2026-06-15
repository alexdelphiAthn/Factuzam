object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'Convertir Borrador en XML electr'#243'nico'
  ClientHeight = 522
  ClientWidth = 1091
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object DBGrid1: TDBGrid
    Left = 24
    Top = 40
    Width = 585
    Height = 273
    DataSource = DataSource1
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
  object ButtonGenerate: TButton
    Left = -16
    Top = 440
    Width = 625
    Height = 25
    Caption = 'Generar XML'
    TabOrder = 2
    OnClick = ButtonGenerateClick
  end
  object btSaveFile: TButton
    Left = 624
    Top = 440
    Width = 459
    Height = 25
    Caption = 'Grabar fichero'
    TabOrder = 3
    OnClick = btSaveFileClick
  end
  object MemoXML: TSynEdit
    Left = 624
    Top = 40
    Width = 459
    Height = 394
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    Font.Quality = fqClearTypeNatural
    TabOrder = 4
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Consolas'
    Gutter.Font.Style = []
    Gutter.Bands = <
      item
        Kind = gbkMarks
        Width = 13
      end
      item
        Kind = gbkLineNumbers
      end
      item
        Kind = gbkFold
      end
      item
        Kind = gbkTrackChanges
      end
      item
        Kind = gbkMargin
        Width = 3
      end>
    Highlighter = SynXMLSyn1
    Options = [eoAltSetsColumnMode, eoAutoIndent, eoDisableScrollArrows, eoDragDropEditing, eoDropFiles, eoEnhanceHomeKey, eoEnhanceEndKey, eoGroupUndo, eoHideShowScrollbars, eoKeepCaretX, eoShowScrollHint, eoSmartTabDelete, eoTabIndent, eoTabsToSpaces, eoShowLigatures]
    SelectedColor.Alpha = 0.400000005960464500
  end
  object Button1: TButton
    Left = 288
    Top = 480
    Width = 625
    Height = 25
    Caption = 'Generar XML'
    TabOrder = 5
    OnClick = Button1Click
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 304
    Top = 224
  end
  object UniConnection1: TUniConnection
    ProviderName = 'MySQL'
    Port = 3310
    Database = 'factuzam'
    Username = 'root'
    Server = '127.0.0.1'
    LoginPrompt = False
    Left = 416
    Top = 224
    EncryptedPassword = 'A5FF9EFF92FF90FF8DFF9EFFCDFFCFFFCDFFCCFF'
  end
  object UniQuery1: TUniQuery
    Connection = UniConnection1
    Left = 192
    Top = 232
  end
  object DataSource1: TDataSource
    DataSet = UniQuery1
    Left = 80
    Top = 240
  end
  object UniQuery2: TUniQuery
    Connection = UniConnection1
    Left = 192
    Top = 296
  end
  object SynXMLSyn1: TSynXMLSyn
    WantBracesParsed = False
    Left = 536
    Top = 248
  end
end
