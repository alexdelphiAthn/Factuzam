inherited frmModalGastoCaja: TfrmModalGastoCaja
  BorderStyle = bsDialog
  Caption = 'Gastos por Caja / Retiradas (F7)'
  ClientHeight = 360
  ClientWidth = 450
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 450
    Height = 310
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Registrar gasto o retirada de efectivo'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 10
      Transparent = True
    end
    object rgTipo: TcxRadioGroup
      Left = 16
      Top = 38
      Caption = 'Tipo'
      Properties.Columns = 2
      Properties.Items = <
        item
          Caption = 'Gasto de caja'
        end
        item
          Caption = 'Retirada de efectivo'
        end>
      ItemIndex = 0
      TabOrder = 0
      Height = 48
      Width = 414
    end
    object lblEmpleadoLbl: TcxLabel
      Left = 16
      Top = 100
      Caption = 'Empleado:'
      TabOrder = 11
      Transparent = True
    end
    object txtEmpleado: TcxTextEdit
      Left = 100
      Top = 98
      Properties.OnChange = txtEmpleadoPropertiesChange
      TabOrder = 1
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 228
      Top = 100
      AutoSize = False
      Style.TextColor = clNavy
      TabOrder = 12
      Transparent = True
      Height = 21
      Width = 200
    end
    object lblDestinoLbl: TcxLabel
      Left = 16
      Top = 130
      Caption = 'Destino:'
      TabOrder = 13
      Transparent = True
    end
    object rgDestino: TcxRadioGroup
      Left = 100
      Top = 126
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = 'Caja fuerte'
        end
        item
          Caption = 'Banco'
        end
        item
          Caption = 'Encargado'
        end>
      ItemIndex = 0
      TabOrder = 2
      Height = 44
      Width = 330
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 186
      Caption = 'Importe:'
      TabOrder = 14
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 184
      TabOrder = 3
      Value = 0.000000000000000000
      Width = 160
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 226
      Caption = 'Concepto:'
      TabOrder = 15
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 224
      Properties.MaxLength = 100
      TabOrder = 4
      Width = 330
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 310
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
    Top = 320
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
