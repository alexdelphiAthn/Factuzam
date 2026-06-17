inherited frmPrintDevCompraV: TfrmPrintDevCompraV
  Caption = 'Imprimir Albarán de Compra (Vertical)'
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
        DataSet = dmDevolucionesCompra.fxdsCabDevc
        DataSetName = 'Devolucion'
      end
      item
        DataSet = dmDevolucionesCompra.fxdsLinDevcSku
        DataSetName = 'LineasDevolucionSku'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poPortrait
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
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
        Height = 110.000000000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        object MemoTituloV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 718.110700000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'ALBARÁN DE COMPRA')
          ParentFont = False
        end
        object MemoEmpRazonV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 30.000000000000000000
          Width = 350.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."NOMBRE_ALM_DEVC"]')
          ParentFont = False
        end
        object MemoEmpDirV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 48.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."DIRECCION_ALM_DEVC"]')
          ParentFont = False
        end
        object MemoEmpCpPobV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 62.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."CODIGO_POSTAL_ALM_DEVC"] [Devolucion."POBLACION_ALM_DEVC"] ([Devolucion."PROVINCIA_ALM_DEVC"])')
          ParentFont = False
        end
        object MemoEmpCifV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 76.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Tel: [Devolucion."TELEFONO_ALM_DEVC"]   Email: [Devolucion."EMAIL_ALM_DEVC"]')
          ParentFont = False
        end
        object MemoPrvLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 30.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
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
        object MemoPrvRazonV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 44.000000000000000000
          Width = 358.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoPrvDirV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 62.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."DIRECCION1_PRV"], [Devolucion."POBLACION_PRV"]')
          ParentFont = False
        end
        object MemoPrvCifV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 76.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'CIF: [Devolucion."CIF_PRV"]')
          ParentFont = False
        end
        object MemoNumeroV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 92.000000000000000000
          Width = 360.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Albarán: [Devolucion."DOCUMENTO_FORMATO"]')
          ParentFont = False
        end
        object MemoFechaV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 92.000000000000000000
          Width = 200.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Fecha: [Devolucion."FECHA_DEVC"]')
          ParentFont = False
        end
        object MemoRefPrvV: TfrxMemoView
          AllowVectorExport = True
          Left = 560.000000000000000000
          Top = 92.000000000000000000
          Width = 158.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Ref. prov.: [Devolucion."REF_PROVEEDOR_DEVC"]')
          ParentFont = False
        end
      end
      object HeaderLineasV: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 140.000000000000000000
        Width = 718.110700000000000000
        object HdrLineaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Linea')
          ParentFont = False
        end
        object HdrArtV: TfrxMemoView
          AllowVectorExport = True
          Left = 40.000000000000000000
          Top = 0.000000000000000000
          Width = 80.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Artículo')
          ParentFont = False
        end
        object HdrSkuV: TfrxMemoView
          AllowVectorExport = True
          Left = 120.000000000000000000
          Top = 0.000000000000000000
          Width = 130.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('SKU')
          ParentFont = False
        end
        object HdrRefV: TfrxMemoView
          AllowVectorExport = True
          Left = 250.000000000000000000
          Top = 0.000000000000000000
          Width = 80.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Ref. prov.')
          ParentFont = False
        end
        object HdrDescV: TfrxMemoView
          AllowVectorExport = True
          Left = 330.000000000000000000
          Top = 0.000000000000000000
          Width = 200.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Descripción')
          ParentFont = False
        end
        object HdrCantV: TfrxMemoView
          AllowVectorExport = True
          Left = 530.000000000000000000
          Top = 0.000000000000000000
          Width = 50.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Cant.')
          ParentFont = False
        end
        object HdrPrecV: TfrxMemoView
          AllowVectorExport = True
          Left = 580.000000000000000000
          Top = 0.000000000000000000
          Width = 68.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Precio')
          ParentFont = False
        end
        object HdrTotV: TfrxMemoView
          AllowVectorExport = True
          Left = 648.000000000000000000
          Top = 0.000000000000000000
          Width = 70.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Total')
          ParentFont = False
        end
      end
      object DataBandLineasV: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 180.000000000000000000
        Width = 718.110700000000000000
        DataSet = dmDevolucionesCompra.fxdsLinDevcSku
        DataSetName = 'LineasDevolucionSku'
        RowCount = 0
        object LinLineaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."LINEA_DEVCLIN"]')
          ParentFont = False
        end
        object LinArtV: TfrxMemoView
          AllowVectorExport = True
          Left = 40.000000000000000000
          Top = 0.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."CODIGO_ART_DEVCLIN"]')
          ParentFont = False
        end
        object LinSkuV: TfrxMemoView
          AllowVectorExport = True
          Left = 120.000000000000000000
          Top = 0.000000000000000000
          Width = 130.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."CODIGO_UNIDAD_DEVCLIN"]')
          ParentFont = False
        end
        object LinRefV: TfrxMemoView
          AllowVectorExport = True
          Left = 250.000000000000000000
          Top = 0.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."REF_PRV_DEVCLIN"]')
          ParentFont = False
        end
        object LinDescV: TfrxMemoView
          AllowVectorExport = True
          Left = 330.000000000000000000
          Top = 0.000000000000000000
          Width = 200.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."DESCRIPCION_ARTICULO_DEVCLIN"]')
          ParentFont = False
        end
        object LinCantV: TfrxMemoView
          AllowVectorExport = True
          Left = 530.000000000000000000
          Top = 0.000000000000000000
          Width = 50.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          DisplayFormat.FormatStr = '#,##0.##'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[FormatFloat('#39'0.######'#39', <LineasDevolucionSku."CANTIDAD_DEVCLIN">)]')
          ParentFont = False
        end
        object LinPrecV: TfrxMemoView
          AllowVectorExport = True
          Left = 580.000000000000000000
          Top = 0.000000000000000000
          Width = 68.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN"]')
          ParentFont = False
        end
        object LinTotV: TfrxMemoView
          AllowVectorExport = True
          Left = 648.000000000000000000
          Top = 0.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = ('[LineasDevolucionSku."TOTAL_DEVCLIN"]')
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
        Height = 30.000000000000000000
        Top = 1010.000000000000000000
        Width = 718.110700000000000000
        object MemoTotBaseV: TfrxMemoView
          AllowVectorExport = True
          Left = 450.000000000000000000
          Top = 0.000000000000000000
          Width = 130.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = ('Total bases: [Devolucion."TOTAL_BASES_DEVC"]')
          ParentFont = False
        end
        object MemoTotIvaV: TfrxMemoView
          AllowVectorExport = True
          Left = 450.000000000000000000
          Top = 14.000000000000000000
          Width = 130.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = ('Total IVA: [Devolucion."TOTAL_IMPUESTOS_DEVC"]')
          ParentFont = False
        end
        object MemoTotLiqV: TfrxMemoView
          AllowVectorExport = True
          Left = 580.000000000000000000
          Top = 0.000000000000000000
          Width = 138.000000000000000000
          Height = 28.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = ('TOTAL: [Devolucion."TOTAL_LIQUIDO_DEVC"] '#8364)
          ParentFont = False
        end
      end
    end
  end
end
