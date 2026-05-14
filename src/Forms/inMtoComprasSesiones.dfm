inherited frmMtoComprasSesiones: TfrmMtoComprasSesiones
  Caption = 'Sesiones de Compra (Pre-pedidos / Pre-albaranes)'
  ClientHeight = 768
  ClientWidth = 1180
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 1180
  ExplicitHeight = 768
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 1040
    Height = 768
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1040
    ExplicitHeight = 768
    inherited pcPantalla: TcxPageControl
      Width = 1040
      Height = 728
      ExplicitWidth = 1040
      ExplicitHeight = 728
      ClientRectBottom = 726
      ClientRectRight = 1038
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1036
        ExplicitHeight = 697
        inherited cxGrdPrincipal: TcxGrid
          Width = 1036
          Height = 697
          ExplicitWidth = 1036
          ExplicitHeight = 697
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
              Width = 90
            end
            object dbcCodigoPrvSes: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_SES'
              Width = 100
            end
            object dbcRefPrvSes: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PRV_SES'
              Width = 140
            end
            object dbcCodigoFamSes: TcxGridDBColumn
              Caption = 'Familia'
              DataBinding.FieldName = 'CODIGO_FAM_SES'
              Width = 110
            end
            object dbcTotalCompraSes: TcxGridDBColumn
              Caption = 'Total compra'
              DataBinding.FieldName = 'TOTAL_COMPRA_SES'
              Width = 120
            end
            object dbcUsuarioAltaSes: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Width = 100
            end
            object dbcInstanteAltaSes: TcxGridDBColumn
              Caption = 'Instante alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Width = 140
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1036
        ExplicitHeight = 697
        object pcSesion: TcxPageControl
          Left = 0
          Top = 72
          Width = 1036
          Height = 625
          Align = alClient
          TabOrder = 0
          Properties.ActivePage = tsLog
          Properties.CustomButtons.Buttons = <>
          ClientRectBottom = 623
          ClientRectLeft = 2
          ClientRectRight = 1034
          ClientRectTop = 29
          object tsCabecera: TcxTabSheet
            Caption = '&1. Cabecera '
            ImageIndex = 0
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            object gbDatosGen: TcxGroupBox
              Left = 8
              Top = 8
              Caption = ' Datos generales '
              TabOrder = 0
              Height = 225
              Width = 1004
              object lblSerie: TcxLabel
                Left = 16
                Top = 24
                Caption = 'Serie'
                TabOrder = 10
              end
              object cbbSerie: TcxDBComboBox
                Left = 80
                Top = 22
                DataBinding.DataField = 'SERIE_SES'
                DataBinding.DataSource = dsTablaG
                Properties.CharCase = ecUpperCase
                Properties.MaxLength = 12
                TabOrder = 0
                Width = 160
              end
              object lblNumero: TcxLabel
                Left = 256
                Top = 24
                Caption = 'N'#250'mero'
                TabOrder = 11
              end
              object txtNumero: TcxDBTextEdit
                Left = 326
                Top = 22
                DataBinding.DataField = 'NUMERO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblFecha: TcxLabel
                Left = 446
                Top = 24
                Caption = 'Fecha'
                TabOrder = 12
              end
              object dteFecha: TcxDBDateEdit
                Left = 506
                Top = 22
                DataBinding.DataField = 'FECHA_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 120
              end
              object lblEstado: TcxLabel
                Left = 646
                Top = 24
                Caption = 'Estado'
                TabOrder = 13
              end
              object txtEstado: TcxDBTextEdit
                Left = 706
                Top = 22
                DataBinding.DataField = 'ESTADO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 100
              end
              object lblEmpresa: TcxLabel
                Left = 29
                Top = 60
                Caption = 'Empresa'
                TabOrder = 14
              end
              object cbbEmpresa: TcxDBLookupComboBox
                Left = 125
                Top = 58
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
                Properties.OnEditValueChanged = cbbEmpresaPropertiesEditValueChanged
                TabOrder = 4
                Width = 275
              end
              object lblProveedor: TcxLabel
                Left = 16
                Top = 96
                Caption = 'Proveedor'
                TabOrder = 15
              end
              object cbbProveedor: TcxDBLookupComboBox
                Left = 124
                Top = 94
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
                TabOrder = 5
                Width = 276
              end
              object lblRefPrv: TcxLabel
                Left = 420
                Top = 96
                Caption = 'Ref. proveedor'
                TabOrder = 16
              end
              object txtRefPrv: TcxDBTextEdit
                Left = 566
                Top = 94
                DataBinding.DataField = 'REF_PRV_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 6
                Width = 240
              end
              object lblAlmacen: TcxLabel
                Left = 16
                Top = 132
                Caption = 'Almac'#233'n destino'
                TabOrder = 17
              end
              object cbbAlmacen: TcxDBLookupComboBox
                Left = 165
                Top = 130
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
                TabOrder = 7
                Width = 175
              end
              object lblMoneda: TcxLabel
                Left = 360
                Top = 132
                Caption = 'Moneda'
                TabOrder = 18
              end
              object txtMoneda: TcxDBTextEdit
                Left = 434
                Top = 130
                DataBinding.DataField = 'MONEDA_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 8
                Width = 60
              end
              object lblComentarios: TcxLabel
                Left = 16
                Top = 165
                Caption = 'Comentarios'
                TabOrder = 19
              end
              object memoComentarios: TcxDBMemo
                Left = 133
                Top = 162
                DataBinding.DataField = 'COMENTARIOS_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 9
                Height = 30
                Width = 847
              end
            end
            object gbPrecios: TcxGroupBox
              Left = 3
              Top = 268
              Caption = ' Plantilla precios e impuestos '
              TabOrder = 1
              Height = 213
              Width = 510
              object lblTipoIva: TcxLabel
                Left = 16
                Top = 24
                Caption = 'Tipo IVA'
                TabOrder = 10
              end
              object cbbTipoIva: TcxDBLookupComboBox
                Left = 100
                Top = 22
                DataBinding.DataField = 'TIPO_IVA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'IVA_IVAGRP'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 40
                    FieldName = 'IVA_IVAGRP'
                  end
                  item
                    Caption = 'Descripci'#243'n'
                    FieldName = 'DESCRIPCION_IVA_IVAGRP'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 0
                Width = 150
              end
              object lblMargen: TcxLabel
                Left = 16
                Top = 60
                Caption = 'Margen comercial %'
                TabOrder = 11
              end
              object spnMargen: TcxDBSpinEdit
                Left = 170
                Top = 58
                DataBinding.DataField = 'PORCENTAJE_MARGEN_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 80
              end
              object lblTarifa: TcxLabel
                Left = 16
                Top = 96
                Caption = 'Tarifa salida'
                TabOrder = 12
              end
              object cbbTarifa: TcxDBLookupComboBox
                Left = 100
                Top = 94
                DataBinding.DataField = 'CODIGO_TAR_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
                Properties.ListColumns = <
                  item
                    Caption = 'Tarifa'
                    FieldName = 'NOMBRE_TAR_TAR'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 2
                Width = 200
              end
              object chkPreciosSinIva: TcxDBCheckBox
                Left = 280
                Top = 26
                Caption = 'Precios sin IVA'
                DataBinding.DataField = 'ESPRECIOS_SIN_IVA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 3
              end
              object chkRedondeoVenta: TcxDBCheckBox
                Left = 272
                Top = 62
                Caption = 'Aplicar redondeo a venta'
                DataBinding.DataField = 'ESREDONDEO_VENTA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 4
              end
              object lblMultiploRedondeo: TcxLabel
                Left = 16
                Top = 132
                Caption = 'Mult.redondeo'
                TabOrder = 8
              end
              object spnMultiploRedondeo: TcxDBSpinEdit
                Left = 130
                Top = 130
                DataBinding.DataField = 'MULTIPLO_REDONDEO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.Increment = 0.050000000000000000
                Properties.ValueType = vtFloat
                TabOrder = 5
                Width = 80
              end
              object lblAjusteFinal: TcxLabel
                Left = 230
                Top = 132
                Caption = 'Ajuste final'
                TabOrder = 9
              end
              object spnAjusteFinal: TcxDBSpinEdit
                Left = 320
                Top = 130
                DataBinding.DataField = 'AJUSTE_FINAL_SES'
                DataBinding.DataSource = dsTablaG
                Properties.Increment = 0.010000000000000000
                Properties.MaxValue = 10.000000000000000000
                Properties.MinValue = -10.000000000000000000
                Properties.ValueType = vtFloat
                TabOrder = 6
                Width = 80
              end
              object chkPrecioPorSku: TcxDBCheckBox
                Left = 16
                Top = 166
                Caption = 'Permitir precio distinto por SKU (talla'#215'color)'
                DataBinding.DataField = 'ESPRECIO_POR_SKU_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                Properties.OnEditValueChanged = chkPrecioPorSkuPropertiesEditValueChanged
                TabOrder = 7
              end
            end
            object gbVariacion: TcxGroupBox
              Left = 519
              Top = 268
              Caption = ' Plantilla variaci'#243'n '
              TabOrder = 2
              Height = 213
              Width = 492
              object lblVariacion: TcxLabel
                Left = 129
                Top = 24
                Caption = 'Variaci'#243'n'
                TabOrder = 5
              end
              object cbbVariacion: TcxDBLookupComboBox
                Left = 232
                Top = 22
                DataBinding.DataField = 'CODIGO_VAR_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_VAR'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_VAR'
                  end
                  item
                    Caption = 'Variaci'#243'n'
                    FieldName = 'NOMBRE_VAR'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 0
                Width = 244
              end
              object chkVarFija: TcxDBCheckBox
                Left = 250
                Top = 55
                Caption = 'Variaci'#243'n fija por l'#237'nea'
                DataBinding.DataField = 'ESVAR_FIJA_SES'
                DataBinding.DataSource = dsTablaG
                Enabled = False
                Hint = 'MVP: una sesi'#243'n = un tallaje (fijo por cabecera).'
                ShowHint = True
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 1
                Visible = False
              end
              object lblConjPivot: TcxLabel
                Left = 16
                Top = 90
                Caption = 'Conj. pivot (columnas)'
                TabOrder = 6
              end
              object cbbConjuntoPivot: TcxDBLookupComboBox
                Left = 232
                Top = 88
                DataBinding.DataField = 'ID_AC_PIVOT_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'ID_AC'
                Properties.ListColumns = <
                  item
                    Caption = 'Conjunto'
                    FieldName = 'NOMBRE_AC'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 2
                Width = 244
              end
              object lblConjFila: TcxLabel
                Left = 16
                Top = 128
                Caption = 'Conj. fila (agrupador)'
                TabOrder = 7
              end
              object cbbConjuntoFila: TcxDBLookupComboBox
                Left = 207
                Top = 125
                DataBinding.DataField = 'ID_AC_FILA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'ID_AC'
                Properties.ListColumns = <
                  item
                    Caption = 'Conjunto'
                    FieldName = 'NOMBRE_AC'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 3
                Width = 269
              end
              object btnVistaPreviaMatriz: TcxButton
                Left = 190
                Top = 162
                Width = 289
                Height = 28
                Caption = 'Vista previa de la matriz'
                TabOrder = 4
                OnClick = btnVistaPreviaMatrizClick
              end
            end
          end
          object tsPlantilla: TcxTabSheet
            Caption = '&2. Datos Fijos en Documento '
            ImageIndex = 1
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            object pcPlantilla: TcxPageControl
              Left = 0
              Top = 0
              Width = 1032
              Height = 594
              Align = alClient
              TabOrder = 0
              Properties.ActivePage = tsPropiedades
              Properties.CustomButtons.Buttons = <>
              ClientRectBottom = 592
              ClientRectLeft = 2
              ClientRectRight = 1030
              ClientRectTop = 29
              object tsPropiedades: TcxTabSheet
                Caption = 'Propiedades comunes'
                ExplicitLeft = 0
                ExplicitTop = 0
                ExplicitWidth = 0
                ExplicitHeight = 0
                object pnlPropsTop: TPanel
                  Left = 0
                  Top = 0
                  Width = 1028
                  Height = 36
                  Align = alTop
                  TabOrder = 0
                  object btnAddProp: TcxButton
                    Left = 8
                    Top = 4
                    Width = 100
                    Height = 28
                    Caption = '+ A'#241'adir'
                    TabOrder = 0
                    OnClick = btnAddPropClick
                  end
                  object btnDelProp: TcxButton
                    Left = 116
                    Top = 4
                    Width = 100
                    Height = 28
                    Caption = '- Borrar'
                    TabOrder = 1
                    OnClick = btnDelPropClick
                  end
                end
                object cxgrdProps: TcxGrid
                  Left = 0
                  Top = 36
                  Width = 1028
                  Height = 527
                  Align = alClient
                  TabOrder = 1
                  object tvProps: TcxGridDBTableView
                    OptionsView.GroupByBox = False
                    object dbcPropsCodigo: TcxGridDBColumn
                      Caption = 'C'#243'digo'
                      DataBinding.FieldName = 'CODIGO_PROP_SESPROP'
                      Width = 89
                    end
                    object dbcPropsNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_PROP'
                      Width = 195
                    end
                    object dbcPropsTipo: TcxGridDBColumn
                      Caption = 'Tipo'
                      DataBinding.FieldName = 'TIPO_PROP'
                      Width = 91
                    end
                    object dbcPropsFijo: TcxGridDBColumn
                      Caption = 'Fijo'
                      DataBinding.FieldName = 'ESFIJO_SESPROP'
                      Width = 97
                    end
                    object dbcPropsValorDefecto: TcxGridDBColumn
                      Caption = 'Valor por defecto'
                      DataBinding.FieldName = 'VALOR_DEFECTO_SESPROP'
                      Width = 166
                    end
                  end
                  object glProps: TcxGridLevel
                    GridView = tvProps
                  end
                end
              end
              object tsKits: TcxTabSheet
                Caption = 'Kits de cantidades'
                ExplicitLeft = 0
                ExplicitTop = 0
                ExplicitWidth = 0
                ExplicitHeight = 0
                object pnlKitsTop: TPanel
                  Left = 0
                  Top = 0
                  Width = 1028
                  Height = 36
                  Align = alTop
                  TabOrder = 0
                  object btnAddKit: TcxButton
                    Left = 8
                    Top = 4
                    Width = 119
                    Height = 28
                    Caption = '+ Nuevo kit'
                    TabOrder = 0
                    OnClick = btnAddKitClick
                  end
                  object btnDelKit: TcxButton
                    Left = 136
                    Top = 4
                    Width = 117
                    Height = 28
                    Caption = '- Borrar kit'
                    TabOrder = 1
                    OnClick = btnDelKitClick
                  end
                  object btnImportarKitPrv: TcxButton
                    Left = 280
                    Top = 4
                    Width = 281
                    Height = 28
                    Caption = 'Importar de proveedor'
                    TabOrder = 2
                    OnClick = btnImportarKitPrvClick
                  end
                end
                object cxgrdKits: TcxGrid
                  Left = 0
                  Top = 36
                  Width = 400
                  Height = 527
                  Align = alLeft
                  TabOrder = 2
                  object tvKits: TcxGridDBTableView
                    OptionsView.GroupByBox = False
                    object dbcKitsCodigo: TcxGridDBColumn
                      Caption = 'C'#243'digo'
                      DataBinding.FieldName = 'CODIGO_SESKIT'
                      Width = 106
                    end
                    object dbcKitsNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_SESKIT'
                      Width = 99
                    end
                    object dbcKitsIdVaDestino: TcxGridDBColumn
                      Caption = 'Atributo destino'
                      DataBinding.FieldName = 'ID_VA_DESTINO_SESKIT'
                      Width = 189
                    end
                  end
                  object glKits: TcxGridLevel
                    GridView = tvKits
                  end
                end
                object cxgrdKitsDet: TcxGrid
                  Left = 400
                  Top = 36
                  Width = 628
                  Height = 527
                  Align = alClient
                  TabOrder = 1
                  object tvKitsDet: TcxGridDBTableView
                    OptionsView.GroupByBox = False
                    object dbcKitsDetValor: TcxGridDBColumn
                      Caption = 'Valor'
                      DataBinding.FieldName = 'VALOR_DESTINO_SESKITD'
                      Width = 139
                    end
                    object dbcKitsDetCantidad: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_SESKITD'
                      Width = 156
                    end
                  end
                  object glKitsDet: TcxGridLevel
                    GridView = tvKitsDet
                  end
                end
              end
            end
          end
          object tsLineas: TcxTabSheet
            Caption = '&2. L'#237'neas '
            ImageIndex = 2
            object pnlLineasTop: TPanel
              Left = 0
              Top = 0
              Width = 1032
              Height = 280
              Align = alTop
              TabOrder = 0
              object pnlLineasBotones: TPanel
                Left = 1
                Top = 1
                Width = 1030
                Height = 36
                Align = alTop
                TabOrder = 0
                object btnAddLinea: TcxButton
                  Left = 8
                  Top = 2
                  Width = 133
                  Height = 28
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAddLineaClick
                end
                object btnDupLinea: TcxButton
                  Left = 160
                  Top = 2
                  Width = 100
                  Height = 28
                  Caption = 'Duplicar'
                  TabOrder = 1
                  OnClick = btnDupLineaClick
                end
                object btnDelLinea: TcxButton
                  Left = 278
                  Top = 2
                  Width = 110
                  Height = 28
                  Caption = '- Borrar'
                  TabOrder = 2
                  OnClick = btnDelLineaClick
                end
                object btnResolverDuplicado: TcxButton
                  Left = 414
                  Top = 2
                  Width = 220
                  Height = 28
                  Caption = 'Resolver duplicado...'
                  TabOrder = 3
                  OnClick = btnResolverDuplicadoClick
                end
                object btnCalcularVenta: TcxButton
                  Left = 644
                  Top = 2
                  Width = 170
                  Height = 28
                  Hint = 
                    'Aplica formula coste->venta a la linea actual o a las selecciona' +
                    'das'
                  Caption = 'Calcular venta'
                  ParentShowHint = False
                  ShowHint = True
                  TabOrder = 4
                  OnClick = btnCalcularVentaClick
                end
              end
              object cxgrdLineas: TcxGrid
                Left = 1
                Top = 37
                Width = 1030
                Height = 242
                Align = alClient
                TabOrder = 1
                object tvLineas: TcxGridDBTableView
                  OnEditKeyDown = tvLineasEditKeyDown
                  OnFocusedRecordChanged = tvLineasFocusedRecordChanged
                  OptionsView.GroupByBox = False
                  object dbcLinNumero: TcxGridDBColumn
                    Caption = 'L'#237'n'
                    DataBinding.FieldName = 'LINEA_SESLIN'
                    Width = 40
                  end
                  object dbcLinTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_LINEA_SESLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Properties.DropDownListStyle = lsFixedList
                    Properties.Items.Strings = (
                      'MATRIZ'
                      'ESCALAR'
                      'SERVICIO')
                    Width = 80
                  end
                  object dbcLinCodigoArt: TcxGridDBColumn
                    Caption = 'C'#243'digo art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_SESLIN'
                    Width = 158
                  end
                  object dbcLinDescripcion: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_SESLIN'
                    Width = 240
                  end
                  object dbcLinFamilia: TcxGridDBColumn
                    Caption = 'Familia'
                    DataBinding.FieldName = 'CODIGO_FAM_SESLIN'
                    Width = 100
                  end
                  object dbcLinRefPrv: TcxGridDBColumn
                    Caption = 'Ref. prov.'
                    DataBinding.FieldName = 'REF_PRV_SESLIN'
                    Width = 110
                  end
                  object dbcLinPrecioCompra: TcxGridDBColumn
                    Caption = 'Pr. compra'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SESLIN'
                    Width = 97
                  end
                  object dbcLinMargen: TcxGridDBColumn
                    Caption = '% margen'
                    DataBinding.FieldName = 'PORCENTAJE_MARGEN_SESLIN'
                    Width = 70
                  end
                  object dbcLinPrecioVenta: TcxGridDBColumn
                    Caption = 'Pr. venta'
                    DataBinding.FieldName = 'PRECIO_VENTA_SESLIN'
                    Width = 90
                  end
                  object dbcLinTipoIva: TcxGridDBColumn
                    Caption = 'IVA'
                    DataBinding.FieldName = 'TIPO_IVA_SESLIN'
                    Width = 50
                  end
                  object dbcLinTotalUnidades: TcxGridDBColumn
                    Caption = 'Uds'
                    DataBinding.FieldName = 'TOTAL_UNIDADES_SESLIN'
                    Width = 60
                  end
                  object dbcLinTotalLinea: TcxGridDBColumn
                    Caption = 'Total l'#237'nea'
                    DataBinding.FieldName = 'TOTAL_LINEA_SESLIN'
                    Width = 100
                  end
                  object dbcLinDuplicado: TcxGridDBColumn
                    Caption = #9888
                    DataBinding.FieldName = 'ESDUPLICADO_SESLIN'
                    Width = 40
                  end
                end
                object glLineas: TcxGridLevel
                  GridView = tvLineas
                end
              end
            end
            object pnlLineasDetalle: TPanel
              Left = 0
              Top = 280
              Width = 1032
              Height = 314
              Align = alClient
              TabOrder = 1
              object lblLineaActiva: TcxLabel
                Left = 8
                Top = 4
                Caption = 'L'#237'nea seleccionada: -'
                TabOrder = 3
              end
              object pnlAlmacenSel: TPanel
                Left = 1
                Top = 1
                Width = 1030
                Height = 36
                Align = alTop
                TabOrder = 0
                object lblAlmacenSel: TcxLabel
                  Left = 8
                  Top = 8
                  Caption = 'Almac'#233'n editando'
                  TabOrder = 2
                end
                object cbbAlmacenMatriz: TcxLookupComboBox
                  Left = 168
                  Top = 6
                  Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                  Properties.ListColumns = <
                    item
                      FieldName = 'NOMBRE_ALM_ALM'
                    end>
                  Properties.OnChange = cbbAlmacenMatrizPropertiesChange
                  TabOrder = 0
                  Width = 222
                end
                object lblTotalesPorAlm: TcxLabel
                  Left = 410
                  Top = 8
                  Caption = '(las celdas vac'#237'as usan el almac'#233'n de cabecera)'
                  Style.TextColor = clGrayText
                  TabOrder = 1
                end
              end
              object pnlMatrizBotones: TPanel
                Left = 1
                Top = 37
                Width = 1030
                Height = 36
                Align = alTop
                TabOrder = 4
                object lblKitSel: TcxLabel
                  Left = 8
                  Top = 8
                  Caption = 'Kit a aplicar'
                  TabOrder = 6
                end
                object cbbKitAplicar: TcxDBLookupComboBox
                  Left = 117
                  Top = 6
                  Properties.ListColumns = <>
                  TabOrder = 0
                  Width = 163
                end
                object btnAplicarKitFila: TcxButton
                  Left = 290
                  Top = 4
                  Width = 140
                  Height = 28
                  Caption = 'Aplicar a fila'
                  TabOrder = 1
                  OnClick = btnAplicarKitFilaClick
                end
                object btnAplicarKitTodas: TcxButton
                  Left = 436
                  Top = 4
                  Width = 140
                  Height = 28
                  Caption = 'Aplicar a todas'
                  TabOrder = 2
                  OnClick = btnAplicarKitTodasClick
                end
                object btnAddFila: TcxButton
                  Left = 600
                  Top = 4
                  Width = 110
                  Height = 28
                  Caption = '+ Fila'
                  TabOrder = 3
                  OnClick = btnAddFilaClick
                end
                object btnDelFila: TcxButton
                  Left = 716
                  Top = 4
                  Width = 110
                  Height = 28
                  Caption = '- Fila'
                  TabOrder = 4
                  OnClick = btnDelFilaClick
                end
                object btnAddColumna: TcxButton
                  Left = 832
                  Top = 4
                  Width = 185
                  Height = 28
                  Caption = '+ Talla / valor pivot'
                  TabOrder = 5
                  OnClick = btnAddColumnaClick
                end
              end
              object gbMatriz: TcxGroupBox
                Left = 1
                Top = 73
                Align = alClient
                Caption = ' Matriz pivotada '
                TabOrder = 1
                Height = 50
                Width = 1030
                object sbMatriz: TScrollBox
                  Left = 4
                  Top = 22
                  Width = 1022
                  Height = 12
                  Align = alClient
                  TabOrder = 0
                end
              end
              object splPreciosSku: TcxSplitter
                Left = 1
                Top = 123
                Width = 1030
                Height = 10
                AlignSplitter = salBottom
                Control = gbPreciosSku
                Visible = False
              end
              object gbPreciosSku: TcxGroupBox
                Left = 1
                Top = 133
                Align = alBottom
                Caption = ' Precios por SKU (override) '
                TabOrder = 2
                Visible = False
                Height = 180
                Width = 1030
                object cxgrdPreciosSku: TcxGrid
                  Left = 4
                  Top = 22
                  Width = 1022
                  Height = 142
                  Align = alClient
                  TabOrder = 0
                  object tvPreciosSku: TcxGridDBTableView
                    OptionsView.GroupByBox = False
                    object dbcPreciosSkuValFila: TcxGridDBColumn
                      Caption = 'Color / Fila'
                      DataBinding.FieldName = 'VAL_FILA'
                      Options.Editing = False
                      Width = 160
                    end
                    object dbcPreciosSkuValPivot: TcxGridDBColumn
                      Caption = 'Talla / Pivot'
                      DataBinding.FieldName = 'VAL_PIVOT'
                      Options.Editing = False
                      Width = 126
                    end
                    object dbcPreciosSkuPrecioCompra: TcxGridDBColumn
                      Caption = 'Pr. compra'
                      DataBinding.FieldName = 'PRECIO_COMPRA_SESLINSKU'
                      Width = 134
                    end
                    object dbcPreciosSkuPrecioVenta: TcxGridDBColumn
                      Caption = 'Pr. venta'
                      DataBinding.FieldName = 'PRECIO_VENTA_SESLINSKU'
                      Width = 110
                    end
                  end
                  object glPreciosSku: TcxGridLevel
                    GridView = tvPreciosSku
                  end
                end
              end
            end
          end
          object tsMaterializacion: TcxTabSheet
            Caption = '&3.Materializaci'#243'n '
            ImageIndex = 3
            object gbResumen: TcxGroupBox
              Left = 8
              Top = 8
              Caption = ' Al pulsar Crear art'#237'culos y documentos... '
              TabOrder = 0
              Height = 200
              Width = 500
              object lblResNumArticulos: TcxLabel
                Left = 16
                Top = 24
                Caption = '...'
                TabOrder = 0
              end
              object lblResNumSkus: TcxLabel
                Left = 16
                Top = 50
                Caption = '...'
                TabOrder = 1
              end
              object lblResNumEan13: TcxLabel
                Left = 16
                Top = 76
                Caption = '...'
                TabOrder = 2
              end
              object lblResNumPropiedades: TcxLabel
                Left = 16
                Top = 102
                Caption = '...'
                TabOrder = 3
              end
              object lblResEnlacePrv: TcxLabel
                Left = 16
                Top = 128
                Caption = '...'
                TabOrder = 4
              end
              object lblResConflictos: TcxLabel
                Left = 16
                Top = 154
                Caption = '...'
                TabOrder = 5
              end
            end
            object gbDocumento: TcxGroupBox
              Left = 513
              Top = 8
              Caption = ' Documento a generar '
              TabOrder = 1
              Height = 200
              Width = 499
              object chkGeneraPedido: TcxDBCheckBox
                Left = 16
                Top = 24
                Caption = 'Pedido de compra (no mueve stock)'
                DataBinding.DataField = 'ESGENERA_PEDIDO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 0
              end
              object chkGeneraAlbaran: TcxDBCheckBox
                Left = 16
                Top = 52
                Caption = 'Albar'#225'n de compra (entra stock)'
                DataBinding.DataField = 'ESGENERA_ALBARAN_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 1
              end
              object lblPrefijoEan: TcxLabel
                Left = 16
                Top = 90
                Caption = 'Prefijo EAN13'
                TabOrder = 5
              end
              object txtPrefijoEan: TcxDBTextEdit
                Left = 152
                Top = 86
                DataBinding.DataField = 'PREFIJO_EAN_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 100
              end
              object btnValidarTodo: TcxButton
                Left = 16
                Top = 130
                Width = 200
                Height = 32
                Caption = 'Validar todo'
                TabOrder = 3
                OnClick = btnValidarTodoClick
              end
              object btnDoMaterializar: TcxButton
                Left = 230
                Top = 130
                Width = 259
                Height = 32
                Caption = 'Crear art'#237'culos y documentos'
                TabOrder = 4
                OnClick = btnDoMaterializarClick
              end
            end
            object cxgrdPreview: TcxGrid
              Left = 8
              Top = 220
              Width = 1004
              Height = 396
              TabOrder = 2
              object tvPreview: TcxGridDBTableView
                OptionsView.GroupByBox = False
                object dbcPrevLinea: TcxGridDBColumn
                  Caption = 'L'#237'n'
                  DataBinding.FieldName = 'LINEA'
                  Width = 40
                end
                object dbcPrevCodigoArt: TcxGridDBColumn
                  Caption = 'C'#243'digo'
                  DataBinding.FieldName = 'CODIGO_ART'
                  Width = 140
                end
                object dbcPrevDescripcion: TcxGridDBColumn
                  Caption = 'Descripci'#243'n'
                  DataBinding.FieldName = 'DESCRIPCION'
                  Width = 250
                end
                object dbcPrevValorPivot: TcxGridDBColumn
                  Caption = 'Talla / Pivot'
                  DataBinding.FieldName = 'VALOR_PIVOT'
                  Width = 133
                end
                object dbcPrevCantidad: TcxGridDBColumn
                  Caption = 'Cantidad'
                  DataBinding.FieldName = 'CANTIDAD'
                  Width = 110
                end
                object dbcPrevPrecioCompra: TcxGridDBColumn
                  Caption = 'Pr. compra'
                  DataBinding.FieldName = 'PRECIO_COMPRA'
                  Width = 112
                end
                object dbcPrevPrecioVenta: TcxGridDBColumn
                  Caption = 'Pr. venta'
                  DataBinding.FieldName = 'PRECIO_VENTA'
                  Width = 90
                end
              end
              object glPreview: TcxGridLevel
                GridView = tvPreview
              end
            end
          end
          object tsLog: TcxTabSheet
            Caption = '&4. Log '
            ImageIndex = 4
            object lblPedidoGenerado: TcxLabel
              Left = 8
              Top = 8
              Caption = 'Pedido generado: -'
              TabOrder = 1
            end
            object lblAlbaranGenerado: TcxLabel
              Left = 8
              Top = 34
              Caption = 'Albar'#225'n generado: -'
              TabOrder = 2
            end
            object lblMensajeError: TcxDBLabel
              Left = 8
              Top = 60
              DataBinding.DataField = 'MENSAJE_ERROR_SES'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Height = 21
              Width = 1000
            end
            object memoLog: TcxMemo
              Left = 8
              Top = 92
              TabOrder = 0
              Height = 520
              Width = 1004
            end
          end
        end
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 1036
          Height = 36
          Align = alTop
          TabOrder = 1
          object btnCrearMaterializar: TcxButton
            Left = 8
            Top = 4
            Width = 275
            Height = 28
            Caption = 'Crear art'#237'culos y documentos'
            TabOrder = 0
            OnClick = btnCrearMaterializarClick
          end
          object btnAnularSesion: TcxButton
            Left = 299
            Top = 4
            Width = 100
            Height = 28
            Caption = 'Anular'
            TabOrder = 1
            OnClick = btnAnularSesionClick
          end
          object btnClonarSesion: TcxButton
            Left = 409
            Top = 4
            Width = 100
            Height = 28
            Caption = 'Clonar'
            TabOrder = 2
            OnClick = btnClonarSesionClick
          end
          object btnCerrarManual: TcxButton
            Left = 519
            Top = 4
            Width = 214
            Height = 28
            Caption = 'Cerrar (sin materializar)'
            TabOrder = 3
            OnClick = btnCerrarManualClick
          end
        end
        object Panel1: TPanel
          Left = 0
          Top = 36
          Width = 1036
          Height = 36
          Align = alTop
          TabOrder = 2
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 1036
        ExplicitHeight = 697
        inherited pnlPerfilTop: TPanel
          Width = 1036
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1036
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1036
          Height = 640
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1036
          ExplicitHeight = 640
          inherited cxgrdPerfil: TcxGrid
            Width = 1036
            Height = 640
            ExplicitWidth = 1036
            ExplicitHeight = 640
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1040
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1040
      inherited pnlTopGrid: TPanel
        Width = 1040
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1040
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1040
    Height = 768
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1040
    ExplicitHeight = 768
    inherited pButtonGen: TPanel
      Top = 570
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 570
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
  end
  object alSesion: TActionList
    Left = 12
    Top = 12
    object actMaterializar: TAction
      Caption = 'Materializar'
      ShortCut = 120
      OnExecute = actMaterializarExecute
    end
    object actNuevaLinea: TAction
      Caption = 'Nueva l'#237'nea'
      ShortCut = 45
      OnExecute = actNuevaLineaExecute
    end
    object actBorrarLinea: TAction
      Caption = 'Borrar l'#237'nea'
      ShortCut = 16430
      OnExecute = actBorrarLineaExecute
    end
    object actDuplicarLinea: TAction
      Caption = 'Duplicar l'#237'nea'
      ShortCut = 16452
      OnExecute = actDuplicarLineaExecute
    end
    object actAplicarKit: TAction
      Caption = 'Aplicar kit'
      ShortCut = 119
      OnExecute = actAplicarKitExecute
    end
    object actValidar: TAction
      Caption = 'Validar'
      ShortCut = 16470
      OnExecute = actValidarExecute
    end
  end
end
