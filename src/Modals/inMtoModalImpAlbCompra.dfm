inherited frmPrintAlbCompra: TfrmPrintAlbCompra
  Caption = 'Imprimir Albar'#225'n de Compra'
  ClientHeight = 220
  ClientWidth = 460
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 476
  ExplicitHeight = 259
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 320
    Height = 220
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 320
    ExplicitHeight = 220
    inherited btnSalir: TcxButton
      Top = 194
      ExplicitTop = 194
    end
  end
  object lblSerie: TcxLabel [1]
    Left = 16
    Top = 16
    Caption = 'Serie'
    TabOrder = 1
    Transparent = True
  end
  object edtSerie: TcxTextEdit [2]
    Left = 16
    Top = 40
    Enabled = False
    TabOrder = 2
    Width = 121
  end
  object lblNumero: TcxLabel [3]
    Left = 152
    Top = 16
    Caption = 'N'#250'mero'
    TabOrder = 3
    Transparent = True
  end
  object edtNumero: TcxTextEdit [4]
    Left = 152
    Top = 40
    Enabled = False
    TabOrder = 4
    Width = 121
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.LastChange = 46196.500000000000000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 8
    Top = 184
    Datasets = <
      item
        DataSet = dmAlbaranesCompra.fxdsCabAlbc
        DataSetName = 'Albaran'
      end
      item
        DataSet = dmAlbaranesCompra.fxdsLinAlbc
        DataSetName = 'LineasAlbaran'
      end
      item
        DataSet = dmAlbaranesCompra.fxdsCabAlbc
        DataSetName = 'Albaran'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Frame.Typ = []
      MirrorMode = []
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 132.283464570000000000
        Top = 18.897650000000000000
        Width = 1046.929500000000000000
        object MemoTitulo: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 1046.929500000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'ALBAR'#193'N DE COMPRA')
          ParentFont = False
        end
        object MemoEmpLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 30.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'EMPRESA')
          ParentFont = False
        end
        object MemoEmpRazon: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 45.354360000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."RAZON_SOCIAL_EMP"]')
          ParentFont = False
        end
        object MemoEmpDir: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."DIRECCION1_EMP"]')
          ParentFont = False
        end
        object MemoEmpCpPob: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (

              '[Albaran."CODIGO_POSTAL_EMP"] [Albaran."POBLACION_EMP"] ([Albaran."PROVINCIA_EMP"])')
          ParentFont = False
        end
        object MemoEmpCif: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'CIF: [Albaran."NIF_EMP"]   Tel: [Albaran."MOVIL_EMP"]')
          ParentFont = False
        end
        object MemoPrvLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 30.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'PROVEEDOR')
          ParentFont = False
        end
        object MemoPrvRazon: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 45.354360000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoPrvDir: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."DIRECCION1_PRV"]')
          ParentFont = False
        end
        object MemoPrvCpPob: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (

              '[Albaran."CODIGO_POSTAL_PRV"] [Albaran."POBLACION_PRV"] ([Albaran."PROVINCIA_PRV"])')
          ParentFont = False
        end
        object MemoPrvCif: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'CIF: [Albaran."NIF_PRV"]   Tel: [Albaran."MOVIL_PRV"]')
          ParentFont = False
        end
        object MemoSesLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 30.236240000000000000
          Width = 336.378170000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'ALBAR'#193'N')
          ParentFont = False
        end
        object MemoSesNumero: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 45.354360000000000000
          Width = 336.378170000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Albaran."SERIE_ALBC"] / [Albaran."NUMERO_ALBC"]')
          ParentFont = False
        end
        object MemoSesFechaLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 71.811070000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha')
          ParentFont = False
        end
        object MemoSesFecha: TfrxMemoView
          AllowVectorExport = True
          Left = 813.543600000000000000
          Top = 71.811070000000000000
          Width = 233.386210000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."FECHA_ALBC"]')
          ParentFont = False
        end
        object MemoSesEstadoLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 86.929190000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Estado')
          ParentFont = False
        end
        object MemoSesEstado: TfrxMemoView
          AllowVectorExport = True
          Left = 813.543600000000000000
          Top = 86.929190000000000000
          Width = 233.386210000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."ESTADO_ALBC"]')
          ParentFont = False
        end
        object MemoSesRefPrvLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 102.047310000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Ref. Prov.')
          ParentFont = False
        end
        object MemoSesRefPrv: TfrxMemoView
          AllowVectorExport = True
          Left = 813.543600000000000000
          Top = 102.047310000000000000
          Width = 233.386210000000000000
          Height = 15.118120000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Albaran."REF_PROVEEDOR_ALBC"]')
          ParentFont = False
        end
        object MemoGuiaTitulo: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 117.165430000000000000
          Width = 1046.929500000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'GU'#205'AS DE TALLAS')
          ParentFont = False
        end
      end
      object DataBandGuias: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.897650000000000000
        Top = 173.858380000000000000
        Width = 1046.929500000000000000
        DataSet = dmAlbaranesCompra.fxdsCabAlbc
        DataSetName = 'Albaran'
        RowCount = 0
        object GuiaSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 60.000000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaNombre: TfrxMemoView
          AllowVectorExport = True
          Left = 60.000000000000000000
          Top = 0.000000000000000000
          Width = 350.000000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT01: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT02: TfrxMemoView
          AllowVectorExport = True
          Left = 436.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT03: TfrxMemoView
          AllowVectorExport = True
          Left = 463.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT04: TfrxMemoView
          AllowVectorExport = True
          Left = 489.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT05: TfrxMemoView
          AllowVectorExport = True
          Left = 516.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT06: TfrxMemoView
          AllowVectorExport = True
          Left = 542.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT07: TfrxMemoView
          AllowVectorExport = True
          Left = 569.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT08: TfrxMemoView
          AllowVectorExport = True
          Left = 595.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT09: TfrxMemoView
          AllowVectorExport = True
          Left = 622.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT10: TfrxMemoView
          AllowVectorExport = True
          Left = 648.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT11: TfrxMemoView
          AllowVectorExport = True
          Left = 675.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT12: TfrxMemoView
          AllowVectorExport = True
          Left = 701.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT13: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT14: TfrxMemoView
          AllowVectorExport = True
          Left = 754.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT15: TfrxMemoView
          AllowVectorExport = True
          Left = 781.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT16: TfrxMemoView
          AllowVectorExport = True
          Left = 807.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT17: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT18: TfrxMemoView
          AllowVectorExport = True
          Left = 860.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT19: TfrxMemoView
          AllowVectorExport = True
          Left = 887.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object GuiaT20: TfrxMemoView
          AllowVectorExport = True
          Left = 913.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
      end
      object HeaderLineas: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 207.874150000000000000
        Width = 1046.929500000000000000
        object HdrCodArt: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 70.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'C'#243'd. Art.')
          ParentFont = False
        end
        object HdrModelo: TfrxMemoView
          AllowVectorExport = True
          Left = 70.000000000000000000
          Top = 0.000000000000000000
          Width = 60.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Modelo')
          ParentFont = False
        end
        object HdrDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Top = 0.000000000000000000
          Width = 140.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Descripci'#243'n')
          ParentFont = False
        end
        object HdrColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.000000000000000000
          Top = 0.000000000000000000
          Width = 90.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Color')
          ParentFont = False
        end
        object HdrSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 0.000000000000000000
          Width = 50.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Sis.')
          ParentFont = False
        end
        object HdrTallasBlock: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Top = 0.000000000000000000
          Width = 530.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Cantidades por talla (T01..T20 — ver gu'#237'as arriba)')
          ParentFont = False
        end
        object HdrTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Top = 0.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Uds.')
          ParentFont = False
        end
        object HdrImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Top = 0.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Importe')
          ParentFont = False
        end
      end
      object DataBandLineas: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 245.669450000000000000
        Width = 1046.929500000000000000
        DataSet = dmAlbaranesCompra.fxdsLinAlbc
        DataSetName = 'LineasAlbaran'
        RowCount = 0
        object LinCodArt: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 70.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = (
            '[LineasAlbaran."CODIGO_ART_ALBCLIN"]')
          ParentFont = False
        end
        object LinModelo: TfrxMemoView
          AllowVectorExport = True
          Left = 70.000000000000000000
          Top = 0.000000000000000000
          Width = 60.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = (
            '[LineasAlbaran."CODIGO_UNIDAD_ALBCLIN"]')
          ParentFont = False
        end
        object LinDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Top = 0.000000000000000000
          Width = 140.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = (
            '[LineasAlbaran."DESCRIPCION_ARTICULO_ALBCLIN"]')
          ParentFont = False
        end
        object LinColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.000000000000000000
          Top = 0.000000000000000000
          Width = 90.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object LinSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 0.000000000000000000
          Width = 50.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object LinT01: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT02: TfrxMemoView
          AllowVectorExport = True
          Left = 436.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT03: TfrxMemoView
          AllowVectorExport = True
          Left = 463.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT04: TfrxMemoView
          AllowVectorExport = True
          Left = 489.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT05: TfrxMemoView
          AllowVectorExport = True
          Left = 516.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT06: TfrxMemoView
          AllowVectorExport = True
          Left = 542.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT07: TfrxMemoView
          AllowVectorExport = True
          Left = 569.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT08: TfrxMemoView
          AllowVectorExport = True
          Left = 595.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT09: TfrxMemoView
          AllowVectorExport = True
          Left = 622.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT10: TfrxMemoView
          AllowVectorExport = True
          Left = 648.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT11: TfrxMemoView
          AllowVectorExport = True
          Left = 675.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT12: TfrxMemoView
          AllowVectorExport = True
          Left = 701.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT13: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT14: TfrxMemoView
          AllowVectorExport = True
          Left = 754.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT15: TfrxMemoView
          AllowVectorExport = True
          Left = 781.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT16: TfrxMemoView
          AllowVectorExport = True
          Left = 807.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT17: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT18: TfrxMemoView
          AllowVectorExport = True
          Left = 860.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT19: TfrxMemoView
          AllowVectorExport = True
          Left = 887.000000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinT20: TfrxMemoView
          AllowVectorExport = True
          Left = 913.500000000000000000
          Top = 0.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            '[IIF(0 > 0, FormatFloat('#39'0'#39', 0), '#39#39')]')
          ParentFont = False
        end
        object LinTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Top = 0.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          DisplayFormat.FormatStr = '%2.0n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[LineasAlbaran."CANTIDAD_ALBCLIN"]')
          ParentFont = False
        end
        object LinImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Top = 0.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          DataSet = dmAlbaranesCompra.fxdsLinAlbc
          DataSetName = 'LineasAlbaran'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[LineasAlbaran."TOTAL_ALBCLIN"]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 26.456710000000000000
        Top = 287.244280000000000000
        Width = 1046.929500000000000000
        object MemoTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 700.000000000000000000
          Top = 3.779530000000000000
          Width = 240.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            'TOTAL: [Albaran."CONTADOR_LINEAS_ALBC"] unidades')
          ParentFont = False
        end
        object MemoTotalImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Top = 3.779530000000000000
          Width = 106.929500000000000000
          Height = 18.897650000000000000
          DataSet = dmAlbaranesCompra.fxdsCabAlbc
          DataSetName = 'Albaran'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[Albaran."CONTADOR_LINEAS_ALBC"]')
          ParentFont = False
        end
        object MemoPagina: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 3.779530000000000000
          Width = 300.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'P'#225'g. [Page#] / [TotalPages#]   '#183'   [Date]')
          ParentFont = False
        end
      end
    end
  end
  inherited frxpdfxprtPedWeb: TfrxPDFExport
    Left = 80
    Top = 184
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    Left = 152
    Top = 184
  end
  inherited unqryPerfiles: TUniQuery
    Left = 224
    Top = 184
  end
  inherited dsPerfiles: TDataSource
    Left = 8
    Top = 8
  end
  inherited frxdsgnr1: TfrxDesigner
    DefaultPaperSize = 9
    DefaultOrientation = poLandscape
    Left = 288
    Top = 184
  end
  inherited frxReportOrigen: TfrxReport
    ReportOptions.Author = ''
    ReportOptions.LastChange = 46196.500000000000000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 376
    Top = 184
    Datasets = <
      item
        DataSet = dmAlbaranesCompra.fxdsCabAlbc
        DataSetName = 'Albaran'
      end
      item
        DataSet = dmAlbaranesCompra.fxdsLinAlbc
        DataSetName = 'LineasAlbaran'
      end
      item
        DataSet = dmAlbaranesCompra.fxdsCabAlbc
        DataSetName = 'Albaran'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Frame.Typ = []
      MirrorMode = []
    end
  end
end
