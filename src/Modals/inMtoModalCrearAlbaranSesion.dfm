inherited frmModalCrearAlbaranSesion: TfrmModalCrearAlbaranSesion
  Caption = 'Crear art'#237'culos y albar'#225'n'
  ClientHeight = 420
  ClientWidth = 560
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 560
  ExplicitHeight = 420
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 560
    Height = 360
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
    object lblSerie: TcxLabel
      Left = 16
      Top = 56
      Caption = 'Serie albar'#225'n'
      Transparent = True
    end
    object txtSerie: TcxTextEdit
      Left = 160
      Top = 54
      Properties.CharCase = ecUpperCase
      Properties.MaxLength = 12
      TabOrder = 0
      Width = 100
    end
    object lblFecha: TcxLabel
      Left = 290
      Top = 56
      Caption = 'Fecha'
      Transparent = True
    end
    object dteFecha: TcxDateEdit
      Left = 360
      Top = 54
      TabOrder = 1
      Width = 130
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 100
      Caption = 'Almac'#233'n destino'
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 160
      Top = 98
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
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
      TabOrder = 2
      Width = 330
    end
    object lblTarifa: TcxLabel
      Left = 16
      Top = 144
      Caption = 'Tarifa venta'
      Transparent = True
    end
    object cbbTarifa: TcxLookupComboBox
      Left = 160
      Top = 142
      Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
      Properties.ListColumns = <
        item
          Caption = 'Tarifa'
          FieldName = 'NOMBRE_TAR_TAR'
        end>
      Properties.ListOptions.ShowHeader = False
      TabOrder = 3
      Width = 330
    end
    object lblTemporada: TcxLabel
      Left = 16
      Top = 188
      Caption = 'Temporada'
      Transparent = True
    end
    object cbbTemporada: TcxLookupComboBox
      Left = 160
      Top = 186
      Properties.KeyFieldNames = 'ID_PV_ARTPROP'
      Properties.ListColumns = <
        item
          Caption = 'Temporada'
          FieldName = 'PV'
        end>
      Properties.ListOptions.ShowHeader = False
      TabOrder = 4
      Width = 330
    end
    object chkGenAlbaran: TcxCheckBox
      Left = 160
      Top = 234
      Caption = 'Generar albar'#225'n de compra (mueve stock)'
      Properties.ValueChecked = True
      Properties.ValueUnchecked = False
      State = cbsChecked
      TabOrder = 5
      Transparent = True
      Width = 360
    end
    object chkGenPedido: TcxCheckBox
      Left = 160
      Top = 270
      Caption = 'Generar pedido de compra'
      Properties.ValueChecked = True
      Properties.ValueUnchecked = False
      TabOrder = 6
      Transparent = True
      Width = 360
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 360
    Width = 560
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
      Left = 350
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
