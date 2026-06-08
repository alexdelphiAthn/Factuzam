inherited frmModalSelAlmacenAlbaran: TfrmModalSelAlmacenAlbaran
  Caption = 'Crear albar'#225'n desde pedido'
  ClientHeight = 200
  ClientWidth = 560
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 576
  ExplicitHeight = 239
  TextHeight = 19
  object pnlButton: TPanel [0]
    Left = 0
    Top = 141
    Width = 560
    Height = 59
    Align = alBottom
    TabOrder = 0
    object btnCancelar: TcxButton
      Left = 40
      Top = 9
      Width = 200
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      ModalResult = 2
      TabOrder = 0
    end
    object btnAceptar: TcxButton
      Left = 320
      Top = 9
      Width = 200
      Height = 40
      Caption = '&Aceptar (F12)'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 0
    Width = 560
    Height = 141
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblPedido: TLabel
      Left = 16
      Top = 12
      Width = 528
      Height = 19
      AutoSize = False
      Caption = 'lblPedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 48
      Caption = 'Almac'#233'n del albar'#225'n:'
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 16
      Top = 74
      Properties.DropDownAutoSize = True
      Properties.DropDownListStyle = lsFixedList
      Properties.DropDownSizeable = True
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
      Properties.ListColumns = <
        item
          Caption = 'C'#243'digo'
          Width = 100
          FieldName = 'CODIGO_ALM_ALM'
        end
        item
          Caption = 'Almac'#233'n'
          Width = 320
          FieldName = 'NOMBRE_ALM_ALM'
        end>
      TabOrder = 0
      Width = 460
    end
  end
  object ActionList1: TActionList
    Left = 456
    Top = 16
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
  end
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      ' ORDER BY NOMBRE_ALM_ALM')
    Left = 360
    Top = 16
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 408
    Top = 16
  end
end
