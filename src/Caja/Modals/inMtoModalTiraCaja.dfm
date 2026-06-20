object frmModalTiraCaja: TfrmModalTiraCaja
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Tira de Caja'
  ClientHeight = 352
  ClientWidth = 470
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object lblTitulo: TcxLabel
    Left = 20
    Top = 16
    Caption = 'Tira de Caja'
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -19
    Style.Font.Name = 'Lucida Sans'
    Style.Font.Style = [fsBold]
    Style.IsFontAssigned = True
    Transparent = True
  end
  object lblSerie: TcxLabel
    Left = 20
    Top = 72
    Caption = 'Serie:'
    Transparent = True
  end
  object cbSerie: TcxComboBox
    Left = 110
    Top = 68
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 0
    Width = 330
  end
  object chkQR: TcxCheckBox
    Left = 110
    Top = 112
    Caption = 'Imprimir QR Verifactu'
    TabOrder = 1
    Transparent = True
    Width = 330
  end
  object chkTraspasos: TcxCheckBox
    Left = 110
    Top = 144
    Caption = 'Incluir traspasos salientes (origen)'
    TabOrder = 2
    Transparent = True
    Width = 330
  end
  object chkIngresos: TcxCheckBox
    Left = 110
    Top = 176
    Caption = 'Incluir ingresos por caja'
    TabOrder = 3
    Transparent = True
    Width = 330
  end
  object chkGastos: TcxCheckBox
    Left = 110
    Top = 208
    Caption = 'Incluir gastos por caja'
    TabOrder = 4
    Transparent = True
    Width = 330
  end
  object chkCredito: TcxCheckBox
    Left = 110
    Top = 240
    Caption = 'Incluir ventas a crédito (depósitos)'
    TabOrder = 5
    Transparent = True
    Width = 330
  end
  object btnImprimir: TcxButton
    Left = 110
    Top = 292
    Width = 150
    Height = 40
    Caption = 'Imprimir'
    Default = True
    ModalResult = 1
    TabOrder = 6
  end
  object btnCancelar: TcxButton
    Left = 290
    Top = 292
    Width = 150
    Height = 40
    Cancel = True
    Caption = 'Cancelar (ESC)'
    ModalResult = 2
    TabOrder = 7
  end
end
