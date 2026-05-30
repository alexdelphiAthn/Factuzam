inherited frmMtoComprasSesiones: TfrmMtoComprasSesiones
  Caption = 'Crear art'#237'culos y un pedido o un albar'#225'n'
  ClientHeight = 720
  ClientWidth = 1240
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 1240
  ExplicitHeight = 720
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 1100
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1100
    ExplicitHeight = 720
    inherited pcPantalla: TcxPageControl
      Width = 1100
      Height = 680
      ExplicitWidth = 1100
      ExplicitHeight = 680
      ClientRectBottom = 676
      ClientRectRight = 1096
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 27
        ExplicitWidth = 1096
        ExplicitHeight = 651
        inherited cxGrdPrincipal: TcxGrid
          Width = 1096
          Height = 651
          ExplicitWidth = 1096
          ExplicitHeight = 651
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcSerieSes: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_SES'
              Width = 60
            end
            object dbcNumeroSes: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_SES'
              Width = 80
            end
            object dbcFechaSes: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_SES'
              Width = 100
            end
            object dbcEstadoSes: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_SES'
              Width = 80
            end
            object dbcCodigoEmpSes: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_SES'
              Width = 80
            end
            object dbcCodigoPrvSes: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_SES'
              Width = 100
            end
            object dbcRazonSocialPrvSes: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_SES'
              Width = 200
            end
            object dbcNombrePrvSes: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_PRV_SES'
              Width = 160
            end
            object dbcCodigoTarSes: TcxGridDBColumn
              Caption = 'Tarifa'
              DataBinding.FieldName = 'CODIGO_TAR_SES'
              Width = 90
            end
            object dbcUsuarioAltaSes: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Width = 100
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1092
        ExplicitHeight = 648
        object gbCabecera: TcxGroupBox
          Left = 0
          Top = 0
          Align = alTop
          Caption = ' Cabecera '
          TabOrder = 0
          Height = 224
          Width = 1092
          object lblSerie: TcxLabel
            Left = 12
            Top = 24
            Caption = 'Serie'
            TabOrder = 0
            Transparent = True
          end
          object txtSerie: TcxDBTextEdit
            Left = 80
            Top = 20
            DataBinding.DataField = 'SERIE_SES'
            DataBinding.DataSource = dsTablaG
            Properties.CharCase = ecUpperCase
            Properties.MaxLength = 12
            TabOrder = 1
            Width = 70
          end
          object lblNumero: TcxLabel
            Left = 164
            Top = 24
            Caption = 'N'#250'mero'
            TabOrder = 2
            Transparent = True
          end
          object txtNumero: TcxDBTextEdit
            Left = 232
            Top = 20
            DataBinding.DataField = 'NUMERO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 70
          end
          object lblFecha: TcxLabel
            Left = 316
            Top = 24
            Caption = 'Fecha'
            TabOrder = 4
            Transparent = True
          end
          object dteFecha: TcxDBDateEdit
            Left = 380
            Top = 20
            DataBinding.DataField = 'FECHA_SES'
            DataBinding.DataSource = dsTablaG
            TabOrder = 5
            Width = 120
          end
          object lblEstado: TcxLabel
            Left = 520
            Top = 24
            Caption = 'Estado'
            TabOrder = 18
            Transparent = True
          end
          object txtEstado: TcxDBTextEdit
            Left = 580
            Top = 20
            DataBinding.DataField = 'ESTADO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 19
            Width = 100
          end
          object lblEmpresa: TcxLabel
            Left = 12
            Top = 67
            Caption = 'Empresa'
            TabOrder = 6
            Transparent = True
          end
          object cbbEmpresa: TcxDBLookupComboBox
            Left = 92
            Top = 63
            DataBinding.DataField = 'CODIGO_EMP_SES'
            DataBinding.DataSource = dsTablaG
            Properties.KeyFieldNames = 'CODIGO_EMP_EMP'
            Properties.ListColumns = <
              item
                Caption = 'C'#243'digo'
                Width = 60
                FieldName = 'CODIGO_EMP_EMP'
              end
              item
                Caption = 'Empresa'
                FieldName = 'RAZON_SOCIAL_EMP'
              end>
            Properties.ListOptions.ShowHeader = False
            TabOrder = 7
            Width = 268
          end
          object lblProveedor: TcxLabel
            Left = 380
            Top = 67
            Caption = 'Proveedor'
            TabOrder = 8
            Transparent = True
          end
          object btnProveedor: TcxDBButtonEdit
            Left = 470
            Top = 63
            DataBinding.DataField = 'CODIGO_PRV_SES'
            DataBinding.DataSource = dsTablaG
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.OnButtonClick = btnProveedorPropertiesButtonClick
            TabOrder = 9
            Width = 160
          end
          object lblRefPrv: TcxLabel
            Left = 770
            Top = 67
            Caption = 'Ref. prov.'
            TabOrder = 10
            Transparent = True
          end
          object txtRefPrv: TcxDBTextEdit
            Left = 850
            Top = 63
            DataBinding.DataField = 'REF_PRV_SES'
            DataBinding.DataSource = dsTablaG
            Properties.MaxLength = 100
            TabOrder = 11
            Width = 200
          end
          object lblAlmacen: TcxLabel
            Left = 12
            Top = 111
            Caption = 'Almac'#233'n'
            TabOrder = 20
            Transparent = True
          end
          object cbbAlmacen: TcxDBLookupComboBox
            Left = 92
            Top = 107
            DataBinding.DataField = 'CODIGO_ALM_SES'
            DataBinding.DataSource = dsTablaG
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
            TabOrder = 21
            Width = 200
          end
          object lblTarifa: TcxLabel
            Left = 304
            Top = 111
            Caption = 'Tarifa venta'
            TabOrder = 22
            Transparent = True
          end
          object cbbTarifa: TcxDBLookupComboBox
            Left = 403
            Top = 107
            DataBinding.DataField = 'CODIGO_TAR_SES'
            DataBinding.DataSource = dsTablaG
            Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
            Properties.ListColumns = <
              item
                Caption = 'Tarifa'
                FieldName = 'NOMBRE_TAR_TAR'
              end>
            Properties.ListOptions.ShowHeader = False
            TabOrder = 23
            Width = 186
          end
          object lblTemporada: TcxLabel
            Left = 612
            Top = 111
            Caption = 'Temporada'
            TabOrder = 24
            Transparent = True
          end
          object cbbTemporada: TcxDBLookupComboBox
            Left = 705
            Top = 107
            DataBinding.DataField = 'ID_PV_TEMPORADA_SES'
            DataBinding.DataSource = dsTablaG
            Properties.KeyFieldNames = 'ID_PV_ARTPROP'
            Properties.ListColumns = <
              item
                Caption = 'Temporada'
                FieldName = 'PV'
              end>
            Properties.ListOptions.ShowHeader = False
            TabOrder = 25
            Width = 220
          end
          object chkFormatoDistribuido: TcxDBCheckBox
            Left = 940
            Top = 107
            Caption = 'Formato distribuido (por almac'#233'n)'
            DataBinding.DataField = 'ESFORMATO_DISTRIBUIDO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.ValueChecked = 'S'
            Properties.ValueUnchecked = 'N'
            TabOrder = 26
            Transparent = True
          end
          object lblMargen: TcxLabel
            Left = 12
            Top = 152
            Caption = 'Margen %'
            TabOrder = 12
            Transparent = True
          end
          object spnMargen: TcxDBSpinEdit
            Left = 102
            Top = 150
            DataBinding.DataField = 'PORCENTAJE_MARGEN_SES'
            DataBinding.DataSource = dsTablaG
            Properties.ValueType = vtFloat
            TabOrder = 13
            Width = 92
          end
          object lblMultiploRedondeo: TcxLabel
            Left = 200
            Top = 152
            Caption = 'M'#250'lt. redondeo'
            TabOrder = 14
            Transparent = True
          end
          object spnMultiploRedondeo: TcxDBSpinEdit
            Left = 334
            Top = 149
            DataBinding.DataField = 'MULTIPLO_REDONDEO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.Increment = 0.050000000000000000
            Properties.ValueType = vtFloat
            TabOrder = 15
            Width = 90
          end
          object lblAjusteFinal: TcxLabel
            Left = 430
            Top = 152
            Caption = 'Ajuste final'
            TabOrder = 16
            Transparent = True
          end
          object spnAjusteFinal: TcxDBSpinEdit
            Left = 530
            Top = 150
            DataBinding.DataField = 'AJUSTE_FINAL_SES'
            DataBinding.DataSource = dsTablaG
            Properties.Increment = 0.010000000000000000
            Properties.MaxValue = 10.000000000000000000
            Properties.MinValue = -10.000000000000000000
            Properties.ValueType = vtFloat
            TabOrder = 17
            Width = 90
          end
          object lblProveedorNombre: TcxLabel
            Left = 12
            Top = 192
            AutoSize = False
            TabOrder = 27
            Transparent = True
            Height = 20
            Width = 1060
          end
        end
        object pnlLineasTop: TPanel
          Left = 0
          Top = 224
          Width = 1092
          Height = 36
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAddLinea: TcxButton
            Left = 12
            Top = 4
            Width = 136
            Height = 28
            Caption = '+ A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAddLineaClick
          end
          object btnDelLinea: TcxButton
            Left = 154
            Top = 5
            Width = 137
            Height = 28
            Caption = '- Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnDelLineaClick
          end
          object btnNuevoColor: TcxButton
            Left = 296
            Top = 5
            Width = 170
            Height = 28
            Caption = 'Otro color'
            Colors.Default = 14346982
            Colors.Normal = 14346982
            LookAndFeel.Kind = lfFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 2
            OnClick = btnNuevoColorClick
          end
          object btnFoto: TcxButton
            Left = 472
            Top = 5
            Width = 120
            Height = 28
            Caption = '+ Foto'
            LookAndFeel.Kind = lfFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 3
            OnClick = btnFotoClick
          end
          object btnArbolFamilias: TcxButton
            Left = 600
            Top = 5
            Width = 164
            Height = 28
            Caption = #193'rbol familias (F3)'
            TabOrder = 4
            OnClick = btnArbolFamiliasClick
          end
          object btnDescargarFotos: TcxButton
            Left = 770
            Top = 5
            Width = 120
            Height = 28
            Caption = 'Bajar fotos'
            LookAndFeel.Kind = lfFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 5
            OnClick = btnDescargarFotosClick
          end
          object lblHint: TcxLabel
            Left = 898
            Top = 7
            Caption = 
              'F3 sobre Familia o C'#243'd. art'#237'culo. PVP se propone al teclear el c' +
              'oste.'
            TabOrder = 6
            Transparent = True
          end
        end
        object cxgrdLineas: TcxGrid
          Left = 0
          Top = 260
          Width = 1092
          Height = 388
          Align = alClient
          TabOrder = 2
          OnEnter = cxgrdLineasEnter
          OnExit = cxgrdLineasExit
          ExplicitTop = 236
          ExplicitWidth = 1096
          ExplicitHeight = 415
          object tvLineas: TcxGridDBTableView
            Navigator.Buttons.ConfirmDelete = True
            Navigator.Buttons.PriorPage.Visible = False
            Navigator.Buttons.NextPage.Visible = False
            Navigator.Buttons.Append.Visible = False
            Navigator.Buttons.Edit.Visible = False
            Navigator.Buttons.SaveBookmark.Visible = False
            Navigator.Buttons.GotoBookmark.Visible = False
            Navigator.Buttons.Filter.Visible = False
            Navigator.Visible = True
            OnCustomDrawCell = tvLineasCustomDrawCell
            OnEditing = tvLineasEditing
            OnEditKeyDown = tvLineasEditKeyDown
            OnFocusedRecordChanged = tvLineasFocusedRecordChanged
            OnInitEdit = tvLineasInitEdit
            DataController.Summary.FooterSummaryItems = <
              item
                Format = '#,##0'
                Kind = skSum
                Column = dbcLinTotalTallas
              end>
            OptionsBehavior.FocusCellOnTab = True
            OptionsBehavior.GoToNextCellOnEnter = True
            OptionsData.Appending = True
            OptionsView.Footer = True
            OptionsView.GroupByBox = False
            object dbcLinFamilia: TcxGridDBColumn
              Caption = 'Familia (F3)'
              DataBinding.FieldName = 'CODIGO_FAM_SESLIN'
              PropertiesClassName = 'TcxTextEditProperties'
              Properties.CharCase = ecUpperCase
              Properties.OnEditValueChanged = dbcLinFamiliaPropertiesEditValueChanged
              Width = 110
            end
            object dbcLinCodArt: TcxGridDBColumn
              Caption = 'C'#243'd. art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_SESLIN'
              PropertiesClassName = 'TcxTextEditProperties'
              Properties.CharCase = ecUpperCase
              Properties.OnEditValueChanged = dbcLinCodArtPropertiesEditValueChanged
              Width = 130
            end
            object dbcLinRefPrv: TcxGridDBColumn
              Caption = 'Modelo prov.'
              DataBinding.FieldName = 'REF_PRV_SESLIN'
              PropertiesClassName = 'TcxTextEditProperties'
              Properties.OnEditValueChanged = dbcLinRefPrvPropertiesEditValueChanged
              Width = 130
            end
            object dbcLinDescripcion: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_SESLIN'
              Width = 341
            end
            object dbcLinColor: TcxGridDBColumn
              Caption = 'Color'
              DataBinding.FieldName = 'COLOR_TEXTO_SESLIN'
              Width = 140
            end
            object dbcLinColorBasico: TcxGridDBColumn
              Caption = 'C. b'#225'sico'
              DataBinding.FieldName = 'CODIGO_ATB_COLOR_SESLIN'
              PropertiesClassName = 'TcxButtonEditProperties'
              Properties.Buttons = <
                item
                  Default = True
                  Kind = bkEllipsis
                end>
              Properties.OnButtonClick = dbcLinColorBasicoPropertiesButtonClick
              Width = 110
            end
            object dbcLinPrecioCompra: TcxGridDBColumn
              Caption = 'Pr. compra'
              DataBinding.FieldName = 'PRECIO_COMPRA_SESLIN'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.OnEditValueChanged = dbcLinPrecioCompraPropertiesEditValueChanged
              Width = 136
            end
            object dbcLinPrecioVenta: TcxGridDBColumn
              Caption = 'Pr. venta'
              DataBinding.FieldName = 'PRECIO_VENTA_SESLIN'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 90
            end
            object dbcLinTallas: TcxGridDBColumn
              Caption = 'Sistema tallas'
              DataBinding.FieldName = 'ID_AC_PIVOT_SESLIN'
              PropertiesClassName = 'TcxButtonEditProperties'
              Properties.Buttons = <
                item
                  Default = True
                  Kind = bkEllipsis
                end>
              Properties.OnButtonClick = dbcLinTallasPropertiesButtonClick
              Width = 170
            end
            object dbcLinTotalTallas: TcxGridDBColumn
              Caption = 'Total tallas'
              DataBinding.FieldName = 'TOTAL_UNIDADES_SESLIN'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.Alignment.Horz = taRightJustify
              HeaderAlignmentHorz = taRightJustify
              Options.Editing = False
              Width = 100
            end
            object dbcLinImporteTotal: TcxGridDBColumn
              Caption = 'Importe s/IVA'
              DataBinding.FieldName = 'TOTAL_LINEA_SESLIN'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.Alignment.Horz = taRightJustify
              HeaderAlignmentHorz = taRightJustify
              Options.Editing = False
              Width = 110
            end
            object dbcLinNumero: TcxGridDBColumn
              Caption = 'L'#237'nea'
              DataBinding.FieldName = 'LINEA_SESLIN'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.Increment = 10.000000000000000000
              Properties.MinValue = 1.000000000000000000
              Width = 70
            end
          end
          object glLineas: TcxGridLevel
            GridView = tvLineas
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1092
        ExplicitHeight = 648
        inherited pnlPerfilTop: TPanel
          Width = 1092
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1092
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1092
          Height = 591
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1096
          ExplicitHeight = 594
          inherited cxgrdPerfil: TcxGrid
            Width = 1096
            Height = 594
            ExplicitWidth = 1096
            ExplicitHeight = 594
          end
        end
      end
      object tsDocumentos: TcxTabSheet
        Caption = 'Documentos'
        ImageIndex = 0
        object pnlDocsTop: TPanel
          Left = 0
          Top = 0
          Width = 1092
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object btnIrADoc: TcxButton
            Left = 12
            Top = 6
            Width = 200
            Height = 28
            Caption = 'Ir a documento (F12)'
            LookAndFeel.Kind = lfFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 0
            OnClick = btnIrADocClick
          end
          object lblDocsInfo: TcxLabel
            Left = 224
            Top = 10
            Caption = 
              'Pedidos y albaranes generados al materializar la sesi'#243'n. Doble c' +
              'lick o F12 navega al documento.'
            TabOrder = 1
            Transparent = True
          end
        end
        object cxgrdDocs: TcxGrid
          Left = 0
          Top = 40
          Width = 1092
          Height = 608
          Align = alClient
          TabOrder = 1
          ExplicitWidth = 1096
          ExplicitHeight = 611
          object tvDocs: TcxGridDBTableView
            OnDblClick = tvDocsDblClick
            OptionsCustomize.ColumnHiding = True
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            object dbcDocTipo: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO'
              Width = 80
            end
            object dbcDocSerie: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE'
              Width = 80
            end
            object dbcDocNumero: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO'
              Width = 120
            end
            object dbcDocAlmacen: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'ALMACEN'
              Width = 140
            end
            object dbcDocInstante: TcxGridDBColumn
              Caption = 'Fecha alta'
              DataBinding.FieldName = 'INSTANTE'
              Width = 150
            end
            object dbcDocUsuario: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO'
              Width = 120
            end
          end
          object glDocs: TcxGridLevel
            GridView = tvDocs
          end
        end
      end
      object tsLog: TcxTabSheet
        Caption = 'Log'
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object pnlLogTop: TPanel
          Left = 0
          Top = 0
          Width = 1096
          Height = 36
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object btnLogClear: TcxButton
            Left = 8
            Top = 4
            Width = 110
            Height = 28
            Caption = 'Limpiar log'
            TabOrder = 0
            OnClick = btnLogClearClick
          end
          object btnLogCopy: TcxButton
            Left = 124
            Top = 4
            Width = 110
            Height = 28
            Caption = 'Copiar al portapapeles'
            TabOrder = 1
            OnClick = btnLogCopyClick
          end
        end
        object mLog: TcxMemo
          Left = 0
          Top = 36
          Align = alClient
          Properties.ReadOnly = True
          Properties.ScrollBars = ssVertical
          Properties.WordWrap = False
          TabOrder = 1
          Height = 612
          Width = 1092
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1100
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1100
      inherited pnlTopGrid: TPanel
        Width = 1100
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1100
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1100
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1100
    ExplicitHeight = 720
    inherited pButtonGen: TPanel
      Top = 522
      TabOrder = 4
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 522
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object btnCrear: TcxButton
      Left = 0
      Top = 230
      Width = 137
      Height = 69
      Caption = 'Crear art'#237'culos y albar'#225'n'
      Colors.Default = 9101247
      Colors.Normal = 9101247
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 1
      WordWrap = True
      OnClick = btnCrearClick
    end
    object btnRevertir: TcxButton
      Left = 0
      Top = 308
      Width = 137
      Height = 40
      Caption = 'Revertir materializaci'#243'n'
      Colors.Default = 11337471
      Colors.Normal = 11337471
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 2
      WordWrap = True
      OnClick = btnRevertirClick
    end
    object btnImprimir: TcxButton
      Left = 0
      Top = 358
      Width = 137
      Height = 69
      Caption = 'Imprimir horizontal'
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 3
      WordWrap = True
      OnClick = btnImprimirClick
    end
  end
  object dlgFoto: TOpenDialog
    Filter = 
      'Imagenes (*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp)|*.png;*.jpg;*.' +
      'jpeg;*.webp;*.avif;*.bmp'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 920
    Top = 8
  end
  object alNavegacion: TActionList
    Left = 1000
    Top = 8
    object actIrArticulos: TAction
      Caption = 'Ir a Art'#237'culos'
      ShortCut = 16449
      OnExecute = actIrArticulosExecute
    end
    object actIrAlbaranesCompra: TAction
      Caption = 'Ir a Albaranes de Compra'
      ShortCut = 24641
      OnExecute = actIrAlbaranesCompraExecute
    end
    object actIrPedidosCompra: TAction
      Caption = 'Ir a Pedidos de Compra'
      ShortCut = 24656
      OnExecute = actIrPedidosCompraExecute
    end
  end
end
