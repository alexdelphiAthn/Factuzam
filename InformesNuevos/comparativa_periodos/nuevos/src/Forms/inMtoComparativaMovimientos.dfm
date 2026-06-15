inherited frmMtoComparativaMovimientos: TfrmMtoComparativaMovimientos
  Caption = 'Comparativa de periodos'
  ClientHeight = 600
  ClientWidth = 900
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 900
    Height = 140
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblDesde: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Fecha desde'
      Style.TextColor = clNavy
      Transparent = True
    end
    object dteFechaDesde: TcxDateEdit
      Left = 16
      Top = 30
      Properties.DisplayFormat = 'dd/mm/yyyy'
      Properties.Kind = ckDate
      Properties.OnChange = dteFechaDesdePropertiesChange
      TabOrder = 0
      Width = 130
    end
    object lblHasta: TcxLabel
      Left = 156
      Top = 8
      Caption = 'Fecha hasta'
      Style.TextColor = clNavy
      Transparent = True
    end
    object dteFechaHasta: TcxDateEdit
      Left = 156
      Top = 30
      Properties.DisplayFormat = 'dd/mm/yyyy'
      Properties.Kind = ckDate
      TabOrder = 1
      Width = 130
    end
    object lblMagnitud: TcxLabel
      Left = 300
      Top = 8
      Caption = 'Magnitud'
      Style.TextColor = clNavy
      Transparent = True
    end
    object cboMagnitud: TcxComboBox
      Left = 300
      Top = 30
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 2
      Width = 200
    end
    object lblAgrupacion: TcxLabel
      Left = 512
      Top = 8
      Caption = 'Agrupaci'#243'n'
      Style.TextColor = clNavy
      Transparent = True
    end
    object cboAgrupacion: TcxComboBox
      Left = 512
      Top = 30
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 3
      Width = 120
    end
    object btnComparar: TcxButton
      Left = 648
      Top = 28
      Width = 130
      Height = 30
      Caption = 'Comparar'
      TabOrder = 4
      OnClick = btnCompararClick
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 78
      Caption = 'Almac'#233'n'
      Style.TextColor = clNavy
      Transparent = True
    end
    object cboAlmacen: TcxComboBox
      Left = 16
      Top = 100
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 5
      Width = 200
    end
    object lblFamilia: TcxLabel
      Left = 228
      Top = 78
      Caption = 'Familia'
      Style.TextColor = clNavy
      Transparent = True
    end
    object cboFamilia: TcxComboBox
      Left = 228
      Top = 100
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 6
      Width = 240
    end
    object lblTemporada: TcxLabel
      Left = 480
      Top = 78
      Caption = 'Temporada'
      Style.TextColor = clNavy
      Transparent = True
    end
    object cboTemporada: TcxComboBox
      Left = 480
      Top = 100
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 7
      Width = 160
    end
  end
  object pnlResumen: TPanel [1]
    Left = 0
    Top = 140
    Width = 900
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object lblTotActualTit: TcxLabel
      Left = 16
      Top = 6
      Caption = 'Total periodo actual'
      Style.TextColor = clGrayText
      Transparent = True
    end
    object lblTotActual: TcxLabel
      Left = 16
      Top = 26
      Caption = '-'
      Style.Font.Height = -16
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object lblTotAnteriorTit: TcxLabel
      Left = 240
      Top = 6
      Caption = 'Total a'#241'o anterior'
      Style.TextColor = clGrayText
      Transparent = True
    end
    object lblTotAnterior: TcxLabel
      Left = 240
      Top = 26
      Caption = '-'
      Style.Font.Height = -16
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object lblVariacionTit: TcxLabel
      Left = 464
      Top = 6
      Caption = 'Variaci'#243'n interanual'
      Style.TextColor = clGrayText
      Transparent = True
    end
    object lblVariacion: TcxLabel
      Left = 464
      Top = 26
      Caption = '-'
      Style.Font.Height = -16
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
  end
  object pnlChart: TPanel [2]
    Left = 0
    Top = 196
    Width = 900
    Height = 404
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 2
  end
end
