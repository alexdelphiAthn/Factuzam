object frmModalTiraCaja: TfrmModalTiraCaja
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Tira de Caja'
  ClientHeight = 220
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
  object btnImprimir: TcxButton
    Left = 110
    Top = 160
    Width = 150
    Height = 40
    Caption = 'Imprimir'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancelar: TcxButton
    Left = 290
    Top = 160
    Width = 150
    Height = 40
    Cancel = True
    Caption = 'Cancelar (ESC)'
    ModalResult = 2
    TabOrder = 3
  end
end
