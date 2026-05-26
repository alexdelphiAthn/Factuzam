inherited frmModalEntradaCambio: TfrmModalEntradaCambio
  BorderStyle = bsDialog
  Caption = 'Entrada de Cambio (F6)'
  ClientHeight = 200
  ClientWidth = 420
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 420
    Height = 150
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Introduzca el efectivo que entra en caja'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 3
      Transparent = True
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 50
      Caption = 'Importe:'
      TabOrder = 4
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 48
      TabOrder = 0
      Value = 0.000000000000000000
      Width = 160
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 90
      Caption = 'Concepto:'
      TabOrder = 5
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 88
      Properties.MaxLength = 100
      TabOrder = 1
      Text = 'Entrada de cambio'
      Width = 300
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 150
    Width = 420
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 120
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 260
      Top = 8
      Width = 130
      Height = 35
      Action = actCancelar
      Cancel = True
      TabOrder = 1
    end
  end
  object alAcciones: TActionList
    Left = 16
    Top = 160
    object actAceptar: TAction
      Caption = 'Aceptar (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar (ESC)'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
