object frmMtoPruebaColumnasSku: TfrmMtoPruebaColumnasSku
  Left = 0
  Top = 0
  Caption = 'Prueba ColumnSKUcxGrid'
  ClientHeight = 477
  ClientWidth = 904
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 904
    Height = 61
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblAlmacen: TcxLabel
      Left = 8
      Top = 8
      Caption = 'Almac'#233'n stock'
    end
    object txtAlmacen: TcxTextEdit
      Left = 8
      Top = 28
      TabOrder = 1
      Text = ''
      Width = 105
    end
    object rgModo: TcxRadioGroup
      Left = 128
      Top = 4
      Caption = 'Modo de columnas'
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = 'Auto'
        end
        item
          Caption = 'SKU'
        end
        item
          Caption = 'Desglose'
        end>
      ItemIndex = 0
      TabOrder = 2
      Height = 51
      Width = 265
    end
    object btnConstruir: TcxButton
      Left = 408
      Top = 20
      Width = 90
      Height = 27
      Caption = 'Construir'
      TabOrder = 3
      OnClick = btnConstruirClick
    end
    object lblEstado: TcxLabel
      Left = 512
      Top = 24
      Caption = '-'
    end
  end
  object cxgrdLineas: TcxGrid
    Left = 0
    Top = 61
    Width = 904
    Height = 416
    Align = alClient
    TabOrder = 1
    object tvLineas: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
      OptionsView.GroupByBox = False
    end
    object glLineas: TcxGridLevel
      GridView = tvLineas
    end
  end
end
