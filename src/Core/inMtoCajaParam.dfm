object frmMtoCajaParam: TfrmMtoCajaParam
  Left = 0
  Top = 0
  Caption = 'Par'#225'metros de Caja'
  ClientHeight = 653
  ClientWidth = 747
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Lucida Sans'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 18
  object Panel2: TPanel
    Left = 0
    Top = 57
    Width = 747
    Height = 596
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 741
    ExplicitHeight = 587
    object cxVerticalGrid1: TcxVerticalGrid
      Left = 1
      Top = 1
      Width = 745
      Height = 594
      Align = alClient
      OptionsView.RowHeaderWidth = 327
      TabOrder = 0
      ExplicitWidth = 739
      ExplicitHeight = 585
      Version = 1
      object vgerChkExistOnly: TcxEditorRow
        Properties.Caption = 'Permitir s'#243'lo art'#237'culos que existan'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 0
        ParentID = -1
        Index = 0
        Version = 1
      end
      object vgerChkStockOnly: TcxEditorRow
        Properties.Caption = 'Permitir vender sin stock'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.Value = 'True'
        ID = 1
        ParentID = -1
        Index = 1
        Version = 1
      end
      object vgerShowCajaSelection: TcxEditorRow
        Properties.Caption = 'Presentar selecci'#243'n de caja'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.Value = 'True'
        ID = 2
        ParentID = -1
        Index = 2
        Version = 1
      end
      object vgerFillEmpleadoDefecto: TcxEditorRow
        Properties.Caption = 'Rellenar empleado por defecto al abrir'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.Value = 'False'
        ID = 3
        ParentID = -1
        Index = 3
        Version = 1
      end
      object vgerDefTarifa: TcxEditorRow
        Properties.Caption = 'Tarifa por defecto en caja'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = 'PVP'
        ID = 4
        ParentID = -1
        Index = 4
        Version = 1
      end
      object vgerMaxOpPending: TcxEditorRow
        Properties.Caption = 'N'#250'mero de operaciones pendientes'
        Properties.EditPropertiesClassName = 'TcxSpinEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = '5'
        ID = 5
        ParentID = -1
        Index = 5
        Version = 1
      end
      object vgerReqRefDevolucion: TcxEditorRow
        Properties.Caption = 'Pedir referencia en devoluciones'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 6
        ParentID = -1
        Index = 6
        Version = 1
      end
      object vgerRecuperaValePIN: TcxEditorRow
        Properties.Caption = 'Recuperar vale s'#243'lo con PIN'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = False
        ID = 7
        ParentID = -1
        Index = 7
        Version = 1
      end
      object vgerCaducidadDefVale: TcxEditorRow
        Properties.Caption = 'Caducidad por defecto en vale'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = False
        ID = 8
        ParentID = -1
        Index = 8
        Version = 1
      end
      object vgerDiasCaducidadVale: TcxEditorRow
        Properties.Caption = 'D'#237'as hasta caducidad en vale'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.DataBinding.ValueType = 'Integer'
        Properties.Value = 365
        ID = 9
        ParentID = -1
        Index = 9
        Version = 1
      end
      object vgerAvisoStockWarning: TcxEditorRow
        Properties.Caption = 'Aviso en art'#237'culos sin stock'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = 'Art'#237'culo sin Stock. Compruebe Stock en almac'#233'n'
        ID = 10
        ParentID = -1
        Index = 10
        Version = 1
      end
      object vgerDefPrinter: TcxEditorRow
        Properties.Caption = 'Nombre impresora de tickets'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = 'Generic'
        ID = 11
        ParentID = -1
        Index = 11
        Version = 1
      end
      object vgerTipoImpresion: TcxEditorRow
        Properties.Caption = 'Tipo de Impresi'#243'n tickets'
        Properties.EditPropertiesClassName = 'TcxComboBoxProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.EditProperties.Items.Strings = (
          'ESC POS'
          'ESC POS NOQR'
          'EDITOR')
        Properties.Value = 'ESC POS'
        ID = 12
        ParentID = -1
        Index = 12
        Version = 1
      end
      object vgerCodEmpleadoDefecto: TcxEditorRow
        Properties.Caption = 'C'#243'digo de empleado por defecto'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = '1'
        ID = 13
        ParentID = -1
        Index = 13
        Version = 1
      end
      object vgerShowEmpleadoLinea: TcxEditorRow
        Properties.Caption = 'Mostrar empleado en linea de caja'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 14
        ParentID = -1
        Index = 14
        Version = 1
      end
      object vgerMoverLineaIdentif: TcxEditorRow
        Properties.Caption = 'Mover linea al identificar art'#237'culo'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = False
        ID = 15
        ParentID = -1
        Index = 15
        Version = 1
      end
      object vgerBusqArtStockOnly: TcxEditorRow
        Properties.Caption = 'B'#250'squeda de art'#237'culos s'#243'lo con stock'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 16
        ParentID = -1
        Index = 16
        Version = 1
      end
      object vgerBusqArtTarifaOnly: TcxEditorRow
        Properties.Caption = 'B'#250'squeda de art'#237'culos s'#243'lo con tarifa'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 17
        ParentID = -1
        Index = 17
        Version = 1
      end
      object vgerFormatoImpPredet: TcxEditorRow
        Properties.Caption = 'Formato de impresion predeterminado'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = ''
        ID = 18
        ParentID = -1
        Index = 18
        Version = 1
      end
      object vgerArqueoTarjetas: TcxEditorRow
        Properties.Caption = 'Hacer arqueo de todas formas de pago'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = False
        ID = 19
        ParentID = -1
        Index = 19
        Version = 1
      end
      object vgerVentasCredito: TcxEditorRow
        Properties.Caption = 'Permitir ventas a cr'#233'dito'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 20
        ParentID = -1
        Index = 20
        Version = 1
      end
      object vgerDepositos: TcxEditorRow
        Properties.Caption = 'Permitir ventas dep'#243'sitos'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 21
        ParentID = -1
        Index = 21
        Version = 1
      end
      object vgerDescuentos: TcxEditorRow
        Properties.Caption = 'Permitir descuentos a'#241'adidos'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 22
        ParentID = -1
        Index = 22
        Version = 1
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 747
    Height = 57
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 741
    object edtBusqueda: TcxButtonEdit
      Left = 21
      Top = 8
      Properties.Buttons = <
        item
          Default = True
          Glyph.SourceDPI = 96
          Glyph.Data = {
            3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
            462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D224C
            61796572312220786D6C6E733D22687474703A2F2F7777772E77332E6F72672F
            323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F7777
            772E77332E6F72672F313939392F786C696E6B2220783D223070782220793D22
            307078222076696577426F783D2230203020333220333222207374796C653D22
            656E61626C652D6261636B67726F756E643A6E6577203020302033322033323B
            2220786D6C3A73706163653D227072657365727665223E262331333B26233130
            3B20203C7374796C6520747970653D22746578742F6373732220786D6C3A7370
            6163653D227072657365727665223E2E426C61636B262331333B262331303B20
            2020207B262331333B262331303B20202020202066696C6C3A23373237323732
            3B262331333B262331303B202020202020666F6E742D66616D696C793A266170
            6F733B64782D666F6E742D69636F6E732661706F733B3B262331333B26233130
            3B202020202020666F6E742D73697A653A333270783B262331333B262331303B
            202020207D262331333B262331303B20203C2F7374796C653E0D0A3C74657874
            20783D22302220793D2233322220636C6173733D22426C61636B223EEF9E8B3C
            2F746578743E0D0A3C2F7376673E0D0A}
          Kind = bkGlyph
        end>
      Properties.OnButtonClick = cxButtonEdit1PropertiesButtonClick
      TabOrder = 0
      OnKeyDown = edtBusquedaKeyDown
      Width = 292
    end
    object cmbGrupoUsuario: TcxComboBox
      Left = 455
      Top = 15
      Properties.OnChange = cmbGrupoUsuarioPropertiesChange
      TabOrder = 1
      Width = 169
    end
    object btnGuardar: TcxButton
      Left = 319
      Top = 15
      Width = 114
      Height = 26
      Caption = '&Guardar'
      TabOrder = 2
      OnClick = btnGuardarClick
    end
    object btnChangeId: TcxButton
      Left = 689
      Top = 0
      Width = 58
      Height = 57
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.Data = {
        3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
        462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D224C
        61796572312220786D6C6E733D22687474703A2F2F7777772E77332E6F72672F
        323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F7777
        772E77332E6F72672F313939392F786C696E6B2220783D223070782220793D22
        307078222076696577426F783D2230203020333220333222207374796C653D22
        656E61626C652D6261636B67726F756E643A6E6577203020302033322033323B
        2220786D6C3A73706163653D227072657365727665223E262331333B26233130
        3B20203C7374796C6520747970653D22746578742F6373732220786D6C3A7370
        6163653D227072657365727665223E2E426C61636B262331333B262331303B20
        2020207B262331333B262331303B20202020202066696C6C3A23373237323732
        3B262331333B262331303B202020202020666F6E742D66616D696C793A266170
        6F733B64782D666F6E742D69636F6E732661706F733B3B262331333B26233130
        3B202020202020666F6E742D73697A653A333270783B262331333B262331303B
        202020207D262331333B262331303B20203C2F7374796C653E0D0A3C74657874
        20783D22302220793D2233322220636C6173733D22426C61636B223EEEA38F3C
        2F746578743E0D0A3C2F7376673E0D0A}
      TabOrder = 3
      OnClick = btnChangeIdClick
    end
  end
end
