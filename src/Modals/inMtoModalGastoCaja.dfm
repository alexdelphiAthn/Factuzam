inherited frmModalGastoCaja: TfrmModalGastoCaja
  BorderStyle = bsDialog
  Caption = 'Gastos por Caja / Retiradas (F7)'
  ClientHeight = 330
  ClientWidth = 500
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 500
    Height = 280
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Registrar gasto o retirada de efectivo'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 10
      Transparent = True
    end
    object lblTipoLbl: TcxLabel
      Left = 16
      Top = 36
      Caption = 'Tipo:'
      TabOrder = 11
      Transparent = True
    end
    object rgTipo: TcxRadioGroup
      Left = 16
      Top = 54
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = 'Pago proveedor'
        end
        item
          Caption = 'Gastos limpieza'
        end
        item
          Caption = 'Retirada banco'
        end
        item
          Caption = 'Retirada encargado'
        end
        item
          Caption = 'Caja fuerte'
        end>
      ItemIndex = 2
      TabOrder = 0
      Height = 64
      Width = 468
    end
    object lblEmpleadoLbl: TcxLabel
      Left = 16
      Top = 132
      Caption = 'Empleado:'
      TabOrder = 12
      Transparent = True
    end
    object btnEmpleado: TcxButtonEdit
      Left = 100
      Top = 130
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnEmpleadoPropertiesButtonClick
      Properties.OnValidate = btnEmpleadoPropertiesValidate
      TabOrder = 1
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 230
      Top = 132
      AutoSize = False
      Style.TextColor = clNavy
      Style.Font.Style = [fsBold]
      TabOrder = 13
      Transparent = True
      Height = 21
      Width = 250
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 170
      Caption = 'Importe:'
      TabOrder = 14
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 168
      TabOrder = 2
      Value = 0.000000000000000000
      Width = 140
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 208
      Caption = 'Concepto:'
      TabOrder = 15
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 206
      Properties.MaxLength = 100
      TabOrder = 3
      Width = 380
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 280
    Width = 500
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 170
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 310
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
    Top = 290
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
