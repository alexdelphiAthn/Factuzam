inherited frmPrintBalanceTallas: TfrmPrintBalanceTallas
  Caption = 'Balance de almac'#233'n por tallas'
  ClientHeight = 470
  ClientWidth = 620
  TextHeight = 19
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsBalance
        DataSetName = 'Balance'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
    end
  end
  inherited frxReportOrigen: TfrxReport
    Datasets = <
      item
        DataSet = fxdsBalance
        DataSetName = 'Balance'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitle1: TfrxReportTitle
        Height = 44.000000000000000000
        Top = 0.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 700.000000000000000000
          Height = 24.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Balance de almac'#233'n por tallas')
          ParentFont = False
        end
        object MemoSubtitulo: TfrxMemoView
          Left = 700.000000000000000000
          Top = 8.000000000000000000
          Width = 347.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Impreso el [Date]')
          ParentFont = False
        end
      end
      object GroupHeaderFam: TfrxGroupHeader
        Height = 22.000000000000000000
        Top = 48.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."CODIGO_FAM"'
        Frame.Typ = []
        object MemoFamilia: TfrxMemoView
          Left = 0.000000000000000000
          Top = 3.000000000000000000
          Width = 800.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'FAMILIA   [Balance."CODIGO_FAM"]   [Balance."DESCRIPCION_FAM"]')
          ParentFont = False
        end
      end
      object GroupHeaderArt: TfrxGroupHeader
        Height = 74.000000000000000000
        Top = 74.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."CODIGO_ART_ART"'
        Frame.Typ = []
        object MemoArtLabel: TfrxMemoView
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 64.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'ART'#205'CULO')
          ParentFont = False
        end
        object MemoArtCod: TfrxMemoView
          Left = 64.000000000000000000
          Top = 4.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."CODIGO_ART_ART"]')
          ParentFont = False
        end
        object MemoArtDesc: TfrxMemoView
          Left = 156.000000000000000000
          Top = 4.000000000000000000
          Width = 520.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object MemoArtRef: TfrxMemoView
          Left = 680.000000000000000000
          Top = 4.000000000000000000
          Width = 160.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."REF_PRV"]')
          ParentFont = False
        end
        object foto300: TfrxPictureView
          AllowVectorExport = True
          Left = 983.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 48.000000000000000000
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
        object MemoColHdr: TfrxMemoView
          Left = 80.000000000000000000
          Top = 52.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Color')
          ParentFont = False
        end
        object MemoTH01: TfrxMemoView
          Left = 160.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T01"]')
          ParentFont = False
        end
        object MemoTH02: TfrxMemoView
          Left = 208.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T02"]')
          ParentFont = False
        end
        object MemoTH03: TfrxMemoView
          Left = 256.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T03"]')
          ParentFont = False
        end
        object MemoTH04: TfrxMemoView
          Left = 304.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T04"]')
          ParentFont = False
        end
        object MemoTH05: TfrxMemoView
          Left = 352.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T05"]')
          ParentFont = False
        end
        object MemoTH06: TfrxMemoView
          Left = 400.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T06"]')
          ParentFont = False
        end
        object MemoTH07: TfrxMemoView
          Left = 448.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T07"]')
          ParentFont = False
        end
        object MemoTH08: TfrxMemoView
          Left = 496.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T08"]')
          ParentFont = False
        end
        object MemoTH09: TfrxMemoView
          Left = 544.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T09"]')
          ParentFont = False
        end
        object MemoTH10: TfrxMemoView
          Left = 592.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T10"]')
          ParentFont = False
        end
        object MemoTH11: TfrxMemoView
          Left = 640.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T11"]')
          ParentFont = False
        end
        object MemoTH12: TfrxMemoView
          Left = 688.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T12"]')
          ParentFont = False
        end
        object MemoTH13: TfrxMemoView
          Left = 736.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T13"]')
          ParentFont = False
        end
        object MemoTH14: TfrxMemoView
          Left = 784.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T14"]')
          ParentFont = False
        end
        object MemoCdadHdr: TfrxMemoView
          Left = 834.000000000000000000
          Top = 52.000000000000000000
          Width = 64.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cdad.')
          ParentFont = False
        end
        object MemoPrecioHdr: TfrxMemoView
          Left = 900.000000000000000000
          Top = 52.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Precio')
          ParentFont = False
        end
        object MemoImpHdr: TfrxMemoView
          Left = 972.000000000000000000
          Top = 52.000000000000000000
          Width = 75.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Importe')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 18.000000000000000000
        Top = 152.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsBalance
        DataSetName = 'Balance'
        RowCount = 0
        Frame.Typ = []
        object MemoBanda: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."ETIQUETA_BANDA"]')
          ParentFont = False
        end
        object MemoColor: TfrxMemoView
          Left = 80.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."COLOR"]')
          ParentFont = False
        end
        object MemoT01: TfrxMemoView
          Left = 160.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T01"]')
          ParentFont = False
        end
        object MemoT02: TfrxMemoView
          Left = 208.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T02"]')
          ParentFont = False
        end
        object MemoT03: TfrxMemoView
          Left = 256.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T03"]')
          ParentFont = False
        end
        object MemoT04: TfrxMemoView
          Left = 304.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T04"]')
          ParentFont = False
        end
        object MemoT05: TfrxMemoView
          Left = 352.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T05"]')
          ParentFont = False
        end
        object MemoT06: TfrxMemoView
          Left = 400.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T06"]')
          ParentFont = False
        end
        object MemoT07: TfrxMemoView
          Left = 448.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T07"]')
          ParentFont = False
        end
        object MemoT08: TfrxMemoView
          Left = 496.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T08"]')
          ParentFont = False
        end
        object MemoT09: TfrxMemoView
          Left = 544.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T09"]')
          ParentFont = False
        end
        object MemoT10: TfrxMemoView
          Left = 592.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T10"]')
          ParentFont = False
        end
        object MemoT11: TfrxMemoView
          Left = 640.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T11"]')
          ParentFont = False
        end
        object MemoT12: TfrxMemoView
          Left = 688.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T12"]')
          ParentFont = False
        end
        object MemoT13: TfrxMemoView
          Left = 736.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T13"]')
          ParentFont = False
        end
        object MemoT14: TfrxMemoView
          Left = 784.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T14"]')
          ParentFont = False
        end
        object MemoCdad: TfrxMemoView
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."CANTIDAD"]')
          ParentFont = False
        end
        object MemoPrecio: TfrxMemoView
          Left = 900.000000000000000000
          Top = 1.000000000000000000
          Width = 70.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."PRECIO"]')
          ParentFont = False
        end
        object MemoImporte: TfrxMemoView
          Left = 972.000000000000000000
          Top = 1.000000000000000000
          Width = 75.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."IMPORTE"]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 174.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoPag: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 400.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'P'#225'gina [Page#] de [TotalPages#]')
          ParentFont = False
        end
        object MemoImpreso: TfrxMemoView
          Left = 647.000000000000000000
          Top = 2.000000000000000000
          Width = 400.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Impreso el [Date]')
          ParentFont = False
        end
      end
    end
  end
  object unqryBalancePrint: TUniQuery
    SQL.Strings = (
      'CALL PRC_GET_BALANCE_ALMACEN_TALLAS('
      '  '#39'A'#39', NULL, NULL, '#39#39', '#39#39', '#39#39', '#39#39', '#39'PVP'#39', '#39'N'#39', '#39#39')')
    Left = 96
    Top = 16
  end
  object fxdsBalance: TfrxDBDataset
    Description = 'Balance'
    UserName = 'Balance'
    CloseDataSource = False
    DataSet = unqryBalancePrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
