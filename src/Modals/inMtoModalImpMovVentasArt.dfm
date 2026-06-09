inherited frmPrintMovVentasArt: TfrmPrintMovVentasArt
  Caption = 'Movimientos de ventas por art'#237'culos y fechas'
  ClientHeight = 470
  ClientWidth = 700
  TextHeight = 19
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsMovVentas
        DataSetName = 'MovVentas'
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
        DataSet = fxdsMovVentas
        DataSetName = 'MovVentas'
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
        Height = 34.000000000000000000
        Top = 0.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 600.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Movimientos de ventas por art'#237'culos y fechas')
          ParentFont = False
        end
        object MemoImpreso: TfrxMemoView
          Left = 700.000000000000000000
          Top = 8.000000000000000000
          Width = 346.000000000000000000
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
      object PageHeader1: TfrxPageHeader
        Height = 20.000000000000000000
        Top = 38.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoHDesc: TfrxMemoView
          Left = 46.000000000000000000
          Top = 2.000000000000000000
          Width = 234.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Art'#237'culo')
          ParentFont = False
        end
        object MemoHUniEnt: TfrxMemoView
          Left = 280.000000000000000000
          Top = 2.000000000000000000
          Width = 50.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Uni.Ent.')
          ParentFont = False
        end
        object MemoHImpEnt: TfrxMemoView
          Left = 330.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Imp.Ent.')
          ParentFont = False
        end
        object MemoHUdsVta: TfrxMemoView
          Left = 394.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Uds Vta')
          ParentFont = False
        end
        object MemoHImpVta: TfrxMemoView
          Left = 442.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Imp Venta')
          ParentFont = False
        end
        object MemoHImpCos: TfrxMemoView
          Left = 506.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Imp Coste')
          ParentFont = False
        end
        object MemoHBenef: TfrxMemoView
          Left = 570.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Beneficio')
          ParentFont = False
        end
        object MemoHPctBnf: TfrxMemoView
          Left = 634.000000000000000000
          Top = 2.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% Bnf')
          ParentFont = False
        end
        object MemoHVtaEnt: TfrxMemoView
          Left = 678.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Venta-Ent')
          ParentFont = False
        end
        object MemoHVentEnt: TfrxMemoView
          Left = 742.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'VentEnt%')
          ParentFont = False
        end
        object MemoHMarg1: TfrxMemoView
          Left = 794.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Margen 1')
          ParentFont = False
        end
        object MemoHMarg2: TfrxMemoView
          Left = 846.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Margen 2')
          ParentFont = False
        end
        object MemoHPctVdto: TfrxMemoView
          Left = 898.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% V.dto')
          ParentFont = False
        end
        object MemoHPctVlast: TfrxMemoView
          Left = 950.000000000000000000
          Top = 2.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% Vlast')
          ParentFont = False
        end
      end
      object GroupHeaderG1: TfrxGroupHeader
        Height = 20.000000000000000000
        Top = 62.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'MovVentas."GRUPO1_COD"'
        Frame.Typ = []
        object MemoGrupo1: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[MovVentas."GRUPO1_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderG2: TfrxGroupHeader
        Height = 20.000000000000000000
        Top = 84.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'MovVentas."GRUPO2_COD"'
        Frame.Typ = []
        object MemoGrupo2: TfrxMemoView
          Left = 14.000000000000000000
          Top = 2.000000000000000000
          Width = 1032.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[MovVentas."GRUPO2_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderG3: TfrxGroupHeader
        Height = 20.000000000000000000
        Top = 106.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'MovVentas."GRUPO3_COD"'
        Frame.Typ = []
        object MemoGrupo3: TfrxMemoView
          Left = 28.000000000000000000
          Top = 2.000000000000000000
          Width = 1018.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[MovVentas."GRUPO3_ETIQ"]')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 34.000000000000000000
        Top = 130.000000000000000000
        Width = 1046.000000000000000000
        DataSet = fxdsMovVentas
        DataSetName = 'MovVentas'
        RowCount = 0
        Frame.Typ = []
        object foto300: TfrxPictureView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 32.000000000000000000
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
        object MemoArtDesc: TfrxMemoView
          Left = 46.000000000000000000
          Top = 1.000000000000000000
          Width = 234.000000000000000000
          Height = 32.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[MovVentas."CODIGO_ART_ART"]'
            '[MovVentas."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object MemoUniEnt: TfrxMemoView
          Left = 280.000000000000000000
          Top = 1.000000000000000000
          Width = 50.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."UNI_ENT_TOT"]')
          ParentFont = False
        end
        object MemoImpEnt: TfrxMemoView
          Left = 330.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."IMP_ENT_TOT"]')
          ParentFont = False
        end
        object MemoUdsVta: TfrxMemoView
          Left = 394.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."UDS_VENTA"]')
          ParentFont = False
        end
        object MemoImpVta: TfrxMemoView
          Left = 442.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."IMP_VENTA"]')
          ParentFont = False
        end
        object MemoImpCos: TfrxMemoView
          Left = 506.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."IMP_COSTE"]')
          ParentFont = False
        end
        object MemoBenef: TfrxMemoView
          Left = 570.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."BENEFICIO"]')
          ParentFont = False
        end
        object MemoPctBnf: TfrxMemoView
          Left = 634.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."PCT_BNFCO"]')
          ParentFont = False
        end
        object MemoVtaEnt: TfrxMemoView
          Left = 678.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."VENTA_ENT"]')
          ParentFont = False
        end
        object MemoVentEnt: TfrxMemoView
          Left = 742.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."VENT_ENT"]')
          ParentFont = False
        end
        object MemoMarg1: TfrxMemoView
          Left = 794.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."MARGEN1"]')
          ParentFont = False
        end
        object MemoMarg2: TfrxMemoView
          Left = 846.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."MARGEN2"]')
          ParentFont = False
        end
        object MemoPctVdto: TfrxMemoView
          Left = 898.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."PCT_VDTO"]')
          ParentFont = False
        end
        object MemoPctVlast: TfrxMemoView
          Left = 950.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[MovVentas."PCT_VLAST"]')
          ParentFont = False
        end
      end
      object GroupFooterG3: TfrxGroupFooter
        Height = 18.000000000000000000
        Top = 172.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoGF3Lbl: TfrxMemoView
          Left = 28.000000000000000000
          Top = 1.000000000000000000
          Width = 252.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [MovVentas."GRUPO3_ETIQ"]')
          ParentFont = False
        end
        object MemoGF3UniEnt: TfrxMemoView
          Left = 280.000000000000000000
          Top = 1.000000000000000000
          Width = 50.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3ImpEnt: TfrxMemoView
          Left = 330.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3UdsVta: TfrxMemoView
          Left = 394.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."UDS_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3ImpVta: TfrxMemoView
          Left = 442.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3ImpCos: TfrxMemoView
          Left = 506.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_COSTE">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3Benef: TfrxMemoView
          Left = 570.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3PctBnf: TfrxMemoView
          Left = 634.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_COSTE">,MasterData1)<>0,SUM(<MovVentas."B' +
            'ENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_COSTE">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoGF3VtaEnt: TfrxMemoView
          Left = 678.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3VentEnt: TfrxMemoView
          Left = 742.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVentas.' +
            '"VENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,MasterData' +
            '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3Marg1: TfrxMemoView
          Left = 794.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."B' +
            'ENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoGF3Marg2: TfrxMemoView
          Left = 846.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."V' +
            'ENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoGF3PctVdto: TfrxMemoView
          Left = 898.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)<>0,SUM(<MovVentas.' +
            '"UDS_VENTA">,MasterData1)/SUM(<MovVentas."UNI_ENT_TOT">,MasterData' +
            '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3PctVlast: TfrxMemoView
          Left = 950.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVentas.' +
            '"IMP_VENTA">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,MasterData' +
            '1)*100,0)]')
          ParentFont = False
        end
      end
      object GroupFooterG2: TfrxGroupFooter
        Height = 18.000000000000000000
        Top = 194.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoGF2Lbl: TfrxMemoView
          Left = 14.000000000000000000
          Top = 1.000000000000000000
          Width = 266.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [MovVentas."GRUPO2_ETIQ"]')
          ParentFont = False
        end
        object MemoGF2ImpEnt: TfrxMemoView
          Left = 330.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2ImpVta: TfrxMemoView
          Left = 442.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2Benef: TfrxMemoView
          Left = 570.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2VtaEnt: TfrxMemoView
          Left = 678.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2Marg1: TfrxMemoView
          Left = 794.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."B' +
            'ENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoGF2Marg2: TfrxMemoView
          Left = 846.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."V' +
            'ENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
      end
      object GroupFooterG1: TfrxGroupFooter
        Height = 20.000000000000000000
        Top = 216.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoGF1Lbl: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 280.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL [MovVentas."GRUPO1_ETIQ"]')
          ParentFont = False
        end
        object MemoGF1ImpEnt: TfrxMemoView
          Left = 330.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1ImpVta: TfrxMemoView
          Left = 442.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1Benef: TfrxMemoView
          Left = 570.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1VtaEnt: TfrxMemoView
          Left = 678.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1Marg1: TfrxMemoView
          Left = 794.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."B' +
            'ENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoGF1Marg2: TfrxMemoView
          Left = 846.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."V' +
            'ENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
      end
      object ReportSummary1: TfrxReportSummary
        Height = 20.000000000000000000
        Top = 238.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoRSLbl: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 280.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL GENERAL')
          ParentFont = False
        end
        object MemoRSUniEnt: TfrxMemoView
          Left = 280.000000000000000000
          Top = 2.000000000000000000
          Width = 50.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImpEnt: TfrxMemoView
          Left = 330.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSUdsVta: TfrxMemoView
          Left = 394.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."UDS_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImpVta: TfrxMemoView
          Left = 442.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImpCos: TfrxMemoView
          Left = 506.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_COSTE">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSBenef: TfrxMemoView
          Left = 570.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSPctBnf: TfrxMemoView
          Left = 634.000000000000000000
          Top = 2.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_COSTE">,MasterData1)<>0,SUM(<MovVentas."B' +
            'ENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_COSTE">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoRSVtaEnt: TfrxMemoView
          Left = 678.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSVentEnt: TfrxMemoView
          Left = 742.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVentas.' +
            '"VENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,MasterData' +
            '1)*100,0)]')
          ParentFont = False
        end
        object MemoRSMarg1: TfrxMemoView
          Left = 794.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."B' +
            'ENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoRSMarg2: TfrxMemoView
          Left = 846.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas."V' +
            'ENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData1)*1' +
            '00,0)]')
          ParentFont = False
        end
        object MemoRSPctVdto: TfrxMemoView
          Left = 898.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)<>0,SUM(<MovVentas.' +
            '"UDS_VENTA">,MasterData1)/SUM(<MovVentas."UNI_ENT_TOT">,MasterData' +
            '1)*100,0)]')
          ParentFont = False
        end
        object MemoRSPctVlast: TfrxMemoView
          Left = 950.000000000000000000
          Top = 2.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVentas.' +
            '"IMP_VENTA">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,MasterData' +
            '1)*100,0)]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 260.000000000000000000
        Width = 1046.000000000000000000
        Frame.Typ = []
        object MemoPag: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 520.000000000000000000
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
        object MemoPie: TfrxMemoView
          Left = 526.000000000000000000
          Top = 2.000000000000000000
          Width = 520.000000000000000000
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
  object unqryMovVentasPrint: TUniQuery
    SQL.Strings = (
      'CALL PRC_GET_MOV_VENTAS_ART('

        '  '#39'2026-01-01'#39', '#39'2026-12-31'#39', NULL, '#39#39', '#39#39', '#39#39', '#39#39', '#39#39', '#39#39', '#39#39', '#39 +
        #39', 0)')
    Left = 96
    Top = 16
  end
  object fxdsMovVentas: TfrxDBDataset
    Description = 'MovVentas'
    UserName = 'MovVentas'
    CloseDataSource = False
    DataSet = unqryMovVentasPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
