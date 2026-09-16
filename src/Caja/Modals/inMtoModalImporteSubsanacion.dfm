inherited frmModalImporteSubsanacion: TfrmModalImporteSubsanacion
  ActiveControl = edtTotalCorregido
  BorderStyle = bsDialog
  Caption = ''
  ClientHeight = 242
  ClientWidth = 480
  Position = poOwnerFormCenter
  object lblTotalActual: TcxLabel
    Left = 16
    Top = 16
    AutoSize = False
    Caption = ''
    TabOrder = 3
    Transparent = True
    Height = 26
    Width = 448
  end
  object lblExplicacion: TcxLabel
    Left = 16
    Top = 52
    AutoSize = False
    Caption = ''
    Properties.WordWrap = True
    TabOrder = 4
    Transparent = True
    Height = 42
    Width = 448
  end
  object lblTotalCorregido: TcxLabel
    Left = 16
    Top = 104
    Caption = ''
    FocusControl = edtTotalCorregido
    TabOrder = 5
    Transparent = True
  end
  object edtTotalCorregido: TcxCurrencyEdit
    Left = 16
    Top = 132
    Properties.DecimalPlaces = 2
    Properties.DisplayFormat = '#,##0.00 "€";-#,##0.00 "€";0.00 "€"'
    TabOrder = 0
    Width = 218
  end
  object btnAplicar: TcxButton
    Left = 248
    Top = 192
    Width = 100
    Height = 34
    Default = True
    TabOrder = 1
    OnClick = btnAplicarClick
  end
  object btnCancelar: TcxButton
    Left = 364
    Top = 192
    Width = 100
    Height = 34
    Cancel = True
    ModalResult = 2
    TabOrder = 2
  end
end
