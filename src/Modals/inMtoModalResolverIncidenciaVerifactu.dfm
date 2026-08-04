inherited frmModalResolverIncidenciaVerifactu: TfrmModalResolverIncidenciaVerifactu
  BorderStyle = bsDialog
  Caption = 'Resolver incidencia VERI*FACTU'
  ClientHeight = 570
  ClientWidth = 720
  Position = poMainFormCenter
  object pnlBotones: TPanel
    Left = 0
    Top = 520
    Width = 720
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnResolver: TcxButton
      Left = 486
      Top = 9
      Width = 105
      Height = 32
      Caption = 'Resolver'
      TabOrder = 0
      OnClick = btnResolverClick
    end
    object btnCancelar: TcxButton
      Left = 599
      Top = 9
      Width = 105
      Height = 32
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object grpIncidencia: TcxGroupBox
    Left = 12
    Top = 12
    Caption = 'Incidencia comunicada por la AEAT'
    TabOrder = 0
    Height = 142
    Width = 696
    object lblFacturaTitulo: TcxLabel
      Left = 14
      Top = 24
      Caption = 'Factura original'
      Transparent = True
    end
    object lblFactura: TcxLabel
      Left = 166
      Top = 24
      AutoSize = False
      Caption = '-'
      Transparent = True
      Height = 24
      Width = 500
    end
    object lblErrorTitulo: TcxLabel
      Left = 14
      Top = 54
      Caption = 'Incidencia AEAT'
      Transparent = True
    end
    object lblError: TcxLabel
      Left = 166
      Top = 54
      AutoSize = False
      Caption = '-'
      Properties.WordWrap = True
      Transparent = True
      Height = 42
      Width = 500
    end
    object lblClienteActualTitulo: TcxLabel
      Left = 14
      Top = 105
      Caption = 'Destinatario de la factura'
      Transparent = True
    end
    object lblClienteActual: TcxLabel
      Left = 166
      Top = 105
      AutoSize = False
      Caption = '-'
      Transparent = True
      Height = 24
      Width = 500
    end
  end
  object grpResolucion: TcxGroupBox
    Left = 12
    Top = 162
    Caption = 'Tratamiento de la incidencia'
    TabOrder = 1
    Height = 176
    Width = 696
    object rgResolucion: TcxRadioGroup
      Left = 14
      Top = 22
      Properties.Items = <
        item
          Caption = 'La factura es correcta: subsanar el registro'
          Value = 0
        end
        item
          Caption = 'El dato figura en la factura: emitir rectificativa R4'
          Value = 1
        end>
      ItemIndex = 0
      Properties.OnChange = rgResolucionPropertiesChange
      TabOrder = 0
      Height = 68
      Width = 666
    end
    object lblMotivo: TcxLabel
      Left = 14
      Top = 94
      Caption = 'Motivo de la corrección'
      Transparent = True
    end
    object mMotivo: TcxMemo
      Left = 166
      Top = 94
      Properties.ScrollBars = ssVertical
      TabOrder = 2
      Height = 64
      Width = 514
    end
  end
  object grpRectificativa: TcxGroupBox
    Left = 12
    Top = 346
    Caption = 'Destinatario correcto'
    TabOrder = 2
    Height = 162
    Width = 696
    object lblCodigoCliente: TcxLabel
      Left = 14
      Top = 27
      Caption = 'Código de cliente'
      Transparent = True
    end
    object edtCodigoCliente: TcxTextEdit
      Left = 139
      Top = 25
      TabOrder = 0
      Width = 132
    end
    object btnCargarCliente: TcxButton
      Left = 279
      Top = 23
      Width = 118
      Height = 28
      Caption = 'Cargar cliente'
      TabOrder = 1
      OnClick = btnCargarClienteClick
    end
    object lblClienteCorrecto: TcxLabel
      Left = 139
      Top = 58
      AutoSize = False
      Caption = '-'
      Transparent = True
      Height = 24
      Width = 527
    end
    object lblSerieRectificativa: TcxLabel
      Left = 14
      Top = 96
      Caption = 'Serie rectificativa'
      Transparent = True
    end
    object edtSerieRectificativa: TcxTextEdit
      Left = 139
      Top = 94
      TabOrder = 3
      Width = 132
    end
    object lblFechaRectificativa: TcxLabel
      Left = 304
      Top = 96
      Caption = 'Fecha rectificativa'
      Transparent = True
    end
    object dtFechaRectificativa: TcxDateEdit
      Left = 436
      Top = 94
      TabOrder = 5
      Width = 132
    end
  end
end
