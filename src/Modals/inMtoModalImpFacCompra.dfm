inherited frmPrintFacCompra: TfrmPrintFacCompra
  Caption = 'Imprimir Factura de Compra'
  ClientHeight = 220
  ClientWidth = 460
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 476
  ExplicitHeight = 259
  TextHeight = 17
  inherited pnl1: TPanel
    Left = 316
    Height = 220
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 314
    ExplicitHeight = 212
    inherited btnSalir: TcxButton
      Top = 194
      ExplicitTop = 186
    end
    inherited btnExcel: TcxButton
      OnClick = btnExcelClick
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
    Caption = 'Número'
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
        DataSet = dmFacturasCompra.fxdsCabFacc
        DataSetName = 'Factura'
      end
      item
        DataSet = dmFacturasCompra.fxdsLinFacc
        DataSetName = 'LineasFactura'
      end
      item
        DataSet = dmFacturasCompra.fxdsGuiasFacc
        DataSetName = 'GuiasTallas'
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
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 132.283464570000000000
        Top = 18.897650000000000000
        Width = 1046.929810000000000000
        object MemoTitulo: TfrxMemoView
          AllowVectorExport = True
          Width = 1046.929500000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'FACTURA DE COMPRA')
          ParentFont = False
        end
        object MemoEmpLbl: TfrxMemoView
          AllowVectorExport = True
          Top = 30.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'ALMACÉN DESTINO')
          ParentFont = False
        end
        object MemoEmpRazon: TfrxMemoView
          AllowVectorExport = True
          Top = 45.354360000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."NOMBRE_ALM_FACC"]')
          ParentFont = False
        end
        object MemoEmpDir: TfrxMemoView
          AllowVectorExport = True
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."DIRECCION_ALM_FACC"]')
          ParentFont = False
        end
        object MemoEmpCpPob: TfrxMemoView
          AllowVectorExport = True
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (

              '[Factura."CODIGO_POSTAL_ALM_FACC"] [Factura."POBLACION_ALM_FACC"' +
              '] ([Factura."PROVINCIA_ALM_FACC"])')
          ParentFont = False
        end
        object MemoEmpCif: TfrxMemoView
          AllowVectorExport = True
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (

              'Tel: [Factura."TELEFONO_ALM_FACC"]   Email: [Factura."EMAIL_ALM_' +
              'FACC"]')
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
          Font.Height = -14
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
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoPrvDir: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."DIRECCION1_PRV"]')
          ParentFont = False
        end
        object MemoPrvCpPob: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (

              '[Factura."CODIGO_POSTAL_PRV"] [Factura."POBLACION_PRV"] ([Factur' +
              'a."PROVINCIA_PRV"])')
          ParentFont = False
        end
        object MemoPrvCif: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'CIF: [Factura."CIF_PRV"]   Tel: [Factura."TELEFONO1_PRV"]')
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
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'FACTURA')
          ParentFont = False
        end
        object MemoSesNumero: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 45.354360000000000000
          Width = 336.378170000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Factura."DOCUMENTO_FORMATO"]')
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
          Font.Height = -14
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
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."FECHA_FACC"]')
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
          Font.Height = -14
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
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."ESTADO_FACC"]')
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
          Font.Height = -14
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
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."REF_PROVEEDOR_FACC"]')
          ParentFont = False
        end
        object MemoGuiaTitulo: TfrxMemoView
          AllowVectorExport = True
          Top = 117.165430000000000000
          Width = 1046.929500000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'GUÍAS DE TALLAS')
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
        Top = 211.653680000000000000
        Width = 1046.929810000000000000
        DataSet = dmFacturasCompra.fxdsGuiasFacc
        DataSetName = 'GuiasTallas'
        RowCount = 0
        object GuiaSistema: TfrxMemoView
          AllowVectorExport = True
          Width = 60.000000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."NOMBRE_CORTO_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaNombre: TfrxMemoView
          AllowVectorExport = True
          Left = 60.000000000000000000
          Width = 350.000000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[GuiasTallas."NOMBRE_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT01: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T01"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT02: TfrxMemoView
          AllowVectorExport = True
          Left = 436.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T02"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT03: TfrxMemoView
          AllowVectorExport = True
          Left = 463.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T03"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT04: TfrxMemoView
          AllowVectorExport = True
          Left = 489.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T04"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT05: TfrxMemoView
          AllowVectorExport = True
          Left = 516.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T05"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT06: TfrxMemoView
          AllowVectorExport = True
          Left = 542.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T06"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT07: TfrxMemoView
          AllowVectorExport = True
          Left = 569.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T07"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT08: TfrxMemoView
          AllowVectorExport = True
          Left = 595.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T08"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT09: TfrxMemoView
          AllowVectorExport = True
          Left = 622.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T09"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT10: TfrxMemoView
          AllowVectorExport = True
          Left = 648.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T10"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT11: TfrxMemoView
          AllowVectorExport = True
          Left = 675.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T11"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT12: TfrxMemoView
          AllowVectorExport = True
          Left = 701.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T12"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT13: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T13"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT14: TfrxMemoView
          AllowVectorExport = True
          Left = 754.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T14"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT15: TfrxMemoView
          AllowVectorExport = True
          Left = 781.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T15"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT16: TfrxMemoView
          AllowVectorExport = True
          Left = 807.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T16"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT17: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T17"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT18: TfrxMemoView
          AllowVectorExport = True
          Left = 860.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T18"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT19: TfrxMemoView
          AllowVectorExport = True
          Left = 887.000000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T19"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT20: TfrxMemoView
          AllowVectorExport = True
          Left = 913.500000000000000000
          Width = 26.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsGuiasFacc
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T20"]')
          ParentFont = False
          VAlign = vaCenter
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
        Top = 253.228510000000000000
        Width = 1046.929810000000000000
        object HdrCodArt: TfrxMemoView
          AllowVectorExport = True
          Width = 70.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Cód. Art.')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrModelo: TfrxMemoView
          AllowVectorExport = True
          Left = 70.000000000000000000
          Width = 60.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Modelo')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Width = 140.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Descripción')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.000000000000000000
          Width = 90.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Color')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Width = 50.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Sis.')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrTallasBlock: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Width = 530.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Cantidades por talla (T01..T20 - ver guías arriba)')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Uds.')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Importe')
          ParentFont = False
          VAlign = vaCenter
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
        Top = 298.582870000000000000
        Width = 1046.929810000000000000
        DataSet = dmFacturasCompra.fxdsLinFacc
        DataSetName = 'LineasFactura'
        RowCount = 0
        object LinCodArt: TfrxMemoView
          AllowVectorExport = True
          Width = 70.000000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasFactura."CODIGO_ART"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinModelo: TfrxMemoView
          AllowVectorExport = True
          Left = 70.000000000000000000
          Width = 60.000000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasFactura."REF_PRV"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Width = 140.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasFactura."DESCRIPCION"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.000000000000000000
          Width = 90.000000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasFactura."COLOR_TEXTO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Width = 50.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[LineasFactura."NOMBRE_CORTO_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT01: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T01"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T01">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT02: TfrxMemoView
          AllowVectorExport = True
          Left = 436.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T02"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T02">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT03: TfrxMemoView
          AllowVectorExport = True
          Left = 463.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T03"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T03">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT04: TfrxMemoView
          AllowVectorExport = True
          Left = 489.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T04"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T04">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT05: TfrxMemoView
          AllowVectorExport = True
          Left = 516.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T05"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T05">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT06: TfrxMemoView
          AllowVectorExport = True
          Left = 542.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T06"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T06">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT07: TfrxMemoView
          AllowVectorExport = True
          Left = 569.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T07"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T07">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT08: TfrxMemoView
          AllowVectorExport = True
          Left = 595.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T08"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T08">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT09: TfrxMemoView
          AllowVectorExport = True
          Left = 622.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T09"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T09">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT10: TfrxMemoView
          AllowVectorExport = True
          Left = 648.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T10"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T10">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT11: TfrxMemoView
          AllowVectorExport = True
          Left = 675.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T11"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T11">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT12: TfrxMemoView
          AllowVectorExport = True
          Left = 701.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T12"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T12">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT13: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T13"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T13">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT14: TfrxMemoView
          AllowVectorExport = True
          Left = 754.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T14"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T14">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT15: TfrxMemoView
          AllowVectorExport = True
          Left = 781.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T15"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T15">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT16: TfrxMemoView
          AllowVectorExport = True
          Left = 807.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T16"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T16">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT17: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T17"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T17">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT18: TfrxMemoView
          AllowVectorExport = True
          Left = 860.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T18"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T18">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT19: TfrxMemoView
          AllowVectorExport = True
          Left = 887.000000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T19"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T19">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT20: TfrxMemoView
          AllowVectorExport = True
          Left = 913.500000000000000000
          Width = 26.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasFactura."T20"> > 0, FormatFloat('#39'0'#39', <LineasFactura.' +
              '"T20">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          DisplayFormat.FormatStr = '%2.0n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasFactura."TOTAL_UNIDADES"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          DataSet = dmFacturasCompra.fxdsLinFacc
          DataSetName = 'LineasFactura'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasFactura."TOTAL_LINEA"]')
          ParentFont = False
          VAlign = vaCenter
        end
      end
      object ReportSummaryTotalesFiscales: TfrxReportSummary
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 120.944960000000000000
        Top = 381.732530000000000000
        Width = 1046.929810000000000000
        object MemoTotalesFiscales: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 7.559060000000000000
          Width = 1046.929500000000000000
          Height = 105.826840000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Courier New'
          Font.Style = []
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'DESGLOSE IVA / RE'

              'Normal       Base [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASE' +
              'I_IVAN_FACC">)]  IVA [FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE' +
              '_IVAN_FACC">)]% [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IVAN' +
              '_FACC">)][IIF(<Factura."TOTAL_REN_FACC"> <> 0, '#39'  RE '#39' + For' +
              'matFloat('#39'0.##'#39', <Factura."PORCENTAJE_REN_FACC">) + '#39'% '#39' + ' +
              'FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_REN_FACC">), '#39#39')]'

              'Reducido     Base [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASE' +
              'I_IVAR_FACC">)]  IVA [FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE' +
              '_IVAR_FACC">)]% [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IVAR' +
              '_FACC">)][IIF(<Factura."TOTAL_RER_FACC"> <> 0, '#39'  RE '#39' + For' +
              'matFloat('#39'0.##'#39', <Factura."PORCENTAJE_RER_FACC">) + '#39'% '#39' + ' +
              'FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_RER_FACC">), '#39#39')]'

              'Super red.   Base [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASE' +
              'I_IVAS_FACC">)]  IVA [FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE' +
              '_IVAS_FACC">)]% [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IVAS' +
              '_FACC">)][IIF(<Factura."TOTAL_RES_FACC"> <> 0, '#39'  RE '#39' + For' +
              'matFloat('#39'0.##'#39', <Factura."PORCENTAJE_RES_FACC">) + '#39'% '#39' + ' +
              'FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_RES_FACC">), '#39#39')]'

              'Exento       Base [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASE' +
              'I_IVAE_FACC">)]  IVA [FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE' +
              '_IVAE_FACC">)]% [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IVAE' +
              '_FACC">)][IIF(<Factura."TOTAL_REE_FACC"> <> 0, '#39'  RE '#39' + For' +
              'matFloat('#39'0.##'#39', <Factura."PORCENTAJE_REE_FACC">) + '#39'% '#39' + ' +
              'FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_REE_FACC">), '#39#39')]'

              'Base total [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASES_FACC' +
              '">)]   Impuestos [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IMPU' +
              'ESTOS_FACC">)]'

              '[IIF(<Factura."TOTAL_RETENCION_FACC"> <> 0, '#39'Retencion IRPF '#39 +
              ' + FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE_RETENCION_FACC">)' +
              ' + '#39'% -'#39' + FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_RETENCION' +
              '_FACC">), '#39#39')]'

              'TOTAL LIQUIDO [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_LIQUID' +
              'O_FACC">)] EUR')
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
        Top = 506.457020000000000000
        Width = 1046.929810000000000000
        object MemoTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 700.000000000000000000
          Top = 3.779530000000000000
          Width = 240.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'TOTAL: [Factura."TOTAL_UNIDADES_FACC"] unidades')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoTotalImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Top = 3.779530000000000000
          Width = 106.929500000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[Factura."TOTAL_LINEAS_FACC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPagina: TfrxMemoView
          AllowVectorExport = True
          Top = 3.779530000000000000
          Width = 300.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Pág. [Page#] / [TotalPages#] - [Date]')
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
  inherited frxdsgnr1: TfrxDesigner
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
        DataSet = dmFacturasCompra.fxdsCabFacc
        DataSetName = 'Factura'
      end
      item
        DataSet = dmFacturasCompra.fxdsLinFacc
        DataSetName = 'LineasFactura'
      end
      item
        DataSet = dmFacturasCompra.fxdsGuiasFacc
        DataSetName = 'GuiasTallas'
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
end
