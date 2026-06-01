object frmCajaReferenciaPago: TfrmCajaReferenciaPago
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Datos de Pago'
  ClientHeight = 541
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
    Height = 481
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    ExplicitWidth = 498
    ExplicitHeight = 452
    object gbInfoPago: TcxGroupBox
      Left = 10
      Top = 9
      Caption = ' Informaci'#243'n del Pago '
      ParentFont = False
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -17
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 0
      Height = 100
      Width = 480
      object lblFormaPago: TcxLabel
        Left = 23
        Top = 23
        Caption = 'Forma de Pago:'
        TabOrder = 0
      end
      object lblFormaPagoValor: TcxLabel
        Left = 162
        Top = 23
        Caption = 'Tarjeta Bancaria'
        TabOrder = 1
      end
      object lblImporte: TcxLabel
        Left = 49
        Top = 61
        Caption = 'Importe:'
        TabOrder = 2
      end
      object edtImporteDivisa: TcxCurrencyEdit
        Left = 144
        Top = 57
        ParentFont = False
        Properties.DecimalPlaces = 11
        Properties.DisplayFormat = ',0.00000000000 ;-,0.00000000000'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -17
        Style.Font.Name = 'Lucida Sans'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 3
        Width = 153
      end
      object txtPendiente: TcxCurrencyEdit
        Left = 360
        Top = 57
        Enabled = False
        ParentFont = False
        Properties.DisplayFormat = ',0.00 '#8364' ;-,0.00 '#8364' '
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -17
        Style.Font.Name = 'Lucida Sans'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 4
        Width = 100
      end
      object cxLabel1: TcxLabel
        Left = 375
        Top = 34
        Caption = 'Pendiente'
        Enabled = False
        TabOrder = 5
      end
    end
    object gbReferencia: TcxGroupBox
      Left = 10
      Top = 116
      Caption = ' Referencia '
      ParentFont = False
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -17
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 1
      Height = 94
      Width = 480
      object lblReferencia: TcxLabel
        Left = 29
        Top = 25
        Caption = 'Referencia:'
        TabOrder = 0
      end
      object lblEjemplo: TcxLabel
        Left = 29
        Top = 50
        Caption = 'Ej: 123456'
        TabOrder = 1
      end
      object edtReferencia: TcxTextEdit
        Left = 144
        Top = 22
        ParentFont = False
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -17
        Style.Font.Name = 'Lucida Sans'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 2
        Width = 316
      end
    end
    object gbDivisa: TcxGroupBox
      Left = 10
      Top = 207
      Caption = ' Otra Divisa '
      TabOrder = 2
      Height = 162
      Width = 480
      object lblDivisa: TcxLabel
        Left = 59
        Top = 35
        Caption = 'Divisa:'
        TabOrder = 2
      end
      object lblFactorCambio: TcxLabel
        Left = 28
        Top = 69
        Caption = 'Cotizaci'#243'n:'
        TabOrder = 3
      end
      object lblImporteDivisa: TcxLabel
        Left = 255
        Top = 106
        Caption = 'Importe final:'
        TabOrder = 4
      end
      object lblEquivale: TcxLabel
        Left = 23
        Top = 102
        Caption = '0,00 EUR = 0.00 USD'
        TabOrder = 5
      end
      object edtFactorCambio: TcxCurrencyEdit
        Left = 120
        Top = 66
        Properties.DecimalPlaces = 11
        Properties.DisplayFormat = '0.00000000000'
        Properties.ReadOnly = False
        Properties.OnChange = edtFactorCambioPropertiesChange
        TabOrder = 0
        Width = 145
      end
      object edtImporteEuros: TcxCurrencyEdit
        Left = 350
        Top = 103
        Properties.ReadOnly = True
        Properties.OnChange = edtImporteDivisaPropertiesChange
        TabOrder = 1
        Width = 110
      end
      object txtDivisa: TcxTextEdit
        Left = 120
        Top = 31
        Enabled = False
        TabOrder = 6
        Width = 340
      end
      object btnGetDivisa: TcxButton
        Left = 271
        Top = 60
        Width = 40
        Height = 34
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000023744558745469746C6500436F6E766572743B52657065
          61743B4172726F773B45786368616E6765762368D2000000C049444154785EA5
          D3B10983501087F1141619C0259C20A033BC29EC1C20609914AE90116C1C208E
          E00E366EF04AC1E2F205727024175E24C5AFF3FF71A01E4424E9DCDF04011FCF
          EC08F811FB90CA51A3C78C0DE244DC4085019210BC408111E24B5F703183051D
          4A1CED385CEF27B45E603281C6790B3A8E98BCC00A4144A663C528438460FD76
          41C4F3C400790B3410C0BFA0B5E397234A74584CE0E27E483A4E1851E866EF78
          40A59B5F2ED830A3478D3CF92FD88886AD6440237B027F7900F82BA5E5BA0A0F
          4B0000000049454E44AE426082}
        TabOrder = 7
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Lucida Sans'
        Font.Style = []
        ParentFont = False
        OnClick = btnGetDivisaClick
      end
      object lblEquivale2: TcxLabel
        Left = 23
        Top = 119
        Caption = '0,00 EUR = 0.00 USD'
        TabOrder = 8
      end
    end
    object gbBlockchain: TcxGroupBox
      Left = 10
      Top = 368
      Caption = ' Blockchain '
      TabOrder = 3
      Visible = False
      Height = 99
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
    Top = 481
    Width = 500
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    ExplicitTop = 452
    ExplicitWidth = 498
    object btnAceptar: TcxButton
      Left = 357
      Top = 9
      Width = 133
      Height = 45
      Caption = 'Aceptar (F12)'
      TabOrder = 0
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Lucida Sans'
      Font.Style = []
      ParentFont = False
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 208
      Top = 9
      Width = 143
      Height = 45
      Caption = 'Cancelar (ESC)'
      TabOrder = 1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Lucida Sans'
      Font.Style = []
      ParentFont = False
      OnClick = btnCancelarClick
    end
    object txtSobra: TcxCurrencyEdit
      Left = 65
      Top = 4
      Enabled = False
      ParentFont = False
      Properties.DisplayFormat = ',0.00 '#8364' ;-,0.00 '#8364' '
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -17
      Style.Font.Name = 'Lucida Sans'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 2
      Width = 100
    end
    object cxLabel2: TcxLabel
      Left = 10
      Top = 7
      Caption = 'Sobra:'
      Enabled = False
      TabOrder = 3
    end
  end
end
