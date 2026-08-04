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
      Caption = 'Serie para todos los documentos de una ubicaci'#243'n'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 6
      Transparent = True
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 46
      Caption = 'Almac'#233'n'
      TabOrder = 7
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 130
      Top = 44
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
      Properties.ListColumns = <
        item
          Caption = 'C'#243'digo'
          Width = 70
          FieldName = 'CODIGO_ALM_ALM'
        end
        item
          Caption = 'Almac'#233'n'
          FieldName = 'NOMBRE_ALM_ALM'
        end>
      Properties.ListOptions.ShowHeader = False
      Properties.ListSource = dsAlmacenes
      Properties.OnEditValueChanged = cbbAlmacenPropertiesEditValueChanged
      TabOrder = 0
      Width = 280
    end
    object lblCaja: TcxLabel
      Left = 16
      Top = 82
      Caption = 'Caja'
      TabOrder = 8
      Transparent = True
    end
    object cbbCaja: TcxLookupComboBox
      Left = 130
      Top = 80
      Properties.KeyFieldNames = 'CODIGO_CAJA_ALMCAJ'
      Properties.ListColumns = <
        item
          Caption = 'C'#243'digo'
          Width = 70
          FieldName = 'CODIGO_CAJA_ALMCAJ'
        end
        item
          Caption = 'Caja'
          FieldName = 'DESCRIPCION_ALMCAJ'
        end>
      Properties.ListOptions.ShowHeader = False
      Properties.ListSource = dsCajas
      TabOrder = 1
      Width = 280
    end
    object lblSerieTokenizada: TcxLabel
      Left = 16
      Top = 118
      Caption = 'Serie tokenizada'
      TabOrder = 9
      Transparent = True
    end
    object txtSerieTokenizada: TcxTextEdit
      Left = 130
      Top = 116
      Properties.MaxLength = 12
      TabOrder = 2
      Width = 180
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
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM'
      '  FROM fza_almacenes'
      ' WHERE CODIGO_EMP_ALM = :EMPRESA'
      '   AND ESACTIVO_ALM = '#39'S'#39
      ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM')
    Left = 48
    Top = 168
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
      end>
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 96
    Top = 168
  end
  object unqryCajas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ'
      '  FROM fza_almacenes_cajas'
      ' WHERE CODIGO_ALM_ALMCAJ = :ALMACEN'
      ' ORDER BY CODIGO_CAJA_ALMCAJ')
    Left = 336
    Top = 168
    ParamData = <
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
      end>
  end
  object dsCajas: TDataSource
    DataSet = unqryCajas
    Left = 384
    Top = 168
  end
end
