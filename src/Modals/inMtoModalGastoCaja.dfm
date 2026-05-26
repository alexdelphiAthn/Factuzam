inherited frmModalGastoCaja: TfrmModalGastoCaja
  BorderStyle = bsDialog
  Caption = 'Gastos por Caja / Retiradas (F7)'
  ClientHeight = 260
  ClientWidth = 420
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 420
    Height = 210
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
      TabOrder = 5
      Transparent = True
    end
    object rgTipo: TcxRadioGroup
      Left = 16
      Top = 40
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
      Width = 384
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 102
      Caption = 'Importe:'
      TabOrder = 6
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 100
      TabOrder = 1
      Value = 0.000000000000000000
      Width = 160
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 142
      Caption = 'Concepto:'
      TabOrder = 7
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 140
      Properties.MaxLength = 100
      TabOrder = 2
      Width = 300
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 210
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
    Top = 220
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
