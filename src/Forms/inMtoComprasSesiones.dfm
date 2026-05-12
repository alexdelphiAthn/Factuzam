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
      Properties.ActivePage = tsLista
      ExplicitWidth = 1040
      ExplicitHeight = 728
      ClientRectBottom = 726
      ClientRectRight = 1038
      inherited tsLista: TcxTabSheet
        ExplicitWidth = 1032
        ExplicitHeight = 694
        inherited cxGrdPrincipal: TcxGrid
          Width = 1032
          Height = 694
          ExplicitWidth = 1032
          ExplicitHeight = 694
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
        ExplicitWidth = 1032
        ExplicitHeight = 694
        object pcSesion: TcxPageControl
          Left = 0
          Top = 36
          Width = 1036
          Height = 661
          Align = alClient
          TabOrder = 0
          Properties.ActivePage = tsCabecera
          Properties.CustomButtons.Buttons = <>
          ExplicitWidth = 1032
          ExplicitHeight = 658
          ClientRectBottom = 659
          ClientRectLeft = 2
          ClientRectRight = 1034
          ClientRectTop = 29
          object tsCabecera: TcxTabSheet
            Caption = '&Cabecera'
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
              Height = 200
              Width = 1004
              object lblSerie: TcxLabel
                Left = 16
                Top = 24
                Caption = 'Serie'
                TabOrder = 10
              end
              object cbbSerie: TcxDBLookupComboBox
                Left = 80
                Top = 22
                DataBinding.DataField = 'SERIE_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 0
                Width = 80
              end
              object lblNumero: TcxLabel
                Left = 170
                Top = 24
                Caption = 'N'#250'mero'
                TabOrder = 11
              end
              object txtNumero: TcxDBTextEdit
                Left = 240
                Top = 22
                DataBinding.DataField = 'NUMERO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblFecha: TcxLabel
                Left = 360
                Top = 24
                Caption = 'Fecha'
                TabOrder = 12
              end
              object dteFecha: TcxDBDateEdit
                Left = 420
                Top = 22
                DataBinding.DataField = 'FECHA_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 120
              end
              object lblEstado: TcxLabel
                Left = 560
                Top = 24
                Caption = 'Estado'
                TabOrder = 13
              end
              object txtEstado: TcxDBTextEdit
                Left = 620
                Top = 22
                DataBinding.DataField = 'ESTADO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 100
              end
              object lblEmpresa: TcxLabel
                Left = 16
                Top = 60
                Caption = 'Empresa'
                TabOrder = 14
              end
              object cbbEmpresa: TcxDBLookupComboBox
                Left = 100
                Top = 58
                DataBinding.DataField = 'CODIGO_EMP_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 4
                Width = 300
              end
              object lblProveedor: TcxLabel
                Left = 16
                Top = 96
                Caption = 'Proveedor'
                TabOrder = 15
              end
              object cbbProveedor: TcxDBLookupComboBox
                Left = 100
                Top = 94
                DataBinding.DataField = 'CODIGO_PRV_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 5
                Width = 300
              end
              object lblRefPrv: TcxLabel
                Left = 420
                Top = 96
                Caption = 'Ref. proveedor'
                TabOrder = 16
              end
              object txtRefPrv: TcxDBTextEdit
                Left = 540
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
                Left = 140
                Top = 130
                DataBinding.DataField = 'CODIGO_ALM_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 7
                Width = 200
              end
              object lblMoneda: TcxLabel
                Left = 360
                Top = 132
                Caption = 'Moneda'
                TabOrder = 18
              end
              object txtMoneda: TcxDBTextEdit
                Left = 420
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
                Left = 100
                Top = 162
                DataBinding.DataField = 'COMENTARIOS_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 9
                Height = 30
                Width = 880
              end
            end
            object gbPrecios: TcxGroupBox
              Left = 8
              Top = 220
              Caption = ' Plantilla precios e impuestos '
              TabOrder = 1
              Height = 200
              Width = 500
              object lblTipoIva: TcxLabel
                Left = 16
                Top = 24
                Caption = 'Tipo IVA'
                TabOrder = 5
              end
              object cbbTipoIva: TcxDBLookupComboBox
                Left = 100
                Top = 22
                DataBinding.DataField = 'TIPO_IVA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 0
                Width = 150
              end
              object lblMargen: TcxLabel
                Left = 16
                Top = 60
                Caption = 'Margen comercial %'
                TabOrder = 6
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
                TabOrder = 7
              end
              object cbbTarifa: TcxDBLookupComboBox
                Left = 100
                Top = 94
                DataBinding.DataField = 'CODIGO_TAR_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 2
                Width = 200
              end
              object chkPreciosSinIva: TcxDBCheckBox
                Left = 280
                Top = 22
                Caption = 'Precios sin IVA'
                DataBinding.DataField = 'ESPRECIOS_SIN_IVA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 3
              end
              object chkRedondeoVenta: TcxDBCheckBox
                Left = 280
                Top = 58
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
                Properties.ValueType = vtFloat
                Properties.Increment = 0.050000000000000000
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
                Properties.ValueType = vtFloat
                Properties.Increment = 0.010000000000000000
                Properties.MinValue = -10.000000000000000000
                Properties.MaxValue = 10.000000000000000000
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
                Width = 400
              end
            end
            object gbVariacion: TcxGroupBox
              Left = 520
              Top = 220
              Caption = ' Plantilla variaci'#243'n / sistema de tallas '
              TabOrder = 2
              Height = 160
              Width = 492
              object lblVariacion: TcxLabel
                Left = 16
                Top = 24
                Caption = 'Variaci'#243'n'
                TabOrder = 5
              end
              object cbbVariacion: TcxDBLookupComboBox
                Left = 100
                Top = 22
                DataBinding.DataField = 'CODIGO_VAR_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 0
                Width = 200
              end
              object chkVarFija: TcxDBCheckBox
                Left = 320
                Top = 22
                Caption = 'Variaci'#243'n fija por l'#237'nea'
                DataBinding.DataField = 'ESVAR_FIJA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 1
              end
              object lblConjPivot: TcxLabel
                Left = 16
                Top = 60
                Caption = 'Conj. pivot (columnas)'
                TabOrder = 6
              end
              object cbbConjuntoPivot: TcxDBLookupComboBox
                Left = 180
                Top = 58
                DataBinding.DataField = 'ID_AC_PIVOT_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 2
                Width = 280
              end
              object lblConjFila: TcxLabel
                Left = 16
                Top = 96
                Caption = 'Conj. fila (agrupador)'
                TabOrder = 7
              end
              object cbbConjuntoFila: TcxDBLookupComboBox
                Left = 180
                Top = 94
                DataBinding.DataField = 'ID_AC_FILA_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ListColumns = <>
                TabOrder = 3
                Width = 280
              end
              object btnVistaPreviaMatriz: TcxButton
                Left = 16
                Top = 124
                Width = 200
                Height = 28
                Caption = 'Vista previa de la matriz'
                TabOrder = 4
                OnClick = btnVistaPreviaMatrizClick
              end
            end
          end
          object tsPlantilla: TcxTabSheet
            Caption = '&Plantilla'
            ImageIndex = 1
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            object pcPlantilla: TcxPageControl
              Left = 0
              Top = 0
              Width = 1032
              Height = 630
              Align = alClient
              TabOrder = 0
              Properties.ActivePage = tsPropiedades
              Properties.CustomButtons.Buttons = <>
              ExplicitWidth = 1024
              ExplicitHeight = 624
              ClientRectBottom = 628
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
                  Width = 1012
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
                  Width = 1012
                  Height = 550
                  Align = alClient
                  TabOrder = 1
                  object tvProps: TcxGridDBTableView
                    object dbcPropsCodigo: TcxGridDBColumn
                      Caption = 'C'#243'digo'
                      DataBinding.FieldName = 'CODIGO_PROP_SESPROP'
                    end
                    object dbcPropsNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_PROP'
                    end
                    object dbcPropsTipo: TcxGridDBColumn
                      Caption = 'Tipo'
                      DataBinding.FieldName = 'TIPO_PROP'
                    end
                    object dbcPropsFijo: TcxGridDBColumn
                      Caption = 'Fijo'
                      DataBinding.FieldName = 'ESFIJO_SESPROP'
                    end
                    object dbcPropsValorDefecto: TcxGridDBColumn
                      Caption = 'Valor por defecto'
                      DataBinding.FieldName = 'VALOR_DEFECTO_SESPROP'
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
                  Width = 1012
                  Height = 36
                  Align = alTop
                  TabOrder = 0
                  object btnAddKit: TcxButton
                    Left = 8
                    Top = 4
                    Width = 100
                    Height = 28
                    Caption = '+ Nuevo kit'
                    TabOrder = 0
                    OnClick = btnAddKitClick
                  end
                  object btnDelKit: TcxButton
                    Left = 116
                    Top = 4
                    Width = 100
                    Height = 28
                    Caption = '- Borrar kit'
                    TabOrder = 1
                    OnClick = btnDelKitClick
                  end
                  object btnImportarKitPrv: TcxButton
                    Left = 224
                    Top = 4
                    Width = 180
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
                  Height = 550
                  Align = alLeft
                  TabOrder = 1
                  object tvKits: TcxGridDBTableView
                    object dbcKitsCodigo: TcxGridDBColumn
                      Caption = 'C'#243'digo'
                      DataBinding.FieldName = 'CODIGO_SESKIT'
                    end
                    object dbcKitsNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_SESKIT'
                    end
                    object dbcKitsIdVaDestino: TcxGridDBColumn
                      Caption = 'Atributo destino'
                      DataBinding.FieldName = 'ID_VA_DESTINO_SESKIT'
                    end
                  end
                  object glKits: TcxGridLevel
                    GridView = tvKits
                  end
                end
                object cxgrdKitsDet: TcxGrid
                  Left = 400
                  Top = 36
                  Width = 612
                  Height = 550
                  Align = alClient
                  TabOrder = 1
                  object tvKitsDet: TcxGridDBTableView
                    object dbcKitsDetValor: TcxGridDBColumn
                      Caption = 'Valor (talla)'
                      DataBinding.FieldName = 'VALOR_DESTINO_SESKITD'
                    end
                    object dbcKitsDetCantidad: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_SESKITD'
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
            Caption = '&L'#237'neas'
            ImageIndex = 2
            ExplicitLeft = 4
            ExplicitTop = 30
            ExplicitWidth = 1024
            ExplicitHeight = 624
            object pnlLineasTop: TPanel
              Left = 0
              Top = 0
              Width = 1032
              Height = 280
              Align = alTop
              TabOrder = 0
              ExplicitWidth = 1024
              object pnlLineasBotones: TPanel
                Left = 1
                Top = 1
                Width = 1030
                Height = 36
                Align = alTop
                TabOrder = 0
                ExplicitWidth = 1022
                object btnAddLinea: TcxButton
                  Left = 8
                  Top = 4
                  Width = 110
                  Height = 28
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAddLineaClick
                end
                object btnDupLinea: TcxButton
                  Left = 126
                  Top = 4
                  Width = 110
                  Height = 28
                  Caption = 'Duplicar'
                  TabOrder = 1
                  OnClick = btnDupLineaClick
                end
                object btnDelLinea: TcxButton
                  Left = 244
                  Top = 4
                  Width = 110
                  Height = 28
                  Caption = '- Borrar'
                  TabOrder = 2
                  OnClick = btnDelLineaClick
                end
                object btnResolverDuplicado: TcxButton
                  Left = 380
                  Top = 4
                  Width = 220
                  Height = 28
                  Caption = 'Resolver duplicado...'
                  TabOrder = 3
                  OnClick = btnResolverDuplicadoClick
                end
                object btnCalcularVenta: TcxButton
                  Left = 610
                  Top = 4
                  Width = 170
                  Height = 28
                  Caption = 'Calcular venta'
                  Hint = 'Aplica formula coste->venta a la linea actual o a las seleccionadas'
                  ShowHint = True
                  TabOrder = 4
                  OnClick = btnCalcularVentaClick
                end
              end
              object cxgrdLineas: TcxGrid
                Left = 1
                Top = 37
                Width = 1022
                Height = 242
                Align = alClient
                TabOrder = 1
                object tvLineas: TcxGridDBTableView
                  OnFocusedRecordChanged = tvLineasFocusedRecordChanged
                  object dbcLinNumero: TcxGridDBColumn
                    Caption = 'L'#237'n'
                    DataBinding.FieldName = 'LINEA_SESLIN'
                    Width = 40
                  end
                  object dbcLinTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_LINEA_SESLIN'
                    Width = 80
                  end
                  object dbcLinCodigoArt: TcxGridDBColumn
                    Caption = 'C'#243'digo art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_SESLIN'
                    Width = 140
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
                    Width = 90
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
              Height = 350
              Align = alClient
              TabOrder = 1
              ExplicitWidth = 1024
              ExplicitHeight = 344
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
                ExplicitWidth = 1022
                object lblAlmacenSel: TcxLabel
                  Left = 8
                  Top = 8
                  Caption = 'Almac'#233'n editando'
                  TabOrder = 2
                end
                object cbbAlmacenMatriz: TcxLookupComboBox
                  Left = 130
                  Top = 6
                  Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                  Properties.ListColumns = <
                    item
                      FieldName = 'NOMBRE_ALM_ALM'
                    end>
                  Properties.OnChange = cbbAlmacenMatrizPropertiesChange
                  TabOrder = 0
                  Width = 260
                end
                object lblTotalesPorAlm: TcxLabel
                  Left = 410
                  Top = 8
                  Caption = '(las celdas vac'#237'as usan el almac'#233'n de cabecera)'
                  Style.TextColor = clGrayText
                  Style.IsFontAssigned = True
                  TabOrder = 1
                end
              end
              object pnlMatrizBotones: TPanel
                Left = 1
                Top = 37
                Width = 1030
                Height = 36
                Align = alTop
                TabOrder = 1
                ExplicitWidth = 1022
                object lblKitSel: TcxLabel
                  Left = 8
                  Top = 8
                  Caption = 'Kit a aplicar'
                  TabOrder = 5
                end
                object cbbKitAplicar: TcxDBLookupComboBox
                  Left = 80
                  Top = 6
                  Properties.ListColumns = <>
                  TabOrder = 0
                  Width = 200
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
              end
              object gbMatriz: TcxGroupBox
                Left = 1
                Top = 37
                Align = alClient
                Caption = ' Matriz pivotada '
                TabOrder = 1
                ExplicitTop = 64
                ExplicitWidth = 1022
                ExplicitHeight = 279
                Height = 312
                Width = 1030
                object sbMatriz: TScrollBox
                  Left = 4
                  Top = 22
                  Width = 1022
                  Height = 274
                  Align = alClient
                  TabOrder = 0
                  ExplicitLeft = 2
                  ExplicitWidth = 1018
                  ExplicitHeight = 255
                end
              end
              object splPreciosSku: TcxSplitter
                Left = 1
                Top = 349
                Width = 1030
                Height = 8
                AlignSplitter = salBottom
                Control = gbPreciosSku
                Visible = False
              end
              object gbPreciosSku: TcxGroupBox
                Left = 1
                Top = 357
                Align = alBottom
                Caption = ' Precios por SKU (override) '
                TabOrder = 2
                Height = 180
                Width = 1030
                Visible = False
                object cxgrdPreciosSku: TcxGrid
                  Left = 4
                  Top = 22
                  Width = 1022
                  Height = 154
                  Align = alClient
                  TabOrder = 0
                  object tvPreciosSku: TcxGridDBTableView
                    Navigator.Buttons.CustomButtons = <>
                    DataController.DataSource = nil
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
                      Width = 100
                    end
                    object dbcPreciosSkuPrecioCompra: TcxGridDBColumn
                      Caption = 'Pr. compra'
                      DataBinding.FieldName = 'PRECIO_COMPRA_SESLINSKU'
                      Properties.OnEditValueChanged = dbcPreciosSkuPrecioCompraPropertiesEditValueChanged
                      Width = 110
                    end
                    object dbcPreciosSkuPrecioVenta: TcxGridDBColumn
                      Caption = 'Pr. venta'
                      DataBinding.FieldName = 'PRECIO_VENTA_SESLINSKU'
                      Properties.OnEditValueChanged = dbcPreciosSkuPrecioVentaPropertiesEditValueChanged
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
            Caption = '&Materializaci'#243'n'
            ImageIndex = 3
            ExplicitLeft = 4
            ExplicitTop = 30
            ExplicitWidth = 1024
            ExplicitHeight = 624
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
              Left = 520
              Top = 8
              Caption = ' Documento a generar '
              TabOrder = 1
              Height = 200
              Width = 492
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
                Left = 120
                Top = 88
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
                Width = 250
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
                  Width = 100
                end
                object dbcPrevCantidad: TcxGridDBColumn
                  Caption = 'Cantidad'
                  DataBinding.FieldName = 'CANTIDAD'
                  Width = 80
                end
                object dbcPrevPrecioCompra: TcxGridDBColumn
                  Caption = 'Pr. compra'
                  DataBinding.FieldName = 'PRECIO_COMPRA'
                  Width = 90
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
            Caption = 'L&og'
            ImageIndex = 4
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
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
          ExplicitWidth = 1032
          object btnCrearMaterializar: TcxButton
            Left = 8
            Top = 4
            Width = 220
            Height = 28
            Caption = 'Crear art'#237'culos y documentos'
            TabOrder = 0
            OnClick = btnCrearMaterializarClick
          end
          object btnAnularSesion: TcxButton
            Left = 240
            Top = 4
            Width = 100
            Height = 28
            Caption = 'Anular'
            TabOrder = 1
            OnClick = btnAnularSesionClick
          end
          object btnClonarSesion: TcxButton
            Left = 350
            Top = 4
            Width = 100
            Height = 28
            Caption = 'Clonar'
            TabOrder = 2
            OnClick = btnClonarSesionClick
          end
          object btnCerrarManual: TcxButton
            Left = 460
            Top = 4
            Width = 160
            Height = 28
            Caption = 'Cerrar (sin materializar)'
            TabOrder = 3
            OnClick = btnCerrarManualClick
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 1034
        ExplicitHeight = 695
        inherited pnlPerfilTop: TPanel
          Width = 1036
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1034
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1036
          Height = 640
          StyleElements = [seFont, seClient, seBorder]
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
