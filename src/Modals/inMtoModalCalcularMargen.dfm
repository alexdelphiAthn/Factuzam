inherited frmModalCalcularMargen: TfrmModalCalcularMargen
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Calcular margen comercial'
  ClientHeight = 480
  ClientWidth = 700
  Position = poScreenCenter
  OnClose = FormClose
  ExplicitWidth = 716
  ExplicitHeight = 519
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 700
    Height = 420
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblArticulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Art'#237'culo'
      Properties.LineOptions.Visible = False
    end
    object edtArticulo: TcxTextEdit
      Left = 220
      Top = 14
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 450
    end
    object lblTarifa: TcxLabel
      Left = 24
      Top = 50
      Caption = 'Tarifa'
      Properties.LineOptions.Visible = False
    end
    object edtTarifa: TcxTextEdit
      Left = 220
      Top = 46
      Properties.ReadOnly = True
      TabOrder = 1
      Width = 450
    end
    object lblSku: TcxLabel
      Left = 24
      Top = 82
      Caption = 'SKU'
      Properties.LineOptions.Visible = False
    end
    object edtSku: TcxTextEdit
      Left = 220
      Top = 78
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 450
    end
    object lblCoste: TcxLabel
      Left = 24
      Top = 134
      Caption = 'Precio coste'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
    end
    object edtCoste: TcxCurrencyEdit
      Left = 220
      Top = 130
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.OnChange = RecalcularPrecioSalida
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      TabOrder = 3
      Width = 160
    end
    object lblMargen: TcxLabel
      Left = 24
      Top = 174
      Caption = 'Margen %'
    end
    object edtMargen: TcxCurrencyEdit
      Left = 220
      Top = 170
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00 %'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 4
      Width = 160
    end
    object lblAjuste: TcxLabel
      Left = 24
      Top = 210
      Caption = 'Ajuste (siguiente m'#250'ltiplo)'
    end
    object edtAjuste: TcxCurrencyEdit
      Left = 220
      Top = 206
      Properties.DecimalPlaces = 4
      Properties.DisplayFormat = '0.0000'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 5
      Width = 160
    end
    object lblMenos: TcxLabel
      Left = 24
      Top = 246
      Caption = 'Menos (resta al final)'
    end
    object edtMenos: TcxCurrencyEdit
      Left = 220
      Top = 242
      Properties.DecimalPlaces = 4
      Properties.DisplayFormat = '0.0000'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 6
      Width = 160
    end
    object lblPrecioActual: TcxLabel
      Left = 24
      Top = 298
      Caption = 'Precio salida actual'
    end
    object edtPrecioActual: TcxCurrencyEdit
      Left = 220
      Top = 294
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 7
      Width = 160
    end
    object lblPrecioCalc: TcxLabel
      Left = 24
      Top = 334
      Caption = 'Precio salida calculado'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
    end
    object edtPrecioCalc: TcxCurrencyEdit
      Left = 220
      Top = 330
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.ReadOnly = True
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      TabOrder = 8
      Width = 160
    end
    object lblFormula: TcxLabel
      Left = 24
      Top = 376
      Caption = 'precio = ceil(coste'#215'margen/100 / ajuste)'#215'ajuste '#8722' menos'
      Style.Font.Style = [fsItalic]
      Style.IsFontAssigned = True
    end
  end
  object pnlButtons: TPanel [1]
    Left = 0
    Top = 420
    Width = 700
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 100
      Top = 10
      Width = 200
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      ModalResult = 2
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 400
      Top = 10
      Width = 200
      Height = 40
      Caption = '&Aceptar (F12)'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
end
