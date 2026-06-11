inherited frmMtoComprasSesiones: TfrmMtoComprasSesiones
  Caption = 'Crear art'#237'culos y un pedido o un albar'#225'n'
  ClientHeight = 720
  ClientWidth = 1240
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitTop = 3
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
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1092
        ExplicitHeight = 648
        inherited cxGrdPrincipal: TcxGrid
          Width = 1092
          Height = 648
          ExplicitWidth = 1092
          ExplicitHeight = 648
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
          ExplicitTop = 1
          Height = 217
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
            Properties.ListFieldIndex = 1
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
            Left = 695
            Top = 24
            Caption = 'Ref. prov.'
            TabOrder = 10
            Transparent = True
          end
          object txtRefPrv: TcxDBTextEdit
            Left = 775
            Top = 20
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
            Left = 656
            Top = 153
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
            Left = 639
            Top = 67
            ParentFont = False
            Style.Font.Charset = ANSI_CHARSET
            Style.Font.Color = clWindowText
            Style.Font.Height = -15
            Style.Font.Name = 'Lucida Sans'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            TabOrder = 27
            Transparent = True
          end
        end
        object pnlBottFich: TPanel
          Left = 0
          Top = 225
          Width = 1092
          Height = 423
          Align = alClient
          TabOrder = 1
          ExplicitTop = 209
          ExplicitHeight = 439
          object cxPageControl2: TcxPageControl
            Left = 1
            Top = 1
            Width = 1090
            Height = 421
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = cxTabSheet1
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 437
            ClientRectBottom = 417
            ClientRectLeft = 4
            ClientRectRight = 1086
            ClientRectTop = 28
            object cxTabSheet1: TcxTabSheet
              Caption = '&1_Lineas de Art'#237'culos'
              ImageIndex = 0
              ExplicitHeight = 405
              object cxgrdLineas: TcxGrid
                Left = 0
                Top = 36
                Width = 1082
                Height = 353
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasEnter
                OnExit = cxgrdLineasExit
                ExplicitHeight = 369
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
              object pnlLineasTop: TPanel
                Left = 0
                Top = 0
                Width = 1082
                Height = 36
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddLinea: TcxButton
                  Left = 12
                  Top = 4
                  Width = 112
                  Height = 28
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAddLineaClick
                end
                object btnDelLinea: TcxButton
                  Left = 130
                  Top = 5
                  Width = 112
                  Height = 28
                  Caption = '- Borrar l'#237'nea'
                  TabOrder = 1
                  OnClick = btnDelLineaClick
                end
                object btnNuevoColor: TcxButton
                  Left = 248
                  Top = 5
                  Width = 120
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
                  Left = 374
                  Top = 5
                  Width = 90
                  Height = 28
                  Caption = '+ Foto'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 3
                  OnClick = btnFotoClick
                end
                object btnArbolFamilias: TcxButton
                  Left = 470
                  Top = 5
                  Width = 150
                  Height = 28
                  Caption = #193'rbol familias (F3)'
                  TabOrder = 4
                  OnClick = btnArbolFamiliasClick
                end
                object btnDescargarFotos: TcxButton
                  Left = 626
                  Top = 5
                  Width = 100
                  Height = 28
                  Caption = 'Bajar fotos'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 5
                  OnClick = btnDescargarFotosClick
                end
                object btnAplicarKit: TcxButton
                  Left = 732
                  Top = 5
                  Width = 130
                  Height = 28
                  Caption = 'Aplicar kit'
                  Colors.Default = 12579775
                  Colors.Normal = 12579775
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 6
                  OnClick = btnAplicarKitClick
                end
                object lblHint: TcxLabel
                  Left = 870
                  Top = 7
                  Caption = 'F3 = familias. PVP se propone al teclear el coste.'
                  TabOrder = 7
                  Transparent = True
                end
              end
            end
            object tsDocumentos: TcxTabSheet
              Caption = '&2_Documentos creados'
              ImageIndex = 1
              ExplicitHeight = 405
              object pnlDocsTop: TPanel
                Left = 0
                Top = 0
                Width = 1082
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
                Width = 1082
                Height = 349
                Align = alClient
                TabOrder = 1
                ExplicitHeight = 365
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
            object tsProveedor: TcxTabSheet
              Caption = '&3_Proveedor'
              ImageIndex = 2
              object pnlProvIzq: TPanel
                Left = 0
                Top = 0
                Width = 560
                Height = 389
                Align = alLeft
                BevelOuter = bvNone
                TabOrder = 0
                object gbProvFicha: TcxGroupBox
                  Left = 0
                  Top = 0
                  Align = alClient
                  Caption = ' Datos del proveedor '
                  TabOrder = 0
                  Height = 389
                  Width = 560
                  object lblProvCodigo: TcxLabel
                    Left = 12
                    Top = 28
                    Caption = 'C'#243'digo'
                    TabOrder = 0
                    Transparent = True
                  end
                  object txtProvCodigo: TcxDBTextEdit
                    Left = 110
                    Top = 24
                    DataBinding.DataField = 'CODIGO_PRV_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 1
                    Width = 120
                  end
                  object lblProvNif: TcxLabel
                    Left = 292
                    Top = 28
                    Caption = 'NIF'
                    TabOrder = 2
                    Transparent = True
                  end
                  object txtProvNif: TcxDBTextEdit
                    Left = 392
                    Top = 24
                    DataBinding.DataField = 'NIF_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 3
                    Width = 152
                  end
                  object lblProvRazon: TcxLabel
                    Left = 12
                    Top = 56
                    Caption = 'Raz'#243'n social'
                    TabOrder = 4
                    Transparent = True
                  end
                  object txtProvRazon: TcxDBTextEdit
                    Left = 110
                    Top = 52
                    DataBinding.DataField = 'RAZON_SOCIAL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 5
                    Width = 434
                  end
                  object lblProvNombre: TcxLabel
                    Left = 12
                    Top = 84
                    Caption = 'Nombre com.'
                    TabOrder = 6
                    Transparent = True
                  end
                  object txtProvNombre: TcxDBTextEdit
                    Left = 110
                    Top = 80
                    DataBinding.DataField = 'NOMBRE_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 7
                    Width = 434
                  end
                  object lblProvTelefono: TcxLabel
                    Left = 12
                    Top = 112
                    Caption = 'Tel'#233'fono'
                    TabOrder = 8
                    Transparent = True
                  end
                  object txtProvTelefono: TcxDBTextEdit
                    Left = 110
                    Top = 108
                    DataBinding.DataField = 'TELEFONO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 9
                    Width = 168
                  end
                  object lblProvMovil: TcxLabel
                    Left = 292
                    Top = 112
                    Caption = 'M'#243'vil'
                    TabOrder = 10
                    Transparent = True
                  end
                  object txtProvMovil: TcxDBTextEdit
                    Left = 392
                    Top = 108
                    DataBinding.DataField = 'MOVIL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 11
                    Width = 152
                  end
                  object lblProvEmail: TcxLabel
                    Left = 12
                    Top = 140
                    Caption = 'Email'
                    TabOrder = 12
                    Transparent = True
                  end
                  object txtProvEmail: TcxDBTextEdit
                    Left = 110
                    Top = 136
                    DataBinding.DataField = 'EMAIL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 13
                    Width = 434
                  end
                  object lblProvDireccion: TcxLabel
                    Left = 12
                    Top = 168
                    Caption = 'Direcci'#243'n'
                    TabOrder = 14
                    Transparent = True
                  end
                  object txtProvDireccion: TcxDBTextEdit
                    Left = 110
                    Top = 164
                    DataBinding.DataField = 'DIRECCION1_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 15
                    Width = 434
                  end
                  object lblProvPoblacion: TcxLabel
                    Left = 12
                    Top = 196
                    Caption = 'Poblaci'#243'n'
                    TabOrder = 16
                    Transparent = True
                  end
                  object txtProvPoblacion: TcxDBTextEdit
                    Left = 110
                    Top = 192
                    DataBinding.DataField = 'POBLACION_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 17
                    Width = 168
                  end
                  object lblProvProvincia: TcxLabel
                    Left = 292
                    Top = 196
                    Caption = 'Provincia'
                    TabOrder = 18
                    Transparent = True
                  end
                  object txtProvProvincia: TcxDBTextEdit
                    Left = 392
                    Top = 192
                    DataBinding.DataField = 'PROVINCIA_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 19
                    Width = 152
                  end
                  object lblProvCPostal: TcxLabel
                    Left = 12
                    Top = 224
                    Caption = 'C. Postal'
                    TabOrder = 20
                    Transparent = True
                  end
                  object txtProvCPostal: TcxDBTextEdit
                    Left = 110
                    Top = 220
                    DataBinding.DataField = 'CODIGO_POSTAL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 21
                    Width = 168
                  end
                  object lblProvPais: TcxLabel
                    Left = 292
                    Top = 224
                    Caption = 'Pa'#237's'
                    TabOrder = 22
                    Transparent = True
                  end
                  object txtProvPais: TcxDBTextEdit
                    Left = 392
                    Top = 220
                    DataBinding.DataField = 'PAIS_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 23
                    Width = 152
                  end
                  object lblProvContacto: TcxLabel
                    Left = 12
                    Top = 252
                    Caption = 'Contacto'
                    TabOrder = 24
                    Transparent = True
                  end
                  object txtProvContacto: TcxDBTextEdit
                    Left = 110
                    Top = 248
                    DataBinding.DataField = 'CONTACTO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 25
                    Width = 168
                  end
                  object lblProvTelContacto: TcxLabel
                    Left = 292
                    Top = 252
                    Caption = 'Tel. contacto'
                    TabOrder = 26
                    Transparent = True
                  end
                  object txtProvTelContacto: TcxDBTextEdit
                    Left = 392
                    Top = 248
                    DataBinding.DataField = 'TELEFONO_CONTACTO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 27
                    Width = 152
                  end
                  object lblProvMargen: TcxLabel
                    Left = 12
                    Top = 284
                    Caption = 'Margen %'
                    TabOrder = 28
                    Transparent = True
                  end
                  object txtProvMargen: TcxDBTextEdit
                    Left = 110
                    Top = 280
                    DataBinding.DataField = 'PORCENTAJE_MARGEN_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 29
                    Width = 90
                  end
                  object lblProvTallas: TcxLabel
                    Left = 292
                    Top = 284
                    Caption = 'Sistema tallas'
                    TabOrder = 30
                    Transparent = True
                  end
                  object txtProvTallas: TcxDBTextEdit
                    Left = 392
                    Top = 280
                    DataBinding.DataField = 'NOMBRE_TALLAS_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 31
                    Width = 152
                  end
                  object btnIrProveedor: TcxButton
                    Left = 110
                    Top = 316
                    Width = 200
                    Height = 28
                    Caption = 'Ir a proveedor (ficha)'
                    LookAndFeel.Kind = lfFlat
                    LookAndFeel.NativeStyle = False
                    TabOrder = 32
                    OnClick = btnIrProveedorClick
                  end
                end
              end
              object gbProvKits: TcxGroupBox
                Left = 560
                Top = 0
                Align = alClient
                Caption = ' Kits de cantidades por talla '
                TabOrder = 1
                Height = 389
                Width = 522
                object pnlProvKitsTop: TPanel
                  Left = 2
                  Top = 18
                  Width = 518
                  Height = 36
                  Align = alTop
                  BevelOuter = bvNone
                  TabOrder = 0
                  object btnAplicarKitProv: TcxButton
                    Left = 8
                    Top = 4
                    Width = 230
                    Height = 28
                    Caption = 'Aplicar kit a la l'#237'nea actual'
                    Colors.Default = 12579775
                    Colors.Normal = 12579775
                    LookAndFeel.Kind = lfFlat
                    LookAndFeel.NativeStyle = False
                    TabOrder = 0
                    OnClick = btnAplicarKitProvClick
                  end
                  object lblProvKitsHint: TcxLabel
                    Left = 246
                    Top = 9
                    Caption = 'Doble click tambi'#233'n aplica. Se definen en Proveedores.'
                    TabOrder = 1
                    Transparent = True
                  end
                end
                object cxgrdPrvKits: TcxGrid
                  Left = 2
                  Top = 54
                  Width = 308
                  Height = 333
                  Align = alClient
                  TabOrder = 1
                  object tvPrvKits: TcxGridDBTableView
                    OnDblClick = tvPrvKitsDblClick
                    Navigator.Visible = False
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object dbcPrvKitCodigo: TcxGridDBColumn
                      Caption = 'Kit'
                      DataBinding.FieldName = 'CODIGO_PRVKIT'
                      Width = 90
                    end
                    object dbcPrvKitNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_PRVKIT'
                      Width = 130
                    end
                    object dbcPrvKitSistema: TcxGridDBColumn
                      Caption = 'Sistema tallas'
                      DataBinding.FieldName = 'NOMBRE_TALLAS_PRVKIT'
                      Width = 120
                    end
                    object dbcPrvKitDescripcion: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_PRVKIT'
                      Width = 140
                    end
                  end
                  object glPrvKits: TcxGridLevel
                    GridView = tvPrvKits
                  end
                end
                object cxgrdPrvKitsDet: TcxGrid
                  Left = 310
                  Top = 54
                  Width = 210
                  Height = 333
                  Align = alRight
                  TabOrder = 2
                  object tvPrvKitsDet: TcxGridDBTableView
                    Navigator.Visible = False
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object dbcPrvKitDetValor: TcxGridDBColumn
                      Caption = 'Talla'
                      DataBinding.FieldName = 'VALOR_DESTINO_PRVKITD'
                      Width = 80
                    end
                    object dbcPrvKitDetCantidad: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_PRVKITD'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.##'
                      Width = 80
                    end
                  end
                  object glPrvKitsDet: TcxGridLevel
                    GridView = tvPrvKitsDet
                  end
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 217
          Width = 1092
          Height = 8
          Cursor = crSizeNS
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          ExplicitLeft = 17
          ExplicitTop = 232
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
          ExplicitWidth = 1092
          ExplicitHeight = 591
          inherited cxgrdPerfil: TcxGrid
            Width = 1092
            Height = 591
            ExplicitWidth = 1092
            ExplicitHeight = 591
          end
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
  object dsPrvFicha: TDataSource
    Left = 1040
    Top = 8
  end
end
