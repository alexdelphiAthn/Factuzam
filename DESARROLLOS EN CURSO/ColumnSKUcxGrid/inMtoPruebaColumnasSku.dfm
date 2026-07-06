inherited frmMtoPruebaColumnasSku: TfrmMtoPruebaColumnasSku
  Caption = 'Prueba ColumnSKUcxGrid (TfrmMtoGen)'
  OnDestroy = FormDestroy
  TextHeight = 17
  inherited pcPantalla: TcxPageControl
    inherited tsFicha: TcxTabSheet
      object pnlTop: TPanel
        Left = 0
        Top = 0
        Width = 1081
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
          Properties.Columns = 2
          Properties.Items = <
            item
              Caption = 'Auto'
            end
            item
              Caption = 'SKU'
            end
            item
              Caption = 'Tallas horizontal'
            end>
          ItemIndex = 0
          TabOrder = 2
          Height = 55
          Width = 265
        end
        object btnConstruir: TcxButton
          Left = 408
          Top = 4
          Width = 90
          Height = 25
          Caption = 'Construir'
          TabOrder = 3
          OnClick = btnConstruirClick
        end
        object btnAddLinea: TcxButton
          Left = 408
          Top = 32
          Width = 90
          Height = 25
          Caption = 'A'#241'adir l'#237'nea'
          TabOrder = 4
          OnClick = btnAddLineaClick
        end
        object chkDistribuido: TcxCheckBox
          Left = 508
          Top = 2
          Caption = 'Almacenes distribuidos'
          TabOrder = 5
          Width = 160
        end
        object lblEstado: TcxLabel
          Left = 512
          Top = 26
          Caption = '-'
        end
      end
      object mLog: TcxMemo
        Left = 0
        Top = 371
        Align = alBottom
        Properties.ReadOnly = True
        Properties.ScrollBars = ssVertical
        TabOrder = 2
        Height = 110
        Width = 1081
      end
      object cxgrdLineas: TcxGrid
        Left = 0
        Top = 61
        Width = 1081
        Height = 310
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
  end
end
