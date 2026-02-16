object frmCajaReferenciaPago: TfrmCajaReferenciaPago
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Datos de Pago'
  ClientHeight = 520
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Lucida Sans'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 16
  object pnlPrincipal: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 460
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    ExplicitWidth = 494
    ExplicitHeight = 451
    object gbInfoPago: TcxGroupBox
      Left = 10
      Top = 10
      Caption = ' Informaci'#243'n del Pago '
      TabOrder = 0
      Height = 100
      Width = 480
      object lblFormaPago: TcxLabel
        Left = 15
        Top = 29
        Caption = 'Forma de Pago:'
        TabOrder = 0
      end
      object lblFormaPagoValor: TcxLabel
        Left = 120
        Top = 29
        Caption = 'Tarjeta Bancaria'
        TabOrder = 1
      end
      object lblImporte: TcxLabel
        Left = 49
        Top = 63
        Caption = 'Importe:'
        TabOrder = 2
      end
      object edtImporte: TcxCurrencyEdit
        Left = 120
        Top = 60
        TabOrder = 3
        Width = 120
      end
    end
    object gbReferencia: TcxGroupBox
      Left = 10
      Top = 116
      Caption = ' Referencia '
      TabOrder = 1
      Height = 85
      Width = 480
      object lblReferencia: TcxLabel
        Left = 29
        Top = 25
        Caption = 'Referencia:'
        TabOrder = 0
      end
      object lblEjemplo: TcxLabel
        Left = 15
        Top = 55
        Caption = 'Ej: 123456'
        TabOrder = 1
      end
      object edtReferencia: TcxTextEdit
        Left = 120
        Top = 22
        TabOrder = 2
        Width = 340
      end
    end
    object gbDivisa: TcxGroupBox
      Left = 10
      Top = 207
      Caption = ' Otra Divisa '
      TabOrder = 2
      Height = 142
      Width = 480
      object lblDivisa: TcxLabel
        Left = 59
        Top = 59
        Caption = 'Divisa:'
        TabOrder = 4
      end
      object lblFactorCambio: TcxLabel
        Left = 28
        Top = 89
        Caption = 'Cotizaci'#243'n:'
        TabOrder = 5
      end
      object lblImporteDivisa: TcxLabel
        Left = 240
        Top = 89
        Caption = 'Importe divisa:'
        TabOrder = 6
      end
      object lblEquivale: TcxLabel
        Left = 120
        Top = 115
        Caption = '0,00 EUR = 0.00 USD'
        TabOrder = 7
      end
      object chkUsarOtraDivisa: TCheckBox
        Left = 15
        Top = 29
        Width = 250
        Height = 17
        Caption = 'El cliente paga en otra divisa'
        TabOrder = 0
        OnClick = chkUsarOtraDivisaClick
      end
      object cbbDivisa: TcxComboBox
        Left = 120
        Top = 56
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = cbbDivisaPropertiesChange
        TabOrder = 1
        Width = 200
      end
      object edtFactorCambio: TcxCurrencyEdit
        Left = 120
        Top = 86
        Properties.DisplayFormat = '0.0000'
        Properties.OnChange = edtFactorCambioPropertiesChange
        TabOrder = 2
        Width = 100
      end
      object edtImporteDivisa: TcxCurrencyEdit
        Left = 350
        Top = 86
        Properties.OnChange = edtImporteDivisaPropertiesChange
        TabOrder = 3
        Width = 110
      end
    end
    object gbBlockchain: TcxGroupBox
      Left = 10
      Top = 355
      Caption = ' Blockchain '
      TabOrder = 3
      Visible = False
      Height = 95
      Width = 480
      object lblRedBlockchain: TcxLabel
        Left = 73
        Top = 25
        Caption = 'Red:'
        TabOrder = 0
      end
      object lblTxHash: TcxLabel
        Left = 44
        Top = 55
        Caption = 'TX Hash:'
        TabOrder = 1
      end
      object cbbRedBlockchain: TcxComboBox
        Left = 120
        Top = 22
        Properties.DropDownListStyle = lsFixedList
        TabOrder = 2
        Width = 200
      end
      object edtTxHash: TcxTextEdit
        Left = 120
        Top = 52
        TabOrder = 3
        Width = 340
      end
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 460
    Width = 500
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    ExplicitTop = 451
    ExplicitWidth = 494
    object btnAceptar: TcxButton
      Left = 370
      Top = 6
      Width = 120
      Height = 39
      Caption = 'Aceptar (F12)'
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 231
      Top = 6
      Width = 120
      Height = 39
      Caption = 'Cancelar (ESC)'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
end
