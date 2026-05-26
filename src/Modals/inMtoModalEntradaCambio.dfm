inherited frmModalEntradaCambio: TfrmModalEntradaCambio
  BorderStyle = bsDialog
  Caption = 'Entrada de Cambio (F6)'
  ClientHeight = 250
  ClientWidth = 450
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 450
    Height = 200
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
      TabOrder = 6
      Transparent = True
    end
    object lblEmpleadoLbl: TcxLabel
      Left = 16
      Top = 48
      Caption = 'Empleado:'
      TabOrder = 7
      Transparent = True
    end
    object txtEmpleado: TcxTextEdit
      Left = 100
      Top = 46
      Properties.OnChange = txtEmpleadoPropertiesChange
      TabOrder = 0
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 228
      Top = 48
      AutoSize = False
      Style.TextColor = clNavy
      TabOrder = 8
      Transparent = True
      Height = 21
      Width = 200
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 88
      Caption = 'Importe:'
      TabOrder = 9
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 86
      TabOrder = 1
      Value = 0.000000000000000000
      Width = 160
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 128
      Caption = 'Concepto:'
      TabOrder = 10
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 126
      Properties.MaxLength = 100
      TabOrder = 2
      Text = 'Entrada de cambio'
      Width = 330
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 200
    Width = 450
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 140
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 280
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
    Top = 210
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
