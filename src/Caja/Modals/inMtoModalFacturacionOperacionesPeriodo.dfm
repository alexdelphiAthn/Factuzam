inherited frmModalFacturacionOperacionesPeriodo: TfrmModalFacturacionOperacionesPeriodo
  Caption = 'Facturaci'#243'n de operaciones por periodo'
  ClientHeight = 405
  ClientWidth = 650
  Position = poMainFormCenter
  ExplicitWidth = 666
  ExplicitHeight = 444
  TextHeight = 17
  object lblContexto: TcxLabel
    Left = 16
    Top = 16
    Caption = 'TPV activo:'
    Transparent = True
  end
  object edtContexto: TcxTextEdit
    Left = 16
    Top = 38
    Properties.ReadOnly = True
    TabOrder = 0
    Width = 610
  end
  object lblDesde: TcxLabel
    Left = 16
    Top = 78
    Caption = 'Desde:'
    Transparent = True
  end
  object dteDesde: TcxDateEdit
    Left = 16
    Top = 100
    TabOrder = 1
    Width = 180
  end
  object lblHasta: TcxLabel
    Left = 220
    Top = 78
    Caption = 'Hasta:'
    Transparent = True
  end
  object dteHasta: TcxDateEdit
    Left = 220
    Top = 100
    TabOrder = 2
    Width = 180
  end
  object lblFechaDocumento: TcxLabel
    Left = 424
    Top = 78
    Caption = 'Fecha documento:'
    Transparent = True
  end
  object dteFechaDocumento: TcxDateEdit
    Left = 424
    Top = 100
    TabOrder = 3
    Width = 202
  end
  object chkVentasContado: TcxCheckBox
    Left = 16
    Top = 146
    Caption = 'VE: proforma interna de VENTA CONTADO'
    State = cbsChecked
    TabOrder = 4
  end
  object chkTraspasosEmpresas: TcxCheckBox
    Left = 16
    Top = 178
    Caption = 'TA: factura fiscal entre empresas'
    State = cbsChecked
    TabOrder = 5
    OnClick = chkTraspasosEmpresasClick
  end
  object lblSerieFiscal: TcxLabel
    Left = 424
    Top = 146
    Caption = 'Serie fiscal TA:'
    Transparent = True
  end
  object edtSerieFiscal: TcxTextEdit
    Left = 424
    Top = 168
    TabOrder = 6
    Width = 202
  end
  object memResultado: TcxMemo
    Left = 16
    Top = 222
    Properties.ReadOnly = True
    TabOrder = 7
    Height = 116
    Width = 610
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 356
    Width = 650
    Height = 49
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 8
    object btnProcesar: TcxButton
      Left = 16
      Top = 10
      Width = 180
      Height = 29
      Caption = 'Procesar periodo'
      TabOrder = 0
      OnClick = btnProcesarClick
    end
    object btnInforme: TcxButton
      Left = 220
      Top = 10
      Width = 180
      Height = 29
      Caption = 'Ver informe'
      TabOrder = 1
      OnClick = btnInformeClick
    end
    object btnCerrar: TcxButton
      Left = 446
      Top = 10
      Width = 180
      Height = 29
      Caption = 'Cerrar'
      TabOrder = 2
      OnClick = btnCerrarClick
    end
  end
end
