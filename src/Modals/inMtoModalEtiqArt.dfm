inherited frmPrintEtiqArt: TfrmPrintEtiqArt
  Caption = 'Impresi'#243'n de Etiquetas de Art'#237'culo'
  ClientHeight = 452
  ClientWidth = 538
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  ExplicitWidth = 556
  ExplicitHeight = 499
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 394
    Height = 452
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 394
    ExplicitHeight = 452
    inherited btnSalir: TcxButton
      Top = 434
      ExplicitTop = 426
    end
  end
  object pnlOpciones: TPanel [1]
    Left = 0
    Top = 0
    Width = 394
    Height = 452
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxlblArticulo: TcxLabel
      Left = 12
      Top = 12
      Caption = 'C'#243'digo de Art'#237'culo:'
      TabOrder = 5
    end
    object edtCodArt: TcxTextEdit
      Left = 156
      Top = 8
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 220
    end
    object chkSoloEsteArt: TcxCheckBox
      Left = 12
      Top = 40
      Caption = 'Imprimir s'#243'lo este art'#237'culo'
      Properties.NullStyle = nssUnchecked
      State = cbsChecked
      TabOrder = 1
    end
    object cxlblTarifa: TcxLabel
      Left = 12
      Top = 76
      Caption = 'Tarifa:'
      TabOrder = 6
    end
    object cbbTarifa: TcxComboBox
      Left = 156
      Top = 72
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 2
      Width = 220
    end
    object cxlblFecha: TcxLabel
      Left = 12
      Top = 108
      Caption = 'Fecha de aplicaci'#243'n:'
      TabOrder = 7
    end
    object dtFechaAplicacion: TcxDateEdit
      Left = 156
      Top = 104
      TabOrder = 3
      Width = 220
    end
    object cxlblAlmacenes: TcxLabel
      Left = 12
      Top = 140
      Caption = 'Almacenes (marque uno o varios):'
      TabOrder = 8
    end
    object lvAlmacenes: TcxListView
      Left = 12
      Top = 168
      Width = 364
      Height = 257
      Checkboxes = True
      Columns = <
        item
          Caption = 'C'#243'digo'
          Width = 100
        end
        item
          Caption = 'Nombre'
          Width = 230
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 4
      ViewStyle = vsReport
    end
  end
  inherited frxrprt1: TfrxReport
    Left = 8
    Top = 8
    Datasets = <
      item
        DataSet = dmArticulos.fxdsEtiquetasArt
        DataSetName = 'EtiquetasArt'
      end>
    Variables = <>
    Style = <>
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    Left = 64
    Top = 8
  end
  inherited unqryPerfiles: TUniQuery
    Left = 168
  end
  inherited dsPerfiles: TDataSource
    Left = 224
    Top = 8
  end
  inherited frxReportOrigen: TfrxReport
    ReportOptions.Author = ''
    ReportOptions.LastChange = 46164.000000000000000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 120
    Top = 8
    Datasets = <
      item
        DataSet = dmArticulos.fxdsEtiquetasArt
        DataSetName = 'EtiquetasArt'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Columns = 2
      ColumnWidth = 100.000000000000000000
      ColumnPositions.Strings = (
        '0'
        '100')
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 120.000000000000000000
        Top = 18.897650000000000000
        Width = 396.850650000000000000
        DataSet = dmArticulos.fxdsEtiquetasArt
        DataSetName = 'EtiquetasArt'
        RowCount = 0
        object EtiqDescripcionArt: TfrxMemoView
          AllowVectorExport = True
          Left = 5.000000000000000000
          Top = 5.000000000000000000
          Width = 360.000000000000000000
          Height = 18.000000000000000000
          DataField = 'DESCRIPCION_ART'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object EtiqDescripcionSku: TfrxMemoView
          AllowVectorExport = True
          Left = 5.000000000000000000
          Top = 25.000000000000000000
          Width = 360.000000000000000000
          Height = 16.000000000000000000
          DataField = 'DESCRIPCION_SKU'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."DESCRIPCION_SKU"]')
          ParentFont = False
        end
        object EtiqRefProv: TfrxMemoView
          AllowVectorExport = True
          Left = 5.000000000000000000
          Top = 45.000000000000000000
          Width = 360.000000000000000000
          Height = 14.000000000000000000
          DataField = 'REF_PROVEEDOR'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Ref: [EtiquetasArt."REF_PROVEEDOR"]')
          ParentFont = False
        end
        object EtiqCodigoBarras: TfrxMemoView
          AllowVectorExport = True
          Left = 5.000000000000000000
          Top = 65.000000000000000000
          Width = 200.000000000000000000
          Height = 14.000000000000000000
          DataField = 'CODIGO_BARRAS_CB'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."CODIGO_BARRAS_CB"]')
          ParentFont = False
        end
        object EtiqPrecio: TfrxMemoView
          AllowVectorExport = True
          Left = 210.000000000000000000
          Top = 65.000000000000000000
          Width = 155.000000000000000000
          Height = 30.000000000000000000
          DataField = 'PRECIO_FINAL_ARTTAR'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[EtiquetasArt."PRECIO_FINAL_ARTTAR"] '#8364)
          ParentFont = False
        end
      end
    end
  end
end
