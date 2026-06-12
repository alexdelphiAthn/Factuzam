inherited frmModalFacturarTicket: TfrmModalFacturarTicket
  Caption = 'Facturar ticket (factura en sustituci'#243'n)'
  ClientHeight = 300
  ClientWidth = 560
  Position = poScreenCenter
  TextHeight = 19
  object lblTicket: TcxLabel [0]
    Left = 24
    Top = 27
    Caption = 'Ticket:'
    Transparent = True
  end
  object edtTicket: TcxTextEdit [1]
    Left = 160
    Top = 24
    Width = 240
    Properties.ReadOnly = True
    TabOrder = 0
  end
  object lblCliente: TcxLabel [2]
    Left = 24
    Top = 67
    Caption = 'Cliente:'
    Transparent = True
  end
  object btnCliente: TcxButtonEdit [3]
    Left = 160
    Top = 64
    Width = 376
    Properties.Buttons = <
      item
        Default = True
        Kind = bkEllipsis
      end>
    Properties.ReadOnly = True
    Properties.OnButtonClick = btnClientePropertiesButtonClick
    TabOrder = 1
  end
  object lblSerie: TcxLabel [4]
    Left = 24
    Top = 107
    Caption = 'Serie factura:'
    Transparent = True
  end
  object cbbSerie: TcxLookupComboBox [5]
    Left = 160
    Top = 104
    Width = 180
    Properties.DropDownListStyle = lsFixedList
    Properties.KeyFieldNames = 'SERIE_CON'
    Properties.ListColumns = <
      item
        Caption = 'Serie'
        Width = 120
        FieldName = 'SERIE_CON'
      end>
    Properties.ListSource = dsSeries
    TabOrder = 2
  end
  object lblFecha: TcxLabel [6]
    Left = 24
    Top = 147
    Caption = 'Fecha factura:'
    Transparent = True
  end
  object dtFecha: TcxDateEdit [7]
    Left = 160
    Top = 144
    Width = 140
    TabOrder = 3
  end
  object pnlButton: TPanel [8]
    Left = 0
    Top = 241
    Width = 560
    Height = 59
    Align = alBottom
    TabOrder = 4
    object btnCancelar: TcxButton
      Left = 80
      Top = 9
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnGenerar: TcxButton
      Left = 300
      Top = 9
      Width = 177
      Height = 40
      Caption = '&Generar factura'
      Default = True
      TabOrder = 1
      OnClick = btnGenerarClick
    end
  end
  object qrySeries: TUniQuery
    SQL.Strings = (
      'SELECT DISTINCT SERIE_CON, DEFAULT_CON'
      'FROM fza_contadores'
      'WHERE TIPO_DOC_CON = '#39'FC'#39' AND ESACTIVO_CON = '#39'S'#39
      'ORDER BY DEFAULT_CON DESC')
    Left = 376
    Top = 144
  end
  object dsSeries: TDataSource
    DataSet = qrySeries
    Left = 376
    Top = 192
  end
end
