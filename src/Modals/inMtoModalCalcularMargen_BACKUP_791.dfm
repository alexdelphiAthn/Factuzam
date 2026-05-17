inherited frmModalCalcularMargen: TfrmModalCalcularMargen
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Calcular margen comercial'
  ClientHeight = 480
  ClientWidth = 700
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
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
    ExplicitWidth = 698
    ExplicitHeight = 412
    object lblArticulo: TcxLabel
      Left = 24
      Top = 18
      Caption = 'Art'#237'culo'
<<<<<<< HEAD
      TabOrder = 9
=======
      Properties.LineOptions.Visible = False
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
<<<<<<< HEAD
      TabOrder = 10
=======
      Properties.LineOptions.Visible = False
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
<<<<<<< HEAD
      TabOrder = 11
=======
      Properties.LineOptions.Visible = False
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
<<<<<<< HEAD
      TabOrder = 12
=======
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
    end
    object edtCoste: TcxCurrencyEdit
      Left = 220
      Top = 130
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 3
      Width = 160
    end
    object lblMargen: TcxLabel
      Left = 24
      Top = 174
      Caption = 'Margen %'
<<<<<<< HEAD
      TabOrder = 13
=======
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
<<<<<<< HEAD
      TabOrder = 14
=======
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
    end
    object edtAjuste: TcxCurrencyEdit
      Left = 258
      Top = 206
      Properties.DecimalPlaces = 4
      Properties.DisplayFormat = '0.0000'
      Properties.OnChange = RecalcularPrecioSalida
      TabOrder = 5
      Width = 122
    end
    object lblMenos: TcxLabel
      Left = 24
      Top = 246
      Caption = 'Menos (resta al final)'
<<<<<<< HEAD
      TabOrder = 15
=======
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
<<<<<<< HEAD
      TabOrder = 16
=======
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
<<<<<<< HEAD
      TabOrder = 17
=======
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
    end
    object edtPrecioCalc: TcxCurrencyEdit
      Left = 226
      Top = 330
      Properties.DisplayFormat = '0.00 '#8364';-0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 8
      Width = 154
    end
    object lblFormula: TcxLabel
      Left = 24
      Top = 376
      Caption = 'precio = ceil(coste'#215'margen/100 / ajuste)'#215'ajuste '#8722' menos'
<<<<<<< HEAD
      TabOrder = 18
=======
      Style.Font.Style = [fsItalic]
      Style.IsFontAssigned = True
      Transparent = True
>>>>>>> 747ddf0054866e444917ab1fcedabec46edc35b2
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
    ExplicitTop = 412
    ExplicitWidth = 698
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
