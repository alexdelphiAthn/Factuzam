inherited frmPrint: TfrmPrint
  Left = 506
  Top = 279
  HorzScrollBar.Visible = False
  BorderStyle = bsSingle
  Caption = 'Imprimir'
  ClientHeight = 265
  ClientWidth = 351
  FormStyle = fsStayOnTop
  Scaled = False
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 367
  ExplicitHeight = 304
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 207
    Top = 0
    Width = 144
    Height = 265
    Align = alRight
    TabOrder = 0
    ExplicitLeft = 203
    ExplicitHeight = 264
    object btnPDF: TcxButton
      Left = 0
      Top = 48
      Width = 142
      Height = 25
      Caption = '&PDF'
      TabOrder = 2
      OnClick = btnPDFClick
    end
    object btnImprimir: TcxButton
      Left = 0
      Top = 120
      Width = 142
      Height = 25
      Caption = '&Imprimir'
      TabOrder = 4
      OnClick = btnImprimirClick
    end
    object btnVistaPreliminar: TcxButton
      Left = 0
      Top = 0
      Width = 142
      Height = 25
      Caption = '&Vista Preliminar'
      TabOrder = 0
      OnClick = btnVistaPreliminarClick
    end
    object btnSalir: TcxButton
      Left = 1
      Top = 239
      Width = 142
      Height = 25
      Align = alBottom
      Caption = '&Salir'
      TabOrder = 5
      OnClick = btnSalirClick
      ExplicitTop = 238
    end
    object btnEditar: TcxButton
      Left = 0
      Top = 72
      Width = 142
      Height = 25
      Caption = '&Editar'
      TabOrder = 3
      OnClick = btnEditarClick
    end
    object btnExcel: TcxButton
      Left = 0
      Top = 24
      Width = 142
      Height = 25
      Caption = 'E&xcel'
      TabOrder = 1
      OnClick = btnExcelClick
    end
  end
  object frxrprt1: TfrxReport
    Version = '2026.1.7'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick]
    PreviewOptions.Zoom = 1.00000000000000000
    PrintOptions.Printer = 'Por defecto'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.Author = 'FactuZam'
    ReportOptions.CreateDate = 42481.63467574070000000
    ReportOptions.LastChange = 43706.46955840281000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      'end.          ')
    Left = 80
    Top = 64
    Datasets = <>
    Variables = <>
    Style = <>
    Watermarks = <>
    object Data: TfrxDataPage
      Height = 1000.00000000000000000
      Width = 1000.00000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.00000000000000000
      PaperHeight = 297.00000000000000000
      PaperSize = 9
      LeftMargin = 5.00000000000000000
      RightMargin = 5.00000000000000000
      TopMargin = 20.00000000000000000
      BottomMargin = 20.00000000000000000
      Frame.Typ = []
      MirrorMode = []
    end
  end
  object frxpdfxprtPedWeb: TfrxPDFExport
    UseFileCache = True
    ShowProgress = True
    OverwritePrompt = False
    DataOnly = False
    Compressed = False
    EmbeddedFonts = True
    InteractiveFormsFontSubset = 'A-Z,a-z,0-9,#43-#47 '
    OpenAfterExport = False
    PrintOptimized = True
    Outline = False
    Background = False
    Quality = 95
    Transparency = False
    Author = 'Alejandro Laorden Hidalgo'
    Subject = 'FactuZam'
    Creator = 'FactuZam Software de Gesti'#243'n Retail'
    Producer = 'FactuZam Printing System'
    ProtectionFlags = [ePrint, eModify, eCopy, eAnnot]
    HideToolbar = False
    HideMenubar = False
    HideWindowUI = False
    FitWindow = False
    CenterWindow = False
    PrintScaling = False
    PdfA = False
    PDFStandard = psNone
    PDFVersion = pv14
    PDFColorSpace = csDeviceRGB
    Left = 88
    Top = 120
  end
  object frxlsxprtExcel: TfrxXLSXExport
    UseFileCache = True
    ShowProgress = True
    OverwritePrompt = False
    CreationTime = 44864.74243649306000000
    DataOnly = False
    ChunkSize = 0
    OpenAfterExport = False
    PictureType = gpPNG
    Left = 176
    Top = 120
  end
  object unqryPerfiles: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_PERFILES = :FormName)'
      'and (USUARIO_GRUPO_PERFILES = :Usuario OR'
      '     USUARIO_GRUPO_PERFILES = :Grupo   OR'
      '     USUARIO_GRUPO_PERFILES = :Todos)')
    Left = 16
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'FormName'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'Usuario'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'Grupo'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'Todos'
        Value = nil
      end>
  end
  object dsPerfiles: TDataSource
    DataSet = unqryPerfiles
    Left = 16
    Top = 64
  end
  object frxdsgnr1: TfrxDesigner
    CloseQuery = False
    DefaultScriptLanguage = 'PascalScript'
    DefaultFont.Charset = DEFAULT_CHARSET
    DefaultFont.Color = clWindowText
    DefaultFont.Height = -13
    DefaultFont.Name = 'Arial'
    DefaultFont.Style = []
    DefaultLeftMargin = 10.00000000000000000
    DefaultRightMargin = 10.00000000000000000
    DefaultTopMargin = 10.00000000000000000
    DefaultBottomMargin = 10.00000000000000000
    DefaultPaperSize = 9
    DefaultOrientation = poPortrait
    GradientEnd = 11982554
    GradientStart = clWindow
    TemplatesExt = 'fr3'
    Restrictions = [drDontEditReportScript]
    RTLLanguage = False
    MemoParentFont = False
    OnSaveReport = frxdsgnr1SaveReport
    Left = 16
    Top = 120
  end
  object frxReportOrigen: TfrxReport
    Version = '2026.1.7'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick]
    PreviewOptions.Zoom = 1.00000000000000000
    PrintOptions.Printer = 'Por defecto'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.Author = 'FactuZam'
    ReportOptions.CreateDate = 42481.63467574070000000
    ReportOptions.LastChange = 43706.46955840281000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      'end.          ')
    Left = 152
    Top = 16
    Datasets = <>
    Variables = <>
    Style = <>
    Watermarks = <>
    object Data: TfrxDataPage
      Height = 1000.00000000000000000
      Width = 1000.00000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.00000000000000000
      PaperHeight = 297.00000000000000000
      PaperSize = 9
      LeftMargin = 5.00000000000000000
      RightMargin = 5.00000000000000000
      TopMargin = 20.00000000000000000
      BottomMargin = 20.00000000000000000
      Frame.Typ = []
      MirrorMode = []
    end
  end
  object ActionList1: TActionList
    Left = 160
    Top = 184
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
  end
  object frLocalizationController1: TfrLocalizationController
    Language = 'Spanish'
    Left = 64
    Top = 184
  end
end
