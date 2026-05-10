inherited frmModalCalcularMargen: TfrmModalCalcularMargen
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Calcular margen comercial'
  ClientHeight = 472
  ClientWidth = 540
  Position = poScreenCenter
  OnClose = FormClose
  ExplicitWidth = 556
  ExplicitHeight = 511
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 540
    Height = 412
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblArticulo: TcxLabel
      Left = 24
      Top = 16
      Caption = 'Art'#237'culo'
    end
    object edtArticulo: TcxTextEdit
      Left = 144
      Top = 14
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 369
    end
    object lblTarifa: TcxLabel
      Left = 24
      Top = 46
      Caption = 'Tarifa'
    end
    object edtTarifa: TcxTextEdit
      Left = 144
      Top = 44
      Properties.ReadOnly = True
      TabOrder = 1
      Width = 369
    end
    object lblSku: TcxLabel
      Left = 24
      Top = 76
      Caption = 'SKU'
    end
    object edtSku: TcxTextEdit
      Left = 144
      Top = 74
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 369
    end
    object lblCoste: TcxLabel
      Left = 24
      Top = 124
      Caption = 'Precio coste'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
    end
    object edtCoste: TcxCurrencyEdit
      Left = 144
      Top = 122
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 3
      Width = 137
    end
    object lblMargen: TcxLabel
      Left = 24
      Top = 162
      Caption = 'Margen (%)'
    end
    object edtMargen: TcxCurrencyEdit
      Left = 144
      Top = 160
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00 %'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 4
      Width = 137
    end
    object lblMultiplo: TcxLabel
      Left = 24
      Top = 196
      Caption = 'M'#250'ltiplo de ajuste'
    end
    object edtMultiplo: TcxCurrencyEdit
      Left = 144
      Top = 194
      Properties.DecimalPlaces = 4
      Properties.DisplayFormat = '0.0000'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 5
      Width = 137
    end
    object lblMenos: TcxLabel
      Left = 24
      Top = 230
      Caption = 'Menos (resta)'
    end
    object edtMenos: TcxCurrencyEdit
      Left = 144
      Top = 228
      Properties.DecimalPlaces = 4
      Properties.DisplayFormat = '0.0000'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 6
      Width = 137
    end
    object lblPrecioActual: TcxLabel
      Left = 24
      Top = 282
      Caption = 'Precio salida actual'
    end
    object edtPrecioActual: TcxCurrencyEdit
      Left = 200
      Top = 280
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 7
      Width = 137
    end
    object lblPrecioCalc: TcxLabel
      Left = 24
      Top = 318
      Caption = 'Precio salida calculado'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
    end
    object edtPrecioCalc: TcxCurrencyEdit
      Left = 200
      Top = 316
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.ReadOnly = True
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      TabOrder = 8
      Width = 137
    end
    object lblFormula: TcxLabel
      Left = 24
      Top = 360
      Caption = 'Precio = coste'#215'(1 + margen/100), ajustado al m'#250'ltiplo y restando "Menos".'
      Style.Font.Style = [fsItalic]
      Style.IsFontAssigned = True
    end
  end
  object pnlButtons: TPanel [1]
    Left = 0
    Top = 412
    Width = 540
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 60
      Top = 10
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      ModalResult = 2
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 303
      Top = 10
      Width = 177
      Height = 40
      Caption = '&Aceptar (F12)'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
end
