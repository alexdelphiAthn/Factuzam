inherited frmModalFacturarAlbaranes: TfrmModalFacturarAlbaranes
  Caption = 'Facturar albaranes de compra'
  ClientHeight = 560
  ClientWidth = 720
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 720
  ExplicitHeight = 560
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 720
    Height = 184
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblEmpresa: TcxLabel
      Left = 16
      Top = 16
      Caption = 'Empresa'
      Transparent = True
    end
    object txtEmpresa: TcxTextEdit
      Left = 90
      Top = 14
      Properties.CharCase = ecUpperCase
      Properties.MaxLength = 8
      TabOrder = 0
      Width = 70
    end
    object lblProveedor: TcxLabel
      Left = 180
      Top = 16
      Caption = 'Proveedor'
      Transparent = True
    end
    object txtProveedor: TcxTextEdit
      Left = 270
      Top = 14
      Properties.CharCase = ecUpperCase
      Properties.MaxLength = 20
      TabOrder = 1
      Width = 110
    end
    object btnCargar: TcxButton
      Left = 400
      Top = 10
      Width = 120
      Height = 30
      Caption = 'Cargar'
      TabOrder = 2
      OnClick = btnCargarClick
    end
    object lblNombrePrv: TcxLabel
      Left = 16
      Top = 50
      Caption = ' '
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object rgModo: TcxRadioGroup
      Left = 16
      Top = 76
      Caption = ' Modo '
      Properties.Items = <
        item
          Caption = 'Crear factura nueva'
        end
        item
          Caption = 'Incorporar a una factura existente'
        end>
      Properties.OnEditValueChanged = rgModoPropertiesEditValueChanged
      ItemIndex = 0
      TabOrder = 3
      Height = 64
      Width = 520
    end
    object lblFacExistente: TcxLabel
      Left = 16
      Top = 150
      Caption = 'Factura existente'
      Transparent = True
    end
    object cbbFacExistente: TcxComboBox
      Left = 160
      Top = 148
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 4
      Width = 400
    end
  end
  object pnlGrid: TPanel [1]
    Left = 0
    Top = 184
    Width = 720
    Height = 316
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdAlb: TcxGrid
      Left = 0
      Top = 0
      Width = 720
      Height = 316
      Align = alClient
      TabOrder = 0
      object tvAlb: TcxGridDBTableView
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CheckBoxVisible = True
        OptionsSelection.MultiSelect = True
        OptionsView.GroupByBox = False
        object colAlbNumero: TcxGridDBColumn
          Caption = 'Numero'
          DataBinding.FieldName = 'NUMERO_ALBC'
          Width = 90
        end
        object colAlbSerie: TcxGridDBColumn
          Caption = 'Serie'
          DataBinding.FieldName = 'SERIE_ALBC'
          Width = 80
        end
        object colAlbFecha: TcxGridDBColumn
          Caption = 'Fecha'
          DataBinding.FieldName = 'FECHA_ALBC'
          Width = 100
        end
        object colAlbRefPrv: TcxGridDBColumn
          Caption = 'Ref. proveedor'
          DataBinding.FieldName = 'REF_PROVEEDOR_ALBC'
          Width = 160
        end
        object colAlbTotal: TcxGridDBColumn
          Caption = 'Total liquido'
          DataBinding.FieldName = 'TOTAL_LIQUIDO_ALBC'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Width = 130
        end
      end
      object lvlAlb: TcxGridLevel
        GridView = tvAlb
      end
    end
  end
  object pnlButton: TPanel [2]
    Left = 0
    Top = 500
    Width = 720
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnSalir: TcxButton
      Left = 40
      Top = 12
      Width = 170
      Height = 38
      Cancel = True
      Caption = '&Salir'
      TabOrder = 0
      OnClick = btnSalirClick
    end
    object btnFacturar: TcxButton
      Left = 470
      Top = 12
      Width = 210
      Height = 38
      Caption = '&Facturar seleccionados'
      Default = True
      TabOrder = 1
      OnClick = btnFacturarClick
    end
  end
end
