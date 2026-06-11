inherited frmModalCrearAlbaranSesion: TfrmModalCrearAlbaranSesion
  Caption = 'Crear art'#237'culos y albar'#225'n / pedido'
  ClientHeight = 560
  ClientWidth = 580
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 580
  ExplicitHeight = 440
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 580
    Height = 500
    Align = alClient
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Confirma los datos del documento a generar:'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object chkGenAlbaran: TcxCheckBox
      Left = 16
      Top = 50
      Caption = 'Generar albar'#225'n (mueve stock)'
      Properties.OnEditValueChanged = chkGenAlbaranPropertiesEditValueChanged
      Properties.ValueChecked = True
      Properties.ValueUnchecked = False
      State = cbsChecked
      TabOrder = 0
      Transparent = True
      Width = 280
    end
    object lblSerieAlb: TcxLabel
      Left = 310
      Top = 52
      Caption = 'Serie albar'#225'n'
      Transparent = True
    end
    object cbbSerieAlb: TcxComboBox
      Left = 430
      Top = 50
      Properties.CharCase = ecUpperCase
      Properties.DropDownListStyle = lsEditList
      Properties.MaxLength = 12
      TabOrder = 1
      Width = 120
    end
    object chkGenPedido: TcxCheckBox
      Left = 16
      Top = 90
      Caption = 'Generar pedido (pdte. de recibir)'
      Properties.OnEditValueChanged = chkGenPedidoPropertiesEditValueChanged
      Properties.ValueChecked = True
      Properties.ValueUnchecked = False
      TabOrder = 2
      Transparent = True
      Width = 280
    end
    object lblSeriePed: TcxLabel
      Left = 310
      Top = 92
      Caption = 'Serie pedido'
      Transparent = True
    end
    object cbbSeriePed: TcxComboBox
      Left = 430
      Top = 90
      Enabled = False
      Properties.CharCase = ecUpperCase
      Properties.DropDownListStyle = lsEditList
      Properties.MaxLength = 12
      TabOrder = 3
      Width = 120
    end
    object lblFecha: TcxLabel
      Left = 16
      Top = 140
      Caption = 'Fecha'
      Transparent = True
    end
    object dteFecha: TcxDateEdit
      Left = 160
      Top = 138
      TabOrder = 4
      Width = 130
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 180
      Caption = 'Almac'#233'n destino'
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 160
      Top = 178
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
      Properties.OnEditValueChanged = cbbAlmacenPropertiesEditValueChanged
      Properties.ListColumns = <
        item
          Caption = 'C'#243'digo'
          Width = 60
          FieldName = 'CODIGO_ALM_ALM'
        end
        item
          Caption = 'Almac'#233'n'
          FieldName = 'NOMBRE_ALM_ALM'
        end>
      Properties.ListOptions.ShowHeader = False
      TabOrder = 5
      Width = 390
    end
    object lblTarifa: TcxLabel
      Left = 16
      Top = 220
      Caption = 'Tarifa venta'
      Transparent = True
    end
    object cbbTarifa: TcxLookupComboBox
      Left = 160
      Top = 218
      Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
      Properties.ListColumns = <
        item
          Caption = 'Tarifa'
          FieldName = 'NOMBRE_TAR_TAR'
        end>
      Properties.ListOptions.ShowHeader = False
      TabOrder = 6
      Width = 390
    end
    object lblTemporada: TcxLabel
      Left = 16
      Top = 260
      Caption = 'Temporada'
      Transparent = True
    end
    object cbbTemporada: TcxLookupComboBox
      Left = 160
      Top = 258
      Properties.KeyFieldNames = 'ID_PV_ARTPROP'
      Properties.ListColumns = <
        item
          Caption = 'Temporada'
          FieldName = 'PV'
        end>
      Properties.ListOptions.ShowHeader = False
      TabOrder = 7
      Width = 390
    end
    object lblRefPrv: TcxLabel
      Left = 16
      Top = 300
      Caption = 'Ref. documento proveedor'
      Transparent = True
    end
    object txtRefPrv: TcxTextEdit
      Left = 160
      Top = 298
      Properties.MaxLength = 100
      TabOrder = 8
      Width = 390
    end
    object rgAgrupacion: TcxRadioGroup
      Left = 16
      Top = 332
      Caption = ' Agrupaci'#243'n almac'#233'n (formato distribuido) '
      Properties.Items = <
        item
          Caption = 'Agrupar todos los almacenes en un solo documento'
        end
        item
          Caption = 'Generar un documento por almac'#233'n (con la serie de su almac'#233'n)'
        end>
      ItemIndex = 0
      TabOrder = 9
      Height = 80
      Visible = False
      Width = 534
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 500
    Width = 580
    Height = 60
    Align = alBottom
    TabOrder = 1
    object btnSalir: TcxButton
      Left = 40
      Top = 12
      Width = 170
      Height = 38
      Cancel = True
      Caption = '&Salir'
      TabOrder = 0
      OnClick = btnSalirClick
    end
    object btnGenerar: TcxButton
      Left = 370
      Top = 12
      Width = 170
      Height = 38
      Caption = '&Generar'
      Default = True
      TabOrder = 1
      OnClick = btnGenerarClick
    end
  end
end
