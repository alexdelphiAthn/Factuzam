inherited frmModalSeriesDocumentos: TfrmModalSeriesDocumentos
  BorderStyle = bsDialog
  Caption = 'Añadir serie a todos'
  ClientHeight = 210
  ClientWidth = 430
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 430
    Height = 160
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Serie común para todos los documentos'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 6
      Transparent = True
    end
    object lblSerie: TcxLabel
      Left = 16
      Top = 46
      Caption = 'Serie'
      TabOrder = 7
      Transparent = True
    end
    object txtSerie: TcxTextEdit
      Left = 130
      Top = 44
      Properties.MaxLength = 12
      TabOrder = 0
      Width = 120
    end
    object lblFechaDesde: TcxLabel
      Left = 16
      Top = 82
      Caption = 'Fecha inicio'
      TabOrder = 8
      Transparent = True
    end
    object dteFechaDesde: TcxDateEdit
      Left = 130
      Top = 80
      TabOrder = 1
      Width = 120
    end
    object lblFechaHasta: TcxLabel
      Left = 16
      Top = 118
      Caption = 'Fecha fin'
      TabOrder = 9
      Transparent = True
    end
    object dteFechaHasta: TcxDateEdit
      Left = 130
      Top = 116
      TabOrder = 2
      Width = 120
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 160
    Width = 430
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 148
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 286
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
    Top = 168
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
