inherited frmMtoComprasSesiones: TfrmMtoComprasSesiones
  Caption = 'Crear art'#237'culos y un pedido o un albar'#225'n'
  ClientHeight = 720
  ClientWidth = 1240
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 1240
  ExplicitHeight = 720
  TextHeight = 19
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
      ClientRectBottom = 678
      ClientRectRight = 1098
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1096
        ExplicitHeight = 649
        inherited cxGrdPrincipal: TcxGrid
          Width = 1096
          Height = 649
          ExplicitWidth = 1096
          ExplicitHeight = 649
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
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1096
        ExplicitHeight = 649
        object gbCabecera: TcxGroupBox
          Left = 0
          Top = 0
          Align = alTop
          Caption = ' Cabecera '
          TabOrder = 0
          Height = 200
          Width = 1096
          object lblSerie: TcxLabel
            Left = 12
            Top = 24
            Caption = 'Serie'
            TabOrder = 0
          end
          object txtSerie: TcxDBTextEdit
            Left = 80
            Top = 22
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
          end
          object txtNumero: TcxDBTextEdit
            Left = 232
            Top = 22
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
          end
          object dteFecha: TcxDBDateEdit
            Left = 380
            Top = 22
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
          end
          object txtEstado: TcxDBTextEdit
            Left = 580
            Top = 22
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
          end
          object cbbEmpresa: TcxDBLookupComboBox
            Left = 92
            Top = 65
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
          end
          object cbbProveedor: TcxDBLookupComboBox
            Left = 470
            Top = 65
            DataBinding.DataField = 'CODIGO_PRV_SES'
            DataBinding.DataSource = dsTablaG
            Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
            Properties.ListColumns = <
              item
                Caption = 'C'#243'digo'
                Width = 60
                FieldName = 'CODIGO_PRV_PRV'
              end
              item
                Caption = 'Proveedor'
                FieldName = 'RAZON_SOCIAL_PRV'
              end>
            Properties.ListOptions.ShowHeader = False
            TabOrder = 9
            Width = 280
          end
          object lblRefPrv: TcxLabel
            Left = 770
            Top = 67
            Caption = 'Ref. prov.'
            TabOrder = 10
          end
          object txtRefPrv: TcxDBTextEdit
            Left = 850
            Top = 65
            DataBinding.DataField = 'REF_PRV_SES'
            DataBinding.DataSource = dsTablaG
            Properties.MaxLength = 100
            TabOrder = 11
            Width = 200
          end
          object lblAlmacen: TcxLabel
            Left = 12
            Top = 109
            Caption = 'Almac'#233'n'
            TabOrder = 20
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
            Top = 109
            Caption = 'Tarifa venta'
            TabOrder = 22
          end
          object cbbTarifa: TcxDBLookupComboBox
            Left = 392
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
            Width = 200
          end
          object lblTemporada: TcxLabel
            Left = 612
            Top = 109
            Caption = 'Temporada'
            TabOrder = 24
          end
          object cbbTemporada: TcxDBLookupComboBox
            Left = 700
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
          object lblMargen: TcxLabel
            Left = 12
            Top = 152
            Caption = 'Margen %'
            TabOrder = 12
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
        end
        object pnlLineasTop: TPanel
          Left = 0
          Top = 200
          Width = 1096
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
            Caption = 'Otro color (mismo art'#237'culo)'
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
            Width = 150
            Height = 28
            Caption = #193'rbol familias (F3)'
            TabOrder = 4
            OnClick = btnArbolFamiliasClick
          end
          object lblHint: TcxLabel
            Left = 760
            Top = 7
            Caption = 
              'F3 sobre Familia o C'#243'd. art'#237'culo. PVP se propone al teclear el c' +
              'oste.'
            TabOrder = 5
          end
        end
        object cxgrdLineas: TcxGrid
          Left = 0
          Top = 236
          Width = 1096
          Height = 413
          Align = alClient
          TabOrder = 2
          OnEnter = cxgrdLineasEnter
          OnExit = cxgrdLineasExit
          object tvLineas: TcxGridDBTableView
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
            OptionsBehavior.FocusFirstCellOnNewRecord = True
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
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.DropDownWidth = 380
              Properties.ImmediatePost = True
              Properties.KeyFieldNames = 'ID_AC'
              Properties.ListColumns = <
                item
                  Caption = 'Sistema'
                  Width = 240
                  FieldName = 'NOMBRE_AC'
                end
                item
                  Caption = 'Desde'
                  Width = 60
                  FieldName = 'PRIMERA'
                end
                item
                  Caption = 'Hasta'
                  Width = 60
                  FieldName = 'ULTIMA'
                end>
              Properties.OnEditValueChanged = dbcLinTallasPropertiesEditValueChanged
              Width = 170
            end
            object dbcLinTalla01: TcxGridDBColumn
              Caption = ''
              Tag = 1
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla02: TcxGridDBColumn
              Caption = ''
              Tag = 2
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla03: TcxGridDBColumn
              Caption = ''
              Tag = 3
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla04: TcxGridDBColumn
              Caption = ''
              Tag = 4
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla05: TcxGridDBColumn
              Caption = ''
              Tag = 5
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla06: TcxGridDBColumn
              Caption = ''
              Tag = 6
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla07: TcxGridDBColumn
              Caption = ''
              Tag = 7
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla08: TcxGridDBColumn
              Caption = ''
              Tag = 8
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla09: TcxGridDBColumn
              Caption = ''
              Tag = 9
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla10: TcxGridDBColumn
              Caption = ''
              Tag = 10
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla11: TcxGridDBColumn
              Caption = ''
              Tag = 11
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla12: TcxGridDBColumn
              Caption = ''
              Tag = 12
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla13: TcxGridDBColumn
              Caption = ''
              Tag = 13
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla14: TcxGridDBColumn
              Caption = ''
              Tag = 14
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla15: TcxGridDBColumn
              Caption = ''
              Tag = 15
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla16: TcxGridDBColumn
              Caption = ''
              Tag = 16
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla17: TcxGridDBColumn
              Caption = ''
              Tag = 17
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla18: TcxGridDBColumn
              Caption = ''
              Tag = 18
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla19: TcxGridDBColumn
              Caption = ''
              Tag = 19
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTalla20: TcxGridDBColumn
              Caption = ''
              Tag = 20
              Visible = True
              Width = 50
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0'
            end
            object dbcLinTotalTallas: TcxGridDBColumn
              Caption = 'Total tallas'
              DataBinding.FieldName = 'TOTAL_UNIDADES_SESLIN'
              PropertiesClassName = 'TcxSpinEditProperties'
              Options.Editing = False
              Width = 100
            end
            object dbcLinImporteTotal: TcxGridDBColumn
              Caption = 'Importe s/IVA'
              DataBinding.FieldName = 'TOTAL_LINEA_SESLIN'
              PropertiesClassName = 'TcxCurrencyEditProperties'
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
        ExplicitWidth = 1096
        ExplicitHeight = 649
        inherited pnlPerfilTop: TPanel
          Width = 1096
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1096
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1096
          Height = 592
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1096
          ExplicitHeight = 592
          inherited cxgrdPerfil: TcxGrid
            Width = 1096
            Height = 592
            ExplicitWidth = 1096
            ExplicitHeight = 592
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
          Height = 613
          Width = 1096
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
          ExplicitHeight = 27
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
    Options = [ofHideReadOnly, ofPathMustExist,# changed Visible: 20
 ofFileMustExist, ofEnableSizing]
    Left = 920
    Top = 8
  end
end
