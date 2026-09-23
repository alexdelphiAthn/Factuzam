inherited frmModalConversionPresupuesto: TfrmModalConversionPresupuesto
  Caption = 'Pasar a documento'
  ClientHeight = 330
  ClientWidth = 500
  Position = poScreenCenter
  TextHeight = 19
  object lblTipoDocumento: TcxLabel [0]
    Left = 24
    Top = 27
    Caption = 'Documento:'
    Transparent = True
  end
  object cbbTipoDocumento: TcxComboBox [1]
    Left = 180
    Top = 24
    Properties.DropDownListStyle = lsFixedList
    Properties.OnEditValueChanged = cbbTipoDocumentoPropertiesEditValueChanged
    TabOrder = 0
    Width = 296
  end
  object lblAlmacen: TcxLabel [2]
    Left = 24
    Top = 67
    Caption = 'Almac'#233'n:'
    Transparent = True
  end
  object cbbAlmacen: TcxLookupComboBox [3]
    Left = 180
    Top = 64
    Properties.DropDownListStyle = lsFixedList
    Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
    Properties.ListColumns = <
      item
        Caption = 'C'#243'digo'
        Width = 60
        FieldName = 'CODIGO_ALM_ALM'
      end
      item
        Caption = 'Almac'#233'n'
        FieldName = 'NOMBRE_ALM_ALM'
      end>
    Properties.ListFieldIndex = 1
    Properties.ListOptions.ShowHeader = False
    Properties.OnEditValueChanged = cbbAlmacenPropertiesEditValueChanged
    TabOrder = 1
    Width = 296
  end
  object lblSerie: TcxLabel [4]
    Left = 24
    Top = 107
    Caption = 'Serie:'
    Transparent = True
  end
  object cbbSerie: TcxComboBox [5]
    Left = 180
    Top = 104
    Properties.CharCase = ecUpperCase
    Properties.DropDownListStyle = lsEditList
    Properties.MaxLength = 12
    TabOrder = 2
    Width = 140
  end
  object lblNumero: TcxLabel [6]
    Left = 24
    Top = 147
    Caption = 'N'#250'mero:'
    Transparent = True
  end
  object chkNumeroAutomatico: TcxCheckBox [7]
    Left = 180
    Top = 145
    Caption = 'Autom'#225'tico'
    Properties.OnEditValueChanged = chkNumeroAutomaticoPropertiesEditValueChanged
    State = cbsChecked
    TabOrder = 3
    Transparent = True
    Width = 140
  end
  object txtNumero: TcxTextEdit [8]
    Left = 336
    Top = 144
    Enabled = False
    Properties.MaxLength = 20
    TabOrder = 4
    Width = 140
  end
  object lblFecha: TcxLabel [9]
    Left = 24
    Top = 187
    Caption = 'Fecha:'
    Transparent = True
  end
  object dteFecha: TcxDateEdit [10]
    Left = 180
    Top = 184
    TabOrder = 5
    Width = 140
  end
  object chkMueveStock: TcxCheckBox [11]
    Left = 180
    Top = 225
    Caption = 'Genera movimientos de stock'
    State = cbsChecked
    TabOrder = 6
    Transparent = True
    Width = 296
  end
  object btnCancelar: TcxButton [12]
    Left = 40
    Top = 270
    Width = 190
    Height = 40
    Cancel = True
    Caption = '&Cancelar (ESC)'
    TabOrder = 8
    OnClick = btnCancelarClick
  end
  object btnAceptar: TcxButton [13]
    Left = 270
    Top = 270
    Width = 190
    Height = 40
    Caption = '&Aceptar'
    Default = True
    TabOrder = 7
    OnClick = btnAceptarClick
  end
end
