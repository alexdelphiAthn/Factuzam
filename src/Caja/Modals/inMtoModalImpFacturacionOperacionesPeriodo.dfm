inherited frmPrintFacturacionOperacionesPeriodo: TfrmPrintFacturacionOperacionesPeriodo
  Caption = 'Informe de facturaci'#243'n de operaciones por periodo'
  ClientHeight = 240
  ClientWidth = 570
  ExplicitWidth = 586
  ExplicitHeight = 279
  TextHeight = 17
  inherited pnl1: TPanel
    Left = 426
    ExplicitLeft = 426
  end
  object lblContexto: TcxLabel
    Left = 16
    Top = 16
    Caption = 'TPV activo:'
    Transparent = True
  end
  object edtContexto: TcxTextEdit
    Left = 16
    Top = 38
    Properties.ReadOnly = True
    TabOrder = 1
    Width = 390
  end
  object lblDesde: TcxLabel
    Left = 16
    Top = 84
    Caption = 'Desde:'
    Transparent = True
  end
  object dteDesde: TcxDateEdit
    Left = 16
    Top = 106
    TabOrder = 2
    Width = 180
  end
  object lblHasta: TcxLabel
    Left = 226
    Top = 84
    Caption = 'Hasta:'
    Transparent = True
  end
  object dteHasta: TcxDateEdit
    Left = 226
    Top = 106
    TabOrder = 3
    Width = 180
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsFacturacionPeriodo
        DataSetName = 'FacturacionPeriodo'
      end>
    Variables = <>
    Style = <>
  end
  inherited frxReportOrigen: TfrxReport
    Datasets = <
      item
        DataSet = fxdsFacturacionPeriodo
        DataSetName = 'FacturacionPeriodo'
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
        Height = 36.000000000000000000
        Top = 0.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 800.000000000000000000
          Height = 25.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Facturaci'#243'n de operaciones por periodo')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        Height = 22.000000000000000000
        Top = 40.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoHArticulo: TfrxMemoView
          Left = 0.000000000000000000
          Width = 120.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = ('Art'#237'culo')
          ParentFont = False
        end
        object MemoHSku: TfrxMemoView
          Left = 120.000000000000000000
          Width = 190.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = ('SKU')
          ParentFont = False
        end
        object MemoHDescripcion: TfrxMemoView
          Left = 310.000000000000000000
          Width = 320.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = ('Descripci'#243'n')
          ParentFont = False
        end
        object MemoHCantidad: TfrxMemoView
          Left = 630.000000000000000000
          Width = 80.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = ('Cantidad')
          ParentFont = False
        end
        object MemoHBase: TfrxMemoView
          Left = 710.000000000000000000
          Width = 110.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = ('Base/importe')
          ParentFont = False
        end
        object MemoHIva: TfrxMemoView
          Left = 820.000000000000000000
          Width = 100.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = ('IVA')
          ParentFont = False
        end
        object MemoHTotal: TfrxMemoView
          Left = 920.000000000000000000
          Width = 127.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = ('Total')
          ParentFont = False
        end
      end
      object GroupHeaderDocumento: TfrxGroupHeader
        Height = 34.000000000000000000
        Top = 66.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'FacturacionPeriodo."CLAVE_DOCUMENTO"'
        KeepTogether = True
        ReprintOnNewPage = True
        Frame.Typ = [ftTop, ftBottom]
        FillType = ftBrush
        Fill.BackColor = 15132390
        object MemoEtiquetaDocumento: TfrxMemoView
          Left = 8.000000000000000000
          Top = 7.000000000000000000
          Width = 75.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = ('Documento:')
          ParentFont = False
        end
        object MemoDocumentoGrupo: TfrxMemoView
          Left = 83.000000000000000000
          Top = 7.000000000000000000
          Width = 330.000000000000000000
          Height = 18.000000000000000000
          DataField = 'DOCUMENTO'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = ('[FacturacionPeriodo."DOCUMENTO"]')
          ParentFont = False
        end
        object MemoFechaGrupo: TfrxMemoView
          Left = 430.000000000000000000
          Top = 7.000000000000000000
          Width = 190.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha: [FormatDateTime(''dd/mm/yyyy'', ' +
            '<FacturacionPeriodo."FECHA_DOCUMENTO">)]')
          ParentFont = False
        end
        object MemoEstadosGrupo: TfrxMemoView
          Left = 630.000000000000000000
          Top = 7.000000000000000000
          Width = 409.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Proceso: [FacturacionPeriodo."ESTADO_PROCESO"]  Fiscal: ' +
            '[FacturacionPeriodo."ESTADO_FISCAL"]')
          ParentFont = False
        end
      end
      object MasterDataArticulos: TfrxMasterData
        Height = 18.000000000000000000
        Top = 104.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsFacturacionPeriodo
        DataSetName = 'FacturacionPeriodo'
        RowCount = 0
        Frame.Typ = []
        object MemoArticulo: TfrxMemoView
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          DataField = 'ARTICULO'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = ('[FacturacionPeriodo."ARTICULO"]')
          ParentFont = False
        end
        object MemoSku: TfrxMemoView
          Left = 120.000000000000000000
          Width = 190.000000000000000000
          Height = 18.000000000000000000
          DataField = 'SKU'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = ('[FacturacionPeriodo."SKU"]')
          ParentFont = False
        end
        object MemoDescripcion: TfrxMemoView
          Left = 310.000000000000000000
          Width = 320.000000000000000000
          Height = 18.000000000000000000
          DataField = 'DESCRIPCION'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = ('[FacturacionPeriodo."DESCRIPCION"]')
          ParentFont = False
        end
        object MemoCantidad: TfrxMemoView
          Left = 630.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          DataField = 'CANTIDAD'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          DisplayFormat.FormatStr = '#,##0.###'
          DisplayFormat.Kind = fkNumeric
          HAlign = haRight
          Memo.UTF8W = ('[FacturacionPeriodo."CANTIDAD"]')
        end
        object MemoBase: TfrxMemoView
          Left = 710.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataField = 'TOTAL_BASE'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          DisplayFormat.FormatStr = '#,##0.00 €'
          DisplayFormat.Kind = fkNumeric
          HAlign = haRight
          Memo.UTF8W = ('[FacturacionPeriodo."TOTAL_BASE"]')
        end
        object MemoIva: TfrxMemoView
          Left = 820.000000000000000000
          Width = 100.000000000000000000
          Height = 18.000000000000000000
          DataField = 'TOTAL_IVA'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          DisplayFormat.FormatStr = '#,##0.00 €'
          DisplayFormat.Kind = fkNumeric
          HAlign = haRight
          Memo.UTF8W = ('[FacturacionPeriodo."TOTAL_IVA"]')
        end
        object MemoTotal: TfrxMemoView
          Left = 920.000000000000000000
          Width = 127.000000000000000000
          Height = 18.000000000000000000
          DataField = 'TOTAL_LINEA'
          DataSet = fxdsFacturacionPeriodo
          DataSetName = 'FacturacionPeriodo'
          DisplayFormat.FormatStr = '#,##0.00 €'
          DisplayFormat.Kind = fkNumeric
          HAlign = haRight
          Memo.UTF8W = ('[FacturacionPeriodo."TOTAL_LINEA"]')
        end
      end
      object GroupFooterDocumento: TfrxGroupFooter
        Height = 22.000000000000000000
        Top = 126.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = [ftTop]
        object MemoTotalDocumento: TfrxMemoView
          Left = 780.000000000000000000
          Top = 2.000000000000000000
          Width = 267.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Total documento: [SUM(<FacturacionPeriodo."TOTAL_LINEA">,' +
            'MasterDataArticulos)]')
          ParentFont = False
        end
      end
    end
  end
  object dsFacturacionPeriodo: TDataSource
    Left = 32
    Top = 176
  end
  object fxdsFacturacionPeriodo: TfrxDBDataset
    UserName = 'FacturacionPeriodo'
    CloseDataSource = False
    DataSource = dsFacturacionPeriodo
    BCDToCurrency = False
    DataSetOptions = []
    Left = 104
    Top = 176
  end
end
