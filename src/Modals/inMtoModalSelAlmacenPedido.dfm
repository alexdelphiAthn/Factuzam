inherited frmModalSelAlmacenPedido: TfrmModalSelAlmacenPedido
  Caption = 'Crear albar'#225'n desde pedido'
  ClientHeight = 600
  ClientWidth = 660
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 676
  ExplicitHeight = 639
  TextHeight = 19
  object pnlButton: TPanel [0]
    Left = 0
    Top = 541
    Width = 660
    Height = 59
    Align = alBottom
    TabOrder = 0
    object btnCancelar: TcxButton
      Left = 60
      Top = 9
      Width = 200
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
    end
    object btnAceptar: TcxButton
      Left = 400
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
    Width = 660
    Height = 541
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblPedido: TLabel
      Left = 16
      Top = 12
      Width = 627
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
      Top = 40
      Caption = 'Almac'#233'n destino (s'#243'lo se reciben las l'#237'neas de este almac'#233'n):'
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 16
      Top = 64
      Properties.DropDownAutoSize = True
      Properties.DropDownListStyle = lsFixedList
      Properties.DropDownSizeable = True
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
      Properties.OnEditValueChanged = cbbAlmacenPropertiesEditValueChanged
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
    object chkIncorporar: TcxCheckBox
      Left = 16
      Top = 96
      Caption = 'Incorporar a un albar'#225'n ya existente de este pedido'
      TabOrder = 5
      OnClick = chkIncorporarClick
    end
    object cxgrdAlbExist: TcxGrid
      Left = 16
      Top = 122
      Width = 628
      Height = 150
      TabOrder = 6
      object tvAlbExist: TcxGridDBTableView
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        object colAlbExistNUMERO: TcxGridDBColumn
          Caption = 'N'#250'mero'
          DataBinding.FieldName = 'NUMERO_ALBC'
          Width = 90
        end
        object colAlbExistSERIE: TcxGridDBColumn
          Caption = 'Serie'
          DataBinding.FieldName = 'SERIE_ALBC'
          Width = 90
        end
        object colAlbExistFECHA: TcxGridDBColumn
          Caption = 'Fecha'
          DataBinding.FieldName = 'FECHA_ALBC'
          Width = 110
        end
        object colAlbExistESTADO: TcxGridDBColumn
          Caption = 'Estado'
          DataBinding.FieldName = 'ESTADO_ALBC'
          Width = 110
        end
        object colAlbExistTOTAL: TcxGridDBColumn
          Caption = 'Total'
          DataBinding.FieldName = 'TOTAL_LIQUIDO_ALBC'
          Width = 120
        end
      end
      object cxgrdlvlAlbExist: TcxGridLevel
        GridView = tvAlbExist
      end
    end
    object lblSerieAlb: TcxLabel
      Left = 16
      Top = 280
      Caption = 'Serie del albar'#225'n'
      Transparent = True
    end
    object cbbSerieAlb: TcxComboBox
      Left = 16
      Top = 304
      Properties.DropDownListStyle = lsEditList
      Properties.MaxLength = 12
      TabOrder = 1
      Width = 180
    end
    object lblRefPrv: TcxLabel
      Left = 216
      Top = 280
      Caption = 'Ref. proveedor'
      Transparent = True
    end
    object txtRefPrv: TcxTextEdit
      Left = 216
      Top = 304
      TabOrder = 2
      Width = 260
    end
    object lblFecha: TcxLabel
      Left = 496
      Top = 280
      Caption = 'Fecha recepci'#243'n'
      Transparent = True
    end
    object dteFecha: TcxDateEdit
      Left = 496
      Top = 304
      TabOrder = 3
      Width = 148
    end
    object lblTemporada: TcxLabel
      Left = 16
      Top = 354
      Caption = 'Temporada'
      Transparent = True
    end
    object cbbTemporada: TcxLookupComboBox
      Left = 16
      Top = 378
      Properties.DropDownAutoSize = True
      Properties.DropDownListStyle = lsFixedList
      Properties.DropDownSizeable = True
      TabOrder = 4
      Width = 460
    end
  end
  object ActionList1: TActionList
    Left = 560
    Top = 16
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
  object unqryTemporadas: TUniQuery
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, PV'
      '  FROM fza_propiedades_valores'
      ' WHERE ID_PROP_PV = '#39'TEMPORADA'#39
      '   AND ESACTIVO_PV = '#39'S'#39
      ' ORDER BY PV')
    Left = 320
    Top = 16
  end
  object dsTemporadas: TDataSource
    DataSet = unqryTemporadas
    Left = 392
    Top = 16
  end
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      ' ORDER BY NOMBRE_ALM_ALM')
    Left = 456
    Top = 16
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 504
    Top = 16
  end
  object unqryAlbExist: TUniQuery
    SQL.Strings = (
      'SELECT NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC,'
      '       TOTAL_LIQUIDO_ALBC'
      '  FROM fza_albaranes_compra'
      ' WHERE NUMERO_PED_ALBC = :np'
      '   AND SERIE_PED_ALBC  = :sp'
      '   AND IFNULL(ESTADO_ALBC, '#39#39') NOT IN ('#39'FACTURADO'#39', '#39'CANCELADO'#39')'
      ' ORDER BY FECHA_ALBC DESC, NUMERO_ALBC DESC')
    Left = 320
    Top = 80
    ParamData = <
      item
        DataType = ftWideString
        Name = 'np'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'sp'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlbExist: TDataSource
    DataSet = unqryAlbExist
    Left = 392
    Top = 80
  end
end
